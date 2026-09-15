# Prilozheniye FUM dlya macOS

Kanonicheskiye iskhodniki prilozheniya nakhodyatsya v `Приложения/FUMA/macOS` monorepozitoriya FUM. Zdesj sokhranenyi 39 fajlov sobstvennoj narabotki iz kommita `39eb66a29c0be6844e73bcb8072e68b914ea7387` s adaptaciyej putej i sborki. Istoricheskiye imena produktov sokhranenyi. Iskhodnyiye i konechnyiye khyeshi perechislenyi v [manifeste perenosa](manifest-perenosa.json).

## Sostav

- `fum` — prilozheniye s ekrannyim prisutstviyem, Accessibility, monitorom vvoda i videopamyatjyu; vstroyennaya vkladka Camera vremenno vyiklyuchena.
- `fum-mcp` — fajlovyij stdio MCP-shlyuz k prilozheniyu: sostoyaniye, ekrannyiye komandyi, AX-snimki, sobyitiya vvoda, zametki i poisk pamyati.
- `fum-attention-loop` — cikl chteniya snimkov i zapisi szhatyikh sobyitij vnimaniya.
- `fum-ax-vision-sense` — sokhranyonnyij samostoyateljnyij Accessibility-sensor.
- [Vektornyij format montazha](docs/vector-video-format.md) — ssyilki na mediamaterialyi, dorozhki i effektyi bez obyazateljnogo eksporta video.

Monitor prilozheniya sokhranyayet takzhe simvolyi klaviaturyi i ispoljzuyet nastennoye vremya. Cikl vnimaniya udalyayet polya simvolov iz sobstvennyikh agregatov. Kontrakt fizicheskikh perekhodov klavish otdeljnogo prototipa FUM etim perenosom ne realizovan.

## Zavisimosti i sborka

Nuzhnyi macOS, Xcode s SDK macOS i Swift 6, a takzhe sistemnyiye `mpv` i `pkg-config`. SwiftPM poluchayet zagolovki i biblioteku cherez `.systemLibrary`, `pkgConfig: "mpv"` i sobstvennyij modulj `CMpvSystem`. Zagolovki i iskhodniki mpv v FUM ne kopiruyutsya. Pri ispoljzovanii Homebrew zavisimosti podgotavlivayutsya otdeljno:

```sh
brew install mpv pkgconf
export PKG_CONFIG_PATH="$(brew --prefix mpv)/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
```

Eta komanda vyibirayet dostupnuyu versiyu Homebrew, a ne zakreplyayet proverennyij bottle. Sborka iz kornya chistogo klona FUM:

```sh
: "${FUM_BUILD_ROOT:?Задайте абсолютный каталог сборки вне Git}"
swift test --package-path Приложения/FUMA/macOS --scratch-path "$FUM_BUILD_ROOT" --jobs 2
swift build --package-path Приложения/FUMA/macOS --scratch-path "$FUM_BUILD_ROOT" --jobs 2 -c release
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Приложения/FUMA/macOS/проверки -p 'test_*.py'
```

Swift-testyi ispoljzuyut toljko vremennyiye fiksturyi konfiguracii putej. Python-proverki podstavlyayut sobstvennyij `swift` dlya proverki runner i ne zapuskayut nastoyasjhij helper. Artefaktyi sborki dolzhnyi nakhoditjsya vne Git. Sborka ne ustanavlivayet i ne zapuskayet prilozheniye.

Profilj obsjhej konfiguracii vosproizvoditsya otdeljno: pyatj obrazcov po 1000 razreshenij absolyutnyikh putej, otkazov otnositeljnogo puti i poiskov otsutstvuyusjhej komandyi v zadannom `PATH`, bez sozdaniya runtime-fajlov. Katalog `FUM_BUILD_ROOT` dolzhen byitj zaraneye sozdan vne Git.

```sh
swiftc -O -parse-as-library Приложения/FUMA/macOS/Sources/ПутиИсполнения/ПутиПриложения.swift \
  Приложения/FUMA/macOS/проверки/профиль-путей.swift -o "$FUM_BUILD_ROOT/профиль-путей"
"$FUM_BUILD_ROOT/профиль-путей"
```

Proverka i profilj C-adaptera ispoljzuyut podstavnyiye `dlsym` i `dlopen`. Sistemnyij mpv uchastvuyet v linkovke, yego funkcii ne vyizyivayutsya:

```sh
clang -IПриложения/FUMA/macOS/Sources/CMpvShim/include \
  -I"$(pkg-config --variable=includedir mpv)" Приложения/FUMA/macOS/проверки/проверка-C-адаптера.c \
  -L"$(pkg-config --variable=libdir mpv)" -lmpv -framework OpenGL -o "$FUM_BUILD_ROOT/проверка-C-адаптера"
"$FUM_BUILD_ROOT/проверка-C-адаптера"
```

Nativnyij `FUM.xcodeproj` soderzhit celi prilozheniya i MCP helper. Obsjhij fajl putej vklyuchyon v obe celi; sistemnyiye katalogi peredayutsya pri vyizove, a ne khranyatsya v proyekte:

Obyichnyij Xcode build takzhe registriruyet sobrannyij bundle v LaunchServices vnutri kataloga sborki. Eto nablyudyonnyij sistemnyij shag sborki; prilozheniye pri etom ne zapuskayetsya.

```sh
xcodebuild -project Приложения/FUMA/macOS/FUM.xcodeproj -scheme FUM \
  -configuration Debug -derivedDataPath "$FUM_BUILD_ROOT/xcode" -jobs 2 \
  FUM_MPV_INCLUDEDIR="$(pkg-config --variable=includedir mpv)" \
  FUM_MPV_LIBDIR="$(pkg-config --variable=libdir mpv)" \
  CODE_SIGNING_ALLOWED=NO build
```

## Konfiguraciya dannyikh

Vse processyi ispoljzuyut obsjhuyu konfiguraciyu `ПутиИсполнения`. Peremennyiye zadayut absolyutnyiye katalogi; otsutstvuyusjhiye znacheniya poluchayut sleduyusjhiye znacheniya po umolchaniyu. Pustoye znacheniye otklonyayetsya.

| Peremennaya         | Naznacheniye            | Znacheniye otnositeljno domashnego kataloga |
| ------------------ | --------------------- | ---------------------------------------- |
| `FUM_RUNTIME_ROOT`  | Tekusjhiye snimki        | `Library/Application Support/FUM/run`    |
| `FUM_MEMORY_ROOT`   | Dolgovremennaya pamyatj | `Library/Application Support/FUM/memory` |
| `FUM_DOCUMENTS_ROOT`| Biblioteka dokumentov | `Documents`                             |

Runtime i pamyatj otklonyayutsya vnutri Git checkout, vklyuchaya yego simvolicheskiye psevdonimyi. Konfiguraciya sama ne sozdayot katalogi. Putj dokumentov sluzhit vyibrannoj poljzovatelem bibliotekoj. Prezhniye `FUM_MCP_ROOT`, `FUM_ATTENTION_ROOT` i privyazka k konfiguracii Codex boljshe ne opredelyayut puti: dlya perenosa susjhestvuyusjhikh dannyikh yavno zadajte novyiye peremennyiye. Avtomaticheskogo peremesjheniya staryikh dannyikh net. `FUM_RUNTIME_ROOT` ukazyivayet neposredstvenno na katalog snimkov, dopolniteljnyij `run` k nemu ne dobavlyayetsya.

V runtime nakhodyatsya `mcp/screen.json`, `senses/ax-vision/latest.json`, `senses/input/latest.json`, `realtime/attention/latest.json` i `camera/known-people.json`. V pamyati sokhranyayutsya JSONL pod `senses/input`, `senses/ax-vision`, `video-player`, `mcp` i `realtime/attention-loop`. Eti dannyiye ne yavlyayutsya iskhodnikami.

`script/fum_mcp.sh` razreshayet paket otnositeljno sobstvennogo fajla i pered zapuskom proveryayet aktualjnostj release helper cherez SwiftPM vo vneshnem `FUM_BUILD_ROOT`. Dlya yavno vyibrannogo uzhe ustanovlennogo helper mozhno zadatj `FUM_MCP_APP_HELPER`; avtomaticheskogo vyibora prezhnej ustanovki net. Zapusk runner nachinayet zhivoj MCP-process i vyipolnyayetsya otdeljno ot proverok perenosa.

MCP poluchayet `pgrep` iz absolyutnyikh katalogov `PATH` libo iz yavno zadannogo `FUM_PGREP_EXECUTABLE`; tekusjhij katalog ne podstavlyayetsya. `FUM_APP_BUNDLE` zadayot putj ustanovlennogo bundle dlya polya statusa, pri otsutstvii konfiguracii pole ravno `null`. Istoricheskiye shablonyi trebuyut yavnyikh `FUM_APPLICATIONS_DIR`, `FUM_LAUNCH_AGENTS_DIR`, `FUM_KEYCHAIN_PATH` i `FUM_PLIST_BUDDY`; sistemnyiye komandyi razreshayutsya cherez `PATH`. Znacheniya po umolchaniyu dlya runtime i pamyati vyichislyayet obsjhij Swift-modulj cherez Foundation.

OpenGL.framework yavno linkuyetsya v SwiftPM i Xcode; obyichnyij poisk simvolov ispoljzuyet `RTLD_DEFAULT`. Toljko dlya dopolniteljnoj biblioteki pri otsutstvuyusjhem simvole mozhno yavno zadatj `FUM_OPENGL_LIBRARY`. Sinteticheskaya proverka C-adaptera podmenyayet zagruzchik i ne podtverzhdayet vosproizvedeniye video. Shablon podpisi dopolniteljno trebuyet `FUM_NULL_DEVICE` i `FUM_CERT_SUBJECT`; ikh znacheniya ne vyichislyayutsya i sistemnyiye operacii zdesj ne vyipolnyayutsya.

## Neprimenyonnyiye shablonyi ustanovki

Tri `script/install_*.sh` sokhranenyi kak istoricheskiye shablonyi i nemedlenno zavershayutsya kodom 2 do ustanovki. V `launchd/*.plist` ispoljzuyutsya nezapolnennyiye markeryi `${FUM_RUNTIME_ROOT}`, `${FUM_MEMORY_ROOT}`, `${FUM_BUILD_ROOT}` i `${FUM_APP_BUNDLE}`. Launchd sam eti markeryi ne raskryivayet. Fajlyi ne gotovyi k zagruzke: podstanovka, podpisj, ustanovka, Keychain i vyidacha sistemnyikh razreshenij trebuyut otdeljnoj podgotovki. Sandbox v istoricheskikh entitlements vyiklyuchen; perenos eto ne izmenyayet. Prilozheniye, sensoryi, ustanovka i zaprosyi razreshenij pri proverke perenosa ne zapuskayutsya.

## Nablyudyonnaya sreda i licenzii

Proverennaya lokaljnaya zavisimostj — Homebrew mpv `0.41.0_9`, `pkg-config` `3.0.7`, kliyentskij API mpv `2.5` (`mpv.pc` soobsjhayet `2.5.0`, eto ne versiya samogo mpv). Ustanovlennyij bottle soderzhit arm64 dylib s minimaljnoj macOS `26.0` i SDK `26.5`. Obyyavlennaya v proyekte macOS 14 ne dokazyivayet rabotosposobnostj etogo bottle na macOS 14/15 ili Intel. Dinamicheskaya biblioteka i yeyo zavisimosti sokhranyayut absolyutnyiye Homebrew install names: sobrannoye prilozheniye zavisit ot sistemnoj ustanovki i ne yavlyayetsya avtonomnoj perenosimoj postavkoj `.app`.

V iskhodnoj narabotke otdeljnogo LICENSE ne byilo. Sobstvennyij kod sokhranyayetsya v monorepozitorii FUM pod yego CC0; licenzii sistemnyikh bibliotek ostayutsya samostoyateljnyimi. Po [Copyright mpv 0.41.0](https://github.com/mpv-player/mpv/blob/v0.41.0/Copyright) rezhim po umolchaniyu — GPLv2+, LGPL primenyayetsya lishj k sootvetstvuyusjhej sborke. U nablyudyonnoj formulyi net `-Dgpl=false`; ustanovlennyij FFmpeg sobran s `--enable-gpl --enable-version3`. Otdeljnyij zagolovok `client.h` imeyet ISC. Etot nabor neljzya opisyivatj kak LGPL-only ili CC0, i perenos sobstvennogo koda ne oznachayet gotovnostj binarnoj publikacii.

Mekhanizm zavisimosti opisan v [dokumentacii SwiftPM](https://github.com/swiftlang/swift-package-manager/blob/main/Sources/PackageManagerDocs/Documentation.docc/Dependencies/AddingSystemLibraryDependency.md). Mashinnyiye znacheniya Xcode peredayutsya snaruzhi; [xcconfig](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project) samostoyateljno shell-komandyi ne ispolnyayet.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:32:08 MSK -->
<!-- content-sha256: sha256:bc7380ba3ea263f383d6f3276f948987b5568d85bfce385f3ec5ba5df89a1e08 -->
<!-- FUM-MD-RECENCY:END -->
