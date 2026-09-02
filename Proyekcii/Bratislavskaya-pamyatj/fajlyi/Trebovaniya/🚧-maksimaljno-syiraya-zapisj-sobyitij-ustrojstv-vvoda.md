# Maksimaljno syiraya zapisj sobyitij ustrojstv vvoda

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0008 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna s maksimaljno dostupnoj na kazhdoj podderzhivayemoj platforme tochnostjyu poluchatj i dolgovremenno sokhranyatj sobyitiya obyyavlennyikh podderzhivayemyimi ustrojstv vvoda do neobratimogo svedeniya k zhestam, komandam interfejsa i smyislovyim interpretaciyam.

«Maksimaljno syiraya» oznachayet naiboleye rannij publichno podderzhivayemyij i publikacionno dopustimyij sloj konkretnoj platformyi. Trebovaniye ne obesjhayet apparatnyiye otchyotyi tam, gde operacionnaya sistema ikh ne predostavlyayet, ne razreshayet obkhod sistemnoj zasjhityi i ne pozvolyayet schitatj semejstvo ustrojstv podderzhannyim po analogii s drugim semejstvom bez sobstvennoj proverki.

Obsjhaya celj razdelena na samostoyateljno realizuyemyiye konturyi fizicheskoj klaviaturyi, myishi, kontaktnyikh poverkhnostej i perjyevyikh ustrojstv. Oni ispoljzuyut yedinyij kontrakt pervichnoj trassyi, a poperechnoye trebovaniye zasjhisjhyonnogo sbora zadayot dopustimyiye usloviya nablyudeniya i khraneniya.

## Semanticheskiye svyazi

- **sostoit iz:** [versionirovannoj pervichnoj trassyi sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — vse semejstva sokhranyayut nablyudeniya i diagnostiruyemyiye poteri v obsjhem dolgovremennom kontrakte.
- **sostoit iz:** [fizicheskikh perekhodov klavish](🚧-fizicheskiye-perekhodyi-klavish.md) — klaviaturnyij kontur sokhranyayet fizicheskiye fazyi, storonyi i identichnostj klavish bez avtopovtora.
- **sostoit iz:** [maksimaljno syiroj zapisi sobyitij myishi](🟡-maksimaljno-syiraya-zapisj-sobyitij-myishi.md) — myishj proveryayetsya otdeljno po knopkam, peremesjheniyu, prokrutke i razlichimosti ustrojstv.
- **sostoit iz:** [maksimaljno syiroj zapisi sobyitij kontaktnyikh poverkhnostej](🟡-maksimaljno-syiraya-zapisj-sobyitij-kontaktnyikh-poverkhnostej.md) — trekpad i drugiye mnogotochechnyiye poverkhnosti sokhranyayut otdeljnyiye kontaktyi do zhestov.
- **sostoit iz:** [maksimaljno syiroj zapisi sobyitij perjyevyikh ustrojstv](🟡-maksimaljno-syiraya-zapisj-sobyitij-perjyevyikh-ustrojstv.md) — stilus i graficheskij planshet sokhranyayut fazyi i fizicheskiye izmereniya do postroyeniya shtrikhov.
- **zavisit ot:** [zasjhisjhyonnogo sbora chuvstviteljnogo vvoda](🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md) — nablyudeniye dopustimo toljko pri yavnom vklyuchenii, minimaljnyikh pravakh i upravlyayemom lokaljnom khranenii.
- **dopolnyayet:** [polnoekrannoye prilozheniye bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — predostavlyayet yego osnovnomu poljzovateljskomu konturu nablyudayemyij i vosproizvodimyij potok dejstvij cheloveka, ostavayasj samostoyateljnyim mezhplatformennyim trebovaniyem.

## Kriterii proverki

- dlya kazhdoj zayavlennoj paryi platformyi i semejstva ustrojstva vyipolnenyi kriterii sootvetstvuyusjhej dochernej kartochki i sokhranyon vosproizvodimyij sravniteljnyij otchyot;
- sobyitiya vsekh podderzhivayemyikh semejstv postupayut v obsjhij kontrakt trassyi do zhestov, komand i smyislovoj interpretacii;
- sovmestnyij scenarij ne meneye chem s dvumya semejstvami ustrojstv sokhranyayet proiskhozhdeniye, vremennyiye dannyiye i identichnostj istochnikov, dostatochnyiye dlya povtornogo postroyeniya proizvodnyikh dejstvij;
- nepodderzhivayemoye pole, ustrojstvo ili platforma oboznachayutsya yavno i ne schitayutsya realizovannyimi po nalichiyu pokhozhego API libo drugogo semejstva;
- status i oblastj gotovnosti kazhdogo kontura chitayutsya iz yego sobstvennoj kartochki, a integracionnyij status roditelya ne podmenyayet eti proverki;
- novoye semejstvo ustrojstv vklyuchayetsya v zayavlennuyu oblastj toljko posle otneseniya k susjhestvuyusjhej kartochke s temi zhe polyami i kriteriyami libo posle sozdaniya otdeljnogo samostoyateljno proveryayemogo trebovaniya.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: sostavnoye trebovaniye realizuyetsya. Klaviaturnyij kontur i karkas obsjhej trassyi imeyut dejstvuyusjhij Swift-prototip, a myishj, kontaktnyiye poverkhnosti, perjyevyiye ustrojstva i polnyij zasjhisjhyonnyij zhiznennyij cikl khraneniya poka zaplanirovanyi. Detaljnyij status kazhdoj chasti zakreplyon v yeyo kartochke.

Do statusa `✅` dolzhnyi byitj vyipolnenyi vse vkhodyasjhiye kartochki v yavno obyyavlennoj matrice podderzhivayemyikh platform i ustrojstv i podtverzhdyon ikh sovmestnyij potok. Zapisj ekrana, audio, setevyikh sobyitij, sintez vvoda, raspoznavaniye zhestov i vyibor konkretnyikh naznachenij nakhodyatsya vne etoj kartochki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:aef5590175abe60a89c0c88a8a89ad49e4a8cadc0b6822afd25e735d49218c54 -->
<!-- FUM-MD-RECENCY:END -->
