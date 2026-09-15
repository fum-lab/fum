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
        данные=deepcopy(self.данные)
        данные['отчёт'].update(dict(zip(['начальный_остаток','поступления','комиссии','возвраты','расходы'],[10000,20000,1000,2000,3000])))
        данные['отчёт']['источник']=dict(self.источник,цитата=self.текст.splitlines()[1])
        self.assertEqual(собрать(self.корень,данные)['конечный_остаток_копейки'],24000)
        данные['отчёт']['расходы']=None
        self.assertIsNone(собрать(self.корень,данные)['конечный_остаток_копейки'])
        данные['отчёт']['поступления']=20001
        with self.assertRaises(ValueError): собрать(self.корень,данные)

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
