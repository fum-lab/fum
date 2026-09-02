# Podtverzhdayemyij ruchnoj sbros FIFO k tekusjhemu HEAD

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0041 -->

Ekspluatacionnyij status: otlozheno vmeste s FIFO-runtime. Kartochka i `./sbrositj.sh` sokhranyayutsya kak istoricheskaya avarijnaya narabotka i ne zapuskayutsya; vozvrat etogo marshruta trebuyet otdeljnogo poljzovateljskogo zaprosa i novogo soglasovannogo perekhoda pravil.

V korne repozitoriya dolzhna susjhestvovatj tochka vkhoda `./sbrositj.sh`, pozvolyayusjhaya cheloveku soznateljno nachatj lokaljnuyu rabotu zanovo ot tochnogo `HEAD` tekusjhej imenovannoj vetki. Eto avarijnyij `break-glass`-marshrut dlya zastryavshej FIFO ili povrezhdyonnogo lokaljnogo runtime-sostoyaniya; on ne yavlyayetsya host-stop, ne sozdayot zadachu-prodolzheniye i ne vozobnovlyayet snyatyij heartbeat.

Do pervoj mutacii zapuskatelj stroit zakryityij plan po fizicheskomu checkout, polnomu ref tekusjhej lokaljnoj vetki, tochnomu `HEAD`, indeksu, rabochemu derevu, obyyektu ocheredi i obsluzhivayemyim `refs/fum/`. Plan poluchayet khyesh i prinimayetsya tochnoj dinamicheskoj frazoj toljko pri nastoyasjhikh TTY na vvode i vyivode. Lyuboj drift mezhdu planom i primeneniyem zakryivayet popyitku.

Posle podtverzhdeniya protokol arkhiviruyet iskhodnyiye OID obsluzhivayemyikh runtime-ssyilok, ustanavlivayet reset-fence, vosstanavlivayet indeks i otslezhivayemoye derevo iz zakreplyonnogo `HEAD`, udalyayet toljko podtverzhdyonnyiye Git-vidimyiye neignoriruyemyiye obyichnyiye fajlyi i simvolicheskiye ssyilki i vyipuskayet svezhuyu pustuyu ocheredj. Ignoriruyemyiye dannyiye, vlozhennyiye repozitorii, drugiye worktree i vetki, tegi, remote i istoriya Git sokhranyayutsya. Istoricheskiye dispatcher-, claim-, repair-, reservation-, ledger- i analytics-ssyilki ochisjhayutsya toljko kak chastj proverennogo snimka prezhnej realizacii i ne stanovyatsya novyim aktivnyim konturom.

## Semanticheskiye svyazi

- **dopolnyayet:** [shtatnyij sbros FIFO-ocheredi i rabochej kopii](🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md) — dobavlyayet soznateljnyij chelovecheskij `break-glass`-marshrut bez avtomaticheskogo zakhvata prava zapisi.

## Kriterii proverki

- kornevoj ispolnyayemyij POSIX-skript sam opredelyayet checkout, ne trebuyet `sudo`, trebuyet TTY odnovremenno na stdin i stdout i ispolnyayet realizaciyu iz tochnogo zakommichennogo `HEAD`;
- vyizov bez TTY, s argumentom, cherez pipe, s nevernoj libo ustarevshej frazoj zavershayetsya bez izmeneniya fajlov, indeksa, vetok, istorii i refs;
- plan zakreplyayet polnyij imenovannyij ref, `HEAD`, queue OID, tochnyiye worktree/index-celi i raw ref/OID-inventarj tekusjhej runtime-oblasti;
- validnaya nezavershyonnaya zapisj perekhoda vetki zakryivayet plan do idempotentnogo zaversheniya i ne osirotit sozdannuyu vetku;
- primeneniye sokhranyayet ignored-dannyiye i vlozhennyiye Git-granicyi, bezopasno otkazyivayet pri skryityikh index-flagakh, nepodderzhivayemom obyyekte, pozdnem drift ili smene vetki;
- final ostavlyayet tochnoye derevo zakreplyonnogo `HEAD`, pustyiye `owner` i `waiting`, svezhuyu ocheredj, tombstone prezhnikh zadach i neizmenyayemuyu kvitanciyu dlya terminal replay;
- prezhniye task ID, ticket i generation otklonyayutsya posle sbrosa, a novuyu rabotu nachinayet toljko otdeljnaya yavno sozdannaya kornevaya zadacha;
- sbros ne dokazyivayet, susjhestvoval li rebyonok posle neodnoznachnogo `create_thread`, i ne razreshayet slepoj povtor etogo host-vyizova;
- avtonomnyiye vremennyiye Git-fiksturyi proveryayut otkazoustojchivostj; nastoyasjhij launcher ne ispolnyayetsya testami nad zhivyim checkout.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: launcher, TTY-podtverzhdeniye, raw archive, ochistka, tombstone i terminal replay podtverzhdenyi avtonomnyimi Git-fiksturami.

Marshrut obsluzhivayet toljko tekusjhuyu lokaljnuyu imenovannuyu vetku odnogo fizicheskogo checkout. On ne ostanavlivayet zadachi Codex, ne sozdayot prodolzheniye, ne publikuyet Git-istoriyu i ne ochisjhayet drugoj klon, worktree, vetku ili remote.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-10 10:19:59 MSK — Dobavitj prostoj sbros FIFO k tekusjhemu HEAD](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [FUM-REQ-0039 — Shtatnyij sbros FIFO-ocheredi i rabochej kopii](🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:e579bc854f9841b879f5f7ae9a37da6dbdd0115ab5fca1f6e74db5479a06fac6 -->
<!-- FUM-MD-RECENCY:END -->
