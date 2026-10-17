#!/usr/bin/env python3
"""Проверяет паспорт владения производными ветками FUM.

Паспорт описывает слой, который пишет в конкретную директорию, его Git ref,
рабочее дерево и зависимости. Проверка намеренно не создаёт ветки, worktree,
коммиты или доставки: это закрытая структурная граница перед такой операцией.
"""

from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from time import monotonic_ns
from typing import Any, Callable, Iterable, Mapping


СХЕМА = "fum.конвейер-производных-веток.v1"
СХЕМА_ИМЕНИ_ВЕТКИ = "bratislavskaya-path-slug.v2"
ПРЕФИКС_ВЕТОКИ = "refs/heads/"
ОИД = re.compile(r"^[0-9a-f]{40}$")
REF_СЕГМЕНТ = re.compile(r"^[A-Za-z0-9._-]+$")
НЕПУСТАЯ_СТРОКА = re.compile(r"^\S(?:.*\S)?$")


class ОшибкаПаспорта(ValueError):
    """Означает отказ до создания или передачи производной ветки."""


def _ошибка(сообщение: str) -> None:
    raise ОшибкаПаспорта(сообщение)


def _требовать_словарь(значение: Any, путь: str) -> dict[str, Any]:
    if not isinstance(значение, dict):
        _ошибка(f"{путь}: ожидался JSON-объект")
    return значение


def _требовать_список(значение: Any, путь: str) -> list[Any]:
    if not isinstance(значение, list):
        _ошибка(f"{путь}: ожидался JSON-массив")
    return значение


def _строка(значение: Any, путь: str) -> str:
    if not isinstance(значение, str) or not НЕПУСТАЯ_СТРОКА.fullmatch(значение):
        _ошибка(f"{путь}: требуется непустая строка")
    return значение


def _точные_ключи(объект: Mapping[str, Any], ожидаемые: set[str], путь: str) -> None:
    неизвестные = set(объект) - ожидаемые
    отсутствующие = ожидаемые - set(объект)
    if неизвестные:
        _ошибка(f"{путь}: неизвестные поля: {', '.join(sorted(неизвестные))}")
    if отсутствующие:
        _ошибка(f"{путь}: отсутствуют поля: {', '.join(sorted(отсутствующие))}")


def _безопасный_относительный_путь(
    значение: Any, путь: str, *, каталог: bool = False
) -> str:
    исходный = _строка(значение, путь)
    if "\\" in исходный or исходный.startswith("/") or "//" in исходный:
        _ошибка(f"{путь}: небезопасный путь")
    части = исходный.split("/")
    if каталог:
        if not исходный.endswith("/"):
            _ошибка(f"{путь}: путь каталога должен оканчиваться /")
        части = части[:-1]
    elif исходный.endswith("/"):
        _ошибка(f"{путь}: путь файла не должен оканчиваться /")
    if not части or any(часть in {"", ".", ".."} for часть in части):
        _ошибка(f"{путь}: небезопасный путь")
    return исходный


def _безопасный_рабочий_путь(значение: Any, путь: str) -> str:
    исходный = _строка(значение, путь)
    if "\\" in исходный or исходный.startswith("/"):
        _ошибка(f"{путь}: рабочее дерево должно быть относительным")
    части = исходный.split("/")
    if any(часть in {"", ".", ".."} for часть in части):
        _ошибка(f"{путь}: небезопасный путь рабочего дерева")
    return исходный


def _компоненты_пути(путь: str) -> list[str]:
    return путь.rstrip("/").split("/") if путь else []


_БРАТИСЛАВСКИЕ_ЗАМЕНЫ = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e",
    "ё": "yo", "ж": "zh", "з": "z", "и": "i", "й": "j", "к": "k",
    "л": "l", "м": "m", "н": "n", "о": "o", "п": "p", "р": "r",
    "с": "s", "т": "t", "у": "u", "ф": "f", "х": "kh", "ц": "c",
    "ч": "ch", "ш": "sh", "щ": "sjh", "ъ": "y", "ы": "yi", "ь": "j",
    "э": "e", "ю": "yu", "я": "ya",
}
_СОГЛАСНЫЕ = set("бвгджзклмнпрстфхцчшщ")
_ГЛАСНЫЕ = set("аеёиоуыэюя")


def _братиславский_компонент(компонент: str) -> str:
    """Делает автономную воспроизводимую Cyrl to Latn основу для имени ref.

    В рабочем контуре результат должен быть сверён с закреплённым
    LinguisticKit. Здесь повторяется используемая FUM схема только для
    структурной проверки; сеть и Swift-процесс не нужны.
    """
    результат: list[str] = []
    символы = list(компонент)
    for номер, символ in enumerate(символы):
        нижний = символ.lower()
        предыдущий = символы[номер - 1].lower() if номер else ""
        следующий = символы[номер + 1].lower() if номер + 1 < len(символы) else ""
        предыдущий_согласный = предыдущий in _СОГЛАСНЫЕ
        следующий_гласный = следующий in _ГЛАСНЫЕ
        if нижний == "е":
            замена = "e" if предыдущий_согласный else "ye"
        elif нижний == "э":
            замена = "ye" if предыдущий_согласный else "e"
        elif нижний == "й":
            замена = "yj" if предыдущий_согласный else "j"
        elif нижний == "ь":
            замена = "j" if предыдущий_согласный else "hj"
        elif нижний == "ъ":
            if предыдущий_согласный and следующий_гласный:
                замена = "yh"
            elif предыдущий_согласный:
                замена = "y"
            elif следующий_гласный:
                замена = "hyh"
            else:
                замена = "hy"
        elif нижний in _БРАТИСЛАВСКИЕ_ЗАМЕНЫ:
            замена = _БРАТИСЛАВСКИЕ_ЗАМЕНЫ[нижний]
        else:
            замена = None
        if замена is not None:
            результат.append(
                замена.upper() if символ.isupper() and len(замена) == 1 else замена
            )
        elif символ.isascii() and (символ.isalnum() or символ in ".-_ "):
            результат.append(символ)
        else:
            _ошибка(f"каталог {компонент!r}: символ не поддержан братиславским именем")
    return "".join(результат).replace("ie", "iye")


def _slug(компонент: str) -> str:
    преобразованный = _братиславский_компонент(компонент).lower()
    преобразованный = re.sub(r"[ _]+", "-", преобразованный)
    преобразованный = re.sub(r"-+", "-", преобразованный).strip("-")
    if not преобразованный or преобразованный in {".", ".."}:
        _ошибка(f"каталог {компонент!r}: пустое имя ветки")
    if not REF_СЕГМЕНТ.fullmatch(преобразованный):
        _ошибка(f"каталог {компонент!r}: небезопасное имя ветки")
    return преобразованный


def сформировать_ref_ветки(путь_каталога: str, namespace: str = "fum") -> str:
    """Возвращает ref из относительного пути каталога.

    Корень получает fum/root. Вложенный путь кодируется одной Git-секцией
    после fum/dir: компоненты остаются в исходном порядке и разделяются --.
    Плоская секция нужна потому, что Git не допускает одновременно ref
    fum/a и fum/a/b; имя всё равно полностью выводится из пути.
    """
    if not isinstance(namespace, str) or not REF_СЕГМЕНТ.fullmatch(namespace):
        _ошибка("namespace имени ветки должен быть безопасным компонентом")
    if путь_каталога == "":
        return f"{ПРЕФИКС_ВЕТОКИ}{namespace}/root"
    нормализованный = _безопасный_относительный_путь(
        путь_каталога, "directory_path", каталог=True
    )
    компоненты = [_slug(компонент) for компонент in _компоненты_пути(нормализованный)]
    return f"{ПРЕФИКС_ВЕТОКИ}{namespace}/dir/" + "--".join(компоненты)


def _проверить_ref(ref: Any, путь: str) -> str:
    значение = _строка(ref, путь)
    if not значение.startswith(ПРЕФИКС_ВЕТОКИ):
        _ошибка(f"{путь}: ref должен начинаться с refs/heads/")
    части = значение[len(ПРЕФИКС_ВЕТОКИ):].split("/")
    if not части or any(
        not REF_СЕГМЕНТ.fullmatch(часть) or часть in {".", ".."}
        for часть in части
    ) or "//" in значение or "@{" in значение:
        _ошибка(f"{путь}: небезопасный Git ref")
    return значение


def _проверить_префиксные_ref(refs: Iterable[str]) -> None:
    упорядоченные = sorted(refs)
    for левый, правый in zip(упорядоченные, упорядоченные[1:]):
        if правый.startswith(левый + "/"):
            _ошибка(f"конфликт ref: {левый} и {правый}")


def _проверить_граф(слои: Mapping[str, Mapping[str, Any]]) -> None:
    состояние: dict[str, int] = {}

    def посетить(идентификатор: str) -> None:
        цвет = состояние.get(идентификатор, 0)
        if цвет == 1:
            _ошибка(f"цикл зависимостей через слой {идентификатор}")
        if цвет == 2:
            return
        состояние[идентификатор] = 1
        for родитель in слои[идентификатор]["depends_on"]:
            посетить(родитель)
        состояние[идентификатор] = 2

    for идентификатор in слои:
        посетить(идентификатор)


def _проверить_слои(
    паспорт: Mapping[str, Any], слои_списком: list[Any]
) -> dict[str, dict[str, Any]]:
    слои: dict[str, dict[str, Any]] = {}
    refs: list[str] = []
    рабочие_деревья: set[str] = set()
    писатели: set[str] = set()
    for номер, сырое in enumerate(слои_списком):
        слой = _требовать_словарь(сырое, f"layers[{номер}]")
        _точные_ключи(
            слой,
            {
                "layer_id", "branch_ref", "directory_path", "parent_layer_id",
                "worktree", "writer", "lifecycle", "status", "depends_on",
            },
            f"layers[{номер}]",
        )
        идентификатор = _строка(слой["layer_id"], f"layers[{номер}].layer_id")
        if идентификатор in слои:
            _ошибка(f"повторный layer_id: {идентификатор}")
        ref = _проверить_ref(слой["branch_ref"], f"layers[{номер}].branch_ref")
        путь = слой["directory_path"]
        if путь != "":
            путь = _безопасный_относительный_путь(
                путь, f"layers[{номер}].directory_path", каталог=True
            )
        elif идентификатор != паспорт["root_layer_id"]:
            _ошибка(
                f"layers[{номер}].directory_path: пустой путь разрешён только корню"
            )
        родитель = слой["parent_layer_id"]
        if родитель is not None and not isinstance(родитель, str):
            _ошибка(f"layers[{номер}].parent_layer_id: требуется строка или null")
        рабочее_дерево = _безопасный_рабочий_путь(
            слой["worktree"], f"layers[{номер}].worktree"
        )
        писатель = _строка(слой["writer"], f"layers[{номер}].writer")
        if рабочее_дерево in рабочие_деревья:
            _ошибка(f"повторное worktree: {рабочее_дерево}")
        if писатель in писатели:
            _ошибка(f"повторный писатель: {писатель}")
        рабочие_деревья.add(рабочее_дерево)
        писатели.add(писатель)
        if слой["lifecycle"] not in {"permanent", "temporary"}:
            _ошибка(f"layers[{номер}].lifecycle: неизвестный жизненный цикл")
        if слой["status"] not in {"active", "paused"}:
            _ошибка(f"layers[{номер}].status: неизвестный статус")
        зависимости = _требовать_список(
            слой["depends_on"], f"layers[{номер}].depends_on"
        )
        if len(зависимости) != len(set(зависимости)):
            _ошибка(f"layers[{номер}].depends_on: повторная зависимость")
        if any(not isinstance(зависимость, str) for зависимость in зависимости):
            _ошибка(f"layers[{номер}].depends_on: идентификатор должен быть строкой")
        refs.append(ref)
        слои[идентификатор] = {
            **слой,
            "layer_id": идентификатор,
            "branch_ref": ref,
            "directory_path": путь,
            "parent_layer_id": родитель,
            "worktree": рабочее_дерево,
            "writer": писатель,
            "depends_on": list(зависимости),
        }
    _проверить_префиксные_ref(refs)
    корень = паспорт["root_layer_id"]
    if корень not in слои:
        _ошибка("root_layer_id не найден среди layers")
    if (
        слои[корень]["parent_layer_id"] is not None
        or слои[корень]["directory_path"] != ""
    ):
        _ошибка("корневой слой должен иметь пустой directory_path и parent_layer_id=null")
    for идентификатор, слой in слои.items():
        if идентификатор != корень:
            родитель = слой["parent_layer_id"]
            if родитель not in слои or родитель == идентификатор:
                _ошибка(f"слой {идентификатор}: неизвестный parent_layer_id")
            путь_родителя = слои[родитель]["directory_path"]
            if путь_родителя and not слой["directory_path"].startswith(путь_родителя):
                _ошибка(f"слой {идентификатор}: путь не вложен в каталог родителя")
        for зависимость in слой["depends_on"]:
            if зависимость not in слои:
                _ошибка(f"слой {идентификатор}: неизвестная зависимость {зависимость}")
        ожидаемый = сформировать_ref_ветки(
            слой["directory_path"], паспорт["branch_naming"]["namespace"]
        )
        if слой["branch_ref"] != ожидаемый:
            _ошибка(
                f"слой {идентификатор}: ветка не выведена из братиславского пути "
                f"({слой['branch_ref']} != {ожидаемый})"
            )
    _проверить_граф(слои)
    return слои


def _проверить_владельцев(
    записи: list[Any], слои: Mapping[str, Mapping[str, Any]]
) -> dict[str, str]:
    владельцы: dict[str, str] = {}
    каталоги: list[tuple[str, str]] = []
    # Сначала регистрируем каталоги и файлы: README может идти в JSON раньше
    # каталога, владельца которого он наследует.
    порядок = [
        *[запись for запись in записи if not isinstance(запись, dict) or запись.get("kind") != "readme"],
        *[запись for запись in записи if isinstance(запись, dict) and запись.get("kind") == "readme"],
    ]
    for номер, сырое in enumerate(порядок):
        запись = _требовать_словарь(сырое, f"path_owners[{номер}]")
        вид = запись.get("kind")
        путь = запись.get("path")
        if вид == "directory":
            _точные_ключи(
                запись, {"path", "kind", "layer_id"}, f"path_owners[{номер}]"
            )
            нормализованный = _безопасный_относительный_путь(
                путь, f"path_owners[{номер}].path", каталог=True
            )
            слой = _строка(
                запись["layer_id"], f"path_owners[{номер}].layer_id"
            )
            if (
                слой not in слои
                or слои[слой]["directory_path"] != нормализованный
            ):
                _ошибка(f"path_owners[{номер}]: каталог не совпадает со слоем")
            каталоги.append((нормализованный, слой))
            владелец = слой
        elif вид == "readme":
            _точные_ключи(
                запись, {"path", "kind", "inherits"}, f"path_owners[{номер}]"
            )
            нормализованный = _безопасный_относительный_путь(
                путь, f"path_owners[{номер}].path"
            )
            if not нормализованный.endswith("/README.md"):
                _ошибка(f"path_owners[{номер}]: README должен находиться в каталоге")
            наследует = _безопасный_относительный_путь(
                запись["inherits"], f"path_owners[{номер}].inherits", каталог=True
            )
            if нормализованный != наследует + "README.md":
                _ошибка(f"path_owners[{номер}]: README имеет неверный inherits")
            владелец = next(
                (
                    слой
                    for путь_каталога, слой in каталоги
                    if путь_каталога == наследует
                ),
                None,
            )
            if владелец is None:
                _ошибка(f"path_owners[{номер}]: README ссылается на неизвестный каталог")
        elif вид == "file":
            _точные_ключи(
                запись, {"path", "kind", "layer_id"}, f"path_owners[{номер}]"
            )
            нормализованный = _безопасный_относительный_путь(
                путь, f"path_owners[{номер}].path"
            )
            владелец = _строка(
                запись["layer_id"], f"path_owners[{номер}].layer_id"
            )
            if владелец not in слои:
                _ошибка(f"path_owners[{номер}]: неизвестный layer_id")
        else:
            _ошибка(f"path_owners[{номер}]: неизвестный kind")
        if нормализованный in владельцы:
            _ошибка(f"повторный path_owner: {нормализованный}")
        владельцы[нормализованный] = владелец
    каталоги_по_пути = dict(каталоги)
    for путь, слой in каталоги:
        компоненты = путь.rstrip("/").split("/")
        ближайший_родитель: str | None = None
        for конец in range(1, len(компоненты)):
            кандидат = "/".join(компоненты[:конец]) + "/"
            if кандидат in каталоги_по_пути:
                ближайший_родитель = каталоги_по_пути[кандидат]
        if ближайший_родитель is not None:
            if слои[слой]["parent_layer_id"] != ближайший_родитель:
                _ошибка(
                    f"пересечение каталогов {путь} и родителя "
                    f"без parent_layer_id={ближайший_родитель}"
                )
    for идентификатор, слой in слои.items():
        if слой["parent_layer_id"] is None:
            continue
        путь = слой["directory_path"]
        if путь and владельцы.get(путь) != идентификатор:
            _ошибка(f"слой {идентификатор}: отсутствует точный path_owner каталога")
    return владельцы


def _проверить_хранилища(записи: list[Any]) -> None:
    seen: set[str] = set()
    for номер, сырое in enumerate(записи):
        запись = _требовать_словарь(сырое, f"storage_targets[{номер}]")
        _точные_ключи(
            запись,
            {"target_id", "kind", "path", "format", "status"},
            f"storage_targets[{номер}]",
        )
        идентификатор = _строка(
            запись["target_id"], f"storage_targets[{номер}].target_id"
        )
        if идентификатор in seen:
            _ошибка(f"повторный storage target: {идентификатор}")
        seen.add(идентификатор)
        _строка(запись["kind"], f"storage_targets[{номер}].kind")
        значение_пути = запись["path"]
        _безопасный_относительный_путь(
            значение_пути,
            f"storage_targets[{номер}].path",
            каталог=isinstance(значение_пути, str) and значение_пути.endswith("/"),
        )
        _строка(запись["format"], f"storage_targets[{номер}].format")
        if запись["status"] not in {"planned", "active", "paused"}:
            _ошибка(f"storage_targets[{номер}].status: неизвестный статус")


def _проверить_доставки(
    записи: list[Any],
    слои: Mapping[str, Mapping[str, Any]],
    владельцы: Mapping[str, str],
    корень: str,
) -> tuple[int, int]:
    seen: set[str] = set()
    result_oids: set[str] = set()
    обратных = 0
    for номер, сырое in enumerate(записи):
        запись = _требовать_словарь(сырое, f"deliveries[{номер}]")
        известные = {
            "delivery_id", "direction", "from_layer", "to_layer", "base_oid",
            "result_oid", "status", "accepted_paths",
        }
        if set(запись) - известные:
            _ошибка(f"deliveries[{номер}]: неизвестные поля")
        обязательные = известные - {"accepted_paths"}
        if not обязательные <= set(запись):
            _ошибка(f"deliveries[{номер}]: отсутствуют обязательные поля")
        идентификатор = _строка(
            запись["delivery_id"], f"deliveries[{номер}].delivery_id"
        )
        if идентификатор in seen:
            _ошибка(f"повторная delivery_id: {идентификатор}")
        seen.add(идентификатор)
        направление = запись["direction"]
        if направление not in {"forward", "reverse"}:
            _ошибка(f"deliveries[{номер}].direction: неизвестное направление")
        источник = _строка(
            запись["from_layer"], f"deliveries[{номер}].from_layer"
        )
        цель = _строка(запись["to_layer"], f"deliveries[{номер}].to_layer")
        if источник not in слои or цель not in слои or источник == цель:
            _ошибка(
                f"deliveries[{номер}]: неизвестная или одинаковая граница слоёв"
            )
        for поле in ("base_oid", "result_oid"):
            if not isinstance(запись[поле], str) or not ОИД.fullmatch(запись[поле]):
                _ошибка(
                    f"deliveries[{номер}].{поле}: нужен lowercase Git OID"
                )
        if запись["result_oid"] in result_oids:
            _ошибка(f"повторный result_oid: {запись['result_oid']}")
        result_oids.add(запись["result_oid"])
        if запись["status"] not in {"planned", "pending", "accepted", "rejected"}:
            _ошибка(f"deliveries[{номер}].status: неизвестный статус")
        if направление == "forward":
            if источник not in слои[цель]["depends_on"]:
                _ошибка(
                    f"forward-доставка {идентификатор}: "
                    "цель не зависит от источника"
                )
        else:
            обратных += 1
            if цель != корень:
                _ошибка(
                    f"reverse-доставка {идентификатор}: возврат должен идти в корень"
                )
            пути = запись.get("accepted_paths")
            if not isinstance(пути, list) or not пути:
                _ошибка(
                    f"reverse-доставка {идентификатор}: "
                    "отсутствуют accepted_paths"
                )
            for путь in пути:
                if not isinstance(путь, str):
                    _ошибка(
                        f"reverse-доставка {идентификатор}: "
                        "accepted_path должен быть строкой"
                    )
                нормализованный = _безопасный_относительный_путь(
                    путь,
                    f"deliveries[{номер}].accepted_paths",
                    каталог=путь.endswith("/"),
                )
                if владельцы.get(нормализованный) != источник:
                    _ошибка(
                        f"reverse-доставка {идентификатор}: "
                        "путь не принадлежит источнику"
                    )
    return len(записи), обратных


def проверить_паспорт(паспорт: dict) -> dict:
    """Проверяет паспорт без изменения входного объекта и возвращает сводку."""
    начало = monotonic_ns()
    if not isinstance(паспорт, dict):
        _ошибка("паспорт должен быть JSON-объектом")
    исходный_снимок = copy.deepcopy(паспорт)
    _точные_ключи(
        паспорт,
        {
            "schema", "pipeline_id", "root_layer_id", "branch_naming", "layers",
            "path_owners", "storage_targets", "deliveries",
        },
        "паспорт",
    )
    if паспорт["schema"] != СХЕМА:
        _ошибка(f"неподдержанная schema: {паспорт['schema']!r}")
    _строка(паспорт["pipeline_id"], "pipeline_id")
    корень = _строка(паспорт["root_layer_id"], "root_layer_id")
    имена = _требовать_словарь(паспорт["branch_naming"], "branch_naming")
    _точные_ключи(имена, {"scheme", "namespace"}, "branch_naming")
    if имена["scheme"] != СХЕМА_ИМЕНИ_ВЕТКИ:
        _ошибка("branch_naming.scheme: требуется братиславский path slug")
    namespace = _строка(имена["namespace"], "branch_naming.namespace")
    if not REF_СЕГМЕНТ.fullmatch(namespace.lower()) or namespace != namespace.lower():
        _ошибка("branch_naming.namespace: нужен lowercase Git-компонент")
    слои_списком = _требовать_список(паспорт["layers"], "layers")
    path_owners = _требовать_список(паспорт["path_owners"], "path_owners")
    storage_targets = _требовать_список(паспорт["storage_targets"], "storage_targets")
    deliveries = _требовать_список(паспорт["deliveries"], "deliveries")
    фазы: list[dict[str, Any]] = []

    def фаза(имя: str, функция: Callable[[], Any]) -> Any:
        старт = monotonic_ns()
        результат = функция()
        фазы.append({"name": имя, "duration_ns": monotonic_ns() - старт})
        return результат

    слои = фаза("layers", lambda: _проверить_слои(паспорт, слои_списком))
    владельцы = фаза(
        "path_owners", lambda: _проверить_владельцев(path_owners, слои)
    )
    фаза("storage_targets", lambda: _проверить_хранилища(storage_targets))
    количество_доставок, обратных = фаза(
        "deliveries",
        lambda: _проверить_доставки(deliveries, слои, владельцы, корень),
    )
    if паспорт != исходный_снимок:
        _ошибка("проверка изменила входной паспорт")
    return {
        "valid": True,
        "schema": СХЕМА,
        "pipeline_id": паспорт["pipeline_id"],
        "layers": len(слои),
        "path_owners": len(path_owners),
        "deliveries": количество_доставок,
        "reverse_deliveries": обратных,
        "storage_targets": len(storage_targets),
        "profile": {
            "duration_ns": monotonic_ns() - начало,
            "phases": фазы,
        },
    }


def _запустить(аргументы: list[str] | None = None) -> int:
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument(
        "--паспорт",
        required=True,
        type=argparse.FileType("r", encoding="utf-8"),
    )
    парсер.add_argument(
        "--профиль",
        action="store_true",
        help="сохранить фазы в JSON-сводке",
    )
    парсер.add_argument("--json", action="store_true", dest="json_вывод")
    параметры = парсер.parse_args(аргументы)
    try:
        паспорт = json.load(параметры.паспорт)
        результат = проверить_паспорт(паспорт)
    except (json.JSONDecodeError, OSError, ОшибкаПаспорта) as ошибка:
        print(f"FUM-PASSPORT ERROR: {ошибка}", file=sys.stderr)
        return 2
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(_запустить())
