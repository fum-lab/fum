+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0140"
"статус" = "активна"
+++
# Privatnyiye ukazateli v soobsjhenii kommita

## Nablyudayemyij sboj

V opublikovannoye soobsjheniye dochernego kommita `70cec1ca7852d64c003baa22ef79bc4a395336c7` popali dva privatnyikh absolyutnyikh puti iz koordinacionnoj peredachi. Ispolnitelj podtverdil narusheniye. Znacheniya putej zdesj ne vosproizvodyatsya; publikaciya soderzhimogo fajlov etim nablyudeniyem ne dokazana.

## Granica povtoreniya

Eta kartochka okhvatyivayet perenos lokaljnyikh ukazatelej koordinacii v publichnoye soobsjheniye Git pri podgotovke konteksta i kommita. Publikaciya iskhodnikov ili sekretov vnutri drugikh artefaktov ne obyyavlyayetsya tem zhe proyavleniyem bez otdeljnogo dokazateljstva.

## Proyavleniya

1. `FUM-СБОЙ-0140/ПРОЯВЛЕНИЕ-0001`: opublikovannyij kommit `70cec1ca7852d64c003baa22ef79bc4a395336c7`, proverka kornya i podtverzhdeniye ispolnitelya. [Zapisj nablyudeniya](../Zhurnal/2026-09-15_15-13-26_MSK_zakrepitj-reakciyu-na-pereraskhod-konteksta/otchyot.md). Znacheniya isklyuchenyi iz posleduyusjhikh publichnyikh zapisej; opublikovannaya istoriya ne perepisyivalasj.

## Ozhidaniye i klassifikaciya

Publikacionnaya chistota rasprostranyayetsya na soobsjheniye kommita i pervichnyiye istochniki koordinacii. Doslovnoye sokhraneniye komandyi cheloveka ne trebuyet publikacii privatnogo transportnogo soobsjheniya agenta. Nablyudeniye klassificirovano kak nedorabotka podgotovki publikacii.

## Mekhanizm i sistemnoye ustraneniye

Nablyudayemaya prichina — v publichnyij tekst popal peredannyij sluzhebnyij kontekst s lokaljnyimi ukazatelyami. Gipoteza boleye obsjhego mekhanizma: nerazlicheniye iskhodnogo soobsjheniya cheloveka i transportnogo konverta porucheniya. Do sistemnoj proverki yavno otbirayutsya iskhodnyiye komandyi i proveryayetsya vesj tekst Git-soobsjheniya. Publikaciya ispravlennogo sleduyusjhego kommita ne udalyayet prezhnyuyu zapisj.

## Svyazannyiye shagi

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — aktualizirovan proyavleniyem 0001: sokhranyatj proiskhozhdeniye i razdelyatj privatnoye raskryitiye konteksta i publichnuyu proizvodnuyu zapisj.

## Kriterii zakryitiya

- Proverka polnogo soobsjheniya Git otlichayet dopustimyij pervichnyij tekst ot privatnogo transportnogo ukazatelya i otklonyayet nablyudyonnyij sluchaj do publikacii.
- Sokhranyonnyij privatnyij istochnik ostayotsya dostupen dlya vosstanovleniya; yego otsutstviye ne skryivayetsya.
- Staroye opublikovannoye ogranicheniye razresheno otdeljnyim resheniyem libo yavno sokhraneno kak nezavershyonnoye; uspeshnyij posleduyusjhij commit sam po sebe kartochku ne zakryivayet.

## Istochniki

- [Pervichnoye nablyudeniye kornya](../Zhurnal/2026-09-15_15-13-26_MSK_zakrepitj-reakciyu-na-pereraskhod-konteksta/otchyot.md).
- [Tekusjhij etap sokhraneniya](../Zhurnal/2026-09-15_16-17-32_MSK_sokhranitj-sboi-peredachi-konteksta/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 16:30:50 MSK -->
<!-- content-sha256: sha256:faa5cbe44ff4ea859737548f92d71c1da481812f25a3b6b68f35180d9a74658b -->
<!-- FUM-MD-RECENCY:END -->
