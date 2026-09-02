---
name: fum-ocheredj-zadach-git-vetki
description: Sokhranyayet istoricheskij FIFO/pool-protokol FUM dlya chteniya kvitancij, regressionnyikh testov i zaversheniya yedinstvennogo uzhe nachatogo perekhodnogo handoff; obyichnaya rabota posle manual-sequential-v1 yego ne zapuskayet.
---

# Ocheredj zadach Git-vetki

## Dejstvuyusjhij status

Posle markera `manual-sequential-v1` etot navyik ne yavlyayetsya marshrutom obyichnoj pishusjhej rabotyi. Novuyu sessiyu vruchnuyu zapuskayet poljzovatelj v pervichnom checkout na `refs/heads/master`; ona ne vyizyivayet route, `join`, pool allocation, continuation, reviewer, integrator, candidate, target CAS, publikaciyu ili vetochnyij selector. Scenarii, refs, kvitancii i testyi nizhe sokhranyayutsya kak istoricheskaya realizaciya i istochnik proiskhozhdeniya, a ne kak polnomochiye.

Yedinstvennoye perekhodnoye isklyucheniye — bridge-zadacha, kotoraya byila sozdana i zaregistrirovana prezhnim `HEAD` do kommita, vpervyiye vvodyasjhego `manual-sequential-v1`. Posle handoff ona perechityivayet novyij `HEAD`, vyipolnyayet toljko exact `ack-head`, dozhidayetsya `admitted` i vyizyivayet `finish-clean`. Ona ne povtoryayet ozhidayusjhiye publikacii, ne zapuskayet `branch-next-step.py`, ne vyibirayet kartochku i ne sozdayot sleduyusjhuyu zadachu. Posle `finished_clean` ordinary FIFO ostayotsya istoricheskim sostoyaniyem.

Vse posleduyusjhiye razdelyi dokumentiruyut prezhnij otlozhennyij konvejyer. Ikh imperativnyiye formulirovki primenimyi toljko k regressionnyim fiksturam libo k otdeljno avtorizovannomu budusjhemu vozvratu protokola i ne pereopredelyayut dejstvuyusjhuyu ruchnuyu skhemu iz `AGENTS.md`.

Ocheredj dopuskayet k zapisi v odin fizicheskij checkout imenovannoj linii toljko odnu kornevuyu zadachu. Biletyi exact-prodolzhenij poluchayut vozrastayusjhij `seq` pervyim uspeshnyim Git compare-and-swap; prioritetov, TTL, perestanovki i prinuditeljnogo obkhoda net. Nezavisimyiye pishusjhiye linii mogut ispolnyatjsya paralleljno v raznyikh slotakh, a read-only-zadacha ne sozdayot FIFO-bilet toljko radi chteniya.

Obyichnyij osmyislennyij kommit posledovateljnoj imenovannoj linii yavlyayetsya uzlom yeyo prichinnoj cepochki. Do promezhutochnogo kommita worktree-linii uzhe susjhestvuyet rovno odin pervyij exact-bilet: yego mogla zaregistrirovatj samostoyateljno otkryitaya zadacha libo, pri otsutstvii bileta, odna zadacha, sozdannaya vladeljcem. Obyichnaya branch FIFO, vklyuchaya `master`, trebuyet predvariteljno sozdannuyu vladeljcem zadachu i peredayot yeyo identifikator v `commit`. Terminaljnyiye commits rezuljtata, revjyu i integracionnogo kandidata pula, a takzhe `finish-clean`, prodolzheniya ne sozdayut.

## Oglavleniye

- [Granica dvukh runtime-profilej](#granica-dvukh-runtime-profilej)
- [Doverennaya marshrutizaciya novoj zadachi](#doverennaya-marshrutizaciya-novoj-zadachi)
- [Pul aktivnyikh worktree-poduzlov](#pul-aktivnyikh-worktree-poduzlov)
- [Bezopasnyij bootstrap pula](#bezopasnyij-bootstrap-pula)
- [Bezopasnyij HEAD-bootstrap obyichnoj branch FIFO](#bezopasnyij-head-bootstrap-obyichnoj-branch-fifo)
- [Vkhod i ozhidaniye](#vkhod-i-ozhidaniye)
- [Perekhod na aktivnuyu vetochnuyu cepochku](#perekhod-na-aktivnuyu-vetochnuyu-cepochku)
- [Predaktivacionnyij barjyer novoj fork-vetki](#predaktivacionnyij-barjyer-novoj-fork-vetki)
- [Rabota vladeljca](#rabota-vladeljca)
- [Predvariteljnoye sozdaniye prodolzheniya obyichnoj branch FIFO](#predvariteljnoye-sozdaniye-prodolzheniya-obyichnoj-branch-fifo)
- [Atomarnyij commit+handoff](#atomarnyij-commithandoff)
- [Rabota prodolzheniya obyichnoj branch FIFO](#rabota-prodolzheniya-obyichnoj-branch-fifo)
- [Diagnostika i vosstanovleniye](#diagnostika-i-vosstanovleniye)
- [Publikaciya](#publikaciya)
- [Proverka](#proverka)
- [Istochniki trebovanij](#istochniki-trebovanij)

## Granica dvukh runtime-profilej

Instrument soderzhit dva otdeljnyikh runtime-profilya i obsjhij read-only-marshrutizator pered nimi. Obyichnaya ocheredj `ocheredj-zadach-git-vetki.py` serializuyet posledovateljnyiye sessii `master` i drugikh obyichnyikh imenovannyikh linij v odnom fizicheskom checkout cherez `join` i `commit+handoff`. Pul `пул-worktree-подузлов.py` lenivo vyidelyayet nezavisimyim liniyam raznyiye linked worktree i polnyiye refs, serializuyet prodolzheniya kazhdoj linii sobstvennoj FIFO slota i peredayot zamorozhennyiye rezuljtatyi cherez nezavisimyiye revjyu i integraciyu.

Profili ne podmenyayut drug druga. Exact-prodolzheniye worktree-linii vkhodit v FIFO pula imenno etogo slota, polnogo ref i checkout i ne poluchayet novyij worktree; `master` ispoljzuyet obyichnuyu branch FIFO v pervichnom checkout. Terminaljnoye naznacheniye pisatelya, recenzenta ili integratora zakanchivayetsya kvitanciyej rezuljtata, revjyu libo integracionnogo kandidata i obyazateljnogo prodolzheniya ne sozdayot. Odna zadacha ne prevrasjhayetsya mezhdu klassami po dogadke.

## Doverennaya marshrutizaciya novoj zadachi

Obyichnaya novaya zadacha Codex nachinayet iz pervichnogo checkout s read-only route, zagruzhennogo iz aktualjnogo zakommichennogo `HEAD`. Ona peredayot tochnyij kornevoj `CODEX_THREAD_ID`; marshrutizator perechityivayet aktualjnyij plan, polnyiye refs i neizmenyayemyiye kvitancii aktivnyikh linij i vozvrasjhayet ograzhdyonnyij snimok variantov. Agent ocenivayet rolj zadachi i vyibirayet odin klass:

- read-only-zadacha poluchayet toljko pravo chteniya i ne rezerviruyet pisateljskij slot;
- nezavisimyij pisatelj atomarno rezerviruyet v sostoyanii pula, zatem idempotentno pereispoljzuyet libo materializuyet `Подузлы/слот-NNNN` s novyim polnyim ref;
- exact-prodolzheniye vyibirayet odnu liniyu iz exact-snimka; ograzhdyonnaya komanda sozdayot neizmenyayemuyu kvitanciyu namereniya i registriruyet task v FIFO toj zhe linii, ref i worktree bez vtorogo checkout;
- recenzent i integrator vkhodyat toljko po otdeljnyim exact-naznacheniyam s zakreplyonnyimi obyyektami proverki.

Namereniye prodolzheniya mozhet sozdatjsya kak po exact roditeljskomu prompt pered commit+handoff, tak i po samostoyateljnomu vyiboru novoj zadache iz svezhego snimka aktivnyikh linij. Posle sozdaniya ono stanovitsya odnorazovyim exact-dokazateljstvom: otsutstvuyusjhaya, ispoljzovannaya, stale ili nesovpavshaya kvitanciya zakryivayet marshrut otkazom i nikogda ne stanovitsya nezavisimyim vyideleniyem. Imya chata, cwd, pokhozhij ref, odin `HEAD`, roditeljskij tekst ili nalichiye svobodnogo slota ne dokazyivayut klass. `refs/heads/master` yavlyayetsya yavnyim isklyucheniyem razmesjheniya: yego dokazannoye prodolzheniye ispoljzuyet pervichnyij checkout, no nezavisimyij pisatelj, otkryityij iz etogo kataloga bez takoj kvitancii, poluchayet novyij ref i slot.

Rezervaciya Git-sostoyaniya i sozdaniye kataloga worktree ne obrazuyut odnu fajlovuyu tranzakciyu. Poetomu slot snachala poluchayet nedostupnoye drugim zadacham sostoyaniye materializacii, a exact povtor posle poteryannogo otveta prodolzhayet tu zhe rezervaciyu; pravo soderzhateljnoj rabotyi poyavlyayetsya lishj posle polnogo fizicheskogo readback i `admitted`. Sformirovannyij vtoroj bootstrap zakreplyayet exact otnositeljnyij putj slota i trebuyet, chtobyi vse soderzhateljnyiye komandyi peredavali yego kak `repo-root`.

Yesli vyibrannaya vershina soderzhit zaregistrirovannyiye verkhneurovnevyiye Git submodule, materialization slota do fizicheskogo readback avtonomno sozdayot dlya kazhdogo otdeljnyij Git-katalog pod katalogom sistemyi versij exact worktree. Istochnikom sluzhit toljko chistyij, detached, nepoverkhnostnyij i kanonicheski nastroyennyij submodule osnovnoj rabochej kopii na tom zhe gitlink; partial clone, promisor remote, `alternates`, shallow-istochnik i lenivaya setevaya dozagruzka zapresjhenyi. Lokaljnoye klonirovaniye i perenos tracking-ref razreshayut toljko fajlovyij protokol i ne ispoljzuyut zaregistrirovannyiye setevyiye URL. V slote vosstanavlivayutsya kanonicheskiye `origin`, `upstream` i refspec, vyibirayetsya exact detached gitlink, a lokaljnyij putj istochnika ne sokhranyayetsya v konfiguracii. Vlozhennaya rekursiya submodule v etot avtomaticheskij kontur ne vkhodit.

Otsutstvuyusjhij, izmenyonnyij ili netochnyij lokaljnyij istochnik zakryivayet vyideleniye do `git worktree add`: naznacheniye ostayotsya v `materializing`, ocheredj i dopusk ne sozdayutsya, setevoj `init` ne podmenyayet avtomaticheskij marshrut. Obyichnoye vosstanovleniye zaregistrirovannoj zavisimosti posle svezhego clone ostayotsya otdeljnoj yavno vyizyivayemoj operaciyej navyika `fum-proverka-git-zavisimostej`.

Lokaljnyij clone snachala stroit polnyij Git-katalog vo vremennom sosednem puti i lishj zatem atomarno ustanavlivayet yego v kanonicheskoye mesto; otdeljnaya atomarnaya zapisj `.git`-ukazatelya pozvolyayet exact povtoru zavershitj poteryannyij otvet mezhdu etimi fazami. Pri povtornom ispoljzovanii slota prezhnyaya chistaya materialization zaraneye peremesjhayetsya v ograzhdyonnyij karantin, yesli novaya vershina udalila ili pereimenovala yeyo putj, smenila imya sekcii ili zamenila gitlink obyichnyim fajlom, katalogom ili simvolicheskoj ssyilkoj. Proveryayemoye namereniye pereklyucheniya zakreplyayet obe vershinyi, vetku i naznacheniye; exact povtor prinimayet toljko dokazannuyu smesj bajtov prezhnego i celevogo dereva, v tom chisle posle avarii do ili posle obnovleniya `HEAD`. Perekhodnyiye ostatki razreshenyi toljko v zarezervirovannyikh `.fum-*`-putyakh exact Git-kataloga slota; kollizionnyiye imena i puti submodule zapresjhenyi. Karantin i ostatki udalyayutsya toljko posle tochnogo readback novoj vershinyi.

Proverki dopuska, fiksacii rezuljtata, revjyu i osvobozhdeniya yavno ispoljzuyut `--ignore-submodules=none`. Poetomu `submodule.<имя>.ignore=all` iz `.gitmodules` ili konfiguracii ne mozhet skryitj izmenyonnuyu libo nezaregistrirovannuyu rabotu vnutri zavisimosti i peredatj zagryaznyonnyij fizicheskij slot sleduyusjhemu naznacheniyu.

Pervyij read-only-vyizov obyichnoj novoj zadachi iz chistogo pervichnogo checkout:

```text
<HEAD-bootstrap-пула> маршрутизировать \
  --task-id "${CODEX_THREAD_ID:?CODEX_THREAD_ID is required}" \
  --целевая-ссылка refs/heads/master \
  --json
```

Otvet soderzhit `хэш_маршрутизации`, exact OID kazhdogo obyazateljnogo planovogo istochnika, aktivnyiye linii s ikh FIFO-readback i svobodnyiye slotyi. Zadacha obyazana perechitatj ukazannyiye exact-obyyektyi i yavno vyibratj odin klass. Fiksaciya lyubogo pishusjhego vyibora odnoj Git-tranzakciyej CAS-proveryayet target, obyyekt pula i vse queue OID snimka i sokhranyayet yedinstvennyij marshrut exact `task_id`; konkurentnyij vyibor dvukh linij ne mozhet sozdatj dve svyazi. Read-only-klass ne sozdayot route-ref, ne poluchayet pravo pozdnej zapisi i zavershayetsya bez pisateljskogo sostoyaniya. Dopolniteljnyij neizmenyayemyij ref `refs/fum/task-runtime-routes/<sha256(task_id)>` yavlyayetsya obsjhej granicej obyichnoj branch-scoped FIFO, bootstrap-perekhoda `перейти-на-цепочку` i worktree-pula: on atomarno poyavlyayetsya toljko vmeste s pervyim ticket libo perekhodnoj FIFO-zapisjyu sootvetstvuyusjhego marshruta, navsegda zakreplyayet exact branch/worktree/queue libo `assignment_hash`, a inoj profilj poluchayet zakryityij otkaz. Paralleljnaya liniya rezerviruyetsya toljko s tem zhe khyeshem:

```text
<HEAD-bootstrap-пула> зарезервировать-себя \
  --task-id "${CODEX_THREAD_ID:?CODEX_THREAD_ID is required}" \
  --хэш-маршрутизации <sha256:...> \
  --решение параллельная_линия \
  --шаг <exact-step> \
  --разрешённый-путь <path> \
  --json
```

Posle `worktree_reserved` zadacha perenosit rabochij katalog v exact `путь_worktree` i iz nego ispolnyayet scenarij iz vozvrasjhyonnogo `доверенная_ревизия_протокола`, a ne iz tekusjhego slot `HEAD`:

```text
<bootstrap-пула-из-protocol_oid> подтвердить-и-войти \
  --task-id "${CODEX_THREAD_ID:?CODEX_THREAD_ID is required}" \
  --json
```

Dlya `последовательное_продолжение` novaya zadacha ukazyivayet exact liniyu i tot zhe snimok; komanda sozdayot neizmenyayemoye namereniye i FIFO-ticket, no ne novyij worktree:

```text
<HEAD-bootstrap-пула> присоединиться-к-линии \
  --task-id "${CODEX_THREAD_ID:?CODEX_THREAD_ID is required}" \
  --идентификатор-назначения <assignment-id> \
  --хэш-маршрутизации <sha256:...> \
  --решение последовательное_продолжение \
  --json
```

Poluchennyij `хэш_продолжения` vmeste s exact `task_id` idyot v `войти-в-линию-и-ждать` iz starogo slota. Vladelec peredayot pervomu FIFO-ticket komandoj `передать-линию --task-id … --поколение … --хэш-продолжения … --файл-сообщения …`. Odna CAS-tranzakciya dvigayet toljko ref linii, yeyo FIFO i sostoyaniye pula. V dolgovechnom marshrute roditelya i prodolzheniya otdeljno sokhranyayetsya exact handoff receipt, vklyuchaya SHA-256 tochnyikh UTF-8-bajtov soobsjheniya kommita. Poetomu povtor i vosstanovleniye ostayutsya odnoznachnyimi dazhe posle terminala linii i pereispoljzovaniya fizicheskoj FIFO slota, a povtor s inyim soobsjheniyem zakryivayetsya otkazom. Prodolzheniye poluchayet `reload_required`, perechityivayet doverennyij `protocol_oid`, sveryayet fakticheskiye ref/HEAD/worktree-id i vyizyivayet `подтвердить-вершину-линии --вершина <exact-new-head>`. Lishj `admitted` dayot pravo zapisi.

Posle obryiva lyubaya iz etikh sessij snachala vyizyivayet read-only `восстановить-сессию --task-id <exact>`. Otvet vosstanavlivayet prezhniye slot, ref, FIFO, route/continuation hash i sleduyusjhuyu komandu. Pered dopuskayusjhim libo terminaljnyim otvetom odna verify-only Git-tranzakciya sveryayet exact immutable task-route, pool-ref, queue-ref i vershinu worktree `HEAD`; srazu posle neyo readback podtverzhdayet, chto `HEAD` ostayotsya symbolic-ssyilkoj exact branch-ref naznacheniya na toj zhe vershine. Ischeznuvshaya, podmenyonnaya ili smenivshayasya mezhdu chteniyem i otvetom svyazj zakryivayet vosstanovleniye bez novogo marshruta. Exact-povtoryi rezervacii, handoff, ack i terminaljnoj kvitancii vozvrasjhayut prezhnij iskhod bez dublya, prichyom handoff i result replay dopolniteljno trebuyut prezhnij khyesh soobsjheniya kommita.

Eta proverka dayot ustojchivoye vosstanovleniye sredi kooperativnyikh uchastnikov odnogo Git common-dir, no ne prevrasjhayet obsjhij katalog obyyektov i refs v nedoverennuyu granicu bezopasnosti. Process s pryamyim dostupom k common-dir, soznateljno obkhodyasjhij protokol, tekhnicheski mozhet vmeshatjsya; nesovpadeniye budet obnaruzheno i zakryito, no sam dostup ne izolirovan.

Tekusjhij dokumentarnyij i etalonnyij prototip proveryayet exact slot `repo-root` na svoikh vkhodakh, no Codex Desktop poka ne predostavlyayet mashinnyij perenos workspace na urovne host i otdeljnuyu ACK-kvitanciyu etogo perenosa. Kontrakt poetomu ne yavlyayetsya nativnoj izolyaciyej host i ne dokazyivayet otsutstviye chtenij pervichnogo checkout: do poyavleniya host ACK soblyudeniye sformirovannogo workdir-marshruta ostayotsya dopolniteljnoj obyazannostjyu agenta. Linked worktree takzhe razdelyayut object database, refs i Git common-dir.

## Pul aktivnyikh worktree-poduzlov

Pul prednaznachen dlya lokaljnogo parallelizma vnutri odnogo fizicheskogo Git-repozitoriya. Osnovnoj checkout i vse slotyi obyazanyi imetj odin `git-common-dir`; kazhdyij slot pri etom yavlyayetsya otdeljnyim linked worktree s sobstvennyimi `--absolute-git-dir`, `worktree_id`, polnyim `refs/heads/codex/подузлы/...` i `refs/fum/worktree-subnode-session-queues/...`. Pul ne koordiniruyet raznyiye klonyi, raznyiye common-dir ili raznyiye repozitorii. Kornevoj `.gitignore` dolzhen soderzhatj tochnuyu otdeljnuyu stroku, kotoraya Gitignore-yakorem ot kornya isklyuchayet katalog `Подузлы`.

Sostoyaniye pula khranitsya kanonicheskim JSON blob pod `refs/fum/worktree-subnode-pools/<идентификатор-репозитория>` i menyayetsya toljko compare-and-swap vmeste s zatronutyimi ocheredyami. Mashinno-lokaljnyij `primary_root` yavlyayetsya chastjyu lokaljnogo runtime-sostoyaniya; perenosimyim pasportom on ne obyyavlyayetsya.

### Bezopasnyij bootstrap pula

Toljko pervaya read-only-marshrutizaciya iz chistogo pervichnogo checkout mozhet zagruzhatj scenarij iz tochno prochitannogo `HEAD`. Nezakommichennyij fajl rabochego dereva nikogda ne ispolnyayetsya:

```text
python3 -I -c 'import os,subprocess,sys;p="Инструменты/fum-ocheredj-zadach-git-vetki/scripts/пул-worktree-подузлов.py";r=sys.argv[1];e={k:v for k,v in os.environ.items() if not (k.upper().startswith("GIT_") or k.upper().startswith("PYTHON") or k.startswith("FUM_TEST_"))};e["GIT_NO_REPLACE_OBJECTS"]="1";e["GIT_OPTIONAL_LOCKS"]="0";b=subprocess.check_output(["git","--no-replace-objects","-C",r,"show","HEAD:"+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],"--repo-root",r];exec(compile(b,p,"exec"))' . <команда> <аргументы> --json
```

Daleye `<HEAD-bootstrap-пула>` oznachayet vsyu etu formu do `<команда>` i razreshena toljko do sozdaniya assignment. Kak toljko marshrut vernul `доверенная_ревизия_протокола`, lyubaya komanda assignment, vklyuchaya recovery, handoff, review i integration recovery, obyazana ispolnyatj exact bajtyi iz etogo `protocol_oid`. Neproverennyij result/candidate `HEAD` nikogda ne yavlyayetsya istochnikom protokola. `<bootstrap-пула-из-protocol_oid>` ispoljzuyet tu zhe isolated-formu, no peredayot literaljnyij `<protocol_oid>` v `git show <protocol_oid>:…`. Pryamoj vyizov fajla dopustim toljko v avtonomnoj vremennoj fiksture.

### Vyideleniye slota i vosstanovleniye poteryannogo otveta

Koordinator zakreplyayet polnuyu nagruzku naznacheniya do sozdaniya dochernej zadachi:

```text
<HEAD-bootstrap-пула> выделить \
  --идентификатор-назначения <assignment-id> \
  --поколение <generation> \
  --идентификатор-попытки <attempt-id> \
  --базовая-вершина <exact-base-OID> \
  --рабочая-ссылка <refs/heads/codex/подузлы/...> \
  --роль <писатель|рецензент|интегратор> \
  --проект <project-id> \
  --шаг <step-id> \
  --разрешённый-путь <путь> \
  --целевая-ссылка <refs/heads/...> \
  --remote <remote-name> \
  --json
```

`--разрешённый-путь` povtoryayetsya dlya kazhdogo neperesekayusjhegosya puti. Otvet `allocated` libo `allocation_recovered` vozvrasjhayet identifikatoryi slota i worktree, otnositeljnyij putj `Подузлы/слот-NNNN`, ocheredj, ref, bazu, khyesh naznacheniya i gotovyij `промпт_запуска`. Yesli process poteryal otvet posle `git worktree add` ili pereklyucheniya vetki, tochnyij povtor s temi zhe polyami vosstanavlivayet tot zhe slot; novyij ref, inoj payload ili vtoroj assignment s tem zhe ref zakryivayutsya otkazom.

Eta polnaya forma ostayotsya marshrutom otdeljnogo naznacheniya recenzenta, integratora ili terminaljnogo pisatelya. Obyichnomu nezavisimomu pishusjhemu chatu koordinator-roditelj ne nuzhen: doverennyij marshrut vyivodit identichnosti naznacheniya, frozen base, novyij ref i bezopasnyiye znacheniya po umolchaniyu iz tochnogo task, aktualjnogo plana i sostoyaniya pula, zatem ispoljzuyet tot zhe CAS-allokator. Exact-prodolzheniye voobsjhe ne vyizyivayet vyideleniye, a ispoljzuyet prezhniye slot, worktree, ref i FIFO svoyej linii.

Assignment, rabochij ref, result-ref i vyipusjhennyiye kvitancii neizmenyayemyi. Osvobozhdeniye ne udalyayet ref i ne svorachivayet sokhranyonnyij diapazon. Osvobozhdyonnyij fizicheskij slot mozhet poluchitj novoye pokoleniye i novyij ref, no prezhniye naznacheniya, rezuljtatyi, revjyu, integracii i publikacionnyiye kvitancii ostayutsya v istorii pula.

### Sozdaniye otdeljnogo naznacheniya, self-registration i host-privyazka

Dlya otdeljnogo naznacheniya koordinator peredayot host rovno `промпт_запуска` iz otveta `выделить`. Etot putj primenyayetsya k recenzentu, integratoru i yavno delegirovannomu terminaljnomu pisatelyu, no ne trebuyetsya obyichnomu nezavisimomu chatu self-bootstrap. Prompt ne soderzhit absolyutnogo puti i trebuyet, chtobyi novaya zadacha pervyim instrumentaljnyim dejstviyem iz naznachennogo worktree vyipolnila sformirovannyij safe bootstrap. Konkretnaya komanda zakreplyayet v naznachenii `protocol_oid`, ravnyij exact vershine celevoj vetki pri vyidelenii, i zagruzhayet scenarij imenno iz nego, a ne iz neproverennogo `HEAD` recenzenta:

```text
<bootstrap-пула-из-protocol_oid> войти-и-ждать \
  --идентификатор-назначения <assignment-id> \
  --task-id "${CODEX_THREAD_ID:?CODEX_THREAD_ID is required}" \
  --таймаут-секунды 86400 \
  --json
```

Komanda snachala idempotentno vyipolnyayet self-registration yedinstvennogo neaktivnogo bileta, zatem zhdyot gruppovoj aktivacii. Do `state = admitted` rebyonok nichego boljshe ne chitayet i ne menyayet. Recenzent ne schitayet svoj candidate `HEAD` doverennyim istochnikom pravil. Otdeljnaya komanda `зарегистрироваться` susjhestvuyet dlya diagnostiki i fikstur, no shtatnyij dochernij prompt ispoljzuyet sostavnuyu `войти-и-ждать`.

Posle nablyudayemoj self-registration i tochnogo host-otveta koordinator svyazyivayet fakticheskuyu paru bez dogadki i povtornogo sozdaniya:

```text
<HEAD-bootstrap-пула> связать-среду \
  --идентификатор-назначения <assignment-id> \
  --task-id <exact-threadId> \
  --host-id <exact-hostId> \
  --json
```

Odin `task_id` i odin `host_id` ne mogut prinadlezhatj dvum naznacheniyam. Poteryannyij ili neodnoznachnyij host-otvet ne razreshayet podstavitj novuyu zadachu libo sredu: naznacheniye ostayotsya neaktivnyim do exact readback i svyazi.

### Gruppovaya aktivaciya i dopusk

Posle exact host-privyazki vsekh sovmestimyikh naznachenij koordinator odnoj tranzakciyej otkryivayet vsyu gruppu:

```text
<HEAD-bootstrap-пула> активировать \
  --идентификатор-назначения <assignment-a> \
  --идентификатор-назначения <assignment-b> \
  --json
```

Gruppa obyazana imetj raznyiye assignment, slot, putj, worktree, queue-ref, branch-ref, task i host. Peresekayusjhiyesya oblasti recenzenta ili integratora serializuyutsya; dve nezavisimo klassificirovannyiye pishusjhiye linii mogut rabotatj paralleljno dazhe pri peresekayusjhikhsya oblastyakh, potomu chto ikh polnyiye refs razlichayutsya, a tekstovyij konflikt obrabatyivayet otdeljnyij agent-integrator s povtornyim revjyu. Pered CAS povtorno proveryayutsya chistota kazhdogo worktree, exact baza, symbolic ref i yedinstvennyij neaktivnyij bilet. Vse ocheredi gruppyi poluchayut odin khyesh aktivacii atomarno; chastichnoj aktivacii net.

Ozhidayusjhij `войти-и-ждать` sam vyipolnyayet perekhod k vladeljcu i vozvrasjhayet `state = admitted`, pokoleniye vladeniya, khyesh aktivacii, tochnyiye rolj, rabochij ref, target-ref i razreshyonnyiye puti. Komanda `получить-допуск` yavlyayetsya otdeljnyim idempotentnyim shagom etogo zhe perekhoda dlya diagnostiki i fikstur. Toljko posle dopuska zadachi gruppyi mogut dejstviteljno rabotatj paralleljno v svoikh worktree.

### Rezuljtat pisatelya i osvobozhdeniye slota

Pisatelj izmenyayet toljko razreshyonnuyu oblastj i pered terminaljnyim perekhodom ostavlyayet nepustoj staged diff bez unstaged, untracked ili konfliktnyikh putej. Rezuljtat fiksiruyetsya ne obyichnyim `git commit` i ne `commit+handoff`, a komandoj pula:

```text
<bootstrap-пула-из-protocol_oid> зафиксировать-результат \
  --идентификатор-назначения <assignment-id> \
  --task-id <exact-threadId> \
  --message-file <файл-сообщения> \
  --json
```

Komanda prinimayet toljko rolj `писатель`, sveryayet kazhdyij staged-putj s zakreplyonnoj oblastjyu i zakryivayetsya, yesli v FIFO ostalosj khotya byi odno prodolzheniye. Dlya odnosessionnogo assignment ona sozdayot odin determinirovannyij neposredstvennyij commit ot bazyi. Dlya `self_line` ona sozdayot finaljnyij commit ot tekusjhej vershinyi i sokhranyayet v kvitancii vesj exact linejnyij diapazon ot iskhodnoj bazyi, vklyuchaya vse promezhutochnyiye commit+handoff. Odna Git-tranzakciya dvigayet toljko rabochij ref, zamorazhivayet ocheredj i zapisyivayet `fum.квитанция-результата-worktree-подузла.2` s SHA-256 tochnyikh UTF-8-bajtov soobsjheniya kommita. Exact povtor vozvrasjhayet prezhnij `result_frozen`; inoye soobsjheniye, nesovpavshiye vladelec, baza ili nagruzka ne pereispoljzuyut kvitanciyu.

Posle zamorozki koordinator osvobozhdayet fizicheskij slot tochnyim khyeshem rezuljtata:

```text
<bootstrap-пула-из-protocol_oid> освободить \
  --идентификатор-назначения <assignment-id> \
  --хэш-квитанции-результата <sha256:...> \
  --json
```

Osvobozhdeniye trebuyet chistyij worktree na exact result head, otsutstviye vladeljca i ozhidayusjhikh FIFO-biletov, vosstanavlivayemo snimayet vetku so slota cherez detached HEAD i delayet slot dostupnyim novomu naznacheniyu. Result-ref, commit i kvitanciya ne udalyayutsya. Posle `result_frozen` vsya `self_line` terminaljna, a yeyo poslednij vladelec boljshe ne menyayet slot. Sleduyusjhaya nezavisimaya zadacha, recenzent ili integrator poluchayet svobodnyij fizicheskij slot kak novoye assignment s novyim ref.

### Otdeljnyij agent-recenzent

Kazhdyij rezuljtat proveryayet otdeljnoye naznacheniye s roljyu `рецензент`, sobstvennoj zadachej, host, vetkoj i worktree. Yego `--базовая-вершина` pri vyidelenii ravna exact head proveryayemogo obyyekta. Posle dopuska recenzent vyipolnyayet zayavlennyiye proverki, sokhranyayet soderzhateljnyij otchyot v otdeljnom obyichnom fajle i fiksiruyet resheniye:

```text
<bootstrap-пула-из-protocol_oid> зафиксировать-ревью \
  --идентификатор-назначения-рецензента <reviewer-assignment-id> \
  --task-id <exact-threadId> \
  --хэш-объекта-ревью <result-hash|integration-candidate-hash> \
  --вердикт <принято|на_доработку|отклонено> \
  --отчёт <файл-отчёта> \
  --проверка <проверка> \
  --json
```

`--проверка` povtoryayetsya, spisok ne mozhet byitj pustyim. Recenzent obyazan ostavitj worktree chistyim i ne sozdayot kandidatnyij commit. Kvitanciya svyazyivayet exact obyyekt, head, ref, task, host, verdikt, proverki i SHA-256 otchyota, posle chego slot recenzenta osvobozhdayetsya. Proverka `публикационная чистота` odnovremenno sokhranyayet durable `publication_pending` intent rezuljtata nezavisimo ot merge-verdikta. Plan sliyaniya prinimayet dlya kazhdogo result rovno odno otdeljnoye revjyu s verdiktom `принято`.

Yesli exact obyyekt uzhe voshyol v prinyatuyu integraciyu ranjshe zaversheniya recenzenta, pozdnij otvet ne stanovitsya novyim verdiktom i ne menyayet `reviews` libo `publications`. Komanda proveryayet neizmenyonnyiye object ref, assignment, owner i sokhranyonnyij `integration_hash`, otsoyedinyayet chistyij reviewer-worktree i odnoj CAS-tranzakciyej vyidayot terminaljnuyu kvitanciyu `review_sealed`, osvobozhdaya ocheredj i slot. Poteryannyij otvet vosstanavlivayetsya po etoj kvitancii dazhe posle polnogo pereispoljzovaniya fizicheskogo slota.

### Otdeljnyij agent-integrator i konflikt sliyaniya

Integrator takzhe poluchayet otdeljnoye naznacheniye i worktree s roljyu `интегратор`, base OID ravnyim ozhidayemoj vershine celi i tochnyim `target_ref`. Posle prinyatyikh revjyu rezuljtatov on zapuskayet ograzhdyonnyij plan:

```text
<bootstrap-пула-из-protocol_oid> слить-результаты \
  --идентификатор-назначения-интегратора <integrator-assignment-id> \
  --task-id <exact-threadId> \
  --хэш-результата <result-hash-a> \
  --хэш-результата <result-hash-b> \
  --хэш-ревью <accepted-review-hash-a> \
  --хэш-ревью <accepted-review-hash-b> \
  --json
```

Naboryi rezuljtatov i revjyu zakreplyayutsya v plane i ne menyayutsya pri povtore. Integrator posledovateljno sozdayot obyichnyiye mnogoroditeljskiye merge-kommityi, sokhranyaya kazhdyij polnyij result-diapazon v rodoslovnoj. Yesli Git obnaruzhivayet konflikt, komanda vozvrasjhayet nenulevoj kod i `state = integration_conflict`, a worktree i vladeniye ostayutsya u togo zhe integratora. Agent razreshayet konflikt v etom worktree, polnostjyu ustranyayet unmerged i unstaged puti, pomesjhayet resheniye v indeks i prodolzhayet:

```text
<bootstrap-пула-из-protocol_oid> продолжить-слияние \
  --идентификатор-назначения-интегратора <integrator-assignment-id> \
  --task-id <exact-threadId> \
  --json
```

Posle vsego diapazona pul zamorazhivayet `fum.квитанция-интеграционного-кандидата-worktree-подузлов.1`, vklyuchaya vkhodnyiye rezuljtatyi i revjyu, polnyij spisok integracionnyikh commits i priznak agentskogo razresheniya konflikta. Slot integratora osvobozhdayetsya, no yego ref i kandidat sokhranyayutsya.

### Nezavisimoye revjyu kandidata i exact CAS celi

Integracionnyij kandidat nezavisimo proveryayet yesjhyo odin agent-recenzent. On vyidelyayetsya na exact `head_oid` kandidata i vyizyivayet tu zhe `зафиксировать-ревью`, peredavaya `integration-candidate-hash`. Revjyu otdeljnyikh rezuljtatov ne zamenyayet eto povtornoye revjyu, a integrator ne mozhet odobritj sobstvennyij kandidat.

Toljko otdeljnaya kvitanciya kandidata s verdiktom `принято` razreshayet koordinatoru prodvinutj celj:

```text
<bootstrap-пула-из-protocol_oid> продвинуть-цель \
  --хэш-интеграционного-кандидата <sha256:...> \
  --хэш-ревью <accepted-integration-review-hash> \
  --целевая-ссылка <refs/heads/...> \
  --ожидаемая-вершина <exact-base-OID> \
  --task-id <CODEX_THREAD_ID-владельца-основной-FIFO> \
  --generation <generation-владельца-основной-FIFO> \
  --идентификатор-продолжения <exact-threadId-продолжения> \
  --json
```

Komanda povtorno proveryayet candidate ref, exact target/base, otdeljnoye revjyu s obyazateljnoj proverkoj `публикационная чистота`, dostizhimostj vsekh result heads, exact vladeljca obyichnoj branch FIFO i zaraneye sozdannyij ozhidayusjhij ticket prodolzheniya. Most ispolnyayet exact bajtyi ocheredi iz zakreplyonnogo doverennogo `protocol_oid` v `python -I`, ochisjhaya `GIT_*`, `PYTHON*` i `FUM_TEST_*`; nezakommichennyij fajl checkout i neproverennyij candidate `HEAD` ne ispolnyayutsya. Obyichnaya FIFO samostoyateljno proveryayet zakryityij old→new-perekhod pula: neizmennostj postoronnikh polej, exact candidate, prinyatoye nezavisimoye revjyu, pereschitannyij khyesh kvitancii i exact pending intent. Checkout snachala gotovitsya k tochnomu derevu kandidata bez izmeneniya ref. Zatem odna Git-tranzakciya dvigayet target, peredayot obyichnuyu FIFO rebyonku, sozdayot neizmenyayemuyu kvitanciyu prinyatoj integracii, zapisyivayet `fum.квитанция-CAS-интеграции-worktree-подузлов.1`, sokhranyayet pending intent remote-target i CAS-obnovlyayet pul. Poetomu `master` neljzya sdvinutj pod inyim FIFO-vladeljcem, a padeniye ne ostavlyayet ocheredj na staroj baze. Proigrannyij CAS vosstanavlivayet checkout k fakticheskomu target `HEAD`, a stale base ne perepisyivayet konkuriruyusjhuyu vershinu; exact povtor vosstanavlivayetsya iz kvitancii. Uspekh yavlyayetsya obyichnyim terminaljnyim `commit+handoff`: prezhnij korenj posle otveta ne vyipolnyayet publikaciyu, a prodolzheniye snachala perechityivayet novyij HEAD, poluchayet dopusk i obrabatyivayet pending intent.

### Publikaciya rezuljtata i prinyatoj integracii

Rezuljtat mozhno opublikovatj v zaraneye nastroyennyij imenovannyij remote nezavisimo ot merge-verdikta, yesli khotya byi odno yego agentskoye revjyu soderzhit tochnuyu proverku `публикационная чистота`:

```text
<HEAD-bootstrap-пула> опубликовать-результат \
  --хэш-результата <result-hash> \
  --remote <remote-name> \
  --task-id <CODEX_THREAD_ID-владельца-основной-FIFO> \
  --generation <generation-владельца-основной-FIFO> \
  --json
```

Verdiktyi `на_доработку` i `отклонено` zapresjhayut vklyuchatj rezuljtat v plan integracii, no ne unichtozhayut publikacionno chistyij kandidat i ne zapresjhayut peredatj yego tochnyij ref. Komanda nikogda ne dvigayet celevoj `master`: ona publikuyet neizmennyij result-ref pod tem zhe polnyim imenem, delayet avtoritetnyij `ls-remote` readback i sokhranyayet otdeljnuyu kvitanciyu.

Prinyataya lokaljnaya integraciya publikuyetsya toljko po exact CAS-kvitancii:

```text
<HEAD-bootstrap-пула> опубликовать-интеграцию \
  --хэш-квитанции-интеграции <integration-hash> \
  --remote <remote-name> \
  --task-id <CODEX_THREAD_ID-владельца-основной-FIFO> \
  --generation <generation-владельца-основной-FIFO> \
  --json
```

Obe komandyi trebuyut exact vladeljca osnovnoj FIFO. Politika transporta prinimayet rovno odin syiroj `remote.<name>.url` i ne boleye odnogo `pushurl`, zakreplyayet oba znacheniya khyeshem intent i peredayot Git bukvaljnyij adres, a ne imya remote. Sovpadeniye adresa s remote-psevdonimom i lyuboye primenimoye `url.*.insteadOf` libo `url.*.pushInsteadOf` zakryivayut publikaciyu do transporta. Push soderzhit toljko exact `<OID>:<полный-ref>` i yavno otklyuchayet follow-tags, rekursivnuyu publikaciyu submodule, signed push i push-options, poetomu soprovozhdayusjhiye refs i pobochnyiye transportnyiye dejstviya ne dobavlyayutsya.

Target pered pervyim push mozhet otsutstvovatj libo sovpadatj s lokaljnyimi base/head, a inaya vershina zakryivayet publikaciyu. Neodnoznachnyij push, nedostupnyij readback ili vremennyij remote-otkaz ostavlyayet dolgovechnyij `publication_pending`: lokaljnyiye refs, rezuljtatyi i integraciya sokhranyayutsya. Kazhdaya vnovj dopusjhennaya kornevaya zadacha do vyibora sleduyusjhej kartochki avtomaticheski povtoryayet vesj backlog odnoj komandoj:

```text
<HEAD-bootstrap-пула> повторить-ожидающие-публикации \
  --task-id <CODEX_THREAD_ID-владельца-основной-FIFO> \
  --generation <generation-владельца-основной-FIFO> \
  --json
```

Retry ne sozdayot novyij slot, rezuljtat, revjyu ili integraciyu i ne ispoljzuyet force-push. Podtverzhdyonnaya publikaciya trebuyet exact `ls-remote` readback; izmeneniye zakreplyonnogo URL ili uzhe opublikovannogo ref zakryivayetsya otkazom vmesto perepisyivaniya.

### Sostoyaniye i diagnosticheskaya granica

Tochnoye naznacheniye mozhno chitatj bez izmeneniya:

```text
<bootstrap-пула-из-protocol_oid> состояние --идентификатор-назначения <assignment-id> --json
```

Otvet pokazyivayet slot, worktree, ocheredj, ref, bazu, task/host, aktivaciyu, rezuljtat i reviziyu pula. On ne vyidayot polnomochiye pisatj, aktivirovatj libo pereispoljzovatj chuzhuyu zadachu. Sluzhebnyiye refs i kvitancii pula yavlyayutsya lokaljnyim runtime-sostoyaniyem i ne zamenyayut perenosimyiye otchyotyi pamyati FUM.

## Bezopasnyij HEAD-bootstrap obyichnoj branch FIFO

Sessiya obyichnoj branch FIFO ne ispolnyayet scenarij iz nezakommichennogo rabochego dereva. Vse yeyo komandyi ispoljzuyut odnu formu:

```text
python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . <команда> <аргументы>
```

Isolated mode, ochistka `GIT_*`, zapret replace-obyyektov i zakreplyonnyij `--repo-root` isklyuchayut perenapravleniye operacii cherez gryaznyij checkout ili unasledovannuyu Git-sredu. Pryamoj vyizov scenariya iz rabochego dereva dopustim toljko v avtonomnyikh vremennyikh fiksturakh.

## Vkhod i ozhidaniye

Posle doverennogo marshruta komanda `join` primenyayetsya toljko dlya dokazannoj obyichnoj branch FIFO, vklyuchaya `refs/heads/master` v pervichnom checkout i dolgovechnyiye nepulovyiye linii. Worktree-liniya vmesto neyo ispoljzuyet `подтвердить-и-войти` dlya pervogo vladeljca libo `присоединиться-к-линии → войти-в-линию-и-ждать` dlya prodolzheniya. Read-only-zadacha bez pisateljskogo dopuska ni odnu FIFO ne zanimayet.

Zadacha peredayot svoj tochnyij `CODEX_THREAD_ID`:

```text
<HEAD-bootstrap> join --task-id <CODEX_THREAD_ID> --json
```

Zamena otsutstvuyusjhemu identifikatoru ne pridumyivayetsya. Marshrutizator do `join` obyazan dokazatj nachaljnuyu kvitanciyu vkhoda libo exact-kvitanciyu prodolzheniya; otsutstviye ili mismatch ne razreshayet pryamoj vkhod i ne sozdayot druguyu liniyu kak rezervnyij marshrut. `admitted` vozvrasjhayet `generation` i `base_head`, kotoryiye vladelec sokhranyayet do terminaljnogo perekhoda. `waiting` ne razreshayet chitatj nezakonchennyij diff linii kak vkhod, menyatj checkout, indeks, refs ili vneshneye sostoyaniye.

Ozhidayusjhaya zadacha ispoljzuyet odin dolgozhivusjhij vyizov:

```text
<HEAD-bootstrap> wait-until-actionable --task-id <CODEX_THREAD_ID> --json
```

Zapasnoj ogranichennyij vyizov `wait --timeout-seconds 300` prednaznachen toljko dlya sredyi, kotoraya ne uderzhivayet odin process. Vremya ne menyayet poryadok i ne snimayet bilet. Sobstvennyij ozhidayusjhij bilet do dopuska mozhno otmenitj tochnoj komandoj `cancel`; chuzhoj bilet i vladelec etim putyom ne udalyayutsya.

Posle kommita predshestvennika perednij bilet poluchayet `reload_required`. Zadacha perechityivayet novyij zakommichennyij `AGENTS.md`, etot navyik i zatronutyiye materialyi, poluchayet tochnyij `git rev-parse HEAD`, zatem vyipolnyayet:

```text
<HEAD-bootstrap> ack-head --task-id <CODEX_THREAD_ID> --head <точный-HEAD> --json
<HEAD-bootstrap> wait-until-actionable --task-id <CODEX_THREAD_ID> --json
```

Pravo zapisi poyavlyayetsya toljko posle novogo `admitted`.

## Perekhod na aktivnuyu vetochnuyu cepochku

Yavno vyibrannaya novaya aktivnaya kartochka cepochki ne obkhodit yedinyij runtime-route. `перейти-на-цепочку` yavlyayetsya otdeljnyim bootstrap-profilem ordinary FIFO: pervaya tranzakciya odnovremenno proveryayet iskhodnyij polnyij ref na exact iskhodnoj vershine, sozdayot immutable task-route, otsutstvuyusjhij `refs/heads/codex/...` na toj zhe vershine i perekhodnuyu zapisj pustoj ocheredi; vtoraya sveryayet exact OID tekusjhego `HEAD`, route i obyyekt perekhodnoj FIFO, pereklyuchayet symbolic `HEAD` i dopuskayet togo zhe vladeljca. Podgotovka, dopusk i zavershyonnyij replay ograzhdenyi zapisannyimi source HEAD OID, task-route i queue OID; replay dopolniteljno vyipolnyayet yedinyij verify-only snimok symbolic `HEAD`, iskhodnogo ref, ocheredi, route i otsutstviya annulirovaniya. Poteryannyij otvet vosstanavlivayet toljko exact perekhod, a zadacha s worktree-, delegated- ili inyim ordinary-marshrutom poluchayet zakryityij otkaz bez dvizheniya vetki. Komanda prinimayet tochnyiye ID i khyesh kartochki, iskhodnyij polnyij ref i `HEAD`, trebuyet chistyij checkout i pustuyu ocheredj; uzhe dopusjhennyij vladelec vetku ne pereklyuchayet. Etot specialjnyij branch-bootstrap ne yavlyayetsya pereklyucheniyem uzhe vyidelennogo worktree-naznacheniya: obyichnaya novaya paralleljnaya liniya vyibirayet svoj ref do materializacii slota.

## Predaktivacionnyij barjyer novoj fork-vetki

Kornevoj reyestr nachaljnogo dvoichnogo zapuska do host-vyizova zakryivayet pervyij `join` kazhdogo novogo zhivogo klona nesvyazannyim barjyerom. Dlya etogo v checkout s pustoj ocheredjyu i tochnyim symbolic `HEAD` on snachala zakreplyayet vetochnyiye ograzhdeniya i identifikator kliyentskoj popyitki, yesjhyo ne znaya budusjhij `threadId` i ne pripisyivaya popyitke budusjhuyu kvitanciyu aktivacii:

```text
<HEAD-bootstrap> установить-барьер-предактивации --ветка <refs/heads/...> --базовая-вершина <HEAD> --идентификатор-форка <fork> --поколение-запуска <поколение> --идентификатор-попытки-создания <client-attempt> --идентификатор-назначения <assignment> --хэш-назначения <sha256:...> --идентификатор-ресурсной-попытки <resource-attempt> --хэш-ресурсного-допуска <sha256:...> --json
```

Komanda sokhranyayet neizmenyayemoye ograzhdeniye v checkout-scoped Git-reyestre skhemyi `fum.реестр-барьеров-предактивации.2`: exact identifikator i khyesh strukturirovannogo naznacheniya, exact identifikator resursnoj popyitki i khyesh vyidannogo do host-vyizova resursnogo dopuska. Reyestr `.1` yavno fail-closed kak ustarevshij i ne migriruyetsya avtomaticheski. Ustanovka ne sozdayot FIFO-bilet i queue-ref. Povtor s temi zhe polyami yavlyayetsya idempotentnyim; izmeneniye lyubogo ograzhdeniya, vetki ili bazyi zakryivayet perekhod. Ustanovka posle poyavleniya vladeljca libo ozhidayusjhego bileta zapresjhena. Toljko posle yeyo uspeshnogo otveta koordinator vprave sovershitj yedinstvennyij host-vyizov sozdaniya; neodnoznachnyij iskhod ne razreshayet privyazku naugad i ostavlyayet vse `join` zakryityimi sostoyaniyem `задача_барьера_не_связана`.

Posle tochnogo otveta host koordinator otdeljnyim CAS svyazyivayet barjyer s fakticheskimi `threadId`, `hostId`, khyeshem polnogo konverta i kanonicheski pereschitannyim khyeshem etoj privyazki; etot perekhod yesjhyo ne otkryivayet FIFO i ne zapisyivayet budusjhuyu kvitanciyu:

```text
<HEAD-bootstrap> связать-задачу-барьера --task-id <threadId> --host-id <hostId> --хэш-конверта <sha256:...> --хэш-привязки <sha256:...> --ветка <refs/heads/...> --базовая-вершина <HEAD> --идентификатор-форка <fork> --поколение-запуска <поколение> --идентификатор-попытки-создания <client-attempt> --идентификатор-назначения <assignment> --хэш-назначения <sha256:...> --идентификатор-ресурсной-попытки <resource-attempt> --хэш-ресурсного-допуска <sha256:...> --ожидаемый-объект-реестра <OID-несвязанного-реестра> --json
```

Dubliruyusjhaya, netochnaya ili ustarevshaya privyazka ne menyayet reyestr. Svyazannaya neaktivnaya zadacha mozhet vyipolnitj svoyo obyazateljnoye pervoye dejstviye `join`, no poluchayet `предактивация_не_подтверждена`: ni bilet, ni queue-ref pri etom ne voznikayut. Poka exact-zadacha ne voshla posle otkryitiya, lyubaya drugaya zadacha etoj vetki poluchayet `барьер_предактивации_занят`.

Toljko posle yedinogo CAS kornevogo reyestra koordinator otkryivayet barjyer tochnyim obyyektom prezhnego Git-reyestra:

```text
<HEAD-bootstrap> открыть-барьер-предактивации --task-id <threadId> --ветка <refs/heads/...> --базовая-вершина <HEAD> --идентификатор-форка <fork> --поколение-запуска <поколение> --идентификатор-попытки-создания <client-attempt> --идентификатор-назначения <assignment> --хэш-назначения <sha256:...> --идентификатор-ресурсной-попытки <resource-attempt> --хэш-ресурсного-допуска <sha256:...> --квитанция-активации <sha256:...> --хэш-предактивации <sha256:...> --хэш-привязки-пары <sha256:...> --хэш-привязки-пары <sha256:...> --хэш-активации <sha256:...> --ожидаемый-объект-реестра <OID-связанного-реестра> --json
```

Otkryitiye sravnivayet vse ograzhdeniya, exact CAS-osnovu i neizmennuyu vetochnuyu vershinu, trebuyet rovno dva raznyikh sortirovannyikh khyesha host-privyazok i samo pereschityivayet obsjheye kornevoye dokazateljstvo skhemyi `.2` iz pokoleniya, khyesha predaktivacii, obsjhej kvitancii i etoj paryi. Khyesh kazhdoj host-privyazki skhemyi `.2` kommitit vse chetyire exact resursnyikh polya svoyej storonyi, poetomu obsjhij khyesh aktivacii svyazyivayet obe raznyiye resursnyiye storonyi tranzitivno, a ne podmeshivayet branch-local tuple v obsjhij payload. Povtor tochnogo uspeshno otkryitogo perekhoda vosstanavlivayet tu zhe zapisj; ustarevshij obyyekt ili izmenyonnoye pole otklonyayutsya. Pervyij posleduyusjhij `join` odnoj tranzakciyej proveryayet neizmennostj reyestra barjyerov, iskhodnogo branch-ref i aktivirovannoj bazovoj vershinyi i zapisyivayet obyichnyij FIFO-bilet. Vyidelennyij `seq` i ozhidayusjhij bilet ne dokazyivayut dopusk exact-zadachi: do yeyo fakticheskogo perekhoda vo vladeljca chuzhoj bilet ne sozdayotsya, otmena yeyo ozhidayusjhego bileta ne otkryivayet chuzhoj pervyij dopusk, a povtornyij exact-vkhod snova proveryayet iskhodnuyu bazu. Atomarnyij perekhod exact-zadachi vo vladeljca sokhranyayet v ocheredi neizmenyayemoye svideteljstvo, posle kotorogo prodolzheniya mogut registrirovatjsya obyichnyim FIFO. Pervyij i kazhdyij posleduyusjhij bilet sokhranyayut i pered dopuskom povtorno sveryayut vse chetyire exact polya s otkryityim checkout-scoped barjyerom. Checkout navsegda svyazan s odnoj nachaljnoj vetkoj: pereklyucheniye symbolic `HEAD` ne otkryivayet obkhod. Posle vkhoda exact-zadachi vetka ispoljzuyet toljko prezhnij unarnyij protokol prodolzhenij; roditeljskaya FIFO ne vyidayotsya za vladeniye rebyonka, a barjyer ne stanovitsya planirovsjhikom, dispetcherom ili vtoryim vladeljcem.

## Rabota vladeljca

Vladelec ne vyizyivayet obyichnyij `git commit`, ne pereklyuchayet vetku i ne pozvolyayet subagentam menyatj indeks ili istoriyu. Korenj mozhet paralleljno delegirovatj neperesekayusjhiyesya fajlyi, no do staging i terminaljnogo perekhoda dozhidayetsya vsekh processov i subagentov, sposobnyikh pozdneye zapisatj rezuljtat.

Yesli zakonnaya rabota ne trebuyet izmeneniya — naprimer, pryamoj vetochnyij selector vernul `done` ili `not_ready`, — vladelec ostanavlivayet pisatelej i vyipolnyayet:

```text
<HEAD-bootstrap> finish-clean --task-id <CODEX_THREAD_ID> --generation <generation> --json
```

Komanda trebuyet neizmennyij `HEAD`, chistyiye indeks i rabocheye derevo i odnoj Git-tranzakciyej peredayot FIFO bez kommita. Uzkij `finish-own-clean` vosstanavlivayet takoye zhe chistoye zaversheniye toljko dlya tochnogo tekusjhego vladeljca i ne obkhodit proverki. Posle `finished_clean` prezhnyaya zadacha nichego ne menyayet i ne sozdayot prodolzheniye.

## Predvariteljnoye sozdaniye prodolzheniya obyichnoj branch FIFO

Etot razdel otnositsya k `master` i drugim obyichnyim imenovannyim vetkam, no ne k FIFO self-line pula, opisannoj vyishe. Do host-vyizova vladelec obyichnoj branch FIFO zavershayet soderzhateljnuyu rabotu, proverki, zhurnaljnyij otchyot, recency, publikacionnyij prosmotr diff i staging. Zatem ograzhdyonnyij perekhod zakreplyayet neizmenyayemuyu kvitanciyu prodolzheniya i formiruyet prompt:

```text
<HEAD-bootstrap> сформировать-промпт-продолжения --task-id <CODEX_THREAD_ID-владельца> --json
```

Kvitanciya svyazyivayet identichnostj imenovannoj linii, polnyij tekusjhij `refs/heads/...`, fizicheskij checkout, yego FIFO, roditeljskiye task i generation i iskhodnyij `HEAD`. Prompt soderzhit yeyo tochnyij khyesh i identichnostj roditelya, ne soderzhit absolyutnogo puti, host-identifikatora ili zaraneye vyibrannoj kartochki i trebuyet ot rebyonka pervyim instrumentaljnyim dejstviyem vyipolnitj doverennyij read-only-marshrut. Marshrut registriruyet `join` toj zhe branch FIFO; otsutstviye, ispoljzovaniye ili mismatch kvitancii zakryivayet vkhod bez nezavisimogo vyideleniya.

Roditelj poluchayet exact sokhranyonnyij proyekt cherez host `list_projects` i rovno odin raz vyizyivayet `create_thread` v etom proyekte s lokaljnoj sredoj, bez yavnyikh `model`, `thinking` i vtorogo worktree. Novaya host-zadacha ispoljzuyet tot zhe fizicheskij checkout obyichnoj linii; dlya `master` on ostayotsya pervichnyim. Uspekh dokazyivayut toljko nepustyiye tochnyiye `threadId` i `hostId` odnogo otveta. Oshibka, tajm-aut, poteryannyij otvet ili odin `clientThreadId` zapresjhayut kommit i avtomaticheskij povtor: vozmozhnoye sozdaniye neljzya otlichitj ot otsutstviya.

Sozdannaya zadacha do peredachi toljko predyyavlyayet kvitanciyu marshrutizatoru, vyipolnyayet `join` so svoim fakticheskim `CODEX_THREAD_ID` i zhdyot. Roditelj prodolzhayet lishj posle read-only `status`, podtverzhdayusjhego rovno odin bilet s exact `task_id = threadId`, khyeshem kvitancii prodolzheniya, temi zhe worktree/FIFO/polnoj vetkoj i `acknowledged_head`, ravnyim `base_head` vladeljca. Etot bilet ne obyazan byitj pervyim: uzhe zaregistrirovannyiye boleye ranniye zadachi sokhranyayut pozicii, a prodolzheniye ne poluchayet skryitogo prioriteta. `hostId` i sokhranyonnyij proyekt proveryayet roditelj na host-granice; ocheredj dokazyivayet Git-storonu svyazi.

## Atomarnyij commit+handoff

Posle exact waiting-bileta vladelec vyizyivayet:

```text
<HEAD-bootstrap> commit --task-id <CODEX_THREAD_ID-владельца> --generation <generation> --идентификатор-продолжения <threadId-ребёнка> --message-file <файл> --json
```

Aktivirovannyij protokol posledovateljnoj imenovannoj linii mashinno trebuyet `--идентификатор-продолжения` i svyazannuyu s biletom exact-kvitanciyu prodolzheniya. Yedinstvennoye bootstrap-isklyucheniye — tekusjhaya sessiya, uzhe dopusjhennaya prezhnim `HEAD`: migracionnaya zadacha odin raz zakreplyayet ekvivalentnyiye prompt i kvitanciyu sama i vsyo ravno zaraneye sozdayot exact ozhidayusjhego rebyonka. Nalichiye kanonicheskogo markera v novom `HEAD` aktiviruyet trebovaniye, a svyazannyij kommit zakreplyayet neobratimyij priznak v ocheredi; posleduyusjheye udaleniye markera ne vozvrasjhayet legacy-rezhim. Terminaljnyiye commits result, review i integration candidate pula prokhodyat sobstvennyiye komandyi i kvitancii i etim trebovaniyem ne okhvatyivayutsya.

Do `write-tree` i `commit-tree`, a zatem povtorno na svezhem obyyekte ocheredi vnutri CAS komanda proveryayet:

- tochnyikh vladeljca, `generation`, polnyij ref i iskhodnyij `HEAD`;
- otsutstviye unstaged, untracked i konfliktnyikh putej i nalichiye nepustogo staged-dereva;
- otlichiye rebyonka ot vladeljca;
- rovno odin exact waiting-bilet rebyonka;
- `acknowledged_head` rebyonka, ravnyij `base_head` vladeljca.

Yesli bilet otmenilsya posle pervoj proverki, Git mozhet poluchitj nedostizhimyiye tree/commit/blob-obyyektyi, no branch-ref, queue-ref i kvitanciya ne menyayutsya. Dokumentiruyemaya atomarnostj otnositsya k ssyilkam i nablyudayemomu sostoyaniyu, a ne k otsutstviyu nedostizhimyikh obyyektov.

Uspeshnaya `update-ref --stdin`-tranzakciya odnovremenno:

- dvigayet tochnyij `refs/heads/...` s `base_head` na novyij kommit;
- snimayet vladeljca i sokhranyayet `last_completion` so svyazjyu, ne pereuporyadochivaya ozhidayusjhiye biletyi;
- sozdayot neizmenyayemuyu kvitanciyu prodolzheniya pod branch- i checkout-scoped `refs/fum/`.

Kvitanciya svyazyivayet fizicheskuyu rabochuyu kopiyu, polnyij ref, roditeljskiye `task_id` i `generation`, staryij i novyij HEAD i exact identifikator rebyonka. Ona ne perezapisyivayetsya sleduyusjhej peredachej FIFO. Poetomu povtor toj zhe komandyi posle poteryannogo Git-otveta vozvrasjhayet prezhnij `committed` dazhe posle `finish-clean` ili kommita rebyonka; inoj libo otsutstvuyusjhij identifikator dayot bezopasnyij otkaz. Dlya svyazannogo kommita snyatyiye dispatcher-, reservation-, claim-, ledger- i analytics-perekhodyi ne ispolnyayutsya.

Uspekh prinimayetsya toljko pri nulevom kode i polnom yedinstvennom JSON s tochnyimi `state = committed`, `task_id`, `generation`, `old_head`, `new_head`, `branch_ref`, polnyim `queue_oid` i `идентификатор_продолжения`. Neizvestnyij iskhod razreshayet lishj tochnyij povtor etoj Git-komandyi s tem zhe rebyonkom, no ne vtoroj `create_thread`.

Posle `committed` roditelj ne menyayet Git, checkout, ocheredj ili host-sostoyaniye i ne vyizyivayet `create_thread`, `push` libo publikaciyu. Razreshenyi toljko finaljnyij otvet i interfejsnyiye direktivyi.

## Rabota prodolzheniya obyichnoj branch FIFO

Kogda bilet rebyonka obyichnoj branch FIFO posle odnoj ili neskoljkikh peredach stanovitsya pervyim, on poluchayet `reload_required`, perechityivayet fakticheskij tekusjhij `HEAD` iz togo zhe checkout, vyipolnyayet `ack-head` i dozhidayetsya `admitted`. Boleye rannyaya zadacha mogla zakonno dobavitj v tot zhe ref sleduyusjhij kommit; staryij prompt ne zakreplyayet rebyonka na prezhnej vershine i ne razreshayet drugoj checkout. Posle dopuska on snachala vyizyivayet `повторить-ожидающие-публикации` profilya pula so svoimi exact `task_id` i `generation`, a zatem napryamuyu vyizyivayet:

```text
python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py show --repo-root . --json
```

Mezhdu sessiyej i selector net heartbeat, dispetchera, obsjhej rezervacii ili kartochochnogo claim. `ready` razreshayet ispolnitj odnu tochnuyu kartochku; `done` i `not_ready` privodyat k `finish-clean`. Kazhdyij sobstvennyij kommit rebyonka povtoryayet predvariteljnoye sozdaniye sleduyusjhego prodolzheniya.

## Diagnostika i vosstanovleniye

Read-only `status --json` pokazyivayet tekusjhij polnyij ref, queue OID, vladeljca, ozhidayusjhiye biletyi i `next_seq`. Ocheredj khranitsya kak kanonicheskij JSON blob pod checkout-scoped `refs/fum/worktree-task-queues/...` i podderzhivayet SHA-1 i SHA-256 object format.

Periodicheskij heartbeat, postoyannaya zadacha dispetchera, avtomaticheskoye vozobnovleniye, `heartbeat-status`, obsjhij reyestr zadanij, reservation/claim i pochinka avtozapuska snyatyi. Ostavshiyesya CLI i refs prezhnikh skhem yavlyayutsya toljko istoricheskoj sovmestimostjyu i ne dayut tekusjhej zadache polnomochij. Ni molchalivoye padeniye, ni dolgoye vyipolneniye ne razreshayut avtomaticheski udalitj bilet.

Staryij dispatcher-only shtatnyij sbros takzhe ne yavlyayetsya dejstvuyusjhim marshrutom. Otkryitoye trebovaniye bezopasnogo host-stop ne realizovano tekusjhej poverkhnostjyu. Dostupnyij cheloveku `./sbrositj.sh` — otdeljnyij podtverzhdayemyij break-glass: on stroit tochnyij TTY-plan, arkhiviruyet obsluzhivayemyiye runtime-refs, vosstanavlivayet indeks i tracked-derevo k tekusjhemu HEAD, udalyayet toljko podtverzhdyonnyiye neignoriruyemyiye obyichnyiye fajlyi i simvolicheskiye ssyilki i vyipuskayet svezhuyu pustuyu ocheredj. On ne ostanavlivayet Codex-zadachi, ne vyiyasnyayet iskhod neodnoznachnogo `create_thread` i ne sozdayot prodolzheniye.

Obyichnaya branch FIFO ne koordiniruyet otdeljnyiye klonyi i otklonyayet odnu imenovannuyu vetku, otkryituyu srazu v neskoljkikh worktree. Detached HEAD v etom profile ne podderzhivayetsya. Otdeljnyij pul vyishe namerenno koordiniruyet linked worktree odnogo common-dir, no toljko s raznyimi polnyimi branch refs i sobstvennyimi ocheredyami slotov; eto ne rasshiryayet polnomochiya obyichnoj ocheredi. Process, soznateljno ignoriruyusjhij `AGENTS.md`, tekhnicheski ne perekhvatyivayetsya.

## Publikaciya

Lokaljnyij `commit+handoff` obyichnoj branch FIFO ne vyipolnyayet push. Ruchnaya publikaciya poljzovatelya libo otdeljno avtorizovannyij nizkourovnevyij `publish` ostayotsya samostoyateljnyim transportnyim dejstviyem s tochnyimi commit/ref/URL i ne vkhodit v prichinnuyu cepochku prodolzhenij. Komandyi `опубликовать-результат` i `опубликовать-интеграцию` prinadlezhat toljko otdeljnomu profilyu pula i trebuyut yego kvitancii, proverki i avtoritetnyij remote-readback.

## Proverka

Avtonomnyij nabor zapuskayetsya bez seti i sekretov:

```text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocheredj-zadach-git-vetki/tests -p 'test_*.py'
```

Testyi obyichnogo profilya pokryivayut FIFO, ozhidaniye, `reload_required`/`ack-head`, clean-handoff, vetochnyij perekhod, nesvyazannyij predaktivacionnyij barjyer bez budusjhikh `taskId` i kvitancii, exact CAS-privyazku i otkryitiye, zapret dubliruyusjhego vladeljca, atomarnuyu proverku barjyera pri `join`, gryaznoye derevo, SHA-1/SHA-256, Unicode-ref, mashinnuyu obyazateljnostj prodolzheniya posle aktivacii, exact waiting-bilet za boleye rannim biletom bez pereuporyadochivaniya, konkurentnuyu otmenu, atomarnuyu kvitanciyu, pozdnij replay i mismatch, otsutstviye absolyutnyikh putej v prompt, break-glass i otdeljno avtorizuyemyij transport.

`test_пул_worktree_подузлов.py` otdeljno pokryivayet dva paralleljnyikh linked worktree, samostoyateljnyiye route/reserve/admit obyichnogo chata, atomarnyij konkurentnyij vyibor yedinstvennoj linii, obsjhej ordinary/pool-granicyi i unikaljnostj live host, lazy reuse, exact user-created continuation odnoj self-line, FIFO handoff/reload/ack, tochnyij khyesh soobsjheniya pri handoff/result replay, read-only recovery vsekh faz s verify-only snimkom obsjhego route i Git-ograzhdenij, handoff receipt posle polnogo reuse slota bez dublikatov, trusted `protocol_oid`, vosstanovleniye materialization, merge i terminal detach, staged- i untracked-puti s opasnyimi probelami, exact target result-kvitancii, nezavisimyiye revjyu, obyazateljnuyu publikacionnuyu chistotu, zapret remote-psevdonimov i primenimyikh URL-perenapravlenij, podavleniye soprovozhdayusjhikh refs i terminaljnoye zapechatyivaniye pozdnego revjyu candidate/result s crash-recovery i reuse, chistoye i konfliktnoye agentskoye sliyaniye, povtornoye revjyu kandidata, sokhraneniye result-diapazonov, zakryituyu proverku old→new pula v atomarnom moste `master` + obyichnaya FIFO + continuation + pool, exact-OID publikaciyu prinyatoj integracii, otricateljnogo rezuljtata i dolgovechnyij `publication_pending` s uspeshnyim avtomaticheskim povtorom.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-14 19:25:10 MSK — Avtomatizirovatj dobavleniye slotov dlya novyikh sessij](../../Zhurnal/2026-08-14_19-25-10_MSK_avtomatizirovatj-dobavleniye-slotov-dlya-novyikh-sessij/zapros.md)
- [tekusjhij zapros 2026-08-13 18:17:47 MSK — Organizovatj paralleljnyiye sessii v izolirovannyikh worktree-poduzlakh](../../Zhurnal/2026-08-13_18-17-47_MSK_organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-fork-poduzlakh/zapros.md)
- [FUM-STEP-0148 — organizovatj paralleljnyiye sessii v izolirovannyikh worktree-poduzlakh](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0148-organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-worktree-poduzlakh.md)
- [tekusjhij zapros 2026-08-13 07:41:51 MSK — Dobavitj resursno-konfliktnoye raspredeleniye cepochek](../../Zhurnal/2026-08-13_07-41-51_MSK_dobavitj-resursno-konfliktnoye-raspredeleniye-cepochek/zapros.md)
- [tekusjhij zapros 2026-08-13 03:21:13 MSK — Dobavitj kornevoj reyestr zapuskov i vosstanovleniye host-privyazok](../../Zhurnal/2026-08-13_03-21-13_MSK_dobavitj-kornevoj-reyestr-zapuskov-i-vosstanovleniye-host-privyazok/zapros.md)
- [FUM-REQ-0043 — derevo vetvevyikh fork i roditeljskaya moderaciya](../../Trebovaniya/🟡-derevo-vetvevyikh-fork-i-roditeljskaya-moderaciya.md)
- [FUM-REQ-0042 — obyazateljnoye prodolzheniye Git-vetki posle kommita](../../Trebovaniya/✅-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md)
- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [FUM-REQ-0041 — podtverzhdayemyij ruchnoj sbros FIFO k tekusjhemu HEAD](../../Trebovaniya/✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md)
- [FUM-REQ-0039 — shtatnyij sbros FIFO-ocheredi i rabochej kopii](../../Trebovaniya/🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)
- [iskhodnyij zapros 2026-08-08 13:37:10 MSK — Vnedritj vetochnyiye cepochki shagov](../../Zhurnal/2026-08-08_13-37-10_MSK_vnedritj-vetochnyiye-cepochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-21 18:31:35 MSK — Vvesti posledovateljnuyu ocheredj sessij bez hooks](../../Zhurnal/2026-07-21_18-31-35_MSK_vvesti-posledovateljnuyu-ocheredj-sessij-bez-hooks/zapros.md)
- [iskhodnyij zapros 2026-07-20 16:11:17 MSK — Serializovatj zadachi v vetke](../../Zhurnal/2026-07-20_16-11-17_MSK_serializovatj-zadachi-v-vetke/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 12:38:11 MSK -->
<!-- content-sha256: sha256:1f1441374193fff15f64ded3ad7e91337fb0430af3fb70e57ce57c5a8c2c091e -->
<!-- FUM-MD-RECENCY:END -->
