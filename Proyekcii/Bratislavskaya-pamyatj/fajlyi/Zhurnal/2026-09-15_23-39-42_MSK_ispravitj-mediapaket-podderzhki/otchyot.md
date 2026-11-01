# Otchyot 2026-09-15 23:39:42 MSK - Ispravitj mediapaket podderzhki

Ispravlena postavka mediapaketa posle otkloneniya b2df928. Finansovyiye znacheniya prinimayutsya toljko pri yavnom istochnike, sovpadayusjhem s Git-rezuljtatom; neizvestnyiye ostayutsya neizvestnyimi. Format perioda i poluchatelya boljshe ne obrabatyivayet ikh kak denjgi, CLI otvergayet povtornyiye JSON-klyuchi i tree-OID.

## Profilj vremeni vyipolneniya

| Stadiya                   | Dliteljnostj | Granicyi i sposob izmereniya                           |
| ------------------------ | ------------ | ---------------------------------------------------- |
| Ozhidaniye dopuska FIFO    | ne izmereno  | Zapolnitj nablyudayemyimi nachalom i koncom ozhidaniya     |
| Soderzhateljnaya rabota    | ne izmereno  | Zapolnitj granicami realizacii i analiza             |
| Celevyiye proverki         | ne izmereno  | Zapolnitj granicami adresnyikh proverok                |
| Polnyij smoke-check       | ne izmereno  | Zapolnitj dliteljnostjyu polnogo proverochnogo kontura |
| Atomarnyij commit+handoff | ne izmereno  | Zapolnitj posle podtverzhdyonnoj peredachi FIFO         |

Granica profilya: zapolnitj nachalo i konec okhvachennogo intervala, vklyucheniye ozhidaniya i finaljnoj peredachi.

### Pryamyiye zapuski proverok

<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; каталог=материалы/запуски-проверок -->

| Vyizov                                       | Dliteljnostj | Rezuljtat |
| ------------------------------------------- | ------------ | --------- |
| [Luna] Vosproizvesti otkloneniye mediapaketa | 1,64 s       | uspeshno   |
| [Luna] GREEN kontrakt mediapaketa Luna high | 1,811 s      | uspeshno   |
| [Luna] Profilj generatora mediapaketa       | 0,66 s       | uspeshno   |

Obsjheye vremya pryamyikh zapuskov proverok: 4,111 s.

Ekonomnyij poryadok proverok: ne gotov.

<!-- FUM-CHECK-RUNS:END -->

## Proverki

GREEN cherez obyortku: 8 testov, kod 0. Profilj: 10 povtorov za 0,6232813329843339 s. Lokaljnyij paket sozdan iz sokhranyonnogo finansovogo marshruta; publikacii i platezhi otsutstvuyut.

## Resheniya i ogranicheniya

Staraya vetka Luna low sokhranena kak refs/heads/codex/sravneniye-luna-low-b2df9280 na b2df928066fa84d3bf7ab8100baf519e934e4233; remote OID podtverzhdyon. Ispravleniya prodolzhayutsya otdeljno na tekusjhej vetke, bez amend/rebase. Modelj etogo etapa gpt-5.6-luna/high; vneshnij zapusk ne vyipolnyalsya.

## Istochniki

- [iskhodnyij zapros](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:42:24 MSK -->
<!-- content-sha256: sha256:c2f79514f5a716a969618ecb54a9595ee33363176b4448474fad5f7771bba5d2 -->
<!-- FUM-MD-RECENCY:END -->
