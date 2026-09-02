+++
schema_version = 1
card_id = "FUM-STEP-0105"
status = "active"
+++
# Realizovatj avtonomnoye yadro pervogo produktovogo URL-sreza

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Realizovatj pervoye bezokonnoye lokaljnoye yadro produktovogo URL-sreza po kontraktu `fum.source-ingest.v1`: strogo prinimatj pyatj tipov soobsjhenij `prepare_request`, `prepared_plan`, `confirmation`, `execute_request` i `execution_result` cherez entrypoint `prepare`, `show-plan`, `confirm`, `execute` i `status`, proveritj odnorazovoye podtverzhdeniye, prognatj fazovuyu setevuyu politiku na vnedryayemom determinirovannom transporte i atomarno prinyatj snimok s obyazateljnyim proiskhozhdeniyem. Zhivoj setevoj adapter, GUI, publikaciya i vneshniye servisyi v shag ne vkhodyat.

## Pochemu sejchas

Pasport, mashinnaya skhema i atomarnyiye trebovaniya delayut avtonomnoye yadro sleduyusjhej proveryayemoj granicej. Odnako tekusjhij zapros razreshayet toljko dorabotku dokumentaljnogo kontrakta i povtornyij audit. Do otdeljnogo yavnogo razresheniya kartochka ostayotsya zablokirovannoj i ne dayot prava na setj ili na produktovuyu mutaciyu.

## Kriterii zaversheniya

- Realizaciya prinimayet toljko strogiye soobsjheniya versii `fum.source-ingest.v1`, otklonyayet neizvestnyiye polya i nesovmestimyiye versii i imeyet avtonomnuyu conformance-matricu.
- `prepare → show plan → confirm → execute` svyazyivayet odnorazovyiye plan digest i nonce s URL, oblastjyu zapisi, iskhodnyim kontekstom, pravami i versiyej politiki; podmena, istecheniye i povtor otklonyayutsya do transporta i zapisi.
- Fiksturnyij transport razdeljno modeliruyet DNS-otvetyi, fakticheskij peer, TLS-imya, redirect-hop, zagolovki i potok tela; otricateljnyiye fiksturyi dokazyivayut fail-closed bez zhivoj seti.
- Odna lokaljnaya ACID-tranzakciya prinimayet kanonicheskiye bajtyi, manifest, pokoleniye, tekusjhij ukazatelj i obyazateljnoye proiskhozhdeniye; pervoye sozdaniye i obnovleniye prokhodyat failpoint- i restart-matricu.
- Povtor togo zhe `operation_id` posle poteri otveta vozvrasjhayet tot zhe prinyatyij rezuljtat bez vtorogo pokoleniya ili svyazi; proyekcii vosstanavlivayutsya iz tranzakcionnogo sostoyaniya.
- Avtonomnyiye testyi i otchyot otdelyayut dokazannoye fiksturnoye yadro ot nerealizovannyikh zhivogo setevogo adaptera, upakovki, GUI i polnoj korobochnoj stadii.

## Istochniki

- [iskhodnyij zapros tekusjhej sessii](../../Zhurnal/2026-07-28_20-06-05_MSK_dorabotatj-pasport-korobochnoj-stadii-i-pervogo-URL-sreza-po-auditu/zapros.md)
- [pasport pervogo produktovogo URL-sreza](../../Dokumentaciya/36-pasport-dokumentacionnogo-prototipa-i-pervogo-korobochnogo-sreza.md)
- [bezopasnyij priyom publichnogo HTML-URL](../../Trebovaniya/🟡-bezopasnyij-priyom-publichnogo-HTML-URL.md)
- [privyazannoye podtverzhdeniye i minimaljnyiye prava priyoma istochnika](../../Trebovaniya/🟡-privyazannoye-podtverzhdeniye-i-minimaljnyiye-prava-priyoma-istochnika.md)
- [produktovoye proiskhozhdeniye prinyatogo istochnika](../../Trebovaniya/🟡-produktovoye-proiskhozhdeniye-prinyatogo-istochnika.md)
- [atomarnoye prinyatiye snimka i proiskhozhdeniya istochnika](../../Trebovaniya/🟡-atomarnoye-prinyatiye-snimka-i-proiskhozhdeniya-istochnika.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8d7ae70bda3cccc318e501883f65f12f5c4e186f5cac6ac984cbe9a663825b63 -->
<!-- FUM-MD-RECENCY:END -->
