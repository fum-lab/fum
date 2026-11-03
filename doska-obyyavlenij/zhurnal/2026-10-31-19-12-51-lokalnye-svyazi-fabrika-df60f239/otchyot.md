# Отчёт: передать локальные связи расселения

## Результат

Создана одна запись по уже принятому контракту `fum.объявление-доски-объявлений.1`: [`lokalnye-svyazi-fabrika-df60f239.json`](../../zapisi/lokalnye-svyazi-fabrika-df60f239.json). В ней закреплены ROOT-источник и три опубликованных handoff, получатели «фабрика-агентов» и «координаторы», точные версии, пути, Git blob и SHA-256 сырых байтов. Отдельно сохранены доставка, получение потребителем, приёмка ROOT и применение. Не добавлялись scheduler, новый реестр, runtime или валидатор.

Снимок: коммит `795097e54796941174316f05f04f5bec5c524392`, дерево `fdc8304ee50fd27bffbb35c712d9033e43fa3f00`, родитель `cac396ad8bd9563040b54b9fcd64740cb8178e91`. Автор коммита: `FUM Codex [gpt-6-luna; effort=max] <fum@local>`; committer: `FUM <fum@local>`. Обычная отправка точного OID выполнена, `git ls-remote` подтвердил `795097e54796941174316f05f04f5bec5c524392` на `refs/heads/fum-lab/fum/doska-obyyavlenij/potreby-01a17815`.

Команда чтения соседним узлом:

```sh
git show 795097e54796941174316f05f04f5bec5c524392:doska-obyyavlenij/zapisi/lokalnye-svyazi-fabrika-df60f239.json
```

## Статусы источников

- ROOT `df60f239c178a6b3bd9274ce190385089579b706`: переданный текущий ROOT-контекст и удалённая вершина `fum-lab/fum/master`; ROOT-приёмка зафиксирована как исходная база. Получение фабрикой/координаторами не подтверждено, применение `false`.
- Source `60a124f5ad1dbb3ea89526bb3b79768ad52868d9`: опубликованная вершина `fum-lab/fum/istochniki/master`; ROOT-приёмка в передаче не подтверждена, получение потребителем неизвестно, применение `false`.
- Требования `ede9725a6e179f0998ef25d60f4637be1d13dc14`: опубликованная ветка `fum-lab/fum/trebovaniya/prinyatj-utochneniya-fuma`, удалённая вершина `aee7888b7d92bf580ab0ecefff0edcdce479b85e`; commit handoff входит в неё. ROOT-приёмка `false` по прямой передаче ROOT; получение потребителем неизвестно, применение `false`.
- Правила `ee993b1e0f9b4bdfa8b87fb635095063deeee708`: опубликованная вершина `fum-lab/fum/pravila/iyerarkhiya-vetok/master`. ROOT-приёмка `false` по прямой передаче ROOT; получение потребителем неизвестно, применение `false`.
- Для этой записи доски доставка подтверждена точным push/readback. Получение, приёмка и применение записи соседним потребителем пока не подтверждены.

## Проверки

- JSON проходит `jq -e`; staged diff прошёл `git diff --check`.
- Для всех четырёх исходных Git-фактов проверены точные commit/path/blob через `git cat-file -e` и `git ls-tree`; SHA-256 пересчитан из сырых `git cat-file blob` байтов.
- Удалённые вершины ROOT, Source, Требований и Правил сверены через `git ls-remote origin`. Для handoff Требований отдельно проверено включение `ede9725…` в опубликованную ветку.
- Raw author/committer, parents, tree и сообщение коммита снимка перечитаны после коммита.
- Полная сборка и Swift suite не запускались: в этом source-only срезе Swift-код не менялся.

## Сохранность прежнего среза

Старый незавершённый Swift-валидатор не переносился и не очищался. В `/Users/fum/.codex/worktrees/b7b8/FUM` остались branch `refs/heads/codex/proverka-doski-obyyavlenij-01a07d3d`, HEAD `d8c79d943c39e88ea4f08b44b6ed0a5647ff831d` и 37 записей `git status`; исходники ниже свежо пересчитаны и совпали с прежним сохранённым отпечатком:

| Файл | SHA-256 |
|---|---|
| `Приложения/FUMA/macOS/Package.swift` | `4efe43a47c7832f47ece569af3dae77695c703946e13d3f9671183becc25019e` |
| `Приложения/FUMA/macOS/Sources/proveritj-dosku-obyyavlenij/main.swift` | `17d9c97cd69e61ce10f170378f0b2371b492fb099f6fac954a24146a79291a10` |
| `Приложения/FUMA/macOS/Sources/proverka-doski-obyyavlenij/ПроверкаЛокальногоИсточника.swift` | `4788ce5de7588861a1a1532e37f84979958c520438fda3f7be8ebe2e4e3ead04` |
| `Приложения/FUMA/macOS/Sources/proverka-doski-obyyavlenij/ИдентификаторОбъявления.swift` | `4be1b6933870a5e335cf9232f01b37dedc89b6790191904cc1fc4b1a24506d42` |
| `Приложения/FUMA/macOS/Sources/proverka-doski-obyyavlenij/ПроверкаКаталогаОбъявлений.swift` | `f9650591a5f671995e3c60452b20c8b03daa4317616fb5821cab56a13684c79e` |
| `Приложения/FUMA/macOS/Sources/proverka-doski-obyyavlenij/МоделиОбъявлений.swift` | `9254a100c6d5b7bb4ad4b73bba1fe6b68d4110817261e0559f774147c82d0920` |
| `Приложения/FUMA/macOS/Sources/proverka-doski-obyyavlenij/ОбработчикКомандыВалидатора.swift` | `febc685f236b956255eb4794504735388bf133f61994d9db946995e80d8e257e` |
| `Приложения/FUMA/macOS/Tests/proverka-doski-obyyavlenij/ПроверкаКаталогаОбъявленийTests.swift` | `61704e4ad787062465a7994bf5b9239b337044d932b1c04b1b8f650ad2c7fd14` |

Другой W `9c22` с долгоживущей веткой доски не менялся; на момент исходного осмотра там были 12 изменённых путей. Активный чат для текущего W — этот поток `01a17815-c6b6-7482-9829-b8dd7901ca23`; иных чатов, привязанных к собственному W, не обнаружено.

## Ограничения и замечание

Профиль общего узла сохранён как `UNKNOWN`; наблюдение ROOT не подтверждает полного покрытия дерева или работы автоматического router/deploy. Начальный роутер правил был вызван через Python до обнаружения прямого запрета Python в поручении; запуск был read-only, не изменил файлы или refs. После этого Python, ROOT RAW/JSONL и legacy reader не запускались.
