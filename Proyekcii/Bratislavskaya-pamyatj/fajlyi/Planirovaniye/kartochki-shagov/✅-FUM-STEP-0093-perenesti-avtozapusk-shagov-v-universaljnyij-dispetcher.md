+++
schema_version = 1
card_id = "FUM-STEP-0093"
status = "completed"
+++
# Perenesti avtozapusk shagov v universaljnyij dispetcher

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Podklyuchitj dejstvuyusjhij zapusk sleduyusjhego shaga kak pervyij adapter universaljnogo dispetchera i migrirovatj na meste uzhe susjhestvuyusjhuyu prikreplyonnuyu zadachu i yeyo pyatiminutnyij heartbeat. Kartochochnyij navyik, skhema rabochego nabora i claim tochnogo pokoleniya vyibora dolzhnyi ostatjsya specializirovannyim modulem, vyizyivayemyim obsjhim sloyem, a ne byitj perepisanyi v universaljnyij reyestr.

## Rezuljtat

Dejstvuyusjhij avtozapusk sleduyusjhego shaga podklyuchyon kak pervyij active-adapter kanonicheskogo reyestra `master` s tochnoj celjyu tekusjhej rabochej kopii i `refs/heads/master`, bez kopirovaniya zadachi i kriteriyev kartochki. Obsjhij dispetcher vyizyivayet specializirovannyiye `show`, `claim` i fenced-vosstanovleniye, sokhranyayet pasport vyibora i dvazhdyi proveryayet nablyudayemyij prostoj Codex. Planovyij tik ne vkhodit v FIFO i ne menyayet checkout, a sozdannaya ispolniteljskaya zadacha pervyim instrumentaljnyim dejstviyem vkhodit v obsjhuyu ocheredj i podtverzhdayet obsjhij i kartochnyij run-fence.

Susjhestvovavshiye prikreplyonnaya zadacha i yeyo pyatiminutnyij heartbeat najdenyi po proveryayemyim host-priznakam i migrirovanyi na meste s sokhraneniyem celi, raspisaniya, statusa i istorii; vtoraya zadacha ili heartbeat ne sozdanyi, a neprozrachnyiye runtime-znacheniya ne voshli v pamyatj proyekta. Obsjhij heartbeat-prompt, kontraktyi ocheredi i adaptera, dokumentaciya i avtonomnyiye testyi razlichayut planovyij tik, kartochnyij adapter, obyichnuyu ispolniteljskuyu zadachu i poljzovateljskij upravlyayusjhij khod. Stop/Start menyayut toljko status togo zhe heartbeat, ne osvobozhdaya claim uzhe sozdannogo zadaniya; itogovyij read-only host-audit podtverdil odnu prikreplyonnuyu zadachu i odin heartbeat.

## Istochniki

- [iskhodnyij zapros o vyibore shaga pri zapuske s uchyotom istorii kommitov](../../Zhurnal/2026-07-27_18-28-42_MSK_vyibiratj-sleduyusjhij-shag-pri-zapuske-s-uchyotom-istorii-kommitov/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [trebovaniye universaljnoj dispetcherizacii](../../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [FUM-STEP-0092 — universaljnyij vyibor i rezervaciya](✅-FUM-STEP-0092-dobavitj-universaljnyij-vyibor-i-zasjhisjhyonnuyu-rezervaciyu-zapuska.md)
- [trebovaniye vyibora sleduyusjhego shaga vetki](../../Trebovaniya/✅-vyibor-sleduyusjhego-shaga-vetki-iz-kartochek-shagov.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:c0d6f7090e0e72208315dc3882332253023a1fb8a30eabf190de616f81beae41 -->
<!-- FUM-MD-RECENCY:END -->
