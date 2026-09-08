# FUM-MAP-GIT-01: Git-infrastruktura evolyucionnyikh cepochek

Eta kartochka fiksiruyet Git-infrastrukturu kak pervyij konkretnyij inzhenernyij nositelj [evolyucionnoj cepochki FUM](../../Glossarij/evolyucionnaya-cepochka-FUM.md). Ona pokazyivayet, kak uzhe ispoljzuyemyij repozitorij mozhet ne toljko khranitj dokumentaciyu, no i vyipolnyatj rolj nablyudayemogo kontura porozhdeniya variantov, proverki, otbora, nasledovaniya i vozvrata kredita.

## Kartochka

- Identifikator: `FUM-MAP-GIT-01`.
- Obyyekt sopostavleniya: Git-infrastruktura evolyucionnyikh cepochek.
- Sloj: inzhenernyij nositelj otbora.
- Nablyudatelj: chelovek, agent rabochej sessii i budusjhij [FUM-uzel](../../Glossarij/FUM-uzel.md), chitayusjhij istoriyu repozitoriya kak trassu proiskhozhdeniya.
- Sootvetstviye obsjhej skheme: [vetka rabotyi](../../Glossarij/vetka-rabotyi.md) vyistupayet variantom, commit ili artefakt - [peredavayemyim rezuljtatom FUM](../../Glossarij/peredavayemyij-rezuljtat-FUM.md), proverka - vneshnim otborom, Git DAG i [reyestr proiskhozhdeniya FUM](../../Glossarij/reyestr-proiskhozhdeniya-FUM.md) - rodoslovnoj i osnovaniyem vozvrata kredita.
- Sokhranyayemyiye invariantyi: rezuljtat imeyet proiskhozhdeniye, mozhet byitj proveren, mozhet byitj unasledovan sleduyusjhej rabotoj i mozhet byitj svyazan s istochnikom trebovaniya.
- Poteri nablyudayemosti: Git ne khranit vesj vnutrennij khod rassuzhdeniya, ne garantiruyet polnotu poljzovateljskogo konteksta i ne zamenyayet zhurnal, iskhodnyij zapros ili publikacionnyij audit.
- Perekhod k istochniku: osnovnaya specifikaciya raskryita v dokumente [Git-infrastruktura evolyucionnyikh cepochek FUM](../20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md), a trebovaniye zakrepleno v iskhodnom zaprose 2026-07-02 10:51:13 MSK.
- Granicyi analogii: sopostavleniye primenimo k vosproizvodimyim rabochim izmeneniyam s yavnyim istochnikom, proverkoj i kommitom; ono oslabevayet dlya nezafiksirovannyikh lokaljnyikh dejstvij, vneshnikh servisov bez trassyi i rezuljtatov, kotoryiye neljzya proveritj.
- Proverka: rabochaya sessiya dolzhna imetj fajl iskhodnogo zaprosa, zhurnal, obnovlyonnyiye proizvodnyiye materialyi, lokaljnyiye proverki i Git-kommit.
- Status uverennosti: zakreplyonnaya kartochka tekusjhej praktiki.

## Sliyaniye, specializaciya i otbor

Status etogo dopolneniya — gipoteza sopostavleniya; polnyij obsjhij algoritm yesjhyo ne ustanovlen. Poljzovatelj opisyivayet sliyaniye s posleduyusjhim vetvleniyem kak polovoye razmnozheniye, [gender agenta](../../Glossarij/gender-FUM-agenta.md) — kak yego specializaciyu, a testyi — kak khisjhnikov.

Posledovateljnostj modeli: sovmestimyiye nasleduyemyiye osnovaniya → obyyedineniye → posleduyusjheye vetvleniye i naznacheniye roli → ispolneniye v [srede](../../Glossarij/okruzhayusjhaya-sreda-FUM.md) → otbor proverkami. Merge-kommit sokhranyayet proiskhozhdeniye ot neskoljkikh roditelej; fast-forward otdeljnogo sobyitiya obyyedineniya v DAG ne sozdayot. Chislo roditelej kommita i mnozhestvo vozmozhnyikh rolej agenta opisyivayut raznyiye svojstva.

«Genom» oboznachayet nasleduyemoye osnovaniye v etoj gipoteze. Yego sostav i kriterij obsjhej sovmestimosti trebuyut opredeleniya; otsutstviye tekstovogo konflikta Git samo po sebe ne dokazyivayet sovmestimostj ispolnyayemogo rezuljtata. Zapusjhennyij agent prokhodit zadannyiye proverki v nablyudyonnyikh usloviyakh; imenno eti usloviya i rezuljtatyi sokhranyayutsya v zhurnale.

«Asteroid» rasshiryayet otbor do rezkoj smenyi sredyi s dliteljnyimi posledstviyami. Inzhenernoye sopostavleniye — proverka povedeniya pri prodolzhiteljnoj nekhvatke resursov, nedostupnosti zavisimostej i posleduyusjhem vosstanovlenii. Vneshneye proiskhozhdeniye sobyitiya ne isklyuchayet otbora po ustojchivosti k novyim usloviyam. Iskhod ispyitaniya, nablyudyonnyiye usloviya i ustanovlennaya prichina otkaza khranyatsya razdeljno; neustanovlennaya prichina ostayotsya neizvestnoj.

Sostav nasleduyemogo osnovaniya, sootvetstviye specializacii kletki naznacheniyu roli, invariantyi obsjhego algoritma i kriterii yego oproverzheniya dobavlenyi v [otkryityij vopros](../../Voprosyi/2026-06-26_12-19-03_MSK_abstrakciya-urovnej-nablyudayemoj-vselennoj-FUM.md). Prokhozhdeniye konechnogo nabora testov podtverzhdayet etot nabor v dannyikh usloviyakh; obsjheye sootvetstviye biologicheskoj i inzhenernoj modelej iz nego ne sleduyet.

## Istochniki trebovanij

- [Utochneniya o sliyanii, roli, sovmestimosti i sredovom otbore, soobsjheniya 26–31](../../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).

- [iskhodnyij zapros 2026-07-02 10:51:13 MSK](../../Zhurnal/2026-07-02_10-51-13_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:33:38 MSK](../../Zhurnal/2026-07-02_11-33-38_MSK/zapros.md)

## Opornyiye dokumentyi

- [Git-infrastruktura evolyucionnyikh cepochek FUM](../20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Evolyuciya i myishleniye](../03-evolyuciya-i-myishleniye.md)
- [Arkhitektura FUM](../22-arkhitektura-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 11:25:54 MSK -->
<!-- content-sha256: sha256:4944728d533a4396a8ef86b9d16035ed98a7f761624accfe9c7a81e543510a41 -->
<!-- FUM-MD-RECENCY:END -->
