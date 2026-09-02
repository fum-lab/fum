# Otchyot 2026-07-17 10:40:21 MSK - Sozdatj prototip fizicheskikh sostoyanij klavish

Rabochaya sessiya perevela trebovaniye o maksimaljno syiroj zapisi sobyitij vvoda iz vyibora po dokumentacii API v dejstvuyusjhij sravniteljnyij Swift-prototip. Dlya klaviaturyi zakreplyon boleye strogij pervichnyij kontrakt: sokhranyayetsya toljko yavnoye izmeneniye fizicheskogo sostoyaniya konkretnoj klavishi konkretnogo ustrojstva; avtopovtor, simvolyi, raskladka, flagi modifikatorov i logicheskoye sostoyaniye Caps Lock ne podmenyayut etot potok.

Sozdan paket `физические-состояния-клавиш` s perenosimyim yadrom, adapterami `IOHIDManager`, `GCKeyboard`, `CGEventTap` i `NSEvent`, headless-probnikom, versionirovannoj JSONL-zapisjyu i avtomaticheskoj matricej kandidatov. Reduktor otbrasyivayet avtopovtor snachala po yavnomu priznaku istochnika, a zatem nezavisimo isklyuchayet povtor uzhe izvestnogo sostoyaniya. Levaya i pravaya Command, odinakovyiye klavishi raznyikh ustrojstv i sostoyaniya `pressed`/`released` sokhranyayutsya razdeljno.

Predvariteljno vyibran gibridnyij stek. `IOHIDManager` yavlyayetsya pervichnyim macOS-istochnikom blagodarya HID usage, znacheniyu elementa, monotonnomu vremeni i razdeljnoj identichnosti ustrojstv. `GCKeyboard` vyibran perenosimyim sloyem Apple, no yego obyyedinyonnaya modelj ustrojstva fiksiruyetsya kak poterya. `CGEventTap` i `NSEvent` ostavlenyi diagnosticheskimi istochnikami: oni poleznyi dlya sravneniya sistemnogo i prikladnogo potokov i yavno oboznachayut avtopovtor, no ne sokhranyayut identichnostj fizicheskoj klaviaturyi.

Kartochka trebovaniya perevedena iz `🟡` v `🚧`. Zaversheniye trebovaniya ne obyyavleno: realjnyiye nazhatiya bez otdeljnogo soglasiya ne zapisyivalisj, a myishj, trekpad, stilus, planshet i prilozheniya-stendyi ostaljnyikh platform Apple yesjhyo ne realizovanyi.

## Resheniye po avtomatizacii

Povtoryayemaya chastj oformlena vnutri prototipa: `FUMInputProbe matrix` vosproizvodimo stroit sravniteljnyij otchyot i rekomendaciyu, `environment` proveryayet dostupnostj sredyi, `devices` inventariziruyet HID-klaviaturyi bez serijnyikh nomerov, a `record` zapuskayet zapisj toljko po otdeljnoj yavnoj komande i pishet JSONL v stdout. Novaya avtomatizaciya v `Инструменты/` poka ne sozdavalasj: do fizicheskikh progonov ustojchivyim nositelem proverki ostayotsya sam Swift-paket.

## Proverki

- Pervyij TDD-cikl upal na otsutstvuyusjhem yadre fizicheskikh sostoyanij; posle realizacii proshli proverki perekhodov, avtopovtora, storon klavish, ustrojstv i vyibora steka.
- Vtoroj TDD-cikl upal na otsutstvuyusjhikh fabrikakh platformennyikh nablyudenij; posle realizacii proshli proverki HID-znachenij, klaviaturnoj usage page, `CGEvent` i `flagsChanged`.
- Itogovyij `swift test` proshyol 16 testov v tryokh naborakh bez oshibok.
- `swift build --product FUMInputProbe` zavershilsya uspeshno.
- `swift format lint --recursive` zavershilsya bez preduprezhdenij posle formatirovaniya paketa.
- `FUMInputProbe matrix` vyibral `iohid-manager` dlya macOS i `gc-keyboard` dlya perenosimogo sloya.
- `FUMInputProbe environment` podtverdil odnu HID-klaviaturu, dostup passivnogo `CGEventTap` i otsutstviye `GCKeyboard.coalesced` v tekusjhem headless-processe.
- `FUMInputProbe devices` obnaruzhil odnu klaviaturu i 271 klaviaturnyij HID-element bez publikacii serijnogo nomera ili lokaljnogo puti.
- Komanda `record` ne zapuskalasj, poetomu fakticheskiye poljzovateljskiye nazhatiya v priyomke ne zakhvatyivalisj i ne sokhranyalisj.

## Prodolzheniye

Sleduyusjhij yavno vklyuchyonnyij progon dolzhen sravnitj chetyire macOS-istochnika na odnoj i neskoljkikh realjnyikh klaviaturakh, vklyuchaya Caps Lock, vse modifikatoryi, otdeljnyiye i odnovremennyiye levuyu i pravuyu Command, korotkoye i dliteljnoye uderzhaniye, sistemnyiye nastrojki avtopovtora, podklyucheniye, son, perepolneniye i razresheniya. Posle etogo nuzhnyi prilozheniya-stendyi s `GCKeyboard` i UI Presses dlya iOS, iPadOS, tvOS i visionOS, a zatem adapteryi myishi, trekpada, stilusa i plansheta.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [kartochka trebovaniya](../../Trebovaniya/🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md)
- [prototip fizicheskikh sostoyanij klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [indeks prototipov](../../Prototipyi/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Istochniki

- [iskhodnyij zapros 2026-07-17 10:40:21 MSK](zapros.md)
- [iskhodnyij zapros 2026-07-17 10:07:09 MSK](../2026-07-17_10-07-09_MSK_razlichatj-fazyi-modifikatorov-i-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:41:27 MSK](../2026-07-17_09-41-27_MSK_utochnitj-razlicheniye-nazhatiya-i-otpuskaniya-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:266ebbb1bebe81091cd1bd7c8f0947748719fe14585695986f2946dac601d6f6 -->
<!-- FUM-MD-RECENCY:END -->
