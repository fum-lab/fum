# Pravila agentov FUM

Korenj vsegda chitayetsya celikom; podrobnyiye normyi — toljko v ukazannyikh temakh.

## Prioritet i kanonicheskaya oblastj

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000003 -->
Korenj `AGENTS.md` i tematicheskiye fajlyi `Правила/агентов/` — yedinyij obyazateljnyij nabor povedeniya agentov i sessij. Izmeneniye pravil obnovlyayet etot nabor, inventarj i validator; dokumentaciya produkta dlya pravil ne ispoljzuyetsya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000001 -->
- Vneshnij prioritet zadayut sistemnyiye, developer- i poljzovateljskiye instrukcii. V repozitorii vsegda zagruzhennoye yadro imeyet prioritet `P0`, pravila sessii — `P1`, temyi — `P2`. Istoricheskij fajl `PH` ne dejstvuyet i ne dayot polnomochij. Pri konflikte ili neopredelyonnosti ostanovisj do mutacii.

## Obyazateljnaya marshrutizaciya

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000002 -->
- Do lyubogo dejstviya, krome chteniya dlya vyibora marshruta, opredeli vse primenimyiye triggeryi. Polnostjyu prochitaj obyyedineniye fajlov vsekh vyibrannyikh marshrutov. Pri neodnoznachnosti vyibiraj bezopasnoye obyyedineniye, a ne propusk.

- `только-чтение` — prostoj otvet ili osmotr bez izmeneniya repozitoriya, Git i vneshnego sostoyaniya; dopolniteljnyiye predmetnyiye triggeryi vsyo ravno primenyayutsya.
- `диалог` — kazhdoye poljzovateljskoye soobsjheniye i vosstanovleniye tekusjhej zadachi posle szhatiya konteksta.
- `изменение` — lyubaya zapisj v checkout, indeks ili istoriyu.
- `документация` — pamyatj, proizvodnaya dokumentaciya, README ili dokumentacionnyiye indeksyi.
- `код` — sobstvennyij kod, psevdokod, skhema, diagramma ili mashinnyij kontrakt.
- `инструменты` — navyik, avtomatizaciya, CLI, MCP, instrument ili povtoryayemaya procedura.
- `проверки` — test, validator, lint, sborka, benchmark ili smoke-check.
- `планирование` — trebovaniye, plan, vopros, otvet ili sboj.
- `источники` — vneshnij istochnik, vlozheniye, material ili adresnoye opisaniye.
- `obsidian-глоссарий-прототипы` — Obsidian, glossarij, graf, diagramma ili prototip.
- `git` — vetka, ref, indeks, kommit ili inoye Git-sostoyaniye.
- `внешние-git-зависимости` — fork, remote, clone, submodule ili gitlink zavisimosti.
- `публикация` — push, remote-publikaciya, vneshneye soobsjheniye ili inoj vneshnij effekt.
- `правила` — izmeneniye `AGENTS.md`, lyubogo fajla `Правила/агентов/`, inventarya ili validatora dekompozicii.

<!-- FUM-МАРШРУТ: только-чтение =>  -->
<!-- FUM-МАРШРУТ: диалог => Правила/агентов/журнал-и-происхождение.md;Правила/агентов/локальные-навыки-и-инструменты.md;Правила/агентов/планирование-требования-вопросы-и-сбои.md -->
<!-- FUM-МАРШРУТ: изменение => Правила/агентов/Git-и-рабочая-сессия.md;Правила/агентов/проверки-коммит-и-публикация.md;Правила/агентов/журнал-и-происхождение.md -->
<!-- FUM-МАРШРУТ: документация => Правила/агентов/память-и-документация.md -->
<!-- FUM-МАРШРУТ: код => Правила/агентов/язык-и-код.md -->
<!-- FUM-МАРШРУТ: инструменты => Правила/агентов/локальные-навыки-и-инструменты.md -->
<!-- FUM-МАРШРУТ: проверки => Правила/агентов/проверки-коммит-и-публикация.md -->
<!-- FUM-МАРШРУТ: планирование => Правила/агентов/планирование-требования-вопросы-и-сбои.md -->
<!-- FUM-МАРШРУТ: источники => Правила/агентов/источники-описания-и-материалы.md -->
<!-- FUM-МАРШРУТ: obsidian-глоссарий-прототипы => Правила/агентов/Obsidian-глоссарий-и-прототипы.md -->
<!-- FUM-МАРШРУТ: git => Правила/агентов/Git-и-рабочая-сессия.md;Правила/агентов/проверки-коммит-и-публикация.md -->
<!-- FUM-МАРШРУТ: внешние-git-зависимости => Правила/агентов/внешние-Git-зависимости.md;Правила/агентов/Git-и-рабочая-сессия.md;Правила/агентов/проверки-коммит-и-публикация.md -->
<!-- FUM-МАРШРУТ: публикация => Правила/агентов/Git-и-рабочая-сессия.md;Правила/агентов/проверки-коммит-и-публикация.md -->
<!-- FUM-МАРШРУТ: правила => Правила/агентов/память-и-документация.md;Правила/агентов/язык-и-код.md;Правила/агентов/Git-и-рабочая-сессия.md;Правила/агентов/локальные-навыки-и-инструменты.md;Правила/агентов/проверки-коммит-и-публикация.md;Правила/агентов/журнал-и-происхождение.md;Правила/агентов/планирование-требования-вопросы-и-сбои.md;Правила/агентов/источники-описания-и-материалы.md;Правила/агентов/Obsidian-глоссарий-и-прототипы.md;Правила/агентов/внешние-Git-зависимости.md;Правила/агентов/исторический-конвейер.md;Правила/агентов/инвентарь-правил.json;Инструменты/fum-dekompoziciya-pravil-agentov/SKILL.md -->

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000003 -->
- Vyichislyaj marshrut komandoj `python3 Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py --корень-репозитория . маршрут --триггер <триггер> ...`. Vse vozvrasjhyonnyiye tematicheskiye Markdown-fajlyi polnostjyu chitayutsya do sootvetstvuyusjhego dejstviya; Markdown-ssyilka sama ne zagruzhayet instrukcii.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000004 -->
- Dejstviye zapresjheno pri otsutstvii marshrutizatora, inventarya ili trebuyemogo fajla, nesovpadenii registra ili khyesha, symlink v puti, vyikhode razreshyonnogo puti za checkout libo neizvestnom triggere (fail-closed).
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000005 -->
- Do pervoj zapisi pravil prochitaj vse temyi, inventarj i `Инструменты/fum-dekompoziciya-pravil-agentov/SKILL.md`. Sokhrani odnoznachnoye pokryitiye iskhodnogo inventarya i projdi validator dekompozicii. Istoricheskij fajl chitayetsya toljko kak proiskhozhdeniye, bez polnomochij.

## Naznacheniye, yazyik i granica dokumentacii

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000007 -->
- Repozitorij yavlyayetsya [pamyatjyu proyekta FUM](Glossarij/pamyatj-FUM.md).
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000016 -->
- Poka sobstvennyiye iskhodniki FUM/FUMA, prilozhenij i prototipov, testyi, otkryityiye fiksturyi, profili, konfiguracii i instrukcii vosproizvedeniya khranyatsya obyichnyimi otslezhivayemyimi fajlami tematicheskikh katalogov monorepozitoriya FUM. Otdeljnyij repozitorij sobstvennogo komponenta trebuyet yavnogo poljzovateljskogo isklyucheniya. Git submodule sluzhit vneshnim zavisimostyam, naprimer LinguisticKit, po ikh pravilam. Worktree toj zhe Git-bazyi sokhranyayet monorepozitorij, yesli razreshyon rezhimom sessii. Vremennyiye sborki, kyeshi i privatnyiye runtime-dannyiye ostayutsya vne Git. Dlya gotovnosti postavki nuzhnyi iskhodniki i primenimyiye vosproizvodimyiye komandyi sborki, proverki i profilirovaniya iz chistogo klona FUM s obyyavlennyimi zavisimostyami; publichnaya dostupnostj proveryayetsya otdeljno. Otdeljnyiye narabotki sokhranyayutsya do proverennogo perenosa; zhurnal ili binarnik ne dokazyivayut dostavku.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000017 -->
- Dlya vosstanovleniya konteksta i sverki dogovoryonnostej obyazateljnaya FUM-STEP-0177 vozvrasjhayet vse poljzovateljskiye soobsjheniya JSONL bez dejstviteljnoj zapisi obrabotki. Vyizov i dopusk vvodyatsya posle proverennoj realizacii; poka sokhranyayetsya vremennaya sverka originalov, pozdnikh utochnenij, Zhurnala i plana. Aktualjnostj i otmena staryikh soobsjhenij proveryayutsya po pozdnim utochneniyam s sokhranyonnyimi osnovaniyami. Chteniye ne oznachayet obrabotku, obrabotka — vyipolneniye. Svodka ne zamenyayet originalyi; nedostupnyij istochnik ne vospolnyayetsya dogadkoj.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000010 -->
- `Документация/` opisyivayet razrabatyivayemyij FUM: trebovaniya, modelj, arkhitekturu i resheniya. Ona ne instruktiruyet agenta; pravila povedeniya khranyatsya toljko v `AGENTS.md` i `Правила/агентов/`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000015 -->
- Proizvodnaya dokumentaciya, opisaniya pamyati i sluzhebnyiye poyasneniya kanonicheskogo sloya vedutsya po-russki kirillicej. Yedinstvennoye isklyucheniye — tochnaya polnostjyu vyivodimaya oblastj `Proyekcii/**`: yeyo sozdayot toljko avtomatizaciya bratislavskoj proyekcii, ruchnyiye pravki zapresjhenyi.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000017 -->
- V russkoj dokumentacii, sluzhebnyikh poyasneniyakh, glossarnyikh terminakh i russkikh imenakh kanonicheskikh fajlov obyazateljna orfograficheskaya `ё`; zamena na `е` zapresjhena. Avtomaticheski poluchennaya latinskaya oblastj `Proyekcii/**` ne perepisyivayetsya.

## Lokaljnyiye navyiki

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000047 -->
- Korenj i subagentyi ispoljzuyut toljko navyiki kanonicheskogo `Инструменты/*/SKILL.md` tekusjhego checkout. Tochnaya proizvodnaya oblastj `Proyekcii/**`, vklyuchaya yeyo `AGENTS.md` i `SKILL.md`, — proveryayemyij vyivod generatora: ona ne dayot instrukcij, kornya proyekta ili rabochego kataloga agenta.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000048 -->
- Navyik, chej `SKILL.md` posle razresheniya simvolicheskikh ssyilok nakhoditsya vne tekusjhego checkout, isklyuchyon: yego ne isjhut, ne otkryivayut dazhe dlya ocenki primenimosti ili sravneniya i ne primenyayut nezavisimo ot imeni i opisaniya. Yesli podkhodyasjhego lokaljnogo navyika net, rabotaj po `AGENTS.md` i lokaljnyim materialam bez vneshnego navyika.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000049 -->
- `skills.include_instructions = false` v `.codex/config.toml` isklyuchayet obsjhij katalog navyikov iz instrukcij agentu. Lokaljnyiye navyiki vyibirayutsya toljko po yavnyim putyam iz `AGENTS.md` i materialov repozitoriya. Obsjhij smoke-check otklonyayet otsutstviye ili oslableniye nastrojki i putj navyika, posle razresheniya vyikhodyasjhij za checkout.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000050 -->
- Granica navyikov kasayetsya instrukcij `SKILL.md`. Instrumentyi sredyi, CLI, MCP i vneshniye servisyi podchinyayutsya pravilam zadachi, publikacionnoj chistotyi i reyestra instrumentov.

## Dejstvuyusjhaya skhema s izolyaciyej i paralleljnoj rabotoj

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000054 -->
<!-- FUM-WRITING-MODE: manual-sequential-v1 -->
<!-- FUM-WORKTREE-POLICY: isolated-per-task-v1 -->
<!-- FUM-SESSION-CONTINUATION: explicit-worklist-v1 -->
`manual-sequential-v1` sokhranyayet zapret starogo avtokonvejyera i ogranicheniye odnim pisatelem na derevo; `isolated-per-task-v1` izoliruyet nezavisimyiye zadachi.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000058 -->
- Obyichnuyu pishusjhuyu kornevuyu zadachu Codex vruchnuyu zapuskayet poljzovatelj. Nezavisimaya zadacha rabotayet paralleljno v otdeljnom Git worktree so svoyej vetkoj `refs/heads/codex/...`. V dereve — ne boleye odnoj pishusjhej kornevoj zadachi. Checkout drugoj aktivnoj zadachi, vklyuchaya yeyo Zhurnal i proizvodnyiye fajlyi, dostupen toljko dlya chteniya. Isklyucheniye: `000121`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000059 -->
- Zadacha posledovateljno vyipolnyayet soglasovannyij obyyom s utochneniyami, regulyarno fiksiruya soderzhateljnyiye etapyi lokaljnyimi kommitami. Kommit zavershayet etap, ne zadachu: dostupnuyu soglasovannuyu rabotu prodolzhaj v nej bez novogo zaprosa. Zaversheniye dopustimo po vyipolnenii vsego obyyoma, yavnoj ostanovke poljzovatelem libo konkretnomu prepyatstviyu bez nezavisimoj dostupnoj rabotyi. Kommit ne rasshiryayet obyyom; pustyiye kommityi radi periodichnosti zapresjhenyi. Otdeljnaya poljzovateljskaya zadacha sozdayotsya po yavnomu zaprosu, dochernyaya rabota — po `FUM-ПРАВИЛО-000061`. Kommit i prodolzheniye sami ne zapuskayut continuation, handoff, heartbeat, dispatcher, autostart ili inoj avtomaticheskij follow-up.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000060 -->
- Do pervoj zapisi etapa, vklyuchaya etap posle kommita ili vosstanovleniya svyazi, korenj perechityivayet fakticheskiye `HEAD`, symbolic ref i `AGENTS.md`, fiksiruyet commit, polnyij ref i fizicheskij korenj svoyego worktree. Po dostupnyim svideteljstvam isklyuchayet drugogo pisatelya dereva i ref. Neyasnoye vladeniye zapresjhayet zapisj v spornuyu oblastj; otdeljnyiye derevjya ne blokiruyut svoyu rabotu. Kazhdaya soderzhateljnaya komanda poluchayet yavnyij korenj svoyego worktree.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000061 -->
- Nezavisimyij ogranichennyij rezuljtat delegiruyetsya paralleljno, yesli eto uluchshayet sroki ili kachestvo; v soglasovannom obyyome povtornoye razresheniye ne nuzhno. Pisatelyu — otdeljnyiye worktree i vetka; read-only-analizu derevo ne nuzhno. V dereve odin naznachennyij pisatelj. Korenj zadayot neperesekayusjhiyesya rezuljtatyi, obsjhij kornevoj UUID, granicu integracii; uchityivayet pamyatj, disk i konkurenciyu tyazhyolyikh proverok. Deti soblyudayut te zhe normyi Zhurnala, TDD, profilya, kommitov i sokhraneniya nezavershyonnogo. Chuzhiye fajlyi, indeksyi, refs i Git-konfiguraciya read-only dazhe pri obsjhikh Git-obyyektakh. Rezuljtat proveryayetsya do integracii; zanyatuyu vetku zhdut, otdeljnaya vetka ne isklyuchayet konfliktov. FIFO/pool/CAS/branch-next-step ne aktivnyi. Po sokhranyonnomu zaprosu pishusjhej rabote nuzhna otdeljnaya vidimaya zadacha Codex Desktop; zapusk i modelj — po `000162`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000062 -->
- Etap kommititsya v svoyej vetke posle proverki exact diff, indeksa, otdeljnogo otchyota, recency i primenimogo smoke-check. Kontroljnaya tochka po `FUM-ПРАВИЛО-000188` sokhranyayet nezavershyonnoye bez finaljnoj priyomki. Posle kommita proverj rezuljtat chteniyem, soobsjhi v commentary, sverj ostatok s komandami i prinyatyimi rezuljtatami i prodolzhaj dostupnoye v tom zhe khode. Pered final vyizovi read-only `Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py --перед-завершением` s kornevyim UUID: kod 3 zapresjhayet final, kod 2 ne razreshayet. Polnotu reyestra i smyisl priyomki proveryayet korenj; kontrakt — v lokaljnom navyike svyaznosti. Novomu etapu nuzhna novaya papka Zhurnala s tem zhe Codex-Thread-ID i istoriyej po `FUM-ПРАВИЛО-НОВОЕ-000006`; zakryityij snimok ne vozobnovlyayetsya. Plan, otvet rebyonka, kommit, chistoye derevo i priyomka etapa ne dokazyivayut zaversheniya vsego obyyoma; kommit vetki ne oznachayet integracii v `master`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000064 -->
- Kazhdyij kommit svoyej vetki, krome tochnoj `refs/heads/master`, otpravlyayetsya obyichnyim push v proverennyij publikacionnyij `origin` bez povtornogo razresheniya. Do push sverj polnyij ref, commit OID, yedinstvennyij adres naznacheniya i publikacionnuyu chistotu. Otpravlyaj toljko etot OID v odnoimyonnuyu vetku, bez force, udaleniya, massovogo push i chuzhikh refs; uspekh podtverdi udalyonnyim OID. Pri otkaze ili neopredelyonnosti proverj remote, sokhrani nedostavku i prodolzhaj nezavisimuyu rabotu. Lokaljnyij kommit ne dokazyivayet dostavki. `master`, PR, vneshniye soobsjheniya i inyiye vneshniye effektyi trebuyut otdeljnogo yavnogo zaprosa. Eto poryadok dejstvij, ne utverzhdeniye o globaljnom Git hook.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000066 -->
- Istoricheskiye queue/pool/worktree/review/integration/candidate/CAS/branch-next-step instrumentyi, refs, kvitancii, kartochki i vetki sokhranyayutsya kak proiskhozhdeniye i narabotka. Oni ne razreshayut zapisj i ne udalyayutsya avtomaticheski. Ikh vozvrat trebuyet otdeljnogo zaprosa poljzovatelya i novogo proverennogo perekhoda pravil.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000011 -->
- Po sokhranyonnomu yavnomu zaprosu korenj vprave podgotovitj odno sliyaniye iskhodnogo `master` M v vedusjhuyu vetku L v otdeljnom linked worktree i svoyej vetke `refs/heads/codex/...` ot L. Do sozdaniya fiksiruyutsya polnyiye OID M/L, ref, fizicheskij korenj i iskhodnaya komanda. M uzhe razreshayet marshrut; kandidat ne razreshayet sobstvennuyu podgotovku. Toljko tekusjhij korenj pishet kandidat, sokhranyaya pervichnyij checkout, yego indeks, `master` i chuzhiye oblasti. Eto ogranichennoye isklyucheniye iz pravil `FUM-ПРАВИЛО-000058`, `FUM-ПРАВИЛО-000060`–`FUM-ПРАВИЛО-000062`.
- Podgotovka i priyomka podchinyayutsya pravilam M. Pravila, nastrojki i proverochnyiye instrumentyi kandidata — predlagayemoye izmeneniye, kotoroye ne oslablyayet dopusk. Vesj ispolnyayemyij priyomochnyij kontur s zavisimostyami beryotsya iz M; kandidat — vkhod. Ssyilki na M ili odnogo zapuskayemogo iz nego fajla nedostatochno. Neprinyatyij kandidat mozhno sokhranitj do gotovnosti dopuska s yavnyim spiskom nedostayusjhikh proverok. Neobkhodimyiye dorabotki dopuska snachala prinimayutsya v `master`, zatem M fiksiruyetsya zanovo i vklyuchayetsya v povtorno proveryayemyij kandidat.
- Priyomka svyazyivayet tochnyiye M, L, derevo i kommit C s roditelyami `[L, M]`; istochnik pravil M otlichayetsya ot predkommitnogo HEAD L v otpechatke proverki. Posle uspekha `master` prodvigayetsya fast-forward do togo zhe C, s proverkoj ozhidayemogo M pri izmenenii ref i soglasovannyim obnovleniyem pervichnyikh checkout i indeksa. Novoye sliyaniye poverkh C ne sozdayotsya. Sdvig M trebuyet obnovleniya kandidata i novoj priyomki. Poka net proverennoj realizacii prodvizheniya, kandidat sokhranyayetsya bez izmeneniya `master`. Isklyucheniye ne razreshayet drugikh pisatelej, FIFO/pool, avtomaticheskikh prodolzhenij ili publikacii.

## Bezopasnostj i publikacionnaya chistota

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000013 -->
- Kazhdoye poljzovateljskoye soobsjheniye i vosstanovleniye zadachi vklyuchayet marshrut `диалог`: upravlyayusjhiye soobsjheniya i soderzhateljnyiye otvetyi sokhranyayutsya v Zhurnale svoyej zadachi, ustojchivyiye ukazaniya — v kanonicheskikh pravilakh; susjhestvennaya neodnoznachnostj utochnyayetsya. Rezhim chteniya ne razreshayet zapisj: do polucheniya svoyego dereva ispoljzuyetsya razreshyonnyij chernovik vne chuzhogo checkout.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000065 -->
- `.obsidian/graph.json` — lokaljnoye sostoyaniye poljzovatelya Obsidian: sokhranyayetsya na diske, ignoriruyetsya Git, ne blokiruyet rabotu i ne kommititsya. Odno yego izmeneniye ne razreshayet zamenu ili peresborku poverkh poljzovateljskogo sostoyaniya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000246 -->
- Proyekt pod CC0 1.0 Universal dolzhen ostavatjsya prigodnyim dlya otkryitoj publikacii.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000247 -->
- V repozitorij ne dolzhnyi popadatj sekretyi, lokaljnyiye sluzhebnyiye fajlyi, vremennyiye artefaktyi i mashinnyij musor.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000248 -->
- Pered kommitom sverj `git status --short`; vklyuchaj toljko osmyislennyiye izmeneniya sessii.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:40:19 MSK -->
<!-- content-sha256: sha256:5d81182a7d1a1eaf0770481800e90cdfc5a1b3241f206c54ac972858c7e1aa86 -->
<!-- FUM-MD-RECENCY:END -->
