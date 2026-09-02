# Otchyot 2026-07-01 14:58:32 MSK

## Glavnoye

V [Planirovaniye/](../../Planirovaniye/README.md) sozdan otdeljnyij sloj [stadij planirovaniya FUM](../../Planirovaniye/stadii/README.md). Teperj tekusjhij [dokumentacionnyij prototip FUM](../../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md) i budusjhaya [korobochnaya realizaciya FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md) opisanyi v otdeljnyikh vlozhennyikh papkakh, a osnovnyiye planovyiye materialyi ssyilayutsya na eto razdeleniye.

## Chto izmenilosj

- Sozdan katalog `Планирование/стадии/` s indeksom i dvumya kartochkami stadij.
- [Dorozhnaya karta](../../Planirovaniye/dorozhnaya-karta.md), [svodnaya tablica](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md), [indeks planirovaniya](../../Planirovaniye/README.md) i [spisok predlozhenij](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) svyazanyi s novyim stadijnyim sloyem.
- Avtomatizaciya [fum-planning-registry](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md) obnovlena do skhemyi `fum.planning.requirements-registry.v3` i teperj vklyuchayet `source_inventory.stages`.
- Test planovogo reyestra snachala zafiksiroval otsutstviye stadij v mashinnom sloye, zatem byil dovedyon do prokhozhdeniya posle obnovleniya skripta.

## Resheniya

Dlya pervoj versii stadijnogo razdeleniya vyibranyi dve uzhe zakreplyonnyiye formyi: tekusjhij dokumentacionnyij prototip i budusjhaya korobochnaya realizaciya. Eto napryamuyu prodolzhayet predyidusjheye razdeleniye svodnoj tablicyi na dokumentaljnuyu i korobochnuyu formyi realizacii i ne vvodit novyij paralleljnyij nabor abstraktnyikh etapov.

Novogo otdeljnogo predlozheniya o sleduyusjhikh shagakh ne dobavleno: aktualjnoye predlozheniye o pasporte pervogo yedinogo prilozheniya korobochnoj realizacii uzhe pokryivayet blizhajsheye prodolzheniye, kotoroye stalo vidneye posle poyavleniya papok stadij.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - snachala ozhidayemo upalo na otsutstvii `source_inventory.stages`, zatem proshlo posle obnovleniya avtomatizacii.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; obnovlenyi sluzhebnyiye recency-metki i indeks Markdown-fajlov.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-01_14-58-32_MSK.md` - proshlo; smoke-check vyipolnil 11 shagov, vklyuchaya 41 lokaljnyij test.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_14-58-32_MSK.md` - proshlo otdeljnyim finaljnyim zapuskom posle obnovleniya recency-metok.

## Istochniki

- [iskhodnyij zapros 2026-07-01 14:58:32 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:18133d120662c2aee3784de70a03bad58e32bb97929970a4972ac7dc5927033e -->
<!-- FUM-MD-RECENCY:END -->
