# Pasport dokumentacionnogo prototipa i pervogo korobochnogo sreza FUM

Etot pasport fiksiruyet dve svyazannyiye, no ne tozhdestvennyiye formyi [FUM](../Glossarij/FUM.md). Pervaya forma uzhe nablyudayetsya: chelovek rabotayet s vneshnej agentskoj sessiyej Codex, a dolgovremennyij rezuljtat sokhranyayetsya v Git-repozitorii, otkryitom v Obsidian kak khranilisjhe. Vtoraya forma poka toljko proyektiruyetsya: uzkij perenosimyij srez budusjhego servisa istochnikov prinimayet odin ustojchivyij publichnyij HTML-URL v lokaljnuyu [pamyatj FUM](../Glossarij/pamyatj-FUM.md). Prinyatyij lokaljnyij CLI-arkhivator sluzhit dokazateljstvom chasti kontrakta, no ne yavlyayetsya gotovyim korobochnyim servisom, yedinyim prilozheniyem ili sobstvennyim agentskim runtime FUM.

## Nablyudayemyij dokumentacionnyij prototip

Tekusjhij [dokumentacionnyij prototip FUM](../Glossarij/dokumentacionnyij-prototip-FUM.md) yavlyayetsya gibridnyim rabochim konturom, a ne avtonomnyim programmnyim uzlom. Yego ustojchivostj voznikayet iz sovmestnoj rabotyi neskoljkikh uchastnikov i instrumentaljnyikh sloyov.

### Roli

- **Chelovek** formuliruyet namereniye, prinosit iskhodnyiye materialyi, zadayot ogranicheniya i prava, dayot neobkhodimyiye podtverzhdeniya, ocenivayet smyisl rezuljtata i sokhranyayet za soboj resheniye o publikacii i perekhode k novoj stadii. Yego doslovnyij vklad otdelyayetsya ot proizvodnogo teksta i khranitsya kak [iskhodnyij zapros](../Glossarij/iskhodnyij-zapros.md).
- **Codex** predostavlyayet vneshnyuyu agentskuyu sessiyu: poluchayet dostupnyij kontekst, chitayet pravila i pamyatj, vyizyivayet razreshyonnyiye instrumentyi, predlagayet i vnosit proizvodnyiye izmeneniya, zapuskayet proverki i obyyasnyayet rezuljtat. Modelj, orkestraciya sessii i chastj instrumentaljnyikh kontraktov prinadlezhat vneshnej srede i ne vosproizvodyatsya samim repozitoriyem.
- **Obsidian-khranilisjhe** — eto rabochaya kopiya repozitoriya, otkryitaya cheloveku kak svyaznoye khranilisjhe Markdown-fajlov. Obsidian dayot navigaciyu, poisk, graf i vizualjnoye predyyavleniye, no kanonicheskimi nositelyami pamyati ostayutsya fajlyi i ikh proveryayemyiye svyazi; lokaljnoye sostoyaniye interfejsa Obsidian ne stanovitsya avtomaticheski chastjyu obsjhej pamyati.
- **Git** fiksiruyet versii, sostav izmeneniya, nasleduyemuyu istoriyu i granicu kommita. On pozvolyayet sravnitj i peredatj rezuljtat, no sam ne interpretiruyet trebovaniya, ne podtverzhdayet smyislovuyu praviljnostj i ne delayet lokaljnyij kommit opublikovannyim.
- **Lokaljnyiye avtomatizacii** materializuyut povtoryayemyiye proverki i preobrazovaniya: sokhranyayut istochniki, sveryayut svyaznostj sessii i planirovaniya, obnovlyayut sluzhebnuyu svezhestj i vyipolnyayut avtonomnyij smoke-check. Oni vkhodyat v pamyatj kak kod, testyi i kontraktyi i zapuskayutsya chelovekom libo rabochej sessiyej. Kazhduyu pishusjhuyu sessiyu poljzovatelj zapuskayet vruchnuyu; prezhneye [prodolzheniye toj zhe Git-vetki](../Glossarij/obyazateljnoye-prodolzheniye-vetki.md) sokhraneno kak otlozhennyij mezhzadachnyij eksperiment i ne yavlyayetsya sobstvennyim planirovsjhikom FUM.

Nablyudayemyij rabochij kontur vnutri otdeljnoj zadachi imeyet formu `намерение человека -> внешняя сессия Codex -> изменение файлов -> локальные проверки -> Git-коммит -> чтение и оценка человеком в Obsidian`. Perekhod mezhdu pishusjhimi zadachami vyipolnyayet poljzovatelj: zavershivshayasya sessiya ne sozdayot rebyonka i ne peredayot yemu vladeniye. Obyazateljnoye prodolzheniye vetki, obsjhij FIFO i atomarnyij handoff sokhranenyi toljko kak otlozhennyij eksperimentaljnyij profilj.

### Proveryayemaya mnogoagentnostj i granica konteksta

Neskoljko chatov ili subagentov Codex ne stanovyatsya vnutrennimi FUM toljko iz-za kolichestva ili vzaimnogo soglasiya. V nablyudayemom prototipe oni yavlyayutsya vneshnimi ispolnitelyami. Ikh rabota priblizhayet [proveryayemyij mnogoagentnyij kontur FUM](../Glossarij/proveryayemyij-mnogoagentnyij-kontur-FUM.md) toljko kogda kazhdyij vklad imeyet otlichimuyu rolj i granicu, proiskhozhdeniye sokhranyayetsya v obsjhej pamyati, utverzhdeniya proveryayutsya po nablyudayemyim svideteljstvam, a raznoglasiya, vyibor i ostanovka yavnyi.

Kontekstnoye okno modeli schitayetsya vremennoj rabochej oblastjyu, a ne dolgovremennoj pamyatjyu. Poetomu shirokaya trayektoriya sokhranyayetsya v adresuyemyikh fajlakh i razbivayetsya na [kartochki shagov](../Glossarij/kartochka-shaga.md). V dejstvuyusjhej ruchnoj skheme odna sessiya dolzhna s vyisokoj veroyatnostjyu zavershatj odin samostoyateljno proveryayemyij rezuljtat v odnom svezhem kontekstnom okne vmeste s obyazateljnyim chteniyem i proverkami. Otlozhennyij profilj `automatic` dopolnyal etu celj atomarnoj peredachej, FIFO-dopuskom i vetochnyim selektorom; chislovaya garantiya ne zayavlyayetsya bez telemetrii.

### Masshtabyi nepreryivnosti

| Masshtab             | Tekusjhij kontur                                                               | Korobochnaya granica                                                    |
| ------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Vnutri odnoj zadachi | Codex vyipolnyayet diskretnyij cikl chteniya, dejstviya, nablyudeniya i proverki.     | Sobstvennyij lokaljnyij runtime i yego trassa.                           |
| Mezhdu zadachami      | Poljzovatelj vruchnuyu zapuskayet sleduyusjhuyu pishusjhuyu sessiyu posle zaversheniya.    | Produktovyij planirovsjhik i sostoyaniye bez vneshnej orkestracii Codex.    |
| Chelovecheskij vvod   | Otpravlennaya zadacha mozhet menyatj pamyatj, trebovaniya i sleduyusjhij shag.         | Razreshyonnyij potok sobyitij vliyayet na aktivnyij cikl v bezopasnoj tochke. |

Na mezhzadachnom masshtabe tekusjhaya realizaciya sokhranyayet prichinnuyu svyazj cherez obsjhuyu [pamyatj](../Glossarij/pamyatj-FUM.md), no ne yavlyayetsya avtomaticheski vozobnovlyayemyim konturom. Poljzovatelj vruchnuyu zapuskayet novuyu zadachu kak [nablyudayemyij vkhodnoj signal](../Glossarij/nablyudayemyij-vkhodnoj-signal.md); cherez izmenyonnyiye trebovaniya i pamyatj ona mozhet perenapravitj posleduyusjhuyu celj, prioritet, plan, dejstviye ili proverku. Takoye opisaniye ne trebuyet i ne predpolagayet dostupa k skryityim rassuzhdeniyam modeli.

Granica prototipa ostayotsya susjhestvennoj. Ispolneniye razbito na otdeljnyiye vruchnuyu zapuskayemyiye kornevyiye zadachi, a sama poverkhnostj sessij prinadlezhit vneshnej srede Codex. Tekusjhij kontur vidit chelovecheskij vvod posle otpravki soobsjheniya-zadachi; [korobochnaya realizaciya](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna prinimatj razreshyonnyiye sobyitiya vvoda vo vremya aktivnogo cikla i uchityivatj ikh na bezopasnoj kontroljnoj tochke. Eto nepreryivnostj upravleniya i prichinnoj svyazi perekhodov, a ne nepreryivnyij inference ili obyazateljnyij vyizov LLM na kazhdoye sobyitiye; otlozhennaya strogaya FIFO ne yavlyayetsya aktivnyim marshrutom repozitoriya.

### Vneshniye zavisimosti i perenosimaya granica

K vneshnim zavisimostyam nablyudayemogo kontura otnosyatsya prilozheniye i runtime Codex, ispoljzuyemaya modelj i instrumentaljnyiye kontraktyi, prilozheniye Obsidian, operacionnaya i fajlovaya sistemyi, Git, interpretatoryi i kompilyatoryi lokaljnyikh avtomatizacij. Obyichnyij priyom URL dopolniteljno zavisit ot seti, udalyonnogo uzla i transporta; publikaciya zavisit ot otdeljnogo udalyonnogo Git-servisa. Dostupnostj, versii i vnutrenneye sostoyaniye etikh komponentov ne vyivodyatsya iz soderzhimogo pamyati.

Perenosimyim yavlyayetsya ne konkretnoye sochetaniye Codex i Obsidian, a yego proveryayemaya struktura:

- namereniye i iskhodnyij material sokhranyayutsya s proiskhozhdeniyem;
- cheloveku vidnyi predpolagayemoye dejstviye, prava, ogranicheniya, rezuljtat i oshibka;
- dejstviye vyipolnyayetsya cherez yavnyij kontrakt s minimaljnyimi pravami;
- rezuljtat prokhodit lokaljnuyu proverku i vozvrasjhayetsya v dolgovremennuyu pamyatj;
- proizvodnoye predstavleniye sokhranyayet putj k istochniku;
- publikaciya, vneshneye dejstviye i rasshireniye avtonomii ne vyivodyatsya iz lokaljnogo razresheniya po umolchaniyu.

Nevosproizvodimaya vneshnyaya chastj dolzhna byitj zamenyayema lokaljnyim kontraktom, fiksturoj ili chestnyim otchyotom o granice vosproizvodimosti. Imenno eti invariantyi, a ne interfejs tekusjhikh prilozhenij, dolzhnyi perejti v budusjhuyu [korobochnuyu realizaciyu FUM](../Glossarij/korobochnaya-realizaciya-FUM.md).

## Pervyij inzhenernyij srez: bezokonnoye vosproizvodimoye popolneniye pamyati

Nachalo korobochnogo prototipa otdelyayetsya ot pervogo poljzovateljskogo reliza. Pervyim inzhenernyim srezom yavlyayetsya [minimaljnyij lokaljnyij SwiftPM-paket](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) bez GUI, seti, realjnoj LLM i vneshnikh effektov. On poluchayet versionirovannuyu posledovateljnostj shtatnyikh sobyitij popolneniya pamyati, primenyayet ogranichennyiye vnutrenniye operacii pamyati i ispolneniya, stroit kanonicheskij snimok i sokhranyayet trassu proiskhozhdeniya kazhdogo prinyatogo i proizvodnogo elementa. Tochnaya granica etogo pokoleniya zadana [pasportom nachaljnogo korobochnogo prototipa](43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md).

Bezokonnaya forma yavlyayetsya proveryayemoj granicej, a ne okonchateljnyim interfejsom. Odin i tot zhe nabor vkhodov dolzhen davatj pobajtovo odinakovyij otchyot nezavisimo ot kataloga zapuska i mashinnogo vremeni; izmeneniye vkhoda dolzhno menyatj snimok nablyudayemyim obrazom. Povtornoye vosproizvedeniye iz pustogo sostoyaniya i posleduyusjheye inkrementaljnoye prodolzheniye dolzhnyi v zrelom konture skhoditjsya k odnomu logicheskomu sostoyaniyu, a sboj ne dolzhen prevrasjhatj chastichnyij rezuljtat v prinyatyij snimok.

GUI poyavlyayetsya posle zhiznesposobnosti etogo yadra i stroitsya na tekh zhe vnutrennikh mekhanizmakh. Kanonicheskaya pamyatj porozhdayet deklarativnuyu modelj predyyavleniya, operator ispolneniya svyazyivayet dostupnoye dejstviye s pravami i ozhidayemyim perekhodom, a interfejsnoye sobyitiye vozvrasjhayetsya v tot zhe zhurnal i redjyuser. Otdeljnaya vruchnuyu podderzhivayemaya modelj ekrana, ne vosstanavlivayemaya iz pamyati i trassyi, ne udovletvoryayet etoj granice dazhe pri nalichii rabotayusjhego okna.

Pervyij paket podtverzhdayet toljko nachaljnuyu konechnuyu fiksturu i determinirovannyij redjyuser. On ne obyyavlyayet gotovyimi dolgovremennoye khranilisjhe, sobstvennyij LLM-provajder, nepreryivnyij runtime, produktovuyu upakovku ili GUI. Daljnejshiye pokoleniya dolzhnyi zamenyatj vneshniye stroiteljnyiye lesa vnutrennimi mekhanizmami FUM po odnomu nablyudayemomu kontraktu, sokhranyaya vosproizvodimyij kontroljnyij progon predyidusjhego pokoleniya.

## Pervyij produktovyij vertikaljnyij srez: priyom ustojchivogo URL v pamyatj

Pervyim uzkim produktovyim vertikaljnyim srezom vyibirayetsya priyom odnogo ustojchivogo publichnogo HTTPS-URL s prostyim HTML-otvetom v lokaljnuyu pamyatj. Eto komponent budusjhego servisa istochnikov vnutri yedinogo lokaljnogo prilozheniya FUM, a ne samostoyateljnaya korobochnaya postavka vsego agenta i ne pervyij inzhenernyij zapusk korobochnogo yadra. Vyibor opirayetsya na uzhe proverennyij lokaljnyij kontur proiskhozhdeniya i ogranichivayet pervuyu poljzovateljskuyu realizaciyu odnim ponyatnyim vkhodom, odnim poljzovatelem i odnim atomarno prinyatyim rezuljtatom.

Granica sreza poluchayet identifikator `fum.source-ingest.v1`. Strogaya [mashinnaya skhema kontrakta](36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza/kontrakt-pervogo-URL-sreza-v1.schema.json) zadayot soobsjheniya `prepare_request`, `prepared_plan`, `confirmation`, `execute_request` i `execution_result`, vlozhennyiye skhemyi manifesta i proiskhozhdeniya, stabiljnyiye kodyi oshibok i logicheskiye entrypoint `prepare`, `show-plan`, `confirm`, `execute` i `status`. Obyichnaya JSON Schema proveryayet formu odnogo soobsjheniya; normativnyiye pravila `x-fum-*` dopolniteljno trebuyut samostoyateljnogo validatora kanonizacii, khyeshej, sovpadeniya polej mezhdu soobsjheniyami, seti i tranzakcii i proveryayutsya priyomochnoj matricej. Skhema yavlyayetsya vkhodom budusjhej realizacii; nalichiye fajla i prokhozhdeniye odnogo strukturnogo validatora ne oznachayut susjhestvovaniya libo gotovnosti servisa.

### Versiya, sovmestimostj i identichnostj URL

Kazhdoye soobsjheniye soderzhit tochnyiye `contract_version = fum.source-ingest.v1` i `schema_version = 1`; neizvestnoye pole, otsutstvuyusjheye obyazateljnoye pole ili nesovmestimaya versiya otklonyayutsya, a ne ugadyivayutsya. Novaya nesovmestimaya semantika poluchayet novyij identifikator kontrakta. Stabiljnyimi yavlyayutsya mashinnyiye kodyi i polya, no ne chelovekochitayemyij tekst oshibki.

Profilj `fum.source-url.canonical.v1` stroit kanonicheskij fetch-URL do seti i imeyet sleduyusjhiye pravila:

- prinimayetsya toljko absolyutnyij ASCII `https`-URL dlinoj ne boleye `4096` bajt, bez userinfo; Unicode-imya uzla dolzhno byitj zaraneye predstavleno kak ASCII A-label, a IP-literalyi i port, otlichnyij ot `443`, v v1 zapresjhenyi;
- ASCII-host proveryayetsya kak posledovateljnostj LDH-metok, perevoditsya v nizhnij registr, odna zavershayusjhaya tochka udalyayetsya, a pustaya metka, odinochnoye imya, nachaljnyij ili konechnyij defis metki i imya sverkh DNS-limitov otklonyayutsya; eto namerennoye ogranicheniye ustranyayet zavisimostj v1 ot razlichayusjhikhsya IDNA-profilej;
- pustoj putj stanovitsya `/`, bukvaljnyiye i poluchivshiyesya posle dekodirovaniya unreserved-oktetov dot-segmentyi udalyayutsya po RFC 3986, hex-cifryi percent-encoding perevodyatsya v verkhnij registr, a unreserved-oktetyi dekodiruyutsya; upravlyayusjhiye simvolyi, probel i obratnaya kosaya cherta zapresjhenyi;
- query sokhranyayet iskhodnyij poryadok, povtoryi, razdeliteli i razlichiye mezhdu otsutstvuyusjhim i pustyim query; znacheniya ne sortiruyutsya i ne interpretiruyutsya kak paryi klyuch-znacheniye;
- fragment ne uchastvuyet v HTTP-zaprose i identichnosti, udalyayetsya do dolgovremennoj zapisi, a plan pokazyivayet toljko fakt yego nalichiya bez znacheniya.

`source_id` raven `SHA-256(UTF8("fum.source-url.identity.v1") || 0x00 || UTF8(canonical_url))`. Razreshyonnoye perenapravleniye ne menyayet etu identichnostj: polnyij fakticheskij konechnyij URL pomesjhayetsya toljko v zasjhisjhyonnuyu lokaljnuyu zapisj proiskhozhdeniya, a publikacionno dostupnyiye puti, trassyi i oshibki soderzhat yego khyesh i redaktirovannoye predstavleniye bez znachenij query. Kolliziya `source_id` s inyim zasjhisjhyonnyim kanonicheskim URL zakryivayet operaciyu s oshibkoj celostnosti.

### Protokol podgotovki i podtverzhdeniya

Produktovaya granica sleduyet poryadku `prepare -> show plan -> confirm -> execute`.

1. `prepare` proveryayet skhemu, kanoniziruyet URL, chitayet toljko konfiguraciyu prav, tekusjhuyu reviziyu celevoj oblasti pamyati i reviziyu konteksta proiskhozhdeniya. On ne vyizyivayet DNS, ne vyipolnyayet `HEAD` ili `GET`, ne sozdayot istochnik i ne menyayet pamyatj libo proiskhozhdeniye.
2. `show plan` predyyavlyayet kanonicheskij i bezopasno redaktirovannyij URL, rezhim `create` ili `update`, tochnuyu oblastj zapisi, kontekst proiskhozhdeniya, tri zaprashivayemyikh prava, setevuyu politiku i limityi, isklyuchyonnyiye vozmozhnosti, vremya istecheniya i `plan_digest`. Polnyij kanonicheskij URL vkhodit v khyesh, dazhe kogda znacheniya query skryityi pri obyichnom pokaze.
3. `prepared_plan` poluchayet kriptograficheski sluchajnyij nonce ne koroche `128` bit i srok zhizni rovno `600` sekund. `plan_digest` — SHA-256 kanonicheskogo JSON plana bez samogo polya khyesha po profilyu `fum.memory.canonical-json.v1`; v khyesh vkhodyat nonce, polnyij kanonicheskij URL, revizii pamyati i proiskhozhdeniya, oblastj i prava, versiya i khyesh setevoj politiki, limityi i rezhim zapisi.
4. `confirm` prinimayet toljko tochnyiye nonce i `plan_digest` pokazannogo plana, fiksiruyet `confirmed_by`, vremya i otdeljnyij `confirmation_digest`. Istyokshij, izmenyonnyij, uzhe upotreblyonnyij ili otnosyasjhijsya k drugoj operacii plan ne zapuskayet setj. Obobsjhyonnoye podtverzhdeniye bez khyesha zapresjheno.
5. `execute` do seti povtorno proveryayet versiyu politiki, prava, celevuyu oblastj i obe ozhidayemyiye revizii. Podtverzhdeniye dolgovremenno zakhvatyivayetsya dlya yedinstvennoj operacii do pervogo setevogo obrasjheniya. Povtor togo zhe zaprosa vozvrasjhayet sokhranyonnyij konechnyij rezuljtat bez vtorogo polucheniya URL; posle prervannoj nezavershyonnoj operacii nuzhen novyij plan i novoye podtverzhdeniye.

### Razlichiye statusov

Prinyatyij `fum source archive` — lokaljnyij CLI-instrument dokumentacionnogo prototipa. On uzhe prokhodit avtonomnyij skvoznoj scenarij, sozdayot kanonicheskij snimok, ochisjhayet publikuyemyiye sloi, obnovlyayet snimok atomarno i svyazyivayet yego s fajlom zaprosa. Yego gotovnostj oznachayet gotovnostj etogo lokaljnogo instrumenta v zayavlennyikh granicakh.

Proyektiruyemyij korobochnyij servis istochnikov dolzhen statj postavlyayemyim produktovyim modulem: imetj ustojchivuyu granicu vyizova iz lokaljnogo prilozheniya, sobstvennuyu modelj prav i oshibok, nablyudayemuyu trassu, upravlyayemoye sostoyaniye i proveryayemuyu ustanovku vmeste s ostaljnyim produktovyim konturom. Ni takogo servisa, ni yego upakovki, ni integracii s yedinyim prilozheniyem eta rabochaya sessiya ne sozdayot.

Sledovateljno, gotovnostj `fum source archive` ne dokazyivayet gotovnostj servisa istochnikov, sobstvennogo agentskogo cikla, yedinogo prilozheniya, korobochnoj stadii ili vsej FUM. CLI yavlyayetsya iskhodnyim proverennyim obrazcom povedeniya, kotoryij budusjhaya realizaciya mozhet pereispoljzovatj ili zamenitj pri sokhranenii kontrakta.

### Pervyij poljzovatelj i yedinstvennyij scenarij

Pervyij poljzovatelj — odin uchastnik proyekta FUM, rabotayusjhij v odnoj lokaljnoj ustanovke i zhelayusjhij sokhranitj publichnyij material tak, chtobyi on ne ostalsya toljko ssyilkoj v dialoge.

Yedinstvennyij poljzovateljskij scenarij pervogo reliza: poljzovatelj peredayot ustojchivyij publichnyij HTTPS-URL prostoj HTML-stranicyi, vidit celevuyu lokaljnuyu oblastj pamyati i zaprashivayemyiye prava, podtverzhdayet priyom, a servis sokhranyayet proveryayemyij snimok i pokazyivayet ssyilku na istochnik, izvlechyonnyij tekst, otchyot, trassu i itogovyij status. Povtor togo zhe scenariya dlya togo zhe URL obnovlyayet tot zhe istochnik bez vtoroj susjhnosti i bez dublirovaniya svyazi s iskhodnyim namereniyem.

### Sostav pervogo reliza

V pervyij reliz proyektiruyemogo sreza vkhodyat:

- odna lokaljnaya operaciya priyoma ustojchivogo publichnogo HTTPS-URL s HTML-otvetom;
- yavnoye podtverzhdeniye chteniya URL i zapisi v vyibrannuyu lokaljnuyu oblastj pamyati;
- kanonicheskaya identichnostj istochnika, ne raskryivayusjhaya sekretopodobnyiye query- i fragment-znacheniya v imeni;
- ochisjhennyij snimok otveta, izvlechyonnyij chelovekochitayemyij tekst, indeks istochnika, otchyot izvlecheniya i tochnyij manifest upravlyayemyikh chastej;
- svyazj rezuljtata s iskhodnyim namereniyem poljzovatelya i polnaya trassa preobrazovanij;
- idempotentnyij povtor i atomarnaya ustanovka celogo snimka;
- produktovaya granica vyizova iz budusjhego lokaljnogo prilozheniya i avtonomnaya fikstura toj zhe granicyi.

V pervyij reliz ne vkhodyat rassharennyiye ChatGPT-dialogi, zagruzka poljzovateljskikh fajlov, privatnyiye ili avtorizovannyiye URL, cookies i uchyotnyiye zapisi, ispolneniye JavaScript stranicyi, obkhod platnyikh ogranichenij dostupa, fonovoj obkhod ssyilok, monitoring izmenenij, udalyonnoye khranilisjhe, mnogopoljzovateljskij dostup, polnocennaya sistema upravleniya bibliografiyej, avtomaticheskij Git-kommit ili publikaciya. Takzhe ne vkhodyat obsjhij interfejs vsego prilozheniya, sobstvennyij agentskij cikl, planirovsjhik, setj MCP-servisov i lyubyiye vneshniye dejstviya za predelami chteniya odnogo podtverzhdyonnogo URL.

Specializirovannaya podderzhka ChatGPT share uzhe susjhestvuyet v lokaljnom arkhivatore, no ne perenositsya v pervyij korobochnyij srez avtomaticheski. Yeyo vklyucheniye potrebuyet otdeljnogo produktovogo kontrakta i priyomki.

### Vkhodyi, vyikhodyi i trassa proiskhozhdeniya

Obyazateljnyiye vkhodyi sreza:

1. iskhodnyij ustojchivyij publichnyij HTTPS-URL bez vstroyennyikh uchyotnyikh dannyikh;
2. lokaljnyij kontekst proiskhozhdeniya — sokhranyonnoye namereniye ili zapisj zaprosa, s kotoroj istochnik dolzhen byitj svyazan;
3. razreshyonnaya oblastj lokaljnoj pamyati, dostupnaya servisu toljko dlya chteniya neobkhodimogo konteksta i zapisi rezuljtata;
4. pokazannyij podgotovlennyij plan i tochnoye podtverzhdeniye yego nonce i khyesha pri neizmennyikh politike, pravakh i reviziyakh;
5. dlya avtonomnogo testa — fiksirovannyij transport, fiksirovannyiye chasyi i determinirovannyiye identifikatoryi, podstavlennyiye za toj zhe produktovoj granicej.

Uspeshnyij vyikhod soderzhit kanonicheskuyu zapisj istochnika, ochisjhennyiye syirjyevyiye sloi, izvlechyonnyij tekst, chelovekochitayemyij indeks, otchyot ob ogranicheniyakh i redakciyakh, tochnyij manifest snimka, rovno odnu svyazj s iskhodnyim kontekstom i itogovuyu trassu. Imena konkretnyikh fajlov lokaljnogo CLI yavlyayutsya sovmestimyim iskhodnyim predstavleniyem, no korobochnyij kontrakt opredelyayetsya smyislovyimi rolyami artefaktov, a ne sluchajnoj raskladkoj pervoj rabochej sredyi.

Trassa proiskhozhdeniya dolzhna pozvolyatj vosstanovitj posledovateljnostj `намерение -> prepare -> показ плана -> подтверждение -> повторная локальная проверка -> DNS и закрепление адреса -> HTTPS и перенаправления -> заголовки -> ограниченный поток -> очистка -> извлечение -> манифест -> единая публикация снимка и происхождения -> итоговая проверка`. Dlya kazhdogo zvena sokhranyayutsya versiya kontrakta i politiki, nablyudayemyij bezopasnyij vkhod i vyikhod, status, oshibka ili ogranicheniye i ssyilka na dostupnyij boleye polnyij zasjhisjhyonnyij sloj. Soderzhimoye skryitogo rassuzhdeniya modeli ne trebuyetsya i ne podmenyayet nablyudayemuyu trassu dejstvij.

### Fazovaya setevaya granica

Proverki proiskhodyat v moment, kogda dannyiye stanovyatsya nablyudayemyimi, i ne vyidayutsya za polnostjyu dostupnyiye do seti.

- **Lokaljnyij preflight do seti** otklonyayet nedopustimuyu versiyu ili formu soobsjheniya, skhemu, userinfo, IP-literal, port, host, URL sverkh limita, nepodtverzhdyonnyij ili podmenyonnyij plan, izmenivshuyusya politiku, nedostatochnyiye prava i ustarevshiye revizii. Pri takom otkaze DNS, transport i kanonicheskaya zapisj ne vyizyivayutsya.
- **Kazhdyij DNS- i connect-hop** ispoljzuyet novyij zapros bez DNS search suffix, poluchayet ne boleye `16` A/AAAA-otvetov i otklonyayet vesj nabor, yesli khotya byi odin adres ne yavlyayetsya globaljno marshrutiziruyemyim po zakreplyonnoj tablice `fum.public-address-space.v1`. Zapresjhenyi kak minimum unspecified, loopback, private/unique-local, link-local, shared address space, protocol-assignment, documentation, benchmark, multicast, reserved, IPv4-mapped i NAT64-formyi, a takzhe metadata-adresa. Vyibrannyij adres zakreplyayetsya na soyedineniye; SNI i proverka sertifikata ispoljzuyut iskhodnyij ASCII-host, a fakticheskij peer obyazan tochno vkhoditj v proverennyij nabor. Proksi sredyi, PAC, DNS-povtor vnutri HTTP-kliyenta i HTTP/3 v v1 otklyuchenyi. Nesovpadeniye peer schitayetsya DNS rebinding i zakryivayet operaciyu.
- **Kazhdoye perenapravleniye** proveryayetsya zanovo do sleduyusjhego tela. Razreshenyi ne boleye pyati otvetov `301`, `302`, `303`, `307` ili `308`, toljko na tot zhe origin `https://<тот же ASCII-host>:443`; userinfo, IP-literal, downgrade, inoj host ili port, cikl i nedopustimyij DNS-rezuljtat zapresjhenyi. Telo redirect-otveta ne sokhranyayetsya.
- **Posle zagolovkov** uspeshnyim schitayetsya toljko kod `200`, odin neprotivorechivyij `Content-Length` ne boleye `4 194 304` bajt ili yego otsutstviye, `Content-Type: text/html` s otsutstvuyusjhim charset, `utf-8` libo `us-ascii`, i `Content-Encoding: identity`. Obsjhij blok zagolovkov ogranichen `65 536` bajtami, chislo polej — `128`, odno znacheniye — `8 192` bajtami. Nepodderzhivayemyij status, framing, MIME, charset, encoding ili obyyavlennyij razmer ostanavlivayet chteniye do tela.
- **Vo vremya potoka** peredacha ostanavlivayetsya pri popyitke poluchitj bajt `4 194 305`, nezavisimo ot `Content-Length` i chunked framing. DNS ogranichen pyatjyu sekundami na hop, soyedineniye i TLS — desyatjyu sekundami, prostoj potoka — desyatjyu sekundami, a vsya operaciya — tridcatjyu sekundami. Potok, zagolovki, izvlecheniye i vse upravlyayemyiye artefaktyi dopolniteljno ogranichenyi tochnyimi limitami mashinnoj skhemyi.

Politika adresov i vse limityi vkhodyat v pokazannyij i podtverzhdyonnyij plan. Izmeneniye tablicyi, limita ili setevoj semantiki sozdayot novyij khyesh politiki i trebuyet novogo podtverzhdeniya.

### Yedinaya tranzakcionnaya granica

Snimok, tochnyij manifest, zasjhisjhyonnaya zapisj polnogo URL i tipizirovannaya svyazj proiskhozhdeniya snachala sobirayutsya vne prinyatogo sostoyaniya. Ikh yedinstvennoj tochkoj vidimosti yavlyayetsya odin podtverzhdyonnyij generation commit pamyati s compare-and-swap po ozhidayemomu pokoleniyu. Etot commit soderzhit khyeshi vsekh artefaktov, polnuyu zapisj proiskhozhdeniya i rovno odno idempotentnoye rebro `source imported-from provenance_context`; proizvodnyij indeks ssyilok ne yavlyayetsya vtoryim istochnikom istinyi.

Dopustima obsjhaya ACID-tranzakciya khranilisjha libo ekvivalentnyij protokol `durable candidate -> fsync -> один атомарный CAS указателя -> recovery`. Dvukhshagovyij poryadok «snachala sdelatj snimok vidimyim, zatem dopisatj svyazj» i obratnyij yemu poryadok zapresjhenyi. Yesli khranilisjhe ne predostavlyayet takuyu granicu, operaciya zavershayetsya `atomic_commit_unavailable` do izmeneniya prinyatogo pokoleniya.

Oshibka transporta, ochistki, izvlecheniya, manifesta, zapisi proiskhozhdeniya, ustanovki, konflikt ozhidayemogo pokoleniya ili prinuditeljnoye zaversheniye do CAS ostavlyayut prezhneye pokoleniye pobajtno neizmennyim, a pri pervom sozdanii — istochnik otsutstvuyusjhim. Yesli process zavershyon posle CAS, no do otveta, recovery nakhodit `operation_id` vnutri prinyatogo pokoleniya i vozvrasjhayet tot zhe uspeshnyij rezuljtat bez novogo setevogo chteniya. Neizvestnoye sostoyaniye zakryivayetsya kak neuspeshnoye i ne povyishayet staging-kandidat. Posle recovery vremennyiye ostatki udalyayutsya libo ostayutsya yavno neprinyatyimi i nedostizhimyimi iz kanonicheskogo ukazatelya.

Stabiljnyiye kodyi oshibok, fazyi `preflight`, `confirmation`, `resolve`, `connect`, `redirect`, `headers`, `stream`, `transform`, `manifest`, `transaction` i `recovery`, a takzhe rezhim povtora `never`, `new_plan` ili `status_only` perechislenyi v mashinnoj skheme. Oshibka ne soderzhit polnogo URL, query, IP, absolyutnogo puti ili inoj lokaljnoj detali; neizvestnaya prichina poluchayet `internal_error`. Chelovekochitayemoye soobsjheniye ne yavlyayetsya chastjyu sovmestimosti.

### Prava, privatnostj i publikacionnaya chistota

Servis poluchayet minimaljnyiye prava: prochitatj odin podtverzhdyonnyij publichnyij URL, zapisatj toljko v vyidelennuyu oblastj istochnikov i dobavitj odnu tipizirovannuyu svyazj k iskhodnomu kontekstu. On ne poluchayet cookies poljzovatelya, tokenyi, proizvoljnoye chteniye domashnego kataloga, vyipolneniye otveta, zapisj vne pamyati, Git-kommit, push ili publikaciyu. Rasshireniye lyubogo iz etikh prav trebuyet otdeljnogo kontrakta i podtverzhdeniya.

Znacheniya `Set-Cookie`, avtorizacionnyiye zagolovki, lokaljnyiye adresa, sluzhebnyiye identifikatoryi transporta i drugiye sekretopodobnyiye dannyiye udalyayutsya do popadaniya v upravlyayemyij snimok i publikacionno dostupnuyu trassu. Polnyij kanonicheskij i konechnyij URL mogut khranitjsya toljko v zasjhisjhyonnoj lokaljnoj zapisi proiskhozhdeniya; putj, obyichnyij pokaz, indeks, trassa i oshibka ispoljzuyut `source_id`, khyeshi i redaktirovannoye predstavleniye bez znachenij query i fragment. Vremennyiye dannyiye ne sokhranyayutsya posle recovery doljshe, chem nuzhno dlya yavnoj diagnostiki.

Lokaljnoye sokhraneniye ne oznachayet razresheniya na otkryituyu publikaciyu. Avtorskiye, personaljnyiye i inyiye ogranichennyiye materialyi ostayutsya lokaljnyimi do otdeljnoj publikacionnoj proverki i resheniya poljzovatelya. Servis pokazyivayet etu granicu i ne prevrasjhayet uspeshnyij priyom v avtomaticheskij Git-kommit ili peredachu vo vneshnij servis.

### Osoznannyiye ogranicheniya v1

Pervyij kontrakt namerenno prinimayet toljko DNS-imya, port `443`, same-origin-perenapravleniya, `text/html`, kod `200`, identity-kodirovaniye i telo do `4 MiB`; ne podderzhivayet IP-literalyi, proxy, szhatiye, inoj charset, cross-origin redirect, HTTP/3, privatnyij URL i poljzovateljskiye zagolovki. Eto ogranichivayet sovmestimostj s realjnyimi sajtami, no delayet pervyij security-invariant vyipolnimyim i avtonomno proveryayemyim. Rasshireniye lyuboj granicyi trebuyet novoj politiki i podtverzhdeniya. Processnyiye crash-testyi dokazyivayut toljko soglasovannostj posle prinuditeljnogo zaversheniya processa na zakreplyonnoj lokaljnoj fajlovoj sisteme; power-loss durability i setevyiye fajlovyiye sistemyi ostayutsya otdeljnoj priyomkoj.

## Avtonomnaya priyomka budusjhej postavki

Budusjhij korobochnyij srez prinimayetsya determinirovannoj matricej «ustojchivyij HTML-URL stanovitsya istochnikom pamyati i bezopasno obnovlyayetsya». Proverka zapuskayetsya iz chistoj lokaljnoj sborki postavlyayemogo servisnogo modulya cherez te zhe `prepare` i `execute`, a ne podmenyayetsya neposredstvennyim vyizovom `fum source archive`.

1. Izolirovannaya vremennaya pamyatj, fiksirovannyiye chasyi, identifikatoryi i entropy, fiksturnyiye resolver, TLS-transport i nablyudatelj peer podayutsya za toj zhe produktovoj granicej. Vneshnyaya setj, sistemnyij DNS, sekretyi i kalendarnoye vremya ne ispoljzuyutsya.
2. Tablica URL-vektorov podtverzhdayet odinakovyij `source_id` dlya ekvivalentnyikh registra scheme/host, yavnogo `:443`, pustogo puti, dot-segmentov i dopustimogo percent-encoding, no raznyiye identichnosti dlya razlichayusjhikhsya libo perestavlennyikh query. Ni odno znacheniye query ili fragment ne poyavlyayetsya v puti, obyichnoj trasse ili oshibke.
3. `prepare` i pokaz plana ne vyizyivayut resolver, transport i zapisj. Vyizov bez podtverzhdeniya, podmena lyubogo svyazannogo polya, nevernyiye nonce ili digest, istecheniye `600` sekund, izmeneniye politiki, oblasti, prav ili revizii proiskhozhdeniya otklonyayutsya do seti. Povtor podtverzhdeniya ne sozdayot vtoroj fetch.
4. Otricateljnaya DNS-matrica pokryivayet private, loopback, link-local i metadata-adresa, smeshannyij public/private-nabor, boljshe `16` otvetov, zamenu adresa posle resolve, nesovpadeniye fakticheskogo peer i povtornoye soyedineniye. Na kazhdom otkaze net tela i prinyatoj zapisi.
5. Matrica perenapravlenij pokryivayet dopustimyij same-origin-hop, userinfo, HTTP downgrade, inoj host ili port, IP-literal, cikl, shestoj hop i public-to-private DNS-perekhod. Kazhdyij hop prokhodit novuyu DNS-proverku i peer pinning.
6. Matrica zagolovkov i potoka pokryivayet nepodderzhivayemyiye status, MIME, charset i encoding, konfliktuyusjhij libo prevyishennyij `Content-Length`, blok zagolovkov sverkh limita, chunked-telo bez dlinyi i bajt `4 194 305`. Zagolovochnyij otkaz ne chitayet telo, potokovyij obryivayet yego na zhyostkom limite, kanonicheskoye sostoyaniye ne menyayetsya.
7. Uspeshnyij `v1` sozdayot odin istochnik, ochisjhayet testovyiye sekretyi, sozdayot obyazateljnyiye artefaktyi, tochnyij manifest, odnu tipizirovannuyu svyazj proiskhozhdeniya i polnuyu uspeshnuyu trassu v odnom pokolenii. Uspeshnyij `v2` sokhranyayet `source_id`, atomarno zamenyayet vsyo pokoleniye, udalyayet otsutstvuyusjhij teperj neobyazateljnyij artefakt i ne dubliruyet svyazj togo zhe istochnika s tem zhe kontekstom.
8. Inyyekciya oshibok manifesta, zapisi proiskhozhdeniya i atomarnogo commit otdeljno proveryayetsya pri pervom sozdanii i obnovlenii: pervyij istochnik ostayotsya otsutstvuyusjhim, a prezhneye pokoleniye — pobajtno neizmennyim.
9. Realjnyiye docherniye writer-processyi prinuditeljno zavershayutsya v tochkakh `after_confirmation_claim`, `after_snapshot_staged`, `after_provenance_staged`, `before_generation_cas` i `after_generation_cas`. Novyij process zapuskayet recovery i vidit toljko otsutstviye/prezhneye polnoye pokoleniye libo polnostjyu proveryayemoye novoye pokoleniye so svyazjyu; crash posle CAS vozvrasjhayet sokhranyonnyij uspekh bez povtornogo fetch.
10. Finaljnaya sverka podtverzhdayet tochnoye ravenstvo sostava manifestu, khyeshej soderzhimomu, odnu dostizhimuyu zapisj proiskhozhdeniya, otsutstviye dublej i prinyatyikh vremennyikh ostatkov, neizmennostj prezhnego sostoyaniya na kazhdom otkaze i odinakovyij rezuljtat pri povtornom zaprose statusa operacii.

Progon schitayetsya dokazateljstvom korobochnogo sreza toljko posle poyavleniya postavlyayemogo servisnogo komponenta, mashinnoj proverki skhemyi i vyipolneniya etoj matricyi na yego dostupnoj produktovoj granice. Prokhozhdeniye uzhe susjhestvuyusjhikh testov lokaljnogo CLI ostayotsya vazhnoj regressiyej, no samo po sebe ne zakryivayet priyomku.

## Granica postavki i perekhoda

Otdeljnyij [iskhodnyij zapros 2026-07-24 10:44:28 MSK](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) pryamo razreshil nachatj korobochnyij prototip i vyibral boleye rannyuyu inzhenernuyu granicu — bezokonnoye vosproizvodimoye popolneniye pamyati na Swift. Eto snimayet vneshneye usloviye razresheniya, no ne zavershayet dokumentacionnyij prototip i ne razreshayet vyidavatj proverochnyij paket za produktovuyu postavku. Zakryitiye nakhodok [audita pasporta korobochnoj stadii](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md) podtverzhdayetsya toljko soglasovannyim stadijnyim komplektom i povtornyim auditom, a ne odnim etim dokumentom.

Dorabotka po `FUM-STEP-0035` razlichayet bezokonnyij inzhenernyij srez i URL-produkt. Rezuljtat otdeljnogo povtornogo audita fiksiruyet proverennoye sostoyaniye etogo kontrakta, no sam po sebe ne vyibirayet i ne razreshayet realizaciyu URL-servisa. Pryamoye razresheniye minimaljnogo Swift-prototipa ne rasshiryayet prava na setj, vneshniye servisyi, upakovku, poljzovateljskiye dannyiye ili fizicheskiye dejstviya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-25 11:56:07 MSK — Zakrepitj kontekstno ogranichennuyu mnogoagentnuyu realizaciyu FUM](../Zhurnal/2026-07-25_11-56-07_MSK_zakrepitj-kontekstno-ogranichennuyu-mnogoagentnuyu-realizaciyu-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-21 15:51:32 MSK - Podgotovitj pasport pervogo korobochnogo sreza FUM](../Zhurnal/2026-07-21_15-51-32_MSK_podgotovitj-pasport-pervogo-korobochnogo-sreza-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-22 03:38:35 MSK - Razreshitj vyipolneniye dostupnyikh kartochek shagov](../Zhurnal/2026-07-22_03-38-35_MSK_razreshitj-vyipolneniye-dostupnyikh-kartochek-shagov/zapros.md)
- [Interfejs FUM-uzla](25-interfejs-FUM-uzla.md)
- [Arkhitektura FUM](22-arkhitektura-FUM.md)
- [stadiya dokumentacionnogo prototipa FUM](../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md)
- [usloviya perekhoda k korobochnoj realizacii FUM](../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md)
- [prinyatyij pervyij reliz arkhivatora istochnikov](../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)
- [lokaljnyij kontrakt arkhivirovaniya prikreplyayemyikh materialov](../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)

## Opornyiye ponyatiya

- [Iskhodnyij zapros o dinamicheskom vyichislenii gotovnosti](../Zhurnal/2026-07-29_09-04-03_MSK_rasshiritj-dinamicheskij-vyibor-sleduyusjhego-shaga/zapros.md)
- [Dokumentacionnyij prototip FUM](../Glossarij/dokumentacionnyij-prototip-FUM.md)
- [Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md)
- [Interfejs FUM-uzla](../Glossarij/interfejs-FUM-uzla.md)
- [Agentskij cikl](../Glossarij/agentskij-cikl.md)
- [Pamyatj FUM](../Glossarij/pamyatj-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:52:01 MSK -->
<!-- content-sha256: sha256:bd655e82a9dd722644d9b4c2735e570de7fba1722f503adbe9f0136722d000cf -->
<!-- FUM-MD-RECENCY:END -->
