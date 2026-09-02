+++
schema_version = 1
card_id = "FUM-STEP-0003"
status = "completed"
+++
# Proveritj prototip kompilyacii ogranichennogo chislennogo podmnozhestva yazyika avtomatizacij FUM v tenzornyij vyichisliteljnyij graf

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Proveritj prototip kompilyacii ogranichennogo chislennogo podmnozhestva [yazyika avtomatizacij FUM](../../Glossarij/yazyik-avtomatizacij-FUM.md) v tenzornyij vyichisliteljnyij graf: chistaya funkciya nad tipizirovannyimi tenzorami, eksport v ONNX ili StableHLO/MLIR, etalonnoye CPU-ispolneniye, lokaljnyiye fiksturyi, benchmark, fallback i trassa versij kompilyatora, runtime i apparatnogo profilya.

## Rezuljtat

Sozdan [samostoyateljnyij Swift-prototip kompilyacii chislennyikh avtomatizacij v tenzornyij graf](../../Prototipyi/kompilyaciya-chislennyikh-avtomatizacij-v-tenzornyij-graf/README.md). Strogij JSON-DSL zadayot chistuyu funkciyu `mul_add` nad tremya staticheskimi `tensor<4xf32>` i dvumya operaciyami; kompilyator proveryayet tipyi, formyi, imena i obratnyiye SSA-ssyilki, vyivodit tipyi rezuljtatov i stroit otdeljnyij tipizirovannyij graf.

Etalonnyij direct CPU i ispolnitelj tipizirovannogo grafa nezavisimo poluchili `[3, 7, 13, 21]` s nulevoj raznicej. Determinirovannyij tekstovyij StableHLO/MLIR-kandidat sovpal s resursnoj exact-fiksturoj i poluchil sokhranyonnyij SHA-256. Shestnadcatj avtonomnyikh testov, sborka so strogoj konkurentnostjyu, Swift-format lint, tochka vkhoda i panelj prototipov proshli.

`stablehlo-opt` v `PATH` ne najden, a celevoj provajder ne nastroyen, poetomu eksport ne obyyavlen oficialjno validirovannyim ili ispolnennyim na uskoritele. Release-benchmark sravnil toljko direct CPU i graph CPU, zafiksiroval odinakovyij checksum i nakladnyiye raskhodyi vnutrennego grafa; uskoreniye, pamyatj i energiya ne izmeryalisj. Trassa sokhranila versii kontraktov prototipnogo kompilyatora, eksportyora i CPU-runtime, dopuski sravneniya, statusyi `not_performed`, obezlichennyij apparatnyij profilj i fakticheski vyibrannyij `cpu_reference` fallback.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-24_02-41-56_MSK_proveritj-prototip-kompilyacii-chislennogo-podmnozhestva-v-tenzornyij-graf/zapros.md)
- [iskhodnyij zapros 2026-07-06 13:34:08 MSK - Opisatj kompilyaciyu algoritmov v tenzornyij graf](../../Zhurnal/2026-07-06_13-34-08_MSK_opisatj-kompilyaciyu-algoritmov-v-tenzornyij-graf/zapros.md), [LLM-oriyentirovannyij yazyik avtomatizacij](../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md), [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md), [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md), [Lokaljnyij agent FUM na vyidelennoj mashine](../../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md), [Arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ffc866eb134c7ba4749e9c4d5e7c0dd86b665f58d27c482333000a6bda058b44 -->
<!-- FUM-MD-RECENCY:END -->
