# Plan uskoreniya povtornoj peresborki proyekcii

Zadacha — sokratitj dliteljnostj povtornyikh peresborok bratislavskoj proyekcii, sokhraniv tochnyiye bajtyi rezuljtata, nezavisimuyu proverku i vosstanovleniye posle preryivaniya. Optimizaciya ostayotsya planom. Po posleduyusjhemu ukazaniyu poljzovatelya v sobstvennoj vetke realizovanyi profilirovochnyiye metki dlya izmereniya tekusjhego algoritma.

## Nablyudeniya i granicyi dokazateljstva

Ssyilki na nomera strok nizhe otnosyatsya k iskhodnoj versii a3bde39c84528848b13b0b2b415a7e6fd033b9a1 do dobavleniya metok.

- V sokhranyonnom otchyote sosednej sessii `Журнал/2026-09-07_18-16-36_MSK_принять-модель-бетонных-глубинных-систем/отчёт.md` uspeshnyij dokumentacionnyij smoke-check zanyal 3141,242 s, to yestj 52 min 21,242 s. Predyidusjhaya neuspeshnaya popyitka zanyala 3118,355 s. Eto vremya vsego sostavnogo processa; obyyavlyatj yego vremenem odnoj transliteracii neljzya.
- Generator pri kazhdoj otdeljnoj CLI-komande sozdayot novyij vremennyij korenj, razvorachivayet zakreplyonnyiye Git-arkhivyi i zadayot novyij SwiftPM scratch-path: `Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py:5705`. V komande na stroke 5766 otsutstvuyet yavnyij vyibor Release; nablyudeniye drugoj aktivnoj zadachi pokazyivayet ispolnyayemyij preobrazovatelj iz Products/Debug, rabotayusjhij neskoljko minut pochti s polnoj zagruzkoj odnogo yadra. Eto osnovaniye izmeritj vliyaniye konfiguracii sborki, a ne dokazannyij koefficiyent uskoreniya.
- Dazhe vetka «bez izmenenij» snachala formiruyet vse vyikhodyi, stroit kontroljnyij plan i vyizyivayet vnutrennyuyu nezavisimuyu proverku: tot zhe fajl, stroki 4910–4942. Rannego deshyovogo vozvrata do polnogo preobrazovaniya net.
- Nezavisimaya proverka zanovo stroit plan i formiruyet polnyij ozhidayemyij nabor vyikhodov: stroki 5250–5280. Sama nezavisimostj nuzhna; yeyo stoimostj neobkhodimo izmeryatj otdeljno.
- Pri izmenenii kanonicheskikh dannyikh zapisyivayetsya polnoye novoye pokoleniye s sinkhronizaciyej kazhdogo fajla i katalogov: stroki 4743–4819. Vozmozhnyij vklad diskovyikh operacij yesjhyo ne izmeren.
- Standartnyij smoke-check vyizyivayet primeneniye, zatem otdeljnuyu proverku. Posle zakryitiya otchyota dejstvuyusjheye pravilo FUM-PRAVILO-000188 trebuyet yesjhyo odnu takuyu paru. Eto ustanovlennyij poryadok, a ne sluchajnyij povtor, kotoryij mozhno molcha udalitj.
- Inventarj vklyuchayet novyiye neignoriruyemyiye fajlyi. Dobavleniye dazhe sobstvennoj kartochki v `Журнал/` menyayet snimok, kotoryij uzhe rabotayusjhaya peresborka obyazana povtorno sveritj. Otsutstviye konflikta sliyaniya ne garantiruyet neizmennosti etogo snimka.

## Utochneniye po nablyudyonnomu profilyu i novyim komandam

Progon 19 dal iskhodnuyu stoimostj: primeneniye 1918,608 s, dva preobrazovaniya soderzhimogo 1788,628 s summarno, otdeljnoye tretjye preobrazovaniye 1116,120 s. Snachala nuzhnyi vnutrenniye Swift-metki po dokumentam i obrabotke registra. V zakreplyonnom LinguisticKit uchastok StringProtocol.swift:119–129 povtoryayet filjtraciyu massiva dlya kazhdogo neodnoznachnogo registra i mozhet imetj kvadratichnuyu stoimostj; eto staticheskaya gipoteza, a ne izmerennyij vklad funkcii. Optimizaciya sokhranyayet fakticheskuyu semantiku konteksta i tochnyiye vyikhodnyiye bajtyi.

Dlya kazhdogo izmeneniya ispolnyayemogo koda obyazatelen cikl iz pravila 000176. Rabota sokhranyayetsya promezhutochnyimi kommitami v etoj postoyannoj zadache. Versionirovannaya podderzhka priyomochnyikh raundov realizovana s sokhraneniyem prezhnikh zakryityikh otchyotov. Zapisj 89 perevela tekusjhij otkryityij zhurnal na v4; predstoyasjhaya finaljnaya priyomka budet proveryatj aktualjnoye soderzhimoye.

## Posledovateljnostj realizacii

1. **Snyatj profilj na neizmenyayemom vkhode.** Razdelitj vremya podgotovki i kompilyacii preobrazovatelya, inventarizacii i khyeshirovaniya, preobrazovaniya putej, razbora Markdown, transliteracii soderzhimogo, zapisi pokoleniya i nezavisimoj proverki. Sravnitj kholodnyij zapusk, povtor bez izmenenij, izmeneniye odnogo dokumenta i izmeneniye toljko zakryivayusjhegosya otchyota. Uchityivatj chislo fajlov i bajtov, vyizovyi preobrazovatelya i perepisannyiye vyikhodyi. Zapuski vyipolnyatj v sobstvennoj dopusjhennoj pishusjhej sessii cherez shtatnuyu otchyotnuyu obyortku. V tekusjhej vetke metki uzhe dobavlenyi: oni razlichayut povtornyiye i vlozhennyiye intervalyi i sokhranyayut monotonnoye vremya. CLI-flag `--профилировать` libo `FUM_PROJECTION_PROFILE=1` vklyuchayet diagnostiku v stderr. Pervyij zamer Swift ostayotsya obsjhej stoimostjyu sborki, zapuska i preobrazovaniya; daljnejsheye razdeleniye etikh zatrat trebuyet dopolniteljnyikh izmerenij.
2. **Proveritj i vnedritj maloye uskoreniye ispolneniya.** Sravnitj Debug i Release na odnikh vkhodakh, podtverditj pobajtovoye sovpadeniye. Yesli vyiigryish podtverzhdyon, sobiratj izolirovannyij Release-preobrazovatelj odin raz i vyizyivatj gotovyij binarnyij fajl dlya sleduyusjhikh paketov strok vnutri processa. Zatem ocenitj povtornoye ispoljzovaniye proverennoj sborki mezhdu komandami. Klyuch dolzhen uchityivatj derevo obyortki, zakreplyonnuyu reviziyu LinguisticKit, konfiguraciyu i flagi sborki, Swift toolchain, SDK i arkhitekturu. Proizvoljnyij HEAD bez izmeneniya etikh vkhodov ne dolzhen obnulyatj kyesh.
3. **Ubratj lishniye vyichisleniya pri povtore.** Dlya neizmenivshegosya pokoleniya sravnivatj aktualjnuyu identichnostj vkhodov i fakticheskoye celevoye derevo do dorogogo formirovaniya vyikhodov. Polnuyu nezavisimuyu proverku ostavitj otdeljnyim etapom. Dlya neboljshikh izmenenij pereispoljzovatj rezuljtatyi toljko po dokazannomu klyuchu: bajtyi istochnika, iskhodnyij i celevoj puti, politika i versiya generatora, versiya preobrazovatelya, zavisimosti ssyilok i yakorej. Izmeneniye globaljnogo konteksta obyazano invalidirovatj zavisimyiye zapisi. Pervyim etapom mozhno kyeshirovatj toljko chistuyu transliteraciyu tochnyikh vkhodnyikh strok; eto menjshe zatragivayet semantiku ssyilok.
4. **Sokhranitj nezavisimostj proverki i atomarnostj ustanovki.** Proveryayusjhij process dolzhen vyivoditj ozhidayemyiye bajtyi iz kanonicheskikh vkhodov, ne doveryaya pare redaktiruyemyikh «manifest + celevoj fajl». Na pervom etape ne ispoljzovatj kyesh strukturnyikh vyikhodov v nezavisimom validatore. Novoye pokoleniye po-prezhnemu ustanavlivatj atomarno; optimizaciyu kopirovaniya i fsync rassmatrivatj toljko po rezuljtatam profilya i s prezhnimi avarijnyimi garantiyami.
5. **Zakrepitj izmerimyij rezuljtat.** Sravnitj polnyij i uskorennyij puti na odnom snimke: odinakovyiye puti, rezhimyi, bajtyi, manifest i vosstanovleniye posle otkaza. Povtor bez izmenenij ne dolzhen zanovo transliterirovatj vse dokumentyi na stadii primeneniya; izmeneniye odnogo dokumenta ne dolzhno trebovatj polnoj povtornoj transliteracii v generatore, yesli globaljnyiye zavisimosti ne izmenilisj. Nezavisimuyu proverku uchityivatj otdeljno. Chislennyij byudzhet vremeni vyibratj po pervomu profilyu i sokhranitj v regressionnom scenarii; uskoreniye v konkretnoye chislo raz sejchas ne obesjhayetsya.

6. **Zakrepitj povedeniye dlya budusjhikh zadach.** Po posleduyusjhim upravlyayusjhim komandam eta chastj vyipolnena v sobstvennoj vetke tekusjhej zadachi: obnovlenyi kanonicheskiye pravila i inventarj, dobavlenyi regressii registracii i izolyacii. Osnovnoj checkout drugoj zadachi ostayotsya dostupen toljko dlya chteniya. Fakticheskiye proverki i status integracii privedenyi v [otchyote](../../otchyot.md). Avtomatizaciya kartochki s zapisjyu toljko v sobstvennuyu papku do vyideleniya worktree ostayotsya vozmozhnyim otdeljnyim uluchsheniyem.

## Nezavisimoye utochneniye plana

Read-only-analiz susjhestvuyusjhikh testov podtverdil prioritet: profilj, Debug/Release, kyesh ispolnyayemogo preobrazovatelya, zatem inkrementaljnoye preobrazovaniye. Odin prokhod smoke-check sejchas formiruyet polnyij rezuljtat kak minimum trizhdyi: pri primenenii, vo vnutrennem i vo vneshnem validatorakh.

Rannij vozvrat neljzya razreshatj toljko po khyesham starogo redaktiruyemogo manifesta. Do uspeshnogo zaversheniya `применить` dolzhno sokhranyatjsya dostatochnoye nezavisimoye dokazateljstvo korrektnosti tekusjhego dereva: povtornoye vyichisleniye ili otdeljno obosnovannyij doverennyij lokaljnyij kyesh. Naruzhnaya proverka ne delayet bezopasnyim uzhe vozvrasjhyonnyij neobosnovannyij uspekh samogo primeneniya.

Susjhestvuyusjhij test idempotentnosti na stroke 2089 proveryayet rezuljtat; dopolniteljno nuzhnyi schyotchiki realjnyikh preobrazovanij. Test soglasovannoj podmenyi vyikhoda i manifesta na stroke 1923 dolzhen sokhranyatj otkaz na uskorennom puti. Test udaleniya i pereimenovaniya na stroke 2172 neobkhodimo dopolnitj izmeneniyem zavisimyikh ssyilok i yakorej. Vse tri nakhodyatsya v `Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests/test_братиславская_проекция_памяти.py`.

## Regressionnyiye scenarii

- Povtor bez izmenenij; izmeneniye odnogo Markdown-fajla; izmeneniye toljko otchyota; chistoye izmeneniye Git HEAD pri neizmennyikh soderzhateljnyikh vkhodakh.
- Dobavleniye, udaleniye i pereimenovaniye istochnika; izmeneniye rezhima; izmeneniye celevogo puti, zagolovka ili yakorya dokumenta, na kotoryij ssyilayutsya drugiye dokumentyi.
- Smena politiki, generatora, zakreplyonnoj zavisimosti, toolchain ili konfiguracii sborki; otsutstviye, usecheniye i podmena zapisi kyesha.
- Soglasovannaya podmena manifesta i celevogo fajla; lishnij vyikhod; simvolicheskaya ssyilka; kolliziya registra ili Unicode.
- Izmeneniye istochnika vo vremya chteniya; preryivaniye do i posle ustanovki pokoleniya; vosstanovleniye posle chastichnoj zapisi.
- Polnoye pobajtovoye sovpadeniye uskorennogo rezuljtata s nezavisimyim rezuljtatom bez kyesha.

## Granica tekusjhej zadachi

Komandyi poljzovatelya i soderzhateljnyiye otvetyi sokhranyayutsya v sobstvennyikh materialakh etoj zadachi. Optimizaciya generatora ostayotsya planom. Postoyannyiye pravila povedeniya i neobkhodimyiye proverki po pozdnejshemu yavnomu ukazaniyu izmenyayutsya v sobstvennoj vetke; osnovnaya vetka drugoj aktivnoj zadachi ne izmenyayetsya. Izmeneniye chisla obyazateljnyikh polnyikh prokhodov potrebuyet otdeljnogo yavnogo izmeneniya pravil s ikh validatorom; pervyij etap uskoreniya etogo ne trebuyet.

## Dopolneniya tekusjhego dialoga

[Swift-nablyudeniye macOS, dolgovremennyij zhurnal i chteniye dialoga iz JSONL](plan-nablyudeniya-macOS.md) sostavlyayut dopolniteljnyiye napravleniya tekusjhego plana. Postoyannoye zakrepleniye rezhima planirovaniya vklyuchayet vosstanovleniye tochnyikh komand iz JSONL posle szhatiya konteksta.

## Prodolzheniye posle kontroljnogo kommita

Kommit a521c41d ne zavershil soglasovannyij obyyom. Posle vyiyavleniya prezhdevremennogo zavershayusjhego otveta rabota prodolzhayetsya v toj zhe zadache.

Sleduyusjhej proveryayemoj chastjyu stal otdeljnyij otpechatok fakticheskogo kanonicheskogo soderzhimogo. Realizovannyij otpechatok sokhranyayetsya posle obyichnogo ili pustogo kommita i izmeneniya sposoba staging, ignorirovatj toljko razreshyonnyiye tekusjhij otchyot, mashinnyiye zapisi i tochnuyu oblastj Proyekcii, no menyatjsya pri soderzhateljnom izmenenii fajlov, putej, rezhima ili zakreplyonnoj zavisimosti. Prezhnij Git-otpechatok ostayotsya proverkoj neizmennosti finaljnogo snimka.

Zatem realizovanyi novaya zapisj zapuska v4 i snimok otchyota v3 s yavnoj proveryayemoj granicej migracii. Istoricheskiye v3-zapuski ne poluchayut vyimyishlennyij soderzhateljnyij otpechatok. Sokhranyonnyij staryij prefiks i yego khyeshi zasjhisjhayutsya ot izmeneniya; staryiye zakryityiye otchyotyi vosproizvodyatsya prezhnej semantikoj. Povtor polnogo zapuska na uzhe proverennom soderzhimom otklonyayetsya do zapuska dochernego processa, vklyuchaya vozvrat A → B → A.

Novyij promezhutochnyij kommit sam po sebe ne yavlyayetsya usloviyem ostanovki: neposredstvenno posle sokhraneniya zapisi sboya vyipolnyayetsya adresnyij RED/GREEN-scenarij otpechatka soderzhimogo. Etot poryadok dayot nablyudayemoye svideteljstvo prodolzheniya, no ne schitayetsya universaljnoj mashinnoj garantiyej povedeniya agenta.

## Konvejyer vnutri odnoj postoyannoj zadachi

Soobsjheniya 34–35 dobavili napravleniye [priyomki neizmenyayemogo dereva Git](plan-konvejyera-odnoj-zadachi.md), poka pozdniye komandyi sokhranyayutsya v checkout. Eto otdeljnoye izmeneniye protokola i zakryitij raundov, poka nakhodyasjheyesya v plane. Ono ne uskoryayet sam preobrazovatelj i ne menyayet zadnim chislom predmet susjhestvuyusjhikh progonov.

[Kontejner nablyudenij](plan-kontejnera-nablyudenij.md) utochnyayet sposob dolgovremennogo khraneniya Swift-nablyudatelya: JSON-zagolovki i vstroyennyiye syiryiye binarnyiye gruppyi vmesto vneshnikh krupnyikh obyyektov.

## Istochniki

- [Doslovnyiye komandyi poljzovatelya](../../zapros.md).
- [Otvetyi, resheniya i otchyot tekusjhej zadachi](../../otchyot.md).
- Kanonicheskij generator: `Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py`.
- Sborsjhik smoke-check: `Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py`, stroki 2375–2414.
- Pravila proverki i zamyikaniya: `Правила/агентов/проверки-коммит-и-публикация.md`, FUM-PRAVILO-000188 i FUM-PRAVILO-000189.
- Sokhranyonnyij otchyot zamerov: `Журнал/2026-09-07_18-16-36_MSK_принять-модель-бетонных-глубинных-систем/отчёт.md`, razdel pryamyikh zapuskov.

## Proveryayemyiye chasti perekhoda priyomochnyikh raundov

1. Primitiv soderzhateljnogo otpechatka podgotovlen i proveren otdeljno; prezhnij Git-otpechatok ne izmenyon. Posle profilya sokrasjhyon obkhod roditelej, sovpadeniye rezuljtatov podtverzhdeno na odnom vkhode.
2. Strogij chitatelj zapuska v4 i proveryayemaya granica iskhodnogo prefiksa podgotovlenyi, staryiye komandyi otklonyayut nepodderzhivayemyij format. Podgotovlen otdeljnyij plan nastoyasjhikh raundov s globaljnyim zapretom povtornoj polnoj popyitki na odnom soderzhimom i sokhraneniyem ogranichenij diagnostiki i istoricheskikh narushenij. Vse 20 testov chitatelya i plana proshli; izmerennaya mediana plana 3,543125 ms obosnovyivayet sokhraneniye pryamoj proverki bez novogo kyesha. Na etape kontroljnoj tochki 84d68a95 CLI yesjhyo sozdaval v3.
3. Podgotovlen snimok otchyota v3 i yego vosproizvedeniye iz dvukh sokhranyonnyikh otpechatkov; staryiye zakryityiye formatyi sokhranyayut bajtyi i verdikt. Proverenyi podgotovlennoye zakryitiye, aktivnaya istoriya, kontroljnaya tochka i smezhnyij chitatelj smoke-check. Profilj zakryitogo chteniya obosnoval sokhraneniye pryamoj proverki bez novogo kyesha; etot etap zafiksirovan v d5efcdbf.
4. Novaya zapisj vklyuchena pod dejstvuyusjhim zamkom: dopusk proveryayet iskhodnyij kontrakt i bazu, oba otpechatka lokalizacii i zapret povtornoj polnoj popyitki do dochernego processa. Pervoye soderzhimoye migracii isklyucheno iz polnyikh popyitok; dlya priyomki nuzhno neobkhodimoye izmeneniye posle registracii. Vse 48 adresnyikh testov i 37 regressij starogo plana/snimkov proshli. Profilj okonchateljnoj realizacii: odnokratnyij dopusk 289,483875 ms; plan 82 zapisej 4,522875 ms po mediane tryokh vyizovov. Resheniye — sokhranitj pryamuyu proverku bez kyesha. Pravilo NEW000006 i inventarj obnovlenyi; zapusk 89 podtverdil 215 pravil, zafiksiroval iskhodnyiye 88 zapisej i stal pervoj fakticheskoj v4. Posleduyusjhij zapusk 90 avtomaticheski sokhranil v4. Itogi, ogranicheniya i proiskhozhdeniye teperj vklyuchayutsya v plan i otchyot.
5. Posle zakonchennogo perekhoda vyipolnitj tekusjhuyu finaljnuyu priyomku i shtatnuyu aktualizaciyu proyekcii. Kazhdyij promezhutochnyij kommit sokhranyayet zakonchennuyu chastj, posle nego prodolzhayetsya sleduyusjhij razreshyonnyij shag.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 13:49:48 MSK -->
<!-- content-sha256: sha256:edd30d1f72355c03d52f80f4fe542eb4f5ced63c8b6ed929e265424a4889aeca -->
<!-- FUM-MD-RECENCY:END -->
