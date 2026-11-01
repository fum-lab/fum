# Otchyot 2026-09-19 07:31:58 MSK - Prinyatj rannij okhvat izmenenij

Prodolzhayetsya komanda «Prodolzhaj drugiye rabotyi.». D22 ostayotsya na pauze. Kontroljnaya tochka ef865324a4dd613760d4e72119b64f29cfea2049 dostavlena v origin/fuma; tochnyij OID, derevo, roditelj, soobsjheniye, identichnosti i chistota dereva proverenyi. Sejchas vyipolnyayetsya obsjhaya priyomka rannego okhvata posle sborki reyestra i do dorogoj proyekcii.

Adresnyiye RED/GREEN, profilj 203 fajlov i nezavisimoye read-only revjyu sokhranenyi v J35. Regressii okhvata i planirovsjhika proshli. Novyij shag proveryayet pokryitiye putej; on ne podmenyayet proverku polnogo snimka ili nezavisimyij razreshyonnyij sostav kommita. Prinimayusjhij kontur podtverzhdyon ispolneniyem s otdeljnyim kornem i namerenno neprigodnyimi odnoimyonnyimi fajlami kandidata.

## Sverka dokumentacii

Navyik kompleksnoj proverki opisyivayet 13 rannikh shagov i 13 testovyikh naborov. Kornevoj poljzovateljskij scenarij ne izmenilsya, README ne trebuyet izmeneniya. Do uspeshnogo zakryitiya, manifesta i kommita priyomka ostayotsya nezavershyonnoj; posledneye prinyatoye pokoleniye — J34, 78a3d9f12c8f2cbf8b6429122583b2155f036d37.

## Profilj vremeni vyipolneniya

| Stadiya                      | Dliteljnostj | Granicyi i sposob izmereniya                         |
| --------------------------- | ------------ | -------------------------------------------------- |
| Podgotovka itogovogo snimka | ne izmereno  | Zhurnal i sokhraneniye proiskhozhdeniya do proverok      |
| Standartnaya priyomka         | ne izmereno  | Fakticheskaya dliteljnostj fiksiruyetsya obyortkoj nizhe |

Granica profilya: fakticheskiye vyizovyi uchityivayet obyortka. Finaljnoye zamyikaniye proyekcii vyipolnyayetsya otdeljno posle zakryitiya. Kalendarnoye vremya razrabotki zadnim chislom ne vyichislyayetsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:787aa90144e1f1a7a4ceb8578809bbe9fbed0ad3e42cc165351c45c85d6d8c12 -->

| Vyizov                                                   | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------- | ------------ | --------- |
| [korenj] Pervaya proverka polej priyomki rannego okhvata   | 1,851 s      | uspeshno   |
| [korenj] Standartnaya priyomka rannego okhvata do proyekcii | 1567,284 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1569,135 s.

Priyomochnyiye raundyi: gotov.
Kontekst Git-snimka: sha256:8ff1f7139dc2497c572440aad16a9274eea1120958e3cf07ad42382b2542531e.
Kontekst soderzhimogo: sha256:7d1fa8b6784e0a8d641bf118018b4479930b4ed2156709142a96b18dcdf2e1c7.
Polnyikh popyitok: 1; uspeshnyikh: 1.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: vyipolneno.
Usloviye «snimok sovpadayet»: vyipolneno.
Usloviye «soderzhimoye sovpadayet»: vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Realizaciya i adresnyiye rezuljtatyi](../2026-09-19_07-18-51_MSK_proveryatj-sostav-do-proyekcii/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 07:33:01 MSK -->
<!-- content-sha256: sha256:0a70bea702171bbefc2486aba6e6d6fe755b1fb9d5868533f68608788b5e7aa1 -->
<!-- FUM-MD-RECENCY:END -->
