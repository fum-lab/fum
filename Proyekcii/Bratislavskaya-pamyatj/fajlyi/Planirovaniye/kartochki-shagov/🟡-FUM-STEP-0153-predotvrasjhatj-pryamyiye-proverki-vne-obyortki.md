+++
schema_version = 1
card_id = "FUM-STEP-0153"
status = "active"
+++
# Predotvrasjhatj pryamyiye proverki vne obyortki

## Zadacha

Zakrepitj proveryayemuyu meru, ne pozvolyayusjhuyu pri ruchnom formirovanii komand zabyivatj obyazateljnuyu obyortku pryamyikh proverok.

## Pochemu sejchas

Iskhodnyij adresnyij diff proshyol bez mashinnoj zapisi. Povtor 0176 dobavil pryamuyu sborku reyestra s neizvestnyim vremenem, a epizod kornya 0201 — chetyire build vne obyortki, tri otkaza i uspekh. Shtatnyiye pozdniye zapuski podtverdili novoye sostoyaniye, no ne vosstanovili dokazateljstvo iskhodnyikh vyizovov zadnim chislom. V kartochke FUM-SBOJ-0025 sokhranenyi pyatj proyavlenij odnoj granicyi: 0001–0003, nezavisimoye 0101 napravleniya vselennoj i 0102 priyomki konteksta. V poslednem epizode otdeljnyiye vremya i kod predvariteljnogo diff ne sokhranenyi; pozdnij uchtyonnyij povtor ne podmenyayet pervonachaljnuyu kvitanciyu.

Vtoroye podtverzhdyonnoye proyavleniye `FUM-СБОЙ-0025/ПРОЯВЛЕНИЕ-0002` vozniklo pri zapuske planovogo generatora v perenose 0176. Mera dolzhna okhvatyivatj takzhe proverochnyiye generatoryi vnutri sostavnyikh komand.

## Kriterii zaversheniya

- Razlichenyi proverochnyiye vyizovyi, read-only-inventarj i razreshyonnyiye proverki zamyikaniya zakryitogo otchyota.
- Primer pryamoj proverki vne obyortki obnaruzhivayetsya ili blokiruyetsya do yeyo ispolneniya; obyichnaya proverka poluchayet sobstvennuyu mashinnuyu zapisj.
- Obkhod ne maskiruyetsya ruchnyim izgotovleniyem zapisi ili vyidachej povtornogo zapuska za iskhodnyij.
- Ogranicheniya vyibrannoj meryi i proverennyiye primeryi svyazanyi so vsemi pyatjyu proyavleniyami sboya; pryamoj diff, sborka reyestra i neskoljko proverochnyikh processov v odnoj shell-komande razlichenyi.
- Obsjhij kod poslednej shell-komandyi ne podmenyayet otdeljnyiye iskhodyi predshestvuyusjhikh proverochnyikh processov; neizvestnoye vremya ne ocenivayetsya zadnim chislom.

## Istochniki

- [FUM-SBOJ-0025/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0025-pryamoj-zapusk-proverki-vne-mashinnogo-uchyota.md#proyavleniya).

- [Iskhodnyij zapros](../../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [FUM-SBOJ-0025/PROYAVLENIYE-0001–0003](../../Sboi/FUM-SBOJ-0025-pryamoj-zapusk-proverki-vne-mashinnogo-uchyota.md#proyavleniya).

- [Otchyot 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-28-44_MSK_перенести-исходники-FUMA/отчёт.md) i [otchyot kornya 0201](../../Zhurnal/2026-09-11_08-49-30_MSK_prinyatj-perekodirovaniye-DNK-v-belki/otchyot.md).
- [Novyij zapros diagnostiki](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md) i [otchyot](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).
- [FUM-SBOJ-0025/PROYAVLENIYE-0101 i 0102](../../Sboi/FUM-SBOJ-0025-pryamoj-zapusk-proverki-vne-mashinnogo-uchyota.md#proyavleniya) i [naznacheniye 0102](../../Zhurnal/2026-09-14_20-03-08_MSK_utochnitj-sobstvennyiye-imena-postavki/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 04:26:02 MSK -->
<!-- content-sha256: sha256:46a59b7160b3cebeb4a9f4fd6534e6b154310bcab2b9ec4dca4a6919e00691c4 -->
<!-- FUM-MD-RECENCY:END -->
