# Vozobnovlyayemyij perenos rabochikh derevjyev

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0066 -->

FUM dolzhen podderzhivatj sokhranyayemyij i vozobnovlyayemyij perenos rabochikh derevjyev s vlozhennyimi Git-repozitoriyami, sokhranyaya ikh identichnosti, versii, indeksyi i lokaljnyiye dannyiye. Izmeneniye fizicheskogo razmesjheniya dolzhno imetj proveryayemyij plan i yavnuyu granicu izmenyayemyikh privyazok.

## Semanticheskiye svyazi

- **dopolnyayet:** [repozitornuyu kompoziciyu dolgovechnyikh poduzlov i proyektov](✅-repozitornaya-kompoziciya-dolgovechnyikh-poduzlov-i-proyektov.md) — fizicheskoye peremesjheniye sokhranyayet identichnosti i zakreplyonnyiye versii vlozhennyikh repozitoriyev; istoricheskiye sposobyi avtomaticheskogo ispolneniya ne vozobnovlyayutsya.

## Kriterii proverki

- Plan bez zapisi fiksiruyet iskhodnyiye identichnosti, ozhidayemyiye OID, refs, indeksyi, topologiyu vlozhennyikh repozitoriyev i konechnyiye marshrutyi; yego primeneniye trebuyet sovpadayusjhego fakticheskogo sostoyaniya i podtverzhdyonnogo vladeniya.
- Perenos sokhranyayet otslezhivayemyiye, neotslezhivayemyiye i ignoriruyemyiye dannyiye. Katalogi ne zamenyayutsya peresozdannyimi checkout; chuzhoye naznacheniye ne perezapisyivayetsya.
- Sokhranyonnyiye fazyi pozvolyayut prodolzhitj posle preryivaniya otdeljnyim processom; tochnyij povtor zavershyonnoj operacii ne peremesjhayet derevo zanovo.
- Proveryayemyij remont Git-privyazok sokhranyayet HEAD, polnyij ref, indeks i identichnostj common-dir kazhdogo perenosimogo repozitoriya i ne menyayet sosedniye rabochiye derevjya.
- Otkazyi okhvatyivayut izmenivshijsya istochnik, zanyatuyu celj, nevernoye vladeniye i nebezopasnyiye puti. Otkryityiye fiksturyi podtverzhdayut granicyi podderzhki i vosstanovleniye posle preryivaniya.
- Privyazki vneshnego prilozheniya proveryayutsya otdeljno ot Git. Neizvestnyij sposob ikh izmeneniya sokhranyayet ogranicheniye i ne zamenyayetsya pryamoj pravkoj sluzhebnoj bazyi.

## Status i granicyi

Status trebovaniya — `🟡`: perenos soglasovan k realizacii. Pervyij ogranichennyij rezuljtat zadayot FUM-STEP-0207: odin linked worktree v predelakh odnogo toma, rekursivnyiye submodule i avtonomnyiye fiksturyi. Perenos zhivyikh derevjyev i dopolniteljnyiye platformyi prinimayutsya otdeljnyimi proveryayemyimi srezami.

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:577fb1f9dd80d9f5b7f1f78afbbe487261fd72dee7437dd7d225480a95672ae3 -->
<!-- FUM-MD-RECENCY:END -->
