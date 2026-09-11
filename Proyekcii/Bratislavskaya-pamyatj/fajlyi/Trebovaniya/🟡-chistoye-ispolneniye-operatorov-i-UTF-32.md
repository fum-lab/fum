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

Status trebovaniya — `🟡`: konechnyij kontrakt realizovan v [prototipe](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/konechnoye-ispolneniye.md) po FUM-STEP-0208; [otchyot realizacii](../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/otchyot.md) sokhranyayet adresnyiye RED/GREEN, nezavisimyiye ozhidaniya i profilj. Eto rezuljtat sobstvennoj vetki; integraciya v osnovnuyu pamyatj proveryayetsya otdeljno. On ne podtverzhdayet universaljnyij yazyik, nezavisimuyu realizaciyu yadra, potokovuyu obrabotku porciyami ili bezopasnostj proizvoljnogo vneshnego koda.

## Istochniki trebovanij

- [Zapros realizacii](../Zhurnal/2026-09-11_07-43-37_MSK_realizovatj-interpretator-i-UTF-32/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:27:58 MSK -->
<!-- content-sha256: sha256:cf49feb2146bc4b10187c83f06e473231f83b9be86f6747c07f4b8f45af294ae -->
<!-- FUM-MD-RECENCY:END -->
