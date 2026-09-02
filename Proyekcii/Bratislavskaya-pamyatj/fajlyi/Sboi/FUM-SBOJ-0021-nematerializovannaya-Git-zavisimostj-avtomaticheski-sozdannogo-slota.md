+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0021"
"статус" = "устранена"
+++
# Nematerializovannaya Git-zavisimostj avtomaticheski sozdannogo slota

Avtomaticheski sozdannyij worktree-slot prezhde poluchal tochnyiye vetku, ocheredj i dopusk, no ostavlyal zaregistrirovannyij Git submodule nematerializovannyim. Lokaljnaya materializaciya iz proverennogo submodule osnovnoj rabochej kopii teperj vkhodit v readback slota i zavershayetsya do vyipuska sostoyaniya `prepared`.

## Nablyudayemyij sboj

Zhivoj marshrutizator sozdal `Подузлы/слот-0007`, potomu chto slotyi `0001`–`0006` byili zanyatyi, i dopustil tekusjhuyu zadachu v novyij worktree. V nyom `git submodule status` vernul prefiks `-` dlya `Зависимости/LinguisticKit`, katalog zavisimosti ostalsya pustyim, a polnyij smoke-check ostanovilsya na otsutstvii `Зависимости/LinguisticKit/Package.swift`.

## Granica povtoreniya

K kartochke otnositsya vyideleniye ili pereispoljzovaniye worktree-slota na vershine s zaregistrirovannyim verkhneurovnevyim gitlink, kogda pul podtverzhdayet toljko vneshnij linked worktree i ne sozdayot otdeljnyij kanonicheskij Git-katalog submodule etogo slota. Obsjhaya mera — avtonomnaya materializaciya vsekh zaregistrirovannyikh gitlink iz tochnyikh lokaljnyikh istochnikov osnovnoj rabochej kopii do readback i dopuska.

Syuda ne otnosyatsya svezhij obyichnyij clone FUM vne pula, yavnaya setevaya komanda `init` navyika proverki Git-zavisimostej, otsutstvuyusjhij libo izmenyonnyij lokaljnyij istochnik i proizvoljnaya vlozhennaya rekursiya submodule. Eti sostoyaniya imeyut otdeljnyiye predusloviya i pri avtomaticheskom vyidelenii slota zakryivayutsya otkazom bez setevoj podmenyi.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                     | Effekt                                                                                 | Vosstanovleniye                                                                                               |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0021/ПРОЯВЛЕНИЕ-0001` | [Otchyot rabochej sessii](../Zhurnal/2026-08-14_19-25-10_MSK_avtomatizirovatj-dobavleniye-slotov-dlya-novyikh-sessij/otchyot.md#obnaruzhennyij-i-ustranyonnyij-sboj) fiksiruyet novyij slot, prefiks `-` i otkaz smoke-check. | Novyij slot formaljno dopusjhen, no ne sposoben sobratj FUM i projti avtonomnuyu priyomku. | Dobavlenyi lokaljnoye klonirovaniye, kanonizaciya topologii i TDD-granica do podtverzhdeniya materializacii slota. |

## Ozhidaniye i klassifikaciya

FUM-STEP-0148 i FUM-REQ-0036 trebuyut, chtobyi lenivo vyidelennyij slot byil izolirovannoj rabochej liniyej, prigodnoj dlya ispolneniya. Dopusk worktree bez obyazateljnoj zaregistrirovannoj zavisimosti narushal uzhe dejstvuyusjheye ozhidaniye i yavlyalsya nedorabotkoj pula, a ne vneshnim setevyim sboyem: tochnaya zavisimostj uzhe byila dostupna lokaljno v osnovnoj rabochej kopii.

## Mekhanizm i sistemnoye ustraneniye

Prezhnij putj vyipolnyal toljko `git worktree add`, pereklyucheniye na novyij ref i readback vneshnikh `HEAD`, worktree i vetki. Obyichnyij `git status` schitayet nematerializovannyij gitlink chistyim, poetomu otsutstviye submodule ne prepyatstvovalo perekhodu naznacheniya v `prepared`.

Sistemnoye ustraneniye do sozdaniya worktree razbirayet `.gitmodules` i exact gitlink vyibrannoj vershinyi, trebuyet chistyij, detached, nepoverkhnostnyij i kanonicheski nastroyennyij lokaljnyij istochnik na toj zhe revizii, a posle pereklyucheniya sozdayot otdeljnyij Git-katalog pod `.git/worktrees/<слот>/modules/...`. `GIT_NO_LAZY_FETCH`, zapret `extensions.partialClone`, promisor remote, `alternates` i promisor-pack zakryivayut neyavnoye setevoye chteniye yesjhyo do proverki chistotyi i dostizhimosti. Klonirovaniye i perenos ssyilok slezheniya dopuskayut toljko lokaljnyij fajlovyij transport s otklyuchyonnoj globaljnoj konfiguraciyej Git; posle etogo vosstanavlivayutsya zaregistrirovannyiye URL i refspec, vyibirayetsya exact detached gitlink i proveryayutsya chistota, topologiya, dostizhimostj i otsutstviye lokaljnogo puti v konfiguracii slota. Otsutstvuyusjhij, netochnyij ili chastichnyij istochnik ostavlyayet naznacheniye v `materializing`, ne sozdayot ocheredj i ne obrasjhayetsya k zaregistrirovannomu setevomu URL.

Perekhodnyij clone stroitsya vne kanonicheskogo Git-kataloga i ustanavlivayetsya tuda atomarno; otdeljnaya atomarnaya zapisj `.git`-ukazatelya pozvolyayet povtoru zavershitj materialization posle poteri otveta mezhdu fazami. Povtornoye ispoljzovaniye slota zaraneye karantiniruyet toljko proverennyij chistyij ostatok zavisimosti i poetomu podderzhivayet perenos, udaleniye, smenu imeni sekcii i zamenu gitlink fajlom, katalogom ili simvolicheskoj ssyilkoj bez vechnogo sostoyaniya `materializing`. Atomarnoye namereniye pereklyucheniya pozvolyayet exact povtoru prinyatj toljko dokazannuyu smesj starogo i novogo dereva posle avarii do libo posle obnovleniya `HEAD`; nesovpavshiye bajtyi, postoronnij putj, neizvestnyij marker ili kollizionnoye `.fum-*`-imya zakryivayut vosstanovleniye. Terminaljnyiye proverki pered fiksaciyej i osvobozhdeniyem yavno otmenyayut `submodule.<имя>.ignore=all`, chtobyi skryitaya gryaznaya zavisimostj ne byila poteryana pri peredache fizicheskogo slota.

## Svyazannyiye shagi

| Kartochka shaga                                                                                                                                                                                              | Svyazj                                                                                                | Osnovaniye                       |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------- |
| [FUM-STEP-0148 — Organizovatj paralleljnyiye sessii v izolirovannyikh worktree-poduzlakh](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0148-organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-worktree-poduzlakh.md) | Zakreplyayet iskhodnoye ozhidaniye prigodnogo lenivo materializuyemogo slota; otdeljnyij novyij shag ne nuzhen. | `FUM-СБОЙ-0021/ПРОЯВЛЕНИЕ-0001` |

## Kriterii zakryitiya

- Fikstura s nedostupnyimi zaregistrirovannyimi URL sozdayot novyij slot i avtonomno poluchayet exact detached submodule iz lokaljnogo istochnika.
- Git-katalog submodule prinadlezhit tochnomu worktree slota, ne razdelyayet indeks i `HEAD` s osnovnoj rabochej kopiyej i sokhranyayet toljko kanonicheskiye `origin` i `upstream`.
- Otsutstvuyusjhij lokaljnyij istochnik zakryivayet materializaciyu do `git worktree add`, ostavlyayet naznacheniye bez ocheredi i ne pyitayetsya ispoljzovatj zaregistrirovannyij transport.
- Lokaljnyij istochnik s attached `HEAD`, dazhe na exact gitlink, zakryivayet materializaciyu do sozdaniya worktree i ocheredi.
- Partial/promisor-istochnik zakryivayetsya do proverok, sposobnyikh vyizvatj lazy fetch; vse Git-vyizovyi pula otklyuchayut lenivuyu setevuyu dozagruzku.
- Poterya otveta posle atomarnoj ustanovki Git-kataloga, no do zapisi `.git`-ukazatelya vosstanavlivayet to zhe naznacheniye bez vtorogo kanonicheskogo clone.
- Pereimenovaniye, udaleniye, smena imeni sekcii i zamena gitlink fajlom, katalogom ili simvolicheskoj ssyilkoj pri povtornom ispoljzovanii togo zhe slota ne ostavlyayut gryaznyij katalog, konfliktuyusjhij Git-katalog ili sluzhebnyij ostatok.
- Poterya otveta do ili posle obnovleniya `HEAD` vosstanavlivayet tochnuyu smesj bajtov starogo i novogo dereva, vklyuchaya uzhe karantinirovannyij gitlink, zamenyonnyij simvolicheskoj ssyilkoj.
- `ignore=all` ne skryivayet izmenyonnuyu zavisimostj ot fiksacii rezuljtata i osvobozhdeniya slota.
- Polnyij nabor testov ocheredi i worktree-poduzlov i avtonomnyij validator realjnoj zavisimosti prokhodyat posle izmeneniya.

## Podtverzhdeniye ustraneniya

Krasnaya fikstura snachala vosproizvela pustoj katalog submodule novogo slota, a finaljnoye revjyu — propusjhennyij attached `HEAD` istochnika na exact gitlink. Posle izmeneniya adresnyiye fiksturyi podtverdili avtonomnyij uspeshnyij putj, zakryityiye otkazyi dlya otsutstvuyusjhego, attached- i partial/promisor-istochnikov, avarijnoye vosstanovleniye do i posle obnovleniya vershinyi, yavnuyu vidimostj gryaznoj zavisimosti i povtornoye ispoljzovaniye slota posle perenosa, udaleniya, smenyi imeni sekcii i zamenyi gitlink fajlom libo simvolicheskoj ssyilkoj. Finaljnyij discovery pula zavershil `244` testa za `668,883 с`. Realjnyij `Зависимости/LinguisticKit` v `слот-0007` proshyol avtonomnuyu proverku na revizii `837e2ce107b97ee7b9d3344c9fe99142281fe393`.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-14_19-25-10_MSK_avtomatizirovatj-dobavleniye-slotov-dlya-novyikh-sessij/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-14_19-25-10_MSK_avtomatizirovatj-dobavleniye-slotov-dlya-novyikh-sessij/otchyot.md)
- [kontrakt pula worktree-poduzlov](../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [kontrakt proverki Git-zavisimostej](../Instrumentyi/fum-proverka-git-zavisimostej/SKILL.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 12:38:11 MSK -->
<!-- content-sha256: sha256:a08708346f4308e9e00afd43d7c2dedea2f52a54f5eabe85b5dcf879eb2a42de -->
<!-- FUM-MD-RECENCY:END -->
