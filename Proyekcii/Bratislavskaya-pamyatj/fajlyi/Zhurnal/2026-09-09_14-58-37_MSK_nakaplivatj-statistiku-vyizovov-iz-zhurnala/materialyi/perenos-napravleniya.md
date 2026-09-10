# Izolirovatj aktivnoye napravleniye statistiki

Sobstvennaya nezakommichennaya deljta perenesena posle zaversheniya oboikh proverochnyikh processov: v4 №1 — 12 RED/36 utverzhdenij pri uspeshnoj kompilyacii, №2 — 12 GREEN, XCTest 0,022 s. Obe syiryiye zapisi sokhranenyi bez izmeneniya.

Iz tochnoj prinyatoj bazyi FUM `583704422445f32cf732f2625e6b5818880fd274` sozdan sobstvennyij ref `refs/heads/codex/статистика-вызовов-01a07d3d`; iz Swift `dd172958b0128cba73361eeac136e8bc66190230` — `refs/heads/codex/call-statistics-01a07d3d`. Dlya kazhdogo vyideleno otdeljnoye worktree s kratkim imenem `статистика-вызовов-01a07d3d` v raneye naznachennyikh roditeljskikh katalogakh.

Do perenosa vne checkout sokhranenyi dva arkhiva i [tochnyij manifest 8+8 fajlov](manifest-perenosa.json). Posle izvlecheniya kazhdyij SHA-256 i rezhim dostupa sovpal s istochnikom. Arkhiv FUM: `869a60be550bada887ea3f0338e2916cc3b726901ae9b3d109cb304cde972baa`; arkhiv Swift: `43655e4cf1947fa4ae3c10ae0e3994c990d7907075e31f7fe9478a04c07c0cad`; iskhodnyij manifest: `ee09c7550a699ce3d4c29da062503e4a81318197080180e0c78ba402a9ee51fd`.

Toljko posle sovpadeniya v prezhnem FUM-dereve vosstanovlenyi dva sobstvennyikh sluzhebnyikh izmeneniya start: indeks Zhurnala i sosednyaya navigaciya. Novyij nezakommichennyij Zhurnal i novyij Swift-paket vmeste s yego sborochnyim katalogom peremesjhenyi v rezervnyij katalog vne checkout, a ne udalenyi. Oba prezhnikh dereva chistyi na iskhodnyikh OID; chuzhiye fajlyi i refs ne menyalisj. Prinyatyiye kontejner i snimok neizmennyi. Arkhivyi i rezervnyiye katalogi pozvolyayut vosstanovitj iskhodnoye sostoyaniye perenosa.

Eto smena izolyacii uzhe vyipolnyayemogo napravleniya, ne prekrasjheniye soderzhateljnoj rabotyi. Daljnejshiye komandyi ispoljzuyut toljko novyiye korni. Manifest opisyivayet bajtyi v moment perenosa, a ne budusjhiye pravki realizacii i otchyota.

Osnovaniye: [komanda ob otdeljnoj vetke](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:21:46 MSK -->
<!-- content-sha256: sha256:a76eae16d81992fa38f1be0ad177fb74475c95884efa88235b08ce246ac12949 -->
<!-- FUM-MD-RECENCY:END -->
