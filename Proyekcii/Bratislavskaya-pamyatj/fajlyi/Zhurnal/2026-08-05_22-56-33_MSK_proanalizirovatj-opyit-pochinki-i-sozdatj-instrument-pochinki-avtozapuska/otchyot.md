# Otchyot 2026-08-05 22:56:33 MSK - Proanalizirovatj opyit pochinki i sozdatj instrument pochinki avtozapuska

Sozdan vosproizvodimyij vnepolosnyij instrument pochinki avtozapuska cherez otdeljnuyu obyichnuyu zadachu Codex v tom zhe sokhranyonnom lokaljnom proyekte. Roditeljskij poljzovateljskij khod toljko ograzhdayet odnu popyitku, rovno odin raz peresekayet `create_thread` i nemedlenno osvobozhdayet FIFO; dochernyaya zadacha samostoyateljno vkhodit v ocheredj, podtverzhdayet iskhodnuyu vershinu i sobstvennoye pokoleniye, vosproizvodit fakticheskij otkaz testom i ispravlyayet susjhestvuyusjhuyu avtomatizaciyu toljko na meste.

Opyit prezhnikh pochinok svedyon v yedinyij diagnosticheskij poryadok. On okhvatyivayet zavisshiye i neodnoznachnyiye claim, protekaniye sostoyaniya mezhdu tikami, otsutstviye polozhiteljnoj vetvi svobodnoj ocheredi, perezapisj polnogo prompt pri `Stop`/`Start`, razlichiye uzhe razobrannogo obyyekta i JSON-teksta, granicu vlozhennoj host-orkestracii, drejf tochnoj skhemyi `list_threads`, staryij claim posle otkata i rassoglasovaniye obsjhego i kartochochnogo fence. Najdennaya istoricheskaya prichina ne podmenyayet povtornoye nablyudeniye vsekh sloyov.

## Rezuljtat

Novyij [lokaljnyij navyik](../../Instrumentyi/fum-pochinka-avtozapuska/SKILL.md) soderzhit roditeljskij protokol, zakryityij runtime-konvert, prompt otdeljnoj zadachi, Git-CAS-avtomat sostoyanij i integracionnyiye testyi s nastoyasjhej fiksturoj FIFO. Sostoyaniye oblasti checkout/vetka imeyet zakryituyu skhemu i fazyi ot `зарезервирован` do `завершён`; neizvestnoye pole, inoj tip, smena vetki, iskhodnoj vershinyi, pokoleniya, vladeljca ili gryaznaya rabochaya kopiya zakryivayut perekhod. Kazhdyij perekhod, vklyuchaya idempotentnyij, atomarno proveryayet bazovuyu vershinu vladeljca, snimok ocheredi i prezhnij repair-ref; terminaljnoye podtverzhdeniye kommita nevozmozhno bez otdeljnoj zadachi, podtverzhdyonnogo pokoleniya i sovpadayusjhej s planom bazovoj vershinyi.

Host-granica namerenno odnorazovaya. Yeyo povtor ne yavlyayetsya idempotentnyim uspekhom i poetomu ne mozhet razreshitj vtoroj `create_thread` posle poteryannogo otveta. `clientThreadId` ostayotsya toljko svideteljstvom podgotovki i ne podmenyayet fakticheskij `CODEX_THREAD_ID` rebyonka. Komanda `состояние` i otvetyi perekhodov vozvrasjhayut toljko smyislovyiye priznaki bez thread-, host-, task- i generation-znachenij.

Posle peredachi roditelya rebyonok ne nasleduyet razresheniye na staroj vershine: lyuboj `reload_required` privodit k perechityivaniyu i posleduyusjhemu zakryitomu otkazu `verify-run`, yesli `HEAD` otlichayetsya ot zakreplyonnogo plana. Posle uspeshnogo fence rebyonok fiksiruyet diagnostiku i proverki v soderzhateljnom kommite ocheredi. Pozdnij upravlyayusjhij khod dayot iskhod `коммит_подтверждён` toljko po yesjhyo tekusjhemu tochnomu `last_completion` vida `committed`; yesli yedinstvennyij slot uzhe perezapisan, popyitka zakryivayetsya kak `неподтверждён` lishj posle dokazannogo otsutstviya rebyonka sredi vladeljca i ozhidayusjhikh FIFO. Ni odin iz etikh iskhodov ne podmenyayet posleduyusjhij polnyij idle-marshrut i zhivuyu priyomku.

Susjhestvuyusjhij helper polnogo snimka avtomatizacii rasshiren komandami `prepare-repair` i `verify-repair`. Pochinka trebuyet obyazateljnyiye `created_at`, `updated_at` i polozhiteljnuyu celuyu `version`, perenosit polnyij deklarativnyij snimok i prinimayet toljko raw exact diff polej `prompt` i `updated_at`, vklyuchaya neizmennostj iskhodnyikh target- i notification-psevdonimov i tochnyikh tipov vlozhennyikh znachenij. Zhivaya avtomatizaciya v etoj sessii ne menyalasj: rezuljtatom zaprosa yavlyayetsya instrument i kontrakt otdeljnoj zadachi, a ne novyij remont uzhe vosstanovlennogo tekusjhego heartbeat.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj                  | Granicyi i sposob izmereniya                                                                                      |
| ------------------------ | ----------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | otsutstvovalo                 | Pervyij atomarnyij `join` srazu vernul `admitted`; otdeljnogo intervala ozhidaniya ne byilo                          |
| Soderzhateljnaya rabota    | otdeljno ne izmeryalasj        | Analiz istorii, tri paralleljnyikh revjyu, proyektirovaniye avtomata, TDD, dokumentaciya i ispravleniye zamechanij     |
| Celevyiye proverki         | sm. upravlyayemyij blok          | Summa verkhneurovnevyikh adresnyikh vyizovov; paralleljnyiye zapuski po wall-clock neljzya skladyivatj kak elapsed-vremya |
| Polnyij smoke-check       | sm. poslednyuyu mashinnuyu stroku | Poslednij zapisyivayemyij vyizov okhvachennoj granicyi                                                                 |
| Atomarnyij commit+handoff | vne chislovoj granicyi          | Vyipolnyayetsya posle zakryitiya snimka i sluzhebnyikh zamyikayusjhikh proverok                                              |

Granica profilya: nachalo — metka sessii `2026-08-05 22:56:33 MSK`; konec — rezuljtat poslednego predfinaljnogo polnogo smoke-check. Zakryitiye snimka, samossyilochnyiye proverki i commit+handoff vyipolnyayutsya posle mashinnoj summyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:2a3b0794c0e07e745e73b31485103da647c07518cec87b1677b817a2dbe755ba -->

| Vyizov                                                                                                  | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------------ | ------------ | --------- |
| [kornevoj agent] TDD-red zhiznennogo cikla zadachi pochinki avtozapuska                                   | 0,393 s      | neuspeshno |
| [kornevoj agent] TDD-green zhiznennogo cikla zadachi pochinki avtozapuska                                 | 10,543 s     | neuspeshno |
| [kornevoj agent] Povtor TDD-green zhiznennogo cikla zadachi pochinki avtozapuska                          | 10,545 s     | uspeshno   |
| [kornevoj agent] TDD-red prompt-only snimka zhivoj avtomatizacii                                        | 0,57 s       | neuspeshno |
| [kornevoj agent] TDD-green prompt-only snimka zhivoj avtomatizacii                                      | 0,528 s      | uspeshno   |
| [kornevoj agent] TDD-red chistotyi dochernego verify-run                                                  | 13,407 s     | neuspeshno |
| [kornevoj agent] TDD-green chistotyi dochernego verify-run                                                | 13,33 s      | uspeshno   |
| [kornevoj agent] TDD-red UUIDv7 i otdeljnosti ispolnitelya pochinki                                      | 7,598 s      | neuspeshno |
| [kornevoj agent] TDD-green UUIDv7 i otdeljnosti ispolnitelya pochinki                                    | 15,532 s     | uspeshno   |
| [kornevoj agent] Proverka yazyika obyyavlenij novogo instrumenta                                          | 4,696 s      | neuspeshno |
| [kornevoj agent] Diagnosticheskij inventarj obyyavlenij koda                                             | 4,435 s      | uspeshno   |
| [kornevoj agent] Diagnostika novyikh latinskikh obyyavlenij                                                | 4,395 s      | uspeshno   |
| [kornevoj agent] Polnyij adresnyij nabor instrumenta pochinki avtozapuska                                 | 16,876 s     | uspeshno   |
| [kornevoj agent] Povtor diagnostiki novyikh latinskikh obyyavlenij                                         | 4,403 s      | uspeshno   |
| [kornevoj agent] Sravneniye smyislovogo ostatka latinskikh obyyavlenij s HEAD                              | 6,602 s      | neuspeshno |
| [kornevoj agent] Povtornoye kratkoye sravneniye smyislovogo ostatka latinskikh obyyavlenij s HEAD            | 6,514 s      | neuspeshno |
| [kornevoj agent] Sravneniye smyislovogo ostatka latinskikh obyyavlenij s HEAD posle NFC-normalizacii putej | 6,673 s      | uspeshno   |
| [kornevoj agent] Mekhanicheskoye obnovleniye snimka pozicij istoricheskogo ostatka obyyavlenij               | 4,345 s      | uspeshno   |
| [kornevoj agent] Proverka obnovlyonnogo snimka istoricheskogo ostatka obyyavlenij                         | 4,575 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor testov instrumenta pochinki avtozapuska                                   | 17,04 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor testov sleduyusjhego shaga vetki                                             | 127,923 s    | uspeshno   |
| [kornevoj agent] TDD-red zapreta dopuska ispolnitelya na izmenivshejsya vershine                           | 3,56 s       | neuspeshno |
| [kornevoj agent] TDD-green i polnyij nabor testov instrumenta posle ograzhdeniya vershinyi                  | 20,568 s     | uspeshno   |
| [kornevoj agent] TDD-red odnokratnoj host-granicyi i neraskryivayusjhego statusa                            | 0,073 s      | neuspeshno |
| [kornevoj agent] TDD-red polnotyi readback pri prompt-only pochinke                                      | 0,133 s      | neuspeshno |
| [kornevoj agent] TDD-red odnokratnoj host-granicyi i neraskryivayusjhego statusa                            | 21,155 s     | neuspeshno |
| [kornevoj agent] TDD-green odnokratnoj host-granicyi i neraskryivayusjhego statusa                          | 21,057 s     | uspeshno   |
| [kornevoj agent] TDD-green polnotyi readback pri prompt-only pochinke                                    | 0,611 s      | uspeshno   |
| [kornevoj agent] TDD-red neprotukhayusjhego zakryitiya popyitki posle perezapisi last_completion              | 5,868 s      | neuspeshno |
| [kornevoj agent] TDD-green neprotukhayusjhego zakryitiya i polnyij nabor instrumenta                          | 33,52 s      | uspeshno   |
| [kornevoj agent] TDD-red zakryitoj skhemyi dolgovechnogo sostoyaniya pochinki                                 | 1,673 s      | neuspeshno |
| [kornevoj agent] TDD-green zakryitoj skhemyi i polnyij nabor instrumenta                                   | 26,518 s     | uspeshno   |
| [kornevoj agent] Proverka zaregistrirovannogo imeni instrumenta pochinki                                | 3,297 s      | uspeshno   |
| [kornevoj agent] Finaljnoye smyislovoye sravneniye ostatka obyyavlenij s HEAD                               | 7,464 s      | uspeshno   |
| [kornevoj agent] Finaljnoye obnovleniye pozicionnogo snimka ostatka obyyavlenij                           | 4,126 s      | uspeshno   |
| [korenj] Polnyij nabor renderer i tochnogo snimka posle recenzii                                         | 0,491 s      | uspeshno   |
| [korenj] Polnyij nabor instrumenta pochinki avtozapuska posle recenzii                                   | 28,192 s     | uspeshno   |
| [korenj] Polnyij regressionnyij nabor sleduyusjhego shaga posle recenzii                                     | 109,93 s     | uspeshno   |
| [korenj] Obnovleniye snimka istoricheskogo ostatka posle finaljnyikh pravok koda                           | 4,991 s      | uspeshno   |
| [korenj] Proverka probeljnoj chistotyi diff posle recenzii                                               | 0,034 s      | uspeshno   |
| [korenj] Proverka finaljnogo snimka istoricheskogo ostatka obyyavlenij                                   | 4,171 s      | uspeshno   |
| [korenj] Polnyij nabor pochinki posle kanonizacii UUID                                                   | 29,506 s     | uspeshno   |
| [korenj] Nabor renderer posle tipochuvstviteljnogo exact diff                                           | 0,539 s      | uspeshno   |
| [korenj] Nabor renderer posle zakryitiya tipovyikh obkhodov                                                 | 0,481 s      | uspeshno   |
| [korenj] Polnyij nabor pochinki posle razdeleniya kommita i zhivoj priyomki                                 | 29,494 s     | uspeshno   |
| [korenj] Nabor renderer s vlozhennyim tipochuvstviteljnyim exact diff                                      | 0,491 s      | uspeshno   |
| [korenj] Polnyij nabor pochinki s razlichimyim registrovyim UUID                                            | 28,969 s     | uspeshno   |
| [korenj] Finaljnoye obnovleniye snimka istoricheskogo ostatka obyyavlenij                                  | 4,167 s      | uspeshno   |
| [korenj] Finaljnaya proverka snimka istoricheskogo ostatka obyyavlenij                                    | 4,126 s      | uspeshno   |
| [korenj] Obnovleniye Markdown-recency pered obsjhej priyomkoj                                              | 0,626 s      | uspeshno   |
| [korenj] Obnovleniye teplovoj kartyi Obsidian pered obsjhej priyomkoj                                       | 0,38 s       | uspeshno   |
| [korenj] Predfinaljnaya kompleksnaya proverka repozitoriya                                                | 1622,01 s    | neuspeshno |
| [korenj] Lokalizaciya mashinno-lokaljnyikh putej posle smoke-check                                         | 11,635 s     | neuspeshno |
| [korenj] Regressiya instrumenta posle ustraneniya markerov putej                                         | 29,107 s     | uspeshno   |
| [korenj] Povtornaya proverka mashinno-lokaljnyikh putej                                                    | 11,721 s     | neuspeshno |
| [korenj] Povtornaya lokalizaciya mashinno-lokaljnyikh putej                                                 | 11,79 s      | neuspeshno |
| [korenj] Regressiya instrumenta posle kanonizacii markerov putej                                        | 28,987 s     | uspeshno   |
| [korenj] Povtornaya proverka mashinno-lokaljnyikh putej posle ispravleniya                                  | 11,861 s     | uspeshno   |
| [korenj] Itogovaya kompleksnaya proverka repozitoriya posle ustraneniya putej                              | 1630,391 s   | neuspeshno |
| [korenj] Proverka svyaznosti posle perekhoda kalendarnoj oporyi Obsidian                                  | 21,949 s     | uspeshno   |
| [korenj] Itogovaya uspeshnaya kompleksnaya proverka repozitoriya                                            | 1637,789 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 5694,374 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Poslednij polnyij nabor novogo instrumenta prokhodit 12 integracionnyikh scenariyev: determinirovannyij plan, zakryityij simptom, odnorazovaya host-granica, UUIDv7 zadach, razdeljnyiye sozdatelj i ispolnitelj, gryazj, drejf `HEAD`, zakryitaya skhema repair-ref, otbrasyivaniye povrezhdyonnogo podtverzhdeniya kommita, tochnaya terminalizaciya i bezopasnoye zakryitiye posle perezapisi `last_completion`.
- Nabor snimka i renderer prokhodit 24 testa, vklyuchaya obyazateljnuyu polnotu host-readback i prompt-only exact diff; polnyij regressionnyij nabor sleduyusjhego shaga vetki prokhodit 158 testov.
- TDD-red-zapuski v upravlyayemom bloke yavlyayutsya ozhidayemyimi dokazateljstvami prezhnego povedeniya. Odin rannij green-zapusk vyiyavil netochnyiye ozhidaniya teksta i byil ispravlen povtorom; otdeljnyij vyizov s nepodderzhivayemyim regulyarnyim vyirazheniyem `-k` ne nashyol testov, posle chego tot zhe kontur byil vyipolnen polnyim naborom.
- Pervyiye dva smyislovyikh sravneniya inventarya obnaruzhili razlichiye sostavnoj i razlozhennoj Unicode-formyi putej Git-arkhiva i rabochej fajlovoj sistemyi. Sravneniye posle NFC-normalizacii dokazalo 0 dobavlennyikh i 0 udalyonnyikh latinskikh sobstvennyikh obyyavlenij; pozicionnyij snimok obnovlyon i strogaya proverka prinyala 43 335 zapisej.
- Upravlyayemaya granica zakryivayetsya toljko posle togo, kak yeyo poslednej strokoj stanet fakticheskij predfinaljnyij polnyij smoke-check. Do etogo otkryityij blok ne yavlyayetsya svideteljstvom obsjhej priyomki; posle uspekha smoke snimok zapuskov zakryivayetsya, a zamyikayusjhiye proverki zakryitogo otchyota, svyaznosti, recency i probeljnoj chistotyi ne dobavlyayutsya v samossyilochnuyu chislovuyu granicu.

## Resheniya i ogranicheniya

- Pochinka ne vklyuchena v heartbeat i obsjhij reyestr zadanij: rannyaya polomka transporta ili `list_threads` sdelala byi vstroyennyij marshrut nedostizhimyim vmeste s remontiruyemyim konturom.
- V `create_thread.prompt` peredayotsya toljko polnoye pole `промпт` rezuljtata `план`; `публичный_промпт` susjhestvuyet dlya vosproizvodimogo khyesha i ne soderzhit znachenij, neobkhodimyikh rebyonku dlya `bind-run` i `verify-run`.
- Posle vozmozhnogo vneshnego effekta net avtomaticheskogo povtora, TTL ili ruchnogo udaleniya Git-ssyilki. Dazhe dokazannoye nesozdaniye poka trebuyet otdeljnogo versionirovannogo rasshireniya host-dokazateljstva; tekusjhij kontrakt predpochitayet ostanovku risku dublikata.
- Polnaya priyomka realjnoj pochinki tryokhurovnevaya: adresnyij TDD-red/green i polnyij nabor zatronutogo instrumenta; primenimyiye repozitornyiye proverki i polnyij smoke-check; yedinyij zhivoj urovenj iz tochnogo readback, prokhozhdeniya rannego gate i polnogo idle-marshruta posle ukhoda roditelya i rebyonka. `queue_busy` vo vremya vladeniya remontnoj zadachi podtverzhdayet lishj promezhutochnuyu chastj zhivogo urovnya.
- Perezapisannyij `last_completion` ne pozvolyayet vosstanovitj tochnyij kommit zadnim chislom. Instrument lishj dokazyivayet, chto prezhnij ispolnitelj boljshe ne sposoben pisatj cherez FIFO, i zakryivayet popyitku kak `неподтверждён`; dazhe iskhod `коммит_подтверждён` ne yavlyayetsya zayavleniyem o vosstanovlenii bez otdeljnogo zhivogo nablyudeniya.
- Sessiya izmenyayet toljko lokaljnyij repozitorij. Zhivaya avtomatizaciya, vneshniye zadachi i Git-publikaciya ne izmenyalisj; lokaljnyij commit+handoff ne svyazan s `push`.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [poslednyaya pochinka tochnoj host-skhemyi](../2026-08-05_21-02-54_MSK_ispravitj-avtozapusk/otchyot.md)
- [vosstanovleniye povtornogo avtozapuska posle otkata](../2026-08-01_09-16-33_MSK_ispravitj-povtornyij-avtozapusk-posle-otkata/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 02:20:51 MSK -->
<!-- content-sha256: sha256:a92500872fc92c86597bff9ef26bbfcca33850dbe36519d14192c25a12f894c6 -->
<!-- FUM-MD-RECENCY:END -->
