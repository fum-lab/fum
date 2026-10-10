"""Исполнение конечного доверенного Git-кода K; это не Python sandbox.

Выбор K и доверие к bootstrap задаёт независимый вызывающий контур.
Загрузчик устанавливается до первого проектного импорта в новом -I -S -B
процессе. Перед каждым внешним эффектом вызывающий код обязан вызвать сверить.
"""
import builtins
import hashlib
import importlib.abc
import importlib.machinery
import importlib.util
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import types


def требовать(условие, пояснение):
    if not условие:
        raise ValueError(пояснение)


def вызвать_гит(корень, *аргументы, вход=None):
    среда = {к:в for к,в in os.environ.items() if not к.startswith('GIT_')}
    return subprocess.check_output(['git','--no-optional-locks','-C',str(корень),*аргументы],env=среда,input=вход)


def обычный_путь(корень, относительный):
    п = PurePosixPath(относительный)
    требовать(isinstance(относительный,str) and относительный==п.as_posix()
              and not п.is_absolute() and п.parts and all(элемент not in ('.','..') for элемент in п.parts),
              'нужен канонический относительный путь')
    путь=корень
    for часть in п.parts:
        путь=путь/часть
        требовать(not путь.is_symlink(), 'symlink не является принятым исходником')
    требовать(путь.is_file() and stat.S_ISREG(путь.lstat().st_mode), 'нужен обычный файл')
    return путь


def захватить_набор(корень, коммит, пути, роль):
    корень=Path(корень)
    требовать(корень.is_absolute() and корень==корень.resolve(), 'нужен физический корень')
    требовать(re.fullmatch('[0-9a-f]{40}',коммит) is not None, 'нужен полный Git OID')
    требовать(вызвать_гит(корень,'rev-parse',коммит+'^{commit}').decode().strip()==коммит, 'не найден коммит')
    требовать(type(пути) in (list,tuple) and пути and len(пути)==len(set(пути)), 'нужен конечный уникальный состав')
    физические={п:обычный_путь(корень,п) for п in пути}
    записи=вызвать_гит(корень,'ls-tree','-z',коммит,'--',*пути).split(b'\0')
    требовать(записи[-1]==b'' and len(записи)==len(пути)+1, 'путь отсутствует или неоднозначен в Git')
    состав={}
    for запись in записи[:-1]:
        мета,имя=запись.split(b'\t',1); режим,тип,объект=мета.decode().split();имя=имя.decode()
        требовать(имя in физические and имя not in состав and тип=='blob' and режим in ('100644','100755'), 'нужен обычный Git blob')
        состав[имя]=(режим,объект)
    объекты=list(dict.fromkeys(объект for режим,объект in состав.values()))
    поток=вызвать_гит(корень,'cat-file','--batch',вход=('\n'.join(объекты)+'\n').encode('ascii'))
    позиция=0;байты={}
    for объект in объекты:
        конец=поток.index(b'\n',позиция)
        идентификатор_объекта,тип,длина=поток[позиция:конец].decode('ascii').split();размер=int(длина)
        требовать(идентификатор_объекта==объект and тип=='blob' and размер>=0, 'неверный ответ cat-file')
        начало=конец+1;исходник=поток[начало:начало+размер];позиция=начало+размер+1
        требовать(len(исходник)==размер and поток[позиция-1:позиция]==b'\n' and
                  hashlib.sha1(b'blob '+str(размер).encode()+b'\0'+исходник).hexdigest()==объект,
                  'байты не соответствуют Git blob OID')
        байты[объект]=исходник
    требовать(позиция==len(поток), 'лишний хвост cat-file')
    результат={}
    for относительный in пути:
        путь=физические[относительный];режим,объект=состав[относительный];исходник=байты[объект]
        требовать(путь.read_bytes()==исходник and ('100755' if путь.stat().st_mode & 0o111 else '100644')==режим,
                  'рабочие байты или режим не соответствуют принятому Git')
        if роль=='K':
            требовать(путь.suffix=='.py', 'исполняемый состав содержит только Python-исходники')
        результат[str(путь)]={'путь':относительный,'физический_путь':str(путь),
                            'корень':str(корень),'коммит':коммит,'blob':объект,'режим':режим,
                            'sha256':hashlib.sha256(исходник).hexdigest(),'байты':исходник,'роль':роль}
    return результат


def захватить_источники(корень, принятый_коммит, пути, данные_исходного_коммита=None):
    """K принят извне; данные C захватываются отдельно и не исполняются."""
    код=захватить_набор(корень,принятый_коммит,пути,'K')
    данные={}
    if данные_исходного_коммита is not None:
        требовать(type(данные_исходного_коммита) is dict and set(данные_исходного_коммита)=={'корень','коммит','пути'}, 'нужен точный селектор данных C')
        данные=захватить_набор(данные_исходного_коммита['корень'],данные_исходного_коммита['коммит'],данные_исходного_коммита['пути'],'C')
        требовать(not set(код)&set(данные), 'код K и данные C имеют отдельные физические пути')
    return Контур(код,данные)


class Контур:
    def __init__(сам, код, данные):
        сам._код=код; сам._данные=данные
        сам.данные_исходного_коммита={элемент['путь']:элемент['байты'] for элемент in данные.values()}
        сам.журнал=[]; сам.глобальные={}
        сам._исполнен=False

    def сверить(сам):
        """Отказ до следующего эффекта; уже совершённые эффекты не откатываются."""
        for запись in [*сам._код.values(),*сам._данные.values()]:
            try:
                путь=обычный_путь(Path(запись['корень']),запись['путь'])
                требовать(путь.read_bytes()==запись['байты'] and
                          ('100755' if путь.stat().st_mode & 0o111 else '100644')==запись['режим'],
                          'изменились принятые байты или режим')
            except (OSError,ValueError) as ошибка:
                raise ValueError(('данные C' if запись['роль']=='C' else 'код K')+' изменились') from ошибка

    def исполнить(сам, точка_входа, *, имена, аргументы_запуска=()):
        """Однократный запуск; процесс после него завершается, hooks не снимаются."""
        требовать(sys.flags.isolated and sys.flags.no_site and sys.dont_write_bytecode,
                  'исполнение требует нового процесса -I -S -B')
        требовать(not сам._исполнен, 'повтор в том же процессе запрещён')
        сам.сверить()
        корень=next(iter(сам._код.values()))['корень']
        вход=str(Path(корень)/точка_входа)
        требовать(вход in сам._код, 'точка входа отсутствует в конечном составе')
        требовать(type(имена) is dict and all(type(и) is str and type(п) is str for и,п in имена.items()), 'нужен конечный реестр имён')
        псевдонимы={и:str(Path(корень)/п) for и,п in имена.items()}
        требовать(all(п in сам._код and и.split('.')[0] not in sys.stdlib_module_names for и,п in псевдонимы.items()),
                  'неизвестный путь или коллизия со стандартной библиотекой')
        for модуль in tuple(sys.modules.values()):
            файл=getattr(модуль,'__file__',None)
            требовать(not файл or str(Path(файл).absolute()) not in сам._код, 'проектный код загружен до допуска')
        сам._исполнен=True
        исполнение=Исполнение(сам,псевдонимы)
        sys.meta_path.insert(0,исполнение)
        setattr(builtins,'compile',исполнение.compile)
        setattr(importlib.util,'spec_from_file_location',исполнение.создать_спецификацию)
        sys.addaudithook(исполнение.аудит)
        sys.__dict__['argv']=[вход,*аргументы_запуска]
        модуль=types.ModuleType('__main__')
        модуль.__file__=вход; модуль.__package__=None
        модуль.__dict__.update(сам.глобальные)
        sys.modules['__main__']=модуль
        exec(исполнение.get_code(вход),модуль.__dict__)
        сам.сверить()


class Загрузчик(importlib.abc.Loader):
    def __init__(сам, исполнение, путь):
        сам.исполнение=исполнение; сам.путь=путь

    def create_module(сам, spec):
        return None

    def exec_module(сам, модуль):
        модуль.__file__=сам.путь
        exec(сам.get_code(модуль.__name__),модуль.__dict__)

    def get_code(сам, имя):
        # Никогда не обращаемся к SourceFileLoader или pyc.
        return сам.исполнение.get_code(сам.путь)


class Исполнение(importlib.abc.MetaPathFinder):
    def __init__(сам, контур, псевдонимы):
        сам.контур=контур; сам.псевдонимы=псевдонимы
        сам.исходная_компиляция=builtins.compile; сам.исходная_спецификация=importlib.util.spec_from_file_location
        сам._коды={}
        сам.стандартная_библиотека=Path(os.__file__).resolve().parent

    def стандартный(сам, имя_файла):
        if re.fullmatch(r'<frozen [\w.]+>',имя_файла) or имя_файла=='<built-in>':
            return True
        путь=Path(имя_файла)
        return (путь.is_absolute() and путь==путь.resolve() and
                путь.is_relative_to(сам.стандартная_библиотека) and путь.is_file())

    def запись(сам, событие, путь):
        исходник=сам.контур._код[путь]
        сам.контур.журнал.append({'событие':событие,**{к:исходник[к] for к in ('путь','физический_путь','коммит','blob','режим','sha256')}})

    def compile(сам, source, filename, mode, *позиционные_аргументы, **именованные_аргументы):
        filename=os.fsdecode(filename)
        if filename in сам.контур._код:
            исходник=сам.контур._код[filename]['байты']
            требовать(isinstance(source,(str,bytes,bytearray)), 'неизвестная форма проектного кода')
            данные=source.encode('utf-8') if isinstance(source,str) else bytes(source)
            требовать(данные==исходник and mode=='exec', 'код не соответствует принятым байтам K')
            код=сам.исходная_компиляция(исходник,filename,mode,*позиционные_аргументы,**именованные_аргументы)
            требовать(isinstance(код,types.CodeType), 'нужен исполняемый code object')
            сам._коды[id(код)]=(код,filename)
            сам.запись('compile',filename)
            return код
        кадр=sys._getframe(1)
        требовать(сам.стандартный(кадр.f_code.co_filename) and
                  (сам.стандартный(filename) or filename in ('<string>','<unknown>')),
                  'динамический проектный код не объявлен')
        код=сам.исходная_компиляция(source,filename,mode,*позиционные_аргументы,**именованные_аргументы)
        if isinstance(код,types.CodeType): сам._коды[id(код)]=(код,None)
        return код

    def get_code(сам, путь):
        сам.контур.сверить()
        return сам.compile(сам.контур._код[путь]['байты'],путь,'exec',dont_inherit=True)

    def создать_спецификацию(сам, name, location=None, *, loader=None, submodule_search_locations=None):
        путь=os.fsdecode(location) if location is not None else ''
        if сам.стандартный(путь):
            требовать(loader is None and submodule_search_locations is None, 'чужой loader или поиск для stdlib запрещён')
            return сам.исходная_спецификация(name,location,loader=loader,submodule_search_locations=submodule_search_locations)
        требовать(сам.псевдонимы.get(name)==путь and loader is None, 'необъявленный alias, путь или loader')
        return сам.исходная_спецификация(name,путь,loader=Загрузчик(сам,путь),submodule_search_locations=submodule_search_locations)

    def find_spec(сам, fullname, path=None, target=None):
        if fullname in сам.псевдонимы:
            return сам.создать_спецификацию(fullname,сам.псевдонимы[fullname])
        корневое_имя=fullname.split('.')[0]
        требовать(корневое_имя in sys.stdlib_module_names, 'import отсутствует в конечном реестре K')
        найденная_спецификация=importlib.machinery.PathFinder.find_spec(fullname,path)
        if найденная_спецификация is not None:
            требовать(найденная_спецификация.origin in ('built-in','frozen') or
                      (isinstance(найденная_спецификация.origin,str) and сам.стандартный(найденная_спецификация.origin)), 'неизвестный импорт стандартной библиотеки')
        return None

    def аудит(сам, событие, аргументы):
        if событие=='exec':
            код=аргументы[0]; запись=сам._коды.get(id(код))
            if запись is not None and запись[0] is код:
                if запись[1] is not None:
                    сам.контур.сверить(); сам.запись('exec',запись[1])
                return
            кадр=sys._getframe(1)
            while кадр and кадр.f_code.co_filename==__file__: кадр=кадр.f_back
            требовать(сам.стандартный(код.co_filename) and кадр is not None and
                      сам.стандартный(кадр.f_code.co_filename), 'exec непривязанного code object запрещён')
        elif событие=='compile':
            компилируемые_байты,имя_файла=аргументы
            if имя_файла in сам.контур._код:
                требовать(компилируемые_байты==сам.контур._код[имя_файла]['байты'], 'подменены компилируемые байты K')
            else:
                # Служебные динамические определения stdlib имеют отдельную доверенную роль.
                кадр=sys._getframe(1)
                while кадр and кадр.f_code.co_filename==__file__: кадр=кадр.f_back
                требовать(кадр is not None and сам.стандартный(кадр.f_code.co_filename) and
                          (сам.стандартный(имя_файла) or имя_файла in ('<string>','<unknown>')),
                          'неизвестная проектная компиляция')
