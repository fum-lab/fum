# Porucheniye o Linux na macOS

Chetyire vyibrannyiye zapisi iskhodnoj zadachi. Eto sokhranyonnyiye komanda, vyibor i otvetyi, a ne polnyij nepreryivnyij dialog ili dokazateljstvo ispolneniya. Iskhodnyiye tekstyi i okonchaniya soobsjhenij sokhranenyi bez normalizacii.

## 1. Poljzovatelj — 2026-09-11T09:29:12.456Z

````text
Sdelaj avtomatizaciyu nastrojki Linux okruzheniya na macOS.

````

## 2. Otvet koordinatora — 2026-09-11T09:29:35.186Z

````text
Сделаю это как воспроизводимую автоматизацию: проверка Mac, подготовка Linux, установка зависимостей FUM и проверка готовности с журналом и измерениями. Сначала сверю существующие наработки и выберу способ запуска Linux; сравнение UTF-8 и интеграция веток продолжатся параллельно.

````

## 3. Poljzovatelj — 2026-09-11T09:31:36.161Z

Vopros interfejsa:

````text
Для Linux на macOS нужна полноценная виртуальная машина или достаточно контейнера? Для работы с системными возможностями FUMA предлагаю виртуальную машину; контейнер подходит для сборок и тестов.
````

Tochnyij vyibrannyij otvet:

````text
Виртуальная машина Linux (рекомендуется)
````

## 4. Otvet koordinatora — 2026-09-11T09:31:45.170Z

````text
Принято: полноценная виртуальная машина Linux. Проверяю вариант на Swift с Virtualization.framework и готовлю отдельную постановку для реализации. В неё войдут первичная настройка, повторный запуск и восстановление после прерывания.

````

## Proiskhozhdeniye i izvlecheniye

[Mashinnyij sloj](soobsjheniya.json) khranit roli, iskhodnyij poryadok, vremena, poluotkryityiye bajtovyiye diapazonyi i SHA-256 chetyiryokh strok s LF. Oni sverenyi chteniyem pervichnogo JSONL zadachi 01a07d3d-d376-7ad2-aafc-67e4c25a67eb. Iskhodnaya komanda podtverzhdena annotaciyej user.text; vyibor VM poluchen iz strukturirovannogo otveta interfejsa. Iz nego vzyatyi tochnyiye znacheniya question i answer bez sluzhebnogo questionItemId. Obolochka interfejsa ne prevrasjhena v dopolniteljnuyu komandu.

Polnyiye syiroj JSONL, chetyire iskhodnyiye stroki i chastnyij kursor ostayutsya vne checkout. V publichnyij sloj ne vklyuchenyi skryityiye rassuzhdeniya, identifikatoryi soobsjhenij i vyizovov, sluzhebnyiye metadannyiye i mashinno-lokaljnyiye puti. Tekstyi komandyi i otvetov ne redaktirovalisj. [Tekusjhij zapros](../../../zapros.md) svyazyivayet istochnik s ogranichennoj postanovkoj.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 12:48:32 MSK -->
<!-- content-sha256: sha256:a1548c8654d73efd3be898c18d20859f1200ac862fd5b1a7fdd535f5caeeeb21 -->
<!-- FUM-MD-RECENCY:END -->
