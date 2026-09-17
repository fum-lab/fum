+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0154"
"статус" = "устранена"
+++
# Nesovmestimyiye s proyekciyej imena shablonov mediapaketa

## Nablyudayemyij sboj

Polnyij dopusk ostanovilsya na shage 5: dva tekstovyikh shablona mediapaketa imeli neizvestnoye proyekcii okonchaniye .txt.shablon.

## Granica povtoreniya

Sovmestimostj postavlyayemyikh shablonov podderzhki s dejstvuyusjhim klassifikatorom proyekcii. Kartochka 0024 otnositsya k drugomu kontraktu patchej i ne poglosjhayetsya.

## Proyavleniya

### FUM-SBOJ-0154/PROYAVLENIYE-0001

[Zapusk 7](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/materialyi/zapuski-proverok/7_b83aa1e9-c11d-4e8c-bd03-229b129fc687.json) zavershilsya otkazom posle chetyiryokh uspeshnyikh shagov; vnutrennij kontur zanyal 55,768 s.

## Ozhidaniye i klassifikaciya

Postavlyayemyiye fajlyi dolzhnyi sokhranyatjsya dejstvuyusjhej proyekciyej. Yeyo otkaz byil shtatnyim; defekt nakhodilsya v vyibore imyon shablonov.

## Mekhanizm i sistemnoye ustraneniye

Shtatnaya avtomatizaciya pereimenovaniya perenesla dva shablona v imena s okonchaniyem .shablon.txt. Soderzhimoye sovpalo s HEAD. Zagruzchik, avtonomnaya kopiya CLI i profilj ispoljzuyut novyiye imena; kontrakt proyekcii ne rasshiren. Regressiya vyizyivayet nastoyasjhij klassifikator dlya vsekh tryokh shablonov podderzhki.

## Svyazannyiye shagi

Ogranichennaya pravka vyipolnena v [etom etape](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/zapros.md); otdeljnogo nezavershyonnogo shaga dlya ispravleniya net.

## Kriterii zakryitiya

RED vosproizvodit neizvestnyiye formatyi; GREEN podtverzhdayet klassifikaciyu, avtonomnyij CLI i ostaljnyiye regressii. Bajtyi shablonov i rezuljtata sokhranyayutsya; novyij profilj uchityivayet oba novyikh imeni.

## Podtverzhdeniye ustraneniya

Pervyij test oshibochno ozhidal dva fajla vmesto tryokh i ne schitayetsya soderzhateljnyim RED. Ispravlennyij test vosproizvyol dva otkaza klassifikatora. Zatem proshli 57 testov. [Profilj](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/materialyi/profilj-shablonov.json) soderzhit novyiye puti s prezhnimi SHA; vkhod i rezuljtat sovpali s prezhnim profilem. Mediana 55,910 ms nizhe poroga issledovaniya 500 ms; daljnejshaya optimizaciya ne obosnovana. Polnaya priyomka obyyedineniya ostayotsya otdeljnoj granicej.

## Istochniki

- [Zapros](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/zapros.md) i [otchyot](../Zhurnal/2026-09-18_00-01-17_MSK_prinyatj-finansovyiye-paketyi-i-reyestr/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-18 00:32:28 MSK -->
<!-- content-sha256: sha256:262165e55a083d7ff19526e22d6bec23d781301698a8a4317cfb3804887c2c09 -->
<!-- FUM-MD-RECENCY:END -->
