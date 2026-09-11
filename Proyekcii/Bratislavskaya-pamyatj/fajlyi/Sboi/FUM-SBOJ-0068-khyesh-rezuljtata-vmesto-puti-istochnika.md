+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0068"
"статус" = "устранена"
+++
# Peredacha khyesha istochnika v parametr fajlovogo puti

## Nablyudayemyij sboj

Korenj 0201 peredal `Path(old['источник'])` iz rezuljtata chitatelya; eto pole soderzhalo SHA, a API ozhidal putj. Voznikli FileNotFoundError, OshibkaSoobsjhenij i OshibkaObrabotki.

## Granica povtoreniya

Oshibka vyibora polya mezhdu rezuljtatom chitatelya i vkhodom priyoma pered etapom DNK. Eto ne otsutstviye nastoyasjhego JSONL, ne oshibka poiska imeni i ne defekt 0177.

## Proyavleniya

### FUM-SBOJ-0068/PROYAVLENIYE-0001

Korenj 0201: call_reymVAAPxMW6d08vyhO3C8cP, chunk b74891, kod 1. Vyizov zavershilsya do posleduyusjhikh zapisej togo scenariya. Ispravlennyij call_spdW6SiS1b1esiIaRVhaKLbm ispoljzoval inp[istochnik] i inp[iskhodnaya_zadacha].

## Ozhidaniye i klassifikaciya

Putj i identifikator zadachi dolzhnyi postupatj iz vkhodnogo kontrakta; odnoimyonnoye pole rezuljtata neljzya traktovatj kak tot zhe tip bez sverki.

## Mekhanizm i sistemnoye ustraneniye

Vzyatyi fakticheskiye putj i UUID iz uzhe prochitannogo vkhoda. Poluchennyij ostatok sopostavlen s prezhnimi ekzemplyarami i istoriyej; daljnejshaya zapisj chastnogo rezuljtata i sozdaniye etapa vyipolnyalisj toljko posle uspeshnogo chteniya.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Novogo STEP i izmeneniya reader ne trebuyetsya: ispravlen konkretnyij vyizyivayusjhij scenarij.

## Kriterii zakryitiya

Ispravlennyij scenarij poluchayet prezhniye 179 ekzemplyarov, polnyij istochnik bez khvosta i zakanchivayetsya uspeshno; pervonachaljnyij otkaz sokhranyayetsya.

## Podtverzhdeniye ustraneniya

call_KeV0nJARjHcVuZPyObjjXbbN zavershil process 15201: chunk 12acd8, kod 0. Podtverzhdenyi prefiks 321971729 bajt, SHA 6f8fcd52404e495d65f09c92342c60f2171b3e37470b8b7e1c3179abb114fb49 i etap 08:49:30. Obsjhaya zasjhita ot smesheniya polej ne zayavlyayetsya.

## Istochniki

[Tekusjhaya registraciya i proiskhozhdeniye](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:2cb20f0bdce798299040f169a24f6d32e9b1c2b96723911614a7cea70520984a -->
<!-- FUM-MD-RECENCY:END -->
