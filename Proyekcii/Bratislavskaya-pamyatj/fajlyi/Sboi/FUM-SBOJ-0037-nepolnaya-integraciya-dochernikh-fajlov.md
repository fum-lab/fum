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
| `FUM-СБОЙ-0037/ПРОЯВЛЕНИЕ-0003` | [Prinyatiye zavisimostej DNK](https://github.com/fum-lab/fum/blob/ef458281e95048e361afb92e73ec960677b95c50/Журнал/2026-09-11_08-49-30_MSK_принять-перекодирование-ДНК-в-белки/отчёт.md): tri otkaza build i posleduyusjheye vosstanovleniye | Pri importe devyati kartochek propusjhena uzhe gotovaya dvukhstrochnaya zavisimostj formata REQ-0058; probnyiye izmeneniya predmetnogo razdela ne vosstanovili build | Prinyatyi tochnyiye dve stroki, shestj regressij i stroka rukovodstva iz 0246844; iskhodnyij format kartochki vosstanovlen; tri formaljnyiye kvitancii v4 uspeshnyi |

## Ozhidaniye i klassifikaciya

Vyibrannyij komplekt perenosa vklyuchayet neobkhodimyiye zavisimosti yego formata mezhdu iskhodnoj i prinimayusjhej bazami. Novyij sluchaj 0058 otnositsya k uzhe ustanovlennoj granice nepolnoj dochernej postavki; on ne sozdayot otdeljnogo sboya. Korrektnyij otkaz sborsjhika ne yavlyayetsya yego novyim defektom. Vyizovyi vne obyortki uchyota ostayutsya otdeljnyim proyavleniyem 0025; mekhanizm ugadyivaniya putej 0009 zdesj ne ustanovlen.

## Mekhanizm i sistemnoye ustraneniye

Otsutstvovala predvariteljnaya proverka polnotyi soglasovannogo nabora. Tochnoye dopolneniye iz commit002bb953 vosstanovilo testovyij scenarij i dochernyuyu istoriyu; [zapusk7](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/materialyi/zapuski-proverok/7_4be4e9ae-a3bd-4fe8-995f-f8f1c251fc5c.json) proshyol17 testov. Eto lokaljnoye vosstanovleniye, a ne zavershyonnaya obsjhaya avtomatizaciya.

### Ogranichennoye vosstanovleniye importa 0058

Pri perenose devyati kartochek iz 5c9806560fb9b52112ff8a7bc11888a1bb71f7aa ne vklyuchyon uzhe susjhestvuyusjhij dopusk tochnogo markera «Pryamyiye semanticheskiye svyazi poka ne ustanovlenyi.». Pervyij build zavershilsya soobsjheniyem malformed semantic relation, chunk ca4864. Posleduyusjhaya recency sdelala kod obsjhej obolochki ravnyim 0; eto ne uspeshnyij build. Probyi s perenosom poyasneniya i pustyim razdelom poluchili missing required section, chunks 7db87e i 103909, obe obolochki zavershilisj kodom 1. Eto tri popyitki odnogo novogo proyavleniya nepolnoj postavki.

Vosstanovlen iskhodnyij predmetnyij format REQ-0058 i prinyat tochnyij kod iz 0246844fe15ba51e48327005b33bc78b668f813a: dve stroki sborsjhika, shestj regressij i odna stroka rukovodstva. Build zavershilsya kodom 0, chunk 39a826. V ef458281e95048e361afb92e73ec960677b95c50 sborsjhik i oba testovyikh fajla sovpadayut pobajtno s iskhodnyim kommitom. Tri realjnyiye kvitancii v4 uspeshnyi: 1_52f6f203-f5b9-413a-85d3-baf9cbf9a6d3 — 0,296325375 s; 2_73ad2f81-b7c2-4592-8630-dfbe95d38cbc — 0,406792083 s; 3_45230cac-b94b-46f1-a2fd-59d3c2745f9b — 0,370420250 s. Ikh summa — 1,073537708 s. Poslednij guard trebuyet prodolzhitj priyom DNK.

[Iskhodnaya kartochka 0046](https://github.com/fum-lab/fum/blob/0246844fe15ba51e48327005b33bc78b668f813a/Сбои/FUM-СБОЙ-0046-невозможность-выразить-требование-без-семантических-связей.md) opisyivayet prezhnyuyu vyiraziteljnostj formata, ispravleniye kotoroj uzhe susjhestvovalo do etogo importa. Novoye proyavleniye 0037 fiksiruyet propusk dostupnoj zavisimosti. Ogranichennoye vosstanovleniye podtverzhdeno; avtomaticheskaya proverka polnotyi po STEP-0162 yesjhyo ne prinyata, poetomu 0037 i 0162 sokhranyayut aktivnyij status. Novogo STEP net.

## Svyazannyiye shagi

- [FUM-STEP-0162 — Proveryatj polnotu dochernej postavki](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0162-proveryatj-polnotu-dochernej-postavki.md).

Novoye osnovaniye togo zhe shaga — `FUM-СБОЙ-0037/ПРОЯВЛЕНИЕ-0003`; susjhestvuyusjhij kriterij resheniya zavisimostej mezhdu razlichnyimi bazami uzhe okhvatyivayet etot sluchaj.

## Kriterii zakryitiya

- Proveryayemaya avtomatizaciya otklonyayet nepolnuyu i pustuyu vyiborku do zapisi.
- Vse nablyudayemyiye granicyi vosproizvedenyi otricateljnyimi testami, korrektnyij polnyij nabor prokhodit.
- Integraciya podtverzhdena na tochnyikh iskhodnyikh bajtakh; dopolniteljnaya stoimostj izmerena.

## Istochniki

- [Komandyi i otchyot tekusjhego etapa](../Zhurnal/2026-09-09_14-35-59_MSK_podgotovitj-nativnoye-prodolzheniye-zadachi/zapros.md).

- [Ogranichennoye vosstanovleniye importa 0058](https://github.com/fum-lab/fum/blob/ef458281e95048e361afb92e73ec960677b95c50/Журнал/2026-09-11_08-49-30_MSK_принять-перекодирование-ДНК-в-белки/отчёт.md).
- [Tekusjhaya registraciya i pervichnyiye svideteljstva](../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 09:58:11 MSK -->
<!-- content-sha256: sha256:d289ee9079562fbc2706fc7243c66f941561687969f3f35448e41ac4146d18cb -->
<!-- FUM-MD-RECENCY:END -->
