+++
schema_version = 1
card_id = "FUM-STEP-0129"
status = "completed"
+++
# Realizovatj vosproizvodimuyu bratislavskuyu proyekciyu pamyati

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Realizovatj po prinyatomu mashinnomu kontraktu lokaljnuyu TDD-avtomatizaciyu polnoj generacii, atomarnoj ustanovki i proverki khranimoj bratislavskoj proyekcii kanonicheskoj pamyati FUM. Toljko eta avtomatizaciya preobrazuyet kanonicheskiye fajlyi: ruchnaya konvertaciya libo ruchnoye ispravleniye proizvodnoj oblasti ne yavlyayutsya dopustimyim rabochim putyom.

## Rezuljtat

Lokaljnaya avtomatizaciya poluchila komandyi polnoj generacii, atomarnoj ustanovki i nezavisimoj proverki pokoleniya. Politika, plan i manifest oformlenyi yavnoj migraciyej `v1 → v2`: opublikovannyiye fajlyi versii 1 sokhranenyi pobajtovo neizmennyimi, a versiya 2 zakreplyayet ssyilki na isklyuchyonnyiye kanonicheskiye celi, lokaljnyij `.obsidian/graph.json` i tochnyij fajl `ЛИЦЕНЗИЯ`. Avtomatizaciya strukturno preobrazuyet Markdown i yego lokaljnyiye ssyilki, sokhranyayet tochnyiye formatyi po politike, pereschityivayet proizvodnyij `FUM-MD-RECENCY`, povtorno proveryayet iskhodnyij snimok i ustanavlivayet derevo cherez vosstanavlivayemuyu fazovuyu tranzakciyu bez chastichnogo rezuljtata. Tokenizirovannaya chastichnaya zapisj atomarno stanovitsya polnyim vyikhodom toljko posle sinkhronizacii bajtov i okonchateljnogo rezhima. Pravo vosstanovleniya na perenos i udaleniye zakreplyayet opublikovannaya do pervoj mutacii vneshnyaya kvitanciya s tochnyimi snimkami pokolenij; vnutrennij zhurnal ne mozhet sam avtorizovatj neizvestnyij sluzhebnyij fajl, a publichnyiye plan i validator ne obkhodyat nezavershyonnuyu tranzakciyu.

Avtonomnyij TDD-nabor pokryivayet preryivaniya do, vo vremya i posle zapisi vyikhoda, granicyi ustanovki i tochku prinyatiya, idempotentnoye vosstanovleniye, poryadok sinkhronizacii mezhkatalozhnogo perenosa, svorachivaniye avarijnyikh dublikatov prezhnego i novogo pokolenij, polnyij predvariteljnyij obkhod pered udaleniyem, poddeljnyij zhurnal bez kvitancii, neizvestnyij fajl v udalyayemom rezerve, atomarnyij otkaz ot zamenyi zanyatogo naznacheniya, tochnyiye rezhimyi pri `umask 077`, udaleniye ischeznuvshikh upravlyayemyikh vyikhodov, ruchnoj drejf, kollizii, zasjhisjhyonnyiye URI i markeryi, globaljno unikaljnyiye Markdown-yakorya, budusjhiye proizvodnyiye celi i otkaz ssyilok na ustarevshiye libo sluzhebnyiye puti prezhnego pokoleniya. Kanonicheskiye avtodiskaveri-konturyi isklyuchayut toljko tochnuyu oblastj `Proyekcii/**`, polnyij smoke-check primenyayet i nezavisimo proveryayet pokoleniye, a finaljnoye zamyikaniye otchyota dopuskayet odnu strogo ogranichennuyu povtornuyu peresborku i proverku. Modelj iskhodit iz odnoj dobrosovestnoj pishusjhej sessii i doverennogo Git-dir; namerennaya poddelka kvitancii processom togo zhe poljzovatelya bez vneshnego kornya doveriya nakhoditsya vne granicyi shaga.

## Istochniki

- [utochneniye tekusjhego zaprosa — avtomaticheskaya konvertaciya, udaleniye vyikhodov i povtor posle konfliktov](../../Zhurnal/2026-08-14_18-09-04_MSK_zapustitj-paralleljnyij-sleduyusjhij-shag-s-minimaljnyimi-konfliktami/zapros.md)
- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [FUM-STEP-0128 — kontrakt paralleljnoj bratislavskoj proyekcii](✅-FUM-STEP-0128-zakrepitj-kontrakt-paralleljnoj-bratislavskoj-proyekcii-pamyati.md)
- [FUM-STEP-0087 — ogranichennoye avtomaticheskoye razresheniye Git-konfliktov](✅-FUM-STEP-0087-dobavitj-ogranichennoye-avtomaticheskoye-razresheniye-Git-konfliktov.md)
- [FUM-STEP-0148 — izolirovannyij worktree-kontur integracii i povtornogo revjyu](✅-FUM-STEP-0148-organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-worktree-poduzlakh.md)
- [trebovaniye o paralleljnoj bratislavskoj proyekcii pamyati FUM](../../Trebovaniya/✅-paralleljnaya-bratislavskaya-proyekciya-pamyati-FUM.md)
- [opisaniye bratislavskoj versii pamyati FUM](../../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)
- [iskhodnyij zapros realizacii FUM-STEP-0129](../../Zhurnal/2026-09-01_11-19-59_MSK_realizovatj-bratislavskuyu-proyekciyu-pamyati/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 17:52:20 MSK -->
<!-- content-sha256: sha256:a79bfca117b54e9baa037e3684c4e87009d8f945328206fe5391b6e07dbf0586 -->
<!-- FUM-MD-RECENCY:END -->
