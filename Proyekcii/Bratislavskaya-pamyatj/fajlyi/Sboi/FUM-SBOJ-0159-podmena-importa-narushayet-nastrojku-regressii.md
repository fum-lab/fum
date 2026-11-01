+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0159"
"статус" = "активна"
+++
# Podmena importa narushayet nastrojku regressii

## Nablyudayemyij sboj

Pervaya regressiya dvojnogo otkaza ne doshla do proveryayemogo dejstviya: podmena globaljnogo importlib.import_module narushila razresheniye sleduyusjhego strokovogo patch.

## Granica povtoreniya

Posledovateljnaya strokovaya nastrojka patch posle zamenyi obsjhego importlib.import_module.

## Proyavleniya

### FUM-SBOJ-0159/PROYAVLENIYE-0001

[Otchyot J24](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md) sokhranyayet obstoyateljstva, iskhodyi i ogranicheniya.

## Ozhidaniye i klassifikaciya

Oshibka testovoj podgotovki; takoj RED ne podtverzhdayet defekt predmetnogo koda.

## Mekhanizm i sistemnoye ustraneniye

Ispoljzovatj uzhe importirovannyij obyyekt i patch.object. Posle ispravleniya podgotovki vyipolnenyi nastoyasjhij RED, GREEN i profilj.

## Svyazannyiye shagi

[FUM-STEP-0232](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0232-izmeritj-stoimostj-podgotovki-proverok.md).

## Kriterii zakryitiya

Sokhranitj oshibochnyij zapusk otdeljno ot validnogo RED; prinyatj proverennyij test i ispravleniye izmeritelya bez podmenyi svideteljstv.

## Istochniki

- [Zapros](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/zapros.md) i [otchyot](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 02:30:45 MSK -->
<!-- content-sha256: sha256:44a59d9ec5d4c05a4f4c0ce20f9bbd61e6e21044a6108d4eefe68e2a0539a213 -->
<!-- FUM-MD-RECENCY:END -->
