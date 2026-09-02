+++
schema_version = 1
card_id = "FUM-STEP-0138"
status = "active"
+++
# Ograditj sostavnuyu shell-diagnostiku ot maskirovki rannego otkaza

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Vvesti podderzhannyij marshrut posledovateljnoj shell-diagnostiki, kotoryij do zapuska razlichayet obyazateljnyiye i neobyazateljnyiye podkomandyi, sokhranyayet iskhod kazhdoj iz nikh i garantiruyet nenulevoj obsjhij rezuljtat posle lyubogo obyazateljnogo otkaza nezavisimo ot uspekha pozdnikh komand.

## Pochemu sejchas

V tochnom proyavlenii `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002` sostavnoj vyizov uspeshno prochital FUM-SBOJ-0008, zatem ne nashyol po oshibochno predpolozhennomu puti obyazateljnuyu kartochku FUM-STEP-0136, no prodolzhil chteniyami tekusjhikh zaprosa i otchyota. Posledneye uspeshnoye chteniye opredelilo obsjhij kod `0`, poetomu uzhe vtoroj rannij otkaz etogo klassa ostalsya toljko strokoj v vyivode i ne izmenil mashinnyij itog vyizova.

## Kriterii zaversheniya

- Krasnaya regressionnaya fikstura vosproizvodit tochnuyu posledovateljnostj `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002`: uspeshnoye chteniye FUM-SBOJ-0008, otkaz `sed` na oshibochno predpolozhennom puti k FUM-STEP-0136 i posleduyusjhiye uspeshnyiye chteniya zaprosa i otchyota sejchas dayut sostavnomu processu kod `0`.
- Plan sostavnoj diagnostiki do ispolneniya zadayot dlya kazhdoj podkomandyi ustojchivoye imya, argumentyi i rovno odin klass — `обязательная` ili `необязательная`; propusjhennyij, neizvestnyij ili protivorechivyij klass otklonyayetsya do zapuska.
- Realizaciya sokhranyayet sobstvennyij iskhod kazhdoj zapusjhennoj podkomandyi i yeyo diagnosticheskij vyivod, poetomu itog ne vyichislyayetsya toljko po poslednej komande.
- Lyuboj nenulevoj iskhod, oshibka zapuska, signal ili inoye nezaversheniye obyazateljnoj podkomandyi garantirovanno dayut nenulevoj obsjhij rezuljtat. Realizaciya mozhet zakryito ostanovitjsya srazu ili prodolzhitj yavno razreshyonnyij sbor diagnostiki, no pozdnij uspekh ne perezapisyivayet obyazateljnyij otkaz.
- Otkaz neobyazateljnoj probyi dopuskayet obsjhij uspekh toljko togda, kogda proba obyyavlena neobyazateljnoj do ispolneniya; yeyo klass i otkaz ostayutsya v strukturirovannom rezuljtate, a dannyiye nevyipolnennoj probyi ne podtverzhdayut obyazateljnyij vyivod.
- Otdeljnyiye avtomaticheskiye fiksturyi pokryivayut vse obyazateljnyiye podkomandyi s uspekhom, rannij i srednij obyazateljnyiye otkazyi s pozdnim uspekhom, neskoljko obyazateljnyikh otkazov i otkaz toljko yavno neobyazateljnoj probyi.
- Podderzhannyij marshrut podklyuchyon k sostavnyim shell-diagnostikam rabochej sessii ili ikh obsjhemu orkestracionnomu pomosjhniku; neproverennaya posledovateljnostj s itogom poslednej komandyi ne ispoljzuyetsya kak mashinnoye dokazateljstvo uspekha.
- Avtonomnyiye regressionnyiye testyi FUM-SBOJ-0010, primenimyiye proverki zatronutogo marshruta i obsjhij smoke-check prokhodyat bez seti i sekretov.

## Istochniki

- [FUM-SBOJ-0010 — Maskirovka rannego otkaza sostavnoj shell-diagnostiki](../../Sboi/FUM-SBOJ-0010-maskirovka-rannego-otkaza-sostavnoj-shell-diagnostiki.md) — tochnoye osnovaniye `FUM-СБОЙ-0010/ПРОЯВЛЕНИЕ-0002`
- [iskhodnyij zapros tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/zapros.md)
- [otchyot tekusjhej rabochej sessii](../../Zhurnal/2026-08-06_22-29-49_MSK_vvesti-kartochki-sboyev-dlya-porozhdeniya-shagov/otchyot.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-07 00:45:19 MSK -->
<!-- content-sha256: sha256:c2c31332dfd95277888f6c335c83c9d47facae3d50bfd41b5c5341ae9cc26697 -->
<!-- FUM-MD-RECENCY:END -->
