+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0059"
"статус" = "устранена"
+++
# Otsutstviye korrekcii negotovogo chastichnogo priyoma

## Nablyudayemyij sboj

Posle otkloneniya vkhoda 0207 semj fajlov uzhe byili ustanovlenyi, no sobyitiye ostavalosj negotovyim i ne imelo postanovki, nablyudeniya ili vneshnej popyitki. V pervonachaljnom sreze otsutstvoval sokhranyayemyij sposob ispravitj takoj priyom s uderzhaniyem yego iskhodnogo namereniya i nomerov.

## Granica povtoreniya

Negotovoye sobyitiye priyoma posle chastichnogo fajlovogo effekta, dlya kotorogo nuzhna yavnaya sokhranyayemaya korrekciya do postanovki i vneshnej popyitki. Pervonachaljnaya oshibochnaya semanticheskaya svyazj — otdeljnaya prichina otkaza. Povtornoye nablyudeniye togo zhe sostoyaniya ne uvelichivayet chislo proyavlenij; osirotevshaya mashinnaya zapisj proverki 0056 imeyet druguyu skhemu i meru.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0059/ПРОЯВЛЕНИЕ-0001` | [Negotovoye sostoyaniye 0207](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md): semj ustanovlennyikh fajlov posle otkaza reyestra, bez postanovki i vneshnej popyitki. | Realjnyij priyom neljzya byilo shtatno ispravitj, sokhraniv namereniye i vyidelennyiye nomera. | Prinyata ogranichennaya komanda `исправить-план`; iskhodnyij otkaz i plan sokhranenyi, effektivnyiye fajlyi i reyestr proverenyi. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka uzhe soglasovannogo vozobnovlyayemogo priyoma 0201: chastichnyij effekt ne dolzhen trebovatj ruchnoj zamenyi istorii, povtornogo vyideleniya nomerov ili nedokazannogo vneshnego vyizova. Proverka reyestra imeyet pravo otklonyatj nevernyij vkhod; problema sostoyala v otsutstvii dopustimogo vosstanovleniya.

## Mekhanizm i sistemnoye ustraneniye

Prinyata postavka `17ef8a59fa3c67a73e54c2348189afcb10849585` s sokhranyayemyim namereniyem korrekcii i ograzhdyonnyim povtorom. Ona razlichayet iskhodnyij plan i effektivnyiye fajlyi, pereproveryayet granicyi do effekta, uderzhivayet zapret chuzhoj ili uzhe razreshyonnoj vneshnej popyitki i zavershayet prervannoye ispravleniye drugim processom. Sistema ne obkhodit pervonachaljnyij otkaz i ne delayet fajlovuyu ustanovku yedinoj tranzakciyej.

## Svyazannyiye shagi

Novogo STEP net: neobkhodimaya ogranichennaya realizaciya, regressii i realjnoye vosstanovleniye uzhe prinyatyi v ramkakh 0201. Zaversheniye dannogo ispravleniya ne zakryivayet vsyu predmetnuyu realizaciyu perenosa 0207 ili polnyij obyyom priyoma napravlenij.

## Kriterii zakryitiya

Ispravlyayetsya iskhodnoye negotovoye sobyitiye bez zamenyi iskhodnyikh polej i nomerov. Preryivaniye posle namereniya, kartochki ili reyestra vosstanavlivayetsya tochnyim povtorom drugogo processa. Podmenyi plana, bazyi, nomera, statusa, zagolovka, puti, chuzhikh dannyikh i vneshnej popyitki ostayutsya otkazami. Realjnyij 0207 gotov posle sverki semi fajlov i reyestra.

## Podtverzhdeniye ustraneniya

[Testyi vosstanovleniya](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_ispravleniya_priyoma.py) proveryayut tochnyij povtor, tri fazyi preryivaniya i zapresjhyonnyiye podmenyi. [Zapusk № 5](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/materialyi/zapuski-proverok/5_6ed7e8ae-55b2-4f34-8215-0c66ece1272e.json) imeyet kod 0 i dliteljnostj obyortki 74,853027333 s; [otchyot](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md) otdeljno fiksiruyet 11 testov za 74,616 s. Realjnoye ispravleniye zanyalo 6,613514750 s, vernulo `готов: true`, prezhniye 0207/0066 i otsutstviye vneshnej popyitki. Pervonachaljnyij plan `7189e69a0526b504f6f93fce542f35ee19323532e4075359947cc9c5b6ba6bb5` sokhranyon; effektivnyiye semj fajlov i reyestr prochitanyi nezavisimo. Eto proverennaya mera v nazvannyikh granicakh, a ne odin udachnyij povtor.

## Istochniki

- [Tekusjhij zapros](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).
- [Adresnoye podtverzhdeniye i chastnyiye pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).
- [Dopustimyiye iskhodyi kartochki](../Pravila/agentov/planirovaniye-trebovaniya-voprosyi-i-sboi.md).
- [Iskhodnoye sostoyaniye, postavka i priyomka](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:7dbaf59ad8c25bab44a93bdf5c484e809a7ce00a740feac8073ffe5393c9a1ae -->
<!-- FUM-MD-RECENCY:END -->
