# Lokaljnyiye navyiki i instrumentyi

Eti pravila polnostjyu chitayutsya do vyibora, sozdaniya, izmeneniya ili povtoryayemogo primeneniya lokaljnogo navyika, avtomatizacii libo instrumenta.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000115 -->
- Dlya sozdaniya, proverki i paketnoj migracii papok zaprosov ispoljzuj lokaljnuyu avtomatizaciyu [strukturyi papok zaprosov](../../Instrumentyi/fum-struktura-papok-zaprosov/SKILL.md). Yeyo sukhoj plan dolzhen byitj determinirovannyim, versionirovannyim i repozitorno-otnositeljnyim, chtobyi to zhe preobrazovaniye mozhno byilo vosproizvesti v nezavisimom checkout i ispoljzovatj kak stroiteljnyij blok budusjhego vyiravnivaniya struktur vetok i forkov pered sliyaniyem. Sama avtomatizaciya papok zaprosov ne poluchayet remote, ne pereklyuchayet vetki, ne vyipolnyayet merge i ne publikuyet rezuljtat. V korne `Журнал/` yedinstvennyim Markdown-fajlom ostayotsya `README.md`; prezhnij paralleljnyij katalog `Запросы/`, dubli, perenapravlyayusjhiye fajlyi i simvolicheskiye ssyilki sovmestimosti ne sozdayutsya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000154 -->
- Fajlyi [opisanij FUM dlya adresatov](../../Glossarij/opisaniye-FUM-dlya-adresata.md) ne redaktiruyutsya tochechnoj ruchnoj pravkoj. Pri sozdanii, ispravlenii ili obnovlenii opisaniye peresozdayotsya cherez yavnyij vyizov zakreplyonnoj [avtomatizacii FUM](../../Glossarij/avtomatizaciya-FUM.md), chtobyi kazhdaya rabochaya sessiya podtverzhdala rabotosposobnostj etoj avtomatizacii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000155 -->
- Yesli adresnoye opisaniye trebuyet izmeneniya, snachala obnovlyayutsya istochniki, pravila ili sama avtomatizaciya, zatem opisaniye peresobirayetsya celikom po etoj avtomatizacii; fajl iskhodnogo zaprosa fiksiruyet vyizvannuyu avtomatizaciyu i rezuljtat peresborki.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000156 -->
- Povtorno ispoljzuyemyiye sistemnyiye prilozheniya, CLI-komandyi, MCP-instrumentyi, instrumentyi sredyi agenta, skriptyi i vneshniye servisyi, kotoryiye primenyayutsya v rabochikh sessiyakh, fiksiruyutsya v [reyestre sistemnyikh prilozhenij i instrumentov](../../Glossarij/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md) `Инструменты/реестр-системных-приложений-и-инструментов.md`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000157 -->
- Kazhdyij fajl iskhodnogo zaprosa dolzhen soderzhatj ustojchivyij razdel `## Использованные инструменты`. V nyom perechislyayutsya realjno ispoljzovannyiye pri vyipolnenii zaprosa instrumentyi i prilozheniya: nazvaniye, versiya ili sposob proverki versii, ssyilka na zapisj v reyestre dlya povtorno ispoljzuyemyikh instrumentov, a takzhe pometka, yesli versiya ne raskryivayetsya sredoj.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000158 -->
- Nachinaya s zaprosa `2026-07-14_02-31-47_MSK_добавлять-идентификатор-сеанса-Codex`, kazhdyij novyij `запрос.md` dolzhen soderzhatj otdeljnyij razdel `## Идентификатор сеанса Codex` s yedinstvennoj strokoj `Codex-Thread-ID: <UUID>`; istoricheskiye fajlyi retrospektivno ne izmenyayutsya. Znacheniye beryotsya neposredstvenno iz `CODEX_THREAD_ID` kornevoj poljzovateljskoj zadachi Codex i pered pervyim `join` i sozdaniyem papki zaprosa perechityivayetsya iz sredyi tekusjhego processa; pereskaz v svodke, istorii soobsjhenij ili vruchnuyu perenesyonnaya stroka ne zamenyayut etu proverku. Pri rabote subagenta neljzya podmenyatj kornevoye znacheniye sobstvennyim dochernim `CODEX_THREAD_ID`, kornevoj identifikator peredayotsya yavno.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000159 -->
- `Codex-Thread-ID` schitayetsya publikacionno dopustimyim identifikatorom proiskhozhdeniya tekusjhej zadachi, no eto razresheniye ne rasprostranyayetsya na drugiye skryityiye identifikatoryi, soderzhimoye lokaljnyikh zhurnalov Codex, tokenyi, uchyotnyiye dannyiye ili privatnoye sostoyaniye sredyi. Odin seans Codex mozhet okhvatyivatj neskoljko rabochikh sessij FUM, poetomu identifikator ne zamenyayet vremennoj prefiks i fajl iskhodnogo zaprosa.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000160 -->
- Razdel `## Использованные инструменты` ne dolzhen raskryivatj sekretyi, tokenyi, privatnyiye URL, lokaljnyiye setevyiye adresa, imena khostov i drugoye nepublikuyemoye sostoyaniye. Yesli instrument vazhen, no yego tochnaya versiya nedostupna ili nepublikuyema, fiksiruyetsya proveryayemaya granica: imya kontrakta, postavsjhik sredyi, data ispoljzovaniya i izvestnyiye ogranicheniya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000161 -->
- Dlya sredyi ChatGPT i Codex neljzya podmenyatj odnoj obsjhej «versiyej Codex» raznyiye sloi. V fajle zaprosa razdeljno fiksiruyutsya toljko realjno uchastvovavshiye i nablyudayemyiye sloi: poverkhnostj ili prilozheniye s versiyej i nomerom sborki, vstroyennyij runtime, otdeljno ustanovlennyij CLI, aktivnaya modelj i rezhim rassuzhdeniya, a takzhe kontraktyi instrumentov agentskoj sessii. Versiya odnogo sloya ne schitayetsya versiyej drugogo.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000162 -->
- Identifikator aktivnoj modeli i rezhim rassuzhdeniya zapisyivayutsya toljko togda, kogda oni pryamo pokazanyi tekusjhej sessiyej, interfejsom ili komandoj statusa. Znacheniye po umolchaniyu iz konfiguracii pomechayetsya kak skonfigurirovannoye i ne vyidayotsya za dokazannyij snimok aktivnoj modeli. Formulirovka «versiya ne raskryivayetsya sredoj» primenyayetsya k konkretnomu sloyu posle proverki dostupnogo sposoba nablyudeniya, a ne ko vsej srede ChatGPT ili Codex celikom.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000167 -->
- Dlya rabotyi s prikreplyayemyimi materialami ispoljzuj lokaljnyij navyik `Инструменты/fum-materialyi-zaprosov/SKILL.md`; dlya rassharennyikh chatov ChatGPT ispoljzuj yego skript `Инструменты/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000168 -->
- Vse ustojchivyiye [avtomatizacii FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoryiye ispoljzuyutsya v rabote repozitoriya, nuzhno stremitjsya vosproizvoditj lokaljno v [pamyati FUM](../../Glossarij/pamyatj-FUM.md): khranitj iskhodnyiye tekstyi ili deklarativnyiye opisaniya, komandyi zapuska, konfiguracii, testovyiye primeryi, ogranicheniya i istoriyu izmenenij.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000169 -->
- Yesli vneshnyuyu avtomatizaciyu, servis ili modelj neljzya polnostjyu vosproizvesti lokaljno iz-za dostupa, sekretov, licenzij ili tekhnicheskikh ogranichenij, v repozitorii sokhranyayetsya lokaljnyij proveryayemyij sloj: interfejsnyij kontrakt, adapter, fiksturyi, simulyator, otchyot o nevosproizvodimoj chasti ili inaya publikacionno chistaya forma.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000170 -->
- Yesli [rabochaya sessiya](../../Glossarij/rabochaya-sessiya.md) vyiyavlyayet zadachu, kotoraya potencialjno mozhet povtoryatjsya, agent dolzhen rassmatrivatj yeyo kak kandidata na [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md) uzhe pri pervom vyipolnenii. K takim zadacham otnosyatsya, naprimer, ocenki, svodnyiye tablicyi, peresborka opisanij, proverki, sbor statistiki, shablonyi otchyotov i drugiye proceduryi, gde ozhidayemo prigodyatsya povtornyij zapusk, yedinaya metodika ili sravnimostj rezuljtatov.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000171 -->
- Dlya potencialjno povtoryayemoj zadachi predpochtiteljnyij rezuljtat - lokaljnaya avtomatizaciya, proveryayemyij shablon, deklarativnyij kontrakt ili testiruyemyij scenarij zapuska. Yesli polnocennuyu avtomatizaciyu neljzya sozdatj v tekusjhej sessii bez chrezmernogo rasshireniya zadachi, nuzhno yavno zafiksirovatj prichinu, ruchnoj status rezuljtata i blizhajshij shag k avtomatizacii v fajle [iskhodnogo zaprosa](../../Glossarij/iskhodnyij-zapros.md), [zhurnale rabot](../../Glossarij/zhurnal-rabot.md) i, kogda prodolzheniye ostayotsya aktualjnyim, otdeljnoj kartochkoj v `Планирование/карточки-шагов/`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000172 -->
- Vnovj vyiyavlennyij v rabochej sessii obobsjhayemyij princip, sposobnyij vliyatj na posleduyusjhiye zadachi, ne ostayotsya toljko v otvete ili doslovnom zhurnale. Sessiya svyazyivayet yego s tochnyim iskhodnyim svideteljstvom i libo zakreplyayet v kanonicheskom istochnike pravil ili trebovanij s primenimoj proverkoj, libo ukazyivayet uzhe susjhestvuyusjhij ne boleye slabyij ekvivalent, libo sozdayot aktualjnuyu kartochku daljnejshej realizacii s yavno zafiksirovannoj granicej. Kartochka ne podmenyayet nemedlenno primenimuyu fiksaciyu, a vremennaya celj ne prevrasjhayetsya bez otdeljnogo osnovaniya v bessrochnoye pravilo.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000173 -->
- Yesli odin i tot zhe mekhanicheskij shag trebuyetsya vyipolnitj dlya neskoljkikh fajlov, zapisej ili inyikh odnotipnyikh obyyektov, agent ne povtoryayet yego vruchnuyu. Snachala ispoljzuyetsya susjhestvuyusjhaya lokaljnaya avtomatizaciya; yesli yeyo kontrakt nedostatochen, do massovogo vyipolneniya sozdayotsya ili rasshiryayetsya TDD-avtomatizaciya, posle chego sama operaciya vyipolnyayetsya cherez neyo. Otsutstviye gotovoj avtomatizacii ne schitayetsya razresheniyem na ruchnoye povtoreniye.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000174 -->
- Kazhdaya novaya ili pereimenovyivayemaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) poluchayet kanonicheskoye smyislovoye nazvaniye na russkom yazyike kirillicej. Yego latinskoye predstavleniye dolzhno tochno sovpadatj s rezuljtatom `LinguisticKit` dlya preobrazovaniya `.Cyrl -> .Latn` po tablice `.ru` na zakreplyonnoj v [reyestre nazvanij avtomatizacij](../../Instrumentyi/reyestr-nazvanij-avtomatizacij.json) revizii; eto kanonicheskij kontrakt FUM, a ne zayavleniye o sootvetstvii otdeljnomu universaljnomu standartu ISO ili GOST.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000175 -->
- Tekhnicheskij identifikator avtomatizacii obrazuyetsya iz rezuljtata `LinguisticKit` otdeljnoj normalizaciyej FUM: nizhnij registr, zamena granic slov defisami i, gde nuzhen obsjhij namespace, prefiks `fum-`. Eta normalizaciya ne schitayetsya chastjyu transliteracii; neodnoznachnostj ili sovpadeniye dvukh identifikatorov zakryivayut dobavleniye. Polya sovmestimosti `legacy` i `legacy_display` v [reyestre nazvanij avtomatizacij](../../Instrumentyi/reyestr-nazvanij-avtomatizacij.json) sokhranyayutsya dlya chteniya istoricheskogo formata i testovyikh fikstur, no v kanonicheskom reyestre pustyi: prezhniye identifikatoryi migrirovanyi, a isklyucheniye neljzya vozvrasjhatj ili kopirovatj dlya novoj avtomatizacii. Obnovleniye revizii ili tablicyi `LinguisticKit` provoditsya kak yavnaya migraciya reyestra. Vnutrenneye imya vspomogateljnogo fajla ili komandyi samo po sebe ne stanovitsya nazvaniyem avtomatizacii, yesli ono ne obyyavleno yeyo identifikatorom.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000181 -->
- Dlya obyichnogo pereimenovaniya ili peremesjheniya otslezhivayemogo fajla v rabochem dereve ispoljzuj lokaljnuyu avtomatizaciyu [pereimenovaniya fajla s obnovleniyem ssyilok](../../Instrumentyi/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/SKILL.md): iskhodnyij fajl dolzhen byitj chistyim otnositeljno Git-index i rabochego dereva, snachala proverj polnyij plan, zatem primeni yego. Avtomatizaciya sopostavlyayet lokaljnyiye Markdown-ssyilki po razreshyonnoj celi, pereschityivayet vkhodyasjhiye i iskhodyasjhiye otnositeljnyiye adresa, vyipolnyayet nastoyasjhij `git mv` i ostanavlivayetsya do zapisi, yesli ne mozhet dokazatj polnotu ili bezopasnostj preobrazovaniya; globaljnaya zamena imeni fajla v tekste ne schitayetsya korrektnyim obnovleniyem ssyilok.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000182 -->
- Domenno upravlyayemyiye fajlyi pereimenovyivayutsya toljko specializirovannyim kontraktom, yesli on susjhestvuyet. V chastnosti, dlya kartochek shagov ispoljzuj `Инструменты/fum-reyestr-planirovaniya/scripts/rename-step-card.py`, potomu chto krome puti i ssyilok on sinkhroniziruyet status, indeks i vetochnoye pokoleniye; obsjhij instrument obyazan napravlyatj takoj sluchaj k specializirovannoj komande. Doslovnyiye razdelyi `Журнал/*/запрос.md` pod zagolovkom `## Текст запроса` i syiryiye materialyi `Источники/` ne perepisyivayutsya avtomaticheski.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000232 -->
- Dlya rabotyi s glossariyem ispoljzuj toljko lokaljnyij navyik `Инструменты/fum-glossarij/SKILL.md`.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:13:37 MSK -->
<!-- content-sha256: sha256:293c2037af6bc7478d868372585292c6d4a015f07052e0f1ba32e4311c564e25 -->
<!-- FUM-MD-RECENCY:END -->
