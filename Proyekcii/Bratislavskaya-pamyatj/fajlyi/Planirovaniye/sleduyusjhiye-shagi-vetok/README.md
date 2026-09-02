# Sleduyusjhiye shagi vetok

Etot katalog khranit versionnyiye naboryi kandidatov [sleduyusjhego shaga vetki](../../Glossarij/sleduyusjhij-shag-vetki.md) dlya imenovannyikh [vetok rabotyi](../../Glossarij/vetka-rabotyi.md). Nabor ne kopiruyet zadachi i kriterii kartochek: on zadayot konechnyij whitelist `automatic`, `paused` i `blocked`, svyazyivayet kandidatov s [kartochkami shagov](../kartochki-shagov/README.md) po `card_id` i zakreplyayet tochnyij khyesh soderzhaniya. Gotovnostj vyichislyayet neposredstvenno dopusjhennaya [zadacha-prodolzheniye](../../Glossarij/obyazateljnoye-prodolzheniye-vetki.md) iz novogo `HEAD`.

Ekspluatacionnyij status: format i naboryi sokhranenyi kak istoricheskaya realizaciya selector-konvejyera. V rezhime `manual-sequential-v1` komanda `show` vozvrasjhayet `done`, izmenyayusjhiye komandyi selektora zapresjhenyi, a znacheniya `open`, `automatic` i vyichislennaya prezhnim algoritmom gotovnostj ne sozdayut zadachu i ne dayut polnomochij.

Identichnostj vetki zadayotsya polnyim `branch_ref`, a ne imenem fajla. Dlya tekusjhej vetki dolzhno nakhoditjsya rovno odno sovpadeniye. Fajl `README.md` opisyivayet format i ne uchastvuyet v vyibore.

Yesli vetka realizuyet konechnuyu cepochku, yeyo upstream sluzhit [kartochka cepochki shagov](../kartochki-cepochek-shagov/README.md). Selektor ne sozdayot i ne pereklyuchayet vetku; otdeljnyij ograzhdyonnyij perekhod vyipolnyayetsya toljko mezhdu kornevyimi zadachami pri pustoj FIFO i chistoj rabochej kopii.

## Format vetochnogo nabora

Zapisj nachinayetsya s TOML-bloka skhemyi `5`:

```toml
+++
schema_version = 5
branch_ref = "refs/heads/project/пример"
state = "open"
project_path = "Проекты/пример/README.md"

[[candidates]]
step_id = "project-example-fum-step-0042-automatic-v1"
dispatch = "automatic"
card_id = "FUM-STEP-0042"
card_content_sha256 = "sha256:<64 шестнадцатеричных символа>"
requires_completed_card_ids = []

[[candidates]]
step_id = "project-example-fum-step-0043-blocked-v1"
dispatch = "blocked"
card_id = "FUM-STEP-0043"
card_content_sha256 = "sha256:<64 шестнадцатеричных символа>"
requires_completed_card_ids = ["FUM-STEP-0042"]
resume_condition = "Получен отдельно подтверждённый внешний вход."
+++
```

Verkhneurovnevyij blok imeyet `schema_version`, `branch_ref`, `state`, `project_path` i `candidates`. `project_path` — normalizovannyij susjhestvuyusjhij putj vnutri repozitoriya. `open` trebuyet kandidatov, `done` — tochnyij pustoj massiv.

Kandidat soderzhit `step_id`, `dispatch`, `card_id`, `card_content_sha256` i `requires_completed_card_ids`; `paused` i `blocked` dopolniteljno trebuyut `resume_condition`. Khyesh vyichislyayetsya po soderzhaniyu kartochki bez konechnogo bloka `FUM-MD-RECENCY`. Vse identifikatoryi unikaljnyi, a celevaya kartochka aktualjna.

`automatic` oznachayet predvariteljnuyu dopustimostj dlya pryamogo prodolzheniya pri vyipolnennyikh ALL-of-zavisimostyakh. Toljko literal-status `completed` udovletvoryayet zavisimosti. `paused` i `blocked` ne otkryivayutsya iz svobodnogo teksta, vremeni, seti, sredyi, sekreta ili vyivoda modeli. Povtor, self-edge, cikl, ustarevshij khyesh ili nebezopasnyij ready-payload zakryivayut vesj nabor.

Izmeneniye puti ili khyesha kartochki, `dispatch`, zavisimostej libo `resume_condition` trebuyet novogo `step_id`. Perekhod v `automatic` vsegda vyipuskayet novuyu versiyu. Smena toljko statusa zavisimosti menyayet vyichislennuyu `selection.id`, no ne obyyavleniye.

## Zhiznennyij cikl

Posle commit+handoff rebyonok perechityivayet novyij `HEAD`, poluchayet FIFO-dopusk i vyizyivayet:

```bash
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py validate --repo-root . --json
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py show --repo-root . --json
```

`ready` dayot odnu kartochku. `done` i `not_ready` zakanchivayutsya `finish-clean`; kommita i sleduyusjhego rebyonka net. Periodicheskij heartbeat, dispetcherskij reyestr, host-inventarizaciya, reservation i claim ne uchastvuyut.

Posle uspeshnoj rabotyi tot zhe kommit perevodit kartochku v istoricheskij status, udalyayet yeyo pokoleniye i sokhranyayet ostaljnyiye kandidatyi libo `done`. Do etogo kommita zadacha sozdayot rovno odno sleduyusjheye prodolzheniye, podtverzhdayet yego ozhidayusjhij bilet i peredayot identifikator ocheredi. Sleduyusjhaya zadacha vyibirayet zanovo; prezhnyaya `selection.id` ne yavlyayetsya polnomochiyem.

Politika `dynamic-readiness-source-history-first-parent-v2` ranzhiruyet toljko vyichislennyij ready-pul po ne boleye chem 16 first-parent-kommitam i ustojchivoj pare `card_id`, `step_id`. Ona ne obkhodit zavisimosti, rezhimyi, polnomochiya ili bezopasnostj.

Kornevoj `./sbrositj.sh` ne menyayet selektor i ne zapuskayet kartochku. Posle chelovecheskogo sbrosa rabotu nachinayet otdeljnyij yavnyij zapros. Istoricheskiye claim- i dispatcher-refs ne yavlyayutsya aktivnoj chastjyu zhiznennogo cikla.

## Sozdaniye proyektnoj vetki

1. Sozdatj pasport proyekta.
2. Sozdatj aktualjnyiye kartochki i obnovitj ikh indeks.
3. Sozdatj nabor s tochnyim polnyim ref, svezhimi khyeshami, pokoleniyami i zavisimostyami.
4. Zapustitj `validate`.
5. Zakommititj pasport, kartochki i nabor po obyichnomu protokolu obyazateljnogo prodolzheniya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [FUM-REQ-0042 — obyazateljnoye prodolzheniye Git-vetki posle kommita](../../Trebovaniya/✅-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK — Zapuskatj sleduyusjhiye shagi vetok](../../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:2b29776fc7055ba27d2dff891cfd998c773b021b390d5903bb26cb4c13dec1c0 -->
<!-- FUM-MD-RECENCY:END -->
