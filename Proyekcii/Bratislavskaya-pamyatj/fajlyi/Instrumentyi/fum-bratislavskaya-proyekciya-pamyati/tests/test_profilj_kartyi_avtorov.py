"""Профиль не приписывает локальные хэши другой проверяемой реализации."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from unittest import TestCase


class ПроверкаПроисхожденияПрофиля(TestCase):
    def test_другой_корень_не_создаёт_ложный_профиль(сам):
        сам.проверить_другой_корень(False)

    def test_ссылка_на_свой_скрипт_не_разрешает_чужие_входы(сам):
        сам.проверить_другой_корень(True)

    def проверить_другой_корень(сам, ссылка):
        каталог = Path(__file__).resolve().parent.parent
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный) / "другая-реализация"
            копия = корень / "Инструменты/fum-bratislavskaya-proyekciya-pamyati"
            for имя in (
                "scripts/братиславская_проекция_памяти.py",
                "контракт-v2.json",
                "совместимость/контракт-v2-до-карты-авторов.json",
                "tests/фикстуры/поколение-до-карты-авторов-v2.json",
            ):
                цель = копия / имя
                цель.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(каталог / имя, цель)
            for имя in (
                "fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py",
                "fum-proyektnyiye-fajlyi/scripts/project_files.py",
                "fum-struktura-papok-zaprosov/scripts/request_folder_layout.py",
            ):
                цель = корень / "Инструменты" / имя
                цель.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(каталог.parent / имя, цель)
            сценарий = копия / "scripts/братиславская_проекция_памяти.py"
            сценарий.write_bytes(сценарий.read_bytes() + "\n# Другой проверяемый источник.\n".encode())
            if ссылка:
                сценарий.unlink()
                сценарий.symlink_to(каталог / "scripts/братиславская_проекция_памяти.py")
                политика = копия / "контракт-v2.json"
                политика.write_bytes(политика.read_bytes() + b"\n")
            выход = Path(временный) / "профиль.json"
            окружение = dict(os.environ, FUM_CHECKED_CODE_ROOT=str(корень))
            процесс = subprocess.run(
                [sys.executable, "-B", str(каталог / "tests/профиль-карты-авторов.py"),
                 "--выход", str(выход), "--повторов", "1"],
                env=окружение, capture_output=True, text=True, timeout=30,
            )
            сам.assertNotEqual(процесс.returncode, 0, процесс.stdout + процесс.stderr)
            сам.assertIn("FUM_CHECKED_CODE_ROOT", процесс.stderr)
            сам.assertFalse(выход.exists())
