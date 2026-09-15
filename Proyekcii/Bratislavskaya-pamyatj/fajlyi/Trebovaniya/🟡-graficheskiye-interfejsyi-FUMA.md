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

## Utochneniye obsjhej realizacii

Interfejs FUMA po vozmozhnosti polnostjyu sobstvennyij: obsjhiye scena i povedeniye opisyivayutsya strukturiruyusjhimi operatorami, platformennyiye ispolniteli ispoljzuyut Metal/Vulkan. Dlya Android planiruyetsya Vulkan; sistemnyiye poverkhnostj, vvod, dostupnostj i zhiznennyij cikl ostayutsya yavnyimi platformennyimi adapterami. Prezhnyaya celj DirectX ne otmenena etim utochneniyem.

[Iskhodnyiye komandyi](../Zhurnal/2026-09-15_20-33-17_MSK_prinyatj-obnovlyonnoye-postoyannoye-planirovaniye/zapros.md).

## Status i granicyi

Pervyij graficheskij putj Windows — Vulkan s Win32 surface; DirectX ne yavlyayetsya usloviyem pervogo zapuska. Dlya macOS, iOS, tvOS i visionOS vyibran Metal. Dlya watchOS namereniye sokhranyayetsya, no publichnaya dokumentaciya Metal ne vklyuchayet etu platformu: dostupnyij graficheskij putj dolzhen byitj ustanovlen otdeljno. Obsjhiye scena i operatornaya logika sokhranyayutsya pri razlichii adapterov.

Osnovaniye: [komandyi i otvetyi](../Zhurnal/2026-09-15_20-55-24_MSK_sokhranitj-medijnyij-plan-i-zapuski-platform/otchyot.md), [Khronos](../Istochniki/URL/https/docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_win32_surface.html/source-index.md) i [dannyiye Apple](../Istochniki/URL/https/developer.apple.com/tutorials/data/documentation/metal.json/otchyot-ob-izvlechenii.md).

Status — `🟡`: prinyato i zaplanirovano. Podderzhka tryokh graficheskikh API poka ne podtverzhdena. Matrica i pervyiye proverki vkhodyat v [platformennyij plan FUMA](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).

Susjhestvuyusjheye [trebovaniye Metal dlya interfejsa Apple silicon](🟡-otrisovka-interfejsa-cherez-Metal.md) sokhranyayet svoyu specialjnuyu oblastj i prezhniye ogranichennyiye svideteljstva.

## Istochniki trebovanij

- [Komanda o graficheskikh API, zamena Mantle na Vulkan i dobavleniye Web](../Zhurnal/2026-09-11_01-03-38_MSK_zaplanirovatj-platformyi-i-grafiku-FUMA/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:15:43 MSK -->
<!-- content-sha256: sha256:848060b8d442db816548a0a4f8b0970fa012ae6d084079bf0ca30bfc4eb4ac5c -->
<!-- FUM-MD-RECENCY:END -->
