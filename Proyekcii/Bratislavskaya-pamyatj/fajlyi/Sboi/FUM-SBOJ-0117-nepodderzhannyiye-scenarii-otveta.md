+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0117"
"статус" = "активна"
+++
# Scenarii otveta ne vkhodili v podderzhannyiye formatyi priyomki

## Nablyudayemyij sboj

Na tochnoj postavke `2e01e5dc9a130ea0fb2f6c10514d7db56817361b` sokhranenyi chetyire CJS-scenariya otveta, no prinimayusjhij inventarj i politika proyekcii podderzhivali toljko prezhnij tochnyij JS-adapter. Pri vozobnovlenii polnoj priyomki obe adresnyiye proverki zakryilisj na neizvestnom formate; postavka ne mogla projti vesj kontur bez dorabotki dopuska.

## Granica povtoreniya

Odin mekhanizm — novyij sobstvennyij ispolnyayemyij format vnesyon bez soglasovannogo prinimayusjhego sintaksisa, inventarya i politiki proyekcii. Dva otkaza otnosyatsya k odnomu proyavleniyu nesovmestimosti. Kontejner patcha iz FUM-SBOJ-0024, drejf chislennogo snimka iz FUM-SBOJ-0045 i oshibki chernovyikh RED-testov syuda ne obyyedinyayutsya.

## Proyavleniya

- `FUM-СБОЙ-0117/ПРОЯВЛЕНИЕ-0001`: v [proverke inventarya](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/materialyi/zapuski-proverok/1_2f1012ac-7c7e-4c89-81e6-30242a16e709.json) i [klassifikacii realjnogo CJS](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/materialyi/zapuski-proverok/3_47a24e2a-7cd4-48aa-93fb-a7db4606e439.json) poluchenyi zakryityiye otkazyi. Istochnik i konkretnaya diagnostika sokhranenyi v [otchyote](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/otchyot.md). Effekt — polnaya priyomka vyiyavlennoj postavki nedostupna. Vremennoye vosstanovleniye — otdeljnaya TDD-dorabotka prinimayusjhego kontura v svoyej vetke; neizvestnoye rasshireniye ne isklyuchalosj iz proverki.

- `FUM-СБОЙ-0117/ПРОЯВЛЕНИЕ-0002`: pri vosstanovlenii ACK-testa [proverka 11](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/11_70c04f4d-6ad2-4626-b7bf-462804dc2f73.json) otklonila vyichislyayemyij klyuch s prichinoj «Vyichislyayemyiye klyuchi ne podderzhanyi». Eto novaya konstrukciya vne zakreplyonnogo CJS-podyyazyika, a ne oshibka zasjhitnogo razbora. Zamena na podderzhannoye rasprostraneniye poluchennogo `первый.профиль` dala [nulevoj ostatok 12](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/12_296f8a83-3434-47dd-b588-7ef8d22bf0b8.json) i [funkcionaljnyij GREEN 14](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/14_60fbdc73-7bb0-4ce6-a9bf-138c7c51aaba.json). Podyyazyik ne rasshiryalsya i proverka ne oslablyalasj; mera rannego sopostavleniya novogo sintaksisa s prinimayusjhim konturom ostayotsya aktualjnoj.

## Ozhidaniye i klassifikaciya

Po pravilam yazyika novyij sobstvennyij sintaksis trebuyet rasshireniya inventarya do pervogo obyyavleniya, a postavka dolzhna vosproizvodimo prokhoditj primenimyiye proverki. Nablyudayemoye raskhozhdeniye — nedorabotka soglasovannosti postavki; validatoryi otkazali soglasno prezhnim politikam. Prezhnyaya otsrochka sovmestnoj priyomki obyyasnyayet vremya obnaruzheniya i ne delayet nekorrektnyim ikh otkaz.

## Mekhanizm i sistemnoye ustraneniye

Konechnaya mera svyazyivayet rovno chetyire puti, polnyij ogranichennyij razbor sobstvennyikh obyyavlenij i vneshnikh rolej, nezavisimuyu sintaksicheskuyu proverku Node, kontrakt i skhemu proyekcii, sokhraneniye bajtov i suffiksa, a takzhe proverennyij perekhod s polnoj zakreplyonnoj prezhnej politiki. Podgotovlenyi adresnyiye otricateljnyiye i polozhiteljnyiye testyi i profilj; vsya priyomka vetki yesjhyo ne zavershena. Neizvestnyiye sintaksisyi i puti ostayutsya zakryityimi.

## Svyazannyiye shagi

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — rannyaya proverka novyikh iskhodnikov; novoye osnovaniye FUM-SBOJ-0117/PROYAVLENIYE-0002.

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — priyomka postavki rabochego konteksta; osnovaniye svyazi `FUM-СБОЙ-0117/ПРОЯВЛЕНИЕ-0001`. Obratnaya svyazj dobavlena v istochniki shaga.

## Kriterii zakryitiya

Chetyire opublikovannyikh iskhodnika uchityivayutsya inventarizatorom s obyyasnyonnyimi sobstvennyimi i vneshnimi imenami; proyekciya sokhranyayet tochnyiye bajtyi i nezavisimo proveryayetsya. Neizvestnyij sosednij putj, nepodderzhannyij sintaksis, podmena vyikhoda i povrezhdyonnaya prezhnyaya politika zakryivayutsya. Primenimaya polnaya priyomka tochnoj postavki uspeshna, a sokhranyonnyiye regressii vosproizvodyat etu granicu. Odin zelyonyij adresnyij test i obnovlyonnyij obsjhij khyesh nedostatochnyi.

## Istochniki

- [Porucheniye i utochneniya oblasti](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/zapros.md).
- [Rezuljtat i ogranicheniya priyomki](../Zhurnal/2026-09-14_18-32-12_MSK_prinyatj-generaciyu-i-profilj-konteksta/otchyot.md).
- [Zakryityij format scenariyev](../Instrumentyi/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scenarii-otveta.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 12:56:44 MSK -->
<!-- content-sha256: sha256:c7dd07b0ca77ca3de4b6ea5edf3e85d14fde702e8a5b6a220706112c1b88a986 -->
<!-- FUM-MD-RECENCY:END -->
