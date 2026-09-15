# Finansirovaniye i resursyi razvitiya FUM

[Korotkij spisok desyati prioritetov](prioritetyi.md) i [proyekt predlozheniya podderzhki so smetoj](proyekt-predlozheniya-podderzhki.md) podgotovlenyi na 14 sentyabrya 2026 goda. [Polnyij avtomaticheski sformirovannyij spisok](spisok.md) soderzhit 30 organizacij i 38 variantov. [Mashinnyij reyestr](reyestr.json) vosproizvoditsya iz [kartochek s istoriyej](kartochki.json) i [polnogo korpusa issledovanij](issledovaniya.json). Pervyiye 16 organizacij, ikh ID i istoriya sokhranenyi; dobavlenyi 14 novyikh kandidatov i otricateljnyikh rezuljtatov.

Eto rezuljtat [FUM-STEP-0212](../kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) po [trebovaniyu finansirovaniya i resursov](../../Trebovaniya/🟡-finansirovaniye-i-resursyi-razvitiya-FUM.md). Reyestr ne podtverzhdayet polucheniye finansirovaniya ili registraciyu FUM kak NKO. Rossiya i nekommercheskaya oriyentaciya zadanyi; yuridicheskaya forma i registraciya ostayutsya neizvestnyimi.

## Kak chitatj rezuljtat

Organizaciya i konkretnaya programma razlichayutsya. Itog organizacii pokazyivayet naiboleye prodvinutyij iz yeyo variantov; usloviya ostaljnyikh vidnyi nizhe. Status «podkhodit dlya sleduyusjhego shaga» u tekhnicheskogo partnyora oznachayet toljko ukazannuyu lokaljnuyu podgotovku. Pole `доступная_программа` otdeljno trebuyet svezhikh pryamyikh oficialjnyikh istochnikov, podtverzhdyonnogo priyoma, proverennogo sroka i otsutstviya neizvestnyikh uslovij zayavitelya.

Po pryamomu utochneniyu poljzovatelya rassmatrivayutsya vse formyi finansirovaniya pri sokhranenii narodnogo dostoyaniya CC0. Dolevoye finansirovaniye zapisano kak forma «denjgi» s yavnyim ukazaniyem doli i vstrechnyikh prav v variante; denezhnyij dolg — «kredit». Sovmestimostj konkretnogo dogovora s CC0 ne predpolagayetsya.

Denjgi, pozhertvovaniya, sponsorstvo, kredit, oblachnyiye bonusyi, skidka, keshbyek bonusami, kompensaciya raskhodov, oborudovaniye i tekhnicheskoye sotrudnichestvo imeyut raznyiye znacheniya. Iskhodnyiye issledovaniya ne dali proverennoj samostoyateljnoj programmyi peredachi oborudovaniya ili pryamogo sponsorstva; pustota ne zapolnyayetsya vyimyishlennoj organizaciyej. Vse kategorii i formyi razreshenyi kontraktom dlya posleduyusjhej predmetnoj rabotyi.

Dlya programmyi srok aktualjnosti raven 30 dnyam, dlya podgotovki sotrudnichestva — 90 dnyam. Vozrast schitayetsya ot samogo rannego pryamogo chteniya sredi neobkhodimyikh istochnikov; v denj dostizheniya poroga trebuyetsya novaya proverka. Indeks poiska i neudachnaya zagruzka ne obnovlyayut svezhestj. Istyokshij dedlajn oznachayet nedostupnostj; v poslednij denj trebuyetsya sveritj tochnoye vremya. Interval trebuyet datyi okonchaniya, nachalo mozhet byitj neizvestno. Postoyannyij priyom dolzhen byitj pryamo ustanovlen istochnikom. Istoricheskij otricateljnyij rezuljtat sokhranyayetsya s otdeljnoj otmetkoj ustarevaniya.

Iskhodnyij nabor imeyet ustojchivyiye ID, vyichislennyiye iz iskhodnogo imeni issledovaniya i nazvaniya organizacii. Proveryayetsya tochnoye pokryitiye vsekh iskhodnyikh kandidatov, dubli i neizmennostj iskhodnogo issledovaniya. SHA-256 iskhodnoj peredachi, zayavlennyij issledovatelem, sokhranyayetsya kak proiskhozhdeniye; on ne vyidayotsya za proverennyij khyesh nyineshnego JSON. Khyesh vkhoda dlya obnovleniya vyichislyayetsya posle kanonicheskoj serializacii JSON, a khyeshi fajlov svideteljstv — po tochnyim bajtam.

## Vosproizvedeniye bez seti

Nuzhnyi Python 3.11 ili noveye i obyichnyij chistyij klon FUM. Dopolniteljnyiye paketyi dlya vyipuska reyestra ne nuzhnyi. Fakticheskaya proverka vyipolnena na macOS arm64 s Python 3.14.7; otdeljnyij profilj pamyati ispoljzuyet POSIX-modulj `resource`. Vse komandyi vyipolnyayutsya iz kornya svoyego checkout.

```bash
python3 -B Инструменты/fum-reyestr-planirovaniya/scripts/реестр-организаций-поддержки.py сформировать \
  --корень-репозитория . \
  --исследования Планирование/финансирование-и-ресурсы/исследования.json \
  --вход Планирование/финансирование-и-ресурсы/карточки.json \
  --дата 2026-09-14 --выход Планирование/финансирование-и-ресурсы
```

Zamenitj `сформировать` na `проверить`, chtobyi sveritj sokhranyonnyiye rezuljtatyi bez zapisi. Data obyazateljna i ne podstavlyayetsya iz chasov kompjyutera. Pri drugoj date generator ispoljzuyet posledneye nablyudeniye ne pozdneye neyo; on ne delayet novogo veb-chteniya. Sluzhebnyij konechnyij blok Markdown-recency isklyuchyon iz sravneniya teksta, no ne iz proverki yego sobstvennyim instrumentom.

Kod 0 oznachayet uspeshnoye vyipolneniye vyibrannoj operacii. Kod 2 oznachayet otkaz kontrakta, nevernyiye parametryi ili nedostupnyij fajl; polozhiteljnyij finansovyij dopusk iz koda zaversheniya ne sleduyet. Polnyij vkhod proveryayetsya do zapisi. Vyikhodam zapresjheno peresekatjsya s kartochkami, issledovaniyami i svyazannyimi svideteljstvami. Kazhdaya zamena fajla atomarna; dva vyikhodnyikh fajla ne sostavlyayut obsjhuyu tranzakciyu. Posle sboya mezhdu zamenami `проверить` obnaruzhit nepolnyij vyipusk, kotoryij mozhno povtoritj.

## Dobavleniye novogo nablyudeniya

Snachala adresno prochitatj aktualjnyiye oficialjnyiye usloviya, sokhranitj istochnik susjhestvuyusjhim mekhanizmom [materialov zaprosov](../../Instrumentyi/fum-materialyi-zaprosov/SKILL.md) i podgotovitj JSON nablyudeniya toj zhe strukturyi, chto poslednij element `проверки` vyibrannogo varianta. Avtor, data, sposob polucheniya, neizvestnyiye i minimaljnyij sleduyusjhij shag zapolnyayutsya yavno. Data novogo chteniya ne pripisyivayetsya staromu issledovatelyu.

Dlya neizmenyayemogo svideteljstva sokhranitj bajtyi izvlechyonnogo teksta v kataloge kanonicheskogo URL: `свидетельства/<sha256>/извлечённый-текст.txt`. Vlozhennyij snimok soderzhit prezhnij nastoyasjhij URL v `source-url.txt`, proiskhozhdeniye i sobstvennyij `snapshot-manifest.json`; suffiks khraneniya ne yavlyayetsya novyim URL. Manifest sozdayotsya susjhestvuyusjhim `write_snapshot_manifest` posle zapisi fajlov i vklyuchayet samogo sebya. `install_snapshot` sokhranyayet samostoyateljnyiye vlozhennyiye snimki pri obnovlenii roditelya. Roditeljskij manifest ne vklyuchayet ikh fajlyi.

V `снимок` ukazatj tochnyij otnositeljnyij putj teksta i SHA-256 yego bajtov. Manifest proveryayet sostav fajlov, a reyestr otdeljno proveryayet SHA; on ne zamenyayet sverku publikacionnoj chistotyi istochnika. Staryiye bajtyi i khyesh ne perepisyivatj. `снимок: null` chestno oboznachayet otsutstviye sokhranyonnyikh bajtov imenno etogo chteniya; oficialjnyij adres i svideteljstvo vsyo ravno obyazateljnyi. [Karta pervogo perenosa](iskhodnyiye-dannyiye/perenos-svideteljstv.json) svyazyivayet prezhniye puti iz istoricheskikh vkhodov s tekusjhim khraneniyem bez izmeneniya dat, avtorov i uslovij.

Poluchitj ozhidayemyij kanonicheskij khyesh kartochek:

```bash
python3 -B - <<'PY'
import sys
from pathlib import Path
sys.path.insert(0, 'Инструменты/fum-reyestr-planirovaniya/scripts')
import реестр_поддержки as реестр
print(реестр.хэш(реестр.разобрать(Path('Планирование/финансирование-и-ресурсы/карточки.json').read_bytes())))
PY
```

Vyizvatj `обновить` s obsjhimi `--корень-репозитория`, `--исследования`, `--вход` i dopolniteljnyimi `--организация FUM-ORG-…`, `--вариант <ид>`, `--наблюдение <путь.json>`, `--ожидаемый-хэш <полученный хэш>`. Pervyij vyizov bez `--применить` pokazyivayet khyeshi do i posle bez zapisi. Povtor s `--применить` dobavlyayet nablyudeniye posle proverki ozhidayemogo khyesha. Staroye chteniye ostayotsya v istorii; novaya proverka toj zhe datyi dobavlyayetsya posle prezhnej. Idempotentno toljko sovpadeniye s poslednim nablyudeniyem, poetomu vozvrat sostoyaniya posle promezhutochnogo izmeneniya sokhranyayetsya. Zasjhita rasschitana na odnogo pisatelya dereva; eto ne blokirovka konkurentnyikh processov.

Operaciya `импортировать` sozdayot nezapolnennuyu zagotovku dlya zadannogo korpusa issledovanij i ne perezapisyivayet zapolnennyiye kartochki. Zagotovka yesjhyo ne prokhodit vyipusk. Izmeneniye samogo korpusa organizacij ili yuridicheskogo profilya trebuyet otdeljnoj yavnoj migracii: etot pervyij kontrakt ne razreshayet nezametno udalitj kandidatov ili obyyavitj registraciyu podtverzhdyonnoj.

## Rasshireniye korpusa 14 sentyabrya 2026 goda

Novyij poisk i utochneniya o vsekh formakh finansirovaniya dali yavnoye osnovaniye rasshiritj korpus. Pervyiye dva konverta issledovanij i pervyiye 16 kartochek sokhranenyi bez smyislovogo izmeneniya. Tretij konvert — konsolidaciya kornya po pryamyim chteniyam i materialam tryokh issledovatelej; yego khyesh vyichislen po kanonicheskomu JSON i ne vyidayotsya za iskhodnuyu peredachu rebyonka. Yuridicheskij profilj FUM ne izmenyon. [Karta migracii](../../Zhurnal/2026-09-14_14-19-35_MSK_najti-dopolniteljnoye-finansirovaniye-rabotyi-FUM/materialyi/migraciya-korpusa.json) fiksiruyet staryij i novyij khyesh, ID, 23 pervichnyikh svideteljstva i dva razdeljnyikh svideteljstva Boosty posle revjyu.

Chastj svideteljstv — yavno oboznachennyiye pereskazyi pryamogo chteniya, a ne polnyiye dokumentyi. HTML Boosty dayot obolochku, poetomu usloviya vzyatyi iz otrisovannogo brauzerom teksta, prochitannogo issledovatelem. PDF Rosmolodyozhi povtorno ne zagruzilsya. Eto ogranicheniye ne skryito za khyeshem snimka.

Posle izmeneniya nablyudenij povtoryayetsya ta zhe komanda vyipuska s yavnoj datoj; pered prodolzheniyem zayavok adresno perechityivayutsya dejstvuyusjhiye usloviya. Prioritetyi — otdeljnoye redakcionnoye resheniye o poryadke podgotovki s pryamyimi ssyilkami v sformirovannyij spisok. Polucheniye sredstv, gotovnostj podachi i zakonnostj konkretnoj sdelki iz uspeshnogo vyipuska ne sleduyut.

## Proverki i profilj

```bash
python3 -B -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p test_реестр_поддержки.py
python3 -B Инструменты/fum-reyestr-planirovaniya/tests/профиль_реестра_поддержки.py \
  --дата 2026-09-14 --повторы 7 --выход .build/профиль-реестра-поддержки.json
```

Profilj izmeryayet chteniye sokhranyonnyikh dannyikh, proverku svideteljstv, ocenku i shablonnyij vyipusk v progretom processe. Setj, zapusk Python i zapisj vyikhodnyikh fajlov za granicej. Otchyot soderzhit versii, khyeshi vkhodov i koda, povtoryi, pamyatj i khyeshi rezuljtata. Vlozhennyiye intervalyi ne skladyivayutsya s obsjhim vremenem.

## Istochniki

- [Iskhodnoye porucheniye](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/запрос.md).
- [Dva peredannyikh issledovaniya](../../Zhurnal/2026-09-11_13-39-59_MSK_prinyatj-napravleniye-finansirovaniya-FUM/materialyi/issledovaniya/organizacii-podderzhki-FUM.json).
- [Itogovyij etap priyomki](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_16-12-17_MSK_завершить-приёмку-реестра-поддержки-FUM/отчёт.md).
- [Otchyot realizacii i ogranicheniya proverki](https://github.com/fum-lab/fum/blob/6c9babdd3663ff0112283b89a361068727825da6/Журнал/2026-09-11_14-52-06_MSK_создать-реестр-организаций-поддержки-FUM/отчёт.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 06:23:18 MSK -->
<!-- content-sha256: sha256:513469c97a3f16a35c676ef3a160049c57752928e2f125d9816349dc0d7ff391 -->
<!-- FUM-MD-RECENCY:END -->
