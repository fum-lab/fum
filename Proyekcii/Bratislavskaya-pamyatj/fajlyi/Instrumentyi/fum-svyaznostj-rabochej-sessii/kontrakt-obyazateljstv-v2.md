# Kontrakt sokhranyonnyikh obyazateljstv v2

Reyestr sokhranyayet iskhodnyiye rezuljtatyi mezhdu etapami odnoj zadachi. Rabotyi etapa obyyasnyayut sleduyusjhij shag, no ne opredelyayut polnyij ostatok. Proverka chitayet realjnyij Git i obyichnyiye lokaljnyiye fajlyi, ne pishet checkout, indeks, refs ili zhurnalyi.

## Vkhodnyiye skhemyi

Fiksirovannyij putj reyestra — `Планирование/задачи/<корневой-UUID>/обязательства.json`. Tochnyiye polya:

- `схема`: `fum.обязательства-задачи.2`;
- `задача`: kanonicheskij UUID, sovpadayusjhij s `--codex-thread-id`;
- `исходный_коммит`: polnyij dostizhimyij OID kommita do pervogo poyavleniya reyestra, predok kazhdogo yego pervogo vvedeniya;
- `план_этапа`: kanonicheskij otnositeljnyij putj JSON-plana;
- `обязательства`: nepustoj spisok obyyektov.

Obyazateljstvo soderzhit rovno `идентификатор`, `родитель` (null libo izvestnyij ID), `основание`, `вид_результата` (`реализация` ili `документ`), `карточка` (null libo `FUM-STEP-NNNN`), `приёмки`. Identifikatoryi unikaljnyi; ciklyi zapresjhenyi. Osnovaniye soderzhit rovno `коммит`, `запрос`, `цитата`: polnyij OID predshestvuyet vvedeniyu obyazateljstva, obyichnyij fajl `Журнал/<временной-префикс>/запрос.md` susjhestvuyet imenno v etom kommite, citata nakhoditsya v yego yedinstvennom doslovnom razdele i prinadlezhit toj zhe kornevoj zadache.

Kazhdaya priyomka soderzhit rovno `запрос`, `запуск`, `результаты`. Zapros ukazyivayet na lokaljnuyu zakryituyu istoriyu; zapusk — kanonicheskij UUID uspeshnoj zapisi `fum.test-run.v4`; rezuljtatyi — nepustoj spisok obyyektov s tochnyimi polyami `путь`, `sha256`. Khyesh — 64 strochnyiye shestnadcaterichnyiye cifryi bez prefiksa. Povtornyiye paryi zapros/UUID i povtornyiye puti, vklyuchaya registrovyiye i normalizacionnyiye dublikatyi, zapresjhenyi.

Plan `fum.продолжение-задачи.2` soderzhit rovno `схема`, `задача`, `режим`, `остановка`, `работы`. Rezhim — `постоянная` ili `разовая`; dlya v2 eto ne menyayet trebovaniya dokazateljstv. Rabota soderzhit rovno `идентификатор`, `обязательство`, `действие`, `состояние`, `основание`, `свидетельство`. Sostoyaniya — `доступна`, `ожидает-ответа`, `завершена`; dostupnaya rabota imeyet null-svideteljstvo, ostaljnyiye — nepustoye. Osnovaniye rabotyi soderzhit `запрос` i `цитата` iz tekusjhego lokaljnogo pervichnogo istochnika. Neizvestnyiye polya i povtornyiye klyuchi JSON zakryivayut proverku otkazom.

## Istoriya i rezuljtat

Iskhodnaya baza i opredeleniya obyazateljstv neizmenyayemyi; dopustimyi toljko novyiye obyazateljstva i dobavochnyiye priyomki. Proveryayetsya kazhdaya vershina i kazhdyij roditelj dostizhimogo DAG. Udaleniye s vosstanovleniyem, novyij genesis, poterya vtorogo roditelya pri merge i konflikt odnogo ID ne skryivayutsya tekusjhim khoroshim fajlom. Novyij rabochij reyestr mozhet dobavlyatj yesjhyo ne zakommichennuyu kartochku: eto nezavershyonnyij ostatok, a ne oshibka zaversheniya.

Kartochki chitayutsya iz HEAD s tochnyim TOML `schema_version`, `card_id`, `status` i sootvetstvuyusjhim imenem. Dlya pogasheniya obyazateljstva s kartochkoj nuzhen status `completed` i sobstvennaya priyomka. Rebyonok ne zakryivayet roditelya; roditelj mozhet ne imetj kartochki. Prinyatiye dokumenta ne podtverzhdayet `реализация`: nuzhen khotya byi odin obyichnyij iskhodnik podderzhannogo yazyika vne dokumentacionnyikh i zhurnaljnyikh oblastej. Eto formaljnyij filjtr, a ne dokazateljstvo poleznosti koda.

Priyomka proveryayetsya po kanonicheskim bajtam zakryitogo snimka `fum.test-run-report.v3`, tochnyim khyeshirovannyim bajtam vsekh zapisej i tochnomu Markdown-bloku otchyota. Chistyij plan raundov dolzhen byitj `готов`; odin uspeshnyij UUID v nezavershyonnoj istorii nedostatochen. S pervogo poyavleniya snimka vesj zakryityij nabor, vklyuchaya otchyot, ostayotsya neizmennyim vo vsekh dostizhimyikh kommitakh i na diske. Soglasovannaya perepisj JSON i otchyota tozhe otklonyayetsya.

Proverka nakhodit dostizhimyij kommit s toj zhe priyomkoj v reyestre i tem zhe zakryityim naborom, zatem vosstanavlivayet yego soderzhateljnyij v4-otpechatok neposredstvenno iz Git-obyyektov. Tak dokazyivayetsya svyazj predkommitnogo zapuska s fakticheskim prinyatyim soderzhimyim, bez trebovaniya oshibochnogo ravenstva starogo HEAD otpechatka novomu HEAD posle commit. Isklyucheniya iz otpechatka tochno povtoryayut v4: tekusjhij otchyot, yego katalog zapuskov i `Proyekcii/**`.

Vse istoricheskiye priyomki dolzhnyi byitj dostovernyi. Dlya tekusjhego pogasheniya dostatochno odnoj, chji zayavlennyiye rezuljtatyi sovpadayut s HEAD i obyichnyimi fajlami na diske. Zakonnoye izmeneniye koda trebuyet dobavochnoj priyomki novogo etapa; staraya sokhranyayetsya kak istoriya. Neljzya schitatj dejstviteljnoj staruyu priyomku izmenyonnogo rezuljtata. Podmena rabochego fajla dazhe s `assume-unchanged` obnaruzhivayetsya pryamyim chteniyem. Pered otvetom povtorno sveryayutsya HEAD i prochitannyiye rabochiye bajtyi/rezhimyi.

## Resheniye dlya Stop

Shtatnyij stdout — odin JSON-obyyekt `fum.решение-продолжения.2` s polyami `задача`, `решение`, `следующая_работа`, `ожидающие_работы`, `незавершённые_обязательства`, `HEAD`, `доказательства`, `вид_коммита`. Dokazateljstva otobrazhayut ID obyazateljstva v spisok OID aktualjnyikh priyomochnyikh kommitov. Vid kommita — null, `контрольный` ili `итоговый-этапа`; eto kontekst, ne polnomochiye zaversheniya.

- `продолжить`: yestj dostupnaya rabota libo nepogashennoye obyazateljstvo. Yesli etap ne pokryivayet ostatok, `следующая_работа` mozhet byitj null: trebuyetsya vosstanovitj plan, a ne zavershatj.
- `ожидать-ответа`: net dostupnoj nezavisimoj rabotyi, vse nepogashennyiye obyazateljstva yavno pokryityi ozhidayusjhimi rabotami. Spisok ozhidayusjhikh nepustoj; svobodnyij tekst prichinyi trebuyet smyislovoj proverki kornya.
- `завершить`: oba spiska ostatka i ozhidaniya pustyi; reyestr i tekusjhij plan tochno sokhranenyi v HEAD, rezuljtatyi i kartochki sovpadayut s diskom.
- `остановлено-пользователем`: proverena samostoyateljnaya komanda ostanovitjsya. Zdesj `HEAD` i `доказательства` mogut otsutstvovatj, pustoj ostatok oznachayet prioritet komandyi, a ne pogasheniye reyestra.

Ostanovka soderzhit `запрос` i `цитата`. Prinimayetsya celyij doslovnyij `text`-blok v posledovateljnosti toljko takikh blokov bez vneshnej prozyi, libo vesj razdel iskhodnogo teksta bez ograd. Okruzhayusjhij tekst, primer vnutri soobsjheniya i proizvoljnyij abzac ne otbrasyivayutsya radi sovpadeniya. Podderzhivayetsya konechnyij nabor odnoznachnyikh komand vrode `Остановись.`, `Останови задачу.`, `Stop the task.`; drugiye formulirovki trebuyut yavnogo utochneniya, a ne ugadyivaniya. Posle chteniya ukazatelya plana komanda primenyayetsya do proverki istorii i ostatka, v tom chisle pri pustom perechne rabot.

S `--перед-завершением` prodolzheniye dayot exit 3, ostaljnyiye shtatnyiye resheniya — exit 0. Bez flaga lyuboye shtatnoye resheniye dayot 0. Oshibka vkhodov ili dokazateljstv dayot exit 2, pustoj stdout i stderr `ошибка: …`. Yesli rezuljtatyi prinyatyi, no plan ili reyestr ne sovpadayet s HEAD, eto oshibka dokazateljstva zaversheniya s ukazaniyem sveritj i zafiksirovatj granicu; sochetaniye `продолжить`, null-sleduyusjhego punkta i pustogo ostatka ne vyidayotsya. `--профиль` dobavlyayet toljko v stderr `FUM-PROFILE` s monotonnyim vremenem i stadiyami; yego sboj ne prevrasjhayet prodolzheniye v uspekh.

## Granicyi i vosproizvedeniye

V2 ne udostoveryayet vneshnyuyu Swift-realizaciyu po kopii otchyota, nazvaniyu puti ili obesjhaniyu. Otdeljnyij vneshnij repozitorij/OID trebuyet novogo versionirovannogo kontrakta; takoye obyazateljstvo zdesj ostayotsya otkryityim. Gitlink pri vosstanovlenii vkhodnogo otpechatka trebuyet dostupnyikh lokaljnyikh obyyektov tochnogo OID. Vlozhennyiye gitlink i simvolicheskiye vkhodyi ne podderzhanyi i otklonyayutsya. Git khranit toljko ispolnyayemyij bit: vosstanavlivayutsya kanonicheskiye rezhimyi 0644/0755; priyomka nestandartnyikh POSIX-rezhimov mozhet byitj bezopasno otklonena.

Shallow-istoriya i grafts otklonyayutsya, replace-obyyektyi i peremennyiye pereadresacii Git ne ispoljzuyutsya. Mezhprocessnogo globaljnogo zamka net: povtornoye chteniye umenjshayet okno gonki, no ne yavlyayetsya atomarnoj fajlovoj tranzakciyej. Smyislovaya polnota rezuljtatov, iskhodnogo reyestra i testov, a takzhe nezavisimaya podlinnostj fakta zapuska ne dokazyivayutsya samosoglasovannyimi fajlami repozitoriya. Eti granicyi neljzya predstavlyatj kak universaljnyij perekhvat zaversheniya Codex.

Profilj vosproizvoditsya cherez obyazateljnuyu otchyotnuyu obyortku vyizovom `python3 Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_обязательств.py --вывод <локальный-JSON>`. Po umolchaniyu — 100 kommitov etapa, 40 nezavershyonnyikh obyazateljstv libo odna zakryitaya priyomka, tri nezavisimyikh zapuska CLI kazhdogo sluchaya. Sokhranyayutsya khyeshi ispolnyayemogo koda i fiksturyi, versii Python/Git i syiryiye zameryi. Kyesh dejstvuyet toljko v predelakh vyizova: odinakovyiye roditeljskiye Git-derevjya chitayutsya odin raz, polnyij DAG i rezhimyi sokhranyayutsya.

## Istochnik i proverochnyij kontur

- [Iskhodnyij zapros i otchyot realizacii](../../Zhurnal/2026-09-09_11-52-29_MSK_zasjhititj-sokhranyonnyiye-obyazateljstva-zadachi/zapros.md).
- [Lokaljnyij navyik](SKILL.md), [proverka v2](scripts/obyazateljstva_zadachi.py), [regressii](tests/test_obyazateljstva_zadachi.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 12:53:23 MSK -->
<!-- content-sha256: sha256:af10254f56915c0869dffac5ce01a45339f968706eb09632f05cbf727340420d -->
<!-- FUM-MD-RECENCY:END -->
