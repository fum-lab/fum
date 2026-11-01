+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0148"
"статус" = "устранена"
+++
# Novyij kursor dlya sokhranyonnoj istorii modeli

## Nablyudayemyij sboj

Pri obnovlenii podgotovki kommita korenj ukazal novyij pustoj privatnyij kursor vmeste s uzhe susjhestvuyusjhim putyom istorii modeli. Chitatelj zakonomerno otkazal: `история не совпадает с курсором или подготовленной записью; нужна сверка`.

## Granica povtoreniya

Odin zapusk podgotovki s novyim kursorom i prezhnej sokhranyonnoj istoriyej sostavlyayet odno proyavleniye. Predshestvuyusjhij otkaz ustarevshej podgotovki — shtatnaya zasjhita: novoye nativnoye nablyudeniye izmenilo chislo nablyudenij, khotya para model/effort ostalasj prezhnej. On ne schitayetsya vtoryim proyavleniyem i ne dokazyivayet neispravnostj sozdatelya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                   | Effekt                                             | Vosstanovleniye                                                                        |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0148/ПРОЯВЛЕНИЕ-0001` | [Tipizirovannyij otkaz](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/materialyi/otkaz-novogo-kursora-modeli.json), kod 2, profilj 8,759886209 s. | Novaya podgotovka ne sozdana; istoriya ne podmenena. | Posle sverki primenyon prezhnij svyazannyij kursor, novaya podgotovka zavershilasj kodom 0. |

## Ozhidaniye i klassifikaciya

Prodolzheniye sokhranyonnoj istorii ispoljzuyet yeyo podtverzhdyonnyij kursor. Novyij privatnyij putj sam po sebe ne vosstanavlivayet etu svyazj. Eto oshibochnyij vyibor vkhoda kornem; chitatelj korrektno zapresjhayet neobosnovannuyu zamenu istorii.

## Mekhanizm i ogranichennoye vosstanovleniye

Korenj perenyos trebovaniye novyikh fajlov podgotovki, soobsjheniya i kvitancii na kursor susjhestvuyusjhej istorii. Posle chteniya kontrakta ustanovleno, chto prezhnij kursor soderzhit tochnoye naznacheniye i khyesh ustanovlennoj istorii. Povtornaya podgotovka ispoljzovala etu svyazj i shtatnyij import dopolnennogo istochnika. Istoriya, staraya podgotovka i oba otkaza ne udalyalisj; prezhnij otkaz ne vyidavalsya za uspekh.

## Svyazannyiye shagi

Otdeljnyij STEP ne nuzhen dlya uzhe vyipolnennogo ogranichennogo vosstanovleniya vyizova. Susjhestvuyusjhaya avtomatizaciya sokhranyayet stroguyu sverku; universaljnaya bezoshibochnostj vyibora vkhodov ne zayavlyayetsya.

## Kriterii zakryitiya

Nepodtverzhdyonnaya para istorii i kursora otklonena do sozdaniya kommita. Sverennaya prezhnyaya para dopuskayet novuyu podgotovku, sokhranyayet iskhodnyiye nablyudeniya i importiruyet dopolniteljnoye. Staroye svideteljstvo i otkaz ostayutsya adresuyemyimi.

## Podtverzhdeniye ustraneniya

[Nablyudeniye uspeshnoj podgotovki](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/materialyi/vosstanovleniye-podgotovki-modeli.json) svyazyivayet kod 0 i khyeshi fakticheskogo otveta, podgotovki i soobsjheniya. [Istoriya modeli](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/materialyi/istoriya-modeli.json) sokhranyayet 62 nablyudeniya i poslednyuyu paru gpt-6-astra / ultra. Eto vosstanovleniye podgotovki; sozdaniye kommita proveryayetsya otdeljno.

## Istochniki

- [Tekusjhij zapros](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/zapros.md), [otchyot](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/otchyot.md).
- [Chitatelj istorii modeli](../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/istoriya_modeli.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:24:37 MSK -->
<!-- content-sha256: sha256:7ae4b1a757428ad08fb050a3a0d5b653dfacd19ab1a69326b92b5cd9db633396 -->
<!-- FUM-MD-RECENCY:END -->
