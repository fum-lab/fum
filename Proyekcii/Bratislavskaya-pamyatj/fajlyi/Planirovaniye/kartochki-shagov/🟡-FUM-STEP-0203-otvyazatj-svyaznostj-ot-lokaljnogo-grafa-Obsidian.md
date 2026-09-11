+++
schema_version = 1
card_id = "FUM-STEP-0203"
status = "active"
+++
# Otvyazatj svyaznostj ot lokaljnogo grafa Obsidian

## Zadacha

Zavershitj ustraneniye zavisimosti primenimogo dokumentacionnogo dopuska ot neobyazateljnogo ignoriruyemogo .obsidian/graph.json. Pereispoljzovatj prinyatoye isklyucheniye svyaznosti v obrabotke ssyilok proyekcii i sokhranitj strogiye otkazyi drugikh celej.

## Pochemu sejchas

FUM-SBOJ-0052/PROYAVLENIYE-0003 obnaruzhilo nepokryituyu vetku: matematicheskoye derevo soderzhit prinyatoye ispravleniye svyaznosti, no shag 4 proyekcii po-prezhnemu trebuyet poljzovateljskij fajl. Nomer shaga sokhranyayetsya; prezhneye zaversheniye otnosilosj k dokazannoj granice proverki Markdown-ssyilok.

## Kriterii zaversheniya

- Adresnyij RED vosproizvodit otsutstvuyusjhij graf pri formirovanii vyikhodov i polnom sinteticheskom primenenii proyekcii, vklyuchaya otsutstviye samoj .obsidian.
- Perepisyivatelj ispoljzuyet tot zhe tochnyij predikat, proveryayet Git-ignore i sokhranyayet adres kanonicheskogo grafa iz proizvodnogo fajla; analizator obyichnyikh pereimenovanij ne oslablen.
- Proverenyi neizmennostj susjhestvuyusjhego grafa, obyichnaya otsutstvuyusjhaya celj, pokhozhiye imena, registr predka, symlink, vyikhod iz checkout i otsutstviye ignore.
- Profilj podtverzhdayet stoimostj neskoljkikh ssyilok; optimizaciya, yesli opravdana zamerom, sokhranyayet proverki kazhdoj ssyilki i obnovleniye vneshnego usloviya mezhdu vyizovami.
- Proverennyij commit peredan vladeljcu matematiki; primenimyij dokumentacionnyij dopusk bez grafa podtverzhdayet ustraneniye novogo puti otkaza. Vremennaya kopiya ili pustoj graf ne ispoljzuyutsya kak dokazateljstvo.

## Prezhnij rezuljtat

28f51c58fa8df4d20d33ef2f05dab758cb7a6f83 ustranil zavisimostj proverki svyaznosti. Proverka 1598 fajlov publichnogo klona iz 0176 sokhranyayetsya kak ogranichennoye svideteljstvo. Tri fajla etogo rezuljtata pobajtno prisutstvuyut v 8609003; povtornyij perenos ne trebuyetsya. [Prezhnyaya kartochka rezuljtata](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Планирование/карточки-шагов/✅-FUM-STEP-0203-отвязать-связность-от-локального-графа-Obsidian.md).

## Istochniki

- [FUM-SBOJ-0052](../../Sboi/FUM-SBOJ-0052-svyaznostj-trebuyet-lokaljnyij-graf-Obsidian.md): osnovaniye povtornoj rabotyi FUM-SBOJ-0052/PROYAVLENIYE-0003.
- [Zapros tekusjhego etapa](../../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:bf23d437ffc9c6571877dac390e08ecc79f7fb5fd08b91dfbf7e8d082f39e04f -->
<!-- FUM-MD-RECENCY:END -->
