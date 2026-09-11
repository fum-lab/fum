+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0079"
"статус" = "активна"
+++
# Zavisimyij smoke posle otkaza predprosmotra

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0079/ПРОЯВЛЕНИЕ-0001`: predprosmotr novogo pustogo zhurnala vernul 1 iz-za otsutstvuyusjhego kataloga zapuskov, no korenj otpravil zavisimyij polnyij smoke bez proverki iskhoda. V otchyote ostalsya nezapolnennyij marker. Posle obnaruzheniya zavedomogo otkaza budusjhej svyaznosti zapusk shtatno ostanovlen: [zapisj](../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/materialyi/zapuski-proverok/1_5f54ab1e-16ac-4612-8405-d565276e17d8.json) sokhranyayet SIGINT, kod −2, dliteljnostj 44,208013416 s, plan 13 naborov i pustyiye nablyudeniya avtonomnyikh testov.

## Narushennoye ozhidaniye i mekhanizm

Zavisimoye dejstviye trebuyet nablyudyonnogo uspeshnogo zaversheniya obyazateljnoj podgotovki. Iskhod predprosmotra byil dostupen i otricatelen; orkestraciya proignorirovala yego. Eto otlichayetsya ot maskirovki rannego otkaza lozhnyim obsjhim uspekhom shell (FUM-SBOJ-0010) i ot prezhdevremennogo dejstviya do nablyudeniya zaversheniya. Projdennyiye ranniye shagi smoke ne ispravlyayut nezapolnennyij otchyot.

## Vosstanovleniye i sistemnaya mera

Prervannaya zapisj sokhranena; novoye pokoleniye proyekcii ne obyyavlyayetsya ustanovlennyim. Posle zaversheniya gruppyi processov predprosmotr sformirovan iz nastoyasjhej terminaljnoj zapisi, ispravlennyij otchyot proshyol [adresnuyu svyaznostj](../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/materialyi/zapuski-proverok/2_79f70d99-b8b9-4a28-8634-55466c485c7d.json) za 40,954866750 s. Daljnejshiye zavisimyiye komandyi vyipolnyayutsya posledovateljno posle yavnoj proverki koda predyidusjhej. Dlya novogo pustogo etapa snachala nuzhna nastoyasjhaya nedorogaya zapisj, zatem uspeshnyij predprosmotr. Pustoj katalog ne zamenyayet zapisj.

Lokaljnoye vosstanovleniye ne dokazyivayet sistemnoye predotvrasjheniye povtoreniya. Ostatok — proveryayemaya regressionnaya granica posledovateljnogo vyipolneniya podgotovki v susjhestvuyusjhej avtomatizacii; novyij orkestrator etim nablyudeniyem ne razreshayetsya.

## Svyazannyiye shagi

- [FUM-STEP-0175](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md); osnovaniye — `FUM-СБОЙ-0079/ПРОЯВЛЕНИЕ-0001`.

## Kriterij zakryitiya

Proveryayemyij sposob podgotovki sokhranyayet rannij otricateljnyij iskhod i garantirovanno ne otpravlyayet zavisimyij smoke posle nego. Otdeljnaya regressiya vosproizvodit otkaz obyazateljnogo predprosmotra; nezavisimaya uspeshnaya podgotovka razreshayet rovno posleduyusjheye dejstviye. Istoricheskij SIGINT ostayotsya v zhurnale. Odin uspeshnyij povtor libo otdeljnyij kommit ne zakryivayut kartochku.

## Istochniki

- [Iskhodnyiye komandyi, posledovateljnostj i otchyot](../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/zapros.md).
- Obsjhij raspredelitelj vyidelil nomer dlya zadachi `01a09047-faa1-7370-83f7-cdfc8f9943a6`; sobyitiye `63ddc204734e9912f640efa36c953f3da3b9261d6cf31893218e4342d738d6fb`. Chastnaya kvitanciya prochitana; nomer ne vyichislen po maksimumu checkout.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:47:51 MSK -->
<!-- content-sha256: sha256:b84cb5ceabe1dc1ba13c40873f4eaeabf97e91ab360297df6845a57927e68f03 -->
<!-- FUM-MD-RECENCY:END -->
