+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0060"
"статус" = "устранена"
+++
# Povtornoye indeksirovaniye uzhe udalyonnyikh staryikh putej

## Nablyudayemyij sboj

Pri podgotovke indeksa etapa 07:44 perechenj iz diff otnositeljno HEAD soderzhal prezhniye imena kartochek 0202 i 0203, uzhe udalyonnyiye iz indeksa shtatnyim pereimenovaniyem. Peredacha vsekh takikh imyon v `git add -A` zavershilasj otkazom na pervom prezhnem puti 0202.

## Granica povtoreniya

V perechenj dlya povtornogo indeksirovaniya popadayet prezhnij putj, otsutstvuyusjhij i na diske, i sredi tekusjhikh otslezhivayemyikh putej indeksa, no uzhe predstavlennyij indeksirovannyim udaleniyem otnositeljno HEAD. Prezhniye imena byili dejstviteljnyimi, poetomu eto ne vyimyishlennyij putj 0009. Oblastj zaprosa i udaleniya proyekcii 0035 zdesj ne yavlyayutsya prichinoj.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0060/ПРОЯВЛЕНИЕ-0001` | [Otkaz staging](../Zhurnal/2026-09-11_07-44-52_MSK_prinyatj-matematiku-i-rabochij-kontekst/otchyot.md): staryiye imena 0202/0203 peredanyi odnim vyizovom; Git soobsjhil `pathspec` dlya 0202 i kod 128, obyortka — kod 1. | Podgotovlennyij vyizov ne zavershil indeksirovaniye; poterya soderzhateljnyikh fajlov ne ustanovlena. | Spisok razdelyon po dejstviteljnomu sostoyaniyu: susjhestvuyusjhiye puti, yesjhyo otslezhivayemyiye udaleniya i uzhe indeksirovannyiye udaleniya. Posledniye ne peredanyi povtorno, ikh effekt sokhranyon. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka podgotovki konkretnogo spiska indeksirovaniya. Spisok dolzhen vyirazhatj dejstviteljnyiye dopustimyiye celi i sokhranyatj uzhe podgotovlennyiye udaleniya. Otkaz Git korrekten; po nemu ne vyivoditsya defekt Git, pereimenovaniya ili kartochek.

## Mekhanizm i sistemnoye ustraneniye

Iskhodnyij spisok smeshival razlichiye s HEAD i tekusjhiye celi indeksa. Proveryayemoye ogranichennoye vosstanovleniye vyibirayet putj, yesli on susjhestvuyet libo yesjhyo otslezhivayetsya v indekse; ostaljnyiye podtverzhdyonnyiye uzhe indeksirovannyiye udaleniya sokhranyayutsya bez povtornoj peredachi. V dannom snimke isklyuchenyi rovno prezhniye 0202/0203. Obsjhaya avtomatizaciya vsekh budusjhikh komand staging ne vvodilasj.

## Svyazannyiye shagi

Otdeljnyij STEP ne trebuyetsya dlya vyipolnennogo ogranichennogo vosstanovleniya etogo spiska. Novoye trebovaniye universaljno predotvrasjhatj ruchnyiye oshibki zdesj ne formuliruyetsya; takaya boleye shirokaya mera ne obyyavlyayetsya zavershyonnoj.

## Kriterii zakryitiya

Vosstanovlennyij spisok dannogo snimka soderzhit 22 tekusjhikh puti i isklyuchayet rovno dva uzhe indeksirovannyikh udaleniya 0202/0203. Ikh effekt ostayotsya v indekse. Podgotovlennyij indeks prokhodit proverku probeljnyikh oshibok, rabocheye derevo ne soderzhit neindeksirovannyikh izmenenij, i sokhranyon yego tochnyij diff. Odnogo uspeshnogo `git add` dlya etogo kriteriya nedostatochno.

## Podtverzhdeniye ustraneniya

[Pervichnoye svideteljstvo](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md) sokhranyayet yavnuyu proverku rovno dvukh isklyuchenij, uspeshnoye indeksirovaniye 22 putej i rezuljtat `already_staged_deletions` s prezhnimi 0202/0203. Zatem uspeshnaya cepochka `git diff --cached --check` i `git diff --quiet` predshestvuyet vyichisleniyu SHA-256 indeksirovannogo diff `49cb1c225eb9dab4b96e00917aa2a3362b75434731b1f80adce07f9795b696e3`. [Otchyot etapa](../Zhurnal/2026-09-11_07-44-52_MSK_prinyatj-matematiku-i-rabochij-kontekst/otchyot.md) fiksiruyet sposob vosstanovleniya i otsutstviye poteri fajlov. Status otnositsya k etomu proverennomu vosstanovleniyu indeksa, a ne k otsutstviyu budusjhikh analogichnyikh oshibok.

## Istochniki

- [Tekusjhij zapros](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).
- [Adresnoye podtverzhdeniye i chastnyiye pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).
- [Dopustimyiye iskhodyi kartochki](../Pravila/agentov/planirovaniye-trebovaniya-voprosyi-i-sboi.md).
- [Otchyot indeksirovaniya i kontroljnoj tochki](../Zhurnal/2026-09-11_07-44-52_MSK_prinyatj-matematiku-i-rabochij-kontekst/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:0f5bd20aee3f647fdb2c2916699db543b04855942a908196ccd72667cf959295 -->
<!-- FUM-MD-RECENCY:END -->
