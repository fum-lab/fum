# Yazyik i kod

Eti pravila polnostjyu chitayutsya do obyyavleniya ili izmeneniya sobstvennogo koda, psevdokoda, skhem i mashinnyikh kontraktov FUM.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000027 -->
- V sobstvennom kode FUM nezavisimo ot rasshireniya fajla, a takzhe vo vsekh sobstvennyikh blokakh i vstroyennyikh fragmentakh koda, psevdokoda, skhem i diagramm vnutri Markdown vse vvodimyiye proyektom smyislovyiye imena kanonicheskogo sloya pishutsya po-russki kirillicej. Pravilo okhvatyivayet, v chastnosti, imena tipov, protokolov, perechislenij i ikh variantov, funkcij i metodov, parametrov, svojstv, peremennyikh, konstant, psevdonimov, testov i identifikatorov uzlov Mermaid; bukva `ё` sokhranyayetsya po russkoj orfografii. Polnostjyu vyivodimyiye latinskiye kopii pod tochnoj oblastjyu `Proyekcii/**` sozdayutsya toljko avtomatizaciyej bratislavskoj proyekcii i ne yavlyayutsya novyimi sobstvennyimi obyyavleniyami.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000028 -->
- Klyuchevyiye slova yazyika, sintaksicheskiye markeryi, zakreplyonnyiye kompilyatorom ili sredoj vyipolneniya sluzhebnyiye imena, imena standartnoj biblioteki, sistemnyikh i vneshnikh API, obyazateljnyiye imena realizuyemyikh vneshnikh protokolov i pereopredelenij i importirovannyiye vneshniye simvolyi ne obyyavlyayutsya FUM i ne perevodyatsya. Tekhnicheski obyazateljnyij prefiks obnaruzheniya testa mozhet sokhranyatjsya pered russkoj smyislovoj chastjyu. Latinskaya abbreviatura v sobstvennom sostavnom imeni dopustima toljko vmeste s russkoj smyislovoj osnovoj, yesli yeyo tochnyij shablon, oblastj, klass isklyucheniya, prichina i proveryayemyij istochnik zakreplenyi v konechnom mashinnom perechne isklyuchenij; subyyektivnogo rasshireniya perechnya nedostatochno.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000029 -->
- Stabiljnyiye mashinnyiye kontraktyi — imena polej vneshnego ili uzhe versionirovannogo formata, komandyi i flagi CLI, peremennyiye sredyi, Git refs, identifikatoryi skhem, modulej, produktov i celej sborki — sokhranyayut tochnoye napisaniye lishj togda, kogda yego trebuyet sovmestimostj ili vneshnij instrument. Novyij sobstvennyij kontrakt vyibirayet russkoye imya, yesli format eto dopuskayet; kazhdoye vyinuzhdennoye latinskoye isklyucheniye dolzhno imetj proveryayemuyu prichinu i istochnik, a izmeneniye sobstvennogo opublikovannogo kontrakta vyipolnyayetsya kak yavnaya versionirovannaya migraciya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000030 -->
- Doslovnyiye bloki iskhodnyikh zaprosov, vneshniye istochniki, citatyi i istoricheskiye snimki ne perepisyivayutsya radi etogo pravila. Komandyi i fragmentyi, pokazyivayusjhiye vneshnij interfejs bukvaljno, sokhranyayut trebuyemoye vneshneye napisaniye; okruzhayusjhiye sobstvennyiye obyyavleniya i poyasneniya ostayutsya russkimi.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000031 -->
- Perevod susjhestvuyusjhikh obyyavlenij schitayetsya massovyim povtoryayemyim preobrazovaniyem i vyipolnyayetsya toljko [lokaljnoj TDD-avtomatizaciyej perevoda obyyavlenij koda](../../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/SKILL.md): ona stroit polnyij vosproizvodimyij inventarj podderzhannyikh sintaksisov, otlichayet sobstvennyiye obyyavleniya ot vneshnikh i doslovnyikh oblastej, prinimayet yavnoye sootvetstviye starogo i russkogo imeni, proveryayet kollizii i khyeshi vkhodov, pokazyivayet sukhoj plan, primenyayet token-osoznannuyu zamenu i podtverzhdayet ostatok. Do pervoj massovoj zapisi obyazateljnyi padayusjhiye testyi dopustimyikh i opasnyikh sluchayev i ikh dovedeniye do uspekha; ruchnaya seriya odnotipnyikh zamen po fajlam ne dopuskayetsya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000032 -->
- Poka istoricheskij ostatok ne svedyon k nulyu, yego tochnyij mashinnyij snimok yavlyayetsya toljko vremennoj granicej migracii: avtomaticheskaya proverka zapresjhayet novyiye latinskiye sobstvennyiye obyyavleniya v podderzhannyikh sintaksisakh i ne pozvolyayet nezametno uvelichitj ili zamenitj ostatok. Proverka isklyuchayet toljko tochnuyu polnostjyu vyivodimuyu oblastj `Proyekcii/**`; registrovyiye, suffiksnyiye i vlozhennyiye pokhozhiye puti ostayutsya kanonicheskim vkhodom, a celostnostj latinskikh kopij dokazyivayet otdeljnyij validator proyekcii. Poyavleniye sobstvennogo koda v inom sintaksise do pervogo novogo obyyavleniya trebuyet TDD-rasshireniya inventarya i proverki; snimok `.swift`, `.py` i Mermaid ne dokazyivayet polnotu dlya drugogo formata. Polnoye zaversheniye perevoda trebuyet nulevogo neobosnovannogo ostatka vo vsekh sobstvennyikh iskhodnikakh nezavisimo ot rasshireniya, soglasovannoj migracii zatronutyikh mashinnyikh kontraktov i prokhozhdeniya primenimyikh testov, sborok i obsjhej kompleksnoj proverki repozitoriya.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:832e1d8b3a7f19a82ab1c05c036cf6e51302f1ceb484a23f93a8f30fb9118518 -->
<!-- FUM-MD-RECENCY:END -->
