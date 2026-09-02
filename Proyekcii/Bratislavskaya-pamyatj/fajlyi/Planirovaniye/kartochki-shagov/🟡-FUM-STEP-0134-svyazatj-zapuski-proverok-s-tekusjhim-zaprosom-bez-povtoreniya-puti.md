+++
schema_version = 1
card_id = "FUM-STEP-0134"
status = "active"
+++
# Svyazatj zapuski proverok s tekusjhim zaprosom bez povtoreniya puti

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj obyortke uchyota proverok shtatnyij sessionnyij marshrut, kotoryij odnoznachno svyazyivayet zapusk s tekusjhim kanonicheskim `запрос.md` po tochnomu kornevomu `CODEX_THREAD_ID` libo raneye proverennomu neprozrachnomu identifikatoru i ne trebuyet povtorno peredavatj dlinnyij svobodnyij putj v kazhdom vyizove.

## Pochemu sejchas

Predfinaljnoye obnovleniye grafa ne nachalosj iz-za odnoj lishnej bukvyi v vruchnuyu povtoryonnom komponente puti tekusjhego zaprosa. Obyortka praviljno otkazala do dochernego processa, no iz-za oshibochnogo puti ne mogla zapisatj samu popyitku v mashinnyij zhurnal nastoyasjhej sessii. Kopirovaniye praviljnoj stroki vosstanavlivayet khod toljko razovo.

## Kriterii zaversheniya

- Krasnaya avtonomnaya fikstura vosproizvodit tochnoye odnobukvennoye raskhozhdeniye FUM-SBOJ-0006 i podtverzhdayet otkaz do dochernego zapuska vmeste s otsutstviyem zapisi v zhurnale nastoyasjhej sessii.
- Novyij shtatnyij interfejs prinimayet kornevoj `CODEX_THREAD_ID` neposredstvenno iz sredyi libo raneye vyidannyij posle tochnoj proverki neprozrachnyij identifikator; svobodnyij putj tekusjhego zaprosa v obyichnom marshrute ne trebuyetsya.
- Privyazka skaniruyet toljko dopustimyij proyektnyij inventarj zaprosov, trebuyet rovno odin obyichnyij `Журнал/<папка>/запрос.md` s tochnyim identifikatorom i sokhranyayet yego kanonicheskij repozitorno-otnositeljnyij putj.
- Nulevoye ili mnozhestvennoye sovpadeniye, dochernij identifikator, simvoljnaya ssyilka, vyikhod za korenj i izmenivshayasya posle privyazki identichnostj zakryito otklonyayutsya do zapuska dochernego processa.
- Yavnyij `--запрос` ostayotsya dostupen dlya avtonomnyikh fikstur i istoricheskikh operacij toljko cherez yavno ograzhdyonnyij marshrut, kotoryij neljzya sluchajno vyibratj tekusjhej obyichnoj sessiyej.
- Nachaljnaya mashinnaya zapisj ustanavlivayetsya do dochernego processa pod najdennyim vladeljcem; poterya otveta i povtor s tem zhe identifikatorom ne sozdayut vtorogo sborsjhika libo zapisi zapuska.
- Migraciya sokhranyayet sovmestimostj zakryityikh istoricheskikh snimkov i ne perepisyivayet ikh puti, khyeshi ili Markdown-bloki.
- Avtonomnyiye testyi pokryivayut kirillicheskij putj, opechatku, otsutstviye i povtor identifikatora, gonku izmeneniya privyazki, yavnyij istoricheskij rezhim i shtatnyij uspeshnyij zapusk; obsjhij smoke-check prokhodit bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0006 — Opechatka puti tekusjhego zaprosa pri uchyote proverki](../../Sboi/FUM-SBOJ-0006-opechatka-puti-tekusjhego-zaprosa-pri-uchyote-proverki.md) — osnovaniye `FUM-СБОЙ-0006/ПРОЯВЛЕНИЕ-0001`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)
- [avtomatizaciya uchyota proverok](../../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:38:54 MSK -->
<!-- content-sha256: sha256:aaf91ad63ccb10b7edc76d920f40406846718a129c308f0f2fa8dc2bfd177c62 -->
<!-- FUM-MD-RECENCY:END -->
