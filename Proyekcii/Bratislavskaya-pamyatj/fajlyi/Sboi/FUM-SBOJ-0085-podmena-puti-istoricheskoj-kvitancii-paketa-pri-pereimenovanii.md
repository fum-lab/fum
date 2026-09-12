+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0085"
"статус" = "активна"
+++
# Podmena puti istoricheskoj kvitancii paketa pri pereimenovanii

## Nablyudayemyij sboj

Shtatnoye pereimenovaniye zavershyonnoj kartochki STEP 0214 izmenilo istoricheskij klyuch puti v JSON-kvitancii primeneniya paketa diagnostiki. Znacheniye SHA-256 prezhnej aktivnoj kartochki ostalosj prezhnim, poetomu poluchivshayasya kvitanciya stala pripisyivatj istoricheskiye bajtyi novomu puti. Korenj obnaruzhil eto v tochnom diff i vosstanovil iskhodnuyu kvitanciyu iz zakreplyonnogo kommita do fiksacii tekusjhikh izmenenij.

## Granica povtoreniya

Kartochka okhvatyivayet perepisyivaniye puti v khyesh-svyazannoj istoricheskoj kvitancii konechnogo paketa diagnostiki pri shtatnom pereimenovanii STEP. Zhivyiye ssyilki v kartochkakh, navigacii i aktualjnom JSON dolzhnyi obnovlyatjsya otdeljno. SBOJ 0031 zasjhisjhayet tochnyij profilj sverki obyyavlenij i ne obyyavlyayet vse JSON neizmenyayemyimi. Neissledovannyiye proizvoljnyiye formatyi ne osvobozhdayutsya ot obnovleniya toljko iz-za pokhozhego imeni.

## Proyavleniya

- `FUM-СБОЙ-0085/ПРОЯВЛЕНИЕ-0001`: pri perevode STEP 0214 iz active v completed vyizov `rename-step-card.py` zavershilsya kodom 0 i izmenil vosemj vkhozhdenij v semi fajlakh. V [istoricheskoj kvitancii](../Zhurnal/2026-09-11_15-48-40_MSK_prinyatj-planirovaniye-Gosuslug/materialyi/svideteljstva/paket-rannej-sborki.json) izmenilsya klyuch puti aktivnoj kartochki na zavershyonnuyu pri neizmennom khyeshe `4e8dc1e638a5b346be512e80906bc3b1e5f97c0187bd03892ec187455e24b6b2`. Iskhodnyij kommit — `0219773d4a6c695739f8a2c53d4e5d4780632b0e`, SHA-256 kvitancii — `074c850dbf62c5fd5839ed3f3e44ca36831b681fb5d5a5e39b36db5389813a60`; izmenyonnyij SHA — `2ddc13a2c582ba9f2441a8e67379c2fd07e180303024a6877e2c5c86d7b09aa1`. Iskhodnyiye bajtyi vosstanovlenyi, chastnaya kopiya izmeneniya sokhranena. [Svideteljstvo vosstanovleniya](../Zhurnal/2026-09-11_16-55-35_MSK_utochnitj-operatornoye-vnimaniye-i-prodolzhitj-priyom/materialyi/svideteljstva/vosstanovleniye-kvitancii-0214.json) ne zamenyayet nablyudeniye tochnogo diff kornem.

## Ozhidaniye i klassifikaciya

Kvitanciya opisyivayet tochnyiye puti i bajtyi sovershyonnogo primeneniya. Pozdneye pereimenovaniye zhivoj kartochki ne dolzhno menyatj eto istoricheskoye utverzhdeniye. Nablyudeniye klassificiruyetsya kak nedorabotka raspoznavaniya konechnogo formata istoricheskogo svideteljstva. Povrezhdyonnaya kvitanciya ne byila prinyata ili opublikovana: vosstanovleniye vyipolneno do kommita `5934b08fefaffd5d002a1df0a422a33e47a83906`.

## Mekhanizm i sistemnoye ustraneniye

Podtverzhdyon effekt obsjhego pereimenovaniya strok puti vnutri JSON bez sokhraneniya granicyi dannoj istoricheskoj kvitancii. Trebuyetsya konechnoye raspoznavaniye yeyo obyyavlennogo kontrakta: sokhranyatj tochnyiye bajtyi raspoznannogo svideteljstva, otklonyatj povrezhdyonnyij raspoznannyij format do pervoj zapisi i prodolzhatj obnovleniye zhivyikh ssyilok. Vosstanovleniye tekusjhikh bajtov vyipolneno; sistemnyij mekhanizm poka ne izmenyon. Obsjheye isklyucheniye vsekh JSON i novaya migracionnaya sistema v etu meru ne vkhodyat.

## Svyazannyiye shagi

[STEP 0217](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0217-sokhranitj-istoricheskuyu-kvitanciyu-paketa-pri-pereimenovanii.md) sozdan iz `FUM-СБОЙ-0085/ПРОЯВЛЕНИЕ-0001` dlya konechnogo raspoznavaniya i regressionnoj proverki. On aktiven. Tekusjheye ogranichennoye vosstanovleniye ne schitayetsya ispolneniyem etogo shaga.

## Kriterii zakryitiya

Na vosproizvodimom pereimenovanii priznannaya istoricheskaya kvitanciya paketa i raneye zasjhisjhyonnyij profilj sokhranyayut iskhodnyiye bajtyi; zhivyiye JSON- i Markdown-ssyilki, kartochka i indeks obnovlyayutsya. Povrezhdyonnyij raspoznannyij format zakryivayet operaciyu do zapisi. Pokhozhiye puti i proizvoljnyiye JSON ne poluchayut neogranichennogo isklyucheniya. Svyazannyij shag predyyavlyayet RED/GREEN, profilj i primenimyij dopusk. Ruchnoye vosstanovleniye yedinstvennogo epizoda ne zakryivayet kartochku.

## Istochniki

- [Fiksaciya iskhodnogo nablyudeniya i vosstanovleniya](../Zhurnal/2026-09-11_16-19-17_MSK_podtverditj-zapusk-Gosuslug-i-prodolzhitj-priyom/otchyot.md).
- [Nastoyasjhij etap diagnostiki](../Zhurnal/2026-09-11_16-55-35_MSK_utochnitj-operatornoye-vnimaniye-i-prodolzhitj-priyom/zapros.md).
- [Kontrakt paketa diagnostiki](../Instrumentyi/fum-reyestr-planirovaniya/paket-diagnostiki.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 17:16:54 MSK -->
<!-- content-sha256: sha256:992354a95ff064580463255f47b1873a01ac3c4f6b49d450f82fe7241f471ef5 -->
<!-- FUM-MD-RECENCY:END -->
