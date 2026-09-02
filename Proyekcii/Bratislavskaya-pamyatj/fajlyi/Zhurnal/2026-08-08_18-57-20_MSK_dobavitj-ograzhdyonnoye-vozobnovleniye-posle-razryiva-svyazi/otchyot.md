# Otchyot 2026-08-08 18:57:20 MSK - Dobavitj ograzhdyonnoye vozobnovleniye posle razryiva svyazi

V FUM realizovano ograzhdyonnoye vozobnovleniye toj zhe dispetcherskoj zadachi posle nablyudayemogo razryiva potoka otveta. Heartbeat teperj proveryayet nezavershyonnuyu svyazannuyu rezervaciyu do obyichnogo vyikhoda po zanyatoj FIFO, prinimayet toljko tochnyij terminaljnyij host-profilj razryiva i posle yedinstvennogo Git-CAS obrasjhayetsya k prezhnej zadache rovno odin raz. Zhivaya heartbeat-avtomatizaciya obnovlena na meste tem zhe kanonicheskim prompt bez izmeneniya yeyo raspisaniya, statusa ili identichnosti i bez sozdaniya dublikata.

Nablyudeniye dokazyivayet toljko terminaljnyij oshibochnyij host-khod s tochnoj oshibkoj razryiva potoka i posleduyusjheye uspeshnoye chteniye toj zhe host-zadachi v sostoyanii `idle` libo `notLoaded`. Ono ne dokazyivayet fizicheskuyu gibernaciyu, probuzhdeniye kompjyutera, poteryu ili polnoye vosstanovleniye seti libo perezapusk processa. Eti prichinyi ostayutsya neizvestnyimi do poyavleniya samostoyateljnogo avtoritetnogo adaptera.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj       | Granicyi i sposob izmereniya                                                                                    |
| ------------------------ | ------------------ | ------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmeryalosj      | Dopusk poluchen do mutacij i zapuska subagentov; otdeljnyij wall-clock-interval ne sokhranilsya                   |
| Soderzhateljnaya rabota    | ne izmeryalasj      | Analiz, TDD, realizaciya i tri ogranichennyikh audita perekryivalisj; ikh dliteljnosti neljzya korrektno summirovatj |
| Celevyiye proverki         | 890,618 s          | Summa zapisej vne chetyiryokh smoke-popyitok; vklyuchayet TDD-red, audityi, adresnyiye naboryi i svyaznostj                |
| Polnyij smoke-check       | 2247,612 s         | Tri ranniye popyitki ostanovilisj na shagakh 6/76, 13/76 i 14/76; finaljnaya proshla vse 76/76 shagov                |
| Atomarnyij commit+handoff | yesjhyo ne vyipolnen    | Vyipolnyayetsya posle zakryitiya mashinnogo snimka proverok i predkommitnyikh read-only-validatorov                    |

Granica profilya: interval nachinayetsya s uzhe poluchennogo FIFO-dopuska etoj rabochej sessii i zavershayetsya atomarnyim `commit+handoff`; tochnoye vremya pryamyikh proverok khranitsya nizhe nezavisimo ot perekryivayusjhejsya soderzhateljnoj rabotyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:6a8d813a8cfaa4e0c4809d3de76c9c85a275007c96c93fa884c8e20794ef380f -->

| Vyizov                                                                               | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Padayusjhiye testyi ograzhdyonnogo vozobnovleniya                          | 56,984 s     | neuspeshno |
| [kornevoj agent] Realizaciya ograzhdyonnogo vozobnovleniya                              | 64,464 s     | uspeshno   |
| [kornevoj agent] Ograzhdeniye vozobnovleniya ot shtatnogo sbrosa                        | 1,974 s      | uspeshno   |
| [kornevoj agent] Padayusjhiye kontraktyi heartbeat-vozobnovleniya                         | 0,09 s       | neuspeshno |
| [kornevoj agent] Kontraktyi heartbeat-vozobnovleniya posle shablona                    | 0,117 s      | neuspeshno |
| [kornevoj agent] Zelyonyiye kontraktyi heartbeat-vozobnovleniya                          | 0,087 s      | neuspeshno |
| [kornevoj agent] Kontraktyi yedinstvennogo heartbeat-soobsjheniya                        | 0,069 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor testov heartbeat-shablona                              | 0,529 s      | neuspeshno |
| [root] Polnyij nabor kontraktov heartbeat posle vozobnovleniya                        | 0,523 s      | uspeshno   |
| [root] Polnyij nabor adaptera dispetchera posle vozobnovleniya                         | 68,518 s     | uspeshno   |
| [root] Polnyij nabor FIFO posle ograzhdeniya vozobnovleniya                             | 141,227 s    | uspeshno   |
| [root] Kontrakt otsutstviya inyikh aktivnyikh zadach pri vozobnovlenii                    | 0,563 s      | uspeshno   |
| [root] Padayusjhij kontrakt celostnosti vlozhennogo recovery pri sbrose                 | 0,427 s      | neuspeshno |
| [root] Padayusjhij kontrakt celostnosti vlozhennogo recovery posle ispravleniya fiksturyi | 0,897 s      | neuspeshno |
| [root] Strogaya celostnostj recovery-sostoyaniya pri sbrose                            | 3,286 s      | uspeshno   |
| [root] Padayusjhiye kontraktyi process-id, dlinnogo readback i JSON-tipov                | 13,006 s     | neuspeshno |
| [root] Kontraktyi process-id, dlinnogo readback i JSON-tipov                         | 16,326 s     | uspeshno   |
| [root] Padayusjhij kontrakt JSON-tipov recovery pri sbrose                             | 0,876 s      | neuspeshno |
| [root] Strogiye chislovyiye tipyi vnutrennej skhemyi recovery                              | 3,856 s      | uspeshno   |
| [root] Strogiye chislovyiye tipyi recovery pri sbrose                                    | 0,877 s      | uspeshno   |
| [root] Zhivoj exact-diff heartbeat posle obnovleniya prompt                           | 0,069 s      | uspeshno   |
| [root] Itogovyij polnyij nabor FIFO recovery                                          | 150,833 s    | uspeshno   |
| [root] Itogovyij polnyij nabor adaptera recovery                                      | 85,793 s     | uspeshno   |
| [root] Itogovyij polnyij nabor heartbeat recovery                                     | 0,522 s      | uspeshno   |
| [root] Validaciya planovogo reyestra posle kartochki recovery                          | 0,346 s      | uspeshno   |
| [root] Predvariteljnaya proverka probeljnoj celostnosti diff                         | 0,085 s      | uspeshno   |
| [root] Predfinaljnaya kompleksnaya proverka repozitoriya                               | 40,512 s     | neuspeshno |
| [root] Sukhoj plan perevoda novogo latinskogo obyyavleniya recovery                    | 0,138 s      | uspeshno   |
| [root] Tochnyij snimok ostatka obyyavlenij posle perevoda recovery                     | 4,532 s      | uspeshno   |
| [root] Polnyij nabor adaptera posle perevoda obyyavleniya recovery                     | 82,951 s     | uspeshno   |
| [root] Itogovaya kompleksnaya proverka repozitoriya                                    | 71,687 s     | neuspeshno |
| [root] Adresnaya svyaznostj sessii posle ispravleniya otchyota                           | 26,304 s     | uspeshno   |
| [root] Finaljnaya kompleksnaya proverka repozitoriya                                   | 217,632 s    | neuspeshno |
| [root] Polnyij nabor sleduyusjhego shaga s novyim tochnyim prompt-byudzhetom                  | 137,168 s    | uspeshno   |
| [root] Svyaznostj sessii posle obnovleniya prompt-byudzheta                             | 27,183 s     | uspeshno   |
| [root] Povtornaya finaljnaya kompleksnaya proverka repozitoriya                         | 1917,782 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3138,233 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-matrica razlichimo podtverdila iskhodnoye otsutstviye marshruta i posleduyusjhij uspekh strogogo host-readback, migracii rezervacii `3 → 4`, CAS-before-send, yedinstvennosti konkurentnogo pobeditelya, blokirovki povtornoj otpravki i shtatnogo sbrosa.
- Itogovyiye polnyiye naboryi proshli: `27` testov dispetcherskogo adaptera za `85,649` s, `108` testov FIFO za `150,681` s i `30` testov heartbeat-renderer za `0,442` s po vnutrennim izmereniyam naborov.
- Otricateljnyiye scenarii otklonyayut `active`, zavershyonnyij khod, inuyu ili chastichno sovpavshuyu oshibku, neizvestnyiye i lishniye polya, JSON-boolean vmesto celogo, nesovpadeniye task/host, preliminary `clientThreadId`, drift HEAD/ocheredi/claim/generation/adaptera i aktivnoye upravleniye libo reset.
- Zhivoj exact-diff posle odnokratnogo `automation_update` podtverdil, chto susjhestvuyusjhaya avtomatizaciya poluchila kanonicheskij prompt, a yeyo identichnostj, raspisaniye, status, target i ostaljnyiye polya sokhranilisj; vtoroj avtomatizacii ne sozdano.
- Pervaya popyitka polnogo smoke-check proshla podgotovku i shagi `1–5`, zatem shtatno ostanovilasj na proverke yazyika obyyavlenij: yedinstvennoye novoye smeshannoye imya uvelichilo Python-ostatok s `16 265` do `16 266`. Khyeshirovannaya karta zamenila yego tri tokenovyiye ssyilki; obsjhij inventarj vernulsya k prezhnim `43 262` obyyavleniyam, tochnaya proverka snimka i povtornyij nabor iz `27` testov adaptera proshli.
- Vtoraya popyitka proshla shagi `1–12` i ostanovilasj na shage svyaznosti rabochej sessii: profilj vremeni ne ispoljzoval bukvaljnyij sluzhebnyij prefiks, a tri izmenyonnyikh kontrakta navyikov byili perechislenyi bez pryamyikh ssyilok. Prefiks i ssyilki ispravlenyi; otdeljnaya adresnaya proverka svyaznosti proshla uspeshno za `26,304` s.
- Tretjya popyitka proshla rannij prefiks i ostanovilasj na shage `14/76`: istoricheskij regression ceiling dlya renderinga ostavalsya ravnyim `15 117` pri tekusjhem byte-exact live prompt dlinoj `19 605` simvolov. Istoriya pokazala, chto ceiling uzhe menyalsya vmeste s namerennyimi rasshireniyami i ne yavlyayetsya host/API-predelom; dva nezavisimyikh read-only-audita podtverdili obnovleniye rovno do `19 605` bez zapasa. Posle nego vse `167` testov sleduyusjhego shaga proshli za `136,980` s, a povtornaya svyaznostj sessii — za `27,183` s po vnutrennim izmereniyam.
- Finaljnyij polnyij smoke-check proshyol vse `76/76` shagov: vneshnyaya monotonnaya zapisj sostavila `1917,782` s, vnutrennyaya — `1917,690` s. Vmeste s tremya sokhranyonnyimi rannimi otkazami chetyire smoke-popyitki zanyali `2247,612` s; uspeshnaya popyitka ostalasj poslednim pryamyim proverochnyim zapuskom.
- Posle zakryitiya mashinnogo snimka otdeljno vyipolnyayutsya toljko razreshyonnyiye read-only-proverki zamyikaniya: strogaya sverka snimka zapuskov, svyaznostj rabochej sessii, recency Markdown, graf Obsidian i `git diff --check`. Oni ne dobavlyayutsya v zakryityij blok i ne porozhdayut rekursivnyij smoke-check.

## Resheniya i ogranicheniya

- Dlya vozobnovleniya prigoden toljko exact same-thread/same-host readback: `kind=codex`, tekusjheye sostoyaniye strogo `idle|notLoaded`, rovno odin novejshij khod `failed` s tochnoj allowlisted-oshibkoj razryiva potoka i otsutstviye lyuboj inoj aktivnoj zadachi krome postoyannoj zadachi dispetchera i rassmatrivayemogo neaktivnogo kandidata. Neprozrachnyiye `items` ne interpretiruyutsya i ne ispolnyayutsya.
- Do host-soobsjheniya odna Git-CAS-tranzakciya povtorno ograzhdayet registry/spec/run/reservation, branch/HEAD, FIFO generation, queue owner, exact claim, inactive management-fence, otsutstviye reset i adapter. Ona sokhranyayet klyuch, pokoleniye i failed-turn cursor v faze `вызов_мог_состояться`.
- Lyuboj rezuljtat, oshibka ili tajm-aut otpravki schitayetsya neodnoznachnyim: tik srazu zavershayetsya bez povtornoj otpravki, `create_thread`, replacement, release ili sinteza zaversheniya. Pending-sostoyaniye blokiruyet shtatnyij sbros i terminalizaciyu rezervacii.
- Vozobnovivshijsya ispolnitelj obyazan imetj tot zhe processnyij `CODEX_THREAD_ID`, pervyim instrumentaljnyim dejstviyem idempotentno vojti v prezhnij FIFO-bilet, perechitatj pravila, vosstanovitj dolgovechnuyu kontroljnuyu tochku ili uzhe zapusjhennyij yielded-process i podtverditj tot zhe klyuch pod temi zhe fence. Neizvestnyij iskhod prezhnego vneshnego effekta ne povtoryayetsya.
- [FUM-STEP-0142](../../Planirovaniye/kartochki-shagov/🗑️-FUM-STEP-0142-dobavitj-ograzhdyonnoye-vozobnovleniye-zadach-posle-poteri-svyazi.md) i [FUM-SBOJ-0014](../../Sboi/FUM-SBOJ-0014-ruchnoye-vozobnovleniye-posle-razryiva-potoka-otveta.md) ostayutsya aktivnyimi: tekusjhaya sessiya dokazala realizaciyu, testyi i tochnoye obnovleniye zhivogo prompt, no ne provodila upravlyayemyij zhivoj razryiv s dostavkoj, worker-ack i yedinichnyim zaversheniyem logicheskogo zapuska.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [dispetcher avtomatizacij FUM](../../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [FUM-STEP-0142](../../Planirovaniye/kartochki-shagov/🗑️-FUM-STEP-0142-dobavitj-ograzhdyonnoye-vozobnovleniye-zadach-posle-poteri-svyazi.md)
- [FUM-SBOJ-0014](../../Sboi/FUM-SBOJ-0014-ruchnoye-vozobnovleniye-posle-razryiva-potoka-otveta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:848689550be1c75ec737f0bf7df52f815da3dfa4681b14b178bf2a890267d143 -->
<!-- FUM-MD-RECENCY:END -->
