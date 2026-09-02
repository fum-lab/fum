# MVP-kandidat: arkhivirovaniye prikreplyayemyikh materialov

## Pasport

- Status: podtverzhdyon kak yedinstvennyij aktivnyij [MVP-kandidat](../../../Glossarij/MVP-kandidat.md); pervyij reliz prinyat avtonomnyim skvoznyim scenariyem obsjhego arkhivatora.
- Gorizontyi dorozhnoj kartyi: [svyaznaya pamyatj proyekta](../../dorozhnaya-karta.md) i [vosproizvodimyiye avtomatizacii](../../dorozhnaya-karta.md).
- Poljzovatelj: agent ili chelovek, kotoryij prinosit vo FUM vneshnij material: URL, rassharennyij chat, dokument ili vlozheniye.
- Minimaljnyij rezuljtat: lokaljnaya avtomatizaciya, kotoraya sokhranyayet material v `Источники/`, izvlekayet publikacionno chistyij tekst, pishet otchyot ob izvlechenii i svyazyivayet istochnik s fajlom zaprosa.

## Produktovaya ideya dlya zapuska

Produkt: **Arkhivator istochnikov FUM** - lokaljnyij instrument, kotoryij prevrasjhayet vneshnij material v proveryayemyij istochnik pamyati.

Pervyij poljzovatelj - uchastnik proyekta, kotoryij prinosit v sessiyu ustojchivyij URL, rassharennyij dialog ili dokument i khochet, chtobyi material ne ostalsya toljko ssyilkoj v chate.

Pervyij scenarij zapuska: poljzovatelj ukazyivayet URL i fajl zaprosa. Arkhivator vyichislyayet kanonicheskuyu papku v `Источники/`, sokhranyayet publikacionno chistyij snimok istochnika, izvlekayet chitayemyij tekst i mashinnyiye sloi, sozdayot `source-index.md` i otchyot ob izvlechenii, a zatem dobavlyayet ssyilki na istochnik v fajl zaprosa.

Sostav pervogo reliza:

- komanda ili scenarij `fum source archive <url> --request <file>`;
- podderzhka ChatGPT share i prostoj HTML/tekstovoj fiksturyi bez setevoj zavisimosti v testakh;
- kanonicheskaya struktura `Источники/URL/<scheme>/<host>/<path...>/`;
- otchyot o sokhranyonnyikh fajlakh, ogranicheniyakh izvlecheniya i redaktirovanii sekretopodobnyikh fragmentov;
- tochnyij manifest upravlyayemyikh fajlov i atomarnaya ustanovka polnostjyu sobrannogo snimka bez smesheniya s prezhnim rezuljtatom;
- idempotentnoye povtornoye svyazyivaniye togo zhe istochnika s tem zhe zaprosom.

Kriterij gotovnosti k zapusku: poljzovatelj mozhet datj odin ustojchivyij URL i poluchitj papku istochnika, indeks, izvlechyonnyij tekst, otchyot i ssyilku iz fajla zaprosa, a povtornyij zapusk ne sozdayot dublikatov, ne raskryivayet sekretyi v imenakh fajlov i ne sokhranyayet otsutstvuyusjhiye v novom manifeste fajlyi prezhnego snimka.

## Resheniye o zapuske

[Iskhodnyij zapros 2026-06-24 14:33:08 MSK](../../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md) perevodit etot kandidat iz sravniteljnogo spiska v aktivnuyu rabotu. Blizhajshij smyisl MVP - ne podderzhatj vse vozmozhnyiye formatyi vlozhenij, a zakrepitj proveryayemyij vkhodnoj kontur [pamyati FUM](../../../Glossarij/pamyatj-FUM.md): vneshnij material dolzhen poluchitj lokaljnuyu papku proiskhozhdeniya, indeks istochnika, otchyot ob izvlechenii i ssyilku iz fajla [iskhodnogo zaprosa](../../../Glossarij/iskhodnyij-zapros.md).

Pervyij rabochij inkrement vyipolnyayetsya cherez susjhestvuyusjhuyu [avtomatizaciyu FUM](../../../Glossarij/avtomatizaciya-FUM.md) `Инструменты/fum-materialyi-zaprosov/` i yeyo lokaljnyiye testyi. Podderzhka novyikh tipov materialov dolzhna dobavlyatjsya toljko posle fiksacii ozhidayemogo povedeniya v testakh ili proverkakh bez setevoj zavisimosti po umolchaniyu.

Rabochaya sessiya [2026-07-21 10:06:41 MSK](../../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md) perepodtverdila vyibor, a [skvoznaya priyomka 2026-07-21 10:36:18 MSK](../../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md) zakryila ostavshijsya razryiv pervogo reliza. Arkhivator ostayotsya yedinstvennyim aktivnyim MVP: obsjhij vkhod, avtonomnaya HTML/tekstovaya fikstura, atomarnyij povtor i pozdnij otkaz teperj proverenyi odnim poljzovateljskim scenariyem bez seti i sekretov.

## Yedinstvennyij skvoznoj scenarij priyomki pervogo reliza

Scenarij nazyivayetsya «obyichnyij HTML-URL prevrasjhayetsya v kanonicheskij istochnik i idempotentno perearkhiviruyetsya». Kontrakt projden cherez obsjhij vkhod `fum source archive` na avtonomnoj HTML/tekstovoj fiksture; rezuljtat prinyat kak pervyij reliz arkhivatora istochnikov.

1. **Vkhod.** Avtonomnaya fikstura `Инструменты/fum-materialyi-zaprosov/tests/fixtures/simple-html/` zadayot URL `https://fixture.invalid/articles/fum`, versii otveta `v1` i `v2`, ustojchivyiye zagolovki, HTML-telo i testovyij `Set-Cookie`, kotoryij obyazan byitj otredaktirovan. Versiya `v1` soderzhit izvlekayemyij strukturnyij blok, sozdayusjhij upravlyayemyij `structured-data.json`, a v `v2` takogo bloka net. Test sozdayot vremennyij fajl iskhodnogo zaprosa; setj, sekretyi i vneshniye servisyi ne ispoljzuyutsya.
2. **Tochka zapuska.** Test kak podprocess vyizyivayet tot zhe poljzovateljskij vkhod `fum source archive https://fixture.invalid/articles/fum --request <временный-файл-запроса>`. Fiksturnyij transport podstavlyayetsya pod obsjhim vkhodom i ne obkhodit orkestraciyu arkhivatora otdeljnyim testovyim scenariyem.
3. **Ozhidayemyiye artefaktyi pervogo zapuska.** V `Источники/URL/https/fixture.invalid/articles/fum/` poyavlyayutsya `source-url.txt`, ochisjhennyiye `response.headers.txt` i `response.body.html`, `extracted-text.md`, `structured-data.json`, `source-index.md`, `extraction-report.md` i tochnyij `snapshot-manifest.json`. Fakticheskij nabor upravlyayemyikh fajlov raven manifestu, testovyij cookie otsutstvuyet vo vsekh publikuyemyikh fajlakh, a vremennyij zapros soderzhit rovno odin nabor ssyilok na papku, indeks i otchyot.
4. **Povtornyij zapusk.** Tot zhe vkhod zapuskayetsya dlya togo zhe URL i zaprosa s versiyej `v2`. Kanonicheskij putj ne menyayetsya, kopiya istochnika i vtoroj nabor ssyilok ne sozdayutsya, soderzhimoye obnovlyayetsya atomarno, a otsutstvuyusjhij v novom manifeste `structured-data.json` ischezayet iz rezuljtata. Sboj do ustanovki novogo snimka ostavlyayet predyidusjhij kanonicheskij snimok pobajtno neizmennyim.
5. **Usloviye priyomki.** Odin avtonomnyij integracionnyij test prokhodit vesj putj cherez obsjhij CLI, proveryayet obe versii fiksturyi, publikacionnuyu ochistku, tochnostj manifesta, otsutstviye dublej i sokhrannostj prezhnego snimka pri pozdnem sboye. Uspeshnyij progon zafiksirovan [rabochej sessiyej priyomki](../../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/otchyot.md), poetomu pervyij reliz nakhoditsya v sostoyanii prinyatogo.

## Pochemu eto mozhet byitj pervyim MVP

FUM ne mozhet byitj nadyozhnoj pamyatjyu, yesli vneshniye materialyi ostayutsya toljko ssyilkami v dialoge. Etot kandidat prevrasjhayet vneshnij material v lokaljnyij proveryayemyij sloj: sokhranyayetsya proiskhozhdeniye, izvlechyonnyij tekst, tekhnicheskij otchyot, ogranicheniya i svyazj s zaprosom.

U proyekta uzhe yestj zagotovka instrumenta `Инструменты/fum-materialyi-zaprosov/`, poetomu pervyij variant mozhno stroitj ne s nulya, a kak razvitiye susjhestvuyusjhego lokaljnogo navyika i skriptov.

## Proveryayemyij MVP

Minimaljnyij variant dolzhen umetj:

- prinyatj ustojchivyij URL i vyichislitj kanonicheskuyu papku v `Источники/URL/`;
- sokhranitj iskhodnyij URL, zagolovki bez sekretov, telo otveta ili dostupnyij snimok;
- izvlechj chelovekochitayemyij tekst i mashinnyiye potoki, yesli oni dostupnyi;
- sozdatj `source-index.md` ili otchyot ob izvlechenii s perechnem sokhranyonnyikh fajlov;
- dobavitj v fajl zaprosa ssyilki na papku istochnika i klyuchevyiye izvlechyonnyiye materialyi;
- zapuskatjsya na lokaljnyikh fiksturakh bez setevoj zavisimosti.

## Kriterii priyomki

- Povtornyij zapusk dlya togo zhe URL ne sozdayot bessmyislennuyu kopiyu istochnika.
- Do polnoj proverki staging prezhnij kanonicheskij snimok ostayotsya neizmennyim.
- Uspeshnyij povtor soderzhit rovno fajlyi novogo `snapshot-manifest.json`; prezhniye uslovnyiye strukturnyiye fajlyi ne perenosyatsya v novyij rezuljtat.
- Pri nedostupnoj atomarnoj zamene povtor zakryivayetsya bez izmeneniya kanonicheskogo snimka.
- Query i fragment ne raskryivayut vozmozhnyiye sekretyi v imeni papki.
- Proverka podtverzhdayet, chto cookie, tokenyi, lokaljnyiye IP i drugiye sekretyi ne popali v publikuyemyiye fajlyi.
- Dlya ChatGPT share ispoljzuyetsya zakreplyonnyij skript `archive-chatgpt-share.py` ili sovmestimyij lokaljnyij sloj.
- V sluchaye nevozmozhnosti polnogo izvlecheniya sozdayotsya otchyot o granice vosproizvodimosti, a ne molchalivyij uspekh.

## Ne vkhodit v pervyij variant

- Obkhod paywall, privatnyikh avtorizacij ili zakryityikh vlozhenij bez yavnogo razresheniya.
- Dolgovremennoye khraneniye sekretov, cookie, tokenov i personaljnyikh dannyikh.
- Polnocennaya sistema citirovaniya ili nauchnogo reference management.

## Zavisimosti

- `Инструменты/fum-materialyi-zaprosov/`.
- Pravila publikacionnoj chistotyi iz [AGENTS.md](../../../AGENTS.md).
- Struktura `Источники/` i svyazj istochnikov s [iskhodnyimi zaprosami](../../../Glossarij/iskhodnyij-zapros.md).

## Riski

- Vneshniye sajtyi i formatyi mogut menyatjsya, poetomu avtomatizaciya dolzhna imetj fiksturyi i chestnyiye otchyotyi o sboyakh.
- Chem shire podderzhka materialov, tem vyishe risk sluchajno sokhranitj privatnoye ili nepublikuyemoye soderzhimoye.
- Nuzhno otdelyatj sokhraneniye syirogo istochnika ot proizvodnogo vyivoda, chtobyi istochnik ne prevrasjhalsya v nepodtverzhdyonnuyu interpretaciyu.

## Pervyij eksperiment

Pervyij eksperiment zavershyon: avtonomnaya URL-fikstura proveryayet kanonicheskuyu papku istochnika, otchyot ob izvlechenii, publikacionnuyu ochistku, tochnyij manifest, ssyilku iz fajla zaprosa, uspeshnyij povtor i pozdnij otkaz.

## Khod pervogo inkrementa

V rabochej sessii [2026-06-24 14:33:08 MSK](../../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md) pervyij eksperiment nachat s TDD-kontrakta dlya `archive-chatgpt-share.py`:

- `source-index.md` dolzhen davatj chelovekochitayemyij vkhod v sokhranyonnyij istochnik i ssyilatjsya na oformlennyij dialog, otchyot ob izvlechenii i strukturnyij sloj soobsjhenij;
- fajl [iskhodnogo zaprosa](../../../Glossarij/iskhodnyij-zapros.md), peredannyij cherez `--request-file`, dolzhen poluchatj razdel `## Прикрепляемые материалы` so ssyilkami na papku istochnika, indeks i otchyot;
- povtornoye svyazyivaniye togo zhe istochnika s tem zhe zaprosom ne dolzhno sozdavatj dubliruyusjhiyesya ssyilki.

Rabochaya sessiya [2026-07-20 22:05:19 MSK](../../../Zhurnal/2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md) zakrepila celostnostj povtornogo snimka:

- polnyij rezuljtat i vse uslovnyiye strukturnyiye fajlyi snachala sobirayutsya v sosednem staging-kataloge;
- `snapshot-manifest.json` perechislyayet tochnyij ustanovlennyij nabor upravlyayemyikh fajlov;
- posledovateljnosti `полный снимок -> неполный снимок` i `полный снимок -> неуспешный повтор` proveryayutsya avtonomno bez seti i sekretov;
- povtor susjhestvuyusjhego snimka ispoljzuyet atomarnyij obmen katalogov libo zakryivayetsya bez izmeneniya kanonicheskogo rezuljtata.

Pervyij reliz prinyat bez rasshireniya na novyiye formatyi, a vkhodnyiye opisaniya FUM posle priyomki polnostjyu aktualizirovanyi. [Pasport pervogo korobochnogo sreza](../../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) otdelyayet etot lokaljnyij CLI-kontur ot poka ne realizovannogo servisa istochnikov; arkhivator ostayotsya yedinstvennyim aktivnyim produktovyim MVP. Dorabotka `FUM-STEP-0035` zakryila zamechaniya pasportnogo audita i povtornuyu proverku, no ne nachala produktovuyu realizaciyu. [FUM-STEP-0105](../../kartochki-shagov/🟡-FUM-STEP-0105-realizovatj-avtonomnoye-yadro-pervogo-produktovogo-URL-sreza.md) sokhranyayet yeyo avtonomnoye yadro otdeljnyim zablokirovannyim prodolzheniyem. [Iskhodnyij zapros o bezokonnom Swift-prototipe](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md) razreshayet toljko ogranichennyij inzhenernyij putj: on ne razreshayet etu produktovuyu realizaciyu, ne dayot yej zhivuyu setj i ne podmenyayet otdeljnuyu priyomku.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../../../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-21 15:51:32 MSK - Podgotovitj pasport pervogo korobochnogo sreza FUM](../../../Zhurnal/2026-07-21_15-51-32_MSK_podgotovitj-pasport-pervogo-korobochnogo-sreza-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-22 03:38:35 MSK - Razreshitj vyipolneniye dostupnyikh kartochek shagov](../../../Zhurnal/2026-07-22_03-38-35_MSK_razreshitj-vyipolneniye-dostupnyikh-kartochek-shagov/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:08:09 MSK](../../../Zhurnal/2026-06-24_14-08-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-24 14:33:08 MSK](../../../Zhurnal/2026-06-24_14-33-08_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](../../../Zhurnal/2026-06-25_18-30-09_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-20 22:05:19 MSK - Sdelatj povtornoye arkhivirovaniye istochnika atomarnyim](../../../Zhurnal/2026-07-20_22-05-19_MSK_sdelatj-povtornoye-arkhivirovaniye-istochnika-atomarnyim/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:06:41 MSK - Perepodtverditj MVP i kriterij vyikhoda dokumentacionnoj stadii](../../../Zhurnal/2026-07-21_10-06-41_MSK_perepodtverditj-MVP-i-kriterij-vyikhoda-dokumentacionnoj-stadii/zapros.md)
- [iskhodnyij zapros 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov](../../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)

## Opornyiye materialyi

- [Vosproizvodimyiye avtomatizacii FUM](../../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [Instrument rabotyi s prikreplyayemyimi materialami](../../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)
- [Modelj pamyati FUM](../../../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Prikreplyayemyij material](../../../Glossarij/prikreplyayemyij-material.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:de5af7c58694e1f853f12c3205a067bcd158b25e5eb775bc49b34afc4d2395db -->
<!-- FUM-MD-RECENCY:END -->
