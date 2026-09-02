# Zhivoj odnoagentnyij epizod

Etot SwiftPM-prototip proveryayet versionnyiye pasport, sobyitiya, chistyij reduktor i odin uzkij skvoznoj odnoagentnyij scenarij [FUM](../../Glossarij/FUM.md). Sobstvennyij runtime chereduyet model-only-shag, razbor namereniya, razreshyonnoye lokaljnoye dejstviye, nablyudeniye, proverku i resheniye o prodolzhenii, khranit live-sobyitiya v kanonicheskikh pokoleniyakh i ostavlyayet core-target bez fajlovyikh, Git-, workspace- i provider-effektov.

Prototip yavlyayetsya uzkim kontraktnyim stendom odnogo lokaljnogo kataloga epizoda i odnogo sinteticheskogo Git-istochnika. Avtonomnyij recorded-harness i otdeljnyij opt-in zhivoj progon podtverdili etot odin scenarij. Rezuljtat ne predstavlyayet gotovuyu [korobochnuyu realizaciyu FUM](../../Glossarij/korobochnaya-realizaciya-FUM.md), polnyij ili universaljnyij agentskij runtime libo raspredelyonnyij FUM, ne integriruyet i ne publikuyet kandidat i ne dokazyivayet preimusjhestvo nad kontroljnyim agentom.

## Sostav paketa

SwiftPM-paket `FUMLiveSingleAgentEpisode` predostavlyayet bibliotechnyij produkt i target `FUMLiveEpisodeCore`. V core nakhodyatsya tipyi pasporta, sobyitij i sostoyaniya, strogij razbor namereniya, byudzhetnoye resheniye `request-or-checkpoint`, chistyij reduktor i tipizirovannyiye otkazyi.

Bibliotechnyij produkt i target `FUMLiveEpisodeRuntime` dobavlyayut pokoleniye epizoda, adapter skhemonezavisimogo khranilisjha, pyatj versionnyikh komand i yavnuyu granicu model-only-adaptera. Runtime ispoljzuyet toljko tochnyiye lokaljnyiye zavisimosti: `FUMReproducibleMemoryPopulation` dlya kanonicheskikh bajtov i obsjhego protokola `CURRENT`, a `FUMPureModelStep` — dlya sovmestimoj modeljnoj granicyi. Core ot etikh paketov ne zavisit.

Ispolnyayemyij produkt i target `FUMLiveEpisodeProbe` bez argumentov sokhranyayut prezhnyuyu bezopasnuyu konstantnuyu fiksturu, a s yavnoj komandoj chitayut odin JSON-konvert versii `1` iz stdin i pechatayut kanonicheskij JSON versii `1` profilya `fum.memory.canonical-json.v1`. Obyichnyij CLI ne podklyuchayet zhivoj provider.

Otdeljnyij ispolnyayemyij target `FUMLiveCandidateAcceptanceProbe` prinimayet toljko yavnyij katalog epizoda i stroguyu JSON-komandu s tochnyim candidate OID. On zanovo chitayet podtverzhdyonnyij `CURRENT`, Git-obyyektyi i pasport, a zatem sokhranyayet tipizirovannuyu kvitanciyu bez merge, rebase ili push.

Ispolnyayemyij target `FUMLiveEpisodeWorker` vyipolnyayet odin dolgovechnyij shag toljko iz yavnogo run directory, publikuyet podtverzhdyonnyij checkpoint-marker i predostavlyayet otdeljnyij `--replay` bez effektov. `FUMLiveEpisodeHarness` gotovit versionnyij scenarij, zapuskayet novyiye worker-processyi, proveryayet dve smyislovyiye kontroljnyiye tochki, fakticheski posyilayet `SIGKILL`, vyizyivayet otdeljnuyu priyomku i audiruyet replay.

Targets `FUMLiveEpisodeCoreTests` i `FUMLiveEpisodeRuntimeTests` proveryayut chistuyu skhemu, podtverzhdyonnoye khranilisjhe, komandyi, povtor, CAS, povrezhdeniye, byudzhet, provider-rubezh, avarijnoye vozobnovleniye i no-call replay.

## Sobyitijnyij kontrakt

Kanonicheskaya identity sobyitiya — `fum.live_single_agent_episode.event`, versiya — `1`. Ona namerenno ne prodolzhayet i ne pereimenovyivayet `fum.agent_cycle.trace`: skhemyi i fiksturyi trassyi versij `1`–`3` ostayutsya otdeljnyim sovmestimyim konturom.

Pasport zakreplyayet celj, kontekst, provider identity i rezhim, raskryitiye dannyikh, shestj byudzhetov, allowlist dejstvij, kriterii proverki, kontroljnyiye tochki i terminaljnyiye iskhodyi. Reduktor vedyot nezavisimyiye modeljnuyu osj i osj vneshnego perekhoda. Kazhdoye vneshneye svideteljstvo svyazano s tochnoj pyatyorkoj `(episode_id, transition_id, schema_version, object_id, expected_effect_sha256)`; vnutrennij `selected_in_model` ne podmenyayet podtverzhdeniye, avtorizaciyu, preflight, ispolneniye ili nablyudeniye.

Avtonomnaya fikstura prorabatyivayet ne meneye dvukh variantov ot obsjhego predka i sokhranyayet proiskhozhdeniye kazhdogo. Vnutrennij vyibor vyivoditsya toljko iz sokhranyonnogo model-only-otveta i strogo razobrannogo namereniya. Yesli rezerviruyemaya stoimostj sleduyusjhego vyizova ne pomesjhayetsya khotya byi v odin primenimyij byudzhet, core vozvrasjhayet resheniye sozdatj kontroljnuyu tochku bez novogo zaprosa. Nulevoj denezhnyij ostatok dopuskayet toljko dokazanno besplatnyij lokaljnyij vyizov pri dostatochnosti ostaljnyikh byudzhetov.

Povtor tochnogo sobyitiya idempotenten. Povtor object identity s inyim soderzhaniyem, neizvestnaya versiya, narushennyij poryadok, podmena identity, cross-transition-svideteljstvo, nedoverennoye pole dejstviya, vyibor bez model-only-sobyitiya i lozhnoye povyisheniye statusa dayut tipizirovannyij otkaz. Posle terminaljnogo resheniya modeljnoj osi novyiye modeljnyiye sobyitiya zakryityi, no uzhe obyyavlennyij ozhidayusjhij perekhod mozhet projti pozdnyuyu stroguyu cepochku sobstvennyikh svideteljstv.

## Pokoleniya i `CURRENT`

`LiveEpisodeGeneration` imeyet identity `fum.live_single_agent_episode.generation` i versiyu `1`. Kanonicheskij nositelj khranit profilj bajtov, versiyu politiki reduktora, ssyilku na predyidusjheye pokoleniye, SHA-256 pasporta, sobyitijnogo zhurnala, zhurnala invocation-receipts i sostoyaniya, neizmenyayemyij pasport, kumulyativnyij `LiveEpisodeEventJournal` i tipizirovannyiye receipts modeljnyikh popyitok. Receipt zakreplyayet tekhnicheskiye identifikatoryi, predlozheniye s reservation i khyesh polnoj komandyi, no ne dubliruyet syiroj modeljnyij input v pokolenii. Sostoyaniye pri chtenii zanovo vyivoditsya chistyim reduktorom; sokhranyonnyij `state_sha256` obyazan sovpastj s kanonicheskim rezuljtatom replay.

`LiveEpisodeGenerationStore` yavlyayetsya domennyim adapterom obsjhego `ContentAddressedGenerationStore`, a ne kopiyej `MemoryGenerationStore`. Obsjheye yadro yedinozhdyi realizuyet adresnyiye fajlyi, staging, `fsync`, postoyannuyu blokirovku, CAS i atomarnuyu zamenu `CURRENT.json`; adapter live-epizoda proveryayet svoyu skhemu, khyeshi, tot zhe pasport, tochnyiye prefiksyi sobyitij i receipts i nepustoj dopustimyij sobyitijnyij suffiks. Kazhdyij provider- ili budget-owned event trebuyet sovpadayusjhij receipt; `append_events` ne mozhet poddelatj runtime-owned zapros, otvet, byudzhetnuyu tochku ili podtverzhdeniye pokoleniya.

Dejstviye `confirm_generation` samo sozdayot `generation_confirmed`, kotoroye dolzhno byitj pervyim novyim sobyitiyem i ssyilatjsya na tochnyiye identifikator, posledovateljnostj i khyesh sostoyaniya predyidusjhego `CURRENT`. Vyizyivayusjhij kod ne peredayot proizvoljnoye telo etogo sobyitiya.

Vozobnovleniye chitayet toljko polnostjyu proverennoye pokoleniye po `CURRENT`. Sirota v `generations/`, staging-khvost, kandidat s ustarevshim roditelem libo povrezhdyonnyiye ukazatelj, pokoleniye, khyesh ili replay ne stanovyatsya tekusjhimi. Novyij process vosstanavlivayet iz kataloga pasport, byudzhet, ozhidayusjhij perekhod, variantyi, vnutrennij vyibor i terminaljnyij iskhod, ne poluchaya prezhnij chat ili skryitoye sostoyaniye processa.

## Git-kandidat

Pasport kandidatnogo epizoda dopuskayet rovno odno dejstviye `create_candidate_commit`. Yego policy zakreplyayet ogranichennyiye puti, checker ID i yego odnoznachnoye zakryitoye otobrazheniye v argv-grammatiku i realizaciyu, base/tree/candidate OID, otdeljnyiye candidate branch i result ref, a takzhe vsyu determinirovannuyu commit-identity. Nedoverennyij modeljnyij tekst ne stanovitsya podtverzhdeniyem ili kvitanciyej; neizvestnyij ID ili nesovpadayusjhaya sokhranyonnaya grammatika otklonyayutsya do publikacii.

Uzkiye doverennyiye interfejsyi posledovateljno sokhranyayut `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed` i `observed` s sobstvennyimi evidence, producer ID i khyeshami predshestvennikov. Obsjhij `append_events` ne mozhet poddelatj ni odnu iz pyati stadij. Nachinaya s preflight zhurnal yedinovremenno zakreplyayet SHA-256 polnoj komandyi i zadannyij yeyu ID podtverzhdeniya observation; eta para neizmenno perenositsya vo vse posleduyusjhiye pokoleniya. Posle avarii neljzya prodolzhitj chuzhim ili izmenyonnyim planom.

Git-adapter sozdayot otdeljnyij clone vne iskhodnogo checkout, do pervoj zapisi descriptor-relative proveryayet ownership marker, kanonicheskuyu config i obyichnyiye nesvyazannyiye `objects`/`refs`, stroit kandidata iz tochnogo base commit, sveryayet tree, diff i proverki, a zatem publikuyet toljko pryamyiye lokaljnyiye ref cherez CAS. Fiksirovannyiye sistemnyiye puti Git, null-device i zapresjhayusjhej komandyi sobranyi v odnom uzkom `LiveGitSystemRuntime`; ostaljnyiye iskhodniki i testovyiye ranneryi ispoljzuyut yego tipizirovannyiye znacheniya, a otricateljnyiye path-fiksturyi zakreplenyi otdeljnyimi postrochnyimi fingerprints. Obryiv posle hardlink-publikacii pasporta vosstanavlivayetsya toljko dlya odnogo tochnogo sobstvennogo same-inode alias; chuzhoj ili neodnoznachnyij alias otklonyayetsya. `executed` sokhranyayetsya do otdeljnogo observer, kotoryij zanovo chitayet ref, commit, tree, diff, blobs, proverki i pasport. Iskhodnyiye ref, indeks, worktree i Git-metadannyiye ostayutsya bez izmenenij.

Process priyomki ne doveryayet in-memory-rezuljtatu ispolnitelya. On poluchayet toljko katalog epizoda i candidate OID, neblokiruyusjhe chitayet podtverzhdyonnyij `CURRENT`, tochnoye pokoleniye i pasport cherez uzhe otkryityiye deskriptoryi, dokazyivayet tochnuyu finaljnuyu paru observation/podtverzhdeniye po sokhranyonnomu command-specified ID i dajdzhestu predyidusjhego pokoleniya, nezavisimo povtoryayet proverku clone metadata, commit, NUL-diff i checker registry do i posle Git-nablyudeniya i sokhranyayet `accepted` ili `rejected`, ne vyipolnyaya merge, rebase ili push.

## Komandyi JSON

Versiya `1` predostavlyayet komandyi `create`, `inspect`, `status`, `resume` i `replay`. Vse oni trebuyut strogij JSON-obyyekt s `schema_version` i `command_id`; neizvestnyiye versii i polya otklonyayutsya. `resume` dopolniteljno zakreplyayet `expected_generation_sha256` i odno dejstviye: `append_events`, `confirm_generation` libo `invoke_model`.

- `create` podtverzhdayet pasport i toljko nachaljnyiye `model_checkpoint_created` libo `pending_transition_declared`;
- `inspect` vozvrasjhayet polnoye podtverzhdyonnoye pokoleniye i vosproizvedyonnoye sostoyaniye;
- `status` vozvrasjhayet kratkiye khyeshi, sleduyusjhij nomer sobyitiya, byudzhet, nereshyonnyiye zaprosyi, fazu perekhoda i terminaljnyij iskhod;
- `resume` podtverzhdayet dopustimyij sobyitijnyij suffiks ili prokhodit modeljnyij rubezh;
- `replay` povtorno stroit to zhe kanonicheskoye sostoyaniye bez model-, tool-, Git- i workspace-vyizovov.

Mutiruyusjhiye otvetyi razlichayut `created`, `advanced`, `checkpointed`, `already_applied` i `provider_outcome_unresolved`. Tochnyij povtor uzhe prinyatogo soderzhaniya idempotenten; otlichayusjhijsya kandidat ot ustarevshego khyesha poluchayet konflikt i ne menyayet `CURRENT`.

`append_events` prinimayet toljko razreshyonnyiye vneshniye tipizirovannyiye sobyitiya; model request/response, byudzhetnuyu tochku i podtverzhdeniye pokoleniya sozdayut sootvetstvuyusjhiye runtime-dejstviya. Poetomu komanda ne mozhet vnedritj gotovoye runtime-owned sobyitiye cherez obsjhij sobyitijnyij suffiks.

## Reservation do provider-vyizova

Dejstviye `invoke_model` snachala proveryayet input hash, disclosure i tekhnicheskiye identifikatoryi i sveryayet polnyij publichnyij kontrakt adaptera s neizmenyayemoj modeljnoj politikoj pasporta. Toljko posle etogo predlozheniye poluchayet chistyij planner. Pri nedostupnom byudzhete runtime podtverzhdayet otdeljnoye sobyitiye kontroljnoj tochki i invocation-receipt, ne vyizyivaya adapter. Pri dostatochnom byudzhete on zapisyivayet `model_request_recorded` i receipt s khyeshem komandyi i tochnoj reservation, publikuyet novoye `CURRENT` i toljko zatem peresekayet provider-granicu.

Posle podtverzhdyonnogo reservation-checkpoint predusmotren nablyudayemyij failpoint: vneshnij testovyij harness poluchayet marker, ostanavlivayet process, zavershayet yego cherez `SIGKILL` i zapuskayet novyij PID s odnim lishj katalogom epizoda. Yesli provider-iskhod oborvalsya do sokhranyonnogo otveta adaptera, zapros ostayotsya zarezervirovannyim i nereshyonnyim. Novyij runtime vozvrasjhayet `provider_outcome_unresolved`, ne povtoryayet vyizov avtomaticheski i ne spisyivayet reservation vtoroj raz.

Vozvrasjhyonnyij rezuljtat adaptera sveryayetsya s tochnyimi invocation, input i provider identity i zapisyivayetsya otdeljnyim `model_response_recorded`; dostovernyij raskhod proveryayetsya pokomponentno i ne mozhet prevyisitj reservation. Yavno vernuvshiyesya provider-timeout ili `unknown_usage` stanovyatsya neuspeshnyim otvetom s konservativnyim odnokratnyim spisaniyem polnogo reservation. Runtime ne prinimayet usage iz teksta modeli. `append_events` toljko podtverzhdayet uzhe tipizirovannyiye live-sobyitiya i ne ispolnyayet opisannoye imi vneshneye dejstviye.

## Skvoznoj harness

Rezhim `recorded` prokhodit tot zhe sobstvennyij runtime s dvumya zapisannyimi model-only-otvetami. Harness podtverzhdayet kontroljnyiye tochki posle vnutrennego vyibora i posle nablyudeniya kandidata, dvazhdyi zavershayet worker cherez `SIGKILL` i kazhdyij raz vozobnovlyayet epizod novyim PID toljko iz podtverzhdyonnogo `CURRENT`. Tretij worker poluchayet otdeljnuyu priyomku i zavershayet epizod rovno iskhodom `completed`. Dva replay-processa vozvrasjhayut pobajtovo odinakovuyu zakreplyonnuyu proyekciyu i ne menyayut run directory; tretij variant zavershayetsya byudzhetnoj kontroljnoj tochkoj bez tretjyego model-vyizova.

Otdeljnyij opt-in progon ispoljzoval provider `lmstudio`, API `REST v0`, modelj `qwen/qwen3-0.6b` i runtime `llama.cpp-mac-arm64-apple-metal-advsimd@2.27.1`. Doverennyij usage sostavil `calls=2`, `input=433`, `output=381`, `wall=3153ms`, `compute=3153`, `money=0`. Worker PID `58614` i `58639` byili zavershenyi cherez `SIGKILL`; PID `58758` vozobnovil epizod do `completed`, a otdeljnyij PID `58761` sokhranil `accepted`. Izolirovannyij kandidat `27b70453870750f7504db957176aec88f90705ea` imeyet roditelya `8c7ef0d85b6daae8fa9da249c0fe8932af2acd6e` i derevo `f7ba19785b4baa61770683c46cece0ec58e7d3a7`. Sinteticheskij source ostalsya neizmennyim, a posle progona provider vozvrasjhyon v iskhodnoye sostoyaniye `off`/pusto. Polnaya publikacionno chistaya trassa privedena v [otchyote o zhivom progone](Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md).

## Zapusk

Iz kornya repozitoriya bezopasnyij avtonomnyij probe zapuskayetsya bez perekhoda v katalog:

```bash
./Прототипы/живой-одноагентный-эпизод/запустить.sh
```

Tot zhe produkt mozhno zapustitj sredstvami SwiftPM:

```bash
swift run --package-path Прототипы/живой-одноагентный-эпизод FUMLiveEpisodeProbe
```

Obe komandyi ispoljzuyut toljko vstroyennuyu fiksturu. Oni ne chitayut poljzovateljskiye fajlyi, ne vyizyivayut Git, modelj, setj ili vneshniye servisyi.

Dlya rabotyi s katalogom epizoda komanda ukazyivayetsya yavno, a odin strogij JSON-konvert versii `1` peredayotsya cherez stdin:

```bash
printf '%s\n' '<JSON-команда-версии-1>' | \
  ./Прототипы/живой-одноагентный-эпизод/запустить.sh \
  <create|inspect|status|resume|replay> <каталог-эпизода>
```

Katalog vyibirayetsya vyizyivayusjhim processom. Dlya vremennoj proverki yego sleduyet razmesjhatj vne repozitoriya; sam CLI ne isjhet prezhnij chat, Git-vetku ili workspace i ne vyibirayet drugoj epizod avtomaticheski.

Avtonomnyij recorded-harness bez seti i zhivoj modeli zapuskayetsya toljko yavnyim rezhimom:

```bash
./Прототипы/живой-одноагентный-эпизод/запустить.sh recorded
```

Otdeljnyij opt-in zhivoj progon trebuyet yavnogo rezhima `live`:

```bash
./Прототипы/живой-одноагентный-эпизод/запустить.sh live
```

Bez puti oba rezhima sozdayut kontroliruyemyij vremennyij katalog i udalyayut yego posle zaversheniya. Dlya sokhraneniya artefaktov mozhno peredatj rovno odin zaraneye sozdannyij pustoj katalog: `запустить.sh <recorded|live> <пустой-run-directory>`. Rezhim `live` ne zapuskayet LM Studio, ne zagruzhayet modelj, ne isjhet novyiye sekretyi i zakryivayetsya pri nedostupnoj ili nesovpadayusjhej zaraneye dostupnoj provider identity.

Otdeljnaya headless-priyomka zapuskayetsya toljko dlya yavnogo kataloga i tochnogo OID:

```bash
printf '%s\n' '{"candidate_oid":"<exact-oid>","command_id":"accept-candidate","schema_version":1}' | \
  swift run --package-path Прототипы/живой-одноагентный-эпизод \
  FUMLiveCandidateAcceptanceProbe <каталог-эпизода>
```

Obyichnyij `resume` s dejstviyem `invoke_model` bez vnedryonnogo bibliotechnogo adaptera vozvrasjhayet otkaz do reservation, provider-vvoda-vyivoda i izmeneniya `CURRENT`. Nablyudayemyij avarijnyij scenarij vklyuchayetsya toljko yavno: `FUM_LIVE_EPISODE_FAILPOINT=reservation-generation-confirmed` i `FUM_LIVE_EPISODE_FAILPOINT_MARKER` s absolyutnyim putyom marker-fajla vne kataloga epizoda. Posle podtverzhdeniya reservation CLI zapisyivayet kanonicheskij marker s versiyej, kontroljnoj tochkoj, PID i SHA-256 pokoleniya i posyilayet sebe `SIGSTOP`; vneshnij harness proveryayet marker i otpravlyayet `SIGKILL`.

## Proverka

Avtonomnyiye testyi zapuskayutsya lokaljno bez sekretov, seti i zhivoj modeli:

```bash
swift test --package-path Прототипы/живой-одноагентный-эпизод
```

Devyatnadcatj core-scenariyev proveryayut polnyij dopustimyij poryadok modeljnyikh i perekhodnyikh sobyitij, dvukhvariantnoye prodolzheniye, strogij vyivod `selected_in_model`, ischerpaniye kazhdogo byudzheta, besplatnyij lokaljnyij vyizov pri nulevom denezhnom ostatke, idempotentnoye vosproizvedeniye i zakryituyu pyatistadijnuyu cepochku kandidatnogo dejstviya. Shestjdesyat chetyire runtime-scenariya dopolniteljno pokryivayut pyatj prezhnikh CLI-komand, provider-putj, podtverzhdyonnoye sozdaniye Git-kandidata, otdeljnuyu headless-priyomku, tochnyiye povtoryi, CAS, povrezhdeniye, neizvestnyiye versii, avarijnoye vosstanovleniye, zakreplyonnyij replay, budget no-call, kanonicheskuyu versionnostj vozobnovlyayemyikh artefaktov i tochnuyu svyazj acceptance-output s sokhranyonnoj receipt. Otdeljnyij avtonomnyij recorded-harness proveryayet oba fakticheskikh `SIGKILL` s `CURRENT`-only-vozobnovleniyem i zakreplyonnuyu skvoznuyu proyekciyu. Git-fiksturyi otdeljno proveryayut sovmestimostj adapter→acceptance, hardlink-podmenyi pasporta i acceptance-receipt, absolyutnyij putj, traversal, symlink/hardlink/FIFO escape, metadata alias, hostile Git config, neizvestnyij checker ID, nesovpavshuyu grammar, neozhidannyij diff, izmenivshuyusya bazu, proval checker, cross-transition-podmenu, lozhnoye modeljnoye podtverzhdeniye, chuzhoye ili pozdneye podtverzhdeniye observation, crash do receipt i mezhdu publikaciyej pasporta i udaleniyem temp-alias, konflikt result ref i otkaz priyomki, ne izmenyaya iskhodnyij checkout.

## Granicyi

Core-target ne vyipolnyayet fajlovyikh, Git-, workspace-, provider-, setevyikh ili GUI-effektov. Runtime dobavlyayet podtverzhdyonnoye lokaljnoye khranilisjhe, bezokonnyiye komandyi, yavnuyu model-only-granicu i uzkij lokaljnyij Git-adapter. Zhivoj progon dokazyivayet rabotu zhivoj modeli i skvoznogo model-to-action-puti toljko v etom zaraneye zaregistrirovannom sinteticheskom scenarii. Harness-podtverzhdeniye kontroljnoj tochki ne yavlyayetsya zhivyim kanalom poljzovateljskogo podtverzhdeniya ili obsjhim vneshnim avtorizatorom.

Stend podderzhivayet odin lokaljnyij epizod, odin izolirovannyij candidate clone i nedostupnyij po umolchaniyu zhivoj provider. Kandidat ostayotsya lokaljnyim i neintegrirovannyim; ni harness, ni [zavershyonnaya FUM-STEP-0112](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md) ne vyipolnyayut merge, rebase, push ili publikaciyu. Power-loss durability i proizvoljnyiye zadachi i dejstviya za predelami pasporta ne proverenyi.

## Istochniki

- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [otchyot o zhivom progone odnoagentnogo epizoda](Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [iskhodnyij zapros 2026-08-01 14:29:41 MSK — Realizovatj izolirovannyij kandidatnyij kommit i otdeljnuyu priyomku](../../Zhurnal/2026-08-01_14-29-41_MSK_realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku/zapros.md)
- [FUM-STEP-0111 — izolirovannyij kandidatnyij kommit i otdeljnaya priyomka](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0111-realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku.md)
- [iskhodnyij zapros 2026-08-01 11:56:54 MSK — Realizovatj podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](../../Zhurnal/2026-08-01_11-56-54_MSK_realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda/zapros.md)
- [FUM-STEP-0110 — podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0110-realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda.md)
- [iskhodnyij zapros 2026-07-31 21:37:26 MSK — Vvesti skhemu sobyitij zhivogo odnoagentnogo epizoda](../../Zhurnal/2026-07-31_21-37-26_MSK_vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda/zapros.md)
- [kontrakt zhivogo odnoagentnogo epizoda FUM](../../Dokumentaciya/48-kontrakt-zhivogo-odnoagentnogo-epizoda.md)
- [FUM-STEP-0109 — skhema sobyitij zhivogo odnoagentnogo epizoda](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0109-vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii pri ozhidanii podtverzhdeniya](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md)
- [minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:32bff6966cd9a1905b9caaf6e6a8d25ca55d1b2d4543ae038a3715e0455b3b97 -->
<!-- FUM-MD-RECENCY:END -->
