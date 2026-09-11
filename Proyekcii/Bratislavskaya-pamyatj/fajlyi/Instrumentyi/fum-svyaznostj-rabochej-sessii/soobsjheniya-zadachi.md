# Chitatj vse iskhodnyiye soobsjheniya zadachi

Etot segment FUM-STEP-0177 vozvrasjhayet polnyij indeks poljzovateljskikh soobsjhenij JSONL, vklyuchaya soobsjheniya do prezhnego kursora. On pomogayet vosstanovitj iskhodnyij kontekst posle szhatiya i uvidetj mnogochastnyij vvod. Dlya sopostavleniya s sokhranyonnyimi otvetami dostupen [sleduyusjhij segment obrabotki](obrabotka-soobsjhenij.md). Obyazateljnoye vklyucheniye v dopusk yesjhyo gotovitsya; uspeshnoye chteniye ne oznachayet, chto komandyi obrabotanyi ili vyipolnenyi.

## Zapusk

Iz kornya svoyego checkout ukazhite JSONL kornevoj zadachi, yeyo `Codex-Thread-ID` i fajl privatnogo kyesha. Roditeljskij katalog kyesha dolzhen susjhestvovatj i nakhoditjsya vne lyubogo Git checkout. Komanda ne vyibirayet chuzhuyu zadachu po pokhozhemu zagolovku.

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/прочитать-сообщения-задачи.py --корень-репозитория . --исходник <локальный-JSONL> --codex-thread-id <UUID-задачи> --кэш <приватный-файл-кэша>
```

JSON v stdout soderzhit tochnyiye chasti soobsjhenij, neprozrachnyiye ssyilki na vlozheniya, iskhodnyij obyyekt soobsjheniya, bajtovyiye pozicii i SHA-256. On privatnyij: ne perenapravlyajte yego v otslezhivayemyij fajl i ne publikujte celikom. Dlya Zhurnala otdeljno vyibirayutsya publikacionno dopustimyiye komandyi i soderzhateljnyiye otvetyi. Media ne skachivayutsya i ne dekodiruyutsya.

Flag `--без-записи` otklyuchayet sozdaniye i obnovleniye kyesha i fajlov blokirovok. V etom rezhime `--кэш` mozhno opustitj: indeks stroitsya v pamyati. Yesli kyesh ukazan, yego susjhestvuyusjhaya versiya proveryayetsya i chitayetsya bez izmeneniya; povrezhdeniye ne skryivayetsya peresozdaniyem. Zapuskajte Python s `-B`, kak v primere, chtobyi interpretator takzhe ne sozdaval bajtkod.

| Kod | Chto proizoshlo                                                                    | Daljnejsheye dejstviye                                                     |
| --- | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 0   | V zavershyonnom prefikse vse vyidannyiye soobsjheniya imeyut podtverzhdyonnoye proiskhozhdeniye | Rassmotretj soobsjheniya vmeste s pozdnimi utochneniyami                     |
| 3   | Yestj neodnoznachnyij vvod libo nezavershyonnaya poslednyaya stroka                      | Proveritj proiskhozhdeniye libo dozhdatjsya dopisyivaniya i povtoritj chteniye   |
| 2   | Istochnik ili kyesh ne udalosj prochitatj i proveritj                                | Sokhranitj prezhniye dannyiye i razobratj prichinu; pustoj rezuljtat ne vyidan |

Ni odin iz etikh kodov ne yavlyayetsya razresheniyem zavershitj rabochuyu zadachu. Obyazateljstva poka proveryayutsya otdeljnyim dejstvuyusjhim instrumentom prodolzheniya.

## Chto sokhranyayetsya

Identichnostj ekzemplyara svyazyivayet UUID zadachi, SHA-256 pervoj stroki `session_meta`, diapazon bajtov i SHA-256 syiroj stroki s LF. Dva odinakovyikh teksta v raznyikh soobsjheniyakh ostayutsya dvumya ekzemplyarami. `event_msg` ne eksportiruyetsya povtorno. Povtor `response_item` s tem zhe transportnyim ID i polnostjyu odinakovyim iskhodnyim obyyektom zapisyivayetsya kak dopolniteljnoye predstavleniye prezhnego ekzemplyara; raznyiye obyyektyi s odnim ID otklonyayutsya, vklyuchaya konflikt s hook ili sluzhebnyim kontekstom.

Klassifikator vyizyivayetsya do obyyedineniya soderzhimogo. Sluzhebnyiye hook i kontekst ne stanovyatsya komandami cheloveka; neopredelyonnoye proiskhozhdeniye ostayotsya yavnyim. Povrezhdyonnaya obolochka `response_item` dayot otkaz. Skryityiye rassuzhdeniya i instrumentaljnyiye rezuljtatyi v indeks ne eksportiruyutsya. Predel 64 MiB otnositsya k odnoj stroke; vesj fajl mozhet byitj znachiteljno boljshe.

Kyesh soderzhit vse najdennyiye ekzemplyaryi, a ne toljko khvost. On ustanavlivayetsya atomarnoj zamenoj s `fsync`; otdeljnyij ustojchivyij lock-fajl serializuyet obnovleniya. Posle preryivaniya iskhodnyij JSONL ostayotsya istochnikom vosstanovleniya. Ischeznoveniye, usecheniye ili izmeneniye uzhe prochitannogo prefiksa ne pogashayutsya novyim kursorom.

## Skorostj i granica doveriya

Pri neizmennyikh ustrojstve, inode, razmere, `mtime_ns` i `ctime_ns` povtor ispoljzuyet sokhranyonnyij indeks. Eto nablyudeniye metadannyikh lokaljnoj fajlovoj sistemyi, a ne kriptograficheskoye dokazateljstvo neizmennosti bajtov. Pri izmenenii fajla prezhnij prefiks polnostjyu khyeshiruyetsya i sravnivayetsya; povtorno razbirayetsya toljko khvost. Izmeneniye koda chitatelya ili klassifikatora vyizyivayet polnyij povtornyij razbor.

Flag `--перепроверить` vsegda zanovo chitayet i razbirayet vesj zavershyonnyij prefiks. Etot rezhim nuzhen dlya nezavisimoj sverki, a byistryij rezhim — dlya povtornyikh obrasjhenij pri obyichnom lokaljnom dobavlenii zapisej. Chteniye ogranicheno razmerom fajla pri otkryitii. Pri dopisyivanii zavershyonnaya granica nezavisimo sveryayetsya po SHA; usecheniye ili izmeneniye prochitannyikh bajtov dayut otkaz. Metka kyesha sokhranyayet iskhodnyij razmer, chtobyi posleduyusjheye chteniye obnaruzhilo khvost.

`полнота_подтверждена` otnositsya toljko k vyibrannomu snimku. `размер_снимка` pokazyivayet yego iskhodnyij razmer, `неполный_хвост` — nezavershyonnuyu stroku vnutri nego, `дописано_после_снимка` — zamechennyiye pozdniye bajtyi. Posledniye yesjhyo ne klassificirovanyi i ne schitayutsya otsutstvuyusjhimi soobsjheniyami. Fajlovyij zamok zasjhisjhayet kyesh, no ne ostanavlivayet zapisyivayusjhij runtime; soglasovannaya vrazhdebnaya podmena istochnika, metadannyikh i kyesha vladeljcem mashinyi nakhoditsya vne dokazannoj granicyi.

Profilj vyivoditsya otdeljno ot soderzhimogo vnutri polya `профиль`: prochitannyiye bajtyi, chislo razobrannyikh strok, rezhim i monotonnyiye dliteljnosti. Vlozhennyiye intervalyi ne pribavlyayutsya povtorno k obsjhej dliteljnosti.

## Vosproizvedeniye proverki i izmerenij

Adresnyij nabor: `python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p 'test_сообщения_задачи.py'`. On sozdayot vremennyiye otkryityiye fiksturyi, ne chitaya privatnuyu perepisku. V rabochej sessii zapusk prokhodit cherez obyazateljnuyu otchyotnuyu obyortku.

Scenarij `scripts/измерить-сообщения-задачи.py --повторов 3 --выход <файл-профиля>` vosproizvodit istochnik boljshe 70 MiB: staroye porucheniye, dva povtora odinakovoj komandyi i pozdneye utochneniye. Povtorite s `--полное-чтение`, chtobyi sravnitj polnyij razbor s indeksom pri odinakovyikh vkhodakh i realizacii. Sbor fiksturyi isklyuchyon iz izmereniya; sokhranyayutsya khyeshi koda, klassifikatora, scenariya i vkhoda kazhdoj stadii. Maksimaljnaya pamyatj otnositsya ko vsemu processu, kyesh fajlovoj sistemyi ne sbrasyivayetsya.

## Istochniki

Iskhodniki i avtonomnyiye scenarii perenesenyi bez izmenenij iz proverennogo kommita `68996460643a50d47cfc6e121b34cc0911639f26`; ssyilki proiskhozhdeniya adaptirovanyi k tekusjhej postavke.

- [Iskhodnyiye komandyi i otchyot tekusjhego segmenta](../../Zhurnal/2026-09-11_01-40-19_MSK_avtomatizirovatj-priyom-napravlenij-FUMA/zapros.md).
- [Polnyij obyyom FUM-STEP-0177](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:07:47 MSK -->
<!-- content-sha256: sha256:ebd11ba904b219ce8f4564ad5b7cdfd729d2a461c293ab769c4953539da02cf0 -->
<!-- FUM-MD-RECENCY:END -->
