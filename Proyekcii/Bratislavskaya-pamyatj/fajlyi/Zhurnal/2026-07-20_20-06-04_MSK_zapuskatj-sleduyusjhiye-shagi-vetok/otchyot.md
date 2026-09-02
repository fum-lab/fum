# Otchyot 2026-07-20 20:06:04 MSK - Zapuskatj sleduyusjhiye shagi vetok

Dlya paralleljnogo razvitiya forka pamyati sozdan vetkozavisimyij kontur prodolzheniya rabotyi. Kazhdaya avtomaticheski razvivayemaya imenovannaya Git-vetka teperj imeyet rovno odin vyibrannyij [sleduyusjhij shag](../../Glossarij/sleduyusjhij-shag-vetki.md), a samostoyateljnyiye proyektyi poluchayut pasporta v kornevom kataloge `Проекты/`.

## Resheniya

- Obsjhij spisok predlozhenij sokhranyon kak pul kandidatov; ispolnyayemyij shag vyinesen v otdeljnuyu zapisj s polnyim `branch_ref`, ustojchivyim `step_id`, statusom, proyektom, zadachej, kriteriyami i istochnikami.
- Kornevoj `master` svyazan s glavnyim README FUM. Vetka `project/<имя>` dolzhna poluchitj `Проекты/<имя>/README.md` i tochnuyu sobstvennuyu zapisj; unasledovannyij shag `master` ne podkhodit.
- Lokaljnaya avtomatizaciya `fum-branch-next-step` validiruyet vyibor, povtorno proveryayet identichnostj i atomarno rezerviruyet zapusk v obsjhem Git-kataloge. Odin `step_id` avtomaticheski vtoroj raz ne zapuskayetsya.
- Claim ne poluchayet TTL. Posle avarii on snimayetsya toljko po predvariteljno nablyudyonnomu `lease_id` posle podtverzhdeniya, chto prezhnyaya zadacha ostanovlena; publikaciya, zamena i udaleniye zakreplyayutsya `fsync` kataloga, a ozhidaniye lokaljnogo lock ogranicheno i zakryivayetsya otkazom.
- Pyatiminutnyij opros realizovan heartbeat tekusjhej dispetcherskoj zadachi, a ne samostoyateljnyim cron-progonom. Poetomu v bokovom menyu sozdayutsya obyichnyiye zadachi realjnyikh shagov, a ne sotni pustyikh Scheduled-zapuskov.
- Heartbeat zaregistrirovan v pauze na vremya fajlovoj rabotyi etoj sessii i aktiviruyetsya toljko posle chistogo kommita.
- Dispetcher zakryivayetsya pri lyuboj drugoj aktivnoj zadache, nablyudayemoj v recent-snimke do 50 zadach, nedostupnom host ili neizvestnom sostoyanii, povtoryayet inventarizaciyu posle claim i sozdayot zadachu toljko v lokaljnom proyekte FUM.
- Dochernyaya zadacha obyazana prochitatj tochnyiye zapisj shaga i pasport proyekta i soblyudatj ikh granicyi dejstvij, dostupa, publikacii i proverki.
- Neodnoznachnyij rezuljtat `create_thread` sokhranyayet claim: oshibka mozhet skryivatj uzhe sozdannuyu zadachu, poetomu osvobozhdeniye dopustimo toljko posle yavnogo otricateljnogo otveta libo cherez fenced-vosstanovleniye s vneshnim podtverzhdeniyem.
- Proverka spiska i sozdaniye zadachi ne yavlyayutsya tranzakciyej, a sam spisok ne soobsjhayet polnotu i ne dokazyivayet sostoyaniye boleye staryikh zadach za predelami snimka. Povtornaya proverka vnutri sozdannoj zadachi i vetochnyij barjyer sokhranyayutsya kak otdeljnyiye ograzhdeniya.

## Proverki

TDD snachala zafiksiroval devyatj otkazov pri otsutstvii realizacii. Posle dobavleniya scenariya vosemj testov proshli, a integracionnyij test zakonomerno potreboval zapisj aktivnoj vetki; posle dobavleniya `master.md` proshli iskhodnyiye devyatj. Nezavisimyij audit zatem rasshiril krasnoye pokryitiye crash-durability, skryityikh i soderzhateljno pustyikh Markdown-razdelov, strogikh tipov i CLI-parametrov, povrezhdyonnyikh claim, simlinkov i dublej JSON, NUL-vkhodov, svyazi pasportov, susjhestvovaniya ref, bounded-lock i read-only-diagnostiki. Finaljnoye revjyu dobavilo regressii dlya neodnoznachnogo otveta `create_thread`, obyazateljnogo chteniya zapisi i pasporta i zapreta skryityikh HTML-kommentariyev v ispolnyayemoj zapisi. Posle ispravlenij prokhodyat vse dvadcatj tri testa.

Struktura navyika, polnyij smoke-check, planovyij reyestr, recency-metki, graf Obsidian, svyaznostj rabochej sessii, Markdown-ssyilki, publikacionnaya chistota i Git diff proverenyi pered kommitom.

## Prodolzheniye

Pervyim gotovyim shagom `master` vyibrano vklyucheniye atomarnyikh kartochek `Требования/` v kanonicheskij mashinnyij planovyij reyestr. Posle zaversheniya sozdannaya zadacha dolzhna zapisatj sleduyusjhij `step_id` libo yavnoye sostoyaniye vetki.

## Zatronutyiye materialyi

- [katalog proyektov](../../Proyektyi/README.md)
- [sleduyusjhiye shagi vetok](../../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)
- [lokaljnaya avtomatizaciya](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [shablon heartbeat-dispetchera](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [pravila povedeniya v repozitorii](../../AGENTS.md)
- [paralleljnaya rabota i sliyaniye](../../Dokumentaciya/04-paralleljnaya-rabota-i-sliyaniye.md)
- [vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [publichnyij upstream i forki pamyati FUM](../../Dokumentaciya/27-publichnyij-upstream-i-forki-pamyati.md)

## Istochniki

- [iskhodnyij zapros 2026-07-20 20:06:04 MSK](zapros.md)
- [oficialjnyij spravochnik zaplanirovannyikh zadach Codex](https://developers.openai.com/codex/app/automations)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c2f668b31da0be6ab08c841166029a221db389014b3fad428fda9abc45843987 -->
<!-- FUM-MD-RECENCY:END -->
