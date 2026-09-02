---
name: fum-zapusk-prototipov
description: Proveryatj kornevuyu panelj prototipyi.sh i obyazateljnyiye prostyiye tochki vkhoda zapustitj.sh u vsekh ustojchivyikh prototipov FUM.
---

# FUM Prototype Launch

Eta lokaljnaya [avtomatizaciya FUM](../../Glossarij/avtomatizaciya-FUM.md) proveryayet yedinyij kontrakt prostogo zapuska prototipov. Kornevoj ispolnyayemyij POSIX-skript `prototipyi.sh` sluzhit obsjhej paneljyu, a kazhdyij neposredstvennyij podkatalog `Прототипы/` s pasportom `README.md` schitayetsya ustojchivyim prototipom i dolzhen soderzhatj ispolnyayemyij POSIX-skript `запустить.sh`.

## Kontrakt obsjhej paneli

Kornevoj skript `prototipyi.sh`:

- imeyet namerenno transliterirovannoye imya dlya zapuska bez pereklyucheniya raskladki;
- nachinayetsya s `#!/bin/sh`, imeyet ispolnyayemyij bit i korrekten dlya `/bin/sh`;
- sam opredelyayet korenj repozitoriya i ne zavisit ot tekusjhego rabochego kataloga;
- bez argumentov pokazyivayet pronumerovannuyu panelj najdennyikh `Прототипы/*/запустить.sh`;
- prinimayet cifru dlya zapuska i `q` dlya bezopasnogo vyikhoda;
- podderzhivayet `--list` bez zapuska i pryamoj vyibor nomerom;
- peredayot ostaljnyiye argumentyi vyibrannoj tochke vkhoda;
- avtomaticheski vklyuchayet budusjhiye prototipyi bez ruchnogo spiska.

## Kontrakt tochki vkhoda prototipa

Skript zapuska:

- nakhoditsya v korne kataloga prototipa i nazyivayetsya `запустить.sh`;
- nachinayetsya s `#!/bin/sh` i imeyet ispolnyayemyij bit;
- korrekten dlya `/bin/sh`;
- sam opredelyayet katalog prototipa i ne zavisit ot tekusjhego rabochego kataloga;
- bez obyazateljnyikh argumentov dayot poleznyij i bezopasnyij scenarij;
- peredayot yavno zadannyiye argumentyi prototipu;
- ne vklyuchayet chuvstviteljnoye dejstviye bez otdeljnoj yavnoj komandyi;
- opisan v pasporte prototipa.

Avtomaticheskaya proverka podtverzhdayet strukturnyiye svojstva kornevoj paneli i tochek vkhoda. Avtonomnyiye testyi dopolniteljno proveryayut spisok paneli, nezavisimostj ot tekusjhego kataloga, interaktivnyij vyibor i peredachu argumentov na vremennyikh fiksturakh. Poleznostj, bezopasnostj scenariya po umolchaniyu, peredachu argumentov i sootvetstviye pasportu nastoyasjhego prototipa nuzhno dopolniteljno proveryatj smyislovoj priyomkoj.

## Komanda zapuska

Iz kornya repozitoriya:

```bash
python3 Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py
```

Iz drugogo kataloga:

```bash
python3 /путь/к/FUM/Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py \
  --repo-root /путь/к/FUM
```

Uspeshnaya proverka podtverzhdayet kornevuyu panelj i soobsjhayet chislo najdennyikh tochek vkhoda prototipov. Oshibka perechislyayet kazhdyij otsutstvuyusjhij ili nekorrektnyij fajl i vozvrasjhayet nenulevoj kod.

## Proverki avtomatizacii

Avtonomnyiye testyi ne trebuyut seti, sekretov, Swift-sborki ili zapuska prototipov:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-zapusk-prototipov/tests \
  -p 'test_*.py'
```

Testyi fiksiruyut korrektnyij POSIX-skript, otsutstviye kornevoj paneli ili kataloga prototipov, otsutstviye fajla, otsutstviye ispolnyayemogo bita, nevernyij shebang, sintaksicheskuyu oshibku, ignorirovaniye sluzhebnyikh katalogov bez `README.md`, spisok paneli, interaktivnyij vyibor i peredachu argumentov.

## Granica avtomatizacii

Strukturnaya proverka namerenno ne ispolnyayet nastoyasjhiye `prototipyi.sh` i `запустить.sh`. Povedeniye paneli proveryayetsya na vremennoj kopii s bezopasnyimi fiksturami. Nastoyasjhij prototip mozhet otkryivatj GUI, obrasjhatjsya k zaraneye ustanovlennoj lokaljnoj modeli, chitatj yavno vyibrannyij fajl ili trebovatj otdeljnogo soglasiya na nablyudeniye chuvstviteljnogo vvoda. Takiye scenarii prinimayutsya otdeljno po pasportu, a proverka tochek vkhoda ostayotsya bezopasnoj i avtonomnoj vnutri yavnogo polnogo profilya libo otdeljnogo celevogo zapuska; standartnyij dokumentacionnyij smoke yeyo ne vyizyivayet.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-08-24 13:29:48 MSK — Sokratitj smoke do dokumentacionnogo prototipa](../../Zhurnal/2026-08-24_13-29-48_MSK_sokratitj-smoke-do-dokumentacionnogo-prototipa/zapros.md)
- [iskhodnyij zapros 2026-07-17 12:20:17 MSK - Sozdatj skriptyi zapuska prototipov](../../Zhurnal/2026-07-17_12-20-17_MSK_sozdatj-skriptyi-zapuska-prototipov/zapros.md)
- [iskhodnyij zapros 2026-07-17 12:33:01 MSK - Dobavitj panelj zapuska prototipov](../../Zhurnal/2026-07-17_12-33-01_MSK_dobavitj-panelj-zapuska-prototipov/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-24 15:00:57 MSK -->
<!-- content-sha256: sha256:e6d8f2a2d80d95ae4170799a32a84ee86d75a3aa08f1c972dec7d81d700cf05e -->
<!-- FUM-MD-RECENCY:END -->
