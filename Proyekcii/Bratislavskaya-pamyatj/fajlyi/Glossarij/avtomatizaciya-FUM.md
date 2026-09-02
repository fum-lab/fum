# Avtomatizaciya FUM

Avtomatizaciya FUM - ustojchivaya avtomaticheskaya algoritmicheskaya struktura, kotoraya vyipolnyayet chastj vospriyatiya, preobrazovaniya sostoyaniya, vyibora dejstviya, workflow, proverki, vizualizacii, postroyeniya [opisanij FUM dlya adresatov](opisaniye-FUM-dlya-adresata.md) ili upravleniya v arkhitekture [FUM](FUM.md).

Avtomatizaciya FUM dolzhna byitj predskazuyemoj i vosproizvodimoj: yeyo iskhodnyiye tekstyi ili deklarativnyiye opisaniya, konfiguracii, versii, vkhodnyiye i vyikhodnyiye skhemyi, proverki i istoriya izmenenij dolzhnyi byitj chastjyu [pamyati FUM](pamyatj-FUM.md).

Yesli avtomatizaciya ispoljzuyetsya v rabote repozitoriya, dlya neyo nuzhno stremitjsya sokhranyatj lokaljno vosproizvodimyij sloj: komandu zapuska, testovyiye primeryi, ozhidayemyiye rezuljtatyi i ogranicheniya vneshnikh zavisimostej. Novyiye i izmenyayemyiye avtomatizacii razvivayutsya cherez [TDD](TDD.md), kogda proverka povedeniya formuliruyetsya do izmeneniya realizacii.

Povtoryayemaya repozitornaya rabota oformlyayetsya lokaljnoj avtomatizaciyej, kotoruyu yavno vyizyivayet vruchnuyu zapusjhennaya pishusjhaya sessiya v predelakh svoyego soderzhateljnogo zaprosa. Raspisaniye, obsjhij reyestr, nablyudayemyij host-prostoj, [zadacha-prodolzheniye vetki](obyazateljnoye-prodolzheniye-vetki.md) i vetochnyij selektor ne dayut avtomatizacii polnomochij na zapusk; continuation/FIFO-profilj sokhranyon toljko kak otlozhennaya narabotka.

Dlya ustojchivyikh avtomatizacij proyektiruyetsya [yazyik avtomatizacij FUM](yazyik-avtomatizacij-FUM.md): yazyik programmirovaniya i opisaniya avtomatizacij, optimizirovannyij dlya chteniya, generacii, proverki i tochechnoj pravki so storonyi LLM.

U kazhdoj novoj ili pereimenovyivayemoj avtomatizacii yestj iskhodnoye smyislovoye imya na russkom yazyike kirillicej. Yego otobrazhayemaya latinskaya forma dolzhna tochno sovpadatj s rezuljtatom vyizova LinguisticKit `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)` na zakreplyonnoj revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Eto kanonicheskaya transliteraciya imenno dlya FUM, a ne zayavleniye o sootvetstvii universaljnomu standartu ISO ili GOST.

Tot zhe LinguisticKit-kontrakt zadayot celevoye preobrazovaniye [bratislavskoj versii pamyati FUM](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md). Yeyo fajlovyij inventarj, pokomponentnoye otobrazheniye polnyikh putej, formatnyiye isklyucheniya i manifest yavlyayutsya otdeljnyim versionirovannyim kontraktom; pravila slug nazvanij avtomatizacij k nim avtomaticheski ne primenyayutsya.

Tekhnicheskij slug obrazuyetsya otdeljnyim pravilom FUM uzhe posle transliteracii: rezuljtat perevoditsya v nizhnij registr, probelyi zamenyayutsya defisami, a tam, gde etogo trebuyet prostranstvo imyon, dobavlyayetsya zakreplyonnyij tekhnicheskij prefiks. Eti preobrazovaniya ne pripisyivayutsya LinguisticKit. Sovpadeniye itogovyikh slug raznyikh smyislovyikh imyon schitayetsya oshibkoj i trebuyet vyibora razlichimyikh imyon.

Prezhniye repozitornyiye identifikatoryi avtomatizacij migrirovanyi na obsjhij kontrakt i boljshe ne obrazuyut aktivnyikh isklyuchenij: v kanonicheskom [reyestre nazvanij avtomatizacij](../Instrumentyi/reyestr-nazvanij-avtomatizacij.json) polya `legacy` i `legacy_display` pustyi. Oni sokhranyayutsya v skheme toljko dlya chteniya istoricheskogo formata i avtonomnyikh testovyikh fikstur; vozvrasjhatj v nikh dejstvuyusjhuyu avtomatizaciyu ili kopirovatj prezhneye imya kak obrazec neljzya. Doslovnyiye zaprosyi, zhurnaljnyiye svideteljstva i sokhranyonnyiye istochniki ostayutsya istoriyej, a ne ispolnyayemyimi psevdonimami. Smena zakreplyonnoj revizii LinguisticKit vyipolnyayetsya toljko kak yavnaya migraciya s povtornyim raschyotom imyon i proverkoj kollizij.

Repozitornaya zavisimostj LinguisticKit podklyuchena kak [Git submodule iz forka ryadom s aktualjnyim FUM](../Zavisimosti/README.md) na zakreplyonnoj revizii. Ispolnyayemaya proverka sveryayet zhivoj rezuljtat paketa s etalonami, a otdeljnaya [avtomatizaciya Git-zavisimostej](../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md) bez setevogo zaprosa proveryayet roli forka i upstream, `.gitmodules`, dostizhimostj revizii iz lokaljno poluchennyikh refs forka i tochnyij gitlink. Zhivaya liniya forka i publikaciya revizii proveryayutsya otdeljno cherez GitHub.

Chastnyimi sluchayami avtomatizacii yavlyayutsya [avtomaticheskij organ vospriyatiya FUM](avtomaticheskij-organ-vospriyatiya-FUM.md) i [avtomaticheskij organ dejstviya FUM](avtomaticheskij-organ-dejstviya-FUM.md). Pervyij byistro szhimayet shirokij vkhodnoj potok vneshnego sobyitiya do kompaktnogo opisaniya, prigodnogo dlya sokhraneniya i obrabotki vnutri [FUM](FUM.md). Vtoroj razvorachivayet vyisokourovnevoye opisaniye dejstviya v konkretnyiye nizkourovnevyiye dejstviya ispolniteljnyikh mekhanizmov.

Deklarativnaya skhema sborki adresnogo opisaniya tozhe mozhet byitj avtomatizaciyej, yesli ona fiksiruyet vkhodyi, istochniki, pravila otbora tezisov, strukturu rezuljtata i proverki vosproizvodimosti.

## Svyazannyiye dokumentyi

- [Obyazateljnoye prodolzheniye Git-vetki posle kommita](../Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [Vosproizvodimyiye avtomatizacii FUM](../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [LLM-oriyentirovannyij yazyik avtomatizacij](../Dokumentaciya/21-LLM-oriyentirovannyij-yazyik-avtomatizacij.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Moduljnaya arkhitektura FUM](../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md)
- [Postroyeniye opisaniya FUM dlya adresata](../Opisaniya/Avtomatizacii/postroyeniye-opisaniya-FUM-dlya-adresata.md)
- [TDD](TDD.md)

## Istochniki

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-27 15:21:35 MSK — Sdelatj dispetcher avtomatizacij vetki universaljnyim](../Zhurnal/2026-07-27_15-21-35_MSK_sdelatj-dispetcher-avtomatizacij-vetki-universaljnyim/zapros.md)
- [iskhodnyij zapros 2026-07-22 08:44:00 MSK — Migrirovatj legacy imena avtomatizacij](../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 12:18:37 MSK — Zakrepitj transliteraciyu nazvanij avtomatizacij](../Zhurnal/2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK — Aktualizirovatj fork i podklyuchitj LinguisticKit](../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)
- [arkhivirovannyij istochnik Roman-Kerimov/LinguisticKit](../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [arkhivirovannaya vyibrannaya reviziya LinguisticKit](../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 15:55:48 MSK -->
<!-- content-sha256: sha256:954fc541895caf89b1d9c1d8dd457ebfffedfcd23c30fc215a6c34970ee6c3cf -->
<!-- FUM-MD-RECENCY:END -->
