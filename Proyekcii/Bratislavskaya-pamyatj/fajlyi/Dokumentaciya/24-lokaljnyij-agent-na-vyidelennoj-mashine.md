# Lokaljnyij agent [FUM](../Glossarij/FUM.md) na vyidelennoj mashine

## Trebovaniye

Vazhnaya celevaya vekha razvitiya [FUM](../Glossarij/FUM.md) - lokaljnyij agent na vyidelennoj mashine s lokaljno zapuskayemoj siljnoj LLM, kotoraya sposobna rabotatj na etoj mashine. Takaya vekha perevodit obraz [lichnogo FUM-agenta](../Glossarij/lichnyij-FUM-agent.md) iz rezhima vneshnej agentskoj sessii v rezhim sobstvennogo vyichisliteljnogo uzla: agent, [pamyatj](../Glossarij/pamyatj-FUM.md), instrumentyi, proverki i osnovnoj modeljnyij runtime dolzhnyi nakhoditjsya v upravlyayemoj lokaljnoj srede.

Rabochij apparatnyij obraz etoj vekhi - Mac Studio s maksimaljnoj dostupnoj pamyatjyu klassa 512 GB. Eta formulirovka ne yavlyayetsya okonchateljnyim zakupochnyim resheniyem: k momentu realizacii nuzhno otdeljno proveritj aktualjnyiye konfiguracii, dostupnyiye lokaljnyiye modeli, runtime-instrumentyi, stoimostj, energopotrebleniye i ogranicheniya licenzij. Smyisl vekhi ne v konkretnoj marke ustrojstva, a v sposobnosti [FUM](../Glossarij/FUM.md) susjhestvovatj kak samodostatochnyij lokaljnyij [FUM-uzel](../Glossarij/FUM-uzel.md), ne zavisyasjhij v osnovnom [agentskom cikle](../Glossarij/agentskij-cikl.md) ot vneshnej oblachnoj modeli.

V boleye obsjhej formulirovke vyidelennaya mashina yavlyayetsya pervyim prakticheskim [kremniyevyim substratom FUM](../Glossarij/kremniyevyij-substrat-FUM.md). Na nej nuzhno ne prosto zapustitj modelj, a organizovatj vyichisleniya razuma: svyazatj pamyatj, LLM, instrumentyi, proverki, trassu, urovni dostupa i peredachu rezuljtatov v formu, kotoraya prodolzhayet uzhe nablyudayemuyu fraktaljnuyu strukturu uzlov myishleniya.

## Chto oznachayet lokaljnostj

Lokaljnostj etoj vekhi oznachayet, chto bazovyij cikl rabotyi [FUM](../Glossarij/FUM.md) mozhet prokhoditj na vyidelennoj mashine:

- poljzovateljskoye namereniye popadayet v lokaljnyij kontur [lichnogo FUM-agenta](../Glossarij/lichnyij-FUM-agent.md);
- dolgovremennaya [pamyatj FUM](../Glossarij/pamyatj-FUM.md), rabochiye fajlyi, zhurnal, istochniki, proverki i trassyi nakhodyatsya na lokaljnom nositele ili v lokaljno upravlyayemom khranilisjhe;
- osnovnaya LLM zapuskayetsya lokaljno i sposobna vyipolnyatj susjhestvennuyu chastj rassuzhdenij, planirovaniya, chteniya pamyati i podgotovki dejstvij;
- lokaljnyiye [avtomatizacii FUM](../Glossarij/avtomatizaciya-FUM.md), instrumentyi i servisnyiye adapteryi vyizyivayutsya cherez nablyudayemyiye kontraktyi;
- vneshniye modeli i servisyi mogut podklyuchatjsya kak dopolniteljnyiye vozmozhnosti, no ikh ispoljzovaniye yavno pomechayetsya v trasse i ne schitayetsya obyazateljnyim osnovaniyem lokaljnoj avtonomii.

Vyidelennaya mashina pri etom yavlyayetsya ne prosto kompjyuterom poljzovatelya, a kandidatom v [apparatnyij FUM-uzel](../Glossarij/apparatnyij-FUM-uzel.md). Ona dolzhna imetj opisannoye naznacheniye, sostav, modeljnyij runtime, prava dostupa, ogranicheniya, rezhim obnovleniya i proverki rabotosposobnosti.

## Rolj lokaljnoj LLM

Lokaljnaya LLM v etoj vekhe yavlyayetsya yadrom modeljnogo shaga, no ne vsej sistemoj [FUM](../Glossarij/FUM.md). [FUM](../Glossarij/FUM.md) ostayotsya setjyu pamyati, avtomatizacij, proverok, interfejsov, urovnej dostupa i otbora rezuljtatov.

LLM dolzhna umetj vkhoditj v [yestestvenno-yazyikovuyu sinkhronizaciyu znanij FUM](../Glossarij/yestestvenno-yazyikovaya-sinkhronizaciya-znanij-FUM.md) ryadom s chelovekom i drugimi agentami: interpretirovatj ne toljko mestoimennyiye roli, no ponyatiya, vremya, modaljnostj, prichinnostj, dokazateljnostj, voprosyi, ispravleniya i strukturu dialoga. Ustojchivyij lokaljnyij [agent chelovecheskogo obrazca FUM](../Glossarij/agent-chelovecheskogo-obrazca-FUM.md) svyazyivayet modelj s lokaljnoj pamyatjyu, kontekstnoj identichnostjyu, proiskhozhdeniyem, urovnyami dostupa, instrumentami i ciklom proverki.

Runtime ne dolzhen predpolagatj yedinstvennuyu monolitnuyu LLM-sessiyu. On dolzhen dopuskatj setj vnutrennikh poduzlov ili specializirovannyikh agentov s raznyimi lokaljnyimi kontekstami, obsjhej sredoj i yazyikovyimi libo operatorno sovmestimyimi soobsjheniyami. Tot zhe kontrakt dolzhen svyazyivatj vnutrennyuyu setj agenta i yego vneshneye uchastiye v seti lyudej, LLM-podderzhivayemyikh i gibridnyikh uzlov.

Poetomu vyibor modeli dolzhen ocenivatjsya ne toljko po obsjhemu kachestvu otvetov, no i po tomu, naskoljko ona prigodna dlya konkretnyikh ciklov [FUM](../Glossarij/FUM.md):

- chteniye i obnovleniye boljshoj lokaljnoj [pamyati](../Glossarij/pamyatj-FUM.md);
- rabota s kodom, Markdown-dokumentaciyej, glossariyem, planovyimi materialami i testami;
- ustojchivoye sledovaniye lokaljnyim pravilam publikacionnoj chistotyi i proiskhozhdeniya;
- vyizov instrumentov, sokhraneniye nablyudayemoj trassyi i uvazheniye tochek podtverzhdeniya;
- sposobnostj rabotatj s dlinnyim kontekstom bez nepriyemlemogo padeniya skorosti i kachestva;
- licenziya i rezhim rasprostraneniya, sovmestimyiye s otkryityim razvitiyem [FUM](../Glossarij/FUM.md) i privatnostjyu lichnoj pamyati.

Trebovaniye k "topovomu" urovnyu lokaljnoj LLM zadayot napravleniye kachestva, no ne zamenyayet kriterii otbora. Do vyibora konkretnoj modeli nuzhen otdeljnyij profilj sravneniya: kakiye benchmark-zadachi FUM vazhnyi, kakaya minimaljnaya skorostj priyemlema, kakoj kontekst nuzhen, kakaya tochnostj instrumentaljnogo povedeniya trebuyetsya i kakiye vneshniye fallback-modeli dopustimyi.

Dlya [tenevogo redaktora prodolzhenij](../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md) lokaljnaya LLM yavlyayetsya ne daljnej celevoj opciyej, a usloviyem dejstviteljnosti osnovnogo scenariya. Oblachnyij fallback ne zaschityivayetsya, testovaya zaglushka ispoljzuyetsya toljko v avtonomnyikh proverkakh, a priyomka trebuyet realjnogo inference zaraneye ustanovlennoj modeli na lokaljnoj mashine. Adapter prinuditeljno obrasjhayetsya k loopback-runtime, snachala proveryayet nalichiye modeli bez avtomaticheskoj zagruzki, peredayot tekst cherez stdin bez shell i ostanavlivayet generaciyu po gorizontu, tajm-autu ili novomu prioritetnomu vvodu. Trassa dolzhna svyazyivatj rezuljtat kak minimum s imenem modeli i runtime; tochnaya versiya vesov, kvantovaniye, parametryi syemplirovaniya, skorostj i zaderzhka ostayutsya obyazateljnyim rasshireniyem dlya sravniteljnyikh vyivodov.

## Fonovaya rabota pri otsutstvii prioritetnogo vkhoda

V [korobochnoj realizacii FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) lokaljnuyu LLM mozhno zagruzhatj [fonovyimi zadaniyami FUM](../Glossarij/fonovoye-zadaniye-FUM.md), kogda odnovremenno net neobrabotannogo poljzovateljskogo vvoda i gotovyikh zadach boleye vyisokogo prioriteta. Resheniye o zapuske prinimayet [darvinovskij planirovsjhik FUM](../Glossarij/darvinovskij-planirovsjhik-FUM.md), a ne sama LLM: otsutstviye vkhoda yavlyayetsya usloviyem dopuska k zaraneye razreshyonnoj ocheredi, no ne obsjhim razresheniyem modeli vyibiratj lyubyiye celi i dejstviya.

Fonovoye zadaniye dolzhno byitj nizkoprioritetnyim, ogranichennyim po vremeni, vyichisleniyam, pamyati i energii, a takzhe preryivayemyim ili vozobnovlyayemyim iz bezopasnoj kontroljnoj tochki. Novyij poljzovateljskij vvod libo boleye prioritetnaya gotovaya zadacha privodyat k sokhraneniyu statusa i trassyi, posle chego fon priostanavlivayetsya ili zavershayetsya. Razreshyonnyiye effektyi ostayutsya temi zhe, chto u obyichnogo zadaniya: fonovyij rezhim ne dayot prava na neobratimoye izmeneniye pamyati, vneshnij vyizov, publikaciyu, rabotu s privatnyimi dannyimi ili fizicheskoye dejstviye bez predusmotrennogo podtverzhdeniya.

Odnim iz poleznyikh klassov fonovoj rabotyi yavlyayetsya postroyeniye i posledovateljnoye utochneniye vneshnego opisaniya modeli mira i [yazyikovogo prostranstva](34-yestestvennyij-yazyik-i-sinkhronizaciya-znanij-FUM.md#yazyikovoj-agent-i-yazyikovoye-prostranstvo) konkretnoj LLM. Takoj artefakt dolzhen byitj privyazan k identifikatoru modeli, versii runtime, dostupnoj pamyati, kontekstnoj konfiguracii, testovyim vkhodam i nablyudayemyim vyikhodam; utverzhdeniya, vyivodyi, gipotezyi i neizvestnoye khranyatsya razdeljno. Poluchennoye samoopisaniye ne schitayetsya pryamoj introspekciyej vesov ili skryityikh sostoyanij i ne stanovitsya faktom bez vneshnej proverki.

Tochnaya politika pula fonovyikh zadanij, shkalyi prioritetov, resursnyikh kvot i vyitesneniya ostayotsya svyazana s [otkryityim voprosom o granicakh issledovateljskoj avtonomii FUM](../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md).

## Ot diskretnogo prodolzheniya k sobyitijnoj rabote

Tekusjhij dokumentacionnyij prototip dayot vneshnij obraz diskretno vozobnovlyayemoj rabotyi: poljzovatelj vruchnuyu zapuskayet kazhduyu pishusjhuyu zadachu, a trebovaniya, pamyatj i lokaljnaya Git-istoriya sokhranyayut nablyudayemuyu trayektoriyu mezhdu zapuskami. Prezhnij profilj s [prodolzheniyem toj zhe Git-vetki](../Glossarij/obyazateljnoye-prodolzheniye-vetki.md), FIFO i `commit+handoff` otlozhen. Ni ruchnaya skhema, ni etot eksperimentaljnyij profilj ne perenosyat modelj, sostoyaniye ili planirovsjhik pod upravleniye lokaljnogo FUM-uzla.

Lokaljnyij korobochnyij runtime dolzhen zamenitj etu krupnuyu diskretnuyu granicu razreshyonnyim sobyitijnyim vkhodom vo vremya aktivnogo cikla. Znachimoye sobyitiye ili yavno agregirovannaya posledovateljnostj sobyitij dolzhnyi na blizhajshej bezopasnoj kontroljnoj tochke privoditj k proveryayemomu vyiboru: sokhranitj plan, izmenitj celj ili prioritet, perestroitj plan, smenitj vetku, priostanovitjsya, otmenitj prodolzheniye libo zaprositj utochneniye. Svyazj resheniya s vkhodom sokhranyayetsya v trasse cherez nablyudayemyiye celj, prioritet, plan, dejstviye, proverku i prodolzheniye, a ne cherez skryityiye rassuzhdeniya modeli.

Yesli utochneniye yavlyayetsya podtverzhdeniyem konkretnogo vneshnego effekta, otsutstviye otveta zakryivayet etot effekt, no ne vsyu lokaljnuyu sessiyu. V predelakh uzhe razreshyonnyikh dlya epizoda identichnosti provajdera, lokaljnogo ili udalyonnogo rezhima, raskryivayemyikh dannyikh i limitov vyizovov, tokenov i deneg agent prodolzhayet modeljnuyu rabotu, pri neobkhodimosti sozdayot neskoljko proveryayemyikh variantov i sokhranyayet vnutrennij vyibor otdeljno ot podtverzhdeniya. Ozhidaniye ne uvelichivayet eti predelyi. Kogda otvet postupayet, on primenyayetsya na bezopasnoj kontroljnoj tochke k tochnoj versii ozhidayusjhego perekhoda; yavnyij otkaz ili otzyiv nikogda ne traktuyetsya kak molchaniye libo soglasiye.

Sobyitijnoye nablyudeniye ne oznachayet postoyannuyu generaciyu tokenov. Organ vospriyatiya mozhet filjtrovatj, szhimatj i obyyedinyatj potok, sokhranyaya proiskhozhdeniye, poryadok, zaderzhku i poteri, a LLM vyizyivayetsya toljko po politike cikla. Avtomaticheski sozdavayemyiye shagi tekusjhej vetki pri etom ne schitayutsya uzhe realizovannoj otdeljnoj ocheredjyu [fonovyikh zadanij FUM](../Glossarij/fonovoye-zadaniye-FUM.md): u nikh poka net polnogo produktovogo kontrakta byudzhetov, kontroljnyikh tochek i sobyitijnogo vyitesneniya.

## Rolj uskoritelej i tenzornyikh runtime

Vyidelennaya mashina vazhna ne toljko kak nositelj lokaljnoj LLM. Yeyo GPU, NPU ili drugiye uskoriteli mogut statj ispolniteljnyim sloyem dlya chistyikh chislennyikh [avtomatizacij FUM](../Glossarij/avtomatizaciya-FUM.md), yesli takiye avtomatizacii kompiliruyutsya v tenzornyij vyichisliteljnyij graf i zapuskayutsya cherez ML- ili GPU-runtime.

Etot putj ne dolzhen podmenyatj obyichnoye programmirovaniye obesjhaniyem ispolnyatj lyubuyu programmu kak nejrosetj. Dlya lokaljnogo uzla polezen boleye uzkij i proveryayemyij kontur: ogranichennoye podmnozhestvo chislennogo yazyika ili DSL, yavnyiye formyi tenzorov, etalonnoye CPU-ispolneniye, eksport v ONNX, StableHLO, MLIR ili drugoj celevoj sloj, lokaljnyij zapusk na uskoritele i sravneniye rezuljtata, skorosti, pamyati i energozatrat. Yesli uskorennyij putj ne dayot vyiigryisha ili teryayet proveryayemostj, avtomatizaciya dolzhna ostavatjsya na boleye prostom runtime.

V pasporte lokaljnogo uzla poetomu nuzhno uchityivatj ne toljko modeljnyij runtime LLM, no i dostupnyiye kompilyatoryi, execution providers, drajveryi, ogranicheniya pamyati uskoritelya, fallback na CPU i trassu togo, kakoj imenno sloj uchastvoval v rezuljtate. Eto svyazyivayet lokaljnuyu avtonomiyu [FUM](../Glossarij/FUM.md) s nablyudayemyim [kremniyevyim substratom FUM](../Glossarij/kremniyevyij-substrat-FUM.md), a ne toljko s kachestvom otvetov modeli.

## Svyazj s virtualizovannyimi sredami

Lokaljnyij agent na vyidelennoj mashine yavlyayetsya chastnyim sluchayem [virtualizovannoj sredyi FUM](../Glossarij/virtualizovannaya-sreda-FUM.md). Nizhnim sloyem vyistupayut fizicheskoye ustrojstvo, operacionnaya sistema, nakopiteli, pamyatj, modeljnyij runtime i dostupnyiye uskoriteli. Poverkh nikh [FUM](../Glossarij/FUM.md) dolzhen predyyavlyatj sebe i vlozhennyim uzlam boleye organizovannyij interfejs: repozitorij pamyati, graf svyazej, zhurnal, lokaljnyiye instrumentyi, modeljnuyu sredu i servisnyiye adapteryi.

Dlya takoj sredyi nuzhno yavno opisyivatj kartu sootvetstviya mezhdu udobnyim interfejsom i nizhelezhasjhim substratom: gde lezhit pamyatj, kak zapuskayetsya modelj, kakiye dannyiye popadayut vo vneshnij servis, kakiye effektyi razreshenyi, kak vosstanavlivayetsya sostoyaniye posle sboya i kakiye chasti neljzya publikovatj.

## Kriterii gotovnosti vekhi

Vekhu mozhno schitatj dostignutoj ne po faktu pokupki mashinyi, a po proveryayemomu lokaljnomu konturu:

- vyibran i opisan apparatnyij profilj vyidelennoj mashinyi;
- vyibran lokaljnyij modeljnyij runtime i odna osnovnaya LLM, realjno pomesjhayusjhayasya v dostupnuyu pamyatj i zapuskayemaya bez vneshnego API;
- [lichnyij FUM-agent](../Glossarij/lichnyij-FUM-agent.md) mozhet vyipolnitj ogranichennuyu rabochuyu sessiyu nad [pamyatjyu FUM](../Glossarij/pamyatj-FUM.md) lokaljno: prochitatj kontekst, predlozhitj izmeneniye, zaprositj podtverzhdeniye vneshnego perekhoda, prodolzhitj bezopasnuyu modeljnuyu proverku variantov i vnesti pravku toljko posle dejstviteljnogo poljzovateljskogo sobyitiya dlya tochnogo perekhoda i versii, nezavisimoj avtorizacii i uspeshnogo preflight tekusjhego sostoyaniya, zatem zapustitj proverku i sokhranitj rezuljtat;
- vo vremya nezavershyonnoj lokaljnoj sessii razreshyonnyij testovyij vvod prinimayetsya bez otpravki novoj zadachi, a blizhajshaya bezopasnaya kontroljnaya tochka sokhranyayet yego proiskhozhdeniye i proveryayemo podtverzhdayet libo menyayet prodolzheniye;
- runtime mozhet provesti proveryayemyij cikl sinkhronizacii mezhdu dvumya poduzlami s razlichnoj lokaljnoj pamyatjyu: soobsjheniye, interpretaciya, utochneniye, ispravleniye, podtverzhdyonnaya obsjhaya chastj i sokhranyonnoye raskhozhdeniye;
- trassa sessii fiksiruyet modelj, runtime, instrumentyi, ogranicheniya, podtverzhdeniya, oshibki i itog;
- vneshniye servisyi, yesli oni ispoljzuyutsya, yavno otdelenyi ot lokaljnogo yadra i ne skryivayut proiskhozhdeniye rezuljtata;
- yestj plan obnovleniya modeli i apparatnogo profilya bez poteri vosproizvodimosti staryikh rezuljtatov.

## Granicyi

Eta vekha ne razreshayet fizicheskoye dejstviye [FUM](../Glossarij/FUM.md) samo po sebe. Vyidelennaya mashina mozhet byitj [apparatnyim FUM-uzlom](../Glossarij/apparatnyij-FUM-uzel.md), no upravleniye vneshnimi ustrojstvami, robotizirovannoye ispolneniye, rabota s syiryimi nositelyami i drugiye fizicheskiye effektyi ostayutsya pod ogranicheniyami dokumenta o [fizicheskom dejstvii FUM](13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md) i [otkryitogo voprosa o granicakh apparatnoj avtonomii](../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md).

Neopredelyonnostj kriteriyev vyibora lokaljnoj LLM i vyidelennoj mashinyi vyinesena v otdeljnyij [otkryityij vopros](../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md), chtobyi strategicheskaya vekha ne prevratilasj v prezhdevremennoye i byistro ustarevayusjheye resheniye.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-06-25 19:50:33 MSK](../Zhurnal/2026-06-25_19-50-33_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 12:05:01 MSK](../Zhurnal/2026-06-26_12-05-01_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-06 13:34:08 MSK - Opisatj kompilyaciyu algoritmov v tenzornyij graf](../Zhurnal/2026-07-06_13-34-08_MSK_opisatj-kompilyaciyu-algoritmov-v-tenzornyij-graf/zapros.md)
- [iskhodnyij zapros 2026-07-13 22:00:22 MSK - Zakrepitj yestestvennyij yazyik kak yazyik sinkhronizacii znanij](../Zhurnal/2026-07-13_22-00-22_MSK_zakrepitj-yestestvennyij-yazyik-kak-yazyik-sinkhronizacii-znanij/zapros.md)
- [iskhodnyij zapros 2026-07-14 03:18:36 MSK - Zakrepitj fonovyiye zadaniya dlya prostoya LLM](../Zhurnal/2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md)
- [iskhodnyij zapros 2026-07-14 08:54:56 MSK - Sozdatj prototip raskhozhdeniya prodolzhenij](../Zhurnal/2026-07-14_08-54-56_MSK_sozdatj-prototip-raskhozhdeniya-prodolzhenij/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

## Opornyiye dokumentyi

- [Arkhitektura FUM](22-arkhitektura-FUM.md)
- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Virtualizovannyiye sredyi FUM i dolgovremennaya pamyatj](23-virtualizovannyiye-sredyi-i-dolgovremennaya-pamyatj.md)
- [Fizicheskoye dejstviye FUM i apparatnyiye uzlyi](13-fizicheskoye-dejstviye-i-apparatnyiye-uzlyi.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](06-obzor-agentskikh-ciklov.md)
- [Yestestvennyij yazyik i sinkhronizaciya znanij FUM](34-yestestvennyij-yazyik-i-sinkhronizaciya-znanij-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:47:26 MSK -->
<!-- content-sha256: sha256:9a79969b9de194dc7d5328a940ebab37f3f2d640e63d9ec06cd7e60679a6f2a3 -->
<!-- FUM-MD-RECENCY:END -->
