+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0054"
"статус" = "устранена"
+++
# Novaya politika proyekcii otklonyala vladeniye prezhnim pokoleniyem versii 2

## Nablyudayemyij sboj

Shtatnoye primeneniye rasshirennoj proyekcii proveryalo svoyo susjhestvuyusjheye pokoleniye novoj politikoj i otklonyalo prezhnij khyesh. Otkaz vosproizvedyon pri neizmennom kanone i pri dobavlenii formatov prilozheniya.

## Granica povtoreniya

Odin mekhanizm, dva scenariya iskhodnogo RED. Dopuskayetsya perekhod toljko ot odnoj polnostjyu zakreplyonnoj prezhnej politiki. Osirotevshij proverochnyij zapusk ne zakryivayetsya etoj meroj i otnositsya k FUM-SBOJ-0056.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0054/PROYAVLENIYE-0001 | [RED №3 37179fad](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-44-12_MSK_обновить-поколение-по-прежней-политике/материалы/запуски-проверок/3_37179fad-9739-4878-b0fa-f7be891365c4.json) | Oba dopustimyikh scenariya perekhoda otklonenyi, kod 1. | Proveritj vladeniye prezhnej polnoj politikoj, zatem novoye pokoleniye tekusjhej. |

## Ozhidaniye i klassifikaciya

Prinimayemoye prezhneye pokoleniye dolzhno podtverzhdatj vladeniye svoyej politikoj; novoye pokoleniye prokhodit nezavisimuyu stroguyu proverku tekusjhej. Nablyudyon defekt sovmestimosti instrumentaljnogo perekhoda.

## Mekhanizm i sistemnoye ustraneniye

Funkciya politika_dlya_dokazateljstva_vladeniya dopuskayet toljko odin obyichnyij fajl polnoj prezhnej politiki s SHA-256 9f262153c9de986270cec76ad3c37da34c99ace0c187474ba8a1bc736222220a. Neizvestnyij khyesh zapresjhyon, itogovaya proverka ostayotsya na novoj politike. Iskhodnoye pokoleniye fiksturyi polucheno iz aeae18cb146a34563ff39c84d9bc5ef59fffab91; dostavka — 582fae9778073ffedcdf347509887c84a4334e27.

## Svyazannyiye shagi

Otdeljnyij novyij shag ne trebuyetsya: ogranichennyij perekhod realizovan i integrirovan v FUM-STEP-0176.

## Kriterii zakryitiya

Oba dopustimyikh perekhoda prokhodyat. Neizvestnaya politika, povrezhdyonnyij vyikhod, chuzhoj fajl, izmeneniye rezhima ili polnyikh metadannyikh otklonyayutsya s sokhraneniyem prezhnego dereva. Otsutstvuyusjhij, izmenyonnyij ili simvolicheskij fajl prezhnego kontrakta zapresjhyon.

## Podtverzhdeniye ustraneniya

Pervyij GREEN №4 0712aad8-f857-4b8e-8856-aea558318142 i [itogovyij GREEN №7 a3f17b43](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-44-12_MSK_обновить-поколение-по-прежней-политике/материалы/запуски-проверок/7_a3f17b43-7fb2-43ad-8f1f-206484874e61.json) imeyut kod 0; itogovyij nabor soderzhit 14 testov. Polnyij dopusk №25 3a114a2c-cb0f-459d-9f13-9d8f40e7c07c podtverzhdayet integraciyu, ne podmenyaya neizvestnyij iskhod zapuska FUM-SBOJ-0056.

## Istochniki

- [Otchyot perekhoda](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-44-12_MSK_обновить-поколение-по-прежней-политике/отчёт.md).
- [Otchyot dostavki](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:e0f3131f9d43d2d3aa1439fe34018204ddda13573f77a4ea37ff8025c415c778 -->
<!-- FUM-MD-RECENCY:END -->
