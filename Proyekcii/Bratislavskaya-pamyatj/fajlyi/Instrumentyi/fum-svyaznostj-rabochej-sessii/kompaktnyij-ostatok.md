# Chitatj ostatok neboljshimi stranicami

Komanda pokazyivayet vyibrannyiye originalyi iz uzhe sokhranyonnogo rezuljtata obyazateljnogo chitatelya. Ona ekonomit mesto v kontekste: syiryiye obyyektyi, dubli i dlinnyiye massivyi pozdnikh svyazej ostayutsya v polnom fajle, a stranica soderzhit tochnyiye ukazateli na nikh. Vyibrannoye soderzhimoye, vklyuchaya vlozheniya i neodnoznachnyiye formyi, peredayotsya bez sokrasjheniya.

## Poryadok rabotyi

Snachala vyipolnitj [obyazateljnoye chteniye](obrabotka-soobsjhenij.md) s `остаток --без-записи` i yavno sokhranitj stdout vne checkout. Kod 0 ili 3 dopuskayet razbor poluchennogo JSON; kod 2 oznachayet oshibku, kotoruyu neljzya zamenitj prezhnim uspeshnyim fajlom. Sokhraneniye stdout vyipolnyayet vyizyivayusjhaya storona: iskhodnyij bezzapisnyij chitatelj ne sozdayot artefakt.

Dlya stranicyi ukazatj polnyij fajl, zaraneye poluchennyij SHA-256 imenno yego bajtov, nachaljnyij nomer soobsjheniya s nulya i chislo soobsjhenij:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/показать-остаток.py --результат <приватный-полный-результат.json> --sha256 <SHA-256-полного-файла> --начало 0 --число 10 --максимум-байтов 16000
```

Komanda nichego ne zapisyivayet i ne zapuskayet Git, setj ili instrumentyi iz soderzhimogo. Ona proveryayet khyesh vsekh prochitannyikh bajtov, razbirayet JSON s zapretom povtornyikh klyuchej, proveryayet ssyilki ekzemplyarov i vozvrasjhayet novuyu obolochku `fum.страница-остатка.1`. Polnyij fajl i vse vyidavayemyiye originalyi ostayutsya privatnyimi. Fajl ogranichen 128 MiB; chislo soobsjhenij — ot 1 do 1000; predel otveta — ot 100 bajtov do 1 MiB, po umolchaniyu 16000 UTF-8-bajtov, vklyuchaya LF. Eto inzhenernyiye predelyi, ne limit tokenov modeli.

Kod 0 oznachayet toljko uspeshnoye predstavleniye stranicyi. Kod 2 oznachayet otkaz, stdout pust. Pri prevyishenii byudzheta nuzhno yavno umenjshitj chislo soobsjhenij ili uvelichitj byudzhet; tekst i vlozheniya ne usekayutsya. Yesli odno soobsjheniye boljshe maksimaljnogo byudzheta, yego neobkhodimo rassmotretj neposredstvenno v polnom artefakte. Garantii kompaktnosti ne podmenyayut sokhraneniye dannyikh.

## Kak prodolzhitj chteniye

`следующее_начало` zadayot sleduyusjhuyu stranicu **togo zhe** fajla s tem zhe SHA. `null` oznachayet dostizheniye konca vyibrannogo snimka, a ne prosmotr vsekh predyidusjhikh soobsjhenij i ne zaversheniye rabotyi. `показаны_все_сообщения` istinno toljko dlya vyidachi vsego spiska ot nulevogo nomera. `непоказанных_необработанных`, obsjhiye prichinyi i ukazatelj kornevogo massiva `остаток` pokazyivayut ostavshijsya za predelami stranicyi razbor.

Ukazateli imeyut format JSON Pointer: nachaljnyij razdelitelj U+002F, klyuch `сообщения`, yesjhyo odin razdelitelj i nomer `17` oboznachayut element 17 v polnom massive. `указатель_обработки` vedyot k yego prichinam, polnoj posledovateljnosti `поздние` i poslednej zapisi obrabotki. Uzhe obrabotannoye pozdneye soobsjheniye tozhe mozhno vyibratj po yego nomeru; odinakovyiye tekstyi ne obyyedinyayutsya.

Stranica ne podtverzhdayet aktualjnostj zhivogo JSONL. Ona sokhranyayet nablyudyonnyiye polnotu, neproverennyij khvost, granicyi i khyesh istochnika iz polnogo rezuljtata i otdeljno ukazyivayet `живой_источник_перепроверен=false`. Posle novogo vvoda nuzhen novyij rezuljtat obyazateljnogo chitatelya. Nomer stranicyi starogo fajla neljzya avtomaticheski perenositj na drugoj fajl: avtomaticheskij kursor mezhdu pokoleniyami yesjhyo ne realizovan.

Vse soobsjheniya ostatka po-prezhnemu trebuyetsya rassmotretj s pozdnimi utochneniyami i vidimyimi otvetami. Ikh uchyot i ispolneniye obyazateljstv ostayutsya raznyimi sostoyaniyami. Eta komanda ne izvlekayet otvetyi assistenta, ne raspoznayot smyisl otmenyi, ne menyayet istoriyu obrabotki i ne razreshayet zaversheniye zadachi. Osnovnoj chitatelj i sostavnoj dopusk ne izmenenyi.

## Proverka i izmereniye

```text
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_компактный_остаток.py
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_компактного_остатка.py --выход <профиль.json>
```

Otkryityij profilj sravnivayet polnuyu serializaciyu i stranicu poslednikh 10 iz 400 soobsjhenij na odnikh bajtakh. Podgotovka vkhoda i zapisj rezuljtatov isklyuchenyi iz vnutrennego vremeni; khyesh, razbor i serializaciya vklyuchenyi. Semj par chereduyut poryadok variantov. Pamyatj Python izmeryayetsya otdeljno. Sokrasjheniye vyivoda ne yavlyayetsya izmereniyem tokenov, kachestva reshenij ili uskoreniya vsego rabochego cikla.

## Istochniki

- [Postanovka i granica etapa](../../Zhurnal/2026-09-14_14-36-01_MSK_prinyatj-kompaktnyij-ostatok/zapros.md).
- [Profilj na otkryitom vkhode](../../Zhurnal/2026-09-14_14-36-01_MSK_prinyatj-kompaktnyij-ostatok/materialyi/iskhodnaya-peredacha.json).
- [Osnovnoj format i obrabotka soobsjhenij](obrabotka-soobsjhenij.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 14:48:49 MSK -->
<!-- content-sha256: sha256:3595e3ac6cfdae6c2e50d7fd35f72d2e00e92f400062bf6780f8a7f9f40dccbc -->
<!-- FUM-MD-RECENCY:END -->
