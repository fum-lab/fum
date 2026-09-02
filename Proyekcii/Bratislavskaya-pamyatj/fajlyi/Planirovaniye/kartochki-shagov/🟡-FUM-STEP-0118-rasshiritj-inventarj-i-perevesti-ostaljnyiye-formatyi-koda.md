+++
schema_version = 1
card_id = "FUM-STEP-0118"
status = "active"
+++
# Rasshiritj inventarj i perevesti ostaljnyiye formatyi koda

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj mashinnyij inventarj i bezopasno perevesti sobstvennyiye obyyavleniya koda vo vsekh formatakh vne Markdown, Python i Swift. Nablyudayemyij iskhodnyij srez bez `Зависимости/` i `Источники/` vklyuchayet 11 fajlov `sh`, 5 `jsonl`, 4 `yaml`, 2 `html` i 1 `mlir`; JSON, TOML i inyiye mashinnyiye skhemyi uchityivayutsya kak kontraktyi i ne perevodyatsya slepoj zamenoj.

## Pochemu sejchas

Dejstvuyusjheye pravilo okhvatyivayet sobstvennyiye obyyavleniya nezavisimo ot rasshireniya fajla, a tri sosedniye kartochki pokryivayut toljko Markdown, Python i Swift. Ostaljnyiye formatyi trebuyut otdeljnoj sintaksicheskoj klassifikacii: odinakovo napisannaya latinica mozhet byitj sobstvennyim imenem, klyuchevyim slovom, vneshnim interfejsom ili polem versionnogo mashinnogo formata.

## Kriterii zaversheniya

- Polnyij mashinnyij inventarj perechislyayet sobstvennyiye formatyi vne Markdown, Python i Swift, otdelyayet kod ot mashinnyikh dannyikh, vneshnikh i doslovnyikh oblastej, podtverzhdayet nablyudayemyiye 11 `sh`, 5 `jsonl`, 4 `yaml`, 2 `html` i 1 `mlir` libo obyyasnyayet raskhozhdeniye vosproizvodimyim snimkom.
- Do pervoj massovoj zapisi dopustimoye pereimenovaniye i opasnyij scenarij otkaza zakreplenyi padayusjhimi testami stadii `red`; toljko posle realizacii, dovedyonnoj do prokhozhdeniya etikh testov, massovaya zapisj vyipolnyayetsya samoj lokaljnoj avtomatizaciyej, a ne ruchnoj seriyej zamen.
- Ostatok zaraneye razbit po formatu, sintaksicheskomu analizatoru i granice sovmestimosti na kontekstno ogranichennyiye klasteryi; scenarii obolochki, JSONL, YAML, HTML i MLIR ne smeshivayutsya v odnoj massovoj zamene.
- Dlya kazhdogo klastera do zapisi zakreplenyi yavnaya karta imyon, sukhoj plan, SHA-256 vkhodnogo snimka, proverka kollizij, smesheniya pisjmennostej i vsekh svyazannyikh obrasjhenij.
- Sobstvennyiye JSON-, TOML- i inyiye mashinnyiye skhemyi klassificirovanyi kak kontraktyi: ikh polya, znacheniya i identifikatoryi menyayutsya toljko versionnoj migraciyej vmeste s parserami, pisatelyami, fiksturami, obratnyim chteniyem i etalonnoj proverkoj; bez takogo perekhoda oni ostayutsya neizmennyimi.
- Klyuchevyiye slova, sintaksicheskiye markeryi, vneshniye API i obyazateljnyiye imena instrumentov sokhranyayutsya toljko po konechnomu mashinno proveryayemomu spisku s tochnyimi oblastjyu, prichinoj i istochnikom; neizvestnaya latinica zakryivayet primeneniye.
- Posle kazhdogo klastera tochnyij povtornyij inventarj dokazyivayet umenjsheniye ostatka, a itogovaya proverka — nulevoj neobosnovannyij ostatok vo vsekh sobstvennyikh formatakh vne Markdown, Python i Swift; primenimyiye testyi i obsjhaya kompleksnaya proverka prokhodyat bez seti i sekretov.

## Istochniki

- [iskhodnyij zapros 2026-08-04 12:51:44 MSK — Perevesti obyyavlyayemyij kod na russkij yazyik](../../Zhurnal/2026-08-04_12-51-44_MSK_perevesti-obyyavlyayemyij-kod-na-russkij-yazyik/zapros.md)
- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [avtomatizaciya perevoda obyyavlenij koda na russkij yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 14:04:20 MSK -->
<!-- content-sha256: sha256:bc78ae246bad533ce152568f70c2252bffe1bc1beb3a96563150bdf896012ee1 -->
<!-- FUM-MD-RECENCY:END -->
