# Proveritj yadro kontejnera

Semj bazovyikh scenariyev proshli posle realizacii. Pervyij vyizov etogo ispolnitelya s tem zhe naborom vyiyavil ENOTDIR: Foundation sokrasjhal fizicheskij putj vremennogo kataloga do simvoljnogo komponenta `var`. Testovyij korenj teperj poluchayetsya cherez POSIX realpath. Vtoroj vyizov proshyol: sborka 1,60 s, semj testov 0,844 s po vyivodu SwiftPM. Polnuyu dliteljnostj processa khranit v4.

## Vosproizvodimyij vyizov

Iz kornya vneshnego repozitoriya:

```sh
swift test --package-path Packages/КонтейнерНаблюдений --build-system native --jobs 2 --filter СегментTests
```

Oba zapuska vyipolnenyi cherez lokaljnuyu obyortku FUM s klassom adresnaya i tajm-autom 120 s. Rabochij katalog obyortki — sobstvennoye FUM-derevo; znacheniye --package-path ukazyivalo na absolyutnyij putj naznachennogo paketa. Khyeshi ispyituyemyikh fajlov dlya uspeshnogo vyizova sokhranenyi v [snimke yadra](iskhodniki-yadra.json). V4 otpechatok FUM sam po sebe ne vklyuchayet otdeljnyij kodovyij repozitorij; etot snimok otdeljno svyazyivayet rezuljtat s kodom.

## Ostatok

Pryamoj zaklyuchiteljnyij dopusk kontroljnoj tochki vernul kod 1 iz-za istoricheskikh ssyilok na otsutstvuyusjhij v izolirovannom worktree ignoriruyemyij poljzovateljskij .obsidian/graph.json. Fajl ne sozdayotsya i poljzovateljskoye sostoyaniye ne kopiruyetsya. Otkaz ne obyyavlyayetsya uspekhom; po yavnoj granice pravila 000178 trebuyetsya proveritj ostaljnyiye diagnostiki. Dopusk vyipolnyayetsya vne tablicyi pryamyikh testov kak zaklyuchiteljnaya proverka kontroljnoj tochki soglasno 000188.

Rasshirennyiye regressii, profilj, resheniye ob optimizacii i dokumentaciya yesjhyo ne zavershenyi. Svyaznostj proveryayetsya v rezhime kontroljnoj tochki. Obsjhij smoke i proyekciya peredanyi planirovsjhiku; etot kommit ne yavlyayetsya ikh priyomkoj. Susjhestvuyusjheye pokoleniye Proyekcii sokhraneno iz bazovogo FUM-kommita ba6f1c7907478a638c9f0fda6d93f6da37a7fcf5 i otstayot ot novyikh zhurnaljnyikh fajlov; nezavisimo v etoj zadache ono ne proveryalosj.

## Istochniki

- [Iskhodnyiye komandyi i peredacha vladeniya](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 13:26:34 MSK -->
<!-- content-sha256: sha256:2fd2dc08d54f31a9a5b35f2d4d40062e15ae07df7b01146c02ca82e8a9b2439f -->
<!-- FUM-MD-RECENCY:END -->
