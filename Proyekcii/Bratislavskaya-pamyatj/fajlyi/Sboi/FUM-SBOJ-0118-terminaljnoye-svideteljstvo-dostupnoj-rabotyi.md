+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0118"
"статус" = "активна"
+++
# Dostupnaya rabota poluchila terminaljnoye svideteljstvo

## Nablyudayemyij sboj

Plan etapa v kommite `c93b0fbca8c5d676eecec7023bc6df1a19c25b91` soderzhal nepustoye terminaljnoye svideteljstvo u dvukh dostupnyikh rabot. Guard shtatno otklonil nekorrektnyij vkhod kodom 2; etot rezuljtat ne ispoljzovan kak razresheniye zaversheniya.

## Granica povtoreniya

Podgotovka ili obnovleniye plana prodolzheniya ostavlyayet svideteljstvo pri sostoyanii «dostupna». Oshibki samogo guard i narusheniya uchyota proverok syuda ne otnosyatsya.

## Proyavleniya

- **FUM-SBOJ-0118/PROYAVLENIYE-0001.** [Prezhnij plan](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/materialyi/plan-etapa.json) soderzhal takiye znacheniya u rabot «sobstvennyiye-imena-postavki» i «zaregistrirovatj-otkloneniye-uchyota». [Publichnoye izvlecheniye iskhodnogo otveta](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/materialyi/nablyudeniya-vkhodnyikh-otkazov.json) podtverzhdayet kod 2. V novom plane svideteljstva dostupnyikh rabot privedenyi k `null`; guard ne izmenyon. Otdeljnaya zapisj testovogo zapuska dlya pervichnoj read-only-granicyi upravleniya ne sozdavalasj; vremya ne vosstanavlivayetsya zadnim chislom.

## Ozhidaniye i klassifikaciya

Dostupnaya rabota dolzhna imetj svideteljstvo `null`. Podtverzhdena nedorabotka podgotovki vkhodnyikh dannyikh; zasjhitnyij otkaz sootvetstvuyet kontraktu. Nepustyiye znacheniya dvukh rabot odnogo podgotovlennogo plana obrazuyut odno proyavleniye.

## Mekhanizm i sistemnoye ustraneniye

Neposredstvennyij defekt — nesoglasovannaya para sostoyaniya i svideteljstva pri ruchnoj podgotovke plana. Razovaya korrekciya vyipolnena; predlozhennaya konechnaya mera — proveryayemaya podgotovka i smena sostoyaniya plana s sokhraneniyem etogo invarianta. Predotvrasjheniye povtora yesjhyo ne dokazano, kod guard ne trebuyet izmeneniya po etomu nablyudeniyu.

## Svyazannyiye shagi

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) sokhranyayet predlozhennuyu meru korrektnoj podgotovki vkhoda prodolzheniya i dokazateljstvo vosstanovleniya; osnovaniye — FUM-SBOJ-0118/PROYAVLENIYE-0001. Registraciya fakta ne rasshiryayet tekusjhuyu priyomku do realizacii novoj sistemyi planov.

## Kriterii zakryitiya

Na tochnom istoricheskom nekorrektnom sluchaye sokhranyayetsya otkaz guard s kodom 2. Povtoryayemyij sposob podgotovki i obnovleniya plana ne ostavlyayet terminaljnogo svideteljstva u dostupnoj rabotyi; ispravleniye sokhranyayet samu dostupnuyu rabotu i obyazannostj prodolzheniya. Mera i proverka imeyut adresnyiye svideteljstva. Poka etogo net, status aktivnyij.

## Istochniki

- [Komanda koordinatora i iskhodnyij zapros](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/zapros.md).
- [Otchyot i granica vosstanovleniya](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/otchyot.md).
- [Tekusjhij plan](../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/materialyi/plan-etapa.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 21:05:29 MSK -->
<!-- content-sha256: sha256:a884bf168bee5fc98427bca3e089f0dc6413268658dc630677d2d68c639f2d67 -->
<!-- FUM-MD-RECENCY:END -->
