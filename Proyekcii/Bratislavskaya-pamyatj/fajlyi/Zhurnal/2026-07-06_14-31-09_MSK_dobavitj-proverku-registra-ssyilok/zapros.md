# Iskhodnyij zapros 2026-07-06 14:31:09 MSK - Dobavitj proverku registra ssyilok

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-06 13:52:08 MSK - Zakrepitj Swift yazyikom prototipov](../2026-07-06_13-52-08_MSK_zakrepitj-Swift-yazyikom-prototipov/zapros.md)
- Sleduyusjhij zapros: [2026-07-06 14:49:39 MSK - Opisatj iyerarkhiyu funkcij i dannyikh](../2026-07-06_14-49-39_MSK_opisatj-iyerarkhiyu-funkcij-i-dannyikh/zapros.md)

## Tekst zaprosa

```text
Dobavim mekhanizm proverki sootvetstviya registra v imenakh fajlov i ssyilkakh na nikh, chtobyi repozitorij korrektno rabotal ne toljko na nechuvstviteljnyikh k registru fajlovyikh sistemakh, no i na chuvstviteljnyikh.
```

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.exec_command`, `functions.apply_patch` i `multi_tool_use.parallel`.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, zapuska lokaljnyikh avtomatizacij, testov, proverok i Git-komand.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); izmenyon i ispoljzovan dlya proverki registra lokaljnyikh Markdown-ssyilok, svyaznosti rabochej sessii i Git-sostoyaniya.
- `fum-planning-registry` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); ispoljzovan dlya peresborki i proverki mashinno chitayemogo planovogo reyestra posle obnovleniya predlozhenij.
- `fum-md-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md); ispoljzovan dlya obnovleniya sluzhebnyikh recency-metok i indeksa Markdown-fajlov.
- `fum-obsidian-graph-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md); ispoljzovan dlya sinkhronizacii teplovoj kartyi `.obsidian/graph.json` posle obnovleniya Markdown-recency.
- `fum-smoke-check` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md); ispoljzovan dlya itogovogo lokaljnogo smoke-check repozitoriya.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 Apple Git-157 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya lokaljnyikh avtomatizacij, diagnosticheskogo skanirovaniya Markdown-ssyilok i testov.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj standartnyim sposobom; ispoljzovanyi `date`, `find`, `ls`, `sed`, `tail` i `awk` bez sokhraneniya privatnogo mashinnogo sostoyaniya.

## Povliyal na fajlyi

- [.obsidian/graph.json](../../../../../.obsidian/graph.json)
- [AGENTS.md](../../AGENTS.md)
- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Zhurnal/2026-07-06_14-31-09_MSK_dobavitj-proverku-registra-ssyilok.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Zaprosyi/2026-07-06_13-52-08_MSK_zakrepitj-Swift-yazyikom-prototipov.md](../2026-07-06_13-52-08_MSK_zakrepitj-Swift-yazyikom-prototipov/zapros.md)
- [Zaprosyi/2026-07-06_14-31-09_MSK_dobavitj-proverku-registra-ssyilok.md](zapros.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/fum-session-coherence/SKILL.md](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [Instrumentyi/fum-session-coherence/scripts/check-session-coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py)
- [Instrumentyi/fum-session-coherence/tests/test_check_session_coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)

## Chto sdelano

V susjhestvuyusjhuyu lokaljnuyu avtomatizaciyu [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) dobavlena proverka registra lokaljnyikh Markdown-ssyilok. Skript teperj obkhodit vse Markdown-fajlyi repozitoriya, dlya kazhdoj lokaljnoj ssyilki nakhodit fakticheskij putj po komponentam bez uchyota registra i soobsjhayet oshibku, yesli napisaniye ssyilki otlichayetsya ot realjnogo imeni fajla ili kataloga.

Proverka specialjno rabotayet i na nechuvstviteljnoj k registru fajlovoj sisteme: ssyilka mozhet fizicheski otkryivatjsya lokaljno, no yesli yeyo registr ne sovpadayet s realjnyim putyom, `fum-session-coherence` vyidayot oshibku `Markdown link case mismatch`. Blagodarya etomu repozitorij dolzhen ostavatjsya perenosimyim na chuvstviteljnyiye k registru fajlovyiye sistemyi.

Pravilo tochnogo registra lokaljnyikh Markdown-ssyilok zakrepleno v [AGENTS.md](../../AGENTS.md), a opisaniye avtomatizacii obnovleno v instrukcii, reyestre instrumentov i dokumente o [vosproizvodimyikh avtomatizaciyakh FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md).

## Resheniye po avtomatizacii

Zapros byil napryamuyu pro povtoryayemuyu proverku, poetomu rezuljtat oformlen kak TDD-rasshireniye susjhestvuyusjhej avtomatizacii, a ne kak razovaya ruchnaya proverka. Snachala dobavlen test na Markdown-ssyilku s nevernyim registrom puti vne spiska zatronutyikh fajlov, zatem realizaciya dovedena do prokhozhdeniya testa i vklyuchena v obyichnyij smoke-check repozitoriya.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-06_14-31-09_MSK_добавить-проверку-регистра-ссылок.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-06_14-31-09_MSK_добавить-проверку-регистра-ссылок.md` - proshlo.

## Prikreplyayemyiye materialyi

Net.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8c5a391d6b72d98c7e20b86096f7549725f066eb495c34eff6c52c97a6bc02f8 -->
<!-- FUM-MD-RECENCY:END -->
