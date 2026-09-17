# Lokaljnyiye chernoviki podderzhki FUM

Generator sobirayet chernoviki Telegram, MAX i otchyota iz odnogo JSON-vkhoda. Sobstvennyiye rezuljtatyi FUM sokhranyayut CC0-1.0. Podgotovka teksta ne sozdayot akkaunt, publikaciyu, pozhertvovaniye ili podtverzhdeniye dostavki.

## Zapusk

Nuzhnyi Python i Git; proverennyiye versii ukazanyi v [profile etapa](../../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/profilj-mediapaketa-itog.json). Sovmestimostj s drugimi versiyami otdeljno ne izmeryalasj. Iz kornya klona FUM:

```bash
python3 -B Инструменты/fum-reyestr-planirovaniya/scripts/медиапакет-поддержки.py --корень-репозитория . --вход Журнал/2026-09-16_00-09-04_MSK_разделить-свидетельства-и-планы-медиапакета/материалы/вход-медиапакета.json
```

Uspekh: kod 0 i polnyij JSON v stdout. Otkaz: kod 2, soobsjheniye v stderr, stdout pust. Sokhraneniye stdout vyipolnyayet vyizyivayusjhaya storona posle proverki koda zaversheniya. Sam CLI ne zapisyivayet paket ili bajtkod i ne zagruzhayet nedostayusjhiye Git-obyyektyi. Git hooks otklyuchayutsya cherez sistemnoye nulevoye ustrojstvo Python (`os.devnull`), bez privyazki k odnomu POSIX-puti. Obyyektyi vsekh ukazannyikh kommitov dolzhnyi uzhe prisutstvovatj lokaljno; nepolnyij klon mozhet byitj otklonyon. Utochneniye okruzheniya i polucheniye obyyektov vyipolnyayutsya otdeljno ot generacii.

## Vkhod versii 2

Polnyij [primer](../../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/vkhod-mediapaketa.json) soderzhit rovno polya `схема`, `лицензия`, `результат`, `ограничения`, `цель`, `следующий_шаг`, `отчёт`. Skhema — `fum.вход-медиапакета.2`; licenziya — `CC0-1.0`. Stroki nepustyiye, odnostrochnyiye, do 8000 simvolov; ogranichenij ot 1 do 32. JSON ogranichen 524288 bajtami. Povtornyiye i neizvestnyiye klyuchi otklonyayutsya.

`результат` soderzhit `вид`, `источник`, `основание`. Vidyi `план` i `материал` trebuyut `основание: null` i poluchayut sootvetstvuyusjhuyu podpisj. Nalichiye citatyi v iskhodnike samo po sebe ne delayet yeyo proverennyim rezuljtatom.

Adres istochnika — obyyekt s polnyim 40-znachnyim `коммит`, tochnyim otnositeljnyim `путь` i `sha256` bajtov Git blob. Materialjnyij istochnik dopolniteljno soderzhit `цитата`. Obyichnyij fajl beryotsya iz ukazannogo kommita, nezavisimo ot tekusjhego fajla v checkout. Simvolicheskiye ssyilki, katalogi, sokrasjhyonnyiye OID, nesovpadeniye registra, khyesha ili citatyi otklonyayutsya; Git replacement refs ne menyayut chitayemyij obyyekt.

Dlya vida `проверенный результат` nuzhno otdeljnoye `основание` s polyami `источник` i `доверенный_автор`. Yego Git blob celikom predstavlyayet odin JSON-obyyekt:

```json
{
  "схема": "fum.свидетельство-результата.1",
  "вид": "свидетельство проверки",
  "автор": "выбранный оператором автор",
  "объект": {"коммит": "полный OID материала", "путь": "путь материала", "sha256": "SHA-256 материала"},
  "утверждение": "точная цитата материала",
  "проверка": "описание выполненной проверки и её границы",
  "исход": "успешно",
  "протокол": {"коммит": "полный OID протокола", "путь": "путь протокола", "sha256": "SHA-256 протокола"}
}
```

Eto skhema polej s poyasneniyami vmesto khyeshej, a ne ispolnyayemyij primer. Avtor, obyyekt i utverzhdeniye dolzhnyi tochno sovpastj s vkhodom; protokol tozhe proveryayetsya po Git-adresu i khyeshu. Vyikhod podpisan «Rezuljtat po svideteljstvu» i pokazyivayet avtora, oblastj proverki, svideteljstvo i protokol.

## Finansovoye svideteljstvo

`отчёт` soderzhit `период`, `получатель`, `валюта`, `начальный_остаток`, `поступления`, `комиссии`, `возвраты`, `расходы`, `источник`, `доверенный_автор`. Valyuta — `RUB`; summyi — celyiye neotricateljnyiye kopejki do 10¹² libo `null`. Nolj oznachayet izvestnyij nolj i trebuyet svideteljstva. Neizvestnoye ne preobrazuyetsya v nolj. Konechnyij ostatok vyichislyayetsya toljko pri izvestnyikh pyati summakh; otricateljnyij vyichislennyij ostatok sokhranyayetsya.

Pri `источник: null` vse summyi i doverennyij avtor dolzhnyi byitj `null`. Period i poluchatelj mogut ostavatjsya neizvestnyimi. Yesli istochnik zadan, vesj yego Git blob dolzhen byitj odnim JSON-obyyektom:

```json
{
  "схема": "fum.свидетельство-поддержки.1",
  "вид": "фактический учёт",
  "автор": "выбранный оператором автор",
  "валюта": "RUB",
  "период": "2026-09",
  "получатель": "явно названный получатель",
  "суммы": {"начальный_остаток": null, "поступления": null, "комиссии": null, "возвраты": null, "расходы": null}
}
```

Polya otchyota i svideteljstva sovpadayut polnostjyu, vklyuchaya `null`. Lyubaya izvestnaya summa trebuyet perioda i poluchatelya. Period — kalendarno dopustimyij `YYYY-MM`. Finansovyij istochnik ukazyivayetsya otdeljno ot materiala novosti. JSON vnutri plana, obesjhaniya, stroki, massiva, vlozhennogo obyyekta ili ryadom s drugim dokumentom ne prinimayetsya kak samostoyateljnoye svideteljstvo. Probeljnoye oformleniye polnogo JSON dopustimo.

Operator yavno vyibirayet doverennogo avtora. Generator proveryayet format, Git-proiskhozhdeniye i soglasovannostj; on ne udostoveryayet lichnostj avtora, ispolneniye proverki ili bankovskuyu operaciyu. Redaktor samostoyateljno proveryayet soderzhaniye svideteljstva i protokola pered publikaciyej. V publichnyij Git popadayut toljko dopustimyiye agregatyi; zakryityiye rekvizityi ne yavlyayutsya vkhodom etogo instrumenta.

## Perekhod i vosproizvedeniye

Tekstovyiye shablonyi khranyatsya kak `шаблоны/сообщение-поддержки.шаблон.txt` i `шаблоны/отчёт-поддержки.шаблон.txt`: okonchaniye `.txt` pozvolyayet proyekcii sokhranyatj ikh tochnyiye bajtyi. Istoricheskiye profili prezhnikh imyon ostayutsya neizmennyimi. Sovmestimostj postavlyayemyikh shablonov proveryayetsya komandoj `python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_формат_шаблонов_поддержки.py`.

Versiya 1 otklonyayetsya: avtomaticheskoj migracii net. Dlya perekhoda nuzhno yavno opredelitj, yavlyayetsya prezhnyaya citata planom, materialom ili utverzhdeniyem s otdeljnyim osnovaniyem, a finansovuyu citatu zamenitj celoj zapisjyu vyibrannogo avtora libo ostavitj summyi neizvestnyimi. Opublikovannyiye staryiye paketyi sokhranyayutsya kak istoriya; novyij paket imeyet skhemu `fum.выход-медиапакета.2`.

Pri odnom vkhode, tekh zhe Git-obyyektakh, kode i shablonakh rezuljtat determinirovan. `вход_sha256` v pakete otnositsya k kanonicheskoj serializacii JSON; `вход_sha256` v profile — k iskhodnyim bajtam vkhodnogo fajla. Eto raznyiye granicyi khyeshirovaniya.

Regressii vosproizvodyatsya komandoj `python3 -B Инструменты/fum-reyestr-planirovaniya/tests/запустить_проверки_медиапакета.py`. Producer sokhranyayet polnyij tekst unittest v stderr i predstavleniye s zamenoj lokaljnyikh putej v stdout; khyesh v konce stdout otnositsya k tekstu unittest, a khyeshi oboikh polnyikh potokov dayot otdeljnyij zakhvat processa. V kontroliruyemoj sessii zapusk uchityivayetsya shtatnoj obyortkoj proverok.

Profiljnyij scenarij `tests/профиль_медиапакета_поддержки.py` prinimayet `--корень`, `--вход`, `--выход`, `--повторы`. On izmeryayet Git-chteniye, proverku i shablonyi; podgotovka vkhoda i zapisj profilya isklyuchenyi. Sravnivatj profili raznyikh kontraktov kak dokazateljstvo uskoreniya neljzya.

## Istochniki

- [Postanovka i korrekciya](../../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/zapros.md), [otchyot](../../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/otchyot.md).
- [Plan medijnogo soprovozhdeniya](../../Planirovaniye/finansirovaniye-i-resursyi/medijnoye-soprovozhdeniye-pozhertvovanij.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-18 00:32:28 MSK -->
<!-- content-sha256: sha256:aca74308fa4fbd8accdd3e2e4cf9e4dcc8ba125e8af5d619e5713d80da4188d6 -->
<!-- FUM-MD-RECENCY:END -->
