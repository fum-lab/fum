# Versionirovannaya pervichnaya trassa sobyitij vvoda

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0009 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna neizmenyayemo i dolgovremenno sokhranyatj postupayusjhiye ot adapterov ustrojstv pervichnyiye sobyitiya vvoda v obsjhej versionirovannoj trasse do ikh svedeniya k zhestam, komandam i smyislovyim interpretaciyam. Zapisi sokhranyayut iskhodnyij poryadok, monotonnoye vremya, tip i identichnostj ustrojstva, fizicheskij element upravleniya, predostavlennyiye istochnikom izmereniya, proiskhozhdeniye nablyudeniya, versii skhemyi, adaptera i API.

Trassa yavno predstavlyayet nedostupnyiye polya, poteri, obyyedineniye sobyitij, razryivyi, perepolneniye, podklyucheniye, otklyucheniye i izmeneniye konfiguracii ustrojstv. Diagnostika istochnika khranitsya otdeljno ot pervichnyikh sobyitij i ne podmenyayet otsutstvuyusjhiye nablyudeniya sintezirovannyimi znacheniyami. Chteniye staroj versii skhemyi dolzhno ostavatjsya vosproizvodimyim, a postroyeniye novyikh proizvodnyikh predstavlenij ne izmenyayet uzhe sokhranyonnyiye zapisi.

## Semanticheskiye svyazi

- **yavlyayetsya chastjyu:** [maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — zadayot obsjhij format i zhiznennyij cikl pervichnyikh nablyudenij vsekh podderzhivayemyikh semejstv ustrojstv.
- **zavisit ot:** [zasjhisjhyonnogo sbora chuvstviteljnogo vvoda](🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md) — dolgovremennaya trassa dopustima toljko pri upravlyayemyikh dostupe, sroke khraneniya, udalenii i eksporte.
- **trebuyetsya dlya:** [fizicheskikh perekhodov klavish](🚧-fizicheskiye-perekhodyi-klavish.md) — sokhranyayet fizicheskiye sostoyaniya klavish i diagnostiruyemyiye poteri klaviaturnyikh istochnikov.
- **trebuyetsya dlya:** [maksimaljno syiroj zapisi sobyitij myishi](🟡-maksimaljno-syiraya-zapisj-sobyitij-myishi.md) — prinimayet knopki, peremesjheniya i prokrutku bez svedeniya k komandam ukazatelya.
- **trebuyetsya dlya:** [maksimaljno syiroj zapisi sobyitij kontaktnyikh poverkhnostej](🟡-maksimaljno-syiraya-zapisj-sobyitij-kontaktnyikh-poverkhnostej.md) — sokhranyayet zhiznennyij cikl otdeljnyikh kontaktov do raspoznavaniya zhestov.
- **trebuyetsya dlya:** [maksimaljno syiroj zapisi sobyitij perjyevyikh ustrojstv](🟡-maksimaljno-syiraya-zapisj-sobyitij-perjyevyikh-ustrojstv.md) — sokhranyayet fazyi, koordinatyi i fizicheskiye izmereniya pera do postroyeniya shtrikhov.
- **dopolnyayetsya:** [nepreryivnyim sobyitijnyim nablyudeniyem poljzovateljskogo vvoda](🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md) — pervichnoye dolgovremennoye khraneniye i operativnoye postupleniye sobyitij v rabotayusjhij kontur sokhranyayutsya kak svyazannyiye, no raznyiye obyazannosti.

## Kriterii proverki

- odinakovyij nabor pervichnyikh zapisej posle kodirovaniya i chteniya sokhranyayet versiyu skhemyi, posledovateljnostj, monotonnoye vremya, identichnostj ustrojstva, proiskhozhdeniye i vse izvestnyiye polya bez smyislovogo preobrazovaniya;
- zapisi ot neskoljkikh odnovremennyikh istochnikov sokhranyayut nablyudayemyij poryadok vnutri kazhdogo istochnika, yavno zadayut yedinicu i domen monotonnogo vremeni i dopuskayut vosproizvodimoye mezhistochnikovoye sopostavleniye;
- nedostupnoye pole, obyyedineniye sobyitij, perepolneniye, razryiv i smena konfiguracii predstavlenyi yavnyim otsutstviyem ili otdeljnoj diagnosticheskoj zapisjyu, a ne pravdopodobnyim sinteticheskim sobyitiyem;
- avarijnoye zaversheniye vo vremya dozapisi ne povrezhdayet raneye podtverzhdyonnyiye zapisi, a povtornyij zapusk obnaruzhivayet i obyyasnyayet nepolnyij khvost;
- podklyucheniye, otklyucheniye, son, probuzhdeniye i izmeneniye konfiguracii ustrojstva ostavlyayut vosproizvodimuyu granicu zhiznennogo cikla;
- povtornoye postroyeniye zhestov, komand ili inyikh proizvodnyikh predstavlenij ne izmenyayet pobitovoye soderzhimoye pervichnoj trassyi;
- srok khraneniya, dostup, udaleniye i vozmozhnyij eksport trassyi podchinyayutsya otdeljnomu trebovaniyu o [zasjhisjhyonnom sbore chuvstviteljnogo vvoda](🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md).

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🚧`: realizuyetsya. [Swift-prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md) uzhe zakrepil `schemaVersion`, posledovateljnyij nomer, identichnostj ustrojstva, JSONL-kodirovaniye, chteniye i avtonomnyiye testyi klaviaturnogo sreza. Vremennyiye domenyi IOHID, CGEvent, NSEvent i GCKeyboard svodyatsya k nanosekundam s momenta zapuska sistemyi; tiki IOHID preobrazuyutsya cherez `mach_timebase_info` s bezopasnoj obrabotkoj perepolneniya. Provodnik sokhranyayet snimok testovogo plana, iskhodyi popyitok, razreshyonnyiye syiryiye nablyudeniya, resheniya otdeljnogo reduktora kazhdogo istochnika i diagnosticheskiye razryivyi v atomarno zavershayemom lokaljnom seanse.

Testovyij seans ne podmenyayet dolgovremennuyu proizvodstvennuyu trassu. Do zaversheniya ostayutsya atomarnaya dozapisj i vosstanovleniye khvosta, polnoye proiskhozhdeniye adapterov i vremennyikh tochek izmereniya, diagnostika otkaza normalizacii vremeni, sobyitiya zhiznennogo cikla ustrojstv, migracii skhemyi i proverka sovmestnoj trassyi raznyikh semejstv vvoda. Kartochka ne opredelyayet fizicheskiye polya otdeljnyikh ustrojstv i ne zadayot interpretaciyu sokhranyonnyikh nablyudenij.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-21 13:49:43 MSK](../Zhurnal/2026-07-21_13-49-43_MSK_dorabotatj-prototip-sbora-klaviaturnyikh-sobyitij/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-20 14:24:31 MSK](../Zhurnal/2026-07-20_14-24-31_MSK_normalizovatj-monotonnoye-vremya-istochnikov-vvoda/zapros.md)
- [prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ec877f9a4787ae284d393612bb4d897658f84e9e39bfa726188f09929f71509e -->
<!-- FUM-MD-RECENCY:END -->
