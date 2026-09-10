# Prodvizheniye prinyatogo sliyaniya

Etot uzkij ispolnitelj zavershayet yavno razreshyonnuyu integraciyu: pervichnyij master M stanovitsya tem zhe proverennyim merge C s roditelyami `[L, M]`. On soglasuyet vetku, indeks i rabochiye fajlyi, ne sozdayot vtoroye sliyaniye, ocheredj, novuyu zadachu ili publikaciyu. Trebuyetsya odin pisatelj i susjhestvuyusjhij otdeljnyij worktree kandidata na C v toj zhe Git-baze.

Snachala vyipolnyayetsya [vyisokij dopusk iz master](proverka-sliyaniya-iz-master.md). Kod ispolnitelya, yego adresnyiye testyi i profilj dolzhnyi byitj proverenyi; rabochij fajl ispolnitelya dolzhen sovpadatj s prinyatoj versiyej v C. Zatem CLI yesjhyo raz zapuskayet zakryityij chitatelj iz neizmennogo M do podgotovki checkout. Povtor uzhe dostignutogo C proveryayet iskhodnyij dolgovechnyij intent i tochnyiye fajlyi, ne zagruzhaya predlagayemyij chitatelj iz novogo checkout.

## Kak vyipolnitj perekhod

Peremennyiye `fum_source`, `fum_candidate`, `fum_python`, `fum_pycache`, `fum_M`, `fum_L`, `fum_C` i `fum_request` imeyut tot zhe smyisl, chto v procedure dopuska. `fum_intent` — novyij absolyutnyij putj dolgovechnogo JSON-fajla vne oboikh checkout. On soderzhit lokaljnyiye puti i ne dobavlyayetsya v Git. Zapuskatj nuzhno proverennyij fajl iz neizmennogo worktree C:

```bash
"$fum_python" -E -B -X "pycache_prefix=$fum_pycache" \
  "$fum_candidate/Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/продвинуть_принятое_слияние.py" \
  --корень "$fum_source" --кандидат "$fum_candidate" \
  --M "$fum_M" --L "$fum_L" --C "$fum_C" \
  --запрос "$fum_request" --intent "$fum_intent"
```

Uspeshnyij otvet `завершено` oznachayet nablyudyonnyiye exact C, derevo indeksa T i sovpadayusjhiye rabochiye bajtyi. `уже_достигнуто` — proverennyij povtor bez povtornogo prodvizheniya refs i izmeneniya intent. Oshibka ne razreshayet povtor s izmenyonnyimi vkhodami i ne oznachayet, chto vetka obyazateljno ostalasj na M: sleduyet prochitatj intent i fakticheskoye sostoyaniye. Posle uspeshnogo otveta vsyo ravno proveryayutsya HEAD, symbolic ref, indeks i rabochiye fajlyi obyichnyim chteniyem.

## Chto zasjhisjheno

Do zapisi proveryayutsya polnyiye OID i poryadok roditelej, obyichnyij primary master, razdeljnyiye git-dir obsjhej Git-bazyi, iskhodnyiye indeks i rabochiye bajtyi, flagi indeksa, registrovyiye i Unicode-kollizii, ignoriruyemyiye puti i tochnyiye materializacii gitlink. Pustyiye Git-podderevjya, kotoryiye indeks ne predstavlyayet, otklonyayutsya. Etot perekhod namerenno ne podderzhivayet izmeneniye gitlink ili attributes; obyichnyiye, budusjhiye i ignoriruyemyiye attributes-fajlyi zapresjhenyi. Sistemnyiye i globaljnyiye attributes, hooks, fsmonitor i lazy-fetch isklyuchenyi iz komand perekhoda. Obyichnyiye lokaljnyiye `.DS_Store` sokhranyayutsya, yesli ne peresekayutsya s celevyimi fajlami.

Otdeljnaya podgotovlennaya tranzakciya primary proveryayet simvolicheskij HEAD i uderzhivayet yego blokirovku bez izmeneniya. Vtoraya tranzakciya iz worktree kandidata proveryayet ozhidayemyij prezhnij M i uderzhivayet master. Posle oboikh podtverzhdenij podgotovki dvukhderevnyij `read-tree -m -u M C` sokhranyayet shtatnuyu zasjhitu Git ot poyavivshikhsya izmenenij. Pered fiksaciyej vetki zanovo proveryayutsya tochnyiye indeks T i rabochiye bajtyi. Readback vyipolnyayetsya do osvobozhdeniya proverki HEAD. Master reflog poluchayet zapisj perekhoda; primary HEAD reflog otdeljnuyu zapisj M→C ne poluchayet.

Pri chastichnom otkaze, neopredelyonnom otvete Git ili novom poljzovateljskom khvoste sokhranyayetsya nablyudayemoye sostoyaniye. Avtomaticheskogo reset, otkata i udaleniya dannyikh net. Intent otmechayet neobkhodimostj razbora; nedostupnoye chteniye tozhe sokhranyayetsya kak oshibka, a ne zamenyayetsya predpolagayemyim rezuljtatom. Mekhanizm rasschitan na soglasovannogo yedinstvennogo pisatelya i obyichnyiye Git-blokirovki; on ne yavlyayetsya globaljnoj blokirovkoj redaktorov ili zasjhitoj ot dejstvij, pryamo ignoriruyusjhikh Git-lock.

## Proverka realizacii

[Regressii](tests/test_prodvizheniye_prinyatogo_sliyaniya.py) sozdayut sobstvennyiye vremennyiye primary i linked worktree, vyipolnyayut nastoyasjhiye Git-tranzakcii i proveryayut sokhrannostj dannyikh pri otkazakh. Vyisokaya priyomka merge ostayotsya otdeljnoj obyazannostjyu chitatelya M; nizkaya funkciya perekhoda sama po sebe yeyo ne dokazyivayet. Dlya tekusjhego pervogo dopuska novyij nabor zapuskayetsya otdeljno cherez otchyotnuyu obyortku M, poskoljku yego yesjhyo net v prinyatom kataloge testov M.

[Parnyij profilj i rezuljtatyi](../../Zhurnal/2026-09-10_20-23-26_MSK_proveritj-sliyaniye-posle-dopuska/otchyot.md) sravnivayut sokhranyonnuyu iskhodnuyu realizaciyu s sokrasjhyonnyim chislom chtenij neizmenyayemyikh Git-obyyektov. Indeks i rabochiye fajlyi perechityivayutsya na kazhdoj granice; rezuljtatyi prezhnej proverki mezhdu vyizovami ne kyeshiruyutsya.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-10 21:26:37 MSK -->
<!-- content-sha256: sha256:ccbcc639d3bdc6e79740047ae31cb34e37dab589025e55d29d48d16e598518a1 -->
<!-- FUM-MD-RECENCY:END -->
