"""Изолированные Git-источники и отсутствие внешнего выпуска."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

СКРИПТЫ = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(СКРИПТЫ))
from медиапакет_поддержки import собрать


class ПроверкаМедиапакета(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.корень = Path(self.временный.name)
        self.текст = 'Локальная проверка пройдена. Не интегрировано.\nНачальный остаток: 100,00 ₽; Поступления: 200,00 ₽; Комиссии: 10,00 ₽; Возвраты: 20,00 ₽; Расходы: 30,00 ₽.\n'
        (self.корень / 'факт.txt').write_text(self.текст)
        self.git('init', '-q')
        self.git('add', 'факт.txt')
        self.git('-c', 'user.name=FUM Тест', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Фикстура')
        self.коммит = self.git('rev-parse', 'HEAD').strip()
        self.источник = {'коммит': self.коммит, 'путь': 'факт.txt', 'sha256': hashlib.sha256(self.текст.encode()).hexdigest(), 'цитата': 'Локальная проверка пройдена. Не интегрировано.'}
        self.данные = {'схема': 'fum.вход-медиапакета.1', 'лицензия': 'CC0-1.0', 'результат': self.источник, 'ограничения': ['Не интегрировано.'], 'цель': 'Поддержать открытый этап FUM.', 'следующий_шаг': 'Согласовать демонстрацию.', 'отчёт': {'период': None, 'получатель': None, 'начальный_остаток': None, 'поступления': None, 'комиссии': None, 'возвраты': None, 'расходы': None, 'источник': None}}

    def tearDown(self):
        self.временный.cleanup()

    def git(self, *аргументы):
        return subprocess.check_output(['git', *аргументы], cwd=self.корень, stderr=subprocess.PIPE).decode()

    def test_повтор_неизменяемый_источник_и_границы(self):
        первый = собрать(self.корень, self.данные)
        (self.корень / 'факт.txt').write_text('Иное рабочее содержимое')
        self.assertEqual(первый, собрать(self.корень, self.данные))
        self.assertEqual(set(первый['черновики']), {'Telegram', 'MAX', 'отчёт'})
        for канал in ['Telegram', 'MAX']:
            self.assertIn('Не интегрировано.', первый['черновики'][канал])
            self.assertIn('CC0', первый['черновики'][канал])
            self.assertIn('Черновик', первый['черновики'][канал])
        self.assertIn('Поступления: неизвестно', первый['черновики']['отчёт'])
        self.assertIsNone(первый['конечный_остаток_копейки'])

    def test_ложное_происхождение_отклоняется(self):
        for ключ, значение in [('коммит', 'HEAD'), ('коммит', '0'*40), ('sha256', '0'*64), ('путь', '../факт.txt'), ('путь', '/факт.txt'), ('путь', 'ФАКТ.txt'), ('цитата', 'Выпущено пользователям')]:
            with self.subTest(ключ=ключ, значение=значение):
                данные = deepcopy(self.данные); данные['результат'][ключ] = значение
                with self.assertRaises(ValueError): собрать(self.корень, данные)

    def test_символьный_git_источник_отклоняется(self):
        (self.корень/'ссылка').symlink_to('факт.txt'); self.git('add','ссылка'); self.git('-c','user.name=FUM Тест','-c','user.email=test@example.invalid','commit','-qm','Ссылка')
        данные=deepcopy(self.данные); данные['результат'].update({'коммит':self.git('rev-parse','HEAD').strip(),'путь':'ссылка'})
        with self.assertRaises(ValueError): собрать(self.корень,данные)

    def test_суммы_требуют_свидетельства_и_точных_типов(self):
        for значение in [0, True, -1, 1.5, '100', 10**18]:
            данные=deepcopy(self.данные); данные['отчёт']['поступления']=значение
            with self.subTest(значение=значение), self.assertRaises(ValueError): собрать(self.корень,данные)

    def test_подтверждённые_суммы_и_частичный_остаток(self):
        данные = self.финансовый_вход()
        self.assertEqual(собрать(self.корень, данные)['конечный_остаток_копейки'], 30000)
        данные['отчёт']['расходы'] = None
        self.assertIsNone(собрать(self.корень, данные)['конечный_остаток_копейки'])
        данные['отчёт']['поступления'] = 20001
        with self.assertRaises(ValueError): собрать(self.корень, данные)

    def свидетельство(self, **изменения):
        запись = {'схема': 'fum.свидетельство-поддержки.1', 'валюта': 'RUB', 'период': '2026-09', 'получатель': 'Открытый проект', 'операции': {}}
        for поле, сумма in [('начальный_остаток', '100,00'), ('поступления', '200,00'), ('комиссии', '0,00'), ('возвраты', '0,00'), ('расходы', '0,00')]:
            запись['операции'][поле] = {'сумма': сумма, 'факт': True, 'тип': поле}
        запись.update(изменения)
        return запись

    def финансовый_вход(self, запись=None):
        запись = self.свидетельство() if запись is None else запись
        текст = json.dumps(запись, ensure_ascii=False)
        (self.корень / 'деньги.json').write_text(текст)
        self.git('add', 'деньги.json')
        self.git('-c', 'user.name=FUM Тест', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Финансовое свидетельство')
        данные = deepcopy(self.данные)
        данные['отчёт'].update({'период': '2026-09', 'получатель': 'Открытый проект', 'начальный_остаток': 10000, 'поступления': 20000, 'комиссии': 0, 'возвраты': 0, 'расходы': 0, 'источник': {'коммит': self.git('rev-parse', 'HEAD').strip(), 'путь': 'деньги.json', 'sha256': hashlib.sha256(текст.encode()).hexdigest(), 'цитата': текст}})
        return данные

    def test_нулевые_операции_при_явном_факте(self):
        self.assertEqual(собрать(self.корень, self.финансовый_вход())['конечный_остаток_копейки'], 30000)

    def test_выдуманная_финансовая_цитата(self):
        данные = deepcopy(self.данные)
        данные['отчёт']['поступления'] = 10000
        данные['отчёт']['источник'] = dict(self.источник, цитата='Поступления: 100,00 ₽; фактически получено.')
        with self.assertRaises(ValueError): собрать(self.корень, данные)

    def test_подстрока_и_чужая_операция_не_свидетельство(self):
        for цитата in ['Цена: 1100,00 ₽.', 'Обещано: 100,00 ₽.', 'План: получить 100,00 ₽.', 'Расходы: 100,00 ₽.']:
            with self.subTest(цитата=цитата):
                данные = deepcopy(self.данные)
                данные['отчёт']['поступления'] = 10000
                данные['отчёт']['источник'] = dict(self.источник, цитата=цитата)
                with self.assertRaises(ValueError): собрать(self.корень, данные)

    def test_период_и_получатель_строго_типизированы(self):
        for поле in ['период', 'получатель']:
            for значение in [True, 12, [], {}, '']:
                with self.subTest(поле=поле, значение=значение):
                    данные = deepcopy(self.данные); данные['отчёт'][поле] = значение
                    with self.assertRaises(ValueError): собрать(self.корень, данные)

    def test_цитата_плана_не_проверенный_результат(self):
        данные = deepcopy(self.данные)
        текст = 'Первый результат — обеспечить ограниченный этап открытой разработки.'
        (self.корень/'план.txt').write_text(текст)
        self.git('add', 'план.txt')
        self.git('-c', 'user.name=FUM Тест', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'План')
        данные['результат'] = {'коммит': self.git('rev-parse', 'HEAD').strip(), 'путь': 'план.txt', 'sha256': hashlib.sha256(текст.encode()).hexdigest(), 'цитата': текст}
        вывод = собрать(self.корень, данные)
        self.assertNotIn('Проверенный результат:', вывод['черновики']['Telegram'])
        self.assertIn('Цитата источника:', вывод['черновики']['Telegram'])

    def test_валюта_факт_и_тип_операции(self):
        for изменение in ['валюта', 'факт', 'тип', 'период', 'получатель']:
            with self.subTest(изменение=изменение):
                запись = self.свидетельство()
                if изменение == 'валюта': запись['валюта'] = 'USD'
                elif изменение in ['факт', 'тип']: запись['операции']['поступления'][изменение] = False if изменение == 'факт' else 'цена'
                else: запись[изменение] = 'другое'
                данные = self.финансовый_вход(запись)
                with self.assertRaises(ValueError): собрать(self.корень, данные)

    def test_семантические_подмены_полного_источника(self):
        for случай in ['валюта', 'нет валюты', 'план', 'тип', 'подстрока', 'поле', 'получатель', 'период', 'повтор']:
            with self.subTest(случай=случай):
                запись = self.свидетельство()
                for операция in запись['операции'].values(): операция['сумма'] = '100,00'
                if случай == 'валюта': запись['валюта'] = 'USD'
                if случай == 'нет валюты': del запись['валюта']
                if случай == 'план': запись['операции']['поступления']['факт'] = False
                if случай == 'тип': запись['операции']['поступления']['тип'] = 'цена'
                if случай == 'подстрока': запись['операции']['поступления']['сумма'] = '1100,00'
                if случай == 'поле': del запись['операции']['поступления']
                if случай in ['получатель', 'период']: запись[случай] = 'Иное'
                данные = self.финансовый_вход(запись)
                for поле in ['начальный_остаток', 'поступления', 'комиссии', 'возвраты', 'расходы']: данные['отчёт'][поле] = 10000
                if случай == 'повтор':
                    текст = данные['отчёт']['источник']['цитата'].replace('"валюта": "RUB"', '"валюта": "USD", "валюта": "RUB"')
                    (self.корень/'деньги.json').write_text(текст)
                    self.git('add', 'деньги.json'); self.git('-c', 'user.name=FUM Тест', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Повтор ключа')
                    данные['отчёт']['источник'].update(коммит=self.git('rev-parse','HEAD').strip(), sha256=hashlib.sha256(текст.encode()).hexdigest(), цитата=текст)
                данные['результат'] = deepcopy(данные['отчёт']['источник'])
                with self.assertRaises(ValueError): собрать(self.корень, данные)

    def test_повторные_ключи_в_полном_валидном_входе(self):
        текст = json.dumps(self.данные, ensure_ascii=False)
        вход = self.корень / 'вход.json'
        for исходный in [текст, текст.replace('"поступления": null', '"поступления": null, "поступления": null')]:
            вход.write_text(исходный)
            запуск = subprocess.run([sys.executable, '-B', str(СКРИПТЫ/'медиапакет-поддержки.py'), '--корень-репозитория', str(self.корень), '--вход', str(вход)], capture_output=True)
            self.assertEqual(запуск.returncode, 0 if исходный == текст else 2, запуск.stderr)
            if исходный != текст: self.assertEqual(запуск.stdout, b'')

    def test_неизвестные_поля_лицензия_и_ограничения(self):
        for ключ,значение in [('лицензия','закрыто'),('ссылка_оплаты','https://example.invalid'),('ограничения',[]),('ограничения',['Полностью готово.'])]:
            данные=deepcopy(self.данные);данные[ключ]=значение
            with self.subTest(ключ=ключ), self.assertRaises(ValueError): собрать(self.корень,данные)

    def test_изменение_входа_меняет_отпечаток(self):
        первый=собрать(self.корень,self.данные);данные=deepcopy(self.данные);данные['цель']='Другой ограниченный этап.'
        self.assertNotEqual(первый['вход_sha256'],собрать(self.корень,данные)['вход_sha256'])

    def test_cli_не_пишет_в_репозиторий_и_не_исполняет_текст(self):
        данные=deepcopy(self.данные);данные['цель']='$(touch недопустимо)'
        вход=self.корень/'вход.json';вход.write_text(json.dumps(данные,ensure_ascii=False))
        до=self.git('status','--porcelain')
        запуск=subprocess.run([sys.executable,'-B',str(СКРИПТЫ/'медиапакет-поддержки.py'),'--корень-репозитория',str(self.корень),'--вход',str(вход)],capture_output=True)
        self.assertEqual(запуск.returncode,0,запуск.stderr)
        self.assertEqual(до,self.git('status','--porcelain'))
        self.assertIn('$(touch недопустимо)',json.loads(запуск.stdout)['черновики']['Telegram'])
        вход.write_text('{"схема":1,"схема":2}')
        отказ=subprocess.run([sys.executable,'-B',str(СКРИПТЫ/'медиапакет-поддержки.py'),'--корень-репозитория',str(self.корень),'--вход',str(вход)],capture_output=True)
        self.assertEqual(отказ.returncode,2);self.assertEqual(отказ.stdout,b'')


if __name__ == '__main__':
    unittest.main()
