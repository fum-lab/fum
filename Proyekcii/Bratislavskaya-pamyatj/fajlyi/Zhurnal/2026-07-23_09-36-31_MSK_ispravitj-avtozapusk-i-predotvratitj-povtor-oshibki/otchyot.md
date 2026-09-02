# Otchyot 2026-07-23 09:36:31 MSK - Ispravitj avtozapusk i predotvratitj povtor oshibki

Avtozapusk sleduyusjhego shaga vosstanovlen bez TTL, ruchnogo redaktirovaniya sluzhebnoj Git-ssyilki i oslableniya zasjhityi ot dublej. Poteryannyij otvet `claim` teperj vosstanavlivayetsya kak tochnyij idempotentnyij povtor sobstvennoj logicheskoj popyitki.

## Ispravleniye

Heartbeat zaraneye sozdayot kanonicheskij UUID i peredayot yego v obyazateljnyij `--lease-id`. Pervyij uspeshnyij compare-and-swap vozvrasjhayet `ownership=new`; povtor toj zhe popyitki posle poteri otveta vozvrasjhayet `ownership=existing`. Drugoj UUID vidit toljko `already_claimed`, ne poluchayet chuzhoj lease i ne mozhet prisvoitj shag. Povtor UUID dlya novogo `step_id` otklonyayetsya.

Potencialjno dolgiye `list_threads` i `list_projects` perenesenyi do claim. Posle rezervacii ostayutsya toljko lokaljnaya podgotovka uzhe proverennogo dochernego prompta i `create_thread`. Tochnyij povtor claim razreshyon lishj do pervogo vyizova sozdaniya; posle nego neodnoznachnyij rezuljtat sokhranyayet claim dlya vneshne podtverzhdyonnogo fenced-vosstanovleniya.

## Vosstanovleniye tekusjhego zapuska

Dejstvuyusjhaya heartbeat-avtomatizaciya vremenno postavlena na pauzu, obnovlena iz repozitornogo shablona i proverena bez smenyi celevoj zadachi ili pyatiminutnogo raspisaniya. Svezhij recent-snimok, tochechnyij poisk po pokoleniyu i zagolovku, istoriya dispetchera i FIFO podtverdili otsutstviye zadachi, sposobnoj prodolzhitj prezhnij zapusk. Staryij claim snyat tochnyim compare-and-delete po sokhranyonnyim `branch_ref` i `lease_id`, posle chego ta zhe avtomatizaciya vozvrasjhena v `ACTIVE`.

Gotovyij produktovyij shag ne podmenyalsya sluzhebnyim ispravleniyem: `FUM-STEP-0024` ostayotsya `ready`, `FUM-STEP-0035` ostayotsya `blocked`, a vyipolnennaya sluzhebnaya kartochka `FUM-STEP-0071` perevedena v istoricheskij status.

## Proverki

TDD-nabor sleduyusjhego shaga pokryivayet poteryu otveta, tochnyij povtor, konkuriruyusjhiye UUID, mezhpokolennyij zapret vnutri vetki, otsutstviye chuzhogo lease i poryadok obeikh host-inventarizacij do claim. Planovyij reyestr, recency-metki, graf Obsidian, svyaznostj sessii i polnyij smoke-check podtverzhdayut soglasovannostj lokaljnogo kontrakta; zhivoj prosmotr heartbeat i `claim-status` podtverzhdayut vneshneye vosstanovleniye.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [diagnostika zavisshej rezervacii](../2026-07-22_17-05-06_MSK_diagnostirovatj-zavisshuyu-rezervaciyu-avtozapuska/otchyot.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:23e7ed9209e72321492608f0f9cdf302e4e4826035650be9d5d69640ef1be769 -->
<!-- FUM-MD-RECENCY:END -->
