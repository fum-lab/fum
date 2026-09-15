# Medijnyij trakt FUMA

FUMA gotovit ozvuchku i generiruyemoye video, sokhranyayet rezuljtat, razdayot yego cherez BitTorrent i svyazyivayet s publikaciyami na YouTube, Twitch, Telegram i MAX. [Porucheniya i otvetyi](../../Zhurnal/2026-09-15_21-58-20_MSK_zaplanirovatj-medijnyiye-adapteryi-i-arkhiv/zapros.md) zadayut etot obyyom. Eto postanovka: generaciya, razdacha i publikaciya etim dokumentom ne obyyavlyayutsya rabotayusjhimi.

## Putj ot zamyisla k publikacii

Chelovek zadayot scenarij, golos, oformleniye i naznacheniya. FUMA pokazyivayet predvariteljnyij rezuljtat; prinyatyij mediafajl poluchayet khyesh i sokhranyayetsya v postoyannom fajlovom khranilisjhe. Odin artefakt stanovitsya osnovaniyem Torrent-razdachi i publikacij. Yesli plosjhadke nuzhen drugoj format, otdeljnaya proizvodnaya versiya sokhranyayet svyazj s iskhodnikom, parametryi kodirovaniya i sobstvennyij khyesh.

Zhurnal khranit scenarij, proiskhozhdeniye vkhodov, versii operatorov i modelej, nastrojki, rezuljtatyi izmerenij, ssyilki na fajlyi i identifikatoryi publikacij. Krupnyiye binarnyiye fajlyi ne pomesjhayutsya v Git. Sokhraneniye chernovika i razresheniye publikacii — otdeljnyiye sostoyaniya. Neizvestnyij iskhod otpravki trebuyet sverki pered povtorom.

Dlya efira zapisj sokhranyayetsya po mere translyacii. Zavershyonnyiye neizmenyayemyiye fragmentyi i ikh poryadok pozvolyayut vosstanovitj zapisj posle sboya; okonchateljnaya sborka poluchayet sobstvennuyu identichnostj. Obyichnyij torrent ne izmenyayetsya na meste pri kazhdom novom fragmente. Versiya, otpravlennaya platforme, sokhranyayetsya nezavisimo ot vozmozhnogo perekodirovaniya na yeyo storone.

## Lokaljnaya ozvuchka

Pervyij scenarij — russkaya rechj dlya rolikov; zatem proveryayetsya prigodnostj dlya pryamogo efira. Upravlyayutsya proiznosheniye, udareniya, pauzyi, temp, montazh i smeshivaniye; tekst svyazan s subtitrami i vremennyimi intervalami.

Chistyij vyichisliteljnyij kontrakt poluchayet tekst, normalizaciyu, tochnyiye vesa i golos, parametryi, sostoyaniye generatora sluchajnyikh chisel i yavnoye sostoyaniye potoka. On vozvrasjhayet PCM, novoye sostoyaniye i diagnosticheskoye nablyudeniye. Zapisj fajlov, vosproizvedeniye i setj vyipolnyayutsya otdeljnyimi adapterami effektov. Vesa dostupnyi lokaljno; zagruzka vo vremya sinteza ne trebuyetsya posle podgotovki polnogo nabora.

Chistota interfejsa ne dokazyivayet pobitovuyu odinakovostj raznyikh vyichislitelej. Seed sam po sebe nedostatochen: sokhranyayutsya backend, biblioteki, tochnostj i profilj determinirovannyikh operacij. Gotovoye audio sokhranyayetsya obyazateljno; vosproizvedeniye ispoljzuyet yego bez povtornoj generacii. Mezhdu fragmentami yavno perenositsya neobkhodimoye modeljnoye sostoyaniye, a ne toljko gotovaya ocheredj PCM.

Dvizhok i golos yesjhyo ne vyibranyi. Pered vyiborom otdeljno proveryayutsya licenzii koda, tochnyikh vesov, golosa i zavisimostej, v tom chisle prigodnostj dlya publichnyikh materialov FUM. Licenziya sobstvennogo adaptera ne zamenyayet licenzii modeli. Kandidatami dlya issledovaniya ostayutsya lokaljnyiye ONNX-dvizhki i modeli s razreshyonnyim russkim profilem; gotovyij perenos grafa na Metal ne predpolagayetsya.

## Torrent i postoyannoye khraneniye

Ispoljzuyetsya raneye vyibrannaya libtorrent-rasterbar 2.1.1, pin 56ae8caba38bf154ffc210403cb23f91d0ecaa49, BSD-3-Clause. Vyibor zakreplyon v [FUM-STEP-0183](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0183-opredelitj-adapteryi-decentralizovannyikh-setej.md). Pervyij obyichnyij BitTorrent-profilj ne vklyuchayet WebTorrent; I2P sokhranyayet svoj otdeljnyij kontrakt.

Tonkij Swift/C++-adapter upravlyayet zagruzkoj, sozdaniyem metadannyikh, razdachej, otmenoj i vosstanovleniyem, perevodya sobyitiya biblioteki v nablyudeniya FUMA. Torrent yavlyayetsya transportom mezhdu uzlami s fajlami: nalichiye magnet-ssyilki ne dokazyivayet dostupnosti dannyikh. Postoyannyiye kopii i sostoyaniye sidov nablyudayutsya otdeljno. Registraciya u trekera i seeding=true ne dokazyivayut dostavku poluchatelyu.

Manifest svyazyivayet SHA-256 polnogo fajla, razmer, format, parametryi kodirovaniya, torrent-identifikator s ukazaniyem versii protokola, sokhranyonnyiye metadannyiye i proiskhozhdeniye. Khyesh fajla ne podmenyayetsya info-hash torrent. Gotovoye audio, generiruyemoye video, ikh iskhodnyiye prinyatyiye dorozhki i otpravlennyiye proizvodnyiye versii razlichayutsya.

## Adapteryi plosjhadok

### Ignorirovaniye binarnyikh rezuljtatov v Git

Yesli khranilisjhe raspolozheno vnutri checkout, avtomatizaciya sozdayot vlozhennyij .gitignore v specialjno vyidelennoj papke media. On isklyuchayet soderzhimoye i sokhranyayet sam .gitignore v Git. Pravila proveryayutsya cherez git check-ignore s uchyotom roditeljskikh isklyuchenij; sluchaj uzhe otslezhivayemogo binarnika obnaruzhivayetsya do zapisi. Susjhestvuyusjhiye poljzovateljskiye pravila ne zatirayutsya, fajlyi ne udalyayutsya i ne isklyuchayutsya iz indeksa molcha. Manifestyi i Zhurnal raspolagayutsya vne ignoriruyemoj papki. Dlya khranilisjha vne checkout takaya zapisj ne trebuyetsya.

Povtor idempotenten. Proverki okhvatyivayut probelyi i specialjnyiye simvolyi v putyakh, roditeljskoye ignorirovaniye, uzhe otslezhivayemyij fajl, simvolicheskiye ssyilki i otkaz zapisi. Binarnik ne dolzhen statj vidimyim dlya obyichnogo git add mezhdu sozdaniyem kataloga i ustanovkoj isklyucheniya.

### Publikaciya i nablyudeniya

YouTube: dannyiye kanala i materialov, podgotovka zagruzki, upravleniye translyaciyej i chteniye dostupnoj vladeljcu analitiki. Twitch: dannyiye kanala i translyacii, razreshyonnyiye izmeneniya i sobyitiya EventSub. Peredacha audiovideopotoka i kodirovaniye vyidelyayutsya otdeljno ot upravlyayusjhego API.

Telegram ispoljzuyet raneye vyibrannyij kliyentskij API TDLib; MAX — Bot API dlya kanalov FUM. Novyiye mediaadapteryi pereispoljzuyut eti napravleniya. Uchyotnyiye dannyiye, prava kanala, ogranicheniya zaprosov i dostupnostj operacii proveryayutsya v sootvetstvuyusjhem adaptere. API plosjhadki samo po sebe ne oznachayet polucheniya finansirovaniya.

Pervaya realizaciya YouTube/Twitch rabotayet na otkryityikh fiksturakh: tipizirovannyiye zaprosyi i otvetyi, paginaciya, neizvestnyiye polya, povtoryi sobyitij, oshibki 401/403/429 i neizvestnyij iskhod zapisi. Podpisj webhook proveryayetsya nad iskhodnyimi bajtami; deduplikaciya sokhranyayetsya mezhdu perezapuskami. Realjnyiye akkauntyi i publikacii podklyuchayutsya otdeljnyim proveryayemyim etapom.

## Pervyij proveryayemyij rezuljtat i paralleljnaya rabota

1. Torrent-zadacha: neboljshoj sinteticheskij mediafajl, proverennyij manifest, razdacha i polucheniye vtoryim kliyentom, tochnoye sovpadeniye SHA-256, preryivaniye i vosstanovleniye, nablyudeniya v pamyati FUMA.
2. Medijnyiye API: obsjhij tipizirovannyij kontrakt i samostoyateljnyiye adapteryi YouTube/Twitch na fiksturakh, s privyazkoj identifikatorov k sokhranyonnomu artefaktu.
3. Ozvuchka: vyibor razreshyonnogo russkogo golosa, oflajn-sintez neskoljkikh replik, sokhraneniye PCM/audiofajla i metadannyikh, povtor posle perezapuska i vosstanovleniye mezhdu fragmentami.

Dlya kazhdogo izmeneniya ispolnyayemogo koda obyazateljnyi TDD, profilj i resheniye ob optimizacii. Dlya rechi izmeryayutsya vremya pervogo zvuka, otnosheniye vremeni sinteza k dliteljnosti audio, pamyatj i vosstanovleniye. Dlya Torrent — podgotovka metadannyikh, vremya pervogo bloka i polnogo polucheniya, pamyatj, povtornyij zapusk. Znacheniya ustanavlivayutsya izmereniyami, ne predpolozheniyem.

Kod vkhodit v obsjhij Swift-paket FUMA, komponentyi razdelyayutsya po naznacheniyu i susjhnostyam; platformennyiye razlichiya vyirazhayutsya cherez #if. Obsjhij manifest i perenos iskhodnikov sejchas prinadlezhat zadache Android; novyij ispolnitelj soglasuyet izmeneniya obsjhikh fajlov s vladeljcem. Kazhdaya pishusjhaya zadacha poluchayet otdeljnyij worktree i vetku.

Poljzovatelj yavno poruchil paralleljnyij zapusk Torrent-napravleniya. Pered sozdaniyem zadachi nuzhno prinyatj minimaljnyij dopusk postoyannyikh vetok v avtomatizaciyu priyoma, soglasovatj aktivnyikh chitatelej obsjhego sostoyaniya i zakrepitj postanovku tochnyim kommitom. Poka eto usloviye ne vyipolneno, zadacha ne obyyavlyayetsya zapusjhennoj.

## Pervichnyiye materialyi

- [YouTube Live Streaming API](../../Istochniki/URL/https/developers.google.com/youtube/v3/live/getting-started/source-index.md).
- [Twitch API](../../Istochniki/URL/https/dev.twitch.tv/docs/api/reference/source-index.md).
- [Ogranicheniya vosproizvodimosti PyTorch](../../Istochniki/URL/https/docs.pytorch.org/docs/2.14/notes/randomness.html/source-index.md).
- Vyibor libtorrent i tranzitivnyiye licenzii — v ukazannoj vyishe kartochke 0183; novyiye istochniki ne zamenyayut proverku tochnogo pin.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 22:09:58 MSK -->
<!-- content-sha256: sha256:c8a44371560c10cffe857b8f5cd54d5e9cb611d85751ebf57c13631a6cea0a6e -->
<!-- FUM-MD-RECENCY:END -->
