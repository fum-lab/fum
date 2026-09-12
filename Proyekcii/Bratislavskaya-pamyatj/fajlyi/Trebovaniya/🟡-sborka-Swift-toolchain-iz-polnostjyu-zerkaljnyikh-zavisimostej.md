# Sborka Swift toolchain iz polnostjyu zerkaljnyikh zavisimostej

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0074 -->

FUM dolzhen obespechivatj vosproizvodimuyu sborku polnogo Swift toolchain iz iskhodnikov i polnostjyu zerkaljnyikh pryamyikh i tranzitivnyikh zavisimostej. Trebovaniye vklyuchayet LLVM/Clang; nalichiye odnoj standartnoj biblioteki libo sistemnogo kompilyatora ne schitayetsya postavkoj instrumentariya.

Pervyij planiruyemyij profilj — native macOS arm64. Tochnyiye release/commit Swift, preset, host, bootstrap Swift, Xcode i macOS SDK vyibirayutsya i zakreplyayutsya do realizacii. Perechenj zavisimostej vyivoditsya iz etogo sochetaniya i zamyikayetsya po vsem aktivnyim sborochnyim, upakovochnyim i SwiftPM-svyazyam, a ne zamenyayetsya zaraneye vyibrannyim korotkim spiskom.

## Kriterii proverki

- Dlya kazhdogo vkhoda zapisanyi rolj, pryamoj potrebitelj, proiskhozhdeniye, versiya/polnyij OID libo khyesh, licenziya, sposob polucheniya i dostavki, arkhitektura, mesto v zerkale i kriterij polnotyi. Vklyuchenyi iskhodniki, instrumentyi sborki, upakovka, bootstrap-kompilyatoryi, SDK i tranzitivnyiye zavisimosti. Neizvestnyij ili nedostavlennyij vkhod zakryivayet sootvetstvuyusjhij dopusk; neobyyavlennyiye isklyucheniya ne vvodyatsya.
- Vse vneshniye Git-istochniki imeyut soglasovannyiye postoyannyiye forki u vladeljca aktualjnogo FUM: origin — fork, upstream — original. Polnyiye vyibrannyiye OID opublikovanyi i dostizhimyi iz forkov; tochnyiye gitlink, metadannyiye i licenzii proverenyi susjhestvuyusjhim mekhanizmom Git-zavisimostej. Sobstvennaya upravlyayusjhaya avtomatizaciya i otkryityiye fiksturyi ostayutsya v monorepozitorii.
- Plan ispoljzuyet shtatnyiye Swift build-script/build-presets i podkhodyasjhij mekhanizm update-checkout kak osnovu. Effektivnaya konfiguraciya ukazyivayet toljko soglasovannyiye zerkala i zamknutyij konechnyij spisok revizij; do i posle obnovleniya/sborki proveryayutsya polnyij sostav i kazhdyij OID. Odin tag ne sluzhit dokazateljstvom zakrepleniya; otsutstviye trebuyemoj revizii, drejf ili neuchtyonnaya zagruzka dayut otkaz bez perekhoda k inoj vershine.
- Vyibrannyij preset yavno opredelyayet postavlyayemyiye produktyi: swift/swiftc, standartnuyu biblioteku, SwiftPM i ostaljnyiye zayavlennyiye komponentyi. Dlya SourceKit-LSP/indexstore, format, DocC, playground, testirovaniya i upakovki imeyetsya resheniye po konkretnomu preset; aktivnaya zavisimostj ne isklyuchayetsya radi umenjsheniya perechnya.
- Podgotovka zerkal i materialov otdelena ot avtonomnoj sborki. Dlya avtonomnoj stadii dostupnyi realjnyiye bajtyi vsekh neobkhodimyikh vkhodov; URL, gitlink, opisaniye paketa i progretyij poljzovateljskij kyesh ne podmenyayut ikh. Dopuski bootstrap, Xcode/SDK i ogranicheniya rasprostraneniya otrazhenyi yavno; nevozmozhnostj razreshyonnoj dostavki ostayotsya prepyatstviyem, a ne isklyucheniyem iz trebovaniya.
- Budusjhaya priyomka ustanavlivayet rezuljtat v otdeljnyij prefiks, identificiruyet imenno sobrannyiye swift/swiftc i svyazannyiye resursyi, vyipolnyayet compile/run, swift build/test i konechnyiye proverki vsekh zayavlennyikh produktov. Podmena kompilyatorom iz Xcode ili PATH, nepolnaya upakovka i sluchajnoye ispoljzovaniye inyikh bibliotek isklyuchenyi nablyudayemyimi proverkami.
- Dlya budusjhej realizacii zadanyi RED/GREEN na otsutstvuyusjheye zerkalo/OID/tranzitivnyij vkhod, podmenu sostava, nepodderzhivayemuyu sredu i povtor. Sokhranyayutsya komandyi, iskhodyi, khyeshi artefaktov i otdeljnyiye profili vremeni, maksimaljnoj pamyati, diska i kyesha. Pobajtovaya identichnostj raznyikh sborok ne obesjhayetsya bez samostoyateljnogo dokazateljstva.

## Khraneniye binarnyikh vkhodov i rezuljtatov

Dlya kazhdoj vyibrannoj revizii i yeyo tranzitivnyikh komponentov proveryayutsya realjnyiye LICENSE/NOTICE i usloviya rasprostraneniya. CC0 sobstvennogo koda FUM ne podmenyayet licenzii chuzhogo instrumentariya.

Neprigodnyiye dlya Git binarnyiye vkhodyi i rezuljtatyi khranyatsya v fajlovoj sisteme vne Git i rasprostranyayutsya cherez Torrent s opisatelyami, versiyami i khyeshami v Git. Realjnyiye lokaljnyiye bajtyi i razreshyonnostj rasprostraneniya proveryayutsya otdeljno; nedostupnaya razdacha, opisatelj ili URL ne podtverzhdayut postavku. Privatnyiye dannyiye ne publikuyutsya avtomaticheski, a ogranicheniya SDK/bootstrap sokhranyayutsya kak obyazateljnyiye usloviya polnogo komplekta.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [polnoj perenosimoj oflajn-avtonomnostjyu FUM](🟡-polnaya-perenosimaya-oflajn-avtonomnostj-FUM.md) — svyazyivayet obyazateljnyiye realjnyiye bajtyi i instrumentyi s proverkoj polnogo perenosimogo komplekta bez interneta.

- **dopolnyayet:** [plan vosproizvodimoj macOS VM](🟡-plan-vosproizvodimoj-macOS-VM-dlya-FUMA.md) — sreda pervogo avtonomnogo ispyitaniya polnogo instrumentariya; gotovnostj samogo gostya podtverzhdayetsya otdeljno.

- **dopolnyayet:** [zapusk FUMA na celevyikh platformakh](🟡-zapusk-FUMA-na-celevyikh-platformakh.md) — zadayot proveryayemoye proiskhozhdeniye i postavku instrumentariya pervogo profilya; sborka toolchain ne podtverzhdayet zapusk FUMA na vsekh platformakh.

## Status i granicyi

Status trebovaniya — `🟡`.

Pervyij rezuljtat — konechnyij plan i manifest trebovanij k sborke. Forki, clone/fetch, registraciya zavisimostej, sborka i ustanovka toolchain v etot rezuljtat ne vkhodyat. Versiya Swift 6.4 v tekusjhej srede ne obyyavlyayetsya vyibrannyim release; minimaljnaya Xcode poka ne ustanovlena. Plan ne oslablyayet trebovaniye polnogo zerkalirovaniya i ne zamenyayet otdeljnyij skvoznoj plan avtonomnosti FUM.

## Obsjhaya granica zerkalirovaniya instrumentov

Ukazaniye zerkalirovatj vsyo, vklyuchaya Codex CLI, rasprostranyayetsya na fakticheski ispoljzuyemyiye vneshniye instrumentyi i ikh pryamyiye i tranzitivnyiye zavisimosti. Dlya Codex CLI sokhranyayetsya otdeljnaya zapisj obsjhego manifesta: postoyannoye zerkalo fum-lab/codex, upstream, tochnaya opublikovannaya reviziya, iskhodniki, aktivnyij sostav sborki i upakovki, resursyi i realjnyiye LICENSE/NOTICE vsego vyibrannogo komplekta. Nalichiye zerkala samo po sebe ne podtverzhdayet zamknutostj zavisimostej, dostupnostj nuzhnyikh bajtov libo vosproizvodimuyu sborku.

Codex CLI ne stanovitsya produktom Swift toolchain i ne podstavlyayetsya v yego zavisimosti bez fakticheskoj svyazi potrebitelya. Polnyij sostav vyibrannogo Swift preset ostayotsya obyazateljnyim; obsjhij komplekt vneshnikh instrumentov i yego proverka bez seti svyazyivayutsya s [oflajn-avtonomnostjyu FUM](🟡-polnaya-perenosimaya-oflajn-avtonomnostj-FUM.md). Oblachnyij backend Codex ne prevrasjhayetsya v lokaljnyij komponent iz-za zerkala kliyenta; usloviya lokaljnogo modeljnogo ispolneniya proveryayutsya otdeljno.

## Istochniki trebovanij

- [Material koordinatora o zerkale i profilyakh Codex CLI](../Zhurnal/2026-09-11_21-47-07_MSK_podtverditj-README-i-utochnitj-zerkala/materialyi/zerkalo-Codex-CLI.md).

- [Ukazaniye zerkalirovatj vsyo, vklyuchaya Codex CLI](../Zhurnal/2026-09-11_21-47-07_MSK_podtverditj-README-i-utochnitj-zerkala/zapros.md).

- [Avtonomnyij komplekt i binarnyiye obyyektyi vne Git](../Zhurnal/2026-09-11_19-12-07_MSK_prinyatj-plan-avtonomnogo-komplekta-FUM/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_18-47-36_MSK_prinyatj-plan-zerkaljnoj-sborki-Swift/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 22:18:20 MSK -->
<!-- content-sha256: sha256:ca6b2afada47309b9681be23e858696e46299f4bcdf6839811edad35d08ae3cf -->
<!-- FUM-MD-RECENCY:END -->
