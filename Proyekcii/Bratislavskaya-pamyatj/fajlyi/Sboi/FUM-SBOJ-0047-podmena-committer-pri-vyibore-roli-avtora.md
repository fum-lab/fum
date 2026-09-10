+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0047"
"статус" = "устранена"
+++
# Podmena committer pri vyibore roli avtora

Pri vyibore roli avtora agent pereopredelil obsjheye `user.name` na odin vyizov commit. Git primenil eto imya takzhe k committer, khotya pravilo trebovalo sokhranitj yego iskhodnyiye dannyiye. Ustraneniye ogranicheno proveryayemoj proceduroj sozdaniya posleduyusjhikh kommitov; opublikovannaya istoriya ne perepisyivalasj.

## Proyavleniya i granica povtoreniya

- `FUM-СБОЙ-0047/ПРОЯВЛЕНИЕ-0001`: kommit `4a721b84f923b6555dbc7028b9178a54b02bf8d9` sozdan cherez `git -c user.name='FUM Писатель' commit`. Fakticheskoye imya committer — `FUM Писатель`, iskhodnoye — `FUM`; author ozhidayemo `FUM Писатель`, email ne menyalsya. [Pervichnoye priznaniye oshibki](../Zhurnal/2026-09-11_00-56-27_MSK_sokhranitj-dialog-o-nauchnyikh-napravleniyakh/otchyot.md).

Obsjhaya granica — izmeneniye committer vmeste s vyiborom avtorskoj roli. Ona ne obyyedinyayet oshibki soobsjheniya kommita, trailer ili vetki.

## Vosstanovleniye i sistemnaya mera

Rolj zadayotsya toljko `GIT_AUTHOR_NAME`. Pered commit chitayutsya i sravnivayutsya `git var GIT_AUTHOR_IDENT` i `git var GIT_COMMITTER_IDENT`, posle — fakticheskiye author/committer iz novogo commit. Etot poryadok dobavlen v susjhestvuyusjheye pravilo `FUM-ПРАВИЛО-000063`. Procedura trebuyet ispolneniya agentom; ustanovlennyij Git hook ili mashinnyij zapret vsekh nepraviljnyikh vyizovov ne zayavlyayetsya.

## Kriterij zakryitiya

Utochneniye kanonicheskoj normyi i proverennyij sleduyusjhij kommit dolzhnyi podtverditj vyibor roli bez izmeneniya iskhodnogo committer i oboikh email. Predyidusjhaya oshibka ostayotsya v istorii s yavnyim proiskhozhdeniyem.

## Podtverzhdeniye ustraneniya

Pered vtoryim kommitom neposredstvenno nablyudalisj author `FUM Писатель` i committer `FUM`, oba s prezhnim email. Kommit `d1cc68502ec8a68b36cd41e7be0105dbf2af7064`, sozdannyij s odnim `GIT_AUTHOR_NAME`, prochitan posle zapisi: author `FUM Писатель`, committer `FUM`, email oboikh `fum@local`. Takim obrazom ogranichennoye procedurnoye vosstanovleniye provereno na realjnom posledovateljnom kommite. Perepisyivaniye pervogo kommita ne vyipolnyalosj.

## Svyazannyiye shagi

Ogranichennaya mera zavershena v etoj rabote; otdeljnyij ispolnyayemyij mekhanizm ne razrabatyivalsya i yego gotovnostj ne zayavlyayetsya.

## Istochniki

- [Tekusjhij zapros](../Zhurnal/2026-09-11_00-59-45_MSK_zakrepitj-posledovateljnuyu-istoriyu-dialoga-fuma/zapros.md).
- [Pravilo identichnosti Git](../Pravila/agentov/Git-i-rabochaya-sessiya.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 01:08:05 MSK -->
<!-- content-sha256: sha256:b141de276b8727f5f2fc974335fc94a54edeb932f8bd1b29a653d8fc6ee298e6 -->
<!-- FUM-MD-RECENCY:END -->
