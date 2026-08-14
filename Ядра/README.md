# Тематические исполнители FUM

Папка хранит три долговечных дочерних fork-репозитория как закреплённые Git submodule. Каждый каталог внутри является чистым detached-снимком принятой ревизии, а не живой рабочей веткой исполнителя. Запись ведётся в отдельном клоне соответствующего fork; родительский репозиторий обновляет только проверенный gitlink.

| Исполнитель       | Публичный fork                                                         | Закреплённая ревизия                         |
| ----------------- | ---------------------------------------------------------------------- | -------------------------------------------- |
| `fum-yadro`       | [`fum-lab/fum-yadro`](https://github.com/fum-lab/fum-yadro)             | `249d076b1857f4e1727e5448587d13f16b15a30a` |
| `fum-optimizator` | [`fum-lab/fum-optimizator`](https://github.com/fum-lab/fum-optimizator) | `249d076b1857f4e1727e5448587d13f16b15a30a` |
| `fum-pisatelj`    | [`fum-lab/fum-pisatelj`](https://github.com/fum-lab/fum-pisatelj)       | `249d076b1857f4e1727e5448587d13f16b15a30a` |

После свежего клонирования сначала материализуйте три верхнеуровневых снимка и восстановите их точные `origin` и `upstream`:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root . --path Ядра/fum-yadro
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root . --path Ядра/fum-optimizator
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root . --path Ядра/fum-pisatelj
```

Затем инициализируйте закреплённую LinguisticKit внутри каждого снимка:

```bash
python3 Ядра/fum-yadro/Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root Ядра/fum-yadro --path Зависимости/LinguisticKit
python3 Ядра/fum-optimizator/Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root Ядра/fum-optimizator --path Зависимости/LinguisticKit
python3 Ядра/fum-pisatelj/Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root Ядра/fum-pisatelj --path Зависимости/LinguisticKit
```

Поле `branch` и `git submodule update --remote` не используются: воспроизводимость задаёт точный gitlink. Текущая ревизия детей предшествует появлению самой папки `Ядра`, поэтому граф конечен. Продвигать дочерний gitlink на ревизию родительского FUM, которая уже содержит `Ядра`, нельзя до выделения отдельной композиционной сборки или другого проверенного устранения рекурсивного цикла.

## Источники требований

- [исходный запрос 2026-08-14 19:57:29 MSK — Создать постоянных тематических исполнителей](../Журнал/2026-08-14_19-57-29_MSK_создать-постоянных-тематических-исполнителей/запрос.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 22:05:41 MSK -->
<!-- content-sha256: sha256:238dd587266ba62ead805c2dcf0f5f814be1ed6fb6a0d8d55afd57a7214ccb0d -->
<!-- FUM-MD-RECENCY:END -->
