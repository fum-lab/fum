---
name: fum-bratislavskaya-proyekciya-pamyati
description: Stroitj, atomarno ustanavlivatj i nezavisimo proveryatj determinirovannuyu bratislavskuyu proyekciyu kanonicheskoj pamyati FUM.
---

# Bratislavskaya proyekciya pamyati

Avtomatizaciya zakreplyayet mashinnuyu granicu mezhdu kanonicheskoj kirillicheskoj pamyatjyu FUM i yeyo proizvodnoj bratislavskoj proyekciyej. Ona proveryayet versionirovannyij kontrakt, stroit sukhoj plan, polnostjyu peresobirayet i atomarno ustanavlivayet pokoleniye, a zatem nezavisimo vyivodit ozhidayemyiye bajtyi iz kanonicheskogo sloya i proveryayet manifest s celevyim derevom.

Kanonicheskim istochnikom ostayotsya korenj tekusjhego Git-checkout. Plan obyyedinyayet otslezhivayemyiye puti s novyimi neignoriruyemyimi putyami rabochego dereva, fiksiruyet tochnyiye bajtyi, rezhimyi i sostoyaniye Git i isklyuchayet proizvodnoye prostranstvo iz obratnogo obkhoda. Ignoriruyemoye lokaljnoye sostoyaniye, sborochnyiye rezuljtatyi i fizicheskiye worktree-poduzlyi ne stanovyatsya pamyatjyu toljko iz-za prisutstviya na fajlovoj sisteme.

## Versionirovannyij kontrakt

Kanonicheskaya politika versii 2 khranitsya v fajle kontrakt-v2.json. Ona fiksiruyet:

- iskhodnuyu oblastj .;
- proizvodnoye prostranstvo Proyekcii;
- celevuyu oblastj Proyekcii/Bratislavskaya-pamyatj;
- korenj otobrazhyonnyikh fajlov Proyekcii/Bratislavskaya-pamyatj/fajlyi;
- manifest Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json;
- yedinstvennyij dopustimyij isklyuchyonnyij gitlink Zavisimosti/LinguisticKit na OID 837e2ce107b97ee7b9d3344c9fe99142281fe393;
- LinguisticKit-preobrazovaniye Cyrl → Latn po tablice ru metodom applyingTransform;
- tochnyiye formatnyiye politiki, strukturnyiye isklyucheniya, perenosimyiye ogranicheniya putej i spisok sokhranyayemyikh tekhnicheskikh rasshirenij.

Skhemyi plana i manifesta nakhodyatsya v skhemyi/skhema-plana-v2.json i skhemyi/skhema-manifesta-v2.json. Versiya 2 yavlyayetsya yavnoj migraciyej ot opublikovannoj versii 1: ona dobavlyayet politiku ssyilok na isklyuchyonnyiye kanonicheskiye celi, tochnoye isklyucheniye lokaljnogo `.obsidian/graph.json` i tochnyij format `ЛИЦЕНЗИЯ`. Fajlyi `контракт-v1.json`, `схемы/схема-плана-v1.json` i `схемы/схема-манифеста-v1.json` sokhranyayutsya pobajtovo neizmennyimi i ne pereinterpretiruyutsya novoj avtomatizaciyej. Kanonicheskij JSON serializuyetsya v UTF-8 s otsortirovannyimi klyuchami, bez neobyazateljnyikh probelov i s odnoj zavershayusjhej novoj strokoj. Poryadok massivov putej opredelyayetsya sravneniyem ikh UTF-8-bajtov.

## Iskhodnyij inventarj

Inventarj stroitsya otdeljnyimi Git-nablyudeniyami otslezhivayemyikh i novyikh neignoriruyemyikh putej. Dlya kazhdogo obyyekta plan sokhranyayet iskhodnyij putj, tip, fakticheskij i indeksnyij rezhimyi, sostoyaniye repozitoriya, identifikator indeksnogo obyyekta, razmer i SHA-256 tekusjhikh bajtov libo tochnuyu prichinu isklyucheniya. Polnyij inventarj i tekusjhaya granica `HEAD` s indeksom i naborom putej snimayutsya povtorno posle postroyeniya; razorvannyij snimok zakryivayet sukhoj plan.

V sokhranyayemom `исходном_снимке` `HEAD` i sostoyaniye indeksa ne ispoljzuyutsya kak dolgovechnaya identichnostj vkhoda: OID kommita, kotoryij odnovremenno fiksiruyet izmenyonnyij kanonicheskij sloj i yego proyekciyu, neizvesten do generacii manifesta. Identichnostj zadayut khyesh kanonicheskogo inventarya i khyesh politiki; inventarnyij khyesh okhvatyivayet putj, tip, fakticheskij rezhim, razmer i khyesh bajtov. Polnyij plan po-prezhnemu pokazyivayet nablyudyonnyiye status, rezhim i OID indeksa, a dvojnaya granica sveryayet ikh vo vremya odnogo zapuska, no eti nablyudateljnyiye polya ne vkhodyat v smyislovoj khyesh plana. Poetomu fiksaciya tochno tekh zhe bajtov kak toljko proizvodnogo, tak i kanonicheskogo sloya ne delayet manifest ustarevshim, a lyuboye izmeneniye puti, rezhima ili bajtov po-prezhnemu trebuyet novoj polnoj peresborki.

Versiya 2 prinimayet toljko obyichnyiye fajlyi rezhimov 100644 i 100755. Simvolicheskaya ssyilka, specialjnyij fajlovyij obyyekt, konfliktnaya stadiya kanonicheskogo indeksa, otsutstvuyusjhij otslezhivayemyij fajl i lyuboj gitlink krome exact LinguisticKit zakryivayut plan. Konfliktnaya stadiya toljko pod `Proyekcii/**` mozhet byitj zamenena komandoj `применить` posle razresheniya kanonicheskogo sloya, no zakryivayet itogovyij nezavisimyij validator. Pustyiye katalogi ne yavlyayutsya Git-obyyektami i ne vkhodyat v inventarj.

Putj Zavisimosti/LinguisticKit ostayotsya nablyudayemyim isklyuchyonnyim gitlink i odnovremenno obespechivayet ispolnyayemyij preobrazovatelj. Shirokoye isklyucheniye vsego kataloga Zavisimosti zapresjheno.

## Granica celi

Obyichnaya komanda `план` otdelyayet tochnuyu proizvodnuyu oblastj ot kanonicheskogo inventarya i prinimayet yeyo toljko kak otsutstvuyusjheye libo dejstviteljnoye upravlyayemoye pokoleniye. Tak prezhnij chastichnyij ili vruchnuyu sozdannyij rezuljtat ne mozhet molcha statj vkhodom novogo pokoleniya. Komanda `применить` dopolniteljno umeyet zamenitj ogranichennyij Git-konflikt samoj proyekcii posle razresheniya kanonicheskogo sloya; neizvestnyij fajl, simvolicheskaya ssyilka ili nepodtverzhdyonnoye derevo zakryivayut dejstviye, a nezavisimyij validator otklonyayet ostatochnuyu konfliktnuyu stadiyu.

Proverka manifesta dopuskayet susjhestvuyusjhuyu celj toljko kak upravlyayemoye pokoleniye. Polnyij nabor celi obyazan sostoyatj rovno iz:

- fajla manifest-proiskhozhdeniya-v2.json;
- putej pod fajlyi/, perechislennyikh manifestom.

Otsutstvuyusjhij rezuljtat, lishnij fajl, inoj rezhim, nesovpavshij khyesh, simvolicheskaya ssyilka, specialjnyij obyyekt ili izmenivshijsya posle predvariteljnoj proverki istochnik zakryivayut proverku. Celevoye derevo chitayetsya pokomponentno ot deskriptora kornya bez perekhoda po simvolicheskim ssyilkam i snimayetsya povtorno pered uspekhom. Manifest vkhodit v upravlyayemyij nabor, no ne soderzhit sobstvennogo rekursivnogo khyesha.

Khyesh strukturnogo rezuljtata ne samozaveryayetsya manifestom: validator nezavisimo povtoryayet preobrazovaniye putej i soderzhimogo, vyivodit polnyij ozhidayemyij nabor bajtov iz kanonicheskogo sloya i sravnivayet yego s zapisjyu manifesta i fakticheskoj celjyu. Dlya dejstviya `сохранить_байты` ozhidayemyij khyesh vyivoditsya neposredstvenno iz istochnika. Soglasovannaya ruchnaya podmena celevogo fajla i redaktiruyemogo manifesta poetomu ne prokhodit proverku. Validator takzhe otklonyayet ostatochnyiye konfliktnyiye stadii Git pod `Proyekcii/**`.

## Politiki soderzhimogo

Obyichnyij Markdown poluchayet dejstviye preobrazovatj_strukturno: lokaljnyiye ssyilki perenapravlyayutsya v to zhe pokoleniye, yakorya preobrazuyutsya i proveryayutsya, URI lyuboj raspoznannoj skhemyi sokhranyayutsya, a FUM-MD-RECENCY pereschityivayetsya determinirovanno. Sovpadeniye iskhodnogo teksta s zarezervirovannyim vnutrennim markerom zakryivayet preobrazovaniye do globaljnoj zamenyi.

V Zhurnal/*/zapros.md doslovno sokhranyayetsya toljko soderzhimoye zasjhisjhyonnogo razdela ## Tekst zaprosa; ostaljnaya Markdown-obolochka otnositsya k strukturnomu preobrazovaniyu. Fajlyi Istochniki/**, sobstvennyij kod, mashinnyiye dannyiye, zaregistrirovannyiye tochnyiye formatyi, dvoichnyiye i ne-UTF-8 dannyiye sokhranyayut tochnyiye bajtyi po yavnoj politike versii 2. Putj .obsidian/fum-recency-reference-date yavlyayetsya otdeljno zaregistrirovannyim extensionless-mashinnyim fajlom, a kornevoj `ЛИЦЕНЗИЯ` — tochnyim spravochnyim yuridicheskim tekstom bez rasshireniya.

Neizvestnyij tekstovyij format zakryivayet plan. Latinskoye rasshireniye iz zakreplyonnogo spiska sokhranyayetsya otdeljno ot preobrazuyemoj osnovyi imeni. Suffiks .md.shablon ne obyyavlyayetsya tekhnicheskim latinskim rasshireniyem: yego kirillicheskaya chastj ostayotsya chastjyu preobrazuyemogo imeni puti, a soderzhimoye sokhranyayetsya kak mashinnyij shablon.

## Preobrazovaniye putej

Kazhdyij komponent polnogo puti obrabatyivayetsya otdeljno. Dlya poslednego komponenta snachala otdelyayetsya samoye dlinnoye zaregistrirovannoye tekhnicheskoye rasshireniye, zatem LinguisticKit preobrazuyet osnovu. Neizmenivshiyesya latinskiye komponentyi vsyo ravno vkhodyat v otobrazheniye.

Do vyidachi plana proveryayutsya:

- exact-, NFC- i NFC+casefold-kollizii;
- fajlovo-katalozhnaya i prefiksnaya kolliziya;
- NFC-forma kazhdogo rezuljtata;
- zapresjhyonnyiye Windows-znaki i zarezervirovannyiye imena;
- konechnaya tochka ili probel;
- predel UTF-8-bajtov komponenta i polnogo puti;
- predel UTF-16-yedinic komponenta.

Avtomaticheskij chislovoj suffiks ne ispoljzuyetsya.

## Vyizov LinguisticKit

Shtatnyij process povtorno ispoljzuyet ispolnyayemuyu celj `preobrazovatj-nazvaniya` iz Instrumentyi/fum-proverka-nazvanij-avtomatizacij. Ona prinimayet JSON-massiv strok cherez standartnyij vvod i vozvrasjhayet massiv toj zhe dlinyi cherez standartnyij vyivod. Paket podklyuchayet materializovannyij Zavisimosti/LinguisticKit lokaljnoj SwiftPM-zavisimostjyu.

Pered zhivyim ispoljzovaniyem Git-topologiya i tochnyij identifikator zavisimosti proveryayutsya otdeljnoj avtomatizaciyej fum-proverka-git-zavisimostej. Materializaciya dopolniteljno sveryayetsya s zakreplyonnyim derevom po polnomu naboru obyichnyikh fajlov, rezhimam i bajtam obyyektov. Otslezhivayemyiye zakreplyonnyim derevom fajlyi v `.swiftpm` otnosyatsya k tochnoj zavisimosti, a lyuboj lishnij fajl v `.build`, `.swiftpm` ili inom meste zakryivayet zapusk. Sam SwiftPM-process ne chitayet etot izmenyayemyij checkout: avtomatizaciya razvorachivayet vo vremennom kataloge Git-arkhiv obyortki iz tochnoj vershinyi osnovnogo repozitoriya i otdeljnyij Git-arkhiv LinguisticKit iz zakreplyonnoj revizii, napravlyayet sborochnoye sostoyaniye v otdeljnyij vremennyij korenj i do i posle vyizova povtorno proveryayet izolirovannoye derevo. Poetomu ignoriruyemyij novyij iskhodnik, skryitoye indeksnyim flagom izmeneniye i tranzitnaya podmena fajla rabochej materializacii ne mogut popastj v sborku pod imenem zakreplyonnoj revizii. Avtonomnyiye testyi etogo instrumenta inyyeciruyut vyizyivayemoye preobrazovaniye putej na vnutrennej granice Python i ne trebuyut seti ili materializovannoj zavisimosti.

## Komandyi

Sam kontrakt proveryayetsya bez zapuska LinguisticKit:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py проверить-контракт \
  --корень-репозитория . \
  --контракт Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json
~~~

Sukhoj plan vyivoditsya v stdout i nichego ne zapisyivayet:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py план \
  --корень-репозитория . \
  --контракт Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json
~~~

Polnoye pokoleniye sobirayetsya, proveryayetsya i ustanavlivayetsya komandoj `применить`; putj celi vyivoditsya toljko iz kontrakta:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py применить \
  --корень-репозитория . \
  --контракт Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json
~~~

Gotovoye pokoleniye i yego manifest nezavisimo proveryayutsya bez otdeljnogo flaga celevogo kornya. Komanda ne prinimayet vneshnij obkhodnoj preobrazovatelj soderzhimogo i ne doveryayet khyeshu iz redaktiruyemogo manifesta.

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py проверить-манифест \
  --корень-репозитория . \
  --контракт Инструменты/fum-bratislavskaya-proyekciya-pamyati/контракт-v2.json \
  --манифест Proyekcii/Bratislavskaya-pamyatj/manifest-proiskhozhdeniya-v2.json
~~~

Avtonomnyiye testyi:

~~~text
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests \
  -p 'test_*.py'
~~~

## Realizovannaya granica FUM-STEP-0129

`применить` stroit novoye pokoleniye vo vremennom sluzhebnom kataloge vnutri `Proyekcii`, proveryayet yego do ustanovki i povtorno sveryayet iskhodnyij snimok. Nezavershyonnyij fajl snachala zapisyivayetsya v vyivedennoye iz tokena prostranstvo chastichnoj zapisi s rezhimom `0600`, sinkhroniziruyetsya, poluchayet okonchateljnyij rezhim, snova sinkhroniziruyetsya i toljko zatem atomarno pereimenovyivayetsya v polnyij vyikhod. Otdeljnoye vremennoye imya fazovogo zhurnala takzhe vyivoditsya iz tokena; poetomu vosstanovleniye mozhet otlichitj prinadlezhavshij prervannoj tranzakcii chastichnyij obyyekt ot neizvestnogo puti.

Do pervoj mutacii `Proyekcii` v Git-dir eksklyuzivno publikuyetsya kvitanciya s otdeljnyim tokenom i polnyimi ustojchivyimi snimkami prezhnego i novogo pokolenij. Toljko eta vneshnyaya kvitanciya dokazyivayet vladeniye sluzhebnyimi derevjyami; vnutrennij fazovyij zhurnal versii 2 razlichayet `строится`, `подготовлено`, `прежнее_зарезервировано`, `новое_установлено`, `принято` i `откачено`, no sam ne razreshayet perenos libo udaleniye. Do fazyi `принято` povtor vosstanavlivayet prezhneye podtverzhdyonnoye pokoleniye; posle prinyatiya idempotentno zavershayet ochistku. Publichnyiye komandyi `план` i `проверить-манифест` otklonyayut ostavshuyusya nezavershyonnuyu kvitanciyu, a `применить` snachala vyipolnyayet dokazuyemoye vosstanovleniye. Celj i rezerv atomarno pereimenovyivayutsya toljko v otsutstvuyusjheye naznacheniye; pri mezhkatalozhnom perenose snachala sinkhroniziruyetsya katalog naznacheniya, zatem katalog istochnika. Vosstanovleniye raspoznayot obrazovavshijsya pri avarii tochnyij dublikat pokoleniya, trebuyet raznyiye inode i svorachivayet toljko dokazannoye kvitanciyej podmnozhestvo. Tochnyij snimok konfliktnyikh stadij Git i `HEAD`, `MERGE_HEAD`, `AUTO_MERGE` povtorno proveryayetsya pered ustanovkoj i prinyatiyem. Lyuboj neizvestnyij putj, nesovpavshij rezhim ili bajt sokhranyayetsya i zakryivayet vosstanovleniye, a kvitanciya udalyayetsya poslednej. Sluzhebnyiye puti chitayutsya bez sledovaniya po simvolicheskim ssyilkam, rekursivnoye udaleniye nachinayetsya toljko posle polnogo predvariteljnogo obkhoda, celevyiye katalogi poluchayut vosproizvodimyij rezhim `0755`, a sluzhebnyij korenj — `0700` nezavisimo ot `umask`.

Modelj rasschitana na odnu dobrosovestnuyu pishusjhuyu sessiyu: Git-dir yavlyayetsya doverennyim lokaljnyim operacionnyim sostoyaniyem, a stabiljnostj kvitancii proveryayetsya pered kazhdoj kriticheskoj mutaciyej. Namerennaya poddelka kvitancii drugim processom togo zhe poljzovatelya ne vkhodit v modelj ugroz i bez otdeljnogo vneshnego kornya doveriya lokaljno neustranima. Zhyostkoye preryivaniye do atomarnoj publikacii kvitancii mozhet ostavitj yeyo tokenizirovannyij vremennyij fajl v Git-dir; bez opublikovannogo dokazateljstva vladeniya avtomatizaciya sokhranyayet takoj diagnosticheskij ostatok, a ne udalyayet yego po dogadke.

Kazhdyij zapusk zanovo vyivodit polnyij upravlyayemyij nabor. Poetomu ischeznuvshij ili pereimenovannyij kanonicheskij istochnik udalyayet prezhnij vyikhod toljko vmeste s polnoj zamenoj podtverzhdyonnogo pokoleniya; neizvestnyij fajl ne udalyayetsya i zakryivayet ustanovku. Povtor bez izmenenij bajtovo idempotenten.

Proizvodnuyu oblastj ne obyyedinyayut vruchnuyu. Posle Git-konflikta snachala razreshayut kanonicheskij sloj, zanovo zapuskayut `применить`, tochno stavyat vosstanovlennuyu `Proyekcii/**` v indeks komandoj `git add -f -A -- Proyekcii` i toljko zatem vyizyivayut nezavisimyij `проверить-манифест`: validator obyazan uvidetj tochnoye pokoleniye bez ostatochnyikh konfliktnyikh stadij. Standartnyij smoke-check nachinayetsya uzhe s beskonfliktnogo indeksa i vyipolnyayet obe komandyi posle kanonicheskikh pishusjhikh generatorov. Posle zakryitiya otchyota, gde konflikta takzhe net, dejstvuyet inoj tochnyij poryadok: odna finaljnaya peresborka, odin pryamoj nezavisimyij validator i lishj zatem postanovka pokoleniya v indeks.

Kanonicheskiye avtodiskaveri-konturyi isklyuchayut toljko kornevuyu oblastj `Proyekcii` i yeyo potomkov. Blizkiye imena, inoj registr i vlozhennyiye odnoimyonnyiye katalogi ostayutsya kanonicheskimi. Proyeciruyemyiye `AGENTS.md`, `SKILL.md` i lyubyiye drugiye fajlyi pod `Proyekcii/**` nikogda ne stanovyatsya instrukciyami, kornem proyekta ili rabochim katalogom agenta. Lokaljnaya ssyilka na isklyuchyonnuyu iz pokoleniya kanonicheskuyu celj sokhranyayetsya po yavno versionirovannoj politike `сохранить_ссылку_на_канонический_слой`.

## Istochniki trebovanij

- [FUM-STEP-0128 — kontrakt paralleljnoj bratislavskoj proyekcii](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0128-zakrepitj-kontrakt-paralleljnoj-bratislavskoj-proyekcii-pamyati.md)
- [Trebovaniye o paralleljnoj bratislavskoj proyekcii](../../Trebovaniya/✅-paralleljnaya-bratislavskaya-proyekciya-pamyati-FUM.md)
- [Bratislavskaya versiya pamyati FUM](../../Dokumentaciya/50-bratislavskaya-versiya-pamyati-FUM.md)
- [Podklyucheniye LinguisticKit](../../Zavisimosti/README.md)
- [iskhodnyij zapros realizacii FUM-STEP-0129](../../Zhurnal/2026-09-01_11-19-59_MSK_realizovatj-bratislavskuyu-proyekciyu-pamyati/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-01 17:52:20 MSK -->
<!-- content-sha256: sha256:59295586537787aec2b4813e6b1ed1f20d5ab122bd522c1bd09e3c4c1375c8a7 -->
<!-- FUM-MD-RECENCY:END -->
