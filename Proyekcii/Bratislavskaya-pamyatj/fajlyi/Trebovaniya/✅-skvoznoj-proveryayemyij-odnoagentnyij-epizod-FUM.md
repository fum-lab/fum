# Skvoznoj proveryayemyij odnoagentnyij epizod FUM

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0029 -->

FUM dolzhen vyipolnitj kak minimum odin skvoznoj bezokonnyij odnoagentnyij epizod v sobstvennom runtime: ot vneshnej zadachi i realjnogo modeljnogo vyizova cherez ogranichennyiye instrumentyi, proverki i kandidatnyij kommit do otdeljnoj priyomki, ostanovki i vozobnovleniya posle prinuditeljnogo preryivaniya. Vneshnyaya sessiya Codex mozhet zapuskatj i ispyityivatj kontur, no yeyo skryitaya istoriya ne stanovitsya pamyatjyu ili runtime FUM.

## Semanticheskiye svyazi

- **zavisit ot:** [vosproizvodimogo shtatnogo popolneniya pamyati](🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md) — sostoyaniye cikla dolzhno byitj samodostatochno vosproizvodimyim i vosstanavlivayemyim.
- **zavisit ot:** [kontekstno posiljnyikh ispolnyayemyikh shagov](🚧-kontekstno-posiljnyiye-ispolnyayemyiye-shagi.md) — epizod dolzhen prokhoditj cherez konechnyiye rabochiye paketyi i nablyudayemyiye peredachi.
- **usilivayetsya:** [avtonomnyim modeljnyim prodolzheniyem pri ozhidanii podtverzhdeniya](🟡-avtonomnoye-modeljnoye-prodolzheniye-pri-ozhidanii-podtverzhdeniya.md) — vneshnij effekt mozhet ozhidatj otveta nezavisimo ot prodolzhayusjhejsya modeljnoj chasti togo zhe epizoda.
- **dopolnyayet:** [proveryayemyij mnogoagentnyij kontur FUM](🚧-proveryayemyij-mnogoagentnyij-kontur-FUM.md) — snachala dokazyivayetsya odin polnyij cikl, posle chego otdeljnyiye roli mogut izmerimo yego usilitj.
- **trebuyetsya dlya:** [sravniteljnoj eksperimentaljnoj priyomki preimusjhestv FUM](🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md) — izmerimoye sravneniye trebuyet zavershyonnogo bazovogo kontura.

## Kriterii proverki

- vneshnyaya zadacha, tochnaya identichnostj modeljnogo adaptera, kontekst, byudzhetyi, parametryi i razreshyonnyiye instrumentyi vkhodyat v versionnyij pasport epizoda;
- dejstviya ogranichenyi allowlist i izolirovannoj rabochej sredoj; modeljnyij tekst sam ne poluchayet prava na ispolneniye;
- vkhodyi, modeljnyiye otvetyi, dejstviya, rezuljtatyi instrumentov, resheniya, otkazyi, proverki i podtverzhdeniya sokhranyayutsya kak kanonicheskiye sobyitiya s proiskhozhdeniyem;
- cikl sozdayot kandidatnyij kommit, ne publikuyet yego kak prinyatuyu istinu i peredayot na otdeljnuyu mashinnuyu proverku i yavnoye podtverzhdeniye ili otkloneniye;
- posle prinuditeljnogo preryivaniya novyij process vozobnovlyayet rabotu iz poslednego podtverzhdyonnogo pokoleniya bez prezhnego chata i zavershayet zaraneye ogranichennuyu postavku;
- prinyatoye sostoyaniye povtorno vyivoditsya v rezhime [vosproizvedeniya prinyatogo epizoda FUM](../Glossarij/vosproizvedeniye-prinyatogo-epizoda-FUM.md), a novyij zhivoj modeljnyij progon sozdayot otdeljnyij epizod i ne obyazan davatj te zhe bajtyi;
- bezokonnyiye interfejsyi dayut ekvivalentyi zapuska, osmotra, statusa, vozobnovleniya, vosproizvedeniya i priyomki bez obyazateljnoj privyazki k konkretnyim imenam komand.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: odin zaraneye zaregistrirovannyij sinteticheskij scenarij zamknut sobstvennyim runtime i podtverzhdyon avtonomnyim recorded-harness i otdeljnyim opt-in zhivyim progonom. Proverka okhvatyivayet tochnyij execution-passport, dva model-only-varianta, konechnyij byudzhet bez tretjyego vyizova, izolirovannyij Git-kandidat, nezavisimuyu priyomku, dva fakticheskikh `SIGKILL`, prodolzheniye novyimi PID iz `CURRENT` i no-effect replay.

Podtverzhdeniye otnositsya toljko k etomu odnomu scenariyu. Ono ne naznachayet novyij produktovyij MVP, versiyu `0.1` ili vneshnyuyu publikaciyu, ne dokazyivayet universaljnyij libo raspredelyonnyij FUM, proizvoljnyiye zadachi i dejstviya, zhivoj poljzovateljskij kanal podtverzhdeniya, power-loss durability ili preimusjhestvo nad kontroljnyim agentom.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-01 19:37:43 MSK — Zamknutj vozobnovleniye i zhivuyu priyomku odnoagentnogo epizoda](../Zhurnal/2026-08-01_19-37-43_MSK_zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda/zapros.md)
- [otchyot zhivogo progona odnoagentnogo epizoda](../Prototipyi/zhivoj-odnoagentnyij-epizod/Otchyotyi/2026-08-01_19-37-43_MSK_zhivoj-progon-odnoagentnogo-epizoda.md)
- [zavershyonnaya kartochka FUM-STEP-0112](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [iskhodnyij zapros 2026-07-27 20:45:59 MSK — Integrirovatj kriticheskij analiz i prioritetyi razvitiya FUM](../Zhurnal/2026-07-27_20-45-59_MSK_integrirovatj-kriticheskij-analiz-i-prioritetyi-razvitiya-FUM/zapros.md)
- [proveryayemaya vosproizvodimostj i eksperimentaljnaya priyomka FUM](../Dokumentaciya/46-proveryayemaya-vosproizvodimostj-i-eksperimentaljnaya-priyomka-FUM.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:21de4d6c880fed21522e531bc3fb73f67ac7566ce2e2c7da428fb17a0ffd0a80 -->
<!-- FUM-MD-RECENCY:END -->
