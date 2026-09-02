+++
schema_version = 1
card_id = "FUM-STEP-0139"
status = "active"
+++
# Proveryatj razdeleniye kriteriyev sboyev i svyazannyikh shagov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Rasshiritj mashinnyij kontur kartochek sboyev determinirovannoj proverkoj, kotoraya dlya kazhdoj svyazannoj paryi razlichayet diagnosticheskuyu granicu zakryitiya i realizacionnyij plan shaga, obnaruzhivayet pochti polnoye soderzhateljnoye dublirovaniye ikh kriteriyev i zakryito otklonyayet takuyu paru s tochnyim obyyasneniyem sovpadenij.

## Pochemu sejchas

FUM-SBOJ-0009 pochti polnostjyu povtorila kriterii FUM-STEP-0137, a sleduyusjhaya FUM-SBOJ-0010 povtorila kriterii FUM-STEP-0138. Vtoroye podtverzhdyonnoye proyavleniye `FUM-СБОЙ-0011/ПРОЯВЛЕНИЕ-0002` stalo tochnyim osnovaniyem shaga. Posle yego oformleniya FUM-SBOJ-0012 vnovj povtorila kriterii FUM-STEP-0140; `FUM-СБОЙ-0011/ПРОЯВЛЕНИЕ-0003` aktualiziruyet regressionnuyu oblastj i dokazyivayet, chto pryamogo pravila glossariya i ruchnogo revjyu nedostatochno.

## Kriterii zaversheniya

- Krasnaya avtonomnaya fikstura sinteziruyet po obobsjhyonnomu otchyotnomu sopostavleniyu osnovaniya `FUM-СБОЙ-0011/ПРОЯВЛЕНИЕ-0002` paru, gde semj kriteriyev kartochki sboya pochti polnostjyu pokryivayutsya vosemjyu kriteriyami shaga. Fikstura proveryayet klass defekta, no ne vyidayotsya za tochnyij snimok utrachennogo predkorrekcionnogo teksta.
- Proverka izvlekayet toljko dejstvuyusjhiye razdelyi `Критерии закрытия` kartochki sboya i `Критерии завершения` kazhdoj pryamo svyazannoj kartochki shaga; istochniki, proyavleniya, poyasneniya i nesvyazannyiye dokumentyi ne vkhodyat v sravneniye.
- Normalizaciya Markdown, ssyilok, identifikatorov i sluzhebnyikh oborotov, mera skhodstva punktov i porog pochti polnogo pokryitiya zadanyi konechnyim versionirovannyim kontraktom i dayut odinakovyij rezuljtat bez seti, modeli i zavisimosti ot poryadka obkhoda fajlov.
- Proverka ocenivayet ne odno sovpavsheye slovo ili obsjhij test, a sootvetstviye punktov i dolyu pokryitiya vsego spiska; otkaz soderzhit tochnyiye puti, nomera libo ustojchivyiye otpechatki sopostavlennyikh punktov i vyichislennyiye znacheniya, dostatochnyiye dlya avtonomnogo vosproizvedeniya.
- Tri obobsjhyonnyikh sopostavleniya iz FUM-SBOJ-0011 porozhdayut yavno sinteticheskiye otricateljnyiye regressii; perestanovka, neznachiteljnoye perefrazirovaniye i zamena Markdown-ssyilki tekstovyim identifikatorom ne obkhodyat obnaruzheniye pochti polnogo dublirovaniya.
- Polozhiteljnyiye fiksturyi dopuskayut kratkuyu ssyilku kartochki sboya na zaversheniye neobkhodimogo shaga, obsjhij identifikator proyavleniya, odnu regressiyu i razdelyayemyij vneshnij invariant, yesli diagnosticheskij spisok ne pokryivayet realizacionnyij chek-list.
- Lyuboye uzkoye isklyucheniye zakreplyayet tochnuyu svyazannuyu paru, otpechatki dopustimyikh obsjhikh utverzhdenij i soderzhateljnuyu prichinu; wildcard, bessrochnoye otklyucheniye paryi i razresheniye vsego razdela zapresjhenyi.
- Posle krasnyikh regressij kriterii FUM-SBOJ-0009 i FUM-SBOJ-0010 razdelyayutsya s planami FUM-STEP-0137 i FUM-STEP-0138: kartochki sboyev sokhranyayut toljko samostoyateljnuyu diagnosticheskuyu granicu, a trebovaniya k realizacii i testovoj matrice ostayutsya v shagakh.
- Proverka vklyuchena v mashinnyij kontur FUM-STEP-0114 i obsjhij smoke-check, vidit otslezhivayemyiye i novyiye neignoriruyemyiye kartochki i ne zavisit ot proizvodnogo planovogo JSON.
- Avtonomnyiye testyi pokryivayut tri sinteticheskiye regressii po obobsjhyonnyim proyavleniyam, tochnuyu kopiyu, pochti polnoye perefrazirovannoye pokryitiye, odinochnoye dopustimoye sovpadeniye, nesvyazannuyu paru, uzkoye isklyucheniye i ustojchivostj diagnosticheskogo vyivoda.

## Istochniki

- [FUM-SBOJ-0011 — Kopirovaniye kriteriyev shagov v kartochki sboyev](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md) — tochnoye osnovaniye `FUM-СБОЙ-0011/ПРОЯВЛЕНИЕ-0002`
- [tretjye proyavleniye FUM-SBOJ-0011](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md#proyavleniya) — aktualizaciya `FUM-СБОЙ-0011/ПРОЯВЛЕНИЕ-0003`
- [pravilo soderzhaniya kartochki sboya](../../Glossarij/kartochka-sboya.md#soderzhaniye-kartochki)
- [FUM-STEP-0114 — Kontur pamyati i sistemnogo ustraneniya nedorabotok](🟡-FUM-STEP-0114-dobavitj-proveryayemyij-kontur-pamyati-i-sistemnogo-ustraneniya-nedorabotok.md)
- [FUM-SBOJ-0009](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md) i [FUM-STEP-0137](🟡-FUM-STEP-0137-razreshatj-tochnyiye-lokaljnyiye-puti-po-inventaryu-pered-vyizovom.md)
- [FUM-SBOJ-0010](../../Sboi/FUM-SBOJ-0010-maskirovka-rannego-otkaza-sostavnoj-shell-diagnostiki.md) i [FUM-STEP-0138](🟡-FUM-STEP-0138-ograditj-sostavnuyu-shell-diagnostiku-ot-maskirovki-rannego-otkaza.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 01:09:33 MSK -->
<!-- content-sha256: sha256:55e9e8ff4cab877d56b91ba7c79579b8033a9fc173bdeafae32fc4966f740b31 -->
<!-- FUM-MD-RECENCY:END -->
