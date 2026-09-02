# Vneshniye Git-zavisimosti

Eti pravila polnostjyu chitayutsya do klonirovaniya, sinkhronizacii, registracii ili obnovleniya vneshnej Git-zavisimosti FUM.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000206 -->
- Do pervogo ispoljzovaniya vneshnego Git-repozitoriya kak zavisimosti FUM sozdayotsya ili podtverzhdayetsya yego postoyannyij fork ryadom s aktualjnyim GitHub-repozitoriyem FUM: v toj zhe organizacii libo v tom zhe individualjnom akkaunte, na kotoryij ukazyivayet publikacionnyij remote `origin` tekusjhej rabochej kopii FUM. Yesli GitHub-vladelec aktualjnogo FUM ne opredelyayetsya odnoznachno, dobavleniye zavisimosti zakryivayetsya do yavnogo resheniya. Originaljnyij repozitorij ne ispoljzuyetsya napryamuyu kak istochnik Git submodule; isklyucheniye vozmozhno toljko po otdeljnomu yavnomu poljzovateljskomu zaprosu, sokhranyonnomu kak istochnik resheniya.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000207 -->
- Fork u GitHub-vladeljca aktualjnogo FUM kloniruyetsya komandoj `git clone` v prednaznachennyij dlya zavisimosti lokaljnyij putj i nastraivayetsya kak remote `origin`, a originaljnyij repozitorij — kak otdeljnyij remote `upstream`. Soderzhimoye zavisimosti neljzya nachinatj ispoljzovatj po ssyilke, iz arkhiva, cherez vyiborochno skachannyiye fajlyi ili iz neuchtyonnogo vlozhennogo repozitoriya vmesto polnocennogo klona.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000208 -->
- Posle klonirovaniya i pered ispoljzovaniyem lokaljnaya kopiya yavno sinkhroniziruyetsya s oboimi istochnikami cherez `git fetch origin` i `git fetch upstream`, posle chego vyibirayetsya i proveryayetsya nuzhnaya reviziya. Vyibrannyij kommit do registracii zavisimosti dolzhen byitj opublikovan i dostizhim iz forka ryadom s aktualjnyim FUM; Git submodule sam po sebe ne sleduyet za udalyonnoj vetkoj avtomaticheski.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000209 -->
- Proverennyij klon dobavlyayetsya v osnovnoj repozitorij kak Git submodule. Kommit osnovnogo repozitoriya fiksiruyet v `.gitmodules` publikacionno dopustimyij URL forka ryadom s aktualjnyim FUM, vosproizvodimyij URL `upstream` i gitlink na tochnyij dostizhimyij iz forka kommit; do etoj registracii klon ne schitayetsya podklyuchyonnoj zavisimostjyu FUM.

<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000210 -->
- Pered kommitom lokaljnaya avtomatizaciya `Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py` proveryayet GitHub-vladeljca aktualjnogo FUM, roli i URL `origin` i `upstream`, URL i putj submodule, dostizhimostj vyibrannogo kommita iz forka, tochnyij gitlink i chistotu lokaljnoj kopii; otdeljno proveryayutsya GitHub-liniya forka, licenziya, dostupnostj i publikacionnaya dopustimostj zavisimosti. Dlya publichno vosproizvodimogo FUM fork dolzhen klonirovatjsya bez sekretov. Izmeneniya zavisimosti snachala kommityatsya i publikuyutsya v forke; sinkhronizaciya s originalom prokhodit cherez `upstream`, zatem obnovlyonnoye sostoyaniye publikuyetsya v forke, i toljko posle etogo osnovnoj repozitorij otdeljnyim osmyislennyim izmeneniyem obnovlyayet gitlink. Trebovaniye publikacii zavisimosti ne rasshiryayet polnomochiya tekusjhej sessii: bez otdeljnogo yavnogo zaprosa poljzovatelya na push rabota zakryito ostanavlivayetsya do zavisyasjhego ot publikacii gitlink-kommita.

## Istochnik dekompozicii

- [iskhodnyij zapros 2026-08-24 15:31:12 MSK — Dekompozirovatj AGENTS MD](../../Zhurnal/2026-08-24_15-31-12_MSK_dekompozirovatj-AGENTS-md/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 16:13:37 MSK -->
<!-- content-sha256: sha256:4360e50071c489d98917fe11290d603dc0cebcdec45e0b36fd596e44b732b599 -->
<!-- FUM-MD-RECENCY:END -->
