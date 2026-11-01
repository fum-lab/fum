# Otchyot 2026-09-19 04:29:36 MSK - Izmeritj sostav proverki svyaznosti

Prodolzhayetsya razreshyonnaya rabota FUMA; D22 ostayotsya na pauze. Predyidusjhaya kontroljnaya tochka 55092f0346752779d252a780c1ca37371b46e06f opublikovana v fuma i podtverzhdena udalyonnyim OID. Yeyo realjnyij profilj: chteniye pervichnyikh komand 0,709258 s, svyaznostj 39,550430 s. Eto nablyudeniya otdeljnyikh stadij, ne raskhod tokenov i ne parnyij zamer polnogo kommita.

Celj etapa — izmeritj sostav proverki svyaznosti pered vyiborom sleduyusjhej optimizacii. Povtornoye chteniye Markdown, razresheniye putej i otdeljnaya proverka svezhesti poka toljko gipotezyi. Pri profilirovanii sokhranyayetsya obyichnyij main, proverka Git i yego kod vozvrata; cProfile cherez CLI ne ispoljzuyetsya iz-za podavleniya SystemExit. Vremya profilirovannogo zapuska vklyuchayet nakladnyiye raskhodyi izmeritelya; vremya ozhidaniya dochernego processa ne raskryivayet yego vnutrenniye funkcii.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Svyaznostj v predyidusjhem kommite | 39,550430 s | Monotonnyij tajmer ispolnitelya J28 |
| Svyaznostj do / posle | 112,064 / 58,707 s | cProfile shtatnogo main, raznyiye snimki Zhurnala |

Granica profilya: otdeljnaya proverka svyaznosti; ni vsya rabochaya sessiya, ni raskhod nedeljnogo limita yej ne pripisyivayutsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                        | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------ | ------------ | --------- |
| [korenj] Profilj shtatnoj svyaznosti J29                       | 112,144 s    | neuspeshno |
| [korenj] RED stoimosti inventarya J29                         | 0,509 s      | neuspeshno |
| [korenj] RED linejnogo obkhoda posle ispravleniya zagruzki J29 | 0,645 s      | neuspeshno |
| [korenj] GREEN linejnogo obkhoda J29                          | 0,733 s      | uspeshno   |
| [korenj] Granica ignoriruyemyikh i otslezhivayemyikh listjyev J29    | 0,898 s      | uspeshno   |
| [korenj] Sovmestimostj strukturyi papok J29                   | 8,077 s      | uspeshno   |
| [korenj] Tochnoye imya otkaza i stoimostj inventarya J29         | 0,777 s      | uspeshno   |
| [korenj] Profilj svyaznosti posle linejnogo obkhoda J29        | 58,786 s     | uspeshno   |
| [korenj] Polya Zhurnala J29                                    | 0,085 s      | uspeshno   |
| [korenj] Publikacionnaya chistota J29                          | 33,662 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 216,316 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:e868bb3efbd969800f4d8c1f6a4591e349bdbe02e0ac14dfed82ae770feb17e8.
Kontekst soderzhimogo: sha256:1851c6c64d392dd20e023499ced54da9d31447b51c8d898804d2156894e3ecdb.
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

Pervyij profilj main zavershilsya kodom 1: v upravlyayemom bloke otchyota yesjhyo ostavalsya shablonnyij marker. Profilj sokhranyon kak diagnostika, ne kak uspeshnyij dopusk; predprosmotr shtatno zamenil blok posle zapisi rezuljtata. cProfile: 112,064 s po monotonnomu tajmeru, 450 174 829 vyizovov; struktura papok 85,515 s, ssyilki Markdown 23,406 s. Vlozhennyiye vremena ne summiruyutsya. [Mashinnyij profilj](materialyi/profilj-svyaznosti.json).

Vyiyavlen povtornyij poisk kazhdoj papki vo vsekh predkakh inventarya. Teperj mnozhestvo tochnyikh predkov stroitsya odin raz iz togo zhe inventarya. Proverki simvolicheskikh ssyilok, registra, publikacionnyikh isklyuchenij, shablonov i posleduyusjhiye svezhiye inventarizacii sokhranenyi.

Pervyij testovyij zapusk oshibsya zagruzkoj sosednego modulya (4 oshibki za 0,403 s) i ne schitayetsya RED algoritma. Posle ispravleniya zagruzki RED podtverdil 3382 obrasjheniya vmesto byudzheta 252: 4 testa, odin otkaz, 0,549 s. GREEN proshyol; rasshirennyiye 5 testov proveryayut takzhe ignoriruyemyij list i yego prinuditeljnoye dobavleniye v indeks. Prezhniye 18 testov proshli za 7,984 s. Revjyu ne nashlo blokera koda; po zamechaniyu test pokhozhikh prefiksov teperj proveryayet tochnoye imya otklonyonnoj papki.

Podgotovka kommita pervonachaljno otkazala pri dopisyivanii JSONL; otdeljnaya sverka ustojchivogo snimka podtverdila polnotu, otsutstviye propuskov i pozdnego khvosta. Novaya podgotovka proshla. Posle rasshireniya sostava na podtverzhdyonnuyu optimizaciyu potrebuyetsya novaya tochnaya podgotovka.

## Resheniya i ogranicheniya

Iskhodnyij kommit etapa: 55092f0346752779d252a780c1ca37371b46e06f; ref refs/heads/fuma; kornevoj UUID ukazan v zaprose. Zapisj vedyot toljko korenj v sobstvennom linked worktree. Izmeneniye ogranicheno vyichisleniyem mnozhestva predkov; ostaljnyiye stadii dopuska sokhranenyi.

Polnaya priyomka novyikh izmenenij yesjhyo ne vyipolnena. Posledneye prinyatoye pokoleniye proyekcii prinadlezhit J27, kommitu 23711de4ee376921dfb1da2c4e9a0f0af1cab041; kanon J28 i tekusjhego etapa uzhe noveye. Eto otstavaniye ne obyyavlyayetsya uspeshnoj finaljnoj priyomkoj.

## Istochniki

- [iskhodnyij zapros](zapros.md).
- [predyidusjhaya kontroljnaya tochka](../2026-09-19_04-14-40_MSK_uskoritj-podgotovku-kommita-proveryayemyim-kyeshem/otchyot.md).

Povtornyij profilj shtatnogo main proshyol s kodom 0 za 58,707 s. Eto nablyudayemoye sokrasjheniye otnositeljno 112,064 s, no ne strogaya parnaya ocenka: mezhdu zapuskami izmenilisj tekusjhij Zhurnal, testyi i dokumentaciya; pervyij zapusk zavershilsya otkazom. Nakladnyiye raskhodyi cProfile vklyuchenyi v obe dliteljnosti. Realjnyij neprofilirovannyij dopusk budet takzhe izmeren ispolnitelem kommita.

Pered zaversheniyem etapa ostayutsya aktualjnyiye proverki polej Zhurnala, publikacionnoj chistotyi, tochnogo indeksa i kontroljnoj tochki. Shirokij kontur bez novogo osnovaniya ne povtoryayetsya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 04:49:19 MSK -->
<!-- content-sha256: sha256:f18b0fbb07e1dd3d180f9b1bfcfe1a40b2a4890cddca96d8a74fe28fcae26276 -->
<!-- FUM-MD-RECENCY:END -->
