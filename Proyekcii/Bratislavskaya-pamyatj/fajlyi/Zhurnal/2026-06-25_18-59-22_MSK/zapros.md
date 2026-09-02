# Iskhodnyij zapros 2026-06-25 18:59:22 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-06-25 18:50:18 MSK](../2026-06-25_18-50-18_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-06-25 19:18:28 MSK](../2026-06-25_19-18-28_MSK/zapros.md)

## Tekst zaprosa

> Dobavj pravilo, chto vezde v dokumentacii myi yavno ispoljzuyem bukvu yo, i ne zamenyayem yeyo na bukvu ye. Rasstavj po vsej pamyati bukvu yo.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.exec_command`, `functions.apply_patch`, `functions.update_plan`, `multi_tool_use.parallel`.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, proverki versij, poiska orfograficheskikh khvostov i zapuska proverok.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `functions.update_plan` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vedeniya kratkogo plana rabochej sessii.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-glossary` - versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-glossarij/SKILL.md); ispoljzovan pri pereimenovanii i obnovlenii glossarnyikh terminov.
- [Postroyeniye opisaniya FUM dlya adresata](../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md) - deklarativnaya avtomatizaciya; yavno vyizvana dlya orfograficheskoj peresborki adresnyikh opisanij bez izmeneniya istochnikovyikh tezisov.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnogo navyika](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); ispoljzovan dlya proverki svyaznosti tekusjhej rabochej sessii.
- `zsh` - `zsh 5.9 (arm64-apple-darwin26.0)`; ispoljzovan kak shell dlya komand.
- `git` - `git version 2.54.0 (Apple Git-156)`; ispoljzovan dlya proverki sostoyaniya, diff, staging i kommita.
- `rg` - `ripgrep 15.1.0`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` - `Python 3.14.6`; ispoljzovan dlya massovoj orfograficheskoj normalizacii, generacii sluzhebnyikh razdelov i zapuska proverok.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj v etoj sessii; ispoljzovanyi `sed`, `date` i standartnyiye shell-operacii chteniya.

## Povliyal na fajlyi

- [AGENTS.md](../../AGENTS.md)
- [README.md](../../README.md)
- [Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md](../../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md)
- [Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md](../../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md)
- [Voprosyi/2026-06-22_07-40-59_MSK_granicyi-kosmicheskoj-avtonomii-FUM.md](../../Voprosyi/2026-06-22_07-40-59_MSK_granicyi-kosmicheskoj-avtonomii-FUM.md)
- [Voprosyi/2026-06-22_07-51-48_MSK_granicyi-vlasti-uzlov-FUM.md](../../Voprosyi/2026-06-22_07-51-48_MSK_granicyi-vlasti-uzlov-FUM.md)
- [Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md](../../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md)
- [Voprosyi/2026-06-22_08-14-25_MSK_konflikt-avtonomii-i-ustojchivosti-FUM.md](../../Voprosyi/2026-06-22_08-14-25_MSK_konflikt-avtonomii-i-ustojchivosti-FUM.md)
- [Voprosyi/2026-06-22_08-22-06_MSK_razlicheniye-issledovateljskikh-statusov-FUM.md](../../Voprosyi/2026-06-22_08-22-06_MSK_razlicheniye-issledovateljskikh-statusov-FUM.md)
- [Voprosyi/README.md](../../Voprosyi/README.md)
- [Glossarij/MCP-server.md](../../Glossarij/MCP-server.md)
- [Glossarij/README.md](../../Glossarij/README.md)
- [Glossarij/avtomatizaciya-FUM.md](../../Glossarij/avtomatizaciya-FUM.md)
- [Glossarij/agentskij-cikl.md](../../Glossarij/agentskij-cikl.md)
- [Glossarij/ves-agenta-FUM.md](../../Glossarij/ves-agenta-FUM.md)
- [Glossarij/ves-svyazi-FUM.md](../../Glossarij/ves-svyazi-FUM.md)
- [Glossarij/vnutrennij-FUM.md](../../Glossarij/vnutrennij-FUM.md)
- [Glossarij/vnutrennyaya-modelj-drugogo-uzla.md](../../Glossarij/vnutrennyaya-modelj-drugogo-uzla.md)
- [Glossarij/vosproizvedyonnyij-rezuljtat-FUM.md](../../Glossarij/vosproizvedyonnyij-rezuljtat-FUM.md)
- [Glossarij/gibridnyij-uzel.md](../../Glossarij/gibridnyij-uzel.md)
- [Glossarij/gipoteza-FUM.md](../../Glossarij/gipoteza-FUM.md)
- [Glossarij/darvinovskij-planirovsjhik-FUM.md](../../Glossarij/darvinovskij-planirovsjhik-FUM.md)
- [Glossarij/dvukhkonturnyij-otbor-FUM.md](../../Glossarij/dvukhkonturnyij-otbor-FUM.md)
- [Glossarij/zhurnal-rabot.md](../../Glossarij/zhurnal-rabot.md)
- [Glossarij/iskhodnyij-zapros.md](../../Glossarij/iskhodnyij-zapros.md)
- [Glossarij/kosmicheskaya-avtonomiya-FUM.md](../../Glossarij/kosmicheskaya-avtonomiya-FUM.md)
- [Glossarij/mezhzvyozdnoye-rasseleniye-FUM.md](../../Glossarij/mezhzvyozdnoye-rasseleniye-FUM.md)
- [Glossarij/modaljnostj-prilozhenij.md](../../Glossarij/modaljnostj-prilozhenij.md)
- [Glossarij/modeljnaya-sreda.md](../../Glossarij/modeljnaya-sreda.md)
- [Glossarij/modulj-FUM.md](../../Glossarij/modulj-FUM.md)
- [Glossarij/napravleniye-proyektirovaniya-i-razvitiya-FUM.md](../../Glossarij/napravleniye-proyektirovaniya-i-razvitiya-FUM.md)
- [Glossarij/obobsjhyonnyij-darvinovskij-algoritm.md](../../Glossarij/obobsjhyonnyij-darvinovskij-algoritm.md)
- [Glossarij/obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md](../../Glossarij/obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)
- [Glossarij/obsjhaya-skhema-FUM.md](../../Glossarij/obsjhaya-skhema-FUM.md)
- [Glossarij/opisaniye-FUM-dlya-adresata.md](../../Glossarij/opisaniye-FUM-dlya-adresata.md)
- [Glossarij/otkryitiye-FUM.md](../../Glossarij/otkryitiye-FUM.md)
- [Glossarij/pattern-pamyati.md](../../Glossarij/pattern-pamyati.md)
- [Glossarij/peredavayemyij-rezuljtat-FUM.md](../../Glossarij/peredavayemyij-rezuljtat-FUM.md)
- [Glossarij/predlozheniye-o-sleduyusjhem-shage.md](../../Glossarij/predlozheniye-o-sleduyusjhem-shage.md)
- [Glossarij/prikreplyayemyij-material.md](../../Glossarij/prikreplyayemyij-material.md)
- [Glossarij/proizvodnaya-dokumentaciya.md](../../Glossarij/proizvodnaya-dokumentaciya.md)
- [Glossarij/proizvodstvennaya-cepochka-FUM.md](../../Glossarij/proizvodstvennaya-cepochka-FUM.md)
- [Glossarij/rabochaya-sessiya.md](../../Glossarij/rabochaya-sessiya.md)
- [Glossarij/robotizirovannaya-sistema-FUM.md](../../Glossarij/robotizirovannaya-sistema-FUM.md)
- [Glossarij/roj-Dajsona.md](../../Glossarij/roj-Dajsona.md)
- [Glossarij/siljnoye-predpolozheniye-FUM.md](../../Glossarij/siljnoye-predpolozheniye-FUM.md)
- [Glossarij/soznaniye.md](../../Glossarij/soznaniye.md)
- [Glossarij/spora-civilizacii.md](../../Glossarij/spora-civilizacii.md)
- [Glossarij/urovenj-dostupa.md](../../Glossarij/urovenj-dostupa.md)
- [Glossarij/fizicheskoye-dejstviye-FUM.md](../../Glossarij/fizicheskoye-dejstviye-FUM.md)
- [Glossarij/evolyucionnaya-cepochka-FUM.md](../../Glossarij/evolyucionnaya-cepochka-FUM.md)
- [Glossarij/eksperiment-FUM.md](../../Glossarij/eksperiment-FUM.md)
- [Glossarij/yazyik-avtomatizacij-FUM.md](../../Glossarij/yazyik-avtomatizacij-FUM.md)
- [Dokumentaciya/00-obzor-proyekta.md](../../Dokumentaciya/00-obzor-proyekta.md)
- [Dokumentaciya/01-modelj-pamyati-FUM.md](../../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Dokumentaciya/02-publikaciya-i-licenziya.md](../../Dokumentaciya/02-publikaciya-i-licenziya.md)
- [Dokumentaciya/03-evolyuciya-i-myishleniye.md](../../Dokumentaciya/03-evolyuciya-i-myishleniye.md)
- [Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md](../../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md](../../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md)
- [Dokumentaciya/06-obzor-agentskikh-ciklov.md](../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md](../../Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md)
- [Dokumentaciya/08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md](../../Dokumentaciya/08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)
- [Dokumentaciya/09-obmen-narabotkami-i-urovni-dostupa.md](../../Dokumentaciya/09-obmen-narabotkami-i-urovni-dostupa.md)
- [Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md](../../Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md)
- [Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md](../../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md)
- [Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md](../../Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md)
- [Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md](../../Dokumentaciya/13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [Dokumentaciya/14-kosmicheskaya-avtonomiya-i-rasseleniye.md](../../Dokumentaciya/14-kosmicheskaya-avtonomiya-i-rasseleniye.md)
- [Dokumentaciya/15-decentralizaciya-i-granicyi-vlasti.md](../../Dokumentaciya/15-decentralizaciya-i-granicyi-vlasti.md)
- [Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md](../../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md)
- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Dokumentaciya/18-opisaniya-FUM-dlya-adresatov.md](../../Dokumentaciya/18-opisaniya-FUM-dlya-adresatov.md)
- [Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md](../../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Dokumentaciya/22-arkhitektura-FUM.md](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md](../../Dokumentaciya/23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)
- [Zhurnal/2026-06-24_13-57-52_MSK.md](../2026-06-24_13-57-52_MSK/otchyot.md)
- [Zhurnal/2026-06-24_14-08-09_MSK.md](../2026-06-24_14-08-09_MSK/otchyot.md)
- [Zhurnal/2026-06-24_14-22-45_MSK.md](../2026-06-24_14-22-45_MSK/otchyot.md)
- [Zhurnal/2026-06-24_14-33-08_MSK.md](../2026-06-24_14-33-08_MSK/otchyot.md)
- [Zhurnal/2026-06-24_14-41-33_MSK.md](../2026-06-24_14-41-33_MSK/otchyot.md)
- [Zhurnal/2026-06-24_14-46-38_MSK.md](../2026-06-24_14-46-38_MSK/otchyot.md)
- [Zhurnal/2026-06-24_15-01-44_MSK.md](../2026-06-24_15-01-44_MSK/otchyot.md)
- [Zhurnal/2026-06-24_15-08-46_MSK.md](../2026-06-24_15-08-46_MSK/otchyot.md)
- [Zhurnal/2026-06-24_15-35-16_MSK.md](../2026-06-24_15-35-16_MSK/otchyot.md)
- [Zhurnal/2026-06-24_15-45-41_MSK.md](../2026-06-24_15-45-41_MSK/otchyot.md)
- [Zhurnal/2026-06-24_15-54-42_MSK.md](../2026-06-24_15-54-42_MSK/otchyot.md)
- [Zhurnal/2026-06-24_16-09-34_MSK.md](../2026-06-24_16-09-34_MSK/otchyot.md)
- [Zhurnal/2026-06-24_16-22-00_MSK.md](../2026-06-24_16-22-00_MSK/otchyot.md)
- [Zhurnal/2026-06-24_16-26-47_MSK.md](../2026-06-24_16-26-47_MSK/otchyot.md)
- [Zhurnal/2026-06-24_16-32-29_MSK.md](../2026-06-24_16-32-29_MSK/otchyot.md)
- [Zhurnal/2026-06-25_17-59-02_MSK.md](../2026-06-25_17-59-02_MSK/otchyot.md)
- [Zhurnal/2026-06-25_18-17-22_MSK.md](../2026-06-25_18-17-22_MSK/otchyot.md)
- [Zhurnal/2026-06-25_18-30-09_MSK.md](../2026-06-25_18-30-09_MSK/otchyot.md)
- [Zhurnal/2026-06-25_18-36-50_MSK.md](../2026-06-25_18-36-50_MSK/otchyot.md)
- [Zhurnal/2026-06-25_18-50-18_MSK.md](../2026-06-25_18-50-18_MSK/otchyot.md)
- [Zhurnal/2026-06-25_18-59-22_MSK.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Zaprosyi/2026-06-21_22-37-41_MSK.md](../2026-06-21_22-37-41_MSK/zapros.md)
- [Zaprosyi/2026-06-22_06-08-01_MSK.md](../2026-06-22_06-08-01_MSK/zapros.md)
- [Zaprosyi/2026-06-22_06-22-15_MSK.md](../2026-06-22_06-22-15_MSK/zapros.md)
- [Zaprosyi/2026-06-22_06-35-26_MSK.md](../2026-06-22_06-35-26_MSK/zapros.md)
- [Zaprosyi/2026-06-22_06-49-53_MSK.md](../2026-06-22_06-49-53_MSK/zapros.md)
- [Zaprosyi/2026-06-22_07-02-40_MSK.md](../2026-06-22_07-02-40_MSK/zapros.md)
- [Zaprosyi/2026-06-22_07-09-16_MSK.md](../2026-06-22_07-09-16_MSK/zapros.md)
- [Zaprosyi/2026-06-22_07-15-34_MSK.md](../2026-06-22_07-15-34_MSK/zapros.md)
- [Zaprosyi/2026-06-22_07-20-42_MSK.md](../2026-06-22_07-20-42_MSK/zapros.md)
- [Zaprosyi/2026-06-22_07-40-59_MSK.md](../2026-06-22_07-40-59_MSK/zapros.md)
- [Zaprosyi/2026-06-22_08-14-25_MSK.md](../2026-06-22_08-14-25_MSK/zapros.md)
- [Zaprosyi/2026-06-22_08-22-06_MSK.md](../2026-06-22_08-22-06_MSK/zapros.md)
- [Zaprosyi/2026-06-22_08-26-51_MSK.md](../2026-06-22_08-26-51_MSK/zapros.md)
- [Zaprosyi/2026-06-22_08-43-27_MSK.md](../2026-06-22_08-43-27_MSK/zapros.md)
- [Zaprosyi/2026-06-22_10-00-58_MSK.md](../2026-06-22_10-00-58_MSK/zapros.md)
- [Zaprosyi/2026-06-22_10-05-04_MSK.md](../2026-06-22_10-05-04_MSK/zapros.md)
- [Zaprosyi/2026-06-23_13-08-36_MSK.md](../2026-06-23_13-08-36_MSK/zapros.md)
- [Zaprosyi/2026-06-23_13-18-14_MSK.md](../2026-06-23_13-18-14_MSK/zapros.md)
- [Zaprosyi/2026-06-23_13-26-21_MSK.md](../2026-06-23_13-26-21_MSK/zapros.md)
- [Zaprosyi/2026-06-23_13-55-41_MSK.md](../2026-06-23_13-55-41_MSK/zapros.md)
- [Zaprosyi/2026-06-23_14-04-59_MSK.md](../2026-06-23_14-04-59_MSK/zapros.md)
- [Zaprosyi/2026-06-23_17-45-40_MSK.md](../2026-06-23_17-45-40_MSK/zapros.md)
- [Zaprosyi/2026-06-23_18-24-05_MSK.md](../2026-06-23_18-24-05_MSK/zapros.md)
- [Zaprosyi/2026-06-23_18-43-31_MSK.md](../2026-06-23_18-43-31_MSK/zapros.md)
- [Zaprosyi/2026-06-23_19-00-50_MSK.md](../2026-06-23_19-00-50_MSK/zapros.md)
- [Zaprosyi/2026-06-23_19-06-56_MSK.md](../2026-06-23_19-06-56_MSK/zapros.md)
- [Zaprosyi/2026-06-24_13-25-48_MSK.md](../2026-06-24_13-25-48_MSK/zapros.md)
- [Zaprosyi/2026-06-24_13-32-11_MSK.md](../2026-06-24_13-32-11_MSK/zapros.md)
- [Zaprosyi/2026-06-24_13-43-47_MSK.md](../2026-06-24_13-43-47_MSK/zapros.md)
- [Zaprosyi/2026-06-24_13-57-52_MSK.md](../2026-06-24_13-57-52_MSK/zapros.md)
- [Zaprosyi/2026-06-24_14-08-09_MSK.md](../2026-06-24_14-08-09_MSK/zapros.md)
- [Zaprosyi/2026-06-24_14-22-45_MSK.md](../2026-06-24_14-22-45_MSK/zapros.md)
- [Zaprosyi/2026-06-24_14-33-08_MSK.md](../2026-06-24_14-33-08_MSK/zapros.md)
- [Zaprosyi/2026-06-24_14-41-33_MSK.md](../2026-06-24_14-41-33_MSK/zapros.md)
- [Zaprosyi/2026-06-24_14-46-38_MSK.md](../2026-06-24_14-46-38_MSK/zapros.md)
- [Zaprosyi/2026-06-24_15-01-44_MSK.md](../2026-06-24_15-01-44_MSK/zapros.md)
- [Zaprosyi/2026-06-24_15-08-46_MSK.md](../2026-06-24_15-08-46_MSK/zapros.md)
- [Zaprosyi/2026-06-24_15-35-16_MSK.md](../2026-06-24_15-35-16_MSK/zapros.md)
- [Zaprosyi/2026-06-24_15-45-41_MSK.md](../2026-06-24_15-45-41_MSK/zapros.md)
- [Zaprosyi/2026-06-24_15-54-42_MSK.md](../2026-06-24_15-54-42_MSK/zapros.md)
- [Zaprosyi/2026-06-24_16-09-34_MSK.md](../2026-06-24_16-09-34_MSK/zapros.md)
- [Zaprosyi/2026-06-24_16-22-00_MSK.md](../2026-06-24_16-22-00_MSK/zapros.md)
- [Zaprosyi/2026-06-24_16-26-47_MSK.md](../2026-06-24_16-26-47_MSK/zapros.md)
- [Zaprosyi/2026-06-24_16-32-29_MSK.md](../2026-06-24_16-32-29_MSK/zapros.md)
- [Zaprosyi/2026-06-25_17-59-02_MSK.md](../2026-06-25_17-59-02_MSK/zapros.md)
- [Zaprosyi/2026-06-25_18-17-22_MSK.md](../2026-06-25_18-17-22_MSK/zapros.md)
- [Zaprosyi/2026-06-25_18-30-09_MSK.md](../2026-06-25_18-30-09_MSK/zapros.md)
- [Zaprosyi/2026-06-25_18-36-50_MSK.md](../2026-06-25_18-36-50_MSK/zapros.md)
- [Zaprosyi/2026-06-25_18-50-18_MSK.md](../2026-06-25_18-50-18_MSK/zapros.md)
- [Zaprosyi/2026-06-25_18-59-22_MSK.md](zapros.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/fum-doc-aggregation/SKILL.md](../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/SKILL.md)
- [Instrumentyi/fum-doc-aggregation/scripts/build-doc-aggregation.py](../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/scripts/build-doc-aggregation.py)
- [Instrumentyi/fum-doc-aggregation/tests/test_build_doc_aggregation.py](../../Instrumentyi/fum-sborka-svodnoj-dokumentacii/tests/test_build_doc_aggregation.py)
- [Instrumentyi/fum-glossary/SKILL.md](../../Instrumentyi/fum-glossarij/SKILL.md)
- [Instrumentyi/fum-request-materials/SKILL.md](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)
- [Instrumentyi/fum-request-materials/scripts/archive-chatgpt-share.py](../../Instrumentyi/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py)
- [Instrumentyi/fum-request-materials/tests/test_archive_chatgpt_share.py](../../Instrumentyi/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py)
- [Instrumentyi/fum-session-coherence/SKILL.md](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [Instrumentyi/fum-session-coherence/scripts/check-session-coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py)
- [Instrumentyi/fum-session-coherence/tests/test_check_session_coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Istochniki/README.md](../../Istochniki/README.md)
- [Opisaniya/README.md](../../Opisaniya/README.md)
- [Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md](../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md)
- [Opisaniya/dlya-gosudarstva.md](../../Opisaniya/dlya-gosudarstva.md)
- [Opisaniya/dlya-investorov.md](../../Opisaniya/dlya-investorov.md)
- [Opisaniya/dlya-razrabotchikov-PO.md](../../Opisaniya/dlya-razrabotchikov-PO.md)
- [Planirovaniye/MVP-kandidatyi/01-pamyatj-rabochej-sessii/README.md](../../Planirovaniye/MVP-kandidatyi/01-pamyatj-rabochej-sessii/README.md)
- [Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)
- [Planirovaniye/MVP-kandidatyi/03-glossarno-dokumentacionnyij-kontur/README.md](../../Planirovaniye/MVP-kandidatyi/03-glossarno-dokumentacionnyij-kontur/README.md)
- [Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md](../../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [Planirovaniye/MVP-kandidatyi/05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md](../../Planirovaniye/MVP-kandidatyi/05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md)
- [Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md](../../Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)
- [Planirovaniye/MVP-kandidatyi/README.md](../../Planirovaniye/MVP-kandidatyi/README.md)
- [Planirovaniye/MVP-kandidatyi/matrica-otbora.md](../../Planirovaniye/MVP-kandidatyi/matrica-otbora.md)
- [Planirovaniye/dorozhnaya-karta.md](../../Planirovaniye/dorozhnaya-karta.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/02-avtomatizacii-i-yazyik.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/02-avtomatizacii-i-yazyik.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/06-evolyucionnyiye-cepochki-i-otbor.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/06-evolyucionnyiye-cepochki-i-otbor.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/08-fizicheskiye-i-daljniye-konturyi.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/08-fizicheskiye-i-daljniye-konturyi.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/README.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/README.md)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
## Proverki

- `python3 Инструменты/fum-doc-aggregation/tests/test_build_doc_aggregation.py` - proshlo.
- `python3 Инструменты/fum-request-materials/tests/test_archive_chatgpt_share.py` - proshlo.
- `python3 Инструменты/fum-session-coherence/tests/test_check_session_coherence.py` - proshlo.
- `git diff --check` - proshlo bez zamechanij.
- `all markdown links ok: 245 files` - proverka Markdown-ssyilok cherez `validate_markdown_links` proshla.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-25_18-59-22_MSK.md` - proshlo.
- `rg`-poisk tipichnyikh propusjhennyikh form s obyazateljnoj `ё` ostavil toljko doslovnuyu citatu iskhodnogo zaprosa 2026-06-22 08:22:06 MSK, kotoraya ne ispravlyayetsya po pravilam sokhraneniya pervichnogo teksta.
## Opisaniye sdelannogo

V [AGENTS.md](../../AGENTS.md) dobavleno pravilo yavnogo ispoljzovaniya bukvyi `ё` v russkoyazyichnoj dokumentacii, sluzhebnyikh poyasneniyakh, glossarnyikh terminakh i russkikh imenakh fajlov. Posle etogo proizvodnaya [pamyatj FUM](../../Glossarij/pamyatj-FUM.md) privedena k etomu pravilu: obnovlenyi tekstyi dokumentacii, glossariya, zhurnalov, planirovaniya, lokaljnyikh navyikov i sluzhebnyikh materialov.

Fajlyi ustojchivyikh terminov s obyazateljnoj `ё` pereimenovanyi, a ssyilki na nikh obnovlenyi: [vosproizvedyonnyij rezuljtat FUM](../../Glossarij/vosproizvedyonnyij-rezuljtat-FUM.md), [mezhzvyozdnoye rasseleniye FUM](../../Glossarij/mezhzvyozdnoye-rasseleniye-FUM.md), [obobsjhyonnyij darvinovskij algoritm](../../Glossarij/obobsjhyonnyij-darvinovskij-algoritm.md) i [obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](../../Glossarij/obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md).

Bloki `## Текст запроса` v staryikh fajlakh `Запросы/` sokhranenyi doslovno, poetomu ostavshijsya `воспроизведенный` vnutri citatyi iskhodnogo zaprosa ne ispravlyalsya. Adresnyiye opisaniya peresobranyi orfograficheski cherez yavnyij vyizov zakreplyonnoj avtomatizacii [postroyeniya opisaniya FUM dlya adresata](../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md), bez izmeneniya ikh istochnikovyikh tezisov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:dc367db94cf61c5b30b2277dbc9c1c7f199c4ca02a132f26e53a970796c91a22 -->
<!-- FUM-MD-RECENCY:END -->
