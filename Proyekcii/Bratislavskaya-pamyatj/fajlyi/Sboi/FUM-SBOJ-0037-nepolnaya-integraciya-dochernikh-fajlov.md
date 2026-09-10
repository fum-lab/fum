+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0037"
"статус" = "активна"
+++
# Nepolnaya integraciya dochernikh fajlov

## Nablyudayemyij sboj

Pri ruchnom vyibore fajlov postavki klassifikatora propusjhen scenarij profilya, ot kotorogo zavisit test. Sleduyusjhij vyibor iz tekstovogo vyivoda Git ne raspoznal ekranirovannyiye kirillicheskiye puti i vernul pustoj nabor. Oba zapuska17 testov zavershilisj odnim FileNotFoundError; nekorrektnyij snimok ne byil zakommichen.

## Granica povtoreniya

Perenos vyibrannoj chasti dochernego rezuljtata bez polnogo soglasovannogo mashinnogo manifesta. Nepolnaya postavka i pustaya vyiborka ostayutsya neotmechennyimi do zapuska testov.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0037/PROYAVLENIYE-0001 | [Zapusk5](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/materialyi/zapuski-proverok/5_7a1172e0-f338-4bf0-8ae3-1ae54a61d571.json) | Propusjhen neobkhodimyij fajl profilya | Dopolnitj tochnuyu postavku |
| FUM-SBOJ-0037/PROYAVLENIYE-0002 | [Zapusk6](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/materialyi/zapuski-proverok/6_896e8d46-5fbe-4cd2-90e1-c98a419de115.json) | Ekranirovannyij spisok dal nulevoj import, otkaz povtorilsya | Ispoljzovan NUL-razdelyonnyij spisok, proveren nepustoj ozhidayemyij nabor |

## Mekhanizm i ogranichennoye vosstanovleniye

Otsutstvovala predvariteljnaya proverka polnotyi soglasovannogo nabora. Tochnoye dopolneniye iz commit002bb953 vosstanovilo testovyij scenarij i dochernyuyu istoriyu; [zapusk7](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/materialyi/zapuski-proverok/7_4be4e9ae-a3bd-4fe8-995f-f8f1c251fc5c.json) proshyol17 testov. Eto lokaljnoye vosstanovleniye, a ne zavershyonnaya obsjhaya avtomatizaciya.

## Svyazannyiye shagi

- [FUM-STEP-0162 — Proveryatj polnotu dochernej postavki](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0162-proveryatj-polnotu-dochernej-postavki.md).

## Kriterii zakryitiya

- Proveryayemaya avtomatizaciya otklonyayet nepolnuyu i pustuyu vyiborku do zapisi.
- Obe nablyudayemyiye granicyi vosproizvedenyi otricateljnyimi testami, korrektnyij polnyij nabor prokhodit.
- Integraciya podtverzhdena na tochnyikh iskhodnyikh bajtakh; dopolniteljnaya stoimostj izmerena.

## Istochniki

- [Komandyi i otchyot tekusjhego etapa](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 15:24:50 MSK -->
<!-- content-sha256: sha256:c6359c3516fe58d63e90535819eda1e76cb6b2171042aef23c11f2efe294f87f -->
<!-- FUM-MD-RECENCY:END -->
