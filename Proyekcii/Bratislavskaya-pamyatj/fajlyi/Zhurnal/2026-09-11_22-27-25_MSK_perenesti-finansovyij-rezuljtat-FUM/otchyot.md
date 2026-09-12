# Otchyot 2026-09-11 22:27:25 MSK - Perenesti finansovyij rezuljtat FUM

Etap perenosit proverennyij finansovyij rezuljtat v sobstvennuyu vetku priyoma. Istochnik — kommit `6c9babdd3663ff0112283b89a361068727825da6`; celevaya baza — `601d7a84719d86c9f5535f4d80bf543afc6bb6e2`. Ustanovlenyi reyestr, iskhodniki, arkhivyi i neobkhodimyiye vkhodyi; adresnyiye proverki sobstvennogo dereva proshli. Eto kontroljnaya tochka perenosa, polnaya priyomka obsjhej vetki yesjhyo predstoit.

## Profilj vremeni vyipolneniya

| Stadiya                | Dliteljnostj  | Granicyi i sposob izmereniya                                                |
| --------------------- | ------------- | ------------------------------------------------------------------------- |
| Pervyij start          | 0,080970916 s | Otkaz do zapisi: v --label oshibochno peredano vremya vmesto suffiksa        |
| Shtatnyij start         | 0,482779917 s | Posle chteniya kontrakta peredan suffiks, kod 0                             |
| Soderzhateljnaya rabota | ne izmereno   | Chteniye iskhodnogo kommita, predvariteljnogo manifesta i adresnaya adaptaciya |
| Polnyij smoke-check    | ne zapuskalsya | Vyichisliteljnoye okno predostavleno drugoj gotovoj zadache                   |

Granica profilya: otdeljnyiye nablyudyonnyiye processyi nachala etapa; nepreryivnaya rabota i ozhidaniye tyazhyologo okna ne izmeryalisj, intervalyi ne skladyivayutsya s vlozhennyimi proverkami.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                            | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------ | ------------ | --------- |
| [korenj-finansovyij-perenos] RED puti vkhoda profilya ochistki posle perenosa                        | 0,086 s      | neuspeshno |
| [korenj-finansovyij-perenos] GREEN i profilj ochistki s dostavlennyim vkhodom                        | 2,378 s      | uspeshno   |
| [korenj-finansovyij-perenos] Testyi reyestra podderzhki posle perenosa                               | 1,215 s      | uspeshno   |
| [korenj-finansovyij-perenos] Regressii arkhivatora posle perenosa                                  | 0,525 s      | uspeshno   |
| [korenj-finansovyij-perenos] Vosproizvedeniye sokhranyonnogo reyestra podderzhki                       | 0,127 s      | uspeshno   |
| [korenj-finansovyij-perenos] Profilj reyestra podderzhki posle perenosa                             | 0,24 s       | uspeshno   |
| [korenj-finansovyij-perenos] Sveritj prinimayusjhij reyestr planirovaniya                              | 0,421 s      | uspeshno   |
| [korenj-finansovyij-perenos] Publikacionnaya chistota finansovogo perenosa                          | 24,341 s     | uspeshno   |
| [korenj-finansovyij-perenos] Tochnyij diff indeksa finansovogo perenosa                             | 0,079 s      | neuspeshno |
| [korenj-finansovyij-perenos] Probeljnaya proverka sobstvennogo sloya s sokhraneniyem tochnyikh syiryikh URL | 0,035 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 29,447 s.

Priyomochnyiye raundyi: ne gotov.
Kontekst Git-snimka: sha256:4173fe768d34dc68559452d640867f79e1156ec03f8fb737d1935a8d84b2b8c1.
Kontekst soderzhimogo: sha256:a73daf74bfacd2ef25967256a5e2ef2415cc7a298ab673127fff83612ce17da3.
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

## Proverki i proiskhozhdeniye

Predvariteljno sverenyi realjnyiye Git-obyyektyi i iskhodnoye sostoyaniye 393 fajlov: 390 novyikh i tri obnovleniya. Eto 10 predmetnyikh fajlov, chetyire fajla arkhivatora, 377 URL-fajlov i dva neobkhodimyikh JSON. Obsjhiye indeksyi, pravila i chuzhoj Zhurnal ne perezapisyivayutsya. Tochnyiye khyeshi i razreshyonnyiye adaptacii sokhranyayutsya v materialakh. Nezavisimyij prosmotr iskhodnikov vyipolnyayetsya paralleljno.

Istoricheskij rezuljtat istochnika podtverzhdyon zakryityim otchyotom v2: polnyij zapusk `e39257a3-2ce9-464e-b5a7-28b82860dcc1`, 24 shaga, kod 0, 1108,017330917 s. On otnositsya k iskhodnomu snimku i ne sluzhit polnoj priyomkoj etoj integracii. Vse ranniye otkazyi istochnika ostayutsya istoricheskimi svideteljstvami.

## Resheniya i ogranicheniya

V reyestre 16 organizacij i 24 varianta; vse variantyi sokhranenyi s dostupnaya_programma=false. Polozhiteljnyiye vyivodyi otnosyatsya k podgotovke vzaimodejstviya, yuridicheskiye i geograficheskiye neizvestnyiye ne snimayutsya. Pisjma, zayavki, kontaktyi s organizaciyami i platezhi ne vyipolnyayutsya. Otvet 198 izvlechyon tochno iz polya answer podtverzhdyonnogo poljzovateljskogo otveta; sluzhebnaya obolochka i yeyo identifikatoryi ne publikuyutsya.

Oba izmenyavshikhsya v istochnike fajla priyoma isklyuchenyi: ikh polnaya zamena poteryala byi dejstvuyusjhiye ispravleniya kornya. Profilj ochistki poluchayet toljko adresnuyu zamenu puti neobkhodimogo JSON; algoritm ne menyayetsya. Istoricheskiye URL-bajtyi i znacheniya istochnikov sokhranyayutsya, novyiye lokaljnyiye puti ne vyidayutsya za prezhniye Git-pereimenovaniya.

V predyidusjhem etape zerkalo Codex zakrepleno k 601d7a84, kod 0 za 7,468192958 s; publikacionnyij remote vernul tot zhe polnyij OID. Guard vernul 3 i 11 nezavershyonnyikh obyazateljstv, rabota prodolzhayetsya. I2P peredan dochernim pisatelem v 6049110117aa2d46380422ff51e2e996f087ee90; yego kornevaya priyomka yesjhyo predstoit, W osvobozhdyon.

Pri podgotovke pervogo chteniya oshibochno ugadan otsutstvuyusjhij putj trebovaniya; tochnoye imya vosstanovleno iz manifesta. Pervichnyij vyivod 0b2f81 sokhranyayetsya kak ocherednoye nablyudeniye dlya uzhe otkryitoj rabotyi diagnostiki0009. Pervaya popyitka start oshibochno smeshala pole vremeni i suffiks --label; instrument zakryil zapisj otkazom, posle chteniya SKILL i realizacii vyipolnen korrektnyij start s toj zhe kanonicheskoj vremennoj paroj. Sistemnaya diagnostika granicyi argumentov ostayotsya otdeljnoj rabotoj.

## Sobstvennyij rezuljtat perenosa

V sobstvennoye derevo perenesenyi 393 iskhodnyikh fajla: predmetnaya avtomatizaciya, arkhivator, 377 fajlov 67 URL-snimkov i dva vkhodnyikh JSON. Vse iskhodnyiye SHA sverenyi s zakreplyonnyim kommitom. Zatem README poluchil chetyire adresnyiye ssyilki, a profilj ochistki — odin putj k dostavlennomu JSON. V README sovpal predusmotrennyij SHA `529907ee090e1c8e52c6a70dc07093dea49b3f627da94b1408aa22e134c56c9a`, v profile — `0d8d10903499bcfc37c976ae8ddbc47f40e7bfdbd5b18f48f9dafa133691765f`; eto bajtyi do obnovleniya recency.

Kartochka FUM-STEP-0212 pereimenovana shtatnoj komandoj za 1,013403750 s. Sokhranenyi iskhodnyiye kriterii, dobavlen rezuljtat i otdelena iskhodnaya priyomka ot tekusjhego perenosa. Nezavisimoye chteniye obnaruzhilo ustarevsheye itogovoye rezyume: poslednij iskhodnyij profilj soderzhit 30,070250 ms, a pozdnij nabor arkhivatora — 56 testov. Kartochka utochnena po etim svideteljstvam. Prezhniye 55 testov v diagnosticheskikh kartochkakh otnosyatsya k svoyemu tochnomu istoricheskomu zapusku i sokhranenyi.

Pyatj kartochek diagnostiki perenesenyi susjhestvuyusjhim paketnyim ispolnitelem: obnovleniye FUM-SBOJ-0020 sokhranyayet proyavleniya 0001–0002 i dobavlyayet uzhe zaregistrirovannoye 0003; FUM-SBOJ-0081–0084 sokhranyayut iskhodnyiye nomera. Indeks postroyen v svoyom dereve. Vo vtorom shtatnom pakete istochniki v tryokh kartochkakh perestavlenyi v konec; vesj nabor strok sokhranyon pobajtno, dopolniteljnoye nablyudeniye MYRTEX pomesjheno v predmetnyij razdel. Primeneniye zanyalo 18,680065250 s. Ni odin novyij nomer dlya finansovogo perenosa ne vyidelen. Raneye soglasovannyiye dva fajla priyoma ostayutsya sobstvennyimi versiyami.

## Adresnaya proverka i resheniye ob optimizacii

Pervyij zapusk profilya ochistki vosproizvyol otsutstvuyusjhij putj iskhodnogo Zhurnala i zavershilsya kodom 1. Posle yedinstvennoj zamenyi puti tot zhe profilj proshyol: 26 HTML-snimkov, semj povtorov, maksimum 328,763583 ms. Nabor vklyuchayet ochistku HTML i zagolovkov v pamyati; setj, izvlecheniye i zapusk Python ne vkhodyat v izmereniye. Prezhnij otricateljnyij iskhod sokhranyon otdeljnoj mashinnoj zapisjyu.

V prinimayusjhem dereve proshli 16 testov reyestra i 56 testov arkhivatora. Proverka sokhranyonnogo vyipuska na yavno zadannuyu datu 2026-09-11 podtverdila te zhe 16 organizacij. Novyij profilj reyestra soderzhit semj povtorov i maksimum 22,823791 ms; izmeryayet chteniye, proverku svideteljstv, ocenku i vyipusk v progretom processe. Idempotentnostj ochistki i vosproizvedeniye vyipuska podtverzhdenyi v svoikh ogranichennyikh scenariyakh.

Probeljnaya proverka vsego indeksa zavershilasj kodom 2 na iskhodnom formatirovanii syiryikh URL-snimkov: koncevyiye probelyi, CRLF i pustyiye zavershayusjhiye stroki. Vse 377 fajlov pered staging pobajtno sovpali s iskhodnyim kommitom; ikh normalizaciya narushila byi sokhrannostj svideteljstv. Otdeljnaya probeljnaya proverka tochnogo spiska ostaljnyikh 46 putej proshla. Globaljnaya Git-konfiguraciya i politika istochnikov ne menyalisj; pervonachaljnyij otricateljnyij zapusk sokhranyon.

Pervyij zaklyuchiteljnyij dopusk kontroljnoj tochki zavershilsya kodom 1 za 44,765614542 s: obnovleniye recency i yeyo indeksa posle predprosmotra izmenilo oba tekusjhikh otpechatka. Sravneniye pokazalo raskhozhdeniye toljko dvukh kontekstnyikh strok upravlyayemogo bloka. Iskhodnyiye desyatj terminaljnyikh zapisej sokhranenyi. Poryadok vosstanovlen: soderzhateljnyiye pravki i recency, tochnyij indeks, zatem svezhij predprosmotr i staging toljko tekusjhego otchyota s yego zapisyami. Etot otkaz ne obyyavlyayetsya defektom proveryayusjhego instrumenta.

Adresnaya adaptaciya puti ne menyayet algoritm. Nablyudayemyiye profili ne dayut osnovaniya vvoditj dopolniteljnuyu optimizaciyu v ramkakh perenosa: sokhranyayetsya proverennaya realizaciya. Raznica s istoricheskimi zamerami ne obyyavlyayetsya uskoreniyem, poskoljku otdeljnyij kontrolj odinakovyikh uslovij do i posle zdesj ne provodilsya. Proyekciya sokhranyayetsya iz pokoleniya kommita `6bf2f53fc76069b02ba1eae3ed31235716f0f1cd`, derevo `d497ed6dd8ba82eaaf808d9d2002050be0d3abb3`, vkhodnoj inventarj `4f14956be3b309ea1fa5be7c2330255c7ea7f9348e56c3dccb229065dfa2fb13`; ona otstayot ot kanonicheskikh pravok etoj kontroljnoj tochki. Polnyij smoke-check i sobstvennoye finaljnoye zakryitiye ostayutsya v plane.

## Vosstanovleniye i soglasovannoye prodolzheniye

Posle vosstanovleniya prochitan pervichnyij JSONL svoyej kornevoj zadachi: odin podtverzhdyonnyij poljzovateljskij ekzemplyar, zavershyonnaya granica 128193596 bajt, SHA-256 `548126f9846fd2916f2e15d571a8a829b7dffee9bbcc840e83dc916d478c91a1`, nepolnyij khvost 0. Dopisannyiye posle snimka 1501 bajt ne obyyavlenyi prochitannyimi komandami. Sverenyi iskhodnyij vopros, tekusjhij Zhurnal, reyestr i plan; chteniye ne pogashayet obrabotku. HEAD ostayotsya `601d7a84719d86c9f5535f4d80bf543afc6bb6e2`, ref — `refs/heads/codex/приём-направлений-FUMA-0201`. Fizicheskij korenj i UUID sverenyi so sredoj; v svoyom dereve pishet toljko korenj, oba subagenta vedut chteniye i chastnyiye predlozheniya.

Na iskhodnyij vopros o paralleljnyikh derevjyakh sokhranyayetsya otvet: sejchas dostatochno susjhestvuyusjhikh. Nezavisimyiye chteniya vyipolnyayutsya paralleljno; novoye podgotoviteljnoye derevo ne sozdavalosj. Prodolzhayutsya sobstvennaya priyomka, proverka peredachi I2P i podgotovlennyiye predmetnyiye napravleniya. Utverzhdeniye zaversheniya vsego priyoma ne delayetsya.

Porucheniye koordinatora zarezervirovatj odin nomer dlya nesovmestimosti normativnyikh profilej M/L ispolneno cherez obsjhij raspredelitelj: FUM-SBOJ-0090, sobyitiye `2574ad635afe12e291f196b0af34bc992451c0dcd53fb09bf9f2e0d9f3d01450`, 7,139264708 s. Osnovaniye — otkaz polnogo C2 `f81e52ff-c573-4b5a-9f59-240fba1dea25`, susjhestvuyusjhij STEP-0175 i sokhranyonnaya smyislovaya sverka koordinatora. Nomer peredan koordinatoru i susjhestvuyusjhej zadache `01a09047-faa1-7370-83f7-cdfc8f9943a6`; kartochku sozdayot etot ispolnitelj. Otdeljnaya zadacha i vtoraya kartochka ne sozdavalisj.

Pri poiske lokaljnogo chitatelya ispoljzovan nesusjhestvuyusjhij shell-shablon, poluchen otkaz `4e68ee`; putj najden cherez inventarj `rg --files`. Pervaya adresnaya pravka profilya ne sovpala s registrom imeni konstantyi i byila otklonena do zapisi; posle chteniya fakticheskoj stroki primenena tochnaya zamena. Eti nablyudeniya ne skryivayutsya uspeshnyim povtorom i vkhodyat v nezavershyonnuyu sverku granic ugadyivaniya putej i argumentov.

Nezavisimaya sverka obnaruzhila 16 sokhranyonnyikh proyavlenij FUM-SBOJ-0009 pri ustarevshem chisle 15 v indekse. Zadacha Gosuslug soobsjhila o sobstvennom yesjhyo ne zakommichennom proyavlenii 0017; nomer schitayetsya zanyatyim, nashi novyiye nablyudeniya yego ne poluchayut. Sverka i soglasovannyij perenos ostayutsya v rabote. Polucheno takzhe soobsjheniye zadachi Telegram o lokaljnoj kontroljnoj tochke `d0ba8b44a9d41e79c4eae4b6996ab1dbfb6d37bf`: eto peredannoye ispolnitelem sostoyaniye, kornevoj priyomkoj ono zdesj ne obyyavlyayetsya; publikaciya, realjnaya sborka i okonchaniye STEP-0222 ne podtverzhdenyi.

## Istochniki

- [Iskhodnyiye komandyi](zapros.md).
- [Tochnyij iskhodnyij perenos](materialyi/perenos-finansirovaniya.json) i [adresnyiye adaptacii](materialyi/adresnyiye-adaptacii.json).
- [Plan prodolzheniya](materialyi/planyi/prodolzheniye.json).
- [Predyidusjhij etap i pozdniye trebovaniya](../2026-09-11_21-47-07_MSK_podtverditj-README-i-utochnitj-zerkala/otchyot.md).
- [Zakryityij otchyot istochnika](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:19:02 MSK -->
<!-- content-sha256: sha256:afd79fffe48685a18f48c619a913e917b0dc51aaff9b7bcc334899ff2d1b4254 -->
<!-- FUM-MD-RECENCY:END -->
