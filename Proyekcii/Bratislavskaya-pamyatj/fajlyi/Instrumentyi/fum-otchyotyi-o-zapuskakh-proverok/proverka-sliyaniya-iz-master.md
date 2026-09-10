# Proverka sliyaniya iz master

Etot rezhim obsluzhivayet yavno razreshyonnoye sliyaniye po `AGENTS.md`. Pervichnyij master M predostavlyayet pravila, proverochnyiye instrumentyi, testyi, fiksturyi i zavisimosti. Kandidat proveryayetsya kak vkhod v otdeljnom rabochem dereve na predkommitnoj osnove L s `MERGE_HEAD=M`. Posle sokhraneniya proveryayetsya tot zhe kommit C s roditelyami `[L, M]` i derevom T. Komandyi nizhe ne razreshayut sozdavatj dopolniteljnyiye pishusjhiye zadachi ili publikovatj rezuljtat.

## Podgotovka

Snachala proveryayusjhij kontur prinimayetsya kommitom v master. V kandidate gotovitsya sliyaniye s etim tochnyim M. Izmeneniye M trebuyet obnovitj kandidat i povtoritj priyomku. Arkhiviruyemaya Swift-obyortka, vlozhennyiye instrumentyi svezhesti i proyektnyikh fajlov i materializovannyij LinguisticKit sveryayutsya s M. Ostaljnaya predlagayemaya realizaciya peredayotsya testam otdeljno; testyi i shablonyi ostayutsya iz M.

V primerakh ispoljzuyutsya zaraneye zadannyiye peremennyiye: `fum_source` i `fum_candidate` — raznyiye fizicheskiye absolyutnyiye korni M i kandidata; `fum_python` — absolyutnyij putj tekusjhego Python; `fum_message` — absolyutnyij fajl soobsjheniya kommita. `fum_request` — otnositeljnyij putj `Журнал/<stem>/запрос.md`, `fum_witness` — sosednij `Журнал/<stem>/материалы/контур-слияния.json`. `fum_M`, `fum_L`, pozdneye `fum_C` i `fum_T` soderzhat polnyiye OID. `fum_thread` — UUID zadachi Codex, a `fum_run` — novyij UUID imenno polnogo zapuska. `fum_pycache` — otdeljnyij pustoj vremennyij katalog vne repozitoriya dlya vneshnikh vkhodov Python; posle komand on ostayotsya pustyim.

Posle podgotovki obyichnogo zaprosa i otchyota sformirujte svideteljstvo. Generator toljko proveryayet sostoyaniye i vyidayot kanonicheskiye bajtyi v stdout; snachala sokhranite uspeshnyij vyivod vo vremennyij fajl, zatem perenesite v `fum_witness` i dobavjte yego vmeste s kanonicheskimi izmeneniyami v indeks kandidata. Oshibka generatora ne dolzhna obnulyatj prezhneye svideteljstvo.

```bash
"$fum_python" -E -B -X "pycache_prefix=$fum_pycache" \
  "$fum_source/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/контур_слияния.py" \
  --корень-кандидата "$fum_candidate" --источник "$fum_M" --ведущая-основа "$fum_L" \
  --запрос "$fum_request" --идентификатор-запуска "$fum_run"
```

Svideteljstvo dolzhno byitj obyichnyim fajlom `100644` s odinakovyimi bajtami v rabochem dereve i indekse. Ono vkhodit v otpechatok polnogo zapuska i ne menyayetsya posle nego. V otlichiye ot snimka zapuskov, ono nakhoditsya vne kataloga `материалы/запуски-проверок/`.

## Polnyij zapusk

```bash
"$fum_python" -E -B -X "pycache_prefix=$fum_pycache" \
  "$fum_source/Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py" \
  запустить --корень-репозитория "$fum_candidate" --запрос "$fum_request" \
  --название 'Проверить кандидат слияния' --исполнитель 'Корневая задача' \
  --класс-проверки полная --идентификатор-запуска "$fum_run" -- \
  "$fum_python" -B "$fum_source/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py" \
  --repo-root "$fum_candidate" --request "$fum_request" \
  --commit-message-file "$fum_message" --codex-thread-id "$fum_thread" \
  --источник-проверок "$fum_M" --ведущая-основа "$fum_L" --свидетельство-контура "$fum_witness"
```

Vse tri parametra proiskhozhdeniya obyazateljnyi vmeste. Rezhim ispoljzuyet standartnyij dokumentacionnyij plan, ne dopuskayet `--list`, `--skip-session-coherence`, polnyij Swift-profilj ili proizvoljnuyu politiku kandidata. Vneshnyaya `FUM_CHECKED_CODE_ROOT` etot rezhim ne vklyuchayet. Obyortka i smoke sveryayut kontur do i posle ispolneniya; upravlyayut sredoj Git/Python i otdeljnyim pustyim prefiksom kyesha. Skhema zapisi ostayotsya `fum.test-run.v3`. Obyortka podtverzhdayet fakticheskoye ispolneniye metkoj `fum.контур-проверки-слияния.1:sha256:<хэш>` v pole polnoj zapisi `ожидаемое_свидетельство`: khyesh otnositsya k kanonicheskim bajtam podgotovlennogo svideteljstva. Metku neljzya peredatj cherez CLI/API; ona vyidayotsya toljko pri okonchateljnom uspekhe. Obyichnyij polnyij zapusk ostavlyayet `null`, dazhe pri nalichii podgotovlennogo fajla s praviljnyim UUID.

Posle uspeshnogo finaljnogo zapuska vyipolnyayetsya obyichnoye zakryitiye otchyota, finaljnaya peresborka proyekcii, proverka zamyikaniya i fiksaciya C po pravilam etapa. Svideteljstvo ne perepisyivayetsya. Sam uspekh dochernego processa yesjhyo ne yavlyayetsya priyomkoj kommita.

## Proverka sokhranyonnogo rezuljtata

```bash
"$fum_python" -E -B -X "pycache_prefix=$fum_pycache" \
  "$fum_source/Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/закрытый_отчёт_из_гита.py" \
  --корень-репозитория "$fum_candidate" --коммит "$fum_C" --запрос "$fum_request" \
  --допуск-слияния --база "$fum_L" --присоединяемый "$fum_M" --дерево "$fum_T"
```

Chitatelj beryot zakryityij otchyot i svideteljstvo iz C, politiku i yeyo proiskhozhdeniye iz M. On trebuyet podtverzhdeniye ispolneniya s sovpadayusjhim khyeshem v finaljnoj zapisi i sveryayet UUID s poslednim uspeshnyim polnyim zapuskom, tochnyiye roditeli i derevo, arkhiviruyemyij paket M/L/C i gitlink M/C. Tekusjhiye fajlyi checkout ne podmenyayut eti Git-obyyektyi. Kod 0 podtverzhdayet etot urovenj dokazateljstva; kod 2 oznachayet nesovpadeniye rekonstruirovannogo otpechatka, kod 1 — narusheniye preduslovij. Nizkij rezhim `--слияние` proiskhozhdeniye proverok ne proveryayet.

Chitatelj ne prodvigayet master i ne zakryivayet smyislovoye obyazateljstvo poljzovatelya. Prodvizheniye do togo zhe proverennogo C otdeljno trebuyet ozhidayemogo prezhnego M i soglasovannogo sostoyaniya pervichnogo checkout i indeksa. [Otchyot realizacii i profilj](../../Zhurnal/2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/otchyot.md) sokhranyayut granicyi tekusjhej proverki.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 19:46:01 MSK -->
<!-- content-sha256: sha256:e5e5da31622276e1f9aa24f07945e8ce39715f02eef8150e13a465e18d1133ee -->
<!-- FUM-MD-RECENCY:END -->
