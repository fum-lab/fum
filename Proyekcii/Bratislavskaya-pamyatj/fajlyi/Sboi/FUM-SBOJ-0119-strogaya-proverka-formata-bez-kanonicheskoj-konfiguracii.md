+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0119"
"статус" = "активна"
+++
# Strogaya proverka Swift zapusjhena bez kanonicheskoj konfiguracii

## Nablyudayemyij sboj

Adresnaya strogaya proverka Swift v zapuske № 25 vyipolnena bez kanonicheskoj konfiguracii i zavershilasj ASCII-diagnostikami. Zapusk № 29 s konfiguraciyej uspeshen.

## Granica povtoreniya

Komanda strogoj proverki Swift v priyomke postavki propuskayet kanonicheskuyu konfiguraciyu ili podmenyayet yeyo neyavnyimi nastrojkami. Narusheniya uchyota zapuskov i nepodderzhannaya grammatika skanera syuda ne otnosyatsya.

## Proyavleniya

- **FUM-SBOJ-0119/PROYAVLENIYE-0001.** [Zapisj № 25](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/materialyi/zapuski-proverok/25_96e09b12-4845-4e5b-8a77-ed629d72c0d1.json) fiksiruyet kod 1 i 0,115043459 s; [izvlecheniye komandyi](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/materialyi/nablyudeniya-vkhodnyikh-otkazov.json) sokhranyayet proiskhozhdeniye propusjhennogo parametra. Voznikli `IdentifiersMustBeASCII` i dva zamechaniya perenosa strok. Posle shtatnogo formatirovaniya [zapusk № 29](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/materialyi/zapuski-proverok/29_e6a207e1-e657-47b9-81be-54352cf35b81.json) s konfiguraciyej zavershilsya kodom 0 za 0,0971485 s. Otpechatki snimkov razlichayutsya: povtor podtverzhdayet vosstanovleniye, a ne kontroliruyemoye sravneniye na neizmennom vkhode libo predotvrasjheniye propuska konfiguracii.

## Ozhidaniye i klassifikaciya

Strogaya proverka sobstvennyikh Swift-iskhodnikov ispoljzuyet kanonicheskuyu konfiguraciyu, razreshayusjhuyu kirillicheskiye identifikatoryi. Podtverzhdena nedorabotka podgotovki komandyi priyomki. Obe popyitki proshli cherez obyazateljnuyu obyortku, poetomu eto ne proyavleniye 0025.

## Mekhanizm i sistemnoye ustraneniye

Neposredstvennyij defekt — propusjhennyij parametr konfiguracii. Ispravlennaya komanda vosstanovila proverku. Predlozhennaya konechnaya mera — povtoryayemyij vkhod priyomki s yavnoj kanonicheskoj konfiguraciyej i proveryayemyim otkazom pri yeyo nedostupnosti. Realizaciya etoj meryi zdesj ne zayavlyayetsya.

## Svyazannyiye shagi

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) sokhranyayet predlozhennuyu meru vosproizvodimoj strogoj proverki postavki; osnovaniye — FUM-SBOJ-0119/PROYAVLENIYE-0001. Registraciya fakta ne poruchayet novuyu sistemu proverok.

## Kriterii zakryitiya

Povtoryayemyij vkhod priyomki yavno vyibirayet kanonicheskuyu konfiguraciyu; otsutstviye libo neprigodnostj fajla ne dopuskayet perekhoda k nastrojkam po umolchaniyu. Na fiksirovannyikh iskhodnikakh podtverzhdenyi dopustimostj kirillicheskikh imyon i sokhraneniye ostaljnyikh strogikh diagnostik. Svideteljstva svyazyivayut komandu, konfiguraciyu i vkhod. Poka etoj meryi net, status aktivnyij.

## Istochniki

- [Komanda koordinatora i iskhodnyij zapros](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/zapros.md).
- [Otchyot s granicej diagnostiki](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/otchyot.md).
- [Kanonicheskaya konfiguraciya](../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-format.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 21:05:29 MSK -->
<!-- content-sha256: sha256:e77cd7a580e44c4fea9d9745b4bde69d3bcfebed48d6ea8204e242d48a6a6e8e -->
<!-- FUM-MD-RECENCY:END -->
