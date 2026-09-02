# Revjyu povtornogo avtozapuska posle otkata

Obnaruzhennoye zamechaniye P2 ustraneno; nezakryityikh susjhestvennyikh zamechanij ne vyiyavleno.

## Granica revjyu

- Iskhodnyij zapros: [Zaprosyi/2026-08-01_09-16-33_MSK_ispravitj-povtornyij-avtozapusk-posle-otkata.md](../../zapros.md)
- Avtomatizaciya: [Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md](../../../../Instrumentyi/fum-revjyu-prodelannoj-rabotyi/SKILL.md)
- Konfiguraciya: [Revjyu/Avtomatizacii/2026-08-01_10-45-59_MSK_revjyu-povtornogo-avtozapuska-posle-otkata.json](2026-08-01_10-45-59_MSK_revjyu-povtornogo-avtozapuska-posle-otkata.json)
- Revjyuyer: Codex
- Vremya revjyu: 2026-08-01 10:45:59 MSK
- Baza: `6d5cb5f98c08144eab77cfa22c05da938c269e46`
- Golova: `HEAD`
- Diapazon Git: `6d5cb5f98c08144eab77cfa22c05da938c269e46..HEAD`
- Oblastj: Proveren rabochij diff ispravleniya povtornogo avtozapuska posle polnogo chistogo otkata: dokazannaya prichina stale claim, skhemyi privyazki zapuska 2–4, FIFO- i vetochnyij run-fence, rearm, privilegirovannoye vneshneye recovery, kanonicheskij i live heartbeat, dokumentaciya i regressii. Neprozrachnyiye runtime-znacheniya i privatnyiye bazyi Codex v publikuyemuyu oblastj ne vkhodili.

## Snimok Git

Kommityi v diapazone:

- Net kommitov v vyibrannom diapazone.

Izmenyonnyiye fajlyi:

Izmenyonnyiye fajlyi v vyibrannom diapazone ne najdenyi.

Statistika diff:

```text

```

Avtomaticheskij signal `git diff --check`: proshyol. Problem whitespace ne obnaruzheno.

Tekusjheye sostoyaniye rabochego dereva pri sborke otchyota:

```text
M AGENTS.md
 M Глоссарий/следующий-шаг-ветки.md
 M Документация/04-параллельная-работа-и-слияние.md
 M Документация/17-воспроизводимые-автоматизации.md
 M Запросы/2026-07-31_21-37-26_MSK_ввести-схему-событий-живого-одноагентного-эпизода.md
 M Инструменты/README.md
 M Инструменты/fum-sleduyusjhij-shag-vetki/SKILL.md
 M Инструменты/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md
 M Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py
 M Инструменты/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py
 M Планирование/следующие-шаги-веток/README.md
 M Ревью/README.md
?? Запросы/2026-08-01_09-16-33_MSK_исправить-повторный-автозапуск-после-отката.md
?? Ревью/Автоматизации/2026-08-01_10-45-59_MSK_ревью-повторного-автозапуска-после-отката.json
```

## Chto proveryalosj

- svyazj claim s tochnyimi lease, task_id, FIFO-generation, base_head i selection do soderzhateljnoj rabotyi
- atomarnostj queue-ref, branch-ref i claim-ref pri verify-run i rearm
- bezopasnaya zhivostj mezhdu rearm i finish-clean bez vozmozhnosti vtorogo pisatelya
- razgranicheniye shtatnogo rearm zhivoj zadachi i privilegirovannogo vneshnego release posle host-dokazateljstva ostanovki
- nepublikuyemyij runtime-konvert, asinkhronnyij clientThreadId i otsutstviye zavisimosti ot dispatcher-side bind
- tochnyij dopustimyij diff susjhestvuyusjhej ACTIVE heartbeat-avtomatizacii i vosstanovleniye tekusjhego stale claim

## Nakhodki

| Prioritet | Status | Fajl | Stroka | Zagolovok |
| --- | --- | --- | --- | --- |
| P2 | ustraneno do zaversheniya revjyu | `Инструменты/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md` | 31 | Granica release zhivogo i okonchateljno ostanovlennogo zapuska byila neyavnoj |

### P2: Granica release zhivogo i okonchateljno ostanovlennogo zapuska byila neyavnoj

Pervonachaljnaya redakciya praviljno vvela rearm dlya zhivogo ispolnitelya, no posle szhatiya dochernego prompt poteryala pryamoj zapret release uspeshno sozdannogo zapuska. Odnovremenno formulirovka rabochego nabora mogla chitatjsya kak absolyutnyij zapret vneshnego release skhem 3 i 4, chto ostavlyalo byi vechnyij claim posle host-dokazannoj okonchateljnoj ostanovki uspevshej svyazatjsya zadachi.

Rekomendaciya: Yavno zapretitj release dochernej zadache, trebovatj ot zhivogo ispolnitelya toljko rearm do finish-clean i sokhranitj exact-lease release lyuboj chitayemoj skhemyi kak otdeljnoye privilegirovannoye vneshneye recovery lishj posle host-dokazateljstva okonchateljnoj ostanovki.

## Proverki

| Proverka | Komanda | Rezuljtat | Detali |
| --- | --- | --- | --- |
| Polnyij nabor sleduyusjhego shaga vetki | `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-sleduyusjhij-shag-vetki/tests -p 'test_*.py'` | proshlo: 149 testov | Proverenyi skhemyi claim 1–4, bind, verify, rearm, vneshnij recovery, gonki Git refs, chistota checkout, runtime-konvert i limit heartbeat prompt. |
| Polnyij nabor FIFO-ocheredi | `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocheredj-zadach-git-vetki/tests -p 'test_*.py'` | proshlo: 58 testov | Mezhkontraktnaya ocheredj sokhranila strogij admission, pokoleniya i atomarnuyu peredachu. |
| Live exact-diff | `python3 -I -c '<полная read-only-сверка automation.toml с renderer до и после штатного host-обновления>'` | proshlo | Finaljnyij in-place-remont izmenil toljko prompt i updated_at; status ACTIVE, identichnostj, celj i raspisaniye sokhranenyi. |
| Fenced-vosstanovleniye tekusjhego claim | `python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py release --repo-root . --branch-ref refs/heads/master --expected-lease-id <непубликуемое-значение> --json` | proshlo | Posle povtornogo host-dokazateljstva zavershyonnogo chistogo otkata exact schema-2 claim udalyon; post-view vernul unclaimed. |
| Publikacionnaya chistota diff | `git diff --check HEAD` | proshlo | Probeljnyiye oshibki v tekusjhem rabochem diff ne obnaruzhenyi. |

## Ostatochnyiye riski

- Proverka chistotyi checkout ne atomarna s Git-tranzakciyej refs, poetomu protokol obyazateljno ostanavlivayet vsekh sposobnyikh pozdneye zapisatj processov do rearm.
- Sboj mezhdu uspeshnyim rearm i finish-clean sokhranyayet prezhnego FIFO-vladeljca i trebuyet vozobnovleniya toj zhe zadachi; eto bezopasno blokiruyet povtor, no vremenno ostanavlivayet zhivostj.
- Host-dokazateljstvo okonchateljnoj ostanovki dlya privilegirovannogo vneshnego release ostayotsya procedurnyim predusloviyem: Git-komanda proveryayet exact lease i CAS, no sama ne chitayet host-inventarizaciyu.
- Host-obnovleniye avtomatizacii ne predostavlyayet expected-version/CAS; polnyij snapshot i post-view exact-diff obnaruzhivayut nablyudayemoye raskhozhdeniye, no ne obesjhayut tranzakcionnuyu zasjhitu ot odnovremennogo vneshnego izmeneniya.

## Sokhraneniye rezuljtata

Otchyot postroyen lokaljnoj avtomatizaciyej `fum-revjyu-prodelannoj-rabotyi` iz sokhranyonnoj konfiguracii, tekusjhego Git-sreza i smyislovogo revjyu agenta. Skript avtomatiziruyet sbor nablyudayemogo konteksta, strukturu otchyota i proverku obyazateljnyikh razdelov, no ne podmenyayet soderzhateljnuyu otvetstvennostj revjyuyera za vyivodyi.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1e397b30c9d7247b37c778dc350adcf87b067c14303708ff2df6ca57c5e67d4e -->
<!-- FUM-MD-RECENCY:END -->
