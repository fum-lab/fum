+++
schema_version = 1
card_id = "FUM-STEP-0077"
status = "completed"
+++
# Dobavitj vosstanavlivayemuyu obsjhuyu pamyatj raspredelyonnogo epizoda

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Adaptirovatj proverennoye odnoagentnoye khranilisjhe k obsjhej pamyati raspredelyonnogo myisliteljnogo epizoda bez sozdaniya paralleljnogo formata. Kazhdyij novyij vklad dolzhen ssyilatjsya na podtverzhdyonnoye roditeljskoye pokoleniye i svoyo proiskhozhdeniye, a prodolzheniye v novom processe — vosproizvoditj prinyatoye sostoyaniye toljko iz kanonicheskikh sobyitij, artefaktov rabochego paketa i pasporta bez istorii prezhnego chata i povtornyikh modeljnyikh vyizovov.

## Rezuljtat

V `Прототипы/проверяемый-многоагентный-контур` dobavlen domennyij adapter obsjhej pamyati nad `CanonicalMemoryJSON` i `ContentAddressedGenerationStore`. Pustoye nachaljnoye pokoleniye vstraivayet validnyij pasport, rabochiye paketyi, manifestyi i iskhodnyiye artefaktyi. Kazhdyij preyemnik dobavlyayet rovno odin vklad s tochnyimi roditelem, roljyu, khyeshem soderzhaniya i ssyilkami na proiskhozhdeniye. Polnyij kumulyativnyij zhurnal povtorno vyivodit tochnoye prinyatoye sostoyaniye bez fiksturyi, chata i novogo vyizova modeli.

Validator proveryayet kanonicheskiye bajtyi, vnutrenniye khyeshi, tochnuyu svyazj pasportnyikh SHA s bajtami rabochikh paketov, vkhodnyikh manifestov i soderzhaniya vkladov, vnutrenniye identifikatoryi, proiskhozhdeniye i tochnyij prefiks zhurnala pod toj zhe mezhprocessnoj blokirovkoj. Ustarevshij roditelj, konflikt, povrezhdeniye i nepolnaya publikaciya zakryivayutsya otkazom. Tochnyij povtor idempotenten, a neizvestnyiye fajlyi ne udalyayutsya. Shestnadcatj avtonomnyikh testov pokryivayut otdeljnyiye CLI-processyi bez resource bundle pri replay, realjnuyu gonku dvukh xctest-processov, povrezhdeniye artefakta i pokoleniya, nepolnuyu publikaciyu, tochnyij povtor, tochnoye sostoyaniye prervannoj podgotovki, sokhraneniye neizvestnyikh fajlov, otricateljnyiye variantyi vklada i razlichimostj odinakovogo soderzhaniya.

Granica zakreplena yavno: eto lokaljnyij stend dlya sotrudnichayusjhikh processov, a ne raspredelyonnyij konsensus, gotovaya dolgovremennaya pamyatj ili polnyij raspredelyonnyij FUM. Avtorstvo i proiskhozhdeniye proveryayutsya strukturno, no ne autentificiruyutsya kriptograficheski; dokazana soglasovannostj posle avarii processa, a ne power-loss durability.

## Istochniki

- [iskhodnyij zapros 2026-08-01 23:00:38 MSK — Dobavitj vosstanavlivayemuyu obsjhuyu pamyatj raspredelyonnogo epizoda](../../Zhurnal/2026-08-01_23-00-38_MSK_dobavitj-vosstanavlivayemuyu-obsjhuyu-pamyatj-raspredelyonnogo-epizoda/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [trebovaniye o proveryayemom mnogoagentnom konture FUM](../../Trebovaniya/🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md)
- [FUM-STEP-0076 — pasport raspredelyonnogo myisliteljnogo epizoda](✅-FUM-STEP-0076-zakrepitj-pasport-raspredelyonnogo-myisliteljnogo-epizoda-FUM.md)
- [FUM-STEP-0112 — skvoznoj odnoagentnyij epizod](✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [vosstanavlivayemaya pamyatj pokolenij dokumentacionnogo prototipa](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3e54ea5333fa79ebd755d367846628336efee8760ed4da507962a6c5fecfcbed -->
<!-- FUM-MD-RECENCY:END -->
