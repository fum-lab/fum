---
name: fum-perevod-obyyavlenij-koda-na-russkij-yazyik
description: Inventariziruyet latinskiye sobstvennyiye obyyavleniya v Python, Swift i Mermaid, proveryayet tochnyij snimok ostatka i po yavno proverennoj karte bezopasno perevodit identifikatoryi na russkij yazyik. Ispoljzuj dlya kontrolya pravila russkikh obyyavlenij i dlya mekhanicheskogo pereimenovaniya bez zatragivaniya strok, kommentariyev i doslovnyikh materialov.
---

# Perevod obyyavlenij koda na russkij yazyik

Avtomatizaciya pomogayet posledovateljno perevesti sobstvennyij kod FUM i zatem ne dopuskatj novogo latinskogo ostatka. Ona otdelyayet nablyudeniye ot izmeneniya: inventarizaciya i proverka snimka nichego ne menyayut, `план` polnostjyu proveryayet kartu i pokazyivayet budusjhij rezuljtat bez zapisi, a `применить` povtoryayet te zhe proverki do pervoj zamenyi.

Instrument ne pridumyivayet russkiye imena i ne obnovlyayet snimok samovoljno. Smyisl kazhdogo imeni opredelyayet chelovek ili agent po kontekstu fajla, a karta pereimenovanij sluzhit yavnyim proveryayemyim resheniyem.

## Oblastj pravila

Inventarj rassmatrivayet toljko sobstvennyiye fajlyi `.py`, `.swift` i `.md`:

- dlya Python sintaksicheskoye derevo dayot klassyi, obyichnyiye i asinkhronnyiye funkcii, parametryi, imena v kontekste zapisi i zapisyivayemyiye atributyi;
- dlya Swift leksicheskij razbor vne strok i kommentariyev dayot tipyi, funkcii, `let`, `var`, variantyi `case`, parametryi funkcij i yavnyikh signatur zamyikanij;
- dlya Markdown rassmatrivayutsya identifikatoryi uzlov toljko v sobstvennyikh ograzhdyonnyikh blokakh `mermaid`; podpisi, stroki, kommentarii i tekst vne bloka ne yavlyayutsya kodom dlya pereimenovaniya.

Iz ostatka isklyuchenyi vneshniye obyazateljnyiye obyyavleniya Python: specialjnyiye imena s dvumya podchyorkivaniyami, tochnyiye metodyi posetitelya sintaksicheskogo dereva i obyazateljnyij prefiks `test_` pered russkim imenem testa. Eto uzkiye isklyucheniya vneshnego interfejsa, a ne razresheniye vvoditj proizvoljnyiye latinskiye imena.

Obkhod polnostjyu isklyuchayet `.git`, `.build`, `.swiftpm`, katalogi kyeshej, `Зависимости`, `Источники`, simvolicheskiye ssyilki i kornevoye proizvodnoye prostranstvo istoricheskikh worktree `Подузлы/`. Komponent `Подузлы` nizhe drugogo kanonicheskogo kornya sam po sebe ne isklyuchayetsya: granica privyazana toljko k pervomu komponentu repo-relative-puti. V Markdown ne analiziruyutsya doslovnyij `Текст запроса` v zhurnaljnom `запрос.md`, `Снимок Git` i razdel `Вопрос` v `Вопросы и ответы`. Oshibka sintaksisa, kodirovki ili nezakryitaya ograda zavershayet proverku otkazom.

## Inventarizaciya

Iz kornya checkout vyipolni:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py инвентаризировать --корень-репозитория .
~~~

Komanda pechatayet determinirovannyij kanonicheskij JSON skhemyi `1`:

~~~json
{
  "версия_схемы": 1,
  "объявления": [
    {
      "вид": "функция",
      "имя": "old_name",
      "путь": "Инструменты/пример.py",
      "столбец": 1,
      "строка": 3,
      "язык": "python"
    }
  ]
}
~~~

Poryadok zapisej stabilen i vkhodit v kontrakt snimka. Pustoj massiv oznachayet otsutstviye nablyudayemogo latinskogo ostatka v podderzhannoj oblasti, no ne zamenyayet soderzhateljnoye revjyu imyon.

## Tochnyij snimok ostatka

Snimok sozdayotsya ili obnovlyayetsya toljko yavnoj komandoj posle prosmotra inventarya. On ne dubliruyet desyatki tyisyach zapisej: khranit SHA-256 kanonicheskogo polnogo inventarya, obsjheye chislo i svodku po yazyikam:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py обновить-снимок --корень-репозитория . --снимок <путь-к-снимку>
~~~

~~~json
{
  "версия_схемы": 1,
  "объявлений": 43362,
  "отпечаток_инвентаря": "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "по_языкам": {
    "mermaid": 469,
    "python": 16359,
    "swift": 26534
  }
}
~~~

Zapisj snimka prokhodit cherez vremennyij fajl v tom zhe kataloge, sinkhronizaciyu soderzhimogo i atomarnuyu zamenu. Obyichnaya proverka ne sozdayot iskhodnyij urovenj i ne prinimayet novyij ostatok:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py проверить --корень-репозитория . --снимок <путь-к-снимку>
~~~

`проверить` zanovo stroit polnyij inventarj i trebuyet tochnogo sovpadeniya yego otpechatka i svodnyikh chisel so snimkom. Lyuboye dobavleniye, udaleniye, peremesjheniye ili izmeneniye pozicii nablyudayemogo obyyavleniya dayot nenulevoj kod zaversheniya.

## Karta pereimenovanij

Karta skhemyi `1` perechislyayet toljko vyibrannyiye fajlyi. Dlya kazhdogo fajla zakreplyayutsya otnositeljnyij putj, khyesh tochnyikh iskhodnyikh bajtov i nepustoye sootvetstviye staryikh imyon novyim:

~~~json
{
  "версия_схемы": 1,
  "файлы": [
    {
      "путь": "Инструменты/пример.py",
      "ожидаемый_хэш": "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "переименования": {
        "old_name": "старое_имя"
      }
    }
  ]
}
~~~

Dopustimoye novoye imya yavlyayetsya identifikatorom, soderzhit kirillicu i ne soderzhit latinicu; yedinstvennoye isklyucheniye — obyazateljnyij tekhnicheskij prefiks obnaruzheniya testa `test_` pered polnostjyu russkoj smyislovoj chastjyu. Instrument otklonyayet neizvestnyiye i povtornyiye polya JSON, povtor puti, vyikhod iz kornya, simvolicheskuyu ssyilku, nepodderzhannyij tip fajla, nevernyij khyesh, staroye imya bez nablyudayemogo obyyavleniya, povtor novogo imeni i kolliziyu s uzhe susjhestvuyusjhim identifikatorom fajla.

## Plan i primeneniye

Snachala vsegda vyipolni sukhoj progon:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py план --корень-репозитория . --карта <путь-к-карте>
~~~

Rezuljtat soderzhit iskhodnyij i budusjhij khyeshi, kazhduyu paru imyon i chislo tokenovyikh zamen. Fajlyi pri etom ne zapisyivayutsya. Prosmotri plan i toljko zatem primeni tu zhe kartu:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py применить --корень-репозитория . --карта <путь-к-карте>
~~~

Do pervoj zapisi instrument chitayet i proveryayet vsyu kartu, vse iskhodnyiye khyeshi, obyyavleniya i kollizii, stroit polnyij novyij tekst kazhdogo fajla i sozdayot vremennyiye fajlyi ryadom s celyami. Neposredstvenno pered zamenoj on snova sveryayet vse iskhodnyiye khyeshi. Kazhdyij celevoj fajl zamenyayetsya atomarno s sokhraneniyem yego rezhima dostupa; stroki, kommentarii, podpisi Mermaid i obyichnyij Markdown ostayutsya netronutyimi. Fajlovaya sistema ne predostavlyayet obsjhej tranzakcii dlya neskoljkikh putej, poetomu avariya operacionnoj sistemyi mezhdu atomarnyimi zamenami raznyikh fajlov trebuyet sverki vyidannogo plana i tekusjhikh khyeshej pered povtorom.

Posle primeneniya zapusti otnosyasjhiyesya k izmenyonnomu kodu proverki, povtori inventarizaciyu i obnovlyaj snimok toljko kak otdeljnoye osmyislennoye izmeneniye ozhidayemogo ostatka.

## Proverka avtomatizacii

Avtonomnyij nabor ne ispoljzuyet setj, sekretyi ili soderzhimoye rabochego repozitoriya:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/tests -p 'test_*.py'
~~~

Testyi proveryayut inventarj tryokh yazyikov, zasjhisjhyonnyiye oblasti, tochnyij snimok, sukhoj plan, tokenovyiye zamenyi bez strok i kommentariyev, syiryiye podpisi Mermaid, khyeshi, russkiye imena, kollizii i otsutstviye latinskikh sobstvennyikh obyyavlenij v samom instrumente.

## Istochnik trebovaniya

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-08-04 12:51:44 MSK — Perevesti obyyavlyayemyij kod na russkij yazyik](../../Zhurnal/2026-08-04_12-51-44_MSK_perevesti-obyyavlyayemyij-kod-na-russkij-yazyik/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-23 12:13:25 MSK -->
<!-- content-sha256: sha256:80989375618708d8f5b40ec3ba078fb74524adb88251f35777d10398ca613a3e -->
<!-- FUM-MD-RECENCY:END -->
