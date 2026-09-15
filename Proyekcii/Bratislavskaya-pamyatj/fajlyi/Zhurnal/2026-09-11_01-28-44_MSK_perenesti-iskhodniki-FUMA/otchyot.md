# Otchyot 2026-09-11 01:28:44 MSK - Perenesti iskhodniki FUMA

Sokhranenyi 71 iskhodnyij fajl chetyiryokh paketov (509 839 bajt) i manifest proiskhozhdeniya. Otnositeljnyiye svyazi sosednikh paketov sokhranenyi. Eto kontroljnaya tochka perenosa; polnaya gotovnostj FUM-STEP-0176 poka ne zayavlena.

## Profilj vremeni vyipolneniya

| Stadiya                  | Dliteljnostj | Granicyi i sposob izmereniya                         |
| ----------------------- | ------------ | -------------------------------------------------- |
| Analiz pravil i sostava  | ne izmereno  | Chteniye i paralleljnyij analiz; intervalyi perekryityi     |
| Postroyeniye plana         | 1,117 s      | Monotonnyiye metki scenariya, 71 fajl                  |
| Izvlecheniye i zapisj      | 2,111 s      | Povtornaya proverka OID/SHA i sozdaniye obyichnyikh fajlov |
| Adresnyiye proverki       | sm. nizhe     | Mashinnyij uchyot kazhdogo pryamogo zapuska               |

Granica profilya: izmeren scenarij perenosa na tekusjhem etape 2026-09-11; obsjhaya podgotovka, ozhidaniye otveta i finaljnaya peredacha ne izmerenyi. Vremya scenariya uzhe vklyucheno v pryamoj zapusk i povtorno ne summiruyetsya. FIFO ne ispoljzovalsya. Swift i standartnyij smoke-check yesjhyo ne zapuskalisj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                  | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj 0176] RED: tochnyiye Git-obyyektyi i zakryityij otkaz perenosa                        | 0,05 s       | neuspeshno |
| [Korenj 0176] RED: otsutstviye realizacii posle ispravleniya fiksturyi                    | 0,057 s      | neuspeshno |
| [Korenj 0176] GREEN: bezopasnoye izvlecheniye zakreplyonnyikh iskhodnikov                     | 1,363 s      | uspeshno   |
| [Korenj 0176] Perenos i profilj 71 iskhodnogo fajla paketov                             | 3,291 s      | uspeshno   |
| [Korenj 0176] RED revjyu: podmena puti i verkhnego proiskhozhdeniya manifesta               | 1,7 s        | neuspeshno |
| [Korenj 0176] GREEN revjyu: tochnyiye puti i cepochka proiskhozhdeniya                         | 1,794 s      | uspeshno   |
| [Korenj 0176] Profilj posle revjyu i ravenstvo 71 iskhodnogo fajla                       | 3,369 s      | neuspeshno |
| [Korenj 0176] RED revjyu: derevo ne yavlyayetsya iskhodnyim kommitom                          | 2,154 s      | neuspeshno |
| [Korenj 0176] GREEN revjyu: zapret podmenyi commit derevom                               | 2,265 s      | uspeshno   |
| [Korenj 0176] Profilj okonchateljnogo izvlecheniya i proverka kanonicheskoj upakovki       | 3,513 s      | uspeshno   |
| [Korenj 0176] Proverka strukturyi, ssyilok i publikacionnoj chistotyi kontroljnoj tochki    | 39,901 s     | neuspeshno |
| [Korenj 0176] Audit mashinno-lokaljnyikh putej perenesyonnyikh paketov                       | 22,251 s     | neuspeshno |
| [Korenj 0176] Lokalizaciya narushenij putej bez razreshyonnyikh istoricheskikh strok           | 22,117 s     | neuspeshno |
| [Korenj 0176] Kontroljnaya priyomka perenosa: svyaznostj, puti, diff                      | 38,6 s       | neuspeshno |
| [Korenj 0176] Sborka reyestra s naznachennyim shagom 0203                                  | 0,413 s      | uspeshno   |
| [Korenj 0176] Svyaznostj i tochnaya publikacionnaya politika posle podgotovki zavisimostej | 63,105 s     | uspeshno   |
| [Korenj 0176] Proveritj tochnyij indeks kontroljnoj tochki perenosa                       | 0,08 s       | neuspeshno |
| [Korenj 0176] Proveritj indeks s sokhraneniyem doslovnogo probela iskhodnoj komandyi       | 0,083 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 206,106 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

Semj adresnyikh testov podtverzhdayut chteniye zakreplyonnyikh obyyektov vopreki izmenyonnomu rabochemu derevu istochnika, sokhraneniye rezhimov, otsutstviye importa untracked, otkaz povtornogo primeneniya, konflikt do zapisi, podmenu SHA, vyikhod za korenj, simvolicheskiye ssyilki i obyyedineniye odinakovyikh putej. Pervyij zapusk vyiyavil oshibku samoj testovoj fiksturyi (kirillica v bytes literal); posle yeyo ispravleniya podtverzhdyon RED otsutstvuyusjhego modulya, zatem GREEN realizacii. Oshibka sokhranena v mashinnom uchyote i ne vyidana za celevoj RED.

Scenarij snachala proveryayet polnyij nabor, zatem pishet; istochnik read-only. Profilj pokazyivayet okolo 3,23 s na 71 fajl i 0,51 MB. Resheniye ob optimizacii: sokhranitj prostoj posledovateljnyij algoritm, poskoljku stoimostj ogranichena odnim perenosom, a povtornoye chteniye podtverzhdayet celostnostj. Uskoreniye ne zayavleno. Posle dvukh zamechanij nezavisimogo revjyu dobavlenyi adresnyiye RED/GREEN dlya verkhnego proiskhozhdeniya i podmenyi commit derevom. Okonchateljnyij profilj: plan 1,191 s, primeneniye 2,199 s; usileniye proverki sokhraneno bez optimizacii, sravneniye ne obyyavlyayet uskoreniya. Dopolniteljnaya proverka upakovki snachala oshibochno predpolozhila otsutstviye recency vo vsekh chetyiryokh iskhodnyikh README; posle sverki iskhodnyikh bajtov ispravleno toljko usloviye sravneniya, sami paketyi ne menyalisj. Itog: 68 fajlov pobajtno ravnyi, u tryokh izmenena toljko sluzhebnaya upakovka. [Kanonicheskiye khyeshi](materialyi/kanonicheskaya-upakovka-paketov.json) i [okonchateljnyij profilj](materialyi/profilj-perenosa-posle-revjyu.json) sokhranenyi. Tyazhyolyiye Swift-proverki budut vyipolnenyi posle sokhraneniya etapa.

## Upakovka i lokaljnaya podgotovka

Mashinnyij audit pokazal 33 raneye ne zaregistrirovannyikh tochnyikh stroki importiruyemyikh fajlov: puti otkryitoj sintetiki, raspolozheniye sobstvennyikh binarnikov v processnyikh testakh, primeryi vremennogo profilya i shebang testovoj fiksturyi. Posle predmetnogo chteniya dobavlenyi toljko [tipizirovannyiye deklaracii](materialyi/deklaracii-putej.json) shtatnyim obnovitelem politiki. Oni ne razreshayut novyiye sosedniye stroki i sokhranyayut iskhodnyiye bajtyi.

Novyij worktree ne soderzhal ignoriruyemyij `.obsidian/graph.json`; susjhestvuyusjhiye istoricheskiye ssyilki vyizvali otkaz globaljnoj svyaznosti. V sobstvennyij raneye otsutstvuyusjhij ignoriruyemyij putj skopirovan poljzovateljskij fajl primary bez izmeneniya primary i bez vklyucheniya kopii v Git. Po naznacheniyu koordinatora sokhranenyi [sboj 0052](../../Sboi/FUM-SBOJ-0052-svyaznostj-trebuyet-lokaljnyij-graf-Obsidian.md) s dvumya podtverzhdyonnyimi proyavleniyami i [shag 0203](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0203-otvyazatj-svyaznostj-ot-lokaljnogo-grafa-Obsidian.md); ispravleniye vosproizvodimosti obsjhego dokumentacionnogo kontura etim dejstviyem ne zayavleno. Chistyij klon dlya proverok novyikh paketov ne budet ispoljzovatj ni poljzovateljskij graf, ni prezhniye iskhodnyiye katalogi.

Pervyij vyizov generatora planovogo reyestra byil vyipolnen napryamuyu kak zapisj i obnaruzhil nevernuyu formu statusa novoj indeksnoj stroki. Nablyudayemaya dliteljnostj ne zapisana obyortkoj i ne vosstanavlivayetsya zadnim chislom. Stroka ispravlena, povtornaya sborka vyipolnena cherez obyortku. Eto ogranicheniye polnotyi mashinnogo uchyota dannogo kontroljnogo etapa; finaljnaya priyomka budet imetj otdeljnuyu polnuyu granicu.

LinguisticKit materializovan v sobstvennom dereve polnyim klonom opublikovannogo forka, sinkhronizirovan s origin i upstream i ustanovlen na prezhnij zakreplyonnyij 837e2ce107b97ee7b9d3344c9fe99142281fe393. Gitlink i publikacionnyiye URL FUM ne menyalisj.

## Resheniya i ogranicheniya

- [Manifest](materialyi/manifest-perenosa-paketov.json) sokhranyayet iskhodnyiye commits, trees, puti, blob OID, SHA-256, razmeryi i rezhimyi. [Profilj](materialyi/profilj-perenosa-paketov.json) soderzhit novyiye izmereniya.
- Tri iskhodnyikh README poluchili toljko sluzhebnyiye bloki recency shtatnyim generatorom; README arkhiva uzhe soderzhal korrektnuyu metku i ostalsya pobajtno neizmennyim. Kanonicheskij SHA i vid etoj upakovki sokhranyayutsya otdeljno; ostaljnyiye fajlyi dolzhnyi sovpadatj pobajtno.
- Nezavisimyij analiz prilozheniya ustanovil: vse yego 39 blob OID otsutstvuyut v iskhodnom FUM. Prototip fizicheskikh klavish imeyet drugoj kontrakt, poetomu ne zamenyayet prilozheniye. Ostatok prilozheniya vklyuchayet staryiye lokaljnyiye puti, nezakreplyonnuyu libmpv i otsutstviye testov. Vse 39 fajlov sokhranyayutsya sleduyusjhim etapom s yavnoj adaptaciyej i proiskhozhdeniyem.
- Iskhodnyij nabor priznan sobstvennyim pryamyim porucheniyem i perenositsya pod obsjhuyu CC0 FUM. Otdeljnogo LICENSE v pakete net. Eto ne menyayet licenzij vneshnikh API i bibliotek. LinguisticKit i yego gitlink ne menyalisj.
- Kod paketov poka sokhranyayet istoricheskiye imena i ogranicheniya Swift tools 6.0 / Swift 6 / macOS 14; obsjhij perevod obyyavlenij, drugiye OS i SwiftNIO ne vkhodyat v dannyij etap.
- Sokhranyonnoye pokoleniye `Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json` otnositsya k startovomu HEAD 406c6ba1; novyikh iskhodnikov v nyom poka net. Kontroljnaya tochka ne obyyavlyayet proyekciyu aktualjnoj i ne zamenyayet finaljnuyu priyomku.
- Soderzhateljnyiye otvetyi koordinatoru: startovyiye identichnosti peredanyi; neobkhodimostj dobavleniya recency soglasovana; nezavisimyiye nomera i chuzhiye derevjya ne izmenyayutsya. Posle etogo kommita rabota prodolzhayetsya: prilozheniye, adaptaciya, chistyij klon, proverki i profili, finaljnaya proyekciya i dostavka.

Posle podgotovki sobstvennoj lokaljnoj sredyi svyaznostj i tochnaya publikacionnaya politika putej proshli. Proverka uzhe postavlennogo indeksa `git diff --cached --check` otdeljno obnaruzhila odin konechnyij probel v doslovnoj iskhodnoj komande poljzovatelya; on sokhranyon po trebovaniyu neizmennogo proiskhozhdeniya. Ostaljnyiye puti proveryayutsya obyichnyim `diff --check`, tochnyij fajl zaprosa — s otklyucheniyem toljko `blank-at-eol` i otdeljnyim sravneniyem doslovnoj oblasti s pervoistochnikom. Eto adresnaya proverka kontroljnoj tochki; paketnyiye Swift-testyi i finaljnyij dopusk ostayutsya sleduyusjhim etapom. Vosstanovlennyij kontekst sveren s originaljnyimi porucheniyami koordinatora v JSONL i dvumya chelovecheskimi komandami; novogo soobsjheniya cheloveka ne obnaruzheno.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [raneye sokhranyonnoye porucheniye](../2026-09-10_17-33-36_MSK_zakrepitj-dopusk-sliyaniya-iz-master/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 03:52:50 MSK -->
<!-- content-sha256: sha256:669ffcb708a0330ce60b85bff34194cd10cb449371f3e7141378593d2879d4c6 -->
<!-- FUM-MD-RECENCY:END -->
