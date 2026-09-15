+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0055"
"статус" = "устранена"
+++
# Pustoj override v pervom teste runner dopustil zapusk ustanovlennogo helper

## Nablyudayemyij sboj

Pervyij RED runner pri pustom override vyibral susjhestvovavshij ustanovlennyij helper. Process poluchil pustoj stdin; instrumentaljnyiye komandyi, GUI i runtime-zapisi ne nablyudalisj.

## Granica povtoreniya

Narushena zayavlennaya izolyaciya odnogo proverochnogo zapuska. Namerennyij RED perenosimosti sam po sebe ne yavlyayetsya otdeljnyim sboyem; rannij zapusk neljzya zadnim chislom obyyavitj sinteticheskim. Posleduyusjhiye RED №3 i №10 ne podtverzhdayut povtornogo vyizova nastoyasjhego helper.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0055/PROYAVLENIYE-0001 | [Zapusk №2 f34e61c3](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-45-23_MSK_адаптировать-приложение-FUM-для-монорепозитория/материалы/запуски-проверок/2_f34e61c3-80ea-4d4d-b1cb-d954a0bbdaa2.json) | Proverka vyishla za granicu podstavnyikh processov, kod 1. | Ubratj neyavnyij ustanovlennyij putj i ispravitj izolirovannuyu fiksturu. |

## Ozhidaniye i klassifikaciya

Proverka perenosimosti ispoljzuyet toljko podstavnoj helper i Swift vo vremennoj oblasti. Eto oshibka izolyacii proverki; dopolniteljno ustranyon neyavnyij vyibor prezhnej ustanovki v runner.

## Mekhanizm i sistemnoye ustraneniye

INSTALLED_HELPER poluchayet toljko yavno peredannyij FUM_MCP_APP_HELPER. Fikstura zadayot yavno otsutstvuyusjhij helper, podstavnoj Swift i vremennyiye katalogi sborki i ispolneniya; proveryayetsya svezhaya sborka vmesto prezhnego binarnika. Yavnyij vremennyij helper proveryayetsya otdeljno. Ispravleniye — 9d39f45a344af3d99d8402c8e7631e58e239c6fa; proverennyij publichnyij iskhodnik — 9c39c9b3fde83c4ce11ba101897c1298c68d436d.

## Svyazannyiye shagi

Otdeljnyij novyij shag ne trebuyetsya dlya ustranyonnoj granicyi; ispravleniye vyipolneno v FUM-STEP-0176.

## Kriterii zakryitiya

Neyavnyij vyibor prezhnej ustanovki udalyon iz runner. Ispravlennaya fikstura iz chuzhogo cwd poluchayet rezuljtat svoyej svezhej podstavnoj sborki; yavnyij podstavnoj helper rabotayet bez sborki. Ogranichennoye dokazateljstvo ne utverzhdayet otsutstviya lyubyikh vozmozhnyikh vneshnikh effektov prezhnego zapuska.

## Podtverzhdeniye ustraneniya

Izolirovannyiye RED №3 f16aa2e1-7e07-4ded-a44b-679973222a5d i №10 f05673db-9720-48d2-a748-1a26e4579bbd predshestvuyut [GREEN №11 dabe685e](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-45-23_MSK_адаптировать-приложение-FUM-для-монорепозитория/материалы/запуски-проверок/11_dabe685e-12bc-4224-b16a-beb428ee6d78.json). Itogovaya peredacha fiksiruyet GREEN №35 ab4bcb6d-f37a-4f42-8f37-1687edd6342c, 12 Python-testov. Otdeljnyij GREEN imenno s pustyim override ne zapisan: udaleniye etogo fallback podtverzhdayetsya chteniyem runner, a GREEN proveryayet ispravlennuyu izolirovannuyu fiksturu.

## Istochniki

- [Otchyot adaptacii](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-45-23_MSK_адаптировать-приложение-FUM-для-монорепозитория/отчёт.md).
- [Otchyot integracii](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-13-44_MSK_интегрировать-поставку-FUMA/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:2efd1f47f455946162950835dc42d825734ec64c46a62360a1bb8cd6800d83b6 -->
<!-- FUM-MD-RECENCY:END -->
