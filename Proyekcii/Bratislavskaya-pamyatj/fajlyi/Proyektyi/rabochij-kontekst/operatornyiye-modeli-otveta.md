# Operatornyiye modeli nativnogo otveta

Odno [opisaniye dannyikh i proyekcii](kontraktyi/opisaniye-otveta.json) porozhdayet [Swift Codable-modeli](porozhdyonnyiye/ModeliOtveta.swift) i [Python dataclass-modeli](porozhdyonnyiye/modeli_otveta.py). Cherez tot zhe opisannyij graf vyichislyayutsya proverki, vyibor otveta, pereimenovaniye polej, schyotchiki i ssyilki na polnyij snimok. Ruchnyiye obsjhiye funkcii nakhodyatsya v [podderzhke yazyikov](obsjhiye/); predmetnogo sootvetstviya polej v nikh net.

Eto pervyij konechnyij profilj `fum.модели-и-проекция.1`, chislovaya oblastj — `целые64-без-дробей`. Rabochij [prezhnij Python-srez](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/kompaktnyij-otvet-zadachi.md) i yego skhemyi sokhranenyi. Sovpadeniye dvukh novyikh realizacij vnutri profilya provereno; sovmestimostj so vsej chislovoj oblastjyu prezhnego kontrakta ne zayavlena. Obsjhaya API/cache-obyortka sokhranyayet prezhnij srez po umolchaniyu; parametr `профиль_представления: "порождённый"` i flag CLI `--профиль порождённый` yavno podklyuchayut eti modeli k novomu i sokhranyonnomu chteniyu. Smena profilya uzhe prinyatogo snimka sokhranyayet proverku SHA i okonchateljnogo byudzheta s putyom i LF; skryitogo otkata net.

## Otkuda beryotsya generaciya

V [susjhestvuyusjhem ispolnitele](../../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/) `AutomationExecutor.выполнить` ispolnyayet dva novyikh konechnyikh shaga: `разобрать-структурный-контракт` sozdayot proverennoye strukturnoye znacheniye, `породить-представление` vyidayot iskhodnyij tekst vyibrannogo yazyika. Opredeleniya [Swift](kontraktyi/generaciya-Swift.json) i [Python](kontraktyi/generaciya-Python.json) vyizyivayut eti shagi s odinakovyim profilem. Ispolnitelj schitayet stoimostj, proveryayet resursnyiye predelyi i vyidayot sledyi s SHA vkhodnyikh bajtov. [Obyortka generacii](poroditj-otvet.py) svyazyivayet oba nablyudeniya s odnim opisaniyem i toljko posle uspekha oboikh vyichislenij pishet vyikhodyi.

Perenesyon minimaljnyij nabor iz desyati fajlov iskhodnogo kommita `f49eeee3fd80a87cd63391d6606dafa19cd6d2b8`; prezhniye tri izmenyayemyikh fajla predvariteljno sovpali s yego roditelem. Perenos i istoricheskiye svideteljstva perechislenyi v [manifeste proiskhozhdeniya](../../Zhurnal/2026-09-14_15-54-44_MSK_poroditj-modeli-otveta-operatorami/materialyi/istochnik-ispolnitelya.json). Proverki istochnika ne zamenyayut sobstvennuyu priyomku: tekusjhij paket proshyol 45 testov.

Sobstvennyij iskhodnyij interfejs podderzhki ispoljzuyet `КонтрактМоделей(кодированноеОписание:)`; pole strukturnogo kontrakta nazyivayetsya `допускаетПустойМаркер`. [Soglasovannaya migraciya imyon](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/sobstvennyiye-imena-konteksta.md) obnovila obyyavleniya, izvestnyiye vyizovyi i shablon generatora, posle chego modeli peresozdanyi ispolnitelem. Metki vneshnikh protokolov `init(from:)` i `encode(to:)`, mashinnyiye klyuchi i JSON-skhema sokhranyayutsya. Sostavnyiye sobstvennyiye JSON-imena zakreplenyi konechnyim perechnem po russkoj smyislovoj osnove.

## Vosproizvedeniye

Nuzhnyi Python 3.10+ so standartnoj bibliotekoj i Swift 6.0+ na macOS 14+. Izmereno na Python 3.14.7 i Apple Swift 6.4. Vneshniye paketyi i setj ne nuzhnyi. Sborochnyiye katalogi zadayutsya vne Git. Vse komandyi vyipolnyayutsya iz kornya klona FUM; uglovyiye plejskholderyi zamenyayutsya fakticheskimi putyami.

```bash
swift build --package-path Прототипы/память-структурирующих-операторов --scratch-path <сборка-операторов> --jobs 2
swift build --package-path Прототипы/память-структурирующих-операторов --scratch-path <сборка-операторов> --show-bin-path
python3 -B Проекты/рабочий-контекст/породить-ответ.py --исполнитель <путь-к-FUMStructuringOperatorMemoryProbe> --выход Проекты/рабочий-контекст/порождённые
swift build --package-path Проекты/рабочий-контекст --scratch-path <сборка-ответа> --jobs 2
swift build --package-path Проекты/рабочий-контекст --scratch-path <сборка-ответа> --show-bin-path
```

`--show-bin-path` vozvrasjhayet katalog ispolnyayemyikh fajlov vyibrannoj sistemyi sborki. `FUMStructuringOperatorMemoryProbe` nakhoditsya v pervom kataloge, `ОтветЗадачи` — vo vtorom. Porozhdyonnyiye fajlyi uzhe khranyatsya v Git; povtornaya generaciya ne nuzhna dlya obyichnoj sborki.

Proverka drejfa dobavlyayet `--проверить` k komande generacii. Uspekh — kod 0 i razmeryi/SHA dvukh fajlov. Kod 2 oznachayet nepodderzhannoye opisaniye, nedostovernoye nablyudeniye libo drejf; susjhestvuyusjhiye vyikhodyi ne ispravlyayutsya rezhimom proverki. Vyichisliteljnyij otkaz do zapisi sokhranyayet oba staryikh fajla. Atomarnaya para zapisej pri otkaze fajlovoj sistemyi ne zayavlena.

Swift CLI poluchayet SHA-256 tochnyikh UTF-8-bajtov obolochki, UUID zadachi i byudzhet; polnyij fajl zaraneye sokhranyayet vyizyivayusjhij sloj:

```bash
<путь-к-ОтветЗадачи> <полный-sha256> <uuid-задачи> 16000 < <полный-сохранённый-json>
```

Python vyizyivayetsya cherez `представить_снимок(данные, ожидаемый_хэш, задача, максимум_байтов=16000)` iz porozhdyonnogo modulya. V putj modulej dobavlyayutsya `общие/Python` i `порождённые`. Vozvrasjhayutsya gotovyiye UTF-8-bajtyi s LF; `ValueError` — otkaz bez izmeneniya vkhodnyikh bajtov. Obsjhij predel snimka — 128 MiB, glubina JSON — 64, byudzhet — 100–1048576 bajtov. Swift CLI na otkaze vozvrasjhayet kod 2, pustoj stdout i kratkuyu diagnostiku. Ni odna realizaciya ne obrezayet rezuljtat do byudzheta.

## Tochnaya oblastj profilya

Otsutstviye, null i pustoye znacheniye razlichayutsya. `error: false`, `error: 0`, pustyiye stroka, massiv i obyyekt sokhranyayutsya kak znacheniya. Vse celyiye ogranichenyi Int64; logicheskij tip otdeljnyij. Tokenyi `1.0` i `1e0` otklonyayutsya dazhe vnutri proizvoljnogo `error`. Leksicheskij kontrolj vyipolnyayetsya do Codable v `представитьСнимок`; otdeljnyij vyizov JSONDecoder bez etogo vkhoda ne dokazyivayet sootvetstviye chislovyikh tokenov profilyu.

Stroki i klyuchi sopostavlyayutsya po tochnyim Unicode-skalyaram. Polnyiye iskhodnyiye stroki ne normalizuyutsya. Povtornyiye i kanonicheski sovpadayusjhiye klyuchi odnogo JSON-obyyekta otklonyayutsya v oboikh yazyikakh; gruppirovka tozhe otkazyivayet, yesli potrebovala byi obyyedinitj takiye klyuchi. Probeljnostj zadayotsya obsjhej tablicej skalyarov v opisanii, vklyuchaya U+0085 i U+001C, no isklyuchaya U+200B i U+FEFF.

Vyibor ispoljzuyet poryadok massivov: pervyij khod s podkhodyasjhim soobsjheniyem i posledneye nepustoye soobsjheniye etogo khoda. `commentary` i `final` ravnopravnyi. Posleduyusjhiye khodyi i elementyi vsyo ravno proveryayutsya i uchityivayutsya. Vyikhod sokhranyayet tochnyiye metadannyiye vyibrannogo khoda, `error`, paginaciyu i yavnyiye schyotchiki propuska. Neizvestnyiye polya i variantyi zakryitogo predmetnogo tipa dayut otkaz. Obyyavlennyiye neprozrachnyiye tipyi elementov sokhranyayutsya toljko v polnom originale i uchityivayutsya schyotchikami.

Snachala proveryayetsya SHA vsej obolochki. Dvukhurovnevyij ukazatelj adresuyet stroku vnutrennego JSON i nuzhnyij element vnutri neyo. Original ostayotsya neobkhodimyim dlya raskryitiya propusjhennogo. Otkaz profilya ne oznachayet otsutstviye otveta ili uspeshnuyu obrabotku. Pustoj prinyatyij otvet tozhe ne dokazyivayet zaversheniya zadachi; priznaki svezhesti i zaversheniya yavno lozhnyi.

Opisaniye ogranicheno 64 KiB, 32 modelyami, 64 polyami modeli i dvumya urovnyami kontejnerov tipov. Rekursivnyiye modeli, povtornyiye obyyavleniya, sluzhebnyiye imena, neizvestnyiye operacii i zavedomo nevernyiye tipyi konstant otklonyayutsya. Dinamicheskij putj dopolniteljno proveryayetsya pri primenenii. Eto konechnyij yazyik odnogo rabochego kontrakta, a ne universaljnyij kompilyator.

## Proverki i izmereniya

```bash
swift test --package-path Прототипы/память-структурирующих-операторов --scratch-path <сборка-операторов> --jobs 2
swift test --package-path Проекты/рабочий-контекст --scratch-path <сборка-ответа> --jobs 2
python3 -B Проекты/рабочий-контекст/проверить-операции.py
python3 -B Проекты/рабочий-контекст/проверить-генерацию.py --исполнитель <путь-к-FUMStructuringOperatorMemoryProbe>
FUM_СВИФТ_ОТВЕТ=<путь-к-ОтветЗадачи> python3 -B Проекты/рабочий-контекст/проверить-порождённый-ответ.py
python3 -B Проекты/рабочий-контекст/профиль-порождённого-ответа.py --исполнитель <путь-к-FUMStructuringOperatorMemoryProbe> --swift <путь-к-ОтветЗадачи> --выход <файл-профиля>
```

Bez `FUM_СВИФТ_ОТВЕТ` nativnaya Python-proverka ne zayavlyayet zapuska Swift. Obsjhiye 32 primera operacij proveryayut strogiye tipyi, glubinnoye ravenstvo, Unicode, otsutstviye i perepolneniye. Nativnyiye semj grupp dopolniteljno proveryayut vesj nabor probeljnyikh skalyarov, granicyi Int64, SHA, tochnuyu granicu byudzheta i dostupnostj iskhodnogo fajla posle otkaza. Povtornyiye vyikhodyi runtime sravnivayutsya po smyislu: poryadok JSON-klyuchej i ekranirovaniye `/` mogut razlichatjsya, a znachit, razmeryi i priyomka na odinakovoj granice byudzheta tozhe mogut razlichatjsya. Byudzhet proveryayetsya po realjnyim bajtam kazhdoj realizacii.

[Profilj](../../Zhurnal/2026-09-14_15-54-44_MSK_poroditj-modeli-otveta-operatorami/materialyi/profilj-generacii-i-primeneniya-okonchateljnyij.json) soderzhit semj povtorov. Mediana generacii — 54,69 ms bez sborki. Malyij vkhod 493 bajta dayot 2133 bajta Python ili 2145 Swift; krupnyij 4021534 bajta dayot 2870 ili 2897 bajtov. Primeneniye Python izmereno vnutri zagruzhennogo processa, Swift — vmeste s novyim CLI-processom; eto raznyiye granicyi, ne rejting yazyikov. Tokenyi, RSS, setj i ekonomiya na realjnoj smeshannoj posledovateljnosti zdesj ne izmerenyi. Istoricheskij zhivoj malyij vkhod prezhnego sreza tozhe uvelichivalsya: 885 → 2595 bajtov.

Optimizaciya etogo etapa ne rasshiryayet yazyik i ne menyayet format radi menjshego rezuljtata. [Sleduyusjhij profilj sokhranyonnoj API-obyortki](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/kompaktnyij-otvet-zadachi.md) izmeril smeshannuyu posledovateljnostj boljshikh i malyikh otvetov s povtornyim ispoljzovaniyem. Istoricheskaya seriya ispoljzovala prezhnij Python-etalon i otdeljno uchityivala stoimostj fajlov, vyizovov i poleznoj vyidachi. [Podklyucheniye yavnogo profilya](../../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/otchyot.md) proverilo realjnyij CLI/cache i ravenstvo 42 rezuljtatov v obsjhej oblasti. Porozhdyonnyij putj dorozhe prezhnego; uskoreniye i obsjhaya ekvivalentnostj prezhnemu kontraktu ne zayavlyayutsya. Granicyi Int64, glubinyi 64, UUID, Unicode-klyuchej i UTF-8 bez BOM perechislenyi v rukovodstve CLI; prezhnij rezhim po umolchaniyu ne suzhen.

## Istochniki

- [Postanovka, prinyatyij chislovoj profilj i otchyot](../../Zhurnal/2026-09-14_15-54-44_MSK_poroditj-modeli-otveta-operatorami/zapros.md).
- [Prezhnyaya priyomka nativnogo Python-sreza](../../Zhurnal/2026-09-14_15-01-38_MSK_sokratitj-otvetyi-nativnyikh-instrumentov/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 03:08:23 MSK -->
<!-- content-sha256: sha256:d8990ab374366d89941b4ffcb8433b6521c0faaaeb1d509923d51cfb3f382893 -->
<!-- FUM-MD-RECENCY:END -->
