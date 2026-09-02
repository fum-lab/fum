# Otchyot 2026-07-20 21:22:17 MSK - Vklyuchitj kartochki trebovanij v mashinnyij planovyij reyestr

Atomarnyiye kartochki `Требования/` stali kanonicheskim vkhodom mashinnogo planovogo reyestra. Vse 14 dejstvuyusjhikh kartochek poluchili ustojchivyiye identifikatoryi `FUM-REQ-0001`–`FUM-REQ-0014`, a skhema `fum.planning.requirements-registry.v5` sokhranyayet ikh statusyi, formulirovki, kriterii i tipizirovannyiye svyazi.

## Resheniya

- Identifikator khranitsya v markere `FUM-REQUIREMENT-ID` srazu posle zagolovka kartochki i ne zavisit ot statusnogo emodzi, imeni fajla, zagolovka ili pozicii v indekse.
- Statusnyim istochnikom ostayotsya prefiks imeni fajla. Indeks i razdel `Статус и границы` yavlyayutsya proveryayemyimi kopiyami i dolzhnyi sovpadatj s nim.
- Validator trebuyet chetyire obyazateljnyikh razdela, nepustuyu formulirovku i kriterii, polnyij indeks bez propuskov i dublej, dopustimyij status i unikaljnyij ID.
- Vse 40 napravlennyikh semanticheskikh zapisej proveryayutsya kak 20 soglasovannyikh par pryamogo i obratnogo otnoshenij.
- Prezhniye 13 shirokikh strok boljshe ne nazyivayutsya kanonicheskimi trebovaniyami v JSON. Oni vkhodyat v `planning_views`, poluchayut yavnyiye `PLAN-LAYER-*` i libo svyazyivayutsya s kartochkami, libo pomechayutsya kak proizvodnyij sloj.
- Spisochnyij punkt o fizicheskikh izmereniyakh klaviaturnogo prototipa perenesyon v tablicu aktualjnyikh predlozhenij. Lyuboj novyij netablichnyij tekst v etom razdele teperj otklonyayetsya kak neproindeksirovannyij.

## TDD

Krasnaya faza dobavila fiksturu iz dvukh kartochek s obratnoj paroj svyazej i proverki kanonicheskikh ID, statusov, formulirovok, kriteriyev, obyazateljnyikh razdelov, indeksa, unikaljnosti, shirokikh sloyov i netablichnogo predlozheniya. Iskhodnaya realizaciya dala desyatj ozhidayemyikh otkazov: kartochek i `planning_views` v kontrakte yesjhyo ne byilo.

Posle realizacii pervyiye desyatj testov proshli. Zatem karta shirokikh strok byila vyinesena v otdeljnuyu kompaktnuyu tablicu, a nabor rasshiren proverkoj vsekh chetyiryokh obyazateljnyikh razdelov, raskhozhdeniya statusa v indekse i tele i polozheniya ID srazu posle zagolovka. Nezavisimyiye audityi porodili novyiye krasnyiye progonyi dlya raskhozhdeniya ID indeksa i kartochki, ne-ASCII cifr, povrezhdyonnyikh i otsutstvuyusjhikh tablic, skryitoj stroki pered zagolovkom, mnogostrochnogo kriteriya i pustyikh istochnikov, zamaskirovannyikh recency-blokom. Itogovyij avtonomnyij nabor soderzhit 19 prokhodyasjhikh testov.

## Proverki

- `fum-planning-registry`: 19 avtonomnyikh testov prokhodyat bez seti i sekretov.
- Realjnyij reyestr uspeshno sobirayetsya i validiruyetsya kak skhema v5.
- Peresobrannyij JSON soderzhit 14 trebovanij, 13 shirokikh predstavlenij, 40 napravlennyikh svyazej i 15 istochnikov iz `Требования/`, vklyuchaya indeks.
- V reyestre predstavlenyi 11 kartochek so statusom `🟡` i 3 kartochki so statusom `🚧`; ID obrazuyut nepreryivnyij vpervyiye naznachennyij diapazon `FUM-REQ-0001`–`FUM-REQ-0014`.
- Zapisj sleduyusjhego shaga vetki prokhodit `validate` i tochnyij `show` dlya `master-atomic-source-rearchive-v1`.
- Polnyij smoke-check prokhodit bez seti i sekretov; svyaznostj sessii, recency-metki, graf Obsidian, Markdown-ssyilki, publikacionnaya chistota i Git diff takzhe podtverzhdenyi pered kommitom.

## Prodolzheniye

Sleduyusjhim ready-shagom `master` vyibrano atomarnoye povtornoye arkhivirovaniye odnogo istochnika: staging-snimok, tochnyij manifest upravlyayemyikh fajlov i celostnaya zamena bez smesheniya starogo i novogo rezuljtata.

## Zatronutyiye materialyi

- [indeks kartochek trebovanij](../../Trebovaniya/README.md)
- [svodnaya tablica i karta shirokikh strok](../../Planirovaniye/svodnaya-tablica-trebovanij-i-realizacij.md)
- [mashinnyij planovyij reyestr](../../Planirovaniye/reyestr-trebovanij-variantov-i-kandidatov.json)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [lokaljnaya avtomatizaciya](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md)
- [sleduyusjhij shag master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [revjyu proyekta 2026-07-18](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:760c90c5725039a2919d79bc79833962ba0c7d5a6da5ea066b59212b38a93fd2 -->
<!-- FUM-MD-RECENCY:END -->
