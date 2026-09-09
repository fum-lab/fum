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

## Dejstvuyusjhaya skhema s izolyaciyej i paralleljnoj rabotoj

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000054 -->
<!-- FUM-WRITING-MODE: manual-sequential-v1 -->
<!-- FUM-WORKTREE-POLICY: isolated-per-task-v1 -->
<!-- FUM-SESSION-CONTINUATION: explicit-worklist-v1 -->
Marker `manual-sequential-v1` sokhranyayet sovmestimyij zapret starogo avtokonvejyera. Posledovateljnostj zapisi otnositsya k odnomu rabochemu derevu; razmesjheniye nezavisimyikh zadach zadayot `isolated-per-task-v1`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000058 -->
- Obyichnuyu pishusjhuyu rabotu poljzovatelj zapuskayet vruchnuyu otdeljnoj kornevoj zadachej Codex. Nezavisimaya zadacha rabotayet paralleljno v otdeljnom Git worktree s sobstvennoj vetkoj `refs/heads/codex/...`; vnutri odnogo dereva dopuskayetsya ne boleye odnoj pishusjhej kornevoj zadachi. V checkout drugoj aktivnoj zadachi agent rabotayet toljko v rezhime chteniya, vklyuchaya yeyo Zhurnal i proizvodnyiye fajlyi.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000059 -->
- Obyichnaya pishusjhaya sessiya obrabatyivayet odin soderzhateljnyij zapros i sozdayot odin itogovyij lokaljnyij kommit. Po yavnomu ukazaniyu poljzovatelya postoyannaya sessiya prodolzhayet rabotu v toj zhe zadache i regulyarno sozdayot promezhutochnyiye lokaljnyiye kommityi posle zakonchennyikh soderzhateljnyikh etapov, v tom chisle pered dliteljnoj proverkoj ili sleduyusjhim krupnyim izmeneniyem. Pustyiye kommityi radi periodichnosti ne sozdayutsya. Kazhdaya upravlyayusjhaya komanda i soderzhateljnyij otvet sokhranyayutsya v yeyo Zhurnale. Otdeljnuyu poljzovateljskuyu zadachu Codex agent sozdayot po yavnomu zaprosu poljzovatelya; ogranichennyiye docherniye rabotyi tekusjhej zadachi delegiruyutsya po pravilu `FUM-ПРАВИЛО-000061`. Ni kommit, ni prodolzheniye razreshyonnoj rabotyi sami po sebe ne zapuskayut continuation, handoff, heartbeat, dispatcher, autostart ili inoj avtomaticheskij follow-up.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000060 -->
- Pered pervoj zapisjyu kornevaya zadacha perechityivayet fakticheskiye `HEAD`, symbolic ref i `AGENTS.md`, fiksiruyet iskhodnyij commit, polnyij ref i fizicheskij korenj sobstvennogo worktree. Po dostupnyim svideteljstvam proveryayet otsutstviye drugogo pisatelya imenno etogo dereva i ref. Neyasnoye vladeniye zapresjhayet zapisj v spornuyu oblastj; nalichiye drugikh zadach v otdeljnyikh derevjyakh ne blokiruyet sobstvennuyu rabotu. Vse soderzhateljnyiye komandyi poluchayut yavnyij korenj sobstvennogo worktree.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000061 -->
- Korenj zapuskayet paralleljnuyu dochernyuyu rabotu, kogda vyidelen nezavisimyij ogranichennyij rezuljtat, yestj dostupnyij ispolnitelj i eto pomogayet srokam ili kachestvu. Povtornoye razresheniye na takuyu rabotu v soglasovannom obyyome ne trebuyetsya. Dlya pishusjhego ispolnitelya korenj vyidelyayet otdeljnyiye worktree i vetku vne chuzhikh checkout libo ispoljzuyet uzhe naznachennyiye yemu; dlya read-only-analiza otdeljnoye derevo ne obyazateljno. Obsjhiye Git-obyyektyi ne dayut prava menyatj chuzhiye refs, indeks, konfiguraciyu ili rabochiye fajlyi. Korenj zadayot neperesekayusjhiyesya rezuljtatyi, obsjhij kornevoj identifikator proiskhozhdeniya i granicu integracii, uchityivayet pamyatj, disk i konkurenciyu tyazhyolyikh proverok. V kazhdom dereve pishet toljko naznachennyij ispolnitelj; on soblyudayet te zhe pravila Zhurnala, TDD, profilirovaniya, kommitov i sokhraneniya nezavershyonnoj rabotyi. Itog rebyonka proveryayetsya pered integraciyej; chuzhiye checkout, indeksyi, refs i konfiguraciya ostayutsya v rezhime chteniya. Integraciya v zanyatuyu osnovnuyu vetku otkladyivayetsya do zaversheniya yeyo pisatelya; otdeljnaya vetka sama po sebe ne garantiruyet otsutstviya konfliktov sliyaniya. FIFO/pool/CAS/branch-next-step ne yavlyayutsya dejstvuyusjhim marshrutom, a read-only-nablyudeniye ne dayot polnomochij pisatelya.
Po zaprosu poljzovatelya nezavisimyiye zadachi vidimyi v Codex Desktop; modelj zadayotsya po `FUM-ПРАВИЛО-000162`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000062 -->
- Itog fiksiruyetsya obyichnyim lokaljnyim `git commit` v sobstvennoj vetke sessii posle proverki exact diff, indeksa, zhurnaljnogo otchyota, recency i primenimogo smoke-check. Promezhutochnyij kommit postoyannoj sessii prokhodit otdeljnyij dopusk kontroljnoj tochki po pravilu `FUM-ПРАВИЛО-000188`, sokhranyayet yavnyiye nezavershyonnyiye rabotyi i ne obyyavlyayetsya finaljnoj priyomkoj. Priyomka etapa ne zavershayet yavno razreshyonnuyu postoyannuyu zadachu. Posle lyubogo kommita etapa korenj proveryayet rezuljtat, soobsjhayet yego cherez commentary, perechityivayet sokhranyonnyij perechenj razreshyonnyikh rabot i nachinayet sleduyusjhij dostupnyij punkt v tom zhe khode bez novogo soobsjheniya poljzovatelya. Pered final obyazatelen read-only-vyizov `Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py --перед-завершением` s kornevyim identifikatorom po reyestru v2: kod 3 zapresjhayet final, kod 2 ne razreshayet zaversheniye. Ustojchivyij reyestr `Планирование/задачи/<UUID>/обязательства.json` opisan lokaljnyim navyikom svyaznosti; polnotu komand i smyisl priyomki proveryayet korenj. Dopustimyiye osnovaniya ostanovki — yavnaya komanda poljzovatelya, ischerpaniye soglasovannogo obyyoma libo neobkhodimyij otvet poljzovatelya pri otsutstvii nezavisimoj dostupnoj rabotyi. Posle zakryitogo i zakommichennogo etapa sleduyusjhij poluchayet novuyu papku Zhurnala s tem zhe kornevyim Codex-Thread-ID i novoj v4-istoriyej; zakryityij snimok predyidusjhego etapa ne vozobnovlyayetsya. Kommit, chistoye derevo i uspeshnaya priyomka sami po sebe ne yavlyayutsya osnovaniyem final. V razovoj zadache itogovyij kommit zavershayet soglasovannyij zapros. Kommit ne sozdayot sleduyusjhuyu zadachu; fiksaciyu v svoyej vetke ne vyidayut za integraciyu v `master`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000064 -->
- Posle kazhdogo kommita sobstvennoj rabochej vetki, krome tochnoj `refs/heads/master`, agent samostoyateljno vyipolnyayet obyichnyij push v proverennyij publikacionnyij `origin` bez povtornogo razresheniya. Do otpravki sveryayutsya polnyij ref, tochnyij commit OID, yedinstvennyij adres naznacheniya i publikacionnaya chistota otpravlyayemyikh izmenenij; otpravlyayetsya toljko etot OID v odnoimyonnuyu vetku, bez force, udaleniya, massovogo push ili chuzhikh refs. Uspekh podtverzhdayetsya udalyonnyim OID. Pri otkaze ili neopredelyonnom rezuljtate proveryayetsya udalyonnoye sostoyaniye, sokhranyayetsya fakt nedostavki i prodolzhayetsya nezavisimaya dostupnaya rabota; lokaljnyij kommit ne vyidayotsya za dostavlennyij. `master`, PR, vneshniye soobsjheniya i drugiye vneshniye effektyi trebuyut otdeljnogo yavnogo zaprosa poljzovatelya. Eta obyazannostj vkhodit v agentskij poryadok rabotyi posle kommita i ne utverzhdayet nalichiye globaljnogo Git hook.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000066 -->
- Istoricheskiye queue/pool/worktree/review/integration/candidate/CAS/branch-next-step instrumentyi, refs, kvitancii, kartochki i chernovyiye vetki sokhranyayutsya kak proiskhozhdeniye i narabotka. Oni ne dayut aktivnogo prava zapisi, ne udalyayutsya avtomaticheski i mogut vernutjsya v dejstvuyusjhij kontur toljko otdeljnyim poljzovateljskim zaprosom i novyim proverennyim perekhodom pravil.

## Bezopasnostj i publikacionnaya chistota

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000009 -->
- Pri kazhdom poljzovateljskom soobsjhenii i vosstanovlenii zadachi dopolniteljno vyibirayetsya marshrut `диалог`: upravlyayusjhiye soobsjheniya i soderzhateljnyiye otvetyi sokhranyayutsya v Zhurnale sobstvennoj zadachi, ustojchivyiye ukazaniya zakreplyayutsya v kanonicheskikh pravilakh, a susjhestvennaya neodnoznachnostj utochnyayetsya. Rezhim chteniya ne rasshiryayet pravo zapisi: do polucheniya sobstvennogo dereva ispoljzuyetsya razreshyonnyij chernovik vne chuzhogo checkout.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000065 -->
- `.obsidian/graph.json` yavlyayetsya lokaljnyim poljzovateljskim sostoyaniyem Obsidian: fajl sokhranyayetsya na diske, ignoriruyetsya Git, ne blokiruyet rabotu, ne vkhodit v kommityi i ne zamenyayetsya libo peresobirayetsya poverkh poljzovateljskogo sostoyaniya toljko iz-za yego izmeneniya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000246 -->
- Proyekt vedyotsya pod licenziyej CC0 1.0 Universal i dolzhen ostavatjsya prigodnyim dlya otkryitoj publikacii.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000247 -->
- V repozitorij ne dolzhnyi popadatj sekretyi, lokaljnyiye sluzhebnyiye fajlyi, vremennyiye artefaktyi i mashinnyij musor.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000248 -->
- Pered kommitom proveryaj `git status --short` i vklyuchaj toljko osmyislennyiye izmeneniya tekusjhej sessii.

## Istochnik utochneniya postoyannoj zadachi

- [Ustranitj ostanovku postoyannoj zadachi i vesti paralleljnyiye docherniye rabotyi](Zhurnal/2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/zapros.md).
- [Sozdavatj celesoobraznyiye paralleljnyiye rabotyi i opisatj dejstvuyusjhij poryadok](Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 13:26:34 MSK -->
<!-- content-sha256: sha256:31d8a4afc31e108245f73d4d6629aaff2dde4c9dd58ea0882b4920f1c3d80635 -->
<!-- FUM-MD-RECENCY:END -->
