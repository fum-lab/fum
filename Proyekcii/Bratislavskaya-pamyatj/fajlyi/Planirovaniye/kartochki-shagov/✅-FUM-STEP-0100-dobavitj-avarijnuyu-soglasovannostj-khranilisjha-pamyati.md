+++
schema_version = 1
card_id = "FUM-STEP-0100"
status = "completed"
+++
# Dobavitj avarijnuyu soglasovannostj khranilisjha pamyati

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zakrepitj i realizovatj tochnyij protokol avarijnoj soglasovannosti fajlovogo khranilisjha: poryadok zapisi pokoleniya i ukazatelya, sinkhronizaciyu fajlov i katalogov, bezopasnyiye khvostyi i vosstanovleniye. Otdeljno dokazatj povedeniye pri avarijnom zavershenii processa i chestno ogranichitj zayavleniye o potere pitaniya nablyudayemyimi svojstvami fajlovoj sistemyi i stenda.

## Rezuljtat

`MemoryGenerationStore` zamenil `Data.write(.atomic)` tochnyim fajlovyim protokolom. Kanonicheskoye pokoleniye polnostjyu zapisyivayetsya vo vremennyij fajl, sinkhroniziruyetsya cherez `fsync`, bez zamesjheniya publikuyetsya pod adresnyim imenem i zakreplyayetsya sinkhronizaciyej kataloga `generations/`. Toljko posle etogo pod postoyannoj mezhprocessnoj blokirovkoj zanovo proveryayetsya roditelj, vremennyij `CURRENT` polnostjyu zapisyivayetsya i sinkhroniziruyetsya, atomarno zamenyayet ukazatelj, a shtatnyij uspekh vozvrasjhayetsya posle `fsync` kornevogo kataloga.

Vosemj testovyikh kontroljnyikh tochek pokryivayut zapisj, sinkhronizaciyu i publikaciyu oboikh fajlov kak dlya pervoj fiksacii iz pustogo khranilisjha, tak i dlya zamenyi susjhestvuyusjhego `CURRENT`. Na kazhdoj otdeljnyij writer-process ostanavlivayetsya i zavershayetsya cherez `SIGKILL`, posle chego novyij recovery-process vidit strogo prezhneye libo polnostjyu proveryayemoye novoye pokoleniye. Vosstanovleniye doveryayet toljko tochnomu `CURRENT`, ne skaniruyet katalog pokolenij i ne povyishayet adresuyemyij obyyekt ili staging-khvost; budusjhaya sborka sirot otdelena ot recovery i potrebuyet sobstvennoj koordinacii.

Dokumentaciya razlichayet logicheskuyu atomarnostj, podtverzhdyonnuyu na tekusjhem lokaljnom macOS-stende process-crash consistency i poka ne dokazannuyu power-loss durability. `fsync` zadayot poryadok zaprosov k OS, no processnyij `SIGKILL` ne zamenyayet ispyitaniye fajlovoj sistemyi, kontrollera, kyeshej i nositelya realjnyim otklyucheniyem pitaniya.

## Istochniki

- [iskhodnyij zapros o vyipolnenii FUM-STEP-0100](../../Zhurnal/2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [FUM-STEP-0099 — mezhprocessnyij CAS](✅-FUM-STEP-0099-dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:de01d181958332529b694bc8fbb2a89761a95864ea35bea68cc3d5e299ee3d1e -->
<!-- FUM-MD-RECENCY:END -->
