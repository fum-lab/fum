# Otchyot 2026-07-17 10:07:09 MSK - Razlichatj fazyi modifikatorov i Caps Lock

V [trebovanii o maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](../../Trebovaniya/🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) pervichnyim klaviaturnyim kontraktom stali fizicheskaya identichnostj klavishi i razdeljnyiye fazyi `нажато` i `отпущено`. Eto odinakovo otnositsya k obyichnyim klavisham, uderzhivayemyim kvazirezhimnyim modifikatoram i rezhimnoj Caps Lock. Dlya parnyikh modifikatorov, v chastnosti Command, sokhranyayutsya levaya i pravaya fizicheskiye klavishi i ikh odnovremennyiye perekhodyi.

Flagi modifikatorov, logicheskoye sostoyaniye Caps Lock i simvolyi sistemnoj raskladki isklyuchenyi iz celevoj abstrakcii. Oni ne mogut zamenyatj fizicheskiye sobyitiya; istochnik, predostavlyayusjhij toljko flag ili pereklyucheniye rezhima, dolzhen yavno soobsjhatj poteryu. Yesli takiye polya prikhodyat ryadom s boleye syiryim potokom, oni dopustimyi lishj kak neobyazateljnaya diagnostika.

Command kak klavishi Leap v dukhe interfejsa Dzhefa Raskina i Caps Lock kak knopka avtodopolneniya zafiksirovanyi kak primeryi povedeniya, kotoroye mozhno postroitj poverkh universaljnogo fizicheskogo potoka. Sama kartochka ne naznachayet klavishi i ne realizuyet avtodopolneniye: ona garantiruyet sloj nablyudeniya, ne navyazyivayusjhij sistemnyiye rezhimyi.

## Resheniye po avtomatizacii

Susjhestvuyusjheye predlozheniye o sravniteljnom Swift-prototipe istochnikov vvoda rasshireno na vse dostupnyiye fizicheskiye klavishi-modifikatoryi i Caps Lock. Obyazateljnyij scenarij proveryayet `нажать -> удерживать -> отпустить`, levuyu i pravuyu Command po otdeljnosti i odnovremenno, a otchyot avtomaticheski otmechayet svorachivaniye perekhodov v obsjhij flag ili rezhim.

Otdeljnaya avtomatizaciya v etoj dokumentacionnoj sessii ne sozdavalasj: vosproizvodimaya proverka trebuyet realizacii cherez publichnyiye platformennyiye API i realjnyikh klaviatur. Sistemnyiye raskladki i porozhdayemyiye imi simvolyi isklyuchenyi iz celevoj matricyi prototipa.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [maksimaljno syiraya zapisj sobyitij ustrojstv vvoda](../../Trebovaniya/🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md)
- [indeks trebovanij](../../Trebovaniya/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Utochneniye vstroyeno v susjhestvuyusjhuyu kartochku bez dublirovaniya trebovaniya i bez izmeneniya dvunapravlennoj semanticheskoj svyazi.
- Celevoj kontrakt i scenarij prototipa proverenyi na otsutstviye zavisimosti ot flagov modifikatorov, rezhima Caps Lock i sistemnyikh raskladok.
- Planovyij reyestr, recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian peresobranyi.
- `git diff --check`, `fum-session-coherence` i polnyij `fum-smoke-check` zavershilisj uspeshno.

## Istochniki

- [iskhodnyij zapros 2026-07-17 10:07:09 MSK](zapros.md)
- [iskhodnyij zapros 2026-07-17 09:41:27 MSK](../2026-07-17_09-41-27_MSK_utochnitj-razlicheniye-nazhatiya-i-otpuskaniya-Caps-Lock/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:645ff401168099388f054916ffd8edb39cf5eb7576af570c3fdbc58fe7e2d314 -->
<!-- FUM-MD-RECENCY:END -->
