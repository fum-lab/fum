+++
schema_version = 1
card_id = "FUM-STEP-0147"
status = "completed"
+++

# Isklyuchitj dublirovaniye polnoj regressii pered finaljnyim smoke-check

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet zavershyonnuyu optimizaciyu proverochnogo kontura: mashinnyij profilj otlichayet risk-sorazmernuyu adresnuyu proverku, dokazannuyu diagnostiku i yedinstvennyij finaljnyij smoke-check vyibrannogo profilya.

## Zadacha

Zakrepitj ekonomnyij poryadok proverok: do obyazateljnogo finaljnogo smoke-check zapuskatj toljko adresnyiye i deshyovyiye strukturnyiye proverki izmenyonnoj granicyi, a polnyij nabor, kotoryij uzhe vkhodit v smoke-check, ne vyipolnyatj otdeljnyim dubliruyusjhim progonom bez yavno dokazannoj diagnosticheskoj neobkhodimosti.

## Rezuljtat

Skhema `fum.test-run.v3` dobavila k kazhdoj novoj zapisi zakryityij `профиль_проверки`. On sokhranyayet klass `адресная`, `диагностическая` ili `полная`, avtomaticheskij otpechatok Git-snimka i tochnyiye klyuchi polnyikh naborov. Dlya finaljnogo smoke-check klyuchi ne doveryayutsya metke vyizova: oni vyivodyatsya iz fakticheski sformirovannogo plana, a iskhodyi — iz dostignutyikh nablyudenij.

Mashinnyij plan sopostavlyayet boleye rannij diagnosticheskij ili polnyij okhvat s yedinstvennyim uspeshnyim finaljnyim smoke-check na tom zhe otpechatke. Diagnosticheskoye perekryitiye razreshayetsya toljko s nepustyim ozhidayemyim svideteljstvom i, dlya lokalizacii, s tochnyim UUID predshestvuyusjhego neuspeshnogo zapuska. Strogaya komanda `проверить-план` podtverzhdayet finaljnostj i neizmennostj snimka. V `manual-sequential-v1` obyichnoj priyomkoj ostayotsya standartnyij dokumentacionnyij profilj; yavnyij `--профиль полный`, yesli on nuzhen, sam zanimayet yedinstvennuyu finaljnuyu poziciyu. Posle zakryitiya vyipolnyayutsya toljko proverki zamyikaniya, odin lokaljnyij kommit na `master` i zaversheniye bez continuation.

## Istochniki

- [iskhodnyij zapros zaversheniya shaga](../../Zhurnal/2026-08-14_18-59-37_MSK_isklyuchitj-dublirovaniye-polnoj-regressii/zapros.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-13_13-14-24_MSK_svyazatj-sleduyusjhiye-shagi-s-dorozhnoj-kartoj/zapros.md)
- [otchyotyi o zapuskakh proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)
- [kompleksnaya proverka repozitoriya](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 14:29:42 MSK -->
<!-- content-sha256: sha256:b037ad41176c3b07405e6ca481f19813817593ecd76f549a567a943422c4d7ac -->
<!-- FUM-MD-RECENCY:END -->
