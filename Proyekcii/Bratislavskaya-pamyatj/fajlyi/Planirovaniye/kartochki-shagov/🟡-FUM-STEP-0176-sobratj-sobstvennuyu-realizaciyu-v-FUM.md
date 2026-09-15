+++
schema_version = 1
card_id = "FUM-STEP-0176"
status = "active"
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

## Istochniki

- [Pryamoye porucheniye i soderzhateljnyij otvet](../../Zhurnal/2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/zapros.md).
- [Vneshnij obzor repozitoriya](../../Istochniki/URL/https/chatgpt.com/share/6aa2c5c7-fe90-83ed-bd10-d7b03db8b334/obzor-github-repozitoriya.md).
- [Ogranichennaya priyomka arkhivnogo snimka](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).
- [Opisaniye arkhivnogo komponenta](../../Dokumentaciya/arkhivnyij-snimok-zadachi-FUMA.md).
- [Tekusjhaya integraciya vetok](🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 18:07:01 MSK -->
<!-- content-sha256: sha256:a2710f0781837eb5b527a14dfb7eff547ca4122f626ef07762ba952f98335556 -->
<!-- FUM-MD-RECENCY:END -->
