# Otchyot 2026-07-21 13:19:18 MSK - Podtverditj dostup k sozdaniyu forkov v FUM lab

Tekusjhaya GitHub-avtorizaciya pozvolyayet sozdavatj v organizacii `fum-lab` forki publichnyikh repozitoriyev. Proverka vyipolnena bez vneshnikh izmenenij: novyij repozitorij ili fork ne sozdavalsya.

## Podtverzhdyonnaya vozmozhnostj

Read-only proverka cherez GitHub CLI i REST API podtverdila, chto tekusjhaya avtorizaciya imeyet dostatochnoye pravo sozdavatj publichnyiye forki v `fum-lab`. Tochnaya uchyotnaya zapisj, rolj chlenstva, atributyi tokena i zakryityiye nastrojki organizacii ne sokhranyayutsya v publichnoj pamyati. Oficialjnyij kontrakt GitHub razreshayet publichnyij fork v organizaciyu, gde u poljzovatelya yestj pravo sozdavatj repozitorii.

Dlya kazhdogo budusjhego forka vsyo ravno trebuyetsya yavno nazvatj iskhodnyij repozitorij i proveritj, chto GitHub razreshayet yego forknutj v organizaciyu. Dlya publichnogo upstream tekusjhego dostupa dostatochno. Dlya privatnogo upstream sozdaniye forka v tekusjhej konfiguracii nedostupno; dlya vnutrennego upstream vozmozhnostj ne podtverzhdena i zavisit ot enterprise-konteksta.

## Granica sessii

Proverka otvechayet toljko na vopros o vozmozhnosti. Ona ne sozdayot fork, ne vyibirayet istochnik, imya i vidimostj repozitoriya, ne kloniruyet zavisimostj i ne menyayet remote ili `.gitmodules`. Uzhe zakreplyonnyij poryadok vneshnikh Git-zavisimostej ostayotsya prezhnim: posle otdeljnogo ukazaniya istochnika postoyannyij fork `fum-lab` dolzhen statj `origin`, a originaljnyij repozitorij — otdeljnyim `upstream`.

## Proverki

- GitHub CLI i REST API podtverdili dostatochnostj tekusjhego dostupa k publichnyim forkam v `fum-lab`, ne raskryivaya privatnoye sostoyaniye v fajlakh sessii.
- Vneshnyaya proverka vyipolnena bez zapisi i bez sozdaniya repozitoriya.
- Oficialjnaya dokumentaciya GitHub podtverzhdayet, chto vladeljcyi organizacii mogut sozdavatj repozitorii nezavisimo ot zapreta dlya obyichnyikh uchastnikov, a privatnyiye forki dopolniteljno ogranichenyi tarifom i politikami.
- Lokaljnaya svyaznostj sessii, recency, graf Obsidian i polnyij smoke-check prokhodyat.

## Zatronutyiye materialyi

- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [sleduyusjhij shag vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros 2026-07-21 13:19:18 MSK](zapros.md)
- [pravilo forkov Git-zavisimostej](../2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/zapros.md)
- [sokhranyonnyiye pravila GitHub o sozdanii repozitoriyev](../../Istochniki/URL/https/docs.github.com/en/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization/source-index.md)
- [sokhranyonnoye opisaniye GitHub prav i vidimosti forkov](../../Istochniki/URL/https/docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-permissions-and-visibility-of-forks/source-index.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:25842f4338d139cb50ffdb23f63c14201d0f93f42d9b8c84bc41e16afcbbfe35 -->
<!-- FUM-MD-RECENCY:END -->
