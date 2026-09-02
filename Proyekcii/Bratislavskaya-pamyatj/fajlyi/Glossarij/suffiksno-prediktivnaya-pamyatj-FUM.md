# Suffiksno-prediktivnaya pamyatj FUM

Suffiksno-prediktivnaya pamyatj FUM - ogranichennaya, veroyatnostnaya i mnogourovnevaya [pamyatj FUM](pamyatj-FUM.md), kotoraya khranit povtoryayusjhiyesya kontekstyi peremennoj dlinyi, raspredeleniya prodolzhenij, chastotyi, davnostj, oshibki, vyiigryish predskazaniya, vyiigryish szhatiya i svyazj s rezuljtatami dejstvij.

V otlichiye ot polnogo suffiksnogo dereva, takaya pamyatj ne obyazana khranitj vse suffiksyi nablyudayemogo potoka. Ona uderzhivayet toljko te kontekstyi, kotoryiye prokhodyat otbor po poljze, stoimosti i ustojchivosti, a takzhe dopuskayet pribliziteljnoye sovpadeniye, peremennyiye slotyi, semanticheskiye klasteryi i sliyaniye pokhozhikh uzlov.

Oslableniye i pruning etoj pamyati yavlyayutsya chastnyim sluchayem [upravlyayemogo zabyivaniya FUM](upravlyayemoye-zabyivaniye-FUM.md). Kontekst nizhe poroga aktivacii perestayot uchastvovatj v obyichnom predskazanii i marshrutizacii, no pri dopustimoj politike khraneniya mozhet ostavatjsya zapisjyu kholodnogo arkhiva s proiskhozhdeniyem i prichinoj zabyivaniya. Novaya predskazateljnaya potrebnostj zapuskayet [vspominaniye FUM](vspominaniye-FUM.md), a davnostj ili nizkaya chastota sami po sebe ne dolzhnyi vyitesnyatj redkij kritichnyij signal ili delatj zabyivaniye bezvozvratnyim.

Lokaljnaya predskazateljnaya oshibka i neozhidannostj etogo sloya pitayut [profilj vnimaniya FUM](profilj-vnimaniya-FUM.md). Povtoryayemyiye ustranimyiye oshibki mogut uvelichitj dolyu nablyudeniya i aktivnogo uderzhaniya konteksta, a ustojchivo malaya kalibrovannaya oshibka pri dostatochnoj vyiborke — snizitj yeyo. Schyotchik normiruyetsya po vozmozhnostyam nablyudeniya, cene oshibki i smene raspredeleniya; inache shumnaya libo pochti ne nablyudayemaya oblastj zakhvatyivayet resurs ili, naoborot, oshibochno vyiglyadit polnostjyu predskazuyemoj.

V [potokovoj samostrukturizacii FUM](potokovaya-samostrukturizaciya-FUM.md) suffiksno-prediktivnaya pamyatj sluzhit byistryim sloyem obnaruzheniya povtoryayemosti i istochnikom kandidatov dlya [samotokenizacii FUM](samotokenizaciya-FUM.md), [strukturiruyusjhikh operatorov FUM](strukturiruyusjhij-operator-FUM.md), [patternov pamyati](pattern-pamyati.md), marshrutizacii vyichislenij i [kontroliruyemoj nejroplastichnosti FUM](kontroliruyemaya-nejroplastichnostj-FUM.md).

## Svyazannyiye dokumentyi

- [Potokovaya samostrukturizaciya FUM](../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md)
- [Obobsjhyonnyij poisk povtoryayusjhikhsya posledovateljnostej](../Dokumentaciya/08-obobsjhyonnyij-poisk-povtoryayusjhikhsya-posledovateljnostej.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-31 14:01:03 MSK - Zakrepitj otbor profilya vnimaniya FUM](../Zhurnal/2026-07-31_14-01-03_MSK_zakrepitj-otbor-profilya-vnimaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-31 12:20:47 MSK - Utochnitj vspominaniye i bezvozvratnoye zabyivaniye](../Zhurnal/2026-07-31_12-20-47_MSK_utochnitj-vspominaniye-i-bezvozvratnoye-zabyivaniye/zapros.md)
- [iskhodnyij zapros 2026-07-31 11:57:37 MSK - Zakrepitj upravlyayemoye zabyivaniye FUM](../Zhurnal/2026-07-31_11-57-37_MSK_zakrepitj-upravlyayemoye-zabyivaniye-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:aca664bd74109deac41f30deba73897c509f93894d2d7f09199b200147182a6e -->
<!-- FUM-MD-RECENCY:END -->
