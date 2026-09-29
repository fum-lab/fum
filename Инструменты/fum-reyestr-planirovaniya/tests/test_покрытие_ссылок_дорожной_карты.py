"""Покрытие горизонтов сохраняется для ссылки на сам файл и локального якоря."""
from pathlib import Path
import tempfile
import unittest

import test_build_planning_registry as основа


class СсылкиГоризонтов(unittest.TestCase):
    def test_дорожная_карта_принимает_ссылки_на_собственный_файл(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            основа.BuildPlanningRegistryTests().write_fixture(корень)
            карта = корень / 'Планирование/дорожная-карта.md'
            исходник = карта.read_text()
            сам.assertEqual(9, исходник.count('](#горизонт-'))
            карта.write_text(исходник.replace('](#горизонт-', '](дорожная-карта.md#горизонт-'))
            реестр = основа.build_planning_registry.build_registry(корень)
            горизонты = [к for к in реестр['source_inventory']['покрытие_дорожной_карты'] if к['вид'] == 'горизонт']
            сам.assertEqual([f'horizon-{н}' for н in range(9)], [к['идентификатор'] for к in горизонты])
            сам.assertTrue(all(к['файл'].startswith('Планирование/дорожная-карта.md#горизонт-') for к in горизонты))
            сам.assertEqual(['FUM-STEP-0001'], горизонты[0]['карточки'])
            сам.assertTrue(all(к['карточки'] == [] for к in горизонты[1:]))
            сам.assertEqual([], основа.build_planning_registry.validate_registry_object(реестр))

    def test_чужой_файл_и_неизвестный_якорь_отклоняются(сам):
        for замена in ('чужая-карта.md#горизонт-', 'дорожная-карта.md#неизвестный-горизонт-'):
            with сам.subTest(замена=замена), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                основа.BuildPlanningRegistryTests().write_fixture(корень)
                карта = корень / 'Планирование/дорожная-карта.md'
                исходник = карта.read_text(encoding='utf-8')
                сам.assertEqual(9, исходник.count('](#горизонт-'))
                карта.write_text(исходник.replace('](#горизонт-', '](' + замена, 1), encoding='utf-8')
                with сам.assertRaisesRegex(ValueError, 'roadmap coverage has unknown contours'):
                    основа.build_planning_registry.build_registry(корень)


if __name__ == '__main__':
    unittest.main()
