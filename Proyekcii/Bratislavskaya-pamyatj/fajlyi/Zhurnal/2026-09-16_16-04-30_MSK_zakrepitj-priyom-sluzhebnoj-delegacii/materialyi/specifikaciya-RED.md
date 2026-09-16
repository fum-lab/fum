# Specifikaciya adresnogo RED

Eto plan proverok posle polucheniya vyibrannoj koordinatorom neizmenyayemoj zapisi razreshyonnoj svyazi. Ispolnyayemyij test yesjhyo ne napisan i ne zapusjhen. Realjnyij priyom zapresjhyon tekusjhim utochneniyem do peredachi yakorya.

## Nemaskiruyusjhij iskhodnyij sluchaj

Ispoljzovatj ustrojstvo fiksturyi iz [test_dopusk_soobsjhenij.py](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_dopusk_soobsjhenij.py): vremennyij sobstvennyij Git-repozitorij, korrektnyij JSONL ispolnitelya, razovyij plan v1 s zavershyonnoj prezhnej rabotoj i polnocennyim sobstvennyim osnovaniyem. Chelovecheskij ostatok raven nulyu. Kontroljnyij vyizov starogo guard bez novogo prinyatiya dolzhen imetj exit 0 i resheniye zavershitj; inache fikstura maskiruyet defekt postoronnim otkazom.

Vnesti proveryayemuyu sluzhebnuyu dostavku v yeyo realjnoj obolochke function_call_output. Podgotovitj otdeljnoye tipizirovannoye prinyatiye toljko otnositeljno nezavisimo vyibrannogo polnomochnogo yakorya. Plan ostayotsya prezhnim, svyazannoj rabotyi net. Yedinstvennaya celevaya prichina otkaza — nepokryitoye dejstviteljnoye prinyatiye, ozhidayemyij exit 2; nedejstviteljnaya fikstura, neizvestnyij flag ili povrezhdyonnyij JSON ne schitayutsya nuzhnyim RED.

Posle shtatnoj registracii nevyipolnennoj rabotyi, svyazannoj s tem zhe prinyatiyem i iskhodnyim osnovaniyem, ozhidatj exit 3, resheniye prodolzhitj i tochnyij ID etoj rabotyi. Postoyannyij v1 i chastichnyij v3 ne ispoljzovatj vmesto osnovnogo sluchaya: oni uzhe trebuyut prodolzheniya.

## Sosedniye adresnyiye proverki

| Izmeneniye vkhoda | Ozhidayemaya granica |
| --- | --- |
| XML ili source_thread_id bez vyibrannogo yakorya | Polnomochiye ne podtverzhdeno; registraciya ne proiskhodit |
| Razgovornoye assistant «prinyal» | Ne sozdayot tipizirovannogo prinyatiya |
| Chuzhoj UUID ispolnitelya ili koordinatora | Otkaz, bez zapisi |
| Izmenyon diapazon/SHA dostavki ili iskhodnoye osnovaniye | Otkaz, bez zapisi |
| Povtor rovno togo zhe yavnogo prinyatiya | Idempotentnostj, bez vtorogo obyazateljstva/statusa |
| Udaleniye/perenaznacheniye prinyatiya v dostizhimoj istorii | Otkaz cherez susjhestvuyusjhij polnyij DAG |
| Rabota otsutstvuyet libo svyazana s drugim prinyatiyem | Exit 2, a ne zavershitj |
| Istochnik, svyazj ili reyestr menyayutsya mezhdu pervyim chteniyem i vyidachej guard | Otkaz pri zaklyuchiteljnoj sverke |
| Zavershyon toljko etap/rebyonok | Roditeljskoye obyazateljstvo koordinatora ne pogashayetsya |

Statusyi rabotyi i dokazateljstva yeyo priyomki ostayutsya susjhestvuyusjhimi; tipizirovannoye prinyatiye ne dubliruyet zhiznennyij cikl. Otdeljno sokhranitj shtatnyij prioritet dejstviteljnoj ostanovki cheloveka. Polnota toljko po proverennomu dolgovechnomu naboru prinyatij; otsutstviye nezapisannogo razgovornogo prinyatiya ne dokazyivayetsya.

## V3 i otdeljnaya rabota

V [proverke v3](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/obyazateljstva_zadachi.py) opredeleniye rabotyi vklyuchayet ID, obyazateljstvo, dejstviye, osnovaniye, predposyilki, ozhidaniye i tochnyiye puti rezuljtatov. Osnovaniye ravno osnovaniyu roditeljskogo obyazateljstva. Opredeleniya neizmenyayemyi na ryobrakh istorii, krome ozhidaniya; priyomka svyazyivayetsya s konkretnoj rabotoj. Poetomu uzhe prinyatuyu FUM-OSTATOK-REYESTR neljzya pereimenovatj ili ispoljzovatj yeyo priyomku kak dokazateljstvo novogo priyoma delegacii. Vyibor novoj root-rabotyi i yeyo prinyatiye ostayotsya koordinatoru.

## Profilj

Na odnoj otkryitoj fiksture sokhranitj versiyu koda, vkhodnyiye khyeshi i razdeljnyiye dliteljnosti chteniya istochnika, proverki vyibrannogo yakorya/diapazonov, istorii prinyatij, pokryitiya rabotoj i zaklyuchiteljnoj sverki. Snachala korrektnostj RED/GREEN, zatem iskhodnyij zamer i opravdannaya optimizaciya libo resheniye ostavitj kod po izmereniyu. Etot profilj ne izmeryayet nativnyij Stop i ne obesjhayet yego byudzhet.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 16:15:40 MSK -->
<!-- content-sha256: sha256:c9ed158557303dc34ce76b2f6c98dfaa23c6afc0c48202bbc6119ca925ce83f4 -->
<!-- FUM-MD-RECENCY:END -->
