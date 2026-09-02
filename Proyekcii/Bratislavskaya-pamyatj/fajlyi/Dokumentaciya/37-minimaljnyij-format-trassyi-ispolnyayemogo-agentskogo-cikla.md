# Minimaljnyij format trassyi ispolnyayemogo agentskogo cikla

Minimaljnaya trassa [agentskogo cikla](../Glossarij/agentskij-cikl.md) FUM — eto dopisyivayemaya posledovateljnostj sobyitij JSON Lines. Stabiljnaya versiya `1` sokhranyayet nablyudayemyij khod odnoj diskretnoj zadachi, versiya `2` yavno predstavlyayet razreshyonnyij poljzovateljskij vvod vo vremya rabotyi i perenapravleniye yesjhyo ne zavershyonnogo plana, a versiya `3` razdelyayet modeljnoye vetvleniye, ozhidayusjhij podtverzhdeniya perekhod i vneshneye ispolneniye. Kazhdaya versiya fiksiruyet proveryayemyiye faktyi rabotyi, no ne skryityiye rassuzhdeniya modeli; novaya versiya ne menyayet semantiku raneye opublikovannyikh skhem i fikstur.

## Naznacheniye

Format nuzhen kak perenosimaya granica mezhdu budusjhim ispolnitelem cikla i [pamyatjyu FUM](../Glossarij/pamyatj-FUM.md). Ispolnitelj mozhet dopisyivatj sobyitiye srazu posle yego vozniknoveniya, chitatelj — vosstanovitj poryadok, a proverka — svyazatj rezuljtat s dejstviyem i nablyudayemyim dokazateljstvom.

Odna trassa opisyivayet odnu ogranichennuyu zadachu. Povtornyij shag togo zhe cikla prodolzhayet tot zhe `trace_id`; novaya samostoyateljnaya zadacha poluchayet drugoj identifikator. Neskoljko dejstvij, oshibok ili proverok ne vkladyivayutsya v odin boljshoj obyyekt, a zapisyivayutsya otdeljnyimi sobyitiyami.

## Nositelj i konvert sobyitiya

Trassa khranitsya v UTF-8-fajle `.jsonl`: odna stroka soderzhit rovno odin zavershyonnyij JSON-obyyekt, poryadok strok sovpadayet s poryadkom sobyitij, fajl okanchivayetsya perevodom stroki. Nezavershyonnaya poslednyaya zapisj ne schitayetsya sobyitiyem; uzhe zavershyonnyij prefiks ostayotsya prigodnyim dlya razbora posle ostanovki processa.

Kazhdoye sobyitiye soderzhit toljko pyatj verkhneurovnevyikh polej:

- `schema_version` — celoye chislo `1`;
- `trace_id` — ustojchivyij tekhnicheskij identifikator odnogo progona;
- `seq` — nomer sobyitiya, nachinaya s `1` bez propuskov i povtorov;
- `kind` — odin iz semi tipov `task`, `observation`, `action`, `check`, `result`, `error` ili `continuation`;
- `payload` — obyyekt tochnogo tipa, zadannogo znacheniyem `kind`.

Tochnaya mashinnaya forma odnoj stroki zakreplena v [JSON Schema sobyitiya versii 1](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v1.json). Neizvestnyiye polya zapresjhenyi: rasshireniye kontrakta trebuyet novoj versii skhemyi, a ne molchalivogo izmeneniya smyisla versii `1`.

## Semj tipov sobyitij

### `task` — zadacha

Pervoye sobyitiye trassyi zadayot proveryayemuyu rabotu. `summary` soderzhit kratkuyu formulirovku, `acceptance` — nepustoj spisok nablyudayemyikh kriteriyev zaversheniya, `source_refs` — ssyilki na proiskhozhdeniye zadachi. `allowed_actions` perechislyayet dopustimyiye sochetaniya operacii, adaptera i effekta, a `model_step` yavno zadayot otsutstviye modeljnogo shaga, proveryayemuyu zaglushku libo ssyilku na otdeljnyij kontrakt provajdera. Kriterii opisyivayut zhelayemyij vneshnij rezuljtat i ne sluzhat mestom dlya skryitogo plana rassuzhdenij.

Dlya rezhima `stub` ili `provider` pole `provider_ref` mozhet ssyilatjsya na [kontrakt chistogo modeljnogo shaga](41-kontrakt-chistogo-modeljnogo-shaga.md) libo na sovmestimyij pasport konkretnogo provajdera. Versiya trassyi `1` ne soderzhit otdeljnogo sobyitiya modeljnogo vyizova: polnyij konvert zaprosa i rezuljtata sokhranyayetsya otdeljno i ne vyidayotsya za vyipolnennoye dejstviye.

### `observation` — nablyudeniye

Sobyitiye soderzhit publikacionno chistoye `summary` nablyudayemogo sostoyaniya i nepustoj spisok `evidence_refs`. Nablyudeniyem schitayetsya dostupnyij agentu vkhod, rezuljtat chteniya, sostoyaniye sredyi, otzyiv cheloveka ili drugoj vneshnij fakt. Polnyij sistemnyij prompt, skryitaya cepochka rassuzhdenij, sekretyi i neobrabotannyiye privatnyiye dannyiye nablyudeniyem dlya etoj trassyi ne yavlyayutsya.

### `action` — dejstviye

Sobyitiye zapisyivayetsya do popyitki ispolneniya i soderzhit `operation`, `adapter`, `effect`, kratkoye `summary`, nepustyiye `target_refs` i `authorization`. Trojka `operation + adapter + effect` dolzhna tochno prisutstvovatj v `task.allowed_actions`. Sobyitiye dokazyivayet, kakoye dejstviye byilo zaprosheno u kakogo adaptera i na kakom osnovanii razresheno, no samo po sebe ne dokazyivayet uspekh. Fakticheskij iskhod poyavlyayetsya otdeljnyim `result` ili `error`.

### `result` — rezuljtat

Sobyitiye ssyilayetsya na predyidusjheye dejstviye cherez `action_seq`, zadayot `status` iz `success`, `partial` ili `failed`, kratkoye `summary` i spisok `artifact_refs`. Otsutstvuyusjhij artefakt oboznachayetsya pustyim spiskom, a ne vyimyishlennoj ssyilkoj.

### `error` — oshibka

Oshibka ne teryayetsya v terminaljnom vyivode i ne podmenyayetsya obsjhim neuspekhom. Ona ssyilayetsya na `action_seq` i soderzhit ustojchivyij `code`, bezopasnoye `summary`, `source`, priznak `retryable` i ssyilki na ochisjhennyiye dokazateljstva. Syiroj vyivod, sposobnyij raskryitj token, lokaljnyij absolyutnyij putj ili privatnoye soderzhimoye, v sobyitiye ne perenositsya.

### `check` — proverka

Proverka ssyilayetsya cherez `subject_seq` na uzhe zapisannyij `result` ili `error`, imeyet `status` `passed` libo `failed`, kratkoye `summary` i nepustyiye `evidence_refs`. Ona fiksiruyet vneshnij kriterij — test, sopostavleniye, revjyu ili podtverzhdeniye sredyi, — a ne samoocenku modeli bez nablyudayemogo osnovaniya.

### `continuation` — status prodolzheniya

Sobyitiye soderzhit nepustoj spisok `basis_seqs`, kratkuyu nablyudayemuyu prichinu `reason` i odin status:

- `continue` — cikl mozhet zapisyivatj sleduyusjhiye sobyitiya;
- `completed` — kriterii zadachi vyipolnenyi;
- `blocked` — prodolzheniye nevozmozhno do izmeneniya vneshnego usloviya;
- `awaiting_confirmation` — trebuyetsya yavnoye podtverzhdeniye;
- `handed_off` — otvetstvennostj peredana drugomu uzlu ili ciklu;
- `stopped` — cikl ostanovlen politikoj, limitom ili otmenoj bez utverzhdeniya o vyipolnenii.
- `failed` — zadacha zavershilasj nevosstanovimoj oshibkoj ili provalennoj proverkoj.

`reason` obyyasnyayet primenyonnoye pravilo ili vneshnij fakt dostatochno dlya proverki resheniya, no ne raskryivayet skryityiye promezhutochnyiye rassuzhdeniya.

## Invariantyi posledovateljnosti

Validnaya trassa versii `1` soblyudayet sleduyusjhiye pravila:

1. Vo vsekh strokakh sovpadayut `schema_version` i `trace_id`, a `seq` obrazuyet ryad `1...N`.
2. Pervoye sobyitiye imeyet tip `task`; kazhdoye dejstviye opirayetsya na uzhe zapisannuyu zadachu i aktualjnoye nablyudeniye, a yego operaciya, adapter i effekt razreshenyi `task.allowed_actions`.
3. Posle `action` zapisyivayetsya `result` ili `error`, ssyilayusjhijsya na susjhestvuyusjhij boleye rannij `action_seq`. Yesli process ostanovilsya srazu posle `action`, iskhod ostayotsya neizvestnyim i ne vosstanavlivayetsya dogadkoj.
4. `check.subject_seq` ukazyivayet na boleye rannij `result` ili `error`; proverka ne predshestvuyet svoyemu predmetu.
5. `continuation.basis_seqs` ssyilayetsya toljko na boleye ranniye sobyitiya. Status `continue` razreshayet prodolzheniye; `completed`, `blocked`, `awaiting_confirmation`, `handed_off`, `stopped` i `failed` yavlyayutsya terminaljnyimi i dopuskayutsya toljko v poslednej stroke.
6. Oshibka i status prodolzheniya nezavisimyi: vosstanovimaya oshibka mozhet vesti k `continue`, a uspeshnoye dejstviye — k `awaiting_confirmation` ili `stopped` po vneshnej politike.
7. Ssyilki ispoljzuyut puti otnositeljno kornya pamyati libo ustojchivyiye publikacionnyiye identifikatoryi. Lokaljnyiye absolyutnyiye puti, sekretyi, tokenyi i privatnyiye URL zapresjhenyi.
8. Trassa ne soderzhit skryitogo rassuzhdeniya modeli. Nablyudayemoye osnovaniye vyibora ostayotsya v `summary`, `authorization`, proverke i `continuation.reason`; vnutrenniye tokenyi i chernovoj khod myisli ne serializuyutsya.

## Lokaljnaya fikstura

[Fikstura korotkoj lokaljnoj zadachi](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-korotkoj-lokaljnoj-zadachi.jsonl) proveryayet vse semj tipov sobyitij bez seti, sekretov i vneshnikh effektov. Ona namerenno fiksiruyet neuspeshnoye chteniye otsutstvuyusjhego testovogo puti, sokhranyayet strukturirovannuyu oshibku, vyibirayet `continue`, chitayet kanonicheskuyu statjyu [«Agentskij cikl»](../Glossarij/agentskij-cikl.md), proveryayet yeyo zagolovok i zavershayet zadachu so statusom `completed`.

Proverka fiksturyi podtverzhdayet sintaksis kazhdoj JSONL-stroki, sovpadeniye so skhemoj obyazateljnyikh polej, nepreryivnostj `seq`, nalichiye semi tipov, korrektnostj ssyilok mezhdu sobyitiyami, terminaljnostj poslednego statusa, otsutstviye polej skryitogo rassuzhdeniya i sootvetstviye zayavlennogo rezuljtata tekusjhemu lokaljnomu fajlu. Dva posledovateljnyikh razbora dayut odinakovyij strukturnyij rezuljtat; eto proveryayet determinirovannostj fiksturyi, no ne obesjhayet determinizm budusjhej modeli.

## Versiya 2: poljzovateljskoye perenapravleniye

[Skhema sobyitiya versii 2](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v2.json) sokhranyayet tot zhe pyatichastnyij konvert i vse semj tipov versii `1`, no trebuyet `schema_version = 2` i dobavlyayet tipyi `plan`, `input_event`, `input_signal`, `checkpoint` i `redirect`. Smyisl versii `1` i yeyo fikstura ne menyayutsya zadnim chislom.

Tri formyi vkhoda ne vzaimozamenyayemyi:

- `task` — yedinstvennoye pervoye diskretnoye soobsjheniye-zadacha. Polya `message_id` i `input_form = task_message` zakreplyayut yego proiskhozhdeniye; eto ne element potoka poljzovateljskogo interfejsa.
- `input_event` — pervichnoye razreshyonnoye sobyitiye nablyudayemogo vkhodnogo potoka. Ono sokhranyayet sobstvennyij `event_id`, identifikator i poziciyu potoka, vremena vozniknoveniya i nablyudeniya, kanal, tip, ochisjhennoye soderzhaniye, resheniye o dopustimosti i ssyilki na istochnik.
- `input_signal` — neobyazateljnoye proizvodnoye agregirovannoye predstavleniye odnogo ili neskoljkikh pervichnyikh sobyitij. Ono obyazano perechislyatj iskhodnyiye `input_event` cherez `source_event_seqs`, sokhranyatj ikh poryadok i soobsjhatj nablyudayemyiye parametryi agregacii: okhvachennyij diapazon, chislo otbroshennyikh i povtornyikh sobyitij, zaderzhku i sostoyaniye obratnogo davleniya. Signal ne stirayet i ne podmenyayet pervichnyiye sobyitiya.

`plan` delayet namereniye cikla nablyudayemyim bez raskryitiya chernovogo khoda myisli: ustojchivyij `plan_id`, monotonnaya `revision`, celj, prioritet, vetka, sleduyusjheye razreshyonnoye dejstviye i ssyilki na osnovaniya. Do dejstviya cikl mozhet zapisatj `checkpoint`, svyazannyij s tekusjhim planom. Kontroljnaya tochka perechislyayet toljko bezopasno izmenyayemyiye izmereniya `goal`, `priority`, `branch` i `action`, a takzhe uzhe nachatyiye dejstviya; otsutstviye dejstviya v polyote yavlyayetsya proveryayemyim usloviyem yego zamenyi.

`redirect` svyazyivayet resheniye `keep` ili `change` s boleye rannimi vvodom, kontroljnoj tochkoj, planom i prodolzheniyem. Pri `change` sobyitiye perechislyayet izmenyonnyiye izmereniya i sudjbu kazhdogo vyitesnennogo zaplanirovannogo dejstviya. Novaya reviziya `plan` ssyilayetsya na `supersedes_plan_seq` i `redirect_seq`, a novoye sobyitiye `continuation` — na novuyu reviziyu i `supersedes_continuation_seq`. Fakticheskoye `action` takzhe svyazano s konkretnyim planom i `planned_action_id`; poetomu prezhneye i novoye prodolzheniya ostayutsya razlichimyimi, a proiskhozhdeniye perekhoda vosstanavlivayetsya toljko po obratnyim ssyilkam na uzhe zapisannyiye sobyitiya.

### Invariantyi perenapravleniya

V dopolneniye k obsjhim pravilam posledovateljnosti versiya `2` trebuyet sleduyusjhego:

1. Pervichnyiye sobyitiya odnogo `stream_id` imeyut strogo vozrastayusjhiye `stream_seq`; sobyitiye ne nablyudayetsya ranjshe vozniknoveniya, a agregat ne ispuskayetsya ranjshe nablyudeniya vsekh svoikh istochnikov.
2. Razreshyonnyij vvod zapisyivayetsya do kontroljnoj tochki i resheniya. Agregirovannoye predstavleniye sokhranyayet vse okhvachennyiye pervichnyiye sobyitiya v iskhodnom poryadke; resheniye ssyilayetsya libo na agregat, libo na neagregirovannyiye pervichnyiye sobyitiya, no ne schitayet odno proiskhozhdeniye dvazhdyi.
3. `redirect.changed_dimensions` yavlyayetsya podmnozhestvom `checkpoint.safe_changes` i v tochnosti sovpadayet s fakticheskimi otlichiyami starogo i novogo planov. Dejstviye v polyote neljzya obyyavitj zamenyonnyim do starta.
4. Novaya reviziya sokhranyayet `plan_id`, uvelichivayet `revision` rovno na yedinicu i ssyilayetsya na prezhnij plan i resheniye. Novoye prodolzheniye vyitesnyayet prezhneye yavno; ni svobodnyij tekst, ni agregirovannyij signal sami po sebe ne menyayut plan.
5. Ispolnyayetsya toljko dejstviye aktualjnogo plana, sovpadayusjheye s `task.allowed_actions`. Proverennyij terminaljnyij status ostayotsya poslednim sobyitiyem trassyi.

### Determinirovannaya fikstura i avtonomnaya proverka

[Fikstura perenapravleniya poljzovateljskim vvodom](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-perenapravleniya-poljzovateljskim-vvodom-v2.jsonl) soderzhit chetyirnadcatj sobyitij v fiksirovannom poryadke: diskretnuyu zadachu, iskhodnyij plan i prodolzheniye, dva pervichnyikh sobyitiya vvoda, ikh agregat, bezopasnuyu kontroljnuyu tochku, resheniye o perenapravlenii, novuyu reviziyu plana i prodolzheniya, lokaljnoye chteniye, rezuljtat, proverku i zaversheniye. Vvod menyayet celj, vetku i yesjhyo ne nachatoye dejstviye, no ne prioritet; skhema dopuskayet izmeneniye lyubogo nepustogo podmnozhestva chetyiryokh izmerenij, obyyavlennogo bezopasnyim v konkretnoj kontroljnoj tochke.

Fikstura vyipolnyayet toljko chteniye statji [«Nablyudayemyij vkhodnoj signal»](../Glossarij/nablyudayemyij-vkhodnoj-signal.md) cherez uslovnyij read-only-adapter i sopostavlyayet yeyo fakticheskij zagolovok. Modeljnyij shag zadan kak `none`. Standartnyij modulj `unittest` proveryayet skhemu, poryadok, vse ssyilki osnovanij, avtorizaciyu, tochnoye sootvetstviye plana celi dejstviya, lokaljnyij fajl, uspeshnyiye rezuljtat i proverku, sostav osnovaniya zaversheniya i otsutstviye specialjnyikh polej skryitogo rassuzhdeniya. Otricateljnyiye sluchai otklonyayut poteryu pervichnogo proiskhozhdeniya, budusjhuyu ssyilku, chuzhuyu sudjbu vyitesnennogo dejstviya, izmeneniye vne bezopasnoj tochki, nezayavlennoye ili nepodderzhivayemoye izmereniye, pustoye izmeneniye, podmenu celi dejstviya, provalennyij rezuljtat ili proverku, nepodtverzhdyonnoye zaversheniye, specialjnoye pole skryityikh rassuzhdenij, modeljnogo provajdera ili setevuyu ssyilku i zapresjhyonnoye pervichnoye sobyitiye:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-kompleksnaya-proverka-repozitoriya/tests -p 'test_perenapravleniye_agentskogo_cikla.py'
```

Proverka specialjnyikh imyon polej yavlyayetsya strukturnyim ogranichitelem, a ne klassifikatorom smyisla proizvoljnogo teksta. Publikacionnaya proverka otdeljno otvechayet za to, chtobyi `summary` i `reason` soderzhali toljko kratkoye nablyudayemoye osnovaniye, a ne skryityij sistemnyij prompt ili chernovoj khod myisli.

## Versiya 3: neblokiruyusjheye modeljnoye vetvleniye

[Skhema sobyitiya versii 3](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v3.json) vvodit novuyu semjyu tipov s `schema_version = 3`, a ne rasshiryayet tikho znacheniya polej versij `1` i `2`. Ikh fajlyi ostayutsya pobajtovo neizmennyimi, a `awaiting_confirmation` ostayotsya terminaljnyim statusom imenno v staryikh kontraktakh. Versiya `3` ispoljzuyet tot zhe pyatichastnyij konvert, no yeyo `kind` ogranichen tipami `task`, `episode_state`, `pending_transition`, `model_checkpoint`, `model_branch`, `model_step`, `branch_check`, `branch_selection`, `episode_checkpoint`, `transition_response`, `transition_stage`, `transition_action` i `external_evidence`.

Sostoyaniye odnogo epizoda razlozheno na chetyire nezavisimyiye osi:

- `episode_state` opisyivayet, mozhet li epizod prodolzhatj bezopasnuyu rabotu, i khranit yego ostatok byudzheta;
- `model_checkpoint`, `model_branch`, `model_step`, `branch_check` i `branch_selection` svyazyivayut kazhduyu modeljnuyu vetvj s obsjhim tochnyim predkom, soderzhateljnyim otlichiyem, konechnyim byudzhetom, chistyim `model_only`-shagom, otdeljnoj proverkoj i nablyudayemyim proiskhozhdeniyem rezuljtata;
- `pending_transition`, `transition_response` i `transition_stage` khranyat tochnyij obyyekt, tochnuyu versiyu i ozhidayemyij effekt zakryitogo perekhoda, a takzhe razlichayut pozdnij tochnyij otvet, ustarevsheye podtverzhdeniye, otkaz i otzyiv;
- `transition_action` i `external_evidence` vvodyat otdeljnuyu osj vneshnego ispolneniya, kotoraya ne sleduyet ni iz ozhidaniya, ni iz modeljnogo vyibora.

### Nezavisimyiye svideteljstva i khraneniye kandidatov

Vnutrennij otbor `selected_in_model` ili `recommended` sokhranyayet variant toljko kak `candidate_only`. On ne menyayet kanonicheskoye sostoyaniye, ne prinimayet politiku polnomochij i ne sozdayot `transition_user_confirmed`. Polucheniye tochnogo razreshyonnogo otveta v bezopasnoj kontroljnoj tochke mozhet vyibratj raneye sokhranyonnuyu aljternativu, no dazhe `selected_by_user` ostayotsya kandidatnyim sostoyaniyem do prokhozhdeniya ostaljnyikh granic. Razreshyonnostj takogo otveta zadayotsya ne odnim `actor = user`: yego `source_event.ingress_authorization` obyazan nezavisimo khranitj tochnuyu trojku `status = allowed`, `purpose = transition_response` i nepustoj `policy_ref` politiki priyoma.

Pyatj rubezhej `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed` i `observed` trebuyut nezavisimyikh svideteljstv. Pervyij opirayetsya na boleye rannij razreshyonnyij `transition_response` dlya tochnyikh tekusjhikh obyyekta, versii i ozhidayemogo effekta. Kazhdyij sleduyusjhij rubezh opirayetsya na sobstvennuyu boleye rannyuyu zapisj `external_evidence` s temi zhe koordinatami perekhoda, effektom, yavnyim `source_ref` i proiskhozhdeniyem: `authorized` — na `authority_decision / allowed`, `preflight_passed` — na `current_state_preflight / passed`, `executed` — na `execution_receipt / succeeded`, `observed` — na `result_observation / observed`. Odnoj rolevoj stroki `evidence_source` nedostatochno, a svideteljstva ne vyivodyatsya drug iz druga, iz podtverzhdeniya ili modeljnogo vyibora. `executed` i `observed` predstavlenyi toljko otdeljnyimi `transition_action` i trebuyut vsej nepreryivnoj predshestvuyusjhej cepochki.

Otvet `stale` ne sozdayot podtverzhdeniya ili poljzovateljskogo vyibora. `refuse` zakryivayet osnovannuyu na etom otvete cepochku podtverzhdeniya i vneshnikh rubezhej. `revoke` dopustim toljko posle susjhestvovavshego raneye tochnogo aktualjnogo podtverzhdeniya i annuliruyet yego i zavisimyiye ot nego posleduyusjhiye rubezhi; nikakoye boleye pozdneye ispolneniye ne mozhet opiratjsya na otozvannuyu cepochku.

Nachaljnoye `task` zadayot politiku khraneniya nezavisimo ot vyibora vetvi: ustojchivyiye identifikator i versiyu, razreshyonnyiye klassyi zapisej trassyi, kandidata i kontroljnoj tochki, a takzhe ssyilku na politiku prinyatiya. Kazhdaya sokhranyayemaya zapisj ssyilayetsya na etu politiku i svoj klass; otsutstviye politiki ili nerazreshyonnyij klass zakryivayut validaciyu. Politika ne oznachayet, chto kandidat prinyat ili razreshyon k ispolneniyu.

### Terminaljnostj i limityi

Terminaljnaya zapisj ostayotsya poslednej: posle neyo neljzya dopisatj dazhe strukturno korrektnoye sobyitiye. Itogovoye potrebleniye byudzheta epizoda ravno summe potrebleniya vetvej, a `episode_checkpoint` i konechnyij `episode_state` obyazanyi tochno sovpastj po tryom schyotchikam: ostatku byudzheta, chislu bezopasnyikh produktivnyikh prodolzhenij i chislu ostavshikhsya razlichayusjhikh proverok. `unresolved_conflict` nedopustim, poka yestj khotya byi odna razlichayusjhaya proverka, kotoraya vmesjhayetsya v ostatok byudzheta. `needs_input` dopustim toljko posle ischerpaniya vsekh bezopasnyikh produktivnyikh prodolzhenij ili ikh ostatka byudzheta. Yesli byudzheta khvatilo toljko na odnu vetvj, vyibor sokhranyayet neproverennyiye aljternativyi i `ambiguity_resolved = false`, a ne vyidayot odnu popyitku za razresheniye neodnoznachnosti.

### Lokaljnyiye fiksturyi i proverka

Tri kanonicheski zapisannyiye fiksturyi pokryivayut raznyiye granicyi odnogo kontrakta:

- `nonblocking_branching_v3` — [neblokiruyusjheye modeljnoye vetvleniye](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-neblokiruyusjhego-modeljnogo-vetvleniya-v3.jsonl) ostavlyayet vneshnij perekhod zakryityim, ne zapisyivayet vneshnego dejstviya, razvorachivayet ot obsjhego predka rovno dve soderzhateljno razlichnyiye vetvi, proveryayet ikh otdeljno i sokhranyayet modeljnuyu rekomendaciyu;
- `late_confirmation_v3` — [pozdneye podtverzhdeniye perekhoda](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-pozdnego-podtverzhdeniya-perekhoda-v3.jsonl) prinimayet razreshyonnyij tochnyij signal na sokhranyonnoj bezopasnoj kontroljnoj tochke i vyibirayet sokhranyonnuyu aljternativu, ne izobretaya zadnim chislom polnomochiye ili fakt ispolneniya;
- `single_branch_limited_budget_v3` — [odna vetvj pri ogranichennom byudzhete](37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-odnoj-vetvi-pri-ogranichennom-byudzhete-v3.jsonl) sokhranyayet rovno odnu proverennuyu vetvj, nepustoj spisok neproverennyikh aljternativ i `ambiguity_resolved = false`, a pri nulevom ostatke byudzheta perekhodit v `needs_input` toljko posle ischerpaniya bezopasnoj produktivnoj rabotyi.

[Avtonomnyij validator](../Instrumentyi/fum-proverka-trassyi-agentskogo-cikla/SKILL.md) proveryayet tri kanonicheskiye fiksturyi po tochnyim profilyam `nonblocking_branching_v3`, `late_confirmation_v3` i `single_branch_limited_budget_v3`. Otdeljnyiye profili `stale_confirmation_v3`, `refusal_v3` i `revocation_v3` zakreplyayut razlichimyiye mutacionnyiye sluchai bez dobavleniya lozhnyikh kanonicheskikh trass. Validator chitayet JSONL i skhemu lokaljno i proveryayet mezhsobyitijnyiye invariantyi. Yemu ne nuzhnyi setj, sekretyi, zhivaya LLM, vneshniye servisyi, publikaciya ili fizicheskoye dejstviye. Eto determinirovannyij kontraktnyij stend, a ne skvoznoj runtime FUM: on ne dokazyivayet rabotu zhivoj modeli, kanala podtverzhdenij, avtorizatora, preflight, adaptera ispolneniya ili nablyudeniya effekta i ne sozdayot faktov rabotayusjhego runtime.

## Granica primenimosti

Tri versii zadayut format nablyudayemogo sleda, a ne ispolnyayemyij runtime. Oni ne vyibirayut modelj, ne podklyuchayut realjnyij potok poljzovateljskogo interfejsa, ne obespechivayut dostavku, khraneniye ili primeneniye vvoda, ne ispolnyayut dejstviye, ne vyidayut zapisj za dokazateljstvo fakticheskogo effekta bez proverki i ne rasshiryayut razresheniya agenta. Versiya `2` predstavlyayet uzhe ochisjhennyiye sinteticheskiye sobyitiya i resheniye na bezopasnoj granice; chisla zaderzhki i obratnogo davleniya v fiksture proveryayut proiskhozhdeniye zapisi, no ne izmeryayut rabotayusjhij kanal i ne dokazyivayut yego propusknuyu sposobnostj. Versiya `3` predstavlyayet lokaljnyiye proveryayemyiye sobyitiya vetvleniya i perekhoda, no yeyo byudzhetyi i proverki ne izmeryayut zhivuyu LLM ili vneshnij adapter. Planirovsjhik, vlozhennyiye ciklyi, stoimostj, potok tokenov, kriptograficheskoye proiskhozhdeniye, kanonizaciya JSON, vosstanovleniye posle sboya i dolgovremennoye khraneniye ostayutsya sleduyusjhimi sloyami.

Versiya `1` mozhet zapisatj uzhe dostupnyij otzyiv cheloveka kak `observation`, no ne zadayot protokol vvoda vo vremya ispolneniya. Versiya `2` ustranyayet imenno etu neodnoznachnostj formata vnutri odnogo `trace_id`: novoye soobsjheniye ne podmenyayet iskhodnyij `task`, pervichnoye sobyitiye ne smeshivayetsya s agregatom, a izmeneniye prodolzheniya trebuyet otdeljnoj kontroljnoj tochki i resheniya. Eto ne dokazyivayet nepreryivnostj mezhdu raznyimi `trace_id` i ne oznachayet, chto tekusjhij Git + Codex-kontur uzhe stal asinkhronnyim sobyitijnyim runtime.

Terminaljnyij status `awaiting_confirmation` versij `1` i `2` ne umeyet nezavisimo predstavitj priparkovannyij vneshnij effekt i prodolzhayusjhijsya modeljnyij epizod: pravilo terminaljnosti zapresjhayet posleduyusjhiye sobyitiya togo zhe `trace_id`. Versiya `3` ustranyayet etu neodnoznachnostj v formate, no ne dokazyivayet samu nepreryivnostj zhivogo cikla. [Zavershyonnaya kartochka FUM-STEP-0072](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0072-opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom.md) zakreplyayet vkhodyasjhuyu storonu, a [kartochka FUM-STEP-0106](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md) zakreplyayet iskhodyasjhuyu granicu vetvleniya i ozhidaniya.

Fikstura proveryayet toljko lokaljnoye chteniye i sopostavleniye teksta. Format ne razreshayet vneshniye servisnyiye operacii, rabotu s privatnyimi dannyimi, fizicheskoye dejstviye ili samostoyateljnuyu dolgovremennuyu avtonomiyu. Dlya nikh nuzhnyi otdeljnyiye adapteryi, ogranichiteli, podtverzhdeniya i proverki.

[Minimaljnyij pasport peredavayemogo rezuljtata FUM](39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md) mozhet ssyilatjsya na sobyitiya `result` i `check` kak na svideteljstva artefakta i proverki, ne kopiruya vsyu trassu. Terminaljnoye sobyitiye `continuation` so statusom `handed_off` podtverzhdayet resheniye otpravitelya peredatj otvetstvennostj, no samo po sebe ne dokazyivayet dostavku ili podtverzhdeniye polucheniya adresatom.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-29 14:32:38 MSK — Zakrepitj neblokiruyusjheye modeljnoye vetvleniye](../Zhurnal/2026-07-29_14-32-38_MSK_zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye/zapros.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii pri ozhidanii podtverzhdeniya](../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [iskhodnyij zapros 2026-07-29 13:22:54 MSK — Opisatj perenapravleniye agentskogo cikla poljzovateljskim vvodom](../Zhurnal/2026-07-29_13-22-54_MSK_opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom/zapros.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-23 18:12:05 MSK - Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla](../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-23 12:53:46 MSK - Opisatj minimaljnyij pasport peredavayemogo rezuljtata FUM](../Zhurnal/2026-07-23_12-53-46_MSK_opisatj-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:07:48 MSK — Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../Zhurnal/2026-07-22_13-07-48_MSK_sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [napravleniye «Agentskij cikl i ispolnyayemyij kontur»](../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md)
- [MVP-kandidat ispolnyayemogo agentskogo cikla](../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [obzor aktualjnyikh realizacij agentskikh ciklov](06-obzor-agentskikh-ciklov.md)
- [kartochka FUM-STEP-0023](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0023-sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:aeafcaa50f7ef3332718958fdb2cb7751eb0f657ba977a78e0df5865a21c3042 -->
<!-- FUM-MD-RECENCY:END -->
