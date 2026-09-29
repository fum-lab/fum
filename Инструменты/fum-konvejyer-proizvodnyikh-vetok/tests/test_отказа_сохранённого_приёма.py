"""Известная обёртка подтверждает CLI-отказ только вместе с его исходным каналом."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest

for каталог in ('fum-konvejyer-proizvodnyikh-vetok', 'fum-reyestr-planirovaniya'):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / каталог / 'scripts'))
from test_отказа_нативного_приёма import образец, строка
import отказ_сохранённого_приёма as отказ


def сохранённый():
    мета, событие, цель = образец()
    путь = '/private/var/tmp/fum-soobsjheniya-' + цель['задача'] + '/ответ-приёма.json'
    исходный = событие['payload']['item']['stdout'].encode()
    программа = f"""python3 -B - <<'PY'
from pathlib import Path
import subprocess,json,os
корень=Path({цель['корень']!r})
приватный=Path({str(Path(путь).parent)!r})
assert приватный.is_dir() and not приватный.is_symlink()
assert приватный.stat().st_uid==os.getuid() and приватный.stat().st_mode & 0o777 == 0o700
цель=приватный/'ответ-приёма.json'
assert not цель.exists()
команда=['python3','-B','Инструменты/fum-konvejyer-proizvodnyikh-vetok/scripts/подготовить-приём.py','принять','--исходник',{цель['исходник']!r}]
with цель.open('x') as файл:
    процесс=subprocess.run(команда,cwd=корень,stdout=файл,text=True)
print('код:',процесс.returncode)
print('ответ:',цель.read_text())
raise SystemExit(процесс.returncode)
PY"""
    э = событие['payload']['item']
    э['command'][2] = программа
    э['stdout'] = 'код: 2\nответ: ' + исходный.decode() + '\n'
    цель['конец'] = len(мета) + len(строка(событие))
    цель['sha256'] = hashlib.sha256(строка(событие)).hexdigest()
    артефакт = {'путь': путь, 'байты': len(исходный), 'sha256': hashlib.sha256(исходный).hexdigest()}
    return мета, событие, цель, исходный, артефакт


class ПроверкаОтказаСохранённогоПриёма(unittest.TestCase):
    def проверить(self, м, с, ц, сырые, а):
        return отказ.проверить(м + строка(с), ц, сырые, а)

    def пересчитать(self, м, с, ц):
        ц['конец'] = len(м) + len(строка(с)); ц['sha256'] = hashlib.sha256(строка(с)).hexdigest()

    def test_исходный_канал_и_канал_обёртки_различаются(self):
        м, с, ц, сырые, а = сохранённый(); до = copy.deepcopy((ц, а))
        р = self.проверить(м, с, ц, сырые, а)
        self.assertEqual(2, р['код']); self.assertEqual('unknown', р['исход_прежнего_слияния'])
        self.assertFalse(р['повтор_эффекта_разрешён'])
        self.assertEqual(а['sha256'], р['stdout_sha256'])
        self.assertEqual(hashlib.sha256(с['payload']['item']['stdout'].encode()).hexdigest(),
                         р['обёртка']['stdout_sha256'])
        self.assertNotEqual(р['stdout_sha256'], р['обёртка']['stdout_sha256'])
        self.assertEqual(до, (ц, а))

    def test_похожая_но_другая_обёртка_не_исполняется_и_не_принимается(self):
        for изменение in ('cwd=корень', 'stdout=файл', 'text=True', "raise SystemExit(процесс.returncode)", "<<'PY'"):
            with self.subTest(изменение=изменение):
                м, с, ц, сырые, а = сохранённый()
                э = с['payload']['item']; э['command'][2] = э['command'][2].replace(изменение, изменение + ' # подмена')
                self.пересчитать(м, с, ц)
                with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_другой_исходник_каталог_и_дополнительная_shell_команда_отклоняются(self):
        for изменение in ('источник', 'каталог', 'shell'):
            with self.subTest(изменение=изменение):
                м, с, ц, сырые, а = сохранённый(); э = с['payload']['item']
                if изменение == 'источник': э['command'][2] = э['command'][2].replace(ц['исходник'], '/иной/источник')
                elif изменение == 'каталог': э['command'][2] = э['command'][2].replace(ц['корень'], '/иной/корень')
                else: э['command'][2] += '\ngit merge иная-ветка'
                self.пересчитать(м, с, ц)
                with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_канал_обёртки_должен_побайтно_содержать_исходный_ответ(self):
        for вывод in ('код: 0\nответ: ', 'только JSON', 'лишний хвост', 'CRLF', 'двойной LF', 'нет LF'):
            with self.subTest(вывод=вывод):
                м, с, ц, сырые, а = сохранённый(); э = с['payload']['item']
                if вывод == 'CRLF': э['stdout'] = э['stdout'].replace('\n', '\r\n')
                elif вывод == 'двойной LF': э['stdout'] += '\n'
                elif вывод == 'нет LF': э['stdout'] = э['stdout'][:-1]
                elif вывод == 'только JSON': э['stdout'] = сырые.decode()
                elif вывод == 'лишний хвост': э['stdout'] += 'подмена\n'
                else: э['stdout'] = вывод + сырые.decode() + '\n'
                self.пересчитать(м, с, ц)
                with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_подмена_артефакта_даже_с_новым_хэшем_не_совпадает_с_native(self):
        м, с, ц, сырые, а = сохранённый()
        д = json.loads(сырые); д['длительность_наносекунды'] += 1
        иные = строка(д); а['байты'] = len(иные); а['sha256'] = hashlib.sha256(иные).hexdigest()
        with self.assertRaises(ValueError): self.проверить(м, с, ц, иные, а)

    def test_повреждённый_локатор_артефакта_не_принимается(self):
        for ключ, значение in (('sha256', '0'*64), ('байты', True), ('байты', 1),
                              ('путь', '/private/var/tmp/иной/ответ-приёма.json')):
            with self.subTest(ключ=ключ):
                м, с, ц, сырые, а = сохранённый(); а[ключ] = значение
                with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_оборванный_и_не_utf8_канал_отклоняется(self):
        for сырые in (b'', b'{}', b'\xff\n'):
            with self.subTest(сырые=сырые):
                м, с, ц, _, а = сохранённый()
                а['байты'] = len(сырые); а['sha256'] = hashlib.sha256(сырые).hexdigest()
                with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_код_обёртки_не_подменяется_кодом_git(self):
        м, с, ц, сырые, а = сохранённый(); с['payload']['item']['exit_code'] = 128
        self.пересчитать(м, с, ц)
        with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_известная_обёртка_также_требует_канонический_абсолютный_исходник(self):
        for исходник in ('=python3', '/tmp/../a.jsonl', '//tmp/a.jsonl'):
            with self.subTest(исходник=исходник):
                м, с, ц, сырые, а = сохранённый(); ц['исходник'] = исходник
                с['payload']['item']['command'][2] = отказ.программа(ц, а['путь'])
                self.пересчитать(м, с, ц)
                with self.assertRaises(ValueError): self.проверить(м, с, ц, сырые, а)

    def test_равенство_в_python_argv_остаётся_буквальным_именем(self):
        м, с, ц, сырые, а = сохранённый(); ц['исходник'] = '/tmp/a==python3'
        с['payload']['item']['command'][2] = отказ.программа(ц, а['путь'])
        self.пересчитать(м, с, ц)
        self.assertEqual(2, self.проверить(м, с, ц, сырые, а)['код'])


if __name__ == '__main__':
    unittest.main()
