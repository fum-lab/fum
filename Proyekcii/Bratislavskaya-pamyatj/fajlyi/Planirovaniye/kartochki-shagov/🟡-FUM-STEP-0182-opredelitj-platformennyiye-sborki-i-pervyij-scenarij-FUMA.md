+++
schema_version = 1
card_id = "FUM-STEP-0182"
status = "active"
+++
# Opredelitj platformennyiye sborki i pervyij scenarij FUMA

## Zadacha

Podgotovitj proveryayemuyu matricu i vosproizvodimyij pervyij poljzovateljskij scenarij FUMA dlya vsekh celevyikh platform. Na etoj osnove vyidelitj platformennyiye realizacii s otdeljnyimi svideteljstvami zapuska i obsjhej proveryayemoj logikoj.

## Pochemu sejchas

Poljzovatelj potreboval zapuskayemyij proyekt FUMA na 14 platformakh i dopolnil perechenj PlayStation i Xbox, zatem isklyuchil Microsoft Windows Holographic. Tekusjhaya celj okhvatyivayet 15 platform i semejstv, a posleduyusjheye porucheniye dobavlyayet Web v Safari, Chrome i Firefox. Avtomatizacii nastrojki GitHub Actions, macOS, Linux i Windows uzhe zaplanirovanyi, no podgotovka sredyi ne zamenyayet produktovuyu podderzhku.

## Nachaljnaya matrica

Dlya vsekh strok celj prinyata; konkretnyij profilj i zapusk yesjhyo ne podtverzhdenyi.

| Platforma       | Utochnyayemyij profilj                                                           |
| --------------- | ---------------------------------------------------------------------------- |
| macOS           | Ustrojstva, OS i arkhitekturyi                                                 |
| Linux           | Distributivyi, okruzheniya i arkhitekturyi                                        |
| Windows         | Vyipuski OS i arkhitekturyi; zapusk prilozheniya otlichatj ot WSL-sredyi razrabotki |
| iOS             | Ustrojstva, OS i sposob postavki                                             |
| Android         | Ustrojstva, OS i sposob postavki                                             |
| Tizen           | Semejstvo ustrojstv, OS i SDK                                                |
| watchOS         | Ustrojstva, OS i samostoyateljnostj prilozheniya                                |
| Wear OS         | Ustrojstva, OS i samostoyateljnostj prilozheniya                                |
| tvOS            | Ustrojstva, OS i vzaimodejstviye s puljtom                                    |
| Android TV      | Ustrojstva, OS i vzaimodejstviye s puljtom                                    |
| visionOS        | Ustrojstva, OS i prostranstvennyij interfejs                                  |
| Meta Horizon OS | Ustrojstva, OS i razreshyonnyiye SDK                                             |
| Android XR      | Ustrojstva, OS i razreshyonnyiye SDK                                             |
| PlayStation     | Pokoleniya konsolej, SDK, dopusk razrabotchika i sposob zapuska                |
| Xbox            | Pokoleniya konsolej, SDK, dopusk razrabotchika i sposob zapuska                |
| Web — Safari    | OS, versiya brauzera, sposob razmesjheniya i graficheskij putj                    |
| Web — Chrome    | OS, versiya brauzera, sposob razmesjheniya i graficheskij putj                    |
| Web — Firefox   | OS, versiya brauzera, sposob razmesjheniya i graficheskij putj                    |

Microsoft Windows Holographic ne vkhodit v tekusjhuyu matricu po posleduyusjhemu resheniyu poljzovatelya.

## Kriterii zaversheniya

- Matrica polnostjyu pokryivayet FUM-REQ-0046. Dlya kazhdoj stroki ustanovlenyi versiya, arkhitektura, sborochnaya sreda, ustrojstvo ili simulyator, sposob ustanovki i dostupnostj instrumentov.
- Do arkhitekturnoj realizacii opredelyon pervyij poleznyij scenarij i sposob vzaimodejstviya na kazhdom klasse ustrojstv. Vliyayusjhiye na smyisl voprosyi o samostoyateljnosti prilozheniya i raspredelyonnom ispolnenii utochnenyi s poljzovatelem.
- Vyidelenyi obsjhaya logika, sovmestimyiye dannyiye i platformennyiye adapteryi. Perenosimostj Swift-paketov proverena; nepodtverzhdyonnaya vozmozhnostj odnoj interfejsnoj tekhnologii na vsekh platformakh ne ispoljzuyetsya kak predposyilka.
- Dlya SDK, podpisaniya, magazinov, konsolej i ustrojstv proverenyi oficialjnyiye aktualjnyiye istochniki i usloviya dostupa. Ogranichennyiye SDK i uchyotnyiye dannyiye ne kopiruyutsya v otkryityij repozitorij.
- Sobstvennyiye realizacii i otkryityiye fiksturyi nakhodyatsya v monorepozitorii; obsjheye opisaniye zavisimostej ispoljzuyetsya avtomatizaciyami okruzheniya i CI.
- Dlya kazhdogo profilya zadan avtomatiziruyemyij scenarij iz chistogo klona: podgotovka, sborka, ustanovka, zapusk i proverka rezuljtata. Razlichayutsya lokaljnaya proverka, fizicheskoye ustrojstvo, simulyator i publikaciya.
- Pervyij proverennyij vertikaljnyij scenarij soprovozhdayetsya RED/GREEN, profilem, resheniyem ob optimizacii i svideteljstvami tochnogo kommita. Ostaljnyiye platformyi poluchayut neperesekayusjhiyesya shagi s kriteriyami priyomki; pervyij uspekh ne obyyavlyayet gotovnostj ostaljnyikh.
- Chelovek poluchayet ponyatnuyu instrukciyu vyibora platformyi, zapuska i chteniya rezuljtata. Nezavershyonnyiye stroki matricyi, vneshniye zavisimosti i sleduyusjhiye dejstviya vidnyi yavno.

- Dlya graficheskikh putej matrica vklyuchayet Metal, DirectX i Vulkan soglasno FUM-REQ-0047; Mantle zamenyon poljzovatelem na Vulkan. Versii i primenimyiye vozmozhnosti vyibirayutsya posle proverki. Brauzernyij putj zadayotsya otdeljno i proveryayetsya v kazhdom celevom brauzere.

## Plan primeneniya Swift System

Poljzovatelj vyibral Swift System dlya sistemnyikh interfejsov Swift-chasti FUMA. Plan otnosit k biblioteke toljko yavno predostavlennyiye yeyu nizkourovnevyiye interfejsyi i deskriptoryi resursov. Ostaljnyiye nuzhnyiye funkcii opredelyayutsya otdeljno po platformennyim API. Eto utochnyayet vyibor sistemnogo sloya v susjhestvuyusjhej FUM-STEP-0182 i ne zamenyayet yeyo polnyiye kriterii zaversheniya.

Opornoye chteniye zakrepleno na versii 1.8.1. Eto versiya issledovaniya, okonchateljnyij vyibor zavisimosti yesjhyo ne vyipolnen. Soglasno [README etoj versii](https://raw.githubusercontent.com/apple/swift-system/1.8.1/README.md), paket otrazhayet platformennyiye sistemnyiye interfejsyi, a yedinaya mezhplatformennaya abstrakciya ne obesjhana. Darwin/POSIX API nazvanyi stabiljnyimi, Windows API — nestabiljnyimi. Dlya semejstva 1.7.0–1.8.x ukazanyi Swift 6.1 i Xcode 16.3 ili noveye; otdeljnyiye API imeyut dopolniteljnyiye usloviya.

| Predmetnaya oblastj | Podtverzhdyonnyij interfejs i granica |
| --- | --- |
| Predstavleniye puti | [FilePath](https://raw.githubusercontent.com/apple/swift-system/1.8.1/Sources/System/FilePath/FilePath.swift): sintaksis i predstavleniye puti; sravneniye ne dokazyivayet tozhdestvo fajlovogo obyyekta. |
| Fajlovyij vvod-vyivod | [FileDescriptor i operacii](https://raw.githubusercontent.com/apple/swift-system/1.8.1/Sources/System/FileOperations.swift): open, close, seek, read, write i drugiye obyyavlennyiye operacii; dostupnostj proveryayetsya dlya konkretnoj peregruzki i OS. |
| Oshibki i fajlovyiye atributyi | Errno i [FilePermissions](https://raw.githubusercontent.com/apple/swift-system/1.8.1/Sources/System/FilePermissions.swift); bityi dostupa ne predostavlyayut prilozheniyu sistemnyikh polnomochij. [Stat](https://raw.githubusercontent.com/apple/swift-system/1.8.1/Sources/System/FileSystem/Stat.swift) v etoj versii isklyuchyon dlya Windows. |
| Resursyi Darwin | [Mach.Port](https://raw.githubusercontent.com/apple/swift-system/1.8.1/Sources/System/MachPort.swift) i prava receive/send/send-once otnosyatsya k Darwin. |
| Asinkhronnyij vvod-vyivod Linux | [IORing](https://raw.githubusercontent.com/apple/swift-system/1.8.1/Sources/System/IORing/IORing.swift) trebuyet Linux, compiler 6.2 ili noveye, Lifetimes i realjnuyu vozmozhnostj io_uring; vozmozhen notSupported. Odnogo obsjhego minimaljnogo Swift 6.1 nedostatochno. |

Blizhajshij rezuljtat utochneniya — matrica: nuzhnaya operaciya → tochnoye obyyavleniye API i versiya paketa → toolchain i OS/SDK → usloviya dostupa → trebuyemyij platformennyij adapter → proveryayemyij scenarij. Nepodtverzhdyonnaya podderzhka ostayotsya neizvestnoj. Eta karta ne dokazyivayet nalichiye GUI, drajverov, upravleniya sluzhbami, polnogo setevogo steka ili rabotosposobnosti vsekh strok platformennoj matricyi. Iz neyo takzhe ne sleduyet otsutstviye lyubyikh setevyikh primitivov. Podderzhka WASI ne dokazyivayet gotovnostj prilozheniya v Safari, Chrome i Firefox.

Samostoyateljnyij setevoj obyyom FUM-STEP-0195 sokhranyayetsya. Dlya sleduyusjhego ogranichennogo scenariya mozhno predlozhitj chteniye otkryitoj fajlovoj fiksturyi cherez FilePath/FileDescriptor s yavnyim rezuljtatom i Errno; eto kandidat plana. Do realizacii zadayutsya fikstura, nezavisimyij ozhidayemyij rezuljtat, RED/GREEN i profilj. Tekusjhij priyom sokhranyayet utochneniye postanovki; paket ne podklyuchyon, sistemnyiye operacii ne vyipolnyalisj, vsya FUM-STEP-0182 ne obyyavlena zavershyonnoj.

## Pervyij integracionnyij srez macOS

V ramkakh pervogo scenariya vyideleno podklyucheniye gotovogo Swift-interpretatora k osnovnomu rantajmu FUMA: vkhod prilozheniya → tipizirovannoye vyipolneniye operatora v tom zhe processe → rezuljtat → dolgovechnoye nablyudeniye. Ispolnyayusjhaya logika i kontejner nablyudenij pereispoljzuyutsya iz susjhestvuyusjhikh sobstvennyikh realizacij.

Ogranichennyij rezuljtat trebuyet skvoznoj proverki, sokhraneniya oshibok i predelov, vosproizvedeniya podtverzhdyonnoj zapisi, sborok SwiftPM i prilozheniya i profilya tochnogo snimka. Odna zavisimostj ne dokazyivayet podklyucheniya. Podrobnyiye granicyi — v [operatornom plane](../operatornyij-interfejs-FUMA.md), istochnik — [postanovka rantajma](../../Zhurnal/2026-09-15_18-29-25_MSK_zakrepitj-vosemj-reshenij-obrabotki/zapros.md). Pervyij uspekh macOS ne zakryivayet ostaljnyiye platformyi i polnuyu kartochku.

## Pervyiye srezyi tvOS, visionOS, Android TV, Android XR, Wear OS i watchOS

Dlya shesti platform trebuyetsya vosproizvesti obsjhij poleznyij scenarij FUMA: dejstviye poljzovatelya → vyipolneniye strukturiruyusjhego operatora → sokhraneniye vkhoda, rezuljtata i trassyi → povtornoye chteniye i replay posle perezapuska. Nachaljnyij scenarij ispoljzuyet preobrazovaniye UTF-8 v Unicode-skalyaryi i UTF-32LE po [Android-planu rantajma](../../Prilozheniya/FUMA/plan-Android-runtime.md); vkhodnaya fikstura i nezavisimyij ozhidayemyij rezuljtat zadayutsya do realizacii. Eto vyibrannyij proyektnyij scenarij, a ne doslovnaya formulirovka poljzovatelya.

Srezyi utochnyayut FUM-REQ-0046 i FUM-REQ-0047. Obsjhaya logika pereispoljzuyetsya; razlichiya ogranichivayutsya platformennyimi adapterami. Obsjhij `Package.swift` i migraciya iskhodnikov ostayutsya u Android-vladeljca do prinyatoj postavki. Realizaciya kazhdogo sreza nachinayetsya ot yavno prinyatogo obsjhego kommita; otdeljnyiye OS-forki kodovoj bazyi ne sozdayutsya. Istoricheskaya opublikovannaya postavka sama po sebe ne dokazyivayet aktualjnuyu obsjhuyu bazu.

| Platforma  | Proveryayemyij pervyij srez                                       | Sreda i graficheskaya granica                                                                                                |
| ---------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| tvOS       | Vvod s puljta, fokus i podtverzhdeniye dejstviya obsjhego scenariya | Ustanovitj dostupnyij profilj SDK i Simulator libo ustrojstva; Metal-kadr proveryatj otdeljno ot rantajma.                   |
| visionOS   | Obsjhij scenarij v minimaljnom okne                             | Proveritj SDK, sredu zapuska i konkretnyiye Metal API; prostranstvennoye vzaimodejstviye vyidelitj sleduyusjhim srezom.            |
| Android TV | Obsjhij scenarij s upravleniyem puljtom i fokusom                | Proveritj ABI, urovenj API, TV-obraz libo ustrojstvo i graficheskiye vozmozhnosti vyibrannogo profilya.                         |
| Android XR | Obsjhij scenarij v okonnoj obolochke                             | Proveritj dostup k SDK, ABI/API i XR-srede; XR-vzaimodejstviye i grafiku podtverditj otdeljno.                              |
| Wear OS    | Obsjhij scenarij s dostupnyim vvodom chasov                       | Proveritj profilj chasov, samostoyateljnostj i zavisimostj ot telefona; podderzhku GPU so smartfona ne perenositj.            |
| watchOS    | Obsjhij scenarij v dostupnoj obolochke chasov                     | Proveritj SDK, sredu i samostoyateljnostj; graficheskij putj ustanovitj otdeljnyim SDK-probnikom, Metal zaraneye ne naznachatj. |

### Obsjhiye kriterii priyomki sreza

- Ukazanyi tochnyij iskhodnyij kommit, versii toolchain i SDK, OS, arkhitektura, ustrojstvo libo obraz sredyi. Dostupnostj SDK, Simulator, API i GPU podtverzhdayetsya otdeljno; neizvestnyiye i nedostupnyiye vozmozhnosti sokhranyayut yavnyij status.
- Iz chistogo klona vosproizvodyatsya podgotovka, sborka, ustanovka, zapusk i proverka rezuljtata. Komandyi, iskhodyi, sborochnyiye artefaktyi i neobkhodimyiye vneshniye usloviya sokhranenyi; uspekh odnogo etapa ne zamenyayet ostaljnyiye.
- Poleznyij scenarij rantajma sokhranyayet vkhod, ozhidayemyiye i fakticheskiye bajtyi, rezuljtat operatora i trassu. Posle perezapuska proveryayutsya chteniye zapisi i replay; oshibki i ogranicheniya ostayutsya nablyudayemyimi.
- Graficheskij rezuljtat imeyet otdeljnoye svideteljstvo: fakticheski ispoljzuyemyij API i ustrojstvo, otobrazheniye soglasovannoj scenyi i obrabotka vvoda. Podderzhka grafiki ne vyivoditsya iz uspeshnoj sborki ili scenariya rantajma.
- Zapusk na Simulator ili emulyatore, zapusk na fizicheskom ustrojstve i publichnaya postavka uchityivayutsya razdeljno. Neproverennyiye granicyi ne obyyavlyayutsya dostignutyimi.
- Dlya izmenyonnogo koda vyipolnenyi primenimyiye RED/GREEN, profilj i obosnovannoye resheniye ob optimizacii. Sobstvennyiye iskhodniki, otkryityiye fiksturyi, konfiguracii i instrukcii vosproizvedeniya sokhranyayutsya v monorepozitorii.
- Rezuljtat kazhdogo sreza ocenivayetsya samostoyateljno. On ne zakryivayet ostaljnyiye platformyi, polnuyu STEP0182 ili trebovaniya FUM-REQ-0046/0047.

## Svyazannyiye rabotyi i poryadok

Dlya pervogo diagnosticheskogo scenariya macOS prinyata [postanovka operatornogo interfejsa FUMA](../operatornyij-interfejs-FUMA.md): Swift zapuskayet Codex CLI, sokhranyayet nablyudayemyij potok v pamyati, a strukturiruyusjhiye operatoryi preobrazuyut sostoyaniye v komandyi Metal. Yazyik operatorov i GUI imeyut obsjhuyu semanticheskuyu osnovu. Prioritet realizacii ostayotsya u obrabotki konteksta; utochneniye ne zakryivayet etu kartochku i ne podtverzhdayet rabotayusjhij ekran.

Snachala utochnyayutsya matrica i obsjhij scenarij; zatem platformennyiye rezuljtatyi mogut vyipolnyatjsya paralleljno v otdeljnyikh rabochikh derevjyakh. Polnaya realizaciya vsekh platform ostayotsya obyyomom trebovaniya i ne podmenyayetsya zaversheniyem etoj kartochki.

- [Graficheskiye interfejsyi FUMA](../../Trebovaniya/🟡-graficheskiye-interfejsyi-FUMA.md).
- [Trebovaniye zapuska FUMA](../../Trebovaniya/🟡-zapusk-FUMA-na-celevyikh-platformakh.md).
- [Sobratj sobstvennuyu realizaciyu v FUM](✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).
- [Nastrojka GitHub Actions](🟡-FUM-STEP-0178-avtomatizirovatj-nastrojku-GitHub-Actions.md).
- [Podgotovka macOS](🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md).
- [Podgotovka Linux](🟡-FUM-STEP-0180-avtomatizirovatj-podgotovku-repozitoriya-na-Linux.md).
- [Podgotovka Windows](🟡-FUM-STEP-0181-avtomatizirovatj-podgotovku-repozitoriya-na-Windows.md).

## Istochniki

- [Tri komandyi o shesti platformakh i granica obsjhego paketa](../../Zhurnal/2026-09-15_22-43-25_MSK_prinyatj-bazu-planirovaniya-chipov-i-platform/zapros.md).
- [Postanovka shesti srezov](../../Zhurnal/2026-09-16_01-31-26_MSK_utochnitj-shestj-platformennyikh-srezov/zapros.md).

- [Utochneniye yazyika operatorov, diagnosticheskogo GUI i pamyati macOS](../../Zhurnal/2026-09-15_15-40-41_MSK_utochnitj-operatornyij-interfejs-FUMA/zapros.md).

- [Iskhodnoye trebovaniye i dva soobsjheniya, dopolnivshiye perechenj](../../Zhurnal/2026-09-11_01-03-38_MSK_zaplanirovatj-platformyi-i-grafiku-FUMA/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:40:25 MSK -->
<!-- content-sha256: sha256:97c7b335191c1db6fccb7494a254e2bf7f9a4f963aa6ef7559a80954b3e41705 -->
<!-- FUM-MD-RECENCY:END -->
