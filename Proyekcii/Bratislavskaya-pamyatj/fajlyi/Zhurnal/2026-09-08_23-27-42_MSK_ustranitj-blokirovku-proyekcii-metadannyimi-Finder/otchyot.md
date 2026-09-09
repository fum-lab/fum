# Otchyot 2026-09-08 23:27:42 MSK - Ustranitj blokirovku proyekcii metadannyimi Finder

Obyichnyiye metadannyiye Finder boljshe ne blokiruyut proverku i vosstanovleniye fizicheskoj proyekcii. Isklyucheniye otnositsya toljko k obyichnomu fajlu s tochnyim imenem `.DS_Store`; tip, neizvestnyiye obyyektyi, upravlyayemyiye bajtyi i kvitanciya ostayutsya proveryayemyimi granicami.

## Polnomochiya i otvetyi na komandyi

- Prioritetnoye ispravleniye: kornevaya zadacha vyidelila uzkuyu dochernyuyu rabotu posle povtornogo poyavleniya metadannyikh Finder pri realjnoj peresborke. Incident FUM-SBOJ-0034 vedyot korenj; novyij nomer zdesj ne sozdayotsya.
- Paralleljnaya rabota: rolj FUM Razrabotchik, sobstvennaya vetka `codex/metadata-finder-projection-01a07d3d` ot `a7e0bbbf20d1fa8dba984d4ce156f6a819c5add6`. Posledovateljno pereispoljzovano naznachennoye docherneye derevo posle zaversheniya LinguisticKit. Chuzhiye derevjya i bibliotechnyij PR ne izmenyayutsya.
- Publikaciya kommitov: podgotovlennaya kontroljnaya tochka otpravlyayetsya toljko v sobstvennuyu vetku origin. Integraciyu i polnuyu proverku realjnogo pokoleniya vyipolnyayet korenj.
- Doslovnyiye komandyi vosstanovlenyi iz polnyikh zapisej kornevogo JSONL: stroki 8251, 9741 i 10270; iskhodnyiye vremennyiye metki i granica chteniya sokhranenyi vne checkout. Delegirovaniye kornya ne vyidano za otdeljnuyu poljzovateljskuyu repliku.

## Kontrakt i realizaciya

Obsjhij klassifikator isklyuchayet obyichnyij `.DS_Store` iz upravlyayemogo snimka na vsekh urovnyakh: proizvodnoye prostranstvo, zhivoye pokoleniye, vremennyiye i rezervnyiye derevjya, sluzhebnyij korenj i chastichnaya zapisj. Soderzhimoye i prava obyichnyikh metadannyikh ne zadayut pokoleniye. Ssyilka, katalog, FIFO i blizkoye imya ne poluchayut isklyucheniya.

Read-only proverka sokhranyayet fizicheskiye metadannyiye i sveryayet upravlyayemyiye bajtyi. Ochistka polnogo dereva snachala obsleduyet vse obyyektyi i proveryayet prinadlezhnostj snimku; metadannyiye ne udalyayutsya, yesli najden pozdnij neizvestnyij obyyekt. Pered udaleniyem povtorno proveryayutsya inode, ustrojstvo i tip; operacii vyipolnyayutsya cherez deskriptor kataloga bez perekhoda po ssyilkam. Pustyiye dokazannyiye katalogi ochisjhayutsya otdeljnoj nerekursivnoj funkciyej. Pozdnyaya podmena i ostatochnyij novyij obyyekt vyizyivayut otkaz bez beskonechnogo povtora.

Pri sboye vosstanovleniya povtorno vyibrasyivayetsya iskhodnyij obyyekt isklyucheniya. Vtoraya prichina dobavlyayetsya zametkoj; CLI otdeljno pechatayet zametki pojmannoj OshibkiKontrakta. Ispravlenyi obe tochki obrabotki otkaza ustanovki.

V instrukcii generatora postanovka vsej proyekcii v indeks yavno isklyuchayet `.DS_Store`. Sam generator indeks ne izmenyayet. Korenj vyibral yesjhyo boleye stroguyu postanovku tochnyikh putej proverennogo manifesta.

## Profilj vremeni vyipolneniya

| Stadiya                | Dliteljnostj   | Granicyi i sposob izmereniya                                     |
| --------------------- | -------------- | -------------------------------------------------------------- |
| Pervyij RED            | 3,720 s        | Pyatj novyikh testov; vyivod unittest vnutri uchtyonnogo processa    |
| Pervyij GREEN          | 10,115 s       | Te zhe pyatj testov posle ispravleniya                            |
| Avtonomnyij nabor      | 87,029 s       | 122 testa Python; bez Swift i realjnoj proyekcii                |
| Izmereniye operacij    | sm. profilj    | Devyatj chereduyusjhikhsya povtorov kazhdogo varianta, perf_counter_ns |
| Polnaya priyomka FUM    | ne vyipolnyalasj | Otdeljnaya rabota kornya posle integracii                        |
| Analiz i dokumentaciya | ne izmereno    | Nepreryivnyij tajmer ne ustanavlivalsya                           |

Granica profilya: otdeljnyiye operacii na sinteticheskom dereve; podgotovka fajlov isklyuchena iz vremeni chteniya i udaleniya. Vklyuchenyi shtatnyiye metki chteniya i yavnaya metka preflight s udaleniyem; ikh intervalyi ne skladyivayutsya s vremenem processa.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                               | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------- | ------------ | --------- |
| [Metadannyiye Finder] RED: metadannyiye Finder i sokhraneniye prichin      | 3,901 s      | neuspeshno |
| [Metadannyiye Finder] GREEN: metadannyiye Finder i sokhraneniye prichin    | 10,301 s     | uspeshno   |
| [Metadannyiye Finder] RED: vtoraya prichina shtatnoj oshibki CLI          | 0,211 s      | neuspeshno |
| [Metadannyiye Finder] GREEN: polnyij avtonomnyij nabor proyekcii         | 87,202 s     | uspeshno   |
| [Metadannyiye Finder] Profilj: chteniye i bezopasnaya ochistka s Finder   | 3,925 s      | uspeshno   |
| [Metadannyiye Finder] Publikacionnaya chistota kontroljnoj tochki Finder | 17,554 s     | uspeshno   |
| [Metadannyiye Finder] Struktura Zhurnala kontroljnoj tochki Finder      | 12,645 s     | uspeshno   |
| [Metadannyiye Finder] Proveritj exact diff kontroljnoj tochki Finder   | 0,023 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 135,762 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:7626fa8e63df6adfb90ef32e9bf362262e5c917b308334a7c7fb3572d230dc93.
Kontekst soderzhimogo: sha256:cb634decec98dbceb31c1718b114dcda74d757ab678d8cd17f85c9bf767fd8fd.
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

## Proverki i TDD

Pervyij RED: pyatj testov, semj oshibok podsluchayev. Obyichnyij Finder-fajl blokiroval vosstanovleniye, chteniye i ochistku; recovery skryival iskhodnyij RuntimeError. Otricateljnyiye tipyi uzhe otklonyalisj. Pervyij GREEN: pyatj testov proshli.

Otdeljnyij RED shtatnogo CLI podtverdil, chto iskhodnyij otkaz pechatalsya, a vtoraya prichina teryalasj. Posle ispravleniya polnyij avtonomnyij nabor: 122 testa, vklyuchaya vosemj novyikh, proshyol za 87,029 s. Proverenyi chetyire stadii vosstanovleniya, chastichnaya zapisj, sokhraneniye fizicheskikh bajtov pri chtenii, neizvestnyij obyyekt do ochistki i pozdnyaya podmena metadannyikh ssyilkoj.

[Profilj operacij](materialyi/profilj.json) soderzhit 27 izmerenij. Dlya kazhdogo varianta ispoljzovano 512 fajlov po 4096 bajt v 32 katalogakh; variant Finder dobavlyayet 33 fajla metadannyikh. Vse upravlyayemyiye snimki sovpali s bazoj, khyesh `sha256:3704043f08423f1c249ef707b38942043d691df7577356d4330942c780ef2b90`. Vse dokazannyiye derevjya uspeshno udalenyi. Fizicheskiye testovyiye derevjya i iskhodnyiye diagnosticheskiye logi nakhodyatsya vne publichnogo checkout.

## Resheniye ob optimizacii

Mediana chteniya: baza 16,915 ms; ispravleniye bez metadannyikh 17,042 ms; s Finder 18,474 ms. Mediana polnogo preflight i udaleniya: 61,377; 61,042 i 67,432 ms sootvetstvenno. Bez metadannyikh zametnoj regressii ne obnaruzheno; dopolniteljnyij obkhod 33 fajlov stoit okolo 1,43 ms chteniya i 6,39 ms ochistki otnositeljno ispravleniya bez nikh.

Prinyato sokhranitj povtornuyu proverku identichnosti i polnyij preflight. Dopolniteljnoye keshirovaniye libo sokrasjheniye proverki ne opravdanyi. Ispravleniye ustranyayet oshibochnuyu ostanovku, a ne dokazyivayet uskoreniye polnoj realjnoj peresborki. Chteniye, sravneniye i udaleniye ne menyayut upravlyayemyiye bajtyi. Vyivod obeikh oshibok otnositsya toljko k avarijnomu puti i otdeljno podtverzhdyon testami; yego skorostj ne opredelyayet shtatnuyu peresborku.

## Priyomka i prodolzheniye

Eto kontroljnaya tochka dochernej rabotyi s otkryitoj v4-istoriyej, a ne finaljnaya priyomka vsego FUM. Polnaya proyekciya namerenno ne zapuskalasj. [Ogranichennyij plan](materialyi/prodolzheniye.json) otnositsya toljko k etoj dochernej rabote; korenj prodolzhayet postoyannuyu zadachu i samostoyateljno proveryayet obyyedinyonnyij rezuljtat.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Lokaljnyij navyik proyekcii](../../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 23:47:16 MSK -->
<!-- content-sha256: sha256:58bf49ca1b8d95282d9d613c5f9d8757f5d6716ed0f86defd65378c306eb3f9b -->
<!-- FUM-MD-RECENCY:END -->
