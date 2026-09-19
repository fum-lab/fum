# Otchyot 2026-09-19 04:14:40 MSK - Uskoritj podgotovku kommita proveryayemyim kyeshem

Predyidusjhij etap prinyat standartnyim konturom 25/25 za 1587,561 s, otchyot zakryit, odnokratnoye primeneniye i nezavisimyij manifest podtverdili 11 747 iskhodnyikh fajlov i 11 748 upravlyayemyikh fajlov. Kommit 23711de4ee376921dfb1da2c4e9a0f0af1cab041 opublikovan v fuma, udalyonnyij OID i chistoye derevo podtverzhdenyi. D22 ostayotsya na pauze. Posleduyusjheye chteniye guard vernulo «prodolzhitj».

Komandyi kommita teperj mogut ispoljzovatj susjhestvuyusjhij privatnyij indeks soobsjhenij bez yego perezapisi. Polnota, pozdnij khvost, poryadok i doslovnoye sovpadeniye s zaprosom proveryayutsya prezhnim chitatelem. V podgotovku dobavlen rannij otkaz nepustoj istorii v3, do chteniya JSONL. Otsutstvuyusjhaya istoriya dopuskayet podgotovku; pervyij zapusk vsyo ravno dolzhen yavno vyibratj v4.

## Profilj vremeni vyipolneniya

| Stadiya                    | Dliteljnostj        | Granicyi i sposob izmereniya                                   |
| ------------------------- | ------------------- | ------------------------------------------------------------ |
| Neizmennyij JSONL bez kyesha | 461,075 ms          | Mediana tryokh chtenij 31 500 459 bajtov                        |
| Neizmennyij JSONL s kyeshem  | 0,393 ms            | Tot zhe SHA vkhoda i rezuljtata, podgotovka indeksa isklyuchena  |
| Khvost bez kyesha / s kyeshem  | 445,023 / 15,114 ms | Promezhutochnyij parnyij zamer; staryij prefiks proveryayetsya khyeshem |
Granica profilya: otkryitaya vosproizvodimaya fikstura, tyoplyij fajlovyij kyesh, po tri chteniya. [Iskhodnyij razbor](materialyi/profilj-do.json), [kyesh neizmennogo fajla](materialyi/profilj-posle.json), [rost bez kyesha](materialyi/khvost-bez-kyesha.json), [rost s kyeshem](materialyi/khvost-s-kyeshem.json). Eto vremya chteniya komand, ne polnyij kommit, ne poljzovateljskij JSONL i ne izmereniye tokenov. Pervyiye dva profilya predshestvuyut dobavleniyu rezhima khvosta; vkhod i rezuljtat ikh paryi sovpadayut.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                   | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------- | ------------ | --------- |
| [korenj] RED kyesha komand i rannego formata J28          | 0,949 s      | neuspeshno |
| [korenj] Iskhodnyij profilj chteniya komand J28             | 2,147 s      | uspeshno   |
| [korenj] GREEN kyesha komand i rannego formata J28        | 0,942 s      | neuspeshno |
| [korenj] Profilj proveryayemogo kyesha komand J28           | 0,758 s      | uspeshno   |
| [korenj] Proverka pozdnej komandyi s polnyim zaprosom J28 | 0,902 s      | uspeshno   |
| [korenj] Rost JSONL bez ispoljzovaniya kyesha J28          | 2,05 s       | uspeshno   |
| [korenj] Rost JSONL s proveryayemyim kyeshem J28             | 0,769 s      | uspeshno   |
| [korenj] Sovmestimostj sozdaniya kommitov posle kyesha J28 | 8,121 s      | neuspeshno |
| [korenj] RED otsutstvuyusjhej istorii J28                  | 1,051 s      | neuspeshno |
| [korenj] GREEN otsutstvuyusjhej i povrezhdyonnoj istorii J28 | 1,064 s      | uspeshno   |
| [korenj] Itogovyiye regressii kyesha i istorii J28          | 1,401 s      | uspeshno   |
| [korenj] Povtor sovmestimosti sozdaniya J28              | 30,865 s     | uspeshno   |
| [korenj] Regressii pervichnogo chitatelya J28              | 0,278 s      | uspeshno   |
| [korenj] Itogovyij profilj khvosta razbor J28             | 2,137 s      | uspeshno   |
| [korenj] Itogovyij profilj khvosta kyesh J28                | 0,843 s      | uspeshno   |
| [korenj] Polya Zhurnala J28                               | 0,087 s      | uspeshno   |
| [korenj] Publikacionnaya chistota J28                     | 34,134 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 88,498 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:029a390a25490939149e5e6d8aebc6effcd7adbc9895e713b77a9894420ffd2f.
Kontekst soderzhimogo: sha256:8c5fe17609bc4896c66212f4df2da620da098b97355fd7fcfd33a7d19720f8df.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Proverki i obnaruzhennyiye oshibki

Pervyij RED: 5 testov za 0,790 s, odin otkaz i dve oshibki pokazyivayut otsutstviye kontrakta kyesha i pozdnyuyu proverku v3. Posle realizacii odin test khvosta otkazal praviljno: v testovoj kartochke ne dobavlen vyibrannyij vtoroj original. Kartochka ispravlena bez izmeneniya proizvodstvennogo dopuska; 5/5 za 0,777 s.

Nezavisimyij prosmotr i prezhniye 27 testov vyiyavili defekt rannej proverki: otsutstvuyusjhij katalog zapuskov oshibochno schitalsya povrezhdyonnyim. Prezhnij nabor dal 16 oshibok za 7,983 s. Usilennyiye novyiye regressii dali dva otkaza i odnu oshibku za 0,924 s; posle proverki cherez lexists — 6/6 za 0,938 s. Dobavlena zasjhita ot lozhnogo uspekha otricateljnyikh testov: oni dokazyivayut, chto doshli do pervichnogo chitatelya. Otdeljno proveryayutsya fajl i oborvannaya ssyilka vmesto kataloga.

V sluzhebnoj komande fiksacii J27 dopolniteljnaya uslovnaya proverka SHA pravil okazalasj neispolnyayemoj. Do push vyipolnena otdeljnaya nastoyasjhaya proverka SHA, ref, OID i yedinstvennogo origin; oni sovpali. Oshibka sluzhebnogo vyirazheniya ne skryivayetsya i ne vyidayotsya za vyipolnennuyu proverku. Daleye primenyayetsya gotovyij ispolnitelj kontroljnyikh tochek v4.

## Resheniya i ogranicheniya

Novaya shirokaya priyomka v etom etape yesjhyo ne vyipolnyalasj. Proverennoye pokoleniye proyekcii otnositsya k J27; posle novyikh kanonicheskikh izmenenij ono otstayot. Realjnyij effekt na podgotovke tekusjhego kommita yesjhyo predstoit izmeritj. Povrezhdyonnyij kyesh ne ignoriruyetsya; kursor modeli ne ispoljzuyetsya kak indeks soobsjhenij.

Pered etim etapom API pokazal 88% ispoljzovannogo nedeljnogo okna, 12% ostalosj. Eto obsjhij akkaunt, raskhod imenno etoj zadachi ne ustanovlen. Dopolniteljnyiye shirokiye paralleljnyiye zapuski ne nachatyi.

## Istochniki

- [iskhodnyij zapros](zapros.md).
- [predyidusjhaya prinyataya rabota](../2026-09-19_03-26-05_MSK_sokratitj-zapuski-Git-pri-sravnenii-derevjyev/otchyot.md).

Itogovyiye adresnyiye proverki: 7/7 za 1,272 s; prezhneye sozdaniye 27/27 za 30,734 s; chitatelj 22/22 za 0,192 s. Finaljnaya para na odinakovom vyirosshem vkhode: [razbor](materialyi/itog-razbor.json) 458,559 ms i [kyesh](materialyi/itog-kyesh.json) 15,091 ms, SHA vkhoda i rezuljtata sovpali. Eto primerno 30-kratnoye sokrasjheniye dannogo uchastka na etoj fiksture, ne vsego rabochego cikla.

Povtornyij nezavisimyij prosmotr podtverdil ustraneniye blokera otsutstvuyusjhego kataloga; novyikh blokiruyusjhikh zamechanij net. Revjyu ne zapuskalo testyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 04:25:46 MSK -->
<!-- content-sha256: sha256:c5c788a604cb7e495b756662e039de02cb63b68f7a9f9f831adfc4f9e415ebd2 -->
<!-- FUM-MD-RECENCY:END -->
