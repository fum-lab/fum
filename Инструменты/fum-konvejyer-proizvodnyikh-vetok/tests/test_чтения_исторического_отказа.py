"""Файловая подготовка не является допуском native или повторной доставки."""
from contextlib import ExitStack
import copy
import os
from pathlib import Path
import tempfile
import unittest
import subprocess
import sys
from unittest import mock

from фикстура_исторического_отказа import ФикстураИсторическогоОтказа, хранение
from фикстура_слияния_приёма import гит
import конверт_приёма as конверт
import эпизод_приёма as эпизод
import историческая_квитанция_отказа as чистый
import прочитать_исторический_отказ as читатель


class ЧтениеИсторическогоОтказа(unittest.TestCase):
    def setUp(self):
        временное = tempfile.TemporaryDirectory(prefix='fum-чтение-отказа-')
        self.addCleanup(временное.cleanup)
        self.ф = ФикстураИсторическогоОтказа(временное.name)
        стек = ExitStack(); self.addCleanup(стек.close)
        стек.enter_context(mock.patch.object(конверт, 'КОРЕНЬ_СОСТОЯНИЯ', self.ф.приватное))
        стек.enter_context(mock.patch.object(эпизод, 'КОРЕНЬ_СОСТОЯНИЯ', self.ф.приватное / 'эпизоды'))

    def читать(self):
        return читатель.прочитать(self.ф.описание_чтения, self.ф.текст, self.ф.нативный)

    def снимок(self):
        индекс = Path(гит(self.ф.цель, 'rev-parse', '--path-format=absolute', '--git-path', 'index'))
        return (гит(self.ф.цель, 'rev-parse', 'HEAD'), гит(self.ф.цель, 'symbolic-ref', 'HEAD'),
            индекс.read_bytes(), {str(p.relative_to(self.ф.приватное)): (p.read_bytes(), p.stat().st_ino)
                for p in self.ф.приватное.rglob('*') if p.is_file()})

    def test_читает_unknown_не_пишет_и_не_разрешает_повтор(self):
        до = self.снимок()
        with mock.patch.object(эпизод, 'начать', side_effect=AssertionError('Запрещена запись')), \
                mock.patch.object(хранение, 'установить', side_effect=AssertionError('Запрещена запись')):
            итог = self.читать()
        self.assertEqual('unknown', итог['квитанция']['исход_эффекта'])
        self.assertIs(False, итог['повтор_эффекта_разрешён'])
        self.assertEqual(self.ф.вершина, итог['git']['коммит'])
        self.assertEqual(до, self.снимок())

    def test_ссылка_вместо_квитанции_или_каталога_отклоняется(self):
        for каталог in (False, True):
            with self.subTest(каталог=каталог):
                путь = self.ф.доставка if каталог else self.ф.квитанция
                резерв = путь.with_name(путь.name + '.резерв')
                путь.rename(резерв); путь.symlink_to(резерв, target_is_directory=каталог)
                try:
                    with self.assertRaises((ValueError, OSError)): self.читать()
                finally:
                    путь.unlink(); резерв.rename(путь)

    def test_жёсткая_ссылка_не_принимается_при_верном_SHA(self):
        os.link(self.ф.квитанция, self.ф.приватное / 'дубликат')
        with self.assertRaises((ValueError, OSError)): self.читать()

    def test_частичная_пара_не_восстанавливается(self):
        for путь in (self.ф.намерение.with_suffix('.начато.json'), self.ф.конверт.with_name('готово.json')):
            сырой = путь.read_bytes(); путь.unlink()
            try:
                with self.assertRaises((ValueError, OSError)): self.читать()
                self.assertFalse(os.path.lexists(путь))
            finally: self.ф.записать_приватно(путь, сырой)

    def test_самосогласованная_иная_приёмка_не_заменяет_Git_свидетельство(self):
        о = copy.deepcopy(self.ф.основание); о['приёмка']['решение']['граница'] = 'Чужая граница'
        о['sha256'] = хранение.хэш({к: з for к, з in о.items() if к != 'sha256'})
        self.ф.сохранить_намерение(о)
        self.ф.описание_чтения['намерение_sha256'] = self.ф.sha(self.ф.намерение)
        with self.assertRaises(ValueError): self.читать()

    def test_самосогласованная_привязка_legacy_и_вход_коммита_строги(self):
        for путь, значение in ((self.ф.доставка / 'получатель.json', {'корень': str(self.ф.цель), 'начато': 1}),
                (self.ф.доставка / 'активная.json', {'идентификатор': '0' * 64}),
                (self.ф.вход_коммита, {**self.ф.параметры, 'источник_модели': '/tmp/чужой.jsonl'})):
            сырой = путь.read_bytes(); self.ф.записать_приватно(путь, значение)
            try:
                with self.assertRaises(ValueError): self.читать()
            finally: self.ф.записать_приватно(путь, сырой)

    def test_грязное_дерево_и_индекс_не_сводятся_к_прежнему_HEAD(self):
        p = self.ф.цель / 'работа.txt'; сырой = p.read_bytes()
        for индекс in (False, True):
            p.write_text('Изменение\n')
            if индекс: гит(self.ф.цель, 'add', 'работа.txt')
            try:
                with self.assertRaises(ValueError): self.читать()
            finally:
                p.write_bytes(сырой); гит(self.ф.цель, 'reset', '--', 'работа.txt')

    def test_новый_ignored_файл_учитывается_при_чистом_tracked_diff(self):
        (self.ф.цель / 'новое.private').write_bytes(b'local')
        self.assertEqual('', гит(self.ф.цель, 'diff', '--name-only'))
        with self.assertRaises(ValueError): self.читать()

    def test_поздний_результат_и_висячая_ссылка_не_считаются_отсутствием(self):
        пути = [Path(self.ф.параметры[к]) for к in ('подготовка', 'квитанция')]
        пути += [self.ф.намерение.with_suffix('.журнал.json'), self.ф.цель / self.ф.блок['журнал']]
        for p in пути:
            with self.subTest(путь=p.name):
                p.parent.mkdir(parents=True, exist_ok=True)
                p.symlink_to(self.ф.папка / 'не существует')
                try:
                    with self.assertRaises((ValueError, OSError)): self.читать()
                finally: p.unlink()

    def test_подмена_между_чистой_проверкой_и_возвратом_отклоняется(self):
        исходная = чистый.проверить
        достигнут = []
        def подмена(*а):
            результат = исходная(*а)
            достигнут.append(True)
            self.ф.записать_приватно(self.ф.доставка / 'активная.json', {'идентификатор': '0' * 64})
            return результат
        with mock.patch.object(чистый, 'проверить', side_effect=подмена), self.assertRaises(ValueError):
            self.читать()
        self.assertEqual([True], достигнут)

    def test_каноничность_права_и_предел_файла_проверяются(self):
        p = self.ф.конверт.with_name('готово.json'); сырой = p.read_bytes()
        for текст, режим in ((b' '+сырой, 0o600), (сырой, 0o644), (b' '*1048577, 0o600)):
            self.ф.записать_приватно(p, текст); p.chmod(режим)
            try:
                with self.assertRaises((ValueError, OSError)): self.читать()
            finally: self.ф.записать_приватно(p, сырой)

    def test_реестр_из_другого_входа_отклоняется(self):
        self.ф.записать_приватно(self.ф.реестр_пакета, {})
        with self.assertRaisesRegex(ValueError, 'реестр владельцев'): self.читать()

    def test_согласованное_ложное_дерево_плана_не_заменяет_настоящую_приёмку(self):
        with tempfile.TemporaryDirectory(prefix='fum-ложный-план-') as временное:
            ф = ФикстураИсторическогоОтказа(временное, подменённое_дерево=True)
            with mock.patch.object(конверт, 'КОРЕНЬ_СОСТОЯНИЯ', ф.приватное), \
                    mock.patch.object(эпизод, 'КОРЕНЬ_СОСТОЯНИЯ', ф.приватное / 'эпизоды'), \
                    self.assertRaisesRegex(ValueError, 'План.*приёмк'):
                читатель.прочитать(ф.описание_чтения, ф.текст, ф.нативный)

    def test_сдвиг_Git_после_чистой_проверки_отклоняется(self):
        исходная = чистый.проверить; достигнут = []
        def сдвиг(*а):
            результат = исходная(*а); достигнут.append(True)
            self.ф.записать(self.ф.цель, 'новая-работа.txt', 'Поздняя работа\n')
            self.ф.коммит(self.ф.цель)
            return результат
        with mock.patch.object(чистый, 'проверить', side_effect=сдвиг), self.assertRaisesRegex(ValueError, 'после H'):
            self.читать()
        self.assertEqual([True], достигнут)

    @unittest.skipUnless(hasattr(os, 'mkfifo'), 'Нужна POSIX FIFO')
    def test_FIFO_после_lstat_не_блокирует_открытие(self):
        код = '''
import json, os, sys
from pathlib import Path
from unittest import mock
sys.path.insert(0, sys.argv[1])
import прочитать_исторический_отказ as ч
import приватные_файлы_отказа as ф
import конверт_приёма as к
import эпизод_приёма as э
цель=Path(sys.argv[3]); original=os.open; подменено=[]
def гонка(путь, flags, *а, **kw):
 if Path(путь)==цель and not подменено:
  цель.unlink(); os.mkfifo(цель, 0o600); подменено.append(True)
 return original(путь,flags,*а,**kw)
with mock.patch.object(к,'КОРЕНЬ_СОСТОЯНИЯ',Path(sys.argv[2])), \\
     mock.patch.object(э,'КОРЕНЬ_СОСТОЯНИЯ',Path(sys.argv[2])/'эпизоды'), \\
     mock.patch.object(ф.os,'open',side_effect=гонка):
 try: ч.прочитать(json.loads(sys.argv[4]),sys.argv[5],sys.argv[6])
 except (ValueError,OSError):
  assert подменено==[True]; print('FIFO отклонена без блокировки')
 else: raise AssertionError('FIFO принята')
'''
        результат = subprocess.run([sys.executable, '-B', '-c', код,
            str(Path(читатель.__file__).parent), str(self.ф.приватное), str(self.ф.квитанция),
            хранение.байты(self.ф.описание_чтения).decode(), self.ф.текст, self.ф.нативный],
            capture_output=True, timeout=8)
        self.assertEqual(0, результат.returncode, результат.stderr.decode())
        self.assertIn('FIFO отклонена', результат.stdout.decode())


if __name__ == '__main__': unittest.main()
