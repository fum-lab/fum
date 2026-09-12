# Polnaya perenosimaya oflajn-avtonomnostj FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0075 -->

FUM dolzhen imetj perenosimyij komplekt, dostatochnyij dlya zayavlennoj rabotyi bez dostupa k internetu. Polnota otnositsya k pamyati i Zhurnalu, sobstvennomu interpretatoru, interfejsu, sborke, proverkam i realjnyim bajtam vsekh neobkhodimyikh zavisimostej i dannyikh. Perechenj URL, gitlink ili zaraneye progretyij setevoj kyesh ne yavlyayetsya takim komplektom.

Pervyij planiruyemyij proverochnyij profilj — macOS VM na vyibrannoj arkhitekture. Etot profilj zadayot konechnuyu pervuyu priyomku, no ne otmenyayet skvoznoye trebovaniye i ostaljnyiye celevyiye platformyi. Predvariteljnoye polucheniye i zakonnaya podgotovka komplekta onlajn otdelenyi ot yego posleduyusjhego avtonomnogo ispoljzovaniya.

## Binarnyiye obyyektyi i rasprostraneniye

Binarnyiye obyyektyi, neprigodnyiye dlya khraneniya v Git, sokhranyayutsya v fajlovoj sisteme vne Git i v Torrent-seti. Git khranit vosproizvodimyiye opisateli, versii, razmeryi, khyeshi soderzhimogo i neobkhodimyiye metadannyiye polucheniya i proverki. Torrent sluzhit rasprostraneniyu i dopolniteljnyim kopiyam; dostupnostj razdachi, nalichiye polnogo lokaljnogo obyyekta i vklyucheniye proverennyikh bajtov v perenosimyij komplekt podtverzhdayutsya otdeljno. Opisatelj, magnet-ssyilka ili svedeniya ob uchastnikakh ne oznachayut, chto nuzhnyij obyyekt poluchen.

V avtonomnuyu VM peredayutsya realjnyiye proverennyiye fajlyi; obrasjheniye k Torrent za nedostayusjhej chastjyu ne vkhodit v oflajn-stadiyu. Plan razlichayet publichno rasprostranyayemyiye obyyektyi, ogranichennyiye licenziyej vkhodyi i privatnyiye runtime-dannyiye. Perepiska, tokenyi, klyuchi, poljzovateljskiye diski i drugiye privatnyiye dannyiye ne publikuyutsya avtomaticheski. Dlya neobkhodimyikh SDK, obrazov i modelej sokhranyayetsya razreshyonnyij sposob dostavki libo konkretnoye prepyatstviye; trebuyemyiye bajtyi ne isklyuchayutsya iz polnogo sostava.

## Kriterii proverki

- Dlya vyibrannoj revizii kazhdogo vneshnego komponenta i vsekh nuzhnyikh tranzitivnyikh vkhodov prochitanyi realjnyiye LICENSE/NOTICE, otrazhenyi obyazannosti sokhraneniya uvedomlenij, usloviya sborki i rasprostraneniya iskhodnikov/binarnikov. Sobstvennyij kod FUM pod CC0 ne izmenyayet vneshnyuyu licenziyu. Dlya pervogo fajlovogo profilya I2P v [FUM-STEP-0183](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0183-opredelitj-adapteryi-decentralizovannyikh-setej.md) vyibran libtorrent-rasterbar 2.1.1, polnyij OID 56ae8caba38bf154ffc210403cb23f91d0ecaa49, BSD-3-Clause; WebTorrent=OFF. Etot vyibor ne zamenyayet proverku polnogo sostava zavisimostej, ikh bajtov i licenzij i ne obyyavlyayet gotovnostj obsjhego Torrent-profilya dlya ostaljnyikh scenariyev.
- Yestj zamknutyij manifest tochnogo FUM OID i vsekh neobkhodimyikh fajlov, Git-obyyektov/zavisimostej, instrumentov, SDK, dannyikh, konfiguracij, modelej i ikh parametrov. Dlya kazhdogo elementa zadanyi versiya/khyesh, proiskhozhdeniye, potrebitelj, razmer, pravo i sposob perenosa. Neuchtyonnyiye bootstrap, SDK ili tranzitivnyiye vkhodyi ne obyyavlyayutsya isklyucheniyem iz vsekh zavisimostej.
- Matrica funkcij otlichayet avtonomno dostupnoye povedeniye, vnutrennyuyu nezavershyonnuyu realizaciyu i dejstviye, kotoromu po smyislu nuzhna vneshnyaya setj. Dlya poslednego chelovek poluchayet yavnuyu nedostupnostj, a namereniye i nezavershyonnaya rabota sokhranyayutsya dlya dopustimogo prodolzheniya. Propavshaya setj ne sozdayot lozhnyij uspekh i ne otmenyayet porucheniye.
- Determinirovannyiye strukturiruyusjhiye operatoryi ispolnyayutsya lokaljno bez obyazateljnoj LLM. Kazhdaya zayavlennaya modeljnaya funkciya imeyet lokaljnyij ispolnitelj, realjnyiye parametryi/dannyiye modeli, dopustimyiye resursyi i proverennyij scenarij. Zapisannyij otvet ili remote API ne zamenyayet lokaljnoye modeljnoye ispolneniye; otsutstviye nuzhnoj modeli ostayotsya nezakryitoj chastjyu komplekta.
- Vyibranyi tochnyiye host/guest macOS, arkhitektura, bootstrap, SDK, sposob ustanovki i dostupnyiye resursyi. Obyazateljnyiye vkhodyi s ogranicheniyami rasprostraneniya imeyut yavnyij razreshyonnyij sposob dostavki; yesli on ne ustanovlen, polnota ne podtverzhdayetsya. Ikh neljzya molcha ubratj iz manifesta ili zamenitj obesjhaniyem budusjhego skachivaniya.
- Budusjhaya priyomka perenosit zayavlennyij komplekt v otdeljnuyu macOS VM i otklyuchayet vneshnij setevoj dostup toljko etoj VM. Vnutri gostya proveryayutsya chteniye pamyati i Zhurnala, sobstvennyij interfejs, operatornyij scenarij, zayavlennaya lokaljnaya modeljnaya funkciya, sborka, proverki i sokhraneniye/vozobnovleniye rezuljtata. Globaljnaya setj khosta ne menyayetsya.
- Uspekh ne zavisit ot download/fetch, udalyonnoj rezolyucii, oblachnoj sessii, katalogov instrumentov khosta ili neuchtyonnogo progretogo kyesha. Dostup k obsjhim katalogam ogranichen peredavayemyim komplektom i uchtyon. Otsutstviye iskhodyasjhego dostupa podtverzhdayetsya nablyudayemoj konfiguraciyej i otkaznyimi scenariyami.
- Povtor v novom processe i povtornaya proverka na chistom gostevom sostoyanii ispoljzuyut tot zhe komplekt. Otsutstvuyusjhaya/povrezhdyonnaya zavisimostj, nedostayusjhiye parametryi modeli, nevernyij SDK, vyikhod za byudzhet i obrasjheniye k seti dayut yavnyij otkaz bez porchi sokhranyonnoj rabotyi. Vremya, pamyatj, disk i obyyom perenosa izmeryayutsya otdeljno ot logicheskogo rezuljtata.

## Semanticheskiye svyazi

- **dopolnyayet:** [sborku Swift toolchain iz polnostjyu zerkaljnyikh zavisimostej](🟡-sborka-Swift-toolchain-iz-polnostjyu-zerkaljnyikh-zavisimostej.md) — proveryayet postavku realjnyikh instrumentov i ikh zavisimostej vnutri polnogo avtonomnogo komplekta FUM.

- **dopolnyayet:** [zapusk FUMA na celevyikh platformakh](🟡-zapusk-FUMA-na-celevyikh-platformakh.md) — utochnyayet avtonomnyij sposob postavki i proverki polnogo komplekta vyibrannoj platformyi; odin macOS VM progon ne zakryivayet ostaljnyiye platformyi.
- **dopolnyayet:** [plan vosproizvodimoj macOS VM dlya FUMA](🟡-plan-vosproizvodimoj-macOS-VM-dlya-FUMA.md) — dobavlyayet samostoyateljnyij scenarij proverki komplekta bez interneta poverkh prigodnogo gostevogo zhiznennogo cikla; ne zamenyayet realizaciyu VM.

## Status i granicyi

Status trebovaniya — `🟡`.

Pervyij rezuljtat ogranichen analiticheskim planom, manifestom trebovanij k perenosimomu komplektu i programmoj budusjhej oflajn-priyomki. VM, sborki, zagruzki modelej i zavisimostej sejchas ne zapuskayutsya. Tekusjheye naznacheniye dvukh detektorov vnimaniya ne rasshiryayetsya do realizacii vsego oflajn-produkta. Neizvestnyiye dostavka, lokaljnaya modelj i fakticheskaya gotovnostj komponentov sokhranyayutsya kak otkryityiye usloviya; oni ne dayut prava obyyavitj urezannyij komplekt polnoj avtonomnostjyu FUM.

## Codex CLI i zamknutyij komplekt vneshnikh instrumentov

Codex CLI vklyuchayetsya v obsjhij inventarj zerkaliruyemyikh vneshnikh instrumentov vmeste so vsemi fakticheski neobkhodimyimi pryamyimi i tranzitivnyimi zavisimostyami vyibrannoj sborki i postavki. Manifest svyazyivayet zerkalo fum-lab/codex, iskhodnyij upstream, tochnyij opublikovannyij OID, realjnyij sostav sborki/upakovki, instrumentarij, resursyi, versii, khyeshi, razmeryi, potrebitelej i realjnyiye LICENSE/NOTICE. Zerkalo iskhodnikov, pustoj gitlink, lock-fajl libo progretyij setevoj kyesh ne zamenyayut zamknutyij perenosimyij komplekt; ogranicheniya zakonnoj dostavki ne skryivayutsya isklyucheniyem obyazateljnogo vkhoda.

Zerkalo Codex CLI sokhranyayet otkryityij kliyent i dostupnyiye zavisimosti. Ono ne vklyuchayet po umolchaniyu oblachnyij backend, modeljnyiye vesa, servisnuyu infrastrukturu ili pravo dostupa i ne dokazyivayet oflajn-rabotu oblachnoj modeljnoj funkcii. Matrica otdeljno proveryayet sobstvennuyu sborku i lokaljno dostupnyiye funkcii kliyenta, funkcii s neobkhodimoj setjyu i nalichiye vyibrannogo lokaljnogo modeljnogo ispolnitelya s realjnyimi parametrami. Nedostupnostj oblaka dayot yavnyij nezavershyonnyij iskhod, a ne uspeshnuyu zaglushku; zerkalirovaniye CLI ne pogashayet prezhneye trebovaniye lokaljnoj modeljnoj funkcii polnogo avtonomnogo FUM. Do yeyo proverki polnaya avtonomnostj ostayotsya nedokazannoj.

Dlya budusjhej proverki ispoljzuyutsya realjnyiye bajtyi zayavlennogo komplekta v chistom gostevom profile s otklyuchyonnoj vneshnej setjyu. Otsutstvuyusjhij tranzitivnyij vkhod, skryitaya zagruzka, nepodderzhannyij lokaljnyij provajder libo nedostupnaya modelj dayut yavnyij otkaz s sokhraneniyem rabotyi. Sozdaniye fum-lab/codex koordiniruyetsya otdeljno: povtornyij fork ne sozdayotsya. Zerkalo, vyibrannyij pin i polnota podtverzhdayutsya pered ispoljzovaniyem shtatnyim mekhanizmom zavisimostej; dannoye planovoye utochneniye ne zayavlyayet vyipolneniye clone, sborki, podklyucheniya akkaunta ili oblachnogo vyizova.

## Profili postavki Codex CLI

Issledovateljskij material koordinatora svyazyivayet publichnoye zerkalo fum-lab/codex i upstream openai/codex s OID 33bdf976ccd1130823d4fe041e4d5075ab511d67. Eto snimok main, a ne vyibrannyij stabiljnyij reliz. Lokaljnyij clone, gitlink, ustanovka i sborka ne sleduyut iz fakta zerkalirovaniya i proveryayutsya otdeljno.

Plan razlichayet tri granicyi postavki, sokhranyaya polnyij sostav togo profilya, kotoryij trebuyetsya zayavlennyim funkciyam FUM:

- Odinochnyij binarnik codex: tochnyiye iskhodniki, target, Rust 1.95.0 i yego komponentyi, Cargo.toml/Cargo.lock/konfiguraciya Cargo, dostupnyiye bez seti crates s kontroljnyimi summami, primenimyiye C/C++ compiler/linker/SDK. V prochitannom materiale perechislenyi shestj Git-istochnikov Cargo.lock: microsoft/mxc, helix-editor/nucleo, dzbarsky/rules_rust, openai-oss-forks/crossterm, tokio-tungstenite i tungstenite-rs. Do realizacii po lockfile izvlekayutsya ikh polnyiye OID i zamyikayutsya aktivnyiye vlozhennyiye zavisimosti; spisok nazvanij ne zamenyayet etot manifest.
- Polnyij workspace/release: krome codex uchityivayutsya codex-code-mode-host, proxy i platformennyiye helpers. Dlya puti polucheniya native-arkhivov nuzhnyi zakreplyonnyiye arkhivyi V8, bindings i checksum manifest; material ukazyivayet kontrakt 150.4.0. Iskhodnaya sborka V8 15.0.245.2 imeyet otdeljnyij Bazel-graf s MODULE.bazel/lock, libc++, libc++abi i llvm-libc i ostaljnyimi aktivnyimi vkhodami. Polucheniye gotovogo native-arkhiva ne obyyavlyayetsya sborkoj V8 iz iskhodnikov, a odinochnyij codex ne obyyavlyayetsya polnyim relizom.
- npm-upakovka: launcher zapuskayet podgotovlennyij Rust-binarnik i trebuyet otdeljnogo komplekta Node/npm, pnpm 10.34.5, pnpm-lock.yaml i platformennyikh payload. Kornevyiye JS-instrumentyi i launcher imeyut raznyiye ogranicheniya Node: ne nizhe 22 i ne nizhe 16 sootvetstvenno po ukazannomu snimku. Obyichnaya dokumentirovannaya Cargo-sborka ne poluchayet obyazateljnyiye JS-zavisimosti toljko po sosedstvu katalogov. Profili macOS, Linux musl i Windows MSVC dlya arm64/x64 razlichayutsya; odna upakovka ne dokazyivayet ostaljnyiye.

Polnota proveryayetsya na zamorozhennom lockfile i realjnyikh bajtakh pri fakticheski zapresjhyonnoj seti, s khyeshami rezuljtatov i otdeljnyimi profilyami vremeni, pamyati i diska. Neizvestnyiye libo nedostavlennyiye vkhodyi ne vyichyorkivayutsya radi uspekha, pobitovaya vosproizvodimostj ne obesjhayetsya bez otdeljnogo dokazateljstva. Po materialu Codex sokhranyayet Apache-2.0, a NOTICE ukazyivayet v tom chisle proiskhozhdeniye Ratatui pod MIT; realjnyiye LICENSE/NOTICE i licenzionnyij sostav kazhdogo vyibrannogo profilya proveryayutsya do ispoljzovaniya. CC0 sobstvennogo koda ne menyayet eti usloviya.

Ni odin profilj zerkalirovaniya i sborki ne predostavlyayet oblachnyij backend ili vesa modelej. Lokaljnyiye Ollama/LM Studio trebuyut sobstvennogo runtime, zaraneye dostupnoj modeli i otdeljnoj proverennoj sovmestimosti vyibrannoj revizii. Sokhranyayutsya prezhniye obyazateljnyiye kriterii polnogo avtonomnogo FUM; zerkalo kliyenta ne zamenyayet lokaljnoye modeljnoye ispolneniye.

## Istochniki trebovanij

- [Material koordinatora o zerkale i profilyakh Codex CLI](../Zhurnal/2026-09-11_21-47-07_MSK_podtverditj-README-i-utochnitj-zerkala/materialyi/zerkalo-Codex-CLI.md).

- [Ukazaniye zerkalirovatj vsyo, vklyuchaya Codex CLI](../Zhurnal/2026-09-11_21-47-07_MSK_podtverditj-README-i-utochnitj-zerkala/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_19-12-07_MSK_prinyatj-plan-avtonomnogo-komplekta-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:52:33 MSK -->
<!-- content-sha256: sha256:a332817384ac79e680349340ecd077c53ca4df15e2f5f70dabc1fd1f8a882e5f -->
<!-- FUM-MD-RECENCY:END -->
