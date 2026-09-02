# Otchyot 2026-07-27 16:12:29 MSK - Uchityivatj vse proverochnyiye vyizovyi v profile vremeni

Profilj vremeni teperj sokhranyayet ne toljko dliteljnostj odnogo itogovogo progona, a vsyu proverochnuyu istoriyu rabochej sessii. Povtoryi, oshibki i preryivaniya stanovyatsya vidimyimi vmeste s obsjhej stoimostjyu, poetomu otchyot pozvolyayet iskatj dorogiye proverki i lishniye perezapuski.

## Rezuljtat

Vnutri `## Профиль времени выполнения` vvedyon podrazdel `### Прямые запуски проверок`. Kazhdaya verkhneurovnevaya proverochnaya komanda poluchayet otdeljnuyu stroku `Вызов | Длительность | Результат`, a obsjhaya stroka soderzhit arifmeticheskuyu summu dliteljnostej. Validator prinimayet toljko neotricateljnyiye sekundyi, proveryayet dopustimyij rezuljtat i tochno sveryayet summu; prezhniye otchyotyi sokhranyayut svoj kontrakt.

Polnotu spiska neljzya dokazatj toljko po fajlam repozitoriya: istoriya vyizovov Codex i host ne vkhodit v proverku svyaznosti. Poetomu mashinnaya proverka otvechayet za formu i arifmetiku, a kornevoj agent — za fiksaciyu kazhdogo pryamogo vyizova, vklyuchaya rabotu subagentov, neuspeshnyiye popyitki i povtoryi.

## Granica i urovni uchyota

Summa pryamyikh vyizovov yavlyayetsya sovokupnyim vremenem processov. Yesli dva zapuska shli paralleljno, obe dliteljnosti vkhodyat v summu, no stadijnyij profilj po-prezhnemu pokazyivayet kalendarnyij wall-clock bez dvojnogo schyota perekryitiya. Shagi vnutri smoke-check yavlyayutsya detalizaciyej odnogo pryamogo vyizova: ikh dliteljnosti nuzhnyi dlya poiska uzkogo mesta, no vtoroj raz v obsjhuyu summu otchyota ne pribavlyayutsya.

Obsjhij smoke-check poluchil sobstvennyij monotonnyij profilj: otdeljno vidnyi podgotovka spiska, kazhdyij obyyavlennyij shag i polnyij interval, vklyuchaya ostanovku pri oshibke. Eto pozvolyayet razlozhitj dorogoj yedinyij zapusk do konkretnogo nabora testov, SwiftPM-sborki, lint ili validatora.

## Proverki

Posle ispravlenij celevyiye naboryi zavershilisj rezuljtatami `46/46` dlya svyaznosti i `24/24` dlya profilya smoke-check. Predfinaljnyij polnyij smoke-check uspeshno vyipolnil `61/61` shagov za `279,63 с` vneshnego wall-clock; yego sobstvennaya monotonnaya zapisj dala `279,570 с`. Vse 28 pryamyikh proverochnyikh vyizovov, vklyuchaya krasnyiye TDD-progonyi, diagnosticheskiye probes i povtoryi, perechislenyi nizhe.

Posle zapisi dliteljnosti polnogo progona vyipolnyayutsya toljko proverki zamyikaniya izmenivshegosya otchyota: svyaznostj s soobsjheniyem kommita, recency Markdown, teplovaya karta Obsidian i `git diff --check`. Oni sleduyut posle granicyi profilya i ne porozhdayut rekursivnyij polnyij smoke-check radi izmereniya samikh sebya.

## Profilj vremeni vyipolneniya

| Stadiya                              | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                          |
| ----------------------------------- | -----------: | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya, ozhidaniye i dopusk FIFO |      296,5 s | Mashinnyiye `registered_at_epoch` i `admitted_at_epoch`: ot `1785157506,439956` do `1785157802,9456298`, vklyuchaya perechityivaniye `HEAD`.                 |
| Soderzhateljnaya rabota               |  ne izmereno | Dokumentirovaniye, TDD i tri neperesekayusjhikhsya subagentskikh vklada; yedinyij monotonnyij interval etoj stadii otdeljno ne sokhranyalsya.                    |
| Celevyiye i vspomogateljnyiye proverki  |  ne izmereno | Do polnogo smoke-check sdelano 27 pryamyikh vyizovov sovokupnoj stoimostjyu `33,212 с`; chastj shla paralleljno, yedinaya wall-clock-granica ne sokhranyalasj. |
| Predfinaljnyij polnyij smoke-check    |     279,63 s | Vneshnij `/usr/bin/time -p`: `real 279,63 с`; vnutrennyaya monotonnaya granica podgotovki i 61 shaga — `279,570 с`.                                      |

### Pryamyiye zapuski proverok

| Vyizov                                                                      | Dliteljnostj | Rezuljtat                                                    |
| -------------------------------------------------------------------------- | -----------: | ------------------------------------------------------------ |
| `[coherence_tdd]` testyi svyaznosti, pervyij TDD red                          |       0,22 s | neuspeshno (5 ozhidayemyikh otkazov iz 41)                        |
| `[coherence_tdd]` testyi svyaznosti posle realizacii                         |       0,26 s | uspeshno (41/41)                                              |
| `[coherence_tdd]` povtor testov svyaznosti posle dokumentacii               |       0,23 s | uspeshno (41/41)                                              |
| `[smoke_timing_audit]` testyi smoke-check, pervyij TDD red                   |      0,349 s | neuspeshno (3 ozhidayemyiye oshibki iz 20)                         |
| `[smoke_timing_audit]` testyi smoke-check posle bazovoj realizacii          |      0,363 s | uspeshno (20/20)                                              |
| `[smoke_timing_audit]` testyi smoke-check posle rasshireniya kontrakta        |       0,32 s | uspeshno (22/22)                                              |
| `[root]` celevyiye testyi smoke-check do kriticheskogo revjyu                   |        0,6 s | uspeshno (22/22)                                              |
| `[root]` celevyiye testyi svyaznosti do kriticheskogo revjyu                     |       0,24 s | uspeshno (41/41)                                              |
| `[coherence_review]` nezavisimyij celevoj nabor testov svyaznosti            |        0,3 s | uspeshno (41/41)                                              |
| `[coherence_review]` probe ekranirovannyikh tablic, fenced-blokov i tochnosti |        0,1 s | uspeshno (vosproizvedenyi 3 defekta)                           |
| `[coherence_tdd]` novyiye regressii po itogam revjyu, TDD red                 |       0,24 s | neuspeshno (7 ozhidayemyikh otkazov iz 46)                        |
| `[coherence_tdd]` testyi svyaznosti posle ispravlenij revjyu                  |       0,24 s | uspeshno (46/46)                                              |
| `[coherence_tdd]` povtor testov svyaznosti posle soglasovaniya kontrakta     |       0,24 s | uspeshno (46/46)                                              |
| `[coherence_tdd]` kombinirovannyij `git diff --check` i prosmotr diff       |        0,1 s | uspeshno (vremya otnositsya ko vsemu kombinirovannomu vyizovu)   |
| `[smoke_timing_review]` nezavisimyij celevoj nabor testov smoke-check       |       0,56 s | uspeshno (22/22)                                              |
| `[smoke_timing_review]` pervyij OSError-probe                               |        0,1 s | neuspeshno (oshibka harness; produkt ne proveren)              |
| `[smoke_timing_review]` ispravlennyij probe oshibok shaga i SwiftPM-manifesta |        0,1 s | uspeshno (vosproizvedyon defekt koda oshibki manifesta)         |
| `[smoke_timing_review]` probe `PermissionError` podgotovki                 |        0,1 s | uspeshno (vosproizvedeno otsutstviye itogovyikh zapisej vremeni) |
| `[smoke_timing_audit]` regressii oshibok podgotovki, TDD red                |      0,432 s | neuspeshno (1 ozhidayemyij otkaz i 1 oshibka iz 24)               |
| `[smoke_timing_audit]` testyi smoke-check posle ispravlenij revjyu           |      0,438 s | uspeshno (24/24)                                              |
| `[root]` celevyiye testyi svyaznosti posle ispravlenij revjyu                   |       0,25 s | uspeshno (46/46)                                              |
| `[root]` celevyiye testyi smoke-check posle ispravlenij revjyu                 |       0,57 s | uspeshno (24/24)                                              |
| `[root]` smoke-check `--skip-session-coherence --list`                     |      13,03 s | uspeshno (spisok postroyen; proverochnyiye shagi ne ispolnyalisj)   |
| `[root]` `git diff --check` pered polnyim smoke-check                       |       0,03 s | uspeshno                                                      |
| `[root]` proverka svyaznosti s soobsjheniyem kommita pered polnyim smoke-check  |      13,03 s | uspeshno                                                      |
| `[root]` proverka svezhesti Markdown pered polnyim smoke-check               |       0,46 s | uspeshno                                                      |
| `[root]` proverka teplovoj kartyi Obsidian pered polnyim smoke-check         |       0,31 s | uspeshno                                                      |
| `[root]` predfinaljnyij polnyij smoke-check                                  |     279,63 s | uspeshno (61/61 shagov)                                        |

Obsjheye vremya pryamyikh zapuskov proverok: 312,842 s

#### Samyiye dorogiye vnutrenniye shagi polnogo smoke-check

| Shag                                                      | Dliteljnostj | Dolya vnutrennego `total` |
| -------------------------------------------------------- | -----------: | -----------------------: |
| Testyi `fum-proverka-git-zavisimostej`                    |     90,717 s |                   32,4 % |
| Testyi `fum-ocheredj-zadach-git-vetki`                    |     53,808 s |                   19,2 % |
| Testyi `fum-sleduyusjhij-shag-vetki`                      |     23,561 s |                    8,4 % |
| Testyi `fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok` |     13,106 s |                    4,7 % |
| Proverka svyaznosti rabochej sessii                        |     12,717 s |                    4,5 % |
| Proverka mashinno-lokaljnyikh putej                         |     10,577 s |                    3,8 % |

Pervyiye tri nabora zanyali `168,086 с`, ili `60,1 %` vsego vnutrennego vremeni polnogo smoke-check, poetomu oni yavlyayutsya glavnyimi kandidatami dlya optimizacii. Podgotovka zanyala yesjhyo `9,875 с`, iz kotoryikh `9,466 с` prishlosj na devyatj posledovateljnyikh razborov SwiftPM-manifestov. Predvariteljnyij vyizov `--list` pokazyival razovyij vyibros manifesta chistogo modeljnogo shaga do `3,709 с`, no v polnom progone tot zhe razbor zanyal `1,008 с`; optimizaciyu sleduyet opiratj na povtornyiye izmereniya, a ne na yedinichnyij vyibros. Vnutrenniye zapisi yavlyayutsya detalizaciyej vneshnego vyizova i ne dobavlenyi k obsjhej summe vtoroj raz.

Granica profilya: ot atomarnoj registracii FIFO-bileta do zaversheniya predfinaljnogo polnogo smoke-check; finaljnaya zapisj yego dliteljnosti, recency, proverki zamyikaniya otchyota, staging, commit+handoff i publikaciya tochnogo kommita sleduyut posle granicyi.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [iskhodnoye pravilo profilya vremeni](../2026-07-23_14-47-43_MSK_vklyuchatj-profilj-vremeni-v-otchyotyi-zhurnala/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d060bbb64ed63ff0f2e034be7eb1ac294d2fad463d5fb5740b0cd27d4aed760a -->
<!-- FUM-MD-RECENCY:END -->
