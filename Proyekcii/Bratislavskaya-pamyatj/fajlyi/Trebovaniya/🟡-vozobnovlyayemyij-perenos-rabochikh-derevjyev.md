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

Status trebovaniya — `🟡`: pervyij ogranichennyij rezuljtat FUM-STEP-0207 realizovan v [tematicheskom instrumente](../Instrumentyi/fum-perenos-rabochikh-derevjyev/SKILL.md). [Otchyot i vosproizvodimyiye fiksturyi](../Zhurnal/2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/otchyot.md) podtverzhdayut odin linked worktree na odnom tome i rekursivnyiye submodule v macOS arm64. Vozobnovleniye dejstvuyet posle dolgovechnoj ustanovki pervichnogo namereniya; boleye rannij nezavershyonnyij fajl sokhranyayetsya bez peremesjheniya i dayot yavnyij otkaz.

Perenos zhivyikh derevjyev i dopolniteljnyiye platformyi prinimayutsya otdeljnyimi proveryayemyimi srezami. Dlya realjnogo dereva yesjhyo nuzhnyi svezhaya topologiya, podtverzhdyonnyij yedinstvennyij pisatelj, fakticheskij tom, adres naznacheniya, vneshniye privyazki Codex/Obsidian/sborok i proverka otnositeljnyikh payload symlink. Uspeshnaya Git-fikstura ne zakryivayet etot ostatok.

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:03:10 MSK -->
<!-- content-sha256: sha256:deb8db58fb5adfbe089b6941e604b86c04581c7e089e2e9c400e34a1dadbd459 -->
<!-- FUM-MD-RECENCY:END -->
