"""Диагностические метки не входят в проверяемые байты."""
from contextlib import contextmanager
from time import perf_counter_ns


class Профиль:
    def __init__(self):
        self.записи = []
        self.глубина = 0

    @contextmanager
    def стадия(self, имя):
        начало = perf_counter_ns()
        глубина = self.глубина
        self.глубина += 1
        исход = 'ошибка'
        try:
            yield
            исход = 'успех'
        finally:
            self.глубина -= 1
            self.записи.append({'стадия': имя, 'глубина': глубина, 'длительность_наносекунды': perf_counter_ns() - начало, 'исход': исход})
