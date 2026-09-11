+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0058"
"статус" = "устранена"
+++
# Oshibochnaya obratnaya para trebovanij pri priyome

## Nablyudayemyij sboj

Vkhod priyoma perenosa 0207 obyyavlyal svyazj trebovanij 0066 i 0027 simmetrichnoj paroj «dopolnyayet/dopolnyayet». Dejstvuyusjhij slovarj trebuyet obratnoye «dopolnyayetsya». Nastoyasjhij sborsjhik otklonil vkhod; prezhnyaya predvariteljnaya ocenka soglasovannosti byila oshibochnoj.

## Granica povtoreniya

Nevernaya obratnaya raznovidnostj uzhe obyyavlennogo tipizirovannogo otnosheniya dvukh trebovanij. Syuda ne otnositsya Markdown-ssyilka glossariya na otkryityij vopros, okhvachennaya 0029. Otkaz priyoma i probel vosstanovleniya chastichnoj ustanovki razlichayutsya. Ispravleniye analogichnogo vkhoda 0208 do primeneniya ne sozdayot vtorogo nablyudyonnogo otkaza.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0058/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij otkaz i korrekciya](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md): 2026-09-11 03:09:34 UTC, `missing inverse semantic relation: FUM-REQ-0027 дополняет FUM-REQ-0066`, kod 2. | Priyom ostayotsya negotovyim; novyiye vneshniye polnomochiya ne poyavlyayutsya. | Slovarj i obe storonyi perechitanyi, sokhranyonnaya korrekciya menyayet rovno obratnoye otnosheniye 0027 k 0066. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka vkhodnyikh dannyikh otnositeljno FUM-PRAVILO-000129: obe storonyi otnosheniya dolzhnyi soderzhatj soglasovannuyu pryamuyu i obratnuyu paru. Validator obnaruzhil dejstviteljnyij defekt i ne priznayotsya neispravnyim.

## Mekhanizm i sistemnoye ustraneniye

Vruchnuyu podgotovlennyij vkhod povtoryal pryamoye otnosheniye v obratnoj storone. Ogranichennoye vosstanovleniye ispoljzuyet dejstvuyusjhij slovarj i sokhranyayemuyu komandu ispravleniya, posle chego nastoyasjhij reyestr proveryayet paru. Iskhodnoye namereniye, nomera i pervyij otkaz ostayutsya adresuyemyimi. Avtomaticheskoye postroyeniye vsekh budusjhikh smyislovyikh otnoshenij ne zayavlyayetsya.

## Svyazannyiye shagi

Otdeljnyij STEP ne trebuyetsya: ogranichennaya korrekciya i proverka uzhe vyipolnenyi v khode 0201. Ostavshiyesya samostoyateljnyiye kriterii vsego 0201 ne obyyavlyayutsya vyipolnennyimi. Kartochka sokhranyayet diagnostiku, a ne vyidayot novoye porucheniye.

## Kriterii zakryitiya

Para 0027 i 0066 sootvetstvuyet slovaryu; prezhnyaya oshibochnaya simmetriya vosproizvodimo otvergayetsya. Ispravleniye ne zamenyayet iskhodnoye namereniye ili nomera; povtor v drugom processe sokhranyayet effektivnyiye bajtyi i gotovnostj. Granica ogranichena etim klassom ispravleniya otnosheniya, a ne universaljnoj bezoshibochnostjyu podgotovki vkhodov.

## Podtverzhdeniye ustraneniya

[Adresnyij nabor](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_ispravleniya_priyoma.py) soderzhit scenarij `test_реальная_обратная_пара_исправляется_без_замены_исходного_намерения`: nastoyasjhij reyestr, sokhraneniye iskhodnyikh polej i otkaza, tochnyij povtor drugim processom. [Zapusk № 5](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/materialyi/zapuski-proverok/5_6ed7e8ae-55b2-4f34-8215-0c66ece1272e.json) zavershyon kodom 0; [otchyot](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md) podtverzhdayet 11 testov. Realjnaya korrekciya `13b600d88ef1603c929e469f358d774aaeb339592f76604031823834032185c8` vernula `готов: true` i prezhniye 0207/0066. Otricateljnoye i polozhiteljnoye svideteljstva sokhranenyi; validator ne oslablen.

## Istochniki

- [Tekusjhij zapros](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).
- [Adresnoye podtverzhdeniye i chastnyiye pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).
- [Dopustimyiye iskhodyi kartochki](../Pravila/agentov/planirovaniye-trebovaniya-voprosyi-i-sboi.md).
- [Otchyot priyoma 0207](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:b972883e670d2fe7181cfaf3e424efebecacf39ad98be980a486e3b0d3d07459 -->
<!-- FUM-MD-RECENCY:END -->
