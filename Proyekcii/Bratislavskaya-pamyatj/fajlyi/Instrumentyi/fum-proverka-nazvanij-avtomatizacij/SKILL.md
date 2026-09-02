---
name: fum-proverka-nazvanij-avtomatizacij
description: Proveryatj russkiye latinskiye nazvaniya avtomatizacij FUM po zakreplyonnoj tablice LinguisticKit.
---

# Proverka nazvanij avtomatizacij

Kanonicheskoye russkoye imya etoj lokaljnoj avtomatizacii FUM — `проверка названий автоматизаций`. Ona sveryayet russkoye imya na kirillice, tochnyij rezuljtat preobrazovaniya LinguisticKit i tekhnicheskij slug. Kirillicheskoye imya ostayotsya smyislovyim istochnikom, a latinskaya forma ne podbirayetsya vruchnuyu.

## Kontrakt reyestra

Reyestr `Инструменты/реестр-названий-автоматизаций.json` imeyet skhemu `fum.automation-names.v1` i khranit:

- `linguistic_kit` — putj, otdeljnyiye adresa forka i iskhodnogo upstream, zakreplyonnuyu reviziyu, paru `Cyrl → Latn`, tablicu `ru` i sostoyaniye materializacii;
- `golden` — obyazateljnyiye etalonnyiye paryi `source` i `transliteration`;
- `current` — novyiye i pereimenovannyiye avtomatizacii s `source`, `transliteration` i `slug`;
- `display` — nazvaniya avtomatizacij bez kataloga, dlya kotoryikh nuzhnyi toljko `source` i `transliteration`;
- `legacy_display` — tochnyiye prezhniye otobrazhayemyiye host-imena bez kataloga, sokhranyonnyiye toljko dlya raspoznavaniya migrirovannoj na meste avtomatizacii;
- `legacy` — pole sovmestimosti istoricheskogo formata dlya prezhnikh katalogov.

V kanonicheskom reyestre `legacy` pust posle zavershyonnoj migracii katalogov. `legacy_display` mozhet soderzhatj tochnoye prezhneye host-imya toljko pri pereimenovanii susjhestvuyusjhej zapisi na meste: ono sluzhit vkhodom raspoznavaniya istoricheskoj konfiguracii, ne schitayetsya dejstvuyusjhim psevdonimom i ne razreshayet sozdavatj ili imenovatj novuyu avtomatizaciyu po-staromu. Validator zapresjhayet povtor legacy-imeni i yego odnovremennoye prisutstviye v aktivnom `display`.

Kogda odin obyyekt imeyet repozitornoye imya v `current` i otdeljnyij UI-zagolovok v `display`, dopuskayetsya para, razlichayusjhayasya toljko registrom russkogo istochnika i rezuljtata LinguisticKit. Validator prinimayet yeyo kak dva predstavleniya odnoj identichnosti toljko pri nalichii `slug` rovno u odnogo elementa; sovpadeniye transliteracij raznyikh smyislovyikh istochnikov po-prezhnemu schitayetsya kolliziyej.

Dlya `current` slug poluchayetsya kak prefiks `fum-` i tochnaya transliteraciya, privedyonnaya k nizhnemu registru i s zamenoj probelov na defisyi. Eta normalizaciya — sloj FUM, a ne funkciya LinguisticKit.

## Chto proveryayetsya

Validator:

- proveryayet skhemu, zakreplyonnyiye metadannyiye i pyatj etalonnyikh par;
- sveryayet `source` s rezuljtatom LinguisticKit cherez JSON-obyortku;
- otklonyayet povtoryi, kollizii, nedopustimyiye slug, ruchnyiye variantyi transliteracii i peresecheniye `legacy_display` s dejstvuyusjhimi otobrazhayemyimi imenami;
- nakhodit `Инструменты/fum-*/SKILL.md`, trebuyet sovpadeniya slug s imenem kataloga i polem `name`;
- otklonyayet nezaregistrirovannuyu ili ischeznuvshuyu avtomatizaciyu.

Tekusjhaya pamyatj FUM zakreplyayet sostoyaniye `ready`, materializovannyij submodule iz forka `fum-lab/LinguisticKit` i zhivuyu sverku kazhdogo sokhranyonnogo imeni. Posle svezhego klonirovaniya zavisimostj nuzhno [inicializirovatj vmeste s lokaljnyim `upstream`](../../Zavisimosti/README.md) do zapuska proverki; perevod kanonicheskogo reyestra v `blocked` ne podmenyayet etu operaciyu. Rezhim `blocked` sokhranyayetsya toljko kak fail-closed sovmestimostj formata i testovaya fikstura. Git-topologiyu gotovogo submodule otdeljno proveryayet [fum-proverka-git-zavisimostej](../fum-proverka-git-zavisimostej/SKILL.md).

## Komandyi

Proverka iz kornya repozitoriya:

```bash
python3 Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py
```

Avtonomnyiye testyi bez seti i bez materializovannoj zavisimosti:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-proverka-nazvanij-avtomatizacij/tests \
  -p 'test_*.py'
```

Testyi podmenyayut JSON-preobrazovatelj lokaljnyim processom. Oni fiksiruyut etalonyi, oshibochnuyu transliteraciyu, nevalidnyiye slug, kollizii, nezaregistrirovannyiye katalogi, imena bez kataloga, a takzhe rezhimyi `ready` i `blocked`.

## Granica avtomatizacii

Validator ne opredelyayet smyislovoye russkoye imya i ne vyipolnyayet pereimenovaniye kataloga. On takzhe ne ustanavlivayet zavisimostj i ne vyibirayet sposob yeyo podklyucheniya. Avtomatizaciya dayot ispolnimuyu strukturnuyu proverku uzhe zapisannogo resheniya i sovmestimostj testov s prezhnim formatom reyestra.

## Istochniki

- [iskhodnyij zapros 2026-07-22 08:44:00 MSK - Migrirovatj legacy imena avtomatizacij](../../Zhurnal/2026-07-22_08-44-00_MSK_migrirovatj-legacy-imena-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 12:18:37 MSK - Zakrepitj transliteraciyu nazvanij avtomatizacij](../../Zhurnal/2026-07-21_12-18-37_MSK_zakrepitj-transliteraciyu-nazvanij-avtomatizacij/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK — Aktualizirovatj fork i podklyuchitj LinguisticKit](../../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)
- [arkhivirovannyij repozitorij LinguisticKit](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/source-index.md)
- [arkhivirovannaya vyibrannaya reviziya LinguisticKit](../../Istochniki/URL/https/github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393/source-index.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-05 13:55:12 MSK -->
<!-- content-sha256: sha256:6426b980ca984b9f1d3d55a2a06662c77b6d2f4993ff565d9e7eb27c803f0b4a -->
<!-- FUM-MD-RECENCY:END -->
