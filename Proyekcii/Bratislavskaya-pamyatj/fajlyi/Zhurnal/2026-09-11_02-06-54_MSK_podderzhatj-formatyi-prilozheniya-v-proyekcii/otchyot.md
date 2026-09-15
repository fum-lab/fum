# Otchyot 2026-09-11 02:06:54 MSK - Podderzhatj formatyi prilozheniya v proyekcii

Proyekciya prinimayet shestj fakticheskikh formatov perenosimogo prilozheniya FUMA s tochnyim sokhraneniyem soderzhimogo. `.c` i `.h` otnosyatsya k kodu; `.modulemap`, `.pbxproj`, `.plist` i `.entitlements` — k prochim tochnyim formatam. Tekhnicheskij suffiks otdelyayetsya ot preobrazuyemoj osnovyi imeni. Vlozhennyij `.gitignore` dopuskayetsya toljko po polnomu puti `Приложения/FUMA/macOS/.gitignore`.

Eto proverennaya na adresnyikh scenariyakh narabotka dlya integracii kornem. Obsjhaya priyomka i aktualjnoye pokoleniye proyekcii yesjhyo ne vyipolnenyi. Izmeneniye ne zatragivayet pravila agentov, LinguisticKit, vneshniye zavisimosti i iskhodniki prilozheniya. Podderzhka `.xcscheme` i `.js` ne dobavlena.

## Proverki i prinyatyiye resheniya

Pervyij RED zapustil chetyire novyikh scenariya protiv prezhnej realizacii: vse shestj formatov v nizhnem i verkhnem registre i tochnyij vlozhennyij `.gitignore` byili otvergnutyi; proverka imeni takzhe pokazala neotdelyonnyij tekhnicheskij suffiks. Eto dejstviteljnyij otkaz trebuyemogo povedeniya. Posle sinkhronizacii tochnyikh spiskov vtoroj zapusk vyiyavil oshibku samoj novoj fiksturyi: korenj celi byil dvazhdyi dobavlen k repozitorno-otnositeljnomu puti. Ispravleniye zatronulo toljko chteniye testovogo vyikhoda; tretij zapusk zavershilsya uspeshno.

Adresnaya regressiya proshla semj scenariyev: chetyire novyikh, otkaz neizvestnogo tekstovogo fajla, strogiye mashinnyiye polya i sokhrannostj tryokh fajlov versii 1 po prezhnim zakreplyonnyim khyesham. CLI proverki kontrakta zavershilsya uspeshno. Posle privedeniya smyislovogo imeni odnogo novogo testa k kirillice otdeljno podtverzhdyon yego zapusk. Vse pryamyiye processyi, vklyuchaya promezhutochnyij neuspekh, nakhodyatsya v mashinnom zhurnale nizhe.

Fikstura sozdayot semj fajlov v chastnom vremennom Git-dereve, peredayot podstavnoj preobrazovatelj, primenyayet i nezavisimo proveryayet pokoleniye. Sveryayutsya bajtyi s `ё` i CRLF, tochnyiye tekhnicheskiye suffiksyi, registraciya klassov i uzostj puti `.gitignore`. Otkaz sokhranyayetsya dlya drugogo prilozheniya, vlozhennogo kataloga, nevernogo registra puti, `.xcscheme`, `.xyz`, `.h.bak` i samovoljnogo rasshireniya kontrakta. Zhivoye pokoleniye repozitoriya i Swift ne ispoljzuyutsya.

Otdeljnaya proverka Git-zavisimosti otklonila razreshyonnyij dlya istoricheskikh ssyilok samostoyateljnyij klon: shtatnyij kontrakt trebuyet svyazannyij `.git`-fajl v Git-kataloge worktree, togda kak lokaljnyij klon imeyet sobstvennuyu `.git`-direktoriyu. Eto chestno sokhranyonnyij otkaz topologicheskoj proverki, a ne gotovnostj zavisimosti k zhivoj generacii. V tom sostavnom vyizove proverka diff i svyaznosti yesjhyo ne zapuskalisj; daleye oni vyipolnyayutsya otdeljno. Topologiya ne perestraivayetsya za predelami razresheniya, validator ne oslablyayetsya. Polnaya inicializaciya dlya obsjhego smoke-check ostayotsya kornyu.

Proverka svyaznosti obnaruzhila lishnyuyu pustuyu stroku neposredstvenno pered trailer vremennogo soobsjheniya kommita. Dobavlena yavnaya itogovaya stroka kontroljnoj tochki s kanonicheskim otdeleniyem trailer; dva iskhodnyikh poljzovateljskikh teksta sokhranenyi bez izmeneniya. Otkaz takzhe uchtyon otdeljno.

## Profilj i resheniye ob optimizacii

[Mashinnoye izmereniye](materialyi/profilj-formatov-do.json) sokhranyayet iskhodnyiye puti i bajtyi, SHA-256 realizacii i kontrakta, bazovyij commit, Python 3.14.7 i arkhitekturu arm64. Vkhod — semj korotkikh UTF-8 fajlov bez NUL; kazhdyij iz pyati povtorov vyipolnyayet 2000 ciklov po semi putyam. Izmereniye ispoljzuyet `perf_counter_ns`, vklyuchayet sozdaniye `Path('.')` i proverku rezuljtata kazhdogo vyizova. Chteniye fajlov, import modulya, Git, sborka, LinguisticKit i generaciya pokoleniya ne vkhodyat vo vnutrennyuyu stoimostj klassifikacii.

Mediana — 4.280310 mks na vyizov. Zagruzka i validaciya politiki zanyali 0.185916 ms. Vyibrannyij do zapuska oriyentir — meneye 100 mks na klassifikaciyu; eto porog resheniya dlya dannogo sinteticheskogo sluchaya, a ne produktovyij SLA. Izmeneniye algoritma ili kyeshirovaniye ne opravdanyi: novyij kod rasshiryayet konechnyiye neboljshiye perechni, a nablyudyonnaya stoimostj susjhestvenno nizhe oriyentira. Uskoreniye ne zayavlyayetsya. Po utochneniyu koordinatora povtor profilya bez izmeneniya algoritma ne vyipolnyalsya; korrektnostj podtverzhdena posleduyusjhej regressiyej.

Dlya vosproizvedeniya zapustitj sleduyusjhij Python-fragment iz kornya chistogo klona cherez otchyotnuyu obyortku svoyej sessii s klassom `адресная`; standartnaya biblioteka dostatochna. Fragment pechatayet pyatj vnutrennikh dliteljnostej i medianu v nanosekundakh, bez seti i Swift:

```python
from pathlib import Path
import importlib.util, statistics, time
каталог = Path('Инструменты/fum-bratislavskaya-proyekciya-pamyati')
спецификация = importlib.util.spec_from_file_location(
    'проекция', каталог / 'scripts/братиславская_проекция_памяти.py')
модуль = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(модуль)
политика = модуль.загрузить_политику(каталог / 'контракт-v2.json')
пути = [f'Приложения/FUMA/macOS/Пример{суффикс}' for суффикс in
        ('.c', '.h', '.modulemap', '.pbxproj', '.plist', '.entitlements')]
пути.append('Приложения/FUMA/macOS/.gitignore')
данные = 'Точные байты: ё\r\n'.encode('utf-8')
замеры = []
for повтор in range(5):
    начало = time.perf_counter_ns()
    for цикл in range(2000):
        for путь in пути:
            assert модуль.классифицировать_содержимое(
                Path('.'), путь, политика, данные)[1] == 'сохранить_байты'
    замеры.append(time.perf_counter_ns() - начало)
print(замеры, statistics.median(замеры) / 14000)
```

## Profilj vremeni vyipolneniya

| Stadiya                            | Dliteljnostj | Granicyi i sposob izmereniya                                              |
| --------------------------------- | ------------ | ---------------------------------------------------------------------- |
| Chteniye, zhurnal i realizaciya        | ne izmereno  | Dliteljnostj ne vosstanavlivayetsya zadnim chislom                          |
| Zagruzka i validaciya politiki      | 0,000186 s   | Odna para perf_counter_ns posle importa modulya                          |
| Klassifikaciya 70000 fajlov         | 0.299753 s   | Summa pyati posledovateljnyikh neperesekayusjhikhsya intervalov perf_counter_ns |
| Adresnyiye proverki i dopusk         | ne izmereno  | Kazhdyij fakticheskij process otdeljno izmeren obyortkoj nizhe               |
| Standartnyij i polnyij smoke-check   | ne izmereno  | Ne zapuskalisj; priyomka ostayotsya kornyu                                 |

Granica profilya: s sozdaniya tekusjhej papki Zhurnala do predkommitnoj proverki kontroljnoj tochki. Ozhidaniye FIFO, Swift i finaljnaya integraciya otsutstvuyut. Vnutrenniye intervalyi profilya vlozhenyi v pryamoj vyizov obyortki i povtorno k yego vremeni ne pribavlyayutsya. Posle granicyi vyipolnyayutsya toljko predprosmotr, recency, chteniye diff i zaklyuchiteljnaya read-only proverka kontroljnoj tochki.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                                               | Dliteljnostj | Rezuljtat |
| --------------------------------------------------------------------------------------------------- | ------------ | --------- |
| [Formatyi] RED: tochnyiye formatyi prilozheniya                                                            | 0,617 s      | neuspeshno |
| [Formatyi] GREEN: tochnyiye formatyi prilozheniya                                                          | 1,443 s      | neuspeshno |
| [Formatyi] GREEN: ispravlennaya adresaciya testovogo vyikhoda                                            | 1,922 s      | uspeshno   |
| [Formatyi] Profilj: klassifikaciya semi formatov do resheniya ob optimizacii                            | 0,457 s      | uspeshno   |
| [Formatyi] Regressiya: formatyi prilozheniya, neizvestnyij tekst, strogij kontrakt i sokhrannostj versii 1 | 2,406 s      | uspeshno   |
| [Formatyi] Kontrakt i kanonicheskoye imya proverki uzkogo isklyucheniya                                    | 0,4 s        | uspeshno   |
| [Formatyi] Dopusk: zavisimostj, chistota diff i svyaznostj sessii                                      | 0,57 s       | neuspeshno |
| [Formatyi] Dopusk: chistota diff i svyaznostj kontroljnoj tochki                                        | 37,619 s     | neuspeshno |
| [Formatyi] Svyaznostj: tochnyij trailer soobsjheniya kontroljnoj tochki                                     | 37,417 s     | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 82,851 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Granica integracii i ostatok

Korenj prinimayet chetyire fajla `fum-bratislavskaya-proyekciya-pamyati`: kontrakt versii 2, Python-validator, fajl adresnyikh testov i SKILL.md, a takzhe tekusjhuyu papku Zhurnala. Navigaciya predyidusjhego zaprosa, indeks Zhurnala i indeks svezhesti soglasovanyi toljko v izolirovannoj vetke; pri integracii korenj peresobirayet ikh po svoyemu aktualjnomu derevu. Novyikh pravil i shirokikh isklyuchenij net.

Sokhraneno unasledovannoye pokoleniye iz bazyi `aeae18cb146a34563ff39c84d9bc5ef59fffab91`: khyesh fajla manifesta `cc02a0482eeddea16d44b9049b9f062dc9004f3c09f97b47c9b71c288b7dde98`, zapisannyij khyesh vkhodnogo inventarya `sha256:544a1e4a110118a3a9e8957b50a3c4a8330380136ef524186f0892861bf62ff2`, khyesh prezhnej politiki `sha256:9f262153c9de986270cec76ad3c37da34c99ace0c187474ba8a1bc736222220a`. Eto nablyudeniye sokhranyonnogo svideteljstva, a ne povtornaya nezavisimaya proverka pokoleniya. Ot novyikh kanonicheskikh fajlov ono otstayot; obnovleniye trebuyet shtatnogo primeneniya kornem posle integracii.

Dlya izvestnyikh istoricheskikh ssyilok vosstanovlen toljko otsutstvuyusjhij ignoriruyemyij graf (574 bajta), a uzhe zaregistrirovannyij LinguisticKit materializovan otdeljnyim polnyim klonom forka na prezhnem gitlink s origin i upstream. Eti lokaljnyiye vkhodyi ne vklyuchayutsya v diff; soderzhaniye zavisimosti, reviziya i obsjhaya Git-konfiguraciya FUM sokhranenyi.

Kontroljnaya tochka sokhranyayet otkryityij terminaljnyij zhurnal bez finaljnogo snimka. Daljnejshiye obyazannosti kornya: nezavisimoye chteniye diff, integraciya s adaptaciyej prilozheniya, obsjhiye indeksyi, standartnyij smoke-check, obnovleniye i nezavisimaya proverka proyekcii, finaljnaya priyomka postavki FUM-STEP-0176. Etot otchyot ne zakryivayet vsyu kornevuyu zadachu.

## Istochniki

- [Komandyi i granica tekusjhego etapa](zapros.md).
- [Pervonachaljnyiye komandyi perenosa](../2026-09-11_01-28-44_MSK_perenesti-iskhodniki-FUMA/zapros.md).
- [Opisaniye kontrakta proyekcii](../../Instrumentyi/fum-bratislavskaya-proyekciya-pamyati/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:22:16 MSK -->
<!-- content-sha256: sha256:94bc0b60b21da84ac60d7796fc99d34f539a896139696a73404365dcbff77dd2 -->
<!-- FUM-MD-RECENCY:END -->
