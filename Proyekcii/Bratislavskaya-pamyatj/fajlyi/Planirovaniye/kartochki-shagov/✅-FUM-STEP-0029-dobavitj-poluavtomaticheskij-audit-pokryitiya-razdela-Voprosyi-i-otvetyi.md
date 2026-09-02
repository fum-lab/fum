+++
schema_version = 1
card_id = "FUM-STEP-0029"
status = "completed"
+++
# Dobavitj poluavtomaticheskij audit pokryitiya razdela Voprosyi i otvetyi/

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj poluavtomaticheskij audit pokryitiya razdela `Вопросы и ответы/`: izvlekatj voprositeljnyiye predlozheniya toljko iz doslovnyikh blokov `## Текст запроса`, sopostavlyatj ikh so ssyilkami na iskhodnyiye zaprosyi v susjhestvuyusjhikh kartochkakh i vyidavatj spisok kandidatov dlya ruchnoj proverki otnosheniya k susjhnosti FUM, soderzhateljnosti otveta i samostoyateljnoj poleznosti.

## Rezuljtat

Sozdana avtonomnaya lokaljnaya avtomatizaciya [fum-audit-pokryitiya-voprosov-i-otvetov](../../Instrumentyi/fum-audit-pokryitiya-voprosov-i-otvetov/SKILL.md). Ona izvlekayet voprositeljnyiye predlozheniya toljko iz doslovnogo payload tochnogo razdela `## Текст запроса`, sopostavlyayet ikh so source-ssyilkami pryamyikh kartochek `Вопросы и ответы/*.md` i vyidayot chelovekochitayemyij libo JSON-spisok vsekh kandidatov s yavnoj ruchnoj proverkoj otnosheniya k susjhnosti FUM, soderzhateljnosti otveta i samostoyateljnoj poleznosti.

Avtonomnyij nabor proshyol `11/11` testov. Na korpuse iz `234` zaprosov audit vyiyavil `10` kandidatov v `9` zaprosakh: tri imeyut ssyilochnoye pokryitiye, semj ne imeyut. Ruchnaya proverka podtverdila polnotu celevogo razdela: nepokryityiye voprosyi yavlyayutsya sluzhebnyimi i ne otnosyatsya neposredstvenno k susjhnosti FUM. Punktuacionnaya vyiborka i request-level ssyilka namerenno ne vyidayutsya za dokazateljstvo voprositeljnoj semantiki ili kachestva konkretnogo otveta.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/zapros.md), [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/otchyot.md)
- [iskhodnyij zapros 2026-07-10 06:46:29 MSK - Dopolnitj voprosyi i otvetyi po vsem zaprosam](../../Zhurnal/2026-07-10_06-46-29_MSK_dopolnitj-voprosyi-i-otvetyi-po-vsem-zaprosam/zapros.md), [iskhodnyij zapros 2026-07-13 15:20:42 MSK - Ogranichitj voprosyi i otvetyi susjhnostjyu FUM](../../Zhurnal/2026-07-13_15-20-42_MSK_ogranichitj-voprosyi-i-otvetyi-susjhnostjyu-FUM/zapros.md), [indeks voprosov i otvetov](../../Voprosyi%20i%20otvetyi/README.md), [fum-svyaznostj-rabochej-sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:4d7ff94da36cc322a3e19ec8e786abf645d597da6632a10bb5c4ad405e12b3f3 -->
<!-- FUM-MD-RECENCY:END -->
