+++
schema_version = 1
card_id = "FUM-STEP-0152"
status = "active"
+++
# Soglasovatj format patcha priyomsjhika s proyekciyej

## Zadacha

Soglasovatj dokumentirovannyij kontejner vyikhodnogo patcha priyomsjhika vneshnego vklada s tochnyimi formatami bratislavskoj proyekcii i proverkoj mashinno-lokaljnyikh putej, chtobyi shtatnyij marshrut prokhodil obsjhij smoke bez nepredpisannyikh preobrazovanij.

## Pochemu sejchas

V tekusjhem priyome korrektnyij lokaljnyij patch byil otklonyon proyekciyej iz-za rasshireniya `.patch`. Promezhutochnyij `.patch.txt` proshyol proyekciyu, no proverka putej otvergla standartnuyu stroku zagolovka dobavlyayemogo fajla. Proverennyiye bajtyi otdeljno zakodirovanyi v `.patch.base64`; primer navyika i tochnyij vyikhod interfejsa poka ne opisyivayut takoj soglasovannyij marshrut.

## Kriterii zaversheniya

- Vyibran yedinyij podderzhannyij format khraneniya s sokhraneniyem tochnyikh bajtov patcha; primer i proveryayemyij interfejs soglasovanyi.
- Regressionnyij primer dobavleniya fajla prokhodit ot vyikhoda priyomsjhika do priyomki proyekcii i proverki lokaljnyikh putej bez nepredpisannyikh pereimenovanij ili kodirovaniya.
- Khyesh dekodirovannyikh bajtov patcha ostayotsya raven svideteljstvu priyomsjhika, neizvestnyij format po-prezhnemu otklonyayetsya.
- Proverki i obnovlyonnaya granica svyazanyi s iskhodnyim proyavleniyem sboya.

## Istochniki

- [Iskhodnyij zapros](../../Zhurnal/2026-09-07_18-16-36_MSK_prinyatj-modelj-betonnyikh-glubinnyikh-sistem/zapros.md).
- [FUM-SBOJ-0024/PROYAVLENIYE-0001](../../Sboi/FUM-SBOJ-0024-nesovmestimyij-format-patcha-v-proyekcii.md#proyavleniya).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-07 20:02:13 MSK -->
<!-- content-sha256: sha256:95906cbdfed2fb9ef178d0e35e3951b33e09db761507f08942f4cc9f70476c09 -->
<!-- FUM-MD-RECENCY:END -->
