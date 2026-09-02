# Otchyot 2026-07-23 13:40:57 MSK - Vyivoditj tekusjhuyu kartochku v sessii avtozapuska

Avtomaticheskaya sessiya teperj srazu pokazyivayet naznachennuyu kartochku i otdeljno podtverzhdayet fakticheskoye nachalo rabotyi posle ocheredi. Eto delayet tekusjhij shag vidimyim cheloveku, ne smeshivaya sozdaniye zadachi s pravom izmenyatj repozitorij.

## Rezuljtat

Pervoye vidimoye soobsjheniye sozdavayemoj zadachi imeyet formu `Автозапуск назначил карточку <card_id> — <title>; ожидаю допуск FIFO.` Ono ispoljzuyet uzhe mashinno proverennyiye znacheniya dispetcherskogo `show`, otpravlyayetsya odin raz do `join` i ne povtoryayetsya vo vremya neizmennogo ozhidaniya.

Posle `admitted` zadacha zanovo sveryayet `branch_ref` i `step_id`. Toljko uspeshnyij fenced `show` razreshayet soobsjheniye `В работу взята карточка <card_id> — <title>.` i perekhod k soderzhateljnoj rabote. Pri mismatch sessiya soobsjhayet, chto naznacheniye ne podtverzhdeno i rabota ne nachata, zatem osvobozhdayet vladeljca cherez `finish-clean` bez proyektnyikh izmenenij.

Dvukhstadijnaya semantika sinkhronizirovana v pravilakh repozitoriya, proizvodnoj dokumentacii, zhiznennom cikle vetochnogo shaga, navyike i shablone heartbeat. TDD-regressiya proveryayet obe formulyi, ikh poryadok i vetku nepodtverzhdyonnogo naznacheniya.

## Granica

Uvedomleniya pokazyivayut toljko ustojchivuyu chelovecheskuyu identichnostj kartochki — `card_id` i zagolovok. Oni ne raskryivayut sluzhebnuyu rezervaciyu, neprozrachnyiye identifikatoryi Codex, khyesh ili polnyij payload. Naznacheniye do FIFO ne vyidayotsya za dopusk, a besshumnoye ozhidaniye ocheredi sokhranyayetsya.

## Prodolzheniye

Dejstvuyusjhaya heartbeat-avtomatizaciya obnovlena shtatno bez smenyi celevoj zadachi, pyatiminutnogo raspisaniya i statusa `ACTIVE`. Rabochij nabor vetki ne perevyipuskayetsya: `FUM-STEP-0027` ostayotsya gotovoj kartochkoj sleduyusjhego avtomaticheskogo zapuska, a `FUM-STEP-0035` — zablokirovannyim kandidatom s prezhnim usloviyem vozobnovleniya.

## Zatronutyiye materialyi

- [pravila repozitoriya](../../AGENTS.md)
- [dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [shablon heartbeat](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [regressionnyiye testyi](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [opisaniye zhiznennogo cikla](../../Planirovaniye/sleduyusjhiye-shagi-vetok/README.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8cdf5e085b511c95b29c8bb892f2a8aaf30d370d19f482d8fe26fa52b9acf93c -->
<!-- FUM-MD-RECENCY:END -->
