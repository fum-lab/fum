# 03. Agentskij cikl i ispolnyayemyij kontur

## Naznacheniye

Eto napravleniye perevodit [agentskij cikl](../../Glossarij/agentskij-cikl.md) iz opisaniya v minimaljnyij ispolnyayemyij kontur. [FUM](../../Glossarij/FUM.md) dolzhen umetj nablyudatj vkhod, sformulirovatj zadachu, vyibratj dejstviye, vyipolnitj yego cherez razreshyonnyij instrument ili avtomatizaciyu, proveritj rezuljtat, sokhranitj trassu i reshitj, mozhno li prodolzhatj cepochku.

Ekspluatacionnaya ograda: sleduyusjhij abzac opisyivayet prezhnij Git + Codex-konvejyer kak istoricheskij povedencheskij prototip. Dejstvuyusjhaya zapisj vyipolnyayetsya ruchnyimi posledovateljnyimi sessiyami bez continuation, FIFO, selector i handoff.

Tekusjhij kontur Git + Codex uzhe sluzhit povedencheskim prototipom avtomaticheski prodolzhayemogo cikla na masshtabe diskretnyikh zadach i kommitov. Zaraneye sozdannaya zadacha-prodolzheniye tochnoj vetki, pryamoj vyibor sleduyusjhego shaga, strogaya FIFO-ocheredj i atomarnaya peredacha svyazyivayut otdeljnyiye zapuski v nablyudayemoye prodolzheniye, a novaya poljzovateljskaya zadacha mozhet izmenitj pamyatj, trebovaniya i posleduyusjhuyu trayektoriyu vetki. Sam etot kontur ne yavlyayetsya sobstvennyim runtime FUM: FIFO ne vyitesnyayet uzhe dopusjhennuyu zadachu v realjnom vremeni i ne nablyudayet poljzovateljskij vvod vnutri neyo kak potok sobyitij.

Otdeljno zavershyon [uzkij inzhenernyij eksperiment odnogo sobstvennogo runtime-scenariya](../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md). Versionnyij pasport svyazyivayet celj, sinteticheskij kontekst, provider identity, konechnyij byudzhet, raskryitiye dannyikh, yedinstvennyij razreshyonnyij Git-effekt, proverki i terminaljnyiye iskhodyi. Sobstvennyij Swift-runtime vyipolnyayet realjnyiye model-only-shagi, sravnivayet dva varianta ot obsjhego predka, sokhranyayet no-call-otkaz tretjyemu variantu po byudzhetu, prinimayet otdeljnoye vneshneye podtverzhdeniye, sozdayot izolirovannyij kandidat i poluchayet nezavisimuyu priyomku. Dva fakticheskikh `SIGKILL` v zaraneye zaregistrirovannyikh checkpoint podtverzhdayut vozobnovleniye novyimi PID toljko iz podtverzhdyonnogo `CURRENT`.

## Proyektnyiye voprosyi

- Kakoj minimaljnyij format sostoyaniya cikla nuzhen dlya lokaljnogo zapuska bez skryityikh rassuzhdenij modeli?
- Chto v trasse yavlyayetsya nablyudeniyem, chto resheniyem, chto dejstviyem, chto proverkoj, a chto rezuljtatom?
- Kak otdelitj vnutrennij vyibor agenta ot vneshnej proverki poljzovatelya, testov, revjyu ili sredyi?
- Kak uchityivatj stoimostj, vremya, ogranicheniya dostupa i vozmozhnostj peredachi rezuljtata sleduyusjhemu uzlu?
- Kak prinyatj razreshyonnyij poljzovateljskij vvod vo vremya nezavershyonnoj rabotyi i bezopasno perenapravitj cikl na nablyudayemoj kontroljnoj tochke?
- Kak otdelitj nepreryivnostj upravlyayusjhego kontura ot nepreryivnogo inference i ot vyizova modeli na kazhdoye sobyitiye vvoda?

## Liniya razvitiya

Pervyij prakticheskij shag opisal trassu cikla kak publikacionno chistyij artefakt: vkhod, celj, vyibrannyiye instrumentyi, podtverzhdeniya, dejstviya, proverki, rezuljtat, oshibki i prodolzheniya. Zavershyonnyij uzkij zapusk proveril ispolneniye odnogo zaraneye zakreplyonnogo sinteticheskogo scenariya. Sleduyusjhij sloj dolzhen rasshiryatj poljzovateljskij format scenariya i nabor razreshyonnyikh dejstvij otdeljnyimi proveryayemyimi shagami, ne obobsjhaya rezuljtat odnogo progona na vesj ispolnyayemyij kontur.

Eto napravleniye dolzhno soyedinyatjsya s [avtomatizaciyami FUM](../../Glossarij/avtomatizaciya-FUM.md): ustojchivyiye shagi cikla vyinosyatsya v proveryayemyiye avtomatizacii, a cikl stanovitsya kompozitorom nablyudayemyikh dejstvij.

[Poljzovateljskoye perenapravleniye nepreryivnogo agentskogo cikla](../../Trebovaniya/🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) i [nepreryivnoye sobyitijnoye nablyudeniye poljzovateljskogo vvoda](../../Trebovaniya/🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md) zadayut perekhod, v kotorom korobochnyij kontur prinimayet razreshyonnyiye sobyitiya vo vremya rabotyi, pri neobkhodimosti agregiruyet ikh i primenyayet relevantnoye izmeneniye na bezopasnoj kontroljnoj tochke. [Zavershyonnaya kartochka FUM-STEP-0072](../kartochki-shagov/✅-FUM-STEP-0072-opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom.md) zakrepila staticheskuyu vkhodnuyu granicu v trasse versii `2` i determinirovannoj read-only-fiksture; rabotayusjhij sobyitijnyij kanal i runtime ostayutsya posleduyusjhim inzhenernyim sloyem.

[Avtonomnoye modeljnoye prodolzheniye pri ozhidanii podtverzhdeniya](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md) utochnyayet druguyu granicu: otsutstviye otveta zakryivayet toljko tochnyij ozhidayusjhij perekhod vo vneshnij ili prinimayemyij kontur, no pri nalichii bezopasnogo produktivnogo prodolzheniya i ostatka nezavisimo razreshyonnogo model-only-byudzheta ne zavershayet vesj myisliteljnyij epizod. V modeljnoj srede cikl vyibirayet takoye prodolzheniye, a pri dostatochnom byudzhete razvorachivayet dva ili boleye soderzhateljno razlichimyikh varianta ot obsjhego predka i otbirayet ikh po obyyavlennyim proverkam. [Zavershyonnaya kartochka FUM-STEP-0106](../kartochki-shagov/✅-FUM-STEP-0106-zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye-pri-ozhidanii-podtverzhdeniya.md) zakrepila etot kontrakt v skheme trassyi versii `3` i tryokh lokaljnyikh determinirovannyikh fiksturakh; odin uzkij runtime-epizod teperj proveryayet tu zhe granicu v ispolnenii, no ne dokazyivayet obsjhij mekhanizm proizvoljnyikh zadach.

## Blizhajshij proveryayemyij artefakt

[Minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) zakreplyon v tryokh versiyakh. Versiya `1` khranit semj iskhodnyikh tipov, versiya `2` dobavlyayet plan, pervichnoye sobyitiye vvoda, agregirovannyij signal, kontroljnuyu tochku i resheniye o perenapravlenii, a versiya `3` nezavisimo predstavlyayet prodolzhayusjhijsya epizod, model-only-vetvi, ozhidayusjhij podtverzhdeniya perekhod i vneshneye ispolneniye. Lokaljnyiye fiksturyi sokhranyayut vosstanovimuyu oshibku bazovogo cikla, proverennoye izmeneniye prodolzheniya i neblokiruyusjheye modeljnoye vetvleniye bez specialjnyikh polej skryityikh rassuzhdenij.

Odin ogranichennyij runtime poverkh etogo kontrakta teperj proveren avtonomnoj recorded-fiksturoj i opt-in zhivyim lokaljnyim progonom. On chereduyet modeljnyij shag, strogij razbor namereniya, dejstviye, nablyudeniye, proverku i resheniye o prodolzhenii; ispoljzuyet odin tochnyij provider profile i odin allowlisted Git-adapter; sokhranyayet kandidat vne iskhodnoj vetki i prinimayet yego otdeljnyim processom. [Otchyot o zhivom progone](../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md) zakreplyayet nablyudayemoye svideteljstvo, a ne universaljnuyu arkhitekturnuyu gotovnostj.

Iz etogo rezuljtata ne sleduyut gotovnostj komandyi `fum run`, obsjhij ili produktovyij runtime, raspredelyonnoye ispolneniye, proizvoljnyiye actions, fonovyiye zadachi, nepreryivnyij priyom vvoda libo preimusjhestvo nad kontroljnyim agentom. Vse eti vozmozhnosti ostayutsya otdeljnyimi proyektnyimi i priyomochnyimi sloyami.

Versiya `2` razlichayet iskhodnyij plan, poljzovateljskij vkhod do zaversheniya rabotyi, bezopasnuyu kontroljnuyu tochku, resheniye o perenapravlenii i novoye prodolzheniye. Soobsjheniye-zadacha, pervichnoye sobyitiye vvoda i agregirovannyij signal ostayutsya raznyimi nablyudayemyimi susjhnostyami; specifikaciya ne dokazyivayet zhivuyu dostavku ili primeneniye sobyitiya sobstvennyim runtime.

## Proveryayemyiye rezuljtatyi

- [Minimaljnaya skhema trassyi cikla](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) opisyivayet zadachu, nablyudeniye, dejstviye, rezuljtat, oshibku, proverku i status prodolzheniya.
- Lokaljnyij primer zapuska sozdayot proveryayemyij rezuljtat v pamyati i ne trebuyet sekretov.
- Rezuljtat cikla mozhet byitj svyazan s [zhurnalom rabot](../../Glossarij/zhurnal-rabot.md), spiskom zatronutyikh fajlov i budusjhim pasportom [peredavayemogo rezuljtata](../../Glossarij/peredavayemyij-rezuljtat-FUM.md).
- Oshibki i ostanovki fiksiruyutsya kak chastj trassyi, a ne propadayut iz pamyati.
- Diskretnyij Git + Codex-kontur yavno opisan kak povedencheskij prototip vozobnovleniya i perenapravleniya mezhdu zadachami, no ne kak sobstvennyij produktovyij runtime.
- Korobochnaya proverka pokazyivayet, kak razreshyonnyij vkhod, postupivshij vo vremya rabotyi, menyayet nablyudayemyiye celj, prioritet, plan, vetku ili dejstviye na bezopasnoj kontroljnoj tochke.
- Ozhidaniye podtverzhdeniya ne vyidayot novyikh polnomochij, no pri nalichii nezavisimo razreshyonnogo modeljnogo byudzheta ostavlyayet cikl produktivnyim: tochnyij vneshnij perekhod zakryit, variantyi sopostavimyi po obsjhemu predku i proverkam, a modeljnyij vyibor ne schitayetsya podtverzhdeniyem poljzovatelya.
- Uzkij sobstvennyij runtime-scenarij avtonomno vosproizvoditsya, prokhodit dva mezhprocessnyikh vozobnovleniya posle `SIGKILL`, sozdayot izolirovannyij kandidat i poluchayet otdeljnuyu priyomku; vyivod ogranichen etim scenariyem.

## Granicyi

Ispolnyayemyij kontur ne dolzhen podmenyatj soglasiye poljzovatelya skryitoj avtonomiyej. Dejstviya s vneshnimi servisami, privatnyimi dannyimi, pravami dostupa i fizicheskoj sredoj trebuyut otdeljnyikh ogranichitelej. Trassa cikla ne dolzhna raskryivatj skryityiye rassuzhdeniya modeli; ona dolzhna fiksirovatj nablyudayemyiye resheniya, dejstviya i proverki. Nepreryivnostj nablyudeniya i upravleniya ne oznachayet beskonechnyij modeljnyij process ili otdeljnyij vyizov LLM na kazhdoye sobyitiye: filjtraciya, agregaciya, zaderzhka i granicyi primeneniya vkhoda dolzhnyi byitj yavnyimi i proveryayemyimi. Zavershyonnyij eksperiment ne rasshiryayet polnomochiya za predelyi sinteticheskikh dannyikh, zakreplyonnogo lokaljnogo provajdera i yedinstvennogo izolirovannogo Git-dejstviya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:07:48 MSK — Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Zhurnal/2026-07-22_13-07-48_MSK_sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

## Opornyiye materialyi

- [Otchyot o zhivom progone odnoagentnogo epizoda](../../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Dostup k vnutrennim sostoyaniyam](../../Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md)
- [Arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md)
- [MVP ispolnyayemogo agentskogo cikla](../MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:51:31 MSK -->
<!-- content-sha256: sha256:79c15f3ac87549a938bcd5e7c37f73773fe14391c975838d438fa6c53f70a11d -->
<!-- FUM-MD-RECENCY:END -->
