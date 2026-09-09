+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0045"
"статус" = "активна"
+++
# Drejf snimka obyyavlenij koda

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0001`: dopolniteljnaya proverka polnogo snimka obyyavlenij v [etape adaptacii](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/otchyot.md) vernula «snimok ne sovpadayet s tekusjhim ostatkom». Sokhraneno 43091 obyyavleniye; nablyudayetsya 43105. Posle udaleniya yedinstvennoj novoj zapisi etogo etapa — obyazateljnogo vneshnego `unittest.TestCase.setUp` — ostayotsya 43104. V ostaljnyikh novyikh Python-fajlakh latinskikh obyyavlenij ne najdeno. Sledovateljno, raskhozhdeniye ne ischerpyivayetsya tekusjhim etapom. Eto odno nablyudeniye sostoyaniya, a ne 14 otdeljnyikh proyavlenij.

## Vosstanovleniye i sistemnaya mera

Iskhodnyij snimok ne obnovlyon bez razbora. Nablyudeniye i ogranichennostj dopolniteljnoj proverki sokhranenyi; adresnyiye testyi adaptera i standartnaya priyomka ostayutsya otdeljnyimi granicami. Tochnyij mekhanizm nakopleniya prezhnikh 13 zapisej i izmenenij pozicij trebuyet sopostavleniya s reviziyej snimka `a3bde39c84528848b13b0b2b415a7e6fd033b9a1`. Obyazateljnyij vneshnij metod dopustim po pravilu yazyika, no nyineshnij inventarizator uchityivayet yego v ostatke.

## Svyazannyiye shagi

- [FUM-STEP-0173](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0173-razobratj-drejf-snimka-obyyavlenij.md); osnovaniye — `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0001`.

## Kriterij zakryitiya

Proiskhozhdeniye kazhdogo izmeneniya ostatka obyyasneno; sobstvennyiye novyiye latinskiye obyyavleniya ustranenyi libo ustanovlena primenimostj tochnogo vneshnego kontrakta. Soglasovannyij snimok i regressii zapresjhayut neobyyasnyonnoye rasshireniye, ne smeshivaya yego s dopustimyimi vneshnimi tochkami vkhoda. Prostoye obnovleniye obsjhego khyesha ne zakryivayet sboj.

## Istochniki

- [Zapros, granica i vse pryamyiye proverochnyiye vyizovyi](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).
- [Sokhranyonnyij snimok](../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json).
- [Otkaz polnogo snimka](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/zapuski-proverok/21_67880c85-58b0-4821-b9e6-2abeb42bb7dd.json), [adresnaya diagnostika novyikh fajlov](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/zapuski-proverok/22_06391345-57d8-4636-8549-b2c24f52cc55.json), [sopostavleniye inventarya](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/zapuski-proverok/23_8c5742d4-de56-4d63-a0c1-3f2e4ef288c5.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 01:19:47 MSK -->
<!-- content-sha256: sha256:e75b80f9ac04b85c7ebb22c69ddc78ac1b87a15172d5f16202654396ef5f483f -->
<!-- FUM-MD-RECENCY:END -->
