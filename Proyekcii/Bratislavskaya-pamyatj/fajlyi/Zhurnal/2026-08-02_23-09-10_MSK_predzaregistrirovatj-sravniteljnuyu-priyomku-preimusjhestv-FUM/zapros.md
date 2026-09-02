# Iskhodnyij zapros 2026-08-02 23:09:10 MSK - Predzaregistrirovatj sravniteljnuyu priyomku preimusjhestv FUM

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-08-02 21:01:15 MSK - Vozobnovitj raspredelyonnyij progon iz pamyati bez skryitogo konteksta](../2026-08-02_21-01-15_MSK_vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta/zapros.md)
- Sleduyusjhij zapros: [2026-08-03 08:48:44 MSK - Zakrepitj topologiyu i pasport repozitornoj kompozicii FUM](../2026-08-03_08-48-44_MSK_zakrepitj-topologiyu-i-pasport-repozitornoj-kompozicii-FUM/zapros.md)

## Tekst zaprosa

### Исходное сообщение

````text
=== ПУБЛИКУЕМОЕ ТЕЛО ИСХОДНОГО ЗАПРОСА СЕССИИ ===
Автоматически выполнить выбранную карточку следующего шага FUM.

Точные машинно проверенные поля:
state: ready
status: ready
dispatch: automatic
requires_completed_card_ids: ["FUM-STEP-0112","FUM-STEP-0083"]
unmet_required_card_ids: []
record_path: Планирование/следующие-шаги-веток/master.md
card_id: FUM-STEP-0104
card_path: Планирование/карточки-шагов/🟡-FUM-STEP-0104-предзарегистрировать-сравнительную-приёмку-преимуществ-FUM.md
card_content_sha256: sha256:3d79ebbe9646786831587b6674d06f421ecb63cf57b2f11f75469d9ad600d28b
project_path: README.md
title: Предзарегистрировать сравнительную приёмку преимуществ FUM
task: Заполнить карточку эксперимента FUM с предварительно зафиксированным сравнением обычного агентского цикла, контроля с точками восстановления, одноагентного FUM, FUM с отдельным проверяющим и FUM с несколькими различимыми подузлами. Не запускать сетевой, платный или изменяющий чужие репозитории прогон: результатом шага является воспроизводимый протокол будущей приёмки.
criteria:
1. Карточка явно задаёт гипотезу, внешний критерий успеха, политику остановки, повторы и минимальный размер выборки до прогонов.
2. Обычный цикл, точки восстановления, память и рабочие пакеты, отдельный проверяющий и множество подузлов образуют разные варианты; ни один вариант не смешивает два новых воздействия.
3. Модель, runtime, инструменты, бюджеты, политика повторов и критерий завершения сопоставимы между вариантами; неустранимые различия указаны как ограничения.
4. Набор задач включает неоднозначность, скрытые тесты, принудительные прерывания, конфликты и повреждённую память; описана защита от утечки скрытых критериев.
5. Метрики включают успех, ложное завершение, восстановление, сохранность подтверждённого, вмешательства человека, токены, деньги, время, дублирование, конфликты и регрессии.
6. Внешние или платные прогоны, публикация результатов и изменение чужих репозиториев явно вынесены за границу этой карточки и требуют отдельного разрешения.
selection.policy: dynamic-readiness-source-history-first-parent-v2
selection.head: 3f4e7ec6c6f88c164be9bc850ed970fa63db2ac5
selection.ready_count: 1
selection.reason: only_ready
selection.commit: null
selection.distance: null
selection.matched_paths: []

В Запросы/, Журнал/, сообщение коммита и любую иную публикуемую память сохраняй только эту публикуемую часть исходного запроса. Не публикуй runtime-конверт и opaque-значения.

Первым видимым сообщением, до join, выведи дословно:
Автозапуск назначил карточку FUM-STEP-0104 — Предзарегистрировать сравнительную приёмку преимуществ FUM; ожидаю допуск FIFO.

Первым инструментальным действием получи собственный точный корневой CODEX_THREAD_ID только из среды, не публикуй его и выполни join через точный HEAD-bootstrap из Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md. До состояния admitted только жди по контракту FIFO; не изменяй checkout, файлы, индекс, ветки, историю или внешнее состояние. При reload_required перечитай требуемые закоммиченные правила и материалы, точно подтверди новый HEAD через ack-head и снова жди admission.

После каждого admitted и до любой записи выполни:
1) bind-run с --expected-branch-ref, --expected-step-id, --expected-selection-id и --expected-lease-id из FUM-RUNTIME, а также --task-id "$CODEX_THREAD_ID";
2) verify-run с теми же expected-значениями, --task-id "$CODEX_THREAD_ID" и точным --generation из текущего admission.
Обе команды выполняй по Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md. Диспетчер bind-run не выполнял.

Только после точного успеха bind-run и verify-run выведи дословно:
В работу взята карточка FUM-STEP-0104 — Предзарегистрировать сравнительную приёмку преимуществ FUM.

После fenced-подтверждения полностью прочитай AGENTS.md, Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md, Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md, а затем точные переданные record_path, card_path и project_path. Используй эти относительные пути как переданы, не добавляй корень проекта и не конструируй производные пути. Соблюдай паспорт проекта и все границы действий, доступа, публикации и проверок.

Если bind-run или verify-run даёт mismatch, не выводи строку о начале работы. Выведи дословно:
Назначение карточки FUM-STEP-0104 — Предзарегистрировать сравнительную приёмку преимуществ FUM не подтверждено; работа не начата.
Затем дождись завершения всех способных позднее записать процессов, не создавай изменений, выполни finish-clean очереди с точными task_id и generation текущего admission и после finished_clean заверши задачу без записей.

До содержательных изменений выполни контекстный preflight. Учти обязательные накладные расходы чтения правил, навыков и источников, сохранения происхождения сессии, целевых проверок, recency, полного smoke-check и атомарной передачи. Если карточка с высокой вероятностью укладывается в одно свежее контекстное окно, выполни её задачу, критерии, рабочий набор и проверки. Если не укладывается, ограничь сессию устойчивой декомпозицией по контракту карточек, не выдавай декомпозицию за завершение исходной реализации. Сохрани корректные automatic, paused и blocked; назначай automatic только безопасным, полномочным и контекстно ограниченным карточкам с точными зависимостями.

Выполни обычную корневую сессию строго по AGENTS.md. Сохрани происхождение только из публикуемого тела. Заверши локальным атомарным commit+handoff очереди без обычного git commit. Перед передачей дождись всех писателей, проверь осмысленный diff, индексируй только требуемые файлы и выполни обязательные проверки карточки, recency и полный smoke-check. После точного состояния committed не выполняй push, publish, записи, изменения checkout, индекса, refs, истории, очереди или внешнего состояния. Успешно созданная задача не вызывает release своего запуска.

Если вместо коммита ты полностью откатил собственную работу к исходному selection.head, остановил всех писателей и доказал чистоту вне корневой .obsidian/ при пустом индексе, до finish-clean выполни rearm с expected branch_ref, step_id, selection_id и lease_id из FUM-RUNTIME, собственным task_id и точным generation текущего admission. После точного rearmed разрешён только finish-clean. После finished_clean не выполняй никаких записей, rearm или release.

В финале явно объясни: публикацию накопленного префикса refs/heads/master подтверждает только ручной push пользователя вне этой задачи; ручной push не является подтверждением каждой карточки, условием готовности или пошаговым допуском следующего automatic-кандидата.
````

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019fc40c-8745-7a83-b45b-831fcd0fbd72

## Rezuljtat

Predzaregistrirovana kartochka sravniteljnoj eksperimentaljnoj priyomki versii `1`. Ona zadayot shestj variantov s yedinstvennyim novyim vozdejstviyem na sosednyuyu stupenj, odinakovyiye agregatnyiye ogranicheniya, skryityij vneshnij kriterij, `50` zadach pyati sloyov, tri povtora i polnyij plan iz `900` izmeryayemyikh progonov bez rannego analiza.

Protokol opredelyayet podderzhku, oproverzheniye i neodnoznachnostj gipotezyi, retry- i stop-politiku, zasjhitu skryityikh kriteriyev i operacionnyiye metriki uspekha, lozhnogo zaversheniya, vosstanovleniya, sokhrannosti, vmeshateljstv cheloveka, tokenov, deneg, vremeni, dublirovaniya, konfliktov i regressij. Nositelj povrezhdyonnoj pamyati, korrelirovannostj odinakovyikh modelej, provider-nedeterminizm i pragmaticheskij razmer vyiborki sokhranenyi kak ogranicheniya.

Izmeryayemyiye, setevyiye ili platnyiye progonyi ne vyipolnyalisj. Task-manifest, evaluator, provider, oplata, chuzhiye repozitorii i publikaciya rezuljtatov trebuyut otdeljnogo yavnogo razresheniya. FUM-STEP-0104 zavershena, a FUM-STEP-0084 stanovitsya sleduyusjhim vyichislyayemo gotovyim avtomaticheskim kandidatom.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, proyektirovaniye protokola i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command` i `apply_patch` — lokaljnyiye processyi, chteniye i proveryayemyiye pravki; versii instrumentaljnyikh kontraktov otdeljno ne raskryivayutsya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — ocheredj, fenced-zapusk, vremya sessii, planovyij perekhod, recency, graf, svyaznostj i polnyij smoke-check.
- Python `3.14.6`, Git `2.54.0`, ripgrep `15.2.0` i standartnyiye Unix-komandyi — lokaljnaya inspekciya, generatoryi i proverki.

## Proverki

Struktura variativnoj lestnicyi, minimaljnaya vyiborka, obyazateljnyiye metriki, ostanovka, granicyi dostupa i otsutstviye izmeryayemyikh zapuskov proverenyi po kriteriyam FUM-STEP-0104. Planovyij reyestr, vetochnyij whitelist, recency, graf, svyaznostj sessii i polnyij repozitornyij smoke-check proveryayutsya pered atomarnoj peredachej; tochnyiye rezuljtatyi i dliteljnosti sokhranyayutsya v svyazannom zhurnaljnom otchyote.

## Povliyal na fajlyi

- [nastrojki grafa Obsidian](../../../../../.obsidian/graph.json)
- [kornevoye opisaniye proyekta](../../README.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka](../../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)
- [iskhodnyij zapros o kriticheskom analize i prioritetakh razvitiya FUM](../2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros o dekompozicii odnoagentnogo epizoda](../2026-07-30_11-42-13_MSK_dekompozirovatj-realizaciyu-skvoznogo-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij zapros o zamyikanii vozobnovleniya odnoagentnogo epizoda](../2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [predyidusjhij iskhodnyij zapros](../2026-08-02_21-01-15_MSK_vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta/zapros.md)
- [tekusjhij iskhodnyij zapros](zapros.md)
- [zhurnaljnyij otchyot tekusjhej sessii](otchyot.md)
- [indeks zhurnala](../README.md)
- [indeks Markdown-fajlov po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [snapshot-test vyichislyayemogo sleduyusjhego shaga](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [vkhodnaya stranica planirovaniya](../../Planirovaniye/README.md)
- [predregistraciya sravniteljnoj priyomki](../../Planirovaniye/kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md)
- [indeks kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md)
- [zavershyonnaya kartochka FUM-STEP-0104](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0104-predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM.md)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0104-предзарегистрировать-сравнительную-приёмку-преимуществ-FUM.md`
- [mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [trebovaniye o sravniteljnoj eksperimentaljnoj priyomke](../../Trebovaniya/🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md)

## Istochniki

- [kartochka FUM-STEP-0104](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0104-predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM.md)
- [trebovaniye o sravniteljnoj eksperimentaljnoj priyomke](../../Trebovaniya/🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md)
- [shablon kartochki eksperimenta FUM](../../Planirovaniye/shablon-kartochki-eksperimenta-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6955c9fbeaa7c9e6ce0143a6f7d4ff2d90445d56c62f0afd7aa50a77a0589dea -->
<!-- FUM-MD-RECENCY:END -->
