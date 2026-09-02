# Iskhodnyij zapros 2026-08-04 17:51:27 MSK - Perevesti proyektyi na repozitorii submodule s sobstvennyimi ocheredyami

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-08-04 15:48:19 MSK - Shablonizirovatj fajlyi zaprosov i otchyotov](../2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)
- Sleduyusjhij zapros: [2026-08-04 20:45:26 MSK - Formirovatj otchyotyi o zapuskakh testov](../2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)

## Tekst zaprosa

````text
Автозапуск назначил следующий точный шаг FUM:
state: "ready"
status: "ready"
dispatch: "automatic"
requires_completed_card_ids: ["FUM-STEP-0088"]
unmet_required_card_ids: []
record_path: "Планирование/следующие-шаги-веток/master.md"
card_id: "FUM-STEP-0089"
card_path: "Планирование/карточки-шагов/🟡-FUM-STEP-0089-перевести-проекты-на-репозитории-submodule-с-собственными-очередями.md"
card_content_sha256: "sha256:285986b237a868c028e019054736e51c215970eb9f5e59c05e7aa19218b4da18"
project_path: "README.md"
title: "Перевести проекты на репозитории-submodule с собственными очередями"
task: "Закрепить и реализовать контракт, по которому каждый новый самостоятельный проект FUM является отдельным Git-репозиторием, подключённым к родительской памяти как submodule. Проект должен хранить собственный паспорт, правила, очередь записи и рабочий набор следующего шага в своём репозитории; родитель хранит только запись композиции, точный gitlink и маршрут получения результата. Автономная фикстура должна создать проект, выполнить в его клоне один шаг и проверяемо обновить gitlink родителя."
criteria: ["Правила и индекс проектов определяют каталог родительских регистраций и требуют отдельный репозиторий и submodule для каждого нового самостоятельного проекта.","Проектный паспорт в дочернем репозитории хранит цель, собственную репозиторную идентичность, полный ref, границы доступа и публикации, источники, проверки, условие завершения и рабочий набор следующего шага.","Очередь, claim и диспетчер проекта привязаны к его физическому checkout и не используют состояние родительского клона как доказательство допуска или простоя.","Родительская запись хранит вид `project`, путь submodule, URL, точный gitlink, доступ и маршрут передачи, но не дублирует содержательную задачу и внутреннюю очередь проекта.","Пишущий шаг проекта создаёт commit только в отдельном живом клоне проекта; родитель после проверки обновляет gitlink отдельным CAS-интеграционным commit.","Автономные тесты отклоняют обычный вложенный каталог вместо gitlink, проект без паспорта или следующего шага, общий checkout с родителем, неверный gitlink, цикл и недоступный уровень публикации.","Свежий клон композиции восстанавливает точную проектную ревизию, а отсутствие materialized submodule не заставляет родителя угадывать состояние живой ветки проекта.","Поставка использует локальные bare-репозитории и не создаёт внешний проект или сетевой remote."]
selection.policy: "dynamic-readiness-source-history-first-parent-v2"
selection.head: "f041405e8e906f8791d880e207f50fd144df4411"
selection.ready_count: 1
selection.reason: "only_ready"
selection.commit: null
selection.distance: null
selection.matched_paths: []

Полностью прочитай AGENTS.md, Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md и Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md.

Первым видимым сообщением до join выведи дословно:
«Автозапуск назначил карточку FUM-STEP-0089 — Перевести проекты на репозитории-submodule с собственными очередями; ожидаю допуск FIFO.»

Первым инструментальным действием выполни join собственного корневого CODEX_THREAD_ID по контракту очереди. До состояния admitted только жди и ничего не изменяй.

После каждого admitted и до любых записей выполни bind-run с точными --expected-branch-ref, --expected-step-id, --expected-selection-id и --expected-lease-id из непубликуемого runtime-конверта, а также --task-id "$CODEX_THREAD_ID". Затем выполни verify-run с теми же expected-значениями, --task-id "$CODEX_THREAD_ID" и точным --generation из admitted. Только после успеха обеих команд выведи дословно:
«В работу взята карточка FUM-STEP-0089 — Перевести проекты на репозитории-submodule с собственными очередями.»

После подтверждения полностью прочитай переданные record_path, card_path и project_path именно как относительные пути, без добавления корня проекта. Соблюдай границы действий, доступа, публикации и проверки паспорта и начни работу.

При любом mismatch не выводи строку о начале работы. Сообщи дословно:
«Назначение карточки FUM-STEP-0089 — Перевести проекты на репозитории-submodule с собственными очередями не подтверждено; работа не начата.»
Дождись всех способных писать процессов, выполни finish-clean с точными task_id и generation и завершись без записи.

Это обычная корневая сессия по AGENTS.md: выполни карточку, критерии, рабочий набор и применимые проверки, затем заверши локальным атомарным commit+handoff команды очереди без обычного git commit. После committed не выполняй push, publish или какие-либо записи. Успешно созданная задача не вызывает release своего запуска; release разрешён только внешнему восстановлению после host-доказательства окончательной остановки возможной задачи.

Если вместо коммита работа полностью откачена к selection.head, сначала останови всех писателей и проверь чистоту, затем до finish-clean выполни rearm с точными --expected-branch-ref, --expected-step-id, --expected-selection-id, --expected-lease-id из runtime-конверта, --task-id "$CODEX_THREAD_ID" и --generation из admitted. После rearm разрешён только finish-clean; после finished_clean не выполняй никаких записей.

До содержательных изменений выполни контекстный preflight. Учти обязательные накладные расходы полного чтения, происхождения, проверок, recency, полного smoke-check и атомарной передачи. Выполни карточку, если она укладывается в одно свежее контекстное окно; иначе ограничь сессию устойчивой декомпозицией и не выдавай декомпозицию за завершение исходной реализации. Сохраняй корректные automatic/paused/blocked; назначай automatic только безопасным, полномочным и контекстно ограниченным карточкам.

В финале объясни, что публикацию накопленного префикса refs/heads/master подтверждает только ручной push пользователя вне этой задачи, а ручной push не является подтверждением каждой карточки. Затем перейди к вложенному вызову предыдущего абзаца о контекстном preflight и границах сессии.
````

## Identifikator seansa Codex

Codex-Thread-ID: 019fcd3b-7a2d-7b91-92e8-65b3d0cf7fad

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, realizaciya, razdelyonnyiye revjyu i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch` i `collaboration.*` — lokaljnyiye processyi, proveryayemyiye pravki i paralleljnyiye audityi; versii kontraktov otdeljno ne raskryivayutsya.
- Git 2.54.0 (Apple Git-157), Python 3.14.6, Apple Swift 6.4, SwiftPM, XCTest, `swift format` vetki `main`, ripgrep i sistemnyiye komandyi Darwin 27.0.0 arm64 — lokaljnyiye Git-fiksturyi, sborka, testyi, generatoryi i inspekciya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-struktura-papok-zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-proverka-mashinno-lokaljnyikh-putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — FIFO, naznacheniye, vremya sessii, proiskhozhdeniye, planirovaniye, publikacionnaya chistota, recency, graf, svyaznostj i itogovaya priyomka.
- [fum-perevod-obyyavlenij-koda-na-russkij-yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md) — sukhoj plan i token-osoznannyij perevod novogo sostavnogo imeni, inventarizaciya i tochnyij snimok ostatka.

## Proverki

- Pyatj adresnyikh Swift-testov proveryayut zakryituyu roditeljskuyu registraciyu, polnyij local-bare roundtrip, semj fail-closed scenariyev, stabiljnyij inventarj i pobajtovo kanonicheskij otchyot bez vremennyikh putej.
- Proyektnyij i roditeljskij checkout nezavisimo prokhodyat shtatnyiye `validate`, `show`, `claim`, `join`, `bind-run`, `verify-run`, `rearm` i chistoye zaversheniye; ikh sluzhebnyiye refs fizicheski razlichayutsya i ne popadayut v bare-repozitorii.
- Posle prinyatiya proyektnogo commit roditelj obnovlyayet registraciyu i gitlink otdeljnyim CAS-kommitom, zatem live-ref rebyonka operezhayet prinyatyij snimok; svezhij parent-only clone vsyo ravno vosstanavlivayet prezhnij tochnyij gitlink.
- Planovyij reyestr i rabochij nabor podtverzhdayut zaversheniye FUM-STEP-0089 i yedinstvennuyu gotovuyu FUM-STEP-0090. Polnyiye rezuljtatyi pryamyikh vyizovov, vklyuchaya TDD-red i najdennuyu publikacionnuyu oshibku, privedenyi v [otchyote](otchyot.md).

## Povliyal na fajlyi

- [tekusjhij zapros](zapros.md)
- [tekusjhij otchyot](otchyot.md)
- [kornevyiye pravila](../../AGENTS.md)
- [kornevoj README](../../README.md)
- [repozitornaya kompoziciya FUM](../../Glossarij/repozitornaya-kompoziciya-FUM.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [indeks samostoyateljnyikh proyektov](../../Proyektyi/README.md)
- [proveryayemyij mnogoagentnyij Swift-prototip](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/)
- [trebovaniye o repozitornoj kompozicii](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [planovyiye materialyi](../../Planirovaniye/)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0089-перевести-проекты-на-репозитории-submodule-с-собственными-очередями.md`
- [snapshot-test sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [snimok ostatka obyyavlenij koda](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json)
- [iskhodnyij zapros o Git-grafe](../2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [predyidusjhij zapros](../2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)
- [indeks zhurnala](../README.md)
- [indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [graf Obsidian](../../../../../.obsidian/graph.json)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:5f51b1bf6d89c355940267e2098e94069934e1af5c65d61f5e5c1c3485e6b76b -->
<!-- FUM-MD-RECENCY:END -->
