+++
schema_version = 1
card_id = "FUM-STEP-0172"
status = "active"
+++
# Proveryatj ostatok obyazateljstv zadachi

## Zadacha

Perenesti proverku sokhranyonnyikh obyazateljstv postoyannoj zadachi na tekusjhiye v3-svideteljstva i vyibiratj sleduyusjhij dostupnyij soglasovannyij etap po mashinnomu reyestru s proiskhozhdeniyem.

## Pochemu sejchas

Poljzovatelj potreboval sistemno ustranitj prezhdevremennuyu ostanovku i prodolzhatj rabotu posle kommita. Pravilo prodolzheniya uzhe prinyato, adapter svyazi otpechatka s kommitom realizovan otdeljno. Istoricheskaya narabotka ispoljzuyet druguyu liniyu Git i nesovmestimyiye skhemyi; prostaya zamena yeyo iskhodnogo kommita tekusjhim HEAD teryayet proiskhozhdeniye.

## Kriterii zaversheniya

- Reyestr ssyilayetsya na realjnyiye doslovnyiye komandyi i polnyiye dostupnyiye kommityi istochnikov pervichnogo checkout; migraciya istoricheskikh identifikatorov yavnaya.
- Udaleniye ili oslableniye obyazateljstva, povtornyiye klyuchi JSON, nevernyij UUID i neproverennaya priyomka otklonyayutsya.
- Zakryityiye v3-svideteljstva polnostjyu proverenyi i svyazanyi s konkretnyim kommitom; rezuljtatyi proveryayutsya protiv obyazateljstv. Plan i otvet dochernego agenta ne ravnyi realizacii, docherneye obyazateljstvo ne zakryivayet roditelya.
- Vyibirayetsya dostupnaya soglasovannaya rabota; ozhidaniye po odnomu napravleniyu ne skryivayet nezavisimyij dostupnyij ostatok.
- Pustoj ostatok nepolnogo reyestra ne vyidayotsya za zaversheniye vsej zadachi FUMA. Sistemnyij perekhvat zaversheniya Codex trebuyet otdeljno podtverzhdyonnogo podklyucheniya.
- Projdenyi RED/GREEN, profilj i optimizaciya chteniya istorii, adresnaya i obsjhaya priyomka.

## Istochniki

- [Komanda prodolzhatj posle kommita](../../Zhurnal/2026-09-09_21-31-19_MSK_prodolzhatj-rabotu-posle-kommita/zapros.md).
- [Etap adaptacii i doslovnyiye osnovaniya](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).
- [Publikacionno chistaya karta proiskhozhdeniya](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/proiskhozhdeniye-obyazateljstv.json).
- [Kontrakt adaptera](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/svyazj-s-kommitom.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 01:11:48 MSK -->
<!-- content-sha256: sha256:6cab2c0008b2211645589f39029de76a409db8e778db0d8c30a4fa0de512c097 -->
<!-- FUM-MD-RECENCY:END -->
