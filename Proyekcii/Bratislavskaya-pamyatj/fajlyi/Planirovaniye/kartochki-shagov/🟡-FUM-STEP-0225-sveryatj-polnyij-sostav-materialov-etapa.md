+++
schema_version = 1
card_id = "FUM-STEP-0225"
status = "active"
+++
# Sveryatj polnyij sostav materialov etapa

## Zadacha

Avtomatizirovatj podgotovku i adresnuyu sverku perechnya zatronutyikh materialov pered zaklyuchiteljnoj svyaznostjyu. Proveryayemyij vkhod vklyuchayet fakticheskij Git-perechenj svoyego dereva, zayavlennyiye rezuljtatyi etapa i tochnyij sostav prinyatogo dochernego perenosa; rezuljtat obyyasnyayet propuski konkretnyimi putyami i predlagayet toljko obosnovannoye dopolneniye razdela zaprosa.

## Pochemu sejchas

[Povtor FUM-SBOJ-0051](../../Sboi/FUM-SBOJ-0051-nepolnyij-perechenj-zatronutyikh-fajlov-zaprosa.md) snachala ostavil desyatj materialov bez dejstviteljnoj Markdown-ssyilki, zatem 29 dochernikh materialov i otchyotov bez pokryitiya: ssyilki na zaprosyi rebyonka sami po sebe ne vklyuchali yego katalogi. Terminaljnaya proverka praviljno ostanovila kommit, no podgotovka potrebovala povtornogo polnogo obkhoda. Obsjhaya avtomatizaciya dolzhna vyiyavlyatj etot konkretnyij propusk do zaklyuchiteljnogo dopuska.

## Kriterii zaversheniya

- Vkhod privyazan k svoyemu fizicheskomu derevu i tochnomu snimku Git; prinyatyij dochernij sostav zadayotsya proverennyim manifestom perenosa, a ne pereskazom rezuljtata rebyonka. Chuzhiye checkout i refs ne izmenyayutsya.
- Rezuljtat sopostavlyayet vse fakticheskiye puti s razreshyonnoj oblastjyu i razreshyonnyimi celyami Markdown-ssyilok. Razdel «Povliyal na fajlyi» ne rasshiryayetsya do kornya repozitoriya; sovpadeniye strokovogo prefiksa ili ssyilka toljko na dochernij zapros ne schitayetsya pokryitiyem sosednikh materialov.
- Otkryityiye regressionnyiye fiksturyi vosproizvodyat obe formyi proyavlenij 0002 i 0003. Otricateljnaya granica vklyuchayet sosednij katalog, pokhozhij prefiks, neukazannoye udaleniye i postoronnij fajl; praviljnyij polnyij perechenj prokhodit bez povtornoj zapisi.
- Primeneniye trebuyet neizmennosti proverennogo vkhoda; drejf posle sverki obnaruzhivayetsya. Doslovnyiye komandyi, zakryityiye otchyotyi i iskhodnyiye proverochnyiye svideteljstva ne perepisyivayutsya.
- Adresnyiye RED/GREEN i monotonnyij profilj dokazyivayut ustraneniye propuska na ustanovlennoj granice; vliyaniye na chislo povtornyikh polnyikh obkhodov ocenivayetsya otdeljno, bez vyidumannogo uskoreniya.

## Utochneniye po susjhestvuyusjhim katalogam svoyego etapa

`FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0004` podtverzhdayet tu zhe granicu polnogo fakticheskogo sostava: ssyilki dolzhnyi pokryivatj susjhestvuyusjhiye tekusjhiye mashinnyiye zapisi i sokhranyonnyij lokaljnyij vyivod. Pokryitiye v zaprose ne oznachayet vklyucheniya vyivoda v kommit i ne razreshayet postoronniye izmeneniya. K iskhodnyim scenariyam 0002 i 0003 dobavlyayetsya etot sluchaj sobstvennogo etapa; sosedniye puti i neukazannyiye udaleniya po-prezhnemu otklonyayutsya.

## Utochneniye obyazateljnoj tekusjhej paryi

`FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0005` dobavlyayet proverku dvukh pryamyikh ssyilok: na tekusjhij zapros i sosednij otchyot. Ssyilka na soderzhasjhij ikh katalog ne zamenyayet eti obyazateljnyiye roli. Regressionnaya granica proveryayet kazhduyu otsutstvuyusjhuyu ssyilku, otsutstviye obeikh i korrektnuyu paru do zaklyuchiteljnogo polnogo obkhoda.

## Utochneniye okhvata materialov proverok

`FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0007` dobavlyayet tekusjhiye mashinnyiye zapisi i proizvodnyij indeks svezhesti v rannyuyu proverku polnogo razreshyonnogo Git-perechnya. Ssyilka toljko na plan libo zapros ne pokryivayet sosedniye rezuljtatyi. Predotvrasjheniye i prezhniye otricateljnyiye granicyi ostayutsya nezavershyonnyimi.

## Povtor pri podgotovke novogo etapa

`FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0008` povtoryayet propusk indeksa svezhesti uzhe v sleduyusjhej papke togo zhe kornya. Predvariteljnaya svyaznostj vyiyavila yego do vtoroj polnoj priyomki; tochnaya ssyilka vosstanovlena. Rannyaya avtomatizirovannaya podgotovka dolzhna vklyuchatj proizvodnyiye fajlyi fakticheskogo Git-sostoyaniya kazhdogo etapa, sokhranyaya prezhniye otricateljnyiye granicyi. Ona yesjhyo ne realizovana.

## Povtor pri podgotovke predposyilki i arkhiva

Osnovaniya `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0009` i `FUM-СБОЙ-0051/ПРОЯВЛЕНИЕ-0010` dopolnyayut rannyuyu podgotovku: uchityivatj navigaciyu proshlogo etapa i perenositj tochnyiye katalogi snimkov v dejstvuyusjhij razdel «Povliyal na fajlyi». Ssyilki v «Prikreplyayemyiye materialyi» sami po sebe okhvat ne dayut. Nuzhnyi otricateljnyiye kontroli nepolnogo razdela i polozhiteljnyij tochnyij povtor. [Pervichnyiye svideteljstva i naznacheniye nomerov](../../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/materialyi/povtoryi-oformleniya.json); [iskhodnyij etap](../../Zhurnal/2026-09-15_22-40-08_MSK_sokhranitj-i-udalitj-rolevyiye-forki/zapros.md).

## Istochniki

- [FUM-SBOJ-0051/PROYAVLENIYE-0005 i vosstanovleniye tekusjhej paryi](../../Zhurnal/2026-09-12_05-27-53_MSK_obyyedinitj-arkhiv-fuma-s-kornevoj-rabotoj/zapros.md).

- [FUM-SBOJ-0051/PROYAVLENIYE-0004](../../Sboi/FUM-SBOJ-0051-nepolnyij-perechenj-zatronutyikh-fajlov-zaprosa.md); [registraciya i vosstanovleniye](https://github.com/fum-lab/fum/blob/f5716675472a9807d004e95144b98c621855bfc2/Журнал/2026-09-12_00-44-07_MSK_зарегистрировать-диагностику-продолжения/запрос.md).

- [FUM-SBOJ-0051/PROYAVLENIYE-0002 i FUM-SBOJ-0051/PROYAVLENIYE-0003](../../Sboi/FUM-SBOJ-0051-nepolnyij-perechenj-zatronutyikh-fajlov-zaprosa.md).
- [Tekusjheye porucheniye, vyidacha nomera i granica rabotyi](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_20-38-32_MSK_подключить-наблюдение-к-гостю-и-обмену/запрос.md).
- [Diagnostika desyati materialov](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_18-28-10_MSK_связать-измерения-с-запросом-и-восстановлением/отчёт.md).
- [Diagnostika 29 dochernikh putej](https://github.com/fum-lab/fum/blob/fe3de05afba64554c9f5801f0f2583c43c67705a/Журнал/2026-09-11_19-51-31_MSK_подключить-экспорт-и-повтор-гостевых-измерений/отчёт.md).
- [Susjhestvuyusjhij kontrakt svyaznosti](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md).

- [Tekusjheye proyavleniye0007](../../Zhurnal/2026-09-14_22-03-16_MSK_prinyatj-sovmestnuyu-klassifikaciyu-ostatka/zapros.md).
- Istochnik perenosa `775128491a1b9f9b130bd6946ad2d33fd04dbe51`, SHA-256 `7e98f350cf46ac2cc3239b03ae42edb0b0dfc0b4532096271f3c5057dc0796c2`; prezhniye kriterii i osnovaniya sokhranenyi.
- [FUM-SBOJ-0051/PROYAVLENIYE-0008](../../Sboi/FUM-SBOJ-0051-nepolnyij-perechenj-zatronutyikh-fajlov-zaprosa.md) — [naznacheniye i nablyudeniye tekusjhego etapa](../../Zhurnal/2026-09-14_22-40-28_MSK_obyyedinitj-paketyi-i-proveritj-ostatok/zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 00:05:56 MSK -->
<!-- content-sha256: sha256:b047add96e68713cdaada6f938d45ba53ddf28c204432d5ce7e29b42230c6462 -->
<!-- FUM-MD-RECENCY:END -->
