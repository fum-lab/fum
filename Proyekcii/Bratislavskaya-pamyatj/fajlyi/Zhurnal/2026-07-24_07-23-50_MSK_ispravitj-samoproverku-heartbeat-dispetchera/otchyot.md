# Otchyot 2026-07-24 07:23:50 MSK - Ispravitj samoproverku heartbeat dispetchera

Avtozapusk sleduyusjhego shaga vosstanovlen bez oslableniya proverki zanyatosti. Heartbeat boljshe ne trebuyet nevozmozhnogo sovpadeniya sobstvennogo runtime-statusa s `active`, no po-prezhnemu zakryivayet zapusk pri lyuboj drugoj nablyudayemoj aktivnoj zadache, neizvestnom sostoyanii ili nedostupnom host.

## Prichina i ispravleniye

Dva poslednikh tika zavershalisj do Git-proverki, `show`, claim i sozdaniya zadachi, potomu chto prikreplyonnaya dispetcherskaya zadacha nablyudalasj shtatnyim spiskom kak `idle`, a prompt treboval dlya sobstvennogo tochnogo identifikatora toljko `active`. Lokaljnyij rabochij nabor pri etom ostavalsya validnyim i soderzhal gotovyij `FUM-STEP-0007`.

Pervyij i povtornyij recent-snimki teperj trebuyut rovno odnu sobstvennuyu zapisj v lyubom izvestnom sostoyanii `active`, `idle` ili `notLoaded`. Posle etogo isklyuchayetsya toljko tochnoye sobstvennoye sovpadeniye; kazhdaya drugaya zapisj proveryayetsya na `active`. Eta formulirovka zakreplena v pravilakh repozitoriya, proizvodnoj dokumentacii, kontrakte navyika i vosproizvodimom heartbeat-shablone.

## Zhivaya avtomatizaciya

Susjhestvuyusjhaya heartbeat-avtomatizaciya obnovlena shtatnyim instrumentom bez sozdaniya dublya i bez ruchnogo redaktirovaniya lokaljnoj konfiguracii. Celevaya dispetcherskaya zadacha, pyatiminutnoye raspisaniye i status `ACTIVE` sokhranenyi; runtime prompt sinkhronizirovan s repozitornyim shablonom. Vo vremya obnovleniya tekusjhaya rabochaya zadacha sama schitalasj drugoj `active`-zadachej i ne pozvolyala dispetcheru sozdatj paralleljnyij shag.

## Proverki

- Krasnyij test snachala podtverdil oshibochnoye trebovaniye `status=active`, zatem otdeljnaya krasnaya faza obnaruzhila ostatochnuyu neodnoznachnostj vtorogo snimka.
- Posle ispravleniya celevoj regressionnyij test i polnyij avtonomnyij nabor iz `59` testov `fum-sleduyusjhij-shag-vetki` prokhodyat.
- Shtatnyij prosmotr zhivoj avtomatizacii podtverzhdayet sokhranyonnyiye identichnostj, raspisaniye i status pri novom prompt.
- Recency-metki, graf Obsidian, sessionnaya svyaznostj, `git diff --check` i povtornyij polnyij smoke-check prokhodyat vse `54` stadii. Pervyij identichnyij process zavershilsya, no vyizyivayusjhaya obolochka ne sokhranila yego itogovyij kod i khvost vyivoda; poetomu dlya dokazannogo rezuljtata vyipolnen vtoroj polnyij progon.

## Profilj vremeni vyipolneniya

| Stadiya                                 | Dliteljnostj | Granicyi i sposob izmereniya                                                                                                                                         |
| -------------------------------------- | -----------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Registraciya i dopusk FIFO              |        0,4 s | Odin shtatnyij `join` nemedlenno vernul `admitted`; neizmennogo ozhidaniya FIFO ne byilo.                                                                               |
| Soderzhateljnaya i TDD-rabota            |  ne izmereno | Ot dopuska do itogovyikh proverok; paralleljnyiye read-only-analizyi subagentov perekryivalisj s rabotoj i ne skladyivayutsya s obsjhim stenovyim vremenem.                    |
| Celevoj nabor sleduyusjhego shaga vetki    |      23,62 s | Stenovoye vremya polnogo avtonomnogo nabora iz `59` testov posle realizacii.                                                                                         |
| Obnovleniye i proverka zhivogo heartbeat |        0,3 s | Summarnoye nablyudayemoye stenovoye vremya shtatnyikh update, view i proverki sokhranyonnyikh polej.                                                                            |
| Predfinaljnyij polnyij smoke-check       |     234,86 s | Stenovoye vremya vtorogo dokazannogo polnogo progona; proshli vse `54` stadii. Pervyij rezuljtat obolochka ne sokhranila, poetomu on ne ispoljzuyetsya kak dokazateljstvo. |

Granica profilya: ot pervogo FIFO-vyizova do zaversheniya predfinaljnogo polnogo smoke-check; neizmennogo ozhidaniya FIFO ne byilo, paralleljnyiye stadii ne skladyivayutsya, neizmerennyiye intervalyi zadnim chislom ne ocenivayutsya. Finaljnyiye recency-pravki, staging i atomarnyij commit+handoff nakhodyatsya posle izmeryayemogo smoke-check.

## Zatronutyiye materialyi

- [pravila repozitoriya](../../AGENTS.md) i [dokumentaciya vosproizvodimyikh avtomatizacij](../../Dokumentaciya/17-vosproizvodimyiye-avtomatizacii.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md) i [heartbeat-shablon](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/references/heartbeat-prompt.md)
- [regressionnyiye testyi](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/tests/test_branch_next_step.py)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [predyidusjheye ispravleniye avtozapuska](../2026-07-23_09-36-31_MSK_ispravitj-avtozapusk-i-predotvratitj-povtor-oshibki/zapros.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:fdca5b5ac6179ae4ca953a206456fe65537155287b2fec7ee594baeb2722fb71 -->
<!-- FUM-MD-RECENCY:END -->
