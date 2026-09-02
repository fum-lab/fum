# Darvinovskij planirovsjhik FUM

Darvinovskij planirovsjhik FUM - arkhitekturnyij modulj, kotoryij zapuskayet [FUM-uzlyi](FUM-uzel.md), vyibirayet adresatov dlya peredachi [peredavayemyikh rezuljtatov](peredavayemyij-rezuljtat-FUM.md), organizuyet [dvukhkonturnyij otbor](dvukhkonturnyij-otbor-FUM.md), uchityivayet stoimostj prodolzheniya i obnovlyayet [vesa agentov](ves-agenta-FUM.md) i [vesa svyazej](ves-svyazi-FUM.md) po itogovoj poleznosti rezuljtatov.

Planirovsjhik ne zamenyayet [obobsjhyonnyij darvinovskij algoritm](obobsjhyonnyij-darvinovskij-algoritm.md), a delayet yego ispolnyayemyim na urovne repozitoriya, workflow, agentskikh zapuskov i [pamyati FUM](pamyatj-FUM.md).

Na urovne planirovaniya realizacii takoj planirovsjhik dolzhen umetj vyibiratj ocheryodnostj uzhe opisannyikh [kartochek shagov](kartochka-shaga.md): podnimatj blizhajshij proveryayemyij shag, ostavlyatj drugiye aktualjnyiye kartochki v pule, otkladyivatj prezhdevremennyiye konturyi i snimatj variantyi, kotoryiye ne vyiderzhivayut proverki cenoj, riskom, poleznostjyu ili svyaznostjyu proiskhozhdeniya.

Blizhajshij dokumentacionnyij prototip ispoljzuyet ogranichennuyu politiku `dynamic-readiness-source-history-first-parent-v2`: neposredstvenno pered zapuskom ona vyichislyayet gotovnostj konechnogo whitelist po tochnyim zavershyonnyim kartochechnyim zavisimostyam, a zatem predpochitayet kandidata, chji lokaljnyiye istochniki svyazanyi s nedavnimi first-parent-kommitami tochnogo `HEAD`, chtobyi soderzhateljno blizkiye izmeneniya po vozmozhnosti shli podryad. Eto ne obsjhij raschyot poleznosti: mashinnyiye zavisimosti i signal istorii lishj filjtruyut i uporyadochivayut predvariteljno attestovannyiye variantyi i ne mogut vyivesti bezopasnostj, polnomochiya, vyibor poljzovatelya ili kontekstnuyu posiljnostj iz teksta.

V runtime korobochnoj realizacii planirovsjhik mozhet vyibiratj [fonovoye zadaniye FUM](fonovoye-zadaniye-FUM.md) toljko pri odnovremennom otsutstvii neobrabotannogo poljzovateljskogo vvoda i gotovyikh zadach boleye vyisokogo prioriteta. Kazhdoye takoye zadaniye poluchayet ogranichennyij byudzhet i bezopasnuyu kontroljnuyu tochku, a pri poyavlenii boleye prioritetnoj rabotyi priostanavlivayetsya ili zavershayetsya s sokhraneniyem nablyudayemoj trassyi.

## Svyazannyiye dokumentyi

- [Git-infrastruktura evolyucionnyikh cepochek FUM](../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Obobsjhyonnyij darvinovskij algoritm](obobsjhyonnyij-darvinovskij-algoritm.md)
- [Moduljnaya arkhitektura FUM](../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md)
- [Ves svyazi FUM](ves-svyazi-FUM.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-29 09:04:03 MSK — Rasshiritj dinamicheskij vyibor sleduyusjhego shaga](../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [iskhodnyij zapros 2026-07-27 18:28:42 MSK — Vyibiratj sleduyusjhij shag pri zapuske s uchyotom istorii kommitov](../Zhurnal/2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK - Zafiksirovatj poshagovyij otbor realizacii](../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-14 03:18:36 MSK - Zakrepitj fonovyiye zadaniya dlya prostoya LLM](../Zhurnal/2026-07-14_03-18-36_MSK_zakrepitj-fonovyiye-zadaniya-dlya-prostoya-LLM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:58f195453a51e8b163d262fe2bbb7172e05911157decc3b19baf688904c4f8c3 -->
<!-- FUM-MD-RECENCY:END -->
