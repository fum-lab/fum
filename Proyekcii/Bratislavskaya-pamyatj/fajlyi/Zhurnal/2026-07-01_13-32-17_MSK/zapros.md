# Iskhodnyij zapros 2026-07-01 13:32:17 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-01 12:11:27 MSK](../2026-07-01_12-11-27_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-07-01 13:44:13 MSK](../2026-07-01_13-44-13_MSK/zapros.md)

## Tekst zaprosa

> Подготовить машинно читаемый реестр требований, вариантов реализации и кандидатов, который можно проверять или пересобирать из дорожной карты, направлений, MVP-кандидатов, предложений и открытых вопросов.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.update_plan`, `functions.exec_command`, `functions.apply_patch`, `multi_tool_use.parallel`.
- `functions.update_plan` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vedeniya plana rabochej sessii.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, zapuska testov, sborki i validacii reyestra, recency-avtomatizacii i proverki svyaznosti.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-planning-registry` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); sozdan i ispoljzovan dlya sborki i proverki mashinno chitayemogo reyestra planovogo sloya.
- `fum-md-recency` - versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md); ispoljzovan dlya obnovleniya sluzhebnyikh recency-metok i indeksa Markdown-fajlov.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); ispoljzovan dlya proverki svyaznosti tekusjhej rabochej sessii.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 Apple Git-156 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya lokaljnyikh testov, sborki JSON-reyestra, recency-avtomatizacii i proverki svyaznosti.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj standartnyim sposobom; ispoljzovanyi `sed`, `mkdir` i `date` bez sokhraneniya privatnogo mashinnogo sostoyaniya.

## Povliyal na fajlyi

- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Instrumentyi/fum-planning-registry/SKILL.md](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md)
- [Instrumentyi/fum-planning-registry/scripts/build-planning-registry.py](../../Instrumentyi/fum-reyestr-planirovaniya/scripts/build-planning-registry.py)
- [Instrumentyi/fum-planning-registry/tests/test_build_planning_registry.py](../../Instrumentyi/fum-reyestr-planirovaniya/tests/test_build_planning_registry.py)
- [Planirovaniye/README.md](../../Planirovaniye/README.md)
- [Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Zaprosyi/2026-07-01_12-11-27_MSK.md](../2026-07-01_12-11-27_MSK/zapros.md)
- [Zaprosyi/2026-07-01_13-32-17_MSK.md](zapros.md)
- [Zhurnal/2026-07-01_13-32-17_MSK.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)

## Chto sdelano

Sozdan mashinno chitayemyij JSON-reyestr [trebovanij, variantov realizacii i kandidatov](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json) so skhemoj `fum.planning.requirements-registry.v1`. Reyestr soderzhit normalizovannyiye stroki svodnoj tablicyi: trebovaniya, proveryayemyiye rezuljtatyi, variantyi realizacii, kandidatov i statusyi. Otdeljno v nyom sokhranyon inventarj istochnikov: gorizontyi dorozhnoj kartyi, napravleniya proyektirovaniya, MVP-kandidatyi, ocheredj produktovyikh kandidatov, aktualjnyiye i istoricheskiye predlozheniya, a takzhe voprosyi po statusam.

Sozdana lokaljnaya avtomatizaciya [fum-planning-registry](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md) so skriptom `build-planning-registry.py` i testami. Komanda `build` peresobirayet JSON iz Markdown-istochnikov, a komanda `validate` zanovo stroit ozhidayemyij rezuljtat i soobsjhayet, yesli sokhranyonnyij reyestr ustarel. V JSON takzhe fiksiruyutsya khyeshi iskhodnyikh Markdown-fajlov bez sluzhebnyikh recency-blokov, chtobyi izmeneniye istochnika byilo vidno mashine.

Planovyiye indeksyi obnovlenyi ssyilkami na novyij sloj: [Planirovaniye/README.md](../../Planirovaniye/README.md), [svodnaya tablica trebovanij i realizacij](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md), [reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) i [Instrumentyi/README.md](../../Instrumentyi/README.md). Predlozheniye o mashinno chitayemom reyestre pereneseno iz aktualjnyikh predlozhenij v istoriyu vyipolnennyikh.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты -p 'test_*.py'` - ne ispoljzovano kak itogovaya proverka: `unittest` ne obnaruzhil testyi iz-za strukturyi katalogov; vmesto etogo zapusjhenyi yavnyiye testovyiye naboryi nizhe.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-md-recency/tests -p 'test_*.py'` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - proshlo.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo, reyestr peresobran.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo, sluzhebnyiye recency-metki i indeks Markdown-fajlov obnovlenyi.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_13-32-17_MSK.md` - proshlo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:5e08a99cfd07e63b881a3ff6ba8397e56c4e9d743e136e60df4cf97365818191 -->
<!-- FUM-MD-RECENCY:END -->
