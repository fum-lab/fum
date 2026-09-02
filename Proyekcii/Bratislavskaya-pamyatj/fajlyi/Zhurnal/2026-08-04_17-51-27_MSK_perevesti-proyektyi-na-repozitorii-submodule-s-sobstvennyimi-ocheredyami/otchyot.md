# Otchyot 2026-08-04 17:51:27 MSK - Perevesti proyektyi na repozitorii submodule s sobstvennyimi ocheredyami

V proveryayemom mnogoagentnom SwiftPM-konture poyavilsya avtonomnyij marshrut samostoyateljnogo proyekta kak otdeljnogo Git-repozitoriya. Fikstura sozdayot toljko vremennyiye lokaljnyiye bare-repozitorii proyekta i roditeljskoj kompozicii, a v dochernem commit sokhranyayet svyazannyij s `README.md` zakryityij mashinnyij `Паспорт-проекта.json`, sobstvennyiye `AGENTS.md`, shtatnyiye scenarii ocheredi i sleduyusjhego shaga, kartochku i rabochij nabor skhemyi `5`.

Pasport zakreplyayet celj, identichnosti proyekta i repozitoriya, ustojchivyij adres, polnyij ref, granicyi dostupa i publikacii, istochniki, proverki, usloviye zaversheniya i puti upravlyayusjhego sloya. On namerenno ne soderzhit OID vklyuchayusjhego commit. Tochnaya prinyataya reviziya khranitsya toljko v roditeljskoj registracii `Проекты/регистрации/самостоятельный.json` i gitlink dereva rezhima `160000`. Registraciya proveryayetsya kak zakryityij JSON-kontrakt: povtornyiye ili neizvestnyiye klyuchi na urovnyakh obolochki, proyekta, marshruta i vlozhennyikh submodule otklonyayutsya, a znacheniya `base_oid`, rezhimov snimka i pisatelya, proverok i marshruta peredachi sveryayutsya soderzhateljno.

Proyektnyij i roditeljskij checkout odnovremenno prokhodyat sobstvennyiye shtatnyiye `validate`, `show`, `claim`, `join`, `bind-run`, `verify-run`, `rearm` i chistoye zaversheniye. Ikh Git common-dir, queue-ref i claim-ref razlichayutsya; sluzhebnyiye refs ne poyavlyayutsya v bare-repozitoriyakh. Odin proyektnyij shag sozdayot neposredstvennyij commit toljko v otdeljnom zhivom klone i tochnyim CAS prodvigayet proyektnyij ref, ne menyaya roditelj.

Posle proverki otdeljnyij integracionnyij klon roditelya sozdayot odnoroditeljskij CAS-kommit, kotoryij soglasovanno menyayet toljko gitlink i registracionnuyu zapisj. Zatem zhivoj ref proyekta namerenno prodvigayetsya yesjhyo odnim neprinyatyim dochernim commit. Svezhij parent-only clone do materialization po-prezhnemu chitayet prezhnij prinyatyij OID, a yavnaya nerekursivnaya inicializaciya vosstanavlivayet chistyij detached-snimok imenno na nyom. Tem samyim otsutstviye materialized submodule ne pozvolyayet podmenitj sokhranyonnuyu reviziyu tekusjhej vershinoj zhivoj vetki.

Semj otricateljnyikh scenariyev razdeljno zakryivayut obyichnyij katalog vmesto gitlink, otsutstviye pasporta ili sleduyusjhego shaga, obsjhij checkout, nevernyij gitlink, cikl i nedostupnuyu publikacionnuyu granicu bez neozhidannogo dvizheniya roditeljskogo ref. Cikl i nesovmestimyij dostup trebuyut tochnyikh kodov `repository_cycle` i `incompatible_access`, poetomu postoronnij obsjhij otkaz ne schitayetsya dokazateljstvom nuzhnoj granicyi. Dva nezavisimyikh progona polozhiteljnoj fiksturyi dayut pobajtovo odinakovyij kanonicheskij otchyot bez vremennogo puti ili `file`-URL.

Kartochka FUM-STEP-0089 zavershena i udalena iz rabochego nabora `master`. Posle pereschyota 13 kandidatov yedinstvennoj runtime-`ready` stala FUM-STEP-0090; shestj avtomaticheskikh prodolzhenij zhdut zaversheniya zavisimostej, pyatj shirokikh prodolzhenij yavno priostanovlenyi, a FUM-STEP-0105 ostayotsya `blocked`. Postavka ne sozdayot nastoyasjhij proyekt, submodule, vneshnij remote, setevoj dostup ili publikaciyu i ne vyidayotsya za sovmestnuyu skvoznuyu priyomku proyekta s dolgovechnyim fork-poduzlom.

## Iskhodnyij zapros

- [zapros](zapros.md)

## Profilj vremeni vyipolneniya

| Stadiya                                    | Dliteljnostj   | Granicyi i sposob izmereniya                                                                                    |
| ----------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO                     | 0,000 s        | Ocheredj dopustila kornevuyu zadachu neposredstvenno posle atomarnoj registracii                                 |
| Kontekstnyij preflight, realizaciya i revjyu | ne izmereno    | Ot podtverzhdeniya naznacheniya do zaversheniya koda, dokumentacii, planirovaniya i dvukh nezavisimyikh revjyu           |
| Pryamyiye celevyiye proverki do polnogo smoke  | 2599,8160034 s | Summa vsekh otdeljnyikh strok tablicyi pryamyikh zapuskov na tekusjhej granice                                         |
| Polnyij smoke-check                        | 1503,190 s     | Tretij polnyij progon uspeshno proshyol vse 73 etapa obsjhego regressionnogo kontura                                |
| Atomarnyij commit+handoff                  | ne izmereno    | Poslednyaya lokaljnaya Git-tranzakciya obsjhej ocheredi posle ostanovki vsekh sposobnyikh pozdneye zapisatj ispolnitelej |

Granica profilya: nachalo — atomarnaya registraciya kornevoj zadachi; tekusjhij chislovoj konec — uspeshnyij polnyij smoke-check iz 73 etapov. Posleduyusjheye samosoglasovannoye zamyikaniye otchyota, recency, grafa i soobsjheniya kommita uchityivayetsya otdeljnyimi pryamyimi strokami do poslednej ustojchivoj granicyi; finaljnyij neizbezhno samossyilochnyij prokhod sluzhebnogo zamyikaniya vyipolnyayetsya posle fiksacii chisel i ne pribavlyayetsya povtorno. Neizmerennyiye stadii ne vkhodyat v arifmeticheskuyu summu, a vlozhennyiye vremena testov ne pribavlyayutsya povtorno k vremeni ikh obsjhego vyizova.

### Pryamyiye zapuski proverok

Kazhdyij vyizov ukazan otdeljno, vklyuchaya ozhidayemyiye TDD-red, oshibochnyiye CLI-vyizovyi, ostanovlennyij tyazhyolyij progon i proverki, kotoryiye nashli realjnyiye defektyi.

| Vyizov                                                   | Dliteljnostj | Rezuljtat                                                                                                 |
| ------------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------- |
| iskhodnyij red-test otsutstvuyusjhego API proyektnoj fiksturyi | 3,700 s      | neuspeshno — ozhidayemyij TDD-red ostanovilsya na otsutstvuyusjhikh deklaraciyakh                                    |
| pervaya kompilyaciya realizacii                            | 3,700 s      | neuspeshno — Swift obnaruzhil oshibki rannej versii API                                                      |
| pervyij polnyij nabor novyikh testov                        | 90,000 s     | prervano — rannyaya tyazhyolaya fikstura zavisla i byila ostanovlena                                             |
| inventarj prezhnego testovogo klassa                     | 3,528 s      | uspeshno — susjhestvuyusjhij paket sobralsya bez novoj runtime-matricyi                                           |
| pervyij polozhiteljnyij scenarij                           | 22,511 s     | neuspeshno — itogovoye resheniye ostalosj otricateljnyim                                                       |
| diagnosticheskij polozhiteljnyij scenarij                  | 23,221 s     | neuspeshno — lokalizovana nevernaya proverka nematerializovannogo snimka                                    |
| pervaya otricateljnaya matrica                            | 52,435 s     | uspeshno — semj rannikh zakryityikh otkazov poluchenyi                                                           |
| polozhiteljnyij scenarij posle ispravleniya                | 22,577 s     | uspeshno — iskhodnyij local-bare roundtrip proshyol                                                            |
| pervaya kanonicheskaya vosproizvodimostj                   | 38,308 s     | uspeshno — dva otchyota sovpali pobajtno                                                                     |
| rannyaya proverka whitespace                              | 0,100 s      | uspeshno — `git diff --check` ne nashyol oshibok                                                              |
| formatirovaniye i inventarj pod russkim testovyim klassom | 7,834 s      | uspeshno — novyij klass obnaruzhen posle obyazateljnogo pereimenovaniya obyyavlenij                             |
| pervyij vyizov pereimenovaniya kartochki                    | 0,0000034 s  | neuspeshno — preflight otklonil prezhdevremenno izmenyonnyij mashinnyij status                                  |
| povtornoye pereimenovaniye kartochki                       | 0,194 s      | uspeshno — kartochka perevedena v zavershyonnoye sostoyaniye i ssyilki sinkhronizirovanyi                           |
| obnovleniye kartochechnyikh fence                            | 0,483 s      | uspeshno — khyesh i pokoleniye FUM-STEP-0090 pereschitanyi                                                       |
| rannyaya validaciya rabochego nabora                        | 0,495 s      | uspeshno — podtverzhdenyi 13 kandidatov i soglasovannyiye zavisimosti                                          |
| rannij raschyot sleduyusjhego shaga                           | 0,500 s      | uspeshno — yedinstvennoj gotovoj stala FUM-STEP-0090                                                        |
| pervaya peresborka reyestra planirovaniya                  | 0,260 s      | uspeshno — mashinnyij reyestr vosproizvodimo postroyen                                                         |
| oshibochnaya validaciya reyestra                             | 0,070 s      | neuspeshno — CLI otklonil nevernoye imya argumenta `--input`                                                 |
| ispravlennaya validaciya reyestra                          | 0,280 s      | uspeshno — postroyennyij reyestr soglasovan                                                                   |
| polnyij proyektnyij nabor do nezavisimogo revjyu            | 112,890 s    | uspeshno — proshli chetyire iskhodnyikh adresnyikh testa                                                           |
| TDD-red zakryitoj vlozhennoj registracii                  | 1,820 s      | neuspeshno — test potreboval yesjhyo otsutstvuyusjhij zakryityij razbor registracii                                 |
| pervaya kompilyaciya usilennoj registracii                 | 1,850 s      | neuspeshno — Swift otklonil throwing-vyirazheniye v korotkozamknutom operatore                                |
| vtoraya kompilyaciya usilennogo live-ref-dokazateljstva    | 1,830 s      | neuspeshno — tot zhe klass oshibki najden vo vtoroj proverke                                                 |
| adresnyij test zakryitoj registracii                      | 4,790 s      | uspeshno — lishneye vlozhennoye pole i nevernyij marshrut otklonenyi                                              |
| adresnyij live-ref-scenarij posle usileniya               | 22,170 s     | uspeshno — zhivaya vershina operezhayet prinyatyij gitlink, a snimok ostayotsya prezhnim                             |
| polnyij usilennyij proyektnyij nabor                        | 113,170 s    | uspeshno — proshli pyatj testov, polozhiteljnyij roundtrip i semj tochnyikh zakryityikh otkazov                      |
| pervyij skan mashinno-lokaljnyikh putej                     | 11,360 s     | neuspeshno — najden odin first-party-literal sistemnogo puti                                               |
| povtornyij skan mashinno-lokaljnyikh putej                  | 11,860 s     | uspeshno — putj `env` teperj vyivoditsya iz proverennogo kataloga Git runtime bez novogo isklyucheniya politiki |
| finaljnaya peresborka reyestra planirovaniya               | 0,260 s      | uspeshno — reyestr obnovlyon posle zavershyonnoj kartochki i dokumentacii                                       |
| finaljnaya validaciya reyestra planirovaniya                | 0,270 s      | uspeshno — sokhranyonnyij reyestr vosproizvodim                                                                |
| oshibochnaya validaciya selector s `--record`               | 0,070 s      | neuspeshno — CLI ne podderzhivayet yavnyij putj zapisi etim argumentom                                         |
| oshibochnyij `show` selector s `--record`                  | 0,080 s      | neuspeshno — CLI ne podderzhivayet yavnyij putj zapisi etim argumentom                                         |
| oshibochnaya validaciya selector s `--branch-ref`           | 0,080 s      | neuspeshno — read-only-komanda vyivodit aktivnuyu vetku sama                                                 |
| oshibochnyij `show` selector s `--branch-ref`              | 0,080 s      | neuspeshno — read-only-komanda vyivodit aktivnuyu vetku sama                                                 |
| ispravlennaya finaljnaya validaciya selector               | 0,640 s      | uspeshno — podtverzhdenyi 13 kandidatov, odin `ready`, 11 `paused` i odin `blocked`                          |
| ispravlennyij finaljnyij raschyot sleduyusjhego shaga           | 0,650 s      | uspeshno — FUM-STEP-0090 vyibrana yedinstvennyim gotovyim prodolzheniyem                                         |
| sverka raw-zaprosa s soobsjheniyem kommita                 | 0,020 s      | uspeshno — publikuyemoye telo iskhodnogo zaprosa sovpalo pobajtno                                             |
| slishkom shirokij skan runtime-konverta                   | 0,180 s      | neuspeshno — globaljnyij inventarj nashyol prezhniye istoricheskiye sovpadeniya i obsjhiye testovyiye literalyi          |
| tochnyij skan runtime-konverta v diff sessii              | 0,090 s      | uspeshno — v izmenyonnyikh i novyikh fajlakh nepublikuyemyiye znacheniya otsutstvuyut                                  |
| itogovaya struktura zhurnaljnyikh sessij                    | 6,310 s      | uspeshno — proverenyi 331 sessiya, 271 otchyot i 60 istoricheskikh request-only-sessij                           |
| strogij Swift-format lint paketa                        | 2,180 s      | uspeshno — `Package.swift`, iskhodniki i testyi sootvetstvuyut centraljnoj konfiguracii                       |
| povtornaya proverka whitespace                           | 0,030 s      | uspeshno — `git diff --check` ne nashyol oshibok                                                              |
| pervoye obnovleniye Markdown-recency                      | 0,560 s      | uspeshno — sluzhebnyiye metki i vremennoj indeks peresobranyi                                                  |
| pervoye obnovleniye grafa Obsidian                        | 0,330 s      | uspeshno — teplovaya karta peresobrana po aktualjnyim recency-metkam                                         |
| pervaya proverka Markdown-recency                        | 0,510 s      | uspeshno — vse sluzhebnyiye metki i vremennoj indeks aktualjnyi                                                |
| pervaya proverka grafa Obsidian                          | 0,340 s      | uspeshno — sokhranyonnaya teplovaya karta sootvetstvuyet Markdown-recency                                       |
| audit reyestra posle recency                             | 0,290 s      | uspeshno — sluzhebnyiye Markdown-metki ne narushili vosproizvodimostj planovogo reyestra                        |
| pervaya itogovaya proverka svyaznosti                      | 20,950 s     | uspeshno — zapros, otchyot, soobsjheniye kommita, ssyilki, profilj i Git-inventarj soglasovanyi                   |
| pervyij polnyij smoke-check                               | 302,060 s    | neuspeshno — etap 19 iz 73 obnaruzhil ustarevsheye ozhidaniye 14 kandidatov vmesto 13                           |
| adresnyij snapshot rabochego nabora                       | 1,470 s      | uspeshno — snapshot soglasovan s 13 kandidatami i gotovoj kartochkoj FUM-STEP-0090                          |
| preddyimnoye obnovleniye Markdown-recency                  | 0,540 s      | uspeshno — otchyot i vremennoj indeks sinkhronizirovanyi pered povtornyim obsjhim progonom                        |
| preddyimnoye obnovleniye grafa Obsidian                    | 0,320 s      | uspeshno — sokhranyonnaya teplovaya karta uzhe sootvetstvovala recency                                          |
| preddyimnaya proverka svyaznosti                           | 21,430 s     | uspeshno — snimok sessii soglasovan pered povtornyim obsjhim progonom                                         |
| vtoroj polnyij smoke-check                               | 1518,810 s   | neuspeshno — proshli 65 iz 73 etapov, etap 66 obnaruzhil novyij latinskij ostatok obyyavlenij                  |
| pervaya filjtraciya inventarya posle smoke                 | 3,900 s      | neuspeshno — `jq` otklonil obrasjheniye k kirillicheskim polyam cherez sokrasjhyonnyij sintaksis                     |
| ispravlennaya filjtraciya inventarya                       | 4,300 s      | uspeshno — lokalizovanyi 14 zapisej v tryokh novyikh Swift-fajlakh                                               |
| pervaya svodka razmera inventarya                         | 4,300 s      | neuspeshno — `jq` potreboval strokovyiye kirillicheskiye klyuchi obyyekta                                         |
| ispravlennaya svodka razmera inventarya                   | 4,600 s      | uspeshno — podtverzhdenyi 43 376 zapisej i tochnyij nabor novyikh imyon                                           |
| inventarj posle pervichnogo ustraneniya imyon              | 4,500 s      | uspeshno — ostatok suzhen do dvukh lozhnyikh parametrov i odnogo sobstvennogo sostavnogo imeni                  |
| sukhoj plan perevoda sostavnogo imeni                    | 0,200 s      | uspeshno — proverenyi dva tokena odnoj zamenyi bez izmeneniya strok                                           |
| primeneniye plana perevoda sostavnogo imeni              | 0,200 s      | uspeshno — dva tokena atomarno zamenenyi profiljnoj avtomatizaciyej                                          |
| promezhutochnaya proverka snimka obyyavlenij                | 8,600 s      | uspeshno — variant bez vneshnikh klyuchej dal nulevoj novyij ostatok i sovpal s prezhnim snimkom                 |
| pervyij strogij lint posle ustraneniya ostatka            | 2,400 s      | neuspeshno — Swift-format otklonil snake_case khranimyikh svojstv                                             |
| finaljnyij prosmotr novyikh obyyavlenij                     | 4,500 s      | uspeshno — ostalisj toljko tri obyazateljnyikh kompilyatornyikh tipa `CodingKeys`                                |
| obnovleniye i proverka snimka obyyavlenij                 | 8,700 s      | uspeshno — granica yavno obnovlena s 43 362 do 43 365 toljko na tri proverennyikh `CodingKeys`                |
| strogij lint posle vosstanovleniya vneshnikh klyuchej        | 2,400 s      | uspeshno — vesj mnogoagentnyij Swift-paket sootvetstvuyet obsjhej konfiguracii                                 |
| adresnyij povtor proyektnogo nabora                       | 120,730 s    | uspeshno — posle ispravleniya proshli vse pyatj testov i tochnyiye JSON-predstavleniya                            |

| obnovleniye Markdown-recency pered tretjim smoke | 0,580 s    | uspeshno — otchyot i vremennoj indeks sinkhronizirovanyi posle ispravleniya etapa 66              |
| obnovleniye grafa pered tretjim smoke            | 0,300 s    | uspeshno — teplovaya karta uzhe sootvetstvovala obnovlyonnyim recency-metkam                     |
| pervaya svyaznostj pered tretjim smoke            | 22,280 s   | neuspeshno — vyiyavlena otsutstvuyusjhaya ssyilka na izmenyonnyij snimok obyyavlenij                   |
| povtornoye obnovleniye Markdown-recency           | 0,550 s    | uspeshno — zapros i otchyot sinkhronizirovanyi posle dobavleniya ssyilki                           |
| povtornoye obnovleniye grafa                      | 0,320 s    | uspeshno — teplovaya karta uzhe sootvetstvovala ispravlennomu zaprosu                          |
| povtornaya svyaznostj pered tretjim smoke         | 22,110 s   | uspeshno — snimok obyyavlenij yavno pokryit perechnem zatronutyikh fajlov                          |
| tretij polnyij smoke-check                       | 1503,190 s | uspeshno — projdenyi vse 73 etapa, vklyuchaya proyektnyij paket i ispravlennuyu proverku obyyavlenij |

Obsjheye vremya pryamyikh zapuskov proverok: 2599,8160034 s.

## Proverki

- Pyatj adresnyikh XCTest ispoljzuyut nastoyasjhiye vremennyiye bare-repozitorii i otdeljnyiye klonyi; vesj polozhiteljnyij i otricateljnyij nabor rabotayet bez seti i sekretov.
- Zakryityij razbor roditeljskoj registracii proveryayet dublikatyi, tochnyiye klyuchi kazhdogo vlozhennogo obyyekta, polnyij nabor znachenij, marshrut peredachi, dostupnostj bazovogo commit i yego predkovuyu svyazj s gitlink.
- Shtatnyiye kopii ocheredi i selector zapuskayutsya iz commit kazhdogo fizicheskogo checkout. Roditeljskij kontur ostayotsya zanyatyim, poka proyekt poluchayet sobstvennyij dopusk i claim, chto isklyuchayet vyivod dochernej gotovnosti iz sostoyaniya roditelya.
- Proyektnyij CAS, otdeljnyij roditeljskij CAS i posleduyusjheye raskhozhdeniye live-ref s prinyatyim gitlink proveryayutsya po tochnyim Git-obyyektam i refs. Parent-only clone vosstanavlivayet prinyatyij OID do i posle yavnoj materialization.
- Inventarj novogo koda ne soderzhit latinskikh sobstvennyikh obyyavlenij. Tri `CodingKeys` yavlyayutsya tochnyim obyazateljnyim imenem mekhanizma Swift `Codable`; mashinnyij snimok prosmotren i uvelichen toljko na eti kompilyatornyiye obyyavleniya.
- Mashinnyij planovyij reyestr vosproizvodimo peresobran; vetochnyij selector pokazyivayet FUM-STEP-0090 yedinstvennyim gotovyim prodolzheniyem. Itogovyiye recency, graf, svyaznostj i obsjhij smoke-check zamyikayutsya pered peredachej FIFO.

## Resheniya i ogranicheniya

- Chelovekochitayemyij `README.md` i zakryityij `Паспорт-проекта.json` yavlyayutsya dvumya svyazannyimi predstavleniyami dochernego pasporta. Self-OID v dochernem commit zapresjhyon; tochnyij snimok yavlyayetsya otvetstvennostjyu roditelya.
- Roditeljskaya zapisj pereispoljzuyet versionirovannyij vid `project`, no khranit toljko kompozicionnyiye polya. Tekstovyij poisk podstrok ne ispoljzuyetsya kak granica: zakryitostj dokazyivayetsya strukturoj i znacheniyami JSON.
- Sostoyaniye ocheredi, claim i dispetchera prinadlezhit Git common-dir konkretnogo checkout i ne publikuyetsya cherez bare-repozitorij. Roditeljskij dopusk ne koordiniruyet rebyonka.
- Prinyatyij gitlink i tekusjhij live-ref namerenno mogut razlichatjsya. Vosproizvodimostj kompozicii opredelyayetsya gitlink, a ne vyiborom vershinyi vetki ili `update --remote`.
- Avtonomnaya fikstura podtverzhdayet lokaljnyij kontrakt, no ne sozdayot nastoyasjhij proyekt, ne proveryayet udalyonnyiye credentials i ne razreshayet vneshnij remote, push ili publikaciyu. Sovmestnaya priyomka s fork-konturom ostayotsya FUM-STEP-0090.

## Razdelyonnoye revjyu

Odin ispolnitelj nezavisimo proveril pokryitiye kriteriya priyomki i nashyol tri susjhestvennyikh probela: sovpadeniye live-ref s gitlink ne dokazyivalo zapret ugadyivaniya vetki, vlozhennaya registraciya dopuskala neizvestnyiye polya, a cikl i dostup prinimali lyuboj obsjhij otkaz. Posle ispravleniya tot zhe ispolnitelj podtverdil raskhozhdeniye live-ref i snimka, zakryityij strukturno-soderzhateljnyij kontrakt registracii i tochnyiye diagnosticheskiye kodyi bez ostavshikhsya blokiruyusjhikh zamechanij.

Dva drugikh ispolnitelya razdeljno sverili dokumentacionnyij kontrakt i inventarj prototipa. Ikh izmeneniya byili ogranichenyi neperesekayusjhimisya naborami fajlov, a korenj proveril itogovyij diff i soglasoval granicyi local-bare-dokazateljstva. Vse ispolniteli otnosyatsya k odnoj modeljnoj semjye; ikh soglasiye yavlyayetsya korrelirovannyim vnutrennim signalom, poetomu itog prinyat po nablyudayemyim Git-obyyektam, shtatnyim instrumentam i vosproizvodimyim testam.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, realizaciya, razdelyonnyiye revjyu i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch` i `collaboration.*` — lokaljnyiye processyi, proveryayemyiye pravki i paralleljnyiye audityi; versii kontraktov otdeljno ne raskryivayutsya.
- Git 2.54.0 (Apple Git-157), Python 3.14.6, Apple Swift 6.4, SwiftPM, XCTest, `swift format` vetki `main`, ripgrep i sistemnyiye komandyi Darwin 27.0.0 arm64 — lokaljnyiye Git-topologii, sborka, testyi, generatoryi i inspekciya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-struktura-papok-zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-proverka-mashinno-lokaljnyikh-putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — FIFO, naznacheniye, vremya, zhurnal, planirovaniye, publikacionnaya chistota, recency, graf, svyaznostj i obsjhij smoke-check.
- [fum-perevod-obyyavlenij-koda-na-russkij-yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md) — sukhoj plan i token-osoznannyij perevod novogo sostavnogo imeni, inventarizaciya i tochnyij snimok ostatka.

## Povliyal na fajlyi

- [tekusjhij iskhodnyij zapros](zapros.md)
- [tekusjhij otchyot](otchyot.md)
- [kornevyiye pravila](../../AGENTS.md)
- [kornevoj README](../../README.md)
- [glossarij repozitornoj kompozicii](../../Glossarij/repozitornaya-kompoziciya-FUM.md)
- [arkhitekturnaya dokumentaciya repozitornogo grafa](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [indeks samostoyateljnyikh proyektov](../../Proyektyi/README.md)
- [proveryayemyij mnogoagentnyij Swift-prototip](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/)
- [trebovaniye o repozitornoj kompozicii](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [planovyiye materialyi](../../Planirovaniye/)
- Udalyonnyij fajl: `Планирование/карточки-шагов/🟡-FUM-STEP-0089-перевести-проекты-на-репозитории-submodule-с-собственными-очередями.md`
- [snapshot-test sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [snimok ostatka obyyavlenij koda](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json)
- [iskhodnyij zapros o Git-grafe](../2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [predyidusjhij zapros](../2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)
- [indeks zhurnala](../README.md)
- [indeks Markdown-fajlov](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [graf Obsidian](../../../../../.obsidian/graph.json)

## Istochniki

- [tekusjhij iskhodnyij zapros](zapros.md)
- [zavershyonnaya kartochka FUM-STEP-0089](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0089-perevesti-proyektyi-na-repozitorii-submodule-s-sobstvennyimi-ocheredyami.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [proveryayemyij mnogoagentnyij kontur](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:5161c22ed454d6276e4c9c38055e097d392833ecd49c7ba4876b33036c1150f7 -->
<!-- FUM-MD-RECENCY:END -->
