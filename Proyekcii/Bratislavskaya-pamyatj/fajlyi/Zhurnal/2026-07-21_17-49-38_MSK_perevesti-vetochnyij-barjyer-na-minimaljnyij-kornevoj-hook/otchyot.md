# Otchyot 2026-07-21 17:49:38 MSK - Perevesti vetochnyij barjyer na minimaljnyij kornevoj hook

Vetochnyij barjyer uprosjhyon do odnogo kornevogo `UserPromptSubmit` hook. Ustranena tochka otkaza, iz-za kotoroj prinyatyij zapusk subagenta ostavalsya bez dochernego markera i blokirovalsya na pervom lokaljnom instrumente; obsjhij checkout i vidimostj sovokupnogo diff pri etom sokhranenyi.

## Novyij kontrakt

Pervyij kornevoj khod zadachi atomarno zakhvatyivayet imenovannuyu vetku toljko pri otsutstvii drugogo vladeljca i pri chistom dereve vne kornevoj `.obsidian/`. Sleduyusjhiye khodyi togo zhe vnutrennego `session_id` sokhranyayut odin lease nezavisimo ot promezhutochnoj chistotyi dereva. V developer-kontekst kornya peredayutsya tochnyij marker dopuska i otdeljnyij vnutrennij identifikator vladeljca dlya shtatnogo osvobozhdeniya.

Dochernij `UserPromptSubmit` ne menyayet sostoyaniye i nichego ne vyivodit. Subagentyi schitayutsya ispolnitelyami uzhe dopusjhennoj kornevoj zadachi, ne registriruyutsya v barjyere i ne poluchayut otdeljnogo vladeniya. Udalenyi project-hooks `SubagentStart`, `PreToolUse` i `Stop`, a vmeste s nimi — pokoleniye na kazhdyij khod, perekhvat kazhdogo instrumenta i avtomaticheskoye osvobozhdeniye po okonchanii otdeljnogo otveta.

Vladeniye snimayetsya yavnoj sinkhronnoj komandoj toljko posle smyislovogo zaversheniya zadachi, ostanovki vsekh vozmozhnyikh pisatelej, kommita i proverki chistotyi dereva. Gryaznoye derevo otklonyayet shtatnoye osvobozhdeniye. Avarijnoye compare-and-delete vosstanovleniye po predvariteljno nablyudyonnomu `lease_id` sokhraneno bez TTL.

## Prichina vyibora

Predyidusjhaya skhema zavisela ot fakticheskogo doveriya i tochnogo poryadka chetyiryokh hook-sobyitij. V zhivom zapuske `spawn_agent` byil prinyat, no `SubagentStart` ne peredal dochernij marker; zatem `PreToolUse` zablokiroval dazhe read-only-komandu. Otdeljnyiye worktree ne vyibranyi, potomu chto oni ukhudshayut nablyudayemostj obsjhej rabotyi po diff. Minimaljnyij kornevoj hook ostavlyayet mekhanicheskuyu serializaciyu mezhdu kornevyimi zadachami, a vnutrenneye rasparallelivaniye perenosit pod otvetstvennostj uzhe dopusjhennogo kornya.

## Granicyi

Eto kooperativnaya zadacha-urovnevaya zasjhita, a ne poinstrumentaljnyij sandbox. Ona ne perekhvatyivayet pozdnyuyu zapisj uzhe zapusjhennogo processa, hosted-instrumenta ili specializirovannogo puti. Poetomu korenj obyazan dozhdatjsya vsekh dochernikh ispolnitelej pered osvobozhdeniyem i ne pisatj posle nego.

Vremennoye isklyucheniye ogranichivalo migraciyu pravilami, konfiguraciyej, katalogom samoj avtomatizacii i obyazateljnyimi materialami sessii. Obsjhiye proizvodnyiye dokumentyi s istoricheskim opisaniyem prezhnego barjyera ostavlenyi vne etogo kommita; tekusjhij ispolnyayemyij kontrakt opredelyayetsya `AGENTS.md`, `.codex/config.toml` i pasportom `fum-branch-task-gate`.

Posle kommita poljzovatelj dolzhen otkryitj `/hooks`, odobritj tochnoye yedinstvennoye opredeleniye `UserPromptSubmit` i proveritj svezhej kornevoj zadachej fakticheskoye poyavleniye markera i stroki vladeljca. Do etogo proyektnaya zapisj konfiguracii ne dokazyivayet zhivuyu aktivaciyu.

## Proverki

- Vse `34` avtonomnyikh testa vetochnogo barjyera proshli.
- Testyi podtverzhdayut odin neizmenyayemyij lease mezhdu kornevyimi khodami, dochernij no-op dazhe pri nepolnoj dochernej identichnosti, yavnyij handoff posle `release`, zagruzku helper iz `HEAD`, fenced-vosstanovleniye, smenu vetki i konkurenciyu processov.
- Polnyij smoke-check proshyol vse `35` shagov; planovyij reyestr, sleduyusjhij shag `master`, recency-metki i teplovaya karta grafa Obsidian validnyi.
- Sessionnaya svyaznostj, identifikator kornevoj zadachi i podgotovlennoye soobsjheniye kommita proverenyi otdeljnoj lokaljnoj avtomatizaciyej.

## Zatronutyiye materialyi

- [teplovaya karta grafa Obsidian](../../../../../.obsidian/graph.json)
- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [proyektnaya konfiguraciya Codex](../../.codex/config.toml)
- [snyatyij vetochnyij barjyer](../../Instrumentyi/fum-branch-task-gate/README.md)
- [scenarij vetochnogo barjyera](../../Instrumentyi/fum-branch-task-gate/scripts/branch-task-gate.py)
- [istoricheskaya svodka vetochnogo barjyera](../../Instrumentyi/fum-branch-task-gate/README.md)

## Istochniki

- [iskhodnyij zapros migracii](zapros.md)
- [predyidusjhij zapros razresheniya subagentov](../2026-07-21_16-20-02_MSK_razreshitj-rabotu-subagentov-cherez-vetochnyij-barjyer/zapros.md)
- [istoriya vetochnogo barjyera](../../Instrumentyi/fum-branch-task-gate/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:fdd5975e128397dccbd59ceb144e440b18c9c2dd0c42162cc9a1bd6f70304a50 -->
<!-- FUM-MD-RECENCY:END -->
