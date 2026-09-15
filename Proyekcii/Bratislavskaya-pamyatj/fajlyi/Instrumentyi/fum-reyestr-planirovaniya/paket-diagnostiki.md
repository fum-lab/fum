# Vyipuskatj podgotovlennyij paket diagnostiki

Uzkaya komanda prinimayet yavnyij paket kartochek s uzhe naznachennyimi nomerami, stroit proveryayemyiye budusjhiye tekstyi i primenyayet sokhranyonnyij plan. Smyisl, chislo proyavlenij, istochniki i status zadayot rabochaya sessiya posle sverki dokazateljstv. Fajlyi ogranichenyi kartochkami `Сбои/`, kartochkami `Планирование/карточки-шагов/` i dvumya sootvetstvuyusjhimi `README.md`.

## Podgotovitj dannyiye

Vkhod — JSON s tochnyimi polyami `схема: "fum.пакет-диагностики.1"`, `сбои` i `шаги`. Oba poslednikh polya — massivyi; vsego dopuskayetsya ot 1 do 100 zapisej. Dlya kazhdoj zapisi nuzhnyi:

| Pole | Znacheniye |
| --- | --- |
| `операция` | `создать` libo `обновить` |
| `номер` | Uzhe naznachennyij `FUM-СБОЙ-NNNN` libo `FUM-STEP-NNNN` |
| `имя` | Opisaniye imeni fajla iz bukv i cifr, razdelyonnyikh defisami; bez puti |
| `статус` | Dlya SBOJ: `активна`, `устранена`, `поглощена`, `снята`; dlya STEP: `active`, `completed`, `absorbed`, `withdrawn` |
| `заголовок` | Gotovyij soderzhateljnyij zagolovok bez perevoda stroki i simvolov `[]\|` |
| `содержимое` | Gotovyiye razdelyi Markdown bez metadannyikh TOML i zagolovka pervogo urovnya |
| `до_sha256` | `null` dlya sozdaniya; polnyij SHA-256 iskhodnyikh UTF-8 bajtov kartochki dlya obnovleniya |

U SBOJ obyazateljnyi yesjhyo `проявлений` — yavno proverennoye polozhiteljnoye celoye chislo, i `основной_шаг` — naznachennyij `FUM-STEP-NNNN` libo `null`. Aktivnomu sboyu nuzhen osnovnoj shag; `null` vyivoditsya v indekse znakom «—». Chislo ne izvlekayetsya iz upominanij nomera v proze. Kvalificirovannaya ssyilka na istoricheskij kommit i putj ostayotsya bukvaljnoj ssyilkoj: yeyo lokaljnyij nomer ne pereadresuyetsya sovremennoj kartochke.

Telo SBOJ soderzhit vosemj nepustyikh razdelov [kanonicheskogo formata](../../Glossarij/kartochka-sboya.md) i sootvetstvuyusjhij statusu razdel podtverzhdeniya. STEP proveryayetsya tem zhe parserom, chto mashinnyij reyestr. Chislo proyavlenij, smyisl dokazateljstva zakryitiya i polnota dvustoronnikh svyazej ostayutsya otdeljnoj smyislovoj proverkoj; eto ne polnyij kontur FUM-STEP-0114.

Dlya istoricheskogo vkhoda bez TOML dopuskayetsya toljko prezhnyaya nachaljnaya shapka: yedinstvennyiye zagolovok `# FUM-СБОЙ-NNNN — …`, stroka `- Идентификатор: ` s tem zhe nomerom v obratnyikh kavyichkakh i konechnoj tochkoj, i stroka dopustimogo statusa. Nomer obyazan sovpadatj s yavno zadannyim obnovleniyem; iskhodnyij SHA-256 proveryayetsya do razbora. Proza posle pervogo razdela ne obyyavlyayet identichnostj. Vyikhod normalizuyetsya v kanonicheskij TOML.

Obnovleniye sokhranyayet nomer i putj: `имя` dolzhno sovpadatj s susjhestvuyusjhim fajlom. Pereimenovaniye i smena statusnogo imeni STEP vyipolnyayutsya shtatnoj otdeljnoj avtomatizaciyej. Neizvestnyiye polya, povtornyiye JSON-klyuchi, dubli nomerov, podmena fajlov, simvolicheskiye ssyilki i kollizii registra ili Unicode pri podgotovke otklonyayutsya.

## Proveritj i primenitj plan

Rabotajte v svoyom worktree i vetke `codex/…`, sokhranyaya vkhod i plan vne publikuyemogo checkout. Iz kornya FUM:

```text
python3 Инструменты/fum-reyestr-planirovaniya/scripts/пакет_диагностики.py план --корень . --задача <корневой-UUID> --вход <пакет.json> > <план.json>
python3 Инструменты/fum-reyestr-planirovaniya/scripts/пакет_диагностики.py применить --корень . --задача <корневой-UUID> --вход <план.json> > <квитанция.json>
```

Snachala prochitajte `данные.файлы` plana: dlya kazhdogo puti sokhranenyi tochnyiye `до` i `после`. Konvert svyazyivayet polnyij paket, fizicheskij korenj, vladeljca, vetku, iskhodnyij kommit i kontroljnyiye summyi. Kontroljnaya summa obnaruzhivayet povrezhdeniye, a povtornoye postroyeniye tekstov iz paketa ne pozvolyayet proizvoljno rasshiritj spisok fajlov. Eto ne cifrovaya podpisj smyislovogo resheniya.

Primeneniye povtorno proveryayet vladeljca, vetku, iskhodnyij kommit i vse iskhodnyiye bajtyi pod obsjhim zamkom khranilisjha. V tom zhe zamke pered ciklom ustanovki povtorno sveryayutsya imena, NFC/casefold i identichnosti sosednikh kartochek: chastichno zapisannyij vtoroj plan ne dopuskayet dve kartochki odnogo nomera. Sobstvennyiye sokhranyonnyiye budusjhiye bajtyi dopuskayutsya dlya vosstanovleniya. Namereniye sokhranyayetsya do zapisi checkout; kazhdyij fajl ustanavlivayetsya atomarnoj zamenoj s sinkhronizaciyej. Paket ne yavlyayetsya yedinoj fajlovoj tranzakciyej: preryivaniye mozhet ostavitj chastj novyikh fajlov, i povtor togo zhe plana zavershayet sokhranyonnoye namereniye. Neozhidannyiye bajtyi zakryivayut povtor. Posle uspeshnogo primeneniya sokhranite kvitanciyu i proverjte diff; pered proizvodnyimi izmeneniyami zavershite neobkhodimoye vosstanovleniye. Izmenyonnyiye vposledstvii generatorom fajlyi ne yavlyayutsya prezhnimi bajtami etogo plana.

Daleye shtatno obnovite mashinnyij reyestr, zatem recency i svyaznostj svoyej sessii:

```text
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json
python3 Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json
```

Komanda ne raspredelyayet nomera, ne pishet chuzhiye vetki, ne sozdayot vneshniye zadachi, ne delayet kommit ili push. Identifikatoryi rezerviruyutsya do podgotovki paketa susjhestvuyusjhim obsjhim raspredelitelem. Neprotokoljnyiye ruchnyiye pisateli dolzhnyi byitj isklyuchenyi vladeljcem sessii.

## Vosproizvesti proverku

Cherez otchyotnuyu obyortku svoyej sessii zapustite adresnyij nabor i malyij profilj. Oni ispoljzuyut toljko otkryityiye vremennyiye Git-repozitorii:

```text
python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_пакета_диагностики.py
python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_пакета_диагностики.py --выход <профиль.json>
```

Profilj izmeryayet pyatj otdeljnyikh paketov po pyatj SBOJ, dva STEP i dva indeksa, zatem tochnyij povtor. On sokhranyayet intervalyi i khyeshi instrumentov; podgotovka vremennogo Git isklyuchena, nablyudeniye vladeljca, chteniye, zamok i sinkhronizaciya fajlov vklyuchenyi.

## Proiskhozhdeniye

- [Komanda i granica realizacii v prinyatom dochernem kommite](https://github.com/fum-lab/fum/blob/4779f4d541a78effad2679bac1ed3a7e4f285403/Журнал/2026-09-11_05-17-24_MSK_выпускать-пакет-диагностики/запрос.md).
- [Dolgovechnoye khranilisjhe priyoma](priyom-napravlenij.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 07:09:21 MSK -->
<!-- content-sha256: sha256:0959af51bc872ad08b44037acc74c75b3735459bdedd66084ec7cd8110ce122b -->
<!-- FUM-MD-RECENCY:END -->
