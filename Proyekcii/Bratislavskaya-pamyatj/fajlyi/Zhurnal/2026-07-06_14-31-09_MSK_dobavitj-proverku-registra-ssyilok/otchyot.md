# Otchyot 2026-07-06 14:31:09 MSK - Dobavitj proverku registra ssyilok

Sessiya dobavila v lokaljnuyu proverku svyaznosti zasjhitu ot oshibki, kotoraya pochti nezametna na nechuvstviteljnyikh k registru fajlovyikh sistemakh: Markdown-ssyilka mozhet otkryivatjsya lokaljno, no lomatjsya na chuvstviteljnoj k registru sisteme iz-za otlichiya `Документация/` ot `документация/` ili pokhozhego raskhozhdeniya.

## Chto izmenilosj

- V [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) dobavlena proverka fakticheskogo registra puti dlya lokaljnyikh Markdown-ssyilok vo vsyom repozitorii.
- Skript [check-session-coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py) teperj isjhet realjnyij putj po komponentam bez uchyota registra i sravnivayet yego s napisaniyem ssyilki.
- Testyi [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py) zakreplyayut sluchaj, kogda ssyilka s nevernyim registrom nakhoditsya v Markdown-fajle vne spiska `## Повлиял на файлы`.
- V [AGENTS.md](../../AGENTS.md), [reyestre instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md), [indekse instrumentov](../../Instrumentyi/README.md) i dokumente o [vosproizvodimyikh avtomatizaciyakh](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md) utochneno, chto registr lokaljnyikh Markdown-ssyilok yavlyayetsya proveryayemyim svojstvom.

## Resheniye

Proverka vstroyena v uzhe obyazateljnyij predkommitnyij kontur, a ne vyinesena v otdeljnuyu ruchnuyu komandu. Tak kazhdaya budusjhaya rabochaya sessiya budet lovitj nevernyij registr lokaljnyikh Markdown-ssyilok vmeste s obyichnoj proverkoj zaprosa, zhurnala, spiska zatronutyikh fajlov, recency-metok i Git-sostoyaniya.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-06_14-31-09_MSK_добавить-проверку-регистра-ссылок.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-06_14-31-09_MSK_добавить-проверку-регистра-ссылок.md`

## Vozmozhnoye prodolzheniye

Otdeljnogo prodolzheniya ne trebuyetsya: zadacha byila realizovana kak chastj susjhestvuyusjhej avtomatizacii i popadayet v yedinyij smoke-check. Yesli v budusjhem poyavyatsya drugiye formatyi ssyilok krome Markdown, ikh stoit dobavitj v etot zhe sloj ili v otdeljnyij proveryayemyij parser.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-06 14:31:09 MSK - Dobavitj proverku registra ssyilok](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ba659b058fb8ad5b9237848f41ee8cee9a7f7f4256fba6fd4a3300b48885fca8 -->
<!-- FUM-MD-RECENCY:END -->
