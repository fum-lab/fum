+++
schema_version = 1
card_id = "FUM-STEP-0183"
status = "active"
+++
# Opredelitj adapteryi decentralizovannyikh setej

## Zadacha

Sproyektirovatj vosproizvodimyiye integracii FUMA s Torrent, Tor, I2P i Bitcoin, vyibratj pervyij poleznyij scenarij dlya kazhdoj i podgotovitj neperesekayusjhiyesya shagi realizacii.

## Pochemu sejchas

Poljzovatelj potreboval rabotu s nazvannyimi setyami i vozmozhnostj dobavlyatj drugiye. Obsjhikh materialov o decentralizacii nedostatochno dlya proveryayemoj sovmestimosti konkretnyikh protokolov.

## Kriterii zaversheniya

- Dlya kazhdoj seti opisanyi vkhod, nablyudayemyij rezuljtat i granicyi pervogo scenariya. Do zavisimogo resheniya zakreplenyi znacheniye Torrent, operacii Bitcoin i rezhim ispoljzovaniya uzla.
- Obsjhij kontrakt okhvatyivayet vozmozhnosti, podgotovku, operaciyu, sostoyaniye, otmenu, vosstanovleniye i proiskhozhdeniye, sokhranyaya osobennosti kazhdogo protokola.
- Po oficialjnyim istochnikam proverenyi versii, dostupnyiye realizacii, SDK i usloviya ispoljzovaniya. Matrica svyazana s platformami FUMA; ogranicheniya konkretnoj OS ili brauzera vidnyi.
- Dlya chteniya, publikacii, razdachi, upravleniya processom, podpisaniya i otpravki dannyikh opredelenyi otdeljnyiye polnomochiya i svideteljstva effekta.
- Podgotovlenyi otkryityiye scenarii otkaza i vosstanovleniya, izolirovannyiye testovyiye uzlyi ili fiksturyi, komandyi zhivoj proverki i plan profilirovaniya. Syiryiye privatnyiye dannyiye ne vklyuchayutsya v publichnyiye materialyi.
- Realizacii poluchayut sobstvennyiye ogranichennyiye shagi s kriteriyami priyomki; obsjhaya avtomatizaciya okruzheniya i CI vosproizvodit primenimyiye proverki. Plan ne obyyavlyayetsya rabotayusjhej integraciyej.

## Svyazannyiye rabotyi

- [Trebovaniye setevyikh integracij](../../Trebovaniya/🟡-rabota-FUMA-s-decentralizovannyimi-setyami.md).
- [Platformennyiye sborki FUMA](🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).
- [Podgotovka GitHub Actions](🟡-FUM-STEP-0178-avtomatizirovatj-nastrojku-GitHub-Actions.md).
- [Sobstvennyiye iskhodniki v monorepozitorii](🟡-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

## Prinyatyij plan fajlovogo scenariya I2P cherez libtorrent

Posle utochneniya o libtorrent pervyij I2P-scenarij ispoljzuyet vstroyennyij SAM biblioteki libtorrent-rasterbar; sobstvennyij Swift-adapter upravlyayet bibliotekoj i svyazyivayet yeyo s obyyektom FUM. Po soglasovannyim otvetam na pervichnyiye voprosyi 238 i 244 vyibran libtorrent-rasterbar 2.1.1, polnyij OID 56ae8caba38bf154ffc210403cb23f91d0ecaa49. Koordinator sozdal zerkalo fum-lab/libtorrent i soobsjhil dostizhimostj etogo OID; lokaljnoye polucheniye i sborka etim pisatelem ne vyipolnyalisj. Metadannyiye torrent i ozhidayemyij khyesh zadayutsya yavno. Obsjhij SAM 3.1 kliyent na SwiftNIO — daljnejsheye rasshireniye servisov vne BitTorrent, a ne povtornaya realizaciya transporta etogo pervogo sreza.

Do realizacii plan zakreplyayet lokaljnyiye i2p_hostname/i2p_port, allow_i2p_mixed=false i proverku torrent_flags::i2p_torrent na tochnoj versii API. On opisyivayet dopustimyiye I2P-celi, povedeniye pri smeshannyikh libo oshibochnyikh metadannyikh, predelyi pamyati, ocheredej, razmera, vremeni i setevogo resursa. Politika proveryayetsya nablyudayemyimi setevyimi iskhodami: nezhelateljnyiye clearnet/DNS/DHT/trackers/webseed/peer-zaprosyi otsutstvuyut, a ne toljko nazvanyi vyiklyuchennyimi v konfiguracii. Vyibrannaya biblioteka ne poluchayet razresheniya na publikaciyu proizvoljnoj pamyati, obsluzhivaniye chuzhogo trafika ili vyikhod cherez outproxy.

Pervyij proveryayemyij obyyekt mal, otkryit i imeyet zaraneye izvestnyij khyesh; operaciya vyidayot celevoj fajl toljko posle proverki. Sobstvennyij testovyij uzel proveryayet neobkhodimyij vkhodyasjhij potok. Plan razlichayet otsutstviye marshrutizatora, vyiklyuchennyij SAM, nesovmestimuyu versiyu, neizvestnoye imya, negotovyiye tunneli, nedostupnyij uzel, razryiv, otmenu, prevyisheniye limita i narusheniye celostnosti. Prekrasjheniye operacii zakryivayet yeyo resursyi i sokhranyayet yavnyij iskhod; povtor i vozobnovleniye ne prevrasjhayut chastichnuyu peredachu v uspekh.

Postoyannaya i vremennaya setevyiye identichnosti razlichayutsya; fakticheskaya vozmozhnostj sokhraneniya vyibrannoj Destination i klyuchej proveryayetsya na pin libtorrent, ne predpolagayetsya po obsjhemu opisaniyu SAM. Yesli nuzhnoye upravleniye ne predostavleno, ostayotsya konkretnoye usloviye razbora do realizacii. Privatnyiye klyuchi i sostoyaniye vosstanovleniya ne popadayut v publikuyemuyu diagnostiku. Algoritm ozhidayemogo khyesha, prikladnoj format obyyekta, svyazj s obsjhim khranilisjhem FUM i tochnyiye ogranicheniya fiksiruyutsya do zavisimogo resheniya.

Programma budusjhikh izolirovannyikh RED/GREEN proveryayet parametryi biblioteki, fakticheskoye primeneniye flaga I2P-torrent, otkaz smeshannyikh/neprigodnyikh vkhodov, ogranicheniya, otmenu, perezapusk, vosstanovleniye, identichnostj, povrezhdeniye obyyekta i otsutstviye klyuchej v diagnostike. Kontroliruyemyiye fiksturyi i nablyudeniye vneshnikh popyitok otlichayut zapros k lokaljnomu SAM ot zapresjhyonnogo clearnet. Dlya obsjhego SAM-rasshireniya otdeljno predusmotrenyi fragmentaciya strok, perekhod k binarnomu potoku i zhiznennyij cikl soyedinenij; eti testyi ne podmenyayut priyomku libtorrent i ne trebuyut novogo obsjhego kliyenta v pervom sreze.

Zhivaya sovmestimostj v budusjhem proveryayetsya otdeljnyim razreshyonnyim etapom na i2pd 2.61.0 (635b013a612ff47278ef02acf8580a28e10e26c5) i Java I2P 2.13.0 (9134f808337b401e8e53c73734c81fab04280c9d), nazvannyikh koordinatorskim materialom. Eto istochnikovyiye oporyi plana, a ne vyipolnennaya zdesj proverka. Odin i tot zhe otkryityij obyyekt, proverennyij khyesh, vkhodyasjhij potok, otmena i perezapusk dayut ogranichennoye svideteljstvo vyibrannogo profilya, ne obesjhaniye absolyutnoj anonimnosti.

Budusjhij profilj otdelyayet izderzhki Swift-adaptera i libtorrent ot marshrutizatora i seti: CPU v pokoye, pamyatj, ustanovleniye sessii/soyedineniya, pervyij bajt, poleznaya peredacha, otmena i vosstanovleniye. Nuzhnaya optimizaciya obosnovyivayetsya izmereniyami i proveryayetsya povtorom togo zhe scenariya. Zerkalo fum-lab/libtorrent sozdano koordinatorom; dublikat ne sozdayotsya. Do ispoljzovaniya sveryayutsya realjnyiye bajtyi vyibrannogo OID, LICENSE/NOTICE i neobkhodimyij tranzitivnyij sostav vyibrannoj sborki; licenziya odnogo SAM-komponenta ne rasprostranyayetsya na vesj marshrutizator.

Tekusjhij rezuljtat ogranichen predmetnyim planom i programmoj priyomki. Kod, clone/fetch, registraciya zavisimostej, ustanovka marshrutizatora, setj, mobiljnaya upakovka i otdeljnaya native-zadacha etoj komandoj ne zapuskayutsya. Sokhranyayutsya obsjhij obyyom Torrent/Tor/I2P/Bitcoin i vse prezhniye kriterii 0183.

## Vyibor Torrent i licenzii pervogo profilya

Vyibrannaya libtorrent-rasterbar 2.1.1 (56ae8caba38bf154ffc210403cb23f91d0ecaa49) rasprostranyayetsya po BSD-3-Clause. Sobstvennyij tonkij Swift/C++-adapter ostayotsya pod CC0; eto ne menyayet licenzij vneshnikh komponentov. Pervyij profilj fiksiruyet WebTorrent=OFF. Yego vklyucheniye trebuyet otdeljnogo proverennogo zamyikaniya zavisimostej libdatachannel i uslovij MPL-2.0, a ne nasleduyet dopusk obyichnogo BitTorrent/I2P.

Budusjhaya vosproizvodimaya sborka sokhranyayet realjnyiye LICENSE/NOTICE vsekh neobkhodimyikh zavisimostej: Boost — BSL-1.0, try_signal — BSD-3-Clause, OpenSSL 3 — Apache-2.0. Sostav sveryayetsya po tochnyim vyibrannyim iskhodnikam i parametram sborki; spisok nazvanij licenzij sam po sebe ne zamenyayet takoj proverki. Vyibor i svedeniya o zerkale prinyatyi iz peredachi koordinatora cherez korenj, bez novoj setevoj proverki v dannom etape. Obsjhaya komanda 243 o zerkalirovanii sokhranyayetsya; obnovleniye trebovanij 0074 i 0075 vyipolnyayetsya kornem otdeljno.

## Istochniki

- [Otvet o vyibore Torrent, pervichnyiye voprosyi 238 i 244 i granicyi licenzij](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_21-56-09_MSK_уточнить-план-подключения-I2P/отчёт.md).

- [Prorabotka I2P i utochneniye vyibora libtorrent](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_21-56-09_MSK_уточнить-план-подключения-I2P/запрос.md).
- [Material koordinatora o podklyuchenii I2P](../integracii/I2P/podklyucheniye-I2P.md).

- [Iskhodnaya komanda i soderzhateljnyij otvet](https://github.com/fum-lab/fum/blob/6049110117aa2d46380422ff51e2e996f087ee90/Журнал/2026-09-11_01-07-38_MSK_запланировать-децентрализованные-сети/запрос.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:52:33 MSK -->
<!-- content-sha256: sha256:9c961033714b4bcacc58ebf7a46ac7a6cc076c04ece72995c2fdb02c23a0de5d -->
<!-- FUM-MD-RECENCY:END -->
