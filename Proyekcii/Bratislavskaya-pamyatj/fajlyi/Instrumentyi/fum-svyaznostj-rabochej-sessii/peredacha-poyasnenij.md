# Yavnaya peredacha povtoryayemyikh poyasnenij

Versiya `пояснения-1` vyinosit toljko tochnyiye znacheniya `полный_снимок.формат` i `граница`. Po umolchaniyu CLI i adapter vozvrasjhayut prezhneye predstavleniye. Novaya versiya eksperimentaljnaya: izmerennoye umenjsheniye otveta ne okupilo opredeleniye, konvert i podtverzhdeniya v polnom obmene.

## Vyibor i granica

K obyichnyim parametram [CLI](scripts/pokazatj-otvet-zadachi.py) dobavlyayutsya `--версия-передачи пояснения-1`, `--передача-пояснений <UUID>` i neobyazateljnyij `--подтверждение-пояснений <JSON>`. Vyibor nezavisim ot `--профиль прежний|порождённый`. U [Node-adaptera](scripts/adapter_otveta.cjs) sootvetstvuyusjhiye parametryi nazyivayutsya `версия_передачи`, `передача_пояснений` i `подтверждение_пояснений`; podtverzhdeniye peredayotsya obyyektom kazhdogo vyizova.

Konvert `fum.передача-ответа.1` soderzhit `передача`, `форма`, `данные`, `профиль` i `определение`. V polnoj forme `данные` ravnyi prezhnemu obyyektu. V ssyilochnoj forme udalenyi rovno dva ukazannyikh polya, a opredeleniye zameneno `null`; versiya i SHA ostayutsya v `профиль`. Polnyij original, putj, SHA i razmer, tekst, oshibki, UUID, sostoyaniye, metadannyiye, ukazateli, paginaciya, schyotchiki i yavnyiye priznaki granic dokazateljstva sokhranyayutsya.

[Opredeleniye](profili/poyasneniya-otveta-1.json) zakrepleno versiyej 1 i SHA-256 `8e1f2fd34c04c2937137388951ec0654b85cb06b6bb4326ed9da386fcd70080e`. Khyesh vyichislyayetsya iz obyyekta bez polya `sha256`: UTF-8, sortirovka klyuchej, kompaktnyiye razdeliteli JSON i zavershayusjhij LF, kak v funkcii `закодировать`. Eto ne khyesh formatirovannogo fajla. Dekoder trebuyet izvestnyij khyesh i celochislennuyu versiyu; `true` i `1.0` nedopustimyi. Pered udaleniyem sravnivayutsya oba tochnyikh znacheniya. Otsutstviye, `null`, pustaya ili izmenyonnaya stroka sokhranyayutsya polnoj formoj.

## Cikl poluchatelya

Poluchatelj vyibirayet kanonicheskij UUID peredachi dlya tekusjhego dostupnogo yemu opredeleniya. Nachaljnoye chteniye bez podtverzhdeniya vozvrasjhayet polnuyu formu s opredeleniyem. Otpravka ili kyeshirovaniye etogo otveta sami po sebe nichego ne podtverzhdayut. Posle yavnogo prinyatiya poluchatelj vyizyivayet `подтвердить`; pered kazhdyim sleduyusjhim zaprosom on zanovo vyizyivayet `подготовить_подтверждение`, peredavaya dejstviteljno dostupnoye opredeleniye.

Primer otdeljnyikh dejstvij Python-poluchatelya posle dobavleniya kataloga `scripts` etogo instrumenta v `PYTHONPATH`:

```python
from пояснения_ответа import подтвердить, подготовить_подтверждение, восстановить

# первый — полученный полный конверт; передача — UUID данного цикла.
определение = первый["определение"]
подтверждение = подтвердить(первый, передача)

# Перед каждым запросом; результат передаётся CLI или адаптеру.
готовое = подготовить_подтверждение(определение, подтверждение, передача)

# ответ — полученный конверт следующего чтения.
прежний = восстановить(ответ, определение, передача)

# При утрате определения старое подтверждение не используется.
определение = None
готовое = подготовить_подтверждение(определение, подтверждение, передача)
```

Poslednij vyizov vozvrasjhayet `None`: sleduyusjhij zapros poluchayet polnuyu formu. Pri novom kontekste poluchatelya takzhe vyibirayetsya novyij UUID. Neizvestnoye, povrezhdyonnoye ili nepodtverzhdyonnoye opredeleniye ne razreshayet sokrasjheniye. Yesli opredeleniye poteryano uzhe posle otpravki zaprosa i prishla ssyilochnaya forma, `восстановить` otkazyivayet: nuzhno povtoritj chteniye bez podtverzhdeniya. Dlya prinyatogo snimka ispoljzuyetsya rezhim `сохранённый`, poetomu povtor zanovo proveryayet SHA fajla, no ne vyizyivayet API i ne zapisyivayet original.

Kod proveryayet yavnyiye dannyiye protokola, a ne vnutrennyuyu pamyatj modeli. Poluchatelj obyazan snyatj podtverzhdeniye pri utrate opredeleniya; proizvoljnoye povtoreniye starogo podtverzhdeniya vopreki etomu kontraktu ne dokazyivayet dostupnostj opredeleniya. Adapter ne khranit podtverzhdeniye v kyeshe snimka. Shirokoye podklyucheniye realjnogo prinimayusjhego kontura v etot etap ne vkhodit.

Povrezhdyonnyij JSON podtverzhdeniya, nevernaya versiya ili UUID privodyat k polnoj forme. Neizvestnoye znacheniye samogo flaga `--версия-передачи` otklonyayetsya kak nevernyij vyibor interfejsa. Nedostupnoye lokaljnoye opredeleniye dayot polnyiye dannyiye i `null` v polyakh opredeleniya i profilya. Polnaya forma vosstanavlivayetsya bez opredeleniya.

## Byudzhet i vosproizvedeniye

Byudzhet primenyayetsya k okonchateljnomu konvertu UTF-8 s putyom i LF posle vyibora polnoj ili ssyilochnoj formyi. V novoj versii promezhutochnoye predstavleniye ogranicheno 1 MiB; etot predel ne oznachayet razresheniya prevyisitj itogovyij byudzhet. Pri prevyishenii CLI vozvrasjhayet kod 2 s pustyim stdout, bez usecheniya. Adapter sokhranyayet predel 16000 bajtov. Proverenyi granicyi N i N−1 dlya dvukh profilej i obeikh form, vklyuchaya polnuyu rezervnuyu vyidachu.

Iz kornya FUM, cherez otchyotnuyu obyortku svoyej sessii:

```sh
PYTHONPATH=Инструменты/fum-svyaznostj-rabochej-sessii/tests python3 -B -m unittest test_пояснения_ответа
node --test --test-name-pattern='Пояснения требуют' Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_адаптер_ответа.cjs
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_передачи_пояснений.py --повторы 7 --выход <приватный-файл-профиля>
```

Nuzhnyi standartnaya biblioteka Python i Node.js dlya adaptera. Otkryitaya fikstura zanimayet 642 bajta. Profilj vyipolnyayet semj chereduyusjhikhsya par dlya serij iz 6, 24 i 8 chtenij; v poslednej opredeleniye teryayetsya. Pervyiye dva chteniya polnyiye, zatem poluchatelj yavno podtverzhdayet opredeleniye; posle utratyi cikl povtoryayetsya. CLI i disk nastoyasjhiye, potrebitelj sinteticheskij, vyizovov API net. Odin vremennyij fajl zapisyivayetsya do izmereniya i udalyayetsya posle nego. Podgotovka parametrov, CLI, razbor i vosstanovleniye vkhodyat vo vremya; proverka semantiki i podgotovka fajla isklyuchenyi.

## Izmerennyij rezuljtat

[Itogovyij profilj](../../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/poyasneniya-profilj-itog.json) uchityivayet vse paketyi parametrov i otvetov s UTF-8/LF. Vlozhennyiye opredeleniya i podtverzhdeniya pokazanyi otdeljno, no ne pribavlenyi vtoroj raz. Paket parametrov modeliruyet vneshnij zapros; argumentyi lokaljnogo processa ne schitayutsya yesjhyo odnim JSON-paketom. Setj, obolochki MCP, tokenyi i RSS ne izmerenyi.

Dlya 6 chtenij obsjhij obmen vyiros s 18768 do 21766 bajtov; dlya 24 — s 75072 do 80122; dlya 8 s utratoj — s 25024 do 30564. Podtverzhdyonnyij otvet umenjshilsya s 2769 do 2483 bajtov, no zapros vyiros s 359 do 759. Poetomu dazhe kazhdoye posleduyusjheye podtverzhdyonnoye chteniye uvelichivayet obmen na 114 bajtov. 550 bajtov strok, 554 s kavyichkami i 588 udalyayemyikh par s razdelitelyami ne yavlyayutsya chistoj ekonomiyej.

Medianyi polnogo cikla sostavili sootvetstvenno 305,421 → 316,443 ms; 1234,864 → 1284,996 ms; 406,604 → 426,769 ms. Vse proshli zaraneye zadannyij predel nakladnyikh raskhodov: prezhneye vremya plyus boljsheye iz 50 ms i 25%. Eto ne uskoreniye. [Pervoye izmereniye](../../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/poyasneniya-profilj-do-optimizacii.json) sokhraneno otdeljno; povtor vyipolnen posle ispravleniya strogosti ssyilki, bez izmeneniya poroga ili scenariyev. Udaleniye podtverzhdenij ili drugikh polej radi polozhiteljnogo rezuljtata ne vyipolnyalosj. Prezhnij format ostayotsya obyichnyim putyom.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 12:56:44 MSK -->
<!-- content-sha256: sha256:9ab4094a909f17b85b3bdce49e44446f1b7e8a5de805bbb96e4d20865fc570fa -->
<!-- FUM-MD-RECENCY:END -->
