+++
schema_version = 1
card_id = "FUM-STEP-0151"
status = "completed"
+++
# Obyyedinitj ochistku sluzhebnyikh zagolovkov arkhivatorov

## Zadacha

Ustranitj povtornoye sokhraneniye sluzhebnyikh HTTP-identifikatorov pri arkhivirovanii ChatGPT-share i obyichnyikh HTML-istochnikov.

## Rezuljtat

Oba vkhoda ispoljzuyut odnu funkciyu ochistki. Ona bez uchyota registra raspoznayot `Set-Cookie`, `CF-Ray`, `X-Request-ID`, `Request-Context` i `X-MS-Middleware-Request-ID`, udalyayet ikh znacheniya i prodolzheniya, sokhranyayet soderzhateljnyiye zagolovki i povtorno primenyayetsya bez izmeneniya rezuljtata. Opisaniya izvlecheniya perechislyayut redakcii; chetyire snimka tekusjhej sessii ochisjhenyi etoj funkciyej bez povtornoj zagruzki tel i soobsjhenij.

Adresnyij test snachala pokazal vosemj neuspeshnyikh sochetanij dvukh vkhodov i chetyiryokh trace-zagolovkov, zatem proshyol. Pervyij oshibochnyij zapusk unittest bez kataloga obnaruzheniya otdeljno sokhranyon v otchyote i ne schitayetsya RED-dokazateljstvom. Polnyij nabor materialov zaprosov vkhodit v finaljnyij standartnyij smoke-check.

## Istochniki

- [Iskhodnyij zapros](../../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [FUM-SBOJ-0020/PROYAVLENIYE-0002](../../Sboi/FUM-SBOJ-0020-publikaciya-sluzhebnogo-CF-Ray-v-snimke-istochnika.md#proyavleniya).
- [Obsjhaya ochistka](../../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py), [vkhod ChatGPT-share](../../Instrumentyi/fum-materialyi-zaprosov/scripts/archive-chatgpt-share.py), [adresnyij test](../../Instrumentyi/fum-materialyi-zaprosov/tests/test_source_archive_cli.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 18:43:58 MSK -->
<!-- content-sha256: sha256:e73f397ecaea06a65323c6d9c28e72b8384b0f790a5d0504580d632960d38069 -->
<!-- FUM-MD-RECENCY:END -->
