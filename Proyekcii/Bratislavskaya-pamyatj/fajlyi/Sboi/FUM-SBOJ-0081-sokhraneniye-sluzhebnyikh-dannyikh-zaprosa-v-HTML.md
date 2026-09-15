+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0081"
"статус" = "устранена"
+++
# Sokhraneniye sluzhebnyikh dannyikh zaprosa v HTML

## Nablyudayemyij sboj

V novyikh HTML obnaruzhenyi csrf.token, csrftoken, nonce, wgRequestId, polya CAPTCHA i diagnosticheskiye adres/ID zaprosa. Znacheniya ne yavlyayutsya soderzhaniyem uslovij podderzhki i ne dolzhnyi popadatj v publikuyemuyu pamyatj.

Dopolniteljnoye podtverzhdyonnoye proyavleniye v tom zhe zakhvate: ID zaprosa stranicyi blokirovki MYRTEX u FPG. Pered publikaciyej dobavlenyi sinteticheskiye RED/GREEN, ochistka toljko pri signature blokirovki i povtornoye izvlecheniye bez seti; publichnyij primer ID vne stranicyi blokirovki sokhranyayetsya. Znacheniya diagnostiki v kartochku ne vklyuchenyi.

## Granica povtoreniya

Obsjhaya podgotovka HTML do izvlecheniya dolzhna ochisjhatj raspoznannyiye sluzhebnyiye polya, sokhranyaya soderzhateljnyiye datyi i netronutyiye bajtyi. Setevyiye trace-zagolovki otnosyatsya otdeljno k FUM-SBOJ-0020. PDF i szhatiye ne obyyedinyayutsya s etim mekhanizmom.

## Proyavleniya


| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                       | Effekt                                               | Vosstanovleniye                                                                                                                                                                                                                                                                       |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0081/ПРОЯВЛЕНИЕ-0001` | [Otchyot reyestra podderzhki](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/отчёт.md) i otdeljnyiye mashinnyiye zapisi RED/GREEN. | Narushena trebuyemaya sokhrannostj istochnika do kommita. | Snachala sinteticheskiye testyi vosproizveli sokhraneniye znachenij. Dobavlena obsjhaya redakciya do izvlecheniya; CAPTCHA ogranichena strukturoj diagnosticheskogo kontejnera. Surrogateescape sokhranyayet netronutyiye syiryiye bajtyi. Novyiye istochniki ochisjhenyi povtorno bez publikacii prezhnikh znachenij. |

## Ozhidaniye i klassifikaciya

Podtverzhdyonnaya nedorabotka susjhestvuyusjhego istochnikovogo mekhanizma; gipoteticheskiye i ne nablyudavshiyesya polya ne obyyavlyayutsya ochisjhennyimi.

## Mekhanizm i sistemnoye ustraneniye

Snachala sinteticheskiye testyi vosproizveli sokhraneniye znachenij. Dobavlena obsjhaya redakciya do izvlecheniya; CAPTCHA ogranichena strukturoj diagnosticheskogo kontejnera. Surrogateescape sokhranyayet netronutyiye syiryiye bajtyi. Novyiye istochniki ochisjhenyi povtorno bez publikacii prezhnikh znachenij.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) aktualizirovan dannyim proyavleniyem: ispravleniye trebuyetsya dlya proverennogo vyipuska pervogo reyestra. Novyij otdeljnyij shag ne sozdayotsya.

## Kriterii zakryitiya

- Sinteticheskiye sluzhebnyiye znacheniya otsutstvuyut v tele i izvlechyonnom tekste; obyichnyiye datyi, publichnyiye adresa i netronutyiye bajtyi sokhranenyi. Povtor ochistki idempotenten; profilj i adresnyij audit podtverzhdayut ogranichennyij nabor.
- Sobstvennaya regressiya meryi prokhodit vmeste s susjhestvuyusjhimi testami arkhivatora; smyislovyiye i licenzionnyiye ogranicheniya istochnikov sokhranyayutsya.

## Podtverzhdeniye ustraneniya

[Povtor 55 testov arkhivatora](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/материалы/запуски-проверок/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) zavershilsya kodom 0 posle sokhranyonnyikh sinteticheskikh RED i ispravlenij. Proverenyi tochnyiye nablyudavshiyesya polya, sokhrannostj publichnogo soderzhimogo, otkaz PDF, raspakovka gzip i sokhrannostj vlozhennogo snimka. Shirokaya priyomka pervogo reyestra otnositsya k STEP-0212; kartochka podtverzhdayet sobstvennuyu vosproizvedyonnuyu granicu.

Pri perenose sokhranyayetsya istoricheskoye podtverzhdeniye ukazannogo zapuska: chislo 55 otnositsya k yego naboru, a ne k boleye pozdnim regressiyam. Perenos kartochki ne yavlyayetsya novyim zapuskom proverki v prinimayusjhem dereve i ne rasshiryayet opisannuyu granicu ustraneniya.

## Istochniki

- [Komanda, utochneniya i soglasovaniye ID](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/запрос.md).
- [Obsjhij arkhivator](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).
- [Otkryityiye regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:11:13 MSK -->
<!-- content-sha256: sha256:863182a84fc6afd97762177dc133ab64d85a771654b2a71fd420f025b9cf50e6 -->
<!-- FUM-MD-RECENCY:END -->
