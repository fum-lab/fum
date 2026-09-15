"""Проверить повторяемость, дрейф и влияние одного описания на оба языка."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

КОРЕНЬ = Path(__file__).resolve().parent
спецификация = importlib.util.spec_from_file_location('порождение', КОРЕНЬ / 'породить-ответ.py')
порождение = importlib.util.module_from_spec(спецификация)
спецификация.loader.exec_module(порождение)


class ПроверкиГенерации(unittest.TestCase):
    def test_детерминизм_дрейф_и_изменение_описания(сам):
        описание = КОРЕНЬ / 'контракты/описание-ответа.json'
        первый = порождение.породить(ИСПОЛНИТЕЛЬ, описание, КОРЕНЬ / 'контракты')
        сам.assertEqual(первый, порождение.породить(ИСПОЛНИТЕЛЬ, описание, КОРЕНЬ / 'контракты'))
        сам.assertEqual(первый, {имя: (КОРЕНЬ / 'порождённые' / имя).read_bytes() for имя in первый})
        with tempfile.TemporaryDirectory(prefix='fum-generation-') as временный:
            каталог = Path(временный)
            for имя, данные in первый.items(): (каталог / имя).write_bytes(данные)
            команда = [sys.executable, '-B', str(КОРЕНЬ / 'породить-ответ.py'), '--исполнитель', str(ИСПОЛНИТЕЛЬ), '--выход', str(каталог), '--проверить']
            сам.assertEqual(subprocess.run(команда, capture_output=True).returncode, 0)
            изменённый = первый['модели_ответа.py'] + b'\n# drift\n'
            (каталог / 'модели_ответа.py').write_bytes(изменённый)
            отказ = subprocess.run(команда, capture_output=True)
            сам.assertEqual((отказ.returncode, отказ.stdout), (2, b''))
            сам.assertEqual((каталог / 'модели_ответа.py').read_bytes(), изменённый)
            узел = json.loads(описание.read_bytes())
            ключ = 'переименовано/"\\\u2028'
            модель = next(м for м in узел['модели'] if м['имя'] == узел['выход'])
            поле = next(п for п in модель['поля'] if п['ключ'] == 'схема')
            поле['ключ'] = ключ
            узел['результат'][ключ] = узел['результат'].pop('схема')
            путь = каталог / 'описание.json'
            путь.write_text(json.dumps(узел, ensure_ascii=False))
            второй = порождение.породить(ИСПОЛНИТЕЛЬ, путь, КОРЕНЬ / 'контракты')
            for имя in первый: сам.assertNotEqual(первый[имя], второй[имя])
            sys.path.insert(0, str(КОРЕНЬ / 'общие/Python'))
            import types
            модуль = types.ModuleType('изменённые_модели')
            sys.modules[модуль.__name__] = модуль
            exec(compile(второй['модели_ответа.py'], '<порождённая модель>', 'exec'), модуль.__dict__)
            фикстура = (КОРЕНЬ / 'фикстуры/нативный-ответ.json').read_bytes()
            import hashlib
            результат = json.loads(модуль.представить_снимок(фикстура, hashlib.sha256(фикстура).hexdigest(), '00000000-0000-0000-0000-000000000165'))
            сам.assertIn(ключ, результат)
            сам.assertNotIn('схема', результат)
            узел['модели'][0]['поля'][0]['тип'] = 'неподдержанный'
            путь.write_text(json.dumps(узел, ensure_ascii=False))
            отказ = subprocess.run(команда[:-1] + ['--описание', str(путь)], capture_output=True)
            сам.assertEqual((отказ.returncode, отказ.stdout), (2, b''))
            сам.assertEqual((каталог / 'модели_ответа.py').read_bytes(), изменённый)


if __name__ == '__main__':
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--исполнитель', type=Path, required=True)
    ИСПОЛНИТЕЛЬ = разбор.parse_args().исполнитель.resolve()
    unittest.main(argv=[sys.argv[0]])
