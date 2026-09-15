# GUI kak proyekciya vnutrennej pamyati i ispolneniya

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0021 -->

Zhiznesposobnyij GUI korobochnogo FUM dolzhen vyivoditj modelj predstavleniya iz kanonicheskoj pamyati i vnutrennikh operatorov FUM, a poljzovateljskoye dejstviye vozvrasjhatj v tot zhe versionirovannyij sobyitijnyij kontur. Otdeljno podderzhivayemaya domennaya modelj GUI ne mozhet byitj vtoryim istochnikom istinyi.

## Semanticheskiye svyazi

- **zavisit ot:** [vosproizvodimogo shtatnogo popolneniya pamyati](🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md) — GUI obyazan vosproizvodimo proyecirovatj podtverzhdyonnoye sostoyaniye i vozvrasjhatj proveryayemyiye izmeneniya.
- **yavlyayetsya chastjyu:** [polnoekrannogo prilozheniya bez sistemnoj obolochki](🟡-polnoekrannoye-prilozheniye-bez-sistemnoj-obolochki.md) — opredelyayet proiskhozhdeniye soderzhimogo i dejstvij budusjhego poljzovateljskogo interfejsa.
- **dopolnyayet:** [otrisovku interfejsa cherez Metal](🟡-otrisovka-interfejsa-cherez-Metal.md) — zadayot semanticheskij istochnik predstavleniya nezavisimo ot vyibrannogo graficheskogo byekenda.

- **dopolnyayetsya:** [Universaljnoye parametricheskoye 3D i vizualizaciya FUMA](🟡-universaljnoye-parametricheskoye-3D-i-vizualizaciya-FUMA.md) — primenyayet obsjhij kanonicheskij istochnik predstavleniya i obratnyikh dejstvij k parametricheskim prostranstvennyim scenam.

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

- [Otkryitj parametricheskoye 3D FUMA](../Zhurnal/2026-09-11_20-37-47_MSK_prinyatj-parametricheskoye-3D-FUMA/zapros.md).

- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [pasport nachaljnogo korobochnogo prototipa FUM](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 20:52:00 MSK -->
<!-- content-sha256: sha256:c4d44bc0749e0248c9426e2c13cfa0b83e6a86885873e3dc30b1e6af98e60e06 -->
<!-- FUM-MD-RECENCY:END -->
