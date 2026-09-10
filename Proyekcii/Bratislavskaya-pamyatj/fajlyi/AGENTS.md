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
- Navyik, chej `SKILL.md` posle razresheniya simvolicheskikh ssyilok nakhoditsya vne tekusjhego checkout, isklyuchyon: yego ne isjhut, ne otkryivayut dazhe dlya ocenki primenimosti ili sravneniya i ne primenyayut nezavisimo ot imeni i opisaniya. Yesli podkhodyasjhego lokaljnogo navyika net, rabotaj po `AGENTS.md` i lokaljnyim materialam bez vneshnego navyika.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000049 -->
- Proyektnaya nastrojka `skills.include_instructions = false` v `.codex/config.toml` isklyuchayet obsjhij katalog navyikov sredyi iz peredavayemyikh agentu instrukcij; lokaljnyiye navyiki vyibirayutsya toljko po yavnyim putyam iz `AGENTS.md` i materialov repozitoriya. Obsjhij smoke-check obyazan otklonyatj otsutstviye ili oslableniye etoj nastrojki, a takzhe lokaljnyij putj navyika, kotoryij posle razresheniya simvolicheskikh ssyilok vyikhodit za korenj checkout.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000050 -->
- Eta granica otnositsya imenno k instrukciyam `SKILL.md`; dostupnyiye instrumentyi sredyi, CLI, MCP i vneshniye servisyi reguliruyutsya otdeljnyimi pravilami zadachi, publikacionnoj chistotyi i reyestra instrumentov.

## Dejstvuyusjhaya skhema s izolyaciyej i paralleljnoj rabotoj

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000054 -->
<!-- FUM-WRITING-MODE: manual-sequential-v1 -->
<!-- FUM-WORKTREE-POLICY: isolated-per-task-v1 -->
<!-- FUM-SESSION-CONTINUATION: explicit-worklist-v1 -->
`manual-sequential-v1` sokhranyayet zapret starogo avtokonvejyera i ogranicheniye odnim pisatelem na derevo; `isolated-per-task-v1` izoliruyet nezavisimyiye zadachi.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000058 -->
- Obyichnuyu pishusjhuyu rabotu poljzovatelj zapuskayet vruchnuyu otdeljnoj kornevoj zadachej Codex. Nezavisimaya zadacha rabotayet paralleljno v otdeljnom Git worktree s sobstvennoj vetkoj `refs/heads/codex/...`; vnutri odnogo dereva dopuskayetsya ne boleye odnoj pishusjhej kornevoj zadachi. V checkout drugoj aktivnoj zadachi agent rabotayet toljko v rezhime chteniya, vklyuchaya yeyo Zhurnal i proizvodnyiye fajlyi.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000059 -->
- Odna pishusjhaya zadacha posledovateljno vyipolnyayet soglasovannyij poljzovatelem obyyom, vklyuchaya utochneniya, i regulyarno fiksiruyet soderzhateljnyiye etapyi lokaljnyimi kommitami. Kommit zavershayet etap, a ne zadachu: dostupnaya soglasovannaya rabota prodolzhayetsya v toj zhe zadache bez novogo zaprosa. Zaversheniye dopustimo posle vyipolneniya vsego obyyoma, yavnoj ostanovki poljzovatelem libo konkretnogo prepyatstviya pri otsutstvii nezavisimoj dostupnoj rabotyi. Kommit ne razreshayet rasshiryatj obyyom; pustyiye kommityi radi periodichnosti ne sozdayutsya. Otdeljnuyu poljzovateljskuyu zadachu agent sozdayot po yavnomu zaprosu; ogranichennyiye docherniye rabotyi delegiruyutsya po pravilu `FUM-ПРАВИЛО-000061`. Kommit i prodolzheniye rabotyi sami po sebe ne zapuskayut continuation, handoff, heartbeat, dispatcher, autostart ili inoj avtomaticheskij follow-up.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000060 -->
- Pered pervoj zapisjyu kazhdogo etapa, v tom chisle posle kommita ili vosstanovleniya svyazi, korenj perechityivayet fakticheskiye `HEAD`, symbolic ref i `AGENTS.md`, fiksiruyet iskhodnyij commit, polnyij ref i fizicheskij korenj sobstvennogo worktree. Po dostupnyim svideteljstvam proveryayet otsutstviye drugogo pisatelya etogo dereva i ref. Neyasnoye vladeniye zapresjhayet zapisj v spornuyu oblastj; drugiye zadachi v otdeljnyikh derevjyakh ne blokiruyut sobstvennuyu rabotu. Vse soderzhateljnyiye komandyi poluchayut yavnyij korenj sobstvennogo worktree.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000061 -->
- Delegiruj nezavisimyij ogranichennyij rezuljtat paralleljno, yesli dostupnyij ispolnitelj pomogayet srokam ili kachestvu; v soglasovannom obyyome povtornoye razresheniye ne trebuyetsya. Pisatelyu naznachayutsya otdeljnyiye worktree i vetka vne chuzhikh checkout; read-only-analiz obkhoditsya bez otdeljnogo dereva. V kazhdom dereve pishet odin naznachennyij ispolnitelj. Korenj zadayot neperesekayusjhiyesya rezuljtatyi, obsjhij kornevoj UUID i granicu integracii, uchityivayet pamyatj, disk i konkurenciyu tyazhyolyikh proverok. Deti soblyudayut te zhe pravila Zhurnala, TDD, profilirovaniya, kommitov i sokhraneniya nezavershyonnogo. Chuzhiye fajlyi, indeksyi, refs i Git-konfiguraciya ostayutsya read-only, obsjhiye Git-obyyektyi etogo ne menyayut. Rezuljtat rebyonka proveryayetsya do integracii; zanyatuyu vetku zhdut, otdeljnaya vetka ne isklyuchayet konfliktov. FIFO/pool/CAS/branch-next-step ne aktivnyi. Po zaprosu nezavisimyiye zadachi vidimyi v Codex Desktop; modelj — po `FUM-ПРАВИЛО-000162`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000062 -->
- Etap fiksiruyetsya lokaljnyim `git commit` svoyej vetki posle proverki exact diff, indeksa, otdeljnogo otchyota, recency i primenimogo smoke-check. Kontroljnaya tochka po `FUM-ПРАВИЛО-000188` sokhranyayet nezavershyonnoye i ne yavlyayetsya finaljnoj priyomkoj. Posle kommita proverj rezuljtat chteniyem, soobsjhi yego v commentary, sverj ostatok s komandami i prinyatyimi rezuljtatami i prodolzhaj dostupnuyu rabotu v tom zhe khode. Pered final vyizovi read-only `Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py --перед-завершением` s kornevyim UUID: kod 3 zapresjhayet final, kod 2 ne razreshayet yego. Polnotu reyestra i smyisl priyomki proveryayet korenj; kontrakt opisan lokaljnyim navyikom svyaznosti. Novyij etap — novaya papka Zhurnala s tem zhe Codex-Thread-ID i istoriyej po `FUM-ПРАВИЛО-НОВОЕ-000006`; zakryityij snimok ne vozobnovlyayetsya. Plan, otvet rebyonka, kommit, chistoye derevo i priyomka etapa ne dokazyivayut zaversheniya vsego obyyoma. Kommit vetki ne oznachayet integracii v `master`.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000064 -->
- Posle kazhdogo kommita svoyej vetki, krome tochnoj `refs/heads/master`, vyipolni obyichnyij push v proverennyij publikacionnyij `origin` bez povtornogo razresheniya. Snachala sverj polnyij ref, commit OID, yedinstvennyij adres naznacheniya i publikacionnuyu chistotu. Otpravlyayetsya toljko etot OID v odnoimyonnuyu vetku: bez force, udaleniya, massovogo push i chuzhikh refs. Uspekh podtverzhdayetsya udalyonnyim OID. Pri otkaze ili neopredelyonnosti proverj udalyonnoye sostoyaniye, sokhrani fakt nedostavki i prodolzhaj nezavisimuyu rabotu; lokaljnyij kommit ne dokazyivayet dostavki. `master`, PR, vneshniye soobsjheniya i drugiye vneshniye effektyi trebuyut otdeljnogo yavnogo zaprosa. Eto poryadok dejstvij agenta, a ne utverzhdeniye o nalichii globaljnogo Git hook.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000066 -->
- Istoricheskiye queue/pool/worktree/review/integration/candidate/CAS/branch-next-step instrumentyi, refs, kvitancii, kartochki i chernovyiye vetki sokhranyayutsya kak proiskhozhdeniye i narabotka. Oni ne dayut aktivnogo prava zapisi, ne udalyayutsya avtomaticheski i mogut vernutjsya v dejstvuyusjhij kontur toljko otdeljnyim poljzovateljskim zaprosom i novyim proverennyim perekhodom pravil.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000011 -->
- Po sokhranyonnomu yavnomu zaprosu korenj vprave podgotovitj odno sliyaniye iskhodnogo `master` M v vedusjhuyu vetku L v otdeljnom linked worktree i svoyej vetke `refs/heads/codex/...` ot L. Do sozdaniya fiksiruyutsya polnyiye OID M/L, ref, fizicheskij korenj i iskhodnaya komanda. M uzhe razreshayet marshrut; kandidat ne razreshayet sobstvennuyu podgotovku. Toljko tekusjhij korenj pishet kandidat, sokhranyaya pervichnyij checkout, yego indeks, `master` i chuzhiye oblasti. Eto ogranichennoye isklyucheniye iz pravil `FUM-ПРАВИЛО-000058`, `FUM-ПРАВИЛО-000060`–`FUM-ПРАВИЛО-000062`.
- Podgotovka i priyomka podchinyayutsya pravilam M. Pravila, nastrojki i proverochnyiye instrumentyi kandidata — predlagayemoye izmeneniye, kotoroye ne oslablyayet dopusk. Vesj ispolnyayemyij priyomochnyij kontur s zavisimostyami beryotsya iz M; kandidat — vkhod. Ssyilki na M ili odnogo zapuskayemogo iz nego fajla nedostatochno. Neprinyatyij kandidat mozhno sokhranitj do gotovnosti dopuska s yavnyim spiskom nedostayusjhikh proverok. Neobkhodimyiye dorabotki dopuska snachala prinimayutsya v `master`, zatem M fiksiruyetsya zanovo i vklyuchayetsya v povtorno proveryayemyij kandidat.
- Priyomka svyazyivayet tochnyiye M, L, derevo i kommit C s roditelyami `[L, M]`; istochnik pravil M otlichayetsya ot predkommitnogo HEAD L v otpechatke proverki. Posle uspekha `master` prodvigayetsya fast-forward do togo zhe C, s proverkoj ozhidayemogo M pri izmenenii ref i soglasovannyim obnovleniyem pervichnyikh checkout i indeksa. Novoye sliyaniye poverkh C ne sozdayotsya. Sdvig M trebuyet obnovleniya kandidata i novoj priyomki. Poka net proverennoj realizacii prodvizheniya, kandidat sokhranyayetsya bez izmeneniya `master`. Isklyucheniye ne razreshayet drugikh pisatelej, FIFO/pool, avtomaticheskikh prodolzhenij ili publikacii.

## Bezopasnostj i publikacionnaya chistota

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000013 -->
- Pri kazhdom poljzovateljskom soobsjhenii i vosstanovlenii zadachi dopolniteljno vyibirayetsya marshrut `диалог`: upravlyayusjhiye soobsjheniya i soderzhateljnyiye otvetyi sokhranyayutsya v Zhurnale sobstvennoj zadachi, ustojchivyiye ukazaniya zakreplyayutsya v kanonicheskikh pravilakh, a susjhestvennaya neodnoznachnostj utochnyayetsya. Rezhim chteniya ne rasshiryayet pravo zapisi: do polucheniya sobstvennogo dereva ispoljzuyetsya razreshyonnyij chernovik vne chuzhogo checkout.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000065 -->
- `.obsidian/graph.json` yavlyayetsya lokaljnyim poljzovateljskim sostoyaniyem Obsidian: fajl sokhranyayetsya na diske, ignoriruyetsya Git, ne blokiruyet rabotu, ne vkhodit v kommityi i ne zamenyayetsya libo peresobirayetsya poverkh poljzovateljskogo sostoyaniya toljko iz-za yego izmeneniya.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000246 -->
- Proyekt vedyotsya pod licenziyej CC0 1.0 Universal i dolzhen ostavatjsya prigodnyim dlya otkryitoj publikacii.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000247 -->
- V repozitorij ne dolzhnyi popadatj sekretyi, lokaljnyiye sluzhebnyiye fajlyi, vremennyiye artefaktyi i mashinnyij musor.
<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000248 -->
- Pered kommitom proveryaj `git status --short` i vklyuchaj toljko osmyislennyiye izmeneniya tekusjhej sessii.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 16:38:28 MSK -->
<!-- content-sha256: sha256:e8d8a207334b33feb04345754bcf0211d83c7d51ce2b0516b7b8bc337373f111 -->
<!-- FUM-MD-RECENCY:END -->
