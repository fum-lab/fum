# Dochernij fork-agent FUM

Dolgovechnyij fork-agent i opisannyiye nizhe worktree/FIFO/review/integration/pull-request marshrutyi yavlyayutsya otlozhennoj celevoj arkhitekturoj, a ne dejstvuyusjhim sposobom zapisi tekusjhego repozitoriya. Sejchas obyichnaya zapisj vyipolnyayetsya toljko vruchnuyu odnoj sessiyej v pervichnom checkout `refs/heads/master`.

Dochernij fork-agent FUM — dolgovechnaya repozitornaya forma [universaljnogo ispolniteljnogo poduzla FUM](universaljnyij-ispolniteljnyij-poduzel-FUM.md). On nasleduyet publikacionno chistoye yadro FUM cherez sobstvennyij fork-repozitorij, sokhranyayet ustojchivuyu identichnostj i pamyatj mezhdu modeljnyimi zapuskami i peredayot obsjheprimenimyiye rezuljtatyi kornevomu FUM proveryayemyimi Git-vetkami i pull request.

Otnositeljno kornevogo FUM takoj poduzel dejstvuyet kak agent, a dlya ispolnyayemyikh vnutri nego shagov sluzhit dolgovechnyim nositelem [modeljnyikh sred](modeljnaya-sreda.md). Konkretnaya sreda yavlyayetsya versionirovannyim predstavleniyem yego sostoyaniya: predyyavlyayet tochnyij snimok pamyati, rolj, rabochij paket, instrumentyi, ogranicheniya, byudzhetyi i dopustimyiye perekhodyi. Fork-agent, yego repozitorij, snimok sredyi, [sessiya shaga FUM](sessiya-shaga-FUM.md) i otdeljnyij modeljnyij vyizov ne tozhdestvennyi drug drugu. Zaversheniye sessii ne unichtozhayet agenta, a odin i tot zhe snimok mozhet byitj predyyavlen novomu ispolneniyu.

Kazhdyij dochernij fork-agent sokhranyayet obsjhij potencialjnyij profilj sposobnostej FUM. [Kontekstnaya rolj FUM-agenta](kontekstnaya-rolj-FUM-agenta.md) zadayot prioritetyi konkretnogo naznacheniya, no ne prevrasjhayet agenta v otdeljnyij ontologicheskij vid i ne rasshiryayet yego polnomochiya. Fakticheskaya kompetentnostj, dostup, vneshniye effektyi i pravo daljnejshej delegacii podtverzhdayutsya i vyidayutsya otdeljno.

Rabochij `master` fork sinkhroniziruyetsya toljko yavno s tochnyim prinyatyim pokoleniyem kornevogo upstream. Rolevaya pamyatj i kandidatnyiye izmeneniya zhivut vne zerkaljnogo `master`. Obsjhaya [narabotka](narabotka.md) oformlyayetsya v publikacionno chistoj vetke ot tochnoj bazyi; pull request zakreplyayet yeyo proiskhozhdeniye i oblastj revjyu, no ne oznachayet avtomaticheskogo prinyatiya. Posle proverki i integracii perenosimyij navyik vkhodit v kornevoye yadro. Novyij celevoj agent poluchayet yego iz tochnogo prinyatogo pokoleniya yadra, a uzhe susjhestvuyusjhij fork — toljko cherez otdeljnuyu proveryayemuyu sinkhronizaciyu.

Fizicheskij fork-repozitorij agenta ne tozhdestven [vetvevomu fork FUM](vetvevoj-fork-FUM.md). Repozitorij mozhet khranitj zerkaljnyij `master`, rolevuyu pamyatj, refs rezuljtatov i pull-request refs, togda kak odin logicheskij vetvevoj fork zakreplyayet rovno odnu avtoritetnuyu paru repozitoriya i rabochego ref, odin zhivoj checkout i ne boleye odnoj dopusjhennoj sessii-vladeljca. Poetomu formula «odin fork — odna vetka» primenyayetsya k uzlu dereva ispolneniya, a ne zapresjhayet sluzhebnyiye refs dolgovechnogo agenta.

Lokaljnaya `self_line` FUM-STEP-0148 takzhe ne yavlyayetsya dochernim fork-agentom. Posle exact committed marshrutizacii ona lenivo zanimayet pereispoljzuyemyij linked worktree `Подузлы/слот-*` togo zhe repozitoriya; yeyo posledovateljnyiye sessii cherez dolgovechnyij FIFO-bilet, CAS handoff i reload/ack ispoljzuyut te zhe slot, polnyij ref i worktree, a read-only-marshrut pisateljskij slot ne zanimayet. Slot osvobozhdayetsya inoj linii toljko posle terminala vsej tekusjhej linii. Avtomaticheskiye revjyu, razresheniye dopustimogo konflikta, povtornoye revjyu i obyichnaya FIFO-integraciya `master` ne sozdayut otdeljnuyu repozitornuyu identichnostj, dolgovechnuyu pamyatj, GitHub fork, pull request ili submodule. Zablokirovannyij rezuljtat sokhranyayetsya i publikuyetsya otdeljnyim result-ref, a ne v `master`.

Etalonnyij dokumentaljnyij CLI zakryivayet soderzhateljnyiye i terminaljnyiye komandyi vne exact repo-root naznachennogo slota, no ne dokazyivayet host-level perenos ili vozobnovleniye workspace Codex Desktop i otsutstviye avtomaticheskogo chteniya osnovnogo checkout. Lokaljnyij linked worktree poetomu ne yavlyayetsya nativnoj izolyaciyej; otdeljnyij fork-repozitorij ostayotsya samostoyateljnyim dolgovechnyim profilem.

Tekusjhiye subagentyi odnoj kornevoj rabochej sessii, razdelyayusjhiye obsjhij checkout, ne yavlyayutsya etim dolgovechnyim vidom. Realjnyij dochernij fork-agent trebuyet sobstvennogo repozitoriya, otdeljnogo zhivogo klona, refs, upravlyayusjhego sostoyaniya i zhivoj priyomki.

## Svyazannyiye dokumentyi

- [Repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [Nachaljnyij rolevoj pul dochernikh fork-agentov FUM](../Planirovaniye/nachaljnyij-rolevoj-pul-dochernikh-fork-agentov-FUM.md)
- [Trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-13 18:17:47 MSK — Organizovatj paralleljnyiye sessii v lokaljnyikh worktree-poduzlakh](../Zhurnal/2026-08-13_18-17-47_MSK_organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-fork-poduzlakh/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:0a802fd46fca8342b01fc6070682ea46000418d82e151d4808bf5e2664b8c518 -->
<!-- FUM-MD-RECENCY:END -->
