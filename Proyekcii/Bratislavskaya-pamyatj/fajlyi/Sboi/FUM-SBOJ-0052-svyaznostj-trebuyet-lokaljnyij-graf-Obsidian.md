+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0052"
"статус" = "устранена"
+++
# Svyaznostj trebuyet lokaljnyij graf Obsidian

## Nablyudayemyij sboj

Proverki istoricheskikh Markdown-ssyilok trebuyut fizicheskij .obsidian/graph.json, khotya on yavlyayetsya neobyazateljnyim ignoriruyemyim sostoyaniyem poljzovatelya. Novoye derevo ne prokhodit primenimyij dokumentacionnyij dopusk bez importa libo sozdaniya chastnogo fajla. Prezhnyaya mera ustranila eto v proverke svyaznosti, no povtor vyiyavil drugoj potrebitelj ssyilok — proyekciyu.

## Granica povtoreniya

Odin obsjhij mekhanizm — obyazateljnoye susjhestvovaniye tochnoj ignoriruyemoj lokaljnoj celi. Svyaznostj i perepisyivatelj proyekcii dolzhnyi primenyatj odnu predmetnuyu granicu. Prochiye otsutstvuyusjhiye celi, nevernyij registr, simvolicheskiye obkhodyi i vyikhod za checkout isklyucheniya ne poluchayut. Prezhniye sboi opornoj datyi 0007 i gryaznogo dereva 0017 ne poglosjhayutsya.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0052/PROYAVLENIYE-0001 | [Otchyot 0176](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_01-28-44_MSK_перенести-исходники-FUMA/отчёт.md), pervaya proverka strukturyi, ssyilok i publikacionnoj chistotyi na baze 406c6ba1d0b3373403fefd14d5f7faf8e0665b7d | Novoye derevo otkazalo na istoricheskikh ssyilkakh. | Vosstanovlena toljko raneye otsutstvovavshaya lokaljnaya kopiya grafa; eto ne sistemnaya mera. |
| FUM-SBOJ-0052/PROYAVLENIYE-0002 | [Sokhranyonnoye podtverzhdeniye koordinatora](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Сбои/FUM-СБОЙ-0052-связность-требует-локальный-граф-Obsidian.md): posledovateljnaya zadacha 01a08d69-b088-7820-838e-dd4e97033753, 282 ssyilki, actual_case_path | Tot zhe otkaz vo vtorom novom dereve; syiroj vyivod etoj zadachi iskhodnoj kartochkoj ne vosproizvodilsya. | Lokaljnaya kopiya (574 bajta) vosstanovila sredu. Zatem dostavlen tochnyij dopusk svyaznosti 0203. |
| FUM-SBOJ-0052/PROYAVLENIYE-0003 | [Zapusk matematiki №5 a4ed8aa9](https://github.com/fum-lab/fum/blob/1a51647b7339aad3760ed09857063ccae791659a/Журнал/2026-09-11_05-09-33_MSK_составить-план-математического-направления/материалы/запуски-проверок/5_a4ed8aa9-f609-46a1-afb0-d8b4b5d6e724.json), [otchyot](https://github.com/fum-lab/fum/blob/1a51647b7339aad3760ed09857063ccae791659a/Журнал/2026-09-11_05-09-33_MSK_составить-план-математического-направления/отчёт.md) | Kod 2 posle 54,185051 s: shag 4 proyekcii otklonyayet istoricheskuyu ssyilku. Predmetnyij plan gotov, polnaya priyomka ne zavershena. | Sozdannyij ispolnitelem pustoj lokaljnyij obyyekt zatem udalyon posle sverki sobstvennyikh bajtov; zavisimyij povtor zhdyot ogranichennogo ispravleniya perepisyivatelya. |

Iskhodnyiye nomera 0001/0002 sokhranenyi; novoye nablyudeniye imeyet nomer 0003. Kolichestvo ssyilok ne schitayetsya kolichestvom proyavlenij.

## Ozhidaniye i klassifikaciya

Svezhij klon dolzhen prokhoditj primenimyij ssyilochnyij dopusk i formirovaniye proyekcii bez chastnogo poljzovateljskogo grafa. Povtor pokazyivayet nepolnoye pokryitiye potrebitelej obsjhej predmetnoj granicej. Prichina otsutstviya grafa shtatna, oshibka otnositsya k instrumentaljnomu ozhidaniyu obyazateljnogo fajla.

## Mekhanizm i sistemnoye ustraneniye

Prezhnij predikat otsutstvuyet_neobyazateljnyij_graf iz 28f51c58fa8df4d20d33ef2f05dab758cb7a6f83 uzhe prisutstvuyet v baze 8609003af7fdb6ef5dddf21c51cd6607ddb34088. Perepisyivatelj proyekcii otdeljno vyizyivayet ensure_outgoing_target, kotoryij trebuyet actual.exists(). Novaya dorabotka pereispoljzuyet prezhnij tochnyij predikat i proverku Git-ignore, sokhranyaya obyazateljnostj obyichnyikh celej. Dorabotka prinyata v 1aab4c016f726452861f42963b59b6ba66483437; yeyo tochnaya realizaciya, adresnyiye RED/GREEN i profilj dopolnenyi uspeshnyim dokumentacionnyim dopuskom matematicheskogo dereva.

## Svyazannyiye shagi

- [FUM-STEP-0203](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0203-otvyazatj-svyaznostj-ot-lokaljnogo-grafa-Obsidian.md): aktualizirovan po tochnomu osnovaniyu FUM-SBOJ-0052/PROYAVLENIYE-0003.

## Kriterii zakryitiya

Otsutstviye tochnogo ignoriruyemogo grafa ne prepyatstvuyet ssyilochnomu dopusku i primeneniyu s nezavisimoj proverkoj proyekcii. Susjhestvuyusjhij graf sokhranyayet bajtyi, identichnostj i vremya izmeneniya. Obyichnyiye bityiye ssyilki i nebezopasnyiye obkhodyi otklonyayutsya. Vosproizvodimoye svideteljstvo okhvatyivayet novyij putj otkaza; vremennyij pustoj fajl ne schitayetsya ustraneniyem.

## Istoricheski ogranichennoye ustraneniye

[Proverka 1598 Markdown-fajlov publichnogo chistogo klona](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/материалы/ссылки-чистого-клона.json) podtverzhdayet otsutstviye oshibok svyaznosti i grafa do i posle. Kommit vkhoda i proveryayusjhego koda ukazanyi razdeljno. Etot rezuljtat sokhranyayetsya; on ne proveryal perepisyivatelj otsutstvuyusjhej celi v proyekcii i ne zakryivayet proyavleniye 0003.

## Podtverzhdeniye ustraneniya

Prinyatyiye 7 adresnyikh scenariyev proveryayut otsutstviye grafa i samoj .obsidian, sokhraneniye susjhestvuyusjhikh bajtov/inode/mtime i strogiye otkazyi drugikh celej. Profilj 25 ssyilok dal medianu 31,2763916 ms dlya otsutstvuyusjhego grafa; prinyato resheniye sokhranyatj ogranichennuyu realizaciyu. Kod perepisyivatelya, predikat, testyi i profilj v matematicheskoj postavke pobajtno sovpadayut s prinyatyim kornem.

[Priyomka matematiki](https://github.com/fum-lab/fum/blob/b762bd0cb77fdbcc418141a1f33800a7bdb630a6/Журнал/2026-09-11_06-05-48_MSK_принять-план-математического-направления/отчёт.md) zavershila standartnyij dokumentacionnyij profilj: 13 naborov uspeshnyi; pryamoj zapusk f3d82b5e-8dea-45db-900d-79ecec5941f7 zanyal 841,984153042 s. [Zakryityij snimok](https://github.com/fum-lab/fum/blob/b762bd0cb77fdbcc418141a1f33800a7bdb630a6/Журнал/2026-09-11_06-05-48_MSK_принять-план-математического-направления/материалы/запуски-проверок/снимок.json) s SHA-256 91a0803eaa2af30e0a4302180afa831617b1ae7d1f2b28599953b16485dea1cc soderzhit te zhe 11 terminaljnyikh zapisej bez pozdnego khvosta; itogovyij otpechatok sovpadayet. Otsutstviye ignoriruyemogo grafa podtverzhdeno vladeljcem i otchyotom, ne vyivedeno iz Git. Primeneniye i nezavisimaya proverka proyekcii proshli bez vremennoj podmenyi grafa. Eto ogranichennoye zakryitiye 0052/0203; finaljnyij dopusk novogo soderzhimogo kornya vyipolnyayetsya otdeljno.

## Istochniki

- [Pervonachaljnaya kartochka](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Сбои/FUM-СБОЙ-0052-связность-требует-локальный-граф-Obsidian.md).
- [Tekusjheye prodolzheniye](../Zhurnal/2026-09-11_05-42-33_MSK_podgotovitj-sleduyusjhiye-napravleniya/zapros.md).
- [Pravilo lokaljnogo poljzovateljskogo sostoyaniya](../AGENTS.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:57:14 MSK -->
<!-- content-sha256: sha256:8f1238de7561c2d5604467fc2fe0cc69c740a188a11c1ef5a5a1ccf6b54ef8f1 -->
<!-- FUM-MD-RECENCY:END -->
