# Добавить событие поставки PR491 и направить локальные ссылки

## Источник

Адресное поручение ROOT в чате `01a07d3d-d376-7ad2-aafc-67e4c25a67eb`; полная переписка и ROOT JSONL в эту запись не копируются.

## Точный текст поручения

ROOT принял адресный архив через PR491 https://github.com/fum-lab/fum/pull/491 и f88044fe7a9e3119328ee7a4af187c6f43008b01 (exact push/ls-remote, GitHub merged=true). Поставщик Источники eb20975… partial от source60a…, только15файлов, не весь архив. FUMA source9c618e2b0cc6a57edd2b50609cd168e4cd0e029f с8/8 принят пока как поставка, не ROOT-интеграция/реальноеиспользование. Tools назначил реального consumer: writer01a192b8-3f85-73c3-a69c-38269efbb3be, iskhodniki/perekhod-vetok/fabrika-agentov/komanda.swift, готовит names-onlypreview и затем1–3узла. В своей доске новый конечный этап: обнови существующее объявление этим add-only событием по тому же контракту, не создавая второго реестра; точный source/source-version/state и отсутствие consumer-use покаUNKNOWN. Потребители Tools01a17797… и Индексы01a17838-f2eb-7f03-ad72-c5f50e73d8aa; передай им прямую локальную read-onlyссылку, получи ACK отдельноотприменения. Python/ROOT RAWнеисполнять; source-onlyпроверкиидоставкакаквпредыдущемгранте, никакогоновогоruntime.

## Сохранённая основа

- W `/Users/fum/.codex/worktrees/doska-nuzhdy-01a17815/FUM`, ref `refs/heads/fum-lab/fum/doska-obyyavlenij/potreby-01a17815`.
- На старте этапа HEAD `d75a2dced627493bba14da298386f2ef338377d7`, чистое дерево и тот же OID на `origin`.
- Существующее объявление: `doska-obyyavlenij/zapisi/lokalnye-svyazi-fabrika-df60f239.json`, snapshot commit `795097e54796941174316f05f04f5bec5c524392`; это единственная запись, куда будет добавлено событие.

## Намерение

Добавить одно append-only событие в указанное существующее объявление, с точными source/version/hash для ROOT merge, частичной поставки Источников и поставки FUMA. Отдельно указать назначенного Tools writer и наблюдаемое `UNKNOWN` для его версии preview, получения, приёмки и реального использования. Направить двум указанным потребителям read-only команду точного Git-чтения, сохранить ACK отдельно от применения. Не изменять другие реестры, работу потребителей и их W/ref; не запускать Python, ROOT RAW/JSONL, legacy reader или новый runtime.
