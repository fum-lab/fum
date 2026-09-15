+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0020"
"статус" = "устранена"
+++
# Publikaciya sluzhebnogo CF-Ray v snimke istochnika

Obsjhij HTML-arkhivator udalyal znacheniya `Set-Cookie`, no sokhranyal sluzhebnyij identifikator otveta `CF-Ray`. Importiruyemyij snimok russkogo perevoda CC0 poetomu soderzhal trace-id konkretnogo HTTP-otveta vmeste s PoP-kodom, khotya eti dannyiye ne yavlyayutsya soderzhaniyem istochnika.

## Nablyudayemyij sboj

Vo vremya semanticheskogo sliyaniya licenzionnoj vetki read-only-audit obnaruzhil v `response.headers.txt` neotredaktirovannoye znacheniye `CF-Ray`. Otchyot ob izvlechenii pri etom zayavlyal toljko redakciyu cookie i ne fiksiroval publikacionnuyu ochistku sluzhebnogo identifikatora.

## Granica povtoreniya

Proyavleniye voznikayet pri arkhivirovanii ustojchivogo HTML-URL ili ChatGPT-share, yesli otdeljnaya realizaciya ochistki propuskayet sluzhebnyiye HTTP-identifikatoryi libo ikh prodolzheniya. Pomimo `CF-Ray` podtverzhdenyi `X-Request-ID`, `Request-Context` i `X-MS-Middleware-Request-ID`; obsjhaya mera — yedinaya tochnaya ochistka oboikh vkhodov. Syuda ne otnosyatsya soderzhateljnyiye i vosproizvodimyiye metadannyiye otveta, takiye kak `Content-Type`, `Content-Language` ili `Last-Modified`.

Proyavleniye 0004 dobavlyayet tochnyiye zagolovki `X-Forwarded-For` i `Trace-Id`. Sluzhebnyij token tela otnositsya k FUM-SBOJ-0081, a oshibochnoye raspoznavaniye pokhozhikh HTML-atributov — k otdeljnomu FUM-SBOJ-0120.

## Proyavleniya


| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                                                                       | Effekt                                                                                | Vosstanovleniye                                                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0001` | [Importirovannyij snimok russkogo perevoda CC0](../Istochniki/URL/https/wiki.creativecommons.org/wiki/Publicdomain/zero/1.0/LegalText_-Russian-35eacbaf5d6489ab/response.headers.txt) do redakcii soderzhal sluzhebnoye znacheniye `CF-Ray`.                                                                                                                                           | V publikacionnuyu pamyatj popadal trace-id otdeljnogo setevogo obrasjheniya.               | Redaktirovatj zagolovok obsjhim arkhivatorom i ochistitj importiruyemyij snimok.                                              |
| `FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0002` | [Otchyot priyoma inzhenernoj modeli](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/otchyot.md): v novyikh snimkakh obnaruzhenyi neochisjhennyiye CF-Ray, X-Request-ID, Request-Context i X-MS-Middleware-Request-ID.                                                                                                                                               | Povtor nepolnoj ochistki HTTP-metadannyikh; obnaruzhen do kommita.                        | Obsjhaya ochistka dvukh arkhivatorov, adresnyij RED/GREEN i ochistka chetyiryokh snimkov.                                           |
| `FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0003` | [Adresnyij audit reyestra podderzhki](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/отчёт.md): X-Trace-Id i X-SP-CRID, takzhe drugiye podtverzhdyonnyiye sluzhebnyiye polya otvetov; znacheniya ne publikuyutsya.                                                                         | Propusk tochnoj ochistki novyikh zagolovkov obnaruzhen do kommita.                         | Obsjhaya funkciya rasshirena, sinteticheskij RED/GREEN i ochistka sokhranyonnyikh otvetov.                                         |
| `FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0004` | [Issledovaniye podderzhki 14.09.2026](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/otchyot.md): v otvete Sponsr obnaruzhenyi sluzhebnyiye `X-Forwarded-For` i `Trace-Id`; [pervichnyij RED](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/zapuski-proverok/11_0923b331-220c-4b2a-867b-6189447319b4.json). | Do publikacii obnaruzhen povtor propuska HTTP-metadannyikh; znacheniya ne vosproizvodyatsya. | Obsjhaya funkciya rasshirena na oba tochnyikh imeni i prodolzheniya; otvet Sponsr zanovo ustanovlen shtatnyim arkhivatorom bez seti. |

## Ozhidaniye i klassifikaciya

Navyik materialov zaprosov trebuyet udalyatj sluzhebnyiye request-id i drugiye znacheniya, ne yavlyayusjhiyesya soderzhaniyem materiala. Sokhraneniye `CF-Ray` raskhodilosj s etoj publikacionnoj granicej i yavlyayetsya nedorabotkoj obsjhego arkhivatora.

## Mekhanizm i sistemnoye ustraneniye

Funkciya ochistki zagolovkov raspoznavala toljko `Set-Cookie`. Teperj ona takzhe raspoznayot `CF-Ray` bez uchyota registra i zamenyayet yego znacheniye stabiljnoj publikacionno chistoj pometkoj. Generiruyemyij otchyot ob izvlechenii yavno fiksiruyet etu redakciyu, a importirovannyij snimok privedyon k tomu zhe kontraktu.

Pri proyavlenii 0004 podtverzhdyon propusk dvukh imyon v obsjhej funkcii `redact_headers`; oni vklyuchenyi v registronezavisimuyu ochistku vmeste s prodolzheniyami. Eto dopolneniye obsjhego mekhanizma, a ne toljko ispravleniye sokhranyonnogo otveta.

## Svyazannyiye shagi

Pervoye proyavleniye ustraneno bez otdeljnogo shaga. Vtoroye proyavleniye `FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0002` svyazano s zavershyonnyim [FUM-STEP-0151](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0151-obyyedinitj-ochistku-sluzhebnyikh-zagolovkov-arkhivatorov.md).

Tretjye proyavleniye aktualiziruyet [FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md): ochistka novyikh oficialjnyikh istochnikov i proverka obsjhej funkcii. Novoye podtverzhdeniye nizhe okhvatyivayet tretjye proyavleniye; prezhneye podtverzhdeniye otnositsya toljko k staryim polyam.

`FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0004` vnovj aktualiziruyet [FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md). Povtor vozobnovil diagnostiku; zavershyonnaya mera i novoye podtverzhdeniye nizhe obosnovyivayut tekusjhij status `устранена` dlya rasshirennoj granicyi.

## Kriterii zakryitiya

- Znacheniye `CF-Ray` ne sokhranyayetsya v snimke nezavisimo ot registra imeni zagolovka.
- Na yego meste ostayotsya stabiljnaya pometka `[REDACTED: response trace identifier]`.
- Redakciya otrazhayetsya v otchyote ob izvlechenii.
- Redaktirovaniye `Set-Cookie` i sokhraneniye soderzhateljnyikh zagolovkov ne oslablenyi.

- Oba arkhivatora ispoljzuyut odnu funkciyu dlya pyati ochisjhayemyikh polej; prodolzheniya ochisjhayemyikh zagolovkov ne raskryivayut znacheniya.

- Tochnyiye novyiye polya X-Trace-Id, X-SP-CRID i ostaljnyiye klassificirovannyiye sluzhebnyiye zagolovki ochisjhenyi; znacheniya i prodolzheniya ne raskryivayutsya.

- `X-Forwarded-For` i `Trace-Id` vmeste s prodolzheniyami zamenyayutsya stabiljnoj redakciyej; `Content-Type` sokhranyayetsya. Fakticheskij ispravlennyij otvet ustojchiv pri povtornoj obrabotke.

## Istoricheskoye podtverzhdeniye ustraneniya

Novyij adresnyij test snachala vosproizvyol utechku: nabor iz 13 testov zavershilsya s odnim ozhidayemyim otkazom. Posle uzkoj pravki tot zhe nabor proshyol vse 13 testov; standartnyij smoke-check tekusjhej sessii povtorno podtverzhdayet polnyij nabor avtomatizacii materialov zaprosov.

Povtornoye proyavleniye vremenno vernulo kartochku v aktivnoye sostoyaniye; posle obsjhej pravki adresnyij test proshyol vosemj sochetanij dvukh vkhodov i chetyiryokh trace-polej, sokhranil soderzhateljnyiye zagolovki i podtverdil idempotentnostj. Predyidusjhij vyivod ostayotsya ogranichennyim obsjhim HTML-vkhodom i odnim polem. Novyiye zagolovki vne tochnogo nabora trebuyut otdeljnoj klassifikacii.

## Podtverzhdeniye ustraneniya

[Povtor 55 testov arkhivatora](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/материалы/запуски-проверок/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) zavershilsya kodom 0 posle sokhranyonnyikh sinteticheskikh RED i ispravlenij. Proverenyi tochnyiye nablyudavshiyesya polya, sokhrannostj publichnogo soderzhimogo, otkaz PDF, raspakovka gzip i sokhrannostj vlozhennogo snimka. Istoricheskiye proyavleniya 0001–0002 sokhranenyi; novoye dokazateljstvo rasprostranyayetsya na proyavleniye 0003.

Pri perenose sokhranyayetsya istoricheskoye podtverzhdeniye ukazannogo zapuska: chislo 55 otnositsya k yego naboru, a ne k boleye pozdnim regressiyam. Perenos kartochki ne yavlyayetsya novyim zapuskom proverki v prinimayusjhem dereve i ne rasshiryayet opisannuyu granicu ustraneniya.

Dlya proyavleniya 0004 [GREEN arkhivatora](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/zapuski-proverok/13_1c3d0ae3-eb47-4558-9dbb-c5266fe6f0ca.json) podtverzhdayet 57 testov posle RED; [svodka perearkhivacii](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/ochistka-novyikh-snimkov.json) razlichayet ochistku zagolovkov Sponsr i tel Boosty. [Profilj 29 snimkov](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/profilj-ochistki-posle.json) vklyuchayet ispravlennyij otvet Sponsr i proveryayet idempotentnostj. Eto adresnoye dokazateljstvo; na moment finansovogo etapa 14 sentyabrya polnyij profilj reyestra yesjhyo ozhidal obsjhej zavisimosti. Ona prinyata 15 sentyabrya, a finansovyij perenos trebuyet sobstvennoj priyomki.

## Istochniki

- [Zapros novogo proyavleniya i soglasovaniye nomera](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/запрос.md).

- [Zapros povtornogo proyavleniya](../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-26_11-16-52_MSK_perevesti-licenzionnuyu-pamyatku-na-anglijskij-yazyik/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-26_11-16-52_MSK_perevesti-licenzionnuyu-pamyatku-na-anglijskij-yazyik/otchyot.md)
- [otchyot ob izvlechenii istochnika](../Istochniki/URL/https/wiki.creativecommons.org/wiki/Publicdomain/zero/1.0/LegalText_-Russian-35eacbaf5d6489ab/extraction-report.md)
- [realizaciya obsjhego arkhivatora](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py)
- [regressionnyiye testyi obsjhego arkhivatora](../Instrumentyi/fum-materialyi-zaprosov/tests/test_source_archive_cli.py)

- [Rezerv lokaljnogo nomera koordinatorom](../Zhurnal/2026-09-14_23-44-58_MSK_zaregistrirovatj-sboi-istochnikov-podderzhki/zapros.md); obsjhij atomarnyij raspredelitelj lokaljnyiye nomera proyavlenij ne vyidayot.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 06:23:18 MSK -->
<!-- content-sha256: sha256:72980ecb3ab89f6bdb0e05a2e507eb3c43456f7e6451989981112441fb9a9080 -->
<!-- FUM-MD-RECENCY:END -->
