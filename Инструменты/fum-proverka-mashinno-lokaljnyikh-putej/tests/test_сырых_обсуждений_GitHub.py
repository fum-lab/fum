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

    def вход_объекта(self, запись):
        текст = json.dumps(запись, ensure_ascii=False)
        хэш = hashlib.sha256(текст.encode()).hexdigest()
        return 'Issues/fum-lab/fum/данные/' + хэш + '.json', текст

    def test_одиночное_обсуждение(self):
        путь, текст = self.вход_объекта(self.запись())
        self.assertEqual(self.категории(путь, текст), ['report.external-source.posix-absolute'])

    def test_одиночный_запрос_слияния_с_публичным_шаблоном(self):
        запись = self.запись()
        запись.update({'pull_request': {}, 'html_url': 'https://github.com/fum-lab/fum/pull/1',
                       'labels_url': 'https://api.github.com/repos/fum-lab/fum/issues/1/labels{/name}'})
        путь, текст = self.вход_объекта(запись)
        категории = self.категории(путь, текст)
        self.assertTrue(категории)
        self.assertTrue(all(категория == 'report.external-source.posix-absolute' for категория in категории))

    def test_одиночный_комментарий(self):
        запись = self.запись(); запись.pop('number')
        запись['issue_url'] = 'https://api.github.com/repos/fum-lab/fum/issues/1'
        путь, текст = self.вход_объекта(запись)
        self.assertEqual(self.категории(путь, текст), ['report.external-source.posix-absolute'])

    def test_одиночная_запись_сохраняет_проверку_путей_и_байтов(self):
        путь, текст = self.вход_объекта(self.запись())
        for новый, байты in [(путь, текст + ' '), (путь.replace('Issues/', 'issues/'), текст),
                             (путь.replace('/данные/', '/наблюдения/'), текст), ('Issues/README.md', текст)]:
            with self.subTest(путь=новый):
                self.assertIn('error.posix-absolute', self.категории(новый, байты))

    def test_одиночная_запись_сохраняет_отказ_неполным_и_чужим_данным(self):
        случаи = [('id', True), ('id', 0), ('number', -1), ('number', True), ('body', 7), ('updated_at', None),
                  ('title', None), ('state', 'unknown'), ('html_url', 'https://github.com/other/repo/issues/1')]
        for поле, значение in случаи:
            запись = self.запись(); запись[поле] = значение
            if поле == 'body': запись['title'] = '/дом/пример'
            путь, текст = self.вход_объекта(запись)
            with self.subTest(поле=поле):
                self.assertIn('error.posix-absolute', self.категории(путь, текст))
        запись = self.запись(); запись.pop('body'); запись['title'] = '/дом/пример'
        путь, текст = self.вход_объекта(запись)
        self.assertIn('error.posix-absolute', self.категории(путь, текст))

    def test_обёртка_не_заменяет_запись_обсуждения(self):
        for данные in [{'обсуждение': self.запись()}, {}, [self.запись(), {}], self.запись()['body']]:
            путь, текст = self.вход_объекта(данные)
            self.assertFalse(сканер._сырое_обсуждение(путь, текст))
            self.assertFalse(any(категория.startswith('report.external-source') for категория in self.категории(путь, текст)))

    def test_нулевой_байт_закрывает_допуск_одиночной_записи(self):
        _, текст = self.вход_объекта(self.запись()); текст += '\0'
        путь = 'Issues/fum-lab/fum/данные/' + hashlib.sha256(текст.encode()).hexdigest() + '.json'
        self.assertFalse(сканер._сырое_обсуждение(путь, текст))

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
