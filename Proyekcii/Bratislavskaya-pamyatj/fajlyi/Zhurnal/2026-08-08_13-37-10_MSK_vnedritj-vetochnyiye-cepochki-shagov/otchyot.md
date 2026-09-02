# Otchyot 2026-08-08 13:37:10 MSK - Vnedritj vetochnyiye cepochki shagov

V pamyatj FUM vvedenyi kanonicheskiye kartochki cepochek shagov, ikh strogaya mashinnaya proyekciya i pervyij ograzhdyonnyij protokol perekhoda na vetku cepochki. Pervaya cepochka — priyomka universaljnogo dispetchera — vyibrana aktivnoj dlya sleduyusjhego ispolneniya; dve nezavisimyiye cepochki sokhranenyi zaplanirovannyimi. Novaya kornevaya zadacha mozhet pervyim instrumentaljnyim dejstviyem sozdatj otsutstvuyusjhij target ref na tochnom iskhodnom `HEAD`, pereklyuchitj symbolic `HEAD` bez izmeneniya dereva i srazu poluchitj FIFO-dopusk uzhe v etoj vetke.

Semantika smoke-check zamknuta na rezuljtat sessii: nulevoj kod vnutrennego proverochnogo processa oznachayet toljko projdennyij plan. Vneshnij uspekh susjhestvuyet lishj posle terminaljnoj zapisi zapuska, zakryityikh otchyota i `снимок.json` i rezuljtata `committed` atomarnogo `commit+handoff` v vetke tekusjhej cepochki. Tekusjhaya zadacha byila dopusjhena na `master` do poyavleniya etogo mekhanizma, poetomu ostayotsya odnorazovoj bootstrap-sessiyej i vetku ne pereklyuchayet.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                          |
| ------------------------ | ------------ | --------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | Dopusk poluchen do sozdaniya papki zaprosa; otdeljnyij wall-clock-interval ne sokhranilsya               |
| Soderzhateljnaya rabota    | ne izmereno  | Audit, TDD i realizaciya perekryivalisj mezhdu kornem i tremya subagentami; dliteljnosti ne summiruyutsya |
| Celevyiye proverki         | ne izmereno  | Tochnyiye dliteljnosti kazhdogo pryamogo vyizova sokhranyayet upravlyayemyij blok i budusjhij snimok              |
| Polnyij smoke-check       | 1 803,830 s  | Vneshnyaya dliteljnostj terminaljnoj zapisi № 63; vnutrennij plan zanyal 1 803,732 s                    |
| Atomarnyij commit+handoff | ne izmereno  | Vyipolnyayetsya posle zamyikaniya otchyota; posle `committed` lyubyiye dopisyivaniya v sessiyu zapresjhenyi          |

Granica profilya: ot kanonicheskogo vremeni zaprosa `2026-08-08 13:37:10 MSK` do finaljnoj atomarnoj peredachi; ozhidaniye FIFO ne izmereno, paralleljnaya soderzhateljnaya rabota ne summiruyetsya, pryamyiye proverki uchityivayutsya otdeljno.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:7d1026f486df5296a546e3d879e7e823eac6f7079c4262643ec0c252791007bc -->

| Vyizov                                                                                               | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] Krasnaya regressiya smoke→commit vetki cepochki                                       | 0,123 s      | neuspeshno |
| [kornevoj agent] Krasnaya regressiya reyestra kartochek cepochek                                         | 0,114 s      | neuspeshno |
| [kornevoj agent] Krasnaya regressiya perekhoda na vetku cepochki                                        | 0,066 s      | neuspeshno |
| [kornevoj agent] Krasnaya regressiya perekhoda na vetku cepochki — funkcionaljnyij otkaz                 | 0,31 s       | neuspeshno |
| [kornevoj agent] Testyi reyestra planirovaniya s kartochkami cepochek                                    | 0,935 s      | neuspeshno |
| [kornevoj agent] Povtor testov reyestra planirovaniya s quoted TOML                                   | 0,971 s      | neuspeshno |
| [kornevoj agent] Tretij progon testov reyestra planirovaniya                                          | 0,922 s      | uspeshno   |
| [kornevoj agent] Sborka reyestra planirovaniya versii 8                                               | 0,327 s      | uspeshno   |
| [kornevoj agent] Kontrakt smoke-sessii i kommita vetki cepochki                                      | 0,116 s      | uspeshno   |
| [kornevoj agent] Krasnaya regressiya yedinstvennoj aktivnoj cepochki                                    | 0,113 s      | neuspeshno |
| [kornevoj agent] Zelyonaya regressiya yedinstvennoj aktivnoj cepochki                                    | 0,148 s      | uspeshno   |
| [kornevoj agent] Testyi ograzhdyonnogo perekhoda na vetku cepochki                                       | 4,018 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor testov FIFO i perekhoda cepochek                                        | 156,397 s    | uspeshno   |
| [kornevoj agent] Finaljnyij celevoj nabor testov reyestra planirovaniya                                | 0,922 s      | uspeshno   |
| [kornevoj agent] Krasnaya regressiya prostranstva vetok cepochek                                       | 0,815 s      | neuspeshno |
| [kornevoj agent] Zelyonaya regressiya prostranstva vetok cepochek                                       | 0,527 s      | uspeshno   |
| [kornevoj agent] Finaljnyij celevoj nabor perekhoda na cepochku                                        | 4,391 s      | uspeshno   |
| [kornevoj agent] Peresborka reyestra s aktivnoj cepochkoj                                             | 0,329 s      | uspeshno   |
| [kornevoj agent] Validaciya reyestra planirovaniya versii 8                                            | 0,323 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown pered svyaznostjyu                                      | 0,623 s      | uspeshno   |
| [kornevoj agent] Peresborka svezhesti grafa Obsidian                                                 | 0,356 s      | uspeshno   |
| [kornevoj agent] Proverka probelov i konfliktnyikh markerov diff                                      | 0,049 s      | uspeshno   |
| [kornevoj agent] Svyaznostj rabochej sessii pered polnyim smoke-check                                  | 27,616 s     | neuspeshno |
| [kornevoj agent] Povtornoye obnovleniye svezhesti posle utochneniya inventarya                            | 0,625 s      | uspeshno   |
| [kornevoj agent] Povtornaya peresborka svezhesti grafa posle inventarya                                | 0,412 s      | uspeshno   |
| [kornevoj agent] Povtornaya svyaznostj rabochej sessii pered smoke-check                               | 28,276 s     | uspeshno   |
| [kornevoj agent] Finaljnaya peresborka reyestra posle vyiravnivaniya indeksa                            | 0,336 s      | uspeshno   |
| [kornevoj agent] Finaljnaya validaciya reyestra posle vyiravnivaniya indeksa                             | 0,339 s      | uspeshno   |
| [kornevoj agent] Finaljnaya proverka diff pered smoke-check                                          | 0,052 s      | uspeshno   |
| [kornevoj agent] Predfinaljnyij polnyij smoke-check repozitoriya                                       | 62,654 s     | neuspeshno |
| [kornevoj agent] Diagnostika mashinno-lokaljnyikh putej posle smoke-otkaza                             | 23,064 s     | neuspeshno |
| [kornevoj agent] Filjtraciya nepokryityikh mashinno-lokaljnyikh putej                                      | 58,385 s     | neuspeshno |
| [kornevoj agent] Zelyonaya proverka mashinno-lokaljnyikh putej                                           | 23,507 s     | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti posle ispravleniya policy                                       | 0,621 s      | uspeshno   |
| [kornevoj agent] Peresborka grafa posle ispravleniya policy                                          | 0,368 s      | uspeshno   |
| [kornevoj agent] Svyaznostj posle ispravleniya rannego smoke-otkaza                                   | 29,514 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle ispravleniya policy                               | 34,525 s     | neuspeshno |
| [kornevoj agent] Povtornyij itogovyij polnyij smoke-check posle vosstanovleniya svyazi                   | 35,341 s     | neuspeshno |
| [kornevoj agent] Diagnostika mashinno-lokaljnyikh putej v izmenyonnyikh fajlakh posle vosstanovleniya svyazi | 13,1 s       | neuspeshno |
| [kornevoj agent] GREEN mashinno-lokaljnyikh putej posle ustraneniya diagnosticheskoj tiljdyi              | 13,071 s     | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown posle ispravleniya diagnostiki                         | 0,872 s      | uspeshno   |
| [kornevoj agent] Peresborka svezhesti grafa posle ispravleniya diagnostiki                            | 0,401 s      | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj posle ispravleniya mashinno-lokaljnogo puti                  | 27,127 s     | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle ustraneniya diagnosticheskoj tiljdyi                | 44,688 s     | neuspeshno |
| [kornevoj agent] Diagnostika latinskogo ostatka v izmenyonnyikh Python-fajlakh                          | 4,558 s      | neuspeshno |
| [kornevoj agent] Povtor diagnostiki latinskogo ostatka v izmenyonnyikh Python-fajlakh                   | 4,982 s      | uspeshno   |
| [kornevoj agent] Sravneniye latinskikh obyyavlenij izmenyonnyikh fajlov s HEAD                            | 4,783 s      | uspeshno   |
| [kornevoj agent] Sukhoj plan perevoda obyyavlenij testa perekhoda na cepochku                           | 0,122 s      | uspeshno   |
| [kornevoj agent] Primeneniye kartyi perevoda obyyavlenij testa perekhoda na cepochku                     | 0,124 s      | uspeshno   |
| [kornevoj agent] GREEN otsutstviya novyikh latinskikh obyyavlenij otnositeljno HEAD                      | 5,104 s      | uspeshno   |
| [kornevoj agent] Obnovleniye snimka istoricheskogo latinskogo ostatka bez izmeneniya mnozhestva imyon    | 4,66 s       | uspeshno   |
| [kornevoj agent] GREEN tochnogo snimka latinskogo ostatka posle perevoda                             | 4,711 s      | uspeshno   |
| [kornevoj agent] Strogoye dokazateljstvo toljko strokovyikh sdvigov istoricheskogo ostatka              | 8,384 s      | neuspeshno |
| [kornevoj agent] Strogoye sravneniye izmenyonnyikh vkhodov istoricheskogo ostatka s HEAD                   | 4,75 s       | uspeshno   |
| [kornevoj agent] Povtor GREEN perekhoda na cepochku posle perevoda obyyavlenij                         | 4,434 s      | uspeshno   |
| [kornevoj agent] Povtor GREEN planovogo reyestra posle perevoda obyyavlenij                           | 3,809 s      | uspeshno   |
| [kornevoj agent] Povtor polnogo FIFO-nabora posle perevoda obyyavlenij                               | 160,125 s    | uspeshno   |
| [kornevoj agent] Testyi avtomatizacii perevoda obyyavlenij posle primeneniya kartyi                     | 1,273 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown posle perevoda obyyavlenij                             | 0,634 s      | uspeshno   |
| [kornevoj agent] Peresborka svezhesti grafa posle perevoda obyyavlenij                                | 0,399 s      | uspeshno   |
| [kornevoj agent] GREEN mashinno-lokaljnyikh putej posle perevoda i otchyota                              | 12,743 s     | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj posle perevoda obyyavlenij                                  | 26,72 s      | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check posle perevoda obyyavlenij                              | 1803,83 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2653,934 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-red razlichimo zafiksiroval otsutstviye smoke→commit-kontrakta, planovoj skhemyi cepochek, CLI perekhoda, trebovaniya yedinstvennoj aktivnoj cepochki i ogranicheniya target-prostranstva. Vse ozhidayemyiye otkazyi sokhranenyi v mashinnom zhurnale, a ne skryityi posleduyusjhimi zelyonyimi progonami.
- Planovyij reyestr skhemyi `8` sokhranyayet tri cepochki s tochnyimi vetkami i uporyadochennyimi izvestnyimi `FUM-STEP-*`, trebuyet rovno odnu aktivnuyu kartochku, tochnoye indeksirovaniye i otsutstviye peresecheniya neotozvannyikh cepochek. Polnyij nabor iz `53` testov proshyol.
- Perekhod versii `1` proshyol shestj adresnyikh scenariyev: happy path, gryaznyij checkout, zanyataya ocheredj, susjhestvuyusjhaya target-vetka, target vne `refs/heads/codex/` i idempotentnyij povtor poteryannogo otveta.
- Polnyij FIFO-nabor proshyol aktualjnyiye `109` testov; otdeljno proshli vse shestj scenariyev perekhoda na cepochku.
- Mashinnyij reyestr peresobran i proshyol `validate`; aktivnaya cepochka `FUM-ЦЕПОЧКА-0001` ukazyivayet na yesjhyo otsutstvuyusjhuyu celevuyu vetku, poetomu sleduyusjhij perekhod ne maskiruyet susjhestvuyusjhuyu istoriyu.
- Pervyij polnyij smoke-check ostanovilsya do dorogikh testov na shage `5/76`: novyij spisok zapresjhyonnyikh simvolov Git-ref soderzhal opredeleniye formyi home-expansion bez policy-fingerprint. Shtatnyij generator dobavil yedinstvennoye `allow.path-validation-definition`, i povtornaya adresnaya proverka proshla.
- Posle prokhozhdeniya shaga `5/76` smoke-check ostanovilsya na shage `6/76`: novyiye testyi soderzhali latinskiye sobstvennyiye obyyavleniya. Khyeshirovannaya karta perevoda proshla sukhoj plan i atomarnoye primeneniye. Strogoye sravneniye izmenyonnyikh vkhodov s `HEAD` podtverdilo ravenstvo `2 119` obyyavlenij, nolj nestrokovyikh razlichij i `2 074` sdviga strok. Obsjhij ostatok ne izmenilsya i sostavlyayet `43 262` obyyavleniya; yego otpechatok obnovlyon s `sha256:2faa2d…945b3` na `sha256:a94aa8…545980`, strogaya proverka i `9` testov instrumenta proshli.
- Itogovyij vnutrennij smoke-check uspeshno zavershil vse `76/76` shagov za `1 803,732` s. Vneshnyaya terminaljnaya zapisj № 63 zakryilasj so statusom `успешно` i dliteljnostjyu `1 803,830` s; ona ostanetsya poslednej zaregistrirovannoj proverkoj pered zamyikaniyem snimka i `commit+handoff`.

## Resheniya i ogranicheniya

- Tekusjhij FIFO-vladelec ne pereklyuchayet vetku. Eta uzhe dopusjhennaya migracionnaya sessiya ostayotsya na `refs/heads/master`; pervoye fakticheskoye pereklyucheniye vyipolnyayet sleduyusjhaya zadacha do otdeljnogo `join` po aktivnoj kartochke i tochnyim fenced-argumentam.
- Pervaya versiya perekhoda namerenno prinimayet toljko otsutstvuyusjhij target ref, sozdavayemyij na exact source HEAD s tem zhe derevom. Uzhe susjhestvuyusjhaya ili razoshedshayasya vetka, gryazj, vladelec, ozhidaniye, drift kartochki, vetki libo vershinyi zakryivayut operaciyu; perenos mezhdu razoshedshimisya derevjyami ne realizovan.
- Kartochka cepochki yavlyayetsya kanonicheskim upstream, a dejstvuyusjhiye selector i dispatcher poka ostayutsya specializirovannyimi dlya `master.next-step`. Ikh generaciya i obsjhaya dispetcherizaciya po cepochkam trebuyut otdeljnoj versionirovannoj migracii.
- Strogaya mashinnaya attestation, svyazyivayusjhaya zakryityij smoke-run, staged tree i queue commit, yesjhyo ne vvedena. V etoj versii garantiyu obrazuyut obyazateljnyij sostavnoj protokol rabochej sessii, fail-closed svyaznostj i pravilo, zapresjhayusjheye nazyivatj vnutrennij zelyonyij process uspeshnoj smoke-sessiyej do `committed`; vnutrennij runner sam kommit ne vyipolnyayet.
- Pustaya ili chistaya sessiya ne poluchayet iskusstvennyij kommit: trebovaniye otnositsya k uspeshnomu polnomu smoke izmenyayusjhej sessii, a `finish-clean` ostayotsya otdeljnyim neuspeshnyim/no-op iskhodom bez smoke-uspekha.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-08 18:43:35 MSK -->
<!-- content-sha256: sha256:cbba4e424b8b8c61089c3257b3c40e411bfa1e9c2068235a81d2c802e0d2185e -->
<!-- FUM-MD-RECENCY:END -->
