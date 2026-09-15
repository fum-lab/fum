# Bezopasnyij perevod privyazok Python

Python-vetvj perevodchika vyibirayet zamenyayemyiye diapazonyi po sintaksicheskoj roli i leksicheskoj oblasti. Vneshniye atributyi, importiruyemyiye imena i klyuchevyiye argumentyi vneshnikh vyizovov sokhranyayutsya. Naprimer, pri perevode lokaljnogo `env` v vyirazhenii `subprocess.run(env=env)` menyayetsya toljko znacheniye argumenta.

Obyichnaya karta i komandyi `план`/`применить` sokhranyayut prezhnij format. Pered primeneniyem trebuyetsya prosmotretj iskhodnyij i itogovyij khyeshi, a posle nego proveritj zatronutyikh potrebitelej. Soglasovannoye pereimenovaniye odinakovogo imeni v neskoljkikh nezavisimyikh oblastyakh razresheno obyichnoj kartoj; dlya chastichnoj migracii nuzhen otdeljnyij vyibor oblastej. Obsjhij snimok istoricheskogo ostatka avtomaticheski ne obnovlyayetsya.

## Oblastj dejstviya

Vspomogateljnyij modulj `scripts/безопасные_привязки_python.py` razlichayet modulj, funkciyu, lyambdu, klass i generator. On uchityivayet parametryi, isklyucheniya, yavnyiye psevdonimyi importov, `global` i `nonlocal`. Import bez psevdonima sokhranyayet vneshnij kontrakt. Smesheniye importnoj i sobstvennoj privyazki zakryivayet preobrazovaniye otkazom.

AST zadayot tochnyiye diapazonyi iskhodnogo teksta; bajtovyiye stolbcyi perevodyatsya v simvoljnyiye. Iskhodnyij tekst ne peresozdayotsya cherez `ast.unparse`. Kommentarii, obyichnyiye stroki i vsyo vne vyibrannyikh diapazonov sokhranyayutsya. Vyirazheniya vnutri formatnyikh strok uchityivayutsya; izmeneniye otladochnoj stroki s vyivodimoj metkoj zapresjheno. Iskhodnik i itog kompiliruyutsya bez ispolneniya, chtobyi vyiyavlyatj ogranicheniya, kotoryiye odin `ast.parse` ne proveryayet.

Imenovannyiye argumentyi perevodyatsya toljko dlya razreshyonnogo pryamogo vyizova sobstvennoj funkcii ili prostogo konstruktora s sobstvennyim inicializatorom. Peredacha funkcii s izmenyonnoj signaturoj drugomu potrebitelyu trebuyet yavnogo razbora. Sobstvennyiye polya podderzhanyi toljko u neposredstvennogo, ne pereprivyazannogo poluchatelya metoda; `сам.tmp.name` ne stanovitsya sobstvennyim polem po odnomu prefiksu `сам`.

Pozicionnyiye parametryi do `/`, imena `*args` i `**kwargs` ne zadayut perevod klyuchej peredannogo slovarya. Signaturnyij risk peredachi otnositsya k dejstviteljno prinimayemyim po imeni parametram; lokaljnoye imya sobirayemoj raspakovki samo po sebe vyizyivayemuyu signaturu ne menyayet. Pryamaya lambda i yeyo yedinstvennaya nepereprivyazannaya imenovannaya privyazka soglasuyutsya s sobstvennyimi vyizovami. Dekorator funkcii libo klassa ne dokazyivayet vyizyivayemuyu signaturu. `global` uchityivayetsya vo vsekh promezhutochnyikh funkciyakh; `nonlocal` propuskayet prostranstva klassov.

Neizvestnyij vladelec svoyego polya, neogranichennyij import, neodnoznachnyij vyizov, dinamicheskoye prostranstvo imyon, strokovyiye annotacii i perechni imyon, refleksiya, sopostavleniye obrazcov i prisvaivaniye v vyirazhenii trebuyut otdeljnogo dopuska. Otkaz oznachayet, chto nuzhno utochnitj proveryayemuyu kartu libo rasshiritj avtomatizaciyu cherez RED/GREEN. On ne razreshayet ruchnuyu seriyu zamen.

Eto ogranichennyij staticheskij analiz odnogo fajla. On ne dokazyivayet polnotu mezhfajlovyikh importov, strokovyikh potrebitelej i vneshnikh vyizovov. Gotovnostj migracii trebuyet otdeljnogo perechisleniya etikh svyazej, proverki iskhodnyikh khyeshej i adresnyikh regressij. V chastnosti, pereimenovaniye sobstvennoj funkcii `git` dolzhno uchityivatj `patch.object(module, "git", ...)`.

## Paket svyazannyikh fajlov

Komanda `scripts/пакет_перевода_python.py план --корень-репозитория . --карта <карта.json> --выход <план.json>` gotovit vesj paket bez zapisi iskhodnikov. Komanda `применить` s temi zhe argumentami povtorno proveryayet vse vkhodyi i primenyayet podgotovlennyiye diapazonyi. Vyikhod plana dolzhen byitj otdeljnyim fajlom. Pered primeneniyem sravnivayutsya tochnyiye bajtyi plana s prosmotrennyim rezuljtatom. CLI ne obnovlyayet obsjhij snimok obyyavlenij.

Skhema `fum.пакет-перевода-python.1` soderzhit spisok fajlov. Kazhdyij fajl zadayot tochnyij otnositeljnyij putj, SHA-256 iskhodnyikh bajtov bez prefiksa, kartu `переводы`, vyibor `области`, perechni `связи` i `передачи`. `области: null` vyibirayet vse sobstvennyiye privyazki; obyyekt ogranichivayet perechislennyiye imena koordinatami ikh leksicheskoj oblasti. Para `(0, 0)` oznachayet modulj. Neobyazateljnyiye `имена_областей` zadayut otdeljnoye russkoye imya dlya tochnoj trojki «stroka, bajtovyij stolbec, prezhneye imya».

Svyazj zakreplyayet postavsjhika, vyirazheniye vladeljca, staroye i novoye imya i tochnoye kolichestvo. Podderzhanyi atribut i prostaya stroka imeni v `.object(владелец, "имя", …)`. Smyisl svyazi i polnotu spiska podtverzhdayet revjyu; sovpadeniye AST i schyotchika ne vyivodit tip obyyekta. Vstroyennyij Python dopuskayetsya toljko cherez `код` s koordinatoj i khyeshem polnogo strokovogo znacheniya. Obyichnyiye stroki avtomaticheski ne prevrasjhayutsya v kod.

`передачи` soderzhit tochnyiye koordinatyi Name libo lambda, oboznachennoj `<lambda>`. Eto proverennyij chelovekom kontrakt pozicionnogo vyizova potrebitelem, a ne vyivod signaturyi vneshnej funkcii. Dopuskayutsya neposredstvennyij argument vyizova i yavno vyibrannoye znacheniye lambda po umolchaniyu; poluchatelj v `callback.__call__` dopuskom ne schitayetsya. Neizvestnyiye ili neispoljzovannyiye selektoryi otklonyayutsya.

Neobyazateljnoye pole `исполнения` soderzhit paryi «stroka, bajtovyij stolbec» pryamyikh `exec`/`eval` s dvumya ili tremya pozicionnyimi argumentami. Eto yavnoye podtverzhdeniye proverennoj chelovekom otdeljnoj testovoj sredyi; avtomatizaciya ne dokazyivayet otsutstviye mutacij ili aliasov slovarya. Pustoj slovarj sam po sebe dopuska ne dayot. Koordinatyi zakreplyayutsya iskhodnyim khyeshem, perenosyatsya cherez pravki svyazej i obyazanyi oboznachatj rovno podderzhannyij vyizov. Dlya otdeljno prosmotrennogo modulya dopuskayetsya takzhe prostranstvo `имя_модуля.__dict__`; prinadlezhnostj konkretnomu vnovj sozdannomu modulyu podtverzhdayetsya chelovekom po tochnyim bajtam, a ne vyivoditsya po odnomu imeni atributa. Neyavnoye ispolneniye v lokaljnom prostranstve ne podderzhano. Posle vyibora individualjnyikh imyon oblastej dopolniteljno zapresjhayetsya sliyaniye raznyikh prezhnikh imyon v odnu effektivnuyu celj.

Neobyazateljnoye pole `внешние_вызовы` zadayot koordinatyi pryamyikh vyizovov prostogo imeni, chjya vneshnyaya prinadlezhnostj ustanovlena vruchnuyu. Naprimer, v profile eto sokhranyonnyij iskhodnyij `subprocess.Popen` s neizmenyonnoj peredachej `*args, **kwargs`. Selektor i khyesh zakreplyayut tochnoye vyizyivayemoye imya, formu vyizova i istochnik; imya lokaljnogo psevdonima samo po sebe vneshnego kontrakta ne dokazyivayet. Bez selektora i dlya neizvestnoj koordinatyi prezhnij otkaz sokhranyayetsya.

Paket zapresjhayet povtornyiye puti, nevernyij registr, simvolicheskiye ssyilki, nesovpadeniye vkhodnyikh khyeshej, kollizii i neizvestnyiye polya. Pered zamenoj perechityivayutsya vse iskhodniki. Zapisj kazhdogo fajla atomarna; paket ne obesjhayet obsjhej fajlovoj tranzakcii pri apparatnom sboye ili oshibke OS vo vremya posledovateljnyikh zamen. Trebuyetsya odin pisatelj dereva.

Gotovyij primer s klassifikaciyej i komandami vosproizvedeniya — [migraciya unasledovannogo Python](migraciya-unasledovannogo-Python.md).

## Proverka i profilj

Adresnyij nabor — `tests/test_безопасный_перевод_python.py`. On proveryayet vneshniye API, zateneniye importov, oblasti generatorov, sobstvennyiye klyuchevyiye argumentyi, strokovyiye svyazi i otkazyi pri potere vladeljca. Pri zapuske v rabochej sessii ispoljzuyetsya obyazateljnaya otchyotnaya obyortka.

Scenarij `tests/измерить_безопасный_перевод_python.py --выход <файл.json>` vyipolnyayet pyatj posledovateljnyikh povtorov na 400 funkciyakh bez ispolneniya vkhodnogo koda. Rezuljtat soderzhit khyeshi vkhoda, rezuljtata, ispolnitelya i scenariya, versiyu Python i monotonnyiye dliteljnosti stadij. Parametr `--функций` zadayot razmer. Povtoryi sravnivayutsya toljko pri odinakovyikh vkhode, scenarii i rezuljtate; perekryivayusjhiyesya proverki ne skladyivayutsya s kalendarnyim vremenem etapa.

## Istochniki

- [Postanovka FUM-STEP-0173](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0173-razobratj-drejf-snimka-obyyavlenij.md).
- [Razrabotka i svideteljstva](../../Zhurnal/2026-09-14_20-07-02_MSK_obespechitj-bezopasnyij-perevod-Python/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 22:10:02 MSK -->
<!-- content-sha256: sha256:7c27285d6a5fc2a6421229d25d24724bb526e14e05bfa50e667b2b1619f4e462 -->
<!-- FUM-MD-RECENCY:END -->
