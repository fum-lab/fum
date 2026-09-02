# Otchyot 2026-07-21 12:18:37 MSK - Zakrepitj transliteraciyu nazvanij avtomatizacij

Rabochaya sessiya sdelala imya avtomatizacii proveryayemyim sostavnyim kontraktom. Smyislovoj istochnik zapisyivayetsya po-russki kirillicej, otobrazhayemaya latinskaya forma tochno vosproizvodit russkuyu tablicu LinguisticKit, a tekhnicheskij slug poluchayetsya otdeljnoj normalizaciyej FUM. Takoj poryadok ne vyidayotsya za universaljnyij ISO- ili GOST-standart i ne pozvolyayet ruchnoj zapisi nezametno razojtisj s vyibrannyim instrumentom.

## Chto izmeneno

Pravilo zakrepleno v povedenii repozitoriya, glossarii, dokumentacii vosproizvodimyikh avtomatizacij i proyektiruyemogo yazyika. Mashinnyij reyestr razlichayet novyiye kanonicheskiye imena, tochnyiye prezhniye isklyucheniya i otobrazhayemyiye imena avtomatizacij vne kataloga instrumentov. Kolliziya, neuchtyonnaya novaya avtomatizaciya, raskhozhdeniye transliteracii ili neyavnoye otsutstviye zavisimosti zakryivayut proverku.

Chetyire susjhestvuyusjhiye avtomatizacii Codex poluchili tochnyiye otobrazhayemyiye imena `Zapusk sleduyusjhego shaga aktivnoj vetki`, `YEzhednevnyij otchyot pamyati FUM`, `Avtokommit pamyati sessij Codex` i `Yezhenedeljnoye obnovleniye Homebrew`. Ikh raspisaniya, promptyi i sostoyaniya ne menyalisj. Susjhestvuyusjhiye repozitornyiye identifikatoryi ne pereimenovyivalisj massovo: oni vremenno perechislenyi tochnyim legacy-naborom, a otdeljnaya migraciya ostayotsya prodolzheniyem.

## Resheniye o LinguisticKit

Iskhodnyij repozitorij i stranica vyibrannoj revizii sokhranenyi v `Источники/`. Etalon zakreplyon na kommite `837e2ce107b97ee7b9d3344c9fe99142281fe393`: yego tablicyi i testyi sovpadayut s nablyudavshimsya sostoyaniyem `f26d46c99367bb1eef37c50906d2691ef36ca4d2`, a otlichiye ogranicheno perekhodom `swift-tools-version` s `5.9` na `6.0`; boleye novoye sostoyaniye ne proshlo sborku tekusjhim Swift 6.4 iz-za strogikh proverok konkurentnosti. Vyibrannaya reviziya proshla sborku i dala sokhranyonnyiye etalonnyiye preobrazovaniya.

Fakticheskaya Git-zavisimostj v repozitorij ne dobavlena. Dlya etogo paketa svyazannoye utochneniye potrebovalo postoyannyij fork `fum-lab/LinguisticKit`, no publichnyij repozitorij s takim adresom na moment proverki otsutstvoval; pryamoye podklyucheniye iskhodnogo repozitoriya ne ispoljzovano kak obkhod. Obsjheye pravilo vyibora i ustrojstva takikh istochnikov namerenno ne vklyucheno v etu atomarnuyu sessiyu: ono dolzhno poluchitj sobstvennyij iskhodnyij poljzovateljskij zapros. Zdesj khranitsya toljko chestnoye zablokirovannoye sostoyaniye materialization, poetomu lokaljnyij validator proveryayet skhemu, polnotu, etalonyi i kollizii, no pryamo soobsjhayet, chto zhivoj vyizov paketa yesjhyo ne vyipolnen.

## Proverki

- TDD avtomatizacii nazvanij: krasnaya faza zafiksirovala otsutstvuyusjhij scenarij; zelyonaya faza i povtornyij progon proshli `20/20` avtonomnyikh testov.
- TDD integracii smoke-check: novoye ozhidaniye snachala upalo iz-za otsutstvuyusjhego shaga, zatem `14/14` testov smoke-check proshli posle yego dobavleniya.
- Kornevoj reyestr strukturno proveril 18 avtomatizacij i vyidal ozhidayemoye preduprezhdeniye o tom, chto zhivaya proverka LinguisticKit ne vyipolnena v zablokirovannom sostoyanii.
- Swift-obyortka otdeljno sobrana s sovmestimyim snimkom revizii i podtverdila pyatj etalonov; yeyo `Package.swift` i iskhodniki prokhodyat strogij `swift format lint` tekusjhej konfiguraciyej.
- Planovyij reyestr peresobran i validen; zapisj sleduyusjhego shaga podtverzhdayet yedinstvennuyu paru `refs/heads/master` / `master-prepare-first-boxed-slice-passport-v2`.
- `.gitmodules` i `Зависимости/LinguisticKit` otsutstvuyut, poetomu iskhodnyij repozitorij ne stal skryitoj ili pryamoj zavisimostjyu. Staged-proverka diff prokhodit dlya vsekh fajlov, krome dvukh neobrabotannyikh `response.body.html`: ikh iskhodnyiye transportnyiye probelyi namerenno sokhranenyi po kontraktu arkhiva istochnikov.
- Posle obnovleniya recency i grafa Obsidian polnyij smoke-check proshyol `33/33` shaga, vklyuchaya proverku svyaznosti okonchateljnogo snimka rabochej sessii.

## Prodolzheniye

Posle otdeljnogo zakrepleniya dopustimogo istochnika zavisimosti nuzhno podklyuchitj paket na vyibrannoj revizii, perevesti validator iz zablokirovannogo v zhivoj rezhim i migrirovatj tochnyij spisok prezhnikh repozitornyikh i deklarativnyikh imyon bez izmeneniya ikh povedeniya. Podgotovka pasporta pervogo korobochnogo sreza ostayotsya raneye vyibrannyim sleduyusjhim shagom vetki i ne podmenyayetsya etoj migraciyej.

## Istochniki

- [iskhodnyij zapros 2026-07-21 12:18:37 MSK - Zakrepitj transliteraciyu nazvanij avtomatizacij](zapros.md)
- [arkhivirovannyij repozitorij Roman-Kerimov/LinguisticKit](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [arkhivirovannaya reviziya 837e2ce](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:99b1bac5e3cb1dde7b3e37c1cad136578a3de4755da0413dd437c308f9498b82 -->
<!-- FUM-MD-RECENCY:END -->
