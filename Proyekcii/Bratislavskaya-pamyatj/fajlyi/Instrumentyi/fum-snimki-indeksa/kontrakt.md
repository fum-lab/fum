# Zakryitaya skhema pervogo vkhoda

Skhema `fum.вход-снимка.1` proveryayet pervyij nezavisimyij vkhod po polnomu Git tree. Ona ne realizuyet perekhodyi polnogo proyekta priyomki i ne menyayet run-v4/report-v3. Ispolnyayemoye opredeleniye — [vkhod.py](scripts/vkhod.py), strogiye bajtyi — [kanon.py](scripts/kanon.py).

Materializaciya proverennyikh syiryikh fajlov opisana otdeljnoj skhemoj [lokaljnoj kvitancii](materializaciya.md). Ona ne menyayet polya vkhoda ili zapret ispolneniya.

## Bajtyi i ssyilki

JSON kodiruyetsya UTF-8 bez BOM, odnim LF v konce, bez neznachasjhikh probelov. Klyuchi uporyadochenyi po kodovyim tochkam Unicode; normalizacii strok net. Kavyichka i obratnaya kosaya cherta ekraniruyutsya; U+0000…U+001F vsegda imeyut formu `\u0000` s chetyirjmya strochnyimi hex-ciframi. Ostaljnyiye skalyarnyiye simvolyi zapisyivayutsya neposredstvenno. Surrogatyi, povtornyiye klyuchi, aljternativnyiye escape, drobnyiye i specialjnyiye chisla, otricateljnyiye celyiye i znacheniya boljshe 2^63−1 otvergayutsya. Tip boolean susjhestvuyet v JSON, no ne prinimayetsya vmesto celogo polya.

Konvert imeyet rovno polya `алгоритм: sha256`, `длина` i `хэш_байтов`. On khyeshiruyet polnyiye kanonicheskiye bajtyi zapisi vmeste s LF i sam v nikh ne vklyuchyon. Vse `хэш_байтов` v etoj versii oznachayut SHA-256 syiryikh bajtov, bez prefiksa i so strochnyimi ciframi.

Git OID imeyet rovno polya `алгоритм` (`sha1` ili `sha256`) i `значение` (sootvetstvenno 40 ili 64 strochnyiye hex-cifryi). Format obyazan sovpadatj s repozitoriyem. Obyyekt chitayetsya po polnomu OID, zatem nezavisimo pereschityivayetsya yego Git-khyesh s zagolovkom tipa i dlinyi. Replace refs, filjtryi i zhivoj checkout ne podstavlyayut bajtyi; lazy fetch i setevyiye protokolyi zapresjhenyi.

Ssyilka na manifest ili fajl imeyet rovno `путь`, `объект`, `длина`, `хэш_байтов`. Tochnyij putj razreshayetsya v zakreplyonnom tree; OID ssyilki sravnivayetsya s fakticheskim listom. Dopustimyi obyichnyiye rezhimyi `100644` i `100755`. Tree chitayetsya iz syiryikh obyyektov; poryadok, tipyi, UTF-8-imena, kollizii registra i NFC proveryayutsya. Simvolicheskiye ssyilki otvergayutsya. Rezhim `160000` dopustim toljko kak polnostjyu opisannaya zavisimostj.

## Zapisj vkhoda

Vse polya obyazateljnyi, dopolniteljnyikh polej net:

- `версия`, `вид` — tochnyiye `fum.вход-снимка.1` i `вход`;
- `идентификатор_задачи`, `идентификатор_раунда` — kanonicheskiye lowercase UUID;
- `предыдущая_квитанция` — toljko null v etom segmente;
- `запрос`, `отчёт` — razlichnyiye tochnyiye otnositeljnyiye puti obyichnyikh fajlov dereva;
- `исходный_коммит`, `дерево_входа` — susjhestvuyusjhiye OID commit i tree;
- `исходная_ветка` — polnyij ref pod `refs/heads/`, sovpadayusjhij s ozhidayemyim ref i nablyudayemyim symbolic HEAD;
- `граница_команд`, `профиль_среды`, `план_проверок`, `политика_выхода` — ssyilki ukazannoj vyishe formyi;
- `основание_полномочий` — nepustoj massiv obyyektov `номер_сообщения`, `действия`. Nomer otnositsya k susjhestvuyusjhemu user-soobsjheniyu eksporta; dejstviya ogranichenyi `проверка_байтов` i `подготовка_дерева`;
- `зависимости` — massiv zakryityikh variantov arkhiva i gitlink.

Iskhodnyij commit sovpadayet s otdeljno ozhidayemyim i nablyudayemyim HEAD. Proverka dopuskayet drugoj tree indeksa i ne pyitayetsya poluchitj yego iz boleye pozdnego checkout. Povtornyiye nablyudeniya do i posle chteniya obnaruzhivayut nesovpadeniye; posledovateljnostj ne obyyavlyayetsya atomarnyim snimkom storonnego pisatelya.

## Vlozhennyiye skhemyi

Eksport `fum.экспорт-команд.1` imeyet polya `схема`, `идентификатор_задачи`, `сообщения`. Nepustoj massiv soobsjhenij nachinayetsya s nomera 1 i sokhranyayet posledovateljnostj bez propuskov. Polya soobsjheniya: `номер`, `роль` (`user` ili `assistant`), `текст`, `байтовая_длина`, `хэш_байтов`. Dlina i khyesh otnosyatsya k tochnomu UTF-8 tekstu. Prezhnij JSONL-kursor zakreplyayet chislo polnyikh bajtov, khyesh prefiksa, khyesh pervoj stroki session_meta i tochnyiye pozicii soobsjhenij; pereschyot podtverzhdayet vse polya kursora, vklyuchaya razlichiye boolean i integer.

Sreda `fum.среда-снимка.1` imeyet `схема`, nepustyiye `компоненты` i `ограничения`. Komponent soderzhit `имя`, `версия`, `команда`; komandyi unikaljnyi i ne soderzhat razdelitelej puti. Versii yavlyayutsya zayavlennyimi nablyudeniyami postavsjhika vkhoda, a ne dokazateljstvom fakticheskoj sredyi budusjhego ispolneniya.

Plan `fum.план-снимка.1` imeyet `схема`, nepustyiye `шаги`, `происхождение`. Shag soderzhit `номер`, `аргументы`, `класс`, `зависит_от`, `ожидаемый_исход`, `ссылки_на_инструменты`, `ссылки_на_правила`. Nomera posledovateljnyi s 1; zavisimosti unikaljnyi i otnosyatsya toljko k predyidusjhim shagam. Ozhidayemyij kod — celoye 0…255. Argumentyi peredayutsya kak dannyiye, bez shell; pervyij argument nazvan v srede. Ssyilki pravil i instrumentov nepustyi i proveryayutsya po tree. Plan nichego ne zapuskayet.

Kazhdyij uzel `происхождение` imeyet `путь`, `вид: непрозрачные_байты`, `зависит_от: []`. Otsortirovannyij po UTF-8 massiv v tochnosti pokryivayet vse listjya tree, vklyuchaya sam plan, no ne zapisyivayet sobstvennyij OID/khyesh. Neizvestnyiye polya, ryobra, ssyilki na budusjhuyu zapisj, propuski i proizvodnyiye uzlyi otvergayutsya. Eto konechnaya strukturnaya granica. Otsutstviye skryitoj soderzhateljnoj zavisimosti proizvoljnyikh bajtov ne dokazyivayetsya; rezuljtat nikogda ne razreshayet ispolneniye.

Politika `fum.выход-снимка.1` soderzhit toljko `схема` i pustyiye `результаты`. Nepustaya deljta trebuyet yesjhyo ne realizovannogo sleduyusjhego segmenta.

Arkhiv soderzhit `вид: архив`, `ссылка`. Gitlink soderzhit `вид: gitlink`, `путь`, `коммит`, `дерево`, `манифест`. Yego manifest `fum.файлы-зависимости.1` soderzhit `схема`, `файлы`; kazhdyij element — `ссылка`, `режим`. Perechenj tochno pokryivayet vse syiryiye fajlyi dependency tree v poryadke UTF-8. Vse gitlink osnovnogo dereva dolzhnyi byitj opisanyi; lishniye lokaljnyiye kartyi i povtornyiye opisaniya otvergayutsya. Nedostupnyiye obyyektyi ne zamenyayutsya rabochimi fajlami.

## Istochniki

- [Polnyij proyekt kontrakta, kotoryij yesjhyo ne obyyavlen realizovannyim](../../Zhurnal/2026-09-08_19-07-59_MSK_utochnitj-kontrakt-snimkov-indeksa/materialyi/planyi/kontrakt-snimkov-indeksa.md).
- [Iskhodnyij zapros ogranichennogo segmenta](../../Zhurnal/2026-09-09_12-51-11_MSK_realizovatj-vkhod-snimka-indeksa/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 14:41:44 MSK -->
<!-- content-sha256: sha256:2cc21703386b0f3c6985024c7f2fec63cccc270bfd21f0c1f10bfe4cf81abc82 -->
<!-- FUM-MD-RECENCY:END -->
