# Otchyot 2026-09-16 17:24:57 MSK - Zaregistrirovatj otkazyi finansovoj priyomki

Zaregistrirovanyi chetyire razdeljnyiye granicyi kornevogo finansovogo dopuska. Vyipusk vyipolnen susjhestvuyusjhim paketom diagnostiki: chetyire kartochki sboyev, tri kartochki shagov i dva indeksa. Kod i chuzhoj J6 ne izmenyalisj; sistemnyiye meryi i finansovaya priyomka ne obyyavlyayutsya zavershyonnyimi.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Iskhodnyij otkaz ssyilki, zapisj3 | 97,160715875 s | Istoricheskaya obyortka koordinatora; shag5, kod2 |
| Iskhodnyij otkaz okhvata, zapisj4 | 568,460521583 s | Istoricheskaya obyortka koordinatora; shag11, kod1 |
| Nevernyij rezhim svyaznosti, zapisj5 | 34,729466209 s | Istoricheskaya obyortka koordinatora; kod1 |
| Obyichnaya svyaznostj, zapisj6 | 34,370809459 s | Istoricheskaya obyortka koordinatora; tot zhe otpechatok, uspekh |
| Podgotovka i vyipusk diagnostiki | ne izmereno | Otdeljnyij monotonnyij interval ne sobiralsya |
| Adresnyiye proverki tekusjhego etapa | v mashinnom bloke | Polnyij process izmeryayet shtatnaya obyortka |

Granica profilya: istoricheskiye dliteljnosti poluchenyi iz neizmenyayemyikh zapisej, a ne izmerenyi povtorno. Vremena nativnyikh zapisej otkaza capture ne schitayutsya sobstvennoj dliteljnostjyu zakhvata. Tyazhyolyiye progonyi, proyekciya i finansovyiye izmereniya zdesj ne vyipolnyalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                              | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj planirovaniya] Rannyaya proverka polej finansovoj diagnostiki                 | 0,151 s      | neuspeshno |
| [Korenj planirovaniya] Adresnaya proverka paketa finansovoj diagnostiki i oformleniya | 26,264 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 26,415 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:357a3ee349b0a2a362fa97fafaf24956bf10e2485f1d56d282e3e312bc6c64d4.
Kontekst soderzhimogo: sha256:5277fa23db5e831544225a19995ad3bd7f6fc1cc25297fa619b78bbc135cd5af.
Polnyikh popyitok: 0; uspeshnyikh: 0.
Usloviye «perekhod ne zamenyayet izmeneniye soderzhimogo»: vyipolneno.
Usloviye «net aktivnyikh»: vyipolneno.
Usloviye «finaljnaya polnaya poslednyaya»: ne vyipolneno.
Usloviye «finaljnaya polnaya uspeshna»: ne vyipolneno.
Usloviye «snimok sovpadayet»: ne vyipolneno.
Usloviye «soderzhimoye sovpadayet»: ne vyipolneno.
Usloviye «net povtornyikh polnyikh popyitok»: vyipolneno.
Usloviye «lokalizacii svyazanyi s predshestvuyusjhim otkazom»: vyipolneno.
Usloviye «net zapresjhyonnyikh perekryitij»: vyipolneno.
Usloviye «nepokryityiye diagnostiki uspeshnyi»: vyipolneno.
Usloviye «istoricheskiye narusheniya otsutstvuyut»: vyipolneno.

<!-- FUM-CHECK-RUNS:END -->

## Klassifikaciya i naznacheniya

- 0051/0011:97 neobyyavlennyikh susjhestvuyusjhikh putej, iz nikh96 proyekcii i odin proizvodnyij reyestr; analog0004. STEP0225 obnovlyon. V sobstvennoj versii vosemj vklyuchyonnyikh proyavlenij;0006 zanyat,0009/0010 sokhranyayutsya u koordinatora i pri budusjhej integracii ne udalyayutsya.
- 0134/0002: kontroljnyij rezhim vnutri aktivnoj otchyotnoj obyortki; obyichnyij rezhim zatem proshyol na tom zhe otpechatke. STEP0174 obnovlyon, sistemnaya profilaktika ne dokazana.
- 0150/0001: aktivnaya ssyilka vne vklyuchyonnogo pokoleniya; novyijSTEP0231 soderzhit minimaljnyij plan rannej proverki. Ispravleniye ssyilki snyalo toljko etot otkaz, sleduyusjhij polnyij dopusk ostanovilsya po0051.
- 0151/0001: vneshnij predelcapture3700s prevyisil3600s. Pervichnyij otkaz i adresnaya proverka otsutstviya effekta vosstanovlenyi i sverenyi po chetyiryom raw-diapazonam; novoj zapisismoke ne byilo. Otdeljnaya granica parametrov svyazana sSTEP0174.

Koordinator naznachil lokaljnyiye nomera0051/0011 i0134/0002 posle okonchateljnoj sverki207refs po polnyim OID. Pervoye chteniye po imenam dalo preduprezhdeniya neodnoznachnosti i pereprovereno; okonchateljnyij SHA8f5765e5 sokhranyon. Setj i nezaregistrirovannyiye chastnyiye rezervyi vne sverki. NovyiyeID0150/0151/0231 vyidelenyi obsjhim raspredelitelem s proiskhozhdeniyem. Pervonachaljnoye osnovaniye rezerva0151 otrazhayet togdashneye otsutstviye syiroj paryi; pozdneye pervichnoye svideteljstvo dobavleno bez perepisyivaniya rezerva.

## Proverka istochnikov i sokhranyonnyiye granicyi

Terminaljnyiye zapisi3–6 skopirovanyi kak istoricheskiye materialyi, ne kak sobstvennyiye zapuski. Polnota zakhvatov i SHA stdout/stderr sverenyi; syiryiye privatnyiye puti i vnutrenniye id ne publikuyutsya. Polnoye pervichnoye porucheniye koordinatora sokhraneno privatno s SHA; publichnyij plan yavlyayetsya proizvodnyim izlozheniyem. Iskhodnaya finansovaya komanda sokhranena doslovno i proverena po native JSONL.

Kvitanciya vyipuska podtverzhdena chteniyem vsekh9 fajlov do proizvodnoj recency. Istoriya0051 ne podmenyayet nedostavlennyiye v etu bazu0009/0010. Staryiye11 obyazateljstv,0149, nasleduyemyij inventarj i finaljnaya proyekciya ostayutsya za prezhnimi granicami. Kontroljnaya tochka ne oznachayet integracii ili polnoj finansovoj priyomki.

## Oformleniye kontroljnoj tochki

Koordinator podtverdil prodolzheniye toljko prinyatoj diagnostiki i sokhraneniye tyazhyologo okna u integratora. Novyikh zadach ne sozdavalosj. Pervaya rannyaya proverka vyiyavila ostavshijsya marker shablona v upravlyayemom bloke otchyota; iskhod sokhranyon, blok sformirovan shtatnyim predprosmotrom pered povtornoj proverkoj. Predvariteljnyij vyizov predprosmotra do pervogo zapuska otkazal iz-za otsutstvuyusjhego kataloga; vruchnuyu katalog i zapisi ne sozdavalisj.

## Istochniki

- [Postanovka i prinyatyij plan](zapros.md).
- [Granica paketa](materialyi/granica-paketa.json) i [kvitanciya](materialyi/kvitanciya-paketa.json).
- [Okonchateljnaya sverka naznachenij](materialyi/okonchateljnaya-granica-naznachenij.json).
- [Ssyilka vne pokoleniya](materialyi/nablyudeniye-otkaza-3.json), [nepolnyij okhvat](materialyi/nablyudeniye-otkaza-4.json), [rezhim svyaznosti](materialyi/nablyudeniye-otkaza-5.json), [rannij otkaz zakhvata](materialyi/nablyudeniye-rannego-otkaza-zakhvata.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 17:48:33 MSK -->
<!-- content-sha256: sha256:87f0c524751871692c7e898acf611a27fc598fb5949b390f04330b1b8bb79d1d -->
<!-- FUM-MD-RECENCY:END -->
