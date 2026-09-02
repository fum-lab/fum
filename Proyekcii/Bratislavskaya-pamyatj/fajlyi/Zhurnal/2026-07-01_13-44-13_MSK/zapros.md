# Iskhodnyij zapros 2026-07-01 13:44:13 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-01 13:32:17 MSK](../2026-07-01_13-32-17_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-07-01 14:02:57 MSK](../2026-07-01_14-02-57_MSK/zapros.md)

## Tekst zaprosa

> Расширить проверку связности рабочей сессии так, чтобы она помогала обнаруживать мета-запросы о правилах [памяти FUM](../Глоссарий/память-FUM.md), которые должны быть заведены в `Запросы/`.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.update_plan`, `functions.exec_command`, `functions.apply_patch`, `multi_tool_use.parallel`.
- `functions.update_plan` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vedeniya plana rabochej sessii.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, zapuska testov, peresborki planovogo reyestra, recency-avtomatizacii i proverki svyaznosti.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-planning-registry` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); ispoljzovan dlya peresborki i proverki mashinno chitayemogo reyestra planovogo sloya posle perenosa predlozheniya v istoriyu.
- `fum-md-recency` - versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md); ispoljzovan dlya obnovleniya sluzhebnyikh recency-metok i indeksa Markdown-fajlov.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); izmenyon i ispoljzovan dlya proverki svyaznosti tekusjhej rabochej sessii.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 Apple Git-156 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya lokaljnyikh testov, peresborki JSON-reyestra, recency-avtomatizacii i proverki svyaznosti.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj standartnyim sposobom; ispoljzovanyi `sed`, `ls`, `head`, `tail`, `sort` i `date` bez sokhraneniya privatnogo mashinnogo sostoyaniya.

## Povliyal na fajlyi

- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Instrumentyi/fum-session-coherence/SKILL.md](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [Instrumentyi/fum-session-coherence/scripts/check-session-coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py)
- [Instrumentyi/fum-session-coherence/tests/test_check_session_coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [Zaprosyi/2026-07-01_13-32-17_MSK.md](../2026-07-01_13-32-17_MSK/zapros.md)
- [Zaprosyi/2026-07-01_13-44-13_MSK.md](zapros.md)
- [Zhurnal/2026-07-01_13-44-13_MSK.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)

## Chto sdelano

Proverka [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) rasshirena evristikoj dlya vozmozhnyikh nezavedyonnyikh meta-zaprosov o pravilakh [pamyati FUM](../../Glossarij/pamyatj-FUM.md). Teperj ona prosmatrivayet zatronutyiye Markdown-fajlyi vne `Запросы/`: yesli tekst pokhozh na fiksaciyu voprosa, utochneniya, otveta ili proverki poljzovatelya o pravilakh pamyati, poryadke rabochej sessii, `AGENTS.md` ili `Запросы/`, fajl dolzhen ssyilatjsya na konkretnyij iskhodnyij zapros.

Evristika ne podmenyayet smyislovuyu proverku agentom. Ona namerenno rabotayet kak rannij signal: yesli sluzhebnaya zametka, zhurnal ili drugoj Markdown fiksiruyet poljzovateljskoye meta-utochneniye bez ssyilki na fajl `Запросы/<YYYY-MM-DD_HH-MM-SS_MSK>.md`, proverka soobsjhayet o vozmozhnom nezaregistrirovannom meta-zaprose.

Predlozheniye o takom rasshirenii pereneseno iz aktualjnyikh predlozhenij v istoriyu vyipolnennyikh, a mashinno chitayemyij planovyij reyestr peresobran iz obnovlyonnyikh istochnikov.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - snachala ozhidayemo upalo na novom TDD-teste do realizacii; posle realizacii proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_13-44-13_MSK.md` - proshlo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a325b36cd25f1b88427ab5cb7c623db5a32c59cbb82cd88e883389523a1c68b7 -->
<!-- FUM-MD-RECENCY:END -->
