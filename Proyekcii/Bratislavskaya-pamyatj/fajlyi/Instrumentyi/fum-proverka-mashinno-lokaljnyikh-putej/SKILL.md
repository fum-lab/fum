---
name: fum-proverka-mashinno-lokaljnyikh-putej
description: Proveryatj soderzhimoye repozitoriya FUM na mashinno-lokaljnyiye absolyutnyiye puti, domashniye sokrasjheniya, file URI i raskryitiye Swift #filePath.
---

# Proverka mashinno-lokaljnyikh putej

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) vyipolnyayet read-only-audit opublikovannogo soderzhimogo repozitoriya. Ona stroit inventarj cherez `git ls-files`, poetomu odinakovo vidit puti iz indeksa i novyiye neignoriruyemyiye fajlyi, no ne obkhodit Git submodule i ne zavisit ot seti ili sekretov. Rezuljtat determinirovanno sortiruyetsya i ne povtoryayet najdennyiye bukvaljnyiye znacheniya: kazhdaya stroka imeyet formu `путь:строка:категория`.

## Kogda ispoljzovatj

Ispoljzuj proverku pered fiksaciyej rabochej sessii, posle dobavleniya generatora Markdown, novogo iskhodnogo koda ili proverki putej, a takzhe pri izmenenii tipizirovannoj politiki dopustimyikh sluchayev. Obsjhij smoke-check zapuskayet yeyo otdeljnyim obyazateljnyim shagom.

## Komanda zapuska

Iz kornya repozitoriya:

```bash
python3 Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/proveritj-mashinno-lokaljnyiye-puti.py \
  --repo-root .
```

Kod `0` oznachayet otsutstviye dejstvuyusjhikh narushenij, dazhe yesli otchyot soderzhit tipizirovannyiye `allow.*` i `report.*`. Kod `1` oznachayet narusheniye soderzhimogo, a kod `2` — nedostovernyij Git-inventarj ili oshibku kontrakta politiki. Skaner otklonyayet proizvoljnyiye POSIX-absolyutyi, domashniye katalogi poljzovatelej, Windows drive, obratnosolyeshevyiye i pryamoslyeshevyiye UNC, `file://`, odinochnyij `~`, imennyiye formyi vrode `~user/path`, POSIX-, Windows- i PowerShell-peremennyiye domashnego kataloga i Swift `#filePath`.

## Tochnoye obnovleniye politiki

Povtoryayemyiye pereschyotyi fingerprint-polej vyipolnyayet `scripts/obnovitj-policy.py`. On ne razreshayet vse tekusjhiye oshibki: kazhdaya deklaraciya yavno zadayot `id`, tochnyij repozitornyij `path`, nomer `line`, zakryituyu `category` i soderzhateljnuyu `reason`. Vid formyi, SHA-256 vsej stroki i chislo sovpadenij instrument vyivodit iz tekusjhego Git-inventa i soderzhimogo fajla.

Kanonicheskij manifest imeyet skhemu `fum.machine-local-path-policy-update.v1` i massiv `declarations`:

```json
{
  "schema": "fum.machine-local-path-policy-update.v1",
  "declarations": [
    {
      "id": "fixture-example",
      "path": "Инструменты/example/tests/test_fixture.py",
      "line": 12,
      "category": "allow.test-fixture",
      "reason": "Закрепляет одну явно выбранную автономную тестовую строку."
    }
  ]
}
```

```bash
python3 Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/obnovitj-policy.py \
  --repo-root . \
  --manifest путь-к-манифесту.json
```

Dlya yedinichnogo zapuska tot zhe JSON-obyyekt mozhno peredatj povtoryayemyim argumentom `--declaration`. Povtornyij zapusk s temi zhe deklaraciyami ne perezapisyivayet fajl. Susjhestvuyusjhij `id` mozhno pereschitatj toljko pri neizmennyikh `path`, `category` i `reason`; eto pozvolyayet bez ruchnogo redaktirovaniya obnovitj vremennuyu poziciyu i fingerprint posle mekhanicheskogo perenosa.

Yesli oshibochnaya migraciya sozdala vtoroj `id` dlya togo zhe smyislovogo fence, manifest skhemyi `fum.machine-local-path-policy-update.v2` mozhet dobavitj massiv `retirements`. Kazhdyij element doslovno povtoryayet vse polya udalyayemoj policy-zapisi. Izmeneniye lyubogo polya zakryivayet operaciyu; uzhe otsutstvuyusjhij tochnyij `id` schitayetsya idempotentno zavershyonnyim retirement. Udaleniye i pereschyot ostavshegosya `id` prokhodyat odnoj atomarnoj zapisjyu.

Obnovleniye otklonyayet neodnoznachnuyu stroku, neaktivnuyu ili netipizirovannuyu stroku, vyikhod iz repozitoriya, wildcard, symlink, neizvestnuyu kategoriyu, dubliruyusjhijsya selektor ili fingerprint, nekanonicheskij JSON, ne-NFC-putj i smenu politiki vo vremya zapisi. Novaya politika snachala prokhodit obsjhij kontrakt, a zatem atomarno zamesjhayet prezhnij fajl.

## Tipizirovannaya granica

Doslovnoye soderzhimoye toljko razdela `## Текст запроса` v tochnyikh fajlakh `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md` i fajlyi pod `Источники/` ostayutsya proiskhozhdeniyem v rezhime `report.*`. Obyichnyiye URL maskiruyutsya do raspoznavaniya lokaljnyikh putej. Sistemnyiye runtime-puti, shebang, yakorya `.gitignore` i dokumentirovannyiye obezlichennyiye primeryi poluchayut otdeljnyiye kontekstnyiye kategorii; proizvoljnyij sistemnyij putj v first-party-kode ne razreshayetsya. Samo nakhozhdeniye stroki v kataloge skanera, v fajle drugoj proverki ili v `tests` nichego ne razreshayet.

Gitlink vyivoditsya kak granica `report.gitlink`: skaner ne vkhodit v vendored istoriyu. Poetomu izvestnoye upstream-ispoljzovaniye `#filePath` v `LinguisticKitBuildTool` fiksiruyetsya kak ogranicheniye zavisimosti, a first-party Swift-fajl s `#filePath` ostanavlivayet proverku.

Istoricheskiye dokazateljnyiye citatyi, opredeleniya raspoznavatelya i testovyiye fiksturyi vne strukturnyikh blokov proiskhozhdeniya dopuskayutsya toljko cherez [policy.json](policy.json). Kazhdaya zapisj skhemyi v2 zakreplyayet tochnyij otnositeljnyij putj, vid formyi, SHA-256 vsej stroki, ozhidayemoye chislo sovpadenij, odnu bazovuyu kategoriyu iz zakryitogo spiska `report.historical`, `allow.path-validation-definition` ili `allow.test-fixture` i soderzhateljnuyu prichinu. Poetomu fikstura ne pereimenovyivayetsya v istoricheskuyu citatu. Neispoljzuyemaya zapisj, izmenivshayasya stroka, neizvestnoye pole ili kategoriya, wildcard, vyikhod iz repozitoriya, dublikat ili chrezmernyij schyotchik delayut politiku oshibochnoj; novaya sosednyaya stroka ostayotsya narusheniyem.

V kanonicheskom zhurnale zapuskov skaner uzko raspoznayot metku ispolnitelya toljko v zakryityikh verkhnikh skhemakh `fum.test-run.v1`, `fum.test-run.v2` i `fum.test-run.v3`; v3 trebuyet dopolniteljnoye pole `профиль_проверки`. Otsutstvuyusjheye ili lishneye verkhneye pole ne dayot nekanonicheskoj zapisi ljgotu dlya mashinno-lokaljnoj metki ispolnitelya.

## Avtonomnyiye testyi

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/tests \
  -p 'test_*.py'
```

Testyi bez seti i sekretov proveryayut vse raspoznavayemyiye formyi, Git-inventarj, stabiljnostj i obezlichivaniye otchyota, strukturnyiye kategorii proiskhozhdeniya, uzkiye dopustimyiye sluchai, strogij fingerprint-kontrakt politiki i otkaz na iskusstvennoj first-party-regressii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)
- [kartochka shaga FUM-STEP-0070](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0070-ustranitj-mashinno-lokaljnyiye-absolyutnyiye-puti-i-dobavitj-ikh-avtomaticheskuyu-proverku.md)
- [audit absolyutnyikh putej](../../Zhurnal/2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/materialyi/revjyu/2026-07-22_12-35-05_MSK_audit-absolyutnyikh-putej.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-15 00:47:22 MSK -->
<!-- content-sha256: sha256:2211ba76b9d56945ca4b2ba3648dcdfca8ab9b7e74fa4f0b25ebd869676f3703 -->
<!-- FUM-MD-RECENCY:END -->
