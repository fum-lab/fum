"""Два процесса одного эпизода выполняют только один фактический merge."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from фикстура_слияния_приёма import ФикстураПриёма, эпизод, гит, ЗАДАЧА


class ПроверкаКонкурентногоПриёма(unittest.TestCase):
    def test_два_процесса_получают_один_эффект(сам):
        with tempfile.TemporaryDirectory() as папка:
            пример = ФикстураПриёма(папка)
            вход = пример.папка / 'вход.json'
            вход.write_bytes(эпизод.хранение.байты({'основание': пример.основание, 'план': пример.план_приёма,
                'реестр': str(пример.реестр), 'эпизоды': str(пример.папка / 'эпизоды'),
                'наблюдения': str(пример.папка / 'слияния.jsonl')}))
            код = '''import json,sys
from pathlib import Path
import эпизод_приёма,слияние_приёма,обратная_доставка
данные=json.loads(Path(sys.argv[1]).read_bytes())
эпизод_приёма.КОРЕНЬ_СОСТОЯНИЯ=Path(данные['эпизоды'])
выполнить=обратная_доставка.выполнить
def наблюдать(корень,*аргументы,**параметры):
    if аргументы[0]=='merge':
        with Path(данные['наблюдения']).open('a') as поток: поток.write(json.dumps(аргументы)+'\\n')
    return выполнить(корень,*аргументы,**параметры)
обратная_доставка.выполнить=наблюдать
приём=слияние_приёма.СлияниеПриёма(данные['основание'],данные['план'],данные['реестр'],lambda:данные['основание'])
print('готов',flush=True)
sys.stdin.readline()
print(json.dumps(приём.применить(),ensure_ascii=False))
'''
            окружение = {**os.environ, 'CODEX_THREAD_ID': ЗАДАЧА,
                'PYTHONPATH': str(Path(__file__).resolve().parents[1] / 'scripts')}
            процессы = []
            try:
                for _ in range(2):
                    процессы.append(subprocess.Popen([sys.executable, '-B', '-c', код, str(вход)],
                        cwd=пример.цель, env=окружение, stdin=subprocess.PIPE,
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True))
                for процесс in процессы: сам.assertEqual(процесс.stdout.readline().strip(), 'готов')
                for процесс in процессы:
                    процесс.stdin.write('старт\n'); процесс.stdin.flush()
                результаты = []
                for процесс in процессы:
                    вывод, ошибки = процесс.communicate(timeout=30)
                    сам.assertEqual(процесс.returncode, 0, ошибки)
                    результаты.append(json.loads(вывод))
                сам.assertEqual(результаты[0], результаты[1])
                сам.assertEqual(результаты[0]['стадия'], 'применено')
                сам.assertEqual(len((пример.папка / 'слияния.jsonl').read_text().splitlines()), 1)
                сам.assertEqual(гит(пример.цель, 'write-tree'), пример.основание['дерево'])
            finally:
                for процесс in процессы:
                    if процесс.poll() is None: процесс.kill()
                    процесс.communicate()


if __name__ == '__main__':
    unittest.main()
