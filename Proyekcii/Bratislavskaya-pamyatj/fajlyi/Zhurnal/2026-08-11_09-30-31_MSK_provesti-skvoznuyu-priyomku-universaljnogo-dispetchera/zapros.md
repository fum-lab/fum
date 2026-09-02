# Iskhodnyij zapros 2026-08-11 09:30:31 MSK - Provesti skvoznuyu priyomku universaljnogo dispetchera

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-08-10 14:30:08 MSK - Dobavitj analitiku po chislu zavershyonnyikh shagov](../2026-08-10_14-30-08_MSK_dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov/zapros.md)
- Sleduyusjhij zapros: [2026-08-11 13:03:53 MSK - Pochinitj avtozapusk FUM](../2026-08-11_13-03-53_MSK_pochinitj-avtozapusk-FUM/zapros.md)

## Tekst zaprosa

````text
Автозапуск FUM назначил карточку FUM-STEP-0097 — Провести сквозную приёмку универсального диспетчера.
{
  "state": "ready",
  "status": "ready",
  "dispatch": "automatic",
  "record_path": "Планирование/следующие-шаги-веток/master.md",
  "card_id": "FUM-STEP-0097",
  "card_path": "Планирование/карточки-шагов/🗑️-FUM-STEP-0097-провести-сквозную-приёмку-универсального-диспетчера.md",
  "card_content_sha256": "sha256:de0760f2ed0decfc90fb2fe8c0a475d30b8c78344074d41b3d2054fc33f43d28",
  "project_path": "README.md",
  "requires_completed_card_ids": [
    "FUM-STEP-0096"
  ],
  "unmet_required_card_ids": [],
  "title": "Провести сквозную приёмку универсального диспетчера",
  "task": "Провести автономную сквозную приёмку общего реестра, выбора, claim, карточного адаптера, управления сообщениями и аналитики после `N` шагов, а затем выполнить контролируемый live-аудит существующей прикреплённой задачи без запуска неразрешённого внешнего эффекта. Отозванный адаптер периодической публикации `master` не должен появляться в действующем реестре или останавливать независимые задания.",
  "criteria": [
    "Автономный сценарий содержит как минимум карточный адаптер, аналитику по порогу, paused-задание и независимо заблокированное задание без внешнего эффекта в одном валидном реестре.",
    "Совпавшие сроки выбирают не более одного запуска детерминированно, последующие тики не создают голодания и не обходят блокировку.",
    "Управляющее сообщение, пришедшее рядом с heartbeat, защищено поколением и не позволяет запуску из устаревшего снимка выполнить действие после перенастройки.",
    "Созданные исполнители проходят FIFO и повторную fenced-проверку; плановый тик не меняет checkout, индекс, Git-историю или внешнее состояние.",
    "Прерывания до claim, после claim, после неоднозначного host-ответа, после commit результата и до курсора восстанавливаются без двойной задачи или двойного порога.",
    "Реестр не содержит задания автоматической публикации `refs/heads/master`; обычный результат заканчивается локальным commit+handoff, а ручной push пользователя не моделируется как runtime-gate следующего шага.",
    "Контролируемый live-аудит подтверждает одну прежнюю прикреплённую задачу, один heartbeat, управление сообщениями и отсутствие дублирующего диспетчера; непрозрачные локальные ID не попадают в публикацию.",
    "Полный smoke-check включает автономные тесты общего слоя и сохранённые тесты карточного адаптера, очереди, recency, графа и публикационной чистоты."
  ],
  "selection": {
    "policy": "dynamic-readiness-source-history-first-parent-v2",
    "ready_count": 3,
    "reason": "completed_step_source",
    "commit": "34926372ca6ab771a723ddda1a1ceedf29f334c3",
    "distance": 0,
    "matched_paths": [
      "Планирование/карточки-шагов/✅-FUM-STEP-0096-добавить-аналитику-по-числу-завершённых-шагов.md"
    ]
  }
}
````

## Identifikator seansa Codex

Tochnyij identifikator seansa namerenno ne sokhranyayetsya: kontrakt avtomaticheskogo naznacheniya pryamo otnosit yego k nepublikuyemomu upravlyayusjhemu konvertu i zapresjhayet perenositj v repozitorij, Zhurnal i soobsjheniye kommita. Proverka svyaznosti, kotoraya trebuyet yego publikacii i odnoimyonnogo trailer kommita, dlya etoj sessii neprimenima; prichina isklyucheniya zafiksirovana bez samogo znacheniya.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — sistemnaya granica dopustimyikh lokaljnyikh instrumentov.
- Codex desktop — upravlyayusjhaya rabochaya sessiya; versiya prilozheniyem ne raskryita, sobstvennyij identifikator ispoljzovan toljko tranzitno dlya FIFO i ograzhdenij zapuska.
- Python, Git i Swift — lokaljnyiye ispolniteli realizacii, proverok i atomarnoj Git-CAS-peredachi; ikh dopustimostj proveryayet polnyij smoke-check po proyektnomu reyestru instrumentov.
- Lokaljnyiye navyiki `fum-dispetcher-avtomatizacij-fum`, `fum-sleduyusjhij-shag-vetki`, `fum-ocheredj-zadach-git-vetki`, `fum-struktura-papok-zaprosov`, `fum-moskovskoye-vremya-rabochej-sessii`, `fum-otchyotyi-o-zapuskakh-proverok`, `fum-reyestr-planirovaniya`, `fum-svezhestj-markdown`, `fum-perevod-obyyavlenij-koda-na-russkij-yazyik`, `fum-svyaznostj-rabochej-sessii`, `fum-kompleksnaya-proverka-repozitoriya`, `fum-svezhestj-grafa-obsidian` i `fum-revjyu-prodelannoj-rabotyi` — lokaljnyiye kontraktyi vyipolneniya, audita, svezhesti i peredachi.
- `fum-moskovskoye-vremya-rabochej-sessii` — kanonicheskaya para vremeni rabochej sessii poluchena lokaljno v zone Europe/Moscow.

## Proverki

- Vse pryamyiye proverochnyiye vyizovyi i ikh dliteljnosti sokhranyayutsya mashinno v [materialakh zapuskov](materialyi/zapuski-proverok/) i svodyatsya v [otchyote](otchyot.md).
- Finaljnyij polnyij smoke-check vyipolnyayetsya s odnim yavno obosnovannyim isklyucheniyem `--skip-session-coherence`: inache proverka potrebovala byi sokhranitj zapresjhyonnyij identifikator seansa; vse ostaljnyiye proverki zapuskayutsya polnostjyu.

## Povliyal na fajlyi

- [tekusjhij zapros](zapros.md) i [tekusjhij otchyot](otchyot.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:0441f6824eb458243fa4dc1d92e3dc9ef444b1c1e7040b3c632ea21be0aa7ed6 -->
<!-- FUM-MD-RECENCY:END -->
