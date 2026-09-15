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

Proyavleniye 0002 otnositsya k propusku strokovogo `websocket.token` vnutri raspoznannoj konfiguracii stranicyi. Chrezmernaya ochistka pokhozhego publichnogo teksta zaregistrirovana otdeljno kak FUM-SBOJ-0120: obsjhij mekhanizm predotvrasjheniya etikh dvukh defektov ne dokazan.

## Proyavleniya


| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                                                                                                                                                                                | Effekt                                                                                                           | Vosstanovleniye                                                                                                                                                                                                                                                                       |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0081/ПРОЯВЛЕНИЕ-0001` | [Otchyot reyestra podderzhki](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/отчёт.md) i otdeljnyiye mashinnyiye zapisi RED/GREEN.                                                                                                                                                                          | Narushena trebuyemaya sokhrannostj istochnika do kommita.                                                             | Snachala sinteticheskiye testyi vosproizveli sokhraneniye znachenij. Dobavlena obsjhaya redakciya do izvlecheniya; CAPTCHA ogranichena strukturoj diagnosticheskogo kontejnera. Surrogateescape sokhranyayet netronutyiye syiryiye bajtyi. Novyiye istochniki ochisjhenyi povtorno bez publikacii prezhnikh znachenij. |
| `FUM-СБОЙ-0081/ПРОЯВЛЕНИЕ-0002` | [Issledovaniye 14.09.2026](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/otchyot.md): v dvukh obolochkakh Boosty najdenyi raznyiye nepustyiye `websocket.token` vnutri sluzhebnogo `script` s `id="app-config"`; [RED](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/zapuski-proverok/12_0f99d814-8c5a-4a35-a8a7-ea5b6f45b2a1.json). | Sluzhebnyiye znacheniya ne byili otredaktirovanyi do izvlecheniya. Ikh naznacheniye ne ustanovleno; znacheniya ne publikuyutsya. | Dobavlena tochnaya ochistka polya konfiguracii; oba sokhranyonnyikh otveta perearkhivirovanyi bez seti, publichnyij primer vne bloka sokhranyon.                                                                                                                                                   |

## Ozhidaniye i klassifikaciya

Podtverzhdyonnaya nedorabotka susjhestvuyusjhego istochnikovogo mekhanizma; gipoteticheskiye i ne nablyudavshiyesya polya ne obyyavlyayutsya ochisjhennyimi.

## Mekhanizm i sistemnoye ustraneniye

Snachala sinteticheskiye testyi vosproizveli sokhraneniye znachenij. Dobavlena obsjhaya redakciya do izvlecheniya; CAPTCHA ogranichena strukturoj diagnosticheskogo kontejnera. Surrogateescape sokhranyayet netronutyiye syiryiye bajtyi. Novyiye istochniki ochisjhenyi povtorno bez publikacii prezhnikh znachenij.

Obsjhaya podgotovka tela teperj ochisjhayet strokovyij token v sluzhebnom bloke `app-config` do izvlecheniya. Soderzhateljnaya cena i tekst uslovij sokhranyayutsya; oblastj raspoznavaniya dopolniteljno ogranichena ispravleniyem FUM-SBOJ-0120.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) aktualizirovan dannyim proyavleniyem: ispravleniye trebuyetsya dlya proverennogo vyipuska pervogo reyestra. Novyij otdeljnyij shag ne sozdayotsya.

Povtor `FUM-СБОЙ-0081/ПРОЯВЛЕНИЕ-0002` aktualiziruyet [FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md). Diagnostika vozobnovlena dlya novogo polya; proverennaya obsjhaya mera i podtverzhdeniye nizhe pozvolyayut snova otmetitj etu konechnuyu granicu kak `устранена`.

## Kriterii zakryitiya

- Sinteticheskiye sluzhebnyiye znacheniya otsutstvuyut v tele i izvlechyonnom tekste; obyichnyiye datyi, publichnyiye adresa i netronutyiye bajtyi sokhranenyi. Povtor ochistki idempotenten; profilj i adresnyij audit podtverzhdayut ogranichennyij nabor.
- Sobstvennaya regressiya meryi prokhodit vmeste s susjhestvuyusjhimi testami arkhivatora; smyislovyiye i licenzionnyiye ogranicheniya istochnikov sokhranyayutsya.

- Sinteticheskij `websocket.token` v tochnom bloke konfiguracii redaktiruyetsya; cena, publichnyij tekst i primer vne konfiguracii sokhranenyi. Dva fakticheskikh snimka posle ochistki idempotentnyi.

## Podtverzhdeniye ustraneniya

[Povtor 55 testov arkhivatora](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/материалы/запуски-проверок/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) zavershilsya kodom 0 posle sokhranyonnyikh sinteticheskikh RED i ispravlenij. Proverenyi tochnyiye nablyudavshiyesya polya, sokhrannostj publichnogo soderzhimogo, otkaz PDF, raspakovka gzip i sokhrannostj vlozhennogo snimka. Shirokaya priyomka pervogo reyestra otnositsya k STEP-0212; kartochka podtverzhdayet sobstvennuyu vosproizvedyonnuyu granicu.

Pri perenose sokhranyayetsya istoricheskoye podtverzhdeniye ukazannogo zapuska: chislo 55 otnositsya k yego naboru, a ne k boleye pozdnim regressiyam. Perenos kartochki ne yavlyayetsya novyim zapuskom proverki v prinimayusjhem dereve i ne rasshiryayet opisannuyu granicu ustraneniya.

Dlya proyavleniya 0002 [GREEN 57 testov](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/zapuski-proverok/13_1c3d0ae3-eb47-4558-9dbb-c5266fe6f0ca.json) sleduyet za adresnyim RED. [Svodka ustanovki](../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/ochistka-novyikh-snimkov.json) sokhranyayet prinadlezhnostj dvukh ochisjhennyikh tel Boosty. [Rasshirennyij profilj 29 HTML](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/profilj-ochistki-posle.json) okhvatyivayet obe stranicyi; staryij profilj 26 HTML etoj granicyi ne dokazyival. [Posleduyusjhij GREEN](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/zapuski-proverok/5_d49ee583-5f67-4ac5-b201-5325f8c76e39.json) podtverzhdayet sokhrannostj tochnogo raspoznavaniya vmeste s otdeljnoj regressiyej FUM-SBOJ-0120. Polnaya priyomka vsego reyestra ostayotsya otdeljnoj.

## Istochniki

- [Komanda, utochneniya i soglasovaniye ID](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/запрос.md).
- [Obsjhij arkhivator](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).
- [Otkryityiye regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py).

- [Koordinacionnyij rezerv nomera proyavleniya](../Zhurnal/2026-09-14_23-44-58_MSK_zaregistrirovatj-sboi-istochnikov-podderzhki/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 06:23:18 MSK -->
<!-- content-sha256: sha256:db8e5beb8f876e8abff2eba86ce5911f14ab69817cfd796d48cded03f2a95fc2 -->
<!-- FUM-MD-RECENCY:END -->
