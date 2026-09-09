# FUM-SBOJ-0035 — Propusk udalyonnogo puti proyekcii v zaprose

- Identifikator: `FUM-СБОЙ-0035`.
- Status: `устранена` v predelakh proveryayemogo vosstanovleniya tochnogo spiska udalyonnyikh fajlov.

## Nablyudayemaya problema

Pri priyomke integracii kanonicheskaya kartochka 0154 uzhe byila pereimenovana iz 🟡 v ✅. Staraya proyekciya ostavalasj v predyidusjhem kontroljnom kommite. Novaya generaciya korrektno sozdala ✅-putj i udalila 🟡-putj, no zapros perechislyal toljko susjhestvuyusjhij katalog Proyekcii. Proverka svyaznosti zakonomerno otkazala: ssyilka na katalog pokryivayet susjhestvuyusjhikh potomkov i ne razreshayet neukazannyiye udaleniya.

## Proyavleniya

| Nomer | Svideteljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0035/ПРОЯВЛЕНИЕ-0001` | [Polnyij zapusk a76dc5e1](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/materialyi/zapuski-proverok/10_a76dc5e1-8872-404e-b604-990af4a7de95.json) i [otchyot](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/otchyot.md) | Otkaz shaga 11 posle uspeshnyikh primeneniya i nezavisimoj proverki proyekcii; vneshnij zapusk 377,427256542 s. | Sveritj staryij i novyij manifestyi, podtverditj yedinstvennoye udaleniye i dobavitj tochnyij marker v zapros. |

## Mekhanizm i granica

Oshibka otnositsya k podgotovke spiska zatronutyikh fajlov. V HEAD `7b692126b6b1c96e162554f71a96a6ef8857924a` odnovremenno sokhranyalisj novaya kanonicheskaya kartochka i staraya proizvodnaya. Otlozhennaya do finaljnoj priyomki generaciya sdelala ozhidayemoye udaleniye vidimyim pozdneye. Oshibka generatora i povrezhdeniye kartochki ne ustanovlenyi.

Granica vosstanovleniya — yavno nazvannoye otsutstvuyusjheye proizvodnoye imya posle podtverzhdyonnogo pereimenovaniya. Obsjhaya ssyilka na katalog ne rasshiryayetsya do lyubyikh otsutstvuyusjhikh potomkov; perenos etoj meryi na sosedniye udaleniya ne dopuskayetsya.

## Proveryayemaya mera

Pered polnoj priyomkoj sleduyet sopostavitj ozhidayemyiye udaleniya starogo pokoleniya s razdelom «Povliyal na fajlyi». Dlya kazhdogo podtverzhdyonnogo otdeljnogo udaleniya ispoljzuyetsya uzhe susjhestvuyusjhij marker «Udalyonnyij fajl» s tochnyim repozitornyim putyom. Nepodtverzhdyonnoye udaleniye ostayotsya prichinoj otkaza.

[Diagnostika a2cc8e4f](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/materialyi/zapuski-proverok/11_a2cc8e4f-e2dc-43b3-80e1-fc121f2aaffe.json) na iskhodnom snimke vosproizvela yedinstvennyij otkaz, sverila yedinstvennoye fakticheskoye udaleniye i proverila iskhodnyij spisok s dobavleniyem odnogo tochnogo markera v pamyati. Zapros zatem obnovlyon tem zhe markerom. Proveryayusjhij kod ne menyalsya.

## Kriterij i predel zakryitiya

Propusjhennyij putj odnoznachno obyyasnyon staryim i novyim pokoleniyami; spisok s tochnyim markerom prokhodit proverku oblasti Git-sostoyaniya. Dejstvuyusjhaya otricateljnaya regressiya `test_git_status_directory_scope_rejects_sibling_prefix_and_deleted_path` sokhranyayet zapret sosednikh i neukazannyikh udalenij. Eto proverennoye ogranichennoye vosstanovleniye dannogo spiska, a ne zayavleniye o nevozmozhnosti budusjhej oshibki agenta ili ob uspeshnoj polnoj priyomke integracii.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-08_21-16-26_MSK_integrirovatj-paralleljnyiye-rezuljtatyi-i-opisatj-rabotu/zapros.md).
- [Dejstvuyusjhij kontrakt svyaznosti](../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 00:17:38 MSK -->
<!-- content-sha256: sha256:32f6cd3afb5fe62b85c6a35e0ba5f7c14d7b480b2c0787dffbc84f8baec3e723 -->
<!-- FUM-MD-RECENCY:END -->
