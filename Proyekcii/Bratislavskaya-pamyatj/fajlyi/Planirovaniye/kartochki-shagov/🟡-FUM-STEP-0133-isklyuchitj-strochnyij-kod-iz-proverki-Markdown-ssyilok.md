+++
schema_version = 1
card_id = "FUM-STEP-0133"
status = "active"
+++
# Isklyuchitj strochnyij kod iz proverki Markdown-ssyilok

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sdelatj izvlecheniye lokaljnyikh Markdown-ssyilok v proverke svyaznosti osvedomlyonnyim o CommonMark-kodovyikh intervalakh: ssyilkopodobnyij sintaksis celikom vnutri korrektnogo strochnogo koda ne dolzhen sozdavatj proveryayemoye rebro, a nastoyasjhiye ssyilki vne nego dolzhnyi sokhranyatj dejstvuyusjhuyu zakryituyu proverku.

## Pochemu sejchas

Predfinaljnaya svyaznostj tekusjhej rabochej sessii zavershilasj kodom `1`, potomu chto polnyij bukvaljnyij primer ssyilki vnutri odinarnyikh obratnyikh kavyichek byil interpretirovan kak aktivnaya ssyilka s vyikhodom za korenj. Lokaljnaya pereformulirovka snimayet tekusjhij otkaz, no ostavlyayet tot zhe lozhnyij rezuljtat dlya budusjhej dokumentacii i ne yavlyayetsya sistemnyim ustraneniyem.

## Kriterii zaversheniya

- Krasnaya avtonomnaya fikstura vosproizvodit tochnyij primer FUM-SBOJ-0005 vnutri odinarnogo kodovogo intervala i nablyudayemyij lozhnyij otkaz `local Markdown link escapes the repository`.
- Razbor Markdown opredelyayet korrektnyiye kodovyiye intervalyi do izvlecheniya ssyilok i isklyuchayet ikh soderzhimoye bez zamenyi dlinyi stroki, sposobnoj smestitj diagnosticheskiye koordinatyi ostaljnyikh ssyilok.
- Fiksturyi pokryivayut odinarnyiye i mnogosimvoljnyiye ogranichiteli obratnyikh kavyichek, razreshyonnyiye vnutrenniye obratnyiye kavyichki, sosednij obyichnyij tekst i neskoljko intervalov v odnoj stroke.
- Tot zhe ssyilochnyij sintaksis vne kodovogo intervala ostayotsya aktivnyim: vyikhod za korenj, otsutstvuyusjhaya celj i nevernyij registr prodolzhayut davatj zakryityij otkaz s tochnyim fajlom i strokoj.
- Aktivnyiye korrektnyiye ssyilki pered kodovyim intervalom i posle nego prokhodyat i prisutstvuyut v proveryayemom nabore bez propuskov ili povtorov.
- Nezakryityiye i neodnoznachnyiye posledovateljnosti obratnyikh kavyichek poluchayut yavno vyibrannoye i proverennoye povedeniye, kotoroye ne pozvolyayet skryitj nastoyasjhuyu aktivnuyu ssyilku.
- Izmeneniye ogranicheno obsjhim izvlecheniyem ssyilok i ne oslablyayet isklyucheniye fenced-blokov, doslovnogo teksta zaprosov, zapret absolyutnyikh putej, vyikhodov za korenj i registronevernyikh celej.
- Avtonomnyiye testyi svyaznosti, regressionnaya fikstura FUM-SBOJ-0005 i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0005 — Interpretaciya Markdown-ssyilki vnutri strochnogo koda proverkoj svyaznosti](../../Sboi/FUM-SBOJ-0005-interpretaciya-Markdown-ssyilki-vnutri-strochnogo-koda-proverkoj-svyaznosti.md) — osnovaniye `FUM-СБОЙ-0005/ПРОЯВЛЕНИЕ-0001`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:28:57 MSK -->
<!-- content-sha256: sha256:ac57570c47c714fb5efb6fccb37708d3c4555d8096d9399731e7fd53f37fe982 -->
<!-- FUM-MD-RECENCY:END -->
