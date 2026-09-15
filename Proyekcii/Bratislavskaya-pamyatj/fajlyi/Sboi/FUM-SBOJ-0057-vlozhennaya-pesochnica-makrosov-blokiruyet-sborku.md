+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0057"
"статус" = "устранена"
+++
# Vlozhennaya pesochnica makrosov SwiftUI blokirovala priyomochnuyu Xcode-sborku

## Nablyudayemyij sboj

Pervyij Xcode build publichnogo chistogo klona pod vneshnej pesochnicej zavershilsya kodom 65. swift-plugin-server poluchil sandbox_apply: Operation not permitted; otsutstviye realizacii makrosa State byilo sledstviyem.

## Granica povtoreniya

Prepyatstviye podtverzhdeno v priyomochnoj srede macOS 27 arm64, Xcode 27 beta, Swift 6.4. Ispravleniye platformyi, podpisi, vsekh konfiguracij pesochnic i drugikh sred ne podtverzhdayetsya. Eto drugaya granica, chem oshibki codesign.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0057/PROYAVLENIYE-0001 | [Zapusk №7 60187cde](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/материалы/запуски-проверок/7_60187cde-7b40-4c12-a45b-e14f131532e9.json) | Kod 65; priyomochnaya sborka ne zavershena. | Sovmestimyij vyizov frontend v novom DerivedData pri sokhranyonnoj vneshnej granice chteniya. |

## Ozhidaniye i klassifikaciya

Makrosyi dolzhnyi ispolnyatjsya pri sokhranenii vneshnego zapreta chteniya prezhnikh katalogov. Nablyudena nesovmestimostj vlozhennyikh pesochnic v proverochnoj srede; pervyij otkaz ne byil namerennyim TDD RED.

## Mekhanizm i sistemnoye ustraneniye

Lokaljnaya spravka frontend podtverdila -disable-sandbox. Parametr OTHER_SWIFT_FLAGS="-Xfrontend -disable-sandbox" peredan toljko priyomochnomu vyizovu; povtor ispoljzoval novyij DerivedData i sokhranil vneshnyuyu pesochnicu. Iskhodniki, proyekt i sistemnyiye nastrojki ne izmenyalisj; usloviye vosproizvedeniya zapisano v rukovodstve.

## Svyazannyiye shagi

Otdeljnyij novyij shag dlya prinyatoj sredyi ne trebuyetsya: sovmestimyij vyizov proveren i opisan v FUM-STEP-0176.

## Kriterii zakryitiya

Tot zhe opublikovannyij iskhodnyij kommit v novom DerivedData dayot BUILD SUCCEEDED i kod 0 pri sokhranyonnom zaprete chteniya prezhnikh katalogov. Iskhodnyij kod 65 i usloviye sovmestimosti sokhranyayutsya otdeljno.

## Podtverzhdeniye ustraneniya

[Povtor №8 6f568460](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/материалы/запуски-проверок/8_6f568460-1aa2-4350-8277-ea9054f14462.json) zavershilsya kodom 0 na iskhodnikakh 9c39c9b3fde83c4ce11ba101897c1298c68d436d. [Svideteljstvo sborki](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/материалы/сборка-приложения-из-клона.json) i [svideteljstvo vneshnej granicyi](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/материалы/чистый-клон.json) sokhranenyi v 6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95.

## Istochniki

- [Otchyot proverki](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/отчёт.md).
- [Rukovodstvo vosproizvedeniya](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Приложения/FUMA/проверка-приложения.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:e40f7fb849befa146baa79a37c135b862b543be4e12ce00318b4881037146785 -->
<!-- FUM-MD-RECENCY:END -->
