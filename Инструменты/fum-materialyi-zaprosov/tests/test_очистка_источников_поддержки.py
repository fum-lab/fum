"""Синтетические формы служебных значений, замеченные при реестре поддержки."""
from pathlib import Path
import sys
import gzip
import hashlib
import json
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import source_archive as архив


class ОчисткаИсточников(unittest.TestCase):
    def test_сжатый_документ_отклоняется_после_распаковки(сам):
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(адрес_источника, файл_тела, путь_заголовков):
                файл_тела.write_bytes(gzip.compress(b'%PDF-1.7\nsynthetic'))
                путь_заголовков.write_text('Content-Type: text/html\nContent-Encoding: gzip\n')
                return {'http_code': '200', 'content_type': 'text/html'}
            with сам.assertRaisesRegex(ValueError, 'PDF'):
                архив.build_snapshot(Path(каталог), 'https://example.org/document', транспорт)
            сам.assertEqual(list(Path(каталог).iterdir()), [])

    def test_диагностический_идентификатор_страницы_блокировки(сам):
        тело = '<h1>Ваш запрос заблокирован системой защиты компании MYRTEX.</h1><p>Обратитесь в техническую поддержку, указав ID запроса: synthetic-private-id</p><p>Срок приёма: 2026-10-01</p>'
        итог = архив.очистить_служебную_разметку(тело)
        сам.assertNotIn('synthetic-private-id', итог)
        сам.assertIn('2026-10-01', итог)
        сам.assertEqual(итог, архив.очистить_служебную_разметку(итог))
        описание = '<p>В публичном примере, указав ID запроса: example-public-id</p>'
        сам.assertEqual(архив.очистить_служебную_разметку(описание), описание)

    def test_сжатое_тело_распаковывается_перед_очисткой(сам):
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(адрес_источника, файл_тела, путь_заголовков):
                файл_тела.write_bytes(gzip.compress(b'<title>Conditions</title><input name="csrftoken" value="synthetic-private"><p>Public terms</p>'))
                путь_заголовков.write_text('Content-Type: text/html\nContent-Encoding: gzip\n')
                return {"http_code": "200"}
            архив.build_snapshot(Path(каталог), 'https://example.org/terms', транспорт)
            сохранено = (Path(каталог) / 'response.body.html').read_bytes()
            сам.assertTrue(сохранено.startswith(b'<title>'))
            сам.assertNotIn(b'synthetic-private', сохранено)
            сам.assertIn('Public terms', (Path(каталог) / 'extracted-text.md').read_text())

    def test_очистка_сохраняет_нетронутые_байты_другой_кодировки(сам):
        тело = b'<title>Source</title>\xff\xfe<input name="csrftoken" value="synthetic-private">'
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(адрес_источника, файл_тела, путь_заголовков):
                файл_тела.write_bytes(тело)
                путь_заголовков.write_text('Content-Type: text/html\n')
                return {"http_code": "200"}
            архив.build_snapshot(Path(каталог), 'https://example.org/conditions', транспорт)
            сохранено = (Path(каталог) / 'response.body.html').read_bytes()
            сам.assertIn(b'\xff\xfe', сохранено)
            сам.assertNotIn(b'synthetic-private', сохранено)

    def test_содержательная_дата_не_является_диагностикой(сам):
        тело = '<time data-testid="timestamp">2026-09-11</time>'
        сам.assertEqual(архив.очистить_служебную_разметку(тело), тело)

    def test_документ_не_сохраняется_как_разметка(сам):
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(адрес_источника, файл_тела, путь_заголовков):
                файл_тела.write_bytes(b'%PDF-1.7\nsynthetic')
                путь_заголовков.write_text('Content-Type: application/pdf\n')
                return {"http_code": "200", "content_type": "application/pdf"}
            with сам.assertRaisesRegex(ValueError, "PDF"):
                архив.build_snapshot(Path(каталог), 'https://example.org/document', транспорт)
            сам.assertEqual(list(Path(каталог).iterdir()), [])

    def test_переархивация_родителя_сохраняет_вложенный_адрес(сам):
        with tempfile.TemporaryDirectory() as каталог:
            каталог = Path(каталог)
            текущий = каталог / "родитель"
            текущий.mkdir()
            def транспорт(адрес_источника, файл_тела, путь_заголовков):
                файл_тела.write_text('<title>Условия</title><p>' + адрес_источника + '</p>')
                путь_заголовков.write_text('HTTP/2 200\n')
                return {"http_code": "200"}
            архив.build_snapshot(текущий, 'https://example.org/parent', транспорт)
            дочерний = текущий / "docs/terms"
            дочерний.mkdir(parents=True)
            архив.build_snapshot(дочерний, 'https://example.org/parent/docs/terms', транспорт)
            до = {п.name: п.read_bytes() for п in дочерний.iterdir()}
            новый = каталог / "новый"
            новый.mkdir()
            архив.build_snapshot(новый, 'https://example.org/parent', транспорт)
            архив.install_snapshot(новый, текущий)
            сам.assertTrue(дочерний.is_dir(), 'Утрачен отдельный дочерний URL-снимок')
            сам.assertEqual({п.name: п.read_bytes() for п in дочерний.iterdir()}, до)
            архив.validate_snapshot_manifest(текущий)
            архив.validate_snapshot_manifest(дочерний)
            (дочерний / архив.SNAPSHOT_MANIFEST_NAME).unlink()
            состояние = {str(п.relative_to(текущий)): п.read_bytes() for п in текущий.rglob('*') if п.is_file()}
            третий = каталог / 'третий'
            третий.mkdir()
            архив.build_snapshot(третий, 'https://example.org/parent', транспорт)
            with сам.assertRaises(ValueError):
                архив.install_snapshot(третий, текущий)
            сам.assertEqual({str(п.relative_to(текущий)): п.read_bytes() for п in текущий.rglob('*') if п.is_file()}, состояние)

    def test_новое_чтение_сохраняет_исторические_байты_того_же_адреса(сам):
        with tempfile.TemporaryDirectory() as каталог:
            каталог = Path(каталог)
            текущий, новый = каталог / "родитель", каталог / "новый"
            текущий.mkdir()
            новый.mkdir()
            адрес_источника = "https://example.org/conditions"
            def транспорт(адрес_источника, файл_тела, путь_заголовков):
                файл_тела.write_text("<title>Условия</title><p>" + содержание + "</p>")
                путь_заголовков.write_text("HTTP/2 200\n")
                return {"http_code": "200"}
            содержание = "Прежние условия"
            архив.build_snapshot(текущий, адрес_источника, транспорт)
            текст = (текущий / "extracted-text.md").read_bytes()
            хэш = hashlib.sha256(текст).hexdigest()
            снимок = текущий / "свидетельства" / хэш
            снимок.mkdir(parents=True)
            (снимок / "извлечённый-текст.txt").write_bytes(текст)
            (снимок / "source-url.txt").write_text(адрес_источника + "\n")
            архив.write_snapshot_manifest(снимок, sorted(set(архив.snapshot_relative_files(снимок)) | {архив.SNAPSHOT_MANIFEST_NAME}))
            до = {п.name: п.read_bytes() for п in снимок.iterdir()}
            содержание = "Новые условия"
            архив.build_snapshot(новый, адрес_источника, транспорт)
            архив.install_snapshot(новый, текущий)
            сам.assertIn(содержание, (текущий / "extracted-text.md").read_text())
            сам.assertEqual(до, {п.name: п.read_bytes() for п in снимок.iterdir()})
            сам.assertEqual(хэш, hashlib.sha256((снимок / "извлечённый-текст.txt").read_bytes()).hexdigest())
            for путь in (текущий, снимок):
                архив.validate_snapshot_manifest(путь)
                архив.ensure_destination_matches_url(путь, адрес_источника)
            имена = json.loads((текущий / архив.SNAPSHOT_MANIFEST_NAME).read_text())["managed_files"]
            сам.assertFalse(any(имя.startswith("свидетельства/") for имя in имена))

    def test_диагностические_поля_страницы_проверки(сам):
        путь_проверки = архив.urlsplit("https://example.org/checkcaptcha").path
        тело = f'<div class="Container"><form id="checkbox-captcha-form" method="POST" action="{путь_проверки}"><input name="pdata" value="synthetic-private-data"><div class="CheckboxCaptcha" data-testid="checkbox-captcha"></div></form><span data-testid="unique-key">synthetic-private-key</span><span data-testid="timestamp">1789112345</span></div><span data-testid="timestamp">2026-09-11</span>'
        итог = архив.очистить_служебную_разметку(тело)
        сам.assertNotIn('synthetic-private', итог)
        сам.assertNotIn('1789112345', итог)
        сам.assertIn('2026-09-11', итог)

    def test_заголовки_токенов_и_трассировки(сам):
        for имя in ("X-XSRF-Token", "X-CSRF-Token", "X-Trace-Id", "X-Correlation-Id", "X-SP-CRID", "X-Tracking-Ref", "CDNUUID", "x-yandex-eu-request"):
            результат = архив.redact_headers(имя + ": synthetic-private\r\n folded-private\r\nContent-Type: text/html\r\n")
            сам.assertNotIn("private", результат)
            сам.assertIn("Content-Type", результат)

    def test_диагностика_одноразового_значения_и_незакавыченное_поле(сам):
        тело = '''<input name="csrftoken" value=synthetic-private-a><script nonce="synthetic-private-n">{"wgRequestId":"synthetic-private-id"}</script><div>Ваш IP-адрес:<div class=info-value><div id=q>192.0.2.13</div></div></div><div>Ваш ID запроса к ресурсу:<div class=info-value>synthetic-private-request</div></div>'''
        результат = архив.очистить_служебную_разметку(тело)
        сам.assertNotIn("synthetic-private", результат)
        сам.assertNotIn("192.0.2.13", результат)
        сам.assertEqual(результат, архив.очистить_служебную_разметку(результат))
        заголовок = архив.redact_headers("Content-Security-Policy: default-src 'self'; script-src 'nonce-synthetic-private'; img-src https:\n")
        сам.assertNotIn("synthetic-private", заголовок)
        сам.assertIn("img-src https:", заголовок)

    def test_тело_очищается_до_извлечения_и_повтор_не_меняет_байты(сам):
        тело = '''<title>Условия</title><input type="hidden" name="csrftoken" value="synthetic-private-a"><script>var state={"csrf":{"token":"synthetic-private-b"},"csrfToken":"synthetic-private-c"};</script><p>Your IP: 192.0.2.13</p><p>Открытый DNS: 8.8.8.8; документы 2026 года.</p>'''
        with tempfile.TemporaryDirectory() as каталог:
            каталог = Path(каталог)
            def транспорт(адрес, путь_тела, заголовки):
                путь_тела.write_text(тело)
                заголовки.write_text("HTTP/2 200\nX-XSRF-Token: synthetic-private-h\n")
                return {"transport": "открытая фикстура", "http_code": "200"}
            архив.build_snapshot(каталог, "https://example.org/rules", транспорт)
            сохранено = (каталог / "response.body.html").read_text()
            сам.assertNotIn("synthetic-private", сохранено)
            сам.assertNotIn("192.0.2.13", сохранено)
            сам.assertIn("8.8.8.8", сохранено)
            сам.assertEqual(архив.очистить_служебную_разметку(сохранено), сохранено)
            сам.assertNotIn("192.0.2.13", (каталог / "extracted-text.md").read_text())


if __name__ == "__main__":
    unittest.main()
