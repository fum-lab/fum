# Nablyudayemoye sostoyaniye agentskogo runtime i interfejsa

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0044 -->

FUMA dolzhna predostavlyatj cheloveku i agentu soglasuyemoye predstavleniye sobstvennogo rabochego sostoyaniya. Po nemu mozhno ponyatj, kakaya zadacha vyipolnyayetsya, kakoj modeljyu, v kakom rabochem dereve, chego ona ozhidayet i chto uzhe pokazano cheloveku. Nepolnyiye svedeniya i raskhozhdeniya istochnikov dolzhnyi byitj vidnyi v etom zhe predstavlenii.

Snimok svyazyivayet faktyi po ustojchivoj identichnosti zadachi. On razlichayet sredu samoj zadachi, fakticheskij katalog otdeljnoj komandyi, naznachennyij worktree i Git ref; vyibrannuyu modelj i modelj nablyudayemogo khoda; prinyatyij zapros zapuska, podgotovku, vyipolneniye i zaversheniye. Prinyatiye komandyi ne schitayetsya dokazateljstvom yeyo effekta.

Dlya kazhdogo znacheniya sokhranyayutsya istochnik, vremya nablyudeniya, granica okhvata i dostupnyij iskhodnyij fakt. Otsutstviye zadachi v nepolnom otvete API ne udalyayet uzhe nablyudyonnuyu zadachu. Ustarevshiye, nedostupnyiye i protivorechasjhiye svedeniya ne zamenyayutsya dogadkoj. Snimok ne utverzhdayet atomarnostj nablyudenij iz raznyikh sistem, yesli obsjhij soglasovannyij moment ne podtverzhdyon.

Obratnaya svyazj svyazyivayet namereniye, vyipolnennoye dejstviye, rezuljtat v poljzovateljskom interfejse, nablyudeniye etogo rezuljtata agentom i posleduyusjhuyu korrektirovku. Sokhranyonnaya posledovateljnostj dolzhna pozvolyatj ustanovitj, na kakom zvene svyazj poteryana: sobyitiye nedostupno, ne raspoznano, neverno sopostavleno, zabyito pri prodolzhenii ili ne ispoljzovano pri sleduyusjhem vyibore.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [statistikoj vyizovov dlya razvitiya avtomatizacij](🟡-statistika-vyizovov-dlya-razvitiya-avtomatizacij.md) — dayot istoriyu obrasjhenij i izmereniye povtoryayemoj rabotyi.

- **dopolnyayet:** [poljzovateljskoye perenapravleniye nepreryivnogo agentskogo cikla](🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) — dayot nablyudayemyij kontekst dlya korrektirovki rabotyi i podtverzhdeniya yeyo effekta.

## Kriterii proverki

- Chelovek i agent nakhodyat odnu zadachu po odnomu identifikatoru; dlya znachimogo sostoyaniya interfejsa dostupen strukturirovannyij istochnik libo yavno ogranichennyij razreshyonnyij vizualjnyij kanal.
- Scenarij s otstayusjhim spiskom API, susjhestvuyusjhej zapisjyu JSONL i vidimoj kartochkoj sokhranyayet vse nablyudeniya i otmechayet raskhozhdeniye, ne sozdavaya povtornuyu zadachu.
- Smena modeli posle pervogo khoda pokazyivayet prezhnyuyu i novuyu modelj s proiskhozhdeniyem. Konfiguraciya po umolchaniyu ne podmenyayet fakticheskuyu modelj khoda.
- Raznyiye runtime cwd i workdir komandyi otobrazhayutsya otdeljno; peredacha worktree podtverzhdayetsya sokhranyonnyimi izmeneniyami, prekrasjheniyem zapisi prezhnim ispolnitelem i prinyatiyem novyim.
- Ozhidaniye razresheniya, otveta cheloveka, rezuljtata processa i rabotyi drugogo ispolnitelya razlichayutsya. Zavershyonnyij khod ne oznachayet zavershyonnoye obyazateljstvo.
- Scenarij dejstviya s zaderzhannyim libo otsutstvuyusjhim izmeneniyem interfejsa ne vyidayot ozhidayemyij effekt za nablyudyonnyij; ispravleniye svyazyivayetsya s konkretnyim raskhozhdeniyem.
- Posle perezapuska iz dolgovechnogo Zhurnala vosproizvodyatsya prezhnij snimok, yego istochniki, neizvestnyiye polya i nezavershyonnaya korrektirovka.
- Sboj ili zapret kanala sokhranyayet prichinu nedostupnosti i ostavlyayet ostaljnyiye kanalyi rabotosposobnyimi; prava dostupa ne rasshiryayutsya iz-za trebovaniya nablyudayemosti.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano. Ruchnaya sverka API, JSONL i predostavlennogo poljzovatelem snimka podtverzhdayet neobkhodimostj etogo sloya, no ne yavlyayetsya yego realizaciyej. Pervyij ogranichennyij shag — [snimok sobstvennogo runtime i interfejsa](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0159-sobratj-snimok-agentskogo-runtime-i-interfejsa.md).

Nablyudayemostj ogranichivayetsya dostupnyimi i razreshyonnyimi vneshnimi sostoyaniyami. Skryityiye rassuzhdeniya modeli, sekretyi i postoronneye soderzhimoye ekrana ne stanovyatsya obyazateljnyim soderzhimyim Zhurnala. Lokaljnoye khraneniye i publichnyij eksport razlichayutsya. Otsutstviye dostupa k chasti sredyi pokazyivayetsya yavno i ne obkhoditsya.

## Istochniki trebovanij

- [Nablyudeniye o neprozrachnosti runtime i utochneniya obratnoj svyazi](../Zhurnal/2026-09-09_11-39-26_MSK_predotvratitj-poteryu-obyazateljstv-postoyannoj-zadachi/zapros.md).
- [Dostup k vnutrennim sostoyaniyam](../Dokumentaciya/07-dostup-k-vnutrennim-sostoyaniyam.md).
- [Interfejs FUM-uzla](../Dokumentaciya/25-interfejs-FUM-uzla.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:20:29 MSK -->
<!-- content-sha256: sha256:f80fc8db3a486968114c9df573f94e81215f02a90f3d9a176346c672ad2ddadb -->
<!-- FUM-MD-RECENCY:END -->
