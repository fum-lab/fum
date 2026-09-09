+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0036"
"статус" = "устранена"
+++
# Konkurentnaya podgotovka doveriya kyesha vyizyivayet lozhnyij otkaz

Granica ustraneniya — kodovaya dochernyaya vetka s podtverzhdyonnoj determinirovannoj regressiyej. Obsjhaya integraciya i realjnaya peresborka vyipolnyayutsya kornem otdeljno.

## Nablyudayemyij sboj

Pervyij podgotovitelj vidit otsutstviye kataloga doveriya. Vtoroj uspevayet opublikovatj klyuch i katalog kyesha. Pervyij chitayet uzhe susjhestvuyusjhij kyesh i oshibochno soobsjhayet, chto doverennogo klyucha net.

## Granica povtoreniya

Dva dobrosovestnyikh podgotovitelya odnogo lokaljnogo kyesha; vtoroj zavershayet publikaciyu mezhdu dvumya nablyudeniyami pervogo. Gonka vosproizvoditsya bez podmenyi doveriya i bez sluchajnogo ozhidaniya.

## Proyavleniya

| Lokaljnyij nomer               | Istochnik i dokazateljstvo                                                                                 | Effekt                                                 | Vosstanovleniye                                                                        |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| FUM-SBOJ-0036/PROYAVLENIYE-0001 | [RED i GREEN](../Zhurnal/2026-09-09_09-50-11_MSK_ustranitj-gonku-podgotovki-kyesha-preobrazovatelya/otchyot.md) | Pervyij podgotovitelj otklonyayet korrektnyij kyesh vtorogo. | Povtorno proveritj doveriye posle obnaruzheniya kyesha i validirovatj opublikovannyij klyuch. |

## Mekhanizm i ogranichennoye vosstanovleniye

Yesli posle pervonachaljnogo otsutstviya doveriya poyavilsya kyesh, podgotovitelj povtorno proveryayet doveriye. Pri nalichii ispoljzuyet susjhestvuyusjhij klyuch posle vsekh shtatnyikh proverok; pri otsutstvii sokhranyayet otkaz bez sozdaniya novogo klyucha. Yesli kyesh yesjhyo otsutstvuyet, atomarnaya publikaciya doveriya po-prezhnemu dopuskayet odnogo pobeditelya i proverku yego rezuljtata.

## Kriterii zakryitiya

- Determinirovannoye cheredovaniye vozvrasjhayet oboim podgotovitelyam odin i tot zhe klyuch.
- Nastoyasjhij kyesh bez doveriya ostayotsya netronutyim i vyizyivayet otkaz.
- Povrezhdyonnyij klyuch, podpisj, rezhim i bajtyi ispolnyayemogo produkta po-prezhnemu otklonyayutsya.
- Kholodnaya i tyoplaya podgotovka dayut odinakovyiye vyikhodnyiye bajtyi pri odnoj i nule sborok sootvetstvenno.

## Podtverzhdeniye ustraneniya

18 testov kyesha i polnyij avtonomnyij nabor proyekcii iz 140 testov proshli. Sobstvennaya para processov na polnom prinyatom vkhode podtverdila 1/0 sborok i pobajtnoye ravenstvo 10 018 076 vyikhodnyikh bajtov. Profilj i ogranicheniya sokhranenyi v [otchyote](../Zhurnal/2026-09-09_09-50-11_MSK_ustranitj-gonku-podgotovki-kyesha-preobrazovatelya/otchyot.md).

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-09_09-50-11_MSK_ustranitj-gonku-podgotovki-kyesha-preobrazovatelya/zapros.md).
- [Otchyot s TDD i profilem](../Zhurnal/2026-09-09_09-50-11_MSK_ustranitj-gonku-podgotovki-kyesha-preobrazovatelya/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 10:04:05 MSK -->
<!-- content-sha256: sha256:311d83d07f90b4a8350980b0a37ee6783b7bdec9ddaee524cd2b96085f917ef8 -->
<!-- FUM-MD-RECENCY:END -->
