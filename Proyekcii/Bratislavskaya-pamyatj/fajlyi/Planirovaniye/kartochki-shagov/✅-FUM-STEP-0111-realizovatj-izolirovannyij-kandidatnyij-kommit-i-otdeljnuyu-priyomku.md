+++
schema_version = 1
card_id = "FUM-STEP-0111"
status = "completed"
+++
# Realizovatj izolirovannyij kandidatnyij kommit i otdeljnuyu priyomku

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj k odnoagentnomu runtime uzkij Git-adapter, kotoryij po yavno podtverzhdyonnomu namereniyu sozdayot kandidatnyij kommit v izolirovannoj rabochej kopii i otdeljnoj vetke, no nikogda ne integriruyet yego avtomaticheski. Nezavisimyij proveryayusjhij process dolzhen prinyatj ili otklonitj tochnyij kandidat po sokhranyonnyim kriteriyam i nablyudeniyam.

## Pochemu sejchas

Khranilisjhe i bezokonnyiye interfejsyi dolzhnyi snachala dokazatj chistoye vozobnovleniye. Posle etogo kandidatnyij Git-effekt mozhno otdelitj ot modeljnogo vyibora i proveritj, chto ni tekst modeli, ni vnutrennij otbor ne podmenyayut poljzovateljskoye podtverzhdeniye, polnomochiya, preflight, nablyudeniye ili priyomku.

## Kriterii zaversheniya

- Allowlist soderzhit odno tochnoye dejstviye `create_candidate_commit` s ogranichennyimi putyami, zaregistrirovannyimi checker ID i fiksirovannoj argv-grammatikoj bez shell, bazovyim commit object i vetkoj-kandidatom; modeljnyij tekst ostayotsya nedoverennyim vkhodom.
- `transition_user_confirmed`, `authorized`, `preflight_passed`, `executed` i `observed` voznikayut toljko iz nezavisimyikh svideteljstv s odinakovyimi `(episode_id, transition_id, schema_version, object_id, expected_effect_sha256)` v zadannom poryadke; otsutstviye, perestanovka ili cross-transition-podmena lyubogo svideteljstva zakryivayet dejstviye otkazom.
- Otdeljnyij lokaljnyij clone s sobstvennyim Git-katalogom sozdayotsya iz tochnogo bazovogo kommita vne poljzovateljskogo checkout, a kandidat — v otdeljnoj vetke; osnovnoj ref, indeks, rabocheye derevo i Git-metadannyiye iskhodnogo repozitoriya ne izmenyayutsya.
- Pasport zakreplyayet determinirovannyiye tree, parent, author/committer, timestamp, message, branch i result ref. Publikaciya result ref ispoljzuyet CAS; posle crash tochnyij susjhestvuyusjhij OID vosstanavlivayetsya idempotentno, a inoj OID zakryivayet prodolzheniye.
- Versionnyij JSON-interfejs otdeljnogo headless-processa priyomki poluchayet toljko katalog epizoda i tochnyij candidate OID, zagruzhayet pasport i dopusk iz podtverzhdyonnogo `CURRENT`, nezavisimo perechityivayet parent/tree/diff, povtorno zapuskayet zaregistrirovannyiye proverki i sokhranyayet tipizirovannoye prinyatiye ili otkloneniye bez merge, rebase, push i izmeneniya osnovnoj vetki.
- Avtonomnaya Git-fikstura pokryivayet uspekh, absolyutnyij putj, traversal, symlink escape, neozhidannyij diff, izmenivshuyusya bazu, proval proverki, cross-transition- i lozhnoye modeljnoye podtverzhdeniye, crash do receipt, povtor i otkaz priyomki; vse vremennyiye repozitorii sozdayutsya lokaljno i udalyayutsya posle testa.

## Rezuljtat

V live-kontrakt dobavleno yedinstvennoye razreshyonnoye dejstviye `create_candidate_commit`: ono zakreplyayet bezopasnyiye otnositeljnyiye puti, zakryituyu registraciyu checker ID s tochnyim otobrazheniyem v argv-grammatiku i realizaciyu bez shell, bazovyij commit object, otdeljnyiye candidate/result refs i determinirovannyiye metadannyiye kommita. Pyatj svideteljstv imeyut obsjhiye koordinatyi, raznyiye doverennyiye producer ID, khyeshirovannuyu svyazj s predshestvennikom i strogij poryadok; obsjhij interfejs dobavleniya sobyitij ne mozhet ikh poddelatj. Nachinaya s preflight zhurnal neizmenyayemo svyazyivayet SHA-256 komandyi s zadannyim yeyu ID podtverzhdeniya observation.

Runtime sozdayot otdeljnyij lokaljnyij clone s sobstvennyim Git-katalogom vne iskhodnogo checkout, do zapisi proveryayet ownership marker, kanonicheskuyu config i descriptor-safe `objects`/`refs`, stroit tochnyij tree i commit, publikuyet pryamoj result ref cherez compare-and-swap i sokhranyayet neizmenyayemyij pasport. Tochnyij susjhestvuyusjhij OID i rovno odin sobstvennyij same-inode temp-alias pasporta s tochnyimi bajtami vosstanavlivayutsya posle obryiva, a symbolic ili inoj OID, chuzhoj ili neodnoznachnyij alias, izmenivshayasya baza, neozhidannyij diff, metadata-alias, nebezopasnyij putj ili proval checker zakryivayut prodolzheniye. Iskhodnyiye ref, indeks, rabocheye derevo i Git-metadannyiye ostayutsya neizmennyimi.

Otdeljnyij headless-process priyomki poluchayet toljko katalog epizoda i tochnyij candidate OID, neblokiruyusjhe i descriptor-relative proveryayet podtverzhdyonnyij `CURRENT`, tochnoye pokoleniye i pasport, polnuyu cepochku svideteljstv i tochnuyu neposredstvennuyu paru observation/podtverzhdeniye s zakreplyonnyim ID i dajdzhestom predyidusjhego pokoleniya, parent, tree, diff, modes, blobs, direct refs, vsyo clone metadata i zaregistrirovannyiye proverki. On povtoryayet proverku izolyacii posle Git-nablyudeniya, trebuyet yedinstvennyij stabiljnyij inode pasporta i atomarno publikuyet tipizirovannoye prinyatiye ili otkloneniye no-replace rename bez hardlink-okna, no ne vyipolnyayet merge, rebase, push i ne izmenyayet osnovnuyu vetku. Avtonomnyiye 19 core- i 53 runtime-testa pokryivayut polozhiteljnyij putj, vse trebuyemyiye podmenyi, crash/retry, FIFO/hardlink/symlink, hostile Git config, otkaz priyomki i udaleniye vremennyikh repozitoriyev.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-08-01_14-29-41_MSK_realizovatj-izolirovannyij-kandidatnyij-kommit-i-otdeljnuyu-priyomku/zapros.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master i poetapnoye podtverzhdeniye](../../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [FUM-STEP-0110 — podtverzhdyonnoye khranilisjhe i interfejsyi](✅-FUM-STEP-0110-realizovatj-podtverzhdyonnoye-khranilisjhe-i-bezokonnyiye-interfejsyi-epizoda.md)
- [karta ogranichitelej fizicheskogo dejstviya FUM](../../Dokumentaciya/40-karta-ogranichitelej-fizicheskogo-dejstviya-FUM.md)
- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ab45c48ca31764ed4d1ccb074bd2497445b57992507c20b7c684ff40b827a534 -->
<!-- FUM-MD-RECENCY:END -->
