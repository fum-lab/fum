+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0035"
"статус" = "активна"
+++
# Propusk udalyonnogo puti proyekcii v zaprose

## Nablyudayemyij sboj

Pereimenovaniye kanonicheskoj kartochki privodit pri sleduyusjhej generacii k udaleniyu prezhnego proizvodnogo puti. Yesli zapros perechislyayet toljko susjhestvuyusjhij katalog Proyekcii, proverka svyaznosti otklonyayet eto neukazannoye udaleniye uzhe posle dorogoj generacii i yeyo nezavisimoj proverki.

## Granica povtoreniya

Podgotovka oblasti zaprosa ne uchityivayet ozhidayemyiye udaleniya starogo pokoleniya. Granica ne rasshiryayet ssyilku na katalog do proizvoljnyikh otsutstvuyusjhikh potomkov. Oshibka generatora i povrezhdeniye kanonicheskoj kartochki ne ustanovlenyi. Susjhestvuyusjhiye neperechislennyiye fajlyi otnosyatsya k inoj granice.

## Proyavleniya

| Nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| FUM-SBOJ-0035/PROYAVLENIYE-0001 | [Polnyij zapusk №10 a76dc5e1](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/materialyi/zapuski-proverok/10_a76dc5e1-8872-404e-b604-990af4a7de95.json) | Shag 11 otkazal posle primeneniya i proverki proyekcii; 377,427256542 s. | Sverenyi pokoleniya i yedinstvennoye udaleniye; v zapros dobavlen tochnyij marker. |
| FUM-SBOJ-0035/PROYAVLENIYE-0002 | [Polnyij zapusk №18 5c5b135b](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/материалы/запуски-проверок/18_5c5b135b-f0cb-44f4-a33e-7b8275025695.json) | Shag 11 otklonil udaleniye prezhnej proizvodnoj kartochki 0176. | Dobavlen shtatnyij tochnyij marker udalyonnogo fajla; adresnyij kontrolj i povtor polnogo dopuska prinyali dopolnennyij vkhod. |

## Ozhidaniye i klassifikaciya

Podtverzhdyonnoye ozhidayemoye udaleniye dolzhno byitj otrazheno v oblasti zaprosa do polnoj priyomki. Proverka svyaznosti dejstvuyet praviljno, obnaruzhena povtornaya nedorabotka podgotovki vkhoda. Novoye proyavleniye vozvrasjhayet kartochku v aktivnyij status.

## Mekhanizm i sistemnoye ustraneniye

V pervom sluchaye HEAD 7b692126b6b1c96e162554f71a96a6ef8857924a uzhe soderzhal novuyu kartochku 0154, a proyekciya sokhranyala prezhnij snimok. Otlozhennaya generaciya vyiyavila udaleniye pozdno. Ogranichennoye ruchnoye vosstanovleniye odnogo spiska ne predotvrasjhayet povtor. Nuzhen proveryayemyij predvariteljnyij vyivod tochnyikh ozhidayemyikh udalenij iz prezhnego i novogo pokolenij s zakryityim sopostavleniyem razdelu «Povliyal na fajlyi».

## Svyazannyiye shagi

- [FUM-STEP-0205](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0205-uchityivatj-udaleniya-proyekcii-do-polnoj-proverki.md). Osnovaniye aktualizacii — FUM-SBOJ-0035/PROYAVLENIYE-0002.

## Kriterii zakryitiya

Proveryayemaya podgotovka oblasti do polnogo dopuska vyiyavlyayet tochnoye ozhidayemoye udaleniye; soglasovannyij marker pokryivayet toljko podtverzhdyonnyij putj. Neobyyasnyonnyiye udaleniya i sosedniye imena ostayutsya zapresjhenyi. Svideteljstvo okhvatyivayet oba nablyudyonnyikh scenariya, a ne toljko uspeshnoye povtoreniye komandyi.

## Istoricheski ogranichennoye ustraneniye

[Diagnostika №11 a2cc8e4f](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/materialyi/zapuski-proverok/11_a2cc8e4f-e2dc-43b3-80e1-fc121f2aaffe.json) na pervom snimke vosproizvela yedinstvennyij otkaz i prinyala spisok s odnim tochnyim markerom v pamyati. Proveryayusjhij kod ne menyalsya. Otricateljnaya regressiya test_git_status_directory_scope_rejects_sibling_prefix_and_deleted_path sokhranyala zapret sosednikh i neukazannyikh udalenij. Prezhneye zakryitiye otnosilosj toljko k vosstanovleniyu dannogo spiska; novoye proyavleniye etu istoricheskuyu proverku ne stirayet.

## Istochniki

- [Pervonachaljnyij zapros](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/zapros.md).
- [Otchyot povtornogo proyavleniya](https://github.com/fum-lab/fum/blob/6599fe4837ef54efc7f871d2bfe6f8d9d07b4d95/Журнал/2026-09-11_02-51-49_MSK_проверить-поставку-FUMA-из-клона/отчёт.md).
- [Kontrakt svyaznosti](../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:43db6c4aa8bd3c038cc6af578666a330283e0fb88d30fd54a724b67b7eb86da9 -->
<!-- FUM-MD-RECENCY:END -->
