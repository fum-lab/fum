# MVP-kandidatyi FUM

## Naznacheniye

Etot katalog khranit [MVP-kandidatyi](../../Glossarij/MVP-kandidat.md) - konkretnyiye idei pervogo minimaljnogo produkta [FUM](../../Glossarij/FUM.md), kotoryiye mozhno podgotovitj k zapusku ranjshe, chem poyavitsya polnyij agent sleduyusjhego pokoleniya. Kandidat mozhet opiratjsya na rabochij sloj, avtomatizaciyu ili demonstracionnyij kontur, no v etom kataloge on dolzhen chitatjsya prezhde vsego kak produktovaya ideya: komu ona nuzhna, chto poljzovatelj zapuskayet, kakoj rezuljtat poluchayet i po kakim priznakam pervyij reliz mozhno schitatj gotovyim.

[MVP-kandidat](../../Glossarij/MVP-kandidat.md) ne yavlyayetsya obesjhaniyem realizacii i ne zamenyayet [proizvodnuyu dokumentaciyu](../../Glossarij/proizvodnaya-dokumentaciya.md). Eto planovaya ramka vyibora i zapuska: yesli kandidat budet vyibran dlya razrabotki, yego trebovaniya dolzhnyi byitj dopolniteljno zafiksirovanyi cherez [iskhodnyiye zaprosyi](../../Glossarij/iskhodnyij-zapros.md), dokumentaciyu, proverki i kommityi.

Kandidatyi nuzhno chitatj ne kak ploskij spisok konkuriruyusjhikh produktov, a kak [stadijnuyu](../stadii/README.md) kartu sozrevaniya [FUM](../../Glossarij/FUM.md). Odin i tot zhe kandidat mozhet imetj blizhnyuyu formu na stadii [dokumentacionnogo prototipa](../stadii/01-dokumentacionnyij-prototip-FUM/README.md), perekhodnyij proveryayemyij rezuljtat i budusjhuyu formu v [korobochnoj realizacii FUM](../stadii/02-korobochnaya-realizaciya-FUM/README.md).

Vyibor mezhdu kandidatami proiskhodit ne toljko odin raz v moment naznacheniya aktivnogo MVP. Na kazhdom sleduyusjhem inkremente nuzhno otbiratj, kakaya uzhe opisannaya chastj dayot blizhajshuyu proveryayemuyu poljzu, kakaya stanovitsya sleduyusjhej, kakaya ostayotsya v zapase, a kakaya snimayetsya iz tekusjhego puti realizacii iz-za cenyi, riska, slaboj svyazi s pamyatjyu ili prezhdevremennoj avtonomii.

Inzhenernyij prototip mozhet proveryatj obsjhij vnutrennij sloj srazu dlya neskoljkikh kandidatov i pri etom ne stanovitjsya novyim produktovyim MVP. [Bezokonnyij Swift-kontur vosproizvodimogo popolneniya pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md) imenno tak gotovit pamyatj, ispolneniye i budusjhuyu GUI-proyekciyu: on uzhe dejstvuyet kak malyij tekhnicheskij bootstrap, no yesjhyo ne yavlyayetsya ni ispolnyayemyim agentskim ciklom, ni yedinyim prilozheniyem.

## Produktovaya ramka

Chtobyi kandidat ne raspadalsya na abstraktnoye napravleniye, kazhdaya kartochka dolzhna yavno otvechatj na voprosyi zapuska:

- kak nazyivayetsya produktovaya ideya i kak yeyo mozhno obyyasnitj odnim predlozheniyem;
- kto pervyij poljzovatelj i v kakoj situacii on prikhodit k produktu;
- kakoj interfejs ili komanda yavlyayetsya pervyim sposobom zapuska;
- kakoj rezuljtat poljzovatelj poluchayet v konce pervogo scenariya;
- chto vkhodit v pervyij reliz, a chto ostayotsya za yego predelami;
- kakoj proveryayemyij kriterij pokazyivayet, chto ideyu uzhe mozhno zapuskatj v ogranichennom konture.

## Obsjhaya ramka MVP

Minimaljnyij produkt dlya FUM dolzhen sokhranyatj glavnuyu arkhitekturnuyu stavku proyekta: ne odnorazovyij otvet modeli, a svyaznyij cikl pamyati, dejstviya, proverki i nasledovaniya rezuljtata. Poetomu kazhdyij kandidat ocenivayetsya po shesti voprosam:

- kakuyu realjnuyu bolj ili rabotu on sokrasjhayet;
- kakiye fajlyi, komandyi, proverki ili artefaktyi on sozdayot;
- kak poljzovatelj ili drugoj uzel ponimayet, chto rezuljtat srabotal;
- naskoljko kandidat opirayetsya na uzhe susjhestvuyusjhuyu [pamyatj FUM](../../Glossarij/pamyatj-FUM.md);
- gde prokhodyat granicyi avtonomii, dostupa i publikacionnoj chistotyi;
- kakoj pervyij eksperiment mozhno vyipolnitj bez vneshnikh sekretov i setevoj zavisimosti.

## Kandidatyi

| Kandidat                                                                                          | Zapuskayemaya produktovaya ideya                                                                                            | Pervyij poljzovateljskij rezuljtat                                                                                             |
| ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [01. Pamyatj rabochej sessii](01-pamyatj-rabochej-sessii/README.md)                                   | Pomosjhnik rabochej sessii FUM: lokaljnyij master oformleniya zaprosa, zhurnala, proverok i kommita                           | Zavershyonnaya rabochaya sessiya s fajlom zaprosa, zhurnalom, navigaciyej, spiskom izmenyonnyikh fajlov i projdennoj proverkoj svyaznosti |
| [02. Arkhivirovaniye prikreplyayemyikh materialov](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) | Arkhivator istochnikov FUM: lokaljnyij instrument prevrasjheniya URL, rassharennogo chata ili vlozheniya v istochnik pamyati        | Papka istochnika v `Источники/`, izvlechyonnyij tekst, otchyot ob izvlechenii i ssyilki iz fajla zaprosa                              |
| [03. Glossarno-dokumentacionnyij kontur](03-glossarno-dokumentacionnyij-kontur/README.md)           | Redaktor svyaznoj dokumentacii FUM: proverka terminov, ssyilok i novyikh ponyatij pered kommitom                             | Otchyot s propusjhennyimi ssyilkami na glossarij, kandidatami v novyiye terminyi i oshibkami strukturyi                                  |
| [04. Ispolnyayemyij agentskij cikl](04-ispolnyayemyij-agentskij-cikl/README.md)                         | Trassirovsjhik agentskogo progona FUM: lokaljnyij zapusk odnoj ogranichennoj zadachi s nablyudayemoj trassoj                   | Strukturirovannaya trassa cikla; bezokonnyij Swift-prototip poka dokazyivayet toljko vosproizvodimyiye perekhodyi pamyati              |
| [05. Adresnyiye opisaniya i pasporta auditorij](05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md) | Generator adresnyikh opisanij FUM: vosproizvodimaya sborka versii proyekta dlya vyibrannoj auditorii                          | Polnostjyu peresobrannoye opisaniye s pasportom auditorii, istochnikami, ogranicheniyami i proverennyimi ssyilkami                    |
| [06. Yedinaya tochka lokaljnoj rabotyi](06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)                   | Yedinoye prilozheniye lokaljnoj pamyati FUM: GUI kak proyekciya vnutrennikh pamyati i ispolneniya, a ne otdeljnyij istochnik istinyi | Vyipolnennoye lokaljnoye dejstviye, proshedsheye iz GUI cherez versionirovannoye sobyitiye k proveryayemomu izmeneniyu pamyati               |

## Stadijnaya karta kandidatov

Eta karta pokazyivayet, kak kandidatyi raskladyivayutsya po stadiyam. Tekusjhaya stadiya otvechayet na vopros, chto mozhno sdelatj v repozitorii uzhe sejchas; perekhodnyij rezuljtat pokazyivayet proveryayemyij kontrakt mezhdu stadiyami; korobochnaya forma pokazyivayet, chem kandidat dolzhen statj v budusjhej postavke FUM.

| MVP-kandidat                                                                                      | Forma na stadii dokumentacionnogo prototipa                                                                        | Perekhodnyij rezuljtat                                                                                                  | Forma v korobochnoj realizacii FUM                                                                                      |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [01. Pamyatj rabochej sessii](01-pamyatj-rabochej-sessii/README.md)                                   | Lokaljnyij master oformleniya zaprosa, zhurnala, izmenyonnyikh fajlov, proverok i kommita.                               | Pasport rabochej sessii i format nablyudayemoj trassyi rezuljtata.                                                        | Vstroyennyij kontur proiskhozhdeniya rezuljtata: vkhod, dejstviye, proverka, zhurnal, versiya i peredacha v pamyatj.              |
| [02. Arkhivirovaniye prikreplyayemyikh materialov](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) | Prinyataya lokaljnaya avtomatizaciya obsjhego URL-vkhoda s sovmestimyim specializirovannyim konturom i avtonomnoj priyomkoj. | Kontrakt istochnika: kanonicheskaya papka, `source-index.md`, izvlechyonnyij tekst, otchyot i ssyilka iz zaprosa.              | Servis priyoma istochnikov s konnektorami, publikacionnoj ochistkoj, API proiskhozhdeniya i povtoryayemyim izvlecheniyem.         |
| [03. Glossarno-dokumentacionnyij kontur](03-glossarno-dokumentacionnyij-kontur/README.md)           | Predkommitnyij otchyot po terminam, ssyilkam, novyim ponyatiyam i strukture glossariya.                                    | Kontrakt kachestva svyaznoj pamyati: kakiye terminyi, ssyilki i novyiye ponyatiya trebuyut resheniya.                              | Redaktor svyaznoj pamyati s podskazkami terminov, statusami dokumentov i vstroyennoj proverkoj publikacionnoj chistotyi.    |
| [04. Ispolnyayemyij agentskij cikl](04-ispolnyayemyij-agentskij-cikl/README.md)                         | Specifikaciya trassyi, fiksturyi i bezokonnyij Swift-replay shtatnyikh perekhodov pamyati bez vneshnikh dejstvij.             | Vosstanavlivayemyiye pokoleniya pamyati i minimaljnyij format scenariya, sostoyaniya, dejstvij, proverok, oshibok i rezuljtata. | Runtime agentskogo cikla s nablyudeniyem, vyiborom dejstviya, podtverzhdeniyami, proverkoj i obnovleniyem pamyati.             |
| [05. Adresnyiye opisaniya i pasporta auditorij](05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md) | Vosproizvodimaya peresborka opisanij iz dokumentacii, glossariya, voprosov i pasporta auditorii.                     | Karta tezisov so statusami, istochnikami, ogranicheniyami i nedopustimyimi obesjhaniyami.                                    | Generator adresnyikh obyyasnenij, kotoryij sobirayet versii iz pamyati i pokazyivayet istochniki, status i granicyi utverzhdenij. |
| [06. Yedinaya tochka lokaljnoj rabotyi](06-yedinaya-tochka-lokaljnoj-rabotyi/README.md)                   | Pasport tekusjhego kontura i diagnostika markerov predposyilok GUI-proyekcii v kanonicheskoj pamyati.                    | Deklarativnaya modelj predstavleniya iz pamyati, obratnoye sobyitiye dejstviya i pasport pervogo yedinogo prilozheniya.         | Pervaya korobochnaya poverkhnostj FUM, chji predstavleniye i dejstviya prokhodyat cherez vnutrenniye pamyatj i ispolneniye.         |

## Tekusjhij vyibor

Status vyibora — `active`. [Arkhivirovaniye prikreplyayemyikh materialov](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md) podtverzhdeno [rabochej sessiyej 2026-07-21 10:06:41 MSK](../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md) kak yedinstvennyij aktivnyij MVP, a [rabochaya sessiya 2026-07-21 10:36:18 MSK](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md) prinyala yego pervyij reliz. Pervichnyij vyibor sdelan [iskhodnyim zaprosom 2026-06-24 14:33:08 MSK](../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md). Ostaljnyiye pyatj kartochek sokhranyayutsya kandidatami bez aktivnogo statusa.

[Iskhodnyij zapros 2026-07-24 10:44:28 MSK](../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) razreshil inzhenernuyu posledovateljnostj ot bezokonnogo Swift-kontura k GUI na osnove vnutrennikh pamyati i ispolneniya, no ne vyibral novyij produktovyij MVP i ne razreshil produktovuyu realizaciyu URL-servisa. Zamechaniya k [produktovomu URL-pasportu](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) zakryityi povtornoj proverkoj, odnako [FUM-STEP-0105](../kartochki-shagov/🟡-FUM-STEP-0105-realizovatj-avtonomnoye-yadro-pervogo-produktovogo-URL-sreza.md) ostayotsya zablokirovannoj i ne prinyatoj. Poetomu arkhivator sokhranyayet yedinstvennyij aktivnyij produktovyij status, a novyij paket ostayotsya obsjhim inzhenernyim predshestvennikom kandidatov 04 i 06.

Pervyij reliz prinyat. Yedinstvennyij skvoznoj scenarij avtonomno provyol obyichnyij HTML-URL cherez obsjhij vkhod `fum source archive`, poluchil kanonicheskuyu papku istochnika, ochisjhennyiye syirjyevyiye sloi, izvlechyonnyij tekst, indeks, otchyot, tochnyij manifest i ssyilki iz fajla zaprosa, a povtor obnovil tot zhe URL bez kopij, dublikatov ssyilok i ustarevshikh upravlyayemyikh fajlov. Polnyij kontrakt i dokazateljstva priyomki zafiksirovanyi v [kartochke aktivnogo MVP](02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md).

## Matrica otbora

- [Matrica otbora MVP-kandidatov](matrica-otbora.md) sravnivayet kandidatov po proveryayemosti, blizosti k tekusjhej pamyati, demonstriruyemosti, risku i slozhnosti.

## Pravila obnovleniya

- Novyiye kandidatyi dobavlyayutsya otdeljnoj podpapkoj s `README.md`, pasportom, kriteriyami priyomki, zavisimostyami, riskami i pervyim eksperimentom.
- Pri dobavlenii ili susjhestvennom izmenenii kandidata nuzhno obnovlyatj yego stroku v stadijnoj karte: tekusjhuyu dokumentaljnuyu formu, perekhodnyij rezuljtat i budusjhuyu korobochnuyu formu.
- Yesli kandidat prevrasjhayetsya v vyibrannyij plan realizacii, yego trebovaniya nuzhno perenesti v sootvetstvuyusjhuyu proizvodnuyu dokumentaciyu ili novyij planovyij material s yavnoj ssyilkoj na iskhodnyij zapros.
- Yesli kandidat zavisit ot nereshyonnogo voprosa, yego fajl dolzhen ssyilatjsya na sootvetstvuyusjhij material v `Вопросы/`.
- Matrica otbora obnovlyayetsya pri dobavlenii, susjhestvennom izmenenii ili snyatii kandidata.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-21 15:51:32 MSK - Podgotovitj pasport pervogo korobochnogo sreza FUM](../../Zhurnal/2026-07-21_15-51-32_MSK_podgotovitj-pasport-pervogo-korobochnogo-sreza-FUM/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:33:08 MSK](../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-29 12:44:23 MSK](../../Zhurnal/2026-06-29_12-44-23_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-01 15:08:04 MSK](../../Zhurnal/2026-07-01_15-08-04_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK - Zafiksirovatj poshagovyij otbor realizacii](../../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii](../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)

## Opornyiye materialyi

- [Dorozhnaya karta FUM](../dorozhnaya-karta.md)
- [Modelj pamyati FUM](../../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Obzor aktualjnyikh realizacij agentskikh ciklov](../../Dokumentaciya/06-obzor-agentskikh-ciklov.md)
- [Vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Git-infrastruktura evolyucionnyikh cepochek FUM](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md)
- [Pasport nachaljnogo korobochnogo prototipa FUM](../../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2a9779f32141e5100457d75c2fd09efd242198a4696ec70fa5cda43fb4f66358 -->
<!-- FUM-MD-RECENCY:END -->
