# Otchyot 2026-07-21 13:49:43 MSK - Dorabotatj prototip sbora klaviaturnyikh sobyitij

Klaviaturnyij prototip poluchil nativnyij graficheskij provodnik fizicheskoj priyomki. On obyyasnyayet cheloveku naznacheniye i granicyi testa, sobirayet yavnoye soglasiye, provodit cherez polnuyu matricu scenariyev i sokhranyayet lokaljnyij analiziruyemyij nabor dannyikh neposredstvenno v rabochej kopii FUM.

## Upravlyayemaya fizicheskaya priyomka

SwiftUI-interfejs otdelyayet podgotovku, aktivnuyu zapisj i zavershyonnyij rezuljtat. Do soglasiya istochniki ne zapuskayutsya. Vo vremya popyitki krasnyij indikator pokazyivayet oblastj zapisi, kartochka zadayot toljko razreshyonnyiye klavishi i ozhidayemoye svideteljstvo, a perekhod mezhdu shagami vyipolnyayetsya myishjyu. Neozhidannaya klavisha vidna schyotchikom i delayet popyitku nedejstviteljnoj, no yeyo kod ne popadayet v fajl.

Plan versii `1` okhvatyivayet obyichnyiye ciklyi i perekryitiye klavish, dolgoye uderzhaniye i avtopovtor, storonyi modifikatorov, odnovremennyiye Command, kombinaciyu Shift + A, dva cikla Caps Lock, dve raskladki, Fn i verkhnij ryad, media-klavishu, granicu fokusa, vtoruyu klaviaturu, perepodklyucheniye, son i probuzhdeniye, otzyiv razresheniya i plotnyij potok. Apparatno nedostupnyij ili nenablyudayemyij scenarij ostayotsya v manifeste kak `unsupported`.

## Nablyudeniye i diagnostika

Kazhdyij odnovremenno rabotayusjhij istochnik ispoljzuyet sobstvennyij reduktor, poetomu obyyedinyonnyiye prostranstva `CGEventTap`, `NSEvent` i `GCKeyboard` ne zagryaznyayut sostoyaniya drug druga. `NSEvent` sochetayet lokaljnyij i globaljnyij monitoryi, `IOHIDManager` prinimayet vyibrannyiye Consumer usages Volume Increment i Play/Pause, a `CGEventTap` soobsjhayet imenovannyiye flagi, avtopovtor i diagnosticheskiye otklyucheniya po tajm-autu ili poljzovateljskomu vvodu. Posledovateljnyij shlyuz zakreplyayet pokoleniye kartochki pri callback i dozhidayetsya uzhe prinyatyikh sobyitij pered zaversheniyem scenariya. Pervichnyiye perekhodyi ostayutsya otdelenyi ot diagnosticheski otklonyonnyikh syiryikh nablyudenij.

## Lokaljnyij nabor dannyikh

Putj rabochej kopii vyivoditsya iz `#filePath` i prinimayetsya toljko pri podtverzhdyonnyikh markerakh repozitoriya. Vnutri prototipa sozdayotsya tochno ignoriruyemyij Git katalog `Локальные-данные-прогонов`: zavershyonnyij seans soderzhit `manifest.json` so snimkom plana i iskhodami popyitok i `events.jsonl` s razreshyonnyimi nablyudeniyami i resheniyami reduktorov. Absolyutnyij putj, simvolyi, vvedyonnyij tekst, raskladka, prilozheniye perednego plana, imya poljzovatelya, imya mashinyi i serijnyiye nomera ne serializuyutsya.

Snachala dannyiye nakhodyatsya v `.incomplete-*`; shtatnaya otmena ili zakryitiye yedinstvennogo okna ostanavlivayet istochniki i udalyayet etot katalog. Posle sinkhronizacii katalog atomarno pereimenovyivayetsya bez perezapisi susjhestvuyusjhego rezuljtata. Simvoljnaya ssyilka na katalog progonov otklonyayetsya dvumya nezavisimyimi proverkami. Katalog poluchayet prava `0700`, fajlyi — `0600`. Zavershyonnyij rezuljtat mozhno pokazatj v Finder ili udalitj cherez podtverzhdeniye GUI. Avtomaticheskogo eksporta net.

## Proverki i granicyi

Krasno-zelyonyij cikl i posleduyusjheye nezavisimoye revjyu dobavili kontraktyi plana, filjtracii, otdeljnyikh reduktorov, uporyadochennoj granicyi callback, tochnogo poryadka i minimaljnoj dliteljnosti scenariyev, obyazateljnoj klassifikacii vsekh kartochek, diagnosticheskogo avtopovtora, top-level Consumer Control, otkaza ot sokhraneniya neozhidannoj klavishi, atomarnogo zaversheniya, prav fajlov i fail-closed-poiska repozitoriya bez simvoljnyikh ssyilok. Paket prokhodit `38` avtonomnyikh testov, otdeljnuyu sborku `FUMInputGuide` i strogij `swift format lint`; fakticheskiye statusyi vyibrannyikh istochnikov ostayutsya vidnyi na kazhdoj kartochke.

Fakticheskiye sobyitiya poljzovatelya v etoj sessii ne zapisyivalisj. Fizicheskij progon trebuyet otdeljnogo soglasiya cheloveka. Tochnyiye vremena i posledovateljnosti kodov ostayutsya chuvstviteljnyimi; proizvodstvennyij srok khraneniya, razreshyonnyij eksport, avtomaticheskoye zaversheniye pri otzyive razresheniya i ustojchivaya podpisannaya TCC-identichnostj yesjhyo ne realizovanyi.

## Prodolzheniye

Aktualjnyim prodolzheniyem ostayotsya fizicheskaya seriya na realjnyikh klaviaturakh cherez gotovyij provodnik, vklyuchaya uslovnyiye scenarii vtoroj klaviaturyi i zhiznennogo cikla. Posle neyo nuzhnyi perenosimyiye prilozheniya-stendyi Apple i otdeljnoye resheniye o proizvodstvennom zasjhisjhyonnom khranilisjhe.

## Zatronutyiye materialyi

- [pasport prototipa](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [fizicheskiye perekhodyi klavish](../../Trebovaniya/🚧-fizicheskiye-perekhodyi-klavish.md)
- [versionirovannaya pervichnaya trassa](../../Trebovaniya/🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md)
- [zasjhisjhyonnyij sbor chuvstviteljnogo vvoda](../../Trebovaniya/🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Istochniki

- [iskhodnyij zapros 2026-07-21 13:49:43 MSK](zapros.md)
- [iskhodnyij zapros o sozdanii prototipa](../2026-07-17_10-40-21_MSK_sozdatj-prototip-fizicheskikh-sostoyanij-klavish/zapros.md)
- [iskhodnyij zapros o dekompozicii sobyitij vvoda](../2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [prototip fizicheskikh sostoyanij klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:69f9f472b1899be7ce420a82c3f91660c499fc94435d3f3b8bb807dc127f6ee9 -->
<!-- FUM-MD-RECENCY:END -->
