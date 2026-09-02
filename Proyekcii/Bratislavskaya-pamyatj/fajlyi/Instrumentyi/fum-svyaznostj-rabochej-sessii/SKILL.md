---
name: fum-svyaznostj-rabochej-sessii
description: Proveryatj svyaznostj rabochej sessii FUM pered kommitom: navigaciyu zaprosov, zavershyonnostj shablonov, zhurnal i yego profilj vremeni, kornevoj Codex-Thread-ID v zaprose i tele kommita, obyazateljnoye kanonicheskoye MSK-vremya, razdel ispoljzovannyikh instrumentov, Markdown-ssyilki, registr putej, klassifikaciyu voprosov i otvetov, signalyi meta-zaprosov i Git-sostoyaniye.
---

# FUM Session Coherence

Etot navyik opisyivayet lokaljnuyu [avtomatizaciyu FUM](../../Glossarij/avtomatizaciya-FUM.md), kotoraya proveryayet, chto [rabochaya sessiya](../../Glossarij/rabochaya-sessiya.md) svyazana s [pamyatjyu FUM](../../Glossarij/pamyatj-FUM.md) kak vosproizvodimaya cepochka:

papka zaprosa -> iskhodnyij zapros i sosednij otchyot -> zatronutyiye fajlyi -> proverki -> kommit.

## Kogda ispoljzovatj

Ispoljzuj etu avtomatizaciyu pered kommitom rabochej sessii, vliyayusjhej na proyekt, posle zapuska `fum-svezhestj-markdown` i posle togo kak fajl zaprosa uzhe soderzhit razdelyi `## Идентификатор сеанса Codex`, `## Использованные инструменты`, `## Повлиял на файлы` i `## Проверки`. Polnuyu predkommitnuyu proverku zapuskaj s tem zhe fajlom soobsjheniya, kotoryij zatem budet peredan `git commit -F`. Dlya novyikh zaprosov nachinaya s zakreplyonnoj vremennoj granicyi parametryi `--commit-message-file` i `--codex-thread-id` obyazateljnyi; istoricheskiye zaprosyi sokhranyayut prezhnij kontrakt.

Avtomatizaciya osobenno polezna, kogda sessiya menyayet neskoljko oblastej pamyati: `Документация/`, `Глоссарий/`, `Инструменты/`, `Планирование/` i `Журнал/`.

## Komanda zapuska

```bash
python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --commit-message-file <путь-к-файлу-сообщения> \
  --codex-thread-id <корневой-CODEX_THREAD_ID>
```

Po umolchaniyu proverka chitayet `git status --short --untracked-files=all` cherez `git -c core.quotepath=false`, chtobyi puti na kirillice sravnivalisj s razdelom `## Повлиял на файлы`, a novyiye katalogi raskryivalisj do konkretnyikh fajlov. Yavnaya Markdown-ssyilka na susjhestvuyusjhij katalog ogranichenno pokryivayet toljko yego potomkov; skhodnyij strokovyij prefiks i sosednij katalog ne pokryivayutsya.

Globaljnyiye fajlovyiye proverki ispoljzuyut obsjhij inventarj [fum-proyektnyiye-fajlyi](../fum-proyektnyiye-fajlyi/SKILL.md). Poetomu `.build`, `.swiftpm`, katalogi kyeshej, `.obsidian/plugins` i `.obsidian/themes` ne stanovyatsya vkhodami proverki ssyilok, voprosno-otvetnyikh materialov ili navigacii zaprosov. Isklyuchyonnyij fajl ne mozhet sdelatj ssyilku na otsutstvuyusjhij proyektnyij dokument formaljno korrektnoj.

Dlya izolirovannoj proverki fajlov i ssyilok bez Git-sostoyaniya mozhno ispoljzovatj:

```bash
python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py \
  --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_краткое-название-запроса]>/запрос.md \
  --skip-git-status
```

## Chto proveryayetsya

- Obsjhaya struktura prokhodit `fum-struktura-papok-zaprosov`: kataloga `Запросы/` net, neposredstvenno v `Журнал/` iz Markdown-fajlov dopustim toljko `README.md`, a kazhdaya papka zaprosa imeyet obyazateljnyij vremennoj prefiks `YYYY-MM-DD_HH-MM-SS_MSK`, obyazateljnyij `запрос.md` i neobyazateljnyij katalog `материалы/`. U novoj rabochej sessii obyazatelen takzhe sosednij `отчёт.md`; yego otsutstviye dopustimo toljko u istoricheskogo zaprosa, dlya kotorogo otchyot ne susjhestvoval do migracii.
- Identichnostj, data i korotkoye nazvaniye zaprosa berutsya toljko iz imeni roditeljskoj papki; zagolovok sootvetstvuyet etomu imeni. Nachinaya s imeni `2026-07-02_23-01-25_MSK_обновить-правило-именования-запросов` korotkoye nazvaniye dolzhno nachinatjsya s glagola v infinitive, a istoricheskiye zaprosyi do etogo pravila ostayutsya dopustimyimi dlya obratnoj sovmestimosti.
- Nachinaya s imeni `2026-07-14_02-31-47_MSK_добавлять-идентификатор-сеанса-Codex`, rovno odin razdel `## Идентификатор сеанса Codex` soderzhit yedinstvennuyu nepustuyu stroku s korrektnyim `Codex-Thread-ID`; obyazateljnyij `--codex-thread-id` sovpadayet s identifikatorom kornevoj zadachi, a obyazateljnyij `--commit-message-file` - s poslednim odnoimyonnyim Git trailer tela soobsjheniya.
- Razdel `## Навигация по запросам` tekusjhego zaprosa ukazyivayet na praviljnyiye predyidusjhij i sleduyusjhij `Журнал/*/запрос.md`, a sosednij zapros ssyilayetsya obratno. Ssyilki sopostavlyayutsya po polnostjyu razreshyonnoj celi, a ne po obsjhemu basename `запрос.md`.
- Ryadom s `запрос.md` susjhestvuyet `отчёт.md` so ssyilkoj na sosednij zapros. Nachinaya s imeni `2026-07-23_14-47-43_MSK_включать-профиль-времени-в-отчёты-журнала` otchyot soderzhit razdel `## Профиль времени выполнения`, tablicu s tochnyimi kolonkami `Стадия | Длительность | Границы и способ измерения`, ne meneye dvukh nepustyikh strok stadij i stroku `Граница профиля:`. Nachinaya s imeni `2026-07-27_16-12-29_MSK_учитывать-все-проверочные-вызовы-в-профиле-времени` tot zhe razdel soderzhit podrazdel `### Прямые запуски проверок`, tablicu s tochnyimi kolonkami `Вызов | Длительность | Результат` i stroku `Общее время прямых запусков проверок:`. Kazhdyij pryamoj zapusk testa ili proverki, vklyuchaya neuspeshnyij, prervannyij i povtornyij, zanimayet otdeljnuyu stroku; dliteljnostj zapisyivayetsya neotricateljnyim chislom sekund s zapyatoj ili tochkoj v roli desyatichnogo razdelitelya, a rezuljtat nachinayetsya so statusa `успешно`, `неуспешно`, `прервано` ili `не завершено`. Itog raven arifmeticheskoj summe dliteljnostej vsekh strok dazhe pri perekryitii zapuskov. Odin pryamoj vyizov sostavnoj smoke-proverki uchityivayetsya odin raz; yeyo vlozhennyiye shagi mogut byitj pokazanyi kak detalizaciya, no ne dubliruyut vklad v summu pryamyikh zapuskov. Nachinaya s imeni `2026-08-04_20-45-26_MSK_формировать-отчёты-о-запусках-тестов` proverka dopolniteljno vyizyivayet [fum-otchyotyi-o-zapuskakh-proverok](../fum-otchyotyi-o-zapuskakh-proverok/SKILL.md): zakryityij otchyot obyazan pobajtovo sovpadatj s khyeshirovannyim snimkom i vsemi fakticheskimi JSON-zapisyami, a perekhodnyij zhurnal obyazan otsutstvovatj. Otkryityij predprosmotr mozhet promezhutochno susjhestvovatj mezhdu vyizovami, no strogaya proverka prinimayet yego toljko pri nalichii khotya byi odnoj zapisi `выполняется`; novaya aktivnaya zapisj skhemyi `fum.test-run.v3` pri etom obyazana sokhranyatj `план: null`, pustyiye nablyudeniya, zakryityij shestipolevoj profilj i pustyiye terminaljnyiye polya, dazhe yesli vneshnij capability-konvert smoke-check uzhe soderzhit analiticheskij plan vyibrannogo profilya. Istoricheskiye v1/v2 ostayutsya chitayemyimi formatami, a boleye ranniye otchyotyi sokhranyayut ruchnoj istoricheskij kontrakt.
- Tekusjhiye `запрос.md` i `отчёт.md` ne soderzhat marker `<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->`; bukvaljnoye sovpadeniye vnutri doslovnogo razdela `## Текст запроса` ne pereinterpretiruyetsya i ne schitayetsya nezavershyonnoj zagotovkoj.
- Razdel `## Использованные инструменты` prisutstvuyet, soderzhit spisok i ssyilku na [reyestr sistemnyikh prilozhenij i instrumentov](../reyestr-sistemnyikh-prilozhenij-i-instrumentov.md). Nachinaya s imeni `2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex` obsjhaya zapisj `Codex - версия не раскрывается средой` otklonyayetsya: prilozheniye, runtime, CLI, modelj i kontraktyi agentskoj sessii dolzhnyi byitj kvalificirovanyi razdeljno. Nachinaya s imeni `2026-07-17_10-25-41_MSK_предотвращать-смещение-времени-сессий` razdel obyazan fiksirovatj ispoljzovaniye `fum-moskovskoye-vremya-rabochej-sessii`.
- Razdel `## Повлиял на файлы` soderzhit lokaljnyiye Markdown-ssyilki na zatronutyiye susjhestvuyusjhiye fajlyi, vklyuchaya tekusjhij `запрос.md` i sosednij `отчёт.md`. Massovoye izmeneniye mozhet yavno nazvatj susjhestvuyusjhij katalog i tem samyim pokryitj toljko yego susjhestvuyusjhikh potomkov. Dlya otsutstvuyusjhej posle tekusjhej sessii tochnoj celi ispoljzuyetsya stroka `- Удалённый файл: \`<putj>\``, для удалённых непосредственных файлов остающегося каталога — `- Удалённые непосредственные файлы каталога: \`<путь>/\``, a dlya celikom udalyonnogo dereva — `- Удалённое поддерево: \`<putj>/\``. Существующий обычный файл, снятый только с Git-учёта и сохранённый как локальное состояние, указывается строкой `- Снят с Git-учёта и сохранён локально: \`<путь>\``; proverka trebuyet exact staged deletion i sovpadeniye puti s Git ignore-pravilom. Marker neposredstvennyikh fajlov trebuyet susjhestvuyusjhij katalog i ne pokryivayet vlozhennyiye puti; udalyonnoye podderevo obyazano otsutstvovatj, nakhoditjsya vnutri repozitoriya i pokryivayet toljko sobstvennyikh potomkov.
- Aktivnyiye lokaljnyiye Markdown-ssyilki vo vsyom repozitorii ukazyivayut na susjhestvuyusjhiye celi, ostayutsya vnutri repozitoriya, a registr kazhdogo komponenta puti sovpadayet s realjnyim imenem fajla ili kataloga. Doslovnyij razdel `## Текст запроса` kanonicheskogo `Журнал/<stem>/запрос.md` schitayetsya syiroj oblastjyu proiskhozhdeniya i ne pereinterpretiruyetsya posle perenosa fajla; ssyilki do i posle nego ostayutsya aktivnyimi. POSIX-absolyutyi, Windows/UNC-puti, `file://` i otnositeljnyiye vyikhodyi za korenj otklonyayutsya; obyichnyiye vneshniye URL ne proveryayutsya.
- Kazhdyij fajl `Вопросы и ответы/*.md`, krome README, soderzhit nepustoj razdel `## Вопрос`, poslednij soderzhateljnyij simvol kotorogo raven `?`. Eto formaljnaya zasjhita nablyudayemogo priznaka, a ne lingvisticheskoye dokazateljstvo voprositeljnoj semantiki.
- Zatronutyiye Markdown-fajlyi, krome kanonicheskikh `Журнал/*/запрос.md`, ne soderzhat pokhozhij na poljzovateljskij meta-zapros o pravilakh [pamyati FUM](../../Glossarij/pamyatj-FUM.md), poryadke [rabochej sessii](../../Glossarij/rabochaya-sessiya.md), `AGENTS.md` ili papkakh zaprosov bez ssyilki na konkretnyij iskhodnyij `запрос.md`.
- Zatronutyiye Markdown-fajlyi, krome kanonicheskikh `Журнал/*/запрос.md`, ne nachinayutsya so spravochnogo bloka proiskhozhdeniya: `Источники требований`, `Источники`, `Опорные документы`, `Опорные материалы`, `Внешний материал`, `Затронутая документация` i pokhozhiye bloki dolzhnyi idti posle osnovnogo soderzhaniya pered `FUM-MD-RECENCY`.
- Zatronutyiye Markdown-fajlyi ne soderzhat Mermaid-podpisej uzlov, kotoryiye nachinayutsya s Markdown-markera spiska vrode `1. `, `1) `, `- `, `* ` ili `+ `, potomu chto Obsidian mozhet otobrazhatj takiye uzlyi kak `Unsupported markdown: list`.
- Avtomatizaciya `fum-svezhestj-markdown` podtverzhdayet svezhestj sluzhebnyikh recency-metok i indeksa `Индексы/markdown-файлы-по-времени-редактирования.md`, yesli etot lokaljnyij instrument yestj v repozitorii.
- Vse puti iz tekusjhego `git status --short` perechislenyi tochno libo vkhodyat v yavno nazvannyij susjhestvuyusjhij katalog, mnozhestvo udalyonnyikh neposredstvennyikh fajlov ostayusjhegosya kataloga ili otsutstvuyusjheye udalyonnoye podderevo iz razdela `## Повлиял на файлы`; lishniye vremennyiye fajlyi, kyeshi, sosedniye puti i otladochnyiye artefaktyi vyizyivayut oshibku.

## Proverki avtomatizacii

Lokaljnyiye testyi zapuskayutsya bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p 'test_*.py'
```

V tablice pryamyikh zapuskov ekranirovannyij Markdown-razdelitelj `\|` ostayotsya chastjyu yachejki. Podrazdel, tablica ili itog vnutri fenced code ili HTML-kommentariya ne schitayutsya strukturoj otchyota. Arifmetika i diagnostika itoga sokhranyayut fakticheskuyu desyatichnuyu razryadnostj vsekh strok, a ne globaljnuyu tochnostj Decimal po umolchaniyu.

Testyi fiksiruyut bazovyij kontrakt: uspeshnaya sessiya prokhodit pri perechislennyikh izmenyonnyikh fajlakh; identichnostj i istoricheskiye vremennyiye granicyi berutsya iz imeni roditeljskoj papki; papka bez polnogo vremennogo prefiksa otklonyayetsya; navigaciya proveryayet tochnyiye celi pri odinakovom basename; novyiye korotkiye nazvaniya nachinayutsya s infinitiva; nezapolnennyij marker shablona vne doslovnogo teksta zaprosa otklonyayetsya; istoricheskaya obsjhaya zapisj versii Codex i istoricheskij otchyot bez profilya vremeni sokhranyayut obratnuyu sovmestimostj; bukvaljnyij vopros s `?` dopustim. Novyij zhurnaljnyij profilj prinimayet otdeljnyiye stroki povtornyikh zapuskov so statusami uspekha, neuspekha, preryivaniya i nezavershyonnosti, tochnuyu arifmeticheskuyu summu ikh dliteljnostej i aktivnuyu v3-zapisj toljko s `план: null`, pustyimi nablyudeniyami, zakryityim shestipolevyim profilem i terminaljnyimi `null`; istoricheskiye v1/v2 ostayutsya chitayemyimi. Otsutstviye podrazdela, tablicyi, strok ili itoga, nevernaya yedinica dliteljnosti, neizvestnyij status i nesovpadayusjhaya summa dayut oshibku. Dlya novyikh zaprosov otsutstvuyusjhiye obyazateljnyiye argumentyi, otsutstvuyusjhij, perenesyonnyij na druguyu stroku, nekorrektnyij ili dochernij `Codex-Thread-ID`, povtornyij razdel, lishnij tekst, psevdotrejler, otsutstvuyusjhij, dublirovannyij ili nesovpadayusjhij nastoyasjhij trailer v tele kommita, nekvalificirovannaya zapisj versii, otsutstviye `fum-moskovskoye-vremya-rabochej-sessii` posle zakreplyonnoj granicyi, otsutstviye sosednego otchyota ili obyazateljnogo tablichnogo profilya vremeni, bitaya ili registronevernaya Markdown-ssyilka, voprosno-otvetnyij fajl bez voprosa ili bez konechnogo `?`, vozmozhnyij nezavedyonnyij meta-zapros bez ssyilki na konkretnyij `Журнал/*/запрос.md`, verkhnij spravochnyij blok proiskhozhdeniya, Mermaid-podpisj uzla s Markdown-markerom spiska, ustarevshaya recency-proverka i neozhidannyij putj v Git-sostoyanii dayut oshibku. Marker dejstviteljno udalyonnogo fajla uchastvuyet pri proverke Git-sostoyaniya bez fiktivnoj ssyilki, a dlya susjhestvuyusjhej celi otklonyayetsya. Otdeljnaya fikstura podtverzhdayet, chto `.build/checkouts/vendor/README.md`, `.swiftpm` i kyeshi ne uchastvuyut v fajlovyikh obkhodakh i ne skryivayut bityiye proyektnyiye ssyilki.

## Granica avtomatizacii

Skript proveryayet strukturnuyu svyaznostj rabochej sessii, no ne podmenyayet smyislovuyu proverku dokumentacii. Agent po-prezhnemu otvechayet za korrektnostj trebovanij, publikacionnuyu chistotu soderzhaniya, polnotu spiska instrumentov, umestnostj zatronutyikh fajlov i kachestvo kommita.

Mashinnyij zhurnal pozvolyayet dokazatj tochnoye sootvetstviye zafiksirovannyikh zapuskov, snimka i Markdown, no ne mozhet obnaruzhitj process, namerenno zapusjhennyij v obkhod obyazateljnoj obyortki. Za soblyudeniye granicyi zapuska otvechayut korenj i subagentyi. Pri perekryitii pryamyikh zapuskov ikh arifmeticheskaya summa yavlyayetsya agregirovannyim call-time, a ne kalendarnyim wall-clock; obsjhiye granicyi sessii i stadij po-prezhnemu opisyivayutsya otdeljno v osnovnoj tablice profilya.

Proverka lokaljnyikh Markdown-ssyilok i registra ikh putej vyipolnyayetsya po vsem Markdown-fajlam repozitoriya, chtobyi oshibka, skryitaya na nechuvstviteljnoj k registru fajlovoj sisteme, ne ostavalasj v pamyati do sluchajnoj pravki konkretnogo fajla.

Proverka kataloga `Вопросы и ответы/` takzhe vyipolnyayetsya globaljno, a ne toljko po spisku fajlov tekusjhej sessii. Ona proveryayet formaljnyij bukvaljnyij priznak voprosa i ne ocenivayet kachestvo ili polnotu soderzhateljnogo otveta.

Proverka meta-zaprosov yavlyayetsya evristikoj. Ona isjhet formulirovki o voprose, utochnenii, otvete ili proverke poljzovatelya v kontekste pravil pamyati, poryadka rabochej sessii, `AGENTS.md` ili papok zaprosov; eto rannij signal, a ne dokazateljstvo, chto zapros dejstviteljno propusjhen.

Proverka Git-sostoyaniya sravnivayet toljko puti. Ona ne reshayet, nuzhno li vklyuchatj konkretnoye soderzhimoye v kommit; pered staging agent vsyo ravno dolzhen prosmotretj diff i isklyuchitj sekretyi, lokaljnoye sostoyaniye i mashinnyij musor.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-14 18:59:37 MSK — Isklyuchitj dublirovaniye polnoj regressii](../../Zhurnal/2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-06 20:56:43 MSK — Optimizirovatj rabotu testov](../../Zhurnal/2026-08-06_20-56-43_MSK_optimizirovatj-rabotu-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 20:45:26 MSK - Formirovatj otchyotyi o zapuskakh testov](../../Zhurnal/2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)
- [iskhodnyij zapros 2026-08-04 15:48:19 MSK - Shablonizirovatj fajlyi zaprosov i otchyotov](../../Zhurnal/2026-08-04_15-48-19_MSK_shablonizirovatj-fajlyi-zaprosov-i-otchyotov/zapros.md)
- [iskhodnyij zapros 2026-07-27 16:12:29 MSK - Uchityivatj vse proverochnyiye vyizovyi v profile vremeni](../../Zhurnal/2026-07-27_16-12-29_MSK_uchityivatj-vse-proverochnyiye-vyizovyi-v-profile-vremeni/zapros.md)
- [iskhodnyij zapros 2026-07-23 14:47:43 MSK - Vklyuchatj profilj vremeni v otchyotyi zhurnala](../../Zhurnal/2026-07-23_14-47-43_MSK_vklyuchatj-profilj-vremeni-v-otchyotyi-zhurnala/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:39:29 MSK - Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)
- [iskhodnyij zapros 2026-07-10 05:59:58 MSK - Utochnitj uchyot versij ChatGPT i Codex](../../Zhurnal/2026-07-10_05-59-58_MSK_utochnitj-uchyot-versij-ChatGPT-i-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-10 06:28:42 MSK - Ispravitj klassifikaciyu zaprosa](../../Zhurnal/2026-07-10_06-28-42_MSK_ispravitj-klassifikaciyu-zaprosa/zapros.md)
- [iskhodnyij zapros 2026-07-14 02:31:47 MSK - Dobavlyatj identifikator seansa Codex](../../Zhurnal/2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-17 10:25:41 MSK - Predotvrasjhatj smesjheniye vremeni sessij](../../Zhurnal/2026-07-17_10-25-41_MSK_predotvrasjhatj-smesjheniye-vremeni-sessij/zapros.md)
- [iskhodnyij zapros 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi](../../Zhurnal/2026-07-21_05-39-00_MSK_sdelatj-sluzhebnyiye-generatoryi-vosproizvodimyimi/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 14:29:42 MSK -->
<!-- content-sha256: sha256:6d2ff33e1a73a1c03eaf5934ac6d67e9e44848788aa937e6de3bd5c9470d9251 -->
<!-- FUM-MD-RECENCY:END -->
