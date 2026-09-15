+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0135"
"статус" = "устранена"
+++
# Nepodderzhannyij flag peredan komande predprosmotra

## Nablyudayemyij sboj

Komanda predprosmotra poluchila nesusjhestvuyusjhij flag `--записать`. Shtatnyij parser vernul kod2 do dejstviya.

## Granica povtoreniya

Forma vyizova konkretnoj komandyi predprosmotra.0065 otnositsya k parametram publikacionnogo skanera,0132 — k smyislu podderzhannogo parametra drugogo instrumenta; obsjhaya profilaktika etikh granic ne dokazana.

## Proyavleniya

### FUM-SBOJ-0135/PROYAVLENIYE-0001

[Pervichnyiye argumentyi i iskhodyi](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/materialyi/vosstanovleniye-flaga-predprosmotra.json) sokhranyayut kod2 i uspeshnyij povtor bez lishnego flaga.

## Ozhidaniye i klassifikaciya

Vyizov ispoljzuyet dokumentirovannyiye parametryi vyibrannoj komandyi. Eto oshibka vyizyivayusjhego; defekt shtatnogo instrumenta ne nablyudalsya.

## Mekhanizm i sistemnoye ustraneniye

Ubran toljko nepodderzhannyij flag, sokhranyon shtatnyij vyizov. Obsjhij generator komand i novyiye testyi etim ogranichennyim vosstanovleniyem ne realizovanyi.

## Svyazannyiye shagi

Ogranichennoye vosstanovleniye vyipolneno v [tekusjhem etape](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/zapros.md); otdeljnogo nezavershyonnogo shaga dlya nego net.

## Kriterii zakryitiya

Sokhranitj pervonachaljnyij otkaz do dejstviya i uspeshno vyipolnitj tu zhe shtatnuyu komandu bez nepodderzhannogo argumenta.

## Podtverzhdeniye ustraneniya

[Svideteljstvo](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/materialyi/vosstanovleniye-flaga-predprosmotra.json) fiksiruyet uspeshnyij povtor s kodom0. Zakryivayetsya toljko vosstanovleniye tekusjhego vyizova, a ne obsjhaya garantiya bezoshibochnoj podgotovki CLI.

## Istochniki

- [Zapros](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/zapros.md).
- [Otchyot](../Zhurnal/2026-09-15_03-35-30_MSK_podgotovitj-obyyedineniye-konteksta-i-finansirovaniya/otchyot.md).
- [Shtatnaya avtomatizaciya](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 04:26:02 MSK -->
<!-- content-sha256: sha256:b529d108cc2c40f001c5980a1e9db1442c329e87886f7602020adacf4abab1a1 -->
<!-- FUM-MD-RECENCY:END -->
