+++
schema_version = 1
card_id = "FUM-STEP-0071"
status = "completed"
+++
# Vosstanovitj avtozapusk posle neodnoznachnogo rezuljtata rezervacii

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Cherez TDD sdelatj heartbeat-dispetcher ustojchivyim k potere otveta mutiruyusjhego `claim`: dobavitj idempotentnoye fenced-vosstanovleniye sobstvennoj popyitki, kotoroye libo bezopasno prodolzhayet sozdaniye zadachi, libo ostanavlivayetsya bez dublya i bez snyatiya chuzhogo pokoleniya.

## Rezuljtat

Cherez TDD vvedyon kliyentskij `lease_id`: heartbeat sozdayot svezhij kanonicheskij UUID do claim, a tochnyij povtor toj zhe paryi `branch_ref` i `step_id` s tem zhe UUID idempotentno podtverzhdayet sobstvennuyu popyitku posle poteryannogo otveta. Drugoj UUID poluchayet `already_claimed` bez raskryitiya chuzhogo lease, a v predelakh odnoj vetki prezhnij UUID neljzya pereispoljzovatj dlya novogo pokoleniya.

Oba recent-snimka i poisk sokhranyonnogo proyekta perenesenyi do claim, poetomu zavisaniye dolgogo read-only host-vyizova boljshe ne ostavlyayet rezervaciyu. Povtor claim razreshyon toljko do pervogo `create_thread`; neodnoznachnyij rezuljtat sozdaniya po-prezhnemu sokhranyayet bessrochnyij claim i trebuyet vneshne podtverzhdyonnogo fenced-vosstanovleniya bez TTL i bez ruchnogo izmeneniya Git-ssyilki.

Shablon heartbeat, lokaljnyij kontrakt, aktivnaya avtomatizaciya i avtonomnyiye testyi soglasovanyi. Prezhnyaya zavisshaya rezervaciya `FUM-STEP-0024` snyata tochnyim compare-and-delete posle povtornogo podtverzhdeniya otsutstviya sozdannoj zadachi; sleduyusjhij planovyij tik mozhet zanovo projti polnyij fail-closed-protokol.

## Istochniki

- [iskhodnyij zapros ob ispravlenii](../../Zhurnal/2026-07-23_09-36-31_MSK_ispravitj-avtozapusk-i-predotvratitj-povtor-oshibki/zapros.md)
- [iskhodnyij zapros o diagnostike](../../Zhurnal/2026-07-22_17-05-06_MSK_diagnostirovatj-zavisshuyu-rezervaciyu-avtozapuska/zapros.md)
- [zhurnal diagnostiki](../../Zhurnal/2026-07-22_17-05-06_MSK_diagnostirovatj-zavisshuyu-rezervaciyu-avtozapuska/otchyot.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [iskhodnyij zapros o zapuske sleduyusjhikh shagov vetok](../../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:dc3d796b2ee41739eccf68545028486510365c591ef5779423fc38ebb937f931 -->
<!-- FUM-MD-RECENCY:END -->
