# Profilj i resheniye ob optimizacii

Shestj posledovateljnyikh release-progonov: tri do i tri posle lokaljnogo izmeneniya diagnostiki. Kazhdyij pishet 64 × 524288 bajt (32 MiB) v novyij fizicheskij katalog mktemp, zatem otdeljnyij process otkryivayet i povtorno proveryayet chistyij segment. Vkhod byte[i] = (i × 131) mod 256 i metadannyiye odinakovyi. Paralleljnyiye proverki vo vremya izmerenij ne zapuskalisj. Druguyu aktivnostj mashinyi i kholodnostj diskovogo kyesha ne kontrolirovali.

Sreda: macOS 27.0 (26A5425a), arm64, Apple Swift 6.4 (swiftlang-6.4.0.30.4), swift-driver 1.168.6. Native SwiftPM, --jobs 2, -c release. Sborka vyinesena iz vremeni progona. [Snimok do](iskhodniki-profilya.json) i [snimok posle](iskhodniki-posle-profilya.json) svyazyivayut vneshniye iskhodniki s izmereniyami otdeljno ot otpechatka FUM v v4. Vse production Swift-fajlyi finaljnogo rezuljtata sovpadayut so snimkom posle; pozdneye test dopolnen nezavisimyim oracle polnogo khyesha.

## Rezuljtatyi

| Seriya / № | Zapisj, MiB/s | Ack p50, ms | Ack p95, ms | RSS writer, MiB | RSS recovery, MiB | Recovery, ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| iskhodnaya / 1 | 372.25 | 1.214 | 2.122 | 8.45 | 71.67 | 100.498 |
| iskhodnaya / 2 | 434.14 | 1.038 | 2.002 | 8.45 | 71.67 | 99.755 |
| iskhodnaya / 3 | 480.40 | 0.999 | 1.177 | 8.48 | 71.67 | 99.808 |
| posle-optimizacii / 1 | 405.65 | 1.146 | 1.400 | 8.47 | 9.27 | 100.152 |
| posle-optimizacii / 2 | 366.30 | 1.215 | 1.579 | 8.50 | 9.27 | 100.954 |
| posle-optimizacii / 3 | 409.91 | 1.113 | 1.513 | 8.47 | 9.28 | 100.238 |

p50/p95 — nearest-rank po 64 otdeljnyim podtverzhdeniyam kazhdogo progona. RSS — getrusage(RUSAGE_SELF).ru_maxrss v bajtakh Darwin, ne prirost i ne pokazatelj vsej mashinyi. Syiryiye zaderzhki i vlozhennyiye stadii sokhranenyi v [izmereniyakh do](profilj-do.json) i [posle](profilj-posle.json).

## Resheniye

Pervyiye tri progona pokazali RSS diagnosticheskogo recovery 75153408 bajt (71,67 MiB) protiv okolo 8,5 MiB writer. Dva prokhoda FileHandle.read pri vyichislenii SHA-256 uderzhivali vremennyiye buferyi do konca oblasti autorelease. Otdeljnaya regressiya do ispravleniya prevyisila vyibrannyij lokaljnyij byudzhet 64 MiB: 75366400 bajt. Eto inzhenernyij byudzhet dannoj sinteticheskoj fiksturyi, ne universaljnaya garantiya API ili poljzovateljskij SLA.

Dobavlen autoreleasepool vokrug chteniya i SHA256.update kazhdogo bloka v diagnosticheskom CLI. Ni format, ni bibliotechnyij fajlovyij protokol, ni poryadok sync ne menyalisj. Posle — 9,27–9,28 MiB: okolo 87% snizheniya pikovogo RSS diagnosticheskogo processa. Vse khyeshi segmenta do/posle v obeikh seriyakh ravnyi 3c504f55979ea006796597846cf070458efc38e9b0dd25d4364dbd2c7d0d104a. Test dopolniteljno sveryayet rezuljtat s nezavisimyim SHA-256 celogo fajla v roditeljskom testovom processe.

Uskoreniye zapisi ili vosstanovleniya ne zayavlyayetsya: zapisj ispoljzuyet prezhnij algoritm, razbros vremeni i progrev susjhestvennyi. V iskhodnoj serii zapisj gruppyi zanimayet primerno 54–59% vremeni ack, khyesh vkhoda — 23–25%; ni odin iz etikh proverochnyikh khyeshej ne ubirayetsya radi skorosti. Povtornyij scan vosstanovleniya ostavlen dlya pereproverki prefiksa neposredstvenno pered vozmozhnyim truncate.

## Granicyi vremeni

Vremya zapisi okhvatyivayet 64 vyizova dobavitj, vklyuchaya sync; sozdaniye fajla, generaciya vkhoda i pechatj JSON vne nego. Ack-vremya — odin vyizov dobavitj do vozvrata kvitancii. Profilj vlozhennyij: vremya podtverzhdeniya vklyuchayet docherniye stadii.

Vremya recovery — otkryitiye/scan plyus yavnaya povtornaya proverka/sync chistogo fajla; dva diagnosticheskikh SHA-256 vne etogo vremeni, no vnutri RSS. Kyesh progret pervyim scan i hash. Remont khvosta, kholodnoye chteniye, perezapusk OS i poterya pitaniya zdesj ne izmeryalisj. Neizmennostj bajtov i vosstanovleniye usechyonnoj fiksturyi podtverzhdayutsya otdeljnyimi testami, a ne podmenyayutsya etim profilem.

## Vosproizvedeniye

Iz kornya kodovogo repozitoriya:

```sh
swift build --package-path Packages/КонтейнерНаблюдений --build-system native --jobs 2 -c release
fum_profile_root=$(python3 -c 'import tempfile; from pathlib import Path; print(Path(tempfile.mkdtemp(prefix="fum-container-profile-")).resolve())')
Packages/КонтейнерНаблюдений/.build/release/профиль-контейнера записать "$fum_profile_root" 64 524288
Packages/КонтейнерНаблюдений/.build/release/профиль-контейнера восстановить "$fum_profile_root"
```

V tekusjhej zadache kazhdyij vyizov i sborka vyipolnyalisj iz naznachennogo FUM-dereva cherez v4-obyortku s absolyutnyim putyom k paketu/binaryu, klassom adresnaya i tajm-autom 120 s (sborka — 180 s). Istoriyu uspeshnyikh i oshibochnyikh zapuskov pokazyivayet [otchyot](../otchyot.md). Sinteticheskiye katalogi ne yavlyayutsya poljzovateljskoj pamyatjyu i ne vklyuchayutsya v Git.

## Istochnik

- [Komanda peredachi i granica rezuljtata](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 13:26:34 MSK -->
<!-- content-sha256: sha256:9691a5b636658baceb3669d5c94792c36a9b55e42f2a680e5e15197f82cee88f -->
<!-- FUM-MD-RECENCY:END -->
