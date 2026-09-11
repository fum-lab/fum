# Otchyot 2026-09-10 20:23:26 MSK - Proveritj sliyaniye posle dopuska

Podgotovleno obyyedineniye sokhranyonnogo C1 `436909208424595f7151f6febca75f89018c0bcb` s prinyatyim M1 `7ce8d9b8bf23c619badf30f643203f70fa1fa1ae`. M1 uzhe proshyol standartnyij kontur iz 24 shagov i 669 testov; yego zakryityij otchyot svyazan s fakticheskim kommitom. Eti rezuljtatyi ne podmenyayut otdeljnuyu proverku obyyedinyonnogo kandidata.

Kod obyyedinilsya bez konfliktov. Vosemj kanonicheskikh konfliktov otnosyatsya k navigacii zhurnala, indeksam, metkam svezhesti i opisaniyu granicyi kommita. Soderzhateljnaya formulirovka granicyi vzyata iz M1; opisaniya v4 sokhranenyi s yavnoj granicej tekusjhego v3-dopuska. Devyatj proizvodnyikh konfliktov ostavlenyi shtatnomu generatoru bez ruchnogo izmeneniya yego vyivoda. Zhurnaljnaya cepochka obyyedinyayet C1 i M1 v poryadke vremeni, sokhranyaya doslovnyiye komandyi.

Nezavisimyij staticheskij razbor podtverdil sokhrannostj M1 pre/post-proverok i metki fakticheskogo ispolneniya v obyyedinyonnoj obyortke, a takzhe pobajtnuyu identichnostj adaptera, zakryitogo chitatelya i kontrollera proiskhozhdeniya sootvetstvuyusjhim Git-obyyektam M1. Testyi etim razborom ne zapuskalisj. Vozmozhnostj v4 sokhranena kak otdeljnyij rezhim; vyisokij dopusk tekusjhego sliyaniya prinimayet toljko v3.

## Iskhodnoye pokoleniye proyekcii

Pervaya shtatnaya popyitka ostanovilasj do ustanovki pokoleniya: nulevaya stadiya Git dlya avtomaticheski obyyedinyonnogo testa proyekcii ne sovpala ni s odnoj versiyej roditeljskikh manifestov. Avtomaticheskoye sliyaniye i indeks sokhranenyi kak svideteljstvo vne checkout; neuspeshnyij zapusk ostayotsya v zhurnale. Dlya povtornoj sborki sredstvami Git vyibrano celoye sokhranyonnoye pokoleniye C1, bez izmeneniya bajtov yego fajlov vruchnuyu. Kanonicheskiye obyyedinyonnyiye iskhodniki sokhranenyi; shtatnyij generator sozdayot novoye pokoleniye iz nikh. Proveryayusjhij kod i yego politika ne oslablyayutsya.

## Proverennyij perekhod bez istoricheskoj ocheredi

Najdenyi i pereispoljzovanyi granicyi susjhestvuyusjhego resheniya, no gotovogo samostoyateljnogo perekhoda v M1 ne okazalosj. Ispolnitelj i yego testyi razmesjhenyi v tematicheskom instrumente otchyotov; v materialakh etogo etapa ostayutsya toljko yego iskhodnaya versiya dlya sravneniya i profilj. On ne zapuskayet ocheredj ili pul. Do izmeneniya checkout CLI vyizyivayet vyisokij chitatelj M, zatem otdeljno uderzhivayet proverku HEAD i CAS master iz susjhestvuyusjhego linked worktree.

Pervyij RED na Apple Git 2.54.0 pokazal, chto sovmestitj symref-verify HEAD s obnovleniyem yego referent neljzya iz-za povtornogo obnovleniya HEAD. Proverka aljternativnogo imeni main-worktree/HEAD takzhe otkazala: eto imya ne prinyato dlya dannoj zapisyivayusjhej tranzakcii. Okonchateljnaya forma ispoljzuyet dve podgotovlennyiye tranzakcii s razdeljnyimi zadachami: read-only HEAD guard v primary i yedinstvennyij update master C M iz candidate. Oba prepare zavershayutsya do izmeneniya checkout; guard ostayotsya do readback.

Chetyire dopolniteljnyikh RED podtverdili propuski ignored attributes, izmenyonnyikh bajtov zavisimosti, symlink samoj zavisimosti i pustogo Git-poddereva. Oni zakryityi do zapisi intent libo prodvizheniya. Posle ispravlenij 16 scenariyev proshli za 11,443 s; rasshirennyiye 19 scenariyev s realjnyim HEAD.lock i granicej CLI — za 13,820 s. Nachaljnyij oshibochnyij vyizov diagnosticheskoj obyortki bez klyucha nabora ostanovilsya do zapuska testov; argumentyi dopolnenyi. Neuspekhi ne udalyayutsya iz istorii.

[Iskhodnyij profilj](materialyi/profilj-perekhoda-do.json) pokazal 41 process Git i medianu 529,777 ms. [Semj chereduyusjhikhsya par](materialyi/profilj-perekhoda-posle.json) na odnoj vremennoj fiksture dali 41 → 35 processov i 482,590 → 408,782 ms. Sopostavlennyiye rezuljtatyi sovpali, krome zakonomernogo khyesha versii ispolnitelya. Optimizaciya sokhranyayet toljko metadannyiye neizmenyayemyikh obyyektov polnogo OID v ramkakh odnogo vyizova; rabochiye fajlyi i indeks perechityivayutsya. Eto sinteticheskij profilj, ne vremya perekhoda vsego FUM; CPU dochernikh processov i pamyatj ne izmerenyi.

Proyekciya 6406 iskhodnyikh fajlov uspeshno perestroyena iz celogo pokoleniya C1 za 227,181 s. Eto otdeljnaya podgotoviteljnaya sborka; itogovyij polnyij progon i zamyikaniye dolzhnyi uchityivatj dobavlennyiye pozdneye iskhodniki ispolnitelya i svideteljstva.

Okonchateljnaya versiya proshla 20 scenariyev za 14,893 s. Dopolniteljnyij RED vosproizvyol otsutstviye lokaljnyikh user.name/email pri zadannoj globaljnoj identichnosti — fakticheskuyu konfiguraciyu primary. Teperj imya i pochta chitayutsya kak dannyiye do intent i peredayutsya toljko dvum tranzakciyam; ostaljnyiye globaljnyiye nastrojki ne vklyuchayutsya. Povtornyij nezavisimyij prosmotr etoj deljtyi blokerov ne obnaruzhil. [Itogovyij profilj](materialyi/profilj-perekhoda-itog.json) poluchen posle perenosa koda v tematicheskij katalog i vklyuchayet etu popravku. Predyidusjhij parnyij profilj izmeryal vsyu togdashnyuyu deljtu, vklyuchaya casefold attributes i uskorennuyu proverku pustyikh podderevjyev, a ne izolirovannuyu stoimostj odnogo kyesha.

Predvariteljnyij validator pravil obnaruzhil prevyisheniye predela kompaktnosti kornya posle sliyaniya; formulirovki sokrasjhenyi s sokhraneniyem norm i identifikatorov, bez povyisheniya limita. Proverka svyaznosti takzhe vyiyavila otsutstviye tochnoj metki granicyi profilya i ssyilki na fakticheski ispoljzovannyij instrument moskovskogo vremeni. Ssyilka podtverzhdena iskhodnyim JSONL; oformleniye ispravleno. Eti otkazyi sokhranenyi v mashinnom otchyote.

Proverka probelov obnaruzhila sokhranyonnyij probel iskhodnoj komandyi i yeyo avtomaticheskoj proyekcii, a takzhe iskhodnyiye probelyi i konechnyiye pustyiye stroki tryokh arkhivnyikh response.body.html. Pervichnyiye bajtyi ne ispravlyayutsya radi stilya. Dlya etikh tochnyikh putej proverka vyipolnyayetsya s parametrami odnogo vyizova Git, otklyuchayusjhimi toljko sootvetstvuyusjhiye probeljnyiye preduprezhdeniya; ostaljnyiye puti proveryayutsya obyichno. Nastrojki Git repozitoriya ne menyayutsya.

## Sovmestimostj podgotovki preobrazovatelya

Pervyij polnyij M1-on-C progon 98cc7213-0e4e-4f35-8a92-fddc1d97f523 ostanovilsya na shage 12 za 492,836 s: 110 iz 111 testov proyekcii proshli, odin obnaruzhil izmeneniye kontrakta helper. Podgotovka pokoleniya 6465 fajlov proshla za 216,678 s, nezavisimyij manifest — za 107,156 s. Eti uspekhi ne oznachayut priyomku vsego kandidata.

Neizmenyonnyij test M1 ozhidal izolyaciyu iskhodnikov i otlozhennuyu komandu Swift, a C1 srazu sobiral binarnik. Nepolnyij testovyij Package.swift poetomu popal v realjnyij kompilyator. Tochnyij scenarij povtorno dal RED za 3,693 s; eto vosproizvodimaya nesovmestimostj API, ne sluchajnyij sboj Swift. Otdeljnyij RED yavnogo parametra kyeshirovaniya zavershilsya za 0,200 s.

Sokhranyon prezhnij odnoparametricheskij API; novyij keyword-only parametr ispoljzovatj_kyesh=False vyibirayet otlozhennuyu podgotovku. Rabochij generator yavno peredayot True i sokhranyayet sborku, proverennyij kyesh i chastnuyu kopiyu ispolnyayemoj sredyi. Vetka vyibora ne smotrit na testyi ili soderzhimoye Package.swift. Iskhodnyij test M1 ne menyalsya i proshyol za 0,330 s; kyeshirovannyij scenarij — za 0,401 s. Realjnaya otlozhennaya komanda na minimaljnom korrektnom Swift-pakete proshla za 4,266 s; proverka zapresjhayet skryituyu predvariteljnuyu sborku i sozdaniye kyesha. Nezavisimyij razbor maloj deljtyi ne nashyol obkhoda granic.

[Semj par profilya podgotovki](materialyi/profilj-sovmestimosti-podgotovki.json) sopostavlyayut C1 i ispravlennyij yavnyij rezhim: kholodnaya podgotovka 160,089 → 159,575 ms, povtornaya 131,529 → 130,834 ms. V obeikh versiyakh na dva vkhoda prikhoditsya odna sborka, bajtyi chastnogo produkta sovpali. Produkt i svedeniya instrumentariya sinteticheskiye; profilj ne izmeryayet kompilyator, pamyatj ili CPU dochernikh processov. Novogo uzkogo mesta po etomu izmereniyu ne obnaruzheno, susjhestvuyusjhaya optimizaciya sokhranena. [Scenarij](materialyi/izmeritj-sovmestimostj-podgotovki.py) chitayet baseline iz tochnogo C1 i ne trebuyet otdeljnoj kopii iskhodnikov vne monorepozitoriya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| ------ | ------------ | ------------------------- |
| Podgotovka sliyaniya i razresheniye konfliktov | ne izmereno | Nachalo etapa zafiksirovano v 20:23:26 MSK; nepreryivnyij sekundomer analiza ne zapuskalsya |
| Pryamyiye proverki | uchtenyi nizhe | Monotonnoye vremya otchyotnoj obyortki; vlozhennyiye shagi ne summiruyutsya vtoroj raz |

Granica profilya: ot podgotovki sliyaniya v 20:23:26 MSK do zakryitiya mashinnogo otchyota etogo etapa; finaljnoye zamyikaniye uchityivayetsya otdeljno. Prinyatyiye prezhniye 200–204 s primeneniya proyekcii otnosyatsya k menjshemu obyyomu M1; izmereniya kandidata sokhranyayutsya otdeljno. FIFO, drugiye pishusjhiye zadachi i publikaciya ne zapuskayutsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:349039230143798cd4dc75d46c9dd9351faf743302aaeae978980c2eaeaa513b -->

| Vyizov                                                                                    | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------------------- | ------------ | --------- |
| [Kornevaya zadacha] Obnovitj svezhestj obyyedinyonnyikh kanonicheskikh dokumentov                 | 1,163 s      | uspeshno   |
| [Kornevaya zadacha] Sobratj reyestr obyyedinyonnyikh planov                                     | 0,394 s      | uspeshno   |
| [Kornevaya zadacha] Razreshitj proizvodnyiye konfliktyi shtatnoj peresborkoj                    | 8,051 s      | neuspeshno |
| [Kornevaya zadacha] Obnovitj svezhestj posle sokhraneniya otkaza generatora                   | 1,077 s      | uspeshno   |
| [Kornevaya zadacha] Peresobratj proyekciyu iz celogo pokoleniya C1                            | 227,181 s    | uspeshno   |
| [Kornevaya zadacha] Proveritj otdeljnyij perekhod master na vremennyikh Git-repozitoriyakh       | 6,537 s      | neuspeshno |
| [Kornevaya zadacha] Utochnitj prichinu otkaza Git-tranzakcii                                 | 0,646 s      | neuspeshno |
| [Kornevaya zadacha] Vosproizvesti granicyi otkaza novogo perekhoda                           | 2,65 s       | neuspeshno |
| [Kornevaya zadacha] Proveritj perekhod cherez kontekst linked worktree                       | 9,832 s      | neuspeshno |
| [Kornevaya zadacha] Proveritj otdeljnuyu blokirovku HEAD i prodvizheniye master               | 11,531 s     | uspeshno   |
| [Kornevaya zadacha] Zavershitj adresnuyu proverku uzkogo perekhoda master                     | 13,904 s     | uspeshno   |
| [Kornevaya zadacha] Izmeritj iskhodnyij samostoyateljnyij perekhod master                       | 4,275 s      | uspeshno   |
| [Kornevaya zadacha] Sravnitj perekhod do i posle sokrasjheniya chtenij Git-obyyektov             | 6,888 s      | uspeshno   |
| [Kornevaya zadacha] Sokhranitj pervichnyij istochnik Git 1                                     | 0,514 s      | uspeshno   |
| [Kornevaya zadacha] Sokhranitj pervichnyij istochnik Git 2                                     | 1,838 s      | uspeshno   |
| [Kornevaya zadacha] Sokhranitj pervichnyij istochnik Git 3                                     | 1,589 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj okonchateljnyij ispolnitelj prodvizheniya master                 | 13,419 s     | uspeshno   |
| [Kornevaya zadacha] Vosproizvesti realjnuyu konfiguraciyu Git bez lokaljnoj identichnosti     | 1,091 s      | neuspeshno |
| [Kornevaya zadacha] Prinyatj okonchateljnuyu realizaciyu perekhoda master                       | 14,979 s     | uspeshno   |
| [Kornevaya zadacha] Podtverditj profilj okonchateljnogo perekhoda s sokhraneniyem identichnosti | 7,004 s      | uspeshno   |
| [Kornevaya zadacha] Obnovitj svezhestj kandidata                                            | 1,02 s       | uspeshno   |
| [Kornevaya zadacha] Sobratj reyestr planirovaniya kandidata                                  | 0,364 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj dekompoziciyu pravil kandidata                                | 0,059 s      | neuspeshno |
| [Kornevaya zadacha] Proveritj mashinnyiye puti kandidata po politike master                   | 21,085 s     | uspeshno   |
| [Kornevaya zadacha] Proveritj svyaznostj opisaniya sliyaniya                                   | 36,083 s     | neuspeshno |
| [Kornevaya zadacha] Proveritj sokrasjhyonnoye yadro pravil kandidata                            | 0,104 s      | uspeshno   |
| [Kornevaya zadacha] Obnovitj metki okonchateljnogo opisaniya kandidata                       | 0,969 s      | uspeshno   |
| [Kornevaya zadacha] Podtverditj svyaznostj ispravlennogo opisaniya sliyaniya                   | 37,196 s     | uspeshno   |
| [Kornevaya zadacha] Obnovitj metki posle sokhraneniya polnogo zapreta vneshnikh navyikov        | 1,039 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj okonchateljnuyu redakciyu pravil i probelyi indeksa              | 0,241 s      | neuspeshno |
| [Kornevaya zadacha] Soglasovatj metki otchyota pered priyomkoj                                | 0,964 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj probelyi s sokhraneniyem pervichnyikh bajtov                       | 0,153 s      | uspeshno   |
| [Kornevaya zadacha] Podgotovitj svideteljstvo proiskhozhdeniya polnoj priyomki                 | 0,801 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj kandidat sliyaniya                                             | 494,25 s     | neuspeshno |
| [Kornevaya zadacha] Vosproizvesti nesovmestimostj podgotovki preobrazovatelya               | 4,105 s      | neuspeshno |
| [Kornevaya zadacha] Zafiksirovatj yavnyij vyibor kyeshirovannoj podgotovki                      | 0,603 s      | neuspeshno |
| [Kornevaya zadacha] Podtverditj prezhnij kontrakt podgotovki neizmenyonnyim testom master     | 0,77 s       | uspeshno   |
| [Kornevaya zadacha] Podtverditj yavnuyu kyeshirovannuyu podgotovku                              | 0,8 s        | uspeshno   |
| [Kornevaya zadacha] Sopostavitj profilj sovmestimoj podgotovki s prezhnim kyeshem             | 7,582 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj realjnoye ispolneniye prezhnej komandyi podgotovki               | 4,695 s      | uspeshno   |
| [Kornevaya zadacha] Obnovitj metki sovmestimogo kandidata                                  | 0,978 s      | uspeshno   |
| [Kornevaya zadacha] Proveritj indeks posle vosstanovleniya sovmestimosti                    | 0,163 s      | uspeshno   |
| [Kornevaya zadacha] Svyazatj ispravlennyij kandidat s povtornoj polnoj priyomkoj              | 0,763 s      | uspeshno   |
| [Kornevaya zadacha] Povtorno proveritj sovmestimyij kandidat sliyaniya                        | 705,854 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1655,204 s.

Ekonomnyij poryadok proverok: gotov.
Otdeljnaya diagnosticheskaya proverka: 6,537 s; rezuljtat: neuspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/test_prodvizheniye_master.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 0,646 s; rezuljtat: neuspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/test_prodvizheniye_master.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 2,65 s; rezuljtat: neuspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/test_prodvizheniye_master.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 9,832 s; rezuljtat: neuspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/test_prodvizheniye_master.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 11,531 s; rezuljtat: uspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/test_prodvizheniye_master.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 13,904 s; rezuljtat: uspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/test_prodvizheniye_master.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 4,275 s; rezuljtat: uspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/izmeritj-prodvizheniye.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 6,888 s; rezuljtat: uspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/izmeritj-prodvizheniye.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 13,419 s; rezuljtat: uspeshno; naboryi: Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/tests/test_prodvizheniye_prinyatogo_sliyaniya.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 1,091 s; rezuljtat: neuspeshno; naboryi: Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/tests/test_prodvizheniye_prinyatogo_sliyaniya.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 14,979 s; rezuljtat: uspeshno; naboryi: Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/tests/test_prodvizheniye_prinyatogo_sliyaniya.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.
Otdeljnaya diagnosticheskaya proverka: 7,004 s; rezuljtat: uspeshno; naboryi: Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/materialyi/izmeritj-prodvizheniye.py; osnovaniye: ne_pokryivayetsya_finaljnoj_kompleksnoj_proverkoj.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Rezuljtat kazhdogo pryamogo vyizova otrazhayetsya v upravlyayemom bloke. Okonchateljnoye podtverzhdeniye trebuyet poslednego uspeshnogo polnogo zapuska M1, gotovogo zakryitogo snimka, neizmennogo svideteljstva proiskhozhdeniya i nezavisimogo chteniya fakticheskogo merge-kommita s tochnyimi roditelyami `[C1, M1]`. Podgotovlennaya storona merge i otvet subagenta uspekhom priyomki ne schitayutsya.

## Resheniya i ogranicheniya

Pervichnyij checkout, indeks i master sokhranyayutsya na M1 vo vremya podgotovki kandidata. Prezhniye nezakommichennyiye izmeneniya voshli v M1; otdeljnyiye proverennyiye rezervnyiye snimki takzhe sokhranenyi. Prodvizheniye master yavlyayetsya sleduyusjhim dejstviyem toljko posle proverki fakticheskogo C2 i mekhanizma soglasovannogo fast-forward s ozhidayemyim prezhnim M1. Vtoroye sliyaniye i publikaciya ne sozdayutsya.

Posle integracii ostayutsya [FUM-STEP-0177 — vkhod neobrabotannyikh soobsjhenij](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md), zatem [FUM-STEP-0176 — perenos sobstvennoj realizacii v FUM](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md). Oni ne schitayutsya vyipolnennyimi po etomu otchyotu. Ostaljnyiye obyazateljstva prodolzhayut khranitjsya v planirovanii i iskhodnoj istorii.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [prinyatyij M1](../2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/otchyot.md)
- [sokhranyonnyij C1](../2026-09-10_15-09-56_MSK_vlitj-master-v-vedusjhuyu-vetku/otchyot.md)
- [doverennaya procedura proverki](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/proverka-sliyaniya-iz-master.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:7c10549f39646512802e94a48ccdcdb579c7c41b862abef1233556ccaf2fe9f5 -->
<!-- FUM-MD-RECENCY:END -->
