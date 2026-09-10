+++
schema_version = 1
card_id = "FUM-STEP-0164"
status = "completed"
+++
# Prinyatj formyi runtime i realjnyij arkhiv

## Zadacha

Posle integracii prinyatj pervyij yavno razreshyonnyij realjnyij arkhivnyij import i utochnitj tochnyij podderzhannyij nabor form Codex JSONL.

## Pochemu sejchas

Pervaya postavka adaptera proverena otkryitoj sintetikoj. Nablyudeniye zhivogo processa, UI i polnoye semanticheskoye pokryitiye runtime ostayutsya za yeyo granicej.

## Kriterii zaversheniya

- Poluchenyi otdeljnoye razresheniye na konkretnyij istochnik i ozhidayemyij UUID; drugiye sessii ne chitayutsya.
- Realjnaya forma proverena po ustojchivomu kontraktu i publikacionno chistyim fiksturam, a ne po odnomu cli_version.
- Import, povtor, dopolneniye, replay i otkaz pri podmene podtverzhdenyi bez publikacii soderzhimogo dialoga ili sekretov.
- Vozmozhnostj obsjhego bajtovogo chitatelya ocenena po prinyatomu commit/API statistiki; semantika statistiki i snimka ostayotsya razdeljnoj.
- Neizvestnyiye statusyi i ogranichennyij okhvat sokhranenyi; rezuljtat etapa ne zakryivayet vsyo nablyudeniye macOS.

## Rezuljtat

Podderzhannyiye formyi proverenyi publichnyimi fiksturami dochernej postavki i dvumya zakreplyonnyimi realjnyimi prefiksami razreshyonnoj kornevoj zadachi. Pervaya neuspeshnaya popyitka prezhnej versii ostayotsya istoricheskim svideteljstvom; ispravlennyij Swift-kommit `cffd4c52852da19d3e71c5a2d22e41712b3e734f` uspeshno importiroval istochnik. Podtverzhdenyi pobajtnyij povtor, dopolneniye 451 strokoj, vosstanovleniye otdeljnyim processom, otkaz podmene i usecheniyu bez izmeneniya prinyatogo kontejnera. Syiryiye dannyiye ne publikovalisj.

Obsjhij chitatelj ocenyon po API statistiki `85dccce282821a890e5e65539b4f22b895b52887`: on vozvrasjhayet predmetnyiye sobyitiya i ne podmenyayet arkhivnyij chitatelj. Vyideleniye obsjhego sloya bajtov, LF i SHA ostavleno budusjhemu samostoyateljnomu resheniyu.

Neizvestnyiye statusyi i ogranichennyij okhvat sokhranenyi. Rezuljtat ne zakryivayet zhivoye nablyudeniye runtime/UI (FUM-STEP-0159) ili otdeljnuyu priyomku podgotovki SwiftPM (FUM-STEP-0163). Ikh istoricheskiye kartochki sokhranyayutsya v iskhodnyikh vetkakh. Dejstvuyusjhaya osnovnaya vetka poluchayet toljko ogranichennuyu arkhivnuyu priyomku bez izmeneniya rezhima rabotyi agentov.

## Istochniki

- [Priyomka realjnogo dopolneniya i podmenyi](../../Zhurnal/2026-09-09_18-43-02_MSK_zavershitj-priyomku-arkhivnogo-snimka/otchyot.md).

- [Ogranichennyij etap sluzhebnyikh obolochek](https://github.com/fum-lab/fum/blob/81e2e2c6e830c0f742fffa719c38facde39e41a1/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_17-52-38_MSK_%D0%BF%D0%BE%D0%B4%D0%B4%D0%B5%D1%80%D0%B6%D0%B0%D1%82%D1%8C-%D1%81%D0%BB%D1%83%D0%B6%D0%B5%D0%B1%D0%BD%D1%8B%D0%B5-%D0%BE%D0%B1%D0%BE%D0%BB%D0%BE%D1%87%D0%BA%D0%B8-runtime/%D0%BE%D1%82%D1%87%D1%91%D1%82.md).

- [Porucheniye](https://github.com/fum-lab/fum/blob/81e2e2c6e830c0f742fffa719c38facde39e41a1/%D0%96%D1%83%D1%80%D0%BD%D0%B0%D0%BB/2026-09-09_16-02-38_MSK_%D1%80%D0%B5%D0%B0%D0%BB%D0%B8%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D1%8C-%D0%B0%D1%80%D1%85%D0%B8%D0%B2%D0%BD%D1%8B%D0%B9-%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA-%D0%B7%D0%B0%D0%B4%D0%B0%D1%87%D0%B8/%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81.md).
- [Arkhivnyij snimok zadachi FUMA](../../Dokumentaciya/arkhivnyij-snimok-zadachi-FUMA.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 18:54:52 MSK -->
<!-- content-sha256: sha256:6d32b677ab85a4b9663c75a7fed22ee39232d6c9b85ad6f4ed63760987e2d827 -->
<!-- FUM-MD-RECENCY:END -->
