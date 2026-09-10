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

## Prinyatyij obyyom tekusjhego etapa

Podgotovlenyi [reyestr semi obyazateljstv](../zadachi/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/obyazateljstva.json) i [otdeljnaya komanda ostatka](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/ostatok-obyazateljstv.md). Proveryayutsya sokhrannostj opredelenij vo vsej dostizhimoj istorii, zakryityiye v3-priyomki rabot i aktualjnostj tranzitivnyikh predposyilok; vyibirayetsya dostupnoye dejstviye. V reyestre splanirovan tekusjhij etap, ostaljnyiye napravleniya yavno trebuyut plana. Priyomka tekusjhego kommita poyavlyayetsya toljko posle yego sozdaniya i otdeljnoj proverki.

Po [utochneniyu poljzovatelya o sorazmernosti processa](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/zapros.md) realizaciya ogranichena prakticheskim uchyotom. Smyislovoye dokazateljstvo zaversheniya vsej FUMA i sistemnoye podklyucheniye k ostanovke Codex ostayutsya otdeljnoj rabotoj; eta kartochka sokhranyayet aktivnyij status.

## Istochniki

- [Komanda prodolzhatj posle kommita](../../Zhurnal/2026-09-09_21-31-19_MSK_prodolzhatj-rabotu-posle-kommita/zapros.md).
- [Etap adaptacii i doslovnyiye osnovaniya](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).
- [Publikacionno chistaya karta proiskhozhdeniya](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/materialyi/proiskhozhdeniye-obyazateljstv.json).
- [Kontrakt adaptera](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/svyazj-s-kommitom.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 12:39:57 MSK -->
<!-- content-sha256: sha256:86b890175f12ad70f3b45b4de2484c2e129aacfc348598a4ca6beeb9fab38c84 -->
<!-- FUM-MD-RECENCY:END -->
