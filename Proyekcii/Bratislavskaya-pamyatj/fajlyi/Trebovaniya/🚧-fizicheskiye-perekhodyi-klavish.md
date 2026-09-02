# Fizicheskiye perekhodyi klavish

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0010 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna s maksimaljno dostupnoj na podderzhivayemoj platforme tochnostjyu poluchatj fizicheskiye izmeneniya sostoyaniya kazhdoj klavishi i peredavatj ikh v [versionirovannuyu pervichnuyu trassu sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md). Pervichnyimi yavlyayutsya identichnostj ustrojstva, fizicheskij identifikator klavishi, storona parnogo elementa i yavnaya faza `нажато` ili `отпущено`, a ne simvol, komanda, raskladka, obsjhij flag ili logicheskij rezhim.

Uderzhivayemyiye kvazirezhimnyiye klavishi-modifikatoryi Shift, Control, Option i Command, a takzhe rezhimnaya klavisha Caps Lock dayut takiye zhe razdeljnyiye fizicheskiye perekhodyi, kak ostaljnyiye klavishi. Levaya i pravaya klavishi sokhranyayutsya nezavisimo, vklyuchaya odnovremennoye nazhatiye. Avtopovtor ne yavlyayetsya novyim fizicheskim sostoyaniyem: istochnik s yavnyim priznakom povtora otbrasyivayetsya adapterom, a obsjhij reduktor otdeljno isklyuchayet povtor uzhe izvestnogo sostoyaniya.

Flagi modifikatorov, logicheskoye sostoyaniye Caps Lock, raskladochno razreshyonnyij simvol i inyiye vyisokourovnevyiye predstavleniya mogut sokhranyatjsya toljko kak diagnosticheskiye polya. Yesli publichnyij istochnik soobsjhayet lishj obsjhij flag ili pereklyucheniye rezhima, adapter fiksiruyet poteryu i ne sinteziruyet otsutstvuyusjhij fizicheskij perekhod. Sloj nablyudeniya pozvolyayet posleduyusjhemu interpretatoru naznachatj klavisham lyuboye povedeniye bez izmeneniya pervichnoj trassyi.

## Semanticheskiye svyazi

- **yavlyayetsya chastjyu:** [maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — vyidelyayet samostoyateljno realizuyemyij i proveryayemyij klaviaturnyij kontur.
- **zavisit ot:** [versionirovannoj pervichnoj trassyi sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — peredayot v obsjhij kontrakt toljko izmeneniya fizicheskogo sostoyaniya i otdeljnuyu diagnostiku poterj.

## Kandidatyi realizacii

| Kandidat                                      | Siljnaya storona                                                                                      | Ogranicheniye, kotoroye nuzhno izmeritj                                                                   |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `IOHIDManager`                                | HID usage, znacheniye elementa, monotonnoye vremya i razdeljnaya identichnostj klaviatur na macOS          | Prava, sandbox, vstroyennyiye ustrojstva i semantika HID-otchyotov trebuyut fizicheskikh proverok             |
| `GCKeyboard`                                  | Perenosimyij publichnyij sloj Apple s yavnyim bulevyim sostoyaniyem i levyimi/pravyimi HID-kodami              | Obyyedinyayet podklyuchyonnyiye klaviaturyi i ne sokhranyayet razdeljnuyu identichnostj ustrojstv                   |
| `CGEventTap`                                  | Sistemnyij potok `keyDown`/`keyUp`, vremennyiye metki i yavnyij priznak avtopovtora                       | Virtualjnyiye kodyi, obsjhaya identichnostj seansa i osobaya obrabotka `flagsChanged`                         |
| `NSEvent`                                     | Podderzhivayemyij prikladnoj potok macOS i yavnyij `isARepeat`                                            | Modifikatoryi predstavlenyi kak `flagsChanged`, a sobyitiya zavisyat ot prikladnogo i okonnogo konteksta   |
| `GCKeyboard` i platformennyiye UI Presses       | Kandidatyi na obsjhij kontroljnyij stend dlya iOS, iPadOS, tvOS i visionOS                                | Dostupnostj vneshnej klaviaturyi, storonyi, Caps Lock, fokus i fonovyiye ogranicheniya razlichayutsya po sredam |

Predvariteljnyij stek sochetayet `IOHIDManager` kak pervichnyij macOS-istochnik, `GCKeyboard` kak perenosimyij sloj Apple i sistemnyiye ili prikladnyiye sobyitiya kak diagnostiku. Vyibor ostayotsya uslovnyim do fizicheskikh progonov.

## Kriterii proverki

- dlya obyichnoj klavishi, kazhdoj dostupnoj klavishi-modifikatora i Caps Lock cikl `нажать -> удерживать -> отпустить` dayot rovno dva izmeneniya fizicheskogo sostoyaniya nezavisimo ot dliteljnosti uderzhaniya i nastrojki avtopovtora;
- levaya i pravaya Command, a takzhe drugiye dostupnyiye parnyiye modifikatoryi razlichayutsya pri razdeljnom i odnovremennom nazhatii;
- pomechennyij avtopovtor i povtor uzhe izvestnogo sostoyaniya isklyuchayutsya iz pervichnoj trassyi nezavisimyimi proverkami;
- odinakovaya fizicheskaya klavisha dvukh odnovremenno podklyuchyonnyikh klaviatur sokhranyayet razdeljnuyu identichnostj tam, gde istochnik yeyo predostavlyayet, a obyyedinyayusjhij istochnik poluchayet yavnuyu otmetku poteri;
- istochnik, soobsjhayusjhij toljko obsjhij flag ili rezhim Caps Lock, ne prokhodit kriterij fizicheskoj polnotyi i ne porozhdayet sinteticheskiye fazyi;
- kriterii uspekha ne ispoljzuyut simvol sistemnoj raskladki, flagi modifikatorov ili logicheskoye sostoyaniye Caps Lock kak ozhidayemyij pervichnyij rezuljtat;
- na macOS fizicheski sravnivayutsya `IOHIDManager`, `GCKeyboard`, `CGEventTap` i `NSEvent`, vklyuchaya podklyucheniye, otklyucheniye, son, probuzhdeniye, perepolneniye, poteryu razresheniya i nagruzku;
- tot zhe fizicheskij kontrakt proveryayetsya cherez dostupnyiye publichnyiye istochniki iOS, iPadOS, tvOS i visionOS.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: realizuyetsya. [Swift-prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md) soderzhit perenosimoye yadro perekhodov, dvukhslojnoye isklyucheniye avtopovtora, chetyire macOS-adaptera, versionirovannoye kodirovaniye i avtonomnyiye testyi. Graficheskij provodnik uzhe zadayot polnuyu macOS-matricu scenariyev, trebuyet otdeljnogo soglasiya, razdelyayet popyitki i istochniki i sokhranyayet lokaljnyij nabor dannyikh; fakticheskaya fizicheskaya seriya yesjhyo ne vyipolnyalasj.

Do statusa `✅` ostayutsya yavno razreshyonnyiye fizicheskiye progonyi odnoj i neskoljkikh klaviatur cherez vse kandidatyi, proverka zhiznennogo cikla i nagruzki, a takzhe perenosimyiye prilozheniya-stendyi Apple. Konkretnyiye naznacheniya klavish, sistemnyiye raskladki, sintez vvoda i zhestyi nakhodyatsya vne kartochki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-21 13:49:43 MSK](../Zhurnal/2026-07-21_13-49-43_MSK_dorabotatj-prototip-sbora-klaviaturnyikh-sobyitij/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:41:27 MSK](../Zhurnal/2026-07-17_09-41-27_MSK_utochnitj-razlicheniye-nazhatiya-i-otpuskaniya-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:07:09 MSK](../Zhurnal/2026-07-17_10-07-09_MSK_razlichatj-fazyi-modifikatorov-i-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:40:21 MSK](../Zhurnal/2026-07-17_10-40-21_MSK_sozdatj-prototip-fizicheskikh-sostoyanij-klavish/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [Game Controller](https://developer.apple.com/documentation/gamecontroller)
- [`GCKeyboard`](https://developer.apple.com/documentation/gamecontroller/gckeyboard)
- [`NSEvent`](https://developer.apple.com/documentation/appkit/nsevent)
- [`CGEvent`](https://developer.apple.com/documentation/coregraphics/cgevent)
- [`IOHIDManager`](https://developer.apple.com/documentation/iokit/iohidmanager_h)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a22ad13e9d523fbd4efc5b2b97e1d7fbfe485e3f999d7aa45121734b9d293150 -->
<!-- FUM-MD-RECENCY:END -->
