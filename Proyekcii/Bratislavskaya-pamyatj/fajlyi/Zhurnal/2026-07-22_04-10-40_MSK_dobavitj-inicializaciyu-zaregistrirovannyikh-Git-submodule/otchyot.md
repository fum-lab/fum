# Otchyot 2026-07-22 04:10:40 MSK - Dobavitj inicializaciyu zaregistrirovannyikh Git submodule

Posle svezhego klonirovaniya FUM zaregistrirovannaya Git-zavisimostj vosstanavlivayetsya odnoj proveryayemoj komandoj. Avtomatizaciya beryot URL forka i originala iz otslezhivayemyikh `url` i `fumUpstream`, tochnuyu reviziyu — iz gitlink, poluchayet oba remote, perevodit submodule v chistyij detached HEAD i zatem primenyayet tot zhe avtonomnyij kontrakt, chto i rezhim `check`.

## Rezhim inicializacii

Novyij CLI-vkhod `init --repo-root <корень> --path <путь>` namerenno ne prinimayet `fork-url`, `upstream-url` ili `revision`. Do setevoj i lokaljnoj mutacii on trebuyet obyichnyij UTF-8-fajl `.gitmodules`, sovpadayusjhij s Git-indeksom, rovno po odnomu nepustomu `path`, `url` i `fumUpstream`, gitlink rezhima `160000` i stage `0`, a takzhe dopustimuyu topologiyu repozitoriyev, rabochego puti i Git-kataloga submodule.

Nematerializovannyij zaregistrirovannyij submodule inicializiruyetsya po tochnomu puti toljko pri otsutstvii ostatochnogo `.git/modules/<name>`; susjhestvuyusjhiye komponentyi puti dolzhnyi byitj obyichnyimi katalogami bez simvolicheskikh ssyilok. U susjhestvuyusjhej kopii zaraneye proveryayutsya svyazannyij `.git`-fajl, tochnyiye Git-dir i common-dir vnutri superproject, otsutstviye shallow-rezhima i lokaljnyikh izmenenij, yedinstvennyij tochnyij `origin`, otsutstviye lishnikh remote, standartnyiye fetch refspec i tochnostj uzhe susjhestvuyusjhego `upstream`. Otsutstvuyusjhij `upstream` dobavlyayetsya iz `fumUpstream`; zatem vyipolnyayutsya `fetch --prune` oboikh remote, detached checkout gitlink bez perezapisi ignoriruyemyikh fajlov i obsjhij avtonomnyij validator. Povtornyij tochnyij zapusk sokhranyayet toljko `origin` i `upstream` i prokhodit bez konflikta.

## Granica primenimosti

Rezhim primenim toljko k odnomu yavno vyibrannomu verkhneurovnevomu submodule, uzhe zaregistrirovannomu v otslezhivayemoj `.gitmodules`. On mozhet obrasjhatjsya k seti, no ne sozdayot novuyu zavisimostj, ne menyayet `.gitmodules` ili gitlink, ne vyibirayet novuyu reviziyu po vershinam remote, ne sinkhroniziruyet fork i ne inicializiruyet proizvoljnuyu vlozhennuyu iyerarkhiyu. Rodstvo i publikaciya forka, yego sinkhronizaciya s originalom, licenziya, dostupnostj i publikacionnaya dopustimostj ostayutsya otdeljnyimi vneshnimi predposyilkami; zavershayusjhij `check` po-prezhnemu avtonomen.

Raskhodyasjhayasya s indeksom, neodnoznachnaya ili ne-UTF-8 `.gitmodules`, lokaljnaya podmena URL, otsutstvuyusjhiye `fumUpstream` ili gitlink, nebezopasnyij putj, ostatochnyij ili chuzhoj Git-katalog, gryaznaya libo shallow-kopiya, lishnij remote, nestandartnyij refspec i nevernyij susjhestvuyusjhij `upstream` ostanavlivayut rezhim bez molchalivogo izmeneniya raskhodyasjhegosya sostoyaniya. Chastichnyij setevoj otkaz mozhet ostavitj tochnyij vosstanovlennyij `upstream`, lokaljnyij URL materializuyemogo submodule i uzhe poluchennyiye lokaljnyiye refs; rezhim namerenno ne tranzakcionen, a povtornyij zapusk bezopasno prodolzhayet tot zhe kontrakt.

## TDD i proverki

Do izmeneniya prokhodili prezhniye `15/15` avtonomnyikh testov. Krasnaya faza dobavila scenarii svezhego `clone --recurse-submodules`, obyichnogo klonirovaniya bez materializacii, CLI i otslezhivayemogo `fumUpstream`; rasshirennyij nabor ozhidayemo poluchil `1 failure` i `3 errors` iz-za otsutstvuyusjhego `init`. Otdeljnyij krasnyij test vyiyavil ranneye ispoljzovaniye lokaljno podmenyonnogo `submodule.<name>.url`; realizaciya poluchila predvariteljnyij zakryivayusjhij kontrolj do materializacii.

Avtonomnyiye vremennyiye bare-repozitorii proveryayut vosstanovleniye `upstream`, polucheniye i prune refs oboikh remote, vyibor starogo gitlink vmesto novoj vershinyi remote, obyichnyij clone bez `--recurse-submodules`, idempotentnostj, gryaznuyu kopiyu, netochnyij susjhestvuyusjhij `upstream`, raskhozhdeniye i stroguyu kratnostj `.gitmodules`, lokaljnuyu podmenu URL, refspec, bezopasnyij rabochij putj, kanonicheskij Git-katalog i zasjhitu ignoriruyemogo fajla. Nezavisimoye revjyu podtverdilo i pomoglo zakryitj ranniye mutacii cherez linked worktree, simvolicheskiye ssyilki, ostatochnyij Git-katalog, fajl v komponente puti, ustarevshuyu remote-tracking vetku i nekorrektnyij UTF-8. Itogovyij nabor proshyol `40/40`; vneshnyaya setj i sekretyi testam ne nuzhnyi.

Planovyij reyestr proshyol `19/19` testov, build i validate. Fakticheskij LinguisticKit proshyol avtonomnyij `check`; vetochnyij validator i fenced `show` podtverdili novyij `master-fum-step-0033-ready-v1`. Recency, graf Obsidian, svyaznostj sessii i `git diff --check` proshli otdeljno, a yedinyij smoke-check zavershil vse `36/36` shagov, vklyuchaya testyi, sborku i primenimyij lint SwiftPM.

## Sostoyaniye planirovaniya

`FUM-STEP-0034` zavershena i perevedena v istoricheskuyu formu s rezuljtatom i granicej primenimosti. Vyipolnennyij `master-fum-step-0034-ready-v1` udalyon iz rabochego nabora. `FUM-STEP-0035` sokhranena kak `blocked` s prezhnim usloviyem vozobnovleniya; yedinstvennyim novyim `ready` vyibrana `FUM-STEP-0033` so svezhim `master-fum-step-0033-ready-v1`.

## Zatronutyiye materialyi

- [avtomatizaciya Git-zavisimostej](../../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md)
- [pasport zavisimostej FUM](../../Zavisimosti/README.md)
- [vosproizvodimyiye avtomatizacii FUM](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [vyipolnennaya kartochka FUM-STEP-0034](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0034-dopolnitj-fum-proverka-git-zavisimostej-rezhimom-inicializacii-uzhe-zaregistrirovannyikh-submodule-posle-svezhego-klonirovaniya-FUM.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](zapros.md)
- [iskhodnyij zapros o klonirovanii vneshnikh repozitoriyev](../2026-07-21_11-06-43_MSK_zakrepitj-klonirovaniye-vneshnikh-repozitoriyev/zapros.md)
- [sessiya pervogo podklyucheniya LinguisticKit](../2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6bb1d8551312f40e0c037d883090a6cbfda14bbbde23e88959d81dc903475876 -->
<!-- FUM-MD-RECENCY:END -->
