# Otchyot 2026-09-09 14:42:57 MSK - Podtverditj materializaciyu vkhoda

Ogranichennyij segment materializacii zavershyon: zakreplyonnyiye raw-fajlyi sozdayutsya i nezavisimo proveryayutsya bez ispolneniya. Vesj adresnyij nabor instrumenta — 50 uspeshnyikh testov, iz nikh 22 dobavlenyi etim segmentom. Pervaya komanda koordinatora realizovana; utochneniye o sokhranenii v3 ispolneno novoj chistoj v4-istoriyej. Rabocheye derevo i vetka ostayutsya prezhnimi, iskhodnyij commit segmenta — 48c0a98d6682f8d3ec2492addcb07f28bb679bf7. Integraciyu i obsjhij smoke vyipolnyayet koordinator.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Vesj adresnyij nabor | 81,793 s | Vneshnij process v4; unittest vnutri soobsjhayet 81,691 s |
| 2, povtornyiye | 2.060 s | 21 fajlov; 17117 bajt; 90 chtenij Git; Python peak 1333440 bajt |
| 2, unikaljnyiye | 2.090 s | 21 fajlov; 17117 bajt; 94 chtenij Git; Python peak 1346874 bajt |
| 100, povtornyiye | 2.281 s | 119 fajlov; 429305 bajt; 90 chtenij Git; Python peak 1832834 bajt |
| 100, unikaljnyiye | 8.061 s | 119 fajlov; 429305 bajt; 486 chtenij Git; Python peak 3540451 bajt |
| Obsjhij smoke | Ne zapuskalsya | Yavno isklyuchyon zadaniyem; ne zamenyayetsya adresnyimi testami |

Granica profilya: podgotovka kazhdogo vremennogo repozitoriya izmeryayetsya otdeljno; materializaciya vklyuchayet povtornuyu proverku vkhoda, syiryiye chteniya Git, sozdaniye, nezavisimuyu sverku i fsync. Zatem otdeljno izmeryayetsya povtornyij read-only-proveryayusjhij. Vlozhennyiye intervalyi i vneshneye vremya processa ne skladyivayutsya. Python peak izmeren tracemalloc; pamyatj dochernego Git ne izmeryalasj. Vremya finaljnogo commit/push i peredachi vne etoj granicyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                              | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj materializacii] Vesj adresnyij nabor snimkov i materializacii               | 81,793 s     | uspeshno   |
| [Korenj materializacii] Povtor profilya s tochnyim sravneniyem vkhodov i manifestov     | 27,876 s     | uspeshno   |
| [Korenj materializacii] Neizmennostj zakryityikh zapisej pervonachaljnogo etapa v3     | 0,086 s      | uspeshno   |
| [Korenj materializacii] Tochnyiye bajtyi instrumenta, istoricheskoye telo i granica diff | 0,102 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 109,857 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:cc3dd3bcea32069d6788ae1d52e9ed11667326431361594f93cba6e2c5cc77db.
Kontekst soderzhimogo: sha256:aa99eaa9da525c1271a607369f99a4f24051dcdca6c768b4bd481ae8915ebf31.
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

[Predyidusjhij otchyot](../2026-09-09_14-12-34_MSK_materializovatj-zakreplyonnyij-vkhod/otchyot.md) sokhranyayet iskhodnyij RED otsutstviya modulya i realjnyiye povedencheskiye RED/GREEN: podmena imenovannyikh inode, izmeneniya katalogov pri chtenii, chuzhoj UUID kvitancii i registrovyij alias reyestra. Eti zapisi fakticheski v3, poskoljku korenj propustil pervyij flag nachala raundov. Oni zakryityi i otdeljno proverenyi, ne perepisanyi i ne vyidanyi za v4. Koordinator yavno razreshil otdeljnuyu zavershayusjhuyu papku; pryamyiye podtverzhdeniya zdesj imeyut v4. Eto ne migraciya starogo prefiksa i ne izmeneniye obyortki.

Vse 50 testov vosproizveli kanonicheskij vkhod i prezhniye 28 granic, materializaciyu A pri zhivyikh B→C, otsutstviye rezervnogo chteniya zhivyikh fajlov, podderzhannyij gitlink, neprozrachnyij arkhiv, sokhraneniye rezhimov i pustyikh derevjyev, otdeljnyiye inode povtornyikh blob, zapret lishnikh/propusjhennyikh/izmenyonnyikh fajlov, symlink i podmen. Proverenyi short/zero/ENOSPC, vtoroj blok boljshogo fajla, zapisj kvitancii, otkaz kazhdogo fsync i ostanovka dochernego processa na chetyiryokh granicakh. Vneshniye kontroljnyiye fajlyi ostayutsya celyimi. Nezavisimaya povtornaya proverka otvergayet poteryu istochnika posle zapolneniya kyesha.

Povtor profilya sravnil SHA-256 kanonicheskogo vkhoda i polnogo manifesta, chislo fajlov i obyyom: vse chetyire paryi sovpali. Iskhodnyij zamer 100 povtornyikh/unikaljnyikh putej — 1,730/6,780 s; podtverzhdayusjhij — 2,281/8,061 s. Mezhdu nimi optimizaciya ne vvodilasj; razbros vremeni ne obyyavlyayetsya uskoreniyem. Svezhaya nezavisimaya sverka sokhranena. Read-only-recenzent povtorno proveril realizaciyu i dokumentaciyu, blokiruyusjhikh zamechanij ne ostalosj.

## Resheniya i ogranicheniya

Realizaciya i obe komandyi opisanyi v [kontrakte materializacii](../../Instrumentyi/fum-snimki-indeksa/materializaciya.md). Toljko novyij katalog pod roditelem tekusjhego UID s rezhimom 0700; kvitanciya nakhoditsya ryadom s nim. Istochniki, reyestr i realjnyiye Git-khranilisjha isklyuchenyi, proveryayutsya aliases. Povtor — novaya proverka susjhestvuyusjhikh bajtov, a chastichnyij rezuljtat ne ochisjhayetsya. Kvitanciya svyazana s vkhodom, tree, putyom, inode i polnyim manifestom; determinirovannyij UUID ne yavlyayetsya podpisjyu ili polnomochiyem.

Eto materializaciya bez ispolneniya. Ocheredj dostavki, pozdnyaya otmena, ispolnyayemyiye planyi, deljta vyikhoda i polnaya priyomochnaya kvitanciya0155 otsutstvuyut; flagi dopuska vsegda false. Git alternates i vlozhennyiye gitlink ne podderzhanyi. Operacii cherez dirfd i povtornyiye nablyudeniya ne obesjhayut polnoj atomarnosti protiv vrazhdebnogo processa togo zhe UID. Posle sboya poslednej sinkhronizacii vosstanovleniye pending yavlyayetsya best effort; uspeshnoye zaversheniye processa ne ugadyivayetsya po odnomu nalichiyu fajla kvitancii.

Obe novyiye papki i razreshyonnaya navigaciya budut zafiksirovanyi odnim razrabotcheskim kommitom. Staryij closed-blok i syiryiye v3-zapisi sokhranyayutsya; tekusjhij v4-blok ostayotsya otkryitoj kontroljnoj tochkoj dlya integracii, bez pritvornogo polnogo dopuska. Obsjhiye pravila, kartochki, reyestryi, obyortka, Proyekcii i poljzovateljskoye sostoyaniye Obsidian ne menyalisj. Nastoyasjhij indeks FUM novyim protokolom ne prinimalsya. Zavershayusjhiye commit/push i read-only-sverka rezuljtata vyipolnyayutsya posle etoj zapisi; tochnyij OID peredayotsya koordinatoru.

Polnaya proverka svyaznosti kontroljnoj tochki posle aktualizacii predprosmotra vyiyavila toljko 1 unasledovannyij razryiv navigacii zaprosa 11:39:26 i 282 ssyilki na otsutstvuyusjheye lokaljnoye `.obsidian/graph.json`. Eti oblasti ne menyayutsya po zadaniyu; polnyij otkaz ne vyidan za uspekh. Sobstvennaya granica svyaznosti, recency, proiskhozhdeniya, tochnogo diff i neizmennosti Python-bajtov proverena otdeljno. Sverka svyaznosti vyipolnena read-only vne mashinnoj tablicyi po isklyucheniyu pravila000188 dlya dopuska kontroljnoj tochki. [Mashinnaya granica](materialyi/granica-svyaznosti.json).

## Istochniki

- [Doslovnyiye komandyi](zapros.md).
- [Predmetnyiye RED/GREEN](../2026-09-09_14-12-34_MSK_materializovatj-zakreplyonnyij-vkhod/otchyot.md).
- [Pervyij profilj](../2026-09-09_14-12-34_MSK_materializovatj-zakreplyonnyij-vkhod/materialyi/profilj-materializacii.json).
- [Podtverzhdayusjhij profilj](materialyi/profilj-podtverzhdeniya.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 14:53:10 MSK -->
<!-- content-sha256: sha256:cd76a3b06be629989b2741d534be62f45022a7c99f9e48f4e2afc9723b7a55b0 -->
<!-- FUM-MD-RECENCY:END -->
