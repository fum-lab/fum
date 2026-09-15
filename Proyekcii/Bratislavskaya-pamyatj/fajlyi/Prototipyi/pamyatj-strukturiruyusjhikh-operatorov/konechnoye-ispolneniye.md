# Konechnoye ispolneniye operatorov

Tot zhe `AutomationExecutor`, kotoryij obsluzhivayet prezhniye scenarii [prototipa](README.md), ispolnyayet otdeljnoye opredeleniye nad tipizirovannyim vkhodom. Chistyij metod `выполнить` vozvrasjhayet nablyudeniye i ne prinimayet ozhidayemogo otveta. Prezhnij `AutomationFixture` sluzhit proverochnyim adapterom: perevodit shagi v opredeleniye, vyizyivayet obsjhij metod, zatem sravnivayet itog s `expectedOutput` i formiruyet prezhnyuyu trassu.

## Zapusk

Komandyi vyipolnyayutsya iz kornya FUM. Dlya otdeljnogo iskhodnogo bajtovogo vkhoda:

```sh
printf '\321\221' | ./Прототипы/память-структурирующих-операторов/запустить.sh исполнить \
  --определение Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/Определения/UTF-8-в-UTF-32LE.json \
  --вход байты
```

Rezuljtat soderzhit skalyar `1105` (U+0451) i bajtyi `[81,4,0,0]`. Dlya UTF-32BE sleduyet peredatj otdeljnyij JSON s `порядок: "BE"` poslednego shaga; rezuljtat — `[0,0,4,81]`. Vyibor poryadka obyazatelen i ne zavisit ot arkhitekturyi mashinyi.

Pervyij samostoyateljnyij primer normalizacii teksta:

```sh
printf '  ИСПРАВЬ   ОТЧЁТ  ' | ./Прототипы/память-структурирующих-операторов/запустить.sh исполнить \
  --определение Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/Определения/нормализация.json \
  --вход текст
```

Nablyudayemyij rezuljtat — `исправь отчёт`. Imya primera oznachayet preobrazovaniye registra i probelov; eto ne Unicode NFC/NFD.

Parametryi `--определение` i `--вход` obyazateljnyi; povtoryi, neizvestnyiye parametryi i lishniye argumentyi otklonyayutsya. Rezhim `байты` peredayot stdin bez preobrazovaniya v `String`; `текст` trebuyet korrektnyij UTF-8; `скаляры` prinimayet JSON-massiv celyikh Unicode-skalyarov. Probnik chitayet toljko yavno ukazannyij fajl opredeleniya i konechnyij stdin, pishet nablyudeniye v stdout, diagnostiku — v stderr. Pri otkaze chastichnyij rezuljtat ne vyivoditsya, kod zaversheniya raven 1. Setevyikh zaprosov, zapisi poljzovateljskikh fajlov i ispolneniya koda iz opredeleniya net. Tochka vkhoda SwiftPM sozdayot lishj sluzhebnuyu sborku vne Git.

## Zakryitoye opredeleniye

Skhema `fum.определение-оператора.1` trebuyet rovno polya `схема`, `идентификатор`, `версия`, `правила`, `шаги`. Kazhdyij shag soderzhit rovno `идентификатор`, `оператор`, `аргументы`. Polnyij primer khranitsya v [normalizacii](Sources/FUMStructuringOperatorMemory/Opredeleniya/normalizaciya.json), bajtovyiye pravila — v [UTF-8 → UTF-32LE](Sources/FUMStructuringOperatorMemory/Opredeleniya/UTF-8-v-UTF-32LE.json).

| Operator          | Vkhod → vyikhod     | Tochnyiye polya argumentov                              |
| ----------------- | ---------------- | -------------------------------------------------- |
| `обрезать`        | tekst → tekst    | pustoj obyyekt                                      |
| `нижний-регистр`  | tekst → tekst    | pustoj obyyekt                                      |
| `сжать-пробелы`   | tekst → tekst    | pustoj obyyekt                                      |
| `заменить`        | tekst → tekst    | `старое`, `новое`: stroki; staroye nepustoye           |
| `префикс`        | tekst → tekst    | `текст`: stroka                                    |
| `повторить-правила` | bajtyi → skalyaryi | `правила`: nepustoj massiv unikaljnyikh imyon          |
| `упаковать-слова` | skalyaryi → bajtyi  | `ширина`: 1, 2 ili 4; `порядок`: `LE` libo `BE`      |

Imenovannoye pravilo soderzhit `идентификатор`, massiv `байты` iz vklyuchiteljnyikh diapazonov `{от,до}` i massiv `поля` iz `{байт,маска,сдвиг}`. Nomer bajta otschityivayetsya ot nachala sovpadeniya s nulya; maska primenyayetsya do levogo sdviga; rezuljtatyi soyedinyayutsya pobitovyim OR. Proverka zapresjhayet vyikhod za granicyi pravila, nulevyiye maski, perepolneniye 32 bit i perekryitiye vyikhodnyikh bitov. Povtor sopostavlyayet konechnyiye diapazonyi i obyazateljno prodvigayet kursor na polozhiteljnuyu dlinu pravila. Peresekayusjhiyesya i prefiksnyiye aljternativyi otklonyayutsya do ispolneniya; poryadok ne sluzhit skryityim razresheniyem neodnoznachnosti.

Razbor otklonyayet neizvestnyiye i povtornyiye polya, vklyuchaya povtor cherez JSON-ekranirovaniye, nevernyiye tipyi, povtornyiye identifikatoryi, neizvestnyiye operatoryi i ssyilki, nepraviljnyiye argumentyi. Chisla toljko celyiye; `true`, `false`, `null`, drobi i eksponentyi ne vkhodyat v skhemu. Pustoj spisok shagov vozvrasjhayet vkhod kak rezuljtat s obyichnoj proverkoj predelov. Nesootvetstviye tipa ocherednomu operatoru dayot yavnyij otkaz ispolneniya.

## Strogij UTF-8 i UTF-32

Opredeleniye soderzhit devyatj aljternativ iz tablicyi 3-7 Unicode 17.0.0: `00–7F`; `C2–DF 80–BF`; `E0 A0–BF 80–BF`; `E1–EC 80–BF 80–BF`; `ED 80–9F 80–BF`; `EE–EF 80–BF 80–BF`; `F0 90–BF 80–BF 80–BF`; `F1–F3 80–BF 80–BF 80–BF`; `F4 80–8F 80–BF 80–BF`. Dlinyi, diapazonyi i maski — dannyiye opredeleniya, a sopostavleniye, izvlecheniye bitov, povtor i upakovka — obsjhiye konechnyiye operacii.

Snachala poluchayetsya massiv Unicode-skalyarov: U+0000…U+10FFFF bez U+D800…U+DFFF. Otdeljnaya upakovka shirinoj 4 vozvrasjhayet UTF-32 v vyibrannom poryadke. Nikakoj ispravlyayusjhij standartnyij dekoder iskhodnogo UTF-8 vnutri etogo puti ne vyizyivayetsya. Nezavisimyiye testyi soderzhat bukvaljnyiye ozhidayemyiye skalyaryi i bajtyi dlya obeikh serializacij.

Izbyitochnyiye kodirovki, otdeljnyiye prodolzheniya, nepraviljnyiye prodolzheniya, surrogatyi, znacheniya vyishe U+10FFFF i oborvannyij konec otklonyayutsya. `позицияБайта` — absolyutnyij indeks s nulya pervogo nesovmestimogo bajta po naiboleye dlinnomu sovpavshemu prefiksu; pri nekhvatke bajta on raven dline vkhoda. `началоПоследовательности` otdeljno ukazyivayet nachalo neudachnogo sopostavleniya. Naprimer, `41 D1` dayot poziciyu 2 i nachalo 1, a `41 E0 9F 80` — poziciyu 2 i nachalo 1.

Normalizaciya Unicode ne vyipolnyayetsya. U+FEFF i noncharacters prinimayutsya kak skalyaryi i sokhranyayutsya; novyij BOM ne dobavlyayetsya, vkhodnoj U+FEFF ne udalyayetsya. Sochetaniye `е` i U+0308 ostayotsya dvumya skalyarami. Upakovka shirinoj 1 ili 2 — obsjhij operator slov s proverkoj vmestimosti, a ne UTF-8 ili UTF-16.

## Predelyi i nablyudeniye

| Obyyekt                    | Verkhnyaya granica                                         |
| ------------------------- | ------------------------------------------------------- |
| Fajl opredeleniya          | 65 536 bajtov UTF-8; glubina JSON 16; 8 192 uzla          |
| Identifikator / versiya    | 128 bajtov bez upravlyayusjhikh skalyarov / 1…1 000 000        |
| Shagi / pravila            | 32 / 32                                                 |
| Bajtyi i bitovyiye polya pravila | po 1…8                                               |
| Strokovyij argument        | 4 096 bajtov UTF-8                                       |
| Otdeljnyij vkhod API        | 262 144 bajta; skalyar uchityivayetsya kak 4 bajta             |
| Rezuljtat kazhdogo shaga    | 1 048 576 bajtov; skalyar uchityivayetsya kak 4 bajta          |
| Schyotchik obsjhikh operacij    | 16 777 216                                              |
| Sobyitiya pravil / sledyi shagov | 256 / 32                                              |

API pozvolyayet toljko umenjshatj predelyi vkhoda, rezuljtata, operacij i sobyitij. CLI snachala ogranichenno chitayet stdin do 262 144 bajtov; dlya rezhima `скаляры` dopolniteljno dejstvuyut predelyi obsjhego JSON-razbora 65 536 bajtov i 8 192 uzla. Eto konechnaya obrabotka vsego prinyatogo vvoda. Porcii chteniya `FileHandle` ne yavlyayutsya potokovyim dekoderom s sokhraneniyem nepolnogo sostoyaniya.

Predel rezuljtata ne raven predelu pamyati processa ili razmera JSON-otchyota: nablyudeniye vklyuchayet rezuljtat, promezhutochnyiye skalyaryi i trassu, serializaciya vremenno vyidelyayet pamyatj. Tekstovyiye operacii ispoljzuyut konechnyiye stroki i tablicyi Swift/Foundation; promezhutochnoye vyideleniye `lowercased`/obrezki mozhet predshestvovatj proverke umenjshennogo predela rezuljtata. Schyotchik operacij ogranichivayet shagi, sopostavleniya, polya, upakovku i yavnyiye strokovyiye ciklyi; on ne izmeryayet instrukcii standartnoj biblioteki, razbor, khyeshirovaniye ili vremya CPU. Ogranicheniye pamyati processa i dedlajn ispolneniya ne zayavlenyi. Unicode-versiya tekstovogo registra zavisit ot runtime; versiya 17.0.0 zakreplena dlya normativnyikh pravil bajtovogo opredeleniya.

Nablyudeniye skhemyi `fum.наблюдение-оператора.1` svyazyivayet khyesh kanonicheskogo opredeleniya, yego versiyu, tip vkhoda, SHA-256 tochnyikh iskhodnyikh bajtov, rezuljtat, poluchennyiye skalyaryi i sledyi shagov. Dlya vkhoda `скаляры` khyeshiruyutsya chetyire bajta BE na skalyar; dlya teksta — yego UTF-8. Khyesh opredeleniya uchityivayet identifikator, versiyu, argumentyi, pravila i poryadok shagov, no ne probelyi oformleniya JSON. Raznyiye opredeleniya s odinakovyim itogom sokhranyayut razlichnuyu identichnostj.

Sobyitiya pravil sokhranyayutsya do predela; ostatok otrazhyon v `пропущеноЗаписей`. `хэшНаблюдения` — SHA-256 tochnogo kanonicheskogo JSON s vremenno pustyim znacheniyem etogo polya. Kanonicheskij kodirovsjhik sokhranyayet imena klyuchej, sortiruyet ikh i ne ekraniruyet sleshi. Khyeshi ne arkhiviruyut vkhodnyiye dannyiye i ne podtverzhdayut ikh istinnostj; dlya posleduyusjhego vosproizvedeniya vyizyivayusjhaya storona sokhranyayet iskhodnik otdeljno. Probnik etogo fajlovogo effekta ne vyipolnyayet.

## Proverki i profilj

Proverka paketa opisana v [README](README.md). [Novyiye avtonomnyiye testyi](Tests/FUMStructuringOperatorMemoryTests/ProverkiChistogoIspolneniya.swift) pokryivayut 23 polozhiteljnyikh vektora v oboikh poryadkakh, 26 otricateljnyikh vektorov s tochnyimi poziciyami, zakryituyu skhemu, byudzhetyi, neodnoznachnostj pravil, izmeneniye povedeniya dannyimi i nezavisimostj ot ozhidaniya. Prezhniye scenarii proveryayutsya tem zhe adapterom; polnoye nablyudeniye sravneno pobajtno s bazoj `3fdcb39ce8822102fe8823ee8bf483be2d6581c3`. Sovmestimostj dokazana dlya sokhranyonnyikh scenariyev i otdeljnyikh pustyikh/povtornyikh shagov; proizvoljnyiye prezhniye vkhodyi za novyimi konechnyimi predelami ne obesjhanyi.

Flag `--профиль` ostavlyayet nablyudeniye determinirovannyim i pishet JSONL stadij v stderr: zagruzka opredeleniya i stdin, razbor, povtornaya proverka tipizirovannogo opredeleniya, ispolneniye i trassa. Trassa vklyuchayet khyeshi i kanonizaciyu dlya khyesha nablyudeniya; finaljnaya serializaciya stdout i zapusk processa nakhodyatsya vne stadij. Na otkaze zagruzki ili razbora profilj mozhet byitj nepolnyim; vyipolnennyiye stadii proverki/ispolneniya pomechayut iskhod. Vse dliteljnosti predstavlenyi JSON-celyimi; yedinica — nanosekunda.

Dlya vosproizvedeniya profilya sobratj Release s `swift build -c release --package-path Прототипы/память-структурирующих-операторов --scratch-path <внешний-каталог-сборки>`, poluchitj putj komandoj `swift build` s temi zhe parametrami i `--show-bin-path`, zatem zapustitj:

```sh
python3 -B Прототипы/память-структурирующих-операторов/Проверки/проверить-и-измерить.py \
  --бинарник <путь-к-FUMStructuringOperatorMemoryProbe> \
  --выход <путь-к-профилю-json>
```

[Skript](Proverki/proveritj-i-izmeritj.py) proveryayet CLI i delayet po pyatj povtorov shesti fiksirovannyikh vkhodov, vklyuchaya predeljnyij ASCII, smeshannyij UTF-8, kirillicheskuyu zamenu i boljshoj grafemnyij klaster. Dlya proverki profilya ispoljzuyetsya nezavisimyij kodek Python, a ne ispolnitelj Swift. Sokhranyayutsya versii sredyi, khyeshi iskhodnikov, binarnika, skripta, opredelenij, vkhodov i rezuljtatov, vse zameryi i medianyi. Skript yavno pishet vyibrannyij otchyot kak proverochnyij instrument; eto ne operaciya yazyika opredeleniya.

V [profilyakh do i posle](../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/otchyot.md) ustraneniye promezhutochnyikh massivov serializacii umenjshilo medianu trassyi predeljnogo ASCII s 375,0 do 49,7 ms; bajtyi nablyudenij sovpali na vsekh shesti vkhodakh. Tochnyiye iskhodniki obeikh serij vosstanavlivayutsya [otkryityimi proverochnyimi patchami](Proverki/etalonyi-profilya/README.md). Eto izmereniye konkretnoj sredyi, a ne obesjhaniye proizvoditeljnosti na drugikh sistemakh.

## Istochniki

- [Trebovaniye FUM-REQ-0067](../../Trebovaniya/🟡-chistoye-ispolneniye-operatorov-i-UTF-32.md).
- [Shag FUM-STEP-0208](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0208-realizovatj-interpretator-i-UTF-32.md).
- [Zapros realizacii](../../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/zapros.md).
- [Unicode 17.0.0, glava 3](../../Istochniki/URL/https/www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/source-index.md): D76, D90–D93, tablicyi 3-6 i 3-7, D99–D100.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:27:58 MSK -->
<!-- content-sha256: sha256:8a72a103624849ce4069580af8ece5f22460f1d77a8c69db0e926bb217a0a6b5 -->
<!-- FUM-MD-RECENCY:END -->
