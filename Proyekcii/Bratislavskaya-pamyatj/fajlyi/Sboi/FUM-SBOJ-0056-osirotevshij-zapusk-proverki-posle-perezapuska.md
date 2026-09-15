+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0056"
"статус" = "активна"
+++
# Perezapusk ostavlyayet vyipolnyayusjhuyusya zapisj proverki bez ogranichennogo vosstanovleniya

## Nablyudayemyij sboj

Posle perezapuska upravlyayemaya proverochnaya sessiya nedostupna, a sokhranyonnaya zapisj ostayotsya vyipolnyayusjhejsya s neizvestnyimi iskhodom i dliteljnostjyu. V tekusjhem konture net prinyatogo sposoba zavershitj imenno takoye sostoyaniye bez vyidumyivaniya rezuljtata; shtatnoye zakryitiye prezhnego otchyota ostayotsya zablokirovannyim.

## Granica povtoreniya

Obsjhaya mera — proveryayemoye ogranichennoye vosstanovleniye osirotevshej zapisi s sokhraneniyem neizvestnyikh znachenij i pervonachaljnogo dokazateljstva. Istoricheskoye proyavleniye otnositsya k prezhnim skhemam, novoye — k fum.test-run.v3. Primenimostj prezhnej realizacii k v3/v4 yesjhyo dolzhna byitj ustanovlena. Istoricheskij nomer FUM-SBOJ-0020 nizhe kvalificirovan tochnyim kommitom; nyineshnyaya kartochka 0020 o CF-Ray yavlyayetsya drugoj susjhnostjyu i ne poglosjhayetsya.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0020/PROYAVLENIYE-0001 v 62f3d8db20ec9ea5abb57b0cf090a4a3630402c6 | [Istoricheskaya kartochka](https://github.com/fum-lab/fum/blob/62f3d8db20ec9ea5abb57b0cf090a4a3630402c6/Сбои/FUM-СБОЙ-0020-блокировка-закрытия-отчёта-осиротевшей-записью-проверки.md), zapusk №27 b32ea17b-df41-436a-9738-a624e0105e0e | Poterya upravlyayusjhej sessii posle nachaljnoj atomarnoj zapisi prepyatstvuyet zakryitiyu otchyota. | Prezhnyaya ogranichennaya procedura sokhranyala rekonstruiruyemyij original, null iskhod i vremya, osnovaniye vosstanovleniya. |
| FUM-SBOJ-0056/PROYAVLENIYE-0001 | [Zapisj №10 f687f3df](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-44-12_MSK_обновить-поколение-по-прежней-политике/материалы/запуски-проверок/10_f687f3df-8532-4008-83af-9d01b4b4b793.json) | Sostoyaniye vyipolnyayetsya, kod i dliteljnostj null; upravlyayemaya sessiya nedostupna posle perezapuska. | Iskhodnaya zapisj sokhranena bez izmeneniya; novyij etap poluchil svoj zhurnal. Staryij otchyot ne zakryit, sistemnoye ustraneniye ne vyipolneno. |

Dva proyavleniya poschitanyi s sokhraneniyem ikh iskhodnyikh lokaljnyikh nomerov; dopolniteljnyiye nablyudeniya odnoj zapisi povtorno ne uchityivayutsya. Otsutstviye nablyudayemogo processa ili Unknown process id ne dokazyivayet zaversheniya vsekh dochernikh processov OS.

## Ozhidaniye i klassifikaciya

Poterya upravlyayusjhego kanala ne dolzhna trebovatj poddeljnogo uspeshnogo iskhoda libo bessrochno isklyuchatj ogranichennoye vosstanovleniye uchyota. Nablyudyon probel vosstanovleniya tekusjhego proverochnogo kontura; prichina samogo perezapuska ne ustanovlena.

## Mekhanizm i sistemnoye ustraneniye

Prezhnij mekhanizm dlya v1/v2 treboval tochnyij UUID, ozhidayemyij khyesh iskhodnyikh bajtov i yavnoye prinyatiye operatorom neopredelyonnosti; sokhranyal originaljnuyu skhemu i rekonstruiruyemyij khyesh, osnovaniye i neizvestnyiye znacheniya. Tochnyij povtor byil bezdejstviyem, nesovpadeniye zapresjhalo zapisj. Perenos primenimyikh invariantov v tekusjhiye v3/v4 poruchayetsya svyazannomu shagu. Staryiye FIFO, pul i vetochnyij avtokonvejyer polnomochij ne dayut i ne vozvrasjhayutsya.

## Svyazannyiye shagi

- [FUM-STEP-0204](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0204-vosstanavlivatj-osirotevshiye-zapisi-proverok.md): osnovaniye — FUM-SBOJ-0056/PROYAVLENIYE-0001 i kvalificirovannoye istoricheskoye proyavleniye. Shag aktiven; otdeljnyij novyij etap Zhurnala sam po sebe sboj ne zakryivayet.

## Kriterii zakryitiya

Osirotevshaya zapisj tekusjhej skhemyi poluchayet vosproizvodimoye ogranichennoye vosstanovleniye s adresuyemyim iskhodnyim dokazateljstvom; neizvestnyiye dliteljnostj i iskhod ostayutsya neizvestnyimi. Povtor ne izmenyayet uzhe vosstanovlennoye sostoyaniye, oshibochnaya identichnostj ili izmenyonnyiye bajtyi zapresjhayut zapisj. Zavershyonnyiye snimki i pozdnij otvet prezhnej obyortki ne mogut poteryatj iskhodnuyu istoriyu.

## Istochniki

- [Iskhodnaya mashinnaya zapisj](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-44-12_MSK_обновить-поколение-по-прежней-политике/материалы/запуски-проверок/10_f687f3df-8532-4008-83af-9d01b4b4b793.json).
- [Otchyot tekusjhego ogranichennogo vosstanovleniya](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_03-32-48_MSK_восстановить-передачу-форматов-после-перезапуска/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:8099426ca70383b4efcdfed272d8fd02e698dd2feae1c8318bd92bd597beb717 -->
<!-- FUM-MD-RECENCY:END -->
