+++
schema_version = 1
card_id = "FUM-STEP-0231"
status = "active"
+++
# Proveryatj ssyilki otnositeljno vklyuchyonnogo pokoleniya

## Zadacha

Podgotovitj minimaljnuyu rannyuyu read-only proverku dopustimosti aktivnyikh lokaljnyikh Markdown-ssyilok otnositeljno yavno zadannogo vklyuchyonnogo pokoleniya pered dorogoj proyekciyej. Ispoljzovatj susjhestvuyusjhij kontrakt razresheniya ssyilok; proverka susjhestvovaniya fajla otdeljno nedostatochna.

## Pochemu sejchas

`FUM-СБОЙ-0150/ПРОЯВЛЕНИЕ-0001` ostanovilo polnyij dopusk na shage5 posle podgotovki. Zamena ssyilki obyichnyim tekstom snyala toljko etot otkaz; sleduyusjhij otkaz0051 imeyet druguyu prichinu. Sejchas sokhranyon plan, realizaciya ne nachata.

## Kriterii zaversheniya

- Vkhod soderzhit tochnyiye iskhodniki, kontrakt i sostav pokoleniya; rezuljtat svyazan s ikh khyeshami i obnaruzhivayet drejf.
- Nedopustimaya aktivnaya celj obyyasnyayetsya iskhodnyim putyom, strokoj i otsutstviyem v pokolenii do dorogogo shaga; chteniye ne izmenyayet fajlyi.
- Adresnyiye scenarii razlichayut susjhestvuyusjhuyu vklyuchyonnuyu celj, susjhestvuyusjhuyu isklyuchyonnuyu celj, otsutstvuyusjhuyu celj i obyichnyij tekst bez aktivnoj ssyilki; povtor ispoljzuyet tot zhe neizmennyij vkhod.
- Izmeren polnyij raskhod rannej proverki i yeyo granicyi; ekonomiya na boljshikh istochnikakh ne vyivoditsya iz maloj fiksturyi.
- Pokazano sistemnoye predotvrasjheniye proyavleniya0001 bez oslableniya dejstvuyusjhej proverki proyekcii. Plan i odin uspeshnyij zapusk ne zakryivayut kartochku sboya.

## Istochniki

- [FUM-SBOJ-0150/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0150-aktivnaya-ssyilka-vne-vklyuchyonnogo-pokoleniya.md).
- [Prinyatoye diagnosticheskoye porucheniye](../../Zhurnal/2026-09-16_17-24-57_MSK_zaregistrirovatj-otkazyi-finansovoj-priyomki/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 17:48:33 MSK -->
<!-- content-sha256: sha256:bc083a88c44747687af86c646ef08cb8830b049ee66b4c9dd2de43c64fab9ae3 -->
<!-- FUM-MD-RECENCY:END -->
