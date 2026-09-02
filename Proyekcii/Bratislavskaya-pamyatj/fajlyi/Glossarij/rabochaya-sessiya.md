# Rabochaya sessiya

Rabochaya sessiya — otdeljnyij vruchnuyu zapusjhennyij prokhod rabotyi nad odnim zaprosom, kotoryij vliyayet na pamyatj proyekta FUM. V dejstvuyusjhej skheme ona vyipolnyayetsya yedinstvennoj pishusjhej kornevoj zadachej v pervichnom checkout `refs/heads/master`, vklyuchayet sozdaniye [papki zaprosa](papka-zaprosa.md), sokhraneniye [iskhodnogo zaprosa](iskhodnyij-zapros.md), obnovleniye svyazannyikh materialov, zapisj `отчёт.md` v [zhurnal rabot](zhurnal-rabot.md), proverki i ne boleye odnogo itogovogo lokaljnogo Git-kommita. Posle kommita sessiya zavershayetsya; sleduyusjhuyu zapuskayet toljko poljzovatelj.

Rabochaya sessiya dolzhna ostavlyatj proveryayemyij sled: kakiye fajlyi izmenenyi, kakoye trebovaniye obrabotano, kakiye instrumentyi i versii ispoljzovalisj, kakiye voprosyi otkryityi, kakoj kornevoj identifikator Codex zafiksirovan i kakoj lokaljnyij kommit sokhranil rezuljtat. Odinakovyij `Codex-Thread-ID` v fajle zaprosa i soobsjhenii kommita svyazyivayet proiskhozhdeniye tekusjhej sessii. Avtomaticheskoj sleduyusjhej zadachi i identifikatora prodolzheniya v dejstvuyusjhej skheme net.

FIFO, obyazateljnoye prodolzheniye, worktree-pul, recenzirovaniye, integraciya i candidate CAS sokhranenyi kak istoricheskaya i otlozhennaya arkhitektura. Oni ne opredelyayut obyichnuyu rabochuyu sessiyu i ne dayut yej pravo sozdavatj route, assignment, slot, continuation ili publikaciyu.

Istoricheskij `./sbrositj.sh` ostayotsya break-glass-instrumentom prezhnej FIFO, no ne yavlyayetsya chastjyu ruchnoj posledovateljnoj skhemyi, soderzhateljnoj sessiyej ili Git-kommitom. Yego ne zapuskayut bez otdeljnogo yavnogo resheniya poljzovatelya.

V otlozhennom celevom konture [dochernikh fork-agentov FUM](dochernij-fork-agent-FUM.md) po-prezhnemu razlichayutsya kornevaya rabochaya sessiya i [sessii shagov FUM](sessiya-shaga-FUM.md). Eta arkhitektura ne aktiviruyetsya tekusjhim ruchnyim rezhimom i trebuyet otdeljnogo budusjhego perekhoda.

Vremennoj sled rabochej sessii sokhranyayetsya v zhurnaljnom profile po stadiyam. On razlichayet ozhidaniye dopuska i aktivnoye vyipolneniye, pokazyivayet granicyi nablyudayemogo wall-clock-intervala i sposob izmereniya, a dlya paralleljnyikh dejstvij ne vyidayot summu vlozhennyikh dliteljnostej za obsjheye kalendarnoye vremya.

Nachinaya s rabochej sessii `2026-08-04 20:45:26 MSK`, kazhdyij pryamoj verkhneurovnevyij proverochnyij vyizov provoditsya cherez obyazateljnuyu avtomatizaciyu i poluchayet sobstvennuyu versionirovannuyu JSON-zapisj, kazhdoye sostoyaniye kotoroj ustanavlivayetsya atomarno. Zapisj sokhranyayet poryadok, ispolnitelya, vyizov, sostoyaniye, nablyudayemuyu dliteljnostj i rezuljtat; povtornyij, neuspeshnyij ili prervannyij progon ostayotsya samostoyateljnyim faktom. Markdown-tablica stroitsya iz etikh zapisej determinirovanno, a obsjhaya dliteljnostj proverok schitayetsya kak summa vidimyikh millisekund, poluchennyikh okrugleniyem dliteljnosti kazhdoj zavershyonnoj zapisi iz nanosekund do celogo. Poetomu sovokupnoye vremya paralleljnyikh vyizovov mozhet prevyishatj kalendarnyij interval i ne yavlyayetsya vosproizvodimyim benchmark bez svedenij o mashine, kyeshakh i nagruzke.

Otkryityij predprosmotr mashinnogo zhurnala mozhet promezhutochno susjhestvovatj mezhdu vyizovami, no strogaya proverka prinimayet yego toljko poka yestj zapisj s aktivno vyipolnyayusjhimsya vyizovom, v tom chisle pri samoproverke obyortki; konechnyim sostoyaniyem kommita on byitj ne mozhet. Posle zaversheniya vsekh vyizovov avtomatizaciya snachala dolgovechno stavit uporyadochennyij snimok imyon i tochnyikh SHA-256 khyeshej bajtov zapisej, zatem zakryivayet Markdown-proyekciyu. Promezhutochnyij snimok s otkryityim marker blokiruyet novyiye vyizovyi i povtorimo dovoditsya do zakryitiya. Otchyot svyazyivayet gotovyij snimok sobstvennyim khyeshem i dolzhen soderzhatj bajt-v-bajt sovpadayusjhuyu zanovo postroyennuyu proyekciyu. Predfinaljnyij smoke-check vyibrannogo profilya yavlyayetsya poslednej okhvachennoj zapisjyu; obyichnaya dokumentacionnaya sessiya ispoljzuyet standartnyij profilj. Posle nego vne profilya vyipolnyayutsya toljko neobkhodimyiye proverki zamyikaniya, chtobyi sama fiksaciya otchyota ne porozhdala beskonechnuyu rekursiyu novyikh zapisej.

## Svyazannyiye dokumentyi

- [AGENTS.md](../AGENTS.md)
- [Papka zaprosa](papka-zaprosa.md)
- [Zhurnal rabot](../Zhurnal/README.md)
- [Predlozheniya o sleduyusjhikh shagakh FUM](../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)
- [Kartochki shagov FUM](../Planirovaniye/kartochki-shagov/README.md)
- [Modelj pamyati FUM](../Dokumentaciya/01-modelj-pamyati-FUM.md)
- [Reyestr sistemnyikh prilozhenij i instrumentov](reyestr-sistemnyikh-prilozhenij-i-instrumentov.md)
- [Avtomaticheskiye otchyotyi o zapuskakh proverok](../Instrumentyi/fum-otchyotyi-o-zapuskakh-proverok/SKILL.md)
- [Trebovaniye shtatnogo sbrosa FIFO-ocheredi i rabochej kopii](../Trebovaniya/🚧-shtatnyij-sbros-FIFO-ocheredi-i-rabochej-kopii.md)
- [Trebovaniye podtverzhdayemogo ruchnogo sbrosa FIFO](../Trebovaniya/✅-podtverzhdayemyij-ruchnoj-sbros-FIFO-k-tekusjhemu-HEAD.md)
- [Obyazateljnoye prodolzheniye vetki](obyazateljnoye-prodolzheniye-vetki.md)

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-10 10:19:59 MSK — Dobavitj prostoj sbros FIFO k tekusjhemu HEAD](../Zhurnal/2026-08-10_10-19-59_MSK_dobavitj-prostoj-sbros-FIFO-k-tekusjhemu-HEAD/zapros.md)
- [iskhodnyij zapros 2026-08-07 20:34:22 MSK — Dobavitj shtatnyij sbros ocheredi](../Zhurnal/2026-08-07_20-34-22_MSK_dobavitj-shtatnyij-sbros-ocheredi/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-04 20:45:26 MSK — Formirovatj otchyotyi o zapuskakh testov](../Zhurnal/2026-08-04_20-45-26_MSK_formirovatj-otchyotyi-o-zapuskakh-testov/zapros.md)
- [iskhodnyij zapros 2026-07-31 16:31:18 MSK - Otklyuchitj avtomaticheskuyu publikaciyu master](../Zhurnal/2026-07-31_16-31-18_MSK_otklyuchitj-avtomaticheskuyu-publikaciyu-master/zapros.md)
- [iskhodnyij zapros 2026-07-27 16:12:29 MSK - Uchityivatj vse proverochnyiye vyizovyi v profile vremeni](../Zhurnal/2026-07-27_16-12-29_MSK_uchityivatj-vse-proverochnyiye-vyizovyi-v-profile-vremeni/zapros.md)
- [iskhodnyij zapros 2026-07-26 15:15:18 MSK - Publikovatj rabotu v GitHub avtomaticheski](../Zhurnal/2026-07-26_15-15-18_MSK_publikovatj-rabotu-v-GitHub-avtomaticheski/zapros.md)
- [iskhodnyij zapros 2026-07-23 14:47:43 MSK - Vklyuchatj profilj vremeni v otchyotyi zhurnala](../Zhurnal/2026-07-23_14-47-43_MSK_vklyuchatj-profilj-vremeni-v-otchyotyi-zhurnala/zapros.md)
- [iskhodnyij zapros 2026-07-14 02:31:47 MSK - Dobavlyatj identifikator seansa Codex](../Zhurnal/2026-07-14_02-31-47_MSK_dobavlyatj-identifikator-seansa-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK - Dekompozirovatj predlozheniya na kartochki shagov](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 15:00:57 MSK -->
<!-- content-sha256: sha256:2745d0b8e89c1ffeccb9a78bf00f338d01770466a5739c3288343098e252f79e -->
<!-- FUM-MD-RECENCY:END -->
