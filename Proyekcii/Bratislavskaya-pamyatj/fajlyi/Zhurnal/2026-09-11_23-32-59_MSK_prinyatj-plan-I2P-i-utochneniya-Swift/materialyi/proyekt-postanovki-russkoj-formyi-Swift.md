# Proyekt postanovki russkoj iskhodnoj formyi Swift

Po komandam 258–261 sobstvennaya russkaya iskhodnaya forma FUM preobrazuyetsya strukturiruyusjhimi operatorami v standartnyij Swift. Poljzovatelj razreshil SwiftSyntax kak bibliotechnyij primitiv. Standartnyij kompilyator vklyuchayetsya v graf cherez fakticheskiye zadaniya, ikh vkhodyi, rezuljtatyi, diagnostiku i zavisimosti. Etot dokument sokhranyayet proverennyij kornem proyekt dlya predmetnogo priyoma; novyiye nomera, kod, zavisimosti i pravila poka ne vvedenyi.

## Rezuljtat pervogo sreza

Odin vosproizvodimyij primer soderzhit funkciyu, peremennuyu, usloviye, vozvrat i otdeljno vyibrannyij kontekstnyij sluchaj. Opredeleniya operatorov porozhdayut tochnyiye Swift-bajtyi i polnuyu kartu iskhodnika; zakreplyonnyij standartnyij kompilyator proveryayet poluchennyij kod. Zapusk otkryitogo primera dayot zaraneye zadannyij rezuljtat. Samostoyateljnyiye etalonyi vkhoda, vyikhoda i diagnostik ne peredayutsya ispolnitelyu kak podskazka.

Malyij slovarj pervogo sreza poluchayet yavnuyu versiyu. Polnoye trebovaniye okhvatyivayet inventarj klyuchevyikh slov i konstrukcij vyibrannogo Swift; nachaljnyij primer ne obyyavlyayetsya podderzhkoj vsego yazyika. Suffiks iskhodnoj formyi i yeyo manifest vyibirayutsya yavno. Obyichnyij fajl Swift bez takoj metki prodolzhayet oznachatj standartnyij Swift.

## Slovarj i ispolneniye

Dlya kazhdoj zapisi sokhranyayutsya russkoye i standartnoye napisaniye, dopustimaya rolj, kontekst, sposob bukvaljnogo ispoljzovaniya imeni i nezavisimyiye polozhiteljnyiye i otricateljnyiye primeryi. Razlichayutsya zarezervirovannyiye i kontekstnyiye slova, direktivyi, atributyi, makrosyi, operatoryi i vneshniye simvolyi. Vnutrenniye tokenyi SIL ne vklyuchayutsya avtomaticheski v poljzovateljskij slovarj.

SwiftSyntax nablyudayet derevo, tokenyi, iskhodnyiye diapazonyi i bajtyi. Slovarj, razreshyonnyiye pozicii, perekhodyi sostoyanij, zamenyi i svyazi ostayutsya opredeleniyami strukturiruyusjhikh operatorov. Izmeneniye dopustimoj zapisi opredeleniya na tekh zhe iskhodnyikh faktakh dolzhno izmenyatj rezuljtat libo otkaz bez izmeneniya bibliotechnogo adaptera.

Nuzhen otdeljnyij tipizirovannyij profilj togo zhe obsjhego ispolnitelya: posledovateljnosti tokenov, srezyi istochnika, rezuljtatyi sopostavlenij, porozhdayemyiye segmentyi i proiskhozhdeniye. On poluchayet sobstvennuyu skhemu, tipyi i konechnyiye byudzhetyi. Pole versii prezhnego opredeleniya ne pereklyuchayet yego grammatiku. Susjhestvuyusjhiye opredeleniya i bajtovyiye ogranicheniya sokhranyayutsya. Prinyatuyu postavku chistogo ispolnitelya 0208 yesjhyo trebuyetsya vyibratj i proveritj pered zavisimoj realizaciyej; v tekusjhej prinimayusjhej baze ostavalsya prezhnij ogranichennyij API.

## Granicyi iskhodnika

Tochnyiye UTF-8-bajtyi i SHA fiksiruyutsya do preobrazovaniya. Povrezhdeniye, neizvestnaya versiya, neodnoznachnyij kontekst, nepolnaya konstrukciya ili prevyisheniye byudzheta dayut ponyatnyij otkaz bez ustanovki chastichnogo rezuljtata. Skryityiye normalizaciya Unicode, izmeneniye registra i uravnivaniye ye i yo isklyuchenyi. Do preobrazovaniya i ustanovki sveryayutsya ozhidayemyiye SHA i baza migracii; nevernyij SHA, sdvig bazyi, vyikhod puti za razreshyonnuyu oblastj, simvolicheskaya ssyilka ili stolknoveniye vyikhodnyikh putej dayut zakryityij otkaz bez zamenyi prinyatogo rezuljtata.

Kommentarii i bukvaljnyiye segmentyi obyichnyikh, mnogostrochnyikh i rasshirennyikh strok sokhranyayutsya pobajtno. Kod vnutri interpolyacii preobrazuyetsya v svoyom rezhime; vlozhennyiye stroki i kommentarii snova zasjhisjhenyi. Uchityivayutsya razdeliteli, vlozhennostj i ekranirovannyiye identifikatoryi. Regex, atributyi, makrosyi i uslovnaya kompilyaciya poluchayut otdeljnoye yavnoye pokryitiye. Kopirovaniye neizvestnoj konstrukcii bez izmeneniya ne dokazyivayet yeyo podderzhku.

Issledovaniye vyiyavilo zavisimostj raspoznavaniya regex bez rasshirennyikh razdelitelej ot predshestvuyusjhego klyuchevogo slova ili identifikatora. Russkoye sootvetstviye return do preobrazovaniya imeyet druguyu leksicheskuyu rolj. Takoj sluchaj neljzya molcha schitatj praviljno razobrannyim; pervyij profilj proveryayet adresnyij otkaz i otdeljno podderzhannyiye rasshirennyiye razdeliteli. Vozvrasjhyonnoye vosstanovlennoye derevo SwiftSyntax takzhe ne oznachayet korrektnyij iskhodnik: nuzhnyi diagnostiki i proverka standartnogo vyikhoda.

## Migraciya i diagnostika

Do vklyucheniya slovarya inventariziruyutsya sovpadeniya s susjhestvuyusjhimi russkimi imenami, obyyavleniyami, upotrebleniyami, metkami i vneshnimi obyazateljnyimi simvolami. Plan zadayot ekranirovaniye libo soglasovannoye pereimenovaniye, iskhodnyiye khyeshi i sukhoj diff. Neodnoznachnaya svyazj blokiruyet primeneniye. Vneshniye API, serializovannyiye klyuchi, raw values i CLI ne perevodyatsya pobochnyim effektom. Dejstvuyusjhaya avtomatizaciya obyyavlenij 0117 sluzhit osnovoj inventarizacii, no yesjhyo ne realizuyet russkuyu iskhodnuyu formu. Pri migracii standartnyij Swift → russkaya forma → standartnyij Swift kartyi dvukh preobrazovanij kompoziruyutsya libo obe sokhranyayutsya s SHA promezhutochnyikh bajtov, chtobyi diagnostika i rezuljtat ostavalisj svyazanyi s iskhodnyim korpusom.

Karta iskhodnika yavlyayetsya samostoyateljnyim polnyim rezuljtatom. Pervichnyi poluotkryityiye diapazonyi UTF-8-bajtov vkhoda i vyikhoda; sokhranyonnyiye, zamenyonnyiye i sinteticheskiye segmentyi razlichayutsya. Karta svyazyivayet SHA istochnika, vyikhoda, opredeleniya i profilya. Ogranichennaya trassa v 256 sobyitij ne zamenyayet yeyo; boleye 256 znachimyikh segmentov libo polnostjyu otobrazhayutsya v predelakh sobstvennogo byudzheta kartyi, libo dayut yavnyij otkaz.

Diagnostiki, primechaniya i ispravleniya standartnogo kompilyatora sokhranyayutsya vmeste s obratnyim otobrazheniyem na russkuyu formu. Proveryayutsya kirillica, yo, CRLF, slova raznoj bajtovoj dlinyi i vstavlennoye ekranirovaniye. Neodnoznachnyij fix-it avtomaticheski ne primenyayetsya. Odnogo sourceLocation nedostatochno dlya kolonok, a yego vliyaniye na location-makrosyi trebuyet otdeljnogo kontrakta. SourceKit, formatirovaniye i makrosyi imeyut samostoyateljnyiye granicyi sovmestimosti.

## Kompilyator v grafe

Uzlyi otrazhayut fakticheskiye vkhodyi, zadaniya, dostupnyiye stadii i artefaktyi. Obyichnaya kompilyaciya ne zapuskayetsya zanovo radi kazhdogo vidimogo etapa. Proverka tipov, sborka i dopolniteljnyiye rezhimyi vyidachi promezhutochnyikh predstavlenij vyibirayutsya po nuzhnomu rezuljtatu; nalichiye rezhima ne dokazyivayet nezavisimoye vozobnovleniye vnutrennego prokhoda.

Interfejsyi frontend, sobyitiya driver, JSON AST i ostaljnyiye vnutrenniye formatyi zakreplyayutsya versiyami i fiksturami. Neizvestnaya versiya dayot otkaz sootvetstvuyusjhego adaptera. Nachaljnyij inkrementaljnyij plan mozhet dopolnyatjsya fakticheskimi zadaniyami, poetomu ne vyidayotsya za okonchateljnyij polnyij graf.

Dlya vosproizvedeniya uchityivayutsya iskhodniki, importyi, zagolovki, parametryi yazyika, target, SDK, kompilyator, linker, runtime, biblioteki, makroplaginyi, susjhestvennoye okruzheniye i otobrazheniye putej. Kyesh i swiftdeps ne zamenyayut inventarj. Izmeneniye kazhdogo susjhestvennogo vkhoda proveryayet invalidirovaniye prezhnego rezuljtata. Zapusk programmyi i zagruzka plaginov ostayutsya otdeljnyimi effektami. Pobajtovaya vosproizvodimostj binarnika raznyikh okruzhenij trebuyet svoyego dokazateljstva.

## Priyomka i profilj

Budusjhiye RED/GREEN okhvatyivayut tochnyij vyikhod, kollizii, zasjhisjhyonnyiye oblasti, vlozhennyiye interpolyacii, neodnoznachnyij regex, povrezhdyonnyij UTF-8, versii, byudzhetyi, kartu dlinneye trassyi i koordinatyi diagnostik. Proveryayutsya prezhniye opredeleniya i migraciya, izmeneniye pravila bez perepisyivaniya adaptera, preryivaniye do ustanovki i sokhrannostj prinyatogo pokoleniya. Po sobyitiyam podtverzhdayetsya, chto otobrazheniye neskoljkikh faz ne uvelichivayet chislo fakticheskikh kompilyacij.

Profilj razdeljno izmeryayet bibliotechnyij razbor, proverku opredeleniya, preobrazovaniye, postroyeniye kartyi, pamyatj, serializaciyu i fakticheskoye zadaniye kompilyatora. Razmeryi, khyeshi, versii, rezhim kyesha i povtoryi fiksiruyutsya. Perekryivayusjhiyesya intervalyi ne skladyivayutsya, neizvestnyiye vnutrenniye vremena ne vyichislyayutsya dogadkoj. Optimizaciya vyibirayetsya po sopostavimyim izmereniyam.

## Ostavshiyesya resheniya

- Shtatno prinyatj otdeljnyiye predmetnyiye kartochki, svyazav 0067/0208, 0074/0220, 0075 i 0117; susjhestvuyusjhiye obyazateljstva sokhranyayutsya.
- Vyibratj slovarj, grammaticheskij profilj, yavnyij vkhodnoj format, pervyij kontekstnyij sluchaj i kartu migracii.
- Vyibratj prinyatuyu realizaciyu obsjhego ispolnitelya i sovmestimuyu paru Swift/SwiftSyntax. Issledovateljskij d38f4e9 ne stanovitsya vyibrannoj postavkoj avtomaticheski.
- Podgotovitj zerkala, tochnyiye revizii, LICENSE/NOTICE i zamyikaniye budusjhikh zavisimostej po 0074/0075. Issledovaniye i razresheniye biblioteki ne dokazyivayut postavku.
- Zakrepitj oblastj russkoj formyi v kanonicheskikh pravilakh i proverkakh do zavisimoj realizacii. Pravilo 000028 prodolzhayet otnositjsya k standartnomu vyikhodnomu Swift; tekusjhij priyomochnyij kontur master ne menyayetsya vo vremya yego proverki.

## Istochniki

- [Pervichnyiye komandyi i vopros 259](svideteljstva/pervichnyiye-komandyi.json), [iskhodnyij zapros](../zapros.md).
- [Issledovaniye koordinatora i Noether s pervichnyimi ssyilkami](issledovaniye-russkoj-formyi-Swift.md), [proiskhozhdeniye i SHA](svideteljstva/proiskhozhdeniye-Swift.json). Issledovaniye prochitano kornem; novyikh sborok i setevyikh proverok v etom perenose ne byilo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:52:33 MSK -->
<!-- content-sha256: sha256:d2de0fb0674dd9427254e0c3223f4a08db745993abfb58fe7c7f0fc1e9f48a7c -->
<!-- FUM-MD-RECENCY:END -->
