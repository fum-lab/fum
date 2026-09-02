# Izolirovannoye paralleljnoye ispolneniye i proveryayemaya integraciya

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0025 -->

Ekspluatacionnyij status: otlozheno. Kartochka sokhranyayet paralleljnoye writer/reviewer/integrator/candidate/CAS-ispolneniye kak celevuyu arkhitekturu; yeyo imperativnyij tekst ne dejstvuyet kak marshrut tekusjhej ruchnoj zapisi.

FUM dolzhen ispolnyatj nezavisimo gotovyiye pishusjhiye shagi paralleljno v otdeljnyikh klonakh i unikaljnyikh Git-vetkakh, a ikh kandidatnyiye commit integrirovatj v odnu celevuyu vetku posledovateljno, atomarno i s povtornoj proverkoj. Paralleljnoye proizvodstvo variantov ne dolzhno sozdavatj neskoljkikh nekoordinirovannyikh pisatelej odnoj integracionnoj vetki.

## Semanticheskiye svyazi

- **zavisit ot:** [kommitiruyemyikh vkladov pishusjhikh poduzlov FUM](✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md) — integracionnyij kontur prinimayet toljko adresuyemyiye kandidatnyiye commit s proveryayemyim proiskhozhdeniyem.
- **zavisit ot:** [vyibora sleduyusjhego shaga vetki iz kartochek shagov](✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md) — kazhdaya rabochaya vetka voznikayet iz tochnoj versii kanonicheskoj kartochki, a ne iz neogranichennogo zadaniya.
- **trebuyetsya dlya:** [ogranichennogo avtomaticheskogo razresheniya Git-konfliktov](✅-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md) — resolver primenyayetsya toljko vnutri serializovannoj popyitki integracii s zakreplyonnyimi roditelyami.
- **trebuyetsya dlya:** [repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md) — peredacha rezuljtata vverkh trebuyet proveryayemogo kontura vklyucheniya commit libo obnovleniya gitlink.
- **trebuyetsya dlya:** [upravlyayemogo ispolneniya cepochek universaljnyimi fork-poduzlami](🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md) — neskoljko dochernikh cepochek proizvodyat rezuljtatyi paralleljno, no prinyatiye odnoj celevoj vetki ostayotsya serializovannyim i proveryayemyim.
- **trebuyetsya dlya:** [dereva vetvevyikh fork i roditeljskoj moderacii](🟡-derevo-vetvevyikh-fork-i-roditeljskaya-moderaciya.md) — dva rebyonka rabotayut v raznyikh checkout i refs, a roditeljskoye resheniye publikuyetsya toljko otdeljnyim CAS-perekhodom.

## Kriterii proverki

- kazhdyij paralleljnyij zapusk poluchayet unikaljnyiye identifikatoryi zapuska, klona i polnogo ref vetki, tochnyij iskhodnyij `base_oid` i odin kontekstno posiljnyij rabochij paket;
- dva pishusjhikh ispolnitelya ne ispoljzuyut odin checkout, indeks ili rabochij ref, a vremennyiye lokaljnyiye puti ne popadayut v sokhranyayemyiye pasporta i prompt;
- integraciya odnoj celevoj vetki serializuyetsya otdeljnyim vladeljcem i publikuyet novyij ref toljko compare-and-swap otnositeljno proverennogo tekusjhego OID;
- beskonfliktnaya integraciya sokhranyayet iskhodnyiye commit poduzlov v Git-rodoslovnoj bez squash; integracionnyij commit ili fast-forward yavno svyazyivayet prinyatyiye rezuljtatyi s prezhnej vershinoj;
- izmeneniye celevoj vetki posle podgotovki otmenyayet publikaciyu starogo dereva i trebuyet novoj integracii i polnogo nabora proverok otnositeljno svezhej vershinyi;
- pered publikaciyej proveryayutsya proiskhozhdeniye, dopustimaya oblastj fajlov, otsutstviye sekretov i mashinnogo musora, avtonomnyiye testyi, celevyiye proverki i polnyij obyazateljnyij kontur roditeljskogo repozitoriya;
- chistoye tekstovoye sliyaniye ne schitayetsya dokazateljstvom smyislovoj sovmestimosti: validatoryi i testyi dolzhnyi obnaruzhivatj protivorechiya, kotoryiye Git ne predstavlyayet konfliktom;
- sboj do atomarnoj publikacii ne teryayet kandidatnyiye commit i ne ostavlyayet celevuyu vetku chastichno obnovlyonnoj, a tochnyij povtor odnoj integracionnoj popyitki idempotenten.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: yedinyij avtonomnyij local-bare scenarij paralleljno zapuskayet dva zakreplyonnyikh pishusjhikh paketa v raznyikh klonakh i unikaljnyikh vetkakh. Dva kandidatnyikh commit ne menyayut roditeljskij checkout; beskonfliktnyij rezuljtat publikuyetsya yedinstvennyim tochnyim CAS s sokhraneniyem kandidata v rodoslovnoj, a zaregistrirovannyij konflikt razreshayetsya otdeljnyim mnogoroditeljskim integracionnyim commit posle povtornyikh proverok. Neizvestnyij ili smyislovoj konflikt dayot `resolution_required`, kanonicheskuyu diagnostiku i dostizhimyiye kandidatnyiye refs, ne menyaya celevoj ref. Vosemj kontroliruyemyikh preryivanij proiskhodyat posle peredachi i proverki commit, neposredstvenno pered zamenoj sootvetstvuyusjhego ref; celi i kvitancii ostayutsya neizmennyimi, a tochnyij povtor zavershayet perekhod. Povtor vsego scenariya podtverzhdayet sovpadeniye shesti pasportov i diagnostik po yavnomu versionirovannomu profilyu i sovpadeniye itogovyikh derevjyev.

Trebovaniye ne obyyavlyayet vse shagi nezavisimyimi i ne razreshayet paralleljnyij zapusk pri obsjhej oblasti zapisi ili nerazreshyonnoj zavisimosti.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-05 00:37:53 MSK — Provesti avtonomnuyu skvoznuyu priyomku repozitornoj kompozicii](../Zhurnal/2026-08-05_00-37-53_MSK_provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii/zapros.md)
- [iskhodnyij zapros 2026-08-04 09:38:47 MSK — Podklyuchitj dolgovechnyij fork-poduzel i peredachu vverkh](../Zhurnal/2026-08-04_09-38-47_MSK_podklyuchitj-dolgovechnyij-fork-poduzel-i-peredachu-vverkh/zapros.md)
- [iskhodnyij zapros 2026-08-03 21:37:49 MSK — Dobavitj CAS-integraciyu beskonfliktnyikh kommitov](../Zhurnal/2026-08-03_21-37-49_MSK_dobavitj-CAS-integraciyu-beskonfliktnyikh-kommitov/zapros.md)
- [iskhodnyij zapros 2026-08-03 18:46:53 MSK — Dobavitj izolirovannyij pishusjhij poduzel i kandidatnyij commit](../Zhurnal/2026-08-03_18-46-53_MSK_dobavitj-izolirovannyij-pishusjhij-poduzel-i-kandidatnyij-commit/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:0da15ac740e17272d619292936c50cc5f11fe70f520f35841e3b3cee9a2ca207 -->
<!-- FUM-MD-RECENCY:END -->
