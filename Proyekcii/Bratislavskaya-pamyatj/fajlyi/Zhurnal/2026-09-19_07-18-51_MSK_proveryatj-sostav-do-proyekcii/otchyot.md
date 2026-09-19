# Otchyot 2026-09-19 07:18:51 MSK - Proveryatj sostav do proyekcii

Prodolzhayetsya komanda «Prodolzhaj drugiye rabotyi.». J34 prinyat: 25/25 shagov za 1561,659 s, zakryityij snimok i nezavisimyij manifest dejstviteljnyi. Kommit 78a3d9f12c8f2cbf8b6429122583b2155f036d37 dostavlen v fuma; udalyonnyij OID proveren. D22 ostayotsya na pauze.

Sleduyusjhaya granica — ranneye obnaruzheniye neperechislennogo izmeneniya posle sborki planovogo reyestra. Povtorno ispoljzuyem susjhestvuyusjhij razbor zaprosa i Git-statusa, sokhranyayem itogovuyu svyaznostj posle proyekcii. Rannyaya proverka ne zamenyayet nezavisimyij konechnyij perechenj razreshyonnyikh materialov kommita. Eta kontroljnaya tochka sokhranyayet narabotku do obsjhej priyomki.

## Profilj vremeni vyipolneniya

| Stadiya                      | Dliteljnostj | Granicyi i sposob izmereniya                         |
| --------------------------- | ------------ | -------------------------------------------------- |
| Podgotovka itogovogo snimka | ne izmereno  | Zhurnal i sokhraneniye proiskhozhdeniya do proverok      |
| Standartnaya priyomka         | ne izmereno  | Fakticheskaya dliteljnostj fiksiruyetsya obyortkoj nizhe |

Granica profilya: adresnyiye vyizovyi uchityivayutsya obyortkoj; profilj rannego otkaza vyipolnyayetsya na otkryitoj fiksture, bez realjnoj proyekcii i bez zayavleniya ob ekonomii tokenov.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                       | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------- | ------------ | --------- |
| [korenj] RED rannego okhvata do proyekcii                     | 0,395 s      | neuspeshno |
| [korenj] GREEN rannego okhvata do proyekcii                   | 1,239 s      | uspeshno   |
| [korenj] RED poryadka okhvata do proyekcii                     | 0,138 s      | neuspeshno |
| [korenj] GREEN poryadka okhvata do proyekcii                   | 0,142 s      | uspeshno   |
| [korenj] Regressii nezavisimogo razresheniya materialov       | 7,102 s      | uspeshno   |
| [korenj] Regressii planirovsjhika smoke posle rannego okhvata  | 1,761 s      | neuspeshno |
| [korenj] Granicyi drejfa i otslezhivayemogo reyestra            | 2,033 s      | uspeshno   |
| [korenj] Regressii poryadka s novyim rannim shagom             | 1,769 s      | uspeshno   |
| [korenj] Granica prinimayusjhego kontura i rannij poryadok      | 0,186 s      | neuspeshno |
| [korenj] Prinimayusjhij kontur s polnoj konfiguraciyej fiksturyi | 0,345 s      | uspeshno   |
| [korenj] Profilj rannego otkaza na otkryitoj fiksture        | 0,659 s      | uspeshno   |
| [korenj] Regressii rannego sostava sozdaniya kommita         | 3,948 s      | uspeshno   |
| [korenj] Polya kontroljnoj tochki rannego okhvata              | 0,075 s      | uspeshno   |
| [korenj] Publikacionnaya chistota rannego okhvata              | 33,738 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 53,53 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:f0a5f8a3b70ad3508a0102dcb5c009be45543ba4baa51e2f4006279c662ce50d.
Kontekst soderzhimogo: sha256:6613f0ccab912dfd55217d7f1a369ceb888fe813a30f84cfd70ab1b23a7471d8.
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

## Rezuljtat i granicyi

CLI ispoljzuyet vyidelennyij obsjhij razbor okhvata bez izmeneniya nezavisimogo razresheniya kommita. Smoke zapuskayet yego posle build/validate reyestra i do proyekcii; itogovaya svyaznostj ostayotsya. Rannij rezuljtat proveryayet puti i povtorno sveryayet zapros, status, HEAD i ref, no ne vyidayot polnogo snimka soderzhimogo vsekh izmenyonnyikh fajlov ili indeksa.

RED CLI: 4 otkaza iz-za otsutstvuyusjhego fajla. GREEN: 4/4; rasshirennyiye granicyi otslezhivayemogo reyestra i drejfa: 6/6 za 1,951 s. Plan: RED vyiyavil otsutstviye shaga; GREEN 2/2. Posle revjyu dobavlen prinimayusjhij kontur: pervaya fikstura ne soderzhala obyazateljnoj .codex/config.toml i byila otklonena do proveryayemogo CLI; ispravlennaya proshla 3/3 za 0,235 s. Prezhnij okhvat: 16/16 za 7,018 s. V regressii planirovsjhika snachala ne obnovlyon ozhidayemyij srez rannikh shagov; posle ispravleniya 69/69 za 1,657 s. Vse promezhutochnyiye otkazyi sokhranenyi.

Profilj na 203 fajlakh: tri otdeljnyikh zapuska CLI, mediana 156 089 333 ns. Nepokryityij reyestr otklonyon, vkhodyi i Git-status ne izmenilisj, otvetyi sovpali. Sozdaniye fiksturyi i proverka neizmennosti vne tajmera; proyekciya ne zapuskalasj. Ekonomiya obsjhego vremeni i tokenov poka ne izmerena. Profilj sokhranyon [mashinno](materialyi/profilj-okhvata.json).

Dokumentaciya standartnogo kontura obnovlena: 13 rannikh shagov i 13 testovyikh naborov pri vklyuchyonnoj sessii. Kornevoj poljzovateljskij scenarij ne menyayetsya, README ne perepisyivayetsya. Polnaya priyomka novogo shaga yesjhyo predstoit; kontroljnaya tochka ne podmenyayet yeyo.

Regressiya rannego sostava sozdaniya kommita takzhe vyipolnena uspeshno; podrobnosti i dliteljnostj privedenyi v mashinnoj istorii zapuskov.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Predyidusjhaya priyomka](../2026-09-19_06-20-43_MSK_prinyatj-podgotovku-proverok-i-kommita/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 07:28:58 MSK -->
<!-- content-sha256: sha256:a5d3b062ba878668bea5b3d31379a97c1acd6aee6d5dd8226bd2d4cc9e08448b -->
<!-- FUM-MD-RECENCY:END -->
