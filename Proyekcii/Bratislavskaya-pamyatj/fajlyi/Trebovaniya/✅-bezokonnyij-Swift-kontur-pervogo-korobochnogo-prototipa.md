# Bezokonnyij Swift-kontur pervogo korobochnogo prototipa

<!-- FUM-REQUIREMENT-ID: FUM-REQ-0019 -->

Pervyij inzhenernyij [korobochnyij prototip FUM](../Glossarij/korobochnyij-prototip-FUM.md) dolzhen byitj minimaljnyim lokaljnyim Swift-konturom, poleznyij scenarij kotorogo vyipolnyayetsya bez WindowServer i GUI-frejmvorkov. Sobstvennyij GUI FUM mozhet otsutstvovatj na vsej nachaljnoj inzhenernoj stadii: vneshnyaya sessiya Codex sluzhit dostatochnoj poverkhnostjyu dlya zapuska, analiza i testirovaniya posledovateljnyikh bezokonnyikh srezov cherez versionirovannyiye lokaljnyiye komandyi i mashinochitayemyiye rezuljtatyi.

Bezokonnostj otnositsya k inzhenernomu bootstrap i ne zapresjhayet budusjhij poljzovateljskij interfejs. Codex pri etom ostayotsya vneshnim stendom: yego agentskij cikl i skryitoye sostoyaniye sessii ne stanovyatsya sobstvennyim runtime, pamyatjyu ili interfejsom FUM.

## Semanticheskiye svyazi

- **trebuyetsya dlya:** [vosproizvodimogo shtatnogo popolneniya pamyati](🚧-vosproizvodimoye-shtatnoye-popolneniye-pamyati.md) — zadayot sobstvennyij ispolnyayemyij nositelj pervogo scenariya pamyati.
- **dopolnyayetsya:** [prototipami kak testami realizacii kornevogo yadra FUM](🟡-prototipyi-kak-testyi-realizacii-kornevogo-yadra-FUM.md) — zakreplyonnyij nablyudayemyij kontrakt prototipa mozhet povtorno proveryatj otdeljnuyu realizaciyu obsjhego yadra bez perenosa eksperimentaljnogo koda v postavku.

## Kriterii proverki

- samostoyateljnyij SwiftPM-paket sobirayetsya bez vneshnikh zavisimostej;
- ispolnyayemyij produkt i bezopasnaya komanda zapuska rabotayut bez AppKit, SwiftUI, seti i realjnoj LLM;
- sborka, zapusk, replay, vosstanovleniye i testyi realizovannyikh srezov dostupnyi Codex neinteraktivnyimi komandami bez ruchnyikh ekrannyikh dejstvij;
- vkhodyi peredayutsya cherez argumentyi, standartnyij vvod ili versionirovannyiye fajlyi; snimok i trassa imeyut ustojchivuyu mashinochitayemuyu formu, a otkaz razlichim po kodu zaversheniya i stabiljnoj diagnostike;
- lokaljnaya fikstura prokhodit cherez vnutrennij API pamyati i vyidayot kanonicheskij mashinochitayemyij otchyot;
- avtonomnyiye testyi podtverzhdayut determinizm i otkaz na nedopustimom vkhode;
- khotya byi odin skvoznoj progon iz vneshnej sessii Codex sokhranyayet vyizvannyiye komandyi, rezuljtatyi proverok i granicu dokazannogo;
- README yavno otdelyayet inzhenernyij prototip ot poljzovateljskogo reliza FUM.

## Status i granicyi

[Status trebovaniya FUM](../Glossarij/status-trebovaniya-FUM.md) — `✅`: kriterii podtverzhdenyi [SwiftPM-prototipom vosproizvodimogo popolneniya pamyati](../Prototipyi/vosproizvodimoye-popolneniye-pamyati/README.md), yego avtonomnyimi testami i vosproizvodimyimi zapuskami iz rabochikh sessij Codex. Rezuljtat ne podtverzhdayet sobstvennyij agentskij runtime FUM, realjnyij modeljnyij provajder ili poljzovateljskij GUI.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-27 20:10:35 MSK — Razreshitj nachaljnuyu korobochnuyu FUM bez GUI cherez Codex](../Zhurnal/2026-07-27_20-10-35_MSK_razreshitj-nachaljnuyu-korobochnuyu-FUM-bez-GUI-cherez-Codex/zapros.md)
- [iskhodnyij zapros 2026-07-24 10:44:28 MSK — Nachatj bezokonnyij Swift-prototip vosproizvodimogo popolneniya pamyati FUM](../Zhurnal/2026-07-24_10-44-28_MSK_nachatj-bezokonnyij-Swift-prototip-vosproizvodimogo-popolneniya-pamyati-FUM/zapros.md)
- [pasport nachaljnogo korobochnogo prototipa FUM](../Dokumentaciya/43-pasport-nachaljnogo-korobochnogo-prototipa-FUM.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 20:15:36 MSK -->
<!-- content-sha256: sha256:4da3a6c8906fb17168effc9eb0997f2eba7d751c280dfd7174773f550f467dce -->
<!-- FUM-MD-RECENCY:END -->
