+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0077"
"статус" = "активна"
+++
# Dopusk protivorechivogo statusa cherez Setext pri korrekcii

## Nablyudayemyij sboj

Na versii 73c proverka korrekcii trebovaniya dopuskala dobavleniye deklaracii 🟡 v pervyij ATX-razdel pri uzhe imeyusjhejsya vidimoj deklaracii ✅ pod posleduyusjhim zagolovkom Setext. Poluchalisj protivorechivyiye statusyi pri sokhranenii prezhnikh bajtov. Oshibka vosproizvedena v otkryitom teste, realjnyiye nedopustimyiye kartochechnyiye ili vneshniye effektyi ne ustanovlenyi.

## Granica povtoreniya

Propusk ogranicheniya additivnoj korrekcii statusa iz-za aljternativnogo oformleniya vidimogo zagolovka. Eto odno proyavleniye s chetyirjmya podsluchayami. 0059 opisyivayet otkaz dopustimogo vosstanovleniya, 0075 — iskhodnoye otsutstviye stroki; obsjhego mekhanizma s nimi, 0005 i 0041 nezavisimyij osmotr ne ustanovil. Eta kartochka ne utverzhdayet polnotu proizvoljnogo Markdown-parsinga.

## Proyavleniya

- `FUM-СБОЙ-0077/ПРОЯВЛЕНИЕ-0001`: [RED 256717c6-65a1-4925-8c98-bd5aa4795842](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/zapuski-proverok/1_256717c6-65a1-4925-8c98-bd5aa4795842.json) pokazal chetyire oshibochnyikh dopuska: obyichnyij Setext-zagolovok, mnogostrochnoye nazvaniye s odnoj chertoj, formatirovaniye s otstupom i odin znak ravenstva. [Pyatj GREEN](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/materialyi/zapuski-proverok/2_d76922fb-4ef2-4ee9-97cf-7f49ef8da920.json) podtverzhdayut adresnoye ispravleniye, vklyuchaya iskhodnyij razreshyonnyij vkhod.

## Ozhidaniye i klassifikaciya

Ogranichennaya vstavka razreshena toljko pri otsutstvii susjhestvuyusjhej deklaracii statusa i yedinstvennom razdele granic. Nepolnoye raspoznavaniye vidimogo zagolovka narushalo etu uzhe zayavlennuyu granicu; eto podtverzhdyonnaya nedorabotka dopuska.

## Mekhanizm i sistemnoye ustraneniye

Podschyot zagolovkov uchityival toljko ATX. Novaya additivnaya vetka posle udaleniya bloka svezhesti konservativno otklonyayet otdeljnuyu stroku iz defisov ili znakov ravenstva s otstupom do tryokh probelov i probeljnyim khvostom. Usloviye ne zavisit ot oformleniya ili chisla strok zagolovka; gorizontaljnyiye razdeliteli takogo vida tozhe otklonyayutsya i eto ogranicheniye opisano. Obyichnyij putj s neizmennyim razdelom proveryayetsya pervyim i ne izmenyon.

## Svyazannyiye shagi

[STEP 0213](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0213-proveritj-ogranichennoye-vosstanovleniye-statusa-priyoma.md) prinimayet ogranichennoye vosstanovleniye i regressionnuyu granicu po `FUM-СБОЙ-0077/ПРОЯВЛЕНИЕ-0001`.

## Kriterii zakryitiya

Vse chetyire sokhranyonnyikh Setext-vkhoda otvergayutsya do namereniya i kartochechnyikh effektov; iskhodnaya dopustimaya vstavka prezhnego statusa i prezhniye ogranicheniya povtorov sokhranenyi. Imeyutsya tochnyiye RED/GREEN, profilj i obyyasneniye konservativnoj granicyi. Izmenyonnyij sposob proshyol samostoyateljnuyu polnuyu priyomku v zakryitom otchyote. Obsjhaya korrektnostj Markdown etim ne dokazyivayetsya.

## Istochniki

- [Komandyi i faktyi tekusjhego etapa](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/zapros.md), [otchyot i granica profilya](../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/otchyot.md).
- [Otkryitaya regressiya](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_ispravleniya_priyoma.py), [rukovodstvo](../Instrumentyi/fum-reyestr-planirovaniya/priyom-napravlenij.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:10:58 MSK -->
<!-- content-sha256: sha256:bb4db2600e2b9f24f589a85d98c7654b14012db39cff2a23993ce1f61fddf672 -->
<!-- FUM-MD-RECENCY:END -->
