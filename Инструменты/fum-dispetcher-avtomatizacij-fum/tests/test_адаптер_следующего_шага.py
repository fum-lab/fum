from __future__ import annotations

import base64
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
import uuid
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from pathlib import Path


КОРЕНЬ_АВТОМАТИЗАЦИИ = Path(__file__).resolve().parents[1]
КОРЕНЬ_РЕПОЗИТОРИЯ = КОРЕНЬ_АВТОМАТИЗАЦИИ.parents[1]
СЦЕНАРИЙ = КОРЕНЬ_АВТОМАТИЗАЦИИ / "scripts" / "диспетчер-автоматизаций.py"
СЦЕНАРИЙ_ОЧЕРЕДИ = (
    КОРЕНЬ_РЕПОЗИТОРИЯ
    / "Инструменты"
    / "fum-ocheredj-zadach-git-vetki"
    / "scripts"
    / "ocheredj-zadach-git-vetki.py"
)
СЦЕНАРИЙ_АНАЛИТИКИ = (
    КОРЕНЬ_РЕПОЗИТОРИЯ
    / "Инструменты"
    / "fum-analitika-zavershyonnyikh-shagov"
    / "scripts"
    / "аналитика-завершённых-шагов.py"
)
СЦЕНАРИЙ_СЛЕДУЮЩЕГО_ШАГА = (
    КОРЕНЬ_РЕПОЗИТОРИЯ
    / "Инструменты"
    / "fum-sleduyusjhij-shag-vetki"
    / "scripts"
    / "branch-next-step.py"
)
СХЕМА = КОРЕНЬ_АВТОМАТИЗАЦИИ / "схемы" / "реестр-заданий-v1.schema.json"
КАНОНИЧЕСКИЙ_РЕЕСТР = (
    КОРЕНЬ_РЕПОЗИТОРИЯ
    / "Планирование"
    / "реестры-заданий-автоматизаций"
    / "master.json"
)
ФИКСТУРА_СОСТОЯНИЯ_ПОСЛЕ_СБРОСА = (
    КОРЕНЬ_АВТОМАТИЗАЦИИ
    / "tests"
    / "фикстуры"
    / "состояние-после-подтверждённого-сброса.json"
)
ОБЛАСТЬ_ОЧЕРЕДИ = "refs/fum/worktree-task-queues"
ОБЛАСТЬ_АНАЛИТИЧЕСКИХ_ПРЕТЕНЗИЙ = (
    "refs/fum/аналитика-завершённых-запусков"
)
ФИКСТУРА_РАЗРЫВА_ПОТОКА = (
    КОРЕНЬ_АВТОМАТИЗАЦИИ
    / "tests"
    / "фикстуры"
    / "снимок-задачи-с-терминальным-разрывом-потока.json"
)
СХЕМА_ПРЕДЛОЖЕНИЯ = (
    КОРЕНЬ_АВТОМАТИЗАЦИИ / "схемы" / "предложение-управления-v1.schema.json"
)
ПУТЬ_СЦЕНАРИЯ_ОЧЕРЕДИ_В_РЕПОЗИТОРИИ = (
    "Инструменты/fum-ocheredj-zadach-git-vetki/"
    "scripts/ocheredj-zadach-git-vetki.py"
)
КОД_ЗАПУСКА_ОЧЕРЕДИ_ИЗ_ВЕРШИНЫ = (
    "import os,subprocess,sys;"
    f"путь={ПУТЬ_СЦЕНАРИЯ_ОЧЕРЕДИ_В_РЕПОЗИТОРИИ!r};"
    "корень=sys.argv[1];"
    "среда={ключ:значение for ключ,значение in os.environ.items() "
    "if not ключ.upper().startswith('GIT_')};"
    "среда['GIT_NO_REPLACE_OBJECTS']='1';"
    "среда['GIT_OPTIONAL_LOCKS']='0';"
    "байты=subprocess.check_output(['git','--no-replace-objects','-C',корень,"
    "'show','HEAD:'+путь],env=среда,timeout=30);"
    "sys.argv=[путь,*sys.argv[2:],'--repo-root',корень];"
    "exec(compile(байты,путь,'exec'))"
)


class АдаптерСледующегоШага(unittest.TestCase):
    def выполнить(
        сам,
        корень: Path,
        *аргументы: str,
        среда: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(СЦЕНАРИЙ), *аргументы],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
            env=среда,
        )

    def выполнить_гит(
        сам,
        корень: Path,
        *аргументы: str,
        вход: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        результат = subprocess.run(
            ["git", "-C", str(корень), *аргументы],
            check=False,
            capture_output=True,
            text=True,
            input=вход,
        )
        сам.assertEqual(
            результат.returncode,
            0,
            результат.stdout + результат.stderr,
        )
        return результат

    def выполнить_очередь(
        сам,
        корень: Path,
        *аргументы: str,
        среда: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(СЦЕНАРИЙ_ОЧЕРЕДИ), *аргументы],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
            env=среда,
        )

    def выполнить_очередь_из_вершины(
        сам,
        корень: Path,
        *аргументы: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                "-I",
                "-c",
                КОД_ЗАПУСКА_ОЧЕРЕДИ_ИЗ_ВЕРШИНЫ,
                str(корень),
                *аргументы,
                "--json",
            ],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
        )

    def данные_успешного_процесса(
        сам,
        результат: subprocess.CompletedProcess[str],
    ) -> dict[str, object]:
        сам.assertEqual(
            результат.returncode,
            0,
            результат.stdout + результат.stderr,
        )
        данные = json.loads(результат.stdout)
        сам.assertIsInstance(данные, dict)
        return данные

    def выполнить_аналитику(
        сам,
        корень: Path,
        *аргументы: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(СЦЕНАРИЙ_АНАЛИТИКИ), *аргументы],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
        )

    def выполнить_следующий_шаг(
        сам,
        корень: Path,
        *аргументы: str,
    ) -> subprocess.CompletedProcess[str]:
        сценарий = (
            корень
            / "Инструменты"
            / "fum-sleduyusjhij-shag-vetki"
            / "scripts"
            / "branch-next-step.py"
        )
        return subprocess.run(
            [sys.executable, str(сценарий), *аргументы],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
        )

    def выполнить_штатный_сброс(
        сам,
        корень: Path,
        идентификатор_диспетчера: str,
    ) -> tuple[dict[str, object], dict[str, object], dict[str, object]]:
        среда = dict(os.environ)
        среда["CODEX_THREAD_ID"] = идентификатор_диспетчера
        план_процесса = сам.выполнить_очередь(
            корень,
            "план-сброса",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--json",
            среда=среда,
        )
        сам.assertEqual(
            план_процесса.returncode,
            0,
            план_процесса.stdout + план_процесса.stderr,
        )
        план = json.loads(план_процесса.stdout)
        подготовка_процесса = сам.выполнить_очередь(
            корень,
            "подготовить-сброс",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--ожидаемая-вершина",
            str(план["целевая_вершина"]),
            "--ожидаемый-объект-очереди",
            str(план["объект_очереди"]),
            "--подтверждение",
            str(план["подтверждение"]),
            "--json",
            среда=среда,
        )
        сам.assertEqual(
            подготовка_процесса.returncode,
            0,
            подготовка_процесса.stdout + подготовка_процесса.stderr,
        )
        подготовка = json.loads(подготовка_процесса.stdout)
        аргументы_неактивных = [
            аргумент
            for задача in план["участники"]
            for аргумент in ("--неактивная-задача", str(задача))
        ]
        остановка = сам.выполнить_очередь(
            корень,
            "подтвердить-остановку-сессий",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовка["идентификатор_сброса"]),
            *аргументы_неактивных,
            "--json",
            среда=среда,
        )
        сам.assertEqual(
            остановка.returncode,
            0,
            остановка.stdout + остановка.stderr,
        )
        сброс_процесса = сам.выполнить_очередь(
            корень,
            "применить-сброс",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовка["идентификатор_сброса"]),
            "--json",
            среда=среда,
        )
        сам.assertEqual(
            сброс_процесса.returncode,
            0,
            сброс_процесса.stdout + сброс_процесса.stderr,
        )
        return план, подготовка, json.loads(сброс_процесса.stdout)

    def записать_объект(сам, путь: Path, значение: object) -> None:
        путь.write_text(
            json.dumps(
                значение,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )

    def создать_репозиторий(
        сам,
    ) -> tuple[Path, Path, Path, Path, dict[str, object]]:
        временный_каталог = tempfile.TemporaryDirectory()
        сам.addCleanup(временный_каталог.cleanup)
        корень = Path(временный_каталог.name)
        инициализация = subprocess.run(
            ["git", "init", "--initial-branch=master", str(корень)],
            check=False,
            capture_output=True,
            text=True,
        )
        сам.assertEqual(инициализация.returncode, 0, инициализация.stderr)
        сам.выполнить_гит(корень, "config", "user.name", "FUM Tests")
        сам.выполнить_гит(
            корень,
            "config",
            "user.email",
            "fum-tests@example.invalid",
        )
        (корень / "README.md").write_text("# FUM\n", encoding="utf-8")
        каталог_карточек = корень / "Планирование" / "карточки-шагов"
        каталог_селекторов = корень / "Планирование" / "следующие-шаги-веток"
        каталог_карточек.mkdir(parents=True)
        каталог_селекторов.mkdir(parents=True)
        карточка = каталог_карточек / "🟡-FUM-STEP-0142-проверить-шаг.md"
        карточка.write_text(
            "+++\n"
            "schema_version = 1\n"
            'card_id = "FUM-STEP-0142"\n'
            'status = "active"\n'
            "+++\n"
            "# Проверить следующий шаг\n\n"
            "Эта карточка задаёт один исполняемый шаг.\n\n"
            "## Задача\n\n"
            "Обновить тестовый артефакт и подтвердить его проверкой.\n\n"
            "## Почему сейчас\n\n"
            "Шаг проверяет долговечное завершение.\n\n"
            "## Критерии завершения\n\n"
            "- Проверка проходит.\n"
            "- Результат сохранён в Git.\n\n"
            "## Источники\n\n"
            "- [Тестовый проект](../../README.md)\n",
            encoding="utf-8",
        )
        хэш_карточки = "sha256:" + hashlib.sha256(
            карточка.read_bytes()
        ).hexdigest()
        (каталог_селекторов / "master.md").write_text(
            "+++\n"
            "schema_version = 5\n"
            'branch_ref = "refs/heads/master"\n'
            'state = "open"\n'
            'project_path = "README.md"\n'
            "[[candidates]]\n"
            'step_id = "master-fum-step-0142-automatic-v5"\n'
            'dispatch = "automatic"\n'
            'card_id = "FUM-STEP-0142"\n'
            f'card_content_sha256 = "{хэш_карточки}"\n'
            "requires_completed_card_ids = []\n"
            "+++\n"
            "# Выбрать шаг тестовой ветки\n\n"
            "Селектор связывает ветку с карточкой.\n\n"
            "## Источники\n\n"
            "- [Тестовый проект](../../README.md)\n",
            encoding="utf-8",
        )
        исторический_сценарий = (
            корень
            / "Инструменты"
            / "fum-sleduyusjhij-shag-vetki"
            / "scripts"
            / "branch-next-step.py"
        )
        исторический_сценарий.parent.mkdir(parents=True)
        исторический_сценарий.write_bytes(
            СЦЕНАРИЙ_СЛЕДУЮЩЕГО_ШАГА.read_bytes()
        )
        реестр = json.loads(КАНОНИЧЕСКИЙ_РЕЕСТР.read_text(encoding="utf-8"))
        путь_реестра = корень / "реестр.json"
        путь_схемы = корень / "схема.json"
        путь_наблюдений = корень / "наблюдения.json"
        наблюдения = {
            "версия_схемы": 1,
            "момент": "2026-08-05T12:05:00Z",
            "условия": {
                условие["наблюдение"]: True
                for условие in реестр["задания"][0]["условия_допуска"]
            },
            "подтверждённые_события": {},
        }
        сам.записать_объект(путь_реестра, реестр)
        путь_схемы.write_bytes(СХЕМА.read_bytes())
        сам.записать_объект(путь_наблюдений, наблюдения)
        сам.выполнить_гит(корень, "add", "--", ".")
        сам.выполнить_гит(корень, "commit", "-m", "Создать фикстуру")
        выбор = сам.выбрать(
            корень,
            путь_реестра,
            путь_схемы,
            путь_наблюдений,
        )
        return корень, путь_реестра, путь_схемы, путь_наблюдений, выбор

    def выбрать(
        сам,
        корень: Path,
        реестр: Path,
        схема: Path,
        наблюдения: Path,
    ) -> dict[str, object]:
        результат = сам.выполнить(
            корень,
            "выбрать",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            "--наблюдения",
            str(наблюдения),
            "--json",
        )
        сам.assertEqual(
            результат.returncode,
            0,
            результат.stdout + результат.stderr,
        )
        return json.loads(результат.stdout)

    def аргументы_выбора(
        сам,
        корень: Path,
        реестр: Path,
        схема: Path,
        наблюдения: Path,
        выбор: dict[str, object],
    ) -> list[str]:
        return [
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            "--наблюдения",
            str(наблюдения),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--expected-spec-generation",
            str(выбор["spec_generation"]),
            "--expected-registry-generation",
            str(выбор["поколение_реестра"]),
            "--expected-run-key",
            str(выбор["run_key"]),
        ]

    def аргументы_ограждения_запуска(
        сам,
        корень: Path,
        выбор: dict[str, object],
        попытка: str,
    ) -> list[str]:
        return [
            "--корень-рабочей-копии",
            str(корень),
            "--expected-branch-ref",
            str(выбор["branch_ref"]),
            "--expected-selection-head",
            str(выбор["selection_head"]),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--expected-spec-generation",
            str(выбор["spec_generation"]),
            "--expected-registry-generation",
            str(выбор["поколение_реестра"]),
            "--expected-run-key",
            str(выбор["run_key"]),
            "--идентификатор-попытки",
            попытка,
        ]

    def подготовить_создание(
        сам,
        корень: Path,
        реестр: Path,
        схема: Path,
        наблюдения: Path,
        выбор: dict[str, object],
        попытка: str,
        идентификатор_среды: str,
        *,
        точное_свидетельство: bool = False,
    ) -> None:
        общие = сам.аргументы_выбора(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
        )
        резерв = сам.выполнить(
            корень,
            "зарезервировать",
            *общие,
            "--идентификатор-попытки",
            попытка,
            "--json",
        )
        сам.assertEqual(резерв.returncode, 0, резерв.stderr)
        сам.записать_претензию_до_вызова_среды(
            корень,
            выбор,
            попытка,
        )
        граница = сам.выполнить(
            корень,
            "начать-вызов-среды",
            *общие,
            "--идентификатор-попытки",
            попытка,
            "--json",
        )
        сам.assertEqual(граница.returncode, 0, граница.stderr)
        аргументы_свидетельства = (
            ["--thread-id", идентификатор_среды, "--host-id", "local"]
            if точное_свидетельство
            else ["--client-thread-id", идентификатор_среды]
        )
        подтверждение = сам.выполнить(
            корень,
            "подтвердить-создание",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            *аргументы_свидетельства,
            "--json",
        )
        сам.assertEqual(
            подтверждение.returncode,
            0,
            подтверждение.stdout + подтверждение.stderr,
        )

    def записать_очередь(
        сам,
        корень: Path,
        ветка: str,
        идентификатор_задачи: str,
        поколение_очереди: str,
        исходная_вершина: str,
        *,
        завершение: dict[str, object] | None = None,
    ) -> str:
        каталог_системы_версий = Path(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--absolute-git-dir",
            ).stdout.strip()
        ).resolve()
        идентичность = hashlib.sha256(
            os.path.normcase(str(каталог_системы_версий)).encode("utf-8")
        ).hexdigest()
        владелец = None
        if завершение is None:
            владелец = {
                "task_id": идентификатор_задачи,
                "ticket_id": "ticket-1",
                "seq": 1,
                "generation": поколение_очереди,
                "base_head": исходная_вершина,
                "admitted_at": "2026-08-05T12:05:01+00:00",
                "admitted_at_epoch": 1.0,
            }
        состояние = {
            "schema_version": 1,
            "worktree_id": идентичность,
            "branch_ref": ветка,
            "next_seq": 2,
            "owner": владелец,
            "waiting": [],
            "last_completion": завершение,
            "updated_at": (
                str(завершение["completed_at"])
                if завершение is not None
                else "2026-08-05T12:05:02+00:00"
            ),
        }
        объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                состояние,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            f"{ОБЛАСТЬ_ОЧЕРЕДИ}/{идентичность}",
            объект,
        )
        return объект

    def записать_пустую_очередь_цепочки(
        сам,
        корень: Path,
        ветка: str,
    ) -> tuple[str, str]:
        каталог_системы_версий = Path(
            сам.выполнить_гит(корень, "rev-parse", "--absolute-git-dir").stdout.strip()
        ).resolve()
        идентичность = hashlib.sha256(
            os.path.normcase(str(каталог_системы_версий)).encode("utf-8")
        ).hexdigest()
        ссылка = f"{ОБЛАСТЬ_ОЧЕРЕДИ}/{идентичность}"
        очередь = {
            "schema_version": 1,
            "worktree_id": идентичность,
            "branch_ref": ветка,
            "next_seq": 1,
            "owner": None,
            "waiting": [],
            "last_completion": None,
            "updated_at": "2026-08-10T12:00:00+00:00",
            "текущая_цепочка": {
                "идентификатор": "FUM-ЦЕПОЧКА-0001",
                "путь": "Планирование/карточки-цепочек-шагов/FUM-ЦЕПОЧКА-0001.md",
                "хэш": "sha256:" + "1" * 64,
                "ветка": ветка,
            },
        }
        объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(очередь, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n",
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка, объект)
        return ссылка, объект

    def записать_аналитическую_претензию(
        сам,
        корень: Path,
        выбор: dict[str, object],
        попытка: str,
        идентификатор_задачи: str,
        поколение_очереди: str,
        вершина_результата: str,
        *,
        фаза: str = "завершена",
        изменение: tuple[str, object] | None = None,
        канонический: bool = True,
    ) -> tuple[str, str]:
        каталог_системы_версий = Path(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--absolute-git-dir",
            ).stdout.strip()
        ).resolve()
        идентичность = hashlib.sha256(
            os.path.normcase(str(каталог_системы_версий)).encode("utf-8")
        ).hexdigest()
        ветка = str(выбор["branch_ref"])
        хэш_ветки = hashlib.sha256(ветка.encode("utf-8")).hexdigest()
        ссылка = (
            f"{ОБЛАСТЬ_АНАЛИТИЧЕСКИХ_ПРЕТЕНЗИЙ}/"
            f"{идентичность}/{хэш_ветки}"
        )
        конец = int(
            dict(выбор["trigger_occurrence"])["конец"]
        )
        начало = int(
            dict(выбор["trigger_occurrence"])["начало"]
        )
        идентификаторы = [
            "sha256:" + f"{индекс:064x}"
            for индекс in range(начало, конец + 1)
        ]
        идентификатор_анализа = "sha256:" + hashlib.sha256(
            json.dumps(
                {
                    "branch_ref": ветка,
                    "job_id": str(выбор["job_id"]),
                    "spec_generation": int(выбор["spec_generation"]),
                    "trigger_occurrence": выбор["trigger_occurrence"],
                    "начало": начало,
                    "конец": конец,
                    "идентификаторы_событий": идентификаторы,
                },
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        путь_отчёта = (
            "Оценки/аналитика-завершённых-запусков/master/"
            f"{str(выбор['job_id'])}/{начало:010d}-{конец:010d}.md"
        )
        байты_отчёта = (
            (корень / путь_отчёта).read_bytes()
            if (корень / путь_отчёта).is_file()
            else b""
        )
        хэш_содержимого_отчёта = "sha256:" + hashlib.sha256(
            байты_отчёта
        ).hexdigest()
        претензия = {
            "схема": "fum.претензия-аналитики-завершённых-запусков.1",
            "branch_ref": ветка,
            "selection_head": str(выбор["selection_head"]),
            "job_id": str(выбор["job_id"]),
            "spec_generation": int(выбор["spec_generation"]),
            "поколение_реестра": int(выбор["поколение_реестра"]),
            "trigger_occurrence": выбор["trigger_occurrence"],
            "run_key": str(выбор["run_key"]),
            "идентификатор_попытки": попытка,
            "lease_id": попытка,
            "порог": конец,
            "диапазон_событий": {
                "начало": начало,
                "конец": конец,
                "идентификаторы_событий": идентификаторы,
                "источники": [
                    {"идентификатор": идентификатор}
                    for идентификатор in идентификаторы
                ],
            },
            "назначение": (
                f"Проведи аналитическую ревизию конечного диапазона подтверждённых событий {начало}–{конец}. "
                "Назови наблюдаемую способность, терминальную приёмку, отрицательные результаты и стоимость пройденной цепочки. "
                "Сверь выводы с внешними критериями и проверяемыми источниками. Не считать число шагов, коммитов или документов доказательством улучшения."
            ),
            "путь_реестра": "реестр.json",
            "путь_отчёта": путь_отчёта,
            "идентификатор_анализа": идентификатор_анализа,
            "фаза": фаза,
            "task_id": (
                None
                if фаза == "зарезервирована"
                else идентификатор_задачи
            ),
            "generation": (
                поколение_очереди
                if фаза in {"подтверждена", "передана", "завершена"}
                else None
            ),
            "свидетельство_передачи": (
                {
                    "base_head": str(выбор["selection_head"]),
                    "commit": вершина_результата,
                    "task_id": идентификатор_задачи,
                    "generation": поколение_очереди,
                }
                if фаза in {"передана", "завершена"}
                else None
            ),
            "подтверждённый_результат": (
                {
                    "идентификатор": идентификатор_анализа,
                    "путь": путь_отчёта,
                    "content_sha256": хэш_содержимого_отчёта,
                    "конец_диапазона": конец,
                    "commit": вершина_результата,
                }
                if фаза == "завершена"
                else None
            ),
        }
        if изменение is not None:
            поле, значение = изменение
            if поле == "подтверждённый_результат.commit":
                результат = dict(претензия["подтверждённый_результат"])
                результат["commit"] = значение
                претензия["подтверждённый_результат"] = результат
            else:
                претензия[поле] = значение
        объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                претензия,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":") if канонический else None,
                indent=None if канонический else 2,
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка,
            объект,
        )
        return ссылка, объект

    def подготовить_аналитическое_завершение(
        сам,
    ) -> tuple[
        Path,
        dict[str, object],
        str,
        str,
        str,
    ]:
        корень, реестр, схема, наблюдения, _ = сам.создать_репозиторий()
        значение_наблюдений = json.loads(
            наблюдения.read_text(encoding="utf-8")
        )
        значение_наблюдений["подтверждённые_события"] = {
            "завершение_runtime_ready_commit_handoff": 5,
        }
        сам.записать_объект(наблюдения, значение_наблюдений)
        сам.выполнить_гит(корень, "add", "--", "наблюдения.json")
        сам.выполнить_гит(
            корень,
            "commit",
            "-m",
            "Достичь порога аналитики",
        )
        выбор = сам.выбрать(корень, реестр, схема, наблюдения)
        сам.assertEqual(выбор["job_id"], "master.completed-step-analysis")
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "analytic-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            идентификатор_задачи,
            точное_свидетельство=True,
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        наступление = dict(выбор["trigger_occurrence"])
        начало = int(наступление["начало"])
        конец = int(наступление["конец"])
        путь_отчёта = корень / (
            "Оценки/аналитика-завершённых-запусков/master/"
            f"{str(выбор['job_id'])}/{начало:010d}-{конец:010d}.md"
        )
        путь_отчёта.parent.mkdir(parents=True)
        путь_отчёта.write_text(
            "готово\n",
            encoding="utf-8",
        )
        идентификаторы = [
            "sha256:" + f"{индекс:064x}"
            for индекс in range(начало, конец + 1)
        ]
        идентификатор_анализа = "sha256:" + hashlib.sha256(
            json.dumps(
                {
                    "branch_ref": str(выбор["branch_ref"]),
                    "job_id": str(выбор["job_id"]),
                    "spec_generation": int(выбор["spec_generation"]),
                    "trigger_occurrence": выбор["trigger_occurrence"],
                    "начало": начало,
                    "конец": конец,
                    "идентификаторы_событий": идентификаторы,
                },
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        реестр_после = json.loads(реестр.read_text(encoding="utf-8"))
        аналитическое_задание = next(
            задание
            for задание in реестр_после["задания"]
            if задание["job_id"] == "master.completed-step-analysis"
        )
        курсор = аналитическое_задание["курсор_результата"]
        курсор["последнее_число_подтверждённых_событий"] = конец
        курсор["следующий_порог"] = конец + int(
            аналитическое_задание["триггер"]["каждые"]
        )
        курсор["последний_подтверждённый_аналитический_результат"] = {
            "идентификатор": идентификатор_анализа,
            "путь": путь_отчёта.relative_to(корень).as_posix(),
            "content_sha256": "sha256:" + hashlib.sha256(
                путь_отчёта.read_bytes()
            ).hexdigest(),
            "конец_диапазона": конец,
        }
        сам.записать_объект(реестр, реестр_после)
        сам.выполнить_гит(
            корень,
            "add",
            "--",
            str(путь_отчёта),
            str(реестр),
        )
        сам.выполнить_гит(корень, "commit", "-m", "Завершить анализ")
        вершина_результата = сам.выполнить_гит(
            корень,
            "rev-parse",
            "HEAD",
        ).stdout.strip()
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
            завершение={
                "kind": "committed",
                "task_id": идентификатор_задачи,
                "generation": поколение_очереди,
                "base_head": str(выбор["selection_head"]),
                "head": вершина_результата,
                "completed_at": "2026-08-05T12:06:00+00:00",
            },
        )
        return (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )

    def подготовить_аналитическую_резервацию_до_среды(
        сам,
    ) -> tuple[Path, Path, Path, Path, dict[str, object], str]:
        корень, реестр, схема, наблюдения, _ = сам.создать_репозиторий()
        значение_наблюдений = json.loads(
            наблюдения.read_text(encoding="utf-8")
        )
        значение_наблюдений["подтверждённые_события"] = {
            "завершение_runtime_ready_commit_handoff": 5,
        }
        сам.записать_объект(наблюдения, значение_наблюдений)
        сам.выполнить_гит(корень, "add", "--", "наблюдения.json")
        сам.выполнить_гит(корень, "commit", "-m", "Достичь порога до вызова среды")
        выбор = сам.выбрать(корень, реестр, схема, наблюдения)
        сам.assertEqual(выбор["job_id"], "master.completed-step-analysis")
        попытка = str(uuid.uuid4())
        резерв = сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(корень, реестр, схема, наблюдения, выбор),
            "--идентификатор-попытки",
            попытка,
            "--json",
        )
        сам.assertEqual(резерв.returncode, 0, резерв.stdout + резерв.stderr)
        return корень, реестр, схема, наблюдения, выбор, попытка

    def подготовить_резервацию_живого_адаптера(
        сам,
        аналитика: bool,
    ) -> tuple[Path, Path, Path, Path, dict[str, object], str]:
        if аналитика:
            return сам.подготовить_аналитическую_резервацию_до_среды()
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        резерв = сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(
                корень,
                реестр,
                схема,
                наблюдения,
                выбор,
            ),
            "--идентификатор-попытки",
            попытка,
            "--json",
        )
        сам.assertEqual(резерв.returncode, 0, резерв.stdout + резерв.stderr)
        return корень, реестр, схема, наблюдения, выбор, попытка

    def аргументы_аналитической_претензии(
        сам,
        корень: Path,
        реестр: Path,
        схема: Path,
        выбор: dict[str, object],
        попытка: str,
    ) -> list[str]:
        return [
            "претендовать",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--expected-branch-ref",
            str(выбор["branch_ref"]),
            "--expected-selection-head",
            str(выбор["selection_head"]),
            "--expected-spec-generation",
            str(выбор["spec_generation"]),
            "--expected-registry-generation",
            str(выбор["поколение_реестра"]),
            "--expected-run-key",
            str(выбор["run_key"]),
            "--expected-threshold",
            str(dict(выбор["trigger_occurrence"])["конец"]),
            "--идентификатор-попытки",
            попытка,
            "--lease-id",
            попытка,
            "--json",
        ]

    def аргументы_аналитического_освобождения(
        сам,
        корень: Path,
        выбор: dict[str, object],
        попытка: str,
    ) -> list[str]:
        return [
            "освободить",
            "--корень-рабочей-копии",
            str(корень),
            "--expected-branch-ref",
            str(выбор["branch_ref"]),
            "--expected-selection-head",
            str(выбор["selection_head"]),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--expected-spec-generation",
            str(выбор["spec_generation"]),
            "--expected-registry-generation",
            str(выбор["поколение_реестра"]),
            "--expected-run-key",
            str(выбор["run_key"]),
            "--expected-threshold",
            str(dict(выбор["trigger_occurrence"])["конец"]),
            "--идентификатор-попытки",
            попытка,
            "--expected-lease-id",
            попытка,
            "--json",
        ]

    def аргументы_общего_освобождения(
        сам,
        корень: Path,
        выбор: dict[str, object],
        попытка: str,
        состояние: str | None = None,
    ) -> list[str]:
        аргументы = [
            "освободить",
            "--корень-рабочей-копии",
            str(корень),
            "--expected-branch-ref",
            str(выбор["branch_ref"]),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--expected-run-key",
            str(выбор["run_key"]),
            "--идентификатор-попытки",
            попытка,
        ]
        if состояние is not None:
            аргументы.extend(["--adapter-recovery-state", состояние])
        return [*аргументы, "--json"]

    def продвинуть_выбор_после_успеха(
        сам,
        корень: Path,
        ожидаемое_задание: str,
    ) -> tuple[Path, Path, Path, dict[str, object]]:
        реестр = корень / "реестр.json"
        схема = корень / "схема.json"
        наблюдения = корень / "наблюдения.json"
        значение = json.loads(наблюдения.read_text(encoding="utf-8"))
        значение["момент"] = "2026-08-05T12:10:00Z"
        if ожидаемое_задание == "master.completed-step-analysis":
            значение["подтверждённые_события"] = {
                "завершение_runtime_ready_commit_handoff": 10,
            }
        else:
            сам.assertEqual(ожидаемое_задание, "master.next-step")
            значение["подтверждённые_события"] = {}
        сам.записать_объект(наблюдения, значение)
        сам.выполнить_гит(корень, "add", "--", "наблюдения.json")
        сам.выполнить_гит(
            корень,
            "commit",
            "-m",
            "Открыть следующий запуск",
        )
        выбор = сам.выбрать(корень, реестр, схема, наблюдения)
        сам.assertEqual(выбор["job_id"], ожидаемое_задание)
        return реестр, схема, наблюдения, выбор

    def резервировать_новый_запуск(
        сам,
        корень: Path,
        реестр: Path,
        схема: Path,
        наблюдения: Path,
        выбор: dict[str, object],
        попытка: str,
    ) -> subprocess.CompletedProcess[str]:
        return сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(
                корень,
                реестр,
                схема,
                наблюдения,
                выбор,
            ),
            "--идентификатор-попытки",
            попытка,
            "--json",
        )

    def проверить_отсутствие_ссылки(
        сам,
        корень: Path,
        ссылка: str,
    ) -> None:
        результат = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", ссылка],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
        )
        сам.assertEqual(результат.returncode, 1, результат.stderr)

    def переписать_карточочную_претензию_в_схему_четыре(
        сам,
        корень: Path,
        ссылка: str,
        объект: str,
    ) -> str:
        претензия = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект,
            ).stdout
        )
        претензия["schema_version"] = 4
        претензия.pop("card_id")
        новый_объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                претензия,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка,
            новый_объект,
            объект,
        )
        return новый_объект

    def подготовить_аналитический_сброс(
        сам,
        фаза_претензии: str,
    ) -> tuple[
        Path,
        dict[str, object],
        str,
        str,
        str,
        str,
        str,
    ]:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_аналитическое_завершение()
        вершина_результата = сам.выполнить_гит(
            корень,
            "rev-parse",
            "HEAD",
        ).stdout.strip()
        ссылка_претензии, объект_претензии = (
            сам.записать_аналитическую_претензию(
                корень,
                выбор,
                попытка,
                идентификатор_задачи,
                поколение_очереди,
                вершина_результата,
                фаза=фаза_претензии,
            )
        )
        завершение: dict[str, object] | None = None
        if фаза_претензии in {"передана", "завершена"}:
            завершение = {
                "kind": "committed",
                "task_id": идентификатор_задачи,
                "generation": поколение_очереди,
                "base_head": str(выбор["selection_head"]),
                "head": вершина_результата,
                "completed_at": "2026-08-05T12:06:00+00:00",
            }
        объект_исходной_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
            завершение=завершение,
        )
        исходная_очередь = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_исходной_очереди,
            ).stdout
        )
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации), 2)
        ссылка_резервации, объект_резервации = снимок_резервации
        if фаза_претензии in {"зарезервирована", "привязана"}:
            резервация = json.loads(
                сам.выполнить_гит(
                    корень,
                    "cat-file",
                    "blob",
                    объект_резервации,
                ).stdout
            )
            резервация["generation"] = None
            if фаза_претензии == "зарезервирована":
                резервация["task_id"] = None
            новый_объект_резервации = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход=json.dumps(
                    резервация,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                )
                + "\n",
            ).stdout.strip()
            сам.выполнить_гит(
                корень,
                "update-ref",
                ссылка_резервации,
                новый_объект_резервации,
                объект_резервации,
            )
            объект_резервации = новый_объект_резервации
        фикстура = json.loads(
            ФИКСТУРА_СОСТОЯНИЯ_ПОСЛЕ_СБРОСА.read_text(encoding="utf-8")
        )
        сам.записать_квитанцию_сброса(
            корень,
            выбор,
            ссылка_резервации,
            объект_резервации,
            идентификатор_задачи,
            поколение_очереди,
            объект_исходной_очереди,
            исходная_очередь,
            dict(фикстура["квитанция_сброса"]),
            включить_ограждение_претензии=False,
            дополнительное_ограждение={
                "ссылка": ссылка_претензии,
                "объект": объект_претензии,
                "действие_при_завершении": "сохранить",
            },
            целевая_вершина=(
                str(выбор["selection_head"])
                if фаза_претензии
                in {"зарезервирована", "привязана", "подтверждена"}
                else вершина_результата
            ),
        )
        if фаза_претензии in {
            "зарезервирована",
            "привязана",
            "подтверждена",
        }:
            сам.выполнить_гит(
                корень,
                "reset",
                "--hard",
                str(выбор["selection_head"]),
            )
        return (
            корень,
            выбор,
            попытка,
            ссылка_претензии,
            объект_претензии,
            ссылка_резервации,
            объект_резервации,
        )

    def записать_точную_претензию(
        сам,
        корень: Path,
        выбор: dict[str, object],
        попытка: str,
        идентификатор_задачи: str | None,
        поколение_очереди: str | None,
    ) -> tuple[str, str]:
        каталог_системы_версий = Path(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--absolute-git-dir",
            ).stdout.strip()
        ).resolve()
        идентичность = hashlib.sha256(
            os.path.normcase(str(каталог_системы_версий)).encode("utf-8")
        ).hexdigest()
        ветка = str(выбор["branch_ref"])
        хэш_ветки = hashlib.sha256(ветка.encode("utf-8")).hexdigest()
        ссылка = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        специализированный_выбор = сам.показать_специализированный_выбор(корень)
        выбор_шага = dict(специализированный_выбор["selection"])
        претензия = {
            "schema_version": 5,
            "branch_ref": ветка,
            "step_id": специализированный_выбор["step_id"],
            "card_id": специализированный_выбор["card_id"],
            "lease_id": попытка,
            "selection_id": выбор_шага["id"],
            "selection_head": выбор_шага["head"],
            "task_id": идентификатор_задачи,
            "generation": поколение_очереди,
        }
        объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                претензия,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка, объект)
        return ссылка, объект

    def записать_претензию_до_вызова_среды(
        сам,
        корень: Path,
        выбор: dict[str, object],
        попытка: str,
    ) -> tuple[str, str]:
        if выбор["job_id"] == "master.next-step":
            return сам.записать_точную_претензию(
                корень,
                выбор,
                попытка,
                None,
                None,
            )
        сам.assertEqual(выбор["job_id"], "master.completed-step-analysis")
        return сам.записать_аналитическую_претензию(
            корень,
            выбор,
            попытка,
            "неиспользованная-задача",
            "неиспользованное-поколение",
            str(выбор["selection_head"]),
            фаза="зарезервирована",
        )

    def показать_специализированный_выбор(
        сам,
        корень: Path,
    ) -> dict[str, object]:
        сценарий = (
            корень
            / "Инструменты"
            / "fum-sleduyusjhij-shag-vetki"
            / "scripts"
            / "branch-next-step.py"
        )
        результат = subprocess.run(
            [
                sys.executable,
                str(сценарий),
                "show",
                "--repo-root",
                str(корень),
                "--json",
            ],
            cwd=корень,
            check=False,
            capture_output=True,
            text=True,
        )
        сам.assertEqual(
            результат.returncode,
            0,
            результат.stdout + результат.stderr,
        )
        return json.loads(результат.stdout)

    def служебная_основа_ветки(
        сам,
        корень: Path,
        ветка: str,
    ) -> tuple[str, str]:
        каталог_системы_версий = Path(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--absolute-git-dir",
            ).stdout.strip()
        ).resolve()
        идентичность = hashlib.sha256(
            os.path.normcase(str(каталог_системы_версий)).encode("utf-8")
        ).hexdigest()
        return идентичность, hashlib.sha256(ветка.encode("utf-8")).hexdigest()

    def записать_претензию_и_журнал_следующего_шага(
        сам,
        корень: Path,
        выбор: dict[str, object],
        специализированный_выбор: dict[str, object],
        попытка: str,
        идентификатор_задачи: str,
        поколение_очереди: str,
        завершивший_коммит: str,
    ) -> tuple[str, str]:
        ветка = str(выбор["branch_ref"])
        идентичность, хэш_ветки = сам.служебная_основа_ветки(корень, ветка)
        выбор_шага = dict(специализированный_выбор["selection"])
        претензия = {
            "schema_version": 5,
            "branch_ref": ветка,
            "step_id": специализированный_выбор["step_id"],
            "card_id": специализированный_выбор["card_id"],
            "selection_id": выбор_шага["id"],
            "selection_head": выбор_шага["head"],
            "lease_id": попытка,
            "task_id": идентификатор_задачи,
            "generation": поколение_очереди,
        }
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_претензии = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                претензия,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка_претензии, объект_претензии)
        событие = {
            "номер": 1,
            "идентификатор": "",
            "branch_ref": ветка,
            "step_id": претензия["step_id"],
            "card_id": претензия["card_id"],
            "selection_head": выбор["selection_head"],
            "завершивший_commit": завершивший_коммит,
            "результат": "commit+handoff",
            "job_id": "master.next-step",
            "spec_generation": выбор["spec_generation"],
        }
        основа_события = {
            ключ: событие[ключ]
            for ключ in (
                "branch_ref",
                "step_id",
                "card_id",
                "завершивший_commit",
                "результат",
            )
        }
        событие["идентификатор"] = "sha256:" + hashlib.sha256(
            json.dumps(
                основа_события,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        журнал = {
            "схема": "fum.журнал-завершённых-запусков.1",
            "branch_ref": ветка,
            "число_событий": 1,
            "события": [событие],
        }
        ссылка_журнала = (
            "refs/fum/worktree-task-completion-ledgers/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_журнала = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                журнал,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка_журнала, объект_журнала)
        return ссылка_претензии, ссылка_журнала

    def подготовить_завершение_следующего_шага_с_журналом(
        сам,
    ) -> tuple[
        Path,
        dict[str, object],
        str,
        str,
        str,
        str,
        str,
    ]:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        сам.assertEqual(выбор["job_id"], "master.next-step")
        специализированный_выбор = сам.показать_специализированный_выбор(корень)
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "ledger-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            идентификатор_задачи,
            точное_свидетельство=True,
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        with (корень / "README.md").open("a", encoding="utf-8") as файл:
            файл.write("Результат шага.\n")
        сам.выполнить_гит(корень, "add", "--", "README.md")
        сам.выполнить_гит(корень, "commit", "-m", "Завершить точный шаг")
        завершивший_коммит = сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip()
        ссылка_претензии, ссылка_журнала = сам.записать_претензию_и_журнал_следующего_шага(
            корень,
            выбор,
            специализированный_выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            завершивший_коммит,
        )
        with (корень / "README.md").open("a", encoding="utf-8") as файл:
            файл.write("Поздняя задача меняет тот же путь.\n")
        сам.выполнить_гит(корень, "add", "--", "README.md")
        сам.выполнить_гит(корень, "commit", "-m", "Завершить позднюю задачу")
        поздняя_вершина = сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip()
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            "later-root-task",
            "later-generation",
            завершивший_коммит,
            завершение={
                "kind": "committed",
                "task_id": "later-root-task",
                "generation": "later-generation",
                "base_head": завершивший_коммит,
                "head": поздняя_вершина,
                "completed_at": "2026-08-05T12:08:00+00:00",
            },
        )
        return (
            корень,
            выбор,
            попытка,
            завершивший_коммит,
            поздняя_вершина,
            ссылка_претензии,
            ссылка_журнала,
        )

    def подготовить_чистое_завершение_следующего_шага_с_поздней_передачей(
        сам,
        *,
        добавить_позднюю_передачу: bool = True,
        версия_претензии_до_перезарядки: int = 5,
        выполнить_чистое_завершение: bool = True,
    ) -> tuple[Path, dict[str, object], str, str, str, str, str]:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        сам.assertEqual(выбор["job_id"], "master.next-step")
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "clean-next-step-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень, реестр, схема, наблюдения, выбор, попытка,
            идентификатор_задачи, точное_свидетельство=True,
        )
        привязка = сам.выполнить(
            корень, "bind-run", *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id", идентификатор_задачи, "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stdout + привязка.stderr)
        сам.записать_очередь(
            корень, str(выбор["branch_ref"]), идентификатор_задачи,
            поколение_очереди, str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень, "verify-run", *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id", идентификатор_задачи, "--generation", поколение_очереди, "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stdout + проверка.stderr)
        ссылка_претензии, _ = сам.записать_точную_претензию(
            корень, выбор, попытка, идентификатор_задачи, поколение_очереди,
        )
        объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()
        претензия = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_претензии,
            ).stdout
        )
        if версия_претензии_до_перезарядки == 4:
            претензия["schema_version"] = 4
            претензия.pop("card_id")
            объект_схемы_четыре = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход=json.dumps(
                    претензия,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                )
                + "\n",
            ).stdout.strip()
            сам.выполнить_гит(
                корень,
                "update-ref",
                ссылка_претензии,
                объект_схемы_четыре,
                объект_претензии,
            )
        else:
            сам.assertEqual(версия_претензии_до_перезарядки, 5)
        перезарядка = сам.выполнить_следующий_шаг(
            корень,
            "rearm",
            "--repo-root",
            str(корень),
            "--expected-branch-ref",
            str(претензия["branch_ref"]),
            "--expected-step-id",
            str(претензия["step_id"]),
            "--expected-selection-id",
            str(претензия["selection_id"]),
            "--expected-lease-id",
            попытка,
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(
            перезарядка.returncode,
            0,
            перезарядка.stdout + перезарядка.stderr,
        )
        сам.assertEqual(json.loads(перезарядка.stdout)["state"], "rearmed")
        объект_после_перезарядки = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()
        претензия_после_перезарядки = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_после_перезарядки,
            ).stdout
        )
        сам.assertEqual(претензия_после_перезарядки["schema_version"], 5)
        повтор_перезарядки = сам.выполнить_следующий_шаг(
            корень,
            "rearm",
            "--repo-root",
            str(корень),
            "--expected-branch-ref",
            str(претензия["branch_ref"]),
            "--expected-step-id",
            str(претензия["step_id"]),
            "--expected-selection-id",
            str(претензия["selection_id"]),
            "--expected-lease-id",
            попытка,
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(
            повтор_перезарядки.returncode,
            0,
            повтор_перезарядки.stdout + повтор_перезарядки.stderr,
        )
        сам.assertEqual(
            json.loads(повтор_перезарядки.stdout)["ownership"],
            "existing",
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip(),
            объект_после_перезарядки,
        )
        if not выполнить_чистое_завершение:
            исходная_вершина = str(выбор["selection_head"])
            return (
                корень,
                выбор,
                попытка,
                идентификатор_задачи,
                поколение_очереди,
                исходная_вершина,
                исходная_вершина,
            )
        чисто = сам.выполнить_очередь(
            корень, "finish-clean", "--repo-root", str(корень), "--task-id", идентификатор_задачи,
            "--generation", поколение_очереди, "--json",
        )
        сам.assertEqual(чисто.returncode, 0, чисто.stdout + чисто.stderr)
        вершина_чистого_завершения = str(json.loads(чисто.stdout)["head"])
        объект_претензии = сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip()
        претензия = json.loads(сам.выполнить_гит(корень, "cat-file", "blob", объект_претензии).stdout)
        сам.assertEqual(претензия["schema_version"], 6)

        поздняя_вершина = сам.выполнить_гит(
            корень,
            "rev-parse",
            "HEAD",
        ).stdout.strip()
        if добавить_позднюю_передачу:
            допуск_поздней = сам.выполнить_очередь(
                корень, "join", "--repo-root", str(корень), "--task-id", "later-clean-overwriter", "--json",
            )
            сам.assertEqual(допуск_поздней.returncode, 0, допуск_поздней.stdout + допуск_поздней.stderr)
            поколение_поздней = str(json.loads(допуск_поздней.stdout)["generation"])
            with (корень / "README.md").open("a", encoding="utf-8") as файл:
                файл.write("Поздняя задача после чистого завершения.\n")
            сам.выполнить_гит(корень, "add", "--", "README.md")
            поздняя_передача = сам.выполнить_очередь(
                корень, "commit", "--repo-root", str(корень), "--task-id", "later-clean-overwriter",
                "--generation", поколение_поздней, "--message", "Завершить позднюю задачу", "--json",
            )
            сам.assertEqual(поздняя_передача.returncode, 0, поздняя_передача.stdout + поздняя_передача.stderr)
            поздняя_вершина = str(json.loads(поздняя_передача.stdout)["new_head"])
        return (корень, выбор, попытка, идентификатор_задачи, поколение_очереди, вершина_чистого_завершения, поздняя_вершина)

    def подготовить_точное_возобновление(
        сам,
        *,
        иной_адаптер: bool = False,
    ) -> tuple[
        Path,
        Path,
        Path,
        dict[str, object],
        str,
        str,
        str,
    ]:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        if иной_адаптер:
            изменённый = json.loads(реестр.read_text(encoding="utf-8"))
            изменённый["задания"][0]["адаптер"] = {
                "тип": "иной_адаптер",
                "контракт": "fum-иной-адаптер.1",
            }
            сам.записать_объект(реестр, изменённый)
            сам.выполнить_гит(корень, "add", "--", ".")
            сам.выполнить_гит(
                корень,
                "commit",
                "-m",
                "Выбрать иной тестовый адаптер",
            )
            выбор = сам.выбрать(корень, реестр, схема, наблюдения)
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "exact-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            идентификатор_задачи,
            точное_свидетельство=True,
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        сам.записать_точную_претензию(
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        return (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )

    def снимок_разрыва_потока(
        сам,
        идентификатор_задачи: str,
        *,
        состояние: str = "idle",
        идентификатор_хода: str = "turn-transport-failure-1",
        начало: int = 1_786_180_198,
        завершение: int = 1_786_195_962,
    ) -> dict[str, object]:
        снимок = json.loads(
            ФИКСТУРА_РАЗРЫВА_ПОТОКА.read_text(encoding="utf-8")
        )
        снимок["thread"]["id"] = идентификатор_задачи
        снимок["thread"]["status"] = {"type": состояние}
        снимок["turns"][0]["id"] = идентификатор_хода
        снимок["turns"][0]["startedAt"] = начало
        снимок["turns"][0]["completedAt"] = завершение
        снимок["turns"][0]["durationMs"] = (завершение - начало) * 1000
        снимок["thread"]["updatedAt"] = завершение
        return снимок

    def аргументы_возобновления(
        сам,
        корень: Path,
        реестр: Path,
        схема: Path,
        выбор: dict[str, object],
        попытка: str,
        идентификатор_задачи: str,
        поколение_очереди: str,
    ) -> list[str]:
        return [
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка)[2:],
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
        ]

    def закодировать_снимок_среды(сам, снимок: dict[str, object]) -> str:
        сырые = json.dumps(
            снимок,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
        return base64.b64encode(сырые).decode("ascii")

    def записать_квитанцию_сброса(
        сам,
        корень: Path,
        выбор: dict[str, object],
        ссылка_резервации: str,
        объект_резервации: str,
        идентификатор_задачи: str,
        поколение_очереди: str,
        исходный_объект_очереди: str,
        исходное_состояние_очереди: dict[str, object],
        квитанция_фикстуры: dict[str, object],
        *,
        включить_ограждение_претензии: bool,
        точная_претензия: bool = True,
        дополнительное_ограждение: dict[str, str] | None = None,
        целевая_вершина: str | None = None,
    ) -> str:
        каталог_версий = Path(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--absolute-git-dir",
            ).stdout.strip()
        ).resolve()
        идентичность = hashlib.sha256(
            os.path.normcase(str(каталог_версий)).encode("utf-8")
        ).hexdigest()
        ветка = str(выбор["branch_ref"])
        хэш_ветки = hashlib.sha256(ветка.encode("utf-8")).hexdigest()
        идентификатор_сброса = str(
            квитанция_фикстуры["идентификатор_сброса"]
        )
        завершено = str(квитанция_фикстуры["завершено"])
        идентификатор_диспетчера = str(
            квитанция_фикстуры["идентификатор_диспетчера"]
        )
        точная_целевая_вершина = (
            целевая_вершина
            if целевая_вершина is not None
            else str(выбор["selection_head"])
        )
        ограждения = [
            {
                "ссылка": ссылка_резервации,
                "объект": объект_резервации,
                "действие_при_завершении": "сохранить",
            }
        ]
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        if включить_ограждение_претензии:
            if точная_претензия:
                объект_претензии_до_освобождения = сам.выполнить_гит(
                    корень,
                    "rev-parse",
                    ссылка_претензии,
                ).stdout.strip()
            else:
                объект_претензии_до_освобождения = сам.выполнить_гит(
                    корень,
                    "hash-object",
                    "-w",
                    "--stdin",
                    вход="{}\n",
                ).stdout.strip()
            ограждения.append(
                {
                    "ссылка": ссылка_претензии,
                    "объект": объект_претензии_до_освобождения,
                    "действие_при_завершении": "сохранить",
                }
            )
        ссылка_журнала = (
            "refs/fum/worktree-task-completion-ledgers/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_журнала = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(objectname)",
            ссылка_журнала,
        ).stdout.strip()
        ограждения.append(
            {
                "ссылка": ссылка_журнала,
                "объект": объект_журнала or "absent",
                "действие_при_завершении": "сохранить",
            }
        )
        if дополнительное_ограждение is not None:
            ограждения.append(dict(дополнительное_ограждение))
        ограждения.sort(key=lambda элемент: str(элемент["ссылка"]))
        запись_сброса = {
            "схема": "fum.сброс-состояния-FIFO.1",
            "фаза": "очистка_рабочей_копии",
            "идентификатор_рабочей_копии": идентичность,
            "ссылка_ветки": ветка,
            "целевая_вершина": точная_целевая_вершина,
            "исходный_объект_очереди": исходный_объект_очереди,
            "исходное_состояние_очереди": исходное_состояние_очереди,
            "идентификатор_сброса": идентификатор_сброса,
            "идентификатор_диспетчера": идентификатор_диспетчера,
            "участники": [идентификатор_задачи],
            "связанные_задачи": [идентификатор_задачи],
            "неактивные_задачи": [идентификатор_задачи],
            "изменённые_пути_плана": [],
            "неотслеживаемые_пути_плана": [],
            "неотслеживаемые_объекты_плана": [],
            "отслеживаемые_объекты_плана": [],
            "отпечаток_индекса_плана": "sha256:" + "1" * 64,
            "отпечаток_изменений": "sha256:" + "0" * 64,
            "служебные_ограждения": ограждения,
            "создано": завершено,
            "обновлено": завершено,
        }
        объект_записи_сброса = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                запись_сброса,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        завершение_сброса = {
            "kind": "reset",
            "task_id": идентификатор_диспетчера,
            "generation": идентификатор_сброса,
            "head": точная_целевая_вершина,
            "completed_at": завершено,
            "аннулированные_задачи": [идентификатор_задачи],
        }
        объект_очереди_после = сам.записать_очередь(
            корень,
            ветка,
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
            завершение=завершение_сброса,
        )
        состояние_очереди_после = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_очереди_после,
            ).stdout
        )
        квитанция = {
            "схема": "fum.квитанция-сброса-состояния-FIFO.1",
            "идентификатор_рабочей_копии": идентичность,
            "ссылка_ветки": ветка,
            "идентификатор_сброса": идентификатор_сброса,
            "идентификатор_диспетчера": идентификатор_диспетчера,
            "целевая_вершина": точная_целевая_вершина,
            "объект_записи_сброса": объект_записи_сброса,
            "запись_сброса": запись_сброса,
            "исходный_объект_очереди": исходный_объект_очереди,
            "объект_очереди_после": объект_очереди_после,
            "состояние_очереди_после": состояние_очереди_после,
            "аннулированные_задачи": [идентификатор_задачи],
            "неактивные_задачи": [идентификатор_задачи],
            "предыдущее_завершение": исходное_состояние_очереди[
                "last_completion"
            ],
            "завершено": завершено,
        }
        объект_квитанции = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                квитанция,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        ссылка_квитанции = (
            "refs/fum/квитанции-сброса-состояния-FIFO/"
            f"{идентичность}/{хэш_ветки}/"
            f"{идентификатор_сброса.removeprefix('sha256:')}"
        )
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_квитанции,
            объект_квитанции,
        )
        return ссылка_претензии

    def проверить_допуск_после_сброса(
        сам,
        *,
        фаза_до_сброса: str,
        включить_ограждение_претензии: bool,
        ожидаемый_код: int,
        восстановить_претензию: bool = False,
        продвинуть_выбор: bool = True,
        привязать_запуск: bool = True,
        точное_свидетельство: bool = True,
        иной_адаптер: bool = False,
        аналитика_готова: bool = False,
        ожидаемый_код_терминала: int = 0,
        претензия_между_снимком_и_заменой: bool = False,
        журнал_между_снимком_и_заменой: bool = False,
        чужой_владелец_после_сброса: bool = False,
        чужое_завершение_после_сброса: bool = False,
        версия_претензии: int = 5,
    ) -> None:
        фикстура = json.loads(
            ФИКСТУРА_СОСТОЯНИЯ_ПОСЛЕ_СБРОСА.read_text(encoding="utf-8")
        )
        сам.assertEqual(
            set(фикстура),
            {
                "версия_схемы",
                "общая_резервация",
                "карточочная_претензия",
                "квитанция_сброса",
                "следующий_свободный_выбор",
            },
        )
        сам.assertEqual(фикстура["версия_схемы"], 1)
        сам.assertEqual(
            set(фикстура["общая_резервация"]),
            {
                "branch_ref",
                "generation",
                "job_id",
                "run_key",
                "selection_head",
                "spec_generation",
                "task_id",
                "trigger_occurrence",
                "идентификатор_попытки",
                "исход",
                "поколение_реестра",
                "состояние",
                "фаза",
            },
        )
        сам.assertEqual(
            фикстура["карточочная_претензия"],
            {"branch_ref": "refs/heads/master", "state": "unclaimed"},
        )
        сам.assertEqual(
            set(фикстура["квитанция_сброса"]),
            {
                "завершено",
                "идентификатор_диспетчера",
                "идентификатор_сброса",
                "карточочная_претензия_ограждена",
            },
        )
        сам.assertIs(
            фикстура["квитанция_сброса"][
                "карточочная_претензия_ограждена"
            ],
            True,
        )
        сам.assertEqual(
            set(фикстура["следующий_свободный_выбор"]),
            {"новая_вершина", "новое_наступление", "новый_ключ_запуска"},
        )
        сам.assertTrue(
            all(
                type(значение) is bool
                for значение in фикстура[
                    "следующий_свободный_выбор"
                ].values()
            )
        )
        идентификаторы = {
            str(фикстура["общая_резервация"]["идентификатор_попытки"]),
            str(фикстура["общая_резервация"]["task_id"]),
            str(фикстура["общая_резервация"]["generation"]),
            str(фикстура["квитанция_сброса"]["идентификатор_диспетчера"]),
            str(фикстура["квитанция_сброса"]["идентификатор_сброса"]),
        }
        сам.assertEqual(len(идентификаторы), 5)
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        if иной_адаптер:
            изменённый_реестр = json.loads(реестр.read_text(encoding="utf-8"))
            изменённый_реестр["задания"][0]["адаптер"] = {
                "тип": "иной_адаптер",
                "контракт": "fum-иной-адаптер.1",
            }
            сам.записать_объект(реестр, изменённый_реестр)
            сам.выполнить_гит(корень, "add", "--", ".")
            сам.выполнить_гит(
                корень,
                "commit",
                "-m",
                "Подменить адаптер фикстуры",
            )
            выбор = сам.выбрать(корень, реестр, схема, наблюдения)
        наблюдённая_резервация = фикстура["общая_резервация"]
        попытка = str(наблюдённая_резервация["идентификатор_попытки"])
        идентификатор_задачи = str(наблюдённая_резервация["task_id"])
        поколение_очереди = str(наблюдённая_резервация["generation"])
        if фаза_до_сброса == "задача_создана":
            сам.подготовить_создание(
                корень,
                реестр,
                схема,
                наблюдения,
                выбор,
                попытка,
                идентификатор_задачи,
                точное_свидетельство=точное_свидетельство,
            )
        elif фаза_до_сброса == "вызов_мог_состояться":
            общие = сам.аргументы_выбора(
                корень,
                реестр,
                схема,
                наблюдения,
                выбор,
            )
            резерв = сам.выполнить(
                корень,
                "зарезервировать",
                *общие,
                "--идентификатор-попытки",
                попытка,
                "--json",
            )
            сам.assertEqual(резерв.returncode, 0, резерв.stderr)
            сам.записать_претензию_до_вызова_среды(корень, выбор, попытка)
            граница = сам.выполнить(
                корень,
                "начать-вызов-среды",
                *общие,
                "--идентификатор-попытки",
                попытка,
                "--json",
            )
            сам.assertEqual(граница.returncode, 0, граница.stderr)
        else:
            сам.fail(f"Неизвестная фаза фикстуры: {фаза_до_сброса}")
        if привязать_запуск:
            привязка = сам.выполнить(
                корень,
                "bind-run",
                *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                "--task-id",
                идентификатор_задачи,
                "--json",
            )
            сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        объект_исходной_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        if привязать_запуск:
            проверка = сам.выполнить(
                корень,
                "verify-run",
                *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                "--task-id",
                идентификатор_задачи,
                "--generation",
                поколение_очереди,
                "--json",
            )
            сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        if версия_претензии == 4:
            ссылка_претензии_до_сброса, объект_претензии_до_сброса = (
                сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/worktree-next-step-claims",
                ).stdout.strip().split("\0")
            )
            сам.переписать_карточочную_претензию_в_схему_четыре(
                корень,
                ссылка_претензии_до_сброса,
                объект_претензии_до_сброса,
            )
        else:
            сам.assertEqual(версия_претензии, 5)
        исходное_состояние_очереди = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_исходной_очереди,
            ).stdout
        )
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации), 2)
        ссылка_резервации, объект_резервации = снимок_резервации
        ссылка_претензии = сам.записать_квитанцию_сброса(
            корень,
            выбор,
            ссылка_резервации,
            объект_резервации,
            идентификатор_задачи,
            поколение_очереди,
            объект_исходной_очереди,
            исходное_состояние_очереди,
            фикстура["квитанция_сброса"],
            включить_ограждение_претензии=(
                включить_ограждение_претензии
            ),
            точная_претензия=not иной_адаптер,
        )
        if чужой_владелец_после_сброса:
            сам.записать_очередь(
                корень,
                str(выбор["branch_ref"]),
                "чужая-задача",
                "чужое-поколение",
                str(выбор["selection_head"]),
            )
        elif чужое_завершение_после_сброса:
            сам.записать_очередь(
                корень,
                str(выбор["branch_ref"]),
                "чужая-задача",
                "чужое-поколение",
                str(выбор["selection_head"]),
                завершение={
                    "kind": "finished_clean",
                    "task_id": "чужая-задача",
                    "generation": "чужое-поколение",
                    "head": str(выбор["selection_head"]),
                    "completed_at": "2026-08-10T12:30:00+00:00",
                },
            )
        if журнал_между_снимком_и_заменой:
            ссылка_журнала = next(
                ограждение["ссылка"]
                for ограждение in json.loads(
                    сам.выполнить_гит(
                        корень,
                        "cat-file",
                        "blob",
                        сам.выполнить_гит(
                            корень,
                            "for-each-ref",
                            "--format=%(objectname)",
                            "refs/fum/квитанции-сброса-состояния-FIFO",
                        ).stdout.strip(),
                    ).stdout
                )["запись_сброса"]["служебные_ограждения"]
                if str(ограждение["ссылка"]).startswith(
                    "refs/fum/worktree-task-completion-ledgers/"
                )
            )
            объект_нового_журнала = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход="{}\n",
            ).stdout.strip()
            ссылка_резервации_до = сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(refname)%00%(objectname)",
                "refs/fum/резервации-запусков-автоматизаций",
            ).stdout.strip().split("\0")
            объект_претензии_до = сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip()
            эпоха_до = сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(refname)%00%(objectname)",
                "refs/fum/эпохи-резерваций-запусков-автоматизаций",
            ).stdout
            имя_модуля = f"_fum_dispatcher_ledger_race_{uuid.uuid4().hex}"
            спецификация = importlib.util.spec_from_file_location(имя_модуля, СЦЕНАРИЙ)
            сам.assertIsNotNone(спецификация)
            if спецификация is None or спецификация.loader is None:
                сам.fail("Не удалось загрузить диспетчер для гонки журнала")
            модуль = importlib.util.module_from_spec(спецификация)
            sys.modules[имя_модуля] = модуль
            сам.addCleanup(sys.modules.pop, имя_модуля, None)
            спецификация.loader.exec_module(модуль)
            исходная_замена = модуль.заменить_общее_ограждение_запуска
            журнал_вставлен = False

            def заменить_после_снимка_журна(
                *аргументы: object,
                **именованные: object,
            ) -> bool:
                nonlocal журнал_вставлен
                if not журнал_вставлен:
                    сам.выполнить_гит(корень, "update-ref", ссылка_журнала, объект_нового_журнала)
                    журнал_вставлен = True
                return bool(исходная_замена(*аргументы, **именованные))

            модуль.заменить_общее_ограждение_запуска = заменить_после_снимка_журна
            код, ответ = модуль.подтвердить_завершение_исполнителя(
                str(корень), str(выбор["branch_ref"]), str(выбор["selection_head"]), str(выбор["job_id"]), int(выбор["spec_generation"]), int(выбор["поколение_реестра"]), str(выбор["run_key"]), попытка, None,
            )
            сам.assertEqual(код, 5, ответ)
            сам.assertEqual(ответ["причина"], "completion_ledger_unverified")
            сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_резервации_до[0]).stdout.strip(), ссылка_резервации_до[1])
            сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip(), объект_претензии_до)
            сам.assertEqual(сам.выполнить_гит(корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/эпохи-резерваций-запусков-автоматизаций").stdout, эпоха_до)
            return
        if претензия_между_снимком_и_заменой:
            ссылка_квитанции, объект_квитанции = сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(refname)%00%(objectname)",
                "refs/fum/квитанции-сброса-состояния-FIFO",
            ).stdout.strip().split("\0")
            квитанция = json.loads(
                сам.выполнить_гит(
                    корень,
                    "cat-file",
                    "blob",
                    объект_квитанции,
                ).stdout
            )
            ограждение_претензии = next(
                ограждение
                for ограждение in квитанция["запись_сброса"][
                    "служебные_ограждения"
                ]
                if ограждение["ссылка"] == ссылка_претензии
            )
            объект_претензии = str(ограждение_претензии["объект"])
            объект_новой_претензии = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход="{}\n",
            ).stdout.strip()
            объект_резервации_до = сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_резервации,
            ).stdout.strip()
            эпоха_до = сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(refname)%00%(objectname)",
                "refs/fum/эпохи-резерваций-запусков-автоматизаций",
            ).stdout
            имя_модуля = f"_fum_dispatcher_reset_race_{uuid.uuid4().hex}"
            спецификация = importlib.util.spec_from_file_location(
                имя_модуля,
                СЦЕНАРИЙ,
            )
            сам.assertIsNotNone(спецификация)
            if спецификация is None or спецификация.loader is None:
                сам.fail("Не удалось загрузить диспетчер для проверки гонки")
            модуль = importlib.util.module_from_spec(спецификация)
            sys.modules[имя_модуля] = модуль
            сам.addCleanup(sys.modules.pop, имя_модуля, None)
            спецификация.loader.exec_module(модуль)
            исходная_замена = модуль.заменить_общее_ограждение_запуска
            претензия_вставлена = False

            def заменить_после_снимка(
                *аргументы: object,
                **именованные: object,
            ) -> bool:
                nonlocal претензия_вставлена
                if not претензия_вставлена:
                    сам.выполнить_гит(
                        корень,
                        "update-ref",
                        ссылка_претензии,
                        объект_новой_претензии,
                    )
                    претензия_вставлена = True
                return bool(исходная_замена(*аргументы, **именованные))

            модуль.заменить_общее_ограждение_запуска = заменить_после_снимка
            код, ответ = модуль.подтвердить_завершение_исполнителя(
                str(корень),
                str(выбор["branch_ref"]),
                str(выбор["selection_head"]),
                str(выбор["job_id"]),
                int(выбор["spec_generation"]),
                int(выбор["поколение_реестра"]),
                str(выбор["run_key"]),
                попытка,
                None,
            )
            сам.assertEqual(код, 5, ответ)
            сам.assertEqual(
                ответ["причина"],
                "next_step_clean_claim_unverified",
            )
            сам.assertEqual(
                сам.выполнить_гит(
                    корень,
                    "rev-parse",
                    ссылка_резервации,
                ).stdout.strip(),
                объект_резервации_до,
            )
            сам.assertEqual(
                сам.выполнить_гит(
                    корень,
                    "rev-parse",
                    ссылка_претензии,
                ).stdout.strip(),
                объект_новой_претензии,
            )
            сам.assertEqual(
                сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/эпохи-резерваций-запусков-автоматизаций",
                ).stdout,
                эпоха_до,
            )
            сам.assertTrue(ссылка_квитанции)
            return
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            ожидаемый_код_терминала,
            терминал.stdout + терминал.stderr,
        )
        if ожидаемый_код_терминала == 0:
            сам.assertEqual(
                json.loads(терминал.stdout)["исход"],
                (
                    "безопасный_отказ_до_эффекта"
                    if включить_ограждение_претензии and not иной_адаптер
                    else наблюдённая_резервация["исход"]
                ),
            )
            повтор = сам.выполнить(
                корень,
                "подтвердить-завершение-исполнителя",
                *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                "--json",
            )
            сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
            сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")
            if чужой_владелец_после_сброса or чужое_завершение_после_сброса:
                _, объект_текущей_очереди = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    ОБЛАСТЬ_ОЧЕРЕДИ,
                ).stdout.strip().split("\0")
                текущая_очередь = json.loads(сам.выполнить_гит(корень, "cat-file", "blob", объект_текущей_очереди).stdout)
                if чужой_владелец_после_сброса:
                    сам.assertEqual(текущая_очередь["owner"]["task_id"], "чужая-задача")
                else:
                    сам.assertEqual(текущая_очередь["last_completion"]["task_id"], "чужая-задача")
        if восстановить_претензию:
            объект_претензии = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход="{}\n",
            ).stdout.strip()
            сам.выполнить_гит(
                корень,
                "update-ref",
                ссылка_претензии,
                объект_претензии,
            )

        if аналитика_готова:
            новые_наблюдения = json.loads(
                наблюдения.read_text(encoding="utf-8")
            )
            новые_наблюдения["подтверждённые_события"] = {
                "завершение_runtime_ready_commit_handoff": 5,
            }
            сам.записать_объект(наблюдения, новые_наблюдения)
            сам.выполнить_гит(корень, "add", "--", ".")
            сам.выполнить_гит(
                корень,
                "commit",
                "-m",
                "Сделать аналитику готовой после сброса",
            )
            новый_выбор = сам.выбрать(корень, реестр, схема, наблюдения)
            сам.assertEqual(
                новый_выбор["job_id"],
                "master.completed-step-analysis",
            )
        elif продвинуть_выбор:
            новые_наблюдения = json.loads(
                наблюдения.read_text(encoding="utf-8")
            )
            новые_наблюдения["момент"] = "2026-08-05T12:10:00Z"
            сам.записать_объект(наблюдения, новые_наблюдения)
            сам.выполнить_гит(корень, "add", "--", ".")
            сам.выполнить_гит(
                корень,
                "commit",
                "-m",
                "Продвинуть свободный тик после сброса",
            )
            новый_выбор = сам.выбрать(корень, реестр, схема, наблюдения)
            сам.assertNotEqual(
                новый_выбор["selection_head"],
                выбор["selection_head"],
            )
            сам.assertNotEqual(
                новый_выбор["trigger_occurrence"],
                выбор["trigger_occurrence"],
            )
            сам.assertNotEqual(новый_выбор["run_key"], выбор["run_key"])
        else:
            новый_выбор = выбор

        новая_попытка = сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(
                корень,
                реестр,
                схема,
                наблюдения,
                новый_выбор,
            ),
            "--идентификатор-попытки",
            str(uuid.uuid4()),
            "--json",
        )

        сам.assertEqual(
            новая_попытка.returncode,
            ожидаемый_код,
            новая_попытка.stdout + новая_попытка.stderr,
        )
        если_допущено = json.loads(новая_попытка.stdout)
        if ожидаемый_код == 0:
            сам.assertEqual(если_допущено["владение"], "новое")
        else:
            сам.assertEqual(
                если_допущено["состояние"],
                "уже_зарезервировано",
            )

    def test_подтверждённый_сброс_разрешает_новую_свободную_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
        )

    def test_сброс_в_фазе_вызова_тоже_разрешает_новую_свободную_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="вызов_мог_состояться",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
        )

    def test_подтверждённый_сброс_точной_схемы_четыре_освобождает_новую_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
            версия_претензии=4,
        )

    def test_подмена_схемы_четыре_после_снимка_сброса_закрывает_терминализацию(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=5,
            ожидаемый_код_терминала=5,
            претензия_между_снимком_и_заменой=True,
            версия_претензии=4,
        )

    def test_квитанция_без_ограждения_претензии_не_разрешает_новую_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=False,
            ожидаемый_код=4,
            ожидаемый_код_терминала=5,
        )

    def test_старая_претензия_после_отката_не_разрешает_новую_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=4,
            восстановить_претензию=True,
        )

    def test_то_же_наступление_после_точного_освобождения_допускает_новую_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
            продвинуть_выбор=False,
        )

    def test_точное_освобождение_следующего_шага_не_блокирует_готовую_аналитику(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
            аналитика_готова=True,
        )

    def test_новая_претензия_между_снимком_и_заменой_блокирует_восстановление(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=5,
            претензия_между_снимком_и_заменой=True,
        )

    def test_журнал_между_снимком_и_заменой_блокирует_безопасный_отказ(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=4,
            журнал_между_снимком_и_заменой=True,
        )

    def test_чужой_владелец_после_сброса_не_блокирует_безопасный_отказ(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
            чужой_владелец_после_сброса=True,
        )

    def test_чужое_завершение_после_сброса_не_скрывает_квитанцию(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
            чужое_завершение_после_сброса=True,
        )

    def test_точная_задача_среды_до_привязки_разрешает_новую_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=0,
            привязать_запуск=False,
        )

    def test_предварительная_задача_до_привязки_не_разрешает_новую_попытку(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=4,
            привязать_запуск=False,
            точное_свидетельство=False,
            ожидаемый_код_терминала=5,
        )

    def test_квитанция_следующего_шага_не_разрешает_иной_адаптер(
        сам,
    ) -> None:
        сам.проверить_допуск_после_сброса(
            фаза_до_сброса="задача_создана",
            включить_ограждение_претензии=True,
            ожидаемый_код=4,
            иной_адаптер=True,
            ожидаемый_код_терминала=5,
        )

    def test_граница_среды_требует_точную_претензию_живого_адаптера(
        сам,
    ) -> None:
        for аналитика in (False, True):
            with сам.subTest(аналитика=аналитика):
                корень, реестр, схема, наблюдения, выбор, попытка = (
                    сам.подготовить_резервацию_живого_адаптера(аналитика)
                )
                резервация_до = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/резервации-запусков-автоматизаций",
                ).stdout
                эпоха_до = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/эпохи-резерваций-запусков-автоматизаций",
                ).stdout
                граница = сам.выполнить(
                    корень,
                    "начать-вызов-среды",
                    *сам.аргументы_выбора(
                        корень,
                        реестр,
                        схема,
                        наблюдения,
                        выбор,
                    ),
                    "--идентификатор-попытки",
                    попытка,
                    "--json",
                )
                сам.assertEqual(
                    граница.returncode,
                    5,
                    граница.stdout + граница.stderr,
                )
                сам.assertEqual(
                    json.loads(граница.stdout)["причина"],
                    "adapter_claim_missing",
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(refname)%00%(objectname)",
                        "refs/fum/резервации-запусков-автоматизаций",
                    ).stdout,
                    резервация_до,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(refname)%00%(objectname)",
                        "refs/fum/эпохи-резерваций-запусков-автоматизаций",
                    ).stdout,
                    эпоха_до,
                )

    def test_удаление_претензии_между_снимком_и_границей_среды_закрыто(
        сам,
    ) -> None:
        for аналитика in (False, True):
            with сам.subTest(аналитика=аналитика):
                корень, реестр, схема, наблюдения, выбор, попытка = (
                    сам.подготовить_резервацию_живого_адаптера(аналитика)
                )
                ссылка_претензии, объект_претензии = (
                    сам.записать_претензию_до_вызова_среды(корень, выбор, попытка)
                )
                ссылка_резервации, объект_резервации = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/резервации-запусков-автоматизаций",
                ).stdout.strip().split("\0")
                эпоха_до = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/эпохи-резерваций-запусков-автоматизаций",
                ).stdout
                имя_модуля = f"_fum_dispatcher_host_boundary_{uuid.uuid4().hex}"
                спецификация = importlib.util.spec_from_file_location(имя_модуля, СЦЕНАРИЙ)
                сам.assertIsNotNone(спецификация)
                if спецификация is None or спецификация.loader is None:
                    сам.fail("Не удалось загрузить диспетчер")
                модуль = importlib.util.module_from_spec(спецификация)
                sys.modules[имя_модуля] = модуль
                сам.addCleanup(sys.modules.pop, имя_модуля, None)
                спецификация.loader.exec_module(модуль)
                исходная_замена = модуль.заменить_резервацию_перед_вызовом_среды
                претензия_удалена = False

                def заменить_после_снимка(
                    *аргументы: object,
                    **именованные: object,
                ) -> bool:
                    nonlocal претензия_удалена
                    if not претензия_удалена:
                        сам.выполнить_гит(
                            корень,
                            "update-ref",
                            "-d",
                            ссылка_претензии,
                            объект_претензии,
                        )
                        претензия_удалена = True
                    return bool(исходная_замена(*аргументы, **именованные))

                модуль.заменить_резервацию_перед_вызовом_среды = заменить_после_снимка
                код, ответ = модуль.начать_вызов_среды(
                    str(корень),
                    str(реестр),
                    str(схема),
                    str(наблюдения),
                    str(выбор["job_id"]),
                    int(выбор["spec_generation"]),
                    int(выбор["поколение_реестра"]),
                    str(выбор["run_key"]),
                    попытка,
                )
                сам.assertEqual(код, 5, ответ)
                сам.assertEqual(ответ["причина"], "adapter_claim_changed")
                сам.assertEqual(
                    сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip(),
                    объект_резервации,
                )
                сам.assertEqual(
                    сам.выполнить_гит(корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/эпохи-резерваций-запусков-автоматизаций").stdout,
                    эпоха_до,
                )

    def test_завершённый_сброс_закрывает_устаревшую_границу_среды(
        сам,
    ) -> None:
        for аналитика in (False, True):
            with сам.subTest(аналитика=аналитика):
                корень, реестр, схема, наблюдения, выбор, попытка = (
                    сам.подготовить_резервацию_живого_адаптера(аналитика)
                )
                ссылка_претензии, _ = сам.записать_претензию_до_вызова_среды(
                    корень,
                    выбор,
                    попытка,
                )
                ссылка_резервации, объект_резервации = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/резервации-запусков-автоматизаций",
                ).stdout.strip().split("\0")
                эпоха_до = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    "refs/fum/эпохи-резерваций-запусков-автоматизаций",
                ).stdout
                идентификатор_диспетчера = "dispatcher-reset-before-host"
                среда = dict(os.environ)
                среда["CODEX_THREAD_ID"] = идентификатор_диспетчера
                сам.записать_пустую_очередь_цепочки(
                    корень,
                    str(выбор["branch_ref"]),
                )
                план_процесса = сам.выполнить_очередь(
                    корень,
                    "план-сброса",
                    "--repo-root",
                    str(корень),
                    "--идентификатор-диспетчера",
                    идентификатор_диспетчера,
                    "--json",
                    среда=среда,
                )
                сам.assertEqual(план_процесса.returncode, 0, план_процесса.stdout + план_процесса.stderr)
                план = json.loads(план_процесса.stdout)
                подготовка = сам.выполнить_очередь(
                    корень,
                    "подготовить-сброс",
                    "--repo-root",
                    str(корень),
                    "--идентификатор-диспетчера",
                    идентификатор_диспетчера,
                    "--ожидаемая-вершина",
                    str(план["целевая_вершина"]),
                    "--ожидаемый-объект-очереди",
                    str(план["объект_очереди"]),
                    "--подтверждение",
                    str(план["подтверждение"]),
                    "--json",
                    среда=среда,
                )
                сам.assertEqual(подготовка.returncode, 0, подготовка.stdout + подготовка.stderr)
                подготовлено = json.loads(подготовка.stdout)
                аргументы_неактивных = [
                    аргумент
                    for задача in план["участники"]
                    for аргумент in ("--неактивная-задача", str(задача))
                ]
                остановка = сам.выполнить_очередь(
                    корень,
                    "подтвердить-остановку-сессий",
                    "--repo-root",
                    str(корень),
                    "--идентификатор-диспетчера",
                    идентификатор_диспетчера,
                    "--идентификатор-сброса",
                    str(подготовлено["идентификатор_сброса"]),
                    *аргументы_неактивных,
                    "--json",
                    среда=среда,
                )
                сам.assertEqual(остановка.returncode, 0, остановка.stdout + остановка.stderr)
                сброс = сам.выполнить_очередь(
                    корень,
                    "применить-сброс",
                    "--repo-root",
                    str(корень),
                    "--идентификатор-диспетчера",
                    идентификатор_диспетчера,
                    "--идентификатор-сброса",
                    str(подготовлено["идентификатор_сброса"]),
                    "--json",
                    среда=среда,
                )
                сам.assertEqual(сброс.returncode, 0, сброс.stdout + сброс.stderr)
                сам.assertEqual(
                    сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).returncode,
                    0,
                )
                if not аналитика:
                    ссылка_квитанции, объект_квитанции = сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(refname)%00%(objectname)",
                        "refs/fum/квитанции-сброса-состояния-FIFO",
                    ).stdout.strip().split("\0")
                    квитанция = json.loads(
                        сам.выполнить_гит(
                            корень,
                            "cat-file",
                            "blob",
                            объект_квитанции,
                        ).stdout
                    )
                    имя_модуля = f"_fum_dispatcher_chain_receipt_{uuid.uuid4().hex}"
                    спецификация = importlib.util.spec_from_file_location(
                        имя_модуля,
                        СЦЕНАРИЙ,
                    )
                    сам.assertIsNotNone(спецификация)
                    if спецификация is None or спецификация.loader is None:
                        сам.fail("Не удалось загрузить диспетчер для проверки цепочки")
                    модуль = importlib.util.module_from_spec(спецификация)
                    sys.modules[имя_модуля] = модуль
                    сам.addCleanup(sys.modules.pop, имя_модуля, None)
                    спецификация.loader.exec_module(модуль)
                    суффикс = ссылка_квитанции.rsplit("/", 1)[1]
                    модуль.проверить_квитанцию_сброса(
                        корень,
                        str(выбор["branch_ref"]),
                        квитанция,
                        суффикс,
                    )

                    лишнее_поле = json.loads(json.dumps(квитанция))
                    лишнее_поле["запись_сброса"]["исходное_состояние_очереди"]["текущая_цепочка"]["лишнее"] = True
                    чужая_ветка = json.loads(json.dumps(квитанция))
                    чужая_ветка["запись_сброса"]["исходное_состояние_очереди"]["текущая_цепочка"]["ветка"] = "refs/heads/other"
                    несогласованная_цепочка = json.loads(json.dumps(квитанция))
                    несогласованная_цепочка["состояние_очереди_после"]["текущая_цепочка"]["хэш"] = "sha256:" + "2" * 64
                    for название, искажённая in (
                        ("лишнее_поле", лишнее_поле),
                        ("чужая_ветка", чужая_ветка),
                        ("несогласованная_цепочка", несогласованная_цепочка),
                    ):
                        искажённая["объект_записи_сброса"] = сам.выполнить_гит(
                            корень,
                            "hash-object",
                            "--stdin",
                            вход=json.dumps(
                                искажённая["запись_сброса"],
                                ensure_ascii=False,
                                sort_keys=True,
                                separators=(",", ":"),
                            )
                            + "\n",
                        ).stdout.strip()
                        искажённая["объект_очереди_после"] = сам.выполнить_гит(
                            корень,
                            "hash-object",
                            "--stdin",
                            вход=json.dumps(
                                искажённая["состояние_очереди_после"],
                                ensure_ascii=False,
                                sort_keys=True,
                                separators=(",", ":"),
                            )
                            + "\n",
                        ).stdout.strip()
                        with сам.subTest(искажение=название):
                            with сам.assertRaises(модуль.ОшибкаКонтракта):
                                модуль.проверить_квитанцию_сброса(
                                    корень,
                                    str(выбор["branch_ref"]),
                                    искажённая,
                                    суффикс,
                                )
                граница = сам.выполнить(
                    корень,
                    "начать-вызов-среды",
                    *сам.аргументы_выбора(корень, реестр, схема, наблюдения, выбор),
                    "--идентификатор-попытки",
                    попытка,
                    "--json",
                )
                сам.assertEqual(
                    граница.returncode,
                    5,
                    граница.stdout + граница.stderr,
                )
                сам.assertEqual(json.loads(граница.stdout)["причина"], "reservation_reset_observed")
                сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip(), объект_резервации)
                сам.assertEqual(сам.выполнить_гит(корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/эпохи-резерваций-запусков-автоматизаций").stdout, эпоха_до)

    def test_канонический_реестр_содержит_два_активных_адаптера(
        сам,
    ) -> None:
        реестр = json.loads(КАНОНИЧЕСКИЙ_РЕЕСТР.read_text(encoding="utf-8"))

        сам.assertEqual(реестр["поколение_реестра"], 3)
        сам.assertEqual(len(реестр["задания"]), 2)
        задание = реестр["задания"][0]
        сам.assertEqual(задание["job_id"], "master.next-step")
        сам.assertEqual(задание["состояние"], "active")
        сам.assertEqual(
            задание["адаптер"],
            {
                "тип": "следующий_шаг_ветки",
                "контракт": "fum-sleduyusjhij-shag-vetki.1",
            },
        )
        сам.assertEqual(
            задание["цель"],
            {
                "branch_ref": "refs/heads/master",
                "якорь_рабочей_копии": ".",
                "идентификатор_проекта": "FUM",
                "путь_проекта": "README.md",
            },
        )
        сам.assertEqual(задание["триггер"]["интервал_секунды"], 300)
        наблюдения = {
            условие["наблюдение"] for условие in задание["условия_допуска"]
        }
        сам.assertIn("codex_свободен_первая_проверка", наблюдения)
        сам.assertIn("codex_свободен_вторая_проверка", наблюдения)
        сериализация = json.dumps(задание, ensure_ascii=False)
        сам.assertNotIn("criteria", сериализация)
        сам.assertNotIn("task", сериализация)
        аналитическое = реестр["задания"][1]
        сам.assertEqual(аналитическое["job_id"], "master.completed-step-analysis")
        сам.assertEqual(аналитическое["состояние"], "active")
        сам.assertEqual(
            аналитическое["адаптер"],
            {
                "тип": "аналитика_завершённых_шагов",
                "контракт": "fum-analitika-zavershyonnyikh-shagov.1",
            },
        )
        сам.assertNotIn("card_id", сериализация)

    def test_общий_выбор_возвращает_маршрут_адаптера_и_точную_вершину(сам) -> None:
        корень, _реестр, _схема, _наблюдения, выбор = сам.создать_репозиторий()

        сам.assertEqual(выбор["состояние"], "выбрано")
        сам.assertEqual(
            выбор["адаптер"],
            {
                "тип": "следующий_шаг_ветки",
                "контракт": "fum-sleduyusjhij-shag-vetki.1",
            },
        )
        сам.assertEqual(выбор["цель"]["branch_ref"], "refs/heads/master")
        сам.assertEqual(
            выбор["selection_head"],
            сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip(),
        )

    def test_общий_тик_принимает_однострочные_наблюдения_без_временного_файла(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор_из_файла = (
            сам.создать_репозиторий()
        )
        текст_наблюдений = json.dumps(
            json.loads(наблюдения.read_text(encoding="utf-8")),
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )

        результат = сам.выполнить(
            корень,
            "выбрать",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            "--наблюдения-json",
            текст_наблюдений,
            "--json",
        )

        сам.assertEqual(результат.returncode, 0, результат.stderr)
        выбор_из_строки = json.loads(результат.stdout)
        сам.assertEqual(выбор_из_строки, выбор_из_файла)

    def test_фактическая_задача_отделена_от_клиентской_подготовки(сам) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            "client-preparation-id",
        )

        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            "actual-root-task",
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        сам.assertEqual(json.loads(привязка.stdout)["состояние"], "bound")
        чужая = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            "other-root-task",
            "--json",
        )
        сам.assertEqual(чужая.returncode, 5, чужая.stdout)
        сам.assertNotIn("client-preparation-id", чужая.stdout)

    def test_точный_идентификатор_задачи_среды_не_позволяет_привязать_другую_задачу(сам) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            "actual-root-task",
            точное_свидетельство=True,
        )

        чужая = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            "other-root-task",
            "--json",
        )
        точная = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            "actual-root-task",
            "--json",
        )

        сам.assertEqual(чужая.returncode, 5, чужая.stdout)
        сам.assertEqual(точная.returncode, 0, точная.stderr)
        сам.assertEqual(json.loads(точная.stdout)["состояние"], "bound")

    def test_повтор_точного_подтверждения_мигрирует_долговечную_резервацию_схемы_два(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        общие = сам.аргументы_выбора(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
        )
        резерв = сам.выполнить(
            корень,
            "зарезервировать",
            *общие,
            "--идентификатор-попытки",
            попытка,
            "--json",
        )
        сам.assertEqual(резерв.returncode, 0, резерв.stderr)
        сам.записать_претензию_до_вызова_среды(корень, выбор, попытка)
        граница = сам.выполнить(
            корень,
            "начать-вызов-среды",
            *общие,
            "--идентификатор-попытки",
            попытка,
            "--json",
        )
        сам.assertEqual(граница.returncode, 0, граница.stderr)
        ссылка = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)",
            "refs/fum/резервации-запусков-автоматизаций/",
        ).stdout.strip()
        резервация = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                ссылка,
            ).stdout
        )
        резервация["версия_схемы"] = 2
        резервация.pop("свидетельство_среды")
        резервация["фаза"] = "задача_создана"
        резервация["идентификатор_созданной_задачи"] = "actual-root-task"
        объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                резервация,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка, объект)

        противоречивая = dict(резервация)
        противоречивая["task_id"] = "other-root-task"
        противоречивая["generation"] = "other-generation"
        противоречивый_объект = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                противоречивая,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка,
            противоречивый_объект,
            объект,
        )
        противоречивое_подтверждение = сам.выполнить(
            корень,
            "подтвердить-создание",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--thread-id",
            "actual-root-task",
            "--host-id",
            "local",
            "--json",
        )
        сам.assertEqual(
            противоречивое_подтверждение.returncode,
            2,
            противоречивое_подтверждение.stdout
            + противоречивое_подтверждение.stderr,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка,
            ).stdout.strip(),
            противоречивый_объект,
        )
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка,
            объект,
            противоречивый_объект,
        )

        подтверждение = сам.выполнить(
            корень,
            "подтвердить-создание",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--thread-id",
            "actual-root-task",
            "--host-id",
            "local",
            "--json",
        )

        сам.assertEqual(
            подтверждение.returncode,
            0,
            подтверждение.stdout + подтверждение.stderr,
        )
        мигрированная = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                ссылка,
            ).stdout
        )
        сам.assertEqual(мигрированная["версия_схемы"], 3)
        сам.assertEqual(
            мигрированная["свидетельство_среды"],
            {
                "вид": "threadId",
                "threadId": "actual-root-task",
                "hostId": "local",
            },
        )

    def test_проверка_запуска_сверяет_владельца_поколение_и_вершину(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "actual-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            "client-preparation-id",
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )

        неверное_поколение = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            "wrong-generation",
            "--json",
        )
        сам.assertEqual(неверное_поколение.returncode, 5, неверное_поколение.stdout)
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        сам.assertEqual(json.loads(проверка.stdout)["состояние"], "verified")

    def test_аналитическое_завершение_без_специальной_претензии_закрыто(
        сам,
    ) -> None:
        корень, выбор, попытка, _, _ = (
            сам.подготовить_аналитическое_завершение()
        )
        снимок_претензии = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            ОБЛАСТЬ_АНАЛИТИЧЕСКИХ_ПРЕТЕНЗИЙ,
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_претензии), 2)
        сам.выполнить_гит(
            корень,
            "update-ref",
            "-d",
            снимок_претензии[0],
            снимок_претензии[1],
        )
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(терминал.returncode, 5, терминал.stdout)
        сам.assertEqual(
            json.loads(терминал.stdout)["причина"],
            "analytic_claim_missing",
        )
        состояние = сам.выполнить(
            корень,
            "состояние-резервации",
            "--корень-рабочей-копии",
            str(корень),
            "--expected-branch-ref",
            str(выбор["branch_ref"]),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--json",
        )
        сам.assertEqual(состояние.returncode, 0, состояние.stderr)
        сам.assertNotEqual(json.loads(состояние.stdout)["фаза"], "завершён")

    def test_журнал_доказывает_следующий_шаг_после_поздней_передачи(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            завершивший_коммит,
            поздняя_вершина,
            ссылка_претензии,
            _,
        ) = сам.подготовить_завершение_следующего_шага_с_журналом()
        исторический_сценарий = (
            корень
            / "Инструменты"
            / "fum-sleduyusjhij-shag-vetki"
            / "scripts"
            / "branch-next-step.py"
        )
        исторический_сценарий.write_text(
            "это невалидный dirty текст\n",
            encoding="utf-8",
        )
        среда = dict(os.environ)
        среда["GIT_DIR"] = str(корень / "нет-такого-git-dir")
        среда["GIT_WORK_TREE"] = str(корень / "иная-рабочая-копия")
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
            среда=среда,
        )
        сам.assertEqual(терминал.returncode, 0, терминал.stdout + терминал.stderr)
        сам.assertEqual(json.loads(терминал.stdout)["владение"], "новое")
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip(), поздняя_вершина)
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip()
        резервация = json.loads(сам.выполнить_гит(корень, "cat-file", "blob", снимок_резервации).stdout)
        сам.assertEqual(резервация["подтверждение_результата"], завершивший_коммит)
        повтор = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
        сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")
        реестр, схема, наблюдения, новый_выбор = (
            сам.продвинуть_выбор_после_успеха(
                корень,
                "master.next-step",
            )
        )
        новая_попытка = str(uuid.uuid4())
        новый_резерв = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            новый_выбор,
            новая_попытка,
        )
        сам.assertEqual(
            новый_резерв.returncode,
            0,
            новый_резерв.stdout + новый_резерв.stderr,
        )
        сам.проверить_отсутствие_ссылки(корень, ссылка_претензии)

    def test_чистое_завершение_следующего_шага_переживает_позднюю_передачу(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            вершина_чистого_завершения,
            поздняя_вершина,
        ) = сам.подготовить_чистое_завершение_следующего_шага_с_поздней_передачей()
        ссылка_претензии, _ = сам.служебная_основа_ветки(корень, str(выбор["branch_ref"]))
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{ссылка_претензии}/{hashlib.sha256(str(выбор['branch_ref']).encode('utf-8')).hexdigest()}"
        )
        чужой_допуск = сам.выполнить_очередь(
            корень,
            "join",
            "--repo-root",
            str(корень),
            "--task-id",
            "foreign-owner-after-clean",
            "--json",
        )
        сам.assertEqual(чужой_допуск.returncode, 0, чужой_допуск.stdout + чужой_допуск.stderr)
        ссылка_очереди, объект_очереди_до = сам.выполнить_гит(
            корень, "for-each-ref", "--format=%(refname)%00%(objectname)", ОБЛАСТЬ_ОЧЕРЕДИ
        ).stdout.strip().split("\0")

        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )

        сам.assertEqual(терминал.returncode, 0, терминал.stdout + терминал.stderr)
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "безопасный_отказ_до_эффекта")
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip(), поздняя_вершина)
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_очереди).stdout.strip(), объект_очереди_до)
        сам.assertEqual(сам.выполнить_гит(корень, "for-each-ref", "--format=%(objectname)", ссылка_претензии).stdout, "")
        снимок_резервации = сам.выполнить_гит(
            корень, "for-each-ref", "--format=%(objectname)", "refs/fum/резервации-запусков-автоматизаций"
        ).stdout.strip()
        резервация = json.loads(сам.выполнить_гит(корень, "cat-file", "blob", снимок_резервации).stdout)
        сам.assertEqual(резервация["task_id"], идентификатор_задачи)
        сам.assertEqual(резервация["generation"], поколение_очереди)
        сам.assertEqual(резервация["подтверждение_результата"], вершина_чистого_завершения)
        повтор = сам.выполнить(
            корень, "подтвердить-завершение-исполнителя", *сам.аргументы_ограждения_запуска(корень, выбор, попытка), "--json",
        )
        сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
        сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")
        повтор_очереди = сам.выполнить_очередь(
            корень, "finish-clean", "--repo-root", str(корень), "--task-id", идентификатор_задачи,
            "--generation", поколение_очереди, "--json",
        )
        сам.assertEqual(повтор_очереди.returncode, 0, повтор_очереди.stdout + повтор_очереди.stderr)
        сам.assertEqual(json.loads(повтор_очереди.stdout)["state"], "finished_clean")

    def test_чистое_завершение_следующего_шага_переживает_штатный_сброс(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            вершина_чистого_завершения,
            _,
        ) = сам.подготовить_чистое_завершение_следующего_шага_с_поздней_передачей()
        идентичность, хэш_ветки = сам.служебная_основа_ветки(
            корень,
            str(выбор["branch_ref"]),
        )
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()

        сам.выполнить_штатный_сброс(
            корень,
            "dispatcher-reset-after-next-step-clean",
        )

        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip(),
            объект_претензии,
        )
        чужой_допуск = сам.выполнить_очередь(
            корень,
            "join",
            "--repo-root",
            str(корень),
            "--task-id",
            "foreign-owner-after-clean-reset",
            "--json",
        )
        сам.assertEqual(
            чужой_допуск.returncode,
            0,
            чужой_допуск.stdout + чужой_допуск.stderr,
        )
        ссылка_очереди, объект_очереди_до = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            ОБЛАСТЬ_ОЧЕРЕДИ,
        ).stdout.strip().split("\0")
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        сам.assertEqual(
            json.loads(терминал.stdout)["исход"],
            "безопасный_отказ_до_эффекта",
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_очереди,
            ).stdout.strip(),
            объект_очереди_до,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(objectname)",
                ссылка_претензии,
            ).stdout,
            "",
        )
        повтор_общего = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            повтор_общего.returncode,
            0,
            повтор_общего.stdout + повтор_общего.stderr,
        )
        сам.assertEqual(
            json.loads(повтор_общего.stdout)["владение"],
            "существующее",
        )
        повтор_очереди = сам.выполнить_очередь(
            корень,
            "finish-clean",
            "--repo-root",
            str(корень),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(
            повтор_очереди.returncode,
            0,
            повтор_очереди.stdout + повтор_очереди.stderr,
        )
        ответ_очереди = json.loads(повтор_очереди.stdout)
        сам.assertEqual(ответ_очереди["state"], "finished_clean")
        сам.assertEqual(ответ_очереди["task_id"], идентификатор_задачи)
        сам.assertEqual(ответ_очереди["generation"], поколение_очереди)
        сам.assertEqual(ответ_очереди["head"], вершина_чистого_завершения)

    def test_перезарядка_схемы_четыре_доводит_претензию_до_общего_завершения(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            _,
            _,
            _,
            _,
        ) = сам.подготовить_чистое_завершение_следующего_шага_с_поздней_передачей(
            добавить_позднюю_передачу=False,
            версия_претензии_до_перезарядки=4,
        )
        идентичность, хэш_ветки = сам.служебная_основа_ветки(
            корень,
            str(выбор["branch_ref"]),
        )
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()
        претензия = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_претензии,
            ).stdout
        )
        сам.assertEqual(претензия["schema_version"], 6)

        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )

        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        сам.assertEqual(
            json.loads(терминал.stdout)["исход"],
            "безопасный_отказ_до_эффекта",
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(objectname)",
                ссылка_претензии,
            ).stdout,
            "",
        )

    def test_сброс_после_перезарядки_сохраняет_доказательство_до_общего_отказа(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            _,
            _,
            _,
            _,
        ) = сам.подготовить_чистое_завершение_следующего_шага_с_поздней_передачей(
            добавить_позднюю_передачу=False,
            выполнить_чистое_завершение=False,
        )
        идентичность, хэш_ветки = сам.служебная_основа_ветки(
            корень,
            str(выбор["branch_ref"]),
        )
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()

        сам.выполнить_штатный_сброс(
            корень,
            "dispatcher-reset-after-rearm",
        )

        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip(),
            объект_претензии,
        )
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        сам.assertEqual(
            json.loads(терминал.stdout)["исход"],
            "безопасный_отказ_до_эффекта",
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(objectname)",
                ссылка_претензии,
            ).stdout,
            "",
        )
        повтор_общего = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            повтор_общего.returncode,
            0,
            повтор_общего.stdout + повтор_общего.stderr,
        )
        сам.assertEqual(
            json.loads(повтор_общего.stdout)["владение"],
            "существующее",
        )

    def test_чистая_претензия_не_переиспользуется_мутациями_адаптера_или_коммитом(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            _,
            _,
        ) = сам.подготовить_чистое_завершение_следующего_шага_с_поздней_передачей(
            добавить_позднюю_передачу=False,
        )
        идентичность, хэш_ветки = сам.служебная_основа_ветки(
            корень,
            str(выбор["branch_ref"]),
        )
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()
        претензия = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_претензии,
            ).stdout
        )
        общая_идентичность = (
            "--expected-branch-ref",
            str(претензия["branch_ref"]),
            "--expected-step-id",
            str(претензия["step_id"]),
            "--expected-selection-id",
            str(претензия["selection_id"]),
        )
        команды = (
            (
                "bind-run",
                *общая_идентичность,
                "--expected-lease-id",
                попытка,
                "--task-id",
                идентификатор_задачи,
            ),
            (
                "verify-run",
                *общая_идентичность,
                "--expected-lease-id",
                попытка,
                "--task-id",
                идентификатор_задачи,
                "--generation",
                поколение_очереди,
            ),
            (
                "release",
                "--branch-ref",
                str(претензия["branch_ref"]),
                "--expected-lease-id",
                попытка,
            ),
        )
        for команда in команды:
            with сам.subTest(команда=команда[0]):
                результат = сам.выполнить_следующий_шаг(
                    корень,
                    *команда,
                    "--repo-root",
                    str(корень),
                    "--json",
                )
                сам.assertNotEqual(
                    результат.returncode,
                    0,
                    результат.stdout + результат.stderr,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "rev-parse",
                        ссылка_претензии,
                    ).stdout.strip(),
                    объект_претензии,
                )

        ссылка_очереди, объект_очереди = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            ОБЛАСТЬ_ОЧЕРЕДИ,
        ).stdout.strip().split("\0")
        вершина_до = сам.выполнить_гит(
            корень,
            "rev-parse",
            "HEAD",
        ).stdout.strip()
        (корень / "не-должно-коммититься.txt").write_text(
            "изменение после чистого завершения\n",
            encoding="utf-8",
        )
        сам.выполнить_гит(
            корень,
            "add",
            "--",
            "не-должно-коммититься.txt",
        )
        коммит = сам.выполнить_очередь(
            корень,
            "commit",
            "--repo-root",
            str(корень),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--message",
            "Не переиспользовать чисто завершённую задачу",
            "--json",
        )
        сам.assertNotEqual(
            коммит.returncode,
            0,
            коммит.stdout + коммит.stderr,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "HEAD",
            ).stdout.strip(),
            вершина_до,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_очереди,
            ).stdout.strip(),
            объект_очереди,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip(),
            объект_претензии,
        )

    def test_чистое_завершение_следующего_шага_отвергает_несовпадающие_ограждения(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            _,
            _,
            _,
            _,
        ) = сам.подготовить_чистое_завершение_следующего_шага_с_поздней_передачей()
        идентичность, хэш_ветки = сам.служебная_основа_ветки(
            корень,
            str(выбор["branch_ref"]),
        )
        ссылка_претензии = (
            "refs/fum/worktree-next-step-claims/"
            f"{идентичность}/{хэш_ветки}"
        )
        ссылка_резервации, объект_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()
        претензия = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_претензии,
            ).stdout
        )

        def записать_канонический_объект(значение: dict[str, object]) -> str:
            return сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход=json.dumps(
                    значение,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                )
                + "\n",
            ).stdout.strip()

        изменения = {
            "step_id": lambda значение: значение.__setitem__(
                "step_id",
                "master-fum-step-9999-automatic-v5",
            ),
            "card_id": lambda значение: значение.__setitem__(
                "card_id",
                "FUM-STEP-9999",
            ),
            "lease_id": lambda значение: значение.__setitem__(
                "lease_id",
                str(uuid.uuid4()),
            ),
            "task_id": lambda значение: значение.__setitem__(
                "task_id",
                "wrong-clean-task",
            ),
            "generation": lambda значение: значение.__setitem__(
                "generation",
                str(uuid.uuid4()),
            ),
            "selection_head": lambda значение: значение.__setitem__(
                "selection_head",
                "0" * len(str(значение["selection_head"])),
            ),
            "base_head": lambda значение: dict(
                значение["свидетельство_чистого_завершения"]
            ).__setitem__(
                "base_head",
                "0" * len(str(значение["selection_head"])),
            ),
        }
        for поле, изменить in изменения.items():
            with сам.subTest(поле=поле):
                изменённая = json.loads(json.dumps(претензия))
                if поле == "base_head":
                    свидетельство = dict(
                        изменённая["свидетельство_чистого_завершения"]
                    )
                    свидетельство["base_head"] = "0" * len(
                        str(изменённая["selection_head"])
                    )
                    изменённая["свидетельство_чистого_завершения"] = свидетельство
                else:
                    изменить(изменённая)
                изменённый_объект = записать_канонический_объект(изменённая)
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка_претензии,
                    изменённый_объект,
                    объект_претензии,
                )
                отказ = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(
                        корень,
                        выбор,
                        попытка,
                    ),
                    "--json",
                )
                сам.assertEqual(
                    отказ.returncode,
                    5,
                    отказ.stdout + отказ.stderr,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "rev-parse",
                        ссылка_резервации,
                    ).stdout.strip(),
                    объект_резервации,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "rev-parse",
                        ссылка_претензии,
                    ).stdout.strip(),
                    изменённый_объект,
                )
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка_претензии,
                    объект_претензии,
                    изменённый_объект,
                )

        резервация = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_резервации,
            ).stdout
        )
        резервация["generation"] = str(uuid.uuid4())
        изменённая_резервация = записать_канонический_объект(резервация)
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_резервации,
            изменённая_резервация,
            объект_резервации,
        )
        отказ_резервации = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            отказ_резервации.returncode,
            5,
            отказ_резервации.stdout + отказ_резервации.stderr,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_резервации,
            ).stdout.strip(),
            изменённая_резервация,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip(),
            объект_претензии,
        )

    def test_журнал_и_сохранённая_претензия_доказывают_успех_после_сброса(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            завершивший_коммит,
            _,
            ссылка_претензии,
            _,
        ) = сам.подготовить_завершение_следующего_шага_с_журналом()
        объект_претензии = сам.выполнить_гит(
            корень, "rev-parse", ссылка_претензии
        ).stdout.strip()
        идентификатор_диспетчера = "dispatcher-reset-task"
        среда = dict(os.environ)
        среда["CODEX_THREAD_ID"] = идентификатор_диспетчера
        план_процесса = сам.выполнить_очередь(
            корень,
            "план-сброса",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--json",
            среда=среда,
        )
        сам.assertEqual(план_процесса.returncode, 0, план_процесса.stdout + план_процесса.stderr)
        план = json.loads(план_процесса.stdout)
        подготовка = сам.выполнить_очередь(
            корень,
            "подготовить-сброс",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--ожидаемая-вершина",
            str(план["целевая_вершина"]),
            "--ожидаемый-объект-очереди",
            str(план["объект_очереди"]),
            "--подтверждение",
            str(план["подтверждение"]),
            "--json",
            среда=среда,
        )
        сам.assertEqual(подготовка.returncode, 0, подготовка.stdout + подготовка.stderr)
        подготовлено = json.loads(подготовка.stdout)
        аргументы_неактивных = [
            аргумент
            for задача in план["участники"]
            for аргумент in ("--неактивная-задача", str(задача))
        ]
        остановка = сам.выполнить_очередь(
            корень,
            "подтвердить-остановку-сессий",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            *аргументы_неактивных,
            "--json",
            среда=среда,
        )
        сам.assertEqual(остановка.returncode, 0, остановка.stdout + остановка.stderr)
        сброс = сам.выполнить_очередь(
            корень,
            "применить-сброс",
            "--repo-root",
            str(корень),
            "--идентификатор-диспетчера",
            идентификатор_диспетчера,
            "--идентификатор-сброса",
            str(подготовлено["идентификатор_сброса"]),
            "--json",
            среда=среда,
        )
        сам.assertEqual(сброс.returncode, 0, сброс.stdout + сброс.stderr)
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip(), объект_претензии)
        ссылка_очереди, объект_очереди_после_сброса = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            ОБЛАСТЬ_ОЧЕРЕДИ,
        ).stdout.strip().split("\0")
        очередь_после_сброса = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_очереди_после_сброса,
            ).stdout
        )
        очередь_после_сброса["next_seq"] = int(
            очередь_после_сброса["next_seq"]
        ) + 1
        очередь_после_сброса["updated_at"] = "2026-08-10T12:00:00+00:00"
        изменённый_объект_очереди = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                очередь_после_сброса,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_очереди,
            изменённый_объект_очереди,
            объект_очереди_после_сброса,
        )
        снимок_резервации_до = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации_до), 2)
        ссылка_резервации, объект_резервации_до = снимок_резервации_до
        ссылка_квитанции, объект_квитанции = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/квитанции-сброса-состояния-FIFO",
        ).stdout.strip().split("\0")
        повреждённый_объект = сам.выполнить_гит(
            корень, "hash-object", "-w", "--stdin", вход="{}\n"
        ).stdout.strip()
        for ссылка_подмены, объект_до in (
            (ссылка_претензии, объект_претензии),
            (ссылка_квитанции, объект_квитанции),
        ):
            with сам.subTest(ссылка=ссылка_подмены):
                сам.выполнить_гит(корень, "update-ref", ссылка_подмены, повреждённый_объект, объект_до)
                отказ = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                    "--json",
                )
                сам.assertEqual(отказ.returncode, 5, отказ.stdout + отказ.stderr)
                сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip(), объект_резервации_до)
                сам.выполнить_гит(корень, "update-ref", ссылка_подмены, объект_до, повреждённый_объект)
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(терминал.returncode, 0, терминал.stdout + терминал.stderr)
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")
        снимок_резервации = сам.выполнить_гит(
            корень, "for-each-ref", "--format=%(objectname)", "refs/fum/резервации-запусков-автоматизаций"
        ).stdout.strip()
        резервация = json.loads(сам.выполнить_гит(корень, "cat-file", "blob", снимок_резервации).stdout)
        сам.assertEqual(резервация["подтверждение_результата"], завершивший_коммит)
        повтор = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
        сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")

    def test_журнал_следующего_шага_закрывает_подмену_и_повреждение(
        сам,
    ) -> None:
        for случай in (
            "selection_id",
            "неканонический_журнал",
            "неканонический_журнал_после_сброса",
            "символический_журнал",
            "дублирующее_событие",
            "несовпадающая_карточка",
        ):
            with сам.subTest(случай=случай):
                (
                    корень,
                    выбор,
                    попытка,
                    _,
                    поздняя_вершина,
                    ссылка_претензии,
                    ссылка_журнала,
                ) = сам.подготовить_завершение_следующего_шага_с_журналом()

                def прочитать_по_ссылке(ссылка: str) -> dict[str, object]:
                    объект = сам.выполнить_гит(корень, "rev-parse", ссылка).stdout.strip()
                    return json.loads(сам.выполнить_гит(корень, "cat-file", "blob", объект).stdout)

                def записать_по_ссылке(
                    ссылка: str,
                    значение: dict[str, object],
                    *,
                    канонический: bool = True,
                ) -> None:
                    объект = сам.выполнить_гит(
                        корень,
                        "hash-object",
                        "-w",
                        "--stdin",
                        вход=json.dumps(
                            значение,
                            ensure_ascii=False,
                            sort_keys=True,
                            separators=(",", ":") if канонический else None,
                            indent=None if канонический else 2,
                        )
                        + "\n",
                    ).stdout.strip()
                    сам.выполнить_гит(корень, "update-ref", ссылка, объект)

                if случай == "selection_id":
                    претензия = прочитать_по_ссылке(ссылка_претензии)
                    претензия["selection_id"] = "sha256:" + "9" * 64
                    записать_по_ссылке(ссылка_претензии, претензия)
                elif случай == "символический_журнал":
                    сам.выполнить_гит(корень, "update-ref", "-d", ссылка_журнала)
                    сам.выполнить_гит(корень, "symbolic-ref", ссылка_журнала, ссылка_претензии)
                else:
                    журнал = прочитать_по_ссылке(ссылка_журнала)
                    if случай in {
                        "неканонический_журнал",
                        "неканонический_журнал_после_сброса",
                    }:
                        записать_по_ссылке(ссылка_журнала, журнал, канонический=False)
                    else:
                        событие = dict(журнал["события"][0])
                        if случай == "дублирующее_событие":
                            событие["номер"] = 2
                            событие["завершивший_commit"] = поздняя_вершина
                        else:
                            событие["card_id"] = "FUM-STEP-9999"
                        основа = {
                            ключ: событие[ключ]
                            for ключ in (
                                "branch_ref",
                                "step_id",
                                "card_id",
                                "завершивший_commit",
                                "результат",
                            )
                        }
                        событие["идентификатор"] = "sha256:" + hashlib.sha256(
                            json.dumps(основа, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
                        ).hexdigest()
                        if случай == "дублирующее_событие":
                            журнал["события"].append(событие)
                            журнал["число_событий"] = 2
                        else:
                            журнал["события"] = [событие]
                        записать_по_ссылке(ссылка_журнала, журнал)
                if случай == "неканонический_журнал_после_сброса":
                    сам.записать_очередь(
                        корень,
                        str(выбор["branch_ref"]),
                        "discarded-task",
                        "discarded-generation",
                        поздняя_вершина,
                        завершение={
                            "kind": "reset",
                            "task_id": "dispatcher-task",
                            "generation": "reset-generation",
                            "head": поздняя_вершина,
                            "completed_at": "2026-08-09T10:00:00+00:00",
                            "аннулированные_задачи": ["discarded-task"],
                        },
                    )
                служебные_ссылки_до = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)%00%(symref)",
                    "refs/fum",
                ).stdout
                терминал = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                    "--json",
                )
                сам.assertEqual(терминал.returncode, 5, терминал.stdout + терминал.stderr)
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(refname)%00%(objectname)%00%(symref)",
                        "refs/fum",
                    ).stdout,
                    служебные_ссылки_до,
                )

    def test_аналитическая_терминализация_требует_точную_завершённую_претензию(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_аналитическое_завершение()
        вершина_результата = сам.выполнить_гит(
            корень,
            "rev-parse",
            "HEAD",
        ).stdout.strip()
        несовпадения = (
            ("фаза", "подтверждена"),
            ("branch_ref", "refs/heads/other"),
            ("selection_head", "0" * 40),
            ("job_id", "master.other-analysis"),
            ("spec_generation", int(выбор["spec_generation"]) + 1),
            ("поколение_реестра", int(выбор["поколение_реестра"]) + 1),
            ("trigger_occurrence", {"тип": "иной"}),
            ("run_key", "sha256:" + "3" * 64),
            ("идентификатор_попытки", str(uuid.uuid4())),
            ("lease_id", str(uuid.uuid4())),
            ("task_id", "other-task"),
            ("generation", "other-generation"),
            ("подтверждённый_результат.commit", "4" * 40),
        )
        for поле, значение in несовпадения:
            with сам.subTest(поле=поле):
                сам.записать_аналитическую_претензию(
                    корень,
                    выбор,
                    попытка,
                    идентификатор_задачи,
                    поколение_очереди,
                    вершина_результата,
                    фаза=(str(значение) if поле == "фаза" else "завершена"),
                    изменение=(поле, значение) if поле != "фаза" else None,
                )
                терминал = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                    "--json",
                )
                сам.assertEqual(терминал.returncode, 5, терминал.stdout)
                сам.assertEqual(
                    json.loads(терминал.stdout)["причина"],
                    "analytic_claim_unverified",
                )
        сам.записать_аналитическую_претензию(
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            вершина_результата,
            канонический=False,
        )
        неканонический = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(неканонический.returncode, 5, неканонический.stdout)
        сам.assertEqual(
            json.loads(неканонический.stdout)["причина"],
            "analytic_claim_unverified",
        )
        (корень / "поздний-результат.txt").write_text("позднее\n", encoding="utf-8")
        сам.выполнить_гит(корень, "add", "--", "поздний-результат.txt")
        сам.выполнить_гит(корень, "commit", "-m", "Завершить позднюю задачу")
        поздняя_вершина = сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip()
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            "later-root-task",
            "later-generation",
            вершина_результата,
            завершение={
                "kind": "committed",
                "task_id": "later-root-task",
                "generation": "later-generation",
                "base_head": вершина_результата,
                "head": поздняя_вершина,
                "completed_at": "2026-08-05T12:07:00+00:00",
            },
        )
        сам.записать_аналитическую_претензию(
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            вершина_результата,
        )
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")

    def test_общий_аналитический_успех_ограждён_от_сброса_и_не_голодает_за_чужим_владельцем(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_аналитическое_завершение()
        вершина_результата = сам.выполнить_гит(
            корень, "rev-parse", "HEAD"
        ).stdout.strip()
        (корень / "поздний-независимый-результат.txt").write_text(
            "позднее\n", encoding="utf-8"
        )
        сам.выполнить_гит(корень, "add", "--", "поздний-независимый-результат.txt")
        сам.выполнить_гит(корень, "commit", "-m", "Завершить независимую задачу")
        текущая_вершина = сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip()
        обычный_объект_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            "later-root-task",
            "later-generation",
            вершина_результата,
            завершение={
                "kind": "committed",
                "task_id": "later-root-task",
                "generation": "later-generation",
                "base_head": вершина_результата,
                "head": текущая_вершина,
                "completed_at": "2026-08-05T12:09:00+00:00",
            },
        )
        ссылка_претензии, _ = сам.записать_аналитическую_претензию(
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
            вершина_результата,
        )
        ссылка_очереди = сам.выполнить_гит(
            корень, "for-each-ref", "--format=%(refname)", ОБЛАСТЬ_ОЧЕРЕДИ
        ).stdout.strip()
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации), 2)
        ссылка_резервации, объект_резервации = снимок_резервации
        объект_претензии = сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip()
        объект_маркера_сброса = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход='{"\u0441\u0445\u0435\u043c\u0430":"fum.\u0441\u0431\u0440\u043e\u0441-\u0441\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u044f-FIFO.1"}\n',
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка_очереди, объект_маркера_сброса, обычный_объект_очереди)
        во_время_сброса = сам.выполнить(корень, "подтвердить-завершение-исполнителя", *сам.аргументы_ограждения_запуска(корень, выбор, попытка), "--json")
        сам.assertEqual(во_время_сброса.returncode, 5, во_время_сброса.stdout)
        сам.assertEqual(json.loads(во_время_сброса.stdout)["причина"], "reset_in_progress")
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip(), объект_резервации)
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip(), объект_претензии)
        сам.выполнить_гит(корень, "update-ref", ссылка_очереди, обычный_объект_очереди, объект_маркера_сброса)
        сам.записать_очередь(корень, str(выбор["branch_ref"]), "unrelated-active-task", "unrelated-active-generation", текущая_вершина)
        терминал = сам.выполнить(корень, "подтвердить-завершение-исполнителя", *сам.аргументы_ограждения_запуска(корень, выбор, попытка), "--json")
        сам.assertEqual(терминал.returncode, 0, терминал.stdout + терминал.stderr)
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")

    def test_поздняя_передача_очереди_не_может_удалить_отчёт_или_откатить_курсор_до_общего_успеха(
        сам,
    ) -> None:
        for случай in ("удалить_отчёт", "откатить_курсор"):
            with сам.subTest(случай=случай):
                (
                    корень,
                    выбор,
                    попытка,
                    идентификатор_задачи,
                    поколение_очереди,
                ) = сам.подготовить_аналитическое_завершение()
                вершина_результата = сам.выполнить_гит(
                    корень,
                    "rev-parse",
                    "HEAD",
                ).stdout.strip()
                сам.записать_аналитическую_претензию(
                    корень,
                    выбор,
                    попытка,
                    идентификатор_задачи,
                    поколение_очереди,
                    вершина_результата,
                )
                if случай == "удалить_отчёт":
                    отчёты = list(
                        (корень / "Оценки" / "аналитика-завершённых-запусков").rglob("*.md")
                    )
                    сам.assertEqual(len(отчёты), 1)
                    отчёты[0].unlink()
                else:
                    (корень / "реестр.json").write_text(
                        сам.выполнить_гит(
                            корень,
                            "show",
                            f"{выбор['selection_head']}:реестр.json",
                        ).stdout,
                        encoding="utf-8",
                    )
                сам.выполнить_гит(корень, "add", "-A", "--", ".")
                сам.выполнить_гит(
                    корень,
                    "commit",
                    "-m",
                    "Изменить аналитические пути поздней задачей",
                )
                терминал = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                    "--json",
                )
                сам.assertEqual(терминал.returncode, 5, терминал.stdout)
                сам.assertEqual(
                    json.loads(терминал.stdout)["причина"],
                    "analytic_result_changed",
                )

    def test_аналитический_сброс_до_передачи_атомарно_освобождает_порог(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            ссылка_претензии,
            _,
            _,
            _,
        ) = сам.подготовить_аналитический_сброс("подтверждена")
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(терминал.returncode, 0, терминал.stdout)
        сам.assertEqual(
            json.loads(терминал.stdout)["исход"],
            "безопасный_отказ_до_эффекта",
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(objectname)",
                ссылка_претензии,
            ).stdout,
            "",
        )

    def test_аналитический_сброс_до_привязки_и_проверки_доказан_квитанцией_среды(
        сам,
    ) -> None:
        for фаза in ("зарезервирована", "привязана"):
            with сам.subTest(фаза=фаза):
                (
                    корень,
                    выбор,
                    попытка,
                    ссылка_претензии,
                    _,
                    _,
                    _,
                ) = сам.подготовить_аналитический_сброс(фаза)
                терминал = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
                    "--json",
                )
                сам.assertEqual(терминал.returncode, 0, терминал.stdout)
                сам.assertEqual(
                    json.loads(терминал.stdout)["исход"],
                    "безопасный_отказ_до_эффекта",
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(objectname)",
                        ссылка_претензии,
                    ).stdout,
                    "",
                )

    def test_аналитическое_чистое_завершение_сохраняется_после_поздней_передачи(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_аналитическое_завершение()
        исходная_вершина = str(выбор["selection_head"])
        реестр = корень / "реестр.json"
        реестр.write_text(
            сам.выполнить_гит(корень, "show", f"{исходная_вершина}:реестр.json").stdout,
            encoding="utf-8",
        )
        каталог_отчётов = корень / "Оценки" / "аналитика-завершённых-запусков"
        for отчёт in каталог_отчётов.rglob("*.md"):
            отчёт.unlink()
        сам.выполнить_гит(корень, "add", "-A", "--", ".")
        сам.выполнить_гит(корень, "commit", "-m", "Продвинуть ветку до допуска аналитики")
        вершина_чистого_завершения = сам.выполнить_гит(корень, "rev-parse", "HEAD").stdout.strip()
        ссылка_претензии, _ = сам.записать_аналитическую_претензию(
            корень, выбор, попытка, идентификатор_задачи, поколение_очереди,
            вершина_чистого_завершения, фаза="зарезервирована",
        )
        снимок_резервации = сам.выполнить_гит(
            корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/резервации-запусков-автоматизаций"
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации), 2)
        ссылка_резервации, объект_резервации = снимок_резервации
        резервация = json.loads(сам.выполнить_гит(корень, "cat-file", "blob", объект_резервации).stdout)
        резервация["generation"] = None
        новый_объект_резервации = сам.выполнить_гит(
            корень, "hash-object", "-w", "--stdin",
            вход=json.dumps(резервация, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n",
        ).stdout.strip()
        сам.выполнить_гит(корень, "update-ref", ссылка_резервации, новый_объект_резервации, объект_резервации)
        сам.записать_очередь(корень, str(выбор["branch_ref"]), идентификатор_задачи, поколение_очереди, вершина_чистого_завершения)
        чисто = сам.выполнить_очередь(
            корень, "finish-clean", "--repo-root", str(корень), "--task-id", идентификатор_задачи, "--generation", поколение_очереди, "--json",
        )
        сам.assertEqual(чисто.returncode, 0, чисто.stdout + чисто.stderr)
        ссылка_очереди, обычный_объект_очереди = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            ОБЛАСТЬ_ОЧЕРЕДИ,
        ).stdout.strip().split("\0")
        объект_маркера_сброса = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                {"схема": "fum.сброс-состояния-FIFO.1"},
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ) + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_очереди,
            объект_маркера_сброса,
            обычный_объект_очереди,
        )
        резервация_до_сброса = сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip()
        претензия_до_сброса = сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip()
        во_время_сброса = сам.выполнить(корень, "подтвердить-завершение-исполнителя", *сам.аргументы_ограждения_запуска(корень, выбор, попытка), "--json")
        сам.assertEqual(во_время_сброса.returncode, 5, во_время_сброса.stdout)
        сам.assertEqual(json.loads(во_время_сброса.stdout)["причина"], "reset_in_progress")
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip(), резервация_до_сброса)
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_претензии).stdout.strip(), претензия_до_сброса)
        сам.выполнить_гит(корень, "update-ref", ссылка_очереди, обычный_объект_очереди, объект_маркера_сброса)
        поздняя_задача = "later-ordinary-task"
        допуск = сам.выполнить_очередь(корень, "join", "--repo-root", str(корень), "--task-id", поздняя_задача, "--json")
        сам.assertEqual(допуск.returncode, 0, допуск.stderr)
        поколение_поздней = str(json.loads(допуск.stdout)["generation"])
        ( корень / "README.md").write_text("# FUM\n\nПоздняя задача.\n", encoding="utf-8")
        сам.выполнить_гит(корень, "add", "--", "README.md")
        поздний_коммит = сам.выполнить_очередь(корень, "commit", "--repo-root", str(корень), "--task-id", поздняя_задача, "--generation", поколение_поздней, "--message", "Завершить позднюю задачу", "--json")
        сам.assertEqual(поздний_коммит.returncode, 0, поздний_коммит.stderr)
        терминал = сам.выполнить(корень, "подтвердить-завершение-исполнителя", *сам.аргументы_ограждения_запуска(корень, выбор, попытка), "--json")
        сам.assertEqual(терминал.returncode, 0, терминал.stdout + терминал.stderr)
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "безопасный_отказ_до_эффекта")
        сам.assertEqual(сам.выполнить_гит(корень, "for-each-ref", "--format=%(objectname)", ссылка_претензии).stdout, "")
        повтор_чистого_завершения_очереди = сам.выполнить_очередь(корень, "finish-clean", "--repo-root", str(корень), "--task-id", идентификатор_задачи, "--generation", поколение_очереди, "--json")
        сам.assertEqual(повтор_чистого_завершения_очереди.returncode, 0, повтор_чистого_завершения_очереди.stdout + повтор_чистого_завершения_очереди.stderr)
        повтор_общего = сам.выполнить(корень, "подтвердить-завершение-исполнителя", *сам.аргументы_ограждения_запуска(корень, выбор, попытка), "--json")
        сам.assertEqual(повтор_общего.returncode, 0, повтор_общего.stdout)
        сам.assertEqual(json.loads(повтор_общего.stdout)["владение"], "существующее")
        свежий_выбор = сам.выбрать(
            корень,
            корень / "реестр.json",
            корень / "схема.json",
            корень / "наблюдения.json",
        )
        сам.assertEqual(свежий_выбор["job_id"], "master.completed-step-analysis")
        сам.assertEqual(свежий_выбор["trigger_occurrence"], выбор["trigger_occurrence"])
        свежая_резервация = сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(
                корень,
                корень / "реестр.json",
                корень / "схема.json",
                корень / "наблюдения.json",
                свежий_выбор,
            ),
            "--идентификатор-попытки",
            str(uuid.uuid4()),
            "--json",
        )
        сам.assertEqual(свежая_резервация.returncode, 0, свежая_резервация.stdout + свежая_резервация.stderr)
        сам.assertEqual(json.loads(свежая_резервация.stdout)["владение"], "новое")

    def test_новая_общая_резервация_требует_отсутствия_своей_претензии(
        сам,
    ) -> None:
        for задание in (
            "master.next-step",
            "master.completed-step-analysis",
        ):
            with сам.subTest(задание=задание):
                корень, реестр, схема, наблюдения, выбор = (
                    сам.создать_репозиторий()
                )
                if задание == "master.completed-step-analysis":
                    значение = json.loads(
                        наблюдения.read_text(encoding="utf-8")
                    )
                    значение["подтверждённые_события"] = {
                        "завершение_runtime_ready_commit_handoff": 5,
                    }
                    сам.записать_объект(наблюдения, значение)
                    сам.выполнить_гит(
                        корень, "add", "--", "наблюдения.json"
                    )
                    сам.выполнить_гит(
                        корень,
                        "commit",
                        "-m",
                        "Открыть аналитическую резервацию",
                    )
                    выбор = сам.выбрать(
                        корень, реестр, схема, наблюдения
                    )
                сам.assertEqual(выбор["job_id"], задание)
                попытка = str(uuid.uuid4())
                if задание == "master.next-step":
                    ссылка_претензии, объект_претензии = (
                        сам.записать_точную_претензию(
                            корень,
                            выбор,
                            попытка,
                            None,
                            None,
                        )
                    )
                else:
                    ссылка_претензии, объект_претензии = (
                        сам.записать_аналитическую_претензию(
                            корень,
                            выбор,
                            попытка,
                            "unused-task",
                            "unused-generation",
                            str(выбор["selection_head"]),
                            фаза="зарезервирована",
                        )
                    )
                резерв = сам.резервировать_новый_запуск(
                    корень,
                    реестр,
                    схема,
                    наблюдения,
                    выбор,
                    попытка,
                )
                сам.assertNotEqual(
                    резерв.returncode,
                    0,
                    резерв.stdout + резерв.stderr,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень, "rev-parse", ссылка_претензии
                    ).stdout.strip(),
                    объект_претензии,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(refname)",
                        "refs/fum/резервации-запусков-автоматизаций",
                    ).stdout,
                    "",
                )

    def test_поздняя_претензия_закрывает_атомарную_замену_новой_общей_резервации(
        сам,
    ) -> None:
        for задание in (
            "master.next-step",
            "master.completed-step-analysis",
        ):
            with сам.subTest(задание=задание):
                корень, реестр, схема, наблюдения, выбор = (
                    сам.создать_репозиторий()
                )
                if задание == "master.completed-step-analysis":
                    значение = json.loads(
                        наблюдения.read_text(encoding="utf-8")
                    )
                    значение["подтверждённые_события"] = {
                        "завершение_runtime_ready_commit_handoff": 5,
                    }
                    сам.записать_объект(наблюдения, значение)
                    сам.выполнить_гит(
                        корень, "add", "--", "наблюдения.json"
                    )
                    сам.выполнить_гит(
                        корень,
                        "commit",
                        "-m",
                        "Открыть аналитическую гонку",
                    )
                    выбор = сам.выбрать(
                        корень, реестр, схема, наблюдения
                    )
                сам.assertEqual(выбор["job_id"], задание)
                попытка = str(uuid.uuid4())
                if задание == "master.next-step":
                    ссылка_претензии, объект_претензии = (
                        сам.записать_точную_претензию(
                            корень,
                            выбор,
                            попытка,
                            None,
                            None,
                        )
                    )
                else:
                    ссылка_претензии, объект_претензии = (
                        сам.записать_аналитическую_претензию(
                            корень,
                            выбор,
                            попытка,
                            "unused-task",
                            "unused-generation",
                            str(выбор["selection_head"]),
                            фаза="зарезервирована",
                        )
                    )
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    "-d",
                    ссылка_претензии,
                    объект_претензии,
                )
                имя_модуля = (
                    "fum_dispatcher_late_claim_"
                    + задание.replace(".", "_").replace("-", "_")
                )
                спецификация = importlib.util.spec_from_file_location(
                    имя_модуля,
                    СЦЕНАРИЙ,
                )
                if спецификация is None or спецификация.loader is None:
                    сам.fail("Не удалось загрузить диспетчер для гонки")
                модуль = importlib.util.module_from_spec(спецификация)
                sys.modules[имя_модуля] = модуль
                сам.addCleanup(sys.modules.pop, имя_модуля, None)
                спецификация.loader.exec_module(модуль)
                исходная_замена = модуль.заменить_резервацию_сравнением
                претензия_вставлена = False

                def заменить_после_снимка(
                    *аргументы: object,
                    **именованные: object,
                ) -> bool:
                    nonlocal претензия_вставлена
                    if not претензия_вставлена:
                        сам.выполнить_гит(
                            корень,
                            "update-ref",
                            ссылка_претензии,
                            объект_претензии,
                        )
                        претензия_вставлена = True
                    return bool(
                        исходная_замена(*аргументы, **именованные)
                    )

                модуль.заменить_резервацию_сравнением = (
                    заменить_после_снимка
                )
                код, ответ = модуль.зарезервировать_запуск(
                    str(корень),
                    str(реестр),
                    str(схема),
                    str(наблюдения),
                    str(выбор["job_id"]),
                    int(выбор["spec_generation"]),
                    int(выбор["поколение_реестра"]),
                    str(выбор["run_key"]),
                    попытка,
                )
                сам.assertNotEqual(код, 0, ответ)
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень, "rev-parse", ссылка_претензии
                    ).stdout.strip(),
                    объект_претензии,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "for-each-ref",
                        "--format=%(refname)",
                        "refs/fum/резервации-запусков-автоматизаций",
                    ).stdout,
                    "",
                )

    def test_подмена_терминальной_претензии_между_чтением_и_атомарной_заменой_не_заменяет_резервацию(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            _,
            _,
            ссылка_претензии,
            _,
        ) = сам.подготовить_завершение_следующего_шага_с_журналом()
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        исходный_объект_претензии = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка_претензии,
        ).stdout.strip()
        претензия = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                исходный_объект_претензии,
            ).stdout
        )
        претензия["generation"] = "late-replay-generation"
        поздний_объект_претензии = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                претензия,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        реестр, схема, наблюдения, новый_выбор = (
            сам.продвинуть_выбор_после_успеха(
                корень,
                "master.next-step",
            )
        )
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации), 2)
        ссылка_резервации, объект_резервации = снимок_резервации
        эпоха_до = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/эпохи-резерваций-запусков-автоматизаций",
        ).stdout
        имя_модуля = "fum_dispatcher_terminal_claim_race"
        спецификация = importlib.util.spec_from_file_location(
            имя_модуля,
            СЦЕНАРИЙ,
        )
        if спецификация is None or спецификация.loader is None:
            сам.fail("Не удалось загрузить диспетчер терминальной гонки")
        модуль = importlib.util.module_from_spec(спецификация)
        sys.modules[имя_модуля] = модуль
        сам.addCleanup(sys.modules.pop, имя_модуля, None)
        спецификация.loader.exec_module(модуль)
        исходная_замена = модуль.заменить_резервацию_сравнением
        претензия_подменена = False

        def заменить_после_чтения(
            *аргументы: object,
            **именованные: object,
        ) -> bool:
            nonlocal претензия_подменена
            if not претензия_подменена:
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка_претензии,
                    поздний_объект_претензии,
                    исходный_объект_претензии,
                )
                претензия_подменена = True
            return bool(исходная_замена(*аргументы, **именованные))

        модуль.заменить_резервацию_сравнением = заменить_после_чтения
        код, ответ = модуль.зарезервировать_запуск(
            str(корень),
            str(реестр),
            str(схема),
            str(наблюдения),
            str(новый_выбор["job_id"]),
            int(новый_выбор["spec_generation"]),
            int(новый_выбор["поколение_реестра"]),
            str(новый_выбор["run_key"]),
            str(uuid.uuid4()),
        )
        сам.assertNotEqual(код, 0, ответ)
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_резервации,
            ).stdout.strip(),
            объект_резервации,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_претензии,
            ).stdout.strip(),
            поздний_объект_претензии,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(refname)%00%(objectname)",
                "refs/fum/эпохи-резерваций-запусков-автоматизаций",
            ).stdout,
            эпоха_до,
        )

    def test_аналитическая_резервация_без_претензии_освобождается_только_после_подтверждения_отсутствия_претензии(
        сам,
    ) -> None:
        корень, реестр, схема, _, выбор, попытка = (
            сам.подготовить_аналитическую_резервацию_до_среды()
        )
        без_доказательства = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(корень, выбор, попытка),
        )
        сам.assertEqual(без_доказательства.returncode, 5, без_доказательства.stdout)
        сам.assertEqual(
            json.loads(без_доказательства.stdout)["причина"],
            "adapter_recovery_required",
        )
        сам.выполнить_гит(
            корень,
            "commit",
            "--allow-empty",
            "-m",
            "Продвинуть ветку до общего освобождения",
        )
        освобождение = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(
                корень,
                выбор,
                попытка,
                "unclaimed",
            ),
        )
        сам.assertEqual(освобождение.returncode, 0, освобождение.stdout + освобождение.stderr)
        сам.assertEqual(json.loads(освобождение.stdout)["владение"], "новое")
        повтор = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(
                корень,
                выбор,
                попытка,
                "unclaimed",
            ),
        )
        сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
        сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")
        поздняя_претензия = сам.выполнить_аналитику(
            корень,
            *сам.аргументы_аналитической_претензии(
                корень,
                реестр,
                схема,
                выбор,
                попытка,
            ),
        )
        сам.assertNotEqual(поздняя_претензия.returncode, 0, поздняя_претензия.stdout)
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(objectname)",
                ОБЛАСТЬ_АНАЛИТИЧЕСКИХ_ПРЕТЕНЗИЙ,
            ).stdout,
            "",
        )

    def test_аналитическая_претензия_удаляется_до_общего_освобождения(
        сам,
    ) -> None:
        корень, _, _, _, выбор, попытка = (
            сам.подготовить_аналитическую_резервацию_до_среды()
        )
        ссылка_претензии, объект_претензии = сам.записать_аналитическую_претензию(
            корень,
            выбор,
            попытка,
            "unused-task",
            "unused-generation",
            str(выбор["selection_head"]),
            фаза="зарезервирована",
        )
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            "unused-task",
            "unused-generation",
            str(выбор["selection_head"]),
        )
        сам.выполнить_гит(
            корень,
            "commit",
            "--allow-empty",
            "-m",
            "Продвинуть ветку после претензии",
        )
        преждевременное = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(
                корень,
                выбор,
                попытка,
                "released",
            ),
        )
        сам.assertEqual(преждевременное.returncode, 5, преждевременное.stdout)
        сам.assertEqual(json.loads(преждевременное.stdout)["причина"], "analytic_claim_not_released")
        сам.assertEqual(
            сам.выполнить_гит(корень, "rev-parse", "--verify", ссылка_претензии).stdout.strip(),
            объект_претензии,
        )
        специализированное = сам.выполнить_аналитику(
            корень,
            *сам.аргументы_аналитического_освобождения(корень, выбор, попытка),
        )
        сам.assertEqual(специализированное.returncode, 0, специализированное.stdout + специализированное.stderr)
        сам.assertEqual(json.loads(специализированное.stdout)["state"], "released")
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "for-each-ref",
                "--format=%(objectname)",
                ссылка_претензии,
            ).stdout,
            "",
        )
        общее = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(
                корень,
                выбор,
                попытка,
                "released",
            ),
        )
        сам.assertEqual(общее.returncode, 0, общее.stdout + общее.stderr)

    def test_аналитическая_претензия_между_снимком_и_атомарной_заменой_блокирует_освобождение(
        сам,
    ) -> None:
        корень, _, _, _, выбор, попытка = (
            сам.подготовить_аналитическую_резервацию_до_среды()
        )
        ссылка_претензии, объект_претензии = сам.записать_аналитическую_претензию(
            корень,
            выбор,
            попытка,
            "unused-task",
            "unused-generation",
            str(выбор["selection_head"]),
            фаза="зарезервирована",
        )
        сам.выполнить_гит(
            корень,
            "update-ref",
            "-d",
            ссылка_претензии,
            объект_претензии,
        )
        ссылка_резервации, объект_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        имя_модуля = f"_fum_dispatcher_test_{uuid.uuid4().hex}"
        спецификация = importlib.util.spec_from_file_location(
            имя_модуля,
            СЦЕНАРИЙ,
        )
        сам.assertIsNotNone(спецификация)
        if спецификация is None:
            сам.fail("Не удалось загрузить сценарий диспетчера")
        сам.assertIsNotNone(спецификация.loader)
        if спецификация.loader is None:
            сам.fail("Сценарий диспетчера не имеет загрузчика")
        модуль = importlib.util.module_from_spec(спецификация)
        sys.modules[имя_модуля] = модуль
        сам.addCleanup(sys.modules.pop, имя_модуля, None)
        спецификация.loader.exec_module(модуль)
        исходная_замена = модуль.заменить_резервацию_сравнением
        претензия_вставлена = False

        def заменить_после_снимка(*аргументы: object, **именованные: object) -> bool:
            nonlocal претензия_вставлена
            if not претензия_вставлена:
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка_претензии,
                    объект_претензии,
                )
                претензия_вставлена = True
            return bool(исходная_замена(*аргументы, **именованные))

        модуль.заменить_резервацию_сравнением = заменить_после_снимка
        код, ответ = модуль.освободить_резервацию(
            str(корень),
            str(выбор["branch_ref"]),
            str(выбор["job_id"]),
            str(выбор["run_key"]),
            попытка,
            "unclaimed",
        )
        сам.assertEqual(код, 5, ответ)
        сам.assertEqual(ответ["причина"], "analytic_claim_not_released")
        сам.assertEqual(
            сам.выполнить_гит(корень, "rev-parse", "--verify", ссылка_резервации).stdout.strip(),
            объект_резервации,
        )
        сам.assertEqual(
            сам.выполнить_гит(корень, "rev-parse", "--verify", ссылка_претензии).stdout.strip(),
            объект_претензии,
        )

    def test_резервация_следующего_шага_освобождается_только_после_доказанного_отсутствия_претензии(
        сам,
    ) -> None:
        корень, _, _, _, выбор, попытка = (
            сам.подготовить_резервацию_живого_адаптера(False)
        )
        без_доказательства = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(корень, выбор, попытка),
        )
        сам.assertEqual(без_доказательства.returncode, 5, без_доказательства.stdout)
        сам.assertEqual(json.loads(без_доказательства.stdout)["причина"], "adapter_recovery_required")
        ссылка_претензии, объект_претензии = сам.записать_претензию_до_вызова_среды(корень, выбор, попытка)
        с_живой_претензией = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(корень, выбор, попытка, "unclaimed"),
        )
        сам.assertEqual(с_живой_претензией.returncode, 5, с_живой_претензией.stdout)
        сам.assertEqual(json.loads(с_живой_претензией.stdout)["причина"], "next_step_claim_not_released")
        сам.выполнить_гит(корень, "update-ref", "-d", ссылка_претензии, объект_претензии)
        сам.выполнить_гит(корень, "commit", "--allow-empty", "-m", "Продвинуть ветку до общего освобождения")
        освобождение = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(корень, выбор, попытка, "released"),
        )
        сам.assertEqual(освобождение.returncode, 0, освобождение.stdout + освобождение.stderr)
        повтор = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(корень, выбор, попытка, "released"),
        )
        сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
        сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")

    def test_поздняя_претензия_следующего_шага_блокирует_общее_освобождение(
        сам,
    ) -> None:
        корень, _, _, _, выбор, попытка = сам.подготовить_резервацию_живого_адаптера(False)
        ссылка_претензии, объект_претензии = сам.записать_претензию_до_вызова_среды(корень, выбор, попытка)
        сам.выполнить_гит(корень, "update-ref", "-d", ссылка_претензии, объект_претензии)
        ссылка_резервации, объект_резервации = сам.выполнить_гит(корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/резервации-запусков-автоматизаций").stdout.strip().split("\0")
        эпоха_до = сам.выполнить_гит(корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/эпохи-резерваций-запусков-автоматизаций").stdout
        имя_модуля = f"_fum_dispatcher_next_step_release_{uuid.uuid4().hex}"
        спецификация = importlib.util.spec_from_file_location(имя_модуля, СЦЕНАРИЙ)
        сам.assertIsNotNone(спецификация)
        if спецификация is None or спецификация.loader is None:
            сам.fail("Не удалось загрузить диспетчер для гонки освобождения")
        модуль = importlib.util.module_from_spec(спецификация)
        sys.modules[имя_модуля] = модуль
        сам.addCleanup(sys.modules.pop, имя_модуля, None)
        спецификация.loader.exec_module(модуль)
        исходная_замена = модуль.заменить_резервацию_сравнением
        претензия_вставлена = False

        def заменить_после_снимка(*аргументы: object, **именованные: object) -> bool:
            nonlocal претензия_вставлена
            if not претензия_вставлена:
                сам.выполнить_гит(корень, "update-ref", ссылка_претензии, объект_претензии)
                претензия_вставлена = True
            return bool(исходная_замена(*аргументы, **именованные))

        модуль.заменить_резервацию_сравнением = заменить_после_снимка
        код, ответ = модуль.освободить_резервацию(str(корень), str(выбор["branch_ref"]), str(выбор["job_id"]), str(выбор["run_key"]), попытка, "unclaimed")
        сам.assertEqual(код, 5, ответ)
        сам.assertEqual(ответ["причина"], "next_step_claim_not_released")
        сам.assertEqual(сам.выполнить_гит(корень, "rev-parse", ссылка_резервации).stdout.strip(), объект_резервации)
        сам.assertEqual(сам.выполнить_гит(корень, "for-each-ref", "--format=%(refname)%00%(objectname)", "refs/fum/эпохи-резерваций-запусков-автоматизаций").stdout, эпоха_до)

    def test_аналитический_сброс_после_передачи_не_даёт_ложного_успеха(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            ссылка_претензии,
            объект_претензии,
            _,
            _,
        ) = сам.подготовить_аналитический_сброс("передана")
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(терминал.returncode, 5, терминал.stdout)
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--verify",
                ссылка_претензии,
            ).stdout.strip(),
            объект_претензии,
        )

    def test_завершённая_аналитика_после_сброса_терминализируется_по_квитанции(
        сам,
    ) -> None:
        (
            корень,
            выбор,
            попытка,
            ссылка_претензии,
            объект_претензии,
            _,
            _,
        ) = сам.подготовить_аналитический_сброс("завершена")
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(терминал.returncode, 0, терминал.stdout)
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                "--verify",
                ссылка_претензии,
            ).stdout.strip(),
            объект_претензии,
        )
        повтор_терминала = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(повтор_терминала.returncode, 0)
        сам.assertEqual(
            json.loads(повтор_терминала.stdout)["владение"],
            "существующее",
        )
        реестр, схема, наблюдения, новый_выбор = (
            сам.продвинуть_выбор_после_успеха(
                корень,
                "master.completed-step-analysis",
            )
        )
        новая_попытка = str(uuid.uuid4())
        новая_резервация = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            новый_выбор,
            новая_попытка,
        )
        сам.assertEqual(
            новая_резервация.returncode,
            0,
            новая_резервация.stdout + новая_резервация.stderr,
        )
        сам.проверить_отсутствие_ссылки(корень, ссылка_претензии)
        повтор_резервации = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            новый_выбор,
            новая_попытка,
        )
        сам.assertEqual(повтор_резервации.returncode, 0)
        сам.assertEqual(
            json.loads(повтор_резервации.stdout)["владение"],
            "существующее",
        )
        восстановление = сам.выполнить_аналитику(
            корень,
            *сам.аргументы_аналитического_освобождения(
                корень,
                новый_выбор,
                новая_попытка,
            ),
        )
        сам.assertEqual(
            восстановление.returncode,
            0,
            восстановление.stdout + восстановление.stderr,
        )
        сам.assertEqual(
            json.loads(восстановление.stdout)["state"],
            "unclaimed",
        )
        общее_освобождение = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(
                корень,
                новый_выбор,
                новая_попытка,
                "unclaimed",
            ),
        )
        сам.assertEqual(
            общее_освобождение.returncode,
            0,
            общее_освобождение.stdout + общее_освобождение.stderr,
        )
        сам.assertEqual(
            json.loads(общее_освобождение.stdout)["исход"],
            "безопасный_отказ_до_эффекта",
        )

    def test_межадаптерный_запуск_сохраняет_чужой_повтор_до_следующей_резервации_его_адаптера(
        сам,
    ) -> None:
        (
            корень,
            аналитический_выбор,
            аналитическая_попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_аналитическое_завершение()
        вершина_результата = сам.выполнить_гит(
            корень, "rev-parse", "HEAD"
        ).stdout.strip()
        ссылка_аналитической_претензии, объект_аналитической_претензии = (
            сам.записать_аналитическую_претензию(
                корень,
                аналитический_выбор,
                аналитическая_попытка,
                идентификатор_задачи,
                поколение_очереди,
                вершина_результата,
            )
        )
        аналитический_терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(
                корень,
                аналитический_выбор,
                аналитическая_попытка,
            ),
            "--json",
        )
        сам.assertEqual(
            аналитический_терминал.returncode,
            0,
            аналитический_терминал.stdout + аналитический_терминал.stderr,
        )
        наблюдения = корень / "наблюдения.json"
        значение_наблюдений = json.loads(
            наблюдения.read_text(encoding="utf-8")
        )
        значение_наблюдений["момент"] = "2026-08-05T12:10:00Z"
        значение_наблюдений["подтверждённые_события"] = {
            "завершение_runtime_ready_commit_handoff": 5,
        }
        сам.записать_объект(наблюдения, значение_наблюдений)
        сам.выполнить_гит(корень, "add", "--", "наблюдения.json")
        сам.выполнить_гит(
            корень,
            "commit",
            "-m",
            "Открыть межадаптерный запуск",
        )
        реестр = корень / "реестр.json"
        схема = корень / "схема.json"
        выбор_следующего_шага = сам.выбрать(
            корень,
            реестр,
            схема,
            наблюдения,
        )
        сам.assertEqual(
            выбор_следующего_шага["job_id"],
            "master.next-step",
        )
        попытка_следующего_шага = str(uuid.uuid4())
        резерв_следующего_шага = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор_следующего_шага,
            попытка_следующего_шага,
        )
        сам.assertEqual(
            резерв_следующего_шага.returncode,
            0,
            резерв_следующего_шага.stdout + резерв_следующего_шага.stderr,
        )
        сам.assertEqual(
            сам.выполнить_гит(
                корень,
                "rev-parse",
                ссылка_аналитической_претензии,
            ).stdout.strip(),
            объект_аналитической_претензии,
        )
        повтор_аналитического_терминала = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(
                корень,
                аналитический_выбор,
                аналитическая_попытка,
            ),
            "--json",
        )
        сам.assertEqual(повтор_аналитического_терминала.returncode, 0)
        сам.assertEqual(
            json.loads(повтор_аналитического_терминала.stdout)["владение"],
            "существующее",
        )
        восстановление_следующего_шага = сам.выполнить_следующий_шаг(
            корень,
            "release",
            "--repo-root",
            str(корень),
            "--branch-ref",
            str(выбор_следующего_шага["branch_ref"]),
            "--expected-lease-id",
            попытка_следующего_шага,
            "--json",
        )
        сам.assertEqual(восстановление_следующего_шага.returncode, 0)
        сам.assertEqual(
            json.loads(восстановление_следующего_шага.stdout)["state"],
            "unclaimed",
        )
        общее_освобождение_следующего_шага = сам.выполнить(
            корень,
            *сам.аргументы_общего_освобождения(
                корень,
                выбор_следующего_шага,
                попытка_следующего_шага,
                "unclaimed",
            ),
        )
        сам.assertEqual(
            общее_освобождение_следующего_шага.returncode,
            0,
            общее_освобождение_следующего_шага.stdout
            + общее_освобождение_следующего_шага.stderr,
        )
        значение_наблюдений["момент"] = "2026-08-05T12:15:00Z"
        значение_наблюдений["подтверждённые_события"] = {
            "завершение_runtime_ready_commit_handoff": 10,
        }
        сам.записать_объект(наблюдения, значение_наблюдений)
        сам.выполнить_гит(корень, "add", "--", "наблюдения.json")
        сам.выполнить_гит(
            корень,
            "commit",
            "-m",
            "Открыть следующую аналитику",
        )
        следующий_аналитический_выбор = сам.выбрать(
            корень,
            реестр,
            схема,
            наблюдения,
        )
        сам.assertEqual(
            следующий_аналитический_выбор["job_id"],
            "master.completed-step-analysis",
        )
        следующий_аналитический_резерв = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            следующий_аналитический_выбор,
            str(uuid.uuid4()),
        )
        сам.assertEqual(
            следующий_аналитический_резерв.returncode,
            0,
            следующий_аналитический_резерв.stdout
            + следующий_аналитический_резерв.stderr,
        )
        сам.проверить_отсутствие_ссылки(
            корень,
            ссылка_аналитической_претензии,
        )

    def test_устаревшее_завершение_не_может_обойти_очередь_и_претензию(
        сам,
    ) -> None:
        for ожидаемое_задание in (
            "master.next-step",
            "master.completed-step-analysis",
        ):
            with сам.subTest(задание=ожидаемое_задание):
                корень, реестр, схема, наблюдения, выбор = (
                    сам.создать_репозиторий()
                )
                if ожидаемое_задание == "master.completed-step-analysis":
                    значение_наблюдений = json.loads(
                        наблюдения.read_text(encoding="utf-8")
                    )
                    значение_наблюдений["подтверждённые_события"] = {
                        "завершение_runtime_ready_commit_handoff": 5,
                    }
                    сам.записать_объект(наблюдения, значение_наблюдений)
                    сам.выполнить_гит(корень, "add", "--", "наблюдения.json")
                    сам.выполнить_гит(
                        корень,
                        "commit",
                        "-m",
                        "Достичь аналитического порога",
                    )
                    выбор = сам.выбрать(корень, реестр, схема, наблюдения)
                сам.assertEqual(выбор["job_id"], ожидаемое_задание)
                попытка = str(uuid.uuid4())
                сам.подготовить_создание(
                    корень,
                    реестр,
                    схема,
                    наблюдения,
                    выбор,
                    попытка,
                    "legacy-created-thread",
                )
                завершение = сам.выполнить(
                    корень,
                    "завершить",
                    "--корень-рабочей-копии",
                    str(корень),
                    "--expected-branch-ref",
                    str(выбор["branch_ref"]),
                    "--expected-job-id",
                    str(выбор["job_id"]),
                    "--expected-run-key",
                    str(выбор["run_key"]),
                    "--идентификатор-попытки",
                    попытка,
                    "--исход",
                    "успех",
                    "--подтверждение-результата",
                    "legacy-result",
                    "--json",
                )
                сам.assertEqual(завершение.returncode, 5, завершение.stdout)
                сам.assertEqual(
                    json.loads(завершение.stdout)["причина"],
                    "legacy_success_forbidden",
                )
                состояние = сам.выполнить(
                    корень,
                    "состояние-резервации",
                    "--корень-рабочей-копии",
                    str(корень),
                    "--expected-branch-ref",
                    str(выбор["branch_ref"]),
                    "--expected-job-id",
                    str(выбор["job_id"]),
                    "--json",
                )
                сам.assertEqual(состояние.returncode, 0, состояние.stderr)
                сам.assertNotEqual(json.loads(состояние.stdout)["фаза"], "завершён")

    def test_следующий_тик_терминализирует_точную_передачу_с_коммитом(
        сам,
    ) -> None:
        for версия_претензии in (4, 5):
            with сам.subTest(версия_претензии=версия_претензии):
                корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
                попытка = str(uuid.uuid4())
                идентификатор_задачи = "actual-root-task"
                поколение_очереди = str(uuid.uuid4())
                сам.подготовить_создание(
                    корень,
                    реестр,
                    схема,
                    наблюдения,
                    выбор,
                    попытка,
                    "created-thread-id",
                )
                привязка = сам.выполнить(
                    корень,
                    "bind-run",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--task-id",
                    идентификатор_задачи,
                    "--json",
                )
                сам.assertEqual(привязка.returncode, 0, привязка.stderr)
                сам.записать_очередь(
                    корень,
                    str(выбор["branch_ref"]),
                    идентификатор_задачи,
                    поколение_очереди,
                    str(выбор["selection_head"]),
                )
                проверка = сам.выполнить(
                    корень,
                    "verify-run",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--task-id",
                    идентификатор_задачи,
                    "--generation",
                    поколение_очереди,
                    "--json",
                )
                сам.assertEqual(проверка.returncode, 0, проверка.stderr)
                ссылка_претензии, объект_претензии = (
                    сам.записать_точную_претензию(
                        корень,
                        выбор,
                        попытка,
                        идентификатор_задачи,
                        поколение_очереди,
                    )
                )
                if версия_претензии == 4:
                    объект_претензии = (
                        сам.переписать_карточочную_претензию_в_схему_четыре(
                            корень,
                            ссылка_претензии,
                            объект_претензии,
                        )
                    )

                (корень / "результат.txt").write_text(
                    "готово\n", encoding="utf-8"
                )
                сам.выполнить_гит(
                    корень, "add", "--", "результат.txt"
                )
                сам.выполнить_гит(
                    корень, "commit", "-m", "Завершить задачу"
                )
                новая_вершина = сам.выполнить_гит(
                    корень,
                    "rev-parse",
                    "HEAD",
                ).stdout.strip()
                сам.записать_очередь(
                    корень,
                    str(выбор["branch_ref"]),
                    идентификатор_задачи,
                    поколение_очереди,
                    str(выбор["selection_head"]),
                    завершение={
                        "kind": "committed",
                        "task_id": идентификатор_задачи,
                        "generation": поколение_очереди,
                        "base_head": str(выбор["selection_head"]),
                        "head": новая_вершина,
                        "completed_at": "2026-08-05T12:06:00+00:00",
                    },
                )

                терминал = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--json",
                )
                сам.assertEqual(
                    терминал.returncode,
                    0,
                    терминал.stdout + терминал.stderr,
                )
                сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")
                повтор_терминала = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--json",
                )
                сам.assertEqual(повтор_терминала.returncode, 0)
                сам.assertEqual(
                    json.loads(повтор_терминала.stdout)["владение"],
                    "существующее",
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень, "rev-parse", ссылка_претензии
                    ).stdout.strip(),
                    объект_претензии,
                )

                (
                    новый_реестр,
                    новая_схема,
                    новые_наблюдения,
                    новый_выбор,
                ) = сам.продвинуть_выбор_после_успеха(
                    корень,
                    "master.next-step",
                )
                новая_попытка = str(uuid.uuid4())
                новая_резервация = сам.резервировать_новый_запуск(
                    корень,
                    новый_реестр,
                    новая_схема,
                    новые_наблюдения,
                    новый_выбор,
                    новая_попытка,
                )
                сам.assertEqual(
                    новая_резервация.returncode,
                    0,
                    новая_резервация.stdout + новая_резервация.stderr,
                )
                сам.assertEqual(
                    json.loads(новая_резервация.stdout)["владение"],
                    "новое",
                )
                сам.проверить_отсутствие_ссылки(
                    корень,
                    ссылка_претензии,
                )
                повтор_резервации = сам.резервировать_новый_запуск(
                    корень,
                    новый_реестр,
                    новая_схема,
                    новые_наблюдения,
                    новый_выбор,
                    новая_попытка,
                )
                сам.assertEqual(повтор_резервации.returncode, 0)
                сам.assertEqual(
                    json.loads(повтор_резервации.stdout)["владение"],
                    "существующее",
                )
                восстановление = сам.выполнить_следующий_шаг(
                    корень,
                    "release",
                    "--repo-root",
                    str(корень),
                    "--branch-ref",
                    str(новый_выбор["branch_ref"]),
                    "--expected-lease-id",
                    новая_попытка,
                    "--json",
                )
                сам.assertEqual(
                    восстановление.returncode,
                    0,
                    восстановление.stdout + восстановление.stderr,
                )
                сам.assertEqual(
                    json.loads(восстановление.stdout)["state"],
                    "unclaimed",
                )
                общее_освобождение = сам.выполнить(
                    корень,
                    *сам.аргументы_общего_освобождения(
                        корень,
                        новый_выбор,
                        новая_попытка,
                        "unclaimed",
                    ),
                )
                сам.assertEqual(
                    общее_освобождение.returncode,
                    0,
                    общее_освобождение.stdout + общее_освобождение.stderr,
                )
                сам.assertEqual(
                    json.loads(общее_освобождение.stdout)["исход"],
                    "безопасный_отказ_до_эффекта",
                )

    def test_завершение_устаревшей_схемы_четыре_не_перезаписывается_ожидавшим_владельцем_до_общего_терминального_исхода(
        сам,
    ) -> None:
        for действие in ("commit", "finish-clean"):
            with сам.subTest(действие=действие):
                корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
                попытка = str(uuid.uuid4())
                идентификатор_задачи = "legacy-schema4-root-task"
                поколение_очереди = str(uuid.uuid4())
                сам.подготовить_создание(
                    корень,
                    реестр,
                    схема,
                    наблюдения,
                    выбор,
                    попытка,
                    идентификатор_задачи,
                    точное_свидетельство=True,
                )
                привязка = сам.выполнить(
                    корень,
                    "bind-run",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--task-id",
                    идентификатор_задачи,
                    "--json",
                )
                сам.assertEqual(
                    привязка.returncode,
                    0,
                    привязка.stdout + привязка.stderr,
                )
                сам.записать_очередь(
                    корень,
                    str(выбор["branch_ref"]),
                    идентификатор_задачи,
                    поколение_очереди,
                    str(выбор["selection_head"]),
                )
                проверка = сам.выполнить(
                    корень,
                    "verify-run",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--task-id",
                    идентификатор_задачи,
                    "--generation",
                    поколение_очереди,
                    "--json",
                )
                сам.assertEqual(
                    проверка.returncode,
                    0,
                    проверка.stdout + проверка.stderr,
                )
                ссылка_претензии, объект_претензии = (
                    сам.записать_точную_претензию(
                        корень,
                        выбор,
                        попытка,
                        идентификатор_задачи,
                        поколение_очереди,
                    )
                )
                объект_претензии = (
                    сам.переписать_карточочную_претензию_в_схему_четыре(
                        корень,
                        ссылка_претензии,
                        объект_претензии,
                    )
                )

                ожидавшая_задача = f"waiting-owner-{действие}"
                ожидание = сам.выполнить_очередь(
                    корень,
                    "join",
                    "--repo-root",
                    str(корень),
                    "--task-id",
                    ожидавшая_задача,
                    "--json",
                )
                сам.assertEqual(
                    ожидание.returncode,
                    10,
                    ожидание.stdout + ожидание.stderr,
                )
                сам.assertEqual(json.loads(ожидание.stdout)["state"], "waiting")

                (корень / "legacy-result.txt").write_text(
                    "готово\n", encoding="utf-8"
                )
                сам.выполнить_гит(
                    корень, "add", "--", "legacy-result.txt"
                )
                сам.выполнить_гит(
                    корень,
                    "commit",
                    "-m",
                    "Завершить legacy schema4 старым bootstrap",
                )
                завершивший_коммит = сам.выполнить_гит(
                    корень, "rev-parse", "HEAD"
                ).stdout.strip()
                ссылка_очереди, объект_очереди = сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname)%00%(objectname)",
                    ОБЛАСТЬ_ОЧЕРЕДИ,
                ).stdout.strip().split("\0")
                очередь = json.loads(
                    сам.выполнить_гит(
                        корень, "cat-file", "blob", объект_очереди
                    ).stdout
                )
                очередь["owner"] = None
                очередь["last_completion"] = {
                    "kind": "committed",
                    "task_id": идентификатор_задачи,
                    "generation": поколение_очереди,
                    "base_head": str(выбор["selection_head"]),
                    "head": завершивший_коммит,
                    "completed_at": "2026-08-11T00:00:00+00:00",
                }
                очередь["updated_at"] = "2026-08-11T00:00:00+00:00"
                новый_объект_очереди = сам.выполнить_гит(
                    корень,
                    "hash-object",
                    "-w",
                    "--stdin",
                    вход=json.dumps(
                        очередь,
                        ensure_ascii=False,
                        sort_keys=True,
                        separators=(",", ":"),
                    )
                    + "\n",
                ).stdout.strip()
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка_очереди,
                    новый_объект_очереди,
                    объект_очереди,
                )
                требуется_перечитать = сам.выполнить_очередь(
                    корень,
                    "wait",
                    "--repo-root",
                    str(корень),
                    "--task-id",
                    ожидавшая_задача,
                    "--json",
                )
                сам.assertEqual(
                    требуется_перечитать.returncode,
                    11,
                    требуется_перечитать.stdout
                    + требуется_перечитать.stderr,
                )
                подтверждение_вершины = сам.выполнить_очередь(
                    корень,
                    "ack-head",
                    "--repo-root",
                    str(корень),
                    "--task-id",
                    ожидавшая_задача,
                    "--head",
                    завершивший_коммит,
                    "--json",
                )
                сам.assertEqual(
                    подтверждение_вершины.returncode,
                    0,
                    подтверждение_вершины.stdout
                    + подтверждение_вершины.stderr,
                )
                допуск = сам.выполнить_очередь(
                    корень,
                    "wait",
                    "--repo-root",
                    str(корень),
                    "--task-id",
                    ожидавшая_задача,
                    "--json",
                )
                сам.assertEqual(
                    допуск.returncode,
                    0,
                    допуск.stdout + допуск.stderr,
                )
                поколение_ожидавшей = str(
                    json.loads(допуск.stdout)["generation"]
                )
                if действие == "commit":
                    (корень / "later-result.txt").write_text(
                        "позднее\n", encoding="utf-8"
                    )
                    сам.выполнить_гит(
                        корень, "add", "--", "later-result.txt"
                    )
                    аргументы_завершения = (
                        "commit",
                        "--repo-root",
                        str(корень),
                        "--task-id",
                        ожидавшая_задача,
                        "--generation",
                        поколение_ожидавшей,
                        "--message",
                        "Завершить ожидавшую задачу",
                        "--json",
                    )
                else:
                    аргументы_завершения = (
                        "finish-clean",
                        "--repo-root",
                        str(корень),
                        "--task-id",
                        ожидавшая_задача,
                        "--generation",
                        поколение_ожидавшей,
                        "--json",
                    )
                преждевременное_завершение = сам.выполнить_очередь(
                    корень, *аргументы_завершения
                )
                сам.assertEqual(
                    преждевременное_завершение.returncode,
                    12,
                    преждевременное_завершение.stdout
                    + преждевременное_завершение.stderr,
                )
                сам.assertEqual(
                    json.loads(преждевременное_завершение.stdout)["state"],
                    "legacy_terminalization_pending",
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень, "rev-parse", ссылка_претензии
                    ).stdout.strip(),
                    объект_претензии,
                )
                объект_очереди_до_повтора = сам.выполнить_гит(
                    корень, "rev-parse", ссылка_очереди
                ).stdout.strip()
                повтор_до_терминала = сам.выполнить_очередь(
                    корень,
                    "commit",
                    "--repo-root",
                    str(корень),
                    "--task-id",
                    идентификатор_задачи,
                    "--generation",
                    поколение_очереди,
                    "--message",
                    "Повторить потерянный ответ до terminal",
                    "--json",
                )
                сам.assertEqual(
                    повтор_до_терминала.returncode,
                    0,
                    повтор_до_терминала.stdout
                    + повтор_до_терминала.stderr,
                )
                сам.assertEqual(
                    json.loads(повтор_до_терминала.stdout)["new_head"],
                    завершивший_коммит,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень, "rev-parse", ссылка_очереди
                    ).stdout.strip(),
                    объект_очереди_до_повтора,
                )
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень, "rev-parse", "HEAD"
                    ).stdout.strip(),
                    завершивший_коммит,
                )

                терминал = сам.выполнить(
                    корень,
                    "подтвердить-завершение-исполнителя",
                    *сам.аргументы_ограждения_запуска(
                        корень, выбор, попытка
                    ),
                    "--json",
                )
                сам.assertEqual(
                    терминал.returncode,
                    0,
                    терминал.stdout + терминал.stderr,
                )
                сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")

                повтор_старого_ответа = сам.выполнить_очередь(
                    корень,
                    "commit",
                    "--repo-root",
                    str(корень),
                    "--task-id",
                    идентификатор_задачи,
                    "--generation",
                    поколение_очереди,
                    "--message",
                    "Повторить потерянный ответ legacy schema4",
                    "--json",
                )
                сам.assertEqual(
                    повтор_старого_ответа.returncode,
                    0,
                    повтор_старого_ответа.stdout
                    + повтор_старого_ответа.stderr,
                )

                повтор = сам.выполнить_очередь(
                    корень, *аргументы_завершения
                )
                сам.assertEqual(
                    повтор.returncode,
                    0,
                    повтор.stdout + повтор.stderr,
                )

    def test_коммит_схемы_четыре_мигрирует_претензию_и_терминализируется_после_поздней_передачи(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        специализированный_выбор = сам.показать_специализированный_выбор(
            корень
        )
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "schema4-migration-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            идентификатор_задачи,
            точное_свидетельство=True,
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(
            привязка.returncode,
            0,
            привязка.stdout + привязка.stderr,
        )
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(
            проверка.returncode,
            0,
            проверка.stdout + проверка.stderr,
        )
        ссылка_претензии, исходный_объект_претензии = (
            сам.записать_точную_претензию(
                корень,
                выбор,
                попытка,
                идентификатор_задачи,
                поколение_очереди,
            )
        )
        исходный_объект_претензии = (
            сам.переписать_карточочную_претензию_в_схему_четыре(
                корень,
                ссылка_претензии,
                исходный_объект_претензии,
            )
        )
        (корень / "schema4-result.txt").write_text(
            "готово\n", encoding="utf-8"
        )
        сам.выполнить_гит(
            корень, "add", "--", "schema4-result.txt"
        )
        передача = сам.выполнить_очередь(
            корень,
            "commit",
            "--repo-root",
            str(корень),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--message",
            "Завершить schema4 с атомарной миграцией",
            "--json",
        )
        сам.assertEqual(
            передача.returncode,
            0,
            передача.stdout + передача.stderr,
        )
        завершивший_коммит = str(json.loads(передача.stdout)["new_head"])
        новый_объект_претензии = сам.выполнить_гит(
            корень, "rev-parse", ссылка_претензии
        ).stdout.strip()
        сам.assertNotEqual(
            новый_объект_претензии,
            исходный_объект_претензии,
        )
        претензия = json.loads(
            сам.выполнить_гит(
                корень, "cat-file", "blob", новый_объект_претензии
            ).stdout
        )
        сам.assertEqual(претензия["schema_version"], 5)
        сам.assertEqual(
            претензия["card_id"],
            специализированный_выбор["card_id"],
        )
        идентичность, хэш_ветки = сам.служебная_основа_ветки(
            корень,
            str(выбор["branch_ref"]),
        )
        ссылка_журнала = (
            "refs/fum/worktree-task-completion-ledgers/"
            f"{идентичность}/{хэш_ветки}"
        )
        журнал = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                сам.выполнить_гит(
                    корень, "rev-parse", ссылка_журнала
                ).stdout.strip(),
            ).stdout
        )
        сам.assertEqual(журнал["число_событий"], 1)
        сам.assertEqual(
            журнал["события"][0]["завершивший_commit"],
            завершивший_коммит,
        )

        поздняя_задача = "later-after-schema4-migration"
        допуск_поздней = сам.выполнить_очередь(
            корень,
            "join",
            "--repo-root",
            str(корень),
            "--task-id",
            поздняя_задача,
            "--json",
        )
        сам.assertEqual(
            допуск_поздней.returncode,
            0,
            допуск_поздней.stdout + допуск_поздней.stderr,
        )
        поколение_поздней = str(json.loads(допуск_поздней.stdout)["generation"])
        (корень / "later-after-schema4.txt").write_text(
            "позднее\n", encoding="utf-8"
        )
        сам.выполнить_гит(
            корень, "add", "--", "later-after-schema4.txt"
        )
        поздняя_передача = сам.выполнить_очередь(
            корень,
            "commit",
            "--repo-root",
            str(корень),
            "--task-id",
            поздняя_задача,
            "--generation",
            поколение_поздней,
            "--message",
            "Завершить позднюю задачу после schema4",
            "--json",
        )
        сам.assertEqual(
            поздняя_передача.returncode,
            0,
            поздняя_передача.stdout + поздняя_передача.stderr,
        )
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")

    def test_сброс_после_коммита_схемы_четыре_ограждает_сохранённую_претензию(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "schema4-reset-after-commit-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            идентификатор_задачи,
            точное_свидетельство=True,
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        исходный_объект_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        ссылка_претензии, объект_претензии = сам.записать_точную_претензию(
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        объект_претензии = (
            сам.переписать_карточочную_претензию_в_схему_четыре(
                корень,
                ссылка_претензии,
                объект_претензии,
            )
        )
        (корень / "schema4-before-reset.txt").write_text(
            "готово\n", encoding="utf-8"
        )
        сам.выполнить_гит(
            корень, "add", "--", "schema4-before-reset.txt"
        )
        сам.выполнить_гит(
            корень,
            "commit",
            "-m",
            "Завершить schema4 до штатного сброса",
        )
        завершивший_коммит = сам.выполнить_гит(
            корень, "rev-parse", "HEAD"
        ).stdout.strip()
        завершение = {
            "kind": "committed",
            "task_id": идентификатор_задачи,
            "generation": поколение_очереди,
            "base_head": str(выбор["selection_head"]),
            "head": завершивший_коммит,
            "completed_at": "2026-08-11T00:00:00+00:00",
        }
        исходный_объект_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
            завершение=завершение,
        )
        исходное_состояние_очереди = json.loads(
            сам.выполнить_гит(
                корень, "cat-file", "blob", исходный_объект_очереди
            ).stdout
        )
        ссылка_резервации, объект_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        квитанция_фикстуры = json.loads(
            ФИКСТУРА_СОСТОЯНИЯ_ПОСЛЕ_СБРОСА.read_text(encoding="utf-8")
        )["квитанция_сброса"]
        сам.записать_квитанцию_сброса(
            корень,
            выбор,
            ссылка_резервации,
            объект_резервации,
            идентификатор_задачи,
            поколение_очереди,
            исходный_объект_очереди,
            исходное_состояние_очереди,
            квитанция_фикстуры,
            включить_ограждение_претензии=True,
            целевая_вершина=завершивший_коммит,
        )
        объект_подмены = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход="{}\n",
        ).stdout.strip()
        имя_модуля = f"_fum_dispatcher_schema4_reset_{uuid.uuid4().hex}"
        спецификация = importlib.util.spec_from_file_location(
            имя_модуля,
            СЦЕНАРИЙ,
        )
        сам.assertIsNotNone(спецификация)
        if спецификация is None or спецификация.loader is None:
            сам.fail("Не удалось загрузить диспетчер schema4 reset")
        модуль = importlib.util.module_from_spec(спецификация)
        sys.modules[имя_модуля] = модуль
        сам.addCleanup(sys.modules.pop, имя_модуля, None)
        спецификация.loader.exec_module(модуль)
        исходная_замена = модуль.заменить_общее_ограждение_запуска
        претензия_подменена = False

        def подменить_сохранённую_претензию(
            *аргументы: object,
            **именованные: object,
        ) -> bool:
            nonlocal претензия_подменена
            if not претензия_подменена:
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка_претензии,
                    объект_подмены,
                    объект_претензии,
                )
                претензия_подменена = True
            return bool(исходная_замена(*аргументы, **именованные))

        модуль.заменить_общее_ограждение_запуска = (
            подменить_сохранённую_претензию
        )
        код, ответ = модуль.подтвердить_завершение_исполнителя(
            str(корень),
            str(выбор["branch_ref"]),
            str(выбор["selection_head"]),
            str(выбор["job_id"]),
            int(выбор["spec_generation"]),
            int(выбор["поколение_реестра"]),
            str(выбор["run_key"]),
            попытка,
            None,
        )
        сам.assertEqual(код, 5, ответ)
        сам.assertEqual(ответ["причина"], "next_step_clean_claim_unverified")
        сам.assertEqual(
            сам.выполнить_гит(
                корень, "rev-parse", ссылка_резервации
            ).stdout.strip(),
            объект_резервации,
        )
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_претензии,
            объект_претензии,
            объект_подмены,
        )
        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            терминал.returncode,
            0,
            терминал.stdout + терминал.stderr,
        )
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")
        повтор = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(повтор.returncode, 0, повтор.stdout + повтор.stderr)
        сам.assertEqual(json.loads(повтор.stdout)["владение"], "существующее")
        реестр, схема, наблюдения, новый_выбор = (
            сам.продвинуть_выбор_после_успеха(
                корень,
                "master.next-step",
            )
        )
        новая_попытка = str(uuid.uuid4())
        новый_резерв = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            новый_выбор,
            новая_попытка,
        )
        сам.assertEqual(
            новый_резерв.returncode,
            0,
            новый_резерв.stdout + новый_резерв.stderr,
        )
        сам.проверить_отсутствие_ссылки(корень, ссылка_претензии)
        повтор_резерва = сам.резервировать_новый_запуск(
            корень,
            реестр,
            схема,
            наблюдения,
            новый_выбор,
            новая_попытка,
        )
        сам.assertEqual(
            повтор_резерва.returncode,
            0,
            повтор_резерва.stdout + повтор_резерва.stderr,
        )
        сам.assertEqual(
            json.loads(повтор_резерва.stdout)["владение"],
            "существующее",
        )

    def test_чистое_завершение_требует_подтверждённого_восстановления(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "actual-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            "created-thread-id",
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        завершение = {
            "kind": "finished_clean",
            "task_id": идентификатор_задачи,
            "generation": поколение_очереди,
            "head": str(выбор["selection_head"]),
            "completed_at": "2026-08-05T12:06:00+00:00",
        }
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
            завершение=завершение,
        )

        без_восстановления = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--json",
        )
        сам.assertEqual(
            без_восстановления.returncode,
            5,
            без_восстановления.stdout,
        )
        после_освобождения = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--adapter-recovery-state",
            "released",
            "--json",
        )
        сам.assertEqual(
            после_освобождения.returncode,
            5,
            после_освобождения.stdout + после_освобождения.stderr,
        )
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip()
        резервация = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                снимок_резервации,
            ).stdout
        )
        сам.assertNotEqual(резервация["фаза"], "завершён")

    def test_квитанция_сброса_терминализирует_резервацию_после_смены_последнего_завершения_и_ветки_пустой_очереди(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, выбор = сам.создать_репозиторий()
        попытка = str(uuid.uuid4())
        идентификатор_задачи = "actual-root-task"
        поколение_очереди = str(uuid.uuid4())
        сам.подготовить_создание(
            корень,
            реестр,
            схема,
            наблюдения,
            выбор,
            попытка,
            "created-thread-id",
        )
        привязка = сам.выполнить(
            корень,
            "bind-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        сам.assertEqual(привязка.returncode, 0, привязка.stderr)
        объект_исходной_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
        )
        проверка = сам.выполнить(
            корень,
            "verify-run",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--task-id",
            идентификатор_задачи,
            "--generation",
            поколение_очереди,
            "--json",
        )
        сам.assertEqual(проверка.returncode, 0, проверка.stderr)
        ссылка_претензии, объект_претензии = сам.записать_точную_претензию(
            корень,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        объект_претензии = (
            сам.переписать_карточочную_претензию_в_схему_четыре(
                корень,
                ссылка_претензии,
                объект_претензии,
            )
        )
        предшествующее_завершение = {
            "kind": "committed",
            "task_id": идентификатор_задачи,
            "generation": поколение_очереди,
            "base_head": str(выбор["selection_head"]),
            "head": str(выбор["selection_head"]),
            "completed_at": "2026-08-05T12:04:00+00:00",
        }
        объект_исходной_очереди = сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            идентификатор_задачи,
            поколение_очереди,
            str(выбор["selection_head"]),
            завершение=предшествующее_завершение,
        )
        каталог_версий = Path(сам.выполнить_гит(корень, "rev-parse", "--absolute-git-dir").stdout.strip()).resolve()
        идентичность = hashlib.sha256(os.path.normcase(str(каталог_версий)).encode("utf-8")).hexdigest()
        хэш_ветки = hashlib.sha256(str(выбор["branch_ref"]).encode("utf-8")).hexdigest()
        исходная_очередь = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_исходной_очереди,
            ).stdout
        )
        снимок_резервации = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        сам.assertEqual(len(снимок_резервации), 2)
        ссылка_резервации, объект_резервации = снимок_резервации

        def записать_квитанцию(
            суффикс: str,
            завершено: str,
            исходный_объект: str,
            исходное_состояние: dict[str, object],
        ) -> tuple[str, dict[str, object]]:
            идентификатор_сброса = "sha256:" + суффикс * 64
            запись_сброса = {
                "схема": "fum.сброс-состояния-FIFO.1",
                "фаза": "очистка_рабочей_копии",
                "идентификатор_рабочей_копии": идентичность,
                "ссылка_ветки": str(выбор["branch_ref"]),
                "целевая_вершина": str(выбор["selection_head"]),
                "исходный_объект_очереди": исходный_объект,
                "исходное_состояние_очереди": исходное_состояние,
                "идентификатор_сброса": идентификатор_сброса,
                "идентификатор_диспетчера": "dispatcher-task",
                "участники": [идентификатор_задачи],
                "связанные_задачи": [идентификатор_задачи],
                "неактивные_задачи": [идентификатор_задачи],
                "изменённые_пути_плана": [],
                "неотслеживаемые_пути_плана": [],
                "неотслеживаемые_объекты_плана": [],
                "отслеживаемые_объекты_плана": [],
                "отпечаток_индекса_плана": "sha256:" + "1" * 64,
                "отпечаток_изменений": "sha256:" + "0" * 64,
                "служебные_ограждения": [
                    {
                        "ссылка": ссылка_претензии,
                        "объект": объект_претензии,
                        "действие_при_завершении": "сохранить",
                    },
                    {
                        "ссылка": ссылка_резервации,
                        "объект": объект_резервации,
                        "действие_при_завершении": "сохранить",
                    },
                ],
                "создано": завершено,
                "обновлено": завершено,
            }
            объект_записи_сброса = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход=json.dumps(
                    запись_сброса,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                )
                + "\n",
            ).stdout.strip()
            завершение_сброса = {
                "kind": "reset",
                "task_id": "dispatcher-task",
                "generation": идентификатор_сброса,
                "head": str(выбор["selection_head"]),
                "completed_at": завершено,
                "аннулированные_задачи": [идентификатор_задачи],
            }
            объект_очереди_после = сам.записать_очередь(
                корень,
                str(выбор["branch_ref"]),
                идентификатор_задачи,
                поколение_очереди,
                str(выбор["selection_head"]),
                завершение=завершение_сброса,
            )
            состояние_очереди_после = json.loads(
                сам.выполнить_гит(
                    корень,
                    "cat-file",
                    "blob",
                    объект_очереди_после,
                ).stdout
            )
            квитанция = {
                "схема": "fum.квитанция-сброса-состояния-FIFO.1",
                "идентификатор_рабочей_копии": идентичность,
                "ссылка_ветки": str(выбор["branch_ref"]),
                "идентификатор_сброса": идентификатор_сброса,
                "идентификатор_диспетчера": "dispatcher-task",
                "целевая_вершина": str(выбор["selection_head"]),
                "объект_записи_сброса": объект_записи_сброса,
                "запись_сброса": запись_сброса,
                "исходный_объект_очереди": исходный_объект,
                "объект_очереди_после": объект_очереди_после,
                "состояние_очереди_после": состояние_очереди_после,
                "аннулированные_задачи": [идентификатор_задачи],
                "неактивные_задачи": [идентификатор_задачи],
                "предыдущее_завершение": исходное_состояние["last_completion"],
                "завершено": завершено,
            }
            объект_квитанции = сам.выполнить_гит(
                корень,
                "hash-object",
                "-w",
                "--stdin",
                вход=json.dumps(
                    квитанция,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                )
                + "\n",
            ).stdout.strip()
            ссылка_квитанции = (
                "refs/fum/квитанции-сброса-состояния-FIFO/"
                f"{идентичность}/{хэш_ветки}/{суффикс * 64}"
            )
            сам.выполнить_гит(
                корень,
                "update-ref",
                ссылка_квитанции,
                объект_квитанции,
            )
            return объект_очереди_после, состояние_очереди_после

        _, первая_очередь = записать_квитанцию(
            "7",
            "2026-08-05T12:06:00+00:00",
            объект_исходной_очереди,
            исходная_очередь,
        )
        пустая_очередь_прежней_ветки = json.loads(
            json.dumps(первая_очередь, ensure_ascii=False)
        )
        пустая_очередь_прежней_ветки["branch_ref"] = "refs/heads/прежняя"
        объект_пустой_очереди_прежней_ветки = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                пустая_очередь_прежней_ветки,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        записать_квитанцию(
            "8",
            "2026-08-05T12:05:30+00:00",
            объект_пустой_очереди_прежней_ветки,
            пустая_очередь_прежней_ветки,
        )
        новая_резервация = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_резервации,
            ).stdout
        )
        новая_резервация["идентификатор_созданной_задачи"] = (
            идентификатор_задачи
        )
        новая_резервация["свидетельство_среды"] = {
            "вид": "clientThreadId",
            "значение": идентификатор_задачи,
        }
        новая_резервация["task_id"] = "new-task"
        новая_резервация["generation"] = "new-generation"
        новый_объект_резервации = сам.выполнить_гит(
            корень,
            "hash-object",
            "-w",
            "--stdin",
            вход=json.dumps(
                новая_резервация,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
        ).stdout.strip()
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_резервации,
            новый_объект_резервации,
            объект_резервации,
        )
        переиспользование = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--adapter-recovery-state",
            "released",
            "--json",
        )
        сам.assertEqual(
            переиспользование.returncode,
            5,
            переиспользование.stdout + переиспользование.stderr,
        )
        сам.assertEqual(
            json.loads(переиспользование.stdout)["причина"],
            "completion_changed",
        )
        сам.выполнить_гит(
            корень,
            "update-ref",
            ссылка_резервации,
            объект_резервации,
            новый_объект_резервации,
        )
        позднее_завершение = {
            "kind": "finished_clean",
            "task_id": "later-task",
            "generation": "later-generation",
            "head": str(выбор["selection_head"]),
            "completed_at": "2026-08-05T12:07:00+00:00",
        }
        сам.записать_очередь(
            корень,
            str(выбор["branch_ref"]),
            "later-task",
            "later-generation",
            str(выбор["selection_head"]),
            завершение=позднее_завершение,
        )
        сам.выполнить_гит(
            корень,
            "commit",
            "--allow-empty",
            "-m",
            "Продвинуть ветку после квитанции сброса",
        )

        терминал = сам.выполнить(
            корень,
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(корень, выбор, попытка),
            "--adapter-recovery-state",
            "released",
            "--json",
        )

        сам.assertEqual(терминал.returncode, 0, терминал.stdout + терминал.stderr)
        сам.assertEqual(json.loads(терминал.stdout)["исход"], "успех")

    def test_возобновление_мигрирует_резервацию_одним_сравнением_и_заменой_без_повтора(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        аргументы = сам.аргументы_возобновления(
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        наблюдение = сам.закодировать_снимок_среды(
            сам.снимок_разрыва_потока(идентификатор_задачи)
        )

        первый = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *аргументы,
            "--host-readback-base64",
            наблюдение,
            "--момент",
            "2026-08-08T16:00:00Z",
            "--json",
        )
        сам.assertEqual(первый.returncode, 0, первый.stdout + первый.stderr)
        ответ = json.loads(первый.stdout)
        сам.assertEqual(
            ответ["состояние"],
            "вызов_возобновления_разрешён",
        )
        сам.assertEqual(ответ["task_id"], идентификатор_задачи)
        сам.assertEqual(ответ["host_id"], "local")
        сам.assertIn("FUM-RUNTIME: не публиковать", ответ["сообщение"])
        сам.assertIn(ответ["ключ_возобновления"], ответ["сообщение"])
        ссылка = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)",
            "refs/fum/резервации-запусков-автоматизаций/",
        ).stdout.strip()
        объект_после_первого = сам.выполнить_гит(
            корень,
            "rev-parse",
            ссылка,
        ).stdout.strip()
        резервация = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                объект_после_первого,
            ).stdout
        )
        сам.assertEqual(резервация["версия_схемы"], 4)
        сам.assertEqual(
            резервация["возобновление"]["состояние"],
            "вызов_мог_состояться",
        )
        сам.assertEqual(резервация["возобновление"]["поколение"], 1)
        сам.assertEqual(резервация["возобновление"]["предел_попыток"], 1)
        сам.assertEqual(резервация["возобновление"]["номер_попытки"], 1)
        сам.assertEqual(
            резервация["возобновление"]["причина"],
            "не_определена",
        )

        повтор = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *аргументы,
            "--host-readback-base64",
            наблюдение,
            "--момент",
            "2026-08-08T16:00:05Z",
            "--json",
        )
        сам.assertEqual(повтор.returncode, 4, повтор.stdout + повтор.stderr)
        сам.assertEqual(
            json.loads(повтор.stdout)["состояние"],
            "возобновление_уже_ограждено",
        )
        сам.assertEqual(
            сам.выполнить_гит(корень, "rev-parse", ссылка).stdout.strip(),
            объект_после_первого,
        )

    def test_конкурентное_возобновление_разрешает_ровно_одно_сообщение(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        аргументы = сам.аргументы_возобновления(
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        наблюдение = сам.закодировать_снимок_среды(
            сам.снимок_разрыва_потока(идентификатор_задачи)
        )

        def вызвать() -> subprocess.CompletedProcess[str]:
            return сам.выполнить(
                корень,
                "начать-возобновление-задачи",
                *аргументы,
                "--host-readback-base64",
                наблюдение,
                "--момент",
                "2026-08-08T16:00:00Z",
                "--json",
            )

        with ThreadPoolExecutor(max_workers=2) as исполнители:
            результаты = list(исполнители.map(lambda _: вызвать(), range(2)))
        сам.assertEqual(sorted(результат.returncode for результат in результаты), [0, 4])
        разрешённые = [
            json.loads(результат.stdout)
            for результат in результаты
            if результат.returncode == 0
        ]
        сам.assertEqual(len(разрешённые), 1)
        сам.assertIn("сообщение", разрешённые[0])

    def test_узкий_профиль_среды_закрывает_неизвестные_состояния_и_ошибки(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        аргументы = сам.аргументы_возобновления(
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        исходный = сам.снимок_разрыва_потока(идентификатор_задачи)
        случаи: list[tuple[str, dict[str, object]]] = []
        активный = json.loads(json.dumps(исходный))
        активный["thread"]["status"] = {"type": "active", "activeFlags": []}
        случаи.append(("active", активный))
        завершённый = json.loads(json.dumps(исходный))
        завершённый["turns"][0]["status"] = "completed"
        завершённый["turns"][0]["error"] = None
        случаи.append(("completed", завершённый))
        иная_ошибка = json.loads(json.dumps(исходный))
        иная_ошибка["turns"][0]["error"]["message"] = "connection reset"
        случаи.append(("иная ошибка", иная_ошибка))
        другая_задача = json.loads(json.dumps(исходный))
        другая_задача["thread"]["id"] = "other-root-task"
        случаи.append(("другая задача", другая_задача))
        другой_узел_среды = json.loads(json.dumps(исходный))
        другой_узел_среды["thread"]["hostId"] = "other-host"
        случаи.append(("другой host", другой_узел_среды))
        лишнее_поле = json.loads(json.dumps(исходный))
        лишнее_поле["unexpected"] = True
        случаи.append(("лишнее поле", лишнее_поле))
        логическая_схема = json.loads(json.dumps(исходный))
        логическая_схема["schemaVersion"] = True
        случаи.append(("логическая версия схемы", логическая_схема))
        логический_предел = json.loads(json.dumps(исходный))
        логический_предел["page"]["limit"] = True
        случаи.append(("логический предел страницы", логический_предел))

        for название, снимок in случаи:
            with сам.subTest(название=название):
                результат = сам.выполнить(
                    корень,
                    "начать-возобновление-задачи",
                    *аргументы,
                    "--host-readback-base64",
                    сам.закодировать_снимок_среды(снимок),
                    "--момент",
                    "2026-08-08T16:00:00Z",
                    "--json",
                )
                сам.assertNotEqual(результат.returncode, 0, результат.stdout)

    def test_длинные_непрозрачные_элементы_снимка_не_сужают_явный_предел(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        снимок = сам.снимок_разрыва_потока(идентификатор_задачи)
        снимок["turns"][0]["items"] = [{"непрозрачное": "я" * 2_000}]
        закодированный = сам.закодировать_снимок_среды(снимок)
        сам.assertGreater(len(закодированный), 1_024)

        результат = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *сам.аргументы_возобновления(
                корень,
                реестр,
                схема,
                выбор,
                попытка,
                идентификатор_задачи,
                поколение_очереди,
            ),
            "--host-readback-base64",
            закодированный,
            "--момент",
            "2026-08-08T16:00:00Z",
            "--json",
        )

        сам.assertEqual(результат.returncode, 0, результат.stdout + результат.stderr)

    def test_подтверждение_требует_точный_процессный_идентификатор_задачи(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        аргументы = сам.аргументы_возобновления(
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        начало = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *аргументы,
            "--host-readback-base64",
            сам.закодировать_снимок_среды(
                сам.снимок_разрыва_потока(идентификатор_задачи)
            ),
            "--момент",
            "2026-08-08T16:00:00Z",
            "--json",
        )
        сам.assertEqual(начало.returncode, 0, начало.stdout + начало.stderr)
        ключ = json.loads(начало.stdout)["ключ_возобновления"]
        ссылка, исходный_объект = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        среды: list[tuple[str, dict[str, str]]] = []
        без_идентификатора = dict(os.environ)
        без_идентификатора.pop("CODEX_THREAD_ID", None)
        среды.append(("отсутствующий", без_идентификатора))
        чужой_идентификатор = dict(os.environ)
        чужой_идентификатор["CODEX_THREAD_ID"] = "чужая-задача"
        среды.append(("чужой", чужой_идентификатор))

        for название, среда in среды:
            with сам.subTest(название=название):
                подтверждение = сам.выполнить(
                    корень,
                    "подтвердить-возобновление-задачи",
                    *аргументы,
                    "--ключ-возобновления",
                    ключ,
                    "--момент",
                    "2026-08-08T16:00:10Z",
                    "--json",
                    среда=среда,
                )
                сам.assertNotEqual(подтверждение.returncode, 0)
                сам.assertEqual(
                    сам.выполнить_гит(
                        корень,
                        "rev-parse",
                        ссылка,
                    ).stdout.strip(),
                    исходный_объект,
                )

    def test_внутренняя_схема_возобновления_не_принимает_логические_числа(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        начало = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *сам.аргументы_возобновления(
                корень,
                реестр,
                схема,
                выбор,
                попытка,
                идентификатор_задачи,
                поколение_очереди,
            ),
            "--host-readback-base64",
            сам.закодировать_снимок_среды(
                сам.снимок_разрыва_потока(идентификатор_задачи)
            ),
            "--момент",
            "2026-08-08T16:00:00Z",
            "--json",
        )
        сам.assertEqual(начало.returncode, 0, начало.stdout + начало.stderr)
        ссылка, исходный_объект = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)%00%(objectname)",
            "refs/fum/резервации-запусков-автоматизаций",
        ).stdout.strip().split("\0")
        исходная_резервация = json.loads(
            сам.выполнить_гит(
                корень,
                "cat-file",
                "blob",
                исходный_объект,
            ).stdout
        )
        пути = (
            ("версия возобновления", ("возобновление", "версия_схемы")),
            ("номер попытки", ("возобновление", "номер_попытки")),
            (
                "версия наблюдения",
                ("возобновление", "наблюдение", "версия_схемы_среды"),
            ),
            (
                "версия конверта",
                ("возобновление", "конверт", "версия_схемы"),
            ),
        )

        for название, путь in пути:
            with сам.subTest(название=название):
                повреждённая = json.loads(json.dumps(исходная_резервация))
                узел = повреждённая
                for часть in путь[:-1]:
                    узел = узел[часть]
                узел[путь[-1]] = True
                повреждённый_объект = сам.выполнить_гит(
                    корень,
                    "hash-object",
                    "-w",
                    "--stdin",
                    вход=json.dumps(
                        повреждённая,
                        ensure_ascii=False,
                        sort_keys=True,
                        separators=(",", ":"),
                    )
                    + "\n",
                ).stdout.strip()
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка,
                    повреждённый_объект,
                    исходный_объект,
                )
                состояние = сам.выполнить(
                    корень,
                    "состояние-резервации",
                    "--корень-рабочей-копии",
                    str(корень),
                    "--expected-branch-ref",
                    str(выбор["branch_ref"]),
                    "--expected-job-id",
                    str(выбор["job_id"]),
                    "--json",
                )
                сам.assertNotEqual(состояние.returncode, 0, состояние.stdout)
                сам.выполнить_гит(
                    корень,
                    "update-ref",
                    ссылка,
                    исходный_объект,
                    повреждённый_объект,
                )

    def test_подтверждение_допускает_грязную_копию_и_открывает_новый_ход(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        аргументы = сам.аргументы_возобновления(
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        первое_наблюдение = сам.закодировать_снимок_среды(
            сам.снимок_разрыва_потока(идентификатор_задачи)
        )
        начало = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *аргументы,
            "--host-readback-base64",
            первое_наблюдение,
            "--момент",
            "2026-08-08T16:00:00Z",
            "--json",
        )
        сам.assertEqual(начало.returncode, 0, начало.stdout + начало.stderr)
        ключ = json.loads(начало.stdout)["ключ_возобновления"]
        (корень / "незавершённая-работа.txt").write_text(
            "рабочая копия намеренно грязная\n",
            encoding="utf-8",
        )
        подтверждение = сам.выполнить(
            корень,
            "подтвердить-возобновление-задачи",
            *аргументы,
            "--ключ-возобновления",
            ключ,
            "--момент",
            "2026-08-08T16:00:10Z",
            "--json",
            среда={**os.environ, "CODEX_THREAD_ID": идентификатор_задачи},
        )
        сам.assertEqual(
            подтверждение.returncode,
            0,
            подтверждение.stdout + подтверждение.stderr,
        )
        сам.assertEqual(
            json.loads(подтверждение.stdout)["состояние"],
            "возобновление_подтверждено",
        )
        повтор_подтверждения = сам.выполнить(
            корень,
            "подтвердить-возобновление-задачи",
            *аргументы,
            "--ключ-возобновления",
            ключ,
            "--момент",
            "2026-08-08T16:00:11Z",
            "--json",
            среда={**os.environ, "CODEX_THREAD_ID": идентификатор_задачи},
        )
        сам.assertEqual(повтор_подтверждения.returncode, 0)
        сам.assertEqual(
            json.loads(повтор_подтверждения.stdout)["владение"],
            "существующее",
        )

        второе_наблюдение = сам.закодировать_снимок_среды(
            сам.снимок_разрыва_потока(
                идентификатор_задачи,
                состояние="notLoaded",
                идентификатор_хода="turn-transport-failure-2",
                начало=1_786_195_963,
                завершение=1_786_195_970,
            )
        )
        второе = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *аргументы,
            "--host-readback-base64",
            второе_наблюдение,
            "--момент",
            "2026-08-08T16:01:00Z",
            "--json",
        )
        сам.assertEqual(второе.returncode, 0, второе.stdout + второе.stderr)
        сам.assertNotEqual(
            json.loads(второе.stdout)["ключ_возобновления"],
            ключ,
        )
        ссылка = сам.выполнить_гит(
            корень,
            "for-each-ref",
            "--format=%(refname)",
            "refs/fum/резервации-запусков-автоматизаций/",
        ).stdout.strip()
        резервация = json.loads(
            сам.выполнить_гит(корень, "cat-file", "blob", ссылка).stdout
        )
        сам.assertEqual(резервация["возобновление"]["поколение"], 2)

    def test_возобновление_закрывается_при_дрейфе_очереди_претензии_вершины_или_адаптера(
        сам,
    ) -> None:
        for вид_дрейфа in ("FIFO", "claim", "HEAD", "адаптер"):
            with сам.subTest(вид_дрейфа=вид_дрейфа):
                (
                    корень,
                    реестр,
                    схема,
                    выбор,
                    попытка,
                    идентификатор_задачи,
                    поколение_очереди,
                ) = сам.подготовить_точное_возобновление(
                    иной_адаптер=вид_дрейфа == "адаптер"
                )
                if вид_дрейфа == "FIFO":
                    сам.записать_очередь(
                        корень,
                        str(выбор["branch_ref"]),
                        "other-root-task",
                        поколение_очереди,
                        str(выбор["selection_head"]),
                    )
                elif вид_дрейфа == "claim":
                    сам.записать_точную_претензию(
                        корень,
                        выбор,
                        попытка,
                        идентификатор_задачи,
                        "other-generation",
                    )
                elif вид_дрейфа == "HEAD":
                    сам.выполнить_гит(
                        корень,
                        "commit",
                        "--allow-empty",
                        "-m",
                        "Сдвинуть вершину во время восстановления",
                    )
                результат = сам.выполнить(
                    корень,
                    "начать-возобновление-задачи",
                    *сам.аргументы_возобновления(
                        корень,
                        реестр,
                        схема,
                        выбор,
                        попытка,
                        идентификатор_задачи,
                        поколение_очереди,
                    ),
                    "--host-readback-base64",
                    сам.закодировать_снимок_среды(
                        сам.снимок_разрыва_потока(идентификатор_задачи)
                    ),
                    "--момент",
                    "2026-08-08T16:00:00Z",
                    "--json",
                )
                сам.assertNotEqual(результат.returncode, 0, результат.stdout)

    def test_ожидающее_возобновление_блокирует_терминализацию_общего_запуска(
        сам,
    ) -> None:
        (
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        ) = сам.подготовить_точное_возобновление()
        аргументы = сам.аргументы_возобновления(
            корень,
            реестр,
            схема,
            выбор,
            попытка,
            идентификатор_задачи,
            поколение_очереди,
        )
        начало = сам.выполнить(
            корень,
            "начать-возобновление-задачи",
            *аргументы,
            "--host-readback-base64",
            сам.закодировать_снимок_среды(
                сам.снимок_разрыва_потока(идентификатор_задачи)
            ),
            "--момент",
            "2026-08-08T16:00:00Z",
            "--json",
        )
        сам.assertEqual(начало.returncode, 0, начало.stdout + начало.stderr)
        завершение = сам.выполнить(
            корень,
            "завершить",
            "--корень-рабочей-копии",
            str(корень),
            "--expected-branch-ref",
            str(выбор["branch_ref"]),
            "--expected-job-id",
            str(выбор["job_id"]),
            "--expected-run-key",
            str(выбор["run_key"]),
            "--идентификатор-попытки",
            попытка,
            "--исход",
            "неопределённый",
            "--json",
        )
        сам.assertEqual(завершение.returncode, 5, завершение.stdout)
        сам.assertEqual(
            json.loads(завершение.stdout)["причина"],
            "возобновление_не_подтверждено",
        )

    def test_сквозная_композиция_проходит_претензию_очередь_и_аналитический_порог(
        сам,
    ) -> None:
        корень, реестр, схема, наблюдения, _ = сам.создать_репозиторий()
        каталог_карточек = корень / "Планирование" / "карточки-шагов"
        путь_второй_карточки = (
            каталог_карточек / "🟡-FUM-STEP-0143-проверить-следующий-шаг.md"
        )
        путь_второй_карточки.write_text(
            "+++\n"
            "schema_version = 1\n"
            'card_id = "FUM-STEP-0143"\n'
            'status = "active"\n'
            "+++\n"
            "# Проверить следующий независимый шаг\n\n"
            "Эта карточка доказывает продвижение очереди.\n\n"
            "## Задача\n\n"
            "Продолжить фикстурную очередь после завершённой карточки.\n\n"
            "## Почему сейчас\n\n"
            "Предшественник должен завершиться без повторной задачи.\n\n"
            "## Критерии завершения\n\n"
            "- Предшественник имеет status=completed.\n"
            "- Выбор не возвращает прежнюю карточку.\n\n"
            "## Источники\n\n"
            "- [Тестовый проект](../../README.md)\n",
            encoding="utf-8",
        )
        хэш_второй_карточки = "sha256:" + hashlib.sha256(
            путь_второй_карточки.read_bytes()
        ).hexdigest()
        путь_селектора = (
            корень / "Планирование" / "следующие-шаги-веток" / "master.md"
        )
        текст_селектора = путь_селектора.read_text(encoding="utf-8")
        маркер_конца_кандидата = "requires_completed_card_ids = []\n+++\n"
        сам.assertEqual(текст_селектора.count(маркер_конца_кандидата), 1)
        второй_кандидат = (
            "requires_completed_card_ids = []\n\n"
            "[[candidates]]\n"
            'step_id = "master-fum-step-0143-automatic-v1"\n'
            'dispatch = "automatic"\n'
            'card_id = "FUM-STEP-0143"\n'
            f'card_content_sha256 = "{хэш_второй_карточки}"\n'
            'requires_completed_card_ids = ["FUM-STEP-0142"]\n'
            "+++\n"
        )
        путь_селектора.write_text(
            текст_селектора.replace(
                маркер_конца_кандидата,
                второй_кандидат,
            ),
            encoding="utf-8",
        )
        путь_очереди = корень / ПУТЬ_СЦЕНАРИЯ_ОЧЕРЕДИ_В_РЕПОЗИТОРИИ
        путь_очереди.parent.mkdir(parents=True, exist_ok=True)
        путь_очереди.write_bytes(СЦЕНАРИЙ_ОЧЕРЕДИ.read_bytes())

        значение_реестра = json.loads(реестр.read_text(encoding="utf-8"))
        шаблон = deepcopy(значение_реестра["задания"][0])

        def создать_неактивное_задание(
            идентификатор: str,
            состояние: str,
            приоритет: int,
        ) -> dict[str, object]:
            задание = deepcopy(шаблон)
            задание["job_id"] = идентификатор
            задание["приоритет"] = приоритет
            задание["адаптер"] = {
                "контракт": "пробник-без-эффекта.1",
                "тип": "пробник_расписания",
            }
            задание["условия_допуска"] = []
            задание["состояние"] = состояние
            задание["эффект"] = {
                "класс": "только_чтение",
                "политика": "без_побочных_эффектов",
            }
            задание["исполнитель"] = {
                "контракт": "локальный-симулятор.1",
                "тип": "локальный_пробник",
            }
            задание["политика_ошибки"]["повтор"] = "вручную"
            return задание

        значение_реестра["поколение_реестра"] = 4
        значение_реестра["задания"].extend(
            [
                создать_неактивное_задание(
                    "master.acceptance-paused",
                    "paused",
                    20,
                ),
                создать_неактивное_задание(
                    "master.acceptance-blocked",
                    "blocked",
                    30,
                ),
            ]
        )
        сам.записать_объект(реестр, значение_реестра)
        сам.выполнить_гит(
            корень,
            "add",
            "--",
            str(реестр.relative_to(корень)),
            str(путь_второй_карточки.relative_to(корень)),
            str(путь_селектора.relative_to(корень)),
            str(путь_очереди.relative_to(корень)),
        )
        сам.выполнить_гит(
            корень,
            "commit",
            "-m",
            "Создать сквозную фикстуру выполнения",
        )
        устаревший_выбор = сам.выбрать(
            корень,
            реестр,
            схема,
            наблюдения,
        )
        сам.assertEqual(устаревший_выбор["job_id"], "master.next-step")
        сам.assertEqual(
            {
                задание["job_id"]
                for задание in значение_реестра["задания"]
            },
            {
                "master.next-step",
                "master.completed-step-analysis",
                "master.acceptance-paused",
                "master.acceptance-blocked",
            },
        )

        симуляция = сам.выполнить(
            корень,
            "симулировать",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            "--наблюдения",
            str(наблюдения),
            "--json",
        )
        данные_симуляции = сам.данные_успешного_процесса(симуляция)
        статусы = {
            задание["job_id"]: задание["статус"]
            for задание in данные_симуляции["задания"]
        }
        сам.assertEqual(
            статусы["master.acceptance-paused"],
            "приостановлено",
        )
        сам.assertEqual(
            статусы["master.acceptance-blocked"],
            "заблокировано",
        )

        внешний_каталог = tempfile.TemporaryDirectory()
        сам.addCleanup(внешний_каталог.cleanup)
        путь_предложения = Path(внешний_каталог.name) / "предложение.json"
        управляющая_задача = str(uuid.uuid4())
        допуск_управления = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                "join",
                "--task-id",
                управляющая_задача,
            )
        )
        поколение_управления = str(допуск_управления["generation"])
        сам.assertEqual(
            допуск_управления["base_head"],
            устаревший_выбор["selection_head"],
        )

        аналитическое_задание = next(
            задание
            for задание in значение_реестра["задания"]
            if задание["job_id"] == "master.completed-step-analysis"
        )
        новый_триггер = deepcopy(аналитическое_задание["триггер"])
        новый_триггер["каждые"] = 1
        новый_курсор = deepcopy(
            аналитическое_задание["курсор_результата"]
        )
        новый_курсор["следующий_порог"] = 1
        данные_намерения = {
            "job_id": "master.completed-step-analysis",
            "триггер": новый_триггер,
            "курсор_результата": новый_курсор,
            "политика_накопленного_остатка": (
                "сохранить_все_непроанализированные_события"
            ),
        }
        процесс_предложения = сам.выполнить(
            корень,
            "предложить-изменение",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема",
            str(схема),
            "--схема-предложения",
            str(СХЕМА_ПРЕДЛОЖЕНИЯ),
            "--намерение",
            "изменить_триггер",
            "--данные-json",
            json.dumps(данные_намерения, ensure_ascii=False),
            "--message-id",
            "сообщение-сквозной-приёмки-001",
            "--message-sha256",
            "sha256:" + "c" * 64,
            "--expected-selection-head",
            str(устаревший_выбор["selection_head"]),
            "--expected-registry-generation",
            "4",
            "--json",
        )
        предложение = сам.данные_успешного_процесса(
            процесс_предложения
        )
        сам.записать_объект(путь_предложения, предложение)
        начало_управления = сам.выполнить(
            корень,
            "начать-управление",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема-предложения",
            str(СХЕМА_ПРЕДЛОЖЕНИЯ),
            "--предложение",
            str(путь_предложения),
            "--task-id",
            управляющая_задача,
            "--generation",
            поколение_управления,
            "--json",
        )
        сам.данные_успешного_процесса(начало_управления)

        попытка_устаревшего_запуска = str(uuid.uuid4())
        устаревшая_резервация = сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(
                корень,
                реестр,
                схема,
                наблюдения,
                устаревший_выбор,
            ),
            "--идентификатор-попытки",
            попытка_устаревшего_запуска,
            "--json",
        )
        сам.assertEqual(устаревшая_резервация.returncode, 4)
        сам.assertEqual(
            json.loads(устаревшая_резервация.stdout),
            {"состояние": "уже_зарезервировано"},
        )

        применение = сам.выполнить(
            корень,
            "применить-предложение",
            "--корень-рабочей-копии",
            str(корень),
            "--реестр",
            str(реестр),
            "--схема-предложения",
            str(СХЕМА_ПРЕДЛОЖЕНИЯ),
            "--предложение",
            str(путь_предложения),
            "--task-id",
            управляющая_задача,
            "--generation",
            поколение_управления,
            "--подтверждение",
            "применить:" + str(предложение["идентификатор_предложения"]),
            "--json",
        )
        сам.assertEqual(
            сам.данные_успешного_процесса(применение)["состояние"],
            "применено",
        )
        сам.выполнить_гит(
            корень,
            "add",
            "--",
            str(реестр.relative_to(корень)),
        )
        передача_управления = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                "commit",
                "--task-id",
                управляющая_задача,
                "--generation",
                поколение_управления,
                "--message",
                "Применить управление порогом аналитики",
            )
        )
        сам.assertEqual(
            передача_управления["old_head"],
            устаревший_выбор["selection_head"],
        )
        повтор_устаревшей_резервации = сам.выполнить(
            корень,
            "зарезервировать",
            *сам.аргументы_выбора(
                корень,
                реестр,
                схема,
                наблюдения,
                устаревший_выбор,
            ),
            "--идентификатор-попытки",
            попытка_устаревшего_запуска,
            "--json",
        )
        сам.assertEqual(повтор_устаревшей_резервации.returncode, 2)
        сам.assertEqual(
            json.loads(повтор_устаревшей_резервации.stdout),
            {
                "состояние": "некорректен",
                "ошибка": "ожидаемый выбор задания изменился",
            },
        )
        отсутствие_устаревшего_запуска = сам.данные_успешного_процесса(
            сам.выполнить(
                корень,
                "состояние-резервации",
                "--корень-рабочей-копии",
                str(корень),
                "--expected-branch-ref",
                "refs/heads/master",
                "--expected-job-id",
                "master.next-step",
                "--json",
            )
        )
        сам.assertEqual(
            отсутствие_устаревшего_запуска["состояние"],
            "отсутствует",
        )
        свежий_выбор = сам.выбрать(корень, реестр, схема, наблюдения)
        сам.assertEqual(свежий_выбор["job_id"], "master.next-step")
        сам.assertEqual(свежий_выбор["поколение_реестра"], 5)

        def снимок_планового_тика() -> tuple[str, str, str, str, str]:
            путь_индекса = корень / ".git" / "index"
            return (
                сам.выполнить_гит(
                    корень,
                    "rev-parse",
                    "HEAD",
                ).stdout,
                hashlib.sha256(путь_индекса.read_bytes()).hexdigest(),
                сам.выполнить_гит(
                    корень,
                    "diff",
                    "--no-ext-diff",
                    "--no-textconv",
                    "--binary",
                    "--",
                ).stdout,
                сам.выполнить_гит(
                    корень,
                    "ls-files",
                    "--others",
                    "--exclude-standard",
                    "-z",
                ).stdout,
                сам.выполнить_гит(
                    корень,
                    "for-each-ref",
                    "--format=%(refname) %(objectname)",
                ).stdout,
            )

        снимок_до_тика = снимок_планового_тика()
        повтор_чистого_выбора = сам.выбрать(
            корень,
            реестр,
            схема,
            наблюдения,
        )
        сам.assertEqual(повтор_чистого_выбора, свежий_выбор)
        сам.assertEqual(снимок_планового_тика(), снимок_до_тика)

        попытка_шага = str(uuid.uuid4())
        общие_аргументы_шага = сам.аргументы_выбора(
            корень,
            реестр,
            схема,
            наблюдения,
            свежий_выбор,
        )
        for ожидаемое_владение in ("новое", "существующее"):
            резерв = сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    "зарезервировать",
                    *общие_аргументы_шага,
                    "--идентификатор-попытки",
                    попытка_шага,
                    "--json",
                )
            )
            сам.assertEqual(резерв["владение"], ожидаемое_владение)

        карточочный_показ = сам.показать_специализированный_выбор(корень)
        карточочный_выбор = dict(карточочный_показ["selection"])
        сам.assertEqual(
            карточочный_выбор["head"],
            свежий_выбор["selection_head"],
        )
        аргументы_претензии_шага = (
            "claim",
            "--expected-branch-ref",
            str(карточочный_показ["branch_ref"]),
            "--expected-step-id",
            str(карточочный_показ["step_id"]),
            "--expected-selection-id",
            str(карточочный_выбор["id"]),
            "--lease-id",
            попытка_шага,
            "--repo-root",
            str(корень),
            "--json",
        )
        for ожидаемое_владение in ("new", "existing"):
            претензия_шага = сам.данные_успешного_процесса(
                сам.выполнить_следующий_шаг(
                    корень,
                    *аргументы_претензии_шага,
                )
            )
            сам.assertEqual(
                претензия_шага["ownership"],
                ожидаемое_владение,
            )

        граница_среды = сам.выполнить(
            корень,
            "начать-вызов-среды",
            *общие_аргументы_шага,
            "--идентификатор-попытки",
            попытка_шага,
            "--json",
        )
        сам.данные_успешного_процесса(граница_среды)
        состояние_после_неоднозначного_ответа = (
            сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    "состояние-резервации",
                    "--корень-рабочей-копии",
                    str(корень),
                    "--expected-branch-ref",
                    str(свежий_выбор["branch_ref"]),
                    "--expected-job-id",
                    str(свежий_выбор["job_id"]),
                    "--json",
                )
            )
        )
        сам.assertEqual(
            состояние_после_неоднозначного_ответа["фаза"],
            "вызов_мог_состояться",
        )

        задача_шага = str(uuid.uuid4())
        свидетельство_среды_шага = uuid.uuid4().hex
        for ожидаемое_владение in ("новое", "существующее"):
            подтверждение = сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    "подтвердить-создание",
                    *сам.аргументы_ограждения_запуска(
                        корень,
                        свежий_выбор,
                        попытка_шага,
                    ),
                    "--thread-id",
                    задача_шага,
                    "--host-id",
                    свидетельство_среды_шага,
                    "--json",
                )
            )
            сам.assertEqual(
                подтверждение["владение"],
                ожидаемое_владение,
            )

        допуск_шага = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                "join",
                "--task-id",
                задача_шага,
            )
        )
        поколение_шага = str(допуск_шага["generation"])
        сам.assertEqual(
            допуск_шага["base_head"],
            свежий_выбор["selection_head"],
        )
        повтор_допуска_шага = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                "join",
                "--task-id",
                задача_шага,
            )
        )
        сам.assertEqual(
            повтор_допуска_шага["generation"],
            поколение_шага,
        )

        общая_привязка = (
            "bind-run",
            *сам.аргументы_ограждения_запуска(
                корень,
                свежий_выбор,
                попытка_шага,
            ),
            "--task-id",
            задача_шага,
            "--json",
        )
        общая_проверка = (
            "verify-run",
            *сам.аргументы_ограждения_запуска(
                корень,
                свежий_выбор,
                попытка_шага,
            ),
            "--task-id",
            задача_шага,
            "--generation",
            поколение_шага,
            "--json",
        )
        for аргументы in (общая_привязка, общая_проверка):
            for _ in range(2):
                сам.данные_успешного_процесса(
                    сам.выполнить(корень, *аргументы)
                )

        карточочная_привязка = (
            "bind-run",
            "--expected-branch-ref",
            str(карточочный_показ["branch_ref"]),
            "--expected-step-id",
            str(карточочный_показ["step_id"]),
            "--expected-selection-id",
            str(карточочный_выбор["id"]),
            "--expected-lease-id",
            попытка_шага,
            "--task-id",
            задача_шага,
            "--repo-root",
            str(корень),
            "--json",
        )
        карточочная_проверка = (
            "verify-run",
            "--expected-branch-ref",
            str(карточочный_показ["branch_ref"]),
            "--expected-step-id",
            str(карточочный_показ["step_id"]),
            "--expected-selection-id",
            str(карточочный_выбор["id"]),
            "--expected-lease-id",
            попытка_шага,
            "--task-id",
            задача_шага,
            "--generation",
            поколение_шага,
            "--repo-root",
            str(корень),
            "--json",
        )
        for аргументы in (карточочная_привязка, карточочная_проверка):
            for _ in range(2):
                сам.данные_успешного_процесса(
                    сам.выполнить_следующий_шаг(корень, *аргументы)
                )

        путь_активной_карточки = корень / str(карточочный_показ["card_path"])
        текст_активной_карточки = путь_активной_карточки.read_text(
            encoding="utf-8"
        )
        сам.assertEqual(текст_активной_карточки.count('status = "active"'), 1)
        путь_завершённой_карточки = путь_активной_карточки.with_name(
            путь_активной_карточки.name.replace("🟡-", "✅-", 1)
        )
        сам.assertEqual(текст_активной_карточки.count("\n## Источники\n"), 1)
        текст_завершённой_карточки = текст_активной_карточки.replace(
            'status = "active"',
            'status = "completed"',
        ).replace(
            "\n## Источники\n",
            "\n## Результат\n\n"
            "Фикстурный результат сохранён одним ограждённым "
            "локальным коммитом и передачей.\n\n"
            "## Источники\n",
        )
        путь_активной_карточки.rename(путь_завершённой_карточки)
        путь_завершённой_карточки.write_text(
            текст_завершённой_карточки,
            encoding="utf-8",
        )
        блок_первого_кандидата = (
            "[[candidates]]\n"
            'step_id = "master-fum-step-0142-automatic-v5"\n'
            'dispatch = "automatic"\n'
            'card_id = "FUM-STEP-0142"\n'
            f'card_content_sha256 = "{карточочный_показ["card_content_sha256"]}"\n'
            "requires_completed_card_ids = []\n\n"
        )
        текст_селектора = путь_селектора.read_text(encoding="utf-8")
        сам.assertEqual(текст_селектора.count(блок_первого_кандидата), 1)
        путь_селектора.write_text(
            текст_селектора.replace(блок_первого_кандидата, ""),
            encoding="utf-8",
        )
        (корень / "результат-сквозного-шага.txt").write_text(
            "готово\n",
            encoding="utf-8",
        )
        сам.выполнить_гит(
            корень,
            "add",
            "--all",
            "--",
            "результат-сквозного-шага.txt",
            str(путь_активной_карточки.relative_to(корень)),
            str(путь_завершённой_карточки.relative_to(корень)),
            str(путь_селектора.relative_to(корень)),
        )
        аргументы_коммита_шага = (
            "commit",
            "--task-id",
            задача_шага,
            "--generation",
            поколение_шага,
            "--message",
            "Завершить сквозной карточочный шаг",
        )
        передача_шага = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                *аргументы_коммита_шага,
            )
        )
        повтор_передачи_шага = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                *аргументы_коммита_шага,
            )
        )
        сам.assertEqual(
            повтор_передачи_шага["new_head"],
            передача_шага["new_head"],
        )

        аргументы_терминала_шага = (
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(
                корень,
                свежий_выбор,
                попытка_шага,
            ),
            "--json",
        )
        for ожидаемое_владение in ("новое", "существующее"):
            терминал = сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    *аргументы_терминала_шага,
                )
            )
            сам.assertEqual(терминал["исход"], "успех")
            сам.assertEqual(
                терминал["владение"],
                ожидаемое_владение,
            )

        наблюдение_журнала = сам.данные_успешного_процесса(
            сам.выполнить_аналитику(
                корень,
                "наблюдать",
                "--корень-рабочей-копии",
                str(корень),
                "--expected-branch-ref",
                "refs/heads/master",
                "--json",
            )
        )
        сам.assertEqual(
            наблюдение_журнала["число_подтверждённых_событий"],
            1,
        )
        сам.assertEqual(сам.выполнить_гит(корень, "remote").stdout, "")
        следующий_карточочный_показ = сам.показать_специализированный_выбор(корень)
        сам.assertEqual(следующий_карточочный_показ["state"], "ready")
        сам.assertEqual(следующий_карточочный_показ["card_id"], "FUM-STEP-0143")
        сам.assertNotEqual(
            следующий_карточочный_показ["card_id"],
            карточочный_показ["card_id"],
        )

        наблюдения_после_шага = json.loads(
            наблюдения.read_text(encoding="utf-8")
        )
        наблюдения_после_шага["момент"] = "2026-08-05T12:10:00Z"
        наблюдения_после_шага["подтверждённые_события"] = {
            "завершение_runtime_ready_commit_handoff": 1,
        }
        путь_новых_наблюдений = (
            Path(внешний_каталог.name) / "наблюдения-после-шага.json"
        )
        сам.записать_объект(
            путь_новых_наблюдений,
            наблюдения_после_шага,
        )
        аналитический_выбор = сам.выбрать(
            корень,
            реестр,
            схема,
            путь_новых_наблюдений,
        )
        сам.assertEqual(
            аналитический_выбор["job_id"],
            "master.completed-step-analysis",
        )
        сам.assertEqual(аналитический_выбор["число_готовых"], 2)

        попытка_аналитики = str(uuid.uuid4())
        общие_аргументы_аналитики = сам.аргументы_выбора(
            корень,
            реестр,
            схема,
            путь_новых_наблюдений,
            аналитический_выбор,
        )
        for ожидаемое_владение in ("новое", "существующее"):
            резерв = сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    "зарезервировать",
                    *общие_аргументы_аналитики,
                    "--идентификатор-попытки",
                    попытка_аналитики,
                    "--json",
                )
            )
            сам.assertEqual(резерв["владение"], ожидаемое_владение)

        показ_аналитики = сам.данные_успешного_процесса(
            сам.выполнить_аналитику(
                корень,
                "показать",
                "--корень-рабочей-копии",
                str(корень),
                "--реестр",
                str(реестр),
                "--схема",
                str(схема),
                "--expected-job-id",
                "master.completed-step-analysis",
                "--json",
            )
        )
        сам.assertEqual(показ_аналитики["state"], "ready")
        сам.assertEqual(показ_аналитики["порог"], 1)

        первая_претензия: dict[str, object] | None = None
        for ожидаемое_владение in ("new", "existing"):
            претензия_процесса = сам.данные_успешного_процесса(
                сам.выполнить_аналитику(
                    корень,
                    *сам.аргументы_аналитической_претензии(
                        корень,
                        реестр,
                        схема,
                        аналитический_выбор,
                        попытка_аналитики,
                    ),
                )
            )
            сам.assertEqual(
                претензия_процесса["ownership"],
                ожидаемое_владение,
            )
            if первая_претензия is None:
                первая_претензия = претензия_процесса
        сам.assertIsNotNone(первая_претензия)
        претензия = dict(первая_претензия)

        сам.данные_успешного_процесса(
            сам.выполнить(
                корень,
                "начать-вызов-среды",
                *общие_аргументы_аналитики,
                "--идентификатор-попытки",
                попытка_аналитики,
                "--json",
            )
        )
        задача_аналитики = str(uuid.uuid4())
        свидетельство_среды_аналитики = uuid.uuid4().hex
        for ожидаемое_владение in ("новое", "существующее"):
            подтверждение = сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    "подтвердить-создание",
                    *сам.аргументы_ограждения_запуска(
                        корень,
                        аналитический_выбор,
                        попытка_аналитики,
                    ),
                    "--thread-id",
                    задача_аналитики,
                    "--host-id",
                    свидетельство_среды_аналитики,
                    "--json",
                )
            )
            сам.assertEqual(
                подтверждение["владение"],
                ожидаемое_владение,
            )

        допуск_аналитики = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                "join",
                "--task-id",
                задача_аналитики,
            )
        )
        поколение_аналитики = str(допуск_аналитики["generation"])
        сам.assertEqual(
            допуск_аналитики["base_head"],
            аналитический_выбор["selection_head"],
        )
        повтор_допуска_аналитики = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                "join",
                "--task-id",
                задача_аналитики,
            )
        )
        сам.assertEqual(
            повтор_допуска_аналитики["generation"],
            поколение_аналитики,
        )

        общая_привязка_аналитики = (
            "bind-run",
            *сам.аргументы_ограждения_запуска(
                корень,
                аналитический_выбор,
                попытка_аналитики,
            ),
            "--task-id",
            задача_аналитики,
            "--json",
        )
        общая_проверка_аналитики = (
            "verify-run",
            *сам.аргументы_ограждения_запуска(
                корень,
                аналитический_выбор,
                попытка_аналитики,
            ),
            "--task-id",
            задача_аналитики,
            "--generation",
            поколение_аналитики,
            "--json",
        )
        for аргументы in (
            общая_привязка_аналитики,
            общая_проверка_аналитики,
        ):
            for _ in range(2):
                сам.данные_успешного_процесса(
                    сам.выполнить(корень, *аргументы)
                )

        порог = str(
            dict(аналитический_выбор["trigger_occurrence"])["конец"]
        )
        аналитическое_ограждение = (
            "--корень-рабочей-копии",
            str(корень),
            "--expected-branch-ref",
            str(аналитический_выбор["branch_ref"]),
            "--expected-selection-head",
            str(аналитический_выбор["selection_head"]),
            "--expected-job-id",
            str(аналитический_выбор["job_id"]),
            "--expected-spec-generation",
            str(аналитический_выбор["spec_generation"]),
            "--expected-registry-generation",
            str(аналитический_выбор["поколение_реестра"]),
            "--expected-run-key",
            str(аналитический_выбор["run_key"]),
            "--expected-threshold",
            порог,
            "--expected-lease-id",
            попытка_аналитики,
            "--task-id",
            задача_аналитики,
        )
        аналитическая_привязка = (
            "bind-run",
            *аналитическое_ограждение,
            "--json",
        )
        аналитическая_проверка = (
            "verify-run",
            *аналитическое_ограждение,
            "--generation",
            поколение_аналитики,
            "--json",
        )
        for аргументы in (
            аналитическая_привязка,
            аналитическая_проверка,
        ):
            for _ in range(2):
                сам.данные_успешного_процесса(
                    сам.выполнить_аналитику(корень, *аргументы)
                )

        путь_отчёта = корень / str(претензия["путь_отчёта"])
        путь_отчёта.parent.mkdir(parents=True, exist_ok=True)
        путь_отчёта.write_text(
            "# Аналитическая ревизия завершённых запусков\n\n"
            "## Наблюдаемая способность\n\n"
            "Цепочка наблюдаемо завершает выбранный запуск.\n\n"
            "## Терминальная приёмка\n\n"
            "Терминальная проверка подтверждена внешним критерием.\n\n"
            "## Отрицательные результаты\n\n"
            "Двойных запусков и порогов не обнаружено.\n\n"
            "## Стоимость пройденной цепочки\n\n"
            "Стоимость включает два локальных запуска и их проверки.\n\n"
            "Число шагов, коммитов или документов не является "
            "доказательством улучшения.\n",
            encoding="utf-8",
        )
        итоговый_реестр = json.loads(реестр.read_text(encoding="utf-8"))
        итоговая_аналитика = next(
            задание
            for задание in итоговый_реестр["задания"]
            if задание["job_id"] == "master.completed-step-analysis"
        )
        диапазон = dict(претензия["диапазон_событий"])
        идентификаторы_событий = list(
            диапазон["идентификаторы_событий"]
        )
        курсор = итоговая_аналитика["курсор_результата"]
        курсор["последнее_число_подтверждённых_событий"] = 1
        курсор["последний_идентификатор_события"] = (
            идентификаторы_событий[-1]
        )
        курсор["следующий_порог"] = 2
        курсор["последний_подтверждённый_аналитический_результат"] = {
            "идентификатор": претензия["идентификатор_анализа"],
            "путь": претензия["путь_отчёта"],
            "content_sha256": "sha256:"
            + hashlib.sha256(путь_отчёта.read_bytes()).hexdigest(),
            "конец_диапазона": 1,
        }
        сам.записать_объект(реестр, итоговый_реестр)
        сам.выполнить_гит(
            корень,
            "add",
            "--",
            str(реестр.relative_to(корень)),
            str(путь_отчёта.relative_to(корень)),
        )
        аргументы_коммита_аналитики = (
            "commit",
            "--task-id",
            задача_аналитики,
            "--generation",
            поколение_аналитики,
            "--message",
            "Завершить сквозную аналитическую ревизию",
        )
        передача_аналитики = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                *аргументы_коммита_аналитики,
            )
        )
        повтор_передачи_аналитики = сам.данные_успешного_процесса(
            сам.выполнить_очередь_из_вершины(
                корень,
                *аргументы_коммита_аналитики,
            )
        )
        сам.assertEqual(
            повтор_передачи_аналитики["new_head"],
            передача_аналитики["new_head"],
        )

        аргументы_завершения_аналитики = (
            "завершить",
            *аналитическое_ограждение,
            "--generation",
            поколение_аналитики,
            "--json",
        )
        for ожидаемое_владение in ("new", "existing"):
            завершение_аналитики = сам.данные_успешного_процесса(
                сам.выполнить_аналитику(
                    корень,
                    *аргументы_завершения_аналитики,
                )
            )
            сам.assertEqual(
                завершение_аналитики["ownership"],
                ожидаемое_владение,
            )
            сам.assertEqual(
                завершение_аналитики["подтверждённый_результат"][
                    "commit"
                ],
                передача_аналитики["new_head"],
            )

        аргументы_общего_терминала_аналитики = (
            "подтвердить-завершение-исполнителя",
            *сам.аргументы_ограждения_запуска(
                корень,
                аналитический_выбор,
                попытка_аналитики,
            ),
            "--json",
        )
        for ожидаемое_владение in ("новое", "существующее"):
            терминал = сам.данные_успешного_процесса(
                сам.выполнить(
                    корень,
                    *аргументы_общего_терминала_аналитики,
                )
            )
            сам.assertEqual(терминал["исход"], "успех")
            сам.assertEqual(
                терминал["владение"],
                ожидаемое_владение,
            )

        следующий_показ = сам.данные_успешного_процесса(
            сам.выполнить_аналитику(
                корень,
                "показать",
                "--корень-рабочей-копии",
                str(корень),
                "--реестр",
                str(реестр),
                "--схема",
                str(схема),
                "--expected-job-id",
                "master.completed-step-analysis",
                "--json",
            )
        )
        сам.assertEqual(следующий_показ["state"], "not_ready")
        сам.assertEqual(len(list(путь_отчёта.parent.glob("*.md"))), 1)
        итоговое_наблюдение = сам.данные_успешного_процесса(
            сам.выполнить_аналитику(
                корень,
                "наблюдать",
                "--корень-рабочей-копии",
                str(корень),
                "--expected-branch-ref",
                "refs/heads/master",
                "--json",
            )
        )
        сам.assertEqual(
            итоговое_наблюдение["число_подтверждённых_событий"],
            1,
        )
        выбор_после_порога = сам.выбрать(
            корень,
            реестр,
            схема,
            путь_новых_наблюдений,
        )
        сам.assertEqual(
            выбор_после_порога["job_id"],
            "master.next-step",
        )
        сам.assertEqual(выбор_после_порога["число_готовых"], 1)

        попытка_следующей_карточки = str(uuid.uuid4())
        резерв_следующей_карточки = сам.данные_успешного_процесса(
            сам.резервировать_новый_запуск(
                корень,
                реестр,
                схема,
                путь_новых_наблюдений,
                выбор_после_порога,
                попытка_следующей_карточки,
            )
        )
        сам.assertEqual(резерв_следующей_карточки["владение"], "новое")

        свежий_показ_следующей_карточки = (
            сам.показать_специализированный_выбор(корень)
        )
        свежий_выбор_следующей_карточки = dict(
            свежий_показ_следующей_карточки["selection"]
        )
        сам.assertEqual(
            свежий_выбор_следующей_карточки["head"],
            выбор_после_порога["selection_head"],
        )
        сам.assertEqual(
            свежий_показ_следующей_карточки["card_id"],
            "FUM-STEP-0143",
        )
        претензия_следующей_карточки = сам.данные_успешного_процесса(
            сам.выполнить_следующий_шаг(
                корень,
                "claim",
                "--expected-branch-ref",
                str(свежий_показ_следующей_карточки["branch_ref"]),
                "--expected-step-id",
                str(свежий_показ_следующей_карточки["step_id"]),
                "--expected-selection-id",
                str(свежий_выбор_следующей_карточки["id"]),
                "--lease-id",
                попытка_следующей_карточки,
                "--repo-root",
                str(корень),
                "--json",
            )
        )
        сам.assertEqual(претензия_следующей_карточки["ownership"], "new")

        освобождение_следующей_карточки = сам.данные_успешного_процесса(
            сам.выполнить_следующий_шаг(
                корень,
                "release",
                "--branch-ref",
                str(свежий_показ_следующей_карточки["branch_ref"]),
                "--expected-lease-id",
                попытка_следующей_карточки,
                "--repo-root",
                str(корень),
                "--json",
            )
        )
        сам.assertEqual(освобождение_следующей_карточки["state"], "released")
        сам.данные_успешного_процесса(
            сам.выполнить(
                корень,
                *сам.аргументы_общего_освобождения(
                    корень,
                    выбор_после_порога,
                    попытка_следующей_карточки,
                    "released",
                ),
            )
        )


if __name__ == "__main__":
    unittest.main()
