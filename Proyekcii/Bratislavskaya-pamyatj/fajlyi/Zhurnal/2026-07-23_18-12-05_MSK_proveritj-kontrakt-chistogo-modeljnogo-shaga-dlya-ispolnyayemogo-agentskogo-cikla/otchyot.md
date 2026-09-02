# Otchyot 2026-07-23 18:12:05 MSK - Proveritj kontrakt chistogo modeljnogo shaga dlya ispolnyayemogo agentskogo cikla

Pamyatj FUM poluchila proveryayemuyu granicu mezhdu modeljyu i sobstvennyim [agentskim ciklom](../../Glossarij/agentskij-cikl.md). Odin vyizov teperj opisan kak strogij obmen dannyimi: vneshnij runtime peredayot polnyij kontekst, a provajder vozvrasjhayet inertnyij tekst ili strukturirovannuyu oshibku, ne poluchaya prava samostoyateljno chitatj pamyatj, vyizyivatj instrumentyi i prodolzhatj cikl.

## Rezuljtat

[Kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md) versii `1` zakreplyayet JSON-konvertyi zaprosa, uspekha i oshibki. Zapros soderzhit zadannyij vyizyivayusjhim `invocation_id`, ozhidayemuyu identichnostj provajdera, uporyadochennyiye soobsjheniya, format otveta, predelyi i tri yavno vyiklyuchennyiye effect-capabilities. Uspekh svyazyivayetsya s kanonicheskim vkhodom cherez `input_sha256` i fiksiruyet toljko nablyudayemyij tekst i bajtovyiye metriki.

[Swift-prototip](../../Prototipyi/chistyij-modeljnyij-shag/README.md) realizuyet profilj `fum.deterministic-echo.v1` bez vneshnikh zavisimostej. Zaglushka vozvrasjhayet posledneye soobsjheniye `user`, proveryayet limit, ne obrasjhayetsya k shell, fajlam, seti ili subprocess i kodiruyet otvet s otsortirovannyimi klyuchami. Vstroyennaya fikstura bezopasno zapuskayetsya obsjhej paneljyu prototipov.

## Proverennyij modeljnyij kontur

Pervyij TDD-progon zafiksiroval ozhidayemoye povedeniye do realizacii i ostanovilsya na otsutstvuyusjhej celi. Posle realizacii odin test obnaruzhil ustarevsheye ozhidaniye pervogo kanonicheskogo klyucha: dobavlennyij `input_sha256` sortiruyetsya ranjshe `metrics`. Ispravlennyij nabor iz `12` testov proshyol polnostjyu.

Testyi podtverzhdayut UTF-8-metriki, pobitovuyu povtoryayemostj, izmeneniye khyesha pri izmenenii konteksta, strogij zapret neizvestnyikh polej i effect-capabilities, obyazateljnoye soobsjheniye `user`, oshibku prevyisheniya vyikhoda i sokhraneniye shell-metasimvolov kak obyichnogo teksta. Rezuljtat, pokhozhij na predlozheniye dejstviya, ostayotsya strokoj i ne ispolnyayetsya.

## Granica primenimosti

Rabota zavershena na determinirovannoj zaglushke. Ona dokazyivayet interfejs, izolyaciyu effektov i vosproizvodimostj testovogo profilya, no ne yavlyayetsya LLM i ne proveryayet kachestvo realjnogo vyivoda. Predel vremeni prisutstvuyet v konverte, odnako mgnovennaya zaglushka ne dokazyivayet ostanovku zavisshego process-adapter.

Susjhestvuyusjhij Ollama-kontur tenevogo redaktora sokhranyayetsya kak chastichnoye svideteljstvo lokaljnogo stdin-vyizova, loopback, predvariteljnoj proverki modeli, otmenyi i predela vyivoda. Dlya obsjhego profilya yemu ne khvatayet polnoj identichnosti runtime, vesov i parametrov generacii. Lokaljnaya spravka `Codex CLI 0.144.6` opisyivayet `codex exec` kak neinteraktivnyij zapusk Codex i predlagayet sandbox dlya sozdannyikh modeljyu shell-komand; otdeljnyij rezhim bez agentskogo cikla i instrumentov ne nablyudalsya, poetomu etot putj ne prinyat.

Trassa agentskogo cikla versii `1` khranit toljko `model_step.mode` i `provider_ref`, no ne otdeljnoye sobyitiye vyizova. Polnyij konvert poka ostayotsya otdeljnyim artefaktom i ne maskiruyetsya pod vyipolnennoye dejstviye.

## Proverki

- `swift test` dlya novogo paketa proshyol: `12` testov, `0` otkazov; otdeljnyiye `swift build` i strogij `swift format lint` takzhe proshli.
- Vstroyennaya fikstura dvazhdyi napechatala pobitovo odinakovyij kanonicheskij JSON s `input_sha256`; shell-podobnyij vvod ne sozdal fajl i sokhranilsya kak tekst.
- Probnik otklonil vkhod razmerom `1048577` bajt i vernul publikacionno chistuyu oshibku neizvestnogo polya bez peredannogo sekretopodobnogo markera.
- JSON Schema i politika SwiftPM razobranyi standartnyim JSON-parserom Python; tri `запустить.sh`, vklyuchaya novyij, proshli strukturnuyu proverku, a novyij launcher — `sh -n` i bezopasnyij zapusk.
- Planovyij reyestr peresobran i proveren; fenced-proverka podtverdila `master-fum-step-0001-ready-v1`, tochnyij khyesh kartochki i sokhranyonnyij `blocked`-kandidat.
- Predfinaljnyij polnyij smoke-check proshyol vse `42/42` shaga. Posle nego testovyiye literalyi ochisjhenyi ot mashinno-pokhozhikh putej, literala peremennoj domashnego kataloga i kompilyatorskogo polnogo puti bez oslableniya regressij; okonchateljnyij povtor na ochisjhennom snimke takzhe proshyol `42/42` bez novyikh preduprezhdenij.

## Prodolzheniye

`FUM-STEP-0005` zavershena na zaglushke. Rabochij nabor `master` sokhranyayet `FUM-STEP-0035` kak `blocked` s prezhnim usloviyem vozobnovleniya i vyibirayet `FUM-STEP-0001` yedinstvennyim novyim `ready`. Eto lokaljnyij determinirovannyij Swift-prototip iyerarkhii funkcij i dannyikh, kotoryij ne trebuyet seti, sekretov, vneshnego ili fizicheskogo dejstviya i ne nachinayet korobochnuyu stadiyu.

Otdeljnyimi budusjhimi proverkami ostayutsya conformance-profilj realjnoj lokaljnoj LLM, processnaya otmena i tajm-aut, yavnyiye parametryi generacii, polnaya identichnostj vesov i resheniye o novom tipe sobyitiya modeljnogo vyizova v trasse.

## Profilj vremeni vyipolneniya

| Stadiya                           | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                              |
| -------------------------------- | -----------: | --------------------------------------------------------------------------------------------------------------------------------------- |
| Registraciya i dopusk FIFO        |        0,5 s | Summa nablyudayemogo wall-clock oshibochnogo pervogo bootstrap-vyizova i tochnogo dokumentirovannogo `join`; dolgogo ozhidaniya ne byilo.        |
| Soderzhateljnaya rabota            | 33 min 0,4 s | Ot `admitted_at` do nachala itogovyikh celevyikh proverok; dva paketa read-only-analizov vyipolnyalisj paralleljno i otdeljno ne skladyivayutsya. |
| Itogovyiye celevyiye proverki        |  1 min 2,4 s | Monotonnyij interval predmetnyikh, CLI-, planovyikh i svyaznostnyikh proverok, vklyuchaya ispravleniye slishkom strogogo ozhidaniya podpisi paneli.    |
| Predfinaljnyij polnyij smoke-check | 2 min 39,0 s | Monotonnyij interval otdeljnogo polnogo progona `42/42` posle pervichnogo obnovleniya recency, grafa, zaprosa i zhurnala.                   |

Granica profilya: ot uspeshnogo FIFO-dopuska do zaversheniya predfinaljnogo polnogo smoke-check; ozhidaniye, soderzhateljnaya rabota, celevyiye proverki i finaljnaya peredacha razlichayutsya, neizvestnyiye dliteljnosti ne ocenivayutsya zadnim chislom.

## Zatronutyiye materialyi

- [kontrakt chistogo modeljnogo shaga](../../Dokumentaciya/41-kontrakt-chistogo-modeljnogo-shaga.md)
- [chistyij modeljnyij shag](../../Glossarij/chistyij-modeljnyij-shag.md)
- [Swift-prototip chistogo modeljnogo shaga](../../Prototipyi/chistyij-modeljnyij-shag/README.md)
- [MVP-kandidat ispolnyayemogo agentskogo cikla](../../Planirovaniye/MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [zavershyonnaya kartochka FUM-STEP-0005](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0005-proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [chastichno proyasnyonnyij vopros o razvilke giperseti i agentskogo cikla FUM](../../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md)
- [minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:bd4a5daa2cffd7a9d2c5568dcd143c5d9bd15a2b0ded1064578454d351868d12 -->
<!-- FUM-MD-RECENCY:END -->
