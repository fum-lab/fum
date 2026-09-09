+++
schema_version = 1
card_id = "FUM-STEP-0171"
status = "active"
+++
# Proveryatj indeks do zakryitiya otchyota

## Zadacha

Avtomaticheski proveryatj podgotovlennyij indeks vmeste s rabochim derevom do neobratimogo zakryitiya otchyota priyomki.

## Pochemu sejchas

Propusjhennyij staged-only defekt obnaruzhen posle gotovogo v3-snimka, kotoryij neljzya shtatno vozobnovitj. Osnovaniye — FUM-SBOJ-0044/PROYAVLENIYE-0001.

## Kriterii zaversheniya

- RED vosproizvodit chistyij `git diff --check` i otkaz `git diff --cached --check` na odnom snimke.
- Priyomka otkazyivayet do zakryitiya i sokhranyayet nablyudayemyij rezuljtat bez ruchnoj pravki mashinnyikh zapisej.
- Ispravlennyij indeks prokhodit adresnuyu i obsjhuyu priyomku.
- Profilj pokazyivayet stoimostj dopolniteljnoj proverki; izmeneniye ne sozdayot rekursivnyiye polnyiye progonyi.

## Istochniki

- [FUM-SBOJ-0044/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0044-proverka-indeksa-propusjhena-do-zakryitiya-otchyota.md).
- [Zapros poljzovatelya](../../Zhurnal/2026-09-09_20-29-51_MSK_zavershitj-priyomku-ignorirovaniya-fajlov-macos/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 20:34:49 MSK -->
<!-- content-sha256: sha256:948d73a8a3f9cf95fcf997cb5f575314ee43ac329308bd0ffcfe0ee4de8d1d25 -->
<!-- FUM-MD-RECENCY:END -->
