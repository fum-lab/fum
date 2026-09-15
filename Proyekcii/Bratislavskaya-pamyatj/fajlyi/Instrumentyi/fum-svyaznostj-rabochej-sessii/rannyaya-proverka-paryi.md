# Proveryatj polya paryi Zhurnala do polnogo dopuska

Komanda pomogayet obnaruzhitj nepolnyij otchyot do obkhoda vsego repozitoriya. Primenyajte yeyo posle zapolneniya zaprosa i otchyota i formirovaniya predprosmotra zapuskov. Na vkhod nuzhnyi korenj checkout i kanonicheskij putj zaprosa; sosednij otchyot vyibirayetsya avtomaticheski.

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-поля-журнала.py --корень . --запрос Журнал/<папка-этапа>/запрос.md
```

Komanda proveryayet zagolovki, markeryi nezapolnennogo shablona, profilj stadij, stroku granicyi profilya, tablicu zapuskov i yeyo summu, razdel instrumentov, identifikator zadachi, ssyilki dvukh dokumentov i ssyilki mezhdu nimi. Doslovnaya komanda poljzovatelya sokhranyayet svoyo isklyucheniye; kommentarij ili blok koda ne zamenyayet ssyilku na sosednij dokument. Soderzhimoye celej ssyilok ne zagruzhayetsya.

Rezuljtat — kompaktnyij JSON s oshibkami, otnositeljnyimi putyami, razmerami i SHA-256 dvukh dokumentov. Znacheniye `полная_приёмка` vsegda `false`. Kod 0 oznachayet otsutstviye oshibok v etoj uzkoj granice, 1 — obnaruzhennyij propusk, 2 — nevozmozhnostj korrektno prochitatj vkhod. Fajlyi i Git-sostoyaniye ne menyayutsya. Do i posle proverki sveryayutsya komponentyi putej i bajtyi; eto nablyudeniye stabiljnosti, a ne atomarnyij snimok pri konkurentnoj zapisi.

Posle ispravleniya perechislennyikh polej povtorite malyij vyizov. Zatem trebuyetsya obyichnaya polnaya svyaznostj: rannij rezuljtat ne podtverzhdayet aktualjnostj predprosmotra, polnotu mashinnogo zhurnala, globaljnuyu navigaciyu i ssyilki, recency, soobsjheniye kommita, indeks, publikacionnuyu chistotu ili gotovnostj proyekcii. Novyij vkhod poka vyizyivayetsya yavno; avtomaticheskogo vklyucheniya v obsjhij smoke net.

## Proverka realizacii i izmereniye

V svoyej tekusjhej pare Zhurnala cherez otchyotnuyu obyortku zapuskayutsya:

```text
python3 -B -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_*полей*.py
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/tests/профиль_полей_журнала.py --выход <профиль.json>
```

Profilj sozdayot otkryituyu paru i 1000 fonovyikh dokumentov. Pyatj chereduyusjhikhsya par izmerenij sravnivayut ranniye polya i polnyij obkhod na odnikh vkhodnyikh bajtakh. Sovpadeniye proveryayetsya dlya oshibok profilya; polnyij kontur dopolniteljno otklonyayet nepolnuyu sinteticheskuyu sessiyu. Import i podgotovka isklyuchenyi. Znacheniya ne izmeryayut tokenyi LLM i ne dokazyivayut uskoreniye vsej rabotyi.

Profilj eksportiruyetsya s uslovnyim oboznacheniyem vremennogo kornya. Chisla i vkhodnyiye otpechatki sokhranyayutsya; dobavlyayutsya SHA iskhodnogo serializovannogo obyyekta, chislo zamen i SHA preobrazovatelya. Eto yavnoye proizvodnoye predstavleniye, a ne doslovnaya lokaljnaya diagnostika.

## Proiskhozhdeniye

- [Povtor propusjhennyikh obyazateljnyikh polej](../../Sboi/FUM-SBOJ-0071-nepolnaya-para-zhurnala-pered-kontroljnoj-tochkoj.md).
- [Oformleniye avtomatizacij i rannij kontrolj](../../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0174-opisyivatj-primeneniye-avtomatizacij-bez-chteniya-koda.md).
- [Proverki, izmereniya i ogranicheniya tekusjhej realizacii](../../Zhurnal/2026-09-15_00-46-36_MSK_proveryatj-polya-zhurnala-do-polnoj-svyaznosti/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 01:14:49 MSK -->
<!-- content-sha256: sha256:76e863d18c98977ea613d56f54dea0b23afd3390ccccb7e21f70cd32103cde83 -->
<!-- FUM-MD-RECENCY:END -->
