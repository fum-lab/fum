# Otchyot 2026-09-16 14:57:36 MSK - Podgotovitj sliyaniye prinyatoj osnovyi i FUMA

PR №4 dostavlen otdeljnyim obyichnyim sliyaniyem G=9efd84ded4e0f47b47aaac4a7464f8c4e5171c8e. Teperj podgotovlen otdeljnyij kandidat ot L14044 dlya prinyatogo M=G; konfliktyi razreshayutsya, C ne prinyat, master etim etapom ne prodvinut.

## Peredannyij rezuljtat PR №4

G imeyet roditelej [9d01af6de4fc2f1c9265ee8805cda4998322e004,08cffcc75c7a9776453b2d7497c1d2d75ca6f994] i derevo ce6975a11886f91cf3933354d470d7c688c80f30. P proshyol 87 shagov vyibrannogo polnogo profilya i zamyikaniye; G sokhranil yego derevo. Svyaznostj G snachala ostanovilasj na otsutstvuyusjhej zavisimosti, zatem posle shtatnogo init LinguisticKit proshla za 52,479647417 s. Dliteljnostj pervogo otkaza ne izmerena.

Tochnyiye obyichnyiye push svoyej vetki i master zavershilisj kodom 0, udalyonnyiye OID podtverzhdenyi. PR №4: closed/merged=true, merge_commit_sha=G, merged_at=2026-09-16T11:46:03Z; draft ostalsya true. Yedinstvennyij primary merge --ff-only G zavershilsya kodom 0 za 0,231966166 s. Zatem HEAD=G/tree=T, checkout i indeks chistyi; graph, obsjhaya konfiguraciya i indeksyi G/P sokhranenyi, zapisj primary prekrasjhena. Privatnyij paket peredachi: SHA-256 40778eb8e3c35dedcbfb8fb78d0e8c2e56aa386ae6e301229d2e4189fe476c5b. Pervichnyiye vyikhodyi push sokhranenyi dopolniteljno bez povtornoj publikacii.

## Pozdnij dialog

[Soobsjheniya, otvetyi i osnovaniya](materialyi/pozdnij-dialog.md) sokhranenyi. Vopros o plane otmenyon sleduyusjhim «Ne tuda.». Zapros Astra Max uchtyon, nativnaya smena kornya ostayotsya nepodtverzhdyonnoj. Uchyot soobsjheniya ne podmenyayet vyipolneniye nastrojki. Vse chetyire sobyitiya sokhranenyi shtatnyim obrabotchikom, ostatok raven nulyu, istochnik polon. Popyitki sokhraneniya bez kyesha i s kyeshem vnutri drugogo Git-dereva otklonenyi; posle razmesjheniya kyesha vne vsekh checkout chetyire sokhraneniya proshli.

## Podgotovka kandidata

Do sozdaniya otdeljnogo worktree zafiksirovanyi M/L, ref, fizicheskij korenj, iskhodnaya komanda, odin pisatelj i kontroljnyiye SHA primary. HEAD=L14044dfd994cf16b5061fb245b18a8e5abf0ac7d, MERGE_HEAD=M9efd84ded4e0f47b47aaac4a7464f8c4e5171c8e. Merge --no-ff --no-commit dal 17 kanonicheskikh i 18 proizvodnyikh konfliktov; eto promezhutochnaya podgotovka, a ne priyomochnyij progon.

Pervyij start Zhurnala ostanovilsya do zapisi na dublirovannoj stroke konfliktnogo indeksa. Dlya kanonicheskogo indeksa vzyata iskhodnaya versiya L, zatem shtatnyij start dobavil novuyu paru i nedostayusjhiye sessii M iz fakticheskogo sostava. Doslovnyiye komandyi sokhranenyi.

## Profilj vremeni vyipolneniya

| Stadiya                    | Dliteljnostj       | Granicyi i sposob izmereniya                       |
| ------------------------- | ------------------ | ------------------------------------------------ |
| Podgotovka merge          | 0,827193667 s      | Vneshnij monotonnyij tajmer; itog — konfliktyi        |
| Pervyij start Zhurnala      | 0,620158042 s      | Vneshnij monotonnyij tajmer; otkaz do zapisi         |
| Povtornyij start Zhurnala   | 0,709700083 s      | Posle vyibora kanonicheskogo indeksa L, itog 0      |
| Razresheniye konfliktov     | ne zaversheno       | Sopostavleniye dvukh proiskhozhdenij i docherniye obzoryi |
| Priyomochnyiye proverki       | yesjhyo ne zapuskalisj | Budut uchtenyi obyazateljnoj obyortkoj M              |

Granica profilya: otdeljnyiye izmereniya podgotovki posle dostavlennogo G; predyidusjhaya priyomka P/G ne summiruyetsya s etim etapom. Obsjhaya dliteljnostj etapa poka ne zavershena.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                 | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------- | ------------ | --------- |
| [Kornevaya zadacha] RED: sovmestimostj pereimenovanij s testami M                       | 0,557 s      | neuspeshno |
| [Kornevaya zadacha] GREEN: sovmestimostj vkhodov M                                       | 11,482 s     | uspeshno   |
| [Kornevaya zadacha] GREEN: sovmestimostj vkhodov L                                       | 10,815 s     | uspeshno   |
| [Kornevaya zadacha] Peresobratj reyestr obyyedinyonnogo planirovaniya                       | 0,508 s      | uspeshno   |
| [Kornevaya zadacha] Plan vosstanovleniya navigacii obyyedinyonnogo Zhurnala                 | 26,047 s     | uspeshno   |
| [Kornevaya zadacha] Vosstanovitj shestj razdelov navigacii po prinyatomu planu            | 0,602 s      | uspeshno   |
| [Kornevaya zadacha] Profilj sovmestimosti prodvizheniya: uspekh i chastichnyij otkaz          | 1,831 s      | uspeshno   |
| [Kornevaya zadacha] Inventarj kandidata ispolnitelem M                                  | 5,652 s      | uspeshno   |
| [Kornevaya zadacha] Obnovitj svezhestj obyyedinyonnogo kanonicheskogo sloya                  | 1,609 s      | neuspeshno |
| [Kornevaya zadacha] Peresobratj indeks svezhesti posle vyibora celoj iskhodnoj metki L     | 1,583 s      | uspeshno   |
| [Kornevaya zadacha] Sokhrannostj chetyiryokh vetvej proyekcii L posle obyyedineniya             | 7,473 s      | uspeshno   |
| [Kornevaya zadacha] Kontrakt snimka M na realizacii kandidata                           | 0,293 s      | uspeshno   |
| [Kornevaya zadacha] Podgotovitj dannyiye sobstvennogo inventarya C bez zapisi snimka       | 6,602 s      | uspeshno   |
| [Kornevaya zadacha] Sveritj iskhodnyiye dannyiye L tem zhe sobstvennyim razborsjhikom C          | 6,203 s      | uspeshno   |
| [Kornevaya zadacha] Publikacionnaya chistota kandidata po zakreplyonnoj politike M         | 34,255 s     | uspeshno   |
| [Kornevaya zadacha] Vosstanovitj konfliktnuyu proyekciyu shtatnyim generatorom M             | 28,303 s     | neuspeshno |
| [Kornevaya zadacha] Sokhranitj svezhestj podgotovlennogo kandidata i svideteljstva otkaza | 1,623 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 145,438 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Tri adresnyikh testa M snachala dali RED: otsutstvovali prezhniye vkhodyi git i SKRIPT_SMOKE. Sovmestimyiye vkhodyi vosstanovlenyi poverkh russkikh realizacij; GREEN podtverdil tri scenariya M i tri sootvetstvuyusjhikh scenariya L, vklyuchaya sokhrannostj chastichno izmenyonnyikh dannyikh pri otkaze. Polnyij vyisokij kontur yesjhyo ne zapuskalsya.

## Resheniya i ogranicheniya

- Soderzhateljnyiye konfliktyi razreshayutsya po oboim istochnikam, Proyekcii peresobirayetsya toljko upravlyayemyim generatorom.
- Pravila, instrumentyi, testyi, fiksturyi i zavisimosti priyomki — iz M; kandidat ne oslablyayet dopusk.
- L14044 ne zamenyayetsya pozdnimi checkpoints fuma. C dolzhen imetj roditelej rovno [L,M]. Prodvizheniye i publikaciya sokhranyayut otdeljnuyu granicu.
- Oshibochnyiye kontroljnyiye vyizovyi guard s absolyutnyim putyom plana i nenulevyimi svideteljstvami dostupnyikh rabot ne razreshali zaversheniye. V lokaljnom plane dostupnyim rabotam vosstanovleno obyazateljnoye null, poyasneniya sokhranenyi otdeljno. Ispravlennyij guard zavershilsya kodom 0: prodolzhitj boljshuyu integraciyu C; zaversheniye zadachi ne dokazano.

## Razresheniye soderzhateljnyikh konfliktov

Proyekciya sokhranyayet obyyedineniye istoricheskikh perekhodov M/L i pozdnyuyu zasjhitu Finder. Perevodchik sokhranyayet vozmozhnosti pereimenovaniya i filjtraciyu L; chetyire scenarnyikh puti M sovpadayut po smyislu. Mashinnaya politika C ravna prinyatoj v M politike kandidata: 447 tochnyikh isklyuchenij, bez izmeneniya proiskhozhdeniya dopuska. STEP0182 sokhranyon iz L: vse kriterii M i dopolniteljnyiye planovyiye razdelyi prisutstvuyut.

Reyestr planirovaniya peresobran ispolnitelem M. Shtatnyij repair-plan predlozhil shestj razdelov navigacii i yesjhyo 25 ssyilok v dvukh dokumentakh. Dlya integracii primenenyi toljko shestj razdelov cherez shtatnyiye funkcii i tranzakciyu M s proverkoj vsekh before/after SHA i neizmennosti teksta zaprosov. Zakryityiye otchyotyi ne izmenenyi.

LinguisticKit materializovan shtatnyim init M za 4,042820958 s; tochnyij gitlink 837e2ce107b97ee7b9d3344c9fe99142281fe393 proveren. Indeksyi primary i kandidata, obsjhaya konfiguraciya i poljzovateljskij graph ostalisj pobajtno prezhnimi.

## Profilj sovmestimogo interfejsa

Vkhod: dva neizmenyonnyikh testa M — uspeshnoye prodvizheniye s povtorom i chastichnyij otkaz read-tree. Realizaciya prodvizheniya posle izmeneniya: SHA-256 6e3da27f919043bf7f38415948a1511108694cb003ca602e5e9ef1edfac62aed; Python 3.14.7, lokaljnyiye vremennyiye Git-fiksturyi vne checkout. Kontur posle dobavleniya konstantyi: SHA-256 928f1eab473201c75660b58489c50ab73552e7467a79411382640201d502f68a. Kriterij — nakladnyiye raskhodyi sovmestimogo vyizova i otsutstviye lishnikh Git-vyizovov na etikh scenariyakh.

Oba testa proshli za 1,718 s. cProfile: obyortka git vyizvana 114 raz, sobstvennoye vremya 0,000338292 s; vyipolnitj_git takzhe vyizvana 114 raz. Kazhdyij sovmestimyij vyizov delegiruyetsya rovno odin raz. Osnovnoye vremya prikhoditsya na processyi Git. Dopolniteljnaya optimizaciya ne opravdana: dinamicheskij vyizov nuzhen dlya sovmestimosti obeikh tochek podmenyi pri testirovanii otkazov. Realizaciya sokhranena, uskoreniye ne zayavlyayetsya.

## Dopolniteljnyiye rezuljtatyi podgotovki

Vosemj adresnyikh regressij podtverdili sokhrannostj chetyiryokh perekhodov L: pozdnego fajla Finder, kartyi avtorov, scenariyev otveta i obyyedinyonnyikh formatov. Proverka mashinno-lokaljnyikh putej ispolnitelem M s zakreplyonnoj politikoj kandidata proshla. Pervyij recency otkazal na konfliktnoj metke samogo indeksa; posle vyibora celoj iskhodnoj metki L shtatnaya peresborka proshla i sokhranila obyyedinyonnyij sostav.

[Sverka inventarej](materialyi/sverka-inventarej.json) razdelyayet ispolnitelej. M→C: 46 767, deljta sostava −320/+173; proiskhozhdeniye vsekh dobavlenij ustanovleno. Tot zhe sobstvennyij ispolnitelj L na dannyikh L i C dayot 46 247 i 46 252: rovno pyatj prezhnikh interfejsov M. Sokhranyonnyij L-snimok 43 091 ustarel yesjhyo do sliyaniya; 3 156 dopolniteljnyikh zapisej prinadlezhat posleduyusjhim izmeneniyam L. Tochnoye poimyonnoye raspredeleniye istoricheskogo rosta na 17 Python-zapisej ne ustanovleno. Dannyiye kandidata ne schitayutsya prinimayusjhim konturom M; novyij kanonicheskij snimok poka ne zapisan.

## Otkaz vosstanovleniya proyekcii

Yedinstvennaya popyitka shtatnogo primeneniya M otkazala do izmeneniya pokoleniya. [Pervichnoye svideteljstvo](materialyi/otkaz-vosstanovleniya-proyekcii.json) svyazyivayet zapusk s tochnyimi M/L, iskhodnyim blob i indeksom. Staryij aktivnyij putj STEP0175 odinakov v obsjhej osnove i M, no udalyon L; obyichnoye sliyaniye Git udalilo yego iz indeksa i AUTO_MERGE. Ispolnitelj M trebuyet obyyedineniye vsekh putej roditeljskikh manifestov i otklonyayet otsutstvuyusjhij staryij putj.

Polnaya proverka iz 24 shagov ne zapuskalasj, proyekciya ne prinyata. Vse 17 kanonicheskikh konfliktov postavlenyi v indeks; 18 konfliktov Proyekcii sokhranenyi bez ruchnogo razresheniya. Khyeshi vsego indeksa proyekcii i fizicheskogo manifesta do i posle otkaza sovpadayut. Read-only obzor podtverdil otsutstviye drugogo dopustimogo marshruta M. [Granica neobkhodimoj predposyilki](materialyi/granica-predposyilki-avtoudaleniya.md) podgotovlena dlya otdeljnogo naznacheniya pisatelya. Sam kandidat ne rasshiryayet prinimayusjhij dopusk.

## Istochniki

- [Komandyi i granica etapa](zapros.md).
- [Prinyatyij otchyot P](../2026-09-16_02-50-47_MSK_splanirovatj-vosstanovleniye-kontrolya-ostatka/otchyot.md).
- [PR №4](https://github.com/fum-lab/fum/pull/4).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 15:53:10 MSK -->
<!-- content-sha256: sha256:036a2348a03c0c12309ced33c384410b2513fd22c3b465d3a5fc53587abc7ec8 -->
<!-- FUM-MD-RECENCY:END -->
