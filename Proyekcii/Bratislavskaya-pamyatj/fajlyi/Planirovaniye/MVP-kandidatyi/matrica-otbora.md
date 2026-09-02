# Matrica otbora MVP-kandidatov

## Legenda

Ocenki kachestvennyiye i nuzhnyi dlya sravneniya, a ne dlya vyichisleniya okonchateljnogo resheniya.

- Proveryayemostj: 5 oznachayet, chto rezuljtat lyogko proveritj lokaljno.
- Blizostj k tekusjhej pamyati: 5 oznachayet, chto boljshaya chastj istochnikov, pravil i praktik uzhe yestj v repozitorii.
- Demonstriruyemostj: 5 oznachayet, chto cennostj mozhno byistro pokazatj poljzovatelyu ili vneshnemu nablyudatelyu.
- Risk avtonomii: 5 oznachayet vyisokij risk prezhdevremennogo rasshireniya dejstvij, dostupa ili obesjhanij.
- Slozhnostj: 5 oznachayet vyisokuyu inzhenernuyu i produktovuyu slozhnostj pervogo varianta.

Matrica ocenivayet ne napravleniya sami po sebe, a produktovyiye idei, gotovyiye k ogranichennomu zapusku. Napravleniye proyektirovaniya mozhet obyyasnyatj proiskhozhdeniye kandidata, no rabochij vyivod dolzhen otvechatj na vopros: chto imenno zapuskayetsya, na kakoj [stadii](../stadii/README.md) eto imeyet smyisl i kakoj poljzovateljskij rezuljtat poyavlyayetsya pervyim.

## Sravneniye

| Kandidat                                                                                      | Produktovaya ideya                    | Proveryayemostj | Blizostj k tekusjhej pamyati | Demonstriruyemostj | Risk avtonomii | Slozhnostj | Rabochij vyivod                                                                                                                               |
| --------------------------------------------------------------------------------------------- | ----------------------------------- | ------------- | ------------------------- | ----------------- | -------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [Pamyatj rabochej sessii](01-pamyatj-rabochej-sessii/README.md)                                   | Pomosjhnik rabochej sessii FUM         | 5             | 5                         | 3                 | 1              | 2         | Blizhajshij vnutrennij zapusk: produkt uzhe vruchnuyu ispoljzuyetsya v kazhdoj sessii i mozhet byistro statj lokaljnyim masterom oformleniya rezuljtata |
| [Arkhivirovaniye prikreplyayemyikh materialov](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) | Arkhivator istochnikov FUM            | 4             | 4                         | 4                 | 2              | 3         | Yedinstvennyij aktivnyij produktovyij zapusk; URL-pasport proveren, no produktovaya realizaciya otdeljno ne razreshena, ne vyipolnena i ne prinyata  |
| [Glossarno-dokumentacionnyij kontur](03-glossarno-dokumentacionnyij-kontur/README.md)           | Redaktor svyaznoj dokumentacii FUM   | 5             | 5                         | 3                 | 1              | 2         | Khoroshij produkt dlya avtorov pamyati: deshyovyij lokaljnyij kontrolj kachestva terminov i ssyilok pered kommitom                                    |
| [Ispolnyayemyij agentskij cikl](04-ispolnyayemyij-agentskij-cikl/README.md)                         | Trassirovsjhik agentskogo progona FUM | 3             | 4                         | 4                 | 3              | 4         | Bezokonnyij Swift-replay uzhe proveryayet perekhodyi pamyati, no ne dokazyivayet agentskij runtime, modeljnyij shag i bezopasnoye perenapravleniye       |
| [Adresnyiye opisaniya i pasporta auditorij](05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md) | Generator adresnyikh opisanij FUM     | 4             | 4                         | 5                 | 2              | 3         | Samyij ponyatnyij vneshnij demonstrator, yesli pervyij reliz strogo ogranichitj istochnikami i statusom proyekta                                     |
| [Yedinaya tochka lokaljnoj rabotyi](06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)                   | Puljt lokaljnoj pamyati FUM          | 3             | 3                         | 5                 | 4              | 5         | Konechnyij GUI dolzhen byitj proyekciyej vnutrennikh pamyati i ispolneniya; yego zapusk ostayotsya posle dokazateljstv boleye uzkikh bezokonnyikh sloyov     |

## Predvariteljnyij poryadok eksperimentov po stadiyam

[Arkhivirovaniye prikreplyayemyikh materialov](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) vyibrano aktivnyim eksperimentom [iskhodnyim zaprosom 2026-06-24 14:33:08 MSK](../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md), perepodtverzhdeno [rabochej sessiyej 2026-07-21 10:06:41 MSK](../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md) kak yedinstvennyij aktivnyij MVP i proshlo priyomku pervogo reliza [2026-07-21 10:36:18 MSK](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md). Posle [utochneniya 2026-06-25 18:30:09 MSK](../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md) i stadijnogo utochneniya [2026-07-01 15:08:04 MSK](../../Zhurnal/2026-07-01_15-08-04_MSK/zapros.md) etot poryadok chitayetsya kak ocheredj zapuska produktovyikh idej po stadiyam, a ne kak spisok napravlenij.

[Bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) ne dobavlyayet sedjmuyu produktovuyu stroku i ne menyayet ocenki kandidatov. Eto obsjhij inzhenernyij srez mezhdu kandidatami 04 i 06: snachala on proveryayet vnutrennyuyu pamyatj i ogranichennoye ispolneniye, zatem dolzhen poluchitj vosstanavlivayemyiye pokoleniya i deklarativnuyu modelj predstavleniya, i toljko posle etogo mozhet statj osnovaniyem zhiznesposobnogo GUI.

| Stadiya                                                                            | Poryadok | Eksperiment                                                                            | Smyisl zapuska                                                                                                    |
| --------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| [Dokumentacionnyij prototip](../stadii/01-dokumentacionnyij-prototip-FUM/README.md) | 1       | [Arkhivator istochnikov FUM](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)        | Datj pervomu poljzovatelyu komandu ili scenarij, kotoryij prevrasjhayet vneshnij material v lokaljnyij istochnik pamyati. |
| [Dokumentacionnyij prototip](../stadii/01-dokumentacionnyij-prototip-FUM/README.md) | 2       | [Pomosjhnik rabochej sessii FUM](01-pamyatj-rabochej-sessii/README.md)                      | Datj uchastniku proyekta master zaversheniya sessii s zaprosom, zhurnalom, proverkoj i sostavom kommita.              |
| [Dokumentacionnyij prototip](../stadii/01-dokumentacionnyij-prototip-FUM/README.md) | 3       | [Redaktor svyaznoj dokumentacii FUM](03-glossarno-dokumentacionnyij-kontur/README.md)    | Datj avtoru pamyati predkommitnyij otchyot po terminam, ssyilkam i novyim ponyatiyam.                                    |
| [Dokumentacionnyij prototip](../stadii/01-dokumentacionnyij-prototip-FUM/README.md) | 4       | [Generator adresnyikh opisanij FUM](05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md) | Datj vneshnemu adresatu chestno sobrannuyu versiyu opisaniya FUM s istochnikami i ogranicheniyami.                       |
| Perekhod k korobochnoj realizacii                                                   | 5       | [Trassirovsjhik agentskogo progona FUM](04-ispolnyayemyij-agentskij-cikl/README.md)         | Dovesti bezokonnyij replay pamyati do vosstanavlivayemogo sostoyaniya i nablyudayemoj trassyi sobstvennogo runtime.      |
| [Korobochnaya realizaciya FUM](../stadii/02-korobochnaya-realizaciya-FUM/README.md)     | 6       | [Yedinoye prilozheniye lokaljnoj pamyati FUM](06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)   | Podklyuchitj GUI k vyivedennoj iz pamyati modeli predstavleniya i vernutj dejstviye v tot zhe sobyitijnyij kontur.        |

Poryadok `1–6` pokazyivayet stadijnoye sozrevaniye produktovyikh kandidatov, a ne tekusjhuyu operativnuyu ocheredj. Aktivnyim produktovyim MVP ostayotsya toljko arkhivator istochnikov. [Tekusjhij zapros](../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) razreshil inzhenernuyu posledovateljnostj bezokonnyikh Swift-srezov, no ne vyibral novyij MVP i ne razreshil produktovuyu realizaciyu URL-servisa. Zamechaniya [audita produktovogo pasporta](../../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md) zakryityi povtornoj proverkoj, no [FUM-STEP-0105](../kartochki-shagov/🟡-FUM-STEP-0105-realizovatj-avtonomnoye-yadro-pervogo-produktovogo-URL-sreza.md) ostayotsya zablokirovannoj do otdeljnogo yavnogo razresheniya. Ostaljnyiye stroki tablicyi ne poluchayut aktivnogo produktovogo statusa iz-za svoyej pozicii ili nalichiya obsjhego tekhnicheskogo predshestvennika.

Etot poryadok ne yavlyayetsya okonchateljnyim obyazateljstvom. On fiksiruyet tekusjhuyu inzhenernuyu intuiciyu: snachala avtomatizirovatj to, chto FUM uzhe delayet v sobstvennoj pamyati, zatem rasshiryatj avtonomiyu.

Matrica dolzhna ispoljzovatjsya ne toljko dlya vyibora odnogo MVP-kandidata, no i dlya poshagovogo otbora uzhe opisannyikh vozmozhnostej vnutri kazhdogo sleduyusjhego inkrementa. Posle kazhdoj susjhestvennoj proverki mozhno yavno menyatj status variantov: blizhajshij shag, sleduyusjhij shag, otlozhennyij kandidat ili snyatyij variant. Snyatiye ne oznachayet udaleniya iz pamyati; ono fiksiruyet, chto tekusjhaya cena, risk, slabaya proveryayemostj ili zavisimostj ot nezrelogo sloya ne pozvolyayut realizovyivatj etot variant sejchas.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-21 15:51:32 MSK - Podgotovitj pasport pervogo korobochnogo sreza FUM](../../Zhurnal/2026-07-21_15-51-32_MSK_podgotovitj-pasport-pervogo-korobochnogo-sreza-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:33:08 MSK](../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-01 15:08:04 MSK](../../Zhurnal/2026-07-01_15-08-04_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK - Zafiksirovatj poshagovyij otbor realizacii](../../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii](../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:dc806160713a68ac9e19dbf567294111b0ea124fdff1515baade77e0e575dd6c -->
<!-- FUM-MD-RECENCY:END -->
