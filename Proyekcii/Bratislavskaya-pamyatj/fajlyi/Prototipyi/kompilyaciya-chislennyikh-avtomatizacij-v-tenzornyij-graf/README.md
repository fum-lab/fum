# Kompilyaciya chislennyikh avtomatizacij v tenzornyij graf

Etot Swift-prototip proveryayet uzkij putj ot deklarativnogo chislennogo podmnozhestva [yazyika avtomatizacij FUM](../../Glossarij/yazyik-avtomatizacij-FUM.md) do tipizirovannogo SSA-grafa i determinirovannogo tekstovogo kandidata StableHLO/MLIR. Vstroyennaya funkciya `mul_add` prinimayet tri tenzora `tensor<4xf32>`, vyichislyayet `left * right + bias` operaciyami `multiply` i `add`, posle chego dva nezavisimyikh CPU-puti sravnivayut rezuljtatyi.

Rezuljtat ne yavlyayetsya podtverzhdyonnyim StableHLO-modulem i ne ispolnyayetsya na uskoritele. Proverka nablyudayet nalichiye `stablehlo-opt` v `PATH`, no nikogda ne vyidayot yego nalichiye za vyipolnennuyu validaciyu. Target provider ne nastroyen, target-ispolneniye imeyet status `not_performed`, a vyibrannyim ispolniteljnyim putyom ostayotsya versionirovannyij etalonnyij CPU fallback. Prototip proveryayet kontrakt i nablyudayemuyu granicu otkaza, no ne zayavlyayet uskoreniye.

## Proveryayemyij kontur

```mermaid
flowchart LR
    source["Канонический JSON-DSL mul_add"] --> compiler["Строгая проверка формы и SSA"]
    compiler --> graph["Внутренний типизированный граф"]
    graph --> text["Текстовый кандидат StableHLO/MLIR"]
    source --> direct["Независимый direct CPU"]
    graph --> executor["Исполнитель typed-graph CPU"]
    direct --> compare["Сравнение f32 с допуском"]
    executor --> compare
    text --> target["Target provider: not_configured"]
    target --> fallback["FUMTensorGraphCPU/1"]
```

JSON — toljko prototipnyij nositelj ogranichennogo DSL, a ne okonchateljnyij sintaksis yazyika avtomatizacij FUM. Kompilyator prinimayet toljko staticheskiye nepustyiye formyi `f32`, tekhnicheskiye ASCII-imena, unikaljnyiye SSA-rezuljtatyi i ssyilki na uzhe obyyavlennyiye znacheniya. Vse vkhodnyiye i vyichislennyiye znacheniya dolzhnyi byitj konechnyimi. Dinamicheskiye formyi, broadcasting, izmeneniye sostoyaniya, vvod-vyivod, stroki, vetvleniya, ciklyi, redukcii i vneshniye operacii ne podderzhivayutsya.

`DirectCPUReference` vyichislyayet `mul_add` neposredstvenno po tryom massivam. `TypedGraphExecutor` nezavisimo interpretiruyet dve operacii s poiskom SSA-znachenij. Obe publichnyiye granicyi povtorno proveryayut tip, chislo elementov i konechnostj kazhdogo znacheniya do indeksirovaniya; sozdaniye vnutrennego typed graph dostupno toljko kompilyatoru. Sovpadeniye CPU-realizacij proveryayet vnutrennij graf, no ne ekvivalentnostj s vneshnim StableHLO-provajderom, poskoljku on ne nastroyen.

## Fiksturyi i trassa

- `Sources/FUMTensorGraphCompiler/Фикстуры/mul_add.json` — kanonicheskij JSON-scenarij versii `1` s formoj `[4]` i konechnyimi znacheniyami;
- `Sources/FUMTensorGraphCompiler/Фикстуры/mul_add.expected.mlir` — tochnyij ozhidayemyij tekst eksportyora;
- oba fajla vkhodyat v resursyi library target i yavlyayutsya yedinstvennyim chitayemyim istochnikom fixture: `verify`, `export` i testyi zagruzhayut ikh cherez `Bundle.module`, a otsutstviye ili raskhozhdeniye resursa privodit k otkazu;
- komanda `verify` vozvrasjhayet JSON-otchyot s `source_sha256`, `ir_sha256`, versiyami compiler/runtime-kontraktov, absolyutnyim i otnositeljnyim dopuskami, oboimi CPU-rezuljtatami, obezlichennoj sredoj, nablyudayemoj dostupnostjyu validator, `not_performed` dlya target-operacij i vyibrannyim fallback;
- komanda `trace` vozvrasjhayet toljko publikacionno chistyiye svojstva sredyi: chislovuyu versiyu macOS, arkhitekturu, chislo processorov, dostupnoye chislo processorov, obyyom pamyati i ogranichennoye compile-time-nablyudeniye versii Swift. Hostname, poljzovateljskiye katalogi i absolyutnyiye puti ne sobirayutsya.

Compile-time-nablyudeniye vida `compiler_6_4_or_newer` ne zamenyayet tochnuyu versiyu toolchain. Tochnuyu fakticheski ispoljzovannuyu versiyu Swift, Clang, Xcode i SDK rabochaya sessiya fiksiruyet otdeljno rezuljtatami komand proverki.

## Kak zapustitj

Bez argumentov launcher vyipolnyayet bezopasnuyu determinirovannuyu proverku:

```bash
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh
```

Dostupnyi yavnyiye rezhimyi:

```bash
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh verify
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh export
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh trace
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh --help
```

Benchmark launcher namerenno sobirayet release-konfiguraciyu:

```bash
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh benchmark
```

On do sozdaniya massivov ogranichivayet chislo elementov, progrevov, vyiborok, iteracij i ikh summarnuyu rabotu, zatem izmeryayet oba CPU-puti monotonnyimi nanosekundami i vozvrasjhayet medianu, p95 i checksum. Vremennyiye znacheniya zavisyat ot khosta i nagruzki, ne vkhodyat v determinirovannuyu fiksturu i ne ispoljzuyutsya kak nestabiljnyij testovyij porog. Sravneniye direct CPU s graph CPU pokazyivayet cenu vnutrennego predstavleniya, a ne preimusjhestvo uskoritelya; pole `acceleration_claim` ostayotsya `not_measured_no_target_provider`.

## Proverki

```bash
swift test \
  --package-path Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф
swift build \
  --package-path Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф \
  --product FUMTensorGraphProbe
swift format lint \
  --configuration Инструменты/fum-kompleksnaya-proverka-repozitoriya/swift-format.json \
  --strict \
  --recursive \
  Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/Package.swift \
  Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/Sources \
  Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/Tests
```

Avtonomnyiye testyi proveryayut resource-backed exact-eksport, bajtovuyu stabiljnostj kanonicheskogo JSON, nezavisimuyu CPU-ekvivalentnostj, stroguyu formu, obratnyiye SSA-ssyilki, unikaljnostj imyon, korotkiye i nekonechnyiye publichnyiye znacheniya bez trap, neizvestnyiye JSON-polya, SHA-256, svyaznuyu trassu, yavnyij fallback i ogranichennyij benchmark bez trebovaniya skorosti.

## Struktura

- `Sources/FUMTensorGraphCompiler/` — kontrakt DSL, strogij kompilyator, tipizirovannyij graf, dva CPU-puti, eksportyor, resursyi fixture, otchyotyi, fallback, trassa i benchmark;
- `Sources/FUMTensorGraphProbe/` — bezopasnyiye rezhimyi `verify`, `export`, `benchmark`, `trace` i spravka;
- `Tests/FUMTensorGraphCompilerTests/` — avtonomnaya proverka bez seti, sekretov i vneshnikh zavisimostej;
- `Sources/FUMTensorGraphCompiler/Фикстуры/` — sokhranyonnyij vkhod i tochnyij celevoj tekst, upakovannyiye SwiftPM kak library resources;
- `Package.swift` — samostoyateljnyij SwiftPM-paket bez vneshnikh zavisimostej;
- `запустить.sh` — POSIX-tochka vkhoda, nezavisimaya ot tekusjhego kataloga.

## Granica primenimosti

Prototip podtverzhdayet toljko kompilyaciyu odnoj konechnoj elementwise-funkcii v sobstvennyij tipizirovannyij graf, vosproizvodimyij tekst i dva soglasovannyikh CPU-rezuljtata. Iskhodnyij JSON uzhe zadayot uporyadochennyij SSA-podobnyij spisok iz `multiply` i `add`; kompilyator proveryayet yego, vyivodit tipyi rezuljtatov i stroit otdeljnyij tipizirovannyij graf, no ne proveryayet parser boleye vyisokogo sintaksisa, optimizaciyu ili avtomaticheskoye preobrazovaniye proizvoljnogo vyirazheniya. Prototip takzhe ne podtverzhdayet sootvetstviye teksta konkretnoj versii specifikacii StableHLO, priyomku vneshnim parser/verifier, ispolneniye cherez MLIR/IREE/XLA, chislennuyu ekvivalentnostj posle vneshnikh optimizacij, rabotu GPU/NPU, vyiigryish vremeni, pamyati ili energii, perenosimostj za predelyi macOS, polnocennuyu grammatiku yazyika avtomatizacij libo bezopasnostj proizvoljnyikh programm.

Dlya nastoyasjhej target-proverki nuzhen otdeljno zaregistrirovannyij vosproizvodimyij offline-kontrakt provider/validator/runtime. Do etogo `stablehlo_mlir_text_candidate`, `provider = not_configured`, `validation_status = not_performed`, `execution_status = not_performed` i `cpu_reference` yavlyayutsya chastjyu rezuljtata, a ne vremenno skryitoj oshibkoj. `swift_compiler_observation` fiksiruyet toljko compile-time-diapazon; tochnaya versiya Swift sokhranyayetsya otdeljno v otchyote rabochej sessii.

Status: dejstvuyusjhij ogranichennyij proverochnyij prototip s CPU fallback; target validator/runtime i uskoreniye ne podtverzhdenyi.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-24_02-41-56_MSK_proveritj-prototip-kompilyacii-chislennogo-podmnozhestva-v-tenzornyij-graf/zapros.md)
- [kartochka FUM-STEP-0003](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0003-proveritj-kompilyaciyu-ogranichennogo-chislennogo-podmnozhestva-yazyika-avtomatizacij-FUM-v-tenzornyij-vyichisliteljnyij-graf.md)

## Opornyiye materialyi

- [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [LLM-oriyentirovannyij yazyik avtomatizacij](../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Lokaljnyij agent FUM na vyidelennoj mashine](../../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [Arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:96711bb3853d40204594790b19b08cb4c4474467743084572282f46dca354eb4 -->
<!-- FUM-MD-RECENCY:END -->
