# Sostav sleduyusjhej integracii

Eto rabochij perechenj tochnyikh postavok, a ne kvitanciya priyomki. Sborka napravlena v fuma, zatem proverennyij rezuljtat — v master. Istochnikom prinimayusjhikh pravil ostayotsya zakreplyonnyij master; kandidat ne rasshiryayet sobstvennyiye polnomochiya.

| Postavka | Zakreplyonnyij kommit | Nablyudayemaya granica |
| --- | --- | --- |
| Kornevaya rabota | `cc0b593bbe01eeec905e95d985f7db283cefbf86` | Opublikovanyi uskoreniya politiki putej i proverki ssyilok, adresnyiye testyi i profili; finaljnyij dopusk vperedi |
| Posledovateljnyij arkhiv fuma | `dfa04ed6c03ff3363d175e39f937f8aa118d993c` | 37 novyikh soderzhateljnyikh otvetov; vershina uderzhivayetsya vladeljcem |
| Priyom napravlenij | `e8437b5dfbd8f4541de52d21f6792e3e2cf34d7f` | Opublikovanyi shestj shtatnyikh nablyudenij i ispravleniye XML-transporta; okonchateljnaya sovmestimostj proveryayetsya otdeljno |
| Vnimaniye k README i integracii | `fcfa02d1feb0b10f086dad7acdccccc37544bace` | Opublikovana kontroljnaya tochka; sobstvennyiye finaljnyiye kriterii ostayutsya otkryityimi |
| Telegram | `08b81e1b23fd6541d9dc5fce0ec800a1148b3daf` | Sokhranenyi skvoznyiye scenarii i profilj vosstanovleniya; otkaz scanner yesjhyo otkryit, postavka poka ne gotova |
| Kompaktnyij rabochij kontekst | `05f6c52e513ceced8d790093c94855212f257c29` | Opublikovan sinteticheskij prototip, adresnyiye proverki i profili; zhivoj kontekst i obsjhaya priyomka ostayutsya otdeljnyimi granicami |
| Oflajn-komplekt | `f2a42cb04a347a79c8732b89fc82a142ffe34051` | Opublikovanyi plan, konechnyij inventarj i istochniki licenzij; avtonomnyij zapusk produkta yesjhyo ne vyipolnen |

Dva poslednikh opublikovannyikh checkpoint nezavisimo razbirayutsya pered vklyucheniyem. Ikh roditelj odinakov: `01b329cb49f4c5a5655fab4c16d7ea3a3ebf55a5`. Derevo rabochego konteksta — `c75131e708482473a8d6a4321ebf5d8d4e2ef341`, oflajn-komplekta — `8a879e5e6d96df9dd831870d1079795f33c0ca93`; Git-obyyektyi prochitanyi kornem. Vladeljcyi podtverdili tochnyij udalyonnyij OID i chistoye derevo, vershinyi uderzhivayutsya.

## Tochnyiye derevjya i proiskhozhdeniye

Nezavisimoye chteniye Git-obyyektov podtverdilo po odnomu roditelyu kazhdoj iz pyati postavok. Eto svideteljstvo susjhestvovaniya obyyektov, a ne rezuljtat ikh sovmestnoj proverki.

| Postavka | Derevo | Roditelj |
| --- | --- | --- |
| Kornevaya rabota | `6953b227f8916e8dc2cee30aaa2a3fdfb96ee9b7` | `7a7ddd52d24f437d73b7427a94f77b2165fd16a7` |
| Arkhiv fuma | `79edfa4fa38daf819f84571549248acbfe1af4f7` | `fa89d55955d88bfaba38af55ab1732665128d9a0` |
| Priyom napravlenij | `1d6c46a00f0eb41078dc325350817da9966a880b` | `01b329cb49f4c5a5655fab4c16d7ea3a3ebf55a5` |
| Vnimaniye | `e913420af2c6dcdd1135bf65a3aef27e4c8bffb2` | `e2cafbf720fe983922bbdde93d40141ac8afe15b` |
| Telegram | `ded501d7bd151874b8c299faf68146e14695de35` | `e0b1b92aaa20767f34ca7f11c66a6d7cf51d23df` |

Obsjhiye osnovaniya poluchenyi cherez `git merge-base --all`, a ne vyibranyi po vremeni kommitov:

- Kornevaya rabota i fuma: tekusjhij master `e95d7f5d1ef6387454b7825932cfbd737e600473`.
- Priyom napravlenij i kazhdaya iz ostaljnyikh chetyiryokh postavok: `6bf2f53fc76069b02ba1eae3ed31235716f0f1cd`. Eto takzhe obsjheye osnovaniye pyati postavok.
- Kornevaya rabota ili fuma s vnimaniyem libo Telegram: `a728283474931eda71cd581ca5429121124ba3f6`.
- Vnimaniye i Telegram: `5044b730a77c89d87a23aaec9e02ce7b05960e7f`.

Toljko kornevaya rabota i fuma uzhe soderzhat tekusjhij master v istorii. Sravneniye ostaljnyikh vetok neposredstvenno s nim skryivalo byi ikh dejstviteljnyiye osnovaniya.

## Predmetnyiye peresecheniya

Chisla otnosyatsya k putyam, izmenyonnyim obeimi storonami otnositeljno ikh dejstviteljnoj parnoj bazyi. Peresecheniye putej samo po sebe ne oznachayet tekstovogo konflikta.

| Para | Soderzhateljnyiye puti | Zhurnal | Reyestr i recency | Indeksyi | Proyekciya |
| --- | --- | --- | --- | --- | --- |
| Priyom napravlenij i kornevaya rabota | 18, iz nikh tri JSON uzhe sovpadayut pobajtno | 2 | 2 | 4 | 24 |
| Telegram i kornevaya rabota | 1 | 2 | 2 | 2 | 0 |

V obsjhem smoke-check nuzhno sokhranitj obe deljtyi: prinyatoye v master razmesjheniye proverki voprosov pered proyekciyej i vyideleniye realjnoj SwiftPM-kompozicii v integracionnyiye testyi polnogo profilya. Odnovremennyiye izmeneniya zatragivayut skript, yego testyi i opisaniye navyika. Zamena fajla celikom odnoj storonoj mozhet poteryatj vtoruyu deljtu.

Politika publikacionnyikh putej kornevoj storonyi soderzhit 419 isklyuchenij, storona priyoma — 358. Vtoraya storona dobavlyayet dva samostoyateljnyikh identifikatora: `deferred-assignment-journal-path` i `fixture-native-delegation-xml-text`. Oni otsutstvuyut sredi novyikh zapisej kornevoj storonyi. Pri obyyedinenii sokhranyayutsya tochnyiye obyyavleniya obeikh storon s proverkoj shtatnyim obnovlyayusjhim instrumentom; menjshij fajl ne zamenyayet prinyatyij celikom.

Ostaljnyiye peresecheniya priyoma zatragivayut opisaniye reyestra planirovaniya, kartochki 0201, 0165, 0181, 0183 i 0195, chetyire fajla rabochego konteksta i chetyire trebovaniya. Tri JSON rabochego konteksta uzhe sovpadayut: `детекторы.json`, `паспорт-эксперимента.json`, `сценарии-приёмки.json`. Novyiye optimizacii kornevyikh etapov Q4 i Q5 s ispolnyayemyim kodom priyoma ne peresekayutsya. Nezavisimyikh izmenenij pravil agenta s obeikh storon ne obnaruzheno.

U Telegram yedinstvennoye soderzhateljnoye peresecheniye — opisaniye perevoda obyyavlenij koda. V nyom sokhranyayutsya konechnyij JS-adapter master i dopolneniye o mezhfajlovoj karte Swift. Kornevoj blob `d5ff01c88b0fd17e06485b4c737525506185c8f1`, Telegram blob `da07a923fa34785f9b90976f2994c2d7f9922c28`; peresecheniya ispolnyayemyikh iskhodnikov net.

Proverennyiye izmeneniya prezhnikh zaprosov v obeikh parakh ogranichenyi navigaciyej i recency, iskhodnyiye komandyi sokhranyayutsya. Proizvodnaya proyekciya ne obyyedinyayetsya ruchnyim vyiborom otdeljnyikh fajlov. Pered priyomkoj primenyayetsya yeyo shtatnaya procedura; prezhneye celoye pokoleniye mozhet ostavatjsya toljko yavno ustarevshim svideteljstvom promezhutochnoj kontroljnoj tochki.

## Sokrasjheniye povtornyikh peresborok

Posle nablyudeniya 1527,706 s na primeneniye i 413,496 s na proverku proyekcii macOS VM ostaljnyiye pyatj gotovyikh zadach poluchili razresheniye na promezhutochnyiye checkpoint i exact push posle adresnyikh proverok. Otdeljnyiye full dlya nikh zamenyayutsya sovmestnoj priyomkoj konechnogo sostava; kriterii ostayutsya otkryityimi do neyo. Uzhe nachatyij smoke macOS VM prodolzhayetsya. Finaljnyij polnyij zapusk prinimayusjhej predposyilki master ostayotsya otdeljnyim neobkhodimyim shagom.

Sovmestnaya priyomka zdesj oznachayet odin soglasovannyij priyomochnyij kontur, a ne obesjhaniye odnoj generacii. Dejstvuyusjhiye pravila trebuyut generaciyu i proverku vnutri smoke, zatem otdeljnuyu paru zamyikaniya posle zakryitiya izmenivshegosya otchyota. Trebovaniya podgotovki pokoleniya pri konflikte kanona takzhe sokhranyayutsya; ikh stoimostj uchityivayetsya otdeljno.

## Prinimayusjhaya predposyilka

Tekusjhij master `e95d7f5d1ef6387454b7825932cfbd737e600473` zapresjhayet izmeneniye gitlink pri prodvizhenii. Raneye proverennaya postavka Telegram dobavlyayet `Зависимости/TDLib` na `d1085f9cebc5a62379991ae1652673954f229c1f`; susjhestvuyusjhij LinguisticKit ostayotsya na `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Nedostatochno snyatj zapret: nuzhna tochnaya oflajn-materializaciya, sokhranyonnoye namereniye perekhoda i vosstanovleniye yego promezhutochnyikh sostoyanij bez razresheniya chuzhogo neotslezhivayemogo khvosta.

Otdeljnaya zadacha dopuska gotovit eto izmeneniye bez dobavleniya samogo TDLib v prinimayusjhij master. Posle prinyatiya predposyilki novyij M fiksiruyetsya zanovo, vklyuchayetsya nastoyasjhim sliyaniyem v vedusjhuyu L, a polnyij dopusk svyazyivayet rezuljtat s roditelyami `[L, M]`. Ruchnoye sozdaniye MERGE_HEAD ne ispoljzuyetsya.

## Poryadok obyyedineniya i vladeljcyi

Snachala kornevaya zadacha sokhranyayet tekusjhij podgotoviteljnyij etap i obyyedinyayet zakreplyonnyiye postavki v sobstvennoj vetke. Sobstvennyij `cc0b593bbe01eeec905e95d985f7db283cefbf86` uzhe yavlyayetsya yeyo predkom i povtorno ne vklyuchayetsya. V sostav dobavlyayutsya uderzhivayemyij arkhiv fuma, priyom napravlenij, vnimaniye, proshedshiye adresnyiye proverki novyiye napravleniya i ispravlennaya peredannaya postavka Telegram. Soderzhateljnyiye konfliktyi razreshayutsya do finaljnogo dopuska; chuzhiye indeksyi i vetki ne menyayutsya.

Obyyedinyonnaya vedusjhaya liniya sokhranyayetsya promezhutochnyim kommitom s perechisleniyem ostayusjhikhsya proverok. Vladelec fuma proveryayet rezuljtat i prodvigayet svoyu uderzhivayemuyu vetku fast-forward do togo zhe kommita, yesli prezhnyaya vershina vsyo yesjhyo sovpadayet s soglasovannoj i vkhodit v yego istoriyu. Vtoroye sliyaniye toljko radi peredachi ne sozdayotsya. Pri izmenenii vershinyi snachala soglasuyetsya novyij vkhod.

Polnyij OID vedusjhej linii L opredelyayetsya posle etoj peredachi. Yego yesjhyo net: ni nyineshnij arkhivnyij kommit fuma, ni kornevoj checkpoint ne yavlyayutsya budusjhim L vsego sostava. Novyij master M s otdeljno prinyatyim dopuskom TDLib zaraneye v L ne vklyuchayetsya.

Dlya zaklyuchiteljnogo sliyaniya korenj sozdayot otdeljnyij kandidat ot tochnogo L v svoyej vetke i otdeljnom rabochem dereve. Yedinstvennoye obyichnoye sliyaniye M dayot pered kommitom HEAD=L i MERGE_HEAD=M. Proverennyij rezuljtat C dolzhen imetj roditelej `[L, M]`. Prinimayusjhiye pravila i ispolnyayemyij kontur berutsya iz M; izmeneniye M vozvrasjhayet kandidat k novoj priyomke.

Posle uspeshnogo vyisokogo dopuska i zamyikaniya naznachennyij yedinstvennyij pisatelj pervichnogo master vyipolnyayet shtatnoye prodvizheniye do togo zhe C. Novyij merge poverkh C ne nuzhen. Vladelec fuma zatem mozhet takzhe prodvinutj svoyu vetku ot L do C. Pishusjhiye polnomochiya ne sleduyut iz obsjhego dostupa k Git-obyyektam: pered kazhdoj operaciyej proveryayutsya dejstviteljnyij vladelec dereva i ozhidayemyij ref.

## Blizhajshiye dejstviya

1. Dopolnitj uzhe proverennuyu kartu pyatjyu novyimi promezhutochnyimi kommitami i rezuljtatom tekusjhego smoke macOS VM.
2. Poluchitj ustraneniye otkaza publikacionnoj proverki Telegram i tochnuyu prinimayusjhuyu predposyilku.
3. Sobratj konechnyij sostav v sobstvennom dereve s sokhraneniyem obeikh storon; proizvodnyiye indeksyi obnovitj shtatnyimi avtomatizaciyami.
4. Vyipolnitj primenimyiye adresnyiye proverki i yedinyij finaljnyij kontur po prinyatyim pravilam; toljko zatem prodvigatj celevyiye vetki soglasovannyim sposobom.

Otdeljnyiye uspekhi testov, profilej, push i kontroljnyikh tochek ne dokazyivayut sovmestnuyu rabotosposobnostj etogo sostava.

## Istochnik

- [Iskhodnyiye komandyi i tekusjhij otchyot](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 05:18:32 MSK -->
<!-- content-sha256: sha256:c92282005d87676ed4311ae6b541ed8d494c832ec7fc282c4028ad7fcd80892e -->
<!-- FUM-MD-RECENCY:END -->
