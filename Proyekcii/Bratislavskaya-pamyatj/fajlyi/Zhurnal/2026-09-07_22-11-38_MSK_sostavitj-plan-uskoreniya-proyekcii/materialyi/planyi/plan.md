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

## Istochniki

- [Doslovnyiye komandyi poljzovatelya](../../zapros.md).
- [Otvetyi, resheniya i otchyot tekusjhej zadachi](../../otchyot.md).
- Kanonicheskij generator: `Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py`.
- Sborsjhik smoke-check: `Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py`, stroki 2375–2414.
- Pravila proverki i zamyikaniya: `Правила/агентов/проверки-коммит-и-публикация.md`, FUM-PRAVILO-000188 i FUM-PRAVILO-000189.
- Sokhranyonnyij otchyot zamerov: `Журнал/2026-09-07_18-16-36_MSK_принять-модель-бетонных-глубинных-систем/отчёт.md`, razdel pryamyikh zapuskov.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 23:46:15 MSK -->
<!-- content-sha256: sha256:86cdf04d83d3b0c9f89bffe6f1517084cfd9a5584bca08c2c3bbf587cd3c91f7 -->
<!-- FUM-MD-RECENCY:END -->
