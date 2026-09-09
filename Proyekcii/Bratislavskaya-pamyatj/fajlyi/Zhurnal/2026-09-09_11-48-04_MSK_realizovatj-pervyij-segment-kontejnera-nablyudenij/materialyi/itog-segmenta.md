# Itog ogranichennogo pervogo segmenta

Realizovan avtonomnyij paket Packages/KontejnerNablyudenij v naznachennom otdeljnom kodovom repozitorii. Biblioteka khranit JSON-zagolovki i syiryiye binarnyiye fragmentyi v odnom segmente; otdeljnyiye writer, reader, recovery i profile CLI ne zapuskayut prilozheniye i organyi nablyudeniya. Identifikator proiskhozhdeniya — FUMA 01a07d3d-d376-7ad2-aafc-67e4c25a67eb.

## Nablyudyonnyiye proverki

Poslednij obsjhij progon: 28 testov v 5 naborakh, uspeshno, 1,091 s po Swift Testing; process 3,184282584 s po v4 №40. Release-sborka posle optimizacii uspeshna (v4 №33). Finaljnyij [snimok 15 Swift-fajlov](iskhodniki-itoga.json) vklyuchayet pozdnij nezavisimyij oracle khyesha; production-kod sovpadayet so [snimkom kontroljnogo profilya](iskhodniki-posle-profilya.json).

Proverenyi:

- Polnyij write do fsync fajla/kataloga i do ack; EINTR, korotkij/nulevoj write, ENOSPC i poisoned state posle otkaza.
- Vidimyij polnyij commit posle oshibochnogo file/directory fsync ne dayot podtverditj retry bez novogo uspeshnogo sync. Povtor sravnivayet ID, tip, versiyu skhemyi, istochnik, vremya, specifikaciyu i dannyiye.
- Kazhdyij bajt usecheniya vtoroj gruppyi, polnyiye data bez commit, neizmennostj zafiksirovannogo prefiksa posle vosstanovleniya; kazhdyij bajt povrezhdeniya polnogo fajla otklonyayetsya bez obrezki.
- Neizvestnyij tip, vse 256 znachenij bajta, signaturyi/perevodyi strok/NUL vnutri payload; pustoye nablyudeniye i Data s nenulevyim startIndex.
- Nevernyiye posledovateljnostj/smesjheniya/dlinyi/commit i JSON s lishnimi/povtornyimi polyami pri praviljnyikh khyeshakh; predeljnyiye zagolovki/obyyektyi/chislo zapisej/fragmentov, sparse-fajlyi, limityi vkhoda do allocation.
- Simvoljnyiye/zhyostkiye ssyilki, FIFO, nebezopasnyiye prava, NUL kornya; susjhestvuyusjhij nulevoj fajl ne zamenyayetsya, recovery ne sozdayot otsutstvuyusjhij.
- Otdeljnyiye processyi writer/reader/recovery; konkurentnyij otkaz bez zapisi, osvobozhdeniye lock posle SIGKILL vladeljca, kornevoj lock do sozdaniya fajla, yavnoye osvobozhdeniye pri zhivyikh dup fd.

SIGKILL primenyayetsya k gotovomu vladeljcu lock pustogo validnogo segmenta. Eto ne ubijstvo pisatelya mezhdu write i sync. Recovery posle nepolnoj zapisi proverena otdeljnyim processom na vruchnuyu usechyonnoj sinteticheskoj fiksture; oshibki I/O vnedrenyi v bibliotechnyiye operacii.

## RED, ispravleniya i revjyu

Istoriya v4 ne perepisana. №1 otkazal v codesign do testov; №2–4 fiksirovali iskhodnyij povedencheskij RED. №5 vyiyavil ENOTDIR testovogo puti, №6 dal semj GREEN posle realpath. №7/9/11/16/19 fiksiruyut otkaz susjhestvuyusjhego nulevogo fajla, NUL URL, oshibochnoye sozdaniye v recovery, prodolzheniye posle povrezhdeniya, avarijnyij Data slice i gonku pervogo sozdaniya; sootvetstvuyusjhiye ispravleniya voshli v posleduyusjhiye GREEN. №8 — oshibka kompilyacii testovoj makrokomandyi, ne povedencheskij RED. №10 prervan SIGTERM (143) iz-za blokiruyusjhego chteniya testovogo barjyera; pozdneye najdennyiye sobstvennyiye helper/holder processyi ostanovlenyi, posle perekhoda na poll + POSIX read processnyiye testyi zavershayutsya.

Posle root flock obsjhij paralleljnyij progon №20 poluchil .zanyat pri povtornom otkryitii. Yavnyij LOCK_UN pered close i otdeljnaya proverka zhivyikh dup ustranili otkaz. Nasledovaniye fd konkurentnyim Foundation Process — obyyasnyayusjhaya gipoteza, ne neposredstvenno zafiksirovannaya trassa fork.

Nezavisimyij subagent rabotal toljko chteniyem. Najdennyiye im oshibki nulevogo fajla, otsutstvuyusjhego recovery, poisoned state i gonki pervogo sozdaniya ispravlenyi i pokryityi testami. Finaljno proverenyi primenyonnyij autoreleasepool i nezavisimyij oracle; utochnenyi nachaljnyij chain hash (SHA-256 FUMOBS01) i granica O_NOFOLLOW vkhodnyikh fajlov v README. Nezavisimoye revjyu ne yavlyayetsya zapuskom testov.

Profilj obosnoval odnu optimizaciyu diagnostiki: №31 RED RSS 75366400 bajt, posle lokaljnogo autoreleasepool obsjhij №32/40 GREEN. [Shestj izmerenij i resheniye](profilj-i-resheniye.md) pokazyivayut snizheniye recovery RSS s 71,67 do 9,27–9,28 MiB bez izmeneniya bajtov. Uskoreniye vremeni ne zayavlyayetsya.

## Granica priyomki

Vyipolnen ogranichennyij poljzovateljskij rezuljtat pervogo segmenta, ne vsya FUM-STEP-0156. Ostayutsya za yego predelami: rotaciya i mnogosegmentnyiye indeksyi, integraciya prilozheniya/sensorov, realjnaya pamyatj, proverka perezapuska OS, otkaza yadra i poteri pitaniya. fsync ne podmenyayetsya dokazateljstvom fizicheskoj dolgovechnosti; F_FULLFSYNC ne ispoljzuyetsya. Advisory lock trebuyet uchastnikov protokola i podderzhki directory flock tekusjhej fajlovoj sistemoj.

Obsjhij FUM smoke i realjnaya bratislavskaya proyekciya ne vyipolnyalisj po yavnomu naznacheniyu: ikh provodit planirovsjhik pri integracii. Pokoleniye Proyekcii unasledovano ot ba6f1c7907478a638c9f0fda6d93f6da37a7fcf5 i ne aktualizirovano novyim Zhurnalom. Dopusk kontroljnoj tochki raneye vozvrasjhal kod 1 toljko iz-za 282 istoricheskikh ssyilok na otsutstvuyusjhij ignoriruyemyij poljzovateljskij .obsidian/graph.json; etot otkaz ne nazyivayetsya uspekhom. Primenena sokhranyonnaya v zaprose granica vremennoj neprimenimosti, poljzovateljskij graph ne sozdavalsya i ne kopirovalsya.

Kodovyij repozitorij ne imeyet remote i ne obyyavlyayetsya podklyuchyonnoj opublikovannoj Git-zavisimostjyu FUM. V FUM sokhranyayetsya Zhurnal i proiskhozhdeniye, ne gitlink i ne kopiya iskhodnikov. Publikuyetsya toljko sobstvennaya naznachennaya non-master vetka FUM v proverennyij origin, bez force i izmeneniya chuzhikh refs.

Pri itogovoj proverke svyaznosti otdeljno ispravlenyi obyazateljnyij prefiks «Granica profilya:» i ustarevshij predprosmotr posle izmeneniya otchyota. Pryamoj dopusk ne vklyuchayetsya rekursivno v v4; yego staryiye otkazyi ne podmenyayutsya uspekhom. Shestj sobstvennyikh vremennyikh profilirovochnyikh segmentov udalenyi posle sokhraneniya chisel i khyeshej; poljzovateljskiye fajlyi ne udalyalisj.

## Princip avtomatizacii

Pozdneye upravlyayusjheye ukazaniye sokhraneno doslovno v zaprose. Rezuljtat avtomatiziruyet povtoryayusjhuyusya zapisj, proverku, chteniye i vosstanovleniye cherez biblioteku/CLI, a ne sokhranyayet odin vruchnuyu sozdannyij kontejner. Sleduyusjhij urovenj uzhe chastichno obespechen Swift Testing i profile CLI: sinteticheskij vkhod generiruyetsya avtomaticheski, JSON-metriki vosproizvodimyi, oshibka RSS stala avtomaticheskoj regressiyej s nezavisimyim oracle.

Obyyedineniye build/test/serij profilya v otdeljnyij obsjhij ispolnitelj rassmotreno kak sleduyusjhij ogranichennyij urovenj, no ne dobavlyayetsya k soglasovannomu pervomu segmentu: tekusjhiye standartnyiye komandyi vosproizvodimyi, novyiye fonovyiye zadachi ne nuzhnyi, obsjhij scenarij FUM nakhoditsya u planirovsjhika. Obsjhiye pravila v etoj vetke ne perepisyivalisj. Iskhodnyiye RED i izmereniya sokhranenyi.

## Istochniki

- [Iskhodnyij zapros i peredacha polnomochij](../zapros.md).
- [Otchyot i vse pryamyiye proverki](../otchyot.md).
- [Profilj i vosproizvodimyiye komandyi](profilj-i-resheniye.md).
- [Sokhranyonnaya kontroljnaya tochka yadra](proverki-yadra.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 12:59:56 MSK -->
<!-- content-sha256: sha256:4a0239ca20ade1e4ad283f225e50072f3d40740130f88e4d7c44793481af09ae -->
<!-- FUM-MD-RECENCY:END -->
