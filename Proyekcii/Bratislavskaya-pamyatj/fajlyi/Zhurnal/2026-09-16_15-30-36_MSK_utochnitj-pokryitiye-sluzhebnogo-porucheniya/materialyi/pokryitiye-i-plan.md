# Pokryitiye prinyatogo sluzhebnogo porucheniya

Kodovyij snimok: `e0068a2dc8135bbe4d858e46dfd13d0e0c862ad5`. Eto staticheskij analiz susjhestvuyusjhikh kontraktov i nablyudenij, bez izmeneniya realizacii. STEP-0154 ostayotsya active.

## Chto nablyudayetsya

[Svideteljstvo tekusjhego prilozheniya](nablyudayemostj.json): ChatGPT 26.908.70816 (9275), tekusjhij khod gpt-6-astra / medium. Oficialjnyij read_thread podtverdil UUID i svoj cwd. Sredi 31 dostupnogo instrumenta codex_app i vsego obyyavlennogo kataloga ne najden vyizov hooks/list ili universaljnyij vyizov RPC tekusjhego runtime. Sostoyaniye dejstvuyusjhikh hooks, Trust i nativnogo Stop — `unknown`; eto ne utverzhdeniye otsutstviya hooks v prilozhenii.

Oficialjnaya [dokumentaciya App Server](https://learn.chatgpt.com/docs/app-server) opisyivayet `hooks/list` dlya obnaruzhennyikh hooks po cwd i uvedomleniya `hook/started`, `hook/completed` dlya sinkhronnyikh hooks. Nalichiye metoda v protokole ne predostavlyayet ispolnitelyu soyedineniye s tekusjhim prilozheniyem. Novyij app-server ne zapuskalsya; konfiguraciya ne chitalasj kak zamena runtime-nablyudeniyu i ne menyalasj. Dlya snyatiya unknown nuzhen oficialjnyij otvet imenno rabotayusjhego prilozheniya, privyazannyij k yego ekzemplyaru i cwd; primer otdeljnogo CLI ili dokumentaciya etogo ne zamenyayut.

## Proverennyij sluchaj i tochka isklyucheniya

Koordinator predostavil privatnoye svideteljstvo finansovoj zadachi 01a0904a-f98e-70b1-8ea6-a0202ff4de7a, SHA256 `7ccc5634b462bc28f96268c104e8d498ff9276dfc1c40f56214075c82c547c92`. Povtorno sverenyi SHA tryokh ukazannyikh diapazonov pervichnogo JSONL: dostavka, prinyatiye i zaversheniye. Tekstyi ne publikuyutsya. Dostavka imeyet obolochku `response_item / function_call_output`, namespace `codex_app`, name `send_message_to_thread`; stroka output soderzhit codex_delegation. Prinyatiye — assistant message, zaversheniye — event_msg/task_complete.

[Chitatelj soobsjhenij](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/soobsjheniya_zadachi.py), stroki 132–157, propuskayet nemessage-obolochku na strokakh 137–139, zatem soobsjheniya s roljyu ne user na 140–142. Poetomu konkretnaya dostavka isklyuchayetsya do klassifikatora. Eto ne universaljnoye utverzhdeniye o lyuboj budusjhej serializacii codex_delegation. Otdeljnyij [klassifikator proiskhozhdeniya](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/proiskhozhdeniye_soobsjhenij.py), stroki 105–144, sokhranyayet razlichiye chelovecheskogo i sluzhebnogo proiskhozhdeniya; menyatj porucheniye na chelovecheskij vvod radi schyotchika neljzya.

Vyivodyi o nezapisannom prinyatom obyyome, nezavershyonnom vyizove ostatka i otsutstvii finaljnogo guard prinadlezhat sokhranyonnomu nezavisimomu obzoru koordinatora. Zdesj podtverzhdenyi khyesh svideteljstva i tri konkretnyiye obolochki, a ne zanovo issledovano vsyo okno. Prichina vozvrata k staromu voprosu, prichina compaction i prichinnaya svyazj s Low ne dokazanyi. V tom sluchaye guard ne byil vyizvan: fakticheskogo lozhnogo otveta guard eto svideteljstvo ne pokazyivayet. Nizhe opisan risk nepolnogo vkhoda pri budusjhem vyizove.

## Uzhe imeyusjhijsya mekhanizm

| Sloj | Chto dejstviteljno proveryayet | Granica pokryitiya |
| --- | --- | --- |
| Ostatok soobsjhenij | Proiskhozhdeniye, chelovecheskiye ekzemplyaryi, istoriyu ikh obrabotki, polnotu istochnika | Dostavka cherez function_call_output ne stanovitsya chelovecheskim obyazateljstvom; nolj ne dokazyivayet ispolneniye poruchenij |
| Plan v1 | Nepustoj zayavlennyij spisok, sostoyaniya, citatu iz svoyego Zhurnala, UUID | Ne sveryayet spisok s prinyatyimi sluzhebnyimi porucheniyami; svobodnaya stroka svideteljstva dostatochna dlya zavershyonnogo punkta |
| Reyestr v2 | Sokhraneniye uzhe vvedyonnyikh obyazateljstv po Git DAG, roditeljskiye svyazi, kartochki, dokazateljstva priyomki | Ne obnaruzhivayet avtomaticheski yesjhyo ne vnesyonnoye porucheniye; iskhodnoye osnovaniye imeyet strogij kontrakt sobstvennoj komandyi |
| Chastichnyij reyestr v3 | Zakreplyonnyij import FUMA, sokhranyonnyiye opredeleniya i priyomki | Privyazan k UUID koordinatora; ne yavlyayetsya universaljnyim importyorom delegacij, ne dokazyivayet polnoye zaversheniye |
| Sostavnoj guard | Sovmesjhayet rezuljtat obyazateljstv s chelovecheskim ostatkom i povtorno sveryayet vkhodyi | Ne sozdayot obyazateljstva i ne vyizyivayetsya sam; nepolnyij zayavlennyij obyyom v1 ne vospolnyayetsya nulevyim ostatkom |

Istochniki: [obrabotka soobsjhenij](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/obrabotka-soobsjhenij.md), [kontrakt v2](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/kontrakt-obyazateljstv-v2.md), [chastichnyij ostatok v3](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/ostatok-obyazateljstv.md), [guard](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/proveritj-prodolzheniye-zadachi.py), stroki 80–145, 153–200, 236–303.

Nezavisimyij dochernij RO-razbor podtverdil granicyi: [v2](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/obyazateljstva_zadachi_v2.py), stroki 324 i 542; [yakorj v3](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/obyazateljstva_zadachi.py), stroki 24 i 395; [ogovorka polnotyi](../../../Instrumentyi/fum-svyaznostj-rabochej-sessii/SKILL.md), stroka 30. Dochernij razbor ne zapuskal reader, guard ili testyi.

U v1 osnovaniye isjhetsya toljko v doslovnom razdele «Tekst zaprosa» s UUID toj zhe zadachi (80–96); proizvoljnoye dobavleniye sluzhebnogo teksta v drugoj razdel ne stanovitsya mashinnyim osnovaniyem. V1 s rezhimom razovaya mozhet vernutj zavershitj po vsem zavershyonnyim punktam (118–142); postoyannyij v1 pered zaversheniyem prinuditeljno trebuyet prodolzheniya (270–272). Na etom snimke dlya sobstvennogo UUID i finansovoj zadachi otdeljnogo fajla reyestra obyazateljstv net; reyestr koordinatora susjhestvuyet. Eto granica dannogo Git-snimka, ne zayavleniye obo vsekh derevjyakh.

## Gde zakreplyatj prinyatyij obyyom sejchas

Do issledovaniya sokhranyatj iskhodnuyu sluzhebnuyu dostavku s yeyo proiskhozhdeniyem v privatnom dolgovechnom materiale i publikacionno dopustimoye opisaniye prinyatogo obyyoma v sobstvennom zaprose/plane etapa. Ukazyivatj UUID koordinatora i ispolnitelya razdeljno, tochnuyu kodovuyu bazu, razreshyonnyiye dejstviya i ogranicheniya. Rabota etapa dolzhna byitj yavno otrazhena v uzhe susjhestvuyusjhem plane, opirayasj na dejstviteljnoye chelovecheskoye osnovaniye roditeljskoj zadachi; sluzhebnuyu citatu ne vyidavatj za novuyu komandu cheloveka. Soderzhimoye porucheniya i svyazj s osnovaniyem poka proveryayet korenj.

Dolgosrochnyij rezuljtat sokhranyayetsya v susjhestvuyusjhem reyestre obyazateljstv sootvetstvuyusjhej zadachi, kogda primenim yego kontrakt proiskhozhdeniya. Zaversheniye etapa ne udalyayet roditeljskoye obyazateljstvo. Neljzya prosto dopisatj sluzhebnyiye polya v zakryituyu skhemu v1/v2/v3 ili ispoljzovatj reyestr drugogo UUID. Obyichnyij Markdown-plan uzhe polezen dlya vosstanovleniya konteksta, no tekusjhij guard ne proveryayet yego polnotu otnositeljno dostavok.

## Konkretno otsutstvuyusjheye podklyucheniye

Otsutstvuyet dokazannaya mashinnaya svyazj «sluzhebnaya dostavka → yavnoye prinyatiye polnomochnogo obyyoma → dolgovechnaya rabota/obyazateljstvo → sverka polnotyi pered final». V adresno proverennyikh skriptakh svyaznosti net obrabotchika codex_delegation/send_message_to_thread. Eto otdeljnyij probel ot otsutstvuyusjhego nablyudeniya nativnogo Stop. Uzhe realizovannyiye monotonnostj reyestra, dokazateljstva priyomki i chelovecheskij ostatok sleduyet sokhranitj.

## Kompaktnyij plan sleduyusjhego etapa

1. Snachala utverditj granicu podklyucheniya k susjhestvuyusjhemu priyomu poruchenij: kakiye faktyi dokazyivayut dostavku i prinyatiye, kak svyazyivayutsya UUID koordinatora/ispolnitelya, chelovecheskoye osnovaniye i tochnyij sluzhebnyij obyyom. Proveritj vozmozhnostj vyirazitj eto susjhestvuyusjhim kontraktom; yesli yeyo net, otdeljno soglasovatj minimaljnoye rasshireniye, ne pridumyivaya sejchas novuyu skhemu.
2. V otdeljnom razreshyonnom etape podgotovitj adresnyij RED na otkryitoj fiksture s fakticheskoj obolochkoj function_call_output i prinyatiyem assistant: chelovecheskij ostatok 0, a prinyatoye nevyipolnennoye porucheniye dolzhno ostavatjsya dostupnoj rabotoj i prepyatstvovatj zaversheniyu. Proveritj povtor dostavki, pozdneye izmeneniye obyyoma, vosstanovleniye posle compaction, chuzhoj UUID i nepodtverzhdyonnuyu dostavku; sluzhebnoye proiskhozhdeniye sokhranyayetsya.
3. Podklyuchitj registraciyu i sverku polnotyi k susjhestvuyusjhim planu/obyazateljstvam i sostavnomu dopusku; otdeljno dokazatj otkaz pri potere prinyatogo punkta i sokhraneniye roditeljskogo obyazateljstva posle zaversheniya podyetapa. Sverka terminaljnogo rezuljtata ostatka i obyazateljnyij vyizov guard ostayutsya samostoyateljnyimi trebovaniyami.
4. Dlya native-kvalifikacii poluchitj oficialjnyij hooks/list i nablyudeniye sinkhronnogo zapuska imenno tekusjhego prilozheniya. Poka interfejs ne predostavlen, etot podpunkt ostayotsya unknown i ne opravdyivayet podklyucheniye/Trust. Toljko posle razreshyonnogo podklyucheniya otdeljno nablyudatj Stop → block → sleduyusjheye razreshyonnoye dejstviye toj zhe zadachi.

Priyomka budusjhej realizacii dolzhna dokazatj pokryitiye prinyatogo sluzhebnogo obyyoma nezavisimo ot chelovecheskogo schyotchika. Tekusjhij byudzhet Stop i uspeshnoye nativnoye podklyucheniye etim analizom ne dokazanyi. Novyij kod, izmeneniya skhem i testyi v tekusjhem etape ne vyipolnyalisj.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-16 15:37:59 MSK -->
<!-- content-sha256: sha256:a735a03402bd9804fd56944ac4a99597f2ebf66cf839fcf5ca8816d0b7647361 -->
<!-- FUM-MD-RECENCY:END -->
