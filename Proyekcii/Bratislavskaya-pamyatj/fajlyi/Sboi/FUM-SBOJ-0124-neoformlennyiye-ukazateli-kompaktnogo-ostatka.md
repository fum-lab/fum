+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0124"
"статус" = "устранена"
+++
# Neoformlennyiye ukazateli kompaktnogo ostatka

## Nablyudayemyij sboj

Publikacionnaya proverka iskhodnogo kompaktnogo chitatelya vernula semj oshibok POSIX: tri opredeleniya JSON Pointer, dve testovyiye proverki i dva opisaniya formata. Polnyij diagnosticheskij povtor podtverdil tot zhe nabor. Mashinnyiye fajlyi sistemyi etimi strokami ne adresuyutsya.

## Granica povtoreniya

Tochnaya granica — semj strok susjhestvuyusjhego sreza kompaktnogo ostatka, perechislennyiye v [svideteljstve](../Zhurnal/2026-09-14_23-21-46_MSK_zafiksirovatj-prodolzheniye-prioritetnoj-rabotyi/materialyi/vosstanovleniye-JSON-Pointer.json). Proizvoljnyiye budusjhiye JSON Pointer, fajlovyiye puti i perenosyi primerov iz drugikh oblastej syuda ne vkhodyat. Odin nabor propusjhennyikh deklaracij schitayetsya odnim proyavleniyem; diagnosticheskij povtor ne uvelichivayet schyotchik.

## Proyavleniya

- `FUM-СБОЙ-0124/ПРОЯВЛЕНИЕ-0001`: [kornevoj etap](../Zhurnal/2026-09-14_23-21-46_MSK_zafiksirovatj-prodolzheniye-prioritetnoj-rabotyi/zapros.md), pryamyiye zapuski3–4. Effekt — kod1 i nevozmozhnostj publikacionnoj priyomki sreza. Vosstanovleniye — semj tochnyikh tipizirovannyikh deklaracij shtatnyim updater; pryamoj zapusk5 vernul0, zapusk6 sveril ikh sostav i sokhrannostj iskhodnikov.

## Ozhidaniye i klassifikaciya

Postavlyayemyij sobstvennyij srez obyazan prokhoditj publikacionnuyu proverku s yavnoj klassifikaciyej dopustimyikh form. Nedorabotka oformleniya postavki podtverzhdena. Izmeneniye algoritma raspoznavaniya ne potrebovalosj; znacheniye JSON Pointer otlichayetsya ot fajlovogo puti.

## Mekhanizm i sistemnoye ustraneniye

Deklaracii ne byili perenesenyi vmeste s novyimi opredeleniyami i primerami. V policy sokhranenyi pyatj tochnyikh opredelenij i dve otkryityiye fiksturyi s SHA vsej stroki i chislom sovpadenij1. Staryiye isklyucheniya pobajtno po smyislovoj strukture sokhranenyi. Ustojchivoye ogranichennoye vosstanovleniye obespechivayetsya sokhranyonnyimi tochnyimi selektorami i shtatnoj proverkoj ikh fingerprint; novyikh obsjhikh razreshenij dlya fajlov ili katalogov net.

## Svyazannyiye shagi

Otdeljnyij planovyij shag ne sozdavalsya: ogranichennoye vosstanovleniye vyipolneno i provereno v etom zhe etape. Polnaya priyomka kompaktnogo chitatelya, realjnoye podklyucheniye CLI i obsjhij perenos proverochnogo vyivoda v kompaktnuyu formu ostayutsya za predelami kartochki.

## Kriterii zakryitiya

- Kazhdoj iz semi iskhodnyikh strok sootvetstvuyet odna tochnaya deklaraciya podkhodyasjhej kategorii.
- Predyidusjhaya politika i chetyire peredannyikh iskhodnika sokhranenyi; novyiye shirokiye isklyucheniya otsutstvuyut.
- Publikacionnyij scanner prinimayet poluchennuyu politiku i ne nakhodit dejstvuyusjhikh narushenij.

## Podtverzhdeniye ustraneniya

[Svideteljstvo vosstanovleniya](../Zhurnal/2026-09-14_23-21-46_MSK_zafiksirovatj-prodolzheniye-prioritetnoj-rabotyi/materialyi/vosstanovleniye-JSON-Pointer.json) sokhranyayet iskhodnyiye oshibki, semj zapisej i khyeshi chetyiryokh neizmennyikh iskhodnikov. [Mashinnyiye rezuljtatyi](../Zhurnal/2026-09-14_23-21-46_MSK_zafiksirovatj-prodolzheniye-prioritetnoj-rabotyi/otchyot.md) fiksiruyut uspeshnuyu proverku publikacii i otdeljnuyu sverku tochnogo izmeneniya. Status ogranichen dannyim naborom; eto ne utverzhdeniye o podderzhke vsekh JSON Pointer.

## Istochniki

- [Iskhodnyij zapros i prodolzheniye](../Zhurnal/2026-09-14_23-21-46_MSK_zafiksirovatj-prodolzheniye-prioritetnoj-rabotyi/zapros.md).
- [Otchyot s pryamyimi proverkami](../Zhurnal/2026-09-14_23-21-46_MSK_zafiksirovatj-prodolzheniye-prioritetnoj-rabotyi/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 23:56:24 MSK -->
<!-- content-sha256: sha256:2bed2ed6f6ad1a7e0e4d725f863960b9ec17af11149826d33f73003b425a4126 -->
<!-- FUM-MD-RECENCY:END -->
