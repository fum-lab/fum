# Otchyot 2026-09-01 11:19:59 MSK - Realizovatj bratislavskuyu proyekciyu pamyati

FUM-STEP-0129 realizovana kak shtatnaya lokaljnaya avtomatizaciya polnoj bratislavskoj proyekcii kanonicheskoj pamyati FUM. Politika, plan i manifest poluchili yavnuyu migraciyu `v1 → v2`: tri opublikovannyikh fajla versii 1 sokhranenyi pobajtovo neizmennyimi, a versiya 2 otdeljno zakreplyayet ssyilki na isklyuchyonnyiye kanonicheskiye celi, lokaljnyij `.obsidian/graph.json` i tochnyij fajl `ЛИЦЕНЗИЯ`. Generator strukturno preobrazuyet puti, Markdown i lokaljnyiye ssyilki cherez zakreplyonnyij LinguisticKit, sokhranyayet tochnyiye formatyi po versionirovannoj politike, formiruyet manifest proiskhozhdeniya i nezavisimo vyivodit ozhidayemyiye bajtyi pri proverke.

Ustanovka pokoleniya stala vosstanavlivayemoj fazovoj tranzakciyej s vneshnej kvitanciyej vladeniya v Git-dir. Kvitanciya publikuyetsya do pervoj mutacii `Proyekcii`, svyazyivayet token s tochnyimi snimkami prezhnego i novogo pokolenij i udalyayetsya poslednej; vnutrennij zhurnal versii 2 sam ne razreshayet perenos libo udaleniye. Token zadayot otdeljnyiye imena vremennogo zhurnala i prostranstva chastichnoj zapisi: vyikhod stanovitsya polnyim toljko posle sinkhronizacii bajtov i okonchateljnogo rezhima. Do prinyatiya povtor vozvrasjhayet prezhneye podtverzhdyonnoye derevo, posle prinyatiya idempotentno zavershayet ochistku; publichnyiye plan i validator zakryivayutsya pri ostavshejsya kvitancii, a primeneniye snachala vosstanavlivayet yeyo tranzakciyu. Atomarnoye `NO_REPLACE` ne zamenyayet neozhidanno poyavivshuyusya celj ili rezerv; mezhkatalozhnyij perenos sinkhroniziruyet naznacheniye ranjshe istochnika, a vosstanovleniye svorachivayet toljko dokazannyij kvitanciyej avarijnyij dublikat s otdeljnyim inode. Tochnaya granica konfliktnyikh stadij i upravlyayusjhikh Git-ssyilok povtorno sveryayetsya pered ustanovkoj i prinyatiyem. Zasjhisjhenyi simvolicheskiye ssyilki, tochnyiye rezhimyi fajlov i katalogov, `umask`, preryivaniya vo vremya postroyeniya i na granicakh zamenyi, ruchnoj drejf, neizvestnyiye sluzhebnyiye fajlyi, URI, yakorya, ischeznuvshiye istochniki i ostatochnyiye Git-konfliktnyiye stadii. Nastoyasjhaya Git-fikstura podtverzhdayet obyazateljnyij putj «razreshitj kanonicheskij sloj → zanovo primenitj proyekciyu → nezavisimo proveritj» bez ruchnogo obyyedineniya proizvodnyikh fajlov.

Tochnaya oblastj `Proyekcii/**` isklyuchena iz kanonicheskikh avtodiskaveri-konturov i Git-otpechatka otchyotnoj granicyi; blizkiye imena, inoj registr i vlozhennyiye odnoimyonnyiye katalogi ostayutsya vkhodami. Ssyilki vnutrj proizvodnoj oblasti razreshenyi toljko dlya tochnyikh fajlov novogo pokoleniya i ikh katalogov-predkov: ustarevshij libo sluzhebnyij potomok prezhnego pokoleniya zakryivayet sborku. Markdown-yakorya poluchayut globaljno pervyij svobodnyij slug, vklyuchaya kollizii tochnyikh i preobrazuyemyikh dokumentov. Polnyij profilj smoke-check vklyuchayet primeneniye, nezavisimuyu proverku, avtonomnyij nabor proyekcii i neobyazateljnyij kontur perevoda obyyavlenij. FUM-REQ-0037 i FUM-STEP-0129 zavershenyi, aktivnaya vyiborka `master` umenjshena do 9 kandidatov, a mashinnyij planovyij reyestr peresobran.

## Profilj vremeni vyipolneniya

| Stadiya                    | Dliteljnostj         | Granicyi i sposob izmereniya                                                                                  |
| ------------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------- |
| Proverka dopuska zapisi   | ne izmerena otdeljno | Do pervoj zapisi sverenyi `HEAD`, `refs/heads/master`, pervichnyij checkout i otsutstviye drugogo pisatelya    |
| Realizaciya i dokumentaciya | ne izmerena otdeljno | Ot metki `11:19:59 MSK`: TDD, usileniye tranzakcii, exact-isklyucheniya, pravila, dokumentaciya i planirovaniye   |
| Adresnyiye proverki         | sm. mashinnyiye zapisi  | Kazhdyij pryamoj vyizov uchtyon monotonnoj dliteljnostjyu, iskhodom i Git-otpechatkom                               |
| Polnyij smoke-check       | sm. mashinnyiye zapisi  | Zavershayusjhij uspeshnyij zapusk polnogo profilya posle lokalizacii otkazov predyidusjhikh popyitok                    |
| Lokaljnyij kommit          | ne izmeryayetsya        | Odin lokaljnyij kommit na `refs/heads/master`; push, handoff i continuation ne vyipolnyayutsya                   |

Granica profilya: ot kanonicheskoj metki `2026-09-01 11:19:59 MSK` do zakryitiya mashinnogo snimka; ozhidaniya FIFO i vneshnej peredachi net.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:5064b1d4d9b743a72879aeff359d97cd6ff76a19b7ec931e2291e217cb6285de -->

| Vyizov                                                                                                                   | Dliteljnostj | Rezuljtat         |
| ----------------------------------------------------------------------------------------------------------------------- | ------------ | ----------------- |
| [Kornevoj pisatelj] TDD RED bratislavskoj proyekcii pamyati                                                               | 17,544 s     | neuspeshno         |
| [Kornevoj pisatelj] TDD GREEN bratislavskoj proyekcii pamyati                                                             | 21,685 s     | neuspeshno         |
| [Kornevoj pisatelj] Povtor TDD GREEN bratislavskoj proyekcii pamyati                                                      | 21,247 s     | neuspeshno         |
| [Kornevoj pisatelj] Zavershayusjhij TDD GREEN bratislavskoj proyekcii pamyati                                                 | 21,29 s      | uspeshno           |
| [Kornevoj pisatelj] TDD RED isklyucheniya proizvodnoj oblasti iz Markdown-inventarya                                        | 0,444 s      | neuspeshno         |
| [Kornevoj pisatelj] TDD RED isklyucheniya proyekcii iz skanera mashinnyikh putej                                               | 2,219 s      | neuspeshno         |
| [Kornevoj pisatelj] TDD RED isklyucheniya proyekcii iz inventarya obyyavlenij                                                 | 1,375 s      | neuspeshno         |
| [Kornevoj pisatelj] TDD GREEN bratislavskoj proyekcii posle sovmestimosti                                                | 21,463 s     | uspeshno           |
| [Kornevoj pisatelj] TDD GREEN isklyucheniya proyekcii iz Markdown-inventarya                                                 | 0,491 s      | uspeshno           |
| [Kornevoj pisatelj] TDD GREEN isklyucheniya proyekcii iz skanera mashinnyikh putej                                             | 2,253 s      | uspeshno           |
| [Kornevoj pisatelj] TDD GREEN isklyucheniya proyekcii iz inventarya obyyavlenij                                               | 1,429 s      | uspeshno           |
| [Kornevoj pisatelj] TDD RED isklyucheniya proyekcii iz strukturyi papok zaprosov                                             | 8,879 s      | neuspeshno         |
| [Kornevoj pisatelj] TDD RED isklyucheniya proyekcii iz pereimenovaniya kartochki shaga                                         | 3,151 s      | neuspeshno         |
| [Kornevoj pisatelj] TDD RED isklyucheniya proyekcii iz otpechatka Git-snimka                                                 | 21,415 s     | neuspeshno         |
| [Kornevoj pisatelj] TDD GREEN isklyucheniya proyekcii iz strukturyi papok zaprosov                                           | 8,688 s      | uspeshno           |
| [Kornevoj pisatelj] TDD GREEN isklyucheniya proyekcii iz otpechatka Git-snimka                                               | 20,954 s     | uspeshno           |
| [Kornevoj pisatelj] TDD GREEN isklyucheniya proyekcii iz pereimenovaniya kartochki shaga                                       | 3,011 s      | uspeshno           |
| [Kornevoj pisatelj] TDD RED vklyucheniya generatora i validatora proyekcii v standartnyij smoke                              | 34,262 s     | neuspeshno         |
| [Kornevoj pisatelj] TDD GREEN vklyucheniya generatora i validatora proyekcii v standartnyij smoke                            | 22,965 s     | neuspeshno         |
| [Kornevoj pisatelj] TDD GREEN vklyucheniya generatora i validatora proyekcii v standartnyij smoke posle soglasovaniya poryadka | 17,605 s     | uspeshno           |
| [Kornevoj pisatelj] TDD RED bezopasnogo vosstanovleniya, rezhimov katalogov, anchors, URI i recency                       | 7,9 s        | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Adresnyiye testyi bratislavskoj proyekcii posle usileniya vosstanovleniya                           | 23,702 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtornyiye adresnyiye testyi bratislavskoj proyekcii posle ispravleniya yakorej                      | 24,553 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Adresnyiye testyi Git-konfliktov bratislavskoj proyekcii                                          | 27,406 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtor nastoyasjhej Git-konfliktnoj fiksturyi proyekcii                                            | 2,96 s       | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Vtoroj povtor nastoyasjhej Git-konfliktnoj fiksturyi proyekcii                                     | 4,025 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Polnyiye adresnyiye testyi bratislavskoj proyekcii posle Git-fiksturyi                               | 30,134 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Adresnyiye testyi tochnyikh isklyuchenij proyekcii i standartnogo plana                                | 40,402 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtor testov tochnyikh isklyuchenij proyekcii i standartnogo plana                                 | 41,411 s     | uspeshno           |
| [Kornevoj pisatelj] Proverka dekompozicii pravil posle utochneniya granicyi proyekcii                                       | 0,061 s      | neuspeshno         |
| [Kornevoj pisatelj] Povtornaya proverka dekompozicii pravil proyekcii                                                     | 0,115 s      | uspeshno           |
| [Kornevoj pisatelj] Sukhoj plan zaversheniya trebovaniya FUM-REQ-0037                                                       | 18,424 s     | uspeshno           |
| [kornevaya sessiya] Proveritj peresobrannyij planovyij reyestr                                                               | 0,391 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Adresnyiye testyi tochnogo yuridicheskogo formata proyekcii                                          | 30,302 s     | uspeshno           |
| [kornevaya pishusjhaya sessiya] Adresnyiye testyi vladeniya konfliktnoj proyekciyej i ignored-ssyilki                                | 30,831 s     | uspeshno           |
| [kornevaya pishusjhaya sessiya] Adresnyiye testyi polnogo vladeniya stage-0 i konfliktnoj proyekciyej                               | 30,145 s     | uspeshno           |
| [kornevaya pishusjhaya sessiya] RED: staged-manifest ne dolzhen sam avtorizovatj konfliktnuyu zamenu                            | 3,05 s       | neuspeshno         |
| [kornevaya pishusjhaya sessiya] RED: obyyedinyonnyij staged-manifest ne dolzhen sam avtorizovatj konfliktnuyu zamenu               | 3,63 s       | neuspeshno         |
| [kornevaya pishusjhaya sessiya] GREEN: konfliktnoye vladeniye toljko iz doverennyikh stadij manifesta                             | 3,688 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] RED: izvestnyij vyikhod bez zapisi indeksa ne dolzhen byitj perezapisan                            | 3,756 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] GREEN: konfliktnaya zamena zakryivayet staged i untracked drejf                                  | 4,288 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Polnyij adresnyij nabor Bratislavskoj proyekcii posle usileniya konfliktnoj zamenyi                | 29,37 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Polnyij adresnyij nabor Bratislavskoj proyekcii posle fail-closed ispravlenij                    | 29,078 s     | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Adresnaya proverka strogogo manifesta Bratislavskoj proyekcii                                   | 27,087 s     | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Adresnaya proverka kvitancii vosstanovleniya Bratislavskoj proyekcii                             | 29,526 s     | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Polnyij adresnyij nabor kvitancii i strogogo manifesta                                          | 40,401 s     | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Adresnaya proverka nastoyasjhego konflikta proyekcii                                               | 4,374 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Povtornaya adresnaya proverka nastoyasjhego konflikta proyekcii                                     | 5,321 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Polnyij adresnyij nabor Bratislavskoj proyekcii posle recovery-ispravlenij                       | 40,239 s     | uspeshno           |
| [kornevaya pishusjhaya sessiya] Proverka probeljnoj korrektnosti tekusjhego izmeneniya                                           | 0,058 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Adresnaya proverka drejfa AUTO_MERGE i tochnogo registra                                        | 0,149 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Adresnaya proverka ruchnogo drejfa AUTO_MERGE                                                   | 5,609 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Adresnaya proverka tochnogo registra kornya proyekcii                                             | 0,211 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Polnyij TDD-nabor bratislavskoj proyekcii posle usileniya vosstanovleniya                         | 45,51 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Polnyij TDD-nabor posle zamyikaniya chastichnyikh zapisej                                            | 45,77 s      | uspeshno           |
| [kornevaya pishusjhaya sessiya] Polnyij TDD-nabor s avarijnyimi regressiyami                                                     | 0,091 s      | neuspeshno         |
| [kornevaya pishusjhaya sessiya] Povtor polnogo TDD-nabora s avarijnyimi regressiyami                                            | 56,189 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Promezhutochnyij polnyij nabor posle usileniya vladeniya i NO_REPLACE                               | 58,618 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Polnyij TDD-nabor avarijnoj dolgovechnosti i atomarnogo NO_REPLACE                              | 62,82 s      | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtor atomarnogo NO_REPLACE v okne naznacheniya                                                | 1,209 s      | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Diagnostika perekhvata atomarnogo NO_REPLACE                                                   | 1,186 s      | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] GREEN atomarnogo NO_REPLACE v okne naznacheniya                                                 | 0,835 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Povtor polnogo TDD-nabora avarijnoj dolgovechnosti i NO_REPLACE                                | 62,417 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Regressiya istoricheskogo pending-bloka svezhesti                                                | 0,483 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Regressii istoricheskikh form svezhesti proyekcii                                                 | 0,498 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Regressiya bootstrap-ssyilki na korenj proyekcii                                                 | 1,217 s      | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] GREEN bootstrap-ssyilki na korenj proyekcii                                                     | 1,165 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Regressiya yakorya v tochnom Markdown-istochnike                                                   | 0,435 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Adresnyiye regressii ssyilok i yakorej bratislavskoj proyekcii                                     | 3,475 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Plan rusifikacii novyikh obyyavlenij FUM-STEP-0129                                               | 0,257 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Testyi instrumentov posle rusifikacii obyyavlenij                                               | 13,297 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtor testov instrumentov posle perenosimoj near-miss fiksturyi                               | 13,339 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Polnyij nabor bratislavskoj proyekcii posle audita i migracii v2                                | 66,658 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Inventarizaciya ostatka obyyavlenij posle rusifikacii                                           | 23,067 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtor kompaktnoj inventarizacii ostatka obyyavlenij                                           | 22,507 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Proverka tochnogo snimka ostatka obyyavlenij                                                    | 22,447 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Integracionnyiye testyi smoke-check i otchyotnogo kontura                                          | 19,539 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Avtonomnyiye testyi otchyotnogo kontura proverok                                                   | 20,049 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Proverka mashinnogo kontrakta bratislavskoj proyekcii v2                                        | 0,144 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Proverka peresobrannogo planovogo reyestra FUM-STEP-0129                                       | 0,381 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Proverka svezhesti Markdown posle migracii v2                                                  | 0,797 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Proverka dekompozicii pravil posle granicyi Proyekcii                                          | 0,151 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Finaljnyij polnyij smoke-check FUM-STEP-0129                                                    | 2865,949 s   | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Diagnostika otkaza proverki mashinno-lokaljnyikh putej                                           | 14,444 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Regressii politiki mashinno-lokaljnyikh putej posle lokalizacii                                  | 2,015 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] GREEN proverki mashinno-lokaljnyikh putej posle tochnogo obnovleniya politiki                      | 14,4 s       | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Povtornyij finaljnyij polnyij smoke-check FUM-STEP-0129                                          | 3069,382 s   | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] GREEN svyaznosti posle tochnogo obyyavleniya udalyonnoj storonyi rename                             | 32,648 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Zavershayusjhij polnyij smoke-check FUM-STEP-0129                                                  | 288,888 s    | prervano — SIGINT |
| [Kornevaya pishusjhaya sessiya] GREEN svyaznosti s vneshnim vremennyim fajlom soobsjheniya kommita                                  | 33,621 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Itogovyij polnyij smoke-check FUM-STEP-0129 s vneshnim soobsjheniyem kommita                        | 3134,708 s   | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Adresnaya proverka legacy-inventarya sleduyusjhikh shagov posle zakryitiya FUM-STEP-0129               | 1,141 s      | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Itogovyij polnyij smoke-check FUM-STEP-0129 posle soglasovaniya legacy-inventarya                 | 3024,117 s   | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] GREEN svyaznosti posle obyyavleniya legacy-testa planovoj proyekcii                               | 34,085 s     | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Povtor GREEN svyaznosti posle obnovleniya recency i obyyavleniya legacy-testa                     | 32,946 s     | uspeshno           |
| [Kornevaya pishusjhaya sessiya] Zavershayusjhij polnyij smoke-check FUM-STEP-0129 posle zamyikaniya svyaznosti                        | 3147,38 s    | neuspeshno         |
| [Kornevaya pishusjhaya sessiya] Finaljnyij polnyij smoke-check FUM-STEP-0129 s ustojchivyim vneshnim zhurnalom                      | 5918,963 s   | uspeshno           |

Obsjheye vremya pryamyikh zapuskov proverok: 22954,205 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- RED-fazyi sokhranili ozhidayemyiye otkazyi do realizacii strukturnoj generacii, exact-isklyuchenij, smoke-integracii i usilennogo vosstanovleniya; posleduyusjhiye GREEN-progonyi prokhodyat bez udaleniya rannikh svideteljstv.
- Polnyij adresnyij nabor proyekcii podtverzhdayet determinirovannyiye puti i bajtyi, ssyilki, yakorya, URI, svezhestj, tochnyiye rezhimyi, sboi vo vremya postroyeniya, do i posle prinyatiya, polnyij predvariteljnyij obkhod udaleniya, otkaz poddeljnogo zhurnala bez kvitancii i nastoyasjhuyu Git-konfliktnuyu fiksturu.
- Sovmestnyiye testyi podtverzhdayut exact-isklyucheniya `Proyekcii/**` v proyektnom Markdown-inventare, strukture zaprosov, pereimenovanii kartochek, skanere mashinno-lokaljnyikh putej, inventare obyyavlenij i Git-otpechatke; near-miss ostayotsya vidimyim.
- Pervaya popyitka polnogo smoke-check lokalizovala pyatj neograzhdyonnyikh literalov testovyikh putej posle rusifikacii obyyavlenij. Shtatnyij generator politiki pereschital dva prezhnikh otpechatka i dobavil tri tochnyiye testovyiye fiksturyi; avtonomnyij nabor i povtornyij repozitornyij skaner podtverdili ispravleniye.
- Vtoraya popyitka proshla ispravlennyij skaner i ostanovilasj na tochnoj granice svyaznosti: prezhneye udalyonnoye imya pereimenovannoj kartochki shaga ne byilo otdeljno obyyavleno v zaprose. Razdel zatronutyikh fajlov dopolnen kanonicheskim markerom udalyonnogo fajla bez rasshireniya razreshyonnoj oblasti.
- Tretjya popyitka byila prervana v chistoj vyichisliteljnoj faze do publikacii kvitancii: nezavisimyij audit obnaruzhil, chto podgotovlennyij tekst soobsjheniya kommita oshibochno nakhodilsya v repozitorii. Te zhe bajtyi perenesenyi v publikacionno chistyij vremennyij fajl vne checkout; repozitornaya kopiya isklyuchena iz rezuljtata, a vneshnij fajl stanovitsya yedinyim vkhodom svyaznosti, smoke-check i `git commit -F`.
- Chetvyortaya popyitka uspeshno proshla generaciyu i nezavisimuyu proverku 4 821 fajla, ispravlennyij skaner i svyaznostj, no ostanovilasj na legacy-teste planovoj proyekcii: posle udaleniya zavershyonnoj FUM-STEP-0129 test vsyo yesjhyo ozhidal prezhniye 10 kandidatov i dva uslovno gotovyikh prodolzheniya. Dve kontroljnyiye konstantyi privedenyi k uzhe zakreplyonnomu v proyekcii sostavu iz 9 kandidatov i odnogo uslovno gotovogo prodolzheniya; adresnyij scenarij podtverdil ispravleniye.
- Pyataya popyitka uspeshno proverila pokoleniye iz 4 823 fajlov i doshla do svyaznosti, kotoraya otklonila novyij putj ispravlennogo legacy-testa kak ne obyyavlennyij v zaprose. Tochnyij putj testa dobavlen v razdel zatronutyikh fajlov bez rasshireniya oblasti ostaljnyikh izmenenij. Pervaya adresnaya pereproverka ozhidayemo obnaruzhila ustarevshiye posle etogo redaktirovaniya recency-metki; shtatnaya peresborka metok i indeksa ustranila raskhozhdeniye, a povtornaya svyaznostj proshla.
- Shestaya popyitka uspeshno postroila pokoleniye iz 4 826 fajlov i vyipolnyala nezavisimuyu proverku, no posle zakryitiya prilozheniyem prezhnego PTY-kanala poteryala priyomnik standartnogo vyivoda i zavershilasj sluzhebnyim kodom Python `120`. Repozitornyij otkaz ne nablyudalsya, odnako progon ne zaschityivayetsya; sleduyusjhaya popyitka pishet polnyij vyivod vo vneshnij vremennyij log i potomu ne zavisit ot zhiznennogo cikla otobrazhayemogo terminala.
- Validator dekompozicii prinimayet 210 pravil v 11 temakh, a planovyij reyestr posle pereimenovanij i zakryitiya shaga sovpadayet s kanonicheskimi istochnikami.
- Itogovuyu polnotu dokazyivayet zavershayusjhij uspeshnyij polnyij smoke-check, posle kotorogo pokoleniye peresobirayetsya i proveryayetsya yesjhyo rovno odin raz po postzakryivayusjhemu protokolu.

## Resheniya i ogranicheniya

- Toljko kirillicheskij kanonicheskij sloj ostayotsya istochnikom istinyi. `Proyekcii/**` khranitsya v Git, no ne stanovitsya instrukciyami, rabochim katalogom agenta ili vkhodom kanonicheskikh generatorov.
- Nezavisimyij validator ne doveryayet redaktiruyemomu manifestu: on zanovo preobrazuyet kanonicheskij snimok i sravnivayet polnyij ozhidayemyij nabor s manifestom i fajlovoj sistemoj.
- Fazovyij zhurnal ne yavlyayetsya dokazateljstvom vladeniya: vosstanovleniye prinimayet toljko sovpavshuyu vneshnyuyu kvitanciyu i tochnyiye ustojchivyiye snimki, a lyuboj neizvestnyij libo izmenyonnyij sluzhebnyij obyyekt sokhranyayet i otklonyayet.
- Tranzakcionnaya zasjhita sleduyet posledovateljnoj skheme s odnoj dobrosovestnoj pishusjhej sessiyej i schitayet Git-dir doverennyim lokaljnyim operacionnyim sostoyaniyem. Pered kriticheskimi mutaciyami kvitanciya sveryayetsya povtorno; namerennaya poddelka yeyo processom togo zhe poljzovatelya bez vneshnego kornya doveriya ostayotsya vne modeli ugroz.
- Zhyostkoye preryivaniye do atomarnoj publikacii kvitancii mozhet ostavitj tokenizirovannyij vremennyij fajl v Git-dir. Bez opublikovannogo dokazateljstva vladeniya on sokhranyayetsya kak diagnosticheskij ostatok i ne ochisjhayetsya avtomaticheski.
- Lokaljnyiye ssyilki na yavno isklyuchyonnyiye celi sokhranyayutsya kak ssyilki na kanonicheskij sloj po zakryitoj politike versii 2; vneshniye URI i tochnyiye mashinnyiye oblasti ne transliteriruyutsya. Opublikovannyij kontrakt versii 1 ne pereinterpretiruyetsya.
- Kartochka cepochki FUM-CEPOCHKA-0003 ostayotsya `запланирована`: yeyo istoricheskoye usloviye trebuyet otdeljnoj vetki, togda kak dejstvuyusjhij `manual-sequential-v1` zavershayet rabotu neposredstvenno na `master`.
- Posle uspeshnogo kommita vyipolnyayutsya toljko read-only-proverki rezuljtata. Push, udaleniye istoricheskikh konturov i sleduyusjhaya zadacha ne vkhodyat v zapros.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [zavershyonnaya kartochka FUM-STEP-0129](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0129-realizovatj-vosproizvodimuyu-bratislavskuyu-proyekciyu-pamyati.md)
- [podtverzhdyonnoye trebovaniye FUM-REQ-0037](../../Trebovaniya/✅-paralleljnaya-bratislavskaya-proyekciya-pamyati-FUM.md)
- [avtomatizaciya bratislavskoj proyekcii](../../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md)
- [opisaniye bratislavskoj versii pamyati](../../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 02:29:57 MSK -->
<!-- content-sha256: sha256:41cee1110009ca688ba940d58b5ea3fdd5bbff800febdddcb8fcf4a3f40eaf20 -->
<!-- FUM-MD-RECENCY:END -->
