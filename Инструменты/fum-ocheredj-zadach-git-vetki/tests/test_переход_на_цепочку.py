"""RED-контракт первого межзадачного перехода на ветку цепочки шагов."""

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


КОРЕНЬ_ИНСТРУМЕНТА = Path(__file__).resolve().parents[1]
ПУТЬ_СЦЕНАРИЯ = (
    КОРЕНЬ_ИНСТРУМЕНТА / "scripts" / "ocheredj-zadach-git-vetki.py"
)


class ТестыПереходаНаЦепочку(unittest.TestCase):
    def подготовить(это) -> None:
        это.временный_каталог = tempfile.TemporaryDirectory()
        это.addCleanup(это.временный_каталог.cleanup)
        это.репозиторий = Path(это.временный_каталог.name) / "main"
        это.репозиторий.mkdir()

        subprocess.run(
            ["git", "init", "-b", "master"],
            cwd=это.репозиторий,
            check=True,
            capture_output=True,
        )
        это.выполнить_гит("config", "user.name", "FUM Test")
        это.выполнить_гит("config", "user.email", "fum-test@example.invalid")

        (это.репозиторий / ".obsidian").mkdir()
        (это.репозиторий / ".obsidian" / "graph.json").write_text(
            '{"zoom": 1}\n',
            encoding="utf-8",
        )
        (это.репозиторий / "README.md").write_text(
            "# Проверочный репозиторий\n",
            encoding="utf-8",
        )
        это.выполнить_гит("add", ".")
        это.выполнить_гит("commit", "-m", "Создать основу фикстуры")
        это.базовая_вершина = это.выполнить_гит("rev-parse", "HEAD").stdout.strip()

        это.идентификатор_цепочки = "FUM-ЦЕПОЧКА-0001"
        это.исходная_ссылка_ветки = "refs/heads/master"
        это.целевая_ссылка_ветки = "refs/heads/codex/test-chain"
        это.относительный_путь_карточки = (
            "Планирование/карточки-цепочек-шагов/"
            "FUM-ЦЕПОЧКА-0001-тестовая-цепочка.md"
        )
        это.путь_карточки = (
            это.репозиторий / это.относительный_путь_карточки
        )
        это.путь_карточки.parent.mkdir(parents=True)
        это.содержимое_карточки = (
            "+++\n"
            '"версия_схемы" = 1\n'
            f'"идентификатор_цепочки" = "{это.идентификатор_цепочки}"\n'
            '"состояние" = "активна"\n'
            f'"ветка" = "{это.целевая_ссылка_ветки}"\n'
            f'"базовая_ветка" = "{это.исходная_ссылка_ветки}"\n'
            '"путь_проекта" = "README.md"\n'
            '"карточки_шагов" = ["FUM-STEP-0001"]\n'
            "+++\n"
            "# Тестовая цепочка\n\n"
            "Цепочка задаёт проверочный последующий шаг.\n"
        )
        это.путь_карточки.write_text(
            это.содержимое_карточки,
            encoding="utf-8",
        )
        это.хэш_карточки = (
            "sha256:"
            + hashlib.sha256(это.содержимое_карточки.encode("utf-8")).hexdigest()
        )
        это.выполнить_гит("add", это.относительный_путь_карточки)
        это.выполнить_гит("commit", "-m", "Добавить карточку тестовой цепочки")
        это.исходная_вершина = это.выполнить_гит("rev-parse", "HEAD").stdout.strip()

    def выполнить_гит(
        это,
        *аргументы: str,
        проверять: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", "-C", str(это.репозиторий), *аргументы],
            check=проверять,
            capture_output=True,
            text=True,
        )

    def вызвать_очередь(
        это,
        *аргументы: str,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(ПУТЬ_СЦЕНАРИЯ), *аргументы],
            cwd=это.репозиторий,
            check=False,
            capture_output=True,
            text=True,
            timeout=60,
        )

    def вызвать_переход(
        это,
        идентификатор_задачи: str = "задача-цепочки",
    ) -> subprocess.CompletedProcess[str]:
        return это.вызвать_очередь(
            "перейти-на-цепочку",
            "--repo-root",
            str(это.репозиторий),
            "--task-id",
            идентификатор_задачи,
            "--chain-card",
            это.относительный_путь_карточки,
            "--expected-chain-id",
            это.идентификатор_цепочки,
            "--expected-card-sha256",
            это.хэш_карточки,
            "--expected-source-branch-ref",
            это.исходная_ссылка_ветки,
            "--expected-source-head",
            это.исходная_вершина,
            "--json",
        )

    def вызвать_вход_в_очередь(
        это,
        идентификатор_задачи: str,
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        результат = это.вызвать_очередь(
            "join",
            "--repo-root",
            str(это.репозиторий),
            "--task-id",
            идентификатор_задачи,
            "--json",
        )
        return результат, это.разобрать_ответ(результат)

    def разобрать_ответ(
        это,
        результат: subprocess.CompletedProcess[str],
    ) -> dict[str, object]:
        это.assertTrue(результат.stdout, результат.stderr)
        значение = json.loads(результат.stdout)
        это.assertIsInstance(значение, dict)
        return значение

    def прочитать_состояние_очереди(
        это,
        ссылка_очереди: str,
    ) -> dict[str, object]:
        значение = json.loads(
            это.выполнить_гит("cat-file", "blob", ссылка_очереди).stdout
        )
        это.assertIsInstance(значение, dict)
        return значение

    def целевая_ветка_отсутствует(это) -> bool:
        результат = это.выполнить_гит(
            "show-ref",
            "--verify",
            "--quiet",
            это.целевая_ссылка_ветки,
            проверять=False,
        )
        return результат.returncode != 0

    def test_отсутствующая_ветка_создаётся_на_исходной_вершине_и_задача_сразу_допускается(
        это,
    ) -> None:
        это.подготовить()
        результат = это.вызвать_переход()
        ответ = это.разобрать_ответ(результат)

        это.assertEqual(результат.returncode, 0, результат.stderr)
        это.assertEqual(ответ["state"], "admitted")
        это.assertEqual(ответ["ownership"], "new")
        это.assertEqual(ответ["task_id"], "задача-цепочки")
        это.assertEqual(ответ["base_head"], это.исходная_вершина)
        это.assertEqual(ответ["branch_ref"], это.целевая_ссылка_ветки)
        это.assertEqual(
            это.выполнить_гит("symbolic-ref", "HEAD").stdout.strip(),
            это.целевая_ссылка_ветки,
        )
        это.assertEqual(
            это.выполнить_гит(
                "rev-parse", "--verify", это.целевая_ссылка_ветки
            ).stdout.strip(),
            это.исходная_вершина,
        )
        это.assertEqual(
            это.выполнить_гит(
                "rev-parse", "--verify", это.исходная_ссылка_ветки
            ).stdout.strip(),
            это.исходная_вершина,
        )

        состояние = это.прочитать_состояние_очереди(str(ответ["queue_ref"]))
        это.assertEqual(состояние["branch_ref"], это.целевая_ссылка_ветки)
        это.assertEqual(состояние["owner"]["task_id"], "задача-цепочки")
        это.assertEqual(состояние["owner"]["base_head"], это.исходная_вершина)
        это.assertEqual(
            состояние["текущая_цепочка"],
            {
                "идентификатор": это.идентификатор_цепочки,
                "путь": это.относительный_путь_карточки,
                "хэш": это.хэш_карточки,
                "ветка": это.целевая_ссылка_ветки,
            },
        )

    def test_грязная_рабочая_копия_отклоняется_до_создания_целевой_ветки(
        это,
    ) -> None:
        это.подготовить()
        (это.репозиторий / "README.md").write_text(
            "# Незакоммиченное изменение\n",
            encoding="utf-8",
        )

        результат = это.вызвать_переход()
        ответ = это.разобрать_ответ(результат)

        это.assertNotEqual(результат.returncode, 0)
        это.assertEqual(ответ["state"], "dirty")
        это.assertTrue(это.целевая_ветка_отсутствует())
        это.assertEqual(
            это.выполнить_гит("symbolic-ref", "HEAD").stdout.strip(),
            это.исходная_ссылка_ветки,
        )
        это.assertEqual(
            это.выполнить_гит(
                "for-each-ref", "--format=%(refname)", "refs/fum/worktree-task-queues"
            ).stdout,
            "",
        )

    def test_активная_очередь_отклоняется_до_создания_целевой_ветки(
        это,
    ) -> None:
        это.подготовить()
        допуск, владелец = это.вызвать_вход_в_очередь("другая-задача")
        это.assertEqual(допуск.returncode, 0, допуск.stderr)
        объект_очереди_до = str(владелец["queue_oid"])

        результат = это.вызвать_переход()
        ответ = это.разобрать_ответ(результат)

        это.assertNotEqual(результат.returncode, 0)
        это.assertEqual(ответ["state"], "queue_active")
        это.assertTrue(это.целевая_ветка_отсутствует())
        это.assertEqual(
            это.выполнить_гит("symbolic-ref", "HEAD").stdout.strip(),
            это.исходная_ссылка_ветки,
        )
        это.assertEqual(
            это.выполнить_гит("rev-parse", str(владелец["queue_ref"])).stdout.strip(),
            объект_очереди_до,
        )

    def test_существующая_целевая_ветка_с_иной_вершиной_отклоняется(
        это,
    ) -> None:
        это.подготовить()
        это.выполнить_гит(
            "branch",
            это.целевая_ссылка_ветки.removeprefix("refs/heads/"),
            это.базовая_вершина,
        )

        результат = это.вызвать_переход()
        ответ = это.разобрать_ответ(результат)

        это.assertNotEqual(результат.returncode, 0)
        это.assertEqual(ответ["state"], "target_branch_exists")
        это.assertEqual(
            это.выполнить_гит(
                "rev-parse", "--verify", это.целевая_ссылка_ветки
            ).stdout.strip(),
            это.базовая_вершина,
        )
        это.assertEqual(
            это.выполнить_гит(
                "rev-parse", "--verify", это.исходная_ссылка_ветки
            ).stdout.strip(),
            это.исходная_вершина,
        )
        это.assertEqual(
            это.выполнить_гит("symbolic-ref", "HEAD").stdout.strip(),
            это.исходная_ссылка_ветки,
        )
        это.assertEqual(
            это.выполнить_гит(
                "for-each-ref", "--format=%(refname)", "refs/fum/worktree-task-queues"
            ).stdout,
            "",
        )

    def test_целевая_ветка_вне_разрешённого_пространства_отклоняется(это) -> None:
        это.подготовить()
        прежняя_ветка = это.целевая_ссылка_ветки
        это.целевая_ссылка_ветки = "refs/heads/feature/test-chain"
        это.содержимое_карточки = это.содержимое_карточки.replace(
            прежняя_ветка,
            это.целевая_ссылка_ветки,
        )
        это.путь_карточки.write_text(
            это.содержимое_карточки,
            encoding="utf-8",
        )
        это.хэш_карточки = (
            "sha256:"
            + hashlib.sha256(
                это.содержимое_карточки.encode("utf-8")
            ).hexdigest()
        )
        это.выполнить_гит("add", это.относительный_путь_карточки)
        это.выполнить_гит("commit", "-m", "Изменить ветку карточки")
        это.исходная_вершина = это.выполнить_гит(
            "rev-parse",
            "HEAD",
        ).stdout.strip()

        результат = это.вызвать_переход()
        ответ = это.разобрать_ответ(результат)

        это.assertNotEqual(результат.returncode, 0)
        это.assertEqual(ответ["state"], "invalid_chain_card")
        это.assertTrue(это.целевая_ветка_отсутствует())
        это.assertEqual(
            это.выполнить_гит("symbolic-ref", "HEAD").stdout.strip(),
            это.исходная_ссылка_ветки,
        )

    def test_повтор_после_потерянного_ответа_идемпотентно_возвращает_тот_же_допуск(
        это,
    ) -> None:
        это.подготовить()
        первый_результат = это.вызвать_переход()
        первый_ответ = это.разобрать_ответ(первый_результат)
        повторный_результат = это.вызвать_переход()
        повторный_ответ = это.разобрать_ответ(повторный_результат)

        это.assertEqual(первый_результат.returncode, 0, первый_результат.stderr)
        это.assertEqual(повторный_результат.returncode, 0, повторный_результат.stderr)
        это.assertEqual(первый_ответ["state"], "admitted")
        это.assertEqual(первый_ответ["ownership"], "new")
        это.assertEqual(повторный_ответ["state"], "admitted")
        это.assertEqual(повторный_ответ["ownership"], "existing")
        for поле in ["ticket_id", "generation", "seq", "base_head", "queue_oid"]:
            это.assertEqual(первый_ответ[поле], повторный_ответ[поле])
        это.assertEqual(
            это.выполнить_гит(
                "rev-parse", "--verify", это.целевая_ссылка_ветки
            ).stdout.strip(),
            это.исходная_вершина,
        )
        это.assertEqual(
            это.выполнить_гит(
                "rev-parse", "--verify", это.исходная_ссылка_ветки
            ).stdout.strip(),
            это.исходная_вершина,
        )

        состояние = это.прочитать_состояние_очереди(
            str(повторный_ответ["queue_ref"])
        )
        это.assertEqual(
            состояние["текущая_цепочка"],
            {
                "идентификатор": это.идентификатор_цепочки,
                "путь": это.относительный_путь_карточки,
                "хэш": это.хэш_карточки,
                "ветка": это.целевая_ссылка_ветки,
            },
        )


if __name__ == "__main__":
    unittest.main()
