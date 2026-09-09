# Otchyot 2026-09-08 20:55:36 MSK - Zasjhititj istoricheskiye profili pri pereimenovanii

Specializirovannoye pereimenovaniye teperj sokhranyayet bajtyi istoricheskoj sverki obyyavlenij i prodolzhayet obnovlyatj zhivyiye ssyilki. Uzkij adapter proveryayet susjhestvuyusjhij format v tochnoj zhurnaljnoj oblasti; povrezhdeniye zakryivayet komandu do zapisi. Zavershyon adresnyij cikl TDD i profilirovaniya v sobstvennoj dochernej vetke.

## Otvetyi na upravlyayusjhiye soobsjheniya

1. Komanda o dochernikh vetkakh vyipolnena v vyidelennom worktree i sobstvennoj vetke codex/zasjhita-profilej-01a07d3d. V chuzhiye rabochiye derevjya, indeks, refs i konfiguraciyu zapisj ne velasj. Kornevoj identifikator proiskhozhdeniya peredan yavno.
2. Prioritetnoye ispravleniye ostanovki prodolzheno ogranichennoj podzadachej: ustraneno prepyatstviye bezopasnomu zaversheniyu kartochki FUM-STEP-0154. Sama kartochka ne pereimenovyivalasj. Nezavisimyij korenj vyipolnyayet integraciyu posle proverki rezuljtata.

## Izmeneniye i dokazateljstvo

Pri chtenii koda obnaruzhena bezuslovnaya zamena prezhnego imeni v UTF-8. V istoricheskom profile pri baze ab3a9d24 pole `файлы[14].путь` oboznachayet obsledovannyij fajl. Nastoyasjhij `git mv` v avtonomnoj Git-fiksture vosproizvyol izmeneniye etikh istoricheskikh dannyikh: pervyij RED zavershilsya kodom 1.

Adapter prinimayet lishj tochnyij zhurnaljnyij putj i konechnuyu strukturu chetyiryokh polej s unikaljnyimi normalizovannyimi putyami i celochislennyimi schyotchikami. Povtornyiye ili neizvestnyiye polya, nevernyiye tipyi, nedostupnostj, simvolicheskiye ssyilki i ne-UTF-8 profilj otklonyayutsya do podgotovki zapisej. Vtoroj RED obnaruzhil pustoj otnositeljnyij putj `.`; ogranicheniye utochneno, vse 16 testov zavershilisj uspeshno. Tri oshibki etogo RED otnosyatsya k odnomu dopusjhennomu pereimenovaniyu: dva posleduyusjhikh subTest uvideli uzhe izmenyonnyij indeks fiksturyi.

Istoricheskij material nastoyasjhego dereva sokhranil SHA-256 `25d10592d01d3d1ec0edf44db70556e9be44aad44e8cd2b1a8d96ea14436c579`. Novyiye syiryiye zapisi ne perepisyivalisj. [Kartochka sboya FUM-SBOJ-0031](../../Sboi/FUM-SBOJ-0031-perezapisj-istoricheskogo-profilya-pri-pereimenovanii-kartochki.md) sokhranyayet proyavleniye i kriterii ustraneniya. Nezavisimyij read-only-agent proveril kod s SHA-256 `d49a74b767783e18ce4a7b1673c960f54070cbcaaa86d688a5bd7aeab5fd61a7` i testyi s SHA-256 `933436efb3b537454a396e902085b0e42bfab9b7fa9af9eb3a192c6f10dc0f62`; susjhestvennyikh zamechanij ne polucheno.

## Profilirovaniye i resheniye ob optimizacii

[Vosproizvodimyij scenarij](materialyi/profili/profilirovatj-pereimenovaniye.py) sozdayot odnu nastoyasjhuyu Git-fiksturu i po pyatj svezhikh kopij dlya versii bazyi 955851da i izmenyonnoj versii. Podgotovka kopii nakhoditsya vne izmeryayemogo intervala. Monotonnyiye metki razlichayut chteniye s validaciyej, plan zamen i vneshneye pereimenovaniye; vnutrenniye stadii vlozhenyi vo vneshnyuyu i ne summiruyutsya s nej. Scenarij sam proveryayet praviljnostj zhivogo rezuljtata i ozhidayemoye sokhraneniye profilya posle ispravleniya.

[Iskhodnyiye izmereniya](materialyi/profili/izmereniya.json) sokhranyayut khyeshi koda, obsjhij khyesh vkhoda, versiyu Python 3.14.7, vse pyatj povtorov, iskhodyi i medianyi. Obsjhaya mediana: 96,028125 ms do izmeneniya i 93,214792 ms posle. Chteniye i validaciya: 0,531084 i 0,771750 ms; plan zamen: 0,443584 i 0,324958 ms. Raznica obsjhego vremeni mala i ne obyyavlyayetsya uskoreniyem. Dobavlennaya proverka stoit doli millisekundyi na etom scenarii, poetomu dopolniteljnyij kyesh ili izmeneniye tranzakcionnogo algoritma ne opravdanyi. Etap optimizacii zavershyon resheniyem sokhranitj prostuyu realizaciyu.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj | Granicyi i sposob izmereniya                                       |
| ------------------------------ | ------------ | ---------------------------------------------------------------- |
| Analiz i soderzhateljnyiye pravki | ne izmereno  | Ot nachala chteniya do oformleniya rezuljtata; ocenka ne vyidumana.   |
| Adresnyiye regressii             | 10,471 s     | Summa pervyikh chetyiryokh posledovateljnyikh processov obyortki.         |
| Sravnimoye profilirovaniye       | 1,914 s      | Pyatyij process obyortki; vklyuchayet desyatj vlozhennyikh pereimenovanij. |

Granica profilya: ot pervogo RED do zaversheniya adresnyikh proverok i formirovaniya kontroljnoj tochki; poljzovateljskaya peredacha i budusjhaya integraciya ne vklyuchenyi. Stadijnyiye dliteljnosti ne pribavlyayutsya povtorno k tablice processov. Polnyij smoke-check i proyekciya v etoj dochernej podzadache ne zapuskalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                         | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------- | ------------ | --------- |
| [Razrabotchik profilej] RED: istoricheskij profilj pri nastoyasjhem pereimenovanii | 0,45 s       | neuspeshno |
| [Razrabotchik profilej] GREEN: sokhraneniye istoricheskogo profilya                | 0,566 s      | uspeshno   |
| [Razrabotchik profilej] RED: pustoj putj istoricheskogo profilya                 | 2,166 s      | neuspeshno |
| [Razrabotchik profilej] GREEN: granicyi istoricheskogo profilya i zhivyikh ssyilok    | 7,289 s      | uspeshno   |
| [Razrabotchik profilej] Profilj do i posle: odinakovaya Git-fikstura            | 1,914 s      | uspeshno   |
| [Razrabotchik profilej] Sveritj novyiye obyyavleniya s iskhodnoj bazoj              | 0,167 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 12,552 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:deffe15bfddbe2def6d1510248e358b6a5d85220535e889d1eb0fd1918ccc6cd.
Kontekst soderzhimogo: sha256:94d171c0297060c19b7a3bab1c515b94f56758f714d6ed4c92313b0358c70e1b.
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

- RED: fakticheskoye izmeneniye istoricheskogo profilya pri Git-pereimenovanii, zatem GREEN dlya yego sokhrannosti.
- RED: pustoj putj; GREEN: 16 testov sokhrannosti, zhivyikh sosedej, strukturnyikh otkazov, prezhnego otkata i vetochnyikh ogranichenij.
- Profilj vyipolnen na odnom vkhode do i posle; obe versii vosproizveli ozhidayemyiye dlya nikh rezuljtatyi.
- [Sverka obyyavlenij](materialyi/profili/sverka-obyyavlenij.json): novyikh latinskikh sobstvennyikh obyyavlenij net; istoricheskiye 317 i 81 sokhranyayutsya, novyij izmeriteljnyij scenarij imeyet nulevoj ostatok.
- Pered kontroljnyim kommitom primenyayutsya recency, tochnyij predprosmotr i otdeljnyij dopusk `--контрольная-точка`; on nakhoditsya vne zapisyivayemoj granicyi i ne izmeryayet sebya rekursivno.

## Resheniya i ogranicheniya

- Adapter susjhestvuyusjhego istoricheskogo formata ne perepisyivayet proshlyiye materialyi. Polnyij OID proveryayetsya kak format, dostizhimostj Git-obyyekta i istinnostj starogo nablyudeniya ne vyivodyatsya iz strukturyi.
- Obsjhaya zasjhita Zhurnala ili vsekh JSON ne vvodilasj. Dlya drugogo istoricheskogo formata trebuyetsya otdeljnyij proveryayemyij kontrakt.
- Zavisimostj LinguisticKit materializovana lokaljnoj kopiyej bez obsjhikh obyyektov i alternates na tochnom pin 837e2ce107b97ee7b9d3344c9fe99142281fe393; setj i chuzhaya konfiguraciya ne ispoljzovalisj.
- Eto kontroljnaya tochka otkryitogo v4-zhurnala. Prezhneye pokoleniye Proyekcii vzyato iz iskhodnogo kommita 955851da1f8ce2424c2f4d020c74a9cf631056e5, yego vkhod prinyat raneye v ab3a9d24; novyiye kanonicheskiye izmeneniya yesjhyo ne vklyuchenyi v proyekciyu.
- Nezaversheno: nezavisimaya proverka itogovogo kommita, integraciya kornem, prinyatiye obsjhego snimka i realjnoye zaversheniye kartochki 0154. Eti dejstviya ne vyidayutsya za vyipolnennyiye dochernej zadachej.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Razresheniye dochernikh derevjyev](../2026-09-08_17-18-45_MSK_uskoritj-peresborku-proyekcii/zapros.md).
- [Prioritetnoye ispravleniye ostanovki](../2026-09-08_18-50-08_MSK_ustranitj-ostanovku-postoyannoj-zadachi/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 21:46:11 MSK -->
<!-- content-sha256: sha256:d3ca9bef9a375ea1bd056214ba7e8331c86960b02608fb3820f605fb445e7369 -->
<!-- FUM-MD-RECENCY:END -->
