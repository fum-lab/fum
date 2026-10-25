# Predlozheniye svyazi susjhestvuyusjhikh napravlenij

Status: podgotovleno dlya rassmotreniya; shtatnyij priyom i izmeneniye perechislennyikh kartochek ne vyipolnenyi. Novyiye nomera i zadachi ne sozdavalisj. Vkhodyasjhaya postanovka prinyata iz `1e6676b97ae992c22ea7112f68d05fff2d38fb09`, predyidusjhaya vershina planirovaniya — `52b08c8aa78b5c49903f9f80211634db06782496`.

## Susjhestvuyusjhaya karta

| Napravleniye | Sokhranyonnyiye identifikatoryi | Blizhajshij ogranichennyij rezuljtat |
| ----------- | ------------------------- | ------------------------------- |
| Android-runtime | FUM-REQ-0046, FUM-STEP-0182 | Obsjhij poleznyij Swift-scenarij na yavnom Android-profile |
| Windows-runtime | FUM-REQ-0046, FUM-STEP-0182 | Tot zhe scenarij s sobstvennyimi sborkoj i zapuskom Windows |
| Sreda Windows | FUM-STEP-0181 | Podgotovka sredyi otdeljno ot nativnogo runtime; WSL ne dokazyivayet yego zapusk |
| Telegram | FUM-REQ-0049, FUM-STEP-0184 | Prodolzheniye susjhestvuyusjhego adaptera i potokovogo chteniya istorii |
| MAX Bot API | FUM-REQ-0049, FUM-STEP-0184 | Tipizirovannyiye operacii i sobyitiya dlya kanalov FUM, podmenyayemyij transport |
| Obsjheye yadro | FUM-REQ-0046, FUM-REQ-0067, FUM-STEP-0182 | Pereispoljzovaniye konechnogo interpretatora FUM-STEP-0208 i kontejnera FUM-STEP-0156 |
| Sobstvennyij GUI | FUM-REQ-0047, FUM-REQ-0021, FUM-REQ-0002, FUM-STEP-0182 | Obsjhaya scena i povedeniye s proveryayemyimi platformennyimi ispolnitelyami |
| Pozhertvovaniya i media | FUM-REQ-0069 | Ssyilka na otdeljnuyu postavku prezhnego finansovogo vladeljca, bez povtornogo plana |

FUM-STEP-0176 podtverzhdayet razmesjheniye iskhodnikov, a ne zapusk na vsekh platformakh. Zavershyonnyiye kartochki interpretatora i razmesjheniya ne pereotkryivayutsya. Ni odna stroka tablicyi ne oznachayet priyomki rabotayusjhej platformyi.

## Peredannyij snimok naznachenij

- Android: `01a0a633-a0a3-71f1-8725-04ad4dfa8a32`. Koordinator peredal podtverzhdeniye ispolnitelya: iskhodnyij OID `1e6676b97ae992c22ea7112f68d05fff2d38fb09`, native `gpt-6-astra` / `low`. Polnyij ref poka ne peredan. Android pervyim izmenyayet perenosimostj obsjhikh paketov.
- Windows: `01a0a633-d5a1-77c1-813c-2d26110a3d67`, ta zhe podtverzhdyonnaya iskhodnaya baza i modelj. Polnyij ref poka ne peredan. Do postavki obsjhego sreza Android rabota ogranichena nezavisimyimi sredoj i upakovkoj.
- Telegram: `01a09179-da9e-72e3-a858-af3bfd6f8894`, vozobnovleniye otrazheno v prinyatom otchyote koordinatora. Po posleduyusjhemu peredannomu soobsjheniyu opublikovan checkpoint `7dfc5b1f`, prodolzhayetsya potokovoye chteniye istorii. Eto peredannoye svideteljstvo, ne sobstvennaya proverka runtime.
- MAX: vidimaya zadacha uzhe sozdayotsya; dostovernyij native UUID poka ne peredan. `clientThreadId` ne podstavlyayetsya vmesto nego; povtornoye sozdaniye zapresjheno.
- Finansovoye medijnoye soprovozhdeniye: prezhnij vladelec `01a0904a-f98e-70b1-8ea6-a0202ff4de7a`, gotovyij source `c99cbd813ca81057d6efe49d9dab2ed4ec52ca83` ozhidayet otdeljnoj integracii koordinatorom. Rezuljtat zdesj ne vosproizvoditsya.

## Tochnaya predlagayemaya redakciya

V [platformennom trebovanii](../../../Trebovaniya/🟡-zapusk-FUMA-na-celevyikh-platformakh.md) zamenitj smeshannyij abzac Android/Windows: kazhdyij iz dvukh srezov trebuyet avtomatizacii sborki i zapuska obsjhego poleznogo scenariya na yavnom profile svoyej platformyi. Obsjhiye Swift-paketyi i interpretator ne dubliruyutsya; platformennyiye adapteryi imeyut otdeljnyiye oblasti. SDK, sborka obsjhego paketa i zapusk sosednej platformyi ne dokazyivayut celevoj profilj. Ssyilku na [plan Android](../../../Prilozheniya/FUMA/plan-Android-runtime.md) sokhranitj.

V [FUM-STEP-0182](../../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0182-opredelitj-platformennyiye-sborki-i-pervyij-scenarij-FUMA.md) posle macOS-sreza dobavitj Android i Windows: UTF-8 → Unicode-skalyaryi → yavno vyibrannyij UTF-32, sokhraneniye i povtor nablyudeniya. Po kazhdomu profilyu nuzhnyi tochnyiye instrumentyi, OS, arkhitektura ili ABI, vkhod, ozhidayemyiye i fakticheskiye bajtyi i kod processa. Sreda, sborka i zapusk razlichayutsya; polnocennyij GUI ne vkhodit v pervyij srez. Prioritet izmenenij obsjhego yadra prinadlezhit Android, nezavisimoj Windows-obolochki — Windows.

V [trebovanii messendzherov](../../../Trebovaniya/🟡-integracii-FUMA-s-messendzherami.md) pered statusom sokhranitj vozobnovleniye Telegram i otdeljnyij srez MAX Bot API dlya kanalov FUM. Vyibran rezhim bota; kliyentskij API poljzovateljskoj uchyotnoj zapisi etim ne razreshyon. Pervyij MAX-rezuljtat — tipizirovannyiye operacii i sobyitiya s podmenyayemyim transportom i avtonomnyimi fiksturami. Registraciya, realjnyiye tokenyi, podklyucheniye kanalov i publikacii otdeljno.

V [FUM-STEP-0184](../../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0184-opredelitj-adapteryi-messendzherov.md) soslatjsya na utochneniye FUM-REQ-0049: prodolzhitj Telegram i MAX Bot API, sokhraniv prochiye otkryityiye rezhimyi obsjhej matricyi. Polucheniye, podgotovka i otpravka razlichayutsya; avtonomnaya proverka ne dokazyivayet podklyucheniye kanala.

V [graficheskom trebovanii](../../../Trebovaniya/🟡-graficheskiye-interfejsyi-FUMA.md) uzhe yestj svoj Metal/Vulkan GUI i sokhranyonnaya celj DirectX. Po pozdnemu peredannomu utochneniyu Windows pervyim mozhet ispoljzovatj Vulkan bez obyazateljnogo DirectX v pervom sreze; obsjheye trebovaniye DirectX ne otmeneno. Metal zhelatelen dlya macOS, iOS, watchOS, tvOS, visionOS, no primenimostj Metal/MTKView k watchOS i sposob ispolneniya ostayutsya otkryitoj platformennoj granicej. Eto ne obesjhaniye podderzhki watchOS. Doslovnyiye pozdniye komandyi i pervichnyij tekhnicheskij istochnik poka ozhidayutsya ot koordinatora; pereskaz ne zamenyayet ikh.

V [operatornom plane](../../../Planirovaniye/operatornyij-interfejs-FUMA.md) svyazatj obsjhiye opredeleniya operatorov, scenu i formatyi nablyudenij s etimi platformennyimi srezami. Swift obespechivayet ispolneniye, primitivyi i adapteryi. Sokhranyayutsya prezhnyaya celj yedinogo runtime i minimizacii IPC.

V [blizhajshem plane](../../../Planirovaniye/README.md) obnovitj granicu: istoriya i runtime uzhe vklyuchenyi cherez prinyatuyu FUMA; finansovyij srez d725 prinyat v `4a528ddbd6d249e1611a296f87d50b146fe7f4ff`, planirovaniye52b — v `1e6676b97ae992c22ea7112f68d05fff2d38fb09`. Dobavitj privedyonnyiye naznacheniya otdeljno ot statusa realizacii. Polnaya obsjhaya priyomka ostayotsya vperedi.

## Nepodderzhannaya operaciya priyoma

Kod `ветка_писателя()` v [priyome](../../../Instrumentyi/fum-reyestr-planirovaniya/scripts/priyom_napravleniya.py) dopuskayet toljko `refs/heads/codex/…`. Proverka vladeljca dejstvuyet i pri read-only predprosmotre [otlozhennyikh naznachenij](../../../Instrumentyi/fum-reyestr-planirovaniya/scripts/otlozhennyiye_naznacheniya.py). Paket naznachenij trebuyet `задача.режим = создать`; svyazj uzhe susjhestvuyusjhikh native UUID ne vyirazhayetsya. Obyichnyij priyom s `действие = обновить`, `задача = null` sokhranyayet nomera, no takzhe otvergayet tekusjhuyu vetku. Vneshneye dejstviye «obnovitj» otpravlyayet porucheniye i ne yavlyayetsya registraciyej izvestnogo naznacheniya.

Operaciya `подготовить` radi vosproizvedeniya ozhidayemogo otkaza ne zapuskalasj: ona otkryivayet obsjhij privatnyij katalog i zamok do proverki vetki. Ispolnyayemyij kod, chuzhiye refs, reyestr priyomov i prezhniye obyazateljstva ne menyalisj. Eto rezuljtat chteniya dejstvuyusjhego kontrakta, ne lozhnyij otchyot ob ispolnennom priyome.

Minimaljnyij sleduyusjhij rezuljtat avtomatizacii: podderzhatj tochnuyu postoyannuyu vetku s prezhnimi proverkami yedinstvennogo vladeljca i otdeljnuyu fiksaciyu uzhe susjhestvuyusjhego naznacheniya bez create_thread ili otpravki novogo porucheniya. Istochnik — nastoyasjhij JSONL koordinatora i yego UUID, s proverennyimi ekzemplyarom, kontekstom i istoriyej. Uzhe prinyatoye chuzhoye sobyitiye ne prisvaivayetsya novomu pisatelyu. Povtor sokhranyayet te zhe identifikatoryi i ne sozdayot vneshnij dublj. Nuzhnyi adresnyiye RED/GREEN i profilj etogo perekhoda do primeneniya; eta dorabotka sejchas toljko postavlena kak konkretnyij ostatok, bez novogo nomera.

## Proiskhozhdeniye

- [Pervichnyiye komandyi v prinyatoj FUMA](../../2026-09-15_20-33-17_MSK_prinyatj-obnovlyonnoye-postoyannoye-planirovaniye/zapros.md).
- [Otvetyi i peredannyiye naznacheniya](../../2026-09-15_20-33-17_MSK_prinyatj-obnovlyonnoye-postoyannoye-planirovaniye/otchyot.md).
- Posleduyusjhiye nativnyiye soobsjheniya koordinatora `01a07d3d-d376-7ad2-aafc-67e4c25a67eb` tekusjhej zadache: ogranichennaya peredacha i podtverzhdeniya Android/Windows. Oni ne yavlyayutsya chelovecheskim vvodom sobstvennogo JSONL.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:06:19 MSK -->
<!-- content-sha256: sha256:126e9b79dcc96a73098fa624dc42bc7b1ca1109c45a1727771289cf13dca7f9a -->
<!-- FUM-MD-RECENCY:END -->
