+++
schema_version = 1
card_id = "FUM-STEP-0110"
status = "completed"
+++
# Realizovatj podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj SwiftPM-paket core-target FUM-STEP-0109 bezokonnyim runtime odnoagentnogo epizoda, pereispoljzuyusjhim paketyi chistogo modeljnogo shaga i vosproizvodimoj pamyati. Dlya etogo vyidelitj iz `MemoryGenerationStore` skhemonezavisimoye content-addressed yadro pokolenij s prezhnimi CAS- i crash-garantiyami, sokhraniv obratnuyu sovmestimostj pamyati. Runtime dolzhen khranitj sobstvennyiye tipizirovannyiye sobyitiya, a ne maskirovatj ikh pod `remember` i `compose`, i predostavlyatj versionnyiye komandyi sozdaniya, osmotra, statusa, prodolzheniya i vosproizvedeniya toljko iz podtverzhdyonnogo pokoleniya.

## Rezuljtat

Iz `MemoryGenerationStore` vyideleno odno skhemonezavisimoye `ContentAddressedGenerationStore`, kotoroye prinimayet kanonicheskiye bajtyi i domennyiye validatoryi i yedinozhdyi realizuyet neizmenyayemyiye SHA-256-fajlyi pokolenij, postoyannuyu mezhprocessnuyu blokirovku, compare-and-swap ukazatelya `CURRENT`, staging, sinkhronizaciyu i vosemj nablyudayemyikh crash-tochek. Tonkij adapter pamyati sokhranil prezhniye skhemu, oshibki, kanonicheskiye bajtyi i Swift↔Python-profilj.

Paket zhivogo epizoda ispoljzuyet toljko razreshyonnyiye tochnyiye lokaljnyiye zavisimosti ot vosproizvodimoj pamyati i chistogo modeljnogo shaga. Sobstvennaya skhema pokoleniya khranit neizmenyayemyij pasport, tipizirovannyij zhurnal live-sobyitij, khyeshi kanonicheskikh obyyektov, vosproizvodimoye sostoyaniye i hash-only invocation-receipts bez dublirovaniya syirogo modeljnogo vvoda. Podgotovlennyiye, povrezhdyonnyiye, konfliktuyusjhiye i proigravshiye CAS obyyektyi ne stanovyatsya tekusjhimi; novyij process nachinayet toljko s polnostjyu proverennogo `CURRENT`.

Versionnyiye JSON-komandyi `create`, `inspect`, `status`, `resume` i `replay` rabotayut bez GUI i prezhnego chata. Pered provider-vvodom-vyivodom runtime podtverzhdayet tochnyij model request i reservation otdeljnyim pokoleniyem; nezavershyonnyij vyizov ne povtoryayetsya avtomaticheski, a vernuvshiyesya tajm-aut ili neizvestnyij usage konservativno spisyivayut polnyij reservation rovno odin raz. Publichnyij kontrakt adaptera, provider identity, input hash, vse budusjhiye identifikatoryi i byudzhet proveryayutsya do zapisi i vyizova.

Avtonomnyiye testyi podtverzhdayut uspeshnyij i byudzhetno nedostupnyij puti, tochnyiye povtoryi, ustarevshij CAS, povrezhdeniye ukazatelya i pokoleniya, strogiye versii i polya JSON, vosstanovleniye pasporta, byudzheta, perekhoda, variantov, vyibora i terminaljnogo iskhoda, no-call replay i realjnyij `SIGSTOP`→`SIGKILL` posle podtverzhdyonnogo checkpoint. Novyij PID poluchayet toljko katalog epizoda, vidit nereshyonnyij reservation i ne povtoryayet provider-vyizov. Stend po-prezhnemu ogranichen odnim lokaljnyim epizodom bez Git-kandidata i otdeljnoj zhivoj priyomki.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-08-01_11-56-54_MSK_realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master i poetapnoye podtverzhdeniye](../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [FUM-STEP-0109 — skhema sobyitij zhivogo epizoda](✅-FUM-STEP-0109-vvesti-skhemu-sobyitij-zhivogo-odnoagentnogo-epizoda.md)
- [FUM-STEP-0101 — yazyikonejtraljnyij protokol pamyati](✅-FUM-STEP-0101-zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- [vosproizvodimoye popolneniye pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)
- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:83dee957bb11b1f76d88c45214521cfbb1fb60004797f3114862d95d379c8033 -->
<!-- FUM-MD-RECENCY:END -->
