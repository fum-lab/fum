# Otchyot 2026-09-09 13:23:25 MSK - Podgotovitj privatnyij komplekt zaversheniya

Pervyij ogranichennyij rezuljtat etapa: dochernij guard zapuskayetsya tem zhe nastoyasjhim Python s `-I -S -B`. RED vosproizvyol ispolneniye `.pth` dochernim processom pri izolirovannom roditele; posle ispravleniya 28 testov i shestj mezhprocessnyikh iskhodov prokhodyat. Podgotovka privatnogo komplekta yesjhyo ne realizovana i ostayotsya dostupnoj rabotoj v [plane](materialyi/prodolzheniye.json).

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| ------ | ------------ | ------------------------- |
| Proyektirovaniye i nezavisimoye chteniye | ne izmereno | Bez ocenki zadnim chislom |
| Adresnyiye proverki | po zapuskam | Monotonnoye vremya processov nizhe |
| Profilj adaptera | po profilyu | 25 zamerov v [syirom profile](materialyi/profilj-izolyacii.json) |

Granica profilya: perechislennyiye adresnyiye processyi; chteniye, ozhidaniya i peredacha vne izmerennoj granicyi. Perekryivayusjhiyesya processyi ne summiruyutsya kak vremya vsego etapa. Obsjhij smoke i proyekciyu vyipolnyayet koordinator.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                       | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------- | ------------ | --------- |
| [Komplekt] Krasnaya proverka izolyacii dochernego Python       | 0,682 s      | neuspeshno |
| [Komplekt] Zelyonaya izolyaciya i regressii adaptera            | 7,532 s      | uspeshno   |
| [Komplekt] Shestj realjnyikh iskhodov s izolirovannyim backend   | 5,452 s      | uspeshno   |
| [Komplekt] Profilj adaptera posle izolyacii dochernego Python | 5,029 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 18,695 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:7c2b5239efa017e69a78d95dc993f204f25d340133cfb46016f4ec7403493d9d.
Kontekst soderzhimogo: sha256:10015954ced874c6f83f809a081018782134e0bca88b589db7581a372c710f95.
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

- RED izolirovannogo venv zavershilsya ozhidayemyim otkazom: dochernij guard ostavil marker `.pth`. Polozhiteljnyij kontrolj snachala dokazal rabotosposobnostj fiksturyi. Sistemnyiye katalogi ne izmenyalisj.
- GREEN: 28 testov, vklyuchaya prezhniye granicyi stdin/stdout/exit i ochistku gruppyi pri signale. Shestj mezhprocessnyikh iskhodov s guard commit `7a5f77c0e00b291338c737d227119975857155af` proshli; iskhodniki guard ostalisj chistyimi. SHA-256 adaptera: `3a2c36ce7fb34c7bfbaff88210c03e0ae40b7bc0e5cc4e6af60091f6c3fe034e`.
- Iskhodnyij obsjhij commit komplekta: `1e5b355bd142a19a5d9b7e9032ffbda31d360f36`, tree `073172b164a514e4addc84154e874e62961158c6`; on yesjhyo soderzhit staryij zapusk backend. Dlya novogo adaptera trebuyetsya sleduyusjhij obsjhij commit s chetyirjmya fajlami.
- Nezavisimoye chteniye podtverdilo zagruzku oboikh sosednikh modulej cherez `spec_from_file_location`; izolyaciya poiska Python ne trebuyet izmeneniya guard.
- Oshibochnyij jq-filjtr lokaljnogo profilya ispravlen na obrasjheniye k kirillicheskim klyucham v kavyichkakh. Iskhodnyiye izmereniya ne menyalisj. Pri sozdanii plana ispravlena oshibka sklejki lokaljnogo puti; oshibochnyij novyij fajl ubran, istochnik ne poteryan.

## Resheniya i ogranicheniya

- Koordinator yavno rasshiril iskhodnuyu granicu toljko na flagi zapuska backend adapterom. Dopolniteljnyij launcher i podmena `sys.executable` isklyuchenyi; v komplekte ostayutsya chetyire project blob i manifest.
- Podgotovka dolzhna vyidavatj lishj proveryayemogo kandidata hook; ustanovka, Trust, sostoyaniye realjnogo runtime i obsjhiye pravila ne izmenyayutsya. Privatnyiye celi pod Git-predkami zapresjhenyi. Zasjhita ot konkurentnoj podmenyi tem zhe UID ne zayavlyayetsya.
- Profilj adaptera posle izolyacii: obyichnyij vyizov 101,651 ms, predeljnyij vvod 100,048 ms, rezuljtat 15 MiB 107,466 ms, chuzhaya zadacha 58,169 ms, tajm-aut 596,523 ms. Kriterii 1 s obyichnogo vyizova i 128 MiB sokhranyayutsya; otdeljnaya optimizaciya ne trebuyetsya. Podgotovka i goryachij bootstrap poluchat otdeljnyiye zameryi.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 13:36:50 MSK -->
<!-- content-sha256: sha256:8a14cd269b6652d0b2f103a8a0f12eafddcbdfee172b87c2dfd374bf9c89b517 -->
<!-- FUM-MD-RECENCY:END -->
