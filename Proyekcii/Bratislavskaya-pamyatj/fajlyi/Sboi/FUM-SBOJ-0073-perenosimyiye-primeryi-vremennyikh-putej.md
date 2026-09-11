+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0073"
"статус" = "устранена"
+++
# Absolyutnyiye vremennyiye puti v primerakh sravneniya

Ustraneniye ogranicheno yavno proverennyim konturom sravneniya dekodirovaniya. Nomer vyidelen koordinatorom posle sverki integracionnogo dereva i rezervov, chto sokhraneno v [iskhodnom zaprose](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/zapros.md).

## Nablyudayemyij sboj

Novyij dokument sravneniya soderzhal pyatj strok komand s absolyutnyim primerom vremennogo kataloga. Dejstvuyusjhij skaner otklonil ikh do zapuska dorogoj proyekcii; sekretnyiye poljzovateljskiye puti ne publikovalisj.

## Granica povtoreniya

Tochnyij dokument sravneniya UTF-8 i yego komandyi vremennoj sborki i vyivoda. Obobsjheniye na proizvoljnyiye dokumentyi i izmeneniye politiki skanera ne zayavlyayutsya.

## Proyavleniya

| Lokaljnyij nomer                 | Istochnik i dokazateljstvo                                                                         | Effekt                                                | Vosstanovleniye                 |
| ------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------ |
| `FUM-СБОЙ-0073/ПРОЯВЛЕНИЕ-0001` | [Otchyot i pryamyiye zapuski](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/otchyot.md) | Finaljnaya priyomka otlozhena do adresnogo podtverzhdeniya | Ogranichennaya mera i GREEN nizhe |

## Mekhanizm i ogranichennoye vosstanovleniye

Lokaljnyij primer absolyutnogo kataloga byil oshibochno prinyat za perenosimuyu komandu. Primeryi teperj ispoljzuyut sistemnyij TMPDIR s obyazateljnoj proverkoj nepustogo znacheniya obolochkoj; poljzovateljskaya konfiguraciya i politika ne menyalisj.

## Kriterii zakryitiya

Skaner s neizmenyonnoj politikoj prinimayet itogovyiye primeryi; komandyi po-prezhnemu peredayut katalog sborki vne checkout. Otkaz voznikayet do tyazhyoloj priyomki.

## Podtverzhdeniye ustraneniya

Zapuski № 12 i № 13 vernuli kod 1, s pyatjyu error.posix-absolute v rukovodstve; № 14 posle ispravleniya vernul kod 0. Iskhodnyij stend i raw ne menyalisj. Finaljnaya priyomka postavki ostayotsya otdeljnoj granicej i etim lokaljnyim statusom ne podmenyayetsya.

## Istochniki

- [Komanda i utochneniya](../Zhurnal/2026-09-11_12-00-09_MSK_sravnitj-dekodirovaniye-UTF-8/zapros.md).
- [Rukovodstvo sravneniya](../Prototipyi/pamyatj-strukturiruyusjhikh-operatorov/sravneniye-dekodirovaniya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 12:43:19 MSK -->
<!-- content-sha256: sha256:bd11d933748010ad2375afa9fe787e2c9e5c2b4cea8787908bebcc3fc22ec4fe -->
<!-- FUM-MD-RECENCY:END -->
