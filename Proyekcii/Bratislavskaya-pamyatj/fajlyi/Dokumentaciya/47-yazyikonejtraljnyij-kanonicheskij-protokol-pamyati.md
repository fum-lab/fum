# Yazyikonejtraljnyij kanonicheskij protokol pamyati

Kanonicheskiye sobyitiya i pokoleniya pamyati [FUM](../Glossarij/FUM.md) imeyut yedinstvennoye normativnoye bajtovoye predstavleniye. Profilj `fum.memory.canonical-json.v1` zadayot prikladnoye podmnozhestvo JSON Canonicalization Scheme: dlya kazhdogo dopustimogo znacheniya bajtyi sovpadayut s JCS, a domennyiye ogranicheniya isklyuchayut nenuzhnyiye variantyi chisel, `null` i Unicode-imena polej.

Profilj opredelyayet preimage dlya SHA-256 i identifikatorov pokolenij. Iskhodnaya transportnaya zapisj, poryadok klyuchej dekodera, `description`, `String.hashValue`, povedeniye Foundation i konechnyij perevod stroki CLI v preimage ne vkhodyat.

## Identichnostj i oblastj dejstviya

Identifikator profilya neizmenyayem: `fum.memory.canonical-json.v1`. Lyuboye izmeneniye pravil, sposobnoye izmenitj bajtyi ili mnozhestvo dopustimyikh znachenij, trebuyet novogo identifikatora i yavnoj politiki sovmestimosti.

Profilj primenyayetsya k obyyektam sobyitij, zapisej, seed, zhurnala, snimka, trassyi, modeli predstavleniya, vkladov raspredelyonnogo epizoda, celogo pokoleniya i ukazatelya `CURRENT`. Skhema domena dopolniteljno opredelyayet tochnyiye polya kazhdogo nositelya; bajtovyij profilj ne zamenyayet domennuyu validaciyu.

## Bajtovaya grammatika

| Aspekt            | Norma `fum.memory.canonical-json.v1`                                                                                                    |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Kodirovka         | Toljko strogo korrektnyij UTF-8 bez BOM, CESU-8 i zamenyi oshibochnyikh posledovateljnostej.                                                  |
| Korenj            | Rovno odin JSON-obyyekt.                                                                                                                 |
| Glubina           | Korenj imeyet glubinu `0`; glubina kazhdogo dochernego znacheniya na yedinicu boljshe. Maksimum — `128`.                                       |
| Probelyi           | Ne vyivodyatsya do, posle ili mezhdu tokenami.                                                                                              |
| Zaversheniye        | Posle konechnoj `}` net bajtov. `LF` ili `CRLF` zapresjhenyi. CLI mozhet dobavitj `LF` kak vneshnij framing, no ne khyeshiruyet yego.              |
| Obyyektyi           | Imena unikaljnyi posle raskryitiya JSON-escape. Dublikat otklonyayetsya do pomesjheniya v map.                                                   |
| Imena polej       | Toljko ASCII po shablonu `[a-z][a-z0-9_]*`.                                                                                              |
| Poryadok polej     | Vozrastaniye po bezznakovyim ASCII-bajtam imeni. V etom podmnozhestve rezuljtat tozhdestvenen JCS-poryadku po bezznakovyim UTF-16 code units. |
| Massivyi           | Sokhranyayut iskhodnyij poryadok elementov.                                                                                                   |
| Bulevyi znacheniya   | Toljko literalyi `true` i `false`.                                                                                                       |
| Celyiye chisla       | Toljko `0…9007199254740991`. Zapisj — `0` libo `[1-9][0-9]*`.                                                                           |
| Zapresjhyonnyiye chisla | Otricateljnyiye celyiye, `-0`, vedusjhij `+`, vedusjhiye nuli, drobi, eksponentyi, chisla vyishe `2^53−1`, `NaN`, ±`Infinity` i `BigInt`.            |
| `null`            | Zapresjhyon. Neobyazateljnoye pole otsutstvuyet; neaktivnyiye polya variantov `remember` i `compose` ne vyivodyatsya.                               |

Diapazon celyikh chisel vyibran iz garantirovanno tochnogo mezhyyazyikovogo diapazona I-JSON. Otricateljnyiye i drobnyiye chisla v tekusjhem domene pamyati ne ispoljzuyutsya: versii, poryadkovyiye nomera i limityi neotricateljnyi. Ikh zapret ne teryayet zakonnyikh znachenij i ne perenosit v protokol slozhnuyu semantiku ECMAScript-chisel.

## Stroki i Unicode

Stroka sokhranyayet tochnuyu posledovateljnostj Unicode scalar values. Profilj ne primenyayet NFC, NFD, NFKC ili NFKD: kompozicionno ekvivalentnyiye stroki ostayutsya raznyimi svideteljstvami i imeyut raznyiye bajtyi i SHA-256.

Odinochnyiye surrogatyi, nekorrektnyiye surrogatnyiye paryi i Unicode noncharacters `U+FDD0…U+FDEF`, `U+nFFFE`, `U+nFFFF`, gde `n` — nomer ploskosti ot `0` do `10₁₆`, zapresjhenyi. Korrektnyiye supplementary characters vyivodyatsya neposredstvenno v UTF-8, a ne paroj `\u`-escape.

Ekranirovaniye yedinstvenno:

- `U+0008`, `U+0009`, `U+000A`, `U+000C`, `U+000D` vyivodyatsya kak `\b`, `\t`, `\n`, `\f`, `\r`;
- ostaljnyiye `U+0000…U+001F` vyivodyatsya kak `\u00xx` s chetyirjmya strochnyimi hex-ciframi;
- `"` vyivoditsya kak `\"`, a `\` — kak `\\`;
- vsyo ostaljnoye vyivoditsya neposredstvenno, vklyuchaya `/`, `U+007F…U+009F`, `U+2028`, `U+2029`, kirillicu i emoji.

## Kanonicheskij priyomnik

Priyomnik avtoritetnyikh bajtov ne polagayetsya na myagkoye povedeniye obyichnogo JSON-dekodera. On:

1. Strogo razbirayet UTF-8 i JSON s sokhraneniyem chislovoj leksemyi i vozmozhnosti obnaruzhitj dublikat do svyortki obyyekta.
2. Proveryayet tipyi, diapazonyi, Unicode i imena polej profilya.
3. Povtorno serializuyet znacheniye po etomu dokumentu.
4. Trebuyet polnogo pobajtovogo ravenstva serializovannogo rezuljtata i vkhoda.
5. Toljko posle bajtovoj proverki peredayot dannyiye v tipizirovannuyu domennuyu validaciyu.

Poetomu korrektnyiye po RFC 8259, no nekanonicheskiye zapisi s probelami, drugim poryadkom klyuchej, `\/`, lishnim `\u`-escape, paroj escape-surrogatov dlya emoji i konechnyim perevodom stroki otklonyayutsya avtoritetnyim konturom.

## SHA-256 i domennyiye identifikatoryi

Tekstovaya forma SHA-256 ravna `sha256:` i rovno 64 strochnyim hex-cifram. Algoritm poluchayet toljko `canonicalBytes(value)` tochnogo nositelya:

| Pole ili identifikator                | Khyeshiruyemoye znacheniye                                                                                                      |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `source_event_sha256`                 | Polnoye kanonicheskoye telo odnogo prinyatogo sobyitiya.                                                                       |
| `output_record_sha256`                | Kanonicheskaya zapisj pamyati vmeste s proiskhozhdeniyem.                                                                      |
| `seed_sha256`                         | Kanonicheskij seed.                                                                                                       |
| `event_journal_sha256`                | Vesj kumulyativnyij zhurnal prinyatyikh sobyitij.                                                                               |
| `input_sha256`                        | Kanonicheskaya programma sobyitij tekusjhego perekhoda, a ne syiryiye transport bytes.                                            |
| `snapshot_sha256`                     | Kanonicheskij snimok.                                                                                                     |
| `trace_sha256`                        | Kanonicheskaya trassa.                                                                                                     |
| `view_model_sha256`                   | Kanonicheskaya modelj predstavleniya.                                                                                       |
| Adres pokoleniya (`generation_sha256`) | Polnoye kanonicheskoye pokoleniye; yego SHA-256 yavlyayetsya adresom fajla i znacheniyem `StoredMemoryGeneration.generationSHA256`. |

Prinyatyiye kanonizatorom zapisi odnoj programmyi sobyitij — naprimer, s drugim poryadkom polej, razreshyonnyimi probelami ili ekvivalentnyim escape — poluchayut odin `input_sha256`. Eto ustranyayet prezhneye raskhozhdeniye, pri kotorom odin putj khyeshiroval syiryiye vkhodnyiye bajtyi, a drugoj — povtorno zakodirovannuyu programmu.

## Versionirovaniye nositelej

Pokoleniye skhemyi `3` soderzhit obyazateljnoye `canonical_profile: "fum.memory.canonical-json.v1"`. Ukazatelj `CURRENT` skhemyi `2` soderzhit tot zhe identifikator i tochnyij SHA-256 pokoleniya. Vyikhodnoj artefakt prototipa takzhe ispoljzuyet skhemu `3` i yavno nazyivayet profilj.

Pokoleniya skhem `1` i `2` i ukazatelj skhemyi `1` ne migriruyutsya molcha. Novyij chitatelj otklonyayet ikh bez pereopredeleniya bajtov novyimi pravilami i ne perezapisyivayet khranilisjhe. Migrator staryikh pokolenij mozhet byitj dobavlen toljko kak otdeljnyij versionnyij perekhod.

## Skhemonezavisimoye adresnoye yadro pokolenij

Fajlovyij protokol pokoleniya realizovan odin raz v `ContentAddressedGenerationStore`. Yadro prinimayet uzhe kanonicheskiye bajtyi domennogo pokoleniya, tochnyij identifikator profilya, predel razmera i dva vnedryonnyikh validatora: polnoj skhemyi i svyazi s tekusjhim predkom. Ono ne znayet tipov `MemoryGeneration`, operacij `remember` i `compose` libo sobyitij zhivogo epizoda i poetomu ne podmenyayet domennuyu proverku obsjhim fajlovyim formatom.

Yadro vyichislyayet adres SHA-256 po tochnyim bajtam pokoleniya, publikuyet neizmenyayemyij fajl bez zamesjheniya, serializuyet compare-and-swap ukazatelya postoyannoj mezhprocessnoj blokirovkoj i podtverzhdayet novoye sostoyaniye toljko atomarnoj zamenoj `CURRENT.json`. Chteniye nachinayet isklyuchiteljno s `CURRENT`: ukazatelj, profilj, adres, khyesh fajla i domennaya skhema proveryayutsya do vozvrata pokoleniya. Podgotovlennyij fajl, proigravshij CAS, staging-khvost ili inoj adresuyemyij sirotskij obyyekt ne stanovitsya tekusjhim iz-za imeni, vremeni libo prisutstviya v `generations/`. Tochnyij povtor uzhe podtverzhdyonnyikh bajtov idempotenten; otlichayusjhijsya kandidat ot ustarevshego roditelya poluchayet konflikt, ne menyayusjhij `CURRENT`.

`MemoryGenerationStore` ostayotsya sovmestimyim adapterom etogo yadra: on kodiruyet i proveryayet prezhneye pokoleniye pamyati skhemyi `3`, vosproizvodit `remember` i `compose`, proveryayet liniyu proiskhozhdeniya i perevodit obsjhiye oshibki v prezhniye domennyiye tipyi. Poetomu vyideleniye yadra ne izmenyayet kanonicheskiye bajtyi pamyati, adresa pokolenij, ukazatelj skhemyi `2` i vosemj proveryayemyikh tochek avarijnoj finalizacii. Runtime zhivogo epizoda pereispoljzuyet tot zhe fajlovyij protokol so svoyej skhemoj pokoleniya i sobstvennyimi tipizirovannyimi sobyitiyami, ne maskiruya ikh pod operacii pamyati. [Obsjhaya pamyatj raspredelyonnogo epizoda](49-kontrakt-vosstanavlivayemoj-obsjhej-pamyati-raspredelyonnogo-epizoda.md) dobavlyayet yesjhyo odin domennyij adapter: on khranit pasport, artefaktyi, polnyij zhurnal razlichimyikh vkladov i vyivedennoye sostoyaniye, a pri publikacii trebuyet tochnyij prefiks i odno novoye sobyitiye.

## Realizacii i conformance

Produktovaya Swift-realizaciya ispoljzuyet sobstvennyiye bajtovyiye parser i writer. Kanonicheskij writer ne vyizyivayet `JSONEncoder`, `JSONSerialization`, formatter chisel ili `String(format:)`. SHA-256 vyichislyayetsya s pomosjhjyu CryptoKit nad uzhe gotovyimi bajtami profilya; strochnyij hex stroitsya pobajtovo. Foundation ostayotsya na granice `Data`, fajlovoj sistemyi, tipizirovannogo dekodirovaniya uzhe proverennyikh bajtov i neavtoritetnogo chteniya nomera prezhnej skhemyi pered yavnyim otkazom; ona ne opredelyayet kanonichnostj ili preimage. Tipizirovannaya programma dolzhna povtorno datj te zhe bajtyi sobstvennogo writer, inache vkhod otklonyayetsya, a `input_sha256` vyichislyayetsya neposredstvenno iz bajtov, poluchennyikh sobstvennyim parser do Foundation-dekodirovaniya.

Vtoraya realizaciya — uzkij avtonomnyij verifier na Python iz standartnoj biblioteki. On imeyet sobstvennyiye parser i writer, ispoljzuyet `hashlib` dlya SHA-256 i ne vyizyivayet `json.dumps` dlya bajtov profilya. On ne zamenyayet Swift-runtime: ne ispolnyayet `remember` i `compose`, ne stroit snimok i ne publikuyet `CURRENT`.

Obe realizacii chitayut odin neizmenyayemyij corpus. On soderzhit 12 polozhiteljnyikh vektorov, 38 otkazov i 2 izvestnyikh vektora SHA-256 — vsego 52 proverki. Polozhiteljnaya chastj zakreplyayet bulevyi znacheniya, granicyi celyikh, glubinyi i razmera `remember`, Unicode i escapes, razlichiye NFC/NFD, obyichnyiye `remember` i `compose`, polnuyu programmu, nachaljnoye i prodolzhennoye pokoleniya, `CURRENT` i tochnyiye SHA-256. Otkazyi pokryivayut prevyisheniye glubinyi, oshibochnyij UTF-8, oba klassa Unicode noncharacter, dublikatyi posle raskryitiya escape, zapresjhyonnyiye imena i znacheniya, a takzhe nekanonicheskiye sobyitiye i `CURRENT`.

V polozhiteljnom vektore `input_base64` mozhet byitj nekanonicheskim transportom, kotoryij obe realizacii privodyat k zakreplyonnomu `canonical_base64`. Vektor `mode: "noncanonical"` proveryayet strogij priyom: kanonizaciya vozmozhna, no iskhodnyiye bajtyi otklonyayutsya. `mode: "invalid"` trebuyet otkaza samoj kanonizacii.

Proveryayemyij avtonomnyij vyizov:

```bash
swift test \
  --package-path 'Прототипы/воспроизводимое-пополнение-памяти' \
  --filter CanonicalMemoryProtocolConformanceTests
```

Test Swift sam zapuskayet Python v isolated mode, sveryayet oba rezuljtata s odnim manifest i dopolniteljno dokazyivayet, chto Swift-runtime sam porozhdayet tochnyiye bajtyi oboikh pokolenij i `CURRENT`. Vyizov ne trebuyet seti, sekretov ili vneshnikh paketov.

## Granicyi garantii

Pobajtovoye sovpadeniye dvukh realizacij i golden vectors dokazyivayut perenosimostj konkretnogo profilya i nabora. Pereispoljzovaniye profilya i fajlovogo yadra live-epizodom ne yavlyayetsya otdeljnyim mezhyyazyikovyim corpus vsej live-skhemyi. Eti svideteljstva takzhe ne dokazyivayut bezoshibochnostj lyuboj budusjhej realizacii, istinnostj soderzhaniya, podlinnostj avtora, polnuyu durability khranilisjha ili perenos produktovoj semantiki FUM na Python.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-01 23:00:38 MSK — Dobavitj vosstanavlivayemuyu obsjhuyu pamyatj raspredelyonnogo epizoda](../Zhurnal/2026-08-01_23-00-38_MSK_dobavitj-vosstanavlivayemuyu-obsjhuyu-pamyatj-raspredelyonnogo-epizoda/zapros.md)
- [iskhodnyij zapros o podtverzhdyonnom khranilisjhe i bezokonnyikh interfejsakh epizoda](../Zhurnal/2026-08-01_11-56-54_MSK_realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda/zapros.md)
- [FUM-STEP-0110 — podtverzhdyonnoye khranilisjhe i bezokonnyiye interfejsyi epizoda](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0110-realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda.md)
- [iskhodnyij zapros o yazyikonejtraljnom kanonicheskom protokole pamyati](../Zhurnal/2026-07-28_08-47-18_MSK_zakrepitj-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati/zapros.md)
- [trebovaniye o vosproizvodimom shtatnom popolnenii pamyati](../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)

## Pervichnyiye tekhnicheskiye istochniki

- [RFC 8785, § 3 — JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785.html#section-3)
- [proverennaya errata 7920 k RFC 8785 ob otkaze dlya `-0`](https://www.rfc-editor.org/errata/eid7920)
- [RFC 8259, §§ 2, 4, 6—8 — JSON](https://www.rfc-editor.org/rfc/rfc8259.html)
- [RFC 7493, § 2 — I-JSON](https://www.rfc-editor.org/rfc/rfc7493.html#section-2)
- [RFC 3629, §§ 3—4 — UTF-8](https://www.rfc-editor.org/rfc/rfc3629.html#section-3)
- [ECMA-262 2019, JSON serialization](https://262.ecma-international.org/10.0/#sec-json.stringify)
- [Unicode Standard Annex #15 — Unicode Normalization Forms](https://www.unicode.org/reports/tr15/)
- [Unicode Standard — Noncharacters](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/#G7404)
- [NIST FIPS 180-4 — Secure Hash Standard](https://csrc.nist.gov/pubs/fips/180-4/upd1/final)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:365c9380497d4279b92c98c7a3a7c10fae4814b59d70881186c03b46e15f905c -->
<!-- FUM-MD-RECENCY:END -->
