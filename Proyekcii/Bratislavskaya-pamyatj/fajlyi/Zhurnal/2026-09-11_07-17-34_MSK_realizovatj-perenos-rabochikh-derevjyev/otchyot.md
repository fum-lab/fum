# Otchyot 2026-09-11 07:17:34 MSK - Realizovatj perenos rabochikh derevjyev

Realizovan pervyij ogranichennyij instrument FUM-STEP-0207: plan bez zapisi, perenos odnogo linked worktree s rekursivnyimi submodule na odnom tome, sokhranyonnyij avtomat faz i vozobnovleniye otdeljnyim processom. Iskhodniki, otkryityiye fiksturyi i komandyi nakhodyatsya v [tematicheskom instrumente](../../Instrumentyi/fum-perenos-rabochikh-derevjyev/SKILL.md). Primeneniye vyipolnyalosj toljko na vremennyikh lokaljnyikh fiksturakh.

## Profilj vremeni vyipolneniya

| Stadiya                                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                            |
| ---------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------- |
| Soderzhateljnaya rabota                    | ne izmereno  | Chteniye, realizaciya i revjyu; polnogo nepreryivnogo tajmera net                                          |
| Pervyij RED                               | 1,423 s      | Monotonnoye vremya otchyotnoj obyortki: process posle rename i novyij process bez realizacii vosstanovleniya |
| Pervyij GREEN                             | 5,154 s      | Monotonnoye vremya obyortki: avariya, vosstanovleniye i tochnyij povtor                                      |
| Iskhodnyij profilj, tri povtora            | 29,449 s     | Vesj profiljnyij vyizov; vlozhennyiye intervalyi ne pribavlyayutsya povtorno                                   |
| Itogovyiye adresnyiye proverki i smoke-check | sm. nizhe     | Kazhdyij pryamoj zapusk izmeryayet obyortka, vlozhennyiye naboryi sokhranyayut sobstvennyiye granicyi                 |
| Kommit i publikaciya vetki                | ne izmereno  | Vyipolnyayutsya posle zakryitiya priyomki; chteniye rezuljtata vne zakryitogo zhurnala                           |

Granica profilya: pryamyiye proverochnyiye processyi ot zapuska do nablyudyonnogo iskhoda. Vremya analiza i ozhidaniya subagenta ne rekonstruiruyetsya po nastennyim chasam. FIFO i handoff ne ispoljzovalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:e60d9fd294d14ebfb24c450f52300ba2f2101223547d4ab7ce08881273f3c72a -->

| Vyizov                                                                                   | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj 0207] Pervyij RED: vosstanovleniye posle fakticheskogo peremesjheniya                 | 1,423 s      | neuspeshno |
| [Korenj 0207] Vosstanovleniye posle peremesjheniya: pervaya realizaciya                       | 3,43 s       | neuspeshno |
| [Korenj 0207] GREEN: vosstanovleniye razorvannyikh Git-privyazok                            | 5,154 s      | uspeshno   |
| [Korenj 0207] Avtonomnyiye fazyi, otkazyi i sokhrannostj perenosa                            | 5,1 s        | neuspeshno |
| [Korenj 0207] RED: smena polnogo ref pri neizmennom OID                                 | 4,374 s      | neuspeshno |
| [Korenj 0207] GREEN: fazyi, smena ref, otkazyi i sokhrannostj                              | 127,417 s    | uspeshno   |
| [Korenj 0207] Profilj tryokh povtorov perenosa i vosstanovleniya                           | 29,449 s     | uspeshno   |
| [Korenj 0207] Tochnoye imya instrumenta po zakreplyonnomu LinguisticKit                     | 21,481 s     | uspeshno   |
| [Korenj 0207] Itogovaya adresnaya regressiya: 14 kontraktov perenosa                       | 143,291 s    | neuspeshno |
| [Korenj 0207] Regressiya 14 kontraktov posle ispravleniya vyibora otkaznoj fiksturyi        | 139,587 s    | uspeshno   |
| [Korenj 0207] RED: Git-metadannyiye celikom na drugom tome                                | 0,048 s      | neuspeshno |
| [Korenj 0207] RED: otdeljnyij tom vsego administrativnogo poddereva                      | 1,789 s      | uspeshno   |
| [Korenj 0207] RED: soglasovannaya podmena stat, lstat i fstat otdeljnogo toma            | 1,736 s      | neuspeshno |
| [Korenj 0207] GREEN: 15 kontraktov s rannim otkazom administrativnogo toma              | 141,689 s    | uspeshno   |
| [Korenj 0207] Avariya do ustanovki pervichnogo namereniya: sokhranitj ostatok i otkazatj    | 5,873 s      | uspeshno   |
| [Korenj 0207] Zhivoj reyestr nazvanij na izolirovannom zakreplyonnom LinguisticKit         | 1,746 s      | uspeshno   |
| [Korenj 0207] Otsutstviye novyikh latinskikh obyyavlenij v sokhranyonnom ostatke               | 4,31 s       | neuspeshno |
| [Korenj 0207] Itogovyij profilj perenosa posle otkaznyikh dorabotok                        | 30,393 s     | uspeshno   |
| [Korenj 0207] Proveritj pervichnuyu podgotovku posle yavnoj ustanovki vneshnikh funkcij      | 5,803 s      | uspeshno   |
| [Korenj 0207] Proveritj neizmennostj ostatka obyyavlenij posle yavnyikh vneshnikh API         | 2,205 s      | neuspeshno |
| [Korenj 0207] Profilj okonchateljnyikh iskhodnikov: tri povtora oboikh scenariyev             | 29,382 s     | uspeshno   |
| [Korenj 0207] Finaljnaya sverka ostatka obyyavlenij na stabiljnom dereve                  | 4,352 s      | neuspeshno |
| [Korenj 0207] Sravnitj obyyavleniya izmenyonnyikh fajlov s tochnyimi Git-obyyektami osnovyi      | 0,448 s      | uspeshno   |
| [Korenj 0207] Finaljnyij standartnyij smoke-check perenosa rabochikh derevjyev               | 323,636 s    | neuspeshno |
| [Korenj 0207] Adresnaya diagnostika otkaza skanera mashinnyikh putej                        | 21,234 s     | neuspeshno |
| [Korenj 0207] Adresnaya proverka putej posle yavnogo razdeleniya operatora Path            | 21,408 s     | uspeshno   |
| [Korenj 0207] Profilj postavki posle leksicheskoj pravki bez izmeneniya AST               | 29,191 s     | uspeshno   |
| [Korenj 0207] Finaljnyij standartnyij smoke posle ustraneniya leksicheskikh sovpadenij putej | 371,299 s    | neuspeshno |
| [Korenj 0207] Adresnaya proverka granicyi profilya i polnogo spiska izmenyonnyikh putej       | 0,096 s      | neuspeshno |
| [Korenj 0207] Podtverditj granicu profilya i puti po tekusjhemu Git status                 | 0,216 s      | uspeshno   |
| [Korenj 0207] Finaljnaya priyomka posle adresnoj proverki oformleniya Zhurnala              | 968,436 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2445,996 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Pervyij RED dejstviteljno prerval otdeljnyij process posle peremesjheniya kataloga, do remonta metadannyikh. Do ozhidayemogo padeniya novogo processa test podtverdil sokhrannostj iskhodnyikh dannyikh i inode. Sleduyusjhaya realizaciya obnaruzhila razorvannyij `core.worktree` vlozhennogo repozitoriya; chteniye Git v etom okne ispravleno yavnyimi `--git-dir` i `--work-tree`. Pervyij GREEN proveril sokhrannostj dannyikh, OID, refs i indeksov posle vosstanovleniya i tochnyij povtor kvitancii.

Otkryityiye otkaznyiye scenarii okhvatyivayut otnositeljnyiye i absolyutnyiye `.git`/`core.worktree`, nesovpadeniye imeni sekcii i puti submodule, dva urovnya vlozhennosti, staged i rabochiye izmeneniya, ignoriruyemyiye fajlyi, symlink payload i pustyiye katalogi. Otdeljnyiye processyi preryivayutsya do rename, posle nego, pri sokhranenii fazyi, podgotovke/zamene fajlov remonta, pered sverkoj i posle zaversheniya. Proveryayutsya otkaz sinkhronizacii kazhdogo roditelya posle rename, zanyatoye naznacheniye pered sistemnyim vyizovom, konkuriruyusjhij povtor pod postoyannyim `flock`, drejf dannyikh, indeksa, konfiguracii i polnogo symbolic ref dazhe pri tom zhe OID.

Dopolniteljnyij RED revjyu pokazal: vesj administrativnyij katalog na otdeljnom tome mog projti plan. Fikstura soglasovanno podmenyayet `stat`, `lstat` i `fstat` vsego etogo poddereva; prezhnij kod ne otkazal. Dobavlena rannyaya sverka toma kazhdogo Git-dir s common-dir. Eto modelirovaniye granicyi, a ne realjnoye montirovaniye vtorogo toma.

Po otdeljnomu [utochneniyu kornya](zapros.md) prinyat yavnyij otkaz dlya nezavershyonnoj pervichnoj zapisi namereniya. Avarijnyij drajver obryivayet nastoyasjhij vyizov posle sozdaniya `подготовка.tmp` i posle zapisi/fsync yego bajtov do poyavleniya `операция.json`. Novyij process sokhranil pustoj, polnyij libo neizvestnyij khvost i otkazal; iskhodnoye derevo, metadannyiye i identichnostj ne izmenilisj. Avtomaticheskoye vosstanovleniye nachinayetsya posle dolgovechnoj ustanovki `операция.json`. Predshestvuyusjheye okno ne obyyavlyayetsya vozobnovlyayemyim.

Pervyij standartnyij smoke proshyol strukturu, reyestr i nezavisimuyu proverku proyekcii, zatem ostanovilsya na dvukh leksicheskikh sovpadeniyakh putej v `перенос.py`: peregruzhennyij operator `Path /` pered peremennyimi byil zapisan bez probelov. Probelyi dobavlenyi, AST do i posle sovpadayet; politika skanera i dopustimyiye puti ne rasshiryalisj. Posle adresnoj proverki vyipolnyayetsya novyij priyomochnyij progon. Vtoroj smoke uspeshno proshyol pervyiye desyatj live-shagov, zatem svyaznostj potrebovala tochnoye dvoyetochiye stroki granicyi profilya i yavnyiye Markdown-ssyilki na proyekciyu i indeks v perechne zatronutyikh fajlov. Zapisj ispravlena; eti dve granicyi proverenyi adresno do sleduyusjhego standartnogo progona.

Istoriya sokhranyayet vse neuspeshnyiye promezhutochnyiye vyizovyi: trebuyemyiye RED, oshibku sintaksisa novoj fiksturyi, nepolnuyu zamenu imeni testovogo scenariya i oshibochnyij adres odinochnogo unittest. Oni ne podmenyayutsya posleduyusjhimi uspeshnyimi zapuskami. Yazyikovoj skaner snachala schyol prisvaivaniya vneshnim `os.open` i `os.fsync` sobstvennyimi obyyavleniyami; yavnaya ustanovka etikh API cherez `setattr` sokhranyayet ikh vneshnij smyisl. Odin povtor skanirovaniya peresyoksya s pereimenovaniyem kartochki i otkazal na ischeznuvshem starom puti; povtor vyipolnyayetsya na stabiljnom dereve. Polnaya yazyikovaya sverka obnaruzhila unasledovannyij [FUM-SBOJ-0045/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md): 43606 obyyavlenij protiv 43163 v sokhranyonnom snimke. [Sravneniye s tochnyimi Git-obyyektami osnovyi](materialyi/profilj/deljta-obyyavlenij.json) podtverdilo nulevuyu deljtu vsekh izmenyonnyikh podderzhannyikh fajlov; v novom instrumente sobstvennyikh latinskikh obyyavlenij net. Docherneye chteniye Git-obyyektov dopolniteljno svyazalo +443 s izmeneniyami mezhdu poslednej zapisjyu snimka `436909208424595f7151f6febca75f89018c0bcb` i iskhodnoj osnovoj: zhurnaljnyiye materialyi +163, kompleksnaya proverka +23, instrumentyi otchyotov +248, reyestr planirovaniya +6, svyaznostj +3. Eto podschyot AST, istoricheskij SHA vsego inventarya otdeljno ne vosproizvodilsya. Po utochneniyu koordinacii tochnyiye puti i deljtyi peredanyi kornyu; massovyikh ispravlenij etikh fajlov ne vyipolnyalosj. Obsjhaya oshibka ostayotsya v FUM-STEP-0173, snimok ne rasshiren radi dopuska. Polnyiye fakticheskiye iskhodyi dostupnyi v tablice vyishe; samostoyateljnyikh proverochnyikh processov rebyonok ne zapuskal.

## Resheniya i ogranicheniya

Povtorno ispoljzovanyi tochnyiye moduli kanonicheskogo JSON i Git-obyyektov iz `fum-snimki-indeksa` i susjhestvuyusjhij ustojchivyij rename bez zamenyi iz proyekcii. Iz proverki Git-zavisimostej vzyata proverennaya granica shtatnoj administrativnoj topologii; yeyo polnyij validator ne primenyayetsya kak algoritm remonta, poskoljku proveryayet takzhe publikaciyu i chistotu, togda kak perenos dolzhen sokhranyatj lokaljnyiye izmeneniya. Otdeljnyij upravlyayemyij Git-process otklyuchayet vneshnyuyu konfiguraciyu, neobyazateljnyiye blokirovki, fsmonitor, replacement, lazy fetch i setevyiye protokolyi.

Plan soderzhit otnositeljnyiye marshrutyi i khyeshi; tochnyiye fizicheskiye korni i bajtyi remonta ostayutsya v privatnyikh privyazkakh i sostoyanii. Pered kazhdyim remontom sveryayutsya snimki i dopustimyiye bajtyi, neposredstvenno pered zamenoj — staryiye bajtyi fajla. Fazyi i kursor zakreplyayutsya do sootvetstvuyusjhikh effektov, a povtor posle zamenyi zanovo sinkhroniziruyet oba kataloga dazhe pri poteryannom rezuljtate prezhnego `fsync`. Postoyannyij lock-fajl ne zamenyayetsya i ne udalyayetsya.

Iskhodnyij profilj: mediana obyichnogo ispolneniya 2,543 s, vozobnovleniya posle rename 1,859 s, tochnogo povtora okolo 0,41 s. Mediana samogo rename — 0,000415 s; remont — 1,272 s, itogovaya sverka — 0,366 s. [Iskhodnyiye izmereniya](materialyi/profilj/iskhodnyij.json) vklyuchayut tri povtora oboikh scenariyev i SHA-256 iskhodnikov. Optimizaciya kyeshirovaniyem ne prinyata: na etoj maloj fiksture kopirovaniya payload net, a povtornoye chteniye vyiyavlyayet mezhfaznyij drejf. [Profilj posle otkaznyikh dorabotok](materialyi/profilj/okonchateljnyij.json) povtoryayet te zhe usloviya na itogovyikh iskhodnikakh; medianyi sostavili 2,508 s dlya ispolneniya, 1,868 s dlya vozobnovleniya i 0,402 s dlya tochnogo povtora. Uskoreniye ne zayavlyayetsya. [Profilj postavki](materialyi/profilj/postavka.json) povtoryayet izmereniye posle zaklyuchiteljnoj pravki probelov. Vse promezhutochnyiye profili sokhranenyi dlya proiskhozhdeniya.

Podderzhka proverena na macOS arm64, Python 3.14.7 i Git 2.54.0. Linux-primitiv sokhranyon, no eta platforma yesjhyo ne prinyata sobstvennyim zapuskom; Windows i perenos mezhdu tomami ne podderzhanyi. Konkretnyiye ogranicheniya indeksa, konfiguracii, putej i tipov obyyektov perechislenyi v [rukovodstve](../../Instrumentyi/fum-perenos-rabochikh-derevjyev/SKILL.md).

Vladeniye predpolagayet dobrosovestnogo yedinstvennogo pisatelya. Tochnyij UUID v Git-lock i postoyannyij `flock` zasjhisjhayut soglasovannyiye povtoryi etoj operacii, no ne vesj Git i ne namerennogo postoronnego pisatelya. Revjyu rebyonka i nezavisimoye chteniye kornya podtverzhdayut etu granicu; proverka bajtov i `os.replace` ne obrazuyut obsjhuyu atomarnuyu tranzakciyu s chuzhimi processami. Processnyiye avarii ne yavlyayutsya ispyitaniyem otklyucheniya pitaniya.

Ostatok otdeljnoj priyomki realjnogo perenosa: svezhaya topologiya i soglasovannoye vladeniye vyibrannogo dereva, fakticheskij fajlovyij tom, ostanovka pisatelej, novyij marshrut, vneshniye privyazki Codex/Obsidian/sborok i proverka otnositeljnyikh payload symlink posle izmeneniya raspolozheniya. Trebovaniye FUM-REQ-0066 sokhranyayet aktivnyij status dlya etikh srezov. Proyektyi Codex, zhivyiye derevjya, chuzhiye refs i istoricheskij pul ne izmenyalisj.

Soderzhateljnyij otvet na iskhodnoye porucheniye — sokhranyonnaya realizaciya i vosproizvodimyiye proverki; na utochneniye revjyu — adresnyij avarijnyij test s yavnyim sokhraneniyem neizvestnogo podgotoviteljnogo khvosta. [Razovyij perechenj rabotyi](materialyi/planyi/prodolzheniye.json) opisyivayet konechnyij obyyom; yego zavershayusjhaya proverka vyipolnyayetsya posle chteniya kommita i dostavki. Plan sam po sebe ne dokazyivayet publikaciyu. Polnyij nabor dogovoryonnostej sveryon s pervichnyimi delegirovannyimi soobsjheniyami; tekhnicheskiye rekomendacii ne vyidanyi za novyiye komandyi cheloveka.

## Istochniki

- [Iskhodnoye porucheniye i utochneniye revjyu](zapros.md).
- [Postanovka napravleniya](../2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md).
- [FUM-STEP-0207](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0207-realizovatj-perenos-rabochikh-derevjyev.md).
- [FUM-REQ-0066](../../Trebovaniya/🟡-vozobnovlyayemyij-perenos-rabochikh-derevjyev.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:26:56 MSK -->
<!-- content-sha256: sha256:be9286e8733b16b3803867e4a9525bdd3d93ec2c5ad92eff6dc52b5fb5695f70 -->
<!-- FUM-MD-RECENCY:END -->
