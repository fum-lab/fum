+++
schema_version = 1
card_id = "FUM-STEP-0173"
status = "active"
+++
# Razobratj drejf snimka obyyavlenij

## Zadacha

Sopostavitj ostatok obyyavlenij s reviziyej sokhranyonnogo snimka i vosstanovitj dokazuyemuyu granicu kontrolya bez prinyatiya neobyyasnyonnyikh latinskikh imyon.

## Pochemu sejchas

Dopolniteljnaya proverka vyiyavila raskhozhdeniye, susjhestvuyusjheye i bez novyikh iskhodnikov adaptera. Uzkaya proverka poslednego etapa pokazyivayet toljko obyazateljnyij vneshnij metod `unittest.TestCase.setUp`. Osnovaniye — `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0001`.

## Kriterii zaversheniya

- Poluchen vosproizvodimyij spisok dobavlenij, udalenij i peremesjhenij otnositeljno revizii snimka, s proiskhozhdeniyem po Git.
- Obyyasnenyi prezhniye 13 dopolniteljnyikh zapisej i izmeneniya pozicij; obyazateljnyiye vneshniye obyyavleniya otlichenyi ot sobstvennyikh proveryayemyim kontraktom.
- Nepravomernyiye novyiye imena ustranenyi; snimok obnovlyon toljko posle razbora i podtverzhdyon proverkoj.
- Izmeneniya ispolnyayemogo kontrolya prokhodyat RED/GREEN, profilj i optimizaciyu bez oslableniya granicyi.

## Istochniki

- [FUM-SBOJ-0045/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md).
- [Nablyudeniye v etape adaptacii](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 01:19:47 MSK -->
<!-- content-sha256: sha256:c027e1d475d307543c71b6db9fb4f663493d65de155618677af931afba654b79 -->
<!-- FUM-MD-RECENCY:END -->
