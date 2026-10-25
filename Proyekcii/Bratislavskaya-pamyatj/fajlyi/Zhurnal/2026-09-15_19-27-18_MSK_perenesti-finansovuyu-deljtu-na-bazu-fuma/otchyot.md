# Otchyot 2026-09-15 19:27:18 MSK - Perenesti finansovuyu deljtu na bazu fuma

Svezhaya finansovaya deljta perenesena v novuyu sobstvennuyu vetku ot tochnoj bazyi d76d9d87faedf2cfe8de5bf4c5b2ae4ed724ff7b. Prezhnij istochnik 790156bedf407511ed4fd0eda14447a443784584 opublikovan i sokhranyon. Podgotovka prednaznachena dlya posleduyusjhego nastoyasjhego merge koordinatorom; integraciya zdesj ne vyipolnyayetsya.

Sravneniye lizinga, bankovskogo kredita, bezvozvratnoj podderzhki i byudzhet etapov sokhranenyi. Istochniki ne perechityivalisj povtorno: prinyatyi tochnyiye bajtyi svezhego etapa. README sokhranyayet proiskhozhdeniye vedusjhej bazyi, spisok zanovo vyipusjhen yeyo generatorom; navigaciya svedena po fakticheskomu poryadku.

## Profilj vremeni vyipolneniya

| Stadiya                 | Dliteljnostj | Granicyi i sposob izmereniya                         |
| ---------------------- | ------------ | -------------------------------------------------- |
| Perenos i svedeniye     | ne izmereno  | Vyibor tochnoj deljtyi i sokhraneniye obsjhej bazyi         |
| Uchyot tryokh soobsjhenij    | ne izmereno  | Shtatnyij plan, prosmotr i primeneniye svideteljstv    |
| Adresnyiye proverki     | po zapisyam   | Monotonnyiye dliteljnosti otchyotnoj obyortki            |

Granica profilya: perenos s 15 sentyabrya 2026 goda 19:27:18 MSK; obsjhij konec ne izmeren. FIFO i polnyij smoke-check otsutstvuyut. Zaklyuchiteljnaya svyaznostj kontroljnoj tochki vyipolnyayetsya vne izmereniya bez rekursivnoj zapisi samoj sebya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                             | Dliteljnostj | Rezuljtat |
| ------------------------------------------------- | ------------ | --------- |
| [Korenj] Proveritj reyestr na novoj baze FUMA      | 0,171 s      | uspeshno   |
| [Korenj] Proveritj publikaciyu ogranichennoj deljtyi | 34,465 s     | neuspeshno |

Obsjheye vremya pryamyikh zapuskov proverok: 34,636 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Adresnaya proverka reyestra uspeshna. Obsjhaya proverka publikacionnoj chistotyi zavershilasj kodom 1: dva error.posix-absolute v neizmenyonnom otnositeljno HEAD fajle Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_ustojchivyiye_svideteljstva.py, stroki 183 i 199. V finansovoj deljte oshibok skanera net; obsjhaya publikacionnaya chistota bazyi ne podtverzhdena. Chuzhoj predmetnyij instrument ne ispravlyalsya. Istoricheskiye proverki prezhnego etapa sokhranenyi pobajtno i ne obyyavlyayutsya proverkami novoj bazyi. Ispolnyayemyij kod ne menyayetsya.

## Resheniya i ogranicheniya

- Tri pryamyikh soobsjheniya vosstanovlenyi obyazateljnyim ostatkom i obrabotanyi shtatnyim planom ustojchivyikh svideteljstv; sokhranenyi originalyi, otvet, osnovaniye i istoriya. Eto uchyot dialoga, ne polucheniye finansirovaniya.
- Peredannaya koordinatorom komanda smenyi vetki sokhranena doslovno otdeljno; yeyo polnomochiya podtverzhdenyi tekusjhim soobsjheniyem. Ona ne trebuyet pisatj v chuzhoj checkout.
- Novyiye polya summ i zayavitelya ostayutsya neizvestnyimi. Vopros o regione, forme zayavitelya, avanse i platezhe ozhidayet otveta. Registracij, zayavok i oplat net.
- Postavlyayetsya kontroljnaya tochka po yavnomu razresheniyu koordinatora. Obsjhij smoke i shirokaya proyekciya ne zapuskayutsya; susjhestvuyusjheye pokoleniye novoj bazyi otstayot ot finansovoj deljtyi. Finaljnaya priyomka vsej vetki ne zayavlyayetsya.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Predyidusjhij predmetnyij etap](../2026-09-15_19-12-12_MSK_podgotovitj-marshrutyi-finansirovaniya-i-lizinga/otchyot.md).
- [Prakticheskij marshrut](../../Planirovaniye/finansirovaniye-i-resursyi/prakticheskij-marshrut.md).
- [Lizing i kredityi](../../Planirovaniye/finansirovaniye-i-resursyi/lizing-i-kredityi.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:37:40 MSK -->
<!-- content-sha256: sha256:878d094c2f4e4dee414148fb80c687faab93e4d5c7df303862c9c29573084548 -->
<!-- FUM-MD-RECENCY:END -->
