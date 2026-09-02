# Pamyatj FUM

Pamyatj FUM - svyaznaya, proveryayemaya i publikuyemaya sistema khraneniya trebovanij, reshenij, proiskhozhdeniya izmenenij, vnutrennikh sostoyanij, rabochikh shagov, iskhodnyikh tekstov [avtomatizacij FUM](avtomatizaciya-FUM.md), [opisanij FUM dlya adresatov](opisaniye-FUM-dlya-adresata.md), [zhurnala rabot](zhurnal-rabot.md) i ustojchivyikh patternov.

Na stadii [dokumentacionnogo prototipa FUM](dokumentacionnyij-prototip-FUM.md) preobladayusjhij obsjhij smyislovoj sloj pamyati predstavlyayet soboj adresuyemyij i versioniruyemyij tekst, formiruyemyij v sovmestnom konture cheloveka i LLM. Iskhodnyiye formulirovki i namereniya porozhdayet chelovek, a proizvodnyiye tekstyi v osnovnom porozhdayet i pererabatyivayet LLM vo vneshnej agentskoj sessii Codex. Tekstyi ne slivayutsya v bezyimyannyij korpus: [iskhodnyiye zaprosyi](iskhodnyij-zapros.md) sokhranyayutsya doslovno, ikh otchyotyi i sobstvennyiye artefaktyi obyyedinyayutsya obsjhej [papkoj zaprosa](papka-zaprosa.md), a proizvodnyiye materialyi svyazyivayutsya s istochnikami, rabochej sessiyej, proverkami i Git-istoriyej.

Eto priblizhyonnoye opisaniye smyislovogo sloya, a ne ischerpyivayusjhaya ontologiya ili pobajtovaya inventarizaciya. Kod, strukturirovannyiye dannyiye, ssyilki, metadannyiye, testyi, vneshniye istochniki, vlozheniya i Git-istoriya tozhe vkhodyat v pamyatj i ne svodyatsya k dvum tekstovyim sloyam.

Kirillicheskij sloj repozitoriya yavlyayetsya yedinstvennyim kanonicheskim rabochim istochnikom. Vmeste s nim dolzhna khranitjsya polnostjyu vyivodimaya [bratislavskaya versiya pamyati](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md): russkoye soderzhaniye i kazhdyij kirillicheskij komponent polnogo puti preobrazuyutsya v [bratislavskij yazyik](bratislavskij-yazyik.md) zakreplyonnyim LinguisticKit-kontraktom. Eta versiya ne redaktiruyetsya vruchnuyu, ne vozvrasjhayetsya vo vkhod generatora i ne stanovitsya vtoryim istochnikom trebovanij; manifest proiskhozhdeniya svyazyivayet kazhdyij iskhodnyij putj i khyesh s proizvodnyim putyom i khyeshem.

Pamyatj FUM dolzhna byitj ne toljko arkhivom. Ona yavlyayetsya sredoj myishleniya, gde [iskhodnyiye zaprosyi](iskhodnyij-zapros.md), [navigaciya po pamyati FUM](navigaciya-po-pamyati-FUM.md), [proizvodnaya dokumentaciya](proizvodnaya-dokumentaciya.md), adresnyiye [opisaniya FUM](opisaniye-FUM-dlya-adresata.md), [avtomatizacii](avtomatizaciya-FUM.md), kompaktnyiye opisaniya ot [avtomaticheskikh organov vospriyatiya FUM](avtomaticheskij-organ-vospriyatiya-FUM.md), [agentskiye ciklyi](agentskij-cikl.md), [zhurnal rabot](zhurnal-rabot.md), [narabotki](narabotka.md) i kommityi obrazuyut razvivayusjhijsya process.

[Kartochki sboyev](kartochka-sboya.md) prevrasjhayut nablyudayemyiye oshibki i propuski etogo processa v dolgovechnuyu diagnosticheskuyu pamyatj. Odna kartochka obyyedinyayet dokazannyiye proyavleniya obsjhego predpolagayemogo mekhanizma, otdelyayet fakt ot gipotezyi prichinyi i porozhdayet otdeljnyiye atomarnyiye [kartochki shagov](kartochka-shaga.md) issledovaniya i sistemnogo ustraneniya. Povtor posle raznyikh rabochikh sessij poetomu usilivayet odnu adresuyemuyu zapisj, a ne rastvoryayetsya v razroznennyikh otchyotakh; zaversheniye shaga ne zakryivayet sboj bez proveryayemogo predotvrasjheniya libo ogranichennogo vosstanovleniya.

V modeli nepreryivnosti agenta pamyatj imeyet neskoljko razlichimyikh rolej. Operativnaya pamyatj delayet predstavleniye proshlogo prichinno dostupnyim tekusjhemu sostoyaniyu rassmatrivayemoj sistemyi; dostatochno li etoj svyazi dlya nepreryivnosti togo zhe agenta, ostayotsya otkryityim. Nasleduyemaya konfiguraciya peredayot formyi informacionnyim potomkam; vneshnij yazyikovoj, kuljturnyij ili arkhivnyij sled mozhet sokhranyatjsya vne iskhodnogo agenta. Odin material sposoben vyipolnyatj neskoljko rolej, no nalichiye vneshnego sleda ili skhodnogo vosstanovleniya samo po sebe ne dokazyivayet nepreryivnostj [lichnosti agenta FUM](lichnostj-agenta-FUM.md).

[Upravlyayemoye zabyivaniye FUM](upravlyayemoye-zabyivaniye-FUM.md) izmenyayet ne kanonicheskoye proshloye, a pryamoye operacionnoye vliyaniye proizvodnoj strukturyi v zadannom rabochem konture. Mekhanizm mozhet oslabnutj nizhe svoyego poroga i perestatj rabotatj pri nenulevom vese; nolj yavlyayetsya lishj dopustimyim predelom. Pri dopustimyikh resursakh i pravilakh khraneniya yego identichnostj, soderzhimoye i proiskhozhdeniye ostayutsya v kholodnom arkhive; novaya potrebnostj zapuskayet otdeljnoye [vspominaniye FUM](vspominaniye-FUM.md) s vosstanovleniyem i povtornoj proverkoj. Bezvozvratnostj utverzhdayetsya toljko dlya nazvannoj oblasti vosstanovleniya, v kotoroj ustojchivo ne ostalosj dostatochnogo razreshyonnogo osnovaniya.

[Profilj vnimaniya FUM](profilj-vnimaniya-FUM.md) svyazyivayet etu dinamiku s nablyudayemyimi oshibkami i predskazuyemostjyu. Znachimyiye povtoryayemyiye oshibki mogut povyisitj chastotu izvlecheniya, proverki i osvezheniya proizvodnoj strukturyi libo zapustitj vspominaniye; ustojchivaya kalibrovannaya predskazuyemostj pri dostatochnom nablyudenii mozhet umenjshitj yeyo obyichnuyu dostupnostj. Ponizheniye vnimaniya ne udalyayet pervichnuyu zapisj i ne dokazyivayet neaktualjnostj: profilj sokhranyayet storozhevoye nablyudeniye i otdelyayetsya ot aktivnogo vesa mekhanizma, klassa khraneniya i polnomochij dostupa.

V [lichnom FUM-agente](lichnyij-FUM-agent.md) na odnoj mashine razreshyonnaya imenno k dolgovremennomu khraneniyu vkhodnaya sensornaya informaciya pri dostatochnom byudzhete obrazuyet zasjhisjhyonnyij pervichnyij sloj. Yego rolj mozhet vyipolnyatj syiroj zakhvat libo zaraneye razreshyonnoye proiskhozhdyonnoye szhatiye, prinyatoye kak yedinstvennaya kanonicheskaya zapisj; oni ne smeshivayutsya mezhdu soboj. Proizvodnyiye II-strukturyi mogut zabyivatjsya i perestraivatjsya, a u pervichnoj zapisi otdeljno menyayutsya klass khraneniya i prioritet izvlecheniya bez avtomaticheskoj poteri soderzhimogo i proiskhozhdeniya.

Dlya sovmestnogo kontura cheloveka i LLM osobenno vazhen tekstovo-yazyikovoj sloj etoj sredyi. [Tekstovo-yazyikovyiye strukturiruyusjhiye operatoryi FUM](tekstovo-yazyikovoj-strukturiruyusjhij-operator-FUM.md) delayut odnu vneshnyuyu simvolicheskuyu formu dostupnoj obeim storonam v predelakh razreshyonnogo dostupa dlya chteniya, porozhdeniya, proverki, ispravleniya, poiska, versionirovaniya i povtornogo vvedeniya v kontekst, ne podmenyaya yeyu pervichnyiye istochniki i drugiye modaljnosti pamyati.

V tekstovom voplosjhenii [lichnogo FUM-agenta](lichnyij-FUM-agent.md) pamyatj mozhet predyyavlyatjsya kak Obsidian-podobnaya sistema vzaimosvyazannyikh tekstov, no yeyo smyislovaya svyaznostj ne dolzhna zavisetj ot ruchnoj rasstanovki vsekh ssyilok. Ispolniteljnyij sloj s pomosjhjyu [sistemyi strukturiruyusjhikh operatorov FUM](sistema-strukturiruyusjhikh-operatorov-FUM.md) avtomaticheski vyiyavlyayet vozmozhnyiye otnosheniya mezhdu adresuyemyimi fragmentami i sozdayot proveryayemyiye vozmozhnosti [semanticheskogo perekhoda](navigaciya-po-pamyati-FUM.md); yavnaya ssyilka ostayotsya odnoj iz proyekcij takoj svyazi.

## Svyazannyiye dokumentyi

- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Bratislavskaya versiya pamyati FUM](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)
- [Obzor proyekta FUM](../Dokumentaciya/00-obzor-proyekta.md)
- [Vosproizvodimyiye avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Opisaniya FUM dlya adresatov](../Dokumentaciya/18-opisaniya-FUM-dlya-adresatov.md)
- [Zhurnal rabot](../Zhurnal/README.md)
- [Kartochki sboyev FUM](../Sboi/README.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-06 22:29:49 MSK — Vvesti kartochki sboyev dlya porozhdeniya shagov](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-31 14:01:03 MSK - Zakrepitj otbor profilya vnimaniya FUM](../Zhurnal/2026-07-31_14-01-03_MSK_zakrepitj-otbor-profilya-vnimaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-31 12:25:42 MSK - Utochnitj sokhraneniye vkhodnoj sensornoj informacii](../Zhurnal/2026-07-31_12-25-42_MSK_utochnitj-sokhraneniye-vkhodnoj-sensornoj-informacii/zapros.md)
- [iskhodnyij zapros 2026-07-31 12:20:47 MSK - Utochnitj vspominaniye i bezvozvratnoye zabyivaniye](../Zhurnal/2026-07-31_12-20-47_MSK_utochnitj-vspominaniye-i-bezvozvratnoye-zabyivaniye/zapros.md)
- [iskhodnyij zapros 2026-07-31 11:57:37 MSK - Zakrepitj upravlyayemoye zabyivaniye FUM](../Zhurnal/2026-07-31_11-57-37_MSK_zakrepitj-upravlyayemoye-zabyivaniye-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-14 00:14:49 MSK - Zakrepitj operatoryi teksta i yazyika vo vneshnej pamyati](../Zhurnal/2026-07-14_00-14-49_MSK_zakrepitj-operatoryi-teksta-i-yazyika-vo-vneshnej-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-14 00:36:30 MSK - Utochnitj tekstovyij sostav pamyati dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-14_00-36-30_MSK_utochnitj-tekstovyij-sostav-pamyati-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-14 01:15:40 MSK - Zakrepitj avtomaticheskiye semanticheskiye svyazi lichnogo FUM](../Zhurnal/2026-07-14_01-15-40_MSK_zakrepitj-avtomaticheskiye-semanticheskiye-svyazi-lichnogo-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-14 01:55:34 MSK - Integrirovatj rekursivnuyu modelj agenta i sredyi](../Zhurnal/2026-07-14_01-55-34_MSK_integrirovatj-rekursivnuyu-modelj-agenta-i-sredyi/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:00:56 MSK -->
<!-- content-sha256: sha256:a479c544da1311b6f33b2065b73ca9c61d59ecbfcac9e30e4d7555fe94f40727 -->
<!-- FUM-MD-RECENCY:END -->
