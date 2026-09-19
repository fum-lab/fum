+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0157"
"статус" = "активна"
+++
# Nekanonicheskij zagolovok novogo Zhurnala

## Nablyudayemyij sboj

CLI sozdaniya Zhurnala otklonil zagolovok s Git-fikstur vmesto Git fikstur do zapisi. Ispravlennyij zagolovok prinyat.

## Granica povtoreniya

Toljko nesootvetstviye zagolovka determinirovannomu imeni papki pri sozdanii novogo etapa.

## Proyavleniya

### FUM-SBOJ-0157/PROYAVLENIYE-0001

[Otchyot J24](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md) sokhranyayet obstoyateljstva, iskhodyi i ogranicheniya.

## Ozhidaniye i klassifikaciya

Oshibka vyizyivayusjhego; rannij otkaz ozhidayem, nevernyij vkhod ne ozhidayem.

## Mekhanizm i sistemnoye ustraneniye

Poluchatj zagolovok iz togo zhe preobrazovaniya, chto formiruyet imya papki, i proveryatj paru do sozdaniya.

## Svyazannyiye shagi

[FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md).

## Kriterii zakryitiya

Para zagolovka i imeni formiruyetsya yedinyim proveryayemyim vkhodom; regressiya pokazyivayet rannij otkaz nesootvetstviya.

## Istochniki

- [Zapros](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/zapros.md) i [otchyot](../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 02:30:45 MSK -->
<!-- content-sha256: sha256:ca1c617f6538ae598795b07cd821233432373dea1ff7e48152948f9fc1d31084 -->
<!-- FUM-MD-RECENCY:END -->
