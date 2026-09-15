"""Команда раннего подтверждения и исполняемый адаптер возможностей Codex."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import unittest

from test_входа_направления import открытый_вход, ЗАДАЧА
from test_постановки_задачи import манифест, нативный_источник

СКРИПТЫ = Path(__file__).resolve().parents[1] / "scripts"


class ПроверкаКоманды(unittest.TestCase):
    def test_новая_задача_может_подтвердить_начало_через_команду(проверка):
        with открытый_вход() as (корень, источник, решение):
            запись = манифест(корень)
            нативный_источник(корень, источник, запись["коммит"])
            результат = subprocess.run([sys.executable, "-B", str(СКРИПТЫ / "принять-направление.py"), "--корень-репозитория", str(корень), "--задача", ЗАДАЧА,
                "подтвердить-начало", "--источник", str(источник), "--коммит", запись["коммит"]], capture_output=True, text=True, cwd=корень)
            проверка.assertEqual(0, результат.returncode, результат.stderr)
            проверка.assertEqual(запись["коммит"], json.loads(результат.stdout)["начальный_HEAD"])

    def test_адаптер_исполняет_один_допущенный_вызов_и_сохраняет_ответ(проверка):
        код = (СКРИПТЫ / "адаптер-codex.js").read_text()
        узел = shutil.which("node")
        проверка.assertIsNotNone(узел, "Для исполняемой границы нужен объявленный Node.js")
        сценарий = """
const адаптер = (КОД);
let вызовы = 0;
let сохранения = 0;
let разрешено = true;
const возможности = {
  подготовить: async (вход) => { const допуск = {разрешён_вызов: разрешено, вход}; разрешено = false; return допуск; },
  исполнить: async (допуск) => { вызовы++; return {clientThreadId: допуск.вход}; },
  сохранить: async (допуск, ответ) => { сохранения++; return ответ; }
};
const первый = await адаптер(возможности, 'отложенный');
const второй = await адаптер(возможности, 'отложенный');
if (вызовы !== 1 || сохранения !== 1 || первый.clientThreadId !== 'отложенный' || второй.разрешён_вызов !== false) throw Error('Нарушен одиночный вызов');
console.log(JSON.stringify({вызовы, сохранения}));
""".replace("КОД", код)
        результат = subprocess.run([узел, "--input-type=module", "-e", сценарий], capture_output=True, text=True, cwd=СКРИПТЫ)
        проверка.assertEqual(0, результат.returncode, результат.stderr)
        проверка.assertEqual({"вызовы": 1, "сохранения": 1}, json.loads(результат.stdout))


if __name__ == "__main__":
    unittest.main()
