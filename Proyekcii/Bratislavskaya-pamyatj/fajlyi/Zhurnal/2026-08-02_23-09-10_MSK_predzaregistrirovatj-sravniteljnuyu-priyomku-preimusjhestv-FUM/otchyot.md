# Otchyot 2026-08-02 23:09:10 MSK - Predzaregistrirovatj sravniteljnuyu priyomku preimusjhestv FUM

Rabochaya sessiya prevratila obsjheye trebovaniye sravnitj FUM s obyichnyim agentskim ciklom v neizmenyayemyij do izmerenij protokol. [Kartochka eksperimenta](../../Planirovaniye/kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md) fiksiruyet prichinnuyu lestnicu, vneshnij skryityij kriterij, vyiborku, povtoryi, byudzhetyi, ostanovku, zasjhitu ot utechki i sposob analiza; izmeryayemyiye progonyi ne vyipolnyalisj.

## Rezuljtat

Shestj variantov obrazuyut posledovateljnostj `V0`–`V5`. Obyichnyij cikl sluzhit kontrolem, a sleduyusjhiye stupeni po odnoj dobavlyayut mekhanicheskij checkpoint, proveryayemuyu pamyatj, kontekstno ogranichennyij rabochij paket, otdeljnogo proveryayusjhego i neskoljko razlichimyikh proizvoditelej. Promezhutochnyij variant s pamyatjyu bez rabochikh paketov ne pozvolyayet smeshatj eti dva mekhanizma vnutri odnogo novogo vozdejstviya.

Pervichnaya gipoteza zaraneye svyazyivayet odnoagentnyij `V3` s obyichnyim `V0`: trebuyetsya ne meneye `+10` procentnyikh punktov avtonomnogo vneshnego uspekha, polozhiteljnaya nizhnyaya granica `95 %` klasternogo bootstrap-intervala i ne boleye `+3` procentnyikh punktov lozhnogo zaversheniya. Podderzhka, oproverzheniye i neodnoznachnostj opredelenyi do serii; sosedniye kontrastyi ostayutsya vtorichnyimi i poluchayut popravku Holm.

Osnovnaya vyiborka soderzhit `50` zadach — po desyatj dlya neodnoznachnosti, skryitoj funkcionaljnoj priyomki, prinuditeljnogo preryivaniya, konflikta i povrezhdyonnoj pamyati. Tri svezhikh povtora kazhdogo iz shesti variantov dayut `900` izmeryayemyikh progonov. Analiz do zakryitiya vsekh osnovnyikh blokov i post-hoc-rasshireniye zapresjhenyi; oshibki agenta ne zamenyayutsya rezervom.

Odinakovaya bazovaya modelj, runtime, instrumentyi, task prompt i agregatnyiye limityi uderzhivayutsya mezhdu variantami. Mnogorolevyiye variantyi delyat obsjhij byudzhet, poetomu chislo poduzlov ne umnozhayet razreshyonnyiye tokenyi, denjgi ili vyizovyi. Vneshnij ocensjhik otdelyon ot ispolnitelej, a skryityiye kriterii nedostupnyi cherez prompt, rabochuyu kopiyu, peremennyiye sredyi, dostupnyiye puti, setj i mezhprogonnuyu pamyatj.

## Planovyij perekhod

FUM-STEP-0104 perevedena v istoricheskij status s rezuljtatom i udalena iz rabochego nabora `master`. Yeyo zaversheniye mashinno otkryivayet neizmenyonnoye pokoleniye FUM-STEP-0084; ostaljnyiye `automatic`, susjhestvuyusjhaya produktovaya blokirovka i tochnyiye zavisimosti sokhranenyi. Trebovaniye sravniteljnoj priyomki ostayotsya `🟡`: protokol predzaregistrirovan, no task-manifest, evaluator, polnomochiya i serii progonov yesjhyo otsutstvuyut.

Izmeryayemyiye, vneshniye, setevyiye i platnyiye progonyi, izmeneniye chuzhikh repozitoriyev i publikaciya rezuljtatov yavno ne vkhodyat v etu sessiyu. Ikh neljzya vyivesti iz zaversheniya kartochki, ruchnogo push ili gotovnosti sleduyusjhego avtomaticheskogo kandidata.

## Profilj vremeni vyipolneniya

| Stadiya                                     | Dliteljnostj | Granicyi i sposob izmereniya                                                                              |
| ------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------- |
| ozhidaniye FIFO                              | 0,400 s      | tochnyij dokumentirovannyij `join` vernul `admitted` v tom zhe vyizove; otdeljnogo perioda ozhidaniya ne byilo  |
| chteniye pravil, fenced-proverka i preflight | ne izmereno  | nachalosj do vremennoj granicyi soderzhateljnoj stadii; zadnim chislom dliteljnostj ne vosstanavlivalasj    |
| soderzhateljnaya rabota                      | 1364 s       | ot polucheniya paryi vremeni sessii do nachala celevogo proverochnogo kontura; wall-clock po sistemnyim chasam |
| celevyiye i predfinaljnyiye proverki           | 66,320 s     | summa call-time pryamyikh vyizovov posle soderzhateljnoj stadii; perekryitiye chtenij ne vyichitayetsya             |
| polnyij repozitornyij smoke-check            | 1178,212 s   | pervyij progon vyiyavil ustarevshij snapshot; posle adresnogo ispravleniya povtor proshyol 68 iz 68 shagov      |
| atomarnaya peredacha ocheredi                 | ne izmereno  | vyipolnyayetsya posle zakryitiya otchyota; rezuljtat podtverzhdayetsya toljko tochnyim sostoyaniyem `committed`        |

Granica profilya: ot tochnogo `join` tekusjhej kornevoj zadachi do lokaljnogo atomarnogo commit+handoff; ranneye chteniye i fenced-preflight vklyuchenyi, no ikh otdeljnaya wall-clock-dliteljnostj ne byila izmerena. Soderzhateljnaya stadiya zavershilasj do celevyikh proverok; tri nezavisimyiye read-only planovyiye proverki vnutri celevoj stadii vyipolnyalisj paralleljno, poetomu arifmeticheskaya summa call-time ne ravna kalendarnomu intervalu.

### Pryamyiye zapuski proverok

| Vyizov                                                                  | Dliteljnostj | Rezuljtat                                                                                                             |
| ---------------------------------------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------- |
| pervaya popyitka dinamicheskogo bootstrap ocheredi                         | 0,100 s      | neuspeshno — process zavershilsya do registracii i ne izmenil ocheredj                                                    |
| vtoraya diagnosticheskaya popyitka poiska queue entrypoint                 | 0,100 s      | neuspeshno — process zavershilsya do registracii i ne izmenil ocheredj                                                    |
| tochnyij dokumentirovannyij `join`                                        | 0,400 s      | uspeshno — poluchen nemedlennyij FIFO-dopusk                                                                             |
| fenced `bind-run` i `verify-run`                                       | 1,900 s      | uspeshno — zapusk svyazan s tekusjhim pokoleniyem vladeljca                                                                |
| pervichnaya proverka `git diff --check` i statusa                        | 0,200 s      | uspeshno — probeljnyikh oshibok i chuzhoj gryazi ne obnaruzheno                                                               |
| domennoye pereimenovaniye FUM-STEP-0104                                  | 0,370 s      | uspeshno — status, indeks, graf, reyestr i zhivyiye ssyilki obnovlenyi specializirovannyim preflight                          |
| peresborka mashinnogo planovogo reyestra                                 | 0,290 s      | uspeshno — reyestr peresobran iz tekusjhikh kartochek                                                                       |
| proverka svezhesti mashinnogo planovogo reyestra                          | 0,310 s      | uspeshno — reyestr sootvetstvuyet tekusjhim kartochkam                                                                      |
| validaciya rabochego nabora sleduyusjhego shaga                              | 0,670 s      | uspeshno — 14 kandidatov: 1 ready, 12 paused i 1 blocked                                                               |
| vyichisleniye sleduyusjhego kandidata vetki master                           | 0,690 s      | uspeshno — yedinstvennyim ready opredelena FUM-STEP-0084                                                                 |
| pervaya popyitka proverki kriteriyev i runtime-chistotyi                    | 0,000 s      | neuspeshno — orkestrator ne predostavil TextEncoder; vneshnij process ne zapuskalsya                                     |
| proverka kriteriyev i runtime-chistotyi s obsjhim markerom                  | 0,190 s      | neuspeshno — obsjhij marker FUM-RUNTIME obnaruzhil dopustimyiye istoricheskiye instrukcii; proverka suzhena do tochnyikh znachenij |
| tochnaya proverka kriteriyev i runtime-chistotyi po vsemu Git-inventaryu     | 0,170 s      | neuspeshno — istoricheskij inventarj dal sovpadeniya; oblastj proverki trebuyet diagnostiki po kategoriyam                 |
| diagnostika sovpadenij tochnyikh nepublikuyemyikh znachenij                   | 0,170 s      | uspeshno — tekusjhij zapros chist; sovpadeniya lokalizovanyi v raneye susjhestvovavshej pamyati                                  |
| proverka pokryitiya kriteriyev FUM-STEP-0104 i runtime-chistotyi diff       | 0,410 s      | uspeshno — shestj variantov i vse kriterii pokryityi; zakryityiye runtime-znacheniya ne dobavlenyi                              |
| pervaya sinkhronizaciya Markdown-recency                                  | 0,580 s      | uspeshno — obnovlenyi 16 proizvodnyikh Markdown-fajlov                                                                    |
| pervaya peresborka teplovoj kartyi grafa                                 | 0,340 s      | uspeshno — graf obnovlyon na kanonicheskuyu datu 2026-08-02                                                               |
| pervaya otdeljnaya proverka Markdown-recency                             | 0,530 s      | uspeshno — recency-metki i vremennoj indeks soglasovanyi                                                                |
| pervaya otdeljnaya proverka teplovoj kartyi grafa                         | 0,340 s      | uspeshno — graph.json sootvetstvuyet recency-snimku                                                                     |
| pervaya predkommitnaya proverka git diff --check                         | 0,040 s      | uspeshno — probeljnyikh oshibok net                                                                                       |
| vtoraya sinkhronizaciya Markdown-recency                                  | 0,580 s      | uspeshno — obnovlenyi izmenivshiyesya zhurnal i vremennoj indeks                                                            |
| povtornaya validaciya mashinnogo planovogo reyestra                        | 0,310 s      | uspeshno — reyestr sokhranil svezhestj posle recency                                                                      |
| vtoraya peresborka teplovoj kartyi grafa                                 | 0,330 s      | uspeshno — graf uzhe sootvetstvoval tekusjhemu recency-snimku                                                             |
| vtoraya otdeljnaya proverka Markdown-recency                             | 0,530 s      | uspeshno — recency-metki i vremennoj indeks soglasovanyi                                                                |
| vtoraya otdeljnaya proverka teplovoj kartyi grafa                         | 0,350 s      | uspeshno — graph.json sootvetstvuyet recency-snimku                                                                     |
| vtoraya predkommitnaya proverka git diff --check                         | 0,040 s      | uspeshno — probeljnyikh oshibok net                                                                                       |
| pred-smoke sinkhronizaciya Markdown-recency                              | 0,580 s      | uspeshno — obnovlenyi izmenivshiyesya zhurnal i vremennoj indeks                                                            |
| pred-smoke peresborka teplovoj kartyi grafa                             | 0,320 s      | uspeshno — graf uzhe sootvetstvoval tekusjhemu recency-snimku                                                             |
| pred-smoke proverka Markdown-recency                                   | 0,530 s      | uspeshno — recency-metki i vremennoj indeks soglasovanyi                                                                |
| pred-smoke proverka teplovoj kartyi grafa                               | 0,340 s      | uspeshno — graph.json sootvetstvuyet recency-snimku                                                                     |
| pred-smoke proverka git diff --check                                   | 0,040 s      | uspeshno — probeljnyikh oshibok net                                                                                       |
| pervaya polnaya proverka svyaznosti rabochej sessii                        | 16,420 s     | uspeshno — zapros, zhurnal, Git-sostoyaniye i soobsjheniye kommita soglasovanyi                                               |
| zamyikayusjhaya pered smoke sinkhronizaciya Markdown-recency                  | 0,580 s      | uspeshno — obnovlenyi izmenivshiyesya zhurnal i vremennoj indeks                                                            |
| zamyikayusjhaya pered smoke peresborka teplovoj kartyi grafa                 | 0,320 s      | uspeshno — graf uzhe sootvetstvoval tekusjhemu recency-snimku                                                             |
| zamyikayusjhaya pered smoke proverka Markdown-recency                       | 0,520 s      | uspeshno — recency-metki i vremennoj indeks soglasovanyi                                                                |
| zamyikayusjhaya pered smoke proverka teplovoj kartyi grafa                   | 0,330 s      | uspeshno — graph.json sootvetstvuyet recency-snimku                                                                     |
| zamyikayusjhaya pered smoke proverka git diff --check                       | 0,040 s      | uspeshno — probeljnyikh oshibok net                                                                                       |
| zamyikayusjhaya pered smoke proverka svyaznosti sessii                       | 16,660 s     | uspeshno — finaljnyij do smoke snimok svyaznoj pamyati podtverzhdyon                                                        |
| pervyij polnyij repozitornyij smoke-check                                 | 354,425 s    | neuspeshno — snapshot-test vetochnogo nabora ozhidal prezhniye 15 kandidatov vmesto 14                                     |
| adresnyij snapshot-test vyichislyayemogo sleduyusjhego shaga                    | 1,610 s      | uspeshno — obnovlyonnoye ozhidaniye 14 kandidatov i FUM-STEP-0084 podtverzhdeno                                             |
| sinkhronizaciya Markdown-recency pered povtornyim smoke                   | 0,540 s      | uspeshno — obnovlenyi test-zavisimyij zapros, zhurnal i vremennoj indeks                                                  |
| peresborka teplovoj kartyi pered povtornyim smoke                        | 0,310 s      | uspeshno — graf uzhe sootvetstvoval tekusjhemu recency-snimku                                                             |
| proverka Markdown-recency pered povtornyim smoke                        | 0,520 s      | uspeshno — recency-metki i vremennoj indeks soglasovanyi                                                                |
| proverka teplovoj kartyi pered povtornyim smoke                          | 0,340 s      | uspeshno — graph.json sootvetstvuyet recency-snimku                                                                     |
| proverka git diff --check pered povtornyim smoke                        | 0,050 s      | uspeshno — probeljnyikh oshibok net                                                                                       |
| proverka svyaznosti pered povtornyim smoke                               | 15,540 s     | uspeshno — obnovlyonnyij snapshot-test i spisok zatronutyikh fajlov soglasovanyi                                            |
| povtornyij polnyij repozitornyij smoke-check                              | 823,787 s    | uspeshno — 68 iz 68; dliteljnostj vzyata iz monotonnoj granicyi smoke-timing total                                       |
| zaklyuchiteljnaya sinkhronizaciya Markdown-recency                          | 0,540 s      | uspeshno — obnovlenyi itogovyij zhurnal i vremennoj indeks                                                                |
| zaklyuchiteljnaya peresborka teplovoj kartyi grafa                         | 0,330 s      | uspeshno — graf uzhe sootvetstvoval itogovomu recency-snimku                                                            |
| zaklyuchiteljnaya validaciya mashinnogo planovogo reyestra                   | 0,310 s      | uspeshno — reyestr sootvetstvuyet zavershyonnoj kartochke i tekusjhim trebovaniyam                                             |
| zaklyuchiteljnaya validaciya vetochnogo whitelist                           | 0,680 s      | uspeshno — 14 kandidatov: 1 ready, 12 paused i 1 blocked                                                               |
| zaklyuchiteljnyij vyibor sleduyusjhego shaga                                   | 0,700 s      | uspeshno — yedinstvennyim ready opredelena FUM-STEP-0084                                                                 |
| zaklyuchiteljnaya proverka Markdown-recency                               | 0,540 s      | uspeshno — recency-metki i vremennoj indeks soglasovanyi                                                                |
| zaklyuchiteljnaya proverka teplovoj kartyi grafa                           | 0,350 s      | uspeshno — graph.json sootvetstvuyet itogovomu recency-snimku                                                           |
| zaklyuchiteljnaya proverka git diff --check                               | 0,040 s      | uspeshno — probeljnyikh oshibok net                                                                                       |
| zaklyuchiteljnaya proverka kriteriyev FUM-STEP-0104 i runtime-chistotyi diff | 0,370 s      | uspeshno — kriterii pokryityi; zakryityiye runtime-znacheniya tekusjhim diff ne dobavlenyi                                       |

<!-- FUM-VALIDATION-ROWS -->

Obsjheye vremya pryamyikh zapuskov proverok: 1247,602 s.

Komandyi chteniya, versii instrumentov i obyichnaya inspekciya ne vklyuchenyi kak testovyiye processyi. Posle zayavlennoj granicyi dopuskayutsya toljko neobkhodimyiye dlya zamyikaniya izmenivshegosya otchyota proverki bez rekursivnogo povtora polnogo smoke-check.

## Resheniya i ogranicheniya

Glavnyij kontrast `V3 - V0` izmeryayet preimusjhestvo sostavnogo odnoagentnogo FUM, a sosedniye kontrastyi obyyasnyayut vklad kazhdogo mekhanizma. Eto sokhranyayet produktovyij vopros i odnovremenno ne vyidayot korrelirovannyiye roli odinakovoj modeli za nezavisimyiye svideteljstva.

Minimum `50` zadach vyibran kak pragmaticheskaya nizhnyaya granica, a ne kak rezuljtat otdeljnogo power-analiza. Poetomu interval, ne dostigayusjhij zaraneye zadannyikh porogov, ostayotsya neodnoznachnyim i ne dopolnyayetsya novyimi zadachami posle prosmotra rezuljtatov. Power-analiz po otdeljnomu neizmeryayemomu pilot-naboru mozhet vyipustitj toljko novuyu versiyu do osnovnoj serii.

Dlya povrezhdyonnoj pamyati polnostjyu odinakovyij nositelj nevozmozhen: variantyi bez proveryayemoj pamyati poluchayut tot zhe iskazhyonnyij material kak obyichnuyu zametku, a variantyi FUM — kak nepodtverzhdyonnogo kandidata. Etot sloj analiziruyetsya otdeljno. Analogichno paralleljnyij `V5` menyayet wall-clock-planirovaniye, khotya agregatnyiye tokenyi, denjgi i vyizovyi ostayutsya obsjhimi.

Pervyiye dve popyitki queue-bootstrap byili lokaljnyimi diagnosticheskimi vyizovami s nevernyim dinamicheskim obnaruzheniyem tochki vkhoda; obe zavershilisj do registracii i bez izmeneniya sostoyaniya. Posle polnogo chteniya zakommichennogo kontrakta ispoljzovana yego bukvaljnaya komanda, i zadacha poluchila obyichnyij dopusk. Neprozrachnyiye runtime-znacheniya v pamyatj sessii ne perenosilisj.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) — obsjhij spravochnik instrumentaljnyikh kontraktov i sposobov proverki.
- Codex Desktop, vstroyennyij runtime i modelj semejstva GPT-5 — kornevaya sessiya, proyektirovaniye protokola i integraciya; tochnyiye versii prilozheniya, runtime i modeli sredoj otdeljno ne raskryityi.
- `functions.exec`, `exec_command` i `apply_patch` — lokaljnyiye processyi, chteniye i proveryayemyiye pravki; versii instrumentaljnyikh kontraktov otdeljno ne raskryivayutsya.
- [fum-ocheredj-zadach-git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md), [fum-sleduyusjhij-shag-vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md), [fum-moskovskoye-vremya-rabochej-sessii](../../Instrumentyi/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md), [fum-reyestr-planirovaniya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md), [fum-svezhestj-markdown](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md), [fum-svezhestj-grafa-obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) i [fum-kompleksnaya-proverka-repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) — ocheredj, fenced-zapusk, vremya sessii, planovyij perekhod, recency, graf, svyaznostj i polnyij smoke-check.
- Python `3.14.6`, Git `2.54.0`, ripgrep `15.2.0` i standartnyiye Unix-komandyi — lokaljnaya inspekciya, generatoryi i proverki.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [predregistraciya sravniteljnoj priyomki](../../Planirovaniye/kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md)
- [zavershyonnaya FUM-STEP-0104](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0104-predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM.md)
- [trebovaniye o sravniteljnoj eksperimentaljnoj priyomke](../../Trebovaniya/🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka](../../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:104217fe4f91d2a8d49c9234f51090eccedc8371bdea3ab753e645a3b74e7e23 -->
<!-- FUM-MD-RECENCY:END -->
