# Proverka zakryitogo otchyota v kommite

[Chitatelj](scripts/zakryityij_otchyot_iz_gita.py) proveryayet priyomochnyiye svideteljstva, sokhranyonnyiye v konkretnom kommite: polnyij katalog zapuskov, zakryityij snimok, upravlyayemyij blok otchyota, gotovnostj plana i [svyazj otpechatka s kodom](svyazj-s-kommitom.md). Eto osnova posleduyusjhej proverki obyazateljstv i priyomki perenosimyikh komponentov.

```bash
python3 -B Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/закрытый_отчёт_из_гита.py \
  --корень-репозитория . \
  --коммит <полный-OID> \
  --запрос Журнал/<stem>/запрос.md
```

Peredayotsya polnyij OID dostupnogo kommita i tochnyij otnositeljnyij putj zaprosa. Korenj sovpadayet s realjnyim checkout. Teg, sokrasjhyonnyij OID, nachaljnyij kommit i merge ne prokhodyat ogranicheniya adaptera svyazi. Otsutstvuyusjhiye obyyektyi ne zagruzhayutsya iz seti.

| Kod | Sostoyaniye | Znacheniye |
| --- | --- | --- |
| 0 | `подтверждён` | Zakryityij otchyot gotov, istoricheskij otpechatok vosstanovlen i sovpadayet s oboimi svideteljstvami. |
| 2 | `не подтверждён` | Otchyot proveren, no istoricheskaya rekonstrukciya otpechatka ne sovpala. Eto ne dokazateljstvo podmenyi. |
| 1 | Oshibka | Vkhod, sostav, tip obyyekta, format, celostnostj libo gotovnostj ne podtverzhdenyi. |

Vyivod imeyet skhemu `fum.проверенный-отчёт.1`, soderzhit polnyij kommit, putj zaprosa, chislo zapuskov, UUID finaljnogo zapuska, khyesh snimka, oba otpechatka i rezuljtat ikh svyazi. Pole `завершение_обязательства_доказано` vsegda ravno `false`: uspeshnaya priyomka koda sama po sebe ne zakryivayet poljzovateljskoye obyazateljstvo.

## Chto proveryayetsya

Inventarj beryotsya iz dereva Git, vklyuchaya vlozhennyiye derevjya. Spisok vnutri snimka ne sluzhit yedinstvennyim istochnikom sostava. V kataloge zapuskov nedopustimyi neizvestnyiye fajlyi, vlozhennyiye katalogi, dazhe pustyiye, i perekhodnyij zhurnal vozobnovleniya. Zapros, otchyot i svideteljstva dolzhnyi byitj obyichnyimi blobs s rezhimom `100644` ili `100755`; simvolicheskiye ssyilki i gitlink otklonyayutsya. Fakticheskij tip kazhdogo obyyekta proveryayetsya otdeljno ot rezhima zapisi dereva: tag na korrektnyij blob ne podmenyayet sam blob.

Vse JSON-obyyektyi otklonyayut povtornyiye klyuchi i nechislovyiye konstantyi. Proveryayutsya skhemyi zapuskov, UUID, unikaljnostj poryadka, sovmestimostj istorii, tochnyiye khyeshi i sostav snimka. Dlya samogo snimka dopolniteljno obyazateljnyi kanonicheskiye bajtyi. Formatirovaniye JSON zapisej mozhet otlichatjsya, yesli ikh tochnyiye bajtyi svyazanyi soglasovannyimi khyeshami; eto sokhranyayet kontrakt prezhnej obyortki.

Marker i upravlyayemyij Markdown-blok sovpadayut s rezuljtatom susjhestvuyusjhego generatora. Zatem otdeljno proveryayetsya ekonomnyij plan: zakryityij, no negotovyij otchyot ne prinimayetsya. Poslednyaya zapisj dolzhna byitj yedinstvennoj uspeshnoj polnoj v3-priyomkoj na otpechatke zakryitiya. Dopustimostj predshestvuyusjhikh istoricheskikh zapisej opredelyayetsya prezhnej proverkoj poryadka.

## Chteniye bez pobochnyikh izmenenij

Istoricheskiye svideteljstva chitayutsya iz Git, dazhe yesli zhivyiye zapros, otchyot ili snimok v checkout udalenyi libo isporchenyi. Ispravlennyij checkout takzhe ne ispravlyayet plokhoj arkhiv v vyibrannom kommite. Chitatelj ne sozdayot vremennyij checkout, zhurnaljnyiye lock-fajlyi ili novyiye zapisi proverki i ne menyayet indeks, refs libo konfiguraciyu. Pri zapuske Python ispoljzuyetsya `-B`, chtobyi import ne sozdaval `__pycache__`.

Git poluchayet toljko polnyiye OID obyyektov iz vyibrannogo dereva. Odin paketnyij vyizov vozvrasjhayet unikaljnyiye obyyektyi, sokhranyaya sootvetstviye kazhdomu iskhodnomu puti. Parser proveryayet tochnyij OID, tip, desyatichnyij razmer, bajtyi zadannoj dlinyi, razdeliteljnyij LF i tochnyij konec otveta. Nenulevoj exit code Git, otsutstvuyusjhij obyyekt, propusk, perestanovka i lishnij otvet oznachayut otkaz bez chastichnogo rezuljtata. Vyivod paketa celikom khranitsya v pamyati.

## Granicyi dokazateljstva

Chitatelj ispoljzuyet doverennyij lokaljnyij Git; nezavisimyij pereschyot Git OID i polnyij audit povrezhdeniya obyyektnoj bazyi ne vkhodyat v kontrakt. Istoricheskaya rekonstrukciya nasleduyet ogranicheniya adaptera po konfiguracii i bukvaljnomu diff. Proveryayetsya upravlyayemoye svideteljstvo, a ne istinnostj svobodnogo teksta otchyota.

Soderzhimoye poljzovateljskikh komand, `Codex-Thread-ID`, polnota reyestra, smyislovaya priyomka rezuljtata i aktualjnostj obyazateljstva trebuyut sleduyusjhego sloya. Nalichiye obyichnogo fajla zaprosa yesjhyo ne dokazyivayet proiskhozhdeniye komandyi. Chitatelj ne vyipolnyayet merge i ne podklyuchyon k zaversheniyu Codex. Sokhranyonnyiye v4-postavki prezhnego konvejyera avtomaticheski ne stanovyatsya prinyatyimi v3-rezuljtatami.

## Izmereniye

[Profilj sravneniya](../../Zhurnal/2026-09-10_02-01-28_MSK_proveryatj-zakryityiye-otchyotyi-iz-kommitov/materialyi/profilj-sravneniya.json) vosproizvoditsya [scenariyem](../../Zhurnal/2026-09-10_02-01-28_MSK_proveryatj-zakryityiye-otchyotyi-iz-kommitov/materialyi/izmeritj-chteniye-otchyota.py) na prinyatom kommite `6fc2c7a76dd7d23a703418b4072f0fdc561a4f53`. Dlya otchyota s 39 zapuskami chislo processov Git umenjshilosj s 94 do 11; medianyi semi chereduyusjhikhsya povtorov sostavili 1405,964 i 178,280 ms. Rezuljtatyi oboikh variantov sovpali. Importyi i otdeljnyij zamer pamyati ne vkhodyat vo vremennuyu seriyu; eto ne kholodnyij diskovyij kesh i ne vremya CLI. Pikovaya uchtyonnaya pamyatj Python sostavila 679198 i 679360 bajt; pamyatj dochernikh Git-processov ne izmeryalasj. Uskoreniye otnositsya k etomu vkhodu i okruzheniyu.

[Testyi](tests/test_zakryityij_otchyot_iz_gita.py) ispoljzuyut nastoyasjhij formatiruyusjhij i otchyotnyij mekhanizm v avtonomnyikh vremennyikh repozitoriyakh. Dochernij smoke v fiksture sinteticheskij: eti testyi ne zayavlyayut vyipolneniye realjnogo polnogo nabora. Realjnaya priyomka tekusjhego koda vyipolnyayetsya otdeljno i sokhranyayetsya v [otchyote etapa](../../Zhurnal/2026-09-10_02-01-28_MSK_proveryatj-zakryityiye-otchyotyi-iz-kommitov/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 11:27:33 MSK -->
<!-- content-sha256: sha256:b9122674b3335a77f11e7559c48291577ad2192db59e0bf7f52bd9ff041e3f59 -->
<!-- FUM-MD-RECENCY:END -->
