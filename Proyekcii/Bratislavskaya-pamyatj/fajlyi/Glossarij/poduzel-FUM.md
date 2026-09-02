# Poduzel FUM

Repozitornyiye fork-, worktree-, FIFO-, reviewer-, integrator- i candidate-profili etogo termina yavlyayutsya otlozhennoj celevoj arkhitekturoj. Oni ne zadayut dejstvuyusjhij marshrut zapisi tekusjhego repozitoriya: sejchas poljzovatelj vruchnuyu zapuskayet odnu pishusjhuyu sessiyu v pervichnom checkout `refs/heads/master`, a paralleljnyiye read-only-nablyudateli ne poluchayut prava zapisi.

Poduzel FUM - [FUM-uzel](FUM-uzel.md), rassmatrivayemyij kak vnutrennij uchastnik boleye krupnogo sostavnogo [FUM-uzla](FUM-uzel.md): [gibridnogo uzla](gibridnyij-uzel.md), komandyi, kompanii, robotizirovannoj sistemyi, proizvodstvennoj cepochki ili drugoj seti.

Poduzel mozhet uchastvovatj v obsjhej [pamyati](pamyatj-FUM.md), koordinacii i dejstviyakh sostavnogo uzla, no ne dolzhen polnostjyu ischezatj v nadsisteme. U nego sokhranyayutsya razlichimaya vnutrennyaya oblastj, proiskhozhdeniye reshenij, [urovni dostupa](urovenj-dostupa.md) i [granicyi vlasti](granica-vlasti-FUM.md), kotoryiye ne pozvolyayut sostavnomu uzlu obladatj nad nim totaljnoj vlastjyu.

Yesli poduzel dolzhen sokhranyatj sobstvennyij profilj i istoriyu doljshe otdeljnoj sessii, on mozhet byitj materializovan otdeljnyim fork-repozitoriyem obsjhego upstream yadra FUM. Roditeljskaya [repozitornaya kompoziciya FUM](repozitornaya-kompoziciya-FUM.md) fiksiruyet toljko proverennyij gitlink takogo repozitoriya; rabochaya vetka zhivyot v dochernem klone. [Pishusjhij poduzel FUM](pishusjhij-poduzel-FUM.md) oboznachayet boleye uzkuyu ispolniteljnuyu rolj odnoj izolirovannoj popyitki i ne tozhdestvenen dolgovechnomu poduzlu.

Dlya lokaljnogo paralleljnogo ispolneniya odnogo repozitoriya poduzel mozhet byitj vremenno materializovan pereispoljzuyemyim linked worktree `Подузлы/слот-*`. Obyichnaya sessiya vyibirayet novuyu liniyu, posledovateljnoye prodolzheniye libo read-only-marshrut iz exact committed snapshot planovyikh OID, aktivnyikh linij i ikh FIFO. Novaya `self_line` poluchayet slot lenivo; prodolzheniye cherez dolgovechnyij bilet i CAS handoff sokhranyayet te zhe slot, polnyij ref i worktree; read-only-rabota pisateljskij slot ne zanimayet.

Odin worktree-slot dopuskayet ne boleye odnoj sessii odnovremenno, no mozhet obsluzhitj posledovateljnostj sessij odnoj linii. On pereispoljzuyetsya inoj liniyej toljko posle yeyo terminala, otsutstviya vladeljca i ozhidayusjhikh biletov i dokazannoj chistotyi. Pisatelj, nezavisimyij recenzent i integrator zanimayut raznyiye aktivnyiye slotyi. Ikh checkout i indeksyi razdelenyi, odnako object database, Git common-dir i refs obsjhiye. Exact repo-root-proverka etalonnogo CLI ne dokazyivayet host-perenos Codex Desktop ili otsutstviye avtomaticheskikh chtenij osnovnogo checkout, poetomu eta forma ne nazyivayetsya nativnoj izolyaciyej i ne prevrasjhayet liniyu v dolgovechnyij fork-repozitorij.

Celevoj dolgovechnyij FUM-agent imeyet [universaljnyij ispolniteljnyij profilj](universaljnyij-ispolniteljnyij-poduzel-FUM.md), a specializaciyu vyirazhayet [kontekstnaya rolj](kontekstnaya-rolj-FUM-agenta.md) konkretnogo naznacheniya. Prezhnij mashinnyij vid `specialized_subnode` ostayotsya istoricheskim vidom avtonomnogo prototipa i ne zadayot otdeljnuyu celevuyu kastu agentov. Obsjhij nabor sposobnostej ne otmenyayet granic vlasti: kazhdoye naznacheniye ostayotsya konechnoj delegaciyej, a cepochka sostoit iz otdeljnyikh proveryayemyikh pishusjhikh shagov.

## Svyazannyiye dokumentyi

- [Decentralizaciya FUM i granicyi vlasti](../Dokumentaciya/15-decentralizaciya-i-granicyi-vlasti.md)
- [Gibridnyiye uzlyi i socialjnaya fraktaljnostj](../Dokumentaciya/12-gibridnyiye-uzlyi-i-socialjnaya-fraktaljnostj.md)
- [Moduljnaya arkhitektura FUM](../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md)
- [Repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-13 18:17:47 MSK — Organizovatj paralleljnyiye sessii v lokaljnyikh worktree-poduzlakh](../Zhurnal/2026-08-13_18-17-47_MSK_organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-fork-poduzlakh/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:80efef72879acaa878132418853b6193f722afc409991f3de37390199203995c -->
<!-- FUM-MD-RECENCY:END -->
