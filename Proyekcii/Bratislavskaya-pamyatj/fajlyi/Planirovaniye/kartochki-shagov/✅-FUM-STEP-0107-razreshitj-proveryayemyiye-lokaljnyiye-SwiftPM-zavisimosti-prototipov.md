+++
schema_version = 1
card_id = "FUM-STEP-0107"
status = "completed"
+++
# Razreshitj proveryayemyiye lokaljnyiye SwiftPM-zavisimosti prototipov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj obsjhij smoke-check versionnyim vosproizvodimyim offline-kontraktom, kotoryij razreshayet verkhneurovnevomu SwiftPM-prototipu zavisetj toljko ot yavno zaregistrirovannyikh sosednikh paketov vnutri `Прототипы/`. Kontrakt dolzhen proveryatj kanonicheskiye otnositeljnyiye puti, fakticheskiye package identity i product-svyazi, ne otkryivaya setj, mashinno-lokaljnyiye puti ili proizvoljnyiye zavisimosti.

## Rezuljtat

Politika SwiftPM perevedena na skhemu `2`: kazhdyij paket khranit tochnyij `localDependencies`, a pustoj allowlist sokhranyayet prezhnij strogij zapret lyubyikh zavisimostej. Razreshyonnaya svyazj fiksiruyet kanonicheskij repo-relative-putj zaregistrirovannogo sosednego paketa, yego fakticheskuyu identity i tochnyiye paryi potreblyayusjhej celi s bibliotechnyim produktom provajdera.

Podgotovka razbirayet toljko literaljnyij massiv `dependencies:` kornevogo `let package = Package(...)`, trebuyet tochnuyu formu `.package(path: "../<сосед>")` i sopostavlyayet yeyo s `swift package dump-package`. Absolyutnyij `fileSystem.path` raskryivayetsya cherez `realpath`, proveryayetsya na nakhozhdeniye vnutri repozitoriya i `Прототипы/` i normalizuyetsya obratno v repo-relative-putj. Drejf puti, identity, product-svyazi ili grafa, absolyutnyiye, vyichislyayemyiye i nekanonicheskiye puti, vyikhod cherez simvolicheskuyu ssyilku, self-dependency, dublikatyi, ciklyi, vneshnyaya `byName`-svyazj i source-control-, registry-, binary- libo neizvestnyiye zavisimosti zakryivayutsya otkazom do testov i sborki.

`dump-package`, `swift test` i `swift build` ispoljzuyut yedinyij offline-nabor bez prefetch, avtomaticheskoj rezolyucii, credential-khranilisjh i poljzovateljskogo dependency-kyesha. Regressiya snachala zakrepila prezhnij otkaz skhemyi `1`, zatem postroila realjnuyu kompoziciyu dvukh vremennyikh paketov i provela yeyo cherez podgotovku, testyi, sborki i strogij lint. Dokumentaciya opisyivayet skhemu, modelj ugroz i poryadok registracii novoj svyazi; polnyij smoke-check podtverzhdayet susjhestvuyusjhij inventarj.

## Istochniki

- [poglosjhyonnaya FUM-STEP-0103 — skvoznoj odnoagentnyij epizod](🧩-FUM-STEP-0103-realizovatj-skvoznoj-odnoagentnyij-epizod-s-vozobnovleniyem.md)
- [kontrakt obsjhego smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [politika SwiftPM-paketov](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/swift-package-policy.json)
- [chistyij modeljnyij shag](../../Prototipyi/chistyij-modeljnyij-shag/README.md)
- [vosproizvodimoye popolneniye pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md)
- [iskhodnyij dispetcherskij zapros o vyipolnenii FUM-STEP-0103](../../Zhurnal/2026-07-30_11-42-13_MSK_dekompozirovatj-realizaciyu-skvoznogo-odnoagentnogo-epizoda/zapros.md)
- [iskhodnyij dispetcherskij zapros o vyipolnenii FUM-STEP-0107](../../Zhurnal/2026-07-31_10-24-29_MSK_razreshitj-proveryayemyiye-lokaljnyiye-SwiftPM-zavisimosti-prototipov/zapros.md)
- [zhurnal vyipolneniya FUM-STEP-0107](../../Zhurnal/2026-07-31_10-24-29_MSK_razreshitj-proveryayemyiye-lokaljnyiye-SwiftPM-zavisimosti-prototipov/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d8b5d22d6c2bb4d97958bc2c87804a6753fadb52c647f446e058cb200b35f6bf -->
<!-- FUM-MD-RECENCY:END -->
