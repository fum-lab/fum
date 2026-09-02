# Produktovoye proiskhozhdeniye prinyatogo istochnika

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0033 -->

Prinyatyij produktovyim servisom istochnik dolzhen imetj minimaljnuyu mashinno chitayemuyu zapisj proiskhozhdeniya, svyazyivayusjhuyu iskhodnoye namereniye, pokazannyij i podtverzhdyonnyij plan, setevoye nablyudeniye, ochistku, izvlecheniye, manifest, tranzakciyu i itogovyij snimok. Etot uzkij sloj `P1` vkhodit v pervyij vertikaljnyij URL-srez i ne vyidayotsya za polnyij [reyestr proiskhozhdeniya FUM](../Glossarij/reyestr-proiskhozhdeniya-FUM.md) dlya vsekh uzlov i [peredavayemyikh rezuljtatov](../Glossarij/peredavayemyij-rezuljtat-FUM.md).

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [bezopasnogo priyoma publichnogo HTML-URL](🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md) — snimok bez obyazateljnoj svyazi s namereniyem ne yavlyayetsya prinyatyim istochnikom.
- **zavisit ot:** [atomarnogo prinyatiya snimka i proiskhozhdeniya istochnika](🟡-atomarnoye-prinyatiye-snimka-i-proiskhozhdeniya-istochnika.md) — zapisj proiskhozhdeniya i kanonicheskij snimok dolzhnyi stanovitjsya vidimyimi odnoj tranzakciyej.

## Kriterii proverki

- zapisj soderzhit versii kontrakta i politiki, `operation_id`, identichnostj istochnika i pokoleniya, ssyilku na namereniye, digest plana i podtverzhdeniya, fakticheskij konechnyij URL, setevyiye i preobrazovateljnyiye digest, manifest, tranzakciyu, status i nablyudayemuyu trassu;
- kazhdoye prinyatoye pokoleniye imeyet rovno odnu obyazateljnuyu tipizirovannuyu svyazj s iskhodnyim kontekstom, a idempotentnyij povtor ne sozdayot dublj;
- lokaljnyiye prava na chteniye konteksta i zapisj svyazi proveryayutsya do seti i povtorno pered commit boundary;
- query sokhranyayetsya toljko v zasjhisjhyonnoj lokaljnoj zapisi, putj i publichnoye predstavleniye ispoljzuyut khyeshirovannuyu identichnostj, a publikacionnaya proyekciya ne raskryivayet sekretopodobnyiye znacheniya;
- avtonomnaya sverka vosstanavlivayet cepochku ot namereniya do kazhdogo upravlyayemogo bajta snimka i otvergayet otsutstvuyusjhuyu, dubliruyusjhuyu ili nesovmestimuyu svyazj.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: minimaljnaya produktovaya skhema proiskhozhdeniya opredelena kak obyazateljnaya chastj URL-sreza, no sootvetstvuyusjhij servisnyij reyestr yesjhyo ne realizovan. Repozitornyiye ssyilki lokaljnogo arkhivatora ostayutsya iskhodnyim obrazcom, a ne produktovyim khranilisjhem `P1`.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej sessii](../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [audit pasporta korobochnoj stadii](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md)
- [pasport pervogo produktovogo URL-sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:605bdcef69415ca07203380677a53ea1284bf083fb2844a094dcfaf0e504a989 -->
<!-- FUM-MD-RECENCY:END -->
