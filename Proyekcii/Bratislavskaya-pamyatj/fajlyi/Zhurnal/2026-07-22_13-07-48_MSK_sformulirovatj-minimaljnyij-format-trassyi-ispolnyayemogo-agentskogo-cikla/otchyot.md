# Otchyot 2026-07-22 13:07:48 MSK - Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla

Pamyatj FUM poluchila minimaljnyij mashinno chitayemyij kontrakt nablyudayemoj rabotyi agenta do realizacii runtime. Format otdelyayet proveryayemyiye sobyitiya ot skryityikh rassuzhdenij i sokhranyayet oshibku nezavisimo ot resheniya prodolzhitj ili ostanovitjsya.

## Rezuljtat

[Specifikaciya versii 1](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) zadayot append-only JSONL-posledovateljnostj. Kazhdaya stroka imeyet versiyu, identifikator trassyi, nepreryivnyij nomer, odin iz semi tipov i tochnyij payload. Neizvestnyiye polya trebuyut novoj versii, poetomu rasshireniye ne menyayet molcha smyisl uzhe sokhranyonnyikh sobyitij.

`FUM-STEP-0023` zavershena po fakticheskomu rezuljtatu. Napravleniye i MVP-kandidat teperj ssyilayutsya na prinyatyiye specifikaciyu i fiksturu, no chestno ostavlyayut ispolnitelj sleduyusjhim inzhenernyim sloyem.

## Minimaljnyij format trassyi

- `task` fiksiruyet kriterii, proiskhozhdeniye, allowlist dejstvij i yavnyij rezhim modeljnogo shaga.
- `observation` sokhranyayet publikacionno chistyij vneshnij fakt s dokazateljstvami.
- `action` zapisyivayet operaciyu, adapter, effekt, celi i osnovaniye razresheniya do ispolneniya.
- `result` libo `error` svyazyivayut fakticheskij iskhod s dejstviyem.
- `check` proveryayet uzhe nablyudayemyij iskhod vneshnim kriteriyem.
- `continuation` nezavisimo reshayet prodolzhitj, zavershitj, zablokirovatj, zaprositj podtverzhdeniye, peredatj, ostanovitj ili priznatj nevosstanovimyij neuspekh.

## Proverka lokaljnoj fiksturyi

Odna korotkaya read-only-zadacha namerenno nachinayet s otsutstvuyusjhego otnositeljnogo puti. Trassa sokhranyayet `FILE_NOT_FOUND`, vyibirayet `continue`, chitayet statjyu [«Agentskij cikl»](../../Glossarij/agentskij-cikl.md), proveryayet yeyo zagolovok i zavershayet progon. Eto pokazyivayet vse semj tipov sobyitij, vosstanovleniye posle oshibki i terminaljnyij status bez vneshnego mira i modeljnogo provajdera.

Dva posledovateljnyikh razbora standartnoj bibliotekoj Python podtverdili odinakovyiye obyazateljnyiye polya, poryadok, ssyilki mezhdu sobyitiyami, allowlist, statusyi i otsutstviye polej skryitogo rassuzhdeniya. Otdeljno proverenyi JSON-sintaksis skhemyi, fakticheskoye otsutstviye testovogo puti, zagolovok kanonicheskogo dokumenta i otsutstviye lokaljnyikh absolyutnyikh putej v mashinnyikh artefaktakh.

## Granica primenimosti

Format ne yavlyayetsya dokazateljstvom ispolneniya sam po sebe: dejstviye podtverzhdayut toljko svyazannyij rezuljtat, oshibka i proverka. Versiya `1` ne zadayot paralleljnyiye vetvi, chasyi, byudzhetyi, stoimostj, ocenku produktivnosti, dolgovremennoye khraneniye, vneshnij servis, fizicheskoye dejstviye ili skryityiye tokenyi modeli. Tekusjhaya sessiya Codex takzhe ne vyidayotsya za realizovannyij runtime FUM.

## Prodolzheniye

Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0070` yedinstvennyim `ready`. Etot shag ustranyayet obnaruzhennyiye mashinno-lokaljnyiye absolyutnyiye puti i dobavlyayet ikh avtomaticheskuyu proverku; on lokaljno ispolnim, ne trebuyet novogo vneshnego razresheniya i zakryivayet raneye zafiksirovannyiye P1/P2-riski publikacii i perenosimosti.

## Zatronutyiye materialyi

- [specifikaciya minimaljnoj trassyi](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)
- [mashinnaya skhema sobyitiya](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v1.json)
- [lokaljnaya fikstura](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-korotkoj-lokaljnoj-zadachi.jsonl)
- [napravleniye agentskogo cikla](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md)
- [MVP-kandidat](../../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [zavershyonnaya kartochka FUM-STEP-0023](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0023-sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [obzor aktualjnyikh realizacij agentskikh ciklov](../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [predyidusjhij audit absolyutnyikh putej](../2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:84d1d288b169e2369593e34bd52187db3f2cc2e857f943cf8beb3ae7847742cc -->
<!-- FUM-MD-RECENCY:END -->
