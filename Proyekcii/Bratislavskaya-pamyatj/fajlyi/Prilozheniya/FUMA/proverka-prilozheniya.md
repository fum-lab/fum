# Proverka prilozheniya iz chistogo klona

Publichnyij kommit `9c39c9b3fde83c4ce11ba101897c1298c68d436d` poluchen iz `https://github.com/fum-lab/fum.git` v otdeljnyij chistyij katalog. Proverenyi pyatj Swift Testing testov, 12 Python-proverok, chetyire Release-produkta SwiftPM, nativnaya Debug-sborka Xcode i dva sinteticheskikh profilya. Vosemj Mach-O artefaktov prochitanyi i khyeshirovanyi bez zapuska. Posle proverki derevo ostalosj chistyim, lokaljnogo grafa Obsidian net.

[Mashinnoye svideteljstvo](../../Zhurnal/2026-09-11_02-51-49_MSK_proveritj-postavku-FUMA-iz-klona/materialyi/sborka-prilozheniya-iz-klona.json) svyazyivayet kommit, rezuljtatyi, khyeshi artefaktov i profilj processov. Vse 71 fajla paketov sovpadayut s raneye proverennyim `aeae18cb146a34563ff39c84d9bc5ef59fffab91`; ikh [133 testa, chetyire Release-sborki i pyatj profilej](proverka-paketov.md) ne povtoryalisj. Obsjhij iskhodnyij nabor prilozheniya i paketov — 110 fajlov.

## Vosproizvedeniye

Klonirujte FUM, vyiberite opublikovannyij kommit i podgotovjte zavisimosti po [rukovodstvu prilozheniya](macOS/README.md). Ono soderzhit obyichnyiye komandyi SwiftPM, Xcode, Python, Swift-profilya i C-profilya. Zadajte absolyutnyij `FUM_BUILD_ROOT` vne Git; katalog dolzhen susjhestvovatj. Dlya sborok ispoljzovanyi dva rabochikh potoka. Kyeshi, konfiguraciya SwiftPM i DerivedData takzhe vyinesenyi v etot katalog:

```sh
swift test --package-path Приложения/FUMA/macOS --scratch-path "$FUM_BUILD_ROOT"   --cache-path "$FUM_BUILD_ROOT/cache" --config-path "$FUM_BUILD_ROOT/config"   --security-path "$FUM_BUILD_ROOT/security" --jobs 2
swift build --package-path Приложения/FUMA/macOS --scratch-path "$FUM_BUILD_ROOT"   --cache-path "$FUM_BUILD_ROOT/cache" --config-path "$FUM_BUILD_ROOT/config"   --security-path "$FUM_BUILD_ROOT/security" --jobs 2 -c release
```

Dlya etoj priyomki dopolniteljno ispoljzovana vneshnyaya `sandbox-exec`, zapresjhayusjhaya chteniye prezhnikh lokaljnyikh katalogov istochnikov. Otkaz chteniya realjno susjhestvuyusjhego iskhodnogo fajla proveren otdeljno. Eto ogranicheniye chteniya, ne obsjhij zapret zapisi, seti ili sistemnyikh IPC. Sama sborka vyipolnyayetsya iz klona s sistemnyimi SDK i mpv.

Vnutri vneshnej pesochnicyi SwiftPM poluchayet `--disable-sandbox`, a Xcode — otdeljnyij argument `OTHER_SWIFT_FLAGS="-Xfrontend -disable-sandbox"`. Oni otklyuchayut toljko vlozhennuyu pesochnicu zapuska instrumentov; vneshnij zapret chteniya ostayotsya. SwiftPM takzhe poluchil sovmestimyij s prezhnimi proverkami `--build-system native`; nablyudyonnyij Swift preduprezhdayet, chto etot flag ustarevayet. Obyichnaya sborka bez vneshnej pesochnicyi etikh parametrov ne trebuyet.

Pervyij Xcode bez parametra dlya makrosov zavershilsya kodom 65: `swift-plugin-server` ne smog primenitj vlozhennuyu pesochnicu i makrosyi SwiftUI ne zagruzilisj. Neuspeshnyij zapusk sokhranyon. Povtor s dokumentirovannyim lokaljnoj spravkoj frontend parametrom vyipolnen v novom DerivedData i zavershilsya `BUILD SUCCEEDED`, kodom 0. Iskhodniki i proyekt ne menyalisj. Xcode registriruyet sobrannyij bundle v LaunchServices; prilozheniye ne zapuskayetsya.

## Nablyudyonnyiye rezuljtatyi

| Process                   | Real, s | Maksimaljnyij RSS, bajt | Rezuljtat                    |
| ------------------------- | ------- | ---------------------- | ---------------------------- |
| SwiftPM test              | 16,89   | 661618688              | Pyatj testov proshli           |
| SwiftPM Release           | 20,43   | 919781376              | Chetyire produkta sobranyi       |
| Xcode, pervaya popyitka     | 11,02   | 461619200              | Otkaz vlozhennoj pesochnicyi     |
| Xcode, sovmestimyij zapusk | 16,84   | 574701568              | Debug app i helper sobranyi    |
| Kompilyaciya i dva profilya  | 4,34    | 299253760              | Sinteticheskiye scenarii proshli |

Vremya i RSS poluchenyi sistemnyim `time -l` na macOS; RSS ukazan v bajtakh. Eto profilj pryamyikh processov s podgotovkoj, kompilyaciyej i ozhidaniyem. Sborki vyipolnyalisj pri razreshyonnoj paralleljnoj lyogkoj proverke drugoj zadachi; profili — posle osvobozhdeniya obsjhego okna. Iz etikh chisel neljzya vyivoditj chistuyu stoimostj kompilyatora ili effekt optimizacii.

[Swift-profilj](../../Zhurnal/2026-09-11_02-51-49_MSK_proveritj-postavku-FUMA-iz-klona/materialyi/profilj-putej.json) soderzhit pyatj obrazcov po 1000 povtorenij. Medianyi na vyizov: proverka absolyutnyikh katalogov — okolo 173,27 mks, otkaz otnositeljnogo puti — 1,70 mks, poisk otsutstvuyusjhej komandyi — 12,89 mks. Fajlyi runtime ne sozdavalisj. Eto konfiguracionnaya operaciya; izmereniye ne vyiyavlyayet neobkhodimosti optimizacii v granice perenosa.

[C-profilj](../../Zhurnal/2026-09-11_02-51-49_MSK_proveritj-postavku-FUMA-iz-klona/materialyi/profilj-C-adaptera.json) ispoljzuyet podstavnyiye `dlsym`/`dlopen`: po 100000 povtorenij dali 956000 i 852000 ns. Eti sinteticheskiye chisla ne izmeryayut realjnyij zagruzchik, mpv ili vosproizvedeniye video. Optimizaciya po nim ne obosnovana.

## Granica postavki

Sreda: macOS 27 arm64, Xcode 27 beta, Swift 6.4, Homebrew mpv `0.41.0_9`, kliyentskij API mpv `2.5`. [Ogranicheniya platformyi i licenzij](macOS/README.md) sokhranyayutsya: ustanovlennyij bottle trebuyet macOS 26, dinamicheskiye zavisimosti ne vklyuchenyi v avtonomnyij bundle, podderzhka staryikh macOS i Intel ne proverena. SwiftPM i Xcode preduprezhdayut ob ustarevshem OpenGL i nesovpadenii celevoj macOS 14 s ustanovlennoj bibliotekoj.

Eta proverka podtverzhdayet vosproizvodimostj iskhodnikov na nablyudyonnoj srede. Ustanovka, podpisj, launchd, vyidacha razreshenij, realjnyiye sensoryi i ispolneniye MCP-komand ostayutsya otdeljnyimi dejstviyami. Paketyi yesjhyo ne podklyuchenyi k prilozheniyu.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:071f6af463936b0fbcf9724c0f6287be2a59d4ae11d060c2806794084823bfc1 -->
<!-- FUM-MD-RECENCY:END -->
