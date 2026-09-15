+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0129"
"статус" = "устранена"
+++
# Vremennyij korenj v publikuyemom profile

## Nablyudayemyij sboj

Dva otkryityikh JSON-profilya sokhranili po tri soobsjheniya polnogo proveryayusjhego s absolyutnyim vremennyim kornem. Publikacionnaya proverka obnaruzhila shestj narushenij do kommita. Izmereniya sami po sebe ne byili oshibochnyimi; neprigodnyim okazalsya soprovozhdayusjhij diagnosticheskij tekst.

## Granica povtoreniya

Odin epizod eksporta diagnosticheskogo vyivoda v dva profilya rannej proverki polej. Shestj strok yavlyayutsya sledstviyem odnogo mekhanizma i ne uvelichivayut schyotchik. Ochistka HTML pered izvlecheniyem iz kartochki 0081 imeyet druguyu granicu.

## Proyavleniya

- `FUM-СБОЙ-0129/ПРОЯВЛЕНИЕ-0001`: publikacionnyij otkaz etapa rannej proverki polej. Iskhodnyiye profili sokhranenyi privatno, a ikh tochnyiye SHA svyazanyi s proizvodnyimi predstavleniyami.

## Ozhidaniye i klassifikaciya

Profilj dlya publikacii sokhranyayet dannyiye izmerenij i proiskhozhdeniye, ne raskryivaya mashinnyij vremennyij korenj. Polnyij proveryayusjhij vyidayot diagnosticheskij putj dlya lokaljnogo primeneniya; perenos etoj stroki bez podgotovki publichnogo predstavleniya byil oshibkoj eksportiruyusjhego koda.

## Mekhanizm i sistemnoye ustraneniye

Dobavleno otdeljnoye vosproizvodimoye predstavleniye profilya. Ono sokhranyayet iskhodnyij obyyekt, chislovyiye znacheniya i vkhodnyiye khyeshi, zamenyayet izvestnyij vremennyij korenj uslovnyim oboznacheniyem i dobavlyayet SHA iskhodnogo serializovannogo profilya, chislo zamen i SHA preobrazovatelya. Profilirovsjhik primenyayet yego pri kazhdom novom eksporte. Istoricheskiye profili preobrazovanyi tem zhe mekhanizmom s otdeljnyim svideteljstvom sokhraneniya izmerenij.

## Svyazannyiye shagi

Novyij STEP ne sozdavalsya: ogranichennyij defekt eksporta ustranyon v tekusjhej rabote. Obsjhaya priyomka rannego vkhoda i yego vklyucheniye v poryadok proverok ostayutsya v susjhestvuyusjhem FUM-STEP-0174 i ne zakryivayutsya etoj kartochkoj.

## Kriterii zakryitiya

- V publichnyikh profilyakh net fakticheskogo vremennogo kornya.
- Vkhodnyiye khyeshi i chisla staryikh izmerenij sokhranenyi, iskhodnyiye JSON dostupnyi privatno.
- Novyij zapusk profilirovsjhika srazu vyidayot publikacionno dopustimoye predstavleniye.
- Regressiya proveryayet sokhrannostj iskhodnogo obyyekta i SHA; publikacionnyij skaner podtverzhdayet otsutstviye narushenij.

## Podtverzhdeniye ustraneniya

Padayusjhij test otsutstvuyusjhego preobrazovatelya dovedyon do uspekha; obsjhij adresnyij nabor soderzhit 12 uspeshnyikh testov. Novyij otkryityij profilj i posleduyusjhaya publikacionnaya proverka proshli. Status ogranichen eksportom etikh sinteticheskikh profilej: universaljnaya ochistka proizvoljnoj diagnostiki i polnaya priyomka instrumenta ne zayavlyayutsya.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-15_00-46-36_MSK_proveryatj-polya-zhurnala-do-polnoj-svyaznosti/zapros.md).
- [Proverki, profilj i ogranicheniya](../Zhurnal/2026-09-15_00-46-36_MSK_proveryatj-polya-zhurnala-do-polnoj-svyaznosti/otchyot.md).
- [Proiskhozhdeniye publichnyikh profilej](../Zhurnal/2026-09-15_00-46-36_MSK_proveryatj-polya-zhurnala-do-polnoj-svyaznosti/materialyi/proiskhozhdeniye-publichnyikh-profilej.json).
- [Novyij publichnyij profilj](../Zhurnal/2026-09-15_00-46-36_MSK_proveryatj-polya-zhurnala-do-polnoj-svyaznosti/materialyi/profilj-polej-publichnyij.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:14:49 MSK -->
<!-- content-sha256: sha256:f4e1bb646601abe35ffee19ddfe3a49a58cff7d8cbaba62dff092b0ae948653d -->
<!-- FUM-MD-RECENCY:END -->
