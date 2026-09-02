+++
schema_version = 1
card_id = "FUM-STEP-0106"
status = "completed"
+++
# Zakrepitj neblokiruyusjheye modeljnoye vetvleniye pri ozhidanii podtverzhdeniya

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj versionirovannyij kontrakt i polnostjyu lokaljnuyu determinirovannuyu fiksturu odnogo agentskogo epizoda, v kotorom podtverzhdayemyij vneshnij perekhod ostayotsya zakryityim, a bezopasnaya model-only-chastj razvorachivayet i prorabatyivayet dve razlichimyiye vetvi ot obsjhego tochnogo predka, proveryayet ikh i sokhranyayet vnutrennij vyibor nezavisimo ot poljzovateljskogo dopuska.

## Rezuljtat

[Minimaljnyij format trassyi](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) poluchil otdeljnuyu [skhemu sobyitiya versii `3`](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v3.json): staryiye skhemyi i fiksturyi ostalisj pobajtovo neizmennyimi. Versiya `3` nezavisimo fiksiruyet sostoyaniya epizoda, modeljnoj vetvi, ozhidayusjhego perekhoda i vneshnego ispolneniya. Vnutrennij otbor ostayotsya `candidate_only` i ne podmenyayet poljzovateljskij dopusk.

Tri JSONL-fiksturyi pokryivayut [dve model-only-vetvi pri zakryitom perekhode](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-neblokiruyusjhego-modeljnogo-vetvleniya-v3.jsonl), [pozdneye tochnoye podtverzhdeniye s vyiborom sokhranyonnoj aljternativyi](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-pozdnego-podtverzhdeniya-perekhoda-v3.jsonl) i [odnu vetvj pri ischerpannom byudzhete](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-odnoj-vetvi-pri-ogranichennom-byudzhete-v3.jsonl). Pozdnij otvet svyazan s tochnyim obyyektom i versiyej perekhoda, yavnyim dopuskom vkhoda i ssyilkoj na politiku priyoma. Ustarevshij otvet, otkaz i otzyiv razlichayutsya validatorom; otkaz i otzyiv annuliruyut zavisimuyu cepochku, a `authorized`, `preflight_passed`, `executed` i `observed` trebuyut otdeljnyikh tipizirovannyikh vneshnikh svideteljstv i ne vyivodyatsya iz modeljnogo vyibora ili podtverzhdeniya.

[Lokaljnyij determinirovannyij validator](../../Instrumentyi/fum-proverka-trassyi-agentskogo-cikla/SKILL.md) i avtonomnyiye testyi prinimayut polozhiteljnyiye fiksturyi i otklonyayut ispolneniye bez nezavisimyikh svideteljstv, povyisheniye kandidata do dopuska ili kanonicheskogo sostoyaniya, nepolnyiye vetvi i nezavisimo zadannuyu politiku khraneniya, nesovpadeniye itogovyikh i kontroljnyikh schyotchikov, zapisj posle ostanovki, prezhdevremennyiye `unresolved_conflict` i `needs_input`, lozhnoye snyatiye neodnoznachnosti i skryityiye rassuzhdeniya ili vneshniye zavisimosti. Rezuljtat ogranichen versionirovannyim kontraktom, lokaljnyimi fiksturami, validatorom, testami i dokumentirovannoj granicej: on ne realizuyet realjnyij modeljnyij provajder, GUI, dolgovremennyij fonovyij runtime, zhivoye vneshneye dejstviye, novyiye polnomochiya, setj, sekretyi ili integraciyu kandidatnogo kommita i ne vyidayotsya za skvoznoj runtime FUM.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-07-29_14-32-38_MSK_zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye/zapros.md)
- [trebovaniye ob avtonomnom modeljnom prodolzhenii pri ozhidanii podtverzhdeniya](../../Trebovaniya/🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)
- [FUM-STEP-0072 — perenapravleniye agentskogo cikla poljzovateljskim vvodom](✅-FUM-STEP-0072-opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom.md)
- [FUM-STEP-0024 — shablon scenariya modeljnoj sredyi](✅-FUM-STEP-0024-opisatj-shablon-scenariya-modeljnoj-sredyi.md)
- [zhurnal tekusjhej sessii](../../Zhurnal/2026-07-29_14-32-38_MSK_zakrepitj-neblokiruyusjheye-modeljnoye-vetvleniye/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:5d1969681ec9cb2b571217f207ef365385479a11534bca7cad285f65048be212 -->
<!-- FUM-MD-RECENCY:END -->
