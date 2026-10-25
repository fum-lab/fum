+++
schema_version = 1
card_id = "FUM-STEP-0198"
status = "active"
+++
# Proveritj i soglasovatj mezhvetochnoye vyideleniye identifikatorov

## Zadacha

Podgotovitj kontrakt sverki zanyatosti i soglasovannogo vyideleniya identifikatorov kartochek i lokaljnyikh nomerov proyavlenij vnutri kartochki mezhdu odnovremenno rabotayusjhimi vetkami FUM, vklyuchaya vosproizvodimyiye scenarii regressij i ozhidayemyiye iskhodyi. Rezuljtat FUM-STEP-0198 — trebovaniya dlya realizacii v obsjhem ispolnitele FUM-STEP-0201; otdeljnaya konkuriruyusjhaya realizaciya zdesj ne sozdayotsya. Budusjhij ispolnitelj dolzhen predotvrasjhatj povtor mekhanizma FUM-SBOJ-0050: lokaljnyij maksimum odnogo checkout ne dokazyivayet svobodu nomera vo vsyom soglasovannom prostranstve.

Snachala opredelitj konechnyij perechenj uchastvuyusjhikh vetok, tochnyiye OID prochitannyikh snimkov, sokhranyonnyiye rezervacii i vladeljcev. Proverka dolzhna razlichatj podtverzhdyonno zanyatyij, zarezervirovannyij, svobodnyij v polnoj obyyavlennoj oblasti i neizvestnyij nomer. Neizvestnyij snimok ne zamenyayetsya pustyim naborom.

## Pochemu sejchas

Dve vetki nezavisimo zakrepili FUM-SBOJ-0046 za raznyimi mekhanizmami. Pozdnyaya ocenka nomera 0047 po odnoj vetke takzhe ne uchla uzhe opublikovannuyu kartochku drugoj zadachi. Ruchnoye soglasovaniye razreshilo tekusjhuyu kolliziyu, no ne yavlyayetsya gotovoj avtomatizaciyej predotvrasjheniya sleduyusjhej.

## Kriterii zaversheniya

- Zadanyi proveryayemaya oblastj mezhvetochnogo prostranstva, tipyi kartochek, vladeljcyi i istochniki rezervov. Polnota etoj oblasti imeyet nablyudayemoye osnovaniye; proverka odnogo checkout ne vyidayotsya za globaljnuyu.
- V kontrakte chteniya zadana svyazj kazhdoj obnaruzhennoj kartochki s yeyo tipom, neizmenyayemyim ID, polnyim ref, OID i putyom. Odinakovyij nomer raznyikh semejstv ne schitayetsya kolliziyej; odin ID raznyikh susjhnostej v odnom semejstve obnaruzhivayetsya.
- Kontrakt okhvatyivayet sostavnuyu identichnostj proyavleniya: ID kartochki sboya i yeyo lokaljnyij nomer. Odinakovyij lokaljnyij nomer v raznyikh kartochkakh dopustim; odin sostavnoj identifikator raznyikh epizodov obnaruzhivayetsya kak kolliziya.
- Dlya vyideleniya opredeleno yedinstvennoye proveryayemoye osnovaniye vladeniya rezervom. Konkuriruyusjhiye zaprosyi odnogo nomera, povtor zaprosa posle neopredelyonnogo iskhoda i osvobozhdeniye libo otmena rezerva imeyut yavno zadannoye povedeniye bez molchalivogo pereispoljzovaniya.
- V kontrakte zadanyi otkazyi pri sdvige iskhodnogo ref, nedostupnoj vetke, nepolnom nabore vkhodov i uzhe zanyatom ili zarezervirovannom nomere: eti sluchai ne dolzhnyi davatj lozhnyij otvet «svoboden».
- Opisanyi regressionnyiye scenarii i ozhidayemyiye rezuljtatyi dlya FUM-SBOJ-0050/PROYAVLENIYE-0001 i PROYAVLENIYE-0002: nezavisimogo sozdaniya 0046 i oshibochnoj ocenki 0047. Dopolniteljno zadanyi sluchai otsutstviya kollizii, konkurencii i povtornogo chteniya neizmennogo snimka. Realjnyiye progonyi otnosyatsya k priyomke ispolnitelya FUM-STEP-0201 i sejchas ne zayavlyayutsya.
- Regressionnyij scenarij FUM-SBOJ-0050/PROYAVLENIYE-0003 sokhranyayet oshibochnoye naznacheniye FUM-SBOJ-0009/PROYAVLENIYE-0005 po nepolnomu checkout pri zanyatyikh 0001–0016 v snimke 6bf2f53fc76069b02ba1eae3ed31235716f0f1cd. Ozhidayemyij rezuljtat — otkaz obyyavlyatj 0005 svobodnyim; soglasovannyij perekhod k 0017 sokhranyayet prezhniye svideteljstva i istoriyu vremennogo nomera. Realjnyij progon otnositsya k priyomke STEP0201.
- Predlozhennyij perekhod susjhestvuyusjhej kollizii sokhranyayet prezhnyuyu identichnostj i tochnyiye iskhodnyiye kommityi kak proiskhozhdeniye. Pereimenovaniye bez istorii ili ispravleniye chuzhogo ref ne podmenyayut soglasovannuyu integraciyu.
- Kontrakt i scenarii peredanyi vladeljcu obsjhego cikla FUM-STEP-0201 s proveryayemyim proiskhozhdeniyem i granicej integracii. Dlya budusjhej realizacii predusmotrenyi TDD, profilj i vosproizvodimyiye komandyi po pravilam zadachi. Naznachennyij vladelec realizacii — zadacha Codex 01a08d77-2060-7701-9f44-ff04769d8a6e; chuzhaya kartochka ne sozdayotsya v etoj vetke, yeyo kanonicheskaya ssyilka dobavlyayetsya posle dostupnoj integracii.
- Itog fiksiruyet polnotu podgotovlennogo kontrakta i peredannyikh scenariyev, vladeljca realizacii i yeyo otdeljnuyu priyomku. Zaversheniye etoj podgotovki ne zakryivayet FUM-SBOJ-0050. Nalichiye rezerva ne dokazyivayet sozdaniye kartochki, kommit, publikaciyu ili integraciyu.

## Sokhranyonnoye predshestvuyusjheye proyavleniye

FUM-SBOJ-0050/PROYAVLENIYE-0003 iz tochnogo kommita 8d89a695d6f099091a13d3ce60c924c7098105f2 rasshiryayet oblastj na paru «ID kartochki sboya, lokaljnyij nomer». Dlya sostavnoj identichnosti tozhe nuzhna mezhvetochnaya sverka pered naznacheniyem. [Gotovyij fragment i iskhodnyiye svideteljstva](../../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/materialyi/proiskhozhdeniye-proyavleniya-0050-0003.json) sokhranenyi bez povtornoj klassifikacii.

## Utochneniye posle poyavleniya obsjhego raspredelitelya

FUM-SBOJ-0050/PROYAVLENIYE-0004 vosproizvodit ruchnoj vyibor uzhe zarezervirovannogo 0091 pri nalichii shtatnogo Khranilisjhe.vyidelitj. Kontrakt dolzhen yavno razlichatj vyidachu etim mekhanizmom i nepodtverzhdyonnoye imya chernovika; nalichiye rabotayusjhego raspredelitelya ne yavlyayetsya dokazateljstvom okhvata obkhodyasjhikh yego ruchnyikh zapisej. Novyij ispolnitelj ili aljternativnyij raspredelitelj etim utochneniyem ne predlagayetsya. Susjhestvuyusjhij mekhanizm vosstanovil konkretnoye nablyudeniye vyidachej 0106; sistemnaya granica obkhoda ostayotsya otkryitoj.

## Istochniki

- [Fakticheskij povtor lokaljnogo vyibora i vosstanovleniye](../../Zhurnal/2026-09-12_01-55-13_MSK_sokhranitj-prodolzheniye-posle-obnovleniya-sistemyi/otchyot.md) — FUM-SBOJ-0050/PROYAVLENIYE-0004, [kartochka i tochnoye proyavleniye](../../Sboi/FUM-SBOJ-0050-vyideleniye-globaljnogo-identifikatora-iz-lokaljnogo-maksimuma.md).

- [Sverka kollizii nomera proyavleniya i soglasovannoye rezervirovaniye](../../Zhurnal/2026-09-11_13-30-58_MSK_podgotovitj-postanovku-Windows-VM-na-macOS/materialyi/koordinaciya-nomera-proyavleniya.json) — FUM-SBOJ-0050/PROYAVLENIYE-0003.

- [Nablyudeniye i soglasovaniye perekhoda](../../Zhurnal/2026-09-11_01-59-54_MSK_razreshitj-kolliziyu-identifikatorov-kartochek/zapros.md).
- [FUM-SBOJ-0050](../../Sboi/FUM-SBOJ-0050-vyideleniye-globaljnogo-identifikatora-iz-lokaljnogo-maksimuma.md).
- [Kartochki shagov i ustojchivyiye identifikatoryi](README.md).
- [Kartochki sboyev i ikh proiskhozhdeniye](../../Sboi/README.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:46:43 MSK -->
<!-- content-sha256: sha256:63d046c5b72799750a8bde33caf98edff37d069f7088f023de5a826ba2fd2455 -->
<!-- FUM-MD-RECENCY:END -->
