import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import unittest

путь = Path(__file__).resolve().parents[1] / 'scripts' / 'proveritj-mashinno-lokaljnyiye-puti.py'
sys.path.insert(0, str(путь.parent))
спецификация = importlib.util.spec_from_file_location('сканер_обсуждений', путь)
сканер = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = сканер
спецификация.loader.exec_module(сканер)


class СырыеОбсуждения(unittest.TestCase):
    def запись(self):
        return {'id': 1, 'number': 1, 'title': 'Пример', 'body': '/дом/пример',
                'updated_at': '2026-10-05T00:00:00Z', 'state': 'open',
                'html_url': 'https://github.com/fum-lab/fum/issues/1'}

    def вход(self, запись=None):
        текст = json.dumps([запись or self.запись()], ensure_ascii=False)
        хэш = hashlib.sha256(текст.encode()).hexdigest()
        return 'Issues/fum-lab/fum/данные/' + хэш + '.json', текст

    def категории(self, путь, текст):
        return [э.category for э in сканер.scan_text(путь, текст)]

    def test_точные_байты_публичного_обсуждения(self):
        путь, текст = self.вход()
        self.assertEqual(self.категории(путь, текст), ['report.external-source.posix-absolute'])

    def test_комментарий_того_же_репозитория(self):
        запись = self.запись(); запись.pop('number')
        запись['issue_url'] = 'https://api.github.com/repos/fum-lab/fum/issues/1'
        путь, текст = self.вход(запись)
        self.assertEqual(self.категории(путь, текст), ['report.external-source.posix-absolute'])

    def test_похожий_путь_не_источник(self):
        путь, текст = self.вход()
        for новый in [путь.replace('Issues/', 'issues/'), путь.replace('/данные/', '/наблюдения/'), 'Issues/README.md']:
            self.assertIn('error.posix-absolute', self.категории(новый, текст))

    def test_подмена_байт_не_источник(self):
        путь, текст = self.вход()
        self.assertIn('error.posix-absolute', self.категории(путь, текст + ' '))

    def test_неполная_или_чужая_запись_не_источник(self):
        for поле, значение in [('body', None), ('html_url', 'https://github.com/other/repo/issues/1'), ('state', 'unknown')]:
            запись = self.запись()
            if поле == 'body':
                запись.pop(поле)
                запись['title'] = '/дом/пример'
            else: запись[поле] = значение
            путь, текст = self.вход(запись)
            self.assertIn('error.posix-absolute', self.категории(путь, текст))


if __name__ == '__main__':
    unittest.main()
