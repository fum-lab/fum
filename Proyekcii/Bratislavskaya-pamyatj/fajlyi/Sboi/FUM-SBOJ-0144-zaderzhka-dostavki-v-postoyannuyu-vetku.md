+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0144"
"статус" = "активна"
+++
# FUM-SBOJ-0144 — Zaderzhka dostavki v postoyannuyu vetku

## Nablyudayemyij sboj

Korenj postoyannoj FUMA publikoval kontroljnyiye tochki v otdeljnoj integracionnoj vetke i prodolzhal vyibiratj sleduyusjhiye etapyi, ne dostaviv nakoplennyij rezuljtat v naznachennuyu postoyannuyu vetku fuma. Pered ispravleniyem ona ostavalasj na `dfa04ed6c03ff3363d175e39f937f8aa118d993c`, a integracionnaya vetka na `87c3b63ba80e8aa2b806e0028b0ed96b10f3a8fe` soderzhala 50 posleduyusjhikh kommitov. U vladeljca ne byilo nesokhranyonnoj rabotyi ili vstrechnyikh kommitov.

## Granica povtoreniya

Kartochka otnositsya k propusku obyazateljnogo perekhoda ot podgotovlennoj postavki k naznachennoj postoyannoj vetke pri dostupnom vladeljce i izvestnom puti dostavki. Obosnovannoye ozhidaniye chuzhogo pisatelya, nastoyasjhego konflikta, neproverennogo istochnika ili nedostupnosti remote ne schitayetsya takim proyavleniyem. Povtornyiye voprosyi ob odnom zaderzhannom perenose ne schitayutsya otdeljnyimi proyavleniyami.

## Proyavleniya

1. `FUM-СБОЙ-0144/ПРОЯВЛЕНИЕ-0001`: voprosyi poljzovatelya i otvet kornya v [etape priyomki](../Zhurnal/2026-09-15_17-27-51_MSK_prinyatj-ustojchivyiye-svideteljstva-i-dostavku/zapros.md), proverennyiye Git OID, 0/50 po sravneniyu predkov i podtverzhdeniye prezhnego pisatelya. Posle kontroljnoj tochki `19765643195f0fb87dce58c7aba7fd1b50301531` korenj prinyal vladeniye, vyipolnil fast-forward 51 kommita i podtverdil tot zhe OID v origin/fuma. Eto vosstanovleniye, ne sistemnoye zakryitiye.

## Ozhidaniye i klassifikaciya

Pravilo 000121 zakreplyalo posledovateljnuyu istoriyu tekusjhej postoyannoj zadachi za refs/heads/fuma. Poljzovatelj otdeljno podtverdil prioritet integracii. Klassifikaciya — nedorabotka vyibora sleduyusjhego etapa i koordinacii kornya. Pravilo susjhestvovalo do nablyudeniya; nekhvatka pravila ne zayavlyayetsya prichinoj.

## Mekhanizm i sistemnoye ustraneniye

Ustanovlennoye dejstviye kornya: posle kommitov on vyibiral sleduyusjhiye infrastrukturnyiye etapyi, ne vyipolniv dostupnuyu peredachu v postoyannuyu vetku. Ne primenena sverka fakticheskoj vetki i vladeljca s naznacheniyem postoyannoj zadachi. Obsjheye predpolozheniye o potere etogo obyazateljstva pri perenose rabochego konteksta trebuyet otdeljnoj proverki.

Vremennoye vosstanovleniye — podtverzhdyonnaya peredacha vladeniya i fast-forward v fuma s sokhraneniyem lokaljnyikh dannyikh. Ustojchivaya mera — yavnoye sostoyaniye naznacheniya i dostavki, avtomaticheskij signal prosrochennogo prinyatogo sreza, vyibor dostavki pered neobyazateljnyim novyim etapom i kvitanciya poluchatelya. Polnomochiya vladeljca i dopuskayemyiye proverki sokhranyayutsya. Obnaruzhennaya nesovmestimostj CLI paketnoj diagnostiki s imenem fuma takzhe dolzhna uchityivatjsya pri podderzhke postoyannyikh vetok.

## Svyazannyiye shagi

- [FUM-STEP-0228](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0228-kontrolirovatj-dostavku-v-postoyannuyu-vetku.md) — osnovnoj shag, porozhdyon proyavleniyem 0001: kontrolj naznacheniya, signal otstavaniya, prioritet dejstviya i kvitanciya. Ispoljzuyet susjhestvuyusjhuyu narabotku obratnoj dostavki vmesto vtorogo Git-dvizhka.

## Kriterii zakryitiya

- Vosproizvedyon nablyudyonnyij scenarij: gotovaya promezhutochnaya postavka, postoyannaya vetka-predok, prezhnij pisatelj zhdyot koordinacii, korenj sobirayetsya vyibratj novyij neobyazateljnyij etap. Detektor vozvrasjhayet prioritetnuyu dostavku i tochnoye osnovaniye.
- Podderzhanyi soglasovannaya peredacha vladeljca, zasjhisjhyonnyij fast-forward ili yavnoye otlozhennoye sostoyaniye; dirty, neizvestnyij vladelec, konflikt i ustarevshij plan ne obkhodyatsya.
- Rezuljtat sokhranyayet source/ref/OID, prinyatuyu granicu, lokaljnyij i udalyonnyij iskhodyi; povtor ne sozdayot povtornogo effekta. Kontekst posle vosstanovleniya sokhranyayet nedostavlennuyu obyazannostj.
- Proverenyi otsutstviye lozhnogo signala na uzhe dostavlennom rezuljtate i stoimostj nablyudeniya. Razovoye prodvizheniye fuma ne zakryivayet kartochku.

## Istochniki

- [Iskhodnyiye voprosyi i priznannaya prichina](../Zhurnal/2026-09-15_17-27-51_MSK_prinyatj-ustojchivyiye-svideteljstva-i-dostavku/otchyot.md).
- [Registraciya i plan realizacii](../Zhurnal/2026-09-15_17-55-33_MSK_vernutj-dostavku-v-postoyannuyu-vetku/zapros.md).
- [Pravilo postoyannoj istorii](../Pravila/agentov/zhurnal-i-proiskhozhdeniye.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 18:06:12 MSK -->
<!-- content-sha256: sha256:4655561b88c2e68b01a63ef3276d808691f38460ee7a9a02ed4aa2abe84e25bb -->
<!-- FUM-MD-RECENCY:END -->
