# Otchyot 2026-07-21 18:31:35 MSK - Vvesti posledovateljnuyu ocheredj sessij bez hooks

Hook-zavisimyij vetochnyij barjyer zamenyon perenosimoj kooperativnoj FIFO-ocheredjyu. Nezavisimyiye kornevyiye zadachi teperj mozhno zapuskatj paralleljno v odnom checkout: oni atomarno registriruyut poryadok, no izmenyayut repozitorij strogo po odnoj i peredayut pravo sleduyusjhej vmeste s kommitom libo proveryayemyim chistyim zaversheniyem zakonnoj no-op-zadachi.

## Posledovateljnyij kontrakt

Pervoye dejstviye kornevoj zadachi — `join` s tochnyim `CODEX_THREAD_ID`. Git compare-and-swap naznachayet vozrastayusjhij `seq`; boleye pozdniye biletyi vyizyivayut ogranichennyij read-only `wait` i ne pishut ni v rabochuyu kopiyu, ni v ref ocheredi. Poryadok ne pereuporyadochivayetsya, prioritetov, TTL i prinuditeljnogo obkhoda net.

Posle kommita predshestvennika ozhidayusjhaya zadacha poluchayet `reload_required`, perechityivayet tekusjhiye `AGENTS.md`, pasport ocheredi i zatronutyiye materialyi, podtverzhdayet tochnyij novyij `HEAD` cherez `ack-head` i lishj zatem mozhet statj vladeljcem. Eto zakryivayet rabotu po ustarevshemu developer-kontekstu uzhe otkryitoj sessii.

Vladelec s osmyislennyim diff zavershayet zadachu ne obyichnyim `git commit`, a atomarnyim commit+handoff. Scenarij proveryayet pokoleniye, vetku, `base_head`, indeks i otsutstviye nezavershyonnyikh putej, sozdayot commit object i odnoj tranzakciyej obnovlyayet ref vetki i ref ocheredi. Sleduyusjhij bilet ne mozhet uvidetj osvobozhdyonnuyu ocheredj bez sootvetstvuyusjhego kommita.

Dlya zakonnoj no-op-zadachi dobavlen `finish-clean`: on trebuyet tochnogo vladeljca i pokoleniya, neizmennogo `HEAD`, chistotyi vne `.obsidian/` i otsutstviya lyubyikh staged-izmenenij. Odna Git-tranzakciya proveryayet ref vetki i peredayot ocheredj bez kommita. Admission primenyayet takoye zhe atomarnoye branch fencing, poetomu ni konkurentnyij handoff, ni chistoye zaversheniye ne ostavlyayut vladeljca na ustarevshem `HEAD`.

## Paralleljnostj vnutri zadachi

Subagentyi ne registriruyutsya otdeljno i ne upravlyayut Git. Dopusjhennyij korenj raspredelyayet mezhdu nimi neperesekayusjhiyesya fajlyi, sinkhroniziruyet peresecheniya shtatnyimi soobsjheniyami, vidit obsjhij diff i sam vyipolnyayet indeksirovaniye, proverki i kommit. Pered handoff korenj dozhidayetsya vsekh vozmozhnyikh pozdnikh pisatelej.

## Perenosimostj i granicyi

Sostoyaniye khranitsya kak kanonicheskij JSON blob pod sluzhebnoj Git-ssyilkoj i menyayetsya compare-and-swap. Ocheredj ispoljzuyet Python 3 i obyichnyiye komandyi Git, podderzhivayet SHA-1, SHA-256 i Unicode refs i ne trebuyet project hooks, POSIX-blokirovok, hard links, signalov ili ruchnogo dopuska v shtatnom khode. Shtatnyij Python HEAD-bootstrap zapuskayetsya v isolated mode, isklyuchayet checkout iz puti importa, ochisjhayet unasledovannyiye Git-peremennyiye, ogranichivayet zagruzku 30 sekundami, ispolnyayet scenarij iz bukvaljnogo zakommichennogo `HEAD` i zakreplyayet korenj checkout; vnutrenniye Git-vyizovyi tozhe ignoriruyut replace-obyyektyi, optional locks i perenapravlyayusjhuyu Git-sredu. Poetomu ozhidayusjhiye sessii ne podkhvatyivayut nezavershyonnoye ili lokaljno podmenyonnoye izmeneniye samoj ocheredi.

Ozhidayusjhiye biletyi i vladelec bessrochnyi. Bez vneshnego dostovernogo signala sboj neotlichim ot dolgoj rabotyi; udaleniye ozhidayusjhego izmenilo byi FIFO, a zakhvat poverkh vladeljca mog byi sozdatj dvukh pisatelej. Ta zhe zadacha mozhet vozobnovitjsya i zavershitj svoj bilet, no prinuditeljnoye vosstanovleniye i pereuporyadochivaniye ne realizovanyi. Otdeljnyiye klonyi ne koordiniruyutsya.

## Planovyiye zadachi

Pyatiminutnyij dispetcher pri lyuboj drugoj nablyudayemoj `active`-zadache ne rezerviruyet shag, ne stavit planovuyu rabotu v FIFO-ocheredj i voobsjhe ne sozdayot zadachu. Toljko nablyudayemyij prostoj posle dvukh proverok dopuskayet sozdaniye obyichnoj kornevoj zadachi, kotoraya zatem soblyudayet obsjhij kontrakt.

Claim planovogo shaga takzhe perevedyon s POSIX `flock` na JSON blob i compare-and-swap sluzhebnoj Git-ssyilki, privyazannoj k fizicheskomu checkout. Proigravshij CAS vyizov ne mozhet perezapisatj boleye novyij `step_id`; symref otklonyayetsya, a vse unasledovannyiye `GIT_*` ochisjhayutsya. Prezhniye claim-fajlyi ne importiruyutsya i boljshe ne avtoritetnyi, poetomu perekhod ne trebuyet ruchnoj migracii.

Tekusjhaya migracionnaya sessiya byila dopusjhena prezhnim minimaljnyim kornevyim hook. Ona fiksiruyet etot perekhod obyichnyim Git-kommitom pod staryim lease i osvobozhdayet yego poslednim dejstviyem; novaya ocheredj nachinayet obsluzhivatj sleduyusjhiye kornevyiye zadachi uzhe iz zakommichennogo `HEAD`.

## Proverki

- Avtonomnyij TDD-nabor iz 31 testa proveryayet konkurentnuyu registraciyu, strogij FIFO, bessrochnostj biletov, read-only ozhidaniye, zapret obkhoda, `reload_required`/`ack-head`, `finish-clean`, branch-fenced admission, atomarnyij commit+handoff i gonki vneshnego izmeneniya `HEAD`.
- Regressii pokryivayut SHA-1/SHA-256, Unicode-vetku, `nan`/`inf` timeout, JSON pri ASCII stdout, smenu vetki, postoyannyiye ref locks, otsutstviye optional zapisi stat-cache, isolated-ispolneniye scenariya iz bukvaljnogo `HEAD` s zakrepleniyem kornya checkout i ochistkoj Git-sredyi, ignorirovaniye replace-obyyektov i otsutstviye POSIX-primitivov.
- Konfiguraciya Codex proveryayetsya na otsutstviye hooks, a staryij putj loader — na minimaljnyij no-op bez aktivnogo pasporta.
- 28 testov dispetchera proveryayut konkurentnyij i mezhshagovyij Git-CAS claim, exact-lease release, zamenu shaga, povrezhdyonnyiye blob i symref, dirty checkout/index, Unicode, SHA-256, ochistku Git-sredyi i trace-fajlov, a takzhe otsutstviye POSIX-primitivov.
- Polnyij smoke-check, planovyij reyestr, recency-metki, graf Obsidian i sessionnaya svyaznostj vyipolnyayutsya pered kommitom.

## Zatronutyiye materialyi

- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [proyektnaya konfiguraciya Codex](../../.codex/config.toml)
- [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [claim sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [paralleljnaya rabota i sliyaniye](../../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [sleduyusjhiye shagi vetok](../../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [predyidusjhaya migraciya na minimaljnyij kornevoj hook](../2026-07-21_17-49-38_MSK_perevesti-vetochnyij-barjyer-na-minimaljnyij-kornevoj-hook/zapros.md)
- [iskhodnoye trebovaniye serializacii](../2026-07-20_16-11-17_MSK_serializovatj-zadachi-v-vetke/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:52185633aa07d74fdbb4bf2507973674e7d26ffb93a7cc2790288c4151ce0213 -->
<!-- FUM-MD-RECENCY:END -->
