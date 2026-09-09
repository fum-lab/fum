+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0031"
"статус" = "устранена"
+++
# Perezapisj istoricheskogo profilya pri pereimenovanii kartochki

Pereimenovaniye kartochki shaga izmenyalo istoricheskiye dannyiye sverki obyyavlenij, poskoljku prinimalo zapisannyij putj obsledovannogo fajla za zhivuyu ssyilku.

## Nablyudayemyij sboj

Pri podgotovke zaversheniya FUM-STEP-0154 obnaruzhen istoricheskij putj v profile sverki s bazoj ab3a9d24. Yego prezhneye imya opisyivayet obsledovannyij fajl; zamena imeni izmenila byi svideteljstvo. Nastoyasjheye Git-pereimenovaniye na otdeljnoj fiksture podtverdilo izmeneniye bajtov profilya. Kanonicheskij material ne pereimenovyivalsya i ne povrezhdyon.

## Granica povtoreniya

Specializirovannaya komanda `rename-step-card.py` zamenyayet prezhneye imya v tekstovom Git-inventare. Sverka obyyavlenij v tochnoj oblasti `Журнал/<канонический stem>/материалы/профили/сверка-объявлений.json` khranit istoricheskiye puti. Yeyo konechnyij strukturnyij kontrakt teperj otlichayet eti dannyiye ot zhivogo teksta. Drugiye JSON-formatyi etoj meroj ne okhvatyivayutsya.

## Proyavleniya

| Lokaljnyij nomer               | Istochnik i dokazateljstvo                                                                                  | Effekt                                      | Vosstanovleniye                               |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------- | -------------------------------------------- |
| FUM-SBOJ-0031/PROYAVLENIYE-0001 | [RED i GREEN](../Zhurnal/2026-09-08_20-55-36_MSK_zasjhititj-istoricheskiye-profili-pri-pereimenovanii/otchyot.md) | Git-fikstura izmenila istoricheskij profilj. | Uzkij adapter i otkaz do zapisi pri defekte. |

## Mekhanizm i sistemnoye ustraneniye

Obsjhaya zamena tochnogo imeni ne razlichala istoricheskoye nablyudeniye i zhivuyu ssyilku. Adapter proveryayet tochnuyu oblastj, zakryityiye polya i tipyi, polnyij format bazovogo OID, nepustoj vneshnij kontrakt i unikaljnyiye normalizovannyiye otnositeljnyiye puti s celochislennyimi neotricateljnyimi schyotchikami. Povtor JSON-polya, povrezhdeniye, nedostupnostj, simvolicheskaya ssyilka ili otsutstviye UTF-8 v etoj oblasti otklonyayutsya do podgotovki zapisej i `git mv`. Prinyatyij profilj ostayotsya pobajtno neizmennyim. Novaya skhema yemu ne pripisyivayetsya; vse novyiye formatyi trebuyut otdeljnogo kontrakta.

## Kriterii zakryitiya

- Nastoyasjheye Git-pereimenovaniye sokhranyayet bajtyi istoricheskogo profilya i obnovlyayet sosednij zhivoj JSON, Markdown i indeks kartochki.
- Povrezhdyonnyij profilj zakryivayet operaciyu do zapisi s neizmennyimi fajlami i indeksom.
- Blizkiye imena i katalogi ne poluchayut obsjhego isklyucheniya.

## Proveryayemyij iskhod

Vse tri kriteriya podtverzhdenyi [adresnyimi regressiyami](../Instrumentyi/fum-reyestr-planirovaniya/tests/test_rename_step_card.py): 16 testov proshli. V [otchyote](../Zhurnal/2026-09-08_20-55-36_MSK_zasjhititj-istoricheskiye-profili-pri-pereimenovanii/otchyot.md) sokhranenyi RED/GREEN i sravnimyij profilj. Ustraneniye otnositsya k ukazannomu istoricheskomu formatu i sobstvennoj vetke; kontroljnyij kommit ne oznachayet integracii v master ili finaljnoj priyomki obsjhego izmeneniya.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-08_20-55-36_MSK_zasjhititj-istoricheskiye-profili-pri-pereimenovanii/zapros.md).
- [Kontrakt specializirovannogo pereimenovaniya](../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 21:46:11 MSK -->
<!-- content-sha256: sha256:ea67302c565f32d0e882e8d1d4153e8c2c5775e4a0ec3bcc233cff4defd50052 -->
<!-- FUM-MD-RECENCY:END -->
