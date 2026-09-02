# Otchyot 2026-07-20 14:24:31 MSK - Normalizovatj monotonnoye vremya istochnikov vvoda

Pervoye zamechaniye `P1` poslednego revjyu ustraneno: vse chetyire klaviaturnyikh istochnika teperj yavno svodyat svoi vremennyiye domenyi k nanosekundam s momenta zapuska sistemyi. IOHID boljshe ne zapisyivayet apparatno-zavisimyiye tiki AbsoluteTime kak gotovyiye nanosekundyi, poetomu budusjhaya fizicheskaya seriya smozhet korrektno sravnivatj dliteljnosti i sobyitiya raznyikh istochnikov.

## Resheniya

- V `FUMInputMac` vvedyon yedinyij normalizator vremennyikh metok s sistemnyim koefficiyentom `mach_timebase_info`.
- Preobrazovaniye IOHID ispoljzuyet polnuyu shirinu promezhutochnogo proizvedeniya i vozvrasjhayet otsutstviye znacheniya vmesto perepolneniya itogovogo `UInt64`.
- `CGEvent` i `GCKeyboard` prokhodyat cherez yavnyij nanosekundnyij vkhod normalizatora, a sekundyi `NSEvent` proveryayutsya i perevodyatsya v tu zhe yedinicu.
- Skhema JSONL ne menyalasj: pole uzhe nazyivalosj `monotonicNanoseconds`, a soderzhateljnyiye klaviaturnyiye trassyi do ispravleniya v pamyatj FUM ne zapisyivalisj.
- Sleduyusjhim po ocheredi zamechaniyem `P1` stanovitsya vklyucheniye SwiftPM-paketov v obsjhij smoke-check.

## Proverki

Swift-paket sobran vmeste s `FUMInputProbe`; vse 21 test proshli. Pyatj novyikh testov podtverzhdayut koefficiyent `125/3`, pravilo okrugleniya vniz, otsutstviye promezhutochnogo perepolneniya, bezopasnyij otkaz pri nepredstavimom rezuljtate, svedeniye chetyiryokh domenov k odnoj metke i otkloneniye nedopustimyikh sekund. `swift format lint` i obsjhij predkommitnyij kontur repozitoriya takzhe proshli.

## Prodolzheniye

Sleduyusjhij shag po ocheredi revjyu — nauchitj `fum-smoke-check` avtomaticheski nakhoditj oba SwiftPM-paketa, sobiratj ispolnyayemyiye produktyi, zapuskatj testyi i primenyatj yavnyij lint-kontrakt. Fizicheskaya seriya klaviaturnyikh izmerenij ostayotsya otdeljnyim yavno vklyuchayemyim etapom posle ustraneniya blokiruyusjhikh defektov proverki; toljko ona podtverdit fakticheskiye smesjheniya i povedeniye chasov raznyikh API vo vremya sna i probuzhdeniya.

## Zatronutyiye materialyi

- [prototip fizicheskikh sostoyanij klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [versionirovannaya pervichnaya trassa](../../Trebovaniya/🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Istochniki

- [iskhodnyij zapros 2026-07-20 14:24:31 MSK](zapros.md)
- [revjyu proyekta 2026-07-18 07:44:15 MSK](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:968a7e6e1a2b2b7a4efd3a663e124f7d51d8c32f7f7c3e3ffe11d75616793643 -->
<!-- FUM-MD-RECENCY:END -->
