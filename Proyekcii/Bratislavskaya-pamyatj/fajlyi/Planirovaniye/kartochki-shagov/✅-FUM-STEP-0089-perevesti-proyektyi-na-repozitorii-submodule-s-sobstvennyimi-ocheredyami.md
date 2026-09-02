+++
schema_version = 1
card_id = "FUM-STEP-0089"
status = "completed"
+++
# Perevesti proyektyi na repozitorii-submodule s sobstvennyimi ocheredyami

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zakrepitj i realizovatj kontrakt, po kotoromu kazhdyij novyij samostoyateljnyij proyekt FUM yavlyayetsya otdeljnyim Git-repozitoriyem, podklyuchyonnyim k roditeljskoj pamyati kak submodule. Proyekt dolzhen khranitj sobstvennyij pasport, pravila, ocheredj zapisi i rabochij nabor sleduyusjhego shaga v svoyom repozitorii; roditelj khranit toljko zapisj kompozicii, tochnyij gitlink i marshrut polucheniya rezuljtata. Avtonomnaya fikstura dolzhna sozdatj proyekt, vyipolnitj v yego klone odin shag i proveryayemo obnovitj gitlink roditelya.

## Rezuljtat

Pravila i indeks proyektov zakreplyayut otdeljnyij Git-repozitorij i submodule dlya kazhdogo novogo samostoyateljnogo proyekta. V dochernem repozitorii chitayemyij kornevoj `README.md` svyazan s zakryityim mashinnyim pasportom, kotoryij khranit celj, sobstvennuyu repozitornuyu identichnostj, polnyij ref, dostup, publikacionnuyu granicu, istochniki, proverki, usloviye zaversheniya i puti sobstvennogo upravlyayusjhego kontura. Tochnyij prinyatyij kommit ne sozdayot samossyilku v dochernem pasporte: yego khranit uzkaya roditeljskaya registraciya ryadom s gitlink.

Avtonomnaya SwiftPM-fikstura sozdayot toljko vremennyiye lokaljnyiye bare-repozitorii proyekta i roditelya. Roditeljskaya registraciya soderzhit vid `project`, putj submodule, URL, polnyij ref, tochnyij gitlink, dostup, proverki i marshrut peredachi, no ne dubliruyet celj, kartochku, ocheredj, claim ili rabochij nabor rebyonka. Ocheredj, claim i dispetcher zapusjhenyi iz fizicheskogo proyektnogo checkout odnovremenno s zanyatyim roditeljskim konturom; ikh sluzhebnyiye ssyilki razlichayutsya i ne popadayut v bare-repozitorii.

Odin proyektnyij shag sozdayot commit v otdeljnom zhivom klone i CAS-obnovlyayet toljko proyektnuyu vetku, poka roditeljskaya vershina ostayotsya neizmennoj. Posle proverki roditelj otdeljnyim CAS-kommitom soglasovanno menyayet rovno gitlink i pole tochnoj revizii v registracionnoj zapisi. Zatem zhivoj ref proyekta namerenno prodvigayetsya yesjhyo odnim neprinyatyim commit: svezhij roditeljskij klon vsyo ravno chitayet prezhniye rezhim `160000`, tochnyij OID i otnositeljnyij marshrut bez materialization, a yavnaya nerekursivnaya inicializaciya vosstanavlivayet chistyij detached-snimok imenno prinyatoj revizii.

Zakryityij validator registracii otklonyayet povtornyiye i neizvestnyiye klyuchi na urovnyakh obolochki, proyekta, marshruta peredachi i vlozhennyikh submodule, a takzhe nevernyiye znacheniya polnogo kompozicionnogo kontrakta. Otricateljnyiye scenarii zakryivayut obyichnyij vlozhennyij katalog, otsutstviye pasporta, otsutstviye sleduyusjhego shaga, obsjhij checkout, nevernyij gitlink, repozitornyij cikl i nedostupnuyu publikacionnuyu granicu do nepredusmotrennogo dvizheniya ssyilok; posledniye dva trebuyut tochnyikh kodov `repository_cycle` i `incompatible_access`. Postavka ne sozdayot realjnyij proyektnyij submodule, vneshnij remote, setevoj dostup ili publikaciyu; sovmestnaya priyomka s dolgovechnyim fork-poduzlom otdeljno zavershena v [FUM-STEP-0090](✅-FUM-STEP-0090-provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii.md).

## Istochniki

- [iskhodnyij zapros 2026-08-04 17:51:27 MSK — Perevesti proyektyi na repozitorii submodule s sobstvennyimi ocheredyami](../../Zhurnal/2026-08-04_17-51-27_MSK_perevesti-proyektyi-na-repozitorii-submodule-s-sobstvennyimi-ocheredyami/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [FUM-STEP-0088 — dolgovechnyij fork-poduzel i peredacha vverkh](✅-FUM-STEP-0088-podklyuchitj-dolgovechnyij-fork-poduzel-i-peredachu-vverkh.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:281bc4fa237d85824c62f646e72e30737b5f16e1292ed466454d6c0217f611aa -->
<!-- FUM-MD-RECENCY:END -->
