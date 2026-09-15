+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0132"
"статус" = "устранена"
+++
# Vremennaya metka peredana vmesto slovesnoj metki etapa

## Nablyudayemyij sboj

Pri sozdanii etapa v argument `--label` instrumenta strukturyi papok peredana vremennaya metka MSK. Instrument ozhidayet slovesnuyu metku iz imeni papki i otklonil vyizov do zapisi.

## Granica povtoreniya

Oshibka primeneniya polya sozdaniya etapa: odnoimyonnoye pole rezuljtata generatora vremeni imeyet drugoj smyisl. Shtatnyiye generator vremeni i validator strukturyi ispravnyi. Kartochka0065 ogranichena argumentami publikacionnogo skanera i ne obyyedinyayetsya s etim proyavleniyem.

## Proyavleniya

### FUM-SBOJ-0132/PROYAVLENIYE-0001

Vyizov dlya etapa2026-09-15_01-49-18_MSK zavershilsya kodom1 s soobsjheniyem `start session stem label does not match --label`. [Nablyudeniye](../Zhurnal/2026-09-15_01-49-18_MSK_sokhranitj-granicyi-priyomki-i-prodolzheniya-konteksta/materialyi/nablyudeniya-podgotovki.json) sokhranyayet nevernyij smyisl polya i tochnoye ispravleniye. Proverka soglasovannosti vyipolnyayetsya v nachale `start_session`, do podgotovki fajlov.

## Ozhidaniye i klassifikaciya

Papka sozdayotsya shtatnoj avtomatizaciyej s soglasovannyimi prefix, slovesnoj metkoj i kanonicheskim zagolovkom. Eto oshibka vyizyivayusjhego; povedeniye API ne obyyavlyayetsya defektnyim. Nomer vyidelen po sobyitiyu `root-start-label-time-instead-of-slug-01a07d3d-014918`.

## Mekhanizm i sistemnoye ustraneniye

Dlya ogranichennogo vosstanovleniya `--label` vzyat iz slovesnogo okonchaniya togo zhe stem; vremennoj prefix sokhranyon. Obyortka i shtatnyij validator ne izmenyalisj. Novyij universaljnyij konstruktor komand etim ne realizovan.

## Svyazannyiye shagi

Ogranichennoye vosstanovleniye zaversheno v [tekusjhem etape](../Zhurnal/2026-09-15_01-49-18_MSK_sokhranitj-granicyi-priyomki-i-prodolzheniya-konteksta/zapros.md); otdeljnyij nezavershyonnyij shag po nemu ne trebuyetsya. Gotovnostj avtomaticheskoj kompozicii vsekh podobnyikh interfejsov ne zayavlyayetsya.

## Kriterii zakryitiya

Povtor s soglasovannyim slovesnyim label i tem zhe vremennyim prefix uspeshno sozdayot rovno zadannuyu papku bez zamenyi susjhestvuyusjhikh dokumentov. Shtatnyij kod sokhranyayetsya. Kriterij otnositsya k etomu vosstanovleniyu, ne k otsutstviyu budusjhikh oshibok primeneniya.

## Podtverzhdeniye ustraneniya

Povtor vernul kod0, `mode=start`, `idempotent=false` i tochnoye imya tekusjhego etapa. Pervyij otkaz predshestvoval sozdaniyu. [Zapros](../Zhurnal/2026-09-15_01-49-18_MSK_sokhranitj-granicyi-priyomki-i-prodolzheniya-konteksta/zapros.md) i [otchyot](../Zhurnal/2026-09-15_01-49-18_MSK_sokhranitj-granicyi-priyomki-i-prodolzheniya-konteksta/otchyot.md) susjhestvuyut; daljnejshaya proverka ikh soderzhimogo ostayotsya samostoyateljnyim dopuskom.

## Istochniki

- [Komandyi, resheniye i granica rabotyi](../Zhurnal/2026-09-15_01-49-18_MSK_sokhranitj-granicyi-priyomki-i-prodolzheniya-konteksta/zapros.md).
- [Otchyot etapa](../Zhurnal/2026-09-15_01-49-18_MSK_sokhranitj-granicyi-priyomki-i-prodolzheniya-konteksta/otchyot.md).
- [Shtatnyij instrument strukturyi](../Instrumentyi/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 02:00:48 MSK -->
<!-- content-sha256: sha256:31f7a42290fcca9988439e226a675d0fa00f421e5c55039953b5b3a0b6ba6fba -->
<!-- FUM-MD-RECENCY:END -->
