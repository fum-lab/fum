+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0046"
"статус" = "устранена"
+++
# Dopisyivaniye JSONL preryivayet vosstanovleniye

## Nablyudayemyij sboj

Chitatelj FUM-STEP-0177 pri vosstanovlenii tekusjhej aktivnoj zadachi otkazal s soobsjheniyem «istochnik izmenilsya vo vremya chteniya». Proverka polnogo sostoyaniya fajla trebuyet nepodvizhnogo JSONL, togda kak runtime dopisyivayet v nego sobyitiya rabotyi. Obyazateljnyij vkhod dolzhen umetj bezopasno chitatj zavershyonnuyu iskhodnuyu granicu pri dopisyivanii posle neyo.

## Granica povtoreniya

Chteniye dostatochno boljshogo zhivogo JSONL odnovremenno s yego rasshireniyem. Dopisyivaniye posle prochitannoj granicyi oshibochno stanovitsya prepyatstviyem dlya vosstanovleniya dazhe bez izmeneniya prezhnego prefiksa.

## Proyavleniya

| Lokaljnyij nomer               | Istochnik i dokazateljstvo                                                                                                   | Effekt                                           | Vosstanovleniye                                                                                                                   |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| FUM-SBOJ-0046/PROYAVLENIYE-0001 | [Otchyot nablyudeniya](../Zhurnal/2026-09-10_23-24-41_MSK_svyazatj-obrabotku-soobsjhenij-s-istoriyej/otchyot.md#resheniya-i-ogranicheniya) | Shtatnyij chitatelj ne vernul dialog tekusjhej zadachi | Ogranichennyij zavershyonnyij prefiks prochitan vremennoj proceduroj i povtorno sveryon po SHA; ispravleniye avtomatizacii yesjhyo predstoit |

## Mekhanizm i ogranichennoye vosstanovleniye

Nablyudayemyij otkaz svyazan s proverkoj metadannyikh vsego fajla posle chteniya. Dopustimoye dopisyivaniye nuzhno otlichatj ot usecheniya i izmeneniya prochitannyikh bajtov. Indeks ogranichennogo snimka ne dolzhen poluchatj metku novogo polnogo fajla i tem samyim skryivatj neprochitannyij khvost. Ruchnoye vosstanovleniye sokhranyayet rabotu, no ne zakryivayet sistemnuyu granicu.

## Svyazannyiye shagi

- [FUM-STEP-0177 — Vozvrasjhatj neobrabotannyiye soobsjheniya poljzovatelya](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md).

## Kriterii zakryitiya

- Vosproizvodimyij scenarij dopisyivaniya sobyitij runtime ne meshayet ogranichennomu chteniyu neizmennogo zavershyonnogo prefiksa.
- Povtor obnaruzhivayet novyij chelovecheskij vvod; neprochitannyij khvost ne teryayetsya iz-za metki kyesha.
- Usecheniye i izmeneniye prochitannyikh bajtov otklonyayutsya; profili podtverzhdayut priyemlemuyu stoimostj.

## Podtverzhdeniye ustraneniya

Ogranichennyij LF-prefiks chitayetsya pri dopisyivanii runtime; usecheniye i izmeneniye prochitannogo prefiksa otklonyayutsya. Zaklyuchiteljnaya sverka vozvrasjhayet neproverennyij khvost yavno, a novyij chelovecheskij vvod trebuyet povtornogo raschyota. [67 adresnyikh testov i profilj vosstanovleniya](../Zhurnal/2026-09-10_23-24-41_MSK_svyazatj-obrabotku-soobsjhenij-s-istoriyej/otchyot.md) podtverzhdayut eti granicyi. [Sostavnoj dopusk i zaklyuchiteljnaya priyomka](../Zhurnal/2026-09-11_02-02-21_MSK_zakrepitj-dopusk-ostatka-soobsjhenij/otchyot.md) dobavlyayut obyazateljnyij bezzapisnyij vkhod i profilj polnogo processa na 70 MiB. Nalichiye neprochitannogo khvosta boljshe ne vyidayotsya za polnotu istochnika.

## Istochniki

- [Iskhodnyiye komandyi i rabota nad obyazateljnyim vkhodom](../Zhurnal/2026-09-10_23-24-41_MSK_svyazatj-obrabotku-soobsjhenij-s-istoriyej/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:33:08 MSK -->
<!-- content-sha256: sha256:86064d5c0fcb9a889f6d433e8a8313aa77fc13ae75cebff52435cf659348ef32 -->
<!-- FUM-MD-RECENCY:END -->
