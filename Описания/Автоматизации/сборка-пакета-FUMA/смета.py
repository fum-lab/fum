"""Расчёт без подстановки нулей вместо неизвестных исходных данных."""

import math


def число(значение):
    if isinstance(значение, bool) or not isinstance(значение, (int, float)):
        raise ValueError("Ожидается число")
    if not math.isfinite(значение) or значение < 0:
        raise ValueError("Ожидается конечное неотрицательное число")
    return значение


def сумма_закупки(позиции):
    итог = 0
    неизвестно = False
    for позиция in позиции:
        количество = число(позиция["количество"])
        if количество == 0:
            continue
        цена = позиция["цена"]
        if цена is None:
            неизвестно = True
        else:
            итог += количество * число(цена)
    return None if неизвестно else итог


def рубли(сумма, курс):
    if сумма is None or курс is None:
        return None
    курс = число(курс)
    if курс == 0:
        raise ValueError("Валютный курс должен быть положительным")
    return число(сумма) * курс


def аннуитет(сумма, годовой_процент, месяцев):
    if not isinstance(месяцев, int) or isinstance(месяцев, bool) or месяцев <= 0:
        raise ValueError("Срок должен быть положительным целым числом месяцев")
    if сумма is None:
        return None
    сумма = число(сумма)
    if сумма == 0:
        return 0
    if годовой_процент is None:
        return None
    ставка = число(годовой_процент) / 1200
    return сумма / месяцев if ставка == 0 else сумма * ставка / (1 - (1 + ставка) ** -месяцев)
