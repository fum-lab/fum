# Otchyot 2026-07-02 22:43:41 MSK - Imena fajlov zaprosov

V rabochej sessii zakrepleno novoye pravilo imenovaniya fajlov [iskhodnyikh zaprosov](../../Glossarij/iskhodnyij-zapros.md): posle moskovskogo vremeni v imeni fajla teperj zapisyivayetsya korotkoye nazvaniye zaprosa, analogichnoye zagolovku kommita, a tot zhe zagolovok povtoryayetsya v pervoj stroke samogo fajla. Pervyij fajl, sozdannyij po etomu pravilu, - [tekusjhij iskhodnyij zapros](zapros.md).

Pravilo dobavleno v [AGENTS.md](../../AGENTS.md), glossarnuyu statjyu ob iskhodnom zaprose, instrukcii `fum-session-coherence` i `fum-smoke-check`, a takzhe v pravilo imenovaniya zhurnala. Lokaljnaya proverka svyaznosti sessii obnovlena cherez test: novyij format imeni prokhodit avtomaticheskuyu proverku, istoricheskiye fajlyi bez korotkogo nazvaniya ostayutsya dopustimyimi dlya obratnoj sovmestimosti.

Povtoryayemaya chastj rabotyi srazu perenesena v avtomatizaciyu: proverka `fum-session-coherence` teperj stroit chelovekochitayemyiye podpisi iz suffiksa imeni fajla i proveryayet ozhidayemyij zagolovok zaprosa i zhurnala.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - snachala ozhidayemo padalo na starom formate imeni, posle obnovleniya skripta proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-02_22-43-41_MSK_имена-файлов-запросов.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-02_22-43-41_MSK_имена-файлов-запросов.md` - proshlo: 14 shagov.

## Istochniki

- [iskhodnyij zapros 2026-07-02 22:43:41 MSK - Imena fajlov zaprosov](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e59a82d5eb362517ffd3afe9f5299ab194e23c1422ec42fd83ac654946df4e6c -->
<!-- FUM-MD-RECENCY:END -->
