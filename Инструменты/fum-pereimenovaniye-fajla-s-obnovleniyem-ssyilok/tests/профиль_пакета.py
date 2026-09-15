"""Сравнить планирование83 файлов на открытой фикстуре; пути среды не публикуются."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import time
from test_пакет import загрузить
from test_pereimenovatj_fajl_s_obnovleniyem_ssyilok import RepositoryFixture


def выполнить():
    параметры = argparse.ArgumentParser(description=__doc__)
    параметры.add_argument('--выход', type=Path, required=True)
    args = параметры.parse_args()
    модуль = загрузить()
    репо = RepositoryFixture()
    try:
        пары = []
        for i in range(83):
            данные = bytes([i]) * 64
            a, b = f'src/{i}.bin', f'out/{i}.bin'
            репо.write(a, данные)
            пары.append({'исходник': a, 'назначение': b, 'sha256': hashlib.sha256(данные).hexdigest()})
        for i in range(8):
            репо.write(f'links-{i}.md', '\n'.join(f'[файл](src/{j}.bin)' for j in range(83))+'\n')
        репо.commit()
        (репо.root/'out').mkdir()
        вход = {'схема':'fum.пакет-переноса.1', 'HEAD':репо.git('rev-parse','HEAD').stdout.strip(), 'перемещения':пары}
        начало = time.perf_counter_ns()
        for item in пары:
            a,b=модуль.validate_paths(репо.root.resolve(),item['исходник'],item['назначение'])
            модуль.build_plan(репо.root.resolve(),a,b)
        одиночный=time.perf_counter_ns()-начало
        начало=time.perf_counter_ns()
        план=модуль.план_пакета(репо.root.resolve(),вход)
        пакетный=time.perf_counter_ns()-начало
        описание=модуль.описание_пакета(план)
        начало=time.perf_counter_ns()
        модуль.применить_пакет(план,описание['sha256'])
        применение=time.perf_counter_ns()-начало
        if any((репо.root/item['исходник']).exists() or hashlib.sha256((репо.root/item['назначение']).read_bytes()).hexdigest()!=item['sha256'] for item in пары):
            raise RuntimeError('результат переноса не совпал с исходниками')
        args.выход.write_text(json.dumps({'схема':'fum.профиль-пакетного-переноса.1','файлы':83,'markdown':8,
            'ссылки':664,'одиночные_планы_нс':одиночный,'пакетный_план_нс':пакетный,'применение_нс':применение,
            'граница':'Одна последовательная пара на открытой временной фикстуре; подготовка исключена; кэш ОС не очищается; повторные защитные чтения включены; не статистическая оценка.',
            'исходник_sha256':hashlib.sha256(Path(модуль.__file__).read_bytes()).hexdigest()},ensure_ascii=False,indent=2)+'\n')
    finally:
        репо.close()

if __name__=='__main__':выполнить()
