+++
schema_version = 1
card_id = "FUM-STEP-0099"
status = "completed"
+++
# Dobavitj mezhprocessnyij CAS ukazatelya pamyati

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zamenitj neatomarnuyu paru «prochitatj `CURRENT` — pozdneye zapisatj `CURRENT`» linearizuyemoj mezhprocessnoj compare-and-swap-publikaciyej. Kazhdyij pretendent dolzhen zakreplyatj tochnogo ozhidayemogo roditelya, a proigravshij gonku poluchatj tipizirovannyij konflikt bez perezapisi uzhe prinyatogo pokoleniya.

## Rezuljtat

`MemoryGenerationStore` podgotavlivayet kanonicheskij adresuyemyij obyyekt, a resheniye o publikacii prinimayet pod eksklyuzivnoj POSIX record lock postoyannogo `CURRENT.lock`. Pod blokirovkoj khranilisjhe zanovo chitayet i polnostjyu proveryayet `CURRENT`: tochnoye sovpadeniye celevogo khyesha dayot idempotentnyij uspekh, sovpadeniye s ozhidayemyim roditelem razreshayet atomarnuyu zamenu ukazatelya, a inoj podtverzhdyonnyij khyesh vozvrasjhayet tipizirovannyij `generationConflict`.

Avtonomnyij test sinkhroniziruyet dva realjnyikh dochernikh processa s raznyimi validnyimi kandidatami ot odnogo roditelya. Rovno odin process publikuyet pokoleniye, vtoroj poluchayet konflikt, oba tochnyikh adresuyemyikh obyyekta sokhranyayutsya, a povtor pobeditelya i povtor proigravshego ne menyayut `CURRENT`. Dopolniteljnyij processnyij scenarij uderzhivayet `CURRENT.lock` v roditele i podtverzhdayet, chto dochernij pisatelj ne prokhodit tochku resheniya do osvobozhdeniya blokirovki.

Garantiya ogranichena sotrudnichayusjhimi processami na lokaljnoj fajlovoj sisteme s POSIX record locks i atomarnoj zamenoj fajla. Vnutriprocessnaya mnogopotochnostj, obkhodyasjhiye protokol pisateli, setevyiye fajlovyiye sistemyi, avarijnaya soglasovannostj i sokhrannostj pri potere pitaniya ostayutsya za granicej rezuljtata.

## Istochniki

- [iskhodnyij zapros o mezhprocessnom CAS ukazatelya pamyati](../../Zhurnal/2026-07-28_00-54-15_MSK_dobavitj-mezhprocessnyij-CAS-ukazatelya-pamyati/zapros.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [FUM-STEP-0098 — samodostatochnyij sobyitijnyij replay](✅-FUM-STEP-0098-sokhranitj-kanonicheskiye-sobyitiya-i-dokazatj-vosproizvedeniye.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f3b97a608e05bc3e8739412f501a1033e04de1fcdfdb4d86aca83ef0ecaef8b8 -->
<!-- FUM-MD-RECENCY:END -->
