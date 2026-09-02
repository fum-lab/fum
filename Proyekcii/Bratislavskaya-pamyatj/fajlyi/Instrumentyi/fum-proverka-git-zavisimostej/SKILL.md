---
name: fum-proverka-git-zavisimostej
description: Dobavlyatj, inicializirovatj posle svezhego klonirovaniya i avtonomno proveryatj vneshniye Git-zavisimosti FUM cherez fork ryadom s aktualjnyim repozitoriyem FUM, otdeljnyij upstream i tochnyij gitlink.
---

# Proverka Git-zavisimostej

Avtomatizaciya materializuyet vneshnyuyu Git-zavisimostj kak polnocennyij klon i Git submodule, vosstanavlivayet uzhe zaregistrirovannuyu zavisimostj posle svezhego klonirovaniya libo avtonomno proveryayet podklyuchyonnoye sostoyaniye. Fork dolzhen nakhoditjsya u togo zhe GitHub-vladeljca, chto i publikacionnyij `origin` aktualjnoj rabochej kopii FUM; originaljnyij repozitorij sokhranyayetsya otdeljnyim remote `upstream`.

Avtonomnaya proverka ne obrasjhayetsya k seti. Ona sveryayet tochnyiye URL i roli remote, putj i URL v `.gitmodules`, sokhranyonnyij `fumUpstream`, detached `HEAD`, otsutstviye shallow-rezhima i lokaljnyikh izmenenij, dostizhimostj vyibrannoj revizii iz poluchennyikh refs forka, rezhim `160000` i SHA gitlink. Liniya forka v GitHub, yego sinkhronizaciya s roditeljskim repozitoriyem, licenziya i publikacionnaya dopustimostj ostayutsya otdeljnyimi vneshnimi predposyilkami.

## Dobavleniye zavisimosti

Do zapuska GitHub-fork uzhe dolzhen susjhestvovatj i byitj sinkhronizirovan s originalom. Mutiruyusjhij rezhim prinimayet toljko yavnyiye znacheniya:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py add \
  --repo-root . \
  --fork-url <публичный-HTTPS-URL-форка> \
  --upstream-url <URL-оригинала> \
  --path <относительный-путь-submodule> \
  --revision <полный-Git-OID>
```

Pered izmeneniyem osnovnogo repozitoriya komanda kloniruyet oba istochnika vo vremennyij katalog i podtverzhdayet, chto vyibrannyij kommit dostizhim iz obyichnoj vetki poluchennogo forka. Nesvyazannyiye izmeneniya osnovnogo repozitoriya sokhranyayutsya; konfliktuyusjhij putj, gitlink, razdel `.gitmodules` ili ostatochnyij Git-katalog zakryivayut dobavleniye. Povtornyij tochnyij vyizov proveryayet uzhe susjhestvuyusjhuyu zavisimostj i zavershayetsya bez novogo izmeneniya.

## Inicializaciya zaregistrirovannoj zavisimosti

Posle svezhego klonirovaniya FUM zaregistrirovannyij submodule i yego otdeljnyij `upstream` vosstanavlivayutsya odnoj komandoj:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init \
  --repo-root . \
  --path Зависимости/LinguisticKit
```

Rezhim `init` ne prinimayet URL ili reviziyu ot vyizyivayusjhej storonyi. On trebuyet obyichnyij UTF-8-fajl `.gitmodules`, sovpadayusjhij s Git-indeksom, i strogo po odnomu nepustomu `path`, `url` i `fumUpstream` zaregistrirovannogo puti. Polnyij OID vyibirayetsya toljko iz gitlink rezhima `160000` i stage `0`. Do materializacii proveryayutsya vse susjhestvuyusjhiye komponentyi rabochego puti, kanonicheskoye imya Git-kataloga submodule i otsutstviye ostatochnogo libo perenapravlennogo `.git/modules/<name>`; nevernoye sostoyaniye ne uspevayet izmenitj lokaljnyij URL ili vneshnij Git-katalog. U uzhe materializovannoj kopii dopuskayetsya chistyij HEAD na drugoj revizii, no ne lokaljnyiye izmeneniya, shallow-rezhim, chuzhoj Git-korenj, lishnij remote, netochnyij URL ili nestandartnyij fetch refspec.

Posle lokaljnoj predvariteljnoj proverki komanda vosstanavlivayet otsutstvuyusjhij `upstream`, vyipolnyayet `git fetch --prune origin` i `git fetch --prune upstream`, vyibirayet gitlink cherez detached checkout s zapretom perezapisi ignoriruyemyikh fajlov i zapuskayet tot zhe validator, chto i `check`. Strogiye fetch refspec i prune isklyuchayut dokazateljstvo dostizhimosti po ustarevshej remote-tracking vetke. Povtornyij tochnyij zapusk idempotenten.

Etot rezhim primenim k odnomu yavno vyibrannomu verkhneurovnevomu submodule, uzhe zaregistrirovannomu v otslezhivayemoj `.gitmodules`. On mozhet obrasjhatjsya k seti, no ne sozdayot novuyu zapisj submodule, ne menyayet `.gitmodules` ili gitlink, ne vyibirayet vershinu remote vmesto gitlink, ne sinkhroniziruyet fork i ne inicializiruyet proizvoljnuyu vlozhennuyu iyerarkhiyu. Rodstvo i publikaciya GitHub-forka, yego sinkhronizaciya s originalom, licenziya, dostupnostj i publikacionnaya dopustimostj ostayutsya otdeljnyimi vneshnimi predposyilkami. Zavershayusjhij `check` po-prezhnemu avtonomen i ne obrasjhayetsya k seti.

## Proverka zavisimosti

Dlya LinguisticKit ispoljzuyetsya komanda:

```bash
python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py check \
  --repo-root . \
  --fork-url https://github.com/fum-lab/LinguisticKit.git \
  --upstream-url https://github.com/Roman-Kerimov/LinguisticKit.git \
  --path Зависимости/LinguisticKit \
  --revision 837e2ce107b97ee7b9d3344c9fe99142281fe393
```

Kod `0` oznachayet polnoye sovpadeniye lokaljnoj Git-topologii i gitlink s kontraktom. Kod `1` soprovozhdayetsya russkoj diagnostikoj kazhdogo obnaruzhennogo raskhozhdeniya.

## Avtonomnyiye testyi

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s Инструменты/fum-proverka-git-zavisimostej/tests \
  -p 'test_*.py'
```

Testyi sozdayut vremennyiye lokaljnyiye bare-repozitorii FUM, forka i upstream. Oni proveryayut uspeshnoye dobavleniye, svezhiye recursive i obyichnyij clone, vosstanovleniye `upstream`, polucheniye i prune oboikh remote, vyibor gitlink, idempotentnostj, dopustimostj nesvyazannyikh izmenenij, prinadlezhnostj forka vladeljcu aktualjnogo FUM, dostizhimostj vyibrannogo kommita iz vetki forka, roli i refspec remote, stroguyu kratnostj `.gitmodules`, kanonicheskiye Git-katalogi, bezopasnyiye komponentyi puti, zasjhitu ignoriruyemyikh fajlov, tochnyij `HEAD`, chistotu klona i CLI-diagnostiku bez vneshnej seti.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 04:10:40 MSK — Dobavitj inicializaciyu zaregistrirovannyikh Git submodule](../../Zhurnal/2026-07-22_04-10-40_MSK_dobavitj-inicializaciyu-zaregistrirovannyikh-Git-submodule/zapros.md)
- [iskhodnyij zapros 2026-07-21 11:06:43 MSK — Zakrepitj klonirovaniye vneshnikh repozitoriyev](../../Zhurnal/2026-07-21_11-06-43_MSK_zakrepitj-klonirovaniye-vneshnikh-repozitoriyev/zapros.md)
- [iskhodnyij zapros 2026-07-21 12:52:18 MSK — Zakrepitj forki Git zavisimostej v FUM lab](../../Zhurnal/2026-07-21_12-52-18_MSK_zakrepitj-forki-Git-zavisimostej-v-fum-lab/zapros.md)
- [iskhodnyij zapros 2026-07-21 13:40:42 MSK — Aktualizirovatj fork i podklyuchitj LinguisticKit](../../Zhurnal/2026-07-21_13-40-42_MSK_aktualizirovatj-fork-i-podklyuchitj-LinguisticKit/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:8e7b5c098f1b99483035b53a7a953fe5e04378f69a397cdebeca9ef97a4dc798 -->
<!-- FUM-MD-RECENCY:END -->
