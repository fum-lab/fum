+++
schema_version = 1
card_id = "FUM-STEP-0213"
status = "active"
+++
# Proveritj ogranichennoye vosstanovleniye statusa priyoma

## Zadacha

Samostoyateljno prinyatj ogranichennoye vosstanovleniye obyazateljnoj stroki prezhnego statusa v chastichnom priyome: bez izmeneniya namereniya, ID, susjhestvuyusjhikh bajtov kartochki i vneshnikh popyitok. Sokhranitj pervichnyij defekt vkhoda i povtor nedostupnogo vosstanovleniya kak raznyiye diagnosticheskiye mekhanizmyi.

## Pochemu sejchas

Finansovyij vkhod propustil obyazateljnuyu deklaraciyu, a prezhnyaya korrekciya ne mogla yeyo dobavitj. Pervoye vosstanovleniye i adresnyiye regressii vyipolnenyi; posle nikh najden i ispravlen dopusk vidimogo Setext-dublya. Nuzhna celjnaya dokazateljnaya granica novyikh ogranichenij, sokhranyayusjhaya prezhnyuyu priyomku 0201.

## Kriterii zaversheniya

- Sokhranenyi kanonicheskiye proyavleniya 0075/0001 i 0059/0002 s iskhodnyimi bajtami, otkazami, rezuljtatami vosstanovleniya i dvustoronnimi svyazyami.
- Nastoyasjhij reyestr prinimayet vosstanovlennoye prezhneye sobyitiye s pervonachaljnyimi ID; povtor drugogo processa ne menyayet iskhodnyij plan i ne sozdayot novogo vneshnego vyizova.
- Proverenyi otkazyi izmenyonnogo, dublirovannogo ili skryitogo statusa i aljternativnyikh zagolovkov; iskhodnyij polozhiteljnyij finansovyij vkhod prokhodit.
- Sokhranenyi RED/GREEN, vosproizvodimyij profilj i obosnovannoye resheniye ob optimizacii. Projden samostoyateljnyij standartnyij itogovyij dopusk novogo soderzhimogo i sokhranyon zakryityij otchyot.
- Sleduyusjhiye podgotovlennyiye kartochki soderzhat obyazateljnuyu deklaraciyu; ikh priyom ne obyyavlyayetsya vyipolnennyim do otdeljnyikh postanovok i vneshnikh nablyudenij.

## Istochniki

- [FUM-SBOJ-0077/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0077-protivorechivyij-status-cherez-Setext-pri-korrekcii.md).
- [FUM-SBOJ-0075/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0075-propusjhennaya-deklaraciya-statusa-trebovaniya.md).
- [FUM-SBOJ-0059/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0059-otsutstviye-korrekcii-negotovogo-chastichnogo-priyoma.md).
- [Iskhodnyiye komandyi, utochneniya i tekusjhaya granica](../../Zhurnal/2026-09-11_14-48-56_MSK_ispravitj-dopusk-statusa-i-prodolzhitj-priyom/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 15:10:58 MSK -->
<!-- content-sha256: sha256:9b64d1ec112c86c524b959ffa818e1eb09a3b7571f11238c65b5c7615921fc03 -->
<!-- FUM-MD-RECENCY:END -->
