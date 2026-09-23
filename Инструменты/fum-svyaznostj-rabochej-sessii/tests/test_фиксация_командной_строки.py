"""Граница переживает новый процесс; повтор не меняет её байты."""
import json
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import test_готовность_этапа as основа_проверки

СЦЕНАРИЙ = Path(__file__).resolve().parents[1] / "scripts/контролировать-фиксацию.py"
ОПИСАНИЕ = importlib.util.spec_from_file_location("команда_готовности", СЦЕНАРИЙ)
КОМАНДА = importlib.util.module_from_spec(ОПИСАНИЕ)
ОПИСАНИЕ.loader.exec_module(КОМАНДА)


class ФиксацияКоманднойСтроки(unittest.TestCase):
    def setUp(сам):
        каталог = tempfile.TemporaryDirectory()
        сам.addCleanup(каталог.cleanup)
        сам.корень = Path(каталог.name).resolve()
        основа = основа_проверки.ГотовностьЭтапа(); основа.setUp()
        сам.снимок = сам.корень / "снимок.json"
        сам.снимок.write_text(json.dumps(основа.снимок, ensure_ascii=False))
        сам.готовность = сам.корень / "готовность.json"

    def вызвать(сам, действие, *аргументы):
        return subprocess.run([sys.executable, "-B", str(СЦЕНАРИЙ), действие,
            "--снимок", str(сам.снимок), "--готовность", str(сам.готовность), *аргументы], capture_output=True, text=True)

    def test_новый_процесс_сохраняет_время_и_возвращает_поздний_ввод(сам):
        первый = сам.вызвать("объявить", "--предел-секунд", "600")
        сам.assertEqual(0, первый.returncode, первый.stdout + первый.stderr)
        исходное = сам.готовность.read_bytes()
        повтор = сам.вызвать("объявить", "--предел-секунд", "600")
        сам.assertEqual(0, повтор.returncode, повтор.stdout + повтор.stderr)
        сам.assertEqual(исходное, сам.готовность.read_bytes())
        сам.assertEqual(json.loads(первый.stdout), json.loads(повтор.stdout))
        поздние = сам.корень / "поздние.json"; поздние.write_text(json.dumps(["d" * 64]))
        итог = сам.вызвать("сверить", "--поздние-экземпляры", str(поздние))
        сам.assertEqual(0, итог.returncode, итог.stdout + итог.stderr)
        сам.assertEqual(["d" * 64], json.loads(итог.stdout)["следующий_этап"])
        сам.assertEqual(0o600, сам.готовность.stat().st_mode & 0o777)

    def test_расширение_и_новый_порог_не_перезаписывают_границу(сам):
        сам.assertEqual(0, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        исходное = сам.готовность.read_bytes()
        сам.assertEqual(2, сам.вызвать("объявить", "--предел-секунд", "1200").returncode)
        снимок = json.loads(сам.снимок.read_bytes()); снимок["экземпляры"].append("d" * 64)
        сам.снимок.write_text(json.dumps(снимок))
        сам.assertEqual(2, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        сам.assertEqual(исходное, сам.готовность.read_bytes())

    def test_символическая_ссылка_и_повторный_ключ_отклоняются(сам):
        чужое = сам.корень / "чужое.json"; чужое.write_text("{}")
        сам.готовность.symlink_to(чужое)
        сам.assertEqual(2, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        сам.assertEqual("{}", чужое.read_text())
        сам.готовность.unlink()
        сам.снимок.write_text('{"задача":"a","задача":"b"}')
        сам.assertEqual(2, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        сам.assertFalse(сам.готовность.exists())

    def test_сохранённый_возраст_не_уменьшается_при_откате_часов(сам):
        сам.assertEqual(0, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        запись = json.loads(сам.готовность.read_bytes()); снимок = json.loads(сам.снимок.read_bytes())
        время = запись["готов_в_наносекундах_эпохи"]
        первый = КОМАНДА.сверить(сам.готовность, снимок, [], время + 700_000_000_000)
        второй = КОМАНДА.сверить(сам.готовность, снимок, [], время + 550_000_000_000)
        сам.assertTrue(первый["задержка"] and второй["задержка"])
        сам.assertEqual(700_000_000_000, второй["возраст_наносекунды"])
        # Следующий настоящий процесс подхватывает сохранённый максимум.
        повтор = сам.вызвать("сверить")
        сам.assertEqual(0, повтор.returncode, повтор.stdout + повтор.stderr)
        сам.assertTrue(json.loads(повтор.stdout)["задержка"])

    def test_оборванная_запись_не_восстанавливается_догадкой(сам):
        сам.готовность.write_bytes(b'{"')
        сам.готовность.chmod(0o600)
        исходное = сам.готовность.read_bytes()
        сам.assertEqual(2, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        сам.assertEqual(2, сам.вызвать("сверить").returncode)
        сам.assertEqual(исходное, сам.готовность.read_bytes())

    def test_сверка_не_создаёт_служебных_файлов_в_checkout(сам):
        сам.assertEqual(0, сам.вызвать("объявить", "--предел-секунд", "600").returncode)
        (сам.корень / ".git").write_text("gitdir: /фикстура")
        сам.assertEqual(2, сам.вызвать("сверить").returncode)
        сам.assertFalse(Path(str(сам.готовность) + ".lock").exists())
        сам.assertFalse(Path(str(сам.готовность) + ".возраст.json").exists())
