# Sravneniye modelej na odnoj zadache v vetkakh

Nablyudeniye poljzovatelya: nezavisimyiye vetki pozvolyayut sravnitj vyipolneniye odnoj postanovki raznyimi modelyami. Eto primeneniye gotovyasjhegosya mekhanizma izolirovannyikh vetok, a ne otdeljnyij uzhe zapusjhennyij eksperiment. Blizhajshij etap — zavershitj proveryayemoye sliyaniye vedusjhej vetki s master.

## Kak provesti pervyij eksperiment

1. Vyibratj ogranichennuyu reprezentativnuyu zadachu i zaraneye sokhranitj odinakovyiye iskhodnyij commit, postanovku, dostupnyiye instrumentyi, zavisimosti i kriterii rezuljtata. Nachaljnyij kontekst tozhe fiksiruyetsya: peredannyij dialog, dejstvuyusjhiye pravila, dopolniteljnyiye materialyi i razresheniye na delegirovaniye. Novyiye popyitki ne nasleduyut najdennyiye resheniya predyidusjhikh. Proveryayusjhij kontur zakrepitj otdeljno ot rezuljtatov uchastnikov.
2. Ot iskhodnogo commit vyidelitj kazhdomu uchastniku svoyo derevo. Imena mogut imetj vid `codex/ab/<эксперимент>/gpt-6-astra` i `codex/ab/<эксперимент>/gpt-5.3-codex-spark`. V opisanii sokhranitj tochnyiye model ID, reasoning effort, ogranicheniya i fakticheskoye podtverzhdeniye vyibrannoj modeli; imya vetki samo etogo ne dokazyivayet.
3. Do okonchaniya nezavisimyikh popyitok ne perenositj resheniya mezhdu vetkami. Do izmerenij vyibratj kholodnyiye libo odinakovo progretyiye kyeshi, poryadok povtorov i raspredeleniye obsjhikh CPU, pamyati i diska. Dlya pervogo sravneniya dliteljnosti cheredovatj posledovateljnyiye popyitki uchastnikov; odnovremennyij zapusk otdeljno ocenivayet rabotu pri konkurencii za resursyi. Yego wall-clock ne kharakterizuyet chistuyu skorostj modeli.
4. Odnim proveryayusjhim konturom ocenitj odinakovyiye kriterii i exact diff. Zaraneye opredelitj byudzhet popyitki, usloviye ostanovki, nachalo i konec izmereniya vremeni, uchyot tokenov i vyizovov, vklyuchaya dochernikh ispolnitelej. Sravnivatj kachestvo rezuljtata, oshibki i vozvratyi k ispravleniyam, dliteljnostj, dostupnyiye schyotchiki tokenov i zatrat, chislo vyizovov instrumentov i vmeshateljstv cheloveka. Prezhdevremennyij final sokhranyayetsya otdeljnyim iskhodom; prodolzheniye posle podskazki cheloveka schitayetsya vmeshateljstvom. Neizvestnyij pokazatelj otmechatj kak neizvestnyij; schyotchik limita akkaunta ne raven stoimosti otdeljnoj popyitki.
5. Sokhranitj iskhodyi obeikh vetok, vklyuchaya neuspekh. Dlya vyivoda o modelyakh ispoljzovatj neskoljko zadach i povtorov: odin vyiigryish yavlyayetsya nablyudeniyem ob etoj popyitke. Pri chelovecheskoj ocenke po vozmozhnosti skryitj imya modeli do vyistavleniya ocenki.
6. Prinimatj vyibrannyij rezuljtat obyichnyim dopuskom master. Pobeda v sravnenii sama po sebe ne dayot prava sliyaniya, publikacii ili zapuska sleduyusjhej zadachi.

## Chto avtomatizirovatj posle pervogo vosproizvodimogo sravneniya

Opisaniye eksperimenta svyazyivayet obsjheye proiskhozhdeniye, vetki uchastnikov, nastrojki runtime, zapuski proverok i itogovyiye commit OID. Avtomatizaciya podgotavlivayet odinakovyiye vkhodyi, sobirayet dostupnuyu statistiku i svodnyij otchyot, sokhranyaya prichinyi raskhozhdenij i neizvestnyiye znacheniya. Zatem po nakoplennyim dannyim mozhno vyibiratj, kakiye zadachi otdavatj byistroj modeli, kogda nuzhna boleye siljnaya i kakiye priznaki trebuyut povtornoj proverki. Pravilo vyibora ocenivayetsya na novyikh zadachakh, a ne toljko na popyitkakh, kotoryimi ono byilo nastroyeno.

Realizaciya, mashinnyij kontrakt eksperimenta i fakticheskij zapusk ostayutsya sleduyusjhej rabotoj posle gotovnosti bazovogo marshruta vetok. Eta zametka ne vklyuchayet istoricheskij FIFO/pool, avtoprodolzheniye ili native hook.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 16:55:44 MSK -->
<!-- content-sha256: sha256:bce71580d6a1100aa02e05a96688d164b70a573b2f17fd2e5d8239848e0f97d3 -->
<!-- FUM-MD-RECENCY:END -->
