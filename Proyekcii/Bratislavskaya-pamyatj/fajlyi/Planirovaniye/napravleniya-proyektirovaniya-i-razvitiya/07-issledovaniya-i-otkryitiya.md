# 07. Issledovaniya i otkryitiya

## Naznacheniye

Eto napravleniye delayet [nauchnyiye issledovaniya FUM](../../Glossarij/nauchnoye-issledovaniye-FUM.md) obyichnoj chastjyu razvitiya proyekta. [Gipotezyi FUM](../../Glossarij/gipoteza-FUM.md), [eksperimentyi](../../Glossarij/eksperiment-FUM.md), otricateljnyiye rezuljtatyi, vosproizvedeniye i [otkryitiya FUM](../../Glossarij/otkryitiye-FUM.md) dolzhnyi sokhranyatjsya kak proveryayemyiye [narabotki](../../Glossarij/narabotka.md), a ne toljko kak krasivyiye utverzhdeniya v dokumentacii.

## Proyektnyiye voprosyi

- Kak otlichatj inzhenernuyu proverku rabotosposobnosti ot nauchnoj proverki utverzhdeniya?
- Kakiye statusyi nuzhnyi issledovateljskomu utverzhdeniyu: gipoteza, nablyudeniye, chastichno provereno, oprovergnuto, vosproizvedeno, otkryitiye?
- Kak sokhranyatj otricateljnyiye rezuljtatyi tak, chtobyi oni ekonomili budusjhuyu rabotu?
- Kak svyazyivatj eksperiment s iskhodnyimi dannyimi, kodom, sredoj, ogranicheniyami i povtornyim zapuskom?

## Liniya razvitiya

Blizhnij rezuljtat realizovan kak [shablon kartochki eksperimenta FUM](../shablon-kartochki-eksperimenta-FUM.md): vopros, gipoteza, metod, dannyiye, sreda, zaraneye zadannaya proverka, otdeljnyiye zapuski, rezuljtat, ogranicheniya, tri osi statusa i sleduyusjhij shag sokhranyayutsya v odnom chelovekochitayemom kontejnere. Polya proiskhozhdeniya i granicyi podgotovlenyi k budusjhej svyazi s avtomatizaciyami i reyestrom proiskhozhdeniya bez prezhdevremennogo obyyavleniya mashinnoj skhemyi.

Daljshe napravleniye dolzhno svyazatjsya s agentskim ciklom: FUM ne toljko vyipolnyayet poljzovateljskiye zadachi, no i umeyet stavitj issledovateljskiye voprosyi, zapuskatj proveryayemyiye eksperimentyi i sokhranyatj znaniya s yasnyim statusom.

## Blizhajshij proverennyij artefakt

[Shablon kartochki eksperimenta FUM](../shablon-kartochki-eksperimenta-FUM.md) otdelyayet neizmenyayemyij plan ot fakticheskikh zapuskov, nablyudeniye ot interpretacii, iskhod proverki ot issledovateljskogo statusa i predlozheniye sleduyusjhego shaga ot razresheniya na dejstviye. Otricateljnyij i neodnoznachnyij rezuljtatyi sokhranyayutsya kak poleznyiye ogranicheniya.

Zapolnennyij lokaljnyij primer sravnivayet determinirovannuyu JSON-serializaciyu dvukh poryadkov vstavki i povtoryayetsya odnoj komandoj Python bez seti, sekretov i zapisi. On podderzhivayet uzkuyu gipotezu v zafiksirovannoj srede, no pryamo ne zayavlyayet universaljnuyu kanonichnostj JSON, nezavisimoye vosproizvedeniye ili otkryitiye.

## Biotekhnologii

Podgotovlenyi trebovaniye FUM-REQ-0057 i aktivnyij shag FUM-STEP-0191 dlya biotekhnologicheskogo napravleniya. Plan predusmatrivayet vyipolnennoye sravneniye dvukh opublikovannyikh variantov obrabotki rastiteljnogo pisjhevogo syirjya s raschyotami, sravniteljnoj tablicej i ogranichennyim vyivodom; pasport vkhodit v tot zhe budusjhij shag. Issledovateljskij kandidat predlozhen analizom, sravneniye poka ne vyipolneno.

- [Sravnitj pervyiye biotekhnologicheskiye scenarii obrabotki pisjhevogo syirjya](../kartochki-shagov/🟡-FUM-STEP-0191-sravnitj-pervyiye-biotekhnologicheskiye-scenarii-obrabotki-pisjhevogo-syirjya.md)
- [Biotekhnologicheskoye napravleniye FUMA](../../Trebovaniya/🟡-biotekhnologicheskoye-napravleniye-FUMA.md)

## Genetika

Podgotovlenyi trebovaniye FUM-REQ-0058 i aktivnyij shag FUM-STEP-0192 dlya geneticheskogo napravleniya. Plan predusmatrivayet vyipolnennoye vosproizvedeniye sinteticheskogo nasledovaniya pryamyim raschyotom i modeljnyimi povtorami s otchyotom o sravnenii; pasport vkhodit v tot zhe budusjhij shag. Sinteticheskij lokus ostayotsya predlozhennyim kandidatom, vyichisliteljnyij eksperiment poka ne vyipolnen.

- [Vosproizvesti modelj nasledovaniya sinteticheskogo lokusa](../kartochki-shagov/🟡-FUM-STEP-0192-vosproizvesti-modelj-nasledovaniya-sinteticheskogo-lokusa.md)
- [Geneticheskoye napravleniye FUMA](../../Trebovaniya/🟡-geneticheskoye-napravleniye-FUMA.md)

## Khimiya

Podgotovlenyi trebovaniye FUM-REQ-0059 i aktivnyij shag FUM-STEP-0193 dlya khimicheskogo napravleniya. Plan predusmatrivayet izvlecheniye tablicyi rastvorimosti, raschyot ili interpolyaciyu i sopostavleniye istochnikov s kolichestvennyim vyivodom; zaversheniye shaga trebuyet vyipolnennogo vyichisliteljnogo issledovaniya, pasport vkhodit v tot zhe rezuljtat. Khlorid natriya ostayotsya predlozhennyim kandidatom, vyichisleniya poka ne vyipolnenyi.

- [Vosproizvesti zavisimostj rastvorimosti soli po otkryityim dannyim](../kartochki-shagov/🟡-FUM-STEP-0193-vosproizvesti-zavisimostj-rastvorimosti-soli-po-otkryityim-dannyim.md)
- [Khimicheskoye napravleniye FUMA](../../Trebovaniya/🟡-khimicheskoye-napravleniye-FUMA.md)

## Fizika

Podgotovlenyi trebovaniye FUM-REQ-0060 i aktivnyij shag FUM-STEP-0194 dlya fizicheskikh issledovanij. Plan predusmatrivayet vyipolnennyiye analiticheskij i chislennyij raschyotyi zatukhayusjhego oscillyatora s izmereniyem oshibki i skhodimosti i ogranichennyim vyivodom; pasport vkhodit v tot zhe budusjhij shag. Oscillyator ostayotsya predlozhennyim kandidatom, vyichisleniya poka ne vyipolnenyi.

- [Vosproizvesti modelj zatukhayusjhego oscillyatora](../kartochki-shagov/🟡-FUM-STEP-0194-vosproizvesti-modelj-zatukhayusjhego-oscillyatora.md)
- [Fizicheskoye issledovateljskoye napravleniye FUMA](../../Trebovaniya/🟡-fizicheskoye-issledovateljskoye-napravleniye-FUMA.md)

## Proveryayemyiye rezuljtatyi

- Issledovateljskaya gipoteza imeyet yavnyij istochnik i kriterij proverki.
- Eksperiment mozhno povtoritj lokaljno ili ponyatj, kakaya chastj nevosproizvodima.
- Otricateljnyij rezuljtat sokhranyayetsya kak poleznoye ogranicheniye budusjhikh rabot.
- Utverzhdeniye ob otkryitii ssyilayetsya na eksperiment, vosproizvedeniye i granicyi primenimosti.

## Granicyi

Issledovateljskij tekst ne dolzhen podmenyatj dokazateljstvo ritorikoj. Yesli rezuljtat poka yavlyayetsya siljnyim predpolozheniyem, on tak i nazyivayetsya. Yesli proverka zavisit ot vneshnej modeli, servisa ili zakryityikh dannyikh, granica vosproizvodimosti fiksiruyetsya yavno.

## Istochniki trebovanij

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-44-21_MSK_zaplanirovatj-fizicheskoye-issledovateljskoye-napravleniye/zapros.md)

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-42-42_MSK_zaplanirovatj-khimicheskoye-napravleniye/zapros.md)

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-41-15_MSK_zaplanirovatj-geneticheskoye-napravleniye/zapros.md)

- [Porucheniye o napravlenii](../../Zhurnal/2026-09-11_01-39-04_MSK_zaplanirovatj-biotekhnologicheskoye-napravleniye/zapros.md)

- [iskhodnyij zapros 2026-07-23 16:11:30 MSK — Opisatj shablon kartochki eksperimenta FUM](../../Zhurnal/2026-07-23_16-11-30_MSK_opisatj-shablon-kartochki-eksperimenta-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)

## Opornyiye materialyi

- [Nauchnyiye issledovaniya i otkryitiya](../../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md)
- [Dorozhnaya karta FUM](../dorozhnaya-karta.md)
- [Voprosyi](../../Voprosyi/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:44:45 MSK -->
<!-- content-sha256: sha256:41f10d67b43b3abeed1c60cfcf5c0820b4196d6644cac8bcba3a7c41927385b5 -->
<!-- FUM-MD-RECENCY:END -->
