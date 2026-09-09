---
name: fum-snimki-indeksa
description: Proveryatj zakryityij vkhod pervogo raunda po syiryim obyyektam zakreplyonnogo Git tree bez dopuska ispolneniya ili kommita.
---

# Snimki indeksa

Instrument realizuyet pervyij ogranichennyij segment FUM-STEP-0155. Rezuljtat uspeshnogo chteniya — podtverzhdyonnyiye syiryiye bajtyi i struktura vkhodnyikh manifestov. Polya `исполнение_разрешено` i `коммит_разрешён` vsegda ravnyi `false`. Komanda `допустить` vsegda otkazyivayet, poskoljku ocheredj dostavki i svyazj otmenyi s dopuskom yesjhyo ne realizovanyi.

Ispoljzovatj toljko kanonicheskij instrument tekusjhego checkout. Skhema `fum.вход-снимка.1` otdeljna ot run-v4/report-v3. Realjnyij indeks FUM etim segmentom ne prinimalsya. Imya instrumenta zaregistrirovano v obsjhikh reyestrakh; soglasovaniye dejstvuyusjhego dopuska i podklyucheniye priyomochnogo kontura ostayutsya za koordinatorom.

## Rabota s vkhodom

Vse komandyi poluchayut tochnyij fizicheskij korenj repozitoriya. Podkatalog, simvolicheskaya ssyilka vmesto kornya, sokrasjhyonnyij OID i imya ref vmesto OID ne prinimayutsya.

- `scripts/снимки-индекса.py --корень-репозитория <корень> подготовить-дерево --ожидаемый-коммит <полный OID> --ожидаемая-ветка <refs/heads/...> --разрешить-запись-объектов` vyipolnyayet otdeljnuyu mutaciyu cherez `git write-tree`. Ona mozhet obnovitj cache-tree indeksa, sozdayot Git-obyyektyi i ne razreshayet ispolneniye.
- `... ссылка --дерево <полный OID> --путь <точный относительный путь>` toljko chitayet i vozvrasjhayet ssyilku na blob s dlinoj i SHA-256.
- `... проверить --вход <файл> --конверт <файл> --реестр <каталог> --ожидаемый-коммит <полный OID> --ожидаемая-ветка <ref>` toljko chitayet. Zapisj, konvert i reyestr nakhodyatsya vne proveryayemogo checkout. Neobyazateljnyij `--зависимости <файл>` prinimayet lokaljnuyu kartu tochnyikh putej gitlink na fizicheskiye korni ikh repozitoriyev.
- `... зарегистрировать` prinimayet te zhe parametryi, polnostjyu proveryayet vkhod i zatem otdeljno sokhranyayet yego identichnostj UUID v lokaljnom reyestre. Eto ne zakryitiye raunda i ne dopusk.
- `... экспортировать --источник <локальный JSONL> --задача <UUID> [--курсор <файл>] [--закрепить]` vyidayot lokaljnyij sostavnoj otvet s polyami `экспорт` i `локальная_квитанция`. V derevo pomesjhayut toljko kanonicheskiye bajtyi polya `экспорт`; kvitanciyu ostavlyayut vne publichnogo checkout. Flag `--закрепить` vosproizvodit prezhnyuyu granicu, dazhe yesli istochnik uzhe dopisan.

Kanonicheskoye kodirovaniye i sozdaniye konverta dostupnyi v `scripts/канон.py`. Primer polnogo sinteticheskogo vkhoda vosproizvodit `tests/фикстуры.py`; on ne obrasjhayetsya k indeksu FUM. Vse sobstvennyiye manifestyi opisanyi v [kontrakte](kontrakt.md).

## Proverka i profilj

Zavisimosti — Python so standartnoj bibliotekoj i Git s `GIT_NO_LAZY_FETCH`; proverennaya sreda ukazana v zhurnaljnom profile. Testyi rabotayut bez seti. Promisor-fikstura ispoljzuyet toljko sobstvennyij lokaljnyij vremennyij remote i dokazyivayet, chto obyichnyij Git dejstviteljno popyitalsya byi zagruzitj otsutstvuyusjhij obyyekt.

Pryamyiye proverki v FUM zapuskatj cherez dejstvuyusjhuyu `fum-otchyotyi-o-zapuskakh-proverok` so svoim tochnyim zaprosom, klassom `адресная` i v4-istoriyej. Dochernyaya komanda nabora:

```bash
python3 -m unittest discover -s Инструменты/fum-snimki-indeksa/tests -p 'test_*.py' -v
```

Povtoryayemyij profilj i sravneniye tekh zhe vkhodnyikh i vyikhodnyikh bajtov:

```bash
python3 Инструменты/fum-snimki-indeksa/tests/профилировать.py --размеры 1,100,1000
python3 Инструменты/fum-snimki-indeksa/tests/профилировать.py --размеры 1,100,1000 --сравнить <предыдущий-профиль.json>
```

Profilj sokhranyayet versii Python/Git, khyeshi iskhodnikov, razmeryi fikstur, otdeljnoye vremya podgotovki i chteniya, vlozhennyiye metki s iskhodom. Vlozhennyiye dliteljnosti ne skladyivayutsya. Sravneniye izmeryayet konkretnyij scenarij s povtoryayusjhimisya blob i ne obesjhayet takoye zhe uskoreniye dlya vsekh repozitoriyev.

## Ogranicheniya

Podderzhan toljko pervyij raund s `предыдущая_квитанция: null`. Vsya oblastj `.fum-приёмка` zarezervirovana i zapresjhena vo vkhode, vklyuchaya Unicode-ekvivalentnyiye variantyi. Istoricheskiye zapisi drugikh raundov v etoj oblasti poka tozhe ne podderzhanyi.

Proiskhozhdeniye vsekh listjyev obyyavlyayetsya kak neprozrachnyiye zakreplyonnyiye bajtyi bez proizvodyasjhikh ryober. Obratnyiye ssyilki v izvestnyikh skhemakh otvergayutsya; proizvoljnyij iskhodnyij kod ne ispolnyayetsya i yego soderzhateljnaya nezavisimostj ne obyyavlyayetsya dokazannoj. Proizvodnyiye uzlyi i generatoryi trebuyut sleduyusjhej versii.

JSONL-adapter podderzhivayet rovno odno tekstovoye soderzhimoye poljzovateljskoj komandyi s `content_item_kinds: ["user.text"]` i vidimyiye otvetyi `response_item`. On sokhranyayet povtoryi i poryadok; `event_msg` ne ispoljzuyetsya kak dubliruyusjhij istochnik. Izvestnyiye instrukcii sredyi propuskayutsya. Neizvestnyiye vidyi i sostavnyiye soobsjheniya, vklyuchaya tekst s izobrazheniyem, dayut otkaz. Poetomu polnyij tekusjhij dialog koordinatora s muljtimodaljnoj komandoj poka celikom ne podderzhivayetsya. Otbor publikacionno dopustimogo teksta i obrabotka pozdnej otmenyi ne avtomatizirovanyi.

Gitlink proveryayetsya po tochnomu commit/tree i polnomu manifestu syiryikh fajlov otdeljnogo repozitoriya. Zhivyiye gryaznyiye bajtyi zavisimosti ne ispoljzuyutsya i ne obyyavlyayutsya proverennoj materializaciyej. Vlozhennyiye gitlink, symlink i nestandartnyiye rezhimyi ne podderzhanyi. Arkhiv proveryayetsya kak neprozrachnyij blob, bez raspakovki.

Reyestr zasjhisjhayet ot povtornogo UUID s drugimi bajtami toljko v peredannom polnom doverennom lokaljnom kataloge. Udaleniye reyestra, zamena yego celikom libo vyibor pustogo kataloga ne dokazyivayut novuyu istoriyu. Povtornyiye proverki putej obnaruzhivayut nablyudayemuyu podmenu, no ne sozdayut atomarnoj zasjhityi ot obkhodyasjhego protokol pisatelya. Razdeljnyiye chteniya HEAD/ref takzhe ne dayut atomarnoj garantii. Materializaciya ispolneniya, konechnaya deljta, dolgovechnoye zakryitiye, publikaciya rezuljtata i tochnyij kommit ostayutsya sleduyusjhimi segmentami.

## Istochniki

- [Zapros i granica zapisi](../../Zhurnal/2026-09-09_12-51-11_MSK_realizovatj-vkhod-snimka-indeksa/zapros.md).
- [Otchyot s RED/GREEN i profilem](../../Zhurnal/2026-09-09_12-51-11_MSK_realizovatj-vkhod-snimka-indeksa/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 13:56:30 MSK -->
<!-- content-sha256: sha256:a5d9bdc7f30258a5354cbbc8a727bf1d1f52745d49fcd85c82f1e056d365bdd6 -->
<!-- FUM-MD-RECENCY:END -->
