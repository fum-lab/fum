# Otchyot 2026-06-25 19:18:28 MSK

## Glavnoye

V pravilakh [pamyati FUM](../../Glossarij/pamyatj-FUM.md) utochneno, chto voprosyi, utochneniya i proverki tekusjhej praktiki tozhe stanovyatsya [iskhodnyimi zaprosami](../../Glossarij/iskhodnyij-zapros.md), yesli iz nikh sleduyet resheniye o pravilakh vedeniya pamyati, khranenii istochnikov, sostave artefaktov ili poryadke [rabochej sessii](../../Glossarij/rabochaya-sessiya.md).

## Chto izmenilosj

- V [AGENTS.md](../../AGENTS.md) dobavleno pravilo dlya meta-zaprosov o praktike vedeniya repozitoriya.
- Utochneno, chto tekst takogo zaprosa sokhranyayetsya v `Запросы/` dazhe togda, kogda proizvodnaya pravka ogranichivayetsya `AGENTS.md`, zhurnalom ili sluzhebnyim poyasneniyem.
- Otdeljno razvedenyi sam tekst zaprosa i soprovozhdayusjhij skrinshot, appshot-kontekst ili drugoj [prikreplyayemyij material](../../Glossarij/prikreplyayemyij-material.md): tekst sokhranyayetsya v `Запросы/`, a material klassificiruyetsya po pravilam `Источники/`.

## Resheniya

Utochnyayusjhiye voprosyi o tom, kak imenno dolzhna rabotatj [pamyatj FUM](../../Glossarij/pamyatj-FUM.md), boljshe ne ostayutsya toljko v dialoge agenta. Yesli otvet na takoj vopros fiksiruyet ili menyayet pravilo, zapros prokhodit obyichnuyu cepochku rabochej sessii: fajl v `Запросы/`, zhurnal, spisok zatronutyikh fajlov, proverka i kommit.

Skrinshot ili appshot-kontekst ne zamenyayet fajl zaprosa. Yego nuzhno rassmatrivatj kak otdeljnyij material: sokhranyatj v `Источники/`, yesli on yavlyayetsya znachimyim istochnikom trebovaniya, proverki ili sostoyaniya interfejsa, i ne sokhranyatj, yesli on byil toljko vspomogateljnyim kontekstom bez samostoyateljnoj istochnikovoj cennosti.

## Proverki

- `git diff --check` - proshlo bez zamechanij.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-25_19-18-28_MSK.md` - proshlo.

## Vozmozhnyiye prodolzheniya

Otdeljnyim sleduyusjhim shagom mozhno rasshiritj avtomatizirovannuyu proverku rabochej sessii tak, chtobyi ona pomogala obnaruzhivatj meta-zaprosyi o pravilakh pamyati, kotoryiye dolzhnyi byitj zavedenyi v `Запросы/`.

## Istochniki

- [iskhodnyij zapros 2026-06-25 19:18:28 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:0de8cd9ce0ada0a69a7083ec43840d157704f1c60e9580f1c56756ce9b965596 -->
<!-- FUM-MD-RECENCY:END -->
