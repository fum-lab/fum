# Otchyot 2026-08-12 03:09:35 MSK - Smodelirovatj vetvleniye FUM derevom forkov

V pamyati FUM zakreplena modelj rekursivnogo vetvleniya: odin linejnyij vetvevoj fork mozhet poroditj rovno dva dochernikh fork ot proverennogo obsjhego Git-sostoyaniya, a tot zhe roditeljskij logicheskij uzel perekhodit v vosstanavlivayemuyu rolj moderatora. Kazhdyij rebyonok imeyet odnu avtoritetnuyu paru repozitoriya i polnogo rabochego ref, odin zhivoj pishusjhij checkout i ne boleye odnoj dopusjhennoj sessii-vladeljca. Ozhidayusjheye prodolzheniye, neaktivnaya dochernyaya zadacha i vneshnyaya proveryayusjhaya zadacha bez prava zapisi vladeljcami fork ne yavlyayutsya.

Vetvevoj fork otdelyon ot fizicheskogo fork-repozitoriya i efemernoj host-sessii. Repozitorij ostayotsya dolgovechnyim kontejnerom i mozhet soderzhatj zerkaljnyij `master`, sluzhebnyiye, rezuljtatnyiye i pull-request refs. Derevom yavlyayetsya toljko neizmenyayemaya genealogiya s odnim kornem i odnim roditelem u kazhdogo potomka; posle vyibora ili sliyaniya Git-graf zakonomerno stanovitsya DAG. Prezhnyaya roditeljskaya sessiya ne uderzhivayet FIFO vo vremya dochernej rabotyi: novaya ograzhdyonnaya sessiya toj zhe logicheskoj identichnosti vosstanavlivayet moderaciyu iz pasporta i sravnivayet zakreplyonnyiye vershinyi po kriteriyam, zadannyim do rezuljtatov.

Novoye trebovaniye FUM-REQ-0043 prinyato so statusom `🟡`, a realizaciya dekompozirovana kartochkoj FUM-STEP-0145 i utochneniyami posleduyusjhikh shagov kornevogo reyestra, resursnogo dopuska, revjyu, avtonomnoj i zhivoj priyomki. Dejstvuyusjhij linejnyij `commit+handoff` ne izmenyon: vnutri kazhdogo fork odin kommit po-prezhnemu imeyet rovno odno prodolzheniye toj zhe vetki. Realjnyij dvukhklonovyij i host-kontur etoj sessiyej ne obyyavlyayetsya realizovannyim.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                                                                                 |
| ------------------------ | ------------ | ---------------------------------------------------------------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | Dolgozhivusjhij `wait-until-actionable` zavershilsya dopuskom posle predshestvennika; monotonnyiye metki ne velisj. |
| Soderzhateljnaya rabota    | ne izmereno  | Inventarizaciya, proyektirovaniye, pravki i nezavisimyiye revjyu perekryivalisj; yedinyij tajmer ne zapuskalsya.     |
| Celevyiye proverki         | po zhurnalu   | Tochnyiye dliteljnosti pryamyikh zapuskov izmeryayutsya monotonnyimi chasami v upravlyayemom bloke nizhe.                |
| Polnyij smoke-check       | po zhurnalu   | Finaljnyij polnyij kontur yavlyayetsya poslednej zaregistrirovannoj proverkoj pered zakryitiyem snimka.           |
| Atomarnyij commit+handoff | ne izmereno  | Vyipolnyayetsya posle zakryitiya otchyota i sozdaniya tochnogo prodolzheniya; v snimok proverok ne vkhodit.             |

Granica profilya: kanonicheskaya metka zaprosa sozdana posle dopuska FIFO; predshestvuyusjheye ozhidaniye vklyucheno kachestvenno bez vyidumannoj dliteljnosti. Proverki uchityivayutsya otdeljno, a host-sozdaniye prodolzheniya i Git-peredacha vyipolnyayutsya posle zakryitiya proverochnogo snimka.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; снимок=материалы/запуски-проверок/снимок.json; sha256=sha256:4dd60b02a3a65ae143708cf83d26a1cf974b56b4fac26c0dacb5df7604a23b43 -->

| Vyizov                                                              | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------------------ | ------------ | --------- |
| [kornevoj agent] Peresborka planovogo reyestra                      | 0,373 s      | uspeshno   |
| [kornevoj agent] Povtornaya peresborka planovogo reyestra            | 0,323 s      | uspeshno   |
| [kornevoj agent] Validaciya planovogo reyestra                       | 0,368 s      | uspeshno   |
| [kornevoj agent] Validaciya sleduyusjhego shaga vetki                   | 0,842 s      | uspeshno   |
| [kornevoj agent] Finaljnaya peresborka planovogo reyestra            | 0,325 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti Markdown                      | 0,626 s      | uspeshno   |
| [kornevoj agent] Obnovleniye svezhesti grafa Obsidian                | 0,379 s      | uspeshno   |
| [kornevoj agent] Finaljnaya validaciya planovogo reyestra             | 0,321 s      | uspeshno   |
| [kornevoj agent] Finaljnaya validaciya sleduyusjhego shaga vetki         | 0,807 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti Markdown                        | 0,621 s      | neuspeshno |
| [kornevoj agent] Svyaznostj rabochej sessii                          | 26,313 s     | neuspeshno |
| [kornevoj agent] Povtornoye obnovleniye svezhesti Markdown            | 0,665 s      | uspeshno   |
| [kornevoj agent] Povtornaya svyaznostj rabochej sessii                | 26,623 s     | uspeshno   |
| [kornevoj agent] Publikacionnaya proverka diff                      | 0,078 s      | uspeshno   |
| [kornevoj agent] Povtornoye obnovleniye svezhesti grafa Obsidian      | 0,386 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka svezhesti Markdown              | 0,599 s      | uspeshno   |
| [kornevoj agent] Proverka svezhesti grafa Obsidian                  | 0,386 s      | uspeshno   |
| [kornevoj agent] Predfinaljnoye obnovleniye svezhesti Markdown        | 0,621 s      | uspeshno   |
| [kornevoj agent] Predfinaljnoye obnovleniye svezhesti grafa Obsidian  | 0,391 s      | uspeshno   |
| [kornevoj agent] Polnyij smoke-check repozitoriya                    | 0,973 s      | neuspeshno |
| [kornevoj agent] Povtornyij polnyij smoke-check repozitoriya          | 39,728 s     | neuspeshno |
| [kornevoj agent] Obnovleniye svezhesti posle diagnostiki smoke-check | 0,63 s       | uspeshno   |
| [kornevoj agent] Obnovleniye grafa posle diagnostiki smoke-check    | 0,381 s      | uspeshno   |
| [kornevoj agent] Proverka snimka obyyavlenij koda                   | 4,418 s      | uspeshno   |
| [kornevoj agent] Predfinaljnaya svyaznostj rabochej sessii            | 26,593 s     | uspeshno   |
| [kornevoj agent] Predfinaljnaya publikacionnaya proverka diff        | 0,09 s       | uspeshno   |
| [kornevoj agent] Itogovyij polnyij smoke-check repozitoriya           | 372,866 s    | neuspeshno |
| [kornevoj agent] Adresnyij test rabochego nabora vetki               | 2,088 s      | uspeshno   |
| [kornevoj agent] Povtornaya proverka snimka obyyavlenij koda         | 5,28 s       | uspeshno   |
| [kornevoj agent] Predyitogovoye obnovleniye svezhesti grafa Obsidian   | 0,381 s      | uspeshno   |
| [kornevoj agent] Itogovoye obnovleniye svezhesti Markdown             | 0,625 s      | uspeshno   |
| [kornevoj agent] Finaljnyij polnyij smoke-check repozitoriya          | 2387,265 s   | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 2902,365 s.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Mashinnyij planovyij reyestr uspeshno peresobran posle dobavleniya trebovaniya, kartochki i zavisimostej cepochki.
- Tri nezavisimyiye inventarizacii bez prava zapisi podtverdili glavnyiye granicyi: tekusjhaya FIFO unikaljna toljko dlya odnogo fizicheskogo checkout; fizicheskij fork-repozitorij ne raven vetke; susjhestvuyusjhij `commit+handoff` vyirazhayet rovno odno prodolzheniye i ne dolzhen rasshiryatjsya do dvukh detej.
- Nezavisimyiye smyislovoye, planovoye i redaktorskoye revjyu zavershenyi. Po ikh rezuljtatam moderator zakreplyon kak tot zhe logicheskij roditelj, roditeljskij rabochij ref — kak yavnaya celj integracii, dochernij dopusk — kak globaljnyij predaktivacionnyij barjyer, a vozobnovleniye neodnoznachnoj sagi — toljko kak prodolzheniye ot dokazannoj granicyi.
- Rannij vspomogateljnyij zapusk `git diff --check` vne otchyotnoj obyortki ne vyiyavil oshibok; pered finaljnyim smoke-check on dubliruyetsya uchityivayemoj publikacionnoj proverkoj.
- Pervaya proverka svezhesti Markdown i pervaya svyaznostj ozhidayemo obnaruzhili ustarevshuyu metku otchyota posle obnovleniya upravlyayemoj tablicyi zapuskov. Povtornoye obnovleniye svezhesti ispravilo otchyot i indeks, posle chego svyaznostj i obe proverki svezhesti zavershilisj uspeshno.
- Pervyij polnyij smoke-check ne proshyol podgotovku, potomu chto vlozhennyij SwiftPM `sandbox-exec` byil zapresjhyon pesochnicej sredyi. Povtor s neobkhodimyim sistemnyim dostupom proshyol podgotovku, no obnaruzhil pozicionno-chuvstviteljnoye raskhozhdeniye snimka latinskikh obyyavlenij: obsjhij ostatok ne vyiros (`43 192`, iz nikh `460` Mermaid), a staryiye latinskiye uzlyi lishj smestilisj posle vstavki novoj kirillicheskoj diagrammyi. Inventarj prosmotren, snimok yavno obnovlyon lokaljnyim navyikom; obe neuspeshnyiye popyitki sokhranenyi pered itogovyim povtorom.
- Sleduyusjhij polnyij progon proshyol ispravlennuyu granicu obyyavlenij i ostanovilsya na yedinstvennom ustarevshem repozitornom ozhidanii testa vetochnogo selektora: novaya planovaya kartochka uvelichila chislo kandidatov s `17` do `18`, a priostanovlennyikh — s `12` do `13`. Schyotnyij kontrakt testa sinkhronizirovan s uzhe proverennyim rabochim naborom; vse popyitki ostayutsya v zhurnale pered povtorom.
- Adresnyiye validatoryi, svezhestj Markdown i grafa, svyaznostj, publikacionnaya chistota diff i polnyij smoke-check vyipolnyayutsya do zakryitiya otchyota; neobkhodimyiye proverki zamyikaniya izmenivshegosya otchyota vyipolnyayutsya posle zakryitiya vne upravlyayemogo snimka.

## Resheniya i ogranicheniya

- «Odin fork — odna vetka» oznachayet postoyannuyu svyazj logicheskogo fork s odnoj avtoritetnoj paroj repozitoriya i polnogo rabochego ref. Para ne pereispoljzuyetsya drugim pokoleniyem; tekhnicheskiye refs fizicheskogo repozitoriya v etu kardinaljnostj ne vkhodyat.
- «Odna aktivnaya sessiya» oznachayet ne boleye odnoj avtoritetnoj sessii-vladeljca: pishusjhej libo moderiruyusjhej. Ozhidayusjheye prodolzheniye, neaktivnaya dochernyaya zadacha i vneshnyaya proveryayusjhaya zadacha bez prava zapisi ne poluchayut etot dopusk.
- Roditelem-moderatorom ostayotsya tot zhe logicheskij fork i yego sokhranyayemoye sostoyaniye, a ne otdeljnyij tretij uzel ili prezhnyaya host-sessiya. Poka deti rabotayut, roditelj ne uderzhivayet aktivnuyu sessiyu ili FIFO.
- Dvoichnaya razvilka yavlyayetsya otdeljnoj sagoj s bezopasnoj ostanovkoj. Obe docherniye zadachi gotovyatsya bez prava zapisi i ne vkhodyat v svoi FIFO do yedinogo CAS-perekhoda globaljnogo predaktivacionnogo barjyera. Neodnoznachnostj odnoj storonyi zapresjhayet novyij vyizov sozdaniya; prodolzheniye dopustimo toljko posle avtoritetnogo chteniya prezhnej popyitki libo yavnogo chelovecheskogo vosstanovleniya.
- Yesli pered razvilkoj nuzhen soderzhateljnyij kommit, obyichnoye unarnoye prodolzheniye snachala prinimayet uzhe zafiksirovannuyu vershinu; koordinator zatem ne pishet roditeljskij rabochij ref i zavershayet yego FIFO cherez `finish-clean` posle aktivacii detej.
- Kazhdyij rebyonok vnutri sebya ostayotsya linejnyim i sozdayot rovno odno prodolzheniye na kommit. Mnogoroditeljskij kommit dopustim toljko na otdeljnoj integracionnoj granice posle moderatorskogo resheniya; v pervoj versii integrator CAS-perekhodom dvigayet zamorozhennyij roditeljskij rabochij ref.
- Kriterii sravneniya zakreplyayutsya do rezuljtatov; tipizirovannyiye iskhodyi razlichayut vyibor levogo, vyibor pravogo, sovmestimoye obyyedineniye, dorabotku, otkloneniye oboikh i neopredelyonnostj.
- Novoye trebovaniye zaplanirovano, no ne realizovano. Realjnyiye klonyi, refs, `create_thread`, remotes, push i publikaciya ostayutsya v posleduyusjhikh kartochkakh i trebuyut sootvetstvuyusjhikh polnomochij.
- Pozicionno-chuvstviteljnyij snimok istoricheskogo latinskogo ostatka obyyavlenij obnovlyon bez uvelicheniya kolichestva; eto sledstviye smesjheniya staroj Mermaid-diagrammyi, a ne razresheniye novogo latinskogo imeni.
- Repozitornaya fikstura vetochnogo selektora teperj ozhidayet `18` kandidatov i `13` priostanovlennyikh sostoyanij, sokhranyaya prezhniye `2` gotovyikh i `3` zablokirovannyikh.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 04:51:06 MSK -->
<!-- content-sha256: sha256:d61c190d5e5b4fcb0a2dbe4d49b8c10008813f9b40d05bd108a11d4f48103324 -->
<!-- FUM-MD-RECENCY:END -->
