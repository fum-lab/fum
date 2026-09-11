+++
schema_version = 1
card_id = "FUM-STEP-0174"
status = "active"
+++
# Opisyivatj primeneniye avtomatizacij bez chteniya koda

## Zadacha

Zakrepitj opisaniye avtomatizacij cherez ponyatnyiye dejstviya i nablyudayemyiye rezuljtatyi. Obyichnoye primeneniye dolzhno obkhoditjsya bez razbora realizacii; razrabotka, diagnostika i optimizaciya sokhranyayut dostup k iskhodnikam.

## Pochemu sejchas

Poljzovatelj poprosil zakrepitj primeneniye avtomatizacij bez chteniya iskhodnikov, ustranitj pozdneye obnaruzheniye uzhe izvestnyikh pravil i obespechitj sokhrannostj nablyudenij pri szhatii konteksta. V tekusjhem etape obnaruzhenyi konkretnyiye sluchai, gde deshyovaya predvariteljnaya proverka mogla predotvratitj povtor dorogoj priyomki.

## Blizhajshiye etapyi

1. Utochnitj kanonicheskoye tematicheskoye pravilo: naznacheniye, usloviya i sposob zapuska, vkhodnyiye dannyiye, rezuljtat, tipichnyiye oshibki i ogranicheniya. Soglasovatj inventarj pravil i proveryayemuyu granicu validatora bez dublirovaniya norm. Primenitj opisaniye k tekusjhej komande ostatka obyazateljstv.
2. Do dorogoj peresborki proveryatj deshyovyiye prichinyi otkaza: sobstvennyiye imena novyikh obyyavlenij i nalichiye doslovnyikh komand v soobsjhenii kommita. Uchityivatj tochnyij izmenyonnyij nabor i istoricheskiye isklyucheniya; proveritj sluchai rannego otkaza.
3. Proveritj vosstanovleniye nevyipolnennogo nablyudeniya po kanonicheskoj zapisi i proiskhozhdeniyu posle poteri tekusjhego konteksta. Vetka dlya samoj zapisi ne trebuyetsya; pozdniye utochneniya vo vremya neizmenyayemoj priyomki sokhranyayutsya vne checkout s posleduyusjhim perenosom.

## Vyipolnennaya chastj i prodolzheniye

Normativnaya chastj podgotovlena v [otdeljnom etape](../../Zhurnal/2026-09-10_13-40-29_MSK_zakrepitj-pravila-opisaniya-avtomatizacij-i-priyomki-sliyanij/zapros.md): pravilo `FUM-ПРАВИЛО-НОВОЕ-000010` ispoljzuyet susjhestvuyusjhuyu tochku vkhoda bez novogo obyazateljnogo shablona. [Rukovodstvo komandyi ostatka](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/ostatok-obyazateljstv.md) prinyato v `76f71fad3adab90f85ae31cb2f7d75f6ceb12e8d`. Ranniye proverki i scenarij vosstanovleniya nablyudeniya ostayutsya sleduyusjhimi etapami; kartochka ostayotsya aktivnoj.

## Kriterii zaversheniya

- Poljzovatelj mozhet opredelitj primenimostj, zapustitj avtomatizaciyu i ponyatj yeyo rezuljtat po opisaniyu bez chteniya realizacii.
- Norma zakreplena v obyazateljnom nabore pravil i svyazana s doslovnyim iskhodnyim soobsjheniyem.
- Podtverzhdyon rannij otkaz do dorogogo shaga na dvukh obnaruzhennyikh klassakh narushenij; istoricheskij ostatok ne vyidayotsya za novoye narusheniye.
- Nevyipolnennoye nablyudeniye nakhoditsya po sokhranyonnoj zapisi nezavisimo ot pamyati modeli; zayavlennaya granica dolgovechnosti sootvetstvuyet fakticheskomu khraneniyu.

## Utochneniye po povtoru obyazateljnyikh polej paryi

`FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0002` dopolnyayet rannyuyu proveryayemuyu granicu obyazateljnyim zapolneniyem kanonicheskoj paryi: tochnaya nepustaya metka «Granica profilya:», tochnyiye zagolovki tablicyi i pryamyiye ssyilki na sobstvennyiye zapros i otchyot. Skhodnaya podpisj i `./` ne zamenyayut mashinnyij kontrakt. Nuzhnyi dokumentirovannyiye usloviya i rannij otkaz do dorogogo shaga; ispravlennyij vruchnuyu dokument ne schitayetsya realizaciyej obsjhej profilaktiki. Iskhodnyiye kriterii dvukh prezhnikh klassov sokhranyayutsya.

## Istochniki

- [Povtor nepolnoj paryi Zhurnala](../../Sboi/FUM-SBOJ-0071-nepolnaya-para-zhurnala-pered-kontroljnoj-tochkoj.md) — tochnoye osnovaniye `FUM-СБОЙ-0071/ПРОЯВЛЕНИЕ-0002`; [pervichnaya proverka](../../Zhurnal/2026-09-11_10-00-32_MSK_zavershitj-priyom-napravlenij-FUMA/otchyot.md).
- [Komandyi, otvetyi i obnaruzhennyiye problemyi](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/zapros.md).
- [Plan i proiskhozhdeniye nablyudenij](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/materialyi/plan-opisaniya-avtomatizacij.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 10:32:01 MSK -->
<!-- content-sha256: sha256:86e6b1c38ac1b202cb164e68f28ef74533b59d6afbab26598f98850a5d0b6005 -->
<!-- FUM-MD-RECENCY:END -->
