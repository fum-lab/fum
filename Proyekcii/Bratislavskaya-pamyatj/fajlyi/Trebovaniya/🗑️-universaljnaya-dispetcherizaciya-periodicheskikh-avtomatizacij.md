# Universaljnaya dispetcherizaciya periodicheskikh avtomatizacij

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0028 -->

Trebovaniye snyato. Pyatiminutnyij heartbeat, postoyannaya prikreplyonnaya zadacha, obsjhij reyestr zadanij, dispetcherskiye rezervacii, vosstanoviteljnyiye soobsjheniya, schyotnaya analitika i upravleniye cherez `Stop`/`Start` boljshe ne yavlyayutsya tekusjhej arkhitekturoj FUM.

Ikh zamenyayet [obyazateljnoye prodolzheniye Git-vetki posle kommita](✅-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md): zavershayusjhayasya zadacha zaraneye sozdayot odnogo rebyonka v tom zhe lokaljnom proyekte, podtverzhdayet yego ozhidayusjhij FIFO-bilet na polnom ref vetki i toljko zatem vyipolnyayet atomarnyij `commit+handoff`. Istoricheskiye realizacii, testyi i dokumentyi dispetchera sokhranyayut proiskhozhdeniye reshenij, no ne dayut novyim zadacham polnomochij i ne schitayutsya aktivnyim marshrutom.

## Osnovaniye snyatiya

Periodicheskij opros host okazalsya lishnim urovnem upravleniya mezhdu posledovateljnyimi kommitami odnoj Git-vetki. Pryamaya peredacha prodolzheniyu svyazyivayet zapusk s fakticheskim terminaljnyim sobyitiyem — podtverzhdyonnyim kommitom — i isklyuchayet otdeljnyiye ponyatiya prostoya, tika, occurrence, obsjhego job registry i adapternogo claim.

Tekusjhaya host-poverkhnostj ne predostavlyayet idempotentnyij klyuch sozdaniya zadachi ili tranzakciyu s Git. Poetomu novyij protokol sozdayot rebyonka do kommita i zapresjhayet kommit pri neodnoznachnom rezuljtate; on ne obesjhayet bezuslovnuyu zhivuchestj posle lyubogo padeniya.

## Semanticheskiye svyazi

- **dopolnyayetsya:** [obyazateljnyim prodolzheniyem Git-vetki posle kommita](✅-obyazateljnoye-prodolzheniye-Git-vetki-posle-kommita.md) — novaya kartochka zamenyayet ekspluatacionnyij marshrut, a snyataya sokhranyayet toljko proiskhozhdeniye prezhnej periodicheskoj arkhitekturyi.

## Kriterii proverki

- kartochka i indeks imeyut status `🗑️`, a tekusjhiye pravila i navyiki ne razreshayut heartbeat, dispetcherskuyu rezervaciyu ili sozdaniye zadach iz reyestra periodicheskikh zadanij;
- dejstvuyusjhij putj prodolzheniya ssyilayetsya na otdeljnoye trebovaniye FUM-REQ-0042 i ne ispoljzuyet etu kartochku kak runtime-polnomochiye;
- istoricheskiye zhurnalyi mogut opisyivatj prezhnij mekhanizm, no ne obyyavlyayut yego tekusjhim konturom.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `🗑️`: snyato tekusjhim resheniyem. Eto ne otmenyayet istoricheskiye faktyi realizacii i proverok, no zapresjhayet ispoljzovatj ikh kak opisaniye dejstvuyusjhego avtoprodolzheniya.

Snyatiye otnositsya k avtozapusku vetochnoj rabotyi Codex. Ono ne zatragivayet otdeljnyiye trebovaniya avtozapuska interfejsa, vkhoda v uchyotnuyu zapisj ili fonovogo servisa produkta.

Snyataya dispetcherizaciya takzhe ne reshayet i ne upolnomochivayet vozmozhnuyu publikaciyu drugikh refs: yeyo granicyi sokhranyayutsya v [otdeljnom voprose o publikacii vetki](../Voprosyi/2026-07-27_15-21-35_MSK_granicyi-periodicheskoj-publikacii-vetki.md).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-05 05:48:39 MSK — Zakrepitj kontrakt universaljnogo dispetchera avtomatizacij FUM](../Zhurnal/2026-08-05_05-48-39_MSK_zakrepitj-kontrakt-universaljnogo-dispetchera-avtomatizacij-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:58:13 MSK -->
<!-- content-sha256: sha256:5f8cae824bdcc1e841b5131f3664e41c18650a837cc2aff13e228d8b25be0e13 -->
<!-- FUM-MD-RECENCY:END -->
