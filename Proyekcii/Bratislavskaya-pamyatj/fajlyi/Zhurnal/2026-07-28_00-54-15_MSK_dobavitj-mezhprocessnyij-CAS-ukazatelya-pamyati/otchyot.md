# Otchyot 2026-07-28 00:54:15 MSK - Dobavitj mezhprocessnyij CAS ukazatelya pamyati

Publikaciya podtverzhdyonnogo pokoleniya pamyati teperj prinimayet linearizuyemoye resheniye mezhdu sotrudnichayusjhimi processami. Dva pisatelya boljshe ne mogut molcha zamenitj rezuljtatyi drug druga posle odnoj proverki obsjhego roditelya: kazhdyij kandidat nesyot tochnoye ozhidaniye, a zasjhisjhyonnoye resheniye zavershayetsya publikaciyej, idempotentnyim povtorom libo tipizirovannyim konfliktom.

## Rezuljtat

`MemoryGenerationStore` snachala proveryayet i kanoniziruyet pokoleniye, vyichislyayet yego SHA-256 i podgotavlivayet adresuyemyij obyyekt. Posle etogo on otkryivayet postoyannyij `CURRENT.lock`, poluchayet eksklyuzivnuyu POSIX record lock i pod nej zanovo chitayet polnostjyu proverennyij `CURRENT`. Sovpadeniye tekusjhego khyesha s celevyim dayot idempotentnyij uspekh; sovpadeniye s `previous_generation_sha256` razreshayet atomarnuyu zamenu ukazatelya; lyuboye inoye sostoyaniye vozvrasjhayet `generationConflict` s ozhidayemyim i fakticheskim khyeshami.

Podgotovka obyyekta predshestvuyet CAS namerenno. Proigravshij process ne menyayet ukazatelj i ne udalyayet podtverzhdyonnoye pokoleniye pobeditelya, no yego sobstvennyij kanonicheskij obyyekt mozhet bezopasno ostatjsya sirotoj. Postoyannyij lock-fajl ne udalyayetsya, poetomu ozhidayusjhiye processyi ne raskhodyatsya po raznyim inode. Garantiya ogranichena sotrudnichayusjhimi otdeljnyimi processami na lokaljnoj fajlovoj sisteme tekusjhego macOS-prototipa. `fcntl` ne rasshiryayet yeyo na proizvoljnyiye potoki odnogo processa ili obkhodyasjhikh protokol pisatelej, a atomarnaya zamena bez otdeljnoj sinkhronizacii ne dokazyivayet sokhrannostj pri avarii processa ili potere pitaniya.

Dvukhprocessnyij test sozdayot dva raznyikh validnyikh pokoleniya ot odnogo podtverzhdyonnogo roditelya i sinkhroniziruyet realjnyiye docherniye xctest-processyi neposredstvenno pered CAS. Krasnyij progon prezhnej realizacii dal dva uspekha i ni odnogo konflikta. Zelyonyij progon dal odnogo pobeditelya i odin tipizirovannyij konflikt, sokhranil tochnyiye bajtyi oboikh adresuyemyikh obyyektov, tochnyij dopustimyij sostav khranilisjha i neizmennyij `CURRENT` posle povtorov. Otdeljnyij processnyij scenarij uderzhivayet `CURRENT.lock` v roditele, nablyudayet testovyiye tochki neposredstvenno do vyizova `fcntl` i posle yego uspekha i podtverzhdayet, chto dochernij pisatelj ne poluchayet lock do yavnogo osvobozhdeniya. Monotonnyiye dedlajnyi i bounded terminate→SIGKILL ne ostavlyayut docherniye processyi zhitj posle neuspeshnogo iskhoda testa.

Kartochka FUM-STEP-0099 zavershena. Sleduyusjhim tekhnicheskim pokoleniyem stanovitsya FUM-STEP-0100: ono otdeljno proverit sinkhronizaciyu fajlov i katalogov, avarijnyiye kontroljnyiye tochki i chestnuyu granicu power-loss durability. Trebovaniye ostayotsya `🚧`; zhurnal otklonyonnyikh kandidatov, avarijnaya soglasovannostj, yazyikonejtraljnyij bajtovyij profilj i prezhnyaya skhema pokoleniya yesjhyo ne zakryityi.

## Proverki

Celevoj SwiftPM-paket prokhodit avtonomnyiye testyi s realjnyimi dochernimi processami. Otdeljno proverenyi strogaya sborka s polnoj konkurentnostjyu i preduprezhdeniyami kak oshibkami, Swift Format lint, kontrakt zapuskatelej, vetochnyij nabor, planovyij reyestr i sluzhebnyiye metki. Posle ispravleniya najdennogo pervyim progonom mashinno-lokaljnogo puti povtornyij polnyij smoke-check proshyol vse 61 shag.

## Profilj vremeni vyipolneniya

| Stadiya                                      | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                  |
| ------------------------------------------- | -----------: | --------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i ozhidaniye FIFO                 |       0,40 s | Wall time yedinstvennogo `join`; sostoyaniye `admitted` polucheno srazu, perioda `waiting` ne byilo.                             |
| Soderzhateljnaya rabota do itogovyikh proverok  |  ne izmereno | Ot FIFO-dopuska do nachala itogovogo proverochnogo kontura; tri razlichimyikh read-only-audita chastichno vyipolnyalisj paralleljno. |
| Celevyiye i sluzhebnyiye proverki do smoke-check |  ne izmereno | Pryamyiye processyi perechislenyi nizhe; povtornyiye ispravleniya kompilyacii i usileniye konkurentnogo testa vkhodyat v etu stadiyu.      |
| Pervyij polnyij smoke-check                   |     226,66 s | Vneshnij `/usr/bin/time`; 53 shaga proshli, shag 54 obnaruzhil mashinno-lokaljnyij absolyutnyij putj zapuska dochernego `xctest`.     |
| Povtornyij polnyij smoke-check                |     226,76 s | Vneshnij `/usr/bin/time`; vse 61 shaga proshli, vnutrenneye monotonnoye vremya runner — 226,720 s.                                |

### Pryamyiye zapuski proverok

| Vyizov                                                           | Dliteljnostj | Rezuljtat                                                                                              |
| --------------------------------------------------------------- | -----------: | ------------------------------------------------------------------------------------------------------ |
| `[root]` chteniye aktualjnogo claim naznacheniya                    |       0,20 s | uspeshno (nablyudenyi tochnyiye `branch_ref`, `step_id`, `selection.id` i `selection.head`)                  |
| `[root]` fenced `show` naznachennoj kartochki                     |       0,70 s | uspeshno (vetka, pokoleniye vyibora, kartochka i yeyo khyesh sovpali)                                           |
| `[root]` proverka opisaniya i runtime SwiftPM-paketa             |       1,30 s | uspeshno (paket bez vneshnikh zavisimostej, platforma macOS 14+, Swift 6.4)                               |
| `[root]` proverka dostupnogo interfejsa sistemnogo `xctest`     |       0,10 s | uspeshno (podtverzhdyon filjtr otdeljnogo metoda v test bundle)                                           |
| `[root]` krasnyij dvukhprocessnyij CAS-test                        |       3,71 s | neuspeshno ozhidayemo (dva processa opublikovali raznyiye pokoleniya; konfliktov ne byilo)                    |
| `[root]` pervaya zelyonaya popyitka posle perenosa resheniya pod lock |       1,40 s | neuspeshno (Swift razlichil strukturu `flock` i odnoimyonnuyu C-funkciyu; realizaciya perevedena na `fcntl`) |
| `[root]` zelyonyij dvukhprocessnyij CAS-test                        |       3,37 s | uspeshno (odin pobeditelj, odin konflikt, idempotentnyij povtor i stale-otkaz)                           |
| `[root]` pervyij polnyij Swift-nabor                              |       2,26 s | uspeshno (23/23 do otdeljnogo testa uderzhaniya lock)                                                     |
| `[root]` pervaya popyitka usilennyikh processnyikh testov             |       1,48 s | neuspeshno (yavno ispravlen tip `Int32` rezuljtata otkryitiya POSIX-fajla)                                 |
| `[root]` usilennyiye processnyiye testyi                             |       4,47 s | uspeshno (2/2: konkurentnyij iskhod i fakticheskoye ozhidaniye uderzhivayemogo `CURRENT.lock`)                  |
| `[root]` pervyij `git diff --check` posle Swift Format           |       0,30 s | uspeshno (oshibok probelov posle mekhanicheskogo formatirovaniya net)                                       |
| `[root]` povtornyij `git diff --check` posle planovogo perekhoda  |       0,20 s | uspeshno (planovyij i sessionnyij diff ne soderzhit oshibok probelov)                                       |
| `[root]` pervyij vetochnyij `validate` posle pereimenovaniya        |       0,39 s | neuspeshno ozhidayemo (obnaruzhen novyij khyesh kartochki FUM-STEP-0100 posle kaskada ssyilki)                   |
| `[root]` itogovyij polnyij Swift-nabor                            |       4,28 s | uspeshno (24/24, vklyuchaya oba processnyikh CAS-scenariya)                                                   |
| `[root]` strogij Swift Format lint                              |       0,22 s | uspeshno                                                                                                |
| `[root]` itogovaya proverka rabochego nabora vetki                |       0,48 s | uspeshno (`ready_count=2`, FUM-STEP-0100 i FUM-STEP-0008)                                               |
| `[root]` proverka planovogo reyestra                             |       0,25 s | uspeshno                                                                                                |
| `[root]` proverka tochek zapuska prototipov                      |       0,10 s | uspeshno (kornevaya panelj i 9 tochek vkhoda)                                                              |
| `[root]` strogaya Swift-sborka                                   |       2,06 s | uspeshno (`strict-concurrency=complete`, preduprezhdeniya kak oshibki)                                     |
| `[root]` pervaya popyitka lokaljnogo scenariya CLI                 |       0,00 s | ne zaversheno (host otklonil komandu ochistki vremennogo kataloga do zapuska proverki)                   |
| `[root]` lokaljnyij scenarij `bootstrap → continue → show`       |       8,31 s | uspeshno (rezuljtat `show` sovpal s prodolzheniyem, postoyannyij `CURRENT.lock` susjhestvuyet)                 |
| `[root]` proverka publikacionnogo remote                        |       0,08 s | uspeshno (yedinstvennyij credential-free HTTPS push URL bez primenimogo rewrite)                          |
| `[session_artifacts]` proverka selector i khyesha kartochki         |       0,10 s | uspeshno (2 ready, 25 paused, 1 blocked; khyesh FUM-STEP-0100 sovpal)                                      |
| `[session_artifacts]` proverka affected-files i ssyilok          |       0,10 s | uspeshno (22 zhivyiye ssyilki i korrektnyij marker udalyonnoj kartochki)                                       |
| `[session_artifacts]` predvariteljnyij recency-audit             |       0,10 s | neuspeshno ozhidayemo (sluzhebnyiye generatoryi yesjhyo ne byili zapusjhenyi)                                         |
| `[root]` usilennyiye processnyiye testyi posle finaljnogo revjyu      |       5,01 s | uspeshno (2/2: tochki do/posle fakticheskogo lock, bounded cleanup i tochnyij sostav store)                 |
| `[root]` polnyij Swift-nabor posle usileniya testov               |       3,78 s | uspeshno (24/24)                                                                                        |
| `[root]` Swift Format lint posle usileniya testov                |       0,21 s | uspeshno                                                                                                |
| `[root]` strogaya Swift-sborka posle usileniya testov             |       2,01 s | uspeshno (`strict-concurrency=complete`, preduprezhdeniya kak oshibki)                                     |
| `[root]` pervyij polnyij smoke-check                              |     226,66 s | neuspeshno (53 shaga proshli; shag 54 obnaruzhil zhyostkij absolyutnyij putj k `xcrun` v novom teste)           |
| `[root]` proba pryamogo zapuska test bundle                      |       0,00 s | neuspeshno (Mach-O bundle ne yavlyayetsya samostoyateljnyim ispolnyayemyim fajlom)                               |
| `[root]` proverka mashinno-lokaljnyikh putej posle ispravleniya     |       9,84 s | uspeshno (putj `xcrun` razreshayetsya iz absolyutnyikh katalogov runtime `PATH`)                              |
| `[root]` processnyiye testyi posle ispravleniya puti zapuska        |       4,58 s | uspeshno (2/2)                                                                                          |
| `[root]` povtornyij polnyij smoke-check                           |     226,76 s | uspeshno (61/61; vnutrenneye monotonnoye vremya runner — 226,720 s)                                        |
| `[root]` itogovaya proverka svyaznosti rabochej sessii             |      10,74 s | uspeshno                                                                                                |
| `[root]` itogovaya proverka recency-metok Markdown               |       0,40 s | uspeshno                                                                                                |
| `[root]` itogovaya proverka teplovoj kartyi grafa Obsidian        |       0,27 s | uspeshno                                                                                                |
| `[root]` itogovyij `git diff --check`                            |       0,03 s | uspeshno                                                                                                |

Obsjheye vremya pryamyikh zapuskov proverok: 526,25 s.

Granica profilya: ot yedinstvennogo FIFO-`join` do uspeshnogo zaversheniya povtornogo polnogo smoke-check. Vlozhennyiye shagi yedinogo runner ne dubliruyutsya kak pryamyiye vyizovyi, a dliteljnosti paralleljnyikh read-only-auditov ne skladyivayutsya s kalendarnyim vremenem. Posle etoj granicyi sluzhebnyiye generatoryi i svyaznostj zamyikayut itogovuyu zapisj otchyota bez rekursivnogo polnogo povtora.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [kartochka FUM-STEP-0099](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0099-dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [Swift-prototip vosproizvodimogo popolneniya pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e0b2dcfc2a87524bd4be8f60f59299b313bc61473ed6519a8a875c9ce278b00b -->
<!-- FUM-MD-RECENCY:END -->
