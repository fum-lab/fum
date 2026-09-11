# Setevoj sloj Swift-chasti FUMA na SwiftNIO

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0061 -->

SwiftNIO vyibran osnovoj setevogo sloya Swift-chasti FUMA. Obsjhaya setevaya arkhitektura dolzhna otdelyatj prikladnyiye operacii FUMA, protokolyi, transport i platformennyiye vozmozhnosti, sokhranyaya proveryayemoye povedeniye pri obmene dannyimi, otkaze, otmene i vosstanovlenii.

SwiftNIO predostavlyayet nizkourovnevyiye asinkhronnyiye sredstva setevogo vvoda-vyivoda. Dlya prikladnyikh protokolov, TLS, brauzernogo ispolneniya i upravleniya podklyucheniyem trebuyutsya yavno vyibrannyiye komponentyi i adapteryi. Samo prisutstviye Swift ili sborka odnogo modulya NIO na platforme ne podtverzhdayet vesj setevoj scenarij FUMA. [Naznacheniye i sostav SwiftNIO](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/README.md).

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Rolj SwiftNIO zakreplena kak vyibrannaya osnova setevogo sloya Swift-chasti; dlya kazhdogo adaptera obyyasnenyi naznacheniye, vkhodyi, vyikhodyi i granica mezhdu prikladnoj operaciyej, protokolom i platformennyim transportom.
- Dlya vsekh 15 celevyikh platform ili semejstv i otdeljno Safari, Chrome i Firefox sokhranena matrica. Ona razlichayet podderzhku Swift, nalichiye nuzhnogo modulya NIO, obyyavlennuyu upstream-podderzhku, konfiguraciyu sborki ili testov, nablyudyonnyij rezuljtat progona i proverennyij scenarij FUMA.
- Svideteljstvo svyazano s tochnyimi versiyami OS, arkhitekturoj, SDK, Swift, NIO i protokoljnyikh paketov, istochnikom, datoj nablyudeniya i predelom vyivoda. Otsutstviye dokazateljstva oboznacheno yavno i ne prevrasjheno v podderzhku ili okonchateljnuyu nevozmozhnostj.
- Dlya HTTP/1.1, WebSocket, TLS i HTTP/2 opredelenyi neobkhodimyiye komponentyi i prikladnyiye obyazannosti. NIOTLS ne schitayetsya realizaciyej TLS; novyij transportnyij ili protokoljnyij paket ne schitayetsya vyibrannyim toljko iz-za rodstva so SwiftNIO.
- Dlya Tor, I2P, Bitcoin, messendzherov, nastrojki interneta i VPN sokhranenyi samostoyateljnyiye kontraktyi integracii. Nalichiye TCP, SOCKS, TLS ili sistemnogo setevogo API ne podmenyayet eti vozmozhnosti.
- Kontrakt setevoj operacii zadayot razreshyonnuyu celj, razresheniye imeni, parametryi soyedineniya i doveriya, ogranicheniya resursov, tajm-autyi, otmenu, obratnoye davleniye, semantiku povtora, zaversheniye resursov, nablyudayemyij rezuljtat i oshibki.
- Brauzernyij adapter i vozmozhnaya svyazj s servernoj Swift-chastjyu opisanyi otdeljno. WebSocket-protokol v NIO i NIOCore dlya WebAssembly ne obyyavlyayutsya gotovyim brauzernyim transportom.
- Budusjhaya realizaciya sokhranyayet sobstvennyiye iskhodniki i primenimyiye komandyi vosproizvedeniya v FUM, prokhodit adresnyiye RED/GREEN, profilj i resheniye ob optimizacii. Pervichnaya matrica i arkhitekturnyij plan ne oznachayut nalichiya etoj realizacii.

## Status i granicyi

Status — `🟡`: osnova vyibrana i zaplanirovana. [Pervyij shag](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0195-opredelitj-matricu-SwiftNIO-i-setevyiye-adapteryi-FUMA.md) dolzhen datj proveryayemuyu matricu svideteljstv i plan setevogo sloya s raspredeleniyem protokolov i adapterov. Dobavleniye zavisimosti, realizaciya setevogo sloya i proverki FUMA na ustrojstvakh v tekusjhij etap ne vkhodyat.

Vyibor SwiftNIO ne isklyuchayet ni odnu celj iz [platformennogo trebovaniya](🟡-zapusk-FUMA-na-celevyikh-platformakh.md). Yesli pryamoj transport NIO dlya tochnogo profilya ne podtverzhdyon, plan sokhranyayet neizvestnoye i rassmatrivayet otdeljnyij adapter ili sposob vzaimodejstviya, ne obyyavlyaya yego uzhe realizovannyim. Vozmozhnosti dostupa k seti i vozmozhnosti menyatj yeyo nastrojki imeyut raznuyu oblastj.

## Istochniki trebovanij

- [Pryamoye porucheniye o SwiftNIO i soderzhateljnyij otvet](../Zhurnal/2026-09-11_02-34-29_MSK_vosstanovitj-kontekst-platformennogo-resheniya-i-SwiftNIO/materialyi/istochniki/kontekst-reshenij/kontekst-vyibora-SwiftNIO.md).
- [SwiftNIO: naznacheniye, produktyi i zayavlennaya podderzhka](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/README.md) — kommit `8c063f043d94c120d0f8d6303ef4fc7918e3561d`, nablyudeniye 2026-09-11 MSK.
- [Celevyiye platformyi FUMA](🟡-zapusk-FUMA-na-celevyikh-platformakh.md).
- [Decentralizovannyiye seti](🟡-rabota-FUMA-s-decentralizovannyimi-setyami.md).
- [Integracii s messendzherami](🟡-integracii-FUMA-s-messendzherami.md).
- [Nastrojka interneta i VPN](🟡-nastrojka-interneta-i-VPN-v-FUMA.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:37:53 MSK -->
<!-- content-sha256: sha256:7d729cb8f3f837dd4362e03f3b79bc7f4e24696b89430d46dad6992b95aa7acd -->
<!-- FUM-MD-RECENCY:END -->
