# Otchyot 2026-09-14 14:19:35 MSK - Najti dopolniteljnoye finansirovaniye rabotyi FUM

Podgotovlenyi desyatj prioritetnyikh vozmozhnostej i proyekt predlozheniya podderzhki s razdeljnoj smetoj tekusjhej rabotyi i celevogo Mac Studio. Susjhestvuyusjhij reyestr rasshiren do 30 organizacij i 38 variantov. Ni odna novaya programma ne obyyavlena polnostjyu dostupnoj FUM; sredstva ne poluchenyi. Eto soderzhateljnyij promezhutochnyij rezuljtat s adresnyimi proverkami, bez polnoj priyomki novogo pokoleniya dokumentacionnogo prototipa.

## Rezuljtat i proiskhozhdeniye

- Baza etapa: `6c9babdd3663ff0112283b89a361068727825da6`; vetka `refs/heads/codex/реестр-организаций-поддержки-01a0904a`. Fizicheskij korenj sobstvennogo worktree proveren i sokhranyon v privatnoj zapisi dopuska. Yedinstvennyij pisatelj — korenj; deti vyipolnyali toljko chteniye.
- Nativnyij UUID kornya perechitan iz sredyi: `01a0904a-f98e-70b1-8ea6-a0202ff4de7a`; kontekst JSONL podtverzhdayet `gpt-6-astra`, `ultra`.
- Predyidusjhiye dva issledovaniya i 16 kartochek sokhranenyi; tretij korpus soderzhit 14 novyikh kandidatov. Yuridicheskij profilj ne menyalsya. Pervichnyiye novyiye svideteljstva — 23, posle razdeleniya dvukh pereskazov Boosty vsego 25, v tom chisle yavno oboznachennyiye pereskazyi otrisovannogo teksta i nedostupnogo povtornogo PDF.
- Rosmolodyozhj postavlena pervoj po srochnosti: 15.09.2026 12:00 MSK. Vozrast, grazhdanstvo, socialjnyij rezuljtat i dopustimostj raskhodov ne podrazumevayutsya. Oblachnyiye bonusyi, kanalyi pozhertvovanij, denezhnyiye zajmyi i dolevoye finansirovaniye otdelenyi.
- Utochneniye o kompjyutere vneseno v trebovaniye i smetu: topovyij M5 Ultra, 512 GiB; SSD i polnaya cena neizvestnyi. Anons Apple podtverzhdyon pryamyim chteniyem. Bazovaya cena ne ispoljzuyetsya kak cena celevoj stancii.
- Utochneniye o vsekh formakh finansirovaniya sokhraneno doslovno. CC0 zakrepleno kak usloviye FUM, a ne kak uzhe soglasovannoye usloviye fonda ili investora.
- RO-revjyu ne obnaruzhilo oshibok v summakh i srokakh proverennyikh oblakov i FRII; utochnilo razlichiye isklyuchyonnoj uslugi i proyekta igrovogo khostinga u Timeweb. Ispravleniye dobavleno shtatnoj komandoj `обновить`: sukhoj plan, zatem primeneniye po ozhidayemomu khyeshu; prezhneye nablyudeniye sokhraneno.

## Profilj vremeni vyipolneniya

| Stadiya                                    | Dliteljnostj             | Granicyi i sposob izmereniya                                                  |
| ----------------------------------------- | ------------------------ | --------------------------------------------------------------------------- |
| Vosstanovleniye, issledovaniye i podgotovka | ne izmereno              | S nachala etapa 14.09.2026 14:19:35 MSK; paralleljnyiye chteniya ne skladyivayutsya |
| Arkhivirovaniye istochnikov                  | ne izmereno              | Nablyudalisj otdeljnyiye processyi, polnogo monotonnogo intervala net           |
| Adresnyiye proverki                         | po tablice zapuskov nizhe | Monotonnyiye izmereniya obyazateljnoj obyortki                                   |
| Standartnyij smoke-check i proyekciya        | ne zapuskalisj           | Pryamoye ogranicheniye porucheniya: tyazhyolyiye proverki poka ne zapuskatj            |

Granica profilya: etap ot 14.09.2026 14:19:35 MSK do tekusjhej kontroljnoj tochki; FIFO i avtomaticheskij handoff ne primenyalisj. Finaljnaya otpravka kommita vne izmereniya. Pervyij profilj reyestra: semj povtorov, maksimum 35,512541 ms. Posle redakcionnoj ochistki aktualjnyikh vkhodov: semj povtorov, maksimum 33,12975 ms; raznyiye khyeshi vkhodov ne ispoljzuyutsya dlya zayavleniya uskoreniya. Vlozhennyiye intervalyi ne summiruyutsya s polnyim povtorom.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                      | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj] RED: prezhnyaya privyazka proverki k iskhodnomu korpusu                | 1,108 s      | neuspeshno |
| [Korenj] GREEN: korpus, istoriya, dopusk i granicyi reyestra                  | 1,129 s      | uspeshno   |
| [Korenj] Profilj aktualjnogo korpusa: semj povtorov                        | 0,324 s      | uspeshno   |
| [Korenj] Vosproizvodimostj aktualjnogo vyipuska reyestra                     | 0,132 s      | uspeshno   |
| [Korenj] Publikacionnaya proverka mashinnyikh lokaljnyikh putej                  | 26,439 s     | neuspeshno |
| [Korenj] Diagnostika otkaza proverki putej bez razreshyonnyikh strok           | 25,862 s     | neuspeshno |
| [Korenj] Proverka publikacionnyikh putej posle redakcionnoj ochistki          | 26,076 s     | uspeshno   |
| [Korenj] Finaljnyij profilj korpusa posle smyislovogo revjyu                  | 0,283 s      | uspeshno   |
| [Korenj] Proverka tochnogo diff kontroljnoj tochki                           | 0,046 s      | uspeshno   |
| [Korenj] Profilj ochistki do rasshireniya nabora sluzhebnyikh zagolovkov         | 2,391 s      | uspeshno   |
| [Korenj] RED: ochistka adresa i trassirovki HTTP-zaprosa                    | 0,112 s      | neuspeshno |
| [Korenj] RED: sluzhebnyij token v konfiguracii stranicyi                      | 0,13 s       | neuspeshno |
| [Korenj] GREEN: avtonomnyij kontur arkhivatora i adresnaya ochistka            | 0,55 s       | uspeshno   |
| [Korenj] Profilj ochistki posle ispravleniya na prezhnikh vkhodakh               | 2,492 s      | uspeshno   |
| [Korenj] Itogovyiye adresnyiye proverki reyestra, svideteljstv i ochistki        | 1,378 s      | uspeshno   |
| [Korenj] Profilj okonchateljnyikh dannyikh reyestra                              | 0,329 s      | uspeshno   |
| [Korenj] Proverka tochnogo indeksa kontroljnoj tochki                        | 0,045 s      | neuspeshno |
| [Korenj] Proverka indeksa s sokhraneniyem probeljnyikh bajtov syiryikh istochnikov | 0,035 s      | uspeshno   |
| [Korenj] Okonchateljnaya publikacionnaya proverka putej                       | 26,457 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 115,318 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Staraya integracionnaya proverka ozhidala prezhnij korpus i dala vosproizvodimyij RED: nesovpadeniye khyesha issledovaniya. Ispravlena privyazka testa i profiljnogo scenariya k aktualjnomu korpusu; osnovnoj ispolnyayemyij kod reyestra ne menyalsya. GREEN: 16 testov. Proveryayutsya sokhrannostj dvukh prezhnikh issledovanij, polnota korpusa, neizvestnostj yuridicheskoj registracii i otsutstviye vyimyishlennogo dopuska. Otdeljnaya shtatnaya komanda podtverdila vosproizvodimostj vyipuska.

Itogovyij profilj okonchateljnyikh dannyikh soderzhit semj povtorov, maksimum 36,385875 ms. Profilj okhvatyivayet te zhe operacii generatora na aktualjnyikh vkhodakh: chteniye, proverku svideteljstv, ocenku i render. Zamena puti vkhoda ne izmenyayet algoritm; izmerennyiye zatratyi ne obosnovyivayut dopolniteljnuyu optimizaciyu. Uskoreniye otnositeljno prezhnego korpusa iz 16 organizacij ne zayavlyayetsya. Khyeshi koda, vkhodov, rezuljtatov i usloviya sokhranenyi v profile.

Proverka publikacionnyikh putej snachala otklonila sokrasjheniya denezhnyikh periodov; oni razvyornutyi slovami bez izmeneniya uslovij, povtornaya proverka uspeshna. Pravila skanera i isklyucheniya ne menyalisj. Polnyij indeks pokazal toljko probeljnyiye osobennosti syiryikh HTML i izvlechyonnogo teksta vneshnikh istochnikov. Ikh bajtyi sokhranenyi po protokolu arkhivacii; povtornaya proverka indeksa s isklyucheniyem toljko `Источники/URL/**/response.body.html` i `Источники/URL/**/извлечённый-текст.txt` uspeshna. Kanonicheskiye dokumentyi, dannyiye i kod proverenyi bez isklyucheniya. Okonchateljnaya proverka publikacionnyikh putej uspeshna.

Predfinaljnyij standartnyij smoke-check, zakryitiye mashinnogo otchyota i peresborka proyekcii ne vyipolnyalisj. Sokhranyonnoye pokoleniye `Proyekcii/**` otnositsya k prinyatomu etapu 6c9babdd3663ff0112283b89a361068727825da6, yego plan — `146eade68c349163f8bb42fd1e9d9170204694dd57053cb6be9c87b4007a1fd2`; ono otstayot ot novyikh kanonicheskikh fajlov. Prezhnij uspekh ne ispoljzuyetsya dlya priyomki nyineshnego snimka. Kontroljnaya tochka sokhranyayet otkryityij otchyot i perechenj ostatka. Pervaya zaklyuchiteljnaya proverka svyaznosti vyiyavila nedostatochno polnyij perechenj zatronutyikh katalogov i otsutstviye tochnogo imeni navyika vremeni v razdele instrumentov; perechenj i imya dopolnenyi. Zaklyuchiteljnyiye proverki kontroljnoj tochki vyipolnyayutsya vne tablicyi zapuskov po uzkomu isklyucheniyu pravila 000188.

## Resheniya i ogranicheniya

Pervyij konechnyij issledovateljskij rezuljtat podgotovlen. Daljnejshij predmetnyij dopusk zavisit ot dannyikh zayavitelya. V svoyej zadache zadano odno utochneniye: «Dlya otbora dostupnyikh programm utochnite, pozhalujsta: kto smozhet poluchatj finansirovaniye FUM — fizlico, samozanyatyij, IP ili organizaciya; region v Rossii; popadayet li zayavitelj v vozrast 14–35 let? Dokumentyi i bankovskiye rekvizityi sejchas ne nuzhnyi». Na moment podgotovki otveta dannyikh ne byilo; status ostavlen neizvestnyim, vopros ne dublirovalsya koordinatorom.

Ostatok: sveritj svedeniya poluchatelya, zapolnitj fakticheskij mesyachnyij byudzhet i polnuyu cenu kompjyutera, vyibratj podkhodyasjhiye dogovornyiye usloviya s sokhraneniyem CC0. Polnaya priyomka dokumentacionnogo pokoleniya ozhidayet snyatiya tekusjhego ogranicheniya tyazhyolyikh proverok. Nikakikh zayavok, pisem, registracii, prinyatiya uslovij, finansovyikh obyazateljstv i platezhej ne byilo. Osnovnaya realizaciya konteksta drugoj zadachi ne zatragivalasj.

Povtornoye RO-revjyu obnaruzhilo X-Forwarded-For i Trace-Id v zagolovkakh Sponsr i izmenyayemyij websocket.token v dvukh HTML-obolochkakh Boosty. Znacheniya ne vyivodilisj i ne publikovalisj. Arkhivator teperj ochisjhayet eti polya; otdeljnyiye RED/GREEN podtverzhdenyi, vesj avtonomnyij kontur arkhivatora — 57 testov. Tri snimka pereustanovlenyi shtatnyimi build_snapshot/install_snapshot bez seti s sokhraneniyem vlozhennyikh svideteljstv. Pereskazyi dvukh dogovorov Boosty razdelenyi po istochnikam; prezhniye svodnyiye bajtyi sokhranenyi s poyasneniyem proiskhozhdeniya.

Profilj ochistki na odinakovyikh 26 sokhranyonnyikh HTML i zagolovkakh: semj povtorov do i posle, maksimumyi 334,369167 i 345,147125 ms. Uskoreniye ne zayavlyayetsya; eti izmereniya ne obosnovyivayut dopolniteljnuyu optimizaciyu, bezopasnostj i sokhraneniye soderzhateljnyikh bajtov podtverzhdenyi testami. Fiksiruyutsya khyeshi koda i vkhodov oboikh zamerov.

Arkhivator sokhranil dostupnyiye HTML i dva PDF s postranichnyim izvlecheniyem. PDF Rosmolodyozhi ne poluchen povtorno za 15 sekund; Cloud.ru — tajm-aut arkhivacii 35 sekund. U roditeljskogo URL NLnet Restack susjhestvovali uzhe sokhranyonnyiye docherniye URL, i obsjhij HTML-vkhod bezopasno otkazal iz-za otsutstviya doverennogo `source-url.txt` u roditelya; docherniye snimki ne podmenyalisj. Dlya etikh istochnikov sokhranenyi chestno oboznachennyiye svideteljstva chteniya issledovatelej. U PDF CloudTips izvlecheniye predupredilo o nevernyikh ukazatelyakh obyyektov, no poluchilo 11 stranic; eto otmecheno kak ogranicheniye izvlecheniya.

## Istochniki

- [Iskhodnyij zapros i pozdniye utochneniya](zapros.md).
- [Soderzhateljnyiye otvetyi s proiskhozhdeniyem](materialyi/soderzhateljnyiye-otvetyi.json).
- [Prioritetyi](../../Planirovaniye/finansirovaniye-i-resursyi/prioritetyi.md).
- [Proyekt predlozheniya i nedostayusjhiye dannyiye](../../Planirovaniye/finansirovaniye-i-resursyi/proyekt-predlozheniya-podderzhki.md).
- [Polnyij reyestr](../../Planirovaniye/finansirovaniye-i-resursyi/README.md).
- [Karta migracii i svideteljstva](materialyi/migraciya-korpusa.json).
- [Ispravleniye Timeweb](materialyi/utochneniye-timeweb.json).
- [Pervyij profilj reyestra](materialyi/profilj-reyestra.json).
- [Promezhutochnyij profilj posle redakcii](materialyi/profilj-reyestra-posle-redakcii.json).
- [Profilj okonchateljnyikh dannyikh](materialyi/profilj-reyestra-itog.json).
- [Profilj ochistki do](materialyi/profilj-zagolovkov-do.json) i [posle](materialyi/profilj-zagolovkov-posle.json).
- [Ochistka tryokh novyikh snimkov](materialyi/ochistka-novyikh-snimkov.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 15:03:14 MSK -->
<!-- content-sha256: sha256:f7031bcb0fc6c377e7bb86ba2bc99c30fe41e36027d922065ac1c8be06b8d89c -->
<!-- FUM-MD-RECENCY:END -->
