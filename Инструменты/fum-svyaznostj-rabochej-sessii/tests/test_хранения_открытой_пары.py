"""Перемещение собственной начальной пары без потери байтов и повторного эффекта."""
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from хранение_открытой_пары import проверить, переместить
import хранение_открытой_пары as хранение


class ХранениеПары(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / 'пара'
        self.source.mkdir()
        self.dest = self.root / 'сохранённая'
        self.files = []
        for name in ('запрос.md', 'отчёт.md'):
            p = self.source / name
            p.write_bytes(name.encode())
            p.chmod(0o644)
            self.files.append({'путь': 'Журнал/пара/' + name,
                'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'режим': 0o644})
        self.plan = {'файлы': self.files}

    def test_перенос_повтор_возврат_сохраняют_идентичность(self):
        (self.source / 'материалы').mkdir()
        before = проверить(self.source, self.plan)
        self.assertFalse(переместить(self.source, self.dest, self.plan, before)['повтор'])
        self.assertFalse(self.source.exists())
        self.assertEqual(проверить(self.dest, self.plan), before)
        self.assertTrue(переместить(self.source, self.dest, self.plan, before)['повтор'])
        self.assertFalse(переместить(self.dest, self.source, self.plan, before)['повтор'])
        self.assertEqual(проверить(self.source, self.plan), before)

    def test_возврат_после_прерывания_до_квитанции(self):
        before = проверить(self.source, self.plan)
        переместить(self.source, self.dest, self.plan, before)
        receipt = self.root / 'квитанция.json'
        basis = {'проверенная_установка': 'S2'}
        with patch.object(хранение, '_сохранить_квитанцию', side_effect=OSError('прерывание')):
            with self.assertRaises(OSError):
                хранение.вернуть_с_квитанцией(self.dest, self.source, self.plan, before, receipt, basis)
        self.assertTrue(self.source.exists())
        self.assertFalse(receipt.exists())
        хранение.вернуть_с_квитанцией(self.dest, self.source, self.plan, before, receipt, basis)
        self.assertEqual(проверить(self.source, self.plan), before)
        self.assertEqual(json.loads(receipt.read_bytes())['результат'], {'повтор': True})
        raw, mtime = receipt.read_bytes(), receipt.stat().st_mtime_ns
        хранение.вернуть_с_квитанцией(self.dest, self.source, self.plan, before, receipt, basis)
        self.assertEqual((receipt.read_bytes(), receipt.stat().st_mtime_ns), (raw, mtime))

    def test_чужая_квитанция_отказывает_до_возврата(self):
        before = проверить(self.source, self.plan)
        переместить(self.source, self.dest, self.plan, before)
        receipt = self.root / 'квитанция.json'
        receipt.write_text(json.dumps({'другое': True}))
        with self.assertRaises(ValueError):
            хранение.вернуть_с_квитанцией(self.dest, self.source, self.plan, before, receipt, {'S2': 'принят'})
        self.assertFalse(self.source.exists())
        self.assertEqual(проверить(self.dest, self.plan), before)

    def test_лишние_данные_запрещают_перенос(self):
        before = проверить(self.source, self.plan)
        (self.source / 'новое').write_text('не терять')
        with self.assertRaises(ValueError):
            переместить(self.source, self.dest, self.plan, before)
        self.assertTrue((self.source / 'новое').exists())

    def test_изменённые_байты_или_права_запрещены(self):
        before = проверить(self.source, self.plan)
        p = self.source / 'запрос.md'
        p.chmod(0o600)
        with self.assertRaises(ValueError):
            переместить(self.source, self.dest, self.plan, before)
        p.chmod(0o644)
        p.write_text('изменено')
        with self.assertRaises(ValueError):
            переместить(self.source, self.dest, self.plan, before)

    def test_оба_назначения_не_перезаписываются(self):
        before = проверить(self.source, self.plan)
        self.dest.mkdir()
        with self.assertRaises(ValueError):
            переместить(self.source, self.dest, self.plan, before)
        self.assertTrue(self.source.is_dir())
        self.assertTrue(self.dest.is_dir())

    def test_ссылки_и_непустые_материалы_запрещены(self):
        p = self.source / 'запрос.md'
        raw = p.read_bytes()
        p.unlink()
        (self.root / 'внешний').write_bytes(raw)
        p.symlink_to(self.root / 'внешний')
        with self.assertRaises(ValueError):
            проверить(self.source, self.plan)
        p.unlink()
        p.write_bytes(raw)
        p.chmod(0o644)
        (self.source / 'материалы').mkdir()
        (self.source / 'материалы/не_терять').write_text('данные')
        with self.assertRaises(ValueError):
            проверить(self.source, self.plan)


if __name__ == '__main__':
    unittest.main()
