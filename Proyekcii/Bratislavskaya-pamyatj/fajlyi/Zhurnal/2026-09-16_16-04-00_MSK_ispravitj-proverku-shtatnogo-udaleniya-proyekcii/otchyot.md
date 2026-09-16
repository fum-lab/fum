# Otchyot 2026-09-16 16:04:00 MSK - Ispravitj proverku shtatnogo udaleniya proyekcii

Ispravlen oshibochnyij otkaz pri shtatnom udalenii neizmenyonnogo fajla odnoj storonoj nastoyasjhego Git-sliyaniya. Osnovnoj kandidat i pervichnyij checkout sokhranenyi. Adresnaya priyomka i profilj opisanyi nizhe. Itog standartnoj priyomki i gotovnostj k kommitu podtverzhdayutsya toljko yeyo poslednej mashinnoj zapisjyu i zakryityim sostoyaniyem otchyota.

## Profilj vremeni vyipolneniya

| Stadiya                | Dliteljnostj           | Granicyi i sposob izmereniya                                                           |
| --------------------- | ---------------------- | ------------------------------------------------------------------------------------ |
| Podgotovka zaprosa    | 0,44385675 s           | Nablyudayemaya dliteljnostj komandyi start                                               |
| Soderzhateljnaya rabota | ne izmereno            | Chteniye, RED/GREEN i nezavisimyij obzor; perekryivayetsya s pryamyimi proverkami            |
| Profilirovaniye        | 26,867731166 s         | Vneshnyaya dliteljnostj obyortki; shestj scenariyev, cProfile 26,295673795 s               |
| Finaljnaya priyomka     | sm. pryamoj zapusk nizhe | Poslednyaya polnaya zapisj soderzhit dliteljnostj standartnogo dokumentacionnogo profilya |

Granica profilya: etap nachat 2026-09-16 16:04:00 MSK; konec okhvachennoj priyomki zadayot poslednyaya polnaya zapisj nizhe; posleduyusjhaya dostavka kommita uchityivayetsya otdeljno. Vnutrenniye shagi ne skladyivayutsya povtorno s pryamyimi zapuskami. FIFO ne primenyalsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:f9e935a99ea772210f178db6fdc7b8c95d1190e77edab3036c25c793a2c2a069 -->

| Vyizov                                                                                            | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------ | ------------ | --------- |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] RED: nastoyasjheye avtomaticheskoye udaleniye proyekcii           | 21,106 s     | neuspeshno |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] GREEN: nastoyasjheye avtomaticheskoye udaleniye proyekcii         | 23,635 s     | neuspeshno |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] GREEN: shestj regressij s sokhranyonnyim gitlink              | 25,184 s     | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Profilj: shestj realjnyikh Git-regressij neizmennogo GREEN   | 26,466 s     | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Regressiya prezhnego konflikta i pozdnej podmenyi stadij     | 9,635 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Sveritj inventarj obyyavlenij predposyilki                  | 0,067 s      | neuspeshno |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Sveritj inventarj obyyavlenij: kanonicheskij CLI            | 4,642 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Obnovitj toljko koordinatyi prezhnego inventarya             | 4,624 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Peresobratj planovyij reyestr predposyilki                   | 0,417 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Obnovitj svezhestj predposyilki                             | 1,375 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Svyaznostj predposyilki pered standartnoj priyomkoj          | 50,984 s     | neuspeshno |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Obnovitj svezhestj posle utochneniya zhurnala                 | 1,311 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Standartnaya priyomka predposyilki: 24 dokumentacionnyikh shaga | 445,907 s    | neuspeshno |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Profilj posle ispravleniya perenosimosti fiksturyi          | 25,563 s     | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Proveritj ispravlennyiye literalyi mashinno-lokaljnyikh putej   | 23,382 s     | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Obnovitj svezhestj posle ispravleniya perenosimosti         | 1,216 s      | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Svyaznostj posle ispravleniya zhurnala i perenosimosti       | 49,127 s     | uspeshno   |
| [01a09047-faa1-7370-83f7-cdfc8f9943a6] Standartnaya priyomka predposyilki: 24 dokumentacionnyikh shaga | 1120,606 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1835,247 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- RED: realjnyiye simmetrichnyiye udaleniya vosproizveli otkaz M na otsutstvii indeksnogo puti; dve otricateljnyiye podmenyi uzhe otklonyalisj. Dva dopolniteljnyikh otricateljnyikh scenariya proveryayut tochnuyu prichinu otkaza posle ispravleniya.
- Pervaya podgotovka CLI obyortki otklonena argparse do zapuska testov: nevernoye polozheniye podkomandyi, 0,083066333 s. Eto ne testovyij RED; diagnosticheskij vyivod sokhranyon privatno.
- GREEN: shestj testov proshli za 25,030 s vnutrennego unittest (25,544544084 s vneshnej obyortki). Rannij GREEN vyiyavil oshibku fiksturyi: obsjhij git add -u snimal otsutstvuyusjhij fizicheski gitlink; podgotovka ogranichena tochnyimi kanonicheskimi putyami, rabochaya realizaciya ne menyalasj.
- Prezhnij nastoyasjhij merge-test s pozdnej podmenoj stadij proshyol: 9,481 s unittest, 10,0813475 s obyortki.
- [Profilj](materialyi/profilj-avtoudaleniya.json): posle ispravleniya perenosimosti fiksturyi polucheno 6/6, novyij helper — 6 vyizovov, 0,155628373 s vklyuchaya Git, sobstvennoye vremya 0,000349041 s. Resheno sokhranitj realizaciyu: okolo 0,613 procenta scenariya ne opravdyivayet dopolniteljnyij kyesh. Pervoye nablyudeniye sokhraneno v tom zhe materiale. Derevjya tryokh istoricheskikh revizij pereispoljzuyutsya; uskoreniye ne zayavlyayetsya.
- [Sverka inventarya](materialyi/sverka-inventarya.json): 46914 → 46914, imena/puti/yazyiki/vidyi polnostjyu sovpadayut; izmenilisj koordinatyi 18 zapisej. Snimok obnovlyon kanonicheskoj avtomatizaciyej. Pervyij CLI-vyizov inventarizacii byil oshibochno sformirovan i otklonyon; ispravlennyij vyizov vyipolnen cherez tu zhe obyortku.
- Pervonachaljnyij standart24 ostanovilsya na shage 7: absolyutnyij vyikhod profilya i dva literala putej testovoj fiksturyi otklonenyi proverkoj mashinno-lokaljnyikh putej. Polnyij UUID 103c164e-e3a0-45fc-817a-a84a8b5cf2ea, obyortka 446,452420125 s; postroyeniye 8098 fajlov 282,069 s, nezavisimaya proverka 112,492 s. Literalyi zamenenyi soyedineniyem komponentov Path, instrukciya profilya prinimayet yavnyij vneshnij putj. Zasjhitnaya politika ne menyalasj.
- Poslednyaya polnaya mashinnaya zapisj i zakryitoye sostoyaniye vyishe zadayut itog povtornoj priyomki; otdeljnyiye zelyonyiye etapyi ne obyyavlyayutsya gotovnostjyu.

## Resheniya i ogranicheniya

- Dopuskayetsya toljko putj, susjhestvovavshij v polnoj bazovoj proyekcii: odna storona udalyayet yego i iz dereva, i iz polnogo manifesta; drugaya sokhranyayet tochnyiye mode/OID osnovyi. Istoricheskiye bajtyi obyazanyi sovpadatj s khyeshami oboikh manifestov.
- AUTO_MERGE, indeks i rabocheye derevo dolzhnyi podtverzhdatj otsutstviye; manifest isklyucheniyu ne podlezhit. Sluchai izmeneniya s udaleniyem, neizvestnyiye fajlyi i ruchnoj drejf sokhranyayut prezhnij otkaz.
- [Pozdnij dialog](materialyi/pozdnij-dialog.md) soderzhit svyazj chetyiryokh komand s otvetami i osnovaniyami. «Ne tuda» otmenyayet vopros o plane dnya; integraciya prodolzhayetsya. Zapros Max ostayotsya aktualjnyim, pereklyucheniye kornya ne podtverzhdeno.
- LinguisticKit materializovan otdeljnyim klonom s sobstvennyim gitdir, origin fum-lab i upstream Roman-Kerimov sinkhronizirovanyi; vyibran chistyij 837e2ce107b97ee7b9d3344c9fe99142281fe393, dostizhimyij iz origin. Pervaya popyitka clone otklonena do zapisi iz-za otsutstvuyusjhego roditeljskogo kataloga gitdir; posle yego sozdaniya klonirovaniye proshlo.
- Posle otdeljnogo proverennogo kommita i publikacii predposyilki ostayutsya dostavka v master, obnovleniye osnovnogo kandidata i yego samostoyateljnaya priyomka.

## Istochniki

- [Iskhodnyij zapros](zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 16:28:53 MSK -->
<!-- content-sha256: sha256:336f9bf96a945cc7587b3d8b7cf348487fb8d0b254dc9e37868d5b0c01ae61ab -->
<!-- FUM-MD-RECENCY:END -->
