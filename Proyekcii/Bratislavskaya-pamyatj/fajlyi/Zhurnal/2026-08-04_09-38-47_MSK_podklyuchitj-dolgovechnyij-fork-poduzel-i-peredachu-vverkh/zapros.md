# Iskhodnyij zapros 2026-08-04 09:38:47 MSK - Podklyuchitj dolgovechnyij fork poduzel i peredachu vverkh

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-08-04 02:55:45 MSK - Dobavitj ogranichennoye avtomaticheskoye razresheniye Git konfliktov](../2026-08-04_02-55-45_MSK_dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov/zapros.md)
- Sleduyusjhij zapros: [2026-08-04 12:51:44 MSK - Perevesti obyyavlyayemyij kod na russkij yazyik](../2026-08-04_12-51-44_MSK_perevesti-obyyavlyayemyij-kod-na-russkij-yazyik/zapros.md)

## Tekst zaprosa

````text
Автоматически выполнить выбранную карточку следующего шага FUM со следующими точными машинно проверенными полями show:

state: "ready"
status: "ready"
dispatch: "automatic"
requires_completed_card_ids: [
  "FUM-STEP-0087"
]
unmet_required_card_ids: []
record_path: "Планирование/следующие-шаги-веток/master.md"
card_id: "FUM-STEP-0088"
card_path: "Планирование/карточки-шагов/🟡-FUM-STEP-0088-подключить-долговечный-fork-подузел-и-передачу-вверх.md"
card_content_sha256: "sha256:6733bfc79436faa59730f8624bb2f26af560ad767a2729502e9820329a93e2da"
project_path: "README.md"
title: "Подключить долговечный fork-подузел и передачу вверх"
task: "На автономных локальных bare-репозиториях реализовать регистрацию одного долговечного специализированного подузла — fork отдельного общего upstream ядра FUM без графа живых экземпляров. Родительская assembly должна закрепить проверенный commit дочернего репозитория как submodule, а отдельный живой клон подузла — продолжить собственную ветку, создать кандидатный commit общей пользы, передать его вверх через паспорт и после проверки обновить родительский результат без рекурсивной инициализации самого себя."
criteria: [
  "Локальный fork-подузел имеет устойчивую идентичность, паспорт специализации, отдельные `origin` и `upstream`, полный живой ref, собственные правила, очередь и рабочий набор следующего шага; его `upstream` указывает на ядро без instance-submodules, а не на родительскую assembly.",
  "Родительская композиция хранит путь submodule и точный достижимый gitlink, а материализованный submodule остаётся чистым detached-снимком.",
  "Пишущий шаг выполняется в отдельном живом клоне fork-подузла, публикует кандидатный commit в его ветку и не меняет родительскую рабочую копию.",
  "Передача вверх связывает исходный commit, область общего улучшения, проверки, доступ и родительскую базу; принятие сохраняет исходный commit в родословной либо обновляет gitlink отдельным родительским commit по объявленному маршруту.",
  "Синхронизация подузла с обновившимся upstream не следует за remote автоматически и закрывается отказом при конфликте, несовпавшем OID или нарушении публикационной границы.",
  "Валидатор отклоняет submodule-ссылку на предка и recursive-init, который материализовал бы fork внутри самого себя.",
  "Свежий локальный клон родителя восстанавливает точный снимок подузла, а новый живой клон подузла продолжает сохранённую ветку и её следующий шаг.",
  "Сценарий не требует сети, внешней учётной записи или создания реального GitHub fork; внешнее развёртывание остаётся отдельным разрешённым шагом."
]
selection.policy: "dynamic-readiness-source-history-first-parent-v2"
selection.head: "1d1d6c50106ef749c462a25d7ff71adf25f3ebe9"
selection.ready_count: 1
selection.reason: "only_ready"
selection.commit: null
selection.distance: null
selection.matched_paths: []

Порядок запуска и допуска обязателен:

1. Первым видимым сообщением, ещё до join, выведи ровно: «Автозапуск назначил карточку FUM-STEP-0088 — Подключить долговечный fork-подузел и передачу вверх; ожидаю допуск FIFO.»
2. Первым инструментальным действием получи собственный точный корневой CODEX_THREAD_ID из среды и выполни join по контракту Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md. Не придумывай замену идентификатору. До состояния admitted только жди по FIFO и ничего не изменяй.
3. После каждого admitted и до любых записей выполни:
   python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py bind-run --repo-root . --expected-branch-ref <branch_ref-из-FUM-RUNTIME> --expected-step-id <step_id-из-FUM-RUNTIME> --expected-selection-id <selection_id-из-FUM-RUNTIME> --expected-lease-id <lease_id-из-FUM-RUNTIME> --task-id "$CODEX_THREAD_ID" --json
   Затем выполни:
   python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py verify-run --repo-root . --expected-branch-ref <branch_ref-из-FUM-RUNTIME> --expected-step-id <step_id-из-FUM-RUNTIME> --expected-selection-id <selection_id-из-FUM-RUNTIME> --expected-lease-id <lease_id-из-FUM-RUNTIME> --task-id "$CODEX_THREAD_ID" --generation <generation-из-admitted> --json
4. Только после точного успеха bind-run и verify-run выведи ровно: «В работу взята карточка FUM-STEP-0088 — Подключить долговечный fork-подузел и передачу вверх.»
5. После подтверждения назначения полностью прочитай AGENTS.md, Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md, Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md, а также переданные record_path, card_path и project_path ровно как относительные пути из полей выше, не добавляя корень проекта и не выводя производные пути. Соблюдай границы действий, доступа, публикации и проверки паспорта.
6. Если bind-run или verify-run возвращает mismatch, не выводи строку о взятии в работу. Сообщи ровно: «Назначение карточки FUM-STEP-0088 — Подключить долговечный fork-подузел и передачу вверх не подтверждено; работа не начата.» Дождись завершения всех способных позднее записать процессов, выполни finish-clean очереди с точными task_id и generation текущего допуска и заверши сессию без записи.

До содержательных изменений выполни контекстный preflight. Учти обязательные накладные расходы чтения правил, навыков и источников, сохранения происхождения сессии, целевых проверок, recency, полного smoke-check и атомарной передачи. Если карточка с высокой вероятностью укладывается в одно свежее контекстное окно, выполни её задачу, критерии, рабочий набор и проверки. Если не укладывается, ограничь сессию устойчивой декомпозицией и не выдавай декомпозицию за завершение исходной реализации. Сохраняй корректные automatic, paused и blocked; назначай automatic только безопасным, полномочным и контекстно ограниченным карточкам с точными зависимостями.

Веди обычную корневую сессию строго по AGENTS.md. Сохрани публикуемую часть исходного запроса и происхождение там, где требует паспорт, но никогда не сохраняй ЧАСТЬ 1. Выполни карточку и критерии, обнови рабочий набор, карточки и обязательные проверки. Заверши работу локальным атомарным commit+handoff команды очереди; обычный git commit запрещён. После точного результата committed не выполняй push, publish или какие-либо записи.

Успешно созданная задача не вызывает release своего запуска. Release разрешён только внешнему восстановлению после host-доказательства окончательной остановки возможной задачи.

Если вместо коммита ты полностью откатил всю работу к точному selection.head из публикуемой части, остановил всех возможных писателей и доказал чистоту, до finish-clean выполни:
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py rearm --repo-root . --expected-branch-ref <branch_ref-из-FUM-RUNTIME> --expected-step-id <step_id-из-FUM-RUNTIME> --expected-selection-id <selection_id-из-FUM-RUNTIME> --expected-lease-id <lease_id-из-FUM-RUNTIME> --task-id "$CODEX_THREAD_ID" --generation <generation-из-admitted> --json
После точного rearmed разрешён только немедленный finish-clean. После finished_clean запрещены любые записи, rearm и release.

В финальном сообщении объясни: публикацию накопленного префикса refs/heads/master подтверждает только ручной push пользователя вне этой дочерней задачи; ручной push не является подтверждением каждой карточки, условием готовности или пошаговым допуском.
````

## Identifikator seansa Codex

Codex-Thread-ID: 019fcb75-1688-7da2-8856-0f1ee0c60882

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, realizaciya, razdelyonnyiye audityi i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch` i `collaboration.*` — lokaljnyiye processyi, proveryayemyiye pravki i razdelyonnaya rabota; versii kontraktov otdeljno ne raskryivayutsya.
- Swift, SwiftPM, XCTest, Git, Python 3, ripgrep i standartnyiye sistemnyiye komandyi — realizaciya, nastoyasjhiye lokaljnyiye Git-fiksturyi, sborka, testyi, generatoryi i inspekciya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-struktura-papok-zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — FIFO, naznacheniye shaga, moskovskoye vremya, pamyatj sessii, planirovaniye, recency, graf, svyaznostj i itogovaya priyomka.

## Proverki

- Adresnyiye Swift-testyi proveryayut polnyij lokaljnyij marshrut dolgovechnogo fork-poduzla i zakryityiye otricateljnyiye granicyi na nastoyasjhikh vremennyikh Git-repozitoriyakh.
- Validatoryi rabochego nabora podtverzhdayut 10 kandidatov, yedinstvennuyu gotovuyu FUM-STEP-0089, vosemj runtime-`paused` i odin `blocked`; snapshot-test zakreplyayet tot zhe rezuljtat.
- Reyestr planirovaniya vosproizvodimo peresobran i proveren; struktura zhurnaljnyikh sessij podtverzhdena otdeljnyim validatorom.
- Itogovyiye rezuljtatyi strogoj sborki, lint, polnogo Swift-nabora, publikacionnoj proverki, recency, grafa Obsidian, svyaznosti sessii i obsjhego smoke-check privedenyi v [otchyote](otchyot.md).

## Povliyal na fajlyi

- [tekusjhij zapros](zapros.md)
- [tekusjhij otchyot](otchyot.md)
- [kornevoj README](../../README.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [iskhodnyij zapros o Git-grafe](../2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [predyidusjhij zapros i yego sokhranyonnoye revjyu](../2026-08-04_02-55-45_MSK_dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov/)
- [indeks zhurnala](../README.md)
- [vremennoj indeks Markdown](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [snapshot-test sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [planovyiye materialyi](../../Planirovaniye/)
- [proveryayemyij mnogoagentnyij Swift-prototip](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/)
- [trebovaniya](../../Trebovaniya/)
- [graf Obsidian](../../../../../.obsidian/graph.json)
- [opornaya data svezhesti grafa](../../.obsidian/fum-recency-reference-date)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 14:04:20 MSK -->
<!-- content-sha256: sha256:811c75ce66ea0dcaca86b3db93d5afeabe9bc86d69e90c40579ac3e3d9c36690 -->
<!-- FUM-MD-RECENCY:END -->
