# Otchyot 2026-07-22 03:38:35 MSK - Razreshitj vyipolneniye dostupnyikh kartochek shagov

Vetochnyij dispetcher boljshe ne ostanavlivayet vsyu avtomaticheskuyu rabotu iz-za odnoj nedostupnoj kartochki. Odin fajl vetki teperj khranit proveryayemyij rabochij nabor: maksimum odnogo gotovogo kandidata i neskoljko otlozhennyikh kandidatov s yavnyimi usloviyami vozobnovleniya.

## Ispravlennyij kontrakt

Skhema `3` perenosit `ready`, `paused` i `blocked` na otdeljnyiye kandidatnyiye zapisi. Kazhdaya zapisj zakreplyayet svoyu kartochku, tochnyij khyesh soderzhaniya i sobstvennyij `step_id`; `paused` i `blocked` dopolniteljno nazyivayut `resume_condition`. Validator proveryayet vesj nabor i otklonyayet neskoljko gotovyikh kandidatov, dublikatyi, povrezhdyonnyiye khyeshi i nepolnyiye otlozhennyiye zapisi. Posle etogo `show` i `claim` razreshayut yedinstvennogo `ready`, ne schitaya korrektnogo otlozhennogo kandidata prepyatstviyem.

V rabochem nabore `master` kartochka `FUM-STEP-0035` sokhranena kak `blocked` do otdeljnogo zaprosa o pasporte ili razresheniya korobochnoj stadii. Tekusjhij zapros etogo razresheniya ne dayot. Odnovremenno `FUM-STEP-0034` vyibrana kak `ready`, poetomu avtomaticheskij potok mozhet prodolzhitj nezavisimuyu lokaljno proveryayemuyu rabotu.

## Proverki

- Regressionnyiye testyi podtverzhdayut sovmestnoye susjhestvovaniye `ready` i `blocked`, obyazateljnostj usloviya vozobnovleniya, unikaljnostj identifikatorov i fail-closed-proverku otlozhennoj zapisi.
- Planovyij reyestr peresobran i validen.
- Vetochnyij `validate` prinimayet novyij nabor, a `show` vozvrasjhayet gotovuyu `FUM-STEP-0034`.
- Sluzhebnaya svezhestj, teplovaya karta Obsidian, svyaznostj sessii, `git diff --check` i polnyij smoke-check prokhodyat pered atomarnyim kommitom ocheredi.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d3800f4715fd7137bb9ef9956dd5bfe6620c8bd6d46a6cd6d3a9877c9084170e -->
<!-- FUM-MD-RECENCY:END -->
