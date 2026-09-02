---
name: fum-glossarij
description: Kanonicheskij lokaljnyij navyik dlya podderzhki glossariya FUM v etom repozitorii.
metadata:
  short-description: Podderzhivatj glossarij FUM
---

# FUM Glossary

Etot kanonicheskij lokaljnyij navyik ispoljzuyetsya pri dobavlenii, pereimenovanii, razdelenii ili obnovlenii terminov v glossarii repozitoriya FUM.

Dlya takoj rabotyi ispoljzuyutsya toljko eta instrukciya, `AGENTS.md` i materialyi tekusjhego checkout. Navyiki za predelami repozitoriya ne otkryivayutsya dazhe dlya proverki primenimosti ili sravneniya.

## Fajlyi

- Indeks: `Глоссарий/README.md` ot kornya tekusjhego checkout.
- Katalog statej: `Глоссарий/` ot kornya tekusjhego checkout.
- Odin termin khranitsya v odnom Markdown-fajle.

## Rabochij poryadok

1. Pered izmeneniyami perejti v korenj tekusjhego checkout, proveryayemyij cherez `git rev-parse --show-toplevel`, i vyipolnitj `git status --short`.
2. Sozdatj ili obnovitj fajl statji v `Глоссарий/`.
3. Nachinatj kazhduyu statjyu s zagolovka `# <Термин>`.
4. Derzhatj statjyu korotkoj i dokumentacionnoj: snachala znacheniye termina v FUM, zatem vneshniye ili istoricheskiye primechaniya, yesli oni nuzhnyi.
5. Dobavitj ili obnovitj ssyilku v `Глоссарий/README.md`.
6. Sokhranyatj alfavitnyij poryadok ssyilok v razdele terminov, yesli lokaljnyij poryadok ne trebuyet drugogo.
7. Sokhranyatj susjhestvuyusjhiye terminyi, yesli poljzovatelj yavno ne prosit perepisatj, razdelitj ili udalitj ikh.
8. Pri izmenenii proizvodnoj dokumentacii rasstavlyatj ssyilki na kazhdoye soderzhateljnoye upotrebleniye uzhe zavedyonnogo termina, yesli ssyilka pomogayet vosstanovitj smyisl.
9. Ssyilatj sklonyayemyiye formyi terminov po praviljnoj forme v tekste, no vesti ikh na fajl statji termina v imeniteljnom padezhe.
10. Kommititj toljko osmyislennyiye izmeneniya tekusjhej sessii i ne vklyuchatj postoronniye gryaznyiye fajlyi.

## Imena fajlov

Imena fajlov statej glossariya podchinyayutsya pravilam `AGENTS.md`: russkiye slova i opisaniya pishutsya kirillicej.

- `Сознание` -> `сознание.md`
- `Орган FUM` -> `орган-FUM.md`
- `Фоновый авто-коммит памяти` -> `фоновый-авто-коммит-памяти.md`
- `FUM` -> `FUM.md`
- `FUM-узел` -> `FUM-узел.md`

Ispoljzuj defisyi mezhdu slovami i rasshireniye `.md`. Ne ispoljzuj ASCII-transliteraciyu dlya russkikh slov. Nazvaniye `FUM`, tekhnicheskiye identifikatoryi, komandyi, formatyi i abbreviaturyi sokhranyayutsya v ikh prinyatom napisanii.

Yesli termin uzhe svyazan iz `Глоссарий/README.md`, ispoljzuj susjhestvuyusjheye kirillicheskoye imya fajla, yesli poljzovatelj ne poprosil pereimenovatj yego.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-23 15:26:35 MSK — Zapretitj vneshniye navyiki v repozitorii](../../Zhurnal/2026-07-23_15-26-35_MSK_zapretitj-vneshniye-navyiki-v-repozitorii/zapros.md)
- [iskhodnyij zapros 2026-07-22 13:39:29 MSK — Ustranitj mashinno-lokaljnyiye puti](../../Zhurnal/2026-07-22_13-39-29_MSK_ustranitj-mashinno-lokaljnyiye-puti/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:ddd18a43c39b05d73ba2615850dc0d1d848c688d1cbd8191eedc26ce864fa68d -->
<!-- FUM-MD-RECENCY:END -->
