# Nauchnyiye istochniki, Mendeley i arXiv

Nauchnaya statjya sokhranyayetsya v pamyati FUM tak, chtobyi mozhno byilo vernutjsya k ispoljzovannoj versii, proveritj proiskhozhdeniye vyivoda i prochitatj poluchennyiye materialyi bez podklyucheniya k servisu. Bibliograficheskaya zapisj, fajl statji, avtorskiye annotacii, zametki chitatelya i vyivod FUM ostayutsya razlichimyimi obyyektami.

Etot dokument rasshiryayet protokol khraneniya. Tekusjhij `fum source archive` prinimayet HTML; avtomaticheskij import biblioteki Mendeley, zagruzka PDF i sinkhronizaciya uchyotnoj zapisi yesjhyo ne realizovanyi. Protokol ne obyyavlyayet eti operacii dostupnyimi komandami. Dlya razrabotki importera ispoljzuyutsya perechislennyiye nizhe vkhodyi i kriterii priyomki.

## Chto sokhranyayetsya

Dlya kazhdogo ispoljzovannogo nauchnogo istochnika sokhranyayutsya iskhodnyij adres ili predostavlennyij fajl, nazvaniye, avtoryi, data, dostupnyiye ustojchivyiye identifikatoryi i tochnaya versiya. Neizvestnyiye polya otmechayutsya yavno. Preprint i opublikovannaya statjya svyazyivayutsya pri nalichii osnovaniya; skhodstvo nazvaniya samo po sebe ne dokazyivayet ikh tozhdestvo.

Kazhdoye poluchennoye predstavleniye imeyet sobstvennyiye iskhodnyiye bajtyi, SHA-256, razmer, fakticheskij tip, vremya polucheniya, adres i sposob izvlecheniya. Proiskhozhdeniye otnositsya k konkretnomu snimku. Chislo ili poryadok zapisi v eksporte ne prevrasjhayetsya v identifikator servisa. Ispravlennaya bibliografiya sokhranyayet svyazj s iskhodnoj; iskhodnyij eksport ne normalizuyetsya poverkh originala.

Otdeljno fiksiruyutsya rezuljtatyi: bibliografiya sokhranena; versiya ustanovlena; polnyij tekst poluchen; annotacii poluchenyi; tekst izvlechyon. Dlya kazhdogo rezuljtata dopustimyi nepolnota, nedostupnostj i neizvestnoye sostoyaniye s prichinoj. Nalichiye metadannyikh ne oznachayet nalichiya PDF, a nalichiye PDF — korrektnogo izvlecheniya formul i tablic.

Kanonicheskaya papka ustojchivogo URL opredelyayetsya [obsjhim protokolom](SKILL.md). Dopolniteljnyiye predstavleniya svyazyivayutsya s nej po identichnosti statji i versii. Vnutrj ustanovlennogo HTML-snimka neljzya proizvoljno dopisyivatj PDF, bibliografiyu ili zametki: tekusjhij arkhivator pri zamene upravlyayet sobstvennyim perechnem fajlov. Do rasshireniya etogo kontrakta dopolniteljnyiye materialyi khranyatsya otdeljno, s yavnyimi ssyilkami i vladeljcem.

Binarnyiye originalyi khranyatsya v fajlovom khranilisjhe soglasno prinyatoj granice binarnyikh dannyikh; v Git ostayutsya publikacionno dopustimyiye metadannyiye, khyeshi, ssyilki i rezuljtatyi izvlecheniya. Torrent-dostavka uchityivayetsya otdeljno ot nalichiya lokaljnoj kopii. Ni polucheniye fajla, ni yego khyesh ne dokazyivayut pravo publichnoj razdachi. Licenziya FUM ne pereopredelyayet prava na vneshnij istochnik.

## Mendeley

Pervyij vosproizvodimyij vkhod — sokhranyonnyij eksport bibliografii v BibTeX, RIS ili EndNote XML, a takzhe otdeljno predostavlennyiye fajlyi i annotacii. Sokhranyayutsya format, nablyudayemaya versiya prilozheniya, vremya eksporta, dostupnaya oblastj biblioteki i iskhodnyij fajl. Sluzhebnyiye lokaljnyiye puti i privatnyiye dannyiye ne publikuyutsya; redakcii opisyivayutsya otdeljno.

Identifikatoryi dokumenta Mendeley i zapisi kataloga, DOI, arXiv ID, identifikator fajla i khyesh snimka khranyatsya razdeljno, yesli oni dejstviteljno prisutstvuyut vo vkhode. Sobstvennyij SHA-256 ne zamenyayetsya vneshnim `filehash`: opublikovannyij API Mendeley opredelyayet yego dlya fajlov kak SHA-1. Otsutstvuyusjhij identifikator ne vosstanavlivayetsya po dogadke.

Bibliograficheskij eksport soderzhit metadannyiye i ssyilki na PDF, no ne sami PDF. Originaljnyij PDF i eksportirovannyij PDF s annotaciyami — raznyiye artefaktyi. Polnota perenosa kollekcij, vyidelenij, zametok, koordinat i identifikatorov proveryayetsya po konkretnomu eksportu; podderzhka obmennogo formata sama po sebe yeyo ne dokazyivayet.

Povtor odnogo i togo zhe eksporta ne sozdayot novyiye ekzemplyaryi tekh zhe bajtov. Sovpadeniye DOI ili arXiv ID predlagayet svyazj zapisej, sokhranyaya konfliktuyusjhiye versii, fajlyi i zametki. Udaleniye v Mendeley ne udalyayet sokhranyonnoye svideteljstvo FUM. Dvustoronnyaya sinkhronizaciya i zapisj v biblioteku trebuyut otdeljnogo realizovannogo kontrakta; v etot srez oni ne vkhodyat.

Opublikovannaya dokumentaciya API opisyivayet dokumentyi, fajlyi i annotacii. Realjnaya dostupnostj API i dostup k uchyotnoj zapisi zdesj ne proveryalisj. Oflajn-priyom uzhe sokhranyonnyikh eksportov i chteniye lokaljnyikh fajlov ne dolzhnyi zavisetj ot Mendeley ili yego tokena.

### Predstavleniye biblioteki FUM v Mendeley

Predlagayemyij adapter formiruyet iz vyibrannyikh zapisej `Источники` bibliograficheskij eksport i papku dostupnyikh PDF vne Git. Mendeley importiruyet ikh v sobstvennuyu biblioteku. Podklyucheniye kanonicheskogo Markdown/JSON-kataloga kak vnutrennej bazyi Mendeley opublikovannoj dokumentaciyej ne podtverzhdeno; pryamoye izmeneniye yego sluzhebnoj bazyi ne vkhodit v proyekt.

Dokumentaciya Mendeley Reference Manager opisyivayet odnu nablyudayemuyu papku PDF na ustrojstvo i import novyikh PDF pri nalichii internet-soyedineniya; perenos papki narushayet privyazku, povtornoye vosstanovleniye nablyudeniya mozhet povtorno importirovatj dokumentyi. Import bibliografii v RIS, BibTeX ili EndNote XML vyipolnyayetsya otdeljno. Nablyudeniye papki samo po sebe ne dokazyivayet sinkhronizaciyu kollekcij, izmenenij metadannyikh, zametok ili udaleniya.

Avtomatizaciya sokhranyayet sootvetstviye identifikatorov FUM i Mendeley, versiyu istochnika i khyesh fajla, zhurnaliruyet fakticheskiye operacii i proveryayet povtornyij zapusk bez dublikatov. Metadannyiye, ugadannyiye Mendeley po PDF, sveryayutsya s sokhranyonnoj bibliografiyej. Pervyij srez gotovit lokaljnyij eksport s otchyotom o dostupnyikh i propusjhennyikh fajlakh; nastrojka uchyotnoj zapisi i fakticheskaya peredacha fajlov proveryayutsya otdeljno. Chteniye pamyati FUM ostayotsya dostupnyim bez Mendeley i seti.

Sleduyusjhij srez ispoljzuyet opublikovannyiye API dokumentov, fajlov, kollekcij i annotacij posle proverki realjnogo dostupa. Dvustoronnij obmen trebuyet sravneniya obeikh storon s poslednim prinyatyim sostoyaniyem, sokhraneniya konfliktov i vozobnovleniya posle chastichnoj oshibki. Udaleniye zapisi servisa ne unichtozhayet iskhodnoye svideteljstvo FUM. Eta skhema poka yavlyayetsya proyektom adaptera, a ne realizovannoj sinkhronizaciyej.

## arXiv i drugiye nauchnyiye repozitorii

Ispoljzuyemyiye nauchnyiye statji i preprintyi arXiv sokhranyayutsya kak istochniki pamyati FUM. Dlya arXiv fiksiruyutsya bazovyij identifikator i tochnyij suffiks versii `vN`, vklyuchaya istoricheskij format s kategoriyej. Yesli iskhodnyij URL ne zadayot versiyu, sokhranyayutsya etot vvod i nablyudyonnaya konkretnaya versiya: adres bez `vN` oboznachayet poslednyuyu redakciyu.

Stranica annotacii, PDF, dostupnyij HTML i arkhiv iskhodnikov svyazyivayutsya kak predstavleniya odnoj ustanovlennoj versii. Ikh dostupnostj ne predpolagayetsya zaraneye. Iskhodniki sokhranyayutsya v poluchennom vide; zagruzka arkhiva ne oznachayet uspeshnoj sborki statji. Proizvodnoye izvlecheniye iz PDF khranitsya otdeljno, s privyazkoj k stranicam, sposobom izvlecheniya, primeneniyem OCR i vyiyavlennyimi poteryami.

Usloviya povtornogo ispoljzovaniya proveryayutsya dlya konkretnoj versii. Metadannyiye arXiv dostupnyi pod CC0; polnyij tekst imeyet otdeljnuyu licenziyu, kotoraya mozhet razlichatjsya mezhdu versiyami. Poiskovyij API ne yavlyayetsya dostatochnyim istochnikom licenzii polnogo teksta: ona proveryayetsya na stranice statji libo v sootvetstvuyusjhikh dannyikh OAI-PMH. Yesli publichnoye rasprostraneniye ne razresheno ili ne ustanovleno, razreshyonnaya lokaljnaya kopiya i publichnaya zapisj o nej sokhranyayut raznyiye granicyi dostupa.

Zapisj Mendeley s arXiv ID svyazyivayetsya s uzhe sokhranyonnoj versiyej, yesli versiya podtverzhdena. Nepolnyij identifikator ne pozvolyayet molcha vyibratj redakciyu. Dlya drugikh repozitoriyev primenyayutsya te zhe principyi identichnosti, versij, proiskhozhdeniya i fakticheskoj polnotyi.

## Sleduyusjhij srez avtomatizacii

Importer poluchayet yavno vyibrannyij eksport ili adres statji i vozvrasjhayet proverennyij nabor iskhodnyikh artefaktov, bibliograficheskuyu zapisj, svyazi versij i otchyot o polnote. Snachala proveryayutsya avtonomnyiye fiksturyi: povtornyij import, konflikt versij, otsutstvuyusjhij PDF, otdeljnyiye annotacii, povrezhdyonnyij eksport, sokhraneniye originalov i otkaz do izmeneniya prinyatogo snimka. Zatem otdeljno proveryayetsya setevoj transport i vosstanovleniye posle preryivaniya.

Priyomka trebuyet povtoryayemogo oflajn-chteniya, otsutstviya dublikatov pri povtore tekh zhe vkhodov, proverki khyeshej, yavnogo rezuljtata po kazhdomu predstavleniyu, profilya i resheniya ob optimizacii. Izmeneniye obsjhej skhemyi manifesta i vladeniya fajlami prokhodit otdeljnuyu sovmestimuyu migraciyu. Avtomaticheskogo massovogo skachivaniya arXiv ili publikacii soderzhimogo biblioteki etot protokol ne vklyuchayet.

## Istochniki trebovanij i proverki vozmozhnostej

- [Komandyi o Mendeley i nauchnyikh istochnikakh, podtverzhdeniye arXiv](../../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/zapros.md).
- [Mendeley: eksport biblioteki](https://www.elsevier.support/mendeley/answer/how-can-i-export-my-library).
- [Mendeley: eksport PDF i annotacij](https://www.elsevier.support/mendeley/answer/how-do-i-export-pdf-files-and-annotations-from-mrm).
- [Mendeley: opublikovannyiye metodyi API](https://dev.mendeley.com/methods/).
- [Mendeley Reference Manager: import i nablyudayemaya papka](https://static.mendeley.com/md-stitch/releases/live/02-adding-references.e005845c.html).
- [Mendeley: obyyektyi API](https://dev.mendeley.com/overview/core_resources.html).
- [arXiv: identifikatoryi i versii](https://info.arxiv.org/help/arxiv_identifier.html).
- [arXiv: dostupnyiye formatyi](https://info.arxiv.org/help/view.html).
- [arXiv: licenzii](https://info.arxiv.org/help/license/index.html) i [povtornoye ispoljzovaniye](https://info.arxiv.org/help/license/reuse.html).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:59:28 MSK -->
<!-- content-sha256: sha256:b40e94c9133aaf99e0087b1412df3eeb495f4130333a163af85c858cc4fef94b -->
<!-- FUM-MD-RECENCY:END -->
