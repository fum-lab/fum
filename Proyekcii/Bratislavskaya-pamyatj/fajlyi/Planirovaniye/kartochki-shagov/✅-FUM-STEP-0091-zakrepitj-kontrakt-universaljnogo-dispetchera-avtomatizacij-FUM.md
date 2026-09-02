+++
schema_version = 1
card_id = "FUM-STEP-0091"
status = "completed"
+++
# Zakrepitj kontrakt universaljnogo dispetchera avtomatizacij FUM

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sozdatj novyij lokaljnyij kontrakt [dispetchera avtomatizacij FUM](../../Glossarij/dispetcher-avtomatizacij-FUM.md), ne prevrasjhaya kartochochnyij `fum-sleduyusjhij-shag-vetki` v obsjhij planirovsjhik. Vvesti versionirovannyij vetochnyij reyestr zadanij, zakryituyu skhemu, lokaljnyij validator i avtonomnyij simulyator. Zapisj zadaniya dolzhna soderzhatj ustojchivyij ID i pokoleniye, adapter, celj, trigger, usloviya, sostoyaniye, klass effekta, ispolnitelya, fence, kursor i politiku oshibki.

## Rezuljtat

Sozdan otdeljnyij lokaljnyij navyik `fum-dispetcher-avtomatizacij-fum` s zaregistrirovannyim russkim nazvaniyem `диспетчер автоматизаций FUM`, proveryayemoj transliteraciyej `dispetcher avtomatizacij FUM` i samostoyateljnyim kontraktom, ne menyayusjhim imya ili naznacheniye `fum-sleduyusjhij-shag-vetki`. Skhema `fum.automation-job-registry.v1` zakryivayet kazhdyij obyyekt reyestra, a kanonicheskij vetochnyij fajl `Планирование/реестры-заданий-автоматизаций/master.json` zakreplyayet polnyij `refs/heads/master`, yakorj fizicheski peredavayemoj rabochej kopii i pasport proyekta `README.md`.

Fail-closed-validator trebuyet ustojchivyij `job_id`, polozhiteljnoye pokoleniye, adapter, tochnuyu celj, odin iz dvukh vzaimoisklyuchayusjhikh triggerov, otdeljnyiye usloviya dopuska, sostoyaniye `active`, `paused`, `blocked` ili `retired`, soglasovannyiye klass i politiku effekta, zakryitogo ispolnitelya, fence togo zhe pokoleniya, kursor sootvetstvuyusjhej formyi i zakryituyu politiku oshibki. On otvergayet neizvestnyiye i povtornyiye JSON-polya, povtoryi `job_id`, ref vne strogogo bezopasnogo ASCII-podmnozhestva i nebezopasnyiye puti, otsutstviye Git-markera, simvolicheskiye ssyilki, nesovpadayusjhiye celi, pokoleniya i fence, nedostatochnogo ispolnitelya, kursor drugoj formyi ili vne setki raspisaniya. Chistyij simulyator razdeljno pokazyivayet nastupleniye triggera, vyipolneniye uslovij, razresheniye sostoyaniya i itogovuyu gotovnostj; nastupivshij srok ne delayet `paused`, `blocked` ili `retired` gotovyimi.

TDD-fiksturyi pokryivayut korrektnyiye raspisaniye i sobyitijnyij porog, vse chetyire sostoyaniya, tablicu otricateljnyikh mutacij i otdeljnyij povtornyij JSON-klyuch. Odin lokaljnyij probnik proveryayet pustoj kanonicheskij reyestr i modeliruyet polnuyu fiksturu bez seti, host Codex, sekretov, Git-indeksa i vneshnikh effektov. Zhivaya prikreplyonnaya zadacha namerenno ne vnesena v novyij reyestr dazhe kak priostanovlennoye zadaniye: universaljnyiye vyibor i CAS otnosyatsya k FUM-STEP-0092, a host-migraciya — k FUM-STEP-0093.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 05:48:39 MSK — Zakrepitj kontrakt universaljnogo dispetchera avtomatizacij FUM](../../Zhurnal/2026-08-05_05-48-39_MSK_zakrepitj-kontrakt-universaljnogo-dispetchera-avtomatizacij-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [dejstvuyusjhaya arkhitektura obyazateljnogo prodolzheniya Git-vetki](../../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [FUM-STEP-0090 — skvoznaya priyomka repozitornoj kompozicii](✅-FUM-STEP-0090-provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:e10ee4c6972fa4188c4f9f75d9dc3226110f685285d797a88f1ba30704c4e788 -->
<!-- FUM-MD-RECENCY:END -->
