# LLM-oriyentirovannyij [yazyik avtomatizacij FUM](../Glossarij/yazyik-avtomatizacij-FUM.md)

## Trebovaniye

[FUM](../Glossarij/FUM.md) nuzhen [yazyik avtomatizacij FUM](../Glossarij/yazyik-avtomatizacij-FUM.md): yazyik programmirovaniya ustojchivyikh [avtomatizacij FUM](../Glossarij/avtomatizaciya-FUM.md), optimizirovannyij dlya rabotyi s nim so storonyi LLM.

Takoj yazyik dolzhen byitj udoben ne toljko dlya ispolneniya mashinoj i chteniya chelovekom, no i dlya aktivnoj rabotyi modeli: ponimatj susjhestvuyusjhuyu avtomatizaciyu, generirovatj novuyu, vnositj maluyu pravku, obyyasnyatj posledstviya izmeneniya, stroitj test, sopostavlyatj trassu s iskhodnyim tekstom i perenositj avtomatizaciyu v drugoj kontur [pamyati FUM](../Glossarij/pamyatj-FUM.md).

## Naznacheniye

Obyichnyiye yazyiki programmirovaniya khorosho vyirazhayut vyichisleniye, no ne vsegda khorosho vyirazhayut proiskhozhdeniye, granicyi dostupa, effektyi, proverki, namereniye i trassu rabotyi agenta. Dlya [FUM](../Glossarij/FUM.md) eti svojstva yavlyayutsya chastjyu samoj avtomatizacii, a ne vneshnimi kommentariyami.

[Yazyik avtomatizacij FUM](../Glossarij/yazyik-avtomatizacij-FUM.md) dolzhen statj sloyem, gde avtomatizaciya opisyivayetsya kak proveryayemaya [narabotka](../Glossarij/narabotka.md): chto ona prinimayet, chto obesjhayet vernutj, kakiye sostoyaniya chitayet, kakiye dejstviya mozhet vyipolnitj, gde trebuyet podtverzhdeniya, kakiye testyi fiksiruyut povedeniye i kak rezuljtat sokhranyayetsya v pamyati.

Etot sloj ne obyazan srazu zamenyatj Python, TypeScript, shell, Markdown-instrukcii ili vneshniye workflow-dvizhki. Na rannem etape on mozhet byitj deklarativnyim profilem, DSL ili promezhutochnyim predstavleniyem, kotoroye vyizyivayet susjhestvuyusjhiye realizacii. Vazhneye drugoye: istochnik smyisla avtomatizacii dolzhen stanovitjsya kompaktnyim, proveryayemyim i prigodnyim dlya nadyozhnoj LLM-pravki.

## Svyazj s sistemoj strukturiruyusjhikh operatorov

[Yazyik avtomatizacij FUM](../Glossarij/yazyik-avtomatizacij-FUM.md) dolzhen razvivatjsya ne kak otdeljnyij DSL ryadom s operatornoj pamyatjyu, a kak ispolnyayemaya proyekciya [sistemyi strukturiruyusjhikh operatorov FUM](../Glossarij/sistema-strukturiruyusjhikh-operatorov-FUM.md). Yesli operatornaya sistema khranit obsjhij graf form, kotoryiye mozhno raspoznavatj, porozhdatj, obyyasnyatj, proveryatj i svyazyivatj s proiskhozhdeniyem, to yazyik avtomatizacij vyibirayet iz etogo grafa te formyi, kotoryim uzhe mozhno datj strogij sintaksis, tipyi, effektyi, trassyi, fiksturyi i lokaljnoye ispolneniye.

Konstrukciya yazyika - shag workflow, deklarativnyij blok, skhema vkhoda, proverka, adapter instrumenta ili pravilo zapisi rezuljtata - dolzhna imetj operatornyij profilj. V nyom vidno, chto imenno konstrukciya raspoznayot v susjhestvuyusjhej praktike, kakuyu formu porozhdayet, kakiye ostatki i oshibki dopuskayet, kak proveryayetsya i kakiye svyazi imeyet s drugimi operatorami. Poetomu razvitiye yazyika i razvitiye operatornoj sistemyi vzaimno pitayut drug druga: povtoryayemyij operator mozhet statj sintaksicheskoj konstrukciyej avtomatizacii, a trassyi zapuskov avtomatizacij dayut material dlya utochneniya, oslableniya ili otkloneniya operatorov.

## Optimizaciya dlya LLM

Optimizaciya dlya LLM oznachayet, chto yazyik proyektiruyetsya s uchyotom ogranichenij modeli kak soavtora koda:

- grammatika dolzhna byitj neboljshoj, regulyarnoj i prigodnoj dlya strogogo parsinga;
- kanonicheskoye formatirovaniye dolzhno umenjshatj shum diffov i isklyuchatj stilevyiye variantyi bez smyislovoj raznicyi;
- odno i to zhe dejstviye dolzhno imetj odin predpochtiteljnyij sposob zapisi;
- imena shagov, vkhodov, vyikhodov i effektov dolzhnyi byitj korotkimi, chelovekochitayemyimi i stabiljnyimi;
- lokaljnaya oblastj izmeneniya dolzhna byitj malenjkoj: pravka odnogo shaga ne dolzhna trebovatj perepisyivatj vesj fajl;
- oshibki parsinga, tipizacii i proverki dolzhnyi ukazyivatj na konkretnyij fragment i vozmozhnyij sposob ispravleniya;
- yazyik dolzhen podderzhivatj strukturirovannyiye kommentarii dlya namereniya, ogranichenij i istochnikov, no ne dolzhen trebovatj skryityikh rassuzhdenij modeli;
- rezuljtat formatirovaniya, parsinga i obratnoj serializacii dolzhen byitj stabiljnyim.

Dlya LLM vazhna ne toljko vyiraziteljnostj, no i nizkaya neodnoznachnostj. Chem menjshe skryityikh soglashenij, neyavnyikh importov, magicheskikh globaljnyikh sostoyanij i svobodnyikh tekstovyikh interpretacij, tem legche modeli izmenyatj avtomatizaciyu bez razrusheniya kontrakta.

## Modelj ispolneniya

Bazovaya modelj ispolneniya dolzhna sokhranyatj razdeleniye, uzhe prinyatoye dlya [vosproizvodimyikh avtomatizacij](17-vosproizvodimyiye-avtomatizacii.md):

- chistoye yadro preobrazuyet yavno peredannyiye vkhodyi, snimki sostoyaniya i konfiguraciyu v rezuljtat;
- obolochki vvoda-vyivoda chitayut sredu, vyizyivayut instrumentyi, zapisyivayut fajlyi, vzaimodejstvuyut s interfejsom, setjyu ili ustrojstvami;
- effektyi obyyavlyayutsya yavno i proveryayutsya do ispolneniya;
- opasnyiye ili neobratimyiye dejstviya prokhodyat cherez yavnyiye podtverzhdeniya i [urovni dostupa](../Glossarij/urovenj-dostupa.md);
- kazhdyij zapusk ostavlyayet trassu: vkhodyi, vyibrannyiye shagi, versii, effektyi, oshibki, rezuljtat i proverochnyij status.

Yazyik dolzhen podderzhivatj kak linejnyiye proceduryi, tak i grafovyiye strukturyi: vetvleniya, povtor, ozhidaniye vneshnego sobyitiya, handoff, sliyaniye rezuljtatov i zaversheniye. Dlya [agentskogo cikla](../Glossarij/agentskij-cikl.md) eto pozvolyayet opisyivatj ne toljko dejstviye, no i nablyudeniye, obnovleniye sostoyaniya, proverku ostanovki i sokhraneniye rezuljtata.

## Minimaljnaya yedinica yazyika

Minimaljnaya yedinica yazyika - opisaniye avtomatizacii. V nyom dolzhnyi byitj vyidelenyi:

- imya, versiya, naznacheniye i istochnik trebovaniya;
- vkhodnyiye skhemyi, vyikhodnyiye skhemyi i dopustimyiye oshibki;
- chitayemyiye oblasti [pamyati](../Glossarij/pamyatj-FUM.md) i vneshnego sostoyaniya;
- razreshyonnyiye effektyi i neobkhodimyiye podtverzhdeniya;
- shagi chistogo vyichisleniya;
- vyizovyi instrumentov ili adapterov;
- proverki, fiksturyi i ozhidayemyiye rezuljtatyi;
- pravila zapisi trassyi i rezuljtata obratno v pamyatj;
- ogranicheniya publikacionnoj chistotyi.

Eta struktura vazhneye konkretnogo sintaksisa pervogo prototipa. Sintaksis mozhet razvivatjsya, no perechislennyiye polya obrazuyut kontrakt: bez nikh avtomatizaciya ostayotsya slishkom neyavnoj dlya nadyozhnogo nasledovaniya i LLM-pravki.

Pole imeni dolzhno khranitj ne svobodnuyu latinskuyu stroku, a svyazannyij nabor predstavlenij. Kanonicheskim smyislovyim istochnikom sluzhit russkoye imya kirillicej; otobrazhayemaya latinskaya forma obyazana tochno sovpadatj s rezuljtatom LinguisticKit `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)` na revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Eto vnutrennij standart FUM, a ne utverzhdeniye o sootvetstvii ISO, GOST ili lyubomu drugomu universaljnomu standartu.

Tekhnicheskij slug vyichislyayetsya sleduyusjhim otdeljnyim etapom FUM: transliteraciya perevoditsya v nizhnij registr, probelyi zamenyayutsya defisami i pri neobkhodimosti dobavlyayetsya fiksirovannyij prefiks prostranstva imyon. Validator dolzhen razlichatj sobstvenno rezuljtat LinguisticKit i etu normalizaciyu, otklonyatj ruchnoye raskhozhdeniye predstavlenij i schitatj sovpadeniye slug raznyikh iskhodnyikh imyon oshibkoj. Avtomaticheskoye dobavleniye suffiksa ne zamenyayet razresheniye smyislovoj kollizii.

Dejstvuyusjhiye istoricheskiye isklyucheniya ustranenyi otdeljnoj migraciyej: [reyestr nazvanij avtomatizacij](../Instrumentyi/reyestr-nazvanij-avtomatizacij.json) khranit pustyiye `legacy` i `legacy_display`, a yazyik ne dolzhen prevrasjhatj upominaniya prezhnikh imyon v doslovnyikh zaprosakh ili zhurnalakh v shablon novogo imeni. Izmeneniye zakreplyonnoj revizii takzhe yavlyayetsya yavnoj migraciyej s povtornyim vyichisleniyem predstavlenij i proverkoj kollizij, a ne obyichnyim obnovleniyem zavisimosti.

Ispolnyayemyij adapter transliteracii ispoljzuyet [LinguisticKit iz proveryayemogo forka](../Zavisimosti/README.md) na zakreplyonnoj revizii. Fork i originaljnyij upstream sokhranyayutsya kak raznyiye Git-roli, a obnovleniye forka ne izmenyayet vyibrannuyu reviziyu i rezuljtatyi imyon bez otdeljnoj migracii.

## Svyazj s [TDD](../Glossarij/TDD.md)

Razrabotka yazyika i avtomatizacij na nyom dolzhna idti cherez [TDD](../Glossarij/TDD.md). Dlya samogo yazyika eto oznachayet, chto snachala fiksiruyutsya testyi parsera, formattera, validatora, interpretatora ili kompilyatora, a zatem realizaciya dovoditsya do prokhozhdeniya etikh proverok.

Dlya kazhdoj avtomatizacii ozhidayemoye povedeniye dolzhno byitj vyirazimo ryadom s yeyo iskhodnyim opisaniyem: minimaljnyiye vkhodyi, ozhidayemyiye vyikhodyi, dopustimyiye oshibki, snimki sostoyaniya i primeryi trass. Yesli avtomatizaciya zavisit ot vneshnego servisa, zakryitogo prilozheniya ili sekretov, yazyik dolzhen pozvolyatj opisatj lokaljnyij simulyator, fiksturu ili otchyot o nevosproizvodimoj chasti.

## Granica s susjhestvuyusjhimi yazyikami

[Yazyik avtomatizacij FUM](../Glossarij/yazyik-avtomatizacij-FUM.md) ne dolzhen prezhdevremenno stanovitjsya universaljnyim yazyikom programmirovaniya obsjhego naznacheniya. Yego pervaya zona otvetstvennosti - ustojchivyiye avtomatizacii [pamyati FUM](../Glossarij/pamyatj-FUM.md), agentskikh ciklov, adresnyikh opisanij, arkhivirovaniya istochnikov, proverki rezuljtatov i vzaimodejstviya s instrumentami.

Susjhestvuyusjhiye yazyiki mogut ostavatjsya ispolniteljnyim sloyem. Naprimer, avtomatizaciya mozhet opisyivatj kontrakt, effektyi, vkhodyi i proverki v LLM-oriyentirovannom formate, a otdeljnyij adapter vyipolnyatj konkretnuyu chastj cherez Python, TypeScript, shell, MCP-server ili drugoj runtime. V takom sluchaye yazyik avtomatizacij khranit smyisl i proveryayemuyu granicu, a ne pryachet ikh vnutri proizvoljnogo skripta.

## Tenzornyij vyichisliteljnyij graf kak celevoj sloj

Dlya chasti avtomatizacij polezen ne toljko interpretiruyemyij ili obyichnyij skriptovyij ispolniteljnyij sloj, no i kompilyaciya v tenzornyij vyichisliteljnyij graf, prigodnyij dlya ML- i GPU-infrastrukturyi. Etot sloj ne dolzhen formulirovatjsya kak prevrasjheniye proizvoljnogo algoritma v nejrosetj. Boleye tochnaya celj - perevoditj ogranichennyiye vyisokourovnevyiye chislennyiye programmyi v promezhutochnoye predstavleniye, sovmestimoye s rantajmami i kompilyatorami vrode ONNX, StableHLO, MLIR, XLA, IREE, TVM, Triton ili TensorRT.

Takoj celevoj sloj umesten dlya chistyikh vyichisliteljnyikh yader: tipizirovannyikh massivov i tenzorov, regulyarnyikh ciklov, map/reduce/scan-patternov, linejnoj algebryi, obrabotki izobrazhenij, DSP, regulyarnyikh simulyacij i drugikh krupnyikh operacij, gde kompilyator mozhet uvidetj formu dannyikh i obyyedinitj operacii. On ne yavlyayetsya khoroshej bazoj dlya proizvoljnogo vvoda-vyivoda, dinamicheskoj allokacii, pointer chasing, neregulyarnogo obkhoda grafov, strokovoj obrabotki, sistemnyikh vyizovov i imperativnyikh programm s bogatyim izmenyayemyim sostoyaniyem.

Poetomu yazyik avtomatizacij dolzhen razlichatj obsjhij sloj opisaniya avtomatizacii i uzkij kompiliruyemyij podyyazyik. V podyyazyike dolzhnyi byitj yavno zadanyi formyi tenzorov, tipyi, chistota funkcii, dopustimyiye effektyi, ogranichennyiye ciklyi, determinirovannostj arifmetiki, fallback-ispolneniye i proverka ekvivalentnosti s etalonnoj realizaciyej. Trassa zapuska dolzhna sokhranyatj ne toljko iskhodnoye opisaniye, no i vyibrannyij celevoj IR, versii kompilyatora, runtime, apparatnyij profilj, rezuljtatyi testov i izvestnyiye poteri nablyudayemosti.

## Trebovaniya k perenosimosti

Tak kak [FUM](../Glossarij/FUM.md) proyektiruyetsya kak setj uzlov i [narabotok](../Glossarij/narabotka.md), avtomatizaciya na etom yazyike dolzhna byitj perenosimoj:

- istochnik dolzhen byitj publikacionno chistyim ili yavno pomechatj zakryityiye chasti;
- zavisimosti dolzhnyi byitj perechislenyi i versionirovanyi;
- prava chteniya, zapisi i dejstviya dolzhnyi byitj otdelenyi ot koda logiki;
- vneshniye adapteryi dolzhnyi imetj kontrakt, kotoryij mozhno proveritj bez dostupa k sekretam;
- trassa zapuska dolzhna pozvolyatj drugomu uzlu ponyatj, chto byilo sdelano i gde rezuljtat raskhoditsya s ozhidaniyem.

Perenosimostj ne oznachayet avtomaticheskoye pravo na vyipolneniye. Drugoj [FUM-uzel](../Glossarij/FUM-uzel.md) mozhet prinyatj opisaniye avtomatizacii kak znaniye, no ne obyazan davatj yej dostup k svoim dannyim, instrumentam ili ustrojstvam.

## Pervyij prakticheskij sloj

Pervyij prakticheskij sloj yazyika stoit razvivatj vokrug uzhe susjhestvuyusjhikh konturov:

- deklarativnyiye skhemyi iz `Описания/Автоматизации/`;
- lokaljnyiye instrumentyi iz `Инструменты/`;
- proverki rabochej sessii i pravila sokhraneniya [iskhodnyikh zaprosov](../Glossarij/iskhodnyij-zapros.md);
- kontur arkhivirovaniya prikreplyayemyikh materialov;
- budusjhij ispolnyayemyij [agentskij cikl](../Glossarij/agentskij-cikl.md).

Minimaljnyij eksperiment mozhet nachatjsya ne s polnocennogo kompilyatora, a s formata, kotoryij opisyivayet odnu realjnuyu avtomatizaciyu, validiruyetsya lokaljnyim testom, formatiruyetsya kanonicheski i svyazyivayet iskhodnyij zapros, vkhodnyiye dannyiye, shagi, effektyi, proverki i rezuljtat. Posle etogo yazyik mozhno rasshiryatj toljko tam, gde povtoryayemyiye avtomatizacii dejstviteljno trebuyut novogo vyiraziteljnogo sredstva.

## Kriterii zrelosti

Yazyik mozhno schitatj sozrevayusjhim, yesli:

- LLM sposobna vnesti maluyu pravku po testovoj oshibke bez perepisyivaniya vsego opisaniya;
- chelovek mozhet prochitatj avtomatizaciyu i ponyatj yeyo effektyi do zapuska;
- lokaljnyij validator nakhodit strukturnyiye oshibki ranjshe ispolneniya;
- formatter delayet diffyi stabiljnyimi i kompaktnyimi;
- trassa zapuska svyazyivayet rezuljtat s konkretnyimi shagami iskhodnogo teksta;
- avtomatizaciya mozhet byitj peredana drugomu uzlu vmeste s kontraktom, testami i ogranicheniyami;
- novyiye vozmozhnosti yazyika poyavlyayutsya iz realjnyikh avtomatizacij, a ne iz abstraktnogo zhelaniya postroitj boljshoj yazyik zaraneye.

## Vneshnij material

- [arkhivirovannyij istochnik Roman-Kerimov/LinguisticKit](../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [arkhivirovannaya vyibrannaya reviziya LinguisticKit](../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij](../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-06-24 15:08:46 MSK](../Zhurnal/2026-06-24_15-08-46_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-06 13:34:08 MSK - Opisatj kompilyaciyu algoritmov v tenzornyij graf](../Zhurnal/2026-07-06_13-34-08_MSK_opisatj-kompilyaciyu-algoritmov-v-tenzornyij-graf/zapros.md)
- [iskhodnyij zapros 2026-07-08 12:11:56 MSK - Svyazatj yazyik avtomatizacij i operatornuyu sistemu](../Zhurnal/2026-07-08_12-11-56_MSK_svyazatj-yazyik-avtomatizacij-i-operatornuyu-sistemu/zapros.md)
- [iskhodnyij zapros 2026-07-21 12:18:37 MSK - Zakrepitj transliteraciyu nazvanij avtomatizacij](../Zhurnal/2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK — Aktualizirovatj fork i podklyuchitj LinguisticKit](../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:bf12026c5eccc77375f9c3f71495b9d8d926efcd4eb47483bc819ad96d61d0aa -->
<!-- FUM-MD-RECENCY:END -->
