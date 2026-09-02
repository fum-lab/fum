+++
schema_version = 1
card_id = "FUM-STEP-0117"
status = "active"
+++
# Perevesti Swift-obyyavleniya paketnyimi migraciyami

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Perevesti na russkij yazyik kirillicej sobstvennyiye obyyavleniya v sobstvennom Swift-kode FUM posledovateljnyimi migraciyami SwiftPM-paketov. Migraciya dolzhna sokhranyatj vneshniye i sistemnyiye API, trebovaniya protokolov, Codable- i raw-value-sovmestimostj, komandyi CLI i kanonicheskiye golden-rezuljtatyi; zakreplyonnyij vneshnij Git-submodule LinguisticKit v oblastj izmeneniya ne vkhodit.

## Pochemu sejchas

Swift-korpus soderzhit svyazannyiye publichnyiye tipyi, moduli, produktyi, ispolnyayemyiye celi, testyi i serializuyemyiye modeli neskoljkikh paketov. Pereimenovaniye svojstva ili enum case sposobno nezametno izmenitj Codable-klyuch, raw value, khyesh ili komandnyij interfejs, a imena trebovanij vneshnikh protokolov neljzya perevoditj kak sobstvennyij API. Poetomu migraciya dolzhna idti v poryadke zavisimostej paketov, s zaraneye zakreplyonnyimi granicami sovmestimosti i polnoj proverkoj kazhdogo klastera.

## Kriterii zaversheniya

- Swift parser- ili AST-inventarj perechislyayet sobstvennyiye obyyavleniya tipov, funkcij, svojstv, parametrov, metok, parametrov obobsjhenij i enum cases, otlichayet klyuchevyiye slova, sistemnyiye i vneshniye API, trebovaniya protokolov i specialjnyiye imena kompilyatora i fiksiruyet tochnyij iskhodnyij ostatok bez fajlov `Зависимости/LinguisticKit` i sborochnyikh artefaktov.
- Do pervoj massovoj zapisi dopustimoye pereimenovaniye i opasnyij scenarij otkaza zakreplenyi padayusjhimi testami stadii `red`; toljko posle realizacii, dovedyonnoj do prokhozhdeniya etikh testov, massovaya zapisj vyipolnyayetsya samoj lokaljnoj avtomatizaciyej, a ne ruchnoj seriyej zamen.
- Ostatok zaraneye razbit po grafu SwiftPM-zavisimostej na kontekstno ogranichennyiye paketnyiye klasteryi; otdeljno uchtenyi manifestyi, imena modulej, produktov i ispolnyayemyikh celej, mezhpaketnyiye `import` i testovyiye celi.
- Dlya kazhdogo klastera do zapisi podgotovlenyi odnoznachnaya karta staryikh i russkikh imyon, `dry-run`, SHA-256 vkhodnogo snimka, proverka kollizij, smesheniya pisjmennostej, metok selektorov i polnogo nabora ssyilok vo vsekh zavisimyikh celyakh.
- Klyuchevyiye slova Swift, standartnyiye, sistemnyiye i vneshniye tipyi i API, obyazateljnyiye imena trebovanij vneshnikh protokolov, overrides i specialjnyiye imena kompilyatora sokhranyayutsya kak obosnovannyiye isklyucheniya; trebovaniya sobstvennyikh protokolov perevodyatsya vmeste so vsemi realizaciyami.
- Do pereimenovaniya Codable-svojstv, `CodingKeys` cases i `String` raw-value cases prezhniye wire-znacheniya zakreplenyi yavno; kanonicheskiye JSON-bajtyi, SHA-256, sokhranyonnyiye pokoleniya i mezhyyazyikovyiye golden-fiksturyi sovpadayut s iskhodnyim kontraktom libo prokhodyat otdeljnuyu versionnuyu migraciyu.
- Komandyi i flagi CLI, imena vyizyivayemyikh vneshnikh instrumentov i opublikovannyiye API sokhranyayut prezhneye napisaniye toljko dlya dokazannogo vneshnego potrebitelya ili obyazateljnogo instrumenta s proveryayemyim istochnikom; vo vsekh ostaljnyikh sluchayakh oni poluchayut yavnuyu versionnuyu migraciyu s sovmestimyim perekhodom; pereimenovaniye lokaljnogo Swift-simvola ne menyayet eti kontraktyi neyavno.
- Posle kazhdogo paketnogo klastera povtornyij inventarj dokazyivayet strogoye umenjsheniye exact-ostatka, a itogovyij progon pokazyivayet nulevoj neobosnovannyij ostatok; kazhdoye sokhranyonnoye isklyucheniye imeyet mashinno proveryayemyij klass i proiskhozhdeniye.
- Dlya kazhdogo paketa prokhodyat `swift package dump-package`, testyi, sborka vsekh ispolnyayemyikh produktov i strogij lint s razreshyonnyimi kirillicheskimi identifikatorami; zatem prokhodyat golden-proverki, mezhpaketnaya sborka i obsjhij smoke-check bez seti i sekretov.

## Istochniki

- [iskhodnyij zapros 2026-08-04 12:51:44 MSK — Perevesti obyyavlyayemyij kod na russkij yazyik](../../Zhurnal/2026-08-04_12-51-44_MSK_perevesti-obyyavlyayemyij-kod-na-russkij-yazyik/zapros.md)
- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [avtomatizaciya perevoda obyyavlenij koda na russkij yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 14:04:20 MSK -->
<!-- content-sha256: sha256:a7fa5c6ca6199381107d89f99968fd4aedfe23a89b41d7adb4976b44b4010e40 -->
<!-- FUM-MD-RECENCY:END -->
