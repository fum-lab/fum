+++
schema_version = 1
card_id = "FUM-STEP-0141"
status = "active"
+++
# Realizovatj shtatnyij sbros FIFO-ocheredi i rabochej kopii

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dovesti do zhivoj priyomki lokaljnyij, ograzhdyonnyij i vozobnovlyayemyij sbros FIFO-ocheredi i Git-rabochej kopii k tochnomu `HEAD` tekusjhej imenovannoj vetki. Sbros nachinayet toljko otdeljnaya yavno upolnomochennaya kornevaya zadacha vosstanovleniya po tochnomu poljzovateljskomu namereniyu i podtverzhdyonnomu planu; postoyannaya zadacha dispetchera, heartbeat i avtomaticheski sozdannoye prodolzheniye polnomochij na etot khod ne poluchayut.

## Pochemu sejchas

Dejstvuyusjhij FIFO-kontrakt namerenno ne imeyet TTL i prinuditeljnogo obkhoda, poetomu poteryannyij vladelec ili gryaznaya rabochaya kopiya mogut zakryitj obsjhij checkout. Lokaljnaya mashina sostoyanij, Git-CAS-ograzhdeniye, tochnaya ochistka, novoye pokoleniye ocheredi i samodostatochnaya kvitanciya uzhe realizovanyi i avtonomno proverenyi. Shag ostayotsya aktivnyim, potomu chto bezopasnaya zhivaya priyomka trebuyet avtoritetnogo polnogo perechnya otnosyasjhikhsya k checkout pisatelej i proveryayemoj ostanovki proizvoljnoj aktivnoj host-sessii; dostupnaya poverkhnostj Codex poka etogo ne dokazyivayet. Otdeljnyij chelovecheskij `./sbrositj.sh` ostayotsya boleye uzkim break-glass i ne podmenyayet etu garantiyu.

## Kriterii zaversheniya

- Read-only-plan zakreplyayet fizicheskij checkout, polnyij ref, tochnyij `HEAD`, obyyekt FIFO, zatragivayemyiye runtime-ssyilki, preimage i target kazhdogo izmenyayemogo tracked-puti i polnyij perechenj vozmozhnyikh pisatelej; specialjnyij untracked-obyyekt, skryityiye flagi indeksa, izmenyonnaya checkout-politika, vneshnij filter, vlozhennaya Git-granica, gryaznyij submodule ili pozdnij drift dayut razlichimyij otkaz do udaleniya.
- Pervyij Git-CAS-perekhod ustanavlivayet reset-fence, posle chego obyichnyiye `join`, dopusk, commit+handoff, `finish-clean` i sozdaniye prodolzheniya dlya toj zhe oblasti bezopasno otkazyivayut do terminaljnogo iskhoda.
- Vosstanoviteljnyij khod prinimayet toljko otdeljnoye yavnoye poljzovateljskoye namereniye i tochnoye podtverzhdeniye plana; obyichnaya zadacha-prodolzheniye, selector i istoricheskij heartbeat ne mogut nachatj ili podtverditj sbros.
- Do pervoj mutacii zadacha dokazyivayet polnyij perechenj vozmozhnyikh pisatelej i neaktivnostj kazhdoj otnosyasjhejsya k checkout sessii; neizvestnostj, tajm-aut, chastichnyij perechenj, neodnoznachnyij otvet ili otsutstviye proveryayemogo host-stop zakryivayut khod.
- Lokaljnyij perekhod vosstanavlivayet indeks i tracked-derevo iz zakreplyonnogo `HEAD`, udalyayet toljko podtverzhdyonnyiye Git-vidimyiye neignoriruyemyiye obyichnyiye fajlyi i simvolicheskiye ssyilki i sokhranyayet ignoriruyemyiye, novyiye, izmenivshiyesya i vlozhennyiye dannyiye.
- Preryivaniye idempotentno prodolzhayet tot zhe reset-record libo bezopasno otkazyivayet; final atomarno sozdayot pustuyu ocheredj novogo pokoleniya i samodostatochnuyu neizmenyayemuyu kvitanciyu, poetomu prezhniye biletyi, vladelec, `task_id`, pokoleniye i sokhranyonnyiye otvetyi boljshe ne dayut prava zapisi.
- Avtonomnaya matrica pokryivayet gonki sbrosa s FIFO i sozdaniyem prodolzheniya, staged-, unstaged-, konfliktnyiye i neotslezhivayemyiye izmeneniya, SHA-1 i SHA-256, Git GC i preryivaniye kazhdoj fazyi; zhivaya priyomka otdeljno podtverzhdayet ostanovku pisatelej, tochnoye vosstanovleniye `HEAD`, pustuyu ocheredj i bezopasnyij novyij `join`.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [FUM-SBOJ-0013 — Blokirovka avtozapuska posle podtverzhdyonnogo FIFO-sbrosa](../../Sboi/FUM-SBOJ-0013-blokirovka-avtozapuska-posle-podtverzhdyonnogo-FIFO-sbrosa.md)
- [iskhodnyij zapros 2026-08-08 07:56:16 MSK — Pochinitj avtozapusk FUM](../../Zhurnal/2026-08-08_07-56-16_MSK_pochinitj-avtozapusk-FUM/zapros.md)
- [FUM-REQ-0039 — Shtatnyij sbros FIFO-ocheredi i rabochej kopii](../../Trebovaniya/🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)
- [iskhodnyij zapros 2026-08-07 20:34:22 MSK — Dobavitj shtatnyij sbros ocheredi](../../Zhurnal/2026-08-07_20-34-22_MSK_dobavitj-shtatnyij-sbros-ocheredi/zapros.md)
- [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [vyibor sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:dba314a8786ad68567f1cea7b565a6d2d26c938336b42b93cd4b20436c247a1f -->
<!-- FUM-MD-RECENCY:END -->
