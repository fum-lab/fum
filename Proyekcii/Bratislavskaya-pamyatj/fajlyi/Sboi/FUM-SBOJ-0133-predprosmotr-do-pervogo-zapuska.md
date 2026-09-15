+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0133"
"статус" = "активна"
+++
# Predprosmotr vyizvan do pervogo nastoyasjhego zapuska

## Nablyudayemyij sboj

Predprosmotr novogo etapa vyizvan do pervoj nastoyasjhej mashinnoj zapisi zapuska. Shtatnyij instrument otkazal, poskoljku katalog zapuskov yesjhyo otsutstvoval.

## Granica povtoreniya

Oshibochnyij poryadok podgotovki vkhoda predprosmotra. Eto ne sboj0079: posle otkaza zavisimyij smoke ne zapuskalsya. Eto takzhe ne ustarevshij otpechatok susjhestvuyusjhego bloka i ne vyizov svyaznosti bez predprosmotra.

## Proyavleniya

### FUM-SBOJ-0133/PROYAVLENIYE-0001

Pervyij predprosmotr tekusjhego etapa vernul kod1 i diagnostiku, nachinayusjhuyusya s `каталог запусков отсутствует`. [Svideteljstvo](../Zhurnal/2026-09-15_02-42-44_MSK_prinyatj-obsjhij-paket-i-proveritj-podklyucheniye/materialyi/vosstanovleniye-predprosmotra.json) svyazyivayet otkaz s posleduyusjhimi nastoyasjhimi kvitanciyami. Nikakaya priyomka po etomu otkazu ne zayavlena.

### FUM-SBOJ-0133/PROYAVLENIYE-0002

V novom etape obzora postavok korenj povtorno vyizval predprosmotr do pervogo nastoyasjhego zapuska. Kod1 i diagnostika `каталог запусков отсутствует` podtverzhdenyi [tochnyim diapazonom iskhodnogo JSONL](../Zhurnal/2026-09-16_00-15-17_MSK_proveritj-postavki-kommita-i-integracii/materialyi/povtor-rannego-predprosmotra.json). Zatem nastoyasjhaya proverka strukturyi zavershilasj kodom0; povtornyij predprosmotr postroyen po yeyo kvitancii. Iskusstvennyikh zapuskov ne sozdavali. Povtor pokazyivayet, chto prezhneye zakryitiye byilo ogranichennyim vosstanovleniyem i ne predotvratilo nevernyij poryadok v novom etape.

## Ozhidaniye i klassifikaciya

V novom etape pervyim vyipolnyayetsya predusmotrennyij adresnyij zapusk cherez otchyotnuyu obyortku, zatem predprosmotr stroitsya po yego terminaljnoj zapisi. Defekt shtatnogo instrumenta ne zayavlyayetsya; eto oshibka podgotovki vyizova kornem.

## Mekhanizm i sistemnoye ustraneniye

Vosstanovlen shtatnyij poryadok zapustitj → predprosmotr. Iskusstvennaya kvitanciya ili pustoj katalog ne sozdavalisj vmesto nastoyasjhego zapuska. Novyij universaljnyij orkestrator etim vosstanovleniyem ne realizovan.

## Svyazannyiye shagi

Ogranichennoye vosstanovleniye zaversheno v [tekusjhem etape](../Zhurnal/2026-09-15_02-42-44_MSK_prinyatj-obsjhij-paket-i-proveritj-podklyucheniye/zapros.md). Dlya iskhodnogo vosstanovleniya otdeljnyij shag ne sozdavalsya; obsjhej garantii otsutstviya podobnyikh oshibok ne zayavleno. Povtor0002 uchityivayetsya v susjhestvuyusjhem [shage0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md): praviljnyij poryadok sleduyet obespechivatj pri podgotovke novogo etapa do dorogikh proverok.

## Kriterii zakryitiya

Nastoyasjhij zaplanirovannyij adresnyij process zavershyon i zapisan obyortkoj. Sleduyusjhij predprosmotr uspeshno sformirovan iz yego kvitancii; zapolnennostj paryi proverena otdeljno. Iskhodnaya istoriya otkaza sokhranena.

## Podtverzhdeniye ustraneniya

`git diff --check` zavershilsya kodom0 cherez obyortku. Predprosmotr zatem zavershilsya kodom0; rannyaya proverka paryi Zhurnala vernula kod0 i pustoj spisok oshibok. [Mashinnoye svideteljstvo](../Zhurnal/2026-09-15_02-42-44_MSK_prinyatj-obsjhij-paket-i-proveritj-podklyucheniye/materialyi/vosstanovleniye-predprosmotra.json) soderzhit imena nastoyasjhikh zapisej. Zakryitiye otnositsya k vosstanovleniyu podgotovki dannogo etapa.

## Istochniki

- [Zapros](../Zhurnal/2026-09-15_02-42-44_MSK_prinyatj-obsjhij-paket-i-proveritj-podklyucheniye/zapros.md).
- [Otchyot](../Zhurnal/2026-09-15_02-42-44_MSK_prinyatj-obsjhij-paket-i-proveritj-podklyucheniye/otchyot.md).
- [Shtatnaya avtomatizaciya](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 00:46:06 MSK -->
<!-- content-sha256: sha256:0c6b249de83e89d63d6948912f0489b203950a6d66164eb77e236286afb09bcf -->
<!-- FUM-MD-RECENCY:END -->
