# Otchyot 2026-09-11 17:00:29 MSK - Utochnitj svideteljstvo reglamenta YESIA

Utochnena odna fraza kartochki istoricheskogo istochnika: ogranicheniye kruga operatorov IS i yego primenimostj k FUMA ostayutsya neproverennyimi do polnogo aktualjnogo reglamenta. Koordinator i zadacha priyoma nezavisimo prinyali vosemj predmetnyikh kriteriyev kommita `6d933f9d5085e2ec8541883231ad762df46ef2c8`. Polnyij dopusk snimka ostayotsya otkryityim.

## Profilj vremeni vyipolneniya

| Stadiya                               | Dliteljnostj  | Granicyi i sposob izmereniya                                                  |
| ------------------------------------ | ------------- | --------------------------------------------------------------------------- |
| Soderzhateljnaya popravka i oformleniye | 424.493 s     | Ot 17:00:29 MSK do 17:07:33.492760 MSK; nastennyiye chasyi s yavnoj zonoj.       |
| Adresnyiye proverki                    | ne izmereno   | Proshli posle soderzhateljnoj granicyi; dliteljnosti processov privedenyi nizhe. |
| Standartnyij dokumentacionnyij smoke   | ne vyipolnyalsya | Ozhidaniye tochnoj deljtyi i okna koordinatora; ne vkhodit v izmerennuyu stadiyu.  |

Granica profilya: soderzhateljnaya stadiya izmerena ot nachala etoj papki Zhurnala do podgotovki otchyota pered proverkami. Predshestvuyusjheye chteniye posle vosstanovleniya otdeljno ne izmereno. Perekryitiya i processyi ne summiruyutsya so stadijnyim vremenem. Ozhidaniye okna, zaklyuchiteljnaya read-only-proverka kontroljnoj tochki, kommit i dostavka nakhodyatsya vne izmerennoj granicyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                 | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------- | ------------ | --------- |
| [Planirovsjhik Gosuslug] Proveritj reyestr posle utochneniya svideteljstva | 0,448 s      | uspeshno   |
| [Planirovsjhik Gosuslug] Proveritj tochnyij indeks popravki               | 0,035 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 0,483 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Adresnaya validaciya reyestra i tochnogo indeksa proshla cherez otchyotnuyu obyortku; obe terminaljnyiye zapisi uspeshnyi. Posle yeyo okonchaniya i aktualjnogo predprosmotra zaklyuchiteljnaya svyaznostj kontroljnoj tochki vyipolnyayetsya napryamuyu po uzkomu isklyucheniyu FUM-PRAVILO-000188. Standartnyij smoke, zakryitiye otchyota i novaya proyekciya yesjhyo ne vyipolnenyi.

Devyatj proverok proshlogo etapa zanimayut tochno 101.475970874 s; prezhnyaya tablica 101.475 s korrektna po summe okruglyonnyikh strok. Eti zapisi ne importiruyutsya povtorno v novyij otchyot. Novoye predmetnoye revjyu posle soobsjheniya zadachi priyoma ostanovleno; dopolniteljnyij rezuljtat ne prinyat.

Vo vremya oformleniya tablicyi rezuljtat susjhestvuyusjhego formattera oshibochno ispoljzovan kak stroka vmesto spiska strok. Lokaljnaya podgotovka ostanovilasj s TypeError do zapisi ispravleniya; prezhnyaya tablica byila vyivedena predstavleniyem spiska. Oshibka vyiyavlena chteniyem, podgotoviteljnaya proverka svyaznosti ostanovlena i tablica vosstanovlena shtatnyim rezuljtatom formattera. Eto ne otkaz predmetnogo plana.

## Resheniya i ogranicheniya

Zaklyuchiteljnaya svyaznostj kontroljnoj tochki potrebovala tochnoye imya fum-moskovskoye-vremya-rabochej-sessii v perechne instrumentov: kanonicheskij vyizov i yego rezuljtat uzhe byili ukazanyi slovami. Imya dobavleno, otkaz sokhranyon zdesj; povtor proveryayet ispravlennuyu paru Zhurnala.

Doslovnyiye utochneniya sokhranenyi v zaprose. Na zamechaniye koordinatora dana lokaljnaya popravka istochnika; novogo shirokogo issledovaniya net. Syiryiye fragmentyi ne izmenenyi. Predmetnaya priyomka sokhranena v shage 0215, status polnogo dopuska ne povyishen.

Nepolnota sokhranyonnogo svideteljstva zaregistrirovana kak FUM-SBOJ-0086 shtatnyim raspredelitelem nomerov i paketom diagnostiki. Predkorrekcionnoye utverzhdeniye i tochnyij kommit sokhranenyi, obsjhij shag 0114 obnovlyon dvustoronne. Tochechnaya pravka ne obyyavlena sistemnyim ustraneniyem; yego realizaciya vne analiticheskogo obyyoma.

Tochnaya ekvivalentnaya deljta instrumenta priyoma ozhidayetsya ot zadachi priyoma posle konechnogo kommita finansov. Sobstvennoye tyazhyoloye okno ne peredano. Ostatok soderzhit polucheniye deljtyi i okna, posleduyusjhij smoke, zamyikaniye otchyota i proyekcii, okonchateljnuyu dostavku dvum adresatam. Do etogo sokhranyayetsya proverennaya kontroljnaya tochka.

Susjhestvuyusjhaya proyekciya sokhranena bez peresborki: `fum.манифест-братиславской-проекции.2`, manifest `Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json`; vkhodnoj plan `sha256:5371a473cb08bd886d52142a75311cec03eda05658a9de27da21143d2adfa819`, inventarj `sha256:4f14956be3b309ea1fa5be7c2330255c7ea7f9348e56c3dccb229065dfa2fb13`, politika `sha256:6f6d399cfb2734a5445eeb52358af3a0d71c74d8b811416d9531b514b210993d`. Eto prezhneye pokoleniye bazyi; ono otstayot ot novyikh kanonicheskikh fajlov i zdesj zanovo ne proveryalosj.

## Istochniki

- [Iskhodnyiye komandyi i otvetyi](zapros.md).
- [Ostatok zadachi](materialyi/plan-prodolzheniya.json).
- [Predyidusjhij otchyot](../2026-09-11_16-18-37_MSK_podgotovitj-plan-Gosuslug/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 17:10:36 MSK -->
<!-- content-sha256: sha256:9feafd365552acd793cfb551e968cc33b2d7c94960c20be3500b8f51391b0581 -->
<!-- FUM-MD-RECENCY:END -->
