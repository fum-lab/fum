# Vosproizvedeniye proverki perekhvata

Zapuskatj iz kornya sobstvennogo checkout cherez otchyotnuyu obyortku. Sleduyusjhiye komandyi ne ustanavlivayut hooks i ne menyayut Trust. Putj realjnogo guard peredayotsya yavno; yego iskhodniki i fiksturyi dolzhnyi sootvetstvovatj sokhranyonnyim khyesham integracii.

## Adresnyij nabor

```bash
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py запустить --корень-репозитория . --запрос Журнал/2026-09-09_12-13-51_MSK_разработать-перехват-завершения/запрос.md --название 'GREEN после штатного перевода имён тестов' --исполнитель 'Адаптер' --класс-проверки адресная --тайм-аут-секунды 30 -- python3 -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p test_перехват_завершения.py
```

Itog — 27 testov. Ranniye RED/GREEN ispoljzovali tot zhe nabor do posleduyusjhikh dopolnenij; otdeljnyij RED progressa vyibiral sootvetstvuyusjhij test. Neuspeshnyiye processyi i povtornyiye zapuski ne udalenyi iz mashinnogo zhurnala.

## Profilj

```bash
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py запустить --корень-репозитория . --запрос Журнал/2026-09-09_12-13-51_MSK_разработать-перехват-завершения/запрос.md --название 'Профиль перед фиксацией: уточнённая диагностика и русские имена' --исполнитель 'Адаптер' --класс-проверки адресная --тайм-аут-секунды 30 -- python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/измерить-перехват-завершения.py
```

Poluchennyij JSON sokhranyayetsya kak publikacionno chistoye svideteljstvo; on soderzhit toljko sinteticheskiye razmeryi, intervalyi, pamyatj, versiyu sredyi i khyeshi. Zapuski profilya ne dokazyivayut zaderzhku polnogo realjnogo guard.

## Mezhprocessnaya integraciya

Nizhe plejskholder zamenyayetsya absolyutnyim kornem proverennogo guard. Mashinno-lokaljnyij putj zdesj ne zakreplyayetsya.

```text
PYTHONDONTWRITEBYTECODE=1 python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py запустить --корень-репозитория . --запрос Журнал/2026-09-09_12-13-51_MSK_разработать-перехват-завершения/запрос.md --название 'Интеграция wire v2: шесть исходов и незакоммиченная граница' --исполнитель 'Адаптер' --класс-проверки адресная --тайм-аут-секунды 60 -- python3 Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-интеграцию-перехвата.py --корень-guard <абсолютный-корень-guard>
```

Itog — shestj uspeshnyikh scenariyev s proverkoj pryamogo iskhoda guard i otveta adaptera. Nativnoye podklyucheniye i nablyudeniye sleduyusjhego khoda vyipolnyayet koordinator otdeljno.

## Proiskhozhdeniye

- [Zapros](../zapros.md).
- [Otchyot](../otchyot.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-09 12:56:06 MSK -->
<!-- content-sha256: sha256:6df9ab5e00df09352073a2a0434fdfac4d7b7e8f6e16ab1ee6332ed7ee759e76 -->
<!-- FUM-MD-RECENCY:END -->
