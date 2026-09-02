# Otchyot 2026-07-01 14:02:57 MSK

## Glavnoye

Vyipolnen regressionnyij zapusk vsekh lokaljnyikh testov avtomatizacij, najdennyikh v tekusjhej [pamyati FUM](../../Glossarij/pamyatj-FUM.md): 38 testov proshli bez padenij.

## Chto proveryalosj

- `fum-doc-aggregation`
- `fum-estimates`
- `fum-md-recency`
- `fum-planning-registry`
- `fum-request-materials`
- `fum-session-coherence`

## Resheniya

Regressionnyij zapusk vyipolnen vruchnuyu otdeljnyimi dokumentirovannyimi komandami iz [Instrumentyi/README.md](../../Instrumentyi/README.md), potomu chto v repozitorii poka net yedinoj avtomatizacii dlya zapuska vsekh testov odnim interfejsom.

Zadacha povtoryayemaya, poetomu blizhajsheye prodolzheniye zafiksirovano v [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md): sobratj yedinyij lokaljnyij smoke-check repozitoriya, chtobyi budusjhiye sessii ne sobirali nabor komand vruchnuyu.

## Proverki

- `find Инструменты -path '*/tests/test_*.py' -print | sort` - obnaruzhenyi 6 testovyikh fajlov, vse oni pokryityi regressionnyim zapuskom.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - proshlo, 4 testa.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - proshlo, 5 testov.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-md-recency/tests -p 'test_*.py'` - proshlo, 4 testa.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - proshlo, 3 testa.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - proshlo, 15 testov.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo, 7 testov.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; zapuskalsya posle soderzhateljnyikh pravok pered finaljnoj proverkoj svyaznosti.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_14-02-57_MSK.md` - proshlo.

## Istochniki

- [iskhodnyij zapros 2026-07-01 14:02:57 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8d1669a01418ce913349b20372cdea695f9f90f8b9fb90d115d93d3075b06690 -->
<!-- FUM-MD-RECENCY:END -->
