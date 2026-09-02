+++
schema_version = 1
card_id = "FUM-STEP-0116"
status = "active"
+++
# Perevesti Python-obyyavleniya klasternyimi migraciyami

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Perevesti na russkij yazyik kirillicej sobstvennyiye obyyavleniya v sobstvennom Python-kode FUM kontekstno ogranichennyimi klasternyimi migraciyami. Kazhdyij klaster dolzhen stroitjsya po mashinnomu inventaryu oblastej vidimosti i svyazej, sokhranyatj tochnyiye CLI- i wire-kontraktyi, trebovaniya yazyika i vneshnikh API i zavershatjsya nablyudayemyim umenjsheniyem ostatka bez izmeneniya povedeniya.

## Pochemu sejchas

Python-kod raspredelyon mezhdu lokaljnyimi avtomatizaciyami, generatorami, validatorami, testami i sluzhebnyimi tochkami vkhoda. Odinakovo napisannyiye anglijskiye imena imeyut raznyiye domennyiye znacheniya i oblasti vidimosti, a ryadom nakhodyatsya obyazateljnyiye specialjnyiye metodyi, vneshniye vyizovyi, argumentyi CLI i polya mashinnyikh formatov. Globaljnaya tekstovaya zamena ne razlichayet eti granicyi, poetomu ostatok nuzhno perevoditj po nezavisimyim proveryayemyim klasteram.

## Kriterii zaversheniya

- AST-inventarj perechislyayet sobstvennyiye Python-obyyavleniya klassov, funkcij, parametrov, peremennyikh, atributov i vspomogateljnyikh tipov, otlichayet importyi, klyuchevyiye slova, specialjnyiye trebovaniya Python i vneshniye API i fiksiruyet tochnyij iskhodnyij ostatok.
- Do pervoj massovoj zapisi dopustimoye pereimenovaniye i opasnyij scenarij otkaza zakreplenyi padayusjhimi testami stadii `red`; toljko posle realizacii, dovedyonnoj do prokhozhdeniya etikh testov, massovaya zapisj vyipolnyayetsya samoj lokaljnoj avtomatizaciyej, a ne ruchnoj seriyej zamen.
- Ostatok zaraneye razbit po lokaljnoj avtomatizacii ili svyazannomu paketu i obsjhemu CLI- libo wire-kontraktu na kontekstno ogranichennyiye klasteryi, kazhdyij iz kotoryikh mozhno nezavisimo izmenitj i proveritj v odnoj rabochej postavke.
- Dlya kazhdogo klastera do zapisi podgotovlenyi odnoznachnaya karta staryikh i russkikh imyon s uchyotom oblastej vidimosti, `dry-run`, SHA-256 vkhodnogo snimka, proverka kollizij, zateneniya, dinamicheskikh obrasjhenij i smesheniya pisjmennostej.
- Imena importiruyemyikh bibliotek, vneshnikh API, Python-protokolov i obyazateljnyikh specialjnyikh metodov sokhranyayutsya; sobstvennyiye vnutrenniye obyyavleniya i vse staticheski i dinamicheski obnaruzhivayemyiye obrasjheniya k nim migriruyutsya soglasovanno.
- Argumentyi i komandyi CLI, peremennyiye sredyi, imena fajlov, JSON-, TOML- i inyiye wire-polya sokhranyayut prezhniye znacheniya libo poluchayut otdeljnuyu versionnuyu migraciyu s obratnyim chteniyem i golden-proverkoj; perevod lokaljnogo identifikatora ne menyayet etot interfejs neyavno.
- Tekst iskhodnyikh poljzovateljskikh zaprosov, katalog `Источники/`, doslovnyiye fiksturyi i sokhranyonnyiye vneshniye materialyi ne perepisyivayutsya; testovyiye dannyiye menyayutsya toljko tam, gde oni proveryayut sobstvennoye novoye obyyavleniye, a ne prezhnij vneshnij kontrakt.
- Posle kazhdogo klastera povtornyij inventarj dokazyivayet strogoye umenjsheniye exact-ostatka, a itogovyij progon pokazyivayet nulevoj neobosnovannyij ostatok; kazhdoye sokhranyonnoye isklyucheniye imeyet mashinno proveryayemyij klass i proiskhozhdeniye.
- Avtonomnyiye testyi zatronutyikh avtomatizacij, proverki CLI i wire-sovmestimosti, kompilyaciya Python-iskhodnikov i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [iskhodnyij zapros 2026-08-04 12:51:44 MSK — Perevesti obyyavlyayemyij kod na russkij yazyik](../../Zhurnal/2026-08-04_12-51-44_MSK_perevesti-obyyavlyayemyij-kod-na-russkij-yazyik/zapros.md)
- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [avtomatizaciya perevoda obyyavlenij koda na russkij yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 14:04:20 MSK -->
<!-- content-sha256: sha256:b2496cea82bcf8f558847bc2a8040cd0e9609acc8beb2295e07990b3fd81e7e7 -->
<!-- FUM-MD-RECENCY:END -->
