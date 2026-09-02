# Otchyot 2026-08-05 12:02:53 MSK - Perenesti avtozapusk shagov v universaljnyij dispetcher

Dejstvuyusjhij zapusk sleduyusjhego shaga perenesyon v universaljnyij dispetcher kak pervyij specializirovannyij adapter. Kanonicheskij reyestr `master` khranit odin active-marshrut s tochnoj celjyu rabochej kopii i vetki, usloviyami dopuska i tipom effekta, no ne kopiruyet kartochechnuyu zadachu ili kriterii. Obsjhij sloj vyibirayet i rezerviruyet zapusk, peredayot vyibor susjhestvuyusjhim `show` i `claim`, svyazyivayet uzhe sozdannyij zapusk s fakticheskoj ispolniteljskoj zadachej i podtverzhdayet obsjhij fence vmeste s kartochnyim.

Susjhestvuyusjhiye prikreplyonnaya zadacha i pyatiminutnyij heartbeat migrirovanyi na meste. Do i posle kazhdogo host-izmeneniya polnyij snimok i povtornyij audit podtverdili sokhraneniye identichnosti, celi, raspisaniya i statusa; izmenilisj toljko obyyavlennyiye imya, prompt, sluzhebnyij moment obnovleniya i zagolovok toj zhe zadachi. Novaya zadacha, vtoroj heartbeat ili neprozrachnyij identifikator v pamyati proyekta ne poyavilisj. FUM-STEP-0093 zavershena, a rabochij nabor otkryil FUM-STEP-0094 kak yedinstvennoye gotovoye avtomaticheskoye prodolzheniye.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj             | Granicyi i sposob izmereniya                                                               |
| ------------------------ | ------------------------ | ---------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | meneye 1 s                | Ot atomarnogo `join` do pervogo `admitted`; ocheredj byila svobodna                        |
| Soderzhateljnaya rabota    | okolo 1 ch 55 min         | Analiz, TDD-realizaciya, dokumentaciya, planirovaniye i ograzhdyonnyiye host-readback             |
| Celevyiye proverki         | 15 min 51 s do smoke     | Summa monotonnyikh dliteljnostej 40 pryamyikh vyizovov do finaljnogo kompleksnogo kontura       |
| Polnyij smoke-check       | sm. upravlyayemyij blok     | Yedinyij lokaljnyij kontur fiksiruyet sobstvennuyu dliteljnostj i rezuljtat                   |
| Atomarnyij commit+handoff | mashinnaya granica ocheredi | Ne vkhodit v predkommitnyij profilj; podtverzhdayetsya toljko itogovyim otvetom komandyi ocheredi |

Granica profilya: nachalo — 2026-08-05 12:02:53 MSK; konec — mashinnyij otvet atomarnogo commit+handoff posle poslednego read-only audita.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:1713229a5dae4f26ff5c7c5fb516e022ab0a8de2d66576875f813b535b750ed5 -->

| Vyizov                                                                            | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent Codex] TDD RED: pervyij adapter, dva fence i migraciya heartbeat   | 0,732 s      | neuspeshno |
| [kornevoj agent Codex] TDD: obsjhij run-fence i exact-diff migracii                | 5,099 s      | neuspeshno |
| [root] Kontrakt heartbeat-prompta posle perekhoda k dispetcheru                    | 129,46 s     | neuspeshno |
| [root] Identifikaciya tochnyikh regressij heartbeat-prompta                          | 131,138 s    | neuspeshno |
| [automation_names_update] TDD RED: kanonicheskiye host-imena dispetchera            | 0,077 s      | neuspeshno |
| [automation_names_update] TDD GREEN: avtonomnyiye testyi reyestra nazvanij           | 0,855 s      | uspeshno   |
| [automation_names_update] Zhivaya proverka proizvodstvennogo reyestra nazvanij      | 3,025 s      | uspeshno   |
| [automation_names_update] TDD RED: UI-zagolovok prikreplyonnoj zadachi             | 0,121 s      | neuspeshno |
| [automation_names_update] TDD GREEN: host-imena prikreplyonnoj zadachi i heartbeat | 0,821 s      | uspeshno   |
| [automation_names_update] Povtornaya zhivaya proverka host-imyon LinguisticKit       | 1,131 s      | uspeshno   |
| [root] Povtornaya proverka tochnyikh heartbeat-kontraktov                            | 0,806 s      | neuspeshno |
| [root] Heartbeat-prompt i upravleniye posle formulirovochnyikh ispravlenij           | 0,5 s        | neuspeshno |
| [root] Avtonomnyij dispetcher i adapter sleduyusjhego shaga                            | 13,24 s      | uspeshno   |
| [root] Kanonicheskij heartbeat-prompt obsjhego dispetchera                           | 0,518 s      | neuspeshno |
| [root] Poryadok host-vyizova posle obsjhej rezervacii                                | 0,498 s      | uspeshno   |
| [root] Odnostrochnyiye nablyudeniya i recovery finished_clean                         | 1,927 s      | neuspeshno |
| [root] Recovery finished_clean posle utochneniya formyi last_completion             | 1,961 s      | uspeshno   |
| [root] Polnyij avtonomnyij kontur obsjhego dispetchera posle yazyikovoj proverki        | 15,066 s     | uspeshno   |
| [root] Polnyij nabor avtonomnyikh testov adaptera sleduyusjhego shaga                   | 108,563 s    | neuspeshno |
| [root] Poisk pervogo ostatochnogo sboya testov adaptera                            | 0,077 s      | neuspeshno |
| [root] Poisk pervogo ostatochnogo sboya testov adaptera — korrektnyij vyizov         | 33,721 s     | neuspeshno |
| [root] Guard sozdaniya zadachi ogranichen tekusjhim tikom                             | 0,236 s      | uspeshno   |
| [root] Poisk sleduyusjhego ostatochnogo sboya testov adaptera                         | 33,951 s     | neuspeshno |
| [root] Tochnyij kontrakt host-sozdaniya zadachi                                      | 0,188 s      | uspeshno   |
| [root] Poisk ostatochnogo sboya posle utochneniya host-kontrakta                     | 73,822 s     | neuspeshno |
| [root] Polnyij nabor avtonomnyikh testov FIFO-ocheredi                               | 53,921 s     | neuspeshno |
| [root] Portativnyij FIFO-kontrakt obsjhego tika                                     | 0,128 s      | neuspeshno |
| [root] Portativnyij FIFO-kontrakt obsjhego tika — povtor                            | 0,132 s      | uspeshno   |
| [root] Polnyij nabor avtonomnyikh testov universaljnogo dispetchera                  | 14,63 s      | uspeshno   |
| [root] Testyi reyestra nazvanij avtomatizacij                                      | 0,786 s      | uspeshno   |
| [root] Obnovleniye fence kartochek rabochego nabora master                          | 0,74 s       | uspeshno   |
| [root] Validaciya rabochego nabora master posle zaversheniya kartochki                | 0,719 s      | uspeshno   |
| [root] Vyibor sleduyusjhej gotovoj kartochki master                                   | 0,735 s      | uspeshno   |
| [root] Validaciya reyestra planirovaniya                                            | 0,32 s       | uspeshno   |
| [root] Finaljnyij polnyij nabor testov adaptera sleduyusjhego shaga                    | 129,378 s    | neuspeshno |
| [root] Kontraktyi renderer heartbeat posle uporyadochivaniya host-vyizova             | 0,579 s      | uspeshno   |
| [root] Sovmestimostj guard mezhdu heartbeat-tikami                                | 0,241 s      | uspeshno   |
| [root] Sovmestimostj tochnogo kontrakta create_thread                             | 0,24 s       | uspeshno   |
| [root] Finaljnyij polnyij nabor testov FIFO-ocheredi                                | 61,864 s     | uspeshno   |
| [root] Povtornyij finaljnyij polnyij nabor testov adaptera sleduyusjhego shaga          | 128,866 s    | uspeshno   |
| [root] Polnyij smoke-check repozitoriya                                            | 1560,753 s   | neuspeshno |
| [root] Diagnostika novyikh mashinno-lokaljnyikh putej                                 | 11,669 s     | neuspeshno |
| [root] Proverka mashinno-lokaljnyikh putej posle obnovleniya tochnogo fingerprint     | 11,746 s     | uspeshno   |
| [root] Povtornyij polnyij smoke-check repozitoriya                                  | 1591,796 s   | neuspeshno |
| [root] Proverka umenjshennogo snimka obyyavlenij koda                              | 5,049 s      | uspeshno   |
| [root] Povtornyiye testyi universaljnogo dispetchera posle russkikh imyon              | 18,552 s     | uspeshno   |
| [root] Povtornyiye testyi reyestra nazvanij posle russkikh imyon                       | 1,093 s      | uspeshno   |
| [root] Povtornyiye testyi adaptera sleduyusjhego shaga posle russkikh imyon               | 134,112 s    | uspeshno   |
| [root] Predfinaljnaya svyaznostj rabochej sessii                                    | 23,908 s     | uspeshno   |
| [root] Finaljnyij polnyij smoke-check repozitoriya                                  | 1599,84 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 5909,33 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-nabor obsjhego dispetchera prokhodit: 31 test podtverzhdayet kanonicheskij pervyij adapter, inline-nablyudeniya, razdeleniye host- i task-identichnosti, obsjhij bind/verify i terminalizaciyu po tochnomu zaversheniyu ocheredi.
- Polnyij staryij kontrakt sleduyusjhego shaga prokhodit: 156 testov podtverzhdayut vyibor, claim/release/rearm, renderer heartbeat, poryadok obsjhej rezervacii do host-vyizova i oba urovnya fence.
- Polnyij kontrakt FIFO prokhodit: 58 testov podtverzhdayut otsutstviye bileta u planovogo tika i obyichnyij dopusk ispolniteljskoj libo poljzovateljskoj zadachi.
- Reyestr nazvanij prokhodit 22 avtonomnyikh testa; novyiye russkoye otobrazheniye i proveryayemaya transliteraciya zaregistrirovanyi, prezhneye imya sokhraneno toljko kak legacy.
- Rabochij nabor i planovyij reyestr validnyi; FUM-STEP-0094 poluchila svezhij soderzhateljnyij khyesh i `step_id`, schyotchiki ravnyi `ready=1`, `paused=7`, `blocked=1`.
- Kontroliruyemyij host-audit do migracii, posle migracii i posle finaljnoj sinkhronizacii renderer podtverdil odnu tu zhe zadachu i odin tot zhe heartbeat bez izmeneniya celi, raspisaniya i statusa.
- Okonchateljnyij rezuljtat polnogo smoke-check i dliteljnosti vsekh pryamyikh vyizovov formiruyutsya nizhe iz mashinnyikh JSON-zapisej, a ne redaktiruyutsya vruchnuyu.

## Resheniya i ogranicheniya

- Universaljnyij reyestr opisyivayet marshrutizaciyu, raspisaniye, usloviya, effekt i ispolnitelya. Skhema kartochek, soderzhateljnyij vyibor, `show`, `claim`, `release` i `rearm` ostayutsya vnutri specializirovannogo adaptera.
- Obsjhaya rezervaciya ispoljzuyet tot zhe sluchajnyij UUID, chto i kartochnyij claim, no host-otvet sozdaniya ne podmenyayet fakticheskij `CODEX_THREAD_ID`. Ispolnitelj posle FIFO-dopuska sam svyazyivayet i proveryayet obsjhij zapusk, zatem proveryayet kartochnyij fence.
- `committed` terminaliziruyet obsjhij zapusk kak uspekh. `finished_clean` schitayetsya bezopasnoj neudachej toljko posle dokazannogo vneshnego vosstanovleniya kartochnogo claim; uspeshnyij ispolnitelj sam `release` ne vyizyivayet.
- Poljzovateljskoye soobsjheniye v prikreplyonnoj zadache ne yavlyayetsya heartbeat-tikom i pered lyubyim izmeneniyem prokhodit obyichnuyu FIFO-ocheredj. Stop/Start sokhranyayut tu zhe zapisj i ne osvobozhdayut uzhe sozdannyij zapusk.
- Host-interfejs obnovleniya ne predostavlyayet expected-version/CAS. Polnyij snimok, povtornaya proverka pered izmeneniyem i tochnyij readback obnaruzhivayut nablyudayemyij drejf, no ne obyyavlyayutsya tranzakcionnoj zasjhitoj ot nezavisimogo odnovremennogo pereklyucheniya.
- Trebovaniye universaljnoj dispetcherizacii ostayotsya v rabote: upravleniye soobsjheniyami, analitika i itogovaya skvoznaya priyomka vyinesenyi v posleduyusjhiye kartochki.
- Sessiya zavershayet toljko lokaljnyij commit+handoff. Push i nizkourovnevyij `publish` ne vyipolnyayutsya.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 15:34:22 MSK -->
<!-- content-sha256: sha256:9f1da54d0a792442e6c114d2581a906d6cdd1f136484c801ac6c5e766ed3f383 -->
<!-- FUM-MD-RECENCY:END -->
