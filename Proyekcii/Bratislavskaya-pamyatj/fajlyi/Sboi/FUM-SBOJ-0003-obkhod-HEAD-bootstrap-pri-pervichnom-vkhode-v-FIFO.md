+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0003"
"статус" = "снята"
+++
# Obkhod HEAD-bootstrap pri pervichnom vkhode v FIFO

Ekspluatacionnyij status: kartochka snyata iz dejstvuyusjhego kontura, potomu chto ruchnaya posledovateljnaya skhema ne vyipolnyayet pervichnyij `join`, HEAD-bootstrap ili inyiye FIFO-perekhodyi. Opisaniye proyavleniya, mekhanizma i kriteriyev nizhe sokhranyayetsya kak istoricheskoye svideteljstvo i usloviye vozmozhnogo budusjhego vozvrata ocheredi, no ne predpisyivayet dejstviya tekusjhej sessii.

Kartochka sokhranyayet narusheniye doverennoj granicyi pervogo vkhoda kornevoj zadachi v FIFO. V nachale tekusjhej sessii agent snachala ugadal nesusjhestvuyusjheye imya scenariya, a zatem vyipolnil `join` pryamyim scenariyem rabochego dereva vmesto obyazateljnoj zagruzki tekh zhe bajtov iz `HEAD`; posleduyusjhiye komandyi ispoljzovali kanonicheskij bootstrap i sokhranili iskhodnyij bilet.

## Nablyudayemyij sboj

Do chteniya tochnogo interfejsa navyika kornevoj agent popyitalsya vyizvatj ocheredj po ugadannomu puti i poluchil otkaz zapuska. Sleduyusjhaya popyitka nashla nastoyasjhij scenarij rabochego dereva i uspeshno zaregistrirovala bilet, no oboshla pryamoj zapret obyichnoj sessii na takoj vyizov. Rabocheye derevo v etot moment byilo chistyim, poetomu fakticheskiye bajtyi sovpali s `HEAD` i povrezhdeniya ocheredi ne nablyudalosj; doverennaya granica vsyo ravno zavisela ot sluchajnogo sostoyaniya checkout.

## Granica povtoreniya

Kartochka okhvatyivayet pervichnyij `join` obyichnoj kornevoj zadachi cherez ugadannyij putj, pryamoj scenarij rabochego dereva ili inoj vkhod, kotoryij ne zagruzil avtomatizaciyu ocheredi iz tochnogo tekusjhego `HEAD` kanonicheskim izolirovannyim bootstrap.

Syuda ne otnosyatsya avtonomnyiye testyi razrabotki ocheredi, kanonicheskij HEAD-bootstrap, povtornyij idempotentnyij `join` posle poteri otveta i otkaz nesusjhestvuyusjhej komandyi, yesli posle nego ni odin nedoverennyij scenarij ne byil ispolnen.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                              | Effekt                                                                                               | Vosstanovleniye                                                                                                                                          |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0003/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md) fiksiruyet obe popyitki i posleduyusjhij perekhod na tochnyij bootstrap. | Bilet sozdan korrektno, no celostnostj pervogo vkhoda ne byila mashinno ograzhdena ot gryaznogo checkout. | Vse posleduyusjhiye komandyi zagruzili ocheredj iz `HEAD`; tot zhe bilet perezhil ozhidaniye, setevoye preryivaniye, `reload_required`, `ack-head` i shtatnyij dopusk. |

## Ozhidaniye i klassifikaciya

Eto nedorabotka ispolneniya: [kontrakt ocheredi](../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md) pryamo zapresjhayet obyichnoj sessii vyizyivatj scenarij rabochego dereva i trebuyet HEAD-bootstrap pervyim dejstviyem. Nablyudayemogo povrezhdeniya dannyikh net, no narusheniye primenimogo pravila lishilo pervyij vkhod garantii nezavisimosti ot nezavershyonnogo obsjhego diff.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon chelovecheski-modeljnyij mekhanizm: do dopuska agent dolzhen samostoyateljno najti lokaljnyij navyik i tochno vosproizvesti dlinnuyu komandu bootstrap, khotya imenno pervyij vkhod yesjhyo ne zasjhisjhyon host- ili orkestracionnyim vladeljcem. Tekstovoye pravilo obnaruzhivayet narusheniye toljko postfaktum i ne meshayet pryamomu scenariyu vyipolnitj `join`.

Vremennoye sderzhivaniye obespechivayut yavnyij zapret v navyike, chteniye scenariya iz `HEAD` vsemi posleduyusjhimi vyizovami i idempotentnostj bileta. Polnoye ustraneniye trebuyet doverennoj pervichnoj tochki vkhoda, kotoraya svyazyivayet tochnyij `CODEX_THREAD_ID` s HEAD-versiyej ocheredi do peredachi resheniya modeli i zakryito otvergayet rabochuyu kopiyu v obyichnom rezhime.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                                      | Svyazj                                                                                                     | Osnovaniye                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0131 — Ograditj pervichnyij vkhod v FIFO doverennoj zagruzkoj iz HEAD](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0131-ograditj-pervichnyij-vkhod-v-FIFO-doverennoj-zagruzkoj-iz-HEAD.md)                       | Predotvrasjhayet pryamoj zapusk rabochego dereva i proveryayet host- ili orkestracionnuyu granicu pervogo `join`. | `FUM-СБОЙ-0003/ПРОЯВЛЕНИЕ-0001` |
| [FUM-STEP-0114 — Dobavitj proveryayemyij kontur pamyati i sistemnogo ustraneniya nedorabotok](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md) | Proveryayet sokhrannostj proyavleniya, dopustimogo iskhoda i dvustoronnej svyazi s shagom.                        | Kontur kartochek sboyev           |

## Kriterii zakryitiya

- Pervyij obyichnyij `join` vyipolnyayetsya doverennoj host- ili orkestracionnoj tochkoj vkhoda do dostupnogo modeli mutiruyusjhego puti i zagruzhayet avtomatizaciyu toljko iz tochnogo `HEAD`.
- Tochnyij kornevoj `CODEX_THREAD_ID` peredayotsya iz sredyi bez ruchnogo kopirovaniya i svyazyivayetsya s sozdannyim libo uzhe susjhestvuyusjhim biletom.
- Pryamoj scenarij rabochego dereva v obyichnom rezhime zakryito otvergayetsya; avtonomnyiye testyi ispoljzuyut otdeljnuyu yavno ograzhdyonnuyu testovuyu granicu.
- Poterya otveta i vosstanovleniye konteksta idempotentno vozvrasjhayut tot zhe bilet bez vtorogo mesta v FIFO.
- Avtonomnaya fikstura i zhivaya dvukhzadachnaya priyomka podtverzhdayut granicu na chistom i gryaznom checkout.
- FUM-STEP-0131 zavershena, a dokazateljstvo yeyo primenimyikh kriteriyev svyazano s etoj kartochkoj.

## Istochniki

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [kontrakt ocheredi zadach Git-vetki](../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:57:35 MSK -->
<!-- content-sha256: sha256:ce16549b9d1d09a7fe8fb30f924920e7ab9a6d4c24d8d1c1e5fd77a63e08f5ad -->
<!-- FUM-MD-RECENCY:END -->
