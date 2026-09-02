+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0017"
"статус" = "устранена"
+++
# Blokirovka starta zadachi izmeneniyami v kornevoj `.obsidian/`

Startovaya marshrutizaciya oshibochno schitala lokaljnoye sostoyaniye kornevogo `.obsidian/` obyichnoj gryazjyu pervichnogo checkout i otkazyivala novoj zadache do vyibora zakonnogo marshruta. Otdeljnyij startovyij predikat teperj isklyuchayet toljko etu tochnuyu kornevuyu oblastj, sokhranyayet yeyo bajtyi i ostavlyayet vse ostaljnyiye ograzhdeniya zakryityimi.

## Nablyudayemyij sboj

Pri izmenyonnom `.obsidian/graph.json` doverennaya komanda `маршрутизировать` vozvrasjhala `dirty_primary_bootstrap`, khotya dejstvuyusjheye pravilo uzhe isklyuchalo kornevoj `.obsidian/` iz obyichnoj chistotyi ocheredi. Iz-za otkaza zadacha ne mogla ni rezervirovatj nezavisimyij worktree-slot, ni prisoyedinitjsya k susjhestvuyusjhej linii bez vremennogo sokryitiya poljzovateljskogo sostoyaniya.

## Granica povtoreniya

Proyavleniye okhvatyivayet tri povtorno proveryayemyikh startovyikh perekhoda iz pervichnogo checkout: `маршрутизировать`, `зарезервировать-себя` i `присоединиться-к-линии`. Dopustimoye isklyucheniye sovpadayet toljko s kornevyim `.obsidian/` i vklyuchayet yego tracked-, staged- i untracked-sostoyaniye bez izmeneniya etikh bajtov. Vlozhennyij `путь/.obsidian/`, sosedneye imya i lyuboj inoj gryaznyij putj obyazanyi sokhranyatj `dirty_primary_bootstrap`.

Syuda ne otnositsya [FUM-SBOJ-0003](FUM-SBOJ-0003-obkhod-HEAD-bootstrap-pri-pervichnom-vkhode-v-FIFO.md): on opisyivayet ispolneniye nedoverennogo scenariya rabochego dereva vmesto zakommichennogo HEAD-bootstrap. Ne otnosyatsya takzhe strogiye terminaljnyiye proverki worktree, perekhod na cepochku, sbros, revjyu i integraciya — startovoye isklyucheniye na nikh ne perenositsya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                               | Effekt                                                                                   | Vosstanovleniye                                                                                     |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0017/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij zapros](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/zapros.md) utochnil prezhneye soglasheniye; adresnyij RED-test vosproizvyol `dirty_primary_bootstrap`. | Novaya zadacha blokirovalasj do marshruta iz-za yedinstvennogo izmeneniya nastrojki Obsidian. | Vvesti otdeljnuyu proverku chistotyi tryokh startovyikh perekhodov s tochnyim kornevyim pathspec-isklyucheniyem. |

## Mekhanizm i sistemnoye ustraneniye

Obsjhij predikat `рабочее_дерево_чисто` bez pathspec ispoljzovalsya i dlya starta, i dlya strogikh proverok zhiznennogo cikla slota. Yego globaljnoye oslableniye zatronulo byi materializaciyu, dopusk, osvobozhdeniye, revjyu i integraciyu. Poetomu obsjhij predikat sokhranyon, a toljko tri startovyikh vyizova perevedenyi na otdeljnuyu pobajtovuyu proverku `git status --porcelain=v1 -z` s `:(top,exclude).obsidian` i `:(top,exclude).obsidian/**`.

Povtornyiye ograzhdeniya rezervirovaniya i prisoyedineniya ostayutsya samostoyateljnyimi: obyichnaya gryazj, poyavivshayasya posle snimka marshruta, zakryivayet perekhod do lyuboj CAS-zapisi. Kornevoye sostoyaniye Obsidian pri tekh zhe perekhodakh ostayotsya neizmennyim.

## Svyazannyiye shagi

Otdeljnaya kartochka shaga ne sozdavalasj: pervoye proyavleniye, sistemnaya mera i regressionnoye dokazateljstvo zavershenyi v odnoj rabochej sessii.

## Kriterii zakryitiya

- Marshrutizaciya, rezervirovaniye, dopusk i prisoyedineniye prokhodyat pri odnovremennyikh tracked-, staged- i untracked-izmeneniyakh vnutri kornevogo `.obsidian/`.
- Polnyij `git status --porcelain=v1 -z` isklyuchyonnoj oblasti sovpadayet do i posle startovyikh perekhodov.
- Vlozhennyij `.obsidian/` i obyichnaya gryazj, voznikshaya mezhdu snimkom i rezervirovaniyem libo prisoyedineniyem, dayut `dirty_primary_bootstrap` bez bileta ili naznacheniya.
- Obsjhij strogij predikat chistotyi terminaljnyikh i rolevyikh worktree ne izmenyon.

## Podtverzhdeniye ustraneniya

Adresnyij test snachala vosproizvyol otkaz staroj realizacii, zatem tri scenariya kornevoj i nekornevoj granicyi proshli posle uzkoj pravki. Otdeljnyij test podtverdil povtornyiye proverki posle uzhe poluchennogo snimka i otsutstviye ozhidayusjhego bileta pri otkaze prisoyedineniya.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/otchyot.md)
- [pravila rabochikh sessij](../AGENTS.md)
- [kontrakt ocheredi i worktree-pula](../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [realizaciya worktree-pula](../Instrumentyi/fum-ocheredj-zadach-git-vetki/scripts/pul-worktree-poduzlov.py)
- [regressionnyiye testyi worktree-pula](../Instrumentyi/fum-ocheredj-zadach-git-vetki/tests/test_pul_worktree_poduzlov.py)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 19:17:13 MSK -->
<!-- content-sha256: sha256:48d940ec7366d57dad9d2141fe21f6354ab2c0e0c6c941929f65d0502828d669 -->
<!-- FUM-MD-RECENCY:END -->
