# Otchyot 2026-07-28 08:47:18 MSK - Zakrepitj yazyikonejtraljnyij kanonicheskij protokol pamyati

Kanonicheskiye sobyitiya i pokoleniya pamyati teperj imeyut versionnoye yazyikonejtraljnoye bajtovoye predstavleniye. Profilj `fum.memory.canonical-json.v1` zadayot yedinstvennyiye bajtyi i preimage SHA-256, a obsjhij corpus podtverzhdayet ikh nezavisimyimi Swift- i Python-realizaciyami.

## Rezuljtat

Profilj zakreplyayet strogij UTF-8 bez BOM, kornevoj obyyekt, glubinu do `128`, ASCII-imena polej v bajtovom poryadke, massivyi s sokhraneniyem poryadka, bulevyi znacheniya, neotricateljnyiye celyiye do `2^53−1`, otsutstviye `null`, probelov i konechnogo perevoda stroki, tochnyiye pravila Unicode i ekranirovaniya. NFC i NFD ne normalizuyutsya i ostayutsya raznyimi svideteljstvami. Vyibor oformlen kak prikladnoye podmnozhestvo JCS i I-JSON i svyazan s pervichnyimi RFC, ECMA-262, Unicode i FIPS 180-4.

Swift-runtime ispoljzuyet sobstvennyiye parser i writer. Kanonicheskij kontur ne vyizyivayet `JSONEncoder`, `JSONSerialization` ili `String(format:)`; SHA-256 poluchayet toljko gotovyiye bajtyi profilya. Vneshnyaya programma snachala kanoniziruyetsya sobstvennyim parser, zatem prokhodit tipizirovannoye dekodirovaniye i obyazana povtorno datj te zhe bajtyi sobstvennyim writer. Poetomu `input_sha256` ne zavisit ot Foundation, poryadka transportnyikh polej ili razreshyonnyikh probelov i escape. Pokoleniye skhemyi `3` i `CURRENT` skhemyi `2` yavno nazyivayut profilj; prezhniye skhemyi poluchayut nemutiruyusjhij otkaz.

Obsjhij manifest soderzhit 12 polozhiteljnyikh vektorov, 38 otkazov i 2 izvestnyikh SHA-256 — vsego 52 proverki. On zakreplyayet obyichnyiye `remember` i `compose`, `remember` na granice 16 KiB, Unicode, chisla, glubinu, polnuyu programmu, nachaljnoye i prodolzhennoye pokoleniya i `CURRENT`. Oba verifier sovpadayut po tochnyim `id`, verdict, bytes i SHA-256; Swift dopolniteljno povtorno porozhdayet golden-pokoleniya i ukazatelj iz produktovogo runtime i validiruyet domennuyu celostnostj.

Nezavisimyij audit nashyol i pomog zakryitj chetyire razryiva: neizvestnyiye kanonicheskiye polya posle myagkogo `JSONDecoder`, poteryu oshibok vlozhennogo `Encoder`, raznyij predel glubinyi writer/parser i povtornoye khyeshirovaniye uzhe Foundation-dekodirovannoj programmyi. Dlya nikh dobavlenyi regressii tochnoj skhemyi, `superEncoder`, granicyi glubinyi, NFC/NFD i prezhnikh versij nositelej.

Kartochka FUM-STEP-0101 zavershena. Rabochij nabor sokhranyayet FUM-STEP-0008 kak yedinstvennyij `ready`; FUM-STEP-0102 ostayotsya `paused` do zakonno nastroyennogo provajdera.

## Proverki

Finaljnyij Swift-nabor vyipolnil 41 test bez otkazov, vklyuchaya 52 obsjhikh Swift↔Python-proverki, tochnyiye golden bytes pokolenij, process-crash-scenarii i mezhprocessnyiye gonki. Strogaya sborka s polnoj proverkoj konkurentnosti i preduprezhdeniyami kak oshibkami, Swift Format lint, source guard kanonicheskogo kontura, rabochij nabor vetki i planovyij reyestr proshli avtonomno bez seti i sekretov. Polnyij repozitornyij smoke-check zavershil vse 61 shag.

## Profilj vremeni vyipolneniya

| Stadiya                                      | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                         |
| ------------------------------------------- | -----------: | ---------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i ozhidaniye FIFO                 |  ne izmereno | Ot pervogo `join` do `admitted`; tochnaya dliteljnostj ne sokhranilasj posle prodolzhiteljnogo ozhidaniya.                              |
| Realizaciya i nezavisimyiye audityi             |  ne izmereno | Ot dopuska do finaljnogo koda i dokumentacii; normativnyij, Swift- i vector-audityi chastichno vyipolnyalisj paralleljno.                |
| Celevyiye i sluzhebnyiye proverki do smoke-check |     131,22 s | Sovokupnoye call-time izvestnyikh pryamyikh zapuskov nizhe; paralleljnyiye Python i Swift-vyizovyi arifmeticheski skladyivayutsya kak otdeljnyiye. |
| Polnyij repozitornyij smoke-check             |     262,76 s | Odin vneshnij vyizov iz 61 shaga; vlozhennyiye `smoke-timing` vkhodyat v etu dliteljnostj i povtorno ne summiruyutsya.                       |
| Zakryitiye proveryayemogo snimka                |      13,35 s | Materializaciya sluzhebnyikh predstavlenij i otdeljnyiye finaljnyiye proverki svyaznosti, vetki, reyestra i diff posle smoke-check.         |

### Pryamyiye zapuski proverok

| Vyizov                                                                  | Dliteljnostj | Rezuljtat                                                                                                         |
| ---------------------------------------------------------------------- | -----------: | ----------------------------------------------------------------------------------------------------------------- |
| `[root]` fenced `show` naznachennoj kartochki                            |       0,90 s | uspeshno (vetka, pokoleniye vyibora, kartochka i yeyo khyesh sovpali)                                                      |
| `[root]` pervyij sintaksicheskij krasnyij Swift-test                      |       3,47 s | neuspeshno ozhidayemo (testovaya zagotovka trebovala ispravleniya sintaksisa)                                          |
| `[root]` krasnyij test otsutstvuyusjhego kanonicheskogo API                 |       1,69 s | neuspeshno ozhidayemo (prezhnij production ne soderzhal trebuyemyikh API)                                                |
| `[root]` pervaya popyitka vyibrannyikh testov posle realizacii              |       2,15 s | neuspeshno (vyiyavlena nevernaya granica dostupa vspomogateljnogo tipa)                                              |
| `[root]` pervyij zelyonyij nabor kanonicheskogo JSON                       |       4,03 s | uspeshno (4/4)                                                                                                    |
| `[root]` pervyij polnyij Swift-nabor                                     |      20,91 s | neuspeshno (obnaruzhenyi prezhniye ozhidaniya skhemyi `2` i kodirovaniye `nil` v crash-worker)                              |
| `[root]` celevoj povtor skhem i crash-worker                            |      11,14 s | uspeshno (7/7)                                                                                                    |
| `[root]` pervyij Python conformance                                     |       0,07 s | neuspeshno (obnaruzhen odin neverno perenesyonnyij bajt fixture prodolzheniya)                                         |
| `[root]` ispravlennyij Python conformance                               |       0,07 s | uspeshno (44 iskhodnyiye proverki corpus)                                                                           |
| `[root]` pervyij Swift conformance                                      |       3,06 s | uspeshno (2/2)                                                                                                    |
| `[root]` promezhutochnyij polnyij Swift-nabor                              |      27,64 s | uspeshno (35/35)                                                                                                  |
| `[root]` promezhutochnyij avtonomnyij Python-verifier                      |       0,06 s | uspeshno (44 proverki)                                                                                            |
| `[root]` atomarnoye pereimenovaniye zavershyonnoj kartochki                 |       0,30 s | uspeshno (status `completed`, kaskad 12 zhivyikh ssyilok)                                                            |
| `[root]` pervaya proverka rasshirennogo kodirovsjhika                      |       2,35 s | neuspeshno (test obnaruzhil oshibochnuyu strokovuyu interpolyaciyu)                                                      |
| `[root]` povtor rasshirennogo kodirovsjhika                               |       3,01 s | uspeshno (7/7)                                                                                                    |
| `[root]` promezhutochnyij Swift↔Python conformance                        |       1,62 s | uspeshno (51 proverka do dobavleniya granichnogo sobyitiya)                                                           |
| `[root]` prezhniye skhemyi i tochnyiye polya khranilisjha                         |       1,38 s | uspeshno (4/4)                                                                                                    |
| `[root]` proverka rabochego nabora vetki                                |       0,43 s | uspeshno (`ready_count=1`, FUM-STEP-0008)                                                                         |
| `[root]` peresborka planovogo reyestra                                  |       0,25 s | uspeshno                                                                                                          |
| `[root]` proverka planovogo reyestra                                    |       0,22 s | uspeshno                                                                                                          |
| `[root]` itogovyij Swift↔Python conformance                             |       2,73 s | uspeshno (52 proverki)                                                                                            |
| `[root]` itogovyij avtonomnyij Python-verifier                           |       0,07 s | uspeshno (52 proverki)                                                                                            |
| `[root]` mekhanicheskoye Swift-formatirovaniye                             |       0,33 s | uspeshno                                                                                                          |
| `[root]` itogovyij polnyij Swift-nabor                                   |      26,89 s | uspeshno (41/41)                                                                                                  |
| `[root]` strogaya Swift-sborka                                          |       2,35 s | uspeshno (`strict-concurrency=complete`, preduprezhdeniya kak oshibki)                                              |
| `[root]` strogij Swift Format lint                                     |       0,34 s | uspeshno                                                                                                          |
| `[root]` source guard kanonicheskogo production-kontura                 |       0,02 s | uspeshno (net Foundation-serializatorov i formattera hex)                                                        |
| `[root]` pervaya materializaciya Markdown-recency                        |       0,42 s | neuspeshno (obnaruzhen dublirovannyij sluzhebnyij blok v novom dokumente)                                            |
| `[root]` pervaya materializaciya teplovoj kartyi Obsidian                 |       0,27 s | uspeshno (karta obnovlena)                                                                                        |
| `[root]` povtornaya materializaciya Markdown-recency                     |       0,40 s | uspeshno (obnovlenyi 2 fajla)                                                                                      |
| `[root]` povtornaya materializaciya teplovoj kartyi Obsidian              |       0,25 s | uspeshno (snimok uzhe aktualen)                                                                                    |
| `[root]` proverka publikacionnogo remote i push URL                    |       0,10 s | uspeshno (`origin`, yedinstvennyij credential-free HTTPS URL `github.com`, bez primenimyikh rewrite)                 |
| `[root]` predshestvuyusjhaya smoke-check materializaciya Markdown-recency    |       0,40 s | uspeshno (obnovlenyi 2 fajla)                                                                                      |
| `[root]` predshestvuyusjhaya smoke-check materializaciya grafa Obsidian      |       0,25 s | uspeshno (snimok uzhe aktualen)                                                                                    |
| `[root]` proverka publikacionnogo diff                                 |       0,03 s | uspeshno (`git diff --check`)                                                                                     |
| `[root]` predvariteljnaya proverka svyaznosti sessii                     |      10,90 s | uspeshno                                                                                                          |
| `[root]` finaljnaya podgotovka Markdown-recency pered smoke-check       |       0,45 s | uspeshno (obnovlenyi 2 fajla)                                                                                      |
| `[root]` finaljnaya podgotovka grafa Obsidian pered smoke-check         |       0,27 s | uspeshno (snimok uzhe aktualen)                                                                                    |
| `[root]` polnyij repozitornyij smoke-check                               |     262,76 s | uspeshno (61/61; vnutrenneye total `262,716` s)                                                                    |
| `[root]` materializaciya Markdown-recency posle smoke-check             |       0,42 s | uspeshno (obnovlenyi 3 fajla)                                                                                      |
| `[root]` materializaciya grafa Obsidian posle smoke-check               |       0,28 s | uspeshno (snimok uzhe aktualen)                                                                                    |
| `[root]` finaljnaya proverka svyaznosti sessii                           |      11,38 s | uspeshno                                                                                                          |
| `[root]` finaljnaya proverka Markdown-recency                           |       0,37 s | uspeshno                                                                                                          |
| `[root]` finaljnaya proverka grafa Obsidian                             |       0,24 s | uspeshno                                                                                                          |
| `[root]` finaljnaya proverka rabochego nabora vetki                      |       0,42 s | uspeshno (`ready_count=1`, FUM-STEP-0008)                                                                         |
| `[root]` finaljnaya proverka planovogo reyestra                          |       0,21 s | uspeshno                                                                                                          |
| `[root]` finaljnaya proverka publikacionnogo diff                       |       0,03 s | uspeshno (`git diff --check`)                                                                                     |

Obsjheye vremya pryamyikh zapuskov proverok: 407,33 s.

Granica profilya: ot fenced-proverki naznacheniya posle FIFO-dopuska do finaljnoj proverki publikacionnogo diff; dliteljnosti nezavisimyikh paralleljnyikh auditov ne vklyuchenyi, a rannij polnyij progon s utrachennyim host-vyivodom otmechen kak neprofilirovannoye ogranicheniye sessii. Povtornaya materializaciya sluzhebnyikh recency-predstavlenij posle zapisi samogo profilya i kontroljnoye read-only podtverzhdeniye snimka vyipolnyayutsya za etoj granicej, chtobyi ne sozdavatj rekursivnuyu stroku izmereniya.

## Istochniki

- [iskhodnyij zapros o vyipolnenii FUM-STEP-0101](zapros.md)
- [yazyikonejtraljnyij kanonicheskij protokol pamyati](../../Dokumentaciya/47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:4f9a0cfe59b6e87c2dd76472a5d6a28df6908b87c436af0aa2655bcb8c11dfee -->
<!-- FUM-MD-RECENCY:END -->
