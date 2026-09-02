# Preobrazovaniye mezhdu nablyudatelyami FUM

Preobrazovaniye mezhdu nablyudatelyami FUM — napravlennyij perekhod ot zakreplyonnogo iskhodnogo sloya, dostupnogo iskhodnomu [nablyudatelyu FUM](nablyudatelj-FUM.md), k predstavleniyu dlya celevogo nablyudatelya. Perekhod fiksiruyet oba profilya nablyudatelej, pryamoj metod, proiskhozhdeniye celevyikh signalov, sokhranyayemyiye invariantyi, yavnyiye poteri, proverku obratimosti i yeyo vyivod.

Preobrazovaniye ne priravnivayet nablyudatelej i ne trebuyet odinakovoj formyi predstavleniya. Ono delayet proveryayemoj svyazj mezhdu bajtami, tekstom, ekranom, JSON, DOM, trassoj, tenzorom ili drugim interfejsnyim sloyem v ramkakh [nablyudateljskoj otnositeljnosti FUM](nablyudateljskaya-otnositeljnostj-FUM.md).

Marshrut k sokhranyonnomu istochniku yavlyayetsya otdeljnyim svojstvom zapisi perekhoda. Proizvodnaya forma obyazana soprovozhdatjsya etoj zapisjyu libo obnaruzhivatj yeyo po ustojchivoj svyazi; v obsjhem sluchaye eto mozhet byitj vstraivaniye, sidecar ili reyestr, a minimaljnyij format versii `1` proveryayet toljko materializovannyij sidecar-kontekst. Neobratimaya svodka pri etom mozhet vesti k polnomu iskhodnomu fajlu, no ne vosstanavlivayet istochnik toljko iz sebya. «Polnaya informaciya» oznachayet polnyij zakreplyonnyij istochnik v yavno nazvannoj proyekcii; ischerpyivayusjhij inventarj yeyo signalov proveryayetsya vnutri obyyavlennyikh oblasti i versii, a ne pretenduyet na absolyutnoye vnutrenneye sostoyaniye sistemyi.

## Svyazannyiye dokumentyi

- [Minimaljnyij format preobrazovaniya mezhdu nablyudatelyami FUM](../Dokumentaciya/38-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM.md)
- [Nablyudateljskaya otnositeljnostj informacionnyikh sistem](../Dokumentaciya/26-nablyudateljskaya-otnositeljnostj-informacionnyikh-sistem.md)
- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md)

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-23_11-50-58_MSK_opisatj-minimaljnyij-format-preobrazovaniya-mezhdu-nablyudatelyami-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-26 11:39:57 MSK](../Zhurnal/2026-06-26_11-39-57_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-02 11:14:15 MSK](../Zhurnal/2026-07-02_11-14-15_MSK/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:dc43fa80c121693cef6c26da2be3c538d3d0990d01eb5934f6bca81701fa136a -->
<!-- FUM-MD-RECENCY:END -->
