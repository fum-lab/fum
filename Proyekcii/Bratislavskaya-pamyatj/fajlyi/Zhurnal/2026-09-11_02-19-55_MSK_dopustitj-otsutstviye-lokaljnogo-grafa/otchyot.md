# Otchyot 2026-09-11 02:19:55 MSK - Dopustitj otsutstviye lokaljnogo grafa

Ispravlena prichina FUM-SBOJ-0052 v ogranichennoj oblasti FUM-STEP-0203: istoricheskaya Markdown-ssyilka na tochnyij `.obsidian/graph.json` dopustima, kogda lokaljnyij graf otsutstvuyet. Novyij rabochij katalog ne trebuyet sozdaniya poljzovateljskogo sostoyaniya. Proveryayusjhij kod toljko chitayet; susjhestvuyusjhij graf sokhranyayet bajtyi, inode i vremya izmeneniya.

Ispoljzuyetsya prezhnij razbor Markdown i prezhnyaya proverka ssyilok. Ogranichennoye isklyucheniye dobavleno toljko posle neudachnogo poiska celi. Ono proveryayet tochnyij putj, fakticheskij registr kazhdogo leksicheskogo komponenta, otsutstviye simvolicheskikh obkhodov, propusjhennyikh predkov i vyikhoda za korenj. Drugiye imena, suffiksyi, absolyutnyiye i vneshniye puti ne poluchayut novogo dopuska. Ispolnitelj 0177 podtverdil neperesekayusjhiyesya oblasti; yego chitatelj, guard i adapter sokhranenyi.

Nezavisimoye chteniye obnaruzhilo pogranichnyij sluchaj: fizicheskij katalog `.Obsidian` mog skryitj oshibku registra pri otsutstvii fajla. Novyij RED podtverdil yego; proverka fakticheskikh imyon ispravila defekt. Povtornoye chteniye prinyalo granicu registra bez dopolniteljnyikh susjhestvennyikh zamechanij. Proverennyij SHA-256 iskhodnika: `8d638fbcee111f6a42ee938ebee8658f89157834c070b550ab72ce7f8d62003f`.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                           |
| ------------------------ | ------------ | ---------------------------------------------------- |
| Soderzhateljnaya rabota    | ne izmereno  | Realizaciya, koordinaciya i chteniye; otdeljnogo tajmera ne byilo |
| Adresnyiye testyi           | 1,289003374 s | Summa pyati posledovateljnyikh processov obyortki № 1, 2, 4, 5, 6; pauzyi mezhdu nimi isklyuchenyi |
| Vosproizvodimyiye profili  | 2,736393542 s | Summa processov obyortki № 3 i 7; podgotovka i vyipolneniye scenariya vklyuchenyi |
| Standartnyij smoke-check  | ne izmereno  | Dlya promezhutochnoj kontroljnoj tochki ne zapuskalsya |

Granica profilya: 2026-09-11 02:19:55 MSK — 2026-09-11 02:36:29 MSK, ot sozdaniya sobstvennogo Zhurnala do zaversheniya adresnogo ispravleniya i profilya. Ozhidaniya FIFO i peredachi dereva ne byilo; lokaljnyij kommit i push nakhodyatsya za etoj granicej. Dliteljnosti testov i profilej pokazyivayut nablyudayemoye vremya processov, a ne polnuyu kalendarnuyu dliteljnostj etapa; ikh ne pribavlyayut k summe pryamyikh zapuskov nizhe. Posle granicyi vyipolnyayutsya toljko proverki oformleniya kontroljnoj tochki: svezhestj Markdown, chistota diff, tochnoye podklyucheniye obyyavlennoj zavisimosti i zaklyuchiteljnaya svyaznostj.

### Profilj izmenyonnogo povedeniya

[Scenarij](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/profilj_neobyazateljnogo_grafa.py) sozdayot otkryityij vremennyij istoricheskij otchyot s 25 odinakovyimi ssyilkami i vyipolnyayet pyatj zamerov po desyatj vyizovov dlya otsutstvuyusjhego grafa, susjhestvuyusjhego grafa i pokhozhego imeni. Podgotovka fiksturyi isklyuchena iz vnutrennikh intervalov. Metki `perf_counter_ns` otdeljno izmeryayut razbor i polnuyu proverku; proverka vklyuchayet razbor, poetomu eti intervalyi ne skladyivayutsya. Python 3.14.7, Darwin; vkhodyi, iskhodnik i scenarij svyazanyi SHA-256 v materialakh.

| Scenarij | Mediana razbora 25 ssyilok | Mediana polnoj proverki 25 ssyilok |
| -------- | ------------------------ | -------------------------------- |
| Graf otsutstvuyet | 0,076392 ms | 11,261775 ms |
| Graf susjhestvuyet | 0,074104 ms | 7,803092 ms |
| Pokhozheye imya | 0,076425 ms | 7,156079 ms |

[Pervonachaljnyij profilj](materialyi/profilj-grafa.json) sokhranyon neizmennyim kak svideteljstvo pervoj versii. [Profilj posle ispravleniya registra](materialyi/profilj-grafa-s-registrom.json) otnositsya k itogovomu iskhodniku. Dopolniteljnyij obkhod imyon trebuyetsya dlya korrektnosti i ogranichen ssyilkami na otsutstvuyusjhij tochnyij graf; izmerennyij scenarij ne dal osnovaniya vvoditj kyesh ili menyatj obsjhij algoritm. Etap optimizacii zavershyon resheniyem sokhranitj realizaciyu. Uskoreniye otnositeljno prezhnego koda ne zayavlyayetsya; rezuljtatyi raznyikh po korrektnosti versij ne ispoljzuyutsya kak dokazateljstvo uskoreniya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                 | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------- | ------------ | --------- |
| [Pisatelj grafa] Krasnaya granica neobyazateljnogo lokaljnogo grafa     | 0,149 s      | neuspeshno |
| [Pisatelj grafa] Zelyonaya granica neobyazateljnogo lokaljnogo grafa     | 0,146 s      | uspeshno   |
| [Pisatelj grafa] Profilj razbora i proverki ssyilok na graf            | 1,257 s      | uspeshno   |
| [Pisatelj grafa] Sokhranitj adresnyiye granicyi ssyilok posle profilya      | 0,401 s      | uspeshno   |
| [Pisatelj grafa] Krasnaya granica registra susjhestvuyusjhego predka        | 0,155 s      | neuspeshno |
| [Pisatelj grafa] Zelyonaya granica grafa i regressiya adresnyikh ssyilok    | 0,438 s      | uspeshno   |
| [Pisatelj grafa] Profilj posle sokhraneniya granicyi registra            | 1,48 s       | uspeshno   |
| [Pisatelj grafa] Proveritj probelyi tochnogo indeksirovannogo izmeneniya | 0,02 s       | uspeshno   |
| [Pisatelj grafa] Proveritj svezhestj Markdown kontroljnoj tochki        | 0,966 s      | uspeshno   |
| [Pisatelj grafa] Proveritj tochnoye podklyucheniye obyyavlennoj zavisimosti | 0,456 s      | uspeshno   |
| [Pisatelj grafa] Proveritj svezhestj posle utochneniya otchyota            | 0,932 s      | uspeshno   |
| [Pisatelj grafa] Proveritj probelyi posle utochneniya otchyota             | 0,019 s      | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 6,419 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

- Pervyij RED: tri testa, oba varianta otsutstviya grafa dali ozhidayemyiye oshibki; sokhraneniye susjhestvuyusjhego grafa i otricateljnyiye sluchai uzhe prokhodili. Posle iskhodnogo ispravleniya tri testa proshli.
- Vtoroj RED: novyij chetvyortyij test vyiyavil oshibochnoye razresheniye fizicheskogo `.Obsidian`. Posle proverki fakticheskikh imyon proshli vosemj adresnyikh testov, vklyuchaya chetyire susjhestvuyusjhikh regressii obsjhego validatora. Itogovyij profilj takzhe proveryayet chislo razobrannyikh ssyilok, chislo oshibok i neizmennostj grafa.
- Dlya povtoreniya adresnoj granicyi iz kornya: `python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_необязательный_граф.py`. Pri rabochem zapuske komanda peredayotsya susjhestvuyusjhej otchyotnoj obyortke s tochnyim zaprosom, ispolnitelem i klassom `адресная`.
- Dlya povtoreniya profilya: `python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_необязательного_графа.py --выход <публикационно-чистый-файл-json>`, takzhe cherez otchyotnuyu obyortku. Putj rezuljtata vyibirayetsya vne prezhnikh khyeshirovannyikh svideteljstv.

Proverki kontroljnoj tochki vyizyivayut `update-md-recency.py --check`, `git diff --check` i `check-session-coherence.py --контрольная-точка` s dannyim zaprosom i tochnyim vremennyim fajlom budusjhego soobsjheniya kommita. Predpisannyij zaklyuchiteljnyij read-only-dopusk vyipolnyayetsya posle predprosmotra vne obyortki; on ne sozdayot rekursivnuyu zapisj sobstvennogo izmereniya.

## Resheniya i ogranicheniya

Sokhranyayetsya promezhutochnaya kontroljnaya tochka vetki `refs/heads/codex/необязательный-граф-0203` ot `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`. Ona soderzhit iskhodnik, adresnyiye testyi, scenarij, profili i sobstvennoye proiskhozhdeniye. Soderzhateljnyiye izmeneniya ogranichenyi etoj prichinoj sboya; novaya identichnostj kartochki ne vyidelyalasj.

Pokoleniye manifesta `Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json` unasledovano iz iskhodnogo HEAD: SHA-256 manifesta `cc02a0482eeddea16d44b9049b9f062dc9004f3c09f97b47c9b71c288b7dde98`, vkhodnoj inventarj `sha256:544a1e4a110118a3a9e8957b50a3c4a8330380136ef524186f0892861bf62ff2`, 6478 zapisej. Eto sokhranyonnoye svideteljstvo prezhnego snimka. Ono otstayot ot novyikh kanonicheskikh fajlov etogo etapa i zdesj ne peresobiralosj.

Pervyij zaklyuchiteljnyij dopusk kontroljnoj tochki otklonil ssyilku sobstvennogo otchyota na strukturno isklyuchyonnuyu proyekciyu i istoricheskuyu ssyilku na licenziyu yesjhyo ne podklyuchyonnogo LinguisticKit; oshibok lokaljnogo grafa ne ostalosj. Ssyilka na proyekciyu zamenena tochnyim tekstovyim imenem. Obyyavlennaya zavisimostj podklyuchena polnocennyim klonom v sobstvennom dereve na neizmennom gitlink `837e2ce107b97ee7b9d3344c9fe99142281fe393`; yeyo avtonomnaya proverka proshla. Chuzhiye klonyi i obsjhij Git-config ne menyalisj. Povtornyij dopusk proveryayet tot zhe ispravlennyij kod na polnom nabore dostupnyikh ssyilok.

Ostatok pered finaljnoj priyomkoj: proverka i integraciya rezuljtata kornem, aktualjnoye pokoleniye proyekcii, standartnyij dokumentacionnyij smoke-check na integrirovannom snimke i zakryitiye yego otchyota. Kontroljnaya tochka ne zavershayet FUM-STEP-0201 ili vsyu kornevuyu zadachu i ne oznachayet prodvizheniya `master`. Publikaciya sobstvennogo kommita vyipolnyayetsya tochnyim OID v odnoimyonnuyu vetku bez force.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:43:00 MSK -->
<!-- content-sha256: sha256:3f8f8abb8cfc6038aa7965162de8bf28547b5d1d792dd892bcb108d8da22f292 -->
<!-- FUM-MD-RECENCY:END -->
