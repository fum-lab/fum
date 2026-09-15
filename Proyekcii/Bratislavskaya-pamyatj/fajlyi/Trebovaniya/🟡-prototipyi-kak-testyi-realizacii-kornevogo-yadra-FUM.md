# Prototipyi kak testyi realizacii kornevogo yadra FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0038 -->

Realizaciya kornevogo yadra FUM dolzhna dopuskatj povtornoye ispoljzovaniye proveryayemyikh prototipov kak ispolnyayemyikh testov sootvetstviya. Testom sluzhit ne eksperimentaljnyij status prototipa i ne vesj yego vnutrennij kod, a zaraneye zakreplyonnyij nablyudayemyij kontrakt: versionirovannyiye vkhodyi i vyikhodyi, fiksturyi, invariantyi, ozhidayemyiye otkazyi i profilj ekvivalentnosti.

V granicakh etogo trebovaniya kornevoye yadro — obsjhij `core` FUM s publikacionno chistyimi pravilami, skhemami, dokumentaciyej, instrumentami i perenosimyimi uluchsheniyami. Kazhdyij test obyazan yavno suzitj proveryayemyij srez yadra; prokhozhdeniye odnogo prototipnogo kontrakta ne oznachayet priyomku vsego yadra.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [chistoye ispolneniye operatorov i UTF-32](🟡-chistoye-ispolneniye-operatorov-i-UTF-32.md) — otdeleniye ispolneniya ot proverochnyikh ozhidanij gotovit nablyudayemyij kontrakt dekodirovaniya dlya budusjhego sravneniya realizacij; obsjhij vyichisliteljnyij dvizhok ne schitayetsya nezavisimyim podtverzhdeniyem yadra.

- **dopolnyayet:** [bezokonnyij Swift-kontur pervogo korobochnogo prototipa](✅-bezokonnyij-Swift-kontur-pervogo-korobochnogo-prototipa.md) — pozvolyayet perenositj zakreplyonnyij kontrakt prototipa v test otdeljnoj realizacii yadra, ne prevrasjhaya sam prototip v postavlyayemyij runtime.

## Kriterii proverki

- pasport svyazyivayet tochnuyu versiyu prototipa s iskhodnyim trebovaniyem, proveryayemyim interfejsom i versiyej realizacii yadra;
- odin zaraneye zafiksirovannyij nabor vkhodov, fikstur, invariantov i otkaznyikh scenariyev primenim k prototipu i k realizacii yadra;
- sravneniye vyipolnyayetsya po yavnomu profilyu ekvivalentnosti nablyudayemogo rezuljtata, a ne po sluchajnyim vnutrennim detalyam dvukh realizacij;
- ozhidayemyij rezuljtat ne vyivoditsya iz proveryayemoj realizacii i ne perepisyivayetsya molcha posle raskhozhdeniya; izmeneniye zakreplyayetsya kak novaya versiya trebovaniya, prototipnogo kontrakta ili profilya ekvivalentnosti;
- test avtonomen po umolchaniyu i ne trebuyet seti, sekretov, zhivoj modeli ili skryitogo sostoyaniya sessii Codex;
- obsjhaya biblioteka dopustima toljko dlya nejtraljnoj skhemyi vkhodov, zapuska i sravneniya: vyichisliteljnaya logika proveryayemogo sreza ne dolzhna delatj prototip i realizaciyu odnim i tem zhe ispolneniyem;
- uspeshnyij prototipnyij test podtverzhdayet toljko obyyavlennyij srez i ne zamenyayet sobstvennyiye moduljnyiye, integracionnyiye, bezopasnostnyiye i produktovyiye proverki yadra.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: strategiya prinyata, dejstvuyusjhiye prototipyi uzhe soderzhat vosproizvodimyiye fiksturyi i nablyudayemyiye kontraktyi, no ikh sistematicheskaya privyazka k otdeljnoj realizacii obsjhego kornevogo yadra yesjhyo ne vyipolnena.

Trebovaniye razreshayet ispoljzovatj prototip kak ispolnyayemyij etalon ili differencialjnyij test, no ne trebuyet sokhranyatj yego vnutrennyuyu arkhitekturu i ne obyyavlyayet eksperimentaljnyij kod chastjyu postavki.

## Istochniki trebovanij

- [Postanovka perenosa i interpretatora](../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/zapros.md)

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-05_20-01-32_MSK_zakrepitj-prototipyi-kak-testyi-i-sozdatj-kartochku-ozhidaniya-ocheredi/zapros.md)
- [repozitornyij graf pishusjhikh poduzlov i proyektov FUM](../Dokumentaciya/44-repozitornyij-graf-pishusjhikh-poduzlov-i-proyektov-FUM.md)
- [pravila prototipov](../Prototipyi/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:26:18 MSK -->
<!-- content-sha256: sha256:3d1287aeb832e0ba722525cc82f27cb238d3762f3361162f7f81e0d05b2b26f2 -->
<!-- FUM-MD-RECENCY:END -->
