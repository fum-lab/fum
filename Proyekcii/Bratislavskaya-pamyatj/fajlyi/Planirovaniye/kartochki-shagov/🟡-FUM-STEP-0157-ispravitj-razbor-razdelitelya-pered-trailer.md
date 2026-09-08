+++
schema_version = 1
card_id = "FUM-STEP-0157"
status = "active"
+++
# Ispravitj razbor razdelitelya pered trailer

## Zadacha

Ispravitj vyideleniye konechnogo trailer-bloka soobsjheniya kommita v validatore svyaznosti pri neskoljkikh pustyikh strokakh pered nim.

## Pochemu sejchas

Diagnostika 101 obnaruzhila lozhnyij otkaz praviljnogo identifikatora zadachi posle tryokh perevodov stroki. Normalizaciya tekusjhego soobsjheniya pozvolyayet prodolzhitj rabotu, no ostavlyayet defekt raspoznavaniya.

## Kriterii zaversheniya

- Krasnaya regressiya vosproizvodit fakticheskij razdelitelj i prokhodit posle ispravleniya; variantyi chisla pustyikh strok proverenyi na ustanovlennoj granice formata.
- Ne oslablenyi otkazyi dlya otsutstvuyusjhego, nevernogo ili povtornogo Codex-Thread-ID i soderzhimogo posle konechnogo bloka.
- Proverenyi prezhniye scenarii svyaznosti; vyipolnenyi profilj i obosnovannoye resheniye ob optimizacii na vosproizvodimyikh vkhodakh.

## Istochniki

- [Proyavleniye FUM-SBOJ-0030/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0030-lishnyaya-pustaya-stroka-narushayet-razbor-trailer.md).
- [Doslovnyiye komandyi](../../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [Otchyot i diagnostika 101](../../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 15:24:29 MSK -->
<!-- content-sha256: sha256:ac7d8df21b6a3bfbdff7f01718d1ebd88a676cc0b5707a3bddee242768df777d -->
<!-- FUM-MD-RECENCY:END -->
