# Otchyot 2026-08-03 18:46:53 MSK - Dobavitj izolirovannyij pishusjhij poduzel i kandidatnyij commit

V proveryayemyij mnogoagentnyij Swift-kontur dobavlen `WritingSubnodeExecutor`, kotoryij ispolnyayet odin uzhe proverennyij WorkPackage v1 v otdeljnom klone ot tochnogo `base_oid`. Tipizirovannyij zapros svyazyivayet zapusk s epizodom, pokoleniyem shaga, kartochkoj, poduzlom i repozitoriyem, zadayot celevoj ref i konechnyij nabor determinirovannyikh zapisej. Pered pervoj zapisjyu v kandidatnyij checkout ispolnitelj povtoryayet predpuskovuyu proverku khyeshej obyazateljnyikh vkhodov, oblasti, isklyuchenij, zavisimostej, proverok, marshruta peredachi i byudzhetov paketa.

Dlya zapuska rezerviruyetsya otdeljnoye ustojchivoye prostranstvo, sozdayotsya klon bez lokaljnyikh hardlink i alternates, udalyayetsya iskhodnyij remote i proveryayetsya nezavisimostj Git directory i common-dir. Pered klonirovaniyem zakryivayutsya ispolnyayemyiye i setevyiye nastrojki lokaljnoj Git-konfiguracii, a istochnik poluchayet polnyij pobajtovyij snimok vmeste s HEAD, indeksom, refs i dostizhimyimi obyyektami. Ispolnitelj naznachayet unikaljnyiye polnyiye branch ref i result ref, dopuskayet toljko obyichnyiye fajlyi vnutri `listed_paths_only`, povtorno sveryayet fakticheskij staged diff i vyipolnyayet toljko zakryityiye deklarativnyiye proverki, chji specifikacii vkhodyat v khyesh zaprosa.

Fajlovyij audit predshestvuyet Git-komandam nad istochnikom i vosstanovlennyim klonom: `.git` ne mozhet byitj ssyilkoj i ne soderzhit FIFO ili drugikh specialjnyikh obyyektov, config chitayetsya cherez `O_NOFOLLOW | O_NONBLOCK`, a yego klyuchi sveryayutsya s zakryityim spiskom. Krupnyij bezopasnyij config podayotsya Git v otdeljnom sistemnom potoke pri odnovremennom chtenii vyivoda, poetomu zapolneniye dvukh pipe ne obrazuyet vzaimnoj blokirovki. Vosstanovleniye takzhe otvergayet ssyilochnyiye komponentyi `runs`, izmenyonnuyu kvitanciyu, annotated tag vmesto pryamogo commit ref i konfiguraciyu filter ili `alternateRefsCommand` do vozmozhnogo vneshnego processa.

Kanonicheskij pasport svyazyivayet tochnyiye bajtyi paketa i preflight-otchyota, snimok istochnika, ustojchivyiye identifikatoryi, commit, tree i roditelya, oba refs, vkhodyi, zavisimosti, byudzhetyi, fakticheskiye puti i khyesh diff, proverki, ogranicheniya i podgotovlennyij, no ne prinyatyij i ne opublikovannyij marshrut peredachi. Mashinnyiye puti ostayutsya vo vneshnem runtime-kontekste. Oba refs publikuyutsya odnoj Git-tranzakciyej; pasport i kvitanciya iskhoda fiksiruyutsya atomarno cherez eksklyuzivnoye pereimenovaniye. Tochnyij povtor uspeshnogo `run_id` ne doveryayet odnomu fajlu: on zanovo proveryayet pasport, klon, direct refs, commit, tree, roditelya, scope, obyazateljnyiye artefaktyi i diff. Oborvannaya popyitka vozobnovlyayetsya v novom klone, a prezhnij klon sokhranyayetsya kak diagnosticheskij artefakt.

Otricateljnyiye scenarii razlichayut `no-op`, blokirovku do zapisi, vyikhod za razreshyonnuyu oblastj i Git-metadannyiye, gryaznyij istochnik, izmenivshijsya vkhod, sekret, publikacionnyij otkaz, proval proverki, smenu bazyi i konflikt zapuska. Ustojchivyiye kvitancii sokhranyayut tot zhe otricateljnyij iskhod pri tochnom povtore; iskusstvennyij commit ili result ref ne sozdayutsya. Iskhodnyij checkout vo vsekh proverennyikh scenariyakh ostayotsya neizmennyim po polnomu pobajtovomu inventaryu, HEAD, simvolicheskomu HEAD, statusu, refs, dostizhimyim obyyektam i indeksu.

FUM-STEP-0085 zavershena i udalena iz whitelist `master`. Yedinstvennyim vyichislennyim gotovyim prodolzheniyem stala FUM-STEP-0086, kotoraya otdeljno dobavit CAS-integraciyu beskonfliktnogo kandidata. Tekusjhaya postavka ne integriruyet kandidatnyij commit, ne vyipolnyayet push, ne zapuskayet modelj ili setevoj servis i ne podklyuchayet subagentov obsjhej rabochej kopii k novomu ispolnitelyu.

## Iskhodnyij zapros

- [zapros](zapros.md)

## Profilj vremeni vyipolneniya

| Stadiya                                       | Dliteljnostj  | Granicyi i sposob izmereniya                                                                                       |
| -------------------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO                        | ne izmereno   | Ot registracii kornevoj zadachi do podtverzhdyonnogo dopuska; interval ne vosstanavlivayetsya zadnim chislom           |
| Kontekstnyij preflight, realizaciya i revjyu    | ne izmereno   | Ot podtverzhdeniya naznacheniya do zaversheniya realizacii, dokumentacii i razdelyonnyikh read-only-auditov               |
| Celevyiye proverki                             | 1060,077728 s | Summa otdeljnyikh zavershivshikhsya pryamyikh zapuskov nizhe; prervannyiye processyi bez sokhranyonnoj granicyi v summu ne vkhodyat |
| Predkommitnoye zamyikaniye i polnyij smoke-check | 997,60 s      | Dva cikla recency i grafa, ispravlennyij formaljnyij otkaz svyaznosti, yeyo uspeshnyij povtor i polnyij smoke-check       |

Granica profilya: nachalo — registraciya kornevoj zadachi i ozhidaniye FIFO; konec proveryayemoj stadii — uspeshnyij polnyij smoke-check. Lokaljnyij atomarnyij commit+handoff vyipolnyayetsya posle zamyikaniya otchyota i ne vklyuchayetsya v izmerennyij profilj. Dliteljnosti paralleljnyikh stadij ne skladyivayutsya kak kalendarnoye vremya.

### Pryamyiye zapuski proverok

| Vyizov                                                    | Dliteljnostj | Rezuljtat                                                                                                           |
| -------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------- |
| iskhodnyij red-test otsutstvuyusjhego API                     | 3,945416 s   | neuspeshno — ozhidayemyij TDD-red ostanovilsya na otsutstvii novogo API                                                  |
| promezhutochnaya kompilyaciya posle poyavleniya API             | 4,909707 s   | neuspeshno — vyiyavlena i zatem ispravlena oshibka fiksturyi `baseOID`                                                   |
| adresnyij polozhiteljnyij scenarij                          | 7,504466 s   | uspeshno — odin test proshyol posle ispravleniya fiksturyi                                                               |
| iskhodnyij adresnyij nabor                                  | 5,399 s      | uspeshno — proshli 6 testov `WritingSubnodeExecutorTests`                                                             |
| formatirovaniye i povtor iskhodnogo nabora                 | 8,341397 s   | uspeshno — formatirovaniye i povtor 6 testov zavershilisj                                                              |
| iskhodnaya proverka reyestra planirovaniya                   | 0,140722 s   | uspeshno — sokhranyonnyij reyestr sootvetstvuyet iskhodnyim kartochkam i trebovaniyam                                         |
| iskhodnaya validaciya rabochego nabora                       | 0,502403 s   | uspeshno — podtverzhdenyi 13 kandidatov i yedinstvennaya gotovaya FUM-STEP-0086                                           |
| iskhodnoye vyichisleniye sleduyusjhego shaga                      | 0,511935 s   | uspeshno — vyibran `master-fum-step-0086-automatic-v3`                                                                |
| iskhodnyij snapshot-test sleduyusjhego shaga                   | 1,276595 s   | uspeshno — snimok soglasovan s perekhodom FUM-STEP-0085 → FUM-STEP-0086                                              |
| promezhutochnyij `git diff --check`                         | 0,100 s      | uspeshno — zavershilsya meneye chem za okruglyonnuyu verkhnyuyu granicu                                                       |
| iskhodnyij strogij Swift-format lint                       | 1,286139 s   | uspeshno — iskhodniki sootvetstvuyut centraljnoj konfiguracii                                                          |
| iskhodnaya strogaya Swift-sborka                            | 5,229948 s   | uspeshno — paket sobran s polnoj proverkoj konkurentnosti i warnings-as-errors                                       |
| iskhodnyij polnyij Swift-nabor                              | 349 s        | uspeshno — proshli 35 + 82 testa; znacheniye okrugleno                                                                  |
| rasshirennyij adresnyij nabor                               | 8,79 s       | uspeshno — proshli 6 testov posle pervogo hardening                                                                  |
| pervaya sborka otdeljnogo pasportnogo probe               | 3,36 s       | neuspeshno — obnaruzhena i ispravlena oshibka kompilyacii novogo produkta                                               |
| adresnyij nabor s otdeljnyim probe                         | 6,48 s       | uspeshno — proshli 8 testov                                                                                           |
| adresnyij nabor vosstanovleniya                            | 8,24 s       | uspeshno — proshli 9 testov                                                                                           |
| formatirovaniye iz nevernogo kataloga                     | 0,05 s       | neuspeshno — obnaruzhen neverno vyibrannyij rabochij katalog                                                             |
| rekursivnoye Swift-formatirovaniye                         | 1,47 s       | uspeshno — novyiye iskhodniki i testyi otformatirovanyi                                                                   |
| povtornyij strogij Swift-format lint                      | 1,48 s       | uspeshno — formatirovaniye podtverzhdeno                                                                              |
| strogaya sborka pasportnogo probe                         | 3,50 s       | uspeshno — otdeljnyij process vosstanovleniya sobran                                                                  |
| adresnaya proverka novogo recovery-guard                  | 6,40 s       | neuspeshno — test vyiyavil nepolnuyu proverku vosstanovleniya, zatem zasjhita usilena                                      |
| povtor nabora vosstanovleniya                             | 7,21 s       | uspeshno — proshli 9 testov posle ispravleniya                                                                        |
| nabor s proverkoj podmenyonnogo pasporta                  | 9,77 s       | uspeshno — proshli 10 testov                                                                                          |
| pervaya publikacionnaya proverka hardening                 | 11,51 s      | neuspeshno — skaner obnaruzhil mashinno-lokaljnyiye testovyiye literalyi, zatem politika utochnena                           |
| povtor nabora s podmenyonnyim pasportom                    | 10,00 s      | uspeshno — proshli 10 testov                                                                                          |
| Swift-formatirovaniye posle hardening                     | 1,41 s       | uspeshno — formatirovaniye zaversheno                                                                                 |
| nabor s ispolnyayemoj Git-konfiguraciyej                    | 10,00 s      | uspeshno — proshli 11 testov                                                                                          |
| povtor publikacionnogo skanera                           | 11,34 s      | neuspeshno — vyiyavlenyi ostavshiyesya fiksturyi putej, zatem reyestr rasshiren                                               |
| diagnosticheskij zapusk filjtrovannogo skanera            | 11,29 s      | neuspeshno — podtverdil proiskhozhdeniye ostavshikhsya sovpadenij                                                          |
| unit-testyi publikacionnogo skanera                       | 1,77 s       | uspeshno — proshli 29 testov                                                                                          |
| Swift-formatirovaniye posle obnovleniya skanera            | 1,38 s       | uspeshno — formatirovaniye zaversheno                                                                                 |
| strogij Swift-format lint posle obnovleniya skanera       | 1,38 s       | uspeshno — formatirovaniye podtverzhdeno                                                                              |
| strogaya Swift-sborka posle obnovleniya skanera            | 4,65 s       | uspeshno — paket sobran                                                                                              |
| povtor adresnogo nabora Git-konfiguracii                 | 10,78 s      | uspeshno — proshli 11 testov                                                                                          |
| Swift-formatirovaniye pered testami specialjnyikh fajlov    | 1,50 s       | uspeshno — formatirovaniye zaversheno                                                                                 |
| nabor s FIFO i simvoljnyimi ssyilkami                      | 14,81 s      | uspeshno — proshli 13 testov                                                                                          |
| publikacionnyij skaner posle novyikh fikstur                | 11,42 s      | neuspeshno — novyiye mashinno-lokaljnyiye literalyi potrebovali tochnyikh policy-zapisej                                      |
| Swift-formatirovaniye pered proverkoj boljshogo config     | 1,44 s       | uspeshno — formatirovaniye zaversheno                                                                                 |
| Swift-formatirovaniye posle ustraneniya pipe-blokirovki    | 1,52 s       | uspeshno — formatirovaniye zaversheno                                                                                 |
| izolirovannyij test krupnogo bezopasnogo config           | 9,37 s       | uspeshno — zapisj 12 000 klyuchej ne blokiruyet odnovremennoye chteniye vyivoda                                            |
| finaljnyij adresnyij nabor                                 | 12,44 s      | uspeshno — proshli 16 testov `WritingSubnodeExecutorTests`                                                           |
| finaljnyij polnyij Swift-nabor                             | 345,39 s     | uspeshno — proshli 35 XCTest, 82 XCTest i 16 Swift Testing                                                           |
| finaljnyij strogij Swift-format lint                      | 1,58 s       | uspeshno — formatirovaniye podtverzhdeno                                                                              |
| finaljnaya strogaya Swift-sborka                           | 3,13 s       | uspeshno — paket sobran s polnoj proverkoj konkurentnosti i warnings-as-errors                                       |
| finaljnyiye unit-testyi publikacionnogo skanera             | 1,85 s       | uspeshno — proshli 30 testov                                                                                          |
| proverka ustarevshego reyestra                             | 0,25 s       | neuspeshno — ozhidayemo obnaruzheno izmeneniye kartochki FUM-STEP-0085                                                    |
| finaljnaya validaciya rabochego nabora                      | 0,57 s       | uspeshno — podtverzhdenyi 13 kandidatov i yedinstvennaya gotovaya FUM-STEP-0086                                           |
| finaljnoye vyichisleniye sleduyusjhego shaga                     | 0,59 s       | uspeshno — vyibran `master-fum-step-0086-automatic-v3`                                                                |
| oshibochnyij vyizov unittest bez discover                    | 0,04 s       | neuspeshno — ispravlen sposob zapuska nabora                                                                         |
| peresborka reyestra planirovaniya                          | 0,27 s       | uspeshno — reyestr vosproizvodimo peresobran                                                                          |
| finaljnaya proverka reyestra                               | 0,27 s       | uspeshno — sokhranyonnyij reyestr sootvetstvuyet iskhodnyim materialam                                                      |
| polnyij nabor sleduyusjhego shaga vetki                       | 121,93 s     | uspeshno — proshli 134 testa                                                                                          |
| finaljnyij publikacionnyij skaner                          | 11,26 s      | uspeshno — mashinno-lokaljnyiye puti i sekretyi ne obnaruzhenyi                                                            |
| finaljnyij `git diff --check`                             | 0,04 s       | uspeshno — probeljnyikh oshibok net                                                                                     |

Obsjheye vremya pryamyikh zapuskov proverok: 1060,077728 s.

Chetyire diagnosticheskikh processa ne vkhodyat v summu, potomu chto ikh vremennaya granica ne sokhranilasj: dva adresnyikh processa byili prervanyi posle obnaruzheniya vzaimnoj blokirovki pipe pri krupnom config, odin polnyij Swift-nabor i odin snapshot-zapusk vetki byili ostanovlenyi posle utratyi instrumentaljnogo kanala. Prichinyi sokhranenyi, vzaimnaya blokirovka ispravlena, a oba nabora zatem uspeshno povtorenyi.

### Predkommitnoye zamyikaniye

Pervyij cikl obnovleniya recency i grafa zanyal 0,52 s i 0,34 s. Pervaya 14,89-sekundnaya proverka svyaznosti zakryilasj formaljnyim otkazom: ona obnaruzhila istoricheskij lishnij simvol v zagolovke zaprosa, nekanonicheskij zagolovok tekusjhego otchyota i nedopustimoye razmesjheniye neizmerennyikh processov v chislovoj tablice. Posle ispravleniya povtornyiye recency i graf zanyali 0,53 s i 0,32 s, a svyaznostj uspeshno proshla za 20,52 s. Polnyij smoke-check zatem proshyol 71 shag za 960,420 s vnutrennego izmereniya i 960,48 s vneshnego wall-clock. Profilj stadii ispoljzuyet vneshnyuyu dliteljnostj polnogo zapuska i sostavlyayet 997,60 s.

## Proverki

- Finaljnyiye 16 testov `WritingSubnodeExecutorTests` pokryivayut uspeshnyij commit, `no-op`, tipizirovannyiye pre-commit-otkazyi, izmeneniye vkhoda posle verifikacii, zakryityiye deklarativnyiye proverki, idempotentnyij povtor i konflikt odnogo `run_id`, vozobnovleniye oborvannoj popyitki, vosstanovleniye v novom processe, ispolnyayemuyu Git-konfiguraciyu, boljshoj bezopasnyij config, annotated tag, izmenyonnuyu kvitanciyu, simvoljnyiye ssyilki i FIFO.
- Polozhiteljnyij scenarij proveryayet yedinstvennogo pryamogo roditelya, tochnyiye refs, tree, diff i soderzhimoye, dva nezavisimyikh zapuska, vosstanovleniye kanonicheskogo pasporta otdeljnyim bezokonnyim processom i otsutstviye vremennogo mashinnogo puti v pasportnyikh bajtakh. Otricateljnyiye scenarii proveryayut POSIX-, Windows- i home-puti, sekretyi, zapresjhyonnuyu oblastj i Git-metadannyiye, gryaznyij istochnik, smenu vkhoda, proval proverki, byudzhetyi, isklyucheniya, predeljnyiye ref i puti.
- Kazhdyij scenarij sravnivayet polnyij pobajtovyij i obyyektnyij snimok iskhodnogo repozitoriya posle ispolneniya; otricateljnyiye iskhodyi dopolniteljno podtverzhdayut otsutstviye dangling candidate commit i result ref, a tochnyij povtor sveryayet neizmennostj vsego execution root.
- Mashinnyij planovyij sloj perevedyon s zavershyonnoj FUM-STEP-0085 na yedinstvennuyu gotovuyu FUM-STEP-0086; reyestr, rabochij nabor i snapshot-test proshli adresnyiye proverki.
- Finaljnyij polnyij Swift-nabor proshyol 35 XCTest, 82 XCTest i 16 Swift Testing; dopolniteljno proshli strogiye formatirovaniye i sborka, 30 unit-testov publikacionnogo skanera, 134 testa sleduyusjhego shaga vetki, finaljnyij publikacionnyij skaner i `git diff --check`.
- Yedinyij predkommitnyij smoke-check proshyol vse 71 shaga: testyi lokaljnyikh avtomatizacij, desyatj SwiftPM-manifestov, testyi, produktyi i lint prototipov, strukturu sessij, reyestryi, Git-zavisimostj, publikacionnuyu chistotu, README, voprosyi, recency, graf i svyaznostj tekusjhej sessii.

## Resheniya i ogranicheniya

- Ispolnitelj prinimayet toljko odin konechnyij proverennyij paket i ne vyidayotsya za paralleljnyij runtime neskoljkikh pishusjhikh poduzlov.
- Putj klona, putj khranilisjha pasportov i drugiye mashinno-lokaljnyiye znacheniya ostayutsya vo vneshnem kontekste i ne vkhodyat v sokhranyayemyij pasport.
- Ustojchivyij result ref sokhranyayet kandidat dostupnyim dlya sleduyusjhego shaga, no sostoyaniye `prepared` ne oznachayet prinyatiye, integraciyu ili publikaciyu.
- Serializovannaya CAS-integraciya, razresheniye konfliktov, dolgovechnyij fork-poduzel, proyektnyij submodule i skvoznaya priyomka ostayutsya otdeljnyimi kartochkami FUM-STEP-0086–FUM-STEP-0090.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, analiz, realizaciya, revjyu i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch`, `update_plan` i `collaboration.*` — lokaljnyiye processyi, proveryayemyiye pravki, rabochij plan i razdelyonnyiye realizacionnyiye i read-only-zadachi; versii kontraktov otdeljno ne raskryivayutsya.
- Swift, SwiftPM, Git, Python 3, ripgrep i standartnyiye sistemnyiye komandyi — realizaciya, lokaljnyiye Git-fiksturyi, sborka, testyi, generatoryi i inspekciya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-struktura-papok-zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-revjyu-prodelannoj-rabotyi](../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-proverka-mashinno-lokaljnyikh-putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — FIFO, podtverzhdeniye naznacheniya, moskovskoye vremya, pamyatj sessii, planirovaniye, revjyu, publikacionnaya chistota, recency, graf, svyaznostj i itogovaya priyomka.

## Istochniki

- [tekusjhij iskhodnyij zapros](zapros.md)
- [zavershyonnaya kartochka FUM-STEP-0085](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0085-dobavitj-izolirovannyij-pishusjhij-poduzel-i-kandidatnyij-commit.md)
- [trebovaniye o kommitiruyemyikh vkladakh pishusjhikh poduzlov](../../Trebovaniya/✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [proveryayemyij mnogoagentnyij kontur](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:586ac62e58bfda402c9fecbf16eaf3b04c8afeb9e0a4577f55175cfbb2bc8176 -->
<!-- FUM-MD-RECENCY:END -->
