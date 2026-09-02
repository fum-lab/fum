# Otchyot 2026-07-21 12:52:18 MSK - Zakrepitj forki Git zavisimostej v FUM lab

Dlya vneshnikh Git-zavisimostej zakreplena yedinaya upravlyayemaya tochka publikacii: postoyannyiye forki v organizacii `fum-lab`. Osnovnoj repozitorij FUM boljshe ne dolzhen ssyilatjsya sabmodulem neposredstvenno na originaljnyij upstream zavisimosti.

## Kontrakt istochnikov zavisimosti

Lokaljnaya kopiya zavisimosti kloniruyetsya iz forka `fum-lab`, kotoryij poluchayet rolj `origin`. Originaljnyij repozitorij sokhranyayetsya otdeljnyim `upstream` dlya sverki i perenosa obnovlenij. Pered registraciyej zavisimosti vyibrannyij kommit dolzhen byitj opublikovan i dostizhim iz forka; `.gitmodules` ukazyivayet na etot fork, a gitlink fiksiruyet tochnyij proverennyij kommit.

Proverka pered kommitom okhvatyivayet roli oboikh remote, URL i putj sabmodulya, dostizhimostj revizii, chistotu klona, licenziyu, vidimostj i publikacionnuyu dopustimostj. Izmeneniya zavisimosti i obnovleniya iz upstream snachala publikuyutsya v upravlyayemom forke, posle chego FUM otdeljnyim izmeneniyem obnovlyayet gitlink.

## Granica tekusjhej sessii

Konkretnyij repozitorij, putj i reviziya dlya podklyucheniya etim zaprosom ne naznachenyi, poetomu vneshnij fork i novyij submodule ne sozdavalisj. Zablokirovannyij zhivoj rezhim LinguisticKit ostayotsya otdeljnyim planovyim prodolzheniyem: snachala nuzhno sozdatj ili podtverditj yego fork v `fum-lab`, zatem podklyuchitj imenno etot istochnik i provesti uzhe zaplanirovannuyu migraciyu imyon.

Susjhestvuyusjheye predlozheniye ob avtomatizacii pervogo podklyucheniya rasshireno do polnoj cepochki `форк -> clone origin -> configure/fetch upstream -> verify publication -> submodule add`. Avtonomnyiye testyi budusjhego pomosjhnika dolzhnyi modelirovatj oba remote lokaljno bez seti, a vneshneye sozdaniye GitHub-forka ostayotsya yavno proveryayemoj predposyilkoj.

## Proverki

- Planovyij reyestr peresobran i validen; zapisj vetki podtverzhdayet tochnuyu paru `refs/heads/master` i `master-prepare-first-boxed-slice-passport-v3`.
- `.gitmodules` i gitlink otsutstvuyut, poetomu tekusjhij kommit ne maskiruyet nepodtverzhdyonnoye podklyucheniye zavisimosti.
- Recency, graf Obsidian i svyaznostj sessii prokhodyat; predfinaljnyij polnyij smoke-check zavershilsya rezuljtatom `33/33`.

## Zatronutyiye materialyi

- [pravila repozitoriya](../../AGENTS.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [sleduyusjhij shag vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros 2026-07-21 12:52:18 MSK](zapros.md)
- [predshestvuyusjheye pravilo klonirovaniya vneshnikh repozitoriyev](../2026-07-21_11-06-43_MSK_zakrepitj-klonirovaniye-vneshnikh-repozitoriyev/zapros.md)
- [otlozhennoye podklyucheniye LinguisticKit](../2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:440190982f874e5fe857b3a10bfa20ecb3ff49112d0dabfade207522a8d0d212 -->
<!-- FUM-MD-RECENCY:END -->
