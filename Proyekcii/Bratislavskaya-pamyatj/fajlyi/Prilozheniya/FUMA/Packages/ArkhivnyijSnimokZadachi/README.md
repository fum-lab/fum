# Arkhivnyij snimok zadachi

Swift-adapter yavno ukazannogo Codex JSONL k dolgovechnomu snimku odnoj zapisannoj zadachi. Rezuljtat imeyet chastichnyij okhvat: **po sostoyaniyu prochitannogo prefiksa**. Kod i otkryityiye fiksturyi predostavlyayutsya pod CC0 1.0 Universal.

Iz kornya Swift-repozitoriya:

```sh
swift test --package-path Packages/АрхивныйСнимокЗадачи --build-system native --jobs 2
mkdir -p .build/архив-задачи
swift run --package-path Packages/АрхивныйСнимокЗадачи --build-system native --jobs 2 архивный-снимок импорт Packages/АрхивныйСнимокЗадачи/Примеры/записанный-префикс.jsonl .build/архив-задачи 11111111-1111-4111-8111-111111111111
swift run --package-path Packages/АрхивныйСнимокЗадачи --build-system native --jobs 2 архивный-снимок replay .build/архив-задачи 11111111-1111-4111-8111-111111111111 --markdown
```

UUID v primere prinadlezhit otkryitoj fiksture. Dlya realjnogo istochnika ozhidayemyij UUID zadayotsya yavno. Katalog kontejnera dolzhen susjhestvovatj. Oshibka ne pechatayet iskhodnuyu stroku ili argumentyi. Prilozheniye ne isjhet sessii avtomaticheski, ne chitayet UI, Accessibility, ScreenCapture i ne sokhranyayet dialog, instrukcii, argumentyi libo vyivod instrumentov.

## Podderzhannaya forma

UTF-8 JSONL, zaversheniye stroki — LF (CR pered LF dopustim kak probel JSON). Pervaya zavershyonnaya stroka — yedinstvennaya `session_meta`, `payload.id` — lowercase UUID. Verkhniye klyuchi: `type`, `timestamp`, `payload`, `ordinal`, `metadata`. Podderzhannyiye verkhniye tipyi: `session_meta`, `turn_context`, `event_msg`, `response_item`, `compacted`, `world_state`, `token_usage_record`, `inter_agent_communication_metadata`. Dubli dekodirovannyikh klyuchej, neizvestnaya verkhnyaya forma i nevernaya polnaya stroka otklonyayutsya. Versiya CLI sama po sebe ne dokazyivayet podderzhku formata.

`type` i obyyekt `payload` obyazateljnyi dlya vsekh vosjmi tipov. `timestamp`, `ordinal` i `metadata` neobyazateljnyi dlya sovmestimosti s prezhnimi istochnikami. Prisutstvuyusjhij `timestamp` — nepustaya stroka do 128 bajtov UTF-8 bez upravlyayusjhikh simvolov; `metadata` — obyyekt. `ordinal` proveryayetsya po iskhodnoj JSON-lekseme: desyatichnoye celoye ot 0 do Int64.max bez znaka, drobi, eksponentyi i vedusjhego nulya, krome samogo `0`. Bool, null i strokovaya zapisj chisla otklonyayutsya. Povtornyiye ili ubyivayusjhiye znacheniya razreshenyi: eto neprozrachnaya annotaciya, ne schyotchik LF, identichnostj ili poryadok polnomochij.

`world_state`, `token_usage_record`, `inter_agent_communication_metadata` i verkhniye `ordinal`/`metadata` uchastvuyut toljko v bajtovoj granice i SHA iskhodnogo prefiksa. Iz nikh ne vyibirayutsya `cwd`, modelj, khod, chelovecheskiye polnomochiya ili zhivoj status, dazhe yesli sootvetstvuyusjhiye polya vstrechayutsya v payload. Vlozhennyiye obyyektyi prokhodyat prezhniye byudzhetyi i proverku povtornyikh klyuchej. Proizvoljnyiye novyiye verkhniye klyuchi i tipyi po-prezhnemu otklonyayutsya.

Iz `session_meta` berutsya identichnostj i neobyazateljnyij `cwd`; iz `turn_context` — obyazateljnyij `turn_id`, neobyazateljnyiye `cwd` i `model`. `event_msg` s yavnyim `turn_id` menyayet toljko identichnostj poslednego khoda. Sravneniye identifikatorov pobajtovoye. Modelj sbrasyivayetsya pri smene khoda; otsutstviye modeli v `turn_context` takzhe sbrasyivayet yeyo. Nepodderzhannyiye polya vnutri izvestnyikh payload uchityivayutsya lishj kak bajtyi prefiksa. Oni ne sozdayut dopolniteljnyiye faktyi.

Poslednij khod oznachayet poslednij khod, yavno identificirovannyij podderzhannyimi `turn_context` ili `event_msg`; chuzhoj `turn_id` vnutri nejtraljnogo tipa ne menyayet etu proyekciyu. Susjhestvovaniye oznachayet nalichiye zapisi sessii. Zaversheniye zadachi, vyipolneniye obyazateljstv, ozhidaniye cheloveka, aktivnostj processa, naznachennoye rabocheye derevo i UI-effektyi neizvestnyi. EOF, tishina, final-otvet i HookPrompt etikh sostoyanij ne dokazyivayut.

## Arkhivnyij kontrakt versii 1

Otdeljnyij kontejnernyij tip `архивный-снимок-задачи/завершённый-префикс` ispoljzuyet publichnyiye `Редуктор`, `Наблюдение` i `Сегмент`; sinteticheskoye khranilisjhe iskhodnogo paketa ne ispoljzuyetsya. Oba iskhodnyikh paketa ostayutsya bez izmenenij na baze `dd172958b0128cba73361eeac136e8bc66190230`.

Odin obyyekt soderzhit versiyu adaptera, ozhidayemyij UUID, identichnostj i poziciyu/SHA iskhodnoj `session_meta`, bajtovuyu i strochnuyu granicu i SHA zavershyonnogo prefiksa, vyibrannyiye faktyi s poziciyami/SHA iskhodnyikh strok, ne boleye tryokh publichnyikh nablyudenij, SHA snimka i SHA predyidusjhego obyyekta. SHA stroki vklyuchayet LF. Syiryiye stroki otsutstvuyut. Kursor ne susjhestvuyet otdeljno ot dannyikh.

Import podtverzhdayetsya posle fsync fajla i kataloga. Povtor tochnogo prefiksa povtoryayet sinkhronizaciyu bez rosta. Lyuboye dopolneniye zavershyonnyimi strokami sozdayot sleduyusjhij obyyekt. Nepolnyij khvost — vklyuchaya korrektnyij JSON bez LF i nepolnyij UTF-8 — ne vkhodit v kursor. Podmena prinyatogo prefiksa zakryivayet prodolzheniye.

Replay proveryayet skhemu, kanonicheskiye bajtyi, identichnostj, pozicii, perekhodyi faktov i SHA snimka, iskhodnik yemu ne nuzhen. Novyij import perechityivayet prezhnij prefiks i sveryayet SHA. Povtornyij JSON-razbor uzhe prinyatoj chasti propuskayetsya; `полныйРазбор: true` sokhranyayet etalon dlya sravneniya. Vremena taktov yavlyayutsya logicheskoj poziciyej prefiksa.

Replay takzhe proveryayet vyipolnimostj promezhutkov mezhdu vyibrannyimi strokami, prezhnej granicej i konechnyim kursorom. Odno chislo zavershyonnyikh strok sootvetstvuyet odnomu bajtovomu smesjheniyu; na kazhduyu propusjhennuyu stroku trebuyetsya ot 34 bajtov do limita stroki, vklyuchaya LF. Pervaya `session_meta` s UUID trebuyet minimum 80 bajtov. Minimumyi otnosyatsya k podderzhannyim JSON-formam; probelyi pered LF pozvolyayut zapolnitj dopustimyiye intervalyi. Eto proverka vnutrennej geometrii, a ne vosstanovleniye iskhodnyikh strok ili dokazateljstvo ikh podlinnosti po SHA.

Dobavleniye neobyazateljnyikh obolochek ne menyayet sokhranyonnuyu skhemu 1 i semantiku prezhnikh pyati tipov. Prezhniye kontejnernyiye bajtyi ne perepisyivayutsya; dopolneniye novyimi nejtraljnyimi strokami i replay proverenyi sinteticheski. Minimumyi 34/80 sokhranyayutsya, poskoljku prezhniye minimaljnyiye formyi ostayutsya dopustimyimi. Yesli budusjhaya versiya nachnyot vyibiratj faktyi iz prezhnikh nejtraljnyikh zapisej, sovmestimostj potrebuyet otdeljnogo resheniya o versii i polnom razbore.

Posle I/O-oshibki ekzemplyar stanovitsya nedostupnyim. Povtornoye otkryitiye vosstanavlivayet vidimyiye zavershyonnyiye obyyektyi, no novyij import obyazan povtorno podtverditj fsync. Nepolnyij kontejnernyij khvost zapresjhayet obyichnoye otkryitiye. Yavnyij API `восстановитьХвост: true` snachala proveryayet identichnostj i semantiku vsekh zavershyonnyikh obyyektov, zatem razreshayet kontejneru udalitj dokazannyij nezavershyonnyij khvost. CLI etu operaciyu ne vyipolnyayet avtomaticheski.

## Byudzhetyi

Istochnik do 256 MiB; stroka do 8 MiB; do 1 000 000 strok, glubina JSON 32, do 65 536 uzlov stroki i 4096 klyuchej odnogo obyyekta. Chitayemyij blok — 256 KiB. Arkhiv — do 1024 obyyektov po 64 KiB. Byudzhetyi mozhno umenjshitj. Cwd ogranichen 1024 bajtami, modelj i identichnostj khoda — 128. Vse ogranicheniya proveryayutsya do sokhraneniya.

Polnyij iskhodnik ne zagruzhayetsya v pamyatj. Dekodiruyetsya odna ogranichennaya stroka; neprofiljnyiye payload susjhestvuyut lishj vo vremennoj pamyati razbora. Fajl dolzhen ostavatjsya stabiljnyim na vremya odnogo vyizova: izmeneniye obnaruzhennyikh razmera/metadannyikh ili zamena inode dayut otkaz. Simvolicheskiye ssyilki i NUL v puti zapresjhenyi. Zasjhita ot vrazhdebnoj soglasovannoj podmenyi vsekh fajlov lokaljnyim poljzovatelem ne obesjhayetsya.

## Proverki i profilj

Otkryityiye XCTest-fiksturyi pokryivayut identichnostj, predelyi, nepolnyiye khvostyi, Unicode, podmenu, povtoryi, replay, lozhnoye zaversheniye, modelj khoda, ENOSPC, nulevoj write, fsync fajla i kataloga i SIGKILL do/posle dolgovechnoj zapisi. Dopolniteljnyij ispolnyayemyij target `АварийнаяФикстура` generiruyet toljko izvestnyij sinteticheskij istochnik; on otdelyon ot komandyi importa.

Profilj sozdayot novyij katalog i determinirovannyij istochnik, sravnivayet pervyij import, polnyij povtor, povtor s propuskom razbora i replay bez iskhodnika. V profile iskhodnik udalyayetsya posle otkryitiya arkhiva, pered vyidachej vosstanovlennogo snimka. Otkryitiye arkhiva pri uzhe otsutstvuyusjhem iskhodnike otdeljno podtverzhdayetsya XCTest. Katalog dolzhen otsutstvovatj do zapuska.

```sh
swift run -c release --package-path Packages/АрхивныйСнимокЗадачи --build-system native --jobs 2 профиль-архивного-снимка .build/новый-профиль-105МБ 105000000
```

Po umolchaniyu maksimaljnaya stroka profilya — 3 326 896 bajtov. Novyij yavnyij rezhim dobavlyayet `ordinal`/`metadata` i chereduyet tri sluzhebnyikh tipa, ogranichivaya stroku 256 KiB, poetomu vse tri tipa prokhodyat i na 1 MB:

```sh
swift run -c release --package-path Packages/АрхивныйСнимокЗадачи --build-system native --jobs 2 профиль-архивного-снимка .build/новый-профиль-оболочек-1МБ 1000000 --служебные-оболочки
```

Eto sinteticheskaya proverka podderzhannyikh obolochek, a ne vosproizvedeniye soderzhimogo realjnogo istochnika. JSON otdelyayet chteniye/khyeshirovaniye, razbor, redukciyu, zapisj, oba fsync, replay i povtor. `ru_maxrss` — nakoplennyij pik vsego processa v bajtakh macOS, vklyuchaya sozdaniye fiksturyi. Kyeshi fajlovoj sistemyi ne ochisjhayutsya; okhvatyivayusjhiye vremena ne skladyivayutsya s vlozhennyimi. Rezuljtatyi chetyiryokh rezhimov sravnivayutsya cherez `Equatable`; SHA snimkov vyivodyatsya otdeljno. Eto ne proverka pobajtovogo ravenstva kanonicheski zakodirovannogo polnogo rezuljtata.

Nablyudayemaya sreda postavki: Apple Swift 6.4 (swiftlang-6.4.0.30.4), Swift 6, macOS arm64. Standartnyij `swiftbuild` otkazal na CodeSign do predmetnogo RED. Shtatnyij `native` vyipolnil testyi; Trust i podpisj ne otklyuchalisj. Native otmechen toolchain kak deprecated; budusjhiye versii trebuyut proverki podgotovki.

## Prodolzheniye

Postavka proverena toljko otkryitoj sintetikoj. Koordinator soobsjhil ob otkaze prezhnego adaptera na zakreplyonnom realjnom prefikse i peredal toljko strukturu obolochek. Novyij etap podderzhivayet ukazannyiye formyi na sintetike; uspeshnyij povtor realjnogo importa yesjhyo ne podtverzhdyon. Ostaljnyiye formyi runtime i dokazateljstvo live-sostoyaniya trebuyut otdeljnoj priyomki. Na stabiljnom statisticheskom kommite `85dccce282821a890e5e65539b4f22b895b52887` obsjhij bajtovyij reader ne vyidelen: `прочитатьПрефикс` vozvrasjhayet statisticheskiye sobyitiya. Etot adapter sokhranyayet otdeljnuyu granicu chteniya i ne importiruyet statisticheskuyu semantiku ili nezakommichennyiye bajtyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 18:09:31 MSK -->
<!-- content-sha256: sha256:6043877242a829b7a38d8ea4a70957d204abd71190a8969bf0e47549b30bfd28 -->
<!-- FUM-MD-RECENCY:END -->
