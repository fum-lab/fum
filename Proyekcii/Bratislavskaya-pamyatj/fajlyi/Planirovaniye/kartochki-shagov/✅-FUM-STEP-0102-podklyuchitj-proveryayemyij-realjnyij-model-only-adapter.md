+++
schema_version = 1
card_id = "FUM-STEP-0102"
status = "completed"
+++
# Podklyuchitj proveryayemyij realjnyij model-only-adapter

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Podklyuchitj k kontraktu chistogo modeljnogo shaga realjnyij modeljnyij provajder v rezhime odnogo otveta bez instrumentov i sobstvennogo agentskogo cikla. Adapter dolzhen yavno fiksirovatj identichnostj runtime i modeli, parametryi, limityi, tajm-aut, otmenu i versionnyiye konvertyi rezuljtata.

## Rezuljtat

Swift-prototip poluchil profilj `fum.lm-studio-cli.one-shot.v1`: odin pryamoj process-vyizov LM Studio bez shell, instrumentov, fajlov, seti modeli, povtorov i ispolneniya otveta. Versionnyij konvert popyitki svyazyivayet tochnyij zapros s pasportom provajdera i tipizirovannyim `completed` libo bezopasnyim `rejected`.

Pasport fiksiruyet tochnyij klyuch modeli, nablyudayemyiye versii CLI i prilozheniya, dejstvuyusjhiye bajtovyij limit i tajm-aut, argv-sredu i yavnyiye zapretyi effektov. Neraskryityiye tekusjhim CLI sampling, seed, predel tokenov i khyesh vesov zapisyivayutsya kak `unknown`. Process-runner razlichayet timeout, caller cancellation, lishnij bajt, otkaz, oshibku, nedostupnostj, nesovpadeniye i narusheniye protokola bez syirogo stderr, sekretov ili lokaljnyikh putej.

Avtonomnyiye zapisannyiye testyi prokhodyat bez seti, modeli i sekretov. Otdeljnyij opt-in-test vyipolnil odin zhivoj otvet uzhe sokhranyonnoj lokaljnoj modeli s otklyuchyonnyim obrasjheniyem k katalogu i korotkim TTL. Otsutstvuyusjhaya konfiguraciya vozvrasjhayet `provider_unconfigured` i nikogda ne podstavlyayet echo-zaglushku.

## Istochniki

- [kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md)
- [FUM-STEP-0101 — yazyikonejtraljnyij protokol pamyati](✅-FUM-STEP-0101-zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- [iskhodnyij zapros o razreshenii modeljnogo provajdera](../../Zhurnal/2026-07-29_20-17-47_MSK_razreshitj-modeljnyij-provajder-dlya-FUM-STEP-0102/zapros.md)
- [iskhodnyij zapros o vyipolnenii FUM-STEP-0102](../../Zhurnal/2026-07-29_23-53-42_MSK_podklyuchitj-proveryayemyij-realjnyij-model-only-adapter/zapros.md)
- [zhurnal vyipolneniya FUM-STEP-0102](../../Zhurnal/2026-07-29_23-53-42_MSK_podklyuchitj-proveryayemyij-realjnyij-model-only-adapter/otchyot.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6af6256acd41fb477a8250ddabeb6a6cd5bb0e8a7558c28456b06e30fde0cd07 -->
<!-- FUM-MD-RECENCY:END -->
