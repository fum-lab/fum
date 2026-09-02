# Otchyot 2026-07-20 22:05:19 MSK - Sdelatj povtornoye arkhivirovaniye istochnika atomarnyim

Povtornoye arkhivirovaniye odnogo ChatGPT share URL boljshe ne smeshivayet fajlyi prezhnego i novogo snimkov. Avtomatizaciya `fum-request-materials` stroit novyij rezuljtat otdeljno, proveryayet yego tochnyij manifest i toljko zatem celikom ustanavlivayet kanonicheskij katalog.

## Resheniya

- Kazhdyij snimok sobirayetsya v skryitom sosednem staging-kataloge na toj zhe fajlovoj sisteme.
- `snapshot-manifest.json` skhemyi `fum.request-materials.snapshot-manifest.v1` perechislyayet vse upravlyayemyiye fajlyi, vklyuchaya sebya; ustanovka razreshena toljko pri tochnom sovpadenii perechnya s fakticheskim soderzhimyim.
- Pervyij snimok ustanavlivayetsya atomarnyim pereimenovaniyem, a povtornyij ispoljzuyet `RENAME_SWAP` na macOS ili `RENAME_EXCHANGE` na Linux.
- Yesli atomarnyij obmen katalogov nedostupen, povtor zakryivayetsya do izmeneniya kanonicheskogo snimka. Rezervnaya dvukhshagovaya skhema s vremenno otsutstvuyusjhim kanonicheskim putyom namerenno ne ispoljzuyetsya.
- Oshibka do ustanovki ostavlyayet prezhnij snimok pobajtno neizmennyim. Posle uspeshnogo obmena novyij snimok uzhe schitayetsya zafiksirovannyim; ochistka prezhnego staging vyipolnyayetsya best-effort, a oshibka svyazyivaniya fajla zaprosa vyivoditsya otdeljnyim preduprezhdeniyem.

## TDD

Iskhodnyiye 15 testov proshli do izmeneniya realizacii. Krasnaya faza dobavila skvoznyiye posledovateljnosti `полный снимок -> неполный снимок` i `полный снимок -> поздний сбой генерации`: prezhnij kod ne sozdaval manifest i uspeval chastichno perezapisatj kanonicheskij katalog.

Posle pervoj zelyonoj realizacii nezavisimoye revjyu obnaruzhilo neatomarnyij rezervnyij putj cherez dva pereimenovaniya. Novyij krasnyij test potreboval fail-closed pri nedostupnom atomarnom obmene, a pozdnij generator stal proveryatj staryiye bajtyi pryamo vo vremya staging. Yesjhyo odin krasnyij test otdelil post-commit oshibku ssyilki ot uzhe uspeshno ustanovlennogo snimka. Finaljnyiye krasnyiye proverki zakrepili atomarnuyu zapisj samogo fajla zaprosa, preduprezhdeniye ob ostavshemsya starom staging i nezavisimostj osnovnogo nabora ot podderzhki exchange konkretnoj fajlovoj sistemoj. Itogovyij avtonomnyij nabor soderzhit 21 prokhodyasjhij test.

## Proverki

- `fum-request-materials`: 21 avtonomnyij test prokhodit bez seti i sekretov.
- Polnyij i zatem nepolnyij snimki ostavlyayut rovno fajlyi novogo `snapshot-manifest.json`; staryiye initial-state, script, decoded-data, messages i oformlennyij Markdown otsutstvuyut v kataloge, indekse i otchyote.
- Pozdnij sboj staging sokhranyayet prezhnij kanonicheskij katalog pobajtno, a nedostupnyij directory exchange zakryivayetsya bez backup-kataloga i bez zapisi.
- Atomarnaya zapisj ssyilki ne usekla fajl zaprosa pri inyyekcii sboya `os.replace`; ostavshijsya posle commit staryij staging vyivoditsya kak yavnoye preduprezhdeniye.
- Polnyij smoke-check proshyol vse 26 etapov bez seti i sekretov, vklyuchaya recency, graf Obsidian, svyaznostj sessii i proverki publikacionnoj chistotyi.

## Prodolzheniye

Sleduyusjhim ready-shagom `master` vyibrano vosstanovleniye obratnyikh ssyilok ot proizvodnoj dokumentacii k otkryityim i chastichno proyasnyonnyim voprosam s avtomaticheskoj proverkoj dvunapravlennosti v smoke-check.

## Zatronutyiye materialyi

- [proizvodnaya dokumentaciya ob avtomatizaciyakh](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [kontrakt fum-request-materials](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)
- [skript arkhivirovaniya](../../Instrumentyi/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py)
- [avtonomnyiye testyi](../../Instrumentyi/fum-materialyi-zaprosov/tests/test_archive_chatgpt_share.py)
- [MVP-kandidat arkhivatora](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [sleduyusjhij shag master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [revjyu proyekta 2026-07-18](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:7b1b1c9b0b2d3cb2096c18612052d3c8bcb690a4177eb23f36eafdad95eea339 -->
<!-- FUM-MD-RECENCY:END -->
