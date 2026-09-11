+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0076"
"статус" = "активна"
+++
# Propusk proverki predkov kataloga tipov

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0076/ПРОЯВЛЕНИЕ-0001`: pri perenose validatora iz `c14b2dee156a5a07d22addf187f06980c1f501bc` semj podsluchayev adresnogo RED pokazali propusk pustogo kataloga s nevernyim registrom i simvolicheskikh ssyilok libo nevernogo registra v predkakh puti ustanovlennogo tipa. Eto odno nablyudeniye obsjhego mekhanizma. [Zapisj RED](../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/materialyi/zapuski-proverok/3_ddabb77b-d1fd-4d8f-a5a0-6cabd7ba05df.json) fiksiruyet otkaz zapuska; tochnaya regressionnaya granica khranitsya v [vosjmi testakh prinimayusjhego validatora](../Instrumentyi/fum-struktura-papok-zaprosov/tests/test_prinimayusjhij_validator_tipov.py).

## Narushennoye ozhidaniye i mekhanizm

Istoricheskoye otsutstviye kataloga tipov dopustimo toljko pri tochnyikh obyichnyikh predkakh. Usloviye `exists() or is_symlink()` pered vyizovom proverki skryivalo registrovyiye variantyi i otsutstvuyusjhij putj pod simvolicheskim predkom. Proverka neposredstvenno kataloga posle etogo usloviya takzhe ne proveryala vsyu cepochku komponentov.

## Vosstanovleniye i sistemnaya mera

V sobstvennoj vetke sovmestimosti `validate_layout` vyizyivayet proverku bez predvariteljnogo usloviya susjhestvovaniya. Proveryayusjhaya funkciya snachala leksicheski proveryayet vesj putj s tochnyim registrom i zapretom simvolicheskikh ssyilok, zatem razreshayet istoricheskoye otsutstviye. Obsjhaya funkciya puti razlichayet trebuyemyij fajl i katalog. Sovmestnyij GREEN proshyol 82 testa, vklyuchaya vosemj novyikh i 19 iskhodnyikh testov rasshireniya: [svideteljstvo](../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/materialyi/zapuski-proverok/4_1d9a7f70-c9fc-490a-b1f1-d4b6fc92b1a4.json). Prezhnij dopusk iskhodnogo kommita ne obyyavlyayetsya proverkoj ispravleniya. Integraciya v master yesjhyo ne vyipolnena.

## Svyazannyiye shagi

- [FUM-STEP-0175](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md); osnovaniye — `FUM-СБОЙ-0076/ПРОЯВЛЕНИЕ-0001`.

## Kriterij zakryitiya

Prinimayusjhij kontur s ispravleniyem prinyat v master i proveren na zakreplyonnom kandidate: povrezhdyonnyiye, nepolnyiye i nesovmestimyiye tipyi, nevernyij registr i simvolicheskiye ssyilki v kazhdom komponente otklonyayutsya; istoricheskoye otsutstviye i sovmestimyiye dannyiye sokhranyayutsya bez zapisi. Adresnyiye regressii predotvrasjhayut povtor obsjhej oshibki. Publikaciya otdeljnoj vetki sama po sebe ne zakryivayet etot kriterij.

## Istochniki

- [Iskhodnyiye komandyi i granica etapa](../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/zapros.md), [otchyot](../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/otchyot.md).
- Nomer vyidelen obsjhim raspredelitelem po porucheniyu koordinatora dlya zadachi `01a09047-faa1-7370-83f7-cdfc8f9943a6`; sobyitiye rezerva `2bf38b849aaadc751ac8cdbe02a47bd872463549a0e11c9278d098e43f036a3f`. Nomer ne vyichislen po lokaljnomu maksimumu; polnaya kvitanciya sokhranyayetsya chastno.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:19:56 MSK -->
<!-- content-sha256: sha256:d83be9c609f4dcbaafc610e7dc5c1b4c7d4cabb158e14adb606eff27f4239c0f -->
<!-- FUM-MD-RECENCY:END -->
