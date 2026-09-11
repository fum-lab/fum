# Otchyot 2026-09-11 22:33:53 MSK - Soglasovatj profili dopuska prodolzheniya

Podgotovlena uzkaya sovmestimostj prinimayusjhego validatora M s sobstvennyim dvukhpoljnyim i celevyim chetyiryokhpoljnyim JSONL-profilyami prodolzheniya. Vyibor opredelyayetsya tochnoj paroj dejstvuyusjhikh kornevyikh pravil. Udaleniye JSONL-polej pri sokhranyonnyikh pravilakh L otklonyayetsya. 38 adresnyikh testov proshli; realjnyiye M i L prinyatyi izmenyonnyim validatorom. Eto postavka predposyilki dopuska, a ne prinyatiye novogo sliyaniya v master.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj                       | Granicyi i sposob izmereniya                                                                                                                         |
| ------------------------------ | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Soderzhateljnaya rabota          | ne izmereno                        | Chteniye M/L, pereispoljzovaniye pyati grupp regressij, realizaciya i nezavisimoye chteniye diff; kalendarnaya dliteljnostj ne vosstanavlivayetsya po dogadke |
| Adresnyij TDD                   | 18,784665959 s                     | Summa monotonnyikh intervalov obyortki dlya zapuskov 1, 2, 3, 6, 7; vklyuchayet tri RED i dva GREEN, bez dvojnogo schyota vlozhennogo unittest               |
| Profilirovaniye realjnyikh M i L  | 0,740882750 s                      | Summa intervalov obyortki dlya zapuskov 4, 5, 8, 9; dva poslednikh izmeryayut kod posle HTML-revjyu                                                      |
| Vyibor profilya posle HTML-revjyu | M: 0,000851792 s; L: 0,000708792 s | Nakoplennoye vremya odnogo vyizova v cProfile, uzhe vkhodit v predyidusjhuyu stroku i ne summiruyetsya povtorno                                               |
| Obsjhaya priyomka i zamyikaniye      | ne izmereno                        | Fakticheskiye dliteljnosti pryamyikh zapuskov sokhranyayutsya nizhe; proyekciya i proverki posle zakryitiya nakhodyatsya vne etoj granicyi                           |
| Ozhidaniye tyazhyologo okna         | ne izmereno                        | Koordinator osvobodil okno do obsjhego zapuska; FIFO ne ispoljzuyetsya                                                                                 |

Granica profilya: pryamyiye vyizovyi ot pervogo RED do poslednego standartnogo smoke tekusjhego etapa; summa vremeni vyizovov ne yavlyayetsya kalendarnoj dliteljnostjyu sessii. Ozhidaniye, Git-publikaciya i posleduyusjhaya integraciya ne vkhodyat. Podrobnyij profilj funkcij i khyeshi vkhodov sokhranenyi v [izmereniyakh](materialyi/profilj-dopuska.json). Dolya vyibora profilya v itogovoj strukture sostavlyayet meneye 2%; otdeljnaya optimizaciya po etim dannyim ne trebuyetsya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:d1b1cf8f3773e1952fcc7e06c349a2d066d833642dd6abfea3ef1d7170fda250 -->

| Vyizov                                                                 | Dliteljnostj | Rezuljtat               |
| --------------------------------------------------------------------- | ------------ | ----------------------- |
| [korenj] RED sovmestimosti profilej M i JSONL                         | 4,084 s      | neuspeshno               |
| [korenj] RED aktivnosti pravil i zakryitogo razbora JSON               | 1,095 s      | neuspeshno               |
| [korenj] GREEN strogoj sovmestimosti profilej M i JSONL               | 6,026 s      | uspeshno                 |
| [korenj] Profilj i strukturnyij dopusk realjnogo dereva M              | 0,183 s      | uspeshno                 |
| [korenj] Profilj i strukturnyij dopusk realjnogo dereva L              | 0,187 s      | uspeshno                 |
| [korenj] RED vneshnej HTML-oblasti pravil                              | 1,132 s      | neuspeshno               |
| [korenj] GREEN aktivnosti pravil posle revjyu                          | 6,448 s      | uspeshno                 |
| [korenj] Itogovyij profilj i dopusk dereva M                           | 0,189 s      | uspeshno                 |
| [korenj] Itogovyij profilj i dopusk dereva L                           | 0,183 s      | uspeshno                 |
| [korenj] RED strogogo poryadka voprosov iz L                           | 0,205 s      | neuspeshno               |
| [korenj] GREEN i profilj strogogo poryadka voprosov iz L               | 0,21 s       | uspeshno                 |
| [korenj] RED skanera putej na bukvaljnom oboznachenii tiljdyi           | 20,02 s      | ne zaversheno — tajm-aut |
| [korenj] GREEN38 posle nezavisimyikh zamechanij                          | 5,862 s      | uspeshno                 |
| [korenj] Profilj okonchateljnogo dopuska M                             | 0,151 s      | uspeshno                 |
| [korenj] Profilj okonchateljnogo dopuska L                             | 0,147 s      | uspeshno                 |
| [korenj] Proverka putej okonchateljnogo snimka                         | 22,354 s     | neuspeshno               |
| [korenj] Sokhraneniye otkaza nekanonicheskomu puti posle zapisi fiksturyi | 0,464 s      | uspeshno                 |
| [korenj] Proverka putej posle pravki literala fiksturyi                | 22,474 s     | uspeshno                 |
| [korenj] Predvariteljnaya svyaznostj itogovogo etapa                    | 42,784 s     | uspeshno                 |
| [korenj] Standartnaya priyomka profilej i poryadka proverok              | 847,422 s    | uspeshno                 |

Obsjheye vremya pryamyikh zapuskov proverok: 981,62 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Zavershyonnyij scanner vyiyavil yedinstvennuyu zapresjhyonnuyu absolyutnuyu formu v literale testovoj podstanovki kataloga. Ta zhe stroka stroitsya iz otnositeljnyikh chastej; politika i proveryayemyiye variantyi puti sokhranenyi. Adresnyij test tochnogo scenariya posle pravki proshyol (0,359 s vnutri unittest); povtornyij scanner podtverzhdayet publikacionnuyu granicu svoim fakticheskim iskhodom nizhe.

- Zamechaniya nezavisimogo revjyu: kazhdyij variant udaleniya JSONL-polya teperj ispoljzuyet svezhuyu kopiyu inventarya; otdeljno proveryayetsya otsutstviye toljko ostatka soobsjhenij. Oboznacheniye tiljdyi v regex zameneno ekvivalentnyim kodom simvola bez oslableniya skanera putej. Povtornyij GREEN38: 5,779 s vnutri unittest. Okonchateljnyiye profili realjnyikh M/L: vyibor 0,000755875/0,000723542 s, struktura 0,055798208/0,058449750 s; khyeshi obeikh redakcij sokhranenyi v izmereniyakh.
- Pervaya otdeljnaya proverka putej dostigla ustanovlennogo predela 20 s i zavershilasj kodom 124 bez rezuljtatov. Nazvaniye zapisi soderzhit RED kak celj diagnostiki, no eta popyitka ne dokazyivayet obnaruzhennoye skanerom narusheniye. Posle ispravleniya vyipolnyayetsya obyichnyij neizmenyonnyij skaner s dostatochnyim predelom; iskhod pervoj popyitki sokhranyon.

- Dopolneniye do full: tochnyiye production i tri sravneniya poryadka iz L. RED dvukh testov — dva otkaza; GREEN s cProfile — dva uspekha, 0,032 s vnutri unittest, 0,209899333 s po obyortke. Dva vyizova build_steps zanyali 0,009834583 s; optimizaciya ne trebuyetsya. Podrobnosti v [profile poryadka](materialyi/profilj-poryadka-voprosov.json).

- Pervyij RED: 34 testa, 11 otkazov na nesovmestimosti L i nedostatochnoj zasjhite profilya; dopolniteljnyiye tri testa aktivnosti i povtornyikh klyuchej dali vosemj otricateljnyikh podsluchayev. Zatem GREEN: 37 testov za 5,916 s vnutri unittest.
- Nezavisimoye revjyu vyiyavilo vneshnyuyu HTML-oblastj. Odin adresnyij RED vosproizvyol desyatj podsluchayev na prezhnem kode, zatem finaljnyij GREEN proshyol 38 testov za 6,351 s vnutri unittest. Polnyij syiroj vyivod pervogo HTML-RED v interfejse byil obrezan; chislo otkazov podtverzhdeno itogom, polnota syirogo loga ne zayavlyayetsya.
- Itogovyij validator prinyat na realjnyikh M i L s tochnyimi pravilami i inventaryami. Kod L ne ispolnyalsya; sobstvennyij validator chital L kak vkhod.
- Finaljnyij standartnyij smoke i shtatnoye zamyikaniye vyipolnyayutsya posle predvariteljnoj svyaznosti. Yedinstvennyij poslednij polnyij zapusk i gotovnostj fiksiruyutsya upravlyayemyim blokom; otsutstviye zapisi ob uspekhe ne zamenyayetsya etim opisaniyem.

## Resheniya i ogranicheniya

1. Komanda o vidimyikh nezavisimyikh rabotakh vyipolnena sobstvennoj vidimoj zadachej i otdeljnyim worktree. Dochernemu auditoru dan toljko rezuljtat chteniya bez zapisi i tyazhyolyikh testov.
2. Komanda o priyomke po master opredelyayet istochnik M `224dc6cf289e4cc88080b85ad7c99240284a7ced`. Polnyij obyazateljnyij nabor pravil, inventarj i navyik prochitanyi do pervoj zapisi; normativnyiye tekstyi i inventarj M sokhranenyi. Pyatj grupp testov 0177 pereispoljzovanyi, novaya prinimayusjhaya logika podderzhivayet oba profilya.
3. Komanda o sliyanii master v vedusjhuyu vetku sokhranyayet napravleniye i poryadok daljnejshikh dejstvij koordinatora. Neprinyatyij C2 `de9f81fec9e2bad840c6e37b049f5734f544d07b` ispoljzuyetsya toljko kak proiskhozhdeniye iskhodnogo otkaza, ne kak prinyatyij istochnik dopuska.
4. Vopros o derevjyakh ot kommitov postanovki zakryit fakticheskoj sverkoj: sobstvennyij HEAD uzhe ravnyalsya M; drugaya vetka i lishnij reset ne ponadobilisj. Odin pisatelj svoyego dereva, chuzhiye ref i indeksyi dostupnyi toljko dlya chteniya.
5. Utochneniye «V fuma, zatem proverennyij rezuljtat v master» ostayotsya dejstvuyusjhim napravleniyem integracii. Etot etap postavlyayet predposyilku v sobstvennoj vetke; prodvizheniye master/fuma i polnocennaya priyomka C2 ostayutsya u koordinatora.

Dopusk zakryit rovno dlya dvukh izvestnyikh par polnyikh tekstov pravil. Neizvestnyiye ili smeshannyiye redakcii, nedejstvuyusjhiye zapisi inventarya, skryityiye normyi, nevernyiye puti, tipyi, klyuchi i poryadok parametrov otklonyayutsya. Eto ne universaljnyij Markdown-parser. Polnaya zamena obeikh norm i deklaracii L tochnyim staryim profilem yavlyayetsya dopustimyim M; zapret istoricheskogo otkata celikom trebuyet vneshnej privyazki ozhidayemyikh pravil pri sliyanii. Staticheskij validator ne obyyavlyayetsya dokazateljstvom takoj istoricheskoj politiki.

[FUM-SBOJ-0090](../../Sboi/FUM-SBOJ-0090-nesovmestimostj-normativnyikh-profilej-prodolzheniya.md) poka aktiven: mera proverena adresno, no zakryitiye trebuyet prinyatj yeyo v master i povtorno proveritj novyij C2 po obnovlyonnomu M. Vse daljnejshiye rabotyi svyazanyi s susjhestvuyusjhim FUM-STEP-0175; novaya zadacha ili avtomaticheskij follow-up ne sozdayutsya.

## Istochniki

- [Iskhodnyij zapros i granica prodolzheniya](zapros.md).
- [Koordinaciya i vidimyiye otvetyi](materialyi/proiskhozhdeniye-koordinacii.md).
- [Granica profilej i iskhodnyij otkaz](materialyi/granica-profilej.md).
- [Otkryitaya fikstura dvukh profilej](../../Instrumentyi/fum-dekompoziciya-pravil-agentov/tests/fiksturyi/profili-prodolzheniya.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:18:30 MSK -->
<!-- content-sha256: sha256:5343156156f7de5707e69ca488dca327a6b0fdf77df08f7be26b6d1add9322f4 -->
<!-- FUM-MD-RECENCY:END -->
