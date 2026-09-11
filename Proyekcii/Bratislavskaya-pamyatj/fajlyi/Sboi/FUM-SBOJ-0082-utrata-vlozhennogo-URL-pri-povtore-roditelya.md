+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0082"
"статус" = "устранена"
+++
# Utrata vlozhennogo URL pri povtore roditeljskogo snimka

## Nablyudayemyij sboj

Povtor snimka stranicyi Astra zamenil katalog roditelya celikom i udalil samostoyateljnyij vlozhennyij URL. Zatronut toljko novyij neopublikovannyij istochnik etoj zadachi; raneye otslezhivayemyiye materialyi ne izmenyalisj. Sinteticheskij test povtoril utratu.

## Granica povtoreniya

Samostoyateljnyij dochernij URL s sobstvennyim istochnikom i manifestom ne prinadlezhit soderzhimomu roditeljskogo otveta. Yego kopirovaniye i proverka dolzhnyi predshestvovatj yedinstvennomu atomarnomu obmenu. Ischeznuvshij marker rebyonka obyazan davatj otkaz, a ne razreshatj udaleniye.

## Proyavleniya

| Lokaljnyij nomer | Istochnik i dokazateljstvo | Effekt | Vosstanovleniye |
| --- | --- | --- | --- |
| `FUM-СБОЙ-0082/ПРОЯВЛЕНИЕ-0001` | [Otchyot reyestra podderzhki](../Zhurnal/2026-09-11_14-52-06_MSK_sozdatj-reyestr-organizacij-podderzhki-FUM/otchyot.md) i otdeljnyiye mashinnyiye zapisi RED/GREEN. | Narushena trebuyemaya sokhrannostj istochnika do kommita. | Inventarj otdelyayet vlozhennyiye snimki; susjhestvuyusjhij roditelj vsegda proveryayetsya. Vlozhennyiye snimki validiruyutsya i kopiruyutsya v staging, konflikt ili povrezhdeniye zakryivayet zamenu otkazom. Zatem vyipolnyayetsya odin obmen direktorij. Sobstvennyij istochnik vosstanovlen novoj zagruzkoj. |

## Ozhidaniye i klassifikaciya

Podtverzhdyonnaya nedorabotka susjhestvuyusjhego istochnikovogo mekhanizma; gipoteticheskiye i ne nablyudavshiyesya polya ne obyyavlyayutsya ochisjhennyimi.

## Mekhanizm i sistemnoye ustraneniye

Inventarj otdelyayet vlozhennyiye snimki; susjhestvuyusjhij roditelj vsegda proveryayetsya. Vlozhennyiye snimki validiruyutsya i kopiruyutsya v staging, konflikt ili povrezhdeniye zakryivayet zamenu otkazom. Zatem vyipolnyayetsya odin obmen direktorij. Sobstvennyij istochnik vosstanovlen novoj zagruzkoj.

## Svyazannyiye shagi

[FUM-STEP-0212](../Planirovaniye/kartochki-shagov/✅-FUM-STEP-0212-avtomatizirovatj-reyestr-organizacij-podderzhki-FUM.md) aktualizirovan dannyim proyavleniyem: ispravleniye trebuyetsya dlya proverennogo vyipuska pervogo reyestra. Novyij otdeljnyij shag ne sozdayotsya.

## Kriterii zakryitiya

- Povtor roditelya sokhranyayet tochnyiye bajtyi rebyonka; nezavisimyiye manifestyi validnyi. Udaleniye manifesta rebyonka dayot otkaz bez izmeneniya tekusjhego dereva. Atomarnyij obmen i prezhniye otkaznyiye regressii sokhranenyi.
- Sobstvennaya regressiya meryi prokhodit vmeste s susjhestvuyusjhimi testami arkhivatora; smyislovyiye i licenzionnyiye ogranicheniya istochnikov sokhranyayutsya.

## Istochniki

- [Komanda, utochneniya i soglasovaniye ID](../Zhurnal/2026-09-11_14-52-06_MSK_sozdatj-reyestr-organizacij-podderzhki-FUM/zapros.md).
- [Obsjhij arkhivator](../Instrumentyi/fum-materialyi-zaprosov/scripts/source_archive.py).
- [Otkryityiye regressii](../Instrumentyi/fum-materialyi-zaprosov/tests/test_ochistka_istochnikov_podderzhki.py).

## Podtverzhdeniye ustraneniya

[Povtor 55 testov arkhivatora](../Zhurnal/2026-09-11_16-12-17_MSK_zavershitj-priyomku-reyestra-podderzhki-FUM/materialyi/zapuski-proverok/3_17734d3d-691c-4d76-85d3-59018cacf97d.json) zavershilsya kodom 0 posle sokhranyonnyikh sinteticheskikh RED i ispravlenij. Proverenyi tochnyiye nablyudavshiyesya polya, sokhrannostj publichnogo soderzhimogo, otkaz PDF, raspakovka gzip i sokhrannostj vlozhennogo snimka. Shirokaya priyomka pervogo reyestra otnositsya k STEP-0212; kartochka podtverzhdayet sobstvennuyu vosproizvedyonnuyu granicu.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 16:22:35 MSK -->
<!-- content-sha256: sha256:6dc391cd1e8d95e82475df80dc6cd29046e250eeb44a1780c8db03cf027043ba -->
<!-- FUM-MD-RECENCY:END -->
