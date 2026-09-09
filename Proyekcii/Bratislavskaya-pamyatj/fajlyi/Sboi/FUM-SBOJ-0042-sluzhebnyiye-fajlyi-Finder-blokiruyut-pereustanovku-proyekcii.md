+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0042"
"статус" = "устранена"
+++
# Sluzhebnyiye fajlyi Finder blokiruyut pereustanovku proyekcii

Standartnaya priyomka otkazala pri vosstanovlenii strogoj proizvodnoj oblasti iz-za obyichnogo `.DS_Store`. Git-ignore ne isklyuchayet fizicheskij fajl iz obsledovaniya. Zasjhita ot neizvestnyikh obyyektov srabotala korrektno, no postoronneye sostoyaniye obnaruzheno posle dliteljnogo preobrazovaniya.

## Nablyudayemyij sboj i granica povtoreniya

Mekhanizm okhvatyivayet neizvestnoye mashinnoye sostoyaniye v oblasti proyekcii, obnaruzhivayemoye posle dorogoj podgotovki. On otlichayetsya ot razreshyonnogo sostoyaniya `.obsidian/` i ot oshibok soderzhimogo vkhodnyikh materialov. Avtor i moment sozdaniya fajlov ne ustanovlenyi.

## Proyavleniya

- `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0001`: [zapusk № 9](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/materialyi/zapuski-proverok/9_5cdf4d33-440b-4162-9fb9-98d3cda2f705.json), shag primeneniya 974,511 s. Neposredstvennyij otkaz vosstanovleniya vyizval `Proyekcii/.DS_Store`; yesjhyo tri obyichnyikh fajla najdenyi v celevom pokolenii, yego `fajlyi` i sluzhebnom kataloge. Eto odno proyavleniye. Oshibka vosstanovleniya zamenila pervonachaljnoye isklyucheniye; yego tochnaya prichina ne ustanovlena.

- `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0002`: [zapusk № 16](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/materialyi/zapuski-proverok/16_1bf1c3ce-f0d6-42ca-a369-ae8b003ad87a.json), povtornyij rannij otkaz vosstanovleniya za 0,449 s. Posle poyavleniya dvukh fajlov podgotoviteljnaya ochistka sama otkazala na sravnenii metadannyikh, no korenj oshibochno zapustil smoke sledom. K etomu momentu preobrazovaniye yesjhyo ne zapuskalosj. Povtornaya ochistka zavershena posle sverki dev/ino/mode/size/mtime/ctime i tochnyikh bajtov, isklyuchayusjhej vremya chteniya iz identichnosti.

## Vosstanovleniye i sistemnaya mera

Pervonachaljnaya ruchnaya ochistka zamenena podderzhkoj izvestnogo tipa metadannyikh. Generator isklyuchayet iz snimka toljko obyichnyij `.DS_Store`, ignoriruyemyij Git po fizicheskomu puti. Sokhranyayemyij katalog ostavlyayet yego na meste; pered udaleniyem prinadlezhasjhego generatoru kataloga fajl atomarno perenositsya v privatnyij arkhiv Git-dir. Ostaljnyiye neizvestnyiye obyyektyi i otsutstviye kvitancii po-prezhnemu vyizyivayut otkaz.

RED/GREEN, otricateljnyiye scenarii i vosstanovleniye chetyiryokh faz podtverdili predmetnuyu meru. Profilj izmeril yeyo stoimostj otdeljno ot Release-preobrazovaniya; rezuljtatyi nakhodyatsya v otchyote i materialakh tekusjhej priyomki. Proizvoljnyiye neizvestnyiye fajlyi ne obyyavlyayutsya razreshyonnyimi, a odnokratnaya ochistka ne ispoljzovana kak dokazateljstvo zakryitiya.

## Svyazannyiye shagi

- [FUM-STEP-0169 — Sokhranyatj metadannyiye Finder pri pereustanovke proyekcii](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0169-sokhranyatj-metadannyiye-Finder-pri-pereustanovke-proyekcii.md); osnovaniya — `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0001` i `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0002`.

## Kriterii zakryitiya

Sistemnoye predotvrasjheniye podtverzhdeno adresnoj regressiyej i vyipolneniyem svyazannogo shaga; yedinichnaya ochistka ne yavlyayetsya zakryitiyem.

## Istochniki

- [Otchyot tekusjhej priyomki](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 19:56:38 MSK -->
<!-- content-sha256: sha256:298d6c7bc07918603187b0d81759a0791a698115a39ac00e12600bfbb86bc454 -->
<!-- FUM-MD-RECENCY:END -->
