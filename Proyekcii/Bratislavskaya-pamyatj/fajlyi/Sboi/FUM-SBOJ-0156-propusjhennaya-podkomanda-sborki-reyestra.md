+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0156"
"статус" = "активна"
+++
# Propusjhennaya podkomanda sborki planovogo reyestra

## Nablyudayemyij sboj

V J22 korenj vyizval build-planning-registry.py s --repo-root bez obyazateljnoj podkomandyi build. Parser zavershilsya kodom 2 do sborki. Ispravlennyij vyizov s build i yavnyim output zavershilsya kodom 0. Eto oshibka vyizyivayusjhego, ne defekt reyestra.

## Granica povtoreniya

Toljko vyibor komandyi sborki planovogo reyestra. Sboj 0153 otnositsya k drugomu CLI; dokazannoj obsjhej profilaktiki poka net.

## Proyavleniya

### FUM-SBOJ-0156/PROYAVLENIYE-0001

[Otchyot etapa](../Zhurnal/2026-09-19_00-58-49_MSK_podklyuchitj-rannyuyu-proverku-polej-zhurnala/otchyot.md) sokhranyayet otkaz i vosstanovleniye. Tochnoye soobsjheniye parsera: invalid choice: '.' (choose from 'build', 'validate', 'sync-boxed-graph-source-hash'). Dliteljnostj otdeljno ne izmeryalasj.

## Ozhidaniye i mekhanizm

Povtoryayemaya komanda vyibirayetsya po tekusjhemu opisaniyu interfejsa, a ne ugadyivayetsya. Posle otkaza ispoljzovana uzhe sokhranyonnaya komanda iz postroitelya smoke-plana. Ustojchivoye primeneniye takogo istochnika yesjhyo ne obespecheno.

## Svyazannyiye shagi

[STEP0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) sokhranyayet dorabotku chelovecheskogo vkhoda povtoryayemyikh komand; ispravleniye odnoj stroki ne zakryivayet meru.

## Kriterii zakryitiya

Proveryayemyij sposob vyizova vyibirayet susjhestvuyusjhuyu podkomandu i obyazateljnyiye parametryi do effekta; sokhranyon regressionnyij scenarij propuska i praviljnogo zapuska. Tekusjhij uspekh sborki etogo sistemnogo kriteriya ne dokazyivayet.

## Istochniki

- [Zapros i razreshyonnyij obyyom](../Zhurnal/2026-09-19_00-58-49_MSK_podklyuchitj-rannyuyu-proverku-polej-zhurnala/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 01:10:33 MSK -->
<!-- content-sha256: sha256:98e9550f7922964a2c00133f07b35f3ab0c355c5ab1a8a7f34914e7d3d8fa52d -->
<!-- FUM-MD-RECENCY:END -->
