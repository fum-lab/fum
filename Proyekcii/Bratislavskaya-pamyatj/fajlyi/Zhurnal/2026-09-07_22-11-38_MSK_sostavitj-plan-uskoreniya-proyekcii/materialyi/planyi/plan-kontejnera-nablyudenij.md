# Plan kontejnera nablyudenij s JSON-zagolovkami

Status: vyibrannoye poljzovatelem napravleniye i proyektnaya detalizaciya. Realizaciya yesjhyo ne vyipolnena. Komandyi 32–33 i otvetyi perenesenyi iz razreshyonnogo vneshnego chernovika posle zaversheniya progona 92.

## Komandyi 32 i 33

````text
Dumayu khranitj nuzhno vsyo v jsonl, aktivno vstraivaya v nego dannyiye v binarnom formate, specifikaciya i tip kotoryikh vsyo ravno opisan v json-obyyektakh.
````

````text
Вопрос: Какую границу формата выбираем для встроенных бинарных данных?
Ответ: Контейнер: JSON-заголовки описывают следующие за ними сырые бинарные блоки; это уже отдельный формат.
````

## Soderzhateljnyiye otvetyi

32. Prinyato trebovaniye khranitj dannyiye nablyudeniya vmeste s opisaniyem ikh tipa i formata. Utochnena granica: strogij JSONL soderzhit dopustimoye JSON-znacheniye v kazhdoj UTF-8-stroke; proizvoljnyiye syiryiye binarnyiye bloki trebuyut drugogo kontejnera. Zadan vopros o vyibore kodirovaniya v JSONL libo JSON-zagolovkov s syiryimi blokami.

33. Poljzovatelj vyibral yedinyij kontejner s JSON-zagolovkami i sleduyusjhimi za nimi syiryimi binarnyimi blokami. Etot vyibor zamenyayet v plane vneshneye khranilisjhe krupnyikh obyyektov. Chteniye iskhodnogo dialoga Codex iz fakticheskogo JSONL sokhranyayetsya kak otdeljnaya obyazannostj. Nazyivatj novyij binarnyij kontejner JSONL ne sleduyet.

## Predlagayemyij kontrakt

- Segment nachinayetsya s signaturyi i versii. Pered zapisjyu raspolagayetsya fiksirovannyij prefiks s dlinoj JSON-zagolovka i dlinoj binarnoj nagruzki v bajtakh. Shirina chisel i poryadok bajtov zakreplyayutsya do realizacii. Perevod stroki ili pokhozhaya na signaturu posledovateljnostj vnutri nagruzki ne menyayut granic.
- JSON-zagolovok sokhranyayet identifikator zapisi, poryadok, istochnik, vremena, tip, versiyu skhemyi, identifikator i khyesh specifikacii, svedeniya o kodirovanii ili szhatii i ozhidayemyij razmer vosstanovlennyikh dannyikh. Sobstvennyiye neobkhodimyiye specifikacii vklyuchayutsya v kontejner otdeljnyimi zapisyami; vneshnij adres sluzhit dopolniteljnyim proiskhozhdeniyem.
- Neizvestnyij tip ne meshayet sokhranyatj i izvlekatj iskhodnyiye bajtyi. Vozmozhnostj interpretirovatj dannyiye otdeljno zavisit ot podderzhki tipa i versii.
- Krupnyij obyyekt razbivayetsya na ogranichennyiye fragmentyi. Zagolovki fiksiruyut obsjhij identifikator obyyekta, nomer, smesjheniye, dlinu i kontroljnuyu summu. Zavershayusjhaya zapisj gruppyi svyazyivayet polnyij poryadok fragmentov, summarnyij razmer i khyesh vosstanovlennogo obyyekta. Sobyitiye vmeste s dannyimi prinimayetsya toljko kak polnostjyu proverennaya gruppa.
- Do vyideleniya pamyati proveryayutsya dlinyi zagolovka i nagruzki, razmer obyyekta i raspakovannyikh dannyikh, chislo nezavershyonnyikh grupp i perepolneniye arifmetiki. Chteniye potokovoye; JSON-zagolovok trebuyet UTF-8, odnoznachnyikh polej i podderzhivayemoj versii. Kontrolj celostnosti okhvatyivayet prefiks, zagolovok i binarnyiye bajtyi.
- Yedinstvennyij pisatelj posledovateljno dopisyivayet gruppu i yeyo zapisj fiksacii, sinkhroniziruyet fajl i lishj zatem podtverzhdayet sokhraneniye. Pri sozdanii segmenta otdeljno obespechivayetsya dolgovechnostj yego imeni. Indeksyi obnovlyayutsya posle podtverzhdeniya i polnostjyu vosstanavlivayutsya iz kontejnera.
- Vosstanovleniye sokhranyayet proverennyij podtverzhdyonnyij prefiks. Nezavershyonnyij khvost ne prinimayetsya avtomaticheski; povrezhdeniye vnutri prinyatogo prefiksa neljzya molcha pereskochitj poiskom sleduyusjhej signaturyi. Posle poteryannogo otveta proveryayetsya uzhe zapisannaya fiksaciya; ustojchivyij identifikator otlichayet povtor podachi ot novoj zapisi.
- Rotaciya sozdayot soglasovannyij nabor segmentov. Samodostatochnaya kopiya vklyuchayet vse neobkhodimyiye segmentyi i vstroyennyiye specifikacii. Pravila udaleniya podtverzhdyonnyikh dannyikh i szhatiya s poteryami ostayutsya otdeljnyim vyiborom poljzovatelya.

## Proverka pered obyyavleniyem gotovnosti

Drugoj process dolzhen vosstanovitj tochnyiye iskhodnyiye bajtyi, vklyuchaya vse znacheniya bajta, perevodyi strok i posledovateljnosti, pokhozhiye na zagolovok. Adresnyiye RED/GREEN-scenarii okhvatyivayut usecheniye na granicakh zapisi, otsutstvuyusjhiye ili perestavlennyiye fragmentyi, povrezhdeniye, prevyisheniye limitov, chastichnyij write, oshibki sinkhronizacii i povtor otkryitiya. Avariya processa, perezapusk OS i poterya pitaniya imeyut raznyiye granicyi dokazateljstva.

Dlya ispolneniya na Swift sokhranyayetsya obyazateljnaya posledovateljnostj TDD → profilj → resheniye ob optimizacii. Izmeryayutsya propusknaya sposobnostj, zaderzhka podtverzhdeniya, pamyatj i vosstanovleniye na melkikh sobyitiyakh i krupnyikh vlozheniyakh. Razmer fragmenta i rezhim paketnoj fiksacii vyibirayutsya po izmereniyu s sokhraneniyem prezhnikh garantij; chislennyij vyiigryish sejchas ne zayavlyayetsya.

## Izmeneniya susjhestvuyusjhego plana

V razdele dolgovremennogo khraneniya zamenitj vneshniye krupnyiye obyyektyi vstroyennyimi binarnyimi gruppami; skorrektirovatj opisaniye segmentov i rezervnoj kopii. Susjhestvuyusjhij ContentAddressedGenerationStore rassmatrivayetsya kak opora dlya publikacii segmentov, a ne gotovyij pisatelj novogo kontejnera. Razdel vosstanovleniya tekusjhego dialoga iz JSONL ostayotsya dejstvuyusjhim.

## Istochniki

- [Soobsjheniya 32–33](../../zapros.md) i [otvetyi tekusjhej zadachi](../../otchyot.md), izvlechyonnyiye iz yeyo fakticheskogo JSONL.
- Susjhestvuyusjhij plan nablyudeniya macOS v sobstvennoj kartochke zadachi.
- [Opisaniye JSON Lines](https://jsonlines.org/) — granica UTF-8, JSON-znacheniya v stroke i razdelitelya strok.
- [RFC 4648](https://www.rfc-editor.org/rfc/rfc4648.html#section-4) — rassmotrennoye, no ne vyibrannoye kodirovaniye binarnyikh dannyikh v tekstovom variante.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 13:49:48 MSK -->
<!-- content-sha256: sha256:fdf4ee8c5c4c7a938cd40965d7f6ced2ed16ead7ff17f7824fb2fd468f2864b8 -->
<!-- FUM-MD-RECENCY:END -->
