# Otchyot 2026-08-26 08:55:49 MSK - Slitj vetku s privyazkoj shagov k dorozhnoj karte

V tekusjhij `master` svedena vetka `codex/подузлы/сессия-c8121b1382fa3ef091cd8fcf` s zavershyonnoj FUM-STEP-0146. Nastoyasjhij tryokhstoronnij merge perenyos privyazku 12 sleduyusjhikh shagov k dorozhnoj karte, dvum stadiyam, gorizontam `0`–`8`, pokoleniyam, rezhimam i zavisimostyam, a takzhe skhemu planovogo reyestra `9`. Pri razreshenii konfliktov sokhranyon boleye novyij ekspluatacionnyij rezhim `manual-sequential-v1`: istoricheskij pul ostayotsya dokumentaljnoj proyekciyej, a selektor ne zapuskayet shag avtomaticheski. Poljzovateljskij `.obsidian/graph.json` vosstanovlen pobajtno i ostavlen vne Git.

## Profilj vremeni vyipolneniya

| Stadiya                              | Dliteljnostj             | Granicyi i sposob izmereniya                                                                  |
| ----------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------- |
| Poisk i audit kandidatnoj vetki     | ne izmereno              | Read-only analiz Git-grafa, izmenenij i ozhidayemyikh konfliktov dvumya nezavisimyimi subagentami |
| Semanticheskij merge                 | ne izmereno              | Ot `git merge --no-commit --no-ff` do peresborki proizvodnyikh dannyikh                          |
| Celevyiye proverki                    | po mashinnoj tablice nizhe | Summa adresnyikh progonov zakreplyayetsya zakryityim snimkom                                        |
| Standartnyij dokumentaljnyij smoke-check | po mashinnoj tablice nizhe | Poslednij zapisannyij proverochnyij vyizov pered zakryitiyem snimka                                |
| Lokaljnyij merge-kommit              | posle proverok            | Odin dvukhroditeljskij kommit bez publikacii                                                  |

Granica profilya: nachalo v 08:55:49 MSK, zakryitiye mashinnogo snimka v 09:44:07 MSK; mashinno izmeryayutsya toljko pryamyiye proverochnyiye vyizovyi, a soderzhateljnyiye stadii ne snabzhayutsya vyimyishlennoj ocenkoj.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:323489abc88f5e718d1cf340b35b01717c3a838d6a2e6cf2ffd3b0859c667fc0 -->

| Vyizov                                                                         | Dliteljnostj | Rezuljtat |
| ----------------------------------------------------------------------------- | ------------ | --------- |
| [FUM Integrator] Celevaya regressiya reyestra planirovaniya                       | 4,562 s      | uspeshno   |
| [FUM Integrator] Regressiya ruchnogo vyibora sleduyusjhego shaga vetki               | 183,963 s    | uspeshno   |
| [FUM Integrator] Proverka tochnogo snimka ostatka obyyavlenij koda              | 22,739 s     | uspeshno   |
| [FUM Integrator] Povtornaya regressiya reyestra posle semanticheskoj adaptacii    | 4,309 s      | uspeshno   |
| [FUM Integrator] Regressiya tochnogo pokryitiya gorizontov dorozhnoj kartyi         | 3,77 s       | uspeshno   |
| [FUM Integrator] Povtornaya regressiya legacy-proyekcii ruchnogo selektora        | 173,8 s      | uspeshno   |
| [FUM Integrator] Povtornaya proverka snimka obyyavlenij posle rusifikacii testa | 21,808 s     | uspeshno   |
| [FUM Integrator] Standartnyij dokumentaljnyij smoke-check                       | 63,374 s     | neuspeshno |
| [FUM Integrator] Adresnaya proverka svyaznosti merge-oblasti                    | 31,415 s     | uspeshno   |
| [FUM Integrator] Povtornyij standartnyij dokumentaljnyij smoke-check             | 113,821 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 623,561 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Do proverochnogo kontura planovyij reyestr skhemyi `9` i tochnyij snimok ostatka obyyavlenij peresobranyi shtatnyimi generatorami bez oshibok.
- Razreshyonnyiye vruchnuyu uchastki ne soderzhat markerov konflikta; predvariteljnyiye `git diff --check` i `git diff --cached --check` uspeshnyi.
- Zaklyuchiteljnaya celevaya regressiya reyestra proshla 76 testov, vklyuchaya otricateljnuyu fiksturu tochnogo nabora gorizontov `0`–`8`. Regressiya legacy-proyekcii ruchnogo selektora proshla 188 testov s 34 uslovnyimi propuskami i podtverdila `show = done`; tochnyij snimok 43 207 obyyavlenij sovpal.
- Pervyij dokumentaljnyij smoke-check ostanovilsya toljko na proverke svyaznosti sessii: perechenj zatronutyikh fajlov ne okhvatyival chastj importirovannoj merge-oblasti. Posle yavnogo obyyavleniya sootvetstvuyusjhikh katalogov adresnaya proverka proshla, a zaklyuchiteljnyij smoke-check uspeshno vyipolnil vse 21 shaga; soderzhateljnyikh oshibok realizacii etot promezhutochnyij otkaz ne vyiyavil.

## Resheniya i ogranicheniya

- Vetka integriruyetsya nastoyasjhim merge-kommitom s dvumya roditelyami, chtobyi sokhranitj proiskhozhdeniye kandidatnoj rabotyi; squash i perepisyivaniye kandidatnogo kommita ne primenyayutsya.
- V soderzhateljnyikh konfliktakh obyyedinenyi novyiye planovyiye svyazi s boleye pozdnimi pravilami `master`; udalyonnyij iz kandidatnoj vetki avtomaticheskij vyibor ne vozvrasjhyon.
- Proizvodnyiye JSON-reyestryi peresobranyi iz obyyedinyonnyikh istochnikov, a navigaciya zhurnala vyistroyena khronologicheski cherez kandidatnuyu sessiyu.
- Nezavisimyij audit obnaruzhil granicu vetochnogo rezuljtata: skhema `9` svyazyivayet 12 prioritetnyikh prodolzhenij prezhnego whitelist, togda kak posle zaversheniya FUM-STEP-0146 v kataloge ostayutsya 42 aktivnyiye kartochki. Poetomu karta i kartochka shaga pryamo nazyivayut rezuljtat neispolnyayemoj vyiborkoj, a ne polnyim ruchnyim pulom; rasshireniye na ostavshiyesya 30 kartochek i smena semantiki reyestra potrebovali byi otdeljnoj skhemyi i otdeljnogo zaprosa.
- Poryadok, pokoleniya, zavisimosti i `dispatch` sokhranenyi kak strogiye polya planovoj proyekcii i legacy-diagnostiki. Oni ne oznachayut runtime-ready, selector-prioritet, avtomaticheskij zapusk ili razresheniye vneshnego dejstviya; kazhdyij sleduyusjhij shag vyibirayet poljzovatelj vruchnuyu.
- Mashinnyiye kvitancii kandidatnoj sessii sokhranenyi kak istoricheskoye proiskhozhdeniye vetki, no dokazateljstvom sovmestimosti s tekusjhim `master` schitayutsya toljko novyiye proverki etoj integracionnoj sessii.
- `.obsidian/graph.json` — ignoriruyemoye poljzovateljskoye sostoyaniye. Yego iskhodnyij SHA-256 `8d50db66b47c1b5f2298cc9c2cf55bc2f6c6111aff520e8c49564369862fb8df` sokhranyon.
- Rezuljtat ostayotsya lokaljnyim: publikaciya, udaleniye kandidatnoj vetki i inyiye vneshniye dejstviya v zapros ne vkhodyat.

## Istochniki

- [iskhodnyij zapros](zapros.md)
- [kandidatnaya sessiya FUM-STEP-0146](../2026-08-14_18-24-50_MSK_zapustitj-daljnij-paralleljnyij-shag/otchyot.md)
- [dorozhnaya karta](../../Planirovaniye/dorozhnaya-karta.md)
- [rabochij nabor sleduyusjhikh shagov `master`](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)
- [kartochka FUM-STEP-0146](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0146-svyazatj-sleduyusjhiye-shagi-s-dorozhnoj-kartoj.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 09:44:42 MSK -->
<!-- content-sha256: sha256:45903d4cdd95ed78ae01d978059db2bfb3b32a685c9d14529b77da31ced7f7ec -->
<!-- FUM-MD-RECENCY:END -->
