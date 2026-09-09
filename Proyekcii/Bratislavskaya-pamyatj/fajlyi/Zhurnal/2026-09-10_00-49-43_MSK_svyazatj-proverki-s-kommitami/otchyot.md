# Otchyot 2026-09-10 00:49:43 MSK - Svyazatj proverki s kommitami

Sozdan ogranichennyij adapter svyazi uzhe proverennyikh v3-svideteljstv s kommitom. Na realjnom prinyatom kommite `11d1b5fd4c912ade510a21c65dd5d515243a084d` vosstanovlen tochnyij otpechatok `sha256:6bc5cfc2b9dae4759c4ccc77a5ff27f82efadcd81a6c1e3f0f83022c46f488a6`; prezhnij zakryityij otchyot otdeljno proshyol stroguyu proverku bez izmeneniya yego bajtov.

Vosstanovleno proiskhozhdeniye semi raneye soglasovannyikh napravlenij iz realjnyikh soobsjhenij JSONL. Karta proiskhozhdeniya ne yavlyayetsya polnyim reyestrom ili priyomkoj etikh obyazateljstv. Blizhajshaya postavka posle dannogo kommita — [proverka ostatka obyazateljstv](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0172-proveryatj-ostatok-obyazateljstv-zadachi.md).

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Analiz, realizaciya i nezavisimoye revjyu | ne izmereno | Etap nachat 2026-09-10 00:49:43 MSK; analiz perekryivalsya s read-only-revjyu |
| Adresnyiye proverki i profilj | po mashinnyim zapisyam nizhe | Obyortka izmeryayet kazhdyij pryamoj process otdeljno |
| Standartnyij dokumentacionnyij smoke-check | po poslednej polnoj zapisi nizhe | Poslednij okhvachennyij zapusk do zakryitiya otchyota; prervannaya popyitka sokhranyayetsya otdeljno |
| Zamyikaniye proyekcii i lokaljnyij kommit | vne mashinnoj granicyi | Posle zakryitiya dopuskayutsya odno primeneniye i odna nezavisimaya proverka; rezuljtat kommita proveryayetsya chteniyem Git |

Granica profilya: s nachala etapa 2026-09-10 00:49:43 MSK do poslednego okhvachennogo standartnogo smoke-check. Ozhidaniya FIFO i peredachi novoj zadache net; okonchateljnoye zamyikaniye nakhoditsya vne mashinnoj granicyi. Dliteljnosti perekryivayusjhikhsya dejstvij ne skladyivayutsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:fcd09f8401eda41239dbdc3d1f427600cbd60d5239b8f70dd56ef9e2d0694332 -->

| Vyizov                                                                                       | Dliteljnostj | Rezuljtat         |
| ------------------------------------------------------------------------------------------- | ------------ | ----------------- |
| [Kornevoj pisatelj] RED: svyazj otpechatka s realjnyim kommitom                                | 4,151 s      | neuspeshno         |
| [Kornevoj pisatelj] GREEN: svyazj otpechatka s realjnyim kommitom                              | 8,415 s      | neuspeshno         |
| [Kornevoj pisatelj] GREEN: adapter i nezavisimaya ochistka flagov fiksturyi                    | 8,533 s      | uspeshno           |
| [Kornevoj pisatelj] RED: obyyekt tega ne podmenyayet identichnostj kommita                      | 0,65 s       | neuspeshno         |
| [Kornevoj pisatelj] GREEN: tochnyij tip obyyekta kommita                                       | 0,599 s      | uspeshno           |
| [Kornevoj pisatelj] RED: vliyaniye sredyi pathspec i ispolnyayemyiye filjtryi                       | 1,368 s      | neuspeshno         |
| [Kornevoj pisatelj] GREEN: izolyaciya sredyi i zapret ispolnyayemyikh filjtrov                     | 1,174 s      | uspeshno           |
| [Kornevoj pisatelj] RED: zakryitaya granica obkhoda podmodulej                                 | 0,609 s      | neuspeshno         |
| [Kornevoj pisatelj] RED: polnyij OID SHA256 i granica podmodulej                             | 1,72 s       | neuspeshno         |
| [Kornevoj pisatelj] GREEN: tochnaya identichnostj i zasjhisjhyonnoye chteniye adaptera                 | 10,151 s     | neuspeshno         |
| [Kornevoj pisatelj] RED: podkatalog ne podmenyayet korenj proverki                            | 0,726 s      | neuspeshno         |
| [Kornevoj pisatelj] GREEN: polnaya granica repozitoriya i nezavisimyiye fiksturyi                | 11,783 s     | uspeshno           |
| [Kornevoj pisatelj] Profilj adaptera do obyyedineniya chtenij indeksa                          | 7,188 s      | uspeshno           |
| [Kornevoj pisatelj] GREEN: sovmestnoye chteniye stadij i flagov indeksa                        | 13,589 s     | uspeshno           |
| [Kornevoj pisatelj] Profilj adaptera posle obyyedineniya chtenij indeksa                       | 6,139 s      | uspeshno           |
| [Kornevoj pisatelj] Proveritj svyazj prinyatogo v3 otchyota s kommitom 11d1b5fd                 | 0,309 s      | uspeshno           |
| [Kornevoj pisatelj] Proveritj nerazreshyonnyiye stadii i smenu vershinyi mezhdu chteniyami           | 1,413 s      | uspeshno           |
| [Kornevoj pisatelj] Sobratj planovyij reyestr posle vyideleniya proverki obyazateljstv           | 0,357 s      | uspeshno           |
| [Kornevoj pisatelj] Obnovitj svezhestj Markdown pered priyomkoj adaptera                      | 0,888 s      | uspeshno           |
| [Kornevoj pisatelj] Proveritj svyaznostj etapa adaptacii svideteljstv                        | 37,832 s     | neuspeshno         |
| [Kornevoj pisatelj] Proveritj otsutstviye novyikh latinskikh obyyavlenij v adaptere i materialakh | 25,327 s     | neuspeshno         |
| [Kornevoj pisatelj] Diagnostirovatj obyyavleniya novyikh iskhodnikov adaptera                    | 0,073 s      | uspeshno           |
| [Kornevoj pisatelj] Sopostavitj polnyij inventarj s vkhodom etapa                             | 24,901 s     | uspeshno           |
| [Kornevoj pisatelj] Sobratj reyestr s otdeljnyim razborom drejfa obyyavlenij                   | 0,358 s      | uspeshno           |
| [Kornevoj pisatelj] Obnovitj Markdown posle fiksacii diagnosticheskogo ostatka               | 0,883 s      | uspeshno           |
| [Kornevoj pisatelj] Proveritj exact diff rabochego dereva i indeksa adaptera                 | 0,089 s      | uspeshno           |
| [Kornevoj pisatelj] Podtverditj svyaznostj podgotovlennogo etapa adaptera                    | 37,479 s     | uspeshno           |
| [Kornevoj pisatelj] Finaljnaya standartnaya priyomka adaptera v3 i istochnikov obyazateljstv     | 287,142 s    | prervano — SIGINT |
| [Kornevoj pisatelj] RED: razlichitj iskhodnuyu reviziyu i fakticheskij snimok reyestra            | 0,082 s      | neuspeshno         |
| [Kornevoj pisatelj] GREEN: arkhiv i semj citat sovpadayut s fakticheskim snimkom reyestra       | 0,087 s      | uspeshno           |
| [Kornevoj pisatelj] Obnovitj Markdown posle utochneniya istoricheskogo proiskhozhdeniya           | 0,89 s       | uspeshno           |
| [Kornevoj pisatelj] Proveritj indeks posle ispravleniya proiskhozhdeniya                        | 0,169 s      | uspeshno           |
| [Kornevoj pisatelj] Finaljnaya standartnaya priyomka posle ispravleniya proiskhozhdeniya           | 334,159 s    | neuspeshno         |
| [Kornevoj pisatelj] Proveritj perenosimyiye puti adaptera i fikstur                           | 17,926 s     | uspeshno           |
| [Kornevoj pisatelj] Proveritj regressii granic putej posle perenosimogo ispravleniya         | 2,373 s      | uspeshno           |
| [Kornevoj pisatelj] Povtoritj svyazj prinyatogo kommita s perenosimyim putyom zaprosa           | 0,334 s      | uspeshno           |
| [Kornevoj pisatelj] Obnovitj Markdown posle perenosimogo ispravleniya putej                  | 0,935 s      | uspeshno           |
| [Kornevoj pisatelj] Proveritj exact diff pered povtornoj polnoj priyomkoj                    | 0,172 s      | uspeshno           |
| [Kornevoj pisatelj] Finaljnaya priyomka adaptera posle ispravleniya perenosimyikh putej          | 544,113 s    | uspeshno           |

Obsjheye vremya pryamyikh zapuskov proverok: 1395,086 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Vtoroj standartnyij progon zavershilsya kodom 1 na proverke mashinno-lokaljnyikh putej posle uspeshnogo primeneniya proyekcii (201,177 s) i nezavisimoj proverki manifesta (99,171 s). Dve sklejki otnositeljnogo puti zamenenyi na `Path`, otricateljnaya fikstura poluchayet absolyutnyij putj iz sobstvennogo vremennogo kataloga. Politika razreshenij ne rasshiryalasj; adresnaya proverka putej proshla. Povtornyij polnyij progon vyipolnyayetsya na ispravlennom vkhode.

Pervyij standartnyij progon prervan po SIGINT cherez obyortku (kod 130) do zaversheniya nezavisimoj proverki proyekcii: revjyu vyiyavilo smesheniye genezisa starogo reyestra i kommita yego snimka. Do preryivaniya primeneniye proyekcii zanyalo 200,787 s dlya 5179 iskhodnyikh fajlov. V karte i zaprose teperj otdeljno ukazanyi genezis `008f27dcc34d6991b437109ddfc8166f25be9e28` i fakticheskij snimok vsekh semi opredelenij `11d71fdd5ea8b958d8e3fc9aa028b8720024b853`; bajtyi snimka sokhranenyi. Kommit `670a1fda352b34668d87000602e76e246aefa22f` soderzhit osnovaniya dvukh pozdnikh komand, no toljko pyatj opredelenij reyestra. [Avtomaticheskaya proverka proiskhozhdeniya](materialyi/proveritj-proiskhozhdeniye.py) sravnivayet kartu s dejstviteljnyim Git-obyyektom. Povtornyij final vyipolnyayetsya na ispravlennom vkhode.

- RED/GREEN podtverzhdayut bukvaljnoye sovpadeniye realjnogo SHA obyortki, tekst, binarnyiye dannyiye, executable-bit, istoricheskuyu granicu i otlichayusjhiyesya prefiksyi Git.
- Otvergayutsya podmena kommita tegom, sokrasjhyonnyij SHA-256, podkatalog vmesto kornya, rasshireniye isklyuchenij cherez sredu, nerazreshyonnyiye stadii i skryivayusjhiye izmeneniya flagi indeksa. Otdeljno provereno povtornoye chteniye vershinyi.
- Pozdniye izmeneniya, nepolnaya iskhodnaya indeksaciya i nesovpadeniye dvukh svideteljstv ne prevrasjhayutsya v podtverzhdeniye. Tochnaya proyekciya isklyuchayetsya, pokhozhiye kanonicheskiye puti uchityivayutsya.
- Pervaya oshibka GREEN otnosilasj k sbrosu dvukh raznyikh flagov odnoj komandoj v testovoj fiksture; sbros razdelyon. Globaljnyiye filjtryi khosta zatem vyiyavili otsutstviye izolyacii fikstur; testyi poluchili yavnyiye otdeljnyiye granicyi konfiguracii. Vse popyitki sokhranenyi v mashinnom zhurnale.
- Realjnyij prinyatyij otchyot i kommit proverenyi [vosproizvodimyim scenariyem](materialyi/proveritj-prinyatyij-kommit.py); rezuljtat sokhranyon [otdeljno](materialyi/proverka-kommita.json).

Nezavisimoye staticheskoye revjyu itogovyikh adaptera, testov i kontrakta ne obnaruzhilo ostavshikhsya blokerov. Proverka svyaznosti pervonachaljno ostanovilasj na yesjhyo ne sformirovannom upravlyayemom bloke otchyota; vyipolnen shtatnyij `предпросмотр`, zapisi zapuskov ne perepisyivalisj.

Dopolniteljnyij polnyij snimok obyyavlenij ne sovpadayet: 43105 protiv 43091, iz nikh odna novaya zapisj — dopustimyij vneshnij `unittest.TestCase.setUp`; bez neyo ostayotsya 43104. V drugikh novyikh iskhodnikakh latinskikh obyyavlenij net. Susjhestvuyusjhij snimok ne obnovlyalsya bez razbora, nablyudeniye sokhraneno v [FUM-SBOJ-0045](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md), issledovaniye — v FUM-STEP-0173. Standartnyij dokumentacionnyij profilj ne vklyuchayet etu globaljnuyu istoricheskuyu proverku; yego uspekh ne obyyavlyayetsya zakryitiyem najdennogo raskhozhdeniya.

## Resheniya i ogranicheniya

[Profilj do](materialyi/profilj-do.json) i [posle](materialyi/profilj-posle.json) soderzhat po semj povtorov dlya 4 i 500 binarnyikh fajlov. Istoricheskij rezhim delayet 6 vyizovov Git; neposredstvennyij sokrasjhyon s 21 do 19 obyyedineniyem chteniya stadij i flagov. Medianyi neposredstvennogo rezhima: 361,841 → 226,298 ms dlya malogo vkhoda i 363,961 → 355,373 ms dlya uvelichennogo. Posledovateljnyiye serii podverzhenyi vneshnej nagruzke: dokazannoye strukturnoye uluchsheniye — dva isklyuchyonnyikh processa, a ne garantirovannyij procent uskoreniya. Istoricheskij rezhim ne menyalsya: 86,831 → 79,135 ms i 99,854 → 104,273 ms pokazyivayut variaciyu izmerenij.

Neposredstvennyij rezhim pervoj versii zakryito otkazyivayet pri gitlink i nastroyennyikh ispolnyayemyikh filjtrakh do obkhoda rabochego dereva. Istoricheskij rezhim podderzhivayet gitlink cherez bukvaljnyij diff. Adapter ne udostoveryayet sam otchyot ili rezuljtat obyazateljstva i ne perekhvatyivayet finaljnyij otvet Codex. Nesovpadeniye istoricheskogo kandidata oznachayet «ne vosstanovlen», a ne ustanovlennuyu podmenu. [Polnyij kontrakt](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/svyazj-s-kommitom.md) opisyivayet kodyi iskhodov i granicyi.

## Istochniki

- [Iskhodnyiye komandyi i soderzhateljnyiye otvetyi](zapros.md).
- [Predyidusjhij prinyatyij etap](../2026-09-09_21-31-19_MSK_prodolzhatj-rabotu-posle-kommita/otchyot.md).
- [Karta proiskhozhdeniya obyazateljstv](materialyi/proiskhozhdeniye-obyazateljstv.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 01:44:23 MSK -->
<!-- content-sha256: sha256:d11c5afb3d214eaabffca61659e66770cb881e78d1ccd2a9c8c045c8d1f53ec3 -->
<!-- FUM-MD-RECENCY:END -->
