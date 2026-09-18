# Ostatok obyazateljstv zadachi

Komanda otvechayet na tri voprosa: kakiye izvestnyiye obyazateljstva sokhranyayutsya, kakiye etapyi podtverzhdenyi i kakuyu rabotu mozhno vyipolnyatj sleduyusjhej. Ona chitayet istoriyu Git i pechatayet JSON. Sleduyusjhuyu rabotu komanda sama ne zapuskayet.

## Ispoljzovaniye

Iz kornya checkout:

```bash
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обязательства_задачи.py
```

Po umolchaniyu ispoljzuyetsya reyestr iz nablyudyonnogo `HEAD`. Nesokhranyonnyiye izmeneniya checkout ne podmenyayut yego. Dlya proverki podgotovlennogo izmeneniya dostupen yavnyij vvod:

```bash
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обязательства_задачи.py --кандидат-из-ввода \
  < Планирование/задачи/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/обязательства.json
```

`--создать-основу` vyivodit iskhodnyiye semj opredelenij bez rabot i priyomok. Eto sredstvo vosstanovleniya proiskhozhdeniya; ono ne zamenyayet tekusjhij reyestr. Vse rezhimyi toljko chitayut. Kod vyikhoda `0` oznachayet korrektno proverennyij rezuljtat, vklyuchaya nalichiye nezavershyonnoj rabotyi; `1` oznachayet oshibku chteniya ili kontrakta.

## Kak chitatj rezuljtat

| Pole                                   | Znacheniye dlya cheloveka                                                                      |
| -------------------------------------- | ------------------------------------------------------------------------------------------ |
| `остаток_обязательств`                 | Vse izvestnyiye obyazateljstva; prinyatiye otdeljnogo etapa ne udalyayet obyazateljstvo            |
| `подтверждённые_этапы`                 | Proverennyiye priyomki s otdeljnyim priznakom aktualjnosti                                     |
| `неактуальные_приёмки`                 | Rezuljtatyi ili ikh predposyilki izmenilisj posle priyomki                                     |
| `работы_в_ожидании`                    | Prichina ozhidaniya i ssyilka na proveryayemoye svideteljstvo                                     |
| `обязательства_без_следующего_этапа`   | Napravleniya, dlya kotoryikh yesjhyo nuzhno vyibratj konkretnuyu rabotu                               |
| `доступные_работы`, `следующая_работа` | Neprinyatyiye rabotyi bez ozhidaniya, chji predposyilki prinyatyi i aktualjnyi; poryadok zadayot reyestr |
| `вершина`, `sha256_реестра`            | Tochnyij Git-snimok i bajtyi proverennogo reyestra                                             |

Sostoyaniye `есть-доступная-работа` oznachayet nalichiye sleduyusjhego dejstviya. `ожидание` vozvrasjhayetsya toljko kogda ostavshiyesya izvestnyiye rabotyi imeyut podtverzhdyonnyiye prichinyi ozhidaniya i net napravleniya bez sleduyusjhego etapa. Inache vozvrasjhayetsya `требуется-план`. Ozhidaniye odnoj rabotyi ne skryivayet nezavisimuyu dostupnuyu rabotu.

## Pochemu priyomka ustarela

Chtobyi poluchitj tochnyiye razlichiya bez ruchnogo poiska po istorii Git, vyizovite:

```bash
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обязательства_задачи.py --диагностика-неактуальности
```

Rezhim vozvrasjhayet otdeljnuyu skhemu `fum.диагностика-приёмок.1`. Shtatnaya skhema `fum.остаток-обязательств.1` i reyestr ne izmenyayutsya. Diagnostika sokhranyayet UUID, vershinu Git, istochnik i SHA reyestra, identichnostj proverennyikh priyomok i ikh priznaki aktualjnosti. Dlya kazhdogo raskhodyasjhegosya obyyavlennogo puti vyivodyatsya prinyatyiye i tekusjhiye SHA-256 i rezhim; `текущее: null` oznachayet otsutstviye fajla. Soderzhimoye fajlov ne vyivoditsya. Poryadok priyomok i rezuljtatov sootvetstvuyet proverennomu reyestru.

Pustoj spisok `изменённые_результаты` ne dokazyivayet aktualjnostj: mogla ustaretj predposyilka. Dlya etogo ostayutsya otdeljnyiye polya `актуальны_собственные_результаты`, `актуальны_предпосылки` i obsjhij priznak `актуальна`. Podmena prinyatogo svideteljstva privodit k obyichnomu otkazu; diagnosticheskij rezhim ne oslablyayet proverku.

Flag sovmestim s `--кандидат-из-ввода` i nesovmestim s `--создать-основу`. Polnaya proverka ostatka vyipolnyayetsya odin raz, zatem diagnostika stroitsya iz uzhe prochitannyikh obyyektov bez novyikh processov Git. Nesokhranyonnyij checkout ne stanovitsya tekusjhim rezuljtatom: sravneniye zakrepleno polem `граница_актуальности`.

## Sokhranyayemyiye dannyiye

V [reyestre etoj zadachi](../../Planirovaniye/zadachi/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/obyazateljstva.json) kazhdoye obyazateljstvo soderzhit identifikator, roditelya, vid rezuljtata i celuyu doslovnuyu komandu s putyom zaprosa i polnyim kommitom. Istoricheskoye proiskhozhdeniye sokhranyayetsya otdeljno ot prinyatogo perenosa v pervichnyij checkout. Nezavisimaya granica importa zakreplena v iskhodnike: proveryayemyij JSON ne mozhet sam naznachitj sebe novyij genezis.

Rabota soderzhit `идентификатор`, `обязательство`, `действие`, `основание`, `предпосылки`, `ожидание` i nepustoj spisok tochnyikh putej `результаты`. Osnovaniye sovpadayet s obyazateljstvom. Predposyilki obrazuyut graf bez ciklov. Ozhidaniye imeyet prichinu i svideteljstvo s polyami `коммит`, `путь`, `sha256`; otsutstviye plana ne maskiruyetsya ozhidaniyem.

Priyomka etapa soderzhit `работа`, `коммит`, `запрос`, `финальный_запуск` i `результаты`. Kazhdyij rezuljtat zadayot `путь`, `sha256` i Git-rezhim `100644` libo `100755`. Opredeleniye rabotyi uzhe prisutstvuyet v kommite priyomki; khotya byi odin zayavlennyij rezuljtat izmenyon etim kommitom. Priyomka zapisyivayetsya pozdneye, kogda izvesten kommit, i proveryayetsya [chitatelem zakryitogo otchyota](../fum-otchyotyi-o-zapuskakh-proverok/svyazj-s-kommitom.md). Proveryayutsya v3-svideteljstva, iskhodnaya komanda, UUID zadachi, poslednij trailer kommita i tochnyiye bajtyi rezuljtata. Vsya cepochka predposyilok proveryayetsya kak na moment priyomki, tak i na tekusjhuyu granicu.

Udaleniye ili izmeneniye opredeleniya, poterya priyomki i udaleniye reyestra obnaruzhivayutsya na kazhdom rebre vsej dostizhimoj istorii, vklyuchaya oboikh roditelej sliyaniya. Ischeznoveniye s posleduyusjhim vosstanovleniyem ne schitayetsya nepreryivnyim sokhraneniyem. Paketnoye chteniye unikaljnyikh derevjyev sokrasjhayet chislo processov Git, sokhranyaya vse versii i ryobra. Shallow-istoriya, grafts, simvolicheskiye ssyilki vmesto obyichnogo fajla i smena `HEAD` vo vremya chteniya otklonyayutsya.

## Granica postavki

Reyestr namerenno chastichnyij: semj sokhranyonnyikh obyazateljstv ne ischerpyivayut vesj dialog. `завершение_задачи_доказано` vsegda ravno `false`. Komanda ne dokazyivayet smyislovoye vyipolneniye vsej FUMA, ne podklyuchayet Stop-hook, ne perenosit staryiye priyomki avtomaticheski i ne podderzhivayet priyomku merge-kommita s neskoljkimi roditelyami. Polnoye perepisyivaniye istorii bez nezavisimogo vneshnego yakorya nakhoditsya za predelami etoj proverki.

V pervoj zapisi splanirovan etap samogo reyestra; ostaljnyiye shestj napravlenij yavno pokazanyi kak trebuyusjhiye sleduyusjhego etapa. Pustoj spisok priyomok ne oznachayet, chto predyidusjhaya rabota otsutstvovala: eta versiya ne prisvaivayet staryim kommitam zadnim chislom novyiye opredeleniya rabot.

Iskhodnoye osnovaniye i obsuzhdeniye sorazmernosti processa: [zapros tekusjhego etapa](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/zapros.md). Scenarii otkazov zakreplenyi adresnyimi testami; [parnyij profilj](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/materialyi/profilj-sravneniya.json) sokhranyayet granicyi izmereniya i sravneniye rezuljtata do i posle optimizacii.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-18 01:51:12 MSK -->
<!-- content-sha256: sha256:67115591e916429115089763072c434484016119b79e042763be02c2ac918829 -->
<!-- FUM-MD-RECENCY:END -->
