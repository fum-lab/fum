# Pasport pilota macOS VM dlya FUMA

Pervyij srez FUM-STEP-0216 zadayot odin budusjhij pilot na Apple Silicon: zakreplyonnyij IPSW, ustanovka macOS, odnokratnaya podgotovka poljzovatelya, SSH, chistyij klon FUM, odin scenarij FUMA, shtatnaya ostanovka i povtor. Eto proveryayemyij plan, a ne gotovyij backend. Na 12 sentyabrya 2026 goda VM, obraz i uchyotnyiye dannyiye v etoj rabote ne sozdavalisj; ustanovka i gostevyiye proverki ne vyipolnyalisj.

Obyyom planirovaniya konechen. Nedostavlennyij obsjhij lifecycle, nepodtverzhdyonnyij IPSW, profilj podgotovki 0179 i nastoyasjhaya priyomka gostya ostayutsya yavno nazvannyimi zavisimostyami. Skvoznoye polnoye vosproizvedeniye sostoyaniya iz prinyatyikh vkhodov primenyayetsya zdesj k sostavu budusjhikh svideteljstv; yego realizaciya dlya vsego FUM etim pasportom ne zayavlyayetsya.

## Vkhodyi i proveryayemyiye statusyi

«Nablyudeno» oznachayet adresnoye chteniye v etoj sessii; «dokumentirovano» — utverzhdeniye Apple s datoj obrasjheniya; «vyibrano dlya proverki» — resheniye pilota; «ne podtverzhdeno» zapresjhayet perekhod k zavisyasjhej stadii. Versiya instrumenta, dostupnostj fajla, sovmestimostj i ispolneniye yavlyayutsya raznyimi faktami.

| Vkhod                 | Znacheniye i status                                                                            | Kak zavershitj proverku                                                                                                                                                                                                |
| -------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fizicheskij khost      | Nablyudeno: MacBookPro18,2, arm64, 10 logicheskikh CPU, 64 GiB RAM                              | Pered budusjhim zapuskom povtoritj `sysctl -n hw.model hw.memsize hw.logicalcpu`, `uname -m`; ne sokhranyatj serijnyij nomer                                                                                               |
| OS khosta             | Nablyudeno: macOS 27.0, build 26A428                                                          | Povtoritj `sw_vers`; eto RC-khost, a ne podtverzhdyonnyij Beta-gostj                                                                                                                                                      |
| SDK i Swift khosta    | Nablyudeno: SDK 27.0 build 26A5419a; Apple Swift 6.4, swiftlang-6.4.0.33.1, clang-2100.3.33.1 | `xcrun --sdk macosx --show-sdk-version`, `--show-sdk-build-version`, `xcrun swift --version`; zatem otdeljnaya sborka adaptera s nuzhnyimi API                                                                           |
| Xcode                | `xcodebuild -version` otkazal: vyibran Command Line Tools                                     | Polnyij Xcode i yego build ne podtverzhdenyi. Ne menyatj developer directory avtomaticheski; vyibratj i proveritj instrumentarij v otdeljnom razreshyonnom etape                                                               |
| Celevoj Beta-gostj   | Vyibran dlya proverki: macOS 27.0 beta, build 26A5353q; Apple datiruyet vyipusk 8 iyunya 2026 goda | Eto zapisj reliza, ne dokazateljstvo polucheniya IPSW; build sveritj s fakticheskim restore image                                                                                                                        |
| Boleye pozdnij vyipusk | Dokumentirovan macOS 27.0 RC, build 26A428, 9 sentyabrya 2026 goda                             | RC ne podmenyayet vyibrannuyu Beta. Izmeneniye celevogo vyipuska trebuyet novoj versii prinyatogo vkhoda i povtornoj proverki                                                                                                  |
| IPSW                 | URL konkretnogo fajla, dlina i SHA-256 neizvestnyi; bajtyi ne poluchenyi                         | Obnaruzhitj oficialjnyij kandidat, zatem otdeljno razreshyonno poluchitj fajl, proveritj yego metadannyiye i zakrepitj bajtyi; stranica zagruzok s vkhodom v Apple Account dostupnostj IPSW ne dokazyivayet                       |
| Sovmestimostj        | Ne podtverzhdena dlya paryi khost / fakticheskij IPSW                                             | `VZMacOSRestoreImage.load(from:)`, `restoreImage.isSupported`, nenulevoj `mostFeaturefulSupportedConfiguration`, podderzhannyij `hardwareModel`, granicyi CPU/RAM i `VZVirtualMachineConfiguration.validate()`           |
| Resursyi gostya        | Vyibrano: 4 vCPU, 8 GiB RAM, disk 80 GiB, odin displej 1280×800, NAT                          | CPU/RAM dolzhnyi byitj ne nizhe minimuma restore image i vnutri predelov VZ. Pri nesovpadenii otkaz i peresmotr pasporta, bez tikhogo uvelicheniya                                                                           |
| Disk khosta           | Dostupnoye mesto i rezerv ne izmerenyi dlya VM                                                  | Do polucheniya IPSW proveritj mesto: 80 GiB osnovnogo diska + 80 GiB otdeljnogo ispyitateljnogo + 80 GiB soglasovannogo rezerva + 20 GiB zapasa, to yestj 260 GiB plyus fakticheskij razmer IPSW i vspomogateljnyikh khranilisjh |

`latestSupported` ispoljzuyetsya toljko dlya obnaruzheniya kandidata: yego rezuljtat mozhet izmenitjsya i mozhet ne sovpastj s vyibrannoj Beta. Prinyatyij vkhod soderzhit iskhodnyij i konechnyij publichnyij URL, vremya, versiyu/build iz restore image, dlinu i SHA-256 fajla, istochnik doveriya i usloviya polucheniya. Khyesh udostoveryayet neizmennostj poluchennyikh bajtov, a proiskhozhdeniye Apple proveryayetsya otdeljno. Avtomaticheskoye obnovleniye obraza posle zakrepleniya zapresjheno proyektom pilota.

Do zagruzki metadannyikh restore image i operacij VZ proveryayutsya podpisj fakticheskogo processa adaptera i entitlement `com.apple.security.virtualization`. Kompilyaciya i nalichiye SDK etogo dopuska ne zamenyayut; sejchas process adaptera otsutstvuyet, dopusk ne proveren.

Apple ukazyivayet dlya Xcode 27 RC minimaljnuyu macOS Tahoe 26.6 i Apple silicon; nablyudyonnyiye SDK/Swift ne podtverzhdayut nalichiye etogo Xcode. V aktualjnyikh primechaniyakh macOS 27 RC problema 179068335 posle ustanovki Xcode 27 beta na macOS 26.5.1 ili starshe otmechena ispravlennoj, no ukazaniye vosstanovitj zatronutyij khost pereustanovkoj macOS sokhranyayetsya: istoriyu konkretnogo khosta yesjhyo nuzhno proveritj, vosstanovleniye ne vyipolnyalosj.

## Obsjhij lifecycle i otdeljnyij adapter

V kommite zapuska `01b329cb49f4c5a5655fab4c16d7ea3a3ebf55a5` net prinyatoj postavki obsjhego Linux lifecycle. Istoricheskij Linux-plan sam po sebe yeyo ne zamenyayet. Najdennyij Linux-kommit `4af8621e134c87beda89899b975a7930be4bf0ff` soderzhit realjnyiye svideteljstva SSH i povtorov, no pryamo oboznachen kontroljnoj tochkoj s nezavershyonnoj finaljnoj priyomkoj. Poetomu povtornoye ispoljzovaniye poka yavlyayetsya uslovnoj zavisimostjyu, a ne utverzhdeniyem o prinyatom obsjhem mekhanizme.

| Granica                        | Konkretnyij susjhestvuyusjhij interfejs Linux                                   | Resheniye macOS                                                                                                                |
| ------------------------------ | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Posledovateljnostj stadij      | `Конвейер.шаг(проверить:выполнить:)`                                      | Kandidat obsjhego mekhanizma proverka → effekt → svideteljstvo; povtorno ne realizovyivatj posle prinyatiya perenosimogo kontrakta |
| Sostoyaniya i gotovnostj         | `ЖизненныйЦикл.перейти(_:)`                                               | Obsjhaya proverka dopustimyikh perekhodov; macOS dobavlyayet otdeljnyiye stadii ustanovki i provisioning                               |
| Vladeniye i lokaljnoye sostoyaniye | `Хранилище(план:создать:)`, `ЧтениеХранилища(_:)`, chteniye/zapisj          | Sokhranitj obsjhuyu zasjhitu neizvestnyikh obyyektov; dannyiye platformyi khranitj otdeljnoj versiyej                                      |
| Komandyi kliyenta                | `КлиентМашины.начать`, `.состояние`, `.готовность`, `.остановить`, `.ssh` | Obsjhij vneshnij zhiznennyij cikl posle priyomki; `начать` ne ravno SSH ili poleznomu rezuljtatu                                   |
| Linux-zagruzka                 | Profilj zakryit na `ubuntu-noble-arm64-vz`, Linux EFI / NoCloud / VSOCK    | Ne perenositj kak macOS provisioning ili bootloader                                                                          |
| macOS-platforma                | V prinyatoj obsjhej postavke ne podtverzhdena                                 | Otdeljnyij adapter: restore image, VZMacOSInstaller, VZMacOSBootLoader, VZMacPlatformConfiguration i pervyij zapusk            |

Pered realizaciyej nuzhno prinyatj tochnyij OID obsjhego sloya s kontraktom interfejsov, avtonomnyimi proverkami i granicej platformennyikh zavisimostej. Neobkhodimoye vyideleniye perenosimogo sloya iz Linux ostayotsya otdeljnoj rabotoj. macOS-adapter peredayot obsjhemu sloyu rezuljtatyi i oshibki platformyi; on ne zavodit vtoroj obsjhij planirovsjhik, khranilisjhe vladeniya, SSH-kliyent ili avtomaticheskij orkestrator.

## Komplekt odnoj mashinyi i vladeniye

Budusjhij privatnyij komplekt VM khranitsya vne Git. Yego manifest svyazyivayet vladeljca, identifikator pilota, versiyu konfiguracii i zakreplyonnyij obraz so sleduyusjhimi obyyektami:

- `hardwareModel`: tochnyiye `dataRepresentation`, poluchennyiye ot podderzhannoj konfiguracii obraza; proverka obratnogo vosstanovleniya i `isSupported` pered ispoljzovaniyem.
- `machineIdentifier`: sozdan odin raz dlya etoj novoj VM, sokhranenyi iskhodnyiye bajtyi; povtor otkryivayet prezhnyuyu identichnostj. Tekusjhego znacheniya net.
- `auxiliaryStorage`: otdeljnoye khranilisjhe, sozdannoye dlya toj zhe hardwareModel i VM; vosstanovleniye otkryivayet susjhestvuyusjhij obyyekt. Izmenyayemyiye bajtyi uchityivayutsya snimkom stadii, a ne trebovaniyem vechnogo ravenstva nachaljnomu khyeshu.
- Disk: otdeljnyij 80 GiB obyyekt s izvestnyim vladeljcem, formatom, razmerom i sostoyaniyem; yego neljzya peresozdavatj pri oshibke obnaruzheniya. SHA-256 fiksiruyetsya v soglasovannom ostanovlennom snimke, poskoljku rabotayusjhij disk izmenyayetsya.
- Postoyannyij MAC-adres i konfiguraciya NAT, parametryi CPU/RAM/displeya, identifikator operacii i terminaljnyiye svideteljstva stadij. Adres DHCP ne sluzhit identichnostjyu.

Povtor proveryayet vesj komplekt i poluchayet isklyuchiteljnoye vladeniye im. Neizvestnyiye susjhestvuyusjhiye fajlyi, symlink, nesovpadeniye vladeljca ili nepolnyij komplekt oznachayut otkaz bez prisvoyeniya, ochistki ili vosstanovleniya po imeni. Kopiya dlya drugoj VM trebuyet sobstvennoj identichnosti i auxiliary storage; perenos odnoj VM na drugoj khost proveryayet prezhnij hardwareModel i sovmestimostj otdeljno.

## Ustanovka, otmena i vosstanovleniye

Ustanovka nachinayetsya toljko na ostanovlennoj VM s proverennyim lokaljnyim IPSW i sokhranyonnyim komplektom. Vyizov `install` vyipolnyayetsya na ocheredi VM i odin raz dlya dannogo ekzemplyara `VZMacOSInstaller`. Planovyij predel — 7200 sekund; fakt istecheniya sroka ne oznachayet uspeshnuyu otmenu.

Otmena aktivnoj ustanovki napravlyayetsya cherez `installer.progress.cancel()`. Do nachala ustanovki etot vyizov nedopustim; obyichnyiye pause/stop vo vremya ustanovki Apple opisyivayet kak neopredelyonnoye povedeniye. Posle zaprosa otmenyi ozhidayetsya terminaljnyij callback/error s otdeljnyim predelom 120 sekund i sokhranyayutsya iskhod, progress i fakticheski nablyudyonnoye sostoyaniye VM. Poka zaversheniye ne podtverzhdeno, komplekt ostayotsya zanyat i novyiye operacii ne nachinayutsya.

Posle avarii processa ili otsutstvuyusjhego terminaljnogo otveta stadiya schitayetsya neopredelyonnoj. Disk, hardwareModel, machineIdentifier i auxiliaryStorage sokhranyayutsya vmeste s zhurnalom operacii. Snachala podtverzhdayetsya otsutstviye prezhnego pisatelya, proveryayutsya prinadlezhnostj i celostnostj komplekta, sozdayotsya soglasovannyij rezerv ostanovlennyikh dannyikh. Chastichnyij disk ne obyyavlyayetsya ustanovlennoj sistemoj po odnomu susjhestvovaniyu fajla.

Povtor ustanovki ispoljzuyet novyij ekzemplyar installer, tot zhe zakreplyonnyij IPSW i tot zhe komplekt toljko posle dokazannogo sostoyaniya stopped i proverki konfiguracii. Eto proyektiruyemyij putj ispyitaniya: Apple ne garantiruyet prodolzheniye s prezhnego `fractionCompleted`, otkat ili uspeshnuyu pereustanovku poverkh prervannogo diska. Pri nedokazannom vosstanovlenii komplekt sokhranyayetsya dlya analiza; vozmozhnaya novaya chistaya VM — otdeljnoye razreshyonnoye dejstviye s novoj identichnostjyu. Staryiye dannyiye ne stirayutsya. Vosstanovleniye iz rezervnoj kopii vozvrasjhayet soglasovanno vesj komplekt i stadiyu, a ne odin disk ryadom s chuzhoj identichnostjyu.

## Pervyij zapusk, provisioning i SSH

Vyibrannyij sposob pervogo zapuska — dokumentirovannyij `VZMacGuestProvisioningOptions` vmeste s `VZMacOSVirtualMachineStartOptions`. Yego dostupnostj na tochnyikh SDK, host i guest macOS 27 dolzhna byitj proverena kompilyaciyej i nastoyasjhim progonom. Status sejchas: API issledovan, avtomatizaciya FUM i yeyo ispolneniye ne podtverzhdenyi. Linux NoCloud i VSOCK ne yavlyayutsya zapasnyim dokazannyim kanalom macOS.

Opcii peredayutsya metodom `setGuestProvisioning(_:)` do zapuska. Oshibka validacii blokiruyet pervyij zapusk; nalichiye obyyekta opcij samo ne oznachayet, chto oni prinyatyi.

Budusjhij sekretnyij vvod poljzovatelya i SSH-klyucha postupayet otdeljno ot publikuyemogo pasporta. Manifest khranit ssyilku na privatnyij sekretnyij obyyekt i fakt zaversheniya, ne parolj ili zakryityij klyuch. Provisioning dopuskayetsya toljko dlya pervogo zapuska posle uspeshnogo restore. Pri povtore on ne peredayotsya: susjhestvuyusjhij poljzovatelj, dannyiye i SSH-identichnostj sokhranyayutsya. Posle obryiva mezhdu sozdaniyem poljzovatelya i zapisjyu rezuljtata snachala vyiyasnyayetsya fakticheskoye sostoyaniye, povtornaya inicializaciya po otsutstviyu marker zapresjhena. Dejstviya cheloveka v Setup Assistant, yesli API ne podkhodit, trebuyut peresmotra sposoba podgotovki i ne obyyavlyayutsya prezhnej avtomaticheskoj priyomkoj.

V plane API zadayot username, fullName, password, `enablesRemoteLogin = true`, `logsInAutomatically = false`. V prochitannom interfejse net polya public key. Pervichnoye polucheniye host key i ustanovka svoyego public key v `authorized_keys` trebuyut doverennogo gostevogo kanala: dlya etogo pilota vyibran otdeljnyij ruchnoj shag cherez konsolj sobstvennoj VM. On zapisyivayetsya kak ruchnaya chastj provisioning; zavershyonnaya polnostjyu avtomaticheskaya podgotovka etim ne zayavlyayetsya. Posle nego vse proverochnyiye SSH-komandyi ispoljzuyut otdeljnyij klyuch kliyenta i sobstvennyij `known_hosts`; parolj ne peredayotsya v argv, otchyotyi ili Git.

`started` fiksiruyet lishj zapusk VM. Posle zaversheniya ruchnogo konsoljnogo shaga v predelakh 600 sekund ozhidayetsya otdeljnaya gotovnostj SSH: soyedineniye s ogranichennyimi ConnectTimeout i BatchMode, proverka doverennogo host key i uspeshnaya komanda. Polnyij otkryityij host key i yego otpechatok pervonachaljno poluchayutsya doverennyim sposobom iz etoj VM i zapolnyayut otdeljnyij `known_hosts`; `ssh-keyscan` cherez tot zhe neproverennyij adres sam doveriye ne sozdayot. Uspekh ustanovki kliyentskogo klyucha proveryayetsya soyedineniyem s khosta. Klyuchi i realjnyiye adresa ostayutsya vne Git. Smena klyucha pri povtore blokiruyet soyedineniye do vyiyasneniya.

Gostevaya komanda otdeljno podtverzhdayet `uname -m = arm64`, `sw_vers` s prinyatoj versiyej/build i metku konkretnogo pilota. Metka dopolnyayet SSH-identichnostj; ona ne zamenyayet kriptograficheskuyu proverku. Dostup k obsjhemu katalogu po umolchaniyu vyiklyuchen. Yesli on ponadobitsya, prinimayetsya tochnyij katalog toljko dlya chteniya; macOSGuestAutomountTag ne dayot gostyu proizvoljnyij dostup k khostu.

Endpoint NAT poluchayetsya cherez doverennuyu konsolj sobstvennoj VM i sokhranyayetsya privatno vmeste s yeyo identichnostjyu. Posle smenyi DHCP adres povtorno obnaruzhivayetsya tem zhe sposobom, soyedineniye po-prezhnemu trebuyet prezhnij host key. Skanirovaniye seti i sovpadeniye adresa sami ne dayut prava prisvoitj najdennuyu VM.

Dlya pilota vyibirayetsya gostevoj port SSH 22; NAT-dostizhimostj s khosta trebuyet otdeljnogo nablyudeniya. Ruchnoj konsoljnyij shag ne skryivayetsya vnutri avtomaticheskogo tajm-auta: ozhidaniye cheloveka izmeryayetsya otdeljno i pri yego otsutstvii ostayotsya nezavershyonnyim.

## Profilj podgotovki 0179 i scenarij FUMA

FUM-STEP-0179 susjhestvuyet kak aktivnaya postanovka avtomatizacii podgotovki macOS; gotovaya realizovannaya postavka profilya ne podtverzhdena. Gostevoj profilj pilota dolzhen udovletvoryatj yeyo susjhestvuyusjhim kriteriyam: inventarizaciya do zapisi, yavnyij plan nedostayusjhikh instrumentov, proverennyiye istochniki, tochnyij checkout, oblastj nastroyek Git i bezopasnyij povtor. Realizaciya 0179 ne podmenyayetsya ustanovochnyimi komandami vnutri macOS-adaptera.

Dlya pilota profilj razdelyayet obyazateljnyiye Git i Swift/SDK vyibrannogo scenariya, Python dlya primenimyikh proverok FUM, uslovnyij LinguisticKit i neobyazateljnyiye interfejsnyiye prilozheniya. Nalichiye vsego reyestra instrumentov ne yavlyayetsya usloviyem ustanovki. Sistemnyiye razresheniya FUMA i licenzii ne obkhodyatsya; ikh ruchnoye predostavleniye otrazhayetsya kak nezavershyonnaya otdeljnaya stadiya.

Vyibran odin scenarij FUMA: **arkhivnyij snimok otkryitogo JSONL → tochnyij povtor importa → replay bez iskhodnika → replay posle povtornogo zapuska VM**. Gostevoj FUM OID zakreplyon: `107eb5bb64cfb7fea2f2aa2725c8580d34e50d0c`. On soderzhit perenesyonnyij iskhodnyij kod `aeae18cb146a34563ff39c84d9bc5ef59fffab91` i svideteljstva chistogo klona. On nakhoditsya vne bazyi zapuska etogo planirovaniya; nuzhnyiye fajlyi prochitanyi iz Git-obyyektov, integraciya v tekusjhuyu vetku ne vyipolnyalasj. Publichnaya dostupnostj etogo OID proveryayetsya otdeljno pered gostevyim klonirovaniyem.

Komponent — `Приложения/FUMA/Packages/АрхивныйСнимокЗадачи`, produkt `архивный-снимок`. Fikstura `Примеры/записанный-префикс.jsonl`: 480 bajtov, tri LF-stroki, SHA-256 `72ee2e79981f0524c0fb9874ff7d7f64c4e57344999e23dd31b5129dae2abb16`. Eto otkryityij sinteticheskij vkhod, a ne realjnyiye zhurnalyi Codex. Paketu nuzhnyi Swift tools 6.0 / yazyik Swift 6 i macOS 14+; zavisimosti — sobstvennyiye sosedniye paketyi `СнимокАгентскойЗадачи` i `КонтейнерНаблюдений`. Vneshnikh SwiftPM-zavisimostej net. LinguisticKit i libmpv etomu scenariyu ne nuzhnyi; oni ne ustanavlivayutsya profilem bez drugogo osnovaniya.

Gostevoj profilj 0179 vyibirayet dlya proverki Git 2.54.0 (Apple Git-157), Apple Swift 6.4 (swiftlang-6.4.0.33.1) i SDK 27.0 build 26A5419a. Eto celevyiye znacheniya, zaimstvovannyiye iz nablyudeniya khosta, a ne ustanovlennyiye instrumentyi gostya. Istochnik — oficialjnyij paket Apple Command Line Tools s sootvetstvuyusjhim toolchain; tochnyiye identichnostj ustanovsjhika, URL, podpisj, SHA i sovmestimostj s vyibrannyim Beta-gostem yesjhyo ne podtverzhdenyi. Pri otsutstvii podkhodyasjhego paketa podgotovka blokiruyetsya, versii ne podmenyayutsya. Polnyij Xcode usloven: nuzhen, yesli konkretnyij sposob sborki ili dostupa k API potrebuyet yego. Python dlya etogo arkhivnogo CLI ne obyazatelen; dlya otdeljno vyibrannyikh proverok FUM celevoj Python 3.14.7 s sobstvennyim proverennyim istochnikom i neizmennyimi bajtami poka takzhe ne postavlen v gostya.

Klon poluchayetsya iz opublikovannogo FUM, checkout zakreplyayetsya na ukazannom 40-simvoljnom OID; `git rev-parse HEAD` i chistyij `git status --porcelain` proveryayutsya do sborki. Susjhestvuyusjhij gryaznyij klon ne ochisjhayetsya. Gitlink LinguisticKit `837e2ce107b97ee7b9d3344c9fe99142281fe393` materializuyetsya lishj pri vyibore proyekcii ili proverok, kotoryim on dejstviteljno nuzhen.

Budusjhaya komanda sborki iz kornya gostevogo klona:

```sh
swift build --package-path Приложения/FUMA/Packages/АрхивныйСнимокЗадачи --build-system native --jobs 2 -c release --product архивный-снимок
```

Backend `native` uzhe v istoricheskoj postavke otmechen ustarevshim; yego rabotosposobnostj na tochnom novom Swift proveryayetsya, a zamena ne vyipolnyayetsya molcha. Posle koda 0 fiksiruyutsya putj i SHA produkta `.build/release/архивный-снимок`. Eto podtverzhdayet sborku, no yesjhyo ne poleznyij rezuljtat.

Daljshe novyij process produkta poluchayet realjnyij interfejs `импорт <копия-фикстуры> <существующий-каталог-архива> 11111111-1111-4111-8111-111111111111`; oba puti zadayutsya otdeljno v sobstvennom privatnom kataloge gostya, vne klona. Posle koda 0 proveryayutsya kanonicheskij JSON, tot zhe UUID, poslednyaya modelj `model-one`, khod `33333333-3333-4333-8333-333333333333`, granica 480 bajtov / 3 stroki i SHA vkhoda. Znacheniye cwd beryotsya iz zakreplyonnoj fiksturyi pobajtno. Status rezuljtata — toljko zapisannyij prefiks; zhivoye vyipolneniye i zaversheniye zadachi ostayutsya neizvestnyimi.

Tochnyij povtor `импорт` dolzhen vernutj te zhe JSON-bajtyi bez rosta kontejnera. Toljko prinadlezhasjhaya ispyitaniyu kopiya vkhoda zatem ubirayetsya iz dostupnogo puti; originaljnaya fikstura Git ne menyayetsya. Novyij process `replay <каталог-архива> 11111111-1111-4111-8111-111111111111` dolzhen vernutj tot zhe JSON bez obrasjheniya k iskhodniku. Posle shtatnoj ostanovki i povtornogo zapuska VM vyipolnyayetsya tot zhe replay iz prezhnego arkhiva. Proveryayutsya otdeljno kodyi processov, bajtyi JSON, razmer kontejnera, sokhranyonnyiye dannyiye i identichnostj VM.

Istoricheskaya proverka iskhodnoj postavki vklyuchayet 35 testov arkhivnogo paketa i Release-sborku na macOS 27 arm64 / Swift 6.4. Eto osnovaniye vyibora scenariya, a ne svideteljstvo budusjhego gostevogo ispolneniya. V dannom sreze sborka i scenarij ne zapuskalisj.

## Programma budusjhej proverki

Vse privedyonnyiye predelyi — iskhodnyiye byudzhetyi pilota, a ne izmereniya skorosti ili garantii Apple. Izmeneniye byudzheta fiksiruyetsya novoj versiyej vkhoda.

| Stadiya            | Ozhidayemoye svideteljstvo                                                             | Predel i vosstanovleniye                                                                |
| ----------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Dopusk vkhodov     | Tochnyiye host/SDK/Swift, dostupnyij IPSW, khyeshi, licenzii, resursyi, prinyatoye obsjheye yadro | 60 s dlya lokaljnogo dopuska; neizvestnyij vkhod ostanavlivayet do sozdaniya                |
| Polucheniye obraza  | Proverennyiye bajtyi konkretnogo IPSW i yego metadannyiye                                 | 3600 s; chastichnyij fajl ne schitayetsya obrazom, polucheniye otdeljno razreshayetsya            |
| Ustanovka         | Terminaljnoye uspeshnoye zaversheniye installer                                          | 7200 s; otmena i vosstanovleniye po otdeljnomu kontraktu vyishe                           |
| Pervyij zapusk     | Uspeshnyij start i otdeljnyij rezuljtat provisioning                                   | 600 s; neizvestnyij rezuljtat ne zapuskayet povtornuyu inicializaciyu                      |
| SSH               | Proverka host key, arkhitekturyi, build i nuzhnogo gostya                               | 600 s summarno, 10 s na popyitku, pauza 5 s; kod/oshibka sokhranyayutsya                     |
| Podgotovka 0179   | Plan, vyipolnennyiye ustanovki, proverka profilya i tochnogo klona                       | 3600 s; prodolzheniye toljko nezavershyonnyikh dejstvij s proverkoj iskhodnyikh bajtov          |
| Sborka i scenarij | Otdeljnyiye rezuljtatyi sborki, zapuska i poleznogo vyikhoda                             | 1800 s dlya sborki, 120 s dlya scenariya; otkaz ne maskiruyetsya povtorom                   |
| Ostanovka         | Snachala shtatnyij `requestStop`, zatem nablyudyonnoye stopped                            | 120 s; prinuditeljnaya ostanovka toljko otdeljnoj yavnoj operaciyej s sokhranyonnyim iskhodom |
| Povtor            | Prezhnyaya VM, disk, poljzovatelj i doverennyij SSH; povtor scenariya                    | 600 s do SSH; provisioning otsutstvuyet, dannyiye sokhranyayutsya                             |

Sinteticheskij nabor budusjhej realizacii ne trebuyet VM: nesovmestimyij restore image, nil-konfiguraciya, nepodderzhannaya hardwareModel, nedostatok CPU/RAM/mesta; chuzhoj katalog i nepolnyij komplekt; konkurentnyij pisatelj; otmena do/vo vremya/posle ustanovki; oshibka i propavshij callback; razryiv posle sozdaniya poljzovatelya; izmenivshijsya SSH host key; nevernyij build/OID; zavisshaya ostanovka; povtor s prezhnej identichnostjyu. Proveryayetsya otsutstviye zapresjhyonnyikh effektov, a ne toljko kod oshibki. Specialjno proveryayetsya, chto `started` bez SSH i SSH bez uspeshnogo scenariya ne dayut gotovnostj.

Nastoyasjhij progon vyipolnyayetsya otdeljno posle realizacii i dopuska vkhodov: odna chistaya ustanovka, odno kontroliruyemoye preryivaniye ustanovki na otdeljnom prinadlezhasjhem ispyitaniyu komplekte, uspeshnyij pervyij zapusk, SSH, profilj 0179, sborka, scenarij, shtatnaya ostanovka i dva povtora. Preryivaniye ne provoditsya na yedinstvennom ekzemplyare poleznyikh dannyikh. Etot plan ispyitaniya ne razreshayet sejchas sozdaniye dopolniteljnoj VM.

Razdeljnyij monotonnyij profilj okhvatyivayet polucheniye obraza, ustanovku, pervyij zapusk, provisioning, ozhidaniye SSH, podgotovku, sborku, poleznuyu rabotu, ostanovku i povtor. Vlozhennyiye i perekryivayusjhiyesya intervalyi ne summiruyutsya dvazhdyi. Sokhranyayutsya iskhodnyiye parametryi, versii, razmeryi, iskhodyi i statistika vyizovov; do/posle optimizacii sravnivayutsya odinakovyiye vkhodyi. Yesli izmereniya ne opravdyivayut optimizaciyu, sokhranyayetsya resheniye ostavitj realizaciyu.

## Licenzii, vosproizvedeniye i ostatok

CC0 pamyati FUM ne menyayet usloviya Apple dlya macOS, SDK i IPSW. Do polucheniya i ispoljzovaniya fiksiruyutsya tochnyiye primenimyiye usloviya i sposob zakonnogo polucheniya; publichnoye pererasprostraneniye obraza etim pasportom ne razreshayetsya. Budusjhaya postavka khranit realjnyiye LICENSE/NOTICE vneshnikh komponentov na zakreplyonnyikh OID, bez zamenyi obsjhej metkoj CC0. Obrazyi, VM-diski, privatnyiye licenzirovannyiye binarniki, klyuchi i lokaljnyiye puti ostayutsya vne Git; otkryityij manifest otdelyayet ikh ot dostupnyikh iskhodnikov.

Dlya vyibrannogo sobstvennogo arkhivnogo komponenta dejstvuyet kornevoj `LICENSE` vyibrannogo FUM OID, SHA-256 `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499`; otdeljnogo LICENSE v iskhodnom nabore ne byilo. Eto fakt postavki, a ne osnovaniye udalyatj drugiye LICENSE/NOTICE. Dokumentyi Apple dlya SDK/obraza i ikh tochnyiye versii yesjhyo ne prinyatyi; do ispoljzovaniya oni ostayutsya vkhodnoj zavisimostjyu.

Vosproizvodimostj imeyet dve granicyi: povtor iz odnikh prinyatyikh neizmennyikh vkhodov i vosstanovleniye sokhranyonnoj konkretnoj mashinyi. Sozdaniye novoj machineIdentifier — yavnyij iskhodnyij nedeterminirovannyij vkhod, posle prinyatiya sokhranyayemyij; disk i auxiliary storage — izmenyayemyiye rezuljtatyi stadij. Bitovaya identichnostj chistyikh ustanovok macOS ne obesjhayetsya bez izmereniya. Nedostupnyiye vkhodyi ne vosstanavlivayutsya dogadkoj i ne oboznachayutsya nulevyimi znacheniyami.

Ostatok realizacii: priyomka obsjhego lifecycle s tochnyim OID; otdeljnyij macOS-adapter; zakrepleniye sovmestimogo IPSW; proverka provisioning i recovery; postavka profilya 0179; prinyatyij FUMA-scenarij iz chistogo klona; sinteticheskiye testyi i nastoyasjhij pilot. FUM-STEP-0216 sokhranyayet aktivnyij status do proverki vsej kartochki; dannyij dokument zavershayet toljko naznachennyij pervyij planovyij srez. Napravleniya oflajn-komplekta i zerkaljnoj sborki Swift sokhranyayut sobstvennyiye granicyi i zdesj ne realizuyutsya.

## Istochniki

- [Porucheniye i otchyot etogo sreza](../Zhurnal/2026-09-12_03-28-44_MSK_podgotovitj-pasport-macOS-VM/zapros.md).
- [Polnoye naznacheniye s istoricheskim manifestom](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/naznacheniya/FUM-STEP-0216.json); istoricheskaya postanovka `5934b08fefaffd5d002a1df0a422a33e47a83906`, novaya baza `01b329cb49f4c5a5655fab4c16d7ea3a3ebf55a5`.
- [Pervichnoye issledovaniye s avtorstvom](../Zhurnal/2026-09-11_15-48-40_MSK_prinyatj-planirovaniye-Gosuslug/materialyi/issledovaniya/macOS-VM-pervichnaya-postanovka.json).
- [Iskhodnaya komanda macOS VM](../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/zapros.md), [princip polnogo vosproizvedeniya](../Zhurnal/2026-09-11_21-47-07_MSK_podtverditj-README-i-utochnitj-zerkala/zapros.md).
- [Kartochka 0216](kartochki-shagov/🟡-FUM-STEP-0216-splanirovatj-profilj-i-pilot-macOS-VM-dlya-FUMA.md), [trebovaniye 0071](../Trebovaniya/🟡-plan-vosproizvodimoj-macOS-VM-dlya-FUMA.md), [podgotovka 0179](kartochki-shagov/🟡-FUM-STEP-0179-avtomatizirovatj-podgotovku-repozitoriya-na-macOS.md).
- [Apple: relizyi](https://developer.apple.com/news/releases/), [restore image](https://developer.apple.com/documentation/virtualization/vzmacosrestoreimage), [platforma](https://developer.apple.com/documentation/virtualization/vzmacplatformconfiguration).
- [Apple: Xcode 27 RC](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes.md), [macOS 27 RC](https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes.md), [proveryayemaya peredacha provisioning](https://developer.apple.com/documentation/virtualization/vzmacosvirtualmachinestartoptions/setguestprovisioning%28_%3A%29).
- [Sokhranyonnoye nablyudeniye relizov](../Istochniki/URL/https/developer.apple.com/news/releases/nablyudeniye-0216.md), [granica installer](../Istochniki/URL/https/developer.apple.com/documentation/virtualization/vzmacosinstaller/install%28%29/nablyudeniye-0216.txt), [otmena](../Istochniki/URL/https/developer.apple.com/documentation/virtualization/vzmacosinstaller/progress/nablyudeniye-0216.md), [pervyij provisioning](../Istochniki/URL/https/developer.apple.com/documentation/virtualization/vzmacguestprovisioningoptions/nablyudeniye-0216.md).
- [Iskhodnyij kod i rukovodstvo FUMA na vyibrannom OID](https://github.com/fum-lab/fum/blob/107eb5bb64cfb7fea2f2aa2725c8580d34e50d0c/Приложения/FUMA/проверка-пакетов.md), [Linux-kandidat s promezhutochnyim statusom](https://github.com/fum-lab/fum/blob/4af8621e134c87beda89899b975a7930be4bf0ff/Проекты/ВиртуальнаяМашина/README.md).
- [Apple: install](https://developer.apple.com/documentation/virtualization/vzmacosinstaller/install()), [progress](https://developer.apple.com/documentation/virtualization/vzmacosinstaller/progress), [provisioning](https://developer.apple.com/documentation/virtualization/vzmacguestprovisioningoptions), [start options](https://developer.apple.com/documentation/virtualization/vzmacosvirtualmachinestartoptions).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:01:10 MSK -->
<!-- content-sha256: sha256:289db918ac866c62cd8e86e2ee0c5b6e5914bd363c48f3c264c59e040191e4fa -->
<!-- FUM-MD-RECENCY:END -->
