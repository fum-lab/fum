+++
schema_version = 1
card_id = "FUM-STEP-0137"
status = "active"
+++
# Razreshatj tochnyiye lokaljnyiye puti po inventaryu pered vyizovom

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj tipizirovannoye razresheniye susjhestvuyusjhikh lokaljnyikh obyyektov FUM, kotoroye do chteniya ili zapuska prinimayet ustojchivyij identifikator kartochki libo mashinno obyyavlennuyu tochku vkhoda navyika, nakhodit rovno odin tochnyij putj v aktualjnom proyektnom inventare i ne pozvolyayet peredatj dochernemu instrumentu putj, vruchnuyu vosstanovlennyij iz smyislovogo imeni.

## Pochemu sejchas

Posle setevogo vosstanovleniya putj k proverke svyaznosti byil snachala ugadan i dal `Errno 2`. Dazhe posle obnaruzheniya fakticheskogo puti sleduyusjhij diagnosticheskij khod dvazhdyi ugadal otsutstvuyusjhiye imena fajlov FUM-SBOJ-0006 i FUM-STEP-0134, a yesjhyo odin khod povtoril oshibku dlya FUM-STEP-0136. Imenno vtoroye podtverzhdyonnoye proyavleniye `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0002` pokazyivayet, chto ruchnoj poisk posle otkaza ne obrazuyet obsjhej granicyi predotvrasjheniya.

## Kriterii zaversheniya

- Krasnaya avtonomnaya fikstura vosproizvodit tochnoye osnovaniye `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0002`: susjhestvuyusjhiye FUM-SBOJ-0006 i FUM-STEP-0134 poluchayut sostavlennyiye po smyislu otsutstvuyusjhiye puti, a oba vyizova `sed` zavershayutsya s `No such file` do zapozdalogo `rg --files`.
- Versionirovannyij inventarj okhvatyivayet otslezhivayemyiye i novyiye neignoriruyemyiye fajlyi tekusjhego checkout i tipizirovanno svyazyivayet `идентификатор_сбоя`, `card_id`, imya lokaljnogo navyika i yego obyyavlennyiye tochki vkhoda s tochnyimi repozitorno-otnositeljnyimi putyami.
- Shtatnaya granica lokaljnogo chteniya ili zapuska prinimayet ustojchivyij identifikator libo obyyavlennoye imya, vyizyivayet razreshitelj do dochernego instrumenta i trebuyet rovno odin susjhestvuyusjhij obyichnyij fajl vnutri kornya checkout.
- Nulevoye i mnozhestvennoye sovpadeniye, dubliruyusjhij identifikator, nevernyij tip obyyekta, nesovpadeniye tochnogo registra ili Unicode-normalizacii, simvolicheskaya ssyilka i vyikhod za korenj zakryito otklonyayutsya bez chteniya ili zapuska predpolagayemoj celi.
- Razresheniye zakreplyayet pokoleniye ili khyesh inventarya i proveryayemuyu identichnostj fajla; udaleniye, zamena ili pereimenovaniye mezhdu razresheniyem i ispoljzovaniyem ne perevodyat ustarevshij putj v vyizov.
- Dochernyaya komanda poluchayet tochnyij rezuljtat razreshitelya bez povtornoj sborki stroki, normalizacii libo dobavleniya opisateljnogo suffiksa; mashinnoye svideteljstvo sokhranyayet iskhodnyij identifikator i fakticheski ispoljzovannyij putj.
- Nechyotkij poisk, blizhajsheye imya i prezhnij putj mogut formirovatj diagnosticheskiye podskazki, no nikogda ne vyibirayut celj avtomaticheski i ne podmenyayut yavnyij otkaz.
- Otricateljnyiye fiksturyi pokryivayut vse sokhranyonnyiye proyavleniya FUM-SBOJ-0009 po ikh neizmenyayemyim lokaljnyim nomeram, nolj i neskoljko celej, pereimenovaniye, novyij neignoriruyemyij fajl, registrovoye i Unicode-raskhozhdeniye, simvoljnuyu ssyilku, vyikhod za korenj i gonku izmeneniya inventarya.
- Yavnyij putj ostayotsya dostupen toljko ograzhdyonnyim istoricheskim operaciyam i avtonomnyim otricateljnyim fiksturam; shtatnyij agentskij marshrut k susjhestvuyusjhemu obyyektu ne prinimayet svobodno ugadannyij putj.
- Avtonomnyiye testyi razreshitelya i zatronutyikh lokaljnyikh obyortok, regressiya FUM-SBOJ-0009, proverka svyaznosti rabochej sessii i obsjhij smoke-check prokhodyat bez seti i sekretov.

- Inventarj stroitsya ot proverennogo kornya libo uzhe odnoznachno razreshyonnogo kataloga. Predpolozhiteljnyij katalog poiska ne peredayotsya `rg --files`: fiksturyi 0007 i 0010 sokhranyayut etot poryadok otkaza.
- Dlya tochnogo testa i vnutrennego resursa komponenta snachala zadayotsya tipizirovannaya identichnostj v konechnom obyyavlenii. Neizvestnyij dokument ili neskoljko smyislovyikh kandidatov dayut zakryityij otkaz; skhodstvo imeni i poisk po teme ne vyibirayut celj avtomaticheski.
- Svideteljstvo fiksiruyet oshibku konkretnogo dochernego obrasjheniya dazhe pri itogovom kode 0 sostavnoj komandyi; eto ogranichennaya regressionnaya granica, a ne porucheniye perepisatj vse obolochki.

## Utochneniye posle povtornogo proyavleniya

`FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0004` povtorilo ugadyivaniye smyislovyikh imyon kartochek pri priyome inzhenernogo paketa. Regressionnyij nabor dolzhen vklyuchatj kartochku, chej ustojchivyij identifikator sokhranilsya, no opisaniye ne sovpadayet s ozhidayemoj temoj.

Novyiye podtverzhdyonnyiye proyavleniya 0005–0016 sokhranyayut tu zhe obsjhuyu meru: razreshatj obyyavlennuyu susjhestvuyusjhuyu celj do obrasjheniya i peredavatj tochnyij rezuljtat bez ruchnoj sborki imeni. Matrica dopolnyayetsya dokumentirovannoj komandoj strukturyi zaprosov, fakticheskim razmesjheniyem chitatelya, svezhestjyu Markdown, tochnyim testovyim resursom priyoma, funkciyami vnutri otchyotnoj avtomatizacii, suffiksom kartochki 0052 i dvumya oshibochnyimi basename modulej priyoma v odnom poiskovom epizode, a takzhe oshibochnyim katalogom strukturyi Zhurnala pered obsjhim inventaryom instrumentov i vyimyishlennyim basename susjhestvuyusjhej kartochki 0001 v dochernej RO-diagnostike, a takzhe povtornyim oshibochnyim adresom navyika svezhesti Markdown v kornevom epizode 0015. Otdeljnyij nedokazannyij dokument, staging, dinamicheskij snimok i poryadok predprosmotra v etu matricu po pokhozhemu otkazu ne vklyuchayutsya. Tochnoye poyavleniye suffiksa s lishnej bukvoj ne obyyasnyayetsya skryityim sostoyaniyem agenta.

Susjhestvuyusjhij plan ostayotsya aktivnyim: obnovleniye kartochek, uspeshnyij razovyij poisk i chteniye ne yavlyayutsya realizaciyej razreshitelya ili dokazateljstvom sistemnogo ustraneniya. Budusjhiye izmeneniya ispolnyayemogo koda prokhodyat TDD i vosproizvodimyij profilj s obosnovannyim resheniyem ob optimizacii po dejstvuyusjhim pravilam.

## Istochniki

- [Razresheniye tekusjhego plana po inventaryu](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md) — tochnoye osnovaniye `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0016`; yavnoye razmesjheniye plana v materialakh vklyuchayetsya v tu zhe regressionnuyu granicu.
- [Sverka pervichnyikh instrumentaljnyikh sobyitij](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md) — `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0005`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0006`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0007`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0008`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0009`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0010`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0011`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0012`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0013`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0014`, `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0015`.
- [Lokalizaciya priyomochnyikh raundov](../../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/otchyot.md) — `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0009`.
- [Vosstanovleniye chitatelya soobsjhenij](../../Zhurnal/2026-09-11_07-44-52_MSK_prinyatj-matematiku-i-rabochij-kontekst/otchyot.md) — `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0010`.

- [Iskhodnyij zapros priyoma modeli](../../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md) — `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0004`.

- [FUM-SBOJ-0009 — Ruchnoye ugadyivaniye lokaljnyikh putej pered vyizovom](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md) — tochnoye osnovaniye `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0002`
- [tretjye proyavleniye FUM-SBOJ-0009](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0003`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [proverka svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:365594e7f340c7600b1a626b37e13ad31c6fbb90a7ce61cd72febcf1141a0289 -->
<!-- FUM-MD-RECENCY:END -->
