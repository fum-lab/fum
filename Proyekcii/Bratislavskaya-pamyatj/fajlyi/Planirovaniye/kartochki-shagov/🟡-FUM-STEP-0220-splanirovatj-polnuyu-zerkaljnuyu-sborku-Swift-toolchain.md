+++
schema_version = 1
card_id = "FUM-STEP-0220"
status = "active"
+++
# Splanirovatj polnuyu zerkaljnuyu sborku Swift toolchain

## Zadacha

Podgotovitj konechnyij plan sborki i ustanovki Swift toolchain dlya native macOS arm64 iz polnostjyu zerkaljnyikh iskhodnikov i vsekh pryamyikh i tranzitivnyikh zavisimostej. Itog — pasport profilya, zamknutyij manifest vkhodov, karta povtornogo ispoljzovaniya shtatnyikh mekhanizmov i pervaya ispolnyayemaya postanovka s proveryayemoj priyomkoj.

## Pochemu sejchas

Poljzovatelj poruchil dobavitj sborku Swift-instrumentariya iz iskhodnikov po analogii s LinguisticKit i otdeljno potreboval zerkala vsekh zavisimostej, vklyuchaya LLVM/Clang. Nyineshnyaya ustanovka Swift ili zakryitaya kompoziciya sobstvennyikh SwiftPM-paketov ne dokazyivayut etu granicu.

## Kriterii zaversheniya

- Pervyij avtonomnyij scenarij privyazan k susjhestvuyusjhemu [planu macOS VM](../../Trebovaniya/🟡-plan-vosproizvodimoj-macOS-VM-dlya-FUMA.md) i FUM-STEP-0216. Proveryayutsya tochnyij profilj gostya, peredannyiye realjnyiye vkhodyi i otsutstviye skryitogo ispoljzovaniya seti ili poljzovateljskogo kyesha khosta; novyij nezavisimyij backend VM ne naznachayetsya.
- Peredannyij inventarj tekusjhego FUM razlichayet yedinstvennyij podklyuchyonnyij gitlink LinguisticKit, lokaljnyiye SwiftPM-svyazi i sistemnuyu zavisimostj prilozheniya mpv. Dlya kazhdogo nuzhnogo vyibrannomu scenariyu vkhoda razdeljno ustanavlivayutsya obyyavleniye, zakrepleniye, zerkalo, nalichiye bajtov i proverennaya gotovnostj. Polnyij dylib-graf mpv i nablyudyonnyiye Homebrew-versii ne schitayutsya zakreplyonnyim toolchain-naborom. Inventarizaciya i proverka zamyikaniya dolzhnyi statj vosproizvodimoj avtomatizaciyej pered materializaciyej zerkal.

- Vyibran odin tochnyij release/polnyij commit Swift i podkhodyasjhij preset dlya macOS arm64; zafiksirovanyi sovmestimyiye host, bootstrap Swift, Xcode/SDK i native instrumentyi po oficialjnyim dokumentam vyibrannoj revizii. Yesli osnovaniye vyibora yesjhyo nedostupno, probel nazvan s neobkhodimyim svideteljstvom i zakryityim perekhodom k realizacii.
- Polnostjyu razobranyi konfiguraciya update-checkout, build-script, preset i aktivnyiye tranzitivnyiye manifests vyibrannogo sreza. Manifest soderzhit vse uzlyi i ryobra, vklyuchaya LLVM/Clang, sborochnyiye i upakovochnyiye instrumentyi, testovyiye vkhodyi i SwiftPM. Dlya uslovnyikh komponentov ukazano usloviye vklyucheniya; neizvestnyiye svyazi ne schitayutsya zamknutyimi.
- Proyekt kartyi zerkal svyazyivayet original, budusjhij soglasovannyij fork ryadom s aktualjnyim FUM, origin/upstream, tochnyij OID, licenzii, gitlink i realjnyiye bajtyi dostavki. Git i ne-Git vkhodyi razlichayutsya; bootstrap/SDK ne skryivayutsya v primechanii kak neobyazateljnyiye. Konkretnyiye zerkala ne sozdayutsya etim shagom.
- Opisana shtatnaya podgotovka cherez build-script/build-presets i adresno proverennyiye parametryi update-checkout. Otdeljnaya zakryitaya proverka polnogo spiska OID do i posle operacii isklyuchayet fallback k ordinary update pri otsutstvuyusjhem tag. Susjhestvuyusjhaya avtomatizaciya Git-zavisimostej pereispoljzuyetsya dlya svoyej oblasti; nedostayusjhaya proverka zamknutosti poluchayet samostoyateljnyij konechnyij kontrakt.
- Opredelenyi otdeljnyiye onlajn-podgotovka i avtonomnaya sborka na dostupnom nabore bajtov, bez skryityikh fetch/download i poljzovateljskogo setevogo kyesha. Nazvanyi sposobyi postavki i pravovyiye ogranicheniya kazhdogo obyazateljnogo SDK/instrumenta; otsutstviye razreshyonnogo sposoba fiksiruyetsya prepyatstviyem bez isklyucheniya zavisimosti.
- Sostavlena priyomka ustanavlivayemogo toolchain: otdeljnyij prefiks, versii i puti sobrannyikh swift/swiftc, compile/run, SwiftPM build/test i proverki vsekh zayavlennyikh produktov. Otdeljno vyiyavlyayetsya podmena sistemnyim instrumentariyem. Odna stdlib ili soobsjheniye ob uspeshnoj kompilyacii kompilyatora ne zakryivayut postavku.
- Plan soderzhit otkaznyiye fiksturyi i povtor, granicu chistoj/povtornoj sborki, tochnyiye nablyudeniya vremeni/RAM/diska/kyesha i sposob sravneniya rezuljtatov. Preryivaniye sokhranyayet razlichimoye nezavershyonnoye sostoyaniye. Chislovyiye byudzhetyi naznachayutsya po obosnovannomu profilyu, a ne vyidayutsya zaraneye kak izmerennyiye.
- Sokhranenyi voprosyi o release, minimaljnoj Xcode, polnom sostave, dostavke SDK i pervom sostave produktov, s istochnikom ozhidayemogo otveta i zavisimyim resheniyem. Itogovoye naznacheniye ostayotsya planovyim: mnogogigabajtnyiye klonyi, izmeneniye toolchain, sborka i rasshireniye tekusjhikh detektorov vnimaniya ne vyipolnyayutsya.

## Istochniki

- [Iskhodnaya komanda](../../Zhurnal/2026-09-11_18-47-36_MSK_prinyatj-plan-zerkaljnoj-sborki-Swift/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 19:03:51 MSK -->
<!-- content-sha256: sha256:6ffb5ef63c6cb1b19dbc38ec66dd213902b95ad2696b7ffa16292ea3494ab64b -->
<!-- FUM-MD-RECENCY:END -->
