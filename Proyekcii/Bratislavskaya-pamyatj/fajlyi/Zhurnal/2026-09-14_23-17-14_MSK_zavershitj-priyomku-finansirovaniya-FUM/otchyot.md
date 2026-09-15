# Otchyot 2026-09-14 23:17:14 MSK - Zavershitj priyomku finansirovaniya FUM

Sokhranenyi utochneniya o vsekh formakh podderzhki pri CC0 i celevom Mac Studio. Podgotovlennyiye 30 organizacij, 38 variantov, desyatj prioritetov, zagotovka smetyi i predlozheniye ostayutsya dejstvuyusjhim predmetnyim rezuljtatom d2ff29cba01323eb52f3ba99307bce1d2fadecdc. Novaya komanda snyala prezhnyuyu otsrochku tyazhyolyikh proverok; pri podgotovke vyiyavlena otdeljnaya fakticheskaya zavisimostj ot obsjhego ispravleniya skanera i bezopasnogo pereimenovatelya, kotoroye prinimayet paralleljnaya zadacha 0165/0173.

Adresnyij audit obnaruzhil chrezmernuyu ochistku pokhozhikh HTML-atributov. Chetyire otricateljnyikh primera vosproizveli izmeneniye publichnogo tokena pri `data-id`, inom registre znacheniya i tekste vnutri kavyichek. Raspoznavaniye ogranicheno polnocennyimi atributami i tochnyim znacheniyem `app-config`; 57 testov arkhivatora prokhodyat. Novyij test poluchil russkoye imya i parametr. Profilj teperj prinimayet yavnoye obyyedineniye neskoljkikh manifestov, sokhranyayet prezhnij vkhod po umolchaniyu i ne vklyuchayet PDF v HTML-izmereniye.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Vosstanovleniye i soderzhateljnaya rabota | ne izmereno | Prochitanyi rodnoj JSONL, dejstvuyusjhiye pravila, HEAD/ref i iskhodniki; skvoznoj tajmer ne ustanavlivalsya. |
| Adresnyiye proverki | mashinnyiye zapisi nizhe | Kazhdyij pryamoj process izmeren obyazateljnoj obyortkoj; vnutrenniye testyi ne summiruyutsya povtorno. |
| Profilj ochistki | do 390,210334 ms do; 391,244667 ms posle | Semj prokhodov po tem zhe 29 HTML i zagolovkam, zagruzhennyim v pamyatj. Setj, chteniye s diska i start Python vne intervala. |
| Polnyij profilj i finaljnaya proyekciya | ne vyipolnyalisj | Ozhidayetsya prinyataya obsjhaya postavka 0165/0173. |
| Kommit i tochnyij push | ne izmereno | Sostoyaniye dostavki podtverzhdayetsya otdeljno posle fiksacii; prezhnij FIFO ne ispoljzuyetsya. |

Granica profilya: ot pervogo adresnogo vyizova do poslednej okhvachennoj zapisi; mashinnyij sbor ostayotsya otkryityim. Zaklyuchiteljnaya read-only-proverka kontroljnoj tochki vyipolnyayetsya posle predprosmotra po uzkomu isklyucheniyu i ne vkhodit v etu summu. Sravneniye khyeshej vkhodov sokhraneno v [dvukh profilyakh](materialyi/); rabochaya sreda — macOS arm64, Python 3.14.7. Pered izmereniyami nablyudalisj load 3,81 / 3,63 / 4,64 i 87% svobodnoj pamyati po memory_pressure; paralleljnaya zadacha mogla menyatj nagruzku. Eto nablyudeniya dliteljnosti, ne kontroliruyemoye dokazateljstvo uskoreniya. Razlichiya ne obosnovyivayut dopolniteljnoj optimizacii; realizaciya sokhranena radi proverennoj tochnosti.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                          | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------ | ------------ | --------- |
| [Korenj] Proveritj vyibor rasshirennogo vkhoda profilya do realizacii              | 0,079 s      | neuspeshno |
| [Korenj] Proveritj ostatok obyyavlenij pered ispravleniyem                       | 4,288 s      | neuspeshno |
| [Korenj] Zafiksirovatj otricateljnyiye sluchai konfiguracii do ispravleniya        | 0,122 s      | neuspeshno |
| [Korenj] Izmeritj ochistku rasshirennogo nabora do ispravleniya                   | 2,826 s      | uspeshno   |
| [Korenj] Proveritj tochnuyu granicu konfiguracii i arkhivirovaniye                 | 0,494 s      | uspeshno   |
| [Korenj] Izmeritj ochistku togo zhe rasshirennogo nabora posle ispravleniya        | 2,816 s      | uspeshno   |
| [Korenj] Sveritj ostatok s prinyatyim bazovyim inventaryom bez dopuska rosta       | 4,495 s      | neuspeshno |
| [Korenj] Lokalizovatj raskhozhdeniye inventarya otnositeljno iskhodnoj bazyi vetki   | 5,033 s      | neuspeshno |
| [Korenj] Sveritj kanonicheskij inventarj bazyi s isklyucheniyem proizvodnoj oblasti | 4,683 s      | neuspeshno |
| [Korenj] Vosstanovitj vesj bazovyij inventarj neposredstvenno iz obyyektov Git   | 8,48 s       | neuspeshno |
| [Korenj] Vyidelitj sobstvennyij prirost poverkh otdeljno negotovoj bazyi           | 8,867 s      | neuspeshno |
| [Korenj] Proveritj sokhranyonnyij vyipusk finansirovaniya na iskhodnoj date          | 0,136 s      | uspeshno   |
| [Korenj] Proveritj publikacionnuyu chistotu kontroljnoj tochki                    | 24,928 s     | uspeshno   |
| [Korenj] Podtverditj tozhdestvennostj vkhodov dvukh profilej                      | 0,028 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 67,275 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Zaklyuchiteljnaya proverka kontroljnoj tochki potrebovala tochnuyu stroku `Граница профиля:` posle tablicyi; formulirovka ispravlena. Etot formatnyij otkaz i yego povtor nakhodyatsya vne mashinnoj granicyi po pravilu zaklyuchiteljnoj svyaznosti.

- Pervyij vyizov profilya s novyimi flagami zavershilsya ozhidayemyim otkazom; posle dobavleniya vkhodnogo spiska obrabotanyi 29 snimkov. Chetyire otricateljnyikh primera ochistki snachala otkazali, zatem vesj arkhivator proshyol 57 testov. Vse iskhodyi sokhranenyi bez svorachivaniya povtorov.
- Proverka ostatka otkazala. Pervichnaya chastnaya rekonstrukciya oshibochno vklyuchila izmenyonnyiye fajlyi proyekcii i dala zavyishennoye chislo 43890; eta ocenka otozvana. Nezavisimoye chteniye vsekh primenimyikh fajlov iskhodnoj bazyi 73c52866e565061b48ee67e164d5d178c5c8d8cd neposredstvenno iz Git dayot staryim skanerom 43606 protiv sokhranyonnyikh 43163. Eto ne razreshayet obnovleniye snimka. Koordinator podtverdil obsjhuyu zavisimostj ot 0165/0173.
- Tekusjhij staryij skaner vidit 43674 zapisi: sobstvennyij prirost otnositeljno prochitannoj bazyi — 68. On sosredotochen v tryokh fajlakh; obyazateljnyiye HTMLParser.handle_starttag/handle_endtag trebuyut vneshnego kontrakta, ostaljnyiye imena podgotovlenyi k bezopasnomu perevodu posle novoj postavki. Schyotchik drugoj vetki ne perenositsya na etu.
- Sopostavleniye tekusjhikh profilej podtverzhdayet odinakovyiye vkhodnyiye bajtyi i idempotentnostj uzhe ochisjhennyikh snimkov. Syiryiye istochniki i usloviya finansirovaniya v etom etape ne redaktirovalisj.

## Resheniya i ogranicheniya

- Po komande o vozobnovlenii vyipolnyayetsya priyomka reyestra, smetyi i predlozheniya. Po posleduyusjhemu utochneniyu obsjhij skaner povtorno ne razrabatyivayetsya; massovoye pereimenovaniye zhdyot proverennoj postavki i yeyo tochnoj granicyi integracii.
- 30 organizacij i 38 variantov ne oznachayut polucheniye sredstv ili dopusk zayavitelya. Dannyiye zayavitelya nuzhnyi dlya posleduyusjhego obrasjheniya; ikh otsutstviye ne podmenyayet tekhnicheskuyu prichinu ozhidaniya priyomki.
- Celevoj Mac ostayotsya otdeljnoj kapitaljnoj potrebnostjyu: topovyij M5 Ultra, 512 GiB po formulirovke poljzovatelya; SSD i polnaya cena neizvestnyi. Zayom, investicii, grant, gosudarstvennaya pomosjhj i pozhertvovaniye rassmatrivayutsya otdeljno pri sokhranenii CC0.
- Obrasjheniya, registracii, podachi, finansovyiye operacii i izmeneniye licenzii ne vyipolnyalisj. Dochernij ispolnitelj toljko chital; tekusjhij korenj ostayotsya yedinstvennyim pisatelem etogo dereva.
- Polnaya priyomka i aktualjnoye pokoleniye poka ne zayavlyayutsya. Soderzhateljnaya kontroljnaya tochka sokhranyayet proverennyiye ispravleniya i tochnyij nezavershyonnyij obyyom; ona ne zamenyayet polnyij profilj.

- Susjhestvuyusjhaya proyekciya sokhranena bez izmeneniya: proverennyij vkhod — etap 6c9babdd3663ff0112283b89a361068727825da6, khyesh plana `sha256:146eade68c349163f8bb42fd1e9d9170204694dd57053cb6be9c87b4007a1fd2`. Ona otstayot ot kanonicheskogo d2ff i nastoyasjhej kontroljnoj tochki.
- Dlya samostoyateljnogo defekta chrezmernoj ochistki zaproshen ID u obsjhego vladeljca; dlya povtorov nepolnoj ochistki zagolovkov i tela zaproshenyi lokaljnyiye nomera FUM-SBOJ-0020 i FUM-SBOJ-0081. Nomera ne naznachenyi po dogadke. Pervichnyiye faktyi, RED/GREEN i mera sokhranenyi; registraciya kartochek vkhodit v ostatok priyomki.

## Istochniki

- [Komandyi i proiskhozhdeniye tekusjhego etapa](zapros.md).
- [Predyidusjhij predmetnyij rezuljtat](../2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/otchyot.md).
- [Desyatj prioritetov](../../Planirovaniye/finansirovaniye-i-resursyi/prioritetyi.md), [smeta i predlozheniye](../../Planirovaniye/finansirovaniye-i-resursyi/proyekt-predlozheniya-podderzhki.md).
- [Sobstvennyij prirost obyyavlenij](materialyi/sobstvennyij-prirost.json), [tochnyiye devyatj iskhodnikov i podgotovka perevoda](materialyi/podgotovka-perevoda.json).
- [Iskhodnyij profilj ochistki](materialyi/profilj-ochistki-do.json), [profilj posle ispravleniya](materialyi/profilj-ochistki-posle.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 23:36:54 MSK -->
<!-- content-sha256: sha256:448a64761603880c3b56d06ba63b6fe3f2a6a215ce1e7c2ebd13061703ede855 -->
<!-- FUM-MD-RECENCY:END -->
