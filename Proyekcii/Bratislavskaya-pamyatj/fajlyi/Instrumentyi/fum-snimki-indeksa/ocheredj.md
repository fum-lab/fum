# Pozdniye komandyi i barjyer pokoleniya

Lokaljnaya biblioteka `scripts/очередь.py` sokhranyayet pozdnij raw JSONL i tipizirovannyiye resheniya vyizyivayusjhego sloya. Eto tretij ogranichennyij segment0155 posle [vkhoda](kontrakt.md) i [materializacii](materializaciya.md). Ispolneniye, primeneniye prinyatogo snimka i zakryitiye polnogo0155 otsutstvuyut. Svodki sostoyaniya i rezuljtatyi barjyernyikh metodov soderzhat `исполнение_разрешено: false`; sozdaniye vozvrasjhayet obyyekt ocheredi, dostavka — raw-zapisj ili `None`.

## Vkhod i doverennaya granica

`Очередь.создать(каталог, источник, задача, снимок, хэш_входа, курсор, разрешения)` poluchayet tochnyiye UUID zadachi i snimka, SHA-256 uzhe proverennogo vkhoda i lokaljnyij kursor `fum.локальная-граница-диалога.1`. Vyizyivayusjhij sloj obyazan poluchitj etu svyazj iz uspeshnoj proverki vkhoda; ocheredj ne povtoryayet Git-proverku i ne udostoveryayet podpisj vkhoda. Kursor polnostjyu vosproizvoditsya iskhodnyim adapterom na zakreplyonnom prefikse. Poetomu ogranicheniye pervonachaljnogo adaptera na yedinstvennuyu tekstovuyu chastj sokhranyayetsya imenno dlya iskhodnogo prefiksa.

Istochnik — fizicheskij putj k obyichnomu fajlu tekusjhego UID bez symlink i hardlink. Zakreplyayutsya yego dev/ino, zadacha i khyesh pervoj stroki. Pervoye uspeshnoye sozdaniye sokhranyayet **vse uzhe prochitannyiye bajtyi**, vklyuchaya pozdnij i chastichnyij khvost. Nablyudyonnyij istochnik mozhet toljko dopisyivatjsya. Usecheniye, izmeneniye bajtov, smena inode i povtornyij `session_meta` dayut otkaz. Peremesjheniye ili rotaciya istochnika v etoj versii ne podderzhanyi.

Ocheredj nakhoditsya v novom chastnom kataloge 0700 pod fizicheskim roditelem tekusjhego UID s rezhimom 0700. Yeyo fajlyi imeyut rezhim 0600. Vyizyivayusjhij sloj razmesjhayet katalog vne prinimayemogo checkout, materializacii i publichnyikh artefaktov: on soderzhit raw-dialog i lokaljnyiye puti. Publichnyij otchyot soderzhit toljko sinteticheskiye fiksturyi i khyeshi. Povtornoye otkryitiye `Очередь(каталог, привязка)` trebuyet tochnoj vneshne sokhranyonnoj `очередь.привязка`: skhema, UUID ocheredi, zadachi i snimka, khyesh vkhoda, kursor, putj i inode istochnika. Neljzya molcha otkryitj novyij pustoj katalog vmesto poteryannogo.

## Proiskhozhdeniye i resheniye

Razdelitelj JSONL — toljko LF. Kazhdyij zavershyonnyij raw-fragment khranitsya vmeste s iskhodnyim LF, a nezakonchennyiye nablyudyonnyiye bajtyi sokhranyayutsya bez dostavki do zaversheniya. Identichnostj soobsjheniya zadayut UUID ocheredi/zadachi/snimka, khyesh vkhoda i istochnika, nomer i tochnyiye nachalo/konec/khyesh stroki. Odinakovyij tekst v raznyikh poziciyakh ostayotsya dvumya soobsjheniyami. `event_msg` khranitsya kak raw, no ne dubliruyet dostavki `response_item`.

Pozdniye poljzovateljskiye `response_item` klassificiruyutsya po iskhodnomu payload **do sklejki chastej**. Podderzhanyi takzhe sostavnyiye soobsjheniya s izobrazheniyem ili audio; dannyiye ne skachivayutsya i ne ispolnyayutsya. Rezuljtat klassifikatora — `человек`, `служебный контекст`, `служебный hook` ili `неоднозначный`. Poslednij blokiruyet ocheredj. Izvestnyiye sluzhebnyiye soobsjheniya dostavlyayutsya s sobstvennyim proiskhozhdeniyem. Povrezhdyonnyij JSON, povtornyiye klyuchi, specialjnyiye chislovyiye konstantyi i povrezhdyonnaya obolochka dayut sokhranyayemuyu neodnoznachnostj.

Klassifikator skopirovan bez izmeneniya bajtov iz commit `002bb953671fa82b2144e7ec506d4975df977e3c`, putj `Инструменты/fum-svyaznostj-rabochej-sessii/scripts/происхождение_сообщений.py`, SHA-256 `a3fdf3e04d9cb023489b60ecabe87428c652cfca92b6336f99a66bb55122fd23`. Chuzhoj `SKILL.md` ne importirovalsya. Etot kod proveryayet strukturu i runtime-annotacii, **ne udostoveryayet lichnostj i ne dokazyivayet zapusk hook**. Tekst «ostanovisj» vnutri `HookPrompt` ne stanovitsya chelovecheskoj otmenoj. Takoj zhe tekst v annotirovannom chelovecheskom soobsjhenii tozhe ne porozhdayet resheniye avtomaticheski.

Resheniye — otdeljnyij zakryityij obyyekt s `идентификатор`, `ссылка`, `действие`, `разрешения`. Identifikator yavlyayetsya kanonicheskim UUID; ssyilka tochno sovpadayet s sokhranyonnoj raw-strokoj etoj ocheredi. Yeyo payload povtorno klassificiruyetsya kak `человек`. Resheniya s proiskhozhdeniyem hook/context/neodnoznachnyij otvergayutsya.

- `учесть` s `разрешения: null` oznachayet yavnuyu obrabotku chelovekom ili doverennyim vyizyivayusjhim sloyem bez izmeneniya nabora polnomochij.
- `отозвать` s `разрешения: null` neobratimo stavit sostoyaniye otmenyi.
- `сузить` prinimayet otsortirovannyij unikaljnyij spisok nepustyikh strok, yavlyayusjhijsya podmnozhestvom prezhnego nabora. Rasshireniya i vosstanovleniya net. Pustoj nabor ne dayot razresheniya vyipolnitj kakoye-libo dejstviye.

Povtor togo zhe UUID i tekh zhe kanonicheskikh bajtov idempotenten. Drugiye bajtyi s tem zhe UUID blokiruyut ocheredj. Novoye resheniye s drugim UUID ob uzhe obrabotannom soobsjhenii dopustimo i sozdayot novoye pokoleniye. Povtornoye `учесть` i `сузить` s tem zhe naborom tozhe dopustimyi; rasshireniye i vosstanovleniye prav zapresjhenyi. Podtverzhdeniye dostavki samo ne yavlyayetsya resheniyem i ne vosstanavlivayet prava.

## Zhivoj kanal i dostavka

Metodyi `доставить`, `подтвердить`, `барьер` i `проверить_барьер` poluchayut funkciyu `наблюдать(запрос)`. Pod blokirovkoj ocheredi ona poluchayet novyij sluchajnyij UUID zaprosa i vozvrasjhayet zakryityij obyyekt `запрос`, `состояние: доступен`, `решения: [...]`. Vyizyivayusjhij sloj obyazan v etot moment proveritj tekusjhuyu svyazj i vklyuchitj vse uzhe poluchennyiye primenimyiye resheniya, yesjhyo ne sokhranyonnyiye ocheredjyu. Povtornyiye resheniya dopustimyi. Isklyucheniye, nesovpavshij UUID, drugoj status ili nepraviljnaya forma otveta oznachayut poteryu kanala. `None` oznachayet otsutstviye svezhego nablyudeniya i ne vyidayot barjyer.

UUID zaprosa predotvrasjhayet sluchajnoye povtoreniye starogo otveta; on ne prevrasjhayet proizvoljnuyu funkciyu v udostoverennyij kanal. Pravdivostj i polnota svezhego runtime-otveta — yavnaya doverennaya predposyilka API. Yesli otmena uzhe dostavlena vyizyivayusjhemu sloyu, no raw-stroka yesjhyo ne zavershena ili yeyo proiskhozhdeniye poka nedokazuyemo, vyizyivayusjhij sloj obyazan prekratitj rassmotreniye dejstvij i soobsjhitj poteryu kanala. Neljzya zhdatj JSONL, prodolzhaya poljzovatjsya staryim barjyerom.

Istochnik perechityivayetsya do i posle callback s proverkoj inode, razmera i vremyon izmeneniya. Novyiye bajtyi sokhranyayutsya do sravneniya barjyera. Pozdnyaya komanda, dopisannaya vo vremya callback, stanovitsya vidimoj ili blokiruyet proverku. Posle poslednego nablyudeniya pisatelj istochnika mozhet snova dopisatj dannyiye — eto opisannaya nizhe granica nablyudeniya.

`доставить(наблюдать)` vozvrasjhayet pervuyu nepodtverzhdyonnuyu zapisj ili `None`. Sobyitiye dostavki dolgovechno zapisyivayetsya **do vozvrata**. Posle avarii do podtverzhdeniya vozvrasjhayutsya tot zhe nomer i ta zhe ssyilka. `подтвердить(ссылка, наблюдать)` prinimayet toljko sleduyusjhuyu raneye dostavlennuyu zapisj. Povtor tochnogo starogo podtverzhdeniya idempotenten. Chelovecheskuyu komandu neljzya podtverditj bez yavnogo tipizirovannogo resheniya. Otmena mozhet byitj sokhranena do vyidachi sootvetstvuyusjhej dostavki; sama ocheredj ne zaderzhivayet otzyiv do podtverzhdeniya potrebitelem.

## Zhurnal i pokoleniya

`события.jsonl` — yedinstvennyij zhurnal sostoyaniya. Kazhdaya kanonicheskaya stroka soderzhit `поколение`, `предыдущий_хэш`, `вид`, `данные`. Pervoye pokoleniye — 1; posleduyusjhiye uvelichivayutsya rovno na yedinicu i ssyilayutsya na SHA-256 predyidusjhej polnoj stroki. Nachalo, prirasjheniye raw-istochnika, dostavka, resheniye, podtverzhdeniye i blokirovka vkhodyat v odin poryadok. Svezhij otvet kanala bez izmenenij ne sozdayot fiktivnogo pokoleniya.

Kazhdaya operaciya beryot `flock` na neizmenyayemom fajle `замок`, vosproizvodit vesj zhurnal, zatem proveryayet imenovannyiye inode kataloga, zamka i zhurnala. Posle operacii povtoryayutsya nablyudeniya imyon, chastnogo rezhima i otsutstviya pending; polnyiye bajtyi zhurnala sravnivayutsya s iskhodnyimi proverennyimi bajtami plyus sobstvennyimi prirasjheniyami. Povtornyij smyislovoj razbor tekh zhe bajtov ne nuzhen. Rabotayet odin serializovannyij pisatelj; otkryitiye FIFO i symlink ne prevrasjhayetsya v blokiruyusjheye chteniye.

Pered kazhdoj zapisjyu sozdayotsya `pending` cherez `O_EXCL`, sinkhroniziruyutsya fajl i katalog, polnostjyu dopisyivayetsya sobyitiye i sinkhroniziruyetsya zhurnal. Toljko posle proverki identichnosti sobstvennoj metki ona udalyayetsya i sinkhroniziruyetsya katalog. Korotkiye zapisi obrabatyivayutsya ciklom; nulevaya zapisj, ENOSPC i fsync-oshibka ne vozvrasjhayut uspekh. Pri oshibke poslednego shaga vosstanovleniye `pending` vyipolnyayetsya po vozmozhnosti cherez `O_EXCL`, bez udaleniya chuzhoj metki.

Obryiv zhurnala, ostavshayasya metka, povrezhdeniye cepochki i neizvestnoye sobyitiye zapresjhayut barjyer. Avtomaticheskogo udaleniya khvosta, vosstanovleniya, kompaktizacii ili sbrosa ocheredi v etoj versii net. Uspekh ugadyivatj po odnomu nalichiyu poslednej stroki neljzya. Pri lyuboj oshibke API vyizyivayusjhij sloj prekrasjhayet rabotu: polnostjyu nerabotayusjheye khranilisjhe ne pozvolyayet dolgovechno zapisatj dazhe fakt oshibki. Zasjhita ot polnogo otkata/zamenyi khranilisjha trebuyet nezavisimogo vneshnego yakorya pokoleniya; khyesh-cepochka sama etogo ne dokazyivayet. Proverki imyon i vremyon ne obesjhayut polnoj atomarnosti protiv vrazhdebnogo processa togo zhe UID, ne soblyudayusjhego protokol.

## Barjyer nablyudeniya

`состояние()` toljko chitayet sokhranyonnyiye svedeniya, bez zhivogo kanala. `барьер(наблюдать)` vozvrasjhayet odno iz chetyiryokh sostoyanij: `можно рассматривать следующий шаг`, `отменено`, `канал утрачен`, `неоднозначно`. Toljko pervoye soprovozhdayetsya obyyektom `fum.барьер-поздних-команд.1`. Nepodtverzhdyonnaya dostavka, nezavershyonnyij khvost, otsutstviye svezhego kanala ili blokirovka isklyuchayut yego vyidachu. Kanaljnaya blokirovka imeyet prioritet nad otobrazheniyem otmenyi; oba sostoyaniya zapresjhayut sleduyusjhij shag.

Barjyer soderzhit polnuyu privyazku, tochnyij kursor nablyudeniya, chislo podtverzhdenij, razresheniya, nomer i khyesh pokoleniya. `проверить_барьер(барьер, наблюдать)` snova sinkhroniziruyet ocheredj i sravnivayet vse kanonicheskiye bajtyi pod toj zhe blokirovkoj; pole `совпадает` istinno toljko dlya tekusjhego dopustimogo sostoyaniya. Lyuboye novoye sobyitiye delayet staryij obyyekt ustarevshim. Otdeljnyij read-only-snimok ocheredi ne zamenyayet etot vyizov.

Rezuljtat yavlyayetsya nablyudeniyem konkretnogo pokoleniya, **ne atomarnyim dopuskom posleduyusjhego ispolneniya**. Posle vozvrata blokirovka snyata, mozhet postupitj otzyiv; ispolnitelj obyazan budet svyazatj sleduyusjheye dejstviye s novyim protokolom dopuska. Takogo ispolnitelya zdesj net; CLI `допустить` po-prezhnemu bezuslovno otkazyivayet. Globaljnyiye hooks i fonovyiye nablyudateli ne ustanavlivayutsya.

## Proverki i stoimostj

Proverki zapuskayutsya cherez v4-obyortku tekusjhego Zhurnala. Novyiye testyi pokryivayut povtoryi, chastichnyij khvost, proiskhozhdeniye, tipizirovannuyu otmenu, staroye pokoleniye, poteryu istochnika/kanala, povrezhdeniye kursora i zhurnala, podmenyi imyon, ENOSPC, korotkiye zapisi, fsync i avarii processa. [Zhurnaljnyij otchyot](../../Zhurnal/2026-09-09_15-19-16_MSK_sokhranitj-ocheredj-pozdnikh-komand/otchyot.md) sokhranyayet realjnyiye RED/GREEN i ogranicheniya.

Profilj `tests/профилировать-очередь.py --выход <файл> [--сравнить <прежний>]` izmeryayet sozdaniye, sokhraneniye khvosta, dostavku, resheniye/podtverzhdeniye, barjyer i povtornoye otkryitiye na 2 i 100 soobsjheniyakh. Iskhodnyiye raw-bajtyi i normalizovannyiye dostavlennyiye bajtyi sravnivayutsya tochno; UUID ocheredi i lokaljnyiye inode ne obyyavlyayutsya povtoryayemyimi. Vremya fsync vlozheno v stadii; Python heap izmeryayetsya otdeljno i ne yavlyayetsya RSS. Predelyi — 64 MiB istochnika i 256 MiB zhurnala; WAL bez kompaktizacii vosproizvoditsya celikom na kazhdom vyizove. Eto ogranicheniye zatrat, ne obesjhaniye vyisokoj propusknoj sposobnosti na predeljnom razmere.

## Istochniki

- [Doslovnaya komanda i oblastj segmenta](../../Zhurnal/2026-09-09_15-19-16_MSK_sokhranitj-ocheredj-pozdnikh-komand/zapros.md).
- [Tochnyij importirovannyij klassifikator](scripts/proiskhozhdeniye_soobsjhenij.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:52:09 MSK -->
<!-- content-sha256: sha256:b1c79d14dcd1c84545bf317977433f389ee46d7fb841143b27180704f4433cf9 -->
<!-- FUM-MD-RECENCY:END -->
