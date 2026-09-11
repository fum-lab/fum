+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0063"
"статус" = "устранена"
+++
# Strogoye dekodirovaniye diagnosticheskogo vyivoda Swift

## Nablyudayemyij sboj

Python-sborsjhik metrik ostanovilsya na UnicodeDecodeError posle uzhe uspeshnogo uchtyonnogo Swift-testa. Oshibka kasayetsya chteniya sokhranyonnogo konsoljnogo loga, a ne vyipolneniya testa.

## Granica povtoreniya

Toljko izvlecheniye i otobrazheniye metrik iz dannogo diagnosticheskogo loga; pravilo strogogo chteniya iskhodnogo poljzovateljskogo JSONL etim sluchayem ne menyayetsya.

## Proyavleniya

### FUM-SBOJ-0063/PROYAVLENIYE-0001

0176: bajt 0xd0 v pozicii 6985 ne proshyol strogij UTF-8. Pervichnaya zapisj obyortki 11b055a5-6a79-4edf-ad5a-1ed5178b8721 sokhranila uspekh testa. Povtor chteniya loga cherez errors=replace pokazal 28 uspeshnyikh testov i metriki; Swift-test povtorno ne zapuskalsya.

## Ozhidaniye i klassifikaciya

Ozhidalosj poluchitj diagnosticheskiye metriki zavershyonnogo processa i sokhranitj yego fakticheskij iskhod. Narusheno izvlecheniye vyivoda; validnostj iskhodnogo koda i dannyikh testa ne oprovergnuta.

## Mekhanizm i sistemnoye ustraneniye

Dlya otobrazheniya primeneno chteniye sokhranyonnogo loga s zamenoj nevalidnyikh posledovateljnostej. Kod zaversheniya beryotsya iz iskhodnoj kvitancii, a ne iz ispravlennogo otobrazheniya. Iskhodnyij log sokhranyon.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Novyij shag ne trebuyetsya: ogranichennoye vosstanovleniye zaversheno. Obsjhaya avtomatizaciya obrabotki lyubyikh diagnosticheskikh potokov ne zayavlyayetsya.

## Kriterii zakryitiya

Povtor chteniya dayot nuzhnyiye metriki; iskhodnaya kvitanciya testa ostayotsya uspeshnoj; test i yego vkhod ne povtoryayutsya radi otobrazheniya.

## Podtverzhdeniye ustraneniya

Pervichnyij chunk d9a867 zavershyon kodom 0; sleduyusjhij 61142e soderzhit 28 testov, 5 naborov, 11,89 s i priznak zamenyi nevalidnogo UTF-8. Kvitanciya 16_e4a75510 podtverzhdayet posleduyusjhuyu sverku metrik i neizmennosti klona. Zakryitiye otnositsya k dannomu izvlecheniyu.

## Istochniki

[Otchyot paketnoj proverki 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-56-50_MSK_проверить-пакеты-FUMA-из-клона/отчёт.md)

[Tekusjhaya registraciya i proiskhozhdeniye](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:de920d4d7706dfaee4535d74dfe22971675291e7d9f489d96b1840a2eb654d97 -->
<!-- FUM-MD-RECENCY:END -->
