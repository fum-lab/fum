+++
schema_version = 1
card_id = "FUM-STEP-0170"
status = "active"
+++
# Sokhranyatj neizmennostj vkhoda do zaversheniya proverki

## Zadacha

Svyazatj soderzhateljnoye redaktirovaniye i zapusk proverok s yavnoj identichnostjyu vkhoda, chtobyi izmeneniye proveryayemogo fajla ne proiskhodilo nezametno do zaversheniya processa.

## Pochemu sejchas

Adresnaya svyaznostj otkazala posle izmeneniya otchyota vo vremya proverki. Osnovaniye — FUM-SBOJ-0043/PROYAVLENIYE-0001; vosstanovleniye poka procedurnoye.

## Kriterii zaversheniya

- RED vosproizvodit popyitku izmeneniya proveryayemogo vkhoda vo vremya processa.
- Shtatnyij redaktor otkazyivayet do zapisi libo yavno zavershayet proverku kak utrativshuyu aktualjnostj do izmeneniya fajla.
- Zaversheniye i preryivaniye osvobozhdayut ogranicheniye; otkaz ne blokiruyet posleduyusjheye razreshyonnoye redaktirovaniye.
- Adresnyiye testyi, profilj i obsjhaya priyomka podtverzhdayut vyibrannyij kontrakt.
- Dlya FUM-SBOJ-0078/PROYAVLENIYE-0002 zavisimyij kommit otklonyayetsya pri zhivoj proverke, otsutstvii terminaljnogo rezuljtata ili neuspekhe; dopuskayetsya toljko posle nablyudyonnogo koda 0 na tom zhe vkhode. Otricateljnyiye i polozhiteljnyij kontroli sokhranenyi razdeljno.

## Dopolniteljnaya granica zavisimogo kommita

Osnovaniye — [FUM-SBOJ-0078/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0078-rannij-zapusk-potrebitelya-do-zaversheniya-proizvoditelya.md): kommit byil sozdan posle rannego vozvrata pustogo vyivoda, no do pozdnego koda 1 proverki. Nuzhnyi otdeljnyiye otricateljnyiye kontroli zavisimogo kommita pri zhivom processe, otsutstvii terminaljnogo rezuljtata i neuspekhe; polozhiteljnyij kontrolj dopuskayetsya toljko posle nablyudyonnogo koda 0 na tom zhe vkhode. Iskhodnyiye kriterii neizmennosti sokhranyayutsya. Zdesj zaregistrirovana neobkhodimaya mera, yeyo realizaciya ne vyipolnena.

## Istochniki

- [Pervichnyiye granicyi i korrekciya](../../Zhurnal/2026-09-16_00-09-04_MSK_razdelitj-svideteljstva-i-planyi-mediapaketa/materialyi/korrekciya-istorii.md).

- [FUM-SBOJ-0043/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0043-izmeneniye-proveryayemogo-snimka-do-zaversheniya-proverki.md).
- [Tekusjhij zapros](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 01:01:16 MSK -->
<!-- content-sha256: sha256:5525029620063a27967f713cae8b3680ce0e1770df2fdcd3cc826beb435d850d -->
<!-- FUM-MD-RECENCY:END -->
