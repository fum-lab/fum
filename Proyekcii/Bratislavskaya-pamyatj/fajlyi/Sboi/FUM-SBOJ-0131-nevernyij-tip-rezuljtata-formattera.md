+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0131"
"статус" = "активна"
+++
# Nevernyij tip rezuljtata formattera v chastnom vyizove

## Nablyudayemyij sboj

Chastnyij vyizov oformleniya otchyota primenil `rstrip()` neposredstvenno k rezuljtatu `render_aligned_markdown_table`, khotya shtatnyij formatter vozvrasjhayet spisok strok. Voznik AttributeError do pervoj zapisi otchyota i zaprosa. Biblioteka vyipolnila svoj kontrakt; defekt nakhodilsya v vyizyivayusjhem kode podgotovki.

## Granica povtoreniya

Nevernoye predpolozheniye o forme vozvrasjhayemogo znacheniya susjhestvuyusjhego API. Eto otdeljno ot 0128: modulj v dannom vyizove korrektno zaregistrirovan v sys.modules i import zavershilsya.

## Proyavleniya

### FUM-SBOJ-0131/PROYAVLENIYE-0001

[Nablyudeniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-tipa-rezuljtata-formattera.json) svyazyivayet iskhodnyij vyizov, otvet s otkazom, bajtovyiye granicyi i SHA kornevogo JSONL. Polnyij chastnyij zhurnal ostayotsya vne checkout. Dliteljnostj operacii ne naznachayetsya zadnim chislom; eto podgotovka dokumentov, ne testovyij process.

## Ozhidaniye i klassifikaciya

Vyizov ispoljzuyet fakticheskij vozvrasjhayemyij tip shtatnogo API. Nomer vyidelen raspredelitelem po sobyitiyu `context-table-render-return-type-01a0930d-call79dG87Rq`.

## Mekhanizm i sistemnoye ustraneniye

Spisok strok obyyedinyon LF, zatem primenyon `rstrip()`. Ispravlennyij vyizov zapisal otchyot i zapros; shtatnyij formatter pobajtno raven HEAD, chto podtverzhdeno v nablyudenii. Eto ogranichennoye vosstanovleniye tekusjhej operacii. Proveryayemyij primer formyi rezuljtata pered povtornyim primeneniyem chastnogo oformleniya yesjhyo ne zakreplyon obsjhej meroj.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — osnovaniye FUM-SBOJ-0131/PROYAVLENIYE-0001.

## Kriterii zakryitiya

Dlya povtornogo ispoljzovaniya formattera dostupen proverennyij primer, yavno pokazyivayusjhij spisok strok i polucheniye teksta cherez LF. Nevernoye obrasjheniye so spiskom vyiyavlyayetsya do zapisi kanonicheskikh dokumentov; formatter sokhranyayet sobstvennyij kontrakt.

## Istochniki

- [Komanda i raspredeleniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).
- [Otchyot](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:54:57 MSK -->
<!-- content-sha256: sha256:a27139e163d7722c72d051e1a7efb1df231a619f22de5bed3ae8b2261d2d50f3 -->
<!-- FUM-MD-RECENCY:END -->
