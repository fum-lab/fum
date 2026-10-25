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

## Politika zakreplyonnogo kandidata

`policy-кандидата-слияния.json` prednaznachena dlya proverki dannyikh zakreplyonnoj vedusjhej osnovyi. Ona otdeljno svyazana v `происхождение-политики-слияния.json` s polnyimi OID osnovyi, yeyo dereva i SHA-256 politiki. Tekusjhaya osnova — `14044dfd994cf16b5061fb245b18a8e5abf0ac7d`, derevo `d9af1d9e69f288c602a78e5e3edab5337b41ef58`; 447 isklyuchenij sostavlyayut prezhniye 419 i 28 tochnyikh dobavlenij otnositeljno prinyatogo master `9d01af6de4fc2f1c9265ee8805cda4998322e004`. Eto vkhod susjhestvuyusjhego kontura sliyaniya, a ne samostoyateljnoye razresheniye sliyaniya. Obyichnaya komanda vyishe prodolzhayet ispoljzovatj `policy.json`, pokryivayusjhuyu toljko realjno prinyatyiye fajlyi; pri perenose novyikh fajlov yeyo izmeneniya sveryayutsya otdeljno.

V prinyatoj predposyilke M obyichnaya politika sokhranyala 419 iskhodnyikh zapisej i dobavlyala toljko tri tochnyikh isklyucheniya perenesyonnogo CJS-raspoznavatelya i yego otkryitoj regex-fiksturyi, vsego 422. Eti tri zapisi uzhe prisutstvovali v tochnom obyyekte L. V podgotovlennom sliyanii obyichnaya policy.json sokhranyayetsya iz L celikom: 447 zapisej, pobajtno ravnyikh zakreplyonnoj v M politike kandidata. Eto izmeneniye dannyikh kandidata; prinimayusjhaya politika i yeyo proiskhozhdeniye v M ostayutsya neizmennyimi.

[Tekusjheye zakrepleniye novoj osnovyi](../../Zhurnal/2026-09-16_02-10-09_MSK_podgotovitj-predposyilku-formatov-proyekcii/zapros.md).

[Pervonachaljnoye osnovaniye i adresnaya sverka prezhnej osnovyi](../../Zhurnal/2026-09-11_14-47-00_MSK_podgotovitj-sovmestimostj-master-i-FUMA/zapros.md).

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

Neskoljko deklaracij odnogo fajla ispoljzuyut odin polnyij analiz etogo fajla v predelakh vyizova. Sokhranyayutsya chislo strok i neizmennyiye kandidatyi; kontekst i chislo odinakovyikh fingerprint po vsemu fajlu proveryayutsya polnostjyu. Sleduyusjhij vyizov zanovo chitayet i razbirayet vkhod, poetomu izmeneniye fajla ne skryivayetsya prezhnim kyeshem. Otdeljnyij itogovyij scanner po-prezhnemu proveryayet vesj repozitorij.

Dlya sravneniya stoimosti ispoljzujte `tests/профиль_пакетного_анализа.py --выход <профиль.json>` cherez otchyotnuyu obyortku. Po umolchaniyu on sozdayot tri otkryityiye fiksturyi primerno po 4 MiB s 12 deklaraciyami, izmeryayet obnovleniye i tochnyij povtor, sokhranyayet khyeshi vkhoda i rezuljtata, schyotchik i vlozhennyiye intervalyi nastoyasjhego polnogo razbora. Podgotovka vremennogo Git-repozitoriya isklyuchena iz izmeryayemogo obnovleniya. Do i posle serii sveryayutsya SHA-256 izmeryayemyikh iskhodnikov, profilirovsjhika i ispoljzuyemyikh modulej fiksturyi; izmenivshijsya ili ischeznuvshij istochnik ne dopuskayet zapisj rezuljtata. Parametryi `--мегабайт`, `--деклараций` i `--повторов` zadayut razmer scenariya. Dlya istoricheskoj realizacii peremennaya `FUM_CHECKED_CODE_ROOT` ukazyivayet na otdeljnyij proverennyij checkout togo zhe monorepozitoriya; profilirovsjhik zapuskayetsya iz tekusjhego dereva. Istoricheskaya kopiya dolzhna soderzhatj zavisimosti skanera, vklyuchaya modulj strukturyi papok zaprosov. Ravenstvo rezuljtatov, sostav vkhodov i usloviya nagruzki sveryayutsya otdeljno; vlozhennyiye intervalyi ne summiruyutsya s obsjhim vremenem.

## Tipizirovannaya granica

Doslovnoye soderzhimoye toljko razdela `## Текст запроса` v tochnyikh fajlakh `Журнал/<имя-с-обязательным-временным-префиксом>/запрос.md` i fajlyi pod `Источники/` ostayutsya proiskhozhdeniyem v rezhime `report.*`. Obyichnyiye URL maskiruyutsya do raspoznavaniya lokaljnyikh putej. Sistemnyiye runtime-puti, shebang, yakorya `.gitignore` i dokumentirovannyiye obezlichennyiye primeryi poluchayut otdeljnyiye kontekstnyiye kategorii; proizvoljnyij sistemnyij putj v first-party-kode ne razreshayetsya. Samo nakhozhdeniye stroki v kataloge skanera, v fajle drugoj proverki ili v `tests` nichego ne razreshayet.

Gitlink vyivoditsya kak granica `report.gitlink`: skaner ne vkhodit v vendored istoriyu. Poetomu izvestnoye upstream-ispoljzovaniye `#filePath` v `LinguisticKitBuildTool` fiksiruyetsya kak ogranicheniye zavisimosti, a first-party Swift-fajl s `#filePath` ostanavlivayet proverku.

Binarnoye vlozheniye s NUL-bajtom v tochnoj oblasti `Журнал/<канонический-временной-префикс>/материалы/источники/<описательное-название>/<файл>` poluchayet `report.external-source.binary`, kak syiroj istochnik verkhnego urovnya, toljko pri susjhestvuyusjhem obyichnom `запрос.md` etoj sessii v Git-inventare. Eto ne rasprostranyayetsya na tekstovyiye i non-UTF-8 fajlyi bez NUL, proizvodnyiye opisaniya, blizkiye imena katalogov i beskhoznyiye libo nekanonicheskiye papki zaprosov. Otsutstviye analiza soderzhimogo binarnogo istochnika ne zamenyayet ruchnuyu publikacionnuyu proverku i yego tochnoye proiskhozhdeniye.

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
<!-- last-content-edit: 2026-09-16 15:53:10 MSK -->
<!-- content-sha256: sha256:764ee974b2c1e8270236c3631473e5e55d94bec7651279287f163bdb2e341c96 -->
<!-- FUM-MD-RECENCY:END -->
