+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0158"
"статус" = "активна"
+++
# Maskirovaniye oshibki podgotovki oshibkoj ochistki

## Nablyudayemyij sboj

V novoj realizacii izmeritelya isklyucheniye cleanup zamenyalo pervichnoye isklyucheniye konstruktora. Validnyij RED vosproizvyol RuntimeError vmesto ValueError.

## Granica povtoreniya

Odnovremennyij otkaz konstruktora i cleanup v izmeritele podgotovki Git-fiksturyi.

## Proyavleniya

### FUM-SBOJ-0158/PROYAVLENIYE-0001

[Otchyot J24](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md) sokhranyayet obstoyateljstva, iskhodyi i ogranicheniya.

## Ozhidaniye i klassifikaciya

Oshibka novoj realizacii, obnaruzhennaya read-only-revjyu do priyomki.

## Mekhanizm i sistemnoye ustraneniye

Sokhranyatj pervichnoye isklyucheniye i otdeljnyiye zapisi obeikh stadij. Ispravleniye proshlo adresnyiye testyi i realjnyij profilj; polnaya priyomka yesjhyo vperedi.

## Svyazannyiye shagi

[FUM-STEP-0232](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0232-izmeritj-stoimostj-podgotovki-proverok.md).

## Kriterii zakryitiya

Prinyatj ispravleniye s regressiyami dvojnogo otkaza i odinochnogo otkaza cleanup, povtornyim profilem i primenimyimi obsjhimi proverkami.

## Istochniki

- [Zapros](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/zapros.md) i [otchyot](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 02:30:45 MSK -->
<!-- content-sha256: sha256:b8e8e7dc43806b6a4e91cb8db7dd9a46335151a845ee669759572b15625ab8f8 -->
<!-- FUM-MD-RECENCY:END -->
