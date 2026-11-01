# Otchyot 2026-09-19 02:44:26 MSK - Izmeritj polnyij nabor proverok reyestra

Predyidusjhaya kontroljnaya tochka 145c82b88beaee89d6654a1d46f8f6a913560c0a opublikovana v fuma i proverena udalyonnyim OID. D22 ostayotsya na pauze. Ostatok obsjhego obyyoma ne zavershyon, guard posle J24 vernul kod 3.

Etot etap izmeryayet susjhestvuyusjhij nabor reyestra standartnyim cProfile, bez novogo diagnosticheskogo framework i bez izmeneniya testovogo runner. Celj — otdelitj sovokupnuyu stoimostj discovery i konstruktorov ot vyipolneniya testov, zatem vyibratj opravdannyij uchastok optimizacii. Binarnyij profilj ostayotsya vne Git; publichnaya svodka soderzhit toljko otnositeljnyiye puti sobstvennyikh iskhodnikov i chislennyiye rezuljtatyi.

## Profilj vremeni vyipolneniya

| Stadiya                           | Dliteljnostj | Granicyi i sposob izmereniya                              |
| -------------------------------- | ------------ | ------------------------------------------------------- |
| Vesj diagnosticheskij process     | 481,193 s    | Monotonnyij interval otchyotnoj obyortki                    |
| Ispolneniye unittest              | 463,382 s    | 355 testov; itogovyij vyivod OK                           |
| Discovery                        | 17,705 s     | cProfile, vklyuchayet import i konstruirovaniye testov      |
| Vyizovyi tel testov                | 454,663 s    | Summa cumulative dlya _callTestMethod, vnutri ispolneniya |
| Nakladnyiye raskhodyi profilirovsjhika | ne izmerenyi  | Vklyuchenyi v nablyudayemyiye intervalyi                        |

Granica profilya: odin posledovateljnyij zapusk; vlozhennyiye cumulative-intervalyi ne summiruyutsya. Sravneniye s prezhnimi 490,878 s J22 ne dokazyivayet uskoreniya ili zamedleniya: otlichayutsya vkhod i instrumentirovaniye.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                               | Dliteljnostj | Rezuljtat |
| --------------------------------------------------- | ------------ | --------- |
| [korenj] Profilj polnogo nabora reyestra             | 481,193 s    | uspeshno   |
| [korenj] Polya Zhurnala J25                           | 0,089 s      | uspeshno   |
| [korenj] Publikacionnyij dopusk profilya J25          | 33,948 s     | neuspeshno |
| [korenj] Rannyaya sverka yavnogo sostava J25           | 0,625 s      | uspeshno   |
| [korenj] polya J25 posle predstavleniya builtin       | 0,086 s      | uspeshno   |
| [korenj] publikaciya J25 posle predstavleniya builtin | 33,756 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 549,697 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:bbc35aad65588d1f073a0564a77e80ba934cad513bde0eead2448e6df80be02b.
Kontekst soderzhimogo: sha256:95395d55d60b2447705db46a5cce9aeed1739de0f3f54c326156f281b9c8ab0a.
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

## Proverki

Proshli 355 testov: zavershyonnyij vyivod unittest soderzhit «Ran 355 tests in 463.382s» i «OK». Otchyotnaya obyortka zafiksirovala 481,193 s i kod processa 0. Khyeshi vsekh 54 vkhodnyikh Python-fajlov posle zapuska sovpali s iskhodnyimi. Polnaya priyomka koda J24 otdeljno ostayotsya otkryitoj.

## Rezuljtat i sleduyusjhij uchastok

Podgotovka testov ne obyyasnyayet osnovnuyu zaderzhku. Konstruktor obsjhej fiksturyi obratnoj dostavki byil vyizvan 61 raz i zanyal 16,659 s cumulative. Osnovnaya stoimostj nakhoditsya vnutri vyipolneniya testov.

V profile 34 646 vyizovov subprocess.run s sovokupnyim vremenem 453,027 s. Eto chislo vyizovov funkcii, a ne dokazannyij schyotchik uspeshno sozdannyikh processov. Sredi sobstvennyikh cepochek: dostavka_git.vyipolnitj — 11 653 vyizova i 143,755 s; ispolnitelj_priyoma.podgotovitj — 70 i 118,098 s; istoriya_puti_gita.prochitatj_istoriyu — 513 i 51,088 s. Intervalyi vlozhenyi i ne summiruyutsya. Read-only-razbor vyidelil malyij kandidat: poluchitj derevjya dvukh fiksirovannyikh OID odnim rev-parse vmesto dvukh. Chastota etoj vetvi otdeljno ne izmerena, susjhestvennyij vyiigryish ne obesjhayetsya. Povtornyiye proverki priyoma razdelenyi zapisjyu namereniya i zamkami, udalyatj ikh bez dokazateljstv neljzya. Sleduyusjhij kandidat — sokrasjheniye povtornyikh Git-vyizovov vnutri dokazuyemo neizmennogo vkhoda; kyeshirovatj izmenyayemyiye refs bez proverki neljzya.

Nezavisimyij analiz takzhe podtverdil otdeljnyij deshyovyij vyiigryish rabochego cikla: susjhestvuyusjhuyu sverku materialov mozhno vyizyivatj v sozdanii kommita do chteniya boljshogo JSONL. Nuzhen obyazateljnyij yavnyij spisok razreshyonnyikh putej v novoj podgotovke, sokhraneniye vosstanovleniya prezhnikh kvitancij i povtornaya sverka snimka pered dorogoj svyaznostjyu. Eto plan sleduyusjhego sreza, yesjhyo ne realizaciya.

## Osobennostj standartnogo profilirovsjhika

Prochitannaya realizaciya Python 3.14.7 profile._Utils.runctx perekhvatyivayet SystemExit; cProfile.main ispoljzuyet yeyo. Poetomu kod 0 diagnosticheskogo processa sam po sebe ne podtverzhdayet uspekh unittest. V dannom zapuske uspekh otdeljno ustanovlen po zavershyonnomu vyivodu s chislom testov i OK, yego SHA i tochnyij itog sokhranenyi. Khyeshi modulej profile.py i cProfile.py vklyuchenyi v svodku. Dlya budusjhego priyomochnogo runner nuzhno yavno vozvrasjhatj rezuljtat unittest, ne polagatjsya na kod CLI cProfile.

## Resheniya i ogranicheniya

Imena metodov cProfile pokazyivayut agregirovannyiye intervalyi i chislo vyizovov. Oni ne vsegda dayut otdeljnuyu stoimostj kazhdogo parametrizovannogo ekzemplyara. Stoimostj Git otnositsya k dochernim processam i ozhidaniyu; Python-profilj ne raskryivayet vnutrennyuyu rabotu Git. Yesli etikh granic nedostatochno, sleduyusjhij eksperiment dobavit adresnyiye metki.

## Publikacionnoye predstavleniye

Pervyij skaner otklonil chetyire specialjnyikh markera vstroyennyikh funkcij pstats kak error.home-expansion. Eto ne domashniye puti: v proizvodnoj svodke oni predstavlenyi yavnoj metkoj builtin, a iskhodnyij binarnyij profilj sokhranyon otdeljno s SHA. Skaner ne oslablyalsya; pervyij otkaz ostayotsya v zapuskakh.

## Istochniki

- [iskhodnyij zapros](zapros.md).
- [svodka profilya](materialyi/profilj-nabora.json), [vkhod i khyeshi](materialyi/vkhod-profilya.json), [tochnyij itog unittest](materialyi/itog-unittest.txt).
- [profilj odnoj fiksturyi J24](../2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 03:02:33 MSK -->
<!-- content-sha256: sha256:4180be8dbfa9bfab9dda0df2accc5afff1731913eea96e782df36ebfbb1484b9 -->
<!-- FUM-MD-RECENCY:END -->
