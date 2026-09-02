# Otchyot 2026-07-16 21:49:27 MSK - Tipizirovatj semanticheskiye svyazi trebovanij

Semj [kartochek trebovanij FUM](../../Glossarij/kartochka-trebovaniya-FUM.md) preobrazovanyi iz nabora neformaljnyikh perekhodov v dvunapravlennyij tipizirovannyij graf. Vosemj soderzhateljnyikh faktov predstavlenyi shestnadcatjyu soglasovannyimi zapisyami: `зависит от / требуется для`, `является частью / состоит из`, `дополняет / дополняется` i `усиливает / усиливается`.

Kazhdaya kartochka poluchila razdel `Семантические связи`, gde odna stroka khranit odin tip, ssyilku na celevuyu kartochku i kratkoye osnovaniye. Minimaljnyij slovarj zakreplyon v indekse trebovanij; otnosheniya bez tekusjhego soderzhateljnogo primera ne dobavlyalisj. Novyij glossarnyij termin otdelyayet tipizirovannuyu svyazj trebovanij ot obyichnoj tematicheskoj Markdown-ssyilki.

## Resheniye po avtomatizacii

Format podgotovlen k mashinnoj proverke. Uzhe zaplanirovannyij validator kartochek posle poyavleniya vtorogo nabora dolzhen proveryatj dopustimostj tipov, razreshimostj celej i tochnuyu obratnuyu svyazj, sokhranyaya smyislovoj vyibor za chelovekom ili agentom.

## Zatronutyiye materialyi

- [iskhodnyij zapros](zapros.md)
- [semanticheskaya svyazj trebovanij FUM](../../Glossarij/semanticheskaya-svyazj-trebovanij-FUM.md)
- [indeks i slovarj otnoshenij](../../Trebovaniya/README.md)
- [semj kartochek trebovanij k interfejsu](../../Trebovaniya/README.md#polnostjyu-kastomnyij-interfejs-poverkh-macos)
- [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md)

## Proverki

- Vruchnuyu sopostavlenyi vosemj pryamyikh i vosemj obratnyikh zapisej.
- Planovyij reyestr peresobran i provalidirovan; recency-metki, indeks Markdown-fajlov i teplovaya karta grafa Obsidian obnovlenyi.
- `git diff --check`, `fum-session-coherence` i polnyij `fum-smoke-check` zavershilisj uspeshno.

## Istochniki

- [iskhodnyij zapros 2026-07-16 21:49:27 MSK](zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:b8694641bfd6e9737adac8b02b044e8832dd6cb6e8aed0c3bac3356dba92ebb6 -->
<!-- FUM-MD-RECENCY:END -->
