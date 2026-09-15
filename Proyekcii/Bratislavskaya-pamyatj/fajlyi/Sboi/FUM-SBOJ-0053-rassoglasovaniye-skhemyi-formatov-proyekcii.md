+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0053"
"статус" = "устранена"
+++
# Rasshireniye formatov proyekcii ostavilo prezhniye konstantyi JSON Schema

## Nablyudayemyij sboj

Posle rasshireniya formatov versii 2 novyiye spiski prisutstvovali v kontrakte i Python-validatore, no otsutstvovali v tryokh const skhemyi plana. Pervyij adresnyij RED vyiyavil devyatj nesovpadenij.

## Granica povtoreniya

Odin defekt soglasovannosti konechnyikh spiskov. Tri spiska proveryalisj protiv kontrakta, fakticheskogo plana i manifesta; devyatj proverochnyikh nesovpadenij ne oznachayut devyatj proyavlenij. Sovmestimostj prezhnej politiki vyidelena v FUM-SBOJ-0054.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0053/PROYAVLENIYE-0001 | [RED №1 d311fbae](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-30-48_MSK_согласовать-схему-форматов-приложения/материалы/запуски-проверок/1_d311fbae-dc4f-4eb4-8c73-75a95c8ad0a0.json) | Devyatj nesovpadenij mashinnogo kontrakta; kod 1. | Soglasovatj tri const i proveritj fakticheskiye predstavleniya. |

## Ozhidaniye i klassifikaciya

Opublikovannyiye predstavleniya formatov dolzhnyi soglasovyivatjsya. Propusjhena chastj izmeneniya mashinnogo kontrakta; eto nablyudyonnaya nedorabotka, a adresnyij RED vosproizvodit yeyo.

## Mekhanizm i sistemnoye ustraneniye

Ispravlenyi const rasshirenij koda, prochikh tochnyikh rasshirenij i tochnyikh putej v skheme plana. Susjhestvuyusjhiye ssyilki $ref manifesta razreshayutsya regressiyej, kotoraya sravnivayet vse predstavleniya. Ispravleniye sokhraneno v 0f534e49fa3c8abdbb1b71aa7b1a29bb8bf1389a.

## Svyazannyiye shagi

Otdeljnyij novyij shag ne trebuyetsya: ogranichennoye ispravleniye i regressiya dostavlenyi v ramkakh FUM-STEP-0176.

## Kriterii zakryitiya

Konechnyiye spiski sovpadayut vo vsekh nazvannyikh predstavleniyakh; zakryityij nabor mashinnyikh polej i tri zakreplyonnyikh fajla versii 1 sokhranenyi. Proverka proizvoljnyikh JSON Schema universaljnyim dvizhkom syuda ne vkhodit.

## Podtverzhdeniye ustraneniya

[GREEN №2 0640c773](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-30-48_MSK_согласовать-схему-форматов-приложения/материалы/запуски-проверок/2_0640c773-3d24-4fc2-98e0-50ce29803043.json) zavershilsya kodom 0: tri adresnyikh testa. Regressiya — test_konstantyi_skhem_sovpadayut_s_formatami_kontrakta_plana_i_manifesta. Polnyij integracionnyij zapusk №25 3a114a2c-cb0f-459d-9f13-9d8f40e7c07c dopolnyayet adresnoye dokazateljstvo.

## Istochniki

- [Otchyot ispravleniya](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-30-48_MSK_согласовать-схему-форматов-приложения/отчёт.md).
- [Otchyot dostavki](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:e326ed17177a0b1df890e91b564a944be890be9fa05075bacfa37dc308b6a8b4 -->
<!-- FUM-MD-RECENCY:END -->
