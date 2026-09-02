# [Otkryityij vopros](../Glossarij/otkryityij-vopros.md): granica GUI iz vnutrennikh mekhanizmov FUM

Bezokonnyij Swift-kontur mozhet nachatj [shtatnoye popolneniye pamyati FUM](../Glossarij/shtatnoye-popolneniye-pamyati-FUM.md) do otveta na etot vopros. Neopredelyonnostj stanovitsya blokiruyusjhej na granice, gde inertnuyu modelj predstavleniya predpolagayetsya priznatj zhiznesposobnyim GUI, sozdannyim na osnove vnutrennikh mekhanizmov pamyati i ispolneniya FUM.

## Neodnoznachnostj

Trebovaniye dopuskayet neskoljko susjhestvenno raznyikh traktovok: FUM mozhet poroditj deklarativnoye derevo dlya fiksirovannogo renderer, skomponovatj nabor zaraneye razreshyonnyikh vidzhetov, sformirovatj SwiftUI/Swift-kod ili izmenyatj sobstvennyij ispolnyayemyij sloj. Eti variantyi razlichayutsya vosproizvodimostjyu, bezopasnostjyu i tem, kakaya chastj rezuljtata dejstviteljno vyivedena iz pamyati, a kakaya zaraneye zashita v seed ili obolochku.

Bez dopolniteljnoj granicyi gotovyij ekran legko oshibochno prinyatj za vnutrenne sozdannyij GUI. Naprotiv, trebovaniye polnoj samogeneracii vsego renderer na pervom shage mozhet sdelatj proveryayemyij perekhod nedostizhimyim i neopravdanno razreshitj ispolneniye porozhdyonnogo koda.

## Voprosyi dlya proyasneniya

- Schitayetsya li dostatochnyim pervyim rezuljtatom inertnoye deklarativnoye derevo predstavleniya, vyivedennoye iz kanonicheskoj pamyati i otobrazhayemoye fiksirovannyim doverennyim renderer?
- Kakiye primitivyi renderer i kakiye pravila kompozicii dopustimo schitatj iskhodnyim seed, a kakiye chasti FUM dolzhen sformirovatj ili vyibratj sam?
- Kakoj minimaljnyij ekran i kakoye obratnoye poljzovateljskoye dejstviye podtverzhdayut zhiznesposobnostj, a ne toljko korrektnostj serializacii predstavleniya?
- Dolzhnyi li polnoye vosproizvedeniye i poetapnoye prodolzheniye poluchatj kanonicheski odinakovuyu modelj predstavleniya?
- Razresheno li v posleduyusjhikh pokoleniyakh generirovatj Swift ili SwiftUI-kod, i kakaya otdeljnaya proverka nuzhna pered yego kompilyaciyej i ispolneniyem?
- Kak otdelitj proiskhozhdeniye GUI ot ruchnoj logiki obolochki i dokazatj otsutstviye vtorogo domennogo istochnika istinyi?

## Prakticheskaya ramka

Bezopasnyij promezhutochnyij artefakt teperj realizovan v [bezokonnom prototipe](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md): inertnaya deklarativnaya modelj kanonicheski vyivoditsya iz prinyatoj pamyati, sokhranyayet proiskhozhdeniye elementov i preobrazuyet dopustimoye namereniye obratno v versionirovannoye sobyitiye. Eto ne otvechayet na voprosyi o renderer, dopustimom seed i kriterii ekrannoj zhiznesposobnosti, ne ispolnyayet sgenerirovannyij kod i ne utverzhdayet, chto GUI uzhe sozdan.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-25 09:09:06 MSK — Dobavitj vosstanavlivayemyiye pokoleniya pamyati i deklarativnuyu GUI-proyekciyu](../Zhurnal/2026-07-25_09-09-06_MSK_dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)

## Zatronutaya dokumentaciya

- [Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)
- [Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md](../Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md)
- [Planirovaniye/kartochki-shagov/✅-FUM-STEP-0074-dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu.md](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0074-dobavitj-vosstanavlivayemyiye-pokoleniya-pamyati-i-deklarativnuyu-GUI-proyekciyu.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:726d586ae6244ca6f53c1cc9702167864ff8fc6824d6271195de4a1329125c2e -->
<!-- FUM-MD-RECENCY:END -->
