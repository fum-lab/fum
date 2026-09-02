+++
schema_version = 1
card_id = "FUM-STEP-0072"
status = "completed"
+++
# Opisatj perenapravleniye agentskogo cikla poljzovateljskim vvodom

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj nablyudayemyij kontrakt trassyi [agentskogo cikla](../../Glossarij/agentskij-cikl.md) i podgotovitj determinirovannuyu lokaljnuyu fiksturu, v kotoroj razreshyonnyij poljzovateljskij vvod postupayet do zaversheniya tekusjhego plana, na bezopasnoj kontroljnoj tochke menyayet celj, prioritet, vetku libo dejstviye i sokhranyayet proiskhozhdeniye prezhnego i novogo prodolzhenij. Otdeljno razlichitj diskretnoye soobsjheniye-zadachu, potok sobyitij vvoda i ikh vozmozhnoye agregirovannoye predstavleniye; ne dobavlyatj vneshniye effektyi i ne raskryivatj skryityiye rassuzhdeniya modeli.

## Rezuljtat

[Minimaljnyij format trassyi](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) rasshiren versiyej `2` bez izmeneniya stabiljnoj versii `1`. [Mashinnaya skhema](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v2.json) sokhranila semj prezhnikh tipov i dobavila `plan`, `input_event`, `input_signal`, `checkpoint` i `redirect`. Diskretnyij `task`, pervichnoye sobyitiye potoka i proizvodnyij agregat poluchili raznyiye obyazateljnyiye polya i yavnyiye ssyilki proiskhozhdeniya.

[Lokaljnaya JSONL-fikstura](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-perenapravleniya-poljzovateljskim-vvodom-v2.jsonl) provodit razreshyonnyij vvod cherez dva pervichnyikh sobyitiya i agregat, fiksiruyet iskhodnyij plan i prodolzheniye, bezopasnuyu kontroljnuyu tochku bez dejstviya v polyote, otdeljnoye resheniye o smene celi, vetki i dejstviya, novuyu reviziyu plana i proverennoye zaversheniye lokaljnogo chteniya. Obratnyiye ssyilki sokhranyayut poryadok i proiskhozhdeniye starogo i novogo prodolzhenij.

Avtonomnyij stdlib-only-test `test_perenapravleniye_agentskogo_cikla.py` proveryayet polozhiteljnyij scenarij, proiskhozhdeniye vsekh perekhodov, fakticheskij lokaljnyij zagolovok, uspeshnyiye rezuljtat i proverku, osnovaniye zaversheniya i nabor otricateljnyikh sluchayev bez seti, sekretov, vneshnego dejstviya i realjnoj LLM. Strukturnyij zapret specialjnyikh polej skryityikh rassuzhdenij ne podmenyayet publikacionnuyu proverku smyisla kratkikh nablyudayemyikh polej. Rezuljtat ogranichen staticheskim formatom i sinteticheskoj read-only-fiksturoj: rabotayusjhij kanal sobyitij, primeneniye politiki dopuska, dolgovremennyij runtime, vosstanovleniye i neblokiruyusjheye modeljnoye prodolzheniye ne realizovanyi.

## Istochniki

- [iskhodnyij zapros 2026-07-29 13:22:54 MSK — Opisatj perenapravleniye agentskogo cikla poljzovateljskim vvodom](../../Zhurnal/2026-07-29_13-22-54_MSK_opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK — Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)
- [trebovaniye FUM-REQ-0017](../../Trebovaniya/🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md)
- [trebovaniye FUM-REQ-0018](../../Trebovaniya/🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md)
- [minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)
- [kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md)
- [zhurnal rabochej sessii](../../Zhurnal/2026-07-29_13-22-54_MSK_opisatj-perenapravleniye-agentskogo-cikla-poljzovateljskim-vvodom/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:86799df1bd2e409d6cb2cf9a829a40c66a9c5784bc9c569ca8baa4e8a73286af -->
<!-- FUM-MD-RECENCY:END -->
