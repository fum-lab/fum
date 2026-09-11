+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0071"
"статус" = "активна"
+++
# Nepolnaya para Zhurnala pered proverkoj svyaznosti

## Nablyudayemyij sboj

Para Zhurnala etapa 08:49 ne soderzhala tryokh obyazateljnyikh elementov: tochnogo zagolovka stolbca profilya, tochnogo imeni instrumenta moskovskogo vremeni i bukvaljnoj nepustoj stroki granicyi profilya. Dve posledovateljnyiye proverki svyaznosti otklonili etot vkhod.

## Granica povtoreniya

Dva otdeljnyikh epizoda nepolnoj kanonicheskoj paryi: etapyi 08:49 i 10:00. Otricateljnyiye kontroli odnoj paryi lokalizuyut odno proyavleniye; raznyiye propusjhennyiye polya ne stanovyatsya otdeljnyimi kartochkami. Rannij vyizov svyaznosti 0176 do pervonachaljnogo predprosmotra — drugoj podgotoviteljnyij mekhanizm i uzhe sokhranyon otdeljno.

## Proyavleniya

### FUM-SBOJ-0071/PROYAVLENIYE-0001

Pervyij kontrolj: chunk beb9bb, kod 1, 38,102 s. Vmesto «Granicyi i sposob izmereniya» byil stolbec «Granica»; v razdele instrumentov otsutstvovalo tochnoye fum-moskovskoye-vremya-rabochej-sessii. Povtor processa 82329: chunk 825f33, kod 1, 37,644 s — otsutstvovala nepustaya stroka «Granica profilya:». Posle ispravleniya vsej paryi process 76503 zavershilsya uspeshno.

### FUM-SBOJ-0071/PROYAVLENIYE-0002

Predvariteljnaya svyaznostj finaljnogo etapa 10:00:32: v4 `661533e7-e8c5-42a5-95a7-269a1f684075`, kod 1, 41,246191583 s. Metka «Granica profilya podgotovki:» ne sootvetstvovala tochnomu «Granica profilya:»; ssyilka `./` ne obyyavlyala dva obyazateljnyikh fajla paryi. Metka i pryamyiye ssyilki ispravlenyi. Eto povtor togo zhe kontrakta obyazateljnogo zapolneniya do svyaznosti; vtoroj polnyij smoke do ispravleniya ne zapuskalsya. [Pervichnyij otkaz i vosstanovleniye](../Zhurnal/2026-09-11_10-00-32_MSK_zavershitj-priyom-napravlenij-FUMA/otchyot.md).

## Ozhidaniye i klassifikaciya

Svyaznostj poluchayet zavershyonnuyu kanonicheskuyu paru s obyazateljnyimi polyami i nablyudyonnyim vremennyim intervalom. Zasjhita praviljno otklonila nepolnoye oformleniye. Oshibki vyichisleniya moskovskogo vremeni ili samikh izmerenij ne ustanovlenyi.

## Mekhanizm i sistemnoye ustraneniye

Vosstanovlenyi tochnyij zagolovok tablicyi, imya instrumenta i stroka «Granica profilya:». Nablyudyonnyij interval 08:49:30–09:03:50 MSK sokhranyon. Posle shtatnyikh predprosmotra, recency i tochnogo staging povtorena neobkhodimaya svyaznostj; predmetnyiye regressii ne povtoryalisj radi oformleniya. Avtomaticheskoye predotvrasjheniye vsekh budusjhikh propuskov ne zayavlyayetsya.

## Svyazannyiye shagi

Tochnoye osnovaniye aktualizacii susjhestvuyusjhego [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0002`: rannyaya proverka obyazateljnyikh polej paryi do dorogoj priyomki. Vtoroj epizod vozvrasjhayet kartochku v aktivnoye sostoyaniye; pervoye ogranichennoye vosstanovleniye sokhranyayetsya istoricheski. Novogo STEP net.

## Kriterii zakryitiya

Obe sokhranyonnyiye paryi imeyut obyazateljnyiye polya i uspeshnyiye lokaljnyiye proverki; do dorogoj priyomki proveryayemaya rannyaya granica 0174 obnaruzhivayet otsutstviye tochnyikh metok profilya i pryamyikh ssyilok na fajlyi paryi. Lokaljnoye vosstanovleniye vtorogo epizoda ne obyyavlyayetsya ispolneniyem etoj budusjhej obsjhej meryi.

## Istoricheskoye podtverzhdeniye ogranichennogo ustraneniya

Pervichnyij rezuljtat chunk 892d4b: session coherence check passed, kod 0, 37,537 s; process 76503. Posle kontrolya prinyat ef458281e95048e361afb92e73ec960677b95c50 s roditelem ef55be2ff2fe997a0f5780f01f5742a66e95a535. V kommite prochitanyi tochnyiye obyazateljnyiye polya i sokhranyonnyij interval. Eto priyomka dannoj kontroljnoj tochki, ne polnyij smoke i ne zaversheniye 0201 ili FUMA.

## Istochniki

[Otchyot prinyatiya zavisimostej DNK](https://github.com/fum-lab/fum/blob/ef458281e95048e361afb92e73ec960677b95c50/Журнал/2026-09-11_08-49-30_MSK_принять-перекодирование-ДНК-в-белки/отчёт.md)

[Tekusjhaya registraciya i pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 10:32:01 MSK -->
<!-- content-sha256: sha256:419b73bf0ed4f65e43bc73ea1233f4b66f5c871c87245a107bc3ef969c9fb231 -->
<!-- FUM-MD-RECENCY:END -->
