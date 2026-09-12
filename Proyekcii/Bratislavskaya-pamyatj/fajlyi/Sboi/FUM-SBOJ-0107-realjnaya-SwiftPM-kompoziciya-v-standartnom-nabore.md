+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0107"
"статус" = "устранена"
+++
# Nastoyasjhaya SwiftPM-kompoziciya popala v standartnyij nabor

## Nablyudayemyij sboj

Standartnyij dokumentacionnyij smoke-check zapustil unasledovannyij Python-test s nastoyasjhimi SwiftPM-paketami alpha i beta. Sborka AlphaTests zavershilasj, no zagruzchik testovogo processa ne nashyol Testing.framework i zavershilsya signalom 5. Vneshnyaya polnaya popyitka zavershilasj kodom 1 na shage 14 iz 24; posleduyusjhiye shagi ne vyipolnyalisj.

## Granica povtoreniya

Kartochka otnositsya k nevernomu vyiboru zhivoj Swift-kompozicii standartnyim naborom. Otsutstviye ustanovlennogo Testing.framework — nablyudyonnaya granica sredyi, kotoruyu eto ispravleniye ne ustranyayet. Mekhanizm otlichayetsya ot vyibora ustanovlennogo helper v FUM-SBOJ-0055. Yedinstvennoye podtverzhdyonnoye proyavleniye ne obyyavlyayetsya regulyarnyim povtorom.

## Proyavleniya

| Nomer                            | Istochnik i dokazateljstvo                                                                                                                                            | Effekt                                        | Vosstanovleniye                                                          |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- | ----------------------------------------------------------------------- |
| FUM-SBOJ-0107/PROYAVLENIYE-0001      | [Zapusk №22](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/zapuski-proverok/22_f3c332ac-8031-49c7-ad03-9b0c32c7859a.json) | Polnaya priyomka otkazala za 689,634982916 s.     | Otdeljnyij integracionnyij katalog, vyibirayemyij toljko polnyim profilem.      |

## Ozhidaniye i klassifikaciya

Pravilo FUM-PRAVILO-000189 zapresjhayet Swift test/build/lint v standartnom konture. Popadaniye zhivogo testa cherez obsluzhivayusjhij Python-nabor narushalo tu zhe granicu. Eto defekt izolyacii testovogo nabora.

## Mekhanizm i sistemnoye ustraneniye

Telo nastoyasjhej proverki sokhraneno kak vspomogateljnyij metod; otdeljnyij integracionnyij modulj vyizyivayet yego rovno odnim testom. Toljko polnoye obnaruzheniye dobavlyayet katalogi `интеграционные-тесты`. Katalog i fajlyi proveryayutsya na simvolicheskiye ssyilki; obyichnyij polozhiteljnyij perechenj ne rasshiryayetsya. Pervichnoye isklyucheniye prokhodit cherez integracionnyij adapter. Unasledovannyij propusk bez Swift ne schitayetsya dokazateljstvom integracii.

## Svyazannyiye shagi

Ogranichennaya mera vyibora nabora realizovana i adresno proverena v tekusjhej rabote priyoma napravlenij. Novyij shag dlya etoj ustranyonnoj granicyi ne trebuyetsya. Obsjhaya finaljnaya priyomka i daljnejsheye polozhiteljnoye sinteticheskoye pokryitiye sokhranyayutsya v otkryitom otchyote tekusjhej postoyannoj zadachi.

## Kriterii zakryitiya

Obyichnyij loader ne obnaruzhivayet nastoyasjhij test; polnyij plan vyibirayet integracionnyij modulj, standartnyij — isklyuchayet. Loader integracionnogo modulya soderzhit rovno odnu proverku; otkaz yeyo tela ne prevrasjhayetsya v uspekh. Simvolicheskiye ssyilki kataloga i fajla otklonyayutsya. Kriterij ogranichen vyiborom nabora i ne utverzhdayet ispravnostj nastoyasjhego Swift toolchain.

## Podtverzhdeniye ustraneniya

Adresnyiye RED №23/24 predshestvuyut [GREEN pyati proverok №25](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/zapuski-proverok/25_65d3cfba-7095-4881-80d3-1f6ee2f18809.json). RO-sverka ustanovila, chto sistemnaya ssyilka predka mogla skryivatj otkaz fajla v №25. Posle fizicheskogo razresheniya kornej i utochneniya ozhidayemoj oshibki [dva adresnyikh testa №30](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/zapuski-proverok/30_3a5f2173-5af0-438b-b360-99d07a1e49aa.json) nezavisimo podtverdili obe vetvi. [Profilj №27](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/profili/granica-SwiftPM-naborov.json) soderzhit tri nezavisimyiye fiksturyi po 114 naborov, tochnyiye SHA realizacii i iskhodyi. Izmereniya ne obosnovali algoritmicheskuyu optimizaciyu; proverki putej sokhranenyi. Otkaz profiljnoj fiksturyi №26 ostayotsya v istorii. Povtornyij standartnyij full posle izmeneniya yesjhyo ne vyipolnen.

Pervichnyij proveryavshijsya HEAD — c613ccf88926046f951cdcaa5205a8cda2aabe31. Privatnyij stdout iskhodnoj polnoj popyitki: 1138733 bajta, SHA-256 c548bf4b7e5e1b33462494c8457ed0f3d04e91209337c1fc1fa61ba1974aa33b; stderr: 81 bajt, SHA-256 4d569c19e3949afa7d7357fa47982fcdbc951b64914134cedb00e19d7dfbec84. Fizicheskiye puti i polnyij vyivod ne publikuyutsya.

## Istochniki

- [Zapros i tochnaya oblastj](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/zapros.md).
- [Otkryityij otchyot s ostatkom](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/otchyot.md).
- [Dolgovechnaya vyidacha nomera](../Zhurnal/2026-09-12_00-13-57_MSK_dobavitj-otlozhennyiye-naznacheniya-napravlenij/materialyi/svideteljstva/nomer-sboya-granicyi-SwiftPM.json).
- [Kontrakt nabora](../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:09:54 MSK -->
<!-- content-sha256: sha256:272ad1c78e4b738ce9b098e8cbdbad2ec57463831fd59fb385f366dccc618b81 -->
<!-- FUM-MD-RECENCY:END -->
