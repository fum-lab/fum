# Otchyot 2026-09-09 18:43:02 MSK - Zavershitj priyomku arkhivnogo snimka

Podtverzhdenyi dopolneniye realjnogo arkhivnogo snimka, tochnyij povtor i vosstanovleniye otdeljnyim processom. Podmena odnogo bajta prinyatogo prefiksa i usecheniye otklonenyi bez izmeneniya kontejnera. FUM-STEP-0164 poluchayet vyipolnennyij status po svoyej ogranichennoj predmetnoj granice; zhivoye nablyudeniye FUMA i ostaljnyiye napravleniya ostayutsya otkryityimi.

## Proverennyij rezuljtat

Dva zakreplyonnyikh prefiksa odnoj razreshyonnoj zadachi soderzhat 17 968 i 18 419 zavershyonnyikh strok: 117 069 638 i 118 401 310 bajtov. Dopolneniye sostavlyayet 451 stroku / 1 331 672 bajta. Prezhniye 4 877 bajtov kontejnera sokhranilisj v nachale novogo kontejnera razmerom 9 839 bajtov. Povtor i vosstanovleniye dali te zhe bajtyi rezuljtata, povtor ne uvelichil kontejner.

Podmenyonnyij istochnik ostayotsya korrektnyim JSON toj zhe dlinyi: menyayetsya yedinstvennyij bajt vremeni pervoj stroki, UUID i predmetnyiye polya sokhranyayutsya. CLI otkazal s kodom 2 i pustyim stdout. Otdeljno podtverzhdyon otkaz usecheniyu. Posle oboikh otkazov kontejner pobajtno neizmenen, vosstanovleniye proshlo. Oba iskhodnyikh fajla i prezhnij kontejner v konce povtorno sverenyi s iskhodnyimi bajtami.

Nezavisimoye read-only-revjyu podtverdilo sootvetstviye utverzhdenij proverkam i otsutstviye syiryikh privatnyikh polej v publichnom otchyote. Po zamechaniyu o Python `assert` scenarij poluchil yavnyij otkaz pri otklyuchyonnyikh proverkakh; aktualjnaya priyomka povtorena cherez `python3 -I -S -B`. Pervyij rezuljtat sokhranyon, povtor ne skryit.

## Uskoreniye, neobkhodimoye dlya priyomki

Pervyij standartnyij progon zanyal 990,810 s i zavershilsya otkazom; shag primeneniya proyekcii — 974,511 s po vstroyennoj metke smoke. Zapuskal preobrazovatelj v Debug. Dlya uskoreniya dobavlenyi `--configuration release` k prezhnemu izolirovannomu `swift run`. Adresnaya regressiya snachala otkazala na otsutstvii konfiguracii, zatem proshla vmeste s prezhnimi proverkami neizmennosti zakreplyonnogo dereva.

Povtoryayemoye [sravneniye Debug/Release](materialyi/sravneniye-debug-release.json) postroilo oba produkta iz odinakovyikh Git-arkhivov primary i zavisimosti `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Tri chereduyusjhikhsya ispolneniya odnogo vkhoda dali odinakovyiye stroki UTF-8; medianyi ispolneniya — 5,771 i 0,149 s, otnosheniye okolo 38,6. Sborki izmerenyi otdeljno: 11,520 i 16,440 s. Eto ogranichennyij sravniteljnyij vkhod, a ne izmereniye uskoreniya vsego repozitoriya. [Izmeritelj](materialyi/sravnitj-debug-release.py) sokhranyayet vkhodnoj khyesh, iskhodnuyu reviziyu i khyeshi generatora i sobstvennogo koda.

Otdeljnyij otkaz vosstanovleniya vyizvan obyichnyim `Proyekcii/.DS_Store`; yesjhyo tri takikh fajla obnaruzhenyi v upravlyayemoj oblasti. Chetyire tochnyikh fajla sokhranenyi privatno i ubranyi posle proverki identichnosti; sostoyaniye tranzakcii, pokoleniya i kvitanciya ostavlenyi shtatnomu vosstanovleniyu. Nablyudyonnyij tekst maskiruyet pervonachaljnoye isklyucheniye, poetomu yego tochnaya pervichnaya prichina ne pripisyivayetsya ustanovlennomu faktu. [FUM-SBOJ-0042](../../Sboi/FUM-SBOJ-0042-sluzhebnyiye-fajlyi-Finder-blokiruyut-pereustanovku-proyekcii.md) i FUM-STEP-0169 sokhranyayut proiskhozhdeniye ispravleniya; okonchateljnaya mera opisana nizhe.

## Podderzhka ignoriruyemyikh metadannyikh macOS

Po utochneniyu poljzovatelya provereno susjhestvuyusjheye pravilo `.DS_Store` v pervoj stroke `.gitignore`; ono dejstvuyet na lyuboj glubine. Povtornoye poyavleniye fajlov pokazalo, chto ruchnaya ochistka ne reshayet problemu. Generator teperj isklyuchayet iz upravlyayemogo snimka toljko obyichnyij fajl s etim tochnyim imenem i polozhiteljnyim Git-ignore dlya fizicheskogo puti. V sokhranyayemyikh katalogakh metadannyiye ostayutsya na meste; pri udalenii prinadlezhasjhego generatoru kataloga oni atomarno perenosyatsya v unikaljnyij privatnyij katalog proverennogo Git-dir.

Podtverzhdenyi pervonachaljnaya ustanovka, povtor, smena pokoleniya, vosstanovleniye chetyiryokh faz preryivaniya i sokhrannostj kazhdogo sinteticheskogo bloka metadannyikh rovno v odnom meste. Simvolicheskiye ssyilki, katalogi, FIFO, inyiye neizvestnyiye imena, otslezhivayemyiye i yavno neignoriruyemyiye fajlyi sokhranyayut otkaz. Pervyij otricateljnyij scenarij bez lokaljnogo pravila vyiyavil vliyaniye ignore sredyi; yavnoye `!.DS_Store` zakrepilo trebuyemyij neignoriruyemyij vkhod, posle chego scenarij proshyol. Iskhodnyij neuspekh ne skryit.

[Profilj raspoznavaniya Finder](materialyi/profilj-metadannyikh-Finder.json) sravnil odinakovoye derevo iz 14 katalogov: medianyi snimka okolo 0,00088 s bez metadannyikh i 0,199 s s metadannyimi; sootvetstvenno 0 i 14 vyizovov Git-ignore. Khyeshi upravlyayemogo dereva sovpali. Vyizovyi ne vyipolnyayutsya dlya kazhdogo obyichnogo fajla. Kyesh izmenyayemyikh pravil ignore ne vvedyon; na tekusjhem chisle metadannyikh eta stoimostj mala otnositeljno preobrazovaniya. Profilj Debug/Release otnositsya k predshestvuyusjhej pravke konfiguracii, a profilj Finder soderzhit otdeljnyij khyesh proverennogo generatora.

Nezavisimoye revjyu potrebovalo sinkhronizirovatj samo soderzhimoye Finder do perenosa i imya privatnogo kataloga cherez yego roditelya. Otkaz fajlovogo `fsync` podtverzhdyon otdeljnyim RED/GREEN: perenos ne vyizyivayetsya, istochnik ostayotsya na meste. Otdeljnyij test sokhranyayet otkaz nesovpadayusjhemu fakticheskomu registru imeni. [Profilj posle revjyu fsync](materialyi/profilj-metadannyikh-Finder-posle-revjyu.json) sokhranil te zhe snimki, 0/14 vyizovov Git-ignore i medianyi okolo 0,00092/0,173 s; posleduyusjheye dobavleniye proverki fakticheskogo imeni pokryivayetsya adresnyim testom i obsjhej priyomkoj.

FUM-STEP-0169 vyipolnen po predmetnoj granice; FUM-SBOJ-0042 ustranyon proveryayemoj meroj, a ne povtornoj ochistkoj. Fizicheskoye otklyucheniye pitaniya ne proveryalosj; test poryadka sinkhronizacii ne vyidayotsya za takoye ispyitaniye. Privatnyiye arkhivyi Finder ne publikuyutsya, ikh udaleniye ne avtomatizirovano.

## Profilj vremeni vyipolneniya

| Stadiya                        | Dliteljnostj | Granicyi i sposob izmereniya                                             |
| ----------------------------- | ------------ | ---------------------------------------------------------------------- |
| Pervoye dopolneniye arkhiva       | 0,724 s      | Ot zapuska otdeljnogo CLI do yego zaversheniya, monotonnyij tajmer           |
| Pervyij replay dopolnennogo arkhiva   | 0,009 s      | Otdeljnyij CLI posle povtora; te zhe bajtyi rezuljtata                      |
| Soderzhateljnaya rabota          | ne izmereno  | Razbor granic, perenos dokumentov, obnovleniye sostoyaniya i revjyu          |
| Standartnyij smoke-check (dokumentacionnyij) | sm. nizhe     | Izmerennaya dliteljnostj — v stroke standartnoj priyomki tablicyi zapuskov  |

Granica profilya: tekusjhij zapros ot 2026-09-09 18:43:02 MSK; podrobnyiye stadii adresnoj priyomki nakhodyatsya v JSON-svideteljstvakh. Eti stadii vkhodyat vo vneshnij zapusk i povtorno ne pribavlyayutsya k summe pryamyikh proverok. Kalendarnaya dliteljnostj vsej rabotyi i budusjhij kommit ne ocenenyi zadnim chislom.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:e4de3136f0817db5b6c75da20ef65eb6cb184581a4a74d98b3a3dda2bad2ab90 -->

| Vyizov                                                                                               | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj — priyomka arkhiva] Proveritj dopolneniye realjnogo arkhiva i otkaz podmene                     | 2,689 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Podtverditj priyomku s izolirovannyim Python posle revjyu                    | 2,758 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Sobratj planovyij reyestr prinyatogo arkhivnogo shaga                          | 0,37 s       | uspeshno   |
| [Korenj — priyomka arkhiva] Proveritj svyaznostj ogranichennoj priyomki pered obsjhim progonom             | 37,13 s      | neuspeshno |
| [Korenj — priyomka arkhiva] Proveritj publikacionnyiye puti arkhivnoj priyomki                            | 18,084 s     | uspeshno   |
| [Korenj — priyomka arkhiva] Sobratj reyestr s otdeljnyim shagom predotvrasjheniya drejfa otchyota             | 0,367 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Povtoritj svyaznostj posle vosstanovleniya mashinnogo zagolovka              | 37,001 s     | uspeshno   |
| [Korenj — priyomka arkhiva] Proveritj probeljnuyu celostnostj itogovogo izmeneniya                      | 0,052 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Standartnaya priyomka arkhivnogo snimka                                      | 990,81 s     | neuspeshno |
| [Korenj — priyomka arkhiva] RED: preobrazovatelj trebuyet Release                                      | 0,501 s      | neuspeshno |
| [Korenj — priyomka arkhiva] GREEN: Release i izolyaciya preobrazovatelya                                 | 0,508 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Sravnitj Debug i Release na odinakovom vkhode primary                      | 49,466 s     | uspeshno   |
| [Korenj — priyomka arkhiva] Sobratj reyestr s predotvrasjheniyem pozdnego otkaza proyekcii                 | 0,348 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Proveritj svyaznostj posle Release i registracii otkaza Finder             | 38,373 s     | neuspeshno |
| [Korenj — priyomka arkhiva] Sobratj okonchateljnyij reyestr vosstanovlennoj priyomki                      | 0,35 s       | uspeshno   |
| [Korenj — priyomka arkhiva] Standartnaya priyomka arkhiva i Release posle vosstanovleniya                 | 16,701 s     | neuspeshno |
| [Korenj — priyomka arkhiva] Sokhranitj povtor rannego otkaza v planovom reyestre                        | 0,38 s       | uspeshno   |
| [Korenj — priyomka arkhiva] RED: Git-ignoriruyemyiye metadannyiye Finder ne blokiruyut proyekciyu             | 0,329 s      | neuspeshno |
| [Korenj — priyomka arkhiva] GREEN: metadannyiye Finder sokhranyayutsya vne udalyayemogo pokoleniya             | 5,063 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Proveritj uzkuyu granicu isklyucheniya Finder                                 | 3,66 s       | neuspeshno |
| [Korenj — priyomka arkhiva] Podtverditj otkaz pri yavnom isklyuchenii iz Git-ignore                      | 1,396 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Izmeritj stoimostj raspoznavaniya metadannyikh Finder                        | 2,003 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Proveritj sokhrannostj Finder pri preryivaniyakh i poryadok dolgovechnoj zapisi | 10,963 s     | uspeshno   |
| [Korenj — priyomka arkhiva] Sobratj planovyij reyestr prinyatoj obrabotki Finder                         | 0,335 s      | uspeshno   |
| [Korenj — priyomka arkhiva] RED: otkaz fsync fajla Finder zapresjhayet perenos                           | 0,312 s      | neuspeshno |
| [Korenj — priyomka arkhiva] GREEN: fsync fajla i imeni arkhiva do perenosa Finder                      | 0,39 s       | uspeshno   |
| [Korenj — priyomka arkhiva] Zakrepitj profilj okonchateljnogo generatora posle revjyu fsync             | 1,723 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Proveritj fakticheskij registr metadannyikh pered perenosom                  | 0,274 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Sinkhronizirovatj reyestr s rezuljtatami revjyu sokhraneniya Finder            | 0,348 s      | uspeshno   |
| [Korenj — priyomka arkhiva] Standartnaya priyomka arkhivnogo snimka, Release i metadannyikh Finder         | 649,248 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1871,932 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- [Pervyij scenarij priyomki](materialyi/priyomka-prodolzheniya.json) i [aktualjnyij izolirovannyij zapusk](materialyi/priyomka-izolirovannogo-zapuska.json) podtverzhdayut ukazannyiye granicyi.
- [Istoricheskij pervyij import i povtor](materialyi/istoricheskiye-svideteljstva/) sokhranenyi tochnyimi bajtami s SHA; oni proiskhodyat iz prezhnego nezakommichennogo sostoyaniya i ne pripisyivayutsya kommitu `ef0b528c`.
- [Proiskhozhdeniye dokumentov i svideteljstv](materialyi/proiskhozhdeniye-priyomki.json) sokhranyayet iskhodnyiye puti i khyeshi. Iskhodnyiye dokumentyi otnosyatsya k FUM-kommitu `81e2e2c6e830c0f742fffa719c38facde39e41a1`; v primary obnovlenyi sostoyaniye i ssyilki. Docherniye zhurnalyi i v4-instrumentyi ne perenosilisj kak dejstvuyusjhij kontur.
- Obsjhaya proverka okhvatyivayet vyibrannoye izmeneniye primary. Ona ne yavlyayetsya povtornoj attestaciyej vsekh komponentov prezhnej vetki.

## Resheniya i ogranicheniya

Posle zakryitiya etoj mashinnoj granicyi finaljnaya proyekciya proshla za 201,36 s, nezavisimaya proverka — za 100,22 s. Zatem proverka podgotovlennogo indeksa obnaruzhila lishnij LF v konce izmeritelya. Eti proverki zamyikaniya ne vkhodyat v summu staryikh pryamyikh zapuskov. [Novyij cikl po komande o macOS](../2026-09-09_20-29-51_MSK_zavershitj-priyomku-ignorirovaniya-fajlov-macos/otchyot.md) sokhranyayet otkaz i itogovuyu priyomku togo zhe obsjhego izmeneniya; prezhniye 30 zapisej, snimok i upravlyayemyij blok ostayutsya pobajtno prezhnimi. Sostoyaniye «gotov» vnutri starogo bloka otnositsya k zakryitomu otpechatku i ne yavlyayetsya dopuskom izmenyonnogo snimka k kommitu.

V izmeritele udalyon toljko odin zavershayusjhij LF: 5971 → 5970 bajtov. Istoricheskij profilj soderzhit SHA iskhodnoj izmerennoj versii `ac33621f51da6511c6dd13aee33c9761f60a43c5882a8dcfba79c1feecdaf7cf`; ispravlennyij fajl imeyet SHA `11a354490a7b22a04f8a29da5607f9b491037e20c2cdd6cf75e7bfb763faeef1`. Prezhniye bajtyi tochno vosstanavlivayutsya dobavleniyem odnogo LF v konec ispravlennogo fajla; AST sovpal. Istoricheskij JSON ne izmenyon i profilj zanovo ne zapuskalsya radi formatirovaniya.

Povtornaya popyitka № 16 otkazala do preobrazovaniya iz-za vnovj poyavivshegosya fajla Finder. Predvariteljnaya ochistka otkazala, no korenj oshibochno zapustil zavisimuyu proverku. Povtornaya ochistka dokazannyikh obyichnyikh fajlov zavershena do sleduyusjhego progona; metadannyiye vremeni chteniya ne ispoljzuyutsya kak identichnostj. Etot povtor sokhranyon kak FUM-SBOJ-0042/PROYAVLENIYE-0002.

Adresnaya svyaznostj № 14 otkazala posle utochneniya stroki profilya vo vremya vyipolneniya proverki. [FUM-SBOJ-0043](../../Sboi/FUM-SBOJ-0043-izmeneniye-proveryayemogo-snimka-do-zaversheniya-proverki.md) sokhranyayet etot mekhanizm. Posle zaversheniya processa tekst i recency obnovlenyi; sleduyusjhij obsjhij progon vyipolnyayetsya na podgotovlennom neizmenyayemom soderzhateljnom snimke.

Adresnaya svyaznostj otkazala iz-za zamenyi tochnogo defisa v H1 tipografskim tire. Zagolovok vosstanovlen; sam otkaz sokhranyon v mashinnom zhurnale. [FUM-SBOJ-0041](../../Sboi/FUM-SBOJ-0041-drejf-mashinnogo-zagolovka-otchyota.md) ostayotsya aktivnyim s otdeljnyim shagom sistemnogo predotvrasjheniya; lokaljnoye ispravleniye ne vyidano za ustraneniye mekhanizma.

Obsjhij chitatelj ocenyon po Swift API statistiki kommita `85dccce282821a890e5e65539b4f22b895b52887`. On uzhe vyibirayet `СобытиеВызова`, poetomu obyyedinyatj yego s arkhivnyim razborom sejchas oznachalo byi smeshatj predmetnuyu semantiku. Budusjheye obsjheye osnovaniye mozhet soderzhatj toljko chteniye bajtov, LF-granicyi i SHA posle vyideleniya ustojchivogo kontrakta.

Rezuljtat ogranichen arkhivnyim sostoyaniyem prefiksa. Ne proveryalisj zhivoj process, UI, otklyucheniye pitaniya ili vrazhdebnaya soglasovannaya perepisj vsekh fajlov. Neizmennostj zdesj oznachayet ravenstvo bajtov, ne polnuyu neizmennostj fajlovyikh metadannyikh. Svyazj binarnika s iskhodnyim kommitom opirayetsya na prezhnyuyu postavku i [manifest iskhodnikov Swift](materialyi/manifest-iskhodnikov-Swift.json); programma zanovo v primary ne sobiralasj i yeyo iskhodniki tuda ne perenosilisj.

Scenarij sokhranyon kak povtoryayemaya priyomochnaya procedura s yavnyimi vkhodami, a ne kak vklyuchyonnyij avtomaticheskij nablyudatelj. Podklyucheniye Stop, ispolnitelj indeksnyikh snimkov, sborsjhik rabochego konteksta i detektoryi ostayutsya otdeljnyimi otkryityimi rabotami. Povtornoye ispoljzovaniye predyidusjhego finaljnogo otveta kak dokazateljstva ikh zaversheniya nedopustimo.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [arkhivnyij snimok FUMA](../../Dokumentaciya/arkhivnyij-snimok-zadachi-FUMA.md)
- [prinyataya kartochka FUM-STEP-0164](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0164-prinyatj-formyi-runtime-i-realjnyij-arkhiv.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 20:34:49 MSK -->
<!-- content-sha256: sha256:ea7ed6bb120d73b45b01c87fb49f2cf93af90f0896e72f5c00ac026e014ae620 -->
<!-- FUM-MD-RECENCY:END -->
