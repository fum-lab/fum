---
name: fum-sleduyusjhij-shag-vetki
description: Sokhranyatj istoricheskij selektor sleduyusjhego shaga vetki i yego regressionnyij kontrakt; posle manual-sequential-v1 obyichnyiye zadachi yego ne vyizyivayut.
---

# Sleduyusjhij shag vetki

## Dejstvuyusjhij status

Posle `manual-sequential-v1` vetochnyij selector ne yavlyayetsya dejstvuyusjhim marshrutom. Poljzovatelj vruchnuyu zapuskayet kazhduyu sleduyusjhuyu pishusjhuyu sessiyu s novyim soderzhateljnyim zaprosom; `create_thread`, continuation, heartbeat i avtomaticheskij vyibor kartochki ne vyizyivayutsya. Zasjhitnyij readback `branch-next-step.py show` vozvrasjhayet `done` s prichinoj `manual-sequential-v1`, a izmenyayusjhiye komandyi istoricheskogo selector fail-closed zapresjhenyi. Scenarij, naboryi i testyi nizhe sokhranenyi kak istoricheskaya narabotka i mogut snova statj aktivnyimi toljko otdeljnyim poljzovateljskim zaprosom i proverennyim izmeneniyem `AGENTS.md`.

Yedinstvennaya bridge-zadacha perekhodnogo kommita selector ne zapuskayet: posle `ack-head` i dopuska ona vyipolnyayet toljko `finish-clean` prezhnej FIFO.

## Istoricheskij kontrakt selektora

Sleduyusjhiye razdelyi dokumentiruyut prezhnij ispolnyayemyij kontrakt i sokhranyayutsya dlya testov i vozmozhnogo budusjhego vozvrata. Oni ne yavlyayutsya instrukciyej obyichnoj rabochej sessii.

Istoricheski `scripts/branch-next-step.py` ispoljzovalsya kak fail-closed selektor mezhdu kanonicheskimi kartochkami shagov i [obyazateljnyim prodolzheniyem vetki](../../Glossarij/obyazateljnoye-prodolzheniye-vetki.md). Novaya zadacha vyizyivala selektor posle FIFO-dopuska i perechityivaniya novogo `HEAD`; periodicheskij heartbeat, obsjhij dispetcher, host-inventarizaciya prostoya, reservation i kartochochnyij claim ne uchastvovali.

Selektor khranit konechnyij whitelist kandidatov s tochnyimi `card_id`, `card_content_sha256`, rezhimom `dispatch` i mashinnyimi zavisimostyami. On ne kopiruyet zadachu i kriterii kartochki i ne sozdayot Git-vetku.

## Format rabochego nabora

Fajl v `Планирование/следующие-шаги-веток/` ispoljzuyet `schema_version = 5`, polnyij `branch_ref`, `state`, `project_path` i massiv `candidates`. `open` trebuyet khotya byi odnogo kandidata, `done` — pustogo massiva.

Kazhdyij kandidat khranit:

- unikaljnyij `step_id` s versionnyim suffiksom `-vN`;
- `dispatch = automatic | paused | blocked`;
- `card_id` aktualjnoj kartochki;
- `card_content_sha256` yeyo soderzhaniya bez sluzhebnogo bloka recency;
- massiv `requires_completed_card_ids`;
- nepustoj `resume_condition` toljko dlya `paused` i `blocked`.

`automatic` oznachayet dopustimostj dlya pryamogo prodolzheniya vetki, a ne raspisaniye. Yego zavisimosti schitayutsya vyipolnennyimi toljko pri literal-statuse kartochki `completed`. `paused`, `blocked`, svobodnyij tekst, vremya, setj, sekretyi i vyivod modeli ne prevrasjhayutsya v gotovnostj.

## Proveritj i vyibratj

Strukturnaya proverka:

```bash
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py \
  validate --repo-root . --json
```

Pryamoj vyibor posle FIFO-dopuska prodolzheniya:

```bash
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py \
  show --repo-root . --json
```

`validate` vozvrasjhayet `state=valid` i vyichislennyiye schyotchiki dazhe pri nulevom gotovom pule. `show` s kodom `0` vozvrasjhayet odin `ready`: puti selektora, kartochki i proyekta, tochnyiye identichnosti i khyeshi, zadachu, kriterii i obyyekt `selection`. Kod `3` oznachayet korrektnyiye `not_ready` libo `done`; zadacha-prodolzheniye v oboikh sluchayakh delayet `finish-clean` i ne sozdayot rebyonka. Kod `2` oznachayet nedokazannyij kontrakt i takzhe zapresjhayet soderzhateljnuyu zapisj.

Selektor proveryayet exact tekusjhij polnyij ref, kanonicheskij TOML, unikaljnostj identichnostej, susjhestvovaniye i aktualjnyij status kartochek, khyeshi, zavisimosti, ciklyi, nepustyiye zadachu i kriterii i publikacionnuyu bezopasnostj gotovogo payload. Nebezopasnyij kandidat zakryivayet vesj vyibor do ranzhirovaniya.

Pri neskoljkikh gotovyikh kandidatakh politika `dynamic-readiness-source-history-first-parent-v2` ispoljzuyet ne boleye 16 first-parent-kommitov tochnogo `HEAD`; pri otsutstvii svideteljstv primenyayet ustojchivuyu paru `card_id`, `step_id`. Soobsjheniya, avtoryi, vremya, embeddings i skhodstvo imyon ne ispoljzuyutsya. Lyubaya smena vershinyi, pula, kartochki ili zavisimosti sozdayot novuyu `selection.id`, no eta identichnostj yavlyayetsya svideteljstvom read-only-vyibora, a ne lease.

## Vyipolnitj prodolzheniye

Posle `ready` zadacha:

1. proveryayet sovpadeniye vozvrasjhyonnogo `branch_ref` s vetkoj FIFO i svoyego admission `base_head` s tekusjhim `HEAD`;
2. polnostjyu chitayet `record_path`, `card_path`, `project_path` i primenimyiye lokaljnyiye navyiki;
3. vyipolnyayet odin kontekstno posiljnyij rezuljtat vmeste s proiskhozhdeniyem, testami, recency, polnyim smoke-check i otchyotom;
4. v tom zhe podgotovlennom kommite perevodit vyipolnennuyu kartochku v istoricheskij status, udalyayet yeyo pokoleniye iz nabora i sokhranyayet ostaljnyiye korrektnyiye kandidatyi libo `done`;
5. do sobstvennogo commit+handoff sozdayot i registriruyet rovno odno sleduyusjheye prodolzheniye po kontraktu ocheredi.

Prezhnij vyibor ne perenositsya cherez kommit. Sleduyusjhaya zadacha zanovo vyizyivayet `show` iz novogo `HEAD`. Ona ne vyipolnyayet `push` ili `publish`; ruchnaya publikaciya ostayotsya otdeljnyim poljzovateljskim dejstviyem.

Komandyi `claim`, `bind-run`, `verify-run`, `rearm` i `release`, a takzhe heartbeat-renderer sokhranenyi v kode toljko dlya sovmestimosti i istoricheskikh fikstur snyatogo dispetchera. Predyidusjhij protokol prodolzheniya ikh ne vyizyival, i ikh sluzhebnyiye refs ne dayut prava zapisi.

## Obnovitj khyeshi posle osmyislennoj pravki kartochek

```bash
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py \
  refresh-card-fences --repo-root . --json
```

Komanda proveryayet vesj nabor, obnovlyayet toljko izmenivshiyesya `card_content_sha256` i mekhanicheski vyipuskayet svezhij suffiks `-vN`. Ona ne menyayet `dispatch`, zavisimosti ili soderzhateljnyij vyibor.

## Proverka avtomatizacii

Zapuskaj testyi cherez obyazateljnuyu otchyotnuyu obyortku tekusjhej rabochej sessii:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-sleduyusjhij-shag-vetki/tests \
  -p 'test_*.py'
```

Sokhranyayemaya testovaya granica pokryivayet skhemu `5`, gotovnostj toljko iz `completed`, zavisimosti, khyesh kartochki, Unicode-vetki, SHA-256-repozitorii, deterministic first-parent-vyibor, nebezopasnyiye puti i korrektnyiye `not_ready`/`done`. Legacy-testyi claim dopustimyi toljko kak sovmestimostj i ne opisyivayut aktivnyij marshrut.

## Granica avtomatizacii

Selektor dokazyivayet strukturnuyu dopustimostj i vyibirayet odin kandidat na tekusjhem `HEAD`, no ne vyidayot pravo zapisi, ne sozdayot zadachu Codex i ne garantiruyet yeyo zhivuchestj. Pravo zapisi dayot toljko FIFO. Svyazj kommita s uzhe sozdannyim prodolzheniyem obespechivayet [ocheredj zadach Git-vetki](../fum-ocheredj-zadach-git-vetki/SKILL.md).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK — Zapuskatj sleduyusjhiye shagi vetok](../../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:8d33eaa5b887f910f85a6483b580719a75af64c4f33bb94eb8c0fd7fd06192f0 -->
<!-- FUM-MD-RECENCY:END -->
