# Otchyot 2026-07-26 15:15:18 MSK - Publikovatj rabotu v GitHub avtomaticheski

Rabochiye sessii FUM teperj zavershayutsya ne toljko lokaljnyim commit+handoff, no i obyazateljnoj avtomaticheskoj popyitkoj publikacii sozdannogo kommita v nastroyennuyu GitHub-vetku. Pravilo okhvatyivayet ruchnyiye i dispetcherskiye kornevyiye zadachi; no-op-putj `finish-clean` po-prezhnemu nichego ne kommitit i ne otpravlyayet.

## Kontrakt zaversheniya rabochej sessii

Lokaljnaya FIFO-tranzakciya ostalasj setenezavisimoj: ona atomarno sozdayot kommit, prodvigayet lokaljnuyu vetku i snimayet vladeljca ocheredi. Do etoj peredachi korenj sokhranyayet yedinstvennyij bezopasnyij push URL. Posle rezuljtata `committed` prezhnyaya zadacha poluchayet uzkoye isklyucheniye iz zapreta vneshnikh dejstvij i zapuskayet publikator iz tochnogo `new_head`.

Publikator prinimayet toljko polnyij commit object, polnyij `refs/heads/...` i credential-free HTTPS GitHub URL bez primenimoj `url.*.insteadOf` ili `url.*.pushInsteadOf` konfiguracii. On otpravlyayet rovno `<new_head>:<branch_ref>`, ne chitayet tekusjhij `HEAD`, ne ispoljzuyet remote po imeni, otklyuchayet lokaljnyij pre-push hook i interaktivnyiye zaprosyi terminala i menedzhera uchyotnyikh dannyikh, ne peredayot tegi i ne primenyayet force. Pri tajm-aute vsya gruppa transportnyikh processov zavershayetsya do kontroljnogo chteniya udalyonnoj vershinyi. Posle rezuljtata publikacii prezhnyaya zadacha okonchateljno prekrasjhayet vneshniye mutacii.

## Bezopasnostj udalyonnoj publikacii

Razdeleniye handoff i push ostavlyayet neizbezhnoye neatomarnoye okno mezhdu lokaljnyim Git i GitHub, no ne rasshiryayet publikuyemyij rezuljtat. Yesli sleduyusjhaya zadacha uzhe prodvinula i opublikovala potomka, prezhnij kommit raspoznayotsya kak uzhe dostizhimyij. Yesli istoriya razoshlasj, server otklonil zapisj ili setj ostavila neodnoznachnyij rezuljtat, lokaljnyij kommit sokhranyayetsya, ocheredj ne otkatyivayetsya, a sboj yavno soobsjhayetsya bez `pull`, merge, rebase ili force-push.

Proverka neizvestnogo lokaljno udalyonnogo object ID vyipolnyayetsya vo vremennom bare-repozitorii s yavno pustyim katalogom hooks. Obsjhiye checkout, indeks, refs i object database posle handoff ne menyayutsya. Avtonomnyiye testyi ispoljzuyut lokaljnyij bare-remote i vnutrennij testovyij dopusk Git URL rewrite, nedostupnyij iz CLI, poetomu ne trebuyut GitHub, seti ili sekretov.

## Proverki

- TDD-krasnaya stadiya: iskhodnyiye novyiye scenarii zavershilisj devyatjyu ozhidayemyimi assertion-failure, potomu chto CLI yesjhyo ne soderzhal `publish`.
- TDD-zelyonaya stadiya i posleduyusjheye usileniye po rezuljtatam revjyu: chetyirnadcatj scenariyev post-handoff-publikacii proshli za ≈ 11,4 s.
- Itogovyij polnyij nabor avtomatizacii ocheredi proshyol 49 iz 49 testov za ≈ 55,2 s.
- Recency i graf, svyaznostj sessii, `git diff --check` i polnyij smoke-check iz 58 etapov proshli; sandbox-ogranicheniye pervogo smoke-zapuska ne byilo defektom repozitoriya, a povtor vne pesochnicyi vyiyavil i pozvolil ispravitj pyatj publikacionno nebezopasnyikh testovyikh/runtime-literalov do itogovogo zelyonogo progona.

## Profilj vremeni vyipolneniya

| Stadiya                                 |       Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                                                                                                              |
| -------------------------------------- | -----------------: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya, ozhidaniye i dopusk FIFO    | ≈ 27 ch 22 min 18 s | Raznostj sokhranyonnyikh otmetok registracii `2026-07-25T08:49:16.490Z` i dopuska `2026-07-26T12:11:34.401Z`; okno vklyuchayet padeniye i shtatnoye vozobnovleniye toj zhe kornevoj zadachi s sokhranyonnyim `seq 46`.                                  |
| Audit, TDD i izmeneniye dokumentacii    |        ne izmereno | Rabota prodolzhilasj posle dolgogo ozhidaniya i vosstanovleniya konteksta; shestj razlichimyikh read-only-auditov vyipolnyalisj dvumya paralleljnyimi volnami, a dostovernaya yedinaya wall-clock-granica soderzhateljnoj stadii otdeljno ne sokhranena. |
| Celevyiye testyi post-handoff-publikatora |           ≈ 11,4 s | Itogovyij progon chetyirnadcati offline-scenariyev na lokaljnyikh bare-remote; krasnyij i promezhutochnyiye progonyi ne pribavlenyi povtorno.                                                                                                        |
| Polnyij nabor testov ocheredi            |           ≈ 55,2 s | Otdeljnyij itogovyij process proshyol 49 iz 49 testov; celevoj progon predyidusjhej stroki v dliteljnostj povtorno ne pribavlen.                                                                                                               |
| Polnyij smoke-check                     |      ≈ 4 min 1,0 s | Itogovyij zelyonyij progon proshyol 58 iz 58 etapov; neuspeshnyiye predvariteljnyiye progonyi i uzhe otdeljno uchtyonnyij celevoj progon ne pribavlenyi povtorno.                                                                                       |

Granica profilya: ot atomarnoj registracii prezhnego FIFO-bileta do zaversheniya itogovogo polnogo smoke-check; ozhidaniye otdeleno ot aktivnoj rabotyi, paralleljnyiye audityi ne summiruyutsya, a commit+handoff i vneshnij push sleduyut posle izmerennoj granicyi.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [kontrakt ocheredi zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [publichnyij upstream i forki pamyati](../../Dokumentaciya/27-publichnyij-upstream-i-forki-pamyati.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1e69798a11d704ad1673eb7af71d0daded8f8f523dc3e722b8cdcf982d2a6c74 -->
<!-- FUM-MD-RECENCY:END -->
