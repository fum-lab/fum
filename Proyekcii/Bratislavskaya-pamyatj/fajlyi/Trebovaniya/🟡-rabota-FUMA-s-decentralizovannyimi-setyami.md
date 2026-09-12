# Rabota FUMA s decentralizovannyimi setyami

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0048 -->

FUMA dolzhna predusmatrivatj rabotu s Torrent, Tor, I2P, Bitcoin i podklyucheniye drugikh setej cherez rasshiryayemyiye adapteryi. Vozmozhnosti i rezuljtat kazhdoj integracii proveryayutsya otdeljno.

Seti ne schitayutsya vzaimozamenyayemyimi: obsjhij interfejs sokhranyayet osobennosti peredachi dannyikh, svyazi i operacij s reyestrom. Slovo «drugiye» trebuyet rasshiryayemosti, no ne podtverzhdayet podderzhku proizvoljnoj seti zaraneye. Dlya oboznacheniya Torrent iskhodnyim kandidatom yavlyayetsya BitTorrent; tochnyij protokol i scenarij zakreplyayutsya do realizacii.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Dlya kazhdoj nazvannoj seti opredelenyi konkretnyiye operacii, protokol i versii, rezhim ispoljzovaniya susjhestvuyusjhego uzla libo upravlyayemogo processa, sovmestimostj s platformami FUMA.
- Adapter soobsjhayet vozmozhnosti, sostoyaniye, rezuljtat, oshibki i ogranicheniya. Povtor, otmena i vosstanovleniye imeyut proverennyij kontrakt.
- Priyom dannyikh, publikaciya ili razdacha, upravleniye uzlom, podpisaniye i otpravka tranzakcij razlichayutsya. Operaciya ispoljzuyet naznachennyiye prava; samo podklyucheniye ne razreshayet publikaciyu privatnoj pamyati ili rasporyazheniye sredstvami.
- Vneshniye dannyiye proveryayutsya pered vklyucheniyem v pamyatj. Proiskhozhdeniye i rezuljtat operacii sokhranyayutsya v Zhurnale bez sekretov.
- Proverenyi nedostupnostj uzlov, povrezhdyonnyiye dannyiye, razryiv svyazi, povtor, vosstanovleniye i ogranicheniya resursov. Zayavlennyiye svojstva privatnosti proveryayutsya otdeljno.
- Realizaciya i otkryityiye fiksturyi nakhodyatsya v FUM. Adresnyiye testyi rabotayut bez vneshnej seti po umolchaniyu; zhivaya sovmestimostj podtverzhdayetsya otdeljnyim scenariyem, profilem i resheniyem ob optimizacii.
- Podklyucheniye novogo adaptera ne trebuyet podmenyatj semantiku uzhe podderzhivayemyikh setej; chelovek vidit podderzhivayemyiye dejstviya i sposobyi zapuska.

## Status i granicyi

Status — `🟡`: prinyato i zaplanirovano. Pervoye dejstviye — [opredelitj adapteryi i scenarii](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0183-opredelitj-adapteryi-decentralizovannyikh-setej.md). Rabota integracij poka ne podtverzhdena. Dlya Bitcoin obyyom operacij zadayotsya yavno; finansovyiye dejstviya ne vyivodyatsya iz obsjhego trebovaniya sovmestimosti.

## Pervyij planiruyemyij fajlovyij profilj I2P

Pervyij profilj — polucheniye otkryitogo obyyekta FUM po BitTorrent cherez vstroyennuyu podderzhku SAM v libtorrent-rasterbar. Sobstvennyij Swift-adapter zadayot parametryi, upravlyayet operaciyej i otobrazhayet sostoyaniye; transport I2P vyipolnyayet biblioteka. Metadannyiye torrent, ozhidayemyij khyesh obyyekta, predel razmera i mesto sokhraneniya zadayutsya yavno. Budusjhij rezuljtat — proverennyij lokaljnyij fajl libo razlichimyij otkaz, s otmenoj i dopustimyim vosstanovleniyem. Eto plan, a ne uzhe realizovannaya integraciya.

I2P-profilj ispoljzuyet yavno zadannyij lokaljnyij endpoint SAM cherez i2p_hostname/i2p_port. allow_i2p_mixed=false i torrent_flags::i2p_torrent zadayutsya i proveryayutsya po tochnomu kontraktu vyibrannoj revizii. Odnikh parametrov nedostatochno: budusjhaya priyomka nablyudayet fakticheskoye otsutstviye nezhelateljnyikh soyedinenij clearnet, DNS, DHT, trekerov, web seeds i peer-soyedinenij vne prinyatoj I2P-oblasti. Oshibochnyiye ili smeshannyiye metadannyiye ne dayut nezametnogo pereklyucheniya v obyichnyij Internet. Otkaz marshrutizatora ne blokiruyet ostaljnyiye lokaljnyiye funkcii FUMA.

Publichnyij Destination, privatnyiye klyuchi, prikladnaya identichnostj FUM i sostoyaniye vozobnovleniya razlichayutsya. Do realizacii proveryayetsya, kak vyibrannyij pin biblioteki podderzhivayet trebuyemyij rezhim identichnosti i yeyo vosstanovleniye; otsutstvuyusjhij API ne vyidumyivayetsya. Poterya klyucha ne razreshayet molcha sozdavatj novuyu postoyannuyu identichnostj. Diagnostika ne publikuyet klyuchi i privatnoye sostoyaniye, uspeshnaya zapisj v soket ne dokazyivayet priyom obyyekta.

Sobstvennyij SAM 3.1 STREAM-kliyent poverkh SwiftNIO ostayotsya otdeljnyim rasshireniyem dlya servisov vne BitTorrent; pervyij fajlovyij scenarij ne dubliruyet vstroyennyij transport libtorrent. Ustanovka i upravleniye marshrutizatorom, HTTP/outproxy, SOCKS, I2CP, datagrammyi, mobiljnaya upakovka i obsluzhivaniye chuzhogo trafika ne vkhodyat avtomaticheski. Vse prezhniye kriterii i ostaljnyiye seti sokhranyayutsya.

## Istochniki trebovanij

- [Prorabotka I2P i utochneniye vyibora libtorrent](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_21-56-09_MSK_уточнить-план-подключения-I2P/запрос.md).
- [Material koordinatora o podklyuchenii I2P](../Planirovaniye/integracii/I2P/podklyucheniye-I2P.md).

- [Porucheniye predusmotretj decentralizovannyiye seti](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_01-07-38_MSK_запланировать-децентрализованные-сети/запрос.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:52:33 MSK -->
<!-- content-sha256: sha256:33741b41ee65c83593abd2f76953bd62f2a534983861c74fe744d182077e36fb -->
<!-- FUM-MD-RECENCY:END -->
