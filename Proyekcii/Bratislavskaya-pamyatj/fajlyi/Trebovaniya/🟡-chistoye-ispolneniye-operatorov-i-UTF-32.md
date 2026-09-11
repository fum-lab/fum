# Chistoye ispolneniye operatorov i UTF-32

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0067 -->

Strukturiruyusjhiye operatoryi FUM dolzhnyi dopuskatj chistoye ispolneniye konechnyikh opredelenij nad otdeljnyimi vkhodnyimi znacheniyami. Vyichisleniye rezuljtata otdelyayetsya ot sravneniya s proverochnyimi ozhidaniyami, a nablyudeniye sokhranyayet proiskhozhdeniye opredeleniya, vkhoda i ogranichennoj trassyi.

Pervyij predmetnyij kontrakt — strogoye dekodirovaniye iskhodnyikh bajtov UTF-8 v Unicode-skalyaryi s otdeljnoj yavno vyibrannoj serializaciyej UTF-32LE ili UTF-32BE. Konkretnyiye pravila dekodirovaniya vyirazhayutsya opredeleniyami operatorov nad konechnyimi obsjhimi primitivami.

## Semanticheskiye svyazi

- **dopolnyayet:** [prototipyi kak testyi realizacii kornevogo yadra FUM](🟡-prototipyi-kak-testyi-realizacii-kornevogo-yadra-FUM.md) — otdelyonnoye ispolneniye i nezavisimyiye ozhidaniya dayut nablyudayemyij kontrakt dlya budusjhego sravneniya realizacij; povtornyij vyizov odnogo dvizhka ne obyyavlyayetsya nezavisimyim podtverzhdeniyem yadra.

## Kriterii proverki

- Chistoye ispolneniye prinimayet opredeleniye i otdeljnyij vkhod; ozhidayemyij otvet ne yavlyayetsya yego argumentom. Proverochnyij adapter sravnivayet samostoyateljnoye nablyudeniye s zaraneye zakreplyonnyimi ozhidaniyami.
- Identichnostj vklyuchayet versiyu, argumentyi i poryadok opredeleniya, tochnyiye vkhodnyiye bajtyi i ogranichennuyu trassu; podmena opredeleniya nablyudayema dazhe pri odinakovom itogovom rezuljtate.
- Zakryitaya skhema i konechnyiye resursnyiye predelyi dayut yavnyiye otkazyi dlya neizvestnyikh polej, neodnoznachnyikh imyon, nevernyikh argumentov i prevyisheniya byudzheta.
- Bajtyi, tekst i Unicode-skalyaryi razlichayutsya. Nekorrektnyij iskhodnyij UTF-8 ne ispravlyayetsya molcha i vozvrasjhayet oshibku s absolyutnoj poziciyej bajta.
- Opredeleniye pokryivayet dopustimyiye dlinyi i diapazonyi UTF-8; izbyitochnyiye kodirovki, surrogatyi, znacheniya vyishe U+10FFFF i nezavershyonnyij konec otklonyayutsya. UTF-32 imeyet yavno vyibrannyij poryadok bajtov, bez neyavnoj normalizacii i BOM.
- Polozhiteljnyiye i otricateljnyiye otkryityiye fiksturyi, staryiye scenarii prototipa i profilj vremeni vosproizvodimyi avtonomno. Ozhidaniya i normativnaya versiya Unicode zakreplenyi nezavisimo ot proveryayemogo vyichisleniya.

## Status i granicyi

Status trebovaniya — `🟡`: interpretator s predmetnyim primerom UTF-8 → UTF-32 prinyat k realizacii. Pervyij ogranichennyij rezuljtat zadayot FUM-STEP-0208. On ne podtverzhdayet universaljnyij yazyik, nezavisimuyu realizaciyu yadra, potokovuyu obrabotku porciyami ili bezopasnostj proizvoljnogo vneshnego koda.

## Istochniki trebovanij

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:26:18 MSK -->
<!-- content-sha256: sha256:9432d09a6e2a5c071f0b216e29b0e881359b780d7d012e19fd21e300688a0eab -->
<!-- FUM-MD-RECENCY:END -->
