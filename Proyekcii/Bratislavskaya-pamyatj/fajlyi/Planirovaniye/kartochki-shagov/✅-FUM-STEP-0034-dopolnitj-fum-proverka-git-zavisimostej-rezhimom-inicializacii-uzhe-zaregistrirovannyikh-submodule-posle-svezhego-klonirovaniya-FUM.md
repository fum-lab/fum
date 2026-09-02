+++
schema_version = 1
card_id = "FUM-STEP-0034"
status = "completed"
+++
# Dopolnitj fum-proverka-git-zavisimostej rezhimom inicializacii uzhe zaregistrirovannyikh submodule posle svezhego klonirovaniya FUM

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dopolnitj `fum-proverka-git-zavisimostej` rezhimom inicializacii uzhe zaregistrirovannyikh submodule posle svezhego klonirovaniya FUM: vosstanovitj `upstream` iz otslezhivayemogo `fumUpstream`, poluchitj oba remote, vyibratj gitlink i zatem vyipolnitj tu zhe avtonomnuyu proverku.

## Rezuljtat

Rezhim `init` vosstanavlivayet uzhe zaregistrirovannyij submodule posle svezhego klonirovaniya: strogo chitayet URL forka i `fumUpstream` iz sovpadayusjhej s Git-indeksom `.gitmodules`, vyibirayet tochnyij kommit iz gitlink, do materializacii proveryayet rabochij putj i kanonicheskij Git-katalog, poluchayet `origin` i `upstream` s prune, ostavlyayet chistyij detached HEAD i zavershayet tem zhe avtonomnyim validatorom, chto i `check`. Avtonomnyiye fiksturyi podtverzhdayut kak `clone --recurse-submodules`, tak i obyichnyij clone bez materializovannoj zavisimosti.

Rezhim ogranichen odnim yavno vyibrannyim verkhneurovnevyim submodule. On mozhet obrasjhatjsya k seti, no ne registriruyet novuyu zavisimostj, ne menyayet `.gitmodules` ili gitlink, ne vyibirayet novuyu reviziyu po vershinam remote i ne dokazyivayet vneshneye sostoyaniye forka, licenziyu ili publikacionnuyu dopustimostj. Raskhozhdeniye proveryayemogo lokaljnogo sostoyaniya ostanavlivayet inicializaciyu bez molchalivoj perezapisi.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/zapros.md), [zhurnal tekusjhej sessii](../../Zhurnal/2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/otchyot.md), [avtomatizaciya Git-zavisimostej](../../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md), [pasport zavisimostej](../../Zavisimosti/README.md)
- [iskhodnyij zapros o klonirovanii](../../Zhurnal/2026-07-21_11-06-43_MSK_zakrepitj-klonirovaniye-vneshnikh-repozitoriyev/zapros.md), [iskhodnyij zapros o forkakh](../../Zhurnal/2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/zapros.md), [zhurnal](../../Zhurnal/2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/otchyot.md), [pravila repozitoriya](../../AGENTS.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:32215e6c252284ec33cbffbedf1f292277ac5f6874582894871a187dec1543d8 -->
<!-- FUM-MD-RECENCY:END -->
