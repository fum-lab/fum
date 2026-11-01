"""Один индекс использует один пакет H; независимый вызов читает H заново."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

from test_двух_общих_проходов import стенд, снимок
import профиль_повторных_построений_индекса as профиль


def состав(р):
    return json.loads((р.ф.корень / р.ж.ПУТЬ_СОСТАВА).read_bytes())


class ОдинПакетПринятогоИндекса(unittest.TestCase):
    def test_одно_построение_читает_пакет_один_раз_с_прежними_байтами(сам):
        with стенд(4) as (р, _):
            вход = состав(р)
            ожидаемое = (р.ф.корень / р.ж.ПУТЬ_ИНДЕКСА).read_bytes()
            до = снимок(р)
            with mock.patch.object(р.ж, '_файлы_коммита',
                    wraps=р.ж._файлы_коммита) as чтение:
                результат = р.ж.построить_принятый_индекс(р.ф.корень, вход)
            сам.assertEqual(результат['байты'], ожидаемое)
            сам.assertEqual(чтение.call_count, 1)
            сам.assertEqual(до, снимок(р))

    def test_следующее_построение_не_возвращает_старый_результат_после_отказа(сам):
        with стенд(4) as (р, _):
            вход = состав(р)
            исходный = р.ж._файлы_коммита
            вызовов = 0
            ошибка = OSError('Принятый объект стал недоступен')

            def прочитать(*а, **к):
                nonlocal вызовов
                вызовов += 1
                if вызовов == 2:
                    raise ошибка
                return исходный(*а, **к)

            до = снимок(р)
            with mock.patch.object(р.ж, '_файлы_коммита', прочитать):
                р.ж.построить_принятый_индекс(р.ф.корень, вход)
                with сам.assertRaises(OSError) as исход:
                    р.ж.построить_принятый_индекс(р.ф.корень, вход)
            сам.assertIs(исход.exception, ошибка)
            сам.assertEqual(вызовов, 2)
            сам.assertEqual(до, снимок(р))

    def test_первичный_отказ_не_вызывает_навигацию_и_повтор(сам):
        with стенд(4) as (р, _):
            вход = состав(р)
            до = снимок(р)
            ошибка = ValueError('Неверный пакет Git')
            with mock.patch.object(р.ж, '_файлы_коммита',
                    side_effect=ошибка) as чтение, mock.patch.object(
                    р.ж.индексы, 'построить_индекс') as навигация:
                with сам.assertRaises(ValueError) as исход:
                    р.ж.построить_принятый_индекс(р.ф.корень, вход)
            сам.assertIs(исход.exception, ошибка)
            сам.assertEqual(чтение.call_count, 1)
            навигация.assert_not_called()
            сам.assertEqual(до, снимок(р))


class ГраницаВыходаПрофиля(unittest.TestCase):
    def test_bare_Git_отказывает_до_подготовки_фикстуры(сам):
        with tempfile.TemporaryDirectory() as каталог:
            bare = Path(каталог).resolve() / 'bare.git'
            subprocess.run(['git', 'init', '--bare', str(bare)], check=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            выход = bare / 'измерение.json'
            with mock.patch.object(sys, 'argv', ['профиль', '--выход', str(выход)]), \
                    mock.patch.object(профиль, 'стенд',
                        side_effect=AssertionError('Началась подготовка фикстуры')) as подготовка:
                with сам.assertRaisesRegex(ValueError, 'вне Git'):
                    профиль.главная()
            подготовка.assert_not_called()
            сам.assertFalse(выход.exists())


if __name__ == '__main__':
    unittest.main()
