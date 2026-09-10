# Karta obyyedineniya vedusjhej vetki i master

Proverenyi sokhranyonnyiye Git-obyyektyi. Vedusjhaya vetka L — `codex/планирование-наблюдения-macos-01a07d3d`, `ef0b528c8c117f7cfddb83d1699aa333d9c486a5`. Sopostavleniye s master `76f71fad3adab90f85ae31cb2f7d75f6ceb12e8d` pokazalo 6 sobstvennyikh kommitov master i 33 vedusjhej vetki. Zatem v master prinyat normativnyij etap `4db1f8f64996d7ca2f9ec30cbc52ef3399a34a4f`. Tekusjhaya rabota prodolzhayetsya ot nego. Karta poluchena chteniyem; sliyaniye i proverki kandidata yesjhyo ne vyipolnyalisj.

## Uzhe gotovyiye operacii

Osnovnyiye ispolniteli i test pula pobajtno sovpadayut v pervonachaljno sravnyonnyikh vershinakh:

- `Инструменты/fum-ocheredj-zadach-git-vetki/scripts/пул-worktree-подузлов.py` — blob `679e08388aa2c6e50e31ce5b6146ad3f438be41b`.
- `Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py` — blob `a70b9527549960a01022d02f93c667f777dbf90c`.
- `Инструменты/fum-ocheredj-zadach-git-vetki/tests/test_пул_worktree_подузлов.py` — blob `b44a6f89eebab53a4d5f94d8f2430877d4c715a4`.

V pule uzhe yestj podgotovka nastoyasjhego merge cherez `команда_слияния`, vosstanovleniye chistogo i konfliktnogo sostoyaniya, proverka poryadka roditelej, zamorozka kandidata i zapusk prodvizheniya. V ocheredi `принять_интеграционный_кандидат` podgotavlivayet checkout i indeks, proveryayet derevo i provodit CAS-tranzakciyu celevogo ref, ocheredi, pula i kvitancii s obrabotkoj otkaza. Soderzhateljnyiye regressii okhvatyivayut nastoyasjheye sliyaniye, konflikt, preryivaniye, povtor, gryaznoye sostoyaniye i soglasovaniye primary.

Gotovyij marshrut svyazan s assignment, FIFO, prodolzheniyami i publikacionnyimi namereniyami. Dlya odnogo ogranichennogo obyyedineniya podlezhat povtornomu ispoljzovaniyu nuzhnyiye operacii i regressii; nalichiye koda samo po sebe ne vklyuchayet vesj staryij rezhim.

## Sokhranyayemyiye rezuljtatyi master

- `f74763f5` — modelj betonnyikh glubinnyikh sistem, istochniki i planyi, obsjheye ochisjheniye sluzhebnyikh HTTP-zagolovkov oboimi arkhivatorami i test. Pryamogo pokryitiya v L net.
- `84d10f88` — fakticheskaya priyomka arkhivnogo snimka FUMA i sokhraneniye bajtov obyichnyikh Git-ignoriruyemyikh fajlov `.DS_Store`. Release uzhe yestj v L vmeste s kyeshem, no yeyo generator udalyayet eti fajlyi pri ochistke kataloga; celikom vyibiratj yego versiyu neljzya.
- `11d1b5fd` — prodolzheniye posle kommita, vladeniye zapisjyu pered kazhdyim etapom i sovmestimostj prezhnikh v3-svideteljstv. Samo prodolzheniye uzhe yestj v L; pravila paralleljnoj zapisi i publikacii otlichayutsya i trebuyut yavnogo soglasovaniya.
- `6fc2c7a` — strogaya svyazj prinyatogo otpechatka s kommitom, regressii i zakreplyonnyij import istoricheskikh obyazateljstv.
- `ef6b936b` — chteniye zakryitogo otchyota iz tipizirovannyikh neizmenyayemyikh blobs Git, proverka gotovnosti i strogij paketnyij razbor. V4-obyortka L etot rezuljtat ne zamenyayet.
- `76f71fad` — reyestr v3, chteniye polnogo DAG, neizmennostj opredelenij i svideteljstv, aktualjnostj rezuljtatov. Vmesto nego L soderzhit reyestr v2 po tomu zhe puti.
- `4db1f8f6` — normyi ponyatnogo opisaniya avtomatizacij, samostoyateljnogo soobsjheniya susjhestvennyikh riskov i ogranichennoj integracii. Napravleniye integracii utochnyayetsya pryamoj sleduyusjhej komandoj poljzovatelya.

## Realjnyiye nesovmestimosti

U L reyestr imeyet skhemu `.2` i genezis `008f27dc`, u master — `.3` i zakreplyonnyij import `6fc2c7a`. Novyij chitatelj proveryayet vse versii na DAG; prostoj vyibor fajla v3 v rezuljtate ostavit v prisoyedinyonnoj istorii versii v2 i vyizovet otkaz. Guard L vyizyivayet `проверить_обязательства`, kotoroj net v novom module master. Nuzhna sovmestimostj proiskhozhdeniya i interfejsa, bez molchalivogo otbrasyivaniya istoricheskikh obyazateljstv.

Chitatelj master proveryayet zakryityij v3-kontur. V obyortke L yego funkcii sokhranenyi, no zapresjhayut peredavatj im v4 kak prezhnyuyu skhemu. Staryiye v3-svideteljstva sokhranyayutsya; priznaniye novyikh v4 trebuyet yavnogo sootvetstvuyusjhego chitatelya. Uzhe gotovyiye v4-raundyi i soderzhateljnyij otpechatok povtorno ne realizuyutsya.

Priyomka starogo pula sokhranyayet Markdown, peredannyij verdikt, nazvaniya proverok i khyesh otchyota. Ona ne razbirayet zakryityij v3-zhurnal i ne vosstanavlivayet yego svyazj s C. Nezavisimoye ozhidayemoye derevo ne peredayotsya otdeljnyim vkhodom, a poryadok roditelej proveryayetsya cherez `rev-list`. Eto uzkiye nedostayusjhiye dokazateljstva, a ne otsutstviye Git-mekhaniki.

## Prinyatyij poryadok sleduyusjhej rabotyi

Po utochneniyu poljzovatelya master M vlivayetsya v vedusjhuyu L. Kandidat C imeyet roditelej `[L, M]`; posle priyomki master prodvigayetsya do togo zhe C. Pravila i proveryayusjhij kod proiskhodyat iz M; predkommitnyij HEAD i baza v3-otpechatka — L. Eti osnovaniya ne vzaimozamenyayemyi.

Snachala podgotavlivayetsya odin konkretnyij kandidat na osnove L i soglasuyutsya perechislennyiye rezuljtatyi. Sostoyaniye «podgotovlen» ne oznachayet «prinyat». Dorabotki dopuska opredelyayutsya po etomu kandidatu. Chastnyiye chernoviki novogo merge-reader i yego testov ne vnesenyi v checkout; ikh razvitiye priostanovleno, chtobyi ne podmenyatj sostavleniye kandidata predvariteljnyim sozdaniyem novoj obsjhej sistemyi.

## Istochnik

- [Komandyi poljzovatelya i soderzhateljnyiye otvetyi](../zapros.md).
- [Kartochka perekhoda k vedusjhej vetke](../../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 14:37:13 MSK -->
<!-- content-sha256: sha256:b842095cb96c24546657947653c88e5af322a530422df14d67b12601a39799ef -->
<!-- FUM-MD-RECENCY:END -->
