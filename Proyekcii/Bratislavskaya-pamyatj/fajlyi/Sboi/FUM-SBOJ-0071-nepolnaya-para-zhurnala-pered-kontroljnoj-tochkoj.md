+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0071"
"статус" = "активна"
+++
# Nepolnaya para Zhurnala pered proverkoj svyaznosti

## Nablyudayemyij sboj

Para Zhurnala etapa 08:49 ne soderzhala tryokh obyazateljnyikh elementov: tochnogo zagolovka stolbca profilya, tochnogo imeni instrumenta moskovskogo vremeni i bukvaljnoj nepustoj stroki granicyi profilya. Dve posledovateljnyiye proverki svyaznosti otklonili etot vkhod.

## Granica povtoreniya

Chetyire sokhranyonnyikh v etoj kartochke epizoda nepolnoj kanonicheskoj paryi: etapyi 08:49 i 10:00, uchyot semi komand 15 sentyabrya i podgotovka obyyedineniya 03:35. Nomera 0003 i 0004 uzhe zanyatyi v drugikh rabochikh derevjyakh; ikh svideteljstva zdesj ne vosproizvodyatsya. Otricateljnyiye kontroli odnoj paryi lokalizuyut odno proyavleniye; raznyiye propusjhennyiye polya ne stanovyatsya otdeljnyimi kartochkami. Rannij vyizov svyaznosti 0176 do pervonachaljnogo predprosmotra — drugoj podgotoviteljnyij mekhanizm i uzhe sokhranyon otdeljno.

## Proyavleniya

### FUM-SBOJ-0071/PROYAVLENIYE-0001

Pervyij kontrolj: chunk beb9bb, kod 1, 38,102 s. Vmesto «Granicyi i sposob izmereniya» byil stolbec «Granica»; v razdele instrumentov otsutstvovalo tochnoye fum-moskovskoye-vremya-rabochej-sessii. Povtor processa 82329: chunk 825f33, kod 1, 37,644 s — otsutstvovala nepustaya stroka «Granica profilya:». Posle ispravleniya vsej paryi process 76503 zavershilsya uspeshno.

### FUM-SBOJ-0071/PROYAVLENIYE-0002

Predvariteljnaya svyaznostj finaljnogo etapa 10:00:32: v4 `661533e7-e8c5-42a5-95a7-269a1f684075`, kod 1, 41,246191583 s. Metka «Granica profilya podgotovki:» ne sootvetstvovala tochnomu «Granica profilya:»; ssyilka `./` ne obyyavlyala dva obyazateljnyikh fajla paryi. Metka i pryamyiye ssyilki ispravlenyi. Eto povtor togo zhe kontrakta obyazateljnogo zapolneniya do svyaznosti; vtoroj polnyij smoke do ispravleniya ne zapuskalsya. [Pervichnyij otkaz i vosstanovleniye](../Zhurnal/2026-09-11_10-00-32_MSK_zavershitj-priyom-napravlenij-FUMA/otchyot.md).

### FUM-SBOJ-0071/PROYAVLENIYE-0005

Pri uchyote semi komand dve posledovateljnyiye proverki kontroljnoj tochki otklonili otchyot: snachala tretij stolbec profilya nazyivalsya «Granica» vmesto «Granicyi i sposob izmereniya», zatem posle ispravleniya zagolovka otsutstvovala nepustaya stroka «Granica profilya:». Obe oshibki otnosyatsya k odnoj pare Zhurnala. Otricateljnyiye rezuljtatyi sokhranenyi razdeljno; avtomatizaciya obnaruzhila narusheniya praviljno. Do uspeshnogo zaklyuchiteljnogo kontrolya kommit etogo etapa ne sozdavalsya. [Otchyot i tochnyiye otkazyi](../Zhurnal/2026-09-15_00-00-47_MSK_uchestj-semj-aktualjnyikh-komand/otchyot.md). Polnogo izmereniya dliteljnosti dvukh otkazov net; vremya ne vosstanavlivayetsya zadnim chislom.

### FUM-SBOJ-0071/PROYAVLENIYE-0006

Pri podgotovke obyyedineniya rannij vkhod obnaruzhil sokrasjhyonnyij zagolovok kolonki profilya i otsutstviye tochnogo imeni navyika vremeni; posle ikh ispravleniya — otsutstviye prefiksa «Granica profilya:». Eto povtor toj zhe granicyi odnoj paryi. [Mashinnyiye zapisi](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/materialyi/ranniye-otkazyi-polej.json) sokhranyayut oba otkaza i sleduyusjhij kod0. Korenj vyizval rannyuyu proverku do polnoj priyomki; novyikh testov ili izmeneniya proveryayusjhego koda ne potrebovalosj. Obsjhaya avtomaticheskaya podgotovka korrektnoj paryi etim ne zavershena.

## Ozhidaniye i klassifikaciya

Svyaznostj poluchayet zavershyonnuyu kanonicheskuyu paru s obyazateljnyimi polyami i nablyudyonnyim vremennyim intervalom. Zasjhita praviljno otklonila nepolnoye oformleniye. Oshibki vyichisleniya moskovskogo vremeni ili samikh izmerenij ne ustanovlenyi.

## Mekhanizm i sistemnoye ustraneniye

Vosstanovlenyi tochnyij zagolovok tablicyi, imya instrumenta i stroka «Granica profilya:». Nablyudyonnyij interval 08:49:30–09:03:50 MSK sokhranyon. Posle shtatnyikh predprosmotra, recency i tochnogo staging povtorena neobkhodimaya svyaznostj; predmetnyiye regressii ne povtoryalisj radi oformleniya. Avtomaticheskoye predotvrasjheniye vsekh budusjhikh propuskov ne zayavlyayetsya.

## Svyazannyiye shagi

Tochnoye osnovaniye aktualizacii susjhestvuyusjhego [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0002`: rannyaya proverka obyazateljnyikh polej paryi do dorogoj priyomki. Vtoroj epizod vozvrasjhayet kartochku v aktivnoye sostoyaniye; pervoye ogranichennoye vosstanovleniye sokhranyayetsya istoricheski. Novogo STEP net. Povtor `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0005` podtverzhdayet prezhnyuyu granicu rannej proverki; chastnoye ispravleniye tekusjhego otchyota ne zakryivayet obsjhuyu meru.

Povtor `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0006` dobavlen k tomu zhe aktivnomu 0174: rannij vkhod obnaruzhil nesootvetstviye do dorogogo obkhoda, a vosproizvodimaya podgotovka samoj paryi ostayotsya neobkhodimoj.

## Kriterii zakryitiya

Vse sokhranyonnyiye paryi imeyut obyazateljnyiye polya i uspeshnyiye lokaljnyiye proverki; do dorogoj priyomki proveryayemaya rannyaya granica 0174 obnaruzhivayet otsutstviye tochnyikh metok profilya i pryamyikh ssyilok na fajlyi paryi. Lokaljnoye vosstanovleniye vtorogo epizoda ne obyyavlyayetsya ispolneniyem etoj budusjhej obsjhej meryi.

## Istoricheskoye podtverzhdeniye ogranichennogo ustraneniya

Pervichnyij rezuljtat chunk 892d4b: session coherence check passed, kod 0, 37,537 s; process 76503. Posle kontrolya prinyat ef458281e95048e361afb92e73ec960677b95c50 s roditelem ef55be2ff2fe997a0f5780f01f5742a66e95a535. V kommite prochitanyi tochnyiye obyazateljnyiye polya i sokhranyonnyij interval. Eto priyomka dannoj kontroljnoj tochki, ne polnyij smoke i ne zaversheniye 0201 ili FUMA.

## Istochniki

[Otchyot prinyatiya zavisimostej DNK](https://github.com/fum-lab/fum/blob/ef458281e95048e361afb92e73ec960677b95c50/Журнал/2026-09-11_08-49-30_MSK_принять-перекодирование-ДНК-в-белки/отчёт.md)

[Tekusjhaya registraciya i pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 04:26:02 MSK -->
<!-- content-sha256: sha256:b5f3241046e851d54049df3225c73a495db93f57b1c407a9f307c32f3d15e944 -->
<!-- FUM-MD-RECENCY:END -->
