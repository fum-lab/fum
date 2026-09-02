# Iskhodnyij zapros 2026-07-01 21:07:58 MSK

## Navigaciya po zaprosam

- Predyidusjhij zapros: [2026-07-01 17:03:14 MSK](../2026-07-01_17-03-14_MSK/zapros.md)
- Sleduyusjhij zapros: [2026-07-01 22:01:43 MSK](../2026-07-01_22-01-43_MSK/zapros.md)

## Tekst zaprosa

> Perenesyom istochniki trebovanij vo vsekh dokumentov vniz dokumenta i zakrepim takoj format, chtobyi spisok istochnikov ne meshal chitatj osnovnoj kontent.

## Ispoljzovannyiye instrumentyi

- [Reyestr sistemnyikh prilozhenij i instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) - obsjhij spravochnik instrumentov, versij i sposobov proverki.
- Codex - versiya ne raskryivayetsya sredoj; ispoljzovan kak agentskaya sreda rabochej sessii i istochnik kontraktov instrumentov `functions.exec_command`, `functions.apply_patch`, `multi_tool_use.parallel`.
- `functions.exec_command` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya chteniya fajlov, proverki Git-sostoyaniya, snyatiya vremeni, zapuska testov, lokaljnyikh avtomatizacij i Git-komand.
- `functions.apply_patch` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya vneseniya ruchnyikh fajlovyikh pravok.
- `multi_tool_use.parallel` - versiya ne raskryivayetsya sredoj; ispoljzovan dlya paralleljnogo chteniya nezavisimyikh fajlov i diagnosticheskikh komand.
- `fum-session-coherence` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md); izmenyon i ispoljzovan dlya proverki svyaznosti rabochej sessii i nizhnego raspolozheniya spravochnyikh blokov.
- `fum-md-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-markdown/SKILL.md); ispoljzovan dlya obnovleniya sluzhebnyikh recency-metok i indeksa Markdown-fajlov.
- `fum-planning-registry` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md); ispoljzovan dlya peresborki i proverki mashinno chitayemogo planovogo reyestra.
- `fum-obsidian-graph-recency` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md); ispoljzovan dlya peresborki teplovoj kartyi `.obsidian/graph.json` posle obnovleniya Markdown-recency.
- `fum-smoke-check` - versiya zadayotsya Git-istoriyej [lokaljnoj avtomatizacii](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md); ispoljzovan dlya itogovogo lokaljnogo smoke-check repozitoriya.
- `zsh` 5.9 - versiya proverena komandoj `zsh --version`; ispoljzovan kak shell dlya komand.
- `git` 2.54.0 Apple Git-156 - versiya proverena komandoj `git --version`; ispoljzovan dlya proverki sostoyaniya, prosmotra diff, staging i kommita.
- `rg` 15.1.0 - versiya proverena komandoj `rg --version`; ispoljzovan dlya poiska po repozitoriyu.
- `python3` 3.14.6 - versiya proverena komandoj `python3 --version`; ispoljzovan dlya mekhanicheskogo perenosa spravochnyikh blokov, lokaljnyikh testov i proverochnyikh skriptov.
- Sistemnyiye utilityi macOS - otdeljnyiye versii ne raskryivalisj standartnyim sposobom; ispoljzovanyi `sed`, `awk`, `find`, `sort`, `tail`, `wc` i `date` bez sokhraneniya privatnogo mashinnogo sostoyaniya.

## Povliyal na fajlyi

- [.obsidian/graph.json](../../../../../.obsidian/graph.json)
- [AGENTS.md](../../AGENTS.md)
- [Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md](../../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md)
- [Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md](../../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md)
- [Voprosyi/2026-06-22_07-40-59_MSK_granicyi-kosmicheskoj-avtonomii-FUM.md](../../Voprosyi/2026-06-22_07-40-59_MSK_granicyi-kosmicheskoj-avtonomii-FUM.md)
- [Voprosyi/2026-06-22_07-51-48_MSK_granicyi-vlasti-uzlov-FUM.md](../../Voprosyi/2026-06-22_07-51-48_MSK_granicyi-vlasti-uzlov-FUM.md)
- [Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md](../../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md)
- [Voprosyi/2026-06-22_08-14-25_MSK_konflikt-avtonomii-i-ustojchivosti-FUM.md](../../Voprosyi/2026-06-22_08-14-25_MSK_konflikt-avtonomii-i-ustojchivosti-FUM.md)
- [Voprosyi/2026-06-22_08-22-06_MSK_razlicheniye-issledovateljskikh-statusov-FUM.md](../../Voprosyi/2026-06-22_08-22-06_MSK_razlicheniye-issledovateljskikh-statusov-FUM.md)
- [Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md](../../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md)
- [Voprosyi/2026-06-26_12-19-03_MSK_abstrakciya-urovnej-nablyudayemoj-vselennoj-FUM.md](../../Voprosyi/2026-06-26_12-19-03_MSK_abstrakciya-urovnej-nablyudayemoj-vselennoj-FUM.md)
- [Glossarij/README.md](../../Glossarij/README.md)
- [Glossarij/napravleniye-proyektirovaniya-i-razvitiya-FUM.md](../../Glossarij/napravleniye-proyektirovaniya-i-razvitiya-FUM.md)
- [Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md](../../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
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
- [Zhurnal/2026-06-25_18-59-22_MSK.md](../2026-06-25_18-59-22_MSK/otchyot.md)
- [Zhurnal/2026-06-25_19-18-28_MSK.md](../2026-06-25_19-18-28_MSK/otchyot.md)
- [Zhurnal/2026-06-25_19-23-10_MSK.md](../2026-06-25_19-23-10_MSK/otchyot.md)
- [Zhurnal/2026-06-25_19-34-12_MSK.md](../2026-06-25_19-34-12_MSK/otchyot.md)
- [Zhurnal/2026-06-25_19-50-33_MSK.md](../2026-06-25_19-50-33_MSK/otchyot.md)
- [Zhurnal/2026-06-26_09-55-41_MSK.md](../2026-06-26_09-55-41_MSK/otchyot.md)
- [Zhurnal/2026-06-26_10-26-06_MSK.md](../2026-06-26_10-26-06_MSK/otchyot.md)
- [Zhurnal/2026-06-26_10-34-02_MSK.md](../2026-06-26_10-34-02_MSK/otchyot.md)
- [Zhurnal/2026-06-26_10-47-01_MSK.md](../2026-06-26_10-47-01_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-05-03_MSK.md](../2026-06-26_11-05-03_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-13-48_MSK.md](../2026-06-26_11-13-48_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-24-11_MSK.md](../2026-06-26_11-24-11_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-39-57_MSK.md](../2026-06-26_11-39-57_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-47-21_MSK.md](../2026-06-26_11-47-21_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-52-42_MSK.md](../2026-06-26_11-52-42_MSK/otchyot.md)
- [Zhurnal/2026-06-26_11-58-26_MSK.md](../2026-06-26_11-58-26_MSK/otchyot.md)
- [Zhurnal/2026-06-26_12-05-01_MSK.md](../2026-06-26_12-05-01_MSK/otchyot.md)
- [Zhurnal/2026-06-26_12-19-03_MSK.md](../2026-06-26_12-19-03_MSK/otchyot.md)
- [Zhurnal/2026-06-29_10-59-18_MSK.md](../2026-06-29_10-59-18_MSK/otchyot.md)
- [Zhurnal/2026-06-29_11-53-44_MSK.md](../2026-06-29_11-53-44_MSK/otchyot.md)
- [Zhurnal/2026-06-29_12-32-43_MSK.md](../2026-06-29_12-32-43_MSK/otchyot.md)
- [Zhurnal/2026-06-29_12-44-23_MSK.md](../2026-06-29_12-44-23_MSK/otchyot.md)
- [Zhurnal/2026-06-29_17-50-10_MSK.md](../2026-06-29_17-50-10_MSK/otchyot.md)
- [Zhurnal/2026-06-29_18-32-13_MSK.md](../2026-06-29_18-32-13_MSK/otchyot.md)
- [Zhurnal/2026-06-29_19-05-53_MSK.md](../2026-06-29_19-05-53_MSK/otchyot.md)
- [Zhurnal/2026-07-01_11-34-46_MSK.md](../2026-07-01_11-34-46_MSK/otchyot.md)
- [Zhurnal/2026-07-01_12-11-27_MSK.md](../2026-07-01_12-11-27_MSK/otchyot.md)
- [Zhurnal/2026-07-01_13-32-17_MSK.md](../2026-07-01_13-32-17_MSK/otchyot.md)
- [Zhurnal/2026-07-01_13-44-13_MSK.md](../2026-07-01_13-44-13_MSK/otchyot.md)
- [Zhurnal/2026-07-01_14-02-57_MSK.md](../2026-07-01_14-02-57_MSK/otchyot.md)
- [Zhurnal/2026-07-01_14-12-17_MSK.md](../2026-07-01_14-12-17_MSK/otchyot.md)
- [Zhurnal/2026-07-01_14-31-25_MSK.md](../2026-07-01_14-31-25_MSK/otchyot.md)
- [Zhurnal/2026-07-01_14-58-32_MSK.md](../2026-07-01_14-58-32_MSK/otchyot.md)
- [Zhurnal/2026-07-01_15-08-04_MSK.md](../2026-07-01_15-08-04_MSK/otchyot.md)
- [Zhurnal/2026-07-01_15-19-31_MSK.md](../2026-07-01_15-19-31_MSK/otchyot.md)
- [Zhurnal/2026-07-01_15-35-24_MSK.md](../2026-07-01_15-35-24_MSK/otchyot.md)
- [Zhurnal/2026-07-01_15-51-24_MSK.md](../2026-07-01_15-51-24_MSK/otchyot.md)
- [Zhurnal/2026-07-01_15-59-05_MSK.md](../2026-07-01_15-59-05_MSK/otchyot.md)
- [Zhurnal/2026-07-01_16-19-24_MSK.md](../2026-07-01_16-19-24_MSK/otchyot.md)
- [Zhurnal/2026-07-01_16-40-36_MSK.md](../2026-07-01_16-40-36_MSK/otchyot.md)
- [Zhurnal/2026-07-01_16-46-04_MSK.md](../2026-07-01_16-46-04_MSK/otchyot.md)
- [Zhurnal/2026-07-01_16-53-59_MSK.md](../2026-07-01_16-53-59_MSK/otchyot.md)
- [Zhurnal/2026-07-01_17-03-14_MSK.md](../2026-07-01_17-03-14_MSK/otchyot.md)
- [Zhurnal/2026-07-01_21-07-58_MSK.md](otchyot.md)
- [Zhurnal/README.md](../README.md)
- [Zaprosyi/2026-07-01_17-03-14_MSK.md](../2026-07-01_17-03-14_MSK/zapros.md)
- [Zaprosyi/2026-07-01_21-07-58_MSK.md](zapros.md)
- [Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md](../../Indeksyi/markdown-fajlyi-po-vremeni-redaktirovaniya.md)
- [Instrumentyi/README.md](../../Instrumentyi/README.md)
- [Instrumentyi/fum-session-coherence/SKILL.md](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)
- [Instrumentyi/fum-session-coherence/scripts/check-session-coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py)
- [Instrumentyi/fum-session-coherence/tests/test_check_session_coherence.py](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_check_session_coherence.py)
- [Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
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
- [Planirovaniye/README.md](../../Planirovaniye/README.md)
- [Planirovaniye/dorozhnaya-karta.md](../../Planirovaniye/dorozhnaya-karta.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/02-avtomatizacii-i-yazyik.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/02-avtomatizacii-i-yazyik.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/04-modeljnaya-sreda-i-planirovaniye.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/06-evolyucionnyiye-cepochki-i-otbor.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/06-evolyucionnyiye-cepochki-i-otbor.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/08-fizicheskiye-i-daljniye-konturyi.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/08-fizicheskiye-i-daljniye-konturyi.md)
- [Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/README.md](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/README.md)
- [Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)

## Chto sdelano

Spravochnyiye bloki proiskhozhdeniya perenesenyi vniz v proizvodnyikh Markdown-dokumentakh pamyati: otkryityikh voprosakh, zhurnalakh, planovyikh materialakh, indeksakh, opisaniyakh, reyestre instrumentov i svyazannyikh fajlakh. Dlya adresnyikh opisanij yavno primenena deklarativnaya avtomatizaciya [Postroyeniye opisaniya FUM dlya adresata](../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md): smyislovoj tekst sokhranyon, a struktura peresobrana pod novyij nizhnij format istochnikov.

Pravilo rasshireno v [AGENTS.md](../../AGENTS.md): proizvodnyiye Markdown-dokumentyi dolzhnyi nachinatjsya s soderzhaniya, a `Источники требований`, `Источники`, `Опорные документы`, `Опорные материалы`, `Внешний материал`, `Затронутая документация` i analogichnyiye spravochnyiye bloki razmesjhayutsya posle osnovnogo soderzhaniya pered `FUM-MD-RECENCY`.

Avtomatizaciya [fum-session-coherence](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md) poluchila TDD-proverku verkhnikh spravochnyikh blokov, chtobyi novyiye ili zatronutyiye fajlyi ne vozvrasjhalisj k prezhnemu formatu. Planovoye predlozheniye o rasprostranenii nizhnego formata na planirovaniye i opisaniya pereneseno v istoriyu vyipolnennyikh.

## Proverki

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - proshlo posle dobavleniya proverki: 8 testov.
- Proverochnyij Python-prokhod po proizvodnyim Markdown-fajlam vne `Запросы/` i `Источники/` podtverdil otsutstviye spravochnyikh blokov srazu posle zagolovka.
- Proverochnyij Python-prokhod podtverdil, chto posle pervogo nizhnego spravochnogo bloka do `FUM-MD-RECENCY` ne nachinayetsya novyij soderzhateljnyij razdel `##`.
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py` - proshlo; obnovlenyi sluzhebnyiye recency-metki i indeks Markdown-fajlov.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo; planovyij JSON-reyestr peresobran.
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json` - proshlo.
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py` - proshlo; teplovaya karta `.obsidian/graph.json` peresobrana posle obnovleniya recency.
- `git diff --check` - proshlo.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-01_21-07-58_MSK.md` - proshlo.
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-01_21-07-58_MSK.md` - proshlo: 14 shagov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e9120f3c8ff63b5f5f616c33f84ea2b3ab9ff79eb00f0e87a53ce516848ff868 -->
<!-- FUM-MD-RECENCY:END -->
