---
name: fum-ocheredj-zadach-git-vetki
description: Координирует несколько корневых задач Codex в одном локальном Git worktree через переносимую FIFO-очередь, Git compare-and-swap, атомарный commit+handoff и чистое завершение no-op-задач без project hooks и POSIX-блокировок. Используй первым действием корневой задачи, при ожидании предшественника, подтверждении нового HEAD, диагностике очереди и завершении задачи.
---

# Очередь задач Git-ветки

Автоматизация разрешает запускать несколько независимых корневых задач Codex в одной рабочей копии одновременно, но допускает к изменению checkout только одну из них. Порядок строгий: задачи обслуживаются по возрастающему `seq`, который назначен первым успешным compare-and-swap при регистрации. Переупорядочивание, приоритеты и принудительная передача места не поддерживаются.

Это кооперативный контракт `AGENTS.md`, а не project hook. Для штатного запуска не нужны `/hooks`, одобрение определения hook, POSIX `flock`, hard links, сигналы или отдельные действия человека.

## Безопасный вход из HEAD

Все штатные команды очереди используют один HEAD-bootstrap:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . <команда> <аргументы>
```

На системе с другим именем запуска Python используй доступное средство запуска Python 3, сохраняя isolated mode `-I`, код и остальные аргументы. Отдельный аргумент `.` задаёт корень текущего checkout. Isolated mode исключает грязный checkout и пользовательские Python-настройки из поиска импортов. Bootstrap удаляет унаследованные `GIT_*` из среды загрузочного `git show`, игнорирует replace-объекты, ограничивает чтение 30 секундами и добавляет доверенный `--repo-root` после пользовательских аргументов. Сценарий для каждого внутреннего Git-вызова отключает replace-объекты и optional locks и удаляет все унаследованные `GIT_*`, включая trace-файлы, перенаправления репозитория, индекса, object database, namespace и Git-конфигурации. CLI не принимает сокращённые имена параметров. Поэтому ожидающая задача не исполняет незавершённую версию автоматизации из общего diff и не может случайно перенаправить очередь в другой каталог или записать trace в checkout.

Прямой вызов `Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py` из рабочего дерева запрещён в обычной сессии и используется только автономными тестами разработки.

## Регистрация корневой задачи

Первым действием корневая задача получает точный `CODEX_THREAD_ID` из среды и выполняет:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . join --task-id <корневой-CODEX_THREAD_ID> --json
```

Не придумывай замену отсутствующему `CODEX_THREAD_ID`.

Результат `admitted` возвращает `ticket_id`, `seq`, `generation` и `base_head`. Сохрани `task_id` и `generation`: только эта пара разрешает итоговую передачу. Результат `waiting` возвращает текущую позицию и не разрешает изменять файлы, индекс, ветки или внешнее состояние.

Повторный `join` того же владельца или ожидающего билета идемпотентен. Билет не имеет TTL и не удаляется по времени.

## Ожидание

Ожидающая корневая задача вызывает пятиминутные ограниченные ожидания, чтобы не возвращать неизменное состояние в контекст чаще необходимого:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . wait --task-id <корневой-CODEX_THREAD_ID> --timeout-seconds 300 --json
```

Пока состояние равно `waiting`, задача не пишет в checkout и повторяет ограниченный вызов не чаще одного раза в 300 секунд. Внутри одного вызова локальный процесс тихо читает Git-ref и завершается раньше только при переходе в действенное состояние, например `reload_required` или `admitted`; эти внутренние проверки не возвращают управление модели и не расходуют её контекст. Ожидание не создаёт heartbeat blob/ref churn. Более поздний билет не обходит более ранний билет, даже если уже подтвердил текущий `HEAD`.

После коммита предшественника передний билет получает `reload_required`: сохранённый `acknowledged_head` больше не совпадает с текущим `HEAD`. Тогда задача:

1. Читает текущие закоммиченные `AGENTS.md` и этот `SKILL.md` заново, а также материалы, которые изменил предшественник.
2. Получает точный текущий object ID командой `git rev-parse HEAD`.
3. Подтверждает именно его:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . ack-head --task-id <корневой-CODEX_THREAD_ID> --head <object-id-HEAD> --json
```

4. Снова вызывает `wait` и начинает мутирующую работу только после `admitted`.

Собственный ожидающий билет можно снять без влияния на остальных:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . cancel --task-id <корневой-CODEX_THREAD_ID> --ticket-id <собственный-ticket_id> --json
```

Владелец не использует `cancel`: он передаёт очередь через `commit` либо через узкий `finish-clean`, если изменений действительно нет.

## Работа владельца и субагентов

Владелец не переключает ветку и не применяет обычный `git commit`. Он может запускать субагентов параллельно, но они являются частями одной корневой задачи:

- субагенты не регистрируются в очереди и не вызывают её команды;
- корень передаёт им непересекающиеся области файлов и свой корневой `CODEX_THREAD_ID`;
- субагенты не меняют ветки, Git-индекс или историю;
- корень синхронизирует пересечения штатными сообщениями, собирает итоговый diff и сам выполняет проверки;
- до любой передачи корень дожидается каждого процесса и субагента, который способен позднее записать результат.

Так параллельная внутренняя работа остаётся видна в общем diff, но независимые корневые задачи не смешивают незавершённые изменения.

## Чистое завершение без коммита

Если допущенная задача законно не имеет изменений — например, read-only аудит завершился без замечаний или созданная диспетчером задача до первой записи обнаружила несовпадение ожидаемых `branch_ref`/`step_id`, — корень после остановки всех возможных писателей выполняет:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . finish-clean --task-id <корневой-CODEX_THREAD_ID> --generation <generation-из-admitted> --json
```

Команда требует точного владельца и поколения, неизменного `base_head`, чистоты вне корневой `.obsidian/` и отсутствия любых staged-изменений, включая `.obsidian/`. Одна `update-ref --stdin` transaction одновременно проверяет ref ветки и меняет только ref очереди. Это завершение no-op-задачи, а не переупорядочивание или принудительный обход. После `finished_clean` прежняя задача больше ничего не записывает и не запускает писателей.

## Атомарный коммит и передача

Перед завершением владелец формирует полное сообщение коммита по `AGENTS.md`, проверяет `.obsidian/`, индексирует только осмысленные изменения и вызывает:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . commit --task-id <корневой-CODEX_THREAD_ID> --generation <generation-из-admitted> --message-file <путь-к-сообщению> --json
```

Вместо файла допустим `--message '<сообщение>'`; значение `--message-file -` читает сообщение из стандартного ввода.

Команда проверяет неизменность ветки и `base_head`, точное поколение владельца, наличие staged-изменений и отсутствие unstaged-, untracked- или конфликтных путей вне корневой `.obsidian/`. Затем она строит дерево через `git write-tree`, создаёт commit object через `git commit-tree` и одним `git update-ref --stdin` transaction сравнивает и обновляет сразу две ссылки:

- текущую `refs/heads/...` с прежнего `base_head` на новый коммит;
- служебную ссылку очереди с текущего JSON blob на состояние без владельца.

При падении до транзакции не меняется ни одна ссылка; после успешной транзакции изменены обе. Конкурирующие `join`, `ack-head` или `cancel` могут изменить только ссылку очереди, поэтому владелец перечитывает её и повторяет транзакцию, не ослабляя проверку старого `HEAD`. `last_completion` делает повтор ответа после неоднозначного результата идемпотентным. После результата `committed` прежний владелец больше ничего не записывает.

## Диагностика

Состояние очереди читается без изменения:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . status --json
```

Ответ показывает `queue_ref`, `queue_oid`, `branch_ref`, владельца, ожидающие билеты и следующий `seq`. Состояние хранится как канонический JSON blob под `refs/fum/worktree-task-queues/<sha256-идентичности-worktree>`. Запись и передача используют только Git object database и compare-and-swap ссылок, поэтому object ID может быть SHA-1 или SHA-256.

## Отказы и границы

Ни ожидающий билет, ни владелец не имеют TTL. Молчаливо упавшая и долго работающая задача неразличимы без внешнего достоверного сигнала, а автоматическое удаление любого предшественника нарушило бы строгий FIFO. Возобновлённая задача с тем же корневым `CODEX_THREAD_ID` продолжает свой билет или поколение; до допуска она может отменить только собственный билет, а после допуска завершает `commit` или `finish-clean`. Принудительное восстановление потерянной задачи в этой модели не реализовано.

Очередь координирует сотрудничающие задачи одного локального checkout и общего Git-каталога. Она не связывает отдельные клоны и отклоняет одну именованную ветку, принудительно открытую в нескольких worktree. Когда очередь пуста, следующий `join` может привязать тот же worktree к другой именованной ветке. Detached HEAD не поддерживается.

Автоматизация не перехватывает произвольный процесс, который сознательно игнорирует `AGENTS.md`, поэтому корневые задачи обязаны соблюдать протокол. При этом штатный путь полностью машинный и не зависит от hook-поддержки конкретного host или ОС.

## Планировщик следующего шага

Плановый heartbeat не использует очередь как backlog и сам не входит в неё: он не рабочий билет и не меняет checkout, индекс, ветку или историю. Если доступный recent-снимок показывает любую другую активную задачу, он не резервирует шаг и не создаёт автоматическую задачу. Только после двух проверок наблюдаемого простоя он создаёт обычную корневую задачу, которая первым действием проходит тот же `join`. Если после допуска fenced-сверка шага даёт mismatch до первой записи, задача вызывает `finish-clean` и прекращает работу.

## Переход со старого hook

В `.codex/config.toml` нет project hooks. По прежнему пути `Инструменты/fum-branch-task-gate/scripts/branch-task-gate.py` оставлен только минимальный no-op без `SKILL.md`: он позволяет уже открытой сессии с кэшированным старым loader завершить переход и не считается активной автоматизацией. Сама миграционная задача завершает старое владение после обычного коммита; первая следующая корневая задача загружает уже закоммиченную очередь из `HEAD`.

## Проверка

Автономные тесты запускаются без сети и секретов:

```text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocheredj-zadach-git-vetki/tests -p 'test_*.py'
```

Набор из 32 тестов проверяет строгий FIFO при конкурентных `join`, идемпотентность, бессрочность билетов, пятиминутный default read-only ожидания, запрет обхода, собственную отмену до допуска, `finish-clean`, обязательный `reload_required`/`ack-head`, атомарные branch-fenced admission, clean finish и commit+handoff, чистоту рабочего дерева, смену ветки, SHA-1/SHA-256, отсутствие optional stat-cache записи до допуска, явные ошибки постоянных ref locks, isolated-исполнение сценария из буквального `HEAD`, закрепление корня, полную очистку Git-среды и запрет trace-файлов, игнорирование replace-объектов внутри сценария, отсутствие POSIX-примитивов, отсутствие project hooks и переходный no-op.

## Источники требований

- [исходный запрос 2026-07-22 11:17:21 MSK — Увеличить ожидание очереди до пяти минут](../../Запросы/2026-07-22_11-17-21_MSK_увеличить-ожидание-очереди-до-пяти-минут.md)
- [исходный запрос 2026-07-21 18:31:35 MSK — Ввести последовательную очередь сессий без hooks](../../Запросы/2026-07-21_18-31-35_MSK_ввести-последовательную-очередь-сессий-без-hooks.md)
- [исходный запрос 2026-07-21 17:49:38 MSK — Перевести веточный барьер на минимальный корневой hook](../../Запросы/2026-07-21_17-49-38_MSK_перевести-веточный-барьер-на-минимальный-корневой-hook.md)
- [исходный запрос 2026-07-20 16:11:17 MSK — Сериализовать задачи в ветке](../../Запросы/2026-07-20_16-11-17_MSK_сериализовать-задачи-в-ветке.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-22 11:34:19 MSK -->
<!-- content-sha256: sha256:56f61f724629fbb56da92032c1b62df65e4f61e2a34a0148709724d5f63180fe -->
<!-- FUM-MD-RECENCY:END -->
