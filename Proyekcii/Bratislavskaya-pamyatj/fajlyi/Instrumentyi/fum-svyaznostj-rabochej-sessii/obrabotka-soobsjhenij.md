# Proveryatj obrabotku iskhodnyikh soobsjhenij

Avtomatizaciya pokazyivayet, kakiye soobsjheniya yesjhyo trebuyut otveta ili peresmotra. Ona uchityivayet vesj dialog, poetomu staryij propusk ne ischezayet posle novogo soobsjheniya ili szhatiya konteksta. Snachala agent rassmatrivayet original vmeste s utochneniyami, sokhranyayet otvet i osnovaniye v Zhurnale, zatem podtverzhdayet obrabotku.

Komandnyij vkhod obyazatelen pri vosstanovlenii i sverke dogovoryonnostej; [sostavnoj dopusk](SKILL.md#resheniye-o-prodolzhenii-zadachi) vyizyivayet yego pered zaversheniyem bez zapisi. Pustoj ostatok soobsjhenij ne oznachayet vyipolneniya vsekh poruchenij: reyestr obyazateljstv proveryayetsya otdeljno.

## Poluchitj ostatok

Pri vosstanovlenii i sverke iz svoyego rabochego dereva zadajte iskhodnyij JSONL kornevoj zadachi i yeyo UUID:

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обработать-сообщения-задачи.py --корень-репозитория . --исходник <JSONL> --codex-thread-id <UUID> остаток --без-записи
```

Pole `сообщения` soderzhit vse originalyi po poryadku. Pole `остаток` ssyilayetsya na trebuyusjhiye razbora ekzemplyaryi i obyyasnyayet prichinu: net obrabotki, utracheno svideteljstvo, poyavilsya pozdnij vvod ili aktualjnostj neyasna. Pozdniye soobsjheniya vyidayutsya i togda, kogda sami uzhe obrabotanyi. Polnyij indeks khranitsya v otvete odin raz; zapisi ostatka ssyilayutsya na yego identifikatoryi.

Kod 3 oznachayet, chto ostalsya razbor ili nepolnyij vvod. Kod 2 oznachayet oshibku istochnika, istorii ili yeyo proverki: pustoj uspeshnyij rezuljtat ne vyidayotsya. Kod 0 podtverzhdayet toljko aktualjnyij uchyot soobsjhenij. Ni odin kod etoj komandyi samostoyateljno ne razreshayet zaversheniye zadachi.

Rezhim `остаток --без-записи` obyazatelen dlya vosstanovleniya i sverki. Putj `--кэш` neobyazatelen; susjhestvuyusjhij kyesh mozhno ispoljzovatj bez izmeneniya. Komanda ne sozdayot kyeshi, katalogi, fajlyi blokirovok i zapisi obrabotki. Zapusk s `python3 -B` isklyuchayet sozdaniye bajtkoda interpretatorom. Otdeljnaya komanda `сохранить` ostayotsya pishusjhej.

Yesli vo vremya zaklyuchiteljnogo chteniya zamechenyi yesjhyo ne razobrannyiye bajtyi, `непроверенный_хвост` pokazyivayet ikh kolichestvo, `полнота_источника` i `разбор_сообщений_завершён` ostayutsya lozhnyimi. `граница_заключительной_сверки` pokazyivayet proverennuyu LF-granicu. Eto poleznyij ogranichennyij rezuljtat, trebuyusjhij sleduyusjhego chteniya; novoye podtverzhdeniye obrabotki pri takom khvoste otklonyayetsya.

Otvet soderzhit privatnyij iskhodnyij vvod i ssyilki na vlozheniya. Yego neljzya avtomaticheski perenositj celikom v publichnyij repozitorij. V Zhurnal sokhranyayutsya otdeljno proverennyiye dopustimyiye komandyi i otvetyi; skryityiye rassuzhdeniya ne eksportiruyutsya.

## Podtverditj obrabotku

Agent snachala sopostavlyayet iskhodnuyu komandu s pozdnimi soobsjheniyami. Otmena, zamena i utochneniye ssyilayutsya na konkretnyij pozdnij chelovecheskij vvod. Sluzhebnyij kontekst ne yavlyayetsya takim osnovaniyem. Yesli smyisl ostayotsya neyasnyim, resheniye sokhranyayet neobkhodimostj razbora.

Posle zapisi originala, soderzhateljnogo otveta i osnovaniya agent gotovit JSON resheniya. On beryot `экземпляр` i vesj `контекст` iz poluchennogo ostatka, ukazyivayet resheniye i aktualjnostj, tochnyiye pozdniye identifikatoryi i tri svideteljstva: `команда`, `ответ`, `основание`. Svideteljstvo svyazyivayet otnositeljnyij kanonicheskij putj, nepustoj diapazon bajtov i SHA-256 diapazona.

Svideteljstvo komandyi dopolniteljno zadayot format: `текст` dlya polnogo iskhodnogo teksta libo `части-json` dlya vsekh chastej mnogochastnogo soobsjheniya. Strukturnyiye chasti serializuyutsya UTF-8, s otsortirovannyimi klyuchami, kompaktnyimi razdelitelyami i zavershayusjhim LF; podstroka i poteryannoye vlozheniye ne podtverzhdayut polnyij original. Samo vlozheniye etot mekhanizm ne skachivayet.

Dopustimyiye resheniya: `ответ`, `работа`, `уточнение`, `отказ`. Aktualjnostj: `актуально`, `уточнено`, `заменено`, `отменено`, `выполнено`, `неясно`. Posledneye ostavlyayet soobsjheniye na razbore. Metka `выполнено` opisyivayet vyivod agenta i ne pogashayet otdeljnyij reyestr obyazateljstv.

```text
python3 -B Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обработать-сообщения-задачи.py --корень-репозитория . --исходник <JSONL> --codex-thread-id <UUID> --кэш <частный-кэш> сохранить --решение <JSON-решения> --ожидаемая-история <история_sha256-из-остатка>
```

Komanda proveryayet svideteljstva i aktualjnostj rassmotrennoj granicyi pered atomarnoj zapisjyu. Polnota smyisla otveta i korrektnostj vyivoda ostayutsya otvetstvennostjyu agenta; sovpadeniye bajtov ne dokazyivayet smyisl.

## Istoriya i vosstanovleniye

Istoriya sokhranyayetsya v `Планирование/задачи/<UUID>/обработка-сообщений.jsonl`. Yeyo zagolovok svyazyivayet zadachu s iskhodnyim JSONL, a posleduyusjhiye stroki — neizmenyayemyiye sobyitiya obrabotki i peresmotra. Proveryayutsya polnyij dostizhimyij Git DAG, oba roditelya sliyanij i rabochaya versiya. Udalyonnyij libo perepisannyij prefiks ne stanovitsya pustyim nachalom.

Utrata otveta ili osnovaniya vozvrasjhayet soobsjheniye na razbor. Dazhe vosstanovleniye prezhnikh bajtov posle zafiksirovannogo v Git udaleniya ne stirayet etot fakt: nuzhno novoye rassmotreniye. Konfliktuyusjhiye linejnyiye khvostyi raznyikh vetvej trebuyut otdeljnogo resheniya; avtomatizaciya ikh ne skleivayet molcha.

Zamok sootvetstvuyet fizicheskomu Git-katalogu i UUID istorii, poetomu vyibor drugogo kyesha ne sozdayot vtorogo pisatelya. Atomarnaya zamena i sinkhronizaciya dannyikh i roditeljskikh katalogov podderzhivayut povtor posle preryivaniya. Yesli otvet o zapisi poteryan, povtorite to zhe resheniye s prezhnim ozhidayemyim SHA istorii. Uzhe ustanovlennoye sobyitiye uznayotsya bez dublirovaniya.

Pri takom povtore vozvrasjhyonnyij `история_sha256` otnositsya k prefiksu neposredstvenno posle povtoryayemoj operacii. Yesli pozzhe dobavlyalisj sobyitiya, dlya sleduyusjhego novogo resheniya zanovo zaprosite ostatok i tekusjheye pokoleniye. Izmenivshayasya istoriya ili novyij chelovecheskij vvod ne razreshayut primeneniye drugogo ustarevshego resheniya.

## Skorostj i granica proverki

Kyesh iskhodnyikh soobsjhenij i otdeljnyij kyesh granic ostayutsya chastnyimi. Proverennyiye granicyi povtorno ispoljzuyutsya toljko pri sovpadenii ustrojstva, inode, razmera, vremyon izmeneniya i SHA realizacii. Pri dobavlenii dannyikh ili smene koda prefiks proveryayetsya zanovo. Povrezhdyonnyij kyesh dayot otkaz.

Dlya nezavisimoj polnoj sverki dobavjte `--перепроверить` posle `остаток`. Byistryij rezhim opirayetsya na nablyudeniye metadannyikh lokaljnoj FS; on ne zasjhisjhayet ot vladeljca mashinyi, sposobnogo soglasovanno podmenitj istochnik, kyesh i metadannyiye. Proverka v konce vyizova obnaruzhivayet nablyudyonnyij drejf; eto ne globaljnaya tranzakcionnaya blokirovka runtime i vsekh fajlov.

Dva chteniya odnogo raschyota ispoljzuyut obsjhij proverennyij indeks toljko v pamyati etogo vyizova. Pri neizmennom istochnike povtornyij razbor ne nuzhen; pri izmenenii proveryayetsya SHA prezhnego prefiksa i razbirayetsya novyij khvost. Naruzhu peredayotsya kopiya soobsjhenij, vnutrennij indeks ne vklyuchayetsya v publichnyij rezuljtat. Raznyiye vyizovyi ne delyat globaljnoye izmenyayemoye sostoyaniye. Polnaya pereproverka sokhranyayet povtornoye chteniye vsekh strok.

Scenarij `scripts/измерить-остаток-сообщений.py --повторов 3 --выход <профиль>` vosproizvodit 70 MiB JSONL so staryim propuskom, povtorom komandyi, pozdnim utochneniyem i odnoj obrabotkoj v Git. Dlya sravneniya togo zhe koda bez kyesha granic dobavjte `--без-кэша-границ`; `--без-записи` izmeryayet otsutstviye diskovogo kyesha na kazhdoj stadii. Profilj vklyuchayet chteniye, istoriyu Git i svideteljstva; podgotovka fiksturyi isklyuchena. V rabochej sessii proverki vyipolnyayutsya cherez otchyotnuyu obyortku.

Dopisyivaniye zhivogo JSONL ne udlinyayet chteniye za vyibrannyij nachaljnyij razmer. Sokhranyonnyiye granicyi proveryayutsya nezavisimo ot novogo khvosta; povrezhdyonnyij staryij prefiks otklonyayetsya. Novyij chelovecheskij vvod, obnaruzhennyij zaklyuchiteljnoj sverkoj, trebuyet povtornogo raschyota. Bezzapisnyij raschyot vklyuchyon v obyazateljnyij sostavnoj dopusk. Eto ne dokazyivayet nativnuyu ustanovku Stop v konkretnom runtime.

## Istochniki

- [Komandyi, otvetyi i otchyot vtorogo segmenta](../../Zhurnal/2026-09-10_23-24-41_MSK_svyazatj-obrabotku-soobsjhenij-s-istoriyej/zapros.md).
- [Pervyij segment chteniya JSONL](soobsjheniya-zadachi.md).
- [Polnyij obyyom FUM-STEP-0177](../../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0177-vozvrasjhatj-neobrabotannyiye-soobsjheniya-poljzovatelya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:33:08 MSK -->
<!-- content-sha256: sha256:b4ef2afe2225b92fd3463d99c15e4e8569ccc2a8f6a6bd0b1ead830993db878c -->
<!-- FUM-MD-RECENCY:END -->
