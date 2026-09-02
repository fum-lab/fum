# Otchyot 2026-06-25 18:17:22 MSK

## Glavnoye

Kazhdoye [napravleniye proyektirovaniya i razvitiya FUM](../../Glossarij/napravleniye-proyektirovaniya-i-razvitiya-FUM.md) teperj svyazano s odnim blizhajshim proveryayemyim artefaktom. Eto prevrasjhayet sloj napravlenij iz obzornoj kartyi v prakticheskuyu razvyazku budusjhikh rabochikh sessij: dlya kazhdogo napravleniya vidno, kakoj sleduyusjhij fajl, shablon, progon ili pasport dolzhen poyavitjsya pervyim i kak proveritj, chto on dejstviteljno prodvinul proyekt.

## Chto izmenilosj

- V indekse [napravlenij proyektirovaniya i razvitiya](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/README.md) tablica napravlenij zamenena kartoj blizhajshikh artefaktov i proverok.
- V kazhdom iz vosjmi fajlov napravlenij dobavlen razdel `## Ближайший проверяемый артефакт`.
- V [predlozheniyakh o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) vyipolnennoye predlozheniye pereneseno v istoriyu, a aktualjnyiye predlozheniya razlozhenyi po konkretnyim blizhajshim artefaktam.

## Resheniya

Dlya kazhdogo napravleniya vyibran rovno odin blizhajshij artefakt, chtobyi planirovaniye ne raspadalosj na dlinnyiye spiski zhelateljnyikh rabot. Artefaktyi podobranyi tak, chtobyi ikh mozhno byilo proveritj lokaljno ili cherez yavno opisannuyu granicu vosproizvodimosti: progon arkhivirovaniya istochnika, smoke-check, trassa cikla, shablon scenariya, pasport adaptera, pasport peredavayemogo rezuljtata, kartochka eksperimenta i karta ogranichitelej fizicheskogo dejstviya.

Eta svyazka ne delayet sami artefaktyi uzhe realizovannyimi. Ona fiksiruyet blizhajshuyu proveryayemuyu tochku vkhoda dlya kazhdogo napravleniya i sokhranyayet obyichnuyu cepochku trebovanij: otdeljnyij artefakt dolzhen sozdavatjsya budusjhim zaprosom, proverkoj i kommitom.

## Proverki

- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-25_18-17-22_MSK.md` - proshlo.
- `git diff --check` - proshlo bez zamechanij.

## Vozmozhnyiye prodolzheniya

Ocheredj blizhajshikh rabot teperj chitayetsya iz [predlozhenij o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md): pervyim prakticheskim prodolzheniyem ostayotsya polnyij lokaljnyij progon arkhivirovaniya prikreplyayemogo materiala, a ostaljnyiye napravleniya poluchili sobstvennyiye proveryayemyiye vkhodyi.

## Istochniki

- [iskhodnyij zapros 2026-06-25 18:17:22 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:e80e51c6b55bc5515678d2cb7617955ca03b4dadbd778df886f041d3583bb8fd -->
<!-- FUM-MD-RECENCY:END -->
