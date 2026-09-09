# Otchyot 2026-09-09 11:52:29 MSK - Zasjhititj sokhranyonnyiye obyazateljstva zadachi

Realizovana lokaljnaya proverka obyazateljstv v2: polnyij reyestr perezhivayet smenu etapa, istoriya ne teryayetsya pri merge, a zaversheniye trebuyet nastoyasjhikh zakryityikh priyomok i sovpadeniya rezuljtatov s Git i diskom. [Kontrakt](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/kontrakt-obyazateljstv-v2.md) opisyivayet tochnyij interfejs i granicyi. Eto kontroljnaya postavka otdeljnogo ispolnitelya, ne finaljnaya priyomka vsej postoyannoj zadachi.

## Soderzhateljnyiye otvetyi i resheniya

- Na «Pochemu snova ostanovilsya?» provereno konkretnoye slaboye mesto: prezhnij guard mog priznatj vyipolnennyim zavershyonnyij perechenj etapa, ne sokhraniv vesj iskhodnyij obyyom. Eto podtverzhdeno RED, a ne obyyasneno predpolozheniyem o povedenii modeli.
- Na «Kak mozhno sistemno reshitj etu problemu s prezhdevremennoj ostanovkoj?» dobavlen ustojchivyij reyestr s neizmenyayemyim proiskhozhdeniyem. Punkt plana, dokument, kommit i zavershyonnyij rebyonok ne zamenyayut iskhodnyij rezuljtat.
- Po peredache planirovsjhika prinyat toljko naznachennyij checkout/ref na baze `ba6f1c7907478a638c9f0fda6d93f6da37a7fcf5`; prezhnij pisatelj podtverdil ostanovku. Realjnyiye pravila i kornevoj reyestr ostalisj oblastjyu planirovsjhika. Doslovnyiye pervichnyiye komandyi sokhranenyi v sosednem zaprose; sluzhebnaya perepiska ispolnitelej ne podmenyayet poljzovateljskij dialog.
- Soglasovan strogij lokaljnyij v2: vneshnyaya Swift-kvitanciya trebuyet otdeljnogo budusjhego kontrakta s repozitoriyem/OID. Otsutstviye takoj kvitancii ostavlyayet obyazateljstvo otkryityim. Kornevoj reyestr s pyatjyu obyazateljstvami proveren toljko chteniyem na sovmestimostj formyi; integraciya vyipolnyayetsya kornem na tochnyikh kommitakh.
- S ispolnitelem Stop soglasovanyi exit 3 dlya realjnogo ostatka i exit 2 dlya nedokazannogo zaversheniya. Sostoyaniye `продолжить/null/[]` isklyucheno: yesli rezuljtatyi prinyatyi, no plan/reyestr otlichayetsya ot HEAD, diagnostika pryamo trebuyet sveritj i zafiksirovatj granicu.
- Na novoye ukazaniye o prioritete avtomatizacii, peredannoye kornem vo vremya podgotovki kontroljnoj tochki, sokhranyon vosproizvodimyij rezuljtat: CLI reshayet proveryayemuyu zadachu, sinteticheskiye Git-fiksturyi avtomatiziruyut yeyo regressionnuyu proverku, otdeljnyij scenarij avtomatiziruyet sozdaniye istorij i sravnimyiye izmereniya. Daljnejshij urovenj avtomatizacii ne rasshiryayet etot segment do beskonechnogo proyektirovaniya; obsjhiye pravila zakreplyayet korenj, iskhodnyiye svideteljstva ne perepisyivayutsya.

## Realizaciya i revjyu

Proverka chitayet vse dostizhimyiye vershinyi i roditelej Git, istochniki imenno iz ukazannyikh kommitov, nastoyasjhiye TOML-kartochki i tochnyiye zakryityiye dokazateljstva v4. Udaleniye/vosstanovleniye reyestra, novyij genesis, poterya vtorogo roditelya, nedostizhimyij ili slishkom pozdnij istochnik, podmena zakryityikh bajtov, simvolicheskij putj i skryityij `assume-unchanged` ne razreshayut zaversheniye. Istoricheskaya dostovernostj prezhnikh priyomok otdelena ot aktualjnosti novogo rezuljtata.

Read-only-revjyu vyiyavilo i pomoglo ustranitj obkhod cherez udalyonnyij reyestr/v1, soglasovannuyu perepisj zakryitogo snimka, nevozmozhnostj povtorno prinyatj obnovlyonnyij kod, lozhnuyu ostanovku po primeru, nepraviljnyij exit dlya oshibok otchyotnogo kontura i rannij stop s postoronnim planom. Dlya nakhodok sokhranenyi RED/GREEN. Poslednyaya uzkaya sverka podtverdila zakryitiye zamechanij; susjhestvennyikh nezakryityikh nakhodok v rassmotrennom obyyome net. Revjyuyer ne zapuskal testyi i ne menyal fajlyi.

Vosproizvodimyij profilj pokazal izbyitochnyiye processyi chteniya istorii. Paketnoye razresheniye roditeljskikh Git-derevjyev i kyesh povtornyikh proverok predka vnutri odnogo vyizova sokratili medianu na 100 kommitakh: 40 otkryityikh obyazateljstv — s 2,264451459 do 0,316622 s; odna zakryitaya priyomka — s 1,739331125 do 0,600791 s. Tochnyiye iskhodnyiye i povtornyiye zameryi, usloviya i khyeshi sokhranenyi v [profile do](materialyi/profilj-do-optimizacii.json) i [profile posle](materialyi/profilj-posle-optimizacii.json). Kriterij — snizheniye medianyi tekh zhe tryokh zapuskov bez izmeneniya reshenij i bez propuska rezhimov/vetvej; vyipolnen. Optimizaciya prinyata; daljnejsheye uslozhneniye bez novogo izmerennogo uzkogo mesta ne trebuyetsya. Novyiye imena normalizovanyi lokaljnoj token-osoznannoj avtomatizaciyej po [proverennoj karte](materialyi/pereimenovaniya.json).

[Kontrolj itogovogo koda](materialyi/profilj-itogovogo-koda.json) posle utochneniya wire i imyon sokhranil rezuljtat: medianyi 0,305455292 i 0,615166708 s sootvetstvenno. Scenarij, versii sredyi i chislo povtorov te zhe; novyiye regressionnyiye metodyi fiksturyi v profilj ne vkhodyat.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Unasledovannaya podgotovka i peredacha | ne izmereno | Nachalo papki 11:52:29 MSK; prezhnyaya narabotka opisana v peredache, dliteljnostj ne vosstanovlena dogadkoj |
| Analiz, TDD i ispravleniya po revjyu | ne izmereno | Sobstvennyij rabochij khod posle peredachi; tochnyiye obsjhiye granicyi ne snimalisj, proverki uchityivayutsya otdeljno |
| Nablyudayemyij interval profilirovaniya i soglasovaniya | 866 s | Kanonicheskiye metki 12:33:15–12:47:41 MSK; kalendarnyij interval vklyuchayet analiz, proverki i perepisku, ne summiruyetsya s nimi |
| Adresnyiye proverki i profili | mashinnyiye izmereniya nizhe | Monotonnoye vremya otdeljnyikh pryamyikh vyizovov v4; zameryi CLI dopolniteljno sokhranenyi v JSON |
| Polnyij FUM smoke i peresborka proyekcii | ne vyipolnyalisj | Ostavlenyi planirovsjhiku pri integracii; chuzhoye derevo ne proveryalosj |

Granica profilya: nablyudayemyiye vremennyiye metki otnosyatsya k 2026-09-09; 12:33:15–12:47:41 MSK — toljko yavno izmerennyij kalendarnyij interval. Vremya do nego i posle, finaljnaya fiksaciya i dostavka ne ocenivayutsya zadnim chislom. FIFO i atomarnyij commit+handoff ne primenyalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                            | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------- | ------------ | --------- |
| [Zasjhita obyazateljstv] RED — sokhranyonnyiye obyazateljstva i dokazateljstva priyomki   | 3,585 s      | neuspeshno |
| [Zasjhita obyazateljstv] RED — istoriya Git, granicyi ostanovki i celostnostj priyomki | 7,553 s      | neuspeshno |
| [Zasjhita obyazateljstv] GREEN — pervyij prokhod proverki obyazateljstv v2             | 17,414 s     | uspeshno   |
| [Zasjhita obyazateljstv] RED — nakhodki nezavisimogo revjyu v2                        | 22,197 s     | neuspeshno |
| [Zasjhita obyazateljstv] GREEN — ispravleniya revjyu i istoricheskij interfejs         | 25,407 s     | uspeshno   |
| [Zasjhita obyazateljstv] Profilj — sto kommitov i dva rezhima resheniya                | 22,88 s      | uspeshno   |
| [Zasjhita obyazateljstv] RED — paketnaya istoriya i dopolniteljnyiye granicyi kontrakta  | 27,438 s     | neuspeshno |
| [Zasjhita obyazateljstv] GREEN — paketnoye chteniye polnoj istorii                     | 29,813 s     | uspeshno   |
| [Zasjhita obyazateljstv] Profilj — povtor posle paketnogo chteniya                    | 15,418 s     | uspeshno   |
| [Zasjhita obyazateljstv] Inventarj — sobstvennyiye obyyavleniya zatronutogo navyika      | 4,17 s       | uspeshno   |
| [Zasjhita obyazateljstv] Proverka bezopasnyikh pereimenovanij                         | 1,633 s      | uspeshno   |
| [Zasjhita obyazateljstv] Regressiya — vesj zatronutyij navyik svyaznosti                | 32,405 s     | uspeshno   |
| [Zasjhita obyazateljstv] RED — nezakommichennaya terminaljnaya granica                 | 1,16 s       | neuspeshno |
| [Zasjhita obyazateljstv] RED — ostanovka ne podmenyayet vyibrannyij plan                | 0,447 s      | neuspeshno |
| [Zasjhita obyazateljstv] GREEN — soglasovannyij wire i strogaya ostanovka             | 30,955 s     | uspeshno   |
| [Zasjhita obyazateljstv] Regressiya — itogovyij adresnyij nabor s Git-zavisimostjyu     | 35,413 s     | uspeshno   |
| [Zasjhita obyazateljstv] Profilj — kontrolj itogovogo koda                          | 14,783 s     | uspeshno   |
| [Zasjhita obyazateljstv] Imena — otsutstviye novyikh sobstvennyikh latinskikh obyyavlenij  | 4,507 s      | uspeshno   |
| [Zasjhita obyazateljstv] Publikacionnaya chistota putej                               | 17,273 s     | neuspeshno |
| [Zasjhita obyazateljstv] Diagnostika — toljko narusheniya publikacionnyikh putej        | 17,563 s     | neuspeshno |
| [Zasjhita obyazateljstv] GREEN — tochnaya publikacionnaya politika                     | 17,269 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 349,283 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:4735a80c4f089ac713c6a962a99d72bb9791de4ce0215bf190903dd821e26d5c.
Kontekst soderzhimogo: sha256:af7402fdbdf6be6fa1036787c2b19f0ff51b9f0248295942b38a2ae0d742ed67.
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

- Pervyiye RED: 11 otkazov iz 12 testov, zatem 14 iz 24; pervyij GREEN — 24 testa. Nezavisimoye revjyu porodilo otdeljnyiye padayusjhiye regressii, posle ispravlenij — 45, zatem 50 proverok v1/v2.
- Polnaya adresnaya regressiya zatronutogo navyika posle utochneniya wire, pereimenovanij i scenariya realjnoj Git-zavisimosti: 130 testov, uspeshno, 35,224 s dochernego processa. Eto ne polnyij FUM smoke.
- Bezopasnoye pereimenovaniye: 11 avtonomnyikh testov, uspeshno; sukhoj plan proveren do primeneniya. Kontrolj ostatka i finaljnoj granicyi otrazhayetsya mashinnyimi zapisyami i zaklyuchiteljnyim read-only-dopuskom kontroljnoj tochki.
- Istoricheskaya popyitka prezhnego pisatelya zavershilasj do registracii dochernikh testov iz-za otsutstviya LinguisticKit; nablyudyonnyij vyizov 0,999 s opisan v [peredache](materialyi/peredacha.md). Ona ne nazvana RED i ne dobavlena vyimyishlennoj zapisjyu zapuska.
- Publikacionnyij skaner obnaruzhil 16 form v opredeleniyakh raspoznavatelya, otnositeljnyikh suffiksakh i sinteticheskikh fiksturakh. Oni prosmotrenyi postrochno; [tochnyij manifest](materialyi/publikacionnyiye-isklyucheniya.json) primenyon shtatnyim generatorom politiki s khyeshami strok i schyotchikami. Mashinno-lokaljnyikh adresov eti stroki ne soderzhat; obsjhij zapret i prezhniye isklyucheniya ne oslablyalisj.
- Dva predvariteljnyikh read-only-dopuska kontroljnoj tochki vyiyavili nesovpadayusjhij predprosmotr posle staging i 282 unasledovannyiye ssyilki na otsutstvuyusjhij ignoriruyemyij `.obsidian/graph.json`. Predprosmotr perenesyon posle okonchateljnogo staging. Planirovsjhik yavno razreshil konkretnuyu neprimenimostj globaljnyikh ssyilok po pravilu 000178: ne sozdavatj/kopirovatj poljzovateljskoye sostoyaniye, ne oslablyatj validator, sokhranitj otkaz i sveritj otsutstviye inyikh oshibok. Eti kontroljnyiye chteniya nakhodyatsya vne mashinnogo zhurnala po uzkomu isklyucheniyu kontroljnoj tochki; ikh polnaya dliteljnostj ne izmerena. Obsjhij dopusk ne obyyavlyayetsya uspeshnyim.
- Okonchateljnaya sverka posle ispravleniya poryadka podtverdila rovno 282 soobsjheniya o staryikh ssyilkakh na etot fajl, ni odnogo soobsjheniya o tekusjhem zaprose i ni odnoj inoj oshibki. Proverki predprosmotra, strukturyi, recency i indeksa boljshe ne dayut otkaza. Itogovyij exit 1 globaljnoj svyaznosti sokhranyon kak yavno razreshyonnaya nepolnaya obsjhaya priyomka, ne zamaskirovan uspekhom.

## Resheniya i ogranicheniya

- Kontroljnyij kommit sokhranyayet otkryityij v4-zhurnal s tochnyim predprosmotrom, ne zakryituyu priyomku. Pravila, realjnyiye kartochki/reyestr kornya, FUMA i obsjhaya Git-konfiguraciya ne izmenenyi. Zavisimostj materializovana na susjhestvuyusjhem gitlink bez yego obnovleniya.
- Susjhestvuyusjhaya proyekciya ne peresobiralasj. Pokoleniye svyazano s khyeshem plana `sha256:448211f8b8fccef2c8c4f471cb0c9b62bcd9dcc431352f5a8de33b03803d912f` i iskhodnyim inventaryom `sha256:27d0770a13d4af0a0f4c9228c89ba597a26050ea1e1f805f3097d53e603e13dc`; ono otstayot ot novyikh kanonicheskikh fajlov. Eto yavnyij ostatok integracii, a ne zayavleniye aktualjnoj proyekcii.
- Planirovsjhiku ostayutsya integraciya tochnogo kommita s adapterom Stop, zapusk po nastoyasjhemu kornevomu reyestru, polnyij primenimyij smoke i aktualjnaya proyekciya. Vneshniye Swift-rezuljtatyi ne pogashayutsya etoj lokaljnoj skhemoj.
- Mashinnaya soglasovannostj ne udostoveryayet semanticheskuyu polnotu trebovanij/realizacii ili nezavisimuyu podlinnostj zapuska. Git khranit toljko ispolnyayemyij bit; nestandartnyiye rezhimyi mogut bezopasno otklonyatjsya. Povtornoye chteniye vkhodov ne yavlyayetsya globaljnoj atomarnoj tranzakciyej.
- Kontroljnaya postavka ispoljzuyet toljko yavno razreshyonnuyu neprimenimostj staryikh ssyilok na lokaljnoye poljzovateljskoye sostoyaniye. Finaljnaya obsjhaya proverka ostayotsya u kornya; poljzovateljskiye fajlyi Obsidian ne izmenenyi. Nalichiye sobstvennoj vetki i checkpoint ne pogashayet pyatj kornevyikh obyazateljstv.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 13:03:08 MSK -->
<!-- content-sha256: sha256:c653fe4a667ee68093844ae570726e7fcb8232d11ed0ea81e5c262a0f2a6a136 -->
<!-- FUM-MD-RECENCY:END -->
