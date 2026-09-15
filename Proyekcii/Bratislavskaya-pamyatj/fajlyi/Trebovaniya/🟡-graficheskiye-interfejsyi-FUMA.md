# Graficheskiye interfejsyi FUMA

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0047 -->

FUMA dolzhna podderzhivatj graficheskiye puti Metal, DirectX i Vulkan na primenimyikh celevyikh platformakh. Pervonachaljno nazvannyij Mantle zamenyon na Vulkan po yavnomu utochneniyu poljzovatelya.

Graficheskij interfejs i nabor yego vozmozhnostej opredelyayutsya dlya konkretnogo platformennogo profilya. Trebovaniye ne oznachayet dostupnosti vsekh tryokh API na kazhdoj platforme. Brauzernyij putj veb-versii vyibirayetsya i proveryayetsya otdeljno; nalichiye nativnoj realizacii ne podtverzhdayet rabotu v brauzere.

## Semanticheskiye svyazi

- **dopolnyayet:** [zapusk FUMA na celevyikh platformakh](🟡-zapusk-FUMA-na-celevyikh-platformakh.md) — zadayot proveryayemyiye graficheskiye puti prilozheniya.

## Kriterii proverki

- Matrica svyazyivayet platformu, ustrojstvo, API, versiyu i obyazateljnyiye vozmozhnosti. Dlya kazhdogo API yestj khotya byi odin podtverzhdyonnyij profilj vyipolneniya.
- Diagnostika pokazyivayet realjno ispoljzuyemyij putj i ustrojstvo. Pryamoye obrasjheniye, dokumentirovannyij byekend i sloj perevoda razlichayutsya; programmnyij rezervnyij rezhim oboznachayetsya yavno.
- Soglasovannaya scena interfejsa FUMA prokhodit proverku otobrazheniya i vzaimodejstviya. Mezhplatformennoye sravneniye ispoljzuyet obosnovannyij dopusk, a ne trebuyet pobitovogo sovpadeniya vsekh GPU.
- Proverenyi otsutstviye neobkhodimyikh vozmozhnostej, oshibka inicializacii i vosstanovleniye posle poteri graficheskogo ustrojstva tam, gde eto primenimo.
- Obsjhaya logika, platformennyiye realizacii, otkryityiye scenyi, testyi i instrukcii khranyatsya v FUM. Tochnyiye vneshniye zavisimosti oboznachenyi.
- RED/GREEN i profilj otdeljno uchityivayut podgotovku, kadr i resursyi; resheniye ob optimizacii opirayetsya na sopostavimyij scenarij.
- Veb-versiya imeyet sobstvennyiye svideteljstva rabotyi v Safari, Chrome i Firefox. Uspekh nativnoj sborki ikh ne zamenyayet.

## Status i granicyi

Status — `🟡`: prinyato i zaplanirovano. Podderzhka tryokh graficheskikh API poka ne podtverzhdena. Matrica i pervyiye proverki vkhodyat v [platformennyij plan FUMA](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).

Susjhestvuyusjheye [trebovaniye Metal dlya interfejsa Apple silicon](🟡-otrisovka-interfejsa-cherez-Metal.md) sokhranyayet svoyu specialjnuyu oblastj i prezhniye ogranichennyiye svideteljstva.

## Istochniki trebovanij

- [Komanda o graficheskikh API, zamena Mantle na Vulkan i dobavleniye Web](https://github.com/fum-lab/fum/blob/5c9806560fb9b52112ff8a7bc11888a1bb71f7aa/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-11_01-03-38_MSK_%D0%B7%D0%B0%D0%BF%D0%BB%D0%B0%D0%BD%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%BF%D0%BB%D0%B0%D1%82%D1%84%D0%BE%D1%80%D0%BC%D1%8B-%D0%B8-%D0%B3%D1%80%D0%B0%D1%84%D0%B8%D0%BA%D1%83-FUMA/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:58:13 MSK -->
<!-- content-sha256: sha256:fc5d74549157f163d4288a98d7293b9eee54fc7344c1e2650aedc326eeb7da29 -->
<!-- FUM-MD-RECENCY:END -->
