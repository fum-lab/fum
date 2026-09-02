# GUI kak proyekciya vnutrennej pamyati i ispolneniya

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0021 -->

Zhiznesposobnyij GUI korobochnogo FUM dolzhen vyivoditj modelj predstavleniya iz kanonicheskoj pamyati i vnutrennikh operatorov FUM, a poljzovateljskoye dejstviye vozvrasjhatj v tot zhe versionirovannyij sobyitijnyij kontur. Otdeljno podderzhivayemaya domennaya modelj GUI ne mozhet byitj vtoryim istochnikom istinyi.

## Semanticheskiye svyazi

- **zavisit ot:** [vosproizvodimogo shtatnogo popolneniya pamyati](🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md) — GUI obyazan vosproizvodimo proyecirovatj podtverzhdyonnoye sostoyaniye i vozvrasjhatj proveryayemyiye izmeneniya.
- **yavlyayetsya chastjyu:** [polnoekrannogo prilozheniya bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — opredelyayet proiskhozhdeniye soderzhimogo i dejstvij budusjhego poljzovateljskogo interfejsa.
- **dopolnyayet:** [otrisovku interfejsa cherez Metal](🟡-otrisovka-interfejsa-cherez-Metal.md) — zadayot semanticheskij istochnik predstavleniya nezavisimo ot vyibrannogo graficheskogo byekenda.

## Kriterii proverki

- khotya byi odin ekrannyij element vyivoditsya cepochkoj `память/оператор → модель представления → renderer`;
- khotya byi odno dejstviye prokhodit obratnyij putj do proveryayemogo izmeneniya pamyati;
- polnoye vosproizvedeniye podtverzhdayet proiskhozhdeniye modeli predstavleniya i rezuljtata dejstviya;
- gotovyij ekran ne zagruzhayetsya iz seed kak ozhidayemyij snimok;
- ruchnoye sostoyaniye renderer ne soderzhit samostoyateljnoj domennoj istinyi;
- zhiznesposobnostj i dopustimyij seed udovletvoryayut resheniyu [otkryitogo voprosa o granice GUI iz vnutrennikh mekhanizmov FUM](../Voprosyi/2026-07-24_10-44-28_MSK_granica-GUI-iz-vnutrennikh-mekhanizmov-FUM.md).

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: [bezokonnyij prototip](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) uzhe vyivodit inertnuyu deklarativnuyu modelj toljko iz prinyatoj pamyati versionirovannyim operatorom, sokhranyayet proiskhozhdeniye elementov i preobrazuyet dopustimoye namereniye obratno v versionirovannoye sobyitiye. Renderer, ekrannaya priyomka i zhiznesposobnyij GUI yesjhyo ne sozdanyi; sgenerirovannyij Swift-kod otsutstvuyet i ne ispolnyayetsya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [pasport nachaljnogo korobochnogo prototipa FUM](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3f1a6fcff8a12c484383a1672bed1fadd2cdfc6883456da5f85f44a125809384 -->
<!-- FUM-MD-RECENCY:END -->
