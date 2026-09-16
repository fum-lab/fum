# Granica predposyilki avtomaticheskogo udaleniya proyekcii

Eto plan neobkhodimogo ispravleniya prinimayusjhego M, a ne razresheniye izmenyatj M iz kandidata. Tochnyij iskhodnyij otkaz sokhranyon v [svideteljstve](otkaz-vosstanovleniya-proyekcii.json). Drugogo shtatnogo marshruta dejstvuyusjhij M ne predostavlyayet; vosstanovleniye kvitancii otnositsya k prervannoj tranzakcii, a obyichnyiye plan i proverka manifesta ne prinimayut konfliktnoye pokoleniye.

## Minimaljnyij kontrakt

Otsutstvuyusjhij v indekse putj mozhno isklyuchitj iz obyyedineniya roditeljskikh manifestov toljko pri dokazannom obyichnom udalenii: yedinstvennaya obsjhaya osnova i odna vershina soderzhat sovershenno odinakovyiye rezhim i blob; drugaya vershina i yeyo polnyij manifest udalili putj. Manifestyi osnovyi i sokhranivshej vershinyi dolzhnyi sootvetstvovatj rezhimu i SHA-256 fakticheskikh bajtov blob. Tot zhe putj otsutstvuyet v AUTO_MERGE, kazhdoj stadii indeksa i fizicheskom snimke.

Napravleniye udaleniya simmetrichno. Manifest samogo pokoleniya ne isklyuchayetsya. Razresheniye ne rasprostranyayetsya na izmeneniye protiv udaleniya, na otsutstviye toljko v AUTO_MERGE, na ruchnoye snyatiye puti iz indeksa, na neizvestnyij fajl ili na povrezhdyonnoye proiskhozhdeniye. Vse prezhniye proverki fizicheskikh bajtov, stadij i neizmennosti granicyi ostayutsya obyazateljnyimi.

Dlya tekusjhego STEP0175 osnova i M soderzhat blob 649c77fcb58fc2f2ce32bb80ac79720e31cc23e3, rezhim 100644, SHA-256 27e7b54481a1fcccbdfd73dfc381bada92fe08267ef78a1c10d75671bd2a54d0. V oboikh sootvetstvuyusjhikh manifestakh zakreplenyi te zhe rezhim i khyesh. L i yeyo manifest putj ne soderzhat.

## Proverka izmeneniya

Nuzhen realjnyij Git-merge v otkryitoj minimaljnoj fiksture s konfliktuyusjhim manifestom i obyichnyim udaleniyem odnogo fajla. Polozhiteljnyij scenarij proveryayetsya dlya obeikh storon. Otricateljnyiye scenarii: izmeneniye protiv udaleniya, vruchnuyu snyatyij neizmenyonnyij fajl, podmena AUTO_MERGE, nesovpadayusjhij blob ili rezhim, nevernyij manifest, smena granicyi posle predproverki i neizvestnyiye fizicheskiye bajtyi.

Snachala sokhranyayetsya RED tekusjhego M, zatem realizuyetsya ogranichennyij dopusk, GREEN, profilj odinakovogo scenariya i obosnovannoye resheniye ob optimizacii. Ispravleniye snachala prinimayetsya v master; toljko posle etogo fiksiruyetsya novyij M i gotovitsya zanovo proveryayemyij C s tem zhe L. Tekusjhij kandidat i pervichnyij otkaz sokhranyayutsya kak narabotka.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 15:53:10 MSK -->
<!-- content-sha256: sha256:e99811490c6850fc840b60506c835029154166a732832d398e7a5c6e0b81ff91 -->
<!-- FUM-MD-RECENCY:END -->
