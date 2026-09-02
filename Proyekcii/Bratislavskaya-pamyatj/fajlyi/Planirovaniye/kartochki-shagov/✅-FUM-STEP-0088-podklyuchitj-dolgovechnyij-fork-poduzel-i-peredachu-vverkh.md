+++
schema_version = 1
card_id = "FUM-STEP-0088"
status = "completed"
+++
# Podklyuchitj dolgovechnyij fork-poduzel i peredachu vverkh

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Na avtonomnyikh lokaljnyikh bare-repozitoriyakh realizovatj registraciyu odnogo dolgovechnogo specializirovannogo poduzla — fork otdeljnogo obsjhego upstream yadra FUM bez grafa zhivyikh ekzemplyarov. Roditeljskaya assembly dolzhna zakrepitj proverennyij commit dochernego repozitoriya kak submodule, a otdeljnyij zhivoj klon poduzla — prodolzhitj sobstvennuyu vetku, sozdatj kandidatnyij commit obsjhej poljzyi, peredatj yego vverkh cherez pasport i posle proverki obnovitj roditeljskij rezuljtat bez rekursivnoj inicializacii samogo sebya.

## Rezuljtat

Avtonomnyij SwiftPM-kontur sozdayot otdeljnyiye lokaljnyiye bare-repozitorii obsjhego yadra, specializirovannogo fork-poduzla i roditeljskoj assembly. Registraciya zakreplyayet ustojchivyiye identichnosti, pasport specializacii, razdeljnyiye `origin` i `upstream`, polnyij zhivoj ref, sobstvennyiye pravila, ocheredj i rabochij nabor sleduyusjhego shaga; proverka dereva yadra zapresjhayet vyidavatj repozitorij s instance-submodules za obsjhij upstream.

Roditeljskaya assembly sokhranyayet obyyavlennyij putj i tochnyij dostizhimyij gitlink. Materializovannyij submodule proveryayetsya kak chistyij detached-snimok, togda kak pishusjhij shag vyipolnyayetsya v otdeljnom zhivom klone, publikuyet kandidatnyij commit v sobstvennuyu vetku fork-poduzla i ostavlyayet roditeljskuyu rabochuyu kopiyu neizmennoj.

Posle nezavisimogo dvizheniya obsjhego yadra yavnaya sinkhronizaciya fork-poduzla trebuyet ozhidayemyiye OID obeikh storon i ne sleduyet za remote avtomaticheski. Zakryityij pasport posleduyusjhej peredachi svyazyivayet opublikovannyij iskhodnyij commit i yego roditelya, oblastj obsjhego uluchsheniya, khyeshirovannyiye proverki, dostup, publikacionnuyu granicu i novuyu tochnuyu roditeljskuyu bazu. Prinyatiye sokhranyayet iskhodnyij kandidat v rodoslovnoj yadra, a obnovleniye gitlink na sinkhronizirovannuyu vershinu vyipolnyayetsya otdeljnyim commit assembly.

Polozhiteljnyij scenarij vosstanavlivayet iz svezhego klona roditelya tochnyij snimok poduzla, a iz novogo zhivogo klona — sokhranyonnuyu vetku i sleduyusjhij shag. Otricateljnyiye scenarii zakryivayut nesovpavshij remote ili OID, ustarevshuyu bazu peredachi, narushennyij dostup i publikacionnuyu granicu, konflikt sinkhronizacii, ssyilku submodule na predka i recursive-init, kotoryij materializoval byi fork vnutri samogo sebya. Vse repozitorii i klonyi vremennyiye i lokaljnyiye; setj, vneshnyaya uchyotnaya zapisj, nastoyasjhij GitHub fork, push i vneshneye razvyortyivaniye ne vyipolnyayutsya.

## Istochniki

- [iskhodnyij zapros 2026-08-04 09:38:47 MSK — Podklyuchitj dolgovechnyij fork-poduzel i peredachu vverkh](../../Zhurnal/2026-08-04_09-38-47_MSK_podklyuchitj-dolgovechnyij-fork-poduzel-i-peredachu-vverkh/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [FUM-STEP-0087 — ogranichennoye avtomaticheskoye razresheniye Git-konfliktov](✅-FUM-STEP-0087-dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:1e3047325795c131518c8109893ed594b81c46a2a3af0b38f12618d1c1923fe7 -->
<!-- FUM-MD-RECENCY:END -->
