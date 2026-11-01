+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0071"
"статус" = "активна"
+++
# Nepolnaya para Zhurnala pered proverkoj svyaznosti

## Nablyudayemyij sboj

Para Zhurnala etapa 08:49 ne soderzhala tryokh obyazateljnyikh elementov: tochnogo zagolovka stolbca profilya, tochnogo imeni instrumenta moskovskogo vremeni i bukvaljnoj nepustoj stroki granicyi profilya. Dve posledovateljnyiye proverki svyaznosti otklonili etot vkhod.

## Granica povtoreniya

Devyatj sokhranyonnyikh v etoj kartochke epizodov nepolnoj kanonicheskoj paryi: etapyi 08:49 i 10:00, uchyot semi komand 15 sentyabrya, podgotovka obyyedineniya 03:35 predposyilka master 23:33 tri paryi mediapaketa 0008–0010 i integraciya rannej sverki 0011. Nomera 0003 i 0004 uzhe zanyatyi v drugikh rabochikh derevjyakh; ikh svideteljstva zdesj ne vosproizvodyatsya. Otricateljnyiye kontroli odnoj paryi lokalizuyut odno proyavleniye; raznyiye propusjhennyiye polya ne stanovyatsya otdeljnyimi kartochkami. Rannij vyizov svyaznosti 0176 do pervonachaljnogo predprosmotra — drugoj podgotoviteljnyij mekhanizm i uzhe sokhranyon otdeljno.

## Proyavleniya

### FUM-SBOJ-0071/PROYAVLENIYE-0001

Pervyij kontrolj: chunk beb9bb, kod 1, 38,102 s. Vmesto «Granicyi i sposob izmereniya» byil stolbec «Granica»; v razdele instrumentov otsutstvovalo tochnoye fum-moskovskoye-vremya-rabochej-sessii. Povtor processa 82329: chunk 825f33, kod 1, 37,644 s — otsutstvovala nepustaya stroka «Granica profilya:». Posle ispravleniya vsej paryi process 76503 zavershilsya uspeshno.

### FUM-SBOJ-0071/PROYAVLENIYE-0002

Predvariteljnaya svyaznostj finaljnogo etapa 10:00:32: v4 `661533e7-e8c5-42a5-95a7-269a1f684075`, kod 1, 41,246191583 s. Metka «Granica profilya podgotovki:» ne sootvetstvovala tochnomu «Granica profilya:»; ssyilka `./` ne obyyavlyala dva obyazateljnyikh fajla paryi. Metka i pryamyiye ssyilki ispravlenyi. Eto povtor togo zhe kontrakta obyazateljnogo zapolneniya do svyaznosti; vtoroj polnyij smoke do ispravleniya ne zapuskalsya. [Pervichnyij otkaz i vosstanovleniye](../Zhurnal/2026-09-11_10-00-32_MSK_zavershitj-priyom-napravlenij-FUMA/otchyot.md).

### FUM-SBOJ-0071/PROYAVLENIYE-0005

Pri uchyote semi komand dve posledovateljnyiye proverki kontroljnoj tochki otklonili otchyot: snachala tretij stolbec profilya nazyivalsya «Granica» vmesto «Granicyi i sposob izmereniya», zatem posle ispravleniya zagolovka otsutstvovala nepustaya stroka «Granica profilya:». Obe oshibki otnosyatsya k odnoj pare Zhurnala. Otricateljnyiye rezuljtatyi sokhranenyi razdeljno; avtomatizaciya obnaruzhila narusheniya praviljno. Do uspeshnogo zaklyuchiteljnogo kontrolya kommit etogo etapa ne sozdavalsya. [Otchyot i tochnyiye otkazyi](../Zhurnal/2026-09-15_00-00-47_MSK_uchestj-semj-aktualjnyikh-komand/otchyot.md). Polnogo izmereniya dliteljnosti dvukh otkazov net; vremya ne vosstanavlivayetsya zadnim chislom.

### FUM-SBOJ-0071/PROYAVLENIYE-0006

Pri podgotovke obyyedineniya rannij vkhod obnaruzhil sokrasjhyonnyij zagolovok kolonki profilya i otsutstviye tochnogo imeni navyika vremeni; posle ikh ispravleniya — otsutstviye prefiksa «Granica profilya:». Eto povtor toj zhe granicyi odnoj paryi. [Mashinnyiye zapisi](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/materialyi/ranniye-otkazyi-polej.json) sokhranyayut oba otkaza i sleduyusjhij kod0. Korenj vyizval rannyuyu proverku do polnoj priyomki; novyikh testov ili izmeneniya proveryayusjhego koda ne potrebovalosj. Obsjhaya avtomaticheskaya podgotovka korrektnoj paryi etim ne zavershena.

### FUM-SBOJ-0071/PROYAVLENIYE-0007

[Pervichnyij otkaz predposyilki master](../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/pervyij-otkaz-svyaznosti-predposyilki.json) — process 9434, kod 1: posle tablicyi otsutstvovala bukvaljnaya nepustaya stroka «Granica profilya:». Tochnyij istochnik i SHA privedenyi v [registracii](../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/povtoryi-oformleniya.json). Vladelec ispravil pole pered povtornoj svyaznostjyu; eto povtor podgotovki paryi, a ne defekt samoj proverki. Prezhniye zakryityiye etapyi ne perepisanyi.

### FUM-SBOJ-0071/PROYAVLENIYE-0008

Para Luna low kommita `b2df928066fa84d3bf7ab8100baf519e934e4233` soderzhit dva zagolovka instrumentov i nezapolnennyiye elementyi otchyota. Vse chetyire zapisi proverok imeyut kod 1, v tom chisle nazvannaya GREEN. Polozhiteljnyij samootchyot ne podtverzhdayet dopusk etoj paryi.

### FUM-SBOJ-0071/PROYAVLENIYE-0009

Para Luna high kommita `193279364854a6081491e02c26dd8c6f66dce0ca` soderzhit povtornyij zagolovok instrumentov, shablonnyiye tablicu i granicu profilya. V zapros skopirovana prezhnyaya postanovka vmesto fakticheskogo porucheniya ispravleniya; yego original vosstanovlen v novom etape, ne podmenyon v starom.

### FUM-SBOJ-0071/PROYAVLENIYE-0010

Para Sol high kommita `abc217c2760c6cbeb778833116a619ba8df644ad` snova soderzhit dva zagolovka instrumentov, instrukcii zapolneniya i shablon profilya. Ssyilki vyivodili za checkout. Publikaciya kommita ne byila priyomkoj oformleniya; rannij zapusk kommita otdeljno uchityivayetsya v 0078/0002.

[Pobajtnyiye svideteljstva tryokh par](../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/svideteljstva-prezhnikh-par.json) sokhranyayut puti, polnyiye OID, SHA i nomera strok. [Novaya korrekciya](../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/korrekciya-istorii.md) ne perepisyivayet prezhniye otchyotyi; ogranichenno ispravlenyi desyatj destination. V iskhodnom finansovom nabore nomera 0003, 0004 i 0007 byili zanyatyi vne yego; obyyedineniye sokhranyayet 0007 vyishe, a 0003 i 0004 ostayutsya vne etoj kartochki. Povtoryi 0008–0010 aktualiziruyut prezhnij aktivnyij STEP0174; ruchnoye zapolneniye novoj paryi ne zakryivayet sistemnuyu meru.

### FUM-SBOJ-0071/PROYAVLENIYE-0011

Pri integracii rannej sverki STEP-0225 otchyot snova ne soderzhal bukvaljnoj nepustoj stroki «Granica profilya:». Standartnyij progon `907ffee2-59b0-4d52-bbd3-d62d7cdfda94` proshyol 10 shagov i ostanovilsya na svyaznosti za 613,865 s. Stroka vosstanovlena; otdeljnaya adresnaya svyaznostj zavershilasj kodom 0. [Pervichnyij otkaz i ispravleniye](../Zhurnal/2026-09-18_12-24-43_MSK_integrirovatj-rannyuyu-sverku-materialov/otchyot.md) ne zakryivayut sistemnuyu meru. Rannyaya sverka sostava fajlov ne proveryayet formu vremennogo profilya; sleduyusjhij srez susjhestvuyusjhego STEP0174 dolzhen proveryatj etu formu do proyekcii, ne dubliruya uzhe prinyatyij razbor fajlov.

## Ozhidaniye i klassifikaciya

Svyaznostj poluchayet zavershyonnuyu kanonicheskuyu paru s obyazateljnyimi polyami i nablyudyonnyim vremennyim intervalom. Zasjhita praviljno otklonila nepolnoye oformleniye. Oshibki vyichisleniya moskovskogo vremeni ili samikh izmerenij ne ustanovlenyi.

## Mekhanizm i sistemnoye ustraneniye

Vosstanovlenyi tochnyij zagolovok tablicyi, imya instrumenta i stroka «Granica profilya:». Nablyudyonnyij interval 08:49:30–09:03:50 MSK sokhranyon. Posle shtatnyikh predprosmotra, recency i tochnogo staging povtorena neobkhodimaya svyaznostj; predmetnyiye regressii ne povtoryalisj radi oformleniya. Avtomaticheskoye predotvrasjheniye vsekh budusjhikh propuskov ne zayavlyayetsya.

## Svyazannyiye shagi

Tochnoye osnovaniye aktualizacii susjhestvuyusjhego [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0002`: rannyaya proverka obyazateljnyikh polej paryi do dorogoj priyomki. Vtoroj epizod vozvrasjhayet kartochku v aktivnoye sostoyaniye; pervoye ogranichennoye vosstanovleniye sokhranyayetsya istoricheski. Novogo STEP net. Povtor `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0005` podtverzhdayet prezhnyuyu granicu rannej proverki; chastnoye ispravleniye tekusjhego otchyota ne zakryivayet obsjhuyu meru.

Povtor `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0006` dobavlen k tomu zhe aktivnomu 0174: rannij vkhod obnaruzhil nesootvetstviye do dorogogo obkhoda, a vosproizvodimaya podgotovka samoj paryi ostayotsya neobkhodimoj.

Povtor `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0007` dopolnyayet tot zhe STEP0174: obyazateljnyiye polya dolzhnyi formirovatjsya do zaklyuchiteljnogo obkhoda; lokaljnoye zapolneniye ne zavershayet avtomatizaciyu.

## Proveryayemaya mera rannego otkaza

[Etap podklyucheniya](../Zhurnal/2026-09-19_00-58-49_MSK_podklyuchitj-rannyuyu-proverku-polej-zhurnala/otchyot.md) ispoljzuyet gotovuyu proverku polej pervyim ispolnyayemyim shagom smoke. Krasnyij test podtverdil otsutstviye takogo poryadka i prinyatiye ssyilok vne nuzhnogo razdela; zelyonyiye regressii proveryayut ostanovku posle yedinstvennogo vyizova i obe pryamyiye roli. Granica priyomki meryi podtverzhdayetsya zakryityim otchyotom etapa; kartochka ostayotsya aktivnoj.

## Kriterii zakryitiya

Dlya istoricheski neprinyatyikh par 0008–0010 sokhranyayutsya iskhodnyiye bajtyi, otricateljnyiye iskhodyi i otdeljnaya novaya korrekciya; ikh perepisyivaniye zadnim chislom ne trebuyetsya i ne dokazyivayet ustraneniye. Aktualjnaya podgotovlennaya para imeyet obyazateljnyiye polya i dejstviteljnyij uspeshnyij dopusk. Do dorogoj priyomki proveryayemaya rannyaya granica 0174 obnaruzhivayet otsutstviye tochnyikh metok profilya i pryamyikh ssyilok na fajlyi paryi. Prezhniye ogranichennyiye vosstanovleniya 0001 i 0002 sokhranyayutsya; lokaljnoye zapolneniye odnoj novoj paryi ne obyyavlyayetsya ispolneniyem etoj budusjhej obsjhej meryi.

## Istoricheskoye podtverzhdeniye ogranichennogo ustraneniya

Pervichnyij rezuljtat chunk 892d4b: session coherence check passed, kod 0, 37,537 s; process 76503. Posle kontrolya prinyat ef458281e95048e361afb92e73ec960677b95c50 s roditelem ef55be2ff2fe997a0f5780f01f5742a66e95a535. V kommite prochitanyi tochnyiye obyazateljnyiye polya i sokhranyonnyij interval. Eto priyomka dannoj kontroljnoj tochki, ne polnyij smoke i ne zaversheniye 0201 ili FUMA.

## Istochniki

[Otchyot prinyatiya zavisimostej DNK](https://github.com/fum-lab/fum/blob/ef458281e95048e361afb92e73ec960677b95c50/Журнал/2026-09-11_08-49-30_MSK_принять-перекодирование-ДНК-в-белки/отчёт.md)

[Tekusjhaya registraciya i pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 01:10:33 MSK -->
<!-- content-sha256: sha256:19a310c8b1d20aadd02e70e46123c6392d6added1c07b709c4c06decdc3992d2 -->
<!-- FUM-MD-RECENCY:END -->
