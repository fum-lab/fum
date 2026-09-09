# Peredacha realizacii proverki obyazateljstv

Rabota peredayotsya vidimoj zadache Codex po rasporyazheniyu kornevoj zadachi. Realizaciya yesjhyo ne vyipolnena; kommit, priyomka i profilj ne zayavlenyi.

## Sokhranyonnyij rezuljtat

- Sobstvennoye derevo i vetka naznachenyi kornem; iskhodnyij i tekusjhij HEAD: `ba6f1c7907478a638c9f0fda6d93f6da37a7fcf5`, ref `refs/heads/codex/защита-обязательств-01a07d3d`.
- Kanonicheskaya komanda `start` sozdala tekusjhiye zapros i otchyot, obnovila navigaciyu prezhnego poslednego zaprosa `2026-09-09_09-50-11_MSK_устранить-гонку-подготовки-кэша-преобразователя` i `Журнал/README.md`.
- Sozdan chernovoj sinteticheskij nabor [test_obyazateljstva_zadachi.py](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_obyazateljstva_zadachi.py). On ne zapuskalsya: yedinstvennaya popyitka cherez v4-obyortku zavershilasj do registracii i dochernego processa oshibkoj «podmodulj ne materializovan v svoyom kataloge»; nablyudayemaya dliteljnostj vyizova instrumenta 0,999 s. Mashinnyikh zapisej zapuska net, poetomu eto ne RED po kontraktu. Nuzhna materializaciya zakreplyonnogo LinguisticKit v sobstvennom dereve shtatnyim lokaljnyim marshrutom, zatem nastoyasjhij RED.
- Susjhestvuyusjhiye guard, prezhniye testyi, SKILL, pravila i reyestryi ne menyalisj. Indeks i Git-istoriya ne menyalisj. Obsjhij smoke, realjnaya proyekciya, sborka, commit i push ne vyipolnyalisj.
- Zapros i otchyot ostayutsya otkryityimi zagotovkami; recency i indeks svezhesti yesjhyo ne obnovlenyi. Kontroljnyij kommit poka ne gotov.

## Predlozhennyij kornyu kontrakt

CLI sokhranyayet prezhniye flagi, no `--план` stanovitsya neobyazateljnyim: ustojchivyij putj `Планирование/задачи/<корневой UUID>/обязательства.json` soderzhit pole `план_этапа`. Yavnyij plan ne dolzhen obkhoditj reyestr. Reyestr imeyet tochnyiye polya `схема: fum.обязательства-задачи.2`, `задача`, `исходный_коммит` (dostizhimyij polnyij OID do genezisa), `план_этапа`, `обязательства`.

Element obyazateljstv: `идентификатор`, `родитель` (null libo ID), `основание` (`коммит`, `запрос`, `цитата`), `вид_результата` (`реализация` libo `документ`), `карточка` (null libo FUM-STEP-NNNN), `приёмки` (pervonachaljno pustoj spisok). Proiskhozhdeniye, identichnostj, vid rezuljtata, roditelj, kartochka i iskhodnyij commit neizmenyayemyi mezhdu dostizhimyimi versiyami fiksirovannogo puti. Novyiye obyazateljstva dobavlyayutsya; udaleniye, novyij genezis i oslableniye prezhnikh zapresjhenyi. Prezhniye versii nuzhno nakhoditj po realjnoj Git-istorii, vklyuchaya merge i vremennoye udaleniye fajla, a ne doveryatj toljko zayavlennomu predshestvenniku. Kartochka sama ne dayot polnomochij: obyazateljstvo opirayetsya na realjnuyu doslovnuyu komandu svoyej kornevoj zadachi v dostizhimom Git-commit.

Plan `fum.продолжение-задачи.2` sokhranyayet prezhniye polya, kazhdoj rabote dobavlyayetsya `обязательство`. Zaversheniye rabotyi etapa ne zavershayet roditeljskoye obyazateljstvo. Predlozhennaya priyomka: `запрос`, `запуск` (UUID), `результаты` (massiv `путь`, `sha256`). Budusjhij OID ne vyidumyivayetsya: resheniye chitayet fakticheskiye HEAD, kartochki i zakryityiye v4-svideteljstva. Tochnuyu svyazj proverennogo snimka s rezuljtatami yesjhyo trebuyetsya realizovatj i nezavisimo proveritj; odnoj stroki «gotovo» ili nenulevogo spiska putej nedostatochno.

Dlya sovmestimosti v1 ostayotsya chitayemyim istoricheskim formatom; postoyannaya zadacha ne poluchayet terminaljnyij uspekh po v1 bez ustojchivogo reyestra. Razovaya istoricheskaya zadacha i inspekciya ne dolzhnyi besprichinno lomatjsya. Rabochij reyestr nuzhen dlya sleduyusjhego etapa i novoj komandyi ostanovitjsya; terminaljnoye zaversheniye trebuyet podtverzhdeniya realjnogo HEAD. Novaya yavnaya ostanovka dolzhna dejstvovatj bez ozhidaniya kommita i nezavisimo ot ostatka. Tochnyij bezopasnyij ogranichennyij sintaksis ostanovki i ozhidaniya yesjhyo ne zavershyon: proizvoljnaya citata ne schitayetsya ostanovkoj, universaljnyij NLP ne zayavlyayetsya.

## Sleduyusjhaya realizaciya i riski

1. Materializovatj sobstvennyij podmodulj, provesti i sokhranitj nastoyasjhij RED chernovyikh testov cherez etu zhe novuyu v4-papku.
2. Realizovatj stroguyu skhemu, chteniye realjnoj istorii, neizmennostj obyazateljstv, realjnyiye kartochki po TOML card_id/status i privyazku vsekh rabot etapa. Aktivnyiye 0155/0156 i roditelj nablyudenij ne pogashayutsya gotovyim kontraktom ili planom. Vse dostizhimyiye roditeljskiye vetvi uchityivayutsya pri merge; neljzya vyibratj lishj udobnyij predok.
3. Proveritj dokazateljstva bez zapisi. V module otchyotov dostupnyi chistyiye `проверить_запись`, `проверить_историю_раундов`, `ожидаемый_снимок_раундов`, `построить_план_раундов`, `сформировать_блок_истории`, `границы_управляемого_блока`, `сформировать_закрытый_маркер`. Ikh mozhno ispoljzovatj nad bajtami Git bez raspakovki v checkout. Zakryityij snimok ne vsegda oznachayet «gotov»: otdeljno trebuyetsya verdikt raundov i korrektnyij uspeshnyij zapusk.
4. Dodelatj testyi: tekusjhij chernovik soderzhit lishj osnovnoj nabor. Nuzhnyi pozitivnyij istoricheskij priyomochnyij commit s neizmennyimi rezuljtatami v novom etape; realjnaya nedostizhimaya commit-vetvj, merge s poteryannyim obyazateljstvom, symlink/dublikatyi/registr, otkryityij ili poddeljnyij otchyot, skryitaya smena iskhodnyikh fajlov posle testa, ostanovka kak citata vnutri soobsjheniya, ozhidaniye pri nezavisimom dostupnom ostatke. Test roditelya i rebyonka sejchas menyayet vkhod posle sinteticheskogo zakryitiya, poetomu dlya strogoj proverki otpechatka yego fiksturu nuzhno podgotovitj do zakryitiya; eto ne povod oslablyatj guard.
5. GREEN vsego zatronutogo avtonomnogo nabora, vosproizvodimyij profilj, izmerennoye resheniye ob optimizacii, obnovleniye lokaljnogo SKILL/kontrakta i otchyota. Zatem chestnyij promezhutochnyij dopusk, sobstvennyij commit i push po prezhnemu razresheniyu kornya. Polnyij smoke i realjnuyu proyekciyu vyipolnyayet korenj posle integracii.

Minimaljnaya mashinnaya garantiya ogranichena strukturoj i dokazuyemyim proiskhozhdeniyem. Polnota pervonachaljnogo perevoda yestestvennyikh komand v obyazateljstva, dostatochnostj kriteriyev priyomki i semanticheskaya istinnostj realizacii ostayutsya predmetom nezavisimoj proverki. Guard ne yavlyayetsya perekhvatchikom Codex final: Stop-adapter realizuyet korenj otdeljno.

## Istochnik

- [Doslovnyiye tekusjhiye komandyi](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 12:53:23 MSK -->
<!-- content-sha256: sha256:af9e965802bba62f2ae46ae13055d4cf84a833386568f19b796f4d6e521ce65a -->
<!-- FUM-MD-RECENCY:END -->
