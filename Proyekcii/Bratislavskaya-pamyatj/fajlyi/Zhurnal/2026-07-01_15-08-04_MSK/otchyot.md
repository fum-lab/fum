# Otchyot 2026-07-01 15:08:04 MSK

## Glavnoye

MVP-kandidatyi FUM razlozhenyi po stadiyam realizacii. Teperj oni chitayutsya ne kak ploskaya ocheredj produktovyikh idej, a kak karta perekhoda ot tekusjhego [dokumentacionnogo prototipa FUM](../../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md) cherez perenosimyiye kontraktyi k budusjhej [korobochnoj realizacii FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md).

## Chto izmenilosj

- V [MVP-kandidatakh](../../Planirovaniye/MVP-kandidatyi/README.md) dobavlena stadijnaya karta kandidatov: dokumentaljnaya forma, perekhodnyij rezuljtat i korobochnaya forma.
- V [stadiyakh planirovaniya](../../Planirovaniye/stadii/README.md) i dvukh kartochkakh stadij dobavlenyi tablicyi, pokazyivayusjhiye rolj MVP-kandidatov na kazhdoj stadii.
- V [svodnoj tablice trebovanij i realizacij](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md) linejnaya ocheredj kandidatov zamenena stadijnoj ocheredjyu.
- [Dorozhnaya karta](../../Planirovaniye/dorozhnaya-karta.md), [indeks planirovaniya](../../Planirovaniye/README.md), [matrica otbora MVP-kandidatov](../../Planirovaniye/MVP-kandidatyi/matrica-otbora.md) i [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) svyazanyi s novoj stadijnoj interpretaciyej.
- Avtomatizaciya [fum-planning-registry](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md) obnovlena do skhemyi `fum.planning.requirements-registry.v4` i teperj izvlekayet `source_inventory.mvp_stage_map`.
- V sostav sessii vklyucheno izmeneniye [.obsidian/graph.json](../../../../../.obsidian/graph.json): Obsidian izmenil masshtab otobrazheniya grafa, a pravila pamyati trebuyut klassificirovatj i kommititj ustojchivoye sostoyaniye grafa.

## Resheniya

Fizicheski katalog `Планирование/MVP-кандидаты/` sokhranyon: kandidatyi ostayutsya produktovyimi kartochkami, a stadiya stala otdeljnyim izmereniyem chteniya. Eto pozvolyayet ne dublirovatj odni i te zhe kandidatyi po papkam, no yavno pokazyivatj, chto imenno mozhno zapuskatj sejchas, kakoj kontrakt dolzhen perezhitj perekhod i chem kandidat stanovitsya v korobochnoj FUM.

Novogo otdeljnogo predlozheniya o sleduyusjhem shage ne dobavleno. Stadijnaya raskladka usilila uzhe aktualjnyiye predlozheniya o pasporte pervogo yedinogo prilozheniya i pasporte tekusjhego dokumentacionnogo prototipa.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - proshlo, 3 testa.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; snachala obnovlenyi 15 Markdown-fajlov, zatem posle dopolneniya zaprosa i zhurnala obnovlenyi yesjhyo 3 fajla.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-01_15-08-04_MSK.md` - pervyij zapusk ostanovilsya na neklassificirovannom `.obsidian/graph.json`, posle dobavleniya etogo fajla v sostav sessii povtornyij zapusk proshyol 11 shagov, vklyuchaya 41 test lokaljnyikh avtomatizacij, proverku reyestra, recency-check i svyaznostj sessii.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_15-08-04_MSK.md` - proshlo.

## Istochniki

- [iskhodnyij zapros 2026-07-01 15:08:04 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:82b3e448e8c510a650b48442be8770113961ba39069874ef26152d88d522be71 -->
<!-- FUM-MD-RECENCY:END -->
