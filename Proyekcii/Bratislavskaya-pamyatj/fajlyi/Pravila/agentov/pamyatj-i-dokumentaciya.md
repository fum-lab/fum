# Pamyatj i dokumentaciya

Eti pravila polnostjyu chitayutsya do izmeneniya pamyati FUM, proizvodnoj dokumentacii, README i indeksov dokumentacii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000008 -->
- [FUM](../../Glossarij/FUM.md) fiksiruyetsya kak abbreviatura latinskimi bukvami ot formulyi `fraktaljnyij uzel myishleniya`, po-russki - [fraktaljnyij uzel myishleniya](../../Glossarij/fraktaljnyij-uzel-myishleniya.md).

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000009 -->
- Proyekt razrabatyivayetsya kak otkryityij agent sleduyusjhego pokoleniya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000016 -->
- Imena fajlov i katalogov, kotoryiye yavlyayutsya russkimi slovami ili opisaniyami na russkom yazyike, tozhe pishutsya kirillicej.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000018 -->
- Dopustimyiye isklyucheniya dlya dokumentacionnogo teksta: nazvaniye FUM, tekhnicheskiye imena fajlov i katalogov, trebuyemyiye vneshnim kontraktom komandyi, formatyi i identifikatoryi, ssyilki, abbreviaturyi, nazvaniya licenzij i doslovnyiye citatyi; yazyik obyyavlyayemogo koda reguliruyetsya otdeljnyim razdelom nizhe.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000019 -->
- Tekst iskhodnogo poljzovateljskogo zaprosa v `Журнал/<YYYY-MM-DD_HH-MM-SS_MSK>_<краткое-название-запроса>/запрос.md` sokhranyayetsya v originaljnom napisanii bez perevoda, normalizacii, ispravleniya orfografii ili transliteracii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000020 -->
- Yesli iskhodnyij zapros napisan latinicej ili translitom, on ostayotsya takim toljko v bloke iskhodnogo teksta zaprosa; proizvodnaya dokumentaciya izlagayet trebovaniya na russkom yazyike kirillicej.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000021 -->
- Kirillicheskiye dokumentyi i puti yavlyayutsya yedinstvennyim kanonicheskim rabochim istochnikom [pamyati FUM](../../Glossarij/pamyatj-FUM.md). [Bratislavskij yazyik](../../Glossarij/bratislavskij-yazyik.md) — russkaya latinskaya proizvodnaya proyekciya etogo istochnika, a ne vtoroj nezavisimo redaktiruyemyij sloj i ne razresheniye vruchnuyu vesti russkoyazyichnyiye materialyi latinicej.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000022 -->
- Celevaya bratislavskaya proyekciya dolzhna khranitjsya v pamyati v neperesekayusjhemsya proizvodnom prostranstve imyon i polnostjyu peresobiratjsya lokaljnoj TDD-avtomatizaciyej cherez LinguisticKit `applyingTransform(from: .Cyrl, to: .Latn, withTable: .ru)` na zakreplyonnoj revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`. Preobrazovaniye okhvatyivayet russkoye soderzhimoye i kazhdyij kirillicheskij komponent polnogo puti ot kornya kanonicheskoj oblasti; tochnyiye vneshniye kontraktyi, doslovnyiye istochniki i nepreobrazuyemyiye formatyi obrabatyivayutsya toljko po yavnoj versionirovannoj politike.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000023 -->
- Proizvodnaya oblastj nikogda ne vkhodit obratno v iskhodnyij inventarj. Avtomatizaciya do pervoj massovoj zapisi dokazyivayet na testovyikh fiksturakh polnyij inventarj, preobrazovaniye ssyilok i putej, neperesecheniye oblastej, otsutstviye exact-, Unicode- i registronezavisimyikh kollizij, sokhraneniye proiskhozhdeniya i bezopasnuyu zamenu polnogo pokoleniya. Vliyayusjhaya na kanonicheskij sloj rabochaya sessiya peresobirayet i nezavisimo proveryayet tochnuyu oblastj `Proyekcii/**` v standartnom smoke-check, a posle zamyikaniya izmenivshegosya otchyota odin raz povtoryayet peresborku i proverku po specialjnoj finaljnoj granice; ruchnoye sozdaniye, ispravleniye ili sliyaniye massovoj bratislavskoj kopii zapresjheno.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000036 -->
- Dlya oblegcheniya vospriyatiya chelovekom fajlyi [proizvodnoj dokumentacii](../../Glossarij/proizvodnaya-dokumentaciya.md), indeksyi, planovyiye materialyi, otkryityiye voprosyi, zhurnaljnyiye otchyotyi i drugiye proizvodnyiye Markdown-dokumentyi [pamyati FUM](../../Glossarij/pamyatj-FUM.md) dolzhnyi nachinatjsya s soderzhateljnogo teksta posle zagolovka, a ne s dlinnyikh spravochnyikh spiskov.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000037 -->
- Osnovnoye soderzhaniye fajlov v `Документация/` dolzhno chitatjsya kak svyaznyij itogovyij tekst na osnove zaprosov, a ne kak khronika rabochej perepiski. Ne ispoljzuj v osnovnom soderzhanii neyavnyiye otsyilki vida "novyij zapros pokazyivayet", "predyidusjhij zapros utochnil" ili pokhozhiye formulirovki; pererabatyivaj smyisl zaprosa v samostoyateljnoye utverzhdeniye dokumentacii, a ssyilki na proiskhozhdeniye ostavlyaj v nizhnikh spravochnyikh razdelakh.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000038 -->
- Razdelyi `Источники требований`, `Источники`, `Опорные документы`, `Опорные материалы`, `Внешний материал`, `Затронутая документация` i analogichnyiye spravochnyiye bloki proiskhozhdeniya razmesjhayutsya vnizu fajla posle osnovnogo soderzhaniya, no pered sluzhebnyim blokom `FUM-MD-RECENCY`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000039 -->
- Pri sozdanii novogo fajla v `Документация/`, `Вопросы/`, `Вопросы и ответы/`, `Планирование/`, `Журнал/`, `Описания/`, `Оценки/`, `Ревью/`, `Сбои/`, `Глоссарий/`, `Инструменты/`, `Прототипы/`, `Проекты/` ili pri redaktirovanii susjhestvuyusjhego proizvodnogo Markdown-fajla agent dolzhen sokhranyatj takuyu strukturu: snachala soderzhaniye dokumenta, zatem spravochnyiye razdelyi s istochnikami i opornyimi materialami.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000040 -->
- Markdown-tablicyi v proizvodnyikh dokumentakh po umolchaniyu oformlyayutsya v stile avtoformatirovaniya Obsidian: kolonki vyiravnivayutsya probelami po shirine samogo dlinnogo soderzhimogo, stroka razdelitelya tozhe rastyagivayetsya po shirine kolonok, a krajniye i vnutrenniye `|` ostayutsya vizualjno vyirovnennyimi v iskhodnike. Takoj format schitayetsya osnovnyim; agent ne dolzhen szhimatj tablicyi do minimaljnogo Markdown-vida, yesli net otdeljnoj prichinyi ili trebovaniya vneshnego generatora.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000041 -->
- Lokaljnyiye Markdown-ssyilki na fajlyi repozitoriya dolzhnyi sovpadatj s fakticheskim registrom kazhdogo komponenta puti. Ssyilki, kotoryiye rabotayut toljko na nechuvstviteljnoj k registru fajlovoj sisteme, schitayutsya oshibkoj i dolzhnyi ispravlyatjsya do kommita.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000042 -->
- Kornevoj `README.md` yavlyayetsya kratkoj instrukciyej tekusjhego ispoljzovaniya FUM, a ne khronikoj progressa, polnyim perechnem prototipov ili tematicheskim indeksom. On soderzhit rovno odin vidimyij razdel `## Как использовать FUM сейчас`, pryamuyu vidimuyu ssyilku na `Документация/README.md`, ne soderzhit razdela `## Документация по темам` i vmeste so sluzhebnyim blokom svezhesti ne prevyishayet `12 000` Unicode-simvolov. Yego soderzhateljno obnovlyayut toljko pri izmenenii nablyudayemogo poljzovateljskogo scenariya, susjhestvennoj granicyi tekusjhej formyi ili osnovnyikh marshrutov vkhoda.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000043 -->
- Polnyij tematicheskij indeks nomernyikh dokumentov khranitsya v `Документация/README.md`: yedinstvennyij razdel `## Документация по темам` napryamuyu pokryivayet vse `Документация/NN-*.md` i `Документация/NN-*/README.md`. Razdeleniye kornevoj instrukcii i polnogo indeksa proveryayet `Инструменты/fum-indeks-readme/scripts/check-readme-index.py`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000128 -->
- [Proizvodnyiye strukturirovannyiye materialyi](../../Glossarij/proizvodnaya-dokumentaciya.md) o FUM razmesjhayutsya v `Документация/`; terminologicheskiye statji razmesjhayutsya v `Глоссарий/`.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000179 -->
- Dokumentaciya ssyilayetsya na iskhodnyiye zaprosyi kak na istochniki trebovanij.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000180 -->
- Fajl iskhodnogo zaprosa soderzhit ssyilki na fajlyi, na kotoryiye etot zapros povliyal.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000242 -->
- Yesli izmeneniye odnovremenno vliyayet na povedeniye repozitoriya i na opisaniye FUM, obnovlyaj kornevoj `AGENTS.md` i vse primenimyiye kanonicheskiye fajlyi v `Правила/агентов/` dlya povedeniya, a otdeljnyij fajl v `Документация/` — dlya opisaniya FUM.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 13:45:05 MSK -->
<!-- content-sha256: sha256:c9f4f0233661d821a8a722e6af62e0070ec92711c4340eae3451a1f69b2da5d2 -->
<!-- FUM-MD-RECENCY:END -->
