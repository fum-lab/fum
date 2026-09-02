# Zavisimosti FUM

Vneshniye Git-zavisimosti FUM khranyatsya kak Git submodule iz postoyannogo forka ryadom s aktualjnyim GitHub-repozitoriyem FUM. `.gitmodules` fiksiruyet publikacionno dopustimyij URL forka i vosproizvodimyij URL originaljnogo `upstream`, a osnovnoj Git-repozitorij fiksiruyet tochnyij gitlink.

## LinguisticKit

LinguisticKit podklyuchyon dlya kanonicheskoj transliteracii russkikh smyislovyikh nazvanij [avtomatizacij FUM](../Glossarij/avtomatizaciya-FUM.md) i celevoj [bratislavskoj versii pamyati FUM](../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md):

- fork i `origin`: `https://github.com/fum-lab/LinguisticKit.git`;
- original i `upstream`: `https://github.com/Roman-Kerimov/LinguisticKit.git`;
- vyibrannaya reviziya: `837e2ce107b97ee7b9d3344c9fe99142281fe393`;
- licenziya vyibrannoj revizii: CC0 1.0 Universal;
- lokaljnyij putj: `Зависимости/LinguisticKit`.

Fork sinkhronizirovan s aktualjnoj vetkoj `master`, no gitlink namerenno sokhranyayet raneye proverennuyu sovmestimuyu reviziyu. Obnovleniye forka ne menyayet kontrakt transliteracii avtomaticheski: perekhod na druguyu reviziyu oformlyayetsya otdeljnoj migraciyej imyon i etalonov.

Avtonomnyij kontrakt submodule proveryayet [avtomatizaciya Git-zavisimostej](../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md). Zhivoye povedeniye paketa proveryayet [reyestr nazvanij avtomatizacij](../Instrumentyi/reyestr-nazvanij-avtomatizacij.json) cherez Swift-obyortku.

Zakreplyonnaya upstream-reviziya vyichislyayet katalog paketa v `LinguisticKitBuildTool` cherez kompilyacionnyij literal `#filePath`. Etot vspomogateljnyij ispolnyayemyij produkt ne yavlyayetsya runtime-zavisimostjyu FUM, a yego lokaljnyiye sborochnyiye rezuljtatyi ostayutsya v isklyuchyonnom iz Git kataloge `.build` i ne publikuyutsya. Istoriyu submodule neljzya ispravlyatj lokaljnoj pravkoj v obkhod forka: ustraneniye ogranicheniya trebuyet otdeljnogo kommita v forke ili originaljnom upstream, proverki novoj revizii i yavnoj migracii gitlink osnovnogo repozitoriya.

## Posle svezhego klonirovaniya FUM

Obyichnaya inicializaciya submodule vosstanavlivayet `origin` iz `.gitmodules`, no ne sozdayot lokaljnyij remote `upstream`. Posle `git clone` s `--recurse-submodules` ili bez nego do polnogo smoke-check nuzhno vyipolnitj:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init \
  --repo-root . \
  --path Зависимости/LinguisticKit
```

Komanda vyivodit URL forka i originala iz yedinstvennyikh otslezhivayemyikh `url` i `fumUpstream` v `.gitmodules`, a reviziyu — iz gitlink tekusjhego Git-indeksa. Ona do materializacii proveryayet obyichnyij UTF-8-fajl metadannyikh, komponentyi rabochego puti i kanonicheskij Git-katalog submodule, pri neobkhodimosti materializuyet vyibrannyij putj, proveryayet ili vosstanavlivayet tochnyij `upstream`, poluchayet oba remote s prune, bezopasno vyibirayet gitlink v detached HEAD i zavershayet avtonomnoj proverkoj vsej lokaljnoj topologii. Povtornyij tochnyij zapusk dopustim.

Rezhim primenim toljko k odnomu yavno ukazannomu uzhe zaregistrirovannomu verkhneurovnevomu submodule. On mozhet obrasjhatjsya k seti, no ne sozdayot novuyu zavisimostj, ne menyayet `.gitmodules` ili gitlink, ne vyibirayet novuyu reviziyu po vershinam remote i ne sinkhroniziruyet fork. Raskhodyasjhayasya s indeksom ili neodnoznachnaya `.gitmodules`, otsutstvuyusjhiye `fumUpstream` ili gitlink, lokaljnaya podmena URL, nebezopasnyij putj ili Git-katalog, gryaznaya zavisimostj, shallow-klon, lishniye remote, nestandartnyij fetch refspec i nevernyij susjhestvuyusjhij `upstream` ostanavlivayut inicializaciyu bez perepisyivaniya raskhodyasjhegosya sostoyaniya. Rodstvo, sinkhronizaciya i publikaciya forka, licenziya i publikacionnaya dopustimostj proveryayutsya otdeljno.

## Istochniki

- [iskhodnyij zapros 2026-08-05 18:12:35 MSK — Sozdatj bratislavskuyu versiyu pamyati](../Zhurnal/2026-08-05_18-12-35_MSK_sozdatj-bratislavskuyu-versiyu-pamyati/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)
- [iskhodnyij zapros 2026-07-22 04:10:40 MSK](../Zhurnal/2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK](../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)
- [arkhivirovannyij originaljnyij repozitorij](../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [arkhivirovannaya vyibrannaya reviziya](../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 18:28:33 MSK -->
<!-- content-sha256: sha256:f367df37e4817b1093e7c241e7b8963550019040ce3dd0f07ca1ec8c10c414c7 -->
<!-- FUM-MD-RECENCY:END -->
