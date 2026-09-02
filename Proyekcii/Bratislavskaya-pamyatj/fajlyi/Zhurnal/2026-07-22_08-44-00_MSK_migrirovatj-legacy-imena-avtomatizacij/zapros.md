# Iskhodnyij zapros 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-22 04:10:40 MSK - Dobavitj inicializaciyu zaregistrirovannyikh Git submodule](../2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/zapros.md)
- Sleduyusjhij zapros: [2026-07-22 09:33:05 MSK - Snyatj lint isklyucheniye tenevogo redaktora prodolzhenij](../2026-07-22_09-33-05_MSK_snyatj-lint-isklyucheniye-tenevogo-redaktora-prodolzhenij/zapros.md)

## Tekst zaprosa

```text
<codex_delegation>
  <source_thread_id>019f8070-6efb-77c1-b3c3-7be5439b851e</source_thread_id>
  <input>Ты — отдельная обычная корневая задача Codex для рабочей сессии FUM в общей локальной рабочей копии /Users/fum/Projects/FUM.

Переданные точные значения записи следующего шага:
branch_ref: "refs/heads/master"
step_id: "master-fum-step-0033-ready-v1"
record_path: "Планирование/следующие-шаги-веток/master.md"
project_path: "README.md"
task: "Мигрировать точный legacy-набор прежних репозиторных и декларативных имён автоматизаций на живой контракт LinguisticKit без изменения поведения автоматизаций."
criteria: [
  "Результат, описанный в разделе «Задача», создан и сохранён в памяти FUM с явной границей применимости.",
  "Проверки, названные в задаче и опорных материалах, выполнены, а их результат зафиксирован в связанном запросе или журнале.",
  "Статус карточки обновлён по фактическому исходу; веточный выбор не дублирует содержание карточки."
]

Обязательный порядок и границы:
1. До любой мутирующей работы получи собственный точный корневой CODEX_THREAD_ID, полностью прочитай /Users/fum/Projects/FUM/Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md и первым допустимым действием войди через join в общую очередь, передав этот CODEX_THREAD_ID как task_id. Не создавай замену идентификатора. Дожидайся admitted и соблюдай reload_required/ack-head, finish-clean и commit строго по контракту очереди.
2. Полностью прочитай /Users/fum/Projects/FUM/AGENTS.md и проведи обычную рабочую сессию по нему. Сохрани весь этот диспетчерский prompt как исходный материал сессии.
3. Полностью прочитай /Users/fum/Projects/FUM/Инструменты/fum-branch-next-step/SKILL.md.
4. Полностью прочитай переданные record_path и project_path. Считай запись шага и паспорт проекта обязательными входами; соблюдай все заданные ими границы действий, доступа, публикации и проверки.
5. До любых записей выполни fenced show с ожидаемыми branch_ref и step_id. При mismatch заверши без изменений через штатное чистое завершение очереди; не выполняй проектный шаг.
6. Выполни переданную task и все criteria.
7. Перед локальным коммитом замени запись следующего шага новым выбранным готовым шагом со свежим step_id либо установи явное состояние paused, blocked или done. Выполненный готовый шаг не оставляй для повторного запуска.
8. Дождись всех способных позднее записать процессов и субагентов, прогони требуемые проверки, проиндексируй только осмысленные файлы и создай локальный коммит исключительно штатной командой commit очереди, а не обычным git commit.
9. Не освобождай claim этого успешно созданного запуска.</input>
</codex_delegation>
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f8855-763a-7920-bf32-0399725812bf

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-ocheredj-zadach-git-vetki`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-sleduyusjhij-shag-vetki`, `fum-proverka-nazvanij-avtomatizacij`, `fum-reyestr-planirovaniya`, `fum-svezhestj-markdown`, `fum-svezhestj-grafa-obsidian`, `fum-svyaznostj-rabochej-sessii` i `fum-kompleksnaya-proverka-repozitoriya` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya FIFO-dopuska, yedinogo vremeni MSK, fenced-sverki shaga, TDD-proverki imyon, proizvodnogo planirovaniya, sluzhebnoj svezhesti, grafa, svyaznosti i polnogo regressionnogo progona.
- Zhivoj paket LinguisticKit i lokaljnaya Swift-obyortka reyestra imyon — zakreplyonnaya Git-reviziya `837e2ce107b97ee7b9d3344c9fe99142281fe393`; ispoljzovanyi dlya vyichisleniya i povtornoj proverki tochnyikh form `.Cyrl -> .Latn` po tablice `.ru`.
- Codex Desktop, vstroyennoye obnovleniye avtomatizacij i kontraktyi `functions.*` i `collaboration.*` — otdeljnyiye versii kontraktov sredoj ne raskryivayutsya; ispoljzovanyi dlya obnovleniya heartbeat bez izmeneniya raspisaniya, patch-pravok, lokaljnyikh komand, plana i paralleljnyikh read-only auditov.
- Git `2.54.0 (Apple Git-157)`, Python `3.14.6`, Swift `6.4`, Node.js `v26.5.0`, ripgrep `15.2.0`, Zsh `5.9` i sistemnyiye utilityi macOS — versii proverenyi lokaljnyimi komandami; ispoljzovanyi dlya pereimenovanij, testov, sborki, mekhanicheskoj migracii ssyilok, poiska i atomarnoj peredachi ocheredi.

## Povliyal na fajlyi

- Udalyonnyij fajl: `Инструменты/fum-branch-next-step/agents/openai.yaml`
- Udalyonnyij fajl: `Инструменты/fum-request-materials/agents/openai.yaml`
- [`.obsidian/graph.json`](<../../.obsidian/graph.json>)
- [`AGENTS.md`](<../../AGENTS.md>)
- [`README.md`](<../../README.md>)
- [`fum`](<../../fum>)
- [`Глоссарий/автоматизация-FUM.md`](<../../Glossarij/avtomatizaciya-FUM.md>)
- [`Глоссарий/следующий-шаг-ветки.md`](<../../Glossarij/sleduyusjhij-shag-vetki.md>)
- [`Документация/17-воспроизводимые-автоматизации.md`](<../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md>)
- [`Документация/21-LLM-ориентированный-язык-автоматизаций.md`](<../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md>)
- [`Документация/22-архитектура-FUM.md`](<../../Dokumentaciya/22-arkhitektura-FUM.md>)
- [`Документация/27-публичный-upstream-и-форки-памяти.md`](<../../Dokumentaciya/27-publichnyij-upstream-i-forki-pamyati.md>)
- [`Документация/28-реестр-карточек-соответствия-FUM/FUM-MAP-SESSION-01.md`](<../../Dokumentaciya/28-reyestr-kartochek-sootvetstviya-FUM/FUM-MAP-SESSION-01.md>)
- [`Документация/36-паспорт-документационного-прототипа-и-первого-коробочного-среза.md`](<../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md>)
- [`Журнал/2026-06-24_15-45-41_MSK.md`](<../2026-06-24_15-45-41_MSK/otchyot.md>)
- [`Журнал/2026-06-24_16-32-29_MSK.md`](<../2026-06-24_16-32-29_MSK/otchyot.md>)
- [`Журнал/2026-06-29_19-05-53_MSK.md`](<../2026-06-29_19-05-53_MSK/otchyot.md>)
- [`Журнал/2026-07-01_13-32-17_MSK.md`](<../2026-07-01_13-32-17_MSK/otchyot.md>)
- [`Журнал/2026-07-01_13-44-13_MSK.md`](<../2026-07-01_13-44-13_MSK/otchyot.md>)
- [`Журнал/2026-07-01_14-12-17_MSK.md`](<../2026-07-01_14-12-17_MSK/otchyot.md>)
- [`Журнал/2026-07-01_14-31-25_MSK.md`](<../2026-07-01_14-31-25_MSK/otchyot.md>)
- [`Журнал/2026-07-01_14-58-32_MSK.md`](<../2026-07-01_14-58-32_MSK/otchyot.md>)
- [`Журнал/2026-07-01_15-08-04_MSK.md`](<../2026-07-01_15-08-04_MSK/otchyot.md>)
- [`Журнал/2026-07-01_15-35-24_MSK.md`](<../2026-07-01_15-35-24_MSK/otchyot.md>)
- [`Журнал/2026-07-01_15-51-24_MSK.md`](<../2026-07-01_15-51-24_MSK/otchyot.md>)
- [`Журнал/2026-07-01_17-03-14_MSK.md`](<../2026-07-01_17-03-14_MSK/otchyot.md>)
- [`Журнал/2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов.md`](<../2026-07-02_23-01-25_MSK_obnovitj-pravilo-imenovaniya-zaprosov/otchyot.md>)
- [`Журнал/2026-07-03_11-32-14_MSK_исправить-отображение-графа-зависимостей.md`](<../2026-07-03_11-32-14_MSK_ispravitj-otobrazheniye-grafa-zavisimostej/otchyot.md>)
- [`Журнал/2026-07-06_13-26-31_MSK_закрепить-содержательные-названия-chatgpt-импортов.md`](<../2026-07-06_13-26-31_MSK_zakrepitj-soderzhateljnyiye-nazvaniya-chatgpt-importov/otchyot.md>)
- [`Журнал/2026-07-06_14-31-09_MSK_добавить-проверку-регистра-ссылок.md`](<../2026-07-06_14-31-09_MSK_dobavitj-proverku-registra-ssyilok/otchyot.md>)
- [`Журнал/2026-07-10_06-28-42_MSK_исправить-классификацию-запроса.md`](<../2026-07-10_06-28-42_MSK_ispravitj-klassifikaciyu-zaprosa/otchyot.md>)
- [`Журнал/2026-07-14_02-31-47_MSK_добавлять-идентификатор-сеанса-Codex.md`](<../2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/otchyot.md>)
- [`Журнал/2026-07-17_10-25-41_MSK_предотвращать-смещение-времени-сессий.md`](<../2026-07-17_10-25-41_MSK_predotvrasjhatj-smesjheniye-vremeni-sessij/otchyot.md>)
- [`Журнал/2026-07-17_12-20-17_MSK_создать-скрипты-запуска-прототипов.md`](<../2026-07-17_12-20-17_MSK_sozdatj-skriptyi-zapuska-prototipov/otchyot.md>)
- [`Журнал/2026-07-17_12-33-01_MSK_добавить-панель-запуска-прототипов.md`](<../2026-07-17_12-33-01_MSK_dobavitj-panelj-zapuska-prototipov/otchyot.md>)
- [`Журнал/2026-07-18_07-44-15_MSK_провести-ревью-проекта.md`](<../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/otchyot.md>)
- [`Журнал/2026-07-20_15-34-46_MSK_включить-SwiftPM-в-общий-smoke-check.md`](<../2026-07-20_15-34-46_MSK_vklyuchitj-SwiftPM-v-obsjhij-smoke-check/otchyot.md>)
- [`Журнал/2026-07-20_20-06-04_MSK_запускать-следующие-шаги-веток.md`](<../2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/otchyot.md>)
- [`Журнал/2026-07-20_21-22-17_MSK_включить-карточки-требований-в-машинный-плановый-реестр.md`](<../2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/otchyot.md>)
- [`Журнал/2026-07-20_22-05-19_MSK_сделать-повторное-архивирование-источника-атомарным.md`](<../2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/otchyot.md>)
- [`Журнал/2026-07-20_23-08-44_MSK_восстановить-обратные-ссылки-вопросов.md`](<../2026-07-20_23-08-44_MSK_vosstanovitj-obratnyiye-ssyilki-voprosov/otchyot.md>)
- [`Журнал/2026-07-21_10-36-18_MSK_завершить-сквозную-приёмку-архиватора-источников.md`](<../2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/otchyot.md>)
- [`Журнал/2026-07-21_11-32-46_MSK_актуализировать-входные-описания-FUM.md`](<../2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/otchyot.md>)
- [`Журнал/2026-07-21_13-40-42_MSK_актуализировать-форк-и-подключить-LinguisticKit.md`](<../2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/otchyot.md>)
- [`Журнал/2026-07-21_16-51-20_MSK_провести-аудит-задачи-по-паспорту-первого-коробочного-среза.md`](<../2026-07-21_16-51-20_MSK_provesti-audit-zadachi-po-pasportu-pervogo-korobochnogo-sreza/otchyot.md>)
- [`Журнал/2026-07-21_18-31-35_MSK_ввести-последовательную-очередь-сессий-без-hooks.md`](<../2026-07-21_18-31-35_MSK_vvesti-posledovateljnuyu-ocheredj-sessij-bez-hooks/otchyot.md>)
- [`Журнал/2026-07-22_08-44-00_MSK_мигрировать-legacy-имена-автоматизаций.md`](<otchyot.md>)
- [`Журнал/README.md`](<../README.md>)
- [`Запросы/2026-06-22_07-02-40_MSK.md`](<../2026-06-22_07-02-40_MSK/zapros.md>)
- [`Запросы/2026-06-22_07-09-16_MSK.md`](<../2026-06-22_07-09-16_MSK/zapros.md>)
- [`Запросы/2026-06-23_13-26-21_MSK.md`](<../2026-06-23_13-26-21_MSK/zapros.md>)
- [`Запросы/2026-06-23_13-47-38_MSK.md`](<../2026-06-23_13-47-38_MSK/zapros.md>)
- [`Запросы/2026-06-23_17-37-29_MSK.md`](<../2026-06-23_17-37-29_MSK/zapros.md>)
- [`Запросы/2026-06-23_17-45-40_MSK.md`](<../2026-06-23_17-45-40_MSK/zapros.md>)
- [`Запросы/2026-06-23_18-24-05_MSK.md`](<../2026-06-23_18-24-05_MSK/zapros.md>)
- [`Запросы/2026-06-23_18-43-31_MSK.md`](<../2026-06-23_18-43-31_MSK/zapros.md>)
- [`Запросы/2026-06-24_13-25-48_MSK.md`](<../2026-06-24_13-25-48_MSK/zapros.md>)
- [`Запросы/2026-06-24_13-32-11_MSK.md`](<../2026-06-24_13-32-11_MSK/zapros.md>)
- [`Запросы/2026-06-24_14-33-08_MSK.md`](<../2026-06-24_14-33-08_MSK/zapros.md>)
- [`Запросы/2026-06-24_15-45-41_MSK.md`](<../2026-06-24_15-45-41_MSK/zapros.md>)
- [`Запросы/2026-06-24_15-54-42_MSK.md`](<../2026-06-24_15-54-42_MSK/zapros.md>)
- [`Запросы/2026-06-24_16-09-34_MSK.md`](<../2026-06-24_16-09-34_MSK/zapros.md>)
- [`Запросы/2026-06-24_16-22-00_MSK.md`](<../2026-06-24_16-22-00_MSK/zapros.md>)
- [`Запросы/2026-06-24_16-26-47_MSK.md`](<../2026-06-24_16-26-47_MSK/zapros.md>)
- [`Запросы/2026-06-24_16-32-29_MSK.md`](<../2026-06-24_16-32-29_MSK/zapros.md>)
- [`Запросы/2026-06-25_17-59-02_MSK.md`](<../2026-06-25_17-59-02_MSK/zapros.md>)
- [`Запросы/2026-06-25_18-17-22_MSK.md`](<../2026-06-25_18-17-22_MSK/zapros.md>)
- [`Запросы/2026-06-25_18-30-09_MSK.md`](<../2026-06-25_18-30-09_MSK/zapros.md>)
- [`Запросы/2026-06-25_18-36-50_MSK.md`](<../2026-06-25_18-36-50_MSK/zapros.md>)
- [`Запросы/2026-06-25_18-50-18_MSK.md`](<../2026-06-25_18-50-18_MSK/zapros.md>)
- [`Запросы/2026-06-25_18-59-22_MSK.md`](<../2026-06-25_18-59-22_MSK/zapros.md>)
- [`Запросы/2026-06-25_19-18-28_MSK.md`](<../2026-06-25_19-18-28_MSK/zapros.md>)
- [`Запросы/2026-06-25_19-23-10_MSK.md`](<../2026-06-25_19-23-10_MSK/zapros.md>)
- [`Запросы/2026-06-25_19-34-12_MSK.md`](<../2026-06-25_19-34-12_MSK/zapros.md>)
- [`Запросы/2026-06-25_19-50-33_MSK.md`](<../2026-06-25_19-50-33_MSK/zapros.md>)
- [`Запросы/2026-06-26_09-55-41_MSK.md`](<../2026-06-26_09-55-41_MSK/zapros.md>)
- [`Запросы/2026-06-26_10-26-06_MSK.md`](<../2026-06-26_10-26-06_MSK/zapros.md>)
- [`Запросы/2026-06-26_10-34-02_MSK.md`](<../2026-06-26_10-34-02_MSK/zapros.md>)
- [`Запросы/2026-06-26_10-47-01_MSK.md`](<../2026-06-26_10-47-01_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-05-03_MSK.md`](<../2026-06-26_11-05-03_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-13-48_MSK.md`](<../2026-06-26_11-13-48_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-24-11_MSK.md`](<../2026-06-26_11-24-11_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-39-57_MSK.md`](<../2026-06-26_11-39-57_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-47-21_MSK.md`](<../2026-06-26_11-47-21_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-52-42_MSK.md`](<../2026-06-26_11-52-42_MSK/zapros.md>)
- [`Запросы/2026-06-26_11-58-26_MSK.md`](<../2026-06-26_11-58-26_MSK/zapros.md>)
- [`Запросы/2026-06-26_12-05-01_MSK.md`](<../2026-06-26_12-05-01_MSK/zapros.md>)
- [`Запросы/2026-06-26_12-19-03_MSK.md`](<../2026-06-26_12-19-03_MSK/zapros.md>)
- [`Запросы/2026-06-29_10-59-18_MSK.md`](<../2026-06-29_10-59-18_MSK/zapros.md>)
- [`Запросы/2026-06-29_11-53-44_MSK.md`](<../2026-06-29_11-53-44_MSK/zapros.md>)
- [`Запросы/2026-06-29_12-32-43_MSK.md`](<../2026-06-29_12-32-43_MSK/zapros.md>)
- [`Запросы/2026-06-29_12-44-23_MSK.md`](<../2026-06-29_12-44-23_MSK/zapros.md>)
- [`Запросы/2026-06-29_17-50-10_MSK.md`](<../2026-06-29_17-50-10_MSK/zapros.md>)
- [`Запросы/2026-06-29_18-32-13_MSK.md`](<../2026-06-29_18-32-13_MSK/zapros.md>)
- [`Запросы/2026-06-29_19-05-53_MSK.md`](<../2026-06-29_19-05-53_MSK/zapros.md>)
- [`Запросы/2026-07-01_11-34-46_MSK.md`](<../2026-07-01_11-34-46_MSK/zapros.md>)
- [`Запросы/2026-07-01_12-11-27_MSK.md`](<../2026-07-01_12-11-27_MSK/zapros.md>)
- [`Запросы/2026-07-01_13-32-17_MSK.md`](<../2026-07-01_13-32-17_MSK/zapros.md>)
- [`Запросы/2026-07-01_13-44-13_MSK.md`](<../2026-07-01_13-44-13_MSK/zapros.md>)
- [`Запросы/2026-07-01_14-02-57_MSK.md`](<../2026-07-01_14-02-57_MSK/zapros.md>)
- [`Запросы/2026-07-01_14-12-17_MSK.md`](<../2026-07-01_14-12-17_MSK/zapros.md>)
- [`Запросы/2026-07-01_14-31-25_MSK.md`](<../2026-07-01_14-31-25_MSK/zapros.md>)
- [`Запросы/2026-07-01_14-58-32_MSK.md`](<../2026-07-01_14-58-32_MSK/zapros.md>)
- [`Запросы/2026-07-01_15-08-04_MSK.md`](<../2026-07-01_15-08-04_MSK/zapros.md>)
- [`Запросы/2026-07-01_15-19-31_MSK.md`](<../2026-07-01_15-19-31_MSK/zapros.md>)
- [`Запросы/2026-07-01_15-35-24_MSK.md`](<../2026-07-01_15-35-24_MSK/zapros.md>)
- [`Запросы/2026-07-01_15-51-24_MSK.md`](<../2026-07-01_15-51-24_MSK/zapros.md>)
- [`Запросы/2026-07-01_15-59-05_MSK.md`](<../2026-07-01_15-59-05_MSK/zapros.md>)
- [`Запросы/2026-07-01_16-19-24_MSK.md`](<../2026-07-01_16-19-24_MSK/zapros.md>)
- [`Запросы/2026-07-01_16-40-36_MSK.md`](<../2026-07-01_16-40-36_MSK/zapros.md>)
- [`Запросы/2026-07-01_16-46-04_MSK.md`](<../2026-07-01_16-46-04_MSK/zapros.md>)
- [`Запросы/2026-07-01_16-53-59_MSK.md`](<../2026-07-01_16-53-59_MSK/zapros.md>)
- [`Запросы/2026-07-01_17-03-14_MSK.md`](<../2026-07-01_17-03-14_MSK/zapros.md>)
- [`Запросы/2026-07-01_21-07-58_MSK.md`](<../2026-07-01_21-07-58_MSK/zapros.md>)
- [`Запросы/2026-07-01_22-01-43_MSK.md`](<../2026-07-01_22-01-43_MSK/zapros.md>)
- [`Запросы/2026-07-02_10-20-18_MSK.md`](<../2026-07-02_10-20-18_MSK/zapros.md>)
- [`Запросы/2026-07-02_10-51-13_MSK.md`](<../2026-07-02_10-51-13_MSK/zapros.md>)
- [`Запросы/2026-07-02_11-14-15_MSK.md`](<../2026-07-02_11-14-15_MSK/zapros.md>)
- [`Запросы/2026-07-02_11-33-38_MSK.md`](<../2026-07-02_11-33-38_MSK/zapros.md>)
- [`Запросы/2026-07-02_13-36-52_MSK.md`](<../2026-07-02_13-36-52_MSK/zapros.md>)
- [`Запросы/2026-07-02_16-52-56_MSK.md`](<../2026-07-02_16-52-56_MSK/zapros.md>)
- [`Запросы/2026-07-02_20-08-37_MSK.md`](<../2026-07-02_20-08-37_MSK/zapros.md>)
- [`Запросы/2026-07-02_22-17-18_MSK.md`](<../2026-07-02_22-17-18_MSK/zapros.md>)
- [`Запросы/2026-07-02_22-26-37_MSK.md`](<../2026-07-02_22-26-37_MSK/zapros.md>)
- [`Запросы/2026-07-02_22-38-45_MSK.md`](<../2026-07-02_22-38-45_MSK/zapros.md>)
- [`Запросы/2026-07-02_22-43-41_MSK_имена-файлов-запросов.md`](<../2026-07-02_22-43-41_MSK_imena-fajlov-zaprosov/zapros.md>)
- [`Запросы/2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов.md`](<../2026-07-02_23-01-25_MSK_obnovitj-pravilo-imenovaniya-zaprosov/zapros.md>)
- [`Запросы/2026-07-03_08-21-17_MSK_описать-гибридный-мозг-личного-FUM.md`](<../2026-07-03_08-21-17_MSK_opisatj-gibridnyij-mozg-lichnogo-FUM/zapros.md>)
- [`Запросы/2026-07-03_08-43-45_MSK_создать-раздел-пользовательских-историй.md`](<../2026-07-03_08-43-45_MSK_sozdatj-razdel-poljzovateljskikh-istorij/zapros.md>)
- [`Запросы/2026-07-03_09-03-59_MSK_описать-календарно-транспортные-действия-FUM.md`](<../2026-07-03_09-03-59_MSK_opisatj-kalendarno-transportnyiye-dejstviya-FUM/zapros.md>)
- [`Запросы/2026-07-03_11-10-22_MSK_закрепить-форматирование-таблиц-obsidian.md`](<../2026-07-03_11-10-22_MSK_zakrepitj-formatirovaniye-tablic-obsidian/zapros.md>)
- [`Запросы/2026-07-03_11-23-15_MSK_выстроить-граф-зависимостей-коробочной-реализации-FUM.md`](<../2026-07-03_11-23-15_MSK_vyistroitj-graf-zavisimostej-korobochnoj-realizacii-FUM/zapros.md>)
- [`Запросы/2026-07-03_11-32-14_MSK_исправить-отображение-графа-зависимостей.md`](<../2026-07-03_11-32-14_MSK_ispravitj-otobrazheniye-grafa-zavisimostej/zapros.md>)
- [`Запросы/2026-07-03_11-49-25_MSK_зафиксировать-пошаговый-отбор-реализации.md`](<../2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md>)
- [`Запросы/2026-07-03_15-36-48_MSK_уточнить-развилку-гиперсети-и-агентского-цикла.md`](<../2026-07-03_15-36-48_MSK_utochnitj-razvilku-giperseti-i-agentskogo-cikla/zapros.md>)
- [`Запросы/2026-07-06_10-05-34_MSK_интегрировать-содержимое-chatgpt-диалога.md`](<../2026-07-06_10-05-34_MSK_integrirovatj-soderzhimoye-chatgpt-dialoga/zapros.md>)
- [`Запросы/2026-07-06_10-24-52_MSK_описать-нейросеть-как-среду-агентов.md`](<../2026-07-06_10-24-52_MSK_opisatj-nejrosetj-kak-sredu-agentov/zapros.md>)
- [`Запросы/2026-07-06_10-51-33_MSK_интегрировать-диалог-chatgpt-pro.md`](<../2026-07-06_10-51-33_MSK_integrirovatj-dialog-chatgpt-pro/zapros.md>)
- [`Запросы/2026-07-06_13-26-31_MSK_закрепить-содержательные-названия-chatgpt-импортов.md`](<../2026-07-06_13-26-31_MSK_zakrepitj-soderzhateljnyiye-nazvaniya-chatgpt-importov/zapros.md>)
- [`Запросы/2026-07-06_13-34-08_MSK_описать-компиляцию-алгоритмов-в-тензорный-граф.md`](<../2026-07-06_13-34-08_MSK_opisatj-kompilyaciyu-algoritmov-v-tenzornyij-graf/zapros.md>)
- [`Запросы/2026-07-06_13-52-08_MSK_закрепить-Swift-языком-прототипов.md`](<../2026-07-06_13-52-08_MSK_zakrepitj-Swift-yazyikom-prototipov/zapros.md>)
- [`Запросы/2026-07-06_14-31-09_MSK_добавить-проверку-регистра-ссылок.md`](<../2026-07-06_14-31-09_MSK_dobavitj-proverku-registra-ssyilok/zapros.md>)
- [`Запросы/2026-07-06_14-49-39_MSK_описать-иерархию-функций-и-данных.md`](<../2026-07-06_14-49-39_MSK_opisatj-iyerarkhiyu-funkcij-i-dannyikh/zapros.md>)
- [`Запросы/2026-07-06_15-00-09_MSK_уточнить-иерархию-функций-и-данных.md`](<../2026-07-06_15-00-09_MSK_utochnitj-iyerarkhiyu-funkcij-i-dannyikh/zapros.md>)
- [`Запросы/2026-07-08_09-10-55_MSK_описать-структурные-элементы-самоструктуризации.md`](<../2026-07-08_09-10-55_MSK_opisatj-strukturnyiye-elementyi-samostrukturizacii/zapros.md>)
- [`Запросы/2026-07-08_09-21-09_MSK_уточнить-структурные-элементы-FUM.md`](<../2026-07-08_09-21-09_MSK_utochnitj-strukturnyiye-elementyi-FUM/zapros.md>)
- [`Запросы/2026-07-08_10-18-09_MSK_закрепить-память-структурирующих-операторов.md`](<../2026-07-08_10-18-09_MSK_zakrepitj-pamyatj-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_10-34-09_MSK_добавить-источник-памяти-структурирующих-операторов.md`](<../2026-07-08_10-34-09_MSK_dobavitj-istochnik-pamyati-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_10-54-49_MSK_уточнить-уровни-структурирующих-операторов.md`](<../2026-07-08_10-54-49_MSK_utochnitj-urovni-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_11-06-21_MSK_связать-уточнение-памяти-структурирующих-операторов.md`](<../2026-07-08_11-06-21_MSK_svyazatj-utochneniye-pamyati-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_11-25-24_MSK_закрепить-операторы-как-интерфейс-объяснимости.md`](<../2026-07-08_11-25-24_MSK_zakrepitj-operatoryi-kak-interfejs-obyyasnimosti/zapros.md>)
- [`Запросы/2026-07-08_11-37-43_MSK_связать-расширенную-ветку-структурирующих-операторов.md`](<../2026-07-08_11-37-43_MSK_svyazatj-rasshirennuyu-vetku-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_11-49-28_MSK_обобщить-систему-структурирующих-операторов.md`](<../2026-07-08_11-49-28_MSK_obobsjhitj-sistemu-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_11-58-07_MSK_уточнить-внешний-интерфейс-структурирующих-операторов.md`](<../2026-07-08_11-58-07_MSK_utochnitj-vneshnij-interfejs-strukturiruyusjhikh-operatorov/zapros.md>)
- [`Запросы/2026-07-08_12-11-56_MSK_связать-язык-автоматизаций-и-операторную-систему.md`](<../2026-07-08_12-11-56_MSK_svyazatj-yazyik-avtomatizacij-i-operatornuyu-sistemu/zapros.md>)
- [`Запросы/2026-07-08_12-21-45_MSK_связать-операторную-систему-с-графическим-интерфейсом.md`](<../2026-07-08_12-21-45_MSK_svyazatj-operatornuyu-sistemu-s-graficheskim-interfejsom/zapros.md>)
- [`Запросы/2026-07-08_12-38-52_MSK_закрепить-операторную-память-как-ядро-FUM.md`](<../2026-07-08_12-38-52_MSK_zakrepitj-operatornuyu-pamyatj-kak-yadro-FUM/zapros.md>)
- [`Запросы/2026-07-09_10-50-38_MSK_связать-операторную-систему-с-рибосомной-трансляцией.md`](<../2026-07-09_10-50-38_MSK_svyazatj-operatornuyu-sistemu-s-ribosomnoj-translyaciyej/zapros.md>)
- [`Запросы/2026-07-09_11-01-42_MSK_уточнить-роли-в-рибосомной-аналогии.md`](<../2026-07-09_11-01-42_MSK_utochnitj-roli-v-ribosomnoj-analogii/zapros.md>)
- [`Запросы/2026-07-10_05-03-09_MSK_сравнить-варианты-реализации.md`](<../2026-07-10_05-03-09_MSK_sravnitj-variantyi-realizacii/zapros.md>)
- [`Запросы/2026-07-10_05-38-47_MSK_ответить-о-связи-операторов-и-интерфейса-FUM-узла.md`](<../2026-07-10_05-38-47_MSK_otvetitj-o-svyazi-operatorov-i-interfejsa-FUM-uzla/zapros.md>)
- [`Запросы/2026-07-10_05-51-44_MSK_создать-папку-вопросов-и-ответов.md`](<../2026-07-10_05-51-44_MSK_sozdatj-papku-voprosov-i-otvetov/zapros.md>)
- [`Запросы/2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex.md`](<../2026-07-10_05-59-58_MSK_utochnitj-uchyot-versij-ChatGPT-i-Codex/zapros.md>)
- [`Запросы/2026-07-10_06-28-42_MSK_исправить-классификацию-запроса.md`](<../2026-07-10_06-28-42_MSK_ispravitj-klassifikaciyu-zaprosa/zapros.md>)
- [`Запросы/2026-07-10_06-46-29_MSK_дополнить-вопросы-и-ответы-по-всем-запросам.md`](<../2026-07-10_06-46-29_MSK_dopolnitj-voprosyi-i-otvetyi-po-vsem-zaprosam/zapros.md>)
- [`Запросы/2026-07-13_15-20-42_MSK_ограничить-вопросы-и-ответы-сущностью-FUM.md`](<../2026-07-13_15-20-42_MSK_ogranichitj-voprosyi-i-otvetyi-susjhnostjyu-FUM/zapros.md>)
- [`Запросы/2026-07-13_20-34-23_MSK_закрепить-ролевую-семантику-взаимодействия-ИИ-агентов.md`](<../2026-07-13_20-34-23_MSK_zakrepitj-rolevuyu-semantiku-vzaimodejstviya-II-agentov/zapros.md>)
- [`Запросы/2026-07-13_22-00-22_MSK_закрепить-естественный-язык-как-язык-синхронизации-знаний.md`](<../2026-07-13_22-00-22_MSK_zakrepitj-yestestvennyij-yazyik-kak-yazyik-sinkhronizacii-znanij/zapros.md>)
- [`Запросы/2026-07-13_22-50-54_MSK_закрепить-многоуровневую-языковую-синхронизацию.md`](<../2026-07-13_22-50-54_MSK_zakrepitj-mnogourovnevuyu-yazyikovuyu-sinkhronizaciyu/zapros.md>)
- [`Запросы/2026-07-13_23-39-13_MSK_закрепить-парную-архитектуру-человеческого-мозга.md`](<../2026-07-13_23-39-13_MSK_zakrepitj-parnuyu-arkhitekturu-chelovecheskogo-mozga/zapros.md>)
- [`Запросы/2026-07-14_00-14-49_MSK_закрепить-операторы-текста-и-языка-во-внешней-памяти.md`](<../2026-07-14_00-14-49_MSK_zakrepitj-operatoryi-teksta-i-yazyika-vo-vneshnej-pamyati/zapros.md>)
- [`Запросы/2026-07-14_00-36-30_MSK_уточнить-текстовый-состав-памяти-документационного-прототипа-FUM.md`](<../2026-07-14_00-36-30_MSK_utochnitj-tekstovyij-sostav-pamyati-dokumentacionnogo-prototipa-FUM/zapros.md>)
- [`Запросы/2026-07-14_01-15-40_MSK_закрепить-автоматические-семантические-связи-личного-FUM.md`](<../2026-07-14_01-15-40_MSK_zakrepitj-avtomaticheskiye-semanticheskiye-svyazi-lichnogo-FUM/zapros.md>)
- [`Запросы/2026-07-14_01-55-34_MSK_интегрировать-рекурсивную-модель-агента-и-среды.md`](<../2026-07-14_01-55-34_MSK_integrirovatj-rekursivnuyu-modelj-agenta-i-sredyi/zapros.md>)
- [`Запросы/2026-07-14_02-31-47_MSK_добавлять-идентификатор-сеанса-Codex.md`](<../2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md>)
- [`Запросы/2026-07-14_03-18-36_MSK_закрепить-фоновые-задания-для-простоя-LLM.md`](<../2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md>)
- [`Запросы/2026-07-17_10-25-41_MSK_предотвращать-смещение-времени-сессий.md`](<../2026-07-17_10-25-41_MSK_predotvrasjhatj-smesjheniye-vremeni-sessij/zapros.md>)
- [`Запросы/2026-07-17_12-20-17_MSK_создать-скрипты-запуска-прототипов.md`](<../2026-07-17_12-20-17_MSK_sozdatj-skriptyi-zapuska-prototipov/zapros.md>)
- [`Запросы/2026-07-17_12-33-01_MSK_добавить-панель-запуска-прототипов.md`](<../2026-07-17_12-33-01_MSK_dobavitj-panelj-zapuska-prototipov/zapros.md>)
- [`Запросы/2026-07-20_15-34-46_MSK_включить-SwiftPM-в-общий-smoke-check.md`](<../2026-07-20_15-34-46_MSK_vklyuchitj-SwiftPM-v-obsjhij-smoke-check/zapros.md>)
- [`Запросы/2026-07-20_20-06-04_MSK_запускать-следующие-шаги-веток.md`](<../2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md>)
- [`Запросы/2026-07-20_21-22-17_MSK_включить-карточки-требований-в-машинный-плановый-реестр.md`](<../2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md>)
- [`Запросы/2026-07-20_22-05-19_MSK_сделать-повторное-архивирование-источника-атомарным.md`](<../2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md>)
- [`Запросы/2026-07-20_23-08-44_MSK_восстановить-обратные-ссылки-вопросов.md`](<../2026-07-20_23-08-44_MSK_vosstanovitj-obratnyiye-ssyilki-voprosov/zapros.md>)
- [`Запросы/2026-07-21_05-39-00_MSK_сделать-служебные-генераторы-воспроизводимыми.md`](<../2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md>)
- [`Запросы/2026-07-21_10-36-18_MSK_завершить-сквозную-приёмку-архиватора-источников.md`](<../2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md>)
- [`Запросы/2026-07-21_11-32-46_MSK_актуализировать-входные-описания-FUM.md`](<../2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md>)
- [`Запросы/2026-07-21_12-18-37_MSK_закрепить-транслитерацию-названий-автоматизаций.md`](<../2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md>)
- [`Запросы/2026-07-21_13-40-42_MSK_актуализировать-форк-и-подключить-LinguisticKit.md`](<../2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md>)
- [`Запросы/2026-07-21_13-49-43_MSK_доработать-прототип-сбора-клавиатурных-событий.md`](<../2026-07-21_13-49-43_MSK_dorabotatj-prototip-sbora-klaviaturnyikh-sobyitij/zapros.md>)
- [`Запросы/2026-07-21_18-31-35_MSK_ввести-последовательную-очередь-сессий-без-hooks.md`](<../2026-07-21_18-31-35_MSK_vvesti-posledovateljnuyu-ocheredj-sessij-bez-hooks/zapros.md>)
- [`Запросы/2026-07-22_02-59-22_MSK_декомпозировать-предложения-на-карточки-шагов.md`](<../2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md>)
- [`Запросы/2026-07-22_03-38-35_MSK_разрешить-выполнение-доступных-карточек-шагов.md`](<../2026-07-22_03-38-35_MSK_razreshitj-vyipolneniye-dostupnyikh-kartochek-shagov/zapros.md>)
- [`Запросы/2026-07-22_04-10-40_MSK_добавить-инициализацию-зарегистрированных-Git-submodule.md`](<../2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/zapros.md>)
- [`Запросы/2026-07-22_08-44-00_MSK_мигрировать-legacy-имена-автоматизаций.md`](<zapros.md>)
- [`Индексы/markdown-файлы-по-времени-редактирования.md`](<../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md>)
- [`Инструменты/README.md`](<../../Instrumentyi/README.md>)
- [`Инструменты/fum-glossarij/SKILL.md`](<../../Instrumentyi/fum-glossarij/SKILL.md>)
- [`Инструменты/fum-indeks-readme/SKILL.md`](<../../Instrumentyi/fum-indeks-readme/SKILL.md>)
- [`Инструменты/fum-indeks-readme/scripts/check-readme-index.py`](<../../Instrumentyi/fum-indeks-readme/scripts/check-readme-index.py>)
- [`Инструменты/fum-indeks-readme/tests/test_check_readme_index.py`](<../../Instrumentyi/fum-indeks-readme/tests/test_check_readme_index.py>)
- [`Инструменты/fum-kompleksnaya-proverka-repozitoriya/SKILL.md`](<../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md>)
- [`Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py`](<../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py>)
- [`Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-format.json`](<../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-format.json>)
- [`Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json`](<../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json>)
- [`Инструменты/fum-kompleksnaya-proverka-repozitoriya/tests/test_run_smoke_check.py`](<../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/tests/test_run_smoke_check.py>)
- [`Инструменты/fum-materialyi-zaprosov/SKILL.md`](<../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md>)
- [`Инструменты/fum-materialyi-zaprosov/agents/openai.yaml`](<../../Instrumentyi/fum-materialyi-zaprosov/agents/openai.yaml>)
- [`Инструменты/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py`](<../../Instrumentyi/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py>)
- [`Инструменты/fum-materialyi-zaprosov/scripts/source_archive.py`](<../../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py>)
- [`Инструменты/fum-materialyi-zaprosov/tests/fixtures/simple-html/v1/response.body.html`](<../../Instrumentyi/fum-materialyi-zaprosov/tests/fixtures/simple-html/v1/response.body.html>)
- [`Инструменты/fum-materialyi-zaprosov/tests/fixtures/simple-html/v1/response.headers.txt`](<../../Instrumentyi/fum-materialyi-zaprosov/tests/fixtures/simple-html/v1/response.headers.txt>)
- [`Инструменты/fum-materialyi-zaprosov/tests/fixtures/simple-html/v2/response.body.html`](<../../Instrumentyi/fum-materialyi-zaprosov/tests/fixtures/simple-html/v2/response.body.html>)
- [`Инструменты/fum-materialyi-zaprosov/tests/fixtures/simple-html/v2/response.headers.txt`](<../../Instrumentyi/fum-materialyi-zaprosov/tests/fixtures/simple-html/v2/response.headers.txt>)
- [`Инструменты/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py`](<../../Instrumentyi/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py>)
- [`Инструменты/fum-materialyi-zaprosov/tests/test_source_archive_cli.py`](<../../Instrumentyi/fum-materialyi-zaprosov/tests/test_source_archive_cli.py>)
- [`Инструменты/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md`](<../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md>)
- [`Инструменты/fum-moskovskoye-vremya-rabochej-sessii/agents/openai.yaml`](<../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/agents/openai.yaml>)
- [`Инструменты/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py`](<../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py>)
- [`Инструменты/fum-moskovskoye-vremya-rabochej-sessii/tests/test_get_session_time.py`](<../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/tests/test_get_session_time.py>)
- [`Инструменты/fum-obratnyiye-ssyilki-voprosov/SKILL.md`](<../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/SKILL.md>)
- [`Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py`](<../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py>)
- [`Инструменты/fum-obratnyiye-ssyilki-voprosov/tests/test_check_question_backlinks.py`](<../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/tests/test_check_question_backlinks.py>)
- [`Инструменты/fum-ocenki/SKILL.md`](<../../Instrumentyi/fum-ocenki/SKILL.md>)
- [`Инструменты/fum-ocenki/scripts/build-estimate.py`](<../../Instrumentyi/fum-ocenki/scripts/build-estimate.py>)
- [`Инструменты/fum-ocenki/tests/test_build_estimate.py`](<../../Instrumentyi/fum-ocenki/tests/test_build_estimate.py>)
- [`Инструменты/fum-ocheredj-zadach-git-vetki/tests/test_ocheredj_zadach_git_vetki.py`](<../../Instrumentyi/fum-ocheredj-zadach-git-vetki/tests/test_ocheredj_zadach_git_vetki.py>)
- [`Инструменты/fum-proverka-nazvanij-avtomatizacij/SKILL.md`](<../../Instrumentyi/fum-proverka-nazvanij-avtomatizacij/SKILL.md>)
- [`Инструменты/fum-proverka-nazvanij-avtomatizacij/tests/test_proveritj_nazvaniya_avtomatizacij.py`](<../../Instrumentyi/fum-proverka-nazvanij-avtomatizacij/tests/test_proveritj_nazvaniya_avtomatizacij.py>)
- [`Инструменты/fum-proyektnyiye-fajlyi/SKILL.md`](<../../Instrumentyi/fum-proyektnyiye-fajlyi/SKILL.md>)
- [`Инструменты/fum-proyektnyiye-fajlyi/scripts/project_files.py`](<../../Instrumentyi/fum-proyektnyiye-fajlyi/scripts/project_files.py>)
- [`Инструменты/fum-proyektnyiye-fajlyi/tests/test_project_files.py`](<../../Instrumentyi/fum-proyektnyiye-fajlyi/tests/test_project_files.py>)
- [`Инструменты/fum-revjyu-prodelannoj-rabotyi/SKILL.md`](<../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md>)
- [`Инструменты/fum-revjyu-prodelannoj-rabotyi/scripts/build-work-review.py`](<../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/scripts/build-work-review.py>)
- [`Инструменты/fum-revjyu-prodelannoj-rabotyi/tests/test_build_work_review.py`](<../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/tests/test_build_work_review.py>)
- [`Инструменты/fum-reyestr-planirovaniya/SKILL.md`](<../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md>)
- [`Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py`](<../../Instrumentyi/fum-reyestr-planirovaniya/scripts/build-planning-registry.py>)
- [`Инструменты/fum-reyestr-planirovaniya/tests/test_build_planning_registry.py`](<../../Instrumentyi/fum-reyestr-planirovaniya/tests/test_build_planning_registry.py>)
- [`Инструменты/fum-sborka-svodnoj-dokumentacii/SKILL.md`](<../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/SKILL.md>)
- [`Инструменты/fum-sborka-svodnoj-dokumentacii/scripts/build-doc-aggregation.py`](<../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/scripts/build-doc-aggregation.py>)
- [`Инструменты/fum-sborka-svodnoj-dokumentacii/tests/test_build_doc_aggregation.py`](<../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/tests/test_build_doc_aggregation.py>)
- [`Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md`](<../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md>)
- [`Инструменты/fum-sleduyusjhij-shag-vetki/agents/openai.yaml`](<../../Instrumentyi/fum-sleduyusjhij-shag-vetki/agents/openai.yaml>)
- [`Инструменты/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md`](<../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md>)
- [`Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py`](<../../Instrumentyi/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py>)
- [`Инструменты/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py`](<../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py>)
- [`Инструменты/fum-svezhestj-grafa-obsidian/SKILL.md`](<../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md>)
- [`Инструменты/fum-svezhestj-grafa-obsidian/scripts/build-obsidian-graph-recency.py`](<../../Instrumentyi/fum-svezhestj-grafa-obsidian/scripts/build-obsidian-graph-recency.py>)
- [`Инструменты/fum-svezhestj-grafa-obsidian/tests/test_build_obsidian_graph_recency.py`](<../../Instrumentyi/fum-svezhestj-grafa-obsidian/tests/test_build_obsidian_graph_recency.py>)
- [`Инструменты/fum-svezhestj-markdown/SKILL.md`](<../../Instrumentyi/fum-svezhestj-markdown/SKILL.md>)
- [`Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py`](<../../Instrumentyi/fum-svezhestj-markdown/scripts/update-md-recency.py>)
- [`Инструменты/fum-svezhestj-markdown/tests/test_update_md_recency.py`](<../../Instrumentyi/fum-svezhestj-markdown/tests/test_update_md_recency.py>)
- [`Инструменты/fum-svyaznostj-rabochej-sessii/SKILL.md`](<../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md>)
- [`Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py`](<../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py>)
- [`Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py`](<../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py>)
- [`Инструменты/fum-zapusk-prototipov/SKILL.md`](<../../Instrumentyi/fum-zapusk-prototipov/SKILL.md>)
- [`Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py`](<../../Instrumentyi/fum-zapusk-prototipov/scripts/check-prototype-launchers.py>)
- [`Инструменты/fum-zapusk-prototipov/tests/test_check_prototype_launchers.py`](<../../Instrumentyi/fum-zapusk-prototipov/tests/test_check_prototype_launchers.py>)
- [`Инструменты/реестр-названий-автоматизаций.json`](<../../Instrumentyi/reyestr-nazvanij-avtomatizacij.json>)
- [`Инструменты/реестр-системных-приложений-и-инструментов.md`](<../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md>)
- [`Описания/Автоматизации/построение-описания-FUM-для-адресата.md`](<../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md>)
- [`Оценки/README.md`](<../../Ocenki/README.md>)
- [`Оценки/Автоматизации/оценка-выбора-архитектурного-подхода-к-реализации-FUM.json`](<../2026-07-10_05-03-09_MSK_sravnitj-variantyi-realizacii/materialyi/ocenki/ocenka-vyibora-arkhitekturnogo-podkhoda-k-realizacii-FUM.json>)
- [`Оценки/Автоматизации/оценка-трудоёмкости-текущей-памяти-FUM.json`](<../2026-06-29_17-50-10_MSK/materialyi/ocenki/ocenka-trudoyomkosti-tekusjhej-pamyati-FUM.json>)
- [`Оценки/оценка-выбора-архитектурного-подхода-к-реализации-FUM.md`](<../2026-07-10_05-03-09_MSK_sravnitj-variantyi-realizacii/materialyi/ocenki/ocenka-vyibora-arkhitekturnogo-podkhoda-k-realizacii-FUM.md>)
- [`Оценки/оценка-трудоёмкости-текущей-памяти-FUM.md`](<../2026-06-29_17-50-10_MSK/materialyi/ocenki/ocenka-trudoyomkosti-tekusjhej-pamyati-FUM.md>)
- [`Планирование/MVP-кандидаты/01-память-рабочей-сессии/README.md`](<../../Planirovaniye/MVP-kandidatyi/01-pamyatj-rabochej-sessii/README.md>)
- [`Планирование/MVP-кандидаты/02-архивирование-прикрепляемых-материалов/README.md`](<../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md>)
- [`Планирование/MVP-кандидаты/03-глоссарно-документационный-контур/README.md`](<../../Planirovaniye/MVP-kandidatyi/03-glossarno-dokumentacionnyij-kontur/README.md>)
- [`Планирование/README.md`](<../../Planirovaniye/README.md>)
- [`Планирование/дорожная-карта.md`](<../../Planirovaniye/dorozhnaya-karta.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0006-перевести-граф-зависимостей-элементов-коробочной-реализации-FUM-в-машинно-читаемый-слой-планирования.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0006-perevesti-graf-zavisimostej-elementov-korobochnoj-realizacii-FUM-v-mashinno-chitayemyij-sloj-planirovaniya.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0029-добавить-полуавтоматический-аудит-покрытия-раздела-Вопросы-и-ответы.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0029-dobavitj-poluavtomaticheskij-audit-pokryitiya-razdela-Voprosyi-i-otvetyi.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0030-снять-lint-исключение-теневого-редактора-продолжений.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0030-snyatj-lint-isklyucheniye-tenevogo-redaktora-prodolzhenij.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0033-мигрировать-legacy-имена-автоматизаций-на-контракт-LinguisticKit.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0033-migrirovatj-legacy-imena-avtomatizacij-na-kontrakt-LinguisticKit.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0039-актуализировать-входные-описания-FUM-и-корневой-README.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0039-aktualizirovatj-vkhodnyiye-opisaniya-FUM-i-kornevoj-README.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0040-завершить-сквозную-приёмку-архиватора-источников.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0040-zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0043-сделать-recency-граф-Obsidian-и-связностные-обходы-независимыми-от-сегодняшней-даты-и-игнорируемых-каталогов.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0043-sdelatj-recency-graf-Obsidian-i-svyaznostnyiye-obkhodyi-nezavisimyimi-ot-segodnyashnej-datyi-i-ignoriruyemyikh-katalogov.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0044-расширить-общий-fum-kompleksnaya-proverka-repozitoriya-обнаружением-SwiftPM-пакетов-тестами-сборкой-исполняемых-продуктов-и-явным-lint-контрактом.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0044-rasshiritj-obsjhij-fum-kompleksnaya-proverka-repozitoriya-obnaruzheniyem-SwiftPM-paketov-testami-sborkoj-ispolnyayemyikh-produktov-i-yavnyim-lint-kontraktom.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0049-добавить-проверку-регистра-Markdown-ссылок-и-путей.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0049-dobavitj-proverku-registra-Markdown-ssyilok-i-putej.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0051-распространить-нижнее-размещение-справочных-блоков.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0051-rasprostranitj-nizhneye-razmesjheniye-spravochnyikh-blokov.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0052-создать-локальную-автоматизацию-для-ревью-проделанной-работы-и-сохранения-результатов.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0052-sozdatj-lokaljnuyu-avtomatizaciyu-dlya-revjyu-prodelannoj-rabotyi-i-sokhraneniya-rezuljtatov.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0054-уточнить-градации-тепловой-карты-графа-Obsidian.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0054-utochnitj-gradacii-teplovoj-kartyi-grafa-Obsidian.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0055-создать-воспроизводимую-тепловую-карту-графа-Obsidian.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0055-sozdatj-vosproizvodimuyu-teplovuyu-kartu-grafa-Obsidian.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0056-собрать-единый-локальный-smoke-check-репозитория.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0056-sobratj-yedinyij-lokaljnyij-smoke-check-repozitoriya.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0057-расширить-проверку-связности-рабочей-сессии.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0057-rasshiritj-proverku-svyaznosti-rabochej-sessii.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0058-подготовить-машинно-читаемый-плановый-реестр.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0058-podgotovitj-mashinno-chitayemyij-planovyij-reyestr.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0059-подготовить-GitHub-публикацию-репозитория-как-базового-upstream-для-форков-памяти.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0059-podgotovitj-GitHub-publikaciyu-repozitoriya-kak-bazovogo-upstream-dlya-forkov-pamyati.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0060-создать-локальную-автоматизацию-для-оценочных-материалов-Оценки.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0060-sozdatj-lokaljnuyu-avtomatizaciyu-dlya-ocenochnyikh-materialov-Ocenki.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0062-ввести-обновляемые-recency-метки-в-Markdown-файлах-и-общий-индекс.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0062-vvesti-obnovlyayemyiye-recency-metki-v-Markdown-fajlakh-i-obsjhij-indeks.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0065-выделить-автоматическую-проверку-связности-рабочей-сессии.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0065-vyidelitj-avtomaticheskuyu-proverku-svyaznosti-rabochej-sessii.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0067-сделать-карточки-требований-каноническим-входом-планового-реестра.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0067-sdelatj-kartochki-trebovanij-kanonicheskim-vkhodom-planovogo-reyestra.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0068-сделать-повторное-архивирование-одного-URL-атомарной-заменой-управляемого-снимка-через-staging-каталог-и-манифест-файлов.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0068-sdelatj-povtornoye-arkhivirovaniye-odnogo-URL-atomarnoj-zamenoj-upravlyayemogo-snimka-cherez-staging-katalog-i-manifest-fajlov.md>)
- [`Планирование/карточки-шагов/✅-FUM-STEP-0069-восстановить-обратные-ссылки-между-документацией-и-открытыми-вопросами.md`](<../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0069-vosstanovitj-obratnyiye-ssyilki-mezhdu-dokumentaciyej-i-otkryityimi-voprosami.md>)
- [`Планирование/карточки-шагов/README.md`](<../../Planirovaniye/kartochki-shagov/README.md>)
- [`Планирование/направления-проектирования-и-развития/01-память-и-происхождение.md`](<../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md>)
- [`Планирование/направления-проектирования-и-развития/02-автоматизации-и-язык.md`](<../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/02-avtomatizacii-i-yazyik.md>)
- [`Планирование/предложения-о-следующих-шагах.md`](<../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md>)
- [`Планирование/реестр-требований-вариантов-и-кандидатов.json`](<../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json>)
- [`Планирование/сводная-таблица-требований-и-реализаций.md`](<../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md>)
- [`Планирование/следующие-шаги-веток/README.md`](<../../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md>)
- [`Планирование/следующие-шаги-веток/master.md`](<../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md>)
- [`Планирование/стадии/01-документационный-прототип-FUM/README.md`](<../../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md>)
- [`Прототипы/README.md`](<../../Prototipyi/README.md>)
- [`Прототипы/теневой-редактор-продолжений/README.md`](<../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md>)
- [`Прототипы/физические-состояния-клавиш/README.md`](<../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md>)
- [`Ревью/2026-07-01_17-03-14_MSK_ревью-проделанной-работы.md`](<../2026-07-01_17-03-14_MSK/materialyi/revjyu/2026-07-01_17-03-14_MSK_revjyu-prodelannoj-rabotyi.md>)
- [`Ревью/2026-07-18_07-44-15_MSK_ревью-проекта.md`](<../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md>)
- [`Ревью/2026-07-21_16-51-20_MSK_аудит-паспорта-первого-коробочного-среза.md`](<../2026-07-21_16-51-20_MSK_provesti-audit-zadachi-po-pasportu-pervogo-korobochnogo-sreza/materialyi/revjyu/2026-07-21_16-51-20_MSK_audit-pasporta-pervogo-korobochnogo-sreza.md>)
- [`Ревью/2026-07-22_02-25-23_MSK_аудит-паспорта-коробочной-стадии.md`](<../2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md>)
- [`Ревью/README.md`](<../../Revjyu/README.md>)
- [`Ревью/Автоматизации/2026-07-01_17-03-14_MSK_ревью-проделанной-работы.json`](<../2026-07-01_17-03-14_MSK/materialyi/revjyu/2026-07-01_17-03-14_MSK_revjyu-prodelannoj-rabotyi.json>)
- [`Ревью/Автоматизации/2026-07-18_07-44-15_MSK_ревью-проекта.json`](<../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.json>)
- [`Ревью/Автоматизации/2026-07-21_16-51-20_MSK_аудит-паспорта-первого-коробочного-среза.json`](<../2026-07-21_16-51-20_MSK_provesti-audit-zadachi-po-pasportu-pervogo-korobochnogo-sreza/materialyi/revjyu/2026-07-21_16-51-20_MSK_audit-pasporta-pervogo-korobochnogo-sreza.json>)
- [`Ревью/Автоматизации/2026-07-22_02-25-23_MSK_аудит-паспорта-коробочной-стадии.json`](<../2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.json>)

## Khod vyipolneniya

Kornevaya zadacha poluchila tochnyij `CODEX_THREAD_ID`, pervoj mutaciyej voshla v FIFO-ocheredj i byila dopusjhena na pokolenii `736d5988-df67-4a68-ad56-8afb08d4d06f` s bazovyim `HEAD` `d9bda51a4d416d80a2d8f0592a7918ae30b3cf1b`. Do pervoj zapisi fenced-komanda `show` podtverdila tochnyiye `refs/heads/master` i `master-fum-step-0033-ready-v1`; obyazateljnyiye pravila, rabochij nabor, kartochka i kornevoj pasport prochitanyi polnostjyu.

Krasnaya faza TDD zakrepila tochnoye otobrazheniye shestnadcati prezhnikh repozitornyikh imyon i odnogo deklarativnogo imeni. Do realizacii test nablyudayemo perechislil vse shestnadcatj ostavshikhsya legacy-zapisej, a otdeljnaya proverka zagolovka deklarativnoj avtomatizacii snachala obnaruzhila staroye kirillicheskoye otobrazheniye. Posle migracii vse shestnadcatj katalogov poluchili slug iz zhivogo LinguisticKit, deklarativnaya avtomatizaciya — yego otobrazhayemuyu latinskuyu formu, a kanonicheskiye massivyi `legacy` i `legacy_display` stali pustyimi.

Aktivnyiye puti, ssyilki, testovyiye fiksturyi, konfiguracii i vneshnyaya heartbeat-avtomatizaciya perevedenyi na novyiye imena. V heartbeat izmenenyi toljko puti k lokaljnomu kontraktu sleduyusjhego shaga; imya, pyatiminutnoye raspisaniye, aktivnyij status, tip i ostaljnoj prompt sokhranenyi. Istoricheskiye iskhodnyiye tekstyi zaprosov i materialyi `Источники/` ne perepisyivalisj; v istoricheskikh zhurnalakh, revjyu i zaprosakh menyalisj toljko naznacheniya lokaljnyikh Markdown-ssyilok, kotoryiye inache stali byi bityimi posle pereimenovaniya katalogov.

Granica migracii ogranichena identichnostyami avtomatizacij: imena katalogov, deklarativnoye otobrazheniye, ssyilki, puti vyizova i reyestr. Algoritmyi, CLI-parametryi, profili, raspisaniya i povedeniye avtomatizacij ne menyalisj. Gitlink, reviziya, tablica i fork/upstream-kontrakt LinguisticKit sokhranenyi; khyesh vremennogo lint-isklyucheniya obnovlyon toljko potomu, chto zasjhisjhyonnyij snimok vklyuchayet putj peremesjhyonnoj konfiguracii.

`FUM-STEP-0033` perevedena v sostoyaniye `completed`. Vyipolnennoye pokoleniye udaleno iz rabochego nabora `master`; `FUM-STEP-0035` sokhranena kak `blocked`, a sleduyusjhim yedinstvennyim `ready` vyibran lokaljno ogranichennyij `FUM-STEP-0030` so svezhim `master-fum-step-0030-ready-v1` bez kopirovaniya zadachi i kriteriyev kartochki.

## Proverki

- Krasnaya faza proverki imyon ozhidayemo obnaruzhila shestnadcatj legacy-zapisej i prezhnij zagolovok deklarativnoj avtomatizacii; zelyonaya faza proshla `21/21` avtonomnyij test i zhivuyu proverku `19` repozitornyikh avtomatizacij cherez LinguisticKit.
- Vse naboryi testov lokaljnyikh avtomatizacij proshli na perenesyonnyikh putyakh; otdeljno podtverzhdenyi `31/31` test ocheredi, `41/41` test sleduyusjhego shaga, `40/40` testov Git-zavisimostej, `29/29` testov svyaznosti i `14/14` testov smoke-check.
- Rezhim `--list` yedinogo smoke-check snachala ozhidayemo vyiyavil ustarevshij khyesh lint-politiki posle perenosa puti konfiguracii, a posle tochechnogo obnovleniya postroil polnyij plan iz `36` shagov.
- Planovyij reyestr proshyol `19/19` testov, build i validate; vetochnyij validate i fenced `show` podtverdili `master-fum-step-0030-ready-v1` pri sokhranyonnom `blocked`-kandidate.
- Audit podtverdil otsutstviye prezhnikh aktivnyikh katalogov i slug, susjhestvovaniye i tochnyij registr `901` migrirovannoj Markdown-ssyilki, neizmennostj vsekh `231` prezhnikh blokov iskhodnogo teksta zaprosov, `.gitmodules` i gitlink LinguisticKit.
- Recency i teplovaya karta Obsidian peresobranyi; svyaznostj sessii proshla s kazhdyim iz `315` putej tekusjhego Git-sostoyaniya.
- Yedinyij lokaljnyij smoke-check proshyol vse `36/36` shagov: testyi avtomatizacij, SwiftPM, reyestryi, LinguisticKit, prototipyi, voprosyi, README, recency, graf i tekusjhuyu sessiyu.
- `git diff --check` proshyol na itogovom diff.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:6f10c5353eb70b6cf8df52b08b438ac7b3d939e8832ad2505f6cd4e6e4bdb482 -->
<!-- FUM-MD-RECENCY:END -->
