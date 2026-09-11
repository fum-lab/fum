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

## Utochneniye po povtoru pervonachaljnogo predprosmotra

`FUM-СБОЙ-0064/ПРОЯВЛЕНИЕ-0002` dopolnyayet rannyuyu proveryayemuyu granicu shtatnyim pervonachaljnyim predprosmotrom upravlyayemogo bloka otchyota do recency, svyaznosti i dorogoj priyomki. Otsutstvuyusjhij predprosmotr otlichayetsya ot ustarevshego otpechatka uzhe sformirovannogo bloka i ot propuska obyazateljnyikh polej paryi. Dokumentirovannyij scenarij dolzhen formirovatj blok shtatnoj avtomatizaciyej; otricateljnaya regressiya obnaruzhivayet otsutstviye ili pustoye napolneniye do zavisimyikh dorogikh proverok, polozhiteljnaya sokhranyayet tochnyiye terminaljnyiye zapisi. Lokaljnoye vosstanovleniye tekusjhego otchyota ne schitayetsya realizaciyej obsjhej profilaktiki. Prezhniye kriterii i rabota po drugim obnaruzhennyim klassam sokhranyayutsya.

## Istochniki

- [Povtor propuska pervonachaljnogo predprosmotra](../../Sboi/FUM-SBOJ-0064-svyaznostj-do-predprosmotra-otchyota.md) — tochnoye osnovaniye `FUM-СБОЙ-0064/ПРОЯВЛЕНИЕ-0002`; [pervichnaya proverka i vosstanovleniye](../../Zhurnal/2026-09-11_13-05-09_MSK_prinyatj-sravneniye-dekodirovaniya/otchyot.md).

- [Komandyi, otvetyi i obnaruzhennyiye problemyi](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/zapros.md).
- [Plan i proiskhozhdeniye nablyudenij](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/materialyi/plan-opisaniya-avtomatizacij.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 13:39:49 MSK -->
<!-- content-sha256: sha256:62543b3a10d4b9bc762ad7df578e621dc1b15b4316adf5c166a89ed4803389cf -->
<!-- FUM-MD-RECENCY:END -->
