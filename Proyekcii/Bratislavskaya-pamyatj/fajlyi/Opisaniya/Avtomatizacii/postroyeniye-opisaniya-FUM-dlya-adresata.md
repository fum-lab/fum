# postroyeniye opisaniya FUM dlya adresata

Kanonicheskoye russkoye imya etoj deklarativnoj avtomatizacii — `построение описания FUM для адресата`, a otobrazhayemaya latinskaya forma `postroyeniye opisaniya FUM dlya adresata` poluchena zhivyim LinguisticKit. Avtomatizaciya zadayot fail-closed kontrakt polnoj sborki adresnogo opisaniya iz yavno perechislennyikh fajlov [pamyati FUM](../../Glossarij/pamyatj-FUM.md). Gotovoye opisaniye yavlyayetsya proizvodnoj proyekciyej istochnikov, a ne samostoyateljnyim istochnikom trebovanij.

## Naznacheniye

Eta [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) zadayot vosproizvodimuyu skhemu, po kotoroj mozhno postroitj s nulya ili obnovitj adresnoye opisaniye [FUM](../../Glossarij/FUM.md) na osnove [pamyati FUM](../../Glossarij/pamyatj-FUM.md).

Avtomatizaciya opisana deklarativno. Yeyo mozhno vyipolnyatj vruchnuyu agentom ili pozdneye perenesti v programmnyij workflow bez izmeneniya smyisla.

Obnovleniye gotovogo opisaniya schitayetsya korrektnyim toljko togda, kogda rabochaya sessiya yavno vyizyivayet etu avtomatizaciyu i peresozdayot rezuljtat. Tochechnaya ruchnaya pravka fajla opisaniya ne podtverzhdayet rabotosposobnostj avtomatizacii i poetomu ne ispoljzuyetsya kak sposob obnovleniya.

## Vkhodyi

- Adresat: konkretnaya auditoriya, rolj ili gruppa chitatelej.
- Celj: dlya chego etomu adresatu nuzhno opisaniye.
- Ogranicheniya: dopustimaya dlina, ton, glubina tekhnicheskikh detalej, nedopustimyiye utverzhdeniya.
- Istochniki: tochnyij versioniruyemyij perechenj fajlov iz `Документация/`, `Глоссарий/`, `Вопросы/`, papok zaprosov v `Журнал/` i, pri neobkhodimosti, drugikh oblastej [pamyati](../../Glossarij/pamyatj-FUM.md). Tranzitivnyiye ssyilki iz etikh fajlov ne stanovyatsya skryityimi vkhodami.
- Operacionnyij snimok: toljko yavno nazvannyiye read-only komandyi ili nablyudeniya, yesli fakticheskij status neljzya vyivesti iz proizvodnoj dokumentacii; komanda, rezuljtat i granica vosproizvodimosti fiksiruyutsya v rabochej sessii.
- Status: novoye opisaniye, polnaya peresborka ili obnovleniye susjhestvuyusjhego fajla.

## Vyikhodyi

- Markdown-fajl v `Описания/`.
- Pasport opisaniya: adresat, celj, status, avtomatizaciya, istochniki, ogranicheniya.
- Svyazi s istochnikami trebovanij i klyuchevyimi dokumentami.
- Kratkaya fiksaciya togo, chto izmenilosj pri obnovlenii.
- Fiksaciya vyizova avtomatizacii v fajle iskhodnogo zaprosa rabochej sessii.

## Chistoye yadro

Predpochtiteljnaya forma avtomatizacii - [chistaya funkciya](../../Glossarij/chistaya-funkciya.md):

`описание = собрать(паспорт_адресата, список_источников, правила_отбора, структура_результата)`

Chistoye yadro ne dolzhno opiratjsya na skryituyu pamyatj agenta. Vse susjhestvennyiye utverzhdeniya dolzhnyi byitj vyivodimyi iz peredannyikh istochnikov ili yavno pomechenyi kak interpretaciya.

## Statusyi tezisov

Kazhdyij susjhestvennyij tezis kartyi sborki poluchayet odin status:

- **realizovannyij lokaljnyij kontur** — kod, avtomatizaciya ili repozitornaya praktika uzhe susjhestvuyut i imeyut nablyudayemuyu proverku;
- **dejstvuyusjhij issledovateljskij prototip** — uzkaya rabochaya proba zapuskayetsya i proveryayetsya, no ne yavlyayetsya prinyatoj produktovoj realizaciyej;
- **proyektiruyemaya korobochnaya forma** — trebovaniye, arkhitekturnoye resheniye ili plan budusjhego produkta bez utverzhdeniya o gotovom runtime;
- **otkryitaya granica** — zafiksirovannaya neopredelyonnostj, risk ili usloviye, kotoroye yesjhyo trebuyet resheniya libo otdeljnoj proverki.

Istoricheskij fakt ili operacionnoye nablyudeniye mogut podderzhivatj tezis, no ne podmenyayut yego status. Yesli istochniki dayut nesovmestimyiye statusyi i prioritet neljzya dokazatj, peresborka ostanavlivayetsya.

## Procedura sborki

1. Zafiksirovatj adresata i yego klyuchevyiye voprosyi.
2. Vyibratj ili obnovitj zakreplyonnyij profilj s tochnyimi putyami vsekh vkhodov, celjyu, ogranicheniyami i vyikhodnyim fajlom.
3. Do napisaniya proveritj susjhestvovaniye i tochnyij registr kazhdogo puti. Otsutstvuyusjhij vkhod, nerazreshyonnoye protivorechiye statusov ili neobkhodimostj skryitogo istochnika ostanavlivayut peresborku.
4. Sobratj kartu tezisov i naznachitj kazhdomu tezisu odin iz chetyiryokh statusov: realizovannyij lokaljnyij kontur, dejstvuyusjhij issledovateljskij prototip, proyektiruyemaya korobochnaya forma ili otkryitaya granica.
5. Otobratj tezisyi, relevantnyiye adresatu, i ubratj detali, kotoryiye ne pomogayut celi opisaniya.
6. Sformirovatj strukturu rezuljtata: kratkaya formulirovka, cennostj dlya adresata, ustrojstvo proyekta, tekusjhij status, riski, blizhajshiye vekhi ili voprosyi.
7. Sozdatj novyij polnyij tekst na russkom yazyike kirillicej, sokhranyaya `FUM` kak latinskuyu abbreviaturu.
8. Rasstavitj ssyilki na istochniki, glossarnyiye terminyi i otkryityiye voprosyi.
9. Proveritj, chto opisaniye ne soderzhit nepodtverzhdyonnyikh faktov, obesjhanij ili trebovanij, kotoryikh net v profile.
10. Sravnitj novyij tekst s prezhnim toljko kak kontrolj poteryannyikh tem i ustarevshikh tezisov. Yesli obnaruzhen neobkhodimyij istochnik vne profilya, snachala obnovitj profilj i povtoritj sborku s nachala.
11. Polnostjyu zamenitj vyikhodnoj fajl novyim rezuljtatom, a ne primenyatj k prezhnemu tekstu nabor tochechnyikh soderzhateljnyikh pravok.
12. Obnovitj indeks `Описания/README.md` i zafiksirovatj vyizov, profilj, rezuljtat i proverki v fajle iskhodnogo zaprosa rabochej sessii.

## Bazovaya struktura fajla

Novyij fajl opisaniya dolzhen nachinatjsya s soderzhateljnogo itogovogo abzaca, posle kotorogo idyot pasport, a istochniki trebovanij razmesjhayutsya vnizu pered `FUM-MD-RECENCY`:

```markdown
# Описание FUM для <адресата>

<Краткий содержательный итог о фактическом статусе FUM для адресата.>

## Паспорт описания

- Адресат: ...
- Цель: ...
- Статус: ...
- Автоматизация: [Построение описания FUM для адресата](Автоматизации/построение-описания-FUM-для-адресата.md)
- Основные источники: ...
- Ограничения: ...

## Краткая формулировка

...

## Источники требований

- [исходный запрос ...](../../Журнал/<YYYY-MM-DD_HH-MM-SS_MSK>_<краткое-название-запроса>/запрос.md)
```

## Zakreplyonnyij profilj `для-разработчиков-ПО-v2`

Profilj `для-разработчиков-ПО-v2` zamenyayet `для-разработчиков-ПО-v1` kak dejstvuyusjhij vkhod polnoj peresborki. Istoricheskij sostav `v1` sokhranyayetsya v Git-istorii, no ne ispoljzuyetsya kak neyavnyij dopolniteljnyij istochnik.

- Vyikhod: [opisaniye FUM dlya razrabotchikov PO](../dlya-razrabotchikov-PO.md).
- Adresat: razrabotchiki PO, inzheneryi agentskikh sistem, arkhitektoryi i tekhnicheskiye uchastniki, ocenivayusjhiye vosproizvodimostj i granicyi realizacii FUM.
- Celj: pokazatj, chto uzhe realizovano i avtonomno proveryayetsya v lokaljnoj pamyati, chem dejstvuyusjhij bezokonnyij Swift-kontur otlichayetsya ot specificirovannogo, no ne realizovannogo produktovogo URL-servisa, chto toljko proyektiruyetsya kak korobochnaya FUM i kakiye granicyi ostayutsya otkryityimi.
- Rezhim: polnaya peresborka vsego vyikhodnogo fajla.
- Ogranicheniya: ne obyyavlyatj dokumentacionnyij prototip, vneshnij kontur Codex, arkhivator istochnikov ili otdeljnyij Swift-prototip gotovyim yadrom FUM, SDK libo yedinyim prilozheniyem; ne vyivoditj gotovnostj produktovogo URL-servisa iz nalichiya pasporta, JSON Schema, kartochek trebovanij ili lokaljnogo CLI; ne schitatj zakryitiye kontraktnyikh zamechanij libo otdeljnyij rezuljtat povtornogo audita zaversheniyem stadii, vyiborom ili razresheniyem produktovoj realizacii; ne vvoditj novyiye trebovaniya; ne skryivatj ruchnuyu deklarativnuyu prirodu etoj avtomatizacii.

Tochnyij nabor vkhodov profilya:

- `Документация/`: [00 — obzor proyekta](../../Dokumentaciya/00-obzor-proyekta.md), [01 — modelj pamyati](../../Dokumentaciya/01-modelj-pamyati-FUM.md), [02 — publikaciya i licenziya](../../Dokumentaciya/02-publikaciya-i-licenziya.md), [05 — moduljnaya arkhitektura](../../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md), [06 — obzor agentskikh ciklov](../../Dokumentaciya/06-obzor-agentskikh-ciklov.md), [17 — vosproizvodimyiye avtomatizacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md), [18 — adresnyiye opisaniya](../../Dokumentaciya/18-opisaniya-FUM-dlya-adresatov.md), [19 — yedinaya tochka vzaimodejstviya](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md), [20 — Git-infrastruktura](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md), [22 — arkhitektura](../../Dokumentaciya/22-arkhitektura-FUM.md), [24 — lokaljnyij agent](../../Dokumentaciya/24-lokaljnyij-agent-na-vyidelennoj-mashine.md), [25 — interfejs uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md), [27 — publichnyij upstream i forki](../../Dokumentaciya/27-publichnyij-upstream-i-forki-pamyati.md), [32 — potokovaya samostrukturizaciya](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md), [36 — dokumentacionnyij prototip i pervyij produktovyij URL-srez](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md), [mashinnaya skhema URL-kontrakta versii 1](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza/kontrakt-pervogo-URL-sreza-v1.schema.json), [43 — nachaljnyij korobochnyij prototip](../../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md).
- `Глоссарий/`: [FUM](../../Glossarij/FUM.md), [pamyatj FUM](../../Glossarij/pamyatj-FUM.md), [dokumentacionnyij prototip FUM](../../Glossarij/dokumentacionnyij-prototip-FUM.md), [korobochnaya realizaciya FUM](../../Glossarij/korobochnaya-realizaciya-FUM.md), [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md), [opisaniye FUM dlya adresata](../../Glossarij/opisaniye-FUM-dlya-adresata.md), [agentskij cikl](../../Glossarij/agentskij-cikl.md), [interfejs FUM-uzla](../../Glossarij/interfejs-FUM-uzla.md), [suffiksno-prediktivnaya pamyatj FUM](../../Glossarij/suffiksno-prediktivnaya-pamyatj-FUM.md), [prikreplyayemyij material](../../Glossarij/prikreplyayemyij-material.md), [TDD](../../Glossarij/TDD.md).
- `Вопросы/`: [indeks voprosov](../../Voprosyi/README.md), [razvilka giperseti i agentskogo cikla](../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md), [kriterii lokaljnoj LLM i vyidelennoj mashinyi](../../Voprosyi/2026-06-25_19-50-33_MSK_kriterii-lokaljnoj-LLM-i-vyidelennoj-mashinyi-FUM.md), [granicyi yestestvenno-yazyikovoj sinkhronizacii znanij](../../Voprosyi/2026-07-13_20-34-23_MSK_granicyi-yestestvenno-yazyikovoj-sinkhronizacii-znanij-FUM.md).
- `Планирование/`: [indeks MVP-kandidatov](../../Planirovaniye/MVP-kandidatyi/README.md), [arkhivirovaniye prikreplyayemyikh materialov](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md), [adresnyiye opisaniya i pasporta auditorij](../../Planirovaniye/MVP-kandidatyi/05-adresnyiye-opisaniya-i-pasporta-auditorij/README.md), [napravleniye pamyati i proiskhozhdeniya](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/01-pamyatj-i-proiskhozhdeniye.md), [indeks stadij](../../Planirovaniye/stadii/README.md), [stadiya 01](../../Planirovaniye/stadii/01-dokumentacionnyij-prototip-FUM/README.md), [stadiya 02](../../Planirovaniye/stadii/02-korobochnaya-realizaciya-FUM/README.md).
- `Прототипы/`: [indeks prototipov](../../Prototipyi/README.md), [vosproizvodimoye popolneniye pamyati](../../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md), [tenevoj redaktor prodolzhenij](../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md), [fizicheskiye sostoyaniya klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md).
- `Инструменты/`: [arkhivirovaniye materialov](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md), [zapusk prototipov](../../Instrumentyi/fum-zapusk-prototipov/SKILL.md), [proverka README](../../Instrumentyi/fum-indeks-readme/SKILL.md), [obsjhij smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md).
- `Требования/`: [indeks kartochek trebovanij](../../Trebovaniya/README.md), [bezokonnyij Swift-kontur pervogo korobochnogo prototipa](../../Trebovaniya/✅-bezokonnyij-Swift-kontur-pervogo-korobochnogo-prototipa.md), [vosproizvodimoye shtatnoye popolneniye pamyati](../../Trebovaniya/🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md), [GUI kak proyekciya vnutrennej pamyati i ispolneniya](../../Trebovaniya/🟡-GUI-kak-proyekciya-vnutrennej-pamyati-i-ispolneniya.md), [bezopasnyij priyom publichnogo HTML-URL](../../Trebovaniya/🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md), [privyazannoye podtverzhdeniye i minimaljnyiye prava priyoma istochnika](../../Trebovaniya/🟡-privyazannoye-podtverzhdeniye-i-minimaljnyiye-prava-priyoma-istochnika.md), [produktovoye proiskhozhdeniye prinyatogo istochnika](../../Trebovaniya/🟡-produktovoye-proiskhozhdeniye-prinyatogo-istochnika.md), [atomarnoye prinyatiye snimka i proiskhozhdeniya istochnika](../../Trebovaniya/🟡-atomarnoye-prinyatiye-snimka-i-proiskhozhdeniya-istochnika.md), [versionirovannaya pervichnaya trassa sobyitij vvoda](../../Trebovaniya/🚧-versionirovannaya-pervichnaya-trassa-sobyitij-vvoda.md), [fizicheskiye perekhodyi klavish](../../Trebovaniya/🚧-fizicheskiye-perekhodyi-klavish.md), [zasjhisjhyonnyij sbor chuvstviteljnogo vvoda](../../Trebovaniya/🟡-zasjhisjhyonnyij-sbor-chuvstviteljnogo-vvoda.md).
- `Ревью/`: [audit pasporta korobochnoj stadii 2026-07-22](../../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md). Otchyot povtornogo audita etoj dorabotki namerenno ne vkhodit v profilj `v2`: inache proveryayemoye opisaniye zaviselo byi ot rezuljtata, kotoryij sam proveryayet opisaniye.
- Papki zaprosov v `Журнал/`: [zapros priyomki arkhivatora](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/zapros.md), [otchyot priyomki arkhivatora](../../Zhurnal/2026-07-21_10-36-18_MSK_zavershitj-skvoznuyu-priyomku-arkhivatora-istochnikov/otchyot.md), [zapros polnoj peresborki v1](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md), [tekusjhij zapros dorabotki pasporta i polnoj peresborki v2](../../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md).
- Kornevoj vkhod: [README](../../README.md). Operacionnyij Git-snimok v `v2` ne ispoljzuyetsya: neobkhodimyij status vyivoditsya iz yavno perechislennyikh dokumentov, trebovanij, prototipov i planovyikh materialov.

Yavnyij vyizov profilya zapisyivayetsya tak:

```text
собрать(
  профиль = "для-разработчиков-ПО-v2",
  режим = "полная пересборка",
  выход = "Описания/для-разработчиков-ПО.md"
)
```

Pered zapisjyu rezuljtata ispolnitelj proveryayet vse perechislennyiye puti, stroit statusnuyu kartu tezisov, sozdayot novyij polnyij tekst i toljko zatem sravnivayet yego s prezhnim opisaniyem kak s kontroljnyim snimkom. Lyuboye rasshireniye vkhodov snachala izmenyayet etot profilj.

## Proverki kachestva

- Adresat i celj ukazanyi yavno.
- Klyuchevyiye utverzhdeniya podderzhanyi ssyilkami na dokumentaciyu ili glossarij.
- Tekusjhij status proyekta ne zavyishen.
- Otkryityiye voprosyi i riski ne spryatanyi.
- Tekst mozhno peresobratj iz tekh zhe istochnikov bez obrasjheniya k skryitoj pamyati agenta.
- V rabochej sessii zafiksirovan vyizov avtomatizacii, a ne toljko ruchnoye izmeneniye gotovogo fajla.
- Opisaniye ne zamenyayet dokumentaciyu i ne vvodit novyiye trebovaniya bez otdeljnoj fiksacii.

## Pervoye primeneniye

- [Opisaniye FUM dlya investorov](../dlya-investorov.md)
- [Opisaniye FUM dlya razrabotchikov PO](../dlya-razrabotchikov-PO.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij](../../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-06-22 09:40:25 MSK](../../Zhurnal/2026-06-22_09-40-25_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 10:00:58 MSK](../../Zhurnal/2026-06-22_10-00-58_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:32:46 MSK - Aktualizirovatj vkhodnyiye opisaniya FUM](../../Zhurnal/2026-07-21_11-32-46_MSK_aktualizirovatj-vkhodnyiye-opisaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-28 20:06:05 MSK — Dorabotatj pasport korobochnoj stadii i pervogo URL-sreza po auditu](../../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 15:53:54 MSK -->
<!-- content-sha256: sha256:5f399a2d8d2b6e2f2c70ad6c8d9afc5709320ef964d76ac83e23555192d51b29 -->
<!-- FUM-MD-RECENCY:END -->
