# Otchyot 2026-07-28 07:49:45 MSK - Dobavitj avarijnuyu soglasovannostj khranilisjha pamyati

Fajlovoye khranilisjhe pokolenij pamyati teperj imeyet proverennyij poryadok staging, sinkhronizacii i publikacii. Posle prinuditeljnoj ostanovki pisatelya novyij process prinimayet toljko prezhneye podtverzhdyonnoye sostoyaniye libo polnostjyu zapisannoye i proveryayemoye novoye pokoleniye; nepodtverzhdyonnyiye sirotyi ne uchastvuyut v vosstanovlenii.

## Rezuljtat

`MemoryGenerationStore` polnostjyu zapisyivayet kanonicheskiye bajtyi pokoleniya v unikaljnoye vremennoye imya, sinkhroniziruyet otkryityij fajl cherez `fsync`, publikuyet tot zhe inode bez zamesjheniya cherez `link(2)`, udalyayet staging-imya i sinkhroniziruyet katalog `generations/`. Uzhe susjhestvuyusjheye adresuyemoye imya prinimayetsya toljko pri tochnom pobajtovom sovpadenii i posle sobstvennoj sinkhronizacii fajla. Eta vetvj proverena odnovremennoj publikaciyej odnogo SHA dvumya realjnyimi processami.

Posle podgotovki pokoleniya postoyannyij `CURRENT.lock` sokhranyayet mezhprocessnuyu CAS-sekciyu. Pod blokirovkoj khranilisjhe povtorno chitayet podtverzhdyonnoye sostoyaniye i toljko pri dopustimom roditele polnostjyu zapisyivayet i sinkhroniziruyet vremennyij ukazatelj, atomarno zamenyayet `CURRENT.json` cherez `rename(2)` i sinkhroniziruyet kornevoj katalog. Shtatnyij uspekh vozvrasjhayetsya posle poslednego `fsync`. Yesli oshibka nablyudayetsya uzhe posle zamenyi ukazatelya, iskhod chestno schitayetsya neodnoznachnyim; povtornoye chteniye opredelyayet fakticheskij `CURRENT`, a idempotentnyij povtor zavershayet kornevuyu sinkhronizaciyu.

Vosstanovleniye ne skaniruyet `generations/`, ne vyibirayet fajl po imeni, vremeni ili predpolagayemoj novizne i ne povyishayet sirotskij obyyekt. Otsutstvuyusjhij `CURRENT` oznachayet pustoye podtverzhdyonnoye sostoyaniye; povrezhdyonnyij ukazatelj libo svyazannoye pokoleniye dayut yavnyij otkaz. Process-crash-harness dvazhdyi prokhodit vosemj tochek protokola: dlya pervoj fiksacii iz pustogo khranilisjha i dlya zamenyi susjhestvuyusjhego `CURRENT`. Na kazhdoj tochke otdeljnyij writer-process ostanavlivayetsya, roditelj podtverzhdayet checkpoint, posyilayet `SIGKILL`, proveryayet zaversheniye imenno etim signalom i zapuskayet otdeljnyij recovery-process.

Dokumentaciya razdelyayet tri urovnya. Logicheskaya atomarnostj linearizuyet sotrudnichayusjhikh pisatelej; process-crash consistency dokazana opisannyim lokaljnyim macOS-scenariyem; power-loss durability ne dokazana. Obyichnyij `fsync` fiksiruyet poryadok zaprosov k OS, no `SIGKILL` ne vosproizvodit sboj yadra, kontrollera, nositelya ili kyesha, poetomu realjnaya sokhrannostj pri otklyuchenii pitaniya trebuyet otdeljnogo stenda i power-cut-ispyitaniya.

Kartochka FUM-STEP-0100 zavershena. V rabochem nabore sokhranena nezavisimaya FUM-STEP-0008, a FUM-STEP-0101 o yazyikonejtraljnom kanonicheskom protokole pamyati stala sleduyusjhim tekhnicheskim kandidatom `ready`. Trebovaniye o vosproizvodimom popolnenii ostayotsya `🚧`: yesjhyo otsutstvuyut zhurnal otklonyonnyikh kandidatov, dokazateljstvo power-loss durability, yazyikonejtraljnyij profilj i podderzhka prezhnej skhemyi pokoleniya.

## Proverki

Krasnyij test prezhnej realizacii ne skompilirovalsya bez avarijnogo checkpoint-kontrakta. Posle realizacii celevyiye progonyi podtverdili obe raznovidnosti fiksacii na vsekh vosjmi tochkakh, idempotentnyij povtor posle neodnoznachnoj oshibki i konkurentnuyu vetvj `EEXIST`. Itogovyij avtonomnyij Swift-nabor vyipolnil 29 testov bez otkazov; strogaya sborka s `strict-concurrency=complete` i preduprezhdeniyami kak oshibkami, Swift Format lint, vetochnyij nabor i planovyij reyestr proshli. Polnyij avtonomnyij smoke-check povtorno proveril vse SwiftPM-paketyi, lokaljnyiye avtomatizacii, reyestryi, publikacionnuyu chistotu, ssyilki, recency i svyaznostj rabochej sessii: projden 61 shag iz 61.

## Profilj vremeni vyipolneniya

| Stadiya                                      | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                             |
| ------------------------------------------- | -----------: | -------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i ozhidaniye FIFO                 |       0,40 s | Wall time yedinstvennogo `join`; sostoyaniye `admitted` polucheno srazu, perioda `waiting` ne byilo.                                        |
| Soderzhateljnaya rabota do itogovyikh proverok  |  ne izmereno | Ot FIFO-dopuska do finaljnogo proverochnogo kontura; razrabotka testov, audit dokumentacii i kriticheskoye revjyu chastichno shli paralleljno. |
| Celevyiye i sluzhebnyiye proverki do smoke-check |  ne izmereno | Vse pryamyiye processyi, vklyuchaya krasnyiye progonyi, diagnostiku, pereimenovaniye i povtornyiye proverki, perechislenyi nizhe.                     |
| Polnyij smoke-check                          |     279,47 s | Vneshnij `/usr/bin/time`; vse 61 shaga proshli, vnutrenneye monotonnoye vremya runner — 279,417 s.                                           |

### Pryamyiye zapuski proverok

| Vyizov                                                                 | Dliteljnostj | Rezuljtat                                                                                                        |
| --------------------------------------------------------------------- | -----------: | ---------------------------------------------------------------------------------------------------------------- |
| `[root]` fenced `show` naznachennoj kartochki                           |       0,90 s | uspeshno (vetka, pokoleniye vyibora, kartochka i yeyo khyesh sovpali)                                                     |
| `[root]` proverka podderzhki `fsync` kataloga                          |       0,10 s | uspeshno na tekusjhem lokaljnom macOS-stende                                                                       |
| `[crash_tests]` krasnyij crash-checkpoint-test                         |       3,98 s | neuspeshno ozhidayemo (v production otsutstvoval `MemoryGenerationCommitCheckpoint`)                               |
| `[root]` pervaya zelyonaya popyitka crash-testa                           |       5,57 s | neuspeshno (dochernij pisatelj ne dostig checkpoint)                                                              |
| `[root]` diagnosticheskij povtor crash-testa                           |       3,77 s | neuspeshno (vyiyavlena oshibochnaya povtornaya podgotovka susjhestvuyusjhego kataloga)                                       |
| `[root]` pervyij zelyonyij crash-test                                    |       7,32 s | uspeshno (vosemj checkpoint pri zamene susjhestvuyusjhego `CURRENT`)                                                  |
| `[root]` pervyij polnyij Swift-nabor                                    |       7,53 s | uspeshno (27/27)                                                                                                 |
| `[crash_protocol_review]` nezavisimyij povtor crash-testa              |       6,32 s | uspeshno                                                                                                         |
| `[root]` krasnyij test povtora posle publikacii `CURRENT`              |       3,33 s | neuspeshno ozhidayemo (idempotentnyij putj ne zavershal kornevuyu sinkhronizaciyu)                                       |
| `[root]` zelyonyij test povtora posle publikacii `CURRENT`              |       2,59 s | uspeshno (povtor zavershayet `root-directory-synchronized`)                                                        |
| `[root]` rasshirennyij crash-test                                       |       9,74 s | uspeshno (vosemj checkpoint dlya pervoj fiksacii i zamenyi)                                                        |
| `[root]` konkurentnaya publikaciya odinakovogo pokoleniya               |       1,77 s | uspeshno (dva processa idempotentno podtverdili odin SHA)                                                        |
| `[root]` pervyij vetochnyij `validate` posle kaskada ssyilki              |       0,47 s | neuspeshno ozhidayemo (obnaruzhen izmenivshijsya khyesh kartochki FUM-STEP-0101)                                           |
| `[root]` pervaya popyitka pereimenovaniya kartochki                       |       0,34 s | neuspeshno ozhidayemo (zhivaya ssyilka na prezhnij putj ostavalasj v selektore)                                        |
| `[root]` povtornoye pereimenovaniye kartochki                            |       0,32 s | uspeshno (status `completed` i kaskad zhivyikh ssyilok)                                                              |
| `[root]` mekhanicheskoye Swift-formatirovaniye                            |       0,22 s | uspeshno                                                                                                         |
| `[root]` itogovyij polnyij Swift-nabor                                  |      12,37 s | uspeshno (29/29, vklyuchaya 16 crash-scenariyev i dve gonki publikacii)                                              |
| `[root]` strogaya Swift-sborka                                         |       2,16 s | uspeshno (`strict-concurrency=complete`, preduprezhdeniya kak oshibki)                                              |
| `[root]` strogij Swift Format lint                                    |       0,29 s | uspeshno                                                                                                         |
| `[root]` peresborka planovogo reyestra                                 |       0,24 s | uspeshno                                                                                                         |
| `[root]` itogovaya proverka rabochego nabora vetki                      |       0,50 s | uspeshno (`ready_count=2`, FUM-STEP-0101 i FUM-STEP-0008)                                                        |
| `[root]` itogovaya proverka planovogo reyestra                          |       0,26 s | uspeshno                                                                                                         |
| `[root]` povtornaya peresborka reyestra posle utochneniya kartochki        |       0,24 s | uspeshno                                                                                                         |
| `[root]` proverka publikacionnogo remote                              |       0,07 s | uspeshno (yedinstvennyij credential-free HTTPS push URL bez primenimogo rewrite)                                  |
| `[root]` predvariteljnyij `git diff --check`                           |       0,10 s | uspeshno                                                                                                         |
| `[root]` materializaciya Markdown-recency                              |       0,49 s | uspeshno (obnovlenyi 17 soderzhateljno izmenyonnyikh Markdown-fajlov i indeks)                                        |
| `[root]` materializaciya teplovoj kartyi Obsidian                       |       0,29 s | uspeshno                                                                                                         |
| `[root]` predvariteljnaya proverka svyaznosti rabochej sessii            |      12,85 s | uspeshno                                                                                                         |
| `[root]` polnyij smoke-check                                           |     279,47 s | uspeshno (61/61; vnutrenneye monotonnoye vremya runner — 279,417 s)                                                 |
| `[root]` itogovaya proverka svyaznosti rabochej sessii                   |      12,90 s | uspeshno                                                                                                         |
| `[root]` itogovaya proverka recency-metok Markdown                     |       0,50 s | uspeshno                                                                                                         |
| `[root]` itogovaya proverka teplovoj kartyi Obsidian                    |       0,33 s | uspeshno                                                                                                         |
| `[root]` povtornaya proverka rabochego nabora vetki                     |       0,56 s | uspeshno (`ready_count=2`)                                                                                       |
| `[root]` povtornaya proverka planovogo reyestra                         |       0,30 s | uspeshno                                                                                                         |
| `[root]` itogovyij `git diff --check`                                  |       0,04 s | uspeshno                                                                                                         |

Obsjheye vremya pryamyikh zapuskov proverok: 378,23 s.

Granica profilya: ot yedinstvennogo FIFO-`join` do uspeshnogo zaversheniya polnogo smoke-check. Vlozhennyiye shagi yedinogo runner ne dubliruyutsya kak pryamyiye vyizovyi, a dliteljnosti paralleljnyikh read-only-auditov ne skladyivayutsya s kalendarnyim vremenem. Posle etoj granicyi sluzhebnyiye generatoryi i svyaznostj zamyikayut itogovuyu zapisj otchyota bez rekursivnogo polnogo povtora.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [kartochka FUM-STEP-0100](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0100-dobavitj-avarijnuyu-soglasovannostj-khranilisjha-pamyati.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [Swift-prototip vosproizvodimogo popolneniya pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e50e3df63b2206aa2467d121fbe7acbd05415b6a7f9c7e29b09e2be0bafe19a0 -->
<!-- FUM-MD-RECENCY:END -->
