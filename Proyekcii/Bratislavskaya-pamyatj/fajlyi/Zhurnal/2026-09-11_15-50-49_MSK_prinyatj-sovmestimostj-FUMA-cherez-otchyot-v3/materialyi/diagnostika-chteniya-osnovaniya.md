# Rassoglasovaniye nablyudayemogo metoda chteniya v iskhodnom M

Povtornyij standartnyij full zavershilsya kodom 1: zapisj `e3f59efa-3149-4efe-8d2d-ac6569a6f55d`, 850,348437917 s; vlozhennyij smoke — 850,270 s. Projdenyi shagi 1–23. Yedinstvennyij otkaz poslednego nabora iz 238 testov — `test_повторное_основание_читается_один_раз_за_вызов`: ozhidayetsya `чтение.call_count == 1`, nablyudayetsya 0. Mashinnaya zapisj khranit 13 planovyikh naborov i 13 nablyudenij; pervyiye 12 naborov uspeshnyi. Otchyot ne zakryivalsya, processyi zavershilisj, tyazhyoloye okno osvobozhdeno.

Polnyij pervichnyij potok sokhranyon chastno vne Git: 887879 bajtov, SHA-256 `3b919b96ef2be4d394c8f19f309902f10272b58fbeea4c2ec24f3014a85ff6bf`. Publikacionno dopustimaya tochnaya chastj otkaza:

````text
FAIL: test_повторное_основание_читается_один_раз_за_вызов (test_продолжение_задачи.ПродолжениеЗадачи.test_повторное_основание_читается_один_раз_за_вызов)
AssertionError: 0 != 1
Ran 238 tests in 118.502s
FAILED (failures=1)
````

Adresnaya proverka soderzhimogo Git pokazala otsutstviye diff oboikh fajlov otnositeljno tochnogo M `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`. Iskhodnyij [test](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_prodolzheniye_zadachi.py), blob `72a7522313210129089037c89a57f2e502a8d6e4`, oborachivayet `Path.read_text` na strokakh 107–108. [Proverka prodolzheniya](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/proveritj-prodolzheniye-zadachi.py), blob `39339dd493370a74e50b485190cfda1ee19ee4eb`, na stroke 86 vyizyivayet `read_bytes()` i zatem dekodiruyet UTF-8. Nolj vyizovov `read_text` sootvetstvuyet etomu kodu.

Nezavisimoye chteniye istorii podtverdilo: test sokhranyayet nablyudeniye `read_text` s `39c40194655fbe27e851abfea17c5c432dca5a9f`; `436909208424595f7151f6febca75f89018c0bcb`, pervyij roditelj M, perevyol ispolneniye na chteniye bajtov bez sootvetstvuyusjhej zamenyi nablyudayemogo metoda testa. Eto iskhodnoye rassoglasovaniye M, a ne posledstviye shesti paketov sovmestimosti.

Koordinator podtverdil minimaljnuyu korrektirovku dvukh tochek nablyudeniya. Tochnyij istochnik perenosa — `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95`, uzhe ispoljzovannyij dlya paketa formatov prilozheniya. Diff etogo fajla soderzhit yedinstvennyij hunk dvukh zamen `read_text` na `read_bytes` v zakhvate iskhodnogo metoda i `mock.patch.object`; iskhodnyij blob — `72a7522313210129089037c89a57f2e502a8d6e4`, itogovyij sootvetstvuyet tekusjhemu testu. Eto perenos propusjhennoj sovmestimoj deljtyi iz izvestnogo istochnika, a ne novyij algoritm.

Boleye rannyaya nezavisimaya sverka obnaruzhila to zhe ispravleniye v `a76969ce644feb82d720825bbc0e5e71cbd192b0`, roditelj `68996460643a50d47cfc6e121b34cc0911639f26`. Blob testa tam i v zakreplyonnoj L `a728283474931eda71cd581ca5429121124ba3f6` — `8d5be5c411101b2bef3336b71c2a8a905e93dd24`. Etot fajl soderzhit dopolniteljnyiye izmeneniya fiksturyi; oni ne perenosyatsya. Pozdneye utochneniye koordinatora zakrepilo imenno minimaljnyij source/diff `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95` dlya dannoj priyomki.

Adresnyij RED `3b88a61f-24f3-4054-9e61-9930f18e87f8` za 0,093797709 s vosproizvyol tot zhe otkaz yedinstvennogo sluchaya do pravki. Posle dvukh zamen tochnaya komanda dala GREEN `4770dff5-38f3-4f8c-b1e4-d3d066c38efa`, kod 0 za 0,101170708 s. Usloviye yedinstvennogo chteniya dlya dvukh osnovanij i proverka otkaza posle izmeneniya fajla mezhdu vyizovami sokhranenyi; production ne menyalsya.

Profilirovannyij adresnyij modulj `45f6bfca-221b-477f-9ea6-fdc39d1a1b07` proshyol vse 13 testov za 1,379 s, obyortka — 1,504784917 s. [Svodka cProfile](profilj-nablyudeniya-chteniya.json) sokhranyayet oblastj izmereniya i ogranicheniya dochernikh processov. Celevoj test zanyal 4,350208 ms nakoplennogo vremeni. Daljnejshaya optimizaciya ne nuzhna: ispravlyayetsya nablyudeniye prezhnego vvoda, vyichisliteljnyij algoritm ne izmenyon, susjhestvennoj izmerennoj stoimosti u etoj pravki net.

Dve neuspeshnyiye polnyiye popyitki i adresnyij RED ostayutsya v R3. Raspredelitelj soglasoval `FUM-СБОЙ-0066/ПРОЯВЛЕНИЕ-0003` posle sverki dostupnoj istorii i chastnyikh rezervov. [Susjhestvuyusjhaya kartochka](../../../Sboi/FUM-SBOJ-0066-ustarevshaya-podstanovka-metoda-chteniya.md) perenesena iz L, blob `e535e7ac3cb2a76234cba5550c28b5cd7f167616`, s sokhraneniyem proyavlenij 0001 i 0002. Novoye proyavleniye otnositsya toljko k nablyudyonnomu M, ne pripisyivayetsya Linux. Aktivnaya granica svyazana s susjhestvuyusjhim FUM-STEP-0175 i trebuyet priyomki i integracii tochnoj deljtyi v master. Sleduyusjhij polnyij progon dopuskayetsya toljko posle zaversheniya vkhoda i peredachi tyazhyologo okna.

Istochnik: [tekusjhij zapros](../zapros.md), [mashinnaya zapisj](zapuski-proverok/7_e3f59efa-3149-4efe-8d2d-ac6569a6f55d.json), nezavisimyij read-only-razbor dochernego ispolnitelya v kornevoj zadache `01a09047-faa1-7370-83f7-cdfc8f9943a6`.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:57:51 MSK -->
<!-- content-sha256: sha256:492797ebe52b4c8ca2393a7ac60bbed045e31a9af90cfabd9d5c86508c318475 -->
<!-- FUM-MD-RECENCY:END -->
