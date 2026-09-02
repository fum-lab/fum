# Privyazannoye podtverzhdeniye i minimaljnyiye prava priyoma istochnika

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0032 -->

Poljzovateljskoye podtverzhdeniye priyoma istochnika dolzhno otnositjsya k odnomu pokazannomu planu i ne perenositjsya na drugoj URL, oblastj zapisi, kontekst proiskhozhdeniya, nabor prav ili versiyu politiki. Kontur `prepare → show plan → confirm → execute` do seti svyazyivayet odnorazovyiye `plan_id`, nonce i SHA-256 kanonicheskogo plana, a ispolneniye poluchayet toljko pravo prochitatj odin publichnyij URL, zapisatj odnu oblastj istochnikov i sozdatj odnu tipizirovannuyu svyazj.

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [bezopasnogo priyoma publichnogo HTML-URL](🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md) — setevoye dejstviye ne nachinayetsya po obsjhemu ili ustarevshemu soglasiyu.

## Kriterii proverki

- `prepare` ne ispoljzuyet DNS ili transport i pokazyivayet normalizovannyij URL, identichnostj istochnika, celevuyu oblastj, kontekst proiskhozhdeniya, tochnyiye prava, limityi i versiyu politiki;
- digest vyichislyayetsya po kanonicheskomu planu vmeste s nonce, a `confirm` i `execute` trebuyut tochnogo sovpadeniya `operation_id`, `plan_id`, digest, nonce i yesjhyo dejstvuyusjhej versii politiki;
- podtverzhdeniye odnorazovo i imeyet konechnyij srok; povtor, istecheniye, izmeneniye plana, politiki, prav ili celi otklonyayutsya do seti i zapisi;
- servis ne poluchayet cookies, tokenyi, proizvoljnoye chteniye fajlov, ispolneniye otveta, Git-kommit, publikaciyu ili dostup za predelami vyidelennoj oblasti;
- avtonomnyiye testyi razlichayut otsutstviye podtverzhdeniya, podmenu kazhdogo svyazannogo polya, povtor nonce, nedostatochnyiye lokaljnyiye prava i nesovmestimuyu versiyu bez pobochnyikh effektov.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: versionirovannaya granica podtverzhdeniya opredelena, no produktovyij mekhanizm khraneniya i potrebleniya odnorazovyikh podtverzhdenij yesjhyo ne realizovan. Razresheniye bezokonnogo inzhenernogo Swift-prototipa ne yavlyayetsya podtverzhdeniyem setevogo plana.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej sessii](../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [audit pasporta korobochnoj stadii](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md)
- [pasport pervogo produktovogo URL-sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:93d5c828791a52c1bd0f1401e70561e71c413119c8d38829442f9715b46c9861 -->
<!-- FUM-MD-RECENCY:END -->
