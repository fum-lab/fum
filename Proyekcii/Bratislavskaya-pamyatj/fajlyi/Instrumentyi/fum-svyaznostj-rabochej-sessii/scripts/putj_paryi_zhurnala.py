"""Проверка компонентов пути перед чтением документа пары."""

from pathlib import Path


def проверить_путь(корень: Path, документ: Path) -> None:
    текущий = корень
    if текущий.is_symlink():
        raise ValueError("Символическая ссылка вместо выбранного корня")
    for часть in документ.relative_to(корень).parts:
        текущий = текущий / часть
        if текущий.is_symlink():
            raise ValueError("Символическая ссылка в пути пары Журнала")
    if not документ.is_file():
        raise ValueError("Отсутствует файл пары: " + документ.name)
