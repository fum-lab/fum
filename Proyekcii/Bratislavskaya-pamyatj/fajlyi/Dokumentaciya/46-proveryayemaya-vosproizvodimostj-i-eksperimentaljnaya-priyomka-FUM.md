# Proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM

[FUM](../Glossarij/FUM.md) dolzhen razlichatj sokhrannostj bajtov, strukturnuyu soglasovannostj, vyivodimostj sostoyaniya iz sobyitij, proiskhozhdeniye, podlinnostj i istinnostj. Khyeshi i kanonicheskaya serializaciya mogut dokazatj neizmennostj i vnutrennyuyu celostnostj artefakta, no sami po sebe ne dokazyivayut ni yego polucheniye povtornyim ispolneniyem, ni pravomernostj avtora, ni istinu soderzhaniya.

Tekusjhij bezokonnyij Swift-prototip uzhe vstraivayet v pokoleniye yavnyij seed i polnyij kumulyativnyij zhurnal prinyatyikh sobyitij, povtorno ispolnyayet po nim zakreplyonnuyu politiku i sravnivayet vyivedennyiye snimok, trassu, proiskhozhdeniye i proyekciyu s sokhranyonnyimi artefaktami. On podtverzhdayet vyivodimostj bez vneshnej fiksturyi i novogo modeljnogo vyizova, kanonicheskuyu skhodimostj polnogo i inkrementaljnogo putej, strukturnuyu validaciyu pokoleniya, mezhprocessnyij compare-and-swap ukazatelya mezhdu sotrudnichayusjhimi pisatelyami i process-crash consistency fajlovogo khranilisjha na tekusjhem lokaljnom macOS-stende. [Profilj `fum.memory.canonical-json.v1`](47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md) zakreplyayet yazyikonejtraljnyiye bajtyi i SHA-256; Swift i uzkij Python-verifier pobajtovo sovpadayut na obsjhem conformance-corpus. Prototip poka ne sokhranyayet zhurnal otklonyonnyikh kandidatov i ne dokazyivayet power-loss durability.

[Obsjhaya pamyatj raspredelyonnogo epizoda](49-kontrakt-vosstanavlivayemoj-obsjhej-pamyati-raspredelyonnogo-epizoda.md) pereispoljzuyet to zhe kanonicheskoye yadro bez paralleljnogo formata. Yeyo pustoye nachaljnoye pokoleniye vstraivayet pasport i artefaktyi, a kazhdyij preyemnik dobavlyayet rovno odno sobyitiye vklada, otdeljnoj proverki utverzhdenij, resheniya, byudzhetnoj operacii, izmeneniya ozhidayusjhego perekhoda libo terminaljnogo iskhoda. Skhema zhurnala, sostoyaniya i pokoleniya i reducer versii 4 sokhranyayut proiskhozhdeniye, peresekayusjhiyesya korrelyacii, tipizirovannyiye instrumentaljnyiye nablyudeniya, iskhodyi proverok i neizmenyayemyiye raznoglasiya vmeste s dokazateljnyim vyiborom, shestimernyim konechnyim byudzhetom, zasjhisjhyonnyimi rezervami proverki i peredachi, tochnyim ozhidayusjhim perekhodom i obyazateljnoj ostanovkoj. Povtornoye ispolneniye iz odnogo generation blob pobajtovo vosstanavlivayet eti dannyiye bez prezhnego chata i novogo vyizova modeli.

Avtonomnyij skvoznoj stend versii 4 soyedinyayet pasport, dva razlichimyikh rabochikh paketa i dvukh proizvoditelej, vkladyi, lokaljnoye instrumentaljnoye nablyudeniye, vosstanavlivayemuyu obsjhuyu pamyatj, otdeljnogo proveryayusjhego, dokazateljnyij vyibor i terminaljnyij iskhod `goal_met`. Perezapusk processa mezhdu vkladami prinimayet toljko podtverzhdyonnoye pokoleniye, a nepreryivnyij i vozobnovlyonnyij progonyi zavershayutsya pobajtovo odinakovyim kanonicheskim `CURRENT`. Otricateljnyiye scenarii otdeljno vosproizvodyat lozhnyij konsensus bez priyomki rezuljtata i ischerpaniye byudzheta do sleduyusjhego dejstviya. Scenarij ozhidaniya podtverzhdeniya proveryayet kanonicheskuyu trassu versii 3 s dvumya resursno ogranichennyimi model-only-vetvyami ot obsjhego predka, ikh proverkami i vnutrennim otborom, ne podmenyayusjhim poljzovateljskij dopusk.

Otdeljnyij uzkij runtime-scenarij zamknul odin odnoagentnyij epizod: exact-pasport, dva model-only-varianta ot obsjhego predka, byudzhetnuyu no-call-tochku, vneshneye svideteljstvo, izolirovannyij candidate commit, otdeljnuyu priyomku i yedinstvennyij terminaljnyij iskhod. Vneshnij harness dvazhdyi nablyudayet zaraneye zaregistrirovannuyu kontroljnuyu tochku, posyilayet fakticheskij `SIGKILL` i zapuskayet novyij PID; kazhdoye vozobnovleniye prinimayet pasport, prikreplyonnyij k podtverzhdyonnomu `CURRENT`, bez prezhnego chata, stdin i skryityikh peremennyikh processa. Avtonomnyij rezhim zakreplyayet kanonicheskuyu replay-proyekciyu i dokazyivayet no-effect replay, a odin opt-in zhivoj progon proshyol tot zhe kontur cherez lokaljnyij LM Studio bez recorded model transport.

## Lestnica garantij

Proverka kazhdogo sloya ne povyishayet artefakt do sleduyusjhego statusa bez otdeljnogo svideteljstva:

1. **Bajtovaya celostnostj** pokazyivayet, chto dannyiye ne izmenilisj otnositeljno konkretnogo khyesha.
2. **Strukturnaya soglasovannostj** pokazyivayet, chto polya, ssyilki, khyeshi i versii ne protivorechat zadannoj skheme.
3. **Vyivodimostj** pokazyivayet, chto proizvodnoye sostoyaniye dejstviteljno poluchayetsya iz tochnyikh pervichnyikh sobyitij po zakreplyonnyim versiyam reduktorov i politik.
4. **Proiskhozhdeniye** svyazyivayet sobyitiye i resheniye s nablyudayemyimi vkhodami, ispolnitelyami, rabochimi paketami, modelyami, postavsjhikami, instrumentami, proverkami i podtverzhdeniyami; obsjhiye osnovaniya sokhranyayutsya yavnyimi svyazyami korrelyacii.
5. **Podlinnostj i pravomochnostj** trebuyut otdeljno dokazatj, kto porodil vklad i imel li on pravo na dejstviye.
6. **Istinnostj ili semanticheskaya obosnovannostj** trebuyut sopostavleniya utverzhdeniya s dokazateljstvom, sredoj ili nezavisimoj proverkoj.

Vyivod tekusjhego validatora obsjhej pamyati ob ogranichennoj nezavisimosti ostayotsya na chetvyortom sloye i ne povyishayet vklad do podlinnosti ili istinyi. Validator razlichayet nezavisimyij po nablyudayemyim priznakam vklad, korrelirovannyij vklad, kopiyu i vklad s nepodtverzhdyonnyim proiskhozhdeniyem. Chislo ogranichennyikh podtverzhdenij schitayetsya po svyaznyim komponentam peresekayusjhikhsya grupp, napravlennyikh ryober, obsjhego ispolnitelya i odnogo instrumentaljnogo vyizova, poetomu svyazannyij vklad ne uvelichivayet schyotchik. Otdeljnoye sobyitiye proverki ne uvelichivayet etot schyotchik proizvoditelej: dlya nego nezavisimo vyivoditsya `external_by_observed_features`, `self_verification`, `correlated_verification` libo `unconfirmed_provenance`, a vneshnij ves poluchayet toljko pervyij status. Kanonicheskoye pole `semantic_independence_proven` vsegda lozhno.

Proverka formyi podtverzhdayet toljko polnotu polej, dopustimyiye znacheniya, khyeshi i zamknutostj tipizirovannyikh ssyilok. Instrumentaljno podtverzhdyonnyij fakt ogranichen iskhodnyim nablyudeniyem s sokhranyonnyimi vidom polnomochiya, identichnostjyu vyizova i SHA-256 vkhoda i rezuljtata; modeljnyij pereskaz i ssyilka proveryayusjhego etogo polnomochiya ne nasleduyut. Iskhod `passed`, `failed` ili `inconclusive` yavlyayetsya sokhranyonnoj semanticheskoj ocenkoj obyyavlennogo proveryayusjhego otnositeljno zaraneye obyyavlennyikh kriteriyev i dokazateljstv, a ne mashinnyim dokazateljstvom istinyi. Dazhe `external_by_observed_features` oznachayet toljko otsutstviye izvestnogo sovpadeniya ispolnitelya, roli ili zapresjhyonnoj korrelyacii i ne dokazyivayet absolyutnuyu nezavisimostj.

## Osj fiksacii fajlovogo sostoyaniya

Smyislovaya lestnica ne zamenyayet otdeljnyiye urovni fizicheskoj fiksacii. Logicheskaya atomarnostj oznachayet, chto sotrudnichayusjhiye processyi prinimayut odno linearizovannoye resheniye blagodarya postoyannoj advisory-lock, povtornoj proverke ozhidayemogo roditelya i atomarnoj zamene `CURRENT`. Soglasovannostj posle avarii processa oznachayet boleye siljnoye nablyudayemoye svojstvo: posle `SIGKILL` pisatelya novyij process prinimayet toljko prezhnij ukazatelj libo novyij ukazatelj na polnostjyu zapisannoye i polnostjyu proveryayemoye pokoleniye. Sokhrannostj pri potere pitaniya trebuyet otdeljnogo dokazateljstva i ne sleduyet iz pervyikh dvukh urovnej.

Proverennyij Swift-protokol polnostjyu zapisyivayet staging-fajl pokoleniya, vyizyivayet `fsync`, publikuyet adresuyemoye pokoleniye bez zamesjheniya i sinkhroniziruyet katalog `generations/`; toljko zatem pod `CURRENT.lock` on povtoryayet CAS, polnostjyu zapisyivayet i sinkhroniziruyet staging-ukazatelj, atomarno zamenyayet `CURRENT.json` i sinkhroniziruyet kornevoj katalog. Vosstanovleniye doveryayet toljko tochnomu `CURRENT`, ne skaniruyet obyyektyi i ne povyishayet sirotyi. Vosemj processnyikh kontroljnyikh tochek do i posle obeikh publikacij proverenyi novyim recovery-processom.

Fajlovyij rezuljtat i odin skvoznoj runtime-scenarij vmeste podtverzhdayut vozobnovleniye posle dvukh avarij processa toljko v etom zakryitom odnoagentnom epizode. Oni ne dokazyivayut vozobnovleniye proizvoljnogo agentskogo epizoda. Uspeshnyij `fsync` takzhe ne zamenyayet [eksperiment](../Glossarij/eksperiment-FUM.md) s zakreplyonnyimi fajlovoj sistemoj, nositelem, kyeshami i realjnyim otklyucheniyem pitaniya. Power-loss durability ostayotsya otdeljnyim neproverennyim rubezhom.

## Dva rezhima vosproizvodimosti

[Vosproizvedeniye prinyatogo epizoda FUM](../Glossarij/vosproizvedeniye-prinyatogo-epizoda-FUM.md) ne vyizyivayet modelj i instrumentyi zanovo. Ono beryot sokhranyonnyiye vkhodyi, modeljnyiye otvetyi, rezuljtatyi instrumentov, resheniya, otkazyi i podtverzhdeniya, povtorno primenyayet versionnyiye reduktoryi i vosstanavlivayet tochnoye prinyatoye sostoyaniye. Eto inzhenernaya garantiya vyivodimosti, a ne nezavisimoye podtverzhdeniye istinyi.

[Povtornoye zhivoye ispolneniye FUM](../Glossarij/povtornoye-zhivoye-ispolneniye-FUM.md) zanovo obrasjhayetsya k modeli, instrumentam i srede iz sopostavimogo nachaljnogo konteksta. Ono nuzhno dlya ocenki ustojchivosti i poljzyi, no novyij otvet LLM ili izmenivsheyesya vneshneye nablyudeniye ne obyazanyi byitj pobajtovo ravnyi prezhnim. Poetomu ono ocenivayetsya po zaraneye zadannomu eksperimentaljnomu protokolu, a ne po khyesh-ravenstvu vsego progona.

## Fizicheskiye sloi pamyati

Odin format ne obyazan odinakovo khorosho sluzhitj vsem rolyam pamyati. Celevaya kompoziciya razlichayet:

- Git-istoriyu kak konstituciyu, prinyatuyu istoriyu trebovanij, reshenij, kontraktov i koda;
- dopisyivayemyij zhurnal epizodov s polnyimi telami sobyitij ili neizmenyayemyimi adresuyemyimi nositelyami etikh tel;
- tranzakcionnoye aktivnoye sostoyaniye s odnoznachnyim poryadkom konkuriruyusjhikh zapisej i vosstanovleniyem posle sboya;
- perestraivayemyiye poiskovyiye, vektornyiye i grafovyiye indeksyi, kotoryiye ne stanovyatsya skryityim istochnikom istinyi;
- obyyektnoye khranilisjhe dlya krupnyikh artefaktov, gde adres, khyesh, rezhim dostupa i proiskhozhdeniye ostayutsya v proveryayemom sloye.

Kazhdyij proizvodnyij indeks dolzhen perestraivatjsya iz kanonicheskogo zhurnala i prinyatoj istorii; yego poterya ne dolzhna unichtozhatj podtverzhdyonnuyu pamyatj.

## Podtverzhdyonnyij i sleduyusjhij rubezhi

Pervyij rubezh — odin skvoznoj bezokonnyij odnoagentnyij epizod — podtverzhdyon avtonomnoj fiksturoj i odnim opt-in zhivyim lokaljnyim progonom. Proverennaya cepochka ogranichena odnim sinteticheskim Git-dejstviyem, dvumya zakreplyonnyimi model-only-promptami, dvumya process-crash-tochkami i odnim terminaljnyim iskhodom; ona ne obobsjhayetsya na proizvoljnyiye zadachi i dejstviya.

Sleduyusjhij inzhenernyij rubezh, zakreplyonnyij kartochkoj FUM-STEP-0081, projden avtonomnyim skvoznyim stendom na zapisannyikh fiksturakh. Polozhiteljnyij scenarij provodit dva kontekstno posiljnyikh i razlichimyikh rabochikh paketa cherez dvukh proizvoditelej, sokhranyayet instrumentaljnoye nablyudeniye odnogo utverzhdeniya, perezapuskayet process mezhdu vkladami, vosstanavlivayet toljko podtverzhdyonnoye pokoleniye, poluchayet iskhod otdeljnogo proveryayusjhego i dokazateljnoye resheniye selektora i ostanavlivayetsya s `goal_met`. Itogovyiye kanonicheskiye bajtyi `CURRENT` nepreryivnogo i vozobnovlyonnogo progonov sovpadayut.

Tri samostoyateljnyikh scenariya zakryivayut otricateljnyiye i polnomochnyiye granicyi. Dva korrelirovannyikh odinakovyikh otveta sokhranyayutsya kak razlichimyiye vkladyi, no ne obrazuyut dokazateljstvo i privodyat k `unresolved_conflict` bez vyibrannogo rezuljtata. Nedostatok tochnoj komponentyi byudzheta blokiruyet dejstviye do yego ispolneniya, sokhranyayet trebuyemoye znacheniye, ostatok i prichinu i zavershayet epizod s `budget_exhausted` bez nepodtverzhdyonnoj publikacii. Kanonicheskaya trassa versii 3 parkuyet tochnyij vneshnij perekhod v ozhidanii podtverzhdeniya, prodolzhayet dve resursno ogranichennyiye model-only-vetvi ot obsjhego predka, sokhranyayet ikh proverki i vnutrennij otbor, no ne sozdayot poljzovateljskogo podtverzhdeniya.

Odin lokaljnyij probnik zapuskayet eti chetyire scenariya bez seti i sekretov. Priyomka dokazyivayet vosproizvodimuyu kompoziciyu kontraktov na zapisannyikh otvetakh ispolnitelej i instrumenta; ona ne dokazyivayet gotovnostj zhivogo mnogomodeljnogo FUM, semanticheskuyu nezavisimostj modelej, dostovernostj nezapisannyikh vneshnikh nablyudenij ili pravo na vneshnij effekt.

Posleduyusjhij neprojdennyij rubezh — sravniteljnaya eksperimentaljnaya priyomka. Yeyo [predregistraciya versii `1`](../Planirovaniye/kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md) uzhe fiksiruyet do izmerenij shestj variantov: obyichnyij cikl, mekhanicheskiye tochki vosstanovleniya, proveryayemuyu pamyatj, kontekstno ogranichennyiye rabochiye paketyi, otdeljnogo proveryayusjhego i neskoljko razlichimyikh poduzlov. Kazhdyij sosednij variant dobavlyayet rovno odno vozdejstviye. Utverzhdeniye, chto FUM uluchshayet agenta ili samouluchshayetsya, po-prezhnemu dolzhno opiratjsya na vneshniye ili skryityiye zadachi, odinakovuyu bazovuyu modelj, sopostavimyiye instrumentyi i agregatnyiye byudzhetyi, odin vneshnij kriterij zaversheniya i povtoryi.

Predzaregistrirovannyij minimum raven `50` zadacham pyati sloyov i tryom povtoram kazhdogo iz shesti variantov, vsego `900` izmeryayemyim progonam bez rannego analiza. Metriki vklyuchayut uspekh po vneshnemu kriteriyu, lozhnoye obyyavleniye zaversheniya, vosstanovleniye posle sboya, sokhrannostj uzhe podtverzhdyonnogo sostoyaniya, chislo vmeshateljstv cheloveka, stoimostj, tokenyi, vremya, dublirovaniye rabotyi, konfliktyi i regressii. Chislo kommitov, kartochek ili zavershyonnyikh shagov mozhet byitj operacionnoj metrikoj, no ne dokazateljstvom uluchsheniya.

Schyotchiki zavershenij sokhranyayut ogranichennuyu rolj operacionnogo svideteljstva, no ne dispetcherizuyut rabotu. V dejstvuyusjhej ruchnoj skheme sleduyusjhuyu pishusjhuyu sessiyu zapuskayet toljko poljzovatelj. [Obyazateljnoye prodolzheniye Git-vetki posle kommita](45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md), FIFO i avtomaticheskij vyibor kandidata yavlyayutsya otlozhennyim profilem; kolichestvo nakoplennyikh sobyitij, vremya i host-prostoj ne dayut polnomochij sozdatj zadachu.

Prezhnyaya periodicheskaya reviziya posle pyati zavershenij, yeyo zhurnal, diapazonyi, rezervacii i claims otnosyatsya k snyatomu heartbeat-konturu. Sokhranyonnyiye artefaktyi i testyi podtverzhdayut proiskhozhdeniye prezhnego resheniya, no ne yavlyayutsya dejstvuyusjhim planirovsjhikom i ne razreshayut povtor host-effekta.

Nuzhnaya analiticheskaya reviziya oformlyayetsya otdeljnyim poljzovateljskim zaprosom; kartochka ostayotsya planovoj pamyatjyu, no sama ne zapuskayet rabotu. Otlozhennyij profilj pryamogo vetochnogo vyibora, FIFO i predsozdaniya prodolzheniya ne yavlyayetsya dejstvuyusjhim marshrutom. Otchyot mozhet vyiyavitj osnovaniye dlya novogo eksperimenta ili izmeneniya processa, no sam fakt yego zapuska ne yavlyayetsya dokazateljstvom uluchsheniya.

Istoricheskoye znacheniye `N = 5` nikogda ne byilo empiricheski dokazannoj optimaljnoj chastotoj analiza. Vyivod ob uluchshenii po-prezhnemu prinimayetsya toljko po nablyudayemoj sposobnosti, vneshnim ili skryityim zadacham, terminaljnyim kriteriyam, sopostavimyim usloviyam i zatratam, vklyuchaya otricateljnyiye rezuljtatyi.

Predregistraciya ne soderzhit izmeryayemyikh zapuskov i ne podtverzhdayet preimusjhestvo. Eti inzhenernyiye rubezhi ne menyayut aktivnyij produktovyij MVP, ne naznachayut versiyu `0.1` i ne razreshayut vneshniye ili platnyiye progonyi.

## Strategicheskaya granica

Tekusjhaya proveryayemaya gipoteza pozicionirovaniya — lokaljnaya Git-oriyentirovannaya sreda dolgovremennoj agentnoj rabotyi s proveryayemyimi pamyatjyu, proiskhozhdeniyem reshenij, vosstanovleniyem i evolyucionnoj rodoslovnoj. Repozitorij uzhe proveryayet chastj etoj mekhaniki i odin uzkij skvoznoj runtime-scenarij. Obsjhij agentskij runtime dlya proizvoljnyikh zadach, raspredelyonnyij FUM, produktovaya versiya i sravniteljnoye preimusjhestvo ne dokazanyi.

Kazhdaya konechnaya cepochka metainfrastrukturnyikh shagov zaraneye nazyivayet vneshne nablyudayemuyu sposobnostj, kriterij yeyo priyomki i predel cepochki. Istoricheskij porog revizii `N = 5` ne yavlyayetsya optimaljnoj strategicheskoj kvotoj i ne zamenyayet empiricheskogo osnovaniya dlya vyibora dlinyi cepochki. Perekhod k GUI, Metal, syiromu sboru vvoda, fizicheskomu dejstviyu i slozhnoj repozitornoj seti ne obgonyayet proveryayemoye odnoagentnoye yadro, modelj polnomochij i eksperimentaljnuyu priyomku.

Sokhraneniye Swift kak tekusjhego runtime-yazyika sovmestimo s yazyikonejtraljnyimi skhemami, bajtovyim profilem, etalonnyimi vektorami i conformance-naborom. Profilj i nabor uzhe dejstvuyut; perepisyivaniye na Python ili drugoj yazyik ne yavlyayetsya celjyu; vtoraya uzkaya realizaciya proveryayet protokol, a ne zamenyayet osnovnoj runtime.

## Resheniya, ne prinyatyiye etim dokumentom

Etot kontrakt ne menyayet CC0 1.0 Universal, ne vvodit torgovuyu marku, ne vyipuskayet reliz, ne menyayet GitHub About, topics, Actions, branch protection ili vetvj publikacii. On ne prinimayet vneshniye cifryi ili ryinochnyiye sravneniya iz importirovannogo analiza kak faktyi bez proverki pervichnyikh istochnikov. Produktovaya numeraciya, smena aktivnogo MVP, vneshniye setevyiye eksperimentyi i rasshireniye realjnyikh polnomochij trebuyut otdeljnyikh reshenij i proverok.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-10 14:30:08 MSK — Dobavitj analitiku po chislu zavershyonnyikh shagov](../Zhurnal/2026-08-10_14-30-08_MSK_dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov/zapros.md)
- [iskhodnyij zapros 2026-08-02 23:09:10 MSK — Predzaregistrirovatj sravniteljnuyu priyomku preimusjhestv FUM](../Zhurnal/2026-08-02_23-09-10_MSK_predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-02 13:26:18 MSK — Provesti avtonomnuyu priyomku raspredelyonnogo myisliteljnogo epizoda](../Zhurnal/2026-08-02_13-26-18_MSK_provesti-avtonomnuyu-priyomku-raspredelyonnogo-myisliteljnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-02 09:36:50 MSK — Dobavitj vyibor, byudzhetyi i usloviye ostanovki epizoda](../Zhurnal/2026-08-02_09-36-50_MSK_dobavitj-vyibor-byudzhetyi-i-usloviye-ostanovki-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-01 23:00:38 MSK — Dobavitj vosstanavlivayemuyu obsjhuyu pamyatj raspredelyonnogo epizoda](../Zhurnal/2026-08-01_23-00-38_MSK_dobavitj-vosstanavlivayemuyu-obsjhuyu-pamyatj-raspredelyonnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij zapros o yazyikonejtraljnom kanonicheskom protokole pamyati](../Zhurnal/2026-07-28_08-47-18_MSK_zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati/zapros.md)
- [iskhodnyij zapros ob avarijnoj soglasovannosti khranilisjha pamyati](../Zhurnal/2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- [iskhodnyij zapros o mezhprocessnom CAS ukazatelya pamyati](../Zhurnal/2026-07-28_00-54-15_MSK_dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati/zapros.md)
- [iskhodnyij zapros o kanonicheskikh sobyitiyakh i samodostatochnom vosproizvedenii](../Zhurnal/2026-07-27_22-17-40_MSK_sokhranitj-kanonicheskiye-sobyitiya-i-dokazatj-vosproizvedeniye/zapros.md)
- [iskhodnyij zapros ob integracii kriticheskogo analiza](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros o kontekstno ogranichennoj mnogoagentnoj realizacii FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-02 01:12:32 MSK — Zafiksirovatj proiskhozhdeniye i ogranichennuyu nezavisimostj vkladov poduzlov](../Zhurnal/2026-08-02_01-12-32_MSK_zafiksirovatj-proiskhozhdeniye-i-ogranichennuyu-nezavisimostj-vkladov-poduzlov/zapros.md)
- [arkhivirovannyij dialog «Proyekti analizi»](../Istochniki/URL/https/chatgpt.com/share/6a676c90-cac4-83ed-b8a7-6bbffc688a1e/proyekti-analizi.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [kontrakt chistogo modeljnogo shaga](41-kontrakt-chistogo-modeljnogo-shaga.md)

## Opornyiye materialyi

- [otchyot o zhivom progone odnoagentnogo epizoda](../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [FUM-STEP-0112 — zamknutyiye vozobnovleniye i zhivaya priyomka odnoagentnogo epizoda](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [FUM-STEP-0080 — vyibor, byudzhetyi i usloviye ostanovki](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0080-dobavitj-vyibor-byudzhetyi-i-usloviye-ostanovki-epizoda.md)
- [FUM-STEP-0081 — avtonomnaya priyomka raspredelyonnogo myisliteljnogo epizoda](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0081-provesti-avtonomnuyu-priyomku-raspredelyonnogo-myisliteljnogo-epizoda.md)
- [pasport nachaljnogo korobochnogo prototipa FUM](43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)
- [minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:47:26 MSK -->
<!-- content-sha256: sha256:ed396a53691920c24474d8a1cc276945a849c9557a6737c9dc6d1b8c7245b358 -->
<!-- FUM-MD-RECENCY:END -->
