# Izmereniye podgotovki Git-fiksturyi

Iz kornya FUM cherez otchyotnuyu obyortku svoyego etapa vyipolnite:

```text
python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_подготовки_доставки.py --выход <профиль.json> --повторы 3
```

Prinimayetsya ot 1 do 20 povtorov. Import test_obratnaya_dostavka izmeryayetsya odin raz; sozdaniye Fikstura i udaleniye yeyo vremennogo kataloga — otdeljno na kazhdom povtore. Tela testov ne ispolnyayutsya. Vyikhod soderzhit iskhodnyiye intervalyi, medianyi uspeshnyikh stadij, versii Python/Git i khyeshi iskhodnikov. Oshibka dayot nenulevoj kod CLI; pervichnaya oshibka sokhranyayetsya pri odnovremennom otkaze ochistki, obe stadii perechislenyi v dannyikh.

Git-vyizovyi nablyudayutsya toljko vnutri stadij. Ikh vremya uzhe vkhodit vo vremya stadii. Sokhranyayutsya nazvaniye podkomandyi, nomer povtora, iskhod i kod vozvrata; argumentyi, lokaljnyiye puti i vyivod processov ne zapisyivayutsya. Razbor komand prednaznachen dlya susjhestvuyusjhej fiksturyi, a ne proizvoljnyikh variantov Git CLI.

Zapusk Python, import izmeritelya i sozdaniye vremennoj papki isklyuchenyi. Stoimostj metok vklyuchena, otdeljno ne izmerena. Odin profilj ne yavlyayetsya sravneniyem optimizacij i ne izmeryayet polnyij unittest discovery libo stoimostj tel testov. Dlya takikh vyivodov nuzhen otdeljnyij eksperiment.

Adresnaya proverka:

```text
python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_профиля_подготовки.py
```

[Nablyudeniye i granicyi pervoj realizacii](../../Zhurnal/2026-09-19_02-10-23_MSK_izmeritj-podgotovku-Git-fikstur/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-19 02:30:45 MSK -->
<!-- content-sha256: sha256:13c154729b508982665dddd923c760ad56578443879f9e30697584f8684f1d74 -->
<!-- FUM-MD-RECENCY:END -->
