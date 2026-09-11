+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0051"
"статус" = "устранена"
+++
# Nepolnyij perechenj zatronutyikh fajlov zaprosa

## Nablyudayemaya problema

Shablon stroiteljnogo etapa dobavil soderzhateljnoye izmeneniye napravleniya 08, no razdel «Povliyal na fajlyi» perechislil kartochki, trebovaniya i reyestr bez samogo napravleniya. Korrektnaya proverka svyaznosti ostanovila kommit soobsjheniyem `unexpected Git status path: Планирование/направления-проектирования-и-развития/08-физические-и-дальние-контуры.md`.

## Proyavleniya

| Nomer                           | Svideteljstvo                                                                                                                                                                                                 | Effekt                                                 | Vosstanovleniye                                                                                                                                                                             |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0001` | [Polnaya adresnaya sverka iskhodnogo i vosstanovlennogo spiska](../Zhurnal/2026-09-11_01-27-07_MSK_zaplanirovatj-stroiteljnoye-napravleniye/materialyi/zapuski-proverok/6_7977a3a9-4582-479e-91bc-3888bf67af03.json) | Podgotovlennaya kontroljnaya tochka otklonena do kommita. | Poluchitj polnyij fakticheskij Git-perechenj, sopostavitj s naznachennoj oblastjyu i razdelom zaprosa, dobavitj propusjhennyij razreshyonnyij katalog napravlenij, povtoritj proverku polnogo perechnya. |

## Mekhanizm i granica

Prichina — nepolnyij perechenj oblasti v shablone zaprosa pri perekhode ot otdeljnyikh kartochek k svodnomu napravleniyu. Oshibka svyaznosti ili vyikhod izmeneniya za soglasovannyij obyyom ne ustanovlenyi. Eta granica otlichayetsya ot FUM-SBOJ-0035: tam otsutstvuyusjhij udalyonnyij putj treboval specialjnogo markera; zdesj propusjhen susjhestvuyusjhij izmenyonnyij dokument.

## Vosproizvodimoye ogranichennoye vosstanovleniye

1. Poluchitj polnyij tekusjhij perechenj komandoj `git -c core.quotepath=false status --short` v tochnom korne zadachi; ne vyivoditj yego iz zaraneye perechislennyikh shablonom katalogov.
2. Sopostavitj kazhdoye soderzhateljnoye izmeneniye s iskhodnoj komandoj i razdelom «Povliyal na fajlyi». Ispoljzovatj `affected_files_from_request` i `validate_git_status` susjhestvuyusjhej proverki svyaznosti; poslednemu peredatj `None` tretjim argumentom dlya chteniya vsego tekusjhego Git-sostoyaniya.
3. Dlya namerennogo izmeneniya napravleniya dobavitj tochnuyu ssyilku na dokument libo susjhestvuyusjhij tematicheskij katalog. Ne rasshiryatj oblastj do vsego checkout i ne obyyavlyatj postoronniye izmeneniya razreshyonnyimi.
4. Povtoritj proverku vsego fakticheskogo perechnya, zatem svezhestj, indeks i nezavisimuyu svyaznostj kontroljnoj tochki. Izmenyonnyij posle sverki snimok proveryatj zanovo.

Adresnyij zapusk vosproizvyol yedinstvennyij iskhodnyij otkaz polnogo perechnya, proveril tochnuyu dobavku v pamyati i otsutstviye neobyyavlennyikh izmenenij posle neyo. Dve susjhestvuyusjhiye regressii podtverdili prinyatiye susjhestvuyusjhikh potomkov i otkloneniye sosednego puti, pokhozhego prefiksa i neukazannogo udaleniya. Proverochnyij kod ne izmenyalsya.

## Kriterij i predel zakryitiya

`Устранена` oznachayet proveryayemoye ogranichennoye vosstanovleniye nepolnogo spiska cherez polnyij Git-perechenj i sokhranyonnuyu otricateljnuyu granicu. Eto ne obesjhaniye nevozmozhnosti novogo propuska agentom i ne strogaya priyomka vsej vetki. Razovyij uspeshnyij povtor bez opisannoj sverki etogo kriteriya ne vyipolnyayet.

## Istochniki

- [Tekusjhij zapros](../Zhurnal/2026-09-11_01-27-07_MSK_zaplanirovatj-stroiteljnoye-napravleniye/zapros.md).
- [Otchyot vosstanovleniya](../Zhurnal/2026-09-11_01-27-07_MSK_zaplanirovatj-stroiteljnoye-napravleniye/otchyot.md).
- [Kontrakt svyaznosti](../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md).
- [Inaya granica otsutstvuyusjhego udalyonnogo puti](FUM-SBOJ-0035-propusk-udalyonnogo-puti-proyekcii-v-zaprose.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:37:18 MSK -->
<!-- content-sha256: sha256:763809376ccddcbec975951630261e28ac85325cbe4b484db6b929f509d1b59c -->
<!-- FUM-MD-RECENCY:END -->
