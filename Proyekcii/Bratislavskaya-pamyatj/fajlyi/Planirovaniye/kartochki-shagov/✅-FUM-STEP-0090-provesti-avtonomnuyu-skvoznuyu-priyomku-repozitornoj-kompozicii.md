+++
schema_version = 1
card_id = "FUM-STEP-0090"
status = "completed"
+++
# Provesti avtonomnuyu skvoznuyu priyomku repozitornoj kompozicii

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sobratj avtonomnyij skvoznoj scenarij repozitornoj kompozicii FUM na lokaljnyikh bare-repozitoriyakh. Dva pishusjhikh poduzla dolzhnyi paralleljno poluchitj otdeljnyiye klonyi i vetki, sokhranitj osmyislennyiye rezuljtatyi kandidatnyimi commit, projti beskonfliktnuyu ili ogranichenno razreshayemuyu integraciyu, a neizvestnyij konflikt — ostatjsya dostizhimyim i zavershitjsya `resolution_required`. Dolgovechnyij fork-poduzel i otdeljnyij proyekt dolzhnyi perezhitj svezhij klon roditelya, prodolzhitj sobstvennyiye ocheredi i peredatj proverennyij rezuljtat vverkh.

## Rezuljtat

Avtonomnyij Swift-scenarij na vremennyikh lokaljnyikh bare-repozitoriyakh zamknul vse kriterii shaga. Dva pishusjhikh ispolnitelya paralleljno sozdayut otdeljnyiye kandidatnyiye commit bez izmeneniya iskhodnogo checkout; pokryitiye vyichislyayetsya iz pyati fakticheskikh sobyitij zapuskov i tryokh sobyitij integracii i otdeljno uchityivayet `commit`, `no-op`, blokirovku, publikacionnyij otkaz i konflikt bez iskusstvennyikh pustyikh commit. Beskonfliktnaya i ogranichenno razreshayemaya integracii sokhranyayut kandidatov pryamyimi roditelyami, a neizvestnyij konflikt sokhranyayet vkhodyi i kanonicheskuyu diagnostiku pri neizmennom celevom ref i vozvrasjhayet `resolution_required`.

Dolgovechnyij fork-poduzel i samostoyateljnyij proyekt prodolzhayut svoi vetki i upravlyayusjhiye konturyi, peredayut rezuljtatyi vverkh i obnovlyayut oba roditeljskikh gitlink odnim commit. Svezhij klon roditelya vosstanavlivayet tochnyiye detached-snimki oboikh submodule, a otdeljnyiye svezhiye zhivyiye klonyi — vetki i ocheredi iz kanonicheskogo sostoyaniya, sokhranyonnogo v dochernikh commit, bez perenosa sluzhebnyikh refs. Dva polnyikh progona dayut odinakovyiye kartyi shesti pasportov i diagnostik po yavnomu profilyu ekvivalentnosti i odinakovyiye kartyi derevjyev. Inyyekcii posle peredachi obyyektov i neposredstvenno pered kazhdyim iz vosjmi obnovlenij ref ne sdvigayut celi; podgotovlennyiye commit sokhranyayutsya dlya tochnogo povtora.

Odin CLI-probnik `composition acceptance` zapuskayet vesj scenarij bez seti, sekretov i modeljnyikh vyizovov i pechatayet kanonicheskij JSON-otchyot s devyatjyu tipizirovannyimi proverkami. Rezuljtat dokazyivayet lokaljnuyu repozitornuyu kompoziciyu, no ne gotovuyu vneshnyuyu infrastrukturu, setevuyu publikaciyu ili nezavisimostj modelej.

## Istochniki

- [iskhodnyij zapros 2026-08-05 00:37:53 MSK — Provesti avtonomnuyu skvoznuyu priyomku repozitornoj kompozicii](../../Zhurnal/2026-08-05_00-37-53_MSK_provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye o kommitiruyemyikh vkladakh pishusjhikh poduzlov FUM](../../Trebovaniya/✅-kommitiruyemyiye-vkladyi-pishusjhikh-poduzlov-FUM.md)
- [trebovaniye ob izolirovannom paralleljnom ispolnenii i proveryayemoj integracii](../../Trebovaniya/✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md)
- [trebovaniye ob ogranichennom avtomaticheskom razreshenii Git-konfliktov](../../Trebovaniya/✅-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md)
- [trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [FUM-STEP-0089 — proyektyi kak repozitorii-submodule](✅-FUM-STEP-0089-perevesti-proyektyi-na-repozitorii-submodule-s-sobstvennyimi-ocheredyami.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:890154630345b83f548eb3925ada4784fa72b561038a9e00fd4673f27fba04dc -->
<!-- FUM-MD-RECENCY:END -->
