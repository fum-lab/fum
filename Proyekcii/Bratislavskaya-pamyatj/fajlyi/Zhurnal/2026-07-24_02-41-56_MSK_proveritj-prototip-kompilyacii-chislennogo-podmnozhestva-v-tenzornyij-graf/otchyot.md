# Otchyot 2026-07-24 02:41:56 MSK - Proveritj prototip kompilyacii chislennogo podmnozhestva v tenzornyij graf

Pamyatj FUM poluchila ispolnyayemuyu lokaljnuyu proverku uzkogo chislennogo puti ot deklarativnoj funkcii nad tipizirovannyimi tenzorami do sobstvennogo SSA-grafa i vosproizvodimogo tekstovogo kandidata StableHLO/MLIR. Proverka sokhranyayet etalonnyij CPU-putj i yavno vyibirayet yego kak fallback: `stablehlo-opt` v `PATH` ne najden, celevoj provajder ne nastroyen, a vneshnyaya validaciya i celevoye ispolneniye ne vyipolnyalisj.

## Rezuljtat

[Samostoyateljnyij Swift-prototip](../../Prototipyi/kompilyaciya-chislennyikh-avtomatizacij-v-tenzornyij-graf/README.md) realizovan paketom bez vneshnikh zavisimostej. Strogij JSON-DSL versii `1` zadayot chistuyu `mul_add(left, right, bias)` dlya tryokh staticheskikh `tensor<4xf32>`. Kompilyator proveryayet konechnostj formyi, ogranicheniye razmera, tekhnicheskiye imena, unikaljnostj znachenij, sovpadeniye tipov operandov i ssyilki toljko na uzhe obyyavlennyiye znacheniya, posle chego stroit otdeljnyij tipizirovannyij graf iz `multiply` i `add`.

Iskhodnyij JSON uzhe yavlyayetsya SSA-podobnyim uporyadochennyim spiskom. Poetomu rezuljtat proveryayet validaciyu, vyivod tipov rezuljtatov, postroyeniye vnutrennego grafa i eksport, no ne sintaksicheskij analiz boleye vyisokogo yazyika, avtomaticheskoye razlozheniye proizvoljnogo vyirazheniya ili optimiziruyusjheye ponizheniye predstavleniya.

## Ogranichennoye chislennoye podmnozhestvo i eksport

Fikstura peredayot `left = [1, 2, 3, 4]`, `right = [2, 3, 4, 5]` i `bias = [1, 1, 1, 1]`. Direct CPU i ispolnitelj tipizirovannogo grafa nezavisimo poluchili `[3, 7, 13, 21]`; maksimaljnaya absolyutnaya raznica ravna nulyu.

Kanonicheskij JSON poluchil khyesh `sha256:91c61fed4d57147a3daeb7d9fcb8824f5d05279baf673e7e95aeded8f5f07c5e`. Tekstovyij StableHLO/MLIR-kandidat s `stablehlo.multiply` i `stablehlo.add` bajtovo sovpal s sokhranyonnoj `.mlir`-fiksturoj i poluchil khyesh `sha256:0aaccd790a3aea19d10da8efe5da06abfd3f0ffcc50863148acf58c9b7d58c64`. Obe fiksturyi upakovanyi kak resursyi bibliotechnoj celi i yavlyayutsya yedinstvennyimi vkhodami shtatnyikh `verify`, `export` i testov.

## Ekvivalentnostj i fallback

`DirectCPUReference` ispolnyayet namereniye `mul_add` neposredstvenno, a `TypedGraphExecutor` chitayet postroyennyiye SSA-uzlyi. Sravneniye ispoljzuyet absolyutnyij i otnositeljnyij dopuski `1e-6`; tochnaya fikstura proshla s nulevoj raznicej.

`stablehlo-opt`, `mlir-opt`, IREE i ONNX Runtime v lokaljnoj srede ne najdenyi. Otchyot razlichayet zavershyonnyij sobstvennyij eksport, dostupnostj komandyi validator, status `not_performed` vneshnej validacii i otsutstviye nastroyennogo celevogo provajdera. Zaproshennyij `stablehlo_target` ne vyidayotsya za ispolnennyij: vyibran `cpu_reference`, prichina fallback — `target_provider_not_configured`, versiya CPU-kontrakta — `FUMTensorGraphCPU/1`.

## Benchmark i trassa sredyi

Release-benchmark ispoljzoval formu `[16384]`, tri progrevochnyikh prokhoda, devyatj vyiborok i po `32` iteracii na vyiborku. V kornevom progone mediana direct CPU sostavila `1934917 ns`, p95 — `1963500 ns`; dlya graph CPU mediana sostavila `4430875 ns`, p95 — `4479667 ns`. Oba puti dali checksum `81.587890625` i ekvivalentnyiye rezuljtatyi.

Eti znacheniya izmeryayut nakladnyiye raskhodyi sobstvennogo CPU-interpretatora grafa, a ne celevoj uskoritelj. Pole `acceleration_claim` ravno `not_measured_no_target_provider`; pamyatj i energiya otdeljno ne izmeryalisj, nestabiljnyij vremennoj porog v testyi ne vklyuchyon. Chislo elementov, progrevov, vyiborok, iteracij i summarnaya rabota ogranichivayutsya do allokacij; chrezmernyij plan zavershayetsya upravlyayemoj oshibkoj.

Svyaznyij otchyot `verify` sokhranil `FUMTensorGraphCompiler` contract `1`, JSON-DSL `1`, `FUMTensorGraphCPU/1`, oba dopuska `1e-6`, khyeshi i obezlichennuyu sredu. Trassa sredyi zafiksirovala macOS `27.0.0`, arkhitekturu `arm64`, `10` logicheskikh i `10` dostupnyikh processorov, `68719476736` bajt fizicheskoj pamyati i compile-time-nablyudeniye `compiler_6_4_or_newer`. Otdeljnaya instrumentaljnaya proverka pokazala Apple Swift `6.4` (`swiftlang-6.4.0.27.1`, clang `2100.3.27.1`) s target `arm64-apple-macosx27.0.0`. Hostname, serijnyiye nomera, poljzovateljskiye katalogi i absolyutnyiye puti v trassu ne vkhodyat.

## Granica primenimosti

Proverena odna konechnaya poelementnaya funkciya, odin tip `f32`, staticheskiye nepustyiye formyi i dve binarnyiye operacii bez broadcasting, ciklov, vetvlenij, redukcij, strok, vvoda-vyivoda, dinamicheskoj pamyati i effektov. Sokhranyonnyij tekst yavlyayetsya neproverennyim kandidatom ogranichennogo profilya, a ne dokazanno korrektnyim modulem konkretnoj versii StableHLO.

Rezuljtat ne podtverzhdayet vneshnyuyu sintaksicheskuyu proverku, ispolneniye MLIR/IREE/XLA, ekvivalentnostj posle optimizacij, GPU/NPU-putj, vyiigryish vremeni, pamyati ili energii, perenosimostj za predelyi macOS, polnocennyij sintaksis yazyika avtomatizacij ili bezopasnostj proizvoljnyikh programm. Podklyucheniye provider/validator/runtime trebuyet otdeljnogo vosproizvodimogo offline-kontrakta i ne vkhodit v eto pokoleniye.

## Proverki

- Pervyij TDD-progon ozhidayemo zavershilsya kodom `1` iz-za otsutstvuyusjhej bibliotechnoj celi. Posle nezavisimogo revjyu novyiye testyi na resursnyiye fiksturyi, bezopasnyiye publichnyiye granicyi, svyaznuyu trassu i ranneye ogranicheniye benchmark snachala dali compile-red; itogovyiye `16` testov proshli.
- Sborka produkta `FUMTensorGraphProbe`, strogaya proverka konkurentnosti s preduprezhdeniyami kak oshibkami i Swift-format lint proshli.
- Bezargumentnyij `verify` podtverdil oba CPU-rezuljtata, nulevuyu raznicu, khyeshi, dopuski, versii kontraktov, `provider = not_configured`, `not_performed` dlya target-operacij i CPU fallback.
- `export` bajtovo sovpal s resursom `Sources/FUMTensorGraphCompiler/Фикстуры/mul_add.expected.mlir`; `trace`, `--help` i release-`benchmark` zavershilisj uspeshno.
- Proverka tochek vkhoda nashla odnu kornevuyu panelj i shestj prototipov.
- Regressionnyij TDD-test navyika svyaznosti vosproizvyol nevernoye zakryitiye chetyiryokhsimvoljnogo Markdown-fence vlozhennyim trojnyim fence; posle ispravleniya vse `37` testov navyika proshli, a doslovnyij zapros ostalsya neizmennyim.
- Planovyij validator podtverdil odin novyij ready-kandidat i sokhranyonnyij blocked-kandidat; fenced `show` podtverdil `master-fum-step-0004-ready-v1` i khyesh kartochki.
- Pervyij polnyij smoke-check doshyol do integracionnogo audita putej i otklonil odinochnyij literal simvola tiljdyi v novom fence-parsere. Posle bezopasnogo chislovogo predstavleniya markera celevyiye testyi i otdeljnyij audit putej proshli; povtornyij polnyij smoke-check zavershil vse `51` etap bez oshibok.

## Prodolzheniye

`FUM-STEP-0003` zavershena. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet [FUM-STEP-0004](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0004-podgotovitj-Swift-prototip-pamyati-strukturiruyusjhikh-operatorov-FUM.md) yedinstvennyim `ready` pokoleniya `master-fum-step-0004-ready-v1`.

Novyij shag ostayotsya lokaljnyim Swift-prototipom. Yego putj LLM-popolneniya ogranichivayetsya determinirovannyim adapterom sokhranyonnyikh kandidatnyikh predlozhenij s proiskhozhdeniyem i ne oznachayet setevogo vyizova zhivoj modeli ili realjnogo samoizmeneniya.

## Profilj vremeni vyipolneniya

| Stadiya                    |  Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                                                                                             |
| ------------------------- | ------------: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i dopusk FIFO |   ne izmereno | Pervyij bootstrap-poisk ne raspoznal zaklyuchyonnyij v kavyichki Git-putj, vtoroj peredal lishnij pozicionnyij korenj; oba otkazali bez zapisi. Sleduyusjhij `join` iz zakommichennogo scenariya srazu dal dopusk, ozhidaniya ne byilo. |
| Soderzhateljnaya rabota     | 23 min 03,0 s | Ot dopuska `02:36:45 MSK` do nachala zavershayusjhego celevogo kontura `02:59:48 MSK`; paralleljnyiye analizyi i TDD vkhodyat v stenovoye vremya i otdeljno ne skladyivayutsya.                                                       |
| Itogovyiye celevyiye proverki | 17 min 29,0 s | Ot `02:59:48 MSK` do `03:17:17 MSK`: ispravleniya po nezavisimomu revjyu, kornevoj povtor Swift-kontura, planovyiye proverki, recency i svyaznostj; paralleljnyiye stadii otdeljno ne skladyivayutsya.                           |
| Predfinaljnyij smoke-check |  5 min 22,9 s | Summa dvukh posledovateljnyikh polnyikh processov: `2 мин 22,5 с` do diagnosticheskogo otkaza audita putej i `3 мин 00,4 с` uspeshnogo povtora `51/51`; tochechnoye ispravleniye mezhdu nimi v dliteljnostj progonov ne vklyucheno.  |

Granica profilya: ot pervogo FIFO-bootstrap do zaversheniya predfinaljnogo polnogo smoke-check; neizmennogo ozhidaniya FIFO ne byilo, soderzhateljnaya rabota, celevyiye proverki, smoke-check i finaljnaya atomarnaya peredacha razlichayutsya.

## Zatronutyiye materialyi

- [Swift-prototip kompilyacii chislennyikh avtomatizacij](../../Prototipyi/kompilyaciya-chislennyikh-avtomatizacij-v-tenzornyij-graf/README.md)
- [kanonicheskaya JSON-fikstura](../../Prototipyi/kompilyaciya-chislennyikh-avtomatizacij-v-tenzornyij-graf/Sources/FUMTensorGraphCompiler/Fiksturyi/mul_add.json)
- [tochnyij StableHLO/MLIR-kandidat](../../Prototipyi/kompilyaciya-chislennyikh-avtomatizacij-v-tenzornyij-graf/Sources/FUMTensorGraphCompiler/Fiksturyi/mul_add.expected.mlir)
- [zavershyonnaya kartochka FUM-STEP-0003](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0003-proveritj-kompilyaciyu-ogranichennogo-chislennogo-podmnozhestva-yazyika-avtomatizacij-FUM-v-tenzornyij-vyichisliteljnyij-graf.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [politika SwiftPM-paketov](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json)
- [proverka svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [iskhodnyij zapros o kompilyacii algoritmov v tenzornyij graf](../2026-07-06_13-34-08_MSK_opisatj-kompilyaciyu-algoritmov-v-tenzornyij-graf/zapros.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [LLM-oriyentirovannyij yazyik avtomatizacij](../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:81e12d514b21aa991a9ebe9ca85d436630248fbb6096bf5e7f3ee588c40ae399 -->
<!-- FUM-MD-RECENCY:END -->
