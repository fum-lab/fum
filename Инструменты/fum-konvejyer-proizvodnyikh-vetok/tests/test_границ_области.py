"""Настройки Git и новая зависимость не меняют границы прежнего контракта."""
import builtins
import importlib
import unittest
from unittest import mock

from test_области_писателя import область_фикстура, экспорт, хранение
from test_запуска_слоёв import исполнитель
import запуск_слоёв


class ПроверкаГраницОбласти(unittest.TestCase):
    def test_ignore_submodules_не_скрывает_чужой_gitlink(self):
        with область_фикстура(gitlink=True) as (_, объект, пакет, план, _, дети):
            дерево = дети["события"][0]
            хранение.гит(дерево, "config", "diff.ignoreSubmodules", "all")
            хранение.гит(дерево, "update-index", "--add", "--cacheinfo", "160000," + пакет["постановка"]["коммит"] + ",чужой-модуль")
            with self.assertRaisesRegex(ValueError, "вне области|тип цели"):
                экспорт(объект, план, дети)

    def test_filemode_false_не_скрывает_чужое_право_исполнения(self):
        with область_фикстура() as (_, объект, _, план, _, дети):
            дерево = дети["события"][0]
            хранение.гит(дерево, "config", "core.fileMode", "false")
            путь = дерево / "общий.txt"
            путь.chmod(путь.stat().st_mode | 0o111)
            with self.assertRaisesRegex(ValueError, "вне области"):
                экспорт(объект, план, дети)

    def test_нет_экспортной_зависимости_старое_состояние_читается(self):
        with область_фикстура() as (корень, объект, _, план, _, дети):
            исходный = объект.состояние(план["запуск"])
            импорт = builtins.__import__
            def без_экспорта(имя, *а, **к):
                if имя == "область_писателя":
                    raise ModuleNotFoundError("Недоступна экспортная зависимость")
                return импорт(имя, *а, **к)
            try:
                with mock.patch.object(builtins, "__import__", side_effect=без_экспорта):
                    importlib.reload(запуск_слоёв)
                    новый = исполнитель(корень)
                    self.assertEqual(исходный, новый.состояние(план["запуск"]))
                    with self.assertRaisesRegex(ValueError, "зависимост"):
                        экспорт(новый, план, дети)
            finally:
                importlib.reload(запуск_слоёв)

    def test_дрейф_байтов_при_чтении_отклоняется(self):
        with область_фикстура() as (_, объект, _, план, _, дети):
            import снимок_области
            путь = дети["события"][0] / "Память/события/поток.jsonl"
            путь.parent.mkdir(parents=True)
            путь.write_text('{"событие":1}\n')
            чтение = снимок_области.охват.состояние_пути
            def с_дрейфом(файл):
                данные = чтение(файл)
                if файл == путь:
                    файл.write_bytes(файл.read_bytes() + b' ')
                return данные
            with mock.patch.object(снимок_области.охват, "состояние_пути", side_effect=с_дрейфом):
                with self.assertRaisesRegex(ValueError, "сдвинулось"):
                    экспорт(объект, план, дети)


if __name__ == "__main__":
    unittest.main()
