# Otchyot 2026-08-07 20:34:22 MSK - Dobavitj shtatnyij sbros ocheredi

Realizovan shtatnyij lokaljnyij protokol sbrosa FIFO-ocheredi i Git-rabochej kopii iz otdeljnogo poljzovateljskogo khoda postoyannoj zadachi dispetchera avtomatizacij FUM. Protokol zakreplyayet tochnyij imenovannyij `HEAD`, obyyekt ocheredi, svyazannyiye service guards, fiksirovannuyu epokhu dispetcherskikh rezervacij i preimage/target kazhdogo izmenyonnogo tracked-puti; blokiruyet obyichnyiye zapisi; trebuyet tochnogo host-dokazateljstva neaktivnosti ili ostanovki uchastnikov; zatem vosstanavlivayet indeks i tracked-derevo, udalyayet po odnomu toljko podtverzhdyonnyiye Git-vidimyiye neignoriruyemyiye obyichnyiye fajlyi i simvolicheskiye ssyilki i vyipuskayet pustuyu ocheredj. Specialjnyij untracked-tip, skryityiye index-flagi, izmenyonnyiye `.gitignore`/`.gitattributes`, vneshnij checkout-filter, target-kolliziya ignoriruyemogo puti i perekhod gitlink zakryivayut operaciyu do poteri dannyikh; vneshnij filter ne zapuskayetsya, vstroyennyiye checkout-preobrazovaniya vkhodyat v tochnyij target-otpechatok.

Sbros oformlen shestjyu komandami `план-сброса`, `подготовить-сброс`, `подтвердить-остановку-сессий`, `применить-сброс`, `отменить-сброс` i `состояние-сброса`. Do finala prervannuyu operaciyu vozobnovlyayet aktivnyij reset-record; finaljnaya Git-tranzakciya atomarno sozdayot samodostatochnuyu neizmenyayemuyu kvitanciyu s kanonicheskimi snimkami reset-record i itogovoj ocheredi, posle chego recovery sokhranyayetsya pri smene odnoslotovogo `last_completion`, povtornom sbrose i Git GC. Obyichnyiye perekhodyi FIFO, obsjhaya rezervaciya, kartochochnyij claim i management-fence fail-closed proveryayut aktivnyij reset; kazhdyij dejstviteljnyij perekhod rezervacii atomarno sdvigayet fiksirovannuyu epokhu i tem samyim zakryivayet gonku sozdaniya raneye otsutstvovavshej reservation-ref. Rezervaciya skhemyi `3` razlichayet exact `threadId`/`hostId` i predvariteljnyij `clientThreadId`, trebuyet sovpadeniya exact-svideteljstva s budusjhim `task_id` i bezopasno migriruyet prezhnyuyu skhemu toljko po neprotivorechivomu povtornomu podtverzhdeniyu.

Lokaljnaya chastj realizovana i avtonomno proverena, no trebovaniye ostavleno v statuse `🚧`: dostupnyij Codex-host ne predostavlyayet otdeljnuyu shtatnuyu ostanovku proizvoljnoj aktivnoj zadachi i polnyij checkout-scoped inventarj. Poetomu tekusjhij bezopasnyij marshrut otkazyivayet do `подготовить-сброс` pri `active`, unknown, nepolnom ili neodnoznachnom sostoyanii; `handoff` ne vyidayotsya za stop. Zhivaya priyomka ostanovki aktivnyikh pisatelej ostayotsya otkryitoj do poyavleniya takogo host-kontrakta.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj                      | Granicyi i sposob izmereniya                                                                 |
| ------------------------ | --------------------------------- | ------------------------------------------------------------------------------------------ |
| Ozhidaniye dopuska FIFO    | bez nablyudayemogo ozhidaniya         | Pervyij `join` srazu vernul `admitted`; otdeljnyij interval ozhidaniya ne voznik                |
| Soderzhateljnaya rabota    | kalendarnyij interval sessii       | Ot registracii 2026-08-07 do zakryitiya itogovogo snimka; vklyuchayet tri paralleljnyikh audita    |
| Celevyiye proverki         | mashinnaya summa v bloke nizhe       | Kazhdaya ispolnyayemaya proverka uchtena profiliruyusjhej obyortkoj                                   |
| Polnyij smoke-check       | itogovaya stroka upravlyayemogo bloka | Otdeljnyij polnyij kontur vyipolnyayetsya posle adresnyikh naborov                                  |
| Atomarnyij commit+handoff | vne chislovoj granicyi              | Vyipolnyayetsya posle zakryitiya snimka i sluzhebnyikh samossyilochnyikh proverok                        |

Granica profilya: nachalo — atomarnaya registraciya FIFO dlya tekusjhego `Codex-Thread-ID`; konec — rezuljtat poslednego polnogo smoke-check. Dliteljnosti pryamyikh proverok ne skladyivayutsya povtorno s kalendarnyim intervalom soderzhateljnoj rabotyi. Zakryitiye snimka, samossyilochnaya svyaznostj i commit+handoff vyipolnyayutsya posle mashinnoj summyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:828f0cfbc170faf74b88802ce1a51d8bd5f966ea229f9fc2782f1b7964f76898 -->

| Vyizov                                                                                    | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] TDD red: shtatnyij sbros FIFO-ocheredi                                     | 61,373 s     | neuspeshno |
| [kornevoj agent] TDD red: reset-fence dispetchera                                         | 1,443 s      | neuspeshno |
| [kornevoj agent] TDD red: reset-fence kartochochnogo claim                                 | 0,674 s      | neuspeshno |
| [kornevoj agent] TDD green attempt: shtatnyij sbros FIFO-ocheredi                           | 1,52 s       | neuspeshno |
| [kornevoj agent] Diagnostika podtverzhdeniya plana sbrosa                                  | 1,573 s      | neuspeshno |
| [kornevoj agent] TDD green attempt: state machine sbrosa FIFO                            | 10,361 s     | uspeshno   |
| [kornevoj agent] TDD green attempt: reset-fence dispetchera                               | 1,723 s      | uspeshno   |
| [kornevoj agent] TDD green: reset-fence kartochochnogo claim                               | 0,811 s      | uspeshno   |
| [kornevoj agent] TDD green: state machine sbrosa FIFO                                    | 10,192 s     | uspeshno   |
| [kornevoj agent] TDD: bezopasnyiye gonki shtatnogo sbrosa FIFO                              | 17,387 s     | uspeshno   |
| [kornevoj agent] Polnyij nabor dispetchera posle reset-fence                               | 32,063 s     | uspeshno   |
| [kornevoj agent] Polnyij nabor sleduyusjhego shaga posle reset-fence                          | 138,605 s    | uspeshno   |
| [kornevoj agent] TDD: polnyij bezopasnyij cikl shtatnogo sbrosa FIFO                        | 29,359 s     | neuspeshno |
| [kornevoj agent] TDD: povtor polnogo bezopasnogo cikla sbrosa FIFO                       | 30,883 s     | uspeshno   |
| [kornevoj agent] Polnaya regressiya FIFO-ocheredi so shtatnyim sbrosom                        | 94,971 s     | neuspeshno |
| [kornevoj agent] Regressiya tekstovogo kontrakta FIFO v AGENTS                            | 0,137 s      | neuspeshno |
| [kornevoj agent] Povtor regressii tekstovogo kontrakta FIFO                              | 0,145 s      | uspeshno   |
| [kornevoj agent] Integraciya sluzhebnyikh ograzhdenij finala sbrosa                           | 3,575 s      | uspeshno   |
| [kornevoj agent] TDD: reset-fence dlya pozdnikh release-perekhodov                          | 2,333 s      | uspeshno   |
| [kornevoj agent] krasnyij test obsjhej epokhi rezervacij dispetchera                          | 0,691 s      | neuspeshno |
| [kornevoj agent] krasnyij test ograzhdeniya epokhi novyikh rezervacij                          | 1,243 s      | neuspeshno |
| [kornevoj agent] sintaksis protokola epokhi rezervacij                                    | 0,12 s       | uspeshno   |
| [kornevoj agent] zelyonyij test obsjhej epokhi rezervacij dispetchera                          | 1,249 s      | uspeshno   |
| [kornevoj agent] zelyonyij test ograzhdeniya epokhi novyikh rezervacij                          | 1,315 s      | uspeshno   |
| [kornevoj agent] krasnyij test dolgovechnoj kvitancii sbrosa                               | 3,022 s      | neuspeshno |
| [kornevoj agent] sintaksis dolgovechnoj kvitancii sbrosa                                  | 0,074 s      | uspeshno   |
| [kornevoj agent] zelyonyij test dolgovechnoj kvitancii sbrosa                               | 3,323 s      | uspeshno   |
| [kornevoj agent] krasnyij test vosstanovleniya rezervacii po kvitancii sbrosa              | 2,218 s      | neuspeshno |
| [kornevoj agent] sintaksis vosstanovleniya po kvitancii sbrosa                            | 0,08 s       | uspeshno   |
| [kornevoj agent] zelyonyij test vosstanovleniya rezervacii po kvitancii sbrosa              | 2,399 s      | neuspeshno |
| [kornevoj agent] povtornyij zelyonyij test vosstanovleniya po kvitancii sbrosa               | 2,326 s      | neuspeshno |
| [kornevoj agent] tretij test vosstanovleniya po kvitancii sbrosa                          | 2,353 s      | neuspeshno |
| [kornevoj agent] zelyonyij test vosstanovleniya po kvitancii sbrosa posle ispravlenij       | 2,93 s       | uspeshno   |
| [kornevoj agent] test dolgovechnogo vosstanovleniya posle prodvizheniya vetki                | 2,859 s      | uspeshno   |
| [kornevoj agent] polnyij klass testov shtatnogo sbrosa FIFO                                | 37,214 s     | uspeshno   |
| [kornevoj agent] polnyij nabor testov dispetchera posle sbrosa                             | 44,931 s     | uspeshno   |
| [kornevoj agent] krasnyij-test-dolgovechnosti-kvitancii                                    | 3,299 s      | neuspeshno |
| [kornevoj agent] krasnyij-test-povtornyikh-kvitancij                                        | 2,911 s      | neuspeshno |
| [kornevoj agent] sintaksis-samodostatochnoj-kvitancii                                     | 0,15 s       | uspeshno   |
| [kornevoj agent] zelyonyij-test-dolgovechnosti-kvitancii                                    | 3,338 s      | uspeshno   |
| [kornevoj agent] zelyonyij-test-povtornyikh-kvitancij                                        | 3,192 s      | uspeshno   |
| [kornevoj agent] krasnyij-test-povtora-ochistki                                            | 2,5 s        | neuspeshno |
| [kornevoj agent] sintaksis-pofajlovyikh-otpechatkov-sbrosa                                  | 0,138 s      | uspeshno   |
| [kornevoj agent] zelyonyij-test-povtora-ochistki                                            | 2,378 s      | uspeshno   |
| [kornevoj agent] krasnyiye-testyi-host-granicyi-sbrosa                                       | 0,92 s       | neuspeshno |
| [kornevoj agent] krasnyij-test-threadId-pochinki                                           | 0,684 s      | neuspeshno |
| [kornevoj agent] sintaksis-host-ograzhdenij-sbrosa                                        | 0,151 s      | uspeshno   |
| [kornevoj agent] zelyonyiye-testyi-host-granicyi-sbrosa                                       | 1,435 s      | uspeshno   |
| [kornevoj agent] klass-testov-shtatnogo-sbrosa-posle-review                               | 34,48 s      | uspeshno   |
| [kornevoj agent] kvitancii-dispetchera-posle-skhemyi-otpechatkov                             | 2,728 s      | uspeshno   |
| [kornevoj agent] krasnyij-test-identichnosti-dispetchera                                    | 0,554 s      | neuspeshno |
| [kornevoj agent] zelyonyij-test-identichnosti-dispetchera                                    | 0,378 s      | uspeshno   |
| [kornevoj agent] krasnyiye-testyi-live-prompta-dispetchera                                   | 0,083 s      | neuspeshno |
| [kornevoj agent] zelyonyiye-testyi-live-prompta-dispetchera                                   | 0,119 s      | uspeshno   |
| [kornevoj agent] polnyij-nabor-testov-FIFO-posle-review                                   | 96,624 s     | uspeshno   |
| [kornevoj agent] Peresborka mashinnogo planovogo reyestra dlya FUM-REQ-0039 i FUM-STEP-0141 | 0,33 s       | uspeshno   |
| [kornevoj agent] Validaciya mashinnogo planovogo reyestra posle shtatnogo sbrosa             | 0,301 s      | uspeshno   |
| [kornevoj agent] Polnaya avtonomnaya matrica dispetchera posle reset-recovery               | 37,612 s     | neuspeshno |
| [kornevoj agent] Povtor adresnoj fiksturyi sozdannoj zadachi rezervacii                    | 0,932 s      | uspeshno   |
| [kornevoj agent] Povtor polnoj avtonomnoj matricyi dispetchera posle ispravleniya fiksturyi  | 37,708 s     | uspeshno   |
| [kornevoj agent] Polnaya avtonomnaya matrica sleduyusjhego shaga i heartbeat                   | 127,671 s    | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown posle realizacii shtatnogo sbrosa           | 0,591 s      | uspeshno   |
| [kornevoj agent] Obnovleniye teplovoj kartyi Obsidian posle shtatnogo sbrosa                | 0,378 s      | uspeshno   |
| [kornevoj agent] Proverka probeljnoj chistotyi itogovogo Git diff                          | 0,078 s      | uspeshno   |
| [kornevoj agent] Predproverka yedinstvennogo in-place obnovleniya live heartbeat           | 0,077 s      | uspeshno   |
| [kornevoj agent] Crash-retry ne stirayet pozdneye tracked i index izmeneniye                | 0,133 s      | neuspeshno |
| [kornevoj agent] Povtor crash-retry fiksturyi pozdnego tracked i index izmeneniya          | 2,604 s      | uspeshno   |
| [kornevoj agent] Polnyij klass shtatnogo reset posle tracked crash-retry fix               | 39,139 s     | uspeshno   |
| [kornevoj agent] Kompilyaciya Python posle usileniya crash-retry i receipt                  | 0,141 s      | uspeshno   |
| [kornevoj agent] Sintaksis Python posle finaljnyikh ograzhdenij sbrosa                      | 0,136 s      | uspeshno   |
| [kornevoj agent] Uzkiye testyi bezopasnogo povtora i host-identichnosti sbrosa              | 13,186 s     | uspeshno   |
| [kornevoj agent] Uzkiye testyi tochnogo threadId pochinki avtozapuska                        | 10,02 s      | uspeshno   |
| [kornevoj agent] Uzkij test vosstanovleniya rezervacii po kvitancii staroj vetki          | 2,732 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor testov FIFO-ocheredi posle finaljnogo audita                | 112,497 s    | uspeshno   |
| [kornevoj agent] Polnyij nabor testov pochinki avtozapuska posle exact threadId            | 33,372 s     | uspeshno   |
| [kornevoj agent] Sintaksis posle skhemyi host-svideteljstva v3                             | 0,138 s      | uspeshno   |
| [kornevoj agent] Uzkiye testyi klassifikacii cleanup i exact host-svideteljstva            | 5,104 s      | neuspeshno |
| [kornevoj agent] Sintaksis posle checkout-politiki i migracii v3                         | 0,122 s      | uspeshno   |
| [kornevoj agent] Povtornyiye uzkiye testyi cleanup, checkout i host v3                       | 8,508 s      | neuspeshno |
| [kornevoj agent] Uzkij test CRLF checkout-predstavleniya                                  | 3,648 s      | uspeshno   |
| [kornevoj agent] Uzkiye testyi tipizirovannogo host-svideteljstva rezervacii v3            | 5,237 s      | neuspeshno |
| [kornevoj agent] Diagnostika migracii v2 v v3 po exact witness                           | 1,487 s      | neuspeshno |
| [kornevoj agent] Povtornyij test migracii v2 v v3 po exact witness                        | 1,576 s      | uspeshno   |
| [kornevoj agent] Kontrakt renderer dlya typed host witness i reset route                  | 0,076 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor testov dispetchera posle schema v3                          | 48,859 s     | uspeshno   |
| [kornevoj agent] Uzkiye testyi CRLF i zapreta vneshnego checkout filter                     | 4,331 s      | uspeshno   |
| [kornevoj agent] Uzkiye testyi exact receipt guard i konfliktnoj migracii v3               | 5,652 s      | uspeshno   |
| [kornevoj agent] Uzkiye testyi zapreta checkout filter iz index i worktree attributes      | 1,145 s      | uspeshno   |
| [kornevoj agent] Uzkij test dvukh reset-kvitancij s prezhnim committed                     | 3,843 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor dispetchera posle reset-audita                              | 49,568 s     | uspeshno   |
| [kornevoj agent] Polnyij nabor sleduyusjhego shaga i heartbeat                                | 153,833 s    | neuspeshno |
| [kornevoj agent] Adresnaya proverka byudzheta heartbeat                                     | 0,313 s      | uspeshno   |
| [kornevoj agent] Polnyij nabor FIFO posle finaljnogo audita                               | 147,809 s    | uspeshno   |
| [kornevoj agent] Povtor polnogo nabora sleduyusjhego shaga posle sokrasjheniya heartbeat        | 151,099 s    | uspeshno   |
| [kornevoj agent] Proverka planovogo reyestra posle FUM-REQ-0039                           | 0,307 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti Markdown posle reset-dokumentacii                     | 0,565 s      | uspeshno   |
| [kornevoj agent] Proverka teplovoj kartyi Obsidian                                        | 0,358 s      | uspeshno   |
| [kornevoj agent] Proverka strukturyi papok zaprosov                                       | 8,423 s      | uspeshno   |
| [kornevoj agent] Kompilyaciya izmenyonnyikh Python-scenariyev                                  | 0,141 s      | uspeshno   |
| [kornevoj agent] Proverka probeljnoj chistotyi diff                                        | 0,075 s      | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj rabochej sessii                                  | 24,158 s     | neuspeshno |
| [kornevoj agent] Itogovaya kompleksnaya proverka reset-protokola                           | 36,202 s     | neuspeshno |
| [kornevoj agent] Povtornaya proverka mashinno-lokaljnyikh putej posle smoke                  | 12,092 s     | neuspeshno |
| [kornevoj agent] Diagnostika khvosta proverki mashinno-lokaljnyikh putej                     | 12,582 s     | neuspeshno |
| [kornevoj agent] Vyideleniye oshibok proverki mashinno-lokaljnyikh putej                       | 12,175 s     | neuspeshno |
| [kornevoj agent] Proverka mashinno-lokaljnyikh putej posle ispravleniya dvukh form            | 12,031 s     | uspeshno   |
| [kornevoj agent] Itogovaya kompleksnaya proverka reset-protokola posle ispravleniya         | 36,642 s     | neuspeshno |
| [kornevoj agent] Sravneniye latinskogo ostatka v izmenyonnyikh Python-fajlakh                 | 0,953 s      | uspeshno   |
| [kornevoj agent] Sukhoj plan perevoda novyikh latinskikh obyyavlenij                          | 0,221 s      | uspeshno   |
| [kornevoj agent] Povtornoye sravneniye latinskogo ostatka posle perevoda                   | 0,98 s       | uspeshno   |
| [kornevoj agent] Proverka obnovlyonnogo snimka latinskogo ostatka                         | 4,138 s      | uspeshno   |
| [kornevoj agent] Povtornaya polnaya FIFO-matrica posle perevoda obyyavlenij                 | 129,459 s    | uspeshno   |
| [kornevoj agent] Okonchateljnaya kompleksnaya proverka shtatnogo sbrosa                      | 1738,624 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3745,649 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- FIFO-matrica zakreplyayet SHA-1/SHA-256, aktivnyij reset-fence, tochnuyu ochistku, skryityiye index-flagi, checkout-policy, vstroyennyij EOL i zapret vneshnego filter, otkaz `unsupported_untracked_type`, ignored-collision, gitlink, sovmestimyij povtor chastichno primenyonnogo `read-tree`, zapret pozdnego tracked/index/untracked-drift i symlink-obkhoda do daljnejshego udaleniya, neposredstvennuyu povtornuyu sverku kazhdogo obyyekta, vlozhennyiye Git-granicyi, nezavershyonnuyu host-granicu, Git GC i povtor zavershyonnogo sbrosa.
- Dispetcherskiye testyi proveryayut vzaimnuyu CAS-zasjhitu management/reservation, fiksirovannuyu epokhu, blokirovku begin-call vo vremya reset, tipizirovannyiye host-svideteljstva, tochnuyu migraciyu skhemyi i vosstanovleniye odnoj rezervacii po neskoljkim samodostatochnyim kvitanciyam bez sovpadeniya po odnomu povtorno ispoljzovannomu `task_id`, predvariteljnomu `clientThreadId` ili vremeni.
- Testyi sleduyusjhego shaga proveryayut queue-guard dlya claim/release, marshrut reset v kanonicheskom heartbeat i bezopasnuyu rabotu snapshot-helper s fakticheski nablyudayemyimi celochislennyimi millisecond-metkami host.
- Navyik perevoda obyyavlenij koda sravnil izmenyonnyiye Python-fajlyi s `HEAD`, ne obnaruzhil ni odnogo novogo latinskogo obyyavleniya, token-osoznanno primenil proverennuyu kartu k pyati fajlam i sokratil istoricheskij ostatok na 66 obyyavlenij. Polnyij obnovlyonnyij snimok iz 43 262 obyyavlenij sovpadayet s vosproizvodimyim inventaryom; povtornaya FIFO-matrica posle pereimenovanij proshla vse 101 test.
- Zhivoj audit nashyol rovno odnu susjhestvuyusjhuyu aktivnuyu pyatiminutnuyu heartbeat-avtomatizaciyu. Ona obnovlena odnim in-place vyizovom bez povtora i dublikata; polnyij TOML-readback podtverdil exact-neizmennostj identichnosti, tipa, imeni, raspisaniya, statusa, target, versii i vremeni sozdaniya, izmeneniye toljko `prompt` i sluzhebnogo `updated_at` i bajtovoye sovpadeniye itogovogo prompt s renderer.
- Poslednyaya stroka upravlyayemogo bloka yavlyayetsya avtoritetnyim rezuljtatom itogovogo polnogo smoke-check; zamyikayusjhiye proverki zakryitogo snimka vyipolnyayutsya posle neyo i ne pereotkryivayut mashinnyij zhurnal.

## Resheniya i ogranicheniya

- «Posledneye zafiksirovannoye v Git» opredeleno kak tochnyij tekusjhij lokaljnyij commit `HEAD` imenovannoj vetki posle snimka, a ne remote, reflog ili proizvoljno vyibrannyij istoricheskij kommit. Branch-ref ne peremesjhayetsya.
- Neignoriruyemaya ochistka ogranichena obyyektami, kotoryiye pokazyivayet `git ls-files --others --exclude-standard`: obyichnyimi fajlami i simvolicheskimi ssyilkami s tochnyimi tipom i SHA-256. Specialjnyij Git-vidimyij obyyekt dayot `unsupported_untracked_type` do podgotovki. Kazhdyij izmenyonnyij tracked-putj khranit preimage/target; crash-retry prinimayet toljko indeks celikom v preimage libo target i kazhdyij putj v odnom iz dvukh zakreplyonnyikh sostoyanij, a pozdneye tracked-, index- ili untracked-raskhozhdeniye blokiruyet tekusjhij vyizov do daljnejshego udaleniya. Pered kazhdyim otdeljnyim udaleniyem literal Git-proverka i povtornyij khyesh predshestvuyut lyubomu fajlovomu obkhodu, poetomu vosstanovlennaya target-ssyilka ne vedyot k vneshnemu fajlu. Ignoriruyemyiye dannyiye, novyiye ili izmenivshiyesya posle podtverzhdeniya obyyektyi, pustyiye katalogi, lyubaya neotslezhivayemaya normal/bare Git-granica i gryaznyij tracked submodule ne ochisjhayutsya neyavno.
- Nezavershyonnyiye host-vyizovyi obsjhej rezervacii i pochinki blokiruyut uzhe planirovaniye, potomu chto budusjhaya zadacha mozhet poyavitjsya posle snimka. Exact `threadId` vkhodit v uchastnikov do bind i obyazan sovpastj s fakticheskim `task_id`; predvariteljnyij `clientThreadId` ostayotsya neodnoznachnostjyu do fakticheskoj privyazki.
- CLI sveryayet identifikator dispetchera s `CODEX_THREAD_ID` processa. Dokazateljstvo, chto eto imenno zakreplyonnaya postoyannaya zadacha, ostayotsya obyazannostjyu host-orkestracii: lokaljnyij process ne mozhet sam udostoveritj prikrepleniye i naznacheniye zadachi.
- Tekusjhaya host-poverkhnostj imeyet read/view/handoff, no ne chistyij `stop_thread`/`interrupt_thread`. Aktivnaya zadacha poetomu blokiruyet sbros do pervoj mutacii; future stop dolzhen vyizyivatjsya posle fence i podtverzhdatjsya povtornyim exact readback.
- Heartbeat ne mozhet samostoyateljno nachinatj ili prodolzhatj sbros. Do finala otdeljnyij yavnyij poljzovateljskij khod prodolzhayet operaciyu po reset-record; posle finaljnogo sozdaniya kvitancii sleduyusjhij heartbeat ispoljzuyet yeyo toljko kak completion-or-receipt-svideteljstvo s tochnyimi reservation-ref/OID i recovery `released` libo `unclaimed`. Posle uspeshnogo `apply` tot zhe poljzovateljskij khod toljko soobsjhayet rezuljtat i ne vyipolnyayet novuyu zapisj ili zapusk.
- FUM-REQ-0039 perevedeno v `🚧`, a FUM-STEP-0141 sokhranena aktivnoj do live-priyomki shtatnoj ostanovki i bezopasnogo novogo `join` posle sbrosa.
- Publikaciya ne vyipolnyayetsya: sessiya zavershayet toljko lokaljnyij commit+handoff bez `push`.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-08 02:16:00 MSK -->
<!-- content-sha256: sha256:f185a9c14b0498ab94b7d80abd0b6b1a429c7fe0687f0850359d63cb2ebfd1ab -->
<!-- FUM-MD-RECENCY:END -->
