+++
schema_version = 1
card_id = "FUM-STEP-0113"
status = "active"
+++
# Dobavitj mezhvetochnuyu sinkhronizaciyu strukturnyikh migracij

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Obobsjhitj determinirovannyiye planyi strukturnyikh migracij do pre-merge-kontura, kotoryij privodit raznyiye Git-vetki ili lokaljno dostupnyiye forki k odnomu versionirovannomu pokoleniyu strukturyi do soderzhateljnogo sliyaniya. Kontur dolzhen sravnivatj tochnyiye iskhodnyiye snimki, primenyatj preobrazovaniya toljko v izolirovannyikh checkout, razlichatj strukturnyiye peremesjheniya i nezavisimyiye soderzhateljnyiye izmeneniya i vyidavatj proveryayemyij otchyot o skhodimosti bez avtomaticheskogo merge ili publikacii.

## Pochemu sejchas

Avtomatizaciya strukturyi papok zaprosov vvodit vosproizvodimyij `plan`, idempotentnyiye `apply` i `validate`, otnositeljnyiye puti i fail-closed-proverki. Eti svojstva obrazuyut lokaljnyij stroiteljnyij blok, no yesjhyo ne zadayut protokol soglasovaniya raznyikh istorij, versij preobrazovaniya i konfliktuyusjhikh soderzhateljnyikh izmenenij pered obyyedineniyem vetok ili forkov.

## Kriterii zaversheniya

- Mashinochitayemyij manifest imeyet versionirovannuyu skhemu, identichnostj preobrazovaniya, tochnyiye vkhodnyiye Git OID, toljko repozitorno-otnositeljnyiye operacii i proveryayemyiye predusloviya soderzhimogo bez absolyutnyikh putej checkout.
- Kontur prinimayet dve ili boleye tochnyiye lokaljno dostupnyiye linii, opredelyayet ikh strukturnyiye pokoleniya i stroit determinirovannyij poryadok neobkhodimyikh migracij bez vyivoda versii iz imeni vetki ili proiskhozhdeniya remote.
- Kazhdaya liniya preobrazuyetsya v otdeljnom izolirovannom checkout; obsjhij poljzovateljskij checkout, refs istochnikov i iskhodnyiye commit ostayutsya neizmennyimi do otdeljnogo integracionnogo resheniya.
- Preflight razlichayet chistoye strukturnoye peremesjheniye, paralleljnoye odinakovoye preobrazovaniye, nezavisimoye izmeneniye soderzhimogo, kolliziyu celevogo puti, raskhozhdeniye zasjhisjhyonnyikh pervichnyikh bajtov i nesovmestimuyu versiyu migracii.
- Sliyaniye razreshayetsya toljko posle sovpadeniya celevogo pokoleniya strukturyi i uspeshnoj proverki obeikh preobrazovannyikh linij; kontur sam ne vyipolnyayet merge, push, publikaciyu ili razresheniye soderzhateljnogo konflikta.
- Avtonomnyiye fiksturyi na lokaljnyikh bare-repozitoriyakh pokryivayut dve vetki obsjhego repozitoriya, dva forka s obsjhej bazoj, raznyij poryadok uzhe primenyonnyikh migracij, vyiigrannuyu skhodimostj, nesovmestimuyu skhemu i soderzhateljnyij konflikt posle strukturnogo vyiravnivaniya.
- Otchyot sokhranyayet proiskhozhdeniye vsekh vkhodnyikh OID, versii avtomatizacij, planyi, proverki i tochnuyu prichinu otkaza; povtor na tekh zhe snimkakh dayot tot zhe kanonicheskij rezuljtat.
- Postavka integriruyetsya s pasportom repozitornoj kompozicii i ne oslablyayet otdeljnyiye polnomochiya na polucheniye remote, izmeneniye refs, merge ili publikaciyu.

## Istochniki

- [iskhodnyij zapros 2026-08-03 11:49:04 MSK — Obyyedinitj zaprosyi i zhurnal](../../Zhurnal/2026-08-03_11-49-04_MSK_obyyedinitj-zaprosyi-i-zhurnal/zapros.md)
- [avtomatizaciya strukturyi papok zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov](../../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [FUM-STEP-0086 — CAS-integraciya beskonfliktnyikh kommitov](✅-FUM-STEP-0086-dobavitj-CAS-integraciyu-beskonfliktnyikh-kommitov.md)
- [FUM-STEP-0088 — dolgovechnyij fork-poduzel i peredacha vverkh](✅-FUM-STEP-0088-podklyuchitj-dolgovechnyij-fork-poduzel-i-peredachu-vverkh.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 11:39:23 MSK -->
<!-- content-sha256: sha256:a2f8ddeb4c4258b55eb4c8bdcafa114704efff14989ca9af5e0a90260595d539 -->
<!-- FUM-MD-RECENCY:END -->
