# Otchyot 2026-08-13 18:17:47 MSK - Organizovatj paralleljnyiye sessii v izolirovannyikh fork poduzlakh

FUM-STEP-0148 zavershena kak dokumentaljnyij etalonnyij profilj pula linked worktree. Obyichnyij novyij chat pervyim instrumentaljnyim dejstviyem poluchayet exact committed snimok plana, aktivnyikh linij i ikh FIFO, ocenivayet rolj zadachi i vyibirayet read-only, novuyu paralleljnuyu liniyu libo posledovateljnoye prodolzheniye susjhestvuyusjhej. Lyuboj pishusjhij vyibor poluchayet yedinstvennyij neizmenyayemyij runtime-route exact `task_id`, atomarnyij s pervyim ticket obyichnoj FIFO, perekhodnoj zapisjyu `перейти-на-цепочку` libo worktree-pula. Nezavisimyij pisatelj lenivo zanimayet svobodnyij ili novyij slot `Подузлы/слот-NNNN`; prodolzheniye zhdyot handoff i rabotayet v tekh zhe slote, ref i FIFO bez vtorogo checkout. Odnovremenno odin slot imeyet toljko odnogo vladeljca.

Posle obryiva read-only `восстановить-сессию` vozvrasjhayet po exact `task_id` prezhniye assignment, slot, worktree, ref, FIFO, khyeshi marshruta i prodolzheniya i sleduyusjhuyu dopustimuyu fazu. Pered dopuskayusjhim libo terminaljnyim otvetom verify-only Git-tranzakciya sveryayet immutable task-route, pool-ref, queue-ref i exact vershinu worktree `HEAD`, posle chego nemedlennyij readback podtverzhdayet symbolic branch-ref naznacheniya na toj zhe vershine; nesovpadeniye zakryivayet vosstanovleniye bez novogo marshruta. Povtoryi materialization, join, handoff, ack i terminal readback ne sozdayut vtoroj katalog, bilet libo commit, a handoff/result replay dopolniteljno svyazan s SHA-256 tochnyikh UTF-8-bajtov soobsjheniya kommita. Posle terminaljnoj kvitancii i chistogo readback slot osvobozhdayetsya dlya novogo naznacheniya, a result-ref, commits i pasporta ostayutsya dostizhimyimi.

Realizovanyi avtomaticheskiye nezavisimoye agentskoye revjyu, sliyaniye i smyislovoye razresheniye konfliktov v otdeljnom integracionnom worktree s obyazateljnyim povtornyim revjyu. Opozdavsheye revjyu uzhe prinyatogo candidate libo result ne sozdayot novyij verdikt: vosstanavlivayemaya `review_sealed`-kvitanciya atomarno osvobozhdayet reviewer FIFO i slot bez izmeneniya revjyu i publikacij. Lokaljnyij `master` dvigayetsya toljko odnoj Git-tranzakciyej, kotoraya odnovremenno proveryayet exact base/head, peredayot obyichnuyu FIFO zaraneye sozdannomu prodolzheniyu, sokhranyayet kvitancii i CAS-obnovlyayet sostoyaniye pula. Zablokirovannyij ili poka neslivayemyij result-ref ne teryayetsya: posle proverki publikacionnoj chistotyi on poluchayet dolgovechnoye namereniye no-force-publikacii v nastroyennyij remote etogo zhe repozitoriya. Oshibka seti ili dostupa ostayotsya `publication_pending`, a sleduyusjhaya dopusjhennaya kornevaya zadacha avtomaticheski povtoryayet backlog.

Posledneye utochneniye poljzovatelya zamenilo prezhneye razresheniye GitHub-fork/push/pull-request dlya etoj zadachi: GitHub forks i pull request ne sozdavalisj. Razreshyon i realizovan toljko tochnyij no-force Git-transport result refs i prinyatogo `master` v uzhe nastroyennyij remote. On zakreplyayet yedinstvennyij syiroj URL i ne boleye odnogo `pushurl`, peredayot Git bukvaljnyij adres, otklonyayet remote-psevdonimyi i primenimyiye `url.*.insteadOf`/`pushInsteadOf`, a takzhe podavlyayet soprovozhdayusjhiye tegi, submodule, signed push i push-options; avtonomnaya priyomka ispoljzovala lokaljnyiye bare-remotes bez seti i sekretov.

## Profilj vremeni vyipolneniya

| Stadiya                     | Dliteljnostj            | Granicyi i sposob izmereniya                                                                                     |
| -------------------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO      | otdeljno ne izmereno    | Bilet `seq=21`, perechityivaniye `HEAD`, `ack-head` i dopusk podtverzhdenyi ocheredjyu; otdeljnyij tajmer ne vyolsya.    |
| Soderzhateljnaya rabota      | ne meneye 19 ch 14 min    | Do poslednego zavershyonnogo polnogo progona; analiz i proverki chastichno perekryityi.                              |
| Pryamyiye celevyiye proverki    | sm. tochnuyu summu nizhe   | Mashinnaya summa monotonnyikh dliteljnostej kazhdogo pryamogo vyizova sokhranena otchyotnoj obyortkoj.                    |
| Zaklyuchiteljnyij smoke-check | 2963,215 s              | Run #160: polnyij proverochnyij kontur zavershil 38 iz 38 etapov uspeshno, kod zaversheniya 0.                       |
| Atomarnyij commit+handoff   | vne zakryivayemogo snimka | Vyipolnyayetsya posle zakryitiya otchyota; dokazateljstvom sluzhit neizmenyayemaya Git-kvitanciya obyichnoj FIFO.             |

Granica profilya: ozhidaniye ocheredi, soderzhateljnaya rabota, pryamyiye proverki i finaljnaya peredacha izmeryayutsya razdeljno. Neuspeshnyiye RED-zapuski sokhranenyi kak TDD-svideteljstva, a ne skryityi itogovyim uspekhom. Adresnyij suite pula zavershilsya uspeshno: 38 scenariyev za 225,701 s. Itogovyij discovery ordinary FIFO, perekhodov i worktree-pula zavershilsya uspeshno: 228 testov za 579,110 s. Zaklyuchiteljnyij run #160 zavershil 38 iz 38 etapov kompleksnogo smoke-check uspeshno za 2963,215 s.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:edaefce3121a4b6dc655bcd0471fb11adb681534d2125a54e47733f3cd102cc0 -->

| Vyizov                                                                                                                            | Dliteljnostj | Rezuljtat         |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------ | ----------------- |
| [korenj] Krasnaya proverka pula worktree-poduzlov                                                                                 | 0,56 s       | neuspeshno         |
| [korenj] Celevaya proverka pula worktree-poduzlov posle pervoj realizacii                                                         | 1,477 s      | neuspeshno         |
| [korenj] Povtornaya celevaya proverka pula worktree-poduzlov                                                                       | 8,016 s      | uspeshno           |
| [korenj] Krasnaya proverka avtomaticheskogo revjyu integracii i publikacii result-ref                                               | 23,347 s     | neuspeshno         |
| [korenj] Celevaya proverka avtomaticheskogo revjyu integracii i publikacii result-ref                                               | 39,426 s     | uspeshno           |
| [korenj] Krasnaya proverka bootstrap sessii i publikacii prinyatogo master                                                         | 41,374 s     | neuspeshno         |
| [korenj] Celevaya proverka bootstrap sessii i publikacii prinyatogo master                                                         | 37,933 s     | uspeshno           |
| [korenj] Krasnaya proverka biyekcii zhivoj sessii i worktree-slota                                                                  | 44,419 s     | neuspeshno         |
| [korenj] Celevaya proverka polnogo kontura pula worktree-poduzlov                                                                 | 45,082 s     | uspeshno           |
| [korenj] Celevaya proverka pula posle perevoda obyyavlenij koda                                                                    | 27,273 s     | neuspeshno         |
| [korenj] Povtornaya proverka pula posle sinkhronizacii argparse                                                                    | 42,26 s      | uspeshno           |
| [korenj] RED: vosstanovleniye osvobozhdeniya, tochnyij prompt i CAS-readback                                                          | 46,655 s     | neuspeshno         |
| [korenj] RED: oblasti zapisi mezhdu aktivaciyami i pri commit-result                                                               | 5,136 s      | neuspeshno         |
| [korenj] GREEN-kandidat: ograzhdyonnyij pul, FIFO-most i publication intent                                                         | 55,328 s     | neuspeshno         |
| [korenj] Povtor FIFO-mosta lokaljnoj i konfliktnoj integracii                                                                    | 33,871 s     | uspeshno           |
| [korenj] Durable publication_pending i avtomaticheskij povtor result-ref                                                          | 5,475 s      | uspeshno           |
| [korenj] Polnaya priyomka worktree-pula posle nezavisimogo revjyu                                                                   | 67,275 s     | uspeshno           |
| [kornevoj agent] Polnaya priyomka worktree-pula posle ispravlenij nezavisimogo revjyu                                               | 67,637 s     | uspeshno           |
| [kornevoj agent] Peresborka planovogo reyestra posle utochneniya semantiki slota                                                    | 0,077 s      | neuspeshno         |
| [kornevoj agent] Peresborka planovogo reyestra s korrektnyim interfejsom                                                           | 0,344 s      | uspeshno           |
| [kornevaya sessiya] Sintaksicheskaya proverka ispravlenij gonok worktree-pula                                                        | 0,145 s      | uspeshno           |
| [kornevaya sessiya] Adresnaya priyomka ispravlennyikh gonok i ograzhdenij worktree-pula                                                 | 0,091 s      | neuspeshno         |
| [kornevaya sessiya] Priyomka atomarnoj integracii publikacii i pozdnikh CAS-gonok                                                    | 21,306 s     | uspeshno           |
| [kornevaya sessiya] Priyomka vosstanovleniya posle konfliktnogo merge-kommita                                                        | 16,741 s     | uspeshno           |
| [kornevaya sessiya] Priyomka publikacii zablokirovannogo result-ref pri TOCTOU-gonke                                                | 6,877 s      | uspeshno           |
| [kornevaya sessiya] Priyomka NUL-putej i granicyi git-common-dir                                                                     | 3,648 s      | uspeshno           |
| [kornevaya sessiya] Polnaya priyomka pula worktree-poduzlov posle ustraneniya gonok                                                   | 73,336 s     | uspeshno           |
| [root] Sintaksis Python posle zakryitiya ograzhdenij worktree-pula                                                                  | 0,148 s      | uspeshno           |
| [root] Celevoj suite lokaljnogo pula worktree-poduzlov posle audita                                                              | 83,145 s     | uspeshno           |
| [root] Celevoj suite pula posle trusted bootstrap i crash-recovery                                                               | 73,355 s     | uspeshno           |
| [root] Polnaya regressiya instrumenta FIFO i worktree-pula                                                                         | 330,639 s    | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Testyi predaktivacionnogo barjyera FIFO                                                     | 0,071 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Testyi predaktivacionnogo barjyera FIFO — povtor                                            | 9,665 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Diagnostika khyesha predaktivacionnoj privyazki                                               | 0,215 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Testyi predaktivacionnogo barjyera FIFO posle ispravleniya                                   | 17,188 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya regressiya ocheredi i worktree-pula                                                  | 386,001 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Peresborka planovogo reyestra zavershyonnogo FUM-STEP-0148                                   | 0,33 s       | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka svezhesti planovogo reyestra FUM-STEP-0148                                         | 0,346 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka strukturyi tekusjhej papki zaprosa                                                  | 13,168 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka vetochnogo selektora posle zaversheniya FUM-STEP-0148                               | 1,063 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka novyikh obyyavlenij koda na russkij yazyik                                            | 5,915 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sukhoj plan russkogo pereimenovaniya obyyavlenij koda                                        | 0,283 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis marshrutizatora i atomarnogo mosta worktree-poduzlov                             | 0,147 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] RED: pul worktree posle self-bootstrap i trusted-review izmenenij                         | 36,562 s     | neuspeshno         |
| [/root/barrier_diagnosis] Celevaya proverka pula worktree-poduzlov posle obnovleniya kontraktov sessii                             | 95,068 s     | neuspeshno         |
| [/root/barrier_diagnosis] Povtornaya celevaya proverka pula worktree-poduzlov posle dopolneniya fiksturyi                            | 103,212 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis protokola worktree-poduzlov posle marshrutizacii prodolzhenij                     | 0,072 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Priyomka pula worktree posle posledovateljnyikh prodolzhenij                                  | 106,603 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis protokola posledovateljnoj worktree-linii                                       | 0,071 s      | uspeshno           |
| [/root/barrier_diagnosis] Celevaya proverka posledovateljnoj peredachi worktree-linii                                              | 113,846 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis marshrutizatora i ocheredi worktree-poduzlov                                      | 0,135 s      | uspeshno           |
| [/root/barrier_diagnosis] Celevaya proverka read-only vosstanovleniya self-line-sessij                                             | 121,611 s    | neuspeshno         |
| [/root/barrier_diagnosis] Povtornaya celevaya proverka read-only vosstanovleniya self-line-sessij                                   | 124,732 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya regressiya ordinary FIFO i worktree-pula posle marshrutizacii i recovery             | 141,797 s    | prervano — SIGINT |
| [019ffa86-9a06-70d1-804e-cbc695651506] Fail-fast diagnostika polnoj regressii FIFO i worktree-pula                               | 125,13 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Diagnostika repozitornoj integracii FIFO posle pravki AGENTS                              | 0,162 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor repozitornoj integracii FIFO posle vosstanovleniya tochnyikh kontraktov                | 0,155 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya regressiya ordinary FIFO i worktree-pula posle ispravlenij                          | 407,611 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Peresborka planovogo reyestra posle zaversheniya FUM-STEP-0148                               | 0,245 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornaya peresborka planovogo reyestra FUM-STEP-0148                                      | 0,34 s       | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka ostatka russkikh obyyavlenij koda worktree-pula                                    | 5,898 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Inventarizaciya raskhozhdeniya ostatka obyyavlenij koda                                        | 5,143 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Semanticheskaya diagnostika raskhozhdeniya snimka obyyavlenij                                   | 5,261 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornaya semanticheskaya diagnostika snimka obyyavlenij                                     | 5,362 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sravneniye semanticheskogo ostatka obyyavlenij s HEAD                                        | 6,295 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka latinskikh obyyavlenij v novyikh fajlakh worktree-pula                                | 5,277 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornaya proverka latinskikh obyyavlenij novyikh fajlov pula                                 | 5,267 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis Python posle ograzhdeniya vosstanovleniya                                          | 0,164 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Pul worktree posle dolgovechnogo marshruta                                                  | 9,611 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Byistraya proverka vyideleniya slotov                                                         | 0,461 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornaya byistraya proverka vyideleniya slotov                                               | 5,415 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Vosstanovleniye samostoyateljnoj linii                                                      | 6,623 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] FIFO prodolzhenij worktree-linii                                                           | 5,132 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Avtomaticheskoye revjyu i integraciya posle doverennogo mosta                                 | 22,034 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Avtomaticheskoye razresheniye konflikta i povtornoye revjyu                                     | 17,65 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnyij nabor testov pula posle ustraneniya gonok                                           | 112,391 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis novyikh regressij marshruta i revjyu                                                | 0,152 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Unikaljnostj live host dlya self-sessij                                                    | 2,868 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Konkurentnyij vyibor odnoj iz dvukh worktree-linij                                           | 5,131 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Dolgovechnoye vosstanovleniye posle polnogo reuse slota                                      | 8,434 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Kompilyaciya Python-konturov pula worktree posle vosstanovleniya peredachi                    | 0,148 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Vosstanovleniye samostoyateljnoj linii posle peredachi i pereispoljzovaniya slota             | 9,14 s       | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Avtomaticheskoye chistoye revjyu i posledovateljnaya integraciya worktree-rezuljtatov            | 25,206 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya priyomka pula lokaljnyikh worktree-poduzlov                                           | 128,076 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sintaksis obsjhego runtime-marshruta zadach                                                   | 0,258 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Yedinyij runtime-marshrut mezhdu obyichnoj FIFO i worktree-pulom                                | 4,997 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor yedinogo runtime-marshruta obyichnoj FIFO i worktree-pula                              | 5,037 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Zelyonaya proverka yedinogo runtime-marshruta obyichnoj FIFO i worktree-pula                    | 7,9 s        | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Regressiya marshruta prodolzheniya worktree-linii                                             | 4,145 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Zapechatyivaniye opozdavshego revjyu posle integracii                                          | 24,466 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor zapechatyivaniya opozdavshego revjyu posle integracii                                   | 27,119 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka immutable marshrutov pool po exact assignment hash                                | 12,679 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Crash-recovery i povtornoye ispoljzovaniye posle zapechatannogo revjyu                        | 29,34 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya terminalizaciya opozdavshikh revjyu candidate i result                                 | 30,554 s     | uspeshno           |
| [/root/ordinary_route_hardening] RED: yedinyij runtime-marshrut ordinary FIFO                                                       | 6,952 s      | neuspeshno         |
| [/root/ordinary_route_hardening] Sintaksis ordinary runtime-marshruta                                                             | 0,154 s      | uspeshno           |
| [/root/ordinary_route_hardening] GREEN: yedinyij runtime-marshrut ordinary FIFO                                                     | 6,939 s      | uspeshno           |
| [/root/ordinary_route_hardening] GREEN: russkij kontrakt testov ordinary-marshruta                                                | 6,804 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Gonka ordinary FIFO i samostoyateljnogo worktree za odin task route                        | 1,109 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya priyomka worktree-pula s yedinyim task route i review sealed                          | 146,977 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya regressiya obyichnoj FIFO posle yedinogo marshruta zadachi                               | 260,679 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya regressiya FIFO, barjyera i worktree-pula                                            | 454,237 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka planovogo reyestra posle zaversheniya FUM-STEP-0148                                 | 0,333 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka snimka ostatka obyyavlenij koda                                                   | 5,664 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sukhoj plan rusifikacii novyikh obyyavlenij marshruta                                          | 0,093 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornaya priyomka worktree-pula posle rusifikacii obyyavlenij                              | 145,053 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] RED: perekhod na cepochku obyazan atomarno zakreplyatj yedinyij marshrut zadachi                  | 12,532 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN: perekhod na cepochku s yedinyim atomarnyim marshrutom zadachi                             | 13,683 s     | uspeshno           |
| [/root/pool_publication_hardening] RED: ograzhdeniye publikacii pula ot perenapravlenij URL i pobochnyikh refs                        | 61,961 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya ordinary FIFO-regressiya posle ograzhdeniya perekhoda na cepochku                       | 290,417 s    | neuspeshno         |
| [/root/pool_publication_hardening] RED: publikaciya pula bez URL rewrite, pushurl i pobochnyikh tegov                                | 65,614 s     | neuspeshno         |
| [/root/pool_publication_hardening] RED: vosstanovleniye trebuyet exact runtime-route i atomarnyij snimok dopuska                    | 5,823 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor tochnogo AGENTS-kontrakta perekhoda na cepochku                                       | 0,222 s      | uspeshno           |
| [/root/pool_publication_hardening] GREEN: vosstanovleniye exact runtime-route i atomarnogo snimka dopuska                         | 5,733 s      | neuspeshno         |
| [/root/pool_publication_hardening] GREEN: povtor vosstanovleniya exact route i branch HEAD                                        | 6,695 s      | uspeshno           |
| [/root/pool_publication_hardening] GREEN: publikaciya pula bez URL rewrite, pushurl i pobochnyikh tegov                              | 59,133 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN: publikaciya pula bez perenapravlenij URL i pobochnyikh refs                            | 63,899 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] RED: tochnyij povtor peredachi i rezuljtata proveryayet soobsjheniye kommita                      | 4,652 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN: tochnyij povtor peredachi i rezuljtata proveryayet soobsjheniye kommita                    | 6,31 s       | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya proverka pula worktree-poduzlov posle finaljnogo usileniya                          | 174,323 s    | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor tryokh regressij kvitancii integracii i vosstanovleniya linii                         | 61,698 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] RED atomarnogo snimka vosstanovleniya i perekhoda na cepochku                                | 4,799 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN atomarnogo snimka vosstanovleniya i perekhoda na cepochku                              | 4,237 s      | neuspeshno         |
| [/root/publication_transport_alias_fix] Krasnaya proverka literal-transporta publikacii bez remote-alias i TOCTOU-perenapravleniya | 40,693 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN ograzhdyonnogo snimka vosstanovleniya i perekhoda na cepochku                            | 4,703 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya proverka perekhoda na kartochku cepochki posle CAS-usileniya                           | 13,047 s     | uspeshno           |
| [/root/publication_transport_alias_fix] Zelyonaya proverka literal-transporta publikacii bez remote-alias i TOCTOU-perenapravleniya | 50,339 s     | neuspeshno         |
| [/root/publication_transport_alias_fix] Povtor literal-transporta rezuljtata bez remote-alias i TOCTOU-perenapravleniya           | 14,749 s     | uspeshno           |
| [/root/publication_transport_alias_fix] Regressiya publikacii rezuljtata cherez izolirovannyij literal-transport                    | 63,537 s     | uspeshno           |
| [/root/publication_transport_alias_fix] Itogovaya proverka literal-transporta rezuljtata i integracii                             | 52,228 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Polnaya proverka pula worktree-poduzlov posle vsekh usilenij                                | 231,045 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Itogovyij polnyij discovery instrumenta ocheredi i worktree-poduzlov                         | 584,667 s    | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka tochnogo snimka latinskikh obyyavlenij posle finaljnogo koda                        | 5,907 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Obnovleniye podtverzhdyonnogo snimka ostatka obyyavlenij bez novyikh latinskikh imyon             | 4,905 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornaya proverka obnovlyonnogo snimka ostatka obyyavlenij                                 | 4,817 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Peresborka reyestra planirovaniya posle zaversheniya FUM-STEP-0148                            | 0,349 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka peresobrannogo reyestra planirovaniya                                              | 0,333 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Obnovleniye svezhesti Markdown posle dokumentaljnogo prototipa worktree                     | 0,71 s       | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Peresborka teplovoj kartyi grafa Obsidian posle recency                                    | 0,381 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sinkhronizaciya recency posle predprosmotra otchyota                                          | 0,682 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Sinkhronizaciya grafa posle finaljnogo recency                                              | 0,387 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka aktualjnosti Markdown recency                                                    | 0,604 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka aktualjnosti teplovoj kartyi Obsidian                                             | 0,371 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Predfinaljnaya proverka probelov diff                                                      | 0,06 s       | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Predfinaljnyij polnyij smoke-check dokumentaljnogo worktree-pula                            | 45,5 s       | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtornyij predfinaljnyij polnyij smoke-check dokumentaljnogo worktree-pula                  | 38,452 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] RED: kanonicheskij identifikator collaboration-subagenta v otchyotakh proverok                | 2,093 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN: kanonicheskij identifikator collaboration-subagenta v otchyotakh proverok              | 1,952 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN: povtor kanonicheskogo identifikatora collaboration-subagenta                        | 1,948 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] GREEN: itogovyiye testyi kanonicheskogo collaboration-ispolnitelya                             | 1,982 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka tekusjhego repozitoriya posle klassifikacii collaboration-ispolnitelej              | 14,075 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Itogovyij predfinaljnyij polnyij smoke-check dokumentaljnogo worktree-pula                   | 44,663 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor profiljnyikh testov skanera posle rusifikacii novyikh obyyavlenij                       | 1,942 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Obnovleniye snimka obyyavlenij bez novogo latinskogo ostatka                                | 4,876 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor itogovogo polnogo smoke-check posle obnovleniya snimka obyyavlenij                   | 81,101 s     | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Proverka svyaznosti posle sinkhronizacii polnogo inventarya fajlov                           | 29,659 s     | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Finaljnyij polnyij smoke-check dokumentaljnogo worktree-pula                                | 236,752 s    | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Regressiya chisla kandidatov master posle zaversheniya FUM-STEP-0148                          | 2,241 s      | neuspeshno         |
| [019ffa86-9a06-70d1-804e-cbc695651506] Povtor regressii sleduyusjhego ready-kandidata master                                        | 2,326 s      | uspeshno           |
| [019ffa86-9a06-70d1-804e-cbc695651506] Finaljnyij polnyij smoke-check posle sinkhronizacii selektora master                         | 2963,215 s   | uspeshno           |

Obsjheye vremya pryamyikh zapuskov proverok: 9981,79 s.

<!-- FUM-CHECK-RUNS:END -->

## Realizovannyij runtime-kontrakt

- `пул-worktree-подузлов.py` khranit zakryitoye sostoyaniye v Git-obyyektakh i sluzhebnyikh refs. Marshrutizator khyeshiruyet exact OID planovyikh istochnikov, target, pool i FIFO; pishusjheye resheniye prinimayetsya toljko dlya neizmenivshegosya snimka i odnoj tranzakciyej sozdayot obsjhij ordinary/chain/pool runtime-route po `task_id`. Podgotovka, dopusk i zavershyonnyij replay `перейти-на-цепочку` ograzhdenyi exact source HEAD OID, route, transition FIFO i symbolic `HEAD`.
- `параллельная_линия` lenivo materializuyet libo pereispoljzuyet odin `Подузлы/слот-NNNN` s novyim polnyim ref. `последовательное_продолжение` sozdayot intent i vozrastayusjhij FIFO-bilet prezhnej linii; read-only ne sozdayot pisateljskogo sostoyaniya.
- Vse soderzhateljnyiye komandyi trebuyut exact slot `repo-root`, `worktree_id`, ref, head i `admitted`. Kod protokola posle naznacheniya zagruzhayetsya iz zakreplyonnogo trusted `protocol_oid`, a ne iz neproverennogo result/candidate `HEAD`.
- `передать-линию` atomarno sozdayot promezhutochnyij commit, dvigayet toljko ref self-line, peredayot FIFO pervomu biletu i sokhranyayet handoff receipt s khyeshem soobsjheniya. Poluchatelj vidit `reload_required`, podtverzhdayet vershinu i prodolzhayet s novyim pokoleniyem v tom zhe worktree. Terminaljnyij rezuljtat sokhranyayet vesj linejnyij diapazon i tot zhe exact message-hash replay-barjyer.
- Recenzent rabotayet s zamorozhennoj exact-vershinoj i sokhranyayet khyesh otchyota, proverki i verdikt. Toljko prinyatyiye result receipts vkhodyat v integraciyu; konflikt ostayotsya agentu-integratoru, a itog vsegda poluchayet novoye nezavisimoye revjyu. Yesli integraciya operedila recenzenta, `review_sealed` sokhranyayet exact integration hash, perezhivayet detach/CAS-sboj i polnyij reuse slota, no ne schitayetsya revjyu.
- Prinyatiye integracionnogo kandidata svyazyivayet `master`, ordinary queue-ref, zaraneye sozdannoye prodolzheniye, obe kvitancii i pool-ref odnoj zakryito proverennoj `update-ref`-tranzakciyej. Poetomu sliyaniya v `master` posledovateljnyi i prokhodyat cherez obyichnuyu FIFO.
- Proverka publikacionnoj chistotyi sozdayot durable intent dazhe dlya otricateljnogo merge-verdikta. Publikaciya ispoljzuyet zakreplyonnyij OID i bukvaljnyij khyeshirovannyij adres transporta, zapresjhayet force, remote-psevdonimyi i primenimyiye URL-perenapravleniya, podavlyayet dobavochnyiye refs/transportnyiye opcii i trebuyet exact `ls-remote` readback; pending backlog perezhivayet perezapusk.

## Proverki

- Adresnaya priyomka worktree-pula pokryivayet self-route/reserve/admit, dve paralleljnyiye linii, slot reuse, poljzovateljskoye prodolzheniye odnoj linii, FIFO handoff/reload/ack, verify-only recovery exact route/ref/FIFO-snimka, exact message-hash replay, adversarial Git-puti, trusted protocol, yedinyij ordinary/chain/pool/delegated runtime-route, nezavisimyiye revjyu, `review_sealed`, chistuyu i konfliktnuyu crash-recovery-integraciyu, ordinary-FIFO-most i izolirovannyij publikacionnyij transport.
- Adresnyij suite worktree-pula proshyol 38 scenariyev za 225,701 s; polnyij discovery ordinary FIFO, perekhodov i worktree-pula proshyol 228 testov za 579,110 s; zaklyuchiteljnyij run #160 kompleksnogo smoke-check proshyol 38 iz 38 etapov za 2963,215 s. Vse RED-zapuski i ispravlyayusjhiye GREEN-zapuski ostayutsya v mashinnom zhurnale.
- Vse udalyonnyiye Git-proverki vyipolnenyi na vremennyikh lokaljnyikh bare-repozitoriyakh. Setevyiye GitHub API, fork, pull request, sekretyi i platnyiye servisyi ne ispoljzovalisj.
- Nezavisimyiye read-only revjyu obnaruzhili obkhod ordinary FIFO, neograzhdyonnyiye Git-puti, gonki aktivacii i detach, nedolgovechnyij pending intent, rassinkhronizaciyu checkout, nedoverennyij bootstrap, publikacionnyij TOCTOU, neodnoznachnuyu runtime-marshrutizaciyu, neograzhdyonnoye recovery i nepolnuyu identichnostj replay. Eti nakhodki zakryityi shared immutable route, verify-only snimkami, izolirovannyim transportom i message-hash-kvitanciyami i podtverzhdenyi zaklyuchiteljnyim polnyim smoke-check.

## Resheniya i ogranicheniya

- Odin fizicheskij slot zakreplyon za self-line do yeyo terminaljnogo rezuljtata, no odnovremenno imeyet toljko odnogo aktivnogo vladeljca. Posledovateljnyiye sessii ispoljzuyut tot zhe ref, FIFO i worktree; posle terminal receipt chistyij slot mozhet poluchitj novuyu liniyu i novyij ref.
- Worktree razdelyayut rabochiye fajlyi i indeksyi, no ne object database, Git common-dir i prostranstvo refs. Eto doverennaya kooperativnaya granica: exact imena, CAS i recovery-snimki ograzhdenyi, odnako pryamoj nedoverennyij pisatelj obsjhego common-dir ne izolirovan, a worktree ne raven otdeljnomu repozitoriyu.
- Avtomaticheskoye razresheniye konflikta mozhet zavershitjsya otricateljnyim revjyu. Togda `master` ne dvigayetsya, no result-ref sokhranyayetsya lokaljno i posle proverki publikacionnoj chistotyi mozhet byitj otpravlen otdeljnyim udalyonnyim ref.
- Codex Desktop ne predostavlyayet etomu prototipu mashinnyij perenos workspace v proizvoljnyij poljzovateljskij worktree i avtoritetnyij ACK takogo perenosa. CLI dokazyivayet exact `repo-root` sobstvennyikh soderzhateljnyikh komand, no ne nativnuyu host-izolyaciyu i ne otsutstviye chtenij pervichnogo checkout; `host_workspace_acknowledged` ostayotsya lozhnyim.
- FUM-STEP-0148 ne zavershayet FUM-REQ-0036: dolgovechnyiye fork/submodule-repozitorii ostayutsya otdeljnoj budusjhej arkhitekturoj. V ramkakh tekusjhego shaga ne sozdayutsya GitHub forks i pull requests.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [FUM-STEP-0148](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0148-organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-worktree-poduzlakh.md)
- [kontrakt ocheredi i pula](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 15:23:37 MSK -->
<!-- content-sha256: sha256:5dd2d3413a21d14a90e96e5906dbec5aca1015496e11d3188ced1569521ab31b -->
<!-- FUM-MD-RECENCY:END -->
