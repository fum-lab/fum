# 01. Pamyatj i proiskhozhdeniye

## Naznacheniye

Eto napravleniye uderzhivayet [pamyatj FUM](../../Glossarij/pamyatj-FUM.md) kak proveryayemuyu osnovu proyekta. Vkhodyi, [iskhodnyiye zaprosyi](../../Glossarij/iskhodnyij-zapros.md), istochniki, resheniya, [proizvodnaya dokumentaciya](../../Glossarij/proizvodnaya-dokumentaciya.md), [zhurnal rabot](../../Glossarij/zhurnal-rabot.md), instrumentyi, proverki i kommityi dolzhnyi obrazovyivatj svyaznuyu trassu, a ne nabor razroznennyikh fajlov.

## Proyektnyiye voprosyi

- Kakaya yedinica pamyati yavlyayetsya minimaljno dostatochnoj: zapros, istochnik, dokument, kommit, proverka, zhurnal ili ikh svyazka?
- Kak sokhranyatj proiskhozhdeniye utverzhdenij tak, chtobyi sleduyusjhij agent mog vosstanovitj cepochku bez skryitogo konteksta?
- Kakiye svyazi dolzhnyi proveryatjsya avtomaticheski, a kakiye ostayutsya smyislovoj otvetstvennostjyu rabochej sessii?
- Kak uderzhivatj publikacionnuyu chistotu pri rasshirenii istochnikov, instrumentov i vneshnikh materialov?

## Liniya razvitiya

Blizhnyaya liniya uzhe nachalasj s [papok zaprosov](../../Glossarij/papka-zaprosa.md) v `Журнал/`, kanonicheskikh URL-istochnikov, glossariya i proverki `fum-svyaznostj-rabochej-sessii`. Sleduyusjhij sloj - usilivatj svyazj mezhdu istochnikom, zatronutyimi fajlami, proverkami, instrumentami i budusjhim [reyestrom proiskhozhdeniya FUM](../../Glossarij/reyestr-proiskhozhdeniya-FUM.md).

Eto napravleniye dolzhno razvivatjsya vmeste s MVP-kandidatom [arkhivirovaniya prikreplyayemyikh materialov](../MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md): bez nadyozhnogo vkhodnogo sloya neljzya chestno stroitj [peredavayemyiye rezuljtatyi](../../Glossarij/peredavayemyij-rezuljtat-FUM.md), vesa agentov i nasleduyemyiye [narabotki](../../Glossarij/narabotka.md).

## Blizhajshij proveryayemyij artefakt

Blizhajshij artefakt — pasport dokumentacionnogo prototipa i pervogo vertikaljnogo korobochnogo sreza. On dolzhen opisatj nablyudayemyij kontur chelovek — Codex — Obsidian, otdelitj prinyatyij lokaljnyij [arkhivator istochnikov](../MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) ot proyektiruyemogo korobochnogo servisa i zafiksirovatj pervogo poljzovatelya, scenarij, vkhodyi, vyikhodyi, trassyi proiskhozhdeniya, oshibki, prava, privatnostj i publikacionnyiye granicyi.

Proverka: pasport zadayot avtonomnyij scenarij priyomki bez seti, sekretov i kalendarnoj zavisimosti, ne nachinayet realizaciyu [stadii 02](../stadii/02-korobochnaya-realizaciya-FUM/README.md) i ostavlyayet perekhod zavisimyim ot otdeljnogo resheniya poljzovatelya.

## Proveryayemyiye rezuljtatyi

- Fajl zaprosa soderzhit iskhodnyij tekst, instrumentyi, zatronutyiye fajlyi, proverki i opisaniye rezuljtata.
- Kazhdaya rabochaya sessiya, vliyayusjhaya na proyekt, imeyet otchyot v zhurnale i prokhodit proverku svyaznosti.
- Vneshnij material poluchayet lokaljnuyu papku istochnika, indeks, otchyot izvlecheniya i ssyilku iz zaprosa.
- Poyavlyayetsya minimaljnyij mashinno chitayemyij pasport proiskhozhdeniya rezuljtata.

## Granicyi

Napravleniye ne dolzhno prevrasjhatj planirovaniye v sklad trebovanij bez istochnikov. Novoye trebovaniye fiksiruyetsya cherez zapros i dokumentaciyu, a ne cherez tikhoye dobavleniye punkta v plan. Sekretyi, privatnyiye URL, lokaljnyiye adresa, tokenyi i mashinnyij musor ne stanovyatsya chastjyu otkryitoj [pamyati FUM](../../Glossarij/pamyatj-FUM.md).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii](../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)

## Opornyiye materialyi

- [Modelj pamyati FUM](../../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Obzor proyekta FUM](../../Dokumentaciya/00-obzor-proyekta.md)
- [Dorozhnaya karta FUM](../dorozhnaya-karta.md)
- [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:bd3c3276e6f23b374c38add572981cc29a87e81ddd9b234b0a943f6416bfc6ad -->
<!-- FUM-MD-RECENCY:END -->
