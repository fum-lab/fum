# Отчёт об извлечении прикрепляемого материала

- Источник: https://github.com/fum-lab/fum/issues/27
- Время извлечения UTC: 2026-10-03T17:18:18.502937+00:00
- Транспорт: curl
- Effective URL: https://github.com/fum-lab/fum/issues/27
- HTTP-код: 200
- Content-Type: text/html; charset=utf-8
- Размер загрузки: 285985 байт
- Извлечено блоков JSON-LD: 1

## Редакции перед сохранением

- Ответ с сигнатурой gzip распаковывается до определения формата и очистки; HTML-файл содержит распакованное очищенное представление, а HTTP-заголовки описывают исходный ответ.
- Значения `Set-Cookie` в HTTP-заголовках заменены на `[REDACTED: response cookie]`.
- Значения `CF-Ray`, `X-Request-ID`, `Request-Context`, `X-MS-Middleware-Request-ID` заменены на `[REDACTED: response trace identifier]`; продолжения очищаемых заголовков удалены.
- Дополнительно очищены X-XSRF-Token, X-CSRF-Token, X-Trace-Id, Trace-Id, X-Forwarded-For, X-Correlation-Id, X-SP-CRID, X-Tracking-Ref, CDNUUID, x-yandex-eu-request и nonce директив CSP.
- Из HTTP-заголовков удалены дополнительные идентификаторы трассировки и метаданные страны и устройства запроса; продолжения этих заголовков удалены.
- Значения Server-Timing, Report-To и Reporting-Endpoints удалены; одноразовый параметр code скрыт в Location и Effective URL без изменения других параметров адреса.
- В блоке script с id app-config очищен служебный websocket.token; видимый текст документа сохраняется.
- До извлечения очищены известные CSRF/XSRF-поля HTML и встроенного JSON, nonce атрибутов, wgRequestId, адрес и ID запроса в диагностическом блоке, поле pdata и диагностические data-testid unique-key/timestamp. Прочее содержимое сохранено без перевода; это ограниченная редакция известных полей, а не гарантия отсутствия всех возможных секретов.
- В блоках script очищены известные JSON-поля идентификаторов посетителя, nonce, запроса и токенов загрузки; в meta очищены точные служебные nonce, request-id и visitor-поля. Содержательный текст сохранён.
- Телеметрия YouTube и токен continuationCommand очищены в script; подписи GitHub очищены в HTML-атрибуте и script, _csrf — в адресе HTML-атрибута. Снимок не предназначен для повторения сеансового запроса продолжения.

## Ограничения извлечения

- Ошибок разбора JSON-LD не обнаружено.

## Сохранённые файлы

- `extracted-text.md`
- `extraction-report.md`
- `response.body.html`
- `response.headers.txt`
- `snapshot-manifest.json`
- `source-index.md`
- `source-url.txt`
- `structured-data.json`

## Поздняя публикационная коррекция при приёмке ROOT

При приёмке ветки в новом этапе, начатом 2026-10-04 23:48:13 MSK, сохранённый заголовок `x-github-edge-region` очищен штатной чистой функцией `redact_headers` из `source_archive.py`. Исходная загрузка от 3 октября, HTTP-код, размер ответа, тело, извлечённый текст и структурные данные не пересоздавались; сетевого запроса не было. Это редакция публикуемого снимка, а не обновление условий или новая проверка получателя. Точные исходный коммит, хэши заголовков и реализации сохранены в [материале нового этапа](../../../../../../../../Журнал/2026-10-04_23-48-13_MSK_принять-разбор-ресурсных-маршрутов/материалы/поздняя-редакция-заголовков.json).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-10-05 00:02:29 MSK -->
<!-- content-sha256: sha256:c75604a73c30100b4743ef4fc98c18ff9c376c0743aecec0c03ab5d2aa18ed23 -->
<!-- FUM-MD-RECENCY:END -->
