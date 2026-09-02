# Kartochki cepochek shagov FUM

[Kartochka cepochki shagov](../../Glossarij/kartochka-cepochki-shagov.md) svyazyivayet konechnuyu uporyadochennuyu posledovateljnostj kanonicheskikh [kartochek shagov](../../Glossarij/kartochka-shaga.md) s odnoj tochnoj lokaljnoj Git-vetkoj. Ona ne kopiruyet zadachi i kriterii otdeljnyikh shagov: poryadok, vetka i sostoyaniye prinadlezhat cepochke, a soderzhateljnaya rabota ostayotsya v `FUM-STEP-*`.

Ekspluatacionnyij status: kartochki cepochek i ikh sostoyaniya sokhranenyi kak otlozhennaya arkhitekturnaya narabotka. Oni ne pereklyuchayut checkout, ne sozdayut FIFO-vladeljca ili continuation i ne zapuskayut shag v dejstvuyusjhej ruchnoj skheme.

Nachalo realizacii cepochki oznachayet perekhod na ukazannyij v kartochke polnyij `refs/heads/codex/...`. Sostoyaniye `активна` fiksiruyet otdeljno vyibrannuyu sleduyusjhuyu cepochku i razreshayet takoj perekhod, no tekusjhej cepochkoj ona stanovitsya toljko pri sovpadenii kartochki, yeyo khyesha i imenovannoj vetki checkout. Uzhe dopusjhennyij vladelec FIFO vetku ne pereklyuchayet. Mezhzadachnyij perekhod dolzhen snachala dokazatj pustuyu ocheredj i chistuyu rabochuyu kopiyu, ograditj gonku, sozdatj otsutstvuyusjhuyu celevuyu vetku ot tochnoj iskhodnoj vershinyi i srazu dopustitj zadachu uzhe v celevoj vetke.

## Format

Kartochka nachinayetsya s TOML-bloka skhemyi `1` i soderzhit zaklyuchyonnyiye v kavyichki kirillicheskiye polya `версия_схемы`, `идентификатор_цепочки`, `состояние`, `ветка`, `базовая_ветка`, `путь_проекта` i `карточки_шагов`. Dopustimyi sostoyaniya `запланирована`, `активна`, `завершена` i `отозвана`; mashinnyij reyestr trebuyet rovno odnu aktivnuyu kartochku. Neotozvannyiye kartochki ne mogut delitj odin shag ili vetku; spisok shagov konechen, uporyadochen i ne soderzhit povtorov.

Polnyij priyomochnyij smoke-check shaga yavlyayetsya vnutrennej stadiyej zaversheniya rabochej sessii. Yego nulevoj kod yesjhyo ne oznachayet uspekh vsej smoke-sessii: uspeshnyij iskhod poyavlyayetsya toljko posle zakryitiya proverochnogo otchyota i atomarnogo `commit+handoff`, kotoryij dvigayet vetku tekusjhej cepochki.

## Indeks

| Identifikator      | Sostoyaniye       | Vetka                                                              | Kartochka                                                                                           |
| ------------------ | --------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `FUM-ЦЕПОЧКА-0001` | 🗑️ Otozvana      | `refs/heads/codex/цепочки/FUM-ЦЕПОЧКА-0001-приёмка-диспетчера`     | [Priyomka universaljnogo dispetchera](🗑️-FUM-CEPOCHKA-0001-priyomka-universaljnogo-dispetchera.md)       |
| `FUM-ЦЕПОЧКА-0002` | 🚧 Aktivna       | `refs/heads/codex/цепочки/FUM-ЦЕПОЧКА-0002-универсальные-подузлы`  | [Universaljnyiye ispolniteljnyiye poduzlyi](🚧-FUM-CEPOCHKA-0002-universaljnyiye-ispolniteljnyiye-poduzlyi.md) |
| `FUM-ЦЕПОЧКА-0003` | 🟡 Zaplanirovana | `refs/heads/codex/цепочки/FUM-ЦЕПОЧКА-0003-братиславская-проекция` | [Bratislavskaya proyekciya pamyati](🟡-FUM-CEPOCHKA-0003-bratislavskaya-proyekciya-pamyati.md)               |

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:80edfc9dda8e110fe0a1b307b1728b610423d29266b40c5bc8630f4d659276bc -->
<!-- FUM-MD-RECENCY:END -->
