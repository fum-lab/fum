+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0059"
"статус" = "активна"
+++
# Otsutstviye korrekcii negotovogo chastichnogo priyoma

## Nablyudayemyij sboj

Posle otkloneniya vkhoda 0207 semj fajlov uzhe byili ustanovlenyi, no sobyitiye ostavalosj negotovyim i ne imelo postanovki, nablyudeniya ili vneshnej popyitki. V pervonachaljnom sreze otsutstvoval sokhranyayemyij sposob ispravitj takoj priyom s uderzhaniyem yego iskhodnogo namereniya i nomerov.

V finansovom priyome 0212/0069 posle obyazateljnogo otkaza reyestra podderzhannyij putj korrekcii takzhe otklonil dobavleniye yavnogo obyyavleniya prezhnego statusa. Sobyitiye, nomera i susjhestvuyusjhiye bajtyi kartochki sokhranyalisj. Eto vtoroye podtverzhdyonnoye proyavleniye; kartochka vozvrasjhena v aktivnoye sostoyaniye do samostoyateljnoj priyomki rasshirennoj granicyi.

## Granica povtoreniya

Negotovoye sobyitiye priyoma posle chastichnogo fajlovogo effekta, dlya kotorogo nuzhna yavnaya sokhranyayemaya korrekciya do postanovki i vneshnej popyitki. Pervonachaljnaya oshibochnaya semanticheskaya svyazj — otdeljnaya prichina otkaza. Povtornoye nablyudeniye togo zhe sostoyaniya ne uvelichivayet chislo proyavlenij; osirotevshaya mashinnaya zapisj proverki 0056 imeyet druguyu skhemu i meru.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0059/ПРОЯВЛЕНИЕ-0001` | [Negotovoye sostoyaniye 0207](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md): semj ustanovlennyikh fajlov posle otkaza reyestra, bez postanovki i vneshnej popyitki. | Realjnyij priyom neljzya byilo shtatno ispravitj, sokhraniv namereniye i vyidelennyiye nomera. | Prinyata ogranichennaya komanda `исправить-план`; iskhodnyij otkaz i plan sokhranenyi, effektivnyiye fajlyi i reyestr proverenyi. |
| `FUM-СБОЙ-0059/ПРОЯВЛЕНИЕ-0002` | [Tochnyiye iskhodnyiye i predlagayemyiye bajtyi](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/svideteljstva/sravneniye-statusa.json) i [otchyot](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/otchyot.md): otkaz `Исправление меняет статус и границы`, kod 2, 1,539687166 s. | Shtatnaya korrekciya chastichnogo finansovogo priyoma ne mogla dobavitj deklaraciyu prezhnego 🟡 bez zamenyi namereniya ili nomerov. | Do dolgovechnogo namereniya otkaz ne raskhodoval korrekciyu. Podderzhana strogaya kanonicheskaya vstavka; prezhneye sobyitiye gotovo, vneshnij zapusk odin i nachaljnaya baza podtverzhdena. Novaya obsjhaya priyomka yesjhyo ne zavershena. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka uzhe soglasovannogo vozobnovlyayemogo priyoma 0201: chastichnyij effekt ne dolzhen trebovatj ruchnoj zamenyi istorii, povtornogo vyideleniya nomerov ili nedokazannogo vneshnego vyizova. Proverka reyestra imeyet pravo otklonyatj nevernyij vkhod; problema sostoyala v otsutstvii dopustimogo vosstanovleniya.

## Mekhanizm i sistemnoye ustraneniye

Prinyata postavka `17ef8a59fa3c67a73e54c2348189afcb10849585` s sokhranyayemyim namereniyem korrekcii i ograzhdyonnyim povtorom. Ona razlichayet iskhodnyij plan i effektivnyiye fajlyi, pereproveryayet granicyi do effekta, uderzhivayet zapret chuzhoj ili uzhe razreshyonnoj vneshnej popyitki i zavershayet prervannoye ispravleniye drugim processom. Sistema ne obkhodit pervonachaljnyij otkaz i ne delayet fajlovuyu ustanovku yedinoj tranzakciyej.

## Svyazannyiye shagi

Sleduyusjhij abzac sokhranyayet istoricheskuyu granicu pervogo proyavleniya.

Novogo STEP net: neobkhodimaya ogranichennaya realizaciya, regressii i realjnoye vosstanovleniye uzhe prinyatyi v ramkakh 0201. Zaversheniye dannogo ispravleniya ne zakryivayet vsyu predmetnuyu realizaciyu perenosa 0207 ili polnyij obyyom priyoma napravlenij.

Povtor `FUM-СБОЙ-0059/ПРОЯВЛЕНИЕ-0002` aktualiziruyet [istochniki STEP 0201](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0201-avtomatizirovatj-priyom-napravlenij-FUMA.md), sokhranyaya yego zavershyonnuyu istoricheskuyu granicu. Tekusjhaya proverka ogranichennogo vosstanovleniya vyinesena v [aktivnyij STEP 0213](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0213-proveritj-ogranichennoye-vosstanovleniye-statusa-priyoma.md).

## Kriterii zakryitiya

Ispravlyayetsya iskhodnoye negotovoye sobyitiye bez zamenyi iskhodnyikh polej i nomerov. Preryivaniye posle namereniya, kartochki ili reyestra vosstanavlivayetsya tochnyim povtorom drugogo processa. Podmenyi plana, bazyi, nomera, statusa, zagolovka, puti, chuzhikh dannyikh i vneshnej popyitki ostayutsya otkazami. Realjnyij 0207 gotov posle sverki semi fajlov i reyestra.

Dlya proyavleniya 0002 trebuyetsya prinyatj stroguyu vstavku prezhnego statusa pri neizmennyikh nomerakh, namerenii i granicakh, podtverditj nastoyasjhij reyestr i povtor drugim processom, otkazyi izmeneniya i skryitiya statusa, profilj i samostoyateljnuyu polnuyu granicu. Predyidusjheye podtverzhdeniye nizhe sokhranyayetsya toljko dlya proyavleniya 0001.

## Podtverzhdeniye ustraneniya

[Testyi vosstanovleniya](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_ispravleniya_priyoma.py) proveryayut tochnyij povtor, tri fazyi preryivaniya i zapresjhyonnyiye podmenyi. [Zapusk № 5](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/materialyi/zapuski-proverok/5_6ed7e8ae-55b2-4f34-8215-0c66ece1272e.json) imeyet kod 0 i dliteljnostj obyortki 74,853027333 s; [otchyot](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md) otdeljno fiksiruyet 11 testov za 74,616 s. Realjnoye ispravleniye zanyalo 6,613514750 s, vernulo `готов: true`, prezhniye 0207/0066 i otsutstviye vneshnej popyitki. Pervonachaljnyij plan `7189e69a0526b504f6f93fce542f35ee19323532e4075359947cc9c5b6ba6bb5` sokhranyon; effektivnyiye semj fajlov i reyestr prochitanyi nezavisimo. Eto proverennaya mera v nazvannyikh granicakh, a ne odin udachnyij povtor.

## Istochniki

- [Povtor 0002, soglasovannyij nomer i granica vosstanovleniya](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/zapros.md). Nomer 0002 soglasovan koordinatorom posle chteniya 52 worktree, 127 heads/origin refs i podtverzhdenij dejstvuyusjhikh pisatelej; nedostupnoye udalyonnoye sostoyaniye etim ne okhvatyivayetsya.
- [Tekusjhij zapros](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).
- [Adresnoye podtverzhdeniye i chastnyiye pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).
- [Dopustimyiye iskhodyi kartochki](../Pravila/agentov/planirovaniye-trebovaniya-voprosyi-i-sboi.md).
- [Iskhodnoye sostoyaniye, postavka i priyomka](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:10:58 MSK -->
<!-- content-sha256: sha256:ef8bf17f1072a344905306f1cfd73ba33ca0b617a788161271647c84eda2342d -->
<!-- FUM-MD-RECENCY:END -->
