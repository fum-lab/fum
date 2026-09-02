+++
schema_version = 1
card_id = "FUM-STEP-0087"
status = "completed"
+++
# Dobavitj ogranichennoye avtomaticheskoye razresheniye Git-konfliktov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj CAS-integrator versionirovannyim reyestrom ogranichennyikh resolver-pravil. Pervaya versiya dolzhna umetj peresobiratj obyyavlennyiye proizvodnyiye fajlyi iz kanonicheskikh istochnikov i obyyedinyatj zapisi s ustojchivyimi identifikatorami toljko pri soglasovannoj skheme i neprotivorechivyikh normativnyikh polyakh. Lyuboj drugoj konflikt dolzhen sokhranyatj iskhodnyiye commit i zavershatjsya sostoyaniyem `resolution_required` s diagnosticheskim artefaktom.

## Rezuljtat

`CandidateCommitIntegrator` rasshiren reyestrom `fum.candidate-conflict-resolver-registry` versii `1`. Kazhdoye pravilo zakreplyayet ustojchivyiye identifikator i versiyu, tochnyij putj, predusloviya, determinirovannyij algoritm, invariantyi rezuljtata i obyazateljnyiye proverki. Pervaya versiya soderzhit rovno dva klassa: polnuyu peresborku obyyavlennogo proizvodnogo manifest iz proverennyikh kanonicheskikh regular-file-istochnikov i base-aware-obyyedineniye kanonicheskikh JSON-zapisej po ustojchivomu ID pri unikaljnyikh klyuchakh, tochnoj skheme, neprotivorechivyikh normativnyikh polyakh i otsutstvii smyislovogo dublirovaniya.

Neizvestnyij libo neodnoznachnyij putj, narusheniye predusloviya, normalizovannaya kolliziya lyubogo komponenta puti, raskhozhdeniye skhemyi, povtor ID, protivorechivoye normativnoye pole, smyislovaya nesovmestimostj i proval obyazateljnoj proverki dayut `resolution_required`. Kanonicheskaya diagnostika sokhranyayet vkhodnyiye commit, tree i blob OID, prichinyi i rezuljtatyi proverok; celevoj ref ne menyayetsya, a pryamyiye refs klona popyitki uderzhivayut iskhodnyiye variantyi. Modeljnoye predlozheniye ostayotsya obyichnyim kandidatnyim commit i ne poluchayet povyishennogo statusa.

Uspeshnoye razresheniye sozdayot otdeljnyij integracionnyij commit s ozhidayemoj vershinoj i vsemi iskhodnyimi kandidatami kak pryamyimi roditelyami. Pasport versii `2` sokhranyayet binding primenyonnogo pravila, khyesh yego specifikacii, vkhodnyiye i vyikhodnoj khyeshi, invariantyi i dva progona obyazateljnyikh proverok. Vosstanovleniye v otdeljnom klone polnostjyu povtoryayet merge i resolver iz zakreplyonnyikh commit i sveryayet vesj itogovyij tree, resolver-zapisi i tochnyij commit object.

Tridcatj avtonomnyikh Git-scenariyev pokryivayut oba razreshyonnyikh klassa, neizvestnoye i konkuriruyusjhiye pravila, protivorechivoye pole, smyislovuyu nesovmestimostj bez tekstovogo konflikta, sboj posle razresheniya, podmenu podgotovlennogo dereva, commit payload, proiskhozhdeniya i diagnostiki, nebezopasnyij tip istochnika i normalizovannyiye kollizii komponentov puti. README i arkhitekturnaya dokumentaciya yavno ogranichivayut resolver zaregistrirovannyimi klassami i ne obesjhayut avtomaticheskogo razresheniya lyubogo konflikta.

## Istochniki

- [iskhodnyij zapros 2026-08-04 02:55:45 MSK — Dobavitj ogranichennoye avtomaticheskoye razresheniye Git-konfliktov](../../Zhurnal/2026-08-04_02-55-45_MSK_dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye ob ogranichennom avtomaticheskom razreshenii Git-konfliktov](../../Trebovaniya/✅-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md)
- [FUM-STEP-0086 — CAS-integraciya beskonfliktnyikh kommitov](✅-FUM-STEP-0086-dobavitj-CAS-integraciyu-beskonfliktnyikh-kommitov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 05:12:39 MSK -->
<!-- content-sha256: sha256:b0e81b30ffd2f44ee47b1696db675c3b57c02413b716fd0025ee93cbdbcc23e7 -->
<!-- FUM-MD-RECENCY:END -->
