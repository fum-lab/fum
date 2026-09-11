# Otchyot 2026-09-11 16:12:17 MSK - Zavershitj priyomku reyestra podderzhki FUM

Realizovan pervyij konechnyij [reyestr podderzhki FUM](../../Planirovaniye/finansirovaniye-i-resursyi/README.md): 16 organizacij iz dvukh issledovanij, 24 varianta, iskhodnoye avtorstvo, datirovannaya istoriya, ogranicheniya i vosproizvodimyij vyipusk po zadannoj date. Konechnyij dopusk etogo etapa podtverzhdayetsya poslednim uspeshnyim standartnyim smoke i zakryityim mashinnyim blokom nizhe; otkryityij blok gotovnostj ne dokazyivayet.

## Izmeneniya etapa

Posle checkpoint `fbf05a051e1e5d24706f7e5c5605dd028559f970`, dostavlennogo v odnoimyonnuyu vetku origin s podtverzhdyonnyim udalyonnyim OID, ispravlen perekhvat tochnogo `ProjectFilesError` v CLI. Nevernyij putj teperj dayot kod 2 i ponyatnuyu diagnostiku bez traceback i izmeneniya fajlov. Isklyucheniya proizvoljnogo RuntimeError ne skryivayutsya.

Sovmestnaya regressiya proveryayet szhatyij PDF s oshibochnyim HTTP-tipom HTML: posle raspakovki signatura PDF vyizyivayet otkaz do zapisi. Samostoyateljnyiye meryi zaregistrirovanyi v soglasovannyikh SBOJ-0083 i SBOJ-0084; SBOJ-0020, 0081 i 0082 poluchili otdeljnoye podtverzhdeniye nablyudavshikhsya granic. Shirokaya priyomka reyestra uchityivayetsya v STEP-0212, a ne podmenyayetsya zakryitiyem diagnostiki. Istoricheskiye proyavleniya i RED sokhranenyi.

Instrukciya dopolnena fakticheskoj sredoj proverki i ssyilkoj na etot etap. Zhivyiye ssyilki STEP-0212 obnovlenyi shtatnoj avtomatizaciyej; dve istoricheskiye JSON-svodki paketov sokhranenyi prezhnimi bajtami, poskoljku svyazanyi s konkretnyimi planami i bazami. Iskhodnyiye issledovaniya i bajtyi neizmenyayemyikh svideteljstv sokhranenyi. V kartochkakh i tekusjhem indekse zamenenyi toljko puti khraneniya 32 tekstov: teperj kazhdyij yavlyayetsya samostoyateljnyim istoricheskim podsnimkom nastoyasjhego URL so svoim manifestom. Karta perenosa soderzhit prezhniye puti, bazovyij kommit i SHA. Istoricheskiye vkhodyi obnovlenij ne perepisanyi; ikh prezhniye puti razreshayutsya v ukazannoj baze. Datyi, avtoryi, usloviya i null nablyudenij ne menyalisj. Vse 32 teksta pobajtovo sverenyi do i posle perenosa.

Pri adresnoj proverke publikacionnoj chistotyi vyiyavlenyi dve raznyiye prichinyi otkaza: sobstvennyij fizicheskij putj v sokhranyonnyikh otvetakh kornya i vneshniye tekstyi vne istochnikovoj oblasti. Otvetyi otredaktirovanyi s yavnyim markerom i SHA iskhodnyikh bajtov; pervichnyij JSONL ostayotsya privatnyim. Istochniki peremesjhenyi s sokhraneniyem proiskhozhdeniya, bez novoj seti i bez izmeneniya soderzhateljnyikh uslovij. Klassifikaciya vneshnego istochnika ne zamenyayet yego otdeljnyij audit sluzhebnyikh znachenij.

V unasledovannom ispolnitelj_priyoma.py izmenena toljko zapisj ASCII-tiljdyi v regulyarnom vyirazhenii na ekvivalentnyij kod simvola. Prichina — lozhnyij home-expansion v scanner na iskhodnom blob 98ccac278715d8a527c23cf7d4d4bc76c461e0a4. Snachala sokhranyon otkaz scanner i proverenyi susjhestvuyusjheye povedeniye i 12 sochetanij dlinyi ogradyi/otstupa; posle pravki podtverzhdenyi otkaz vstavki statusa v ograde i obyichnaya dopustimaya vstavka. Politika isklyuchenij i scanner ne izmenenyi. Kornevoj web-putj formyi CAPTCHA vyirazhen cherez razbor polnogo sinteticheskogo URL bez seti; strokovoye sravneniye ostalosj tem zhe.

## Sootvetstviye porucheniyu

- Vse iskhodnyiye 9 + 7 organizacij sokhranenyi s ustojchivyimi ID; novyiye proverki ne pripisanyi avtoram peredannyikh issledovanij. 26 HTML i 9 PDF sokhranenyi istochnikovyim mekhanizmom, a istoricheskiye nablyudeniya ispoljzuyut otdeljnyiye khyeshirovannyiye svideteljstva.
- Otdeljno pokazanyi fondyi, pozhertvovaniya, oblachnyiye resursyi i nauchno-tekhnologicheskoye sotrudnichestvo; formyi deneg, bonusov, skidok, kompensacii i sotrudnichestva ne smeshanyi. Neobnaruzhennaya programma oborudovaniya ili sponsorstva ne vyidumana.
- Kazhdaya zapisj soderzhit vzaimnuyu poljzu, oficialjnyiye adresa i datyi, trebovaniya, Rossiyu, ogranicheniya, neizvestnoye, sroki i minimaljnyij sleduyusjhij shag. Svezhestj 30/90 dnej vyichislyayetsya po yavnoj date. Zakryityij ili istyokshij priyom ne stanovitsya dostupnyim.
- Import, dobavleniye nablyudeniya, vyipusk i proverka povtoryayemyi; sokhranenyi TDD, otkryityiye fiksturyi, iskhodniki, shablon i profilj. Obnovleniye A → B → A sokhranyayet istoriyu; vyikhodyi ne perezapisyivayut istochniki.
- Upravlyayusjhiye soobsjheniya o baze, vetke, rezervakh i resursnom okne vyipolnenyi v svoyej oblasti; soobsjheniya sokhranenyi doslovno s proiskhozhdeniyem v zaprose. Soglasovaniye okna ne yavlyayetsya dopolniteljnyim razresheniyem na predmetnuyu rabotu.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Semj povtorov reyestra | do 30,071 ms za povtor | Progretyij process: chteniye, proverka svideteljstv, ocenka, render. Setj, start Python i zapisj vyipuska isklyuchenyi. |
| Ochistka okonchateljnogo korpusa | do 341,342 ms za nabor | Semj povtorov 26 HTML i zagolovkov v pamyati; PDF, setj i izvlecheniye vne granicyi. |
| Ispravleniye propusjhennogo statusa | mediana 3339,273 ms | Tri nezavisimyiye Git-fiksturyi. Vlozhennaya proverka granic — mediana 0,379 ms; povtor operacii — 288,295 ms. |
| Adresnyiye proverki i finaljnyij smoke | Mashinnyiye stroki nizhe | Monotonnyiye intervalyi obyortki, v tom chisle ozhidayemyij RED. Polnyij standartnyij smoke otmechen otdeljno. |
| Soderzhateljnaya rabota i soglasovaniye resursov | Otdeljno ne izmerenyi | Nachalo etapa 16:12:17 MSK; zaversheniye mashinnoj granicyi fiksiruyet snimok. FIFO i handoff ne primenyalisj. |
| Itogovaya proyekciya i proverki zamyikaniya | Vne zakryitoj granicyi | Posle zakryitiya predusmotrenyi odin shtatnyij vyipusk, odna nezavisimaya proverka i read-only dopusk kommita. |

Granica profilya: izmerennyiye programmnyiye intervalyi ne podmenyayut polnoye kalendarnoye vremya zadachi; vlozhennyiye stadii ne summiruyutsya s roditeljskim povtorom. Po rezuljtatu dopolniteljnaya optimizaciya reyestra ne trebuyetsya: do 31 ms dlya 16 organizacij, sokhraneniye vosproizvodimosti vazhneye kyesha. Istoricheskiye izmereniya otnosyatsya k svoim tochnyim khyesham; aktualjnyij profilj uchityivayet ispravlennyij CLI i novyiye puti svideteljstv. Uzkaya proverka tiljdovyikh ograd zanimayet meneye millisekundyi; optimizaciya yeyo ne trebuyetsya. Polnyij profilj korrekcii preimusjhestvenno izmeryayet realjnyij Git i ustanovku fajlov, a ne regulyarnoye vyirazheniye. Sreda: macOS arm64, Python 3.14.7. Profilj pamyati ispoljzuyet POSIX `resource`.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:d09125e6010195b6e0f35ff79a8242414d970c73c08366db66851e1721062f69 -->

| Vyizov                                                              | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------ | ------------ | --------- |
| [Korenj] RED: tochnyij otkaz CLI na nevernom puti                    | 1,547 s      | neuspeshno |
| [Korenj] GREEN: otkaz CLI i vse granicyi reyestra                    | 1,441 s      | uspeshno   |
| [Korenj] Sovmestnaya granica gzip i PDF; regressii arkhivatora       | 0,584 s      | uspeshno   |
| [Korenj] Itogovyij profilj reyestra posle ispravleniya CLI            | 0,258 s      | uspeshno   |
| [Korenj] Publikacionnaya proverka podgotovlennogo vkhoda             | 24,801 s     | neuspeshno |
| [Korenj] Soglasovannostj itogovyikh kartochek planirovaniya            | 0,468 s      | uspeshno   |
| [Korenj] Povtor sokhranyonnogo vyipuska cherez konechnyij CLI            | 0,137 s      | uspeshno   |
| [Korenj] Lokalizaciya otkaza skanera pered polnyim dopuskom          | 24,705 s     | neuspeshno |
| [Korenj] URL-semantika formyi i regressii arkhivatora                | 0,575 s      | uspeshno   |
| [Korenj] Iskhodnaya granica tiljdovoj ogradyi i obyichnogo vkhoda        | 105,577 s    | uspeshno   |
| [Korenj] Sokhraneniye istoricheskogo URL i vse regressii arkhivatora   | 0,54 s       | uspeshno   |
| [Korenj] GREEN: tiljdovyiye ogradyi i obyichnoye dobavleniye statusa      | 0,249 s      | uspeshno   |
| [Korenj] Profilj propusjhennogo statusa posle tiljdovoj pravki       | 17,081 s     | uspeshno   |
| [Korenj] Profilj reyestra posle perenosa svideteljstv               | 0,243 s      | uspeshno   |
| [Korenj] Profilj ochistki okonchateljnogo korpusa istochnikov         | 2,482 s      | uspeshno   |
| [Korenj] Publikacionnaya chistota posle perenosa i uzkikh ispravlenij | 24,698 s     | uspeshno   |
| [Korenj] Povtor vyipuska s tochnyimi SHA peremesjhyonnyikh svideteljstv    | 0,117 s      | uspeshno   |
| [Korenj] Svyaznostj okonchateljnogo otkryitogo etapa                  | 44,429 s     | neuspeshno |
| [Korenj] Svyaznostj s polnyim perechnem fakticheski zatronutyikh fajlov  | 42,975 s     | uspeshno   |
| [Korenj] Itogovyij standartnyij smoke reyestra podderzhki FUM          | 1108,017 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 1400,924 s.

Ekonomnyij poryadok proverok: gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

16 testov reyestra i 56 arkhivatora proshli adresno. Dopolniteljno projdenyi 16 testov ispravleniya priyoma na iskhodnoj forme i dva adresnyikh scenariya posle ekvivalentnoj tiljdovoj pravki. Sokhranenyi otdeljnyij RED tryokh nevernyikh form puti, GREEN i sovmestnyij scenarij gzip/PDF. Itogovyij profilj soderzhit khyeshi koda, vkhodov, vyikhoda, versii, semj povtorov i pamyatj. RO-sverka audit_reuse podtverdila sootvetstviye README fakticheskomu CLI; audit_tech raneye podtverdil ochistku diagnosticheskogo ID FPG v obeikh kopiyakh. Dopolniteljnaya nezavisimaya RO-sverka audit_tech sravnila vse 32 peremesjhyonnyikh teksta s fbf05a05 i ne obnaruzhila chuvstviteljnyikh sluzhebnyikh znachenij; chisla punktov dogovora i publichnoye nazvaniye SmartCaptcha ne schitalisj sekretami. Adresnyij scanner zavershilsya kodom 0. Predvariteljnaya svyaznostj potrebovala dopolnitj razdel zatronutyikh fajlov fakticheskimi arkhivami i tekusjhimi vyipuskami; predmetnaya oblastj ne rasshiryalasj. Zaklyuchiteljnaya RO-sverka audit_funders ne nashla soderzhateljnyikh propuskov: 16 organizacij, 24 varianta, proiskhozhdeniye 9 + 7, vse 24 znacheniya dostupnosti programmyi otricateljnyi, polozhiteljnyiye iskhodyi otnosyatsya toljko k podgotovke ITMO, ALT i SSWG. Predmetnyiye neizvestnyiye sokhranenyi kak rezuljtat issledovaniya. Docherniye ispolniteli ne pisali fajlyi i ne zapuskali tyazhyolyikh proverok.

Standartnyij smoke vyipolnyayetsya toljko posle gotovnosti kanonicheskogo vkhoda v soglasovannom okne. Yego mashinnyij rezuljtat, zatem zakryitiye otchyota i ogranichennyiye proverki zamyikaniya yavlyayutsya usloviyami okonchateljnogo kommita. Eta fraza opisyivayet dopusk, a ne zaraneye pripisannyij uspekh.

## Resheniya i ogranicheniya

- Rossiya i nekommercheskaya oriyentaciya zadanyi; yuridicheskaya forma i registraciya NKO neizvestnyi. Ni odin variant ne obyyavlen dostupnoj denezhnoj programmoj FUM. Lokaljnaya podgotovka tekhnicheskogo sotrudnichestva ne oznachayet polucheniya resursov.
- U FPG i FSI pryamoye chteniye nepolno; sokhranyayutsya ogranicheniya Yandeksa, VK, Selectel i licenzij SSWG. Skolkovo ne kompensiruyet razrabotku PO kak sozdaniye prototipa. Kazhdoye usloviye vidno v otdeljnom variante.
- Semanticheskoye chteniye uslovij i migraciya iskhodnogo korpusa ne avtomatizirovanyi. Staroye svideteljstvo bez sokhranyonnyikh bajtov ostayotsya null. Povtor s toj zhe datoj ne podtverzhdayet novogo chteniya sajta.
- Vneshniye pisjma, obrasjheniya, registracii, zayavki, platezhi i izmeneniye licenzii ne vyipolnyalisj. Tochnyij push sobstvennoj vetki i razreshyonnaya koordinaciya zadach otdelenyi ot takikh dejstvij.
- Standartnyij dokumentacionnyij profilj ne yavlyayetsya shirokim repozitornyim profilem. Integraciya v master nakhoditsya vne porucheniya etoj zadachi; konechnyiye OID i dokazateljstva peredayutsya koordinatoru i vladeljcu priyoma.

## Istochniki

- [Iskhodnoye porucheniye i utochneniya](zapros.md).
- [Pervonachaljnaya realizaciya i yeyo RED/GREEN](../2026-09-11_14-52-06_MSK_sozdatj-reyestr-organizacij-podderzhki-FUM/otchyot.md).
- [Aktualjnyij profilj reyestra](materialyi/profili/reyestr-podderzhki-perenos.json).
- [Profilj ochistki](materialyi/profili/ochistka-istochnikov.json).
- [Profilj ispravleniya statusa](materialyi/profili/tiljdovaya-ograda.json).
- [Karta perenosa svideteljstv](materialyi/perenos-svideteljstv.json).
- [Primenyonnyij paket diagnostiki](materialyi/paket-diagnostiki.json).
- [Soderzhateljnyiye otvetyi kornya](materialyi/otvetyi-ispolnitelya.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:53:07 MSK -->
<!-- content-sha256: sha256:fa73b39b87c793eb59c64dac36c09c23eb409e107d7538f85c9dde3a804365b9 -->
<!-- FUM-MD-RECENCY:END -->
