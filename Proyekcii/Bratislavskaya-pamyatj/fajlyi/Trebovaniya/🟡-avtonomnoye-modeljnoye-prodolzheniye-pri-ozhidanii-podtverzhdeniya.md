# Avtonomnoye modeljnoye prodolzheniye pri ozhidanii podtverzhdeniya

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0035 -->

[Korobochnaya realizaciya FUM](../Glossarij/korobochnaya-realizaciya-FUM.md) ne dolzhna ostanavlivatj vesj [agentskij cikl](../Glossarij/agentskij-cikl.md) toljko potomu, chto sleduyusjhij vneshnij perekhod trebuyet poljzovateljskogo podtverzhdeniya. Poka podtverzhdeniye otsutstvuyet, etot perekhod ostayotsya zakryityim, a tot zhe myisliteljnyij epizod prodolzhayet bezopasnyiye i produktivnyiye modeljnyiye shagi toljko v predelakh nezavisimo razreshyonnogo dlya nego model-only-runtime i konechnogo byudzheta.

Takoj dopusk zakreplyayet tochnuyu identichnostj provajdera, lokaljnyij ili udalyonnyij rezhim, razreshyonnyij obyyom raskryivayemyikh dannyikh i limityi vyizovov, tokenov, vremeni, vyichislenij i deneg. Samo ozhidaniye podtverzhdeniya ne uvelichivayet ni odin limit i ne razreshayet dopolniteljnuyu peredachu dannyikh. Yesli nezavisimo zadannogo dopuska net ili yego byudzhet ischerpan, FUM sokhranyayet kontroljnuyu tochku vmesto novogo modeljnogo vyizova.

Samostoyateljnyij vyibor FUM v etoj faze yavlyayetsya modeljnyim dopusjheniyem, vnutrennim otborom ili rekomendaciyej, no ne poljzovateljskim namereniyem, podtverzhdeniyem libo razresheniyem. Otsutstviye otveta otlichayetsya ot yavnogo otkaza ili otzyiva: otkaz zakryivayet otnosyasjhijsya k nemu perekhod i ne mozhet byitj preobrazovan v podrazumevayemoye soglasiye.

Pri soderzhateljnoj neodnoznachnosti i dostatochnom resurse FUM sozdayot dva ili boleye varianta ot odnogo tochnogo modeljnogo predka. Kazhdyij variant imeyet yavnoye otlichiye, otdeljnyij byudzhet, kriterij proverki, proiskhozhdeniye i nablyudayemyij rezuljtat. Otbor mozhet vyibratj variant dlya daljnejshej modeljnoj prorabotki, sokhranitj neskoljko zhiznesposobnyikh vetvej ili priznatj neodnoznachnostj neustranyonnoj; ni odin iz etikh iskhodov sam po sebe ne vooruzhayet vneshnij ispolniteljnyij kontur.

## Semanticheskiye svyazi

- **usilivayet:** [poljzovateljskoye perenapravleniye nepreryivnogo agentskogo cikla](🟡-poljzovateljskoye-perenapravleniye-nepreryivnogo-agentskogo-cikla.md) — ozhidayemyij poljzovateljskij signal ne prevrasjhayet produktivnuyu modeljnuyu fazu v polnuyu ostanovku, a pozdnij signal primenyayetsya na bezopasnoj kontroljnoj tochke.
- **usilivayet:** [skvoznoj proveryayemyij odnoagentnyij epizod FUM](✅-skvoznoj-proveryayemyij-odnoagentnyij-epizod-FUM.md) — odnoagentnyij runtime dolzhen nezavisimo predstavlyatj priparkovannyij vneshnij effekt i prodolzhayusjheyesya modeljnoye sostoyaniye.
- **usilivayetsya:** [proveryayemyim mnogoagentnyim konturom FUM](🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md) — razlichimyiye roli, gipotezyi i sposobyi proverki povyishayut kachestvo vetvleniya, no korrelirovannoye soglasiye ne stanovitsya podtverzhdeniyem poljzovatelya.

## Kriterii proverki

- determinirovannaya fikstura dokhodit do perekhoda, trebuyusjhego podtverzhdeniya, sokhranyayet tochnyij obyyekt, versiyu, ozhidayemyij effekt i usloviye dopuska, no ne vyipolnyayet perekhod bez dejstviteljnogo otveta;
- pri nalichii dvukh soderzhateljno razlichnyikh i resursno dopustimyikh prodolzhenij fikstura sozdayot ikh ot obsjhego tochnogo predka, ogranichivayet byudzhet kazhdoj vetvi, sokhranyayet razlichiya, proverki i proiskhozhdeniye i prodolzhayet kak minimum odin nablyudayemyij modeljnyij shag v kazhdoj;
- vnutrennij otbor mozhet pometitj variant kak `selected_in_model` ili `recommended`, no `transition_user_confirmed` voznikayet toljko iz dejstviteljnogo poljzovateljskogo sobyitiya dlya tochnogo perekhoda i versii, `authorized` — iz nezavisimoj politiki polnomochij, `preflight_passed` — iz proverki tekusjhego sostoyaniya, `executed` — iz sobyitiya ispolniteljnogo adaptera, a `observed` — iz svideteljstva fakticheskogo rezuljtata;
- model-only-faza ne vyikhodit za nezavisimo zadannyij setevoj ili servisnyij dopusk, ne podklyuchayet novyij provajder ili adres servisa, ne uvelichivayet uzhe razreshyonnyiye vyizovyi, raskryitiye dannyikh ili raskhodyi, ne izvlekayet sekretyi, ne rasshiryayet prava, ne publikuyet, ne otpravlyayet soobsjheniya, ne sovershayet platyozh ili fizicheskoye dejstviye;
- append-only-trassa, kandidatnyiye artefaktyi i kontroljnaya tochka mogut zapisyivatjsya toljko po nezavisimo zadannoj politike khraneniya epizoda; modeljnyij vyibor, uspeshnaya modeljnaya proverka i ozhidaniye otveta ne povyishayut kandidata do prinyatogo kanonicheskogo sostoyaniya, dlya kotorogo trebuyetsya otdeljnyij protokol priyomki;
- yesli byudzhet pozvolyayet toljko odin variant, FUM vyibirayet yego po obyyavlennoj politike, sokhranyayet neproverennyiye aljternativyi i ne obyyavlyayet neodnoznachnostj ustranyonnoj sravneniyem;
- ischerpaniye byudzheta ili otsutstviye bezopasnoj produktivnoj rabotyi sozdayut vosproizvodimuyu kontroljnuyu tochku ozhidaniya, a ne lozhnoye zaversheniye zadachi; nereshyonnyij konflikt stanovitsya terminaljnyim toljko posle ischerpaniya dostupnyikh razlichayusjhikh proverok libo kogda ostavshiyesya proverki nebezopasnyi, neproduktivnyi ili vyikhodyat za byudzhet;
- pozdneye podtverzhdeniye svyazyivayetsya s tochnyim ozhidayusjhim perekhodom i yego versiyej, povtorno prokhodit predstartovuyu proverku i mozhet perenapravitj rabotu k sokhranyonnoj aljternative bez perepisyivaniya istorii; ustarevsheye podtverzhdeniye otklonyayetsya;
- trassa pokazyivayet prichinnuyu posledovateljnostj modeljnyikh sostoyanij, variantov, proverok i otbora, no ne trebuyet nepreryivnogo inference i ne serializuyet skryityiye rassuzhdeniya modeli.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: odin sinteticheskij sobstvennyij runtime-scenarij uzhe proveryayet dva model-only-varianta ot obsjhego predka, konechnyij byudzhet i pozdneye vneshneye mashinnoye svideteljstvo bez povyisheniya vnutrennego vyibora do dopuska. Pri etom harness sam sozdayot tochnoye podtverzhdeniye posle nablyudeniya checkpoint; zhivoj poljzovateljskij kanal, yego otkaz ili otzyiv i perenapravleniye k sokhranyonnoj aljternative yesjhyo ne proverenyi.

Trebovaniye razreshayet toljko rabotu vnutri uzhe dopustimoj modeljnoj sredyi i zaraneye ogranichennogo vyichisliteljnogo kontura. Ono ne sozdayot novyiye polnomochiya, ne podmenyayet podtverzhdeniye, ne trebuyet beskonechnogo myishleniya i ne prevrasjhayet vnutrennij vyibor v dokazateljstvo istinnosti ili bezopasnosti vneshnego rezuljtata.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [otchyot zhivogo progona odnoagentnogo epizoda](../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [iskhodnyij zapros 2026-07-29 10:25:10 MSK — Prodolzhatj myishleniye pri ozhidanii podtverzhdeniya](../Zhurnal/2026-07-29_10-25-10_MSK_prodolzhatj-myishleniye-pri-ozhidanii-podtverzhdeniya/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:6b0e4f495b83f77b22cd45b5dfab60e942f99087745b288d471f838879c62044 -->
<!-- FUM-MD-RECENCY:END -->
