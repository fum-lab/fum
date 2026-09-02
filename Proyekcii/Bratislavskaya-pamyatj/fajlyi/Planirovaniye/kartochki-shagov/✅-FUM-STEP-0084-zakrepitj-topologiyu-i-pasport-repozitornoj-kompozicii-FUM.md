+++
schema_version = 1
card_id = "FUM-STEP-0084"
status = "completed"
+++
# Zakrepitj topologiyu i pasport repozitornoj kompozicii FUM

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj prototip proveryayemogo mnogoagentnogo kontura versionirovannyim mashinochitayemyim pasportom repozitornoj kompozicii. Pasport dolzhen razlichatj roditeljskij repozitorij, efemernuyu vetku shaga, dolgovechnyij specializirovannyij poduzel i samostoyateljnyij proyekt; zakreplyatj tochnyiye Git OID, polnyij zhivoj ref dochernej linii, putj i gitlink submodule, granicyi dostupa, proverki i marshrut peredachi vverkh. Avtonomnyij validator dolzhen otdeljno dokazyivatj, chto gitlink yavlyayetsya snimkom commit, a ne zhivoj vetkoj, i zakryivatjsya otkazom pri cikle repozitornyikh identichnostej ili ssyilke dochernego submodule na predka.

## Rezuljtat

V prototip dobavlena zakryitaya JSON Schema pasporta repozitornoj kompozicii versii `1`. Roditeljskij repozitorij opisyivayetsya otdeljno, a tri varianta dochernej linii razlichayut efemernuyu `step_branch`, dolgovechnyij `specialized_subnode` i samostoyateljnyij `project`. Dlya kazhdogo varianta skhema trebuyet toljko primenimyiye polya i zakreplyayet ustojchivyiye URI-identichnosti bez mashinno-lokaljnoj skhemyi `file`, tochnyiye OID, polnyij zhivoj ref, dostup, publikacionnuyu granicu, proverki i marshrut peredachi vverkh.

Avtonomnyij preflight proveryayet obyyavlennyiye commit i ref cherez Git plumbing v lokaljnyikh bare-repozitoriyakh. Dlya specializirovannogo poduzla i proyekta on otdeljno sveryayet cepochku ot bazyi cherez gitlink k live-ref, gitlink rezhima `160000` i `.gitmodules` v tochnom roditeljskom snimke, nerekursivno vosstanovlennyij detached HEAD i chistotu snimka, a takzhe otdeljnyij Git common-dir, origin, simvolicheskij HEAD i OID pishusjhego klona. Zhivaya vershina dochernej vetki namerenno ukhodit vperyod prinyatogo gitlink i tem samyim dokazyivayet, chto gitlink ostayotsya snimkom commit, a ne avtomaticheski dvizhusjhejsya vetkoj.

Polozhiteljnaya i semj otricateljnyikh fikstur bez seti vosproizvodyat specializirovannyij fork, nezavisimyij proyekt, efemernuyu vetku, tochnoye vosstanovleniye gitlink, nesovmestimyij dostup, otsutstvuyusjhuyu reviziyu, povtoryi identichnosti i puti, ssyilku na predka, cikl i samorekursivnuyu topologiyu nastoyasjhimi dochernimi Git-derevjyami. Nablyudayemyij graf ne doveryayet odnomu JSON: skryitiye deklarativnogo rebra ne maskiruyet cikl. Narusheniya vozvrasjhayutsya kak deduplicirovannyij sortirovannyij mashinochitayemyij otchyot. README i bezokonnyij probnik fiksiruyut komandyi i granicu postavki: pishusjhij ispolnitelj, kandidatnyij commit, integraciya vverkh, obnovleniye nastoyasjhego gitlink i sozdaniye vneshnego GitHub-repozitoriya ne vyipolnyayutsya.

## Istochniki

- [iskhodnyij zapros tekusjhej realizacii](../../Zhurnal/2026-08-03_08-48-44_MSK_zakrepitj-topologiyu-i-pasport-repozitornoj-kompozicii-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)
- [trebovaniye o repozitornoj kompozicii dolgovechnyikh poduzlov i proyektov](../../Trebovaniya/✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md)
- [FUM-STEP-0083 — vozobnovleniye raspredelyonnogo progona iz pamyati](✅-FUM-STEP-0083-vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 02:54:58 MSK -->
<!-- content-sha256: sha256:55043eff4de574b744b5abb2473c33b5447d317951501df637c279165090b52f -->
<!-- FUM-MD-RECENCY:END -->
