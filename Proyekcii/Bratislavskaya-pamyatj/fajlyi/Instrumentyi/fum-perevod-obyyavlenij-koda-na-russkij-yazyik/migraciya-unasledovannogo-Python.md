# Migraciya unasledovannogo Python

Ogranichennaya postavka FUM-STEP-0173 sopostavlyayet 19 Python-putej iskhodnoj bazyi `c93b0fbca8c5d676eecec7023bc6df1a19c25b91` s reviziyej zakreplyonnogo snimka `436909208424595f7151f6febca75f89018c0bcb`. Ona ne perevodit vesj istoricheskij ostatok i ne prinimayet obsjhij khyesh repozitoriya.

## Proverennaya deljta

Prezhnij analizator nablyudal 352 dobavleniya: 340 sobstvennyikh zapisej, 10 vneshnikh metodov i dva novyikh prisvaivaniya uzhe susjhestvuyusjhikh privyazok. Vneshniye metodyi — vosemj `unittest.TestCase.setUp` i `HTMLParser.handle_starttag`/`handle_endtag`. `env` v prezhnej oblasti `run_steps` i `body_bytes` v `build_snapshot` povtorno prisvaivayutsya, poetomu dopolniteljnaya zapisj ne oznachayet novogo imeni.

Sdvig koordinat 1111 prezhnikh zapisej otdelyon ot novyikh imyon. Prezhnij `test_accepts_registered_local_swiftpm_composition` izvlechyon v russkuyu vspomogateljnuyu proverku i integracionnyij test. Rasshirennyij analiz dopolniteljno vyiyavil vosemj parametrov lambda i privyazok isklyuchenij. Otdeljno perevedyon sobstvennyij generator vnutri tochnoj stroki Python, peredavayemoj `-c` v teste kompleksnoj proverki.

Avtomatizirovannaya karta menyayet 14 unasledovannyikh fajlov i pyatj ssyilok odnogo neobkhodimogo zhivogo profilya. Itogovaya sverka 19 putej prezhnim i rasshirennyim analizatorami ostavlyayet toljko desyatj vneshnikh metodov i dva povtornyikh prisvaivaniya; neobosnovannyij sobstvennyij ostatok etoj gruppyi raven nulyu. [Mashinnaya sverka](../../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/materialyi/sverka-unasledovannoj-deljtyi.json) khranit tochnyiye revizii, khyeshi fajlov i sravneniye po vidu i imeni. Eto ne utverzhdeniye o nulevom ostatke vsego FUM.

Konechnyiye koordinatyi vneshnikh metodov peredayutsya prinimayusjhej rabote 0165. Povtornyiye zapisi staryikh privyazok sokhranyayut istoricheskij status. Obsjhij snimok obnovlyayetsya toljko posle obyyedinyonnoj klassifikacii obeikh rabot; yego prezhneye chislo 43163 etoj postavkoj ne zamenyayetsya.

## Vosproizvedeniye preobrazovaniya

V [karte](../../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/materialyi/karta-unasledovannogo-perevoda.json) zakreplenyi tochnyiye iskhodnyiye khyeshi, oblasti, russkiye imena i potrebiteli. [Prosmotrennyij plan](../../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/materialyi/plan-unasledovannogo-perevoda.json) imeyet SHA-256 `ab108a7b1d2361d2e55d36daae0d17a79eecaee9c6990394ed091448b3616b0d`.

V nezavisimom vremennom checkout iskhodnoj bazyi nuzhnyi aktualjnyiye iskhodniki perevodchika i fajlyi kartyi. Dlya zhivogo profilya do primeneniya kartyi dobavlyayutsya dve soderzhateljnyiye stroki zagruzki adaptera iz etoj postavki; yego iskhodnyij khyesh v karte uzhe vklyuchayet eto izmeneniye. Posle migracii povtornoye primeneniye iskhodnoj kartyi zakonomerno otkazyivayet po khyeshu: karta prednaznachena iskhodnomu snimku.

Iz kornya podgotovlennogo checkout:

```sh
python3 -B Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/пакет_перевода_python.py план --корень-репозитория . --карта Журнал/2026-09-14_20-41-53_MSK_перевести-унаследованные-привязки-Python/материалы/карта-унаследованного-перевода.json --выход <путь-к-плану>
```

Vmesto `<путь-к-плану>` ukazhi fajl plana vne checkout; vremennyij rezuljtat ne vklyuchayetsya v Git.

Posle sravneniya s prosmotrennyim planom ta zhe komanda s podkomandoj `применить` vyipolnyayet preobrazovaniye. V rabochej sessii pryamyiye proverki zapuskayutsya cherez otchyotnuyu obyortku.

## Istoricheskij profilj

Fajl `Журнал/2026-09-10_20-23-26_MSK_проверить-слияние-после-допуска/материалы/продвижение-до-оптимизации.py` sokhranyon pobajtno: 17446 bajt, SHA-256 `c8695da01383f3c131d8eb82dc9df90d43adbe7ebcbf54661349ec6199002fce`. Novyij [adapter](../fum-otchyotyi-o-zapuskakh-proverok/scripts/adapter_istoricheskogo_prodvizheniya.py) snachala proveryayet etot khyesh i vyidayot shestj pryamyikh ssyilok na izvestnyiye eksportyi i standartnyij modulj `subprocess` dlya schyotchika processov.

Fikstura ispoljzuyet pozicionnyiye argumentyi i neizmenyonnyij keyword `наблюдатель`; novyiye russkiye keyword dlya istoricheskikh funkcij ne obesjhayutsya. Adapter ne oborachivayet funkcii i sokhranyayet ikh `__globals__`. Yego sozdaniye i proverka khyesha isklyuchenyi iz izmeryayemogo intervala. Polnyiye regressii proveryayut nastoyasjhij migrirovannyij modulj: podmena eksportov adaptera ne menyayet vnutrenniye globaljnyiye ssyilki istoricheskikh funkcij.

Zhivoj profilj zapuskayetsya obyichnoj komandoj:

```sh
python3 -B Журнал/2026-09-10_20-23-26_MSK_проверить-слияние-после-допуска/материалы/измерить-продвижение.py
```

Semj chereduyusjhikhsya par i semanticheskoye sravneniye rezuljtatov sokhranenyi: medianyi 452,296 ms i 41 Git-process dlya istoricheskoj versii, 399,738 ms i 36 processov dlya migrirovannoj. Polucheniye eksportov cherez prostranstvo imyon adaptera ostayotsya chastjyu vyizovov fiksturyi; yego otdeljnaya stoimostj ne izmerena, nulevoj nakladnoj raskhod ne obesjhayetsya. V otdeljnom soglasovannom etape perevedenyi vse 45 obyichnyikh sobstvennyikh zapisej dvukh izmeritelej. [Karta](../../Zhurnal/2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/materialyi/karta-zhivyikh-izmeritelej.json) i [plan](../../Zhurnal/2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/materialyi/plan-zhivyikh-izmeritelej.json) zakreplyayut vkhodyi `d0ac3eea…`; khyesh plana — `0c6a7af55ac0b2c887e2e68bcc5a6f79e7f49dd24d611ffeae5f6ef6c6260668`. Oba scenariya posle perevoda proshli prezhniye proverki semantiki. Dva vneshnikh prisvaivaniya `subprocess.Popen` sokhranenyi. Zasjhisjhyonnyij before otdeljno soderzhit 116 istoricheskikh zapisej prezhnego skanera i pyatj dopolniteljno obnaruzhennyikh parametrov lambda/isklyuchenij.

## Polnyij effekt Python-skanera

Na odinakovyikh tekusjhikh bajtakh 252 Python-putej prezhnij i novyij analizatoryi dayut 16308 i 16594 zapisi: dobavleno 312, udaleno 26. Dobavleniya — 238 privyazok isklyuchenij, 71 parametr lambda i tri psevdonima importa. Dlya 307 zapisej najdenyi te zhe iskhodnyiye stroki, bajtovyiye stolbcyi, vidyi i imena v `436909…`; pyatj ostaljnyikh prinadlezhat tochnomu zasjhisjhyonnomu before iz postanovochnoj bazyi. Eto rasshireniye nablyudeniya starogo koda, ne vvod novyikh imyon i ne razresheniye polnogo istoricheskogo perevoda.

Vse 26 udalenij — vneshniye metodyi i privyazki delegiruyusjhikh metodov dejstviteljnyikh `ast.NodeVisitor`: 14 opredelenij i 12 prisvaivanij. Ikh realjnyiye klassyi, import `ast`, stroki i khyeshi sokhranenyi otdeljno. Svobodnaya funkciya `visit` libo metod klassa bez sootvetstvuyusjhej bazyi vneshnego isklyucheniya ne poluchayet.

[Konechnaya klassifikaciya 22 putej](../../Zhurnal/2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/materialyi/konechnaya-klassifikaciya-python.json) ostavlyayet nad rasshirennyim analizom revizii snimka: 121 zapisj zasjhisjhyonnogo before, 12 vneshnikh API i dva povtornyikh prisvaivaniya. Neobosnovannyij novyij ostatok soglasovannoj Python-gruppyi raven nulyu. Eto ne obnuleniye istoricheskogo ostatka FUM; obsjhij snimok prinimayet vladelec 0165 posle obyyedinyonnoj proverki.

[Komandyi vosproizvedeniya](../../Zhurnal/2026-09-14_21-49-30_MSK_perevesti-zhivyiye-izmeriteli-Python/materialyi/vosproizvedeniye-klassifikacii.md) sokhranenyi iz fakticheskikh zapuskov. Inventarj soderzhit kazhdyij Python-putj i yego SHA-256; proiskhozhdeniye svyazyivayet kazhdoye dobavleniye s tochnyim Git blob. Sravnivayutsya zapisi, a ne toljko summarnoye chislo.

## Profilj perevodchika

Profilj yadra do poslednego revjyu na prezhnem scenarii 400 funkcij dal medianu 118,545 ms. Dobavlennaya kompilyaciya i proverki razresheniya imyon rasshiryayut proveryayemuyu rabotu; eto ne zayavlyayetsya uskoreniyem otnositeljno kontroljnoj tochki. Sukhoj paket iz 15 fajlov dal medianu 592,380 ms na pyati povtorakh. Samaya dolgaya stadiya poslednego povtora — razbor boljshogo fajla testov kompleksnoj proverki, 153,564 ms iz 593,480 ms vsego paketa. Posle udaleniya neobosnovannogo dopuska pustogo slovarya i proverki effektivnyikh kollizij yadro dalo 107,596 ms, paket — 586,373 ms. Novyij paket pyatj raz vosproizvyol tochnyiye bajtyi okonchateljnogo plana `ab108a7b…`; iskhodnyiye fajlyi poluchenyi iz `c93b0fb…` s dvumya utverzhdyonnyimi strokami adaptera, vse vkhodnyiye khyeshi proverenyi do izmereniya. Korenj vyipolnyal povtoryi posledovateljno; nagruzka drugikh zadach khosta neizvestna. Po etomu ogranichennomu vkhodu daljnejsheye uslozhneniye algoritma ne obosnovano; realizaciya sokhranena. Raznostj etikh korotkikh zamerov ne obyyavlyayetsya uskoreniyem. Izmereniya i tochnyiye khyeshi versij nakhodyatsya v [materialakh etapa](../../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/materialyi).

Posle utochneniya lokaljnoj raspakovki i dvukh yavnyikh kontraktov zhivyikh profilej konechnoye yadro dalo 114,463 ms na tom zhe scenarii; sukhoj paket dvukh izmeritelej — 12,435 ms na pyati posledovateljnyikh povtorakh. Eto malyij ogranichennyij vkhod; izmereniya ne obosnovali daljnejshego izmeneniya algoritma. Staryij 15-fajlovyij plan dopolniteljno vosproizvedyon pobajtno etim zhe yadrom.

Prezhnyaya sopostavimaya trojka profilej poiska obyyavlenij sokhranyayetsya: 270,325 → 91,260 → 94,567 ms. Fajl `профиль-до.json` pervogo etapa otnositsya k drugomu scenariyu i v etu paru ne vkhodit. Bajtyi baseline do optimizacii vosstanovlenyi obratnyim primeneniyem izvestnyikh tochnyikh pravok; do sokhraneniya podtverzhdyon raneye zafiksirovannyij SHA-256 `7a796a362c6525ff88399f26ae7bb6e25df91108c534a8df92709fb764aee551`. Eto istoricheskij izmeriteljnyij iskhodnik s izvestnyimi pozdneye ispravlennyimi ogranicheniyami, a ne dopusjhennyij perevodchik realjnyikh fajlov.

Izmerennaya karta sokhranena otdeljno kak `карта-пакета-при-измерении.json` i sovpadayet s khyeshem profilya. Karta primeneniya otlichayetsya ot neyo toljko utochneniyem russkogo imeni parametra odnoj lambda; eto ne izmeneniye algoritma i ne osnovaniye zayavleniya novogo uskoreniya.

Dlya povtoreniya baseline iz chistogo klona iskhodniki scenariya i istoricheskogo helper razmesjhayutsya vo vremennoj izolirovannoj strukture. Tak scenarij vyichislyayet khyesh imenno ispoljzuyemogo helper:

```python
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

корень = Path.cwd()
исходник = корень / 'Журнал/2026-09-14_20-41-53_MSK_перевести-унаследованные-привязки-Python/материалы/безопасные-привязки-до-оптимизации.py'
сценарий = корень / 'Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/tests/измерить_безопасный_перевод_python.py'
with tempfile.TemporaryDirectory() as каталог:
    временный = Path(каталог)
    (временный / 'scripts').mkdir()
    (временный / 'tests').mkdir()
    shutil.copyfile(исходник, временный / 'scripts/безопасные_привязки_python.py')
    запуск = временный / 'tests/измерить_безопасный_перевод_python.py'
    shutil.copyfile(сценарий, запуск)
    subprocess.run([sys.executable, '-B', str(запуск), '--выход', str(корень / 'повтор-исходного-профиля.json')], check=True)
```

Proverochnyij povtor baseline podtverdil ravenstvo khyeshej iskhodnika, vkhoda, rezuljtata i scenariya. On vyipolnyalsya odnovremenno s adresnoj proverkoj sovmestimosti, poetomu yego dliteljnostj 285,360 ms ne ispoljzuyetsya dlya sravneniya skorosti.

Blok vyipolnyayetsya cherez `python3 -` libo sokhranyayetsya vo vremennyij fajl. Vyikhod `повтор-исходного-профиля.json` yavlyayetsya rezuljtatom lokaljnogo zapuska i avtomaticheski v Git ne dobavlyayetsya.

## Istochniki

- [Postanovka FUM-STEP-0173](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0173-razobratj-drejf-snimka-obyyavlenij.md).
- [Razrabotka i rezuljtatyi etapa](../../Zhurnal/2026-09-14_20-41-53_MSK_perevesti-unasledovannyiye-privyazki-Python/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 23:50:17 MSK -->
<!-- content-sha256: sha256:f81efa097b75702a2e738190d4ef75b251ccec1a976850688f32c2c34a4d87d9 -->
<!-- FUM-MD-RECENCY:END -->
