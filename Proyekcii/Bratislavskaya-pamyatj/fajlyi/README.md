# [FUM](Glossarij/FUM.md)

[FUM](Glossarij/FUM.md) — `fraktaljnyij uzel myishleniya`, po-russki — [fraktaljnyij uzel myishleniya](Glossarij/fraktaljnyij-uzel-myishleniya.md). Proyekt razrabatyivayetsya kak otkryityij agent sleduyusjhego pokoleniya.

Sejchas etot repozitorij — [pamyatj proyekta](Glossarij/pamyatj-FUM.md) i yego [dokumentacionnyij prototip](Glossarij/dokumentacionnyij-prototip-FUM.md), a ne gotovoye otdeljnoye prilozheniye. Prakticheskij interfejs tekusjhej formyi — chelovek, vneshnyaya zadacha Codex i lokaljnaya kopiya pamyati v Git i Markdown. Obsidian mozhno ispoljzovatj kak udobnyij interfejs chteniya i navigacii, no kanonicheskim istochnikom ostayutsya fajlyi repozitoriya.

## Kak ispoljzovatj FUM sejchas

### 1. Podgotovjte svoyu kopiyu

Dlya lichnoj ili publichnoj rabotyi sozdajte fork, zamenite `USERNAME` svoim imenem na GitHub, klonirujte fork i pri neobkhodimosti podklyuchite bazovyij repozitorij kak `upstream`:

```bash
git clone https://github.com/USERNAME/fum.git FUM
cd FUM
git remote add upstream https://github.com/fum-lab/fum.git
```

Posle svezhego klonirovaniya inicializirujte zakreplyonnuyu Git-zavisimostj LinguisticKit:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init \
  --repo-root . \
  --path Зависимости/LinguisticKit
```

Otkrojte korenj repozitoriya kak lokaljnyij proyekt v Codex Desktop. Pri zhelanii otkrojte tot zhe katalog kak khranilisjhe Obsidian.

### 2. Sformulirujte obyichnyij zapros

Napishite zadache Codex, chto nuzhno ponyatj, izmenitj, proveritj ili sokhranitj. Mozhno pisatj yestestvennyim yazyikom, v tom chisle translitom. Yesli zapros vliyayet na pamyatj proyekta, yego iskhodnaya formulirovka sokhranyayetsya doslovno, a proizvodnaya pamyatj vedyotsya po-russki kirillicej. Yesli vazhnyi dostup, publikaciya, setj, sekretyi, platnyiye servisyi ili drugiye vneshniye effektyi, ukazhite razreshyonnyiye granicyi yavno.

Poleznyij zapros obyichno soderzhit ozhidayemyij rezuljtat, iskhodnyiye materialyi i susjhestvennyiye ogranicheniya. Znatj vnutrenneye ustrojstvo pamyati ili specialjnyiye komandyi FUM dlya nachala rabotyi ne trebuyetsya.

Yesli issledovaniye uzhe vyipolneno vo vneshnem Web ChatGPT, ne prosite yego imitirovatj pryamoj kommit ili push cherez obyichnoye GitHub-podklyucheniye: etot kanal prednaznachen dlya chteniya. Poprosite vernutj odin [tipizirovannyij paket vneshnego vklada](Dokumentaciya/51-proveryayemyij-priyom-vneshnego-vklada.md) pryamo v tekstovom soobsjhenii, opublikujte share-ssyilku i peredajte yeyo novoj lokaljnoj zadache Codex. Lokaljnaya zadacha arkhiviruyet dialog, proveryayet tochnyiye bazu, manifest i khyesh, pokazyivayet nedoverennyij patch i toljko zatem samostoyateljno oformlyayet prinimayemoye izmeneniye po pravilam FUM.

### 3. Zapustite odnu pishusjhuyu sessiyu

Kazhduyu pishusjhuyu zadachu zapuskajte vruchnuyu v Codex Desktop dlya pervichnogo checkout `refs/heads/master`. Odnovremenno rabotayet toljko odna pishusjhaya sessiya; otdeljnyiye read-only-zadachi mogut nablyudatj sostoyaniye, no ne izmenyayut fajlyi ili Git.

Odna sessiya vyipolnyayet odin soderzhateljnyij zapros: chitayet prinyatuyu pamyatj, obnovlyayet dokumentyi ili kod, sokhranyayet proiskhozhdeniye v `Журнал/`, zapuskayet proverki i sozdayot ne boleye odnogo lokaljnogo kommita. Posle rezuljtata ona zavershayetsya; sleduyusjhuyu sessiyu zapuskayete vyi novyim zaprosom.

Obyichnyij marshrut ne sozdayot continuation, handoff, FIFO-bilet, otdeljnyij worktree, reviewer, integrator ili candidate. Istoricheskiye instrumentyi i refs etikh skhem sokhranenyi v repozitorii kak narabotka, no sami po sebe ne zapuskayut rabotu.

Lokaljno menyayusjhijsya `.obsidian/graph.json` ostayotsya poljzovateljskim sostoyaniyem Obsidian, ignoriruyetsya Git i ne blokiruyet kommit.

### 4. Proverjte rezuljtat

Prochitajte itog zadachi, prosmotrite izmenyonnyiye fajlyi i Git-diff, a pri neobkhodimosti — sosedniye `запрос.md` i `отчёт.md` v novoj papke `Журнал/`. Otchyot pokazyivayet smyisl izmeneniya, proverki, resheniya i izvestnyiye ogranicheniya; Git-kommit zakreplyayet tochnyij prinyatyij snimok.

Posle kommita ubeditesj, chto `master` ukazyivayet na pokazannuyu vershinu. Avtomaticheskoj sleduyusjhej zadachi net: pri neobkhodimosti sformulirujte novyij zapros i zapustite novuyu sessiyu vruchnuyu. Kartochki i planyi ostayutsya pamyatjyu razvitiya, a ne ocheredjyu avtozapuska.

### 5. Opublikujte otdeljno, yesli eto nuzhno

Publikujte vyibrannyij lokaljnyij rezuljtat toljko otdeljnyim yavnyim dejstviyem, naprimer:

```bash
git push origin master
```

Dlya drugoj vetki ili tochnogo ref ispoljzujte sootvetstvuyusjhuyu yavnuyu komandu. Ruchnoj push publikuyet proverennyij Git-prefiks, no ne rasshiryayet razresheniya na inyiye vneshniye effektyi. Avtomaticheskoj publikacii net.

## Otlozhennyij konvejyer

FIFO, obyazateljnoye prodolzheniye, branch-next-step, worktree-pul, nezavisimoye agentskoye revjyu, integraciya, candidate CAS i avtomaticheskij transport sokhranenyi kak [istoricheski realizovannyij konvejyer](Dokumentaciya/45-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md) i vozmozhnaya budusjhaya arkhitektura. Sejchas on ne dejstvuyet i ne yavlyayetsya instrukciyej poljzovatelyu ili agentu. Nizhe sokhraneno obyyasneniye yego prezhnikh zasjhitnyikh svojstv.

Kommit razreshyon toljko posle podtverzhdeniya exact continuation-intent i pervogo ozhidayusjhego bileta na iskhodnoj vershine tekh zhe ref i worktree. Atomarnyij commit+handoff dvigayet vetku i peredayot ocheredj. Worktree-prodolzheniye podtverzhdayet novuyu vershinu v tom zhe slote; prodolzheniye obyichnoj vetki perechityivayet novyij `HEAD`, zapuskayet selektor i beryot odin dopustimyij shag. Nesovpavshaya kvitanciya zakryivayet marshrut bez rezervnogo nezavisimogo vyideleniya. `done`, otsutstviye gotovogo shaga ili chistyij otkaz zakanchivayutsya `finish-clean`, poetomu pustoj petli net.

Zadacha sleduyusjhej fazyi susjhestvuyet do promezhutochnogo kommita namerenno. Git-kvitancii pozvolyayut novoj sessii posle obryiva read-only vosstanovitj tot zhe slot, ref, FIFO, intent i sleduyusjhuyu dopustimuyu komandu bez dublikata. No oshibka, tajm-aut, odin `clientThreadId` ili poteryannyij otvet pri sozdanii yesjhyo neizvestnoj host-zadachi zapresjhayut kommit i slepoj povtor: host-poverkhnostj ne imeyet idempotentnogo klyucha i avtoritetnogo poiska takogo rezuljtata. Eto bezopasnaya ostanovka, no ne obesjhaniye bezuslovnogo progressa posle lyubogo sboya sredyi.

Yesli imenno eti zasjhitnyiye ograzhdeniya ne dayut bezopasno prodolzhitj lokaljnuyu rabotu, chelovek mozhet ispoljzovatj otdeljnyij avarijnyij marshrut iz kornya repozitoriya:

```bash
./sbrositj.sh
```

Skript bez `sudo` trebuyet nastoyasjhiye TTY odnovremenno na stdin i stdout, pokazyivayet tochnyiye tekusjhiye vetku, `HEAD`, udalyayemyiye izmeneniya i runtime-ssyilki i zaprashivayet dinamicheskuyu frazu polnogo plana. Posle podtverzhdeniya on vozvrasjhayet indeks i rabocheye derevo k etomu `HEAD`, sokhranyaya ignored-dannyiye i vlozhennyiye repozitorii, arkhiviruyet i annuliruyet prezhneye scoped runtime-sostoyaniye i sozdayot svezhuyu pustuyu FIFO. Eto soznateljnyij `break-glass`, a ne host-stop i ne istochnik novoj zadachi-prodolzheniya: daljnejsheye ispolneniye nachinayet chelovek otdeljnyim zaprosom. Oshibka frazyi ili izmeneniye plana zavershayut vyizov bez sbrosa; skript ne prinimayet neinteraktivnyij force-obkhod.

## Granicyi tekusjhej formyi

- Yedinogo korobochnogo prilozheniya, sobstvennogo samostoyateljnogo runtime i gotovogo GUI FUM poka net; Codex i yego host-orkestraciya ostayutsya vneshnej sredoj.
- Sokhranyonnyij otlozhennyij prototip worktree-pula proveryayet exact slot `repo-root` soderzhateljnyikh komand, no ne yavlyayetsya dejstvuyusjhim marshrutom zapisi. Tekusjhaya ruchnaya skhema ispoljzuyet toljko pervichnyij checkout `refs/heads/master`; istoricheskaya proverka slota ne dokazyivayet nativnuyu host-izolyaciyu Codex Desktop.
- Git, zhurnal i avtomaticheskiye proverki podtverzhdayut proiskhozhdeniye, strukturu i vosproizvodimyiye invariantyi, no ne dokazyivayut istinnostj kazhdogo soderzhateljnogo vyivoda ili preimusjhestvo FUM nad drugimi agentami.
- Setj, sekretyi, platnyiye servisyi, publikaciya, polucheniye dannyikh iz vneshnikh istochnikov i fizicheskiye effektyi trebuyut otdeljnogo yavnogo razresheniya.
- Ispolnyayemyiye prototipyi podtverzhdayut toljko svoi ogranichennyiye scenarii i ne yavlyayutsya obesjhaniyem gotovnosti polnogo produkta.

## Kuda idti daljshe

- [Polnyij indeks dokumentacii FUM](Dokumentaciya/README.md) — tematicheskaya karta vsekh nomernyikh dokumentov.
- [Obzor proyekta](Dokumentaciya/00-obzor-proyekta.md) — kratkaya smyislovaya ramka.
- [Osnovnaya poljzovateljskaya istoriya svyaznoj pamyati](Dokumentaciya/31-poljzovateljskiye-istorii-FUM/vesti-svyaznuyu-pamyatj-FUM.md) — nablyudayemyij potok ot zaprosa do vozobnovlyayemoj pamyati.
- [Pasport dokumentacionnogo prototipa](Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md) — sostav tekusjhego kontura i yego granicyi.
- [Proveryayemyij priyom vneshnego vklada](Dokumentaciya/51-proveryayemyij-priyom-vneshnego-vklada.md) — peredacha predlozheniya iz Web ChatGPT v lokaljnuyu kornevuyu sessiyu bez fiktivnogo write-dostupa.
- [Dorozhnaya karta](Planirovaniye/dorozhnaya-karta.md), [sleduyusjhiye shagi vetok](Planirovaniye/sleduyusjhiye-shagi-vetok/README.md) i [prototipyi](Prototipyi/) — razvitiye i ispolnyayemyiye proverki otdeljnyikh reshenij.
- [Glossarij proyekta](Glossarij/glossarij-proyekta.md) — znacheniya ustojchivyikh terminov FUM.

## Licenziya

Proyekt publikuyetsya pod [CC0 1.0 Universal](LICENZIYA.md). Kanonicheskij publichnyij upstream — [fum-lab/fum](https://github.com/fum-lab/fum).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-13 18:17:47 MSK — Organizovatj paralleljnyiye sessii v lokaljnyikh worktree-poduzlakh](Zhurnal/2026-08-13_18-17-47_MSK_organizovatj-paralleljnyiye-sessii-v-izolirovannyikh-fork-poduzlakh/zapros.md)
- [iskhodnyij zapros 2026-08-10 14:30:08 MSK — Dobavitj analitiku po chislu zavershyonnyikh shagov](Zhurnal/2026-08-10_14-30-08_MSK_dobavitj-analitiku-po-chislu-zavershyonnyikh-shagov/zapros.md)
- [iskhodnyij zapros 2026-08-10 10:19:59 MSK — Dobavitj prostoj sbros FIFO k tekusjhemu HEAD](Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [iskhodnyij zapros 2026-08-07 20:34:22 MSK — Dobavitj shtatnyij sbros ocheredi](Zhurnal/2026-08-07_20-34-22_MSK_dobavitj-shtatnyij-sbros-ocheredi/zapros.md)
- [iskhodnyij zapros 2026-08-06 15:14:50 MSK — Sdelatj README instrukciyej ispoljzovaniya FUM](Zhurnal/2026-08-06_15-14-50_MSK_sdelatj-README-instrukciyej-ispoljzovaniya-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-27 20:10:35 MSK — Razreshitj nachaljnuyu korobochnuyu FUM bez GUI cherez Codex](Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK — Otklyuchitj avtomaticheskuyu publikaciyu master](Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [iskhodnyij zapros 2026-08-06 06:59:01 MSK — Dobavitj upravleniye dispetcherom cherez soobsjheniya](Zhurnal/2026-08-06_06-59-01_MSK_dobavitj-upravleniye-dispetcherom-cherez-soobsjheniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-02 09:36:08 MSK -->
<!-- content-sha256: sha256:b7b2c0f06c8f3fd8acaa4a7fdb5847f67a7113837d9ac4410d975aab43e4cf3e -->
<!-- FUM-MD-RECENCY:END -->
