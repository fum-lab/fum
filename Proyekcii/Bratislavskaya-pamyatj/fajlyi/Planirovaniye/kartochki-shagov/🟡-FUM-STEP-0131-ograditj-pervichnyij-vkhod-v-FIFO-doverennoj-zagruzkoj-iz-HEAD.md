+++
schema_version = 1
card_id = "FUM-STEP-0131"
status = "active"
+++
# Ograditj pervichnyij vkhod v FIFO doverennoj zagruzkoj iz HEAD

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Dobavitj doverennuyu host- ili orkestracionnuyu tochku pervichnogo vkhoda obyichnoj kornevoj zadachi v FIFO. Do dostupnogo modeli mutiruyusjhego puti ona dolzhna poluchitj tochnyij `CODEX_THREAD_ID`, zagruzitj avtomatizaciyu ocheredi iz tochnogo tekusjhego `HEAD`, idempotentno vyipolnitj `join` i vernutj svyazannyij bilet; pryamoj scenarij rabochego dereva v obyichnom rezhime dolzhen zakryito otvergatjsya.

## Pochemu sejchas

V nachale rabochej sessii FUM-SBOJ-0003 agent snachala ugadal nesusjhestvuyusjhij putj ocheredi, a zatem zaregistriroval bilet pryamyim scenariyem chistogo rabochego dereva vmesto obyazateljnogo HEAD-bootstrap. Bilet i FIFO-poryadok ne povredilisj, no primenimaya zasjhita zavisela ot sluchajnogo sovpadeniya checkout s `HEAD`. Tekstovyij zapret ne ograzhdayet imenno tot pervyij instrumentaljnyij khod, kotoryij dolzhen ustanovitj pravo daljnejshej zapisi.

## Kriterii zaversheniya

- Krasnaya integracionnaya fikstura vosproizvodit pryamoj `join` iz rabochego dereva do dopuska i pokazyivayet, chto dejstvuyusjhij kooperativnyij kontrakt ne meshayet etomu vyizovu izmenitj ocheredj. Otkaz ugadannogo nesusjhestvuyusjhego puti ostayotsya kontekstom proyavleniya, no ne podmenyayet proveryayemuyu opasnuyu granicu.
- Doverennaya tochka vkhoda zapuskayetsya do dostupnogo modeli mutiruyusjhego puti, poluchayet kornevoj `CODEX_THREAD_ID` neposredstvenno iz sredyi i zagruzhayet avtomatizaciyu ocheredi toljko iz tochnogo `HEAD` izolirovannyim sposobom.
- Uspekh vozvrasjhayet tochnyiye `task_id`, `ticket_id`, `seq`, sostoyaniye i pri nalichii `generation`; poterya otveta ili vosstanovleniye konteksta idempotentno nakhodit tot zhe bilet bez povtornoj pozicii.
- Pryamoj scenarij rabochego dereva zakryito otvergayet obyichnyij proizvodstvennyij `join`, vklyuchaya chistyij checkout. Avtonomnyiye testyi razrabotki sokhranyayut otdeljnyij yavnyij rezhim, kotoryij neljzya sluchajno unasledovatj obyichnoj zadachej.
- Gryaznyij checkout s izmenyonnyim scenariyem ocheredi ne vliyayet na bajtyi pervichnogo `join`, bilet, branch ref ili FIFO-poryadok.
- Poddeljnyij, pustoj ili vruchnuyu perenesyonnyij vmesto sredyi `task_id`, otsutstvuyusjhij `HEAD`, nevernyij korenj i nedoverennyij bootstrap dayut otkaz do izmeneniya sluzhebnoj Git-ssyilki.
- Avtonomnyij poddeljnyij host bez seti i sekretov pokryivayet chistyij i gryaznyij checkout, poteryu otveta, povtor, otkaz rabochego scenariya i gonku dvukh pervyikh zadach.
- Zhivaya priyomka dvukh kornevyikh zadach podtverzhdayet vozrastayusjhiye `seq`, ozhidaniye vtoroj zadachi i shtatnuyu peredachu bez pryamogo vyizova rabochego dereva modeljyu.
- `AGENTS.md`, navyik ocheredi i arkhitekturnyiye dokumentyi opisyivayut odnu fakticheskuyu tochku pervogo vkhoda; primenimyiye testyi i obsjhij smoke-check prokhodyat.

## Istochniki

- [FUM-SBOJ-0003 — Obkhod HEAD-bootstrap pri pervichnom vkhode v FIFO](../../Sboi/FUM-SBOJ-0003-obkhod-HEAD-bootstrap-pri-pervichnom-vkhode-v-FIFO.md) — osnovaniye `FUM-СБОЙ-0003/ПРОЯВЛЕНИЕ-0001`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [ocheredj zadach Git-vetki](../../Instrumentyi/fum-ocheredj-zadach-git-vetki/SKILL.md)
- [pravila rabochikh sessij](../../AGENTS.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-06 23:00:56 MSK -->
<!-- content-sha256: sha256:51db7e703bd55da751f55d3be5428c2c6eb220b738fea9b78851ef04f1256d3e -->
<!-- FUM-MD-RECENCY:END -->
