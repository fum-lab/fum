# Otchyot 2026-06-25 19:34:12 MSK

## Glavnoye

Tochechnoye resheniye o perenose bloka `Источники требований` vniz fajla zakrepleno kak postoyannoye pravilo oformleniya [proizvodnoj dokumentacii](../../Glossarij/proizvodnaya-dokumentaciya.md) v `Документация/`. Verkh dokumenta teperj dolzhen srazu pokazyivatj soderzhaniye, a spravochnyiye spiski proiskhozhdeniya ostayutsya vnizu.

## Chto izmenilosj

- V [AGENTS.md](../../AGENTS.md) dobavlen razdel `Оформление документации` s pravilom nizhnego razmesjheniya spravochnyikh blokov.
- V 23 fajlakh `Документация/` verkhniye bloki `Источники требований` perenesenyi v konec fajlov.
- V [Git-infrastrukture evolyucionnyikh cepochek FUM](../../Dokumentaciya/20-Git-infrastruktura-evolyucionnyikh-cepochek-FUM.md) vmeste s istochnikami vniz perenesyon spravochnyij blok `Внешний материал`.
- V [Arkhitekture FUM](../../Dokumentaciya/22-arkhitektura-FUM.md) vmeste s istochnikami vniz perenesyon spravochnyij blok `Опорные документы`.

## Resheniya

Pravilo sformulirovano dlya fajlov `Документация/`, potomu chto imenno etot katalog khranit osnovnuyu proizvodnuyu dokumentaciyu o FUM. Adresnyiye opisaniya ne peresobiralisj i ne redaktirovalisj vruchnuyu, tak kak dlya nikh v pravilakh repozitoriya dejstvuyet otdeljnyij poryadok cherez zakreplyonnyiye avtomatizacii.

Migraciya byila mekhanicheskoj: osnovnoj soderzhateljnyij tekst dokumentov ne perepisyivalsya, menyalosj toljko polozheniye spravochnyikh spiskov.

## Proverki

- `git diff --check` - proshlo bez zamechanij.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-25_19-34-12_MSK.md` - proshlo.

## Vozmozhnyiye prodolzheniya

Mozhno otdeljno reshitj, rasprostranyatj li takoj zhe nizhnij format spravochnyikh blokov na planovyiye materialyi i adresnyiye opisaniya, gde dejstvuyut svoi pravila obnovleniya i avtomatizacii.

## Istochniki

- [iskhodnyij zapros 2026-06-25 19:34:12 MSK](zapros.md)
- [iskhodnyij zapros 2026-06-25 19:23:10 MSK](../2026-06-25_19-23-10_MSK/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:4d30a10553be53804feb6bab02f856b064e77bd0d281a53ac847a8bd3a387c8a -->
<!-- FUM-MD-RECENCY:END -->
