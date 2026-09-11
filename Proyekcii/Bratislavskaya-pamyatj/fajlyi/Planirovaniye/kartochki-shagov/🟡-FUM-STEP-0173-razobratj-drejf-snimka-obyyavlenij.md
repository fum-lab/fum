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

Povtor `FUM-СБОЙ-0045/ПРОЯВЛЕНИЕ-0002` v FUM-STEP-0207 podtverzhdayet drejf uzhe v osnove `1aab4c016f726452861f42963b59b6ba66483437`: 43606 nablyudayemyikh obyyavlenij protiv 43163 sokhranyonnyikh, pri nulevoj deljte sobstvennyikh izmenenij perenosa. Razbor dolzhen obyyasnitj takzhe eti 443 Python-zapisi; obnovleniye khyesha bez proiskhozhdeniya ne yavlyayetsya ispravleniyem.

## Kriterii zaversheniya

- Poluchen vosproizvodimyij spisok dobavlenij, udalenij i peremesjhenij otnositeljno revizii snimka, s proiskhozhdeniyem po Git.
- Obyyasnenyi prezhniye 13 dopolniteljnyikh zapisej i izmeneniya pozicij; obyazateljnyiye vneshniye obyyavleniya otlichenyi ot sobstvennyikh proveryayemyim kontraktom.
- Nepravomernyiye novyiye imena ustranenyi; snimok obnovlyon toljko posle razbora i podtverzhdyon proverkoj.
- Izmeneniya ispolnyayemogo kontrolya prokhodyat RED/GREEN, profilj i optimizaciyu bez oslableniya granicyi.

## Istochniki

- [FUM-SBOJ-0045/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md).
- [FUM-SBOJ-0045/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0045-drejf-snimka-obyyavlenij-koda.md) i [sverka s osnovoj](../../Zhurnal/2026-09-11_07-17-34_MSK_realizovatj-perenos-rabochikh-derevjyev/materialyi/profilj/deljta-obyyavlenij.json).
- [Nablyudeniye v etape adaptacii](../../Zhurnal/2026-09-10_00-49-43_MSK_svyazatj-proverki-s-kommitami/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:07:22 MSK -->
<!-- content-sha256: sha256:0be87a6ea9722284603ff50b1318caaab4f78aba00234ee7d19dfd9ef582ad51 -->
<!-- FUM-MD-RECENCY:END -->
