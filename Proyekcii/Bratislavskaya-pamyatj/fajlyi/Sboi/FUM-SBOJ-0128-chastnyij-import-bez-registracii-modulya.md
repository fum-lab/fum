+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0128"
"статус" = "активна"
+++
# Chastnyij import ne zaregistriroval modulj do dataclass

## Nablyudayemyij sboj

Chastnaya podgotovka otchyota zagruzila shtatnyij modulj Markdown-recency cherez importlib bez predvariteljnoj zapisi v sys.modules. Dekorator dataclass ne nashyol modulj i ostanovil process do zapisi otchyota.

## Granica povtoreniya

Dinamicheskaya zagruzka Python-modulya s dataclass cherez module_from_spec i exec_module bez registracii sozdannogo obyyekta. Eto oshibka chastnogo vyizova, a ne shtatnogo formattera; Swift-testovyij import 0033 i nevernyij konvert 0127 imeyut drugiye granicyi.

## Proyavleniya

### FUM-SBOJ-0128/PROYAVLENIYE-0001

[Pervichnoye nablyudeniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-chastnogo-importa.json) sokhranyayet SHA i bajtovyiye granicyi iskhodnogo otveta: kod 1, AttributeError pri obrasjhenii k __dict__ otsutstvuyusjhego modulya. Dve predshestvuyusjhiye JSON-zapisi uzhe byili sokhranenyi; otchyot yesjhyo ne zapisyivalsya. Dliteljnostj processa ne izmerena.

## Ozhidaniye i klassifikaciya

Ispoljzovaniye shtatnogo formattera dolzhno soblyudatj kontrakt Python-zagruzki i davatj proveryayemyij rezuljtat. Nomer vyidelen obsjhim raspredelitelem po sobyitiyu `context-private-dataclass-import-01a0930d-after-0127`. Oshibka i vosstanovleniye ne pripisyivayutsya runtime FUM.

## Mekhanizm i sistemnoye ustraneniye

Chastnyij vyizov ispravlen: modulj zaregistrirovan v sys.modules do exec_module. Shtatnyij formatter uspeshno zagruzilsya; tablica i dopolneniye otchyota zapisanyi. Yego ispolnyayemaya realizaciya ne izmenyalasj. Dlya daljnejshego oformleniya vyibirayutsya shtatnyij CLI i uzhe proverennyiye shablonyi; obsjhaya mera predotvrasjheniya novogo oshibochnogo chastnogo importa yesjhyo ne dokazana.

## Svyazannyiye shagi

- [FUM-STEP-0174](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md) — proverennyij sposob primeneniya formattera; tochnoye osnovaniye FUM-SBOJ-0128/PROYAVLENIYE-0001.

## Kriterii zakryitiya

Vosproizvodimyij podderzhannyij sposob oformleniya otchyota ispoljzuyet shtatnyij CLI libo proverennyij shablon zagruzki s korrektnoj registraciyej modulya. Scenarij s dataclass ne trebuyet novogo chastnogo importa; rezuljtat sokhranyayet kanonicheskoye formatirovaniye. Razovaya korrekciya vyizova ne obyyavlyayetsya obsjhej profilaktikoj.

## Nablyudayemoye vosstanovleniye

[Nablyudeniye](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/materialyi/nablyudeniye-chastnogo-importa.json) svyazyivayet vyipolnennoye ispravleniye i SHA otchyota srazu posle uspeshnoj zapisi. Etot khyesh otnositsya k toj vremennoj granice; posleduyusjhiye dopolneniya, predprosmotr i recency imeyut svoi versii. Dve raneye sokhranyonnyiye JSON-zapisi ne poteryanyi. Oshibochnyij vyizov radi registracii ne povtoryalsya.

## Istochniki

- [Raspredeleniye nomera i komanda o sposobe primeneniya](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).
- [Otchyot](../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/otchyot.md).
- [Shtatnaya avtomatizaciya svezhesti Markdown](../Instrumentyi/fum-svezhestj-markdown/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:05:57 MSK -->
<!-- content-sha256: sha256:3c8a501a00b02f12441d2e35f1a3431179a0078df27da60a4440612694263f37 -->
<!-- FUM-MD-RECENCY:END -->
