# Pravila povedeniya v repozitorii FUM

Etot korotkij korenj vsegda zagruzhayetsya celikom. On zadayot kriticheskuyu granicu i obyazateljnyij marshrutizator; podrobnyiye dejstvuyusjhiye normyi nakhodyatsya toljko v ukazannyikh tematicheskikh fajlakh.

## Prioritet i kanonicheskaya oblastj

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000003 -->
Kornevoj `AGENTS.md` vmeste s kanonicheskimi tematicheskimi fajlami v `Правила/агентов/` yavlyayetsya yedinyim obyazateljnyim naborom pravil povedeniya agentov i rabochikh sessij. Izmeneniye pravil obnovlyayet etot nabor, yego mashinnyij inventarj i validator, a ne dokumentaciyu o produkte FUM.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000001 -->
- Vneshnij poryadok prioriteta zadayut sistemnyiye, developer- i poljzovateljskiye instrukcii. Vnutri repozitoriya vsegda zagruzhennoye yadro imeyet prioritet `P0`, pravila dejstvuyusjhej sessii — `P1`, tematicheskiye normyi — `P2`; istoricheskij fajl imeyet prioritet `PH`, ne dejstvuyet i ne dayot polnomochij. Konflikt ili neopredelyonnostj zakryivayutsya ostanovkoj do mutacii.

## Obyazateljnaya marshrutizaciya

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000002 -->
- Do lyubogo dejstviya, krome read-only-proverok, nuzhnyikh dlya vyibora marshruta, opredeli vse podkhodyasjhiye triggeryi po tablice nizhe. Pri neskoljkikh triggerakh polnostjyu chitayutsya fajlyi iz obyyedineniya vsekh marshrutov; pri neodnoznachnosti vyibirayetsya bezopasnoye obyyedineniye, a ne propusk.

- `только-чтение` — prostoj otvet ili osmotr bez izmeneniya repozitoriya, Git i vneshnego sostoyaniya; dopolniteljnyiye predmetnyiye triggeryi vsyo ravno primenyayutsya.
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
- Marshrut vosproizvodimo vyichislyayetsya komandoj `python3 Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py --корень-репозитория . маршрут --триггер <триггер> ...`. Kazhdyij vozvrasjhyonnyij tematicheskij Markdown-fajl prochityivayetsya polnostjyu do otnosyasjhegosya k nemu dejstviya; proizvoljnaya Markdown-ssyilka sama po sebe ne zagruzhayet instrukcii v Codex.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000004 -->
- Otsutstviye marshrutizatora, inventarya ili trebuyemogo fajla, nesovpadeniye registra libo khyesha, simvolicheskaya ssyilka v puti, vyikhod posle yeyo razresheniya za korenj checkout ili neizvestnyij trigger oznachayut fail-closed: otnosyasjheyesya dejstviye ne vyipolnyayetsya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000005 -->
- Izmeneniye samikh pravil trebuyet do pervoj zapisi polnostjyu prochitatj vse tematicheskiye fajlyi, inventarj i `Инструменты/fum-dekompoziciya-pravil-agentov/SKILL.md`, zatem sokhranitj odnoznachnoye pokryitiye iskhodnogo inventarya i projti validator dekompozicii. Istoricheskij fajl pri etom chitayetsya toljko kak proiskhozhdeniye i ne stanovitsya dejstvuyusjhim.

## Naznacheniye, yazyik i granica dokumentacii

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000007 -->
- Repozitorij yavlyayetsya [pamyatjyu proyekta FUM](Glossarij/pamyatj-FUM.md).
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000010 -->
- `Документация/` opisyivayet sam razrabatyivayemyij FUM, yego trebovaniya, modelj, arkhitekturu i resheniya i ne sluzhit instrukciyami agentu; pravila povedeniya repozitoriya khranyatsya toljko v obyazateljnom nabore `AGENTS.md` i `Правила/агентов/`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000015 -->
- Proizvodnaya dokumentaciya, opisaniya pamyati i sluzhebnyiye poyasneniya v kanonicheskom sloye repozitoriya vedutsya na russkom yazyike kirillicej. Yedinstvennoye yazyikovoye isklyucheniye — polnostjyu vyivodimoye soderzhimoye tochnoj oblasti `Proyekcii/**`, kotoroye sozdayotsya toljko avtomatizaciyej bratislavskoj proyekcii i ne redaktiruyetsya vruchnuyu.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000017 -->
- V russkoyazyichnoj dokumentacii, sluzhebnyikh poyasneniyakh, glossarnyikh terminakh i russkikh imenakh fajlov kanonicheskogo sloya yavno ispoljzuyetsya bukva `ё` tam, gde ona nuzhna po orfografii; zamena `ё` na `е` ne dopuskayetsya. Eto orfograficheskoye pravilo ne perepisyivayet avtomaticheski poluchennuyu latinskuyu oblastj `Proyekcii/**`.

## Lokaljnyiye navyiki

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000047 -->
- V zadachakh etogo repozitoriya kornevoj agent i subagentyi ispoljzuyut toljko lokaljnyiye navyiki iz kanonicheskogo `Инструменты/*/SKILL.md` vnutri kornya tekusjhego checkout. Ni odin putj pod tochnoj proizvodnoj oblastjyu `Proyekcii/**`, vklyuchaya sproyecirovannyiye `AGENTS.md` i `SKILL.md`, ne stanovitsya instrukciyej, kornem proyekta ili rabochim katalogom agenta; eti fajlyi rassmatrivayutsya toljko kak proveryayemyij vyivod generatora.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000048 -->
- Lyuboj navyik, chej `SKILL.md` posle razresheniya simvolicheskikh ssyilok nakhoditsya za predelami kornya tekusjhego checkout, polnostjyu isklyuchyon iz marshrutizacii: yego ne isjhut, ne otkryivayut dazhe dlya proverki primenimosti ili sravneniya i ne primenyayut nezavisimo ot sovpadeniya imeni ili opisaniya s zadachej libo lokaljnyim navyikom. Yesli podkhodyasjhego lokaljnogo navyika net, agent rabotayet neposredstvenno po `AGENTS.md` i lokaljnyim materialam repozitoriya bez vneshnego navyika.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000049 -->
- Proyektnaya nastrojka `skills.include_instructions = false` v `.codex/config.toml` isklyuchayet obsjhij katalog navyikov sredyi iz peredavayemyikh agentu instrukcij; lokaljnyiye navyiki vyibirayutsya toljko po yavnyim putyam iz `AGENTS.md` i materialov repozitoriya. Obsjhij smoke-check obyazan otklonyatj otsutstviye ili oslableniye etoj nastrojki, a takzhe lokaljnyij putj navyika, kotoryij posle razresheniya simvolicheskikh ssyilok vyikhodit za korenj checkout.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000050 -->
- Eta granica otnositsya imenno k instrukciyam `SKILL.md`; dostupnyiye instrumentyi sredyi, CLI, MCP i vneshniye servisyi reguliruyutsya otdeljnyimi pravilami zadachi, publikacionnoj chistotyi i reyestra instrumentov.

## Dejstvuyusjhaya ruchnaya posledovateljnaya skhema

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000054 -->
<!-- FUM-WRITING-MODE: manual-sequential-v1 -->
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000058 -->
- Obyichnuyu pishusjhuyu rabotu poljzovatelj zapuskayet vruchnuyu otdeljnoj kornevoj zadachej Codex v pervichnom checkout na `refs/heads/master`. Odnovremenno dopuskayetsya ne boleye odnoj pishusjhej kornevoj zadachi; read-only-nablyudateli mogut sosusjhestvovatj, no ne poluchayut prava menyatj fajlyi, indeks, refs, Git-konfiguraciyu ili vneshneye sostoyaniye.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000059 -->
- Odna pishusjhaya sessiya obrabatyivayet odin soderzhateljnyij poljzovateljskij zapros, sozdayot ne boleye odnogo itogovogo lokaljnogo kommita i posle otveta zavershayetsya. Sleduyusjhuyu pishusjhuyu sessiyu zapuskayet toljko poljzovatelj; agent ne sozdayot `create_thread`, continuation, handoff, heartbeat, dispatcher, autostart ili inoj avtomaticheskij follow-up.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000060 -->
- Pered pervoj zapisjyu kornevaya zadacha perechityivayet fakticheskiye `HEAD`, symbolic ref i `AGENTS.md`, ubezhdayetsya, chto rabotayet v pervichnom checkout na `refs/heads/master`, fiksiruyet iskhodnyij `HEAD` i proveryayet otsutstviye drugoj pishusjhej zadachi po dostupnyim yej nablyudayemyim svideteljstvam. Otsutstviye mashinnogo globaljnogo lock ne razreshayet paralleljnuyu zapisj: pri neodnoznachnosti zadacha ostanavlivayetsya do pervoj mutacii i prosit poljzovatelya ustranitj konkurenciyu.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000061 -->
- Obyichnaya rabota vedyotsya neposredstvenno v pervichnom checkout. Agent ne vyidelyayet linked worktree, otdeljnuyu vetku, assignment, slot, reviewer, integrator ili candidate i ne vyizyivayet FIFO/pool/CAS/branch-next-step kak dejstvuyusjhij marshrut. Subagentyi dopustimyi toljko dlya read-only-analiza; pisatj rabocheye derevo, indeks i istoriyu mozhet lishj kornevaya sessiya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000062 -->
- Itog fiksiruyetsya obyichnyim lokaljnyim `git commit` na `refs/heads/master` posle proverki exact diff, indeksa, zhurnaljnogo otchyota, recency i primenimogo smoke-check. Kommit ne sozdayot i ne peredayot sleduyusjhuyu zadachu. Posle uspeshnogo kommita sessiya vyipolnyayet toljko read-only-proverku rezuljtata i finaljnyij otvet.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000064 -->
- `push`, remote-publikaciya, vneshniye soobsjheniya i drugiye vneshniye effektyi vyipolnyayutsya toljko po otdeljnomu yavnomu zaprosu poljzovatelya. Lokaljnyij kommit sam po sebe publikaciyej ne yavlyayetsya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000066 -->
- Istoricheskiye queue/pool/worktree/review/integration/candidate/CAS/branch-next-step instrumentyi, refs, kvitancii, kartochki i chernovyiye vetki sokhranyayutsya kak proiskhozhdeniye i narabotka. Oni ne dayut aktivnogo prava zapisi, ne udalyayutsya avtomaticheski i mogut vernutjsya v dejstvuyusjhij kontur toljko otdeljnyim poljzovateljskim zaprosom i novyim proverennyim perekhodom pravil.

## Bezopasnostj i publikacionnaya chistota

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000065 -->
- `.obsidian/graph.json` yavlyayetsya lokaljnyim poljzovateljskim sostoyaniyem Obsidian: fajl sokhranyayetsya na diske, ignoriruyetsya Git, ne blokiruyet rabotu, ne vkhodit v kommityi i ne zamenyayetsya libo peresobirayetsya poverkh poljzovateljskogo sostoyaniya toljko iz-za yego izmeneniya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000246 -->
- Proyekt vedyotsya pod licenziyej CC0 1.0 Universal i dolzhen ostavatjsya prigodnyim dlya otkryitoj publikacii.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000247 -->
- V repozitorij ne dolzhnyi popadatj sekretyi, lokaljnyiye sluzhebnyiye fajlyi, vremennyiye artefaktyi i mashinnyij musor.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000248 -->
- Pered kommitom proveryaj `git status --short` i vklyuchaj toljko osmyislennyiye izmeneniya tekusjhej sessii.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:692cceb4c9c449b0c50921ddeafa35e34a6e8a070141d80f863124698e584b55 -->
<!-- FUM-MD-RECENCY:END -->
