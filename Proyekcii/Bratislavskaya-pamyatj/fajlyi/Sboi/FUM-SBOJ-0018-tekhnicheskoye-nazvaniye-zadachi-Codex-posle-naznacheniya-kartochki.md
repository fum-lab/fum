+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0018"
"статус" = "устранена"
+++
# Tekhnicheskoye nazvaniye zadachi Codex posle naznacheniya kartochki

Zadacha Codex mogla sokhranitj tekhnicheskoye nazvaniye prodolzheniya ili vetki posle togo, kak yeyo tochnaya soderzhateljnaya rabota uzhe byila dokazana. Teperj kanonicheskoye pravilo i oba aktivnyikh prompt-kontura trebuyut smyislovoye nazvaniye do soderzhateljnoj rabotyi, ne smeshivaya interfejsnyij zagolovok s polnomochiyami marshruta.

## Nablyudayemyij sboj

Aktivnyiye kartochechnyiye zadachi, nazvannyiye poljzovatelem, pokazyivali ustojchivuyu formu `FUM-STEP-NNNN — <краткое содержательное название>`, togda kak inaya zadacha mogla ostavatjsya «Prodolzhitj rabotu vetki master». Tekhnicheskij zagolovok skryival fakticheski ispolnyayemuyu kartochku i zatrudnyal razlicheniye paralleljnyikh sessij.

## Granica povtoreniya

Proyavleniye voznikayet posle dokazannogo naznacheniya rabotyi, yesli vidimoye nazvaniye prodolzhayet opisyivatj vetku, slot, FIFO ili sam fakt prodolzheniya vmesto soderzhaniya zadachi. Dlya exact `ready` istochnikami imeni yavlyayutsya toljko `card_id` i `title` selektora. Pryamoj zapros, read-only-zadacha, recenzent ili integrator bez kartochki poluchayut kratkoye russkoye smyislovoye nazvaniye bez pridumannogo `FUM-STEP`.

Syuda ne otnositsya [FUM-SBOJ-0016](FUM-SBOJ-0016-drejf-live-prompt-universaljnogo-dispetchera.md): on opisyivayet snyatyij heartbeat-kontur i drejf yego live-prompt. Nazvaniye tekusjhej zadachi yavlyayetsya izmenyayemoj interfejsnoj proyekciyej i nikogda ne sluzhit dokazateljstvom identichnosti, marshruta, dopuska ili prava Git-perekhoda.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                                                                                                                                              | Effekt                                                                          | Vosstanovleniye                                                                                                      |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `FUM-СБОЙ-0018/ПРОЯВЛЕНИЕ-0001` | [Iskhodnyij zapros](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/zapros.md) sopostavil zadachu s tremya soderzhateljno nazvannyimi aktivnyimi kartochechnyimi zadachami. | Paralleljnuyu sessiyu prikhodilosj raspoznavatj po tekhnicheskomu prodolzheniyu vetki. | Zakrepitj moment i format imenovaniya v pravilakh, generated prompts, navyike vyibora shaga i reyestre host-instrumentov. |

## Mekhanizm i sistemnoye ustraneniye

Host predostavlyal `set_thread_title`, no pravila ne zadavali obyazateljnyij moment vyizova i istochnik teksta. Roditelj ordinary-prodolzheniya namerenno ne znayet budusjhuyu kartochku do handoff, poetomu on ne dolzhen ugadyivatj imya rebyonka. Novaya zadacha snachala vyipolnyayet obyazateljnyij marshrut i dopusk; posle exact `branch-next-step.py show` s `ready` ona sostavlyayet `FUM-STEP-NNNN — <краткое содержательное название>` iz tochnyikh polej otveta i lishj zatem nachinayet soderzhateljnuyu rabotu.

Generated prompt ordinary-prodolzheniya, prompt worktree-naznacheniya, centraljnyiye pravila i lokaljnyiye navyiki soglasovanyi. Dlya naznacheniya bez dokazannoj kartochki prompt trebuyet kratkoye russkoye nazvaniye i pryamo zapresjhayet pridumyivatj nomer. Neodnoznachnyij host-otvet avtomaticheski ne povtoryayetsya, a neudacha interfejsnogo dejstviya ne sozdayot Git-polnomochij.

## Svyazannyiye shagi

Otdeljnaya kartochka shaga ne sozdavalasj: pervoye proyavleniye, sistemnaya mera i regressionnoye dokazateljstvo zavershenyi v odnoj rabochej sessii.

## Kriterii zakryitiya

- Exact `ready` privodit k nazvaniyu iz `card_id`, dlinnogo tire i `title` do ispolneniya kartochki.
- Naznacheniye bez exact kartochki poluchayet kratkoye russkoye soderzhateljnoye imya bez vyidumannogo identifikatora.
- Imenovaniye ne vyipolnyayetsya ranjshe obyazateljnogo pervogo marshruta i primenimogo dopuska.
- Pravila i generated prompts pryamo fiksiruyut, chto zagolovok ne dokazyivayet marshrut ili dopusk.
- Kontrakt host-instrumenta i otsutstviye otdeljnogo title-readback otrazhenyi v sistemnom reyestre.

## Podtverzhdeniye ustraneniya

Tekusjhaya zadacha posle dopuska poluchila smyislovoye nazvaniye «Praviljnyiye nazvaniya sessij Codex». Dva RED-testa snachala podtverdili otsutstviye trebovaniya v ordinary- i worktree-prompt, a posle pravki proshli; staticheskaya proverka takzhe podtverdila soglasovannostj `AGENTS.md` i dvukh lokaljnyikh navyikov.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/zapros.md)
- [otchyot tekusjhej rabochej sessii](../Zhurnal/2026-08-14_18-46-19_MSK_imenovatj-sessii-Codex-i-ignorirovatj-izmeneniya-Obsidian-pri-starte/otchyot.md)
- [pravila rabochikh sessij](../AGENTS.md)
- [kontrakt ocheredi i worktree-pula](../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [navyik vyibora sleduyusjhego shaga](../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [reyestr sistemnyikh prilozhenij i instrumentov](../Instrumentyi/reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [generated prompt ordinary-prodolzheniya](../Instrumentyi/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py)
- [regressionnyiye testyi ocheredi](../Instrumentyi/fum-ocheredj-zadach-git-vetki/tests/test_ocheredj_zadach_git_vetki.py)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-14 19:17:13 MSK -->
<!-- content-sha256: sha256:506fe14bcd1083528168aca810241c7aefe6853954ace8ff45df405fa551ae94 -->
<!-- FUM-MD-RECENCY:END -->
