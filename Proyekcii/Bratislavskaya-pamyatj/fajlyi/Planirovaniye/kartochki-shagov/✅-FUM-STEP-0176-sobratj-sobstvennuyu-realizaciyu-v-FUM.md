+++
schema_version = 1
card_id = "FUM-STEP-0176"
status = "completed"
+++
# Sobratj sobstvennuyu realizaciyu v FUM

## Zadacha

Sobratj sobstvennyiye iskhodniki FUM, ikh testyi, publichnyiye fiksturyi, scenarii profilirovaniya i instrukcii zapuska v yedinom repozitorii FUM. Zaregistrirovannyiye sabmoduljnyiye zavisimosti sokhranyayut samostoyateljnyiye repozitorii. Pervaya postavka — svyazannaya semjya Swift-paketov nablyudenij i arkhivnogo importa; pered perenosom sostavlyayetsya inventarj ostaljnyikh sobstvennyikh komponentov vne FUM.

## Pochemu sejchas

Zhurnal arkhivnoj priyomki khranit rezuljtatyi ispolneniya i manifest iskhodnikov, no pryamo ogranichivayet postavku: Swift-iskhodniki v primary ne perenesenyi. Ikh net i v sokhranyonnom kandidate sliyaniya `436909208424595f7151f6febca75f89018c0bcb`. Poetomu uspeshnoye sliyaniye vetok yesjhyo ne pozvolyayet vneshnemu uchastniku povtoritj etu rabotu iz odnogo klona. Poljzovatelj yavno poruchil ustranitj razryiv sleduyusjhim shagom.

Nachalo perenosa sleduyet za tekusjhim etapom dopuska sliyaniya. Inventarizaciya i sokhraneniye istochnikov dopuskayutsya zaraneye chteniyem. Kartochka fiksiruyet otdeljnyij rezuljtat, ne obyyavlyayet kontejner zavershyonnyim i ne podmenyayet ostaljnyiye obyazateljstva FUMA.

## Kriterii zaversheniya

- Sostavlen perechenj sobstvennyikh lokaljnyikh repozitoriyev i rabochikh vetok, iz kotoryikh trebuyetsya dostavka. Dlya kazhdogo zafiksirovanyi polnyij iskhodnyij commit, derevo, nezakommichennyij ostatok, licenziya i naznacheniye komponentov; lokaljnyiye sluzhebnyiye puti ne stanovyatsya obyazateljnyimi parametrami publichnoj sborki.
- Svyazannyiye paketyi kontejnera, snimka zadachi, arkhivnogo importa i statistiki perenesenyi s istochnikami, testami, otkryityimi fiksturami i scenariyami izmerenij v kanonicheskij katalog FUM. Nezavisimyiye izmeneniya vetvej svedenyi po soderzhaniyu; susjhestvuyusjhaya realizaciya pereispoljzovana. Iskhodnyiye repozitorii i ikh istoriya sokhranenyi do proverki polnogo perenosa; proiskhozhdeniye importirovannyikh fajlov proveryayemo po commits i khyesham.
- Zaregistrirovannyiye vneshniye sabmoduli sokhranyayut gitlink, URL i tochnuyu reviziyu. Sobstvennaya realizaciya ne skryita dopolniteljnyim lokaljnyim sabmodulem; vremennyiye sborki, keshi, personaljnyiye trassyi i sekretyi v postavku ne vkhodyat.
- V chistom klone FUM bez staryikh lokaljnyikh katalogov vosproizvodyatsya sborka, primenimyiye testyi i profilirovaniye perenesyonnyikh paketov. Zafiksirovanyi versiya Swift, rezhim Concurrency, platforma, komandyi, tochnyiye revizii zavisimostej i granicyi izmerenij. Izmeneniya ispolnyayemogo koda prokhodyat adresnyiye RED/GREEN i obyazateljnyij analiz optimizacii; chistyij perenos otdeljno proveryayetsya na ravenstvo iskhodnikov.
- README i svyazannyiye rukovodstva dayut cheloveku putj ot klonirovaniya i podgotovki zavisimostej do zapuska i ponimaniya rezuljtata bez chteniya realizacii. Dlya vyipolneniya obyichnogo scenariya ne trebuyetsya ugadyivatj absolyutnyij putj k chuzhomu checkout ili lokaljnomu binarniku.
- Inventarj ne ostavlyayet obyazateljnyij sobstvennyij komponent toljko v lokaljnom repozitorii. Dlya nezavisimyikh dopolniteljnyikh komponentov naznachenyi otdeljnyiye proveryayemyiye postavki; otsutstviye perenosa ne pomecheno gotovnostjyu.
- Lokaljnaya priyomka i publichnaya dostupnostj razlichayutsya: posle otdeljnogo razreshyonnogo dejstviya publikacii provereno polucheniye tochnogo rezuljtata i sabmodulej iz opublikovannyikh adresov. Do etogo rezuljtat nazyivayetsya lokaljno vosproizvodimyim; arkhivirovaniye obzora i sokhraneniye kartochki ne schitayutsya dostavkoj iskhodnikov.

## Rezuljtat

Vse 110 iskhodnyikh fajlov sobstvennoj realizacii dostavlenyi obyichnyimi fajlami FUM: 71 fajl chetyiryokh paketov i 39 fajlov prilozheniya, s devyatjyu neobkhodimyimi dopolneniyami prilozheniya. Iskhodnyiye Git-obyyektyi sokhranenyi; manifestyi svyazyivayut polnyiye iskhodnyiye commits, blob OID, SHA-256, rezhimyi i kanonicheskiye fajlyi. Paketyi opublikovanyi v `aeae18cb146a34563ff39c84d9bc5ef59fffab91`, obyyedinyonnyiye iskhodniki — v `9c39c9b3fde83c4ce11ba101897c1298c68d436d`; oba poluchenyi iz publichnogo origin dlya proverki.

[Proverka paketov](../../Prilozheniya/FUMA/proverka-paketov.md): 133 testa, chetyire Release-sborki i pyatj profilej. [Proverka prilozheniya](../../Prilozheniya/FUMA/proverka-prilozheniya.md): pyatj Swift i 12 Python-proverok, chetyire Release-produkta, Xcode Debug i dva sinteticheskikh profilya. Prezhniye katalogi nedostupnyi processam chteniyem cherez vneshnyuyu pesochnicu; posle proverki klon chist. Tochnyiye komandyi, iskhodnyij otkaz vlozhennoj pesochnicyi Xcode, vosstanovleniye, sreda, zavisimosti i ogranicheniya sokhranenyi v rukovodstvakh i mashinnyikh svideteljstvakh.

LinguisticKit sokhranyon vneshnim gitlink `837e2ce107b97ee7b9d3344c9fe99142281fe393` i poluchen po obyyavlennomu publichnomu adresu. Runtime, lichnyiye trassyi, kyeshi i binarniki ne perenesenyi. Sobstvennyiye paketyi poka ne podklyuchenyi k prilozheniyu; gotovnostj avtonomnogo app bundle i inyikh platform ne zayavlena.

Tekusjhij etap dopolniteljno prinimayet formatyi proyekcii i otsutstviye neobyazateljnogo grafa. Finaljnyij obsjhij dopusk, zamyikaniye otchyota i exactOID-publikaciya vyipolnyayutsya posle zamorozki etogo podgotovlennogo vkhoda i do zaversheniya zadachi; otmetka postavki iskhodnikov ne zamenyayet etu obyazateljnuyu posledovateljnostj.

## Istochniki

- [Pryamoye porucheniye i soderzhateljnyij otvet](../../Zhurnal/2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/zapros.md).
- [Vneshnij obzor repozitoriya](../../Istochniki/URL/https/chatgpt.com/share/6aa2c5c7-fe90-83ed-bd10-d7b03db8b334/obzor-github-repozitoriya.md).
- [Ogranichennaya priyomka arkhivnogo snimka](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).
- [Opisaniye arkhivnogo komponenta](../../Dokumentaciya/arkhivnyij-snimok-zadachi-FUMA.md).
- [Tekusjhaya integraciya vetok](🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:5d8fc22121f4e65a927cc186d5839ad5b1dd167f3bcd80dc81dff9168b1c9c78 -->
<!-- FUM-MD-RECENCY:END -->
