# Otchyot 2026-07-22 10:02:43 MSK - Dobavitj audit pokryitiya voprosov i otvetov

Razdel `Вопросы и ответы/` poluchil avtonomnyij poluavtomaticheskij audit polnogo korpusa iskhodnyikh zaprosov. Scenarij izvlekayet voprositeljnyiye predlozheniya toljko iz doslovnogo soderzhimogo tochnogo razdela `## Текст запроса`, sopostavlyayet ikh so source-ssyilkami susjhestvuyusjhikh kartochek i vyidayot determinirovannyij spisok dlya ruchnoj smyislovoj proverki.

## Rezuljtat

Chelovekochitayemyij otchyot i JSON skhemyi `fum.question-answer-coverage-audit.v1` perechislyayut kazhdyij vopros s tochnyimi putyom i strokoj, doslovnyim fragmentom, statusom pokryitiya i vsemi kartochkami, ssyilayusjhimisya na tot zhe iskhodnyij zapros. V otchyote yavno povtoryayutsya tri ruchnyikh resheniya: otnosheniye k susjhnosti FUM, soderzhateljnostj otveta i samostoyateljnaya poleznostj.

Izvlecheniye podderzhivayet tekusjhiye istoricheskiye formyi pamyati: neskoljko `text`-fence v odnom zaprose, legacy-blockquote i raw-fallback. Pri nalichii `text`-fence proizvodnyiye poyasneniya i kontejnernyiye zagolovki vokrug nikh ne stanovyatsya vkhodom. Vnutrennij poljzovateljskij H2 ne obryivayet doslovnyij blok, a voprositeljnyiye znaki v inline-code, HTML-kommentariyakh, Markdown-adresakh, bare URL, ekranirovannom tekste i okonchanii `?!` ne schitayutsya terminaljnyimi voprosami.

## Fakticheskij audit korpusa

Posle sokhraneniya tekusjhego prompt proverenyi `234` iskhodnyikh zaprosa. Najdenyi `10` voprositeljnyikh kandidatov v `9` zaprosakh; tri susjhestvuyusjhiye kartochki dayut source-ssyilochnoye pokryitiye tryom kandidatam, semj kandidatov ssyilok ne imeyut.

Ruchnaya proverka dala sleduyusjhij itog:

- tri pokryityikh voprosa neposredstvenno otnosyatsya k susjhnosti FUM i uzhe imeyut soderzhateljnyiye samostoyateljnyiye otvetyi;
- semj nepokryityikh voprosov otnosyatsya k Obsidian, versiyam ChatGPT i Codex, dekompozicii planovoj kartochki, GitHub-dostupu, ocheredi kornevyikh zadach i vetochnoj dispetcherizacii;
- novyiye kartochki `Вопросы и ответы/` ne sozdavalisj, potomu chto ni odin nepokryityij kandidat ne proshyol pervuyu smyislovuyu granicu razdela.

## Granica primenimosti

Voprositeljnyij znak yavlyayetsya toljko vosproizvodimyim punktuacionnyim priznakom. Source-ssyilka kartochki podtverzhdayet pokryitiye iskhodnogo zaprosa na urovne puti, no ne vyibirayet konkretnyij vopros, yesli ikh neskoljko, i ne dokazyivayet kachestvo otveta. Avtomatizaciya ne prinimayet smyislovyikh reshenij i nichego ne ispravlyayet; nalichiye kandidatov yavlyayetsya uspeshnyim shtatnyim rezuljtatom.

## TDD i proverki

Do realizacii zafiksirovanyi testyi tochnoj granicyi razdela, neskoljkikh form doslovnogo payload, punktuacii, vidimosti source-ssyilok, mnozhestvennyikh voprosov i determinirovannogo CLI. Krasnaya faza ozhidayemo otkazala iz-za otsutstvuyusjhego scenariya; posle realizacii avtonomnyij nabor proshyol `11/11` testov.

Polnyij repozitornyij audit podtverdil ozhidayemyij snimok `10 / 3 / 7`: desyatj kandidatov, tri kandidata so ssyilochnyim pokryitiyem i semj bez nego. Itogovyiye planovyiye, recency-, grafovyiye, svyaznostnyiye i smoke-proverki perechislenyi v [iskhodnom zaprose rabochej sessii](zapros.md).

## Prodolzheniye

`FUM-STEP-0029` perevedena v `completed`. Sleduyusjhim bezopasnyim kandidatom `ready` vyibran `FUM-STEP-0023` — lokaljnaya specifikaciya minimaljnoj trassyi ispolnyayemogo agentskogo cikla. `FUM-STEP-0035` ostayotsya `blocked` do otdeljnogo poljzovateljskogo razresheniya.

## Zatronutyiye materialyi

- [kontrakt audita pokryitiya](../../Instrumentyi/fum-audit-pokryitiya-voprosov-i-otvetov/SKILL.md)
- [scenarij audita pokryitiya](../../Instrumentyi/fum-audit-pokryitiya-voprosov-i-otvetov/scripts/audit-question-answer-coverage.py)
- [testyi audita pokryitiya](../../Instrumentyi/fum-audit-pokryitiya-voprosov-i-otvetov/tests/test_audit_question_answer_coverage.py)
- [indeks voprosov i otvetov](../../Voprosyi%20i%20otvetyi/README.md)
- [kartochka FUM-STEP-0029](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0029-dobavitj-poluavtomaticheskij-audit-pokryitiya-razdela-Voprosyi-i-otvetyi.md)
- [rabochij nabor vetki master](../../Planirovaniye/sleduyusjhiye-shagi-vetok/master.md)

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](zapros.md)
- [iskhodnyij zapros o polnom audite voprositeljnyikh blokov](../2026-07-10_06-46-29_MSK_dopolnitj-voprosyi-i-otvetyi-po-vsem-zaprosam/zapros.md)
- [iskhodnyij zapros o smyislovoj granice razdela](../2026-07-13_15-20-42_MSK_ogranichitj-voprosyi-i-otvetyi-susjhnostjyu-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:2f6878e34e221eb166a48ee3b597fcb70561f98bcbdf355e2a63418bdc6996b2 -->
<!-- FUM-MD-RECENCY:END -->
