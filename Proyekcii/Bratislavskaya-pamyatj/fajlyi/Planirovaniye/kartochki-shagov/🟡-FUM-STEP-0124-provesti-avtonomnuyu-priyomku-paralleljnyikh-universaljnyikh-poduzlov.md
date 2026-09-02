+++
schema_version = 1
card_id = "FUM-STEP-0124"
status = "active"
+++
# Provesti avtonomnuyu priyomku paralleljnyikh universaljnyikh poduzlov

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sobratj odin vosproizvodimyij scenarij s lokaljnyimi bare-repozitoriyami dlya polnogo upravlyayemogo kontura. Odin roditeljskij vetvevoj fork dolzhen ot proverennogo obsjhego iskhodnogo sostoyaniya poroditj dva dochernikh fork s raznyimi rolevyimi konechnyimi cepochkami, vyipolnitj ikh paralleljno na sovmestimyikh refs cherez avtonomnyij zamenitelj host, osvoboditj roditeljskoye vladeniye i vosstanovitj tot zhe fork kak moderatora dvukh zamorozhennyikh rezuljtatov. Moderator sravnivayet libo obyyedinyayet rezuljtatyi, posle chego kontur serializuyet konkuriruyusjhuyu celj, formiruyet tochnyiye konvertyi predlozhenij pull request, provodit otdeljnoye revjyu i prinimayet resheniye CAS-integraciyej. Odin sinteticheskij kandidat navyika prokhodit cherez yadro, sostoyaniye sinkhronizacii susjhestvuyusjhego fork i soglasovannoye obnovleniye core- i dochernego gitlink, posle chego svezhiye klonyi vosstanavlivayut tochnyiye snimki i upravlyayusjheye sostoyaniye.

## Pochemu sejchas

Otdeljnyiye mekhanizmyi ne dokazyivayut, chto delegaciya, cepochki, zasjhitnyiye host-privyazki, revjyu, integraciya i gitlink obrazuyut odin vosstanavlivayemyij protokol. Avtonomnaya priyomka nuzhna do sozdaniya realjnyikh vneshnikh fork i zadach Codex.

## Kriterii zaversheniya

- Dva poddeljnyikh universaljnyikh ispolnitelya zavershayut ne meneye chem po dva soderzhateljnyikh shaga v raznyikh klonakh i refs, a roditeljskij checkout ostayotsya neizmennyim do integracii.
- Oba rebyonka imeyut proverennoye obsjheye iskhodnoye sostoyaniye, raznyiye identichnosti fork, paryi repozitoriya i ref i checkout i po odnomu dopusjhennomu pisatelyu; chastichnyij ili neizvestnyij host-zapusk ne aktiviruyet pokoleniye, predaktivacionnyij barjyer ne dopuskayet ni odnogo rebyonka v FIFO, a ozhidayusjheye prodolzheniye ne uchityivayetsya kak vtoroj aktivnyij vladelec.
- Roditeljskaya host-sessiya osvobozhdayet FIFO posle razvilki, novaya ograzhdyonnaya sessiya togo zhe logicheskogo fork vosstanavlivayet moderatora iz pasporta i prinimayet resheniye po oboim neizmenyayemyim rezuljtatam bez zapisi v docherniye refs.
- Kontekstnyiye roli vliyayut na marshrutizaciyu, no ne na profilj polnomochij; khotya byi odin poddeljnyij agent poluchayet inoj rolevoj shag i prokhodit te zhe granicyi naznacheniya.
- Konkurentnyiye naznacheniya odnoj celi ne poluchayut dvukh vladeljcev; sovmestimyiye naznacheniya dejstviteljno perekryivayutsya po nablyudayemomu vremeni libo barjyeru scenariya.
- Otdeljnyij proveryayusjhij vyidayot prinyatiye i dorabotku dlya tochnyikh vershin; integrator prinimayet toljko podtverzhdyonnyij diapazon i obnovlyayet gitlink otdeljnyim CAS-perekhodom.
- Avtonomnyij konvert predlozheniya pull request zakreplyayet tochnyiye base/head, polnyij diapazon, rolj i manifest sinteticheskoj fiksturyi peredachi; dvizheniye base ili head annuliruyet revjyu, prinyatyij artefakt poyavlyayetsya v kornevom pokolenii, a novyij avtonomnyij agent nasleduyet imenno etot commit. Scenarij dokazyivayet transport sinteticheskogo artefakta, no ne realjnyij host-kontur, poleznostj navyika i ne povyishayet poiskovyij pasport `fum-optimizator` do realizacii.
- Posle prinyatiya sinteticheskogo navyika avtonomnyij susjhestvuyusjhij fork prokhodit sostoyaniye `принято_в_ядре_синхронизация_ребёнка_ожидается`, sinkhroniziruyet zerkaljnyij `master`, sozdayot proverennyij dochernij commit i odnim assembly-CAS obnovlyayet core-gitlink vmeste s dochernim gitlink; dochernij gitlink ne raven PR-head i yavlyayetsya potomkom prinyatogo core OID.
- Inyyekcii sboyev i poteryannyikh otvetov na granicakh zapuska, shaga, sozdaniya i readback predlozheniya pull request, revjyu, integracii, sinkhronizacii fork i gitlink ne ostavlyayut neuchtyonnogo promezhutochnogo sostoyaniya. Pri uspekhe CAS celevogo ref integracii i nezavershyonnom sleduyusjhem perekhode scenarij fiksiruyet otdeljnoye vozobnovlyayemoye sostoyaniye i dopuskayet tochnyij povtor bez otkata prinyatogo commit.
- Povtor polnogo scenariya dayot kanonicheski ekvivalentnyiye pasporta, diagnostiki i itogovyiye derevjya; svezhiye klonyi vosstanavlivayut toljko prinyatyiye detached-snimki i sobstvennyiye ocheredi.
- Scenarij ne ispoljzuyet setj, zhivuyu modelj, sekretyi, vneshnij push ili realjnyiye host-zadachi i pryamo sokhranyayet etu dokazateljnuyu granicu.

## Istochniki

- [iskhodnyij zapros 2026-08-12 03:09:35 MSK — Smodelirovatj vetvleniye FUM derevom forkov](../../Zhurnal/2026-08-12_03-09-35_MSK_smodelirovatj-vetvleniye-FUM-derevom-forkov/zapros.md)
- [iskhodnyij zapros 2026-08-06 17:38:49 MSK — Sozdatj dochernikh fork-agentov FUM](../../Zhurnal/2026-08-06_17-38-49_MSK_sozdatj-docherniye-fork-agentyi-FUM/zapros.md)
- [iskhodnyij zapros 2026-08-05 15:49:53 MSK — Upravlyatj universaljnyimi pishusjhimi poduzlami](../../Zhurnal/2026-08-05_15-49-53_MSK_upravlyatj-universaljnyimi-pishusjhimi-poduzlami/zapros.md)
- [trebovaniye ob upravlyayemom ispolnenii cepochek universaljnyimi fork-poduzlami](../../Trebovaniya/🟡-upravlyayemoye-ispolneniye-cepochek-universaljnyimi-fork-poduzlami.md)
- [FUM-STEP-0123 — kornevoye revjyu i integraciya cepochki](✅-FUM-STEP-0123-dobavitj-kornevoye-revjyu-i-CAS-integraciyu-cepochki.md)
- [FUM-STEP-0090 — prezhnyaya priyomka repozitornoj kompozicii](✅-FUM-STEP-0090-provesti-avtonomnuyu-skvoznuyu-priyomku-repozitornoj-kompozicii.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-13 15:44:23 MSK -->
<!-- content-sha256: sha256:90423b1cfa49b2892ff4820ca020ba86bbd13e21f99ccf808c842bb0829ea728 -->
<!-- FUM-MD-RECENCY:END -->
