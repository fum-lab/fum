# Otchyot 2026-09-15 19:20:02 MSK - Proveritj postavku istorii modeli

Zavershena predmetnaya dorabotka inkrementaljnoj istorii modeli i usiliya posle kornevogo obzora. Doslovnyiye citatyi sokhranyayutsya, fajl kommita privaten s momenta sozdaniya, nepolnaya para sokhranyayet dostupnyiye znacheniya. Postavka ogranichena proverennoj kontroljnoj tochkoj po pozdnemu utochneniyu kornya. Polnaya priyomka FUM i aktualjnaya obsjhaya proyekciya v feature-vetke ne vkhodyat v etu peredachu.

## Otvetyi na utochneniya kornya

1. Kolliziya markerov podtverzhdena RED. Obsjhij regex udalyon: generator ne udalyayet ni odnogo fragmenta tela. Tochnyij tekusjhij suffiks idempotenten; inoj konechnyij marker dayot otkaz s trebovaniyem iskhodnoj osnovyi. Poslednij kornevoj trejler sokhranyayetsya. GREEN podtverzhdayet sokhrannostj iskhodnoj citatyi.
2. Okno prav ustraneno cherez sozdaniye `O_EXCL` s 0600. Test nablyudayet rezhim otkryitogo deskriptora do pervoj zapisi pri `umask=0`, proveryayet tochnyij tekst i zapret perezapisi.
3. Nepolnyij `turn_context` sokhranyayet dostupnyiye modelj, usiliye i vremya v propuske; otsutstvuyusjheye ili nekorrektnoye — `unknown`. Takoj priyom ne stanovitsya polnyim nablyudeniyem i ne podgotavlivayet soobsjheniye kommita.
4. Nulevoye chteniye povtornogo istochnika yavno opirayetsya na sovpadeniye stat i realizacii v kooperativnoj lokaljnoj modeli. Nezavisimoye povtornoye dokazateljstvo bajtov pri takom puti ne zayavlyayetsya.
5. [Vosproizvodimaya sverka](materialyi/sveritj-istorii.py) podtverdila chetyire sobyitiya, vremya, pozicii i SHA: `gpt-6-astra/ultra` → `gpt-5.5/xhigh` → `gpt-6-astra/low` → `gpt-6-astra/ultra`. Staryij JSONL ne menyalsya: SHA `f80a7ec49d12590322397a8f0be0d0661aadd86aff3416305b64256e60211bba`. Boljshoj native JSONL dlya etoj sverki povtorno ne chitalsya.
6. Ukazaniye o nastoyasjhem kommite sliyaniya prinyato dlya posleduyusjhej kornevoj integracii. Eta zadacha sokhranyayet obyichnyiye kommityi sobstvennoj vetki; `fuma`, `master` i obsjheye pravilo sliyaniya ne menyayet. Polnyij delta peredayotsya ot iskhodnoj bazyi s sokhraneniyem roditeljstva.

## Profilj vremeni vyipolneniya

| Stadiya                         | Dliteljnostj | Granicyi i sposob izmereniya                         |
| ------------------------------ | ------------ | -------------------------------------------------- |
| Pervyij priyom 74970899 bajtov     | 0,844690 s   | Monotonnyij tajmer API, podgotovka isklyuchena          |
| Povtor s kursorom               | 0,000830 s   | Sovpadeniye stat, nolj prochitannyikh bajtov             |
| Povtor bez zapisi               | 0,000500 s   | Kursor toljko chitayetsya, nolj prochitannyikh bajtov      |
| Dorabotka i obzor               | ne izmereno  | Retrospektivnaya ocenka ne proizvoditsya              |

Granica profilya: tri posledovateljnyikh vyizova API otkryitogo scenariya; vlozhennyiye intervalyi vkhodyat v pryamoj zapusk profilya i povtorno ne summiruyutsya. Podgotovka, obsjhaya razrabotka i finaljnaya peredacha isklyuchenyi; vremya standartnogo dokumentacionnogo smoke-check uchityivayet mashinnaya zapisj nizhe.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                                            | Dliteljnostj | Rezuljtat         |
| -------------------------------------------------------------------------------- | ------------ | ----------------- |
| [Ispolnitelj istorii modeli] RED — sokhraneniye doslovnyikh markerov                 | 0,112 s      | neuspeshno         |
| [Ispolnitelj istorii modeli] GREEN — citatyi, privatnostj i skvoznoj CLI          | 0,377 s      | uspeshno           |
| [Ispolnitelj istorii modeli] Povtornyij profilj posle ispravlenij                 | 0,943 s      | uspeshno           |
| [Ispolnitelj istorii modeli] Sverka chetyiryokh prinyatyikh nablyudenij                  | 0,037 s      | uspeshno           |
| [Ispolnitelj istorii modeli] Standartnaya dokumentacionnaya priyomka istorii modeli | 381,152 s    | prervano — SIGINT |

Obsjheye vremya pryamyikh zapuskov proverok: 382,621 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki i resheniye ob optimizacii

Odinnadcatj adresnyikh scenariyev proshli: proiskhozhdeniye i deduplikaciya, inkrementaljnyij rost, povrezhdeniye/usecheniye/zamena, nepolnyij khvost, otsutstviye zapisi, granicyi putej, crash+append, podgotovka polej, sokhraneniye citatyi, prava do zapisi i skvoznoj CLI. RED citatyi predshestvuyet ispravleniyu. [Itogovyij profilj](materialyi/profilj-itogovoj-realizacii.json) soderzhit SHA iskhodnikov i tu zhe fiksturu, chto pervichnyij zamer. Dopolniteljnaya algoritmicheskaya optimizaciya ne obosnovana: povtornyij putj uzhe chitayet nolj bajtov istochnika. Raznica yedinichnyikh zamerov ne obyyavlyayetsya uskoreniyem.

## Suzheniye priyomki i nachatyij polnyij progon

Posle nachala standartnogo progona korenj yavno ogranichil blizhajshuyu peredachu kontroljnoj tochkoj. Povtornyij polnyij progon ne zapuskalsya. Uzhe nachatyij process proshyol strukturu, sborku i proverku reyestra, obratnyiye ssyilki i primeneniye proyekcii: 10199 fajlov, 344,867 s na primeneniye. V faze `новое_установлено` process ne preryivalsya; posle zaversheniya ustanovki i udaleniya kvitancii otchyotnoj obyortke peredan SIGINT vo vremya otdeljnoj nezavisimoj proverki. Itog obyortki — kod 130, preryivaniye sokhraneno mashinnoj zapisjyu. Nezavisimaya proverka ne zavershena; poluchennoye pokoleniye sokhranyayetsya kak nepriyomochnyij proizvodnyij snimok i posle registracii pozdnego utochneniya otstayot ot kanona. Novyij krug proyekcii ne vyipolnyayetsya.

Polnyij privatnyij stdout imeyet 3424 bajta, SHA `8a63e51328037f0a4131c7916ee947bd40e4ba66bd11d83b1d7c94432e4c300a`; stderr pust. Aktivnyikh processov progona ne ostalosj. Posleduyusjhaya kontroljnaya svyaznostj ne trebuyet obyyavlyatj etot progon uspeshnyim.

## Oblastj postavki i ogranicheniya

Toljko moduli, testyi i rukovodstvo svyaznosti, dve sobstvennyiye paryi Zhurnala, neobkhodimaya navigaciya i proizvodnaya proyekciya. Prilozheniya/FUMA/macOS, fum-reyestr-planirovaniya, pravila i konfiguraciya Codex ne menyayutsya. Istorii predyidusjhikh nablyudenij ostayutsya neizmennyimi. Sozdaniye kartochki kornevogo sboya vne ogranichennoj oblasti peredano kornyu s iskhodnyim zamechaniyem i RED/GREEN.

[Interfejs i vosproizvedeniye](../../Instrumentyi/fum-svyaznostj-rabochej-sessii/istoriya-modeli.md) opisyivayut yavnyij zapusk i podgotovku soobsjheniya. Avtozapusk otsutstvuyet. Polnyij kornevoj ostatok ne yavlyayetsya obyyomom etoj zadachi; prinyatiye i integraciya vetki v `fuma` otnosyatsya k kornyu. Kontroljnaya tochka `5398b7a7d0d2beedc6b827b99bdc1f30fe24cf08` opublikovana, udalyonnyij OID proveren. Finaljnyiye OID, derevo i roditeli soobsjhayutsya posle fiksacii. Neprinyatyij ostatok: nezavisimaya obsjhaya proverka i finaljnaya proyekciya, smyislovaya priyomka kornem i merge-kommit v `fuma`; oni ne obyyavlenyi vyipolnennyimi etoj zadachej.

## Istochniki

- [Porucheniye i pozdniye utochneniya](zapros.md).
- [Pervyij etap](../2026-09-15_19-05-01_MSK_sokhranyatj-nablyudayemuyu-istoriyu-modeli/otchyot.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 19:34:25 MSK -->
<!-- content-sha256: sha256:c24c0bc8889773b48cbba20b173935dce53e4c19d9032c638da42bbb2f946702 -->
<!-- FUM-MD-RECENCY:END -->
