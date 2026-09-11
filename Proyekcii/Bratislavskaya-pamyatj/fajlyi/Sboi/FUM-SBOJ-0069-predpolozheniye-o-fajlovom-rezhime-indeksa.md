+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0069"
"статус" = "устранена"
+++
# Predpolozheniye 0644 vmesto nablyudyonnogo rezhima indeksov 0600

## Nablyudayemyij sboj

Chastnyij importyor devyati kartochek treboval lokaljnyij mode 0644 u dvukh indeksov pri fakticheskom 0600 i Git-mode 100644. Dopusk otkazal do pervoj zapisi.

## Granica povtoreniya

Dva indeksa dannogo importa ot ef55be2f; rezhim obyichnogo Git-obyyekta ne zadayot tochnyiye lokaljnyiye prava. Otkaz ne yavlyayetsya povrezhdeniyem repozitoriya.

## Proyavleniya

### FUM-SBOJ-0069/PROYAVLENIYE-0001

Korenj 0201: chunk ef62d9, kod 2, oshibka «Izmenilsya fajlovyij mode indeksa», polnostjyu ustanovlennyiye puti — pustoj spisok. Sleduyusjheye nablyudeniye 878dc7 podtverdilo 0600 u oboikh indeksov i otsutstviye devyati celevyikh kartochek.

## Ozhidaniye i klassifikaciya

Adresnyij import dolzhen prinimatj fakticheski soglasovannyij rezhim indeksov i sokhranyatj yego, proveryaya Git-mode otdeljno. Skript oshibochno zafiksiroval nenablyudyonnyiye prava.

## Mekhanizm i sistemnoye ustraneniye

Iskhodnaya versiya s SHA 4edaee1c6ec0a48dda2dc8546ee2b249564b05776d5a900e0fd9a37429e1e866 sokhranena. Otdeljnaya versiya cbad063e66dcf9942f11e2763fd92ec83354972c1a5e423698aa54c6735d3a6c trebuyet i sokhranyayet 0600 u indeksov; novyiye kartochki ostayutsya 0644. Ostaljnyiye dopuski sokhranenyi.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Novogo STEP net. Chastnaya versiya ispravlena dlya nablyudyonnoj paryi indeksov; universaljnaya politika prav ili obsjhij tranzakcionnyij importyor ne zayavlyayutsya.

## Kriterii zakryitiya

Ispravlennyij import ustanavlivayet rovno devyatj kartochek i devyatj strok indeksov, podtverzhdayet predusmotrennyiye khyeshi i sokhranyayet lokaljnyiye prava indeksov.

## Podtverzhdeniye ustraneniya

Process 71031 zavershyon v call_hsWrlR5zlwfGuQo2WdZ2jNWl: chunk f9c133, kod 0. Vse devyatj promezhutochnyikh SHA sovpali manifestu. Rezuljtat ogranichen importom do recency i peresborki reyestra; posleduyusjhaya priyomka DNK etim ne udostoveryayetsya.

## Istochniki

[Tekusjhaya registraciya i proiskhozhdeniye](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:69b7690c44124c39ecd0963148b7bb342ce134d28aa2f8e79d15f6cd117387f8 -->
<!-- FUM-MD-RECENCY:END -->
