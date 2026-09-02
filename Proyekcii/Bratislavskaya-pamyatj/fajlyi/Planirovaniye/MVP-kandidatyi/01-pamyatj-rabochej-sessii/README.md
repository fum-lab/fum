# MVP-kandidat: pamyatj rabochej sessii

## Pasport

- Status: [MVP-kandidat](../../../Glossarij/MVP-kandidat.md).
- Gorizontyi dorozhnoj kartyi: [svyaznaya pamyatj proyekta](../../dorozhnaya-karta.md) i [vosproizvodimyiye avtomatizacii](../../dorozhnaya-karta.md).
- Poljzovatelj: uchastnik proyekta ili agent, kotoryij menyayet [pamyatj FUM](../../../Glossarij/pamyatj-FUM.md).
- Minimaljnyij rezuljtat: poluavtomaticheskij kontur [rabochej sessii](../../../Glossarij/rabochaya-sessiya.md), kotoryij pomogayet sozdatj [papku zaprosa](../../../Glossarij/papka-zaprosa.md), zafiksirovatj [iskhodnyij zapros](../../../Glossarij/iskhodnyij-zapros.md), obnovitj navigaciyu, sozdatj otchyot v [zhurnale rabot](../../../Glossarij/zhurnal-rabot.md), proveritj ssyilki i podgotovitj osmyislennyij kommit.

## Produktovaya ideya dlya zapuska

Produkt: **Pomosjhnik rabochej sessii FUM** - lokaljnyij master zaversheniya rabotyi nad pamyatjyu proyekta.

Pervyij poljzovatelj - uchastnik proyekta ili agent, kotoryij uzhe menyayet repozitorij FUM i khochet ne derzhatj v golove vsyu rutinu sessii: papku zaprosa, navigaciyu, otchyot, spisok zatronutyikh fajlov, proverku i kommit.

Pervyij scenarij zapuska: poljzovatelj peredayot tekst zaprosa i zapuskayet lokaljnyij scenarij zaversheniya sessii. Pomosjhnik sozdayot ili proveryayet `Журнал/<имя-папки-запроса>/` s obyazateljnyim vremennyim prefiksom, obnovlyayet navigaciyu sosednikh `запрос.md`, gotovit `отчёт.md`, sobirayet izmenyonnyiye fajlyi, zapuskayet proverku svyaznosti i pokazyivayet sostav budusjhego kommita.

Sostav pervogo reliza:

- komanda ili scenarij `fum session` dlya sozdaniya i proverki paketa rabochej sessii;
- shablon papki zaprosa i yeyo `запрос.md` s navigaciyej, kornevyim `Codex-Thread-ID`, instrumentami, proverkami i spiskom zatronutyikh fajlov;
- shablon `отчёт.md` s chelovecheskim rezyume izmeneniya;
- podgotovka fajla soobsjheniya kommita s tochnyim zaprosom, opisaniyem sdelannogo i sovpadayusjhim `Codex-Thread-ID` v tele;
- otchyot o gryaznyikh fajlakh: chto otnositsya k tekusjhej sessii, a chto uzhe byilo izmeneno do neyo;
- zapusk `fum-svyaznostj-rabochej-sessii` kak finaljnoj lokaljnoj proverki.

Kriterij gotovnosti k zapusku: odnu realjnuyu rabochuyu sessiyu FUM mozhno zakryitj cherez pomosjhnika tak, chtobyi navigaciya zaprosov, zhurnal, spisok instrumentov, ssyilki i proverka svyaznosti ne trebovali ruchnogo ispravleniya formyi.

## Pochemu eto mozhet byitj pervyim MVP

Etot kandidat delayet produktom samu disciplinu pamyati FUM. Sejchas rabochaya sessiya uzhe soderzhit povtoryayemyij cikl: prinyatj zapros, najti istochniki, izmenitj dokumentyi, svyazatj fajlyi, proveritj rezuljtat i zakommititj. Minimaljnyij produkt mozhet prevratitj etot cikl iz ruchnogo pravila v nablyudayemuyu avtomatizaciyu.

Takoj MVP srazu polezen proyektu: kazhdaya sleduyusjhaya sessiya stanovitsya deshevle, svyaznostj pamyati povyishayetsya, a oshibki vrode propusjhennoj ssyilki na sleduyusjhij zapros ili nezapolnennogo zhurnala stanovyatsya proveryayemyimi.

## Proveryayemyij MVP

Minimaljnyij variant dolzhen umetj:

- sozdatj papku v `Журнал/` s obyazateljnyim vremennyim prefiksom i vlozhennyij `запрос.md` s razdelom navigacii i doslovnyim tekstom zaprosa;
- zapisatj v fajl zaprosa `Codex-Thread-ID` kornevoj poljzovateljskoj zadachi i ne podmenyatj yego identifikatorom subagenta;
- obnovitj ssyilku na sleduyusjhij zapros v prezhnem poslednem fajle;
- sozdatj `отчёт.md` v toj zhe papke zaprosa;
- sobratj spisok izmenyonnyikh fajlov tekusjhej sessii;
- proveritj otnositeljnyiye Markdown-ssyilki v izmenyonnyikh fajlakh;
- pokazatj pered kommitom, kakiye fajlyi budut vklyuchenyi, a kakiye yavlyayutsya postoronnimi izmeneniyami.
- sobratj i proveritj telo soobsjheniya kommita s tem zhe `Codex-Thread-ID`, posle chego peredatj proverennyij fajl v `git commit -F`.

## Kriterii priyomki

- Lokaljnaya proverka zapuskayetsya bez setevyikh vyizovov i sekretov.
- Proverka ne izmenyayet fajlyi bez yavnogo dejstviya poljzovatelya ili agenta.
- Otchyot yavno razlichayet fajlyi tekusjhej sessii i uzhe susjhestvuyusjhiye gryaznyiye izmeneniya.
- Minimaljnaya fikstura s dvumya zaprosami podtverzhdayet obnovleniye navigacii po zaprosam.
- Oshibki ssyilok, otsutstvuyusjhego zhurnala ili nesovpadayusjhego vremennogo prefiksa vyidayutsya kak ponyatnyij spisok problem.

## Ne vkhodit v pervyij variant

- Polnostjyu avtonomnoye izmeneniye smyisla dokumentacii.
- Avtomaticheskij kommit bez pokaza sostava izmenenij.
- Upravleniye vneshnimi servisami, sekretami ili privatnyimi materialami.

## Zavisimosti

- Pravila [rabochikh sessij](../../../AGENTS.md).
- Susjhestvuyusjhaya struktura papok zaprosov v `Журнал/`, a takzhe `Документация/`, `Глоссарий/` i `Планирование/`.
- Praktika lokaljnyikh proverok iz [vosproizvodimyikh avtomatizacij FUM](../../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md).

## Riski

- Kontur mozhet statj slishkom byurokraticheskim, yesli budet trebovatj lishnego vvoda dlya prostyikh pravok.
- Avtomatizaciya ne dolzhna podmenyatj inzhenernoye ponimaniye izmeneniya; ona fiksiruyet formu i proverki, no ne reshayet smyislovoj vyibor sama.
- Nuzhno akkuratno obrasjhatjsya s uzhe susjhestvuyusjhimi nezakommichennyimi izmeneniyami poljzovatelya.

## Pervyij eksperiment

Sdelatj lokaljnuyu proverku, kotoraya na testovoj kopii zhurnala podtverzhdayet chetyire usloviya: imya kazhdoj papki imeyet obyazateljnyij vremennoj prefiks, novyij zapros ssyilayetsya na predyidusjhij, prezhnij poslednij zapros ssyilayetsya na novyij, a otchyot nakhoditsya v toj zhe papke. Posle etogo dobavitj proverku otnositeljnyikh Markdown-ssyilok dlya izmenyonnyikh fajlov.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-14 02:31:47 MSK - Dobavlyatj identifikator seansa Codex](../../../Zhurnal/2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md)

## Opornyiye materialyi

- [Modelj pamyati FUM](../../../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Zhurnal rabot](../../../Zhurnal/README.md)
- [AGENTS.md](../../../AGENTS.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:4bfb6216afc2aaea966adfedbd1f993bd0d88c6ca8cdc7ec8f0872baca678dff -->
<!-- FUM-MD-RECENCY:END -->
