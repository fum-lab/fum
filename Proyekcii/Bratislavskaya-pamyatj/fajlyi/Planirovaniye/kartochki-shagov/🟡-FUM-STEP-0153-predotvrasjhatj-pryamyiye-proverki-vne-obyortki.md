+++
schema_version = 1
card_id = "FUM-STEP-0153"
status = "active"
+++
# Predotvrasjhatj pryamyiye proverki vne obyortki

## Zadacha

Zakrepitj proveryayemuyu meru, ne pozvolyayusjhuyu pri ruchnom formirovanii komand zabyivatj obyazateljnuyu obyortku pryamyikh proverok.

## Pochemu sejchas

Iskhodnyij adresnyij diff proshyol bez mashinnoj zapisi. Povtor 0176 dobavil pryamuyu sborku reyestra s neizvestnyim vremenem, a epizod kornya 0201 — chetyire build vne obyortki, tri otkaza i uspekh. Shtatnyiye pozdniye zapuski podtverdili novoye sostoyaniye, no ne vosstanovili dokazateljstvo iskhodnyikh vyizovov zadnim chislom. FUM-SBOJ-0025 teperj soderzhit tri proyavleniya odnoj granicyi.

Vtoroye podtverzhdyonnoye proyavleniye `FUM-СБОЙ-0025/ПРОЯВЛЕНИЕ-0002` vozniklo pri zapuske planovogo generatora v perenose 0176. Mera dolzhna okhvatyivatj takzhe proverochnyiye generatoryi vnutri sostavnyikh komand.

## Kriterii zaversheniya

- Razlichenyi proverochnyiye vyizovyi, read-only-inventarj i razreshyonnyiye proverki zamyikaniya zakryitogo otchyota.
- Primer pryamoj proverki vne obyortki obnaruzhivayetsya ili blokiruyetsya do yeyo ispolneniya; obyichnaya proverka poluchayet sobstvennuyu mashinnuyu zapisj.
- Obkhod ne maskiruyetsya ruchnyim izgotovleniyem zapisi ili vyidachej povtornogo zapuska za iskhodnyij.
- Ogranicheniya vyibrannoj meryi i proverennyiye primeryi svyazanyi so vsemi tremya proyavleniyami sboya; pryamoj diff, sborka reyestra i neskoljko proverochnyikh processov v odnoj shell-komande razlichenyi.
- Obsjhij kod poslednej shell-komandyi ne podmenyayet otdeljnyiye iskhodyi predshestvuyusjhikh proverochnyikh processov; neizvestnoye vremya ne ocenivayetsya zadnim chislom.

## Istochniki

- [FUM-SBOJ-0025/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0025-pryamoj-zapusk-proverki-vne-mashinnogo-uchyota.md#proyavleniya).

- [Iskhodnyij zapros](../../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [FUM-SBOJ-0025/PROYAVLENIYE-0001–0003](../../Sboi/FUM-SBOJ-0025-pryamoj-zapusk-proverki-vne-mashinnogo-uchyota.md#proyavleniya).

- [Otchyot 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-28-44_MSK_перенести-исходники-FUMA/отчёт.md) i [otchyot kornya 0201](../../Zhurnal/2026-09-11_08-49-30_MSK_prinyatj-perekodirovaniye-DNK-v-belki/otchyot.md).
- [Novyij zapros diagnostiki](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md) i [otchyot](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 11:59:08 MSK -->
<!-- content-sha256: sha256:642ab58726d0de8be3044c5a28e07a8fe36f42159c00850c42242ed42fffc488 -->
<!-- FUM-MD-RECENCY:END -->
