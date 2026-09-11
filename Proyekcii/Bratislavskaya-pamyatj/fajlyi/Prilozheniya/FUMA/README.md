# Iskhodniki FUMA

Katalog sobirayet sobstvennuyu realizaciyu FUMA obyichnyimi fajlami yedinogo FUM: chetyire samostoyateljnyikh SwiftPM-paketa i prilozheniye dlya macOS. Paketyi yesjhyo ne podklyuchenyi k prilozheniyu; takoj svyazi ne byilo i v iskhodnoj realizacii.

- [Kontejner nablyudenij](Packages/KontejnerNablyudenij/README.md) khranit odin ogranichennyij segment binarnyikh nablyudenij.
- [Snimok agentskoj zadachi](Packages/SnimokAgentskojZadachi/README.md) vosproizvodit sinteticheskiye scenarii i vosstanavlivayet snimok.
- [Arkhivnyij snimok zadachi](Packages/ArkhivnyijSnimokZadachi/README.md) importiruyet yavno peredannyij zavershyonnyij prefiks zhurnala.
- [Statistika vyizovov](Packages/StatistikaVyizovov/README.md) uchityivayet vyizovyi po otkryitomu kontraktu sobyitij.
- [Prilozheniye dlya macOS](macOS/README.md) sokhranyayet ekrannoye prilozheniye, MCP-shlyuz i dva pomosjhnika nablyudeniya; rukovodstvo opisyivayet sistemnyiye zavisimosti, sborku i otdeljnyiye granicyi ustanovki.

Paketyi obyyavlyayut Swift tools 6.0, Swift 6 i macOS 14. Eto granica nyineshnej realizacii, a ne zayavleniye o podderzhke vsekh celevyikh OS. Rukovodstva paketov poka sokhranyayut iskhodnyij tekst; ikh komandyi s `Packages/` vyipolnyayutsya iz etogo kataloga. [Proverka paketov iz chistogo klona](proverka-paketov.md) podtverzhdena na nablyudyonnoj platforme: 133 testa, chetyire Release-sborki i pyatj sinteticheskikh profilej. Rukovodstvo soderzhit samostoyateljnyiye komandyi i ogranicheniya. [Proverka prilozheniya iz chistogo klona](proverka-prilozheniya.md) podtverzhdayet SwiftPM, Xcode i sinteticheskiye profili s otdeljnyimi ogranicheniyami sredyi.

## Sokhraneniye proiskhozhdeniya

[Manifest perenosa](../../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/materialyi/manifest-perenosa-paketov.json) svyazyivayet kazhdyij iskhodnyij putj s polnyimi commit, blob OID, SHA-256, razmerom, rezhimom i mestom v FUM. Iskhodniki i fiksturyi izvlechenyi bez izmeneniya bajtov. V README shtatno dobavlyayutsya toljko sluzhebnyiye metki svezhesti; ikh polnyij kanonicheskij khyesh uchityivayetsya otdeljno.

[Manifest prilozheniya](macOS/manifest-perenosa.json) otdeljno svyazyivayet 39 iskhodnyikh fajlov s kanonicheskimi bajtami posle adaptacii i perechislyayet dobavlennyiye fajlyi. Prezhniye lokaljnyiye puti zamenenyi obsjhej konfiguraciyej dannyikh i yavnyimi sborochnyimi parametrami. Originaljnyiye Git-obyyektyi sokhranenyi; syiryiye chastnyiye puti ne vklyuchayutsya v publichnuyu istoriyu radi promezhutochnogo perenosa. Obsjhaya granica iskhodnogo nabora — 110 fajlov, iz nikh 71 fajl paketov i 39 fajlov prilozheniya.

Realizaciya priznana sobstvennoj pryamyim porucheniyem poljzovatelya i vklyuchayetsya pod obsjhuyu [CC0 FUM](../../LICENSE). V iskhodnom nabore net otdeljnogo LICENSE; eto ne ustanavlivayet licenziyu storonnikh bibliotek. LinguisticKit ostayotsya vneshnej zavisimostjyu s prezhnim gitlink. Ni runtime, ni lokaljnyiye kyeshi, ni chastnyiye zhurnalyi v perenos ne vkhodyat.

## Povtoreniye perenosa

Vspomogateljnyij [scenarij izvlecheniya](scenarii/perenesti-iskhodniki.py) trebuyet susjhestvuyusjhij korenj naznacheniya i yavnyij putj k iskhodnomu Git-repozitoriyu. On ne sozdayot klon, ne menyayet iskhodnyiye refs i ne chitayet rabochiye ili neotslezhivayemyiye fajlyi. Kazhdyij `--выбор` imeyet vid `полный-commit:путь`, tochka oznachayet vsyo derevo. Bez `--применить` vyivoditsya toljko JSON-plan; s flagom snachala proveryayutsya vse naznacheniya i iskhodnyiye obyyektyi, zatem sozdayutsya fajlyi. Uzhe susjhestvuyusjhaya celj, konflikt iskhodnyikh versij, ssyilka ili nesovpadeniye khyesha dayut otkaz. Diagnosticheskij stderr soderzhit izmereniya postroyeniya plana i primeneniya v nanosekundakh; stdout — manifest.

Dlya povtornogo izvlecheniya nuzhen pustoj celevoj katalog. Posle importa syiroj manifest sokhranyayetsya; obyazateljnaya obrabotka kanonicheskikh Markdown vyipolnyayetsya otdeljno shtatnoj avtomatizaciyej svezhesti. Scenarij ogranichen obyichnyimi fajlami Git SHA-1, soglasovannyim yedinstvennyim pisatelem i iskhodnyim repozitoriyem bez konkurentnoj podmenyi. Pri oshibke zapisi sozdannyiye im fajlyi udalyayutsya; pustyiye katalogi mogut ostatjsya. Eto vspomogateljnyij mekhanizm perenosa dannoj realizacii, ne avtomaticheskoye vklyucheniye neizvestnogo storonnego repozitoriya.

## Istochniki

- [Zapros i otchyot perenosa](../../Zhurnal/2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/zapros.md).
- [FUM-STEP-0176](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0176-sobratj-sobstvennuyu-realizaciyu-v-FUM.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:4acce5aa2aa63a5c8a0f88fb06d1cf1d96f82c5b439e0eb9c85a8c8c36d23600 -->
<!-- FUM-MD-RECENCY:END -->
