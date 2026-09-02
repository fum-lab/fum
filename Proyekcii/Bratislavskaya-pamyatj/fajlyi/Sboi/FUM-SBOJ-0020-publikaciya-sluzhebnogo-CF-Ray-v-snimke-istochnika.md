+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0020"
"статус" = "устранена"
+++
# Publikaciya sluzhebnogo `CF-Ray` v snimke istochnika

Obsjhij HTML-arkhivator udalyal znacheniya `Set-Cookie`, no sokhranyal sluzhebnyij identifikator otveta `CF-Ray`. Importiruyemyij snimok russkogo perevoda CC0 poetomu soderzhal trace-id konkretnogo HTTP-otveta vmeste s PoP-kodom, khotya eti dannyiye ne yavlyayutsya soderzhaniyem istochnika.

## Nablyudayemyij sboj

Vo vremya semanticheskogo sliyaniya licenzionnoj vetki read-only-audit obnaruzhil v `response.headers.txt` neotredaktirovannoye znacheniye `CF-Ray`. Otchyot ob izvlechenii pri etom zayavlyal toljko redakciyu cookie i ne fiksiroval publikacionnuyu ochistku sluzhebnogo identifikatora.

## Granica povtoreniya

Proyavleniye voznikayet pri arkhivirovanii ustojchivogo HTML-URL, yesli HTTP-otvet soderzhit zagolovok `CF-Ray` v lyubom registre. Syuda ne otnosyatsya soderzhateljnyiye i vosproizvodimyiye metadannyiye otveta, takiye kak `Content-Type`, `Content-Language` ili `Last-Modified`.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                     | Effekt                                                                  | Vosstanovleniye                                                               |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `FUM-СБОЙ-0020/ПРОЯВЛЕНИЕ-0001` | [Importirovannyij snimok russkogo perevoda CC0](../Istochniki/URL/https/wiki.creativecommons.org/wiki/Publicdomain/zero/1.0/LegalText_-Russian-35eacbaf5d6489ab/response.headers.txt) do redakcii soderzhal sluzhebnoye znacheniye `CF-Ray`. | V publikacionnuyu pamyatj popadal trace-id otdeljnogo setevogo obrasjheniya. | Redaktirovatj zagolovok obsjhim arkhivatorom i ochistitj importiruyemyij snimok. |

## Ozhidaniye i klassifikaciya

Navyik materialov zaprosov trebuyet udalyatj sluzhebnyiye request-id i drugiye znacheniya, ne yavlyayusjhiyesya soderzhaniyem materiala. Sokhraneniye `CF-Ray` raskhodilosj s etoj publikacionnoj granicej i yavlyayetsya nedorabotkoj obsjhego arkhivatora.

## Mekhanizm i sistemnoye ustraneniye

Funkciya ochistki zagolovkov raspoznavala toljko `Set-Cookie`. Teperj ona takzhe raspoznayot `CF-Ray` bez uchyota registra i zamenyayet yego znacheniye stabiljnoj publikacionno chistoj pometkoj. Generiruyemyij otchyot ob izvlechenii yavno fiksiruyet etu redakciyu, a importirovannyij snimok privedyon k tomu zhe kontraktu.

## Svyazannyiye shagi

Otdeljnaya kartochka shaga ne sozdavalasj: pervoye proyavleniye, sistemnaya mera i regressionnoye dokazateljstvo zavershenyi v tekusjhej rabochej sessii.

## Kriterii zakryitiya

- Znacheniye `CF-Ray` ne sokhranyayetsya v snimke nezavisimo ot registra imeni zagolovka.
- Na yego meste ostayotsya stabiljnaya pometka `[REDACTED: response trace identifier]`.
- Redakciya otrazhayetsya v otchyote ob izvlechenii.
- Redaktirovaniye `Set-Cookie` i sokhraneniye soderzhateljnyikh zagolovkov ne oslablenyi.

## Podtverzhdeniye ustraneniya

Novyij adresnyij test snachala vosproizvyol utechku: nabor iz 13 testov zavershilsya s odnim ozhidayemyim otkazom. Posle uzkoj pravki tot zhe nabor proshyol vse 13 testov; standartnyij smoke-check tekusjhej sessii povtorno podtverzhdayet polnyij nabor avtomatizacii materialov zaprosov.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-26_11-16-52_MSK_perevesti-licenzionnuyu-pamyatku-na-anglijskij-yazyik/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-26_11-16-52_MSK_perevesti-licenzionnuyu-pamyatku-na-anglijskij-yazyik/otchyot.md)
- [otchyot ob izvlechenii istochnika](../Istochniki/URL/https/wiki.creativecommons.org/wiki/Publicdomain/zero/1.0/LegalText_-Russian-35eacbaf5d6489ab/extraction-report.md)
- [realizaciya obsjhego arkhivatora](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py)
- [regressionnyiye testyi obsjhego arkhivatora](../Instrumentyi/fum-materialyi-zaprosov/tests/test_source_archive_cli.py)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 11:32:07 MSK -->
<!-- content-sha256: sha256:e9477fcb8496628ed05a674436b0a7920b4cd6cabbb2ae25d99d99778e3a964d -->
<!-- FUM-MD-RECENCY:END -->
