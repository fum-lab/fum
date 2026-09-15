# Otchyot 2026-09-11 02:51:49 MSK - Proveritj postavku FUMA iz klona

Vse 110 iskhodnyikh fajlov sokhranenyi v opublikovannom `9c39c9b3`. Sborki i sinteticheskiye proverki obyyedinyonnogo klona zavershenyi. Obsjhij dopusk fiksiruyetsya poslednim sostavnyim zapuskom v mashinnom bloke; itogovyij OID proveryayetsya posle kommita.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                           |
| ------------------------ | ------------ | ---------------------------------------------------- |
| Klon i integraciya        | ne izmereno  | Lokaljnaya podgotovka i chteniye tochnyikh rezuljtatov    |
| Proverki prilozheniya     | sm. nizhe     | Pryamyiye processyi, otdeljnyiye izmereniya vremeni i RSS  |
| Finaljnyij obsjhij dopusk  | sm. nizhe     | Standartnyij smoke i shtatnoye zamyikaniye otchyota        |

Granica profilya: etap nachat 2026-09-11 02:51:49 MSK; prezhniye etapyi, perekryityiye intervalyi detej i ozhidaniye soobsjhenij ne summiruyutsya. FIFO i avtomaticheskij handoff ne ispoljzuyutsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:7021ffd15ea06e0911117b7a551671df7e69960b0b925720dddf8b2fa6c735fb -->

| Vyizov                                                                                             | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj 0176] Proveritj prilozheniye iz publichnogo klona s zapretom prezhnikh katalogov               | 1,305 s      | uspeshno   |
| [Korenj 0176] Podtverditj proiskhozhdeniye chistogo klona i dejstvuyusjhij zapret chteniya                 | 0,238 s      | uspeshno   |
| [Korenj 0176] Proveritj isklyucheniye otsutstvuyusjhego lokaljnogo grafa posle integracii               | 0,142 s      | uspeshno   |
| [Korenj 0176] Proveritj vse Markdown-ssyilki chistogo klona bez lokaljnogo grafa                    | 22,494 s     | uspeshno   |
| [Korenj 0176] SwiftPM testyi prilozheniya iz publichnogo chistogo klona                                | 16,898 s     | uspeshno   |
| [Korenj 0176] SwiftPM Release prilozheniya iz publichnogo chistogo klona                              | 20,443 s     | uspeshno   |
| [Korenj 0176] Xcode Debug prilozheniya iz publichnogo chistogo klona                                  | 11,033 s     | neuspeshno |
| [Korenj 0176] Xcode iz chistogo klona s vneshnej pesochnicej i sovmestimyim zapuskom makrosov         | 16,85 s      | uspeshno   |
| [Korenj 0176] Sinteticheskiye Swift i C profili prilozheniya iz chistogo klona                         | 4,345 s      | uspeshno   |
| [Korenj 0176] Proveritj Mach-O artefaktyi i chistotu klona posle sborok                             | 0,234 s      | uspeshno   |
| [Korenj 0176] Proveritj publikacionnyiye puti obyyedinyonnogo soderzhimogo                             | 21,212 s     | neuspeshno |
| [Korenj 0176] Peresobratj planovyij reyestr posle postavki i zakryitiya sboya grafa                    | 0,353 s      | uspeshno   |
| [Korenj 0176] Proveritj tochnyij indeks bez perepisyivaniya doslovnyikh zaprosov                        | 0,035 s      | uspeshno   |
| [Korenj 0176] Proveritj probelyi zaprosov s sokhraneniyem tochnogo poljzovateljskogo originala        | 0,017 s      | uspeshno   |
| [Korenj 0176] Povtoritj skaner posle pyati tochnyikh deklaracij proiskhozhdeniya i fiksturyi              | 21,389 s     | uspeshno   |
| [Korenj 0176] Proveritj svyaznostj podgotovlennogo vkhoda pered poslednim smoke                     | 37,046 s     | neuspeshno |
| [Korenj 0176] Proveritj zavershayusjhij trailer posle ispravleniya granicyi abzaca                      | 0,063 s      | uspeshno   |
| [Korenj 0176] Finaljnyij standartnyij dopusk integrirovannoj postavki FUMA                          | 387,227 s    | neuspeshno |
| [Korenj 0176] Proveritj tochnoye pokryitiye udalyonnoj proizvodnoj kartochki i tekusjhego Git-sostoyaniya   | 0,286 s      | uspeshno   |
| [Korenj 0176] Finaljnyij standartnyij dopusk posle tochnoj deklaracii udalyonnoj proizvodnoj kartochki | 733,77 s     | neuspeshno |
| [Korenj 0176] Lokalizovatj otkaz schyotchika chteniya osnovaniya guard                                  | 1,35 s       | neuspeshno |
| [Korenj 0176] Proveritj prezhneye ispravleniye schyotchika chteniya osnovaniya guard                       | 1,368 s      | uspeshno   |
| [Korenj 0176] Finaljnyij standartnyij dopusk posle perenosa prezhnego ispravleniya mock               | 328,06 s     | neuspeshno |
| [Korenj 0176] Proveritj vse puti okonchateljno dopolnennogo Zhurnala i kanonicheskogo dereva         | 21,539 s     | uspeshno   |
| [Korenj 0176] Finaljnyij standartnyij dopusk posle polnoj proverki putej Zhurnala                    | 757,007 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2404,704 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Chistaya sborochnaya priyomka zavershena: pyatj Swift Testing testov, 12 Python-proverok, chetyire Release-produkta i Xcode Debug, dva sinteticheskikh profilya. Vosemj Mach-O artefaktov proverenyi bez ispolneniya. Klon ostalsya chistyim. [Rukovodstvo i rezuljtatyi](../../Prilozheniya/FUMA/proverka-prilozheniya.md) svyazyivayut tochnyij publichnyij kommit s nablyudeniyami. Vse 71 fajla raneye prinyatyikh paketov neizmennyi; 133 testa, chetyire Release-sborki i pyatj profilej ne povtoryalisj. Finaljnyij obsjhij dopusk uchityivayetsya poslednim sostavnyim zapuskom nizhe.

## Resheniya i ogranicheniya

Sreda i licenzii sistemnogo mpv ogranichivayut tekusjhuyu proverku. Podderzhka staryikh macOS, drugikh arkhitektur i avtonomnoye rasprostraneniye bundle ne dokazanyi. Pervyij vyizov polucheniya vremeni poluchil otkaz do zapuska iz-za opechatki v puti; praviljnaya shtatnaya komanda zatem dala ispoljzovannuyu paru. Proverochnaya kvitanciya zadnim chislom ne sozdayotsya.

Posle poljzovateljskogo perezapuska sokhranyonnyiye HEAD, ref, indeks i zavershyonnyiye rezuljtatyi sovpali. Susjhestvuyusjhij pisatelj proyekcii vozobnovlyon yedinstvennyim `followup_task`; yego 14 uspeshnyikh testov i profilj ne povtoryayutsya. Zavershyonnyij pisatelj prilozheniya ne vozobnovlyalsya. Prezhnij nezavisimyij revjyuyer poluchil novyij ogranichennyij read-only-audit kommita 0203, kotoryij ustranyayet prepyatstviye otsutstvuyusjhego lokaljnogo grafa. Tyazhyolyiye sborki yesjhyo ne nachinalisj iz novogo klona i ozhidayut osvobozhdeniya okna 0177; prezhniye proverki rabochego dereva ne podmenyayut etu ostavshuyusya priyomku.

Kommit `28f51c58fa8df4d20d33ef2f05dab758cb7a6f83` prinyat vyiborochno: tri fajla kontura svyaznosti i iskhodnyij Zhurnal avtora s sokhranyonnyim UUID. Nezavisimoye revjyu ne nashlo ispravlyayemyikh zamechanij. Isklyucheniye dejstvuyet toljko dlya otsutstvuyusjhego lokaljnogo grafa s tochnyim registrom i dopustimyimi predkami; ono ne oslablyayet proverki drugikh ssyilok. Prezhnyaya obrabotka uzhe susjhestvuyusjhikh simvolicheskikh celej etim izmeneniyem ne peresmatrivayetsya.

Vse 1598 kanonicheskikh Markdown-fajlov chistogo publichnogo klona proshli ssyilochnyij dopusk kodom 0203; graf ne sozdavalsya, derevo ostalosj chistyim. Kommit vkhoda i prinyatyij proveryayusjhij kod razlichenyi v mashinnom svideteljstve. Eto zakryivayet tochnyij kriterij sboya 0052; obsjhij finaljnyij dopusk vsej postavki yesjhyo predstoit.

Pri vosstanovlenii rebyonka obnaruzhena osirotevshaya zapisj proverki: process boljshe ne nablyudayetsya, no iskhod i dliteljnostj neizvestnyi. Zapisj ne ispravlyayetsya vruchnuyu. Novyij etap vosstanovleniya opirayetsya na 000060 i sobstvennuyu okhvachennuyu granicu 000185–000188; predyidusjhiye otchyot i JSON ostayutsya nezakryityim proiskhozhdeniyem. Nezavisimyij audit podtverdil etu ogranichennuyu interpretaciyu. Korotkiye otkazyi chteniya po neverno predpolozhennyim imenam fajlov i sintaksicheskij otkaz vneshnego vyizova do ispolneniya ne dali izmenenij; fakticheskiye imena zatem poluchenyi iz inventarya.

Novyij chistyij progon SwiftPM proshyol: pyatj Swift Testing testov i chetyire Release-produkta. Pervyij Xcode pod vneshnim zapretom chteniya staryikh katalogov zavershilsya kodom 65: `swift-plugin-server` ne smog vlozhenno primenitj sandbox dlya makrosov SwiftUI (`sandbox_apply: Operation not permitted`). Lokaljnaya spravka `swiftc -frontend -help-hidden` podtverzhdayet `-disable-sandbox`; povtor poluchayet `OTHER_SWIFT_FLAGS="-Xfrontend -disable-sandbox"` toljko kak parametr priyomochnoj sborki pri sokhranyonnoj vneshnej pesochnice. Kod proyekta i sistemnyiye nastrojki ne menyayutsya. Otkaz sokhranyon otdeljnoj mashinnoj zapisjyu; povtor ispoljzuyet novyij DerivedData.

Vyiborochno prinyat opublikovannyij `582fae9778073ffedcdf347509887c84a4334e27`: devyatj fajlov kontura proyekcii i chetyire iskhodnyikh Zhurnala. Sokhranenyi 14 adresnyikh GREEN, profilj perekhoda i otdeljnoye vosstanovleniye prervannoj peredachi; pryamoj checkpoint novogo etapa proshyol. Korenj povtorno prochital itogovyij diff centraljnoj proverki vladeniya: razreshena rovno odna zakreplyonnaya prezhnyaya politika, proveryayemaya polnyim khyeshem; strogij itogovyij manifest i neizvestnyiye politiki ostayutsya zakryityimi.

Povtor Xcode v novom DerivedData proshyol s `BUILD SUCCEEDED`, kod 0. Makrosyi zapuskayutsya vnutri sokhranyonnoj vneshnej pesochnicyi; iskhodniki klona ne menyalisj. Xcode vyipolnil obyyavlennuyu registraciyu postroyennogo bundle v LaunchServices, bez zapuska prilozheniya.

Navigaciya obyyedinyonnyikh Zhurnalov peresobrana shtatnyimi repair i reindex ot tochnogo `9c39c9b3`. Plan dopolniteljno predlagal 27 davnikh semanticheskikh izmenenij v tryokh chistyikh fajlakh vne obyyoma; toljko eti fajlyi vosstanovlenyi iz iskhodnogo HEAD posle primeneniya. Dva novyikh izmeneniya v zaprose prilozheniya lishj normalizuyut tot zhe adres. Prezhniye otchyotyi i mashinnyiye zapisi rebyonka sokhranenyi; menyayetsya neobkhodimaya navigaciya zaprosov i yeyo recency. Popyitka prochitatj vremennyij JSON-plan do zaversheniya processa dala otkaz razbora, posle zaversheniya prochitan polnyij plan; povtor generatora ne zapuskalsya.

Plan razovoj zadachi pered finaljnoj zamorozkoj utochnyon po fakticheskoj granice: zavershena podgotovka soderzhateljnogo paketa. Prezhnyaya formulirovka «Projti finaljnyij dopusk, opublikovatj exactOID i peredatj koordinatoru» ne obyyavlena zaraneye vyipolnennoj. Vesj etot ostatok sokhranyayetsya obyazateljnoj zavershayusjhej posledovateljnostjyu: poslednij standartnyij smoke → proveritj-plan → zakryitj → rovno odno primeneniye i odna nezavisimaya proverka proyekcii → fiksaciya → publikaciya tochnogo OID → podtverzhdeniye udalyonnogo OID → peredacha koordinatoru → read-only guard → otvet. Norma 000062 pryamo vozlagayet smyislovuyu polnotu na korenj; guard sam ne dokazyivayet publikaciyu. Posle zamorozki plan ne perepisyivayetsya radi podtverzhdeniya sobstvennogo kommita.

Publikacionnyij skaner vyiyavil pyatj otsutstvuyusjhikh deklaracij prinyatogo rebyonka: dva uzhe zapisannyikh fizicheskikh kornya etapov, dve istoricheskiye komandyi s vremennyimi vyikhodami i stroku regressionnogo prisoyedineniya `foreign.txt` k otnositeljnoj celi. Kazhdaya stroka prosmotrena i poluchayet otdeljnyij tochnyij fingerprint shtatnyim obnovleniyem politiki; iskhodniki prilozheniya ne poluchayut novyikh chastnyikh zavisimostej. Obratimyij Base64 prezhnego zaprosa dekodirovan i proveren kornem; on sokhranyayet tot zhe obyyavlennyij korenj etapa, bez inyikh lokaljnyikh absolyutnyikh putej. Pervichnyij otkaz skanera uchtyon, zatem vyipolnyayetsya adresnyij povtor.

Predvariteljnaya svyaznostj obnaruzhila odin defekt oformleniya vremennogo soobsjheniya kommita: tri posledovateljnyikh perevoda stroki pered trailer ostavlyali pustuyu stroku vnutri poslednego bloka dlya strogogo parsera. Git raspoznaval trailer, no lokaljnyij kontrakt yego otklonyal. Doslovnyiye komandyi ne menyalisj; mezhdu nimi i zavershayusjhim trailer dobavleno soderzhateljnoye poyasneniye. Povtor ogranichen proverkoj soobsjheniya; ostaljnyiye projdennyiye chasti predvariteljnoj svyaznosti ne perezapuskayutsya otdeljno ot obyazateljnogo finaljnogo smoke.

Pervonachaljnyiye pyatj diagnosticheskikh nablyudenij s ustojchivyimi vremennyimi klyuchami sokhranenyi v [materiale dlya raspredelitelya](materialyi/nablyudeniya-dlya-raspredelitelya.json). Koordinator naznachil kanonicheskuyu numeraciyu vladeljcu obsjhego raspredelitelya 0201 i poruchil ne zaderzhivatj nezavisimuyu priyomku istochnikov. Vyidelennyiye ID i kanonicheskiye kartochki zdesj ne vyidumanyi; ikh otdeljnaya fiksaciya ne obyyavlena vyipolnennoj. 0025 i 0052 uzhe imeyut sobstvennyiye kartochki i ne dubliruyutsya.

Nezavisimyij zavershayusjhij read-only-audit sopostavil rukovodstvo s pyatjyu profilyami processov, mashinnyim JSON i iskhodnyimi logami: chislennyiye i smyislovyiye ispravlyayemyiye nesootvetstviya ne najdenyi. Proverenyi pyatj Swift testov, chetyire Release-produkta, posledovateljnostj otkaza i uspekha Xcode, dve sinteticheskiye metodiki i ogranicheniya sandbox, LaunchServices, platformyi i licenzij. Auditor nichego ne zapuskal i ne izmenyal; vse docherniye pishusjhiye rabotyi zavershenyi do zamorozki vkhoda.

Pervyij finaljnyij standartnyij zapusk `5c5b135b-f0cb-44f4-a33e-7b8275025695` zavershilsya otkazom na shage 11 posle uspeshnogo primeneniya proyekcii (6811 fajlov, 215,556 s), nezavisimoj proverki i ostaljnyikh pervyikh desyati shagov. Prichina — nepolnoye opisaniye izmenyonnyikh putej: ssyilka na susjhestvuyusjhij katalog pokryivayet lishj susjhestvuyusjhikh potomkov, poetomu udalyonnaya staraya proizvodnaya kartochka 0176 trebovala tochnogo markera. Po dejstvuyusjhemu kontraktu svyaznosti dobavlen yedinstvennyij `Удалённый файл` dlya realjno otsutstvuyusjhej celi. Kod i proverka ne oslablyayutsya. Kanonicheskij vkhod izmenyon etim neobkhodimyim ispravleniyem; daleye provoditsya adresnaya proverka oblasti i novyij finaljnyij standartnyij zapusk. Staryij otkaz (387,227 s po vneshnej obyortke) sokhranyayetsya i ne schitayetsya priyomkoj novogo vkhoda.

Vtoroj finaljnyij zapusk `3cb41946-c609-4f13-9bfa-41dac6073c88` uspeshno zavershil pervyiye 23 shaga i otkazal v poslednem nabore: 238 testov, odno nesootvetstviye `0 != 1` v `test_повторное_основание_читается_один_раз_за_вызов`. Polnaya dliteljnostj po obyortke — 733,770 s. Izolirovannyij RED togo zhe modulya podtverdil defekt: mock perekhvatyival `Path.read_text`, togda kak production guard posle `436909208424595f7151f6febca75f89018c0bcb` chitayet `Path.read_bytes`. Koordinator svyazal povtor s uzhe opublikovannyim ispravleniyem 0177 `a76969ce644feb82d720825bbc0e5e71cbd192b0` i perenosom fuma `33f6e4c9b1d4d295195bc7727216d6b3e80182d0`. Korenj prosmotrel iskhodnyij diff i perenyos rovno dve stroki mock, sokhraniv schyotchik 1 i povtornuyu proverku posle izmeneniya istochnika. Production guard sovpadayet s iskhodnyim HEAD; ostaljnyiye izmeneniya migracii 0177 ne perenosilisj. Adresnyij GREEN: vse 13 testov za 1,282 s. Nezavisimyij auditor podtverdil mekhanizm chteniyem, bez novyikh zapuskov. Eto povtor izvestnogo mekhanizma, a ne osnovaniye vyidumatj novyij tip ili ID sboya; prezhniye i tekusjhiye svideteljstva napravlenyi koordinatorom vladeljcu 0201. Oba polnyikh neuspekha i otdeljnyij RED sokhranenyi. Novoye neobkhodimoye izmeneniye testa prokhodit posleduyusjhij standartnyij dopusk; sborki i profili FUMA povtorno ne zapuskayutsya.

Posle vosstanovleniya konteksta korenj povtorno prochital pervichnyij JSONL i pozdniye upravlyayusjhiye soobsjheniya, sveril fakticheskiye HEAD `9c39c9b3fde83c4ce11ba101897c1298c68d436d`, polnyij ref i fizicheskij korenj s granicej etapa. Posleduyusjhiye soobsjheniya koordinacii sokhranenyi v zaprose; soderzhateljnyiye resheniya uchtenyi zdesj. Okno proverki ostayotsya u 0176 do zaversheniya finaljnoj proyekcii, posle chego yavnyij signal poluchat koordinator i 0177. Pozdnyaya kanonicheskaya klassifikaciya uzhe peredannoj diagnostiki ostayotsya otdeljnoj soglasovannoj fiksaciyej 0201.

Tretij polnyij zapusk proshyol postroyeniye proyekcii 6817 fajlov (199,879 s) i nezavisimuyu proverku (91,140 s), zatem otkazal na proverke putej; obsjhaya dliteljnostj vnutrennego smoke — 327,985 s. V doslovnoj citate pozdnego soobsjheniya koordinatora oboznacheniye pribliziteljnogo razmera JSONL s tiljdoj pered 296 MB raspoznano kak `error.home-expansion`. Korenj zaregistriroval drugoj absolyutnyij istoricheskij putj etoj perepiski, no propustil etu formu i ne provyol otdeljnyij skan vsego dopolnennogo zaprosa do dorogogo zapuska. Eto nablyudayemaya oshibka podgotovki tekusjhego vkhoda; ni istochnik, ni neuspekh ne skryityi. Dobavlena tochnaya tipizirovannaya deklaraciya istoricheskoj stroki s proveryayemyim fingerprint; skaner i tekst citatyi sokhranyayutsya. Posle zaversheniya vsekh soderzhateljnyikh pravok vyipolnyayetsya adresnyij skan vsego kanonicheskogo dereva, zatem neobkhodimyij standartnyij dopusk ispravlennogo vkhoda. Pozdneye utochneniye koordinatora o dvukh korotkikh diagnosticheskikh processakh 0177 ne menyayet vkhod postavki ili yeyo dopusk; ono sokhraneno v pervichnom JSONL, bez vmeshateljstva v proveryayemuyu granicu.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 04:36:35 MSK -->
<!-- content-sha256: sha256:7a62e7a733805f1ea0868ffa0ce231bc21527fd50ac61d1c520464ceed50c8b2 -->
<!-- FUM-MD-RECENCY:END -->
