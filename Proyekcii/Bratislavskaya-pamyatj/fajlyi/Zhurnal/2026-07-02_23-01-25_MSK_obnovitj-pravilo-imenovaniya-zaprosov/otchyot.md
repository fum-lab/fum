# Otchyot 2026-07-02 23:01:25 MSK - Obnovitj pravilo imenovaniya zaprosov

V rabochej sessii utochneno pravilo imenovaniya fajlov [iskhodnyikh zaprosov](../../Glossarij/iskhodnyij-zapros.md): korotkoye nazvaniye posle moskovskogo vremennogo prefiksa teperj oformlyayetsya kak zagolovok soobsjheniya kommita i nachinayetsya s glagola v infinitive. Tekusjhij zapros zafiksirovan uzhe v novom stile: [obnovitj-pravilo-imenovaniya-zaprosov](zapros.md).

Pravilo vneseno v [AGENTS.md](../../AGENTS.md) i glossarnuyu statjyu ob iskhodnom zaprose. Lokaljnaya avtomatizaciya [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) obnovlena cherez TDD: novyiye zagolovochnyiye imena proveryayutsya na start s russkim infinitivom, a istoricheskoye imya predyidusjhej sessii ostayotsya dopustimyim.

Indeks [zhurnala rabot](../README.md) zaodno dopolnen nedostayusjhimi otchyotami za 2026-07-02, chtobyi novaya zapisj byila svyazana s sosednimi rabochimi sessiyami togo zhe dnya.

Novyikh prodolzhenij dlya planovogo spiska ne vozniklo: izmeneniye zakryivayet utochneniye pravila i yego proveryayemoye zakrepleniye.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - snachala ozhidayemo padalo na otsutstvuyusjhej proverke infinitiva, posle obnovleniya skripta proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов.md` - proshlo: 14 shagov.

## Istochniki

- [iskhodnyij zapros 2026-07-02 23:01:25 MSK - Obnovitj pravilo imenovaniya zaprosov](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:58d0f17c2927fef158a6ef065a2f6090323d354ab2059332fd21c500f1847921 -->
<!-- FUM-MD-RECENCY:END -->
