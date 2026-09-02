# Korobochnaya realizaciya FUM

Korobochnaya realizaciya FUM - celevaya postavlyayemaya forma [FUM](FUM.md), v kotoroj osnovnyiye dannyiye, [pamyatj](pamyatj-FUM.md), interfejsyi, lokaljnyiye [avtomatizacii](avtomatizaciya-FUM.md), proverki, pravila dostupa i vosproizvodimyij runtime sobranyi v rabotayusjhij produktovyij kontur, a ne toljko opisanyi v dokumentacii.

Korobochnaya realizaciya dolzhna nasledovatj proveryayemyiye kontraktyi [dokumentacionnogo prototipa FUM](dokumentacionnyij-prototip-FUM.md), no ne obyazana kopirovatj konkretnyiye instrumentyi pervoj rabochej sredyi. Dlya FUM vazhno perenesti strukturu: sokhraneniye vkhodov, proiskhozhdeniye reshenij, svyaznuyu pamyatj, podtverzhdeniya dejstvij, trassyi, lokaljnyiye proverki, urovni dostupa i vozmozhnostj popolnyatj sistemu neobkhodimyimi dannyimi.

Inzhenernyij start korobochnoj realizacii ne tozhdestven pervomu poljzovateljskomu vyipusku. Vsya nachaljnaya inzhenernaya stadiya mozhet sostoyatj iz posledovateljnyikh lokaljnyikh Swift-srezov bez sobstvennogo GUI FUM: oni vosproizvodimo proigryivayut versionirovannoye shtatnoye popolneniye [pamyati FUM](pamyatj-FUM.md), primenyayut ogranichennyiye vnutrenniye mekhanizmyi pamyati i ispolneniya i sokhranyayut kanonicheskiye snimki s trassoj proiskhozhdeniya. Vneshnyaya sessiya Codex mozhet byitj yedinstvennoj inzhenernoj poverkhnostjyu dlya ikh zapuska, analiza i testirovaniya cherez versionirovannyiye komandyi, fajlyi, standartnyiye potoki, kodyi zaversheniya i mashinochitayemyiye otchyotyi.

Takoye upravleniye ne delayet Codex chastjyu postavki ili sobstvennyim runtime FUM i ne otmenyayet budusjhij interfejs. Graficheskaya obolochka dobavlyayetsya ne kak paralleljnyij ruchnoj istochnik sostoyaniya, a posle zhiznesposobnosti bezokonnogo kontura — kak proyekciya toj zhe pamyati i tekh zhe ispolnyayemyikh mekhanizmov s obratnyim vozvratom poljzovateljskikh dejstvij v proveryayemyiye sobyitiya.

Pervaya poljzovateljskaya versiya korobochnoj realizacii dolzhna byitj oformlena kak yedinoye lokaljnoye prilozheniye. Eto oznachayet, chto poljzovatelj zapuskayet odin postavlyayemyij kontur dlya namereniya, poiska konteksta, podtverzhdeniya dejstvij, vyipolneniya lokaljnyikh avtomatizacij, proverki i sokhraneniya rezuljtata, dazhe yesli vnutri prilozheniya ostayutsya otdeljnyiye moduli, CLI-komandyi, runtime-komponentyi i diagnosticheskiye instrumentyi.

V otlichiye ot diskretnyikh soobsjhenij-zadach [dokumentacionnogo prototipa](dokumentacionnyij-prototip-FUM.md), korobochnyij FUM dolzhen nablyudatj razreshyonnyij chelovecheskij vvod vo vremya aktivnogo [agentskogo cikla](agentskij-cikl.md) na urovne sobyitij. Znachimoye sobyitiye primenyayetsya k celi, prioritetu ili vetke rabotyi na bezopasnoj kontroljnoj tochke i mozhet izmenitj posleduyusjhuyu nablyudayemuyu trayektoriyu cikla. Eto ne trebuyet otdeljnogo vyizova LLM na kazhdoye sobyitiye, ne oznachayet skryitogo globaljnogo sbora vvoda i ne delayet skryityiye rassuzhdeniya modeli chastjyu nablyudayemoj trayektorii.

Yesli konkretnyij vneshnij perekhod trebuyet poljzovateljskogo podtverzhdeniya, korobochnyij FUM parkuyet toljko etot perekhod. On prodolzhayet bezopasnyiye i produktivnyiye dejstviya v [modeljnoj srede](modeljnaya-sreda.md) toljko v predelakh nezavisimo razreshyonnyikh dlya epizoda provajdera, lokaljnogo ili udalyonnogo rezhima, raskryivayemyikh dannyikh i limitov vyizovov, tokenov i deneg, pri neobkhodimosti sravnivayet neskoljko nasleduyusjhikh obsjheye sostoyaniye variantov i sokhranyayet modeljnyij vyibor otdeljno ot podtverzhdeniya, avtorizacii i ispolneniya. Ozhidaniye otveta ne rasshiryayet eti predelyi.

Produktovyij runtime mozhet ispoljzovatj svobodnyij vyichisliteljnyij resurs dlya [fonovyikh zadanij FUM](fonovoye-zadaniye-FUM.md), no toljko pri otsutstvii neobrabotannogo poljzovateljskogo vvoda i gotovyikh zadach boleye vyisokogo prioriteta. Takoj rezhim dolzhen byitj ogranichennyim, nablyudayemyim i vyitesnyayemyim, a yego nalichiye ne dayot sisteme dopolniteljnyikh prav na vneshneye dejstviye.

## Svyazannyiye dokumentyi

- [Lokaljnyij agent FUM na vyidelennoj mashine](../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md)
- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)
- [MVP-kandidat: yedinaya tochka lokaljnoj rabotyi](../Planirovaniye/MVP-kandidatyi/06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-29 10:25:10 MSK - Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:10:35 MSK - Razreshitj nachaljnuyu korobochnuyu FUM bez GUI cherez Codex](../Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-14 03:18:36 MSK - Zakrepitj fonovyiye zadaniya dlya prostoya LLM](../Zhurnal/2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK - Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK - Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:02771fb1a0783ef5780a93f5d353be3c6b33d23192c03792bc17d8da58d7d91a -->
<!-- FUM-MD-RECENCY:END -->
