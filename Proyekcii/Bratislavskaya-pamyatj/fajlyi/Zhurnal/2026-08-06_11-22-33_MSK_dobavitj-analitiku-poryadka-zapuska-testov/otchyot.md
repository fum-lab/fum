# Otchyot 2026-08-06 11:22:33 MSK - Dobavitj analitiku poryadka zapuska testov

Obsjhij smoke-check poluchil khyeshiruyemuyu analitiku fakticheski dostignutyikh Python- i SwiftPM-testov i determinirovannyij adaptivnyij poryadok. Snachala zapuskayutsya izvestnyiye naboryi s nablyudavshimisya oshibkami — po ubyivaniyu ikh chastotyi i, pri ravenstve, po vozrastaniyu dliteljnosti. Zatem idyot issledovateljskij blok bez zavershyonnoj istorii, a khvost obrazuyut izvestnyiye testyi bez nablyudavshikhsya oshibok. Poetomu ocheredj nachinayetsya podtverzhdyonnyim riskom i zakanchivayetsya podtverzhdyonnoj empiricheskoj veroyatnostjyu uspekha `1`, ne vyidavaya otsutstviye dannyikh za nadyozhnostj.

Nablyudeniya sokhranyayutsya posle kazhdogo dostignutogo testa i vmeste s tochnyim `план` vkhodyat v zapisj skhemyi `fum.test-run.v2` vnutri obyichnogo zakryitogo snimka rabochej sessii. Sleduyusjhij zapusk prinimayet statistiku toljko iz polnostjyu proverennyikh zakryityikh snimkov i neposredstvenno primenyayet yeyo v algoritme sortirovki. Fiksirovannyiye sborki, lint i validatoryi ne pereuporyadochivayutsya mezhdu soboj, vneshne prervannyiye iskhodyi ne vyidayutsya za oshibki, a avarijnyij signal samogo testa, tajm-aut i drugoye `не завершено` dostignutogo testa schitayutsya nablyudayemyim neuspekhom. Propusjhennyiye iz-za fail-fast testyi voobsjhe ne poluchayut vyimyishlennogo iskhoda.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj             | Granicyi i sposob izmereniya                                                                                         |
| ------------------------ | ------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Ozhidaniye dopuska FIFO    | 44 min 7,222 s           | Monotonnyij interval ocheredi ot registracii `07:36:53 UTC` do dopuska `08:21:00 UTC`                                |
| Soderzhateljnaya rabota    | ne izmereno otdeljno     | Ot dopuska do nachala predfinaljnogo smoke-check; vklyuchayet analiz, TDD-realizaciyu, revjyu kontrakta i dokumentaciyu    |
| Celevyiye proverki         | agregirovannyij call-time | Summa mashinnyikh dliteljnostej adresnyikh TDD-, regressionnyikh i planovyikh vyizovov v tablice pryamyikh zapuskov             |
| Polnyij smoke-check       | po mashinnoj zapisi       | Monotonnaya dliteljnostj poslednego pryamogo vyizova v zakryivayemom upravlyayemom bloke                                  |
| Atomarnyij commit+handoff | ne izmereno              | Vyipolnyayetsya FIFO-avtomatizaciyej posle proverok zamyikaniya i ne mozhet byitj podtverzhdyon vnutri sobstvennogo kommita    |

Granica profilya: ot registracii kornevoj zadachi v FIFO do poslednej proverki zamyikaniya zakryitogo otchyota pered atomarnyim commit+handoff; sama peredacha ostayotsya vne sokhranyayemogo profilya. Mashinnaya summa nizhe okhvatyivayet toljko pryamyiye proverochnyiye processyi i ne skladyivayetsya s perekryivayusjhimi yeyo stadiyami soderzhateljnoj rabotyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:e0beffc7dfeb812db4564b8e8f8b176f7c87b155b2c6c2d886a89c0713e67fc9 -->

| Vyizov                                                                  | Dliteljnostj | Rezuljtat                                                                                                        |
| ---------------------------------------------------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------- |
| [root] TDD-red: khyeshiruyemyiye nablyudeniya zapuskov v2                      | 6,255 s      | neuspeshno                                                                                                        |
| [root] TDD-red: poryadok vnutrennikh testov smoke-check                  | 22,796 s     | neuspeshno                                                                                                        |
| [root] TDD-green: poryadok vnutrennikh testov smoke-check                | 20,004 s     | uspeshno                                                                                                          |
| [root] TDD-green: khyeshiruyemyiye nablyudeniya zapuskov v2                    | 6,512 s      | uspeshno                                                                                                          |
| [root] TDD-red: obyazateljnyij plan i konvert smoke-check                | 6,663 s      | neuspeshno                                                                                                        |
| [root] TDD-red: plan analiticheskikh klyuchej smoke-check                  | 20,967 s     | neuspeshno                                                                                                        |
| [root] TDD-green: obyazateljnyij plan i konvert smoke-check              | 6,726 s      | uspeshno                                                                                                          |
| [root] TDD-green: plan analiticheskikh klyuchej smoke-check                | 21,803 s     | uspeshno                                                                                                          |
| [root] Proverka kontrakta otchyotov posle usileniya celostnosti           | 6,704 s      | uspeshno                                                                                                          |
| [root] Proverka analiticheskogo planirovsjhika posle usileniya celostnosti | 18,9 s       | uspeshno                                                                                                          |
| [root] Postroyeniye ocheredi po zakryitoj istorii repozitoriya              | 14,102 s     | uspeshno                                                                                                          |
| [root] Regressiya zakryitoj istorii i poryadka smoke-check                | 19,966 s     | uspeshno                                                                                                          |
| [root] Regressiya v2-protokola smoke-check                              | 6,941 s      | uspeshno                                                                                                          |
| [root] Itogovaya adresnaya regressiya analiticheskogo poryadka              | 18,515 s     | uspeshno                                                                                                          |
| [root] Proverka yazyika novyikh obyyavlenij koda                            | 4,863 s      | neuspeshno                                                                                                        |
| [root] Inventarizaciya novyikh obyyavlenij koda                            | 4,263 s      | uspeshno                                                                                                          |
| [root] TDD-red: polnyij poryadok riska i avarijnyiye signalyi               | 19,416 s     | neuspeshno                                                                                                        |
| [root] Diagnostika ostatka obyyavlenij v zatronutom kode                | 4,306 s      | neuspeshno                                                                                                        |
| [root] Diagnostika latinskikh obyyavlenij v zatronutom kode              | 4,676 s      | uspeshno                                                                                                          |
| [root] TDD-red: analitika nezavershyonnyikh i aktivnyij test                | 25,135 s     | neuspeshno                                                                                                        |
| [root] TDD-red: samoproveryayemaya istoriya i prioritet signala            | 8,047 s      | neuspeshno                                                                                                        |
| [root] TDD-green: analitika nezavershyonnyikh i aktivnyij test              | 21,043 s     | ne zaversheno — nevernyiye nablyudeniya smoke-check: uspeshnyij smoke-check ne podtverdil polnyij uspeshnyij testovyij plan |
| [root] TDD-green: samoproveryayemaya istoriya i prioritet signala          | 7,38 s       | neuspeshno                                                                                                        |
| [root] TDD-green: polnyij poryadok i aktivnyij test                       | 19,404 s     | uspeshno                                                                                                          |
| [root] TDD-green: v2-plan tajm-aut i signal                            | 7,452 s      | uspeshno                                                                                                          |
| [root] Plan perevoda novyikh obyyavlenij analitiki                        | 0,132 s      | neuspeshno                                                                                                        |
| [root] Skorrektirovannyij plan perevoda obyyavlenij analitiki            | 0,186 s      | neuspeshno                                                                                                        |
| [root] Proverennyij plan perevoda obyyavlenij analitiki                  | 0,183 s      | uspeshno                                                                                                          |
| [root] Primeneniye perevoda obyyavlenij analitiki                        | 0,189 s      | uspeshno                                                                                                          |
| [root] Regressiya protokola otchyotov posle perevoda imyon                 | 7,205 s      | uspeshno                                                                                                          |
| [root] Regressiya sortirovki i sborsjhika analitiki posle perevoda imyon   | 25,103 s     | uspeshno                                                                                                          |
| [root] Inventarizaciya obyyavlenij posle analitiki                       | 5,172 s      | uspeshno                                                                                                          |
| [root] Diagnostika novyikh latinskikh obyyavlenij                          | 4,659 s      | uspeshno                                                                                                          |
| [root] Povtornaya inventarizaciya obyyavlenij posle aliasov importov      | 4,813 s      | uspeshno                                                                                                          |
| [root] Podtverzhdeniye neizmennogo chisla latinskikh obyyavlenij            | 4,804 s      | uspeshno                                                                                                          |
| [root] Proverka prezhnego snimka obyyavlenij pered obnovleniyem pozicij   | 4,327 s      | neuspeshno                                                                                                        |
| [root] Obnovleniye pozicionnogo snimka obyyavlenij bez rosta ostatka     | 4,302 s      | uspeshno                                                                                                          |
| [root] Proverka snimka obyyavlenij posle obnovleniya pozicij             | 4,482 s      | uspeshno                                                                                                          |
| [root] Finaljnaya regressiya sortirovki posle yazyikovoj granicyi           | 22,071 s     | uspeshno                                                                                                          |
| [root] Obnovleniye svezhesti Markdown posle analitiki testov             | 0,649 s      | uspeshno                                                                                                          |
| [root] Peresborka svezhesti grafa Obsidian posle analitiki testov       | 0,392 s      | uspeshno                                                                                                          |
| [root] Predfinaljnaya proverka snimka obyyavlenij                        | 4,466 s      | uspeshno                                                                                                          |
| [root] Predfinaljnaya proverka svezhesti Markdown                        | 0,608 s      | uspeshno                                                                                                          |
| [root] Predfinaljnaya proverka svezhesti grafa Obsidian                  | 0,403 s      | uspeshno                                                                                                          |
| [root] Predfinaljnaya proverka probelov diff                            | 0,079 s      | uspeshno                                                                                                          |
| [root] Polnyij smoke-check repozitoriya                                  | 1620,682 s   | neuspeshno                                                                                                        |
| [root] Diagnostika mashinno-lokaljnogo puti posle polnogo progona       | 12,332 s     | uspeshno                                                                                                          |
| [root] Regressiya smoke-check posle ustraneniya mashinnogo puti           | 19,215 s     | uspeshno                                                                                                          |
| [root] Regressiya otchyotov posle ustraneniya mashinnogo puti               | 7,195 s      | uspeshno                                                                                                          |
| [root] Povtornaya proverka mashinno-lokaljnyikh putej                      | 12,476 s     | uspeshno                                                                                                          |
| [root] Inventarizaciya obyyavlenij posle ispravleniya mashinnyikh putej      | 4,604 s      | uspeshno                                                                                                          |
| [root] Obnovleniye pozicionnogo snimka posle ispravleniya mashinnyikh putej | 4,234 s      | uspeshno                                                                                                          |
| [root] Proverka snimka obyyavlenij posle ispravleniya mashinnyikh putej     | 4,2 s        | uspeshno                                                                                                          |
| [root] Tikhoye podtverzhdeniye mashinno-lokaljnyikh putej                     | 11,851 s     | uspeshno                                                                                                          |
| [root] Proverka diff posle ustraneniya mashinnyikh putej                   | 0,046 s      | uspeshno                                                                                                          |
| [root] Povtornyij polnyij smoke-check repozitoriya                        | 1608,091 s   | neuspeshno                                                                                                        |
| [root] Itogovyij polnyij smoke-check repozitoriya                         | 1657,026 s   | uspeshno                                                                                                          |

Obsjheye vremya pryamyikh zapuskov proverok: 5379,016 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Pervyiye TDD-red-progonyi dokazali otsutstviye sortirovki i v2-nablyudenij; usilennyiye krasnyiye progonyi otdeljno zakrepili obyazateljnostj tochnogo plana i konverta.
- Itogovyij avtonomnyij nabor obsjhego smoke-check proshyol `56` testov, vklyuchaya izvestnyiye otkazyi do issledovateljskogo bloka, izvestnyij khvost bez nablyudavshikhsya oshibok, korotkij test pri ravnom riske, avarijnyiye signalyi, uchyot nezavershyonnogo i cenzurirovaniye vneshnego preryivaniya.
- Itogovyij avtonomnyij nabor otchyotov o zapuskakh proshyol `39` testov, vklyuchaya tochnoye raspoznavaniye smoke-komandyi, samoproveryayemyiye plan i prefiks, rannij otkaz podgotovki, tajm-aut tekusjhego testa, prioritet signala nad oshibkoj konverta i samostoyateljnyij otkaz zapisi pri narushenii ostanovki posle oshibki.
- Avtomatizaciya perevoda obyyavlenij podtverdila, chto istoricheskij latinskij ostatok ne vyiros i sokhranilsya na urovne `43 336`; snimok obnovlyon toljko iz-za izmenivshikhsya pozicij i povtorno proveren.
- Rezhim `--list` uspeshno postroil polnyij fakticheskij plan repozitoriya i strogo proveril vse susjhestvuyusjhiye zakryityiye snimki. Poskoljku prezhniye zapisi imeyut skhemu v1, poryadok etoj sessii zakonomerno byil kholodnyim startom; yeyo zakryityij v2-snimok stal pervoj dostupnoj istoriyej i budet neposredstvenno primenyon sleduyusjhim zapuskom pri sortirovke testov.
- Itogovyij polnyij smoke-check stal poslednim pryamyim proverochnyim vyizovom i proshyol vse `76` shagov; yego rezuljtat vklyuchyon v zakryityij upravlyayemyij blok vyishe.
- Posle zakryitiya snimka vne profilya uspeshno vyipolnenyi strogaya proverka otchyota, svyaznostj rabochej sessii, recency-proverki, proverka snimka obyyavlenij i `git diff --check` bez otkryitiya novogo zhurnala zapuskov.

## Resheniya i ogranicheniya

- Chastota oshibok pervichna, a dliteljnostj ispoljzuyetsya toljko dlya razresheniya ravnoj chastotyi. Otnosheniye `частота / длительность` ne primeneno, potomu chto ono moglo byi postavitj boleye nadyozhnyij test pered meneye nadyozhnyim i narushitj trebuyemuyu monotonnostj veroyatnosti uspekha.
- Nabor bez uchtyonnoj istorii obrazuyet issledovateljskij blok mezhdu izvestnyimi otkazami i izvestnyim khvostom bez nablyudavshikhsya oshibok: otsutstviye nablyudenij ne yavlyayetsya ni nulevoj, ni maksimaljnoj chastotoj oshibok. Yego mesto vnutri bloka opredelyayetsya stabiljnyim repo-relative POSIX-klyuchom.
- V chastotu i srednyuyu dliteljnostj vkhodyat `успешно`, `неуспешно` i `не завершено`; dva poslednikh statusa obrazuyut nablyudayemyij neuspekh. Yestestvennyij avarijnyij signal testovogo processa otnositsya k neuspekhu, a vneshneye `прервано` — k cenzurirovannomu iskhodu. Nedostignutyiye shagi ne zapisyivayutsya.
- Vremennyij konvert soderzhit sformirovannyij uporyadochennyij plan, fakticheskij prefiks i tekusjhij test, no nakhoditsya vne repozitoriya i udalyayetsya obyortkoj. Vlozhennyiye testyi ne nasleduyut capability-peremennyiye. V v2-zapisj perenosyatsya i plan, i proverennyij prefiks nablyudenij.
- Analitika perestavlyayet toljko nezavisimyiye testovyiye naboryi. Otnositeljnyij poryadok sborok, lint, generacii i validacii reyestrov, recency i svyaznosti ostayotsya fiksirovannyim.
- Nablyudayemaya chastota yavlyayetsya empiricheskoj i na maloj vyiborke mozhet byitj shumnoj. Sglazhivaniye, okno davnosti i minimaljnyij razmer vyiborki ne vvodilisj, chtobyi tochno vyipolnitj zapros i ne skryivatj nablyudavshiyesya iskhodyi; eti politiki mozhno dobavitj otdeljnyim versionirovannyim resheniyem posle nakopleniya istorii.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 15:08:22 MSK -->
<!-- content-sha256: sha256:4576e7facc55a95e7a92f58a210497a4d6f75cefd42e0cf04c1e9ee77d2960f3 -->
<!-- FUM-MD-RECENCY:END -->
