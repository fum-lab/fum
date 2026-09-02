# Shtatnyij sbros FIFO-ocheredi i rabochej kopii

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0039 -->

Ekspluatacionnyij status: otlozheno vmeste s FIFO-runtime. Kartochka sokhranyayet bezopasnyij proyekt sbrosa istoricheskogo kontura, no obyichnaya ruchnaya sessiya yego ne vyizyivayet i ne poluchayet cherez nego prav na ochistku checkout, index ili refs.

Otdeljnaya yavno upolnomochennaya kornevaya zadacha vosstanovleniya dolzhna umetj vernutj FIFO-ocheredj i rabochuyu kopiyu k poslednemu zafiksirovannomu v tekusjhej lokaljnoj imenovannoj Git-vetke neprotivorechivomu sostoyaniyu. Etot khod ne yavlyayetsya prodolzheniyem vetki, prioritetom ili TTL i ne razreshayet proizvoljno obojti ocheredj: do udaleniya dannyikh on zakreplyayet fizicheskij checkout, polnyij ref, tochnyij `HEAD`, obyyekt ocheredi i vse zatragivayemyiye runtime-ssyilki, zakryivayet novyiye perekhodyi ograzhdeniyem i poluchayet avtoritetnoye podtverzhdeniye ostanovki vozmozhnyikh pisatelej.

Read-only-plan khranit tochnyiye preimage i target kazhdogo izmenyayemogo tracked-puti. Izmenyonnaya checkout-politika, skryityiye flagi indeksa, vneshnij filter, specialjnyij untracked-obyyekt, vlozhennaya Git-granica, gryaznyij submodule ili pozdnij drift zakryivayut operaciyu do razrushiteljnogo shaga. Posle dokazannoj ostanovki pisatelej sbros vosstanavlivayet indeks i otslezhivayemyiye fajlyi iz zakreplyonnogo `HEAD`, udalyayet toljko podtverzhdyonnyiye Git-vidimyiye neignoriruyemyiye obyichnyiye fajlyi i simvolicheskiye ssyilki i sokhranyayet ignoriruyemyiye dannyiye.

Do terminaljnoj Git-tranzakcii vosstanovleniye khranit vozobnovlyayemyij reset-record. Samodostatochnaya neizmenyayemaya kvitanciya poyavlyayetsya atomarno toljko vmeste s pustoj ocheredjyu novogo pokoleniya, kotoroye annuliruyet prezhniye biletyi, vladeniye i dopuski. Istoricheskiye refs dispetchera, rezervacij i claim mogut ochisjhatjsya lishj kak yavno perechislennaya chastj snimka snyatoj realizacii; oni ne stanovyatsya novyim dejstvuyusjhim konturom. Uspekh sbrosa ne sozdayot sessiyu-prodolzheniye, ne obrasjhayetsya k remote i ne publikuyet vetku.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [podtverzhdayemyim ruchnyim sbrosom FIFO k tekusjhemu HEAD](✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md) — otdeljnyij chelovecheskij `break-glass` annuliruyet lokaljnyiye runtime-polnomochiya bez zayavleniya o host-stop i ne oslablyayet etot bezopasnyij marshrut.

## Kriterii proverki

- sbros nachinayetsya toljko po otdeljnomu yavnomu poljzovateljskomu namereniyu, iz specialjno dopusjhennogo vosstanoviteljnogo khoda i po tochnomu podtverzhdyonnomu planu;
- plan zakreplyayet fizicheskij checkout, polnyij ref imenovannoj lokaljnoj vetki, tochnyij `HEAD`, obyyekt FIFO, vse zatragivayemyiye runtime-ssyilki i tochnyiye preimage/target kazhdogo izmenyayemogo tracked-puti;
- pervaya compare-and-swap-operaciya ustanavlivayet reset-fence, posle chego obyichnyiye `join`, dopusk, peredacha, zaversheniye i sozdaniye prodolzheniya dlya toj zhe oblasti zakryivayutsya do terminaljnogo iskhoda;
- aktivnaya ili neodnoznachnaya sessiya vozmozhnogo pisatelya blokiruyet podgotovku; dostupnyij prosmotr zadach i peredacha prodolzheniya ne zamenyayut proveryayemyij host-stop;
- sboj ili povtor idempotentno prodolzhayet tot zhe reset-record libo bezopasno otkazyivayet, a final atomarno sozdayot pustuyu ocheredj novogo pokoleniya i samodostatochnuyu kvitanciyu;
- avtonomnyiye testyi pokryivayut gonki s FIFO i prodolzheniyem, SHA-1 i SHA-256, gryaznyij indeks i derevo, specialjnyiye i vlozhennyiye obyyektyi, drift, kvitanciyu, Git GC i preryivaniye kazhdoj fazyi;
- zhivaya priyomka podtverzhdayet ostanovku vsekh otnosyasjhikhsya k checkout pisatelej, tochnoye vosstanovleniye `HEAD`, pustuyu ocheredj novogo pokoleniya i bezopasnyij novyij `join`.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: lokaljnaya mashina sostoyanij, Git-CAS-ograzhdeniye, tochnaya ochistka, samodostatochnaya kvitanciya i avtonomnaya TDD-matrica susjhestvuyut, no bezopasnaya zhivaya priyomka ostayotsya otkryitoj. Perevod v `✅` nevozmozhen, poka dostupnyij Codex-host ne predostavlyayet avtoritetnyij perechenj otnosyasjhikhsya k checkout sessij i proveryayemuyu ostanovku proizvoljnogo zhivogo pisatelya.

Kartochka ne razreshayet ochisjhatj remote, drugiye checkout, ignoriruyemyiye poljzovateljskiye dannyiye ili vlozhennyiye repozitorii, ne delayet istoriyu Git neprotivorechivoj zanovo i ne vyibirayet inoj kommit vmesto uzhe zakreplyonnogo lokaljnogo `HEAD`. Dopolnyayusjhij kornevoj `break-glass` ne dokazyivayet ostanovku zhivyikh host-zadach i ne zakryivayet eto trebovaniye.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-10 10:19:59 MSK — Dobavitj prostoj sbros FIFO k tekusjhemu HEAD](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [iskhodnyij zapros 2026-08-07 20:34:22 MSK — Dobavitj shtatnyij sbros ocheredi](../Zhurnal/2026-08-07_20-34-22_MSK_dobavitj-shtatnyij-sbros-ocheredi/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:99b1a676a40dd019b5bc786de09731a65ebbe9be2a98c84944116b2e84980fa5 -->
<!-- FUM-MD-RECENCY:END -->
