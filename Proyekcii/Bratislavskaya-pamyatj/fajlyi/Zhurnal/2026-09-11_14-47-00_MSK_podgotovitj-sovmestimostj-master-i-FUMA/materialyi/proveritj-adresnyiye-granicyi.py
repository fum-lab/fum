import sys,unittest
from pathlib import Path
корень=Path.cwd()
for имя in ('fum-bratislavskaya-proyekciya-pamyati','fum-perevod-obyyavlenij-koda-na-russkij-yazyik','fum-reyestr-planirovaniya','fum-svyaznostj-rabochej-sessii','fum-struktura-papok-zaprosov'):
    sys.path.insert(0,str(корень.joinpath('Инструменты',имя,'tests')))
import test_братиславская_проекция_памяти as основа
класс=основа.ПроверкаКонтрактаБратиславскойПроекции
имена=[имя for имя in dir(класс) if имя.startswith(('test_переход_прежнего_v2_', 'test_форматы_приложения_')) or имя in ('test_разрешение_исключений_приложения_не_расширяет_неизвестные_пути','test_дополнительный_формат_приложения_требует_изменения_контракта','test_константы_схем_совпадают_с_форматами_контракта_плана_и_манифеста')]
набор=unittest.TestSuite(класс(имя) for имя in имена)
for имя in ('test_шаблон_адаптера','test_проекция_конечного_адаптера','test_пустые_связи_требований','test_необязательный_граф','test_проекция_необязательного_графа','test_принимающий_валидатор_типов','test_расширение_шаблонов'):
    набор.addTests(unittest.defaultTestLoader.loadTestsFromName(имя))
итог=unittest.TextTestRunner(verbosity=1).run(набор)
sys.exit(not итог.wasSuccessful())
