# Otchyot 2026-08-04 20:45:26 MSK - Formirovatj otchyotyi o zapuskakh testov

Realizovana avtomatizaciya `fum-otchyotyi-o-zapuskakh-proverok`, kotoraya zapuskayet kazhduyu pryamuyu proverku bez shell, atomarno sokhranyayet yeyo sostoyaniye i nablyudyonnyij iskhod v otdeljnom JSON-fajle, a zatem determinirovanno formiruyet tablicu v zhurnaljnom `отчёт.md`.

Zapisi svyazanyi s tochnyim zaprosom, uporyadochenyi pod mezhprocessnyim zamkom i khyeshiruyutsya v zakryitom snimke. Povtoryi, ozhidayemyiye TDD-red, neuspekhi, signalyi, tajm-autyi i nezavershyonnyiye zapuski ne svorachivayutsya i ne vyidayutsya za uspekh. Zakryitiye ispoljzuyet povtorimuyu podgotoviteljnuyu fazu so snimkom pervyim, a obratnyij perekhod zasjhisjhyon kanonicheskim `возобновление.json`, kotoryij blokiruyet ostaljnyiye dejstviya do zaversheniya. Syiroj vyivod, argumentyi, sreda, PID i mashinno-lokaljnyiye dannyiye v publikuyemyij zhurnal ne popadayut.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj         | Granicyi i sposob izmereniya                                                                                              |
| ------------------------ | -------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno          | Ocheredj zaregistrirovala bilet `seq=38`; tochnaya dliteljnostj ozhidaniya do dopuska ne sokhranyalasj                         |
| Soderzhateljnaya rabota    | ne izmereno          | Ot metki sessii `2026-08-04 20:45:26 MSK` do predfinaljnogo smoke-check; otdeljnyij tajmer dlya analiza i pravok ne vyolsya |
| Celevyiye proverki         | mashinnyij itog nizhe   | Summa vsekh otdeljnyikh strok upravlyayemogo bloka, vklyuchaya ozhidayemyiye neuspekhi i povtoryi                                     |
| Polnyij smoke-check       | mashinnaya stroka nizhe | Poslednyaya verkhneurovnevaya zapisj okhvachennoj granicyi; vnutrenniye shagi smoke-check povtorno ne uchityivayutsya                |
| Atomarnyij commit+handoff | vne granicyi          | Poslednyaya Git-tranzakciya ocheredi; ona vyipolnyayetsya posle zakryitiya snimka i v samootchyot ne vklyuchayetsya                     |

Granica profilya: nachalo — metka sessii `2026-08-04 20:45:26 MSK`; chislovoj konec — zaversheniye poslednej mashinnoj stroki, predfinaljnogo polnogo smoke-check. Ozhidaniye FIFO predshestvuyet metke i ne izmereno; samosoglasovannoye zamyikaniye snimka, sluzhebnyiye proverki zamyikaniya i commit+handoff v arifmetiku ne vkhodyat.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:0534b20a94fc8d929a7af77d02180bb5a7b3c614847e390b1e3ddf242e914248 -->

| Vyizov                                                                                            | Dliteljnostj | Rezuljtat                                                                                                                  |
| ------------------------------------------------------------------------------------------------ | ------------ | -------------------------------------------------------------------------------------------------------------------------- |
| [korenj] yedinyij zagruzochnyij TDD-progon testov otchyotov, svyaznosti i shablona                       | 9,462 s      | neuspeshno — ozhidayemyij pervichnyij TDD-red do poyavleniya obyortki; dliteljnostj izmerena monotonnyimi chasami zagruzochnogo vyizova |
| [korenj] celevyiye testyi avtomatizacii otchyotov o zapuskakh proverok                                 | 1,575 s      | uspeshno                                                                                                                    |
| [korenj] celevyiye testyi svyaznosti rabochej sessii                                                  | 1,793 s      | uspeshno                                                                                                                    |
| [korenj] celevyiye testyi strukturyi papok zaprosov                                                  | 8,769 s      | uspeshno                                                                                                                    |
| [korenj] inventarizaciya obyyavlenij koda posle realizacii                                         | 4,077 s      | uspeshno                                                                                                                    |
| [korenj] proverka prezhnego snimka obyyavlenij posle dobavleniya koda                               | 4,154 s      | neuspeshno                                                                                                                  |
| [korenj] proverka latinskikh obyyavlenij v novoj avtomatizacii                                     | 4,37 s       | neuspeshno                                                                                                                  |
| [korenj] sukhoj plan perevoda obyyavlenij novoj avtomatizacii                                      | 0,058 s      | neuspeshno                                                                                                                  |
| [korenj] TDD-red obyazateljnogo prefiksa test_ v karte perevoda                                   | 1,082 s      | neuspeshno                                                                                                                  |
| [korenj] TDD-green obyazateljnogo prefiksa test_ v karte perevoda                                 | 1,247 s      | uspeshno                                                                                                                    |
| [korenj] povtornyij sukhoj plan perevoda obyyavlenij novoj avtomatizacii                            | 0,08 s       | uspeshno                                                                                                                    |
| [korenj] primeneniye proverennoj kartyi obyyavlenij novoj avtomatizacii                             | 0,081 s      | uspeshno                                                                                                                    |
| [korenj] povtornaya proverka latinskikh obyyavlenij novoj avtomatizacii                             | 4,121 s      | uspeshno                                                                                                                    |
| [korenj] obnovleniye snimka istoricheskogo ostatka obyyavlenij                                      | 4,095 s      | uspeshno                                                                                                                    |
| [korenj] proverka obnovlyonnogo snimka obyyavlenij koda                                            | 4,039 s      | uspeshno                                                                                                                    |
| [korenj] sravneniye prirosta istoricheskogo ostatka obyyavlenij s HEAD                              | 7,331 s      | neuspeshno                                                                                                                  |
| [korenj] sukhoj plan ustraneniya prirosta ostatka v testakh svyaznosti                               | 0,09 s       | uspeshno                                                                                                                    |
| [korenj] primeneniye kartyi ustraneniya prirosta ostatka v testakh svyaznosti                         | 0,085 s      | uspeshno                                                                                                                    |
| [korenj] povtornoye sravneniye prirosta ostatka obyyavlenij s HEAD                                  | 7,176 s      | uspeshno                                                                                                                    |
| [korenj] finaljnoye obnovleniye snimka ostatka bez prirosta                                        | 4,189 s      | uspeshno                                                                                                                    |
| [korenj] sovmestnyij regressionnyij progon chetyiryokh zatronutyikh avtomatizacij                        | 13,563 s     | uspeshno                                                                                                                    |
| [korenj] proverka probeljnyikh oshibok posle svedeniya dokumentacii                                  | 0,03 s       | uspeshno                                                                                                                    |
| [korenj] proverka strukturyi papok zaprosov posle svedeniya dokumentacii                           | 6,553 s      | uspeshno                                                                                                                    |
| [korenj] proverka reyestra nazvanij avtomatizacij                                                 | 3,332 s      | uspeshno                                                                                                                    |
| [korenj] proverka mashinno-lokaljnyikh putej                                                        | 12,055 s     | uspeshno                                                                                                                    |
| [korenj] proverka snimka ostatka obyyavlenij koda pered zamyikaniyem                                | 4,179 s      | uspeshno                                                                                                                    |
| [korenj] proverka otkryitogo mashinnogo zhurnala s aktivnoj sobstvennoj zapisjyu                     | 0,067 s      | uspeshno                                                                                                                    |
| [subagent-audit] TDD-red upravleniya sostoyaniyem processov i tochnyikh kontraktov otchyotov             | 3,883 s      | neuspeshno                                                                                                                  |
| [subagent-audit] TDD-red otkatov zakryitiya i vozobnovleniya                                        | 0,307 s      | neuspeshno                                                                                                                  |
| [subagent-audit] TDD-green upravleniya sostoyaniyem processov i tochnyikh kontraktov otchyotov           | 5,473 s      | neuspeshno                                                                                                                  |
| [subagent-audit] diagnostika tajm-auta upravleniya sostoyaniyem processov                           | 0,784 s      | neuspeshno                                                                                                                  |
| [subagent-audit] povtornyij TDD-green upravleniya sostoyaniyem processov i tochnyikh kontraktov otchyotov | 5,396 s      | uspeshno                                                                                                                    |
| [subagent-audit] regressiya integracii mashinnogo otchyota so svyaznostjyu sessii                      | 1,112 s      | neuspeshno                                                                                                                  |
| [subagent-audit] finaljnyij celevoj progon ispravlenij upravleniya sostoyaniyem processov            | 5,355 s      | uspeshno                                                                                                                    |
| [subagent-audit] povtornaya regressiya integracii mashinnogo otchyota so svyaznostjyu sessii            | 2,029 s      | uspeshno                                                                                                                    |
| [subagent-audit] TDD-red vtorogo cikla nadyozhnosti otchyotov o zapuskakh                             | 5,732 s      | neuspeshno                                                                                                                  |
| [subagent-audit] TDD-green vtorogo cikla nadyozhnosti otchyotov o zapuskakh                           | 10,571 s     | neuspeshno                                                                                                                  |
| [subagent-audit] TDD-green povtor vtorogo cikla nadyozhnosti otchyotov                               | 5,887 s      | uspeshno                                                                                                                    |
| [subagent-audit] TDD-red tretjyego cikla WAL i linearizacii signalov                              | 6,036 s      | neuspeshno                                                                                                                  |
| [subagent-audit] TDD-red utochnyonnoj granicyi WAL i signalov                                       | 6,063 s      | neuspeshno                                                                                                                  |
| [subagent-audit] popyitka TDD-green tretjyego cikla WAL i signalov                                 | 6,125 s      | uspeshno                                                                                                                    |
| [subagent-audit] kontroljnyij TDD-green tretjyego cikla WAL i signalov                             | 6,109 s      | uspeshno                                                                                                                    |
| [subagent-audit] finaljnyij TDD-green tretjyego cikla WAL i signalov                               | 6,087 s      | neuspeshno                                                                                                                  |
| [subagent-audit] diagnostika EPERM pri proverke ischeznoveniya gruppyi                              | 0,714 s      | uspeshno                                                                                                                    |
| [subagent-audit] finaljnyij TDD-green posle utochneniya proverki gruppyi                             | 5,98 s       | uspeshno                                                                                                                    |
| [korenj] sovmestnyij itogovyij regressionnyij progon chetyiryokh zatronutyikh avtomatizacij               | 17,07 s      | uspeshno                                                                                                                    |
| [korenj] proverka obnovlyonnogo snimka obyyavlenij koda posle finaljnoj realizacii                 | 3,97 s       | uspeshno                                                                                                                    |
| [korenj] proverka strukturyi papok zaprosov posle finaljnogo svedeniya kontraktov                  | 6,328 s      | uspeshno                                                                                                                    |
| [korenj] proverka reyestra nazvanij posle finaljnogo svedeniya kontraktov                          | 5,36 s       | uspeshno                                                                                                                    |
| [korenj] proverka mashinno-lokaljnyikh putej posle finaljnogo svedeniya kontraktov                   | 11,564 s     | uspeshno                                                                                                                    |
| [korenj] proverka probeljnyikh oshibok posle finaljnogo svedeniya dokumentacii                       | 0,047 s      | uspeshno                                                                                                                    |
| [korenj] predvariteljnaya proverka svyaznosti rabochej sessii                                       | 21,345 s     | neuspeshno                                                                                                                  |
| [korenj] povtornaya predvariteljnaya proverka svyaznosti rabochej sessii                             | 21,332 s     | uspeshno                                                                                                                    |
| [korenj] predfinaljnyij polnyij smoke-check                                                        | 1517,741 s   | uspeshno                                                                                                                    |

Obsjheye vremya pryamyikh zapuskov proverok: 1796,053 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Avtonomnyij nabor iz 31 testa zakrepil skhemyi zapisi, snimka i zhurnala vozobnovleniya, uspekh, nenulevoj kod, oshibku zapuska, signaljnuyu linearizaciyu, ochistku PGID, tajm-aut, paralleljnyij poryadok, vosstanavlivayemyiye fazyi, tochnyiye khyeshi i zakryituyu proverku.
- Sovmestnyij itogovyij regressionnyij progon chetyiryokh zatronutyikh avtomatizacij vyipolnil 128 testov bez oshibok; otdeljnyiye TDD-red i neuspeshnyiye kandidatyi na zelyonyij rezuljtat v mashinnoj tablice sokhranenyi kak fakticheskaya istoriya razrabotki.
- Perevodchik obyyavlenij dopuskayet obyazateljnyij prefiks `test_` toljko pered russkoj smyislovoj osnovoj. Inventarj podtverdil otsutstviye novogo neobosnovannogo latinskogo ostatka.
- Kanonicheskoye imya `fum-otchyotyi-o-zapuskakh-proverok` polucheno rabochim LinguisticKit-marshrutom i zakrepleno v reyestre nazvanij.
- Itog polnogo smoke-check fiksiruyet poslednyaya stroka mashinnogo bloka; posle yego zakryitiya vyipolnyayutsya toljko sluzhebnyiye proverki zamyikaniya vne profilya.

## Resheniya i ogranicheniya

- Kanonicheskaya skhema zapisi — `fum.test-run.v1`; zakryityij snimok — `fum.test-run-report.v1`; vremennyij zhurnal obratnogo perekhoda — `возобновление-отчёта-проверок.1`. Snimok svyazyivayet imena i SHA-256 vsekh zapisej s marker-khyeshem v `отчёт.md`, a zhurnal perekhoda udalyayetsya poslednim i v gotovoye sostoyaniye ne vkhodit.
- Razdel schitayet summu iz otobrazhayemyikh millisekund i vyiravnivayet Markdown-tablicu v stile Obsidian; odinakovyiye vyizovyi ostayutsya otdeljnyimi strokami.
- Zapisj `1` importirovana odnokratno dlya zagruzochnogo TDD-red, vyipolnennogo do poyavleniya samoj obyortki: tochnaya monotonnaya dliteljnostj i neuspekh sokhranenyi, no takaya migraciya ne yavlyayetsya shtatnyim rezhimom.
- Zapisi primeneniya kart pereimenovanij i obnovleniya snimka ostatka popali v rannij samoproverochnyij profilj kak processyi s vstroyennyimi proverkami plana, khyeshej i ostatka. Oni sokhranenyi, a ne udalenyi zadnim chislom, no ne yavlyayutsya chistyim izmereniyem toljko testov i validatorov; shtatnaya granica ne oborachivayet mutiruyusjhiye komandyi.
- Dva promezhutochnyikh `git diff --check` byili sluchajno vyipolnenyi vnutri obzornyikh shell-komand vne obyortki i ne poluchili mashinnyikh strok. Namerennyij progon povtoryon v zapisi `22`, a itogovaya probeljnaya proverka vyipolnyayetsya posle zakryitiya; etot perekhodnyij defekt ne skryivayetsya i podtverzhdayet ogranicheniye: avtomatizaciya ne mozhet obnaruzhitj namerennyij ili oshibochnyij obkhod tochki vkhoda.
- Pryamoj vyizov ne sokhranyayet stdout, stderr, argumentyi ili sredu. Poetomu mashinnyij zhurnal dokazyivayet iskhod i dliteljnostj vyizova, no ne soderzhaniye yego vyivoda i ne smyislovuyu polnotu testa.
- Avtomaticheskaya polnota okhvatyivayet toljko vyizovyi, provedyonnyiye cherez `запустить`; eto zakrepleno kak obyazateljnoye pravilo kornya i subagentov, no ne mozhet byitj dokazano odnim skanirovaniyem fajlov.
- Posle zakryitiya snimka strogaya sverka avtomatizacii, recency, graf, svyaznostj i probeljnyiye oshibki vyipolnyayutsya vne zakryitoj granicyi, chtobyi ne sozdatj rekursivnyij samoizmenyayusjhijsya otchyot.
- Leksicheskaya zasjhita putej ne ustranyayet vrazhdebnuyu TOCTOU-podmenu predka; sokhranyonnyij PGID ne okhvatyivayet namerenno pokinuvshij gruppu process. Postoyannyij odnovremennyij otkaz vsekh vosstanoviteljnyikh zapisej takzhe ostayotsya sistemnoj granicej, poetomu mezhfajlovyiye perekhodyi opisanyi kak obnaruzhimyiye povtoryayemyiye fazyi, a ne kak odna atomarnaya tranzakciya.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [avtomatizaciya otchyotov o zapuskakh](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)
- [rabochaya sessiya](../../Glossarij/rabochaya-sessiya.md)
- [zhurnal rabot](../../Glossarij/zhurnal-rabot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 00:20:06 MSK -->
<!-- content-sha256: sha256:bcf1b55afa7328077e5710b642bfb2cac4a827c7e5eed67d142e7589d279f9e9 -->
<!-- FUM-MD-RECENCY:END -->
