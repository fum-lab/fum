# Iskhodnyij zapros 2026-07-02 23:01:25 MSK - Obnovitj pravilo imenovaniya zaprosov

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-02 22:43:41 MSK - Imena fajlov zaprosov](../2026-07-02_22-43-41_MSK_imena-fajlov-zaprosov/zapros.md)
- Sleduyusjhij zapros: [2026-07-03 08:21:17 MSK - Opisatj gibridnyij mozg lichnogo FUM](../2026-07-03_08-21-17_MSK_opisatj-gibridnyij-mozg-lichnogo-FUM/zapros.md)

## Tekst zaprosa

```text
Imena zaprosov budem delatj v stile zogolovkov soobsjhenij kommitov, nachinaya s glagola v infinitive
```

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.exec_command`, `functions.apply_patch`, `functions.update_plan`, `multi_tool_use.parallel`.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, zapuska lokaljnyikh avtomatizacij, proverok i Git-komand.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `functions.update_plan` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vedeniya kratkogo plana rabochej sessii.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-glossary` - versiya zadayotsya Git-istoriyej [lokaljnoj instrukcii](../../Instrumentyi/fum-glossarij/SKILL.md); ispoljzovan dlya utochneniya glossarnoj statji ob iskhodnom zaprose. Vneshnyaya odnoimyonnaya instrukciya iz poljzovateljskoj papki byila proverena i ne primenena, potomu chto ukazyivayet na drugoj katalog.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); ispoljzovan i obnovlyon cherez TDD dlya proverki novogo pravila imeni zaprosa.
- `fum-planning-registry` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); ispoljzovan dlya peresborki i proverki mashinno chitayemogo planovogo reyestra posle obnovleniya spiska predlozhenij.
- `fum-md-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md); ispoljzovan dlya obnovleniya sluzhebnyikh recency-metok i indeksa Markdown-fajlov.
- `fum-obsidian-graph-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md); ispoljzovan dlya sinkhronizacii teplovoj kartyi `.obsidian/graph.json` posle obnovleniya Markdown-recency.
- `fum-smoke-check` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md); ispoljzovan dlya itogovogo lokaljnogo smoke-check repozitoriya.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 Apple Git-156 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya lokaljnyikh avtomatizacij i proverochnyikh skriptov.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj standartnyim sposobom; ispoljzovanyi `date`, `sed` i `find` bez sokhraneniya privatnogo mashinnogo sostoyaniya.

## Povliyal na fajlyi

- [.obsidian/graph.json](../../../../../.obsidian/graph.json)
- [AGENTS.md](../../AGENTS.md)
- [Glossarij/iskhodnyij-zapros.md](../../Glossarij/iskhodnyij-zapros.md)
- [Zhurnal/README.md](../README.md)
- [Zhurnal/2026-07-02_23-01-25_MSK_obnovitj-pravilo-imenovaniya-zaprosov.md](otchyot.md)
- [Zaprosyi/2026-07-02_22-43-41_MSK_imena-fajlov-zaprosov.md](../2026-07-02_22-43-41_MSK_imena-fajlov-zaprosov/zapros.md)
- [Zaprosyi/2026-07-02_23-01-25_MSK_obnovitj-pravilo-imenovaniya-zaprosov.md](zapros.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Instrumentyi/fum-session-coherence/SKILL.md](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [Instrumentyi/fum-session-coherence/scripts/check-session-coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py)
- [Instrumentyi/fum-session-coherence/tests/test_check_session_coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)

## Chto sdelano

V [pravilakh povedeniya repozitoriya](../../AGENTS.md) i glossarnoj statjye [iskhodnyij zapros](../../Glossarij/iskhodnyij-zapros.md) zakrepleno, chto korotkoye nazvaniye zaprosa posle vremennogo prefiksa stroitsya kak zagolovok soobsjheniya kommita i nachinayetsya s glagola v infinitive.

Lokaljnaya proverka [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) obnovlena cherez TDD: dlya novyikh zagolovochnyikh imyon zaprosov ona proveryayet pervyij token suffiksa kak russkij infinitiv, no sokhranyayet obratnuyu sovmestimostj s istoricheskim zaprosom [2026-07-02 22:43:41 MSK - Imena fajlov zaprosov](../2026-07-02_22-43-41_MSK_imena-fajlov-zaprosov/zapros.md).

Pri obnovlenii [zhurnala rabot](../README.md) indeks dopolnen nedostayusjhimi otchyotami za 2026-07-02, chtobyi tekusjhaya zapisj ne visela otdeljno ot sosednikh rabochikh sessij.

Novyikh predlozhenij o sleduyusjhikh shagakh ne dobavleno: sessiya zakryivayet utochneniye tekusjhego pravila i svyazannoj avtomaticheskoj proverki.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - snachala ozhidayemo padalo na otsutstvuyusjhej proverke infinitiva, posle obnovleniya skripta proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo; planovyij JSON-reyestr peresobran.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; obnovlenyi sluzhebnyiye recency-metki i indeks Markdown-fajlov.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo; teplovaya karta `.obsidian/graph.json` sinkhronizirovana s obnovlyonnyimi Markdown-recency.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов.md` - proshlo: 14 shagov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a49a5e3e85f5c4ef6280e9557835d623a0453547f803140b3e10c0e0fba39d7d -->
<!-- FUM-MD-RECENCY:END -->
