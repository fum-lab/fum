# Otchyot 2026-07-14 20:33:47 MSK - Sozdatj kartochki trebovanij k interfejsu

V pamyati FUM sozdan otdeljnyij razdel `Требования/` dlya atomarnyikh [kartochek trebovanij FUM](../../Glossarij/kartochka-trebovaniya-FUM.md). Sostoyaniye kazhdoj kartochki teperj vidno neposredstvenno v imeni fajla cherez yedinyij emodzi [statusa trebovaniya FUM](../../Glossarij/status-trebovaniya-FUM.md); legenda razlichayet chernovik, prinyatoye i zaplanirovannoye trebovaniye, realizaciyu, podtverzhdyonnyij rezuljtat, blokirovku i snyatiye.

Pervyij nabor sostavlen iz semi punktov razdela «Polnostjyu kastomnyij interfejs poverkh macOS» arkhivirovannogo ChatGPT-dialoga. Vse semj kartochek poluchili status `🟡`: tekusjhij poljzovateljskij zapros prinimayet ikh kak zaplanirovannyiye trebovaniya, no ne utverzhdayet gotovuyu i proverennuyu realizaciyu. Kartochki okhvatyivayut polnoekrannoye prilozheniye, Metal-otrisovku, skryitiye sistemnyikh panelej, avtomaticheskij vkhod, avtozapusk, otdeljnyij fonovyij servis i upravlyayemyij zhyostkij kiosk-rezhim.

Kazhdaya kartochka otdelyayet formulirovku ot kriteriyev proverki i granic. V chastnosti, polnyij interfejs nachinayetsya posle zapuska poljzovateljskoj sessii i ne podmenyayet zagruzochnuyu cepochku Apple; avtomaticheskij vkhod trebuyet otdeljnoj modeli ugroz; zhyostkij kiosk zadayotsya kak uslovnaya vozmozhnostj dlya upravlyayemogo ustrojstva.

## Resheniye po avtomatizacii

Pervyij nabor oformlen vruchnuyu po yedinomu shablonu. Otdeljnaya avtomatizaciya poka ne sozdana, chtobyi ne zakreplyatj skhemu po odnomu primeru. Posle vtorogo nabora kartochek predlagayetsya TDD-proverka dopustimogo emodzi v imeni, obyazateljnyikh razdelov, soglasovannosti statusa i polnotyi indeksa.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [razdel trebovanij](../../Trebovaniya/README.md)
- [kartochka trebovaniya FUM](../../Glossarij/kartochka-trebovaniya-FUM.md)
- [status trebovaniya FUM](../../Glossarij/status-trebovaniya-FUM.md)
- [arkhivirovannyij istochnik](../../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/source-index.md)
- [pravila repozitoriya](../../AGENTS.md)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Lokaljnaya avtomatizaciya izvlekla 10 soobsjhenij dialoga i sokhranila syiroj, strukturnyij i chelovekochitayemyij sloi istochnika.
- Vruchnuyu proverenyi semj imyon kartochek, sootvetstviye statusa v imeni i tele, obyazateljnyiye razdelyi i ssyilki proiskhozhdeniya.
- Planovyij reyestr peresobran i validirovan; recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian obnovlenyi.
- `git diff --check` i `fum-session-coherence` zavershilisj uspeshno.
- Polnyij `fum-smoke-check` proshyol 14 shagov: 69 testov devyati lokaljnyikh avtomatizacij, sborku i proverku planovogo reyestra, proverki recency, grafa Obsidian i svyaznosti tekusjhej sessii.

## Istochniki

- [iskhodnyij zapros 2026-07-14 20:33:47 MSK](zapros.md)
- [dialog «Zapusk kastomnogo interfejsa»](../../Istochniki/URL/https/chatgpt.com/share/6a5664cd-4838-83eb-9da3-60f7f5d22566/zapusk-kastomnogo-interfejsa.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:41ca6b0b7b9caccc019a79a74e0ca2c55aa6de6c38504a31dd836fe2693d98f8 -->
<!-- FUM-MD-RECENCY:END -->
