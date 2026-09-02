# Otchyot 2026-07-21 05:39:00 MSK - Sdelatj sluzhebnyiye generatoryi vosproizvodimyimi

Sluzhebnyiye Markdown-avtomatizacii teperj vosproizvodimyi na odnom Git-snimke: kalendarnyij perekhod ne lomayet strukturnuyu proverku grafa, a sborochnyiye katalogi, lokaljnyiye zavisimosti i kyeshi ne vkhodyat v generatoryi ili globaljnyiye obkhodyi svyaznosti.

## Rezuljtat

Sozdan obsjhij modulj `fum-project-files`. V Git-repozitorii on otdeljno poluchayet otslezhivayemyiye Markdown-fajlyi i novyiye neignoriruyemyiye Markdown-fajlyi, a zatem primenyayet neizmenyayemuyu strukturnuyu granicu dlya `.build`, `.swiftpm`, katalogov kyeshej, `.obsidian/plugins` i `.obsidian/themes`. Lokaljnyij exclude ne skryivayet otslezhivayemyij dokument, a prinuditeljno otslezhivayemyij fajl vnutri isklyuchyonnogo kataloga ostayotsya vne proyektnogo inventarya.

`fum-md-recency` i `fum-obsidian-graph-recency` ispoljzuyut etot inventarj dlya vkhodov, a `fum-session-coherence` — dlya navigacii zaprosov, globaljnoj proverki ssyilok i voprosno-otvetnyikh materialov. Isklyuchyonnyij Markdown-fajl ne chitayetsya, ne indeksiruyetsya, ne perepisyivayetsya i ne mozhet zamaskirovatj otsutstvuyusjhuyu proyektnuyu celj ssyilki.

Teplovaya karta Obsidian khranit opornuyu datu v proyektnom sidecar-fajle `.obsidian/fum-recency-reference-date`. Obnovleniye prinimayet yavnyij `--today` libo sokhranyayet tekusjhuyu datu MSK, a proverka bez yavnoj datyi ispoljzuyet sokhranyonnoye znacheniye. Novyij kalendarnyij denj poetomu ne menyayet rezuljtat strukturnoj proverki neizmennogo snimka; novyij srez sozdayotsya osoznannyim obnovleniyem opornoj datyi.

## Bezopasnostj obkhodov

Obsjhij modulj rabotayet fail-closed. Simvolicheskaya ssyilka v lyubom komponente vkhodnogo ili vyikhodnogo puti, razresheniye za predelyi repozitoriya ili vnutrj isklyuchyonnogo khranilisjha, oshibka `os.walk` i skryito otsutstvuyusjhij otslezhivayemyij `skip-worktree`-fajl ostanavlivayut avtomatizaciyu. Kanonicheskiye indeks recency i `graph.json` proveryayutsya do chteniya ili zapisi.

Fajlovyij fallback ne sleduyet po simvolicheskim ssyilkam i primenyayet tu zhe strukturnuyu politiku. Flag `--no-git` v `fum-md-recency` otklyuchayet toljko Git-istoriyu dlya vyibora vremeni, no ne prevrasjhayet ignoriruyemyiye katalogi v proyektnyiye vkhodyi.

## TDD i revjyu

Do realizacii fiksturyi zafiksirovali kalendarnyij drejf i nezhelateljnuyu obrabotku `.build/checkouts/vendor/README.md`, `.swiftpm` i kyeshej vo vsekh tryokh potrebitelyakh. Zelyonaya faza dala 47 testov: 5 obsjhego fajlovogo sloya, 6 `fum-md-recency`, 7 `fum-obsidian-graph-recency` i 29 `fum-session-coherence`.

Nezavisimoye revjyu obnaruzhilo dopolniteljnyiye granichnyiye sluchai vokrug lokaljnogo `.git/info/exclude`, `--no-git`, simvolicheskikh ssyilok i oshibok obkhoda. Posle ikh pokryitiya i ispravleniya povtornoye revjyu ne nashlo susjhestvennyikh ostavshikhsya defektov i samostoyateljno podtverdilo vse 47 testov.

Pervyij polnyij smoke-check doshyol do shaga 28 i pokazal yesjhyo odnu sredovuyu granicu: otkryityij Obsidian udalil neznakomoye pole opornoj datyi iz `graph.json` pri sokhranenii sobstvennogo sostoyaniya. Yakorj perenesyon v otdeljnyij sidecar, a fikstura teperj imitiruyet Obsidian-round-trip grafa i podtverzhdayet sokhraneniye kalendarnogo kontrakta.

## Sostoyaniye Obsidian

Vo vremya rabochej sessii prilozheniye Obsidian izmenyalo ustojchivuyu nastrojku masshtaba grafa i povtorno sokhranyalo sobstvennyij JSON. Posledneye poljzovateljskoye znacheniye sokhranyayetsya kak sostoyaniye bez sekretov ili lokaljnyikh absolyutnyikh putej; generator poverkh nego peresobirayet cvetovyiye gruppyi, ne sbrasyivayet ostaljnyiye nastrojki i khranit opornuyu datu otdeljno.

## Prodolzheniye

Sleduyusjhim ispolnyayemyim shagom `master` vyibran `master-reconfirm-mvp-stage-exit-v1`: perepodtverditj yedinstvennyij aktivnyij MVP, zafiksirovatj yego skvoznoj acceptance-scenarij, opredelitj binarnyij kriterij vyikhoda dokumentacionnoj stadii i ranzhirovatj ne boleye tryokh blizhajshikh zadach. Eto perenosit ocheredj ot zakryitoj infrastrukturnoj nakhodki k vyiyavlennoj v revjyu neodnoznachnosti produktovogo napravleniya.

## Proverki

- Fenced `show` podtverdil iskhodnuyu paru `refs/heads/master` i `master-stabilize-service-generators-v1` do pervoj zapisi.
- 47 celevyikh avtonomnyikh testov prokhodyat bez seti i sekretov.
- Struktura novogo navyika `fum-project-files` sverena s kontraktom sistemnogo `skill-creator`; sam `quick_validate.py` v dostupnyikh Python-runtime ne startuyet iz-za otsutstvuyusjhego modulya `PyYAML`, chto zafiksirovano otdeljno ot obyazateljnogo green-kontura repozitoriya.
- Novaya zapisj sleduyusjhego shaga prokhodit `fum-branch-next-step validate`.
- `git diff --check` prokhodit.
- Polnyij `fum-smoke-check` prokhodit s tekusjhim zaprosom, podgotovlennyim soobsjheniyem kommita i kornevyim Codex-Thread-ID.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [revjyu proyekta 2026-07-18](../2026-07-18_07-44-15_MSK_provesti-revjyu-proyekta/materialyi/revjyu/2026-07-18_07-44-15_MSK_revjyu-proyekta.md)
- [vosproizvodimyiye avtomatizacii](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:76364ae5fa309b5148065dd5f4d23f947c6df695ae3753d78f2aed1f01753afc -->
<!-- FUM-MD-RECENCY:END -->
