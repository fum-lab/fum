# Sravneniye strogogo dekodirovaniya UTF-8

Stend sravnivayet tekusjhij [interpretator strukturiruyusjhikh operatorov](konechnoye-ispolneniye.md) i standartnyij Swift na odinakovyikh bajtakh. On snachala dokazyivayet sovpadeniye rezuljtata, zatem izmeryayet gotovyiye vyizovyi v odnom processe Release. Iskhodnaya realizaciya interpretatora iz kommita `f49eeee3fd80a87cd63391d6606dafa19cd6d2b8` sokhranena bez optimizacii pod sravneniye.

## Vosproizvedeniye

Nuzhnyi macOS 14 ili noveye, ustanovlennyij Swift i Python 3. Komandyi vyipolnyayutsya iz kornya chistogo klona FUM. V primerakh ispoljzuyetsya sistemnyij vremennyij katalog macOS iz `TMPDIR`; obolochka ostanovitsya, yesli on ne zadan. Sborka nakhoditsya vne checkout; otkryityiye vkhodyi i ozhidayemyiye skalyaryi zadanyi literalami v [iskhodnike stenda](Sources/StendDekodirovaniya/Stend.swift). Setevyikh zavisimostej u etogo SwiftPM-paketa net.

```sh
python3 Прототипы/память-структурирующих-операторов/Проверки/сравнить-декодирование.py подготовить --каталог-сборки "${TMPDIR:?}fum-utf8-comparison-build"
python3 Прототипы/память-структурирующих-операторов/Проверки/сравнить-декодирование.py проверить --каталог-сборки "${TMPDIR:?}fum-utf8-comparison-build" --вывод "${TMPDIR:?}fum-utf8-correctness.json"
python3 Прототипы/память-структурирующих-операторов/Проверки/сравнить-декодирование.py измерить --каталог-сборки "${TMPDIR:?}fum-utf8-comparison-build" --вывод "${TMPDIR:?}fum-utf8-comparison.json"
```

Pervaya komanda stroit produkt `СравнениеДекодирования` s `--configuration release` i sokhranyayet khyeshi iskhodnikov i binarnika v kataloge sborki. Sleduyusjhiye komandyi otklonyayut ustarevshuyu sborku. Posle izmeneniya iskhodnikov snova vyipolnite podgotovku. Vyikhodnoj JSON soderzhit vse iskhodnyiye nablyudeniya, statistiku i proiskhozhdeniye; fajl rezuljtata poyavlyayetsya toljko posle uspeshnogo zaversheniya. Diagnostika nevernyikh argumentov i oshibok idyot v stderr s nenulevyim kodom. Sam ispolnyayemyij fajl prinimayet `проверить` ili `измерить`; v sborke Debug rezhim izmereniya zapresjhyon.

Dlya adresnoj proverki stenda:

```sh
swift test --package-path Прототипы/память-структурирующих-операторов --scratch-path "${TMPDIR:?}fum-utf8-comparison-build" --filter ПроверкиСравненияДекодирования
```

## Chto sravnivayetsya

Oba puti otdeljno materializuyut polnyij `[UInt32]`, zatem v drugom sravnenii — polnyij `[UInt32]` i bajtyi UTF-32LE. Massiv skalyarov sam po sebe ne imeyet poryadka bajtov. Upakovka yavno vyidayot chetyire bajta na skalyar, mladshij pervyim; BOM ne dobavlyayetsya, imeyusjhijsya U+FEFF sokhranyayetsya. Normalizacii Unicode i podschyota grafem net.

Standartnyij putj vyizyivayet `transcode(_:from:to:stoppingOnError:into:)` iz `Unicode.UTF8` v `Unicode.UTF32`, s `stoppingOnError: true`. Vozvrasjhyonnoye `true` oznachayet oshibku; nakoplennyij prefiks otbrasyivayetsya, naruzhu vozvrasjhayetsya `nil`. Etot kontrakt proveren po ustanovlennomu Swift.swiftinterface i pervichnomu iskhodniku Swift. Ispravlyayusjhij nevernyij vvod `String(decoding:as:)` ne ispoljzuyetsya. Standartnyij massiv skalyarov rastyot cherez `append`, bez predvariteljnogo znaniya chisla skalyarov; upakovka rezerviruyet rovno chetyire bajta na skalyar. Takoj zhe vyibor rezervirovaniya ispoljzuyet tekusjhij interpretator.

JSON opredeleniya zagruzhayetsya i razbirayetsya do serij. Dlya granicyi skalyarov zaraneye udalyayetsya poslednij obsjhij shag upakovki; sami pravila dekodirovaniya sovpadayut. `AutomationExecutor.выполнить` pri kazhdom vyizove vsyo ravno proveryayet opredeleniye i predelyi, schitayet operacii, materializuyet trassu i vyichislyayet khyeshi, vklyuchaya JSON nablyudeniya. Variant skalyarov takzhe vyipolnyayet vnutrennyuyu bajtovuyu serializaciyu radi khyeshej. Poetomu otnosheniye vremyon opisyivayet stoimostj dostupnyikh API pri ravnyikh poleznyikh rezuljtatakh. Ono ne izmeryayet chistuyu stoimostj dvukh algoritmov dekodirovaniya.

Osnovnyiye ryadyi vyizyivayut interpretator bez callback profilya s obyichnyim limitom 256 sobyitij trassyi. Yesjhyo tri diagnosticheskikh vyizova dlya kazhdoj granicyi zapisyivayut shtatnyiye intervalyi `проверка`, `исполнение`, `трасса` i vremya polnogo vyizova. Oni isklyuchenyi iz osnovnyikh ryadov. Interval `исполнение` vklyuchayet obsjhij mekhanizm pravil, schyotchiki i upakovku, a trassa vyichitayetsya vnutrennimi metkami; eto tozhe ne chistyij dekoder. Polnyij interval i vlozhennyiye metki neljzya skladyivatj.

## Korpus i metod izmereniya

Chetyire povtoryayemyikh obrazca: ASCII `Az \n`; kirillica `Ёж ёж.`; smesj `Aё€🙂`; dekompozirovannoye `e` + U+0301 + NUL + U+FEFF + 🙂. Kazhdyij povtoryayetsya celikom do blizhajshego chisla bajtov, ne prevyishayusjhego 4096, 32768 i 262144. Mnogobajtovyiye posledovateljnosti ne obrezayutsya. V otchyote sokhranenyi fakticheskoye chislo bajtov, skalyarov, vyikhodnyikh bajtov i khyeshi vkhoda i ozhidayemogo vyikhoda. Predel ispolnitelya — 262144 bajta vkhoda i 1048576 bajt rezuljtata.

Do zamerov proveryayutsya 46 polozhiteljnyikh sochetanij: 12 vkhodov korpusa i 11 korotkikh granichnyikh vektorov v dvukh rezhimakh. Skalyaryi zadanyi nezavisimo ot oboikh dekoderov; ozhidayemyiye bajtyi poluchenyi otdeljnoj arifmeticheskoj upakovkoj. Yesjhyo 14 sochetanij proveryayut otkaz na nevernom UTF-8. Oni sokhranyayut kod i poziciyu oshibki interpretatora otdeljno ot standartnogo `nil`. Vremya oshibok ne sravnivayetsya: diagnosticheskiye kontraktyi razlichayutsya.

Dlya kazhdogo puti — tri progrevochnyikh vyizova, odinochnaya proba i kalibrovochnyij paket. Po kalibrovke vyibirayetsya 1–10000 povtorov s celjyu okolo 20 ms summarnogo vremeni vyizovov. Zatem vyipolnyayutsya devyatj par paketov; poryadok putej chereduyetsya i zavisit takzhe ot nomera korpusa i granicyi rezuljtata. Krupnyij yedinichnyij vyizov mozhet prevyishatj celj paketa. Publikuyutsya mediana, minimum, maksimum i mediannoye absolyutnoye otkloneniye srednikh vremyon paketov. Propusknaya sposobnostj v desyatichnyikh MB/s rasschitana po vkhodnyim bajtam.

Kazhdyij vyizov okruzhyon monotonnyimi tajmerami `DispatchTime`. Polnaya kontroljnaya summa vsekh skalyarov i vyikhodnyikh bajtov proveryayetsya posle vtorogo tajmera, rezuljtat zatem osvobozhdayetsya. `autoreleasepool` ogranichivayet nakopleniye vremennyikh obyyektov. V osnovnyikh funkciyakh i potrebitele stoit `@inline(never)`. Dva chteniya chasov i vyizov obyortki vkhodyat v nablyudayemuyu stoimostj; otdeljnoye polnoye vremya paketa vklyuchayet kontroljnuyu summu i osvobozhdeniye. Massivyi otdeljnyikh rezuljtatov mezhdu povtorami ne uderzhivayutsya. Kalibrovki i syiryiye paketyi sokhranenyi, povtornyiye processyi na kazhdyij vyizov ne sozdayutsya.

Process ne zakreplyayetsya za yadrom, chastota CPU ne fiksiruyetsya. Progon otrazhayet konkretnyij khost i yego nagruzku; on ne dokazyivayet sootnosheniya na drugikh processorakh ili kholodnom kyeshe. Vstroyennyij profilj ne optimiziruyetsya po rezuljtatu etogo sravneniya.

## Zafiksirovannyij progon

Apple M1 Max, 10 logicheskikh processorov, 64 GiB pamyati, macOS 27.0 (26A5425a), Apple Swift 6.4, sborka Release. Posle uspeshnoj proverki gotovogo binarnika vyipolnena odna seriya v soglasovannom okne bez nashikh konkuriruyusjhikh sborok, proyekcii i smoke-check. Fonovaya rabota macOS sokhranyalasj; [dva sreza nagruzki](../../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/materialyi/nagruzka.json) ne yavlyayutsya nepreryivnyim monitoringom. Teplovoye sostoyaniye vo vsekh paketakh ravno 0, energosberezheniye vyiklyucheno.

Process zanyal 16,504 s, interval serij i otdeljnoj diagnostiki — 16,095 s. Zagruzka opredeleniya zanyala 5,138 ms, razbor i podgotovka — 0,809 ms; eti odnorazovyiye nablyudeniya isklyuchenyi iz ryadov. Vyibrano 1–1655 povtorov na paket. MAD devyati srednikh vremyon paketov sostavlyayet 0,091–2,507% medianyi po 48 ryadam. Eto opisateljnyij razbros, ne doveriteljnyij interval. Koefficiyent v tablice — otnosheniye dvukh median; privedyonnyiye cifryi ne imeyut tochnosti universaljnoj kharakteristiki processora.

| Vkhod                | Bajt / skalyarov | Rezuljtat    | Swift, ms | Interpretator, ms | Otnosheniye | MB/s Swift / interpretator |
| ------------------- | --------------- | ------------ | --------- | ----------------- | --------- | -------------------------- |
| ASCII-4096          | 4096 / 4096     | skalyaryi      | 0.0142    | 1.7504            | 123.10×   | 288.06 / 2.34              |
| ASCII-4096          | 4096 / 4096     | skalyaryi + LE | 0.0303    | 2.2606            | 74.70×    | 135.35 / 1.81              |
| ASCII-32768         | 32768 / 32768   | skalyaryi      | 0.1097    | 5.4935            | 50.10×    | 298.82 / 5.96              |
| ASCII-32768         | 32768 / 32768   | skalyaryi + LE | 0.2351    | 9.1914            | 39.10×    | 139.39 / 3.57              |
| ASCII-262144        | 262144 / 262144 | skalyaryi      | 0.8722    | 35.2118           | 40.37×    | 300.55 / 7.44              |
| ASCII-262144        | 262144 / 262144 | skalyaryi + LE | 1.9205    | 64.1064           | 33.38×    | 136.49 / 4.09              |
| kirillica-4096      | 4090 / 2454     | skalyaryi      | 0.0186    | 1.5494            | 83.46×    | 220.32 / 2.64              |
| kirillica-4096      | 4090 / 2454     | skalyaryi + LE | 0.0288    | 1.9119            | 66.38×    | 142.01 / 2.14              |
| kirillica-32768     | 32760 / 19656   | skalyaryi      | 0.1619    | 4.0231            | 24.86×    | 202.40 / 8.14              |
| kirillica-32768     | 32760 / 19656   | skalyaryi + LE | 0.2330    | 6.2772            | 26.94×    | 140.61 / 5.22              |
| kirillica-262144    | 262140 / 157284 | skalyaryi      | 1.3236    | 23.2056           | 17.53×    | 198.05 / 11.30             |
| kirillica-262144    | 262140 / 157284 | skalyaryi + LE | 1.9446    | 41.0398           | 21.10×    | 134.80 / 6.39              |
| smesj-4096          | 4090 / 1636     | skalyaryi      | 0.0120    | 1.4614            | 122.18×   | 341.93 / 2.80              |
| smesj-4096          | 4090 / 1636     | skalyaryi + LE | 0.0182    | 1.7600            | 96.65×    | 224.60 / 2.32              |
| smesj-32768         | 32760 / 13104   | skalyaryi      | 0.0936    | 3.2213            | 34.42×    | 350.03 / 10.17             |
| smesj-32768         | 32760 / 13104   | skalyaryi + LE | 0.1458    | 4.8800            | 33.48×    | 224.75 / 6.71              |
| smesj-262144        | 262140 / 104856 | skalyaryi      | 0.7415    | 17.1175           | 23.09×    | 353.54 / 15.31             |
| smesj-262144        | 262140 / 104856 | skalyaryi + LE | 1.1667    | 29.7724           | 25.52×    | 224.68 / 8.80              |
| dekompoziciya-4096   | 4092 / 1860     | skalyaryi      | 0.0135    | 1.5160            | 112.06×   | 302.46 / 2.70              |
| dekompoziciya-4096   | 4092 / 1860     | skalyaryi + LE | 0.0217    | 1.8282            | 84.24×    | 188.55 / 2.24              |
| dekompoziciya-32768  | 32758 / 14890   | skalyaryi      | 0.1080    | 3.5984            | 33.33×    | 303.40 / 9.10              |
| dekompoziciya-32768  | 32758 / 14890   | skalyaryi + LE | 0.1641    | 5.2039            | 31.72×    | 199.66 / 6.29              |
| dekompoziciya-262144 | 262141 / 119155 | skalyaryi      | 0.8259    | 19.0693           | 23.09×    | 317.38 / 13.75             |
| dekompoziciya-262144 | 262141 / 119155 | skalyaryi + LE | 1.3105    | 32.4306           | 24.75×    | 200.03 / 8.08              |

Dlya skalyarov vmeste s UTF-32LE na vkhodakh okolo 256 KiB polnyij API interpretatora zanimayet v 21,10–33,38 raza boljshe vremeni, chem strogij standartnyij putj. Soputstvuyusjhaya rabota interpretatora susjhestvenna: medianyi tryokh otdeljnyikh diagnosticheskikh vyizovov privedenyi nizhe. Stolbec polnogo vyizova okhvatyivayet vlozhennyiye intervalyi; skladyivatj yego s nimi neljzya. Otdeljnyiye medianyi stadij ne obyazanyi tochno skladyivatjsya v medianu polnogo vyizova.

| Vkhod okolo 256 KiB | Polnyij vyizov, ms | Proverka, ms | Ispolneniye, ms | Trassa i khyeshi, ms |
| ------------------ | ---------------- | ------------ | -------------- | ----------------- |
| ASCII              | 63,865           | 0,306        | 14,056         | 49,514            |
| Kirillica          | 41,131           | 0,252        | 9,297          | 31,559            |
| Smesj              | 29,484           | 0,242        | 7,025          | 22,223            |
| Dekompoziciya       | 32,656           | 0,254        | 7,951          | 24,316            |

Vse 46 polozhiteljnyikh sluchayev i 14 strogikh otkazov podtverzhdenyi do serij, kontroljnaya summa kazhdogo izmeryayemogo vyizova sovpala. UTF-32BE i skorostj obrabotki oshibochnyikh vkhodov ne izmeryalisj. Optimizaciya interpretatora po etim dannyim trebuyet otdeljnogo etapa. Stend sokhranyayet vyibrannuyu realizaciyu: profilj ne pokazal osnovaniya uslozhnyatj sbor metrik, a izmeneniye ispolnyayemogo dekodera pryamo isklyucheno iz tekusjhego sravneniya.

Syiryiye [432 paketa, 48 kalibrovok i 72 diagnosticheskikh vyizova](../../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/materialyi/sravneniye-Release.json) soderzhat takzhe minimum, maksimum i MAD. Nezavisimyij Python-proveryayusjhij povtorno vyivodit statistiku iz summarnogo vremeni i chisla povtorov, proveryayet paryi, cheredovaniye i khyeshi iskhodnikov. Posle izmereniya pereimenovano toljko sobstvennoye imya odnogo Swift-testa po yazyikovomu pravilu; ispolnyayemyiye iskhodniki stenda i interpretatora ne menyalisj. Staraya kvitanciya po-prezhnemu vklyuchayet Tests. Tochnyiye [prezhniye bajtyi testa](Proverki/etalonyi-profilya/test-sravneniya-do-pereimenovaniya.swift.txt) sokhranenyi. Sleduyusjhiye komandyi vosstanavlivayut izmerennyij snimok v otdeljnom vremennom kataloge, proveryayut vse 21 khyesh bez isklyuchenij i vyivodyat tablicu. Dlya sobstvennogo novogo progona dostatochno ukazatj yego JSON bez flaga kornya iskhodnikov, yesli tekusjhiye fajlyi sovpadayut s yego kvitanciyej. Diagnosticheskiye 72 vyizova proveryayutsya zdesj toljko po kolichestvu; semantika vnutrennikh metok proveryalasj otdeljno pri chtenii metodiki.

```sh
set -- "$(mktemp -d "${TMPDIR:?}fum-utf8-source.XXXXXX")"
cp -R Прототипы/память-структурирующих-операторов/. "$1/"
cp Прототипы/память-структурирующих-операторов/Проверки/эталоны-профиля/тест-сравнения-до-переименования.swift.txt "$1/Tests/FUMStructuringOperatorMemoryTests/ПроверкиСравненияДекодирования.swift"
python3 Прототипы/память-структурирующих-операторов/Проверки/проверить-сравнение.py Журнал/2026-09-11_12-00-09_MSK_сравнить-декодирование-UTF-8/материалы/сравнение-Release.json --корень-исходников "$1" --таблица "${TMPDIR:?}fum-utf8-results-table.txt"
python3 -B -m unittest discover -s Прототипы/память-структурирующих-операторов/Проверки -p test_проверка_сравнения.py
```

Proveryayusjhij zakreplyayet nezavisimyij konechnyij perechenj 21 puti iskhodnogo stenda versii 1. S etim perechnem otdeljno sravnivayutsya kvitanciya i sostav Sources/Tests vosstanovlennogo kataloga; zatem proveryayutsya bajtyi. Flag `--корень-исходников` vyibirayet mesto chteniya bajtov i ne opredelyayet obyazateljnyij sostav. Izmeneniye sostava iskhodnikov budusjhego stenda potrebuyet yavnogo obnovleniya etogo kontrakta. Semj regressij vklyuchayut odnovremennuyu poteryu fajla i zapisi o nyom.

## Istochniki i rezuljtatyi

- [Komanda i utochneniya metodiki](../../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/zapros.md).
- [Otchyot etapa](../../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/otchyot.md).
- [Korrektnostj Release i proiskhozhdeniye sborki](../../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/materialyi/korrektnostj-Release.json).
- [Sverka ustanovlennogo standartnogo API](../../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/materialyi/standartnyij-dekoder.json).
- [Arkhiv pervichnogo iskhodnika Swift](../../Istochniki/URL/https/github.com/swiftlang/swift/blob/main/stdlib/public/core/Unicode.swift/source-index.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 13:02:34 MSK -->
<!-- content-sha256: sha256:b80a30aa28432e0ddd3c68d72062ae665e9695f00cd4d2a813cdd9d9f0b4784a -->
<!-- FUM-MD-RECENCY:END -->
