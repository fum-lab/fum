# Iskhodnyij zapros 2026-08-05 12:02:53 MSK - Perenesti avtozapusk shagov v universaljnyij dispetcher

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-08-05 09:07:08 MSK - Dobavitj universaljnyij vyibor i zasjhisjhyonnuyu rezervaciyu zapuska](../2026-08-05_09-07-08_MSK_dobavitj-universaljnyij-vyibor-i-zasjhisjhyonnuyu-rezervaciyu-zapuska/zapros.md)
- Sleduyusjhij zapros: [2026-08-05 15:49:53 MSK - Upravlyatj universaljnyimi pishusjhimi poduzlami](../2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)

## Tekst zaprosa

````text
{
  "branch_ref": "refs/heads/master",
  "step_id": "master-fum-step-0093-automatic-v4",
  "status": "ready",
  "dispatch": "automatic",
  "requires_completed_card_ids": [
    "FUM-STEP-0092"
  ],
  "unmet_required_card_ids": [],
  "record_path": "Планирование/следующие-шаги-веток/master.md",
  "card_id": "FUM-STEP-0093",
  "card_path": "Планирование/карточки-шагов/🟡-FUM-STEP-0093-перенести-автозапуск-шагов-в-универсальный-диспетчер.md",
  "card_content_sha256": "sha256:4586cd68d698e0ba9bd24d0629156fc1a8b38af0c418d7450a2c3a39395ae02c",
  "project_path": "README.md",
  "title": "Перенести автозапуск шагов в универсальный диспетчер",
  "task": "Подключить действующий запуск следующего шага как первый адаптер универсального диспетчера и мигрировать на месте уже существующую прикреплённую задачу и её пятиминутный heartbeat. Карточочный навык, схема рабочего набора и claim точного поколения выбора должны остаться специализированным модулем, вызываемым общим слоем, а не быть переписаны в универсальный реестр.",
  "criteria": [
    "В реестре создано одно active-задание адаптера следующего шага с точной целью текущего checkout и ветки, без копирования задачи и критериев карточки.",
    "Общий диспетчер вызывает существующие `show`, `claim` и release-восстановление и сохраняет `branch_ref`, `step_id`, `selection_id`, `card_id`, содержательный хэш и двойную проверку занятости Codex.",
    "Прикреплённая задача найдена по проверяемой совокупности host-признаков и обновлена на месте; новая задача или второй heartbeat не создаются, непрозрачный локальный ID не публикуется.",
    "Heartbeat-промпт, AGENTS.md, контракты очереди, документация, реестр названий и связанные тесты различают общий плановый тик, карточочный адаптер и обычную исполнительскую задачу.",
    "Плановый тик остаётся без FIFO-билета и без изменения checkout или внешнего эффекта; созданная исполнительская задача первым инструментальным действием входит в FIFO и подтверждает оба уровня fence.",
    "Пользовательский ход в той же прикреплённой задаче не наследует исключение heartbeat и при мутации проходит обычный корневой контракт.",
    "Stop/Start всего heartbeat сохраняют существующую цель, расписание и историю и не освобождают claim уже созданного задания.",
    "Автономные тесты старого next-step-контракта и нового диспетчера проходят, а контролируемый read-only host-аудит подтверждает одну прикреплённую задачу и один heartbeat."
  ]
}
````

## Identifikator seansa Codex

Codex-Thread-ID: 019fd120-1127-7980-8e5d-b6a9dd1d3e48

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — primenyalsya kak publikacionnaya granica lokaljnyikh CLI i host-interfejsov.
- `fum-ocheredj-zadach-git-vetki` — registraciya v FIFO, dopusk i podgotovka atomarnogo commit+handoff bez obyichnogo `git commit`.
- `fum-dispetcher-avtomatizacij-fum` i `fum-sleduyusjhij-shag-vetki` — obsjhij reyestr, adapter, dva urovnya fence, renderer heartbeat i vosstanovleniye terminala.
- `fum-proverka-nazvanij-avtomatizacij`, `fum-reyestr-planirovaniya` i `fum-svezhestj-markdown` — reyestryi imyon i planirovaniya, zhiznennyij cikl kartochki i svezhestj proizvodnoj dokumentacii.
- Host-interfejsyi Codex dlya avtomatizacij, zadach i proyektov — toljko dlya kontroliruyemogo snimka, obnovleniya susjhestvuyusjhikh zapisej na meste i readback-audita; novyiye zapisi ne sozdavalisj.
- `fum-moskovskoye-vremya-rabochej-sessii` — kanonicheskaya para vremeni rabochej sessii.

## Proverki

- 156 avtonomnyikh testov adaptera sleduyusjhego shaga prokhodyat.
- 31 avtonomnyij test universaljnogo dispetchera, 58 testov FIFO-ocheredi i 22 testa reyestra nazvanij prokhodyat.
- Rabochij nabor `master` validen: 9 kandidatov, odna gotovaya FUM-STEP-0094, 7 `paused` i 1 `blocked`; sokhranyonnyij reyestr planirovaniya vosproizvodim.
- Dva posledovateljnyikh host-readback podtverdili tu zhe prikreplyonnuyu zadachu, tot zhe heartbeat, neizmennyiye celj, pyatiminutnoye raspisaniye i status, tochnyij itogovyij renderer i otsutstviye dublikata.
- Polnyij smoke-check i ostaljnyiye pryamyiye vyizovyi sokhranyayutsya v upravlyayemom zhurnale [otchyota](otchyot.md).

## Povliyal na fajlyi

- [tekusjhij zapros](zapros.md)
- [tekusjhij otchyot](otchyot.md)
- [materialyi tekusjhej sessii](materialyi/)
- [AGENTS.md](../../AGENTS.md) i [kornevoj obzor](../../README.md)
- [glossarij](../../Glossarij/) i [dokumentaciya](../../Dokumentaciya/)
- [instrumentyi](../../Instrumentyi/), vklyuchaya obsjhij dispetcher, adapter sleduyusjhego shaga, FIFO, reyestryi imyon i mashinnyiye proverki
- [planirovaniye](../../Planirovaniye/), vklyuchaya zavershyonnuyu FUM-STEP-0093, FUM-STEP-0094, rabochij nabor i reyestryi
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [indeks vremeni redaktirovaniya](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md) i [graf Obsidian](../../../../../.obsidian/graph.json)
- [indeks zhurnala](../README.md)
- [predshestvuyusjhij zapros o dispetchere](../2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [predshestvuyusjhij zapros o vyibore sleduyusjhego shaga](../2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)
- [predshestvuyusjhij zapros o kontrakte dispetchera](../2026-08-05_05-48-39_MSK_zakrepitj-kontrakt-universaljnogo-dispetchera-avtomatizacij-FUM/zapros.md)
- [predshestvuyusjhij zapros o zasjhisjhyonnoj rezervacii](../2026-08-05_09-07-08_MSK_dobavitj-universaljnyij-vyibor-i-zasjhisjhyonnuyu-rezervaciyu-zapuska/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:34cb5101a370b209567eef8adcd9fbcefd3ee60f31978f1fa12adaac1f4251e6 -->
<!-- FUM-MD-RECENCY:END -->
