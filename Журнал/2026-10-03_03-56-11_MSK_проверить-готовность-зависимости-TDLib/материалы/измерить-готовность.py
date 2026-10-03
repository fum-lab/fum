"""Получить ограниченный профиль чтения: фикстура и фактический CLI без сборки."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time
import unittest

корень = Path(sys.argv[1]).resolve()
клиент = корень / 'Приложения/FUMA/Packages/КлиентTelegram'
путьТестов = клиент / 'Проверки/test_сборка_tdlib.py'
спецификация = importlib.util.spec_from_file_location('проверки_готовности', путьТестов)
проверки = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(проверки)
набор = unittest.defaultTestLoader.loadTestsFromTestCase(проверки.ПроверкиГотовностиЗависимости)
итогТестов = unittest.TextTestRunner(verbosity=1).run(набор)
if not итогТестов.wasSuccessful():
    raise SystemExit(2)
фикстура = проверки.ПроверкиГотовностиЗависимости('test_чистая_синтетическая_зависимость_готова_без_записи')
началоПодготовки = time.perf_counter_ns()
фикстура.setUp()
подготовка = time.perf_counter_ns() - началоПодготовки
try:
    положительный = фикстура.проверить()
finally:
    фикстура.doCleanups()
начало = time.perf_counter_ns()
процесс = subprocess.run([sys.executable, '-O', '-B', str(клиент / 'Проверки/собрать-tdlib.py'),
                          '--корень-репозитория', str(корень), '--только-проверить-зависимость'],
                         capture_output=True, timeout=15)
времяПроцесса = time.perf_counter_ns() - начало
отрицательный = json.loads(процесс.stderr)
if процесс.returncode != 2 or процесс.stdout or отрицательный['причина'] != 'нет_регистрации':
    raise SystemExit('фактический CLI не дал ожидаемый отказ отсутствующей регистрации')
хэши = {str(файл.relative_to(корень)): hashlib.sha256(файл.read_bytes()).hexdigest()
         for файл in (клиент / 'Проверки/собрать-tdlib.py', путьТестов,
                      клиент / 'Профили/2026-09-30-сборка-tdlib.json')}
результат = {'схема': 'fum.профиль-готовности-зависимости-tdlib.1', 'исход': 'успех',
    'базовыйКоммит': '16fbb601afa5fb05f9ae58a85791b11155b5ccee', 'исходникиШа256': хэши,
    'синтетическаяФикстура': {'подготовкаНаносекунды': подготовка, 'результат': положительный,
        'граница': 'OID, дерево, время и хэш файла подставлены из временной локальной фикстуры; это не производственная TDLib.'},
    'фактическийCLI': {'код': процесс.returncode, 'процессНаносекунды': времяПроцесса,
        'stderrШа256': hashlib.sha256(процесс.stderr).hexdigest(), 'результат': отрицательный},
    'неизменность': '18 тестов под -O сверяют файлы, режимы, индексы, refs, config и объекты временных репозиториев до/после чтения; сборочные функции и mkdir запрещены оракулом.',
    'ограничения': 'Один локальный комплект. Подготовка фикстуры исключена из диагностики. Доступность зеркала, init/fetch, сборка, загрузка и работа живой TDLib не проверены.'}
выход = клиент / 'Профили/2026-10-03-готовность-зависимости-TDLib.json'
with выход.open('x', encoding='utf-8') as поток:
    поток.write(json.dumps(результат, ensure_ascii=False, indent=2, sort_keys=True) + '\n')
print(json.dumps({'исход': 'успех', 'тестов': итогТестов.testsRun,
    'фикстураНаносекунды': положительный['длительностьНаносекунды'],
    'CLIНаносекунды': времяПроцесса, 'профильШа256': hashlib.sha256(выход.read_bytes()).hexdigest()}, ensure_ascii=False))
