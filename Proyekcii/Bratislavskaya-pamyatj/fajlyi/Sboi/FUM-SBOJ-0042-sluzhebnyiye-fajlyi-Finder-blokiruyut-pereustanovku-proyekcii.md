+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0042"
"статус" = "устранена"
+++
# Sluzhebnyiye fajlyi Finder blokiruyut pereustanovku proyekcii

Standartnaya priyomka otkazala pri vosstanovlenii strogoj proizvodnoj oblasti iz-za obyichnogo `.DS_Store`. Git-ignore ne isklyuchayet fizicheskij fajl iz obsledovaniya. Zasjhita ot neizvestnyikh obyyektov srabotala korrektno, no postoronneye sostoyaniye moglo poyavitjsya kak do polnogo obkhoda, tak i pozdno — mezhdu rekursivnoj ochistkoj kataloga i yego `rmdir`.

## Nablyudayemyij sboj i granica povtoreniya

Mekhanizm okhvatyivayet neizvestnoye mashinnoye sostoyaniye v oblasti proyekcii, obnaruzhivayemoye posle dorogoj podgotovki. On otlichayetsya ot razreshyonnogo sostoyaniya `.obsidian/` i ot oshibok soderzhimogo vkhodnyikh materialov. Avtor poyavleniya fajlov ne ustanovlen; dlya pozdnego `Directory not empty` podtverzhdena granica mezhdu odnorazovyim `listdir` i posleduyusjhim `rmdir` ochisjhennogo dochernego kataloga.

## Proyavleniya

- `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0001`: [zapusk № 9](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/materialyi/zapuski-proverok/9_5cdf4d33-440b-4162-9fb9-98d3cda2f705.json), shag primeneniya 974,511 s. Neposredstvennyij otkaz vosstanovleniya vyizval `Proyekcii/.DS_Store`; yesjhyo tri obyichnyikh fajla najdenyi v celevom pokolenii, yego `fajlyi` i sluzhebnom kataloge. Eto odno proyavleniye. Oshibka vosstanovleniya zamenila pervonachaljnoye isklyucheniye; yego tochnaya prichina ne ustanovlena.

- `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0002`: [zapusk № 16](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/materialyi/zapuski-proverok/16_1bf1c3ce-f0d6-42ca-a369-ae8b003ad87a.json), povtornyij rannij otkaz vosstanovleniya za 0,449 s. Posle poyavleniya dvukh fajlov podgotoviteljnaya ochistka sama otkazala na sravnenii metadannyikh, no korenj oshibochno zapustil smoke sledom. K etomu momentu preobrazovaniye yesjhyo ne zapuskalosj. Povtornaya ochistka zavershena posle sverki dev/ino/mode/size/mtime/ctime i tochnyikh bajtov, isklyuchayusjhej vremya chteniya iz identichnosti.

- `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0003`: [etap ispravleniya finaljnoj proyekcii](../Zhurnal/2026-09-15_13-00-53_MSK_ispravitj-sboj-finaljnoj-proyekcii/otchyot.md) posle zakryitiya finansovogo perenosa. Dve komandyi primeneniya zavershilisj `OSError: [Errno 66] Directory not empty: 'fajlyi'` na `os.rmdir(имя, dir_fd=дескриптор)` posle rekursivnoj ochistki dochernego kataloga. Posle vosstanovleniya receipt i sluzhebnyiye `.fum-*` katalogi otsutstvovali, a obyichnyiye `.DS_Store` snova prisutstvovali v proizvodnoj oblasti. RED vosproizvyol pozdneye poyavleniye `.DS_Store` pered `rmdir`; otdeljnyij otricateljnyij scenarij podtverdil, chto pozdnij neizvestnyij fajl ostayotsya otkazom.

## Vosstanovleniye i sistemnaya mera

Pervonachaljnaya ruchnaya ochistka zamenena podderzhkoj izvestnogo tipa metadannyikh. Generator isklyuchayet iz snimka toljko obyichnyij `.DS_Store`, ignoriruyemyij Git po fizicheskomu puti. Sokhranyayemyij katalog ostavlyayet yego na meste; pered udaleniyem prinadlezhasjhego generatoru kataloga fajl atomarno perenositsya v privatnyij arkhiv Git-dir. Yesli `rmdir` uzhe ochisjhennogo kataloga poluchayet `ENOTEMPTY`, generator povtorno otkryivayet tot zhe katalog bez perekhoda po ssyilkam, razreshayet toljko pozdnij obyichnyij ignoriruyemyij `.DS_Store`, sokhranyayet yego tem zhe arkhivnyim mekhanizmom i odin raz povtoryayet udaleniye. Ostaljnyiye neizvestnyiye obyyektyi, podmena kataloga i otsutstviye kvitancii po-prezhnemu vyizyivayut otkaz.

RED/GREEN, otricateljnyiye scenarii, vosstanovleniye chetyiryokh faz i novaya regressiya pozdnego `ENOTEMPTY` podtverdili predmetnuyu meru. Profilj izmeril stoimostj obyichnoj ochistki i vetki pozdnego Finder otdeljno ot Release-preobrazovaniya; rezuljtatyi nakhodyatsya v otchyotakh i materialakh sootvetstvuyusjhikh etapov. Proizvoljnyiye neizvestnyiye fajlyi ne obyyavlyayutsya razreshyonnyimi, a odnokratnaya ochistka ne ispoljzovana kak dokazateljstvo zakryitiya.

## Svyazannyiye shagi

- [FUM-STEP-0169 — Sokhranyatj metadannyiye Finder pri pereustanovke proyekcii](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0169-sokhranyatj-metadannyiye-Finder-pri-pereustanovke-proyekcii.md); osnovaniya — `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0001`, `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0002` i `FUM-СБОЙ-0042/ПРОЯВЛЕНИЕ-0003`.

## Kriterii zakryitiya

Sistemnoye predotvrasjheniye podtverzhdeno adresnoj regressiyej i vyipolneniyem svyazannogo shaga; yedinichnaya ochistka ne yavlyayetsya zakryitiyem.

## Istochniki

- [Otchyot tekusjhej priyomki](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).
- [Otchyot ispravleniya pozdnego Finder pered rmdir](../Zhurnal/2026-09-15_13-00-53_MSK_ispravitj-sboj-finaljnoj-proyekcii/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 13:12:42 MSK -->
<!-- content-sha256: sha256:03a070d4c58a89ab1cf6c004b451ad59b66d12c70c7f8e1923f6f1610a1a10dd -->
<!-- FUM-MD-RECENCY:END -->
