# Otchyot 2026-07-06 13:26:31 MSK - Zakrepitj soderzhateljnyiye nazvaniya ChatGPT importov

Sessiya zakrepila pravilo, chto import znanij iz ChatGPT-dialogov dolzhen poluchatj nazvaniye po smyislu samogo dialoga. Fajl zaprosa i svyazannyij zhurnaljnyij otchyot teperj dolzhnyi pomogatj cheloveku ponyatj, kakaya tema byila vnesena v [pamyatj FUM](../../Glossarij/pamyatj-FUM.md), yesjhyo do otkryitiya arkhivirovannogo istochnika.

## Chto izmenilosj

- V [AGENTS.md](../../AGENTS.md) dobavleno pravilo: korotkoye nazvaniye zaprosa pri importe ChatGPT-dialoga vyibirayetsya posle pervichnogo chteniya ili izvlecheniya soderzhaniya dialoga i otrazhayet yego temu, tezis ili osnovnoj vklad.
- V lokaljnom navyike [fum-request-materials](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md) obnovlyon osnovnoj protokol: fajl iskhodnogo zaprosa sozdayotsya s korotkim nazvaniyem po pravilam `AGENTS.md`, a dlya ChatGPT-dialogov eto nazvaniye vyibirayetsya po soderzhaniyu.
- V navigacii zaprosov dobavlena svyazj ot predyidusjhej rabochej sessii k tekusjhej.
- V spiske sleduyusjhikh shagov zafiksirovano, chto sessiya ne dobavila novyikh proyektnyikh prodolzhenij, a utochnila sluzhebnoye pravilo vedeniya pamyati.

## Resheniye

Obsjheye nazvaniye vrode `интегрировать-диалог-chatgpt-pro` boljshe ne schitayetsya normaljnyim itogovyim imenem, yesli soderzhaniye dialoga dostupno. Takoj fallback ostayotsya dopustimyim toljko pri nedostupnosti soderzhaniya; v etom sluchaye prichina dolzhna byitj yavno zapisana v fajle zaprosa i zhurnale, chtobyi potom byilo ponyatno, pochemu imya ne soobsjhayet temu istochnika.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-06_13-26-31_MSK_закрепить-содержательные-названия-chatgpt-импортов.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-06_13-26-31_MSK_закрепить-содержательные-названия-chatgpt-импортов.md`

## Vozmozhnoye prodolzheniye

Novogo proyektnogo prodolzheniya ne dobavleno. Yesli pozzhe okazhetsya, chto takiye imena mozhno nadyozhno predlagatj avtomaticheski po izvlechyonnomu `chatgpt-share.messages.json` ili oformlennomu Markdown-sloyu, eto mozhno budet razvitj kak otdeljnuyu proveryayemuyu funkciyu `fum-request-materials`.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-06 13:26:31 MSK - Zakrepitj soderzhateljnyiye nazvaniya ChatGPT importov](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:82881f6ebfcf4dc84275617cffbe2678fa3bdd0dddb4435507731932ad080d97 -->
<!-- FUM-MD-RECENCY:END -->
