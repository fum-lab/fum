# Otchyot 2026-07-23 10:44:00 MSK - Avtomatizirovatj obnovleniye ssyilok pri smene statusa kartochki

Ruchnoye pereimenovaniye kartochki shaga boljshe ne dolzhno ostavlyatj v pamyati FUM ssyilki na ischeznuvshij putj. Planovyij kontur poluchayet odnu komandu, kotoraya vyipolnyayet Git-pereimenovaniye i v tom zhe zapuske algoritmicheski perenosit vse zhivyiye tekstovyiye upominaniya na novoye imya.

## Rezuljtat

Avtomatizaciya `fum-reyestr-planirovaniya` rasshirena komandoj smenyi statusa ili opisateljnogo imeni kartochki. Ona nakhodit kartochku po neizmenyayemomu `card_id`, proveryayet dopustimyiye staryij i novyij puti, obnovlyayet mashinnyij status, indeks i tekstovyiye predstavleniya, a sam fajl perenosit cherez `git mv`.

Pered perenosom komanda gotovit novyiye versii i rezervnyiye kopii vsekh izmenyayemyikh fajlov. Oshibka atomarnoj ustanovki otkatyivayet uzhe zamenyonnyiye fajlyi i Git-perenos; nedostupnyij vetochnyij selektor ili dublikat `card_id` zakryivayet operaciyu yesjhyo na preflight.

Doslovnyij tekst iskhodnogo zaprosa i syiryiye vneshniye materialyi ne perepisyivayutsya. Eto sokhranyayet proiskhozhdeniye dannyikh i odnovremenno ustranyayet bityiye ssyilki v zhivyikh spravochnyikh razdelakh, selektorakh i proizvodnyikh mashinnyikh fajlakh.

## Proverka

Regressionnaya fikstura vosproizvodit smenu `🟡` na `✅`, dva istoricheskikh spiska zatronutyikh fajlov, obyichnuyu i zaklyuchyonnuyu v uglovyiye skobki Markdown-celj, mashinnuyu zapisj puti i prezhnij putj vnutri doslovnogo zaprosa. Test trebuyet, chtobyi vse zhivyiye vkhozhdeniya poluchili novyij putj, iskhodnyij blok sokhranilsya pobajtno, a Git raspoznal perenos kak pereimenovaniye; otdeljnyiye scenarii vnedryayut sboj ustanovki i proveryayut nedostupnyij selektor i neotslezhivayemyij dublikat.

## Zatronutyiye materialyi

- [pravila rabochej sessii](../../AGENTS.md)
- [termin «kartochka shaga»](../../Glossarij/kartochka-shaga.md)
- [kontrakt planovogo reyestra](../../Instrumentyi/fum-reyestr-planirovaniya/SKILL.md)
- [indeks kartochek shagov](../../Planirovaniye/kartochki-shagov/README.md)
- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ad80dae544f4e77ff0e9bfc7feab67bd1359dda1c9fb6ac9cad8fc5d997f5fe2 -->
<!-- FUM-MD-RECENCY:END -->
