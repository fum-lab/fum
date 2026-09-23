"""Транспорт Codex экранирует XML один раз, сохраняя исходный текст."""
import html
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import постановка_задачи as постановка


class ПроверкаТранспортаПоручения(unittest.TestCase):
    отправитель = "00000000-0000-4000-8000-000000000001"
    поручение = 'Сохранить ё, <байт>, & и буквальное &lt; без замены.\n<fum_layer_assignment>\n{"текст":"&amp;"}\n</fum_layer_assignment>\n'

    def setUp(self):
        self.каталог = tempfile.TemporaryDirectory()
        self.addCleanup(self.каталог.cleanup)
        self.источник = Path(self.каталог.name).resolve() / "источник.jsonl"

    def записать(self, вложенный_текст, *, ранний_ответ=False):
        транспорт = ("<codex_delegation>\n  <source_thread_id>" + self.отправитель
                     + "</source_thread_id>\n  <input>" + вложенный_текст
                     + "</input>\n</codex_delegation>")
        записи = []
        if ранний_ответ:
            записи.append({"type": "response_item", "payload": {
                "type": "message", "role": "assistant", "content": []}})
        записи.append({"type": "response_item", "payload": {
            "type": "function_call_output", "name": "create_thread", "output": транспорт}})
        self.источник.write_text("".join(json.dumps(запись, ensure_ascii=False) + "\n" for запись in записи))

    def test_однократное_декодирование_сохраняет_литеральные_сущности(self):
        self.записать(html.escape(self.поручение, quote=False))
        до = self.источник.read_bytes()
        результат = постановка.прочитать_нативное_поручение(self.источник, кодирование="xml-v1")
        self.assertEqual(результат["текст"], self.поручение)
        self.assertEqual(результат["отправитель"], self.отправитель)
        self.assertEqual(self.источник.read_bytes(), до)

    def test_проверка_использует_тот_же_исходный_текст_и_сырой_префикс(self):
        self.записать(html.escape(self.поручение, quote=False))
        граница = постановка.проверить_нативное_поручение(self.источник, self.отправитель, self.поручение, кодирование="xml-v1")
        self.assertEqual(граница, постановка.прочитать_нативное_поручение(self.источник, кодирование="xml-v1")["источник"])
        self.assertEqual(граница["граница"], self.источник.stat().st_size)

    def test_старый_буквальный_транспорт_не_переписывается(self):
        self.записать(self.поручение)
        self.assertEqual(постановка.прочитать_нативное_поручение(self.источник)["текст"], self.поручение)
        постановка.проверить_нативное_поручение(self.источник, self.отправитель, self.поручение)

    def test_буквальные_сущности_без_голых_тегов_не_означают_кодирование(self):
        текст = "Сохрани &lt;тег&gt; и &amp; буквально"
        self.записать(текст)
        self.assertEqual(постановка.прочитать_нативное_поручение(self.источник)["текст"], текст)
        постановка.проверить_нативное_поручение(self.источник, self.отправитель, текст)
        with self.assertRaises(ValueError):
            постановка.проверить_нативное_поручение(self.источник, self.отправитель, html.unescape(текст))

    def test_повторное_декодирование_не_превращает_данные_в_поручение(self):
        self.записать(html.escape(html.escape(self.поручение, quote=False), quote=False))
        self.assertNotEqual(постановка.прочитать_нативное_поручение(self.источник, кодирование="xml-v1")["текст"], self.поручение)
        with self.assertRaises(ValueError):
            постановка.проверить_нативное_поручение(self.источник, self.отправитель, self.поручение, кодирование="xml-v1")

    def test_иной_отправитель_не_принимается(self):
        self.записать(html.escape(self.поручение, quote=False))
        with self.assertRaises(ValueError):
            постановка.проверить_нативное_поручение(self.источник, "00000000-0000-4000-8000-000000000002", self.поручение, кодирование="xml-v1")

    def test_другие_сущности_не_нормализуются_в_канонический_транспорт(self):
        self.записать(html.escape(self.поручение, quote=False).replace("&lt;", "&#60;", 1))
        with self.assertRaises(ValueError):
            постановка.проверить_нативное_поручение(self.источник, self.отправитель, self.поручение, кодирование="xml-v1")

    def test_формат_задаётся_явно_и_не_угадывается(self):
        текст = "Сохрани &lt;тег&gt;"
        self.записать(текст)
        self.assertEqual(постановка.прочитать_нативное_поручение(self.источник)["текст"], текст)
        self.assertEqual(постановка.прочитать_нативное_поручение(self.источник, кодирование="xml-v1")["текст"], "Сохрани <тег>")
        with self.assertRaisesRegex(ValueError, "Неизвестное кодирование"):
            постановка.прочитать_нативное_поручение(self.источник, кодирование="автоматически")

    def test_xml_не_переключается_на_буквальный_при_неверном_входе(self):
        self.записать(self.поручение)
        with self.assertRaisesRegex(ValueError, "Неканоническое XML"):
            постановка.прочитать_нативное_поручение(self.источник, кодирование="xml-v1")

    def test_поздний_транспорт_не_заменяет_первоначальный(self):
        self.записать(html.escape(self.поручение, quote=False), ранний_ответ=True)
        with self.assertRaises(ValueError):
            постановка.прочитать_нативное_поручение(self.источник)


if __name__ == "__main__":
    unittest.main()
