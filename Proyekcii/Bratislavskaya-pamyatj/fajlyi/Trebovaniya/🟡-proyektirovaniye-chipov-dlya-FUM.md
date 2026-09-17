# Proyektirovaniye chipov dlya FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0078 -->

FUM dolzhen razvivatj napravleniye proyektirovaniya chipov dlya apparatnoj realizacii ustojchivyikh i chasto trebuyemyikh skhem strukturiruyusjhikh operatorov. Kandidat vyibirayetsya po vosproizvodimyim nablyudeniyam programmnogo ispolneniya; tematicheskaya vazhnostj sama po sebe ne dokazyivayet chastotu, stabiljnostj ili poljzu apparatnogo perenosa.

## Semanticheskiye svyazi

Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.

## Kriterii proverki

- Dlya konechnogo nabora kandidatov sokhranenyi tochnaya semantika, vkhodyi i vyikhodyi, razryadnostj, dopustimyiye obyyomyi, oshibki i ogranicheniya. Kandidatyi mogut vklyuchatj kodirovaniye Unicode, proverku granic i povtoryayemuyu cepochku operatorov; ikh chastota i prigodnostj yesjhyo podlezhat izmereniyu.
- Na zakreplyonnom programmnom ispolnitele izmerenyi chastota po obyyavlennomu naboru nagruzok, zaderzhka, propusknaya sposobnostj, obyyom peremesjhyonnyikh dannyikh i, pri dostupnom izmeritele, energiya na poleznyij rezuljtat. Podgotovka, I/O i vyichisleniye razdelenyi, stoimostj granicyi host/uskoritelj vklyuchena. Istochnik, vyiborka, yedinicyi i neopredelyonnostj sokhranenyi.
- Pervyij apparatnyij kandidat prokhodit nezavisimyiye ozhidayemyiye rezuljtatyi, granichnyiye i oshibochnyiye vkhodyi, sravneniye s programmnyim ispolnitelem i vosproizvodimuyu FPGA-proverku. Sintez, modelirovaniye i zapusk na konkretnoj plate razlichayutsya. Otsutstvuyusjhaya plata ili SDK sokhranyayutsya kak ogranicheniye, bez zayavleniya apparatnogo uspekha.
- Perekhod k ASIC cherez proizvodstvennogo partnyora obosnovan rezuljtatami kandidata: modeljyu plosjhadi, mosjhnosti, zaderzhek, interfejsov pamyati, proveryayemosti, korpusa i tekhnologicheskikh ogranichenij. Ocenka instrumentov i PDK s usloviyami dostupa otdelena ot fakticheskogo sign-off i izgotovleniya.
- Sobstvennoye proizvodstvo oformleno otdeljnyim daljnim etapom: celevoj process, oborudovaniye, resursyi, kompetencii, izmerimostj kachestva i vyikhoda godnyikh, zavisimosti i kriterii perekhoda. Yego gotovnostj ne vyivoditsya iz gotovnosti RTL, FPGA ili partnyorskogo ASIC.
- Dlya kazhdogo perekhoda zadan proveryayemyij rezuljtat i usloviye otkaza libo peresmotra; dopustimo ostavitj skhemu programmnoj pri otsutstvii dokazannoj poljzyi apparatnogo varianta.

## Status i granicyi

Status trebovaniya — `🟡`.

Napravleniye prinyato v planirovaniye. Issledovaniye konkretnoj arkhitekturyi, FPGA-zapusk i izgotovleniye ne vyipolnenyi. Zakupki, vneshniye obrasjheniya i vyibor proizvodstvennogo partnyora v tekusjhij obyyom ne vkhodyat. Vozmozhnostj sobstvennogo proizvodstva sokhranyayetsya kak otdeljnaya dolgosrochnaya celj.

Pervyij shag — [vyibratj operatornuyu skhemu](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0229-vyibratj-operatornuyu-skhemu-dlya-apparatnoj-proverki.md). [Inzhenernyij pasport kremniyevogo substrata](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0017-opisatj-inzhenernyij-pasport-kremniyevogo-substrata-FUM.md) zadayot smezhnyij apparatnyij kontekst i fizicheskiye ogranicheniya, no ne zamenyayet proyektirovaniye novogo chipa.

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-16_00-55-04_MSK_prinyatj-postanovku-chipovogo-napravleniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:06:47 MSK -->
<!-- content-sha256: sha256:4240ff2d3f37fd977b560f811bf7906c58f4c0365ad7d6388ee0c31f6f166eb5 -->
<!-- FUM-MD-RECENCY:END -->
