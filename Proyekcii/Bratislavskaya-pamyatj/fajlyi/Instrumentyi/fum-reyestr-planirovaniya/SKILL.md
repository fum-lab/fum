---
name: fum-reyestr-planirovaniya
description: Sobiratj i proveryatj mashinno chitayemyij reyestr trebovanij, stadij realizacii, MVP-kandidatov, kartochek shagov, kartochek cepochek shagov i otkryityikh voprosov FUM, a takzhe bezopasno pereimenovyivatj kartochki shagov s obnovleniyem zhivyikh tekstovyikh ssyilok.
---

# FUM Planning Registry

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoraya sobirayet mashinno chitayemyij JSON-reyestr planovogo sloya proyekta iz tekusjhikh Markdown-istochnikov:

- [kanonicheskikh kartochek trebovanij FUM](../../Trebovaniya/README.md);
- [svodnoj tablicyi trebovanij i realizacij](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md);
- [dorozhnoj kartyi](../../Planirovaniye/dorozhnaya-karta.md);
- [stadij planirovaniya](../../Planirovaniye/stadii/README.md);
- [grafa zavisimostej korobochnoj realizacii](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.md) i yego [mashinnoj proyekcii](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/graf-zavisimostej.json);
- [napravlenij proyektirovaniya i razvitiya](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/README.md);
- [MVP-kandidatov](../../Planirovaniye/MVP-kandidatyi/README.md);
- kanonicheskogo [indeksa kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md) i samikh kartochek `<эмодзи>-FUM-STEP-NNNN-<краткое-название>.md`;
- kanonicheskogo [indeksa kartochek cepochek shagov](../../Planirovaniye/kartochki-cepochek-shagov/README.md) i samikh kartochek `<эмодзи>-FUM-ЦЕПОЧКА-NNNN-<краткое-название>.md`;
- neispolnyayemoj [planovoj vyiborki 9 prioritetnyikh prodolzhenij vetki `master`](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md) i yeyo proveryayemoj proyekcii po stadiyam i gorizontam v dorozhnoj karte;
- perekhodnogo [obzora predlozhenij o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md), kotoryij boljshe ne yavlyayetsya istochnikom formulirovok i statusov;
- [otkryityikh voprosov](../../Voprosyi/README.md).

Rezuljtat skhemyi `9` khranitsya v [reyestre trebovanij, stadij realizacii i kandidatov](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json). Massiv `requirements` stroitsya toljko iz atomarnyikh kartochek `Требования/` s ustojchivyimi `FUM-REQ-*`; shirokiye stroki svodnoj tablicyi vkhodyat otdeljno kak `planning_views`; massiv `steps` stroitsya iz kartochek s ustojchivyimi `FUM-STEP-*`; massiv `цепочки_шагов` stroitsya iz kartochek `FUM-ЦЕПОЧКА-*` i sokhranyayet ikh uporyadochennyiye ssyilki na shagi i tochnyiye lokaljnyiye vetki; `boxed_implementation_graph` vklyuchayet proverennuyu mashinnuyu proyekciyu elementov `P0`–`P16`, ikh zavisimostej, predposyilok gotovnosti, paralleljnyikh vetvej, riskov i MVP-svyazej. `source_inventory.очередь_дорожной_карты` svyazyivayet kazhduyu iz 9 zapisej planovoj vyiborki s aktualjnoj kartochkoj, kategoriyej ogranicheniya, zavisimostyami, stadiyami, gorizontami i pribliziteljnyim usloviyem ruchnogo vyibora, a `source_inventory.покрытие_дорожной_карты` dokazyivayet polnotu obeikh osej. Eto ne polnyij pul: posle zaversheniya FUM-STEP-0129 v kataloge ostayutsya yesjhyo 30 aktivnyikh kartochek vne etoj proyekcii. Sovmestimyiye predstavleniya `source_inventory.active_proposals` i `source_inventory.proposal_history` proizvodyatsya iz tekh zhe kartochek shagov i sokhranyayut ikh stabiljnyiye identifikatoryi. JSON ne zamenyayet iskhodnyiye Markdown-materialyi, a dayot proveryayemyij sloj dlya programmnoj sverki i budusjhej peresborki navigacii.

Pri `manual-sequential-v1` polya prezhnej skhemyi `step_id`, `dispatch` i vyichislennyij legacy-nabor bez nezavershyonnyikh zavisimostej ne dayut runtime-ready, selector-prioriteta, avtozapuska ili polnomochij na dejstviye. Kazhdyij sleduyusjhij shag vyibirayet poljzovatelj otdeljnyim soderzhateljnyim zaprosom.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu, kogda menyayutsya planovyiye materialyi, svodnaya tablica, napravleniya, MVP-kandidatyi, kartochki shagov, ikh indeks ili voprosyi i nuzhno ubeditjsya, chto mashinno chitayemyij sloj sootvetstvuyet tekusjhemu sostoyaniyu pamyati.

Avtomatizaciya takzhe polezna pered razrabotkoj novyikh planovyikh proverok: JSON uzhe soderzhit formulirovki, statusyi, kriterii i tipizirovannyij graf atomarnyikh trebovanij, shirokiye planovyiye predstavleniya, predpolagayemuyu realizaciyu na dokumentacionnoj stadii i v korobochnoj FUM, kandidatov, stadijnuyu kartu MVP, stadijnuyu ocheredj produktovyikh kandidatov, dorozhnyiye gorizontyi, kartochki shagov, sovmestimyiye proyekcii aktivnyikh i istoricheskikh predlozhenij i voprosyi po statusam.

## Komandyi

Sobratj reyestr:

```bash
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py build \
  --output Планирование/реестр-требований-вариантов-и-кандидатов.json
```

Proveritj, chto sokhranyonnyij reyestr ne ustarel otnositeljno istochnikov:

```bash
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py validate \
  --registry Планирование/реестр-требований-вариантов-и-кандидатов.json
```

Sinkhronizirovatj toljko `source.content_sha256_without_recency` mashinnogo grafa s yego Markdown-istochnikom:

```bash
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py \
  sync-boxed-graph-source-hash
```

Komanda do zapisi proveryayet JSON, skhemu i vesj kontrakt grafa, tochnyij kanonicheskij putj i iskhodnyij format khesha. Lyuboye raskhozhdeniye, krome korrektno oformlennogo ustarevshego khesha, zakryivayet komandu bez izmeneniya fajla. Novyiye bajtyi gotovyatsya vo vremennom fajle ryadom s celjyu i ustanavlivayutsya atomarno; povtor pri uzhe tochnom kheshe ne perezapisyivayet JSON.

Smenitj zhiznennyij status kartochki i pri neobkhodimosti utochnitj yeyo opisateljnoye imya:

```bash
python3 Инструменты/fum-reyestr-planirovaniya/scripts/rename-step-card.py \
  --card-id FUM-STEP-NNNN \
  --status completed
```

Dlya odnovremennogo utochneniya imeni dobavj `--description новое-краткое-название`. Do vyizova podgotovj sootvetstvuyusjhiye novomu statusu razdelyi kartochki. Yesli prezhnij putj prisutstvuyet v `Планирование/следующие-шаги-веток/*.md`, snachala udali vyipolnennogo kandidata libo perevyipusti aktualjnogo kandidata s novyim `card_path` i svezhim `step_id`: komanda zakryivayetsya do zapisi i ne ispravlyayet vetochnyij fence avtomaticheski.

Posle polnogo preflight komanda vyivodit novoye imya iz `card_id`, statusa i opisaniya, vyipolnyayet nastoyasjhij `git mv`, sinkhroniziruyet pole `status` i stroku polnogo indeksa, zatem zamenyayet tochnoye prezhneye imya vo vsekh dostupnyikh UTF-8 tekstakh iz Git-inventarya. Do `git mv` vse novyiye bajtyi i rezervnyiye kopii gotovyatsya vo vremennyikh fajlakh ryadom s celyami; ustanovka vyipolnyayetsya atomarnoj zamenoj kazhdogo fajla, a oshibka vozvrasjhayet iskhodnyiye bajtyi i obratnyij Git-perenos. Nedostupnaya kanonicheskaya zapisj sleduyusjhego shaga i dublikat `card_id` sredi otslezhivayemyikh ili novyikh kartochek ostanavlivayut operaciyu do pereimenovaniya.

Razdel `## Текст запроса` kazhdogo tochnogo fajla `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md`, vesj katalog `Источники/`, simvoljnyiye ssyilki, dvoichnyiye i ne-UTF-8 fajlyi ostayutsya pobajtno neizmennyimi. JSON-reyestr posle operacii peresobirayetsya obyichnoj komandoj `build`, a recency i graf — sobstvennyimi generatorami.

## Chto proveryayetsya

Validator:

- proveryayet JSON-skhemu `fum.planning.requirements-registry.v9` i vlozhennuyu skhemu grafa `fum.planning.boxed-implementation-dependency-graph.v1`;
- peresobirayet ozhidayemyij reyestr iz tekusjhikh istochnikov i sravnivayet yego s sokhranyonnyim fajlom;
- fiksiruyet khyeshi iskhodnyikh Markdown-fajlov bez sluzhebnogo bloka `FUM-MD-RECENCY`;
- trebuyet rovno odin unikaljnyij marker `FUM-REQUIREMENT-ID` v kazhdoj kartochke i ne vyivodit ID iz imeni, statusa ili pozicii;
- sveryayet polnyij nabor kartochek s `Требования/README.md`, dopustimyij status v imeni, indekse i tele, chetyire obyazateljnyikh razdela i nepustyiye formulirovku s kriteriyami;
- proveryayet dopustimyiye tipyi semanticheskikh svyazej, indeksirovannyiye celi i rovno odnu soglasovannuyu obratnuyu zapisj dlya kazhdogo napravlennogo otnosheniya;
- trebuyet, chtobyi kazhdaya shirokaya stroka imela yavnyij `PLAN-LAYER-*` i byila libo svyazana s kartochkami, libo pomechena kak `Производный слой`;
- trebuyet u kazhdoj kartochki shaga tochnyij TOML-kontrakt `schema_version`, `card_id`, `status`, unikaljnyij `FUM-STEP-NNNN`, rovno odin zagolovok pervogo urovnya, zadachu i spisochnyiye istochniki so ssyilkami;
- proveryayet imya `<эмодзи>-FUM-STEP-NNNN-<краткое-название>.md`: `🟡`, `✅`, `🧩` i `🗑️` dolzhnyi sootvetstvovatj mashinnomu statusu, nomer — `card_id`, nepustoye opisaniye — defisnomu formatu iz Unicode-bukv i cifr, a polnoye imya — predelu 255 bajt UTF-8;
- trebuyet ploskij katalog kartochek i schitayet tochnyij kornevoj `README.md` yedinstvennyim Markdown-fajlom, osvobozhdyonnyim ot kartochnogo kontrakta;
- dlya `active` trebuyet `Почему сейчас` i spisochnyiye `Критерии завершения`, a dlya `completed`, `absorbed` i `withdrawn` — `Результат`;
- proveryayet yedinstvennuyu indeksnuyu tablicu s kolonkami `Идентификатор | Статус | Карточка`, polnoye vzaimno odnoznachnoye pokryitiye vsekh kartochek shaga, unikaljnostj ID i putej, sootvetstviye mashinnogo i russkogo statusov s emodzi i tochnoye sovpadeniye zagolovka kartochki s podpisjyu ssyilki;
- vklyuchayet obzor, indeks i kazhduyu kartochku shaga v `source_files`, poetomu izmeneniye lyubogo iz etikh istochnikov delayet sokhranyonnyij JSON ustarevshim;
- trebuyet u kazhdoj kartochki cepochki tochnyij TOML-kontrakt skhemyi `1` s zaklyuchyonnyimi v kavyichki kirillicheskimi klyuchami, unikaljnyij `FUM-ЦЕПОЧКА-NNNN`, dopustimoye sostoyaniye, vetku vnutri `refs/heads/codex/`, lokaljnuyu bazovuyu vetku, susjhestvuyusjhij otnositeljnyij putj proyekta i nepustoj uporyadochennyij spisok izvestnyikh kartochek shagov;
- proveryayet imya, statusnyij emodzi i polnyij indeks kartochek cepochek, trebuyet rovno odnu aktivnuyu cepochku, zapresjhayet povtor vetki i chlenstvo odnogo shaga v neskoljkikh neotozvannyikh cepochkakh i vklyuchayet indeks s kazhdoj kartochkoj v `source_files`;
- proveryayet, chto v istochnikovom inventare yestj tochnyij nabor dorozhnyikh gorizontov `0`–`8`, stadii, napravleniya, MVP-kandidatyi, stadijnaya karta MVP, predlozheniya i voprosyi po statusam;
- strogo razbirayet tochnyij zagolovok i razdelitelj kartyi stadij, trebuyet polnogo pokryitiya fakticheskikh pasportov i ne prinimayet simvoljnyij, registrovyij libo inoj leksicheskij psevdonim exact-ssyilki;
- razbirayet tochnyij TOML-kontrakt skhemyi `5` neispolnyayemoj vyiborki `refs/heads/master`, trebuyet aktualjnyiye unikaljnyiye kartochki i khyeshi ikh soderzhimogo, dopustimyiye kategorii `dispatch`, pokoleniya i zavisimosti i vklyuchayet nabor v `source_files`;
- trebuyet, chtobyi strogaya tablica dorozhnoj kartyi tochno i v tom zhe poryadke pokryivala vse 9 zapisej vyiborki, povtoryala ikh pokoleniya, kategorii ogranichenij i zavisimosti, ssyilalasj na izvestnyiye stadii i gorizontyi i vyivodila pribliziteljnoye usloviye ruchnogo vyibora toljko iz `dispatch` i zhiznennyikh statusov zavisimostej;
- trebuyet otdeljnuyu stroku pokryitiya dlya kazhdoj stadii i kazhdogo zagolovka `Горизонт N`, zapresjhayet neizvestnyiye i povtornyiye konturyi i prinimayet pustoj kontur toljko s tochnyim markerom `Нет назначенного шага`;
- proveryayet exact-polya, tipyi, ssyilki i perekryostnuyu soglasovannostj obeikh sokhranyonnyikh JSON-proyekcij dorozhnoj kartyi nezavisimo ot povtornoj sborki istochnikov;
- proveryayet, chto MVP-kandidatyi pokryityi shirokimi planovyimi predstavleniyami, stadijnoj kartoj ili ocheredjyu produktovyikh kandidatov.
- trebuyet exact-polya mashinnogo grafa i privyazku k tochnomu Markdown-istochniku cherez SHA-256 bez `FUM-MD-RECENCY`;
- trebuyet tochnyij polnyij nabor `P0`–`P16`, nepreryivnyiye nomera predstavleniya, izvestnyiye zavisimosti bez povtorov, self-edge i ciklov, no ne schitayet `order` topologicheskim rangom;
- proveryayet nepustyiye tekstovyiye predposyilki i kriterii gotovnosti kazhdogo elementa, ne smeshivaya ikh s ryobrami Mermaid, a pravilo gotovnosti trebuyet otdeljno vyipolnitj zavisimosti, tekstovyiye predposyilki, kriterii rezuljtata i snyatj vse svyazannyiye blokiruyusjhiye riski;
- trebuyet, chtobyi v kazhdoj obyyavlennoj paralleljnoj gruppe byilo ne meneye dvukh izvestnyikh elementov bez pryamoj ili tranzitivnoj zavisimosti drug ot druga;
- proveryayet unikaljnyiye blokiruyusjhiye riski, izvestnyiye blokiruyemyiye elementyi, kriterii snyatiya i susjhestvuyusjhiye otnositeljnyiye puti istochnikov;
- sveryayet `mvp-*` i tochnyiye puti mashinnogo grafa s inventaryom MVP i trebuyet pokryitiya kazhdogo tekusjhego kandidata rovno odnoj zapisjyu svyazi;
- komanda sinkhronizacii khesha otklonyayet do zapisi malformed JSON, nevernuyu skhemu, nekanonicheskij ili simvoljnyij putj, malformed-khesh i lyubuyu inuyu oshibku kontrakta grafa;
- pered pereimenovaniyem kartochki proveryayet yedinstvennostj `card_id`, dopustimostj i otsutstviye novogo puti, otslezhivayemostj iskhodnoj kartochki i otsutstviye prezhnego puti v vetochnom rabochem nabore;
- pri uspeshnom pereimenovanii sokhranyayet Git-operaciyu `git mv`, obnovlyayet status i vyirovnennuyu indeksnuyu tablicu i soobsjhayet determinirovannyij spisok zhivyikh tekstovyikh fajlov, v kotoryikh zameneno prezhneye imya.

## Proverki avtomatizacii

Lokaljnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p 'test_*.py'
```

Testyi fiksiruyut bazovyij kontrakt: sborka normalizuyet kartochki trebovanij, shagov i cepochek, obratnyiye paryi svyazej i sovmestimyiye proyekcii predlozhenij; razlichayet kartochechno-svyazannyiye i proizvodnyiye shirokiye stroki; otklonyayet defektyi imeni fajla, TOML, ID, vetochnyikh refs, uslovnyikh razdelov, spiskov, ssyilok, statusov i polnogo indeksirovaniya; zapresjhayet neizvestnyiye i povtorno raspredelyonnyiye shagi cepochek; vklyuchayet vse kartochki v istochniki; prinimayet svezhesobrannyij JSON i soobsjhayet ob ustarevanii posle izmeneniya kartochki. Avtonomnaya fikstura ocheredi otdeljno podtverzhdayet tochnyij nabor gorizontov `0`–`8`, yavnoye otsutstviye naznacheniya i otklonyayet propusjhennuyu stadiyu ili gorizont, nesusjhestvuyusjhuyu, simvoljnuyu libo leksicheski netochnuyu celj stadii, poteryannogo kandidata, bituyu libo snyatuyu kartochku, nestroguyu granicu TOML, vesjhestvennuyu versiyu skhemyi, netekstovyiye polya, pustoj diapazon, cikl i nesinkhronnuyu perestanovku zapisej libo smenu pokoleniya, rezhima ili zavisimostej. Fikstura mashinnogo grafa otklonyayet poteryu lyubogo elementa `P0`–`P16`, neizvestnuyu zavisimostj, cikl, zavisimyiye elementyi v paralleljnoj gruppe, neizvestnyij MVP i ustarevshij khyesh Markdown. Otdeljnaya Git-fikstura podtverzhdayet pereimenovaniye kartochki, sinkhronizaciyu statusa i indeksa, zamenu obyichnyikh, uglovyikh i mashinnyikh putej, sokhraneniye pervichnyikh istochnikov i otkaz do zapisi pri negotovom imeni ili prezhnem vetochnom `step_id`.

## Granica avtomatizacii

Avtomatizaciya ne vyivodit novyiye trebovaniya ili shagi iz smyisla dokumentov, ne naznachayet `FUM-REQ-*` ili `FUM-STEP-*` i ne reshayet, kakoj MVP ili shag vyibiratj v rabotu. Pereimenovaniye ne sochinyayet `Результат`, ne vyibirayet sleduyusjhij vetochnyij kandidat i ne vyipuskayet novyij `step_id`: eti smyislovyiye izmeneniya rabochaya sessiya gotovit yavno. Avtomatizaciya normalizuyet uzhe zapisannyiye kartochki i planovyij sloj, perenosit putj bez poteri zhivyikh ssyilok i pomogayet obnaruzhitj strukturnoye raskhozhdeniye mezhdu mashinno chitayemyim reyestrom i Markdown-istochnikami. Khyesh grafa dokazyivayet privyazku k versii Markdown, no ne avtomaticheskoye semanticheskoye ravenstvo ruchnoj proyekcii; skhema v1 ne vyichislyayet OR-zavisimosti, fakticheskoye snyatiye riskov ili gotovnostj elementa i schitayet paralleljnyiye gruppyi nepolnyim naborom dokazannyikh vetvej, a ne raspisaniyem ili barjyernyimi urovnyami. Smyislovaya otvetstvennostj za formulirovki, statusyi kartochek, svyazi shirokikh sloyov i otkryityiye voprosyi ostayotsya u rabochej sessii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-14 18:59:37 MSK — Isklyuchitj dublirovaniye polnoj regressii](../../Zhurnal/2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [iskhodnyij zapros 2026-08-13 13:14:24 MSK — Svyazatj sleduyusjhiye shagi s dorozhnoj kartoj](../../Zhurnal/2026-08-13_13-14-24_MSK_svyazatj-sleduyusjhiye-shagi-s-dorozhnoj-kartoj/zapros.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-24 05:27:17 MSK - Perevesti graf zavisimostej korobochnoj realizacii v mashinnyij sloj](../../Zhurnal/2026-07-24_05-27-17_MSK_perevesti-graf-zavisimostej-korobochnoj-realizacii-v-mashinnyij-sloj/zapros.md)
- [iskhodnyij zapros 2026-07-23 10:44:00 MSK - Avtomatizirovatj obnovleniye ssyilok pri smene statusa kartochki](../../Zhurnal/2026-07-23_10-44-00_MSK_avtomatizirovatj-obnovleniye-ssyilok-pri-smene-statusa-kartochki/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK - Dekompozirovatj predlozheniya na kartochki shagov](../../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-01 13:32:17 MSK](../../Zhurnal/2026-07-01_13-32-17_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-20 21:22:17 MSK](../../Zhurnal/2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)
- [iskhodnyij zapros 2026-07-22 11:48:49 MSK — Oformitj kartochki shagov opisateljnyimi imenami i emodzi statusami](../../Zhurnal/2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:3820199f88b502394ee8ed588bda1f417dd135909f4bff69bc45d76ca5abaa5f -->
<!-- FUM-MD-RECENCY:END -->
