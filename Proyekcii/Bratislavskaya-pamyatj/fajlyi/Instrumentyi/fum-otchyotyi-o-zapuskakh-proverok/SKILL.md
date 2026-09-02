---
name: fum-otchyotyi-o-zapuskakh-proverok
description: Avtomaticheski vesti mashinnyij uchyot kazhdogo pryamogo zapuska testov, validatorov, sborok, lint, benchmark i smoke-check i determinirovanno formirovatj iz nego proveryayemyij razdel otchyota rabochej sessii.
---

# Otchyotyi o zapuskakh proverok

Eta lokaljnaya avtomatizaciya zamenyayet ruchnoye perepisyivaniye rezuljtatov pryamyikh proverochnyikh vyizovov v zhurnaljnyij otchyot. Ona zapuskayet rovno odin peredannyij process bez obolochki, srazu sozdayot prinadlezhasjhuyu rabochej sessii mashinnuyu zapisj, sokhranyayet nablyudyonnuyu dliteljnostj i iskhod, a posle zaversheniya vsekh paralleljnyikh ispolnitelej determinirovanno stroit razdel `### Прямые запуски проверок` sosednego `отчёт.md`.

Avtomatizaciya uchityivayet toljko verkhneurovnevyiye vyizovyi, pryamo zapusjhennyiye kornevoj pishusjhej sessiyej: test, validator, sborku, lint, benchmark, standartnyij libo yavnyij polnyij smoke-check i inoj proverochnyij process. Read-only-subagentyi mogut vernutj komandu ili dokazateljstvo, no ne zapuskayut proverochnyij process i ne sozdayut mashinnuyu zapisj. Vnutrenniye shagi sostavnogo ispolnitelya ostayutsya yego detalizaciyej i vtoroj raz v mashinnyij zhurnal ne dobavlyayutsya. Odinakovyiye komandyi i povtornyiye popyitki nikogda ne svorachivayutsya: kazhdyij fakticheskij zapusk poluchayet sobstvennuyu zapisj.

Nachinaya s rabochej sessii `2026-08-04_20-45-26_MSK_формировать-отчёты-о-запусках-тестов`, zakryityij mashinnyij snimok i sootvetstvuyusjhij yemu zakryityij Markdown-blok yavlyayutsya obyazateljnoj granicej novogo otchyota, yesli v okhvachennom profilem intervale byili pryamyiye proverki. Boleye ranniye otchyotyi sokhranyayut istoricheskij format.

## Komandnyij interfejs

Tochka vkhoda avtomatizacii prinimayet odnu iz shesti komand: `запустить`, `предпросмотр`, `проверить-план`, `закрыть`, `возобновить` ili `проверить`. Dlya kazhdoj komandyi obyazateljnyi obsjhiye parametryi `--корень-репозитория` i `--запрос`. Putj zaprosa kanonicheski razreshayetsya vnutri ukazannogo kornya i obyazan vesti k obyichnomu fajlu `Журнал/<stem>/запрос.md`; sosednij `отчёт.md` vyivoditsya toljko iz nego.

Pryamoj zapusk oformlyayetsya tak:

```bash
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py \
  запустить \
  --корень-репозитория . \
  --запрос Журнал/<stem>/запрос.md \
  --название '<человекочитаемое название вызова>' \
  --исполнитель '<устойчивая метка исполнителя>' \
  --класс-проверки адресная \
  --тайм-аут-секунды <положительное число> \
  -- <программа> <аргументы...>
```

Parametr `--идентификатор-запуска <UUID>` mozhno peredatj posle `--исполнитель` dlya avtonomnoj fiksturyi ili zaraneye svyazannogo vyizova. V obyichnom zapuske avtomatizaciya sozdayot novyij kanonicheskij lowercase UUID. Povtor uzhe susjhestvuyusjhego identifikatora, pustoye nazvaniye, pustoj ispolnitelj, upravlyayusjhij simvol v etikh publikuyemyikh metkakh, neizvestnyij parametr, otsutstvuyusjhaya komanda posle `--`, NUL v argumente dochernej komandyi i nedopustimyij tajm-aut otklonyayutsya do zapuska processa. Drugiye argumentyi dochernej komandyi peredayutsya bukvaljno i ne publikuyutsya. `--тайм-аут-секунды` neobyazatelen; yesli on otsutstvuyet, avtomatizaciya ne pridumyivayet neyavnyij predel.

Sobstvennyiye chelovekochitayemyiye znacheniya `--название` i `--исполнитель` zadayutsya po-russki kirillicej; tochnyiye tekhnicheskiye tokenyi sokhranyayutsya toljko tam, gde bez nikh teryayetsya identichnostj proveryayemogo kontrakta. Posle sozdaniya eti metki stanovyatsya chastjyu khyeshirovannogo svideteljstva fakticheskogo zapuska i ne perepisyivayutsya radi perevoda ili kosmeticheskogo ispravleniya: oshibochnuyu metku yavno priznayut v otchyote, a posleduyusjhiye zapuski nazyivayut praviljno.

Obyazateljnyij parametr `--класс-проверки` vyibirayet rovno odin zakryityij klass: `адресная`, `диагностическая` ili `полная`. Adresnaya zapisj ne obyyavlyayet polnyikh naborov. Diagnosticheskaya zapisj povtoryayet `--полный-набор <ключ>` dlya kazhdoj zatronutoj granicyi, sokhranyayet `--основание` i `--ожидаемое-свидетельство`; osnovaniye `локализация_наблюдаемого_отказа` dopolniteljno trebuyet `--идентификатор-отказа <UUID>` raneye zavershyonnoj neuspeshnoj zapisi na tom zhe snimke. Klass `полная` razreshyon toljko dlya tochno raspoznannogo `run-smoke-check.py`, a klyuchi naborov vyivodyatsya iz yego fakticheskogo plana. Eto klass sostavnogo finaljnogo zapuska, a ne trebovaniye CLI-profilya `--профиль полный`: v obyichnoj ruchnoj sessii im yavlyayetsya yedinstvennyij finaljnyij standartnyij dokumentacionnyij smoke-check; yavno vyibrannyij polnyij profilj sam zanimayet etu yedinstvennuyu finaljnuyu poziciyu.

Ostaljnyiye komandyi ispoljzuyut tot zhe tochnyij zapros:

```bash
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py предпросмотр --корень-репозитория . --запрос Журнал/<stem>/запрос.md
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py проверить-план --корень-репозитория . --запрос Журнал/<stem>/запрос.md
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py закрыть --корень-репозитория . --запрос Журнал/<stem>/запрос.md
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py возобновить --корень-репозитория . --запрос Журнал/<stem>/запрос.md
python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py проверить --корень-репозитория . --запрос Журнал/<stem>/запрос.md
```

`предпросмотр` chitayet zapisi, proveryayet ikh i atomarno obnovlyayet otkryityij upravlyayemyij Markdown-blok bez sozdaniya snimka. `проверить-план` nichego ne menyayet, dopuskayetsya toljko v otkryitoj sessii bez snimka i zhurnala vosstanovleniya i trebuyet rovno odin uspeshnyij poslednij polnyij zapusk, otsutstviye nerazreshyonnogo perekryitiya i sovpadeniye tekusjhego Git-otpechatka s finaljnyim. `закрыть` dopuskayetsya toljko posle zaversheniya vsekh ispolnitelej: snachala ono dolgovechno ustanavlivayet kanonicheskij snimok, zatem atomarno zamenyayet upravlyayemyij Markdown-blok; fakticheskoye narusheniye plana chestno sokhranyayetsya kak `не готов`, no ne prokhodit terminaljnyij dopusk. `возобновить` otkryivayet toljko dopustimyij negotovyij profilirovannyij libo chisto istoricheskij v1-sbor posle strogogo podtverzhdeniya vsekh khyeshej i bajtov i provodit perekhod cherez otdeljnyij zhurnal vosstanovleniya. Gotovyij v3-snimok i istoricheskij snimok s v2 ne vozobnovlyayutsya. `проверить` nichego ne menyayet: otkryityij sbor ono dopuskayet toljko pri nalichii vyipolnyayusjhejsya zapisi, a zakryityij — kak tochnoye ravenstvo zapisej, snimka, marker-khyesha i Markdown; lyubaya nezavershyonnaya perekhodnaya faza otklonyayetsya.

## Razmesjheniye i skhema zapisi zapuska

Vse mashinnyiye dannyiye prinadlezhat odnomu zaprosu i razmesjhayutsya toljko v kataloge:

```text
Журнал/<stem>/материалы/запуски-проверок/
  <порядок>_<uuid>.json
  снимок.json
  возобновление.json
```

`снимок.json` susjhestvuyet v podgotovlennom ili zakryitom sostoyanii. `возобновление.json` susjhestvuyet toljko vo vremya nezavershyonnoj komandyi `возобновить` i udalyayetsya poslednim; v gotovom otkryitom ili zakryitom sostoyanii yego net.

Kazhdyij zapusk poluchayet odin fajl `<порядок>_<uuid>.json`. `порядок` — unikaljnoye polozhiteljnoye desyatichnoye chislo, naznachennoye pod mezhprocessnyim zamkom; UUID v imeni tochno sovpadayet s polem `идентификатор`. Chislovoj poryadok, a ne leksikograficheskij obkhod fajlovoj sistemyi, yavlyayetsya poryadkom strok otchyota. Povtor nomera i nesootvetstviye imeni soderzhimomu zapresjhenyi.

Istoricheskaya zapisj v1 imeyet skhemu `fum.test-run.v1` i zakryityij nabor polej:

- `схема` — tochnaya stroka `fum.test-run.v1`;
- `сессия` — kanonicheskij repo-relative putj `Журнал/<stem>/запрос.md` s `/` kak razdelitelem;
- `порядок` — polozhiteljnoye celoye chislo, sovpadayusjheye s imenem fajla;
- `идентификатор` — kanonicheskij lowercase UUID, sovpadayusjhij s imenem fajla;
- `состояние` — `выполняется` ili `завершён`;
- `исполнитель` — nepustaya odnostrochnaya metka, poluchennaya iz `--исполнитель`;
- `вызов` — nepustoye odnostrochnoye nazvaniye, poluchennoye iz `--название`;
- `длительность_наносекунды` — `null` vo vremya vyipolneniya libo neotricateljnoye celoye chislo posle zaversheniya;
- `статус` — `null` vo vremya vyipolneniya libo odna iz strok `успешно`, `неуспешно`, `прервано`, `не завершено`;
- `код_завершения` — `null` libo nablyudyonnyij celyij kod zaversheniya;
- `пояснение` — `null` libo odnostrochnoye diagnosticheskoye poyasneniye bez syirogo vyivoda processa.

Istoricheskij tochno raspoznannyij `run-smoke-check.py` lyubogo profilya, zapusjhennyij neposredstvenno libo podderzhannoj komandoj Python bez `--list`, mog poluchitj skhemu `fum.test-run.v2`. Ona sokhranyayet vse polya v1 i dobavlyayet `план` i `наблюдения` vyibrannogo profilya. Plan raven `null`, yesli podgotovka ne uspela yego sformirovatj, libo khranit uporyadochennyiye paryi kanonicheskogo repo-relative POSIX-klyucha `ключ_проверки` i `название`. Kazhdoye nablyudeniye povtoryayet etu paru i dobavlyayet terminaljnyij `статус` i celuyu neotricateljnuyu `длительность_наносекунды`. Aktivnaya v2-zapisj vsegda soderzhit `план: null` i pustyiye nablyudeniya; novyiye v2-fajlyi komandnyij interfejs ne sozdayot.

Kazhdaya novaya zapisj poluchayet skhemu `fum.test-run.v3`, sokhranyayet polya v2 i dobavlyayet zakryityij shestipolevoj obyyekt `профиль_проверки`: `класс`, `отпечаток_снимка`, `полные_наборы`, `основание`, `идентификатор_отказа` i `ожидаемое_свидетельство`. SHA-256-otpechatok avtomaticheski svyazyivayet `HEAD`, indeks, rabochuyu tracked-raznicu i bajtyi neignoriruyemyikh untracked-fajlov, prichyom indeks i rabochaya raznica khyeshiruyutsya razdeljno. Gryaznyij inicializirovannyij podmodulj zakryivayet vyichisleniye otkazom. Iz otpechatka isklyuchenyi tekusjhiye `отчёт.md`, `материалы/запуски-проверок/` i tochnaya kornevaya oblastj `Proyekcii` vmeste s potomkami: atomarnyiye zapisi obyortki i shtatnaya finaljnaya peresborka proizvodnogo pokoleniya ne menyayut kanonicheskij snimok. `Proyekcii-copy`, `proyekcii` i vlozhennyij `Документация/Proyekcii` ne isklyuchayutsya. V1 dopustim toljko kak istoricheskij prefiks do pervoj v3-zapisi; v2 neljzya smeshivatj s v3, a novaya istoricheskaya zapisj posle pervoj v3 otklonyayetsya do zapuska dochernego processa.

Dlya peredachi detalizacii obyortka sozdayot vne repozitoriya odnorazovyij capability-putj, UUID i kanonicheskij nachaljnyij konvert `fum.smoke-test-observations.v1` s `план: null`, pustyimi `наблюдения` i pustoj `текущая_проверка`. Smoke-check atomarno zamenyayet yego posle formirovaniya plana, do pervogo rannego fiksirovannogo shaga, pered startom i posle iskhoda kazhdogo testa; capability-peremennyiye udalyayutsya iz okruzheniya vlozhennyikh testov. Obyortka prinimayet konvert toljko pri sovpadenii UUID, zakryityikh naborakh polej, unikaljnyikh kanonicheskikh klyuchakh bez registronezavisimyikh kollizij, tochnom sootvetstvii nablyudenij prefiksu plana, ne boleye chem odnom poslednem neuspeshnom iskhode i summe vlozhennyikh dliteljnostej ne boljshe vneshnej. Pri tajm-aute ona zavershayet tekusjhij test kak `не завершено`, pri signale — kak `прервано`; signal imeyet prioritet nad oshibkoj konverta. Uspeshnyij vneshnij smoke obyazan podtverditj vesj sformirovannyij plan toljko uspeshnyimi nablyudeniyami. Vneshnij otkaz do pervogo testa dopustimo sokhranyayet nepustoj plan i pustyiye nablyudeniya, a otkaz posle polnostjyu uspeshnoj testovoj fazyi — polnyij uspeshnyij prefiks, poskoljku oshibitjsya mozhet fiksirovannaya proverka vne analiticheskogo plana. Bez boleye siljnoj prichinyi narusheniye protokola poluchayet `не завершено` i kod `125`, a vremennyij katalog udalyayetsya.

Do zapuska dochernego processa avtomatizaciya pod zamkom atomarno ustanavlivayet polnuyu zapisj s sostoyaniyem `выполняется` i `null` vo vsekh terminaljnyikh polyakh. Posle nablyudayemogo zaversheniya ona atomarno zamenyayet etot zhe fajl sostoyaniyem `завершён`. Fajl nikogda ne dopisyivayetsya chastyami. Nevozmozhnostj ustanovitj nachaljnuyu zapisj zapresjhayet zapusk processa; nevozmozhnostj ustanovitj terminaljnoye sostoyaniye delayet sam vyizov neuspeshnyim i ostavlyayet aktivnuyu zapisj, kotoraya zakryivayet formirovaniye otchyota do yavnogo ustraneniya prichinyi.

Sobstvennyiye zapisi avtomatizaciya serializuyet v UTF-8 s `ensure_ascii=False`, `sort_keys=True`, `indent=2` i rovno odnim zavershayusjhim perevodom stroki LF. Proverka prinimayet toljko tochnuyu skhemu i dopustimyiye znacheniya; paryi terminaljnogo statusa i koda zaversheniya proveryayutsya sovmestno. Publikuyemyiye metki otklonyayut upravlyayusjhiye simvolyi Unicode kategorij `Cc` i razdeliteli strok i abzacev `Zl`/`Zp`. Khyesh snimka svyazyivayet fakticheskiye bajtyi kazhdoj prinyatoj zapisi, poetomu ikh posleduyusjhaya perezapisj obnaruzhivayetsya nezavisimo ot formatirovaniya JSON. Simvolicheskiye ssyilki v leksicheski nablyudayemyikh komponentakh upravlyayemogo puti, neizvestnyiye polya i vyikhod za katalog sessii zakryivayutsya otkazom. Obsjhaya publikacionnaya proverka repozitoriya otdeljno otklonyayet mashinno-lokaljnyiye puti v publikuyemyikh fajlakh.

## Zakryityij snimok

Sessiya toljko s istoricheskimi v1/v2-zapisyami poluchayet `снимок.json` skhemyi `fum.test-run-report.v1` i rovno tri verkhneurovnevyikh polya:

- `схема` — tochnaya stroka `fum.test-run-report.v1`;
- `сессия` — tot zhe repo-relative putj k `запрос.md`;
- `файлы` — massiv obyyektov `{ "имя": "<порядок>_<uuid>.json", "sha256": "<64hex>" }` v tochnom chislovom poryadke zapuskov.

Khyesh `файлы[].sha256` vyichislyayetsya po fakticheskim proverennyim bajtam sootvetstvuyusjhego JSON-fajla i zapisyivayetsya bez prefiksa. Sam `снимок.json` serializuyetsya kanonicheskim sposobom. SHA-256 yego polnyikh bajtov v Markdown-marker zapisyivayetsya uzhe s obyazateljnyim prefiksom `sha256:`. `снимок.json` ne vklyuchayet sam sebya v `файлы`.

Sessiya s v3 poluchayet snimok `fum.test-run-report.v2`: k tem zhe polyam dobavlyayetsya `отпечаток_закрытия`. On vyichislyayetsya v moment zakryitiya po toj zhe Git-granice i khyeshirovanno fiksiruyet fakticheskij verdikt plana. Drift posle finaljnogo zapuska renderitsya kak `не готов`, a posleduyusjhaya strukturnaya proverka stroit te zhe bajtyi iz sokhranyonnogo otpechatka, ne zavisya ot budusjhego sostoyaniya rabochego dereva.

Zakryitaya proverka trebuyet tochnogo ravenstva otsortirovannogo inventarya fakticheskim obyichnyim JSON-fajlam zapuskov. Perestanovka elementov, povtor, lishnyaya ili ischeznuvshaya zapisj, izmeneniye bajta, podmena sostoyaniya, neizvestnyij fajl, vremennyij ostatok, simvolicheskaya ssyilka, nekanonicheskiye bajtyi snimka i nesovpadayusjhij khyesh yavlyayutsya oshibkoj. Snimok s khotya byi odnoj zapisjyu `выполняется` ne sozdayotsya. Posle dolgovechnoj ustanovki snimka i do zamenyi Markdown mozhet nablyudatjsya podgotovlennaya faza `снимок.json` vmeste s otkryityim marker: ona blokiruyet novyiye zapuski i predprosmotr, ne prinimayetsya strogoj proverkoj i zavershayetsya toljko povtorom `закрыть`.

## Zhurnal vozobnovleniya

Pered pervoj mutaciyej zakryitogo sostoyaniya komanda `возобновить` dolgovechno sozdayot kanonicheskij `возобновление.json`. Istoricheskij snimok v1 poluchayet skhemu `возобновление-отчёта-проверок.1` s zakryityim naborom polej `схема`, `сессия`, `хэш_закрытого_отчёта`, `хэш_открытого_отчёта` i `хэш_снимка`; dlya profilirovannogo snimka skhema `возобновление-отчёта-проверок.2` dopolniteljno sokhranyayet `отпечаток_закрытия`. Kazhdyij khyesh yavlyayetsya lowercase SHA-256 bez prefiksa. Zhurnal ne vkhodit v snimok zapuskov i blokiruyet `запустить`, `предпросмотр`, `проверить-план`, `проверить` i `закрыть`.

Povtor `возобновить` strogo sveryayet kanonicheskiye bajtyi zhurnala, tekusjhiye zapisi i dopustimuyu zakryituyu libo otkryituyu proyekciyu, zatem determinirovanno prodolzhayet perekhod iz faz `закрытый отчёт + снимок`, `открытый отчёт + снимок` ili `открытый отчёт без снимка`. Zhurnal udalyayetsya i katalog sinkhroniziruyetsya toljko posle dolgovechnogo otkryitogo otchyota i podtverzhdyonnogo otsutstviya snimka. Povrezhdyonnyij zhurnal ne yavlyayetsya razresheniyem na vosstanovleniye.

## Otkryityij i zakryityij Markdown-blok

V novom `отчёт.md` susjhestvuyet rovno odna aktivnaya para marker-strok. Poka sbor otkryit, nachalo i konec imeyut tochnyij vid:

```markdown
<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->
...
<!-- FUM-CHECK-RUNS:END -->
```

Posle zakryitiya pervaya stroka zamenyayetsya na:

```markdown
<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:<64hex> -->
```

Konechnaya stroka ostayotsya `<!-- FUM-CHECK-RUNS:END -->`. Vo vsyom otchyote dopuskayetsya rovno odna tochnaya para: otsutstvuyusjhaya, povtornaya, vlozhennaya, perestavlennaya ili sintaksicheski rasshirennaya para otklonyayetsya bez zapisi. Poetomu doslovnyij tekst, fenced-blok i drugoj razdel otchyota ne dolzhnyi dublirovatj upravlyayusjhiye marker-stroki.

Gotovoye otkryitoye sostoyaniye oznachayet otsutstviye `снимок.json` i `возобновление.json`. Ono dopustimo vo vremya vyipolneniya tochnoj aktivnoj rabochej sessii, v tom chisle kogda smoke-check vidit sobstvennuyu yesjhyo vyipolnyayusjhuyusya verkhneurovnevuyu zapisj. Ono ne yavlyayetsya gotovyim otchyotom dlya kommita. Podgotovlennyiye fazyi zakryitiya i vozobnovleniya takzhe ne yavlyayutsya gotovyimi sostoyaniyami. Zakryitoye sostoyaniye trebuyet susjhestvuyusjhij snimok, otsutstviye zhurnala vozobnovleniya, tochnyij marker-khyesh kanonicheskikh bajtov snimka i pobajtovoye sovpadeniye soderzhimogo mezhdu marker-strokami s zanovo postroyennyim predstavleniyem.

Rabochij predprosmotr mozhet ostavatjsya otkryityim mezhdu vyizovami. Takoye promezhutochnoye sostoyaniye ne prinimayetsya komandoj `проверить` bez aktivnoj zapisi i ne mozhet byitj zafiksirovano kak gotovyij otchyot. Vo vremya aktivnogo vyizova predprosmotr pokazyivayet tekhnicheskiye `0,000 с` i `не завершено — нет итоговой записи`; eto znacheniye ne vkhodit v summu i zamenyayetsya nablyudyonnoj dliteljnostjyu do zakryitiya.

## Determinirovannoye Markdown-predstavleniye

Upravlyayemyij blok soderzhit tablicu s tochnyimi kolonkami `Вызов | Длительность | Результат` i stroku `Общее время прямых запусков проверок: <N> с.`. Stroki sleduyut chislovomu `порядок`; povtoryayusjhiyesya znacheniya sokhranyayutsya kak otdeljnyiye stroki.

Pervaya yachejka stroitsya kak `[<исполнитель>] <вызов>`. Vtoraya poluchayetsya toljko iz `длительность_наносекунды`: znacheniye okruglyayetsya do celyikh millisekund po pravilu round-half-up, zatem otobrazhayetsya v sekundakh s zapyatoj kak desyatichnyim razdelitelem i ne boleye chem tremya znakami bez bessmyislennyikh konechnyikh nulej. Naprimer, `1 499 999` ns dayut `0,001 с`, a `1 500 000` ns — `0,002 с`.

Tretjya yachejka nachinayetsya s tochnogo `статус`; nepustoye bezopasnoye poyasneniye dobavlyayetsya cherez tire kak `<статус> — <пояснение>`. Nablyudyonnyij `код_завершения` ostayotsya mashinnyim polem i ne dubliruyetsya v chelovekochitayemoj yachejke. Razdeliteli Markdown v poljzovateljskikh yachejkakh ekraniruyutsya, perevodyi strok ne dopuskayutsya, a shirina kolonok i stroki razdelitelya vyiravnivayetsya probelami v stile Obsidian.

Obsjheye vremya vyichislyayetsya kak summa uzhe okruglyonnyikh do millisekund otobrazhayemyikh znachenij strok, a ne kak otdeljnoye okrugleniye summyi iskhodnyikh nanosekund. Poetomu chislo v itogovoj stroke vsegda arifmeticheski ravno vidimoj tablice i nezavisimo proveryayetsya `fum-svyaznostj-rabochej-sessii`. Render ne ispoljzuyet tekusjheye vremya, poryadok obkhoda katalogov, locale ili skryituyu sredu: odinakovyiye kanonicheskiye zapisi dayut odinakovyiye bajtyi bloka i snimka.

Dlya v3 blok posle itogovoj stroki pokazyivayet vyichislennoye sostoyaniye ekonomnogo poryadka. Kazhdoye perekryitiye rannego diagnosticheskogo libo polnogo okhvata s naborami finaljnogo smoke-check na tom zhe otpechatke renderitsya otdeljno vmeste s razreshyonnostjyu, dliteljnostjyu, iskhodom, naborami i osnovaniyem. Diagnostika, dejstviteljno ne pokryivayemaya finaljnyim smoke, pokazyivayetsya otdeljno i ne nazyivayetsya dublem. `нормативный_контур` perechislyayet obyazateljnyiye stadii protokola `manual-sequential-v1`, vklyuchaya odin lokaljnyij kommit na `master` i zaversheniye bez continuation; fakticheskaya gotovnostj vyivoditsya toljko iz zakryityikh mashinnyikh uslovij, a ne iz svobodnoj metki vyizova.

## Paralleljnyiye processyi i fajlovaya granica

Korotkij mezhprocessnyij fajlovyij zamok serializuyet soglasovannyiye chteniya kataloga, naznacheniye sleduyusjhego poryadka, atomarnuyu ustanovku nachaljnoj zapisi, terminaljnuyu zamenu, predprosmotr, `проверить-план`, proverku, `закрыть` i `возобновить`. Sam proverochnyij process ne uderzhivayet globaljnyij zamok, poetomu nezavisimyiye ispolniteli rabotayut paralleljno i obnovlyayut toljko sobstvennyiye JSON-fajlyi. Operacionnaya sistema osvobozhdayet zamok pri zavershenii vladeljca; tajmer, TTL i evristicheskoye snyatiye ne ispoljzuyutsya.

`закрыть` snachala poluchayet zamok, zapresjhayet novyiye startyi, perechityivayet vesj katalog, otklonyayet aktivnyiye ili nekanonicheskiye zapisi i stroit budusjhiye bajtyi v pamyati. Zatem ono dolgovechno ustanavlivayet `снимок.json` i toljko posle etogo atomarno zamenyayet upravlyayemyij blok `отчёт.md`. Sboj vtorogo shaga ostavlyayet obnaruzhimuyu zakryituyu otkazom podgotovlennuyu fazu; povtor `закрыть` sveryayet snimok s neizmennyimi zapisyami i zavershayet Markdown. Povtor uspeshnogo `закрыть` s neizmennyimi vkhodami yavlyayetsya pobajtovyim no-op.

`возобновить` ne yavlyayetsya sposobom obojti oshibku. Pervyij vyizov dopuskayetsya toljko pri polnostjyu korrektnom zakryitom snimke, sovpadayusjhem marker-khyeshe, tochnom Markdown i otsutstvii aktivnyikh zapisej. Gotovyij v3-snimok ne otkryivayetsya, chtobyi prezhnij uspeshnyij finaljnyij smoke ne delal prodolzheniye zavedomo negotovyim; istoricheskij snimok s v2 tozhe ne otkryivayetsya iz-za zapreta smeshannoj istorii. Komanda pod zamkom snachala stavit zhurnal vosstanovleniya, perevodit marker v `состояние=открыт`, zatem udalyayet i sinkhroniziruyet snimok, a zhurnal vosstanovleniya udalyayet poslednim. Prezhniye zapisi ne udalyayutsya; sleduyusjhij poryadok prodolzhayet susjhestvuyusjhuyu posledovateljnostj. Posle nablyudayemogo sboya povtor razreshyon toljko cherez strogo proverennyij zhurnal, a ostaljnyiye dejstviya ostayutsya zakryityimi.

## Zapusk processa, neuspekhi i signalyi

Peredannaya komanda zapuskayetsya kak tochnyij massiv argumentov s `shell=False`. Standartnyiye potoki vyivoda i oshibok nasleduyutsya, poetomu chelovek i vyizyivayusjhij instrument vidyat iskhodnyij vyivod bez zaderzhki. Avtomatizaciya ne sokhranyayet stdout, stderr, polnuyu sredu, sekretyi, hostname ili PID v publikuyemom mashinnom zhurnale i ne pyitayetsya izvlekatj status iz nedoverennogo teksta testovogo frejmvorka.

Dochernij process poluchayet otdeljnuyu gruppu processov, identifikator kotoroj sokhranyayetsya nezavisimo ot zhiznennogo cikla lidera. Nulevoj kod dayot status `успешно`, nenulevoj — `неуспешно`; nevozmozhnostj zapuska poluchayet `не завершено`, bezopasnoye poyasneniye i nablyudayemyij sovmestimyij kod. Yestestvennoye zaversheniye signalom ili signal, poluchennyij obyortkoj i peredannyij vsej gruppe, fiksiruyetsya kak `прервано`. Pri dostizhenii tajm-auta avtomatizaciya posyilayet sokhranyonnoj gruppe `SIGTERM`, zhdyot fiksirovannyij korotkij period, pri neobkhodimosti posyilayet `SIGKILL` i v ogranichennyij srok trebuyet podtverzhdeniya ischeznoveniya PGID. Process, namerenno pokinuvshij etu gruppu, takoj ochistkoj ne okhvatyivayetsya.

Dliteljnostj izmeryayetsya monotonnyim tajmerom ot neposredstvennoj popyitki zapuska do nablyudyonnogo zaversheniya i uborki gruppyi. Absolyutnoye znacheniye monotonnyikh chasov v JSON ne sokhranyayetsya. `SIGINT` i `SIGTERM` blokiruyutsya vokrug ustanovki nachaljnoj i terminaljnoj zapisi; iskhodnaya maska vosstanavlivayetsya v dochernem processe pered `exec`. Terminaljnaya atomarnaya zapisj yavlyayetsya tochkoj linearizacii: toljko uzhe uchtyonnyiye ozhidayusjhiye signalyi poglosjhayutsya, a novyij signal posle neyo peredayotsya prezhnemu obrabotchiku. Neobrabatyivayemyij `SIGKILL`, avariya sredyi vyipolneniya, mashinyi ili fajlovoj sistemyi mogut ostavitj sostoyaniye `выполняется`; takoye sostoyaniye yavlyayetsya nablyudayemyim otkazom i blokiruyet zakryitiye. V terminaljnuyu zapisj avtomatizaciya ne podstavlyayet `0 с`, vremya obnaruzheniya ili ocenku zadnim chislom.

## Integraciya s smoke-check i zaversheniyem sessii

Katalog `tests` etoj avtomatizacii yavno vkhodit v polozhiteljnyij perechenj standartnogo smoke-check i avtomaticheski obnaruzhivayetsya polnyim profilem. Dopolniteljnyij read-only shag `проверить` strogo sveryayet snimok peredannogo zaprosa, a etot zapros dopuskayet v otkryitom sostoyanii toljko pri nalichii aktivnoj zapisi, chtobyi obyornutyij predfinaljnyij smoke-check ne potreboval sobstvennogo rezuljtata do zaversheniya. Otkryitaya proverka ne vyidayotsya za gotovnostj k kommitu, a strukturno korrektnyij zakryityij snimok mozhet chestno khranitj verdikt `не готов`; terminaljnuyu gotovnostj otdeljno dokazyivayet `проверить-план` do zakryitiya. Toljko polnostjyu zakryityiye istoricheskiye v2- i profilirovannyiye v3-nablyudeniya mogut statj vkhodom analiticheskogo poryadka yavnogo polnogo profilya; standartnyij profilj istoriyu ne chitayet.

Kornevoj ispolnitelj pered zakryitiyem dozhidayetsya vsekh read-only-subagentov, zavershayet soderzhateljnyiye izmeneniya, generatoryi, recency i svyaznostj, zatem indeksiruyet vse soderzhateljnyiye puti. Predfinaljnyij standartnyij smoke-check dokumentacionnogo prototipa yavlyayetsya yedinstvennoj poslednej zapisyivayemoj strokoj okhvachennoj granicyi i poluchayet klass `полная`, yesli otdeljnoye trebovaniye ne vyibralo vmesto nego polnyij profilj. Srazu posle uspekha korenj read-only-komandoj vyizyivayet `проверить-план`, zatem `закрыть`. Posle zakryitiya razreshyon rovno odin shtatnyij `применить` bratislavskoj proyekcii, za nim rovno odin pryamoj nezavisimyij `проверить-манифест` i tochnaya postanovka `Proyekcii/**` v indeks. Zatem vyipolnyayutsya toljko proverki zamyikaniya izmenivshegosya otchyota i pokoleniya: strogaya proverka snimka, svyaznostj rabochej sessii, recency bez zapisi i `git diff --check`. Eti vyizovyi nakhodyatsya vne zakryitoj granicyi i ne porozhdayut rekursivnyij smoke-check. Lyuboye izmeneniye kanonicheskogo puti posle zakryitiya vozvrasjhayet sessiyu do granicyi finaljnogo smoke i trebuyet novogo profilirovannogo cikla. Zatem ruchnaya pishusjhaya sessiya sozdayot odin itogovyij lokaljnyij kommit na `refs/heads/master` i zavershayetsya bez continuation.

## Proverki avtomatizacii

Avtonomnyij nabor rabotayet bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-otchyotyi-o-zapuskakh-proverok/tests \
  -p 'test_*.py'
```

TDD-nabor zakreplyayet uspekh, nenulevoj kod, oshibku zapuska, yestestvennyij i otlozhennyij signal, tajm-aut i ochistku zhivogo potomka posle vyikhoda lidera, otsutstviye utechki argumentov i vyivoda, paralleljnoye naznacheniye poryadka, strogiye skhemyi snimka i zhurnala vozobnovleniya, podgotovlennyiye fazyi i povtor posle fajlovogo sboya, soglasovannoye chteniye pod zamkom, paryi status–kod, obyazateljnyij konvert smoke-check lyubogo profilya, tochnoye raspoznavaniye komandyi, vstraivaniye strukturirovannyikh nablyudenij, dopustimyij rannij otkaz s nepustyim planom i pustyimi nablyudeniyami i otkaz pri narushenii analiticheskogo plana. V3-fiksturyi dopolniteljno zakreplyayut obyazateljnyij profilj, avtomaticheskij Git-otpechatok, razdeljnoye isklyucheniye staged-, unstaged- i untracked-sostoyaniya tochnoj oblasti `Proyekcii/**` pri sokhranenii blizkikh imyon v snimke, tri klassa, diagnosticheskuyu svyazj s tochnyim otkazom, otobrazheniye dublej, yedinstvennyij poslednij uspeshnyij smoke, zapret pozdnego khvosta, `проверить-план`, snimok report-v2 i nevozmozhnostj vozobnovitj gotovyij v3. Nabor takzhe fiksiruyet Unicode-razdeliteli, tochnyij LF v Markdown, ekranirovaniye, round-half-up, summu otobrazhayemyikh znachenij, Obsidian-vyiravnivaniye, idempotentnoye zakryitiye, sokhrannostj teksta vne marker-paryi i sovmestimostj s `fum-svyaznostj-rabochej-sessii`.

## Granica avtomatizacii

Mashinnyij zhurnal dokazyivayet polnotu toljko tekh pryamyikh vyizovov, kotoryiye dejstviteljno provedenyi cherez komandu `запустить`. Pravilo rabochej sessii dolzhno trebovatj etu obyortku ot kornya i subagentov v okhvachennoj granice; avtomatizaciya ne mozhet obnaruzhitj process, namerenno zapusjhennyij v obkhod neyo. Ona takzhe ne ocenivayet smyisl testa, ne razbirayet frejmvork-zavisimyiye schyotchiki, ne sokhranyayet syiroj vyivod, ne zamenyayet publikacionnuyu proverku tochnoj komandyi i ne skladyivayet vnutrenniye shagi sostavnogo processa kak nezavisimyiye zapuski.

Leksicheskaya proverka simvolicheskikh ssyilok ne ustranyayet vrazhdebnuyu TOCTOU-podmenu predka mezhdu proverkoj puti i fajlovoj operaciyej; polnaya zasjhita potrebovala byi privyazannyikh k `dirfd` operacij s `O_NOFOLLOW`. Chislovoj PGID teoreticheski mozhet byitj pereispoljzovan, a process mozhet namerenno pokinutj gruppu. Postoyannyij odnovremennyij otkaz vsekh vosstanoviteljnyikh fajlovyikh operacij ne pozvolyayet obesjhatj avtomaticheskoye zaversheniye perekhoda; standartnyiye odinakovyiye POSIX-signalyi mogut obyyedinyatjsya yadrom. Khyeshi obnaruzhivayut nesoglasovannuyu podmenu, no ne zasjhisjhayut ot subyyekta, sposobnogo soglasovanno perepisatj vse lokaljnyiye fajlyi.

## Istochnik trebovanij

- [iskhodnyij zapros 2026-08-14 18:59:37 MSK — Isklyuchitj dublirovaniye polnoj regressii](../../Zhurnal/2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros realizacii FUM-STEP-0129](../../Zhurnal/2026-09-01_11-19-59_MSK_realizovatj-bratislavskuyu-proyekciyu-pamyati/zapros.md)

- [iskhodnyij zapros 2026-08-06 20:56:43 MSK — Optimizirovatj rabotu testov](../../Zhurnal/2026-08-06_20-56-43_MSK_optimizirovatj-rabotu-testov/zapros.md)
- [iskhodnyij zapros 2026-08-06 11:22:33 MSK - Dobavitj analitiku poryadka zapuska testov](../../Zhurnal/2026-08-06_11-22-33_MSK_dobavitj-analitiku-poryadka-zapuska-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 20:45:26 MSK - Formirovatj otchyotyi o zapuskakh testov](../../Zhurnal/2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:2c3da009899779bce109833fe858c61395a48fb920bdcb0018c0761ecfa9332a -->
<!-- FUM-MD-RECENCY:END -->
