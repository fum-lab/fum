# V4, синтетический no-checkout и границы доказательств

Корневая задача 01a07d3d-d376-7ad2-aafc-67e4c25a67eb. Наблюдатель gpt-6.1-sol; effort неизвестен. Факты специалистов ниже переданы ROOT; собственная память и чужие личные области не проверялись.

Подготовлен private recovery patch /private/tmp/sol-publisher-retry-v4-bounded.patch SHA5713f75c8d8c05e875adeca2d112e3cd81364f6c6f84cc4798c9c9d57ff9a326. Proposed source d5099f380f1a0b553a0fbe60d89004cb3ef1dd78c20e3a3cde057b950d7aec5f, tests4baa83ab9bc675f6f7f49aa9ac5295c2385ad6bb7e0eeea0f41bf58505b90829, UI3270379cd2dd814cc4a16a622215def67a4b1180336dca53324d80caa125f75b. Bases c69f4560d9589c7bbbd96d9587ec8584ce313173ba3459192a3432dcfccc0374 / eedb57cee41b8cec86095a8ba122f50f73b4ab6432d88a248e1f333da3789728 / 28f1a25828861f6b5fcdbeb9ed10db1d778d3705f5fc0cbf82c2655bccdb0e04. Прежние drafts отозваны. Кодер дал независимый статический peer-review; compilation/tests NOT RUN. W2 этим агентом не изменялся.

V4 включает retained latest, bounded backoff, явный stop, injected cancellation-aware fake worker/sleeper и конечные test gates. Добавлены invalid capture→исправление модели с revision+1, отрицательная подмена error↔snapshot при равной revision, duplicate generation, retired address через empty capture, epoch и full-registry API. Production publish сознательно принимает Registry вместо произвольного Envelope; текущие внутренние потребители мигрируются совместно. Внешняя API backward compatibility UNKNOWN и не заявлена. Internal envelope seam требует полного синхронного capture; это не IPC authority. Полный поток событий/взаимодействий человека не отслеживается. Внешний watchdog всё ещё требуется: тестовые deadlines не обеспечивают containment процесса, MainActor или блокирующего реального I/O.

ROOT передал два разных синтетических no-checkout результата. У кодера x.py присутствовал только как blob/index, материализован один txt. У специалиста ядра x.py также только blob/index, материализованы два json/md. В обоих write-tree совпал, отсутствие .py в fixture подтверждено исполнителями. Это свидетельства выбранных собственных фикстур; Git attributes/filters и безопасное применение к реальному дереву не доказаны. Такие проверки не подменяют реальный code-checkpoint admission и не разрешают старый Source/status/diff.

Отдельно ROOT подтвердил инцидент полного checkout кодера с материализацией .py. Его нельзя переименовать в no-checkout успех или поглотить последующими synthetic GREEN. Дополнительные последствия здесь UNKNOWN, повтор/исправление чужого дерева наблюдатель не выполнял.

Главстрой сообщил аддитивный коммит7275342785ce05eb84eaa0b7b88246068ca9691a, исправляющий прежнее утверждение о неподтверждённом effort прошлого коммита. Сообщён push exit0, independent readback не выполнялся. Это атрибутированный факт передачи, не самостоятельная проверка памяти, авторства или всей истории.

Агент не объявляется долгоживущим или автоматически восстанавливающимся: runtime evidence для таких гарантий отсутствует. Поручение, подготовленный patch, статический обзор, compilation, tests, commit, push, интеграция и активация различаются.

Эта личная запись сохраняется по прямому исключению без проверок, хуков, ревью и независимого readback.
