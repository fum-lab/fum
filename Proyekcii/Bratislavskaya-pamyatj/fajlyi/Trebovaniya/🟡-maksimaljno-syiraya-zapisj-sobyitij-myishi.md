# Maksimaljno syiraya zapisj sobyitij myishi

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0011 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna s maksimaljno dostupnoj na podderzhivayemoj platforme tochnostjyu poluchatj sobyitiya kazhdoj myishi do ikh svedeniya k peremesjheniyu ukazatelya, zhestam ili komandam interfejsa i peredavatj ikh v [versionirovannuyu pervichnuyu trassu sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md).

Dlya kazhdogo nablyudeniya sokhranyayutsya identichnostj ustrojstva, fizicheskij element upravleniya, faza knopki, otnositeljnoye peremesjheniye po dostupnyim osyam, prokrutka i inyiye nizkourovnevyiye polya istochnika. Yesli API predostavlyayet toljko absolyutnuyu poziciyu ukazatelya, uzhe uskorennoye smesjheniye, obyyedinyonnyiye otschyotyi ili obsjhuyu virtualjnuyu myishj, eto proiskhozhdeniye i poterya syirosti otmechayutsya yavno i ne vyidayutsya za fizicheskij otchyot ustrojstva.

## Semanticheskiye svyazi

- **yavlyayetsya chastjyu:** [maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — vyidelyayet samostoyateljno realizuyemyij i proveryayemyij kontur knopok, peremesjheniya i prokrutki myishi.
- **zavisit ot:** [versionirovannoj pervichnoj trassyi sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — sokhranyayet izmereniya myishi i ogranicheniya istochnika v obsjhem formate.

## Kandidatyi realizacii

Sravneniyu podlezhat `GCMouse` kak perenosimyij sloj Apple, `IOHIDManager` kak boleye blizkij k ustrojstvu istochnik macOS, a takzhe `CGEventTap`, `NSEvent` i publichnyiye platformennyiye pointer API kak sistemnyiye i prikladnyiye kontroljnyiye istochniki. Dopustim gibrid, yesli ni odin publichnyij API ne sokhranyayet odnovremenno identichnostj ustrojstva, knopki i trebuyemuyu tochnostj dvizheniya.

## Kriterii proverki

- nazhatiye i otpuskaniye kazhdoj dostupnoj knopki sokhranyayutsya razdeljno i ne vyivodyatsya iz komandyi interfejsa;
- dvizheniye po kazhdoj fizicheski dostupnoj osi i prokrutka vosproizvodyatsya s iskhodnyimi vremennyimi metkami, znakom, razresheniyem i yedinicami libo s yavnoj otmetkoj preobrazovaniya;
- dve odnovremenno podklyuchyonnyiye myishi razlichayutsya tam, gde eto dopuskayet istochnik, a obyyedineniye v virtualjnoye ustrojstvo fiksiruyetsya kak poterya;
- dlya kazhdogo kandidata izmeryayutsya chastota, vremennoye razresheniye, zaderzhka, poryadok, obyyedineniye, propuski, vliyaniye uskoreniya i povedeniye pod nagruzkoj;
- absolyutnaya poziciya ukazatelya i otnositeljnoye dvizheniye ustrojstva ne podmenyayut drug druga bez yavnogo preobrazovaniya i proiskhozhdeniya;
- podklyucheniye, otklyucheniye, son, probuzhdeniye, izmeneniye konfiguracii, perepolneniye i poterya razresheniya ostavlyayut nablyudayemuyu granicu ili diagnostiruyemyij razryiv;
- odinakovyiye fizicheskiye scenarii sravnivayutsya na macOS i ostaljnyikh podderzhivayemyikh platformakh Apple, gde publichnyij API i sootvetstvuyusjhaya myishj dostupnyi.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano, no samostoyateljnyij adapter myishi i fizicheskij sravniteljnyij stend yesjhyo ne realizovanyi. Klaviaturnyij prototip dayot obsjhij format issledovaniya, no ne podtverzhdayet knopki, dvizheniye, prokrutku ili neskoljko myishej.

Kartochka ne opredelyayet vneshnij vid ukazatelya, uskoreniye kak poljzovateljskuyu nastrojku, raspoznavaniye zhestov i naznacheniye knopok.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [Game Controller](https://developer.apple.com/documentation/gamecontroller)
- [`NSEvent`](https://developer.apple.com/documentation/appkit/nsevent)
- [`CGEvent`](https://developer.apple.com/documentation/coregraphics/cgevent)
- [`IOHIDManager`](https://developer.apple.com/documentation/iokit/iohidmanager_h)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:45c18172dd3ff5aab9cd695aacc9989225de420aa552d80d9a12df6da64821eb -->
<!-- FUM-MD-RECENCY:END -->
