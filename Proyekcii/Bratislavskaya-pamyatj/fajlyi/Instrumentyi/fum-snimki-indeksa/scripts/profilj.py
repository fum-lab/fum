"""Диагностические метки не входят в проверяемые байты."""
from contextlib import contextmanager
from time import perf_counter_ns


class Профиль:
    def __init__(сам):
        сам.записи = []
        сам.глубина = 0

    @contextmanager
    def стадия(сам, имя):
        начало = perf_counter_ns()
        глубина = сам.глубина
        сам.глубина += 1
        исход = 'ошибка'
        try:
            yield
            исход = 'успех'
        finally:
            сам.глубина -= 1
            сам.записи.append({'стадия': имя, 'глубина': глубина, 'длительность_наносекунды': perf_counter_ns() - начало, 'исход': исход})
