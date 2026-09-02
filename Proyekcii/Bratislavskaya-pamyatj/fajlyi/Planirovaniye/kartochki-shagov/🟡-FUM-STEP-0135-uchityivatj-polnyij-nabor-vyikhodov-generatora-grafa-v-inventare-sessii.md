+++
schema_version = 1
card_id = "FUM-STEP-0135"
status = "active"
+++
# Uchityivatj polnyij nabor vyikhodov generatora grafa v inventare sessii

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Svyazatj mashinno obyyavlennyij polnyij nabor kanonicheskikh vyikhodov generatora svezhesti grafa Obsidian s inventaryom zatronutyikh fajlov rabochej sessii, chtobyi oba vyikhoda pokryivalisj do zakryitiya nezavisimo ot iskhodnogo Git diff i perekhoda kalendarnoj datyi MSK.

## Pochemu sejchas

Polnyij smoke-check tekusjhej sessii peresyok polnochj MSK. Zamyikayusjhij zapusk generatora vpervyiye izmenil `.obsidian/fum-recency-reference-date`, togda kak zapros perechislyal toljko `.obsidian/graph.json`; svyaznostj praviljno otkazala na neozhidannom puti i potrebovala vozobnovitj uzhe zakryityij mashinnyij zhurnal. Ruchnoye dobavleniye sidecar vosstanavlivayet odnu sessiyu, no ne predotvrasjhayet povtor na sleduyusjhej kalendarnoj granice.

## Kriterii zaversheniya

- Krasnaya integracionnaya fikstura nachinayet s chistogo sidecar datyi `D`, formiruyet inventarj toljko po iskhodnomu diff, perevodit generator na `D+1` v zamyikayusjhem khode i vosproizvodit neozhidannyij putj FUM-SBOJ-0007.
- Generator predostavlyayet zakryityij mashinno chitayemyij perechenj svoikh kanonicheskikh vyikhodov s tochnyimi repozitorno-otnositeljnyimi putyami `.obsidian/graph.json` i `.obsidian/fum-recency-reference-date`.
- Sessionnaya avtomatizaciya do zakryitiya sopostavlyayet fakt ispoljzovaniya generatora s yego perechnem vyikhodov i trebuyet pokryitiya kazhdogo puti razdelom `Повлиял на файлы`, ne vyivodya perechenj iz tekusjhego Git diff.
- Nalichiye v inventare obyyavlennogo, no pobajtno neizmennogo vyikhoda dopustimo i ne prinuzhdayet generator k perezapisi; lishnij putj, neizvestnyij vyikhod, nevernyij registr, simvoljnaya ssyilka i vyikhod za korenj otklonyayutsya.
- Fiksturyi pokryivayut neizmennuyu datu, perekhod cherez polnochj MSK do smoke-check, perekhod mezhdu smoke-check i zakryitiyem i povtornyij zamyikayusjhij zapusk na toj zhe date.
- Oshibka do zakryitiya ne sozdayot snimok proverok; obnaruzheniye posle uzhe podgotovlennogo snimka imeyet idempotentnyij dokumentirovannyij putj vozobnovleniya bez poteri mashinnyikh zapisej.
- Avtonomnyiye testyi generatora grafa, strukturyi zaprosov i svyaznosti rabochej sessii, regressiya FUM-SBOJ-0007 i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0007 — Propusk opornoj datyi grafa posle perekhoda cherez polnochj MSK](../../Sboi/FUM-SBOJ-0007-propusk-opornoj-datyi-grafa-posle-perekhoda-cherez-polnochj-MSK.md) — osnovaniye `FUM-СБОЙ-0007/ПРОЯВЛЕНИЕ-0001`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya svezhesti grafa Obsidian](../../Instrumentyi/fum-svezhestj-grafa-obsidian/SKILL.md)
- [avtomatizaciya svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 00:19:54 MSK -->
<!-- content-sha256: sha256:12deada69dfc616c564503c6b80b1628e3de3cf4a6c39cc2d275f17d64973e95 -->
<!-- FUM-MD-RECENCY:END -->
