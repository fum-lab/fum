# Otchyot 2026-07-22 17:05:06 MSK - Diagnostirovatj zavisshuyu rezervaciyu avtozapuska

Avtozapusk ne ostanovlen i ne poteryal gotovyij shag. Yego blokiruyet sokhranyonnaya fenced-rezervaciya, voznikshaya posle poteri odnoznachnogo rezuljtata mutiruyusjhego `claim` do sozdaniya obyichnoj zadachi.

## Diagnoz

Heartbeat imeyet sostoyaniye `ACTIVE` i zapuskayetsya raz v pyatj minut. Rabochaya kopiya chista, vetochnyij kontrakt validen, a `FUM-STEP-0024` dostupen kak yedinstvennyij `ready`-kandidat. Dlya togo zhe pokoleniya uzhe susjhestvuyet claim bez TTL, poetomu kazhdyij sleduyusjhij tik poluchayet `already_claimed` i zavershayetsya do `create_thread`.

Istoriya dispetchera svyazyivayet poyavleniye claim s tikom 2026-07-22 15:29:54 MSK. Tik proshyol proverku nablyudayemogo prostoya, Git i `show`, nachal fenced claim, zatem perezhil svyortku konteksta i zavershilsya soobsjheniyem o neodnoznachnom rezuljtate bez sozdannoj zadachi. Pozdnejshiye tiki pryamo soobsjhayut, chto shag uzhe zarezervirovan. Poisk tochnogo shaga v zadachakh i FIFO ne nashyol zapuska, sposobnogo prodolzhitj rabotu.

## Granica vosstanovleniya

Claim ne snimalsya. Bessrochnaya rezervaciya zasjhisjhayet ot dublya pri dejstviteljno neodnoznachnom `create_thread`, poetomu avtomaticheskoye istecheniye zdesj byilo byi nebezopasno. Nablyudayemoye otsutstviye sozdannoj zadachi delayet otdeljnoye fenced-vosstanovleniye obosnovannyim, no izmeneniye vneshnego sostoyaniya ostavleno do yavnoj prosjbyi poljzovatelya.

Aktivnostj samoj diagnosticheskoj zadachi takzhe zakryivayet tekusjhiye heartbeat-tiki po pravilu prostoya. Posle zaversheniya etoj sessii etot vremennyij faktor ischeznet, a sokhranyonnyij claim ostanetsya do otdeljnogo vosstanovleniya ili smenyi `step_id`.

## Prodolzheniye

Dobavlena kartochka `FUM-STEP-0071` dlya idempotentnogo vosstanovleniya sobstvennogo pokoleniya posle poteri otveta `claim`. Ona trebuyet testov poteryannogo otveta, konkuriruyusjhikh tikov i sokhraneniya zasjhityi ot dublej. Tekusjhij rabochij nabor vetki ne menyayetsya: produktovyij shag `FUM-STEP-0024` ostayotsya `ready`, a `FUM-STEP-0035` — `blocked` s prezhnim usloviyem vozobnovleniya.

## Proverki

Lokaljnyiye `validate`, `show` i `claim-status` podtverdili validnyij ready-shag i sovpadayusjhuyu rezervaciyu. Istoriya heartbeat, tochechnyij poisk zadach i FIFO-sostoyaniye podtverdili otsutstviye sozdannogo rabochego bileta posle problemnogo tika. Proizvodnyiye indeksyi, planovyij reyestr, svyaznostj i `git diff --check` proshli; obsjhij smoke-check zavershil `39/39` shagov.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [kontrakt sleduyusjhego shaga vetki](../../Instrumentyi/fum-sleduyusjhij-shag-vetki/SKILL.md)
- [iskhodnyij zapros o zapuske sleduyusjhikh shagov vetok](../2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:d8440bbc3c933714dcf4e4c53e3a1a895c9bd503621d5c4f2716f4611151c416 -->
<!-- FUM-MD-RECENCY:END -->
