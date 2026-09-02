# Atomarnoye prinyatiye snimka i proiskhozhdeniya istochnika

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0034 -->

Kanonicheskiye bajtyi novogo pokoleniya istochnika, tochnyij manifest, tekusjhij ukazatelj i obyazateljnaya zapisj proiskhozhdeniya dolzhnyi prinimatjsya odnoj lokaljnoj tranzakciyej. Do commit boundary istochnik ostayotsya kandidatom; posle commit on polnostjyu nablyudayem i idempotentno vosstanavlivayetsya po `operation_id`. Fajlovyiye predstavleniya vne tranzakcionnogo khranilisjha yavlyayutsya toljko vosstanavlivayemyimi proyekciyami i ne opredelyayut status prinyatiya.

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [bezopasnogo priyoma publichnogo HTML-URL](🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md) — uspeshnyij transport ne razreshayet chastichno prinyatj snimok.
- **trebuyetsya dlya:** [produktovogo proiskhozhdeniya prinyatogo istochnika](🟡-produktovoye-proiskhozhdeniye-prinyatogo-istochnika.md) — snimok i yego obyazateljnaya svyazj poluchayut odnu granicu vidimosti.

## Kriterii proverki

- odna ACID-tranzakciya vklyuchayet kanonicheskiye bajtyi ili content-addressed blobs, manifest, pokoleniye istochnika, tekusjhij ukazatelj, zapisj proiskhozhdeniya i zasjhitu unikaljnosti svyazi;
- oshibka do commit ostavlyayet prezhneye sostoyaniye pobajtno i logicheski neizmennyim, ne sozdayot prinyatogo pokoleniya, novoj svyazi ili vremennogo kanonicheskogo ostatka;
- avariya posle commit, no do otveta vosstanavlivayetsya kak prinyatyij rezuljtat togo zhe `operation_id`, a povtor ne sozdayot vtoruyu svyazj ili pokoleniye;
- failpoint-matrica pokryivayet pervoye sozdaniye i obnovleniye posle zapisi blobs, snimka, proiskhozhdeniya i ukazatelya, neposredstvenno do commit i srazu posle commit s perezapuskom novogo processa;
- kazhdaya tochka podtverzhdayet toljko odin iz dvukh iskhodov: polnostjyu prezhneye libo polnostjyu novoye proveryayemoye sostoyaniye; neopredelyonnaya ili chastichnaya vidimostj zapresjhena.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🟡`: tranzakcionnaya granica vyibrana i yeyo priyomka specificirovana, no produktovyij store i crash/restart-testyi yesjhyo ne realizovanyi. Atomarnaya zamena fajlov lokaljnogo arkhivatora i protokol pokolenij bezokonnoj pamyati ne dokazyivayut etu otdeljnuyu sovmestnuyu tranzakciyu URL-sreza.

## Istochniki trebovanij

- [iskhodnyij zapros tekusjhej sessii](../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [audit pasporta korobochnoj stadii](../Zhurnal/2026-07-22_02-25-23_MSK_provesti-audit-pasporta-korobochnoj-stadii/materialyi/revjyu/2026-07-22_02-25-23_MSK_audit-pasporta-korobochnoj-stadii.md)
- [pasport pervogo produktovogo URL-sreza](../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8197a5d8cab7da39f46e261d9c40e559fa16ceafd7a5772bc8456825174db7e9 -->
<!-- FUM-MD-RECENCY:END -->
