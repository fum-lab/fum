# Otchyot 2026-07-25 11:56:07 MSK - Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM

V dolgovremennoj [pamyati FUM](../../Glossarij/pamyatj-FUM.md) zakreplena granica mezhdu neskoljkimi chatami odnoj modeli i [proveryayemyim mnogoagentnyim konturom FUM](../../Glossarij/proveryayemyij-mnogoagentnyij-kontur-FUM.md). Chislo sessij i sovpadeniye ikh otvetov ostayutsya poleznyim sposobom razdelitj ispolniteljskuyu rabotu, no ne schitayutsya nezavisimyim svideteljstvom bez razlichimyikh vkladov, proiskhozhdeniya, vneshnej proverki, pravila vyibora i ostanovki.

Shirokaya realizaciya razlozhena na devyatj zavisimyikh kartochek FUM-STEP-0075–FUM-STEP-0083. Vo vneshnij avtozapusk peredan toljko pervyij kontekstno posiljnyij rezuljtat; ostaljnyiye pokoleniya sokhranyayutsya otlozhennyimi do proverki neposredstvennyikh predshestvennikov.

## Proveryayemaya mnogoagentnostj

Novyij termin i trebovaniye opisyivayut odin ogranichennyij myisliteljnyij epizod cherez obsjhuyu celj i dolgovremennyij artefakt, otlichimyiye roli ili gipotezyi, lokaljnyiye kontekstyi, adresnoye proiskhozhdeniye, otdeljnuyu proverku, sokhranyonnyiye raznoglasiya, vyibor, byudzhetyi i usloviye ostanovki. Povtor odnoj modeli otnesyon k korrelirovannomu vnutrennemu signalu, a ne k vneshnemu podtverzhdeniyu.

[Arkhitektura FUM](../../Dokumentaciya/22-arkhitektura-FUM.md) i [pasport dokumentacionnogo prototipa](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) teperj pryamo otdelyayut dejstvuyusjhikh vneshnikh ispolnitelej Codex ot yesjhyo ne realizovannyikh vnutrennikh poduzlov FUM. Kontekstnoye okno opredeleno kak vremennaya rabochaya oblastj; mezhsessionnoj pamyatjyu schitayutsya toljko sokhranyonnyiye adresuyemyiye artefaktyi.

## Kontekstnaya granica i avtozapusk

Pravila rabochej sessii i lokaljnyij navyik sleduyusjhego shaga vetki trebuyut predpuskovogo analiza vsej kartochki s uchyotom chteniya pravil i istochnikov, fiksacii proiskhozhdeniya, celevyikh proverok, recency, polnogo smoke-check i atomarnoj peredachi. Yesli polnaya sessiya s vyisokoj veroyatnostjyu ne pomesjhayetsya v odno svezheye kontekstnoye okno, ona ogranichivayetsya ustojchivoj dekompoziciyej i ne vyidayot yeyo za zaversheniye iskhodnoj realizacii.

Regressionnyij test zakreplyayet to zhe trebovaniye v shablone heartbeat: dochernyaya zadacha poluchayet kontekstnyij predpuskovoj analiz, a novyij `ready`-slot dopuskayet toljko odin bezopasno ispolnimyij i kontekstno ogranichennyij rezuljtat. Paralleljnyij samodialog ekzemplyarov odnoj modeli ne ispoljzuyetsya dlya maskirovki shirokoj kartochki.

## Realizacionnaya cepochka

[FUM-STEP-0075](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0075-zakrepitj-kontrakt-kontekstno-posiljnogo-rabochego-paketa-FUM.md) sozdayot versionirovannyij rabochij paket i yego avtonomnyij predpuskovoj analiz. Sleduyusjhiye kartochki po odnoj dobavlyayut pasport raspredelyonnogo epizoda, vosstanavlivayemuyu obsjhuyu pamyatj, proiskhozhdeniye i gruppyi korrelyacii, otdeljnuyu proverku i sokhraneniye raznoglasij, vyibor s byudzhetami i ostanovkoj, avtonomnuyu priyomku, zhivoj read-only-progon Codex i vozobnovleniye v novoj sessii toljko iz sokhranyonnoj pamyati.

V [rabochem nabore vetki `master`](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md) FUM-STEP-0075 yavlyayetsya yedinstvennyim kandidatom `ready`, FUM-STEP-0076–FUM-STEP-0083 obrazuyut posledovateljnuyu ocheredj `paused`, a prezhniye FUM-STEP-0008 i FUM-STEP-0035 ne poteryanyi. Eto plan i ispolnyayemaya peredacha, a ne lozhnoye utverzhdeniye, chto sobstvennyij mnogoagentnyij runtime uzhe sozdan.

## Proverki

- Vetochnyij selektor podtverdil validnyij otkryityij nabor, yedinstvennyij `ready` i tochnyiye `card_id`, `step_id`, putj i soderzhateljnyij khyesh FUM-STEP-0075.
- Avtonomnyij nabor `fum-sleduyusjhij-shag-vetki` proshyol `61` test bez oshibok; novyij test snachala nablyudal otsutstviye kontekstnogo predpuskovogo analiza, a posle izmeneniya kontrakta stal zelyonyim.
- Mashinnyij planovyij reyestr peresobran i proshyol sobstvennuyu validaciyu s trebovaniyami FUM-REQ-0022–FUM-REQ-0023 i kartochkami FUM-STEP-0075–FUM-STEP-0083.
- Dva polnyikh avtonomnyikh smoke-check proshli po `58` iz `58` shagov bez seti i vneshnikh effektov; vtoroj progon proveril itogovyij tekst posle fiksacii rezuljtata pervogo.

## Profilj vremeni vyipolneniya

| Stadiya                           | Dliteljnostj  | Granicyi i sposob izmereniya                                                                                                                                                                 |
| -------------------------------- | ------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Registraciya i dopusk FIFO        | ≈ 63 min 54 s | Raznostj sokhranyonnyikh otmetok registracii `2026-07-25T07:49:06Z` i dopuska `2026-07-25T08:53:00Z`; pochti vsyo okno zanyalo ozhidaniye predshestvuyusjhej kornevoj zadachi.                           |
| Issledovaniye, TDD i dokumentaciya |   ne izmereno | Rabota peresekla padeniye host-sessii i shtatnoye vozobnovleniye prezhnego vladeljca; tochnuyu nepreryivnuyu wall-clock-granicu zadnim chislom vosstanovitj neljzya, poetomu ocenka ne podstavlyayetsya. |
| Celevoj nabor testov dispetchera  |       22,43 s | Stenovoye vremya finaljnogo progona `61` testa `fum-sleduyusjhij-shag-vetki`; boleye rannij krasnyij TDD-progon i tochechnaya pereproverka ne summiruyutsya s nim.                                  |
| Pervyij polnyij smoke-check        | 4 min 47,75 s | Uspeshnyij avtonomnyij progon `58` shagov na predfinaljnom tekste; otdeljno uchityivayetsya polnoye stenovoye okno processa, a yego vlozhennyiye testyi ne pribavlyayutsya k profilyu povtorno.               |
| Itogovyij polnyij smoke-check      | 3 min 56,73 s | Povtornyij uspeshnyij progon `58` shagov posle fiksacii rezuljtata pervogo; sborochnyiye kyeshi izmenili dliteljnostj, no ne sostav i iskhod proverok.                                               |

Granica profilya: ot atomarnoj registracii susjhestvuyusjhego FIFO-bileta do zaversheniya itogovogo polnogo smoke-check; neizvestnyij interval padeniya ne ocenivayetsya, a staging i `commit+handoff` sleduyut posle izmerennoj granicyi.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [trebovaniye o proveryayemom mnogoagentnom konture FUM](../../Trebovaniya/🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md)
- [trebovaniye o kontekstno posiljnyikh ispolnyayemyikh shagakh](../../Trebovaniya/🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md)
- [rabochij nabor sleduyusjhego shaga vetki `master`](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:ff271533c29aeebee93f72f5b8e57e1b3cd197cc4a8ce5a1e2a95accc050e007 -->
<!-- FUM-MD-RECENCY:END -->
