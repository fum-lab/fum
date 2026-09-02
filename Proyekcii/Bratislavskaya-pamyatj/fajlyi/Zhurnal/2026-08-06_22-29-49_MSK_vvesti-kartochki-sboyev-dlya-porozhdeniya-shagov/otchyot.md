# Otchyot 2026-08-06 22:29:49 MSK - Vvesti kartochki sboyev dlya porozhdeniya shagov

V pamyatj FUM vvedyon otdeljnyij sloj kartochek sboyev. Odna kartochka teperj agregiruyet dokazannyiye proyavleniya obsjhego predpolagayemogo mekhanizma, sokhranyayet granicu povtoreniya i dvustoronne svyazyivayetsya s atomarnyimi shagami issledovaniya ili ustraneniya. Kartochka ne uchastvuyet v dispatch, a zaversheniye shaga ne zakryivayet yeyo bez proveryayemoj sistemnoj meryi.

Sozdanyi dvenadcatj pervyikh aktivnyikh kartochek: [FUM-SBOJ-0001](../../Sboi/FUM-SBOJ-0001-propusk-voprosno-otvetnogo-materiala.md) o propuske voprosno-otvetnogo materiala porodila i konkretizirovala FUM-STEP-0114, [FUM-SBOJ-0002](../../Sboi/FUM-SBOJ-0002-samovoljnaya-otmena-ozhidayusjhego-FIFO-bileta.md) o samovoljnoj otmene ozhidayusjhego FIFO-bileta svyazana s FUM-STEP-0130, obnaruzhennyij v nachale etoj sessii [FUM-SBOJ-0003](../../Sboi/FUM-SBOJ-0003-obkhod-HEAD-bootstrap-pri-pervichnom-vkhode-v-FIFO.md) ob obkhode doverennogo HEAD-bootstrap porodil FUM-STEP-0131, vyiyavlennyij auditom [FUM-SBOJ-0004](../../Sboi/FUM-SBOJ-0004-nevernoye-razresheniye-uglovoj-Markdown-ssyilki-planovyim-reyestrom.md) o nevernoj proizvodnoj celi uglovoj Markdown-ssyilki porodil FUM-STEP-0132, pojmannyij predfinaljnoj proverkoj [FUM-SBOJ-0005](../../Sboi/FUM-SBOJ-0005-interpretaciya-Markdown-ssyilki-vnutri-strochnogo-koda-proverkoj-svyaznosti.md) o lozhnoj interpretacii ssyilki vnutri strochnogo koda porodil FUM-STEP-0133, [FUM-SBOJ-0006](../../Sboi/FUM-SBOJ-0006-opechatka-puti-tekusjhego-zaprosa-pri-uchyote-proverki.md) o ruchnoj opechatke puti zaprosa porodil FUM-STEP-0134, [FUM-SBOJ-0007](../../Sboi/FUM-SBOJ-0007-propusk-opornoj-datyi-grafa-posle-perekhoda-cherez-polnochj-MSK.md) o nepolnom inventare posle perekhoda cherez polnochj MSK porodil FUM-STEP-0135, [FUM-SBOJ-0008](../../Sboi/FUM-SBOJ-0008-pustoj-scenarij-orkestracii-proverki-bez-dochernego-vyizova.md) o pustom scenarii orkestracii porodil FUM-STEP-0136, povtoryayusjhijsya [FUM-SBOJ-0009](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md) o ruchnom ugadyivanii susjhestvuyusjhikh lokaljnyikh putej porodil FUM-STEP-0137, povtoryayusjhijsya [FUM-SBOJ-0010](../../Sboi/FUM-SBOJ-0010-maskirovka-rannego-otkaza-sostavnoj-shell-diagnostiki.md) o maskirovke rannego otkaza pozdnim uspekhom porodil FUM-STEP-0138, [FUM-SBOJ-0011](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md) o povtornom kopirovanii kriteriyev porodil FUM-STEP-0139, a [FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md) o prevyishenii silyi i izmenchivosti dokazateljstva porodil i aktualiziroval FUM-STEP-0140. Massovaya retroklassifikaciya istorii ne vyipolnyalasj: novyiye proyavleniya budut dobavlyatjsya po mere nablyudeniya i dokazateljstva obsjhej granicyi predotvrasjheniya.

## Rezuljtat

Katalog [Sboi](../../Sboi/README.md) poluchil ploskij indeks, neizmenyayemyiye identifikatoryi `FUM-СБОЙ-NNNN`, chetyire statusa i yedinyij sostav kartochki. Kazhdoye proyavleniye imeyet lokaljnyij nomer, istochnik, dokazateljstvo, effekt i vosstanovleniye. Vtoroye podtverzhdyonnoye proyavleniye schitayetsya povtorom i obyazateljno sozdayot libo aktualiziruyet shag; proizvoljnaya metka regulyarnosti ne zamenyayet ryad nablyudenij.

[Glossarnaya statjya](../../Glossarij/kartochka-sboya.md) otdelyayet sobyitiye, kartochku, nedorabotku i planovyij shag. `AGENTS.md` marshrutiziruyet zamechennuyu nedorabotku v kanonicheskuyu kartochku, zapresjhayet obyyedinyatj sluchai toljko po pokhozhemu simptomu i trebuyet proveryayemogo zakryitiya. [Pamyatj FUM](../../Glossarij/pamyatj-FUM.md) i [planirovaniye](../../Planirovaniye/README.md) svyazyivayut novyij diagnosticheskij sloj s rabochimi shagami.

FUM-STEP-0114 ostayotsya aktualjnoj: tekusjhaya sessiya sozdayot format i realjnyiye fiksturyi, no ne vyidayot ruchnoj indeks za mashinno proveryayemyij kontur. Yeyo kriterii teperj trebuyut validirovatj identichnostj, statusyi, obyazateljnyiye razdelyi, ryad proyavlenij, dopustimyiye iskhodyi i vzaimnyiye ssyilki. FUM-STEP-0130 poluchila obratnuyu ssyilku na svoj sboj, FUM-STEP-0131 trebuyet perenesti samyij pervyij `join` v doverennuyu host- ili orkestracionnuyu tochku vkhoda, FUM-STEP-0132 — ispravitj razbor i validaciyu uglovyikh lokaljnyikh Markdown-ssyilok planovogo reyestra, FUM-STEP-0133 — isklyuchitj korrektnyij strochnyij kod iz izvlecheniya aktivnyikh ssyilok, FUM-STEP-0134 — svyazatj proverochnyiye vyizovyi s tekusjhim zaprosom bez povtornogo svobodnogo puti, FUM-STEP-0135 — uchityivatj oba vyikhoda generatora grafa do zakryitiya sessii, FUM-STEP-0136 — zapresjhatj uspekh proverochnogo khoda bez dochernego vyizova i mashinnoj zapisi, FUM-STEP-0137 — razreshatj tochnyij lokaljnyij putj po inventaryu do vyizova, FUM-STEP-0138 — sokhranyatj otkaz kazhdoj obyazateljnoj podkomandyi sostavnoj diagnostiki v obsjhem iskhode, FUM-STEP-0139 — proveryatj razdeleniye diagnosticheskikh i realizacionnyikh kriteriyev, a FUM-STEP-0140 — zakreplyatj silu i neizmenyayemuyu identichnostj adresuyemogo dokazateljstva.

### Sboj pervichnogo vkhoda tekusjhej sessii

Do chteniya tochnogo interfejsa ocheredi kornevoj agent snachala vyizval ugadannyij nesusjhestvuyusjhij putj, a zatem vyipolnil `join` pryamyim scenariyem chistogo rabochego dereva. Vtoroj vyizov sozdal praviljnyij bilet, no narushil zapret obkhoditj HEAD-bootstrap. Posle obnaruzheniya vse komandyi ocheredi zagruzhalisj iz tochnogo `HEAD`. Posle kommitov predshestvennikov tot zhe bilet vernul `reload_required`; zadacha perechitala aktualjnyiye `AGENTS.md`, navyik ocheredi i izmeneniya `HEAD`, vyipolnila `ack-head` dlya tochnogo obyyekta i poluchila shtatnyij dopusk bez povtornoj pozicii. Proyavleniye sokhraneno kak [FUM-SBOJ-0003](../../Sboi/FUM-SBOJ-0003-obkhod-HEAD-bootstrap-pri-pervichnom-vkhode-v-FIFO.md), a ne skryito kak bezvrednaya opechatka.

### Sboj proizvodnoj celi planovogo reyestra

Integracionnyij audit sopostavil kanonicheskuyu ssyilku `<../../Вопросы и ответы/README.md>` v FUM-STEP-0114 s dvumya yeyo predstavleniyami v peresobrannom mashinnom reyestre. Oba soderzhat nesusjhestvuyusjhuyu celj `Планирование/карточки-шагов/Вопросы и ответы/README.md>`, khotya otdeljnaya validaciya reyestra zavershilasj uspeshno. Dokazannoye raskhozhdeniye sokhraneno kak [FUM-SBOJ-0004](../../Sboi/FUM-SBOJ-0004-nevernoye-razresheniye-uglovoj-Markdown-ssyilki-planovyim-reyestrom.md) i porodilo FUM-STEP-0132. V etoj sessii parser ne ispravlyayetsya: do zaversheniya shaga kanonicheskij Markdown ostayotsya istochnikom istinyi, a korrektnostj proizvodnyikh `source_links` yavno ne schitayetsya dokazannoj.

### Lozhnaya ssyilka vnutri strochnogo koda

Predfinaljnaya svyaznostj zavershilasj kodom `1` i soobsjhila `local Markdown link escapes the repository` dlya bukvaljnogo primera ssyilki, celikom zaklyuchyonnogo v strochnyij kod FUM-SBOJ-0004. Neuspeshnyij vyizov sokhranyon v mashinnom zhurnale pod nomerom `23`. Tekusjhij tekst bezopasno razdelyayet podpisj i celj, no takaya lokaljnaya pereformulirovka ne ispravlyayet skaner. Proyavleniye sokhraneno kak [FUM-SBOJ-0005](../../Sboi/FUM-SBOJ-0005-interpretaciya-Markdown-ssyilki-vnutri-strochnogo-koda-proverkoj-svyaznosti.md) i porodilo FUM-STEP-0133; povtornaya svyaznostj dolzhna podtverditj toljko vosstanovleniye tekusjhej sessii, a ne zakryitiye kartochki.

### Opechatka puti uchyota proverki

Pri sleduyusjhem predfinaljnom obnovlenii grafa komponent `для-порождения-шагов` v parametre `--запрос` byil vruchnuyu nabran kak `для-порожденния-шагов`. Obyortka praviljno otkazala do dochernego processa, poetomu generator ne zapuskalsya i sostoyaniye grafa etim vyizovom ne menyalosj. Oshibochnyij putj odnovremenno lishil obyortku vozmozhnosti svyazatj samu popyitku s nastoyasjhim mashinnyim zhurnalom; etot interval ne vklyuchyon v mashinnuyu summu i yavno sokhranyon zdesj. Proyavleniye oformleno kak [FUM-SBOJ-0006](../../Sboi/FUM-SBOJ-0006-opechatka-puti-tekusjhego-zaprosa-pri-uchyote-proverki.md) i porodilo FUM-STEP-0134. Povtor tochnoj komandyi vosstanavlivayet tekusjhij khod, no ne zakryivayet kartochku.

### Perekhod opornoj datyi grafa cherez polnochj MSK

Pervyij uspeshnyij polnyij smoke-check dlilsya okolo 27 minut i peresyok kalendarnuyu granicu MSK. Posle zakryitiya mashinnogo snimka zamyikayusjhij generator grafa shtatno izmenil `.obsidian/fum-recency-reference-date` s `2026-08-06` na `2026-08-07`; tekusjhij zapros yesjhyo perechislyal toljko `.obsidian/graph.json`, poetomu svyaznostj zakryito otkazala s `unexpected Git status path: .obsidian/fum-recency-reference-date`. Snimok byil strogo proveren i shtatno vozobnovlyon, sidecar dobavlen v inventarj, a proyavleniye sokhraneno kak [FUM-SBOJ-0007](../../Sboi/FUM-SBOJ-0007-propusk-opornoj-datyi-grafa-posle-perekhoda-cherez-polnochj-MSK.md), porodiv FUM-STEP-0135. Generator i proverka srabotali praviljno; oshibkoj byil nepolnyij zaraneye sostavlennyij nabor yego potencialjnyikh vyikhodov.

### Pustoj scenarij orkestracii proverki

Pri sleduyusjhej popyitke uchtyonnogo obnovleniya grafa scenarij `functions.exec` toljko obyyavil putj zaprosa i nachal massiv komandyi, no zavershilsya bez `await tools.exec_command`, bez vyivoda i bez dochernego processa. Vneshneye JavaScript-vyichisleniye vernulo pustoj uspeshnyij iskhod; generator i obyortka proverok ne zapuskalisj, poetomu mezhdu sosednimi mashinnyimi zapisyami novogo nomera net. Oshibka sokhranena kak [FUM-SBOJ-0008](../../Sboi/FUM-SBOJ-0008-pustoj-scenarij-orkestracii-proverki-bez-dochernego-vyizova.md) i porodila FUM-STEP-0136. Povtornyij khod obyazan yavno vyizvatj i dozhdatjsya vlozhennoj komandyi, no takoj ruchnoj kontrolj ne zakryivayet kartochku.

### Ruchnoye ugadyivaniye lokaljnyikh putej

Posle vosstanovleniya sessii kornevoj agent snachala popyitalsya vyizvatj proverku svyaznosti po nesusjhestvuyusjhemu puti `Инструменты/fum-proverka-soglasovannosti-seansa/scripts/check-session-coherence.py`; `python3` vernul `Errno 2`, a tochnaya tochka vkhoda `Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py` byila najdena cherez `rg --files`. Sleduyusjhij diagnosticheskij vyizov do inventarizacii peredal `sed` dva otsutstvuyusjhikh puti: `Сбои/FUM-СБОЙ-0006-ручная-опечатка-пути-текущего-запроса.md` i `Планирование/карточки-шагов/FUM-STEP-0134-сессионный-запуск-проверок-без-повтора-пути-запроса.md`; dlya kazhdogo byil poluchen tochnyij rezuljtat `No such file or directory`, posle chego `rg --files` nashyol fakticheskiye imena. Yesjhyo odin vyizov povtoril oshibku dlya `Планирование/карточки-шагов/FUM-STEP-0136-запретить-успех-проверочного-хода-без-дочернего-вызова-и-машинной-записи.md`. Tri proyavleniya sokhranenyi v [FUM-SBOJ-0009](../../Sboi/FUM-SBOJ-0009-ruchnoye-ugadyivaniye-lokaljnyikh-putej-pered-vyizovom.md); vtoroye tochnyim obrazom porodilo FUM-STEP-0137. Eto pryamyiye read-only-diagnostiki vne obyortki uchyota, poetomu ikh dliteljnosti ne vkhodyat v mashinnuyu summu.

### Maskirovka rannego otkaza sostavnoj diagnostiki

Dva posledovateljnyikh diagnosticheskikh shell-vyizova soderzhali neskoljko obyazateljnyikh chtenij bez pooperacionnogo agregirovaniya statusov. V pervom dva `sed` vernuli `No such file or directory`, no zavershayusjhij uspeshnyij `rg` sdelal obsjhij kod ravnyim `0`; vo vtorom oshibku chteniya FUM-STEP-0136 analogichno skryil uspekh posleduyusjhego chteniya otchyota. Tekst oshibok ostalsya vidimyim, poetomu nepolnota byila zamechena i chteniya povtorenyi po najdennyim tochnyim putyam, no vneshnij mashinnyij iskhod dvazhdyi byil lozhnopolozhiteljnyim. Proyavleniya sokhranenyi v [FUM-SBOJ-0010](../../Sboi/FUM-SBOJ-0010-maskirovka-rannego-otkaza-sostavnoj-shell-diagnostiki.md); vtoroye tochnyim obrazom porodilo FUM-STEP-0138. Eti read-only-vyizovyi takzhe ne vkhodyat v mashinnuyu summu uchtyonnyikh proverok.

### Defektyi samikh kartochek pri nezavisimom audite

Finaljnyij read-only-audit obnaruzhil, chto predkorrekcionnyiye vosemj kriteriyev FUM-SBOJ-0009 pochti po poryadku povtoryali desyatj kriteriyev FUM-STEP-0137: inventarj, razresheniye puti, otricateljnyiye sluchai, zapret nechyotkogo vyibora i testyi. Sleduyusjhiye semj kriteriyev FUM-SBOJ-0010 analogichno pokryivali vosemj kriteriyev FUM-STEP-0138: krasnuyu fiksturu, klassifikaciyu, obyazateljnyiye i neobyazateljnyiye iskhodyi, polozhiteljnyiye sluchai, podklyucheniye i testyi. Eti dva proyavleniya sokhranenyi v [FUM-SBOJ-0011](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md), vtoroye porodilo FUM-STEP-0139, a tekusjhiye kartochki sokrasjhenyi do samostoyateljnoj granicyi zakryitiya.

Tot zhe audit ustanovil, chto na moment proverki otchyot govoril toljko o dvukh ugadannyikh otsutstvuyusjhikh imenakh i posleduyusjhej inventarizacii, togda kak `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0002` pripisyivala yemu dva tochnyikh vyizova `sed`, dva tochnyikh rezuljtata `No such file` i polnyij poryadok `rg --files`; FUM-STEP-0137 zatem nazvala usilennuyu trassu tochnoj fiksturoj. Eto proyavleniye sokhraneno v [FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md) i porodilo FUM-STEP-0140. Otchyot byil dopolnen tochnyimi putyami i rezuljtatami, a kriterii ispravlenyi, no novyiye kartochki snachala soslalisj na uzhe izmenivshiyesya zhivyiye stroki kak na snimok prezhnego sostoyaniya. Vtoroye proyavleniye FUM-SBOJ-0012 aktualizirovalo FUM-STEP-0140 trebovaniyem neizmenyayemoj identichnosti dokazateljstva.

Nakonec, sozdannaya po rezuljtatam audita FUM-SBOJ-0012 sama poluchila devyatj kriteriyev, pochti pokryivayusjhikh odinnadcatj kriteriyev FUM-STEP-0140: krasnuyu fiksturu, urovni i adresa dokazateljstva, zapret usileniya, perenos v shag, ruchnoye sderzhivaniye i testyi. Eto tretjye proyavleniye [FUM-SBOJ-0011](../../Sboi/FUM-SBOJ-0011-kopirovaniye-kriteriyev-shagov-v-kartochki-sboyev.md) dobavleno v FUM-STEP-0139; tekusjhaya kartochka sokrasjhena do tryokh diagnosticheskikh rezuljtatov. Vse chetyire ruchnyiye korrekcii yavlyayutsya toljko vosstanovleniyem tekusjhikh tekstov i ne zakryivayut sistemnyiye kartochki.

Povtornyij audit ispravlennyikh par obnaruzhil yesjhyo dva proyavleniya [FUM-SBOJ-0012](../../Sboi/FUM-SBOJ-0012-pereobesjhannoye-adresuyemoye-dokazateljstvo-proyavleniya.md). FUM-STEP-0139 uzhe ssyilalasj na tretjye proyavleniye FUM-SBOJ-0011, no sama FUM-SBOJ-0011 ostavila v osnovanii svyazi toljko vtoroye; tochnyij nomer tretjyego teperj zerkaljno dobavlen. Krome togo, FUM-STEP-0139 nazyivala otchyotnyiye chisla i tematicheskiye rezyume «predkorrekcionnyim snimkom» i «tochnyimi snimkami», khotya prezhniye punktyi kriteriyev, ikh otpechatki i patch ne byili sokhranenyi. Shag teperj chestno nazyivayet oporu obobsjhyonnoj, a porozhdyonnyiye po nej regressii — sinteticheskimi; FUM-STEP-0140 aktualizirovana tochnyimi nomerami `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0003` i `FUM-СБОЙ-0012/ПРОЯВЛЕНИЕ-0004`.

Proverka ostaljnyikh povtoryayusjhikhsya kartochek vyiyavila pyatoye proyavleniye FUM-SBOJ-0012: FUM-STEP-0137 uzhe opisyivala tretjye proyavleniye ugadyivaniya puti, no ni ona, ni osnovaniye svyazi FUM-SBOJ-0009 ne sokhranyali tochnyij nomer `FUM-СБОЙ-0009/ПРОЯВЛЕНИЕ-0003`. Nomer dobavlen s obeikh storon, a FUM-STEP-0140 teperj trebuyet zerkaljnyij ryad kazhdogo proyavleniya nachinaya so vtorogo.

Posle dobavleniya etikh sluchayev v kriterii FUM-SBOJ-0012 ostalosj utverzhdeniye «Dlya oboikh proyavlenij», uzhe raskhodivsheyesya s fakticheskim ryadom. Shestoye proyavleniye fiksiruyet ostatochnuyu ruchnuyu schyotnuyu konstantu; formulirovka zamenena na okhvat vsekh sokhranyonnyikh proyavlenij, a FUM-STEP-0140 trebuyet vyivoditj chislo i granicyi ryada mashinno.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj                     | Granicyi i sposob izmereniya                                                                                                           |
| ------------------------ | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Ozhidaniye dopuska FIFO    | 8301,611 s (2 ch 18 min 21,611 s) | 2026-08-06 20:08:14,119–22:26:35,730 MSK; raznostj mashinnyikh epoch-metok registracii i dopuska sokhranyonnogo bileta                    |
| Soderzhateljnaya rabota    | 9726,270 s (2 ch 42 min 6,270 s)   | 2026-08-06 22:26:35,730–2026-08-07 01:08:42 MSK; ot dopuska do poslednej soderzhateljnoj pravki, vklyuchaya audityi i pervyij cikl priyomki |
| Celevyiye proverki         | sm. upravlyayemyij blok             | Summa verkhneurovnevyikh adresnyikh vyizovov do smoke-check; vlozhennyiye etapyi ne skladyivayutsya povtorno                                      |
| Polnyij smoke-check       | sm. poslednyuyu mashinnuyu stroku    | Poslednij zapisyivayemyij vyizov okhvachennoj granicyi                                                                                      |
| Atomarnyij commit+handoff | vne chislovoj granicyi             | Vyipolnyayetsya posle zakryitiya snimka i sluzhebnyikh samossyilochnyikh proverok                                                                 |

Granica profilya: nachalo — atomarnaya registraciya FIFO 2026-08-06 20:08:14,119 MSK; konec — rezuljtat poslednego predfinaljnogo polnogo smoke-check. Setevoye preryivaniye ne sozdalo otdeljnogo intervala: tot zhe bilet i process byili shtatno prodolzhenyi. Kalendarnyij interval soderzhateljnoj rabotyi vklyuchayet paralleljnyiye audityi i adresnyiye proverki; dliteljnosti samikh proverok otdeljno privedenyi v upravlyayemom bloke i povtorno s nim ne skladyivayutsya. Zakryitiye snimka, proverki yego samossyilochnoj svyaznosti i commit+handoff vyipolnyayutsya posle mashinnoj summyi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:d32c5aa894d4e7c00a54d9c97649fa841eefd8690d70de12a3ca87b29de770ab -->

| Vyizov                                                                                                               | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [kornevoj agent Codex] Peresborka mashinnogo planovogo reyestra                                                       | 0,315 s      | uspeshno   |
| [kornevoj agent Codex] Validaciya mashinnogo planovogo reyestra                                                        | 0,355 s      | uspeshno   |
| [kornevoj agent Codex] Validaciya strukturyi papok zaprosov                                                           | 7,694 s      | uspeshno   |
| [kornevoj agent Codex] Proverka probeljnoj chistotyi Git diff                                                         | 0,073 s      | uspeshno   |
| [kornevoj agent Codex] Povtornaya peresborka planovogo reyestra posle audita                                          | 0,304 s      | uspeshno   |
| [kornevoj agent Codex] Povtornaya validaciya planovogo reyestra posle audita                                           | 0,331 s      | uspeshno   |
| [kornevoj agent Codex] Povtornaya proverka probeljnoj chistotyi Git diff                                               | 0,039 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya peresborka planovogo reyestra posle revjyu                                           | 0,31 s       | uspeshno   |
| [kornevoj agent Codex] Finaljnaya validaciya planovogo reyestra posle revjyu                                            | 0,32 s       | uspeshno   |
| [kornevoj agent Codex] Obnovleniye Markdown-recency                                                                  | 0,613 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye teplovoj kartyi Obsidian                                                           | 0,318 s      | uspeshno   |
| [kornevoj agent Codex] Predfinaljnaya svyaznostj rabochej sessii                                                       | 23,58 s      | uspeshno   |
| [kornevoj agent Codex] Peresborka planovogo reyestra posle dobavleniya FUM-SBOJ-0004                                  | 0,324 s      | uspeshno   |
| [kornevoj agent Codex] Validaciya planovogo reyestra posle dobavleniya FUM-SBOJ-0004                                   | 0,309 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye svezhesti Markdown posle dobavleniya chetvyortoj kartochki sboya                        | 0,761 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye teplovoj kartyi grafa posle dobavleniya chetvyortoj kartochki sboya                     | 0,318 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya peresborka planovogo reyestra posle audita FUM-SBOJ-0004                            | 0,267 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya validaciya planovogo reyestra posle audita FUM-SBOJ-0004                             | 0,327 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnoye obnovleniye svezhesti Markdown posle audita FUM-SBOJ-0004                            | 0,613 s      | uspeshno   |
| [kornevoj agent Codex] Predfinaljnoye obnovleniye svezhesti Markdown posle otchyotnoj fiksacii                           | 0,594 s      | uspeshno   |
| [kornevoj agent Codex] Predfinaljnoye obnovleniye teplovoj kartyi grafa                                                | 0,367 s      | uspeshno   |
| [kornevoj agent Codex] Predfinaljnaya proverka probeljnoj chistotyi Git diff                                           | 0,045 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya adresnaya svyaznostj rabochej sessii pered smoke-check                                | 23,338 s     | neuspeshno |
| [kornevoj agent Codex] Peresborka planovogo reyestra posle dobavleniya FUM-SBOJ-0005                                  | 0,338 s      | uspeshno   |
| [kornevoj agent Codex] Validaciya planovogo reyestra posle dobavleniya FUM-SBOJ-0005                                   | 0,318 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye svezhesti Markdown posle dobavleniya FUM-SBOJ-0005                                  | 0,665 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya peresborka planovogo reyestra posle dobavleniya FUM-SBOJ-0006                        | 0,336 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya validaciya planovogo reyestra posle dobavleniya FUM-SBOJ-0006                         | 0,356 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnoye obnovleniye svezhesti Markdown posle dobavleniya FUM-SBOJ-0006                        | 0,648 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnoye obnovleniye teplovoj kartyi grafa posle dobavleniya FUM-SBOJ-0006                     | 0,376 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya probeljnaya chistota Git diff pered smoke-check                                      | 0,05 s       | uspeshno   |
| [kornevoj agent Codex] Povtornaya svyaznostj rabochej sessii posle fiksacii FUM-SBOJ-0005 i FUM-SBOJ-0006              | 24,911 s     | uspeshno   |
| [kornevoj agent Codex] Obnovleniye svezhesti Markdown posle predprosmotra zhurnala proverok                            | 0,643 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye teplovoj kartyi grafa posle predprosmotra zhurnala proverok                         | 0,371 s      | uspeshno   |
| [kornevoj agent Codex] Predfinaljnyij polnyij smoke-check repozitoriya                                                 | 1634,555 s   | uspeshno   |
| [kornevoj agent Codex] Peresborka planovogo reyestra posle dobavleniya FUM-SBOJ-0007                                  | 0,316 s      | uspeshno   |
| [kornevoj agent Codex] Validaciya planovogo reyestra posle dobavleniya FUM-SBOJ-0007                                   | 0,331 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye svezhesti Markdown posle dobavleniya FUM-SBOJ-0007                                  | 0,606 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya peresborka planovogo reyestra posle dobavleniya FUM-SBOJ-0008                        | 0,317 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnaya validaciya planovogo reyestra posle dobavleniya FUM-SBOJ-0008                         | 0,325 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnoye obnovleniye svezhesti Markdown posle dobavleniya FUM-SBOJ-0008                        | 0,616 s      | uspeshno   |
| [kornevoj agent Codex] Finaljnoye obnovleniye teplovoj kartyi grafa posle dobavleniya FUM-SBOJ-0008                     | 0,363 s      | uspeshno   |
| [kornevoj agent Codex] Itogovaya proverka chistotyi diff pered polnyim smoke-check                                      | 0,047 s      | uspeshno   |
| [kornevoj agent Codex] Peresborka planovogo reyestra posle dobavleniya povtoryayusjhikhsya FUM-SBOJ-0009 i FUM-SBOJ-0010    | 0,306 s      | uspeshno   |
| [kornevoj agent Codex] Validaciya planovogo reyestra posle dobavleniya povtoryayusjhikhsya FUM-SBOJ-0009 i FUM-SBOJ-0010     | 0,329 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye svezhesti Markdown posle dobavleniya povtoryayusjhikhsya FUM-SBOJ-0009 i FUM-SBOJ-0010    | 0,626 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye teplovoj kartyi grafa posle dobavleniya povtoryayusjhikhsya FUM-SBOJ-0009 i FUM-SBOJ-0010 | 0,323 s      | uspeshno   |
| [kornevoj agent Codex] Itogovaya probeljnaya chistota posle integracii FUM-SBOJ-0009 i FUM-SBOJ-0010                   | 0,049 s      | uspeshno   |
| [kornevoj agent Codex] Itogovaya svyaznostj rabochej sessii posle integracii FUM-SBOJ-0009 i FUM-SBOJ-0010             | 23,144 s     | uspeshno   |
| [kornevoj agent Codex] Okonchateljnaya peresborka planovogo reyestra posle FUM-SBOJ-0011 i FUM-SBOJ-0012               | 0,325 s      | uspeshno   |
| [kornevoj agent Codex] Okonchateljnaya validaciya planovogo reyestra posle FUM-SBOJ-0011 i FUM-SBOJ-0012                | 0,331 s      | uspeshno   |
| [kornevoj agent Codex] Okonchateljnoye obnovleniye svezhesti Markdown posle smyislovogo audita                           | 0,595 s      | uspeshno   |
| [kornevoj agent Codex] Okonchateljnoye obnovleniye teplovoj kartyi grafa posle smyislovogo audita                        | 0,366 s      | uspeshno   |
| [kornevoj agent Codex] Okonchateljnaya probeljnaya chistota pered itogovyim smoke-check                                  | 0,047 s      | uspeshno   |
| [kornevoj agent Codex] Okonchateljnaya svyaznostj rabochej sessii pered itogovyim smoke-check                            | 23,932 s     | uspeshno   |
| [kornevoj agent Codex] Obnovleniye svezhesti Markdown posle okonchateljnogo predprosmotra zhurnala proverok             | 0,557 s      | uspeshno   |
| [kornevoj agent Codex] Obnovleniye teplovoj kartyi grafa posle okonchateljnogo predprosmotra zhurnala proverok          | 0,356 s      | uspeshno   |
| [kornevoj agent Codex] Itogovyij polnyij smoke-check repozitoriya posle vsekh kartochek sboyev i smyislovogo audita        | 1638,71 s    | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 3417,999 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Mashinnyij planovyij reyestr peresobirayetsya i strukturno validiruyetsya posle vsekh izmenenij kartochek shagov, vklyuchaya FUM-STEP-0131–FUM-STEP-0140. Uspekh dejstvuyusjhego validatora ne obyyavlyayetsya dokazateljstvom korrektnosti `source_links`: etot nedostayusjhij invariant sokhranyon v FUM-SBOJ-0004.
- Struktura papok zaprosov, probeljnaya chistota diff, Markdown-recency, graf Obsidian i svyaznostj tekusjhej sessii poluchayut otdeljnyiye adresnyiye zapuski pered obsjhim smoke-check.
- Poslednyaya stroka upravlyayemogo bloka yavlyayetsya avtoritetnyim rezuljtatom predfinaljnogo polnogo smoke-check; zamyikayusjhiye proverki zakryitogo snimka vyipolnyayutsya posle nego i ne pereotkryivayut mashinnyij zhurnal.

## Resheniya i ogranicheniya

- Kartochki razmesjhenyi v kornevom `Сбои/`, a ne v `Планирование/` ili materialakh odnogo zaprosa: proyavleniya mogut otnositjsya k neskoljkim sessiyam, togda kak ispolnyayemyiye sposobyi ustraneniya ostayutsya kartochkami shagov.
- Imena kartochek ne soderzhat statusnyij emodzi. Izmeneniye sostoyaniya ne trebuyet pereimenovaniya, a tochnaya identichnostj khranitsya russkoyazyichnyimi polyami skhemyi `1` i neizmenyayemyim `FUM-СБОЙ-NNNN`.
- Statusyi ogranichenyi znacheniyami `активна`, `устранена`, `поглощена` i `снята`. Povtor posle ustraneniya vnovj aktiviruyet tu zhe kartochku, ne stiraya istoricheskoye dokazateljstvo.
- Setevoye preryivaniye tekusjhej zadachi ne klassificirovano kak sboj: bilet, FIFO-poziciya, rabocheye sostoyaniye i rezuljtat ne poteryanyi, a vozobnovleniye proshlo po dejstvuyusjhemu kontraktu.
- V sessii ne sozdayotsya otdeljnyij JSON-reyestr kartochek sboyev, ne rasshiryayetsya planovyij validator, ne menyayetsya skaner ssyilok i ne vvodyatsya novyiye sessionnyiye interfejsyi proverok, mashinnyij reyestr vyikhodov generatorov, host-konvert ozhidayemogo effekta, razreshitelj putej, agregator sostavnoj diagnostiki, detektor kopirovaniya kriteriyev ili tipizirovannyij reyestr dokazateljstv: obsjhij kontur kartochek ostayotsya yavno nezavershyonnoj chastjyu FUM-STEP-0114, ispravleniye razbora `source_links` — otdeljnoj FUM-STEP-0132, isklyucheniye strochnogo koda iz proverki ssyilok — FUM-STEP-0133, ustraneniye ruchnogo puti tekusjhego zaprosa — FUM-STEP-0134, polnyij inventarj vyikhodov grafa — FUM-STEP-0135, ograzhdeniye pustogo scenariya — FUM-STEP-0136, tochnoye razresheniye putej — FUM-STEP-0137, sokhraneniye rannego obyazateljnogo otkaza — FUM-STEP-0138, razdeleniye kriteriyev — FUM-STEP-0139, a adresuyemoye dokazateljstvo — FUM-STEP-0140. Kornevoj README i nomernaya dokumentaciya ne menyayutsya, potomu chto poljzovateljskij scenarij ispoljzovaniya FUM i predmetnaya arkhitektura produkta ne izmenilisj.
- Subagentyi vyipolnili tri razlichimyikh read-only-audita modeli kartochki, integracii s pamyatjyu i vyibora pervyikh proyavlenij; posle obnaruzheniya sboyev dva iz nikh sozdali v neperesekayusjhikhsya fajlakh chernovyiye paryi FUM-SBOJ-0009/FUM-STEP-0137, FUM-SBOJ-0010/FUM-STEP-0138, FUM-SBOJ-0011/FUM-STEP-0139 i FUM-SBOJ-0012/FUM-STEP-0140, a kornevoj agent proveril, ispravil i integriroval ikh v obsjhuyu pamyatj.
- Sessiya ne ispoljzuyet internet, ne sozdayot vneshniye effektyi i zavershayet toljko lokaljnyij commit+handoff bez `push` ili publikacii.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 01:39:12 MSK -->
<!-- content-sha256: sha256:8cdeec6a8923d0dab505aab305f98d5c71fa0b51778cad7b455ca4f6216318f9 -->
<!-- FUM-MD-RECENCY:END -->
