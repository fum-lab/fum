# Otchyot 2026-07-21 10:36:18 MSK - Zavershitj skvoznuyu priyomku arkhivatora istochnikov

Pervyij reliz arkhivatora istochnikov FUM prinyat. Obyichnyij ustojchivyij HTML-URL prokhodit cherez obsjhij poljzovateljskij vkhod, poluchayet kanonicheskij publikacionno chistyij snimok i idempotentno obnovlyayetsya bez smesheniya pokolenij.

## Obsjhij vkhod i perenosimyij sloj

Kornevoj ispolnyayemyij `fum` poluchil komandu `source archive <url> --request <file>`. Ona peredayot rabotu modulyu `source_archive.py`, gde transport yavlyayetsya yavnoj zavisimostjyu, a vyichisleniye kanonicheskoj papki, sborka artefaktov, tochnyij manifest, atomarnaya ustanovka i svyazj s zaprosom ostayutsya odinakovyimi dlya production-zakhvata i avtonomnoj fiksturyi.

HTML-snimok khranit iskhodnyij URL, zagolovki s otredaktirovannyimi cookie, iskhodnyiye bajtyi tela, izvlechyonnyij vidimyij tekst, JSON-LD pri nalichii, indeks, otchyot i `snapshot-manifest.json`. Specializirovannyij `archive-chatgpt-share.py` sokhranil prezhnij CLI i glubokoye izvlecheniye rassharennyikh dialogov.

## Skvoznaya priyomka

Avtonomnyij subprocess-test vyizyivayet tot zhe poljzovateljskij vkhod dlya `https://fixture.invalid/articles/fum`. Versiya `v1` sozdayot vosemj tochno perechislennyikh fajlov, vklyuchaya `structured-data.json`; versiya `v2` atomarno obnovlyayet tu zhe papku semjyu fajlami bez ustarevshego strukturnogo sloya i ne dubliruyet ssyilki v zaprose. Failpoint `after-build` srabatyivayet posle polnoj proverki staging i do ustanovki, poetomu snimok `v2` ostayotsya pobajtno neizmennyim.

Fikstura soderzhit stabiljnyiye HTTP-zagolovki, HTML i testovyij cookie. Znacheniye cookie otsutstvuyet v publikuyemom snimke; test ne ispoljzuyet setj, sekretyi ili vneshnij servis.

## Publikacionnyiye i atomarnyiye granicyi

Dopolniteljnyiye TDD-regressii zakryili vyiyavlennyiye nezavisimyim revjyu riski. Query i fragment predstavlenyi v imeni papki toljko khyeshem, neodnoznachnaya ochistka path-segmenta poluchayet razlichayusjhij khyesh, a susjhestvuyusjhaya papka pered sborkoj i ustanovkoj sveryayetsya s tochnyim `source-url.txt`. Obsjhij i specializirovannyij vkhodyi razreshayut toljko HTTP(S) bez userinfo, ogranichivayut protokolyi redirekta `curl`, otklonyayut otsutstvuyusjhij fajl zaprosa do zakhvata i vyivodyat upravlyayemuyu oshibku bez traceback s URL. Vneshnij title ekraniruyetsya pered vstavkoj v Markdown.

## Planovyij rezuljtat

Checklist stadii `01` vyipolnen na `3 из 6`: vyibor MVP, yego pervyij reliz i obsjhij proverochnyij kontur podtverzhdenyi. Blizhajshim blokerom stala aktualizaciya vkhodnyikh opisanij, zatem ostayutsya pasport perekhodnogo sreza i otdeljnoye resheniye o nachale korobochnoj stadii.

Vyipolnennaya priyomka perenesena v istoriyu operativnyikh predlozhenij, prezhniye rangi 2 i 3 stali rangami 1 i 2. Zapisj `master` ukazyivayet na svezhij ready-shag `master-refresh-developer-entrypoints-v1` — aktualizirovatj vkhodnyiye opisaniya FUM. Claim tekusjhego zapuska ne osvobozhdalsya; pokoleniye smeneno novoj zapisjyu shaga.

## Proverki

- Fenced `show` iskhodnoj paryi projden do pervoj zapisi.
- Krasnaya faza zafiksirovala otsutstviye obsjhego `fum`; posle realizacii skvoznoj subprocess-scenarij stal zelyonyim.
- Vse `38` avtonomnyikh testov `fum-request-materials` proshli, vklyuchaya obsjhij CLI, legacy-sovmestimostj i publikacionnyiye granicyi.
- Nezavisimoye itogovoye revjyu ne obnaruzhilo blokiruyusjhikh defektov.
- Planovyij JSON-reyestr peresobran i validen; `19` testov `fum-planning-registry` proshli.
- `23` testa vyibora sleduyusjhego shaga proshli; novyij `master-refresh-developer-entrypoints-v1` podtverzhdyon fenced `show`, obsjhij validator vernul `state=valid`, a `git diff --check` ne obnaruzhil oshibok probelov.
- Proverka svyaznosti sessii i vse `29` shagov polnogo smoke-check proshli na itogovom sostave izmenenij.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [aktivnyij MVP arkhivirovaniya istochnikov](../../Planirovaniye/MVP-kandidatyi/02-arkhivirovaniye-prikreplyayemyikh-materialov/README.md)
- [kontrakt rabotyi s prikreplyayemyimi materialami](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:3654a24a6d8dc4f4b5b9edc44ca571ff64835a03c99d8cde39b42a5c1340cb0f -->
<!-- FUM-MD-RECENCY:END -->
