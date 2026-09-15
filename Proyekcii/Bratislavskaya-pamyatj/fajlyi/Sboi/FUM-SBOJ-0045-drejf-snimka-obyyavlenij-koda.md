+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0045"
"статус" = "активна"
+++
# Drejf snimka obyyavlenij koda

## Nablyudayemyij sboj

Sokhranyonnyij tochnyij snimok raskhoditsya s nablyudayemyim polnyim inventaryom. V nablyudeniyakh smeshanyi sobstvennyiye novyiye imena, obyazateljnyiye vneshniye imena, lozhnyiye srabatyivaniya i izmeneniya pozicij; odin obsjhij khyesh ne obyyasnyayet ikh proiskhozhdeniye. Tekusjhaya priyomka 0165 obnaruzhila 43800 zapisej protiv sokhranyonnyikh 43163.

## Granica povtoreniya

Kartochka obyyedinyayet povtornyiye nablyudeniya neobyyasnyonnogo drejfa polnogo snimka obyyavlenij. Odin zapusk s mnozhestvom zapisej ostayotsya odnim proyavleniyem. Otkaz na nepodderzhannyij CJS-format otnositsya otdeljno k FUM-SBOJ-0117; posleduyusjhij uspeshnyij razbor formata ne prinimayet vesj chislennyij ostatok.

## Proyavleniya

- `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0001`: dopolniteljnaya proverka polnogo snimka obyyavlenij v [etape adaptacii](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/otchyot.md) vernula «snimok ne sovpadayet s tekusjhim ostatkom». Sokhraneno 43091 obyyavleniye; nablyudayetsya 43105. Posle udaleniya yedinstvennoj novoj zapisi etogo etapa — obyazateljnogo vneshnego `unittest.TestCase.setUp` — ostayotsya 43104. V ostaljnyikh novyikh Python-fajlakh latinskikh obyyavlenij ne najdeno. Sledovateljno, raskhozhdeniye ne ischerpyivayetsya tekusjhim etapom. Eto odno nablyudeniye sostoyaniya, a ne 14 otdeljnyikh proyavlenij.

- `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0002`: v [realizacii perenosa](../Zhurnal/2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/otchyot.md) povtorno otkazala dopolniteljnaya proverka polnogo snimka: sokhraneno 43163, nablyudayetsya 43606 obyyavlenij, raznica 443 otnositsya k Python. Novyij instrument posle ustraneniya oshibochno uchtyonnyikh prisvaivanij vneshnim API dayot nulevoj ostatok. [Adresnaya sverka](../Zhurnal/2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/materialyi/profilj/deljta-obyyavlenij.json) sravnila obyyavleniya vsekh izmenyonnyikh podderzhannyikh fajlov s tochnyimi Git-obyyektami osnovyi `1aab4c016f726452861f42963b59b6ba66483437`: izmeneniye inventarya ravno nulyu. Obsjhij snimok ne obnovlyalsya. Eto povtor nablyudeniya drejfa, a ne 443 otdeljnyikh proyavleniya.

- `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0003`: [polnyij inventarj](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/materialyi/zapuski-proverok/30_e3801048-0916-4775-8965-3803f168219b.json) posle dopuska chetyiryokh CJS postroyen uspeshno i soderzhit 43800 zapisej pri sokhranyonnyikh 43163; [sravneniye imyon](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/materialyi/zapuski-proverok/32_d4dc19b3-0eed-4c80-af16-e6095a45254c.json) s tochnyimi obyyektami kommita snimka `436909208424595f7151f6febca75f89018c0bcb` vyiyavilo i sobstvennuyu deljtu 0165, i unasledovannyij prirost v instrumentakh prodvizheniya, planirovaniya, ochistki istochnikov i istoricheskikh materialakh. Koordinator vzyal unasledovannuyu chastj na sebya; korenj 0165 prodolzhayet sobstvennuyu. Polnyij snimok ne obnovlyalsya. Primenimostj CLI-profilya obsjhej priyomki utochnyayetsya otdeljno i ne vyivoditsya iz klassa obyortki.

- `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0004`: pri [podklyuchenii yavnogo profilya CLI](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/zapros.md) adresnaya proverka pyati novyikh versij iskhodnikov vyiyavila sobstvennoye smeshannoye imya polya `семантика_sha256` ([otkaz 20](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/zapuski-proverok/20_5d003902-1288-418f-9293-125ceecdf0c7.json)). Eto novoye napisaniye tekusjhego sreza, a ne povtornoye obnaruzheniye istoricheskogo koda. Predshestvuyusjhij [otkaz 18](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/zapuski-proverok/18_5a9f872c-1c12-4b0c-84c3-bfd72844722c.json) videl dva prisvaivaniya vneshnikh native-polej `error` i `text`; oni klassificirovanyi otdeljno ot sobstvennogo polya. Oshibka fiksturyi teperj zadayotsya parametrom susjhestvuyusjhej fabriki, bez povtornogo razbora i mutacii serializovannoj obolochki. Sobstvennoye pole pereimenovano v `хэш_семантики`. [GREEN 21](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/zapuski-proverok/21_3157ca53-0ce6-4ff0-97fe-28dbd1bbe69e.json) podtverdil nulevuyu deljtu vsekh pyati konechnyikh iskhodnikov i tochnyiye SHA; obsjhij snimok ne menyalsya. [Sverka zamenyi](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/materialyi/pereimenovaniye-polya-profilya.json) dokazyivayet yedinstvennoye izmeneniye imeni vne izmeryayemogo intervala; vse pervonachaljnyiye izmereniya sokhranenyi. Nomer 0004 zakreplyon koordinatorom posle nezavisimoj sverki refs i rezervov; eto odno proyavleniye s etapami lokalizacii, a ne tri sboya.

## Ozhidaniye i klassifikaciya

Prinimayemyij snimok dolzhen vosproizvodimo sootvetstvovatj obyyasnyonnomu ostatku; novyiye sobstvennyiye imena ne prinimayutsya toljko po nasledovaniyu. Nablyudeniye drejfa podtverzhdeno. Prichina kazhdoj dopolniteljnoj zapisi yesjhyo ne klassificirovana, poetomu vesj prirost ne obyyavlyayetsya novyim narusheniyem yazyika. V chastnosti, klyuchevyiye slova Swift i imena vneshnikh protokolov trebuyut analiza roli.

## Mekhanizm i sistemnoye ustraneniye

Sokhraneno prezhneye ogranichennoye vosstanovleniye: snimok ne obnovlyon bez razbora, adresnaya funkcionaljnaya priyomka otdelena ot proverki polnogo ostatka. Dlya pervogo proyavleniya ostayotsya istochnik `a3bde39c84528848b13b0b2b415a7e6fd033b9a1`; dlya posleduyusjhikh — tochnaya reviziya sootvetstvuyusjhego snimka. Nuzhnyi klassifikaciya sobstvennyikh i vneshnikh obyyavlenij, obyyasneniye peremesjhenij i regressii inventarizatora. Istoricheskiye iskhodnyiye bajtyi profilya do optimizacii sokhranyayutsya.

Tochnaya diagnostika tekusjhego razbora sokhranena v [sleduyusjhem etape](../Zhurnal/2026-09-14_21-11-44_MSK_sveritj-obsjhuyu-granicu-priyomki/otchyot.md). Ispravleniye Swift-rolej v kontroljnoj tochke 165c9874 oshibochno skryivalo realjnyiye signaturyi; shestj dopustimyikh primerov podtverzhdenyi kompilyatorom, RED i posleduyusjhimi regressiyami. Versiya posle ispravleniya vozvrasjhayet 121 metku i parametr `$source`, isklyuchayet tri lozhnyikh svojstva i povtornuyu zapisj `url`. Vse 557 novyikh pozicij ciklov uzhe prisutstvovali v istoricheskikh iskhodnikakh 4369092: utochnilsya moment obnaruzheniya, a ne vozrast napisaniya. Neodnoznachnaya migraciya imeni, sovpadayusjhego s modifikatorom, zakryita otkazom. Popozicionnyiye roli, kratnostj, Git-bajtyi i granica polnoj priyomki sokhranyayutsya v [klassifikacii](../Zhurnal/2026-09-14_21-11-44_MSK_sveritj-obsjhuyu-granicu-priyomki/materialyi/klassifikaciya-deljtyi-svift.json). Eto diagnostika nezavershyonnogo tretjyego proyavleniya; obsjhij snimok yesjhyo ne prinyat.

[Promezhutochnaya mera 0173](../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/otchyot.md) zamenila nebezopasnyij perevod vsekh tokenov ogranichennyim analizom privyazok i tochnoj kartoj potrebitelej. Posle RED/GREEN i avtomatizirovannoj migracii 15 fajlov neobosnovannyij novyij ostatok gruppyi 19 instrumentaljnyikh putej raven nulyu. [Posleduyusjhij etap](../Zhurnal/2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/otchyot.md) ustranil 45 sobstvennyikh zapisej zhivyikh izmeritelej i svyazal kazhdoye iz 312 novyikh nablyudenij Python s istoricheskimi iskhodnyimi strokami; 26 udalenij klassificirovanyi kak vneshniye AST API. Eto chastichnoye ustraneniye proyavleniya 0003: obsjhij snimok yesjhyo ne obnovlyon, trebuyetsya obyyedinyonnaya priyomka s 0165, status sboya ne izmenyon.

Dlya proyavleniya 0004 primenena rannyaya adresnaya proverka sobstvennyikh imyon do standartnoj priyomki. Novyij smeshannyij klyuch ispravlen, vneshniye polya ne pereimenovanyi; fabrika testa uprosjhena, 12 Node-testov proshli povtorno. Mera tekusjhego sreza ne zakryivayet obsjhij aktivnyij sboj i ne dokazyivayet avtomaticheskogo zapreta povtorov na vsekh putyakh.

## Svyazannyiye shagi

Obyyedinyonnaya [klassifikaciya 0165 i 0173](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/sovmestnaya-klassifikaciya.md) vosproizvela tochnyij istoricheskij massiv43163 i obyyasnila perekhod k43091. Vse izmenyonnyiye klyuchi sokhranenyi s kratnostjyu;385Python-perevodov podtverzhdenyi tokenami, AST i khyeshirovannyimi planami,312istoricheskikh obnaruzhenij svyazanyi s iskhodnyimi bajtami. Shtatno obnovlyon snimokSHA46642cc72523484d581d21f756de67d350de2f231d9b77db7612581e6d70b76d. Eto zavershyonnaya klassifikaciya i vosstanovlennaya kontroljnaya granica; polnaya priyomka obyyedineniya yesjhyo trebuyetsya, kartochka ostayotsya aktivnoj.

- [FUM-STEP-0173](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0173-razobratj-drejf-snimka-obyyavlenij.md) — obsjhij razbor drejfa i rannyaya proverka povtorov, vklyuchaya `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0004`; prezhniye osnovaniya `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0001`, `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0002` i `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0003`.
- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — sobstvennaya deljta tekusjhej postavki; osnovaniya `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0003` i `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0004`.

## Kriterii zakryitiya

Proiskhozhdeniye kazhdogo izmeneniya ostatka obyyasneno; sobstvennyiye novyiye latinskiye obyyavleniya ustranenyi libo ustanovlena primenimostj tochnogo vneshnego kontrakta. Soglasovannyij snimok i regressii zapresjhayut neobyyasnyonnoye rasshireniye, ne smeshivaya yego s dopustimyimi vneshnimi tochkami vkhoda. Prostoye obnovleniye obsjhego khyesha ne zakryivayet sboj.

## Istochniki

- [Podklyucheniye profilya, pervichnyiye otkazyi i vosstanovleniye](../Zhurnal/2026-09-15_02-35-33_MSK_podklyuchitj-porozhdyonnyiye-modeli/otchyot.md).

- [Pervoye nablyudeniye](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).
- [Sokhranyonnyij snimok](../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/ostatok-obyyavlenij-koda.json).
- [Tekusjhij zapros i naznacheniye tretjyego proyavleniya](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/zapros.md).
- [Proiskhozhdeniye tochnyikh vkhodov i prezhnej versii kartochki](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/materialyi/proiskhozhdeniye-drejfa-obyyavlenij.json).

- [Otkaz polnogo snimka](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/zapuski-proverok/21_67880c85-58b0-4821-b9e6-2abeb42bb7dd.json), [adresnaya diagnostika novyikh fajlov](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/zapuski-proverok/22_06391345-57d8-4636-8549-b2c24f52cc55.json), [sopostavleniye inventarya](../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/zapuski-proverok/23_8c5742d4-de56-4d63-a0c1-3f2e4ef288c5.json).

Prezhniye proyavleniya perenesenyi iz proverennogo blob `6a539f645601902085315ba21b7522e5eabbe5e6`; soderzhateljnaya granica kartochki sokhranena i normalizovana v tekusjhiye vosemj razdelov. Istoricheskij tekst vtorogo proyavleniya ne oznachayet priyomku nyineshnego prirosta.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 04:47:16 MSK -->
<!-- content-sha256: sha256:c38238f9519ff340872419c9843a48e767c8497e0d574404dc668b60cd8cc9e6 -->
<!-- FUM-MD-RECENCY:END -->
