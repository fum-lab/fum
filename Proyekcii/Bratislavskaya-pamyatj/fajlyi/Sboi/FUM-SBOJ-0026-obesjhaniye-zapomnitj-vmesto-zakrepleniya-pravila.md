+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0026"
"статус" = "устранена"
+++
# Obesjhaniye zapomnitj vmesto zakrepleniya pravila

Postoyannoye ukazaniye poljzovatelya byilo ostavleno punktom plana, khotya trebovalosj zakrepitj povedeniye dlya sleduyusjhikh zadach. Ustraneniye otnositsya k pravilu rabotyi i proveryayemoj registracii norm v tekusjhej vetke; ono ne dokazyivayet bezoshibochnostj vsekh budusjhikh ispolnitelej.

## Nablyudayemyij sboj

Na vopros o postoyannom zakreplenii agent otvetil namereniyem vklyuchitj povedeniye v plan. Poljzovatelj zatem utochnil, chto obyazateljstvo oznachayet dejstviye vpredj i trebuyet zapisi zhelayemogo povedeniya imenno v pravilakh vmeste s zhurnalom komand i otvetov.

## Granica povtoreniya

Postoyannaya upravlyayusjhaya komanda priznana, no otsutstvuyet dejstvuyusjhaya norma s oblastjyu i proiskhozhdeniyem libo ssyilka na ravnosiljnoye susjhestvuyusjheye pravilo. Razovoye trebovaniye ne stanovitsya postoyannyim toljko iz-za slova «nuzhno».

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0026/ПРОЯВЛЕНИЕ-0001` | [Komandyi 5 i 12](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md), [soderzhateljnyiye otvetyi](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/otchyot.md) | Obyazateljstvo ostalosj namereniyem. | Zakrepitj postoyannuyu normu i obyazateljnyij marshrut dialoga v sobstvennoj vetke. |

## Mekhanizm i sistemnoye ustraneniye

Korenj teperj trebuyet marshrut `диалог` pri kazhdom poljzovateljskom soobsjhenii i vosstanovlenii zadachi. Pravilo 000172 svyazyivayet postoyannoye ukazaniye s dejstvuyusjhej normoj ili ravnosiljnyim pravilom, ogranichivayet smyisl obyazateljnyikh formulirovok oblastjyu dejstviya i zapresjhayet obyyavlyatj chernovik uzhe dejstvuyusjhim pravilom osnovnoj vetki. Zhurnal khranit komandyi i otvetyi, JSONL pozvolyayet vosstanovitj ikh posle szhatiya.

## Kriterii zakryitiya

- Postoyannoye ukazaniye imeyet kanonicheskuyu normu s proiskhozhdeniyem i yavnoj oblastjyu.
- Marshrut dialoga obyazatelen v korne i soglasovan s inventaryom.
- Nezaregistrirovannyij yakorj i dejstvuyusjhaya norma v istoricheskoj teme otvergayutsya.
- Zhurnal soderzhit kazhduyu upravlyayusjhuyu komandu i svyazannyij soderzhateljnyij otvet; status sobstvennoj vetki otlichyon ot integracii.

## Podtverzhdeniye ustraneniya

V tekusjhem Zhurnale sokhranenyi 13 komand i 13 soderzhateljnyikh otvetov. Nablyudyon RED dlya propuskov registracii i polnomochij; posle ispravleniya proshli 19 regressionnyikh testov dekompozicii i strukturnaya proverka 215 pravil. Proverki ogranichivayut celostnostj pravil i marshrutov; smyisl i primeneniye normyi ostayutsya otvetstvennostjyu ispolnitelya. V osnovnuyu vetku rezuljtat yesjhyo ne integrirovan.

## Istochniki

- [Iskhodnyiye komandyi](../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).
- [Obyazateljnyij korenj](../AGENTS.md).
- [Postoyannyiye principyi](../Pravila/agentov/lokaljnyiye-navyiki-i-instrumentyi.md).
- [Regressii](../Instrumentyi/fum-dekompoziciya-pravil-agentov/tests/test_dekompoziciya_pravil_agentov.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 23:08:12 MSK -->
<!-- content-sha256: sha256:efa3317cfd126cdc249dfd7e724cf6155ecafc0b0c9700da3f215fc3767512f1 -->
<!-- FUM-MD-RECENCY:END -->
