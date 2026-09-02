+++
schema_version = 1
card_id = "FUM-STEP-0142"
status = "withdrawn"
+++
# Dobavitj ograzhdyonnoye vozobnovleniye zadach posle poteri svyazi

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet istoricheskoye proiskhozhdeniye snyatogo shaga.

## Zadacha

Rasshiritj prezhnij heartbeat-dispetcher podprotokolom yedinstvennogo vosstanovleniya uzhe sozdannoj ispolniteljskoj zadachi posle nablyudayemogo razryiva potoka svyazi.

## Rezuljtat

Kartochka snyata bez zayavleniya o zavershenii. V novom konture net heartbeat, kotoryij mog byi chitatj prezhnyuyu zadachu i otpravlyatj vosstanoviteljnoye soobsjheniye: kazhdyij podtverzhdyonnyij kommit zaraneye svyazan s novoj sessiyej-prodolzheniyem, a ischeznuvshij ispolnitelj ostayotsya yavnoj granicej ruchnogo vosstanovleniya.

## Istochniki

- [iskhodnyij zapros 2026-08-11 23:30:57 MSK — Zamenitj avtozapusk obyazateljnyim prodolzheniyem vetki](../../Zhurnal/2026-08-11_23-30-57_MSK_zamenitj-avtozapusk-obyazateljnyim-prodolzheniyem-vetki/zapros.md)
- [iskhodnyij zapros 2026-08-08 18:57:20 MSK — Dobavitj ograzhdyonnoye vozobnovleniye posle razryiva svyazi](../../Zhurnal/2026-08-08_18-57-20_MSK_dobavitj-ograzhdyonnoye-vozobnovleniye-posle-razryiva-svyazi/zapros.md)
- [FUM-SBOJ-0014 — Ruchnoye vozobnovleniye zadachi posle razryiva potoka otveta](../../Sboi/FUM-SBOJ-0014-ruchnoye-vozobnovleniye-posle-razryiva-potoka-otveta.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-12 01:34:29 MSK -->
<!-- content-sha256: sha256:ca7ce6df00b2892d5045931a599b82e29aac4356f8883b07e33145e754241179 -->
<!-- FUM-MD-RECENCY:END -->
