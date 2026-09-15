+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0065"
"статус" = "устранена"
+++
# Peredacha skaneru flaga drugogo instrumenta

## Nablyudayemyij sboj

Publikacionnomu skaneru 0176 peredan --korenj-repozitoriya vmesto podderzhannogo --repo-root; argparse zavershil zapusk kodom 2.

## Granica povtoreniya

Tochnyij argv dannogo skanera. Fajl najden praviljno; eto ne ugadyivaniye puti i ne SBOJ-0009.

## Proyavleniya

### FUM-SBOJ-0065/PROYAVLENIYE-0001

0176: posle uspeshnoj svyaznosti chunk 2416e6 vyidal unrecognized arguments: --korenj-repozitoriya. Kvitanciya 18_da376ef7 sokhranyayet kod 2. Korrektnyij otdeljnyij vyizov otrazhyon v 19_5f8fcc00.

## Ozhidaniye i klassifikaciya

Komanda dolzhna sootvetstvovatj fakticheskomu CLI. Nevernyij flag — oshibka vyizova, a ne narusheniye proverochnogo povedeniya skanera.

## Mekhanizm i sistemnoye ustraneniye

Vyizov ispravlen na --repo-root; skaner i politika ne izmenyalisj. Ispravlennyij zapusk vyipolnen cherez prezhnyuyu otchyotnuyu obyortku.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Novyij shag ne trebuyetsya; obyazateljstvo obsjhego generatora komand iz etoj oshibki ne vyivoditsya.

## Kriterii zakryitiya

Shtatnyij CLI prinimayet argumentyi i skaniruyet tot zhe podgotovlennyij vkhod bez narusheniya publikacionnoj chistotyi.

## Podtverzhdeniye ustraneniya

Kvitanciya 19_5f8fcc00-94de-47b2-8cda-39e892d59806: kod 0, 23,197485250 s. Pervyij otkaz sokhranyon. Vosstanovleniye ogranicheno etim argv i vkhodom.

## Istochniki

[Otchyot paketnoj proverki 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-56-50_MSK_проверить-пакеты-FUMA-из-клона/отчёт.md)

[Tekusjhaya registraciya i proiskhozhdeniye](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:f608b741fe06990038fa933afc477f775aa3251a65da81896fcd758c507e13f2 -->
<!-- FUM-MD-RECENCY:END -->
