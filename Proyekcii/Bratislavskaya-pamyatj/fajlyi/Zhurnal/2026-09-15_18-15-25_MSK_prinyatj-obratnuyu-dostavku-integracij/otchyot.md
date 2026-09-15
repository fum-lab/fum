# Otchyot 2026-09-15 18:15:25 MSK - Prinyatj obratnuyu dostavku integracij

V fuma prinyat ogranichennyij srez obratnoj dostavki 2f55f909d5d73fbca17b93497b587090414f0ed7. Vse 44 kornevyiye regressii proshli za 128,298 s unittest; polnaya dliteljnostj pryamogo vyizova sokhranena nizhe. Novyikh latinskikh obyyavlenij ne obnaruzheno. Ispolnyayemyiye iskhodniki i rezhimyi sokhranenyi bez pravok; nezavisimyij obzor ne obnaruzhil blokiruyusjhikh defektov. Gotovnostj vsego FUM i vklyucheniye v master ne zayavlyayutsya.

## Profilj vremeni vyipolneniya

| Stadiya | Dliteljnostj | Granicyi i sposob izmereniya |
| --- | --- | --- |
| Chteniye i perenos | ne izmereno | Polnyiye Git OID i pobajtovoye sravneniye |
| Adresnyiye regressii | v tablice nizhe | Shtatnyij uchyot pryamogo zapuska |
| Profilj ispolnitelya | 1,513 s + 0,758 s | Medianyi tryokh nezavisimyikh otkryityikh fikstur: proverka s otchyotom i podgotovka so sverkoj indeksa; vremya kornya ne vklyuchayet eti intervalyi |

Granica profilya: adresnaya priyomka sreza; nezavisimyiye intervalyi ispolnitelya ne summiruyutsya so vremenem kornya.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                                  | Dliteljnostj | Rezuljtat |
| ------------------------------------------------------ | ------------ | --------- |
| [korenj] Regressii obratnoj dostavki i shtatnogo otchyota | 141,962 s    | uspeshno   |
| [korenj] Russkiye obyyavleniya prinyatogo sreza dostavki   | 0,11 s       | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 142,072 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Resheniya i ogranicheniya

Dostavka prinimayet toljko uzkuyu sluzhebnuyu raznicu odnoj zaraneye naznachennoj proverki: prezhniye zapisi, zapros i vsyo vne upravlyayemogo bloka neizmennyi. Indeks podtverzhdayetsya vladeljcem otdeljno. Proverenyi proiskhozhdeniye sreza i neizmennostj tryokh pryamyikh zavisimostej; polnyij ispolnyayemyij kontur master etim ne prinimayetsya.

Poluchateli mekhanizma poka ogranichenyi codex-vetkami. Dopusk postoyannoj fuma i svoyevremennostj dostavki ostayutsya otdeljnoj realizaciyej FUM-STEP-0228. Kod ne aktiviruyet zadachi nativno i ne zavershayet avtomaticheski polnyij smoke libo zakryitiye otchyota.

## Svideteljstva priyomki

[Profilj](materialyi/profilj-otchyotnogo-cikla.json) peredan iz tochnogo itogovogo kommita; devyatj SHA iskhodnikov i pryamyikh zavisimostej sovpali s prinimayemyimi fajlami. Sozdaniye repozitoriyev, plan i merge isklyuchenyi; kyesh OS tyoplyij, proverka pechatayet stroku cherez nastoyasjhuyu obyortku. Setj, polnyij FUM i svoyevremennostj dostavki ne izmerenyi. Eto profilj stoimosti, ne dokazateljstvo uskoreniya vsego cikla.

Nezavisimyij obzor podtverdil uzkuyu proverku zapisej i indeksa, migraciyu kvitancii v1 → v2 i rekursivnuyu zasjhitu skryityikh flagov zavisimostej. V modeli ostayotsya yedinstvennyij doverennyij pisatelj; vrazhdebnaya podmena privatnogo kataloga ne zasjhisjhayetsya etimi SHA.

## Utochneniye poljzovatelya

Da: korenj pishet tekusjhuyu fuma po yeyo dejstvuyusjhim pravilam. Podgotovka i priyomka dlya master podchinyayetsya iskhodnomu master. Eta kontroljnaya tochka ne vyidayotsya za priyomku master.

## Promezhutochnyij otkaz

Pervyij vspomogateljnyij perenos otklonyon do zapisi novyikh iskhodnikov: Git vyivel kirillicheskiye puti s C-ekranirovaniyem, a pomosjhnik schital ikh bukvaljnyimi imenami. Spisok prochitan povtorno v NUL-formate; vse Git-obyyektyi i usloviya zatem proverenyi do zapisi. Kod prinimayemogo instrumenta ne zatronut etoj oshibkoj.

## Istochniki

- [Iskhodnyiye komandyi i obyyom](zapros.md).
- [Sostav sreza](materialyi/sostav-sreza.json).
- [Iskhodnaya postavka](https://github.com/fum-lab/fum/commit/2f55f909d5d73fbca17b93497b587090414f0ed7).

Utochneniye o pravilakh sokhraneno iz kornevogo JSONL: `[781023700, 781024154)`, SHA-256 `ba2c0c9546bee195e53ddef7af129760ff3ec4083b9fb234558bca11a0786ad0`.

Poljzovatelj podtverdil vyibrannyij poryadok. Otvet kornya: prodolzheniye priyomki sreza v fuma; shtatnyiye regressii vyipolnyayutsya. Podtverzhdeniye iz JSONL: `[781159407, 781159811)`, SHA-256 `84e0337c2db6b3b84c0e7c4b0ccde45abee0de5161761c0d3177622a3b852d6c`.

## Proverka HEAD postoyannoj vetki

Na vopros poljzovatelya vyipolnena adresnaya sverka: v naznachennom fizicheskom dereve HEAD, refs/heads/fuma i lokaljnoye nablyudeniye origin/fuma sovpali na `ced9c03e8a65088864ac7ca91aacebb0e840c705`. Najden drugoj raneye susjhestvovavshij katalog s imenem fuma, no yego HEAD otsoyedinyon na `a16976d8a5dcac2710340f752134b595e1de1331`. On ne yavlyayetsya tekusjhim vladeljcem ref. Imya papki ne zamenyayet fakticheskuyu svyazku fizicheskogo kornya i symbolic ref. Eto obyyasnyayet vozmozhnoye raskhozhdeniye nablyudeniya poljzovatelya; tochnyij prosmatrivavshijsya im putj ne ustanovlen. Chuzhoye otsoyedinyonnoye derevo ne izmenyalosj.

Istochnik voprosa v JSONL: `[781480124, 781480574)`, SHA-256 `e593e2fd05356c4e334dc218163bc5412b4ecf48138d662a1497bb3732a882fa`.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 18:25:23 MSK -->
<!-- content-sha256: sha256:41c050d8a4c4b5ea136f2a2a157e0bde89537fa835613ead43941b0d2bcd670a -->
<!-- FUM-MD-RECENCY:END -->
