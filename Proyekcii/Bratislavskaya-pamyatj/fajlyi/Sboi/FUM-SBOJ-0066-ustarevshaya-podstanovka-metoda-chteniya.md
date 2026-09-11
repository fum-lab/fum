+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0066"
"статус" = "устранена"
+++
# Ustarevshij mock posle perekhoda chteniya na tochnyiye bajtyi

## Nablyudayemyij sboj

Test schital vyizovyi Path.read_text posle perekhoda proveryayemogo guard na Path.read_bytes i nablyudal 0 vmesto ozhidayemogo 1.

## Granica povtoreniya

Odin kontrakt testa povtornogo chteniya osnovaniya i odin dvukhstrochnyij hunk. Pervichnoye nablyudeniye 0177 i povtor 0176 — dva proyavleniya; polnaya popyitka i adresnyij RED vnutri 0176 — odna lokalizaciya vtorogo proyavleniya. Perenos v fuma otdeljnyim proyavleniyem ne schitayetsya.

## Proyavleniya

### FUM-SBOJ-0066/PROYAVLENIYE-0001

0177: otkaz 10_a4fff42d lokalizovan kak ustarevsheye nablyudeniye read_text; posle perekhoda mock na read_bytes obnovlyonnyiye vkhodyi proshli 49 proverok, kvitanciya 13_70998c19.

### FUM-SBOJ-0066/PROYAVLENIYE-0002

0176: polnyij otkaz 20_3cb41946 i adresnyij RED 21_3d51450f podtverdili tot zhe mekhanizm. Perenesenyi rovno dve stroki prezhnego ispravleniya; adresnaya kvitanciya 22_b7418825 uspeshna.

## Ozhidaniye i klassifikaciya

Test dolzhen nablyudatj realjno ispoljzuyemyij metod, sokhranyaya ozhidaniye rovno odnogo chteniya povtornogo osnovaniya. Nulevoj schyotchik nepraviljnoj podstanovki ne dokazyivayet defekt production guard.

## Mekhanizm i sistemnoye ustraneniye

V a76969ce644feb82d720825bbc0e5e71cbd192b0, perenose fuma 33f6e4c9b1d4d295195bc7727216d6b3e80182d0 i 0176 soglasovanyi dve stroki mock. Ozhidaniye 1 i povtornaya proverka posle izmeneniya istochnika sokhranenyi; production guard radi etogo ispravleniya ne menyalsya.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Tochnoye osnovaniye aktualizacii susjhestvuyusjhego [FUM-STEP-0177](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md) — `FUM-СБОЙ-0066/ПРОЯВЛЕНИЕ-0002`; zerkaljnaya zapisj sokhranena v istochnikakh shaga. Eto utochneniye proiskhozhdeniya proverennogo ogranichennogo vosstanovleniya.

Novogo STEP net. Realizaciya 0177 ostayotsya samostoyateljnyim prinyatyim rezuljtatom; novoye porucheniye na yeyo peredelku etim diagnozom ne sozdayotsya.

## Kriterii zakryitiya

Tot zhe test nablyudayet read_bytes, proveryayet schyotchik 1 i izmeneniye istochnika; oba proyavleniya imeyut sokhranyonnyiye otkaz i uspeshnoye vosstanovleniye.

## Podtverzhdeniye ustraneniya

0177: kvitanciya 13_70998c19, kod 0, 51,548278959 s. 0176: 22_b7418825, kod 0, 1,367696833 s; otchyot ukazyivayet 13 uspeshnyikh testov. Posleduyusjhij standartnyij dopusk 25_3a114a2c takzhe uspeshen. Eto ustraneniye konkretnogo rassoglasovaniya mock, ne obesjhaniye sovmestimosti vsekh budusjhikh metodov.

## Istochniki

[Pervoye ispravleniye v 0177](https://github.com/fum-lab/fum/blob/6b1860591deb1d669f5f5ae1bd03336170fb8fce/Журнал/2026-09-11_01-25-54_MSK_включить-остаток-сообщений-в-допуск/отчёт.md) [Otchyot postavki 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/отчёт.md)

[Tekusjhaya registraciya i proiskhozhdeniye](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:59:08 MSK -->
<!-- content-sha256: sha256:1777301c5a751aaa5b2b7f06fe47954a3f549ea4916828ea6909b0a8a5772219 -->
<!-- FUM-MD-RECENCY:END -->
