# Otchyot 2026-08-03 08:48:44 MSK - Zakrepitj topologiyu i pasport repozitornoj kompozicii FUM

Rabochaya sessiya dobavila v proveryayemyij mnogoagentnyij Swift-kontur zakryityij pasport repozitornoj kompozicii versii `1`, avtonomnyij Git-preflight i lokaljnyiye bare-fiksturyi. Kontrakt razlichayet efemernuyu vetku shaga, dolgovechnyij specializirovannyij fork-poduzel i samostoyateljnyij proyekt, a gitlink proveryayet kak tochnyij commit-snimok roditeljskogo dereva nezavisimo ot ushedshego vperyod zhivogo ref.

## Rezuljtat

Skhema zakreplyayet identichnosti kompozicii i dochernikh uzlov, roditeljskij snimok, tochnyiye `base_oid` i `gitlink_oid`, polnyiye zhivyiye refs, puti submodule, urovni dostupa, publikacionnyiye granicyi, proverki i marshrut peredachi vverkh. Variantyi `step_branch`, `specialized_subnode` i `project` zakryityi dlya neprimenimyikh polej; samostoyateljnyij proyekt ne poluchayet lozhnuyu upstream-identichnostj, a efemernaya vetka — lozhnyij gitlink.

Preflight ispoljzuyet toljko read-only Git plumbing. On proveryayet nalichiye commit, tochnuyu vershinu ref, dostizhimostj ot bazyi, zapisj rezhima `160000` v dereve roditeljskogo snimka, chistyij detached checkout snimka i otdeljnyij prikreplyonnyij pishusjhij klon. Polozhiteljnaya fikstura namerenno ostavlyayet gitlink pozadi vershinyi live-ref i tem samyim dokazyivayet otsutstviye neyavnogo dvizheniya snimka.

Predfinaljnaya publikacionnaya proverka ustranila sistemnyiye absolyutyi iz first-party Swift-koda: ispolnyayemyij Git teperj razreshayetsya cherez runtime-`PATH`, izolyaciya globaljnoj konfiguracii ispoljzuyet nepublikuyemyij vremennyij putj, a `#fileID` ne raskryivayet putj kompilyatora. Lozhnoye skhodstvo JSON Pointer s POSIX-putyom snyato yedinyim protokoljnyim razdelitelem; tri nastoyasjhikh opredeleniya zapreta domashnego sokrasjheniya v polnom Git ref zakreplenyi tochnyimi fingerprint-isklyucheniyami politiki.

Semj otricateljnyikh topologij zakryivayut nesovmestimyij dostup, ssyilku dochernego submodule na predka, povtor identichnosti, povtor puti, otsutstvuyusjhuyu reviziyu, cikl i samorekursivnuyu inicializaciyu. Narusheniya dedupliciruyutsya, sortiruyutsya i vkhodyat v kanonicheskij JSON-otchyot. Bezokonnyij probnik publikuyet fiksirovannyij spisok scenariyev i vozvrasjhayet raznyiye kodyi dlya `valid`, `invalid` i oshibki komandyi.

## Planovyij perekhod

FUM-STEP-0084 perevedena v istoricheskij status i udalena iz whitelist vetki `master`. Rabochij nabor skhemyi `5` soderzhit 13 kandidatov: yedinstvennoj vyichislennoj `ready` stala FUM-STEP-0085, 11 kartochek ozhidayut tochnyikh zavisimostej, a produktovaya FUM-STEP-0105 ostayotsya `blocked` do otdeljnogo razresheniya.

Zaversheniye kontrakta ne zapuskayet pishusjhego ispolnitelya, ne sozdayot i ne integriruyet kandidatnyij commit, ne obnovlyayet nastoyasjhij gitlink, ne sozdayot vneshnij fork, samostoyateljnyij repozitorij ili resurs GitHub i ne predostavlyayet novyikh setevyikh, platnyikh ili publikacionnyikh polnomochij.

## Profilj vremeni vyipolneniya

| Stadiya                                     | Dliteljnostj | Granicyi i sposob izmereniya                                                                                        |
| ------------------------------------------ | ------------ | ----------------------------------------------------------------------------------------------------------------- |
| ozhidaniye FIFO                              | 0,400 s      | dokumentirovannyij `join` vernul `admitted` v tom zhe vyizove; otdeljnogo perioda ozhidaniya ne byilo                   |
| chteniye pravil, fenced-proverka i preflight | ne izmereno  | vyipolnenyi do ustojchivoj vremennoj granicyi soderzhateljnoj stadii; zadnim chislom dliteljnostj ne vosstanavlivalasj  |
| soderzhateljnaya rabota                      | ne izmereno  | okhvatyivayet skhemu, validator, lokaljnuyu Git-topologiyu, CLI, dokumentaciyu i planovyij perekhod                        |
| celevyiye i predfinaljnyiye proverki           | 1163,699 s   | arifmeticheskaya summa call-time pryamyikh zapuskov bez chetyiryokh polnyikh smoke-check; diagnosticheskiye chteniya ne vklyuchenyi |
| polnyij repozitornyij smoke-check            | 3809,753 s   | summa chetyiryokh polnyikh progonov: dva otkaza audita proizvodnoj pamyati, odin otkaz recency i uspeshnyiye itogovyiye 68/68 |
| atomarnaya peredacha ocheredi                 | ne izmereno  | vyipolnyayetsya posle zakryitiya otchyota; rezuljtat podtverzhdayetsya toljko tochnyim sostoyaniyem `committed`                  |

Granica profilya: ot tochnogo `join` tekusjhej kornevoj zadachi do lokaljnogo atomarnogo commit+handoff; ranneye chteniye i fenced-preflight vklyuchenyi, no ikh otdeljnaya wall-clock-dliteljnostj ne byila izmerena. Arifmeticheskaya summa pryamyikh vyizovov yavlyayetsya agregirovannyim call-time, a ne kalendarnoj dliteljnostjyu sessii.

### Pryamyiye zapuski proverok

| Vyizov                                                          | Dliteljnostj | Rezuljtat                                                                                                   |
| -------------------------------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------- |
| pervaya popyitka dinamicheskogo bootstrap ocheredi                 | 0,100 s      | neuspeshno — process zavershilsya do registracii i ne izmenil ocheredj                                          |
| tochnyij dokumentirovannyij `join`                                | 0,400 s      | uspeshno — poluchen nemedlennyij FIFO-dopusk                                                                   |
| fenced `bind-run` i `verify-run`                               | 1,700 s      | uspeshno — zapusk svyazan s tekusjhim pokoleniyem vladeljca                                                      |
| iskhodnyij krasnyij TDD-progon kontrakta kompozicii               | 5,163 s      | neuspeshno — ozhidayemo otsutstvoval novyij publichnyij API                                                       |
| proverka JSON-skhemyi, regulyarnyikh vyirazhenij i versij sredyi       | 0,064 s      | uspeshno — JSON i shablonyi korrektnyi; nablyudalisj Swift 6.4, Git 2.54.0 i Python 3.14.6                       |
| pervyij kompilyacionnyij progon posle dobavleniya fikstur          | 1,763 s      | neuspeshno — obnaruzhenyi dve lishniye escape-posledovateljnosti v strokovoj interpolyacii                        |
| vtoroj kompilyacionnyij progon posle dobavleniya fikstur          | 1,960 s      | neuspeshno — prervannyij ispolnitelj ne uspel dopisatj semanticheskuyu i Git-proverku                           |
| tretij kompilyacionnyij progon validatora                        | 1,795 s      | neuspeshno — obnaruzheno nevernoye sravneniye opcionaljnogo rezuljtata proverki origin                          |
| pervyij polnyij celevoj progon posle kompilyacii                  | 67,000 s     | prervano — progon ostanovlen posle diagnostiki medlennogo mnogokratnogo Git-preflight                       |
| celevoj progon posle sokrasjheniya lishnikh Git-proverok            | 63,090 s     | neuspeshno — vosemj testov proshli, odin vyiyavil propusjhennuyu proverku `base_oid` proyekta                       |
| adresnyij test ustojchivogo kanonicheskogo otchyota                 | 8,013 s      | uspeshno — tri nezavisimyikh narusheniya obnaruzhenyi, otsortirovanyi i vosproizvodimyi                              |
| itogovyij celevoj nabor `RepositoryCompositionContractTests`    | 62,292 s     | uspeshno — 9 iz 9 testov proshli na lokaljnyikh bare-repozitoriyakh                                               |
| pervyij CLI-progon spiska, polozhiteljnogo i otricateljnogo puti | 19,437 s     | neuspeshno — otchyotyi byili korrektnyi, no obolochka ispoljzovala zarezervirovannoye imya peremennoj                |
| povtor otricateljnogo CLI-scenariya                             | 6,069 s      | uspeshno — `repository_cycle` dal kanonicheskij `invalid` i ozhidayemyij kod `3`                                 |
| formatirovaniye i strogij lint izmenyonnyikh Swift-fajlov          | 0,275 s      | uspeshno — centraljnaya konfiguraciya ne obnaruzhila otklonenij                                                 |
| strogaya Swift 6 concurrency-sborka probnika                    | 3,962 s      | uspeshno — produkt sobran s warnings-as-errors                                                               |
| domennoye pereimenovaniye FUM-STEP-0084                          | 0,166 s      | uspeshno — status, indeks, graf, reyestr i zhivyiye ssyilki obnovlenyi specializirovannyim preflight                |
| peresborka mashinnogo planovogo reyestra                         | 0,097 s      | uspeshno — reyestr peresobran iz tekusjhikh kartochek                                                             |
| proverka svezhesti mashinnogo planovogo reyestra                  | 0,103 s      | uspeshno — reyestr sootvetstvoval tekusjhim kartochkam                                                           |
| pervaya validaciya rabochego nabora posle perekhoda                | 0,363 s      | neuspeshno — ssyilka na zavershyonnogo predshestvennika izmenila dajdzhest FUM-STEP-0085                          |
| povtornaya validaciya rabochego nabora                            | 0,453 s      | uspeshno — podtverzhdenyi 13 kandidatov: 1 ready, 11 paused i 1 blocked                                        |
| vyichisleniye sleduyusjhego kandidata vetki `master`                 | 0,451 s      | uspeshno — yedinstvennoj ready opredelena FUM-STEP-0085 s novyim pokoleniyem shaga                               |
| adresnyij polozhiteljnyij test posle kriticheskogo revjyu           | 19,046 s     | uspeshno — snimki nerekursivno vosstanovlenyi iz svezhego parent clone i otdelenyi ot pisatelej                 |
| test nablyudayemoj Git-topologii bez deklarativnyikh ryober         | 31,334 s     | uspeshno — realjnyiye predok, cikl i samorekursiya obnaruzhenyi posle sokryitiya ryober v JSON                       |
| test ustojchivosti pasporta mezhdu vremennyimi topologiyami        | 20,708 s     | uspeshno — bajtyi pasporta i otchyota sovpali, mashinno-lokaljnyiye URI i vremennyiye puti otsutstvuyut               |
| test dostupa roditelya i cepochki base-gitlink-live              | 19,941 s     | uspeshno — mezhrepozitornyij dostup i obe granicyi ancestry zakryivayutsya otkazom                                 |
| povtornoye formatirovaniye i strogij lint posle revjyu            | 0,320 s      | uspeshno — centraljnaya konfiguraciya ne obnaruzhila otklonenij                                                 |
| pervyij polnyij rasshirennyij celevoj nabor                        | 165,912 s    | neuspeshno — 11 testov proshli, odin vyiyavil prezhdevremennyij propusk semanticheskoj proverki                    |
| adresnyij povtor ustojchivogo kanonicheskogo otchyota               | 8,832 s      | uspeshno — strukturnyiye i semanticheskiye narusheniya odnovremenno sokhranenyi v otchyote                             |
| itogovyij rasshirennyij nabor kompozicii                          | 165,633 s    | uspeshno — 12 iz 12 testov proshli, vklyuchaya realjnyiye otricateljnyiye Git-derevjya                                |
| povtornaya strogaya Swift 6 concurrency-sborka                   | 3,632 s      | uspeshno — produkt sobran posle ustraneniya zamechanij revjyu                                                   |
| adresnyij test povtornogo klyucha JSON                            | 10,909 s     | uspeshno — neodnoznachnyij pasport otklonyon do zapuska Git-proverok                                            |
| finaljnoye formatirovaniye i strogij lint Swift-fajlov           | 0,535 s      | uspeshno — izmeneniya posle revjyu sootvetstvuyut centraljnoj konfiguracii                                      |
| finaljnaya strogaya Swift 6 concurrency-sborka                   | 5,879 s      | uspeshno — produkt sobran s polnoj proverkoj konkurentnosti i warnings-as-errors                             |
| finaljnyij celevoj nabor kompozicii                             | 169,354 s    | uspeshno — 13 iz 13 testov proshli, vklyuchaya povtornyij JSON-klyuch i realjnyiye otricateljnyiye Git-derevjya          |
| adresnyij test snimka rabochego nabora vetki                     | 1,361 s      | uspeshno — repozitornyij invariant podtverzhdayet 13 kandidatov i perekhod k FUM-STEP-0085                       |
| finaljnaya peresborka mashinnogo planovogo reyestra               | 0,137 s      | uspeshno — reyestr peresobran posle zamyikaniya zavershyonnoj kartochki                                            |
| finaljnaya proverka mashinnogo planovogo reyestra                 | 0,114 s      | uspeshno — sokhranyonnyij reyestr sootvetstvuyet tekusjhim kartochkam                                                |
| finaljnaya validaciya rabochego nabora                            | 0,430 s      | uspeshno — podtverzhdenyi 13 kandidatov: 1 ready, 11 paused i 1 blocked                                        |
| finaljnoye vyichisleniye sleduyusjhego kandidata `master`             | 0,463 s      | uspeshno — yedinstvennoj ready opredelena FUM-STEP-0085                                                       |
| pervichnoye obnovleniye Markdown-recency                          | 0,578 s      | uspeshno — obnovlenyi sluzhebnyiye bloki i vremennoj indeks izmenyonnyikh Markdown-fajlov                           |
| pervichnaya proverka Markdown-recency                            | 0,328 s      | uspeshno — sokhranyonnyiye bloki i vremennoj indeks sootvetstvovali soderzhaniyu                                   |
| pervichnoye obnovleniye teplovoj kartyi grafa                      | 0,155 s      | uspeshno — graf Obsidian peresobran dlya opornoj datyi 2026-08-03                                              |
| pervichnaya proverka teplovoj kartyi grafa                        | 0,154 s      | uspeshno — sokhranyonnyij graf sootvetstvoval Markdown-recency i opornoj date                                   |
| povtornoye obnovleniye Markdown-recency                          | 0,362 s      | uspeshno — zamknutyi tekusjhij zapros, zhurnal i vremennoj indeks                                                |
| povtornoye obnovleniye teplovoj kartyi grafa                      | 0,151 s      | uspeshno — graf uzhe sootvetstvoval obnovlyonnoj proizvodnoj pamyati                                            |
| pervaya proverka svyaznosti rabochej sessii                       | 14,117 s     | uspeshno — Git-sostoyaniye, ssyilki, proiskhozhdeniye, profilj i trailer soglasovanyi                               |
| pervyij polnyij repozitornyij smoke-check                         | 950,065 s    | neuspeshno — 60 shagov proshli, shag 61 vyiyavil nerazmechennyiye mashinno-lokaljnyiye literalyi                         |
| otfiljtrovannyij audit novyikh mashinno-lokaljnyikh putej            | 11,254 s     | neuspeshno — lokalizovanyi JSON Pointer, sistemnyiye runtime-puti i raskryitiye puti kompilyatora                  |
| proverka pustogo `GIT_CONFIG_GLOBAL`                           | 0,000 s      | neuspeshno — Git podtverdil, chto pustoye znacheniye ne yavlyayetsya bezopasnyim otklyucheniyem global config            |
| povtornyij audit posle pervichnogo ustraneniya putej              | 11,156 s     | neuspeshno — ostalisj tri publikuyemyiye formulirovki s mashinno-lokaljnoj URI-skhemoj                            |
| formatirovaniye i strogij lint posle ispravleniya putej          | 0,544 s      | uspeshno — mekhanicheskaya sborka JSON Pointer i runtime-refaktoring otformatirovanyi                            |
| strogaya Swift 6 concurrency-sborka posle ispravleniya putej     | 4,152 s      | uspeshno — produkt sobran bez preduprezhdenij                                                                 |
| peresborka reyestra posle utochneniya zavershyonnoj kartochki        | 0,095 s      | uspeshno — proizvodnyij planovyij JSON obnovlyon                                                                |
| proverka peresobrannogo planovogo reyestra                      | 0,101 s      | uspeshno — reyestr sootvetstvuyet istochnikam                                                                   |
| audit fingerprint-politiki putej                               | 11,159 s     | neuspeshno — JSON Schema soderzhit dva sovpadeniya domashnego sokrasjheniya, a politika pervonachaljno ozhidala odno |
| itogovyij audit mashinno-lokaljnyikh putej                         | 10,991 s     | uspeshno — ostalisj toljko tipizirovannyiye allow/report-srabatyivaniya                                          |
| avtonomnyiye testyi proverki mashinno-lokaljnyikh putej              | 0,889 s      | uspeshno — 19 iz 19 testov politiki i skanera proshli                                                         |
| povtornoye formatirovaniye i strogij Swift-lint                  | 0,515 s      | uspeshno — kod i testyi sootvetstvuyut centraljnoj konfiguracii                                                |
| celevoj nabor posle publikacionnogo refaktoringa               | 178,243 s    | uspeshno — 13 iz 13 Git-scenariyev proshli povtorno                                                            |
| formatirovaniye XCTest-diagnostiki `#fileID`                    | 0,055 s      | uspeshno — preduprezhdeniye ustraneno bez vozvrata mashinnogo puti kompilyatora                                  |
| strogij adresnyij test bez Swift-preduprezhdenij                 | 6,763 s      | uspeshno — test i vse zavisimosti sobranyi s warnings-as-errors                                               |
| itogovaya validaciya rabochego nabora                             | 0,438 s      | uspeshno — podtverzhdenyi 13 kandidatov: 1 ready, 11 paused i 1 blocked                                        |
| itogovoye vyichisleniye sleduyusjhego kandidata `master`              | 0,452 s      | uspeshno — yedinstvennoj ready povtorno opredelena FUM-STEP-0085                                              |
| preddyimnoye obnovleniye Markdown-recency                         | 0,376 s      | uspeshno — zamknutyi posledniye izmeneniya zaprosa, zhurnala i kartochki                                          |
| preddyimnoye obnovleniye teplovoj kartyi grafa                     | 0,154 s      | uspeshno — graf uzhe sootvetstvoval tekusjhej proizvodnoj pamyati                                                |
| proverka svyaznosti s razdelitelem tyisyach                        | 14,039 s     | neuspeshno — profilj otklonil probel vnutri chislovogo znacheniya obsjhej dliteljnosti                            |
| finaljnoye obnovleniye Markdown-recency                          | 0,371 s      | uspeshno — profilj bez razdelitelya tyisyach vklyuchyon v svezhuyu proizvodnuyu pamyatj                                 |
| finaljnoye obnovleniye teplovoj kartyi grafa                      | 0,150 s      | uspeshno — graf soglasovan s obnovlyonnyimi Markdown-blokami                                                   |
| povtornaya proverka svyaznosti rabochej sessii                    | 14,341 s     | uspeshno — zapros, zhurnal, Git-sostoyaniye i soobsjheniye kommita soglasovanyi                                     |
| vtoroj polnyij repozitornyij smoke-check                         | 947,313 s    | neuspeshno — shag 61 vyiyavil dva zapresjhyonnyikh domashnikh sokrasjheniya v pozdno dopolnennom zhurnale                  |
| kontroljnyij audit putej posle ispravleniya zhurnala              | 11,510 s     | uspeshno — dejstvuyusjhikh mashinno-lokaljnyikh putej ne ostalosj                                                   |
| tretij polnyij repozitornyij smoke-check                         | 944,679 s    | neuspeshno — pervyiye 65 shagov proshli, shag 66 potreboval obnovitj recency posle ispravleniya zhurnala            |
| zamyikaniye Markdown-recency pered itogovoj priyomkoj             | 0,500 s      | uspeshno — obnovlenyi zhurnal i vremennoj indeks Markdown                                                      |
| zamyikaniye teplovoj kartyi grafa pered itogovoj priyomkoj         | 0,350 s      | uspeshno — teplovaya karta uzhe sootvetstvovala svezhemu indeksu                                                |
| itogovyij polnyij repozitornyij smoke-check                       | 967,696 s    | uspeshno — vse 68 iz 68 shagov, vklyuchaya testyi, sborki, lint, puti, recency, graf i svyaznostj, proshli          |

Obsjheye vremya pryamyikh zapuskov proverok: 4973,452 s.

## Resheniya i ogranicheniya

- Vremennyiye katalogi bare-repozitoriyev i checkout peredayutsya validatoru otdeljnyim runtime-kontekstom i ne sokhranyayutsya v pasport libo pamyatj proyekta.
- Ni odin test ne ispoljzuyet setj: remotes yavlyayutsya lokaljnyimi bare-repozitoriyami, a Git-komandyi ochisjhayut unasledovannyiye `GIT_*`, otklyuchayut sistemnuyu i globaljnuyu konfiguraciyu i interaktivnyij prompt.
- Strukturno nevernyij pasport ne zapuskayet lishniye Git-processyi; proverka vneshnej topologii nachinayetsya toljko posle uspeshnogo razbora i semanticheskoj proverki deklaracii.
- Dostupnyij preflight dokazyivayet nablyudayemuyu lokaljnuyu topologiyu i sostoyaniye checkout v moment proverki, no ne yavlyayetsya tranzakcionnoj blokirovkoj budusjhego dvizheniya refs.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, proyektirovaniye, realizaciya i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command`, `apply_patch`, `update_plan` i `collaboration.*` — lokaljnyiye processyi, proveryayemyiye pravki, plan i razdelyonnoye arkhitekturnoye i kriticheskoye revjyu; versii kontraktov otdeljno ne raskryivayutsya.
- Swift 6.4, SwiftPM, Git 2.54.0, Python 3.14.6, ripgrep i standartnyiye Unix-komandyi — realizaciya, lokaljnyiye bare-fiksturyi, sborka, testyi, generatoryi i inspekciya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md), [fum-proverka-mashinno-lokaljnyikh-putej](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — ocheredj, vyibor sleduyusjhego shaga, vremya, planovyij perekhod, recency, graf, publikacionnaya chistota, svyaznostj i itogovaya priyomka.

## Istochniki

- [tekusjhij iskhodnyij zapros](zapros.md)
- [zavershyonnaya kartochka FUM-STEP-0084](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0084-zakrepitj-topologiyu-i-pasport-repozitornoj-kompozicii-FUM.md)
- [trebovaniye o repozitornoj kompozicii](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [proveryayemyij mnogoagentnyij kontur](../../Prototipyi/proveryayemyij-mnogoagentnyij-kontur/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:0026a2f49f1e8b4b55081808a08c9898572de4168126d91c13fd2b96f3fb814b -->
<!-- FUM-MD-RECENCY:END -->
