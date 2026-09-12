+++
schema_version = 1
card_id = "FUM-STEP-0216"
status = "active"
+++
# Splanirovatj profilj i pilot macOS VM dlya FUMA

## Zadacha

Podgotovitj tekhnicheskij plan odnogo profilya macOS VM na Apple Silicon i konechnogo pilota FUMA: sovmestimyij obraz → ustanovka → pervyij zapusk → gotovnostj SSH → tochnyij gostevoj klon → vyibrannyij scenarij → ostanovka i povtor.

## Pochemu sejchas

Potrebnostj v macOS VM prinyata otdeljnoj komandoj. Linux-instrument dayot sosednij opyit zhiznennogo cikla, no ustanovku macOS, identichnostj gostya i provisioning neobkhodimo splanirovatj otdeljno. Napravleniye sokhranyayetsya bez vyideleniya yesjhyo odnogo aktivnogo ispolnitelya ili zapuska mashinyi v tekusjhej granice.

## Kriterii zaversheniya

- Sostavlena matrica obsjhego i otdeljnogo povedeniya Linux/macOS; povtornoye ispoljzovaniye opirayetsya na konkretnyij prinyatyij commit, a nedostavlennyiye chasti ukazanyi kak zavisimosti.
- Podgotovlen pasport odnogo pilota s usloviyami host/SDK/Swift/obraza/resursov. Neizvestnyiye polya yavno perechislenyi vmeste so sposobom ikh polucheniya; gipoteza macOS 27+ Beta iz peredannogo issledovaniya ne obyyavlyayetsya proverennoj gotovnostjyu.
- Opisan otdeljnyij kontrakt vosstanovleniya prervannoj ustanovki cherez VZMacOSInstaller. Obyichnyiye pause/stop vo vremya ustanovki ne obyyavlenyi podderzhannyim sposobom otmenyi.
- Plan pervogo zapuska razlichayet provisioning i povtor: poljzovatelj ne pereinicializiruyetsya, apparatnaya modelj, identifikator, vspomogateljnoye khranilisjhe i disk sokhranyayutsya.
- Vyibran i nazvan odin scenarij FUMA iz chistogo klona tochnogo OID i susjhestvuyusjhaya podgotovka macOS/FUM-STEP-0179; sborka, zapusk i poleznyij rezuljtat imeyut otdeljnyiye kriterii.
- Zadanyi sinteticheskiye proverki zhiznennogo cikla i otdeljnyij nastoyasjhij progon sovmestimogo gostya s SSH, shtatnoj ostanovkoj i povtorom; vkhodyi i profilj vosproizvodimyi.
- Itogovyij plan perechislyayet ogranicheniya i zavisimosti dlya realizacii. V etom shage ne sozdayutsya VM, uchyotnyiye dannyiye i novaya aktivnaya zadacha; daljnejshaya realizaciya i nastoyasjheye ispyitaniye poluchayut otdeljnuyu yavnuyu granicu.

## Istochniki

- [Pervyij pasport pilota i programma proverki](../macOS-VM-pasport-pilota.md): tochnyij nablyudyonnyij khost, vyibrannaya Beta, vkhodyi IPSW, vosstanovleniye installer, SSH i odin arkhivnyij scenarij FUMA. Eto planovyij srez; prinyatyij obsjhij Linux lifecycle, gostevoj profilj 0179, obraz i nastoyasjhij progon ostayutsya zavisimostyami. Aktivnyij status vsej kartochki sokhranyon.
- [Porucheniye pervogo sreza](../../Zhurnal/2026-09-12_03-28-44_MSK_podgotovitj-pasport-macOS-VM/zapros.md).
- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:43:42 MSK -->
<!-- content-sha256: sha256:d3acaf44b033f4866126e4ab13cd8626101da8096ff8cec3fc2ba4fa64f65707 -->
<!-- FUM-MD-RECENCY:END -->
