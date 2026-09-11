# Otchyot 2026-09-11 18:02:51 MSK - Perenesti deljtu tiljdovoj ogradyi

Perenesenyi ekvivalentnaya zapisj ASCII-tiljdyi v odnom regulyarnom vyirazhenii ispolnitelya priyoma i test dvenadcati sochetanij ogradyi. Iskhodnik finansov `6c9babdd3663ff0112283b89a361068727825da6` prochitan kak tochnyij diff; sobstvennyiye Setext-zasjhita i porucheniye o perekhode detached HEAD sokhranenyi. Podgotovka otnositsya k tekhnicheskomu dopusku raneye prinyatogo analiticheskogo plana.

## Profilj vremeni vyipolneniya

| Stadiya                                      | Dliteljnostj                 | Granicyi i sposob izmereniya                                                                |
| ------------------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------- |
| ispravleniye celikom                         | 3195.724333 → 3438.351459 ms | Do → posle; mediana tryokh Git-fikstur; vlozhennyiye intervalyi ne summiruyutsya.                 |
| tochnyij povtor                               | 282.051917 → 296.472708 ms   | Do → posle; mediana tryokh Git-fikstur; vlozhennyiye intervalyi ne summiruyutsya.                 |
| proverka granic kartochek vnutri ispravleniya | 0.386583 → 0.407208 ms       | Do → posle; mediana tryokh Git-fikstur; vlozhennyiye intervalyi ne summiruyutsya.                 |
| Soderzhateljnaya podgotovka i ozhidaniye        | ne izmereno                  | Nachalo etapa 18:02:51 MSK; polnyij smoke ne zapuskalsya, ozhidaniye okna otdeljno ne oceneno. |

Granica profilya: dva otdeljnyikh zapuska sokhranyonnoj avtomatizacii na odnom scenarii «propusjhennyij status», Python 3.14.7/Darwin. Fiksturyi otkryityiye, setj ne ispoljzuyetsya. Podgotovka Git isklyuchena; realjnaya korrekciya, povtor, sborka, ustanovka i proverka granic izmerenyi yavno. Vlozhennyiye vremena ne pribavlyayutsya k celomu. Kommit, dostavka, ozhidaniye okna i zaklyuchiteljnaya svyaznostj vne etoj granicyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                         | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------- | ------------ | --------- |
| [Planirovsjhik Gosuslug] RED: publikacionnaya nakhodka do perenosa deljtyi         | 23,476 s     | neuspeshno |
| [Planirovsjhik Gosuslug] Iskhodnyij profilj korrekcii statusa                     | 16,741 s     | uspeshno   |
| [Planirovsjhik Gosuslug] Iskhodnoye povedeniye ograd i obyichnoj vstavki             | 0,26 s       | uspeshno   |
| [Planirovsjhik Gosuslug] GREEN: ogradyi, Setext i obyichnaya vstavka posle perenosa | 0,265 s      | uspeshno   |
| [Planirovsjhik Gosuslug] Profilj korrekcii posle ekvivalentnoj deljtyi           | 17,515 s     | uspeshno   |
| [Planirovsjhik Gosuslug] GREEN: publikacionnaya proverka sobstvennogo snimka     | 22,545 s     | uspeshno   |
| [Planirovsjhik Gosuslug] Proveritj reyestr tekhnicheskogo ostatka                  | 0,445 s      | uspeshno   |
| [Planirovsjhik Gosuslug] Proveritj tochnyij indeks perenosa                       | 0,031 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 81,278 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Do khunka scanner vernul code 1 na yedinstvennoj dejstvuyusjhej nakhodke `Инструменты/fum-reyestr-planirovaniya/scripts/исполнитель_приёма.py:85:error.home-expansion`. Eto RED publikacionnogo dopuska; test smyislovoj ekvivalentnosti zakonomerno prokhodit i do pravki. Do khunka proshli dva adresnyikh testa ograd i dopustimoj vstavki. Posle khunka proshli tri testa, vklyuchaya sobstvennuyu Setext-zasjhitu. Profili do i posle takzhe proveryayut nastoyasjheye ispravleniye i identichnyij povtor.

Tekhnicheskij RO nezavisimo sopostavil dve versii i istochnik. Finansovyiye zapisi scanner 5/8 imeyut code 1; zapisj 12 proveryayet ogradyi i vstavku, 16 — scanner code 0; full 20 imeyet code 0 i 1108.017330917 s. Ikh snimok `sha256:d09125e6010195b6e0f35ff79a8242414d970c73c08366db66851e1721062f69` otnositsya k finansovomu kommitu i ne zamenyayet svoj dopusk. RO ne zapuskal processyi i ne pereschityival vse khyeshi svideteljstv; eto ogranicheniye sokhraneno.

Publikacionnyij scanner sobstvennogo snimka posle perenosa zavershilsya code 0; dejstvuyusjhikh narushenij net. Reyestr tekhnicheskogo ostatka proshyol adresnuyu proverku. Politika i scanner ostalisj prezhnimi.

## Resheniya i ogranicheniya

Profilj ne dokazyivayet uskoreniye: sobstvennyiye medianyi celogo ispravleniya vyirosli s 3195.724333 do 3438.351459 ms, proverki granic — s 0.386583 do 0.407208 ms. Tri nezavisimyiye Git-fiksturyi ne izoliruyut stoimostj regulyarnogo vyirazheniya ot ostaljnyikh rabot i sredyi. Osnovaniya menyatj algoritm ili dobavlyatj kyesh net: vyibrannaya popravka sokhranyayet povedeniye i ustranyayet konkretnuyu publikacionnuyu nakhodku; daljnejshaya optimizaciya ne vyipolnyayetsya.

Koordinator podtverdil prinyatiye istochnika i snova otlozhil nash full do yavnogo okna posle M i korotkogo Swift Linux. Novoye predmetnoye issledovaniye Gosuslug ne trebuyetsya. Pri uspeshnyikh adresnyikh proverkakh sokhranyayetsya kontroljnaya tochka; zaklyuchiteljnaya svyaznostj vyipolnyayetsya posle aktualjnogo predprosmotra. Polnoye zamyikaniye otchyota, proyekcii i finaljnaya dostavka ostayutsya v plane prodolzheniya.

Susjhestvuyusjheye pokoleniye `Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json` ne peresobiralosj: skhema `fum.манифест-братиславской-проекции.2`, plan `sha256:5371a473cb08bd886d52142a75311cec03eda05658a9de27da21143d2adfa819`, inventarj `sha256:4f14956be3b309ea1fa5be7c2330255c7ea7f9348e56c3dccb229065dfa2fb13`, politika `sha256:6f6d399cfb2734a5445eeb52358af3a0d71c74d8b811416d9531b514b210993d`. Eto otstayusjhij ot tekusjhikh kanonicheskikh fajlov vkhod bazyi; novyij uspekh proyekcii ne zayavlyayetsya.

## Istochniki

- [Komandyi i otvet](zapros.md), [ostatok](materialyi/plan-prodolzheniya.json).
- [Profilj do](materialyi/profili/do-perenosa.json), [profilj posle](materialyi/profili/posle-perenosa.json).
- [Tochnyij finansovyij istochnik](https://github.com/fum-lab/fum/commit/6c9babdd3663ff0112283b89a361068727825da6).
- [Sokhranyonnoye rukovodstvo priyoma](../../Instrumentyi/fum-reyestr-planirovaniya/priyom-napravlenij.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 18:09:25 MSK -->
<!-- content-sha256: sha256:832bbff56ef95468321c6dcd847265389d52f7cab7ea0e06028aba70099e1c2b -->
<!-- FUM-MD-RECENCY:END -->
