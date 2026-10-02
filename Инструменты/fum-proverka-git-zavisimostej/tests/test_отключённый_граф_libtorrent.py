"""Точный отключённый граф и активная try_signal в автономных Git-фикстурах."""
import copy
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from test_proveritj_git_zavisimostj import GitDependencyFixture, run_git
from test_подготовка_зависимостей import загрузить_подготовку

ГРАФ = {
    'deps/asio-gnutls': 'a57d4d36923c5fafa9698e14be16b8bc2913700a',
    'deps/libdatachannel': 'a02b751917ac8afc8c58dc6f4461d25ff9465d48',
    'deps/try_signal': '105cce59972f925a33aa6b1c3109e4cd3caf583d',
    'simulation/libsimulator': 'dcb401642be66e36dd08283d852053c7381da585',
}
ОПИСАНИЕ = '''[submodule "simulation/libsimulator"]
\tpath = simulation/libsimulator
\turl = https://github.com/arvidn/libsimulator.git
[submodule "deps/try_signal"]
\tpath = deps/try_signal
\turl = https://github.com/arvidn/try_signal.git
[submodule "deps/asio-gnutls"]
\tpath = deps/asio-gnutls
\turl = https://github.com/paullouisageneau/boost-asio-gnutls.git
[submodule "deps/libdatachannel"]
\tpath = deps/libdatachannel
\turl = https://github.com/paullouisageneau/libdatachannel.git
'''
ФЛАГИ = {'CMAKE_BUILD_TYPE': 'Release', 'BUILD_SHARED_LIBS': True,
    'webtorrent': False, 'gnutls': False, 'dht': False, 'i2p': False,
    'encryption': False, 'exceptions': True, 'build_tests': False,
    'build_examples': False, 'build_tools': False, 'python-bindings': False}


class ФикстураГрафа:
    def __init__(сам, корень):
        сам.база = GitDependencyFixture(корень)
        сам.база.path = 'Зависимости/libtorrent'
        сам.корень = сам.база.superproject
        сам.модуль = загрузить_подготовку()
        сам.путь_сигнала = 'Зависимости/try_signal'
        сам.оригинал_сигнала = сам.база.upstream_namespace / 'try_signal.git'
        сам.форк_сигнала = сам.база.namespace / 'try_signal.git'
        run_git('clone', '--bare', str(сам.база.upstream), str(сам.оригинал_сигнала))
        run_git('clone', '--bare', str(сам.база.upstream), str(сам.форк_сигнала))
        сам.граф = {**ГРАФ, 'deps/try_signal': сам.база.first_revision}
        (сам.база.seed / '.gitmodules').write_text(ОПИСАНИЕ, encoding='utf-8')
        (сам.база.seed / 'CMakeLists.txt').write_text('# Открытая синтетическая фикстура\n', encoding='utf-8')
        run_git('add', '.gitmodules', 'CMakeLists.txt', cwd=сам.база.seed)
        for путь, ревизия in сам.граф.items():
            run_git('update-index', '--add', '--cacheinfo', f'160000,{ревизия},{путь}', cwd=сам.база.seed)
        run_git('commit', '-m', 'Закрепить открытый граф', cwd=сам.база.seed)
        сам.ревизия = run_git('rev-parse', 'HEAD', cwd=сам.база.seed)
        run_git('push', 'origin', 'HEAD:master', cwd=сам.база.seed)
        run_git('push', str(сам.база.fork), 'HEAD:master', cwd=сам.база.seed)
        assert сам.база.add_dependency(revision=сам.ревизия) == []
        сам.зависимость = сам.корень / сам.база.path
        сам.политика = {'ревизия': сам.ревизия, 'форк': str(сам.база.fork),
            'оригинал': str(сам.база.upstream), 'граф': сам.граф,
            'описание': run_git('rev-parse', 'HEAD:.gitmodules', cwd=сам.зависимость),
            'сборка': run_git('rev-parse', 'HEAD:CMakeLists.txt', cwd=сам.зависимость),
            'форк_сигнала': str(сам.форк_сигнала), 'оригинал_сигнала': str(сам.оригинал_сигнала)}
        сам.подмена = mock.patch.object(сам.модуль, 'ПОЛИТИКА_ТОРРЕНТА', сам.политика, create=True)
        сам.подмена.start()
        сам.профиль = сам.корень / 'Зависимости/профиль-libtorrent.json'
        сам.данные = {'схема': 'fum.профиль-вложенного-libtorrent.1',
            'путь_торрента': сам.база.path, 'путь_сигнала': сам.путь_сигнала,
            'параметры_сборки': copy.deepcopy(ФЛАГИ), 'обязательные_цели': ['OpenSSL::SSL', 'OpenSSL::Crypto']}
        сам.сохранить_профиль()
        сам.материализовать_сигнал()

    def закрыть(сам):
        сам.подмена.stop()

    def сохранить_профиль(сам):
        сам.профиль.write_text(json.dumps(сам.данные, ensure_ascii=False), encoding='utf-8')
        run_git('add', 'Зависимости/профиль-libtorrent.json', cwd=сам.корень)

    def материализовать_сигнал(сам):
        run_git('-c', 'protocol.file.allow=always', 'submodule', 'add', '--',
                str(сам.форк_сигнала), сам.путь_сигнала, cwd=сам.корень)
        run_git('remote', 'add', 'upstream', str(сам.оригинал_сигнала), cwd=сам.корень/сам.путь_сигнала)
        run_git('fetch', 'upstream', cwd=сам.корень/сам.путь_сигнала)
        run_git('checkout', '--detach', сам.база.first_revision, cwd=сам.корень/сам.путь_сигнала)
        run_git('config', '-f', '.gitmodules', f'submodule.{сам.путь_сигнала}.fumUpstream',
                str(сам.оригинал_сигнала), cwd=сам.корень)
        run_git('add', '.gitmodules', сам.путь_сигнала, cwd=сам.корень)

    def готовность(сам):
        return сам.модуль.проверить_готовность_зависимости(сам.корень, сам.база.path)


class ПроверкиОтключённогоГрафа(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.фикстура = ФикстураГрафа(Path(сам.временный.name).resolve())
        сам.addCleanup(сам.фикстура.закрыть)

    def отказ(сам):
        итог = сам.фикстура.готовность()
        сам.assertFalse(итог['готова'], итог)
        сам.assertEqual('вложенные_зависимости', итог['состояние'], итог)

    def test_точный_профиль_с_готовым_сигналом_проходит_без_эффектов(сам):
        до = сам.фикстура.модуль.снять_снимок(сам.фикстура.корень)
        сигнал = сам.фикстура.модуль.проверить_готовность_зависимости(
            сам.фикстура.корень, сам.фикстура.путь_сигнала)
        сам.assertTrue(сигнал['готова'], сигнал)
        with mock.patch.object(сам.фикстура.модуль.исходный, 'initialize_registered_dependency',
                               side_effect=AssertionError('init запрещён')):
            итог = сам.фикстура.готовность()
        сам.assertTrue(итог['готова'], итог)
        сам.assertEqual(до, сам.фикстура.модуль.снять_снимок(сам.фикстура.корень))

    def test_неизвестный_или_изменённый_гитлинк_отклоняется(сам):
        for путь in ('deps/лишняя', 'deps/asio-gnutls'):
            with сам.subTest(путь=путь):
                run_git('update-index', '--add', '--cacheinfo', '160000,'+'f'*40+','+путь,
                        cwd=сам.фикстура.зависимость)
                сам.отказ()
                run_git('reset', '--', путь, cwd=сам.фикстура.зависимость)

    def test_удалённый_гитлинк_не_обходит_допуск(сам):
        for путь in ГРАФ:
            run_git('update-index', '--force-remove', путь, cwd=сам.фикстура.зависимость)
        сам.отказ()

    def test_профиль_не_подменяет_источник_или_ревизию(сам):
        for поле in ('форк', 'оригинал', 'ревизия'):
            with сам.subTest(поле=поле), mock.patch.dict(сам.фикстура.политика, {поле: 'иная'}):
                сам.отказ()

    def test_профиль_требует_все_отключения_и_криптобиблиотеку(сам):
        эталон = copy.deepcopy(сам.фикстура.данные)
        for флаг in ФЛАГИ:
            with сам.subTest(флаг=флаг):
                сам.фикстура.данные = copy.deepcopy(эталон)
                сам.фикстура.данные['параметры_сборки'][флаг] = 'иное'
                сам.фикстура.сохранить_профиль(); сам.отказ()
        сам.фикстура.данные = copy.deepcopy(эталон)
        сам.фикстура.данные['обязательные_цели'] = ['OpenSSL::Crypto']
        сам.фикстура.сохранить_профиль(); сам.отказ()

    def test_профиль_обычный_индексированный_точный_документ(сам):
        сам.фикстура.профиль.write_text('{}', encoding='utf-8'); сам.отказ()
        сам.фикстура.сохранить_профиль()
        текст = сам.фикстура.профиль.read_text(encoding='utf-8')
        сам.фикстура.профиль.write_text(текст[:-1]+',"путь_торрента":"повтор"}', encoding='utf-8')
        run_git('add', 'Зависимости/профиль-libtorrent.json', cwd=сам.фикстура.корень); сам.отказ()
        сам.фикстура.профиль.unlink()
        сам.фикстура.профиль.symlink_to(сам.фикстура.зависимость/'.gitmodules'); сам.отказ()

    def test_материализованный_вложенный_путь_запрещён_даже_игнорируемый(сам):
        for путь in ГРАФ:
            with сам.subTest(путь=путь):
                каталог = сам.фикстура.зависимость/путь
                каталог.mkdir(parents=True, exist_ok=True)
                (каталог/'содержимое').write_text('активная копия', encoding='utf-8')
                сам.отказ()
                (каталог/'содержимое').unlink()
        сам.assertTrue(сам.фикстура.готовность()['готова'])

    def test_активная_локальная_настройка_запрещена(сам):
        run_git('config', 'submodule.deps/libdatachannel.active', 'true', cwd=сам.фикстура.зависимость)
        сам.отказ()

    def test_сигнал_обязателен_и_проходит_прежний_строгий_валидатор(сам):
        run_git('checkout', '--detach', сам.фикстура.база.second_revision,
                cwd=сам.фикстура.корень/сам.фикстура.путь_сигнала)
        сам.отказ()
        run_git('checkout', '--detach', сам.фикстура.база.first_revision,
                cwd=сам.фикстура.корень/сам.фикстура.путь_сигнала)
        (сам.фикстура.корень/сам.фикстура.путь_сигнала/'README.md').write_text('грязная копия',encoding='utf-8')
        сам.отказ()

    def test_неизвестный_граф_сохраняет_прежний_отказ(сам):
        with mock.patch.dict(сам.фикстура.политика, {'ревизия': 'f'*40}):
            сам.отказ()

    def test_включённая_конфигурация_не_скрывает_активацию(сам):
        файл = сам.фикстура.база.root/'включённая-настройка'
        файл.write_text('[submodule]\n\tactive = .\n', encoding='utf-8')
        run_git('config', 'include.path', str(файл), cwd=сам.фикстура.зависимость)
        сам.отказ()

    def test_вложенные_ссылки_и_административные_остатки_запрещены(сам):
        путь = сам.фикстура.зависимость/'simulation/libsimulator'
        путь.rmdir(); путь.symlink_to(сам.фикстура.база.root, target_is_directory=True)
        сам.отказ(); путь.unlink(); путь.mkdir()
        каталог = Path(run_git('rev-parse', '--absolute-git-dir', cwd=сам.фикстура.зависимость))/'modules'
        каталог.mkdir(); сам.отказ()

    def test_грязный_исходный_контракт_не_скрывается_настройкой_игнорирования(сам):
        файл = сам.фикстура.зависимость/'.gitmodules'
        файл.write_text(файл.read_text(encoding='utf-8')+'\n# Подмена\n', encoding='utf-8')
        run_git('config', 'diff.ignoreSubmodules', 'all', cwd=сам.фикстура.зависимость)
        сам.отказ()

    def test_числа_не_подменяют_булевы_флаги(сам):
        сам.фикстура.данные['параметры_сборки']['webtorrent'] = 0
        сам.фикстура.сохранить_профиль(); сам.отказ()

    def test_пустые_копии_требуют_готового_сигнала_до_первого_эффекта(сам):
        сам.фикстура.база.publish_dependency_registration()
        клон = сам.фикстура.база.fresh_clone(recurse_submodules=False)
        run_git('checkout', '-b', 'codex/пустой-граф', cwd=клон)
        инвентарь = сам.фикстура.модуль.прочитать_инвентарь(клон)
        запись = next(з for з in инвентарь if з['путь'] == сам.фикстура.база.path)
        снимок = сам.фикстура.модуль.снять_снимок(клон)
        каталог = Path(run_git('rev-parse', '--absolute-git-dir', cwd=клон))
        до = set(каталог.iterdir())
        исполнитель = '00000000-0000-0000-0000-000000000001'
        with mock.patch.object(сам.фикстура.модуль.исходный, 'initialize_registered_dependency',
                               side_effect=AssertionError('init до готового сигнала')), \
                mock.patch.dict(os.environ, {'CODEX_THREAD_ID': исполнитель}):
            итог = сам.фикстура.модуль.проверить_запись(клон, запись)
            with сам.assertRaisesRegex(RuntimeError, 'неподготовимое состояние'):
                сам.фикстура.модуль.подготовить_зависимости(клон, снимок, исполнитель,
                    '00000000-0000-0000-0000-000000000002')
        сам.assertEqual('вложенные_зависимости', итог['состояние'], итог)
        сам.assertEqual(снимок, сам.фикстура.модуль.снять_снимок(клон))
        сам.assertEqual(до, set(каталог.iterdir()))

    def test_производственная_политика_закрепляет_первичные_объекты(сам):
        модуль = загрузить_подготовку()
        сам.assertEqual('56ae8caba38bf154ffc210403cb23f91d0ecaa49', модуль.ПОЛИТИКА_ТОРРЕНТА['ревизия'])
        сам.assertEqual(ГРАФ, модуль.ПОЛИТИКА_ТОРРЕНТА['граф'])
        сам.assertEqual('8fba94d3e699d689394cc42b8d057b14de8f7950', модуль.ПОЛИТИКА_ТОРРЕНТА['описание'])


if __name__ == '__main__':
    unittest.main()
