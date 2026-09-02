# 04. Modeljnaya sreda i planirovaniye

## Naznacheniye

Eto napravleniye uderzhivayet [modeljnuyu sredu](../../Glossarij/modeljnaya-sreda.md) kak otdeljnyij rezhim myishleniya [FUM](../../Glossarij/FUM.md). V nej mozhno opisyivatj aktualjnoye sostoyaniye, rekonstruirovatj proshloye, stroitj vozmozhnyiye budusjhiye scenarii i modelirovatj drugiye uzlyi, ne smeshivaya planovyiye dopusjheniya s nablyudayemyimi faktami.

## Proyektnyiye voprosyi

- Kak yavno razlichatj fakt, rekonstrukciyu, prognoz, scenarij, gipotezu i zhelayemoye sostoyaniye?
- Kak sokhranyatj urovenj uverennosti, istochniki, ogranicheniya i zavisimostj ot [otkryityikh voprosov](../../Glossarij/otkryityij-vopros.md)?
- Kak modelirovatj drugogo [FUM-uzla](../../Glossarij/FUM-uzel.md) bez prisvoyeniya polnogo znaniya o yego [vnutrennem sostoyanii](../../Glossarij/vnutrenneye-sostoyaniye.md)?
- Gde modeljnoye dejstviye ostayotsya bezopasnyim planirovaniyem, a gde nachinayet trebovatj realjnogo podtverzhdeniya?

## Liniya razvitiya

Blizhnij sloj realizovan kak [shablon scenariya modeljnoj sredyi](../shablon-scenariya-modeljnoj-sredyi.md): istochnik, vremennoj rezhim, status utverzhdenij, uverennostj, ogranicheniya dostupa, svyazannyiye voprosyi i ozhidayemyij rezuljtat zadayutsya dlya kazhdogo znachimogo utverzhdeniya. Kontejner pozvolyayet planirovaniyu v `Планирование/` ssyilatjsya na neyasnosti yavno, a ne pryatatj ikh vnutri uverennogo teksta.

Sleduyusjhij sloj - svyazatj modeljnuyu sredu s agentskim ciklom: cikl mozhet stroitj variantyi dejstvij vnutri modeli, no realjnoye dejstviye dolzhno prokhoditj cherez otdeljnuyu proverku i podtverzhdeniye.

## Blizhajshij proverennyij artefakt

[Shablon scenariya modeljnoj sredyi](../shablon-scenariya-modeljnoj-sredyi.md) sokhranyayet tri vremennyikh rezhima, lokaljnyij slovarj statusov, kachestvennuyu uverennostj s osnovaniyem, istochniki, [urovni dostupa](../../Glossarij/urovenj-dostupa.md), svyazannyiye [otkryityiye voprosyi](../../Glossarij/otkryityij-vopros.md), ozhidayemyij modeljnyij rezuljtat i otdeljnuyu granicu realjnogo dejstviya.

Zapolnennyij primer yavno razlichayet aktualjnyij fakt, rekonstrukciyu proshlogo i plan budusjhego. Neproyasnyonnaya razvilka ssyilayetsya na [vopros o statuse vnutrennikh FUM i modeljnyikh sred](../../Voprosyi/2026-06-22_06-35-26_MSK_status-vnutrennikh-FUM.md), a rezuljtat ogranichen dokumentaljnyim sravneniyem bez vyibora runtime i bez vneshnego dejstviya.

## Proveryayemyiye rezuljtatyi

- Shablon scenariya razlichayet aktualjnoye opisaniye, rekonstrukciyu proshlogo i plan budusjhego.
- Planovyij material s neproyasnyonnoj razvilkoj ssyilayetsya na fajl v `Вопросы/`.
- Vnutrennyaya modelj drugogo uzla soderzhit istochniki i granicyi uverennosti.
- Perekhod ot modeljnogo dejstviya k realjnomu dejstviyu trebuyet yavnogo statusa i proverki.

## Granicyi

Modeljnaya sreda ne dolzhna vyidavatj scenarij za fakt. Ona takzhe ne dolzhna stanovitjsya sposobom obojti [granicyi vlasti FUM](../../Glossarij/granica-vlasti-FUM.md): prognoz o drugom uzle ne raven razresheniyu dejstvovatj vmesto nego ili raskryivatj yego privatnoye sostoyaniye.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 10:22:00 MSK — Opisatj shablon scenariya modeljnoj sredyi](../../Zhurnal/2026-07-23_10-22-00_MSK_opisatj-shablon-scenariya-modeljnoj-sredyi/zapros.md)
- [iskhodnyij zapros 2026-06-25 17:59:02 MSK](../../Zhurnal/2026-06-25_17-59-02_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](../../Zhurnal/2026-06-25_18-17-22_MSK/zapros.md)

## Opornyiye materialyi

- [Sreda dlya vnutrennikh FUM](../../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md)
- [Vnutrenniye modeli drugikh uzlov](../../Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md)
- [Dorozhnaya karta FUM](../dorozhnaya-karta.md)
- [Voprosyi](../../Voprosyi/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:428415d7a190c62a504ad64f17fb622cf2172e16a1f7c451b797520d32b18a75 -->
<!-- FUM-MD-RECENCY:END -->
