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
- Otricateljnyiye fiksturyi pokryivayut vse tri proyavleniya FUM-SBOJ-0009, nolj i neskoljko celej, pereimenovaniye, novyij neignoriruyemyij fajl, registrovoye i Unicode-raskhozhdeniye, simvoljnuyu ssyilku, vyikhod za korenj i gonku izmeneniya inventarya.
- Yavnyij putj ostayotsya dostupen toljko ograzhdyonnyim istoricheskim operaciyam i avtonomnyim otricateljnyim fiksturam; shtatnyij agentskij marshrut k susjhestvuyusjhemu obyyektu ne prinimayet svobodno ugadannyij putj.
- Avtonomnyiye testyi razreshitelya i zatronutyikh lokaljnyikh obyortok, regressiya FUM-SBOJ-0009, proverka svyaznosti rabochej sessii i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0009 — Ruchnoye ugadyivaniye lokaljnyikh putej pered vyizovom](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md) — tochnoye osnovaniye `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0002`
- [tretjye proyavleniye FUM-SBOJ-0009](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0003`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [proverka svyaznosti rabochej sessii](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 01:09:33 MSK -->
<!-- content-sha256: sha256:83404bdcc8ca903238181bad22e1f2f9878243ee384fead43363ae27a55d9064 -->
<!-- FUM-MD-RECENCY:END -->
