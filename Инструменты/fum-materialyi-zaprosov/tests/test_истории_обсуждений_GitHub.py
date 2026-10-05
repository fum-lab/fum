import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


путь = Path(__file__).resolve().parents[1] / 'scripts' / 'архив_обсуждений_GitHub.py'
спецификация = importlib.util.spec_from_file_location('архив_обсуждений', путь)
архив = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(архив)


def тело(объекты):
    return json.dumps(объекты, ensure_ascii=False).encode('utf-8')


def обращение(текст='Первый текст', изменение='2026-10-04T10:00:00Z'):
    return {'id': 70, 'number': 7, 'title': 'Проверка памяти', 'body': текст,
            'state': 'open', 'updated_at': изменение,
            'html_url': 'https://github.com/fum-lab/fum/issues/7'}


def комментарий(номер=90, текст='Первый комментарий'):
    return {'id': номер, 'body': текст, 'updated_at': '2026-10-04T10:00:00Z',
            'issue_url': 'https://api.github.com/repos/fum-lab/fum/issues/7',
            'html_url': f'https://github.com/fum-lab/fum/issues/7#issuecomment-{номер}'}


class ИсторияОбсуждений(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.корень = Path(self.временный.name)
        self.addCleanup(self.временный.cleanup)

    def сохранить(self, метка, обращения, комментарии, полнота=True):
        return архив.импортировать(self.корень, 'fum-lab/fum', метка,
                                   [('issues', тело(обращения)),
                                    ('comments', тело(комментарии))],
                                   полнота=полнота, связи={'7': ['FUM-STEP-0237']})

    def test_пережить_удаление_GitHub_из_окружения_после_редактирования(self):
        self.сохранить('первое', [обращение()], [комментарий()])
        self.сохранить('второе', [обращение('Изменённый текст', '2026-10-05T10:00:00Z')],
                      [комментарий(текст='Исправленный комментарий'), комментарий(91, 'Новый')])
        subprocess.run(['git', 'init', '-q', str(self.корень)], check=True)
        subprocess.run(['git', '-C', str(self.корень), 'add', 'Issues'], check=True)
        subprocess.run(['git', '-C', str(self.корень), '-c', 'user.name=Тест',
                        '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Память'], check=True)
        копия = self.корень / 'копия'
        subprocess.run(['git', 'clone', '-q', '--no-local', str(self.корень), str(копия)], check=True)
        shutil.rmtree(self.корень / 'Issues')
        with patch.object(subprocess, 'run', side_effect=AssertionError('GitHub недоступен')):
            результат = архив.прочитать(копия, 'fum-lab/fum')
        запись = результат['обращения']['7']
        self.assertEqual([к['body'] for к in запись['версии']], ['Первый текст', 'Изменённый текст'])
        self.assertEqual([к['body'] for к in запись['комментарии']['90']],
                         ['Первый комментарий', 'Исправленный комментарий'])
        self.assertEqual(запись['комментарии']['91'][0]['body'], 'Новый')
        self.assertEqual(запись['связи'], ['FUM-STEP-0237'])
        self.assertEqual(запись['обработка'], 'не разобрано')

    def test_повтор_не_дублирует_версии_но_сохраняет_наблюдение(self):
        self.сохранить('первое', [обращение()], [комментарий()])
        self.сохранить('второе', [обращение()], [комментарий()])
        повтор = self.сохранить('второе', [обращение()], [комментарий()])
        результат = архив.прочитать(self.корень, 'fum-lab/fum')
        self.assertEqual(len(результат['наблюдения']), 2)
        self.assertEqual(len(результат['обращения']['7']['версии']), 1)
        self.assertTrue(повтор['повтор'])

    def test_неполный_вход_не_объявляет_удаление_и_полноту(self):
        self.сохранить('первое', [обращение()], [комментарий()])
        self.сохранить('второе', [], [], полнота=False)
        результат = архив.прочитать(self.корень, 'fum-lab/fum')
        self.assertFalse(результат['последнее_наблюдение_полно'])
        self.assertIn('7', результат['обращения'])

    def test_подмена_сырой_страницы_закрывает_чтение(self):
        self.сохранить('первое', [обращение()], [])
        страница = next(к for к in (self.корень / 'Issues/fum-lab/fum/данные').glob('*.json')
                        if к.read_bytes() != b'[]')
        страница.write_bytes(b'[]')
        with self.assertRaises(ValueError):
            архив.прочитать(self.корень, 'fum-lab/fum')

    def test_другая_версия_под_прежней_меткой_отказывается(self):
        self.сохранить('первое', [обращение()], [])
        with self.assertRaises(ValueError):
            self.сохранить('первое', [обращение('Подмена')], [])
        self.assertEqual(архив.прочитать(self.корень, 'fum-lab/fum')['обращения']['7']['версии'][0]['body'],
                         'Первый текст')

    def test_ошибка_второй_страницы_сохраняет_первую_и_не_маскируется(self):
        ответы = iter([(тело([обращение()]), 'https://api.github.com/repos/fum-lab/fum/issues?page=2')])
        def транспорт(адрес):
            try:
                return next(ответы)
            except StopIteration:
                raise OSError('GitHub выключен')
        with self.assertRaises(OSError):
            архив.получить(self.корень, 'fum-lab/fum', 'неполное', транспорт=транспорт)
        результат = архив.прочитать(self.корень, 'fum-lab/fum')
        self.assertIn('7', результат['обращения'])
        self.assertFalse(результат['последнее_наблюдение_полно'])

    def test_вложенная_ссылка_не_меняет_чужую_папку(self):
        внешняя = self.корень / 'чужая'; внешняя.mkdir()
        (self.корень / 'Issues').symlink_to(внешняя, target_is_directory=True)
        with self.assertRaises(ValueError):
            self.сохранить('первое', [обращение()], [])
        self.assertEqual(list(внешняя.iterdir()), [])

    def test_числовой_Link_GitHub_не_меняет_исходный_репозиторий(self):
        адреса = []
        def транспорт(адрес):
            адреса.append(адрес)
            if len(адреса) == 1:
                return тело([обращение()]), 'https://api.github.com/repositories/123/issues?state=all&per_page=100&after=fixture%3D&page=2'
            return b'[]', None
        архив.получить(self.корень, 'fum-lab/fum', 'полное', транспорт=транспорт)
        self.assertTrue(all('/repos/fum-lab/fum/' in к for к in адреса))
        self.assertEqual(len(адреса), 3)
        self.assertIn('after=fixture%3D', адреса[1])
        self.assertTrue(архив.прочитать(self.корень, 'fum-lab/fum')['последнее_наблюдение_полно'])

    def test_Link_не_может_сузить_состояния_или_сменить_репозиторий(self):
        for адрес in ['https://api.github.com/repos/other/repo/issues?page=2',
                      'https://api.github.com/repositories/1/issues?state=closed&page=2']:
            with self.assertRaises(ValueError):
                архив._следующая(адрес, 'fum-lab/fum', 'issues')

    def test_краткий_список_не_выдаётся_за_полную_память(self):
        with self.assertRaises(ValueError):
            self.сохранить('краткое', [{'id': 70, 'number': 7}], [])
        пустое_тело = обращение(); пустое_тело['body'] = None
        self.сохранить('полное', [пустое_тело], [])
        self.assertIsNone(архив.прочитать(self.корень, 'fum-lab/fum')['обращения']['7']['версии'][0]['body'])

    def test_неразобранный_HTTP_ответ_остаётся_в_памяти(self):
        def транспорт(адрес):
            return b'{invalid JSON', None
        with self.assertRaises(ValueError):
            архив.получить(self.корень, 'fum-lab/fum', 'повреждённое', транспорт=транспорт)
        файлы = list((self.корень / 'Issues/fum-lab/fum/данные').glob('*.json'))
        self.assertEqual(len(файлы), 1)
        self.assertEqual(файлы[0].read_bytes(), b'{invalid JSON')
        наблюдение = json.loads((self.корень / 'Issues/fum-lab/fum/наблюдения/повреждённое/наблюдение.json').read_bytes())
        self.assertFalse(наблюдение['полнота'])
        self.assertEqual(наблюдение['страницы'][0]['разбор'], 'не проверен')


if __name__ == '__main__':
    unittest.main()
