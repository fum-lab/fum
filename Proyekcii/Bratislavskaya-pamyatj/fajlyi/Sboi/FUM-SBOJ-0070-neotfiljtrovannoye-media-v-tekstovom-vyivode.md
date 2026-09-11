+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0070"
"статус" = "устранена"
+++
# Vyivod soderzhimogo media bez otbora tekstovyikh chastej

## Nablyudayemyij sboj

V read-only-razbore vyivodilsya polnyij obyyekt soobsjheniya ili massiv soderzhimogo bez otbora tekstovyikh chastej, poetomu v tekstovyij otvet instrumenta popalo zakodirovannoye izobrazheniye i vyivod byil obrezan.

## Granica povtoreniya

Filjtr diagnosticheskogo vyivoda vyizyivayusjhego scenariya. Eto ne izmeneniye iskhodnogo poljzovateljskogo materiala, ne defekt klassifikacii 0177 i ne mekhanizm ugadyivaniya putej 0009. Limit max_output_tokens ne zamenyayet filjtraciyu do serializacii.

## Proyavleniya

### FUM-SBOJ-0070/PROYAVLENIYE-0001

Korenj 0201: `print(json.dumps(d['сообщения'][-1]))` privyol k chunk 7f98e6 s original_token_count 712072. Posleduyusjhij scenarij DNK vyibiral konkretnyiye polya i toljko soderzhimoye s type=input_text.

### FUM-SBOJ-0070/PROYAVLENIYE-0002

Koordinator FUMA: chunk 0b6a07 soderzhal original_token_count 359692. Ispravlennyij filjtr v call_jnYEHXx65xlnNQJjEmSr1lD4 dal chunk e8c9b8, 648 tokenov, chetyire poslednikh chelovecheskikh teksta.

## Ozhidaniye i klassifikaciya

Dlya vosstanovleniya tekstovogo konteksta vyivodyatsya toljko nuzhnyiye metadannyiye i tekstovyiye chasti. Syiroj massiv s media ne dolzhen popadatj v diagnosticheskuyu tekstovuyu vyidachu.

## Mekhanizm i sistemnoye ustraneniye

Primenyon polozhiteljnyij perechenj polej i otbor content.type=input_text do json.dumps. Iskhodnyij JSONL i vlozheniya sokhranenyi; kod 0177 ne menyalsya. Syiryiye media v kartochku i yeyo svideteljstva ne kopiruyutsya.

Obsjhaya avtomaticheskaya profilaktika povtoreniya ne zayavlyayetsya.

## Svyazannyiye shagi

Tochnoye osnovaniye aktualizacii susjhestvuyusjhego [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — `FUM-СБОЙ-0070/ПРОЯВЛЕНИЕ-0002`; zerkaljnaya zapisj sokhranena v istochnikakh shaga. Eto utochneniye proiskhozhdeniya proverennogo ogranichennogo vosstanovleniya.

Atributirovannyij material dlya susjhestvuyusjhego [rabochego konteksta FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md); novogo porucheniya, realizacii ili novogo STEP ne sozdayot. Napravleniye diagnostiki 0009 ne poglosjhayet etot inoj mekhanizm.

## Kriterii zakryitiya

Kazhdoye iz dvukh proyavlenij imeyet adresnyij ispravlennyij vyizov, kotoryij vyibirayet tekstovyiye chasti i sokhranyayet nuzhnyiye soobsjheniya bez serializacii media.

## Podtverzhdeniye ustraneniya

U kornya 0201 call_spdW6SiS1b1esiIaRVhaKLbm yavno filjtruyet type=input_text; itog 12acd8 uspeshen. U koordinatora ispravlennyij e8c9b8 imeyet kod 0 obolochki i 648 tokenov; vlozhennyij ostatok imeyet shtatnyij kod 3, kotoryij ne vyidan za zaversheniye FUMA. Eto dva ogranichennyikh vosstanovleniya, ne sozdannaya sistemnaya avtomatizaciya.

## Istochniki

[Tekusjhaya registraciya i proiskhozhdeniye](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:5a9eb7ca9e0dfd5cfe80513f031549732098bf3c62f3656c5fc783bb94ca639c -->
<!-- FUM-MD-RECENCY:END -->
