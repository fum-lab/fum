# Otchyot 2026-06-26 10:47:01 MSK

## Glavnoye

V [pamyati FUM](../../Glossarij/pamyatj-FUM.md) yavno razvedenyi [interfejs FUM-uzla](../../Glossarij/interfejs-FUM-uzla.md) i [MCP-server](../../Glossarij/MCP-server.md). Interfejs FUM-uzla opisyivayet vsyu granicu nablyudeniya, smyisla, dejstviya, dostupa i proiskhozhdeniya uzla, a MCP-server opisyivayet mashinnyij dostup k konkretnomu servisu ili srede vnutri vneshnego interfejsa.

## Chto izmenilosj

- V dokumente [Interfejs FUM-uzla](../../Dokumentaciya/25-interfejs-FUM-uzla.md) dobavlen razdel ob otlichii interfejsa ot MCP s prakticheskoj tablicej razlichij.
- Glossarnyiye statji [Interfejs FUM-uzla](../../Glossarij/interfejs-FUM-uzla.md) i [MCP-server](../../Glossarij/MCP-server.md) utochnenyi tak, chtobyi MCP ne smeshivalsya s celostnyim interfejsom FUM.
- Dokument [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../../Dokumentaciya/19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md) teperj pryamo govorit, chto MCP-server yavlyayetsya servisnyim organom, a ne zamenoj interfejsa FUM-uzla.
- Spisok [predlozhenij o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) utochnyon: budusjhij pasport interfejsa dolzhen fiksirovatj otlichiye ot MCP-serverov.

## Resheniya

MCP zakreplyon kak poleznyij i proveryayemyij sposob podklyuchatj servisnyiye vozmozhnosti k FUM, no ne kak arkhitekturnaya obolochka vsego uzla. Polnocennyij interfejs FUM dolzhen svyazyivatj servisnyiye vyizovyi s pamyatjyu, poljzovateljskim namereniyem, podtverzhdeniyami, [urovnyami dostupa](../../Glossarij/urovenj-dostupa.md), trassami, proiskhozhdeniyem i peredachej rezuljtata.

## Proverki

- `git diff --check` - proshlo bez zamechanij.
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-06-26_10-47-01_MSK.md` - proshlo.

## Vozmozhnyiye prodolzheniya

Sleduyusjhij prakticheskij shag ostayotsya tem zhe: opisatj minimaljnyij pasport tekusjhego kontura chelovek - Codex - Obsidian-khranilisjhe i yavno pokazatj v nyom, gde prokhodyat poljzovateljskij, vnutrennij, fajlovyij, instrumentaljnyij i MCP-podobnyij servisnyij konturyi.

## Istochniki

- [iskhodnyij zapros 2026-06-26 10:47:01 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:48c4eb140be7a23b6e862ed583ffcef6aecde06dc647a6e77ac935b0a4f95122 -->
<!-- FUM-MD-RECENCY:END -->
