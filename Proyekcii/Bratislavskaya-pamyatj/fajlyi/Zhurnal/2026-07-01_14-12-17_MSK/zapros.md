# Iskhodnyij zapros 2026-07-01 14:12:17 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-01 14:02:57 MSK](../2026-07-01_14-02-57_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-07-01 14:31:25 MSK](../2026-07-01_14-31-25_MSK/zapros.md)

## Tekst zaprosa

> Собрать единый локальный smoke-check репозитория, который запускает тесты всех локальных автоматизаций, пересборку проверяемых реестров, recency-проверку и проверку связности выбранной рабочей сессии без секретов и сетевых зависимостей по умолчанию.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.update_plan`, `functions.exec_command`, `functions.apply_patch`, `multi_tool_use.parallel`.
- `functions.update_plan` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vedeniya plana rabochej sessii.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, proverki versij, zapuska testov, smoke-check, recency-avtomatizacii, planovogo reyestra i proverki svyaznosti.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-smoke-check` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md); sozdan i ispoljzovan dlya yedinogo smoke-check repozitoriya.
- `fum-planning-registry` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); ispoljzovan cherez smoke-check dlya peresborki i proverki mashinno chitayemogo planovogo reyestra.
- `fum-md-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md); ispoljzovan dlya proverki i obnovleniya sluzhebnyikh recency-metok i indeksa Markdown-fajlov.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); ispoljzovan cherez smoke-check i otdeljnyim finaljnyim zapuskom dlya proverki svyaznosti tekusjhej rabochej sessii.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 Apple Git-156 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya zapuska lokaljnyikh testov, smoke-check, planovogo reyestra, recency-avtomatizacii i proverki svyaznosti.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj standartnyim sposobom; ispoljzovanyi `sed`, `find`, `date` i `mkdir` bez sokhraneniya privatnogo mashinnogo sostoyaniya.

## Povliyal na fajlyi

- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Instrumentyi/fum-smoke-check/SKILL.md](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [Instrumentyi/fum-smoke-check/scripts/run-smoke-check.py](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py)
- [Instrumentyi/fum-smoke-check/tests/test_run_smoke_check.py](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/tests/test_run_smoke_check.py)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Zaprosyi/2026-07-01_14-02-57_MSK.md](../2026-07-01_14-02-57_MSK/zapros.md)
- [Zaprosyi/2026-07-01_14-12-17_MSK.md](zapros.md)
- [Zhurnal/2026-07-01_14-12-17_MSK.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)

## Chto sdelano

Sozdana lokaljnaya avtomatizaciya [fum-smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md). Yeyo skript [run-smoke-check.py](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py) zapuskayet vse obnaruzhennyiye lokaljnyiye testyi `Инструменты/*/tests`, peresobirayet i validiruyet [planovyij JSON-reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json), vyipolnyayet recency-proverku bez zapisi i proveryayet svyaznostj vyibrannoj rabochej sessii cherez [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md).

Novaya avtomatizaciya proshla TDD-kontur: snachala dobavlen testovyij kontrakt dlya postroyeniya spiska shagov, rezhima `--skip-session-coherence` i obyazateljnosti `--request` v polnom rezhime, zatem realizovan runner. Smoke-check zakreplyon v [kataloge instrumentov](../../Instrumentyi/README.md), [reyestre sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) i razdele o vosproizvodimyikh avtomatizaciyakh v [proizvodnoj dokumentacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md).

Predlozheniye o smoke-check pereneseno iz aktualjnyikh predlozhenij v istoriyu vyipolnennyikh predlozhenij v [planirovanii](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md). Mashinno chitayemyij planovyij reyestr peresobran posle izmeneniya planovogo sloya.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` - proshlo, 3 testa.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-01_14-12-17_MSK.md` - proshlo; smoke-check vyipolnil 11 shagov: 7 testovyikh naborov lokaljnyikh avtomatizacij, 41 test, peresborku i proverku planovogo reyestra, recency-proverku i proverku svyaznosti tekusjhej sessii.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; zapuskalsya posle soderzhateljnyikh pravok pered finaljnoj proverkoj.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_14-12-17_MSK.md` - proshlo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0ef889063133af48458f96d4c1d4095475215283ef389a6a3fee4950102a243e -->
<!-- FUM-MD-RECENCY:END -->
