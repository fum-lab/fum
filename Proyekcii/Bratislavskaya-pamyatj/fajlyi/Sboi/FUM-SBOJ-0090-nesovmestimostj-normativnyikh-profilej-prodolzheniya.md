+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0090"
"статус" = "активна"
+++
# Nesovmestimostj normativnyikh profilej prodolzheniya

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0090/ПРОЯВЛЕНИЕ-0001`: iskhodnyij prinimayusjhij M `224dc6cf289e4cc88080b85ad7c99240284a7ced` otklonyayet soglasovannyij profilj L `a728283474931eda71cd581ca5429121124ba3f6`. Full C2 `f81e52ff-c573-4b5a-9f59-240fba1dea25` zavershyon s kodom 1 na dekompozicii: «granica prodolzheniya zadachi ne soglasovana». [Diagnostika s mashinnyim pervoistochnikom i predelami dokazateljstva](../Zhurnal/2026-09-11_22-33-53_MSK_soglasovatj-profili-dopuska-prodolzheniya/materialyi/granica-profilej.md). Effekt — C2 neljzya prinyatj po iskhodnomu M. Posleduyusjhiye adresnyiye RED issleduyut tu zhe granicu i ne yavlyayutsya nezavisimyimi povtorami iskhodnogo C2.

## Ozhidaniye, dejstvuyusjhij kontrakt i mekhanizm

Soglasovannaya integraciya trebuyet prinimatj novyij kandidat po pravilam iskhodnogo master. Yego validator podderzhival toljko dvukhpoljnuyu deklaraciyu prodolzheniya; prinyatyiye v L normyi 0177 trebuyut chetyire polya i obyazateljnuyu proverku ostatka JSONL. Eto nedostatochnaya sovmestimostj prinimayusjhego kontura s soglasovannyim celevyim profilem, a ne proizvoljnoye narusheniye staroj skhemyi. Obsjheye razresheniye lishnikh klyuchej pozvolilo byi nezametno ponizitj novyij kontrakt; kopiya strogogo L otvergla byi M.

## Vosstanovleniye i posleduyusjhaya rabota

Podgotovlen validator rovno dvukh zakryityikh profilej, vyibrannyikh po tochnoj pare dejstvuyusjhikh normativnyikh tel. Deklaraciya, parametryi, tipyi, puti i aktivnostj dolzhnyi sootvetstvovatj vyibrannomu profilyu. RED/GREEN38 i proverka realjnyikh M/L podtverzhdayut etu granicu. Obsjhaya priyomka paketa, perenos v master, fiksaciya novogo M i povtornaya proverka C2 ostayutsya otdeljnyimi posledovateljnyimi dejstviyami; uspeshnyiye adresnyiye testyi ne zakryivayut kartochku.

## Svyazannyiye shagi

- [FUM-STEP-0175](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0175-podgotovitj-smenu-golovnoj-vetki-razrabotki.md); osnovaniye svyazi — `FUM-СБОЙ-0090/ПРОЯВЛЕНИЕ-0001`. Novogo shaga i dubliruyusjhej kartochki v C2 net.

## Kriterij zakryitiya

Prinimayusjhij paket proveren i prinyat v master, novyij M zafiksirovan, yego validator prinimayet soglasovannyiye dejstviteljnyiye M/L bez rasshireniya profilej. Negativnyiye testyi sokhranyayut otkaz pri udalenii JSONL-polej, neizvestnoj ili smeshannoj norme, nevernyikh tipakh, klyuchakh i putyakh, skryitoj razmetke i povtornyikh JSON-klyuchakh. Novyij C2 prokhodit rannyuyu dekompoziciyu, a zatem primenimuyu obsjhuyu priyomku po novomu M. Iskhodnyij otkaz i proiskhozhdeniye sokhranenyi; staticheskij dopusk ne obyyavlyayetsya kontrolem polnogo istoricheskogo otkata pravil.

## Istochniki

- [Zapros etapa](../Zhurnal/2026-09-11_22-33-53_MSK_soglasovatj-profili-dopuska-prodolzheniya/zapros.md), [koordinaciya](../Zhurnal/2026-09-11_22-33-53_MSK_soglasovatj-profili-dopuska-prodolzheniya/materialyi/proiskhozhdeniye-koordinacii.md), [otchyot](../Zhurnal/2026-09-11_22-33-53_MSK_soglasovatj-profili-dopuska-prodolzheniya/otchyot.md).
- Obsjhij raspredelitelj vyidelil ID dlya zadachi `01a09047-faa1-7370-83f7-cdfc8f9943a6`; sobyitiye `2574ad635afe12e291f196b0af34bc992451c0dcd53fb09bf9f2e0d9f3d01450`. Privatnaya kvitanciya prochitana. Nezavisimyij audit koordinatora ne nashyol susjhestvuyusjhej kartochki s etoj regressionnoj granicej.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 23:16:44 MSK -->
<!-- content-sha256: sha256:57de4640c16216357ef5f49b7b016c474fa09a9fb682f032e5f1dc4d26596eca -->
<!-- FUM-MD-RECENCY:END -->
