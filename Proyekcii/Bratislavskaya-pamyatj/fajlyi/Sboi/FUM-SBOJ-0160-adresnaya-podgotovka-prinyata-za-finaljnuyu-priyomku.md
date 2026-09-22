+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0160"
"статус" = "активна"
+++
# Adresnaya podgotovka prinyata za finaljnuyu priyomku

## Nablyudayemyij sboj

Istoricheskij etap C4 soderzhal toljko uspeshnyiye adresnyiye zapuski, no zapisj `приёмки_этапов` traktovala yego kak finaljnuyu priyomku. Posle sleduyusjhego kommita strogij chitatelj ozhidal polnyij zakryityij otchyot i ostanavlival prodolzheniye zadachi.

## Granica povtoreniya

Reyestr soderzhit priyomku s finaljnyim UUID, chji sokhranyonnyiye zapuski imeyut klass `адресная`, bez zakryitogo polnogo smoke-check, svyazannogo s tem zhe kommitom.

## Proyavleniya

### FUM-SBOJ-0160/PROYAVLENIYE-0001

[Otchyot tekusjhego etapa](../Zhurnal/2026-09-22_02-25-51_MSK_zafiksirovatj-postkommitnuyu-ostanovku-i-ispravitj-priyomku/otchyot.md) sokhranyayet iskhodnyij vopros, tochnyiye khyeshi C3/C4, nablyudayemuyu ostanovku i granicu vosstanovleniya.

## Ozhidaniye i klassifikaciya

Promezhutochnyij adresnyij chekpojnt dolzhen sokhranyatjsya, no ne vyidavatj sebya za podtverzhdyonnyij finaljnyij rezuljtat. Polnaya priyomka obyazana imetj zakryityij polnyij otchyot i tochnuyu svyazj s kommitom.

## Mekhanizm i sistemnoye ustraneniye

Ispolnitelj `обязательства_задачи.py` raspoznayot nabor uspeshnyikh adresnyikh zapuskov kak `адресная-подготовка`, vozvrasjhayet yego kak neaktualjnyij rezuljtat i ostavlyayet sleduyusjhuyu rabotu dostupnoj. Istoricheskiye otchyotyi i zapisj proiskhozhdeniya ne perepisyivayutsya.

## Svyazannyiye shagi

[FUM-STEP-0172](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0172-proveryatj-ostatok-obyazateljstv-zadachi.md).

## Kriterii zakryitiya

Polnyij smoke-check tekusjhego ispravleniya dolzhen projti i zakryitjsya s tochnyim snimkom; chteniye reyestra dolzhno stabiljno klassificirovatj C4 kak promezhutochnuyu podgotovku, a regressionnyij test dolzhen sokhranyatj etot iskhod. Do etogo kartochka ostayotsya aktivnoj.

## Istochniki

- [Zapros i otchyot](../Zhurnal/2026-09-22_02-25-51_MSK_zafiksirovatj-postkommitnuyu-ostanovku-i-ispravitj-priyomku/zapros.md).
- [Istoricheskaya adresnaya priyomka](../Zhurnal/2026-09-22_00-43-17_MSK_podgotovitj-zakryituyu-priyomku-plana/otchyot.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-22 02:44:42 MSK -->
<!-- content-sha256: sha256:80e660a262b46a600a2c95fe930c3095835a444ba412ae82b6e1f7f77bc3dde3 -->
<!-- FUM-MD-RECENCY:END -->
