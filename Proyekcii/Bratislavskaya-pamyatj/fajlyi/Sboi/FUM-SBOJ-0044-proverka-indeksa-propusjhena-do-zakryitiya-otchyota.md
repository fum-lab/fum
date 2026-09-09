+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0044"
"статус" = "активна"
+++
# Proverka indeksa propusjhena do zakryitiya otchyota

Do zakryitiya mashinnogo otchyota agent proveril rabochuyu kopiyu komandoj `git diff --check`, no ne podgotovlennyij indeks cherez `git diff --cached --check`. Poslednyaya komanda posle zakryitiya obnaruzhila lishnij LF v konce indeksirovannogo izmeritelya. Uspekh testov i manifesta ne podtverdil etu otdeljnuyu granicu.

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0044/ПРОЯВЛЕНИЕ-0001`: pozdnij otkaz zamyikaniya s kodom 2 posle gotovogo v3-snimka priyomki 18:43; [adresnoye vosproizvedeniye](../Zhurnal/2026-09-09_20-29-51_MSK_zavershitj-priyomku-ignorirovaniya-fajlov-macos/materialyi/zapuski-proverok/1_28323153-a17b-4021-b12a-6f0b824404fc.json) sokhranilo tot zhe defekt do ispravleniya. Pervoye nablyudeniye nakhodilosj vne zakryitoj mashinnoj granicyi i ne vyidano za novyij zapusk v starom otchyote.

## Vosstanovleniye i sistemnaya mera

Udalyon odin zavershayusjhij LF; AST neizmenen. Istoricheskij profilj i 30 mashinnyikh zapisej sokhranenyi. Novaya zhurnaljnaya granica otnositsya k nastoyasjhej komande poljzovatelya o macOS v toj zhe kornevoj zadache. Provoditsya novaya priyomka do odnogo obsjhego kommita. Eto procedurnoye vosstanovleniye; avtomaticheskij zapret prezhdevremennogo zakryitiya yesjhyo ne realizovan.

## Svyazannyiye shagi

- [FUM-STEP-0171](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0171-proveryatj-indeks-do-zakryitiya-otchyota.md); osnovaniye — `FUM-СБОЙ-0044/ПРОЯВЛЕНИЕ-0001`.

## Kriterij zakryitiya

Shtatnyij cikl proveryayet exact diff rabochego dereva i indeksa do neobratimogo zakryitiya; regressiya podtverzhdayet otkaz na staged-only defekte. Otdeljnyij budusjhij kontrakt povtornoj priyomki posle gotovogo snimka ne dolzhen perepisyivatj staroye svideteljstvo.

## Istochniki

- [Zapros poljzovatelya](../Zhurnal/2026-09-09_20-29-51_MSK_zavershitj-priyomku-ignorirovaniya-fajlov-macos/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 20:34:49 MSK -->
<!-- content-sha256: sha256:bede9facf5d2b9620c0eeabb1a874334845d5f6dbaf967c5cd671c62c43ddfb5 -->
<!-- FUM-MD-RECENCY:END -->
