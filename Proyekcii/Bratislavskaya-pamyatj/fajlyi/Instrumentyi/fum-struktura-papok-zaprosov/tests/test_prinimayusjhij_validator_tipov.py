"""Принимающая реализация проверяет только данные типов чужого кандидата."""
import copy
import json
from pathlib import Path
import unittest

import test_расширение_шаблонов as образцы
from test_request_folder_layout import RepositoryFixture
import request_folder_layout as принимающий


class ПроверкаПринимающегоВалидатораТипов(unittest.TestCase):
    def setUp(сам):
        сам.фикстура = RepositoryFixture()
        сам.addCleanup(сам.фикстура.close)
        сам.фикстура.make_canonical_layout()
        сам.корень = сам.фикстура.root
        сам.область = сам.корень / образцы.ОБЛАСТЬ

    def установить(сам):
        описание = {к: з for к, з in copy.deepcopy(образцы.ОПИСАНИЕ).items() if к != 'шаблон'}
        сам.фикстура.write(str(образцы.ОБЛАСТЬ / 'типы/вопрос.json'),
                          json.dumps(описание, ensure_ascii=False))
        сам.фикстура.write(str(образцы.ОБЛАСТЬ / 'шаблоны/вопрос.md.шаблон'), образцы.ШАБЛОН)

    def проверить(сам):
        return принимающий.validate_layout(сам.корень)

    def отказ(сам):
        with сам.assertRaisesRegex(принимающий.LayoutError, 'несовместимый установленный шаблон'):
            сам.проверить()

    def test_историческое_отсутствие_не_создаёт_каталог(сам):
        сам.проверить()
        сам.assertFalse(сам.область.exists())

    def test_совместимые_данные_сохраняются(сам):
        сам.установить()
        до = {п: п.read_bytes() for п in сам.область.rglob('*') if п.is_file()}
        сам.проверить()
        сам.assertEqual(до, {п: п.read_bytes() for п in до})

    def test_повреждение_неполнота_и_несовместимость_отклоняются(сам):
        for вид in ('JSON', 'шаблон отсутствует', 'несовместимый шаблон', 'имя типа'):
            with сам.subTest(вид=вид):
                сам.установить()
                описание = сам.область / 'типы/вопрос.json'
                шаблон = сам.область / 'шаблоны/вопрос.md.шаблон'
                if вид == 'JSON':
                    описание.write_text('{')
                elif вид == 'шаблон отсутствует':
                    шаблон.unlink()
                elif вид == 'несовместимый шаблон':
                    шаблон.write_text('# Повреждённый шаблон\n')
                else:
                    данные = json.loads(описание.read_text())
                    данные['тип'] = 'другой'
                    описание.write_text(json.dumps(данные, ensure_ascii=False))
                сам.отказ()

    def test_символическая_ссылка_вместо_пустого_и_отсутствующего_каталога(сам):
        сам.область.mkdir(parents=True)
        цель = сам.корень / 'пустой'
        for существует in (False, True):
            with сам.subTest(существует=существует):
                if существует:
                    цель.mkdir()
                ссылка = сам.область / 'типы'
                ссылка.symlink_to(цель, target_is_directory=True)
                try:
                    сам.отказ()
                finally:
                    ссылка.unlink()

    def test_символическая_ссылка_предка_при_пустом_и_отсутствующем_каталоге(сам):
        for глубина in (1, 2):
            for существует in (False, True):
                with сам.subTest(глубина=глубина, существует=существует):
                    цель = сам.корень / f'цель-{глубина}-{существует}'
                    цель.mkdir()
                    части = образцы.ОБЛАСТЬ.parts
                    ссылка = сам.корень.joinpath(*части[:глубина])
                    ссылка.parent.mkdir(parents=True, exist_ok=True)
                    if существует:
                        цель.joinpath(*части[глубина:], 'типы').mkdir(parents=True)
                    ссылка.symlink_to(цель, target_is_directory=True)
                    try:
                        сам.отказ()
                    finally:
                        ссылка.unlink()

    def test_неверный_регистр_пустого_каталога_и_предков(сам):
        for части in (('инструменты',), ('Инструменты', 'Fum-struktura-papok-zaprosov'),
                      ('Инструменты', 'fum-struktura-papok-zaprosov', 'Типы')):
            with сам.subTest(части=части):
                путь = сам.корень.joinpath(*части)
                путь.mkdir(parents=True)
                try:
                    сам.отказ()
                finally:
                    путь.rmdir()

    def test_ссылки_и_регистр_описания_и_шаблона(сам):
        сам.установить()
        for относительный in ('типы/вопрос.json', 'шаблоны/вопрос.md.шаблон'):
            путь = сам.область / относительный
            данные = путь.read_bytes()
            цель = сам.корень / 'байты-фикстуры'
            цель.write_bytes(данные)
            путь.unlink()
            путь.symlink_to(цель)
            сам.отказ()
            путь.unlink()
            иной = путь.with_name('В' + путь.name[1:])
            иной.write_bytes(данные)
            сам.отказ()
            иной.unlink()
            путь.write_bytes(данные)

    def test_исполняемые_файлы_кандидата_не_загружаются(сам):
        сам.установить()
        for имя in ('request_folder_layout.py', 'расширение_шаблонов.py'):
            сам.фикстура.write(str(образцы.ОБЛАСТЬ / 'scripts' / имя),
                              "raise AssertionError('код кандидата исполнен')\n")
        сам.проверить()


if __name__ == '__main__':
    unittest.main()
