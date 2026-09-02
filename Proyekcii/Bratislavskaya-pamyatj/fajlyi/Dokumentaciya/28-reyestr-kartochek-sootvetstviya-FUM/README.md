# Reyestr kartochek sootvetstviya FUM

Reyestr kartochek sootvetstviya FUM nuzhen dlya masshtabirovaniya modeli ot pervogo inzhenernogo primera k boleye shirokim tekhnicheskim, issledovateljskim i fizicheskim sloyam. Yesli Git uzhe pokazyivayet, kak [vetka rabotyi](../../Glossarij/vetka-rabotyi.md), commit, proverka i [reyestr proiskhozhdeniya FUM](../../Glossarij/reyestr-proiskhozhdeniya-FUM.md) mogut byitj nositelyami [evolyucionnoj cepochki FUM](../../Glossarij/evolyucionnaya-cepochka-FUM.md), to sleduyusjhij shag - khranitj takiye sopostavleniya kak yavnyiye [kartochki sootvetstviya FUM](../../Glossarij/kartochka-sootvetstviya-FUM.md).

Kartochka sootvetstviya ne dokazyivayet, chto dva urovnya tozhdestvennyi. Ona pokazyivayet, kakoj fragment [obsjhej skhemyi FUM](../../Glossarij/obsjhaya-skhema-FUM.md) viden v konkretnom instrumente, srede ili fizicheskoj ramke, kakiye invariantyi sokhranyayutsya pri perenose, gde voznikayut poteri i kakaya proverka mozhet usilitj ili oslabitj sopostavleniye.

Reyestr khranitsya papkoj vnutri `Документация/`, potomu chto kartochka dolzhna chitatjsya chelovekom kak otdeljnyij material, a ne kak stroka boljshoj tablicyi. Vkhodnoj fajl zadayot navigaciyu, shablon i pravila popolneniya; kazhdaya kartochka lezhit v sobstvennom Markdown-fajle ryadom s nim.

Takoj reyestr zasjhisjhayet proyekt srazu s dvukh storon. S inzhenernoj storonyi on pomogayet perenositj udachnyiye patternyi mezhdu Git, lokaljnyimi avtomatizaciyami, interfejsami, virtualizovannyimi sredami i budusjhej [korobochnoj realizaciyej FUM](../../Glossarij/korobochnaya-realizaciya-FUM.md). S issledovateljskoj storonyi on ne dayot fizicheskim i disciplinarnyim analogiyam statj rasplyivchatoj deklaraciyej: obsjhaya teoriya otnositeljnosti, kvantovaya mekhanika, khimiya, biologiya, ekonomika, psikhologiya, psikhofiziologiya i psikhiatriya dolzhnyi vkhoditj v pamyatj FUM cherez proveryayemyiye kartyi sootvetstvij s granicami primenimosti.

## Shablon kartochki

Minimaljnaya kartochka sootvetstviya fiksiruyet:

- identifikator kartochki;
- obyyekt sopostavleniya: instrument, sloj, sredu, nauchnuyu ramku ili fizicheskij analog;
- urovenj opisaniya i profilj [nablyudatelya FUM](../../Glossarij/nablyudatelj-FUM.md);
- elementyi [obsjhej skhemyi FUM](../../Glossarij/obsjhaya-skhema-FUM.md), kotoryiye sopostavlyayutsya s obyyektom;
- sokhranyayemyiye invariantyi;
- poteri nablyudayemosti i neodnoznachnosti;
- marshrut k iskhodnomu ili boleye polnomu istochniku informacii libo yavnuyu otmetku nevozmozhnosti takogo perekhoda;
- granicyi analogii i usloviya, pri kotoryikh kartochka perestayot byitj primenimoj;
- proverku ili kriterij oproverzheniya;
- istochniki trebovanij, opornyiye dokumentyi i status uverennosti.

Kartochka dolzhna byitj dostatochno korotkoj, chtobyi sluzhitj navigacionnoj yedinicej, no dostatochno strogoj, chtobyi po nej mozhno byilo ponyatj, chto imenno perenositsya mezhdu urovnyami. Yesli sopostavleniye neljzya proveritj ili khotya byi ogranichitj usloviyami primenimosti, ono ostayotsya zametkoj ili [gipotezoj FUM](../../Glossarij/gipoteza-FUM.md), a ne zreloj kartochkoj sootvetstviya.

Kartochka sootvetstviya opisyivayet konceptualjnoye sopostavleniye ili granicu analogii i ne zamenyayet napravlennoye [preobrazovaniye mezhdu nablyudatelyami FUM](../../Glossarij/preobrazovaniye-mezhdu-nablyudatelyami-FUM.md). Yesli realjnyij iskhodnyij signal perevoditsya v drugoye predstavleniye, yego karta signalov, poteri, obratimostj i marshrut fiksiruyutsya po otdeljnomu [minimaljnomu formatu preobrazovaniya](../38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md); kartochka mozhet ssyilatjsya na takuyu zapisj kak na dokazateljstvo.

## Kartochki

- [FUM-MAP-GIT-01](FUM-MAP-GIT-01.md) - Git-infrastruktura evolyucionnyikh cepochek kak inzhenernyij nositelj otbora.
- [FUM-MAP-SESSION-01](FUM-MAP-SESSION-01.md) - rabochaya sessiya chelovek - Codex - repozitorij kak dokumentacionnyij prototip malogo cikla FUM.
- [FUM-MAP-AUTO-01](FUM-MAP-AUTO-01.md) - lokaljnyiye avtomatizacii FUM kak ispolnyayemyij sloj pamyati.
- [FUM-MAP-SILICON-01](FUM-MAP-SILICON-01.md) - kremniyevyij substrat i mikrochipnaya lokaljnostj kak apparatnyij inzhenernyij sloj.
- [FUM-MAP-PHYS-01](FUM-MAP-PHYS-01.md) - okruzhayusjhaya sreda, fizika, khimiya, biologiya i ekonomika kak fiziko-issledovateljskij gorizont.
- [FUM-MAP-BRAIN-01](FUM-MAP-BRAIN-01.md) - parnaya mezhpolusharnaya organizaciya kak biologicheskaya analogiya lokaljnyikh podsistem i yavnogo kanala koordinacii.

## Pravila popolneniya

Novaya kartochka dobavlyayetsya v reyestr toljko vmeste s istochnikom trebovaniya ili yavno ukazannyim opornyim materialom. Dlya tekhnicheskogo instrumenta nuzhno pokazatj, kakuyu rabotu on realjno vyipolnyayet v konture FUM: nablyudeniye, pamyatj, porozhdeniye variantov, otbor, peredachu, proverku, nasledovaniye, marshrutizaciyu ili ogranicheniye dostupa.

Kartochka ne dolzhna stanovitjsya tupikom navigacii. Yesli ona szhimayet trassu, perevodit mashinnyij sloj v chelovecheskoye opisaniye ili svyazyivayet raznyiye nablyudateljskiye predstavleniya, v nej dolzhen byitj perekhod k istochniku polnoj informacii. Kogda perekhod nevozmozhen, kartochka fiksiruyet ne toljko samu poteryu, no i prichinu: tekhnicheskuyu neobratimostj, publikacionnoye ogranicheniye, otsutstvuyusjhij dostup, granichnyij sluchaj nablyudeniya ili utrachennuyu svyazj proiskhozhdeniya.

Dlya fizicheskoj, nauchnoj ili disciplinarnoj analogii trebovaniya strozhe. Kartochka dolzhna yavno otdelyatj perenos arkhitekturnoj disciplinyi ot utverzhdeniya fizicheskoj teorii, klinicheskogo vyivoda ili gotovogo nauchnogo obyyasneniya, ukazyivatj profilj nablyudatelya, urovenj opisaniya, sokhranyayemyiye invariantyi, poteri i usloviya oproverzheniya. Chem daljshe sloj ot tekusjhego inzhenernogo nositelya, tem vazhneye status uverennosti i svyazj s [otkryityimi voprosami](../../Glossarij/otkryityij-vopros.md).

Yesli kartochka nachinayet povtoryatjsya kak procedura, yeyo sleduyusjhij zrelyij vid dolzhen statj lokaljnoj avtomatizaciyej, proveryayemyim shablonom ili mashinno chitayemyim reyestrom. Do etogo tekusjhaya papka sluzhit chelovekochitayemyim reyestrom i mestom, gde vidna cepochka: zapros -> karta sootvetstviya -> proverka -> commit.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 11:50:58 MSK - Opisatj minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:33:38 MSK](../../Zhurnal/2026-07-02_11-33-38_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 13:36:52 MSK](../../Zhurnal/2026-07-02_13-36-52_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-13 23:39:13 MSK - Zakrepitj parnuyu arkhitekturu chelovecheskogo mozga](../../Zhurnal/2026-07-13_23-39-13_MSK_zakrepitj-parnuyu-arkhitekturu-chelovecheskogo-mozga/zapros.md)

## Opornyiye dokumentyi

- [Evolyuciya i myishleniye](../03-evolyuciya-i-myishleniye.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](../26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md)
- [Arkhitektura FUM](../22-arkhitektura-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2ab087183a6da0ae8a207bed14ead209d51c77af513a7f5db83829444ff1e654 -->
<!-- FUM-MD-RECENCY:END -->
