"""Синтетические формы служебных значений, замеченные при реестре поддержки."""
from pathlib import Path
import sys
import gzip
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import source_archive as архив


class ОчисткаИсточников(unittest.TestCase):
    def test_диагностический_ID_страницы_блокировки(self):
        тело = '<h1>Ваш запрос заблокирован системой защиты компании MYRTEX.</h1><p>Обратитесь в техническую поддержку, указав ID запроса: synthetic-private-id</p><p>Срок приёма: 2026-10-01</p>'
        итог = архив.очистить_служебный_html(тело)
        self.assertNotIn('synthetic-private-id', итог)
        self.assertIn('2026-10-01', итог)
        self.assertEqual(итог, архив.очистить_служебный_html(итог))
        описание = '<p>В публичном примере, указав ID запроса: example-public-id</p>'
        self.assertEqual(архив.очистить_служебный_html(описание), описание)

    def test_gzip_распаковывается_перед_очисткой(self):
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(url, body, headers):
                body.write_bytes(gzip.compress(b'<title>Conditions</title><input name="csrftoken" value="synthetic-private"><p>Public terms</p>'))
                headers.write_text('Content-Type: text/html\nContent-Encoding: gzip\n')
                return {"http_code": "200"}
            архив.build_snapshot(Path(каталог), 'https://example.org/terms', транспорт)
            сохранено = (Path(каталог) / 'response.body.html').read_bytes()
            self.assertTrue(сохранено.startswith(b'<title>'))
            self.assertNotIn(b'synthetic-private', сохранено)
            self.assertIn('Public terms', (Path(каталог) / 'extracted-text.md').read_text())

    def test_очистка_сохраняет_нетронутые_байты_другой_кодировки(self):
        тело = b'<title>Source</title>\xff\xfe<input name="csrftoken" value="synthetic-private">'
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(url, body, headers):
                body.write_bytes(тело)
                headers.write_text('Content-Type: text/html\n')
                return {"http_code": "200"}
            архив.build_snapshot(Path(каталог), 'https://example.org/conditions', транспорт)
            сохранено = (Path(каталог) / 'response.body.html').read_bytes()
            self.assertIn(b'\xff\xfe', сохранено)
            self.assertNotIn(b'synthetic-private', сохранено)

    def test_содержательная_дата_не_является_диагностикой(self):
        тело = '<time data-testid="timestamp">2026-09-11</time>'
        self.assertEqual(архив.очистить_служебный_html(тело), тело)

    def test_PDF_не_сохраняется_как_HTML(self):
        with tempfile.TemporaryDirectory() as каталог:
            def транспорт(url, body, headers):
                body.write_bytes(b'%PDF-1.7\nsynthetic')
                headers.write_text('Content-Type: application/pdf\n')
                return {"http_code": "200", "content_type": "application/pdf"}
            with self.assertRaisesRegex(ValueError, "PDF"):
                архив.build_snapshot(Path(каталог), 'https://example.org/document', транспорт)
            self.assertEqual(list(Path(каталог).iterdir()), [])

    def test_переархивация_родителя_сохраняет_вложенный_URL(self):
        with tempfile.TemporaryDirectory() as каталог:
            каталог = Path(каталог)
            текущий = каталог / "родитель"
            текущий.mkdir()
            def транспорт(url, body, headers):
                body.write_text('<title>Условия</title><p>' + url + '</p>')
                headers.write_text('HTTP/2 200\n')
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
            self.assertTrue(дочерний.is_dir(), 'Утрачен отдельный дочерний URL-снимок')
            self.assertEqual({п.name: п.read_bytes() for п in дочерний.iterdir()}, до)
            архив.validate_snapshot_manifest(текущий)
            архив.validate_snapshot_manifest(дочерний)
            (дочерний / архив.SNAPSHOT_MANIFEST_NAME).unlink()
            состояние = {str(п.relative_to(текущий)): п.read_bytes() for п in текущий.rglob('*') if п.is_file()}
            третий = каталог / 'третий'
            третий.mkdir()
            архив.build_snapshot(третий, 'https://example.org/parent', транспорт)
            with self.assertRaises(ValueError):
                архив.install_snapshot(третий, текущий)
            self.assertEqual({str(п.relative_to(текущий)): п.read_bytes() for п in текущий.rglob('*') if п.is_file()}, состояние)

    def test_диагностические_поля_страницы_проверки(self):
        тело = '<div class="Container"><form id="checkbox-captcha-form" method="POST" action="/checkcaptcha"><input name="pdata" value="synthetic-private-data"><div class="CheckboxCaptcha" data-testid="checkbox-captcha"></div></form><span data-testid="unique-key">synthetic-private-key</span><span data-testid="timestamp">1789112345</span></div><span data-testid="timestamp">2026-09-11</span>'
        итог = архив.очистить_служебный_html(тело)
        self.assertNotIn('synthetic-private', итог)
        self.assertNotIn('1789112345', итог)
        self.assertIn('2026-09-11', итог)

    def test_заголовки_токенов_и_трассировки(self):
        for имя in ("X-XSRF-Token", "X-CSRF-Token", "X-Trace-Id", "X-Correlation-Id", "X-SP-CRID", "X-Tracking-Ref", "CDNUUID", "x-yandex-eu-request"):
            результат = архив.redact_headers(имя + ": synthetic-private\r\n folded-private\r\nContent-Type: text/html\r\n")
            self.assertNotIn("private", результат)
            self.assertIn("Content-Type", результат)

    def test_диагностика_nonce_и_незакавыченное_поле(self):
        тело = '''<input name="csrftoken" value=synthetic-private-a><script nonce="synthetic-private-n">{"wgRequestId":"synthetic-private-id"}</script><div>Ваш IP-адрес:<div class=info-value><div id=q>192.0.2.13</div></div></div><div>Ваш ID запроса к ресурсу:<div class=info-value>synthetic-private-request</div></div>'''
        результат = архив.очистить_служебный_html(тело)
        self.assertNotIn("synthetic-private", результат)
        self.assertNotIn("192.0.2.13", результат)
        self.assertEqual(результат, архив.очистить_служебный_html(результат))
        заголовок = архив.redact_headers("Content-Security-Policy: default-src 'self'; script-src 'nonce-synthetic-private'; img-src https:\n")
        self.assertNotIn("synthetic-private", заголовок)
        self.assertIn("img-src https:", заголовок)

    def test_тело_очищается_до_извлечения_и_повтор_не_меняет_байты(self):
        тело = '''<title>Условия</title><input type="hidden" name="csrftoken" value="synthetic-private-a"><script>var state={"csrf":{"token":"synthetic-private-b"},"csrfToken":"synthetic-private-c"};</script><p>Your IP: 192.0.2.13</p><p>Открытый DNS: 8.8.8.8; документы 2026 года.</p>'''
        with tempfile.TemporaryDirectory() as каталог:
            каталог = Path(каталог)
            def транспорт(адрес, путь_тела, заголовки):
                путь_тела.write_text(тело)
                заголовки.write_text("HTTP/2 200\nX-XSRF-Token: synthetic-private-h\n")
                return {"transport": "открытая фикстура", "http_code": "200"}
            архив.build_snapshot(каталог, "https://example.org/rules", транспорт)
            сохранено = (каталог / "response.body.html").read_text()
            self.assertNotIn("synthetic-private", сохранено)
            self.assertNotIn("192.0.2.13", сохранено)
            self.assertIn("8.8.8.8", сохранено)
            self.assertEqual(архив.очистить_служебный_html(сохранено), сохранено)
            self.assertNotIn("192.0.2.13", (каталог / "extracted-text.md").read_text())


if __name__ == "__main__":
    unittest.main()
