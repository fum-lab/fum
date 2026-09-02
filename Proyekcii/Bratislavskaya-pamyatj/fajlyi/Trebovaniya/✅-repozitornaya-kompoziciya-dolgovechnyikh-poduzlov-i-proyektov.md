# Repozitornaya kompoziciya dolgovechnyikh poduzlov i proyektov

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0027 -->

Ekspluatacionnyij status: sokhranyonnyij iskhodnyij srez i celevaya arkhitektura. Yego istoricheskiye submodule, otdeljnyiye repozitorii, FIFO i marshrutyi peredachi ne yavlyayutsya dejstvuyusjhim sposobom obyichnoj zapisi tekusjhego repozitoriya i ne sozdayutsya avtomaticheski.

Zavershyonnyij iskhodnyij srez repozitornoj kompozicii registriruyet dolgovechnyij specializirovannyij poduzel i samostoyateljnyij proyekt kak otdeljnyiye Git-repozitorii s sobstvennyimi liniyami razvitiya, a v roditeljskoj pamyati svyazyivayet ikh cherez Git submodule na tochnom proverennom commit. Dolgovechnaya vetka zhivyot v dochernem repozitorii; gitlink roditelya yavlyayetsya vosproizvodimyim snimkom, a ne avtomaticheski dvizhusjhejsya ssyilkoj na vetku. Mashinnyij vid `specialized_subnode` sokhranyayet tochnoye istoricheskoye znacheniye skhemyi versii `1` i avtonomnyikh fikstur FUM-REQ-0027, no ne zadayot celevoj vid ili otdeljnuyu kastu FUM-agentov: universaljnyij ispolniteljnyij profilj, kontekstnaya rolj i otdeljnyiye polnomochiya razvivayutsya posleduyusjhim FUM-REQ-0036.

## Semanticheskiye svyazi

- **zavisit ot:** [izolirovannogo paralleljnogo ispolneniya i proveryayemoj integracii](✅-izolirovannoye-paralleljnoye-ispolneniye-i-proveryayemaya-integraciya.md) — dochernij repozitorij peredayot vverkh adresuyemyij commit ili proverennoye obnovleniye gitlink cherez obsjhij integracionnyij kontrakt.
- **trebuyetsya dlya:** [upravlyayemogo ispolneniya cepochek universaljnyimi fork-poduzlami](🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md) — dolgovechnyij ispolnitelj predstavlen prinyatyim gitlink-snimkom, a yego zhivaya vetka, FIFO i obyazateljnoye prodolzheniye ostayutsya v otdeljnom dochernem klone.

## Kriterii proverki

- istoricheskij roditeljskij pasport kompozicii versii `1` khranit ustojchivuyu identichnostj dochernego uzla, vid `specialized_subnode` ili `project`, putj submodule, URL repozitoriya, tochnyij gitlink, polnyij rabochij ref, granicyi dostupa i publikacii, proverki i marshrut peredachi vverkh; registraciya proyekta nakhoditsya v kataloge `Проекты/регистрации/` i ne dubliruyet celj, zadachu, pravila, FIFO, kvitancii prodolzheniya, kartochku ili rabochij nabor selector dochernego repozitoriya;
- repozitorij istoricheskoj specializirovannoj fiksturyi yavlyayetsya fork otdeljnogo obsjhego upstream yadra FUM bez grafa zhivyikh ekzemplyarov, sokhranyayet specializaciyu i sobstvennuyu vetku i ne nasleduyet assembly, sposobnuyu soslatjsya na nego samogo; samostoyateljnyij proyekt imeyet otdeljnuyu repozitornuyu identichnostj i ne obyazan byitj fork vsej pamyati;
- samostoyateljnyij proyekt khranit v korne chelovekochitayemyij `README.md` i svyazannyij zakryityij mashinnyij `Паспорт-проекта.json` s celjyu, identichnostyami, adresom repozitoriya, polnyim ref, granicami dostupa i publikacii, putyami pravil i upravlyayusjhikh materialov, khyeshem rabochego nabora, istochnikami, proverkami i usloviyem zaversheniya; dochernij pasport ne soderzhit OID vklyuchayusjhego yego kommita ili gitlink na sebya, potomu chto tochnyij prinyatyij OID prinadlezhit toljko roditeljskoj registracii i derevu;
- do materializacii roditelj proveryayet registraciyu, `.gitmodules`, rezhim dereva `160000`, tochnyij gitlink i dostizhimostj commit, ne vyibiraya vershinu zhivoj vetki; yavno materializovannyij submodule ostayotsya chistyim detached-snimkom zakreplyonnogo commit, togda kak pishusjhaya rabota vyipolnyayetsya v otdeljnom zhivom klone dochernego repozitoriya;
- kazhdyij dochernij repozitorij imeyet sobstvennyiye pravila, ocheredj zapisi, obyazateljnoye prodolzheniye vetki i rabochij nabor pryamogo selector; oni vyichislyayut sluzhebnyiye refs iz fizicheskogo checkout i yego Git common-dir, a sostoyaniye FIFO, kvitancii prodolzheniya ili checkout roditelya ne vyidayotsya za koordinaciyu dochernego klona i ne perenositsya cherez bare-repozitorij;
- obnovleniye dochernej vetki ne menyayet roditelj avtomaticheski: novyij commit snachala zakreplyayetsya i proveryayetsya v dochernem repozitorii, zatem roditelj pri sovpavshikh ozhidayemyikh vershine, prezhnem gitlink i novoj dochernej vershine otdeljnyim odnoroditeljskim CAS-kommitom obnovlyayet toljko gitlink i soglasovannuyu registraciyu; konflikt, ustarevshaya vershina ili proigrannyij CAS ne razreshayutsya resolver-vyiborom i ne dvigayut celevoj ref;
- peredacha obsjhego uluchsheniya vverkh sokhranyayet proiskhozhdeniye, proverki, urovenj dostupa i iskhodnyij commit i ne perenosit privatnuyu pamyatj libo proyektnyiye materialyi bez razresheniya;
- avtonomnyij proyektnyij scenarij otklonyayet obyichnyij katalog vmesto gitlink, otsutstviye mashinnogo pasporta ili rabochego nabora sleduyusjhego shaga, obsjhij checkout s roditelem, nevernyij gitlink, cikl repozitornoj kompozicii i nedostupnuyu publikacionnuyu granicu, ne dopuskaya neozhidannogo dvizheniya refs; obsjhij validator takzhe otklonyayet ssyilku submodule na predka, povtor puti ili identichnosti i rekursivnuyu inicializaciyu, sposobnuyu vlozhitj repozitorij v samogo sebya;
- urovenj dostupa dochernego repozitoriya sovmestim s roditelem: publichnaya kompoziciya ne obyyavlyayetsya vosproizvodimoj pri nedostupnom privatnom submodule;
- svezhij klon roditelya do materialization vosstanavlivayet tochnuyu zapisj gitlink vsekh dostupnyikh dochernikh repozitoriyev, a yavnaya materialization — chistyij detached-snimok na tom zhe OID; otsutstviye checkout, dostupa ili revizii dayot yavnyij otkaz bez vyibora drugoj vershinyi vetki.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: yedinyij avtonomnyij local-bare stend vklyuchayet v obsjhij roditeljskij commit tochnyiye gitlink dolgovechnogo fork-poduzla i samostoyateljnogo proyekta. Oba dochernikh repozitoriya v otdeljnyikh zhivyikh klonakh prodolzhayut sobstvennyiye vetki i sleduyusjhiye shagi: fork sokhranyayet iskhodnyij commit pri peredache obsjhego rezuljtata vverkh, a proyekt vyipolnyayet sobstvennyij shag i peredayot novuyu vershinu v roditelj otdeljnyim CAS-kommitom gitlink. Kanonicheskiye kartochki i vetochnyij rabochij nabor khranyatsya v dochernem commit, a kazhdyij zhivoj klon poluchayet sobstvennyiye checkout-local FIFO i kvitancii obyazateljnogo prodolzheniya; posle kommita novaya zadacha perechityivayet `HEAD` i neposredstvenno vyibirayet sleduyusjhij shag. Poetomu svezhij klon roditelya vosstanavlivayet oba chistyikh detached-snimka na zakreplyonnyikh OID bez skryitogo sostoyaniya prezhnego processa ili publikacii `refs/fum/` v bare. Takuyu proverochnuyu topologiyu povtorno sozdayut toljko vremennyiye lokaljnyiye bare-repozitorii; proverka ne sozdayot vneshnij fork ili proyekt, ne obrasjhayetsya k seti, sekretam ili modelyam i ne podtverzhdayet vneshneye razvyortyivaniye ili nezavisimostj modelej.

Zavershyonnostj otnositsya k istoricheskoj skheme versii `1` i yeyo specializirovannoj fork-fiksture. Ona ostayotsya vosproizvodimyim osnovaniyem novogo universaljnogo sloya, no sama po sebe ne dokazyivayet universaljnyij profilj rebyonka, smenyayemuyu kontekstnuyu rolj, otdeljnostj polnomochij ili upravlyayemoye ispolneniye cepochki.

Trebovaniye ne otozhdestvlyayet submodule s zhivoj vetkoj i ne razreshayet ispoljzovatj avtomatizaciyu vneshnikh zavisimostej bez otdeljnoj proverki yeyo primenimosti k vnutrennej repozitornoj kompozicii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 00:37:53 MSK — Provesti avtonomnuyu skvoznuyu priyomku repozitornoj kompozicii](../Zhurnal/2026-08-05_00-37-53_MSK_provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii/zapros.md)
- [iskhodnyij zapros 2026-08-04 17:51:27 MSK — Perevesti proyektyi na repozitorii-submodule s sobstvennyimi ocheredyami](../Zhurnal/2026-08-04_17-51-27_MSK_perevesti-proyektyi-na-repozitorii-submodule-s-sobstvennyimi-ocheredyami/zapros.md)
- [iskhodnyij zapros 2026-08-04 09:38:47 MSK — Podklyuchitj dolgovechnyij fork-poduzel i peredachu vverkh](../Zhurnal/2026-08-04_09-38-47_MSK_podklyuchitj-dolgovechnyij-fork-poduzel-i-peredachu-vverkh/zapros.md)
- [iskhodnyij zapros 2026-08-03 18:46:53 MSK — Dobavitj izolirovannyij pishusjhij poduzel i kandidatnyij commit](../Zhurnal/2026-08-03_18-46-53_MSK_dobavitj-izolirovannyij-pishusjhij-poduzel-i-kandidatnyij-commit/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 16:10:09 MSK -->
<!-- content-sha256: sha256:980dbac86012d0c0df26065d8d1e80b14623a532235fa5408933fe8032890aa5 -->
<!-- FUM-MD-RECENCY:END -->
