+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0019"
"статус" = "устранена"
+++
# Zavisimostj repozitornogo testa selektora ot aktivnoj worktree-vetki

Repozitornaya fikstura kanonicheskogo selektora `master` vyizyivala rabochiye komandyi dlya fakticheskoj aktivnoj vetki. Poetomu polnyij smoke-check iz zakonnoj vremennoj linii worktree-pula lozhno ostanavlivalsya na korrektnom zakryitom otkaze.

## Nablyudayemyij sboj

Vo vremya polnogo smoke-check na vremennoj vetke iz prostranstva `refs/heads/codex/подузлы/` test `test_repository_has_a_valid_record_for_its_active_branch` ozhidal uspekh `validate` i `show`. Selektor zakonno otklonil vetku, potomu chto za nej ne zakreplena kartochka `Планирование/следующие-шаги-веток`.

## Granica povtoreniya

Proyavleniye voznikayet, kogda repozitornyij test sostava i vyibora shaga `master` zapuskayetsya iz checkout inoj vetki i skryito podmenyayet celj fakticheskim `symbolic-ref HEAD`. Rabochiye komandyi `validate` i `show` po-prezhnemu obyazanyi ispoljzovatj tochnuyu aktivnuyu vetku i zakryito otkazyivatj pri otsutstvii yeyo zapisi.

Syuda ne otnosyatsya [FUM-SBOJ-0017](FUM-SBOJ-0017-blokirovka-starta-zadachi-izmeneniyami-v-kornevoj-obsidian.md), kotoryij opisyivayet startovuyu chistotu, i [FUM-SBOJ-0018](FUM-SBOJ-0018-tekhnicheskoye-nazvaniye-zadachi-Codex-posle-naznacheniya-kartochki.md), kotoryij opisyivayet interfejsnoye nazvaniye zadachi.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                           | Effekt                                                   | Vosstanovleniye                                                                        |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0019/ПРОЯВЛЕНИЕ-0001` | [Otchyot tekusjhej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/otchyot.md) fiksiruyet otkaz shaga 14 polnogo smoke-check. | Polnaya priyomka worktree-rezuljtata ne mogla zavershitjsya. | Otvyazatj repozitornuyu fiksturu `master` ot tekusjhej vetki bez izmeneniya koda produkta. |

## Ozhidaniye i klassifikaciya

Polnyij smoke-check obyazan prokhoditj iz zakonnoj izolirovannoj worktree-linii. Lozhnaya neprimenimostj kanonicheskoj fiksturyi v takom checkout raskhodilasj s etim dejstvuyusjhim ozhidaniyem i yavlyayetsya nedorabotkoj testovoj granicyi, a ne vneshnim sboyem.

## Mekhanizm i sistemnoye ustraneniye

Fikstura namerenno proveryala tochnyiye kanonicheskiye chisla i vyibor dlya `refs/heads/master`, no poluchala zapisj cherez `active_record`. Teperj ona chitayet vse kartochki i zapisi, trebuyet rovno odnu zapisj `refs/heads/master`, proveryayet yeyo pul gotovnosti i vyibor na vershine `master`. Kod produkta i yego zakryitaya granica ne izmenenyi.

## Svyazannyiye shagi

Otdeljnaya kartochka shaga ne sozdavalasj: pervoye proyavleniye, ustojchivaya mera i yeyo polnaya testovaya proverka zavershenyi v toj zhe rabochej sessii.

## Kriterii zakryitiya

- Repozitornaya fikstura proveryayet rovno odnu zapisj `refs/heads/master` nezavisimo ot aktivnoj worktree-vetki.
- Proverki sostava `13/4/6/3` i vyibora `FUM-STEP-0124` versii `v8` sokhranenyi.
- Rabochiye komandyi ne poluchayut zapasnogo vyibora `master` i otkazyivayut neimenovannoj aktivnoj vetke.
- Adresnyij scenarij i polnyij nabor selektora prokhodyat iz vremennoj vetki worktree-pula.

## Podtverzhdeniye ustraneniya

Adresnaya fikstura proshla odin test, a polnyij nabor `fum-sleduyusjhij-shag-vetki` proshyol `186` testov s `34` ozhidayemyimi propuskami neposredstvenno iz tekusjhej vetki worktree-pula. Scenarii otkaza aktivnoj vetke bez zapisi ostalisj v tom zhe polnom nabore. Finaljnyij polnyij smoke-check zatem povtorno podtverdil etot nabor vnutri vsekh `77` uspeshnyikh shagov.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/otchyot.md)
- [testyi vyibora sleduyusjhego shaga](../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)
- [pravila rabochikh sessij](../AGENTS.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 23:17:06 MSK -->
<!-- content-sha256: sha256:94321537b0faf296a9815634029076f4891cf3565b2701b6dbe4c6b4a4b3c6ba -->
<!-- FUM-MD-RECENCY:END -->
