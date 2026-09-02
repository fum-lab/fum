# Vetka rabotyi

Vetka rabotyi v FUM — otdeljnaya imenovannaya liniya razvitiya zadachi, gipotezyi ili konechnoj cepochki izmenenij. Ona sokhranyayet sobstvennyij kontekst, proiskhozhdeniye reshenij, promezhutochnyiye rezuljtatyi i itog, kotoryij zatem mozhet byitj vozvrasjhyon v obsjhuyu pamyatj cherez osmyislennoye sliyaniye.

Vetka rabotyi nuzhna dlya paralleljnogo razvitiya variantov: [FUM](FUM.md) dolzhen umetj sravnivatj linii rabotyi, obnaruzhivatj konfliktyi i sokhranyatj istoriyu togo, pochemu vyibran itogovyij variant.

V otlozhennom avtomaticheski razvivayemom profile imenovannaya Git-vetka imeyet rovno odin [sleduyusjhij shag vetki](sleduyusjhij-shag-vetki.md), kotoryij vyibirayet aktualjnuyu [kartochku shaga](kartochka-shaga.md) libo yavno fiksiruyet zaversheniye. Etot profilj ne dejstvuyet dlya tekusjhej zapisi v repozitorij. Identichnostj vetki vklyuchayet repozitorij i polnyij ref: odinakovyij `refs/heads/master` v yadre, poduzle i proyekte oboznachayet raznyiye linii. Samostoyateljnyij proyekt khranit vetki i sleduyusjhij shag v sobstvennom repozitorii, a roditelj zakreplyayet yego proverennuyu reviziyu cherez [repozitornuyu kompoziciyu](repozitornaya-kompoziciya-FUM.md).

Dlya konechnoj posledovateljnosti shagov kanonicheskij upstream vetki zadayot [kartochka cepochki shagov](kartochka-cepochki-shagov.md): ona svyazyivayet ustojchivyij identifikator cepochki, tochnyij polnyij ref i uporyadochennyiye kartochki, togda kak sleduyusjhij shag vetki ostayotsya proizvodnyim selektorom tekusjhego prodolzheniya. Perekhod versii `1` razreshyon toljko mezhdu kornevyimi zadachami, iz chistogo i pustogo FIFO-sostoyaniya, na otsutstvuyusjhij celevoj ref, sozdavayemyij rovno na tochnom iskhodnom `HEAD`; dopusjhennyij vladelec vetku ne pereklyuchayet.

V dereve ispolneniya odna para identichnosti repozitoriya i polnogo ref yavlyayetsya avtoritetnoj rabochej liniyej odnogo [vetvevogo fork FUM](vetvevoj-fork-FUM.md) i ne pereispoljzuyetsya drugim uzlom. Linejnyij fork mozhet otdeljnyim ograzhdyonnyim perekhodom poroditj rovno dva dochernikh fork ot proverennogo obsjhego iskhodnogo sostoyaniya; kazhdyij rebyonok poluchayet druguyu paru repozitoriya i polnogo ref i zhivoj checkout, a tot zhe roditeljskij uzel stanovitsya moderatorom. Vnutri kazhdogo rebyonka posledovateljnostj kommitov ostayotsya linejnoj, a posleduyusjhaya integraciya ne menyayet derevo proiskhozhdeniya.

V dejstvuyusjhej ruchnoj skheme odna poljzovateljski zapusjhennaya pishusjhaya sessiya vyipolnyayet odin soderzhateljnyij zapros, zakryivayet proverochnyij otchyot, sozdayot ne boleye odnogo lokaljnogo kommita `refs/heads/master` i zavershayetsya. Avtomaticheskiye selector/dispatcher, FIFO i `commit+handoff` yavlyayutsya istoricheskoj libo otlozhennoj narabotkoj i ne zapuskayut sleduyusjhuyu rabotu.

[Vetka shaga FUM](vetka-shaga-FUM.md) yavlyayetsya odnorazovoj vetkoj odnoj pishusjhej popyitki ot tochnogo `base_oid`; ona ne zamenyayet dolgovechnuyu vetku poduzla ili proyekta. Git submodule khranit tochnyij gitlink, a ne samu zhivuyu vetku.

## Svyazannyiye dokumentyi

- [Paralleljnaya rabota i sliyaniye](../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Kartochki cepochek shagov FUM](../Planirovaniye/kartochki-cepochek-shagov/README.md)
- [Sleduyusjhiye shagi vetok](../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK - Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK - Dekompozirovatj predlozheniya na kartochki shagov](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-26 12:59:08 MSK — Sproyektirovatj Git-graf pishusjhikh subagentov i proyektov](../Zhurnal/2026-07-26_12-59-08_MSK_sproyektirovatj-Git-graf-pishusjhikh-subagentov-i-proyektov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:37:47 MSK -->
<!-- content-sha256: sha256:7689a12f5ac8cc13aa48944df6cf7c1b1f3fb4c6fc01c70bf24298c34d316bc3 -->
<!-- FUM-MD-RECENCY:END -->
