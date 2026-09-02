# Otchyot 2026-07-03 11:23:15 MSK - Vyistroitj graf zavisimostej korobochnoj realizacii FUM

V rabochej sessii sozdan planovyij [graf zavisimostej elementov korobochnoj realizacii FUM](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md). On perevodit vopros o poryadke realizacii iz obsjhej ocheredi MVP-kandidatov v yavnuyu zavisimostnuyu skhemu: kakiye sloi dolzhnyi poyavitjsya do yedinogo prilozheniya, kakiye mozhno razvivatj paralleljno, a kakiye ostayutsya daljnimi ogranichennyimi konturami.

Glavnyij vyivod grafa: pervaya korobochnaya forma FUM ne dolzhna nachinatjsya s krasivoj obolochki bez vnutrennego kontrakta. Snachala nuzhnyi reyestr proiskhozhdeniya, dostup i publikacionnaya chistota, zatem konturyi rabochej sessii i istochnikov, svyaznaya pamyatj, katalog lokaljnyikh avtomatizacij, format trassyi i ogranichennyij runtime. Toljko posle etogo yedinoye prilozheniye lokaljnoj pamyati stanovitsya proveryayemyim integracionnyim produktom.

V [stadii korobochnoj realizacii](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md), indekse [stadij planirovaniya](../../Planirovaniye/stadii/README.md), obsjhem [indekse planirovaniya](../../Planirovaniye/README.md) i [svodnoj tablice trebovanij](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md) dobavlenyi ssyilki na novyij graf, chtobyi on chitalsya kak chastj planovogo sloya, a ne kak otdeljnaya zametka.

V [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) dobavleno prodolzheniye: pri daljnejshem ispoljzovanii grafa perevesti yego v mashinno chitayemyij sloj planirovaniya s identifikatorami elementov, zavisimostyami, blokiruyusjhimi riskami i kriteriyami gotovnosti. V tekusjhej sessii eto ne avtomatizirovano, potomu chto snachala nuzhno byilo zafiksirovatj smyislovuyu strukturu i proveritj, chto ona soglasuyetsya s uzhe susjhestvuyusjhimi MVP-kandidatami.

Otkryityikh voprosov ne dobavleno: novaya skhema utochnyayet poryadok realizacii uzhe opisannyikh elementov korobochnoj stadii i ne vvodit konfliktuyusjheye trebovaniye.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build` - proshlo.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check` - proshlo.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-03_11-23-15_MSK_выстроить-граф-зависимостей-коробочной-реализации-FUM.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-03_11-23-15_MSK_выстроить-граф-зависимостей-коробочной-реализации-FUM.md` - proshlo.

## Istochniki

- [iskhodnyij zapros 2026-07-03 11:23:15 MSK - Vyistroitj graf zavisimostej korobochnoj realizacii FUM](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:98d2dd96d5e2b6a53075f3312b9c58e609dc292e7607658bd0ea837e48182e2e -->
<!-- FUM-MD-RECENCY:END -->
