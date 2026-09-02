# Poljzovateljskoye perenapravleniye nepreryivnogo agentskogo cikla

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0017 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna podderzhivatj logicheski prodolzhayusjhijsya [agentskij cikl](../Glossarij/agentskij-cikl.md), v kotorom novyij razreshyonnyij poljzovateljskij vkhod mozhet izmenitj daljnejshuyu rabotu, ne dozhidayasj poteri uzhe sokhranyonnogo sostoyaniya. Na blizhajshej bezopasnoj kontroljnoj tochke cikl dolzhen svyazatj vkhod s prezhnim sostoyaniyem i zanovo vyibratj nablyudayemoye prodolzheniye: sokhranitj ili utochnitj celj, izmenitj prioritet libo plan, perejti v druguyu vetku, priostanovitj ili zavershitj rabotu libo zaprositj utochneniye.

Izmeneniye «trayektorii myishleniya» proveryayetsya cherez nablyudayemyiye celj, prioritet, plan, vetku, vyibrannoye dejstviye, proverku i sleduyusjheye prodolzheniye, a ne cherez dostup k skryityim rassuzhdeniyam modeli. Nepreryivnostj upravlyayusjhego kontura ne oznachayet nepreryivnyij inference: otdeljnyiye modeljnyiye shagi, zadachi i dejstviya mogut byitj diskretnyimi, poka pamyatj, proiskhozhdeniye i pravilo vozobnovleniya svyazyivayut ikh v odin proveryayemyij khod rabotyi.

## Semanticheskiye svyazi

- **usilivayetsya:** [avtonomnyim modeljnyim prodolzheniyem pri ozhidanii podtverzhdeniya](🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md) — ozhidaniye signala blokiruyet toljko podtverzhdayemyij perekhod, poka bezopasnaya produktivnaya modeljnaya rabota ostayotsya vozmozhnoj.
- **usilivayetsya:** [nepreryivnyim sobyitijnyim nablyudeniyem poljzovateljskogo vvoda](🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md) — korobochnaya forma perenosit perenapravleniye s granic soobsjhenij-zadach na razreshyonnyiye sobyitiya, postupayusjhiye vo vremya rabotyi.
- **dopolnyayet:** [vyibor sleduyusjhego shaga vetki iz kartochek shagov](✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md) — obobsjhayet uzhe proverennuyu smenu prodolzheniya mezhdu diskretnyimi zadachami do kontrakta rabotayusjhego produktovogo cikla.

## Kriterii proverki

- determinirovannyij scenarij zapuskayet cikl s nezavershyonnyim planom, vvodit novyij razreshyonnyij poljzovateljskij signal do terminaljnogo sostoyaniya i podtverzhdayet yego priyom vo vremya rabotyi;
- na blizhajshej obyyavlennoj bezopasnoj kontroljnoj tochke cikl libo sokhranyayet prezhnij plan s obyyasnimyim osnovaniyem, libo izmenyayet celj, prioritet, plan, vetku ili dejstviye;
- trassa svyazyivayet prezhneye sostoyaniye, poljzovateljskij vkhod, resheniye o perenapravlenii, otmenyonnyiye libo otlozhennyiye dejstviya i novoye prodolzheniye, ne raskryivaya skryityiye rassuzhdeniya modeli;
- neobratimoye ili uzhe nachatoye dejstviye ne obyyavlyayetsya prervannyim bez nablyudayemogo rezuljtata; yesli nemedlennaya ostanovka nebezopasna, cikl pokazyivayet zaderzhku i tochku, v kotoroj izmeneniye vstupit v silu;
- seriya otdeljnyikh modeljnyikh ili zadachnyikh zapuskov sokhranyayet ustojchivuyu identichnostj rabotyi, sostoyaniye i proiskhozhdeniye, dostatochnyiye dlya proveryayemogo vozobnovleniya posle pauzyi ili sboya;
- dejstvuyusjhij Git + Codex-kontur prinimayetsya kak povedencheskij prototip perenapravleniya na granicakh diskretnyikh zadach i kommitov, no sam po sebe ne zaschityivayetsya sobstvennyim runtime korobochnoj FUM.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano. Tekusjhij dokumentacionnyij prototip svyazyivayet diskretnyiye sessii prichinnoj cepochkoj vetochnyikh kommitov i obyazateljnyikh prodolzhenij, a poljzovateljskiye zadachi mogut menyatj pamyatj, trebovaniya i posleduyusjhij whitelist. Odnako vneshnij runtime Codex i strogaya FIFO-ocheredj ne dokazyivayut sobstvennyij postoyanno dostupnyij runtime FUM ili nemedlennoye vyitesneniye uzhe dopusjhennoj zadachi.

Kartochka ne dayot agentu novyikh prav, ne trebuyet beskonechnogo modeljnogo processa i ne razreshayet nachalo korobochnoj stadii. Politika prioritetov, bezopasnyiye kontroljnyiye tochki, byudzhet, vosstanovleniye i dopustimaya zaderzhka perenapravleniya trebuyut otdeljnoj realizacii i proverki.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-29 09:04:03 MSK — Rasshiritj dinamicheskij vyibor sleduyusjhego shaga](../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [pasport dokumentacionnogo prototipa i pervogo korobochnogo sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:a9b82177f9d0af25ab34c70dc3d377840ddbfd1cb891334a2fc4e18da4ef6d40 -->
<!-- FUM-MD-RECENCY:END -->
