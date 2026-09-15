+++
schema_version = 1
card_id = "FUM-STEP-0168"
status = "active"
+++
# Sokhranyatj mashinnyij zagolovok pri zapolnenii otchyota

## Zadacha

Predostavitj operaciyu obnovleniya soderzhateljnyikh razdelov otchyota, kotoraya sokhranyayet tochnyij sgenerirovannyij H1 i ne trebuyet povtoryatj yego vruchnuyu.

## Pochemu sejchas

Pri tekusjhej priyomke ruchnaya perepisj karkasa zamenila obyazateljnyij defis tipografskim tire. Validator predotvratil fiksaciyu, no potrebovalsya dopolniteljnyij cikl vosstanovleniya. Osnovaniye — FUM-SBOJ-0041/PROYAVLENIYE-0001.

## Kriterii zaversheniya

- RED vosproizvodit drejf H1 pri obnovlenii soderzhimogo.
- Shtatnoye obnovleniye sokhranyayet mashinnyij zagolovok i otklonyayet neyavnuyu zamenu do zapisi.
- Podtverzhdenyi razreshyonnyiye pravki razdelov, sokhrannostj iskhodnogo teksta i navigacii, otkaz neodnoznachnomu karkasu.
- Adresnyiye testyi, sorazmernyij profilj i obsjhaya priyomka podtverzhdayut ustojchivoye predotvrasjheniye FUM-SBOJ-0041.

## Utochneniye sokhrannosti navigacii

`FUM-СБОЙ-0106/ПРОЯВЛЕНИЕ-0001` dobavlyayet adresnyij scenarij start s vvodnyim abzacem vnutri upravlyayemoj navigacii. Nuzhnyi tochnoye sokhraneniye teksta libo otkaz do zapisi pri neodnoznachnom karkase, sokhrannostj obyichnogo obnovleniya sosednikh ssyilok i dokumentirovannaya granica razmesjheniya poyasnenij. Ruchnoye vosstanovleniye tekusjhego abzaca ne zakryivayet etot kriterij i ne zamenyayet realizaciyu iskhodnyikh trebovanij k H1.

`FUM-СБОЙ-0106/ПРОЯВЛЕНИЕ-0002` podtverzhdayet povtor togo zhe mekhanizma v repair pri obyyedinenii arkhivov. Priyomka okhvatyivayet oba vkhoda start i repair: soderzhateljnyij abzac vnutri upravlyayemogo bloka sokhranyayetsya tochno libo vyizyivayet otkaz do zapisi. Perenos vosstanovlennogo abzaca za granicu navigacii zasjhisjhayet tekusjhij dokument, no ne dokazyivayet ispravleniye avtomatizacii.

## Istochniki

- [Povtor pri obyyedinenii arkhiva](../../Zhurnal/2026-09-12_05-27-53_MSK_obyyedinitj-arkhiv-fuma-s-kornevoj-rabotoj/zapros.md) — `FUM-СБОЙ-0106/ПРОЯВЛЕНИЕ-0002`.

- [Poterya vvodnogo teksta pri obnovlenii navigacii](../../Sboi/FUM-SBOJ-0106-poterya-vvodnogo-teksta-pri-obnovlenii-navigacii.md) — tochnoye osnovaniye `FUM-СБОЙ-0106/ПРОЯВЛЕНИЕ-0001`; [pervichnyij arkhivnyij etap](../../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/zapros.md).

- [Proyavleniye FUM-SBOJ-0041/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0041-drejf-mashinnogo-zagolovka-otchyota.md).
- [Iskhodnyij zapros priyomki](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 05:52:00 MSK -->
<!-- content-sha256: sha256:840927c4daa12e014f1fbcbf3afab99a837daeff51e8f6d274c5ade635694d47 -->
<!-- FUM-MD-RECENCY:END -->
