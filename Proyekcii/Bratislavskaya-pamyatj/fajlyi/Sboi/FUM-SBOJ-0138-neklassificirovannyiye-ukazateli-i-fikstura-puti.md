+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0138"
"статус" = "активна"
+++
# Neklassificirovannyiye ukazateli i fikstura puti

## Nablyudayemyij sboj

Pervyij standartnyij progon ostanovilsya na shage 6 proverki mashinno-lokaljnyikh putej. Vosemj strok dvukh JSON Pointer i odna stroka otkryitoj absolyutnoj fiksturyi ne imeli tochnyikh deklaracij dejstvuyusjhej politiki. Poljzovateljskikh putej v etikh strokakh net.

## Granica povtoreniya

Podgotovka novogo soderzhimogo propuskayet tipizirovannuyu klassifikaciyu strok, pokhozhikh na mashinno-lokaljnyiye puti. Dva proyavleniya razdelenyi po roli: opredeleniye adresov polej JSON i obezlichennaya testovaya fikstura. Eto ne raskryitiye privatnogo adresa i ne osnovaniye oslabitj obsjhij skaner.

## Proyavleniya

### FUM-SBOJ-0138/PROYAVLENIYE-0001

[Otkaz 17](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/17_5a8c413a-01b9-4bd6-8350-e55f85ef8183.json) soderzhit vosemj strok s dvumya tochnyimi JSON Pointer v kodeke, opredelenii i Node-teste. [Diagnostika](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/diagnostika-putej.json) sokhranyayet adresa strok, kategorii i khyesh iskhodnogo zhurnala. Dejstvuyusjhaya politika uzhe ispoljzuyet `allow.path-validation-definition` dlya JSON Pointer. Shtatnyij updater dobavil tochnyiye deklaracii opredelenij; testovyiye stroki klassificirovanyi `allow.test-fixture`.

### FUM-SBOJ-0138/PROYAVLENIYE-0002

Tot zhe otkaz 17 soderzhit odnu obezlichennuyu absolyutnuyu stroku Python-fiksturyi, ispoljzuyemuyu dlya proverki obratimosti i byudzheta. Ona poluchila otdeljnuyu `allow.test-fixture` s sobstvennyim khyeshem stroki i soderzhateljnoj prichinoj. Pervonachaljnaya obsjhaya prichina oshibochno nazyivala yeyo Pointer; do proverki ona zamenena shtatnyim v2-retirement i novoj tochnoj deklaraciyej. Dannyiye poljzovatelya ne ispoljzovanyi.

### FUM-SBOJ-0138/PROYAVLENIYE-0003

[Povtornyij otkaz 20](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/20_9ad33ebd-3291-4dd6-a1bc-40dff724adca.json) za 385,823750417 s vyiyavil odnu novuyu stroku v JSON-proiskhozhdenii: pozdnyaya komanda koordinatora produblirovala obezlichennyij primer posle adresnoj proverki 18. Vse devyatj raneye klassificirovannyikh strok proshli. Polnyij tekst komandyi ostayotsya v razdele `Текст запроса`; JSON khranit koordinatyi iskhodnoj zapisi i khyeshi zapisi i tochnogo teksta, bez dublirovaniya. Eto novyij khvost vkhoda posle rannego skanera, ne izmeneniye izmerennogo koda. Prezhneye ogranichennoye vosstanovleniye 18 ne pokryivalo pozdnyuyu zapisj.

## Ozhidaniye i klassifikaciya

Novyiye semanticheski dopustimyiye opredeleniya i otkryityiye fiksturyi dolzhnyi imetj tochnyiye tipizirovannyiye deklaracii do dorogoj priyomki. Zasjhitnyij otkaz sootvetstvuyet dejstvuyusjhej politike; nedorabotka — propusk podgotovki yeyo konechnogo vkhoda. Nomer 0138 zarezervirovan koordinatorom 01a07d3d-d376-7ad2-aafc-67e4c25a67eb posle sverki obeikh rabochikh oblastej.

## Mekhanizm i sistemnoye ustraneniye

Dobavlenyi devyatj deklaracij shtatnyim updater s tochnyimi putyom, khyeshem stroki, chislom sovpadenij i kategoriyej. Neizvestnyiye sosedniye stroki ostayutsya narusheniyami, izmeneniye zakreplyonnoj stroki trebuyet novoj sverki. Kod skanera i semj iskhodnikov itogovogo izmereniya ne menyalisj. [Adresnyij povtor 18](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/18_791cca5d-4e04-466f-ac45-16f2c89a4f38.json) zavershilsya kodom 0; povtornyij profilj ne nuzhen pri neizmennyikh izmerennyikh bajtakh.

## Svyazannyiye shagi

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — novoye osnovaniye FUM-SBOJ-0138/PROYAVLENIYE-0003: zaklyuchiteljnyij skaner dolzhen uchityivatj pozdniye istochniki, a yego snimok sokhranyatjsya do polnoj priyomki.

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — osnovaniya FUM-SBOJ-0138/PROYAVLENIYE-0001 i FUM-SBOJ-0138/PROYAVLENIYE-0002. Rannyaya proverka novyikh Pointer i fikstur vklyuchena v priyomku ogranichennoj peredachi.

Nablyudeniye 0003 vozvrasjhayet kartochku v aktivnoye sostoyaniye. Trebuyetsya povtoryayemoye podtverzhdeniye otsutstviya pozdnego soderzhateljnogo khvosta mezhdu zaklyuchiteljnyim skanirovaniyem i priyomkoj. Razovaya ochistka JSON i novyij uspeshnyij skaner vosstanavlivayut tekusjhij vkhod, no ne dokazyivayut obsjhuyu meru.

## Kriterii zakryitiya

Vse devyatj nablyudyonnyikh strok klassificirovanyi po fakticheskoj roli tochnoj politikoj, bez obsjhej ljgotyi katalogu ili formatu. Polnyij adresnyij skaner vozvrasjhayet 0, iskhodnyiye dannyiye i iskhodniki izmereniya sokhranenyi, prezhnij otkaz ostayotsya dostupen.

## Istoricheskoye podtverzhdeniye ogranichennogo vosstanovleniya

Adresnyij povtor 18 proshyol; JSON Pointer i fikstura razlichenyi, deklaracii imeyut devyatj otdeljnyikh tochnyikh selektorov. Podtverzhdeno ogranichennoye vosstanovleniye etikh vkhodov. Obsjhaya podderzhka proizvoljnogo JSON Pointer i polnaya priyomka vsego etapa etoj kartochkoj ne zayavlyayutsya.

## Istochniki

- [Iskhodnyiye komandyi i rezerv](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/zapros.md).
- [Otchyot](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/otchyot.md) i [diagnostika](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/diagnostika-putej.json).
- [Tipizirovannaya politika](../Instrumentyi/fum-proverka-mashinno-lokaljnyikh-putej/policy.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 13:19:48 MSK -->
<!-- content-sha256: sha256:b46e860f088efe55bc8ba7a5b1fe02ec5305d9e6d5b40f7290f20cfbda4f8609 -->
<!-- FUM-MD-RECENCY:END -->
