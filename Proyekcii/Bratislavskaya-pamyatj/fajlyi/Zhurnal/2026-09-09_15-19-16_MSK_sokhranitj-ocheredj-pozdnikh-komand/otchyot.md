# Otchyot 2026-09-09 15:19:16 MSK - Sokhranitj ocheredj pozdnikh komand

Ogranichennyij segment zavershyon, obsjhij adresnyij nabor — 77 uspeshnyikh testov, vklyuchaya 27 novyikh testov ocheredi. Realizovana ocheredj pozdnikh raw-komand: sokhraneniye nablyudyonnogo khvosta, dostavka s povtorom posle avarii, yavnaya obrabotka chelovecheskikh soobsjhenij, monotonnyiye resheniya o suzhenii/otzyive i proverka barjyera konkretnogo pokoleniya. Ispolneniye, primeneniye prinyatogo snimka i vesj0155 ostayutsya sleduyusjhim etapom. Baza segmenta — 6612aac2879582f4d14bd2304a8c959f86963628; rabota vedyotsya v sobstvennom raneye naznachennom dereve i fakticheskom symbolic ref. Odin read-only-recenzent proveryal kontraktyi i kod, ne menyaya rabocheye derevo.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Vesj adresnyij nabor | 92,354 s | Vneshnij v4-process; 77 testov, unittest soobsjhayet 92,227 s |
| Iskhodnyij profilj: 2 / 100 soobsjhenij | 0,095 / 783,945 s | Summa razdeljnyikh monotonic-stadij s tracemalloc |
| Posle uskoreniya: 2 / 100 soobsjhenij | 0,065 / 25,118 s | Te zhe iskhodnyiye i dostavlennyiye bajtyi; 35 / 1211 fsync |
| Tochnaya sokhrannostj proiskhozhdeniya i prezhnikh etapov | 0,574 s | Otdeljnyij v4-process |
| Obsjhij smoke | Ne zapuskalsya | Yavno isklyuchyon zadaniyem |

Dlya 100 soobsjhenij istochnik zanimayet 25 719 bajt, WAL — 259 348 bajt, konechnoye pokoleniye — 302. Podtverzhdayusjhij profilj sokhranil SHA-256 istochnika i normalizovannyikh dostavlennyikh raw-bajtov, razresheniya, pokoleniya i chislo sinkhronizacij v oboikh razmerakh. Lokaljnyiye UUID/puti/inode i polnyiye bajtyi barjyera ne obyyavlyayutsya vosproizvodimyimi mezhdu ocheredyami. Python heap peak: iskhodnyij 3 610 261 bajt, posle uskoreniya 3 855 648 bajt; eto ne RSS. Vlozhennoye vremya 1211 fsync — 0,126 / 0,100 s, ono ne skladyivayetsya s summoj stadij.

Uskoreniye ogranicheno pryamyim poiskom po proverennomu nomeru s polnyim sravneniyem ssyilki i zamenoj vtorogo smyislovogo razbora WAL na polnoye sravneniye iskhodnyikh bajtov plyus sobstvennyiye prirasjheniya. Pervichnyij razbor vsej cepochki sokhranyon. V etom scenarii vremya sokratilosj primerno v 31,2 raza; eto ne universaljnaya ocenka proizvoditeljnosti. Podtverzhdayusjhij process chastichno sovpal po vremeni s obsjhim adresnyim naborom, chto ne vyidayotsya za izolirovannyij benchmark sredyi. Iskhodniki podtverzhdayusjhego profilya proverenyi do i posle zamera; ikh tochnyiye SHA-256 sokhranenyi. Do uskoreniya ostavalsya izvestnyij RED metki pri chistom nablyudenii; ispravleniye usilivayet itogovuyu proverku i ne menyayet sravnivayemyiye raw-bajtyi.

Granica profilya: toljko processyi adresnyikh proverok i sinteticheskoj ocheredi. Vremya razrabotki, ozhidaniya recenzenta, commit/push i finaljnaya peredacha otdeljno ne izmeryalisj i ne skladyivayutsya s dliteljnostyami testov. FIFO i avtomaticheskogo handoff net.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                           | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------- | ------------ | --------- |
| [Kornevaya zadacha vkhoda] RED otsutstvuyusjhego protokola ocheredi                    | 0,125 s      | neuspeshno |
| [Kornevaya zadacha vkhoda] Pervyij povedencheskij progon ocheredi                     | 0,138 s      | neuspeshno |
| [Kornevaya zadacha vkhoda] Povedeniye posle ispravleniya fizicheskogo puti fiksturyi   | 0,177 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] RED gonok i povrezhdenij ocheredi                         | 0,449 s      | neuspeshno |
| [Kornevaya zadacha vkhoda] GREEN gonok i avarijnyikh granic                          | 0,339 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] RED sokhraneniya nachaljnogo khvosta i oblasti resheniya      | 0,254 s      | neuspeshno |
| [Kornevaya zadacha vkhoda] GREEN nachaljnogo khvosta i tochnogo resheniya               | 0,397 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] Plan russkikh sobstvennyikh imyon ocheredi                   | 0,086 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] Utochnyonnyij plan grammaticheskikh imyon                     | 0,087 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] 26 testov ocheredi posle perevoda i avarijnyikh dopolnenij | 0,424 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] Profilj ocheredi 2 i 100 soobsjhenij                       | 784,19 s     | uspeshno   |
| [Kornevaya zadacha vkhoda] RED poyavleniya metki pri chistom nablyudenii               | 0,294 s      | neuspeshno |
| [Kornevaya zadacha vkhoda] GREEN poslednej avarijnoj granicyi i uskoreniya           | 0,383 s      | uspeshno   |
| [Kornevaya zadacha vkhoda] Podtverzhdayusjhij profilj s tochnoj sverkoj bajtov          | 25,332 s     | uspeshno   |
| [Kornevaya zadacha vkhoda] Obsjhij adresnyij nabor vkhoda materializacii i ocheredi     | 92,354 s     | uspeshno   |
| [Kornevaya zadacha vkhoda] Tochnoye proiskhozhdeniye imena i sokhrannostj prezhnikh etapov | 0,574 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 905,603 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:640cf5780418b5fad0f8dbba49cc57df5b9ae68e9adef5391abfece2f243b3e4.
Kontekst soderzhimogo: sha256:7776c605a639d860d13d3889d9dbf486841798ce15b11792c66038e3b5d7acba.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Pervyij zapusk v etoj novoj papke yavno vklyuchil `--приёмочные-раунды`; vse zapisi imeyut v4, iskhodnyij poryadok 1 i otsutstviye perekhoda skhemyi. Pervonachaljnyij RED — otsutstviye modulya. Sleduyusjhij progon vyiyavil nepraviljnuyu fiksturu puti macOS: vremennyij putj /var prokhodil cherez symlink; fikstura stala ispoljzovatj fizicheskij resolve, ogranicheniye koda ne oslablyalosj. Zatem devyatj osnovnyikh scenariyev dali GREEN.

Adresnyiye povedencheskiye RED vyiyavili propusk dopisannogo vo vremya callback soobsjheniya, povrezhdyonnoj obolochki i podmenyi imenovannogo WAL. Ispravleniya proverenyi povtorno. Sleduyusjhiye RED recenzenta dokazali poteryu khvosta pri sozdanii, perenos resheniya mezhdu ocheredyami i propusk payload bez tipa. Ikh zakryili sokhraneniyem vsekh uzhe nablyudyonnyikh bajtov v nachaljnom sobyitii, rasshireniyem ssyilki na oblastj ocheredi/snimka/vkhoda i strogoj proverkoj raw. Otdeljnyij RED zafiksiroval poyavleniye pending pri chistom nablyudenii. Syiryiye zapisi etikh otkazov ne perepisyivalisj. Finaljnaya proverka metki, inventarya, rezhima i privyazki vyipolnena do vozvrata i posle poslednego polnogo chteniya WAL; vse 27 testov dali GREEN. Obsjhij adresnyij nabor zatem proshyol celikom. Itogovoye nezavisimoye read-only-revjyu blokerov ne obnaruzhilo.

Avarijnyiye testyi proveryayut kazhdyij iz chetyiryokh fsync, ostanovku dochernego processa na chetyiryokh granicakh, ENOSPC v seredine sobyitiya, korotkuyu i nulevuyu zapisj, zamenu pending bez udaleniya chuzhogo fajla, povrezhdeniye cepochki, nevernyij kursor i ssyilku. Otdeljno podtverzhdenyi povtor dostavki posle perezapuska, partial→complete rovno odin raz, sostavnoye raw-soobsjheniye, HookPrompt s «ostanovisj», yavnaya pozdnyaya otmena, ustarevshij barjyer i otsutstviye rasshireniya polnomochij pri podtverzhdenii.

## Resheniya i ogranicheniya

[Kontrakt](../../Instrumentyi/fum-snimki-indeksa/ocheredj.md) fiksiruyet Python API i yavnuyu doverennuyu granicu. Nachaljnyij proverennyij vkhod predostavlyayetsya vyizyivayusjhim sloyem; ocheredj sama ne vyipolnyayet povtornuyu Git-priyomku. Raw JSONL chitayetsya do sklejki chastej, vne publichnogo checkout. Zhivoj callback otvechayet na svezhij nonce i dostavlyayet tipizirovannyiye resheniya; eto ne udostovereniye lichnosti ili dokazateljstvo zapuska hook. Neizvestnoye proiskhozhdeniye, nezakonchennyij khvost i poterya kanala zapresjhayut barjyer. Poluchennaya runtime-otmena bez zakonchennoj raw-stroki dolzhna nemedlenno blokirovatj vyizyivayusjhij sloj.

WAL, flock, pending i povtornyiye proverki fajlov dayut dolgovechnyij serializovannyij poryadok. Proverka barjyera — nablyudeniye konkretnogo pokoleniya pod blokirovkoj, bez atomarnogo prava posleduyusjhego ispolneniya. Posleduyusjhij otzyiv mozhet poyavitjsya posle vozvrata API; ispolniteljnyij protokol zdesj otsutstvuyet. Polnostjyu neispravnoye khranilisjhe ne pozvolyayet garantirovatj sokhraneniye fakta sboya: lyuboj neuspeshnyij vyizov prekrasjhayet rassmotreniye dejstvij. Polnyij otkat kataloga bez vneshnego yakorya i vrazhdebnyij process togo zhe UID vne protokola ne obyyavlyayutsya predotvrasjhyonnyimi. Net avtomaticheskogo remonta, sbrosa ili kompaktizacii.

Chistyij klassifikator importirovan iz razreshyonnogo commit 002bb953671fa82b2144e7ec506d4975df977e3c s tochnyim SHA-256 a3fdf3e04d9cb023489b60ecabe87428c652cfca92b6336f99a66bb55122fd23. Skopirovan toljko modulj; chuzhoj navyik ne prochitan i ne importirovan. Sobstvennyiye imena privedenyi k russkim lokaljnoj tokenovoj avtomatizaciyej posle prosmotra sukhogo plana; obsjhiye reyestryi i snimki ne menyalisj.

Obsjhaya read-only-proverka svyaznosti zavershilasj otkazom toljko po prezhnim prichinam: odna nevernaya sleduyusjhaya ssyilka zaprosa 11:39:26 i 282 ssyilki na otsutstvuyusjhij lokaljnyij `.obsidian/graph.json`. Sobstvennaya oblastj etikh oshibok ne soderzhit. [Granica proverki](materialyi/granica-svyaznosti.json) sokhranyayet kategorii i khyesh polnogo vyivoda. Chuzhaya navigaciya i poljzovateljskij graph ne ispravlyalisj. Zaklyuchiteljnyiye read-only-proverki svyaznosti, recency i exact diff vyipolnyayutsya kak samonablyudayusjhij dopusk kontroljnoj tochki po FUM-PRAVILO-000188 vne obyortki; oni ne podmenyayut zapisannyiye adresnyiye testyi.

## Oshibka otpravki predyidusjhego kommita

Posle kommita 6612aac2879582f4d14bd2304a8c959f86963628 v prezhnem segmente agent vruchnuyu perepechatal naznacheniye push i oshibochno ispoljzoval kirillicheskuyu `д` v suffikse. Obyichnyij push sozdal raneye otsutstvovavshij ref `refs/heads/codex/вход-снимка-индекса-01a07д3d` na etom OID. Zatem tot zhe tochnyij OID obyichnyim push otpravlen v praviljnyij `refs/heads/codex/вход-снимка-индекса-01a07d3d`; Git podtverdil perekhod 48c0a98d→6612aac. Toljko oshibochno sozdannyij ref udalyon s tochnoj lease na 6612aac2879582f4d14bd2304a8c959f86963628. Drugiye refs ne menyalisj, commit ostavalsya dostizhimyim v praviljnoj vetke.

Zavershayusjhij read-only-audit cherez fakticheskij `git symbolic-ref HEAD` i udalyonnyij spisok podtverdil: praviljnaya vetka soderzhit exact6612aac, oshibochnyij ref otsutstvuyet, rabocheye derevo chistoye. Oshibka i korrekciya byili soobsjhenyi koordinatoru. Etot interval proizoshyol posle prezhnego commit i ne vklyuchyon zadnim chislom v staryij zakryityij otchyot. Zdesj on sokhranyon po novomu yavnomu porucheniyu. Vo vsekh novyikh Git-komandakh naznacheniye beryotsya iz fakticheskogo symbolic ref; vruchnuyu perepechatannyiye istoricheskiye refs vyishe yavlyayutsya toljko opisaniyem proisshestviya.

## Proiskhozhdeniye i granica fiksacii

Doslovnaya komanda vosstanovlena iz zavershyonnogo raw JSONL tekusjhej runtime-zadachi 01a08592-8a01-7701-9386-78a0ae0553d7: toljko function_call_output s obolochkoj codex_delegation i iskhodnyim input. Eto yavnoye delegirovaniye kornya 01a07d3d-d376-7ad2-aafc-67e4c25a67eb, a ne pritvornoye response_item cheloveka. Syiryiye JSONL ostalisj vne publichnogo checkout. Posle vosstanovleniya tekusjhiye HEAD, symbolic ref i AGENTS perechitanyi, marshrut dialog vklyuchyon; drugoj pisatelj etogo dereva po dostupnyim svideteljstvam otsutstvoval.

V pervom update soglasovan kompaktnyij kontrakt: syiryiye pozicii i proiskhozhdeniye sokhranyayutsya otdeljno ot tipizirovannogo resheniya; barjyer svyazyivayet UUID snimka, podtverzhdeniya i pokoleniye; novoye sobyitiye delayet staryij barjyer ustarevshim. Dva vyizova start snachala neverno peredali label/stem i poluchili otkaz do zapisi; tretij korrektno sozdal novuyu papku. Predyidusjhiye otchyotyi i istorii ne vozobnovlyalisj.

Sobstvennaya kontroljnaya tochka ostavlyayet v4-otchyot otkryityim dlya integracii. Obsjhiye pravila, planyi, reyestryi i obyortka ne izmenenyi; polnyij smoke i integraciya ostayutsya u koordinatora. Tochnaya fiksaciya, ordinary push i read-only-proverka OID vyipolnyayutsya posle zaversheniya dokumentacii; ikh vremya ne vkhodit v profilj.

## Istochniki

- [Doslovnaya komanda](zapros.md).
- [Kontrakt ocheredi](../../Instrumentyi/fum-snimki-indeksa/ocheredj.md).
- [Proiskhozhdeniye importirovannogo modulya](materialyi/proiskhozhdeniye-modulya.json).
- [Karta sobstvennyikh imyon](materialyi/karta-imyon.json).
- [Iskhodnyij profilj](materialyi/profilj-ocheredi.json) i [podtverzhdayusjhij profilj](materialyi/profilj-podtverzhdeniya.json).
- [Itog nezavisimogo revjyu](materialyi/nezavisimoye-revjyu.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:53:47 MSK -->
<!-- content-sha256: sha256:d82b4776684ad6459c84ad2a6b0a63ab3521c56f41d6f8e841061d9e4c6042a3 -->
<!-- FUM-MD-RECENCY:END -->
