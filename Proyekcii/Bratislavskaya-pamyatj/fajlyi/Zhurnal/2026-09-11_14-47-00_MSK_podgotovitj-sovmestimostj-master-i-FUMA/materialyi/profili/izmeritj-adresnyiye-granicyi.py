import sys,json,hashlib,statistics,io,unittest,cProfile,pstats
from pathlib import Path
from time import perf_counter_ns
корень=Path.cwd()
for имя in ('fum-bratislavskaya-proyekciya-pamyati','fum-reyestr-planirovaniya','fum-struktura-papok-zaprosov'):
    sys.path.insert(0,str(корень.joinpath('Инструменты',имя,'tests')))
import test_проекция_конечного_адаптера as адаптер
import test_принимающий_валидатор_типов as типы
import test_пустые_связи_требований as связи
выход=Path("Журнал/2026-09-11_14-47-00_MSK_подготовить-совместимость-master-и-FUMA/материалы/профили")
адаптер.измерить_классификацию(выход/'адаптер-проекция.json')
замеры={}
политика=адаптер.политика()
пути=['Приложения/FUMA/macOS/Пример'+суффикс for суффикс in ('.c','.h','.modulemap','.pbxproj','.plist','.entitlements')]+['Приложения/FUMA/macOS/.gitignore']
for повтор in range(5):
    начало=perf_counter_ns()
    for вызов in range(2000):
        for путь in пути:
            assert адаптер.модуль.классифицировать_содержимое(корень,путь,политика,b'text\n')[1]=='сохранить_байты'
    замеры[str(повтор)]=(perf_counter_ns()-начало)/14000
результат={'схема':'fum.профиль-совместимости.1','форматы_нс_на_вызов':замеры,'типы':[],'граница':'Синтетические фикстуры, Swift отсутствует. Типы: полная validate_layout включает Git-инвентарь и текущие шаблоны.'}
for случай in ('историческое отсутствие','совместимый тип','пустой каталог неверного регистра'):
    испытание=типы.ПроверкаПринимающегоВалидатораТипов();испытание.setUp()
    try:
        if случай=='совместимый тип': испытание.установить()
        if случай=='пустой каталог неверного регистра': (испытание.область/'Типы').mkdir(parents=True)
        выборки=[]
        for повтор in range(10):
            начало=perf_counter_ns()
            if случай=='пустой каталог неверного регистра': испытание.отказ()
            else: испытание.проверить()
            выборки.append(perf_counter_ns()-начало)
        результат['типы'].append({'случай':случай,'выборки_нс':выборки,'медиана_нс':statistics.median(выборки)})
    finally: испытание.doCleanups()
профиль=cProfile.Profile();профиль.enable()
итог=unittest.TextTestRunner(stream=io.StringIO()).run(unittest.defaultTestLoader.loadTestsFromModule(связи))
профиль.disable();assert итог.wasSuccessful()
статистика=pstats.Stats(профиль)
результат['связи']={'тестов':итог.testsRun,'всего_вызовов':статистика.total_calls,'секунды':статистика.total_tt,'разбор':[{'функция':ключ[2],'вызовов':значение[1],'собственное_время':значение[2],'включая_детей':значение[3]} for ключ,значение in статистика.stats.items() if ключ[2]=='parse_requirement_relations']}
результат['исходники']={путь:'sha256:'+hashlib.sha256((корень/путь).read_bytes()).hexdigest() for путь in ('Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py','Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py','Инструменты/fum-struktura-papok-zaprosov/scripts/расширение_шаблонов.py','Инструменты/fum-reyestr-planirovaniya/scripts/build-planning-registry.py')}
(выход/'форматы-типы-связи.json').write_text(json.dumps(результат,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(результат,ensure_ascii=False))
