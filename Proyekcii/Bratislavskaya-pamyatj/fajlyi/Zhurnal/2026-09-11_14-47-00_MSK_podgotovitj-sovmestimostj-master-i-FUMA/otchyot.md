# Otchyot 2026-09-11 14:47:00 MSK - Podgotovitj sovmestimostj master i FUMA

Podgotavlivayetsya konechnyij paket sovmestimosti prinimayusjhego kontura M s zakreplyonnyim L. Zaversheniye FUM-STEP-0175 etim etapom ne obyyavlyayetsya: integraciya v master i novyij kandidat ostayutsya u koordinatora.

## Profilj vremeni vyipolneniya

| Stadiya                      | Dliteljnostj    | Granicyi i sposob izmereniya                                            |
| --------------------------- | --------------- | --------------------------------------------------------------------- |
| Chteniye pravil i iskhodnikov  | ne izmereno     | Do pervogo proverochnogo processa; zadnim chislom ne ocenivayetsya        |
| Adresnyiye proverki i profili | po strokam nizhe | Monotonnoye vremya obyortki; vlozhennyiye intervalyi ne summiruyutsya povtorno |

Granica profilya: nachalo etapa 2026-09-11 14:47:00 MSK; obsjhij interval chteniya, ozhidaniya i peredachi ne izmeryalsya monotonno i zadnim chislom ne ocenivayetsya. FIFO ne primenyalsya. Vremya pryamyikh proverok ogranicheno zapuskami obyortki nizhe.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                 | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj] RED: perenosimyiye granicyi formatov, adaptera, svyazej i grafa na M             | 11,561 s     | neuspeshno |
| [Korenj] RED: prinimayusjhij validator ustanovlennyikh tipov na M                          | 1,904 s      | neuspeshno |
| [Korenj] RED: probelyi registra i simvolicheskikh ssyilok v perenesyonnom validatore tipov | 1,646 s      | neuspeshno |
| [Korenj] GREEN: sovmestnyiye adresnyiye regressii pyati paketov i prinimayusjhego validatora  | 25,492 s     | uspeshno   |
| [Korenj] Profilj perekhoda prezhnej politiki                                            | 7,824 s      | uspeshno   |
| [Korenj] Profilj konechnogo JS-shablona                                                 | 2,421 s      | uspeshno   |
| [Korenj] Profilj svyaznosti neobyazateljnogo grafa                                      | 1,417 s      | uspeshno   |
| [Korenj] Profilj proyekcii neobyazateljnogo grafa                                       | 2,404 s      | uspeshno   |
| [Korenj] Profilj klassifikacii formatov, adaptera, prinimayusjhikh tipov i shesti svyazej   | 2,984 s      | uspeshno   |
| [Korenj] Adresnaya sverka 350 i 69 isklyuchenij, proiskhozhdeniya L i obyichnyij skaner        | 0,504 s      | neuspeshno |
| [Korenj] Regressii neizmennogo istochnika proverok i strogikh isklyuchenij                | 4,442 s      | uspeshno   |
| [Korenj] Sveritj politiku s uchyotom povtoryayusjhikhsya istoricheskikh strok                   | 1,589 s      | neuspeshno |
| [Korenj] Sveritj 419 isklyuchenij po tochnoj semantike skanera                           | 25,604 s     | neuspeshno |
| [Korenj] Sveritj politiki posle ispravleniya putej scenariyev vosproizvedeniya           | 25,33 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 115,122 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:0523d73a5874e42bd27a0c362caa1593e956928114d593ce3c20155d75b1f5d3.
Kontekst soderzhimogo: sha256:b3deb194e90173df187b3e56529fd8653a79c56f0e9f7575085df54769b146cf.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Pervichnaya sverka Git podtverdila tochnyij M, chistyij indeks i rabocheye derevo; sobstvennaya vetka sozdana ot M. Iskhodnyiye blobs perenosimyikh paketov proveryayutsya chteniyem Git-obyyektov.

[Karta perenosa](materialyi/karta-perenosa.md) svyazyivayet kazhdyij paket s tochnyimi iskhodnyimi kommitami i granicej integracii.

Pervyij zapusk obyortki ostanovilsya do proverochnogo processa: otsutstvovala materializaciya LinguisticKit. Shtatnyij `proveritj-git-zavisimostj.py init --repo-root . --path Зависимости/LinguisticKit` materializoval prezhnij gitlink `837e2ce107b97ee7b9d3344c9fe99142281fe393`; gitlink ne izmenyon. Eto podgotovka zavisimosti, a ne vyipolnennyij RED.

Pervyij RED pyati paketov: 55 testov, 31 neuspeshnaya proverka i 58 oshibok podsluchayev; na M otsutstvovali perenosimyiye funkcii i dopuski. Pervyij RED tipov vklyuchal oshibki ochistki fiksturyi; ispravleniye ochistki cherez `finally` otdeleno ot produktovogo izmeneniya. Povtor na tochnom perenose c14b2 podtverdil semj otricateljnyikh podsluchayev bez oshibok fiksturyi. Posle ispravleniya predkov puti sovmestnyij GREEN proshyol 82 testa za 25,169 s. Otdeljno proshli semj susjhestvuyusjhikh regressij istochnika kontura i politiki za 4,225 s. Eto adresnyiye granicyi, ne polnyij progon vsekh testov repozitoriya.

Sokhranyonnyiye scenarii vosproizvedeniya zapuskayutsya iz kornya cherez otchyotnuyu obyortku: [82 regressii](materialyi/proveritj-adresnyiye-granicyi.py), [sverka politiki](materialyi/proveritj-politiku.py), [profilj adresnyikh granic](materialyi/profili/izmeritj-adresnyiye-granicyi.py). Pervyiye izmereniya regressij i malogo profilya ispolnyali tela kak `python3 -B -c`; sokhranyonnyiye fajlyi otlichayutsya sposobom soyedineniya putej `Path.joinpath`, ispravlennyim po strogomu scanner. Oni ne obyyavlyayutsya pervonachaljnyim sposobom zapuska.

Dve pervyiye adresnyiye sverki politiki otkazali iz-za lishnikh predpolozhenij scenariya: prezhniye isklyucheniya mogut pokryivatj neskoljko odinakovyikh strok, a `count` vklyuchayet toljko nakhodki `error.*`, kak v `_apply_policy`. Traceback pervoj popyitki ne sokhranilsya; yeyo mesto otkaza ustanovleno chteniyem scenariya i L. Posle ispravleniya etikh predpolozhenij sverenyi vse 419 zapisej, no obyichnyij skaner otklonil shestj strok novyikh scenariyev iz-za putevyikh suffiksov. Soyedineniya zamenenyi na `Path.joinpath`; isklyucheniya politiki dlya scenariyev ne dobavlyalisj. Vse popyitki ostayutsya v mashinnom zhurnale.

## Profili i resheniye ob optimizacii

Profili vyipolnenyi na Python 3.14.7 / Darwin. Shestj JSON v [materialakh profilej](materialyi/profili/) sokhranyayut realizacii, scenarii, vkhodyi i intervalyi tam, gde ikh fiksiruyet iskhodnaya avtomatizaciya. Podgotovka fikstur ne vklyuchena v intervalyi operacij.

- Vyibor prezhnej politiki: mediana 0,164 ms; perekhod fiksturyi odnogo tekstovogo fajla — 1,173 s. Polnaya realjnaya proyekciya etim izmereniyem ne podmenyayetsya.
- Proverka konechnogo JS-shablona: 56,03 mks do i 55,80 mks pri povtore bez izmeneniya algoritma; boljshoj vkhod — 4,36 i 4,39 ms. Klassifikaciya tochnogo adaptera proyektorom — 76,61 mks, semi formatov — 3,78 mks.
- Polnyij prinimayusjhij validator tipov: 69,45 ms dlya sovmestimyikh dannyikh i 66,95 ms pri istoricheskom otsutstvii; otkaz nevernogo registra — 0,49 ms.
- Profilj shesti testov svyazej: 0,272 s; 39 vyizovov parsera zanyali summarno 4,55 ms, sobstvennoye vremya — 0,145 ms.
- Svyaznostj 25 otsutstvuyusjhikh lokaljnyikh ssyilok, desyatj proverok na zamer: mediana 102,67 ms; proyekciya 25 takikh ssyilok — 38,12 ms posle pervogo izmereniya 78,82 ms. Susjhestvuyusjhij graf i pokhozheye imya sokhranyayut otdeljnyiye kontroljnyiye rezuljtatyi.

Izmerennyiye ogranichennyiye operacii ne obosnovali dopolniteljnoj optimizacii: sokhranenyi iskhodnyij kyesh konechnogo adaptera i strogaya proverka kazhdogo komponenta puti. Sravneniya do/posle otnosyatsya toljko k yavno ukazannyim odinakovyim scenariyam; uskoreniye obsjhej proverki ili novoj polnoj proyekcii ne zayavlyayetsya.

## Resheniya i ogranicheniya

Shestj paketov perenesenyi adresno. Generaciya proyekcii vozmozhna toljko posle obyyedineniya formatov i JS: promezhutochnoye pokoleniye odnogo rasshireniya ne dopuskayetsya sokhranyonnyim mostom migracii. Kontroljnaya tochka sokhranyayet prezhneye pokoleniye M bez obyyavleniya yego aktualjnosti dlya novyikh kanonicheskikh fajlov. Koordinator peredal tyazhyoloye okno posle ostanovki sborochnyikh operacij VM; itogovyij smoke i shtatnaya para zamyikaniya yesjhyo predstoyat.

Ispravleniye [FUM-SBOJ-0076](../../Sboi/FUM-SBOJ-0076-propusk-proverki-predkov-kataloga-tipov.md) podgotovleno v etoj vetke; kartochka ostayotsya aktivnoj do prinyatiya v master i proverki kandidata. Tri nezavisimyikh analiza vyipolnyalisj toljko chteniyem. Novyiye zavisimosti proyektora i proverki tipov vkhodyat v rekursivnuyu proverku vsego otslezhivayemogo `Инструменты` susjhestvuyusjhim konturom. Pryamyiye CLI berut kod otnositeljno sobstvennogo `__file__`; dannyiye kandidata ne stanovyatsya istochnikom importov. Unit-testyi, naprotiv, mogut namerenno vyibiratj kandidatnuyu realizaciyu cherez `FUM_CHECKED_CODE_ROOT` i ne schitayutsya pryamoj validaciyej dannyikh kodom M.

Ostatok kontroljnoj tochki: zavershitj adresnuyu sverku politiki, standartnuyu finaljnuyu priyomku i zamyikaniye proyekcii; opublikovatj tochnyij kommit, proveritj udalyonnyij OID i peredatj paket koordinatoru. Prodvizheniye master/fuma i novyij kandidat ostayutsya u koordinatora.

## Istochniki

- [Iskhodnyiye komandyi i granica koordinacii](zapros.md).
- [FUM-STEP-0175](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:19:56 MSK -->
<!-- content-sha256: sha256:30ff85bf26696f4226ce1be0e0275b1644b8487f7f8397a4c05545bdae96a0a4 -->
<!-- FUM-MD-RECENCY:END -->
