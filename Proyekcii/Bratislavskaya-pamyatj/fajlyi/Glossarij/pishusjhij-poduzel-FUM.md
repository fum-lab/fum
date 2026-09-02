# Pishusjhij poduzel FUM

Pul pishusjhikh poduzlov, worktree-slotyi, FIFO, continuation, avtomaticheskiye review/integration/CAS i publikaciya nizhe yavlyayutsya otlozhennoj celevoj arkhitekturoj. Oni ne dayut polnomochij tekusjhej sessii: obyichnaya zapisj vyipolnyayetsya toljko odnoj vruchnuyu zapusjhennoj sessiyej v pervichnom checkout `refs/heads/master`.

Pishusjhij poduzel FUM — [poduzel FUM](poduzel-FUM.md), kotoromu yavno delegirovano uzkoye pravo vyipolnitj odin kontekstno posiljnyij rabochij paket i sozdatj Git-kommit v tochnom vetochnom kontekste. Polnomochiye zakreplyayet tochnyiye repozitorij, `base_oid`, polnyij ref, fizicheskij checkout, oblastj izmenenij, urovenj dostupa, proverki i kriterij ostanovki. Sobstvennaya [vetka shaga FUM](vetka-shaga-FUM.md) v otdeljnom klone ili worktree otnositsya k nezavisimomu paralleljnomu kandidatu; posledovateljnyij shag linejnoj cepochki poluchayet yeyo obsjhij zhivoj checkout i tochnyij rabochij ref.

V lokaljnom profile FUM-STEP-0148 obyichnaya novaya sessiya snachala svyazyivayet vyibor marshruta s exact committed snapshot: OID celevoj vershinyi i planovyikh istochnikov, aktivnyimi liniyami i tochnyim sostoyaniyem ikh FIFO i svobodnyimi slotami. `параллельная_линия` posle vyibora lenivo sozdayot `self_line` v pereispoljzuyemom linked worktree `Подузлы/слот-*`; `последовательное_продолжение` dobavlyayet dolgovechnyij bilet k tochnoj linii; `только_чтение` ne zanimayet pisateljskij slot. Odnovremenno aktivnyiye pisatelj, nezavisimyij recenzent i integrator zanimayut raznyiye slotyi.

Nezavisimaya paralleljnaya liniya ne menyayet checkout roditelya, yego Git-indeks, celevuyu vetku ili istoriyu. Posledovateljnyiye vladeljcyi etoj linii ispoljzuyut te zhe fizicheskij slot, polnyij ref i worktree strogo po odnomu: do kommita sleduyusjhij vladelec zakreplyayetsya FIFO-biletom, CAS `commit+handoff` atomarno peredayot ref i ocheredj, a poluchatelj posle `reload_required` perechityivayet novyij `HEAD` i podtverzhdayet exact OID. Tochnyij povtor i read-only-vosstanovleniye poteryannogo otveta ne dubliruyut slot, bilet, kommit ili peredachu.

Poka prodolzheniye ozhidayet, rezuljtat linii neljzya zamorozitj i slot neljzya pereispoljzovatj. Posle terminala vsej linii tochnyij commit sokhranyayetsya pod ustojchivyim result-ref; lishj dokazannyiye otsutstviye vladeljca i biletov, ostanovka pozdnikh pisatelej, chistota checkout i indeksa i terminaljnaya kvitanciya razreshayut vernutj slot v pul. Zamorozhennyij obyyekt prokhodit avtomaticheskoye nezavisimoye agentskoye revjyu; otdeljnyij integrator v svoyom worktree razreshayet dopustimyij konflikt, a itog obyazateljno poluchayet povtornoye nezavisimoye revjyu. Toljko prinyatyij obyyekt peredayotsya v obyichnuyu FIFO osnovnoj vetki dlya exact-CAS lokaljnogo `master`.

Kazhdyij result-ref, vklyuchaya zablokirovannyij i neslivayemyij, sokhranyayetsya lokaljno i posle proverki publikacionnoj chistotyi avtomaticheski otpravlyayetsya bez force v nastroyennyij remote togo zhe repozitoriya s tochnyim readback. Oshibka seti ili autentifikacii dayot `publication_pending` i ne unichtozhayet ref. Zablokirovannyij rezuljtat ostayotsya otdeljnyim result-ref i ne popadayet v `master`. GitHub fork i pull request v etom lokaljnom marshrute ne ispoljzuyutsya; otdeljnyij klon ostayotsya materializaciyej samostoyateljnogo repozitoriya.

Etalonnyij dokumentaljnyij CLI dopuskayet soderzhateljnyiye i terminaljnyiye komandyi toljko iz exact repo-root naznachennogo slota s sovpavshim `worktree_id`. Eto ne dokazyivayet perenos ili vozobnovleniye host-workspace Codex Desktop i otsutstviye avtomaticheskikh chtenij osnovnogo checkout do pervogo instrumenta. Poetomu linked worktree zdesj yavlyayetsya kooperativnoj protokoljnoj granicej, a ne nativnoj izolyaciyej.

Etot termin ne oboznachayet nyineshnego subagenta v obsjhem checkout odnoj kornevoj zadachi. Takoj subagent po-prezhnemu ne menyayet Git-indeks ili istoriyu; yego diff sobirayet i kommitit dopusjhennyij kornevoj ispolnitelj.

[Universaljnyij ispolniteljnyij poduzel FUM](universaljnyij-ispolniteljnyij-poduzel-FUM.md) mozhet poluchitj konechnuyu linejnuyu cepochku kartochek, no ne otmenyayet odnopaketnuyu granicu pishusjhego poduzla. Vsya cepochka ispoljzuyet odin fizicheskij zhivoj checkout i tochnyij polnyij rabochij ref: korenj sozdayot toljko nachaljnuyu host-zadachu, a kazhdyij kommityasjhij vladelec zaraneye sozdayot rovno odno prodolzheniye togo zhe checkout i ref i zatem vyipolnyayet `commit+handoff`, kotoryij sozdayot neposredstvennyij odnoroditeljskij commit i peredayot stroguyu FIFO. Otdeljnyiye proveryayusjhij i integrator podklyuchayutsya toljko posle gotovnosti proveryayemogo diapazona i ne stoyat mezhdu posledovateljnyimi vladeljcami vetki.

## Svyazannyiye dokumentyi

- [Paralleljnaya rabota i sliyaniye](../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [Poduzel FUM](poduzel-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-13 18:17:47 MSK — Organizovatj paralleljnyiye sessii v lokaljnyikh worktree-poduzlakh](../Zhurnal/2026-08-13_18-17-47_MSK_organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-fork-poduzlakh/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:41:30 MSK -->
<!-- content-sha256: sha256:a66eeeb0ca877fc6cf56b5042935649d64e37cc40a7088d10e0ac049eeee0611 -->
<!-- FUM-MD-RECENCY:END -->
