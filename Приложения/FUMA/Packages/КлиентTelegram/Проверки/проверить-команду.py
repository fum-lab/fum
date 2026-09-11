#!/usr/bin/env python3
"""Проверка справки и закрытых отказов собранной команды; настоящую TDLib не подменяет."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def проверить(исполняемый: Path) -> None:
    справка = subprocess.run([str(исполняемый), '--help'], capture_output=True, text=True, timeout=10, check=True)
    assert '--библиотека' in справка.stdout and 'без аккаунта' in справка.stdout
    случаи = [
        ([], 'неверные_входы'),
        (['--raw', 'sendMessage'], 'неверные_входы'),
        (['--библиотека', 'относительный.dylib'], 'неверные_входы'),
        (['--библиотека', '/несуществующий/tdjson.dylib', '--простой-секунд', '0'], 'неверные_входы'),
        (['--библиотека', '/несуществующий/tdjson.dylib'], 'библиотека_недоступна'),
    ]
    for аргументы, ошибка in случаи:
        результат = subprocess.run([str(исполняемый), *аргументы], capture_output=True, text=True, timeout=15)
        assert результат.returncode == 2, (аргументы, результат.returncode)
        отчёт = json.loads(результат.stdout)
        assert отчёт['схема'] == 'fum.автономный-запуск-телеграма.1'
        assert отчёт['библиотекаЗагружена'] is False
        assert отчёт['ошибка'] == ошибка
        assert 'начальныйОтвет' not in отчёт and 'простой' not in отчёт and 'закрытие' not in отчёт
    print(json.dumps({'случаев': len(случаи) + 1, 'исход': 'успех',
                      'исполняемый_sha256': hashlib.sha256(исполняемый.read_bytes()).hexdigest()}, ensure_ascii=False))


if __name__ == '__main__':
    assert len(sys.argv) == 2, 'Требуется абсолютный путь собранной команды'
    исполняемый = Path(sys.argv[1])
    assert исполняемый.is_absolute() and исполняемый.is_file()
    проверить(исполняемый)
