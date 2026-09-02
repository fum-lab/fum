# Iskhodnyij zapros

Iskhodnyij zapros - doslovno sokhranyonnyij poljzovateljskij zapros, kotoryij vliyayet na proyekt FUM. On khranitsya v fajle `запрос.md` sobstvennoj [papki zaprosa](papka-zaprosa.md) v `Журнал/` v originaljnom napisanii, bez perevoda, normalizacii, ispravleniya orfografii ili transliteracii.

Imya papki zaprosa sostoit iz moskovskogo vremeni zaprosa i korotkogo nazvaniya zaprosa v kebab-case: `YYYY-MM-DD_HH-MM-SS_MSK_<краткое-название-запроса>`. Vremennoj prefiks obyazatelen; u rannikh istoricheskikh zaprosov posle nego mozhet ne byitj kratkogo nazvaniya. Dlya novyikh zaprosov korotkoye nazvaniye stroitsya kak zagolovok soobsjheniya kommita: nachinayetsya s glagola v infinitive i kratko nazyivayet dejstviye rabochej sessii. To zhe korotkoye nazvaniye povtoryayetsya v pervoj stroke vlozhennogo `запрос.md` kak chelovekochitayemyij zagolovok zaprosa.

Iskhodnyij zapros yavlyayetsya pervichnyim istochnikom trebovaniya. [Proizvodnaya dokumentaciya](proizvodnaya-dokumentaciya.md) dolzhna ssyilatjsya na nego, chtobyi sokhranyalasj cepochka: zapros, opisaniye trebovaniya, izmeneniye fajlov i kommit.

V [dokumentacionnom prototipe FUM](dokumentacionnyij-prototip-FUM.md) iskhodnyij zapros sluzhit kontejnerom proiskhozhdeniya diskretnoj poljzovateljskoj zadachi i svyazannoj [rabochej sessii](rabochaya-sessiya.md). On ne yavlyayetsya minimaljnoj yedinicej budusjhego poljzovateljskogo vvoda: [korobochnaya realizaciya FUM](korobochnaya-realizaciya-FUM.md) mozhet nablyudatj razreshyonnyiye sobyitiya vo vremya aktivnogo [agentskogo cikla](agentskij-cikl.md), a resheniye o sokhranenii sobyitiya kak zaprosa, trebovaniya ili drugogo sloya pamyati prinimayetsya otdeljno.

Fajl iskhodnogo zaprosa takzhe khranit sluzhebnyij snimok [rabochej sessii](rabochaya-sessiya.md): navigaciyu po sosednim zaprosam, identifikator kornevogo seansa Codex, zatronutyiye fajlyi, proverki, opisaniye sdelannogo i razdel ispoljzovannyikh instrumentov. V razdele `## Идентификатор сеанса Codex` stroka `Codex-Thread-ID: <UUID>` fiksiruyet znacheniye `CODEX_THREAD_ID` kornevoj poljzovateljskoj zadachi, a ne dochernego subagenta. Odin seans Codex mozhet vklyuchatj neskoljko rabochikh sessij FUM, poetomu eto pole dopolnyayet, no ne zamenyayet vremennoj prefiks i imya papki zaprosa.

Razdel `## Использованные инструменты` svyazyivayet konkretnuyu sessiyu s [reyestrom sistemnyikh prilozhenij i instrumentov](reyestr-sistemnyikh-prilozhenij-i-instrumentov.md), chtobyi versii i ogranicheniya sredyi ne ischezali iz proiskhozhdeniya izmeneniya.

## Svyazannyiye dokumentyi

- [AGENTS.md](../AGENTS.md)
- [Papka zaprosa](papka-zaprosa.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Reyestr sistemnyikh prilozhenij i instrumentov](reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-14 02:31:47 MSK - Dobavlyatj identifikator seansa Codex](../Zhurnal/2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:01:26 MSK - Utochnitj sobyitijnuyu nepreryivnostj dokumentacionnogo prototipa FUM](../Zhurnal/2026-07-24_10-01-26_MSK_utochnitj-sobyitijnuyu-nepreryivnostj-dokumentacionnogo-prototipa-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:781e89a381327259b54eea4f53e8191e8cd36ea7742bca0b8d439eace6820629 -->
<!-- FUM-MD-RECENCY:END -->
