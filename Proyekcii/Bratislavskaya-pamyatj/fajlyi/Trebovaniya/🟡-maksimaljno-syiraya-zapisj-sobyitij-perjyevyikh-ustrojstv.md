# Maksimaljno syiraya zapisj sobyitij perjyevyikh ustrojstv

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0013 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna s maksimaljno dostupnoj na podderzhivayemoj platforme tochnostjyu poluchatj sobyitiya stilusa, pera graficheskogo plansheta i svyazannyikh fizicheskikh elementov upravleniya do postroyeniya shtrikha, raspoznavaniya rukopisnogo vvoda ili komandyi interfejsa i peredavatj ikh v [versionirovannuyu pervichnuyu trassu sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md).

Dlya kazhdogo nablyudeniya sokhranyayutsya identichnostj ustrojstva i instrumenta, dostupnyiye fazyi blizosti, kasaniya, dvizheniya, zaversheniya i otmenyi, tip nakonechnika ili lastika, sostoyaniya fizicheskikh knopok, koordinatyi, davleniye, naklon, azimut, vrasjheniye, tangencialjnoye davleniye i inyiye polya istochnika. Obyyedinyonnyiye i predskazannyiye otschyotyi oboznachayutsya otdeljno. Yesli platforma predostavlyayet lishj gotovyij shtrikh ili raspoznannoye dejstviye, poterya pervichnyikh izmerenij fiksiruyetsya yavno.

## Semanticheskiye svyazi

- **yavlyayetsya chastjyu:** [maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — vyidelyayet samostoyateljno realizuyemyij i proveryayemyij kontur stilusa i graficheskogo plansheta.
- **zavisit ot:** [versionirovannoj pervichnoj trassyi sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — sokhranyayet fazyi i fizicheskiye izmereniya pera v obsjhem formate.

## Kandidatyi realizacii

Sravneniyu podlezhat publichnyiye sobyitiya plansheta AppKit, UIKit-istochniki stilusa i Apple Pencil, a takzhe publichno dopustimyiye HID-istochniki tam, gde oni predostavlyayut boleye ranniye izmereniya. Obsjhij touch API mozhet byitj transportom, no ne osnovaniyem smeshivatj pero s paljcevyim kontaktom v odnom trebovanii.

## Kriterii proverki

- dostupnyiye fazyi priblizheniya, kasaniya, dvizheniya, zaversheniya i otmenyi sokhranyayutsya razdeljno i v iskhodnom poryadke;
- nakonechnik, lastik i fizicheskiye knopki razlichayutsya bez vyivoda iz naznachennoj im komandyi;
- koordinatyi, davleniye, naklon, azimut, vrasjheniye i tangencialjnoye davleniye sokhranyayutsya s predostavlennyimi diapazonami i yedinicami libo s yavnyim preobrazovaniyem;
- fakticheskiye, obyyedinyonnyiye i predskazannyiye otschyotyi razlichimyi i ne podmenyayut drug druga;
- dva dostupnyikh pera ili instrumenta razlichayutsya tam, gde istochnik predostavlyayet identichnostj, a obyyedineniye otmechayetsya kak poterya;
- dlya kazhdogo kandidata izmeryayutsya chastota, vremennoye razresheniye, zaderzhka, poryadok, propuski i povedeniye pri byistryikh shtrikhakh, izmenenii davleniya i naklona;
- gotovyij shtrikh, raspoznannyij tekst ili zhest ne prinimayutsya za pervichnoye nablyudeniye bez yavnoj otmetki neobratimoj poteri;
- podklyucheniye, otklyucheniye, smena instrumenta, ukhod iz oblasti chuvstviteljnosti i poterya fokusa ostavlyayut nablyudayemuyu granicu ili diagnostiruyemyij razryiv.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano, no adapteryi, fizicheskiye ustrojstva i sravniteljnyij stend yesjhyo ne realizovanyi.

Kartochka ne opredelyayet kistj, sglazhivaniye shtrikha, raspoznavaniye rukopisnogo vvoda, zhestyi ili naznacheniye knopok. Paljcevyiye kontaktyi trekpada i sensornogo ekrana proveryayutsya otdeljno.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [`NSEvent`](https://developer.apple.com/documentation/appkit/nsevent)
- [`IOHIDManager`](https://developer.apple.com/documentation/iokit/iohidmanager_h)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f0886baf5b1617f0426f1ef232612ad10674beb8c48045a417f4009c6c63cc14 -->
<!-- FUM-MD-RECENCY:END -->
