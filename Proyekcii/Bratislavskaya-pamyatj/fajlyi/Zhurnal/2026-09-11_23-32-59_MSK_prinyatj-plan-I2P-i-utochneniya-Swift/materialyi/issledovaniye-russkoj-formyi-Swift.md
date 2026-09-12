# Russkaya forma Swift cherez strukturiruyusjhiye operatoryi

Poljzovatelj vyibral preobrazovaniye russkoj iskhodnoj formyi strukturiruyusjhimi operatorami v standartnyij Swift. Posleduyusjheye utochneniye vklyuchayet sam Swift toolchain v graf sloyov operatorov po etapam. Eto postanovka, a ne gotovaya realizaciya; dejstvuyusjhaya integraciya master prodolzhayetsya nezavisimo.

## Granica pervogo preobrazovatelya

Profilj yazyika, slovarj i pravila raspoznavaniya pozicij khranyatsya versionirovannyimi dannyimi pamyati. Poljzovatelj261 razreshil SwiftSyntax kak yavno oboznachennyij bibliotechnyij primitiv; eto ne trebuyet povtorno pisatj vsyu leksicheskuyu realizaciyu. Sobstvennyiye neobkhodimyiye perekhodyi sostoyanij i kontekstnyiye ogranicheniya ostayutsya proveryayemyimi pravilami. Obsjhij ispolnitelj primenyayet eti opredeleniya i vyidayot tochnyiye standartnyiye Swift-bajtyi i kartu proiskhozhdeniya. Zamenu slov po vsemu tekstu ili yedinstvennyij neprozrachnyij vyizov gotovogo preobrazovatelya neljzya vyidavatj za vyipolneniye grafa operatorov.

Pervyij srez ogranichivayetsya obyyavleniyami funkcii i peremennoj, usloviyem i vozvratom, plyus odnim otdeljno proveryayemyim kontekstnyim sluchayem. Konkretnyij russkij slovarj yesjhyo dolzhen poluchitj yavnuyu versiyu; on ne vvoditsya molcha vo vse susjhestvuyusjhiye fajlyi. Russkiye identifikatoryi uzhe ispoljzuyutsya i mogut sovpastj s novyimi slovami. Do migracii nuzhnyi inventarj sovpadenij, plan ekranirovaniya i proverka neizmennosti obyyavlennyikh vneshnikh imyon. Kanonicheskij vkhod sleduyet otlichatj ot avtomaticheski sozdavayemogo standartnogo Swift, chtobyi obyichnaya sborka ne prinimala nepodgotovlennuyu russkuyu formu za gotovyij fajl Swift.

Leksicheskiye granicyi vklyuchayut celyiye identifikatoryi, odnostrochnyiye i vlozhennyiye blochnyiye kommentarii, obyichnyiye i mnogostrochnyiye stroki, rasshirennyiye razdeliteli, interpolyaciyu i ekranirovannyiye imena. Dannyiye literalov sokhranyayutsya pobajtno; kod vnutri interpolyacii obrabatyivayetsya po sobstvennyim granicam, vklyuchaya vlozhennyiye stroki i skobki. Chislo znakov reshyotki vliyayet na nachalo interpolyacii rasshirennogo literala. Regulyarnyiye vyirazheniya otlichayutsya ot strok i mogut byitj neodnoznachnyi s operatorami. Nepodderzhannaya konstrukciya poluchayet adresnuyu diagnostiku; yeyo neizmennoye kopirovaniye ne dokazyivayet podderzhku.

Granicyi Unicode berutsya iz zakreplyonnoj grammatiki Swift. Skryitaya normalizaciya NFC/NFKC, izmeneniye registra ili uravnivaniye ye i yo ne vvodyatsya. Imena v obratnyikh kavyichkakh sokhranyayutsya kak imena. Kontekstnyiye slova trebuyut raspoznavaniya pozicii; vesj vnutrennij perechenj tokenov kompilyatora, vklyuchaya SIL i sluzhebnyiye tokenyi, ne yavlyayetsya poljzovateljskim slovaryom yazyika.

## Diagnostika i obratnoye otobrazheniye

Karta svyazyivayet iskhodnyiye i vyikhodnyiye diapazonyi UTF-8, stroki, zamenyonnyiye i vstavlennyiye uchastki. Direktiva vneshnego Swift sourceLocation pomogayet s fajlom i strokoj, no ne ispravlyayet kolonku posle zamenyi slova drugoj dlinyi i sama vliyayet na location-makrosyi. Otdeljno proveryayutsya podsvetka, diapazonyi oshibok i ispravleniya fix-it, osobenno peresekayusjhiye zamenyonnyij uchastok. Podmena lokaljnogo puti ustojchivyim imenem istochnika vkhodit v yavnyij kontrakt, a ne vyipolnyayetsya nezametno.

Standartnyij SwiftParser mozhet proveryatj poluchennyij Swift, no yego neljzya bez adaptacii obyyavlyatj parser russkoj formyi. Nalichiye vozvrasjhyonnogo sintaksicheskogo dereva ne dokazyivayet korrektnostj: neobkhodimyi diagnostiki i kompilyaciya zakreplyonnyim toolchain. Obratnoye otobrazheniye SourceKit, formatirovaniya i makrosov — otdeljnyiye proveryayemyiye vozmozhnosti.

## Vklyucheniye kompilyatora v graf

Vkhodyi, rezuljtatyi i zavisimosti etapov podgotovki iskhodnika, razbora i proverki tipov, promezhutochnyikh predstavlenij, generacii koda, diagnostiki i zapuska dolzhnyi byitj vidimyimi uzlami grafa. Dlya kazhdogo etapa fiksiruyutsya proiskhozhdeniye, profilirovochnyiye metki i usloviya povtornogo ispoljzovaniya rezuljtata. Dostupnyiye interfejsyi zakreplyonnogo Swift toolchain sostavyat pervyij srez; dostup k vnutrennim prokhodam kompilyatora trebuyet otdeljnoj proverki kontraktov. Utochneniye ne otmenyayet standartnyij Swift kak rezuljtat perevoda russkoj formyi.

Polnota vosproizvedeniya trebuyet yavnyikh versij kompilyatora, SDK, celevoj platformyi, flagov, zavisimostej, podklyuchayemyikh makrosov i instrumentov. Perechenj realjno kontroliruyemyikh vkhodov i granica determinirovannosti dolzhnyi byitj dokazanyi; shtatnaya kompilyaciya sama po sebe ne obyyavlyayetsya pobajtovo vosproizvodimoj. Podrobneye dostupnyiye interfejsyi yesjhyo issleduyutsya.

## Proverennaya granica SwiftSyntax

Publichnyij Parser.parse i obkhod tokens s rezhimom sourceAccurate dayut vosstanovlennoye derevo s prisutstvuyusjhimi tokenami: sokhranyayutsya unexpected-uzlyi, a sinteticheskiye missing-tokenyi propuskayutsya. syntaxTextBytes predostavlyayet iskhodnyiye bajtyi. Eto poleznyij adapter, no vosstanovlennoye derevo ne podtverzhdayet praviljnostj yesjhyo russkoj grammatiki. Pryamoj Lexer.tokenize otmechen SPI dlya testirovaniya i ne obyyavlyayetsya ustojchivyim publichnyim interfejsom.

Vyiyavlen konkretnyij kontekst: raspoznavaniye literala regulyarnogo vyirazheniya bez rasshirennyikh razdelitelej zavisit ot predyidusjhego keyword ili identifier. Russkoye sootvetstviye return do preobrazovaniya yavlyayetsya identifier. Poetomu pervyij profilj dolzhen yavno diagnostirovatj neodnoznachnyiye sluchai, a rasshirennyiye razdeliteli proveryatj otdeljno. Slovarj i vyibor zamen ispolnyayutsya operatorami; bibliotechnyij razbor ne podmenyayet vesj preobrazovatelj.

SwiftSyntax ispoljzuyet Apache License2.0 s Runtime Library Exception. Licenzionnyij tekst zavisimosti sokhranyayetsya; CC0 sobstvennogo FUM ne zamenyayet yego. Po oficialjnomu README vyipuski SwiftSyntax soglasuyutsya s vyipuskami yazyika i instrumentariya. Konkretnaya sovmestimaya para, yeyo khyeshi i zerkalo yesjhyo dolzhnyi byitj zakreplenyi; issledovateljskij commit ne yavlyayetsya avtomaticheski vyibrannoj postavkoj.

## Realjnyiye vozmozhnosti tekusjhego ispolnitelya

RO-proverka Halley po checkpoint de9f81fe obnaruzhila yadro AutomationExecutor: opredeleniye otdeljno ot vkhoda, posledovateljnostj shagov, byudzhetyi, oshibki, khyeshi i profilj; ozhidayemyij otvet v ispolnitelj ne peredayotsya. Bajtovyij profilj uzhe vyirazhayet strogij UTF-8 dannyimi. Pri etom semj zakryityikh dejstvij ne predostavlyayut tokenyi, proizvoljnyiye zakhvatyi i porozhdeniye posledovateljnostej. Zamena podstroki ne uchityivayet sintaksis. Nuzhen otdeljnyij yavno versionirovannyij profilj dlya tipizirovannyikh tokenov i kartyi diapazonov, sovmestimyij s prezhnimi opredeleniyami.

Pole versii opredeleniya samo ne vyibirayet grammatiku skhemyi. Ogranichennuyu trassu v256 sobyitij neljzya ispoljzovatj kak yedinstvennoye mesto khraneniya polnoj kartyi proiskhozhdeniya: karta yavlyayetsya samostoyateljnyim rezuljtatom. Staryiye ogranicheniya bajtovogo profilya, vklyuchaya32 pravila i predel8 bajtov na pravilo, neljzya molcha oslabitj radi novogo scenariya. SwiftSyntax razreshayet bibliotechnuyu granicu razbora, no ne snimayet neobkhodimostj tipizirovannogo rezuljtata i upravlyayemogo pravilami preobrazovaniya.

Pervyij adresnyij TDD-srez mozhet menyatj odno vyibrannoye klyuchevoye slovo i sokhranyatj yego v sostavnom identifikatore, kommentarii i strokovyikh dannyikh. Samo russkoye sootvetstviye yesjhyo ne utverzhdayetsya etim primerom. Izmeneniye tablicyi i dopustimoj pozicii dolzhno menyatj rezuljtat ili otkaz bez izmeneniya adaptera. Nekorrektnyij UTF-8, nezavershyonnyiye konstrukcii, prevyisheniye byudzheta i nepodderzhannyij sintaksis dayut yavnyij otkaz bez chastichnogo rezuljtata.

## Kontraktyi compiler graph

Pervyij vertikaljnyij srez: iskhodnyiye bajtyi, SwiftSyntax-primitiv, pravila russkogo profilya, standartnyij Swift i karta diapazonov, proverka vyikhodnogo sintaksisa, vyibrannoye zadaniye swiftc, diagnostika ili artefakt. Zapusk poluchennoj programmyi yavlyayetsya otdeljnyim effektom. Proverka tipov i sborka — otdeljnyiye vetvi po potrebnosti: pyatj povtornyikh kompilyacij odnogo iskhodnika radi pyati vidimyikh uzlov ne trebuyutsya.

V zakreplyonnom issledovateljskom Swift podtverzhdenyi rezhimyi parse, typecheck, dump-parse, dump-ast, emit-silgen, emit-sil, emit-irgen, emit-ir, emit-object i emit-executable. Oni dayut raznyiye rezuljtatyi, no sami ne dokazyivayut nezavisimoye vozobnovleniye kazhdogo vnutrennego prokhoda. Format JSON AST yavno nestabilen mezhdu versiyami, a frontend CLI yavlyayetsya vnutrennim nestabiljnyim kontraktom.

JSON-protokol driver pozvolyayet nablyudatj nachalo, zaversheniye, signal i propusk zadanij. Daljnejshij adapter SwiftDriver mozhet ispoljzovatj Job s instrumentom, argumentami, vkhodami, vyikhodami i okruzheniyem. Inkrementaljnyij plan sposoben dopolnyatjsya posle analiza zavisimostej, poetomu iskhodnyij perechenj zadanij ne vsegda polnyij okonchateljnyij graf. SourceKit-LSP predostavlyayet IDE-zaprosyi; upravleniye vsemi prokhodami iz etogo ne sleduyet.

Dlya replay dopolniteljno uchityivayutsya importyi i zagolovki, linker/runtime, makroplaginyi i ikh server, okruzheniye, celevaya platforma i otobrazheniye putej. Makrosyi ispolnyayutsya otdeljnyimi programmami, zagruzchik plaginov obrasjhayetsya k fizicheskoj fajlovoj sisteme. Kyesh kompilyatora sam po sebe polnotu vkhodov ne dokazyivayet; swiftdeps ostayotsya neprozrachnyim versionnyim artefaktom. Invalidirovaniye proveryayetsya pri izmenenii kazhdogo susjhestvennogo vkhoda, otdeljno ot chistogo i povtornogo vosproizvedeniya.

## Priyomka i profilj

Nezavisimyiye fiksturyi zadayut russkij vkhod i tochnyiye ozhidayemyiye Swift-bajtyi. Proveryayutsya zasjhisjhyonnyiye oblasti, sovpadeniya imyon, kontekstnyiye slova, vlozhennaya interpolyaciya, rasshirennyiye stroki, regulyarnyiye vyirazheniya, ekranirovaniye i koordinatyi diagnostiki. Izmeneniye opredeleniya v pamyati dolzhno menyatj nablyudayemoye preobrazovaniye bez pravki ispolnitelya. Povtornoye vosproizvedeniye odinakovyikh prinyatyikh vkhodov dayot odinakovyiye khyeshi vyikhoda i kartyi.

Izmereniya razdelyayut razbor, vyipolneniye operatorov, postroyeniye kartyi, pamyatj i kompilyaciyu. Fiksiruyutsya khyeshi iskhodnika, opredelenij, slovarya, profilya grammatiki i toolchain. Optimizaciya vyipolnyayetsya po sopostavimyim izmereniyam; kompilyaciyu ne pribavlyayut povtorno k vklyuchayusjhemu yeyo vneshnemu intervalu. Migraciya susjhestvuyusjhego Swift nachinayetsya posle proverennogo pervogo sreza i sobstvennogo sukhogo plana.

Tekusjheye pravilo000028 sokhranyayet tochnyiye vneshniye klyuchevyiye slova standartnogo vyikhodnogo Swift. Dlya novoj russkoj vkhodnoj formyi trebuyetsya soglasovannoye rasshireniye kanonicheskikh pravil i proverok, bez izmeneniya pravil tekusjhego prinimayemogo snimka po khodu yego full.

## Proiskhozhdeniye

Komandyi kornevoj zadachi01a07d3d-d376-7ad2-aafc-67e4c25a67eb:258,259,260,261; originalyi i otvetyi sokhranenyi v lokaljnom JSONL s kvalificirovannyimi poziciyami. Svyazi: interpretator0208, zerkala i sborka Swift0074, planirovaniye priyoma napravlenij0201. Novaya aktivnaya zadacha ili rabocheye derevo dlya etogo napravleniya poka ne sozdavalisj.

## Pervichnyiye istochniki issledovaniya

Issledovaniye Noether,11.09.2026. Privedyonnyiye OID yavlyayutsya snimkami issledovaniya; sovmestimyij komplekt Swift/SwiftSyntax dlya realizacii yesjhyo ne vyibran i ne obyyavlyayetsya zerkalirovannyim.

- [Tokenyi kompilyatora Swift](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/include/swift/AST/TokenKinds.def).
- [Klassifikaciya klyuchevyikh slov SwiftSyntax](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/CodeGeneration/Sources/SyntaxSupport/KeywordSpec.swift).
- [Leksicheskaya struktura Swift](https://github.com/swiftlang/swift-book/blob/8e6ed2a76b95e3695a4384fc47f0c339a2b22a73/TSPL.docc/ReferenceManual/LexicalStructure.md).
- [SE0200: rasshirennyiye razdeliteli strok](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0200-raw-string-escaping.md).
- [SE0354: literalyi regulyarnyikh vyirazhenij](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0354-regex-literals.md).
- [SE0451: ekranirovannyiye identifikatoryi](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0451-escaped-identifiers.md).
- [SourceManager](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/include/swift/Basic/SourceManager.h).
- [SwiftSyntax SourceLocation](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/Sources/SwiftSyntax/SourceLocation.swift).
- [Kontrakt SwiftParser](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/Sources/SwiftParser/SwiftParser.docc/SwiftParser.md).

## Dopolniteljnyiye pervichnyiye istochniki

- [SwiftSyntax i iskhodnyiye bajtyi](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/Sources/SwiftSyntax/SyntaxProtocol.swift).
- [Rezhim obkhoda dereva](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/Sources/SwiftSyntax/SyntaxTreeViewMode.swift).
- [Granica Lexer SPI](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/Sources/SwiftParser/Lexer/Lexer.swift).
- [Kontekst literala regulyarnogo vyirazheniya](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/Sources/SwiftParser/Lexer/RegexLiteralLexer.swift#L598).
- [Licenziya SwiftSyntax](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/LICENSE.txt).
- [Sovmestimostj vyipuskov SwiftSyntax](https://github.com/swiftlang/swift-syntax/blob/d38f4e9257b4123eaf88fa13265b392c462d2d72/README.md).
- [Rezhimyi kompilyatora](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/include/swift/Option/Options.td#L1447).
- [Ogranicheniye stabiljnosti AST](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/include/swift/Option/Options.td#L1510).
- [Sobyitiya driver](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/docs/DriverParseableOutput.md).
- [SwiftDriver](https://github.com/swiftlang/swift-driver).
- [Inkrementaljnyiye zavisimosti](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/docs/DependencyAnalysis.md).
- [Granica driver/frontend](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/docs/Driver.md).
- [SourceKit-LSP](https://github.com/swiftlang/sourcekit-lsp).
- [SE0382: makrosyi](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0382-expression-macros.md).
- [Zagruzka plaginov](https://github.com/swiftlang/swift/blob/87cd32130979d689b7e6c4ae9e478a60474357b3/lib/AST/PluginLoader.cpp).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:52:33 MSK -->
<!-- content-sha256: sha256:58fc33b56eb07aec90866b90262b243afeb2e22db9f2b8a0decb9d4c5bda4b68 -->
<!-- FUM-MD-RECENCY:END -->
