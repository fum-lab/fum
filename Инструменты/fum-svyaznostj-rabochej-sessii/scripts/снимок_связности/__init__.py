"""Изолированный срез ссылок, без ready/creator и межвызовного кэша."""
import importlib.util
from pathlib import Path
import sys
КОРЕНЬ = Path(__file__).resolve().parents[4]
ПРЕЖНИЙ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py'
ИНВЕНТАРЬ = 'Инструменты/fum-proyektnyiye-fajlyi/scripts/project_files.py'
ЛЕКСЕР = 'Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py'
ДВИЖОК = 'Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py'
ПАКЕТ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/снимок_связности/'
ИМЕНА_МОДУЛЕЙ = ('модель', 'поднабор', 'пути', 'чтение', 'проверка', 'сверка', 'сравнение')
ПУТИ_КОДА = (ПРЕЖНИЙ, ИНВЕНТАРЬ, ЛЕКСЕР, ДВИЖОК, ПАКЕТ + '__init__.py',
    *(ПАКЕТ + элемент + '.py' for элемент in ИМЕНА_МОДУЛЕЙ))
# Нативный initializer доверенного импорта — граница загрузки. Все остальные
# исполняемые проектные модули компилируются из точных удержанных байтов.
КОД_ЗАГРУЗКИ = tuple((элемент, (КОРЕНЬ / элемент).read_bytes()) for элемент in ПУТИ_КОДА)


def загрузить(имя, путь):
    описание = importlib.util.spec_from_file_location(имя, КОРЕНЬ / путь)
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[имя] = модуль
    exec(compile(dict(КОД_ЗАГРУЗКИ)[путь], str(КОРЕНЬ/путь), 'exec'), модуль.__dict__)
    return модуль


for имя in ИМЕНА_МОДУЛЕЙ[:3]:
    globals()[имя] = загрузить(__name__ + '.' + имя, ПАКЕТ + имя + '.py')
ИСПОЛНЯЕМЫЙ_ПОДНАБОР = (
    поднабор.выделить(dict(КОД_ЗАГРУЗКИ)[ИНВЕНТАРЬ], поднабор.ИМЕНА_ИНВЕНТАРЯ),
    поднабор.выделить(dict(КОД_ЗАГРУЗКИ)[ПРЕЖНИЙ], поднабор.ИМЕНА_ПРЕЖНИЕ))
ПРОЕКТНЫЕ_ФАЙЛЫ = загрузить('fum_snapshot_project_files', ИНВЕНТАРЬ)
ОБЩИЙ_ЛЕКСЕР = загрузить('fum_snapshot_shared_layout', ЛЕКСЕР)
ОБЩИЙ_ЛЕКСЕР._LINK_TOOLS = загрузить('fum_snapshot_link_engine', ДВИЖОК)
for имя in ИМЕНА_МОДУЛЕЙ[3:]:
    globals()[имя] = загрузить(__name__ + '.' + имя, ПАКЕТ + имя + '.py')
собрать = чтение.собрать
проверить = проверка.проверить
вычислить = проверка.вычислить
сверить = сверка.сверить
НеполныйСнимок = модель.НеполныйСнимок
лексические_цели = сравнение.лексические_цели
