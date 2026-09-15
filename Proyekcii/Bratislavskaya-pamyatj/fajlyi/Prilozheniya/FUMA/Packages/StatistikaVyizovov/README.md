# Statistika vyizovov po zapisannomu JSONL

Pervyij ogranichennyij Swift-adapter zavershyonnogo prefiksa Codex JSONL: potokovoye chteniye, proveryayemoye proiskhozhdeniye, dolgovechnoye nakopleniye i JSON/Markdown-otchyot. 35 adresnyikh testov, otdeljnyiye processyi CLI i publichnyiye profili. Prinyatyiye paketyi kontejnera i snimka ne izmenenyi. macOS 14+, Swift 6; provereno Apple Swift 6.4 na arm64.

## Zapusk

Vyikhod — susjhestvuyusjhij fizicheskij katalog vne obyichnogo, linked-worktree i bare Git-repozitoriya, prinadlezhasjhij poljzovatelyu i bez gruppovoj/obsjhej zapisi. Kontejner ne sleduyet simvolicheskim ssyilkam. Primer iz kataloga paketa sozdayot toljko publichnuyu sintetiku:

```sh
swift build --build-system native --jobs 2 -c release
mkdir -m 700 /private/tmp/профиль-статистики
.build/release/статистика-вызовов профиль --выход /private/tmp/профиль-статистики --размер малый
.build/release/статистика-вызовов импорт --вход /private/tmp/профиль-статистики/публичная-фикстура.jsonl --выход /private/tmp/профиль-статистики/контейнер --задача 11111111-1111-4111-8111-111111111111
.build/release/статистика-вызовов отчёт --выход /private/tmp/профиль-статистики/контейнер --задача 11111111-1111-4111-8111-111111111111 --формат markdown
```

Dlya kazhdogo profilya nuzhen novyij pustoj katalog: razmeryi `малый`, `большой`, `рабочий`. CLI ne isjhet zadachi, katalogi zhurnalov ili zhivyiye API. `импорт` trebuyet yavnogo absolyutnogo vkhoda, vyikhoda i lowercase UUID; `отчёт` chitayet toljko kontejner i ne trebuyet iskhodnogo fajla. JSON po umolchaniyu libo `--формат markdown`. Neizvestnyiye/povtornyiye flagi otklonyayutsya. Kod 2 — otkaz s konechnoj diagnostikoj bez iskhodnyikh argumentov/soderzhimogo; kod 0 podtverzhdayet toljko prinyatyij zavershyonnyij prefiks, ne vesj fajl ili okonchaniye zadachi.

## Vyibrannyij kontrakt

Pervaya zavershyonnaya stroka obyazana byitj `session_meta` s tem zhe `payload.id`; povtornaya metainformaciya ne mozhet smenitj UUID. Kontrakt `fum.codex-jsonl-вызовы.1` vyibirayet toljko `response_item` s `function_call`, `custom_tool_call`, `function_call_output`, `custom_tool_call_output`. Polya vneshnego JSON sokhranyayut yego napisaniye; `sha256` sokhranyayetsya kak tochnoye pole uzhe versionirovannoj modeli.

Stroka zavershayetsya LF. Poluotkryityij diapazon [nachalo, konec), individualjnyij SHA-256 i podtverzhdyonnyij SHA vsego prefiksa vklyuchayut LF. CRLF imeyet sobstvennyiye tochnyiye bajtyi. BOM, pustaya/nevernaya zavershyonnaya stroka, nevernyij UTF-8, povtornyij klyuch posle JSON-unescape i chrezmernaya vlozhennostj otklonyayutsya, vklyuchaya nerelevantnyiye stroki novogo prefiksa. Nedopisannyij khvost vozvrasjhayetsya bez ozhidaniya i ne prodvigayet granicu.

Sokhranyayutsya toljko semejstvo, napravleniye, ogranichennyiye call_id/imya, kachestvo i chislovoye vremya, nomer/bajtovyij diapazon/khyesh stroki i kontrakt. Sistemnyiye soobsjheniya, reasoning, arguments i output ne perenosyatsya v normalizovannyiye sobyitiya ili diagnostiku. Polnyij iskhodnyij JSON vremenno razbirayetsya po odnoj ogranichennoj stroke; otdeljnyij autoreleasepool osvobozhdayet vremennyiye obyyektyi Foundation kazhdoj stroki. Ogranichennaya deljta i uchyot ostayutsya v pamyati — neogranichennyij potok i nulevoye kopirovaniye ne zayavlenyi.

Klyuch vyizova — UUID + call_id; napravleniye otdelyayet vyizov ot rezuljtata. Tochnyiye dubli na novyikh strokakh sokhranyayut proiskhozhdeniye, no ne uvelichivayut chislo vyizovov. Izmenyonnyiye bajtyi togo zhe klyucha/napravleniya konfliktuyut, dazhe yesli izmenenyi toljko otbroshennyiye arguments. Novoye nastoyasjheye call_id s prezhnim imenem — otdeljnyij vyizov. Call bez ID ostayotsya otdeljnyim neizvestnyim nablyudeniyem; output bez ID ne stanovitsya vyizovom. Tokenyi — ASCII-bukvyi, cifryi i `_.:/-`, 1–256 bajt; ostaljnyiye znacheniya ne kopiruyutsya i schitayutsya neizvestnyimi.

Timestamp v1: toljko UTC `YYYY-MM-DDTHH:MM:SS[.1–9 цифр]Z`, kalendarnyij diapazon 1970–2100, bez leap second. Missing/invalid razlichayutsya i ne zamenyayutsya nulyom. Epoch-ns — nablyudyonnaya otmetka zhurnala; sovmestimaya para dayot zaderzhku lishj pri dvukh izvestnyikh vremenakh i neotricateljnoj raznosti. Output ne dokazyivayet uspeshnostj, zaderzhka ne yavlyayetsya vremenem ispolneniya, universaljnyikh porogov avtomatizacii net.

## Dolgovechnostj i ogranicheniya

Odin actor vladeyet sinkhronnyim non-Sendable `Сегмент`; mezhdu preflight, append/fsync i publikaciyej uchyota net await. Polnyij povtornyij potokovyij prokhod proveryayet SHA na prezhnej podtverzhdyonnoj granice. Novyiye sobyitiya i novaya granica zapisyivayutsya odnoj atomarnoj gruppoj kontejnera; otdeljnogo cursor-fajla net. Novyiye nerelevantnyiye stroki tozhe mogut sozdatj gruppu s pustyimi sobyitiyami. Pervyij nevernyij UUID/JSON ne sozdayot segment.

Tochnyij povtor bez novyikh strok zanovo sinkhroniziruyet iskhodnyij poslednij paket, ne sozdavaya novyij. Posle oshibki zapisi ili fsync ekzemplyar trebuyet zakryitiya/replay i ne vyidayot uspeshnogo podtverzhdeniya. Vidimaya posle oshibochnogo fsync gruppa pri povtore snova prokhodit fsync. Povrezhdeniye, nepolnaya gruppa ili nepodkhodyasjhij konvert otklonyayutsya bez avtomaticheskogo remonta. Replay proveryayet versiyu, UUID, kanonicheskiye bajtyi, metadannyiye, poryadok, perekhod granicyi, vyipolnimostj promezhutkov strok/bajtov i kazhdoye sobyitiye do arifmetiki. Eto testyi I/O/restart, ne dokazateljstvo ustojchivosti k potere pitaniya.

| Ogranicheniye | Predel |
| --- | ---: |
| Blok chteniya | 64 KiB |
| Stroka i nezavershyonnyij khvost | 4 MiB |
| Yavnyij vkhodnoj fajl | 256 MiB |
| Zavershyonnyiye stroki | 100000 |
| Normalizovannyiye sobyitiya za istoriyu, vklyuchaya dubli | 8192 |
| Atomarnyij paket | 8 MiB |
| Paketyi | 256 |
| Glubina JSON | 16 |
| Klyuchi odnoj iskhodnoj stroki / konverta | 8192 / 200000 |

Serializaciya deljtyi vyipolnyayetsya do proverki razmera paketa; eti strukturnyiye predelyi ne yavlyayutsya zhyostkim ogranichitelem RSS. Nizhnij kontejner dopolniteljno ogranichen 256 MiB segmenta i 4096 zapisyami; pri otkryitii yego skanirovaniye predshestvuyet boleye uzkim limitam adaptera. Istoriya ne vrasjhayetsya i ne ochisjhayetsya avtomaticheski: perepolneniye trebuyet otdeljnogo resheniya.

Istochnik i prostranstvo imyon vyikhoda predpolagayutsya neizmennyimi vo vremya operacii, ostaljnyiye pisateli — soglasovannyimi. Nachaljnyij razmer, odin fd i proverki inode/size/mtime/ctime otklonyayut nablyudyonnuyu podmenu vkhoda; konechnyij symlink ne otkryivayetsya, roditeljskiye katalogi vkhoda doverenyi. Proverki identichnosti kornya/segmenta do i posle append otklonyayut perenos s podmenoj mezhdu operaciyami. Atomarnaya zasjhita ot vrazhdebnoj namespace/in-place gonki ne zayavlena. Khyeshi — ne anonimizaciya i ne podpisj istochnika.

## Proverki i profilj

`swift test --build-system native --jobs 2` proveryayet dubli, nastoyasjhiye raznyiye call_id, neizvestnyiye polya/vremena, khvost, smenu prefiksa, restart, file/directory fsync, korotkuyu zapisj, povrezhdyonnyiye konvertyi, chislovyiye kraya, limityi, read-only/vladeniye i CLI. Native SwiftPM soobsjhayet preduprezhdeniye ob ustarevanii. V FUM proverki zapuskayutsya cherez obyazateljnuyu v4-obyortku.

Malyij profilj: 32 raznyikh instrumenta/64 sobyitiya. Boljshoj: 2048 instrumentov/4096 sobyitij i 16 ignoriruyemyikh strok po 524376 bajt, vsego 9054449 bajt/4113 strok. Rabochij — toljko publichnaya sintetika s peredannyimi razmerami 105356966 bajt/16609 strok/max3326896, ne kopiya strukturyi ili soderzhimogo zhivogo zhurnala. V kazhdom sluchaye izmeryayutsya import, polnyij povtor, otchyot v pamyati, kodirovaniye i replay. Istochnik progret generaciyej i fsync; vremya — DispatchTime, pamyatj — ru_maxrss vsego processa. Tochnyiye rezuljtatyi, iskhodniki do optimizacii i khyeshi otchyotov khranyatsya v sobstvennom FUM Zhurnale.

Gruppirovka po instrumentu vyipolnyayetsya odin raz: prezhniye povtornyiye prokhodyi po vsem vyizovam zamenenyi slovaryom grupp pri sokhranenii sortirovki i schyotchikov. Vremennyiye obyyektyi Foundation ogranichenyi strokoj i pri generacii fiksturyi, i pri importe.

Istochnik zadaniya — kornevaya zadacha FUM `01a07d3d-d376-7ad2-aafc-67e4c25a67eb`, etap `2026-09-09_14-58-37_MSK_накапливать-статистику-вызовов-из-журнала`; pervichnyij istochnik zakreplyon FUM `670a1fda352b34668d87000602e76e246aefa22f`. FUM-REQ-0045/0160, obsjhuyu priyomku i realjnyij razreshyonnyij import vyipolnyayet korenj. V4 i runtime item_completed — budusjhiye otdeljnyiye adapteryi. Kontrakt proiskhozhdeniya/granicyi mozhet byitj pereispoljzovan, no EOF, final, HookPrompt i vremennaya blizostj ne dokazyivayut zaversheniye zadachi ili roditeljstvo.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:36:01 MSK -->
<!-- content-sha256: sha256:3c56795f6d601e71c71dec8209ef99a0550be658b889d5d50143ef8a9f51a783 -->
<!-- FUM-MD-RECENCY:END -->
