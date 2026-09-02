# Otchyot 2026-07-01 14:31:25 MSK

## Glavnoye

V [svodnoj tablice trebovanij i realizacij FUM](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md) razvedenyi dve stadii predpolagayemoj realizacii: tekusjhaya dokumentacionnaya stadiya i budusjhaya [korobochnaya FUM](../../Glossarij/korobochnaya-realizaciya-FUM.md). Teperj odin i tot zhe sloj trebovanij pokazyivayet, chto mozhno podderzhivatj v nyineshnej Markdown-pamyati i chto dolzhno statj vstroyennyim servisom, interfejsom, runtime-modulem ili upravlyayemyim konturom v produktovoj realizacii.

## Chto izmenilosj

- Yedinyij stolbec variantov realizacii v svodnoj tablice zamenyon dvumya stolbcami: realizaciya na dokumentacionnoj stadii i realizaciya v korobochnoj FUM.
- [Planovyij JSON-reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json) peresobran po skheme `fum.planning.requirements-registry.v2`.
- Avtomatizaciya [fum-planning-registry](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md) teperj sokhranyayet dva polya: `documentation_stage_implementation` i `boxed_fum_implementation`.
- Planovyij indeks i spisok predlozhenij obnovlenyi, chtobyi tekusjhaya navigaciya ukazyivala na novoye razdeleniye stadij.

## Resheniya

Skhema reyestra podnyata do `v2`, potomu chto pole `implementation_options` zameneno dvumya raznyimi smyislovyimi gruppami. Eto ne toljko kosmeticheskaya pravka tablicyi: budusjhiye proverki teperj mogut otdeljno sveryatj dokumentacionnyiye artefaktyi i predpolagayemyiye elementyi korobochnoj realizacii.

Novyikh predlozhenij o sleduyusjhikh shagakh iz etoj sessii ne dobavleno. Blizhajshiye prodolzheniya uzhe pokryityi susjhestvuyusjhimi predlozheniyami o pasporte korobochnoj realizacii, lokaljnom agente, interfejse uzla i drugikh planovyikh artefaktakh.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - proshlo, 3 testa.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_14-31-25_MSK.md` - proshlo.

## Istochniki

- [iskhodnyij zapros 2026-07-01 14:31:25 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a54cd37c9dd18715e05b7975133f89a231b809c3a50b7c05304fa5f194413f51 -->
<!-- FUM-MD-RECENCY:END -->
