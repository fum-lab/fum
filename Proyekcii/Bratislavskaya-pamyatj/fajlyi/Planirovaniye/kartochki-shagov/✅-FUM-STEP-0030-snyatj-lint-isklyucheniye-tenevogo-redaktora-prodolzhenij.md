+++
schema_version = 1
card_id = "FUM-STEP-0030"
status = "completed"
+++
# Snyatj lint-isklyucheniye tenevogo redaktora prodolzhenij

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Snyatj khyesh-privyazannoye lint-isklyucheniye tenevogo redaktora prodolzhenij otdeljnyim mekhanicheskim formatirovaniyem vsego Swift-paketa bez funkcionaljnyikh izmenenij.

## Rezuljtat

Centraljnyij `swift-format` mekhanicheski normalizoval `Package.swift` i vse Swift-fajlyi celej i testov tenevogo redaktora prodolzhenij. Iskhodnyij strogij lint vosproizvyol `2225` strok diagnostik, a posle formatirovaniya zavershilsya bez diagnostik; konkretnoye khyesh-privyazannoye isklyucheniye udaleno iz obsjhej politiki SwiftPM-paketov, a obsjhij proveryayemyij mekhanizm vremennyikh isklyuchenij sokhranyon.

Granica izmeneniya ogranichena rezuljtatom formattera: otstupami, perenosami, zapyatyimi mnogostrochnyikh kollekcij, poryadkom importov i ekvivalentnoj fajlovoj vidimostjyu. Algoritmyi, publichnyiye kontraktyi, sostav produktov, zavisimosti i testovyiye ozhidaniya ne menyalisj. Vse `30` avtonomnyikh testov proshli, `FUMShadowEditor` i `FUMShadowProbe` sobranyi otdeljnyimi komandami, a polnyij smoke-check zavershil `36/36` shagov.

## Istochniki

- [iskhodnyij zapros o vyipolnenii shaga](../../Zhurnal/2026-07-22_09-33-05_MSK_snyatj-lint-isklyucheniye-tenevogo-redaktora-prodolzhenij/zapros.md), [zhurnal](../../Zhurnal/2026-07-22_09-33-05_MSK_snyatj-lint-isklyucheniye-tenevogo-redaktora-prodolzhenij/otchyot.md)
- [iskhodnyij zapros 2026-07-20 15:34:46 MSK](../../Zhurnal/2026-07-20_15-34-46_MSK_vklyuchitj-SwiftPM-v-obsjhij-smoke-check/zapros.md), [politika SwiftPM-paketov](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json), [tenevoj redaktor prodolzhenij](../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md), [revjyu proyekta](../../Zhurnal/2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:7b68045c12b959b26e10f21d49a4ca28493a15d5d99d882cb04bf8ca1ef48c5e -->
<!-- FUM-MD-RECENCY:END -->
