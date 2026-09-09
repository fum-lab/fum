# Otchyot 2026-09-09 09:50:11 MSK - Ustranitj gonku podgotovki kyesha preobrazovatelya

V otdeljnoj vetke integrirovan kyesh podgotovlennogo Swift-produkta i ispravlena gonka inicializacii doveriya. Pervyij podgotovitelj povtorno proveryayet klyuch, yesli drugoj uspel opublikovatj doveriye i kyesh mezhdu chteniyami. Nastoyasjhij kyesh bez klyucha po-prezhnemu vyizyivayet otkaz.

## Polnomochiya i soderzhateljnyiye otvetyi

- Prioritet uskoreniya: prinyata ogranichennaya dochernyaya integraciya koda kyesha i ispravleniye podtverzhdyonnoj gonki; realjnaya polnaya generaciya i obsjhij smoke-check ostayutsya kornyu.
- Paralleljnyiye zadachi: rolj FUM Razrabotchik, sobstvennoye naznachennoye rabocheye derevo i vetka `codex/cache-preparer-race-01a07d3d` ot `e1fa94d0c54a339abab2a6d229163a07b47647ce`. V chuzhiye derevjya, indeksyi, refs i konfiguraciyu zapisj ne vyipolnyayetsya.
- Avtomaticheskaya publikaciya vetok: kontroljnaya tochka posle proverok otpravlyayetsya v sobstvennuyu vetku origin; master i iskhodnyij repozitorij LinguisticKit ne menyayutsya.
- «Osvobodil.»: vozobnovlena raneye razreshyonnaya rabota posle osvobozhdeniya diska. Soglasovannyij obyyom ne rasshiren do samostoyateljnoj obsjhej priyomki.
- Komandyi prochitanyi iz polnogo prefiksa kornevogo JSONL: stroki 7081, 9741, 10270 i 11709; tochnaya granica i khyesh sokhranenyi privatno. Kornevoj UUID sokhranyon; porucheniye kornya ne vyidano za dopolniteljnuyu poljzovateljskuyu repliku.

## Integraciya

Perenesena toljko itogovaya instrumentaljnaya deljta `f74763f5a9e93e97fb7966c71d02e851473dfbf7..4065ae6d314dc36014af856ab724961b00a87b2b` iz devyati zayavlennyikh putej. Kommityi kandidata, yego zapros, zakryitaya istoriya zapuskov i Proyekcii ne nasleduyutsya.

Itog izmenyayet vosemj instrumentaljnyikh fajlov: test sborki uzhe prisutstvoval v baze s dopolniteljnyimi profilirovochnyimi proverkami i sokhranyon. Konfliktyi razreshenyi soderzhateljno: process poluchayet kontroliruyemoye okruzheniye i UTF-8, sborka sokhranyayet prezhniye metki, podgotovka ispoljzuyet proverennyij kyesh. Vse 17 prezhnikh metok sokhranenyi; dobavlenyi tri metki identifikacii instrumentariya, podgotovki doveriya i polucheniya sredyi.

Sravneniye AST susjhestvuyusjhikh funkcij pokazyivayet izmeneniya toljko v chtenii obyichnogo fajla, zapuske processa, sborke i podgotovke izolirovannogo produkta. Funkcii formirovaniya vyikhodov, Finder i tranzakcionnogo vosstanovleniya sokhranenyi. Ispravleniye skanera dobavlyayet uzkuyu kategoriyu dlya binarnogo vlozheniya s NUL vnutri kanonicheskoj papki zaprosa; obyichnyiye tekstyi, beskhoznyiye vlozheniya i blizkiye imena sokhranyayut prezhniye otkazyi.

## TDD i proverki

- RED gonki: dva novyikh scenariya; nastoyasjhaya sirota otklonyalasj korrektno, a zavershyonnyij vtoroj podgotovitelj vyizyival oshibochnyij otkaz pervogo. Vosproizvedeniye determinirovannoye, bez sluchajnyikh zaderzhek.
- GREEN: 18 testov kyesha proshli. Klyuch ne zamenyayetsya ni pri konkurentnoj publikacii, ni pri nastoyasjhem osirotevshem kyeshe.
- Obyyedinyonnyij avtonomnyij nabor proyekcii: 140 testov za 93,049 s; Finder i susjhestvuyusjhiye profilirovochnyiye proverki sokhranenyi.
- RED skanera na iskhodnike e1: kanonicheskoye binarnoye vlozheniye oshibochno poluchalo error.binary-input.
- GREEN skanera: 34 testa za 2,385 s; otdeljno proverenyi polozhiteljnyij kontrakt i proizvoditeljnostj na odnom i tom zhe sinteticheskom dereve.
- [FUM-SBOJ-0036](../../Sboi/FUM-SBOJ-0036-gonka-inicializacii-doveriya-kyesha.md) svyazyivayet nablyudeniye, mekhanizm i kriterii zakryitiya.

## Profilj vremeni vyipolneniya

| Stadiya                            | Dliteljnostj      | Granicyi i sposob izmereniya                                            |
| --------------------------------- | ----------------- | --------------------------------------------------------------------- |
| Avtonomnyiye testyi proyekcii         | 93,049 s          | Vremya unittest; bez realjnoj generacii                                |
| Avtonomnyiye testyi skanera          | 2,385 s           | Vremya unittest                                                        |
| Kholodnaya podgotovka polnogo vkhoda | 22,920 s          | Ot vkhoda v podgotovitelj do gotovoj chastnoj kopii, odin zapusk sborki |
| Tyoplaya podgotovka polnogo vkhoda   | 0,942 s           | Novyij process, tot zhe kyesh, nolj sborok                                |
| Preobrazovaniye polnogo vkhoda      | 35,278 / 35,237 s | Kholodnyij i tyoplyij processyi; syiryiye stdout sovpali                      |
| Obsjhaya priyomka i realjnaya proyekciya | ne vyipolnyalisj    | Vyipolnit korenj posle integracii                                      |
| Analiz i dokumentirovaniye         | ne izmereno       | Nepreryivnyij tajmer ne ustanavlivalsya                                  |

Granica profilya: podgotovka, vyipolneniye produkta i proverki sobstvennoj granicyi izmerenyi na tekusjhem ispolnyayemom iskhodnike. Kompilyaciya vlozhena v polucheniye sredyi; dliteljnosti vlozhennyikh metok ne skladyivayutsya. Odna kholodnaya/tyoplaya para ne yavlyayetsya statisticheskoj ocenkoj polnoj peresborki.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                        | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------- | ------------ | --------- |
| [Podgotovka kyesha] Krasnaya proverka gonki dvukh podgotovitelej                 | 0,209 s      | neuspeshno |
| [Podgotovka kyesha] Zelyonaya proverka gonki i neizmennosti doveriya              | 0,369 s      | uspeshno   |
| [Podgotovka kyesha] Avtonomnyiye regressii obyyedinyonnoj proyekcii                 | 93,213 s     | uspeshno   |
| [Podgotovka kyesha] Kholodnaya podgotovka i polnyij prinyatyij vkhod                 | 58,518 s     | uspeshno   |
| [Podgotovka kyesha] Tyoplaya podgotovka v novom processe i tochnyiye vyikhodnyiye bajtyi | 36,424 s     | uspeshno   |
| [Podgotovka kyesha] Krasnaya proverka binarnogo vlozheniya na iskhodnom skanere    | 0,351 s      | neuspeshno |
| [Podgotovka kyesha] Avtonomnyiye proverki skanera publikacionnyikh putej           | 2,495 s      | uspeshno   |
| [Podgotovka kyesha] Profilj i zelyonyij kontrakt skanera binarnyikh vlozhenij       | 2,134 s      | uspeshno   |
| [Podgotovka kyesha] Publichnyij korpus: kholodnaya podgotovka v otdeljnom processe | 21,939 s     | uspeshno   |
| [Podgotovka kyesha] Publichnyij korpus: tyoplyij process i pobajtnoye ravenstvo     | 1,634 s      | uspeshno   |
| [Podgotovka kyesha] Publikacionnaya chistota kyesha i publichnogo korpusa           | 17,139 s     | uspeshno   |
| [Podgotovka kyesha] Struktura Zhurnala integracii kyesha                          | 12,125 s     | uspeshno   |
| [Podgotovka kyesha] Tochnyij indeks kontroljnoj tochki kyesha                       | 0,024 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 246,574 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:4fc79b131e236c4d52e174c096e9b2916444fdc2bcfd5348af03e6b7835ed141.
Kontekst soderzhimogo: sha256:7e7658f084515d7af5139a95cfa5c36d1b135d42134036a63bdbc858e87292d7.
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

## Izmereniya i resheniye ob optimizacii

[Polnaya para](materialyi/profilj-polnogo-vkhoda.json) obrabotala 1321 stroku: 14 328 439 vkhodnyikh i 10 018 076 vyikhodnyikh bajtov. Vkhod imeyet SHA-256 `51eb7e87d7f896f00d3a1b75cfe5f35793457c7ad3a013d09de7e6639d792cbc`, etalon i oba vyikhoda — `4b075f54cb501033b605c064c824d27498a0f494400e8057600dae2aec989cd3`. Polnyij vkhod soderzhit istoricheskiye mashinnyiye puti, poetomu v publichnuyu vetku ne perenositsya; yego khyesh oboznachayet privatnyij artefakt. Proverka pobajtnaya, ne toljko po khyeshu.

Dlya publichnogo vosproizvedeniya sokhranenyi [sinteticheskij vkhod](materialyi/publichnyij-vkhod.json), [tochnyij vyikhod](materialyi/publichnyij-vyikhod.json) i [otdeljnaya para podgotovki](materialyi/profilj-publichnogo-vkhoda.json). Dva otdeljnyikh processa ispoljzuyut novyij chastnyij kyesh izmereniya; susjhestvuyusjhij rabochij kyesh ne udalyayetsya. Vkhod soderzhit 12 strok i 570 bajt; vyikhod — 389 bajt. Kholodnaya podgotovka 21,221 s, tyoplaya 0,934 s; ispolneniye 0,503 i 0,498 s. Sborok 1 i 0, vyikhodyi pobajtno ravnyi; SHA-256 vyikhoda `3defd97644dff3eac8c37750fc6e990a0fb7c20936d2c98bbf366ea64d1b1739`.

[Profilj skanera](materialyi/profilj-skanera.json) soderzhit semj chereduyusjhikhsya izmerenij kazhdogo varianta na 200 tekstovyikh fajlakh i tochnom binarnom vlozhenii. Mediana iskhodnogo skanera 138,781 ms, izmenyonnogo 139,015 ms. Dopolniteljnyij uchyot tochnyikh zaprosov ne trebuyet daljnejshej optimizacii; raznica sostavlyayet okolo 0,235 ms v etom izmerenii.

Prinyato kyeshirovatj toljko proverennyij ispolnyayemyij produkt, sokhraniv povtornyij vyivod strok, vyikhodnyikh bajtov i manifesta. Vyiigryish podgotovki podtverzhdyon; vremya samoj transliteracii susjhestvenno ne izmenilosj. Povtornoye chteniye doveriya ustranyayet oshibochnyij otkaz bez novoj blokirovki i ne oslablyayet proverku klyucha, rezhima, podpisi ili bajtov produkta. Dopolniteljnoye keshirovaniye soderzhimogo libo uskoreniye vsej peresborki etim rezuljtatom ne zayavlyayutsya.

## Priyomka i prodolzheniye

Otkryitaya v4-istoriya sootvetstvuyet kontroljnoj tochke dochernej rabotyi. Polnaya integraciya i priyomka FUM vyipolnyayutsya kornem. [Ogranichennyij plan](materialyi/prodolzheniye.json) ne zamenyayet perechenj rabot postoyannoj kornevoj zadachi.

## Istochniki

- [Iskhodnyij zapros](zapros.md).
- [Kontrakt kyesha i profilirovochnyikh metok](../../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md).
- [Granica binarnogo istochnika](../../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 10:04:05 MSK -->
<!-- content-sha256: sha256:8fd9b809ced52a36f3fceb2c9e22816f9f32333f26fbeafdb7ae781066da411b -->
<!-- FUM-MD-RECENCY:END -->
