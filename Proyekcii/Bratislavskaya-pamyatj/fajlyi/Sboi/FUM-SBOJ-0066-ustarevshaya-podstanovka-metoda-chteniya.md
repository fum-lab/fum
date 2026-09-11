+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0066"
"статус" = "активна"
+++
# Ustarevshij mock posle perekhoda chteniya na tochnyiye bajtyi

## Nablyudayemyij sboj

Test schital vyizovyi Path.read_text posle perekhoda proveryayemogo guard na Path.read_bytes i nablyudal 0 vmesto ozhidayemogo 1.

## Granica povtoreniya

Odin kontrakt testa povtornogo chteniya osnovaniya i odin dvukhstrochnyij hunk. Pervichnoye nablyudeniye 0177 i povtoryi 0176 i 0175 — tri proyavleniya; polnaya popyitka i adresnyij RED vnutri 0176 — odna lokalizaciya vtorogo proyavleniya. Perenos v fuma otdeljnyim proyavleniyem ne schitayetsya.

## Proyavleniya

### FUM-SBOJ-0066/PROYAVLENIYE-0001

0177: otkaz 10_a4fff42d lokalizovan kak ustarevsheye nablyudeniye read_text; posle perekhoda mock na read_bytes obnovlyonnyiye vkhodyi proshli 49 proverok, kvitanciya 13_70998c19.

### FUM-SBOJ-0066/PROYAVLENIYE-0002

0176: polnyij otkaz 20_3cb41946 i adresnyij RED 21_3d51450f podtverdili tot zhe mekhanizm. Perenesenyi rovno dve stroki prezhnego ispravleniya; adresnaya kvitanciya 22_b7418825 uspeshna.

### FUM-SBOJ-0066/PROYAVLENIYE-0003

0175: iskhodnyij M `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d` sokhranil prezhnij mock. Povtornyij polnyij zapusk R3 `e3f59efa-3149-4efe-8d2d-ac6569a6f55d` zavershilsya kodom 1 za 850,348437917 s: odin otkaz iz 238 testov poslednego nabora, `0 != 1`. Eto nablyudeniye zadachi `01a09047-faa1-7370-83f7-cdfc8f9943a6`, ne Linux. Adresnyij RED `3b88a61f-24f3-4054-9e61-9930f18e87f8` i profilj — lokalizaciya togo zhe proyavleniya, ne novyiye proyavleniya.

Posle perenosa yedinstvennogo dvukhstrochnogo hunk iz `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95` tochnyij GREEN `4770dff5-38f3-4f8c-b1e4-d3d066c38efa` zavershilsya kodom 0 za 0,101170708 s. Vse 13 testov adresnogo modulya s profilem proshli: `45f6bfca-221b-477f-9ea6-fdc39d1a1b07`, 1,504784917 s. Production i oba prezhnikh utverzhdeniya testa sokhranenyi. [Diagnostika R3](../Zhurnal/2026-09-11_15-50-49_MSK_prinyatj-sovmestimostj-FUMA-cherez-otchyot-v3/materialyi/diagnostika-chteniya-osnovaniya.md) khranit tochnoye proiskhozhdeniye i izmereniya.

Nomer 0003 soglasovan raspredelitelem posle sverki istoricheskikh versij i dostupnyikh worktree, s isklyucheniyem privatnyikh rezervov uchastnikov. Prezhniye 0001 i 0002 sokhranenyi iz zakreplyonnoj L `a728283474931eda71cd581ca5429121124ba3f6`. Povtor v M vozvrasjhayet kartochku v aktivnoye sostoyaniye do prinyatiya ispravleniya i yego integracii v master; prezhneye podtverzhdeniye ustraneniya ostayotsya istoricheski ogranichennyim.

## Ozhidaniye i klassifikaciya

Test dolzhen nablyudatj realjno ispoljzuyemyij metod, sokhranyaya ozhidaniye rovno odnogo chteniya povtornogo osnovaniya. Nulevoj schyotchik nepraviljnoj podstanovki ne dokazyivayet defekt production guard.

## Mekhanizm i sistemnoye ustraneniye

V a76969ce644feb82d720825bbc0e5e71cbd192b0, perenose fuma 33f6e4c9b1d4d295195bc7727216d6b3e80182d0 i 0176 soglasovanyi dve stroki mock. Ozhidaniye 1 i povtornaya proverka posle izmeneniya istochnika sokhranenyi; production guard radi etogo ispravleniya ne menyalsya.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Tochnoye osnovaniye aktualizacii susjhestvuyusjhego [FUM-STEP-0177](https://github.com/fum-lab/fum/blob/a728283474931eda71cd581ca5429121124ba3f6/Планирование/карточки-шагов/✅-FUM-STEP-0177-возвращать-необработанные-сообщения-пользователя.md) — `FUM-СБОЙ-0066/ПРОЯВЛЕНИЕ-0002`; zerkaljnaya zapisj sokhranena v istochnikakh shaga. Eto utochneniye proiskhozhdeniya proverennogo ogranichennogo vosstanovleniya.

Novogo STEP net. Realizaciya 0177 ostayotsya samostoyateljnyim prinyatyim rezuljtatom; novoye porucheniye na yeyo peredelku etim diagnozom ne sozdayotsya.

Dlya tekusjhego `FUM-СБОЙ-0066/ПРОЯВЛЕНИЕ-0003` aktualizirovan [FUM-STEP-0175](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md): prinyatj tochnuyu deljtu v M i proveritj sleduyusjhij kandidat. Obratnaya ssyilka sokhranyayet tot zhe nomer. Eto prodolzheniye susjhestvuyusjhej integracii, novyij STEP ne sozdayotsya.

## Kriterii zakryitiya

Tot zhe test nablyudayet read_bytes, proveryayet schyotchik 1 i izmeneniye istochnika; vse tri proyavleniya imeyut sokhranyonnyiye otkaz i uspeshnoye vosstanovleniye. Dlya proyavleniya 0003 dopolniteljno trebuyetsya finaljnaya priyomka paketa i integraciya yego tochnogo kommita v master.

## Podtverzhdeniye ustraneniya

0177: kvitanciya 13_70998c19, kod 0, 51,548278959 s. 0176: 22_b7418825, kod 0, 1,367696833 s; otchyot ukazyivayet 13 uspeshnyikh testov. Posleduyusjhij standartnyij dopusk 25_3a114a2c takzhe uspeshen. Eto ustraneniye konkretnogo rassoglasovaniya mock, ne obesjhaniye sovmestimosti vsekh budusjhikh metodov.

## Istochniki

[Pervoye ispravleniye v 0177](https://github.com/fum-lab/fum/blob/6b1860591deb1d669f5f5ae1bd03336170fb8fce/Журнал/2026-09-11_01-25-54_MSK_включить-остаток-сообщений-в-допуск/отчёт.md) [Otchyot postavki 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/отчёт.md)

[Istoricheskaya registraciya i proiskhozhdeniye](https://github.com/fum-lab/fum/blob/a728283474931eda71cd581ca5429121124ba3f6/Журнал/2026-09-11_09-36-55_MSK_сохранить-оставшуюся-диагностику-приёма/запрос.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:57:51 MSK -->
<!-- content-sha256: sha256:c48989e0e93776c8706c486542e10dbb0ee39f3666c7d43b5ebd31765285422e -->
<!-- FUM-MD-RECENCY:END -->
