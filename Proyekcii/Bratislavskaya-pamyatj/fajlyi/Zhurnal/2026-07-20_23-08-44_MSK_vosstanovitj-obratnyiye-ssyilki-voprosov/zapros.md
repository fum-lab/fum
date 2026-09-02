# Iskhodnyij zapros 2026-07-20 23:08:44 MSK - Vosstanovitj obratnyiye ssyilki voprosov

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-20 22:05:19 MSK - Sdelatj povtornoye arkhivirovaniye istochnika atomarnyim](../2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md)
- Sleduyusjhij zapros: [2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)

## Tekst zaprosa

```text
Выполни следующий шаг ветки FUM как отдельную обычную рабочую сессию.

Точные значения записи шага:
- branch_ref: refs/heads/master
- step_id: master-restore-question-backlinks-v1
- record_path: Планирование/следующие-шаги-веток/master.md
- project_path: README.md
- state: ready
- status: ready
- title: Восстановить обратные ссылки вопросов
- task: Через TDD восстановить обязательные обратные ссылки от производной документации ко всем открытым и частично прояснённым вопросам и добавить локальную автоматическую проверку двунаправленности, входящую в полный smoke-check. Сверить заявленные цели вопросов с фактическими смысловыми зависимостями, а не добавлять формальные ссылки без основания.
- criteria:
  1. Каждая фактическая цель открытого или частично прояснённого вопроса содержит обратную ссылку на этот вопрос; ошибочно заявленные цели исправлены в самом вопросе с сохранением происхождения решения.
  2. Автономный валидатор обнаруживает отсутствующую обратную ссылку, лишённую цели ссылку и несовпадающий регистр локального пути.
  3. Проверка двунаправленности автоматически входит в полный smoke-check и не требует сети или секретов.
  4. Автономные тесты затронутой автоматизации и полный smoke-check проходят.
  5. Рабочая сессия обновляет эту запись новым `step_id` и следующим шагом либо явным состоянием `blocked`, `paused` или `done`.

Обязательный порядок:
1. Полностью прочитай /Users/fum/Projects/FUM/Инструменты/fum-branch-next-step/SKILL.md.
2. Полностью прочитай /Users/fum/Projects/FUM/Планирование/следующие-шаги-веток/master.md и /Users/fum/Projects/FUM/README.md. Считай запись шага и паспорт проекта обязательными входами; соблюдай все заданные ими границы действий, доступа, публикации и проверки.
3. До любых записей выполни fenced show:
   python3 Инструменты/fum-branch-next-step/scripts/branch-next-step.py show --repo-root . --expected-branch-ref refs/heads/master --expected-step-id master-restore-question-backlinks-v1 --json
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

Codex-Thread-ID: 019f8121-009d-7cd0-a492-1d8f5a6367e4

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Lokaljnyiye avtomatizacii `fum-session-time`, `fum-branch-next-step`, `fum-question-backlinks`, `fum-md-recency`, `fum-obsidian-graph-recency`, `fum-session-coherence` i `fum-smoke-check` — versii zadayutsya Git-istoriyej; ispoljzuyutsya dlya kanonicheskogo vremeni, fenced-proverki shaga, dvunapravlennosti voprosov, recency, grafa Obsidian, svyaznosti i polnogo avtonomnogo proverochnogo kontura.
- Instrumentaljnyiye kontraktyi `functions.*` i `collaboration.*` sredyi Codex — otdeljnyiye versii ne raskryivayutsya; ispoljzuyutsya dlya chteniya, vedeniya plana, tochechnyikh pravok i nezavisimyikh auditov.
- Git `2.54.0 (Apple Git-157)` — provereno `git --version`; ispoljzuyetsya dlya sverki sostoyaniya, diff, indeksa i lokaljnogo kommita.
- Python `3.14.6` — provereno `python3 --version`; ispoljzuyetsya dlya validatora, avtonomnyikh testov i lokaljnyikh avtomatizacij.
- ripgrep `15.2.0` — provereno `rg --version`; ispoljzuyetsya dlya poiska fajlov, ssyilok i strukturnyikh fragmentov.
- Node.js `v26.5.0` i `jq 1.7.1-apple` — proverenyi `node --version` i `jq --version`; fiksiruyutsya kak dostupnyiye CLI-sostavlyayusjhiye proveryayemoj sredyi.
- Zsh `5.9`, sistemnyiye `sed`, `awk`, `find`, `head`, `tail`, `sort`, `wc`, `cut` i `fold` — ispoljzuyutsya dlya lokaljnogo chteniya, inventarizacii i prosmotra dlinnyikh tablic bez seti.
- Swift `6.4`, `swift-driver 1.168.4`, celj `arm64-apple-macosx27.0.0` — provereno `swift --version`; ispoljzuyetsya polnyim smoke-check dlya avtonomnyikh prototipov.

## Povliyal na fajlyi

- [Kornevoj README](../../README.md)
- [Glossarij: agentnostj FUM](../../Glossarij/agentnostj-FUM.md)
- [Glossarij: gorizont agenta FUM](../../Glossarij/gorizont-agenta-FUM.md)
- [Glossarij: lichnostj agenta FUM](../../Glossarij/lichnostj-agenta-FUM.md)
- [Glossarij: mnogourovnevaya yazyikovaya sinkhronizaciya FUM](../../Glossarij/mnogourovnevaya-yazyikovaya-sinkhronizaciya-FUM.md)
- [Glossarij: obsjhaya skhema FUM](../../Glossarij/obsjhaya-skhema-FUM.md)
- [Glossarij: tekstovo-yazyikovoj strukturiruyusjhij operator FUM](../../Glossarij/tekstovo-yazyikovoj-strukturiruyusjhij-operator-FUM.md)
- [Obzor proyekta](../../Dokumentaciya/00-obzor-proyekta.md)
- [Evolyuciya i myishleniye](../../Dokumentaciya/03-evolyuciya-i-myishleniye.md)
- [Vnutrenniye modeli drugikh uzlov](../../Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md)
- [Gibridnyiye uzlyi i socialjnaya fraktaljnostj](../../Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md)
- [Fizicheskoye dejstviye i apparatnyiye uzlyi](../../Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [Vosproizvodimyiye avtomatizacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Yedinaya tochka vzaimodejstviya s kompjyuterom](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [Virtualizovannyiye sredyi i dolgovremennaya pamyatj](../../Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](../../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Potokovaya samostrukturizaciya FUM](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md)
- [Yestestvennyij yazyik i sinkhronizaciya znanij FUM](../../Dokumentaciya/34-yestestvennyij-yazyik-i-sinkhronizaciya-znanij-FUM.md)
- [Indeks zhurnala](../README.md)
- [Otchyot tekusjhej sessii](otchyot.md)
- [Predyidusjhij zapros](../2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md)
- [Tekusjhij zapros](zapros.md)
- [Indeks instrumentov](../../Instrumentyi/README.md)
- [Pasport fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [Scenarij fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py)
- [Testyi fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/tests/test_run_smoke_check.py)
- [Pasport fum-question-backlinks](../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/SKILL.md)
- [Scenarij fum-question-backlinks](../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py)
- [Testyi fum-question-backlinks](../../Instrumentyi/fum-obratnyiye-ssyilki-voprosov/tests/test_check_question_backlinks.py)
- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Indeks Markdown-fajlov po vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [MVP yedinoj tochki lokaljnoj rabotyi](../../Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)
- [Predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Sleduyusjhij shag vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [Stadiya korobochnoj realizacii FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md)
- [Graf zavisimostej korobochnoj realizacii](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md)
- [Teplovaya karta grafa Obsidian](../../../../../.obsidian/graph.json)

## Khod vyipolneniya

Fenced-proverka podtverdila tochnyiye `refs/heads/master` i `master-restore-question-backlinks-v1` do pervoj zapisi. Obyazateljnyiye zapisj shaga, pasport proyekta, navyik sleduyusjhego shaga i pravila repozitoriya prochitanyi polnostjyu.

Predvariteljnaya strukturnaya sverka nashla 14 otkryityikh ili chastichno proyasnyonnyikh voprosov, 85 zayavlennyikh celej i 31 otsutstvuyusjhuyu obratnuyu ssyilku vo vsekh tipakh celej. Iz nikh 21 otnositsya k 69 celyam v `Документация/` i `Планирование/`, chto vosproizvodit nakhodku iskhodnogo revjyu.

Dva nezavisimyikh smyislovyikh prokhoda podtverdili vse 85 celej; oshibochno zayavlennyikh zavisimostej ne najdeno. Tridcatj odna otsutstvovavshaya ssyilka vosstanovlena v 23 celevyikh fajlakh ryadom s zavisimyim tezisom libo v umestnom nizhnem razdele svyazannyikh dokumentov.

Cherez TDD sozdan `fum-question-backlinks`: validator poluchayet aktivnyiye statusyi iz indeksa voprosov, trebuyet nepustyiye lokaljnyiye celi, proveryayet susjhestvovaniye Markdown-fajla, tochnyij registr i vidimuyu obratnuyu ssyilku. Nezavisimoye revjyu parsera rasshirilo regressii do 21 sluchaya i zakryilo obkhodyi cherez otsutstvuyusjhiye statusnyiye razdelyi, pustyiye i fragment-only celi, fenced-primeryi, smeshannyiye markeryi fence, izobrazheniya, inline-code, HTML-kommentarii, ekranirovannyiye psevdossyilki, vneshniye symlink i ne-Markdown-fajlyi.

Otdeljnyij obyazateljnyij shag proverki dobavlen v polnyij `fum-smoke-check`. Vyipolnennaya zapisj `master-restore-question-backlinks-v1` zamenena gotovyim prodolzheniyem `master-stabilize-service-generators-v1` o vosproizvodimosti recency, grafa Obsidian i svyaznostnyikh obkhodov.

## Proverki

- Fenced `show` — tochnaya para vetki i shaga podtverzhdena do zapisi.
- Krasnaya faza TDD — testyi validatora upali iz-za otsutstvuyusjhego scenariya, test plana smoke-check — iz-za otsutstvuyusjhego shaga.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-question-backlinks/tests -p 'test_*.py'` — 21 test prokhodit.
- `python3 Инструменты/fum-question-backlinks/scripts/check-question-backlinks.py` — podtverzhdenyi 14 aktivnyikh voprosov i 85 zayavlennyikh celej.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` — 14 testov prokhodyat.
- `python3 Инструменты/fum-branch-next-step/scripts/branch-next-step.py validate --repo-root . --json` — novaya zapisj `master-stabilize-service-generators-v1` validna i yedinstvenna dlya `refs/heads/master`.
- `git diff --check` — oshibok probelov i konfliktnyikh markerov net.
- Polnyij `fum-smoke-check` s tekusjhim zaprosom, podgotovlennyim soobsjheniyem kommita i kornevyim Codex-Thread-ID — prokhodit bez seti i sekretov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:4d2d78648989eee4ae4c1a14f4332579fa4d07cf000928f054fb230a6b77d7d9 -->
<!-- FUM-MD-RECENCY:END -->
