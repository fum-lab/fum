# Zhivoj progon odnogo odnoagentnogo epizoda 2026-08-01

Odin uzkij scenarij proshyol v sobstvennom runtime FUM ot dvukh realjnyikh model-only-vyizovov do razreshyonnogo lokaljnogo Git-dejstviya, izolirovannogo kandidatnogo kommita, nezavisimoj priyomki i yedinstvennogo terminaljnogo iskhoda `completed`. Harness dvazhdyi nablyudal zaraneye zaregistrirovannoye podtverzhdyonnoye pokoleniye, posyilal ostanovlennomu worker fakticheskij `SIGKILL`, a prodolzheniye vyipolnyali novyiye processyi bez prezhnego stdin, chata i skryityikh peremennyikh. Vozobnovleniye svyazyivalo polnyij execution-passport s SHA v `CURRENT`; pered Git-perekhodom otdeljnyij vneshnij artefakt podtverzhdeniya byil privyazan k pervomu checkpoint.

Rezuljtat otnositsya toljko k etomu sinteticheskomu scenariyu. On ne dokazyivayet gotovnostj universaljnogo ili raspredelyonnogo FUM, produktovogo runtime, proizvoljnogo nabora dejstvij, ustojchivostj k potere pitaniya libo preimusjhestvo nad kontroljnyim agentom.

## Pasport i modeljnyiye vyizovyi

Zhivoj execution-passport skhemyi `fum.live_single_agent_episode.execution_passport` versii `1` imeyet SHA-256 `sha256:68fec7d41fa64ddc937582a1fae347d656426ea3648816ad91cabe06422c67a0`. On razreshayet toljko sinteticheskiye dannyiye naznacheniya `single_agent_candidate_variant`, ne boleye `467` vkhodnyikh bajtov za vyizov i odno dejstviye `create_candidate_commit` cherez `fum-git-candidate-v1` klassa `isolated-git-write`. V pasporte perechislenyi proverki strogogo namereniya, sovpadeniya candidate plan i otdeljnoj priyomki, dva checkpoint i iskhodyi `completed`, `needs_input`, `budget_exhausted`, `failed`.

Provider ispoljzovalsya cherez uzhe ustanovlennyij lokaljnyij kontur bez skachivaniya vesov, novyikh sekretov, platnogo dostupa i poljzovateljskikh dannyikh:

| Pole       | Nablyudayemoye znacheniye                                 |
| ---------- | ---------------------------------------------------- |
| provider   | `lmstudio`                                           |
| interface  | `lmstudio.rest-api.v0.chat-completions`              |
| model      | `qwen/qwen3-0.6b`, lokaljnyij variant `Q8_0`          |
| runtime    | `llama.cpp-mac-arm64-apple-metal-advsimd@2.27.1`     |
| transport  | `lmstudio_live`; recorded transport ne ispoljzovalsya |
| disclosure | toljko zaraneye podgotovlennyiye sinteticheskiye stroki   |
| money      | `0` mikrodenezhnyikh yedinic                             |

Maksimaljnyij byudzhet raven dvum vyizovam, `512` vkhodnyim i `512` vyikhodnyim tokenam, `60 000` millisekundam i `60 000` compute units. Reservation odnogo vyizova raven `1 / 256 / 256 / 30 000 / 30 000 / 0` v poryadke `calls / input / output / wall-clock-ms / compute / money`. Tochnaya predvariteljnaya tokenizaciya byila zakreplena dlya oboikh vkhodov i sovpala s usage provider.

| Variant     | Input | Output | Wall-clock | Compute | Output SHA-256                                                            |
| ----------- | ----: | -----: | ---------: | ------: | ------------------------------------------------------------------------- |
| `variant-a` |   219 |    193 |   1 694 ms |   1 694 | `sha256:1d4c8988c1bf3deaea6c81168c6273b943199e76b1950b3884bd27ef4e210a9e` |
| `variant-b` |   214 |    188 |   1 459 ms |   1 459 | `sha256:8f36755113a3a026f2dcccd5570af7cbe88da89240806e9cac023fc3272c0fd8` |
| Itogo       |   433 |    381 |   3 153 ms |   3 153 | dva tochnyikh kanonicheskikh otveta                                            |

Tretij proposal `variant-c` byil nedostupen po konechnomu byudzhetu. Runtime sokhranil `budget_checkpoint_created` bez novogo request, transport-vyizova ili otveta; nezavisimyij audit harness potreboval `model_response_count = 2` i `budget_checkpoint_no_call = true`.

## Mezhprocessnyiye checkpoint i vozobnovleniye

Harness imel PID `58556`. Kazhdyij marker byil kanonicheski dekodirovan, neposredstvenno sveren s tekusjhimi generation/state SHA v `CURRENT` i s podtverzhdeniyem smyislovogo sobyitiya, posle chego harness poslal tochnomu ostanovlennomu PID `SIGKILL`.

| Stadiya                               | Worker PID | Generation SHA-256                                                        | State SHA-256                                                             | Iskhod processa |
| ------------------------------------ | ---------: | ------------------------------------------------------------------------- | ------------------------------------------------------------------------- | -------------- |
| vyibor i podtverzhdeniye pokoleniya      |      58614 | `sha256:44d0f19d5936bcab2572d563cfbe5b266422f47aec8220cdaa291e0595a1203f` | `sha256:9cee3999bb4c8ba10d10da9f5c855a195285907e561db2aad62e6f80a0e660f7` | `SIGKILL`      |
| nablyudeniye kandidata i podtverzhdeniye |      58639 | `sha256:0bab58a53377ac1b5476cf6c44f8cb2ffbb776f4da152c90190143e551192350` | `sha256:4fbce89d7020ccc9c072182de78af353951a2ae81d000f38142058aa4e9ab6a9` | `SIGKILL`      |
| otdeljnoye terminaljnoye prodolzheniye   |      58758 | `sha256:a5d4fd95339b600ec091f56ee9befb87473e2a39bc316e6fb69f61d3ca658af0` | `sha256:3a07de1297d467ecde86abb93483e59f7182f827bc056adba6f9b4954d105e7d` | `exit 0`       |

Posle pervogo ubijstva harness zapisal yedinstvennoye vidimoye vneshneye podtverzhdeniye s SHA-256 `sha256:9ba95558382836f28611bcf3a1d268650533f2f05560d721f081895a65ee13d4`. Ono svyazano s pervyim marker, yego worker PID, generation/state SHA i execution-passport SHA. Bez etogo fajla runtime zakryivayet perekhod do zapisi Git-effekta.

## Kandidat i otdeljnaya priyomka

Razreshyonnoye dejstviye sozdalo kandidat toljko v otdeljnom clone i otdeljnoj vetke. Iskhodnyij checkout sokhranil bazovyij `HEAD`, indeks, rabocheye derevo i refs; merge, rebase, push i avtomaticheskaya integraciya ne vyipolnyalisj.

| Obyyekt             | Znacheniye                                                                  |
| ------------------ | ------------------------------------------------------------------------- |
| parent commit      | `8c7ef0d85b6daae8fa9da249c0fe8932af2acd6e`                                |
| candidate tree     | `f7ba19785b4baa61770683c46cece0ec58e7d3a7`                                |
| candidate commit   | `27b70453870750f7504db957176aec88f90705ea`                                |
| candidate branch   | `refs/heads/fum-live-episode-candidate`                                   |
| result ref         | `refs/fum/candidates/fum-live-episode-candidate`                          |
| acceptance PID     | `58761`                                                                   |
| acceptance verdict | `accepted`                                                                |
| acceptance receipt | `sha256:b66db06cfb2eb09cf2747107b786a3db9c1638d183a71ebd8c0f58d7c9dd2f76` |

Priyomochnyij process poluchil toljko katalog epizoda i tochnyij candidate OID, zanovo prochital podtverzhdyonnyij kontrakt, proveril parent/tree/diff/checker i sokhranil otdeljnyij receipt. Terminaljnoye pokoleniye soderzhit `27` sobyitij i rovno odno `continuation_decided = completed`; SHA zhurnala sobyitij — `sha256:40190293152bfc3ea5af8053350fa9c646fbab37055c86a51b07cd682e1c2f67`.

## Vosproizvedeniye i otsutstviye effektov replay

Avtonomnyij recorded harness dvazhdyi proshyol iz novogo chistogo obsjhego predka s temi zhe dvumya fakticheskimi ubijstvami. Yego kanonicheskaya semanticheskaya proyekciya zakreplena SHA-256 `sha256:316f1189af9cd027fafbe87edba82a3799f67b691ea1dac54e1473ddfa42a9a1`; oba nezavisimyikh progona dali tochnyiye odinakovyiye bajtyi, nesmotrya na razlichnyiye PID i absolyutnyiye vremennyiye katalogi v syirom audite.

Zhivoj replay vyipolnili otdeljnyiye PID `58810` i `58812`. Oba vernuli odinakovyiye bajtyi proyekcii s SHA-256 `sha256:54ee25678c3608db8081d4682950884242a9fef656999422dc338c415dc5473a`. Khyesh vsego run-kataloga do i posle oboikh replay sovpal. Replay ne sozdayot model-, action-, Git- ili acceptance-adapteryi i ne zapisyivayet workspace; eto no-call chteniye, proverka podtverzhdyonnogo `CURRENT` i chistoye svyortyivaniye sokhranyonnoj trassyi.

Posle zhivogo progona tochnaya modelj byila vyigruzhena, lokaljnyij server ostanovlen, `lms server status --json` vernul `{"running":false,"port":1234}`, a `lms ps --json` — pustoj massiv. Eto vosstanovilo nablyudayemoye iskhodnoye sostoyaniye provider.

## Istochniki i opornyiye materialyi

- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../../../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [zavershyonnaya kartochka FUM-STEP-0112](../../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [kontrakt zhivogo odnoagentnogo epizoda](../../../Dokumentaciya/48-kontrakt-zhivogo-odnoagentnogo-epizoda.md)
- [pasport prototipa](../README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c073caf8bb90a47e7018d82616d2c09b9776e02b1d43d73ba101b66fa2198c0a -->
<!-- FUM-MD-RECENCY:END -->
