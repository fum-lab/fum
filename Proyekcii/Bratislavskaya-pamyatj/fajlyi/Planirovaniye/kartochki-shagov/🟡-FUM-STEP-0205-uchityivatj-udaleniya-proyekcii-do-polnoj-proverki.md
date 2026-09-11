+++
schema_version = 1
card_id = "FUM-STEP-0205"
status = "active"
+++
# Uchityivatj udaleniya proyekcii do polnoj proverki

## Zadacha

Avtomatizirovatj predvariteljnoye sopostavleniye ozhidayemyikh udalenij prezhnego pokoleniya proyekcii s tochnoj oblastjyu tekusjhego zaprosa do dorogogo polnogo dopuska.

## Pochemu sejchas

FUM-SBOJ-0035/PROYAVLENIYE-0002 povtorilo uzhe vosstanovlennyij lokaljnyij propusk: ssyilka na susjhestvuyusjhij katalog ne obyyavlyayet udaleniye prezhnej kartochki. Ruchnoj marker ispravil odin vkhod posle otkaza shaga 11; nuzhna vosproizvodimaya podgotovka do zapuska.

## Kriterii zaversheniya

- Obobsjhyonnyiye fiksturyi oboikh proyavlenij vosproizvodyat pozdnij propusk udalyonnogo puti do ispravleniya.
- Sukhoj vyivod ispoljzuyet podtverzhdyonnoye vladeniye staryim pokoleniyem i ozhidayemyij novyij plan; sokhranyayet tochnyiye repozitornyiye puti i osnovaniye kazhdogo udaleniya bez zapisi v poljzovateljskoye derevo.
- Primeneniye soglasovannyikh markerov proveryayet neizmennostj vkhoda; povtor ne dubliruyet svedeniya. Nepodtverzhdyonnoye udaleniye ne poluchayet razresheniya avtomaticheski.
- Polozhiteljnyiye pereimenovaniya, sosedniye prefiksyi, neizvestnoye udaleniye, izmenivsheyesya pokoleniye i nevernaya oblastj proverenyi otdeljno; susjhestvuyusjhij strogij zapret ne oslablen.
- Shtatnyij marshrut podgotovki zaprosa ispoljzuyet rezuljtat do polnogo smoke; instrukciya, RED/GREEN, profilj i resheniye ob optimizacii sokhranenyi.

## Istochniki

- [FUM-SBOJ-0035](../../Sboi/FUM-SBOJ-0035-propusk-udalyonnogo-puti-proyekcii-v-zaprose.md): osnovaniye FUM-SBOJ-0035/PROYAVLENIYE-0002.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:7400650773b952815d58316a3d7acf7c86b8dbc51fdfd6492610354e464f1287 -->
<!-- FUM-MD-RECENCY:END -->
