# Zhurnal i proiskhozhdeniye

Eti pravila polnostjyu chitayutsya do registracii zaprosa, izmeneniya navigacii zhurnala ili fiksacii proiskhozhdeniya rabochej sessii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000114 -->
- Kazhdyij [iskhodnyij poljzovateljskij zapros](../../Glossarij/iskhodnyij-zapros.md), vliyayusjhij na proyekt, poluchayet sobstvennuyu [papku zaprosa](../../Glossarij/papka-zaprosa.md) `Журнал/<YYYY-MM-DD_HH-MM-SS_MSK>_<краткое-название-запроса>/`. Imya papki yavlyayetsya identichnostjyu zapisi i obyazateljno nachinayetsya s tochnogo kanonicheskogo vremennogo prefiksa `YYYY-MM-DD_HH-MM-SS_MSK`; suffiks posle nego sleduyet tem zhe pravilam, po kotoryim prezhde imenovalsya fajl zaprosa. U rannego istoricheskogo zaprosa bez kratkogo nazvaniya papka mozhet sostoyatj iz odnogo tochnogo vremennogo prefiksa. Vnutri papki obyazateljnyij `запрос.md` khranit doslovnyij pervichnyij tekst, `отчёт.md` khranit otchyot tekusjhej rabochej sessii, a prinadlezhasjhiye toljko etomu zaprosu artefaktyi razmesjhayutsya v `материалы/` po soderzhateljnyim podpapkam. Istoricheskiye zaprosyi, sozdannyiye do vvedeniya otdeljnogo zhurnala, ne poluchayut vyimyishlennyij `отчёт.md` zadnim chislom.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000116 -->
- Kanonicheskiye karkasyi novyikh `запрос.md` i `отчёт.md` khranyatsya v [shablone zaprosa](../../Instrumentyi/fum-struktura-papok-zaprosov/shablonyi/zapros.md.shablon) i [shablone otchyota](../../Instrumentyi/fum-struktura-papok-zaprosov/shablonyi/otchyot.md.shablon). Komanda `start` obyazana do pervoj zapisi zakryito proveritj tochnyij nabor i odnokratnostj polej, obyazateljnyiye razdelyi, aktivnostj karkasa, poryadok zagolovkov i vyiravnivaniye tablic, a zatem odnoprokhodno zapolnitj imenno eti fajlyi; samostoyateljnoye dublirovaniye karkasa v generatore ne dopuskayetsya. Sozdannaya zagotovka sokhranyayet mashinnyij marker `<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->` v kazhdom trebuyusjhem zaversheniya smyislovom bloke, a proverka svyaznosti zapresjhayet etot marker vne doslovnogo teksta zaprosa do kommita. Avtonomnyiye testyi ispoljzuyut te zhe khranimyiye shablonyi i dopolniteljno peredayut sgenerirovannyij rezuljtat nezavisimyim proverkam svyaznosti. Zavershyonnyiye istoricheskiye zaprosyi i otchyotyi ne perepisyivayutsya radi vyiravnivaniya s tekusjhim shablonom.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000118 -->
- Pered sozdaniyem papki rabochej sessii poluchaj paru `prefix` i `label` odnim zapuskom `python3 Инструменты/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py --format both`. Suffiks `_MSK` vsegda oznachayet vremya zonyi `Europe/Moscow` (UTC+3), nezavisimo ot lokaljnoj zonyi khosta; zapresjheno podstavlyatj lokaljnyiye nastennyiye chasyi sredyi ili vruchnuyu pereschityivatj ikh bez yavnoj vremennoj zonyi. Znacheniye `prefix` bez izmenenij ispoljzuyetsya v imeni papki zaprosa i svyazannyikh vremennyikh identifikatorakh, a sootvetstvuyusjheye `label` — v zagolovkakh i tekstovyikh ssyilkakh.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000119 -->
- Posle vremennogo prefiksa `YYYY-MM-DD_HH-MM-SS_MSK` v imeni papki zaprosa zapisyivayetsya korotkoye nazvaniye zaprosa, analogichnoye zagolovku soobsjheniya kommita. Korotkoye nazvaniye nachinayetsya s glagola v infinitive, formuliruyet dejstviye rabochej sessii i pishetsya v kebab-case; vnutri `запрос.md` tot zhe zagolovok povtoryayetsya v pervoj stroke zagolovka.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000121 -->
- K zaprosam, vliyayusjhim na proyekt, otnosyatsya ne toljko pryamyiye prosjbyi izmenitj dokumentaciyu ili kod, no i voprosyi, utochneniya, proverki tekusjhej praktiki i otvetyi poljzovatelya, iz kotoryikh sleduyet resheniye o pravilakh vedeniya [pamyati FUM](../../Glossarij/pamyatj-FUM.md), khranenii istochnikov, sostave artefaktov ili poryadke [rabochej sessii](../../Glossarij/rabochaya-sessiya.md). Takiye soobsjheniya tozhe doslovno sokhranyayutsya v `запрос.md` tekusjhej papki zaprosa, dazhe yesli proizvodnaya pravka ogranichivayetsya `AGENTS.md`, otchyotom ili sluzhebnyim poyasneniyem.
  Sokhranyayetsya kazhdoye upravlyayusjheye soobsjheniye, vklyuchaya utochneniye i otvet na vopros agenta, v iskhodnom poryadke bez obyyedineniya odinakovyikh povtorov. Soderzhateljnyij otvet na kazhdoye soobsjheniye sokhranyayetsya v `отчёт.md` s yavnoj svyazjyu s komandoj: prinyatoye resheniye, oblastj obyazateljstva, vyipolnennoye dejstviye i ostavshayasya rabota. Novaya komanda dopolnyayet tekusjhuyu zapisj i ne stirayet raneye prinyatyiye ogranicheniya. Vo vremya rabotyi chuzhogo pisatelya ili proverki neizmennosti yego snimka zapisj vedyotsya v sobstvennom worktree; do yego vyideleniya — v razreshyonnom chernovike vne checkout. Perenos v obsjhij Zhurnal i perestrojka obsjhej navigacii vyipolnyayutsya lishj pri otsutstvii konkuriruyusjhej zapisi v celevom dereve.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-НОВОЕ-000010 -->
- Tekusjhij dialog vosstanavlivayetsya iz JSONL imenno kornevoj zadachi po yeyo `Codex-Thread-ID`: pered prodolzheniyem posle szhatiya ili razryiva chitayutsya pervichnyiye poljzovateljskiye soobsjheniya i vidimyiye soderzhateljnyiye otvetyi, zatem sveryayutsya s Zhurnalom i dejstvuyusjhimi pravilami. Chitayetsya toljko zavershyonnyij prefiks strok; poryadok i povtornyiye soobsjheniya sokhranyayutsya, a kursor s granicej bajtov i khyeshem prefiksa predotvrasjhayet propusk i povtornyij import. Izmenivshijsya prefiks trebuyet sverki, a nedostupnyij iskhodnik yavno otmechayetsya i ne zamenyayetsya vyidumannoj rekonstrukciyej. Sistemnyiye i developer-instrukcii, skryityiye rassuzhdeniya, soobsjheniya subagentov i syiroj vyivod instrumentov ne eksportiruyutsya kak poljzovateljskij dialog. Polnyij lokaljnyij JSONL i kursor ostayutsya vne publichnogo checkout; v Zhurnal perenosyatsya publikacionno dopustimyiye komandyi i soderzhateljnyiye otvetyi. Svodka pomogayet navigacii, no ne zamenyayet pervichnyiye tekstyi; otklyucheniye avtomaticheskogo szhatiya sredyi ne obesjhayetsya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000192 -->
- V kazhdom `запрос.md` podderzhivayetsya razdel `## Навигация по запросам` so ssyilkami na predyidusjhij i sleduyusjhij zaprosyi v khronologicheskom poryadke imyon soderzhasjhikh ikh papok.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000193 -->
- Pri dobavlenii novogo zaprosa avtomatizaciya strukturyi papok zaprosov dobavlyayet v yego `запрос.md` ssyilku na predyidusjhij zapros i ukazyivayet, chto sleduyusjhego zaprosa poka net; v prezhnem poslednem `запрос.md` ona obnovlyayet ssyilku na sleduyusjhij zapros.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000194 -->
- Novyiye trebovaniya oformlyayutsya tak, chtobyi byila vidna cepochka: zapros -> proizvodnaya dokumentaciya -> kommit.

## Istochnik tekusjhego utochneniya

- [Upravlyayusjhiye komandyi tekusjhej zadachi](../../Zhurnal/2026-09-07_22-11-38_MSK_sostavitj-plan-uskoreniya-proyekcii/zapros.md).

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 23:04:16 MSK -->
<!-- content-sha256: sha256:e1dfcc19fc34b53986a9759bf7dba9a2c8d3ad7f0c51afc3c97a46ba1139b6f4 -->
<!-- FUM-MD-RECENCY:END -->
