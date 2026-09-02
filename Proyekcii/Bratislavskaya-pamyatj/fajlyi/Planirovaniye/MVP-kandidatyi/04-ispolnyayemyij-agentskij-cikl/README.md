# MVP-kandidat: ispolnyayemyij agentskij cikl

Ekspluatacionnyij status repozitornogo prototipa: dejstvuyusjhaya zapisj vyipolnyayetsya vruchnuyu zapuskayemyimi posledovateljnyimi sessiyami. Upomyanutyiye nizhe avtomaticheski prodolzhayemyij cikl, FIFO i handoff sokhranenyi kak prezhnij eksperimentaljnyij sloj i ne yavlyayutsya tekusjhim sposobom zapuska; produktovaya ideya MVP ostayotsya celevoj.

## Pasport

- Status: [MVP-kandidat](../../../Glossarij/MVP-kandidat.md).
- Gorizontyi dorozhnoj kartyi: [ispolnyayemyij agentskij cikl](../../dorozhnaya-karta.md) i [evolyucionnyiye cepochki](../../dorozhnaya-karta.md).
- Poljzovatelj: razrabotchik ili issledovatelj FUM, kotoromu nuzhen ne toljko otvet agenta, no i proveryayemaya trassa rabotyi.
- Minimaljnyij rezuljtat: lokaljnyij runtime odnogo ogranichennogo [agentskogo cikla](../../../Glossarij/agentskij-cikl.md), gde celj, nablyudeniya, dejstviya, proverki, sostoyaniye, itog i priznaki produktivnosti cepochki sokhranyayutsya kak strukturirovannyij artefakt pamyati.

## Produktovaya ideya dlya zapuska

Produkt: **Trassirovsjhik agentskogo progona FUM** - lokaljnyij ispolnitelj odnoj ogranichennoj zadachi s nablyudayemoj trassoj dejstvij i proverok.

Pervyij poljzovatelj - razrabotchik FUM, kotoryij khochet uvidetj ne toljko finaljnyij otvet agenta, no i prigodnyij dlya analiza sled: kakaya celj byila postavlena, kakiye dejstviya razreshenyi, chto realjno vyipolneno, kakiye proverki proshli i gde cikl ostanovilsya.

Do poyavleniya sobstvennogo runtime tekusjhaya svyazka Git + Codex uzhe proveryayet povedeniye avtomaticheski prodolzhayemogo cikla na boleye krupnoj granulyarnosti. Zaraneye sozdannaya zadacha-prodolzheniye tochnoj vetki, pryamoj vyibor sleduyusjhego shaga, FIFO-dopusk i atomarnaya peredacha svyazyivayut diskretnyiye zadachi i kommityi, a poljzovateljskaya zadacha mozhet izmenitj daljnejshuyu nablyudayemuyu trayektoriyu. Etot dejstvuyusjhij kontur yavlyayetsya povedencheskim prototipom MVP, no ne realizaciyej komandyi `fum run`: dopusjhennaya zadacha ne poluchayet ot FIFO nemedlennogo vyitesneniya, a vvod vnutri neyo yesjhyo ne nablyudayetsya kak sobyitijnyij potok.

[Bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati](../../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) proveryayet boleye uzkij vnutrennij sloj budusjhego `fum run`: versionirovannyiye sobyitiya prokhodyat cherez ogranichennyiye operacii k kanonicheskim snimku i trasse. On ne stavit celj agentu, ne vyibirayet dejstviya i ne realizuyet cikl nablyudeniya, poetomu podtverzhdayet vosproizvodimuyu pamyatj ispolneniya, no ne gotovnostj produktovogo runtime.

Poverkh etikh sloyov zavershyon [uzkij inzhenernyij eksperiment odnogo sobstvennogo runtime-scenariya](../../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md). Odin versionnyij pasport svyazyivayet sinteticheskuyu celj i kontekst s model-only-provajderom, byudzhetom, raskryitiyem dannyikh, yedinstvennyim razreshyonnyim Git-dejstviyem, proverkami i terminaljnyimi iskhodami. Tot zhe runtime provyol avtonomnuyu recorded-fiksturu i odin opt-in zhivoj lokaljnyij progon: sravnil dve modeljnyiye vetvi ot obsjhego predka, otkazal tretjyemu vyizovu po byudzhetu bez obrasjheniya k provajderu, dozhdalsya otdeljnogo vneshnego podtverzhdeniya, sozdal kandidatnyij kommit v izolirovannoj vetke, poluchil nezavisimuyu priyomku i posle dvukh fakticheskikh `SIGKILL` prodolzhil rabotu novyimi processami toljko iz podtverzhdyonnogo `CURRENT`.

Etot rezuljtat proveryayet odin zaraneye zakreplyonnyij scenarij, a ne gotovnostj komandyi `fum run`, obsjhego ili produktovogo runtime. On ne razreshayet proizvoljnyiye actions, raspredelyonnoye ispolneniye, fonovyiye zadaniya, nepreryivnyij priyom poljzovateljskogo vvoda i ne dokazyivayet preimusjhestvo FUM nad kontroljnyim agentom.

Pervyij scenarij zapuska: poljzovatelj zadayot celj i lokaljnyij scenarij s razreshyonnyimi dejstviyami. Trassirovsjhik sozdayot strukturirovannyij fajl progona, vyipolnyayet malenjkuyu zadachu na lokaljnyikh dannyikh, sokhranyayet nablyudeniya posle kazhdogo dejstviya, fiksiruyet oshibki instrumentov i zavershayet progon itogom s proverkami.

Pervyij scenarij sobstvennogo runtime ne dolzhen skryito zavisetj ot vneshnego agentskogo cikla. Yesli v progone poyavlyayetsya modeljnyij shag, on dolzhen byitj opisan kak otdeljnyij provajder: lokaljnaya LLM, proveryayemaya zaglushka ili dokazannyij rezhim `Codex CLI`, gde instrument ispoljzuyetsya kak prostoj LLM-provajder, a ne kak samostoyateljnyij cikl nablyudeniya, dejstvij i proverok. Eta granica ne otmenyayet cennostj vneshnego Git + Codex-kontura kak povedencheskogo prototipa na masshtabe diskretnyikh zadach.

Sostav pervogo reliza:

- komanda ili scenarij `fum run <scenario>`;
- bezokonnyiye interfejsyi osmotra, statusa, vozobnovleniya, vosproizvedeniya i priyomki epizoda bez obyazateljnoj privyazki k etim tochnyim imenam komand;
- prostoj format scenariya s celjyu, vkhodnyimi fajlami, razreshyonnyimi dejstviyami i ozhidayemyim rezuljtatom;
- allowlist pervyikh dejstvij: chteniye fajlov, sozdaniye otchyota i zapusk lokaljnoj proverki;
- mashinno chitayemaya trassa i chelovekochitayemoye rezyume;
- kandidatnyij kommit v izolirovannoj vetke s otdeljnoj proverkoj i yavnoj priyomkoj;
- fikstura, gde vosproizvedeniye prinyatogo epizoda dayot to zhe sostoyaniye, a povtornoye zhivoye ispolneniye oformlyayetsya kak novyij sravnivayemyij epizod.

Kriterij gotovnosti produktovogo zapuska shire zavershyonnogo eksperimenta: demonstracionnyij progon dolzhen ispoljzovatj budusjhij poljzovateljskij format scenariya i podderzhannyij nabor dejstvij, ostavlyatj polnuyu trassu nablyudayemyikh dejstvij i pokazyivatj, kakiye shagi dali proveryayemuyu poljzu, a kakiye byili ostanovlenyi ili zavershilisj oshibkoj.

## Pochemu eto mozhet byitj pervyim MVP

Etot kandidat blizhe vsego k celevomu obrazu FUM kak agenta, a ne toljko repozitoriya. On otvechayet na vopros: kakoj minimaljnyij cikl uzhe mozhno ispolnyatj tak, chtobyi on ostavlyal sled, byil proveryayem i mog stanovitjsya materialom dlya sleduyusjhego cikla.

Odnako eto boleye slozhnyij kandidat, chem pamyatj sessii ili glossarnyij kontur. Yego luchshe stroitj na uzhe proverennyikh mekhanizmakh fiksacii zaprosov, zhurnalov, ssyilok i lokaljnyikh avtomatizacij.

## Proveryayemyij MVP

Minimaljnyij variant dolzhen umetj:

- prinyatj celj i startovyij kontekst iz lokaljnoj pamyati;
- zafiksirovatj nachaljnoye sostoyaniye cikla v strukturirovannom fajle;
- yavno zapisatj kontrakt modeljnogo shaga ili otsutstviye realjnogo LLM-provajdera v pervom progone;
- vyipolnitj ogranichennyij nabor razreshyonnyikh dejstvij, naprimer chteniye fajlov, sozdaniye otchyota ili zapusk lokaljnoj proverki;
- sokhranitj nablyudeniye posle kazhdogo dejstviya;
- yavno zapisatj resheniye o prodolzhenii, ostanovke ili zaprose podtverzhdeniya;
- pri ozhidanii podtverzhdeniya zakryitj toljko tochnyij ozhidayusjhij perekhod i, yesli modeljnaya sreda i yeyo byudzhet nezavisimo razreshenyi, prodolzhitj bezopasnuyu modeljnuyu rabotu ot zafiksirovannogo obsjhego predka;
- sokhranitj itogovyij rezuljtat, proverki i svyazj s izmenyonnyimi fajlami;
- vosproizvoditj prinyatoye sostoyaniye iz versionirovannyikh vkhodov, a posle poyavleniya dolgovremennyikh pokolenij poluchatj odinakovyij kanonicheskij rezuljtat iz polnogo replay i prodolzheniya ot podtverzhdyonnogo pokoleniya.
- posle prinuditeljnogo preryivaniya prodolzhitj rabotu novyim processom iz poslednego podtverzhdyonnogo pokoleniya bez skryitogo konteksta prezhnej sessii.

## Kriterii priyomki

- Kazhdyij shag cikla imeyet tip: nablyudeniye, namereniye, dejstviye, rezuljtat proverki ili ostanovka.
- Cikl ne vyipolnyayet vneshniye dejstviya bez yavnogo razreshyonnogo adaptera.
- Oshibka instrumenta sokhranyayetsya kak nablyudeniye, a ne teryayetsya v terminaljnom vyivode.
- Itog mozhno prochitatj kak chelovekochitayemyij otchyot i kak mashinno obrabatyivayemuyu trassu.
- Kandidatnyij kommit ne stanovitsya prinyatoj istinoj bez otdeljnogo protokola proverki i priyomki.
- Modeljnoye prodolzheniye ne vyipolnyayet ozhidayusjhij vneshnij effekt, ne uvelichivayet razresheniya iz-za molchaniya poljzovatelya i otdelyayet modeljnyiye statusyi `selected_in_model` i `recommended` ot svideteljstv `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed` i `observed`.
- Identichnostj provajdera, lokaljnostj ili udalyonnostj, raskryitiye dannyikh i predelyi vyizovov, tokenov, vremeni, vyichislenij i deneg yavno zadanyi do epizoda; ozhidaniye ne rasshiryayet eti predelyi.
- Pri dostatochnom byudzhete minimum dve soderzhateljno razlichimyiye vetvi imeyut odin tochnyij obsjhij predok, yavnyiye deljtyi i odinakovo primenimyiye proverki; pri byudzhete toljko na odnu vetvj trassa sokhranyayet neproverennyiye aljternativyi i ne obyyavlyayet neodnoznachnostj ustranyonnoj.
- Prinuditeljnoye preryivaniye v zaraneye zadannoj kontroljnoj tochke ne teryayet podtverzhdyonnoye sostoyaniye i ne trebuyet prezhnego chata dlya vozobnovleniya.
- Trassa pozvolyayet ocenitj, naskoljko cepochka byila dlinnoj, poleznoj i produktivnoj: kakiye shagi sozdali proveryayemuyu poljzu, kakiye porodili sleduyusjhij material, a kakiye okazalisj kholostyimi.
- Minimaljnaya fikstura podtverzhdayet determinirovannoye [vosproizvedeniye prinyatogo epizoda FUM](../../../Glossarij/vosproizvedeniye-prinyatogo-epizoda-FUM.md); novyij vyizov realjnoj modeli otnositsya k [povtornomu zhivomu ispolneniyu FUM](../../../Glossarij/povtornoye-zhivoye-ispolneniye-FUM.md) i ocenivayetsya otdeljno.

## Ne vkhodit v pervyij variant

- Samostoyateljnaya dolgovremennaya avtonomiya bez poljzovateljskogo zaprosa.
- Fizicheskoye dejstviye, vneshniye servisnyiye operacii i upravleniye privatnyimi dannyimi.
- Polnyij avtomaticheskij darvinovskij otbor neskoljkikh agentov ili vyichisleniye vesov, khotya polya trassyi dolzhnyi gotovitj dannyiye dlya takogo otbora.
- Neogranichennoye vetvleniye, raskhodovaniye nerazreshyonnogo provajdera ili byudzheta i perenos modeljnogo pobeditelya v kanonicheskuyu pamyatj bez otdeljnoj politiki prinyatiya.
- Rabotayusjhij kanal nepreryivnogo sobyitijnogo nablyudeniya poljzovateljskogo vvoda i perenapravleniye nezavershyonnogo runtime; versiya `2` uzhe proveryayet staticheskij format etogo styika otdeljnoj lokaljnoj fiksturoj, no ne realizuyet kanal.

Ogranichennyiye [fonovyiye zadaniya FUM](../../../Glossarij/fonovoye-zadaniye-FUM.md) otnosyatsya ne k pervomu variantu, a k sleduyusjhemu sloyu korobochnogo runtime. Format [poljzovateljskogo perenapravleniya cikla](../../../Trebovaniya/🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) uzhe proveren na sinteticheskoj bezopasnoj kontroljnoj tochke; do fonovogo planirovsjhika sobstvennyij runtime dolzhen otdeljno dokazatj korrektnostj sostoyaniya, ostanovki, zhivogo priyoma vkhoda i primeneniya toj zhe granicyi na yavno zadannoj poljzovateljskoj celi.

## Zavisimosti

- [Pamyatj rabochej sessii](../01-pamyatj-rabochej-sessii/README.md) kak predvariteljnyij kontur fiksacii rezuljtata.
- Lokaljnyiye pravila [vosproizvodimyikh avtomatizacij](../../../Glossarij/avtomatizaciya-FUM.md).
- Yavnaya granica mezhdu modeljnyim planom i realjnyim dejstviyem.
- Versionirovannyij kontrakt neblokiruyusjhego modeljnogo prodolzheniya iz [FUM-STEP-0106](../../kartochki-shagov/✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md) do vklyucheniya etogo povedeniya v ispolnyayemyij runtime.
- [Bezokonnyij Swift-kontur](../../../Trebovaniya/✅-bezokonnyij-Swift-kontur-pervogo-korobochnogo-prototipa.md) i [vosproizvodimoye shtatnoye popolneniye pamyati](../../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md) kak nizhnij sloj sostoyaniya do dobavleniya agentskogo vyibora.
- Proyasneniye [razvilki giperseti i agentskogo cikla FUM](../../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md) pered utverzhdeniyem runtime, kotoryij dolzhen vkladyivatj ciklyi drug v druga.

## Riski

- Mozhno prezhdevremenno uslozhnitj runtime, vmesto togo chtobyi proveritj malenjkij ponyatnyij cikl.
- Trassa ne dolzhna raskryivatj skryityiye rassuzhdeniya ili privatnyiye dannyiye; yej dostatochno fiksirovatj nablyudayemyiye dejstviya, resheniya i rezuljtatyi.
- Neljzya smeshivatj planirovaniye budusjhego s utverzhdeniyami o fakticheskom sostoyanii proyekta.
- Neljzya smeshivatj nepreryivnostj vkhodnogo i upravlyayusjhego kontura s nepreryivnyim inference: [sobyitijnoye nablyudeniye](../../../Trebovaniya/🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md) dolzhno dopuskatj yavnuyu filjtraciyu i agregaciyu bez vyizova LLM na kazhdoye sobyitiye.

## Pervyij eksperiment

Pervyij uzkij inzhenernyij eksperiment zavershyon na sinteticheskoj lokaljnoj zadache. Sobstvennyij runtime chereduyet modeljnyij shag, strogij razbor namereniya, proverku, razreshyonnoye dejstviye, nablyudeniye i resheniye o prodolzhenii; sokhranyayet yedinstvennuyu trassu i terminaljnyij iskhod; sozdayot tochnyij izolirovannyij kandidat s izmeneniyem `artifact.txt`; peredayot yego otdeljnomu processu priyomki. Vneshnij harness posle podtverzhdyonnogo vnutrennego vyibora i posle podtverzhdyonnogo nablyudeniya kandidata dvazhdyi zavershayet worker cherez `SIGKILL`, a novyiye PID prodolzhayut epizod iz kanonicheskogo `CURRENT` bez prezhnego chata, stdin i skryitogo sostoyaniya processa.

Avtonomnaya recorded-fikstura proveryayet dva varianta ot obsjhego predka, no-call-otkaz tretjyemu variantu po konechnomu byudzhetu, determinirovannyij replay i otsutstviye model-, tool-, Git- i workspace-effektov pri vosproizvedenii. Odin opt-in zhivoj progon tem zhe runtime ispoljzuyet uzhe dostupnyij lokaljnyij model-only-provajder i zakreplyayet yego identity, usage, PID, checkpoint, candidate object i otdeljnuyu priyomku v [otchyote](../../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md).

Etot inzhenernyij eksperiment ne menyayet yedinstvennyij aktivnyij produktovyij MVP arkhivirovaniya prikreplyayemyikh materialov, ne naznachayet reliz FUM i ne prevrasjhayet tochnyij sinteticheskij Git-adapter v obsjhij allowlist dejstvij.

Dokumentacionnaya forma eksperimenta zakreplena v [minimaljnom formate trassyi ispolnyayemogo agentskogo cikla](../../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md). Prezhnyaya lokaljnaya JSONL-fikstura proveryayet semj tipov sobyitij, vosstanovimuyu oshibku, allowlist dejstviya, otsutstviye realjnogo modeljnogo shaga i zaversheniye po nablyudayemomu rezuljtatu. Zavershyonnyij Swift-eksperiment dobavlyayet nablyudayemoye ispolneniye toljko odnogo scenariya; oba rezuljtata ostayutsya vkhodami dlya budusjhego `run`, a ne utverzhdeniyem o gotovom universaljnom ispolnitele.

[FUM-STEP-0073](../../kartochki-shagov/✅-FUM-STEP-0073-nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati.md) zavershil pervyij ispolnyayemyij Swift-bootstrap: dva chistyikh replay dayut odinakovyij kanonicheskij artefakt, a nedopustimyij vkhod zavershayetsya tipizirovannyim otkazom. [FUM-STEP-0074](../../kartochki-shagov/✅-FUM-STEP-0074-dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu.md) dobavil vosstanavlivayemyiye pokoleniya i dokazal skhodimostj polnogo i inkrementaljnogo puti; postanovka celi, modeljnyij shag i agentskij vyibor ostayutsya otdeljnyimi kriteriyami runtime.

[Kontrakt chistogo modeljnogo shaga](../../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md) versii `1` i yego [Swift-prototip s determinirovannoj zaglushkoj](../../../Prototipyi/chistyij-modeljnyij-shag/README.md) teperj proveryayut sleduyusjhij izolirovannyij sloj: polnyij yavnyij kontekst, tochnuyu identichnostj provajdera, predelyi, zapret instrumentov, fajlov i seti, kanonicheskij otvet, svyazannyij s vkhodom, i strukturirovannyiye oshibki. Zaglushka ne yavlyayetsya LLM i ne realizuyet runtime cikla; realjnyij lokaljnyij provajder i neagentskij rezhim `Codex CLI` trebuyut otdeljnyikh conformance-proverok.

[Zavershyonnaya kartochka FUM-STEP-0072](../../kartochki-shagov/✅-FUM-STEP-0072-opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom.md) zakrepila determinirovannyij eksperiment bez vneshnikh effektov: razreshyonnyij poljzovateljskij vkhod postupayet do zaversheniya iskhodnogo plana, prokhodit cherez sinteticheskuyu bezopasnuyu kontroljnuyu tochku i nablyudayemo menyayet celj, vetku i yesjhyo ne nachatoye dejstviye. Fikstura versii `2` razlichayet soobsjheniye-zadachu, dva pervichnyikh sobyitiya i ikh agregirovannyij signal, sokhranyaya prezhneye i novoye prodolzheniya; zhivoj sobyitijnyij runtime iz etogo rezuljtata ne sleduyet.

[Kartochka FUM-STEP-0106](../../kartochki-shagov/✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md) dobavlyayet k etomu konturu drugoj determinirovannyij scenarij: podtverzhdeniye tochnogo perekhoda otsutstvuyet, vneshnij effekt ostayotsya zakryit, a dve byudzhetirovannyiye modeljnyiye vetvi ot obsjhego predka proveryayutsya i sravnivayutsya bez vyidachi modeljnogo vyibora za poljzovateljskuyu volyu ili za prinyatuyu kanonicheskuyu pamyatj.

Posleduyusjhij korobochnyij eksperiment dobavlyayet dve ocheredi: pri otsutstvii poljzovateljskogo vvoda i gotovoj boleye prioritetnoj zadachi zapuskayetsya odno byudzhetirovannoye fonovoye opisaniye modeli mira i yazyikovogo prostranstva testovoj LLM-zaglushki; postupleniye poljzovateljskogo vvoda sokhranyayet trassu i perenapravlyayet fon na obyyavlennoj bezopasnoj kontroljnoj tochke.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../../../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../../../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../../../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../../../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-23 18:12:05 MSK - Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla](../../../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-24 16:22:00 MSK](../../../Zhurnal/2026-06-24_16-22-00_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-03 15:36:48 MSK - Utochnitj razvilku giperseti i agentskogo cikla](../../../Zhurnal/2026-07-03_15-36-48_MSK_utochnitj-razvilku-giperseti-i-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-14 03:18:36 MSK - Zakrepitj fonovyiye zadaniya dlya prostoya LLM](../../../Zhurnal/2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:07:48 MSK — Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../../Zhurnal/2026-07-22_13-07-48_MSK_sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../../../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)

## Opornyiye materialyi

- [Otchyot o zhivom progone odnoagentnogo epizoda](../../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Agentskij cikl](../../../Glossarij/agentskij-cikl.md)
- [Razvilka giperseti i agentskogo cikla FUM](../../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md)
- [Pasport nachaljnogo korobochnogo prototipa FUM](../../../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:720af9d978787911586b6ea739ff17ad9a8137cc112693551179bc0cd460e6f8 -->
<!-- FUM-MD-RECENCY:END -->
