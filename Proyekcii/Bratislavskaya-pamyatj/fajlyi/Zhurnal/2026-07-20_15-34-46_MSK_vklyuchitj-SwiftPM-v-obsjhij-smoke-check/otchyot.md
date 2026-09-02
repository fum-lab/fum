# Otchyot 2026-07-20 15:34:46 MSK - Vklyuchitj SwiftPM v obsjhij smoke check

Vtoroye zamechaniye `P1` poslednego revjyu ustraneno: obsjhij `fum-smoke-check` teperj proveryayet ne toljko Python-avtomatizacii, reyestryi i svyaznostj sessii, no i oba dejstvuyusjhikh SwiftPM-prototipa. Kazhdyij paket prokhodit avtonomnyiye testyi, a vse tri ispolnyayemyikh produkta sobirayutsya otdeljnyimi komandami.

## Resheniya

- Paketyi avtomaticheski obnaruzhivayutsya toljko po ustojchivyim tochkam `Прототипы/*/Package.swift`, poetomu `.build`, `.swiftpm` i tranzitivnyiye paketyi ne stanovyatsya samostoyateljnyimi vkhodami.
- Fakticheskiye produktyi i puti celej chitayutsya iz `swift package dump-package`, a ne izvlekayutsya regulyarnyim vyirazheniyem iz ispolnyayemogo Swift-manifesta; ozhidayemyiye paketyi i produktyi zakreplenyi v proveryayemom inventare.
- Lyubaya obyyavlennaya SwiftPM-zavisimostj otklonyayetsya do zapuska, poka dlya neyo ne zadan otdeljnyij vosproizvodimyij offline-kontrakt.
- Strogij `swift format lint` primenyayetsya s centraljnoj konfiguraciyej; `.swift-format-ignore` zapresjhyon, a paket fizicheskikh sostoyanij klavish prokhodit proverku bez isklyuchenij.
- Konfiguraciya ne soderzhit imyon pravil, otsutstvuyusjhikh v Swift 6.0; polnostjyu proverennyij snimok zafiksirovan na Swift 6.4 i Xcode 27.0 bez obesjhaniya odinakovoj semantiki raznyikh versij formattera.
- Dlya tenevogo redaktora zafiksirovano vremennoye vidimoye isklyucheniye vmesto massovogo formatiruyusjhego diff: prichina, kriterij snyatiya i SHA-256 iskhodnikov khranyatsya v JSON-politike, a lyuboye izmeneniye zasjhisjhyonnogo snimka ostanavlivayet proverku.
- Rekomendaciya o bezopasnom `--self-test` tochek zapuska s timeout ne smeshivalasj s etim shagom i ostayotsya otdeljnyim prodolzheniyem revjyu.

## Proverki

Snachala chetyire novyikh testa upali iz-za otsutstvuyusjhikh SwiftPM-kontraktov, zatem rasshirennyij nabor iz 14 testov `fum-smoke-check` proshyol. Obsjhij smoke-check vyipolnil 24 shaga: 93 Python-testa, 30 testov tenevogo redaktora, 21 test klaviaturnogo prototipa, tri otdeljnyiye sborki produktov, strogij lint klaviaturnogo paketa i proverku svyaznosti sessii. Planovyij reyestr, recency-metki, graf Obsidian i publikacionnaya chistota diff takzhe proverenyi.

## Prodolzheniye

Sleduyusjhij blokiruyusjhij punkt `P1` — sdelatj atomarnyiye kartochki `Требования/` kanonicheskim vkhodom mashinnogo planovogo reyestra so stabiljnyimi identifikatorami, statusami, kriteriyami i proveryayemyimi dvunapravlennyimi svyazyami. Otdeljno ostayotsya snyatj lint-isklyucheniye tenevogo redaktora cherez mekhanicheskuyu normalizaciyu vsego Swift-paketa bez smesheniya s funkcionaljnyimi izmeneniyami.

## Zatronutyiye materialyi

- [vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [obsjhij smoke-check](../../Instrumentyi/fum-kompleksnaya-proverka-repozitoriya/SKILL.md)
- [tenevoj redaktor prodolzhenij](../../Prototipyi/tenevoj-redaktor-prodolzhenij/README.md)
- [prototip fizicheskikh sostoyanij klavish](../../Prototipyi/fizicheskiye-sostoyaniya-klavish/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Istochniki

- [iskhodnyij zapros 2026-07-20 15:34:46 MSK](zapros.md)
- [revjyu proyekta 2026-07-18 07:44:15 MSK](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:a3dbdb8e837390869196b9951eb60939ad7830edd8cf64dc9d6133a79d0c729b -->
<!-- FUM-MD-RECENCY:END -->
