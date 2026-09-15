+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0049"
"статус" = "активна"
+++
# Propusk vidimoj zadachi pishusjhej rabotyi

Sokhranyonnoye ukazaniye pokazyivatj nezavisimyiye pishusjhiye rabotyi otdeljnyimi zadachami Codex Desktop primenyalosj neposledovateljno: planirovaniye poluchilo vidimuyu zadachu, a drugiye derevjya ostavalisj u iskhodnoj zadachi i vnutrennikh subagentov. Tekusjhaya peredacha vosstanovlena, no ustojchivostj primeneniya pri sleduyusjhikh naznacheniyakh yesjhyo trebuyet proverki.

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0049/ПРОЯВЛЕНИЕ-0001`: 2026-09-11 01:16:55 MSK poljzovatelj povtorno sprosil, pochemu otdeljnyiye sessii dlya rabochikh derevjyev sistematicheski ne sozdayutsya. Realjnyij otvet 01:17:17 MSK priznal neposledovateljnoye ispolneniye: otdeljnaya zadacha susjhestvovala dlya planirovaniya, drugiye rabotyi ostavalisj pod upravleniyem iskhodnoj zadachi i subagentov. Komanda i otvet sokhranenyi v [tekusjhem zaprose](../Zhurnal/2026-09-11_01-26-17_MSK_podtverzhdatj-vidimyiye-zadachi-nezavisimyikh-rabot/zapros.md) i [otchyote](../Zhurnal/2026-09-11_01-26-17_MSK_podtverzhdatj-vidimyiye-zadachi-nezavisimyikh-rabot/otchyot.md).

Pervonachaljnoye ozhidaniye zadano [9 sentyabrya](../Zhurnal/2026-09-09_11-39-26_MSK_predotvratitj-poteryu-obyazateljstv-postoyannoj-zadachi/zapros.md); ono ne schitayetsya otdeljnyim narusheniyem. Zdesj zaregistrirovan odin podtverzhdyonnyij pozdnij epizod povtornogo neispolneniya, zatronuvshij neskoljko rabot. Slovo «sistematicheski» ne zamenyayet inventarj otdeljnyikh proyavlenij.

Granica — naznacheniye nezavisimogo pisatelya posle sokhranyonnogo zaprosa vidimosti bez podtverzhdeniya otdeljnoj zadachi. Sboj 0018 kasayetsya nazvaniya susjhestvuyusjhej zadachi, 0026 — nezakreplyonnogo ukazaniya, 0027 — prezhdevremennogo zaversheniya. Obsjhaya sistemnaya mera dlya ikh obyyedineniya ne dokazana.

## Gipoteza mekhanizma

Ukazaniye traktovalosj kak razovyij vyibor pri sozdanii predyidusjhikh zadach; otdeljnyiye worktree i vnutrennij ispolnitelj oshibochno schitalisj dostatochnyim rezuljtatom. Eto gipoteza o mekhanizme, a ne nablyudeniye skryitogo sostoyaniya modeli.

## Vosstanovleniye i sistemnaya mera

Susjhestvuyusjhiye normyi `000061` i `000162` utochnenyi: sokhranyonnoye ukazaniye primenyayetsya pri kazhdom sleduyusjhem naznachenii i posle vosstanovleniya konteksta. Sozdaniye, podgotovka i podtverzhdyonnyij zapusk razlichayutsya. Zapusk svyazyivayet nastoyasjhij task ID, adresnyij status i otvet, fizicheskij worktree, polnyij ref, HEAD, yedinstvennogo pisatelya i otdeljno zaproshennuyu i nablyudyonnuyu modelj. Nepolnyij obsjhij spisok i odin clientThreadId ne razreshayut obyyavitj uspekh ili sozdatj dublikat.

[Svideteljstvo tekusjhego vosstanovleniya](../Zhurnal/2026-09-11_01-26-17_MSK_podtverzhdatj-vidimyiye-zadachi-nezavisimyikh-rabot/materialyi/podtverzhdeniye-vidimyikh-zadach.md) fiksiruyet dve realjnyiye zadachi i granicyi proverki. Pravilo trebuyet ispolneniya agentom; mashinnyij zapret propuska i podklyuchyonnyij runtime ne zayavlyayutsya.

## Kriterij zakryitiya

Konechnyij vosproizvodimyij scenarij dolzhen podtverditj primeneniye proceduryi pri sleduyusjhem nezavisimom naznachenii i posle vosstanovleniya konteksta. Proveryayutsya podgotovka s odnim clientThreadId, otsutstviye izvestnoj zadachi v obsjhem spiske, nepodtverzhdyonnaya modelj i podtverzhdyonnyij zapusk. Nepolnoye svideteljstvo ne stanovitsya uspekhom i ne porozhdayet dublikat. Polozhiteljnyij iskhod tekusjhej peredachi sam po sebe ne zakryivayet etot kriterij.

## Svyazannyiye shagi

- [FUM-STEP-0196 — proveryatj vidimostj nezavisimoj pishusjhej rabotyi](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0196-proveryatj-vidimostj-nezavisimoj-pishusjhej-rabotyi.md): osnovaniye `FUM-СБОЙ-0049/ПРОЯВЛЕНИЕ-0001`.

## Istochniki

- [Iskhodnyij zapros i utochneniye](../Zhurnal/2026-09-11_01-26-17_MSK_podtverzhdatj-vidimyiye-zadachi-nezavisimyikh-rabot/zapros.md).
- [Sokhranyonnoye ozhidaniye](../Zhurnal/2026-09-09_11-39-26_MSK_predotvratitj-poteryu-obyazateljstv-postoyannoj-zadachi/zapros.md).
- [Pravilo instrumentov](../Pravila/agentov/lokaljnyiye-navyiki-i-instrumentyi.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:40:19 MSK -->
<!-- content-sha256: sha256:ba8bb2f4673e1770994e52b0374940294c7b09ae4216236c4b6e295277313e8b -->
<!-- FUM-MD-RECENCY:END -->
