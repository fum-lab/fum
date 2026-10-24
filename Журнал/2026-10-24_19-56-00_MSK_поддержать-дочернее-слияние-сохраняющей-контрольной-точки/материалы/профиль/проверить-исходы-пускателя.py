"""Проверить исход профиля и отказ до запуска при занятом выходе."""
import os as ос
import pstats as статистика
import subprocess as процессы
import sys as система
import tempfile as временные
import unittest as проверки
from pathlib import Path as Путь

ПУСКАТЕЛЬ = Путь(__file__).with_name('запустить-профиль-с-сохранением-исхода.py')

class ИсходыПрофиля(проверки.TestCase):
    def сценарий(сам, текст, код, *, занят=False):
        with временные.TemporaryDirectory() as каталог:
            папка=Путь(каталог); исходник=папка/'исходник.py'; выход=папка/'профиль.pstats'; эффект=папка/'эффект'
            исходник.write_text(текст, encoding='utf-8')
            if занят:
                выход.write_bytes(b'preserve'); выход.chmod(0o600)
            процесс=процессы.run([система.executable,'-E','-s','-S','-B',str(ПУСКАТЕЛЬ),str(выход),str(исходник),str(эффект)],capture_output=True)
            сам.assertEqual(код,процесс.returncode,процесс.stderr.decode())
            if занят:
                сам.assertEqual(b'preserve',выход.read_bytes()); сам.assertFalse(эффект.exists())
            else:
                сам.assertEqual(0o600,выход.stat().st_mode & 0o777); сам.assertTrue(статистика.Stats(str(выход)).stats)
            return процесс

    def test_успех_сохраняется_и_маска_режимов_не_меняется(сам):
        маска=ос.umask(0); ос.umask(маска)
        процесс=сам.сценарий('import os; маска=os.umask(0); os.umask(маска); print(маска); raise SystemExit(0)',0)
        сам.assertEqual(str(маска).encode(),процесс.stdout.strip())

    def test_ненулевой_исход_не_подавляется(сам):
        сам.сценарий('raise SystemExit(7)',7)

    def test_исключение_сохраняется(сам):
        процесс=сам.сценарий('raise RuntimeError("fixture")',1)
        сам.assertIn(b'RuntimeError: fixture',процесс.stderr)

    def test_занятый_выход_отказывает_до_исходного_эффекта(сам):
        сам.сценарий('from pathlib import Path; import sys; Path(sys.argv[1]).write_text("effect"); raise SystemExit(7)',1,занят=True)

    def test_ошибка_дампа_не_превращает_успех_в_ложный_успех(сам):
        сам.сценарий('import os\ndef отказ(дескриптор): raise OSError("fixture dump")\nos.fsync=отказ\nraise SystemExit(0)',1)

    def test_ошибка_дампа_не_заменяет_исходный_отказ(сам):
        сам.сценарий('import os\ndef отказ(дескриптор): raise OSError("fixture dump")\nos.fsync=отказ\nraise SystemExit(7)',7)

if __name__=='__main__': проверки.main()
