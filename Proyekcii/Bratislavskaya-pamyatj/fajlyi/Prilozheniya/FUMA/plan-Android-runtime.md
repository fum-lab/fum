# Podgotovka FUMA dlya Android

Status: prinyato v rabotu otdeljnoye napravleniye podgotovki runtime. Zapusk FUMA na Android poka ne podtverzhdyon. Osnovaniye — [porucheniye i otvetyi](../../Zhurnal/2026-09-15_20-33-17_MSK_prinyatj-obnovlyonnoye-postoyannoye-planirovaniye/zapros.md).

FUMA razvivayetsya na yedinoj sobstvennoj kodovoj baze v monorepozitorii. Obsjhiye Swift-paketyi soderzhat interpretator strukturiruyusjhikh operatorov, formatyi nablyudenij i perenosimuyu logiku. Platformennyiye adapteryi predostavlyayut khraneniye, vvod, zhiznennyij cikl, graficheskuyu poverkhnostj i sistemnyiye vozmozhnosti. Isklyucheniya dostupnosti oboznachayutsya yavno; moduli macOS ne importiruyutsya v obsjheye yadro.

## Pervyij ogranichennyij rezuljtat

1. Proveritj uzhe susjhestvuyusjhiye paketyi i zavisimosti, vyidelitj minimaljnyij perenosimyij srez bez dublirovaniya interpretatora.
2. Podgotovitj vosproizvodimuyu avtomatizaciyu ustanovki soglasovannyikh Swift toolchain, Swift SDK for Android i Android NDK; versii i khyeshi zakrepitj posle fakticheskoj proverki. Uchestj susjhestvuyusjhij plan zerkal, licenzii i avtonomnuyu postavku.
3. Sobratj obsjhij scenarij UTF-8 → Unicode-skalyaryi → UTF-32 i zapisj/povtor nablyudeniya dlya yavnogo Android ABI i urovnya API.
4. Vyipolnitj scenarij na dostupnom emulyatore libo ustrojstve cherez avtomatizaciyu. Sokhranitj polnyij vkhod, ozhidayemyiye i fakticheskiye bajtyi, kod processa, platformu i proiskhozhdeniye. Kompilyaciya otdeljno ot zapuska.
5. Vyipolnitj neobkhodimyiye RED/GREEN, izmeritj vremya zapuska, ispolneniya i perekhoda cherez platformennyij most, ocenitj optimizacii. Sborki i testyi macOS ne povtoryatj bez zatronutogo kontrakta.

Minimaljnoye Android-prilozheniye mozhet potrebovatj tonkoj Java/Kotlin-obolochki i JNI. Predpochteniye — obsjhaya logika na Swift; obyyom platformennogo koda opredelyayetsya realjnyimi ogranicheniyami SDK. Net obesjhaniya yedinstvennogo binarnika dlya vsekh OS i otsutstviya lyubogo mosta.

## Sobstvennyij interfejs

Interfejs po vozmozhnosti polnostjyu sobstvennyij. Obsjheye opisaniye scenyi i povedeniya stroitsya strukturiruyusjhimi operatorami; platformennyiye ispolniteli vyidayut komandyi Metal ili Vulkan. Dlya Android pervyim graficheskim putyom planiruyetsya Vulkan. Sistemnaya poverkhnostj, vvod, dostupnostj i zhiznennyij cikl trebuyut otdeljnyikh kontraktov i proverki. Pikseljnoye sovpadeniye raznyikh GPU zaraneye ne obyyavlyayetsya.

Pervyij runtime-srez ne vklyuchayet zavershyonnyij graficheskij interfejs. Sleduyusjhij srez svyazyivayet obsjhij graf scenyi s Vulkan, proveryayet sobyitiye vvoda i odin nablyudayemyij kadr. Prezhnyaya celj DirectX ostayotsya dlya primenimyikh profilej; posledneye utochneniye ne byilo yeyo yavnoj otmenoj.

## Istochniki i svyazi

- [Platformennoye trebovaniye](../../Trebovaniya/🟡-zapusk-FUMA-na-celevyikh-platformakh.md).
- [Graficheskoye trebovaniye](../../Trebovaniya/🟡-graficheskiye-interfejsyi-FUMA.md).
- [FUM-STEP-0182](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md).
- [Oficialjnaya sborka Swift dlya Android](../../Istochniki/URL/https/www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html/source-index.md).
- [Oficialjnyij vyipusk SDK v Swift 6.3](../../Istochniki/URL/https/www.swift.org/blog/swift-6.3-released/source-index.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 20:44:05 MSK -->
<!-- content-sha256: sha256:a1b5f6c5eb36d709bcc4755b8b30deb2492f946ab58e758a16016f6df6140161 -->
<!-- FUM-MD-RECENCY:END -->
