# Iskhodniki FUMA

Katalog sobirayet sobstvennuyu realizaciyu FUMA obyichnyimi fajlami yedinogo FUM: chetyire samostoyateljnyikh SwiftPM-paketa i prilozheniye dlya macOS. Kontejner nablyudenij uzhe podklyuchyon k CLI-scenariyu operatorov prilozheniya; ostaljnyiye paketyi trebuyut otdeljnoj integracii.

- [Kontejner nablyudenij](Packages/KontejnerNablyudenij/README.md) khranit odin ogranichennyij segment binarnyikh nablyudenij.
- [Snimok agentskoj zadachi](Packages/SnimokAgentskojZadachi/README.md) vosproizvodit sinteticheskiye scenarii i vosstanavlivayet snimok.
- [Arkhivnyij snimok zadachi](Packages/ArkhivnyijSnimokZadachi/README.md) importiruyet yavno peredannyij zavershyonnyij prefiks zhurnala.
- [Statistika vyizovov](Packages/StatistikaVyizovov/README.md) uchityivayet vyizovyi po otkryitomu kontraktu sobyitij.
- [Prilozheniye dlya macOS](macOS/README.md) sokhranyayet ekrannoye prilozheniye, MCP-shlyuz i dva pomosjhnika nablyudeniya; rukovodstvo opisyivayet sistemnyiye zavisimosti, sborku i otdeljnyiye granicyi ustanovki.

Paketyi obyyavlyayut Swift tools 6.0, Swift 6 i macOS 14. Eto granica nyineshnej realizacii, a ne zayavleniye o podderzhke vsekh celevyikh OS. Rukovodstva paketov poka sokhranyayut iskhodnyij tekst; ikh komandyi s `Packages/` vyipolnyayutsya iz etogo kataloga. [Proverka paketov iz chistogo klona](proverka-paketov.md) podtverzhdena na nablyudyonnoj platforme: 133 testa, chetyire Release-sborki i pyatj sinteticheskikh profilej. Rukovodstvo soderzhit samostoyateljnyiye komandyi i ogranicheniya. [Proverka prilozheniya iz chistogo klona](proverka-prilozheniya.md) podtverzhdayet SwiftPM, Xcode i sinteticheskiye profili s otdeljnyimi ogranicheniyami sredyi.

## Razvitiye obsjhej kodovoj bazyi

[Podgotovka Android-runtime](plan-Android-runtime.md) prinyata v rabotu: obsjheye Swift-yadro, platformennyiye adapteryi i sobstvennyij interfejs cherez Metal/Vulkan. Zapusk na Android yesjhyo trebuyetsya podtverditj.

Celevaya struktura po poslednemu utochneniyu — yedinyij Swift-paket FUMA v etom kataloge, obsjhiye Sources/Tests i platformennyiye razlichiya cherez #if vnutri komponentov. Perenos prezhnego macOS-paketa i otdeljnyikh sobstvennyikh paketov yesjhyo predstoit; tekusjheye raspolozheniye vyishe ostayotsya opisaniyem fakta.

[Tekstovaya sreda po modeli Canon Cat](../../Dokumentaciya/interfejs-FUMA/tekstovaya-sreda-Canon-Cat.md) zaplanirovana na strukturiruyusjhikh operatorakh: LEAP, sostavnoj kursor i shriftovoj trakt k Metal/Vulkan. Istochnik i granicyi pervogo sreza privedenyi v plane.

[Medijnyij trakt](medijnyij-trakt.md) svyazyivayet lokaljnuyu ozvuchku, generiruyemoye video, Torrent-arkhiv i publikacii YouTube/Twitch/Telegram/MAX; eto plan s yavnoj granicej pervogo proveryayemogo sreza.

[GitHub-adapter](plan-GitHub-adaptera.md) zaplanirovan dlya nablyudeniya i vedeniya repozitoriyev, zadach, PR, proverok i relizov FUM.

## Sokhraneniye proiskhozhdeniya

[Podgotovka iOS-runtime](plan-iOS-runtime.md) takzhe aktivirovana: prilozheniye v Simulator, zapisj i replay obsjhego scenariya, sobstvennyij graficheskij putj Metal. Perenosimostj paketov i zapusk trebuyut proverki.

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
<!-- last-content-edit: 2026-09-15 22:23:43 MSK -->
<!-- content-sha256: sha256:66cebb0e666ce1a42ed41e0afdd28911a444a88857885187af3c8d9df0b09a19 -->
<!-- FUM-MD-RECENCY:END -->
