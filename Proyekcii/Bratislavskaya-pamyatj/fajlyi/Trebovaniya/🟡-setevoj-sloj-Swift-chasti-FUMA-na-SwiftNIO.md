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

## Razdeleniye I2P-profilej

Fajlovyij BitTorrent-scenarij I2P planiruyetsya cherez vstroyennyij SAM libtorrent-rasterbar. Sobstvennyij Swift-sloj upravlyayet bibliotekoj, parametrami, sostoyaniyem i prikladnoj proverkoj obyyekta; on ne vyidayotsya za uzhe gotovyij SAM-kliyent na SwiftNIO. Nuzhnyiye tochnyiye API i granicyi resursa podtverzhdayutsya na vyibrannom pin do realizacii.

Sobstvennyij SAM 3.1 STREAM-kliyent poverkh vyibrannogo SwiftNIO ostayotsya otdeljnyim budusjhim profilem servisov vne BitTorrent. V nyom NIO obsluzhivayet transport, sobyitiya i obratnoye davleniye, a SAM-sessiya, Destination, razresheniye I2P-imyon i prikladnoj rezuljtat prinadlezhat protokoljnomu adapteru. Eto razdeleniye sokhranyayet SwiftNIO kak vyibrannuyu osnovu Swift-chasti i ne trebuyet dublirovatj chuzhoj vstroyennyij transport. Prezhniye kriterii, vse platformyi i brauzeryi sokhranyayutsya; ni odin iz profilej sejchas ne obyyavlyayetsya realizovannyim.

## Istochniki trebovanij

- [Prorabotka I2P i utochneniye vyibora libtorrent](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_21-56-09_MSK_уточнить-план-подключения-I2P/запрос.md).
- [Material koordinatora o podklyuchenii I2P](../Planirovaniye/integracii/I2P/podklyucheniye-I2P.md).

- [Pryamoye porucheniye o SwiftNIO i soderzhateljnyij otvet](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_02-34-29_MSK_восстановить-контекст-платформенного-решения-и-SwiftNIO/материалы/источники/контекст-решений/контекст-выбора-SwiftNIO.md).
- [SwiftNIO: naznacheniye, produktyi i zayavlennaya podderzhka](https://github.com/apple/swift-nio/blob/8c063f043d94c120d0f8d6303ef4fc7918e3561d/README.md) — kommit `8c063f043d94c120d0f8d6303ef4fc7918e3561d`, nablyudeniye 2026-09-11 MSK.
- [Celevyiye platformyi FUMA](🟡-zapusk-FUMA-na-celevyikh-platformakh.md).
- [Decentralizovannyiye seti](🟡-rabota-FUMA-s-decentralizovannyimi-setyami.md).
- [Integracii s messendzherami](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Требования/🟡-интеграции-FUMA-с-мессенджерами.md).
- [Nastrojka interneta i VPN](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Требования/🟡-настройка-интернета-и-VPN-в-FUMA.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:52:33 MSK -->
<!-- content-sha256: sha256:e3219742abec298547b602220c7c33a0f52060d33406f19c2ef657de995d4bb2 -->
<!-- FUM-MD-RECENCY:END -->
