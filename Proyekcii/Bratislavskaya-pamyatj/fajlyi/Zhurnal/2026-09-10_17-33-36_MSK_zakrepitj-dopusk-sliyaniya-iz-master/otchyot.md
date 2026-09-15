# Otchyot 2026-09-10 17:33:36 MSK - Zakrepitj dopusk sliyaniya iz master

Vedyotsya sleduyusjhij etap prinyatogo napravleniya: podgotovitj proveryayusjhij kontur v master posle sokhraneniya neprinyatogo C1. Korenj ostayotsya yedinstvennyim pisatelem; derevo C1 posle fiksacii ne izmenyayetsya.

## Plan

1. Zakrepitj istochnik pravil M i novuyu vedusjhuyu bazu L1=C1 bez perepisyivaniya iskhodnoj istorii.
2. Razdelitj v susjhestvuyusjhem smoke istochnik proverok i proveryayemoye derevo. Testyi, fiksturyi i ozhidayemyiye rezuljtatyi berutsya iz M; yavnyij korenj realizacii vyibirayetsya do importa toljko v zatronutyikh predmetnyikh testakh. Obyichnyij rezhim sokhranyayetsya.
3. Sokhranitj otdeljnuyu tipizirovannuyu politiku kandidata: 301 prezhneye isklyucheniye M i 49 dopolniteljnyikh iz L. Pereispoljzovatj ogranichennoye raspoznavaniye binarnyikh vlozhenij zaprosov i proveritj yego granicu; eto ne proverka soderzhimogo arkhivov na sekretyi.
4. Svyazatj zakryityij polnyij otchyot s nastoyasjhim merge-kommitom i tochnyimi roditelyami [L1, M1], otlichaya predkommitnyij HEAD L1 ot doverennogo istochnika M1. Prezhnij kontrakt odnogo roditelya ne oslablyatj.
5. Podgotovitj proveryayemoye fast-forward-prodvizheniye togo zhe prinyatogo kommita s ozhidayemyim prezhnim master i sokhraneniyem lokaljnogo sostoyaniya. Do proverki etogo puti master ne prodvigayetsya.
6. Vyipolnitj RED/GREEN, profilj, itogovyij smoke M1 i lokaljnyij kommit. Zatem vklyuchitj prinyatyij M1 v kandidat i provesti yego otdeljnuyu priyomku.

## Iskhodnaya granica

C1: `436909208424595f7151f6febca75f89018c0bcb`; derevo: `1a60584ba702afd3938eddba50245551dd2b8ee7`; roditeli: [`ef0b528c8c117f7cfddb83d1699aa333d9c486a5`, `6bd676e2dbba4dc210fa5041e641a9126cc2624c`]. Eto sokhraneniye podgotovlennoj rabotyi, ne prinyatyij rezuljtat sliyaniya.

Read-only-razbor suzil standartnyij kontur do vosjmi izmenyonnyikh susjhestvuyusjhikh realizacij i dvenadcati tochek vyibora proveryayemogo koda v testakh. Semj ostaljnyikh standartnyikh katalogov realizacii, Markdown-parser, shablonyi zaprosov, Swift-paket preobrazovatelya i yego kontrakt, LinguisticKit i yakornyiye JSON istorii obyazateljstv sovpadayut. Eti nablyudeniya yesjhyo ne zamenyayut proverki novogo kontura.

## Utochneniye poljzovatelya o dostavke iskhodnikov

Zafiksirovano novoye porucheniye sleduyusjhim shagom sobratj sobstvennuyu realizaciyu v FUM, sokhraniv sabmoduljnyiye zavisimosti. [FUM-STEP-0176](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md) soderzhit granicyi perenosa i priyomki iz chistogo klona. Dva iskhodnyikh soobsjheniya prochitanyi iz JSONL i sokhranenyi doslovno s vremennyimi metkami i SHA-256 v zaprose. Obzor po ssyilke arkhivirovan shtatnyim instrumentom: HTTP 200, 56 soobsjhenij; inline-paketa vneshnego izmeneniya net.

Chteniye pervichnyikh zhurnalov i Git podtverdilo neperenesyonnyiye iskhodniki i otdeljnuyu Git-bazu bez remote. Kod prisutstvuyet v tryokh svyazannyikh rabochikh vetkakh kontejnera, statistiki i arkhivnogo snimka; master i sokhranyonnyij C1 soderzhat svideteljstva, no ne eti Swift-paketyi. Inventarizaciya ne ispolnyala chuzhiye programmyi i ne povtoryala prezhniye Swift-proverki. Sborka i proverka obnovlyonnogo reyestra planirovaniya proshli. Proverka mashinno-lokaljnyikh putej posle arkhivirovaniya obzora i zapisi plana takzhe proshla; eto ogranichennaya publikacionnaya proverka tekusjhikh materialov. Perenos iskhodnikov i yego priyomka yesjhyo predstoyat.

### Utochnyonnyij sostav sleduyusjhego perenosa

Nezavisimaya staticheskaya inventarizaciya vyiyavila 110 razlichnyikh otslezhivayemyikh fajlov: 39 fajlov obsjhej osnovyi prilozheniya i 71 fajl chetyiryokh paketov. Eto inventarj kandidatov na dostavku, ne razresheniye vslepuyu ustanavlivatj vse launchd-konfiguracii i scenarii. Sovpadayusjhiye puti tryokh dochernikh vershin soderzhat odinakovyiye bajtyi; statistika i arkhivnyij adapter nakhodyatsya v raznyikh vetkakh, poetomu kopirovaniye toljko odnogo checkout poteryayet chastj rezuljtata.

| Paket | Vsego fajlov | Sources | Tests |
| ----- | ------------ | ------- | ----- |
| KontejnerNablyudenij | 16 | 9 | 5 |
| SnimokAgentskojZadachi | 17 | 8 | 6 |
| StatistikaVyizovov | 20 | 11 | 7 |
| ArkhivnyijSnimokZadachi | 18 | 8 | 7 |

Ostaljnyiye paketnyiye fajlyi — manifestyi, README i sinteticheskiye primeryi. Vnutri paketov sokhranenyi scenarii profilirovaniya; zavisimosti sistemnyiye ili otnositeljnyiye mezhdu sosednimi paketami. Sobstvennyikh gitlink v iskhodnoj Git-baze net. Obsjhaya osnova soderzhit prilozheniye, sensor Accessibility, cikl vnimaniya, MCP-vkhod, proyekt Xcode i scenarii ustanovki. Dva neotslezhivayemyikh runtime-fajla osnovnoj rabochej kopii ne chitalisj i ne vklyuchenyi v perechenj. Proverennaya publikacionnaya chistota tekusjhego arkhiva i plana ne otnositsya k yesjhyo ne perenesyonnyim 110 fajlam.

Vse 16 fajlov pervogo kontejnera sovpadayut s iskhodnyim commit `dfdd1b65afd59666a696c29a024e0ca059497157`; 15 Swift-fajlov sovpadayut s sokhranyonnyim manifestom pervogo segmenta. Perenos sleduyet proveryatj kak obyyedineniye etikh tochnyikh naborov s sokhraneniyem ikh proiskhozhdeniya. Priyomka perenesyonnogo rezuljtata poka ne vyipolnyalasj.

## Zakrepleniye razmesjheniya sobstvennyikh komponentov

Po sleduyusjhej pryamoj komande poljzovatelya v kornevoye yadro i inventarj dobavleno `FUM-ПРАВИЛО-НОВОЕ-000016`: monorepozitorij FUM yavlyayetsya mestom sobstvennoj realizacii po umolchaniyu. Pravilo okhvatyivayet iskhodniki, proverki, profili i instrukcii, razlichayet vneshniye zavisimosti i rabochiye derevjya toj zhe Git-bazyi, sokhranyayet lokaljnyiye runtime-dannyiye vne Git i trebuyet otdeljnogo podtverzhdeniya publichnoj dostupnosti. Istoricheskiye otdeljnyiye repozitorii ne udalyayutsya; ikh perenos ostayotsya FUM-STEP-0176. Novoye pravilo razmesjheno v P0, poetomu yego obnaruzheniye ne zavisit ot vyibora specialjnogo tematicheskogo marshruta. Oblastj normyi 000206 takzhe utochnena: otdeljnoye raspolozheniye sobstvennogo komponenta ne delayet yego vneshnej zavisimostjyu. Obnovlenyi inventarj i khyesh tematicheskogo fajla; istoricheskij snimok sokhranyon.

## Sleduyusjhij obyazateljnyij vkhod soobsjhenij

Po utochneniyu poljzovatelya sleduyusjhej posle tekusjhego dopuska naznachena FUM-STEP-0177: avtomatizaciya polnogo ostatka poljzovateljskikh soobsjhenij bez dejstviteljnoj istorii obrabotki. Ruchnaya sverka JSONL yavlyayetsya vremennyim sposobom do yeyo priyomki. Perenos sobstvennoj realizacii FUM-STEP-0176 sokhranyon i sleduyet za etim vkhodom. Pervichnyiye soobsjheniya, soderzhateljnyiye otvetyi i kriterii zapisanyi; gotovaya realizaciya obyazateljnogo vyizova poka otsutstvuyet.

## Posledniye predmetnyiye rezuljtatyi dopuska

Prezhniye chastnyiye chernoviki adaptera i testov sliyaniya najdenyi i pereispoljzovanyi v monorepozitorii. Pervaya popyitka testa obnaruzhila nedopustimyij kirillicheskij bytes-literal chernovika; posle yego ispravleniya poluchen soderzhateljnyij RED otsutstvuyusjhego API i GREEN realjnogo merge s otpechatkom dejstvuyusjhej obyortki. Chetyirnadcatj iskhodnyikh scenariyev proshli. Dopolniteljnyij RED pokazal propusk shallow i grafts; posle ogranichennogo ispravleniya proshli vse semnadcatj scenariyev, vklyuchaya drugoj master s tem zhe derevom i Git replace pri vneshnem GIT_NO_REPLACE_OBJECTS=0.

Zamechaniye o vlozhennom importe podtverzhdeno RED pri polnom obnaruzhenii testov skanera. Dve sosedniye tochki zagruzki realizacii soglasovanyi s vyibrannyim kornem; tot zhe adresnyij scenarij proshyol GREEN. Testyi i shablonyi ostayutsya istochnikom master. Eti rezuljtatyi ne zamenyayut ostavshijsya doverennyij zapusk vsego kontura, profilirovaniye i finaljnuyu priyomku M1.

## Istochnik polnogo zapuska i nezavisimyij razbor

Dobavlen otdeljnyij vyibor proveryayemoj realizacii dlya 13 standartnyikh naborov pri sokhranenii testov i fikstur iz master. Tri regressii podtverdili RED/GREEN: testyi kandidata ne podmenyayut doverennyij nabor, sokrasjheniye plana zapresjheno, peremennyiye Python i Git ochisjhayutsya. Vlozhennyij import skanera raneye ispravlen otdeljnoj regressiyej pri polnom discover.

Novyij modulj proiskhozhdeniya sveryayet prinyatyij master, yego iskhodniki, pravila, testyi, fiksturyi i politiku s Git-obyyektami. Arkhiviruyemaya Swift-obyortka i vlozhennyiye recency/project-files imeyut otdeljnuyu granicu identichnosti. Proveryayetsya tochnyij gitlink LinguisticKit i yego materializaciya. Po nezavisimomu razboru ispravlenyi podtverzhdyonnyiye RED obkhodyi: lishnij modulj, uzhe dobavlennyij v indeks; nevernyij rezhim gitlink pri tom zhe OID; simvolicheskaya ssyilka v roditeljskom kataloge zavisimosti; skryityij vneindeksnyij import kandidata; nevernyij rezhim indeksirovannogo svideteljstva. Polnyij inventarj sveryayetsya nezavisimo ot tekusjhego indeksa. Vse 12 pervonachaljnyikh adresnyikh scenariyev proshli; pozdneye dobavlen otkaz pri izmenyonnoj rabochej Swift-obyortke kandidata.

Skvoznaya fikstura zapuskayet nastoyasjhiye smoke i otchyotnuyu obyortku iz master, 13 sinteticheskikh naborov testov i proveryayemyij kandidat. Poluchena uspeshnaya v3-zapisj s 13 nablyudeniyami pri podmenyonnyikh testakh kandidata, yego unittest.py, vneshnikh PYTHONPATH/GIT_DIR i ustarevshem bajtkode master s sovpadayusjhimi razmerom i mtime iskhodnika. Sobstvennyij pustoj prefiks kyesha peredayotsya obyichnyim i izolirovannyim Python-processam. Eto proverka mekhanizma zapuska; realjnaya polnaya priyomka M1 i C2 yesjhyo vperedi.

Obsjhij nabor smoke vyipolnil 89 testov i obnaruzhil chetyire ustarevshiye zagotovki argumentov CLI; zagotovki dopolnenyi novyimi neobyazateljnyimi polyami. Adresnyij povtor pyati zatronutyikh scenariyev proshyol. Obsjhij nabor otchyotnoj obyortki, starogo adaptera, zakryitogo chitatelya i sliyaniya proshyol: 124 testa za 58,827 s. Nezavisimyij prosmotr ne nashyol blokiruyusjhikh defektov otdeljnogo adaptera svyazi sliyaniya.

Realizovana proverka proiskhozhdeniya po svideteljstvu iz neizmenyayemogo merge-kommita. Skvoznoj RED otsutstvuyusjhego CLI smenilsya GREEN: uspeshnaya polnaya v3-zapisj zakryivayetsya, vkhodit v nastoyasjhij merge, svyazyivayetsya s M i UUID poslednego polnogo zapuska. Pyatj podmen — otsutstviye, nekanonicheskiye bajtyi, inoj UUID, inoj istochnik i lishnij klyuch — otklonenyi. Komandyi podgotovki, zapuska i chteniya sokhranenyi v dokumentacii instrumenta. Ostayutsya finaljnaya priyomka M1 i posleduyusjhaya priyomka C2. Uspeshnyij zapusk otdeljnogo sloya ne vyidayotsya za obsjhij dopusk prodvizheniya master.

## Izmereniya i optimizaciya dopuska

[Parnyij scenarij adaptera](materialyi/izmeritj-dopusk-sliyaniya.py) sokhranyayet iskhodnuyu realizaciyu i sravnivayet yeyo s optimizirovannoj na odnoj sinteticheskoj Git-fiksture. [Rezuljtat](materialyi/profilj-adaptera-posle.json): 13 → 6 processov Git, mediana semi chereduyusjhikhsya par 153,231 → 70,398 ms; polnyiye otvetyi sovpali. Chetyire paryi zaprosov tipov zamenenyi odnim strogim batch-check. Novaya regressiya otvergayet perestanovki, propuski, nevernyiye tipyi i razmeryi; vse 18 scenariyev adaptera proshli.

[Scenarij proiskhozhdeniya](materialyi/izmeritj-proiskhozhdeniye-kontura.py) i [yego profilj](materialyi/profilj-proiskhozhdeniya-kontura.json) otdeljno izmeryayut novuyu granicu M/C/zavisimosti: 39 processov Git, mediana semi povtorov 454,153 ms. Podgotovka fiksturyi isklyuchena; eto sinteticheskij tyoplyij vkhod, ne vesj FUM i ne vremya proyekcii. CPU Python sokhranyon, CPU dochernikh processov i pamyatj ne izmerenyi. Analiz optimizacii vyiyavlyayet postoyannuyu stoimostj zapuskov Git; daljnejsheye obyyedineniye zaprosov otlozheno do izmereniya na realjnom kandidate, poskoljku raznyiye proverki vyipolnyayutsya v raznyikh Git-bazakh i podtverzhdayut otdeljnyiye granicyi. Kyeshirovatj uspeshnoye proiskhozhdeniye mezhdu proverkami neljzya bez novogo dokazateljstva neizmennosti. Uskoreniye adaptera uzhe podtverzhdeno bez oslableniya etikh granic.

## Podtverzhdeniye fakticheskogo ispolneniya

Nezavisimyij razbor obnaruzhil nedostatochnostj podgotovlennogo svideteljstva: obyichnyij polnyij zapusk kandidata s praviljnyimi M/L/UUID oshibochno poluchal vyisokij dopusk. Eto vosproizvedeno RED na nastoyasjhem merge. Ispravleniye svyazyivayet kanonicheskij khyesh svideteljstva s finaljnoj v3-zapisjyu posle uspeshnyikh pre/post-proverok istochnika i okonchateljnogo uspekha. CLI/API ne mogut peredatj podtverzhdeniye argumentom. GREEN podtverzhdayet: obyichnyij full prinimayetsya nizkim chitatelem i otklonyayetsya vyisokim; shtatnyij M-on-C prokhodit; izmeneniye istochnika vo vremya zapuska ne vyidayot metku. Vse 15 scenariyev proshli za 34,421 s. Boleye rannij obsjhij zapusk 13 scenariyev vyiyavil ustarevsheye ozhidaniye teksta oshibki posle uzhestocheniya proverki Swift-paketa; ozhidaniye privedeno k fakticheskoj granice otkaza. Eto ne povtornaya realizaciya vetki planirovsjhika.

## Sokhraneniye nezakommichennogo etapa

Po voprosu poljzovatelya vyipolnena read-only-sverka: master ostayotsya na iskhodnom M0, indeks pust, nezakommichennyiye izmeneniya prisutstvuyut. Dopolniteljno vne checkout sokhranenyi i sverenyi po SHA-256 72 izmenyonnyikh i novyikh fajla, vklyuchaya binarnyiye dannyiye, a takzhe diff i bajtyi indeksa. Eto snimok do daljnejshikh pravok tekusjhego etapa, a ne yego itogovaya postavka. Tochnaya iskhodnaya komanda i soderzhateljnyij otvet sokhranenyi v zaprose po JSONL. Pered prodvizheniyem master etap M1 dolzhen vojti v proverennyij lokaljnyij kommit i statj roditelem sleduyusjhego sliyaniya.

Nezavisimyij staticheskij povtor posle ispravleniya ne obnaruzhil blokerov v svyazi ispolneniya: metka formiruyetsya toljko iz podtverzhdyonnyikh kanonicheskikh bajtov posle okonchateljnogo uspekha, a chitatelj sveryayet finaljnuyu zapisj togo zhe C. Eto dopolniteljnyij razbor, ne zamena finaljnogo smoke-check.

## Pervaya obsjhaya priyomka

Pervyij polnyij progon ostanovilsya na shestom shage publikacionnoj chistotyi posle uspeshnyikh strukturyi, reyestra i proyekcii. Primeneniye 5388 fajlov zanyalo 204,436 s, nezavisimaya proverka manifesta — 98,432 s; polnaya neuspeshnaya popyitka — 339,433 s. Poljzovatelj schyol vremya primeneniya priyemlemyim dlya tekusjhego obyyoma. Chetyire srabatyivaniya skanera otnosilisj k chastyam otnositeljnyikh putej i ekranirovannyim perevodam strok sinteticheskogo koda. Puti vyirazhenyi cherez Path, perevodyi strok — cherez chr(10), bez oslableniya politiki skanera. Eto prichina povtornoj priyomki; dopolniteljnaya optimizaciya ne dobavlyayetsya. Adresnaya publikacionnaya proverka ispravleniya proshla. Predvariteljnaya svyaznostj vyiyavila otsutstviye arkhiva obzora v razdele zatronutyikh fajlov zaprosa; posle dobavleniya tochnoj ssyilki svyaznostj takzhe proshla. Pozdniye soobsjheniya perenesenyi iz dolgovechnogo chernovika posle zaversheniya neuspeshnoj popyitki; iskhodnyij snimok ne menyalsya vo vremya yeyo ispolneniya.

Polnyij `git diff --cached --check` soobsjhil toljko zavershayusjhij probel v doslovnoj iskhodnoj komande poljzovatelya o monorepozitorii. On sokhranyon kak chastj originala. Dlya ostaljnyikh putej primenyayetsya obyichnaya proverka whitespace; toljko fajl etogo zaprosa proveryayetsya s otklyuchyonnyim `blank-at-eol`. Eto adresnoye isklyucheniye dlya sokhrannosti iskhodnogo teksta, ne izmeneniye Git-konfiguracii repozitoriya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| ------ | ------------ | ------------------------- |
| Razbor sokhranyonnogo kandidata i granicyi proverok | ne izmereno | Chteniye M i C1 do realizacii etogo etapa |
| Pryamyiye proverki | uchtenyi nizhe | Zapuski cherez otchyotnuyu obyortku etogo zaprosa |

Granica profilya: etap nachat po nablyudyonnoj pare 2026-09-10 17:33:36 MSK posle sokhraneniya C1. Nepreryivnoye vremya analiza ne snimalosj; vremya proverok fiksiruyetsya obyortkoj. Vlozhennyiye shagi ne summiruyutsya vtoroj raz. FIFO i publikaciya ne zapuskalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:1a3515afe94ddadbbbb313966f57453a12f00f4701c48f08962dd2304ebd80f9 -->

| Vyizov                                                                                                     | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Kornevoj pisatelj] RED: binarnoye vlozheniye trebuyet obyichnyij iskhodnyij zapros                                | 0,236 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: binarnoye proiskhozhdeniye vlozheniya i zapret ssyilki vmesto zaprosa                 | 0,304 s      | uspeshno   |
| [Kornevoj pisatelj] Obyichnaya publikacionnaya politika master posle podderzhki vlozhenij                       | 18,372 s     | uspeshno   |
| [Kornevoj pisatelj] Predlagayemaya politika M1 na sokhranyonnom kandidate C1                                  | 21,345 s     | uspeshno   |
| [Kornevoj pisatelj] RED: yavnyij vyibor realizacii i izolyaciya obyichnogo smoke                                 | 0,127 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: yavnaya realizaciya peredayotsya toljko vyibrannyim proverochnyim detyam                 | 0,189 s      | uspeshno   |
| [Kornevoj pisatelj] RED: realizaciya vyibirayetsya do importa, a shablonyi ostayutsya doverennyimi                 | 0,658 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: doverennyiye testyi vyibirayut realizaciyu do importa i sokhranyayut svoi shablonyi       | 0,541 s      | uspeshno   |
| [Kornevoj pisatelj] Sborka reyestra s shagom yedinoj postavki iskhodnikov                                     | 0,406 s      | uspeshno   |
| [Kornevoj pisatelj] Obnovleniye reyestra posle vyiravnivaniya indeksnoj stroki shaga                           | 0,355 s      | uspeshno   |
| [Kornevoj pisatelj] Proverka reyestra posle dobavleniya yedinoj postavki i recency                           | 0,382 s      | uspeshno   |
| [Kornevoj pisatelj] Publikacionnaya chistota arkhiva obzora i plana yedinoj postavki                          | 18,726 s     | uspeshno   |
| [Kornevoj pisatelj] Dekompoziciya pravil s obyazateljnyim monorepozitoriyem po umolchaniyu                      | 0,134 s      | uspeshno   |
| [Kornevoj pisatelj] Dekompoziciya posle utochneniya vneshnego proiskhozhdeniya zavisimostej                      | 0,1 s        | uspeshno   |
| [Kornevoj pisatelj] RED: sokhranyonnyij chernovik trebuyet svyazj nastoyasjhego sliyaniya                            | 0,053 s      | neuspeshno |
| [Kornevoj pisatelj] RED: realjnoye sliyaniye posle ispravleniya sintaksisa chernovika                          | 0,859 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: realjnoye sliyaniye svyazano s zakryityim otchyotom bez oslableniya starogo API         | 1,44 s       | uspeshno   |
| [Kornevoj pisatelj] Proverka pravila pereproverki iskhodnyikh soobsjhenij JSONL                                | 0,111 s      | uspeshno   |
| [Kornevoj pisatelj] Granicyi otdeljnogo merge-API i istoricheskogo chitatelya                                 | 17,847 s     | uspeshno   |
| [Kornevoj pisatelj] RED: merge-dopusk otklonyayet shallow i grafts                                          | 1,162 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: granicyi merge-svideteljstva s zasjhitoj istorii i tochnogo master                 | 21,682 s     | uspeshno   |
| [Kornevoj pisatelj] RED: polnyij discover ne dolzhen podmenyatj vlozhennyij import kandidata                   | 0,198 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: polnyij discover poluchayet vlozhennyij import iz kandidata                         | 0,21 s       | uspeshno   |
| [Kornevoj pisatelj] Sborka planovogo reyestra s obyazateljnyim vkhodom neobrabotannyikh soobsjhenij               | 0,349 s      | uspeshno   |
| [Kornevoj pisatelj] RED: istochnik testov sliyaniya i izolyaciya okruzheniya                                     | 0,189 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: istochnik testov sliyaniya i izolyaciya okruzheniya                                   | 0,234 s      | uspeshno   |
| [Kornevoj pisatelj] RED: proiskhozhdeniye vsego proveryayusjhego kontura sliyaniya                                 | 0,068 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: proiskhozhdeniye vsego proveryayusjhego kontura sliyaniya                               | 2,197 s      | neuspeshno |
| [Kornevoj pisatelj] Povtor posle ispravleniya Git-fiksturyi proiskhozhdeniya kontura                           | 5,98 s       | uspeshno   |
| [Kornevoj pisatelj] RED: polnyij vyizov sliyaniya i zaraneye indeksirovannoye proiskhozhdeniye                     | 0,519 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: polnyij vyizov i indeksirovannoye proiskhozhdeniye sliyaniya                           | 7,588 s      | uspeshno   |
| [Kornevoj pisatelj] RED: lishnij indeksirovannyij modulj proveryayusjhego kontura                               | 1,529 s      | neuspeshno |
| [Kornevoj pisatelj] RED: indeksirovannyij modulj posle ispravleniya granicyi fiksturyi                        | 1,491 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: polnyij inventarj istochnikov nezavisimo ot indeksa                              | 1,106 s      | uspeshno   |
| [Kornevoj pisatelj] RED: roditeljskaya ssyilka i rezhim podklyucheniya zavisimosti                              | 2,015 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: polnyij inventarj, tochnyij gitlink i fizicheskij korenj zavisimosti               | 10,61 s      | uspeshno   |
| [Kornevoj pisatelj] RED: raspoznavaniye otdeljnogo polnogo zapuska sliyaniya                                 | 0,111 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: raspoznavaniye otdeljnogo polnogo zapuska sliyaniya                               | 0,136 s      | uspeshno   |
| [Kornevoj pisatelj] RED: skvoznoj polnyij v3 zapusk iz master na kandidate                                 | 1,631 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: skvoznoj polnyij v3 zapusk iz master na kandidate                               | 6,577 s      | uspeshno   |
| [Kornevoj pisatelj] Proverka polnogo v3 s ustarevshim bajtkodom i podmenyonnyim okruzheniyem                   | 6,374 s      | uspeshno   |
| [Kornevoj pisatelj] Regressii obyichnogo smoke i otdeljnogo kontura sliyaniya                                 | 34,265 s     | neuspeshno |
| [Kornevoj pisatelj] Sovmestimostj obyichnogo smoke posle dopolneniya fikstur argumentov                      | 0,231 s      | uspeshno   |
| [Kornevoj pisatelj] RED: skryityij import kandidata i rezhim indeksirovannogo svideteljstva                  | 1,866 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: indeks svideteljstva i polnyij inventarj ispolnyayemoj realizacii                 | 16,274 s     | uspeshno   |
| [Kornevoj pisatelj] Sovmestimostj starogo adaptera i zakryitogo chteniya kommitov                            | 58,938 s     | uspeshno   |
| [Kornevoj pisatelj] Iskhodnyij profilj merge-adaptera na sinteticheskom vkhode                                | 3,058 s      | uspeshno   |
| [Kornevoj pisatelj] RED: strogij paket metadannyikh merge-adaptera                                          | 2,365 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: paketnaya proverka metadannyikh bez oslableniya merge-adaptera                     | 18,474 s     | uspeshno   |
| [Kornevoj pisatelj] Parnyij profilj paketnoj optimizacii merge-adaptera                                    | 2,386 s      | uspeshno   |
| [Kornevoj pisatelj] RED: podgotovka proiskhozhdeniya CLI i fiksaciya arkhiviruyemoj realizacii                  | 2,06 s       | neuspeshno |
| [Kornevoj pisatelj] GREEN: CLI proiskhozhdeniya i neizmennostj arkhiviruyemogo paketa                          | 7,641 s      | uspeshno   |
| [Kornevoj pisatelj] RED: neizmenyayemaya svyazj polnogo zapuska s proiskhozhdeniyem iz master                    | 7,269 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: neizmenyayemyij istochnik master svyazan s poslednim polnyim zapuskom                | 9,526 s      | uspeshno   |
| [Kornevoj pisatelj] Profilj stoimosti proverki proiskhozhdeniya na sinteticheskoj Git-fiksture                | 3,727 s      | uspeshno   |
| [Kornevoj pisatelj] Proveritj istochnik master, zakryitiye i neizmenyayemoye svideteljstvo sliyaniya              | 20,244 s     | neuspeshno |
| [Kornevoj pisatelj] RED: obyichnyij polnyij zapusk ne dokazyivayet ispolneniye kontura master                    | 3,415 s      | neuspeshno |
| [Kornevoj pisatelj] GREEN: obyichnyij polnyij zapusk ne mozhet podtverditj ispolneniye kontura master           | 3,957 s      | uspeshno   |
| [Kornevoj pisatelj] Podtverzhdeniye ispolneniya: istochnik, obyichnyij zapusk i otkaz posle proverki             | 34,486 s     | uspeshno   |
| [Kornevoj pisatelj] Proveritj dekompoziciyu pravil pered priyomkoj M1                                       | 0,11 s       | uspeshno   |
| [Kornevoj pisatelj] Obnovitj planovyij reyestr pered fiksaciyej M1                                           | 0,371 s      | uspeshno   |
| [Kornevoj pisatelj] Finaljnaya priyomka M1: proveryayusjhij kontur sliyaniya                                      | 339,513 s    | neuspeshno |
| [Kornevoj pisatelj] Lokalizovatj otkaz publikacionnoj chistotyi posle obsjhego progona                        | 18,617 s     | neuspeshno |
| [Kornevoj pisatelj] Publikacionnaya chistota posle utochneniya otnositeljnyikh putej i testovyikh perevodov strok | 18,955 s     | uspeshno   |
| [Kornevoj pisatelj] Proveritj svyaznostj podgotovlennogo otchyota i teksta kommita M1                        | 37,453 s     | neuspeshno |
| [Kornevoj pisatelj] Svyaznostj M1 posle vklyucheniya arkhiva v tochnuyu oblastj izmenenij zaprosa                | 37,607 s     | uspeshno   |
| [Kornevoj pisatelj] Proveritj format indeksirovannogo diff M1                                             | 0,04 s       | neuspeshno |
| [Kornevoj pisatelj] Format diff s sokhraneniyem doslovnogo zavershayusjhego probela komandyi poljzovatelya        | 0,061 s      | uspeshno   |
| [Kornevoj pisatelj] Priyomka M1 posle ispravleniya publikacionnyikh predstavlenij i svyaznosti                 | 651,819 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1488,869 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Istochniki

- [Doslovnyiye komandyi i otvetyi](zapros.md).
- [Predyidusjhij prinyatyij etap](../2026-09-10_14-26-58_MSK_proveryatj-sliyaniye-master-v-vedusjhuyu-vetku/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 20:00:59 MSK -->
<!-- content-sha256: sha256:ba5cd495756679fa2ee904419e02e0202d275631d514474c14b170cfe8b2eaa2 -->
<!-- FUM-MD-RECENCY:END -->
