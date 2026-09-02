---
name: fum-moskovskoye-vremya-rabochej-sessii
description: Formiruyet kanonicheskiye vremennoj prefiks i zagolovochnuyu metku rabochej sessii FUM v zone Europe/Moscow. Ispoljzuj pered sozdaniyem papki zaprosa v Zhurnal/ i drugikh vremenno imenovannyikh materialov, osobenno kogda lokaljnaya zona sredyi otlichayetsya ot moskovskoj.
---

# Moskovskoye vremya rabochej sessii FUM

Poluchaj obe formyi vremeni odnim vyizovom:

```bash
python3 Инструменты/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py --format both
```

Skopiruj znacheniye `prefix` bez izmenenij v imya papki zaprosa i svyazannyiye vremennyiye identifikatoryi materialov. Ispoljzuj sootvetstvuyusjheye znacheniye `label` v zagolovkakh i tekstovyikh ssyilkakh. Ne vyivodi MSK-vremya iz lokaljnyikh chasov sredyi i ne zamenyaj `Europe/Moscow` tekusjhej zonoj khosta.

Dlya vosproizvodimoj proverki konkretnogo momenta peredavaj ISO 8601 s `Z` ili yavnyim smesjheniyem:

```bash
TZ=Europe/Saratov python3 Инструменты/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py \
  --at 2026-07-17T07:07:09Z \
  --format both
```

Ozhidayemyij rezuljtat:

```text
prefix=2026-07-17_10-07-09_MSK
label=2026-07-17 10:07:09 MSK
```

## Proverka

Zapuskaj avtonomnyiye testyi bez seti i sekretov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-moskovskoye-vremya-rabochej-sessii/tests \
  -p 'test_*.py'
```

Testyi zakreplyayut preobrazovaniye UTC-momenta v `Europe/Moscow`, nezavisimostj ot zonyi khosta, soglasovannostj dvukh form i otkloneniye neodnoznachnogo vremeni bez zonyi.

## Granica avtomatizacii

Skript toljko vyichislyayet kanonicheskiye formyi odnogo momenta. Sozdaniye papki zaprosa, navigaciya, zhurnalirovaniye i proverka ssyilok vyipolnyayutsya avtomatizaciyej strukturyi papok zaprosov i posleduyusjhimi shagami rabochej sessii.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-17 10:25:41 MSK - Predotvrasjhatj smesjheniye vremeni sessij](../../Zhurnal/2026-07-17_10-25-41_MSK_predotvrasjhatj-smesjheniye-vremeni-sessij/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:134723ce1dcfc5efd18d172640c43c1e2e2e8c21cd577d74c91af524660272fd -->
<!-- FUM-MD-RECENCY:END -->
