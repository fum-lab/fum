+++
schema_version = 1
card_id = "FUM-STEP-0128"
status = "completed"
+++
# Zakrepitj kontrakt paralleljnoj bratislavskoj proyekcii pamyati

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sozdatj cherez TDD versionirovannyij mashinnyij kontrakt polnogo iskhodnogo inventarya, neperesekayusjhegosya celevogo prostranstva, pokomponentnogo preobrazovaniya puti i manifesta proiskhozhdeniya dlya paralleljnoj bratislavskoj proyekcii pamyati FUM.

## Pochemu sejchas

LinguisticKit uzhe zakreplyon i umeyet preobrazovyivatj stroki, no tekusjhaya obyortka ne razlichayet formatyi, ne obkhodit derevo i ne zasjhisjhayet ot sovpadayusjhikh latinskikh putej, rekursivnogo vkhoda, povrezhdeniya ssyilok ili mashinnyikh kontraktov. Format i dry-run nuzhnyi do lyuboj massovoj zapisi.

## Kriterii zaversheniya

- Do realizacii padayusjhiye testyi fiksiruyut polnyij polozhiteljnyij putj i opasnyiye sluchai: uzhe latinskoye imya, vlozhennyij kirillicheskij putj, exact-, NFC- i casefold-kollizii, peresecheniye source/target, rekursivnyij vkhod, simvolicheskuyu ssyilku, gitlink, dvoichnyij i ne-UTF-8 fajl, dlinnoye libo neperenosimoye imya.
- Yedinyij vosproizvodimyij inventarj klassificiruyet vse otslezhivayemyiye i dopustimyiye novyiye obyyektyi kanonicheskoj pamyati, a ne toljko Markdown, i yavno zadayot granicyi dlya `.git`, sborochnyikh kyeshej, zavisimosti, `.obsidian`, vneshnikh istochnikov, specialjnyikh fajlov, rezhimov i pustyikh katalogov.
- Skhema fiksiruyet tochnyij iskhodnyij snimok, versiyu, oblastj i isklyucheniya, neperesekayusjheyesya fizicheskoye razmesjheniye celi, `.Cyrl → .Latn`, tablicu `.ru`, reviziyu LinguisticKit, formatnuyu politiku i otobrazheniye kazhdoj paryi putej i khyeshej.
- Kazhdyij komponent polnogo otnositeljnogo puti preobrazuyetsya otdeljno; neizmenivshiyesya tekhnicheskiye komponentyi ostayutsya nablyudayemyimi, rasshireniya imeyut yavnoye pravilo, a vse klassyi kollizij zakryivayut plan do zapisi bez chislovogo suffiksa.
- Formatnyiye pravila razlichayut russkij tekst, lokaljnyiye ssyilki i anchors, vneshniye URL, doslovnyiye zaprosyi i istochniki, kod, JSON i drugiye mashinnyiye dannyiye, content-addressed imena, khyeshi i `FUM-MD-RECENCY`.
- Sukhoj plan determinirovanno pokazyivayet polnyij source → target, dejstviye s soderzhimyim i diagnostiruyemuyu prichinu kazhdogo sokhraneniya ili otkaza; izmeneniye vkhoda posle preflight delayet plan nedejstviteljnyim.
- Validator manifesta otklonyayet otsutstvuyusjhij, lishnij, ustarevshij ili vruchnuyu izmenyonnyij vyikhod i dokazyivayet, chto proizvodnaya oblastj ne stala vkhodom, otdeljnyim paketom, avtomatizaciyej libo vtoryim istochnikom trebovanij.
- Avtonomnyiye testyi rabotayut bez seti i sekretov i prokhodyat vmeste s obsjhej kompleksnoj proverkoj repozitoriya.

## Rezuljtat

Sozdana lokaljnaya avtomatizaciya `fum-bratislavskaya-proyekciya-pamyati` s zakryityimi skhemami plana i manifesta, tochnoj politikoj formatov, polnyim Git-inventaryom, pokomponentnyim LinguisticKit-preobrazovaniyem putej, zakryityimi kolliziyami i nezavisimoj proverkoj celevyikh bajtov. Content-addressed identichnostj istochnika perezhivayet kak kommit toljko proizvodnogo pokoleniya, tak i yedinyij kommit izmenyonnogo kanonicheskogo sloya s yego proyekciyej, no lyuboye izmeneniye puti, rezhima ili bajtov zakryivayet validaciyu.

Pyatjdesyat avtonomnyikh TDD-fikstur prokhodyat bez seti; zhivoj sukhoj plan na zakreplyonnom LinguisticKit okhvatil polnyij tekusjhij checkout, v kontroljnom progone postroil 4 062 tochnyikh paryi source → target bez kollizij i dvazhdyi vyidal pobajtovo odinakovyij plan. Massovaya zapisj `Proyekcii/` ne vyipolnyalasj: polnaya generaciya, atomarnaya zamena, udaleniye celej ischeznuvshikh istochnikov i obyazateljnyij povtor posle razresheniya Git-konflikta zakreplenyi v utochnyonnoj FUM-STEP-0129.

## Istochniki

- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [trebovaniye o paralleljnoj bratislavskoj proyekcii pamyati FUM](../../Trebovaniya/✅-paralleljnaya-bratislavskaya-proyekciya-pamyati-FUM.md)
- [opisaniye bratislavskoj versii pamyati FUM](../../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)
- [podklyucheniye LinguisticKit](../../Zavisimosti/README.md)
- [obsjhij inventarj proyektnyikh Markdown-fajlov](../../Instrumentyi/fum-proyektnyiye-fajlyi/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:da6296d15ea79c8a1f33c4fb8a4451d73e0b3ae60b847774474a3657789a10d9 -->
<!-- FUM-MD-RECENCY:END -->
