# Iskhodnyij zapros 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)
- Sleduyusjhij zapros: [2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)

## Tekst zaprosa

```text
Выполни следующий шаг ветки FUM как отдельную обычную рабочую сессию.

Точные значения записи шага:
- branch_ref: refs/heads/master
- step_id: master-reconfirm-mvp-stage-exit-v1
- record_path: Планирование/следующие-шаги-веток/master.md
- project_path: README.md
- state: ready
- status: ready
- title: Переподтвердить MVP и критерий выхода документационной стадии
- task: По текущей памяти проекта принять и зафиксировать одно однозначное решение о ближайшем MVP: либо подтвердить архиватор источников и определить его единственный сквозной acceptance-сценарий первого релиза, либо явно приостановить его и выбрать фактически активный контур. Одновременно определить проверяемый критерий выхода документационной стадии и ранжировать не более трёх ближайших задач, синхронизировав канонические плановые материалы.
- criteria:
  1. Ровно один MVP явно отмечен активным; прежний архиватор подтверждён либо переведён в явное состояние `paused` с обоснованием и источниками.
  2. Для выбранного MVP описан один сквозной сценарий приёмки с входом, точкой запуска, ожидаемыми артефактами, повторным запуском и автономной фикстурой.
  3. Стадия `01` содержит бинарный checklist выхода, ссылки на проверяемые артефакты и честный текущий статус.
  4. В оперативном планировании ранжированы 1–3 ближайшие задачи; предложение о переподтверждении MVP завершено, плановый JSON-реестр пересобран и валиден.
  5. Автономные проверки и полный smoke-check проходят; запись `master` получает очередной свежий `step_id` либо явное конечное состояние.

Обязательный порядок:
1. Полностью прочитай /Users/fum/Projects/FUM/Инструменты/fum-branch-next-step/SKILL.md.
2. Полностью прочитай /Users/fum/Projects/FUM/Планирование/следующие-шаги-веток/master.md и /Users/fum/Projects/FUM/README.md. Считай запись шага и паспорт проекта обязательными входами; соблюдай все заданные ими границы действий, доступа, публикации и проверки.
3. До любых записей выполни fenced show:
   python3 Инструменты/fum-branch-next-step/scripts/branch-next-step.py show --repo-root . --expected-branch-ref refs/heads/master --expected-step-id master-reconfirm-mvp-stage-exit-v1 --json
   Если получен mismatch или точная пара не подтверждена, заверши без изменений.
4. Проведи обычную рабочую сессию по AGENTS.md. Сохрани этот диспетчерский prompt дословно как исходный пользовательский материал сессии.
5. Выполни task и все criteria.
6. Перед коммитом замени запись шага новым выбранным следующим шагом со свежим step_id либо установи явное состояние paused, blocked или done. Не оставляй выполненный step_id готовым к повторному запуску.
7. Дождись завершения всех процессов и субагентов, способных писать в репозиторий, прогони требуемые автономные проверки и полный smoke-check, затем создай локальный коммит.
8. Не освобождай claim этого успешно созданного запуска: смена поколения должна произойти через обновление записи шага.
```

Служебный идентификатор задачи-диспетчера из оболочки делегирования не переносился: исходным пользовательским материалом этой рабочей сессии является дословное содержимое её `input`, а публикационно разрешённый идентификатор текущей корневой задачи записан отдельно ниже.

## Prikreplyayemyiye materialyi

Net.

## Identifikator seansa Codex

Codex-Thread-ID: 019f837c-8ca5-75c1-9f22-1f12ea884e5e

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-session-time`, `fum-branch-next-step`, `fum-request-materials`, `fum-planning-registry`, `fum-md-recency`, `fum-obsidian-graph-recency`, `fum-session-coherence` i `fum-smoke-check` — versii zadayutsya Git-istoriyej; ispoljzuyutsya dlya kanonicheskogo vremeni, fenced-proverki shaga, chteniya kontrakta arkhivirovaniya, sinkhronizacii planovogo reyestra, recency, teplovoj kartyi Obsidian, svyaznosti i polnogo avtonomnogo proverochnogo kontura.
- Instrumentaljnyiye kontraktyi `functions.*` i `collaboration.*` sredyi Codex — otdeljnyiye versii ne raskryivayutsya; ispoljzuyutsya dlya chteniya, vedeniya plana, tochechnyikh pravok, paralleljnyikh auditov i nezavisimogo revjyu.
- Codex Desktop `26.715.61943`, build `5628`; vstroyennyij Codex CLI `0.145.0-alpha.27`; otdeljno ustanovlennyij Codex CLI `0.144.6` — versii proverenyi po lokaljnomu bundle i CLI; modelj aktivnoj zadachi sredoj ne raskryivayetsya kak proveryayemoye znacheniye.
- Git `2.54.0 (Apple Git-157)` — proveryayetsya `git --version`; ispoljzuyetsya dlya inventarya, sverki sostoyaniya, diff, indeksa i lokaljnogo kommita.
- Python `3.14.6` — proveryayetsya `python3 --version`; ispoljzuyetsya dlya generatorov, avtonomnyikh testov i lokaljnyikh proverok.
- ripgrep `15.2.0` — proveryayetsya `rg --version`; ispoljzuyetsya dlya poiska fajlov, ssyilok i strukturnyikh fragmentov.
- Node.js `v26.5.0` — proveryayetsya `node --version`; ispoljzuyetsya dlya mekhanicheskogo vyiravnivaniya izmenyonnyikh Markdown-tablic.
- Zsh `5.9`, sistemnyiye `sed`, `awk`, `tail`, `sort` i `wc` — ispoljzuyutsya dlya lokaljnogo chteniya, inventarizacii i prosmotra bez seti.
- Swift `6.4`, `swift-driver 1.168.4`, celj `arm64-apple-macosx27.0.0` — proveryayetsya `swift --version`; ispoljzuyetsya polnyim smoke-check dlya avtonomnyikh prototipov.

## Povliyal na fajlyi

- [Teplovaya karta grafa Obsidian](../../../../../.obsidian/graph.json)
- [Indeks Markdown-fajlov po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Indeks zhurnala](../README.md)
- [Otchyot tekusjhej sessii](otchyot.md)
- [Predyidusjhij zapros](../2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)
- [Tekusjhij zapros](zapros.md)
- [Indeks planirovaniya](../../Planirovaniye/README.md)
- [Dorozhnaya karta](../../Planirovaniye/dorozhnaya-karta.md)
- [Svodnaya tablica trebovanij i realizacij](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md)
- [Indeks MVP-kandidatov](../../Planirovaniye/MVP-kandidatyi/README.md)
- [Aktivnyij MVP-kandidat](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)
- [Matrica otbora MVP-kandidatov](../../Planirovaniye/MVP-kandidatyi/matrica-otbora.md)
- [Napravleniye pamyati i proiskhozhdeniya](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md)
- [Indeks stadij](../../Planirovaniye/stadii/README.md)
- [Stadiya 01](../../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md)
- [Predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Sleduyusjhij shag vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Khod vyipolneniya

Fenced-proverka do pervoj zapisi podtverdila tochnyiye `refs/heads/master` i `master-reconfirm-mvp-stage-exit-v1`. Obyazateljnyiye zapisj shaga, pasport proyekta, navyik sleduyusjhego shaga i pravila repozitoriya prochitanyi polnostjyu.

Arkhivator istochnikov podtverzhdyon yedinstvennyim aktivnyim MVP. Resheniye opirayetsya na iskhodnyij vyibor, susjhestvuyusjhij `fum-request-materials`, atomarnyij povtor snimka i lokaljnyiye testyi; aljternativnyiye Swift-prototipyi ostayutsya komponentnyimi eksperimentami, a ne boleye zrelyimi zamenami produktovogo kontura. Pervyij reliz yesjhyo ne prinyat: otsutstvuyut obsjhij vkhod `fum source archive`, avtonomnaya HTML/tekstovaya fikstura i odin skvoznoj progon cherez etot vkhod.

Dlya stadii `01` zadan binarnyij kriterij vyikhoda. Posle uspeshnyikh proverok tekusjhej sessii vyipolnenyi dva iz shesti punktov; perekhod ostayotsya zakryit do priyomki MVP, aktualizacii vkhodnyikh opisanij, pasporta pervogo korobochnogo sreza i otdeljnogo resheniya o nachale produktovoj stadii. Operativnaya ocheredj ogranichena tremya ranzhirovannyimi zadachami, a vyipolnennoye predlozheniye o perepodtverzhdenii MVP pereneseno v istoriyu.

## Proverki

- Fenced `show` — tochnaya para vetki i shaga podtverzhdena do zapisi.
- Nezavisimyiye read-only audityi MVP, stadii i proverochnogo kontura — vyivodyi soglasovanyi; subagentyi zavershenyi bez izmenenij repozitoriya.
- Planovyij JSON-reyestr — peresobran i validen; operativnyiye rangi sleduyut v poryadke `1`, `2`, `3`.
- Avtonomnyiye testyi `fum-branch-next-step` — `23` testa projdenyi; novaya zapisj `master-complete-source-archiver-acceptance-v1` validna.
- Avtonomnyiye testyi `fum-planning-registry` — `19` testov projdenyi; `git diff --check` ne vyiyavil oshibok.
- Pervyij polnyij smoke-check obnaruzhil ustarevshuyu proizvodnuyu teplovuyu kartu `.obsidian/graph.json`; karta peresobrana posle recency. Na okonchateljnom snimke `fum-session-coherence` i vse `29` shagov polnogo `fum-smoke-check` projdenyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d165b724f07274ebb354de061d764616df87c9f4433c6d178187febcaa787275 -->
<!-- FUM-MD-RECENCY:END -->
