# Otchyot 2026-08-10 14:30:08 MSK - Dobavitj analitiku po chislu zavershyonnyikh shagov

Vtoryim aktivnyim tipom zadaniya universaljnogo dispetchera stala analitika posle nastraivayemogo chisla podtverzhdyonno zavershyonnyikh zapuskov `master.next-step`. Schyotnoye sobyitiye rozhdayetsya toljko v obsjhej Git-tranzakcii s kommitom rezuljtata i peredachej FIFO. Sobyitiye khranit pokoleniye zapuska, a yego ustojchivaya identichnostj svyazyivayet polnuyu ssyilku vetki, `step_id`, `card_id`, zavershayusjhij kommit i rezuljtat, poetomu povtor idempotenten. Tekusjhij `last_completion` ostayotsya byistryim putyom podtverzhdeniya sleduyusjhego shaga, zhurnal i pretenziya skhemyi `5` dayut dolgovechnoye dokazateljstvo uspekha, a obyichnyij `finish-clean` atomarno sozdayot skhemu `6` s tochnyim `свидетельство_чистого_завершения = {"base_head": selection_head, "task_id": task_id, "generation": generation}`. Obsjhaya terminalizaciya prinimayet oba dokazateljstva nezavisimo ot pozdnej peredachi: uspeshnoye zaversheniye sokhranyayet pretenziyu dlya povtora, a bezopasnyij otkaz posle chistogo zaversheniya yeyo udalyayet. Sleduyusjhaya rezervaciya togo zhe adaptera atomarno poglosjhayet terminaljnuyu pretenziyu. Planovyij tik, chat, proizvoljnyij kommit i staraya pretenziya bez `card_id` v zhurnal ne popadayut.

Tekusjhij perekhodnyij zapusk yesjhyo ispoljzuyet pretenziyu skhemyi `4` i poetomu osoznanno ne stanovitsya pervyim schyotnyim sobyitiyem. Yego peredacha vsyo zhe obespechivayet odnokratnostj: novaya versiya ocheredi iz `HEAD` ne pozvolyayet sleduyusjhemu vladeljcu zamenitj byistryij `last_completion` chuzhim `commit` ili `finish-clean`, poka svyazannaya obsjhaya rezervaciya neterminaljna; posle obsjhej terminalizacii povtor prokhodit, a sbros sokhranyayet prezhneye zaversheniye v kvitancii. Posleduyusjhij kommit skhemyi `4` pod novoj versiyej istoricheski podtverzhdayet gotovyij vyibor i `card_id`, atomarno perevodit pretenziyu v skhemu `5` i pishet obyichnoye sobyitiye zhurnala.

Kanonicheskij reyestr khranit nachaljnoye `N = 5`, granicu schyota, sleduyusjhij porog, oblastj analiza i kursor poslednego podtverzhdyonnogo analiticheskogo rezuljtata. Adapter vyibirayet starejshij nezakryityij porog, zamorazhivayet v pretenzii konechnyij diapazon sobyitij i sozdayot ne boleye odnoj obyichnoj zadachi FIFO za planovyij tik. Nezavershyonnyij porog perezhivayet propusjhennyij tik, povtor i perezapusk. Do granicyi vyizova sredyi tochnaya pretenziya mozhet byitj atomarno udalena kak `released`, a yeyo podtverzhdyonnoye otsutstviye oboznachayetsya `unclaimed`; posleduyusjheye obsjheye osvobozhdeniye zanovo proveryayet sravneniyem i zamenoj otsutstviye ssyilki, poetomu vstrechnoye sozdaniye pretenzii ne ostavlyayet osirotevshego sostoyaniya. Posle dopuska `finish-clean` atomarno sokhranyayet fazu `очищена` s zadachej, pokoleniyem i `base_head`, i pozdnyaya peredacha FIFO uzhe ne stirayet eto dokazateljstvo otsutstviya kommita.

Ocheredj atomarno perevodit uspeshno zavershivshuyusya pretenziyu v fazu `передана` vmeste s kommitom i peredachej i sokhranyayet ustojchivoye svideteljstvo kommita. Specializirovannoye zaversheniye sveryayet svideteljstvo, cepochku pervyikh roditelej i tochnyiye bajtyi otchyota i reyestra; obsjheye podtverzhdeniye povtoryayet proverku, sveryayet OID sravneniyem i zamenoj, terminaliziruyet obsjhuyu rezervaciyu i sokhranyayet tochnuyu analiticheskuyu pretenziyu `завершена` dlya terminaljnogo povtora, povtora FIFO i specializirovannogo povtora. Poetomu planovyij tik mozhet zavershitj lyubuyu svyazannuyu pretenziyu `передана`, dazhe yesli posleduyusjhaya peredacha zamenila `last_completion` ili shtatnyij sbros sokhranil pretenziyu. Novaya analiticheskaya rezervaciya odnoj operaciyej sravneniya i zamenyi poglosjhayet terminaljnuyu pretenziyu vmeste s zamenoj terminaljnoj rezervacii; sboj posle rezervirovaniya vidit pretenziyu otsutstvuyusjhej. Prodvizheniye kursora svyazano s podtverzhdyonnyim otchyotom togo zhe diapazona. Izmeneniye `N` vyipuskayet novoye pokoleniye s yavnoj politikoj nakoplennogo ostatka i ne perepisyivayet istoriyu.

Analiticheskaya zadacha poluchayet proveryayemyiye ssyilki na sobyitiya, kartochki i kommityi. Yeyo zapros trebuyet nazvatj nablyudayemuyu sposobnostj, terminaljnuyu priyomku, otricateljnyiye rezuljtatyi i stoimostj cepochki i zapresjhayet schitatj samo chislo shagov, kommitov ili dokumentov dokazateljstvom uluchsheniya. Tekusjhaya FUM-STEP-0096 soznateljno ne vkhodit v nachaljnyij schyot: zhurnal prinimayet toljko posleduyusjhiye proverennyiye pretenzii novoj skhemyi.

Pervyij finaljnyij vyizov FIFO-kommita ne sozdal obyyekta kommita: v indekse nakhodilosj toljko pereimenovaniye kartochki, togda kak ostaljnaya realizaciya i zhurnaljnyiye materialyi ostavalisj nezaindeksirovannyimi ili novyimi, poetomu predvariteljnaya proverka zavershilasj sostoyaniyem `dirty` do `write-tree`. Boljshoj perechenj blokiruyusjhikh putej perepolnil nablyudayemyij vyivod, a yego usecheniye byilo oshibochno prinyato za uspekh. Ispravleniye ogranichivayet razmer diagnosticheskogo JSON, fiksiruyet chislo i proveryayemyij otpechatok polnogo inventarya i zakreplyayet boleye siljnuyu granicu rezuljtata: indeksirovaniye vyipolnyayetsya yavno, a kommit podtverzhdayetsya toljko polnyim razobrannyim otvetom `state = committed`; neizvestnyij ili usechyonnyij iskhod trebuyet idempotentnogo povtora toj zhe komandyi i ne razreshayet soobsjhatj ob uspekhe. Angloyazyichnyiye metki uzhe zapisannyikh zapuskov 296–304 sokhranenyi doslovno kak chastj khyeshirovannogo svideteljstva; posleduyusjhiye zapuski poluchayut russkiye nazvaniya.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj                         | Granicyi i sposob izmereniya                                                                                   |
| ------------------------ | ------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| Ozhidaniye dopuska FIFO    | otdeljno ne izmeryalosj               | Dopusk podtverzhdyon do pervoj soderzhateljnoj zapisi; otdeljnaya monotonnaya otmetka nachala ozhidaniya ne velasj   |
| Soderzhateljnaya rabota    | otdeljno ne izmeryalasj               | Realizaciya i analiz cheredovalisj s TDD-progonami, poetomu nepodtverzhdyonnaya raznostj nastennyikh chasov ne dana   |
| Celevyiye proverki         | po mashinnomu itogu nizhe              | Kazhdaya adresnaya komanda zapisana otchyotnoj obyortkoj s monotonnoj dliteljnostjyu i rezuljtatom                  |
| Polnyij smoke-check       | po mashinnoj zapisi nizhe              | Itogovyij polnyij kontur zapisyivayetsya toj zhe obyortkoj otdeljnyim imenovannyim zapuskom                            |
| Atomarnyij commit+handoff | vne okhvachennogo intervala otchyota     | Vyipolnyayetsya posle zakryitiya i proverki otchyota; tochnyij uspekh podtverzhdayet terminaljnyij otvet FIFO              |

Granica profilya: ot iskhodnogo zaprosa 2026-08-10 14:30:08 MSK do zakryitiya proverochnogo otchyota. Nepodtverzhdyonnyiye ocenki vremeni soderzhateljnoj rabotyi ne podmenyayut mashinnyiye dliteljnosti zapuskov.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:8e5bd0669dc251cd640ef161a8d42b3ca04dc2ee453cd8c2783c31c306a63090 -->

| Vyizov                                                                                                               | Dliteljnostj | Rezuljtat         |
| ------------------------------------------------------------------------------------------------------------------- | ------------ | ----------------- |
| [korenj] Krasnyij rubezh obsjhego selektora i kanonicheskogo reyestra                                                     | 17,867 s     | neuspeshno         |
| [korenj] Zhurnal zavershyonnyikh runtime-ready zapuskov                                                                  | 3,359 s      | neuspeshno         |
| [korenj] Zhurnal zavershyonnyikh runtime-ready zapuskov posle ispravleniya                                                | 9,242 s      | neuspeshno         |
| [korenj] Zhurnal zavershyonnyikh runtime-ready zapuskov, atomarnaya CAS                                                   | 6,41 s       | uspeshno           |
| [korenj] Reyestr i event-first vyibor dispetchera                                                                      | 17,99 s      | neuspeshno         |
| [subagent-next-step] Krasnaya granica avtonomnyikh testov next-step schema 5                                           | 138,56 s     | neuspeshno         |
| [subagent-adapter-analitiki] Krasnyij rubezh lokaljnogo adaptera analitiki                                            | 2,81 s       | neuspeshno         |
| [subagent-next-step] Kontraktnyiye testyi claim schema 5 i legacy schema 4                                             | 12,865 s     | uspeshno           |
| [subagent-next-step] Regressii FIFO dlya schema 4 i schema 5                                                         | 6,422 s      | uspeshno           |
| [subagent-next-step] Polnyij avtonomnyij nabor next-step posle schema 5                                               | 145,748 s    | neuspeshno         |
| [korenj] Event-first vyibor i globaljnaya rezervaciya                                                                  | 21,183 s     | neuspeshno         |
| [korenj] Event-first vyibor i odna globaljnaya rezervaciya, povtor                                                     | 21,228 s     | uspeshno           |
| [subagent-next-step] Fail-fast diagnostika next-step schema 5                                                       | 44,537 s     | neuspeshno         |
| [subagent-next-step] Buferizovannaya fail-fast diagnostika next-step                                                 | 44,529 s     | neuspeshno         |
| [korenj] Upravleniye N analitiki s yavnoj politikoj ostatka                                                           | 0,141 s      | neuspeshno         |
| [subagent-next-step] Polnaya diagnostika next-step schema 5 bez fail-fast                                            | 143,231 s    | neuspeshno         |
| [korenj] Upravleniye N analitiki, soglasovannyiye pokoleniya                                                            | 0,149 s      | neuspeshno         |
| [korenj] Upravleniye N analitiki posle fiksacii politiki                                                             | 0,142 s      | uspeshno           |
| [subagent-next-step] Tochechnaya proverka heartbeat i replay claim schema 5                                            | 1,368 s      | neuspeshno         |
| [subagent-next-step] Povtornaya tochechnaya proverka heartbeat i replay claim schema 5                                  | 1,263 s      | neuspeshno         |
| [subagent-next-step] Recovery povtornogo claim skhemyi 5                                                              | 1,182 s      | uspeshno           |
| [subagent-next-step] Kontraktnyiye regressii next-step schema 5 i heartbeat                                           | 13,09 s      | uspeshno           |
| [subagent-next-step] Avtonomnyiye regressii zhurnala zavershyonnyikh zapuskov                                              | 6,812 s      | uspeshno           |
| [korenj] Polnyij avtonomnyij kontur FIFO s zhurnalom i reset                                                           | 194,438 s    | uspeshno           |
| [subagent-adapter-analitiki] Iskhodnyiye testyi lokaljnogo adaptera analitiki                                           | 4,055 s      | neuspeshno         |
| [subagent-adapter-analitiki] Povtor iskhodnyikh testov lokaljnogo adaptera analitiki                                   | 6,707 s      | uspeshno           |
| [subagent-adapter-analitiki] Krasnyij rubezh avtomata zaversheniya analitiki                                            | 11,221 s     | neuspeshno         |
| [korenj] Polnyij nabor testov FIFO posle integracii zhurnala                                                          | 201,076 s    | uspeshno           |
| [subagent-adapter-analitiki] Avtomat zaversheniya lokaljnogo adaptera analitiki                                       | 12,322 s     | neuspeshno         |
| [subagent-adapter-analitiki] Diagnostika avtomata zaversheniya analitiki                                              | 12,247 s     | neuspeshno         |
| [subagent-adapter-analitiki] Povtor avtomata zaversheniya analitiki                                                   | 12,902 s     | uspeshno           |
| [subagent-adapter-analitiki] Rasshirennyiye testyi avtomata zaversheniya analitiki                                        | 16,81 s      | uspeshno           |
| [zakrytie_kartochki] Domennoye zaversheniye kartochki FUM-STEP-0096                                                     | 0,387 s      | neuspeshno         |
| [zakrytie_kartochki] Domennoye zaversheniye kartochki FUM-STEP-0096 — povtor posle ochistki selector                     | 0,455 s      | uspeshno           |
| [korenj] Transliteraciya imeni novogo analiticheskogo adaptera                                                        | 5,285 s      | uspeshno           |
| [subagent-adapter-analitiki] Obsjhiye i specializirovannyiye ograzhdeniya analitiki                                        | 25,953 s     | uspeshno           |
| [subagent-adapter-analitiki] Finaljnyiye avtonomnyiye testyi analitiki zavershyonnyikh shagov                                 | 25,512 s     | uspeshno           |
| [kanonicheskoye_imya_adaptera] Proverka kanonicheskogo imeni analiticheskogo adaptera                                    | 2,268 s      | uspeshno           |
| [terminalizaciya_dispatchera] Krasnyiye testyi terminalizacii analiticheskogo zapuska                                   | 79,59 s      | neuspeshno         |
| [subagent-adapter-analitiki] Krasnyij rubezh soglasovannosti kursora analitiki                                        | 26,386 s     | neuspeshno         |
| [subagent-adapter-analitiki] Zelyonyij rubezh soglasovannosti kursora analitiki                                        | 26,743 s     | uspeshno           |
| [subagent-adapter-analitiki] red-exact-once-analytics-witness-management                                            | 32,332 s     | neuspeshno         |
| [subagent-adapter-analitiki] exact-once-analytics-witness-management-implementation                                 | 38,386 s     | uspeshno           |
| [subagent-adapter-analitiki] queue-regression-after-analytics-witness                                               | 194,622 s    | neuspeshno         |
| [subagent-adapter-analitiki] analytics-exact-once-final-narrow                                                      | 40,478 s     | uspeshno           |
| [subagent-adapter-analitiki] queue-regression-final-after-reset-preserve                                            | 177,383 s    | neuspeshno         |
| [terminalizaciya_dispatchera] Sintaksis tochnoj terminalizacii analitiki                                             | 0,07 s       | uspeshno           |
| [terminalizaciya_dispatchera] Uzkiye testyi tochnoj terminalizacii analitiki                                           | 9,044 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Tochnaya zavershyonnaya pretenziya posle pozdnej peredachi                                   | 6,695 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Sovmestimostj identifikatora zavershyonnoj analitiki                                    | 6,451 s      | uspeshno           |
| [subagent-adapter-analitiki] queue-completion-ledger-reset-isolation                                                | 6,997 s      | uspeshno           |
| [subagent-adapter-analitiki] queue-chain-transition-isolation                                                       | 9,096 s      | uspeshno           |
| [subagent-adapter-analitiki] queue-main-failfast-trace                                                              | 179,901 s    | uspeshno           |
| [terminalizaciya_dispatchera] Sintaksis reset-testov analitiki                                                      | 0,081 s      | uspeshno           |
| [terminalizaciya_dispatchera] Tri okna oficialjnogo reset analitiki                                                 | 9,218 s      | uspeshno           |
| [subagent-adapter-analitiki] analytics-exact-once-post-strengthening                                                | 40,319 s     | uspeshno           |
| [subagent-adapter-analitiki] queue-regression-final-exact-once                                                      | 202,398 s    | uspeshno           |
| [terminalizaciya_dispatchera] Zapret legacy-success zhivyikh adapterov                                                 | 3,814 s      | uspeshno           |
| [terminalizaciya_dispatchera] Regressii upravlyayusjhego fence rezervacij                                               | 1,922 s      | neuspeshno         |
| [subagent-adapter-analitiki] analytics-exact-once-cli-smoke-final                                                   | 40,88 s      | uspeshno           |
| [terminalizaciya_dispatchera] Upravlyayusjhiye gonki rezervacii i analiticheskoj pretenzii                                | 1,548 s      | neuspeshno         |
| [subagent-adapter-analitiki] analytics-duplicate-registry-red                                                       | 2,242 s      | neuspeshno         |
| [terminalizaciya_dispatchera] CAS upravleniya protiv novyikh rezervacii i claim                                        | 2,44 s       | uspeshno           |
| [subagent-adapter-analitiki] analytics-duplicate-registry-green                                                     | 2,191 s      | uspeshno           |
| [subagent-adapter-analitiki] analytics-later-handoff-retention-red                                                  | 5,887 s      | neuspeshno         |
| [subagent-adapter-analitiki] analytics-later-handoff-retention-green                                                | 5,795 s      | uspeshno           |
| [subagent-adapter-analitiki] analytics-exact-once-current-tree-final                                                | 51,122 s     | uspeshno           |
| [terminalizaciya_dispatchera] Terminalizaciya analitiki s retention i realjnyim reset                                 | 19,009 s     | uspeshno           |
| [terminalizaciya_dispatchera] Reset analitiki do bind i verify                                                      | 10,371 s     | uspeshno           |
| [terminalizaciya_dispatchera] Retention analiticheskogo otchyota i kursora                                             | 12,8 s       | uspeshno           |
| [terminalizaciya_dispatchera] Sintaksis dispatcher terminalization                                                  | 0,07 s       | uspeshno           |
| [terminalizaciya_dispatchera] Sintaksis dispatcher ledger tests                                                     | 0,087 s      | uspeshno           |
| [terminalizaciya_dispatchera] Next-step ledger fallback positive                                                    | 3,262 s      | uspeshno           |
| [terminalizaciya_dispatchera] Next-step ledger fallback negative                                                    | 14,164 s     | uspeshno           |
| [korenj] Sukhoj plan russkikh obyyavlenij analiticheskogo adaptera                                                      | 0,083 s      | neuspeshno         |
| [korenj] Povtornyij sukhoj plan russkikh obyyavlenij analiticheskogo adaptera                                            | 0,085 s      | neuspeshno         |
| [korenj] Itogovyij sukhoj plan russkikh obyyavlenij analiticheskogo adaptera                                             | 0,108 s      | uspeshno           |
| [korenj] Avtonomnyiye testyi analitiki posle migracii obyyavlenij                                                       | 50,346 s     | uspeshno           |
| [terminalizaciya_dispatchera] Sintaksis durable clean witness FIFO                                                  | 0,137 s      | uspeshno           |
| [korenj] Polnyij nabor testov vyibora sleduyusjhego shaga posle rusifikacii novyikh obyyavlenij                              | 142,506 s    | neuspeshno         |
| [korenj] Kratkaya diagnostika otkazov test_branch_next_step posle rusifikacii                                        | 142,328 s    | neuspeshno         |
| [korenj] Kratkaya diagnostika otkazov test_render_heartbeat_prompt posle rusifikacii                                 | 0,436 s      | neuspeshno         |
| [korenj] Snimok schyotchikov next-step dlya sinkhronizacii kontraktnogo testa                                            | 0,729 s      | uspeshno           |
| [terminalizaciya_dispatchera] Sintaksis terminal i FIFO replay                                                      | 0,157 s      | uspeshno           |
| [terminalizaciya_dispatchera] Tekusjhiye testyi zhurnala zavershenij FIFO                                                 | 6,713 s      | uspeshno           |
| [korenj] Kontraktnyiye testyi heartbeat posle sinkhronizacii ozhidanij                                                   | 0,46 s       | neuspeshno         |
| [terminalizaciya_dispatchera] Tekusjhiye dispatcher ledger regressii                                                   | 17,882 s     | uspeshno           |
| [korenj] Kontraktnyiye testyi heartbeat posle tochnoj sinkhronizacii ozhidanij                                            | 0,46 s       | uspeshno           |
| [korenj] Polnyij nabor testov vyibora sleduyusjhego shaga posle rusifikacii i sinkhronizacii kontraktov                    | 148,539 s    | neuspeshno         |
| [korenj] Adapter analitiki: pre-host osvobozhdeniye i ochisjhennaya pretenziya                                             | 58,256 s     | neuspeshno         |
| [korenj] Povtor adaptera analitiki posle sinkhronizacii clean witness                                                | 54,586 s     | uspeshno           |
| [korenj] Snimok tekusjhego vyibora next-step dlya sinkhronizacii kontraktnogo testa                                      | 1,008 s      | uspeshno           |
| [korenj] Tochechnyiye testyi lease i tekusjhego vyibora next-step                                                           | 0,148 s      | neuspeshno         |
| [korenj] Tochechnyij test next-step: lease                                                                             | 0,235 s      | uspeshno           |
| [korenj] Tochechnyij test next-step: selection                                                                         | 1,94 s       | uspeshno           |
| [korenj] Finaljnyij polnyij nabor testov vyibora sleduyusjhego shaga                                                       | 143,599 s    | uspeshno           |
| [terminalizaciya_dispatchera] Krasnyij cikl durable FIFO witnesses                                                   | 0,039 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Krasnyij cikl durable FIFO witnesses 2                                                 | 13,791 s     | uspeshno           |
| [korenj] Kontrakt heartbeat: osvobozhdeniye i chistoye zaversheniye analitiki                                             | 0,457 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher analytics finished-clean durable integration                               | 4,36 s       | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher syntax after analytic release fence                                        | 0,129 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher analytic pre-host release fencing                                          | 2,655 s      | neuspeshno         |
| [terminalizaciya_dispatchera] dispatcher analytic pre-host claim release                                            | 1,859 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher analytic release CAS race                                                  | 1,416 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher durable cleanup and release fences                                         | 8,95 s       | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher completion ledger corruption fail closed                                   | 17,315 s     | uspeshno           |
| [terminalizaciya_dispatchera] FIFO completion ledger cleanup replay and resume fence                                | 14,039 s     | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher analytic release across branch advance                                     | 4,853 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher durable cleanup reopens threshold                                          | 5,026 s      | uspeshno           |
| [terminalizaciya_dispatchera] full dispatcher test suite after terminalization                                      | 167,518 s    | neuspeshno         |
| [korenj] Marker shtatnogo sbrosa ograzhdayet specializirovannoye zaversheniye analitiki                                   | 2,922 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher regression fixes syntax                                                    | 0,109 s      | uspeshno           |
| [terminalizaciya_dispatchera] dispatcher full-suite regressions targeted                                            | 19,534 s     | neuspeshno         |
| [terminalizaciya_dispatchera] dispatcher reset fallback and process contract regressions                            | 3,691 s      | uspeshno           |
| [korenj] Vse mutacii analiticheskoj pretenzii ograzhdenyi markerom shtatnogo sbrosa                                     | 6,648 s      | uspeshno           |
| [korenj] Polnyij nabor analitiki posle ograzhdeniya vsekh mutacij ot sbrosa                                             | 70,349 s     | uspeshno           |
| [terminalizaciya_dispatchera] Celevyiye testyi ograzhdeniya obsjhej analiticheskoj terminalizacii ot sbrosa                 | 9,272 s      | uspeshno           |
| [terminalizaciya_dispatchera] Krasnyij test sokhraneniya pretenzii sleduyusjhego shaga shtatnyim sbrosom                     | 1,151 s      | neuspeshno         |
| [korenj] Krasnyij test povrezhdyonnoj obyichnoj ocheredi analitiki                                                        | 0,993 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Proverka sintaksisa reset-aware terminalization                                       | 0,154 s      | uspeshno           |
| [terminalizaciya_dispatchera] Celevyiye testyi dolgovechnogo dokazateljstva sleduyusjhego shaga posle sbrosa                | 9,248 s      | uspeshno           |
| [korenj] Zelyonyij test povrezhdyonnoj obyichnoj ocheredi analitiki                                                        | 0,872 s      | uspeshno           |
| [korenj] Polnyij nabor testov analitiki posle strogoj proverki ocheredi                                               | 69,443 s     | uspeshno           |
| [terminalizaciya_dispatchera] Celevyiye testyi matricyi sokhraneniya i osvobozhdeniya pretenzii posle sbrosa                | 13,001 s     | uspeshno           |
| [terminalizaciya_dispatchera] Regressii sbrosa ledger i analiticheskoj terminalization                               | 57,759 s     | uspeshno           |
| [korenj] Krasnyij test run-fence posle shtatnogo sbrosa ocheredi                                                       | 1,928 s      | neuspeshno         |
| [korenj] Zelyonyij test run-fence posle shtatnogo sbrosa ocheredi                                                       | 1,906 s      | uspeshno           |
| [korenj] Testyi kanonicheskogo zaversheniya shtatnogo sbrosa v run-fence                                                 | 1,99 s       | uspeshno           |
| [korenj] Polnyij nabor next-step i heartbeat posle reset-completion                                                  | 146,624 s    | neuspeshno         |
| [terminalizaciya_dispatchera] Proverka sintaksisa posle matricyi reset recovery                                      | 0,105 s      | uspeshno           |
| [terminalizaciya_dispatchera] Tri kriticheskikh scenariya preserve reset recovery                                      | 14,775 s     | uspeshno           |
| [korenj] Sinkhronizaciya dochernego recovery i no-publish heartbeat-kontrakta                                          | 0,29 s       | neuspeshno         |
| [korenj] Tochnyij no-publish kontrakt dochernego heartbeat                                                             | 0,208 s      | uspeshno           |
| [terminalizaciya_dispatchera] Polnyij nabor testov dispetchera avtomatizacij                                          | 198,998 s    | neuspeshno         |
| [korenj] Fail-fast next-step posle sinkhronizacii heartbeat-kontrakta                                                | 40,872 s     | neuspeshno         |
| [korenj] Sinkhronizaciya idempotentnogo claim i create_thread heartbeat                                               | 0,221 s      | uspeshno           |
| [korenj] Vtoroj fail-fast next-step posle heartbeat-sinkhronizacii                                                   | 40,755 s     | neuspeshno         |
| [korenj] Povtornyij polnyij nabor testov vyibora sleduyusjhego shaga                                                       | 38,625 s     | neuspeshno         |
| [korenj] Tochechnyij heartbeat-kontrakt oblasti zapreta povtora                                                        | 0,191 s      | neuspeshno         |
| [korenj] Tochechnyij heartbeat-kontrakt oblasti zapreta povtora posle utochneniya                                        | 0,187 s      | uspeshno           |
| [korenj] Povtornyij fail-fast nabora sleduyusjhego shaga posle utochneniya heartbeat                                       | 146,456 s    | uspeshno           |
| [terminalizaciya_dispatchera] Tochechnyiye regressii terminalization posle polnogo nabora                               | 13,308 s     | uspeshno           |
| [terminalizaciya_dispatchera] Polnyij nabor zhurnala zavershenij FIFO                                                  | 13,383 s     | uspeshno           |
| [terminalizaciya_dispatchera] Polnyij nabor ocheredi posle terminalization                                            | 206,613 s    | neuspeshno         |
| [terminalizaciya_dispatchera] Krasnyiye testyi bezopasnogo osvobozhdeniya posle sbrosa                                   | 12,445 s     | neuspeshno         |
| [terminalizaciya_dispatchera] Bezopasnoye osvobozhdeniye posle sbrosa                                                  | 15,691 s     | uspeshno           |
| [terminalizaciya_dispatchera] Bezopasnoye osvobozhdeniye i gonka pretenzii                                             | 19,764 s     | uspeshno           |
| [terminalizaciya_dispatchera] Rasshirennaya matrica reset ledger release                                              | 82,93 s      | uspeshno           |
| [terminalizaciya_dispatchera] Polnyij nabor dispetchera posle terminalization                                         | 211,118 s    | neuspeshno         |
| [korenj] Krasnyij replay-test osvobozhdeniya kartochochnoj pretenzii                                                     | 1,131 s      | neuspeshno         |
| [korenj] Idempotentnoye osvobozhdeniye kartochochnoj pretenzii                                                           | 1,12 s       | uspeshno           |
| [korenj] Polnyij next-step posle idempotentnogo osvobozhdeniya                                                         | 149,943 s    | uspeshno           |
| [terminalizaciya_dispatchera] Regressii polnogo dispatcher posle safe release                                       | 16,024 s     | uspeshno           |
| [terminalizaciya_dispatchera] Povtornyij polnyij nabor dispetchera posle safe release                                  | 136,688 s    | prervano — SIGINT |
| [terminalizaciya_dispatchera] Krasnyiye testyi ograzhdeniya pretenzii na granice sredyi                                   | 4,889 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Krasnyij test ustarevshej granicyi sredyi posle shtatnogo sbrosa                           | 7,758 s      | neuspeshno         |
| [korenj] Krasnyij test vzaimnogo ograzhdeniya osvobozhdeniya kartochochnoj pretenzii                                       | 1,203 s      | neuspeshno         |
| [korenj] Vzaimnoye ograzhdeniye i replay osvobozhdeniya kartochochnoj pretenzii                                            | 2,585 s      | neuspeshno         |
| [korenj] Povtor vzaimnogo ograzhdeniya i replay kartochochnogo release                                                  | 2,611 s      | uspeshno           |
| [korenj] Polnyij next-step posle vzaimnogo ograzhdeniya release                                                        | 146,035 s    | uspeshno           |
| [terminalizaciya_dispatchera] Sintaksis ograzhdeniya granicyi sredyi                                                    | 0,113 s      | uspeshno           |
| [terminalizaciya_dispatchera] Zelyonyiye testyi ograzhdeniya granicyi sredyi i sbrosa                                       | 12,783 s     | neuspeshno         |
| [terminalizaciya_dispatchera] Povtor testov ograzhdeniya granicyi sredyi i sbrosa                                       | 12,901 s     | uspeshno           |
| [korenj] Krasnyij test release guard bez simple-reset boundary                                                       | 1,679 s      | uspeshno           |
| [korenj] Krasnyij release guard s obsjhej rezervaciyej bez boundary                                                     | 1,093 s      | neuspeshno         |
| [korenj] Ograzhdeniye claim i release obsjhej rezervaciyej bez boundary                                                  | 3,226 s      | uspeshno           |
| [korenj] Polnyij next-step posle boundary-independent guard                                                          | 148,459 s    | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher: reset-kvitanciya sokhranyayet tekusjhuyu cepochku                                 | 0,416 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: reset-kvitanciya sokhranyayet tekusjhuyu cepochku posle ispravleniya sintaksisa    | 8,04 s       | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: diagnostika reset-kvitancii cepochki                                       | 7,991 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: trace reset-kvitancii cepochki                                             | 7,715 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: reset-kvitanciya cepochki posle ispravleniya imeni                           | 7,75 s       | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher: canonical current-chain reset receipt positive and negatives              | 8,304 s      | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher reset contour: sintaksis source i tests                                    | 0,123 s      | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher: atomic reset claim ledger owner overwrite replay                          | 10,866 s     | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: atomic reset claim ledger owner overwrite replay after fixture fix        | 14,68 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: atomic reset claim ledger owner overwrite replay with exact live claim    | 18,745 s     | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher: next-step prehost release absence CAS                                     | 3,216 s      | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher: expanded reset ledger management begin-host contour                       | 224,037 s    | neuspeshno         |
| [terminalizaciya_dispatchera] Dispatcher: receipt without claim guard stays fail-closed                             | 4,13 s       | uspeshno           |
| [terminalizaciya_dispatchera] Dispatcher: expanded reset ledger management begin-host contour green rerun           | 224,838 s    | uspeshno           |
| [terminalizaciya_dispatchera] Krasnyij test dolgovechnogo chistogo zaversheniya sleduyusjhego shaga                          | 0,616 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Zelyonyij test dolgovechnogo chistogo zaversheniya sleduyusjhego shaga FIFO                     | 0,78 s       | uspeshno           |
| [terminalizaciya_dispatchera] Krasnyij integracionnyij test chistogo zaversheniya sleduyusjhego shaga posle pozdnej peredachi | 4,828 s      | neuspeshno         |
| [terminalizaciya_dispatchera] Zelyonyij integracionnyij test chistogo zaversheniya sleduyusjhego shaga posle pozdnej peredachi | 5,401 s      | uspeshno           |
| [terminalizaciya_dispatchera] schema6 OID-fence ocheredi                                                             | 1,563 s      | uspeshno           |
| [terminalizaciya_dispatchera] schema6 pozdnyaya peredacha i chuzhoj vladelec                                             | 0,089 s      | neuspeshno         |
| [terminalizaciya_dispatchera] schema6 pozdnyaya peredacha i chuzhoj vladelec povtor                                      | 5,82 s       | uspeshno           |
| [terminalizaciya_dispatchera] schema6 terminal reset mismatch replay                                                | 20,579 s     | neuspeshno         |
| [terminalizaciya_dispatchera] schema6 shtatnyij sbros replay povtor                                                   | 8,432 s      | uspeshno           |
| [terminalizaciya_dispatchera] staroye chistoye zaversheniye bez durable witness                                          | 3,465 s      | uspeshno           |
| [terminalizaciya_dispatchera] schema6 canonical clean route targeted                                                | 23,415 s     | uspeshno           |
| [terminalizaciya_dispatchera] perezaryadka sokhranyayet schema5 do schema6                                              | 15,51 s      | neuspeshno         |
| [terminalizaciya_dispatchera] perezaryadka schema4 schema5 i chistoye zaversheniye                                       | 16,064 s     | uspeshno           |
| [terminalizaciya_dispatchera] perezaryadka zatem schema6 late handoff common                                         | 6,545 s      | uspeshno           |
| [terminalizaciya_dispatchera] rearm schema6 integration reset mutation replay                                       | 40,969 s     | neuspeshno         |
| [terminalizaciya_dispatchera] rearm schema6 integration reset mutation replay povtor                                | 40,413 s     | uspeshno           |
| [terminalizaciya_dispatchera] rasshirennyij kontur perezaryadki sleduyusjhego shaga                                        | 31,612 s     | uspeshno           |
| [terminalizaciya_dispatchera] rasshirennyij dispatcher reset ledger management clean                                  | 128,43 s     | uspeshno           |
| [terminalizaciya_dispatchera] rasshirennyij FIFO zhurnal i chistyiye zaversheniya                                           | 14,663 s     | neuspeshno         |
| [terminalizaciya_dispatchera] rasshirennyij FIFO zhurnal i chistyiye zaversheniya povtor                                    | 15,001 s     | uspeshno           |
| [terminalizaciya_dispatchera] polnyij next-step posle fenced rearm                                                   | 144,931 s    | uspeshno           |
| [terminalizaciya_dispatchera] polnyij dispatcher discovery                                                           | 298,956 s    | neuspeshno         |
| [terminalizaciya_dispatchera] gonka novoj pretenzii posle schema6 reader                                            | 4,291 s      | uspeshno           |
| [terminalizaciya_dispatchera] polnyij FIFO discovery                                                                 | 206,428 s    | uspeshno           |
| [terminalizaciya_dispatchera] polnyij dispatcher discovery povtor                                                    | 299,957 s    | uspeshno           |
| [terminalizaciya_dispatchera] polnyij next-step discovery final                                                      | 145,576 s    | uspeshno           |
| [terminal_claim_cleanup] RED terminal claim reservation guards                                                      | 1,772 s      | neuspeshno         |
| [terminal_claim_cleanup] RED late claim CAS race                                                                    | 1,776 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN terminal claim reservation guards                                                    | 1,665 s      | uspeshno           |
| [terminal_claim_cleanup] GREEN late claim CAS race                                                                  | 2,28 s       | uspeshno           |
| [terminal_claim_cleanup] Targeted fast terminal claim consume schema4 schema5                                       | 11,174 s     | uspeshno           |
| [terminal_claim_cleanup] Targeted durable journal terminal claim consume                                            | 4,923 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted analytics reset terminal claim consume                                            | 5,208 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted cross adapter replay and own consume                                              | 5,561 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted terminal claim late replay CAS race                                               | 5,496 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted generic reservation compatibility                                                 | 1,877 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted generic reservation compatibility rerun                                           | 2,349 s      | uspeshno           |
| [terminal_claim_cleanup] Expanded adapter terminal claim exact once                                                 | 296,5 s      | uspeshno           |
| [terminal_claim_cleanup] Expanded universal reservation compatibility                                               | 21,159 s     | uspeshno           |
| [terminal_claim_cleanup] Full dispatcher suite after terminal claim consume                                         | 334,846 s    | uspeshno           |
| [terminal_claim_cleanup] Full FIFO queue suite after terminal claim consume                                         | 204,751 s    | uspeshno           |
| [terminal_claim_cleanup] Full next-step suite after terminal claim consume                                          | 151,53 s     | neuspeshno         |
| [terminal_claim_cleanup] Diagnose heartbeat prompt failures after terminal claim docs                               | 0,421 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted heartbeat child release and publication contract                                  | 0,41 s       | neuspeshno         |
| [terminal_claim_cleanup] Targeted heartbeat child contract final                                                    | 0,459 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted heartbeat tick scope and live repair limit                                        | 0,189 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted heartbeat live repair budget                                                      | 0,183 s      | uspeshno           |
| [terminal_claim_cleanup] Full heartbeat renderer and status snapshot suite                                          | 0,465 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted heartbeat common consume then separate claim                                      | 0,209 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted heartbeat common consume then separate claim rerun                                | 0,185 s      | neuspeshno         |
| [terminal_claim_cleanup] RED legacy schema4 completion slot guard                                                   | 7,02 s       | neuspeshno         |
| [terminal_claim_cleanup] RED legacy schema4 completion slot guard exact                                             | 8,608 s      | neuspeshno         |
| [korenj] Sukhoj plan pervoj kartyi perevoda obyyavlenij                                                                | 0,092 s      | uspeshno           |
| [korenj] Primeneniye pervoj kartyi perevoda obyyavlenij                                                                | 0,093 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted legacy schema4 completion slot guard green                                        | 10,598 s     | neuspeshno         |
| [terminal_claim_cleanup] Targeted terminal schema4 FIFO replay diagnostic                                           | 10,961 s     | neuspeshno         |
| [terminal_claim_cleanup] Targeted legacy schema4 guard and terminal replay                                          | 12,338 s     | uspeshno           |
| [terminal_claim_cleanup] Targeted queue schema4 atomic migration                                                    | 0,875 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted schema4 migrate late handoff common terminal                                      | 3,619 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted schema4 migration late handoff terminal green                                     | 5,943 s      | uspeshno           |
| [terminal_claim_cleanup] Expanded completion ledger suite after schema4 bridge                                      | 15,665 s     | uspeshno           |
| [terminal_claim_cleanup] Expanded adapter schema4 bridge cluster                                                    | 18,175 s     | uspeshno           |
| [terminal_claim_cleanup] Expanded adapter fast and durable terminal cluster                                         | 16,62 s      | uspeshno           |
| [terminal_claim_cleanup] Targeted schema4 preterminal and terminal replay freeze                                    | 13,378 s     | uspeshno           |
| [korenj] Peresborka reyestra planirovaniya posle FUM-STEP-0096                                                        | 0,307 s      | uspeshno           |
| [korenj] Proverka reyestra planirovaniya posle FUM-STEP-0096                                                          | 0,351 s      | uspeshno           |
| [korenj] Sukhoj plan vtoroj kartyi perevoda obyyavlenij                                                                | 0,146 s      | uspeshno           |
| [korenj] Primeneniye vtoroj kartyi perevoda obyyavlenij                                                                | 0,145 s      | uspeshno           |
| [terminal_claim_cleanup] RED official reset schema4 safe failure                                                    | 7,866 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted official reset schema4 safe failure green                                         | 9,37 s       | neuspeshno         |
| [terminal_claim_cleanup] RED post-commit reset schema4 claim CAS guard                                              | 3,999 s      | neuspeshno         |
| [terminal_claim_cleanup] Targeted official reset schema4 safe and post-commit guards                                | 19,124 s     | neuspeshno         |
| [terminal_claim_cleanup] GREEN official reset schema4 safe and post-commit guards                                   | 22,142 s     | uspeshno           |
| [terminal_claim_cleanup] Expanded adapter official reset contour after schema4 fix                                  | 96,242 s     | neuspeshno         |
| [terminal_claim_cleanup] Targeted reset receipt previous completion preserved claim                                 | 3,587 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN reset receipt previous completion preserved claim                                    | 4,358 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN reset receipt previous schema4 completion preserved claim                            | 4,069 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN reset receipt previous schema4 completion preserved claim canonical guards           | 4,285 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN reset receipt prior schema4 completion and changed queue                             | 5,564 s      | uspeshno           |
| [terminal_claim_cleanup] GREEN expanded adapter official reset contour after schema4 fix                            | 97,732 s     | uspeshno           |
| [terminal_claim_cleanup] Sukhoj plan tretjyej kartyi perevoda obyyavlenij                                               | 0,254 s      | neuspeshno         |
| [terminal_claim_cleanup] Sukhoj plan tretjyej kartyi perevoda obyyavlenij posle ustraneniya kollizii                     | 0,36 s       | uspeshno           |
| [terminal_claim_cleanup] Primeneniye tretjyej kartyi perevoda obyyavlenij                                               | 0,362 s      | uspeshno           |
| [korenj] Peresborka planovogo reyestra posle sinkhronizacii reset-kontrakta                                           | 0,302 s      | uspeshno           |
| [korenj] Proverka planovogo reyestra posle sinkhronizacii reset-kontrakta                                             | 0,308 s      | uspeshno           |
| [terminal_claim_cleanup] AST-proverka ogranichennyikh pereimenovanij chetyiryokh fajlov                                    | 0,035 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN AST-proverka ogranichennyikh pereimenovanij chetyiryokh fajlov                              | 0,248 s      | uspeshno           |
| [terminal_claim_cleanup] Polnaya inventarizaciya obyyavlenij posle tretjyej kartyi                                       | 5,031 s      | uspeshno           |
| [terminal_claim_cleanup] Celevoj zhurnal zavershenij posle rusifikacii obyyavlenij                                     | 16,109 s     | uspeshno           |
| [terminal_claim_cleanup] Celevyiye pereimenovannyiye testyi adaptera posle rusifikacii                                   | 78,95 s      | uspeshno           |
| [terminal_claim_cleanup] Proverka diff chetyiryokh fajlov i kart rusifikacii                                            | 0,024 s      | uspeshno           |
| [terminal_claim_cleanup] Polnyij dispatcher discovery posle reset-fix i rusifikacii                                  | 399,609 s    | uspeshno           |
| [korenj] Polnyij nabor analitiki zavershyonnyikh shagov posle finaljnogo freeze                                           | 76,855 s     | uspeshno           |
| [korenj] Polnyij nabor FIFO posle finaljnogo freeze                                                                  | 223,968 s    | uspeshno           |
| [korenj] AST-proverka chetyiryokh scope-aware pereimenovanij next-step                                                  | 0,058 s      | uspeshno           |
| [korenj] Polnyij nabor sleduyusjhego shaga posle finaljnoj scope-aware rusifikacii                                       | 151,957 s    | neuspeshno         |
| [korenj] Povtor tryokh ispravlennyikh next-step regressions                                                             | 7,96 s       | uspeshno           |
| [korenj] Povtor polnogo nabora sleduyusjhego shaga posle ispravleniya scope-aware regressij                              | 150,334 s    | neuspeshno         |
| [korenj] Povtor CAS-race next-step posle soglasovaniya imeni ssyilki                                                  | 1,391 s      | uspeshno           |
| [korenj] Finaljnyij polnyij nabor sleduyusjhego shaga                                                                     | 148,057 s    | uspeshno           |
| [korenj] Obnovleniye tochnogo snimka ostatka obyyavlenij koda                                                          | 4,419 s      | uspeshno           |
| [korenj] Proverka tochnogo snimka ostatka obyyavlenij koda                                                            | 4,402 s      | uspeshno           |
| [korenj] Postroyeniye sokhranyonnogo revjyu analitiki zavershyonnyikh shagov                                                  | 0,184 s      | uspeshno           |
| [korenj] Proverka sokhranyonnogo revjyu analitiki zavershyonnyikh shagov                                                    | 0,069 s      | uspeshno           |
| [korenj] Obnovleniye svezhesti Markdown tekusjhej sessii                                                                | 0,649 s      | uspeshno           |
| [korenj] Obnovleniye teplovoj kartyi grafa Obsidian                                                                   | 0,343 s      | uspeshno           |
| [korenj] Finaljnaya kompleksnaya proverka FUM-STEP-0096                                                               | 35,11 s      | neuspeshno         |
| [korenj] Diagnostika mashinno-lokaljnogo puti posle smoke-check                                                      | 12,374 s     | neuspeshno         |
| [korenj] Proverka suzhennogo policy mashinno-lokaljnyikh putej                                                          | 12,377 s     | uspeshno           |
| [korenj] Povtornaya finaljnaya kompleksnaya proverka FUM-STEP-0096                                                     | 68,595 s     | neuspeshno         |
| [korenj] Povtornoye obnovleniye svezhesti posle ustraneniya oshibok svyaznosti                                            | 0,61 s       | uspeshno           |
| [korenj] Povtornoye obnovleniye grafa posle ustraneniya oshibok svyaznosti                                               | 0,348 s      | uspeshno           |
| [korenj] Celevaya proverka svyaznosti rabochej sessii                                                                  | 26,416 s     | uspeshno           |
| [korenj] Itogovaya kompleksnaya proverka FUM-STEP-0096 posle ispravlenij                                              | 2272,702 s   | uspeshno           |
| [terminal_claim_cleanup] RED: ogranichennyij dirty JSON i povtor commit bez message-file                              | 3,981 s      | neuspeshno         |
| [terminal_claim_cleanup] RED: oversized dirty path                                                                  | 0,237 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN: ogranichennyij dirty JSON i povtor commit bez message-file                            | 4,637 s      | neuspeshno         |
| [terminal_claim_cleanup] GREEN: bounded dirty envelope and pre-message replay                                       | 3,845 s      | uspeshno           |
| [terminal_claim_cleanup] Expanded FIFO dirty and commit replay contour                                              | 15,709 s     | uspeshno           |
| [terminal_claim_cleanup] FIFO queue syntax and owned diff check                                                     | 0,175 s      | uspeshno           |
| [terminal_claim_cleanup] Final targeted bounded dirty and pre-message replay                                        | 3,992 s      | uspeshno           |
| [terminal_claim_cleanup] Final expanded FIFO dirty and commit replay contour                                        | 15,114 s     | uspeshno           |
| [terminal_claim_cleanup] Final FIFO syntax and owned diff check                                                     | 0,165 s      | uspeshno           |
| [[korenj]] Povtornaya proverka diff posle pryamoj inspekcii                                                           | 0,02 s       | uspeshno           |
| [[korenj]] Polnyij nabor FIFO posle ogranicheniya dirty-otveta                                                         | 217,987 s    | uspeshno           |
| [[korenj]] Obnovleniye svezhesti Markdown posle ispravleniya peredachi                                                  | 0,689 s      | uspeshno           |
| [[korenj]] Obnovleniye teplovoj kartyi posle ispravleniya peredachi                                                     | 0,352 s      | uspeshno           |
| [[korenj]] Povtornoye obnovleniye svezhesti otchyota pered smoke                                                         | 0,724 s      | uspeshno           |
| [[korenj]] Itogovaya kompleksnaya proverka posle ispravleniya finaljnoj peredachi                                       | 42,638 s     | neuspeshno         |
| [[korenj]] Svodka polnogo inventarya obyyavlenij pered obnovleniyem snimka                                             | 4,847 s      | uspeshno           |
| [[korenj]] Obnovleniye tochnogo snimka obyyavlenij posle kirillicheskoj pravki FIFO                                     | 4,777 s      | uspeshno           |
| [[korenj]] Obnovleniye svezhesti posle sinkhronizacii snimka obyyavlenij                                                | 0,635 s      | uspeshno           |
| [[korenj]] Povtornaya sinkhronizaciya teplovoj kartyi pered smoke                                                       | 0,429 s      | uspeshno           |
| [[korenj]] Povtornaya itogovaya kompleksnaya proverka posle obnovleniya snimka                                          | 70,674 s     | prervano — SIGINT |
| [[korenj]] Obnovleniye svezhesti posle utochneniya zatronutyikh fajlov                                                    | 0,639 s      | uspeshno           |
| [[korenj]] Sinkhronizaciya teplovoj kartyi posle utochneniya fajlov                                                      | 0,354 s      | uspeshno           |
| [[korenj]] Celevaya svyaznostj pered povtornyim polnyim smoke                                                           | 27,598 s     | uspeshno           |
| [[korenj]] Finaljnaya kompleksnaya proverka posle zamyikaniya svyaznosti                                                 | 33,51 s      | prervano — SIGINT |
| [[korenj]] Obnovleniye svezhesti posle yazyikovoj pravki                                                                | 0,638 s      | uspeshno           |
| [[korenj]] Sinkhronizaciya teplovoj kartyi posle yazyikovoj pravki                                                       | 0,358 s      | uspeshno           |
| [[korenj]] Proverka svyaznosti sessii pered itogovoj kompleksnoj proverkoj                                           | 27,774 s     | uspeshno           |
| [[korenj]] Obnovleniye svezhesti Markdown posle utochneniya kontrakta kommita                                           | 0,613 s      | uspeshno           |
| [[korenj]] Obnovleniye svezhesti grafa Obsidian posle utochneniya kontrakta kommita                                     | 0,382 s      | uspeshno           |
| [[korenj]] Povtornaya proverka svyaznosti sessii posle utochneniya kontrakta kommita                                    | 26,143 s     | uspeshno           |
| [[korenj]] Obnovleniye svezhesti Markdown posle fiksacii poryadka bajtov                                               | 0,615 s      | uspeshno           |
| [[korenj]] Proverka svezhesti grafa Obsidian pered polnoj proverkoj                                                  | 0,326 s      | uspeshno           |
| [[korenj]] Okonchateljnaya kompleksnaya proverka posle ispravleniya kommita                                             | 2474,799 s   | uspeshno           |

Obsjheye vremya pryamyikh zapuskov proverok: 15763,469 s.

<!-- FUM-CHECK-RUNS:END -->

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, realizaciya, razdelyonnyiye audityi i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch`, `update_plan` i `collaboration.*` — lokaljnyiye processyi, proveryayemyiye pravki, rabochij plan i paralleljnyiye realizacionnyiye i read-only-zadachi; versii kontraktov otdeljno ne raskryivayutsya.
- `zsh 5.9`, `git 2.54.0`, `Python 3.14.6`, `ripgrep 15.2.0` i standartnyiye sistemnyiye komandyi — lokaljnyiye Git-fiksturyi, generatoryi, testyi, poisk i inspekciya. Vneshnyaya setj dlya soderzhateljnoj rabotyi ne ispoljzovalasj.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-dispetcher-avtomatizacij-fum](../../Instrumentyi/fum-dispetcher-avtomatizacij-fum/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-analitika-zavershyonnyikh-shagov](../../Instrumentyi/fum-analitika-zavershyonnyikh-shagov/SKILL.md), [fum-otchyotyi-o-zapuskakh-proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-perevod-obyyavlenij-koda-na-russkij-yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md), [fum-revjyu-prodelannoj-rabotyi](../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — FIFO i run-fence, dva adaptera dispetchera, proverochnyij otchyot, planovyij kaskad, rusifikaciya obyyavlenij, sokhranyonnoye revjyu, recency, graf, svyaznostj i itogovaya priyomka.

## Povliyal na fajlyi

- [tekusjhij iskhodnyij zapros](zapros.md)
- [tekusjhij otchyot](otchyot.md)
- [materialyi tekusjhej sessii](materialyi/)
- [osnovnyiye pravila repozitoriya](../../AGENTS.md)
- [kornevoj README](../../README.md)
- [arkhitekturnaya i eksperimentaljnaya dokumentaciya](../../Dokumentaciya/)
- [glossarij dispetchera avtomatizacij](../../Glossarij/dispetcher-avtomatizacij-FUM.md)
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [reyestr, selector i kartochki planirovaniya](../../Planirovaniye/)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0096-добавить-аналитику-по-числу-завершённых-шагов.md`
- [universaljnyij dispetcher avtomatizacij](../../Instrumentyi/fum-dispetcher-avtomatizacij-fum/)
- [analitika zavershyonnyikh shagov](../../Instrumentyi/fum-analitika-zavershyonnyikh-shagov/)
- [FIFO-ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/)
- [otchyotyi o zapuskakh proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/)
- [adapter sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/)
- [indeks instrumentov](../../Instrumentyi/README.md)
- [mashinnyij snimok ostatka obyyavlenij koda](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json)
- [indeks zhurnala](../README.md)
- [indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [graf Obsidian](../../../../../.obsidian/graph.json)
- [sokhranyonnoye revjyu i yego konfiguraciya](materialyi/revjyu/)

## Proverki

Finaljnyiye polnyiye naboryi proshli bez oshibok: 138 testov universaljnogo dispetchera, polnyij nabor FIFO-ocheredi posle ispravleniya finaljnoj peredachi, 182 testa sleduyusjhego shaga i 42 testa analiticheskogo adaptera. Novyij TDD-kontur snachala vosproizvyol otvet `dirty` razmerom boleye 141 tyisyach bajt i otkaz vosstanovleniya posle ischeznoveniya fajla soobsjheniya, zatem proshyol 5 adresnyikh i 11 rasshirennyikh scenariyev; polnyij FIFO-nabor podtverdil otsutstviye regressii. Tochnyij inventarj obyyavlenij sovpal s osmyislenno obnovlyonnyim snimkom; nezavisimyiye exact-once- i publikacionnyij audityi ne vyiyavili P0/P1, novyikh latinskikh sobstvennyikh obyyavlenij, skryityikh runtime-znachenij, mashinno-lokaljnyikh putej libo bityikh lokaljnyikh ssyilok. Sokhranyonnoye revjyu ne soderzhit susjhestvennyikh zamechanij. Povtornyij itogovyij polnyij smoke-check yavlyayetsya poslednim pryamyim zapuskom pered zakryitiyem mashinnogo bloka, i yego iskhod otrazhayetsya v tablice vyishe. Domennoye zaversheniye kartochki posle udaleniya yeyo pokoleniya iz selector vyipolneno shtatnoj komandoj sinkhronizacii statusa i ssyilok; pervyij fail-closed-vyizov verno otklonil yesjhyo ostavavshuyusya tekstovuyu ssyilku iz kanonicheskogo selector, povtor posle yeyo ispravleniya zavershilsya uspeshno.

Vo vremya chteniya izmenyonnyikh fragmentov odin `git diff --check` byil neprednamerenno zapusjhen napryamuyu v sostavnoj inspekcionnoj komande. On nichego ne izmenil; tot zhe nabor putej srazu povtorno proveren cherez obyazateljnuyu otchyotnuyu obyortku i otrazhyon v mashinnom zhurnale. Eto procedurnoye otkloneniye sokhraneno yavno, a ne skryito zelyonyim povtorom.

Neskoljko novyikh zapisej subagenta poluchili angloyazyichnyiye chelovekochitayemyiye nazvaniya. Uzhe khyeshirovannyiye fakticheskiye zapisi ne perepisyivalisj: oni sokhranenyi kak tochnoye istoricheskoye svideteljstvo zapuska, a navyik otchyotov teperj yavno trebuyet russkiye sobstvennyiye nazvaniya i ispolnitelej dlya budusjhikh zapuskov, ostavlyaya latinicej lishj neobkhodimyiye tekhnicheskiye tokenyi.

Metka ispolnitelya `[корень]` takzhe uzhe vkhodit v khyeshirovannyiye mashinnyiye zapisi. Tekusjhij formirovatelj tablicyi dobavil k nej vtoruyu paru skobok, poetomu posledovateljnostj `[[корень]]` v upravlyayemom bloke yavlyayetsya sokhranyonnyim artefaktom otobrazheniya, a ne ssyilkoj na fajl `корень.md`. Mashinnyiye zapisi i zakryityij snimok ne perepisyivalisj; budusjhaya versiya formirovatelya dolzhna ekranirovatj skobki metki do postroyeniya Markdown, sokhranyaya iskhodnoye svideteljstvo doslovno.

Pervyij povtornyij smoke-check posle ispravleniya ostanovilsya na rannem shage proverki snimka obyyavlenij: novyiye kirillicheskiye funkcii sdvinuli pozicii prezhnego inventarya. Polnaya inventarizaciya sokhranila prezhniye 43 194 nablyudayemyikh latinskikh obyyavleniya i tu zhe svodku po yazyikam, posle chego snimok byil obnovlyon yavnoj komandoj lokaljnogo navyika; neuspeshnyij smoke sokhranyon otdeljnoj mashinnoj zapisjyu i ne zaschitan kak priyomka.

Sleduyusjhij smoke-check byil prervan na rannem proverochnom prefikse, kogda do zaversheniya svyaznosti obnaruzhilosj, chto novyij normativnyij fajl navyika otchyotov yesjhyo ne perechislen sredi zatronutyikh putej tekusjhej sessii. Prodolzhatj zavedomo neprinimayemyij progon radi dopolniteljnyikh zelyonyikh rezuljtatov ne stali; spisok fajlov dopolnen, a priyomka nachinayetsya zanovo polnyim zapuskom.

Yesjhyo odin povtor byil prervan na tom zhe rannem prefikse posle obnaruzheniya nenuzhnogo angloyazyichnogo slova v novoj normativnoj formulirovke. Termin zamenyon russkim ekvivalentom do dorogikh naborov; prervannyij vyizov takzhe ostayotsya otdeljnoj mashinnoj zapisjyu i ne schitayetsya priyomkoj.

## Resheniya i ogranicheniya

- Nachaljnoye `N = 5` — yavnoye operacionnoye znacheniye kanonicheskogo reyestra, a ne metrika kachestva ili zayavleniye o zhelateljnoj chastote.
- Istoriya zavershenij ne perepisyivayetsya pri smene `N`; novoye pokoleniye obyazano yavno vyibratj politiku uzhe nakoplennogo ostatka.
- Upravlyayusjhaya ploskostj vyibirayet, rezerviruyet i sozdayot zadachu, no ne pishet analiticheskij otchyot.
- Shtatnyij sbros sokhranyayet validnyij zhurnal, next-step claims skhem `4`/`5`/`6` i exact OID analiticheskoj pretenzii i ne vyizyivayet vneshnij `release`. Vse specializirovannyiye mutacii claim i obsjhiye perekhodyi rezuljtata CAS-ograzhdenyi OID obyichnoj ocheredi: aktivnyij reset-marker ikh blokiruyet, a posle finala oni prodolzhayutsya po novomu OID dazhe pri inom vladeljce. Common-terminal prioritetno prinimayet durable success ili clean proof; safe failure trebuyet exact receipt/host/ledger/current queue/branch i prezhniye reservation/epoch, a perekhodnaya skhema `4` dopolniteljno prokhodit istoricheskuyu proverku ready-vyibora. Terminal-success oboikh adapterov sokhranyayet claim dlya replay, a novyij reserve togo zhe adaptera atomarno poglosjhayet yego. Do host-granicyi otsutstviye pretenzii libo yeyo exact osvobozhdeniye po-prezhnemu podtverzhdayetsya dvumya posledovateljnyimi CAS-perekhodami. Avarijnyij marshrut arkhiviruyet oba vida runtime-sostoyaniya vmeste s ostaljnyim checkout-scoped konturom.
- Obsjhaya rezervaciya i management-fence proveryayut drug druga pod obsjhim CAS-perimetrom: nachalo nastrojki i perekhod zapuska k host-granice ne mogut odnovremenno schitatj sebya dopusjhennyimi.
- Publikaciya ne vkhodit v rezuljtat: nakoplennyij prefiks `refs/heads/master` mozhet opublikovatj toljko ruchnoj push poljzovatelya vne etoj zadachi; takoj push ne yavlyayetsya podtverzhdeniyem kazhdoj kartochki.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [sokhranyonnoye revjyu analitiki zavershyonnyikh shagov i odnokratnoj terminalizacii](materialyi/revjyu/2026-08-11_01-28-08_MSK_revjyu-analitiki-zavershyonnyikh-shagov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:14ed728200af1bf2c2f6ad6407bf364b3ae5ee5a6403af0e2b3cbf09117ad8d0 -->
<!-- FUM-MD-RECENCY:END -->
