# Prototipyi

Papka `Прототипы/` khranit rabochiye probyi otdeljnyikh chastej reshenij dlya [korobochnoj realizacii FUM](../Glossarij/korobochnaya-realizaciya-FUM.md). Zdesj mozhno proveryatj interfejsnyiye, algoritmicheskiye, arkhitekturnyiye, servisnyiye i integracionnyiye idei do togo, kak oni stanut ustojchivoj [proizvodnoj dokumentaciyej](../Glossarij/proizvodnaya-dokumentaciya.md), lokaljnoj [avtomatizaciyej FUM](../Glossarij/avtomatizaciya-FUM.md) ili chastjyu planovoj postavki.

Prototipyi ne zamenyayut trebovaniya i itogovuyu dokumentaciyu. Ikh zadacha - datj bezopasnoye mesto dlya malyikh proveryayemyikh shagov: sobratj maket, napisatj eksperimentaljnyij skript, opisatj kontrakt, proveritj fiksturu, sravnitj variantyi i sokhranitj vyivodyi tak, chtobyi potom mozhno byilo prinyatj, snyatj ili perenesti rezuljtat v osnovnoj kontur [pamyati FUM](../Glossarij/pamyatj-FUM.md).

Novyiye rabochiye prototipyi po umolchaniyu pishutsya na Swift. Eto delayet prototipnyij sloj blizhe k budusjhej korobochnoj inzhenernoj forme i pomogayet zaraneye proveryatj lokaljnuyu sborku, tipyi, paketyi, testyi i ogranicheniya runtime v odnom osnovnom steke. Yesli otdeljnaya proverka trebuyet drugogo yazyika, formata ili vneshnego runtime, eto dopustimo toljko kak yavno opisannoye isklyucheniye v pasporte prototipa.

## Dejstvuyusjhiye prototipyi

- [Vosproizvodimoye popolneniye pamyati](vosproizvodimoye-popolneniye-pamyati/README.md) - bezokonnyij Swift-kontur korobochnogo prototipa: versionirovannyiye sobyitiya prokhodyat ogranichennyiye `remember` i `compose`, sokhranyayutsya polnyimi kanonicheskimi telami v vosstanavlivayemom pokolenii, samodostatochno pereispolnyayutsya vmeste s proyekciyej i proiskhozhdeniyem, a vyidelennoye skhemonezavisimoye yadro publikacii `CURRENT` mezhdu sotrudnichayusjhimi processami predostavlyayet linearizuyemyij compare-and-swap i proverennyij na vosjmi tochkakh process-crash-protokol; power-loss durability ne zayavlena.
- [Pamyatj strukturiruyusjhikh operatorov](pamyatj-strukturiruyusjhikh-operatorov/README.md) - proverochnyij Swift-prototip ogranichennogo kontekstnogo lesa, veroyatnostnoj reshyotki, zaraneye sokhranyonnyikh i zapisannyikh LLM-predlozhenij operatorov, gain-metrik, obratnogo porozhdeniya, diagnosticheskikh ostatkov, pruning, proiskhozhdeniya i yestestvenno-yazyikovoj sinkhronizacii vneshnikh i vnutrennikh uzlov.
- [Kompilyaciya chislennyikh avtomatizacij v tenzornyij graf](kompilyaciya-chislennyikh-avtomatizacij-v-tenzornyij-graf/README.md) - proverochnyij Swift-prototip chistogo `mul_add` nad staticheskimi `tensor<4xf32>`: strogij deklarativnyij JSON-DSL kompiliruyetsya v otdeljnyij tipizirovannyij SSA-graf, etalonnyij i grafovyij CPU-puti sveryayutsya, a determinirovannyij StableHLO/MLIR-kandidat sokhranyayetsya vmeste s benchmark, trassoj sredyi i yavnyim fallback pri nenastroyennom celevom provajdere.
- [Agentnoye chteniye setevoj sredyi](agentnoye-chteniye-setevoj-sredyi/README.md) - proverochnyij Swift-prototip neizmenyayemoj kartyi arifmeticheskikh vyichislitelej, neskoljkikh interpretatorov s nasleduyemyimi vesami perekhodov, ogranichennoj mutacii, polnogo marshruta, byudzheta vnutrennej populyacii i kachestvennogo barjyera pered resursnoj poleznostjyu.
- [Iyerarkhiya funkcij i dannyikh](iyerarkhiya-funkcij-i-dannyikh/README.md) - proverochnyij Swift-prototip chistogo celochislennogo preobrazovaniya, trassyi oshibki, stoimosti i poljzyi, chetyiryokh atomarnyikh kandidatov i determinirovannoj meta-funkcii, kotoraya zakreplyayet proshedsheye nezavisimuyu proverku izmeneniye libo vozvrasjhayet tochnyij iskhodnyij snimok.
- [Tenevoj redaktor prodolzhenij](tenevoj-redaktor-prodolzhenij/README.md) - dejstvuyusjhij issledovateljskij Swift-prototip: odin tekstovyij fajl, zamorozhennyij prefiks, skryitoye prodolzheniye lokaljnoj LLM, fakticheskoye prodolzheniye cheloveka i odinakovyiye ogranichennyiye suffiksno-kontekstnyiye strukturyi dlya sravneniya. Eto rannij vertikaljnyij srez cheloveko-modeljnogo vzaimodejstviya, a ne nachaljnoye korobochnoye yadro, gotovaya korobochnaya FUM, yedinoye prilozheniye ili agentskij cikl.
- [Fizicheskiye sostoyaniya klavish](fizicheskiye-sostoyaniya-klavish/README.md) - sravniteljnyij Swift-prototip klaviaturnyikh istochnikov `IOHIDManager`, `GCKeyboard`, `CGEventTap` i `NSEvent`: perenosimoye yadro prinimayet toljko yavnyiye izmeneniya fizicheskogo sostoyaniya, a SwiftUI-provodnik po yavnomu soglasiyu vedyot cheloveka cherez plan fizicheskikh izmerenij i sokhranyayet lokaljnyij Git-ignoriruyemyij nabor dannyikh v rabochej kopii.
- [Chistyij modeljnyij shag](chistyij-modeljnyij-shag/README.md) - proverochnyij Swift-prototip strogogo JSON-kontrakta, determinirovannoj zaglushki i lokaljnogo LM Studio REST v0-profilya: disclosure-preflight i process-memory ledger rezerviruyut shestimernyij byudzhet do inference, `max_tokens` ispolnyayet vyikhodnoj predel, odna sinteticheskaya fikstura imeyet exact-tokenizacionnuyu attestaciyu, a trusted usage ostayotsya otdeljno ot inertnogo modeljnogo teksta.
- [Zhivoj odnoagentnyij epizod](zhivoj-odnoagentnyij-epizod/README.md) - Swift-kontrakt otdeljnoj live-skhemyi, versionnogo pasporta, shestimernogo byudzheta i dvukh nezavisimyikh osej sostoyaniya, dopolnennyij podtverzhdyonnyimi pokoleniyami, `CURRENT`-only recovery, bezokonnyimi JSON-komandami, izolirovannyim Git-kandidatom i otdeljnoj headless-priyomkoj. Odin uzkij model-to-action-scenarij podtverzhdyon avtonomnyim recorded-harness i otdeljnyim opt-in progonom s uzhe dostupnyim LM Studio; eto ne polnyij, universaljnyij, raspredelyonnyij ili produktovyij FUM.
- [Proveryayemyij mnogoagentnyij kontur](proveryayemyij-mnogoagentnyij-kontur/README.md) - bezokonnyij Swift-prototip strogogo rabochego paketa, simvolicheskogo pasporta i vosstanavlivayemoj obsjhej pamyati epizoda. Pamyatj pereispoljzuyet kanonicheskij profilj, `CURRENT`, mezhprocessnyij CAS i avarijnuyu granicu odnoagentnogo khranilisjha; skhema zhurnala i reducer versii 4 dobavlyayut otdeljnyiye proverki, neizmenyayemyiye raznoglasiya, dokazateljnyij vyibor, konechnyiye byudzhetyi s zasjhisjhyonnyim rezervom, neblokiruyusjheye ozhidaniye podtverzhdeniya i odin tipizirovannyij terminaljnyij iskhod. Yedinyij lokaljnyij rezhim `acceptance all` vyidayot determinirovannyij JSON-otchyot dlya polozhiteljnogo `goal_met`, lozhnogo konsensusa, ischerpaniya byudzheta i ozhidaniya podtverzhdeniya; eto priyomka zapisannyikh fikstur, a ne dokazateljstvo zhivoj mnogomodeljnoj rabotyi, istinyi ili semanticheskoj nezavisimosti.

## Panelj i prostoj zapusk

Iz kornya repozitoriya obsjhaya terminaljnaya panelj zapuskayetsya bez pereklyucheniya raskladki:

```bash
./prototipyi.sh
```

Panelj avtomaticheski nakhodit vse tochki vkhoda `Прототипы/*/запустить.sh`, pokazyivayet pronumerovannyij spisok i prinimayet cifru dlya zapuska libo `q` dlya vyikhoda. Poetomu novyij ustojchivyij prototip poyavlyayetsya v paneli bez ruchnogo izmeneniya kornevogo skripta.

Dlya polucheniya spiska bez zapuska i pryamogo vyibora po nomeru dostupnyi:

```bash
./prototipyi.sh --list
./prototipyi.sh <номер> [аргументы-прототипа...]
```

U kazhdogo dejstvuyusjhego i budusjhego ustojchivogo prototipa yestj odinakovo nazvannaya ispolnyayemaya tochka vkhoda `запустить.sh`. Iz kornya repozitoriya dejstvuyusjhiye prototipyi zapuskayutsya tak:

```bash
./Прототипы/воспроизводимое-пополнение-памяти/запустить.sh
./Прототипы/память-структурирующих-операторов/запустить.sh
./Прототипы/компиляция-численных-автоматизаций-в-тензорный-граф/запустить.sh
./Прототипы/агентное-чтение-сетевой-среды/запустить.sh
./Прототипы/иерархия-функций-и-данных/запустить.sh
./Прототипы/теневой-редактор-продолжений/запустить.sh
./Прототипы/физические-состояния-клавиш/запустить.sh
./Прототипы/чистый-модельный-шаг/запустить.sh
./Прототипы/живой-одноагентный-эпизод/запустить.sh
./Прототипы/проверяемый-многоагентный-контур/запустить.sh
```

Polnaya avtonomnaya priyomka proveryayemogo mnogoagentnogo kontura zapuskayetsya otdeljno odnoj komandoj:

```bash
./Прототипы/проверяемый-многоагентный-контур/запустить.sh acceptance all
```

Skriptyi rabotayut i iz drugogo tekusjhego kataloga, potomu chto sami opredelyayut putj k svoyemu prototipu. Dopolniteljnyiye argumentyi peredayutsya konkretnomu prilozheniyu ili probniku; tochnyiye bezopasnyiye scenarii opisanyi v pasportakh.

Vosproizvodimoye popolneniye pamyati, pamyatj strukturiruyusjhikh operatorov, kompilyaciya chislennyikh avtomatizacij, agentnoye chteniye setevoj sredyi, iyerarkhiya funkcij i dannyikh, chistyij modeljnyij shag, zhivoj odnoagentnyij epizod i proveryayemyij mnogoagentnyij kontur bez argumentov vyipolnyayut vstroyennyiye determinirovannyiye fiksturyi. Tenevoj redaktor bez argumentov otkryivayet GUI, a putj k tekstovomu fajlu mozhno peredatj pervyim argumentom. Prototip fizicheskikh sostoyanij klavish bez argumentov otkryivayet GUI-provodnik, no ne zapuskayet istochniki i ne zapisyivayet sobyitiya do yavnogo soglasiya i starta kartochki; bezopasnaya matrica dostupna argumentom `matrix`. Vosproizvodimoye popolneniye pamyati dopolniteljno podderzhivayet yavnyiye `bootstrap <каталог>`, `continue <каталог>` i `show <каталог>`, sobstvennyij JSON-vkhod chistogo modeljnogo shaga peredayotsya cherez `stdin`, a zhivoj epizod prinimayet cherez `stdin` strogiye komandyi `create`, `inspect`, `status`, `resume` i `replay` s yavnyim katalogom. Otdeljnyiye yavnyiye rezhimyi `recorded` i `live` napravlyayut vyipolneniye v sobstvennyij harness: bez puti on sozdayot i udalyayet vremennyij katalog, a s odnim putyom trebuyet uzhe susjhestvuyusjhij pustoj katalog. `live` ne zapuskayet provider i ne skachivayet modelj. Proveryayemyij mnogoagentnyij kontur razdelyayet komandyi rabochego paketa, pasporta `episode`, obsjhej pamyati `memory bootstrap|continue|show` i polnoj lokaljnoj priyomki `acceptance all`; poslednyaya vyipolnyayet chetyire zapisannyikh scenariya bez seti, sekretov, zhivoj modeli i zhivogo instrumenta i pechatayet odin kanonicheskij JSON-otchyot.

Yedinyij kontrakt proveryayetsya bez zapuska prototipov:

```bash
python3 Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py
```

## Kak oformlyatj prototip

Kazhdyij ustojchivyij prototip razmesjhayetsya v otdeljnoj podpapke. V podpapke nuzhen kratkij `README.md` ili pasport, kotoryij fiksiruyet:

- kakuyu chastj [korobochnoj realizacii FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) proveryayet prototip;
- na kakiye [iskhodnyiye zaprosyi](../Glossarij/iskhodnyij-zapros.md), dokumentyi, planovyiye materialyi ili otkryityiye voprosyi on opirayetsya;
- chto schitayetsya proveryayemyim rezuljtatom: kod, maket, dannyiye, scenarij zapuska, test, otchyot ili sravneniye variantov;
- ispolnyayemyij POSIX-skript `запустить.sh`, kotoryij sam opredelyayet katalog prototipa, dayot poleznyij bezopasnyij zapusk bez obyazateljnyikh argumentov i peredayot dopolniteljnyiye argumentyi;
- kak zapustitj ili proveritj prototip lokaljno bez sekretov i setevyikh zavisimostej po umolchaniyu, vklyuchaya scenarii `запустить.sh`;
- yesli prototip napisan ne na Swift, pochemu vyibran drugoj yazyik, runtime ili stek;
- kakiye ogranicheniya, riski, ruchnyiye dopusjheniya i nevosproizvodimyiye chasti ostayutsya za predelami proverki;
- tekusjhij status: chernovik, proveryayetsya, prinyat dlya perenosa, snyat ili arkhivirovan.

Yesli prototip trebuyet vneshnej modeli, servisa, zakryityikh dannyikh ili ruchnogo dejstviya, v pasporte sokhranyayetsya publikacionno chistyij kontrakt: vkhodyi, vyikhodyi, ozhidayemoye povedeniye, fiksturyi, simulyator ili otchyot o nevosproizvodimoj chasti.

## Rolj testa realizacii kornevogo yadra

Prototip mozhet ispoljzovatjsya kak ispolnyayemyij test otdeljnoj realizacii [kornevogo yadra FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md). V etom sluchaye pasport dopolniteljno fiksiruyet tochnuyu versiyu i srez yadra, obsjhij nabor vkhodov, invariantov i ozhidayemyikh otkazov, profilj sravneniya nablyudayemyikh rezuljtatov, komandyi zapuska obeikh storon i granicu nepokryitogo povedeniya.

Ozhidayemyiye rezuljtatyi zakreplyayutsya do zapuska proveryayemoj realizacii i ne porozhdayutsya yeyu. Nejtraljnaya obvyazka vkhoda i sravneniya mozhet byitj obsjhej, no vyichisliteljnaya logika proveryayemogo sreza ostayotsya nezavisimoj; inache sovpadeniye ne yavlyayetsya samostoyateljnyim testom. Raskhozhdeniye neljzya ustranyatj molchalivoj podgonkoj etalona, a uspekh odnogo sreza ne vyidayotsya za gotovnostj vsego yadra ili korobochnoj postavki.

## Perenos rezuljtatov

Prinyatyiye vyivodyi iz prototipov perenosyatsya v osnovnoj kontur po smyislu:

- v `Документация/`, yesli vyivod menyayet opisaniye [FUM](../Glossarij/FUM.md), trebovaniya, arkhitekturu ili modelj;
- v `Инструменты/`, yesli rezuljtat stanovitsya vosproizvodimoj lokaljnoj avtomatizaciyej, proverkoj ili CLI-scenariyem;
- v `Планирование/`, yesli rezuljtat utochnyayet dorozhnuyu kartu, MVP-kandidata, stadiyu ili predlozheniye sleduyusjhego shaga;
- v `Вопросы/`, yesli prototip vyiyavil protivorechiye, nepolnotu trebovanij ili risk, kotoryij neljzya snyatj vnutri tekusjhej sessii.

Poka rezuljtat ostayotsya toljko v `Прототипы/`, on schitayetsya rabochej proboj, a ne obesjhaniyem gotovogo produkta. Vneshniye opisaniya, planyi i kommityi dolzhnyi razlichatj status prototipa i status prinyatogo resheniya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-05 20:01:32 MSK - Zakrepitj prototipyi kak testyi i sozdatj kartochku ozhidaniya ocheredi](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/zapros.md)
- [iskhodnyij zapros 2026-08-02 13:26:18 MSK - Provesti avtonomnuyu priyomku raspredelyonnogo myisliteljnogo epizoda](../Zhurnal/2026-08-02_13-26-18_MSK_provesti-avtonomnuyu-priyomku-raspredelyonnogo-myisliteljnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-02 09:36:50 MSK - Dobavitj vyibor, byudzhetyi i usloviye ostanovki epizoda](../Zhurnal/2026-08-02_09-36-50_MSK_dobavitj-vyibor-byudzhetyi-i-usloviye-ostanovki-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-01 23:00:38 MSK - Dobavitj vosstanavlivayemuyu obsjhuyu pamyatj raspredelyonnogo epizoda](../Zhurnal/2026-08-01_23-00-38_MSK_dobavitj-vosstanavlivayemuyu-obsjhuyu-pamyatj-raspredelyonnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-01 19:37:43 MSK - Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-08-01 14:29:41 MSK - Realizovatj izolirovannyij kandidatnyij kommit i otdeljnuyu priyomku](../Zhurnal/2026-08-01_14-29-41_MSK_realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku/zapros.md)
- [iskhodnyij zapros 2026-08-01 11:56:54 MSK - Realizovatj podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](../Zhurnal/2026-08-01_11-56-54_MSK_realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-31 21:37:26 MSK - Vvesti skhemu sobyitij zhivogo odnoagentnogo epizoda](../Zhurnal/2026-07-31_21-37-26_MSK_vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-31 18:05:50 MSK - Zakrepitj ispolnimyij token-byudzhet model-only-profilya](../Zhurnal/2026-07-31_18-05-50_MSK_zakrepitj-ispolnimyij-token-byudzhet-model-only-profilya/zapros.md)
- [iskhodnyij zapros 2026-07-28 07:49:45 MSK - Dobavitj avarijnuyu soglasovannostj khranilisjha pamyati](../Zhurnal/2026-07-28_07-49-45_MSK_dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-28 00:54:15 MSK - Dobavitj mezhprocessnyij CAS ukazatelya pamyati](../Zhurnal/2026-07-28_00-54-15_MSK_dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-27 22:17:40 MSK - Sokhranitj kanonicheskiye sobyitiya i dokazatj vosproizvedeniye](../Zhurnal/2026-07-27_22-17-40_MSK_sokhranitj-kanonicheskiye-sobyitiya-i-dokazatj-vosproizvedeniye/zapros.md)
- [iskhodnyij zapros 2026-07-25 09:09:06 MSK - Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK - Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 03:39:33 MSK - Podgotovitj Swift-prototip pamyati strukturiruyusjhikh operatorov FUM](../Zhurnal/2026-07-24_03-39-33_MSK_podgotovitj-Swift-prototip-pamyati-strukturiruyusjhikh-operatorov-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 02:41:56 MSK - Proveritj prototip kompilyacii chislennogo podmnozhestva v tenzornyij graf](../Zhurnal/2026-07-24_02-41-56_MSK_proveritj-prototip-kompilyacii-chislennogo-podmnozhestva-v-tenzornyij-graf/zapros.md)
- [iskhodnyij zapros 2026-07-24 02:06:29 MSK - Proveritj prototip agentnogo chteniya setevoj sredyi](../Zhurnal/2026-07-24_02-06-29_MSK_proveritj-prototip-agentnogo-chteniya-setevoj-sredyi/zapros.md)
- [iskhodnyij zapros 2026-07-23 19:08:00 MSK - Proveritj minimaljnyij Swift-prototip iyerarkhii funkcij i dannyikh FUM](../Zhurnal/2026-07-23_19-08-00_MSK_proveritj-minimaljnyij-Swift-prototip-iyerarkhii-funkcij-i-dannyikh-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-23 18:12:05 MSK - Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla](../Zhurnal/2026-07-23_18-12-05_MSK_proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-01 22:01:43 MSK](../Zhurnal/2026-07-01_22-01-43_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-06 13:52:08 MSK - Zakrepitj Swift yazyikom prototipov](../Zhurnal/2026-07-06_13-52-08_MSK_zakrepitj-Swift-yazyikom-prototipov/zapros.md)
- [iskhodnyij zapros 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij](../Zhurnal/2026-07-14_08-54-56_MSK_sozdatj-prototip-raskhozhdeniya-prodolzhenij/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:40:21 MSK - Sozdatj prototip fizicheskikh sostoyanij klavish](../Zhurnal/2026-07-17_10-40-21_MSK_sozdatj-prototip-fizicheskikh-sostoyanij-klavish/zapros.md)
- [iskhodnyij zapros 2026-07-17 12:20:17 MSK - Sozdatj skriptyi zapuska prototipov](../Zhurnal/2026-07-17_12-20-17_MSK_sozdatj-skriptyi-zapuska-prototipov/zapros.md)
- [iskhodnyij zapros 2026-07-17 12:33:01 MSK - Dobavitj panelj zapuska prototipov](../Zhurnal/2026-07-17_12-33-01_MSK_dobavitj-panelj-zapuska-prototipov/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:49:43 MSK - Dorabotatj prototip sbora klaviaturnyikh sobyitij](../Zhurnal/2026-07-21_13-49-43_MSK_dorabotatj-prototip-sbora-klaviaturnyikh-sobyitij/zapros.md)

## Opornyiye materialyi

- [otchyot o zhivom progone odnoagentnogo epizoda](zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [Stadiya: korobochnaya realizaciya FUM](../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md)
- [MVP-kandidat: yedinaya tochka lokaljnoj rabotyi](../Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)
- [Arkhitektura FUM](../Dokumentaciya/22-arkhitektura-FUM.md)
- [Vosproizvodimyiye avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 20:15:36 MSK -->
<!-- content-sha256: sha256:4d0ddd7246b5ac3dbf6e7207a18b281051710e31805b93a10b55e81e35aa3b6c -->
<!-- FUM-MD-RECENCY:END -->
