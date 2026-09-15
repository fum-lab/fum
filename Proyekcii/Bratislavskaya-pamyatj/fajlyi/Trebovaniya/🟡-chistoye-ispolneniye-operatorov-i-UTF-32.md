# Chistoye ispolneniye operatorov i UTF-32

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0067 -->

Strukturiruyusjhiye operatoryi FUM dolzhnyi dopuskatj chistoye ispolneniye konechnyikh opredelenij nad otdeljnyimi vkhodnyimi znacheniyami. Vyichisleniye rezuljtata otdelyayetsya ot sravneniya s proverochnyimi ozhidaniyami, a nablyudeniye sokhranyayet proiskhozhdeniye opredeleniya, vkhoda i ogranichennoj trassyi.

Pervyij predmetnyij kontrakt — strogoye dekodirovaniye iskhodnyikh bajtov UTF-8 v Unicode-skalyaryi s otdeljnoj yavno vyibrannoj serializaciyej UTF-32LE ili UTF-32BE. Konkretnyiye pravila dekodirovaniya vyirazhayutsya opredeleniyami operatorov nad konechnyimi obsjhimi primitivami.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [planom razbora shriftov strukturiruyusjhimi operatorami](🟡-plan-razbora-shriftov-strukturiruyusjhimi-operatorami.md) — otdeljnyij formatnyij profilj ispoljzuyet to zhe razdeleniye opredeleniya, bajtovogo vkhoda i nezavisimyikh ozhidanij.

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
- [Postanovka shriftovogo profilya](../Zhurnal/2026-09-11_16-55-35_MSK_utochnitj-operatornoye-vnimaniye-i-prodolzhitj-priyom/zapros.md).

- [Iskhodnaya komanda](../Zhurnal/2026-09-11_07-19-51_MSK_prinyatj-postanovku-interpretatora/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 04:26:02 MSK -->
<!-- content-sha256: sha256:0d5e8138903c270edaf65919dffee1c4972ed7e6f93f5a67a159a85fad11bd5d -->
<!-- FUM-MD-RECENCY:END -->
