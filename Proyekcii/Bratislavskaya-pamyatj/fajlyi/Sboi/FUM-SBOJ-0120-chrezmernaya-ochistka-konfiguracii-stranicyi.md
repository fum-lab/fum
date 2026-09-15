+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0120"
"статус" = "устранена"
+++
# Chrezmernaya ochistka konfiguracii stranicyi

Ochistka konfiguracii stranicyi raspoznavala pokhozhiye atributyi kak sluzhebnyij blok i izmenyala publichnyij primer. Ispravleniye sokhranyayet chetyire vosproizvedyonnyiye otricateljnyiye formyi.

## Nablyudayemyij sboj

Pri podgotovke polnoj priyomki reyestra vyiyavleno, chto ochistka sluzhebnogo `websocket.token` izmenyala publichnyij primer v chetyiryokh pokhozhikh formakh atributov: `data-id="app-config"`, `id="APP-CONFIG"`, tekst `id="app-config"` vnutri kavyichek drugogo atributa i sochetaniye publichnogo `id` s `data-id`. Vse chetyire formyi vosproizvedenyi sinteticheskimi testami; utrata soderzhimogo fakticheskogo opublikovannogo istochnika ne ustanovlena.

## Granica povtoreniya

Oshibochnoye raspoznavaniye atributa i yego znacheniya pri vyibore konfiguracionnogo bloka. Propusk ochistki nastoyasjhego sluzhebnogo polya otnositsya k FUM-SBOJ-0081, propuski HTTP-zagolovkov — k FUM-SBOJ-0020. FUM-SBOJ-0120 ne obyyavlyayetsya povtorom ili poglosjheniyem etikh kartochek.

## Proyavleniya

- `FUM-СБОЙ-0120/ПРОЯВЛЕНИЕ-0001`: [chetyire otkazavshikh otricateljnyikh primera](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/zapuski-proverok/3_ce600c63-e03b-4424-b60e-aa62a7e8bcd1.json) podtverdili zamenu publichnogo tokena. Effekt — izmeneniye teksta vne obesjhannoj tochnoj konfiguracii. Vosstanovleniye — raspoznavaniye polnocennogo atributa s tochnyim znacheniyem i sokhraneniye otricateljnyikh regressij.

## Ozhidaniye i klassifikaciya

Navyik materialov zaprosov obesjhal ochistku toljko bloka s tochnyim `id="app-config"` i sokhrannostj publichnogo primera. Nesovpadeniye etogo kontrakta s ispolnyayemyim raspoznavaniyem — podtverzhdyonnaya nedorabotka, a ne gipoteticheskij risk.

## Mekhanizm i sistemnoye ustraneniye

Prezhnyaya granica slova dopuskala `id` vnutri `data-id` i vnutri chuzhogo strokovogo znacheniya; obsjhij flag bez uchyota registra rasshiryal znacheniye `app-config`. V 5afb565756f3e5c31e5c99e7b3b74c3fd2836f3f raspoznavaniye ogranicheno sintaksisom polnyikh atributov i tochnyim registrom znacheniya. Imena HTML-tega i atributa sokhranyayut dopustimyij nezavisimyij registr. Tochnaya polozhiteljnaya konfiguraciya ochisjhayetsya, chetyire otricateljnyikh formyi ostayutsya neizmennyimi.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) aktualizirovan `FUM-СБОЙ-0120/ПРОЯВЛЕНИЕ-0001` kak ogranichennaya korrekciya podgotovki istochnikov reyestra podderzhki. Otdeljnyij novyij shag ne nuzhen: mera realizovana i proverena v susjhestvuyusjhem obyyome.

## Kriterii zakryitiya

- Chetyire vosproizvedyonnyiye otricateljnyiye formyi sokhranyayut tochnyiye iskhodnyiye bajtyi.
- Nastoyasjhij sluzhebnyij token redaktiruyetsya; cena, tekst uslovij i primer vne konfiguracii sokhranyayutsya; povtor idempotenten.
- Regressiya prokhodit vmeste s susjhestvuyusjhimi testami arkhivatora, a profilj fiksirovannogo nabora pozvolyayet ocenitj stoimostj ispravleniya bez zayavleniya o nedokazannom uskorenii.

## Podtverzhdeniye ustraneniya

[GREEN 57 testov arkhivatora](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/zapuski-proverok/5_d49ee583-5f67-4ac5-b201-5325f8c76e39.json) sleduyet za sokhranyonnyim RED. [Iskhodnyij profilj](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/profilj-ochistki-do.json) i [profilj ispravleniya](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/profilj-ochistki-posle.json) soderzhat po semj prokhodov po 29 odinakovyim HTML; [proverka tozhdestva](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/materialyi/zapuski-proverok/14_5985c483-bf84-43e9-a696-9b5de0b90f66.json) podtverzhdayet vkhodyi. Maksimumyi 390,210334 i 391,244667 ms nablyudalisj pri vozmozhnoj konkuriruyusjhej nagruzke; uskoreniye ne zayavlyayetsya, dopolniteljnaya optimizaciya ne obosnovana. Eto dokazateljstvo konechnoj regressionnoj granicyi, ne polnaya priyomka proyekta.

## Istochniki

- [Iskhodnaya diagnostika i ispravleniye](../Zhurnal/2026-09-14_23-17-14_MSK_zavershitj-priyomku-finansirovaniya-FUM/otchyot.md).
- [Vyidacha FUM-SBOJ-0120 obsjhim raspredelitelem](../Zhurnal/2026-09-14_23-44-58_MSK_zaregistrirovatj-sboi-istochnikov-podderzhki/zapros.md), sobyitiye `funding-app-config-overclean-01a0904a-5afb5657`.
- [Regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py), [realizaciya](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 23:59:27 MSK -->
<!-- content-sha256: sha256:c09f62bdde84bb2adf29812b16e97b0d5e441dbaa89c807af2e56cb15cd5db7f -->
<!-- FUM-MD-RECENCY:END -->
