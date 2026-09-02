# Istochniki, opisaniya i materialyi

Eti pravila polnostjyu chitayutsya do importa istochnika, rabotyi s vlozheniyem ili adresnyim opisaniyem FUM.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000011 -->
- [Opisaniya FUM dlya adresatov](../../Glossarij/opisaniye-FUM-dlya-adresata.md) razmesjhayutsya v `Описания/` i stroyatsya na osnove `Документация/`, `Глоссарий/`, `Вопросы/`, `Вопросы и ответы/` i papok zaprosov v `Журнал/`, ne stanovyasj samostoyateljnyim istochnikom trebovanij.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000117 -->
- V `материалы/` fizicheski vkladyivayutsya toljko artefaktyi s odnim dokazannyim vladeljcem-zaprosom: naprimer, yego lokaljnoye vlozheniye bez ustojchivogo URL, snimok ocenki ili revjyu i sootvetstvuyusjhaya odnorazovaya konfiguraciya. Proizvodnaya dokumentaciya, glossarij, trebovaniya, voprosyi, planirovaniye, kod, prototipyi i kanonicheskiye URL-istochniki imeyut sobstvennuyu ustojchivuyu identichnostj ili mogut otnositjsya k neskoljkim zaprosam, poetomu ostayutsya v tematicheskikh katalogakh i svyazyivayutsya s papkoj zaprosa ssyilkami.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000120 -->
- Dlya zaprosov na import znanij iz rassharennyikh ili sokhranyonnyikh ChatGPT-dialogov korotkoye nazvaniye zaprosa vyibirayetsya posle pervichnogo chteniya ili izvlecheniya soderzhaniya dialoga i otrazhayet temu, tezis ili osnovnoj vklad dialoga, a ne toljko istochnik ili servis. Obsjhiye nazvaniya vrode `интегрировать-диалог-chatgpt`, `интегрировать-содержимое-chatgpt-диалога` ili `интегрировать-диалог-chatgpt-pro` dopuskayutsya toljko kak vremennyij fallback, yesli soderzhaniye dialoga nedostupno; prichinu fallback nuzhno zafiksirovatj v fajle zaprosa i zhurnale.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000127 -->
- Yesli takoj zapros soprovozhdayetsya skrinshotom, appshot-kontekstom ili drugim [prikreplyayemyim materialom](../../Glossarij/prikreplyayemyij-material.md), sam tekst zaprosa vsyo ravno sokhranyayetsya v `запрос.md`, a material otdeljno klassificiruyetsya po pravilam papki zaprosa, `Источники/`, publikacionnoj chistotyi i znachimosti dlya istochnika.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000133 -->
- [Opisaniya FUM dlya adresatov](../../Glossarij/opisaniye-FUM-dlya-adresata.md) razmesjhayutsya v `Описания/`; ustojchivyiye skhemyi ikh sborki i obnovleniya razmesjhayutsya v `Описания/Автоматизации/` kak vosproizvodimyiye [avtomatizacii FUM](../../Glossarij/avtomatizaciya-FUM.md).

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000135 -->
- Katalog `Прототипы/физические-состояния-клавиш/Локальные-данные-прогонов/` bazovo ostayotsya v `.gitignore`. Yesli iz zavershyonnogo progona delayetsya susjhestvennyij vyivod, vliyayusjhij na trebovaniya, dokumentaciyu, arkhitekturnoye resheniye, status ili priyomku, tot zhe kommit obyazan vklyuchatj publikacionno proverennyij minimaljno polnyij katalog imenno etogo seansa s `manifest.json` i `events.jsonl`; tochnyij putj dobavlyayetsya cherez `git add -f -- <путь-сеанса>`, a material s vyivodom ssyilayetsya na nego. Shiroko snimatj bazovoye isklyucheniye, dobavlyatj vesj katalog, ispoljzovatj `.incomplete-*` ili kommititj vyivod bez iskhodnyikh dannyikh neljzya. Yesli nabor ne prokhodit publikacionnuyu proverku, susjhestvennyij vyivod ne fiksiruyetsya do polucheniya publikacionno chistogo vosproizvodimogo progona.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000163 -->
- Skachivayemyiye istochniki i drugiye [prikreplyayemyiye materialyi](../../Glossarij/prikreplyayemyij-material.md) s ustojchivyim URL sokhranyayutsya v kanonicheskoj URL-papke `Источники/URL/<scheme>/<host>/<path...>/`: cepochka katalogov sootvetstvuyet skheme, domenu i puti URL v lokaljnoj pamyati. Povtornyiye zaprosyi na tot zhe URL ssyilayutsya na tu zhe papku istochnika, a ne sozdayut kopiyu. Yesli query ili fragment menyayut soderzhaniye istochnika, oni dobavlyayutsya k puti kak otdeljnyiye khyeshirovannyiye segmentyi bez raskryitiya vozmozhnyikh sekretov v imeni papki.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000164 -->
- Prikreplyayemyiye materialyi bez ustojchivogo URL i s odnim vladeljcem-zaprosom sokhranyayutsya v `Журнал/<имя-папки-запроса>/материалы/источники/<описательное-название>/`; imya papki zaprosa uzhe soderzhit tochnyij vremennoj prefiks, a vlozhennaya papka kratko opisyivayet istochnik. Material, kotoryij imeyet sobstvennuyu ustojchivuyu identichnostj ili otnositsya k neskoljkim zaprosam, ostayotsya v tematicheskom kataloge i svyazyivayetsya ssyilkami.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000165 -->
- `запрос.md` dolzhen soderzhatj ssyilku na prinadlezhasjhij zaprosu material libo kanonicheskuyu papku URL-istochnika i, kogda polezno, ssyilki na osnovnyiye izvlechyonnyiye fajlyi ili otchyot ob izvlechenii.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000166 -->
- Vneshniye ssyilki i drugiye materialyi s ustojchivyim URL sokhranyayutsya v `Источники/` maksimaljno syiro v predelakh publikacionnoj chistotyi; prinadlezhasjhiye odnomu zaprosu vlozheniya bez ustojchivogo URL tak zhe sokhranyayutsya v yego `материалы/`. Dlya oboikh klassov fiksiruyutsya dostupnyiye iskhodnyiye dannyiye, izvlechyonnyij tekst i otchyot ob izvlechenii, no cookie, tokenyi, lokaljnyiye IP, geometadannyiye zaprosa i drugiye sekretyi redaktiruyutsya pered kommitom.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:13:37 MSK -->
<!-- content-sha256: sha256:2936359d391ff17f892289c9595e9e31122abe685a0c551f0676404e5b4274b6 -->
<!-- FUM-MD-RECENCY:END -->
