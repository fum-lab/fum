# Sinteticheskij snimok agentskoj zadachi

Biblioteka i CLI pervogo ogranichennogo segmenta FUM-STEP-0159. Oni vosproizvodyat zapisannyij konechnyij scenarij, sokhranyayut kazhdoye nablyudeniye i perekhod v prinyatom kontejnere i vosstanavlivayut snimok novyim ekzemplyarom ili processom. Sborsjhikov zhivyikh dannyikh zdesj net.

[Zapisannyij primer](Primeryi/pyatj-scenariyev.json) soderzhit 18 sinteticheskikh nablyudenij pyati predmetnyikh scenariyev. Yego bajtyi sveryayutsya testom s generatorom `примерСценария()`. JSON i Markdown stroyatsya iz odnogo `Снимок`; Markdown ne interpretiruyet HTML, ssyilki i razmetku iskhodnyikh svideteljstv.

## Zapusk

Iz kornya etogo vneshnego Swift-repozitoriya:

```sh
swift build --package-path Packages/СнимокАгентскойЗадачи --build-system native --jobs 2 -c release
FUM_SNAPSHOT_DIR="$(mktemp -d /private/tmp/fum-snapshot.XXXXXX)"
Packages/СнимокАгентскойЗадачи/.build/release/снимок-задачи собрать "$PWD/Packages/СнимокАгентскойЗадачи/Примеры/пять-сценариев.json" "$FUM_SNAPSHOT_DIR" json
Packages/СнимокАгентскойЗадачи/.build/release/снимок-задачи восстановить "$FUM_SNAPSHOT_DIR" синтетический-codex стенд задача-1 markdown
```

Komandyi CLI:

- `пример` — kanonicheskij JSON zapisannogo scenariya v stdout.
- `собрать <абсолютный-вход.json> <абсолютный-корень> <json|markdown>` — polnyij preflight, sokhraneniye i snimok. Povtor togo zhe scenariya ne dobavlyayet zapisi, no povtoryayet uspeshnyij fsync.
- `восстановить <абсолютный-корень> <поставщик> <хост> <ID-задачи> <json|markdown>` — toljko chteniye. Iskhodnyij scenarij ne nuzhen; ozhidayemaya identichnostj proveryayetsya po sokhranyonnyim nablyudeniyam.
- `профиль <новый-абсолютный-корень> <1..256>` — konechnaya sinteticheskaya nagruzka, chistaya sborka, zapisj, replay i 32 povtora. Korenj uzhe dolzhen susjhestvovatj i ne soderzhatj nablyudenij.

Korenj dannyikh — susjhestvuyusjhij fizicheskij katalog vladeljca bez simvolicheskikh ssyilok i gruppovoj/obsjhej zapisi. Oshibka dayot kod 2 i stderr; uspeshnyij snimok ne pechatayetsya do sokhraneniya. CLI ne chitayet okna, JSONL Codex ili sistemnyiye istochniki i ne zaprashivayet polnomochiya.

## Znacheniye snimka

Kazhdoye nablyudeniye soderzhit versiyu, ustojchivyij ID, sostavnuyu zadachu, kanal i ekzemplyar istochnika, logicheskij takt i srok, okhvat, oblastj, iskhodnyij sinteticheskij fakt i tipizirovannoye soderzhaniye. Eto yedinyiye logicheskiye chasyi scenariya, ne sinkhronizirovannyiye chasyi realjnyikh API i ne atomarnyij snimok OS.

Znaniye polya — neizvestnostj, soglasovannoye znacheniye ili protivorechiye. Svezhestj vyichislyayetsya otdeljno dlya kazhdogo kandidata: konflikt mozhet odnovremenno ustaretj. Povtor ID ne menyayet takt ili srok. Vse iskhodniki ostayutsya dostupnyi po ID, vklyuchaya zamesjhyonnyiye i proignorirovannyiye nablyudeniya.

| Pole / fakt | Dopustimyiye kanalyi i smyisl |
| --- | --- |
| Zhelayemaya modelj | Nastrojka ili interfejs; ne dokazyivayet fakticheskuyu modelj |
| Nablyudyonnaya modelj | Zhurnal ili interfejs; obyazateljnyij kontekst konkretnogo khoda |
| Runtime cwd | Zhurnal; otdeljnoye pole zadachi |
| Cwd komandyi | Komanda; obyazateljnyij ID komandyi v kontekste |
| Naznachennyij worktree | Nastrojka; zapusk komandyi v drugom cwd ne menyayet vladeniye |
| Vetka | Zhurnal ili komanda; kontekst dereva obyazatelen |
| Susjhestvovaniye, tekusjhaya rabota, ozhidaniye | Zhurnal, API ili interfejs |
| Ozhidaniye | Znacheniya: net, poljzovatelj, polnomochiya, process, drugaya-zadacha |

Modelj proshlogo khoda ne perenositsya na novyij khod i ne obyyavlyayetsya aktivnoj bez svideteljstva. Znacheniye tekusjhej rabotyi ne zakryivayet poljzovateljskoye obyazateljstvo. Polya bez svideteljstv perechislyayutsya yavno; zapros neizvestnogo konteksta vozvrasjhayet neizvestnostj.

Otsutstviye zadachi v **lyubom** spiske, dazhe obyyavlennom polnyim, oznachayet toljko «ne perechislena v etoj oblasti otveta». Dlya otricaniya susjhestvovaniya nuzhno otdeljnoye yavnoye svideteljstvo. Polozhiteljnoye svideteljstvo spiska v v1 neljzya zamenitj cherez `заменяет`; pozdneye otricaniye ostayotsya vidimyim konfliktom, pri neobkhodimosti ustarevshim.

Yavnoye zamesjheniye razresheno toljko dlya aktivnogo znacheniya togo zhe polya, konteksta, istochnika i oblasti. Raznyiye istochniki ne razreshayut konflikt poryadkom postupleniya.

## Komanda, effekt, otkaz

Namereniye, otpravka i transportnoye prinyatiye — otdeljnyiye fazyi, no ni odna ne podtverzhdayet UI-effekt. Fazyi sokhranyayut pervonachaljnyiye istochnik, oblastj, ozhidayemyij effekt i osnovaniye.

Podtverzhdeniye trebuyet boleye pozdnego svideteljstva kanala interfejsa s sovpadayusjhimi zadachej, oblastjyu, operaciyej i effektom. Korrektirovka dopolniteljno ssyilayetsya na prezhneye tipizirovannoye `расхождение` toj zhe oblasti s tem zhe ozhidayemyim rezuljtatom. Toljko posle UI-podtverzhdeniya ona stanovitsya poslednej podtverzhdyonnoj korrektirovkoj. Eto istoricheskoye podtverzhdeniye, ne obesjhaniye neizmennosti interfejsa posle nego.

Otkaz dejstvuyet na **vesj kanal**, vklyuchaya novyiye ekzemplyaryi. Posleduyusjhiye nablyudeniya etogo kanala sokhranyayutsya kak proignorirovannyiye i ne dayut novyikh znachenij ili podtverzhdenij. Prezhniye svideteljstva ostayutsya istoriyej i mogut ustarevatj. Avtomaticheskogo povtornogo polucheniya polnomochij ili obkhoda otkaza net.

Istochniki sinteticheskiye i zayavlenyi vkhodom; proverka SHA-256 obespechivayet celostnostj vosproizvedeniya, no ne autentichnostj vneshnego fakta.

## Bajtyi, identichnostj i format v1

Serializaciya — tochnyij JSON `JSONEncoder` s `sortedKeys` i `withoutEscapingSlashes`, dopustim odin zavershayusjhij LF. Eto ogranichennyij protokol, ne obsjhij RFC 8785: inoj poryadok/probelyi, neizvestnyiye i povtornyiye klyuchi, usecheniye i neizvestnaya versiya otklonyayutsya.

**Payload ne normalizuyetsya.** Iskhodnyiye UTF-8-posledovateljnosti strok, vklyuchaya NFC/NFD i `Наблюдение.задача`, sokhranyayutsya. Pobajtovoye ravenstvo serializovannogo nablyudeniya obyazateljno dlya retry; obyichnyij Swift `String ==` / `Equatable` nedostatochen. Drugoj payload s tem zhe ID — konflikt.

Toljko `Снимок.задача` ispoljzuyet yavno nazvannoye `нормализованнаяИдентичность` (NFC). Tri komponenta mashinnogo klyucha ogranichenyi do i posle preobrazovaniya: po 128 bajtov; posle nego dopustimyi Unicode-bukvyi, desyatichnyiye cifryi i `._:-`. Ostatochnyiye combining marks, emoji i podpisi interfejsa ne yavlyayutsya identifikatorami v1. Eto predotvrasjhayet neodnoznachnuyu obrabotku patologicheskikh combining-posledovateljnostej; ne menyayet iskhodnyij payload. Kirillicheskij NFC/NFD-klyuch proveryayetsya otdeljnyim testom; sokhraneniye NFD-payload — processnyim replay.

Predelyi: 256 nablyudenij, 4 MiB vkhoda, glubina JSON 12, 16 KiB nablyudeniya, 32 KiB kontejnernogo obyyekta, 8 ekzemplyarov istochnikov, 64 paryi pole/kontekst, 16 UI-operacij, do 16 ssyilok zamesjheniya; obyichnaya stroka do 1024 bajtov, iskhodnyij fakt do 8192. Strukturnyiye i skalyarnyiye proverki idut do promezhutochnogo kodirovaniya nablyudeniya.

Pri otkryitii susjhestvuyusjhego fajla kontejner snachala skaniruyet yego po sobstvennyim prinyatyim predelam (256 MiB segmenta, 4096 zapisej). Lishj zatem obolochka primenyayet menjshiye predelyi snimka. Eto ne obesjhaniye skanirovaniya proizvoljnogo chuzhogo kontejnera v predelakh 4 MiB vkhoda. Diagnosticheskoye chteniye profilya imeyet otdeljnyij cap 16 MiB.

## Khraneniye i strogaya Concurrency

Aktor yedinolichno vladeyet sinkhronnyim non-Sendable kontejnerom. Mezhdu redukciyej, zapisjyu i publikaciyej snimka net `await`; kontejner naruzhu ne peredayotsya, `unchecked Sendable` otsutstvuyet.

Na sobyitiye prikhoditsya odin atomarnyij obyyekt: iskhodnoye nablyudeniye, versiya reduktora, nomer perekhoda i SHA-256 snimkov do/posle. Replay vyichislyayet perekhod zanovo i pobajtovo sveryayet metadannyiye i konvert. Khyesh do sleduyusjhego perekhoda povtorno ispoljzuyetsya toljko iz uzhe vyichislennogo i proverennogo predyidusjhego khyesha posle.

Povtor ID raspoznayotsya do redukcii i povtoryayet uspeshnuyu sinkhronizaciyu iskhodnyikh bajtov. Posle neopredelyonnoj oshibki zapisi aktor trebuyet zakryitiya/replay; vidimostj zapisi na diske sama po sebe ne dayot uspeshnogo ack. Otkaz rezhima toljko chteniya ne povrezhdayet vozmozhnostj chteniya.

Scenarij predvariteljno proveryayetsya celikom, no atomarnostj sokhranyayetsya **po sobyitiyu**, ne po vsemu scenariyu: I/O-sboj mozhet ostavitj podtverzhdyonnyij prefiks. Nepolnyij khvost, povrezhdeniye, chuzhaya identichnostj, neizvestnaya versiya ili nevernyij perekhod dayut otkaz; avtomaticheskogo remonta i migracii net.

## Proverki i profilj

`swift test --package-path Packages/СнимокАгентскойЗадачи --build-system native --jobs 2`

Na stende Apple Swift 6.4, yazyikovoj rezhim Swift 6, macOS arm64. Native backend — vremennaya granica stenda iz-za kodovoj podpisi kirillicheskogo XCTest bundle v drugom backend; SwiftPM soobsjhayet yego deprecated-status.

Profilj na 256 nablyudeniyakh do ogranichennogo povtornogo ispoljzovaniya proverennogo khyesha: chistaya sborka okolo 20 ms, zapisj 1,11–1,14 s, replay 1,06–1,09 s. Posle — zapisj okolo 0,65 s, replay 0,58–0,59 s. Vkhod 297121 bajt, kontejner 597922 bajta, 32 povtora dayut nulevoj prirost; SHA-256 snimka i fajla sovpadayut do/posle. Profilj lokaljnyij, bez SLA i bez dokazateljstva kholodnogo diskovogo kyesha. Finaljnyiye zapisi i khyeshi iskhodnikov peredayutsya v otdeljnom FUM Zhurnale.

Prinyatyij paket `КонтейнерНаблюдений` ne izmenyon. Novyij ekzemplyar i process ne dokazyivayut ustojchivostj k perezapusku OS ili potere pitaniya. Polnyiye FUM-STEP-0159, FUM-STEP-0156 i FUM-REQ-0044 etim sinteticheskim segmentom ne zakryivayutsya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:36:01 MSK -->
<!-- content-sha256: sha256:fce55f96f7b32ae03d22d4d19f9213042fcc994bb2f92c2d98493fb04cbe7034 -->
<!-- FUM-MD-RECENCY:END -->
