+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0136"
"статус" = "устранена"
+++
# Propusjhennyij obyazateljnyij argument proverki manifesta

## Nablyudayemyij sboj

Posle zakryitiya priyomochnogo otchyota vyizov `проверить-манифест` ne soderzhal obyazateljnogo argumenta `--манифест`. Parser vernul kod 2 do nezavisimoj proverki. Kanon, zakryityij otchyot i pokoleniye ne menyalisj.

## Granica povtoreniya

Sostav argumentov konkretnogo vyizova nezavisimoj proverki proyekcii. Nepodderzhannyij flag predprosmotra 0135 i parametryi publikacionnogo skanera 0065 imeyut drugiye chastnyiye granicyi; obsjhaya profilaktika podgotovki CLI etim vosstanovleniyem ne dokazana.

## Proyavleniya

### FUM-SBOJ-0136/PROYAVLENIYE-0001

[Svideteljstvo](../Zhurnal/2026-09-15_05-48-06_MSK_svyazatj-priyomku-konteksta-s-obyazateljstvom/materialyi/vosstanovleniye-argumenta-manifesta.json) sokhranyayet otkaz parsera, propusjhennyij argument, tochnyij ispravlennyij putj i uspeshnuyu nezavisimuyu proverku.

## Ozhidaniye i klassifikaciya

Dokumentirovannyij vyizov soderzhit vse obyazateljnyiye parametryi. Eto oshibka vyizyivayusjhego; defekt proveryayusjhego instrumenta ne nablyudalsya.

## Mekhanizm i sistemnoye ustraneniye

Ogranichennoye vosstanovleniye zamenyayet nepolnyij vyizov dokumentirovannyim vyizovom s tochnyim manifestom sozdannogo pokoleniya. Zasjhitnyij otkaz parsera sokhranyon. Novyij obsjhij generator komand i obsjhaya garantiya praviljnogo vosstanovleniya sintaksisa ne realizovanyi.

## Svyazannyiye shagi

Vosstanovleniye vyipolneno v prinyatom snimke; tekusjhij [etap svyazi](../Zhurnal/2026-09-15_05-48-06_MSK_svyazatj-priyomku-konteksta-s-obyazateljstvom/zapros.md) sokhranyayet yego proiskhozhdeniye, ne vozobnovlyaya zakryityij otchyot. Otdeljnogo nezavershyonnogo shaga dlya ogranichennogo vosstanovleniya net.

## Kriterii zakryitiya

Nepolnyij vyizov otklonyon do proverki; komanda s dokumentirovannyim obyazateljnyim putyom uspeshno proveryayet rovno sozdannyij manifest. Sokhranenyi oba iskhoda i otsutstviye izmenenij kanonicheskogo sostava mezhdu nimi.

## Podtverzhdeniye ustraneniya

[Otkaz i ispravleniye](../Zhurnal/2026-09-15_05-48-06_MSK_svyazatj-priyomku-konteksta-s-obyazateljstvom/materialyi/vosstanovleniye-argumenta-manifesta.json) fiksiruyut kodyi 2 i 0. Nezavisimaya proverka predshestvovala linejnomu kommitu `d461aefa874d56aa2160e70b72bbad700ca73030`; [chitatelj Git](../Zhurnal/2026-09-15_05-48-06_MSK_svyazatj-priyomku-konteksta-s-obyazateljstvom/materialyi/priyomka-iz-Git.json) podtverzhdayet priyomochnyij otchyot. Zakryitiye ogranicheno vosstanovlennyim vyizovom.

## Istochniki

- [Zapros](../Zhurnal/2026-09-15_05-48-06_MSK_svyazatj-priyomku-konteksta-s-obyazateljstvom/zapros.md) i [otchyot](../Zhurnal/2026-09-15_05-48-06_MSK_svyazatj-priyomku-konteksta-s-obyazateljstvom/otchyot.md).
- [Dokumentirovannyij interfejs](../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 05:54:54 MSK -->
<!-- content-sha256: sha256:b361209ec274e62ad8392bfaa49452752f85d17cf7641fec5030826b23b76a63 -->
<!-- FUM-MD-RECENCY:END -->
