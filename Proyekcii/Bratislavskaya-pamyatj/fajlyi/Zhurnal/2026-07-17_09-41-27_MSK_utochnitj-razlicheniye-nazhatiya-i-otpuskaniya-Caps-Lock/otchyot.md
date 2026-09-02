# Otchyot 2026-07-17 09:41:27 MSK - Utochnitj razlicheniye nazhatiya i otpuskaniya Caps Lock

V [trebovanii o maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](../../Trebovaniya/🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) fizicheskaya faza klavishi otdelena ot sostoyaniya modifikatorov i logicheskogo sostoyaniya rezhimov fiksacii. Dlya Caps Lock celevaya trassa dolzhna po vozmozhnosti razlichatj nazhatiye i otpuskaniye klavishi, a vklyucheniye ili vyiklyucheniye rezhima sokhranyatj samostoyateljno i ne vyidavatj za fizicheskuyu fazu.

Yesli publichnyij API predostavlyayet toljko pereklyucheniye rezhima, adapter obyazan yavno zafiksirovatj poteryu fizicheskoj fazyi i ne pridumyivatj sobyitiye otpuskaniya. Fakticheski dostupnyij i publikacionno dopustimyij istochnik ili sochetaniye istochnikov, sokhranyayusjheye obe fazyi, poluchayet preimusjhestvo pri vyibore vmeste s ocenkoj razreshenij, ogranichenij sandbox, zaderzhki, ustojchivosti i stoimosti. Tak ogranicheniye konkretnogo API ostayotsya nablyudayemyim i ne iskazhayet iskhodnyij potok.

## Resheniye po avtomatizacii

Susjhestvuyusjheye predlozheniye o sravniteljnom Swift-prototipe istochnikov vvoda dopolneno obyazateljnyim scenariyem Caps Lock. Prototip dolzhen nachinatj ciklyi iz oboikh logicheskikh sostoyanij rezhima, otdeljno sopostavlyatj perekhodyi «nazhato» i «otpusjheno» s sostoyaniyem rezhima i avtomaticheski pomechatj istochnik, kotoryij ikh svorachivayet. Otdeljnaya avtomatizaciya v etoj dokumentacionnoj sessii ne sozdavalasj: vosproizvodimaya proverka trebuyet realizacii cherez platformennyiye API i realjnyikh klaviatur.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [maksimaljno syiraya zapisj sobyitij ustrojstv vvoda](../../Trebovaniya/🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md)
- [indeks trebovanij](../../Trebovaniya/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Utochneniye vstroyeno v susjhestvuyusjhuyu kartochku bez dublirovaniya trebovaniya i bez izmeneniya dvunapravlennoj semanticheskoj svyazi.
- Planovyij reyestr, recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian peresobranyi.
- `git diff --check`, `fum-session-coherence` i polnyij `fum-smoke-check` zavershilisj uspeshno.

## Istochniki

- [iskhodnyij zapros 2026-07-17 09:41:27 MSK](zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d5873cd788ff51d858be17a8965bdf14dfcc6cf6da42fef67030796bd2d1188e -->
<!-- FUM-MD-RECENCY:END -->
