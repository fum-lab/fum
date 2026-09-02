# Otchyot 2026-07-22 11:48:49 MSK - Oformitj kartochki shagov opisateljnyimi imenami i emodzi statusami

Kartochki shagov poluchayut chelovekochitayemyiye imena, v kotoryikh vmeste s ustojchivyim nomerom vidnyi kratkoye opisaniye i emodzi tekusjhego statusa. Identichnostj shaga po-prezhnemu zadayotsya neizmenyayemyim `card_id`, a smena statusa stanovitsya nablyudayemyim Git-pereimenovaniyem.

## Rezuljtat

Vse 69 kartochek pereimenovanyi po skheme `<эмодзи>-FUM-STEP-NNNN-<краткое-название>.md`: 31 aktualjnaya kartochka ispoljzuyet `🟡`, 37 vyipolnennyikh — `✅`, yedinstvennaya poglosjhyonnaya — `🧩`; `🗑️` zakreplyon za snyatyimi kartochkami i poka ne primenyayetsya. Neizmenyayemyiye `card_id`, zagolovki, soderzhaniye i datyi soderzhateljnogo redaktirovaniya kartochek sokhranenyi.

Pravila, glossarij, trebovaniye i polnyij indeks razlichayut zhiznennyij status kartochki i vetochnyiye sostoyaniya zapuska. Smena statusa ili utochneniye opisaniya vyipolnyayetsya cherez `git mv`; polnoye imya ogranicheno 255 bajtami UTF-8. Shestj dlinnyikh opisanij soderzhateljno sokrasjhenyi, fakticheskij maksimum raven 249 bajtam, casefold- i NFD-kollizij net.

Obe planovyiye avtomatizacii proveryayut tochnoye sootvetstviye imeni TOML-metadannyim, dopustimoye Unicode-opisaniye i polnyij Markdown-inventarj kataloga. Planovyij reyestr peresobran s novyimi putyami. Rabochij nabor `master` sokhranyayet kartochki `FUM-STEP-0023` i `FUM-STEP-0035`, no vyipuskayet novyiye pokoleniya `step_id` iz-za izmeneniya `card_path` v sozdavayemom prompt.

## Proverki

- TDD-nabor `fum-reyestr-planirovaniya`: 26 testov; otdeljno vosproizvedyon i zakryit fail-open dlya vlozhennyikh i registrovyikh variantov Markdown.
- TDD-nabor `fum-sleduyusjhij-shag-vetki`: 48 testov; otdeljno vosproizvedenyi i zakryityi fail-open dlya netochnogo `README.md`, rasshireniya `.MD` i validnoj vlozhennoj kartochki.
- Planovyij reyestr uspeshno sobran i proveren; vetochnyij `validate` vidit 69 kartochek, a fenced `show` vozvrasjhayet novyij putj `FUM-STEP-0023` i pokoleniye `master-fum-step-0023-ready-v2`.
- Provereno otsutstviye casefold- i NFD-kollizij; maksimaljnaya dlina imeni — 249 bajt.
- Recency-metki, graf Obsidian, svyaznostj sessii i `git diff --check` proshli; polnyij smoke-check zavershil vse 37 etapov, vklyuchaya SwiftPM-testyi, sborki produktov i strogij lint.

## Zatronutyiye materialyi

- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [glossarnaya statjya «Kartochka shaga»](../../Glossarij/kartochka-shaga.md)
- [trebovaniye ob atomarnyikh kartochkakh planovyikh shagov](../../Trebovaniya/✅-atomarnyiye-kartochki-planovyikh-shagov.md)
- [indeks kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md)
- avtomatizacii `fum-reyestr-planirovaniya` i `fum-sleduyusjhij-shag-vetki`

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:da3dbb2e95dfa479af226dcbdadf3c4ef1a831bc5aca74be96463b8327fb7723 -->
<!-- FUM-MD-RECENCY:END -->
