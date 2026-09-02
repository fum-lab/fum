# Istoriya: zapuskatj vosproizvodimuyu avtomatizaciyu FUM

Poljzovatelyu ili [FUM-uzlu](../../Glossarij/FUM-uzel.md) nuzhna povtoryayemaya procedura, rezuljtat kotoroj mozhno proveritj, obyyasnitj i peredatj sleduyusjhemu ispolnitelyu. [Avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) ne dolzhna susjhestvovatj toljko kak privyichka agenta ili skryitoye povedeniye zapusjhennoj sredyi: yeyo istochnik, vkhodyi, effektyi, versii, proverki i ogranicheniya vkhodyat v pamyatj.

Cennostj istorii sostoit v kontroliruyemom povtorenii. Odin i tot zhe zapusk v sopostavimyikh usloviyakh dolzhen davatj tot zhe rezuljtat libo obyyasnimoye raskhozhdeniye, a nevosproizvodimaya vneshnyaya chastj ne dolzhna skryivatjsya za obsjhim soobsjheniyem ob uspekhe.

## Poljzovateljskaya istoriya

Kak poljzovatelj povtoryayemoj proceduryi FUM, ya khochu vyibratj versiyu avtomatizacii, uvidetj yeyo vkhodyi, prava i ozhidayemyiye effektyi, zapustitj yeyo i poluchitj rezuljtat vmeste s trassoj, chtobyi ya ili drugoj uzel mogli proveritj i vosproizvesti rabotu bez skryitoj metodiki.

## Osnovnoj scenarij

1. Poljzovatelj vyibirayet avtomatizaciyu po kanonicheskomu imeni, naznacheniyu i versii.
2. FUM pokazyivayet vkhodnuyu i vyikhodnuyu skhemyi, konfiguraciyu, zavisimosti, dopustimyiye oshibki, razreshyonnyiye effektyi i tochki podtverzhdeniya.
3. Lokaljnaya fikstura ili test podtverzhdayet bazovyij kontrakt bez seti, sekretov i neobratimyikh dejstvij.
4. Avtomatizaciya poluchayet yavnyiye vkhodyi; po vozmozhnosti chistoye vyichisliteljnoye yadro vyipolnyayetsya otdeljno ot obolochki vvoda-vyivoda i pobochnyikh effektov.
5. Vneshnij, platnyij, privatnyij ili neobratimyij effekt prokhodit otdeljnuyu proverku prav i primenimoye podtverzhdeniye.
6. FUM sokhranyayet versiyu avtomatizacii i instrumentov, vkhodyi, konfiguraciyu, rezuljtat, oshibku, trassu i izvestnyiye vneshniye zavisimosti.
7. Povtornyij zapusk sravnivayetsya s pervyim; raskhozhdeniye obyyasnyayetsya izmenivshimsya vkhodom, versiyej, sredoj, vremenem, seed, modeljyu libo vneshnim sostoyaniyem.

## Aljternativyi i otkazyi

- Yesli vneshnij servis, sekret ili licenziya nedostupnyi, FUM zapuskayet toljko razreshyonnyij lokaljnyij kontrakt, adapter, simulyator ili fiksturu i ne imitiruyet realjnyij vneshnij uspekh.
- Yesli vremya, sluchajnostj, modelj ili vneshneye sostoyaniye vliyayut na rezuljtat, oni fiksiruyutsya kak vkhodyi libo kak yavnaya granica sravnimosti.
- Yesli proverka ne prokhodit, rezuljtat imeyet status otkaza; chastichnyij fajl ili pobochnyij effekt ne stanovitsya prinyatyim vyikhodom avtomaticheski.
- Yesli dejstviye trebuyet boleye shirokikh prav, zapusk ostanavlivayetsya do otdeljnogo razresheniya, a ne rasshiryayet oblastj dostupa sam.
- Yesli povtoryayemaya ruchnaya procedura yesjhyo ne imeyet ispolnyayemogo scenariya, pamyatj khranit proveryayemyij shablon, ruchnoj status i blizhajshuyu granicu avtomatizacii.

## Kriterii priyomki

- Iskhodnyij tekst ili deklarativnaya skhema, komanda zapuska, konfiguraciya, zavisimosti, versii, skhemyi vkhoda i vyikhoda i testyi dostupnyi v pamyati FUM.
- Bazovaya proverka vyipolnyayetsya lokaljno bez seti i sekretov.
- Razreshyonnyiye i zapresjhyonnyiye effektyi otdelenyi ot chistogo yadra i nablyudayemyi v trasse.
- Povtor na odinakovom snimke dayot tot zhe rezuljtat libo dokumentirovannoye obyyasnimoye raskhozhdeniye.
- Neuspekh, neizvestnostj i nevosproizvodimaya vneshnyaya chastj ne vyidayutsya za uspeshnyij vosproizvodimyij rezuljtat.
- Drugoj dopusjhennyij ispolnitelj mozhet ponyatj naznacheniye, ogranicheniya i sposob proverki bez skryitogo konteksta avtora.

## Granica primenimosti

Istoriya ne trebuyet pobajtovogo ravenstva dlya lyuboj LLM ili menyayusjhegosya vneshnego servisa i ne obyyavlyayet yedinyij yazyik avtomatizacij uzhe gotovyim. Vosproizvodimostj strukturyi i zapuska sama po sebe ne dokazyivayet istinnostj, poleznostj ili bezopasnostj rezuljtata. Nabor dejstvuyusjhikh repozitornyikh instrumentov yavlyayetsya proveryayemoj chastjyu dokumentacionnogo prototipa, a ne polnyim runtime FUM.

## Status

Tekusjhij status: lokaljnyiye avtomatizacii pamyati FUM chastichno realizuyut istoriyu cherez otdeljnyiye scenarii so svoimi kontraktami, komandami i proverkami.

Celevoj status: obsjhij [yazyik avtomatizacij FUM](../../Glossarij/yazyik-avtomatizacij-FUM.md) i sobstvennyij runtime vyirazhayut tot zhe proveryayemyij kontur bez skryitoj zavisimosti ot konkretnoj agentskoj sredyi.

## Istochniki trebovanij

- [iskhodnyij zapros o napolnenii poljzovateljskikh istorij FUM](../../Zhurnal/2026-07-28_10-56-30_MSK_napolnitj-poljzovateljskiye-istorii-FUM/zapros.md)

## Opornyiye dokumentyi

- [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md)
- [Modelj pamyati FUM](../01-modelj-pamyati-FUM.md)
- [LLM-oriyentirovannyij yazyik avtomatizacij](../21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1e1f7a6c11605f3cf169d8390a0746978749b7b7abe2324d53800db45ad24c5a -->
<!-- FUM-MD-RECENCY:END -->
