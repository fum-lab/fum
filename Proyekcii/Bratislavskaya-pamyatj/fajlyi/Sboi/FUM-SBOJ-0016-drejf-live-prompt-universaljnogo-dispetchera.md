+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0016"
"статус" = "снята"
+++
# Drejf live-prompt universaljnogo dispetchera

Kartochka istoricheski sokhranyayet nablyudyonnoye raskhozhdeniye mezhdu kanonicheskim renderer universaljnogo dispetchera i prompt dejstvovavshej heartbeat-avtomatizacii. Periodicheskij heartbeat udalyon iz rabochego puti, dispetcher snyat, a obyazateljnoye prodolzheniye Git-vetki ne chitayet i ne ispolnyayet etot live-prompt; poetomu prezhneye ozhidaniye sovpadeniya boljshe neprimenimo i ne trebuyet pochinki prompt. Syiryiye host-snimki, polnyij prompt i neprozrachnyiye lokaljnyiye identifikatoryi v pamyatj ne perenosyatsya.

## Nablyudayemyij sboj

Read-only host-audit obnaruzhil odnu prezhnyuyu prikreplyonnuyu dispetcherskuyu zadachu i odin napravlennyij v neyo `ACTIVE` heartbeat s pyatiminutnyim raspisaniyem. Dubliruyusjhij dispetcher v proverennoj inventarizacii ne obnaruzhen, odnako prochitannyij live-prompt ne sovpadayet pobajtovo s tekusjhim rezuljtatom kanonicheskogo renderer i otnositsya k predshestvuyusjhemu doanaliticheskomu pokoleniyu. Dopolniteljnyij readback zadachi cherez `read_thread` nedostupen, poetomu dejstvuyusjhij universaljnyij kontur i polnyij live-protokol upravleniya soobsjheniyami ne podtverzhdenyi.

## Granica povtoreniya

K etoj kartochke otnositsya sokhraneniye odnoj i toj zhe prikreplyonnoj zadachi i odnoj heartbeat-avtomatizacii pri byte-drift yeyo prompt otnositeljno tekusjhego renderer. Obsjhaya granica predotvrasjheniya — razreshyonnoye obnovleniye prompt na meste s sokhraneniyem identichnosti, celi, raspisaniya i statusa i otdeljnyim tochnyim readback bez dublya.

Syuda ne otnosyatsya otsutstviye avtomatizacii, poyavleniye vtoroj kopii, status `PAUSED`, drejf celi ili raspisaniya i obsjhaya nedostupnostj host-poverkhnosti bez nablyudayemogo raskhozhdeniya prompt: eti sluchai imeyut inyiye meryi vosstanovleniya. Nedostupnostj `read_thread` sama po sebe takzhe ne dokazyivayet mekhanizm drejfa.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                                                       | Effekt                                                                                              | Vosstanovleniye                                                                                                      |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0016/ПРОЯВЛЕНИЕ-0001` | [Otchyot skvoznoj priyomki](../Zhurnal/2026-08-11_09-30-31_MSK_provesti-skvoznuyu-priyomku-universaljnogo-dispetchera/otchyot.md) sokhranyayet obezlichennyij itog read-only host-audita i pobajtovogo sravneniya s kanonicheskim renderer. | Universaljnyij live-kontur i kartochka FUM-STEP-0097 ne mogut byitj prinyatyi po repozitornyim testam.      | Otdeljno razreshitj obnovleniye susjhestvuyusjhego heartbeat na meste i povtoritj nezavisimyij read-only host-audit.        |

## Ozhidaniye i klassifikaciya

Snyatyij kontrakt treboval migracii yedinstvennoj susjhestvovavshej avtomatizacii na meste i fail-closed-proverki tochnogo prompt. Nablyudayemoye raskhozhdeniye byilo nedorabotkoj prezhnego live-razvyortyivaniya, no istochnik drejfa ne ustanovlen: kartochka ne pripisyivayet yego konkretnomu upravlyayusjhemu khodu, heartbeat-tiku ili host-operacii. V dejstvuyusjhem konture eto toljko istoricheskoye nablyudeniye.

## Mekhanizm i sistemnoye ustraneniye

Mekhanizm poyavleniya doanaliticheskogo pokoleniya v prezhnej live-konfiguracii ne ustanovlen. Istoricheskim sderzhivaniyem byilo ne menyatj host-sostoyaniye bez otdeljnogo yavnogo poljzovateljskogo zapuska pochinki, ne sozdavatj replacement i ne schitatj lokaljnyiye testyi dokazateljstvom live-sovpadeniya.

Dejstvuyusjhaya arkhitektura ne ustranyayet drejf zamenoj prompt: ona isklyuchayet heartbeat i universaljnyij dispetcher iz puti prodolzheniya. Kazhdyij kommit peredayot vetku zaraneye sozdannoj zadache-prodolzheniyu, a novyij vladelec posle handoff neposredstvenno vyizyivayet vetochnyij selector.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                  | Svyazj                                                                               | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0097 — Provesti skvoznuyu priyomku universaljnogo dispetchera](../Planirovaniye/kartochki-shagov/🗑️-FUM-STEP-0097-provesti-skvoznuyu-priyomku-universaljnogo-dispetchera.md)  | Istoricheskaya popyitka priyomki snyatogo live-kontura; dejstvuyusjhej rabotyi ne porozhdayet. | `FUM-СБОЙ-0016/ПРОЯВЛЕНИЕ-0001` |

## Osnovaniye snyatiya

- Periodicheskaya heartbeat-avtomatizaciya i universaljnyij dispetcher boljshe ne yavlyayutsya dejstvuyusjhim konturom prodolzheniya FUM i dolzhnyi ostavatjsya ostanovlennyimi.
- Obyazateljnoye prodolzheniye vetki sozdayotsya do kommita i poluchayet vladeniye cherez branch-scoped FIFO bez live-prompt dispetchera.
- Snyatyij FUM-STEP-0097 ne trebuyet povtornoj priyomki ili obnovleniya prezhnej avtomatizacii.
- Kartochka povtorno aktiviruyetsya toljko pri yavnom vozvrasjhenii live-dispetchera i novogo nablyudayemogo raskhozhdeniya yego prompt.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-11_09-30-31_MSK_provesti-skvoznuyu-priyomku-universaljnogo-dispetchera/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-11_09-30-31_MSK_provesti-skvoznuyu-priyomku-universaljnogo-dispetchera/otchyot.md)
- [trebovaniye universaljnoj dispetcherizacii](../Trebovaniya/🗑️-universaljnaya-dispetcherizaciya-periodicheskikh-avtomatizacij.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:1492eaa00b2efb6924d939ffca6b7d962f988186f4cb8b0c07cdbdd4a96f6f11 -->
<!-- FUM-MD-RECENCY:END -->
