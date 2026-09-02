# Maksimaljno syiraya zapisj sobyitij kontaktnyikh poverkhnostej

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0012 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna s maksimaljno dostupnoj na podderzhivayemoj platforme tochnostjyu poluchatj otdeljnyiye kontaktyi trekpada, sensornogo ekrana i inoj mnogotochechnoj kontaktnoj poverkhnosti do ikh svedeniya k zhestam, ukazatelyu ili komandam interfejsa i peredavatj ikh v [versionirovannuyu pervichnuyu trassu sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md).

Sobyitiye sokhranyayet identichnostj ustrojstva i kontakta, fazu poyavleniya, izmeneniya, zaversheniya ili otmenyi, monotonnoye vremya, koordinatyi i vse predostavlennyiye istochnikom fizicheskiye izmereniya: davleniye, plosjhadj, formu, oriyentaciyu i inyiye polya. Obyyedinyonnyiye, predskazannyiye i ispravlennyiye sistemoj otschyotyi razlichayutsya ot fakticheski nablyudyonnyikh. Yesli publichnyij API predostavlyayet toljko zhest ili dvizheniye ukazatelya, adapter fiksiruyet poteryu otdeljnyikh kontaktov i ne vosstanavlivayet ikh sinteticheski.

## Semanticheskiye svyazi

- **yavlyayetsya chastjyu:** [maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — vyidelyayet samostoyateljno realizuyemyij i proveryayemyij mnogokontaktnyij kontur.
- **zavisit ot:** [versionirovannoj pervichnoj trassyi sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — sokhranyayet zhiznennyij cikl kontaktov i ogranicheniya istochnika v obsjhem formate.

## Kandidatyi realizacii

Sravneniyu podlezhat publichnyiye AppKit- i UIKit-istochniki otdeljnyikh kasanij, platformennyiye pointer i gesture API kak kontrolj uzhe vyipolnennoj interpretacii, a takzhe boleye nizkourovnevyiye publichno dopustimyiye HID-istochniki tam, gde oni dostupnyi. Vyibor delayetsya po fakticheskoj razlichimosti kontaktov, polyam, chastote, obyyedineniyu i platformennyim ogranicheniyam.

## Kriterii proverki

- odinochnyij kontakt sokhranyayet polnyij dostupnyij cikl `появился -> изменялся -> завершился` libo yavnuyu fazu otmenyi;
- dva i boleye odnovremennyikh kontakta sokhranyayut ustojchivuyu razdeljnuyu identichnostj do zaversheniya, v tom chisle pri sblizhenii i peresechenii trayektorij;
- koordinatyi, davleniye, plosjhadj, forma i oriyentaciya sokhranyayut predostavlennyiye yedinicyi i tochnostj libo soprovozhdayutsya yavnyim preobrazovaniyem;
- fakticheskiye, obyyedinyonnyiye, predskazannyiye i ispravlennyiye sistemoj otschyotyi razlichimyi v trasse i ne smeshivayutsya v odin neoboznachennyij potok;
- istochnik, dostupnyij toljko posle raspoznavaniya zhesta ili svedeniya k ukazatelyu, poluchayet yavnuyu otmetku neobratimoj poteri kontaktov;
- dlya kazhdogo kandidata izmeryayutsya chastota, vremennoye razresheniye, zaderzhka, poryadok, propuski, obyyedineniye i povedeniye pod mnogotochechnoj nagruzkoj;
- podklyucheniye, otklyucheniye, smena konfiguracii, ukhod prilozheniya iz aktivnogo sostoyaniya i sistemnaya otmena kontaktov ostavlyayut nablyudayemuyu granicu ili diagnostiruyemyij razryiv.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano, no otdeljnyij mnogokontaktnyij adapter, fizicheskiye scenarii i sravniteljnyij otchyot yesjhyo ne realizovanyi.

Kartochka ne opredelyayet raspoznavaniye zhestov, peremesjheniye ukazatelya, ekrannuyu geometriyu interfejsa ili perjyevoj vvod. Stilus, Apple Pencil i graficheskij planshet proveryayutsya otdeljnyim trebovaniyem, dazhe yesli platforma dostavlyayet ikh cherez obsjhij touch API.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [`NSEvent`](https://developer.apple.com/documentation/appkit/nsevent)
- [`IOHIDManager`](https://developer.apple.com/documentation/iokit/iohidmanager_h)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e5e8ecc3d135b75516be85fddacf306a0fa930d5e1b3b4afaeb7210809b803c2 -->
<!-- FUM-MD-RECENCY:END -->
