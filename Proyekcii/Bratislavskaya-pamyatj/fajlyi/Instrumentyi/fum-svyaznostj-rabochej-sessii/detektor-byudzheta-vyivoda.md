# Avtomaticheski vyibiratj kompaktnoye chteniye po byudzhetu

Lokaljnaya komanda sravnivayet razmer sokhranyonnogo ostatka s zadannyim byudzhetom stdout v **bajtakh**. Pri prevyishenii ona sama vyizyivayet susjhestvuyusjhij kompaktnyij chitatelj; povtornoye porucheniye cheloveka dlya vyibora ne trebuyetsya. Pri ravenstve ili menjshem razmere vozvrasjhayutsya tochnyiye iskhodnyiye bajtyi, bez pereserializacii. Eto ne izmereniye tokenov i ne perekhvat vsekh instrumentov Codex.

## Zapusk

Snachala sokhranite polnyij stdout osnovnogo `обработать-сообщения-задачи.py ... остаток --без-записи` vne checkout, otdeljno zapomniv yego kod zaversheniya. Kod 2 oznachayet oshibku: staryij fajl ne podstavlyayetsya. Zatem vyichislite SHA-256 fakticheskikh bajtov i vyizovite:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/потребить-остаток.py --результат <приватный-файл.json> --sha256 <SHA-256> --код-производителя 3 --бюджет-байтов 16000 --начало 0 --число 1
```

stdout soderzhit toljko vyibrannyiye dannyiye. stderr soderzhit otdeljnuyu JSON-kvitanciyu: sokhranite yeyo otdeljno, yesli vyizyivayusjhij instrument inache obyyedinyayet oba kanala. Byudzhet otnositsya toljko k stdout; kvitanciya ne skryivayetsya v etom chisle. Na otkryitom profile ona zanimayet 808 bajtov dopolniteljno. Skript nichego ne zapisyivayet, ne zapuskayet proizvoditelya, ne vyipolnyayet komandyi iz dannyikh, Git ili setj. Privyazku privatnogo puti, zapuska proizvoditelya i yego koda sokhranyayet vyizyivayusjhaya storona.

Kod CLI 0 oznachayet uspeshnyij vyibor predstavleniya, a ne pustoj ostatok. Iskhodnyij kod 0 ili 3 sokhranyayetsya v kvitancii i proveryayetsya na soglasovannostj s `разбор_сообщений_завершён`. Peredannyij kod ne dokazyivayet podlinnostj vneshnego zapuska. Kod CLI 2 oznachayet otkaz s pustyim stdout i otdeljnoj diagnostikoj: nevernyij SHA, kod, JSON, skhema, identichnostj zadachi, parametryi libo prevyisheniye byudzheta stranicyi. Oshibku neljzya zamenyatj prezhnim uspeshnyim rezuljtatom.

## Granicyi vyibora

Prinimayetsya toljko `fum.остаток-сообщений.1`, ne boleye 128 MiB, s kanonicheskim UUID zadachi. Porog — yavno peredannoye celoye ot 100 do 1 048 576 bajtov; bulevo znacheniye ne prinimayetsya API. Formula srabatyivaniya: fakticheskoye chislo bajtov polnogo fajla strogo boljshe byudzheta. LF iskhodnika vkhodit v yego razmer; LF kompaktnoj stranicyi vkhodit v razmer vyivoda.

Parametryi `начало` i `число` vyibirayut stranicu toljko pri prevyishenii. Po umolchaniyu eto pervoye soobsjheniye; avtomaticheskogo poiska poslednego ili samogo udobnogo soobsjheniya net. Yesli zadannaya stranica ne pomesjhayetsya, umenjshite chislo; yesli ne pomesjhayetsya odno soobsjheniye vmeste s obolochkoj, rassmotrite polnyij privatnyij artefakt adresno ili yavno uvelichjte byudzhet. Soderzhimoye ne usekayetsya i soobsjheniya ne propuskayutsya avtomaticheski.

Polnyij fajl ostayotsya istochnikom vsekh originalov, povtorov, pozdnikh svyazej i proiskhozhdeniya. Stranica soderzhit SHA polnogo fajla, ukazateli, schyotchiki i priznaki polnotyi po [susjhestvuyusjhemu kontraktu](kompaktnyij-ostatok.md). Sleduyusjhaya stranica otnositsya toljko k tomu zhe fajlu/SHA. Konec poslednej stranicyi ne podtverzhdayet rassmotreniye predyidusjhikh soobsjhenij. Zhivoj JSONL ne pereproveryayetsya, obrabotka i vyipolneniye obyazateljstv ne podtverzhdayutsya.

Eto ogranichennaya realizaciya reakcii na izmerennoye prevyisheniye odnogo sokhranyonnogo vyivoda. Sinteticheskij byudzhet `Проекты/рабочий-контекст/сборщик.py` otnositsya k drugomu formatu. Deklarativnyiye DETEKTOR-03, 04 i 08 ne obyyavlyayutsya polnostjyu podklyuchyonnyimi ili otkalibrovannyimi. Statistika vyizovov JSONL ne podklyuchayetsya k etomu vkhodu avtomaticheski. Dlya realjnogo runtime vyizyivayusjhaya storona dolzhna napravlyatj sokhranyonnyij rezuljtat v etot CLI; obsjhij perekhvat otsutstvuyet.

## Proverka i profilj

```text
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_детектор_вывода.py
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_детектора_вывода.py --выход <профиль.json>
```

V rabochej sessii komandyi vyipolnyayutsya cherez otchyotnuyu obyortku. Desyatj testov proveryayut avtomaticheskij vyibor, N/N−1 polnogo fajla i stranicyi, tochnyiye iskhodnyiye bajtyi, soglasovannostj koda, ogranichennuyu identichnostj kvitancii, nepolnotu, determinizm i otsutstviye chastichnogo vyivoda.

Otkryityij profilj ispoljzuyet odin fajl 12 003 881 bajt, semj chereduyusjhikhsya par ruchnogo i avtomaticheskogo vyibora odnoj i toj zhe stranicyi. Vyikhodyi pobajtovo ravnyi: 2305 bajtov stranicyi i dopolniteljno 808 bajtov kvitancii detektora. Posle ustraneniya dvojnogo razbora mediana detektora snizilasj s 38,112208 do 24,239167 ms; ruchnoj vyibor v itogovom progone — 19,258375 ms. Avtomaticheskoye resheniye imeyet dopolniteljnuyu stoimostj. Kriterij do optimizacii: ta zhe vyidacha i ne khuzhe iskhodnoj medianyi plyus maksimum iz 5 ms i 25%; on vyipolnen. Podgotovka, fajlovyij vvod, zapusk Python, setj i zapisj profilya ne vkhodyat v eti intervalyi. Eto ne profilj vsego rabochego cikla.

## Istochniki

- [Porucheniye, utochneniya i proverki](https://github.com/fum-lab/fum/blob/cb3adea7267ecb6a66c0d2399e6f1fd21afc181e/Журнал/2026-09-15_15-10-25_MSK_обнаруживать-превышение-бюджета-вывода/запрос.md).
- [Iskhodnyij profilj](https://github.com/fum-lab/fum/blob/cb3adea7267ecb6a66c0d2399e6f1fd21afc181e/Журнал/2026-09-15_15-10-25_MSK_обнаруживать-превышение-бюджета-вывода/материалы/профиль-до.json) i [itogovyij profilj](https://github.com/fum-lab/fum/blob/cb3adea7267ecb6a66c0d2399e6f1fd21afc181e/Журнал/2026-09-15_15-10-25_MSK_обнаруживать-превышение-бюджета-вывода/материалы/профиль-итог.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 16:48:05 MSK -->
<!-- content-sha256: sha256:2d479bdd2fada659d840eab2cef680405866c3a63b6e926917bc9db936ab8f7d -->
<!-- FUM-MD-RECENCY:END -->
