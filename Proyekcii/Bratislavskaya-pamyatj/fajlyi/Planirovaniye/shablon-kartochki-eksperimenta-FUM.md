# Shablon kartochki [eksperimenta FUM](../Glossarij/eksperiment-FUM.md)

Shablon versii `1` zadayot chelovekochitayemyij kontejner dlya planirovaniya, vyipolneniya i sokhraneniya odnogo proveryayemogo eksperimenta v [pamyati FUM](../Glossarij/pamyatj-FUM.md). Kartochka svyazyivayet vopros, gipotezu, metod, dannyiye, sredu, zaraneye zadannuyu proverku, otdeljnyiye zapuski, fakticheskij rezuljtat, ogranicheniya, status i odin sleduyusjhij shag.

Kartochka sokhranyayet otricateljnyij i neodnoznachnyij rezuljtat naravne s podderzhavshim gipotezu. Yeyo zadacha — sdelatj proiskhozhdeniye i granicu vyivoda nablyudayemyimi, a ne prevratitj udachnyij progon, uverennyij tekst ili sovpadeniye s ozhidaniyem v dokazannyij vneshnij fakt.

## Granica primenimosti

Versiya `1` prednaznachena dlya materialov tekusjhego [dokumentacionnogo prototipa FUM](../Glossarij/dokumentacionnyij-prototip-FUM.md). Eto povtorno ispoljzuyemyij Markdown-shablon, a ne ispolnyayemaya skhema, laboratornyij runtime, avtomaticheskij ocensjhik istinnosti, razresheniye dostupa ili dokazateljstvo vosproizvodimosti.

Kartochka sama po sebe ne razreshayet setj, publikaciyu, vozdejstviye na lyudej, izmeneniye vneshnej cifrovoj sistemyi ili [fizicheskoye dejstviye FUM](../Glossarij/fizicheskoye-dejstviye-FUM.md). Dlya takikh effektov nuzhnyi otdeljnyiye trebovaniya, prava, proverka riska i podtverzhdeniye. Poka prakticheskiye granicyi issledovateljskoj avtonomii ne opredelenyi, perekhod za lokaljnyiye tekst, dannyiye, kod i yavno ogranichennuyu [modeljnuyu sredu](../Glossarij/modeljnaya-sreda.md) ostayotsya svyazan s [otkryityim voprosom o granicakh issledovateljskoj avtonomii FUM](../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md).

Modeljnyij rezuljtat otnositsya k modeli i usloviyam zapuska, a ne avtomaticheski k vneshnemu miru. Chelovekochitayemyij slovarj versii `1` ne yavlyayetsya okonchateljnoj mashinnoj ontologiyej korobochnoj FUM ili budusjhego [reyestra proiskhozhdeniya FUM](../Glossarij/reyestr-proiskhozhdeniya-FUM.md).

## Osnovnoye pravilo

Odna kartochka opisyivayet odnu versiyu odnogo protokola dlya odnoj proveryayemoj gipotezyi i yavnoj oblasti primenimosti. Neizmenyonnyij protokol mozhet imetj neskoljko zapuskov, no soderzhateljnaya smena voprosa, gipotezyi, dannyikh, metoda, sredyi ili kriteriya proverki trebuyet novoj versii kartochki so ssyilkoj na predshestvennicu.

Planovyiye polya zapolnyayutsya do pervogo zapuska i ne perepisyivayutsya pod fakticheskij iskhod. Otkloneniye ot plana zapisyivayetsya vnutri konkretnogo zapuska. Rezuljtat otdelyayet nablyudeniye ot interpretacii, a sleduyusjhij shag ne zapuskayet dejstviye avtomaticheski.

## Tri nezavisimyikh statusa

Slovo «status» v kartochke raskryivayetsya po tryom osyam, kotoryiye neljzya zamenyatj drug drugom.

### Sostoyaniye vyipolneniya

- `черновик` — protokol yesjhyo nepolon;
- `готов к запуску` — vkhodyi, kriterii, ogranicheniya i razresheniya proverenyi;
- `выполняется` — nachat khotya byi odin nezavershyonnyij zapusk;
- `завершён` — zaplanirovannyiye dejstviya ostanovlenyi i rezuljtat zapisan;
- `остановлен` — srabotal kriterij ostanovki libo prodolzheniye priznano nedopustimyim;
- `заблокирован` — dlya zapuska ne khvatayet dannyikh, sredyi, dostupa ili razresheniya.

### Iskhod proverki gipotezyi

- `не проверено` — prigodnogo rezuljtata yesjhyo net;
- `поддерживает гипотезу в заданной границе` — nablyudeniye sootvetstvuyet zaraneye zadannomu kriteriyu podderzhki;
- `опровергает гипотезу в заданной границе` — vyipolneno zaraneye zadannoye usloviye oproverzheniya;
- `неоднозначно` — svideteljstva nedostatochnyi, protivorechivyi ili ne otdelyayut gipotezu ot aljternativ.

Podderzhka ne ravna okonchateljnomu podtverzhdeniyu, a oproverzheniye v odnoj oblasti ne obyazano oprovergatj boleye shirokoye ili inoye utverzhdeniye. Otricateljnyij i neodnoznachnyij iskhodyi sokhranyayutsya kak ogranicheniya budusjhej rabotyi.

### Issledovateljskij status utverzhdeniya

Status utverzhdeniya vyibirayetsya otdeljno po kanonicheskoj shkale: [gipoteza FUM](../Glossarij/gipoteza-FUM.md), [siljnoye predpolozheniye FUM](../Glossarij/siljnoye-predpolozheniye-FUM.md), [vosproizvedyonnyij rezuljtat FUM](../Glossarij/vosproizvedyonnyij-rezuljtat-FUM.md) ili [otkryitiye FUM](../Glossarij/otkryitiye-FUM.md). Povtornyij progon vnutri togo zhe proizvodyasjhego [FUM-uzla](../Glossarij/FUM-uzel.md) mozhet usilitj osnovaniye, no sam po sebe ne yavlyayetsya nezavisimyim vosproizvedeniyem drugim uzlom.

## Kopiruyemyij shablon

### Pasport

- **Identifikator i versiya:** `<устойчивый experiment_id>; <версия>`
- **Nazvaniye:** `<краткое название>`
- **Tip sredyi:** `текст, данные и код` | `модельная` | `внешняя цифровая` | `физическая`
- **Sozdayusjhij uzel ili nablyudatelj:** `<кто формирует карточку и какие сигналы ему доступны>`
- **Data sozdaniya:** `<дата с явной временной зоной>`
- **Istochnik voprosa:** `<ссылка на запрос, документ, наблюдение или другую наработку>`
- **Predshestvuyusjhaya versiya ili roditeljskij eksperiment:** `<ссылка либо «нет»>`
- **Urovenj dostupa i dopustimyiye operacii:** `<что разрешено читать, использовать, изменять, передавать и публиковать>`

### Vopros

- **Issledovateljskij vopros:** `<самостоятельная формулировка>`
- **Pochemu vopros vazhen:** `<какую неизвестность или решение он затрагивает>`
- **Vkhodit v oblastj:** `<явный перечень>`
- **Ne vkhodit v oblastj:** `<исключения>`

### Gipoteza

- **Proveryayemoye utverzhdeniye:** `<что ожидается>`
- **Ozhidayemoye nablyudeniye:** `<наблюдаемый признак поддержки>`
- **Usloviye oproverzheniya:** `<наблюдаемый признак опровержения>`
- **Konkuriruyusjhiye obyyasneniya:** `<альтернативы и способы их различить>`
- **Iskhodnyij issledovateljskij status:** `гипотеза FUM`

### Metod

- **Protokol:** `<упорядоченные действия, достаточные для повтора>`
- **Izmenyayemyiye velichinyi:** `<что меняется>`
- **Kontroliruyemyiye usloviya:** `<что удерживается неизменным>`
- **Instrumentyi i versii:** `<команды, библиотеки, модели, приборы и способы проверки версий>`
- **Povtoryi i sravneniye:** `<число повторов, контроль и способ сопоставления>`
- **Kriterij ostanovki:** `<когда выполнение прекращается>`
- **Obrabotka otklonenij:** `<как фиксируется незапланированное изменение протокола>`

### Dannyiye

- **Vkhodyi:** `<происхождение, версия или дата, хэш и ссылка>`
- **Preobrazovaniya:** `<точные шаги от входа к анализируемому представлению>`
- **Vyikhodyi i svideteljstva:** `<что сохраняется и где>`
- **Polnota i smesjheniya:** `<известные пропуски, отбор и ограничения измерения>`
- **Dostup i chuvstviteljnostj:** `<публикационная допустимость и ограничения>`

Lokaljnyiye Markdown-ssyilki v publichnoj pamyati ostayutsya otnositeljnyimi putyami vnutri repozitoriya i razreshayutsya ot kataloga soderzhasjhego ikh fajla. Mashinochitayemyiye polya puti, yavno opredelyonnyiye kak otnositeljnyiye k kornyu repozitoriya, sokhranyayut etu otdeljnuyu semantiku. Sekretyi, privatnyiye URL, domashniye i absolyutnyiye mashinnyiye puti ne perenosyatsya v kartochku.

### Sreda

- **Tip sredyi:** `<одно значение из паспорта>`
- **Sostav i versii:** `<ПО, оборудование, модели, сервисы и значимые настройки>`
- **Setj, sekretyi i razresheniya:** `<что требуется и на каком основании>`
- **Razreshyonnyiye effektyi:** `<наблюдаемые допустимые изменения>`
- **Zapresjhyonnyiye effektyi:** `<явная граница>`
- **Granica vosproizvodimosti:** `<что можно повторить локально и какая часть невоспроизводима>`

Dlya modeljnoj sredyi otdeljno zapisyivayetsya, chto yeyo sostoyaniya i rezuljtatyi ne yavlyayutsya nablyudeniyami vneshnego mira.

### Proverka

Kriterii zadayutsya do zapuska.

- **Podderzhka gipotezyi:** `<наблюдаемый критерий>`
- **Oproverzheniye gipotezyi:** `<наблюдаемый критерий>`
- **Neodnoznachnyij iskhod:** `<условие недостаточности или конфликта>`
- **Lokaljnyij sposob proverki:** `<команда, расчёт, обзор или сравнение>`
- **Aljternativnyiye obyyasneniya:** `<что проверяется отдельно>`
- **Trebovaniya k povtoru:** `<какие условия должны совпасть>`
- **Trebovaniya k nezavisimomu vosproizvedeniyu:** `<какой иной узел, данные или метод нужны>`
- **Neobkhodimyiye svideteljstva:** `<выходы, журнал, хэш, измерение или ссылка>`

### Zapusk `<run_id>`

Blok povtoryayetsya dlya kazhdogo zapuska neizmenyonnoj versii protokola.

- **Data, ispolnitelj i uzel:** `<время с зоной; кто выполнял>`
- **Versiya protokola:** `<ссылка на точную версию карточки>`
- **Tochnyiye vkhodyi i sreda:** `<версии, хэши и отличия от паспорта>`
- **Dejstviya ili komanda:** `<что фактически выполнено>`
- **Zavershyonnostj:** `завершён` | `остановлен` | `ошибка`
- **Otkloneniya ot metoda:** `<перечень либо «нет»>`
- **Vyikhodyi i svideteljstva:** `<наблюдаемый результат и ссылки>`

### Rezuljtat

- **Fakticheskiye nablyudeniya:** `<без подмены интерпретацией>`
- **Svodka povtorov:** `<совпадения, расхождения и способ объединения>`
- **Iskhod otnositeljno gipotezyi:** `<одно значение словаря исходов>`
- **Interpretaciya:** `<какое объяснение поддержано и почему>`
- **Neopredelyonnostj:** `<что неизвестно и как это влияет на вывод>`
- **Otricateljnyij ili neodnoznachnyij rezuljtat:** `<полезное ограничение будущей работы либо «неприменимо»>`
- **Chto rezuljtat ne dokazyivayet:** `<явная граница вывода>`

### Ogranicheniya

- **Oblastj primenimosti:** `<где вывод допустим>`
- **Isklyucheniya:** `<где вывод неприменим>`
- **Nevosproizvodimaya chastj:** `<что и почему нельзя повторить локально>`
- **Ugrozyi validnosti i izvestnyiye oshibki:** `<смещения, конфаундеры и слабые места>`
- **Riski i ogranicheniya dostupa:** `<что запрещает расширить эксперимент>`
- **Usloviya peresmotra:** `<какие новые данные меняют вывод>`

### Status

- **Sostoyaniye vyipolneniya:** `<одно значение словаря>`
- **Iskhod proverki gipotezyi:** `<одно значение словаря>`
- **Issledovateljskij status utverzhdeniya:** `<одно значение канонической шкалы>`
- **Osnovaniye statusov:** `<ссылки на запуски, свидетельства и критерии>`
- **Nezavisimoye vosproizvedeniye:** `<узел, протокол и результат либо «не выполнялось»>`

### Sleduyusjhij shag

- **Dejstviye:** `повторить` | `провести независимую проверку` | `проверить альтернативу` | `создать новую версию` | `остановить исследование` | `связать с инженерным решением`
- **Osnovaniye:** `<почему выбран именно этот шаг>`
- **Predusloviya i razresheniya:** `<данные, доступ, риск и подтверждения>`
- **Svyazannyij material:** `<ссылка либо «ещё не создан»>`

Zapisj sleduyusjhego shaga yavlyayetsya predlozheniyem i ne oznachayet yego zapuska ili razresheniya.

## Pravila zapolneniya

Kartochka schitayetsya zapolnennoj, kogda:

- vopros, gipoteza i oblastj dopuskayut nablyudayemuyu proverku;
- metod, dannyiye i sreda dostatochnyi dlya povtora libo pryamo nazyivayut nevosproizvodimuyu chastj;
- kriterii podderzhki, oproverzheniya, neodnoznachnosti i ostanovki zapisanyi do zapuska;
- kazhdyij zapusk imeyet sobstvennyij identifikator, tochnyiye usloviya, otkloneniya i svideteljstva;
- nablyudeniye otdeleno ot interpretacii, a otricateljnyij rezuljtat ne udalyon;
- tri osi statusa imeyut otdeljnyiye osnovaniya;
- zayavlennoye vosproizvedeniye nazyivayet nezavisimyij uzel i sopostavimyij protokol;
- ogranicheniya ne pozvolyayut perenositj modeljnyij ili lokaljnyij vyivod na boleye shirokuyu oblastj bez novoj proverki;
- sleduyusjhij shag soderzhit predusloviya i ne podmenyayet razresheniye na dejstviye.

## Proverochnyij primer

### Pasport

- **Identifikator i versiya:** `json-order-sha256; 1`
- **Nazvaniye:** `Проверить детерминированную сериализацию двух словарей`
- **Tip sredyi:** `текст, данные и код`
- **Sozdayusjhij uzel ili nablyudatelj:** dokumentacionnyij prototip FUM; dostupnyi komanda, standartnyij vyivod i versiya lokaljnogo Python.
- **Data sozdaniya:** `2026-07-23 MSK`
- **Istochnik voprosa:** [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-23_16-11-30_MSK_opisatj-shablon-kartochki-eksperimenta-FUM/zapros.md).
- **Predshestvuyusjhaya versiya ili roditeljskij eksperiment:** `нет`.
- **Urovenj dostupa i dopustimyiye operacii:** `публичный`; dopustimyi lokaljnoye chteniye i vyichisleniye bez zapisi, seti i sekretov.

### Vopros

- **Issledovateljskij vopros:** dayut li dva slovarya s odinakovyimi parami klyuchej i znachenij, no raznyim poryadkom vstavki, odinakovyiye serializaciyu i SHA-256 pri tochno zadannyikh parametrakh Python `json.dumps`?
- **Pochemu vopros vazhen:** primer proveryayet, chto shablon pozvolyayet zaraneye zadatj nablyudayemyij iskhod i zatem sokhranitj tochnyiye dannyiye, sredu i granicu vyivoda.
- **Vkhodit v oblastj:** dva zadannyikh slovarya, Python `3.14.6`, UTF-8 i parametryi `ensure_ascii=False`, `sort_keys=True`, `separators=(",", ":")`.
- **Ne vkhodit v oblastj:** drugiye tipyi znachenij, parametryi serializacii, realizacii JSON, versii sredyi i utverzhdeniye ob universaljnoj kanonichnosti JSON.

### Gipoteza

- **Proveryayemoye utverzhdeniye:** oba poryadka vstavki dadut odnu stroku i odin SHA-256.
- **Ozhidayemoye nablyudeniye:** dve stroki ravnyi `{"a":1,"b":2}`, a dva khyesha ravnyi mezhdu soboj.
- **Usloviye oproverzheniya:** razlichayetsya khotya byi odna stroka ili odin khyesh.
- **Konkuriruyusjhiye obyyasneniya:** poryadok vstavki vliyayet na vyikhod; `sort_keys=True` ne normalizuyet dannyij sluchaj; razlichayutsya kodiruyemyiye bajtyi.
- **Iskhodnyij issledovateljskij status:** `гипотеза FUM`.

### Metod

- **Protokol:** sozdatj slovari `{"b": 2, "a": 1}` i `{"a": 1, "b": 2}`; serializovatj kazhdyij s zadannyimi parametrami; vyichislitj SHA-256 ot UTF-8 bez zavershayusjhego perevoda stroki; vyivesti obe paryi.
- **Izmenyayemyiye velichinyi:** poryadok vstavki klyuchej.
- **Kontroliruyemyiye usloviya:** paryi klyuchej i znachenij, parametryi serializacii, kodirovka i algoritm khyeshirovaniya.
- **Instrumentyi i versii:** `python3 --version` soobsjhayet `Python 3.14.6`; ispoljzuyutsya toljko `json` i `hashlib` standartnoj biblioteki.
- **Povtoryi i sravneniye:** dva varianta vkhoda sravnivayutsya v odnom lokaljnom zapuske.
- **Kriterij ostanovki:** komanda zavershilasj, vernula oshibku libo narushila zapret seti i zapisi.
- **Obrabotka otklonenij:** nezaplanirovannoye otkloneniye fiksiruyetsya v zapisi tekusjhego zapuska; povtor ili prodolzheniye s soderzhateljno izmenyonnoj komandoj libo sredoj trebuyet novoj versii kartochki. V tekusjhem zapuske otklonenij net.

### Dannyiye

- **Vkhodyi:** literalyi `{"b": 2, "a": 1}` i `{"a": 1, "b": 2}` v komande; vneshnikh istochnikov net.
- **Preobrazovaniya:** sortirovka klyuchej pri serializacii, kompaktnyiye razdeliteli, kodirovaniye UTF-8 i SHA-256.
- **Vyikhodyi i svideteljstva:** chetyire znacheniya standartnogo vyivoda sokhranenyi nizhe v zapisi zapuska.
- **Polnota i smesjheniya:** proveryayutsya toljko dve perestanovki odnogo dvukhyelementnogo nabora.
- **Dostup i chuvstviteljnostj:** dannyiye publikacionno chistyi, sekretov i personaljnyikh svedenij net.

### Sreda

- **Tip sredyi:** `текст, данные и код`.
- **Sostav i versii:** lokaljnyij Python `3.14.6`, moduli `json` i `hashlib` standartnoj biblioteki.
- **Setj, sekretyi i razresheniya:** ne trebuyutsya.
- **Razreshyonnyiye effektyi:** chteniye versii sredyi i vyivod rezuljtata v standartnyij potok.
- **Zapresjhyonnyiye effektyi:** zapisj fajlov, setj i izmeneniye vneshnego sostoyaniya.
- **Granica vosproizvodimosti:** komanda povtorima lokaljno pri nalichii Python 3; tochnoye sovpadeniye mezhdu inyimi versiyami i realizaciyami otdeljno ne provereno.

### Proverka

- **Podderzhka gipotezyi:** obe serializacii i oba khyesha poparno ravnyi ozhidayemyim znacheniyam.
- **Oproverzheniye gipotezyi:** khotya byi odna para razlichayetsya.
- **Neodnoznachnyij iskhod:** komanda ne zavershilasj libo sreda ne pozvolyayet otdelitj vliyaniye poryadka ot izmeneniya drugikh uslovij.
- **Lokaljnyij sposob proverki:** vyipolnitj sokhranyonnuyu komandu i sravnitj dve stroki vyivoda.
- **Aljternativnyiye obyyasneniya:** tochnyiye parametryi i bajtyi vyivoda fiksiruyutsya, chtobyi rezuljtat ne obyyasnyalsya neyavnyim formatirovaniyem.
- **Trebovaniya k povtoru:** te zhe vkhodyi, parametryi i UTF-8; versiya Python zapisyivayetsya ryadom s rezuljtatom.
- **Trebovaniya k nezavisimomu vosproizvedeniyu:** drugoj FUM-uzel povtoryayet protokol v sopostavimoj srede i sokhranyayet sobstvennoye svideteljstvo.
- **Neobkhodimyiye svideteljstva:** versiya Python, obe serializacii, oba SHA-256 i kod zaversheniya komandyi.

### Zapusk `local-2026-07-23-01`

- **Data, ispolnitelj i uzel:** `2026-07-23 MSK`; tekusjhaya kornevaya zadacha Codex v dokumentacionnom prototipe FUM.
- **Versiya protokola:** `json-order-sha256; 1`.
- **Tochnyiye vkhodyi i sreda:** vkhodyi i Python `3.14.6` sovpadayut s pasportom.
- **Dejstviya ili komanda:**

  ```bash
  python3 -I -c 'import hashlib,json; values=[{"b":2,"a":1},{"a":1,"b":2}]; texts=[json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(",",":")) for value in values]; print(*(text + " " + hashlib.sha256(text.encode("utf-8")).hexdigest() for text in texts), sep="\n")'
  ```

- **Zavershyonnostj:** `завершён`; kod vyikhoda `0`.
- **Otkloneniya ot metoda:** `нет`.
- **Vyikhodyi i svideteljstva:**

  ```text
  {"a":1,"b":2} 43258cff783fe7036d8a43033f830adfc60ec037382473548ac742b888292777
  {"a":1,"b":2} 43258cff783fe7036d8a43033f830adfc60ec037382473548ac742b888292777
  ```

### Rezuljtat

- **Fakticheskiye nablyudeniya:** obe serializacii ravnyi `{"a":1,"b":2}`, oba SHA-256 ravnyi `43258cff783fe7036d8a43033f830adfc60ec037382473548ac742b888292777`.
- **Svodka povtorov:** dva varianta poryadka vstavki dali odinakovyij vyikhod; nezavisimogo povtora drugim uzlom ne byilo.
- **Iskhod otnositeljno gipotezyi:** `поддерживает гипотезу в заданной границе`.
- **Interpretaciya:** pri zafiksirovannyikh vkhodakh, parametrakh i lokaljnoj srede poryadok vstavki ne izmenil nablyudayemyij rezuljtat.
- **Neopredelyonnostj:** ne proverenyi drugiye dannyiye, versii Python i realizacii serializacii.
- **Otricateljnyij ili neodnoznachnyij rezuljtat:** `неприменимо`; poleznoye ogranicheniye sostoit v uzkoj oblasti primera.
- **Chto rezuljtat ne dokazyivayet:** universaljnuyu kanonichnostj JSON, perenosimostj na drugiye tipyi dannyikh ili nezavisimuyu vosproizvodimostj.

### Ogranicheniya

- **Oblastj primenimosti:** dva zadannyikh slovarya i tochnyiye parametryi lokaljnoj komandyi.
- **Isklyucheniya:** vse inyiye vkhodyi, parametryi i sredyi.
- **Nevosproizvodimaya chastj:** otsutstvuyet dlya lokaljnogo povtora; nezavisimyij uzel ne uchastvoval.
- **Ugrozyi validnosti i izvestnyiye oshibki:** malaya vyiborka i odin proizvodyasjhij uzel.
- **Riski i ogranicheniya dostupa:** rasshireniye ne dolzhno vvoditj setj, sekretyi ili zapisj bez otdeljnogo osnovaniya.
- **Usloviya peresmotra:** inoj rezuljtat sopostavimogo povtora ili vyiyavlennaya zavisimostj ot nezafiksirovannogo usloviya.

### Status

- **Sostoyaniye vyipolneniya:** `завершён`.
- **Iskhod proverki gipotezyi:** `поддерживает гипотезу в заданной границе`.
- **Issledovateljskij status utverzhdeniya:** `сильное предположение FUM`; vyipolnena pervichnaya lokaljnaya proverka odnim uzlom.
- **Osnovaniye statusov:** zapusk `local-2026-07-23-01`, kod vyikhoda `0` i sokhranyonnyij standartnyij vyivod.
- **Nezavisimoye vosproizvedeniye:** `не выполнялось`.

### Sleduyusjhij shag

- **Dejstviye:** `остановить исследование`.
- **Osnovaniye:** primer uzhe proveryayet zapolnyayemostj vsekh obyazateljnyikh polej shablona; rasshireniye issledovaniya ne trebuyetsya dlya tekusjhej zadachi.
- **Predusloviya i razresheniya:** dlya nezavisimoj proverki nuzhen otdeljnyij uzel i samostoyateljnoye svideteljstvo; oni ne trebuyutsya dlya prinyatiya chelovekochitayemogo shablona.
- **Svyazannyij material:** `ещё не создан`.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-07-23_16-11-30_MSK_opisatj-shablon-kartochki-eksperimenta-FUM/zapros.md)
- [napravleniye issledovanij i otkryitij](napravleniya-proyektirovaniya-i-razvitiya/07-issledovaniya-i-otkryitiya.md)
- [nauchnyiye issledovaniya FUM i otkryitiya](../Dokumentaciya/16-nauchnyiye-issledovaniya-i-otkryitiya.md)

## Opornyiye materialyi

- [eksperiment FUM](../Glossarij/eksperiment-FUM.md)
- [otkryityij vopros o granicakh issledovateljskoj avtonomii FUM](../Voprosyi/2026-06-22_08-04-45_MSK_granicyi-issledovateljskoj-avtonomii-FUM.md)
- [minimaljnyij pasport peredavayemogo rezuljtata FUM](../Dokumentaciya/39-minimaljnyij-pasport-peredavayemogo-rezuljtata-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:f113a9df6ae71d46a485c6a8c027724a59f353640ffccb807b5ca4a3a3a3505c -->
<!-- FUM-MD-RECENCY:END -->
