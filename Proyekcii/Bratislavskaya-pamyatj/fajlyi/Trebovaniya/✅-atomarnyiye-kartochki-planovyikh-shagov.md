# Atomarnyiye kartochki planovyikh shagov

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0015 -->

Planovyij sloj [pamyati FUM](../Glossarij/pamyatj-FUM.md) dolzhen khranitj kazhdoye [predlozheniye o sleduyusjhem shage](../Glossarij/predlozheniye-o-sleduyusjhem-shage.md) kak otdeljnuyu [kartochku shaga](../Glossarij/kartochka-shaga.md). Kartochka fiksiruyet odin planovyij shag, yego ustojchivuyu identichnostj, status, zadachu i istochniki; aktualjnaya kartochka khranit obosnovaniye i kriterii zaversheniya, a istoricheskaya — rezuljtat.

Obsjhij indeks i mashinnyij planovyij reyestr stroyatsya iz kanonicheskikh kartochek i ne khranyat vtoruyu nezavisimuyu kopiyu ikh smyislovogo soderzhaniya. Imya fajla pokazyivayet emodzi zhiznennogo statusa, neizmenyayemyij identifikator i kratkoye opisaniye shaga. Perestanovka kartochek, pereimenovaniye fajla ili smena statusa ne menyayut identifikator i ne razryivayut istoriyu shaga.

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [vyibora sleduyusjhego shaga vetki iz kartochek shagov](✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md) — vetochnyij vyibor mozhet ssyilatjsya na shag toljko posle poyavleniya kanonicheskoj kartochki s proveryayemoj identichnostjyu.
- **trebuyetsya dlya:** [kontekstno posiljnyikh ispolnyayemyikh shagov](🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md) — ocenka pomesjhayemosti opirayetsya na odnu kanonicheskuyu kartochku i yeyo proveryayemyij rezuljtat.

## Kriterii proverki

- kazhdoye aktualjnoye i istoricheskoye predlozheniye o sleduyusjhem shage predstavleno rovno odnoj kanonicheskoj kartochkoj;
- kazhdaya kartochka imeyet rovno odin unikaljnyij ustojchivyij identifikator, kotoryij ne vyivoditsya iz pozicii, zagolovka, imeni fajla ili statusa i posle snyatiya ne pereispoljzuyetsya;
- imya kazhdoj kartochki imeyet vid `<эмодзи>-FUM-STEP-NNNN-<краткое-название>.md`, a validator sveryayet emodzi so statusom, nomer s `card_id`, nepustoye defisnoye opisaniye i perenosimuyu dlinu imeni; katalog kartochek ploskij, i toljko yego tochnyij kornevoj `README.md` osvobozhdyon ot kartochnogo kontrakta;
- aktualjnaya kartochka khranit nepustyiye zadachu, obosnovaniye, kriterii zaversheniya, status i khotya byi odin istochnik, a vyipolnennaya, poglosjhyonnaya ili snyataya kartochka vmesto obosnovaniya i kriteriyev khranit nepustoj rezuljtat;
- indeks kartochek tochno sovpadayet s naborom fajlov, a mashinnyij reyestr sobirayet te zhe identifikatoryi, statusyi i soderzhaniye;
- validator otklonyayet dubliruyusjhiyesya identifikatoryi, neindeksirovannyiye ili otsutstvuyusjhiye kartochki, nedopustimyiye statusyi, pustyiye obyazateljnyiye razdelyi i povrezhdyonnyiye ssyilki na istochniki;
- peresborka mashinnogo reyestra iz neizmenivshikhsya kartochek dayot bajtovo identichnyij rezuljtat.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: trebovaniye realizovano v dokumentacionnom prototipe: predlozheniya dekompozirovanyi v otdeljnyiye kanonicheskiye kartochki, a ikh indeks i mashinnoye predstavleniye proveryayutsya avtonomnyimi testami i polnyim smoke-check.

Kartochka ne delayet planovyij shag novyim trebovaniyem i ne obesjhayet yego ispolneniye. Smyislovoj vyibor ocheryodnosti, prioriteta ili snyatiya shaga ostayotsya otdeljnyim resheniyem rabochej sessii ili planirovsjhika. Produktovyij runtime budusjhej korobochnoj FUM etoj kartochkoj ne schitayetsya realizovannyim.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK — Dekompozirovatj predlozheniya na kartochki shagov](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK — Zafiksirovatj poshagovyij otbor realizacii](../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK — Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-20 21:22:17 MSK — Vklyuchitj kartochki trebovanij v mashinnyij planovyij reyestr](../Zhurnal/2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)
- [iskhodnyij zapros 2026-07-22 11:48:49 MSK — Oformitj kartochki shagov opisateljnyimi imenami i emodzi statusami](../Zhurnal/2026-07-22_11-48-49_MSK_oformitj-kartochki-shagov-opisateljnyimi-imenami-i-emodzi-statusami/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:83721ce2edfca8156cb0e2009477f2077e2de2696e15a0025ea586dcb0d34cbc -->
<!-- FUM-MD-RECENCY:END -->
