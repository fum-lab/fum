# Otchyot 2026-09-10 15:09:56 MSK - Vlitj master v vedusjhuyu vetku

Podgotovleno nastoyasjheye sliyaniye prinyatogo master M v otdeljnuyu vetku ot vedusjhej L. Dlya sokhraneniya rezuljtata fiksiruyetsya neprinyatyij kandidat C1 s roditelyami [L, M]. Vse konfliktnyiye stadii razreshenyi; indeksyi i proyekciya vosstanovlenyi avtomatizaciyami M. Eto sokhraneniye podgotovlennoj rabotyi, dopuska v master yesjhyo net.

## Profilj vremeni vyipolneniya

| Stadiya                               | Dliteljnostj | Granicyi i sposob izmereniya                                                              |
| ------------------------------------ | ------------ | --------------------------------------------------------------------------------------- |
| Podgotovka dereva i analiz sliyaniya   | ne izmereno  | Nablyudeniya do sozdaniya etoj papki sokhranenyi v protokole; nepreryivnoye vremya ne snimalosj |
| Razresheniye soderzhateljnyikh konfliktov | ne izmereno  | Ot pervogo merge do podgotovki proveryayemogo kandidata                                   |
| Pryamyiye proverki                      | uchtenyi nizhe  | Toljko processyi cherez otchyotnuyu obyortku iz M                                             |

Granica profilya: podgotovka nachalasj posle prinyatiya 6bd676e2; papka Zhurnala sozdana po nablyudyonnoj pare 2026-09-10 15:09:56 MSK. Tochnoye vremya processov uchityivayetsya nizhe pri ikh zapuske; analiz i Git-operacii ne poluchayut vyimyishlennyikh dliteljnostej. Vlozhennyiye proverki ne summiruyutsya povtorno. FIFO, handoff, push i prodvizheniye master ne vyipolnyalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:9f829b1fe587cbb28fc064269f3f48d933605dd7bd4ce9b59d2e5ae988272ca4 -->

| Vyizov                                                                                                  | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------------ | ------------ | --------- |
| [Kornevoj pisatelj] RED: prinyatyiye proverki sokhraneniya Finder protiv iskhodnogo generatora vedusjhej vetki | 2,328 s      | neuspeshno |
| [Kornevoj pisatelj] Profilj do soglasovaniya Finder na publichnoj fiksture M                             | 1,256 s      | uspeshno   |
| [Kornevoj pisatelj] GREEN: prinyatyiye proverki sokhraneniya Finder protiv obyyedinyonnogo generatora         | 5,251 s      | uspeshno   |
| [Kornevoj pisatelj] Profilj posle soglasovaniya Finder na toj zhe publichnoj fiksture M                   | 1,875 s      | uspeshno   |
| [Kornevoj pisatelj] Semj prinyatyikh scenariyev Finder iz M protiv generatora kandidata                    | 17,526 s     | uspeshno   |
| [Kornevoj pisatelj] Kontrolj profilya na prinyatom M s temi zhe trebovaniyami sokhraneniya Finder            | 1,902 s      | uspeshno   |
| [Kornevoj pisatelj] Diagnostika sokhranyonnyikh scenariyev L i otmenyi ignore v obyyedinyonnom kode            | 11,625 s     | uspeshno   |
| [Kornevoj pisatelj] RED sovmestimosti norm L na validatore M                                           | 0,317 s      | neuspeshno |
| [Kornevoj pisatelj] Obyyedinyonnyiye regressii dekompozicii M i L                                          | 1,927 s      | uspeshno   |
| [Kornevoj pisatelj] Struktura obyyedinyonnyikh norm validatorom M                                          | 0,103 s      | uspeshno   |
| [Kornevoj pisatelj] Profilj dekompozicii na obsjhej fiksture M                                           | 0,731 s      | uspeshno   |
| [Kornevoj pisatelj] RED smeshannogo DAG obyazateljstv na module M                                        | 1,571 s      | neuspeshno |
| [Kornevoj pisatelj] Smeshannyij DAG obyazateljstv posle soglasovaniya                                      | 6,228 s      | uspeshno   |
| [Kornevoj pisatelj] Ograzhdeniye istoricheskogo avtokonvejyera v obyyedinyonnyikh normakh                       | 0,124 s      | neuspeshno |
| [Kornevoj pisatelj] Regressii v3 posle soglasovaniya istorii v2                                         | 0,088 s      | uspeshno   |
| [Kornevoj pisatelj] Unittest discovery chetyirnadcati regressij v3                                       | 26,451 s     | uspeshno   |
| [Kornevoj pisatelj] RED izolirovannogo guard na chastichnom v3                                           | 1,277 s      | neuspeshno |
| [Kornevoj pisatelj] RED istoricheskogo dvojnogo perevoda stroki v komande                               | 1,714 s      | neuspeshno |
| [Kornevoj pisatelj] Smeshannaya istoriya, oformleniye komand i izolirovannyij guard                         | 15,203 s     | uspeshno   |
| [Kornevoj pisatelj] RED polnogo sostava zavisimostej Stop-komplekta                                    | 0,667 s      | neuspeshno |
| [Kornevoj pisatelj] RED pozdnego poyavleniya reyestra pri starom plane                                    | 0,653 s      | neuspeshno |
| [Kornevoj pisatelj] RED: pozdneye poyavleniye reyestra posle dejstviteljnogo resheniya starogo plana         | 0,563 s      | neuspeshno |
| [Kornevoj pisatelj] Smeshannaya istoriya i stabiljnostj istoricheskogo plana                               | 15,64 s      | uspeshno   |
| [Kornevoj pisatelj] Polnyij komplekt zaversheniya s obeimi versiyami reyestra                               | 12,979 s     | neuspeshno |
| [Kornevoj pisatelj] Polnyij vosjmifajlovyij komplekt zaversheniya                                          | 20,467 s     | uspeshno   |
| [Kornevoj pisatelj] Sokhraneniye istoricheskogo reyestra vtoroj versii                                     | 28,976 s     | uspeshno   |
| [Kornevoj pisatelj] Shestj scenariyev integracii proverki zaversheniya                                     | 5,803 s      | uspeshno   |
| [Kornevoj pisatelj] Otchyotnaya obyortka s otdeljnyimi formatami staroj priyomki i raundov                   | 56,167 s     | uspeshno   |
| [Kornevoj pisatelj] Stabiljnostj istoricheskikh vkhodov s sokhraneniyem UTF-8                               | 15,842 s     | uspeshno   |
| [Kornevoj pisatelj] Soglasovannoye ograzhdeniye istoricheskogo konvejyera                                   | 0,249 s      | uspeshno   |
| [Kornevoj pisatelj] Sravneniye polnogo CLI chitatelya ostatka M i kandidata                               | 0,112 s      | neuspeshno |
| [Kornevoj pisatelj] Sravneniye chitatelej s podderzhivayemyim obeimi versiyami CLI                           | 7,108 s      | uspeshno   |
| [Kornevoj pisatelj] Profilj realjnyikh komplektov vedusjhej i kandidata bez ustanovki                      | 29,585 s     | uspeshno   |
| [Kornevoj pisatelj] Povtor profilya dekompozicii s okonchateljnyimi imenami izmeritelya                    | 0,617 s      | uspeshno   |
| [Kornevoj pisatelj] Profilj prezhnego reyestra na sta kommitakh posle perenosa fiksturyi                   | 12,73 s      | uspeshno   |
| [Kornevoj pisatelj] Proverka kanonicheskikh norm kandidata validatorom M                                 | 0,106 s      | uspeshno   |
| [Kornevoj pisatelj] Publikacionnaya chistota obyyedinyonnyikh iskhodnikov                                     | 0,174 s      | neuspeshno |
| [Kornevoj pisatelj] Inventarj obyyavlenij obyyedinyonnogo koda                                            | 3,855 s      | uspeshno   |
| [Kornevoj pisatelj] Obnaruzheniye pereimenovannoj kirillicheskoj regressii metadannyikh                     | 0,23 s       | uspeshno   |
| [Kornevoj pisatelj] Vosstanovleniye konfliktnoj proyekcii generatorom M                                  | 182,903 s    | neuspeshno |
| [Kornevoj pisatelj] Predvariteljnaya klassifikaciya vsekh formatov sredstvami M                           | 1,758 s      | uspeshno   |
| [Kornevoj pisatelj] Vosstanovleniye proyekcii posle ispravleniya formata materiala                        | 192,354 s    | neuspeshno |
| [Kornevoj pisatelj] Proverka vsekh ssyilok do povtornoj generacii proyekcii                               | 21,053 s     | uspeshno   |
| [Kornevoj pisatelj] Vosstanovleniye proyekcii posle proverki formatov i ssyilok                           | 375,749 s    | uspeshno   |
| [Kornevoj pisatelj] Manifest vosstanovlennoj proyekcii                                                  | 25,822 s     | neuspeshno |
| [Kornevoj pisatelj] Tochnyij snimok sobstvennyikh obyyavlenij kandidata                                     | 4,215 s      | uspeshno   |
| [Kornevoj pisatelj] Publikacionnaya chistota beskonfliktnogo kandidata                                   | 20,962 s     | neuspeshno |
| [Kornevoj pisatelj] Svyaznostj sokhraneniya neprinyatogo kandidata po pravilam M                           | 38,372 s     | uspeshno   |
| [Kornevoj pisatelj] Proverka diff podgotovlennogo sliyaniya                                              | 0,368 s      | neuspeshno |
| [Kornevoj pisatelj] Proverka sobstvennogo kanonicheskogo diff s sokhraneniyem doslovnyikh istochnikov        | 0,072 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1173,648 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Do sozdaniya dereva sokhranenyi polnyiye M i L, sobstvennyij ref, fizicheskij korenj i doslovnyiye komandyi. Posle merge podtverzhdenyi HEAD=L, MERGE_HEAD=M, neizmennyiye iskhodnyiye refs, chistoye otslezhivayemoye sostoyaniye primary i prezhniye bajtyi yego indeksa.
- Pervaya popyitka merge zavershilasj kodom 128 do izmeneniya dereva: izolyaciya globaljnoj konfiguracii isklyuchila committer identity. Posle podtverzhdeniya chistotyi povtor poluchil iskhodnyiye nablyudyonnyiye identity cherez okruzheniye; Git-konfiguraciya ne menyalasj. Kod 1 povtornogo merge oznachayet obnaruzhennyiye konfliktyi.
- Dopolniteljnoye chteniye obnaruzhilo drejf ignoriruyemogo kornevogo .DS_Store mezhdu nablyudeniyami. Prichina ne ustanovlena; podgotovka ne otkryivala yego dlya zapisi. On sokhranyon na meste i ne vkhodit v Git. Pervonachaljnaya popyitka otchyota o sostoyanii oshibochno trebovala neizmennosti etogo lokaljnogo fajla; povtor utochnil granicu nablyudeniya. Khyesh .obsidian/graph.json sovpal.
- Odin zapros chteniya otchyota soderzhal opechatku v imeni rabochego dereva i zavershilsya otkazom bez zapisi. Daljnejshiye operacii ispoljzuyut raneye razreshyonnyij korenj kandidata.
- Nezavisimyiye chitateli podgotovili razbor konfliktov generatora i otchyotnoj obyortki, vklyuchaya avtomaticheskiye sklejki vne markerov. Proverochnyiye processyi subagentyi ne zapuskali; ikh analiz ne vyidayotsya za GREEN.

### Soglasovaniye generatora i Finder

Dva scenariya prinyatogo M na tochnom generatore L dali soderzhateljnyij RED: ignoriruyemyij Finder meshal pervomu pokoleniyu, a neignoriruyemyij fajl oshibochno prinimalsya. Posle obyyedineniya oba proshli; otdeljno proshli vse semj scenariyev M i semj scenariyev L s novoj regressiyej otmenyi Git-ignore posle obsledovaniya. V poslednem sluchaye iskhodnyiye bajtyi sokhranyayutsya i arkhiv ne sozdayotsya. Eto adresnaya diagnostika kandidata cherez obyortku M, ne okonchateljnyij dopusk sliyaniya.

Tri zasjhitnyiye funkcii Finder sokhranenyi pobajtno iz M. Deskriptornyij obkhod L sokhranyon; arkhivirovaniye vyipolnyayetsya posle polnogo obsledovaniya i povtornoj proverki inode. Uchastok generatora ot podgotovki okruzheniya do konca fajla, vklyuchayusjhij kyesh, Release i proverku chastnoj kopii, pobajtno sovpadayet s L. Nezavisimyij chitatelj podtverdil eti svojstva staticheski.

Na odnoj publichnoj sinteticheskoj fiksture s 14 katalogami mediana snimka s Finder: L — 0,742 ms, M — 184,806 ms, kandidat — 181,497 ms. L propuskal vse Git-ignore-proverki, poetomu etot rezuljtat ne yavlyayetsya bezopasnoj celjyu uskoreniya. M i kandidat vyipolnyayut po 14 proverok; raznica okolo 1,8% ne dokazyivayet uskoreniya. Bez Finder medianyi sostavili 0,725; 0,972 i 0,923 ms sootvetstvenno. Vse upravlyayemyiye snimki sovpali po khyeshu. Izmeritelj iskhodnogo M toljko pereadresovan na vyibrannyij generator; tri povtora kazhdogo varianta ne izmeryayut polnuyu peresborku, Swift ili stoimostj arkhivirovaniya. Novyij paketnyij algoritm Git-ignore v eto sliyaniye ne dobavlyayetsya: sokhranyayutsya podgotovlennyij kyesh L i zasjhita M.

### Pravila, istoriya obyazateljstv i proverka zaversheniya

Obyyedinenyi normyi vedusjhej vetki i master bez poteri dejstvuyusjhego istochnika polnomochij. Peresekavshiyesya novyiye nomera L perenesenyi v 13–15, nomera 9–12 M sokhranenyi; tochnaya karta nakhoditsya v materiale `соответствие-номеров-правил.json`. Polnoye pokryitiye iskhodnogo inventarya sokhranyayetsya, kornevaya instrukciya ukladyivayetsya v ustanovlennuyu granicu. Vse 22 testa dekompozicii proshli; otdeljnyij zapusk validatora M podtverdil 219 pravil i 11 tematicheskikh fajlov. Utochneniya formulirovok posle etogo zapuska trebuyut povtornogo itogovogo podtverzhdeniya.

Strogij reyestr v3 i prinyatyiye svideteljstva M sokhranenyi. Prezhnij chitatelj i yego testyi L vyidelenyi v otdeljnyiye fajlyi `_v2.py`; ikh algoritm ne perepisan. Smeshannaya istoriya dopuskayet staryiye opredeleniya toljko cherez zakreplyonnyij arkhiv i kartu importa, proveryayet vse versii i ryobra DAG, sokhranyayet zapret udaleniya s posleduyusjhim vozvratom i ponizheniya versii. Dvojnoj perevod stroki u ogradyi staroj komandyi dopuskayetsya toljko v istoricheskom moste posle tochnogo sovpadeniya opredeleniya s arkhivom. Obsjhij razbor komand M ne oslablen. Nezavisimoye staticheskoye revjyu ne nashlo ostavshikhsya defektov etogo mosta.

Polnyij zapusk 14 prezhnikh testov M proshyol, kak i 40 testov prezhnego reyestra L. Poslednij nabor iz 14 testov smeshannoj istorii i interfejsa zaversheniya proshyol za 15,749 s. Regressiya vosproizvela lozhnoye `завершить` posle poyavleniya reyestra vo vremya obrabotki starogo plana; ispravleniye povtorno proveryayet otsutstviye reyestra, iskhodnyiye bajtyi plana i prochitannyikh zaprosov, a takzhe HEAD. Tri sosednikh scenariya proveryayut pozdnyuyu smenu HEAD, plana i istochnika. Sokhranyayutsya UTF-8-kontrakt i pervoye nablyudeniye kazhdogo vkhoda. Eto proverka nablyudyonnoj stabiljnosti, ne garantiya atomarnosti bez obsjhego zamka.

Chastichnyij ostatok v3 peredayotsya v sovmestimom formate resheniya Stop toljko kak `продолжить`; otsutstviye zaplanirovannyikh rabot ne obyyavlyayet zadachu vyipolnennoj. Podgotovitelj komplektuyet vosemj neobkhodimyikh iskhodnikov vmesto chetyiryokh, ispoljzuya novuyu skhemu manifesta `.2`; prezhniye sokhranyonnyiye komplektyi ne perepisyivayutsya. Proshli 22 testa komplekta i shestj scenariyev realjnoj integracii. Ispravlenyi ispolnyayemyiye ssyilki izmeritelej na peremesjhyonnuyu fiksturu i adresnyiye isklyucheniya publikacionnoj politiki. Ni native hook, ni Trust ne ustanavlivalisj.

Vse 164 testa otchyotnoj obyortki proshli za 55,999 s. Strogaya priyomka M i podgotovlennyiye v L raundyi ostayutsya otdeljnyimi kontraktami. Otdeljnaya proverka ograzhdeniya istoricheskogo konvejyera takzhe proshla; istoricheskij FIFO ne vklyuchyon.

### Profilirovaniye soglasovannyikh realizacij

[Sravneniye chitatelej](materialyi/profilj-chitatelya-ostatka.json) soderzhit tri chereduyusjhiyesya paryi polnogo CLI na odnoj prinyatoj istorii M. Rezuljtatyi sovpali pobajtno; medianyi M i C sostavili 1,152 i 1,176 s. Raznica okolo 2,1% po tryom povtoram ne dokazyivayet susjhestvennogo zamedleniya. Paketnoye chteniye Git-istorii sokhraneno; novyij povtornyij obkhod vsej istorii ne dobavlen.

[Polnyij profilj komplektov](materialyi/profilj-komplektov-sliyaniya.json) proveril shestj odinakovyikh iskhodov chetyiryokhfajlovogo L i vosjmifajlovogo C iz vremennyikh sinteticheskikh kommitov. Proverka celostnosti odnogo komplekta zanimayet primerno 1,2 ms u L i 1,5–1,7 ms u C. Dlya nezavershyonnogo obyazateljstva medianyi celogo goryachego vyizova — 293,238 i 289,820 ms; dlya prinyatogo rezuljtata — 526,558 i 570,082 ms. Zdesj uvelichen proveryayemyij sostav, a fajlovyij kyesh ne kontrolirovalsya; nablyudeniye ne vyidayotsya za dokazannoye uskoreniye. Samaya dorogaya chastj ostayotsya v realjnom guard, a ne v proverke vosjmi fajlov. Dopolniteljnaya infrastruktura kyeshirovaniya dlya dolej millisekundyi ne vvoditsya.

[Perenesyonnyij profilj starogo reyestra](materialyi/profilj-starogo-reyestra-kandidata.json) na 100 kommitakh dal medianyi 0,270 s dlya 40 nezavershyonnyikh obyazateljstv i 0,492 s dlya odnoj priyomki. [Okonchateljnyij izmeritelj dekompozicii](materialyi/profilj-dekompozicii-okonchateljnyij.json) dal 54,380 ms u M i 54,951 ms u C na odnoj fiksture. Ranneye izmereniye i diff utochneniya imyon sokhranenyi kak proiskhozhdeniye; yego khyesh ne vyidayotsya za khyesh okonchateljnogo izmeritelya.

### Utochneniya diagnostiki

Pervyij pryamoj zapusk fajla testov M vernul kod 0, no ne ispolnil testov: v nyom otsutstvuyet `unittest.main`. On ne schitayetsya GREEN; zatem vyipolnen nastoyasjhij discovery iz 14 testov. Pervyij test pozdnego poyavleniya reyestra tozhe snachala ostanovilsya ranjshe inyyekcii iz-za pustogo plana fiksturyi; posle zadaniya dejstviteljnogo zavershyonnogo punkta poluchen soderzhateljnyij RED s kodom 0 i resheniyem `завершить`. Pervaya proverka rasshirennogo komplekta obnaruzhila ostavshuyusya proverku chisla fajlov na chetyire; ona zamenena tochnyim razmerom obyazateljnogo inventarya, posle chego vse 22 testa proshli. Pervyij profilj chitatelya pyitalsya ispoljzovatj `-I`, kotoryij prezhnij samostoyateljnyij CLI M ne podderzhivayet; sravneniye povtoreno s obsjhim podderzhivayemyim vyizovom `-S -B`. Izolirovannyij zapusk novogo guard proveren otdeljno.

### Kanonicheskaya podgotovka indeksa

Povtornyij validator M podtverdil 219 pravil i 11 tem. Generator planirovaniya M peresobral obyyedinyonnyij reyestr. Navigaciya devyati zaprosov privedena k obsjhemu khronologicheskomu poryadku sredstvami M; doslovnyiye chasti sravnenyi pobajtno i sokhranenyi. Indeks Zhurnala podtverdil 421 papku. Pervyij prokhod recency obnaruzhil ostavshuyusya konfliktnuyu metku generiruyemogo indeksa; posle vyibora prinyatoj osnovyi M povtor peresobral etot indeks. V tablice sboyev vosstanovlenyi pyatj kolonok stroki 0037 po samoj kartochke. Nachaljnyij obrabotchik vyiravnivaniya ostanovilsya na staroj odinochnoj stroke tablicyi reyestra, odinakovoj u oboikh roditelej; povtor formatiruyet toljko nastoyasjhiye tablicyi i sokhranyayet etu stroku.

Audit obyyavlenij sravnil tochnyiye fajlyi libo kolichestvo kazhdogo imeni s oboimi roditelyami. Novoye sostavnoye imya testa s Finder zameneno russkim, posle chego test uspeshno obnaruzhen i vyipolnen. Yedinstvennoye ostavsheyesya novoye latinskoye obyyavleniye — obyazateljnoye pereopredeleniye unittest.TestCase.setUp. Peremesjheniye prezhnikh fajlov v2 svereno s ikh istochnikom L; novyij sobstvennyij latinskij ostatok ne razreshyon. Audit sokhranyon v materialakh. Pervyij zapusk publikacionnogo skanera otklonyon s error.inventory iz-za yesjhyo konfliktnyikh stadij Git; on povtoryayetsya posle avtomaticheskogo vosstanovleniya proyekcii.

LinguisticKit materializovan avtomatizaciyej M v otdeljnom Git-kataloge dereva kandidata na tochnom gitlink `837e2ce107b97ee7b9d3344c9fe99142281fe393`; vyipolnena shtatnaya proverka zavisimosti. Bajtyi obsjhego Git-config i indeksa primary posle inicializacii sovpali s iskhodnyimi. Svezhij spisok zadach po-prezhnemu pokazyivayet toljko tekusjhego kornya aktivnyim pisatelem FUM.

Pervaya avtomaticheskaya peresborka konfliktnoj proyekcii otklonena do ustanovki: novyij material s rasshireniyem `.diff` otsutstvuyet v perechne podderzhannyikh formatov. Te zhe iskhodnyiye bajtyi sokhranenyi kak `.diff.txt`; format politiki ne rasshiryalsya. Eto pozdneye obnaruzheniye vkhodnoj oshibki, a ne soderzhateljnyij RED optimizacii; yego stoimostj sokhranena mashinnoj zapisjyu.

Vtoroj zapusk proyekcii obnaruzhil istoricheskuyu ssyilku na lokaljnyij `.obsidian/graph.json`, kotorogo net v novom Git worktree. Susjhestvuyusjhiye nastrojki primary skopirovanyi pobajtno toljko v otsutstvovavshij ignoriruyemyij fajl kandidata; iskhodnyij fajl sokhranyon. Eto materializaciya lokaljnogo sostoyaniya, a ne zamena iskhodnoj ssyilki ili rasshireniye politiki formatov. Do sleduyusjhej sborki otdeljno proveryayutsya ssyilki.

Predvariteljnaya klassifikaciya 6 288 istochnikov i proverka ssyilok v 1 560 Markdown-fajlakh proshli. Tretjye primeneniye uspeshno ustanovilo 6 291 celevoj fajl za 375,749 s; posle staging nerazreshyonnyikh stadij indeksa ne ostalosj. Otdeljnaya proverka tochnogo snimka obyyavlenij podtverdila 43 163 obyyavleniya.

Posleduyusjhaya proverka manifesta ne zavershilasj: paralleljno zavershavshayasya adresnaya proverka obnovila svoyu mashinnuyu zapisj mezhdu inventarizaciyej i klassifikaciyej. Korenj oshibochno schyol eti proverki nezavisimyimi. Stoimostj otkaza sokhranena; finaljnoye primeneniye i nezavisimaya proverka vyipolnyayutsya posledovateljno posle zakryitiya zapisej, bez paralleljnyikh pisatelej. Izmenivshijsya posle generacii zhurnal takzhe trebuyet novogo pokoleniya proyekcii.

Skaner M na beskonfliktnom dereve ispoljzoval politiku iz M i otklonil chastj materialov L. Isklyucheniya v predlagayemoj politike C avtomaticheski ne prinimayutsya. Eto otdeljnoye izvestnoye ogranicheniye polnogo dopuska, a ne uspeshnaya proverka publikacionnoj chistotyi kandidata.

Read-only-razbor vsekh 50 strok otkaza vyiyavil 49 tekstovyikh form, tochno sovpadayusjhikh s tipizirovannyimi isklyucheniyami C po puti i khyeshu stroki; ikh proiskhozhdeniye proslezheno do L, vklyuchaya perenos 16 zapisej v2. Eto sinteticheskiye fiksturyi, sistemnyiye ispolnyayemyiye puti, raspoznavateli putej i istoricheskoye svideteljstvo. Otdeljnyij otkaz otnositsya k ZIP s istoricheskimi svideteljstvami: M razreshayet binarnyiye istochniki toljko pod `Источники/`, a arkhiv raspolozhen v materialakh Zhurnala. Yego SHA-256 — `46b642f5987e0dcb38fba4daf1190410d3e33da51329585f9a066a100aef7a26`, sovpadayusjhego blob v M net. V 47 zapisyakh, vklyuchaya vlozhennyij TAR, adresnoye chteniye ne obnaruzhilo priznakov lichnyikh putej; eto ogranichennyij razbor proiskhozhdeniya, ne podtverzhdeniye polnoj publikacionnoj chistotyi. Otkaz i neobkhodimostj otdeljnogo resheniya M sokhranenyi.

Proverka svyaznosti tekusjhego zaprosa, otchyota, navigacii i tochnogo fajla soobsjheniya kommita iz M proshla. Obsjhij `git diff --check HEAD` soobsjhil probelyi v doslovnyikh vneshnikh istochnikakh, ikh proyekcii i sokhranyonnom diff izmeritelya. Eti iskhodnyiye bajtyi ne perepisyivalisj radi formatirovaniya. Adresnaya proverka sobstvennogo kanonicheskogo diff, isklyuchayusjhaya toljko oblastj istochnikov, polnostjyu proizvodnuyu proyekciyu i tochnyij fajl doslovnogo diff, proshla.

## Resheniya i ogranicheniya

Polnyij ispolnyayemyij priyomochnyij kontur dolzhen proiskhoditj iz M. Sejchas ispoljzovanyi adresnyiye proverki i generator iz M; kandidatskiye realizacii proveryalisj kak predmetnyiye vkhodyi, chastj regressij vzyata iz L i C. Eto yesjhyo ne yedinyij nezavisimyij kontur dopuska. Swift-paket generator izvlekayet iz HEAD kandidata L; dlya tochnyikh M i L yego derevo sovpadayet: `160bd0a74ba83d127ace33a5f66ad61dc65c2ab0`. Kontrakt proyekcii takzhe sovpadayet u oboikh roditelej. Eto ogranichennoye dokazateljstvo dannogo zapuska, ne obsjhij ispravlennyij mekhanizm vyibora doverennogo istochnika.

Proverki polnogo proiskhozhdeniya, publikacionnoj politiki, svyazi polnogo otchyota s nastoyasjhim merge-kommitom i proverennoye prodvizheniye master ostayutsya usloviyami dopuska. M yavno razreshayet sokhranitj neprinyatyij kandidat do ikh gotovnosti. Poetomu zhurnal zakryivayetsya s fakticheskim verdiktom `не готов`, bez fiktivnogo polnogo smoke ili svideteljstva zavershyonnogo sliyaniya. Pervichnyij checkout i master sokhranyayutsya.

Sleduyusjhij etap prinimayet nedostayusjhiye proverki v master. Yesli M izmenitsya posle sokhraneniya C1, predpolagayetsya yavno zakrepitj C1 kak sleduyusjhuyu vedusjhuyu bazu L1, sokhraniv proiskhozhdeniye iskhodnyikh L, M i C1. Togda obyichnoye vklyucheniye novogo M1 dast roditelej [L1, M1] i potrebuyet novoj priyomki. Eto predlozheniye dlya prinimayemogo M1; tekusjhemu C1 ono ne dayot polnomochij prodvigatj refs ili obyyavlyatjsya prinyatyim.

Sokhranyayutsya kyesh i podgotovlennyiye vozmozhnosti L, rezuljtatyi i politika sokhraneniya Finder iz M, obe versii istoricheskikh svideteljstv i semj nezavershyonnyikh obyazateljstv. Otdeljno proveryayetsya sovmestimostj smeshannogo DAG reyestra, API guard i v3/v4 otchyotov. Pravila L ne razreshayut dejstviya tekusjhej podgotovki.

Predlozheniye poljzovatelya ob A/B-sravnenii modelej sokhraneno vmeste s doslovnoj komandoj, proiskhozhdeniyem JSONL i [planom eksperimenta](materialyi/plan-AB-sravneniya.md). Predpolagayutsya odinakovyiye iskhodnaya postanovka, Git-baza, sreda i kriterii priyomki; tochnyiye parametryi modeli khranyatsya v manifeste, a imena vetok sluzhat navigacii. Eksperiment ne zapusjhen i ne zamenyayet blizhajshij prioritet proverennogo sliyaniya.

## Istochniki

- [Doslovnyiye komandyi](zapros.md).
- [Protokol podgotovki](materialyi/protokol-podgotovki.json).
- [Prinyataya karta obyyedineniya](../2026-09-10_14-26-58_MSK_proveryatj-sliyaniye-master-v-vedusjhuyu-vetku/materialyi/karta-obyyedineniya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 17:19:08 MSK -->
<!-- content-sha256: sha256:5901c78d5f3f170e2de72b519827783ed6d0d057a2f46c070fc2659a472e2b34 -->
<!-- FUM-MD-RECENCY:END -->
