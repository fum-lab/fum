# Iyerarkhiya funkcij i dannyikh FUM

Iyerarkhiya funkcij i dannyikh FUM - arkhitekturnyij princip, po kotoromu [FUM](FUM.md) razlichayet boleye byistro menyayusjhiyesya dannyiye i boleye ustojchivyiye funkcii, kotoryiye eti dannyiye obrabatyivayut. Telo funkcii obyichno izmenyayetsya rezhe, chem yeyo vkhodyi, no samo telo mozhet stanovitjsya dannyimi dlya boleye bazovoj funkcii, kotoraya sozdayot, ispravlyayet, otbirayet ili zamenyayet funkcii sleduyusjhego urovnya.

V etoj ramke [pamyatj FUM](pamyatj-FUM.md), [moduli FUM](modulj-FUM.md), [avtomatizacii](avtomatizaciya-FUM.md), agentskiye nastrojki i nejrosetevyiye vesa obrazuyut raznyiye tempyi izmeneniya. Byistryij sloj prinimayet novyiye vkhodyi i trassyi, srednij sloj menyayet parametryi, pravila, marshrutyi ili adapteryi, a medlennyij sloj menyayet sami sposobyi postroyeniya i proverki funkcij.

Princip ne oznachayet zhyostkuyu centralizovannuyu vlastj verkhnego urovnya nad nizhnim. Boleye bazovyij sloj poluchayet pravo menyatj proizvodnyij sloj toljko cherez proiskhozhdeniye, proverku, byudzhet, kriterii poljzyi, vozmozhnostj otkata i [obobsjhyonnyij darvinovskij algoritm](obobsjhyonnyij-darvinovskij-algoritm.md). Poetomu takaya iyerarkhiya opisyivayet ne status nachaljstva, a ustojchivuyu lestnicu tempov izmeneniya.

Klassicheskaya iskusstvennaya nejrosetj yavlyayetsya chastnyim primerom: process obucheniya vyistupayet boleye medlennoj funkciyej, kotoraya porozhdayet setj, a setj zatem byistreye obrabatyivayet vkhodnyiye dannyiye. Dlya FUM trebuyetsya boleye mnogourovnevaya i gibkaya forma etogo principa, gde funkcii, dannyiye, parametryi, trassyi i meta-funkcii mogut nakhoditjsya na neskoljkikh proveryayemyikh urovnyakh.

Minimaljnaya yedinica takoj iyerarkhii vklyuchayet telo preobrazovaniya, pattern primenimyikh vkhodov, sostoyaniye ili parametryi, istoriyu primeneniya, ocenku poljzyi, meru ustojchivosti i mekhanizm izmeneniya. Malyij cikl rabotyi etoj yedinicyi sostoit iz chetyiryokh dejstvij: primenitj funkciyu k dannyim, ocenitj rezuljtat, izmenitj podkhodyasjhij urovenj i zakrepitj udachnyij variant. Chem fundamentaljneye urovenj, tem dorozhe yego izmeneniye i tem siljneye dolzhnyi byitj osnovaniya dlya zakrepleniya.

## Svyazannyiye dokumentyi

- [Arkhitektura FUM](../Dokumentaciya/22-arkhitektura-FUM.md)
- [Moduljnaya arkhitektura FUM](../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md)
- [Potokovaya samostrukturizaciya FUM](../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md)
- [Evolyuciya i myishleniye](../Dokumentaciya/03-evolyuciya-i-myishleniye.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-06 14:49:39 MSK - Opisatj iyerarkhiyu funkcij i dannyikh](../Zhurnal/2026-07-06_14-49-39_MSK_opisatj-iyerarkhiyu-funkcij-i-dannyikh/zapros.md)
- [iskhodnyij zapros 2026-07-06 15:00:09 MSK - Utochnitj iyerarkhiyu funkcij i dannyikh](../Zhurnal/2026-07-06_15-00-09_MSK_utochnitj-iyerarkhiyu-funkcij-i-dannyikh/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:14fdcb04c6135d7f7ce8a283315645a6781f96293dd9ff948123c6657bc3dfd8 -->
<!-- FUM-MD-RECENCY:END -->
