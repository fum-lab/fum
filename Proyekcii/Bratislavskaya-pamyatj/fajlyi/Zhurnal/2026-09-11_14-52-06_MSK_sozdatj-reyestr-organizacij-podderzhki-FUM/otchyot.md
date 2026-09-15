# Otchyot 2026-09-11 14:52:06 MSK - Sozdatj reyestr organizacij podderzhki FUM

Podgotovlen pervyij [reyestr podderzhki](../../Planirovaniye/finansirovaniye-i-resursyi/README.md): 16 iskhodnyikh organizacij, 24 varianta, istoriya nablyudenij, samostoyateljnyiye statusyi programm i lokaljnoj podgotovki, yavnoye ustarevaniye i neizvestnyij yuridicheskij profilj. Eto kontroljnaya tochka s otkryityim otchyotom: finaljnaya priyomka yesjhyo ne vyipolnena.

## Realizaciya i predmetnaya proverka

Dobavlenyi import, bezopasnoye dobavleniye nablyudeniya, formirovaniye i proverka JSON/Markdown po yavnoj date. Pereispoljzovanyi odnoshagovyij shablonnyij mekhanizm, proverka putej, atomarnaya zapisj i susjhestvuyusjhij profilj. Zasjhisjhenyi polnoye pokryitiye pervonachaljnyikh 16 kandidatov, iskhodnoye avtorstvo, obyazateljnyiye usloviya, istyokshiye sroki, dubli, budusjhiye datyi, obnovleniye A → B → A i neperesecheniye vyikhodov s dokazateljstvami.

Sokhraneno 26 HTML i 9 PDF oficialjnyikh istochnikov. Dva peredannyikh issledovaniya ostayutsya neizmennyimi; novoye chteniye issledovatelej i sverka novyikh lokaljnyikh PDF otmechenyi otdeljno. Dlya nablyudenij sozdanyi neizmenyayemyiye tekstovyiye svideteljstva s khyeshami. Pervaya chernovaya privyazka nechitabeljnogo predstavleniya Swift.org snyata do publikacii; praviljnyij gzip raspakovan, a PDF Astra po adresu bez rasshireniya sokhranyon kak PDF. Staryiye predmetnyiye nablyudeniya sokhranenyi bez pripisyivaniya im novyikh bajtov.

Soderzhateljnyiye utochneniya: Skolkovo isklyuchayet razrabotku PO iz kompensacii sozdaniya prototipa, poetomu poyavilsya otdeljnyij nedostupnyij variant; ispyitaniya ostayutsya otdeljnoj neproverennoj vozmozhnostjyu. U Potanina utochnenyi oblastj zapreta avtomatizacii fondov materialov i data utverzhdeniya 08.04.2026. U RNF sokhranenyi sroki i trebovaniya k vozrastnomu sostavu komandyi. FPG i FSI otmechenyi kak nepolnoye pryamoye chteniye; fizicheskiye lica v FSI ne zamenenyi obyazateljnoj registraciyej kompanii. Selectel razlichayet novyiye kliyentskiye otnosheniya, testovyiye bonusyi, platyozhnyij keshbyek i istyokshij OpenFix. ALT Join vosstanovlen, polnaya Team/Join poka ne prochitana. Dlya Yandeksa, VK i SSWG sokhranenyi ogranicheniya verifikacii, raskhodov i licenzij. Ni odin variant ne obyyavlen dostupnoj denezhnoj programmoj FUM.

## Ispravleniya istochnikovogo mekhanizma

Rasshirena obsjhaya ochistka podtverzhdyonnyikh sluzhebnyikh HTTP-polej; RED/GREEN ne soderzhit realjnyikh znachenij. CSRF, nonce i diagnosticheskiye polya redaktiruyutsya do izvlecheniya. CAPTCHA raspoznayotsya po konkretnomu kontejneru, soderzhateljnyiye datyi vne nego sokhranyayutsya; netronutyiye bajtyi drugoj kodirovki prokhodyat obratimo. gzip raspakovyivayetsya do opredeleniya formata, HTML-vkhod otkazyivayet na PDF. Vlozhennyiye samostoyateljnyiye snimki sokhranyayutsya pri obnovlenii roditelya; povrezhdyonnyij dochernij manifest dayot otkaz bez poteri.

[SBOJ-0020](../../Sboi/FUM-SBOJ-0020-publikaciya-sluzhebnogo-CF-Ray-v-snimke-istochnika.md) poluchil soglasovannoye proyavleniye 0003 s sokhraneniyem istorii; [SBOJ-0081](../../Sboi/FUM-SBOJ-0081-sokhraneniye-sluzhebnyikh-dannyikh-zaprosa-v-HTML.md) i [SBOJ-0082](../../Sboi/FUM-SBOJ-0082-utrata-vlozhennogo-URL-pri-povtore-roditelya.md) vyidelenyi obsjhim raspredelitelem. Svyazannyij STEP-0212 aktualizirovan. Statusyi poka aktivnyi do zaversheniya dopuska. Otdeljno zarezervirovanyi SBOJ-0083 dlya gzip i SBOJ-0084 dlya PDF; ikh kartochki budut vyipusjhenyi v sleduyusjhem etape. Eti mekhanizmyi ne smeshivayutsya s ochistkoj sluzhebnyikh znachenij.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Reyestr s korrektnyimi svideteljstvami | do 20,005 ms za povtor | Semj povtorov v progretom processe; chteniye, proverka khyeshej, ocenka i render. Setj, start Python i zapisj rezuljtata isklyuchenyi. |
| Ochistka sokhranyonnyikh HTML | do 340,735 ms za nabor | Semj povtorov 26 uzhe zagruzhennyikh HTML i zagolovkov; PDF, setj i izvlecheniye teksta vne granicyi. |
| Pryamyiye proverki | Mashinnaya summa nizhe | Kazhdyij RED, GREEN, profilj i povtor zapisan otdeljno obyortkoj. |
| Soderzhateljnaya rabota i ozhidaniye resursnogo okna | Ne izmereno otdeljno | Nachalo etapa 14:52:06 MSK; rabota prodolzhayetsya. FIFO i avtomaticheskaya peredacha ne primenyalisj. |
| Finaljnyij standartnyij smoke | Yesjhyo ne vyipolnyalsya | Ozhidayetsya okno posle soglasovannoj rabotyi Linux VM. |

Granica profilya: izmerenyi otdeljnyiye programmnyiye intervalyi i vse pryamyiye proverochnyiye vyizovyi. Oni ne podmenyayut polnoye kalendarnoye vremya zadachi. Istoricheskiye profili 6,99 i 17,68 ms otnosyatsya k boleye rannim vkhodam; aktualjnyij profilj soderzhit tochnyiye khyeshi. Optimizaciya reyestra ne trebuyetsya dlya 16 kandidatov: maksimum okolo 20 ms v dannoj granice, vosproizvodimostj i proverki vazhneye dopolniteljnogo kyesha. Dlya ochistki primenyayetsya ogranicheniye razbora CAPTCHA po yeyo yavnoj signature; daljnejshaya optimizaciya po tekusjhemu profilyu ne obosnovana.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                        | Dliteljnostj | Rezuljtat |
| ---------------------------------------------------------------------------- | ------------ | --------- |
| [Korenj] RED: granicyi reyestra podderzhki                                      | 0,057 s      | neuspeshno |
| [Korenj] GREEN: proiskhozhdeniye, vremya i dopusk podderzhki                      | 0,113 s      | uspeshno   |
| [Korenj] RED: interfejs vyipuska i bezopasnogo obnovleniya                     | 0,133 s      | neuspeshno |
| [Korenj] GREEN: interfejs vyipuska i bezopasnogo obnovleniya                   | 0,751 s      | uspeshno   |
| [Korenj] RED: isklyuchitj obkhod neizvestnogo statusa zayavitelya                 | 0,223 s      | neuspeshno |
| [Korenj] GREEN: yuridicheskij profilj i polnota chteniya uslovij                 | 0,738 s      | uspeshno   |
| [Korenj] Profilj reyestra: semj vosproizvodimyikh povtorov                      | 0,15 s       | uspeshno   |
| [Korenj] RED: publikacionnaya ochistka otvetov istochnikov                      | 0,108 s      | neuspeshno |
| [Korenj] GREEN: ochistka tokenov i diagnosticheskogo adresa do izvlecheniya      | 0,111 s      | uspeshno   |
| [Korenj] RED: ostavshiyesya diagnosticheskiye polya otveta                         | 0,115 s      | neuspeshno |
| [Korenj] RED: interval bez datyi okonchaniya                                    | 0,678 s      | neuspeshno |
| [Korenj] GREEN: ogranichennaya ochistka izvestnyikh polej otveta                  | 0,115 s      | uspeshno   |
| [Korenj] GREEN: interval trebuyet proverennoj granicyi                         | 0,696 s      | uspeshno   |
| [Korenj] RED: vozvrat sostoyaniya i zasjhita iskhodnikov vyipuska                  | 1,009 s      | neuspeshno |
| [Korenj] RED: peresecheniye razreshyonnyikh kanonicheskikh putej                     | 0,972 s      | neuspeshno |
| [Korenj] GREEN: istoriya sostoyanij i neperesecheniye vyipuska                    | 1,001 s      | uspeshno   |
| [Korenj] Regressii susjhestvuyusjhego arkhivatora istochnikov                       | 1,121 s      | uspeshno   |
| [Korenj] RED: sluzhebnyiye polya diagnosticheskoj stranicyi Yandeksa                | 0,118 s      | neuspeshno |
| [Korenj] GREEN: diagnostika Yandeksa i regressii arkhivatora                   | 0,553 s      | uspeshno   |
| [Korenj] Priyomka sokhranyonnogo korpusa i neizmenyayemyikh svideteljstv            | 1,084 s      | uspeshno   |
| [Korenj] Povtor vyipuska po sokhranyonnyim dannyim bez seti                       | 0,125 s      | uspeshno   |
| [Korenj] Priyomka utochnyonnyikh uslovij sokhranyonnyikh PDF                          | 0,975 s      | uspeshno   |
| [Korenj] Profilj utochnyonnogo reyestra so svideteljstvami                      | 0,206 s      | uspeshno   |
| [Korenj] Profilj i ustojchivostj ochistki sokhranyonnyikh otvetov                  | 0,102 s      | neuspeshno |
| [Korenj] RED: sokhraneniye vlozhennogo URL pri povtore roditeljskogo snimka     | 0,128 s      | neuspeshno |
| [Korenj] GREEN: vlozhennyiye URL i regressii istochnikovogo arkhiva               | 0,563 s      | uspeshno   |
| [Korenj] Povtor profilya ochisjhennogo nabora posle vosstanovleniya dochernego URL | 0,106 s      | neuspeshno |
| [Korenj] RED: realjnyij format otveta i nepolnyij dochernij snimok              | 0,13 s       | neuspeshno |
| [Korenj] GREEN: otkaz na PDF i povrezhdyonnyij vlozhennyij snimok                 | 0,594 s      | neuspeshno |
| [Korenj] RED: pobajtnaya sokhrannostj i soderzhateljnaya data                    | 0,132 s      | neuspeshno |
| [Korenj] GREEN: pobajtnaya redakciya i lokaljnaya diagnostika CAPTCHA           | 0,576 s      | uspeshno   |
| [Korenj] Profilj ustojchivoj ochistki 26 HTML; PDF vne tekstovoj granicyi       | 0,118 s      | neuspeshno |
| [Korenj] RED: szhatoye predstavleniye oficialjnogo HTML                         | 0,149 s      | neuspeshno |
| [Korenj] GREEN: gzip, formatyi, ochistka i vlozhennyiye snimki                    | 0,587 s      | uspeshno   |
| [Korenj] Profilj ochistki raspakovannyikh 26 HTML                               | 2,444 s      | uspeshno   |
| [Korenj] Priyomka reyestra posle ispravleniya formatov istochnikov               | 1,118 s      | uspeshno   |
| [Korenj] Profilj vyipuska s korrektnyimi svideteljstvami vsekh formatov         | 0,229 s      | uspeshno   |
| [Korenj] Proverka iskhodnoj materializovannoj Git-zavisimosti                 | 0,574 s      | neuspeshno |
| [Korenj] Podtverzhdeniye svyazannoj topologii iskhodnoj Git-zavisimosti          | 0,565 s      | uspeshno   |
| [Korenj] RED: diagnosticheskij ID stranicyi blokirovki FPG                     | 0,142 s      | neuspeshno |
| [Korenj] GREEN: diagnostika blokirovki i regressii istochnikov                | 0,565 s      | uspeshno   |
| [Korenj] Profilj ochistki posle redakcii diagnostiki FPG                      | 2,443 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 22,417 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Pri okonchateljnom prosmotre do publikacii najdena otdeljnaya forma ID na stranice blokirovki MYRTEX u FPG. Dobavlenyi sinteticheskij RED i GREEN, ogranichennaya redakciya pri tochnoj signature blokirovki i proverka sokhraneniya publichnogo primera. Snimok pereizvlechyon bez seti; reyestr ne ssyilalsya na nego kak na dokazateljstvo uslovij. Profilj povtoryon dlya novyikh bajtov.
- `git diff --cached --check` vyiyavil 14 601 preduprezhdeniye toljko v syiryikh fajlakh `Источники/`; sobstvennyiye kod i dokumentaciya preduprezhdenij ne imeyut. Probeljnyiye bajtyi istochnikov ne normalizovanyi radi lintera.

- Pervyij dopusk kontroljnoj tochki vyiyavil nematerializovannuyu iskhodnuyu Git-zavisimostj LinguisticKit: istoricheskaya ssyilka na LICENSE nedostupna. Materializovan zaregistrirovannyij fork i tochnyij gitlink 837e2ce107b97ee7b9d3344c9fe99142281fe393 v sobstvennom dereve, bez izmeneniya gitlink i chuzhoj Git-konfiguracii. Proverka snachala otklonila samostoyateljnyij .git-katalog; shtatnyij absorbgitdirs svyazal yego s privatnoj administrativnoj oblastjyu tekusjhego worktree, posle chego profiljnaya proverka zavisimosti proshla.
- Reyestr: 15 testov posle vsekh predmetnyikh utochnenij. Proverenyi 16 iskhodnyikh organizacij, dve linii avtorstva, 24 varianta, khyeshi svideteljstv, otsutstviye lozhnogo polozhiteljnogo dopuska, istecheniye, obnovleniya i zasjhita iskhodnyikh fajlov.
- Arkhivator: 54 testa susjhestvuyusjhego i novogo naborov; sokhranenyi konkretnyiye RED utechki, vlozhennogo URL, ne-UTF-8, soderzhateljnoj datyi, PDF i gzip. Otkazyi profilya na utrachennom puti i nevernom predstavlenii priveli k ispravleniyu prichin; eto ne uspeshnyiye izmereniya.
- Po novyim lokaljnyim PDF audit_funders sveril RNF, Potanina i Skolkovo, audit_tech — Selectel. audit_reuse nezavisimo proveril granicyi obnovleniya i sokhrannosti istochnikov. Vse docherniye ispolniteli rabotali toljko na chteniye, yedinstvennyij pisatelj — korenj.

## Resheniya i ogranicheniya

- Yuridicheskaya forma i registraciya FUM neizvestnyi. Nikakikh zayavok, pisem, registracij, platezhej i izmenenij licenzii ne vyipolneno. Reyestr ne oznachayet polucheniya sredstv.
- Obnovleniye korpusa kandidatov i yuridicheskogo profilya trebuyet yavnoj migracii; tekusjhaya avtomatizaciya obsluzhivayet sokhranyonnyij pervyij korpus. Smyislovoye chteniye istochnikov ne avtomatizirovano. Otsutstvuyusjhij snimok prezhnego chteniya ostayotsya null.
- Nachaljnaya baza i tekusjhaya baza etapa: 73c52866e565061b48ee67e164d5d178c5c8d8cd; polnyij ref refs/heads/codex/reyestr-organizacij-podderzhki-01a0904a. Fizicheskij korenj sobstvennogo worktree zafiksirovan v pervichnom istochnike porucheniya; drugoj pisatelj isklyuchyon.
- Prezhnyaya bratislavskaya proyekciya ostavlena bez peresborki. Manifest bazyi: SHA-256 63f4fc631d0220d5e620d595958b2e44f7fe5e7142a414fb1f96c82df275bda0; khyesh yeyo plana sha256:5371a473cb08bd886d52142a75311cec03eda05658a9de27da21143d2adfa819. Ona otstayot ot novyikh kanonicheskikh fajlov i ne dokazyivayet gotovnostj rezuljtata.
- Ostatok posle kontroljnoj tochki: vyipustitj kartochki SBOJ-0083 i SBOJ-0084, proveritj szhatyij PDF i obrabotku ProjectFilesError v CLI, soglasovannyij finaljnyij standartnyij smoke, aktualjnuyu proyekciyu, zakryityij otchyot, itogovyij commit/push i peredachu OID koordinatoru i zadache priyoma. Kontroljnaya tochka ne zavershayet porucheniye i ne oznachayet integracii v master.

## Istochniki

- [Iskhodnoye porucheniye i vse prinyatyiye utochneniya](zapros.md).
- [Otvetyi kornevogo ispolnitelya](materialyi/otvetyi-ispolnitelya.json).
- [Profilj reyestra](materialyi/profili/reyestr-podderzhki-svideteljstva.json).
- [Profilj ochistki](materialyi/profili/ochistka-FPG.json).
- [Proiskhozhdeniye povtornoj ochistki](materialyi/ochistka-snimkov.json), [paket vosjmi PDF](materialyi/izvlecheniye-PDF.json); devyatyij PDF Astra imeyet sobstvennyij otchyot istochnika.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:09:13 MSK -->
<!-- content-sha256: sha256:a436c5b9ec5ac39f5b58fa8ac591c5213917ff126ab9b1e01d879980c62bfa12 -->
<!-- FUM-MD-RECENCY:END -->
