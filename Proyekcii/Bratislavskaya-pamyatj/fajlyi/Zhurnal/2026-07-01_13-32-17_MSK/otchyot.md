# Otchyot 2026-07-01 13:32:17 MSK

## Glavnoye

Podgotovlen mashinno chitayemyij sloj planirovaniya FUM: JSON-reyestr [trebovanij, variantov realizacii i kandidatov](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json), kotoryij mozhno peresobiratj i proveryatj iz tekusjhikh planovyikh Markdown-istochnikov.

## Chto izmenilosj

- Sozdana avtomatizaciya [fum-planning-registry](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md) so skriptom sborki i validacii.
- Dobavlen JSON-reyestr so skhemoj `fum.planning.requirements-registry.v1`: trebovaniya, variantyi realizacii, kandidatyi, statusyi, dorozhnyiye gorizontyi, napravleniya, MVP-kandidatyi, predlozheniya i voprosyi.
- [Planirovaniye/README.md](../../Planirovaniye/README.md), [svodnaya tablica](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md), [Instrumentyi/README.md](../../Instrumentyi/README.md) i [reyestr instrumentov](../../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) teperj ssyilayutsya na novyij sloj i komandu proverki.
- Predlozheniye o mashinno chitayemom reyestre pereneseno v istoriyu vyipolnennyikh v [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md).

## Resheniya

Reyestr sdelan determinirovannyim: v nyom net tekusjhego vremeni sborki, zato yestj khyeshi iskhodnyikh Markdown-fajlov bez sluzhebnyikh recency-blokov. Eto pozvolyayet komande `validate` sravnivatj sokhranyonnyij JSON s rezuljtatom novoj sborki i lovitj ustarevaniye posle izmeneniya planovyikh istochnikov.

Smyislovyiye trebovaniya po-prezhnemu ostayutsya v Markdown-dokumentakh. JSON ne vvodit novyiye trebovaniya, a normalizuyet uzhe zapisannuyu svodnuyu tablicu i istochnikovyij inventarj, chtobyi budusjhiye proverki mogli rabotatj s planirovaniyem programmno.

## Proverki

Lokaljnyiye testyi vsekh instrumentov iz `Инструменты/README.md` proshli yavnyimi komandami po katalogam. Reyestr byil peresobran komandoj `build` i proveren komandoj `validate`; zatem proshli obnovleniye i proverka recency-metok, a takzhe obsjhaya proverka svyaznosti rabochej sessii.

## Vozmozhnyiye prodolzheniya

Sleduyusjhij sloj mozhet ispoljzovatj JSON-reyestr dlya otchyota o pokryitii: kakiye otkryityiye voprosyi yesjhyo ne svyazanyi s trebovaniyami, kakiye napravleniya ne imeyut aktivnogo kandidata, kakiye predlozheniya davno aktualjnyi bez dvizheniya i kakiye stroki svodnoj tablicyi menyalisj posle poslednej sborki.

## Istochniki

- [iskhodnyij zapros 2026-07-01 13:32:17 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:7a5c340b593e07f73a55a4e5af7f5cfa243c236bad028f059453a8d21e900523 -->
<!-- FUM-MD-RECENCY:END -->
