# Otchyot 2026-06-25 18:30:09 MSK

## Glavnoye

[MVP-kandidatyi](../../Glossarij/MVP-kandidat.md) FUM pereformatirovanyi tak, chtobyi chitatjsya kak konkretnyiye produktovyiye idei, gotovyiye k ogranichennomu zapusku, a ne kak obsjhiye napravleniya razvitiya. Dlya kazhdogo kandidata teperj yavno nazvanyi produkt, pervyij poljzovatelj, pervyij scenarij zapuska, sostav pervogo reliza i kriterij gotovnosti.

## Chto izmenilosj

- Obnovleno opredeleniye termina [MVP-kandidat](../../Glossarij/MVP-kandidat.md): napravleniye proyektirovaniya teperj schitayetsya osnovaniyem kandidata, no ne zamenyayet produktovuyu ideyu.
- V indekse [MVP-kandidatov](../../Planirovaniye/MVP-kandidatyi/README.md) dobavlena produktovaya ramka i tablica zapuskayemyikh idej.
- V [matrice otbora](../../Planirovaniye/MVP-kandidatyi/matrica-otbora.md) sravneniye perevedeno na urovenj produktovyikh idej: "Arkhivator istochnikov FUM", "Pomosjhnik rabochej sessii FUM", "Redaktor svyaznoj dokumentacii FUM", "Trassirovsjhik agentskogo progona FUM", "Generator adresnyikh opisanij FUM" i "Puljt lokaljnoj pamyati FUM".
- V kazhduyu kartochku kandidata dobavlen razdel `## Продуктовая идея для запуска`.
- V [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) dobavleno prodolzheniye pro paket pervogo zapuska dlya aktivnogo produkta "Arkhivator istochnikov FUM".

## Resheniya

Susjhestvuyusjhiye kandidatyi sokhranenyi, potomu chto ikh arkhitekturnyiye osnovaniya uzhe poleznyi i svyazanyi s dorozhnoj kartoj. Izmenyon urovenj formulirovki: teperj kartochka dolzhna nachinatjsya s vidimogo produkta i poljzovateljskogo rezuljtata, a ne s vnutrennego napravleniya ili sloya.

Aktivnyim blizhajshim zapuskom ostayotsya arkhivirovaniye prikreplyayemyikh materialov, no teperj ono sformulirovano kak produkt "Arkhivator istochnikov FUM": poljzovatelj dayot URL ili rassharennyij material i poluchayet lokaljnuyu papku istochnika, izvlechyonnyij tekst, otchyot i ssyilki iz fajla zaprosa.

## Proverki

- `git diff --check` - proshlo bez zamechanij.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-25_18-30-09_MSK.md` - proshlo.

## Vozmozhnyiye prodolzheniya

Pervyim prakticheskim prodolzheniyem stoit sobratj paket pervogo zapuska dlya "Arkhivatora istochnikov FUM": komandu ili scenarij zapuska, README pervogo poljzovateljskogo scenariya, lokaljnyiye fiksturyi i demonstracionnyij rezuljtat na odnom ustojchivom istochnike.

## Istochniki

- [iskhodnyij zapros 2026-06-25 18:30:09 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:38d633a80a445cf77c0eb26fd4f14328a91e739b2e9ca960d5e4aa04d6012f13 -->
<!-- FUM-MD-RECENCY:END -->
