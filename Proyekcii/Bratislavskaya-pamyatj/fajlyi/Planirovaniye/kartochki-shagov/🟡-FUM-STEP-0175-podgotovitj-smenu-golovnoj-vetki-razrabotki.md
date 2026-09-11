+++
schema_version = 1
card_id = "FUM-STEP-0175"
status = "active"
+++
# Podgotovitj smenu golovnoj vetki razrabotki

## Zadacha

Podgotovitj perekhod k vyibrannoj golovnoj linii razrabotki, kotoruyu mozhno menyatj po neobkhodimosti. Nezavisimyiye dorabotki vyipolnyayutsya v otdeljnyikh vetkakh i rabochikh derevjyakh; v master periodicheski postupayet sovmestno proverennyij rezuljtat.

## Pochemu sejchas

Poljzovatelj ukazal, chto nuzhnoye paralleljnoye povedeniye uzhe razrabotano v sokhranyonnoj vetke, i predlozhil ispoljzovatj aktualjnuyu golovnuyu liniyu do perenosa obsjhego rezuljtata v master. Povtornoye izobreteniye etoj politiki vmesto yeyo proverki teryayet podgotovlennuyu rabotu.

## Sokhranyonnaya osnova

Vetka `codex/планирование-наблюдения-macos-01a07d3d`, vershina `ef0b528c8c117f7cfddb83d1699aa333d9c486a5`, soderzhit sentyabrjskij perekhod posle ruchnogo rezhima:

- `a521c41df61f7f8d3411c8782a74dfae5eed22b5` — `isolated-per-task-v1`, otdeljnyiye worktree, vetki i promezhutochnyiye kommityi.
- `39c40194655fbe27e851abfea17c5c432dca5a9f` — otdeljnyiye derevjya pishusjhikh detej i prodolzheniye posle kommita.
- `9b9c456e0be6ce409f21f4653b6caa09d132f3d7` — celesoobraznoye paralleljnoye vyideleniye soglasovannoj nezavisimoj rabotyi.
- `008f27dcc34d6991b437109ddfc8166f25be9e28` — vidimyiye nezavisimyiye zadachi Codex Desktop po zaprosu poljzovatelya.

Osnovnyiye puti v etikh Git-obyyektakh: `AGENTS.md` i `Правила/агентов/проверки-коммит-и-публикация.md`. Oni rassmatrivayutsya kak istochniki perekhoda; nalichiye istoricheskogo pravila samo po sebe ne vklyuchayet staryiye ocheredi, hooks ili publikaciyu. Na moment nablyudeniya master `ef6b936be7ac4ac518e0c5b5f5792263a686fab7` i sokhranyonnaya vetka imeyut 5 i 33 sobstvennyikh kommita ot obsjhej bazyi `a3bde39c84528848b13b0b2b415a7e6fd033b9a1`; gotovnostj avtomaticheskogo merge ne dokazana.

## Podgotovlennaya granica i prodolzheniye

Poljzovatelj utochnil napravleniye v [sleduyusjhem etape](../../Zhurnal/2026-09-10_14-26-58_MSK_proveryatj-sliyaniye-master-v-vedusjhuyu-vetku/zapros.md): iskhodnyij master M vlivayetsya v gotovuyu vedusjhuyu vetku L; posle proverki master prodvigayetsya do togo zhe C s roditelyami `[L, M]`. Vedusjhej osnovoj vyibrana `codex/планирование-наблюдения-macos-01a07d3d` na `ef0b528c8c117f7cfddb83d1699aa333d9c486a5`. Osnovnoj prioritet — yeyo polnocennoye obyyedineniye s sokhraneniyem rezuljtatov master. Podgotovka kandidata otdelena ot razresheniya yego prodvizheniya.

[Karta sokhraneniya rezuljtatov](../../Zhurnal/2026-09-10_14-26-58_MSK_proveryatj-sliyaniye-master-v-vedusjhuyu-vetku/materialyi/karta-obyyedineniya.md) podtverzhdayet: Git-mekhanika sliyaniya, vosstanovleniya, proverki roditelej i CAS uzhe yestj v oboikh derevjyakh pobajtno. Yeyo povtornaya realizaciya isklyuchena iz plana. Kyesh, v4-raundyi, vkhod snimka indeksa i zasjhita prodolzheniya berutsya iz podgotovlennoj vetki. Soglasovaniyu podlezhat sokhraneniye fajlov Finder, raznyiye pokoleniya reyestra obyazateljstv i priyomochnyikh svideteljstv, a takzhe yavno vyibrannyiye pravila rabotyi.

Snachala gotovitsya konkretnyij kandidat i razreshayutsya eti razlichiya. Toljko nedostayusjhiye dlya yego priyomki proverki dorabatyivayutsya otdeljno. Chastnyiye chernoviki chitatelya svyazi otchyota so sliyaniyem i yego testov perenesenyi v tekusjhij etap M1; 17 adresnyikh scenariyev proshli. Istochnik polnogo zapuska iz master otdelyon ot proveryayemoj realizacii kandidata i proveren skvoznoj v3-fiksturoj; etot etap yesjhyo ne prinyat v master. Istochnik doverennogo proverochnogo koda M i predkommitnyij HEAD L razlichayutsya. Neizmenyayemoye podtverzhdeniye polnogo zapuska i profilj realizovanyi: 15 scenariyev istochnika i ispolneniya proshli, adapter optimizirovan s 13 do 6 processov Git. Nezavershyonnyimi ostayutsya finaljnaya priyomka M1, zatem proverka novogo kandidata C2 i prodvizheniye master.

## Paket sovmestimosti prinimayusjhego kontura

Ot iskhodnogo M `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d` podgotovlena sobstvennaya vetka sovmestimosti s neizmennyim L `a728283474931eda71cd581ca5429121124ba3f6` i derevom `bc258a41133107198602c60d003555898d4cfad2`. [Etap podgotovki](../../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/zapros.md) obyyedinyayet shestj adresnyikh paketov: formatyi prilozheniya, yedinstvennyij konechnyij JS-adapter, tochnyij marker otsutstviya svyazej, prinimayusjhuyu proverku tipov, neobyazateljnyij lokaljnyij graf i otdeljnuyu kandidatnuyu politiku putej. Politika kandidata soderzhit prezhniye 350 i 69 novyikh isklyuchenij L; obyichnaya politika soderzhit toljko odno neobkhodimoye dobavleniye k prezhnim 350.

Pri perenose tipov podtverzhdeno `FUM-СБОЙ-0076/ПРОЯВЛЕНИЕ-0001`: [kartochka sboya](../../Sboi/FUM-SBOJ-0076-propusk-proverki-predkov-kataloga-tipov.md) svyazyivayet semj otricateljnyikh podsluchayev i ispravleniye predkov puti. 82 sovmestnyikh adresnyikh testa proshli; profili i semj regressij neizmennogo kontura sokhranenyi v otchyote. Priyomka etogo paketa, yego integraciya v master, fiksaciya novogo M i proverka novogo kandidata ostayutsya posledovateljnyimi otdeljnyimi granicami. Tekusjhij etap ne sozdayot kandidata i ne prodvigayet master libo fuma.

## Sovmestimaya priyomka i sokhranyonnyiye ogranicheniya

[Sleduyusjhij etap](../../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/zapros.md) sokhranyayet odnu prervannuyu polnuyu popyitku v4 i adresnoye vosstanovleniye otchyota. `FUM-СБОЙ-0079/ПРОЯВЛЕНИЕ-0001` — [zavisimyij zapusk posle nablyudyonnogo otkaza predprosmotra](../../Sboi/FUM-SBOJ-0079-zavisimyij-smoke-posle-otkaza-predprosmotra.md); sistemnaya regressionnaya granica podgotovki ostayotsya posleduyusjhej rabotoj.

`FUM-СБОЙ-0080/ПРОЯВЛЕНИЕ-0001` — [otsutstvuyusjhaya podderzhka raundov Git-chitatelem](../../Sboi/FUM-SBOJ-0080-Git-chitatelj-ne-prinimayet-raundyi.md). Koordinator otozval predpolozheniye ob obyazateljnosti yeyo realizacii dlya blizhajshego sliyaniya. Iskhodnyij M razreshayet novyij otdeljnyij etap v3/report-v2; staryiye v4 ostayutsya neizmennyimi. Blizhajshij obyyom sokhranyayet shestj paketov. Predlozheniye budusjhego dostatochnogo svideteljstva Unix-atributov i strogogo Git-vosstanovleniya khranitsya v [razbore](../../Zhurnal/2026-09-11_15-22-57_MSK_proveritj-paket-sovmestimosti-master-i-FUMA/materialyi/granica-chitatelya-i-priyomki.md), ne vyidayotsya za realizovannoye ispravleniye i ne blokiruyet podderzhannyij C2.

V obyichnom etape v3 vyiyavleno `FUM-СБОЙ-0066/ПРОЯВЛЕНИЕ-0003`: [ustarevshaya podstanovka metoda chteniya](../../Sboi/FUM-SBOJ-0066-ustarevshaya-podstanovka-metoda-chteniya.md) uzhe iskhodnogo M. Polnyij otkaz, adresnyij RED, GREEN i profilj sokhranenyi v [diagnostike R3](../../Zhurnal/2026-09-11_15-50-49_MSK_prinyatj-sovmestimostj-FUMA-cherez-otchyot-v3/materialyi/diagnostika-chteniya-osnovaniya.md). Koordinator razreshil yedinstvennyij dvukhstrochnyij hunk testa iz iskhodnogo paketa formatov `6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95`; production i utverzhdeniya sokhranyayutsya. Etot povtor trebuyet dovesti uzhe susjhestvuyusjhij shag do priyomki tochnoj deljtyi v master i novogo kandidata; novyij STEP ne sozdayotsya.

## Kriterii zaversheniya

- Sopostavlenyi podgotovlennaya politika i prinyatyiye izmeneniya master, sokhranenyi proverennyiye v3-svideteljstva i proiskhozhdeniye obeikh linij.
- Opredelenyi vyibrannaya golovnaya liniya, yeyo osnovaniye i poryadok bezopasnoj smenyi s sokhraneniyem nezavershyonnyikh zadach.
- Razdelenyi nezavisimyiye rabochiye derevjya i mesto sovmestnoj priyomki; obnovlyon obyazateljnyij nabor pravil bez neyavnogo vklyucheniya istoricheskikh polnomochij.
- Rezuljtat integracii proveryayetsya do popadaniya v master; kontroljnyij kommit s planom ne vyidayotsya za prinyatuyu realizaciyu.
- Prinyata podderzhka nastoyasjhikh merge-kommitov i proveryayusjhego istochnika; obyichnyij rezhim adaptera sokhranyayet ogranicheniye odnim roditelem. Integracionnaya vetka v otdeljnom dereve stroitsya ot vedusjhej L, prinimayet master M i sokhranyayet C s roditelyami [L, M]; posle proverki master prodvigayetsya do togo zhe C pri sokhranenii M i soglasovannosti osnovnogo checkout.
- Izmeneniya pravil samoj integriruyemoj linii ne mogut nezametno oslabitj yeyo priyomku; susjhestvennyiye ogranicheniya i vozrazheniya soobsjhayutsya poljzovatelyu.
- Priyomka vyipolnyayetsya po pravilam zafiksirovannogo iskhodnogo master. Predlagayemyiye novyiye pravila ocenivayutsya vnutri kandidata i nachinayut dejstvovatj posle prinyatiya; proveryayusjhaya storona ne podmenyayetsya kandidatnoj realizaciyej.
- Utochnena granica rannego sokhraneniya nablyudenij: vetka opravdana samostoyateljnyim rezuljtatom i pervyim shagom, a dannyiye sokhranyayutsya nezavisimo ot sozdaniya vetki.

## Istochniki

- [FUM-SBOJ-0066, proyavleniye 0003](../../Sboi/FUM-SBOJ-0066-ustarevshaya-podstanovka-metoda-chteniya.md).

- [Pryamyiye komandyi i soderzhateljnyiye otvetyi](../../Zhurnal/2026-09-10_11-51-55_MSK_sokhranyatj-ostatok-obyazateljstv/zapros.md).
- [Podgotovka sovmestimosti s FUMA](../../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/zapros.md).
- [FUM-SBOJ-0076, proyavleniye 0001](../../Sboi/FUM-SBOJ-0076-propusk-proverki-predkov-kataloga-tipov.md).
- [Podgotovka proveryayemogo perenosa soderzhimogo vetok](../../Zhurnal/2026-09-10_02-01-28_MSK_proveryatj-zakryityiye-otchyotyi-iz-kommitov/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:57:51 MSK -->
<!-- content-sha256: sha256:f7e6bf938fb1cfbfba962d528e3f9593d15f678c55c1651a4e42fe6dcd2330f6 -->
<!-- FUM-MD-RECENCY:END -->
