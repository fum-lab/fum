# Vetochnyiye cepochki shagov i zaversheniye smoke-check kommitom

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0040 -->

Ekspluatacionnyij status: otlozheno. Kartochka sokhranyayet cepochki, FIFO i `commit+handoff` kak arkhitekturnuyu narabotku; yeyo imperativnyij tekst ne dejstvuyet dlya ruchnogo lokaljnogo kommita i ne trebuyet continuation posle smoke-check.

Kazhdaya ispolnyayemaya posledovateljnostj planovyikh shagov FUM dolzhna imetj kanonicheskuyu [kartochku cepochki shagov](../Glossarij/kartochka-cepochki-shagov.md), kotoraya svyazyivayet konechnyij uporyadochennyij spisok susjhestvuyusjhikh kartochek s odnoj tochnoj lokaljnoj Git-vetkoj. Nachalo realizacii cepochki oznachayet ograzhdyonnyij perekhod checkout na etu vetku do poyavleniya novogo FIFO-vladeljca. Polnyij priyomochnyij smoke-check izmenyayusjhej sessii yavlyayetsya vnutrennej stadiyej sostavnogo zaversheniya: yego nulevoj kod yesjhyo ne schitayetsya vneshnim uspekhom, a uspeshnyij iskhod voznikayet toljko posle zakryitiya dokazateljstv progona, podtverzhdyonnogo sozdaniya prodolzheniya toj zhe vetki i atomarnogo `commit+handoff`.

## Semanticheskiye svyazi

- **usilivayet:** [vyibor sleduyusjhego shaga vetki iz kartochek shagov](✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md) — otdeljnyij kandidat poluchayet proveryayemuyu prinadlezhnostj konechnoj cepochke i vetke, v kotoroj sokhranyayutsya vse uspeshnyiye rezuljtatyi.
- **usilivayetsya:** [derevom vetvevyikh fork i roditeljskoj moderaciyej](🟡-derevo-vetvevyikh-fork-i-roditeljskaya-moderaciya.md) — linejnyiye cepochki mogut statj detjmi odnoj proveryayemoj razvilki, sokhranyaya sobstvennyij unarnyij `commit+handoff`.

## Kriterii proverki

- skhema kartochki khranit ustojchivyij `FUM-ЦЕПОЧКА-NNNN`, sostoyaniye, polnyij lokaljnyij ref prostranstva `refs/heads/codex/`, bazovuyu vetku, putj proyekta i nepustoj uporyadochennyij spisok susjhestvuyusjhikh `FUM-STEP-*` bez povtorov;
- indeks i mashinnyij planovyij reyestr vzaimno odnoznachno pokryivayut kartochki i trebuyut rovno odnu aktivnuyu cepochku; neizvestnyij shag, povtor shaga mezhdu neotozvannyimi cepochkami, povtor vetki, nevernyij ref, neizvestnoye pole ili raskhozhdeniye indeksa zakryivayut sborku;
- nachalo realizacii kartochki ne vyipolnyayetsya uzhe dopusjhennyim FIFO-vladeljcem: mezhzadachnyij perekhod trebuyet tochnuyu pustuyu ocheredj, chistuyu rabochuyu kopiyu, otsutstviye vstrechnogo perekhoda i celevuyu vetku na zakreplyonnoj iskhodnoj vershine, posle chego novaya zadacha poluchayet dopusk uzhe v etoj vetke;
- obyichnyij `join`, pereklyucheniye vladeljcem, vneshnij `git switch`, idle-rebind i pokhozheye imya vetki ne podmenyayut proverennuyu identichnostj kartochki cepochki;
- pryamoj vnutrennij process smoke-check ne vyipolnyayet Git-kommit; nulevoj kod oznachayet toljko prokhozhdeniye proverochnogo kontura, posle kotorogo dolzhnyi byitj terminalizirovanyi zapisj zapuska, otchyot i snimok;
- vneshnij uspekh polnoj smoke-sessii vozvrasjhayetsya toljko posle atomarnogo `commit+handoff`, kotoryij vklyuchayet zakryityiye dokazateljstva i dvigayet exact-vetku tekusjhej cepochki; nenulevoj vnutrennij smoke, sboj zakryitiya, inoj staged tree, vetka ili kartochka ne dayut uspeshnogo iskhoda;
- do commit+handoff kornevaya zadacha sozdayot i registriruyet v FIFO odno prodolzheniye polnogo ref toj zhe vetki; posle peredachi prodolzheniye perechityivayet novyij `HEAD` i zanovo vyibirayet tekusjhuyu kartochku cepochki, a chistoye terminaljnoye sostoyaniye ne porozhdayet sleduyusjhuyu zadachu;
- tekusjhaya bootstrap-sessiya, uzhe dopusjhennaya na `refs/heads/master` do poyavleniya novogo perekhoda, ne menyayet vetku i zavershayet migraciyu prezhnej HEAD-bootstrap-komandoj toljko posle podtverzhdyonnyikh sozdaniya i waiting-bileta prodolzheniya; pervoye fakticheskoye pereklyucheniye vyipolnyayetsya sleduyusjhim otdeljnyim vyizovom vetochnogo perekhoda.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: kanonicheskaya skhema, indeks, nachaljnyiye kartochki cepochek, mashinnaya proyekciya planovogo reyestra i sostavnaya semantika smoke-sessii vvodyatsya etoj rabochej sessiyej. Ograzhdyonnyij perekhod pervoj versii ogranichivayetsya sozdaniyem otsutstvuyusjhej vetki na tochnoj tekusjhej vershine s neizmennyim derevom; perenos mezhdu uzhe razoshedshimisya vetkami, avtomaticheskaya migraciya vsekh selektorov i strogaya smoke-attestation trebuyut otdeljnyikh sleduyusjhikh shagov i ne podmenyayutsya pryamyim `git switch` ili deklaraciyej v dokumentacii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:e40354a268d0b12bc26128f5af89de70fd682d6fa65daa6c26ba8e8fd81366b9 -->
<!-- FUM-MD-RECENCY:END -->
