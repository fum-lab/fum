+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0082"
"статус" = "устранена"
+++
# Utrata vlozhennogo URL pri povtore roditeljskogo snimka

## Nablyudayemyij sboj

Povtor snimka stranicyi Astra zamenil katalog roditelya celikom i udalil samostoyateljnyij vlozhennyij URL. Zatronut toljko novyij neopublikovannyij istochnik etoj zadachi; raneye otslezhivayemyiye materialyi ne izmenyalisj. Sinteticheskij test povtoril utratu.

## Granica povtoreniya

Samostoyateljnyij dochernij URL s sobstvennyim istochnikom i manifestom ne prinadlezhit soderzhimomu roditeljskogo otveta. Yego kopirovaniye i proverka dolzhnyi predshestvovatj yedinstvennomu atomarnomu obmenu. Ischeznuvshij marker rebyonka obyazan davatj otkaz, a ne razreshatj udaleniye.

## Proyavleniya


| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                       | Effekt                                               | Vosstanovleniye                                                                                                                                                                                                                                                                      |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0082/ПРОЯВЛЕНИЕ-0001` | [Otchyot reyestra podderzhki](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/отчёт.md) i otdeljnyiye mashinnyiye zapisi RED/GREEN. | Narushena trebuyemaya sokhrannostj istochnika do kommita. | Inventarj otdelyayet vlozhennyiye snimki; susjhestvuyusjhij roditelj vsegda proveryayetsya. Vlozhennyiye snimki validiruyutsya i kopiruyutsya v staging, konflikt ili povrezhdeniye zakryivayet zamenu otkazom. Zatem vyipolnyayetsya odin obmen direktorij. Sobstvennyij istochnik vosstanovlen novoj zagruzkoj. |

## Ozhidaniye i klassifikaciya

Podtverzhdyonnaya nedorabotka susjhestvuyusjhego istochnikovogo mekhanizma; gipoteticheskiye i ne nablyudavshiyesya polya ne obyyavlyayutsya ochisjhennyimi.

## Mekhanizm i sistemnoye ustraneniye

Inventarj otdelyayet vlozhennyiye snimki; susjhestvuyusjhij roditelj vsegda proveryayetsya. Vlozhennyiye snimki validiruyutsya i kopiruyutsya v staging, konflikt ili povrezhdeniye zakryivayet zamenu otkazom. Zatem vyipolnyayetsya odin obmen direktorij. Sobstvennyij istochnik vosstanovlen novoj zagruzkoj.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) aktualizirovan dannyim proyavleniyem: ispravleniye trebuyetsya dlya proverennogo vyipuska pervogo reyestra. Novyij otdeljnyij shag ne sozdayotsya.

## Kriterii zakryitiya

- Povtor roditelya sokhranyayet tochnyiye bajtyi rebyonka; nezavisimyiye manifestyi validnyi. Udaleniye manifesta rebyonka dayot otkaz bez izmeneniya tekusjhego dereva. Atomarnyij obmen i prezhniye otkaznyiye regressii sokhranenyi.
- Sobstvennaya regressiya meryi prokhodit vmeste s susjhestvuyusjhimi testami arkhivatora; smyislovyiye i licenzionnyiye ogranicheniya istochnikov sokhranyayutsya.

## Podtverzhdeniye ustraneniya

[Povtor 55 testov arkhivatora](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/материалы/запуски-проверок/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) zavershilsya kodom 0 posle sokhranyonnyikh sinteticheskikh RED i ispravlenij. Proverenyi tochnyiye nablyudavshiyesya polya, sokhrannostj publichnogo soderzhimogo, otkaz PDF, raspakovka gzip i sokhrannostj vlozhennogo snimka. Shirokaya priyomka pervogo reyestra otnositsya k STEP-0212; kartochka podtverzhdayet sobstvennuyu vosproizvedyonnuyu granicu.

Pri perenose sokhranyayetsya istoricheskoye podtverzhdeniye ukazannogo zapuska: chislo 55 otnositsya k yego naboru, a ne k boleye pozdnim regressiyam. Perenos kartochki ne yavlyayetsya novyim zapuskom proverki v prinimayusjhem dereve i ne rasshiryayet opisannuyu granicu ustraneniya.

## Istochniki

- [Komanda, utochneniya i soglasovaniye ID](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/запрос.md).
- [Obsjhij arkhivator](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).
- [Otkryityiye regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:11:13 MSK -->
<!-- content-sha256: sha256:a578cda23bfa389f5b7cef2b3c99f66e8e92d1df29fcd1de249f244318c00461 -->
<!-- FUM-MD-RECENCY:END -->
