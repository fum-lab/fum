+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0083"
"статус" = "устранена"
+++
# Propusk raspakovki gzip pered izvlecheniyem HTML

## Nablyudayemyij sboj

Otvet Swift.org byil sokhranyon i prochitan kak tekst, khotya bajtyi soderzhali gzip; izvlecheniye ne davalo prigodnyikh uslovij. Do publikacii nevernoye svideteljstvo isklyucheno, praviljnyij otvet raspakovan i svyazan novyim nablyudeniyem.

## Granica povtoreniya

Podgotovka setevogo predstavleniya pered HTML-izvlecheniyem. Granica otlichayetsya ot ochistki sluzhebnyikh znachenij i ot sokhraneniya vlozhennyikh URL. Ispravleniye ne vyivoditsya iz rasshireniya adresa.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0083/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij RED](../Zhurnal/2026-09-11_14-52-06_MSK_sozdatj-reyestr-organizacij-podderzhki-FUM/materialyi/zapuski-proverok/33_da3295e0-773f-4d2c-8657-9234cffde49e.json) | Neprigodnoye predstavleniye oficialjnogo usloviya v neopublikovannoj podgotovke reyestra | Ispravlen obsjhij mekhanizm i vosstanovleno praviljnoye svideteljstvo do pervogo push |

## Ozhidaniye i klassifikaciya

Nablyudyonnaya nedorabotka susjhestvuyusjhego arkhivatora. Globaljnyij nomer vyidelen vladeljcem raspredelitelya v sokhranyonnoj komande; sobyitiye `907de935373a35df5c41c76db6954f04260eaa1eac58323330a131ff3614d429`. Eto ne gipoteza o soderzhanii programmyi podderzhki.

## Mekhanizm i sistemnoye ustraneniye

Signatura gzip raspakovyivayetsya pered opredeleniyem formata, dekodirovaniyem i ochistkoj. Sinteticheskij szhatyij HTML dayot chitayemyiye publichnyiye usloviya i ochisjhennyiye sluzhebnyiye polya.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) vklyuchayet etu neobkhodimuyu meru pervogo vyipuska. [FUM-SBOJ-0084](FUM-SBOJ-0084-propusk-proverki-PDF-pered-izvlecheniyem-HTML.md) svyazan scenariyem szhatogo PDF: raspakovka i posleduyusjhij otkaz na PDF proveryayutsya sovmestno, obe meryi samostoyateljnyi.

## Kriterii zakryitiya

- Signatura gzip raspakovyivayetsya pered opredeleniyem formata, dekodirovaniyem i ochistkoj. Sinteticheskij szhatyij HTML dayot chitayemyiye publichnyiye usloviya i ochisjhennyiye sluzhebnyiye polya.
- Szhatyij PDF s oshibochnyim HTTP-tipom HTML raspoznayotsya posle raspakovki i otklonyayetsya; vyikhodnoj katalog ostayotsya pustyim.
- Regressii susjhestvuyusjhego arkhivatora prokhodyat; oshibochnoye predstavleniye ne vyidayotsya za prochitannyij oficialjnyij istochnik.

## Podtverzhdeniye ustraneniya

[55 testov susjhestvuyusjhego i novogo naborov](../Zhurnal/2026-09-11_16-12-17_MSK_zavershitj-priyomku-reyestra-podderzhki-FUM/materialyi/zapuski-proverok/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) proshli, vklyuchaya `test_сжатый_PDF_отклоняется_после_распаковки`. Pervonachaljnyij RED ostayotsya otdeljnoj zapisjyu predyidusjhego etapa. Ispravleniya vklyuchenyi v checkpoint fbf05a051e1e5d24706f7e5c5605dd028559f970, sovmestnaya granica proverena posleduyusjhim etapom. Priyomka vsego reyestra uchityivayetsya otdeljno v STEP-0212.

## Istochniki

- [Realjnyiye komandyi i rezerv nomera](../Zhurnal/2026-09-11_16-12-17_MSK_zavershitj-priyomku-reyestra-podderzhki-FUM/zapros.md).
- [Otchyot pervonachaljnogo ispravleniya](../Zhurnal/2026-09-11_14-52-06_MSK_sozdatj-reyestr-organizacij-podderzhki-FUM/otchyot.md).
- [Obsjhij mekhanizm](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).
- [Otkryityiye regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:22:35 MSK -->
<!-- content-sha256: sha256:d605de2d7c34c5193e812fe089b447aef1baf76bf5f6eafd7a65b21434452120 -->
<!-- FUM-MD-RECENCY:END -->
