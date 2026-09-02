# Otchyot 2026-07-20 16:11:17 MSK - Serializovatj zadachi v vetke

Dlya zadach Codex odnoj imenovannoj Git-vetki realizovan avtomaticheskij posledovateljnyij dopusk. Posle zagruzki i doveriya proyektnoj konfiguracii `UserPromptSubmit` hook dozhidayetsya osvobozhdeniya vetki pered nachalom khoda, `PreToolUse` povtorno podtverzhdayet vladeniye pered podderzhivayemyim lokaljnyim instrumentom, a `Stop` snimayet vladeniye toljko posle chistogo Git-sostoyaniya vne kornevoj `.obsidian/`.

## Resheniya

- Odin snimok `git status` ne prinyat kak dostatochnyij mutex iz-za gonki odnovremennogo starta; on ispoljzuyetsya vmeste s atomarnyim fajlom vladeniya v obsjhem Git-kataloge.
- Perekhodyi serializovanyi obsjhej POSIX-blokirovkoj: nachaljnyij polnostjyu zapisannyij JSON publikuyetsya atomarnyim hard link, a novyij khod togo zhe seansa zamenyayet zapisj vmeste s `turn_id` i `lease_id`.
- Vladeniye privyazano k polnomu `refs/heads/*` i vnutrennemu `session_id` hook: raznyiye vetki mogut rabotatj nezavisimo, a sleduyusjhij khod togo zhe seansa prodolzhayet sobstvennyiye nezakommichennyiye izmeneniya. Shtatnyij `Stop` fenced po `turn_id`, avarijnoye vosstanovleniye — po predvariteljno nablyudyonnomu `lease_id`; vnutrenniye identifikatoryi ne podmenyayut `Codex-Thread-ID`.
- Zapisj soderzhit khyesh identichnosti worktree: posle pereklyucheniya vetki nikakoj drugoj seans ne poluchayet tot zhe worktree poverkh ostavshegosya vladeniya. Hooks ispolnyayut helper iz `HEAD`, a ne yego vozmozhnuyu nezavershyonnuyu rabochuyu kopiyu.
- Zagruzchik buferizuyet vyivod helper i publikuyet yego toljko posle shtatnogo zaversheniya; chastichnyij vyivod pered oshibkoj otbrasyivayetsya v poljzu odnogo sobyitijnogo fail-closed otveta.
- Vidimyiye v `git status` staged-, unstaged-, untracked-, konfliktnyiye i submodule-izmeneniya vne kornevoj `.obsidian/` blokiruyut sleduyusjhuyu zadachu.
- Kornevaya `.obsidian/` isklyuchena toljko iz startovogo barjyera. Yeyo ustojchivyiye izmeneniya po-prezhnemu klassificiruyutsya i kommityatsya po pravilam repozitoriya.
- Detached HEAD i odna vetka, prinuditeljno otkryitaya v neskoljkikh worktree, otklonyayutsya; otdeljnyiye klonyi ne koordiniruyutsya, Windows ne podderzhivayetsya, strogij FIFO i avtomaticheskij stale-TTL ne obesjhayutsya.
- Vnutrennij dedlajn ozhidaniya `85 800` sekund ostavlyayet desyatiminutnyij zapas do host-timeout `86 400` sekund, Git-komandyi i perekhodnaya blokirovka tozhe ogranichenyi po vremeni, a pojmannyiye oshibki hook shtatno vozvrasjhayut otkaz nachatj khod.
- `Stop` traktuyetsya kak konec khoda, a ne dokazannoye smyislovoye zaversheniye vsej zadachi: barjyer serializuyet aktivnyiye khodyi i gryaznuyu fajlovuyu rabotu kak nablyudayemyij proksi.
- Yesli paralleljnyij `Stop` prodolzhil chistyij khod posle osvobozhdeniya, sleduyusjhij `PreToolUse` povtorno poluchayet yesjhyo svobodnuyu vetku ili zapresjhayet instrument posle peredachi novomu vladeljcu; ustarevshij `turn_id` togo zhe seansa tozhe otklonyayetsya.
- Strogij kontrakt trebuyet yedinstvennogo aktivnogo `Stop`, sposobnogo prodolzhitj khod, i zaversheniya pered osvobozhdeniyem vsekh processov i subagentov, sposobnyikh pozdneye zapisatj v repozitorij. `write_stdin`, uzhe dopusjhennyiye processyi, hosted-instrumentyi i specializirovannyiye opt-out-puti ne obrazuyut novyij `PreToolUse`.
- Posle sboya prinuditeljnoye snyatiye dopuskayetsya toljko kak yavnoye vosstanovleniye posle otdeljnogo podtverzhdeniya, chto prezhnyaya zadacha boljshe ne dejstvuyet.

## Proverki

TDD-nabor snachala zafiksiroval otsutstviye scenariya i proyektnyikh hooks, a nezavisimyiye revjyu zatem obnaruzhili gonki povtornogo i prinuditeljnogo osvobozhdeniya, zapozdalyij `Stop` prezhnego khoda togo zhe seansa, prodolzheniye posle paralleljnogo `Stop`, dopusk ustarevshego `turn_id` k instrumentu, lozhnyij uspekh vosstanovleniya otsutstvuyusjhego pokoleniya, obkhod cherez smenu vetki v odnom worktree, ispolneniye gryaznoj kopii helper, neobrabotannyiye oshibki i nedostatochnyij zapas vnutrennego dedlajna. Posle regressionnyikh ispravlenij proshli 36 testov. Oni pokryivayut vidyi Git-izmenenij, isklyucheniye toljko kornevoj `.obsidian/`, odnovremennyij zakhvat, atomarnuyu publikaciyu, otdeljnyiye fences `turn_id` i `lease_id`, `PreToolUse`-ograzhdeniye handoff, polnyij sinteticheskij perekhod mezhdu dvumya zadachami, determinirovanno podtverzhdyonnoye ozhidaniye vtorogo processa, raznyiye vetki v linked worktree, zapret vtoroj sessii posle smenyi vetki, helper iz `HEAD`, idempotentnoye prodolzheniye odnogo seansa, fenced-vosstanovleniye, otsutstvuyusjhij i povrezhdyonnyij lock i detached HEAD.

Struktura novogo navyika uspeshno proverena shtatnyim `quick_validate.py` iz `skill-creator` s vremenno predostavlennoj zavisimostjyu PyYAML. Proyektnyij TOML razobran vstroyennyim runtime Codex, a oficialjnyij spravochnik hooks podtverdil polya sobyitij, turn-scope, project trust, paralleljnoye ispolneniye i pokryitiye tool-hooks. Eksperimentaljnyij app-server `hooks/list` razreshil rovno tri project-hook (`PreToolUse`, `UserPromptSubmit`, `Stop`), odin `Stop`, bez warnings i errors; vse tri poka imeyut `trustStatus=untrusted`. Fakticheskoye srabatyivaniye v novoj zadache trebuyet odnorazovogo prosmotra i doveriya tochnyim opredeleniyam so storonyi poljzovatelya i ne vyidayotsya za uzhe dokazannoye v tekusjhej otkryitoj zadache.

Polnyij smoke-check proshyol 25 shagov: 129 Python-testov, 51 Swift-test, tri sborki ispolnyayemyikh produktov, strogij libo khyesh-privyazannyij Swift-lint, planovyij reyestr, launchers, recency-metki, graf Obsidian i svyaznostj rabochej sessii.

## Prodolzheniye

Posle odobreniya project hooks sleduyet cherez `/hooks` podtverditj, chto vetochnyij barjyer ostayotsya yedinstvennyim continuation-capable `Stop`, i vyipolnitj otdeljnyij integracionnyij probnyij zapusk v dvukh zadachakh odnoj vetki. Pervaya uderzhivayet vladeniye s nezakommichennyim izmeneniyem i ne ostavlyayet pozdnikh pisatelej, vtoraya vidimo zhdyot, zatem avtomaticheski prodolzhayet posle kommita i `Stop`; otdeljno proveryayetsya prodolzheniye togo zhe khoda drugim `Stop` i zapret yego instrumenta posle handoff. Eto proverit poverkhnostj Codex Desktop poverkh uzhe projdennogo lokaljnogo kontrakta skripta.

## Zatronutyiye materialyi

- [paralleljnaya rabota i sliyaniye](../../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [snyatyij barjyer zadach Git-vetki](../../Instrumentyi/fum-branch-task-gate/README.md)
- [pravila povedeniya v repozitorii](../../AGENTS.md)

## Istochniki

- [iskhodnyij zapros 2026-07-20 16:11:17 MSK](zapros.md)
- [oficialjnyij spravochnik Codex Hooks](https://developers.openai.com/codex/hooks)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c5e767f386eb1fc75d0b3d39fc0fbfaa6d844b7ee3f3026beababb233d481b9d -->
<!-- FUM-MD-RECENCY:END -->
