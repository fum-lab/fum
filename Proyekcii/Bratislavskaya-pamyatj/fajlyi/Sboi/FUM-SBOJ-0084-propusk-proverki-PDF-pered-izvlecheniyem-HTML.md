+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0084"
"статус" = "устранена"
+++
# Propusk proverki PDF pered izvlecheniyem HTML

## Nablyudayemyij sboj

Oficialjnyij adres Astra bez rasshireniya vernul PDF, kotoryij HTML-mekhanizm pervonachaljno pyitalsya sokhranitj kak stranicu. Pered publikaciyej telo sokhraneno kak PDF i izvlecheno otdeljno s iskhodnyim formatom.

## Granica povtoreniya

Podgotovka setevogo predstavleniya pered HTML-izvlecheniyem. Granica otlichayetsya ot ochistki sluzhebnyikh znachenij i ot sokhraneniya vlozhennyikh URL. Ispravleniye ne vyivoditsya iz rasshireniya adresa.

## Proyavleniya


| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                    | Effekt                                                                               | Vosstanovleniye                                                                    |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0084/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij RED](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/материалы/запуски-проверок/28_0e7ebabb-b41a-48ba-9634-8a22bc4557a6.json) | Neprigodnoye predstavleniye oficialjnogo usloviya v neopublikovannoj podgotovke reyestra | Ispravlen obsjhij mekhanizm i vosstanovleno praviljnoye svideteljstvo do pervogo push |

## Ozhidaniye i klassifikaciya

Nablyudyonnaya nedorabotka susjhestvuyusjhego arkhivatora. Globaljnyij nomer vyidelen vladeljcem raspredelitelya v sokhranyonnoj komande; sobyitiye `6d4d6d6c335e9381e8f75a982914c08e32befb769e73e659f1a7579bd4252b97`. Eto ne gipoteza o soderzhanii programmyi podderzhki.

## Mekhanizm i sistemnoye ustraneniye

Posle raspakovki signatura PDF ili obyyavlennyij Content-Type application/pdf zakryivayut HTML-vkhod otkazom do pervoj zapisi snimka. Otdeljnoye sokhraneniye PDF i izvlecheniye teksta ostayutsya obyazateljnyimi.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) vklyuchayet etu neobkhodimuyu meru pervogo vyipuska. [FUM-SBOJ-0083](FUM-SBOJ-0083-propusk-raspakovki-gzip-pered-izvlecheniyem-HTML.md) svyazan scenariyem szhatogo PDF: raspakovka i posleduyusjhij otkaz na PDF proveryayutsya sovmestno, obe meryi samostoyateljnyi.

## Kriterii zakryitiya

- Posle raspakovki signatura PDF ili obyyavlennyij Content-Type application/pdf zakryivayut HTML-vkhod otkazom do pervoj zapisi snimka. Otdeljnoye sokhraneniye PDF i izvlecheniye teksta ostayutsya obyazateljnyimi.
- Szhatyij PDF s oshibochnyim HTTP-tipom HTML raspoznayotsya posle raspakovki i otklonyayetsya; vyikhodnoj katalog ostayotsya pustyim.
- Regressii susjhestvuyusjhego arkhivatora prokhodyat; oshibochnoye predstavleniye ne vyidayotsya za prochitannyij oficialjnyij istochnik.

## Podtverzhdeniye ustraneniya

[55 testov susjhestvuyusjhego i novogo naborov](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/материалы/запуски-проверок/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) proshli, vklyuchaya `test_сжатый_PDF_отклоняется_после_распаковки`. Pervonachaljnyij RED ostayotsya otdeljnoj zapisjyu predyidusjhego etapa. Ispravleniya vklyuchenyi v checkpoint fbf05a051e1e5d24706f7e5c5605dd028559f970, sovmestnaya granica proverena posleduyusjhim etapom. Priyomka vsego reyestra uchityivayetsya otdeljno v STEP-0212.

Pri perenose sokhranyayetsya istoricheskoye podtverzhdeniye ukazannogo zapuska: chislo 55 otnositsya k yego naboru, a ne k boleye pozdnim regressiyam. Perenos kartochki ne yavlyayetsya novyim zapuskom proverki v prinimayusjhem dereve i ne rasshiryayet opisannuyu granicu ustraneniya.

## Istochniki

- [Realjnyiye komandyi i rezerv nomera](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/запрос.md).
- [Otchyot pervonachaljnogo ispravleniya](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/отчёт.md).
- [Obsjhij mekhanizm](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).
- [Otkryityiye regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:11:13 MSK -->
<!-- content-sha256: sha256:d3ab078b1ad3fc0a6cfbb966388fda12531dfaa36ebdf0b68c70e77cf75b435e -->
<!-- FUM-MD-RECENCY:END -->
