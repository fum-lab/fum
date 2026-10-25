# Ispolneniye operatora v FUMA

Osnovnoj binarnik FUMA prinimayet yavnoye opredeleniye strukturiruyusjhego operatora i vkhodnoj fajl, vyizyivayet susjhestvuyusjhij Swift-interpretator v svoyom processe i sokhranyayet nablyudeniye v nakopiteljnuyu pamyatj. Komandnyij rezhim zavershayetsya do sozdaniya scenyi i obrabotki razreshenij. Vyizov ne zapuskayet pomosjhnika ili IPC.

## Pervyij scenarij: UTF-8 → UTF-32LE

Sokhranyonnoye [trebovaniye FUM-REQ-0067](../../../../Trebovaniya/🟡-chistoye-ispolneniye-operatorov-i-UTF-32.md) zadayot pervyij predmetnyij scenarij: iskhodnyiye bajtyi UTF-8 → Unicode-skalyaryi → UTF-32 s yavnyim poryadkom bajtov. Nizhe vyipolnyayetsya yego variant UTF-32LE bez normalizacii i BOM. Potokovaya obrabotka porciyami etim konechnyim vyizovom ne podtverzhdayetsya.

Nuzhnyi zavisimosti i sborka iz [rukovodstva prilozheniya](../README.md#zavisimosti-i-sborka): macOS s Xcode/Swift 6, sistemnyiye mpv i pkg-config. Obe lokaljnyiye biblioteki vkhodyat v chistyij klon FUM; otdeljnyiye repozitorii sobstvennogo koda ne nuzhnyi. SwiftPM ispoljzuyet paket interpretatora iz `Прототипы/память-структурирующих-операторов` i paket `КонтейнерНаблюдений` iz `Приложения/FUMA/Packages`.

Komandyi nizhe vyipolnyayutsya iz fizicheskogo kornya FUM. `FUM_BUILD_ROOT` — zaraneye vyibrannyij susjhestvuyusjhij absolyutnyij fizicheskij katalog vne lyubogo Git checkout. Katalog zhurnala dolzhen susjhestvovatj, prinadlezhatj tekusjhemu poljzovatelyu, imetj prava `0700` i ne soderzhatj simvolicheskikh ssyilok v puti. Prilozheniye ne vyibirayet mesto khraneniya avtomaticheski.

```sh
: "${FUM_BUILD_ROOT:?Задайте физический каталог вне Git}"
swift build --package-path Приложения/FUMA/macOS --scratch-path "$FUM_BUILD_ROOT" --jobs 2 --product fum
mkdir -m 700 "$FUM_BUILD_ROOT/наблюдения"
printf '%s' 'Aё🙂' > "$FUM_BUILD_ROOT/вход-UTF-8.txt"
"$FUM_BUILD_ROOT/debug/fum" --выполнить-оператор \
  --определение "$(pwd -P)/Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/Определения/UTF-8-в-UTF-32LE.json" \
  --вход "$FUM_BUILD_ROOT/вход-UTF-8.txt" \
  --тип-входа байты --журнал "$FUM_BUILD_ROOT/наблюдения"
```

V stdout vozvrasjhayetsya JSON `fuma.результат-исполнения.1` s `наблюдение` i `квитанция`. Rezuljtat soderzhit 12 bajtov UTF-32LE: `41 00 00 00 51 04 00 00 42 F6 01 00`, a trassa — tri pravila dekodirovaniya. Kod `0` vozvrasjhayetsya posle podtverzhdyonnogo sokhraneniya i zapisi otveta. V `квитанция.описание.идентификатор` nakhoditsya identifikator dolgovremennoj zapisi.

Povtor ispoljzuyet sokhranyonnyiye prinyatyiye dannyiye; iskhodnyiye fajlyi boljshe ne nuzhnyi. Podstavjte poluchennyij identifikator:

```sh
"$FUM_BUILD_ROOT/debug/fum" --повторить-оператор 'идентификатор-из-квитанции' \
  --журнал "$FUM_BUILD_ROOT/наблюдения"
```

Uspeshnyij povtor sveryayet determinirovannyij khyesh i sozdayot novoye nablyudeniye s novyim identifikatorom i vremenem. Sami prinyatyiye dannyiye i determinirovannyij rezuljtat sokhranyayutsya bez izmeneniya. Raskhozhdeniye pri povtore zavershayetsya otkazom do dobavleniya zapisi.

Dlya Xcode vyipolnite [shtatnuyu sborku FUMA.app](../README.md#zavisimosti-i-sborka). Te zhe argumentyi prinimayet osnovnoj fajl `"$FUM_BUILD_ROOT/xcode/Build/Products/Debug/FUMA.app/Contents/MacOS/FUMA"`. Xcode podklyuchayet obe biblioteki kak lokaljnyiye paketnyiye produktyi, vklyuchaya resursyi interpretatora.

Dopolniteljnyij tekstovyij scenarij ispoljzuyet `Определения/нормализация.json`, vkhod `Приложения/FUMA/macOS/проверки/фикстуры/вход-оператора.txt` i `--тип-входа текст`. Yego rezuljtat — `привет ёж`; na nyom izmeryayetsya profilj nizhe.

## Prinyatyij vkhod i pamyatj

Podderzhivayutsya dva yavnyikh tipa vkhoda: `текст` — strogij UTF-8, `байты` — tochnyiye bajtyi fajla. Opredeleniye razbirayetsya susjhestvuyusjhim `ОпределениеОператора.разобрать`; novaya kopiya dekodera ili interpretatora ne vvoditsya. Dlya bajtovogo scenariya prigodno sokhranyonnoye opredeleniye `UTF-8-в-UTF-32LE.json`. Otdeljnyij vkhod dlya massiva skalyarov ili gotovogo strukturnogo obyyekta v etoj vertikali ne obyyavlen; strukturnyij kontrakt mozhno peredatj tekstom sootvetstvuyusjhemu susjhestvuyusjhemu operatoru.

Payload zapisi `fuma.исполнение-оператора.1` soderzhit:

- `принятыеДанные`: tochnyiye iskhodnyiye bajtyi opredeleniya, yego proverennoye kanonicheskoye predstavleniye, iskhodnyiye bajtyi vkhoda, tip i polnyij profilj predelov;
- `наблюдение`: rezuljtat susjhestvuyusjhego ispolnitelya, identichnostj/versiyu opredeleniya, khyeshi, sledyi shagov, imeyusjhuyusya trassu pravil, chislo propusjhennyikh zapisej i vyipolnennyikh operacij.

Polya `Data` serializovanyi standartnyim JSONEncoder kak Base64. Identifikator i vremya nakhodyatsya v opisanii kontejnera i ne vkhodyat v determinirovannyij payload. Profilj izmerenij takzhe ne vkhodit v nego. Profilj ispolnitelya versii 1 zakreplyayet predelyi: opredeleniye do 65 536 bajtov, vkhod do 262 144 bajtov, rezuljtat do 1 048 576 bajtov, do 16 777 216 operacij i do 256 zapisej trassyi. Izmeneniye profilya trebuyet novoj versii; povtoryi neizvestnogo profilya otklonyayutsya. Povtor Unicode-preobrazovanij predpolagayet sovmestimyij Swift/Foundation runtime; khyesh vyiyavlyayet raskhozhdeniye mezhdu versiyami.

Kontejner dopisyivayet gruppyi v `сегмент.fumobs`, proveryayet prezhnyuyu istoriyu i vozvrasjhayet kvitanciyu toljko posle zapisi i `fsync` fajla i kataloga. Segment ogranichen 256 MiB i 4096 nablyudeniyami; avtomaticheskaya rotaciya ne vklyuchena. Biblioteka uderzhivayet neblokiruyusjhij mezhprocessnyij zamok; zanyatyij zhurnal dayot otkaz. `latest.json` AX-sensora v etom scenarii ne uchastvuyet.

## Otkazyi

Nepodderzhannyij operator, nekorrektnoye opredeleniye/UTF-8, nevernyiye, povtornyiye ili smeshannyiye argumentyi, privatnyij putj vnutri Git i otkaz pamyati dayut kod `2`, pustoj stdout i obyyasneniye v stderr. Flagi `--request-permissions` i `--permission-status` neljzya smeshivatj s ispolneniyem: takoj vyizov otklonyayetsya do obrabotki razreshenij.

Pri oshibke zapisi prezhnij podtverzhdyonnyij prefiks sokhranyayetsya. Posle otkaza sinkhronizacii novaya zapisj mozhet byitj vidima, khotya kvitanciya ne vyidana; otsutstviye otveta ne dokazyivayet otsutstviya zapisi. Ne povtoryajte takoj zapusk vslepuyu. Prochitajte kontejner cherez yego [shtatnyiye instrumentyi](../../Packages/KontejnerNablyudenij/README.md), proverjte istoriyu i vyiberite daljnejsheye dejstviye. Nepolnyij khvost zapresjhayet novoye dobavleniye; CLI ispolneniya ne udalyayet i ne vosstanavlivayet yego avtomaticheski. Apparatnaya garantiya pri otklyuchenii pitaniya etim etapom ne proverena.

Otdeljnaya granica — vyivod otveta v stdout posle podtverzhdyonnogo dolgovremennogo sokhraneniya. Yesli eta zapisj v stdout vyibrasyivayet perekhvatyivayemuyu oshibku, process vozvrasjhayet kod `2`, khotya nablyudeniye uzhe sokhraneno. Otvet mozhet otsutstvovatj ili byitj chastichnyim; metka `сохранение=успешно` otnositsya k pamyati. Otkaz vyivoda ne otkatyivayet zapisj, poetomu slepoj povtor mozhet dobavitj yesjhyo odno nablyudeniye. Idempotentnaya dostavka kvitancii — povtornaya vyidacha togo zhe podtverzhdeniya bez novogo dobavleniya — poka ne realizovana.

## Proverki i profilj

```sh
swift test --package-path Приложения/FUMA/macOS --scratch-path "$FUM_BUILD_ROOT" --jobs 2 --filter ПроверкиИсполнения
python3 -B Приложения/FUMA/macOS/проверки/проверить-исполнение-оператора.py \
  --бинарник "$FUM_BUILD_ROOT/debug/fum" --профиль-выход "$FUM_BUILD_ROOT/профиль-SwiftPM.json"
python3 -B Приложения/FUMA/macOS/проверки/проверить-исполнение-оператора.py \
  --бинарник "$FUM_BUILD_ROOT/xcode/Build/Products/Debug/FUMA.app/Contents/MacOS/FUMA" \
  --профиль-выход "$FUM_BUILD_ROOT/профиль-Xcode.json"
```

Swift-testyi proveryayut nakopleniye, povtor posle udaleniya iskhodnyikh fajlov i inyyekcii ENOSPC/oshibki `fsync`. Scenarij Python zapuskayet nastoyasjhij binarnik posledovateljno, proveryayet tekstovyij i bajtovyij rezuljtat s trassoj, povtoryi oboikh scenariyev posle udaleniya opredeleniya i vkhoda, smeshannyiye flagi razreshenij, oshibki dannyikh, privatnostj kataloga i sokhrannostj nepolnogo khvosta. Bajtovyij povtor sokhranyayet ozhidayemyiye 12 bajtov UTF-32LE, tri zapisi trassyi i determinirovannyij khyesh, sozdayot novyij identifikator i dopisyivayet istoriyu bez izmeneniya prezhnego prefiksa. Obyichnyiye puti prilozheniya namerenno zadanyi nedopustimyimi: obrasjheniye k nim do rannego CLI ne projdyot proverku. Testovyij process ogranichen 15 sekundami; vremennyiye dannyiye udalyayutsya posle proverki. Granica otkaza stdout opisana po poryadku vyizovov; otdeljnaya inyyekciya etogo otkaza v dannom nabore otsutstvuyet.

Flag `--профиль` vyidayot JSON-metki v stderr: vkhod, dekodirovaniye, ispolneniye i sokhraneniye, a takzhe vlozhennyiye etapyi interpretatora i kontejnera. V kazhdoj metke yestj monotonnaya dliteljnostj, iskhod i glubina. Skladyivatj roditeljskiye i vlozhennyiye intervalyi neljzya. Diagnosticheskaya oshibka vyivoda ne zamenyayet osnovnoj iskhod. Pyatj profiljnyikh obrazcov ispoljzuyut odin otkryityij vkhod i nakaplivayutsya posledovateljno; polnyij process vklyuchayet zapusk rantajma, a sborka izmeryayetsya otdeljno. Vyikhod profilya svyazyivayet binarnik i fiksturyi SHA-256.

Eta vertikalj ne vklyuchayet graficheskij Metal-render i daljnejshiye podsistemyi FUMA. Nalichiye sborki i proverok vetki ne oznachayet integracii v `master` ili priyomki vsej FUMA.

## Istochnik

- [Postanovka pervogo integracionnogo etapa](../../../../Zhurnal/2026-09-15_18-29-25_MSK_zakrepitj-vosemj-reshenij-obrabotki/zapros.md#sleduyusjhij-integracionnyij-etap-osnovnogo-rantajma).
- [Zapros i otchyot realizacii](../../../../Zhurnal/2026-09-15_19-04-26_MSK_integrirovatj-ispolneniye-operatora-FUMA/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:53:43 MSK -->
<!-- content-sha256: sha256:17e015de43c55ead557b04ca2494e9370c6a568f7bc2c5ee8a53f906726fd2c6 -->
<!-- FUM-MD-RECENCY:END -->
