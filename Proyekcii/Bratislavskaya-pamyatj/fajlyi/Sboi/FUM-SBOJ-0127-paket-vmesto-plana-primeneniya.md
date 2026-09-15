+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0127"
"статус" = "активна"
+++
# Iskhodnyij paket peredan vmesto plana primeneniya

## Nablyudayemyij sboj

Pri registracii 0126 korenj peredal komande primeneniya iskhodnyij paket diagnostiki vmesto uzhe podgotovlennogo i prochitannogo konverta plana. Instrument praviljno otkazal do zapisi.

## Granica povtoreniya

Pereputanyi dva posledovateljnyikh artefakta odnogo interfejsa: vkhod podgotovki i rezuljtat podgotovki, trebuyemyij primeneniyem. Skhema, parser i runtime ne narushenyi; oshibka prinadlezhit vyizovu kornya posle vosstanovleniya konteksta.

## Proyavleniya

### FUM-SBOJ-0127/PROYAVLENIYE-0001

[Iskhodnoye nablyudeniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-nevernogo-vkhoda-primeneniya.json) sokhranyayet bajtovyiye granicyi i SHA pervichnogo otveta, kod 1 i soobsjheniye «Neizvestnyiye libo otsutstvuyusjhiye polya zapisi». Peredan paket 0126; zapisj checkout ne nachalasj. Dliteljnostj processa ne izmerena i zadnim chislom ne naznachayetsya.

## Ozhidaniye i klassifikaciya

[Rukovodstvo paketa](../Instrumentyi/fum-reyestr-planirovaniya/paket-diagnostiki.md) yavno trebuyet peredatj komande `применить` sokhranyonnyij plan. Nomer vyidelen obsjhim raspredelitelem po sobyitiyu `context-diagnostic-package-instead-of-plan-01a0930d-0126`. Eto otdeljnaya oshibka vyibora vkhoda, ne proyavleniye 0126.

## Mekhanizm i sistemnoye ustraneniye

Posle chteniya tochnogo kontrakta peredan neizmenyonnyij sokhranyonnyij plan. Praviljnyij vyizov zavershilsya uspeshno, kazhdyij vyikhod prochitan i sovpal s planom. Obsjhaya mera podgotovki vyizova, isklyuchayusjhaya poteryu razlichiya artefaktov posle vosstanovleniya konteksta, yesjhyo ne realizovana. Runtime menyatj po etomu nablyudeniyu ne trebuyetsya.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — korrektnyij vyibor vkhodnogo konverta; tochnoye osnovaniye FUM-SBOJ-0127/PROYAVLENIYE-0001.

## Kriterii zakryitiya

Povtoryayemaya podgotovka komandyi primeneniya svyazyivayet yeyo s proverennyim konvertom plana, vklyuchaya prodolzheniye posle szhatiya konteksta. Iskhodnyij paket ostayotsya zapresjhyonnyim vkhodom primeneniya, korrektnyij neizmenyonnyij plan vyipolnyayetsya s proverkoj tochnyikh vyikhodnyikh bajtov. Razovoye ispravleniye komandyi ne dokazyivayet etu obsjhuyu meru.

## Nablyudayemoye vosstanovleniye

[Kvitanciya primeneniya 0126](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/kvitanciya-registracii-0126.json) svyazyivayet SHA paketa i plana, iskhodnyiye HEAD/ref i prochitannyiye SHA vsekh vyikhodov do recency. Pozdneye ogranichennoye utochneniye 0126 imeyet otdeljnuyu kvitanciyu i ne vyidayotsya za prezhnij rezuljtat plana. Istoricheskij oshibochnyij vyizov ne povtoryalsya radi registracii.

## Istochniki

- [Raspredeleniye nomera i iskhodnyij zapros](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).
- [Otchyot](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:05:57 MSK -->
<!-- content-sha256: sha256:d39d9aab083dab5084efca806b2d4050e015b5f23e934588360700602a0ce4f7 -->
<!-- FUM-MD-RECENCY:END -->
