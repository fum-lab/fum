# Kartochka cepochki shagov

Kartochka cepochki shagov — kanonicheskaya planovaya zapisj FUM, kotoraya svyazyivayet konechnyij uporyadochennyij spisok [kartochek shagov](kartochka-shaga.md) s odnoj tochnoj lokaljnoj [vetkoj rabotyi](vetka-rabotyi.md). Kartochka khranit ustojchivyij identifikator `FUM-ЦЕПОЧКА-NNNN`, sostoyaniye, polnyij Git-ref vetki, bazovuyu vetku i putj proyekta, no ne kopiruyet zadachi, kriterii ili istochniki otdeljnyikh shagov.

Mashinnyij reyestr dopuskayet rovno odnu aktivnuyu kartochku: eto otdeljno vyibrannaya sleduyusjhaya cepochka, no yesjhyo ne dokazateljstvo tekusjhej vetki. Realizaciya cepochki nachinayetsya s ograzhdyonnogo perekhoda na yeyo vetku mezhdu kornevyimi zadachami. Tekusjhaya cepochka opredelyayetsya proverennoj kartochkoj, yeyo tochnyim khyeshem i sovpadeniyem polnogo ref s imenovannoj vetkoj checkout, a ne toljko sostoyaniyem ili pokhozhim imenem vetki. Uspeshnoye zaversheniye kazhdogo izmenyayusjhego shaga vklyuchayet zakryityiye dokazateljstva polnogo smoke-check i atomarnyij kommit imenno v etu vetku.

Kanonicheskiye kartochki i ikh indeks khranyatsya v [Planirovaniye/kartochki-cepochek-shagov](../Planirovaniye/kartochki-cepochek-shagov/README.md).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-08 15:04:10 MSK -->
<!-- content-sha256: sha256:7fe714167627740d5c23f97ef2397841b641f28a0fea5e4fde333b62b55a458b -->
<!-- FUM-MD-RECENCY:END -->
