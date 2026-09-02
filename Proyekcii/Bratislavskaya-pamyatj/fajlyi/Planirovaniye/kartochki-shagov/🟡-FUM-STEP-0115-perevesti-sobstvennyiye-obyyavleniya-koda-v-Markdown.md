+++
schema_version = 1
card_id = "FUM-STEP-0115"
status = "active"
+++
# Perevesti sobstvennyiye obyyavleniya koda v Markdown

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Perevesti na russkij yazyik kirillicej sobstvennyiye obyyavleniya koda, soderzhasjhiyesya v proizvodnyikh Markdown-dokumentakh FUM: identifikatoryi Mermaid, obyyavleniya v psevdokode i vstroyennyikh fragmentakh koda, a takzhe svyazannyiye inline-ssyilki i obrasjheniya k etim obyyavleniyam. Migraciya dolzhna vyipolnyatjsya kontekstno ogranichennyimi klasterami po mashinnomu inventaryu, ne menyatj doslovnyiye i vneshniye oblasti i sokhranyatj sovmestimostj vnutrennikh skhem toljko cherez yavnoye versionirovaniye.

## Pochemu sejchas

Obsjheye pravilo russkogo yazyika dlya obyyavlyayemogo koda uzhe zakreplyayetsya i poluchayet avtomatizirovannuyu proverku, no susjhestvuyusjhij Markdown-korpus slishkom shirok dlya odnoj bezopasnoj mekhanicheskoj zamenyi. V nyom sovmestno nakhodyatsya sobstvennyiye diagrammyi i psevdokod, vneshniye API, stabiljnyiye mashinnyiye polya, doslovnyiye zaprosyi i arkhivnyiye istochniki. Ustojchivaya postavka trebuyet snachala otdelitj eti klassyi, zatem posledovateljno umenjshatj tochnyij ostatok bez skryitogo izmeneniya kontraktov.

## Kriterii zaversheniya

- Mashinnyij inventarj perechislyayet sobstvennyiye obyyavleniya v Mermaid, psevdokode, fenced- i inline-fragmentakh Markdown, otlichayet ikh ot upotreblenij, klyuchevyikh slov, vneshnikh API, komand, stabiljnyikh wire-imyon i doslovnogo materiala i fiksiruyet tochnyij iskhodnyij ostatok.
- Do pervoj massovoj zapisi dopustimoye pereimenovaniye i opasnyij scenarij otkaza zakreplenyi padayusjhimi testami stadii `red`; toljko posle realizacii, dovedyonnoj do prokhozhdeniya etikh testov, massovaya zapisj vyipolnyayetsya samoj lokaljnoj avtomatizaciyej, a ne ruchnoj seriyej zamen.
- Ostatok zaraneye razbit na kontekstno ogranichennyiye klasteryi po vidu konstrukcii i oblasti svyazannyikh ssyilok; odin klaster ne smeshivayet nezavisimyiye skhemyi, diagrammyi ili dokumentyi s raznyimi kontraktami sovmestimosti.
- Dlya kazhdogo klastera do zapisi podgotovlenyi odnoznachnaya karta staryikh i russkikh imyon, `dry-run`, SHA-256 vkhodnogo snimka, proverka kollizij, smesheniya pisjmennostej i polnogo nabora svyazannyikh obrasjhenij.
- Tekst iskhodnyikh poljzovateljskikh zaprosov, vesj katalog `Источники/`, doslovnyiye citatyi, sokhranyonnyiye vneshniye materialyi i identifikatoryi vneshnikh API ostayutsya pobajtno neizmennyimi v zasjhisjhyonnyikh granicakh.
- Identifikatoryi Mermaid i vse ikh ryobra, podpisi, ssyilki i obrasjheniya migrirovanyi soglasovanno; diagrammyi razbirayutsya shtatnyimi proverkami, a lokaljnyiye Markdown-ssyilki sokhranyayut susjhestvuyusjhiye celi i tochnyij registr putej.
- Polya i znacheniya vnutrennikh mashinnyikh skhem pereimenovyivayutsya toljko s novoj versiyej skhemyi, yavnyim preobrazovaniyem prezhnego formata i golden-proverkoj kanonicheskogo rezuljtata; bez takogo perekhoda stabiljnyiye wire-imena sokhranyayutsya.
- Posle kazhdogo klastera povtornyij inventarj dokazyivayet strogoye umenjsheniye exact-ostatka, a itogovyij progon pokazyivayet nulevoj neobosnovannyij ostatok; kazhdoye sokhranyonnoye isklyucheniye imeyet mashinno proveryayemyij klass i proiskhozhdeniye.
- Domennyiye proverki Markdown, Mermaid, lokaljnyikh ssyilok, grafa Obsidian, recency i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [iskhodnyij zapros 2026-08-04 12:51:44 MSK — Perevesti obyyavlyayemyij kod na russkij yazyik](../../Zhurnal/2026-08-04_12-51-44_MSK_perevesti-obyyavlyayemyij-kod-na-russkij-yazyik/zapros.md)
- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [avtomatizaciya perevoda obyyavlenij koda na russkij yazyik](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-04 14:04:20 MSK -->
<!-- content-sha256: sha256:db9a1445f65d91144a747c2b6a2b98227c4c013e5af1265cef4cb285e5b53ada -->
<!-- FUM-MD-RECENCY:END -->
