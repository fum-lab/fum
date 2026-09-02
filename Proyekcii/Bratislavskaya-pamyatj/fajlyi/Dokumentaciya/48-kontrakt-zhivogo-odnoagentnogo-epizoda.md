# Kontrakt zhivogo odnoagentnogo epizoda FUM

Zhivoj odnoagentnyij epizod zadayot sobstvennyij versionnyij sobyitijnyij kontur [FUM](../Glossarij/FUM.md). Chistyij reduktor vosproizvodit yego bez effektov, a otdeljnyij bezokonnyij runtime podtverzhdayet kanonicheskiye pokoleniya, vozobnovlyayet odin lokaljnyij epizod mezhdu processami, rezerviruyet modeljnyij byudzhet do provider-vyizova i mozhet sozdatj tochno zakreplyonnyij Git-kandidat v izolirovannom clone. Kanonicheskaya identity sobyitiya — `fum.live_single_agent_episode.event`, versiya — `1`. Odin uzkij zhivoj [agentskij cikl](../Glossarij/agentskij-cikl.md) zamknut do otdeljnoj priyomki i terminaljnogo iskhoda; kandidat ne integriruyetsya avtomaticheski, a obsjhij cikl dlya proizvoljnyikh zadach ne schitayetsya realizovannyim.

Novaya semjya sobyitij otdelena ot `fum.agent_cycle.trace`. Skhemyi, bajtyi, fiksturyi i proverki trass versij `1`–`3` sokhranyayut prezhniye identity i smyisl; live-sobyitiya ne pereimenovyivayut ikh i ne stanovyatsya ikh versiyej `4`. [Minimaljnyij format trassyi](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) ostayotsya nablyudayemyim fiksturnyim i zhurnaljnyim predstavleniyem, togda kak etot kontrakt opredelyayet perekhodyi sobstvennogo runtime mezhdu tipizirovannyimi sostoyaniyami.

## Pasport epizoda

Pervoye sostoyaniye epizoda zakreplyayet odin neizmenyayemyij versionnyij pasport. On soderzhit identity i celj epizoda, nachaljnyij kontekst, identity modeljnogo provajdera i runtime, lokaljnyij ili udalyonnyij rezhim, razreshyonnyiye klassyi, obyyom i naznacheniye raskryitiya dannyikh, a takzhe vse primenimyiye byudzhetyi: chislo vyizovov, vkhodnyiye i vyikhodnyiye tokenyi, wall-clock-vremya, vyichisliteljnyij resurs i denjgi.

Tot zhe pasport zadayot konechnyij allowlist dejstvij, kriterii proverki, dopustimyiye kontroljnyiye tochki i terminaljnyiye iskhodyi. Svobodnyij tekst modeli ne mozhet dobavitj dejstviye, proverku, iskhod, provajdera ili byudzhet. Sobyitiya sveryayutsya s identity i versiyej live-skhemyi, identity epizoda i tochnoj identity provajdera. Runtime khranit neizmenyayemyij pasport i yego kanonicheskij SHA-256 v kazhdom podtverzhdyonnom pokolenii; chistyij reduktor po-prezhnemu poluchayet odin i tot zhe pasport dlya vsego replay.

Zamknutyij scenarij dobavlyayet verkhnij exact-pasport ispolneniya. On pobajtovo fiksiruyet dva sinteticheskikh model-only-vkhoda i ozhidayemyiye kanonicheskiye namereniya, tochnuyu tokenizaciyu, provider i runtime identity, konechnyiye byudzhetyi i raskryitiye, yedinstvennyij Git-allowlist, proverki, dve process-crash-tochki i dopustimyiye terminaljnyiye iskhodyi. Yego SHA-256 zakreplyon v obsjhem modeljnom predke, a kazhdyij novyij process do prodolzheniya povtorno trebuyet yego tochnoye sovpadeniye s podtverzhdyonnyim `CURRENT`.

Pasport yavlyayetsya predelom polnomochij, a ne komandoj na ispolneniye. Dazhe razreshyonnoye dejstviye prokhodit otdeljnyiye podtverzhdeniye, avtorizaciyu i preflight dlya tochnogo perekhoda. Terminaljnyij iskhod vyibirayetsya toljko iz obyyavlennogo pasportom nabora i delayet daljnejsheye soderzhateljnoye sobyitiye nedopustimyim.

## Dve nezavisimyiye osi sostoyaniya

Chistyij reduktor vedyot modeljnuyu osj i osj vneshnego perekhoda nezavisimo. Ozhidaniye podtverzhdeniya ne ostanavlivayet konechnuyu model-only-proverku variantov, a zaversheniye vnutrennego vyibora ne prodvigayet vneshnij perekhod.

Modeljnaya osj razlichayet zapros modeli, sokhranyonnyij otvet, strogo razobrannoye nedoverennoye namereniye, proverku variantov, vnutrennij vyibor `selected_in_model`, resheniye o prodolzhenii i kontroljnuyu tochku. [Chistyij modeljnyij shag](../Glossarij/chistyij-modeljnyij-shag.md) postavlyayet toljko rezuljtat modeljnoj chasti; yego tekst ne schitayetsya faktom raskhoda, avtorizacii ili ispolneniya.

Osj perekhoda razlichayet sozdaniye ozhidayusjhego perekhoda, `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed`, `observed` i proverku rezuljtata. Kazhdoye prodvizheniye trebuyet sobstvennogo sobyitiya i sobstvennogo svideteljstva. Podtverzhdeniye pokoleniya khranitsya otdeljnyim sostoyaniyem vsego epizoda i svyazyivayet resheniye o prodolzhenii s uzhe prinyatoj posledovateljnostjyu. Resheniye o prodolzhenii toljko fiksiruyet vyibor runtime: ono ne sozdayot sleduyusjhij zapros i ne sinteziruyet otsutstvuyusjheye vneshneye svideteljstvo.

Terminaljnyij iskhod modeljnoj chasti zapresjhayet novyiye modeljnyiye zaprosyi, otvetyi, razboryi, vyiboryi i resheniya, no ne unichtozhayet obyyavlennyij ozhidayusjhij perekhod. Dlya nego po-prezhnemu razreshena toljko strogaya cepochka pozdnikh sovpadayusjhikh sobyitij podtverzhdeniya, avtorizacii, preflight, ispolneniya, nablyudeniya i proverki. Poetomu konechnaya model-only-proverka i vneshnij perekhod dejstviteljno zavershayutsya nezavisimo.

Poryadok sobyitij yavlyayetsya chastjyu kontrakta. Otvet ne prinimayetsya bez predshestvuyusjhego zaprosa, namereniye — bez sokhranyonnogo otveta, dejstviye — bez sovpadayusjhikh podtverzhdeniya, avtorizacii i preflight, nablyudeniye — bez ispolneniya, a proverka rezuljtata — bez nablyudeniya. Narushennyij poryadok ne ispravlyayetsya dogadkoj reduktora.

## Svideteljstva i strogoye namereniye

Kazhdoye svideteljstvo vneshnego perekhoda tochno svyazano s odnoj pyatyorkoj `(episode_id, transition_id, schema_version, object_id, expected_effect_sha256)`. Sovpadeniye toljko chasti polej nedostatochno. Svideteljstvo drugogo perekhoda, obyyekta, epizoda, effekta ili versii ne perenositsya i ne povyishayet sostoyaniye.

Namereniye ostayotsya nedoverennyim dazhe posle sintaksicheskogo razbora. Strogij razbor poluchayet toljko sokhranyonnyij model-only-otvet, prinimayet zakryituyu grammatiku i sveryayet identifikator dejstviya s pasportnyim allowlist. Neizvestnoye pole dejstviya, svobodnaya argv-stroka, nepodderzhannoye dejstviye ili nesovpadayusjhij identifikator perekhoda dayut otkaz. Vneshnij vyizyivayusjhij kod ne mozhet peredatj gotovoye `selected_in_model` vmesto otveta i razbora.

`selected_in_model` voznikayet toljko iz sochetaniya sokhranyonnogo model-only-otveta i uspeshno razobrannogo namereniya. Etot vnutrennij vyibor sokhranyayet proiskhozhdeniye, no ne sozdayot `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed` ili `observed` i ne obyyavlyayet rezuljtat prinyatyim kanonicheskim sostoyaniyem.

Perekhod iz etogo vyibora v dejstviye trebuyet vneshneye svideteljstvo, svyazannoye s exact generation i state SHA-256 pervoj kontroljnoj tochki. Zaraneye izvestnyij literal, povtornyij zapusk ili sam vnutrennij vyibor ne zamenyayut etogo svideteljstva. Runtime proveryayet yego do avtorizacii i pervoj Git-zapisi.

## Variantyi, byudzhetyi i kontroljnaya tochka

Avtonomnaya fikstura sozdayot ne meneye dvukh soderzhateljno razlichnyikh variantov ot odnogo tochnogo obsjhego predka. Kazhdyij variant khranit sobstvennyij identifikator, ssyilku na predka, vyidelennyij byudzhet, modeljnyiye zapros i otvet, razobrannoye namereniye i rezuljtat proverki. Proiskhozhdeniye proigravshego varianta ne udalyayetsya posle vnutrennego vyibora.

Pered sleduyusjhim modeljnyim vyizovom chistyij planner prinimayet obyyavlennuyu rezerviruyemuyu stoimostj i vozvrasjhayet resheniye `request-or-checkpoint`. Vyizov dopustim, toljko yesli yego polnaya rezerviruyemaya stoimostj pomesjhayetsya vo vse primenimyiye ostatki pasporta. Skhema versii `1` trebuyet pasportnuyu politiku kontroljnoj tochki pri byudzhetnom otkaze: yesli khotya byi odnogo ostatka nedostatochno, planner vozvrasjhayet tochnyij payload tochki, a vyizyivayusjhij runtime primenyayet yego otdeljnyim sobyitiyem bez novogo modeljnogo zaprosa. Nulevoj denezhnyij ostatok sam po sebe ne zapresjhayet dokazanno besplatnyij lokaljnyij vyizov s nulevoj rezerviruyemoj stoimostjyu; ostaljnyiye primenimyiye byudzhetyi pri etom proveryayutsya bez oslableniya.

Ozhidaniye podtverzhdeniya ne raskhoduyet i ne uvelichivayet byudzhet. Modeljnyij otvet ne mozhet obyyavitj sobstvennuyu stoimostj ili vernutj spisannyij resurs. Sobyitiya reservation i podtverzhdyonnogo potrebleniya ostayutsya razdeljnyimi, a podtverzhdyonnoye khranilisjhe vosproizvodit ikh konservativnyij ostatok bez avtomaticheskogo povtora neodnoznachnogo vyizova.

V zamknutom scenarii dva exact model-only-varianta poluchayut odin obsjhij predok i konechnyij byudzhet. Tretjye predlozheniye zavershayetsya zakreplyonnoj byudzhetnoj tochkoj do `model_request_recorded`; avtonomnaya fikstura trebuyet rovno dva otveta i otsutstviye novogo model-only-vyizova.

## Podtverzhdyonnyiye pokoleniya i vozobnovleniye

Pokoleniye `fum.live_single_agent_episode.generation` versii `1` khranit profilj kanonicheskikh bajtov, versiyu politiki reduktora, tochnyij SHA-256 predyidusjhego pokoleniya, khyeshi pasporta, sobyitijnogo zhurnala, zhurnala invocation-receipts i sostoyaniya, sam neizmenyayemyij pasport, kumulyativnyij zhurnal sobstvennyikh `LiveEpisodeEvent` i tipizirovannyiye receipts modeljnyikh popyitok. Receipt zakreplyayet tekhnicheskiye identifikatoryi, predlozheniye s reservation i khyesh polnoj komandyi, no ne dubliruyet syiroj modeljnyij input v pokolenii. Sostoyaniye ne stanovitsya vtoroj nezavisimo redaktiruyemoj istinoj: pri kazhdom chtenii runtime povtorno primenyayet sobyitijnyij zhurnal k pasportu chistyim reduktorom, vyichislyayet kanonicheskij khyesh rezuljtata i trebuyet sovpadeniya s `state_sha256`. Kazhdyij provider- ili budget-owned event obyazan imetj rovno odin sovpadayusjhij receipt; proizvoljnoye `append_events` ne mozhet poddelatj eti runtime-owned sobyitiya.

Kandidatnyij epizod dopolniteljno khranit khyesh zhurnala candidate-receipts. Kazhdaya iz pyati stadij zakreplyayet tochnyiye koordinatyi perekhoda, zaregistrirovannogo producer, sobstvennoye svideteljstvo i SHA-256 predyidusjhej kvitancii; receipts obrazuyut neizmenyayemyij prefiks i dvunapravlenno svyazyivayutsya s sobyitiyami. Nachinaya s preflight tot zhe zhurnal yedinovremenno zakreplyayet neizmenyayemuyu paru iz SHA-256 polnoj komandyi i zadannogo yeyu ID podtverzhdeniya observation; smena, razdeleniye, perestanovka, sokrasjheniye ili cross-transition-podmena zakryivayut prodolzheniye.

Khranilisjhe epizoda pereispoljzuyet skhemonezavisimyij `ContentAddressedGenerationStore` iz paketa vosproizvodimoj pamyati. Odno obsjheye yadro vladeyet adresaciyej, staging, `fsync`, mezhprocessnyim compare-and-swap i atomarnoj publikaciyej `CURRENT`; adapter epizoda dobavlyayet svoyu stroguyu skhemu i proverku linii proiskhozhdeniya. Nachaljnoye pokoleniye soderzhit vesj nachaljnyij zhurnal, a preyemnik obyazan sokhranitj tot zhe pasport, tochnyiye prefiksyi sobyitij i invocation-receipts, dobavitj nepustoj dopustimyij sobyitijnyij suffiks i soslatjsya na tekusjhij khyesh. Specialjnoye dejstviye `confirm_generation` samo stroit `generation_confirmed`: eto sobyitiye obyazano byitj pervyim v novom suffikse i svyazyivayet tochnyiye identifikator, posledovateljnostj i khyesh sostoyaniya predyidusjhego `CURRENT`.

Yedinstvennyim istochnikom vozobnovleniya yavlyayetsya polnostjyu proverennyij obyyekt, na kotoryij ukazyivayet `CURRENT.json`. Podgotovlennoye, povrezhdyonnoye, konfliktuyusjheye ili opublikovannoye toljko po adresu pokoleniye ne vyibirayetsya skanirovaniyem kataloga i ne povyishayetsya po vremeni. Iz podtverzhdyonnogo pasporta i zhurnala novyij process determinirovanno vosstanavlivayet ostatki byudzheta, ozhidayusjhij perekhod, vse variantyi, vnutrennij vyibor i terminaljnyij iskhod bez prezhnego chata i skryitogo in-memory-sostoyaniya.

Avtonomnyij harness prinuditeljno zavershayet pervyij PID posle podtverzhdyonnogo vnutrennego vyibora i vtoroj PID posle podtverzhdyonnogo nablyudeniya candidate commit. Oba raza on snachala sveryayet kanonicheskij marker s tekusjhim pokoleniyem, sostoyaniyem i smyislovyim sobyitiyem, zatem posyilayet fakticheskij `SIGKILL` i zapuskayet novyij process s drugim PID. Novyij worker poluchayet toljko run-directory; yego stdin zakryit, a sreda ne perenosit opt-in, provider ili inoye skryitoye sostoyaniye prezhnego processa.

## Bezokonnyiye komandyi

Runtime predostavlyayet pyatj komand versii `1` so strogim JSON-vvodom i kanonicheskim JSON-vyivodom:

- `create` podtverzhdayet pasport i toljko nachaljnyiye `model_checkpoint_created` libo `pending_transition_declared` novogo lokaljnogo epizoda;
- `inspect` vozvrasjhayet podtverzhdyonnoye pokoleniye vmeste s vosproizvedyonnyim sostoyaniyem;
- `status` vyidayot kratkuyu proyekciyu khyeshej, sleduyusjhej posledovateljnosti, byudzheta, nereshyonnyikh modeljnyikh zaprosov, perekhoda i terminaljnogo iskhoda;
- `resume` prodolzhayet tochnyij ozhidayemyij khyesh dejstviyem `append_events`, `confirm_generation` libo `invoke_model`;
- `replay` zanovo stroit kanonicheskoye sostoyaniye toljko iz podtverzhdyonnogo pasporta i zhurnala.

Neizvestnyiye versii i polya otklonyayutsya. Mutiruyusjhaya komanda zakreplyayet ozhidayemyij SHA-256 pokoleniya i ne mozhet molcha prodolzhitj drugogo predka. Tochnyij uzhe primenyonnyij rezuljtat raspoznayotsya idempotentno, togda kak otlichayusjheyesya soderzhimoye s ustarevshim ozhidaniyem dayot konflikt. Otdeljnyij no-call-kontur `replay` ne sozdayot model-, tool-, Git- ili workspace-vyizovov i vozvrasjhayet to zhe kanonicheskoye sostoyaniye, chto obyichnoye podtverzhdyonnoye chteniye.

`append_events` prinimayet toljko dopustimyiye vneshniye tipizirovannyiye sobyitiya. Model request/response, byudzhetnuyu tochku i podtverzhdeniye pokoleniya sozdayut toljko sootvetstvuyusjhiye runtime-dejstviya. Dlya epizoda s `create_candidate_commit` obsjhij interfejs takzhe ne prinimayet gotovyiye `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed` i `observed`: eti stadii prinadlezhat pyati uzkim doverennyim granicam.

Obyichnyij CLI ne podklyuchayet model-only-provajdera: `invoke_model` bez yavno vnedryonnogo bibliotechnogo adaptera zakryivayetsya do reservation, provider-vvoda-vyivoda i izmeneniya `CURRENT`. Tak nalichiye komandyi ne prevrasjhayetsya v skryitoye polnomochiye zhivogo vyizova.

## Rubezh modeljnogo vvoda-vyivoda

Dlya `invoke_model` runtime snachala sveryayet polnyij publichnyij kontrakt adaptera s neizmenyayemoj modeljnoj politikoj pasporta, proveryayet input hash, disclosure i tekhnicheskiye identifikatoryi, a zatem peredayot predlozheniye chistomu planner. Nesovpadeniye zakryivayet komandu do reservation i provider-vvoda-vyivoda. Nedostupnyij byudzhet sozdayot otdeljnoye sobyitiye kontroljnoj tochki i podtverzhdayet yego vmeste s tochnyim invocation-receipt bez obrasjheniya k adapteru. Pri dopustimom vyizove runtime dobavlyayet `model_request_recorded` i receipt s khyeshem komandyi i tochnoj shestimernoj reservation, posle chego publikuyet eto pokoleniye kak `CURRENT` do pervogo provider-vvoda-vyivoda.

Srazu posle podtverzhdyonnogo reservation-checkpoint dostupen nablyudayemyij failpoint: vneshnij harness poluchayet kanonicheskij marker s versiyej, kontroljnoj tochkoj, PID i khyeshem pokoleniya, posle chego process posyilayet sebe `SIGSTOP`; harness mozhet zavershitj yego cherez `SIGKILL`. Novyij PID otkryivayet toljko katalog epizoda. Yesli process pogib libo provider-iskhod oborvalsya do sokhranyonnogo otveta adaptera, podtverzhdyonnyij zapros ostayotsya zarezervirovannyim i nereshyonnyim; svezhij runtime soobsjhayet `provider_outcome_unresolved` i ne povtoryayet yego avtomaticheski.

Kazhdyij vozvrasjhyonnyij rezuljtat adaptera obyazan byitj svyazan s tochnyimi invocation, input i provider identity. Dostovernyij raskhod ne mozhet prevyishatj reservation; yavno vernuvshiyesya provider-timeout ili `unknown_usage` konservativno sozdayut neuspeshnyij `model_response_recorded` so spisaniyem polnogo reservation rovno odin raz. V oboikh sluchayakh otdeljnoye sobyitiye osvobozhdayet rezerv, a povtor ne vyizyivayet provider snova i ne spisyivayet byudzhet povtorno. Vyivod provajdera ne mozhet sam zapisatj usage ili povyisitj dejstviye. Obsjhaya model-only-komanda ne ispolnyayet Git, instrumentyi libo workspace-operacii; Git-effekt dostupen toljko cherez uzkij kontur nizhe.

Avtonomnaya fikstura prokhodit etot kontur s determinirovannyim recorded-adapterom bez seti i zhivoj modeli. Odin otdeljnyij opt-in progon ispoljzuyet tot zhe runtime i tochnyij lokaljnyij LM Studio adapter k `qwen/qwen3-0.6b`, bez recorded model transport. Zhivoj vyivod sam porozhdayet dva kanonicheskikh namereniya; runtime sveryayet ikh s exact input/output SHA-256 i provider usage do lyubogo dejstviya.

## Izolirovannyij Git-kandidat i priyomka

Yedinstvennoye ispolnimoye dejstviye etogo sreza — `create_candidate_commit`. Yego candidate-policy zakreplyayet sortirovannyiye otnositeljnyiye puti, zaregistrirovannyiye checker ID s odnoznachnyim zakryityim otobrazheniyem v argv-grammatiku i realizaciyu, tochnyiye base, tree i candidate OID, otdeljnuyu candidate-vetku i result ref, avtora, committer, timestamp, soobsjheniye i pyatj producer ID. Nedoverennoye modeljnoye namereniye obyazano sovpastj s kanonicheskim khyeshem plana, no ne mozhet samo sebya podtverditj ili avtorizovatj. Neizvestnyij checker ID ili nesovpadayusjhaya sokhranyonnaya grammatika dayut otkaz do publikacii.

Posle razdeljnyikh podtverzhdeniya, avtorizacii i preflight Git-adapter sozdayot otdeljnyij lokaljnyij clone vne poljzovateljskogo checkout i toljko iz zakreplyonnogo base commit. Do pervoj zapisi on descriptor-relative proveryayet sobstvennyiye obyichnyiye katalogi i vsyo derevo `objects`/`refs`, ownership marker, otsutstviye alternates i kanonicheskuyu lokaljnuyu Git-konfiguraciyu; symlink, hardlink, FIFO, metadata-alias i ispolnyayemaya repo-local-nastrojka zakryivayut dejstviye. Fiksirovannyiye puti sistemnogo Git-runtime izolirovanyi v odnom uzkom pasporte, a ostaljnyiye iskhodniki poluchayut toljko yego tipizirovannyiye znacheniya; publikacionnaya proverka razreshayet sistemnyiye puti rovno v etom fajle i otdeljno zakreplyayet fingerprints otricateljnyikh path-fikstur. Adapter materializuyet tochnyiye obyichnyiye fajlyi, sveryayet tree i diff, povtoryayet zaregistrirovannyiye proverki, sozdayot determinirovannyij commit i publikuyet oba pryamyikh nesymbolic ref cherez compare-and-swap. Pasport kandidata publikuyetsya kak kanonicheskij neizmenyayemyij fajl. Obryiv mezhdu yego hardlink-publikaciyej i udaleniyem vremennogo imeni vosstanavlivayetsya toljko pri rovno odnom sobstvennom same-inode alias s tochnyimi bajtami; chuzhoj ili neodnoznachnyij alias otklonyayetsya. Tochnyij povtor vosstanavlivayet uzhe poluchennyij OID, a inoj OID v lyubom ref zakryivayet prodolzheniye. Iskhodnyiye ref, indeks, worktree i Git-metadannyiye pri etom ne izmenyayutsya.

Ispolneniye i nablyudeniye razdelenyi dolgovechnyim pokoleniyem, a preflight i observation prodolzhayutsya toljko posle sobstvennogo neposredstvennogo `generation_confirmed` s zadannyim command event ID i dajdzhestom exact stage-generation. Posle sokhranyonnoj kvitancii `executed` otdeljnyij observer zanovo chitayet ref, commit, parent, tree, NUL-diff, blobs, checker-nablyudeniya i pasport; toljko etot kontur mozhet sozdatj `observed`. Yesjhyo odin headless-process priyomki poluchayet toljko katalog epizoda i tochnyij candidate OID, descriptor-relative zagruzhayet podtverzhdyonnyiye `CURRENT`, pokoleniye i pasport s `O_NOFOLLOW`, `O_NONBLOCK`, predelom bajtov, `nlink == 1` i stabiljnyim `fstat` do i posle chteniya, dokazyivayet tochnuyu neposredstvennuyu paru `observed → generation_confirmed` s sokhranyonnyim command-specified ID i dajdzhestom predyidusjhego pokoleniya, nezavisimo povtoryayet proverku clone metadata do i posle Git-nablyudeniya i atomarno publikuyet tipizirovannoye `accepted` ili `rejected` cherez no-replace rename bez hardlink-okna. On ne vyipolnyayet merge, rebase, push i ne izmenyayet osnovnuyu vetku.

## Vosproizvedeniye i otkazyi

Reduktor yavlyayetsya chistoj funkciyej sostoyaniya i odnogo sobyitiya. Povtor tochnogo uzhe prinyatogo sobyitiya s toj zhe identity i tem zhe soderzhaniyem idempotenten. Povtor object identity s otlichayusjhimsya soderzhaniyem, poryadkom, ozhidayemyim effektom ili svyazjyu proiskhozhdeniya zakryivayetsya tipizirovannyim konfliktom, a ne perepisyivayet istoriyu.

Prinyataya trassa zavershayetsya rovno odnim `completed`; drugiye dopustimyiye pasportom iskhodyi proveryayutsya avtonomnyimi otricateljnyimi fiksturami. No-call replay snachala sveryayet podtverzhdyonnyiye pasport, `CURRENT`, pokoleniye, zhurnal i acceptance receipt, zatem vyivodit proyekciyu s zakreplyonnyim SHA-256. Dva povtora dayut te zhe kanonicheskiye bajtyi, a khyesh vsego run-directory do i posle podtverzhdayet otsutstviye model-, tool-, Git- i workspace-effektov.

Otricateljnyiye scenarii otdeljno otklonyayut neizvestnuyu versiyu, sobyitiye vne poryadka, podmenu identity, cross-transition-svideteljstvo, nedoverennoye pole dejstviya, vyibor bez sokhranyonnogo model-only-sobyitiya i lozhnoye povyisheniye vneshnego statusa. Otkaz sokhranyayet nablyudayemuyu prichinu, no ne sozdayot nedostayusjhij dopustimyij perekhod.

## Granicyi realizacii

SwiftPM core-target realizuyet toljko tipyi pasporta, sobyitij, sostoyaniya, proveryayemyiye resheniya i chistyij reduktor. On ne chitayet i ne pishet fajlyi, ne vyizyivayet modeljnogo provajdera, ne ispolnyayet Git, ne obrasjhayetsya k workspace, seti, shell ili poljzovateljskomu interfejsu. Avtonomnaya fikstura po-prezhnemu proveryayet redukciyu bez effektov. Otdeljnyij target `FUMLiveEpisodeRuntime` zavisit toljko ot tochnyikh lokaljnyikh produktov chistogo modeljnogo shaga i vosproizvodimoj pamyati, vladeyet fajlovoj i provider-granicami i ne perenosit ikh v core.

Stend ogranichen odnim lokaljnyim katalogom epizoda, lokaljnyim sinteticheskim Git-istochnikom, dvumya exact model-only-vkhodami i nedostupnyim po umolchaniyu zhivyim provider-adapterom. On dokazyivayet zhivoj model-to-action-putj s vneshnim svideteljstvom i otdeljnoj priyomkoj toljko dlya etogo zakryitogo scenariya. Kandidat ostayotsya v izolirovannoj vetke, ne integriruyetsya, ne publikuyetsya i ne izmenyayet iskhodnyij checkout. Eto zavershayet [FUM-STEP-0112](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md), no ne obyyavlyayet obsjhij runtime, power-loss durability, raspredelyonnyij FUM, produkt ili sravniteljnoye preimusjhestvo.

## Istochniki

- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [otchyot o zhivom progone odnoagentnogo epizoda](../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [FUM-STEP-0112 — zamknutyiye vozobnovleniye i zhivaya priyomka odnoagentnogo epizoda](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [iskhodnyij zapros 2026-08-01 14:29:41 MSK — Realizovatj izolirovannyij kandidatnyij kommit i otdeljnuyu priyomku](../Zhurnal/2026-08-01_14-29-41_MSK_realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku/zapros.md)
- [FUM-STEP-0111 — izolirovannyij kandidatnyij kommit i otdeljnaya priyomka](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0111-realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku.md)
- [iskhodnyij zapros 2026-08-01 11:56:54 MSK — Realizovatj podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](../Zhurnal/2026-08-01_11-56-54_MSK_realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda/zapros.md)
- [FUM-STEP-0110 — podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0110-realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda.md)
- [iskhodnyij zapros 2026-07-31 21:37:26 MSK — Vvesti skhemu sobyitij zhivogo odnoagentnogo epizoda](../Zhurnal/2026-07-31_21-37-26_MSK_vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda/zapros.md)
- [FUM-STEP-0109 — skhema sobyitij zhivogo odnoagentnogo epizoda](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0109-vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii pri ozhidanii podtverzhdeniya](../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [kontrakt chistogo modeljnogo shaga](41-kontrakt-chistogo-modeljnogo-shaga.md)
- [minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)
- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](../Planirovaniye/kartochki-shagov/🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)
- [prototip zhivogo odnoagentnogo epizoda](../Prototipyi/zhivoj-odnoagentnyij-epizod/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f8aee659ed62891191b811a7c8628ab5dc880a625421d153cc3cbd0d813ab2e8 -->
<!-- FUM-MD-RECENCY:END -->
