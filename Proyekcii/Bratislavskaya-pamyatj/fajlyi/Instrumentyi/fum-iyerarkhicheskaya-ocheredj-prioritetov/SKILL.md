---
name: fum-iyerarkhicheskaya-ocheredj-prioritetov
description: Determinirovanno vyibiratj sleduyusjhij dopustimyij shag po iyerarkhicheskomu vektoru, sokhranyatj proiskhozhdeniye sobyitij i vosproizvoditj ocheredj bez vyidachi prava zapisi.
---

# Iyerarkhicheskaya ocheredj prioritetov

Avtomatizaciya perevodit prinyatyiye obsuzhdeniyem kandidatyi v dolgovechnoye mashinnoye
svideteljstvo i vyibirayet sleduyusjhij dopustimyij shag. Ona ne sozdayot Codex-zadachi,
ne sozdayot Git-vetki, ne menyayet indeks ili rabocheye derevo i ne zamenyayet
priyomku pisatelya.

## Kontrakt

Scenarij `scripts/очередь-приоритетов.py` prinimayet JSON so skhemoj
`fum.иерархическая-очередь.1` i vozvrasjhayet determinirovannyij JSON. Kazhdyij
kandidat obyazan imetj identifikator, sostoyaniye, rezhim dispetcherizacii, klass,
yavnyij prioritet, srochnostj, stoimostj, vremya postanovki, zavisimosti i chislo
razblokiruyemyikh shagov. Priostanovlennyiye, zablokirovannyiye, zavershyonnyiye,
ruchnyiye i nerazreshyonnyiye po zavisimostyam kandidatyi ne popadayut v gotovuyu ocheredj.

Poryadok — leksikograficheskij vektor, a ne neprozrachnaya summa:

1. klass (`безопасность`, `восстановление`, `пользовательский`, `обычный`);
2. yavnyij prioritet;
3. chislo razblokiruyemyikh shagov;
4. srochnostj;
5. vozrast v polnyikh minutakh (zasjhita ot golodaniya);
6. obratnaya stoimostj;
7. identifikator kak stabiljnaya vosstanavlivayemaya razvyazka.

Roditelj peredayot dochernemu kandidatu ne menjshe svoyego klassa i yavnogo
prioriteta. Budusjheye vremya, ciklicheskij roditelj, povtor identifikatora,
propusjhennoye pole ili neizvestnoye znacheniye dayut otkaz do sortirovki.

Komanda `воспроизвести` proveryayet otdeljnyij neizmenyayemyij zhurnal sobyitij. Nomer
sobyitiya nepreryiven, vremya ne ubyivayet, a kazhdoye sobyitiye soderzhit `источник` s
identifikatorom zadachi i iskhodnyim soobsjheniyem. Podderzhivayutsya sobyitiya
`добавить`, `обновить`, `завершить`, `приостановить`, `возобновить` i
`заблокировать`. Rezuljtatom yavlyayetsya sostoyaniye, prigodnoye dlya povtornogo
vyibora, i otpechatok vkhoda. Eto dolgovremennaya pamyatj obsuzhdeniya, a ne toljko
snimok okna tekusjhej sessii.

## Komandyi

```bash
python3 -B Инструменты/fum-iyerarkhicheskaya-ocheredj-prioritetov/scripts/очередь-приоритетов.py \
  выбрать --вход путь/к/очереди.json

python3 -B Инструменты/fum-iyerarkhicheskaya-ocheredj-prioritetov/scripts/очередь-приоритетов.py \
  воспроизвести --вход путь/к/журналу-событий.json
```

`--вход -` chitayet standartnyij vvod. Odinakovyiye bajtyi vkhoda dayut odinakovyij
otpechatok i poryadok. Vyivod ne zapisyivayetsya avtomaticheski v repozitorij: yego
peredachu v `Журнал/`, planirovaniye ili otdeljnuyu zadachu vyipolnyayet naznachennyij
pisatelj s obyichnyim proiskhozhdeniyem i proverkami.

## Proverki

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-iyerarkhicheskaya-ocheredj-prioritetov/tests \
  -p 'test_*.py'
```

Testyi zakreplyayut poryadok urovnej, isklyucheniye negotovyikh kandidatov,
nasledovaniye ot roditelya, zasjhitu ot golodaniya, stabiljnuyu razvyazku,
fail-closed dlya povrezhdyonnogo vkhoda i vosproizvedeniye zhurnala s proiskhozhdeniyem.

## Granica

Iyerarkhicheskij vyibor — read-only-podgotovka. On ne vozvrasjhayet polnomochiya
paralleljnoj zapisi i ne dokazyivayet, chto vyibrannyij shag vyipolnen. Posle vyibora
pisatelj obyazan povtorno sveritj svezhiye `HEAD`, vladeljca dereva, aktualjnostj
kartochki i primenimyiye pravila; rezuljtat, otkaz i posleduyusjheye resheniye
sokhranyayutsya v dolgovremennom zhurnale.

## Istochnik

- [iskhodnyij zapros 2026-09-21 19:19:21 MSK — Vvesti iyerarkhicheskuyu ocheredj prioritetov](../../Zhurnal/2026-09-21_19-19-21_MSK_vvesti-iyerarkhicheskuyu-ocheredj-prioritetov/zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-21 19:38:06 MSK -->
<!-- content-sha256: sha256:970d9ad3375f57ef3f62b8d038a07061cfcc3a5b1bd908af753c35e3ef861cf2 -->
<!-- FUM-MD-RECENCY:END -->
