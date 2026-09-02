# Otchyot 2026-08-24 15:31:12 MSK - Dekompozirovatj AGENTS MD

Kornevoj `AGENTS.md` preobrazovan v polnostjyu zagruzhayemoye kompaktnoye yadro s polozhiteljnyim mashinnyim marshrutizatorom. Vse dejstvuyusjhiye normyi iskhodnogo fajla sokhranenyi v yedinstvennom obyazateljnom nabore iz kornya i kanonicheskikh tematicheskikh fajlov `Правила/агентов/`; neaktivnyij prezhnij FIFO/pool-konvejyer izolirovan kak proiskhozhdeniye bez polnomochij. Mashinnyij inventarj svyazyivayet kazhduyu iskhodnuyu yedinicu i kazhdoye pravilo so stabiljnyim identifikatorom, oblastjyu, prioritetom, triggerami i yedinstvennyim celevyim yakorem.

Itogovyij korenj zanimayet 3 451 token vosproizvodimoj ocenki `o200k_base` vmesto 25 782 tokenov polnogo iskhodnogo fajla. Eto sokrasjheniye na 22 331 token, ili 86,61 %. Obyichnaya dokumentacionnaya pravka zagruzhayet 10 647 tokenov, kodovaya — 9 524, a prostoj read-only-vopros — toljko 3 451; ni odin iz etikh scenariyev ne chitayet istoricheskij konvejyer libo polnyij mashinnyij inventarj.

## Metriki kornya

Iskhodnyij snimok vosproizvoditsya kak `92f34d52a76f584be8e60c9d1f6cf9920ffdf428:AGENTS.md`, Git blob `fea10e1c9473ca49275103df13726e0d0ab05525`, SHA-256 `a8e7675dbc181ae53e9266179d2759566113d49dfcfea8ebca8c1ad433dfe695`. Itogovyij SHA-256 kornya posle recency — `14fa0f9f7c692297946c414c1d839fd8d82cdbb24b24c4d25857a1e62fcdc1fc`.

Stroki poschitanyi kak `str.splitlines()`, Unicode-simvolyi — kak kodovyiye tochki Python, bajtyi — kak UTF-8. Tokenyi poluchenyi lokaljnyim rabotnikom tokenizatora VS Code/Copilot s kodirovkoj `o200k_base`; SHA-256 BPE-tablicyi — `d4f3aed4bede01e9379bb52edb9b4b54d13315eb8ff60fad510ece42c4c0038d`, rabotnika — `9179cb7c13590aff37510c4d002b5f6a23767f26731aaa4f9d4c2d3c62c34b01`. Eto vosproizvodimaya ocenka modeljnogo konteksta, a ne izmereniye billinga API.

| Metrika         | Do      | Posle  | Absolyutnoye sokrasjheniye | Sokrasjheniye |
| --------------- | ------- | -----: | --------------------: | ---------: |
| Stroki          | 265     |    107 |                   158 |    59,62 % |
| Unicode-simvolyi | 97 851  | 11 432 |                86 419 |    88,32 % |
| Bajtyi UTF-8     | 170 738 | 18 997 |               151 741 |    88,87 % |
| Tokenyi          | 25 782  |  3 451 |                22 331 |    86,61 % |

Lokaljnyij `codex-cli 0.149.1` do izmeneniya vklyuchal v modeljnyij vvod toljko pervyiye 32 768 bajt iskhodnogo `AGENTS.md`: obyortka imela 32 853 bajta i obryivalasj vnutri opisaniya istoricheskogo konvejyera. Posle dekompozicii `codex debug prompt-input` vernul vse 18 997 bajt kornya; SHA-256 izvlechyonnogo tela sovpal s rabochim fajlom pobajtno. Eto podtverzhdayet ne toljko sokrasjheniye, no i ustraneniye prezhnej nedostupnosti pravil za granicej zagruzki.

## Stoimostj tematicheskikh fajlov

V tablice privedena samostoyateljnaya stoimostj kazhdogo kanonicheskogo tematicheskogo Markdown-fajla posle recency. Ona ne vklyuchayet vsegda zagruzhayemyij korenj.

| Tema                                        | Stroki | Unicode-simvolyi | Bajtyi  | Tokenyi |
| ------------------------------------------- | -----: | --------------: | -----: | -----: |
| Pamyatj i dokumentaciya                       |     75 |           7 647 | 12 923 |  2 311 |
| Yazyik i kod                                  |     30 |           4 219 |  7 321 |  1 188 |
| Git i rabochaya sessiya                        |     21 |           1 528 |  2 392 |    492 |
| Lokaljnyiye navyiki i instrumentyi              |     78 |          11 556 | 19 906 |  3 223 |
| Proverki, kommit i publikaciya               |     54 |          10 137 | 17 273 |  2 921 |
| Zhurnal i proiskhozhdeniye                      |     36 |           4 741 |  7 946 |  1 472 |
| Planirovaniye, trebovaniya, voprosyi i sboi    |     63 |          11 750 | 20 544 |  3 359 |
| Istochniki, opisaniya i materialyi             |     42 |           5 172 |  8 776 |  1 558 |
| Obsidian, glossarij i prototipyi             |     69 |           7 239 | 12 036 |  2 207 |
| Vneshniye Git-zavisimosti                     |     27 |           3 417 |  5 625 |    951 |
| Istoricheskij konvejyer, toljko proiskhozhdeniye |    186 |          38 661 | 65 001 | 10 568 |

## Stoimostj marshrutov

Stoimostj marshruta — tokenyi tochnoj konkatenacii kornya i vozvrasjhyonnyikh marshrutizatorom fajlov cherez odin perevod stroki. Povtoryayusjhiyesya puti v obyyedinenii triggerov uchityivayutsya odin raz.

| Marshrut                        | Fajlov s kornem | Tokenyi  |
| ------------------------------ | --------------: | ------: |
| `только-чтение`                |               1 |   3 451 |
| `изменение`                    |               4 |   8 336 |
| `документация`                 |               2 |   5 762 |
| `код`                          |               2 |   4 639 |
| `инструменты`                  |               2 |   6 674 |
| `проверки`                     |               2 |   6 372 |
| `планирование`                 |               2 |   6 810 |
| `источники`                    |               2 |   5 009 |
| `obsidian-глоссарий-прототипы` |               2 |   5 658 |
| `git`                          |               3 |   6 864 |
| `внешние-git-зависимости`      |               4 |   7 815 |
| `публикация`                   |               3 |   6 864 |
| `правила`                      |              14 | 122 941 |

Isklyuchiteljnyij marshrut `правила` namerenno chitayet vse temyi, JSON-inventarj i navyik izmeneniya strukturyi; yego vyisokaya stoimostj platitsya toljko pri izmenenii samikh agentskikh pravil.

| Tipichnyij scenarij        | Obyyedineniye triggerov       | Fajlov s kornem | Tokenyi | Sokrasjheniye k polnomu iskhodniku |
| ------------------------ | --------------------------- | --------------: | -----: | -----------------------------: |
| Prostoj vopros/read-only | `только-чтение`             |               1 |  3 451 |                        86,61 % |
| Dokumentacionnaya pravka  | `изменение`, `документация` |               5 | 10 647 |                        58,70 % |
| Kodovaya pravka           | `изменение`, `код`          |               5 |  9 524 |                        63,06 % |
| Git/kommit               | `изменение`, `git`          |               4 |  8 336 |                        67,67 % |

## Struktura i marshrutizaciya

Korenj sokhranyayet normyi, narusheniye kotoryikh vozmozhno do predmetnogo vyibora: prioritet, fail-closed-marshrutizaciyu, yazyikovoye yadro, lokaljnostj navyikov, `manual-sequential-v1`, zapret samovoljnogo push, publikacionnuyu chistotu i neprikosnovennostj `.obsidian/graph.json`. Ostaljnyiye normyi raznesenyi po neperesekayusjhimsya temam bez kopirovaniya aktivnoj semantiki.

Agent do predmetnogo dejstviya opredelyayet vse podkhodyasjhiye triggeryi. Pri smeshannoj ili neodnoznachnoj zadache vyichislyayetsya bezopasnoye obyyedineniye marshrutov, kazhdyij vozvrasjhyonnyij Markdown-fajl polnostjyu chitayetsya do dejstviya. Neizvestnyij trigger, otsutstvuyusjhij ili podmenyonnyij fajl, nevernyij registr, lyuboj symlink-komponent libo vyikhod puti za checkout zakryivayet dejstviye otkazom. Izmeneniye pravil trebuyet polnogo nabora, inventarya i specialjnogo navyika.

Validator fiksiruyet 265 neperekryivayusjhikhsya iskhodnyikh yedinic i 209 smyislovyikh pravil. Kazhdaya yedinica pobajtovo privyazana k iskhodnyim diapazonam, a kazhdoye pravilo imeyet stabiljnyij ID, status, prioritet, oblastj, triggeryi, semanticheskij klyuch i yedinstvennyij celevoj yakorj. Iskhodnyij tekst ne dubliruyetsya: tochnyij snimok vosstanavlivayetsya iz commit i blob.

Codex avtomaticheski obnaruzhivayet toljko `AGENTS.override.md`, `AGENTS.md` i nastroyennyiye rezervnyiye imena po iyerarkhii ot kornya proyekta k rabochemu katalogu; proizvoljnyij linked Markdown instrukciyej ne stanovitsya. Poetomu obyazateljnostj tematicheskikh fajlov obespechivayut yavnyij kornevoj dogovor, mashinnyiye kommentarii `FUM-МАРШРУТ`, sovpadayusjhij JSON-manifest i komanda `маршрут`, a ne predpolozheniye ob avtozagruzke.

## TDD i proverki ekvivalentnosti

Razrabotka validatora nachalasj s RED: 12 otricateljnyikh fikstur padali i odna zavershalasj oshibkoj do realizacii. Pervyij GREEN vyiyavil yesjhyo dve netochnyiye diagnostiki; posle ispravleniya vse 14 testov proshli. Oni pokryivayut validnyij marshrut, otsutstviye i nevernyij registr temyi, symlink za checkout, povtor ID, nepolnyij iskhodnyij inventarj, povtor aktivnoj semantiki i celevogo yakorya, slishkom boljshoj korenj, raskhozhdeniye kornevogo i JSON-marshrutov, nepolnyij marshrut izmeneniya pravil, istoricheskuyu temu v obyichnom marshrute, podmenu tematicheskogo fajla i dopustimoye izmeneniye toljko recency.

Otdeljnyij RED/GREEN-cikl podklyuchil lyogkuyu strukturnuyu proverku k standartnomu smoke. Ona neobkhodima neposredstvenno dlya praviljnoj zagruzki pravil dokumentacionnogo prototipa i vyipolnyayet odin read-only-prokhod; avtonomnyiye otricateljnyiye fiksturyi ostayutsya v celevom i polnom profilyakh, poetomu standartnyij smoke ne utyazhelyon kopirovaniyem vremennyikh checkout.

## Profilj vremeni vyipolneniya

| Stadiya                              | Dliteljnostj | Granicyi i sposob izmereniya                                     |
| ----------------------------------- | ------------ | -------------------------------------------------------------- |
| Startovaya granica i analiz          | ne izmereno  | Ot 2026-08-24 15:31:12 MSK; read-only guard i analiz strukturyi |
| Realizaciya i TDD                    | ne izmereno  | Dekompoziciya, inventarj, validator i integraciya smoke          |
| Pryamyiye celevyiye proverki             | sm. nizhe     | Tochnyiye wall-time kazhdogo dochernego processa zapisanyi mashinno   |
| Finaljnyij standartnyij smoke         | sm. nizhe     | Tochnyij wall-time zapisan poslednim pryamyim zapuskom             |
| Lokaljnyij kommit i read-only-sverka | ne izmereno  | Granica nakhoditsya posle zakryitiya otchyota, bez handoff i push    |

Granica profilya: nachinayetsya kanonicheskoj paroj vremeni zaprosa 2026-08-24 15:31:12 MSK i zakanchivayetsya poslednim pryamyim smoke-zapuskom; zakryitiye otchyota, lokaljnyij kommit i read-only-sverka nakhodyatsya za etoj granicej. Obsjhaya soderzhateljnaya wall-time ne izmeryalasj otdeljnyim monotonnyim tajmerom; vyidumannaya dliteljnostj ne podstavlyayetsya. Pryamyiye proverochnyiye processyi izmerenyi `time.monotonic_ns()` avtomatizaciyej otchyotov.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:cfb32053eee4e1911e43144b10b657fb7b8f7d7b2392250ee16e1a0bf3e75ce6 -->

| Vyizov                                                                                        | Dliteljnostj | Rezuljtat |
| -------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent] RED: validator dekompozicii pravil agentov                                  | 0,495 s      | neuspeshno |
| [kornevoj agent] GREEN: validator dekompozicii pravil agentov                                | 1,182 s      | neuspeshno |
| [kornevoj agent] GREEN: povtor validatora posle utochneniya diagnostik                         | 1,119 s      | uspeshno   |
| [kornevoj agent] GREEN: avtonomnyiye testyi dekompozicii pravil agentov posle polnogo inventarya | 1,08 s       | uspeshno   |
| [kornevoj agent] Validator dekompozicii pravil na realjnom checkout                          | 0,123 s      | uspeshno   |
| [kornevoj agent] RED: standartnyij smoke trebuyet lyogkuyu proverku pravil agentov               | 0,149 s      | neuspeshno |
| [kornevoj agent] GREEN: standartnyij smoke vklyuchayet lyogkuyu proverku pravil agentov            | 0,151 s      | uspeshno   |
| [kornevoj agent] Regressiya postroitelya standartnogo i polnogo smoke posle novogo live-shaga   | 21,742 s     | neuspeshno |
| [kornevoj agent] Povtor regressii smoke posle soglasovaniya poryadka rannikh proverok           | 20,054 s     | uspeshno   |
| [kornevoj agent] Itogovyiye avtonomnyiye testyi dekompozicii pravil agentov                       | 1,043 s      | uspeshno   |
| [kornevoj agent] Itogovyij validator dekompozicii na realjnom checkout                        | 0,147 s      | uspeshno   |
| [kornevoj agent] Proverka nazvaniya novoj avtomatizacii dekompozicii                          | 3,668 s      | uspeshno   |
| [kornevoj agent] Proverka ostatka russkikh obyyavlenij posle novogo validatora                 | 22,74 s      | neuspeshno |
| [kornevoj agent] GREEN: ostatok russkikh obyyavlenij bez uvelicheniya latinskogo snimka          | 23,342 s     | uspeshno   |
| [kornevoj agent] Povtor celevyikh testov posle kirillizacii novyikh obyyavlenij                   | 1,039 s      | uspeshno   |
| [kornevoj agent] Povtor zhivogo validatora posle kirillizacii novyikh obyyavlenij                | 0,142 s      | uspeshno   |
| [kornevoj agent] Predvariteljnaya svyaznostj sessii pered itogovyim smoke                       | 30,626 s     | neuspeshno |
| [kornevoj agent] Reprezentativnoye bezopasnoye obyyedineniye smeshannogo marshruta                 | 0,151 s      | uspeshno   |
| [kornevoj agent] Finaljnyij standartnyij dokumentacionnyij smoke-check                          | 65,799 s     | neuspeshno |
| [kornevoj agent] Povtor svyaznosti posle zamyikaniya zhurnaljnyikh materialov                      | 30,946 s     | uspeshno   |
| [kornevoj agent] Povtor finaljnogo standartnogo dokumentacionnogo smoke-check                | 113,951 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 339,689 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Avtonomnyiye testyi dekompozicii: 14 testov, itog `OK`.
- Validator realjnogo checkout: 209 pravil i 11 tem, itog uspeshen.
- Regressiya postroitelya standartnogo i polnogo smoke: 69 testov, itog `OK` posle zafiksirovannogo RED po poryadku rannikh shagov.
- Proverka russkikh obyyavlenij snachala otklonila smeshannyiye novyiye imena; posle ispravleniya novyij instrument dal nulevoj latinskij ostatok. Tochnyij obsjhij snimok sokhranil prezhniye 43 212 obyyavlenij i prezhnyuyu svodku po yazyikam, izmeniv toljko otpechatok pozicij v otredaktirovannyikh smoke-fajlakh.
- Predstaviteljnyiye marshrutyi proveryayutsya JSON-fiksturami dlya dokumentacii, koda, publikacii, izmeneniya pravil i neodnoznachnoj smeshannoj zadachi; otricateljnyiye sluchai zakryivayut otsutstviye i podmenu temyi.
- Itogovyiye celevyiye proverki i standartnyij smoke vkhodyat v mashinnyij blok pryamyikh zapuskov; proverki zamyikaniya recency, svyaznosti, publikacionnoj chistotyi i exact diff vyipolnyayutsya pered kommitom.

## Resheniya i ogranicheniya

- Tematicheskiye fajlyi yavlyayutsya sluzhebnyimi agentskimi pravilami i poetomu nakhodyatsya v `Правила/агентов/`, a ne v produktovoj `Документация/`.
- Korenj ogranichen 140 strokami, 17 000 Unicode-simvolami i 30 000 UTF-8-bajtami. Itog ostayotsya nizhe kazhdogo poroga i nizhe nablyudayemoj granicyi Codex v 32 768 bajt.
- Khyeshi tematicheskikh fajlov vyichislyayutsya bez sluzhebnogo bloka `FUM-MD-RECENCY`, poetomu obnovleniye svezhesti ne maskiruyet i ne imitiruyet normativnoye izmeneniye.
- Istoricheskij konvejyer imeyet `полномочия=false`, ne vkhodit ni v odin obyichnyij marshrut i chitayetsya toljko pri izmenenii pravil kak proiskhozhdeniye.
- Polnyij inventarj velik, no nikogda ne zagruzhayetsya v obyichnyiye zadachi. Yego stoimostj yavlyayetsya osoznannoj platoj za redkoye izmeneniye samikh pravil i dokazateljstvo migracionnoj ekvivalentnosti.
- Sessiya rabotayet toljko v pervichnom checkout na `master`, sozdayot odin lokaljnyij kommit i ne vyipolnyayet push.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [kompaktnoye kornevoye yadro](../../AGENTS.md)
- [mashinnyij inventarj pravil](../../Pravila/agentov/inventarj-pravil.json)
- [lokaljnaya avtomatizaciya dekompozicii](../../Instrumentyi/fum-dekompoziciya-pravil-agentov/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:36:31 MSK -->
<!-- content-sha256: sha256:14f22342f0f2ed631ff7ace34dd0e3a61a7127ac53e7341daf857071a91f7e05 -->
<!-- FUM-MD-RECENCY:END -->
