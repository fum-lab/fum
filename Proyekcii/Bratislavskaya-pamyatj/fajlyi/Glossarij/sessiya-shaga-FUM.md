# Sessiya shaga FUM

Avtomaticheskaya cepochka takikh sessij cherez continuation, FIFO i `commit+handoff` yavlyayetsya otlozhennyim profilem. V dejstvuyusjhej ruchnoj skheme poljzovatelj sam zapuskayet kazhduyu pishusjhuyu sessiyu v pervichnom checkout `refs/heads/master`; ona vyipolnyayet odin soderzhateljnyij zapros, sozdayot ne boleye odnogo itogovogo lokaljnogo kommita i zavershayetsya bez preyemnika.

Sessiya shaga FUM — efemernaya host-zadacha, ispolnyayusjhaya odin kontekstno posiljnyij rabochij paket dochernego fork-agenta FUM. V nachaljnom profile kornevoj FUM sozdayot v Codex Desktop toljko pervuyu sessiyu cepochki i svyazyivayet yeyo s tochnyimi naznacheniyem, roljyu, `CODEX_THREAD_ID`, repozitoriyem, zhivyim klonom, bazovyim commit, polnyim rabochim ref i byudzhetami. Kazhduyu sleduyusjhuyu sessiyu zaraneye sozdayot kommityasjhij vladelec kak obyazateljnoye prodolzheniye togo zhe klona i ref.

Sessiya shaga ne yavlyayetsya [rabochej sessiyej](rabochaya-sessiya.md) kornevogo zaprosa, ustojchivoj identichnostjyu [dochernego fork-agenta FUM](dochernij-fork-agent-FUM.md) ili otdeljnyim modeljnyim vyizovom. Odna sessiya mozhet soderzhatj neskoljko modeljnyikh vyizovov i instrumentaljnyikh perekhodov, no obsluzhivayet rovno odin shag. Odin `CODEX_THREAD_ID` ne pereispoljzuyetsya dlya drugogo shaga ili pokoleniya naznacheniya.

Kazhdyij shag poluchayet otdeljnuyu sessiyu i novyij `CODEX_THREAD_ID`, no zadachi odnoj linejnoj cepochki nasleduyut odin fizicheskij checkout i polnyij ref. Odnovremenno ispolnyayutsya toljko gotovyiye sovmestimyiye shagi raznyikh cepochek ili nezavisimyikh vetvej; zavisimyiye shagi odnoj linejnoj cepochki zapuskayutsya posledovateljno ot prinyatoj vershinyi. Zaversheniye sessii ne unichtozhayet sostoyaniye agenta: sleduyusjhij shag vosstanavlivayetsya iz Git, naznacheniya, pasportov i artefaktov bez obyazateljnoj istorii prezhnego chata.

Dlya [vetvevogo fork FUM](vetvevoj-fork-FUM.md) aktivnoj schitayetsya toljko odna avtoritetnaya sessiya-vladelec: pishusjhaya sessiya rabochego ref libo ograzhdyonnaya sessiya moderacii, no ne obe odnovremenno. Zaraneye sozdannaya ozhidayusjhaya sessiya obyazateljnogo prodolzheniya, neaktivnaya dochernyaya zadacha i vneshnyaya proveryayusjhaya zadacha bez prava zapisi mogut susjhestvovatj paralleljno, no ne poluchayut polnomochij fork. Posle razvilki tot zhe roditeljskij logicheskij uzel mozhet prodolzhitj rolj moderatora novoj sessiyej; prezhnyaya host-sessiya ne dolzhna uderzhivatj roditeljskij FIFO vo vremya rabotyi detej.

Odin ekzemplyar Codex Desktop yavlyayetsya zayavlennyim nachaljnyim profilem razvyortyivaniya. Mashinno dokazuyemaya chastj zakreplyayet raznyiye host-zadachi, `CODEX_THREAD_ID`, checkout i refs. Yedinstvennostj fizicheskogo Desktop-kontrollera schitayetsya dokazannoj toljko pri nalichii ustojchivoj identichnosti i avtoritetnogo readback host; inache ona ostayotsya nablyudayemoj konfiguraciyej, a ne proverennyim invariantom.

## Svyazannyiye dokumentyi

- [Rabochaya sessiya](rabochaya-sessiya.md)
- [Repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [Trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:0e3c84b45e2aa6d74fade895ecc63fa7d0d975607b66c40fac98e28126f9ef5b -->
<!-- FUM-MD-RECENCY:END -->
