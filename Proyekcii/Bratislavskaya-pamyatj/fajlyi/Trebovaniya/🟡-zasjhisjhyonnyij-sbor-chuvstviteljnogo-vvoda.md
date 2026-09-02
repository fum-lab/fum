# Zasjhisjhyonnyij sbor chuvstviteljnogo vvoda

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0014 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) dolzhna sobiratj i khranitj chuvstviteljnyiye sobyitiya ustrojstv vvoda toljko posle yavnogo dejstviya vladeljca, v oboznachennoj oblasti i s minimaljnyimi sistemnyimi pravami. Sbor po umolchaniyu vyiklyuchen; yego aktivnostj, okhvachennyiye ustrojstva, mesto khraneniya i srok dolzhnyi byitj nablyudayemyi chelovekom, a otzyiv razresheniya prekrasjhayet novyiye zapisi bez obkhoda zasjhitnyikh mekhanizmov operacionnoj sistemyi.

Pervichnaya trassa zasjhisjhayetsya lokaljnyimi mekhanizmami dostupa i khraneniya, udalyayetsya po istechenii zadannogo sroka ili po yavnoj komande i ne pokidayet lokaljnyij kontur bez otdeljnogo razresheniya na konkretnyij eksport. Diagnosticheskiye i publikacionnyiye otchyotyi ne dolzhnyi raskryivatj soderzhateljnyiye nazhatiya, tekst, ustojchivyiye identifikatoryi ustrojstv ili inoj chuvstviteljnyij potok, yesli eto ne trebuyetsya otdeljno razreshyonnoj proverkoj.

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [maksimaljno syiroj zapisi sobyitij ustrojstv vvoda](🚧-maksimaljno-syiraya-zapisj-sobyitij-ustrojstv-vvoda.md) — zadayot poperechnuyu granicu soglasiya, prav, khraneniya, udaleniya i eksporta dlya vsekh semejstv vvoda.
- **trebuyetsya dlya:** [versionirovannoj pervichnoj trassyi sobyitij vvoda](🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md) — zadayot dopustimyij zhiznennyij cikl dolgovremenno sokhranyayemyikh chuvstviteljnyikh nablyudenij.
- **trebuyetsya dlya:** [nepreryivnogo sobyitijnogo nablyudeniya poljzovateljskogo vvoda](🟡-nepreryivnoye-sobyitijnoye-nablyudeniye-poljzovateljskogo-vvoda.md) — ogranichivayet oblastj, prava i otzyiv razresheniya dlya vkhoda, postupayusjhego vo vremya rabotyi.

## Kriterii proverki

- posle chistoj ustanovki i obyichnogo zapuska soderzhateljnyiye sobyitiya vvoda ne zapisyivayutsya do otdeljnogo yavnogo vklyucheniya;
- vklyucheniye zadayot ponyatnyiye cheloveku oblastj, ustrojstva, naznacheniye i srok, a interfejs ili komanda sostoyaniya odnoznachno pokazyivayet aktivnyij sbor;
- prilozheniye zaprashivayet toljko neobkhodimyiye tekusjhemu istochniku razresheniya i ne obkhodit Secure Input, sandbox, sistemnyiye zapretyi ili zasjhisjhyonnyiye polya;
- otzyiv soglasiya ili razresheniya prekrasjhayet novyiye zapisi, zakryivayet aktivnuyu sessiyu trassyi i ostavlyayet diagnostiruyemuyu, no ne soderzhateljnuyu granicu;
- sokhranyonnaya trassa nedostupna vne razreshyonnogo lokaljnogo kontura, a rezervnyiye, vremennyiye i avarijnyiye fajlyi poluchayut tu zhe zasjhitu;
- istecheniye sroka i yavnoye udaleniye proveryayemo ustranyayut trassu, yeyo indeksyi i vremennyiye kopii v predelakh kontroliruyemogo khranilisjha;
- peredacha za predelyi lokaljnogo kontura trebuyet otdeljnogo razresheniya s ukazannyimi poluchatelem i sostavom dannyikh;
- vosproizvodimyij sravniteljnyij otchyot mozhet byitj opublikovan bez fakticheskikh nazhatij, teksta, serijnyikh nomerov, tokenov, lokaljnyikh putej i inyikh sekretov.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: trebovaniye prinyato i zaplanirovano. Klaviaturnyij prototip uzhe realizuyet ogranichennyij testovyij srez: do otdeljnogo soglasiya istochniki ne zapuskayutsya, aktivnaya kartochka i krasnyij indikator zadayut oblastj zapisi, neozhidannaya klavisha ne sokhranyayetsya, a rezuljtat ostayotsya v tochno ignoriruyemom Git lokaljnom kataloge s pravami `0700`/`0600` i yavnyim udaleniyem cherez GUI. Absolyutnyij putj, simvolyi, tekst, raskladka, prilozheniye perednego plana, imya poljzovatelya, imya mashinyi i serijnyiye nomera v nabor dannyikh ne vkhodyat.

Polnyij kontrakt yesjhyo ne dostignut: tochnyiye vremena i posledovateljnosti kodov ostayutsya chuvstviteljnyimi, avtomaticheskogo sroka udaleniya i razreshyonnogo eksporta net, otzyiv sistemnogo razresheniya ne zakryivayet vesj seans avtomaticheski, a zapusk SwiftPM ne dayot ustojchivoj podpisannoj TCC-identichnosti. Provodnik prednaznachen toljko dlya dobrovoljnogo lokaljnogo testovogo progona vladeljcem i ne dokazyivayet zasjhisjhyonnostj dolgovremennogo proizvodstvennogo khranilisjha.

Kartochka ne razreshayet skryitoye nablyudeniye, obkhod sistemnoj zasjhityi ili sbor dannyikh drugikh lyudej bez polnomochij vladeljca. Konkretnyij kriptograficheskij i sistemnyij mekhanizm vyibirayetsya otdeljno dlya kazhdoj podderzhivayemoj platformyi i proveryayetsya po etomu kontraktu.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-21 13:49:43 MSK](../Zhurnal/2026-07-21_13-49-43_MSK_dorabotatj-prototip-sbora-klaviaturnyikh-sobyitij/zapros.md)
- [iskhodnyij zapros 2026-07-17 09:18:01 MSK](../Zhurnal/2026-07-17_09-18-01_MSK_dobavitj-kartochku-syiroj-zapisi-sobyitij-vvoda/zapros.md)
- [ocenka dekompozicii 2026-07-17 14:44:31 MSK](../Zhurnal/2026-07-17_14-44-31_MSK_ocenitj-dekompoziciyu-kartochki-sobyitij-vvoda/zapros.md)
- [iskhodnyij zapros 2026-07-18 07:11:37 MSK](../Zhurnal/2026-07-18_07-11-37_MSK_dekompozirovatj-kartochku-ustrojstv-vvoda/zapros.md)
- [prototip fizicheskikh sostoyanij klavish](../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3a373f2b6989dc224dc58facfc144e71aa37749cdfdfd546ce0e6cefbb16f044 -->
<!-- FUM-MD-RECENCY:END -->
