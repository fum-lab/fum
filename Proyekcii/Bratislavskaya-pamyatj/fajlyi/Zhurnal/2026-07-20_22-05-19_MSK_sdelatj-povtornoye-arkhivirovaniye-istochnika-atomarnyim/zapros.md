# Iskhodnyij zapros 2026-07-20 22:05:19 MSK - Sdelatj povtornoye arkhivirovaniye istochnika atomarnyim

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-20 21:22:17 MSK - Vklyuchitj kartochki trebovanij v mashinnyij planovyij reyestr](../2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)
- Sleduyusjhij zapros: [2026-07-20 23:08:44 MSK - Vosstanovitj obratnyiye ssyilki voprosov](../2026-07-20_23-08-44_MSK_vosstanovitj-obratnyiye-ssyilki-voprosov/zapros.md)

## Tekst zaprosa

```text
Выполни следующий шаг активной ветки FUM как отдельную обычную рабочую сессию.

Точные входы диспетчера:
- корень репозитория: /Users/fum/Projects/FUM
- branch_ref: refs/heads/master
- step_id: master-atomic-source-rearchive-v1
- status: ready
- record_path: Планирование/следующие-шаги-веток/master.md
- project_path: README.md
- заголовок: «Сделать повторное архивирование источника атомарным»

Задача:
Доработать `fum-request-materials` через TDD: собирать повторный снимок в staging-каталоге, фиксировать точный манифест управляемых файлов и заменять канонический снимок только целиком. Полный снимок с последующим неполным или неуспешным повтором не должен сохранять старые структурные файлы как часть нового результата.

Критерии завершения:
- До успешного завершения staging прежний канонический снимок остаётся неизменным.
- Успешная замена содержит ровно управляемые файлы нового манифеста и не сохраняет отсутствующие в нём старые файлы.
- Автономные тесты покрывают последовательности `полный снимок -> неполный снимок` и `полный снимок -> неуспешный повтор`.
- Автономные тесты `fum-request-materials` и полный smoke-check проходят без сети и секретов.
- Рабочая сессия обновляет эту запись новым `step_id` и следующим шагом либо явным состоянием `blocked`, `paused` или `done`.

Обязательный порядок:
1. Полностью прочитай `/Users/fum/Projects/FUM/Инструменты/fum-branch-next-step/SKILL.md`.
2. Полностью прочитай переданные `Планирование/следующие-шаги-веток/master.md` и `README.md`; считай запись шага и паспорт проекта обязательными входами, соблюдай их источники, границы действий, доступа, публикации и проверки.
3. До любых записей из корня репозитория выполни fenced-проверку:
   `python3 Инструменты/fum-branch-next-step/scripts/branch-next-step.py show --repo-root . --expected-branch-ref refs/heads/master --expected-step-id master-atomic-source-rearchive-v1 --json`
   При mismatch, неготовом состоянии или иной ошибке заверши без изменений.
4. Проведи обычную рабочую сессию строго по `/Users/fum/Projects/FUM/AGENTS.md`. Сохрани этот диспетчерский prompt как исходный пользовательский материал сессии по правилам репозитория.
5. Выполни задачу и все критерии через TDD. Не расширяй полномочия и не публикуй секреты или непрозрачные локальные идентификаторы.
6. Перед коммитом обязательно замени запись `Планирование/следующие-шаги-веток/master.md` новым выбранным шагом со свежим `step_id` либо установи явное состояние `paused`, `blocked` или `done` с объяснением. Не оставляй выполненный ready-шаг с прежним `step_id`.
7. Дождись всех процессов и субагентов, прогони требуемые проверки, включая полный smoke-check, и создай локальный коммит. Push не выполняй без отдельного разрешения.
8. Не освобождай claim успешно созданного запуска: новое поколение `step_id` сменит его атомарно, а неизменившийся шаг должен остаться защищён от повтора.
```

Служебный идентификатор задачи-диспетчера из оболочки делегирования не переносился: исходным пользовательским материалом этой рабочей сессии является дословное содержимое её `input`, а публикационно разрешённый идентификатор текущей корневой задачи записан отдельно ниже.

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f80e9-1d40-7392-b47e-82cc6d8578d7

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-session-time`, `fum-branch-next-step`, `fum-request-materials`, `fum-planning-registry`, `fum-md-recency`, `fum-obsidian-graph-recency`, `fum-session-coherence` i `fum-smoke-check` — versii zadayutsya Git-istoriyej; ispoljzovanyi dlya kanonicheskogo vremeni, fenced-proverki, TDD, planirovaniya i polnogo avtonomnogo proverochnogo kontura.
- Instrumentaljnyiye kontraktyi `functions.*` i `collaboration.*` sredyi Codex — otdeljnyiye versii ne raskryivayutsya; ispoljzovanyi dlya chteniya, vedeniya plana, tochechnyikh pravok i shesti nezavisimyikh auditov.
- Git `2.54.0 (Apple Git-157)`, Python `3.14.6`, ripgrep `15.2.0`, Node.js `v26.5.0`, jq `1.7.1-apple`, zsh `5.9` i Apple Swift `6.4` — nablyudayemyiye lokaljnyiye ispolnyayemyiye instrumentyi sessii.
- Sistemnyiye `awk`, `find`, `sed`, `sort`, `tail`, `wc` i `xcrun` — vspomogateljnoye chteniye, vyiborka i proverka lokaljnyikh fajlov i SDK-kontrakta; otdeljnyiye versii ne fiksirovalisj.

## Povliyal na fajlyi

- [graf Obsidian](../../../../../.obsidian/graph.json)
- [proizvodnaya dokumentaciya ob avtomatizaciyakh](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [indeks Markdown-fajlov po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [indeks zhurnala](../README.md)
- [otchyot tekusjhej sessii](otchyot.md)
- [Predyidusjhij zapros](../2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)
- [Tekusjhij zapros](zapros.md)
- [kontrakt fum-request-materials](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)
- [skript arkhivirovaniya ChatGPT share](../../Instrumentyi/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py)
- [avtonomnyiye testyi fum-request-materials](../../Instrumentyi/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py)
- [MVP-kandidat arkhivirovaniya prikreplyayemyikh materialov](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [sleduyusjhij shag master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Khod vyipolneniya

Fenced-proverka podtverdila tochnyiye `refs/heads/master` i `master-atomic-source-rearchive-v1` do pervoj zapisi. Obyazateljnyiye zapisj shaga, pasport proyekta, navyik sleduyusjhego shaga, pravila repozitoriya i kontrakt `fum-request-materials` prochitanyi polnostjyu.

Iskhodnyiye 15 avtonomnyikh testov `fum-request-materials` proshli bez seti i sekretov. Krasnaya faza dobavila skvoznyiye posledovateljnosti `полный снимок -> неполный снимок` i `полный снимок -> поздний сбой генерации`: prezhnyaya realizaciya ne sozdavala manifest i chastichno perezapisyivala kanonicheskij katalog do oshibki.

Pervaya zelyonaya realizaciya perenesla vse zapisi v sosednij staging, dobavila tochnyij `snapshot-manifest.json` i celostnuyu ustanovku kataloga. Tri nezavisimyikh code review obnaruzhili neatomarnyij rezervnyij putj cherez dva pereimenovaniya, vozmozhnostj chastichnogo otkata uzhe udalyayemogo backup i neodnoznachnostj post-commit oshibok. Dopolniteljnyiye krasnyiye progonyi zakrepili fail-closed pri nedostupnom directory exchange, neizmennostj staryikh bajtov pryamo vo vremya staging, otdeljnoye preduprezhdeniye ob oshibke ssyilki, atomarnuyu zapisj fajla zaprosa, preduprezhdeniye ob ostavshemsya starom staging i nezavisimostj osnovnogo nabora ot vozmozhnostej fajlovoj sistemyi.

Itogovaya realizaciya ispoljzuyet `RENAME_SWAP` na macOS i `RENAME_EXCHANGE` na Linux, a pri otsutstvii podderzhki ne menyayet kanonicheskij snimok. Vse 21 test prokhodyat. Vyipolnennoye predlozheniye pereneseno v istoriyu, a prezhnij ready-shag zamenyon novyim `master-restore-question-backlinks-v1`.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py' -v` — itogovyiye 21 test prokhodyat bez seti i sekretov.
- Izolirovannaya platformennaya proverka `try_atomic_directory_exchange` — `RENAME_SWAP` na tekusjhej fajlovoj sisteme macOS atomarno obmenyal dva nepustyikh kataloga.
- `fum-smoke-check` — vse 26 etapov prokhodyat bez seti i sekretov, vklyuchaya avtonomnyiye naboryi, oba Swift-prototipa, planovyij reyestr, recency, graf Obsidian i svyaznostj rabochej sessii.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:eb7e30211f0456f0eddc93f179a2fdad2301946ae328cc198f55dce756a08b60 -->
<!-- FUM-MD-RECENCY:END -->
