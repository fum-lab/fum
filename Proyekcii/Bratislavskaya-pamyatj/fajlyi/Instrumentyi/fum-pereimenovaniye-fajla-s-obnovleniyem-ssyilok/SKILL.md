---
name: fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok
description: Bezopasno pereimenovyivatj otslezhivayemyij fajl pamyati FUM vmeste s proveryayemyim obnovleniyem vkhodyasjhikh i iskhodyasjhikh Markdown-ssyilok.
---

# Pereimenovaniye fajla s obnovleniyem ssyilok

Kanonicheskoye russkoye imya etoj lokaljnoj [avtomatizacii FUM](../../Glossarij/avtomatizaciya-FUM.md) — `переименование файла с обновлением ссылок`. Odin zapusk perenosit odin otslezhivayemyij fajl vnutri tekusjhego checkout i soglasovanno obnovlyayet podderzhannyiye zhivyiye ssyilki, ne podmenyaya operaciyu prostoj zamenoj imeni fajla vo vsyom tekste.

## Komandyi

Snachala postroitj determinirovannyij plan bez izmenenij rabochego dereva, indeksa i istorii:

```bash
python3 Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py \
  plan \
  --source '<прежний-путь-от-корня>' \
  --destination '<новый-путь-от-корня>' \
  --repo-root .
```

Primenitj tot zhe kontrakt posle polnogo preflight:

```bash
python3 Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py \
  apply \
  --source '<прежний-путь-от-корня>' \
  --destination '<новый-путь-от-корня>' \
  --repo-root .
```

Oba puti zadayutsya kak otnositeljnyiye POSIX-puti ot tochnogo kornya Git-worktree. Istochnik dolzhen byitj otslezhivayemyim obyichnyim fajlom vnutri checkout i ne imetj staged- ili unstaged-izmenenij: chistota istochnika sokhranyayet tochnyij predshestvuyusjhij Git-index pri vozmozhnom otkate. Naznacheniye dolzhno byitj otsutstvuyusjhim bezopasnyim putyom s susjhestvuyusjhim realjnyim roditeljskim katalogom, bez simvolicheskikh ssyilok, vyikhoda iz repozitoriya, strukturno isklyuchyonnyikh katalogov i kollizii imeni. Avtomatizaciya rabotayet s fajlami, a ne s katalogami; uzhe izmenyonnyij istochnik snachala nuzhno vernutj v dokazuyemoye Git-sostoyaniye ili pereimenovatj do yego soderzhateljnoj pravki.

## Kontrakt ssyilok

Avtomatizaciya raspoznayot lokaljnyiye Markdown-ssyilki po razreshyonnoj celi, a ne po sovpadeniyu basename. Podderzhivayutsya:

- obyichnyiye inline-ssyilki i izobrazheniya, vklyuchaya dopustimyij perenos adresa na sleduyusjhuyu fizicheskuyu stroku;
- celi v uglovyikh skobkakh i neobyazateljnyiye zagolovki ssyilok;
- percent-encoded segmentyi puti s sokhraneniyem query i fragment;
- odno- i dvukhstrochnyiye opredeleniya reference-style-ssyilok i ikh ispoljzovaniya;
- vkhodyasjhiye ssyilki iz drugikh proyektnyikh Markdown-fajlov;
- iskhodyasjhiye ssyilki iz peremesjhayemogo Markdown-fajla, vklyuchaya ssyilki na sebya.

Pri perenose mezhdu katalogami kazhdaya podderzhannaya lokaljnaya celj zanovo vyichislyayetsya otnositeljno itogovogo raspolozheniya soderzhasjhego yeyo fajla. Vneshniye URL, chistyiye fragment-ssyilki, pokhozhij basename, obyichnaya proza, nesvyazannyiye puti, inline-code, otstupnyiye bloki koda i fenced-bloki, v tom chisle vnutri Markdown-kontejnerov, ne izmenyayutsya. Yesli sintaksis, kodirovka, registr ili polnota ssyilok ne pozvolyayut dokazatj odnoznachnoye preobrazovaniye, komanda ostanavlivayetsya do zapisi; neraspoznannaya wiki-ssyilka na perenosimyij fajl ne propuskayetsya molcha, no yavnaya wiki-ssyilka na drugoj putj s tem zhe basename ne sozdayot lozhnogo zapreta.

## Zasjhisjhyonnyiye zonyi

Syiryiye materialyi v `Источники/` i doslovnyij razdel `## Текст запроса` tochnyikh fajlov `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md` ne redaktiruyutsya. Yesli takaya zona soderzhit ssyilku na perenosimyij fajl, kotoruyu potrebovalosj byi izmenitj dlya sokhraneniya zhivoj svyaznosti, i `plan`, i `apply` zavershayutsya fail-closed s diagnostikoj zasjhisjhyonnoj celi.

Kartochki shagov v `Планирование/карточки-шагов/` ne pereimenovyivayutsya obsjhej komandoj. Dlya nikh obyazateljno ispoljzuyetsya `Инструменты/fum-reyestr-planirovaniya/scripts/rename-step-card.py`, potomu chto domennaya operaciya dopolniteljno sinkhroniziruyet status, polnyij indeks i vetochnyij rabochij nabor. Drugoj domennyij format takzhe dolzhen poluchitj otdeljnyij yavnyij adapter, yesli prostogo perenosa fajla i Markdown-ssyilok nedostatochno dlya sokhraneniya yego invariantov.

## Plan, primeneniye i otkat

Rezhim `plan` vyipolnyayet tot zhe read-only preflight, chto i `apply`, i vozvrasjhayet ustojchivyij JSON-otchyot. Polya `source`, `destination` i `renamed_file` opisyivayut perenos, `rewritten_files` perechislyayet fajlyi s izmenyonnyimi bajtami, `updated_files` — vse itogovyiye puti zatronutyikh fajlov, a `updated_links` — chislo realjno izmenyonnyikh adresov. Preflight proveryayet Git-identichnostj i chistotu istochnika, bezopasnostj naznacheniya, otsutstviye kollizii, razbor vsekh podderzhannyikh vkhodyasjhikh i iskhodyasjhikh ssyilok, otsutstviye slomannyikh iskhodyasjhikh celej i konfliktov v zasjhisjhyonnyikh ili domennyikh zonakh. Read-only Git-vyizovyi otklyuchayut optional locks, vse puti peredayutsya kak bukvaljnyiye pathspec, a unasledovannyiye `GIT_*` ne mogut perenapravitj repozitorij, rabocheye derevo ili indeks.

Rezhim `apply` povtorno stroit plan na tekusjhikh bajtakh, gotovit novyiye versii zatronutyikh fajlov i rezervnyiye kopii do pervoj ustanovki, vyipolnyayet perenos cherez `git mv` i ustanavlivayet podgotovlennyiye versii atomarnoj zamenoj. Pered podgotovkoj i neposredstvenno pered perenosom povtoryayutsya lstat-, symlink-, portable-name-, Markdown-inventory-, HEAD- i exact-index-fences; perevodyi strok i fajlovyij rezhim sokhranyayutsya. Pri perekhvatyivayemoj oshibke processa posle nachala primeneniya avtomatizaciya pyitayetsya vernutj prezhniye puti, bajtyi, rezhimyi i iskhodnoye Git-sostoyaniye, a zatem otdeljno sveryayet vosstanovlennyiye bajtyi, rezhimyi, `HEAD`, indeks, status i Markdown-inventarj. Uspeshnyij otkat podtverzhdayetsya testom, vklyuchaya zaraneye susjhestvovavshiye staged- i unstaged-izmeneniya nesvyazannyikh fajlov. Sboj pitaniya, prinuditeljnoye zaversheniye processa, oshibka ochistki ili samogo otkata ne vyidayutsya za atomarnyij uspekh: sokhranyonnaya rezervnaya kopiya i tochnaya diagnostika trebuyut ruchnogo vosstanovleniya.

Obyazateljnyij path-based-vyizov `git mv` ostavlyayet korotkoye neustranimoye okno dlya vrazhdebnoj odnovremennoj podmenyi kataloga mezhdu poslednim lstat-fence i sistemnyim obrasjheniyem Git. Kontrakt rasschitan na sotrudnichayusjhiye processyi odnogo checkout: lyuboye nablyudayemoye izmeneniye zakryivayetsya povtornyimi snimkami, no avtomatizaciya ne yavlyayetsya zasjhitoj ot processa, kotoryij namerenno vyiigryivayet sistemnuyu gonku imyon fajlov.

## Avtonomnyiye testyi

Testyi zapuskayutsya lokaljno bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/tests \
  -p 'test_*.py'
```

Fiksturyi sozdayut vremennyiye Git-repozitorii i proveryayut read-only-plan, uspeshnoye primeneniye, podderzhannyiye formyi Markdown-ssyilok, pereschyot vkhodyasjhikh i iskhodyasjhikh celej, tochnostj sovpadeniya, zasjhisjhyonnyiye i domennyiye granicyi, nebezopasnyiye puti, kollizii, nerazreshimyiye ssyilki, sokhraneniye CRLF i ispolnyayemogo rezhima, a takzhe polnyij otkat pri vnedryonnoj oshibke ustanovki.

## Granica avtomatizacii

Avtomatizaciya ne prinimayet smyislovoye resheniye o novom imeni, ne menyayet soderzhaniye prozyi, ne pereimenovyivayet katalogi i ne ispravlyayet zaraneye slomannyiye ssyilki. Ona obespechivayet proveryayemuyu fajlovuyu operaciyu toljko dlya obyyavlennogo nabora Markdown-form; neizvestnyij znachimyij format trebuyet yavnogo rasshireniya kontrakta i testov do primeneniya.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-24 16:26:31 MSK — Sozdatj obobsjhyonnyij instrument pereimenovaniya fajla](../../Zhurnal/2026-07-24_16-26-31_MSK_sozdatj-obobsjhyonnyij-instrument-pereimenovaniya-fajla/zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:42b1af06c532a56f0b816090b653c44b45912259e5b5d5b6870ed327093f2548 -->
<!-- FUM-MD-RECENCY:END -->
