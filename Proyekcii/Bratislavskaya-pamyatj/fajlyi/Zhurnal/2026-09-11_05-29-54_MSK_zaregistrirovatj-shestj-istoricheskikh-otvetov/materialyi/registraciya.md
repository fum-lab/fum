# Nablyudeniye adresnoj registracii

Polnyij pervonachaljnyij ostatok soderzhal 179 chelovecheskikh ekzemplyarov i pustuyu istoriyu. Shestj reshenij vyibranyi po ekzemplyaram iz vyivoda prinyatogo CLI, a ne po SHA syiryikh strok adresnoj kartyi. Vse 179 identifikatorov vklyuchenyi v kontekst kazhdogo resheniya; u samogo rannego voprosa rassmotrenyi 74 pozdnikh chelovecheskikh soobsjheniya. Spisok ne izmenilsya pri posleduyusjhikh chteniyakh.

Fakticheskaya obrabotka vyipolnyayetsya susjhestvuyusjhim CLI iz [zakreplyonnogo komplekta](kontur-0177.md), otdeljnyiye [osnovaniya](osnovaniya.md) ogranichivayut resheniye sostoyavshimsya istoricheskim otvetom. Komandnyiye svideteljstva vklyuchayut polnyij LF; tretij otvet sokhranyayet otsutstviye konechnogo LF.

## Promezhutochnoye sostoyaniye

Pervyiye pyatj reshenij posledovateljno sokhranenyi; posle pervyikh chetyiryokh poluchen polnyij ostatok s isklyucheniyem toljko uzhe vyibrannyikh ekzemplyarov. Posle pyatoj zapisi dva kontroljnyikh chteniya ne podtverdili polnotu iz-za dopisi sluzhebnogo khvosta; pervoye sokhranilo 5066 neproverennyikh bajt. V prochitannom indekse ostavalisj te zhe 179 chelovecheskikh ekzemplyarov, a rasschitannyij ostatok soderzhal 174. Eto ne dokazateljstvo polnotyi neprochitannogo khvosta. Shestaya zapisj byila otlozhena do svezhego polnogo chteniya; sokhranyonnaya istoriya ne perepisyivalasj. Povtornoye chteniye soderzhalo 5339 neproverennyikh bajt. Posle polucheniya polnogo snimka vyipolnena shestaya zapisj i itogovoye chteniye.

## Konechnoye sostoyaniye

Sokhranenyi rovno shestj sobyitij v [kanonicheskoj istorii](../../../Planirovaniye/zadachi/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/obrabotka-soobsjhenij.jsonl). SHA-256 istorii `3099759c6a80b2197632f3f72a98fdeff04c3b915448078df186e5d6f338f403`. Konechnyij polnyij ostatok soderzhit 173 ekzemplyara; iz pervonachaljnyikh 179 isklyuchenyi rovno shestj vyibrannyikh, ostaljnyiye identichnosti sokhranenyi. Neproverennyij khvost raven nulyu. Spisok vsekh chelovecheskikh ekzemplyarov ne izmenilsya.

Konechnyij kontekst imeyet SHA-256 `1bea63f0bb2972703b1f0d94194c4926198c8dc4edd625a374a82e52f7273301`; yego tochnaya granica i vesj spisok ekzemplyarov sokhranenyi v mashinnyikh dannyikh. Kod 3 oznachayet nepustoj ostatok, a ne zaversheniye postoyannoj zadachi. Resheniya «otvet» / «vyipolneno» imeyut toljko istoricheskij smyisl, podrobno ogranichennyij v osnovaniyakh.

### Sobyitiya

- Para 1: ekzemplyar `906df3c2d3155626fef6c4cbe534e9813cafd1ab2882204bed4f8e3923926e21`, sobyitiye `cf1b56bc2ca60f4cd0ee32eef70e733f5991efe0a79572c922db15aac2408d73`.
- Para 2: ekzemplyar `aef473450884ae14f68d4bb6f691ee9a5aebb17c0e8e008c40d2e7b1bba1ffab`, sobyitiye `45371c8b64906360d31d8ee7180849e46d547fed5a9857dc1a747d10cdec83ab`.
- Para 3: ekzemplyar `a72f3e954d79c1312d28ad07cb4842bb35f39575f776522dea2d49da6f6fd061`, sobyitiye `0ba9489bc184b1ad85d2c55fe3d32b6e9ace0141f87616208f962577ea5d9d69`.
- Para 4: ekzemplyar `c95ff5b82caec4840377d4ce2fa64b87ffc93c175d310979e5e9141dfcae0a6a`, sobyitiye `595055c64112a617cf1abad2fcca2f6b1b7cc5ccd81aaa0e91751ddf5eb7c0c1`.
- Para 5: ekzemplyar `e50d0f401e6012ea80b0015aaee3b7b80c2a4d0382760584bd8e28b3eb2fb6e9`, sobyitiye `a21e8976136c649ffdf0dc26b2f4860ee99b9994ce98cafca70b20ed4e17d4f2`.
- Para 6: ekzemplyar `95c62290ade246b82994cf30e6a886b71bf40cd9b279a46e19d215970cdedf64`, sobyitiye `bc0d3b2274ffb78c5bce3b5ed772e80acc437f74c57c7929a044bf25ff35fd94`.

## Izmerennyiye operacii

| Operaciya                              | Dliteljnostj | Kod i rezuljtat                               |
| ------------------------------------- | ------------ | --------------------------------------------- |
| Pervichnyij polnyij ostatok              | 5.288 s      | 3: Polnyij snimok, 179 v ostatke               |
| Svezhij ostatok i trassa importov      | 5.322 s      | 3: Polnyij snimok, 179 v ostatke               |
| Polnyij ostatok posle perenosa vne Git | 5.525 s      | 3: Polnyij snimok, 179 v ostatke               |
| zapisj-10-01                          | 0.092 s      | 2: Adres kyesha otklonyon do sozdaniya istorii    |
| zapisj-10-01-popyitka-2                | 3.268 s      | 0: Resheniye sokhraneno                          |
| ostatok-10-posle-01                   | 5.608 s      | 3: Ostatok 178; polnyij snimok                 |
| zapisj-10-02                          | 0.764 s      | 0: Resheniye sokhraneno                          |
| ostatok-10-posle-02                   | 5.622 s      | 3: Ostatok 177; polnyij snimok                 |
| zapisj-10-03                          | 0.752 s      | 0: Resheniye sokhraneno                          |
| ostatok-10-posle-03                   | 5.609 s      | 3: Ostatok 176; polnyij snimok                 |
| zapisj-10-04                          | 0.630 s      | 0: Resheniye sokhraneno                          |
| ostatok-10-posle-04                   | 6.024 s      | 3: Ostatok 175; polnyij snimok                 |
| zapisj-10-05                          | 1.004 s      | 0: Resheniye sokhraneno                          |
| ostatok-10-posle-05                   | 5.831 s      | 3: Ostatok 174; neproverennyij khvost 5066 bajt |
| ostatok-10-posle-05-pereproverka      | 5.894 s      | 3: Ostatok 174; neproverennyij khvost 5339 bajt |
| ostatok-10-okno                       | 5.460 s      | 3: Ostatok 174; polnyij snimok                 |
| zapisj-10-06                          | 0.919 s      | 0: Resheniye sokhraneno                          |
| ostatok-10-posle-06                   | 5.727 s      | 3: Ostatok 173; polnyij snimok                 |

Vsego 18 izmerennyikh operacij CLI: 69.338 s. Dliteljnosti izmerenyi vneshnim monotonnyim tajmerom vokrug kazhdogo processa; oni ne smeshivayutsya s otdeljnyimi adresnyimi proverkami Zhurnala. Pervonachaljnyij otkaz i oba nepolnyikh chteniya vklyuchenyi. Ruchnaya podgotovka, chteniye koda i diagnostika prichinyi kyesha ne izmeryalisj zadnim chislom.

## Istochniki

[Zapros](../zapros.md), [arkhiv par](../../2026-09-11_05-17-54_MSK_sokhranitj-istoricheskiye-voprosyi-i-otvetyi-o-rabote/materialyi/istochniki/shestj-voprosov/paryi.md), [smyislovyiye osnovaniya](osnovaniya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 05:49:24 MSK -->
<!-- content-sha256: sha256:09ed7c5ae408b17f5b934b5c1ccc2c8080c69e10c8c7e9995b996cbc2d75a92d -->
<!-- FUM-MD-RECENCY:END -->
