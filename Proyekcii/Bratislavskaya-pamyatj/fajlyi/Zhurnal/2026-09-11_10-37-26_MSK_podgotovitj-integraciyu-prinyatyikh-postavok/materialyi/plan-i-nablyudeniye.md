# Podgotovka sovmestnoj integracii

Podgotovka vyipolnena po [iskhodnomu zaprosu](../zapros.md) do polucheniya finaljnogo 0201. Nachalo — commit `10dc3b2149d2121c1d02926ca409c1299f2b4b5c`, tree `02a3625db37ece53616563d66f14f71312ad8085`; sobstvennaya vetka — `refs/heads/codex/интеграция-поставок-01a08f62`. Pervonachaljnyij detached HEAD ispravlen naznacheniyem novoj vetki ot togo zhe OID posle soobsjheniya koordinatoru. Eto ne izmeneniye bazyi.

## Zakreplyonnyiye vkhodyi

| Vkhod          | Commit                                   | Tree                                     | Kanonicheskiye puti |
| ------------- | ---------------------------------------- | ---------------------------------------- | ----------------- |
| 0176          | 6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95 | 2fd6153375357c8750e0f24c30364fde233cdaa7 | 149               |
| 0177/0154     | d635cfff2e5f9073a61ebfece1f0f3f51afd5417 | 12a0ba08dc0de20a36208cf879c262682e5557e5 | 41                |
| planirovaniye | 186b0360a31b97184773757634976257d0f86495 | d75d8c0daa7ade103fb9c8ccd8185c7264d3d4ed | 65                |
| 0201          | 6bf2f53fc76069b02ba1eae3ed31235716f0f1cd | 860a0dd135f395ef29d26d34491a6782c35c7ff5 | utochnyayetsya        |
| Matematika    | b762bd0cb77fdbcc418141a1f33800a7bdb630a6 | 1b065e4463e1246375df0aed9799f3ccd459cd35 | 58                |
| 0207          | 1c31740699c8937d610eea45c4a3326314923330 | 26f6b940698432bb93a232c9ef3e636a81dbfdc0 | 87                |
| 0208          | f49eeee3fd80a87cd63391d6606dafa19cd6d2b8 | e5154ac2522cbdc5b761bcbdc8d8756ca4c32ace | 103               |

Nezavisimyij pomosjhnik poluchil derevjya cherez Git-obyyektyi i adresnyiye diff, bez zapisi, testov i probnogo merge. Chislo putej vyichisleno otnositeljno obsjhej bazyi `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`, bez `Proyekcii/`, `Журнал/` i `Индексы/`; unasledovannyiye izmeneniya vklyuchenyi. U vsekh shesti vkhodov ta zhe obsjhaya baza s postanovkoj, ni odin ne poglosjhayet drugoj. Integrator otdeljno podtverdil shestj tochnyikh opublikovannyikh refs cherez odin adresnyij `git ls-remote --heads origin`; adres naznacheniya — proverennyij publichnyij repozitorij FUM. Eto podtverzhdayet dostupnostj vkhodov, ne sovmestnuyu priyomku.

Prinyata okonchateljnaya [peredacha 0201](prinyataya-peredacha-0201.txt); integrator otdeljno podtverdil tochnyiye commit/tree/parent i opublikovannyij ref. Poryadok semi vkhodov razreshyon k ispolneniyu.

## Poryadok ispolneniya

Posle prinyatoj koordinatorom peredachi okonchateljnogo 0201 zakrepitj yego commit/tree, polozhiteljnyij polnyij dopusk i nezavisimuyu kvitanciyu. Adresno dopolnitj kartu ancestry/diff imenno etim vkhodom. Do etogo merge zapresjhyon; ozhidayemoye osvobozhdeniye tyazhyologo smoke otdeljno podtverzhdayetsya koordinatorom.

Posledovateljnostj sokhranyayetsya: 0176 → 0177/0154 → planirovaniye → 0201 → matematika → 0207 → 0208. Dlya kazhdogo shaga zaraneye zapisatj tekusjhij HEAD i tochnyij vkhod, zatem primenyatj obyichnoye sliyaniye v sobstvennom dereve s ostanovkoj pered kommitom. Sokhranitj roditeli, rezuljtat, konfliktnyiye puti, prinyatoye resheniye po kazhdoj storone i itogovoye derevo; soderzhateljnyiye promezhutochnyiye etapyi fiksirovatj kontroljnyimi kommitami po dejstvuyusjhemu dopusku. Chuzhiye refs ne dvigayutsya. Finaljnaya integraciya v fuma trebuyet peredachi yeyo yedinstvennomu pisatelyu.

Proizvodnuyu proyekciyu ne slivatj vruchnuyu: posle kanonicheskogo soglasovaniya ispoljzovatj shtatnyiye generator i nezavisimyij manifest. Yesli promezhutochnaya kontroljnaya tochka sokhranyayet predyidusjheye pokoleniye, yavno fiksirovatj yego vkhod i otstavaniye. Zakryityiye zhurnalyi i mashinnyiye svideteljstva obeikh linij sokhranyayutsya; tekusjhiye navigaciya i indeksyi vyivodyatsya susjhestvuyusjhimi instrumentami.

## Sovmestnyiye granicyi vnimaniya

- Proyektor: soglasovatj realizaciyu, kontrakt v2, skhemu i testyi. Sokhranitj `.c/.h`, `.modulemap/.pbxproj/.plist/.entitlements` i tochnyij fajl gitignore prilozheniya iz 0176, ogranichennyij JS-adapter iz linii 0201 i neobyazateljnyij otsutstvuyusjhij fajl grafa iz matematiki. Vyibor celogo konfliktnogo fajla odnoj storonyi nedopustim bez dokazateljstva sokhraneniya drugoj.
- Politika lokaljnyikh putej: sokhranitj 65 tochnyikh dobavlenij 0176 i shestj nezavisimyikh dobavlenij matematicheskoj linii; adresnyiye stroki sveritj s fakticheskimi obyyedinyonnyimi fajlami.
- Pravila: sokhranitj isklyucheniya postoyannyikh vetok fuma i planirovaniye, obyazateljnyij ostatok soobsjhenij i iskhodnik 0177, priyom napravlenij, trebovaniye tochnogo kommita postanovki, vidimoj zadachi i nablyudayemoj modeli. Do zapisi pravil prochitatj polnyij obyyedinyonnyij marshrut i proveritj inventarj s khyeshami.
- Obrabotka soobsjhenij i zaversheniye: chetyire osnovnyikh fajla 0177 i matematicheskoj vershinyi sovpadayut; sovmestnogo vnimaniya trebuyut dopolneniya 0154, profilj ostatka, testyi i ispravleniye neobyazateljnogo grafa v svyaznosti.
- Planovyij reyestr: sokhranitj tochnyij marker otsutstvuyusjhikh pryamyikh semanticheskikh svyazej i yego proverku iz planirovaniye vmeste s priyomom napravlenij. Soglasovatj kartochki 0165, platformyi i DNK s finaljnyim 0201.
- Matematika: sokhranitj zavershyonnuyu kartochku 0202, yeyo pereimenovaniye, novyij 0206 i ispravleniye grafa; aktivnuyu kopiyu 0202 iz drugoj linii ne vozvrasjhatj.

Podtverzhdenyi obsjhiye predki matematicheskoj linii s 0207/0208 — `8609003af7fdb6ef5dddf21c51cd6607ddb34088`, 0207 s 0208 — `1aab4c016f726452861f42963b59b6ba66483437`; roditelj 0208 — `3fdcb39ce8822102fe8823ee8bf483be2d6581c3`. Posle sootvetstvuyusjhikh obsjhikh predkov u etikh par net sovmestno izmenyonnyikh razlichayusjhikhsya fajlov instrumentov i pravil. Eto ne obesjhayet otsutstviya tekstovyikh konfliktov.

Ispravleniye svyaznosti neobyazateljnogo grafa uzhe vklyucheno v 0176; yego blob `529d1a00cf35c4fd4a400e24a67dc49baf221c00` sovpadayet s matematicheskoj liniyej. Posle razreshyonnogo pervogo merge dopustima popyitka promezhutochnoj kontroljnoj tochki bez prezhdevremennogo perenosa ostaljnyikh vkhodov. Do prinyatoj peredachi 0201 ona sokhranyayetsya nezakommichennoj: staryij dopusk 10dc ne prinimayet otsutstviye lokaljnogo grafa, a obkhod i fiktivnoye sostoyaniye zapresjhenyi koordinatorom.

## Vyibrannyij dopusk

Podgotoviteljnaya kontroljnaya tochka ispoljzuyet pravila nachaljnogo `10dc3b21`, shtatnyiye otchyotnuyu obyortku, recency i svyaznostj s flagom kontroljnoj tochki. Polnyij dopusk obyyedineniya otdeljnyij: on vklyuchayet adresnyiye proverki sovmestnyikh kontraktov i primenimyiye iskhodnikam proverki; nalichiye Swift i neobyazateljnyikh avtomatizacij yavlyayetsya osnovaniyem yavno vyibratj polnyij repozitornyij profilj dlya itogovogo snimka. Staryiye prinyatyiye vetochnyiye testyi povtorno ne zapuskayutsya radi podgotovki.

Dlya finaljnogo snimka do zapuska indeksirovatj kanonicheskiye soderzhateljnyiye puti, ispoljzovatj shtatnyiye priyomochnyiye raundyi, poslednim okhvachennyim processom vyipolnitj vyibrannyij polnyij smoke; posle uspekha proveritj plan, zakryitj otchyot, odin raz shtatno primenitj proyekciyu i nezavisimo proveritj manifest po razreshyonnoj granice zamyikaniya. Nikakogo samodeljnogo dopuska, novyikh optimizacij ili live hooks etot plan ne vvodit.

Master sejchas ukazyivayet na `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`. V nyom obnaruzhen otslezhivayemyij ispolnitelj prodvizheniya prinyatogo sliyaniya; nalichiye fajla ne obyyavlyayet budusjhij kandidat prinyatyim. Pri posleduyusjhej priyomke zanovo zakrepitj fakticheskij M, polnostjyu prochitatj yego pravila i proveritj vesj kontur iz M. Podgotovka tekusjhego kandidata v fuma ne dvigayet master.

## Metodika nablyudeniya

Pervaya metka postavlena do zapisi chastnogo kataloga nablyudenij i naznacheniya vetki. Nachaljnyiye verkhniye intervalyi opublikovanyi v [izmereniyakh](nachaljnyiye-izmereniya.json); syiryiye vyivodyi i lokaljnyiye puti ostayutsya vne checkout. `time.monotonic_ns` izmeryayet dliteljnostj, `time.time_ns` — kalendarnyiye granicyi. Sistemnyij time izmeryayet resursyi komandyi; stdout i stderr proveryayemoj programmyi ne podmenyayutsya.

Stadii: Git-sovmesjheniye, konfliktyi, indeksyi, generaciya proyekcii, manifest, adresnyiye proverki, polnyij dopusk, commit i push. Dlya pryamyikh proverok obyazateljna susjhestvuyusjhaya otchyotnaya obyortka; sostavnyiye `smoke-timing` i metki proyekcii sluzhat detalizaciyej. Vneshnyuyu obyortku time razmesjhatj snaruzhi, chtobyi ne izmenitj raspoznavaniye polnoj komandyi.

Dlya kazhdogo intervala fiksiruyutsya iskhod, tochnyij vkhod, yedinicyi, versiya instrumenta, fajlyi, konfliktyi, popyitki i proiskhozhdeniye dejstvij. Kolichestvo konfliktov schitayetsya po razlichnyim putyam kazhdogo shaga; povtornaya popyitka sokhranyayetsya otdeljno. Summa vnutrennikh stadij ne pribavlyayetsya k ikh roditelyu; paralleljnyij analiz i ozhidaniye ne skladyivayutsya kak posledovateljnaya rabota.

CPU user/system poluchenyi dlya sistemnoj granicyi zapusjhennoj komandyi; vyidelennyij CPU kazhdogo potomka — unknown. RSS — nablyudyonnyij maksimum etoj granicyi v bajtakh, piki processov ne summiruyutsya. Schyotchiki block I/O ne zamenyayut chislo fakticheski prochitannyikh/zapisannyikh bajtov; posledniye poka unknown. Nulevoj sistemnyij schyotchik ne dokazyivayet otsutstviye fajlovyikh operacij. Stoimostj nablyudeniya otdeljno ne vyidelena i ostayotsya unknown: instrument vklyuchyon v izmerennyij verkhnij interval. Kyeshi fajlovoj sistemyi ne kontrolirovalisj; novogo progreva i iskusstvennogo ochisjheniya net. Podmodulj LinguisticKit v novom dereve yesjhyo ne materializovan.

Ozhidaniye prinyatoj peredachi 0201 nachalosj s polucheniya naznacheniya i perekryivayetsya s podgotovkoj; ono poka ne zaversheno. Chistoye vremya bezdejstviya do nachala nepreryivnogo izmereniya — unknown. Nablyudeniye schitayetsya zavershyonnyim toljko posle polnogo processa s otkazami i peredachej, poetomu tekusjhiye dva intervala ne obyyavlyayutsya polnyim profilem integracii.

## Istochniki

- [Zapros etapa](../zapros.md), [porucheniye koordinatora](porucheniye-koordinatora.txt).
- [Postanovka tochnogo vkhoda](../../2026-09-11_10-20-32_MSK_sokhranitj-postanovku-integracii-i-nablyudeniya/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:20:00 MSK -->
<!-- content-sha256: sha256:bb1667dd254d1c72ccc5e8606773906b24bf8042d0e415f9b316262a7e5fe7ea -->
<!-- FUM-MD-RECENCY:END -->
