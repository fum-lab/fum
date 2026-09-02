+++
schema_version = 1
card_id = "FUM-STEP-0132"
status = "active"
+++
# Ispravitj razresheniye uglovyikh Markdown-ssyilok planovyim reyestrom

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Ispravitj postroitelj i validator mashinnogo planovogo reyestra tak, chtobyi lokaljnyiye Markdown-adresa v uglovyikh skobkakh razbiralisj tem zhe putyom, chto obyichnyiye adresa, razreshalisj otnositeljno iskhodnogo fajla i prinimalisj toljko pri susjhestvuyusjhej celi s tochnyim registrom vnutri kornya repozitoriya.

## Pochemu sejchas

Audit tekusjhej rabochej sessii obnaruzhil, chto korrektnaya ssyilka `<../../Вопросы и ответы/README.md>` iz FUM-STEP-0114 prevrasjhayetsya v nesusjhestvuyusjhij `target` `Планирование/карточки-шагов/Вопросы и ответы/README.md>`. Shtatnaya validaciya reyestra pri etom zavershayetsya uspeshno. Kanonicheskij Markdown ne povrezhdyon, no proizvodnoye proiskhozhdeniye shagov neljzya schitatj celostnyim do mashinnogo ispravleniya i regressii.

## Kriterii zaversheniya

- Krasnaya avtonomnaya fikstura vosproizvodit tochnuyu uglovuyu ssyilku iz FUM-STEP-0114 i podtverzhdayet odnovremenno nevernuyu proizvodnuyu celj i nyineshnij lozhnyij uspekh validatora.
- Odin razborsjhik lokaljnogo Markdown-adresa korrektno otdelyayet sintaksicheskiye uglovyiye skobki do razresheniya puti; validnaya obyichnaya zapisj s `%20` vmesto probelov i uglovaya zapisj toj zhe celi s syiryimi probelami dayut odinakovoye predstavleniye.
- Adres razreshayetsya otnositeljno kataloga iskhodnoj kartochki, normalizuyetsya v tochnuyu repozitorno-otnositeljnuyu celj `Вопросы и ответы/README.md` i ne sokhranyayet simvol `>` kak chastj puti.
- Probelyi i dopustimyij fragment ssyilki sokhranyayut znacheniye; pustoj adres, nesbalansirovannyiye uglovyiye skobki i inoye sintaksicheskoye povrezhdeniye dayut zakryityij otkaz.
- Validator proveryayet susjhestvovaniye, tochnyij registr kazhdogo komponenta i nakhozhdeniye lokaljnoj celi vnutri kornya repozitoriya; otsutstvuyusjhij, registronevernyij i obkhodyasjhij korenj putj otklonyayutsya.
- Mashinnyij reyestr peresobran iz kanonicheskikh kartochek, oba oshibochnyikh `source_links` ispravlenyi, a povtornaya sborka ne menyayet rezuljtat.
- Avtonomnyiye testyi postroitelya i validatora, proverka planovogo reyestra i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0004 — Nevernoye razresheniye uglovoj Markdown-ssyilki planovyim reyestrom](../../Sboi/FUM-SBOJ-0004-nevernoye-razresheniye-uglovoj-Markdown-ssyilki-planovyim-reyestrom.md) — osnovaniye `FUM-СБОЙ-0004/ПРОЯВЛЕНИЕ-0001`
- [FUM-STEP-0114 s vosproizvodyasjhej ssyilkoj](🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya planovogo reyestra](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:15:38 MSK -->
<!-- content-sha256: sha256:f26636a7326dd426a559e495c8e6092c484d3e18530a5b5e34f9f397f118b25f -->
<!-- FUM-MD-RECENCY:END -->
