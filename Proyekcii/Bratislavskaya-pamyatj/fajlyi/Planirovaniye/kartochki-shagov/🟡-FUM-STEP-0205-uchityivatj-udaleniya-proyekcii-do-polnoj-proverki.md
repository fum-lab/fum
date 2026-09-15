+++
schema_version = 1
card_id = "FUM-STEP-0205"
status = "active"
+++
# Uchityivatj udaleniya proyekcii do polnoj proverki

## Zadacha

Avtomatizirovatj predvariteljnoye sopostavleniye ozhidayemyikh udalenij prezhnego pokoleniya proyekcii s tochnoj oblastjyu tekusjhego zaprosa do dorogogo polnogo dopuska.

## Pochemu sejchas

FUM-SBOJ-0035/PROYAVLENIYE-0002 povtorilo uzhe vosstanovlennyij lokaljnyij propusk: ssyilka na susjhestvuyusjhij katalog ne obyyavlyayet udaleniye prezhnej kartochki. Ruchnoj marker ispravil odin vkhod posle otkaza shaga 11. FUM-SBOJ-0035/PROYAVLENIYE-0003 povtorilo tu zhe granicu pri pereimenovanii kartochki 0177: posle desyati uspeshnyikh shagov obnaruzhen neukazannyij staryij putj; adresnaya proverka prinyala dopolnennyij zapros bez izmeneniya realizacii. FUM-SBOJ-0035/PROYAVLENIYE-0004 povtorilo pozdneye obnaruzheniye srazu pyati prezhnikh kartochek v obyyedinyonnom pokolenii. Nuzhna vosproizvodimaya podgotovka do zapuska.

## Kriterii zaversheniya

- Obobsjhyonnyiye fiksturyi vsekh chetyiryokh proyavlenij vosproizvodyat pozdnij propusk udalyonnogo puti do ispravleniya.
- Sukhoj vyivod ispoljzuyet podtverzhdyonnoye vladeniye staryim pokoleniyem i ozhidayemyij novyij plan; sokhranyayet tochnyiye repozitornyiye puti i osnovaniye kazhdogo udaleniya bez zapisi v poljzovateljskoye derevo.
- Primeneniye soglasovannyikh markerov proveryayet neizmennostj vkhoda; povtor ne dubliruyet svedeniya. Nepodtverzhdyonnoye udaleniye ne poluchayet razresheniya avtomaticheski.
- Polozhiteljnyiye pereimenovaniya, sosedniye prefiksyi, neizvestnoye udaleniye, izmenivsheyesya pokoleniye i nevernaya oblastj proverenyi otdeljno; susjhestvuyusjhij strogij zapret ne oslablen.
- Shtatnyij marshrut podgotovki zaprosa ispoljzuyet rezuljtat do polnogo smoke; instrukciya, RED/GREEN, profilj i resheniye ob optimizacii sokhranenyi.

## Istochniki

- [FUM-SBOJ-0035](../../Sboi/FUM-SBOJ-0035-propusk-udalyonnogo-puti-proyekcii-v-zaprose.md): osnovaniya FUM-SBOJ-0035/PROYAVLENIYE-0002, FUM-SBOJ-0035/PROYAVLENIYE-0003 i FUM-SBOJ-0035/PROYAVLENIYE-0004.

- [Otchyot 0177](https://github.com/fum-lab/fum/blob/6b1860591deb1d669f5f5ae1bd03336170fb8fce/Журнал/2026-09-11_02-02-21_MSK_закрепить-допуск-остатка-сообщений/отчёт.md), [otkaz № 19](https://github.com/fum-lab/fum/blob/6b1860591deb1d669f5f5ae1bd03336170fb8fce/Журнал/2026-09-11_02-02-21_MSK_закрепить-допуск-остатка-сообщений/материалы/запуски-проверок/19_e9f92a65-105d-4a42-b74c-3cfa8e718a6b.json) i [adresnoye vosstanovleniye № 20](https://github.com/fum-lab/fum/blob/6b1860591deb1d669f5f5ae1bd03336170fb8fce/Журнал/2026-09-11_02-02-21_MSK_закрепить-допуск-остатка-сообщений/материалы/запуски-проверок/20_6d01bd93-bd39-44a2-b106-eb413e6e71f7.json).
- [Novyij zapros diagnostiki](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/zapros.md) i [otchyot](../../Zhurnal/2026-09-11_09-36-55_MSK_sokhranitj-ostavshuyusya-diagnostiku-priyoma/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 05:16:15 MSK -->
<!-- content-sha256: sha256:1045d9b325dbfb24ab58bcc5920aed5b4718d89c846a9d100bd3ec3a73293cb0 -->
<!-- FUM-MD-RECENCY:END -->
