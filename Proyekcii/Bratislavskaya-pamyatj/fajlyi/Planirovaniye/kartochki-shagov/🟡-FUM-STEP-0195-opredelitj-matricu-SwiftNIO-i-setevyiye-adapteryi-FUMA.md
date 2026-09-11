+++
schema_version = 1
card_id = "FUM-STEP-0195"
status = "active"
+++
# Opredelitj matricu SwiftNIO i setevyiye adapteryi FUMA

Pervyij ogranichennyij rezuljtat — proveryayemaya matrica primenimosti vyibrannoj setevoj osnovyi i arkhitekturnyij plan protokolov i adapterov Swift-chasti FUMA.

## Zadacha

Zafiksirovatj rolj SwiftNIO, utochnitj platformennyiye profili i razdelitj obsjhij setevoj kontrakt, protokolyi, transport i sistemnoye upravleniye svyazjyu. Podgotovitj resheniye, kakiye komponentyi NIO nuzhnyi kazhdomu pervomu scenariyu, kakiye zadachi ostayutsya prikladnyimi adapterami i gde dokazateljstv podderzhki poka nedostatochno.

Etot shag zakanchivayetsya predmetnyim resheniyem s istochnikami i yavnyim ostatkom. On ne dobavlyayet paketyi v proyekt, ne realizuyet setevoj sloj, ne podklyuchayet uchyotnyiye zapisi i ne izmenyayet tekusjhuyu setj poljzovatelya.

## Pochemu sejchas

Poljzovatelj vyibral SwiftNIO dlya internet-vozmozhnostej FUMA. Uzhe zaplanirovanyi 15 platform ili semejstv, tri brauzera, decentralizovannyiye seti, messendzheryi i upravleniye internetom/VPN. Obsjhaya setevaya osnova dolzhna svyazyivatj eti planyi bez avtomaticheskogo perenosa podderzhki mezhdu raznyimi protokolami i platformami.

## Kriterii zaversheniya

- Soglasovana tochnaya rolj vyibrannogo SwiftNIO: obsjhiye abstrakcii i setevoj vvod-vyivod Swift-chasti. Plan nazyivayet konkretnyiye moduli, ikh otvetstvennostj i osnovaniya vyibora; rodstvo paketov ne oznachayet obyazateljnogo vklyucheniya vsego semejstva.
- Matrica pokryivayet vse 15 celej i otdeljno Safari, Chrome i Firefox. Dlya kazhdoj ukazanyi profilj ustrojstva ili emulyatora, OS, arkhitektura, SDK, Swift, NIO, neobkhodimyiye moduli i sposob ispolneniya. Neopredelyonnyij parametr imeyet yavnyij status i konkretnyij istochnik sleduyusjhego utochneniya.
- Kazhdaya ocenka razlichayet podderzhku yazyika, nalichiye iskhodnogo koda, zayavleniye proyekta, konfiguraciyu CI, nablyudyonnyij rezuljtat sborki, testovyij progon i poleznyij setevoj scenarij FUMA. Tochnyiye kommityi, versii, data nablyudeniya, izmenyayemyiye ssyilki i predel svideteljstva sokhranenyi.
- Podgotovlen plan obsjhikh kontraktov i platformennyikh adapterov: primeneniye NIOCore, vyibor podkhodyasjhego transporta, HTTP/1.1, WebSocket, TLS i pri neobkhodimosti HTTP/2. Dlya TLS otdeljno opredelenyi realizaciya, proverka imeni i doveriya, nastrojka sertifikatov i istochnik sistemnyikh ogranichenij.
- Dlya Tor, I2P, Bitcoin i messendzherov ukazanyi otdeljnyiye protokoljnyiye kontraktyi i sposob vzaimodejstviya s neobkhodimyim komponentom. SOCKS ili TCP ne schitayutsya gotovoj integraciyej. Nastrojka seti i VPN opisana cherez otdeljnyiye sistemnyiye API, prava i sostoyaniye, a ne kak sledstviye podklyucheniya NIO.
- Dlya brauzerov sproyektirovan otdeljnyij putj transporta; kandidatyi — brauzernyiye Fetch/WebSocket API i yavnoye vzaimodejstviye s servernoj Swift-chastjyu. Sborka NIOCore/Wasm ne schitayetsya dokazateljstvom rabotyi NIOPosix libo polnogo kanala v Safari, Chrome ili Firefox. Sposob ispolneniya ostayotsya predlozheniyem do svoyej proverki.
- Vyibran odin ogranichennyij pervyij setevoj scenarij dlya posleduyusjhej realizacii, s vkhodom, nablyudayemyim rezuljtatom, otmenoj, tajm-autom, ogranicheniyami resursov, obratnyim davleniyem, povtorom i zakryitiyem soyedineniya. Protokolyi, nuzhnyiye toljko boleye pozdnim scenariyam, oboznachenyi otdeljno.
- Plan budusjhej priyomki nazyivayet izolirovannyiye fiksturyi, tochnyiye platformyi i neobkhodimyiye svideteljstva dlya otkaza DNS, soyedineniya i TLS, razryiva, otmenyi i povtornoj operacii. Dlya budusjhego koda predusmotrenyi RED/GREEN, profilj vremeni i resursov i resheniye ob optimizacii; uspeshnyiye progonyi sejchas ne zayavlyayutsya.
- Itog soderzhit zapolnennuyu matricu svideteljstv, arkhitekturnoye resheniye, spisok neobkhodimyikh adapterov i ogranichennyiye posleduyusjhiye realizacii. Yesli celj ne podtverzhdena, ona ostayotsya v matrice s obyyasnyonnyim probelom; ni odna platforma ne isklyuchayetsya molcha. Zavisimosti, realizacii i realjnyiye setevyiye nastrojki etim shagom ne izmenyayutsya.

## Pervichnyij snimok svideteljstv

Nablyudeniye istochnikov: 2026-09-11 MSK. Osnovnoj snimok SwiftNIO — `8c063f043d94c120d0f8d6303ef4fc7918e3561d`; eto reviziya prochitannogo istochnika, a ne prinyataya versiya zavisimosti FUM. [README](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/README.md) opisyivayet nizkourovnevuyu rolj proyekta. [Package.swift](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/Package.swift) soderzhit platformennyiye moduli, no sam po sebe ne dokazyivayet ikh rabotosposobnostj.

[Platformennaya tablica Swift](https://github.com/swiftlang/swift-org-website/blob/ee5a7123ce9ddb631f3c45a9efc94787c0c72de0/platform-support/_platform-support.md) sluzhit svideteljstvom podderzhki yazyika i SDK. [PR CI NIO](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/.github/workflows/pull_request.yml) i [matrica Apple-sborok](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/.github/workflows/macos_tests.yml) pokazyivayut nastroyennyiye proverki, a ne prochitannyiye rezuljtatyi zapuskov. [Android-skript](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/scripts/swift-build-with-android-sdk.sh) vyipolnyayet kross-sborku; dlya Wasm PR yavno vyibirayet toljko `--target NIOCore`. Ni odin iz etikh artefaktov ne yavlyayetsya proverkoj prilozheniya FUMA.

| Celj FUMA       | Svideteljstvo Swift                                       | Svideteljstvo NIO i predel vyivoda                                                                                                          |
| --------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| macOS           | Ukazana v tablice Swift.                                  | README NIO zayavlyayet razrabotku i testirovaniye; yestj testovyij CI. Priyomka FUMA ne vyipolnena.                                                |
| Linux           | Ukazanyi konkretnyiye distributivyi Swift.                    | README NIO zayavlyayet razrabotku i testirovaniye; yestj Linux CI. Eto ne vse distributivyi i arkhitekturyi.                                       |
| Windows         | Ukazana v tablice Swift.                                  | Yestj CNIOWindows i vklyuchyonnyij PR CI s swift test. Rezuljtatyi etikh progonov zdesj ne issledovanyi.                                           |
| iOS             | Ukazana v tablice Swift.                                  | Yestj zayavleniye README, NIOTS i konfiguraciya sborki Apple. Testovyij zapusk iOS v etoj konfiguracii po umolchaniyu vyiklyuchen.                   |
| Android         | Yestj oficialjnyij Swift SDK dlya Android.                   | V NIO yestj scenarij kross-sborki Android SDK; prochitannyij skript vyipolnyayet swift build. Ustrojstvo i setj etim ne proverenyi.               |
| Tizen           | Otdeljnoye podtverzhdeniye v prochitannoj tablice ne najdeno. | Pryamogo svideteljstva nuzhnogo transporta NIO v prochitannyikh istochnikakh net. Nuzhen otdeljnyij profilj.                                        |
| watchOS         | Ukazana v tablice Swift.                                  | README NIOTS i konfiguraciya sborki Apple; testovyij zapusk po umolchaniyu vyiklyuchen. Nuzhna proverka dostupnyikh setevyikh rezhimov.                 |
| Wear OS         | Obsjhij Android SDK ne dokazyivayet eto semejstvo.            | Neljzya perenositj rezuljtat Android-sborki NIO na chasyi bez otdeljnogo profilya i scenariya.                                                  |
| tvOS            | Ukazana v tablice Swift.                                  | README NIOTS i konfiguraciya sborki Apple; testovyij zapusk po umolchaniyu vyiklyuchen. Priyomka prilozheniya ne vyipolnena.                          |
| Android TV      | Obsjhij Android SDK ne dokazyivayet eto semejstvo.            | Otdeljnyij profilj NIO i prikladnoj setevoj scenarij ne podtverzhdenyi.                                                                       |
| visionOS        | Ukazana v tablice Swift.                                  | V tekusjhem CI NIO yestj konfiguraciya sborki visionOS; testovyij zapusk po umolchaniyu vyiklyuchen. README NIOTS ne dayot otdeljnoj stroki visionOS. |
| Meta Horizon OS | Primenimostj obsjhego Android SDK trebuyet proverki.         | Otdeljnogo svideteljstva NIO dlya etogo semejstva v prochitannyikh istochnikakh net.                                                             |
| Android XR      | Primenimostj obsjhego Android SDK trebuyet proverki.         | Otdeljnogo svideteljstva NIO dlya etogo semejstva v prochitannyikh istochnikakh net.                                                             |
| PlayStation     | Otdeljnoye podtverzhdeniye v prochitannoj tablice ne najdeno. | Nuzhnyi tochnyij SDK i dostupnoye svideteljstvo setevogo transporta; podderzhka NIO ne ustanovlena.                                              |
| Xbox            | Windows kak platforma Swift ne dokazyivayet Xbox.           | Windows CI NIO ne yavlyayetsya proverkoj Xbox; otdeljnyij transportnyij profilj ne ustanovlen.                                                   |
| Web: Safari     | Swift SDK dlya Wasm susjhestvuyet; eto ne proverka brauzera.  | PR CI NIO sobirayet dlya Wasm toljko NIOCore. Brauzernyij transport i scenarij Safari ne podtverzhdenyi.                                        |
| Web: Chrome     | Swift SDK dlya Wasm susjhestvuyet; eto ne proverka brauzera.  | Svideteljstvo sborki NIOCore ne podtverzhdayet setevoj scenarij Chrome. Nuzhen brauzernyij adapter.                                            |
| Web: Firefox    | Swift SDK dlya Wasm susjhestvuyet; eto ne proverka brauzera.  | Svideteljstvo sborki NIOCore ne podtverzhdayet setevoj scenarij Firefox. Nuzhen brauzernyij adapter.                                           |

Granica otsutstviya svideteljstva otnositsya toljko k prochitannyim pervichnyim istochnikam. Ona ne dokazyivayet tekhnicheskuyu nevozmozhnostj porta. Semejstva ustrojstv, zakryityiye SDK i ogranicheniya rasprostraneniya dolzhnyi poluchitj samostoyateljnuyu proverku v ramkakh polnoj platformennoj matricyi.

Istoricheskiye minimaljnyiye versii OS v README NIO ne perenosyatsya avtomaticheski na budusjhuyu postavku: nuzhno soglasovatj konkretnyiye versii Swift, SDK, NIO i vsekh vyibrannyikh paketov. README, manifest i CI dayut raznyiye svedeniya i ne zamenyayut drug druga.

Oficialjnaya [dokumentaciya perenosa Swift v Wasm](https://docs.swift.org/latest/documentation/wasmguide/porting/) otdeljno otmechayet ogranicheniya brauzernoj sredyi i nedostupnostj obyichnyikh soketov i nizkourovnevoj seti. Sborka obsjhego koda trebuyet samostoyateljnogo resheniya o brauzernom vvode-vyivode. Prochitana JSON-forma DocC; yeyo SHA256 ukazan nizhe, a tochnyij kommit publikacii stranicyi ne ustanovlen.

## Pervichnoye raspredeleniye komponentov

- `NIOCore` zadayot obsjhiye abstrakcii, `NIOPosix` — transportnyij vvod-vyivod, `NIOEmbedded` — upravlyayemyij kontur bez realjnoj seti. `NIOHTTP1` i `NIOWebSocket` predostavlyayut nizkourovnevyiye protokolyi. Prikladnoj setevoj scenarij stroitsya poverkh etikh komponentov. [Sostav NIO](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/README.md).
- `NIOTLS` soderzhit obsjhiye abstrakcii. Realjnyij TLS vyibirayetsya otdeljno: `NIOSSL` ispoljzuyet BoringSSL; NIOTS dayot drugoj putj cherez Network.framework. [NIOSSL](https://github.com/apple/swift-nio-ssl/blob/322f3c2a4a21df31c84ca416bf65ee5e9059e440/README.md), [NIOTS](https://github.com/apple/swift-nio-transport-services/blob/f5b11d7931f92e3b6fcbf590de446fd48e9deec5/README.md).
- `NIOHTTP2` realizuyet HTTP/2 otdeljno ot TLS. Yego vyibor dolzhen uchityivatj nastrojku transporta i soglasovaniye protokola. [Dokumentaciya NIOHTTP2](https://github.com/apple/swift-nio-http2/blob/c702a62e279b520712837887ea7f28d456189bc9/Sources/NIOHTTP2/Docs.docc/index.md).
- NIOTS predostavlyayet aljternativnyij transport cherez Network.framework/Dispatch. README pryamo razlichayet funkcionaljnuyu dostupnostj na perechislennyikh Apple-platformakh i vozmozhnostj sobratj uslovno otklyuchyonnyij modulj na Linux. Upominaniye sistemnyikh proxy/VPN-vozmozhnostej ne dokazyivayet nastrojku VPN silami FUMA. [README NIOTS](https://github.com/apple/swift-nio-transport-services/blob/f5b11d7931f92e3b6fcbf590de446fd48e9deec5/README.md).
- `NIOSOCKS` iz extras — vozmozhnyij komponent SOCKS v5; polnota nuzhnyikh komand, autentifikacii i konkretnoj integracii proveryayetsya otdeljno. On ne yavlyayetsya gotovyimi Tor, I2P ili Bitcoin. [Dokumentaciya NIOSOCKS](https://github.com/apple/swift-nio-extras/blob/9b2b225177296c405b63afa4849bbb7af51a75d9/Sources/NIOSOCKS/Docs.docc/index.md).
- SwiftNIO QUIC i SwiftNIO HTTP/3 susjhestvuyut kak otdeljnyiye proyektyi aktivnoj razrabotki bez stabiljnogo API v prochitannyikh README. Oni ostayutsya otdeljnyimi kandidatami dlya issledovaniya zrelosti, a ne obyazateljnyimi zavisimostyami pervogo sreza. [QUIC](https://github.com/apple/swift-nio-quic/blob/05363a4355e417e9aa05ad9e51bec34916c6f916/README.md), [HTTP/3](https://github.com/apple/swift-nio-http3/blob/5a9ed08d16fb0222ffe6d02c3ceea2a010cec1f3/README.md).

## Svyazannyiye rabotyi

- [Setevoj sloj Swift-chasti FUMA na SwiftNIO](../../Trebovaniya/🟡-setevoj-sloj-Swift-chasti-FUMA-na-SwiftNIO.md).
- [Platformennyiye sborki i pervyij scenarij FUMA](🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).
- [Adapteryi decentralizovannyikh setej](🟡-FUM-STEP-0183-opredelitj-adapteryi-decentralizovannyikh-setej.md).
- [Adapteryi messendzherov](🟡-FUM-STEP-0184-opredelitj-adapteryi-messendzherov.md).
- [Nastrojka interneta i VPN](🟡-FUM-STEP-0185-opredelitj-nastrojku-interneta-i-VPN.md).

## Istochniki

- [Pryamoye porucheniye poljzovatelya i soderzhateljnyij otvet](../../Zhurnal/2026-09-11_02-34-29_MSK_vosstanovitj-kontekst-platformennogo-resheniya-i-SwiftNIO/materialyi/istochniki/kontekst-reshenij/kontekst-vyibora-SwiftNIO.md).
- [SwiftNIO README](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/README.md), [manifest](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/Package.swift), [PR CI](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/.github/workflows/pull_request.yml), [Windows/Linux unit-test workflow](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/.github/workflows/unit_tests.yml), [Apple workflow](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/.github/workflows/macos_tests.yml), [Android build script](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/scripts/swift-build-with-android-sdk.sh) — kommit `8c063f043d94c120d0f8d6303ef4fc7918e3561d`, datirovan 2026-09-09; nablyudeniye 2026-09-11 MSK.
- [Swift platform support](https://github.com/swiftlang/swift-org-website/blob/ee5a7123ce9ddb631f3c45a9efc94787c0c72de0/platform-support/_platform-support.md), [Swift SDK for Android](https://github.com/swiftlang/swift-org-website/blob/ee5a7123ce9ddb631f3c45a9efc94787c0c72de0/documentation/articles/swift-sdk-for-android-getting-started.md), [Swift SDKs for Wasm](https://github.com/swiftlang/swift-org-website/blob/ee5a7123ce9ddb631f3c45a9efc94787c0c72de0/documentation/articles/wasm-getting-started.md) — kommit sajta `ee5a7123ce9ddb631f3c45a9efc94787c0c72de0`, datirovan 2026-09-08; nablyudeniye 2026-09-11 MSK. Stranicyi podtverzhdayut vozmozhnosti Swift, a ne NIO na kazhdom ustrojstve.
- [NIOSSL README](https://github.com/apple/swift-nio-ssl/blob/322f3c2a4a21df31c84ca416bf65ee5e9059e440/README.md) — `322f3c2a4a21df31c84ca416bf65ee5e9059e440`; [NIOHTTP2 DocC](https://github.com/apple/swift-nio-http2/blob/c702a62e279b520712837887ea7f28d456189bc9/Sources/NIOHTTP2/Docs.docc/index.md) — `c702a62e279b520712837887ea7f28d456189bc9`; [NIOTS README](https://github.com/apple/swift-nio-transport-services/blob/f5b11d7931f92e3b6fcbf590de446fd48e9deec5/README.md) — `f5b11d7931f92e3b6fcbf590de446fd48e9deec5`; [NIOSOCKS DocC](https://github.com/apple/swift-nio-extras/blob/9b2b225177296c405b63afa4849bbb7af51a75d9/Sources/NIOSOCKS/Docs.docc/index.md) — `9b2b225177296c405b63afa4849bbb7af51a75d9`. OID poluchenyi 2026-09-11 01:28:27 MSK; eto svideteljstva naznacheniya komponentov, a ne mezhplatformennoj priyomki FUMA.
- [SwiftNIO QUIC](https://github.com/apple/swift-nio-quic/blob/05363a4355e417e9aa05ad9e51bec34916c6f916/README.md) — `05363a4355e417e9aa05ad9e51bec34916c6f916`; [SwiftNIO HTTP/3](https://github.com/apple/swift-nio-http3/blob/5a9ed08d16fb0222ffe6d02c3ceea2a010cec1f3/README.md) — `5a9ed08d16fb0222ffe6d02c3ceea2a010cec1f3`. Nablyudeniye 2026-09-11 01:31:41 MSK; aktivnaya razrabotka bez stabiljnogo API.
- [Swift Wasm: Porting](https://docs.swift.org/latest/documentation/wasmguide/porting/); prochitannyij [DocC JSON](https://docs.swift.org/latest/data/documentation/wasmguide/porting.json), SHA256 `b8ca302d72f7543098e912ece5e0b875a8258d3e3959918c81e0a9e992d3716c`, nablyudeniye 2026-09-11 MSK. URL izmenyayemyij, tochnyij kommit publikacii ne ustanovlen; ogranicheniya ne vyidayutsya za rezuljtat proverki konkretnogo brauzera.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:37:53 MSK -->
<!-- content-sha256: sha256:0e3bdc416091852f123cd632148e75d570e9d4134d2e1c05d72e444f9a680375 -->
<!-- FUM-MD-RECENCY:END -->
