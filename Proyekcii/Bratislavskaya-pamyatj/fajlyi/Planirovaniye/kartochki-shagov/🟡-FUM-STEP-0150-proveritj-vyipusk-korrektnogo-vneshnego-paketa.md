+++
schema_version = 1
card_id = "FUM-STEP-0150"
status = "active"
+++
# Proveritj vyipusk korrektnogo vneshnego paketa

## Zadacha

Podtverditj na otdeljnom zhivom primere, chto vneshnij proizvoditelj peredayot polnyij paket v1 s aktualjnoj bazoj, fakticheskimi razmerom i khyeshami, yedinstvennyim finaljnyim blokom i chitayemyim tekstom bez ruchnogo vosstanovleniya prinimayusjhej storonoj.

## Pochemu sejchas

Pri priyome inzhenernoj modeli iskhodnyij share i metadannyiye poslednego paketa ne proshli dejstvuyusjhij kontrakt. Lokaljnaya peresborka po otdeljnomu zaprosu sokhranila poleznoye soderzhaniye, no ne podtverdila rabotosposobnostj vneshnego vyipuska.

## Kriterii zaversheniya

- Podgotovlen minimaljnyij publikacionno chistyij primer na tochnoj opublikovannoj baze; polnyij paket zavershayet otdeljnyij share bez dopolniteljnyikh ograd.
- Bajtyi patcha, Base64, razmer, SHA-256 i Git OID vyichislenyi instrumentaljno v proizvodyasjhej srede.
- Neizmenyonnyij arkhiv prokhodit shtatnyij rezhim `проверить-share`; proiskhozhdeniye i vyivod proverki sokhranenyi.
- Soderzhimoye dekodirovannogo dokumenta nezavisimo svereno s prednaznachennyim tekstom.
- Iskhodyi i ogranicheniya svyazanyi s tochnyim proyavleniyem sboya; nevozmozhnostj vneshnego vyipuska ne maskiruyetsya lokaljnyim ispravleniyem.

## Istochniki

- [Iskhodnyij zapros](../../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [FUM-SBOJ-0023/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0023-nekorrektnyij-vneshnij-paket.md#proyavleniya).
- [Priyom vneshnego vklada](../../Dokumentaciya/51-proveryayemyij-priyom-vneshnego-vklada.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 18:43:58 MSK -->
<!-- content-sha256: sha256:2be1f4c1834c3dc69c0102bb03c4699e83ebad8017e0765bd4cfde34ba48e509 -->
<!-- FUM-MD-RECENCY:END -->
