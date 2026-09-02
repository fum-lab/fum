# Bratislavskaya versiya pamyati FUM

[Pamyatj FUM](../Glossarij/pamyatj-FUM.md) susjhestvuyet v dvukh svyazannyikh predstavleniyakh: kanonicheskom russkom kirillicheskom i khranimom paralleljnom russkom latinskom. Kirillicheskiye fajlyi ostayutsya osnovnoj rabochej versiyej, a [bratislavskaya versiya](../Glossarij/bratislavskij-yazyik.md) odnostoronne i vosproizvodimo poluchayetsya iz nikh s pomosjhjyu LinguisticKit.

## Avtoritetnostj sloyov

Toljko kirillicheskaya oblastj redaktiruyetsya chelovekom ili agentom i sluzhit istochnikom trebovanij, ssyilok, proverok i sleduyusjhej generacii. Bratislavskaya oblastj ne prinimayet ruchnyikh soderzhateljnyikh pravok, ne ispoljzuyetsya dlya obratnogo preobrazovaniya i ne mozhet raskhoditjsya s kanonicheskim snimkom nezametno. Yeyo nalichiye v Git oznachayet khraneniye proverennogo proizvodnogo predstavleniya vmeste s pamyatjyu, a ne poyavleniye vtorogo istochnika istinyi.

Doslovnyij iskhodnyij zapros, vneshnij istochnik ili istoricheskij snimok ostayotsya pervichnyim toljko v kanonicheskoj oblasti. Yego latinskoye predstavleniye, yesli ono vklyucheno politikoj formata, yavno pomechayetsya kak proizvodnoye i svyazyivayetsya s khyeshem iskhodnyikh bajtov.

## Tochnoye preobrazovaniye

Russkij tekst preobrazuyetsya vyizovom LinguisticKit `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)` na zakreplyonnoj revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Eto tochnyij vnutrennij kontrakt FUM, a ne proizvoljnyij translit, smyislovoj perevod, ISO ili GOST. Smena tablicyi ili revizii yavlyayetsya versionirovannoj migraciyej vsej proyekcii s novyim sukhim planom, prosmotrom diff i povtornoj proverkoj kollizij.

Avtomatizaciya obyazana uchityivatj format. Obyichnyij russkij tekst preobrazuyetsya, a vneshniye URL, neprozrachnyiye identifikatoryi, zakreplyonnyiye mashinnyiye polya, khyeshi i inyiye tochnyiye kontraktyi sokhranyayutsya libo pereschityivayutsya toljko po yavnomu pravilu konkretnogo formata. Prostaya peredacha vsekh bajtov fajla v strokovoye preobrazovaniye ne schitayetsya realizaciyej etogo trebovaniya.

## Polnyij putj

Dlya kazhdogo vklyuchyonnogo iskhodnogo fajla otobrazheniye nachinayetsya ot polnogo puti otnositeljno kornya kanonicheskoj oblasti. Po otdeljnosti obrabatyivayetsya kazhdyij komponent: vse kirillicheskiye chasti imyon katalogov i fajlov preobrazuyutsya tem zhe LinguisticKit-kontraktom, a neizmenivshiyesya tekhnicheskiye chasti sokhranyayutsya i vsyo ravno zapisyivayutsya v manifest. Rasshireniye fajla sokhranyayetsya, poka versionirovannaya politika formata ne trebuyet inogo.

Bratislavskaya oblastj razmesjhayetsya v tochnom neperesekayusjhemsya prostranstve `Proyekcii/Bratislavskaya-pamyatj/`. Otobrazhyonnyiye fajlyi lezhat pod `fajlyi/`, a `manifest-proiskhozhdeniya-v2.json` khranit proiskhozhdeniye pokoleniya. Politika, plan i manifest versii 2 obrazuyut yavnuyu migraciyu; opublikovannyiye fajlyi versii 1 ostayutsya pobajtovo neizmennyimi i ne poluchayut novogo smyisla zadnim chislom. Eto neobkhodimo, potomu chto `README.md`, `AGENTS.md`, `LICENSE.md`, `.gitignore`, `fum`, `prototipyi.sh` i drugiye uzhe latinskiye puti posle transliteracii sovpadayut s istochnikami. Ni odin celevoj putj ne sovpadayet s istochnikom i ne popadayet obratno vo vkhodnoj obkhod.

Preobrazovaniye prekrasjhayetsya do pervoj zapisi pri exact-, NFC-, registronezavisimoj, fajlovo-katalozhnoj, prefiksnoj, dlinovoj ili platformennoj kollizii. Avtomaticheskij chislovoj suffiks ne skryivayet neodnoznachnostj. Simvolicheskiye ssyilki, gitlink, specialjnyiye fajlyi, dvoichnyiye ili ne-UTF-8 dannyiye dopuskayutsya toljko posle yavnoj politiki, kotoraya sokhranyayet proiskhozhdeniye i ne vyikhodit za granicu repozitoriya.

## Ssyilki i proiskhozhdeniye

Lokaljnaya ssyilka v preobrazuyemom dokumente vedyot na sootvetstvuyusjhuyu celj v tom zhe proizvodnom pokolenii. Yesli politika isklyuchayet celj iz pokoleniya, versionirovannoye dejstviye `сохранить_ссылку_на_канонический_слой` ostavlyayet yavnuyu ssyilku na kanonicheskij istochnik. Generator proveryayet registr kazhdogo komponenta, anchors i strukturnyiye ssyilki posle preobrazovaniya. Vneshniye URI lyuboj raspoznannoj skhemyi zasjhisjhenyi ot strukturnogo perepisyivaniya, a zarezervirovannyiye vnutrenniye markeryi ne mogut sovpastj s iskhodnyim tekstom.

Versionirovannyij manifest pokoleniya khranit kak minimum tochnyij iskhodnyij Git-snimok ili ekvivalentnyij polnyij khyeshirovannyij inventarj, versiyu skhemyi, oblastj i isklyucheniya, napravleniye i tablicu preobrazovaniya, reviziyu LinguisticKit, otobrazheniye kazhdogo iskhodnogo puti v celevoj, khyeshi iskhodnogo i proizvodnogo soderzhimogo i itogovyij nabor fajlov. Otsutstvuyusjhij, lishnij, ustarevshij ili vruchnuyu izmenyonnyij rezuljtat delayet pokoleniye nedejstviteljnyim.

## Peresborka i proverka

Povtoryayemoye massovoye preobrazovaniye realizovano cherez TDD. Krasnaya faza predshestvovala pervoj zapisi i zakrepila polozhiteljnyiye primeryi soderzhimogo i vlozhennyikh putej, kollizii, neizmenivshiyesya latinskiye imena, ssyilki, doslovnyiye oblasti, mashinnyiye formatyi, Unicode-normalizaciyu, registr, udaleniye i pereimenovaniye istochnikov, rekursivnyij vkhod, nastoyasjhij Git-konflikt i sboi na granicakh ustanovki.

Posle polnogo predvariteljnogo obkhoda novoye pokoleniye sobirayetsya vo vremennom sluzhebnom prostranstve, proveryayetsya po manifestu i ustanavlivayetsya celikom. Kazhdyij vyikhod snachala zapisyivayetsya i sinkhroniziruyetsya s bezopasnyim rezhimom v vyivedennom iz tokena prostranstve chastichnoj zapisi, zatem poluchayet okonchateljnyij rezhim, povtorno sinkhroniziruyetsya i atomarno stanovitsya polnyim vyikhodom. Do pervoj mutacii proizvodnogo prostranstva Git-dir eksklyuzivno poluchayet kvitanciyu s tokenom i polnyimi ustojchivyimi snimkami prezhnego i novogo pokolenij. Vnutrennij fazovyij zhurnal razlichayet podgotovku, rezervirovaniye prezhnej celi, ustanovku, prinyatiye i otkat, no pravo na perenos i udaleniye vyivoditsya toljko iz kvitancii. Do prinyatiya povtor vosstanavlivayet prezhneye podtverzhdyonnoye pokoleniye; posle prinyatiya idempotentno zavershayet ochistku. Publichnyiye plan i validator ne obkhodyat ostavshuyusya kvitanciyu, a primeneniye snachala vosstanavlivayet yeyo tranzakciyu. Atomarnoye pereimenovaniye `NO_REPLACE` ne zamenyayet uzhe poyavivsheyesya naznacheniye; mezhkatalozhnyij perenos sinkhroniziruyet katalog naznacheniya ranjshe kataloga istochnika, a vosstanovleniye raspoznayot toljko tochnyij avarijnyij dublikat s raznyimi inode i svorachivayet dokazannoye kvitanciyej podmnozhestvo. Snimok konfliktnyikh stadij i upravlyayusjhikh Git-ssyilok povtorno sveryayetsya pered ustanovkoj i prinyatiyem. Neizvestnyij libo izmenyonnyij sluzhebnyij obyyekt sokhranyayetsya i zakryivayet vosstanovleniye, rekursivnoye udaleniye nachinayetsya lishj posle polnogo obkhoda, a kvitanciya udalyayetsya poslednej. Oshibka ne ostavlyayet chastichno obnovlyonnoye derevo, a uspeshnaya peresborka udalyayet toljko dokazanno ustarevshiye upravlyayemyiye rezuljtatyi. Komponentyi puti proveryayutsya cherez `lstat` bez sledovaniya po simvolicheskim ssyilkam, rezhim celevyikh katalogov zakreplyon kak `0755`, sluzhebnogo kornya — kak `0700` nezavisimo ot `umask`.

Tranzakcionnaya modelj opirayetsya na dejstvuyusjhuyu posledovateljnuyu skhemu s odnoj dobrosovestnoj pishusjhej sessiyej i schitayet Git-dir doverennyim lokaljnyim operacionnyim sostoyaniyem. Stabiljnostj kvitancii proveryayetsya pered kazhdoj kriticheskoj mutaciyej; namerennaya poddelka yeyo drugim processom togo zhe poljzovatelya ostayotsya vne modeli ugroz, poskoljku dlya yeyo ustraneniya nuzhen vneshnij korenj doveriya. Yesli process pogib do atomarnoj publikacii kvitancii, yeyo tokenizirovannyij vremennyij fajl ostayotsya diagnosticheskim obyyektom v Git-dir: avtomatizaciya ne mozhet dokazatj vladeniye im i potomu ne udalyayet avtomaticheski.

Shtatnaya komanda `применить` polnostjyu peresobirayet pokoleniye, a nezavisimaya komanda `проверить-манифест` zanovo vyivodit ozhidayemyiye puti i bajtyi iz kanonicheskogo sloya, sveryayet manifest i otklonyayet ruchnoj drejf libo ostatochnyiye konfliktnyiye stadii Git. Obe komandyi vkhodyat v standartnyij smoke-check posle kanonicheskikh pishusjhikh generatorov. Posle zakryitiya otchyota vyipolnyayutsya yesjhyo rovno odna finaljnaya peresborka, odna nezavisimaya proverka i tochnaya postanovka `Proyekcii/**` v indeks, chtobyi khranimoye pokoleniye otrazhalo okonchateljnyiye kanonicheskiye bajtyi sessii.

Kanonicheskiye validatoryi, indeksatoryi, testovyij avtopoisk i generatoryi svezhesti isklyuchayut toljko tochnuyu kornevuyu oblastj `Proyekcii` i yeyo potomkov. Blizkiye imena, inoj registr i vlozhennyiye odnoimyonnyiye katalogi ne isklyuchayutsya. Proyeciruyemyiye `AGENTS.md`, `SKILL.md` i lyubyiye drugiye fajlyi proizvodnoj oblasti ne stanovyatsya instrukciyami, kornem proyekta ili rabochim katalogom agenta. Posle Git-konflikta proizvodnyiye fajlyi ne obyyedinyayutsya vruchnuyu: snachala razreshayetsya kanonicheskij sloj, zatem pokoleniye peresobirayetsya, tochno stavitsya v indeks komandoj `git add -f -A -- Proyekcii` i toljko posle zakryitiya unmerged-stadij nezavisimo proveryayetsya. Standartnyij smoke-check zapuskayetsya uzhe na beskonfliktnom indekse.

## Otnosheniye k kanonicheskomu protokolu pamyati

Eta fajlovaya yazyikovaya proyekciya ne menyayet profilj `fum.memory.canonical-json.v1` i yego yazyikonejtraljnyiye kanonicheskiye bajtyi, opisannyiye v [kanonicheskom protokole pamyati](47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md). Bratislavskaya versiya otnositsya k chelovekochitayemomu repozitornomu predstavleniyu pamyati; produktovyij format sobyitij i snimkov sokhranyayet sobstvennuyu skhemu sovmestimosti.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros realizacii FUM-STEP-0129](../Zhurnal/2026-09-01_11-19-59_MSK_realizovatj-bratislavskuyu-proyekciyu-pamyati/zapros.md)

## Opornyiye dokumentyi

- [Vosproizvodimyiye avtomatizacii FUM](17-vosproizvodimyiye-avtomatizacii.md)
- [Yazyikonejtraljnyij kanonicheskij protokol pamyati](47-yazyikonejtraljnyij-kanonicheskij-protokol-pamyati.md)
- [Podklyucheniye LinguisticKit](../Zavisimosti/README.md)
- [Avtomatizaciya bratislavskoj proyekcii](../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 17:52:20 MSK -->
<!-- content-sha256: sha256:ee7d997fd60a1adbefad8071c2cd6eb66763520367de5f2dac42226153ee3214 -->
<!-- FUM-MD-RECENCY:END -->
