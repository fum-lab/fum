+++
schema_version = 1
card_id = "FUM-STEP-0023"
status = "completed"
+++
# Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla

[Kartochka shaga](../../Glossarij/kartochka-shaga.md) sokhranyayet odin atomarnyij planovyij shag i yego proiskhozhdeniye otdeljno ot vetochnogo vyibora.

## Zadacha

Sformulirovatj minimaljnyij format trassyi ispolnyayemogo [agentskogo cikla](../../Glossarij/agentskij-cikl.md): nablyudeniye, zadacha, dejstviye, proverka, rezuljtat, oshibka i status prodolzheniya.

## Rezuljtat

Sozdana [specifikaciya minimaljnoj trassyi](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla.md) versii `1`: semj tipizirovannyikh JSONL-sobyitij sokhranyayut zadachu, nablyudeniye, dejstviye, rezuljtat, oshibku, proverku i resheniye o prodolzhenii bez skryityikh rassuzhdenij modeli. [Mashinnaya skhema](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/skhema-sobyitiya-v1.json) zakreplyayet tochnyiye polya, a [lokaljnaya fikstura](../../Dokumentaciya/37-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/fikstura-korotkoj-lokaljnoj-zadachi.jsonl) pokazyivayet vosstanovimuyu oshibku, prodolzheniye i proverennoye zaversheniye.

Lokaljnaya proverka podtverdila obyazateljnyiye polya i semj tipov sobyitij, nepreryivnuyu posledovateljnostj, svyazi dejstvij s iskhodami i proverkami, allowlist dejstviya, terminaljnyij status, otsutstviye polej skryitogo rassuzhdeniya i sootvetstviye rezuljtata statjye [«Agentskij cikl»](../../Glossarij/agentskij-cikl.md). Rezuljtat ogranichen formatom nablyudayemoj trassyi i read-only-fiksturoj: ispolnyayemyij runtime, vneshnij modeljnyij provajder, servisnyiye i fizicheskiye dejstviya ne realizovanyi i ne razreshenyi.

## Istochniki

- [napravleniye agentskogo cikla](../napravleniya-proyektirovaniya-i-razvitiya/03-agentskij-cikl-i-ispolnyayemyij-kontur.md), [MVP ispolnyayemogo agentskogo cikla](../MVP-kandidatyi/04-ispolnyayemyij-agentskij-cikl/README.md)
- [iskhodnyij zapros 2026-07-22 13:07:48 MSK — Sformulirovatj minimaljnyij format trassyi ispolnyayemogo agentskogo cikla](../../Zhurnal/2026-07-22_13-07-48_MSK_sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/zapros.md)
- [zhurnal rabochej sessii](../../Zhurnal/2026-07-22_13-07-48_MSK_sformulirovatj-minimaljnyij-format-trassyi-ispolnyayemogo-agentskogo-cikla/otchyot.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:9780961df43959d8b14e6e22fbaefd464a560eea01cdd908302c02ee79a91936 -->
<!-- FUM-MD-RECENCY:END -->
