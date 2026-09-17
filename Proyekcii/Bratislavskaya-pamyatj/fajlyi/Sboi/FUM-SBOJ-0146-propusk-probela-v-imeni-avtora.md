+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0146"
"статус" = "активна"
+++
# Propusk probela v imeni avtora

## Nablyudayemyij sboj

Dva opublikovannyikh kommita poluchili bukvaljnoye imya avtora `FUMИнтегратор` bez obyichnogo probela. Naznachennaya rolj — `FUM Интегратор`. Kommitter i email ostalisj iskhodnyimi.

## Granica povtoreniya

Dva samostoyateljnyikh sozdaniya kommita v postoyannoj vetke planirovaniya. Opublikovannyiye obyyektyi neizmennyi; avtomatizaciya dolzhna predotvrasjhatj novyiye proyavleniya, a ne perepisyivatj istoriyu.

## Proyavleniya

1. `74252ec580be30e2781b158d3a248d5c01c5f98e` — avtor bez probela, committer `FUM`.
2. `34af8b6594e5de670c69b81e05c3673f7b1c6d77` — povtor pri sliyanii s dvumya roditelyami.

V prezhnem `72c7f064abbd901dbb01b2890c23bc20c64e7962` probel prisutstvuyet. Vse tri syiryikh nabora polej nezavisimo prochitanyi iz Git.

## Ozhidaniye i klassifikaciya

Eto nevernoye ruchnoye znacheniye `GIT_AUTHOR_NAME`, proshedsheye prezhnyuyu proverku svyaznosti. Prezhnij [FUM-SBOJ-0047](FUM-SBOJ-0047-podmena-committer-pri-vyibore-roli-avtora.md) otnositsya k podmene committer; zdesj committer sokhranyon. Sovpadeniye temyi avtorstva ne dokazyivayet odnu granicu regressii.

## Mekhanizm i sistemnoye ustraneniye

Polnyij putj podgotovki i sozdaniya proveryayet naznachennuyu rolj s obyichnyim probelom, pervichnyiye komandyi, UUID, nablyudayemuyu modelj, indeks i obyazateljnyiye proverki; posle Git sveryayet obyyekt. Realjnyiye fiksturyi obyichnogo i merge-kommita prokhodyat. Itogovyij rezhim poka yavno otkazyivayet do proverennogo vklyucheniya zamyikaniya proyekcii. Uspekh fikstur ne zakryivayet priyomku instrumenta.

## Svyazannyiye shagi

- [FUM-STEP-0230 — Sozdavatj kommityi cherez proveryayemyij putj](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0230-sozdavatj-kommityi-cherez-proveryayemyij-putj.md).

## Kriterii zakryitiya

Prinyat povtorno primenimyij putj s otricateljnyimi i polozhiteljnyimi proverkami obyazateljnyikh polej, vosproizvodimyim profilem, dokumentaciyej, fakticheskoj kontroljnoj tochkoj i otdeljno proverennyim itogovyim rezhimom. Opublikovannyiye oshibochnyiye OID sokhranenyi kak proiskhozhdeniye.

## Istochniki

- [Iskhodnyiye komandyi](../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/zapros.md).
- [Nablyudyonnyiye polya Git](../Zhurnal/2026-09-15_22-54-33_MSK_oformitj-napravleniye-proyektirovaniya-chipov/materialyi/nablyudeniye-avtorov.json).
- [Realizaciya i ogranicheniya](../Instrumentyi/fum-svyaznostj-rabochej-sessii/sozdaniye-kommita.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 00:03:24 MSK -->
<!-- content-sha256: sha256:bbfc2ed7940b4db71b86d6d31562d7ecf12155cc9be747552032880623f91bf0 -->
<!-- FUM-MD-RECENCY:END -->
