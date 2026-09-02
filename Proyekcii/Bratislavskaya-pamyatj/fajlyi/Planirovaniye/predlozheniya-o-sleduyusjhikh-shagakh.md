# Predlozheniya o sleduyusjhikh shagakh FUM

Predlozheniya o prakticheskikh prodolzheniyakh khranyatsya ne strokami obsjhej tablicyi, a otdeljnyimi [kartochkami shagov](kartochki-shagov/README.md). Takoye predstavleniye sokhranyayet ustojchivuyu identichnostj kazhdogo kandidata, yego zadachu, obosnovaniye, kriterii ili rezuljtat i istochniki nezavisimo ot poryadka v obsjhem pule.

Ekspluatacionnyij status: aktualjnyij pul ostayotsya navigacionnyim perechnem vozmozhnostej. On ne yavlyayetsya avtomaticheskoj ocheredjyu, a sleduyusjhij soderzhateljnyij zapros i pishusjhuyu sessiyu vruchnuyu vyibirayet i zapuskayet poljzovatelj.

Etot putj sokhranyon kak kompaktnaya vkhodnaya i perekhodnaya stranica, chtobyi istoricheskiye ssyilki prodolzhali vesti k smyislu planovogo sloya. Kanonicheskij polnyij indeks i zhiznennyij cikl nakhodyatsya v `Планирование/карточки-шагов/`; mashinnyij [planovyij reyestr](reyestr-trebovanij-variantov-i-kandidatov.json) stroitsya iz samikh kartochek.

## Aktualjnyij pul

V [indekse kartochek](kartochki-shagov/README.md) nakhodyatsya `22` aktualjnyikh kandidata i `49` istoricheskikh kartochek. Aktualjnaya kartochka ne obesjhayet realizaciyu i ne stanovitsya trebovaniyem bez obyichnoj cepochki proiskhozhdeniya: [iskhodnyij zapros](../Glossarij/iskhodnyij-zapros.md) -> [proizvodnaya dokumentaciya](../Glossarij/proizvodnaya-dokumentaciya.md) -> proverka -> kommit.

Odin kandidat stanovitsya ispolnyayemyim prodolzheniyem toljko cherez otdeljnyij [sleduyusjhij shag vetki](../Glossarij/sleduyusjhij-shag-vetki.md). Vetochnyij selektor zakreplyayet `card_id` i khyesh kartochki, no ne kopiruyet yeyo zadachu i kriterii.

## Svyazannyiye otkryityiye voprosyi

Perekhodnaya stranica sokhranyayet dvunapravlennyiye svyazi prezhnego obsjhego spiska s otkryityimi voprosami; konkretnyiye planovyiye prodolzheniya teperj nakhodyatsya v kartochkakh:

- [abstrakciya urovnej nablyudayemoj Vselennoj FUM](../Voprosyi/2026-06-26_12-19-03_MSK_abstrakciya-urovnej-nablyudayemoj-vselennoj-FUM.md) svyazana s [FUM-STEP-0022](kartochki-shagov/🟡-FUM-STEP-0022-opisatj-minimaljnyij-pasport-obsjhej-skhemyi-FUM.md);
- [razvilka giperseti i agentskogo cikla FUM](../Voprosyi/2026-07-03_15-36-48_MSK_razvilka-giperseti-i-agentskogo-cikla-FUM.md) svyazana s [FUM-STEP-0005](kartochki-shagov/✅-FUM-STEP-0005-proveritj-kontrakt-chistogo-modeljnogo-shaga-dlya-ispolnyayemogo-agentskogo-cikla.md).

## Istoriya migracii

Prezhniye `35` strok razdela aktualjnyikh predlozhenij preobrazovanyi v `FUM-STEP-0001...FUM-STEP-0035`; `33` vyipolnennyikh i odna poglosjhyonnaya stroka istorii — v `FUM-STEP-0036...FUM-STEP-0069`. Iskhodnyiye formulirovki, obosnovaniya ili rezuljtatyi i opornyiye ssyilki perenesenyi v kartochki. Pozicionnyiye identifikatoryi prezhnego mashinnogo reyestra boljshe ne zadayut identichnostj shaga.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-23 11:33:38 MSK — Vernutj ruchnuyu posledovateljnuyu skhemu sessij](../Zhurnal/2026-08-23_11-33-38_MSK_vernutj-ruchnuyu-posledovateljnuyu-skhemu-sessij/zapros.md)
- [iskhodnyij zapros 2026-07-24 05:27:17 MSK - Perevesti graf zavisimostej korobochnoj realizacii v mashinnyij sloj](../Zhurnal/2026-07-24_05-27-17_MSK_perevesti-graf-zavisimostej-korobochnoj-realizacii-v-mashinnyij-sloj/zapros.md)
- [iskhodnyij zapros 2026-07-23 19:08:00 MSK - Proveritj minimaljnyij Swift-prototip iyerarkhii funkcij i dannyikh FUM](../Zhurnal/2026-07-23_19-08-00_MSK_proveritj-minimaljnyij-Swift-prototip-iyerarkhii-funkcij-i-dannyikh-FUM/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:07:48 MSK - Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../Zhurnal/2026-07-22_13-07-48_MSK_sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [iskhodnyij zapros 2026-07-22 12:35:05 MSK - Provesti audit absolyutnyikh putej](../Zhurnal/2026-07-22_12-35-05_MSK_provesti-audit-absolyutnyikh-putej/zapros.md)
- [iskhodnyij zapros 2026-07-22 10:02:43 MSK - Dobavitj audit pokryitiya voprosov i otvetov](../Zhurnal/2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/zapros.md)
- [iskhodnyij zapros 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij](../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-22 04:10:40 MSK - Dobavitj inicializaciyu zaregistrirovannyikh Git submodule](../Zhurnal/2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/zapros.md)
- [iskhodnyij zapros 2026-07-22 02:59:22 MSK - Dekompozirovatj predlozheniya na kartochki shagov](../Zhurnal/2026-07-22_02-59-22_MSK_dekompozirovatj-predlozheniya-na-kartochki-shagov/zapros.md)
- [iskhodnyij zapros 2026-07-03 11:49:25 MSK - Zafiksirovatj poshagovyij otbor realizacii](../Zhurnal/2026-07-03_11-49-25_MSK_zafiksirovatj-poshagovyij-otbor-realizacii/zapros.md)
- [iskhodnyij zapros 2026-07-20 20:06:04 MSK - Zapuskatj sleduyusjhiye shagi vetok](../Zhurnal/2026-07-20_20-06-04_MSK_zapuskatj-sleduyusjhiye-shagi-vetok/zapros.md)
- [iskhodnyij zapros 2026-07-20 21:22:17 MSK - Vklyuchitj kartochki trebovanij v mashinnyij planovyij reyestr](../Zhurnal/2026-07-20_21-22-17_MSK_vklyuchitj-kartochki-trebovanij-v-mashinnyij-planovyij-reyestr/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 09:37:36 MSK -->
<!-- content-sha256: sha256:d339c9989951053c184dd9f8a29c2ae714033873e5a68ffe6871cc728a6a858a -->
<!-- FUM-MD-RECENCY:END -->
