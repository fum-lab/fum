"""Воспроизводимый профиль полного сохранения Markdown внутри исходной команды."""
import argparse
import hashlib
import json
import statistics
import time
from pathlib import Path

from test_check_session_coherence import check_session_coherence as проверка


def выполнить():
    parser = argparse.ArgumentParser()
    parser.add_argument('--выход', type=Path, required=True)
    args = parser.parse_args()
    тело = '\n\n````text\n' + '## Исходное сообщение: ё🙂\n' * 2000 + '````\n\n'
    вход = '## Текст запроса' + тело + '## Проверки\nконец\n'
    времена = []
    for _ in range(30):
        начало = time.perf_counter_ns()
        выход = проверка.section_body(вход, 'Текст запроса')
        времена.append(time.perf_counter_ns() - начало)
        assert выход == тело
    результат = {'схема': 'fum.профиль-разделов.1', 'вход_sha256': hashlib.sha256(вход.encode()).hexdigest(),
                 'выход_sha256': hashlib.sha256(тело.encode()).hexdigest(), 'байтов': len(вход.encode()),
                 'повторов': len(времена), 'длительности_наносекунды': времена,
                 'медиана_наносекунды': statistics.median(времена),
                 'исходник_sha256': hashlib.sha256(Path(проверка.__file__).read_bytes()).hexdigest()}
    with args.выход.open('x') as файл:
        json.dump(результат, файл, ensure_ascii=False, indent=2)
        файл.write('\n')
    print(json.dumps(результат, ensure_ascii=False))


if __name__ == '__main__':
    выполнить()
