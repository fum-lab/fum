# Otchyot 2026-07-22 13:39:29 MSK - Ustranitj mashinno lokaljnyiye puti

Publikacionnaya granica FUM teperj opirayetsya ne na razovyij poisk, a na vosproizvodimuyu tipizirovannuyu proverku mashinno-lokaljnyikh putej. Perenosimostj zakreplena v tochkakh, gde lokaljnyiye puti mogli popastj v prompt, Markdown ili runtime.

## Rezuljtat

Navyik glossariya i reyestr instrumentov boljshe ne publikuyut pyatj dejstvuyusjhikh mashinnyikh privyazok. Dochernij prompt proveryayet vesj ready-payload do `show` i claim; Markdown-generatoryi validiruyut path-polya do zapisi; proverka svyaznosti otvergayet absolyutnyiye i vyikhodyasjhiye za korenj lokaljnyiye ssyilki.

Swift-lokator poluchayet korenj checkout v runtime iz peremennoj sredyi, a launcher vyichislyayet yego iz svoyego mesta v tekusjhem checkout. Test perenosa podtverzhdayet, chto tot zhe kod prinimayet novyij korenj i ne sokhranyayet prezhnyuyu privyazku. Upstream-ogranicheniye zavisimosti zafiksirovano otdeljno bez obkhoda forka.

## Skaner i politika

Skaner chitayet Git-inventarj, sortiruyet nakhodki i pechatayet toljko `путь:строка:категория`, ne raskryivaya sam literal. Politika delit isklyucheniya po tipu i kontekstu. Doslovnyij blok iskhodnogo zaprosa i arkhivyi vneshnikh istochnikov otchyotnyi, togda kak dejstvuyusjhaya first-party-ssyilka blokiruyet priyomku. Kazhdoye uzkoye isklyucheniye skhemyi v2 imeyet zakryituyu kategoriyu, prichinu i otpechatok; izmeneniye ili neispoljzuyemoye isklyucheniye dayot oshibku. Samo nakhozhdeniye stroki v testakh, skanere ili drugom validatore nichego ne razreshayet.

## Proverki

Razrabotka velasj cherez krasnyiye i zelyonyiye progonyi. Krasnaya faza pokazala, chto prezhniye `show`, claim, generatoryi, svyaznostj, Swift-lokator i smoke-check ne pokryivali nuzhnuyu granicu. Zelyonyiye naboryi zakrepili kross-platformennyiye formyi, otkaz do zapisi i sozdaniya claim, perenos checkout, uzkiye isklyucheniya i padeniye smoke-check na iskusstvennoj regressii. Finaljnyij nezavisimyij audit vyiyavil redkiye obkhodyi POSIX-, UNC- i home-form i shirokiye razresheniya po raspolozheniyu fajla; posle ikh zakryitiya avtonomnyiye naboryi i polnyij povtornyij skan proshli.

## Prodolzheniye

Kartochka `FUM-STEP-0070` zavershena. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` v statuse `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0024` yedinstvennyim `ready`. Eto bezopasno ispolnimoye lokaljno opisaniye shablona scenariya modeljnoj sredyi.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [predyidusjhij audit](../2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/materialyi/revjyu/2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.md)
- [zavershyonnaya kartochka FUM-STEP-0070](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0070-ustranitj-mashinno-lokaljnyiye-absolyutnyiye-puti-i-dobavitj-ikh-avtomaticheskuyu-proverku.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3b5b87b99233fc427abf9bf842fc038f670582801d6282e2c8977472b1409271 -->
<!-- FUM-MD-RECENCY:END -->
