+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0041"
"статус" = "активна"
+++
# Drejf mashinnogo zagolovka otchyota

Pri zapolnenii otchyota sgenerirovannyij zagolovok byil perepisan vruchnuyu s tipografskim tire vmesto obyazateljnogo defisa. Proverka svyaznosti obnaruzhila raskhozhdeniye do obsjhej priyomki. Zagolovok vosstanovlen; zasjhita ot povtornogo ruchnogo izmeneniya poka ostayotsya budusjhej rabotoj.

## Nablyudayemyij sboj i granica povtoreniya

Okhvatyivayutsya soderzhateljnyiye obnovleniya otchyota, pri kotoryikh agent zanovo pishet uzhe sgenerirovannyij mashinnyij H1 i menyayet yego tochnyiye bajtyi. Korrektnyij otkaz validatora ne schitayetsya defektom. Mekhanizm otlichayetsya ot oshibki puti pri zapuske: zdesj putj i vladelec vernyi, povrezhdeno soderzhimoye.

## Proyavleniya

- `FUM-СБОЙ-0041/ПРОЯВЛЕНИЕ-0001`: [tekusjhij otchyot](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md), pryamoj zapusk № 4. Ozhidalsya zagolovok `# Отчёт 2026-09-09 18:43:02 MSK - Завершить приёмку архивного снимка`; vmesto ` - ` stoyalo ` — `. Proverka zavershilasj kodom 1. Effekt — dopolniteljnyij cikl ispravleniya pered smoke-check; kommit povrezhdyonnogo otchyota ne vyipolnyalsya.

## Vosstanovleniye i sistemnaya mera

Tochnyij zagolovok vosstanovlen. Odno ispravleniye ne zakryivayet mekhanizm: soderzhateljnyij redaktor dolzhen sokhranyatj sgenerirovannyij H1 i razreshatj yego izmeneniye lishj cherez yavnuyu migraciyu identichnosti sessii.

## Svyazannyiye shagi

- [FUM-STEP-0168 — Sokhranyatj mashinnyij zagolovok pri zapolnenii otchyota](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0168-sokhranyatj-mashinnyij-zagolovok-pri-zapolnenii-otchyota.md); osnovaniye — `FUM-СБОЙ-0041/ПРОЯВЛЕНИЕ-0001`.

## Kriterii zakryitiya

- Test vosproizvodit zamenu defisa tipografskim tire pri obnovlenii soderzhimogo.
- Shtatnaya operaciya zapolneniya otchyota sokhranyayet H1 pobajtno i otklonyayet popyitku yego neyavnoj zamenyi do zapisi.
- Yavnaya migraciya identichnosti, yesli podderzhivayetsya, proveryayet soglasovannostj zaprosa, otchyota i navigacii.
- Regressiya podtverzhdayet razreshyonnyiye soderzhateljnyiye izmeneniya i otkaz drejfu; FUM-STEP-0168 vyipolnen.

## Istochniki

- [Iskhodnyij zapros tekusjhej priyomki](../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 18:59:45 MSK -->
<!-- content-sha256: sha256:0800b399f3840b2268e87fc936610d1051e001d4b65d8857b9fa0b28d2719e52 -->
<!-- FUM-MD-RECENCY:END -->
