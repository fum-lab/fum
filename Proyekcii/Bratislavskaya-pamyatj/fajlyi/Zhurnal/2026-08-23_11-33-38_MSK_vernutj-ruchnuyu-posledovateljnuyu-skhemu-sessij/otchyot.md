# Otchyot 2026-08-23 11:33:38 MSK - Vernutj ruchnuyu posledovateljnuyu skhemu sessij

Repozitorij perevedyon na ruchnuyu posledovateljnuyu skhemu: odnu pishusjhuyu sessiyu poljzovatelj zapuskayet v pervichnom checkout `refs/heads/master`, ona vyipolnyayet odin soderzhateljnyij zapros, sozdayot ne boleye odnogo lokaljnogo kommita i zavershayetsya bez avtomaticheskogo prodolzheniya. FIFO/pool/worktree/review/integration/candidate/branch-next-step kontur otdelyon kak istoricheskaya i otlozhennaya narabotka. `.obsidian/graph.json` sokhranyon na diske, snyat s Git-uchyota i zakryit tochnyim pravilom `.gitignore`; yego tekusjhiye poljzovateljskiye bajtyi ne perepisyivalisj.

## Profilj vremeni vyipolneniya

| Stadiya                              | Dliteljnostj            | Granicyi i sposob izmereniya                                                                                 |
| ----------------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------- |
| Podtverzhdeniye existing owner        | otdeljno ne izmereno    | Read-only `status` podtverdil task, generation, `HEAD`, FIFO OID i otsutstviye waiting-biletov.            |
| Soderzhateljnaya rabota               | do finaljnogo zamyikaniya | Interval ot kanonicheskogo vremeni `2026-08-23 11:33:38 MSK`; analiz, pravki i proverki chastichno perekryityi. |
| Pryamyiye celevyiye proverki             | sm. tochnuyu summu nizhe   | Monotonnyiye dliteljnosti kazhdogo vyizova sokhranyayet mashinnaya otchyotnaya obyortka.                               |
| Zaklyuchiteljnyij polnyij smoke-check   | 3019,918 s              | Yedinyij progon `76/76` na itogovom diff; vneshnyaya obyortka zafiksirovala `3020,039 с`.                        |
| Perekhodnyij atomarnyij commit+handoff | vne zakryivayemogo snimka | Yedinstvennyij bridge sozdayotsya posle staging; dokazateljstvom sluzhit exact FIFO-kvitanciya.                 |

Granica profilya: soderzhateljnaya rabota nachinayetsya kanonicheskim vremenem zaprosa; pryamyiye proverki izmeryayutsya avtomaticheski. Finaljnyij bridge-handoff vyipolnyayetsya posle zakryitiya mashinnogo snimka i ne porozhdayet sleduyusjhuyu rabotu.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:652759c2f0ab970cfcb22f66f623eb29a9459ad70e02bdc79113702938c52cde -->

| Vyizov                                                                                             | Dliteljnostj | Rezuljtat                                 |
| ------------------------------------------------------------------------------------------------- | ------------ | ----------------------------------------- |
| [kornevaya sessiya] Regressiya polnogo smoke-check posle otklyucheniya graph.json                       | 30,776 s     | uspeshno                                   |
| [kornevaya sessiya] Proverka kornevoj instrukcii i indeksa README                                   | 0,267 s      | uspeshno                                   |
| [kornevaya sessiya] Proverka svyaznosti perekhodnoj rabochej sessii                                    | 30,423 s     | uspeshno                                   |
| [kornevaya sessiya] Zaklyuchiteljnyij polnyij smoke-check ruchnoj posledovateljnoj skhemyi                 | 128,258 s    | neuspeshno                                 |
| [kornevaya sessiya] Proverka snimka obyyavlenij posle sokhraneniya istoricheskoj utilityi graph          | 74,66 s      | neuspeshno                                 |
| [kornevaya sessiya] Regressiya inventarya obyyavlenij bez istoricheskikh Poduzlov                        | 1,312 s      | uspeshno                                   |
| [kornevaya sessiya] Proverka kanonicheskogo snimka obyyavlenij bez istoricheskikh Poduzlov              | 23,14 s      | uspeshno                                   |
| [kornevaya sessiya] Zaklyuchiteljnyij polnyij smoke-check ruchnoj posledovateljnoj skhemyi                 | 100,72 s     | neuspeshno                                 |
| [kornevaya sessiya] Povtornaya proverka svyaznosti rasshirennogo perekhodnogo inventory                 | 29,709 s     | uspeshno                                   |
| [kornevaya sessiya] Finaljnyij polnyij smoke-check zamknutogo perekhodnogo inventory                   | 824,436 s    | neuspeshno                                 |
| [kornevaya sessiya] Regressiya ruchnogo zaversheniya smoke-sessii v FIFO-nabore                         | 0,15 s       | uspeshno                                   |
| [kornevaya sessiya] Povtornaya proverka snimka obyyavlenij posle FIFO-regressii                       | 22,794 s     | uspeshno                                   |
| [kornevaya sessiya] Regressiya kirillicheskogo ruchnogo zaversheniya smoke-sessii                        | 0,185 s      | uspeshno                                   |
| [kornevaya sessiya] Finaljnaya proverka snimka obyyavlenij bez rosta ostatka                          | 22,588 s     | uspeshno                                   |
| [kornevaya sessiya] Priyomochnyij polnyij smoke-check ruchnoj posledovateljnoj skhemyi                     | 1800,024 s   | ne zaversheno — tajm-aut                   |
| [kornevaya sessiya] Finaljnyij polnyij smoke-check bez sokrasjhyonnogo limita                            | 1892,319 s   | neuspeshno                                 |
| [kornevoj agent] Povtor tochnogo testa tajm-auta symbolic-ref                                      | 5,265 s      | uspeshno                                   |
| [kornevaya sessiya] Povtornyij finaljnyij polnyij smoke-check posle yedinichnogo tajm-auta               | 673,425 s    | prervano — SIGINT                         |
| [kornevoj agent] Regressiya ograzhdeniya ruchnoj skhemyi ot istoricheskogo konvejyera                     | 0,184 s      | uspeshno                                   |
| [kornevoj agent] RED-proverka snimka obyyavlenij posle novogo regressionnogo ograzhdeniya            | 22,713 s     | neuspeshno                                 |
| [kornevoj agent] GREEN-proverka snimka obyyavlenij posle novogo regressionnogo ograzhdeniya          | 22,463 s     | uspeshno                                   |
| [kornevaya sessiya] Finaljnaya regressiya ograzhdeniya ruchnogo marshruta                                 | 0,189 s      | uspeshno                                   |
| [kornevaya sessiya] Finaljnaya regressiya kornevogo isklyucheniya Poduzlov                               | 1,223 s      | uspeshno                                   |
| [kornevaya sessiya] Finaljnaya proverka tochnogo snimka obyyavlenij                                    | 22,827 s     | uspeshno                                   |
| [kornevaya sessiya] Povtornaya regressiya polnogo ograzhdeniya ruchnogo marshruta                         | 0,188 s      | uspeshno                                   |
| [kornevaya sessiya] Povtornaya regressiya zamknutogo inventarya obyyavlenij                             | 1,289 s      | uspeshno                                   |
| [kornevaya sessiya] Povtornaya proverka tochnogo snimka obyyavlenij                                    | 22,9 s       | uspeshno                                   |
| [kornevaya sessiya] Predfinaljnaya proverka svyaznosti polnogo perekhodnogo inventory                  | 30,232 s     | neuspeshno                                 |
| [kornevaya sessiya] Predfinaljnaya proverka kornevoj instrukcii README                               | 0,313 s      | uspeshno                                   |
| [kornevaya sessiya] Predfinaljnaya proverka svezhesti Markdown                                        | 0,651 s      | uspeshno                                   |
| [kornevaya sessiya] Diagnosticheskij povtor svyaznosti polnogo perekhodnogo inventory                  | 29,848 s     | neuspeshno                                 |
| [kornevaya sessiya] RED-proverka lokaljno sokhranyonnogo fajla vne Git-uchyota                          | 0,188 s      | neuspeshno                                 |
| [kornevaya sessiya] GREEN-proverka lokaljno sokhranyonnogo fajla vne Git-uchyota                        | 0,242 s      | uspeshno                                   |
| [kornevaya sessiya] GREEN-proverka svyaznosti s lokaljno sokhranyonnyim graph                           | 31,538 s     | uspeshno                                   |
| [kornevaya sessiya] Proverka snimka obyyavlenij posle rasshireniya svyaznosti                           | 22,639 s     | uspeshno                                   |
| [kornevaya sessiya] Povtornaya GREEN-regressiya lokaljnogo graph vne Git-uchyota                        | 0,397 s      | uspeshno                                   |
| [kornevaya sessiya] Regressiya ekspluatacionnyikh ograd ruchnogo marshruta                               | 0,185 s      | uspeshno                                   |
| [kornevaya sessiya] Proverka nulevogo rosta snimka obyyavlenij                                       | 32,857 s     | uspeshno                                   |
| [kornevaya sessiya] Predfinaljnaya GREEN-proverka polnoj svyaznosti                                   | 33,298 s     | uspeshno                                   |
| [kornevaya sessiya] RED-proverka otklyucheniya vetochnogo selektora v ruchnom rezhime                     | 1,018 s      | neuspeshno                                 |
| [kornevaya sessiya] GREEN-proverka otklyucheniya vetochnogo selektora v ruchnom rezhime                   | 0,628 s      | uspeshno                                   |
| [kornevaya sessiya] Itogovaya regressiya otklyuchyonnogo selector                                        | 0,676 s      | uspeshno                                   |
| [kornevaya sessiya] Itogovaya regressiya ograd Trebovanij i Planirovaniya                              | 0,188 s      | uspeshno                                   |
| [kornevaya sessiya] Itogovaya proverka otsutstviya rosta ostatka obyyavlenij                           | 23,687 s     | uspeshno                                   |
| [kornevaya sessiya] Itogovaya svyaznostj rasshirennogo perekhodnogo inventory                           | 31,483 s     | uspeshno                                   |
| [kornevaya sessiya] Proverka tochnogo snimka obyyavlenij posle ograzhdeniya selector                    | 0,004 s      | ne zaversheno — ispolnyayemyij fajl ne najden |
| [kornevaya sessiya] Povtornaya proverka tochnogo snimka obyyavlenij posle ograzhdeniya selector          | 22,352 s     | uspeshno                                   |
| [kornevaya sessiya] Regressiya fail-closed selector ruchnoj posledovateljnoj skhemyi                    | 0,658 s      | uspeshno                                   |
| [kornevaya sessiya] Regressiya zamknutyikh ograd ruchnoj posledovateljnoj skhemyi                         | 0,13 s       | uspeshno                                   |
| [kornevaya sessiya] Proverka svyaznosti posle lokaljnyikh ograd istoricheskogo konvejyera                | 29,884 s     | uspeshno                                   |
| [kornevaya sessiya] Proverka svezhesti Markdown posle lokaljnyikh ograd                                | 0,613 s      | uspeshno                                   |
| [kornevaya sessiya] Povtornaya proverka kornevoj instrukcii i indeksa README                         | 0,294 s      | uspeshno                                   |
| [kornevaya sessiya] Okonchateljnyij polnyij smoke-check ruchnoj posledovateljnoj skhemyi                  | 85,765 s     | prervano — SIGINT                         |
| [kornevaya sessiya] Finaljnaya regressiya ograd sboyev istoricheskoj FIFO                               | 0,188 s      | uspeshno                                   |
| [kornevaya sessiya] Finaljnaya svyaznostj posle snyatiya sboyev FIFO                                     | 30,123 s     | neuspeshno                                 |
| [kornevaya sessiya] Povtornaya svyaznostj s sinkhronizirovannyim planovyim reyestrom                      | 29,925 s     | uspeshno                                   |
| [kornevaya sessiya] Okonchateljnyij polnyij smoke-check posle globaljnogo audita                       | 64,08 s      | neuspeshno                                 |
| [kornevaya sessiya] GREEN-proverka snimka posle ograd sboyev FIFO                                    | 23,447 s     | uspeshno                                   |
| [kornevaya sessiya] Finaljnyij polnyij smoke-check sinkhronizirovannogo snimka                         | 256,523 s    | neuspeshno                                 |
| [kornevaya sessiya] Polnaya regressiya selector posle obnovleniya acceptance                           | 179,723 s    | uspeshno                                   |
| [kornevaya sessiya] Itogovyij polnyij smoke-check posle GREEN selector                                | 937,912 s    | neuspeshno                                 |
| [kornevaya sessiya] GREEN-proverka istoricheskoj heartbeat-spravki                                   | 0,141 s      | uspeshno                                   |
| [kornevaya sessiya] Polnaya regressiya FIFO posle istoricheskogo acceptance                            | 541,82 s     | uspeshno                                   |
| [kornevaya sessiya] Polnyij smoke-check posle GREEN selector i FIFO                                  | 2749,014 s   | neuspeshno                                 |
| [kornevaya sessiya] Swift: istoricheskaya fikstura konechnoj cepochki posle izolyacii AGENTS             | 206,4 s      | uspeshno                                   |
| [kornevaya sessiya] Swift: pryamoj selektor universaljnoj fiksturyi posle polnoj izolyacii AGENTS      | 5,355 s      | uspeshno                                   |
| [kornevaya sessiya] Swift: konechnaya cepochka posle polnoj izolyacii AGENTS                            | 192,548 s    | uspeshno                                   |
| [kornevaya sessiya] SwiftPM proveryayemogo mnogoagentnogo kontura posle izolyacii istoricheskikh fikstur | 1109,475 s   | uspeshno                                   |
| [kornevaya sessiya] Itogovyij polnyij smoke-check posle izolyacii istoricheskikh Swift-fikstur           | 3020,039 s   | uspeshno                                   |

Obsjheye vremya pryamyikh zapuskov proverok: 15480,908 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Adresnyij nabor `fum-kompleksnaya-proverka-repozitoriya` proshyol posle isklyucheniya obyazateljnoj heatmap-proverki lokaljnogo `graph.json`.
- Inventarj obyyavlenij isklyuchayet toljko kornevoye proizvodnoye prostranstvo `Подузлы/`: adresnaya regressiya proshla 10/10, a kanonicheskij snimok sovpal dlya 43 213 obyyavlenij. Pervyij povtor polnogo smoke-check korrektno ostanovilsya, poka chetyire obnaruzhennyikh fajla ne byili dobavlenyi v zamknutyij zhurnaljnyij inventory.
- Istoricheskij FIFO-nabor sokhranil proverki starogo runtime, a odna ustarevshaya acceptance-proverka zaversheniya smoke-sessii perevedena s obyazateljnogo `committed`/`commit+handoff` na dejstvuyusjhij ruchnoj commit `master` bez sleduyusjhej zadachi. Promezhutochnyij latinskij suffiks imeni testa ne prinyat v snapshot i zamenyon kirillicheskim `мастер`, chtobyi itogovyij ostatok sokhranilsya ravnyim 43 213.
- Istoricheskiye Swift-fiksturyi universaljnogo kontura boljshe ne kopiruyut dejstvuyusjhij kornevoj `AGENTS.md`: oni poluchayut sobstvennyiye izolirovannyiye arkhivnyiye pravila bez markera `manual-sequential-v1`. Adresno proshli odin test pryamogo selektora i tri testa vozobnovlyayemoj cepochki; zatem vesj paket proshyol 45 XCTest, 82 XCTest i 169 Swift Testing testov bez oshibok.
- Itogovyij polnyij smoke-check proshyol vse 76 shagov. Vnutri nego selector zavershil 188 testov s 34 arkhivnyimi propuskami, FIFO — 228/228, dispatcher — 140/140, a povtor polnogo mnogoagentnogo Swift-paketa snova proshyol bez oshibok.
- Kontrakt kornevoj instrukcii i tematicheskogo indeksa proshyol: `required=52`, `indexed=52`.
- Tekusjhij blob lokaljnogo `.obsidian/graph.json` do i posle snyatiya s uchyota sovpal: `7096cf7316bde8c43634a3f441d9d1868f957da5`.
- Neuspeshnyiye promezhutochnyiye zapisi ne ispoljzovanyi kak svideteljstvo gotovnosti. Oni fiksiruyut ozhidayemyiye RED-fazyi, nezamknutyiye na tot moment inventory/recency/planovyij reyestr, rassinkhronizirovannyij snimok obyyavlenij, prezhniye acceptance-ozhidaniya continuation/FIFO i obnaruzhennuyu utechku kornevogo ruchnogo markera v istoricheskuyu Swift-fiksturu; posle kazhdogo finding vyipolnen otdeljnyij GREEN-povtor.
- Zapusk poryadka 15 ostanovila slishkom korotkaya vneshnyaya granica 1800 sekund; posleduyusjhij polnyij progon poluchil limit 7200 sekund. Zapuski poryadka 18 i 53 byili prervanyi `SIGINT` i ne pereispoljzovanyi. Zapusk poryadka 46 oshibochno peredal `PYTHONDONTWRITEBYTECODE=1` kak imya ispolnyayemogo fajla, poluchil kod 127 i byil nemedlenno povtoryon korrektnoj komandoj. Eti tri klassa interfejsnyikh/operatorskikh iskhodov ne maskiruyutsya kak proverki koda.
- Posle zakryitiya mashinnogo snimka vyipolnyayutsya toljko finaljnyiye recency/coherence/diff/readback, staging i obyazateljnyij staroprotokoljnyij FIFO bridge; oni ne menyayut soderzhateljnoye resheniye.

## Resheniya i ogranicheniya

- `AGENTS.md` ostayotsya glavnyim istochnikom dejstvuyusjhikh pravil i soderzhit mashinno vidimyij marker `manual-sequential-v1`.
- Staryiye imperative-razdelyi FIFO/pool sokhranenyi vnutri yavno istoricheskoj granicyi; scripts, tests, refs i receipts ne udalyalisj i ne vyidayutsya za aktivnyij marshrut.
- Sokhranyonnyiye istoricheskiye worktree v kornevom `Подузлы/` ne vkhodyat v kanonicheskij inventarj iskhodnikov, inache pervichnyij checkout mnogokratno uchityival byi odni i te zhe obyyavleniya; odnoimyonnyij komponent nizhe drugogo kanonicheskogo kornya ne isklyuchayetsya.
- Yedinstvennaya bridge-zadacha nuzhna toljko potomu, chto zakommichennyij do perekhoda runtime trebuyet continuation dlya samogo perekhodnogo kommita. Posle novogo `HEAD` ona vyipolnyayet `ack-head` i `finish-clean`, ne zapuskayet selector i ne sozdayot rebyonka.
- Chernovoj v4 ne integriruyetsya i dolzhen ostatjsya dostizhimyim po `refs/heads/codex/подузлы/ремонт-сохранения-graph-при-CAS-цели-в4` na `335980d70204d65b42de4bee775fa4b20005ae93`.
- Push, remote publication i vneshniye effektyi ne vyipolnyayutsya.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 12:48:25 MSK -->
<!-- content-sha256: sha256:a7b2b2bd96c7aef2d31aa149d1bbb18fc1c0248d4aaffc83381102296dcc6db2 -->
<!-- FUM-MD-RECENCY:END -->
