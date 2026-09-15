+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0130"
"статус" = "активна"
+++
# Ustarevshiye tekstovyiye kontraktyi repozitornyikh testov ocheredi

## Nablyudayemyij sboj

Dva repozitornyikh testa istoricheskoj ocheredi trebovali prezhniye doslovnyiye formulirovki. Tretij shirokij priyomochnyij zapusk ostanovilsya na shage 17: vyipolneno 244 testa, dva zavershilisj otkazom. Predshestvuyusjhiye 16 shagov proshli; shagi 18–87 ne vyipolnyalisj.

## Granica povtoreniya

Staryiye stroki ozhidanij realjnogo checkout razoshlisj s tekusjhimi formulirovkami kanonicheskikh pravil i opisaniya smoke-check. Etot mekhanizm otlichayetsya ot nevernogo mashinnogo znacheniya rezhima v 0126. Iskhodnoye koordinacionnoye predpolozheniye takzhe ukazyivalo na dekompoziciyu AGENTS; konechnaya sverka dannogo proyavleniya lokalizovala 13 strokovyikh konstant, dlya ispravleniya kotoryikh rasshireniye oblasti chteniya ne potrebovalosj. Pravila i runtime ne menyalisj.

## Proyavleniya

### FUM-SBOJ-0130/PROYAVLENIYE-0001

[Zapusk 32](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/32_d7ce33e6-130e-4953-95a7-2831eff3e6ef.json) zavershilsya kodom 1 za 1157.536886584 s. Otkazyi voznikli v `test_agents_contract_names_the_portable_fifo_protocol` i `test_контрольный_и_итоговый_коммиты_не_запускают_исторический_конвейер` klassa RepositoryIntegrationTests. [Diagnostika vsekh ozhidanij](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-tekstovyikh-ozhidanij-ocheredi.json) sokhranila istochnik, SHA i 121 usloviye: 13 prezhnikh fraz otsutstvovali. Ostaljnyiye 242 uspeshnyikh testa nablyudalisj v otkazavshem polnom nabore; eto ne uspeshnaya priyomka vsego nabora.

## Ozhidaniye i klassifikaciya

Test realjnogo repozitoriya proveryayet dejstvuyusjhij smyisl i formulirovki yego kanonicheskikh istochnikov, sokhranyaya nezavisimyiye zapretyi istoricheskogo zapuska. Nomer naznachen raspredelitelem po sobyitiyu `context-stale-prose-contracts-01a0930d-full32`.

## Mekhanizm i sistemnoye ustraneniye

Ispravlenyi rovno 13 strokovyikh konstant dvukh susjhestvuyusjhikh metodov. [Proverka izmeneniya](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/proverka-ispravlenij-ozhidanij-ocheredi.json) svyazyivayet iskhodnyiye i konechnyiye SHA, sootvetstviye AST s tochnyimi zamenami i vse 526 obyyavlenij bez deljtyi obsjhego inventarya. Ni odno usloviye ne udaleno. Pervyiye 12 novyikh ozhidanij vzyatyi iz tekusjhego AGENTS, posledneye — iz opisaniya kompleksnoj proverki. Obsjhaya rannyaya sverka smyislovyikh kontraktov poka ne podklyuchena; yeyo granica sokhranena v STEP0174.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — osnovaniye FUM-SBOJ-0130/PROYAVLENIYE-0001.

## Kriterii zakryitiya

Rannyaya adresnaya proverka obnaruzhivayet rassinkhronizaciyu repozitornyikh ozhidanij i dejstvuyusjhikh istochnikov do dorogoj proyekcii, sokhranyayet vse proveryayemyiye zapretyi i otdeljnyiye istoricheskiye fiksturyi. Primenimostj kornevyikh i tematicheskikh istochnikov opredelena yavno; pravila ne menyayutsya radi prokhozhdeniya testa. Yedinichnoye ispravleniye 13 strok ne dokazyivayet podklyucheniye obsjhej meryi.

## Nablyudayemoye vosstanovleniye

[Zapusk 34](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/zapuski-proverok/34_92a43671-e0bf-442d-8d2e-34503547595e.json) proshyol oba susjhestvuyusjhikh testa. [Profilj](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/profilj-tekstovyikh-ozhidanij-ocheredi.json) soderzhit semj chereduyusjhikhsya par na odinakovyikh vkhodakh so vsemi 121 usloviyami: medianyi do 4427916 ns, posle 4312083 ns; kazhdyij konechnyij zamer menjshe zaraneye prinyatogo predela 100 ms. Algoritm i resursyi sokhranenyi, uskoreniye ne zayavlyayetsya. Adresnyij uspekh ne podmenyayet povtor vsego nabora iz 244 testov.

## Istochniki

- [Komandyi i utochneniya](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).
- [Otchyot](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:54:57 MSK -->
<!-- content-sha256: sha256:a6ad53cb456cf189db95e1918c7de2207e8d18d7e3292b2b296522aef1c6498f -->
<!-- FUM-MD-RECENCY:END -->
