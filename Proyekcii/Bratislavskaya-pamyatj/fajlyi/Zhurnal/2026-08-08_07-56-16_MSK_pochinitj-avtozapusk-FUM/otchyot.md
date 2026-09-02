# Otchyot 2026-08-08 07:56:16 MSK - Pochinitj avtozapusk FUM

Diagnostika lokalizovala nezapusk ne v raspisanii, renderer ili zhivom prompt, a na styike obsjhej rezervacii dispetchera i kartochochnogo recovery posle shtatnogo FIFO-sbrosa. Sbros uzhe dokazal neaktivnostj prezhnego ispolnitelya i udaleniye specializirovannogo claim, no prezhnyaya obsjhaya rezervaciya byila terminalizirovana kak `завершён/неопределённый`; obsjhij predikat zamenyi ne otlichal eto vosstanovlennoye sostoyaniye ot obyichnoj host-neopredelyonnosti i ostanavlival novuyu idle-occurrence do kartochochnogo claim.

Dobavlena uzkaya fail-closed-vetvj: toljko novaya occurrence exact-adaptera sleduyusjhego shaga s otlichayusjhimsya `run_key` mozhet zamenitj takuyu rezervaciyu po pobajtovo vosproizvedyonnoj predterminaljnoj forme, exact reset-kvitancii, annulirovannomu i neaktivnomu ispolnitelyu, tochnomu udalyayemomu claim-ograzhdeniyu i atomarno podtverzhdyonnomu otsutstviyu claim-ssyilki. Do obsjhego `bind-run` ispolnitelya razresheno sopostavitj toljko po soglasovannomu tochnomu `threadId`; predvariteljnyij `clientThreadId` ne prinimayetsya. Inoj adapter, obyichnaya host-neopredelyonnostj, povtor togo zhe nastupleniya, nepolnaya kvitanciya i vernuvshijsya staryij claim ostayutsya zablokirovanyi. Kanonicheskij prompt zhivoj avtomatizacii uzhe sovpadal s renderer, poetomu host-konfiguraciya ne izmenyalasj.

## Diagnostika po sloyam

### 1. Raspisaniye i istoriya tikov

Najdena rovno odna susjhestvuyusjhaya heartbeat-avtomatizaciya po proveryayemoj sovokupnosti priznakov. Ona aktivna, imeyet pyatiminutnoye raspisaniye i prezhnyuyu versiyu konfiguracii. Istoriya poslednikh tikov pokazala posledovateljnostj: uspeshnyij shtatnyij sbros, vosstanoviteljnaya terminalizaciya prezhnego zapuska po kvitancii, zatem otkaz novoj obsjhej rezervacii kak zanyatoj. Boleye pozdnij tik vo vremya tekusjhego FIFO-vladeniya zavershilsya na `queue_busy`; eto podtverzhdayet toljko rannij gate i ne yavlyayetsya zhivoj priyomkoj ispravleniya.

### 2. FIFO i Git-sostoyaniye

Do remonta podtverzhdenyi tekusjhaya lokaljnaya imenovannaya vetka, tochnaya iskhodnaya vershina, pustoj indeks i chistaya rabochaya kopiya. Remontnaya zadacha voshla v FIFO pervyim instrumentaljnyim dejstviyem, dozhdalasj dopuska i uspeshno proshla zakryityiye `bind-run` i `verify-run`. Posle dopuska vse izmeneniya vyipolnyalisj toljko pod sobstvennyim pokoleniyem ocheredi; vetka i istoriya do finaljnoj peredachi ne dvigalisj.

### 3. Reyestr i vetochnyij vyibor

Obsjhij reyestr skhemyi `1` proshyol lokaljnyij `validate`: odno aktivnoye zadaniye obsjhego marshruta, soglasovannyiye pokoleniye i adapter. Specializirovannyij `validate` takzhe proshyol, a `show` vyibral gotovyij shag iz kanonicheskikh kartochek. Gipoteticheskoye nablyudeniye svobodnoj ocheredi dalo novuyu vershinu vyibora, novoye nastupleniye i novyij klyuch zapuska, poetomu povtor prezhnej occurrence isklyuchyon.

### 4. Obsjhaya rezervaciya i kartochochnyij claim

Obsjhaya rezervaciya imela fazu `завершён` i iskhod `неопределённый`, sokhranyaya svyazj s prezhnim FIFO-ispolnitelem. Specializirovannyij claim uzhe otsutstvoval. Neizmenyayemaya kvitanciya svyazyivala prezhnij reservation-ref/OID, annulirovannoye i neaktivnoye mnozhestva i tochnoye udalyayemoye ograzhdeniye claim. Staryij kontrakt obsjhej rezervacii razreshal zamenu lishj posle bezopasnogo otkaza do effekta libo uspekha drugoj occurrence, poetomu dokazannoye reset-recovery ne imelo puti k novomu zapusku.

### 5. Renderer i zhivoj prompt

Polnyij rezuljtat renderer pobajtovo sovpal s polnyim snapshot zhivogo prompt: odinakovaya dlina i odin SHA-256. Sovpadeniye proveryalosj po syiryim bajtam, a ne po fragmentu ili normalizovannomu tekstu. Obnovleniye avtomatizacii ne potrebovalosj; yeyo konfiguraciya i sluzhebnyiye metadata ostalisj bez izmenenij.

### 6. Host-transport i zakryitaya skhema zadach

Fakticheskij vlozhennyij host-vyizov vernul strokovyij transport, kotoryij byil razobran kak polnyij JSON rovno odin raz. Prinyat tochnyij profilj skhemyi `4` s shestjyu verkhneurovnevyimi polyami `schemaVersion`, `untrustedDataNotice`, `pinnedThreads`, `threads`, `unavailableHosts` i `unavailableSources`; oba massiva zadach obyyedinenyi, nedostupnyiye istochniki otsutstvovali, unikaljnostj zapisej sokhranena. Sobstvennaya prikreplyonnaya zadacha korrektno prinimayetsya v `idle` ili `notLoaded`, a ne obyazana vyiglyadetj `active`. Neizvestnyiye polya, wrapper, rekursivnyij razbor, Markdown, prefiks i suffiks po-prezhnemu ne prinimayutsya.

## Ispravleniye

Dobavlena minimaljnaya obezlichennaya JSON-fikstura nablyudyonnogo sostoyaniya s tochnyimi tipami, polyami, vlozhennostjyu, opcionaljnostjyu i otnosheniyami unikaljnosti. Realjnyiye host-identifikatoryi i lokaljnyiye puti v neyo ne perenesenyi.

Dispetcher teperj vosproizvodit bez zapisi obe dopustimyiye predterminaljnyiye formyi — `задача_создана` i `вызов_мог_состояться` — i isjhet ikh tochnyij Git-obyyekt v proverennoj reset-kvitancii. Dopusk ogranichen exact-adapterom sleduyusjhego shaga i trebuyet prezhnego ispolnitelya odnovremenno v annulirovannom i neaktivnom mnozhestvakh, rovno odno ograzhdeniye ozhidayemogo kartochochnogo claim s dejstviyem `удалить` i novyij `run_key`. Svyazannyij `task_id` ostayotsya osnovnoj identichnostjyu; do yego privyazki prinimayetsya toljko exact-para `threadId`/`hostId` s sovpavshim `идентификатор_созданной_задачи`. Otsutstviye claim proveryayetsya v toj zhe `update-ref`-tranzakcii, chto i zamena obsjhej rezervacii, s proverkami vetki, FIFO-sbrosa i epokhi rezervacij. Nevosproizvodimaya terminaljnaya forma, inoj adapter, predvariteljnyij `clientThreadId` i povtor togo zhe nastupleniya vozvrasjhayut shtatnoye `уже_зарезервировано`, a ne vnutrennyuyu oshibku kontrakta.

Regressionnaya matrica otdeljno zakreplyayet poteryannyij otvet claim, sobstvennyij `idle`/`notLoaded`, obyyedineniye zakreplyonnyikh i nedavnikh zadach, mezhtikovuyu izolyaciyu, posledstviya `Stop`/`Start`, obyyekt protiv stroki s odnokratnyim JSON-razborom, vlozhennuyu host-granicu, drejf versii i tochnyikh polej, proyekciyu svobodnoj ocheredi, tochnuyu zadachu do `bind-run`, zapret predvariteljnogo `clientThreadId` i inogo adaptera, povtor togo zhe nastupleniya, staryij claim posle otkata i soglasovannostj obsjhego i kartochochnogo fence.

Dva posledovateljnyikh polnyikh progona vyiyavili ne produktovyij otkaz, a slishkom korotkiye watchdog testovoj obvyazki: obyichnyiye Git-komandyi raznyikh naborov odin raz prevyisili sootvetstvenno pyatj i desyatj sekund pod dliteljnoj nagruzkoj, posle chego obe proverki otdeljno zavershilisj byistro i uspeshno. Obyichnyij watchdog adaptera uvelichen do 30 sekund, FIFO — do 60 sekund, to yestj strogo vyishe vnutrennego 30-sekundnogo Git-limita ocheredi. Specialjnyiye vremennyiye argumentyi testiruyemyikh komand ne menyalisj; konkurentnyiye watchdog takzhe ostayutsya konechnyimi, a dva byistryikh invarianta zapresjhayut snova opustitj vneshnyuyu granicu nizhe vnutrennego Git-limita.

## Plan vosstanovleniya posle poteri svyazi

Prodolzheniye uzhe sozdannoj ispolniteljskoj zadachi zaplanirovano kak post-bind-podprotokol susjhestvuyusjhego dispetchera, a ne kak vtoroj heartbeat ili kornevoye sozdaniye host-privyazki. Pered novyim vyiborom on dolzhen svyazatj tochnuyu neterminaljnuyu obsjhuyu rezervaciyu s prezhnimi host-zadachej, FIFO-vladeniyem, `HEAD` i adapternyim fence i poluchitj polozhiteljnyij host-fakt `disconnected`/`resumable` s otsutstviyem aktivnogo khoda i ozhidaniya poljzovatelya. Dostupnaya poverkhnostj poka ne dayot etu sovokupnostj, poetomu marshrut ostayotsya zablokirovannyim: `idle`, `notLoaded`, otsutstviye v ogranichennom recent-snimke i oshibka transporta sami po sebe ne dokazyivayut setevoj sboj. Pered soobsjheniyem sokhranyayutsya faza vozmozhnogo host-vyizova, nomer, predel i zaderzhka popyitki; poteryannyij otvet ne razreshayet resend bez dokazannoj nedostavki ili host-deduplikacii ustojchivyim klyuchom.

[FUM-STEP-0142](../../Planirovaniye/kartochki-shagov/🗑️-FUM-STEP-0142-dobavitj-ograzhdyonnoye-vozobnovleniye-zadach-posle-poteri-svyazi.md) zakreplyayet tochnyiye ograzhdeniya, ogranichennuyu politiku popyitok, zapret vtorogo ispolnitelya i povtora vneshnego effekta, avtonomnuyu TDD-matricu i zhivuyu priyomku razryiva i vosstanovleniya seti. Pervaya realizaciya ogranichivayetsya exact-adapterom sleduyusjhego shaga; ostaljnyiye adapteryi ostayutsya fail-closed do sobstvennoj recovery-politiki.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                                       |
| ------------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | Dopusk podtverzhdyon, no otdeljnyiye monotonnyiye metki nachala i konca ozhidaniya ne sokhranyalisj.                        |
| Soderzhateljnaya rabota    | ne izmereno  | Analiz, pravka i dokumentirovaniye perekryivalisj s read-only-probami; otdeljnyij nepreryivnyij tajmer ne zapuskalsya. |
| Celevyiye proverki         | po zhurnalu   | Tochnyiye dliteljnosti kazhdogo pryamogo zapuska izmerenyi monotonnyimi chasami v upravlyayemom bloke nizhe.                |
| Polnyij smoke-check       | 1831,854 s   | Poslednij zaregistrirovannyij zapusk proshyol vse `76/76` shagov; dliteljnostj izmerena vneshnej monotonnoj obyortkoj. |
| Atomarnyij commit+handoff | ne izmereno  | Vyipolnyayetsya posle zakryitiya otchyota odnoj queue-komandoj, poetomu ne vkhodit v yego zakryityij snimok.                 |

Granica profilya: rabochaya sessiya nachinayetsya kanonicheskoj metkoj zaprosa; pryamyiye proverki izmeryayutsya otdeljno monotonnyimi chasami. Finaljnaya peredacha FIFO proiskhodit posle zakryitiya zhurnaljnogo snimka i ne pripisyivayetsya soderzhateljnoj stadii.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:1152ac0ade25f8e7ad4d4d5e2b62f1e1f349ce533b7d6987f76e0f1b799a0ebc -->

| Vyizov                                                                                            | Dliteljnostj | Rezuljtat               |
| ------------------------------------------------------------------------------------------------ | ------------ | ----------------------- |
| [kornevoj agent] Proverka obsjhego reyestra dispetchera                                              | 0,122 s      | uspeshno                 |
| [kornevoj agent] Proverka rabochego nabora sleduyusjhego shaga                                        | 0,777 s      | uspeshno                 |
| [kornevoj agent] Vyibor gotovogo sleduyusjhego shaga                                                  | 1,106 s      | uspeshno                 |
| [kornevoj agent] Diagnostika obsjhej rezervacii dispetchera                                         | 0,177 s      | neuspeshno               |
| [kornevoj agent] Diagnostika obsjhej rezervacii dispetchera posle ispravleniya komandyi               | 0,178 s      | uspeshno                 |
| [kornevoj agent] Diagnostika kartochochnogo claim posle sbrosa                                     | 1,273 s      | uspeshno                 |
| [kornevoj agent] Pobajtovoye sravneniye zhivogo prompt s renderer                                   | 0,133 s      | uspeshno                 |
| [kornevoj agent] Modelirovaniye idle-vyibora posle sbrosa                                          | 0,013 s      | neuspeshno               |
| [kornevoj agent] Modelirovaniye idle-vyibora posle ispravleniya komandyi                             | 0,306 s      | uspeshno                 |
| [kornevoj agent] TDD-red podtverzhdyonnogo sbrosa obsjhej rezervacii                                 | 3,665 s      | neuspeshno               |
| [kornevoj agent] TDD-green podtverzhdyonnogo sbrosa obsjhej rezervacii                               | 3,82 s       | uspeshno                 |
| [kornevoj agent] Otricateljnyij test neodnoznachnogo host-iskhoda bez kvitancii                     | 2,475 s      | uspeshno                 |
| [kornevoj agent] Polnyij nabor testov dispetchera avtomatizacij                                    | 53,152 s     | uspeshno                 |
| [kornevoj agent] Polnyij nabor testov sleduyusjhego shaga vetki                                       | 148,812 s    | uspeshno                 |
| [kornevoj agent] TDD-red: neodnoznachnyij host-iskhod bez zadachi ostayotsya zakryityim                  | 1,808 s      | neuspeshno               |
| [kornevoj agent] TDD-green: neodnoznachnyij host-iskhod bez zadachi ostayotsya zakryityim                | 1,834 s      | uspeshno                 |
| [kornevoj agent] TDD-red: obe predterminaljnyiye fazyi reset-recovery                               | 2,924 s      | neuspeshno               |
| [kornevoj agent] TDD-red: reset-kvitanciya bez claim-guard ostayotsya zakryitoj                      | 3,319 s      | neuspeshno               |
| [kornevoj agent] TDD-green: reset receipt, obe fazyi i kartochochnyij claim-fence                    | 10,775 s     | neuspeshno               |
| [kornevoj agent] TDD-green: reset receipt, obe fazyi i kartochochnyij claim-fence — povtor           | 11,138 s     | uspeshno                 |
| [kornevoj agent] Adresnyiye regressii sbrosa i neopredelyonnogo host-iskhoda                         | 16,966 s     | uspeshno                 |
| [kornevoj agent] Polnyij adresnyij nabor dispetchera avtomatizacij                                  | 67,037 s     | uspeshno                 |
| [kornevoj agent] Peresborka reyestra planirovaniya                                                 | 0,309 s      | uspeshno                 |
| [kornevoj agent] Proverka reyestra planirovaniya                                                   | 0,32 s       | uspeshno                 |
| [kornevoj agent] Obnovleniye svezhesti Markdown                                                    | 0,643 s      | uspeshno                 |
| [kornevoj agent] Peresborka svezhesti grafa Obsidian                                              | 0,355 s      | uspeshno                 |
| [kornevoj agent] Svyaznostj rabochej sessii pered kommitom                                         | 25,822 s     | neuspeshno               |
| [kornevoj agent] Svyaznostj rabochej sessii pered kommitom — povtor                                | 25,622 s     | uspeshno                 |
| [kornevoj agent] Adresnyiye regressii posle kirillicheskogo imenovaniya                              | 16,479 s     | uspeshno                 |
| [kornevoj agent] Adresnyiye regressii dokazannogo vosstanovleniya posle sbrosa                      | 18,512 s     | uspeshno                 |
| [kornevoj agent] Adresnaya regressiya obyichnogo neopredelyonnogo iskhoda sredyi                        | 1,944 s      | uspeshno                 |
| [kornevoj agent] Finaljnaya svyaznostj rabochej sessii pered smoke-check                            | 25,958 s     | uspeshno                 |
| [kornevoj agent] Polnyij smoke-check repozitoriya                                                  | 790,782 s    | prervano — SIGINT       |
| [kornevoj agent] TDD-red: oblastj adaptera i tochnaya zadacha do privyazki                           | 10,414 s     | neuspeshno               |
| [kornevoj agent] TDD-green: oblastj adaptera i tochnaya zadacha do privyazki                         | 8,563 s      | uspeshno                 |
| [kornevoj agent] Polnaya adresnaya matrica vosstanovleniya posle sbrosa                             | 28,276 s     | uspeshno                 |
| [kornevoj agent] Povtornaya regressiya obyichnogo neopredelyonnogo iskhoda sredyi                       | 1,84 s       | uspeshno                 |
| [kornevoj agent] Povtornaya peresborka reyestra planirovaniya                                       | 0,344 s      | uspeshno                 |
| [kornevoj agent] Povtornaya proverka reyestra planirovaniya                                         | 0,373 s      | uspeshno                 |
| [kornevoj agent] Svyaznostj sessii posle finaljnyikh zasjhitnyikh pravok                                | 26,495 s     | uspeshno                 |
| [kornevoj agent] Polnyij smoke-check repozitoriya posle zasjhitnyikh pravok                            | 295,602 s    | prervano — SIGINT       |
| [kornevoj agent] Svyaznostj posle ustraneniya protivorechiya kontrakta                               | 26,704 s     | uspeshno                 |
| [kornevoj agent] Itogovyij polnyij smoke-check repozitoriya                                         | 1800,02 s    | ne zaversheno — tajm-aut |
| [kornevoj agent] Peresborka reyestra posle planirovaniya vosstanovleniya svyazi                      | 0,344 s      | uspeshno                 |
| [kornevoj agent] Proverka reyestra posle planirovaniya vosstanovleniya svyazi                        | 0,329 s      | uspeshno                 |
| [kornevoj agent] Obnovleniye svezhesti posle planirovaniya vosstanovleniya svyazi                     | 0,67 s       | neuspeshno               |
| [kornevoj agent] Peresborka grafa posle planirovaniya vosstanovleniya svyazi                        | 0,398 s      | uspeshno                 |
| [kornevoj agent] Povtornoye obnovleniye svezhesti posle planirovaniya vosstanovleniya svyazi           | 0,656 s      | uspeshno                 |
| [kornevoj agent] Proverka svezhesti posle planirovaniya vosstanovleniya svyazi                       | 0,615 s      | uspeshno                 |
| [kornevoj agent] Povtornaya peresborka grafa posle planirovaniya vosstanovleniya svyazi              | 0,394 s      | uspeshno                 |
| [kornevoj agent] Finaljnaya peresborka reyestra plana vosstanovleniya svyazi                         | 0,345 s      | uspeshno                 |
| [kornevoj agent] Finaljnaya proverka reyestra plana vosstanovleniya svyazi                           | 0,344 s      | uspeshno                 |
| [kornevoj agent] Finaljnoye obnovleniye svezhesti plana vosstanovleniya svyazi                        | 0,836 s      | uspeshno                 |
| [kornevoj agent] Finaljnaya peresborka grafa plana vosstanovleniya svyazi                           | 0,558 s      | uspeshno                 |
| [kornevoj agent] Svyaznostj sessii s planom vosstanovleniya svyazi                                  | 37,14 s      | neuspeshno               |
| [kornevoj agent] Obnovleniye svezhesti posle utochneniya inventarya                                   | 0,755 s      | uspeshno                 |
| [kornevoj agent] Peresborka grafa posle utochneniya inventarya                                      | 0,391 s      | uspeshno                 |
| [kornevoj agent] Povtornaya svyaznostj sessii s planom vosstanovleniya svyazi                        | 36,868 s     | uspeshno                 |
| [kornevoj agent] Itogovyij polnyij smoke-check repozitoriya posle planirovaniya vosstanovleniya svyazi | 513,243 s    | neuspeshno               |
| [kornevoj agent] Peresborka reyestra posle vosstanovleniya aktivnoj kartochki                       | 0,399 s      | uspeshno                 |
| [kornevoj agent] Proverka reyestra posle vosstanovleniya aktivnoj kartochki                         | 0,341 s      | uspeshno                 |
| [kornevoj agent] Obnovleniye svezhesti posle vosstanovleniya aktivnoj kartochki                      | 0,649 s      | uspeshno                 |
| [kornevoj agent] Peresborka grafa posle vosstanovleniya aktivnoj kartochki                         | 0,35 s       | uspeshno                 |
| [kornevoj agent] Povtor polnogo nabora sleduyusjhego shaga posle vosstanovleniya kartochki             | 153,891 s    | uspeshno                 |
| [kornevoj agent] Svyaznostj pered povtornyim itogovyim smoke-check                                  | 28,953 s     | uspeshno                 |
| [kornevoj agent] Finaljnyij polnyij smoke-check posle ustraneniya planovogo konflikta               | 777,176 s    | neuspeshno               |
| [kornevoj agent] Povtor upavshego idempotent join FIFO-testa                                      | 0,723 s      | uspeshno                 |
| [kornevoj agent] Adresnyiye atomarnyiye testyi watchdog sleduyusjhego shaga                               | 11,849 s     | uspeshno                 |
| [kornevoj agent] Adresnyij povtor idempotent join posle pravki watchdog                           | 0,767 s      | uspeshno                 |
| [kornevoj agent] Adresnyiye dolgozhivusjhiye ozhidaniya FIFO posle pravki watchdog                       | 6,627 s      | uspeshno                 |
| [kornevoj agent] Invariantyi vneshnikh watchdog nad Git-limitami                                    | 0,398 s      | uspeshno                 |
| [kornevoj agent] Obnovleniye svezhesti posle pravki watchdog                                       | 0,66 s       | uspeshno                 |
| [kornevoj agent] Peresborka grafa posle pravki watchdog                                          | 0,394 s      | uspeshno                 |
| [kornevoj agent] Svyaznostj pered smoke-check s ustojchivyimi watchdog                              | 26,213 s     | uspeshno                 |
| [kornevoj agent] Itogovyij polnyij smoke-check s ustojchivyimi watchdog                              | 40,791 s     | neuspeshno               |
| [kornevoj agent] Povtor proverki ostatka obyyavlenij posle watchdog                               | 4,518 s      | neuspeshno               |
| [kornevoj agent] Proverka ostatka obyyavlenij posle pozicionno nejtraljnoj pravki                 | 4,594 s      | neuspeshno               |
| [kornevoj agent] Zelyonaya proverka ostatka obyyavlenij posle watchdog                              | 4,436 s      | uspeshno                 |
| [kornevoj agent] Finaljnyiye invariantyi watchdog nad Git-limitami                                  | 0,278 s      | uspeshno                 |
| [kornevoj agent] Finaljnyiye atomarnyiye testyi watchdog sleduyusjhego shaga                              | 11,621 s     | uspeshno                 |
| [kornevoj agent] Obnovleniye svezhesti pered itogovyim smoke-check                                  | 0,632 s      | uspeshno                 |
| [kornevoj agent] Peresborka grafa pered itogovyim smoke-check                                     | 0,349 s      | uspeshno                 |
| [kornevoj agent] Svyaznostj rabochej sessii pered itogovyim smoke-check                             | 25,889 s     | uspeshno                 |
| [kornevoj agent] Itogovyij polnyij smoke-check posle stabilizacii watchdog                         | 1831,854 s   | uspeshno                 |

Obsjheye vremya pryamyikh zapuskov proverok: 6965,425 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- TDD-red vosproizvyol nablyudyonnyij otkaz: novaya occurrence posle polnoj reset-kvitancii ostavalasj zanyatoj. Otdeljnyiye krasnyiye sluchai zakrepili vtoruyu dopustimuyu predterminaljnuyu fazu, oshibochnyij dopusk kvitancii bez claim-ograzhdeniya i vnutrennyuyu oshibku dlya obyichnoj host-neopredelyonnosti bez sozdannoj zadachi.
- TDD-green propustil obe predterminaljnyiye fazyi toljko dlya novoj occurrence exact-adaptera, vklyuchaya tochnuyu sozdannuyu zadachu do `bind-run`, i ostavil zakryityimi inoj adapter, predvariteljnyij `clientThreadId`, povtor togo zhe nastupleniya, kvitanciyu bez claim-ograzhdeniya, vernuvshijsya staryij claim i obyichnyij neodnoznachnyij host-iskhod.
- Itogovyij smoke-check proshyol vse `76/76` shagov. Vnutri nego uspeshno zavershilisj polnyij nabor dispetchera iz `82` testov, polnyij nabor specializirovannogo vyibora sleduyusjhego shaga iz `164` testov i polnyij FIFO-nabor iz `102` testov.
- Reyestr obsjhego dispetchera i specializirovannyij vyibor proshli `validate`; `show` podtverdil novyij gotovyij vyibor pri svobodnoj proyekcii ocheredi.
- Renderer i zhivoj prompt sovpali pobajtovo; tochnyij readback podtverdil yedinstvennuyu aktivnuyu zapisj, poetomu host-obnovleniye ne vyipolnyalosj.
- Pervyij polnyij smoke-check byil prervan srazu posle podtverzhdeniya dvukh dopolniteljnyikh defektov proveryayemogo snimka: slishkom shirokoj oblasti adaptera i otsutstvuyusjhego tochnogo sopostavleniya sozdannoj zadachi do `bind-run`. Taktika nemedlennogo preryivaniya zavedomo nepriyomochnogo dolgogo progona zakreplena v obsjhikh pravilakh i kontrakte smoke-check; priyomochnyim mozhet byitj toljko posleduyusjhij polnyij uspeshnyij zapusk.
- Pervyij neprervannyij progon ne obnaruzhil testovogo defekta, no obyortka ostanovila posledovateljnyij nabor na obsjhem 30-minutnom limite posle vsekh uzhe zafiksirovannyikh uspeshnyikh etapov. Eto ne prinyato kak smoke-uspekh: posle vklyucheniya planovogo diff zapuskayetsya novyij polnyij nabor s dostatochnyim limitom.
- Posleduyusjhiye progonyi ostanovilisj na dvukh raznyikh korotkikh subprocess-watchdog; oba upavshikh testa otdeljno proshli, a vtoroj sluchaj podtverdil, chto vneshnij desyatisekundnyij limit byil koroche shtatnoj fail-closed-granicyi FIFO. Posle uvelicheniya toljko obyichnyikh watchdog adresnyiye regressii i itogovyij polnyij smoke-check proshli; vse promezhutochnyiye neuspeshnyiye i prervannyiye zapuski sokhranenyi v mashinnom zhurnale.
- Repozitornyiye generatoryi i svyaznostj proshli pered itogovyim zapuskom. Poslednij zaregistrirovannyij smoke-check zavershilsya uspeshno za `1831,854` sekundyi vneshnego vremeni i podtverdil polnyij plan `76/76`.

## Resheniya i ogranicheniya

- Razresheniye novoj rezervacii osnovano na sostoyanii, dokazannom neizmenyayemoj kvitanciyej i tekusjhej atomarnoj proverkoj claim, a ne na doverii svobodnomu CLI-flagu ili odnomu terminaljnomu iskhodu.
- Susjhestvuyusjhaya avtomatizaciya ne sozdavalasj, ne udalyalasj, ne zamenyalasj i ne obnovlyalasj: zhivoj prompt uzhe kanonichen. Status `ACTIVE`, raspisaniye i vse sokhranyayemyiye metadata ostavlenyi bez izmenenij.
- Rannij zhivoj `queue_busy` ozhidayem vo vremya vladeniya remontnoj zadachej i podtverzhdayet toljko rannij gate. Polnyij idle-marshrut posle ukhoda obeikh zadach dolzhen nablyudatj posleduyusjhij upravlyayusjhij khod; do etogo avtozapusk ne obyyavlyayetsya vosstanovlennyim, a [FUM-SBOJ-0013](../../Sboi/FUM-SBOJ-0013-blokirovka-avtozapuska-posle-podtverzhdyonnogo-FIFO-sbrosa.md) ostayotsya aktivnoj.
- Remont ne dobavlyalsya v heartbeat ili obsjhij reyestr zadanij. Novaya zadacha ne sozdavalasj, publikaciya i push ne vyipolnyayutsya, sobstvennaya remontnaya rezervaciya posle peredachi ne terminaliziruyetsya etoj zadachej.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:210be9c7754cc5b65b40866678242cb3b3e3e4a6532478af6f7b149ffbc13031 -->
<!-- FUM-MD-RECENCY:END -->
