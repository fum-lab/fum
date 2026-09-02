# Otchyot 2026-06-25 18:59:22 MSK

## Glavnoye

V pravilakh [pamyati FUM](../../Glossarij/pamyatj-FUM.md) zakrepleno yavnoye ispoljzovaniye bukvyi `ё` v russkoyazyichnoj dokumentacii, sluzhebnyikh poyasneniyakh, glossarnyikh terminakh i russkikh imenakh fajlov. Posle etogo vsya tekusjhaya pamyatj byila privedena k etomu pravilu, krome doslovnyikh blokov iskhodnyikh poljzovateljskikh zaprosov, kotoryiye po pravilam repozitoriya sokhranyayutsya bez ispravlenij.

## Chto izmenilosj

- V [AGENTS.md](../../AGENTS.md) dobavleno pravilo: tam, gde `ё` nuzhna po orfografii, yeyo neljzya zamenyatj na `е`.
- Russkoyazyichnyiye Markdown-materialyi, lokaljnyiye navyiki i proverochnyiye stroki avtomatizacij privedenyi k yavnomu napisaniyu `ё`.
- Pereimenovanyi fajlyi glossariya i dokumentacii, gde `ё` byila chastjyu ustojchivogo termina: vosproizvedyonnyij rezuljtat, mezhzvyozdnoye rasseleniye, obobsjhyonnyij darvinovskij algoritm i obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej.
- Ssyilki na pereimenovannyiye materialyi obnovlenyi po [pamyati FUM](../../Glossarij/pamyatj-FUM.md).
- Adresnyiye opisaniya v `Описания/` peresobranyi orfograficheski cherez yavnyij vyizov deklarativnoj avtomatizacii [postroyeniya opisaniya FUM dlya adresata](../../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md): soderzhaniye i istochnikovyiye tezisyi sokhranenyi, izmenyon toljko sloj russkoj orfografii.

## Resheniya

Bloki `## Текст запроса` v fajlakh `Запросы/` ne normalizovalisj: dazhe yesli v iskhodnom poljzovateljskom tekste stoit `е` tam, gde v proizvodnoj dokumentacii teperj nuzhna `ё`, pervichnyij istochnik ostayotsya doslovnyim.

Izmeneniya v lokaljnyikh avtomatizaciyakh ogranichenyi poljzovateljski vidimyimi russkimi strokami, testovyimi ozhidaniyami i sluzhebnyimi instrukciyami. Proverochnyiye kontraktyi obnovlenyi vmeste s kodom, chtobyi novyiye otchyotyi i istochniki sozdavalisj uzhe s bukvoj `ё`.

## Proverki

- `python3 Инструменты/fum-doc-aggregation/tests/test_build_doc_aggregation.py` - proshlo.
- `python3 Инструменты/fum-request-materials/tests/test_archive_chatgpt_share.py` - proshlo.
- `python3 Инструменты/fum-session-coherence/tests/test_check_session_coherence.py` - proshlo.
- `git diff --check` - proshlo bez zamechanij.
- `all markdown links ok: 245 files` - proverka Markdown-ssyilok cherez `validate_markdown_links` proshla.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-25_18-59-22_MSK.md` - proshlo.
- Poisk tipichnyikh propusjhennyikh form s obyazateljnoj `ё` ostavil toljko doslovnuyu citatu iskhodnogo zaprosa 2026-06-22 08:22:06 MSK.

## Vozmozhnyiye prodolzheniya

Otdeljnyim sleduyusjhim shagom mozhno sdelatj lokaljnuyu orfograficheskuyu proverku dlya budusjhikh rabochikh sessij, no v etoj sessii novoye predlozheniye ne dobavlyalosj: tekusjhij zapros byil vyipolnen kak razovaya normalizaciya pamyati i pravilo dlya daljnejshej rabotyi.

## Istochniki

- [iskhodnyij zapros 2026-06-25 18:59:22 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:767a401ea47b82a5a98fc3b242636c96638e2d1aa791a3e83b6ea4b471dfd8cc -->
<!-- FUM-MD-RECENCY:END -->
