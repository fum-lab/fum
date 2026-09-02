# [Virtualizovannyiye sredyi FUM](../Glossarij/virtualizovannaya-sreda-FUM.md) i dolgovremennaya [pamyatj](../Glossarij/pamyatj-FUM.md)

## Trebovaniye

Vlozhennyiye [FUM-uzlyi](../Glossarij/FUM-uzel.md) dolzhnyi byitj sposobnyi vyistraivatj dlya svoikh [poduzlov](../Glossarij/poduzel-FUM.md) vsyo boleye [virtualizovannuyu sredu FUM](../Glossarij/virtualizovannaya-sreda-FUM.md). Kazhdyij novyij sloj mozhet skryivatj boleye syiroj nizhelezhasjhij interfejs i predostavlyatj poverkh nego boleye organizovannuyu formu [pamyati](../Glossarij/pamyatj-FUM.md), dejstviya, nablyudeniya ili ispolneniya.

Eto trebovaniye rasshiryayet uzhe opisannuyu [modeljnuyu sredu](../Glossarij/modeljnaya-sreda.md). [Modeljnaya sreda](../Glossarij/modeljnaya-sreda.md) opisyivayet mir, proshloye ili vozmozhnoye budusjheye vnutri myishleniya [FUM](../Glossarij/FUM.md). [Virtualizovannaya sreda FUM](../Glossarij/virtualizovannaya-sreda-FUM.md) mozhet byitj ne toljko modeljyu, no i realjnyim programmnyim ili apparatno-sistemnyim sloyem, cherez kotoryij vlozhennyij uzel poluchayet dostup k dolgovremennoj pamyati, vyichisleniyu, servisam ili ustrojstvam.

V terminakh [interfejsa FUM-uzla](../Glossarij/interfejs-FUM-uzla.md) virtualizovannaya sreda yavlyayetsya sposobom predyyavitj vnutrennij interfejs vlozhennyim uzlam. Ona ne prosto skryivayet nizhnij sloj, a zadayot nablyudayemyij kontrakt: chto vlozhennyij uzel vidit, kakiye operacii mozhet vyipolnyatj, kakiye ogranicheniya dejstvuyut i kak elementyi udobnogo interfejsa svyazanyi s nizhelezhasjhim substratom.

## Ot syirogo sloya k interfejsu pamyati

Chastnyij, no vazhnyij primer - organizaciya [pamyati](../Glossarij/pamyatj-FUM.md) na lokaljnoj mashine. Yesli sloj [FUM](../Glossarij/FUM.md) zapusjhen na golom zheleze ili na ochenj nizkom sistemnom urovne, on mozhet zamenitj interfejs syirogo nakopitelya boleye osmyislennyim interfejsom dolgovremennoj [pamyati](../Glossarij/pamyatj-FUM.md).

Takim interfejsom mozhet byitj:

- fajlovaya sistema;
- zhurnal sobyitij;
- graf [pamyati FUM](../Glossarij/pamyatj-FUM.md);
- obyyektnoye ili kontentno-adresuyemoye khranilisjhe;
- sloj versij, proiskhozhdeniya i proverok;
- gibridnaya forma, sovmesjhayusjhaya neskoljko sposobov organizacii dolgovremennogo sostoyaniya.

Fajlovaya sistema zdesj ne yavlyayetsya okonchateljnoj modeljyu [pamyati FUM](../Glossarij/pamyatj-FUM.md). Ona yavlyayetsya odnim iz vozmozhnyikh interfejsov, kotoryij delayet syiroj nakopitelj prigodnyim dlya daljnejshej rabotyi uzlov. Drugoj sloj [FUM](../Glossarij/FUM.md) mozhet poverkh fajlovoj sistemyi postroitj repozitorij, bazu znanij, graf svyazej, [modeljnuyu sredu](../Glossarij/modeljnaya-sreda.md) ili specializirovannyij format [narabotok](../Glossarij/narabotka.md).

## Lokaljnaya vyichisliteljnaya sreda agenta

Celevaya vekha lokaljnogo agenta na vyidelennoj mashine yavlyayetsya prikladnyim sluchayem [virtualizovannoj sredyi FUM](../Glossarij/virtualizovannaya-sreda-FUM.md). Nizhnim sloyem vyistupayut fizicheskaya mashina, operacionnaya sistema, pamyatj, nakopiteli, modeljnyij runtime i lokaljno zapuskayemaya LLM. Poverkh nikh [FUM](../Glossarij/FUM.md) dolzhen predyyavlyatj sebe boleye organizovannyij interfejs: repozitorij [pamyati](../Glossarij/pamyatj-FUM.md), lokaljnyiye avtomatizacii, zhurnal, proverki, [modeljnuyu sredu](../Glossarij/modeljnaya-sreda.md) i servisnyiye adapteryi.

Dlya takogo sloya osobenno vazhno fiksirovatj, gde prokhodit granica lokaljnosti. Yesli vneshnij servis ili vneshnyaya modelj uchastvuyet v rezuljtate, eto dolzhno byitj vidno v trasse i [pamyati FUM](../Glossarij/pamyatj-FUM.md). Yesli rezuljtat poluchen polnostjyu lokaljno, sreda dolzhna sokhranyatj svedeniya o versii modeli, runtime, apparatnom profile i proverkakh, chtobyi posleduyusjhiye uzlyi mogli vosproizvesti ili khotya byi ponyatj usloviya rezuljtata.

Kakiye znacheniya etikh parametrov delayut lokaljnyij sloj dostatochnyim dlya osnovnogo agentskogo cikla, ostayotsya v [otkryitom voprose o kriteriyakh lokaljnoj LLM i vyidelennoj mashinyi](../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md).

## Obsidian-khranilisjhe kak tekusjhij sloj

Tekusjhaya svyazka Codex i Obsidian-khranilisjha yavlyayetsya blizhnim programmnyim primerom [virtualizovannoj sredyi FUM](../Glossarij/virtualizovannaya-sreda-FUM.md). Nizhnim sloyem vyistupayut fajlovaya sistema, Git-repozitorij, Markdown-fajlyi, proverki i agentskaya sreda Codex. Poverkh etogo sloya chelovek vidit Obsidian-khranilisjhe kak navigacionnyij graf i chitayemuyu bazu znanij, a LLM vidit tot zhe material kak nabor fajlov, komand, pravil, ssyilok i proveryayemyikh izmenenij.

V takoj forme [pamyatj FUM](../Glossarij/pamyatj-FUM.md) uzhe ne yavlyayetsya toljko passivnyim khranilisjhem. Ona predyyavlyayet raznyiye interfejsyi raznyim [nablyudatelyam FUM](../Glossarij/nablyudatelj-FUM.md): cheloveku, LLM, Git, proverochnyim skriptam i budusjhim avtomatizaciyam. Prakticheskaya zadacha blizhajshego sloya - opisatj kartu sootvetstviya mezhdu etimi interfejsami: kakoj smyisl Obsidian-grafa sokhranyayetsya v Markdown i Git, kakiye dejstviya Codex ostavlyayet v trasse, kakiye sostoyaniya dostupnyi toljko ekranu cheloveka i gde voznikayut poteri strukturirovannosti.

## Rekursivnostj sloyov

[Virtualizovannaya sreda FUM](../Glossarij/virtualizovannaya-sreda-FUM.md) dolzhna byitj rekursivnoj. Odin sloj poluchayet nizhelezhasjhij substrat, organizuyet yego i predyyavlyayet sleduyusjhemu sloyu novyij kontrakt. Sleduyusjhij sloj mozhet prodelatj to zhe samoye uzhe s etim kontraktom.

Dlya kazhdogo takogo sloya nuzhno razlichatj:

- nizhelezhasjhij substrat: syiroj nakopitelj, fajlovaya sistema, process, setj, servis, ustrojstvo, modelj ili drugaya sreda;
- predyyavlyayemyij interfejs: chto vidit vlozhennyij uzel i kakiye operacii schitayet dopustimyimi;
- kartu sootvetstviya: kak elementyi interfejsa svyazanyi s nizhelezhasjhim substratom;
- proiskhozhdeniye i istoriyu izmenenij;
- [urovni dostupa](../Glossarij/urovenj-dostupa.md), prava peredachi i granicyi publikacii;
- proverki celostnosti, vosstanovleniye posle oshibok i otkaznyiye rezhimyi;
- ogranicheniya, pri kotoryikh interfejs perestayot byitj nadyozhnyim.

Bez takoj yavnoj kartyi virtualizaciya stanovitsya skryityim preobrazovaniyem: vlozhennyij uzel vidit udobnyij interfejs, no [pamyatj FUM](../Glossarij/pamyatj-FUM.md) teryayet vozmozhnostj obyyasnitj, otkuda vzyalisj dannyiye, kak oni byili preobrazovanyi i chto delatj pri povrezhdenii nizhnego sloya.

## Granica s fizicheskim dejstviyem

Sloj, kotoryij rabotayet s realjnyim nakopitelem, ustrojstvom ili golyim zhelezom, otnositsya k daljnemu fizicheskomu i sistemnomu gorizontu [FUM](../Glossarij/FUM.md). Takoye trebovaniye ne razreshayet nemedlennyij perekhod k nebezopasnyim nizkourovnevyim dejstviyam. Realjnaya rabota s apparatnyim nositelem dolzhna prokhoditj cherez otdeljnoye trebovaniye, simulyator ili proveryayemyij kontrakt, ogranicheniya dostupa, nablyudayemuyu trassu i svyazj s [otkryityim voprosom o granicakh apparatnoj avtonomii FUM](../Voprosyi/2026-06-22_07-28-43_MSK_granicyi-apparatnoj-avtonomii-FUM.md).

Blizhnij prakticheskij sloj mozhet byitj polnostjyu programmnyim: simulyator syirogo blochnogo ustrojstva, fikstura s bajtovyim potokom, testovyij format zhurnala, lokaljnyij adapter ili publikacionno chistyij kontrakt. Eto pozvolit proveryatj ideyu organizacii dolgovremennoj [pamyati](../Glossarij/pamyatj-FUM.md) bez riska dlya realjnogo oborudovaniya i dannyikh.

## Skhema sloyov

```mermaid
flowchart TD
    physical["Физический носитель или нижняя среда"] --> raw["Сырой интерфейс: блоки, байты, события"]
    raw --> low_fum["Низкий слой FUM"]
    low_fum --> memory_interface["Интерфейс долговременной памяти"]
    memory_interface --> fs["Файловая система"]
    memory_interface --> graph["Граф памяти"]
    memory_interface --> log["Журнал событий"]
    fs --> upper_fum["Вложенный FUM-узел"]
    graph --> upper_fum
    log --> upper_fum
    upper_fum --> virtual_env["Следующая виртуализованная среда"]
    virtual_env --> inner["Подузлы и внутренние FUM"]
```

## Arkhitekturnyiye sledstviya

- [FUM](../Glossarij/FUM.md) dolzhen proyektirovatj sredu dlya vlozhennyikh uzlov ne toljko kak opisaniye mira, no i kak predyyavlyayemyij interfejs k dolgovremennomu sostoyaniyu.
- Organizaciya [pamyati](../Glossarij/pamyatj-FUM.md) dolzhna dopuskatj neskoljko interfejsov poverkh odnogo nizhnego sloya: fajlovyij, grafovyij, zhurnaljnyij, obyyektnyij ili inoj.
- Kazhdyij sloj virtualizacii dolzhen sokhranyatj proiskhozhdeniye, ogranicheniya, kartu preobrazovanij i proverki vosstanovleniya.
- Boleye vyisokij sloj ne dolzhen schitatj nizhnij sloj prozrachnyim ili beskonechno nadyozhnyim: povrezhdeniya, chastichnaya poterya dannyikh, nesovmestimostj versij i ogranicheniya dostupa dolzhnyi byitj vidimyi v [pamyati](../Glossarij/pamyatj-FUM.md).
- Sloj virtualizacii ne dolzhen prevrasjhatjsya v skryituyu totaljnuyu vlastj nad [poduzlami](../Glossarij/poduzel-FUM.md): interfejsyi dostupa i prava izmeneniya dolzhnyi ostavatjsya yavnyimi.
- Budusjhaya apparatnaya realizaciya dolzhna byitj sovmestima s programmnyimi simulyatorami i kontraktami, chtobyi [obsjhiye skhemyi FUM](../Glossarij/obsjhaya-skhema-FUM.md) mozhno byilo proveryatj do fizicheskogo ispolneniya.

## Blizhnij proveryayemyij sloj

Minimaljnyij proveryayemyij sleduyusjhij shag - opisatj kontrakt virtualizovannogo sloya dolgovremennoj [pamyati](../Glossarij/pamyatj-FUM.md): nizhelezhasjhij substrat, predyyavlyayemyij interfejs, operacii chteniya i zapisi, kartu sootvetstviya, proverki celostnosti, vosstanovleniye posle sboya, [urovni dostupa](../Glossarij/urovenj-dostupa.md) i format nablyudayemoj trassyi.

Takoj kontrakt dolzhen snachala rabotatj na lokaljnoj bezopasnoj fiksture, a ne na realjnom syirom nakopitele. Posle etogo yego mozhno budet rassmatrivatj kak [obsjhuyu skhemu FUM](../Glossarij/obsjhaya-skhema-FUM.md), prigodnuyu dlya perenosa mezhdu fajlovoj sistemoj, grafom [pamyati](../Glossarij/pamyatj-FUM.md), zhurnalom sobyitij i budusjhimi nizkourovnevyimi realizaciyami.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-25 18:50:18 MSK](../Zhurnal/2026-06-25_18-50-18_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 19:50:33 MSK](../Zhurnal/2026-06-25_19-50-33_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 09:55:41 MSK](../Zhurnal/2026-06-26_09-55-41_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-26 10:34:02 MSK](../Zhurnal/2026-06-26_10-34-02_MSK/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:9795fb88eb9b2decc76d9af9c557200725728d125b6000470e991ea9288412e1 -->
<!-- FUM-MD-RECENCY:END -->
