+++
schema_version = 1
card_id = "FUM-STEP-0204"
status = "active"
+++
# Vosstanavlivatj osirotevshiye zapisi proverok

## Zadacha

Vosstanovitj ogranichennyij proveryayemyij sposob zaversheniya uchyota osirotevshego zapuska dlya tekusjhikh skhem v3/v4, pereispoljzovav primenimyiye invariantyi istoricheskoj realizacii v1/v2. Snachala sopostavitj tochnyiye kontraktyi i sokhranyonnyiye istochniki; neizvestnyij iskhod ne prevrasjhatj v uspekh.

## Pochemu sejchas

Novoye FUM-SBOJ-0056/PROYAVLENIYE-0001 povtorilo kvalificirovannoye istoricheskoye FUM-SBOJ-0020/PROYAVLENIYE-0001: zapisj ostalasj vyipolnyayusjhejsya posle utratyi upravleniya. Otdeljnyij novyij Zhurnal sokhranil daljnejshuyu rabotu, no prezhneye sostoyaniye ne vosstanovleno.

## Kriterii zaversheniya

- Sopostavlenyi susjhestvuyusjhiye perekhodyi v3/v4 i prezhnij prinyatyij mekhanizm, perechislenyi neobkhodimyiye otlichiya; istoricheskiye FIFO i pul ne vklyuchayutsya.
- Do ispravleniya vosproizvedyon otkaz na otkryitoj obobsjhyonnoj fiksture osirotevshej zapisi.
- Yavnaya komanda prinimayet tochnuyu identichnostj, ozhidayemyiye iskhodnyiye bajtyi i osnovaniye priznaniya neopredelyonnosti; sokhranyayet rekonstruiruyemyij original, neizvestnyiye znacheniya, atomarnostj i tochnyij povtor.
- Proverenyi podmenyonnyij khyesh, neodnoznachnaya ili terminaljnaya zapisj, zakryityij snimok, symlink, preryivaniye i pozdnij otvet prezhnej obyortki; nevernyij vkhod ne izmenyayet dannyiye.
- Chelovecheskij interfejs obyyasnyayet granicu vosstanovleniya i daljnejshiye dejstviya; RED/GREEN, profilj i resheniye ob optimizacii sokhranenyi vmeste s itogovyim dopuskom.

## Istochniki

- [FUM-SBOJ-0056](../../Sboi/FUM-SBOJ-0056-osirotevshij-zapusk-proverki-posle-perezapuska.md): tochnoye osnovaniye FUM-SBOJ-0056/PROYAVLENIYE-0001; istoricheskoye proyavleniye sokhranyayet svoj nomer i ssyilku na kommit.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:ddebe558bafa1647ae88f9ac59fe421a268eb02408b545f57273ffa4ea1b3425 -->
<!-- FUM-MD-RECENCY:END -->
