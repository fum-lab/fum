+++
schema_version = 1
card_id = "FUM-STEP-0122"
status = "completed"
+++
# Dobavitj kornevoj reyestr zapuskov i vosstanovleniye host-privyazok

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj sokhranyayemyij kornevoj reyestr host-privyazok dlya nachaljnogo profilya odnogo ekzemplyara Codex Desktop bez dochernikh dispetcherov. On dolzhen materializovatj i proveryatj otdeljnyij zhivoj klon dlya kazhdoj ispolnyayemoj vetki, globaljno svyazyivatj [vetvevoj fork FUM](../../Glossarij/vetvevoj-fork-FUM.md) s odnim pokoleniyem, odnoj paroj repozitoriya i rabochego ref i odnim pishusjhim checkout, svyazyivatj yedinstvennuyu popyitku sozdaniya i fakticheskuyu Desktop-zadachu s sobstvennyim `CODEX_THREAD_ID`, tochnyimi naznacheniyem, roljyu i fork, a posle pervogo zapuska peredavatj prodolzheniye samoj vetke cherez yeyo FIFO i obyazateljnyij `commit+handoff`. Dlya dvoichnoj razvilki reyestr gotovit obe privyazki v globaljnom predaktivacionnom sostoyanii i aktiviruyet pokoleniye toljko posle tochnogo podtverzhdeniya paryi.

## Rezuljtat

Proveryayemyij mnogoagentnyij kontur poluchil sokhranyayemyij lokaljnyij reyestr nachaljnyikh zapuskov. On atomarno khranit pokoleniya pod mezhprocessnoj blokirovkoj, navsegda rezerviruyet fork, paru repozitoriya i polnogo ref, popyitku, fizicheskij istochnik i zhivoj checkout, a dlya kazhdoj storonyi materializuyet otdeljnyij standalone Git-klon ot tochnoj obsjhej vershinyi. Mashinno-lokaljnyiye puti ostayutsya toljko v reyestre; perenosimyij pasport soderzhit neprozrachnyiye fizicheskiye identichnosti.

Polnyij konvert host-vyizova i yego SHA-256 vyichislyayutsya samim reyestrom. Dolgovechnoye namereniye zapisyivayetsya do effekta, poetomu padeniye posle nego, poteryannyij libo nepolnyij otvet blokiruyut obe storonyi bez povtora. Vosstanovleniye samo chitayet tochnuyu prezhnyuyu popyitku cherez adapter sredyi i prinimayet toljko odin polnostjyu sovpavshij rezuljtat. `threadId`, `hostId`, `CODEX_THREAD_ID` i neaktivnyij bilet sveryayutsya so vsem naznacheniyem, roljyu, rebyonkom, fork, repozitoriyem, ref, checkout, bazoj, popyitkoj, shagom i proyektom.

Do host-vyizova v novom checkout ustanavlivayetsya nesvyazannyij barjyer toljko s vetkoj, bazoj, fork, pokoleniyem i kliyentskoj popyitkoj. Posle tochnogo otveta otdeljnyij Git CAS dobavlyayet `threadId`, `hostId`, khyesh polnogo konverta i pereschitannyij khyesh privyazki, no ne otkryivayet FIFO. Posle podtverzhdeniya oboikh detej reyestr zamorazhivayet snimok i povtorno proveryayet oba klona. Odin CAS vyidayot obsjhuyu kvitanciyu, dva khyesha privyazok i kornevoye dokazateljstvo ikh obsjhej aktivacii. Toljko zatem tochnoye idempotentnoye otkryitiye po Git CAS-osnove dopuskayet prezhnij unarnyij protokol prodolzhenij vetki; pervyij `join` odnovremenno sveryayet obyyekt barjyera, polnyij ref i aktivirovannuyu bazovuyu vershinu. Pereklyucheniye symbolic `HEAD` togo zhe checkout ograzhdeniye ne obkhodit. Avtonomnyiye Swift- i Python-fiksturyi pokryivayut polozhiteljnyij marshrut i otkaznyiye granicyi bez seti, modeli, vneshnikh repozitoriyev ili planirovsjhika resursov.

## Granica rezuljtata

Poddeljnaya host-sreda vosproizvodimo modeliruyet avtoritetnoye chteniye popyitki, no ne yavlyayetsya fakticheskim Codex Desktop API. Pri nedostupnoj identichnosti kontrollera reyestr chestno ne dokazyivayet yedinstvennostj fizicheskogo ekzemplyara Desktop. Realjnyiye fork-agentyi, zhivyiye host-vyizovyi, publikaciya dochernikh diapazonov, moderaciya i integraciya ostayutsya posleduyusjhimi kartochkami; prezhnij dispetcher i heartbeat ne vozvrasjhenyi.

## Kriterii zaversheniya

- Kornevoj reyestr svyazyivayet naznacheniye, rolj, rebyonka, repozitorij, identichnostj fizicheskogo checkout, polnyij rabochij ref, kliyentskuyu popyitku, fakticheskuyu Desktop-zadachu, `CODEX_THREAD_ID` i pokoleniye zapuska; neizvestnaya ili dublirovannaya svyazj zakryivayet perekhod.
- Odin ustojchivyij fork svyazyivayetsya rovno s odnoj avtoritetnoj paroj repozitoriya i polnogo rabochego ref i odnim zhivyim checkout; para repozitoriya i ref navsegda rezerviruyetsya za nim v sokhranyayemom dereve, a odin zhivoj checkout ne mozhet prinadlezhatj raznyim pokoleniyam. Otdeljnyiye klonyi ne mogut odnovremenno obyyavitj odnu paru svoyej ili poluchitj dvukh dopusjhennyikh vladeljcev.
- Kazhdyij kontekstno posiljnyij shag poluchayet otdeljnuyu Desktop-zadachu i novyij `CODEX_THREAD_ID`; povtornoye ispoljzovaniye odnoj sessii dlya drugogo shaga ili pokoleniya naznacheniya zapresjheno.
- Zhivoj klon imeyet otdeljnyij Git common-dir i proveryayemoye sootvetstviye rebyonku, repozitoriyu, baze i rabochemu ref; mashinno-lokaljnyij putj ostayotsya toljko v lokaljnom reyestre i ne popadayet v perenosimyij pasport.
- Sozdaniye vyipolnyayetsya rovno odin raz i prinimayet toljko tochnuyu paru `threadId` i `hostId`; poteryannyij ili neodnoznachnyij otvet perevodit privyazku v zakryitoye neizvestnoye sostoyaniye i zapresjhayet novyij vyizov sozdaniya. Prodolzheniye dopustimo lishj do zamorazhivaniya posle avtoritetnogo chteniya tochnoj prezhnej popyitki s sovpadayusjhim ograzhdeniyem libo cherez otdeljnoye yavno audiruyemoye chelovecheskoye vosstanovleniye; pozdnij readback ne menyayet kvitanciyu, a neizvestnostj ne osvobozhdayet resurs kak uspekh.
- Reyestr sokhranyayet ustojchivuyu identichnostj Desktop-kontrollera libo chestnyij priznak yeyo nedostupnosti. Vo vtorom sluchaye avtonomnaya i zhivaya priyomki dokazyivayut toljko otdeljnostj zadach, checkout i refs, no ne yedinstvennostj fizicheskogo ekzemplyara Desktop.
- Poteryannyij otvet sozdaniya, ostanovka do privyazki i povtor sverki ne sozdayut vtorogo ispolnitelya; posle tochnoj privyazki kazhdyij kommit dochernej vetki sozdayot sobstvennoye prodolzheniye, kotoroye posle dopuska neposredstvenno vyizyivayet selector etoj vetki.
- Dlya dvukh detej odnogo pokoleniya chastichnyij uspekh i neizvestnyij iskhod lyuboj popyitki sokhranyayutsya bez prava zapisi oboikh detej. Nesvyazannyij vetochnyij barjyer stavitsya do host-effekta, a exact-privyazka posle otveta vsyo yesjhyo ne sozdayot FIFO-bilet. Otkryitiye trebuyet proverennogo obsjhego iskhodnogo sostoyaniya, raznyikh par repozitoriya i ref, raznyikh checkout, dvukh tochnyikh podtverzhdyonnyikh host-privyazok i kornevogo dokazateljstva yedinogo CAS; pervyij vkhod atomarno sveryayet aktivirovannuyu bazovuyu vershinu.
- Avtonomnaya mezhpokolencheskaya fikstura otklonyayet povtor paryi repozitoriya i ref i povtor zhivogo checkout, dazhe yesli identifikatoryi pokolenij razlichayutsya.
- Avtonomnyij poddeljnyij host proveryayet kazhduyu granicu sboya bez seti, modeli, vneshnikh repozitoriyev ili planirovsjhika resursov.

## Istochniki

- [tekusjhij zapros 2026-08-13 03:21:13 MSK — Dobavitj kornevoj reyestr zapuskov i vosstanovleniye host-privyazok](../../Zhurnal/2026-08-13_03-21-13_MSK_dobavitj-kornevoj-reyestr-zapuskov-i-vosstanovleniye-host-privyazok/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0121 — vozobnovlyayemoye ispolneniye dochernej cepochki](✅-FUM-STEP-0121-realizovatj-vozobnovlyayemoye-ispolneniye-cepochki-v-universaljnom-fork-poduzle.md)
- [FUM-STEP-0145 — pasport dereva vetvevyikh fork](✅-FUM-STEP-0145-zakrepitj-pasport-dereva-vetvevyikh-fork-i-reshenij-moderatora.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-13 06:37:55 MSK -->
<!-- content-sha256: sha256:17a057e7039757ec03e9680159ff87c298f7faf127f327002b1ef4589b868863 -->
<!-- FUM-MD-RECENCY:END -->
