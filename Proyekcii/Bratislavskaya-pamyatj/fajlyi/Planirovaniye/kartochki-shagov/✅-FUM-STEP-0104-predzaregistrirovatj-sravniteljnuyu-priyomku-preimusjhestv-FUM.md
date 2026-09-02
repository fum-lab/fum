+++
schema_version = 1
card_id = "FUM-STEP-0104"
status = "completed"
+++
# Predzaregistrirovatj sravniteljnuyu priyomku preimusjhestv FUM

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Zapolnitj kartochku eksperimenta FUM s predvariteljno zafiksirovannyim sravneniyem obyichnogo agentskogo cikla, kontrolya s tochkami vosstanovleniya, odnoagentnogo FUM, FUM s otdeljnyim proveryayusjhim i FUM s neskoljkimi razlichimyimi poduzlami. Ne zapuskatj setevoj, platnyij ili izmenyayusjhij chuzhiye repozitorii progon: rezuljtatom shaga yavlyayetsya vosproizvodimyij protokol budusjhej priyomki.

## Rezuljtat

Sozdana [predregistraciya sravniteljnoj eksperimentaljnoj priyomki](../kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md) versii `1`. Shestj sosednikh variantov dobavlyayut po odnomu vozdejstviyu: mekhanicheskij checkpoint, proveryayemuyu pamyatj, kontekstno ogranichennyij rabochij paket, otdeljnogo proveryayusjhego i neskoljko razlichimyikh proizvoditelej. Tak obyazateljnyij odnoagentnyij FUM sravnivayetsya s obyichnyim ciklom, a effektyi pamyati i rabochikh paketov ne smeshivayutsya.

Do izmerenij zakreplenyi odin vneshnij kriterij, odinakovyiye agregatnyiye ogranicheniya modeli, runtime, instrumentov i byudzheta, `50` osnovnyikh zadach pyati sloyov, po tri povtora kazhdogo varianta, blochnaya randomizaciya, zapret rannego analiza, politika infrastrukturnogo povtora i ostanovka pri utechke ili utrate polnomochij. Operacionnyiye metriki vklyuchayut uspekh, lozhnoye zaversheniye, vosstanovleniye, sokhrannostj podtverzhdyonnogo, vmeshateljstva cheloveka, tokenyi, denjgi, vremya, dublirovaniye, konfliktyi i regressii.

Izmeryayemyiye, setevyiye i platnyiye progonyi ne vyipolnyalisj. Task-manifest, evaluator, provider, oplata, izmeneniye vneshnego sostoyaniya i publikaciya rezuljtatov trebuyut otdeljnogo yavnogo razresheniya; zapolnennaya kartochka ostayotsya gipotezoj so statusom `не проверено`.

## Istochniki

- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-02_23-09-10_MSK_predzaregistrirovatj-sravniteljnuyu-priyomku-preimusjhestv-FUM/zapros.md)
- [predregistraciya sravniteljnoj eksperimentaljnoj priyomki](../kartochka-eksperimenta-sravniteljnoj-priyomki-preimusjhestv-FUM.md)
- [trebovaniye o sravniteljnoj eksperimentaljnoj priyomke](../../Trebovaniya/🟡-sravniteljnaya-eksperimentaljnaya-priyomka-preimusjhestv-FUM.md)
- [shablon kartochki eksperimenta FUM](../shablon-kartochki-eksperimenta-FUM.md)
- [FUM-STEP-0112 — skvoznoj odnoagentnyij epizod](✅-FUM-STEP-0112-zamknutj-vozobnovleniye-i-zhivuyu-priyomku-odnoagentnogo-epizoda.md)
- [FUM-STEP-0083 — vozobnovleniye raspredelyonnogo progona](✅-FUM-STEP-0083-vozobnovitj-raspredelyonnyij-progon-iz-pamyati-bez-skryitogo-konteksta.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:1b4db1e45c806d11adeaacb142a34232b824918c2bedeaf3fe34f1f539cc79fb -->
<!-- FUM-MD-RECENCY:END -->
