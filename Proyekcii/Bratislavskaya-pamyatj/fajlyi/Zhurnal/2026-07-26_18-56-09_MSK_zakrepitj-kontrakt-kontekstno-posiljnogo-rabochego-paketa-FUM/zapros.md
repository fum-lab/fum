# Iskhodnyij zapros 2026-07-26 18:56:09 MSK - Zakrepitj kontrakt kontekstno posiljnogo rabochego paketa FUM

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-26 15:15:18 MSK - Publikovatj rabotu v GitHub avtomaticheski](../2026-07-26_15-15-18_MSK_publikovatj-rabotu-v-GitHub-avtomaticheski/zapros.md)
- Sleduyusjhij zapros: [2026-07-27 15:21:35 MSK - Sdelatj dispetcher avtomatizacij vetki universaljnyim](../2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)

## Tekst zaprosa

```text
Автозапуск назначил карточку FUM-STEP-0075 — Закрепить контракт контекстно посильного рабочего пакета FUM; ожидаю допуск FIFO.

Точная запись рабочего набора:
branch_ref: refs/heads/master
step_id: master-fum-step-0075-ready-v2
status: ready
record_path: Планирование/следующие-шаги-веток/master.md
card_id: FUM-STEP-0075
card_path: Планирование/карточки-шагов/🟡-FUM-STEP-0075-закрепить-контракт-контекстно-посильного-рабочего-пакета-FUM.md
card_content_sha256: sha256:843410d7acfd720d83b7c6633318ba350c7f0cb373022106433465c8127f7b9c
project_path: README.md
title: Закрепить контракт контекстно посильного рабочего пакета FUM
task: Начать в точном каталоге `Прототипы/проверяемый-многоагентный-контур/` самостоятельный безоконный SwiftPM-прототип проверяемого многоагентного контура FUM с версионированного машиночитаемого контракта одного контекстно посильного исполняемого шага. Рабочий пакет должен до начала модельной или изменяющей работы описывать одну основную поставку, ограниченный набор входов, допустимую область изменений, исключения, зависимости, проверки, передачу результата и раздельный бюджет чтения, работы, проверок, ответа и резерва. Локальный предпусковой анализатор должен возвращать только проверяемое решение ready или split_required и закрываться отказом на неполном либо противоречивом пакете.

Содержательные изменения реализации ограничены новым каталогом прототипа, его строкой в Прототипы/README.md и регистрацией пакета в политике общего smoke-check. Разрешены только обязательные служебные артефакты текущей рабочей сессии: исходный запрос, журнал, завершение этой карточки, новый веточный выбор и выходы штатных генераторов планового реестра, recency и графа. Не изменять существующие прототипы, продуктовый runtime, сетевые или модельные адаптеры, очередь FIFO и механизм claim следующего шага.

criteria:
1. Создан самостоятельный SwiftPM-прототип без сетевых вызовов и внешних зависимостей; README честно отделяет предпусковую оценку помещаемости от доказательства фактического расхода контекста.
2. Содержательный diff остаётся в объявленной области: новый каталог прототипа, индекс прототипов и политика SwiftPM общего smoke-check; дополнительные изменения только перечисленные служебные артефакты.
3. Версионированный JSON-контракт требует одну основную поставку, цель, конечный манифест входов с хэшами, допустимые изменения, явные исключения, зависимости, проверки, формат передачи и раздельные лимиты чтения, работы, проверок, ответа и резерва.
4. Предпусковой анализ выполняется до модельного вызова и до изменения пользовательских данных, детерминированно выдаёт ready либо split_required и объясняет каждое нарушение машиночитаемыми кодами.
5. Пакет с несколькими зависимыми поставками, отсутствующим обязательным входом, неограниченной областью изменений, неразрешённой зависимостью или без резерва не получает статус ready.
6. Положительные и отрицательные фикстуры, автономные тесты, сборка, проверка форматирования и локальный запуск пробника воспроизводят контракт без секретов и внешних эффектов.
7. Прототип не заявляет числовую вероятность помещаемости без наблюдаемой телеметрии и не выдаётся за готовый многоагентный runtime FUM.
8. Обязательными предметными входами служат только перечисленные источники; AGENTS.md и локальные навыки читаются как правила выполнения, а не разрешение расширить поставку.

Сначала полностью прочитай AGENTS.md, Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md и Инструменты/fum-ocheredj-zadach-git-vetki/SKILL.md. Первым инструментальным действием зарегистрируй свой корневой CODEX_THREAD_ID в FIFO-очереди через join и до admitted только жди без изменений и промежуточных сообщений. Полностью прочитай переданные record_path, card_path и project_path без добавления корня проекта; считай их обязательными входами и соблюдай границы действий, доступа, публикации и проверки паспорта. После admitted и до любых записей выполни fenced show с ожидаемыми branch_ref и step_id; при несовпадении выведи «Назначение карточки FUM-STEP-0075 — Закрепить контракт контекстно посильного рабочего пакета FUM не подтверждено; работа не начата.», не оставляй владельца, дождись отсутствия писателей и выполни документированный finish-clean с точными task_id и generation. После успешного fenced show ровно один раз выведи «В работу взята карточка FUM-STEP-0075 — Закрепить контракт контекстно посильного рабочего пакета FUM.». Сохрани этот диспетчерский prompt как исходный материал сессии, выполни задачу и критерии. Перед завершением удали выполненного кандидата, сохрани paused/blocked с resume_condition, выбери не более одной новой безопасной ready со свежим step_id либо state=done, не скрывай готовый шаг отложенным. Дожди́сь всех писателей, выполни проверки и атомарный commit+handoff очереди без обычного git commit; после committed немедленно выполни publish точного коммита по сохранённому push URL. Не освобождай успешно созданный claim.
```

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f9f1c-7344-7cc2-96c6-a2d1d5eb9043

## Rezuljtat

Sozdan samostoyateljnyij bezokonnyij SwiftPM-prototip `Прототипы/проверяемый-многоагентный-контур/` bez seti i vneshnikh paketnyikh zavisimostej. Yego kontrakt versii 1 trebuyet odnu osnovnuyu postavku, celj, konechnyij manifest vkhodov s khyeshami, ogranichennuyu oblastj izmenenij i isklyucheniya, razreshyonnyiye zavisimosti, proverki, format peredachi i razdeljnyij byudzhet chteniya, rabotyi, proverki, otveta i rezerva.

Lokaljnyij analizator chitayet toljko perechislennyiye vkhodyi otnositeljno otkryitogo deskriptora yavnoj rabochej oblasti, zapresjhayet simvolicheskiye ssyilki, zhyostko ogranichivayet prochitannyiye bajtyi i sveryayet fakticheskij SHA-256 obyichnogo neizmenivshegosya fajla. Nepolnyij, protivorechivyij, neizvestnyij ili povtoryayusjhij klyuchi JSON zakryivayetsya resheniyem `split_required`; polnyij paket poluchayet `ready`. Kazhdyij otkaz soderzhit ustojchivo otsortirovannyiye mashinochitayemyiye kodyi. Vstroyenyi polozhiteljnaya i pyatj obyazateljnyikh otricateljnyikh fikstur, avtonomnyiye testyi i CLI-probnik s kanonicheskim JSON-vyikhodom. README chestno ogranichivayet `ready` staticheskoj predpuskovoj proverkoj i ne pripisyivayet prototipu izmerennuyu veroyatnostj pomesjhayemosti, dokazateljstvo fakticheskogo raskhoda konteksta ili svojstva gotovogo mnogoagentnogo runtime.

Kartochka FUM-STEP-0075 zavershena. Yedinstvennyim novyim `ready` vyibran samostoyateljno proveryayemyij FUM-STEP-0076 s pasportom raspredelyonnogo myisliteljnogo epizoda; vse ostaljnyiye kandidatyi sokhranenyi otlozhennyimi s prezhnimi usloviyami vozobnovleniya.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye navyiki [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md), [fum-proverka-mashinno-lokaljnyikh-putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md) i [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) — obyazateljnyiye kontraktyi vyipolneniya i proverki.
- Codex Desktop s instrumentami vyipolneniya komand, `apply_patch`, vedeniya plana i read-only-audita subagentom — realizaciya, proverka i nezavisimaya kriticheskaya recenziya v obsjhej rabochej kopii.
- Swift 6.4 i SwiftPM — biblioteka, ispolnyayemyij probnik, fiksturyi, sborka, testyi i strogij Swift-format lint bez vneshnikh zavisimostej.
- Python 3.14.6, Git 2.54.0 (Apple Git-157), zsh 5.9 i ripgrep 15.2.0 — shtatnyiye generatoryi, validaciya, poisk, audit diff i atomarnaya peredacha ocheredi.
- macOS 27.0 i Xcode 27.0 (build 27A5228h) — lokaljnaya sreda sborki Swift-prototipa.

## Povliyal na fajlyi

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [predyidusjhij zapros s obnovlyonnoj navigaciyej](../2026-07-26_15-15-18_MSK_publikovatj-rabotu-v-GitHub-avtomaticheski/zapros.md)
- [iskhodnyij zapros o kontekstno ogranichennoj realizacii s obnovlyonnoj ssyilkoj na kartochku](../2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [tekusjhij zhurnaljnyij otchyot](otchyot.md)
- [predyidusjhij zhurnaljnyij otchyot s obnovlyonnoj ssyilkoj na kartochku](../2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/otchyot.md)
- [indeks zhurnala](../README.md)
- [README novogo SwiftPM-prototipa](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/README.md)
- [manifest novogo SwiftPM-paketa](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Package.swift)
- [biblioteka predpuskovogo analizatora](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/WorkPackageContract.swift)
- [resurs nablyudayemogo vkhoda](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/RabochayaOblastj/inputs/requirements.txt)
- [polozhiteljnaya JSON-fikstura](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/ready.json)
- [fikstura otsutstvuyusjhego obyazateljnogo vkhoda](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/split-missing-required-input.json)
- [fikstura neskoljkikh postavok](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/split-multiple-deliverables.json)
- [fikstura bez rezerva](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/split-no-reserve.json)
- [fikstura neogranichennoj oblasti](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/split-unbounded-change-scope.json)
- [fikstura nerazreshyonnoj zavisimosti](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMVerifiableMultiAgentContour/Fiksturyi/split-unresolved-dependency.json)
- [CLI-probnik](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Sources/FUMWorkPackageProbe/main.swift)
- [trinadcatj avtonomnyikh testov](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/Tests/FUMVerifiableMultiAgentContourTests/WorkPackageContractTests.swift)
- [ispolnyayemaya tochka zapuska](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/zapustitj.sh)
- [indeks prototipov](../../Prototipyi/README.md)
- [politika SwiftPM obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json)
- [zavershyonnaya kartochka FUM-STEP-0075](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0075-zakrepitj-kontrakt-kontekstno-posiljnogo-rabochego-paketa-FUM.md)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0075-закрепить-контракт-контекстно-посильного-рабочего-пакета-FUM.md`
- [kartochka FUM-STEP-0076 s obnovlyonnoj ssyilkoj na predshestvennika](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0076-zakrepitj-pasport-raspredelyonnogo-myisliteljnogo-epizoda-FUM.md)
- [indeks kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md)
- [rabochij nabor sleduyusjhego shaga vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [indeks svezhesti Markdown](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [opornaya data recency](../../.obsidian/fum-recency-reference-date)
- [graf Obsidian](../../../../../.obsidian/graph.json)

## Proverki

- TDD-krasnyij progon podtverdil otsutstviye yesjhyo ne realizovannoj modeli otchyota; posle realizacii `swift test` vyipolnyayet 13 testov bez oshibok.
- `swift build --product FUMWorkPackageProbe` i strogij `swift format lint` prokhodyat bez zamechanij.
- Probnik iz vneshnego tekusjhego kataloga vozvrasjhayet kanonicheskij `ready` s kodom 0, obyazateljnyij `split_required` s kodom 3, spisok fikstur i fail-closed-otchyot dlya nepolnogo stdin-paketa.
- Validator rabochego nabora podtverzhdayet yedinstvennyij `master-fum-step-0076-ready-v2` i tochnyij khyesh kartochki; planovyij reyestr peresobran i validen.
- Proverka tochek zapuska podtverzhdayet kornevuyu panelj i 9 prototipov.
- Polnyij smoke-check prokhodit 61 iz 61 shaga; svyaznostj sessii, recency, teplovaya karta grafa i publikacionnaya chistota podtverzhdenyi itogovyimi proverkami.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:22d9267c173969c3b37f255af3cfd14cc689f0a64f47e083db30d22ed05300d9 -->
<!-- FUM-MD-RECENCY:END -->
