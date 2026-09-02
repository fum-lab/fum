# Otchyot 2026-07-06 14:49:39 MSK - Opisatj iyerarkhiyu funkcij i dannyikh

Sessiya zafiksirovala novyij arkhitekturnyij princip ustojchivosti FUM: dannyiye menyayutsya byistreye funkcij, a funkcii mogut izmenyatjsya toljko cherez boleye bazovyiye funkcii, kotoryiye rassmatrivayut telo funkcii kak svoi dannyiye. Eto prevrasjhayet ideyu plastichnosti v mnogourovnevuyu proveryayemuyu konstrukciyu, a ne v rasplyivchatoye samoizmeneniye sistemyi.

## Chto izmenilosj

- V [glossarij](../../Glossarij/iyerarkhiya-funkcij-i-dannyikh-FUM.md) dobavlen termin "Iyerarkhiya funkcij i dannyikh FUM".
- V [arkhitekture FUM](../../Dokumentaciya/22-arkhitektura-FUM.md) princip dobavlen kak skvoznoj invariant: nuzhno khranitj proiskhozhdeniye funkcii, vkhodnyiye dannyiye, trassu primeneniya, kriterij izmeneniya i urovenj, kotoromu razresheno menyatj funkciyu.
- V [potokovoj samostrukturizacii](../../Dokumentaciya/32-potokovaya-samostrukturizaciya-FUM.md) opisana minimaljnaya trojka: funkciya urovnya `N`, dannyiye urovnya `N`, trassa i boleye bazovyij sloj, kotoryij reshayet, menyatj dannyiye, parametryi, telo funkcii ili pravila otbora.
- V [moduljnoj arkhitekture](../../Dokumentaciya/05-moduljnaya-arkhitektura-FUM.md), [agentskom cikle](../../Dokumentaciya/06-obzor-agentskikh-ciklov.md) i [evolyucionnom myishlenii](../../Dokumentaciya/03-evolyuciya-i-myishleniye.md) dobavlena granica mezhdu byistryimi vkhodami, ustojchivyimi funkciyami i boleye medlennyimi meta-funkciyami izmeneniya.
- V [predlozheniya o sleduyusjhikh shagakh](../../Planirovaniye/predlozheniya-o-sleduyusjhikh-shagakh.md) dobavlen minimaljnyij Swift-prototip dlya proverki etogo principa.

## Resheniye

Iyerarkhiya funkcij i dannyikh opisana kak iyerarkhiya tempov izmeneniya, a ne kak iyerarkhiya vlasti. Boleye bazovaya funkciya ne poluchayet proizvoljnogo prava perepisyivatj proizvodnuyu funkciyu: izmeneniye dolzhno prokhoditj cherez proiskhozhdeniye, proverku, byudzhet, kriterii poljzyi i otkat. Tak sokhranyayetsya svyazj s decentralizaciyej FUM i s kontroliruyemoj nejroplastichnostjyu.

## Proverki

- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py build --output Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-planning-registry/scripts/build-planning-registry.py validate --registry Планирование/реестр-требований-вариантов-и-кандидатов.json`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py`
- `python3 Инструменты/fum-md-recency/scripts/update-md-recency.py --check`
- `python3 Инструменты/fum-obsidian-graph-recency/scripts/build-obsidian-graph-recency.py --check`
- `git diff --check`
- `python3 Инструменты/fum-session-coherence/scripts/check-session-coherence.py --request Запросы/2026-07-06_14-49-39_MSK_описать-иерархию-функций-и-данных.md`
- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/2026-07-06_14-49-39_MSK_описать-иерархию-функций-и-данных.md`

## Vozmozhnoye prodolzheniye

Blizhajsheye prodolzheniye - minimaljnyij Swift-prototip: chistaya funkciya, vkhodnyiye dannyiye, parametryi, trassa poleznosti i meta-funkciya, kotoraya vyibirayet urovenj izmeneniya. On dolzhen pokazatj, mozhno li poluchitj prostoj bazovyij mekhanizm poiska reshenij bez prezhdevremennogo perekhoda k polnocennoj dinamicheskoj nejroseti.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-06 14:49:39 MSK - Opisatj iyerarkhiyu funkcij i dannyikh](zapros.md)


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:84a646132382d93d675d7753c902f7f56ff160e4071fe077d46d0c2e45cf8def -->
<!-- FUM-MD-RECENCY:END -->
