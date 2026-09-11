# Podklyucheniye FUMA k I2P

Pervyij etap — dostavka otkryitogo obyyekta FUM cherez vstroyennuyu podderzhku I2P v libtorrent-rasterbar. Sobstvennyij Swift-adapter upravlyayet bibliotekoj, a yeyo SAM-transport podklyuchayetsya k lokaljnomu marshrutizatoru. Metadannyiye torrent i ozhidayemyij khyesh zadayutsya yavno. Obsjhij SAM 3.1 kliyent poverkh SwiftNIO ostayotsya rasshireniyem dlya servisov vne BitTorrent; dublirovatj transport biblioteki v pervom fajlovom scenarii ne trebuyetsya. Ustanovka i upravleniye marshrutizatorom oformlyayutsya sleduyusjhim etapom.

Eto postanovka napravleniya po [soobsjheniyam 242 i 244](../zapros.md), proverennaya po oficialjnyim istochnikam 11 sentyabrya 2026 goda. Kod adaptera, rabotayusjhaya setj i rezuljtatyi ispyitanij etim dokumentom ne zayavlyayutsya. Vedusjhaya osnova `a728283474931eda71cd581ca5429121124ba3f6` uzhe soderzhit napravleniye decentralizovannyikh setej REQ0048/STEP0183 i vyibor SwiftNIO REQ0061/STEP0195. Novyij material utochnyayet eti osnovaniya; nomera novyikh kartochek naznachayet susjhestvuyusjhaya avtomatizaciya priyoma.

## Chto poluchit chelovek

FUMA pokazyivayet dostupnostj lokaljnogo marshrutizatora i predlagayet operaciyu polucheniya obyyekta: adres, ozhidayemyij khyesh, predel razmera i mesto sokhraneniya. Peredacha zavershayetsya proverennyim lokaljnyim fajlom libo ponyatnoj prichinoj otkaza. Yeyo mozhno otmenitj; prekrasjheniye rabotyi marshrutizatora ne blokiruyet ostaljnyiye lokaljnyiye funkcii FUMA. Povtornoye podklyucheniye sokhranyayet vyibrannuyu setevuyu identichnostj.

Pervyij proveryayemyij primer — neboljshoj otkryityij obyyekt s zaraneye izvestnyim khyeshem. Sobstvennyij testovyij uzel pozvolyayet proveritj takzhe vkhodyasjhij potok. Publikaciya proizvoljnogo soderzhimogo, obsjhij prosmotr veba cherez outproxy i obsluzhivaniye chuzhogo trafika ne vkhodyat v pervyij primer.

## Vyibor interfejsa

| Interfejs | Primeneniye |
| --- | --- |
| SAM | Vstroyennyij transport libtorrent dlya pervogo fajlovogo sreza; obsjhij adapter FUMA dlya drugikh servisov — daljnejsheye rasshireniye. |
| HTTP/CONNECT-proksi | Otdeljnyij budusjhij scenarij chteniya HTTP-resursov. Trebuyet yavnogo razlicheniya I2P-resursa i vyikhoda cherez outproxy. |
| SOCKS | Podklyucheniye uzhe susjhestvuyusjhikh prilozhenij s podderzhkoj proksi. Vozmozhnosti vkhodyasjhikh soyedinenij i UDP zavisyat ot realizacii. |
| I2CP | Nizkourovnevoye vzaimodejstviye s marshrutizatorom. Dlya pervogo Swift-kliyenta dobavlyayet neopravdannyij obyyom realizacii. |

Oficialjnaya dokumentaciya rekomenduyet SAM dlya prilozhenij ne na Java. SAM 3.1 STREAM vyibran kak ogranichennyij profilj sovmestimosti: boleye novyiye vozmozhnosti 3.2/3.3 neodinakovo realizovanyi v Java I2P i i2pd. Tekusjhaya specifikaciya SAM obnovlena v iyule 2026 goda i pomechena API 0.9.70. [SAM v3](https://i2p.net/en/docs/api/samv3/), [razrabotka prilozhenij](https://i2p.net/en/docs/development/applications/), [I2CP](https://i2p.net/en/docs/specs/i2cp/), [I2PTunnel](https://www.i2p.net/en/docs/api/i2ptunnel/).

## Povtornoye ispoljzovaniye libtorrent

Utochneniye 244 zakreplyayet libtorrent-rasterbar 2.1.1 kak biblioteku BitTorrent. V nej uzhe yestj SAM-podklyucheniye cherez i2p_hostname i i2p_port. Dlya otdeljnogo I2P-profilya zapresjhayetsya nezametnoye smeshivaniye setej: allow_i2p_mixed ostayotsya vyiklyuchennyim, tip I2P-torrent zadayotsya i proveryayetsya yavno. Odnoj etoj nastrojki nedostatochno dlya dokazateljstva otsutstviya obyichnyikh setevyikh zaprosov: priyomka otdeljno nablyudayet DNS, DHT, trekeryi, web seeds i peer-soyedineniya. Biblioteka poluchayet predelyi resursa i privatnoye sostoyaniye vosstanovleniya cherez sobstvennyij Swift-adapter FUMA. [Nastrojki libtorrent](https://www.libtorrent.org/reference-Settings.html), [tip torrent](https://www.libtorrent.org/reference-Core.html).

Nizhe opisana obsjhaya granica SAM. V pervom BitTorrent-scenarii yeyo vyipolnyayet vstroyennaya realizaciya libtorrent; samostoyateljnyij ispolnitelj FUMA nuzhen toljko sleduyusjhemu profilyu drugikh servisov.

## Pervyij ispolnyayemyij srez

1. Avtomatizaciya proveryayet yavno zadannyij lokaljnyij endpoint SAM i soglasovyivayet versiyu.
2. Sozdayot ili vosstanavlivayet Destination, zatem dolgozhivusjhuyu upravlyayusjhuyu STREAM-sessiyu.
3. Razreshayet I2P-imya i otkryivayet otdeljnyij soket CONNECT; testovyij uzel proveryayet ACCEPT.
4. Chitayet potok s predelom razmera i obratnyim davleniyem, sokhranyayet vremennyij rezuljtat, proveryayet khyesh i toljko posle uspekha vyidayot obyyekt prilozheniyu.
5. Otmena zakryivayet otnosyasjhiyesya k operacii soyedineniya. Razryiv upravlyayusjhego soyedineniya zavershayet sessiyu i otrazhayetsya v sostoyanii FUMA.
6. Posle perezapuska avtomatizaciya proveryayet sokhranyonnuyu identichnostj i vosstanavlivayet dopustimuyu operaciyu s yavnyim rezuljtatom predyidusjhej popyitki.

V daljnejshem obsjhem SAM-profile konechnyij avtomat, ogranichennyiye ocheredi i obratnoye davleniye realizuyutsya poverkh sobyitij NIO. Pervyij BitTorrent-profilj ispoljzuyet transport libtorrent. Politika podklyucheniya prinadlezhit adapteru: otsutstviye marshrutizatora, vyiklyuchennyij SAM, nesovmestimaya versiya, neizvestnoye imya, negotovyiye tunneli i nedostupnyij uzel dayut razlichnyiye sostoyaniya. Nezametnogo pereklyucheniya na obyichnyij Internet net. Soglasovannyiye parametryi podpisi, shifrovaniya i tunnelej fiksiruyutsya v profile; ikh sovmestimostj proveryayetsya na obeikh realizaciyakh, a ne vyivoditsya toljko iz nomera SAM.

SAM-soyedineniye samo po sebe po umolchaniyu ne zasjhisjheno shifrovaniyem i autentifikaciyej. Poetomu pervyij profilj ogranichen lokaljnyim endpoint; udalyonnyij marshrutizator potrebuyet otdeljnogo zasjhisjhyonnogo kanala. Setevyiye tajm-autyi zadayutsya s uchyotom podgotovki tunnelej i povedeniya marshrutizatora. [Protokol i zhiznennyij cikl SAM](https://i2p.net/en/docs/api/samv3/).

## Identichnostj i sokhrannostj

Destination yavlyayetsya kriptograficheskoj setevoj identichnostjyu, a ne udostovereniyem lichnosti cheloveka. Publichnyij adres otdelyayetsya ot privatnyikh klyuchej i prikladnogo identifikatora FUM. Postoyannyiye klyuchi khranyatsya v privatnom khranilisjhe; ikh poterya ili nedostupnostj ne dolzhnyi molcha sozdavatj novuyu postoyannuyu identichnostj. V diagnosticheskom zhurnale sokhranyayutsya rezuljtatyi i proiskhozhdeniye operacij, no ne privatnyiye klyuchi. Imena razreshayutsya sredstvami I2P. [Imena i adresnaya kniga](https://i2p.net/en/docs/overview/naming/).

Potok predostavlyayet uporyadochennuyu dostavku bajtov; uspeshnaya zapisj v soket ne dokazyivayet sokhraneniye obyyekta drugim prilozheniyem. Podtverzhdeniya, proverka celostnosti, povtor i vozobnovleniye ostayutsya prikladnyim kontraktom FUM. Datagrammyi vyinosyatsya za pervyij srez, poskoljku trebuyut sobstvennogo resheniya poterj, poryadka i ogranichenij razmera. [Potoki](https://i2p.net/en/docs/api/streaming/), [datagrammyi](https://i2p.net/en/docs/api/datagrams/).

## Marshrutizatoryi, zerkala i licenzii

| Proveryayemaya realizaciya | Zakreplyonnyij istochnik | Licenzionnaya granica |
| --- | --- | --- |
| i2pd 2.61.0 | `635b013a612ff47278ef02acf8580a28e10e26c5` | BSD-3-Clause; sokhranyayutsya uvedomleniya, usloviya i disclaimer. Dlya vyibrannoj sborki proveryayutsya Boost, OpenSSL, zlib i opcionaljnyiye komponentyi. |
| Java I2P 2.13.0 | `9134f808337b401e8e53c73734c81fab04280c9d` | Smeshannyij sostav licenzij, vklyuchaya GPL/LGPL-komponentyi. Public domain u sam.jar ne otnositsya ko vsej postavke. |

Pervomu Swift-kliyentu ne trebuyetsya vklyuchatj iskhodniki marshrutizatora v prilozheniye. Avtomatizaciya posleduyusjhej ustanovki i oflajn-sborki dolzhna ispoljzovatj proverennyiye zerkala fum-lab, tochnyiye revizii i polnyij licenzionnyij sostav vyibrannogo profilya. Sobstvennyij kod ostayotsya CC0, vneshniye zavisimosti sokhranyayut svoi licenzii. Gotovnostj mobiljnoj upakovki i fonovoj rabotyi podtverzhdayetsya otdeljno dlya kazhdoj platformyi. [i2pd: licenziya](https://github.com/PurpleI2P/i2pd/blob/2.61.0/LICENSE), [i2pd: sostav sborki](https://github.com/PurpleI2P/i2pd/blob/2.61.0/build/CMakeLists.txt), [Java I2P: licenzii](https://github.com/i2p/i2p.i2p/blob/i2p-2.13.0/LICENSE.txt).

## Priyomka i proizvoditeljnostj

Snachala TDD bez podklyucheniya k I2P: fragmentaciya i obyyedineniye otvetov SAM, perekhod ot strok k binarnomu potoku, oshibochnaya versiya, poterya sessii, ogranicheniya pamyati, otmena, povtor posle perezapuska, neizmennostj vyibrannoj identichnosti i otsutstviye klyuchej v diagnostike. Podmena ozhidayemogo obyyekta, obryiv potoka i prevyisheniye limita ne dolzhnyi vyidavatj uspeshnyij rezuljtat.

Profilj fiksiruyet vkhod, revizii i nastrojki; izmeryayet CPU v pokoye, pamyatj, ustanovleniye sessii i soyedineniya, vremya pervogo bajta, skorostj poleznoj peredachi, otmenu i vosstanovleniye. Izderzhki sobstvennogo kliyenta otdelyayutsya ot zaderzhek marshrutizatora i seti. Po etim dannyim vyibirayetsya opravdannaya optimizaciya, zatem povtoryayetsya proverka korrektnosti na tom zhe scenarii.

Zhivaya priyomka provoditsya otdeljnyim etapom na obeikh zakreplyonnyikh realizaciyakh: odin i tot zhe otkryityij obyyekt, proverennyij khyesh, vkhodyasjhij potok, otmena i perezapusk marshrutizatora. Uspekh oznachayet rabotu etogo profilya i ne dokazyivayet absolyutnuyu anonimnostj ili dostupnostj lyubogo uzla. [Modelj ugroz I2P](https://i2p.net/en/docs/overview/threat-model/).

## Resheniya sleduyusjhego etapa

- Vyibratj postoyannuyu ili vremennuyu identichnostj dlya pervogo poljzovateljskogo scenariya; oba rezhima dolzhnyi byitj razlichimyi.
- Zakrepitj ogranicheniya pamyati, razmera obyyekta, tajm-autov i setevogo resursa.
- Snachala proveritj desktop-profilj; mobiljnyiye platformyi i upravleniye marshrutizatorom podgotovitj kak otdeljnyiye proveryayemyiye rasshireniya.
- Soglasovatj prikladnoj format zaprosa otkryitogo obyyekta s obsjhim khranilisjhem FUM, chtobyi I2P ostavalsya transportom i ne sozdaval vtoroj nesovmestimyij protokol khraneniya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 22:03:48 MSK -->
<!-- content-sha256: sha256:0a6cc656205b1025fef3131f3ac768ad9d4aa23fce76067686da47bc2d170d5a -->
<!-- FUM-MD-RECENCY:END -->
