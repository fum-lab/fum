# [Otkryityij vopros](../Glossarij/otkryityij-vopros.md): status [vnutrennikh FUM](../Glossarij/vnutrennij-FUM.md) i [modeljnyikh sred](../Glossarij/modeljnaya-sreda.md)

## Status

Vopros chastichno proyasnyon dlya dolgovechnyikh ispolnyayemyikh fork-agentov, no ostayotsya otkryityim dlya drugikh klassov vnutrennikh FUM i vremennyikh rezhimov modeljnoj sredyi.

## Neodnoznachnostj

[Iskhodnyij zapros](../Glossarij/iskhodnyij-zapros.md) fiksiruyet, chto [FUM](../Glossarij/FUM.md) sozdayot [okruzhayusjhuyu sredu](../Glossarij/modeljnaya-sreda.md) dlya [vnutrennikh FUM](../Glossarij/vnutrennij-FUM.md), kotoraya mozhet sluzhitj osnovaniyem modeli aktualjnogo mira, proshlogo ili budusjhego. Pri etom poka ne opredeleno, kakim dolzhen byitj status [vnutrennikh FUM](../Glossarij/vnutrennij-FUM.md) v takoj srede: polnocennyiye vlozhennyiye agentyi, simulyacionnyiye roli, modeli vneshnikh uchastnikov, [moduljnyiye](../Glossarij/modulj-FUM.md) poduzlyi [pamyati](../Glossarij/pamyatj-FUM.md) ili boleye lyogkiye gipoteticheskiye predstavleniya.

Takzhe ne do konca opredelena granica mezhdu sredoj opisaniya aktualjnogo mira, sredoj rekonstrukcii proshlogo i sredoj planirovaniya budusjhego: eti rezhimyi mogut ispoljzovatj obsjhij mekhanizm, no trebuyut raznyikh pravil uverennosti, proverki i perekhoda k realjnyim dejstviyam.

## Chastichnoye proyasneniye

Dlya odnogo inzhenernogo klassa status opredelyon. [Dochernij fork-agent FUM](../Glossarij/dochernij-fork-agent-FUM.md) yavlyayetsya dolgovechnyim universaljnyim agentom otnositeljno kornya i nositelem versionirovannyikh [modeljnyikh sred](../Glossarij/modeljnaya-sreda.md) otdeljnyikh shagov. Yego repozitorij, konkretnyij commit-snimok sredyi i efemernaya [sessiya shaga](../Glossarij/sessiya-shaga-FUM.md) ostayutsya raznyimi susjhnostyami; modeljnyij rezuljtat ne sozdayot Git-, host- ili publikacionnyij effekt bez otdeljnogo ispolnyayemogo perekhoda i priyomki.

Eto ne otvechayet na vopros o statuse vsekh vnutrennikh FUM. Oblegchyonnaya rolj, gipoteza ili modelj vneshnego uchastnika mozhet ne imetj sobstvennogo agentskogo cikla i repozitoriya. Takzhe ostayutsya otkryityi tochnyiye tipyi vremennyikh sred, rekursivnostj vnutrennikh FUM i mashinnoye sootvetstviye mezhdu sostoyaniyem sredyi i ispolnyayemyim runtime.

## Voprosyi dlya proyasneniya

- Dolzhen li [vnutrennij FUM](../Glossarij/vnutrennij-FUM.md) byitj polnocennyim ispolnyayemyim agentskim uzlom so svoim ciklom nablyudeniya, dejstviya i [pamyati](../Glossarij/pamyatj-FUM.md), ili dostatochno boleye lyogkoj modeli roli, uchastnika ili gipotezyi?
- Mozhet li [vnutrennij FUM](../Glossarij/vnutrennij-FUM.md) imetj sobstvennyiye [vnutrenniye FUM](../Glossarij/vnutrennij-FUM.md) i sozdavatj vlozhennyiye sredyi sleduyusjhego urovnya?
- Kakiye dejstviya [vnutrennikh FUM](../Glossarij/vnutrennij-FUM.md) schitayutsya toljko modeljnyimi, a kakiye mogut perekhoditj v realjnyiye dejstviya vneshnego [FUM](../Glossarij/FUM.md) posle proverki?
- Dolzhnyi li aktualjnoye opisaniye, rekonstrukciya proshlogo i planirovaniye budusjhego byitj rezhimami odnoj sredyi ili raznyimi tipami sred?
- Kakiye pravila uverennosti, istochnikov i dostupa nuzhnyi dlya kazhdogo vremennogo rezhima?

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-06 15:14:50 MSK — Sdelatj README instrukciyej ispoljzovaniya FUM](../Zhurnal/2026-08-06_15-14-50_MSK_sdelatj-README-instrukciyej-ispoljzovaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-22 05:39:36 MSK](../Zhurnal/2026-06-22_05-39-36_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 06:17:48 MSK](../Zhurnal/2026-06-22_06-17-48_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 06:22:15 MSK](../Zhurnal/2026-06-22_06-22-15_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 06:35:26 MSK](../Zhurnal/2026-06-22_06-35-26_MSK/zapros.md)

## Zatronutaya dokumentaciya

- [Dokumentaciya/00-obzor-proyekta.md](../Dokumentaciya/00-obzor-proyekta.md)
- [Dokumentaciya/01-modelj-pamyati-FUM.md](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md](../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md)
- [Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md](../Dokumentaciya/10-vnutrenniye-modeli-drugikh-uzlov.md)
- [Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md](../Dokumentaciya/11-sreda-dlya-vnutrennikh-FUM.md)
- [Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md](../Planirovaniye/shablon-scenariya-modeljnoj-sredyi.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 18:39:31 MSK -->
<!-- content-sha256: sha256:328a5a4d1867f74ea214b52df4e4e381bcf20dca737fe0f2cd8e64d225571efa -->
<!-- FUM-MD-RECENCY:END -->
