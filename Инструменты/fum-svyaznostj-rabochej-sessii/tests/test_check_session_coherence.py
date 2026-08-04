import hashlib
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "check-session-coherence.py"
)

spec = importlib.util.spec_from_file_location("check_session_coherence", SCRIPT_PATH)
check_session_coherence = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = check_session_coherence
spec.loader.exec_module(check_session_coherence)


class CheckSessionCoherenceTests(unittest.TestCase):
    @staticmethod
    def initialize_git_repository(root: Path) -> None:
        subprocess.run(
            ["git", "init", "--quiet"],
            cwd=root,
            check=True,
            capture_output=True,
            text=True,
        )

    @staticmethod
    def canonical_request(stem: str) -> Path:
        return Path("Журнал") / stem / "запрос.md"

    def test_request_identity_comes_from_parent_stem_and_report_is_sibling(self):
        request_path = Path(
            "Журнал/2026-08-03_12-34-56_MSK_обновить-структуру/запрос.md"
        )

        self.assertIsNotNone(check_session_coherence.request_match(request_path))
        self.assertEqual(
            check_session_coherence.expected_request_heading(request_path),
            "# Исходный запрос 2026-08-03 12:34:56 MSK - Обновить структуру",
        )
        self.assertEqual(
            check_session_coherence.expected_journal_path(
                request_path,
                Path("/repo"),
            ),
            Path(
                "Журнал/2026-08-03_12-34-56_MSK_обновить-структуру/отчёт.md"
            ),
        )

    def test_request_file_is_exact_nested_journal_target(self):
        root = Path("/repo")
        canonical = root / "Журнал/2026-08-03_12-34-56_MSK/запрос.md"

        self.assertTrue(check_session_coherence.is_request_file(canonical, root))
        self.assertFalse(
            check_session_coherence.is_request_file(
                root / "Журнал/2026-08-03_12-34-56_MSK/отчёт.md",
                root,
            )
        )
        self.assertFalse(
            check_session_coherence.is_request_file(
                root / "Запросы/2026-08-03_12-34-56_MSK.md",
                root,
            )
        )

    def test_meta_and_provenance_guards_exempt_only_canonical_request(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request = (
                root
                / "Журнал"
                / "2026-08-03_12-34-56_MSK_обновить-структуру"
                / "запрос.md"
            )
            request.parent.mkdir(parents=True)
            request.write_text(
                "\n".join(
                    [
                        "# Исходный запрос",
                        "",
                        "Источники требований:",
                        "",
                        "Пользователь уточнил правило ведения памяти FUM.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            self.assertEqual(
                check_session_coherence.validate_meta_request_coverage(
                    {request},
                    root,
                ),
                [],
            )
            self.assertEqual(
                check_session_coherence.validate_provenance_section_position(
                    {request},
                    root,
                ),
                [],
            )

    def test_request_folder_requires_full_time_prefix(self):
        malformed = Path("Журнал/обновить-структуру/запрос.md")

        self.assertIsNone(check_session_coherence.request_match(malformed))
        self.assertEqual(
            check_session_coherence.validate_request_filename_title(malformed),
            [],
        )

    def test_navigation_requires_exact_request_target_not_shared_basename(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            stems = (
                "2026-08-03_12-00-00_MSK_создать-первый-запрос",
                "2026-08-03_12-01-00_MSK_создать-второй-запрос",
                "2026-08-03_12-02-00_MSK_создать-третий-запрос",
            )
            requests = []
            for stem in stems:
                request = root / "Журнал" / stem / "запрос.md"
                request.parent.mkdir(parents=True)
                request.write_text("# Запрос\n", encoding="utf-8")
                requests.append(request.resolve())

            current = requests[1]
            text = "\n".join(
                [
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: "
                    f"[{check_session_coherence.request_label(requests[0])}]"
                    f"(../{stems[2]}/запрос.md)",
                    "- Следующий запрос: "
                    f"[{check_session_coherence.request_label(requests[2])}]"
                    f"(../{stems[2]}/запрос.md)",
                    "",
                ]
            )

            errors = check_session_coherence.validate_navigation(
                root,
                current,
                text,
                markdown_paths=set(requests),
            )

            self.assertIn(
                f"missing previous request navigation link: {stems[0]}/запрос.md",
                errors,
            )

    def test_layout_rejects_legacy_requests_directory_and_top_level_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.initialize_git_repository(root)
            (root / "Запросы").mkdir()
            journal = root / "Журнал"
            journal.mkdir()
            (journal / "2026-08-03_12-34-56_MSK_обновить-структуру.md").write_text(
                "# Старый отчёт\n",
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_request_folder_layout(root)

            self.assertTrue(errors)
            self.assertTrue(
                any("Запросы" in error or "README.md" in error for error in errors),
                errors,
            )

    def test_layout_delegates_to_dedicated_automation_when_available(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            validator = mock.Mock(return_value={"status": "valid"})

            with mock.patch.object(
                check_session_coherence,
                "validate_layout",
                validator,
            ):
                errors = check_session_coherence.validate_request_folder_layout(root)

            self.assertEqual(errors, [])
            validator.assert_called_once_with(root.resolve())

    def write_fixture(self, root: Path) -> Path:
        self.initialize_git_repository(root)
        (root / "Журнал").mkdir()
        (root / "Документация").mkdir()
        (root / "Инструменты").mkdir()

        (root / "Документация" / "17-воспроизводимые-автоматизации.md").write_text(
            "# Воспроизводимые автоматизации FUM\n",
            encoding="utf-8",
        )
        (root / "Инструменты" / "реестр-системных-приложений-и-инструментов.md").write_text(
            "# Реестр системных приложений и инструментов\n",
            encoding="utf-8",
        )
        first_stem = "2026-06-24_16-26-47_MSK_первый-запрос"
        current_stem = "2026-06-24_16-32-29_MSK_проверка-связности-сессии"
        first_dir = root / "Журнал" / first_stem
        current_dir = root / "Журнал" / current_stem
        first_dir.mkdir()
        current_dir.mkdir()

        (first_dir / "запрос.md").write_text(
            "\n".join(
                [
                    "# Исходный запрос 2026-06-24 16:26:47 MSK - Первый запрос",
                    "",
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: нет",
                    "- Следующий запрос: [2026-06-24 16:32:29 MSK - Проверка связности сессии](../2026-06-24_16-32-29_MSK_проверка-связности-сессии/запрос.md)",
                    "",
                    "## Текст запроса",
                    "",
                    "> Предыдущий запрос.",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        (first_dir / "отчёт.md").write_text(
            "# Отчёт 2026-06-24 16:26:47 MSK - Первый запрос\n\n"
            "## Источники\n\n- [исходный запрос](запрос.md)\n",
            encoding="utf-8",
        )

        request_path = current_dir / "запрос.md"
        request_path.write_text(
            "\n".join(
                [
                    "# Исходный запрос 2026-06-24 16:32:29 MSK - Проверка связности сессии",
                    "",
                    "## Навигация по запросам",
                    "",
                    "- Предыдущий запрос: [2026-06-24 16:26:47 MSK - Первый запрос](../2026-06-24_16-26-47_MSK_первый-запрос/запрос.md)",
                    "- Следующий запрос: нет",
                    "",
                    "## Текст запроса",
                    "",
                    "> Выделить автоматическую проверку связности рабочей сессии.",
                    "",
                    "## Использованные инструменты",
                    "",
                    "- [Реестр системных приложений и инструментов](../../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                    "- `python3` - использован для запуска проверки.",
                    "",
                    "## Повлиял на файлы",
                    "",
                    "- [Документация/17-воспроизводимые-автоматизации.md](../../Документация/17-воспроизводимые-автоматизации.md)",
                    "- [Журнал/текущий запрос](запрос.md)",
                    "- [Журнал/текущий отчёт](отчёт.md)",
                    "- [Журнал/предыдущий запрос](../2026-06-24_16-26-47_MSK_первый-запрос/запрос.md)",
                    "",
                    "## Проверки",
                    "",
                    "- Проверка связности рабочей сессии - прошла.",
                    "",
                    "## Описание сделанного",
                    "",
                    "Добавлена проверка [воспроизводимых автоматизаций](../../Документация/17-воспроизводимые-автоматизации.md).",
                    "",
                ]
            ),
            encoding="utf-8",
        )

        (current_dir / "отчёт.md").write_text(
            "\n".join(
                [
                    "# Отчёт 2026-06-24 16:32:29 MSK - Проверка связности сессии",
                    "",
                    "## Проверки",
                    "",
                    "- Проверка связности рабочей сессии - прошла.",
                    "",
                    "## Источники",
                    "",
                    "- [исходный запрос 2026-06-24 16:32:29 MSK - Проверка связности сессии](запрос.md)",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        (root / "Журнал" / "README.md").write_text(
            "\n".join(
                [
                    "# Журнал",
                    "",
                    "## Папки запросов",
                    "",
                    f"- [Текущий отчёт]({current_stem}/отчёт.md)",
                    f"- [Первый отчёт]({first_stem}/отчёт.md)",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        return request_path

    def write_time_profile_journal(
        self,
        root: Path,
        *,
        request_stem: str,
        request_label: str,
        invocation_rows: list[str] | None,
        invocation_total: str | None,
    ) -> Path:
        (root / "Журнал").mkdir()
        session_dir = root / "Журнал" / request_stem
        session_dir.mkdir()
        request_path = session_dir / "запрос.md"
        request_path.write_text(f"# Исходный запрос {request_label}\n", encoding="utf-8")
        lines = [
            f"# Отчёт {request_label}",
            "",
            "Отчёт с измеренным профилем.",
            "",
            "## Профиль времени выполнения",
            "",
            "| Стадия | Длительность | Границы и способ измерения |",
            "| --- | ---: | --- |",
            "| Анализ | 12 с | Монотонные отметки. |",
            "| Проверки | 31 с | Wall-clock `real`. |",
            "",
            "Граница профиля: от допуска очереди до завершения проверок.",
            "",
        ]
        if invocation_rows is not None:
            lines.extend(
                [
                    "### Прямые запуски проверок",
                    "",
                    "| Вызов | Длительность | Результат |",
                    "| --- | ---: | --- |",
                    *invocation_rows,
                    "",
                ]
            )
            if invocation_total is not None:
                lines.extend([invocation_total, ""])
        lines.extend(
            [
                "## Источники",
                "",
                "- [исходный запрос](запрос.md)",
                "",
            ]
        )
        (session_dir / "отчёт.md").write_text(
            "\n".join(lines),
            encoding="utf-8",
        )
        return request_path

    @staticmethod
    def _канонические_машинные_байты(значение: object) -> bytes:
        return (
            json.dumps(
                значение,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
            + "\n"
        ).encode("utf-8")

    @staticmethod
    def _хэш_машинных_данных(байты: bytes) -> str:
        return hashlib.sha256(байты).hexdigest()

    @staticmethod
    def _секунды_из_наносекунд(наносекунды: int) -> str:
        целые, дробные = divmod(наносекунды, 1_000_000_000)
        if дробные == 0:
            return str(целые)
        хвост = f"{дробные:09d}".rstrip("0")
        return f"{целые},{хвост}"

    def _запись_запуска(
        себя,
        *,
        стем: str,
        порядок: int,
        идентификатор: str,
        исполнитель: str,
        вызов: str,
        состояние: str = "завершён",
        длительность_наносекунды: int | None = 0,
        статус: str | None = "успешно",
        код_завершения: int | None = 0,
        пояснение: str | None = "",
    ) -> dict[str, object]:
        return {
            "схема": "fum.test-run.v1",
            "идентификатор": идентификатор,
            "сессия": f"Журнал/{стем}/запрос.md",
            "порядок": порядок,
            "исполнитель": исполнитель,
            "вызов": вызов,
            "состояние": состояние,
            "длительность_наносекунды": длительность_наносекунды,
            "статус": статус,
            "код_завершения": код_завершения,
            "пояснение": пояснение,
        }

    def _ячейки_запуска(себя, запись: dict[str, object]) -> tuple[str, str, str]:
        вызов = f"[{запись['исполнитель']}] {запись['вызов']}"
        if запись["состояние"] == "выполняется":
            return вызов, "0,000 с", "не завершено — нет итоговой записи"
        длительность = запись["длительность_наносекунды"]
        себя.assertIsInstance(длительность, int)
        статус = str(запись["статус"])
        пояснение = запись["пояснение"]
        if пояснение:
            статус = f"{статус} — {пояснение}"
        return (
            вызов,
            f"{себя._секунды_из_наносекунд(длительность)} с",
            статус,
        )

    def _блок_запусков(
        себя,
        записи: list[dict[str, object]],
        маркер: str,
    ) -> str:
        упорядоченные = sorted(записи, key=lambda запись: int(запись["порядок"]))
        строки = [себя._ячейки_запуска(запись) for запись in упорядоченные]
        заголовки = ("Вызов", "Длительность", "Результат")
        ширины = [
            max(len(заголовки[номер]), *[len(строка[номер]) for строка in строки])
            for номер in range(3)
        ]

        def табличная_строка(ячейки: tuple[str, str, str]) -> str:
            return "| " + " | ".join(
                ячейка.ljust(ширины[номер])
                for номер, ячейка in enumerate(ячейки)
            ) + " |"

        таблица = [
            табличная_строка(заголовки),
            табличная_строка(tuple("-" * ширина for ширина in ширины)),
            *[табличная_строка(строка) for строка in строки],
        ]
        общая_длительность = sum(
            int(запись["длительность_наносекунды"] or 0)
            for запись in упорядоченные
        )
        return "\n".join(
            [
                "### Прямые запуски проверок",
                "",
                маркер,
                "",
                *таблица,
                "",
                "Общее время прямых запусков проверок: "
                f"{себя._секунды_из_наносекунд(общая_длительность)} с.",
                "",
                "<!-- FUM-CHECK-RUNS:END -->",
            ]
        )

    def _записать_машинный_профиль(
        себя,
        корень: Path,
        *,
        стем: str,
        метка: str,
        записи: list[dict[str, object]],
        состояние: str,
    ) -> tuple[Path, Path, Path | None, str]:
        строки = [
            f"| {ячейки[0]} | {ячейки[1]} | {ячейки[2]} |"
            for ячейки in [
                себя._ячейки_запуска(запись)
                for запись in записи
            ]
        ]
        общая_длительность = sum(
            int(запись["длительность_наносекунды"] or 0)
            for запись in записи
        )
        путь_запроса = себя.write_time_profile_journal(
            корень,
            request_stem=стем,
            request_label=метка,
            invocation_rows=строки,
            invocation_total=(
                "Общее время прямых запусков проверок: "
                f"{себя._секунды_из_наносекунд(общая_длительность)} с."
            ),
        )
        каталог = корень / "Журнал" / стем / "материалы" / "запуски-проверок"
        каталог.mkdir(parents=True)
        описания_файлов: list[dict[str, str]] = []
        for запись in sorted(записи, key=lambda запись: int(запись["порядок"])):
            имя = f"{int(запись['порядок']):06d}_{запись['идентификатор']}.json"
            байты = себя._канонические_машинные_байты(запись)
            (каталог / имя).write_bytes(байты)
            описания_файлов.append({"имя": имя, "sha256": себя._хэш_машинных_данных(байты)})

        путь_снимка: Path | None = None
        if состояние == "закрыт":
            себя.assertTrue(all(запись["состояние"] == "завершён" for запись in записи))
            снимок = {
                "схема": "fum.test-run-report.v1",
                "сессия": f"Журнал/{стем}/запрос.md",
                "файлы": описания_файлов,
            }
            байты_снимка = себя._канонические_машинные_байты(снимок)
            путь_снимка = каталог / "снимок.json"
            путь_снимка.write_bytes(байты_снимка)
            маркер = (
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=закрыт; "
                "снимок=материалы/запуски-проверок/снимок.json; "
                f"sha256=sha256:{себя._хэш_машинных_данных(байты_снимка)} -->"
            )
        else:
            себя.assertEqual(состояние, "открыт")
            маркер = (
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; "
                "каталог=материалы/запуски-проверок -->"
            )

        путь_отчёта = путь_запроса.parent / "отчёт.md"
        текст = путь_отчёта.read_text(encoding="utf-8")
        начало = текст.index("### Прямые запуски проверок")
        конец = текст.index("## Источники", начало)
        путь_отчёта.write_text(
            текст[:начало]
            + себя._блок_запусков(записи, маркер)
            + "\n\n"
            + текст[конец:],
            encoding="utf-8",
        )
        return путь_запроса, каталог, путь_снимка, маркер

    def _завершённые_записи(себя, стем: str) -> list[dict[str, object]]:
        return [
            себя._запись_запуска(
                стем=стем,
                порядок=1,
                идентификатор="00000000-0000-4000-8000-000000000001",
                исполнитель="корень",
                вызов="первый тест",
                длительность_наносекунды=1_250_000_000,
                статус="неуспешно",
                код_завершения=1,
                пояснение="ожидаемый TDD-red",
            ),
            себя._запись_запуска(
                стем=стем,
                порядок=2,
                идентификатор="00000000-0000-4000-8000-000000000002",
                исполнитель="субагент",
                вызов="повторный тест",
                длительность_наносекунды=2_000_000_000,
            ),
        ]

    def _записи_с_активной(себя, стем: str) -> list[dict[str, object]]:
        return [
            себя._завершённые_записи(стем)[0],
            себя._запись_запуска(
                стем=стем,
                порядок=2,
                идентификатор="00000000-0000-4000-8000-000000000003",
                исполнитель="корень",
                вызов="обёрнутая проверка связности",
                состояние="выполняется",
                длительность_наносекунды=None,
                статус=None,
                код_завершения=None,
                пояснение=None,
            ),
        ]

    def test_valid_session_with_listed_dirty_files_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            git_status = "\n".join(
                [
                    " M Документация/17-воспроизводимые-автоматизации.md",
                    " M Журнал/2026-06-24_16-26-47_MSK_первый-запрос/запрос.md",
                    "?? Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии/отчёт.md",
                    "?? Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии/запрос.md",
                ]
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status=git_status,
            )

            self.assertEqual(errors, [])

    def test_незаполненный_маркер_шаблона_останавливает_связность(себя):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса = себя.write_fixture(корень)
            состояние_репозитория = "\n".join(
                [
                    " M Документация/17-воспроизводимые-автоматизации.md",
                    " M Журнал/2026-06-24_16-26-47_MSK_первый-запрос/запрос.md",
                    "?? Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии/отчёт.md",
                    "?? Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии/запрос.md",
                ]
            )
            исходный = путь_запроса.read_text(encoding="utf-8")
            только_сырой = исходный.replace(
                "> Выделить автоматическую проверку связности рабочей сессии.",
                "<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->",
            )
            путь_запроса.write_text(только_сырой, encoding="utf-8")
            себя.assertEqual(
                check_session_coherence.validate_session(
                    корень,
                    путь_запроса.relative_to(корень),
                    git_status=состояние_репозитория,
                ),
                [],
            )

            путь_запроса.write_text(
                только_сырой + "\n<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->\n",
                encoding="utf-8",
            )
            ошибки = check_session_coherence.validate_session(
                корень,
                путь_запроса.relative_to(корень),
                git_status=состояние_репозитория,
            )

            себя.assertTrue(
                any("незаполненный маркер шаблона" in ошибка for ошибка in ошибки),
                ошибки,
            )

    def test_historical_request_filename_without_title_still_has_old_heading(self):
        request_path = self.canonical_request("2026-06-24_16-32-29_MSK")

        self.assertIsNotNone(check_session_coherence.request_match(request_path))
        self.assertEqual(
            check_session_coherence.expected_request_heading(request_path),
            "# Исходный запрос 2026-06-24 16:32:29 MSK",
        )

    def test_new_request_title_must_start_with_infinitive_verb(self):
        request_path = self.canonical_request(
            "2026-07-03_00-00-00_MSK_имена-запросов"
        )

        errors = check_session_coherence.validate_request_filename_title(request_path)

        self.assertEqual(
            errors,
            [
                "request folder title must start with an infinitive verb: имена-запросов"
            ],
        )

    def test_historical_request_title_before_infinitive_rule_remains_allowed(self):
        request_path = self.canonical_request(
            "2026-07-02_22-43-41_MSK_имена-файлов-запросов"
        )

        errors = check_session_coherence.validate_request_filename_title(request_path)

        self.assertEqual(errors, [])

    def test_new_request_rejects_unqualified_codex_version_fallback(self):
        request_path = self.canonical_request(
            "2026-07-10_05-59-58_MSK_уточнить-учёт-версий-ChatGPT-и-Codex"
        )
        generic_entries = (
            "- Codex - версия не раскрывается средой; использован как агентская среда.",
            "- `Codex` - версия не раскрывается средой; использован как агентская среда.",
            "- ChatGPT/Codex — версия не раскрывается средой; использован как агентская среда.",
            "- `ChatGPT / Codex` – версия не раскрывается средой; использован как агентская среда.",
        )

        for generic_entry in generic_entries:
            with self.subTest(generic_entry=generic_entry):
                text = "\n".join(
                    [
                        "## Использованные инструменты",
                        "",
                        "- [Реестр](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                        generic_entry,
                        "",
                    ]
                )

                errors = check_session_coherence.validate_used_tools_section(
                    text,
                    request_path,
                )

                self.assertEqual(
                    errors,
                    [
                        "used tools section must qualify the ChatGPT or Codex layer instead of using the generic version fallback"
                    ],
                )

    def test_historical_request_keeps_unqualified_codex_version_fallback(self):
        text = "\n".join(
            [
                "## Использованные инструменты",
                "",
                "- [Реестр](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                "- Codex - версия не раскрывается средой; использован как агентская среда.",
                "",
            ]
        )
        request_path = self.canonical_request(
            "2026-07-10_05-51-44_MSK_создать-папку-вопросов-и-ответов"
        )

        errors = check_session_coherence.validate_used_tools_section(
            text,
            request_path,
        )

        self.assertEqual(errors, [])

    def test_new_request_requires_canonical_session_time_tool(self):
        request_path = self.canonical_request(
            "2026-07-17_10-25-41_MSK_"
            "предотвращать-смещение-времени-сессий"
        )
        text = "\n".join(
            [
                "## Использованные инструменты",
                "",
                "- [Реестр](../Инструменты/реестр-системных-приложений-и-инструментов.md) - общий справочник.",
                "- `python3` - использован для локальных проверок.",
                "",
            ]
        )

        errors = check_session_coherence.validate_used_tools_section(
            text,
            request_path,
        )

        self.assertEqual(
            errors,
            [
                "used tools section must include fum-moskovskoye-vremya-rabochej-sessii for canonical MSK time"
            ],
        )

    def test_new_request_requires_codex_thread_id(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            "## Текст запроса\n\nДобавить идентификатор.\n",
            request_path,
        )

        self.assertEqual(
            errors,
            ["missing section: Идентификатор сеанса Codex"],
        )

    def test_new_request_accepts_root_codex_thread_id(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                f"Codex-Thread-ID: {root_thread_id}",
                "",
            ]
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            text,
            request_path,
            expected_codex_thread_id=root_thread_id,
        )

        self.assertEqual(errors, [])

    def test_new_request_rejects_split_or_non_unique_codex_thread_id_section(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        invalid_texts = {
            "split value": (
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID:\n{root_thread_id}\n"
            ),
            "extra content": (
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
                "Лишняя строка.\n"
            ),
            "duplicate heading": (
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n\n"
                "## Идентификатор сеанса Codex\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
        }

        for label, text in invalid_texts.items():
            with self.subTest(label=label):
                errors = check_session_coherence.validate_codex_thread_id_section(
                    text,
                    request_path,
                )
                self.assertTrue(errors)

    def test_new_request_rejects_subagent_codex_thread_id(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        child_thread_id = "019f5dd2-af59-7a31-99d0-243a677529ab"
        text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                f"Codex-Thread-ID: {child_thread_id}",
                "",
            ]
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            text,
            request_path,
            expected_codex_thread_id=root_thread_id,
        )

        self.assertEqual(
            errors,
            [
                "Codex-Thread-ID does not match the expected root Codex thread: "
                f"{child_thread_id}"
            ],
        )

    def test_new_request_rejects_non_uuid_codex_thread_id(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )
        text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                "Codex-Thread-ID: not-a-uuid",
                "",
            ]
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            text,
            request_path,
        )

        self.assertEqual(
            errors,
            ["Codex-Thread-ID must be a canonical lowercase UUID: not-a-uuid"],
        )

    def test_historical_request_without_codex_thread_id_remains_allowed(self):
        request_path = self.canonical_request(
            "2026-07-14_01-55-34_MSK_"
            "интегрировать-рекурсивную-модель-агента-и-среды"
        )

        errors = check_session_coherence.validate_codex_thread_id_section(
            "## Текст запроса\n\nИсторический запрос.\n",
            request_path,
        )

        self.assertEqual(errors, [])

    def test_new_request_requires_commit_context_arguments(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )

        errors = (
            check_session_coherence.validate_codex_commit_context_requirements(
                request_path,
                expected_codex_thread_id=None,
                commit_message=None,
            )
        )

        self.assertEqual(
            errors,
            [
                "--codex-thread-id is required for this request",
                "--commit-message-file is required for this request",
            ],
        )

        historical_path = self.canonical_request(
            "2026-07-14_01-55-34_MSK_"
            "интегрировать-рекурсивную-модель-агента-и-среды"
        )
        self.assertEqual(
            check_session_coherence.validate_codex_commit_context_requirements(
                historical_path,
                expected_codex_thread_id=None,
                commit_message=None,
            ),
            [],
        )

    def test_commit_message_requires_matching_codex_thread_id_trailer(self):
        request_path = self.canonical_request(
            "2026-07-14_02-31-47_MSK_добавлять-"
            "идентификатор-сеанса-Codex"
        )
        root_thread_id = "019f5dd0-c129-7fa0-9315-77e85dead3e7"
        request_text = "\n".join(
            [
                "## Идентификатор сеанса Codex",
                "",
                f"Codex-Thread-ID: {root_thread_id}",
                "",
            ]
        )
        messages = {
            "missing": "Добавлять ID\n\nСделано.\n",
            "subject only": f"Codex-Thread-ID: {root_thread_id}\n",
            "split value": (
                "Добавлять ID\n\nСделано.\n\n"
                f"Codex-Thread-ID:\n{root_thread_id}\n"
            ),
            "not a trailer block": (
                "Добавлять ID\n\nСделано.\n\n"
                "Обычный текст.\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
            "different": (
                "Добавлять ID\n\nСделано.\n\n"
                "Codex-Thread-ID: 019f5dd2-af59-7a31-99d0-243a677529ab\n"
            ),
            "duplicate": (
                "Добавлять ID\n\nСделано.\n\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
            "case-insensitive duplicate": (
                "Добавлять ID\n\nСделано.\n\n"
                "codex-thread-id: 019f5dd2-af59-7a31-99d0-243a677529ab\n"
                f"Codex-Thread-ID: {root_thread_id}\n"
            ),
        }

        for label, message in messages.items():
            with self.subTest(label=label):
                errors = check_session_coherence.validate_commit_message_codex_thread_id(
                    request_text,
                    request_path,
                    message,
                )
                self.assertTrue(errors)

        valid_message = (
            "Добавлять идентификатор сеанса Codex\n\n"
            "Исходный запрос и описание сделанного.\n\n"
            f"Codex-Thread-ID: {root_thread_id}\n"
        )
        self.assertEqual(
            check_session_coherence.validate_commit_message_codex_thread_id(
                request_text,
                request_path,
                valid_message,
            ),
            [],
        )

    def test_answered_question_file_requires_literal_question_mark(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "Вопросы и ответы"
            directory.mkdir()
            (directory / "README.md").write_text(
                "# Вопросы и ответы\n",
                encoding="utf-8",
            )
            valid = directory / "верный-вопрос.md"
            valid.write_text(
                "\n".join(
                    [
                        "# Почему это вопрос",
                        "",
                        "## Вопрос",
                        "",
                        "```text",
                        "Почему это вопрос?",
                        "```",
                        "",
                        "## Ответ",
                        "",
                        "Потому что он оканчивается вопросительным знаком.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            invalid = directory / "невопросительный-запрос.md"
            invalid.write_text(
                "\n".join(
                    [
                        "# Создать папку",
                        "",
                        "## Вопрос",
                        "",
                        "```text",
                        "Давай создадим папку вопросов и ответов.",
                        "```",
                        "",
                        "## Ответ",
                        "",
                        "Папка создана.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_answered_question_files(root)

            self.assertEqual(
                errors,
                [
                    "answered-question text must end with '?' in "
                    "Вопросы и ответы/невопросительный-запрос.md"
                ],
            )

    def test_answered_question_file_requires_question_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / "Вопросы и ответы"
            directory.mkdir()
            path = directory / "нет-раздела-вопроса.md"
            path.write_text(
                "# Нет раздела вопроса\n\n## Ответ\n\nОтвет без вопроса.\n",
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_answered_question_files(root)

            self.assertEqual(
                errors,
                [
                    "answered-question text must end with '?' in "
                    "Вопросы и ответы/нет-раздела-вопроса.md"
                ],
            )

    def test_affected_files_accepts_deleted_path_marker(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённый файл: `Вопросы и ответы/ошибочный-материал.md`",
                    "",
                ]
            )

            affected, errors = check_session_coherence.affected_files_from_request(
                text,
                request_path,
                root,
            )

            self.assertEqual(errors, [])
            self.assertEqual(
                affected,
                {(root / "Вопросы и ответы" / "ошибочный-материал.md").resolve()},
            )

    def test_deleted_path_marker_rejects_existing_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            existing = root / "Документация" / "существующий-файл.md"
            existing.parent.mkdir()
            existing.write_text("# Существующий файл\n", encoding="utf-8")
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённый файл: `Документация/существующий-файл.md`",
                    "",
                ]
            )

            _, errors = check_session_coherence.affected_files_from_request(
                text,
                request_path,
                root,
            )

            self.assertEqual(
                errors,
                [
                    "deleted affected path still exists: "
                    "Документация/существующий-файл.md"
                ],
            )

    def test_git_status_accepts_existing_descendants_of_linked_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            affected_directory = root / "Документация" / "модуль"
            nested_directory = affected_directory / "вложенный"
            nested_directory.mkdir(parents=True)
            (affected_directory / "первый.md").write_text("# Первый\n", encoding="utf-8")
            (nested_directory / "второй.md").write_text("# Второй\n", encoding="utf-8")
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- [Модуль](../../Документация/модуль/)",
                    "",
                ]
            )

            affected, affected_errors = (
                check_session_coherence.affected_files_from_request(
                    text,
                    request_path,
                    root,
                )
            )
            status_errors = check_session_coherence.validate_git_status(
                root,
                affected,
                "\n".join(
                    [
                        " M Документация/модуль/первый.md",
                        "?? Документация/модуль/вложенный/второй.md",
                    ]
                ),
            )

            self.assertEqual(affected_errors, [])
            self.assertEqual(status_errors, [])

    def test_git_status_directory_scope_rejects_sibling_prefix_and_deleted_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            affected_directory = root / "Документация" / "модуль"
            affected_directory.mkdir(parents=True)
            sibling = root / "Документация" / "сосед.md"
            sibling.write_text("# Сосед\n", encoding="utf-8")
            prefix = root / "Документация" / "модуль-другой" / "файл.md"
            prefix.parent.mkdir()
            prefix.write_text("# Другой\n", encoding="utf-8")
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- [Модуль](../../Документация/модуль/)",
                    "",
                ]
            )

            affected, affected_errors = (
                check_session_coherence.affected_files_from_request(
                    text,
                    request_path,
                    root,
                )
            )
            status_errors = check_session_coherence.validate_git_status(
                root,
                affected,
                "\n".join(
                    [
                        " M Документация/сосед.md",
                        " M Документация/модуль-другой/файл.md",
                        " D Документация/модуль/удалённый.md",
                    ]
                ),
            )

            self.assertEqual(affected_errors, [])
            self.assertEqual(
                status_errors,
                [
                    "unexpected Git status path: Документация/сосед.md",
                    "unexpected Git status path: Документация/модуль-другой/файл.md",
                    "unexpected Git status path: Документация/модуль/удалённый.md",
                ],
            )

    def test_deleted_direct_files_marker_allows_only_direct_children(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            journal = root / "Журнал"
            (journal / "сессия").mkdir()
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённые непосредственные файлы каталога: `Журнал/`",
                    "",
                ]
            )

            affected, affected_errors = (
                check_session_coherence.affected_files_from_request(
                    text,
                    request_path,
                    root,
                )
            )
            status_errors = check_session_coherence.validate_git_status(
                root,
                affected,
                "\n".join(
                    [
                        "D  Журнал/старый-отчёт.md",
                        "D  Журнал/сессия/вложенный.md",
                        "D  Журнал-снимок/старый-отчёт.md",
                    ]
                ),
            )

            self.assertEqual(affected_errors, [])
            self.assertEqual(
                status_errors,
                [
                    "unexpected Git status path: Журнал/сессия/вложенный.md",
                    "unexpected Git status path: Журнал-снимок/старый-отчёт.md",
                ],
            )

    def test_deleted_direct_files_marker_requires_existing_directory_inside_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённые непосредственные файлы каталога: `Нет/`",
                    "- Удалённые непосредственные файлы каталога: `../вне-репозитория/`",
                    "",
                ]
            )

            _, errors = check_session_coherence.affected_files_from_request(
                text,
                request_path,
                root,
            )

            self.assertEqual(
                errors,
                [
                    "deleted direct-files directory must exist: Нет/",
                    "deleted direct-files directory must stay inside the repository: "
                    "../вне-репозитория/",
                ],
            )

    def test_deleted_subtree_marker_allows_only_its_descendants(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённое поддерево: `Запросы/`",
                    "",
                ]
            )

            affected, affected_errors = (
                check_session_coherence.affected_files_from_request(
                    text,
                    request_path,
                    root,
                )
            )
            status_errors = check_session_coherence.validate_git_status(
                root,
                affected,
                "\n".join(
                    [
                        "D  Запросы/первый.md",
                        "D  Запросы/вложенный/второй.md",
                        "D  Запросы-архив/файл.md",
                        "D  Запросы",
                    ]
                ),
            )

            self.assertEqual(affected_errors, [])
            self.assertEqual(
                status_errors,
                [
                    "unexpected Git status path: Запросы-архив/файл.md",
                    "unexpected Git status path: Запросы",
                ],
            )

    def test_deleted_subtree_marker_requires_absent_path_inside_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            (root / "Запросы").mkdir()
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённое поддерево: `Запросы/`",
                    "- Удалённое поддерево: `../вне-репозитория/`",
                    "",
                ]
            )

            _, errors = check_session_coherence.affected_files_from_request(
                text,
                request_path,
                root,
            )

            self.assertEqual(
                errors,
                [
                    "deleted affected subtree still exists: Запросы/",
                    "deleted affected subtree must stay inside the repository: "
                    "../вне-репозитория/",
                ],
            )

    def test_deleted_file_marker_remains_exact_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root / "Журнал" / "2026-08-03_12-34-56_MSK" / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            text = "\n".join(
                [
                    "## Повлиял на файлы",
                    "",
                    "- Удалённый файл: `Документация/удалённый.md`",
                    "",
                ]
            )

            affected, affected_errors = (
                check_session_coherence.affected_files_from_request(
                    text,
                    request_path,
                    root,
                )
            )
            status_errors = check_session_coherence.validate_git_status(
                root,
                affected,
                "\n".join(
                    [
                        "D  Документация/удалённый.md",
                        "D  Документация/удалённый.md/вложенный.md",
                    ]
                ),
            )

            self.assertEqual(affected_errors, [])
            self.assertEqual(
                status_errors,
                [
                    "unexpected Git status path: "
                    "Документация/удалённый.md/вложенный.md"
                ],
            )

    def test_reports_missing_sibling_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            (request_path.parent / "отчёт.md").unlink()

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertIn(
                "missing sibling report file: Журнал/"
                "2026-06-24_16-32-29_MSK_проверка-связности-сессии/отчёт.md",
                errors,
            )

    def test_affected_files_requires_current_request_and_sibling_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/текущий отчёт](отчёт.md)\n",
                "",
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertIn(
                "affected files section must include sibling report: Журнал/"
                "2026-06-24_16-32-29_MSK_проверка-связности-сессии/отчёт.md",
                errors,
            )

    def test_new_journal_requires_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Журнал").mkdir()
            session_dir = (
                root
                / "Журнал"
                / "2026-07-23_14-47-43_MSK_"
                "включать-профиль-времени-в-отчёты-журнала"
            )
            session_dir.mkdir()
            request_path = session_dir / "запрос.md"
            journal_path = session_dir / "отчёт.md"
            journal_path.write_text(
                "\n".join(
                    [
                        "# Отчёт 2026-07-23 14:47:43 MSK - "
                        "Включать профиль времени в отчёты журнала",
                        "",
                        "Отчёт без профиля времени.",
                        "",
                        "## Источники",
                        "",
                        "- [исходный запрос](запрос.md)",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "missing journal section: Профиль времени выполнения",
                errors,
            )

    def test_new_journal_accepts_two_stage_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Журнал").mkdir()
            session_dir = (
                root
                / "Журнал"
                / "2026-07-23_14-47-43_MSK_"
                "включать-профиль-времени-в-отчёты-журнала"
            )
            session_dir.mkdir()
            request_path = session_dir / "запрос.md"
            journal_path = session_dir / "отчёт.md"
            journal_path.write_text(
                "\n".join(
                    [
                        "# Отчёт 2026-07-23 14:47:43 MSK - "
                        "Включать профиль времени в отчёты журнала",
                        "",
                        "Отчёт с измеренным профилем.",
                        "",
                        "## Профиль времени выполнения",
                        "",
                        "| Стадия | Длительность | Границы и способ измерения |",
                        "| --- | ---: | --- |",
                        "| Анализ | 12 с | Монотонные отметки начала и конца. |",
                        "| Smoke-check | 31 с | Wall-clock `real`. |",
                        "",
                        "Граница профиля: от допуска очереди до завершения smoke-check.",
                        "",
                        "## Источники",
                        "",
                        "- [исходный запрос](запрос.md)",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_current_journal_accepts_each_direct_check_run_and_exact_total(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_stem=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=[
                    "| `python3 -m unittest` | 1,25 с | неуспешно (exit 1) |",
                    "| `python3 -m unittest` | 0.75 с | успешно |",
                    "| `python3 smoke.py` | 2 с | прервано по тайм-ауту |",
                    "| `python3 smoke.py` | 3 с | не завершено из-за остановки |",
                ],
                invocation_total=(
                    "Общее время прямых запусков проверок: 7 с."
                ),
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_current_journal_accepts_escaped_pipe_inside_invocation_cell(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_stem=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=[
                    r"| `printf 'first \| second'` | 1,5 с | успешно |",
                ],
                invocation_total=(
                    "Общее время прямых запусков проверок: 1,5 с."
                ),
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_current_journal_ignores_fake_direct_check_subsection_in_nonsemantic_regions(self):
        fake_subsection = [
            "### Прямые запуски проверок",
            "",
            "| Вызов | Длительность | Результат |",
            "| --- | ---: | --- |",
            "| `python3 fake.py` | 1 с | успешно |",
            "",
            "Общее время прямых запусков проверок: 1 с.",
        ]
        wrappers = (
            ["```markdown", *fake_subsection, "```"],
            ["<!--", *fake_subsection, "-->"],
        )
        for wrapped_subsection in wrappers:
            with self.subTest(wrapper=wrapped_subsection[0]), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                request_path = self.write_time_profile_journal(
                    root,
                    request_stem=(
                        "2026-07-27_16-12-29_MSK_"
                        "учитывать-все-запуски-проверок"
                    ),
                    request_label=(
                        "2026-07-27 16:12:29 MSK - "
                        "Учитывать все запуски проверок"
                    ),
                    invocation_rows=None,
                    invocation_total=None,
                )
                journal_path = request_path.parent / "отчёт.md"
                journal_text = journal_path.read_text(encoding="utf-8")
                journal_path.write_text(
                    journal_text.replace(
                        "\n## Источники",
                        "\n" + "\n".join(wrapped_subsection) + "\n\n## Источники",
                    ),
                    encoding="utf-8",
                )

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                self.assertIn(
                    "missing journal time profile subsection: "
                    "Прямые запуски проверок",
                    errors,
                )

    def test_current_journal_ignores_fake_direct_check_table_in_fenced_code(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_stem=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=None,
                invocation_total=None,
            )
            fake_table = "\n".join(
                [
                    "### Прямые запуски проверок",
                    "",
                    "```markdown",
                    "| Вызов | Длительность | Результат |",
                    "| --- | ---: | --- |",
                    "| `python3 fake.py` | 1 с | успешно |",
                    "",
                    "Общее время прямых запусков проверок: 1 с.",
                    "```",
                ]
            )
            journal_path = request_path.parent / "отчёт.md"
            journal_text = journal_path.read_text(encoding="utf-8")
            journal_path.write_text(
                journal_text.replace(
                    "\n## Источники",
                    f"\n{fake_table}\n\n## Источники",
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "journal direct check runs must contain table columns: "
                "Вызов | Длительность | Результат",
                errors,
            )

    def test_current_journal_ignores_fake_direct_check_total_in_html_comment(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_stem=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=[
                    "| `python3 real.py` | 1 с | успешно |",
                ],
                invocation_total=None,
            )
            journal_path = request_path.parent / "отчёт.md"
            journal_text = journal_path.read_text(encoding="utf-8")
            journal_path.write_text(
                journal_text.replace(
                    "\n## Источники",
                    "\n<!--\nОбщее время прямых запусков проверок: "
                    "1 с.\n-->\n\n## Источники",
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "journal direct check runs must contain exactly one total line: "
                "Общее время прямых запусков проверок:",
                errors,
            )

    def test_current_journal_sums_durations_at_their_actual_precision(self):
        large = f"{'9' * 60}.9"
        exact_total = f"{'9' * 60}.91"
        rounded_total = f"1{'0' * 60}"
        cases = (
            (exact_total, None),
            (
                rounded_total,
                "journal direct check run total must equal the sum of row durations: "
                f"expected {exact_total} с, got {rounded_total} с",
            ),
        )
        for total, expected_error in cases:
            with self.subTest(total=total), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                request_path = self.write_time_profile_journal(
                    root,
                    request_stem=(
                        "2026-07-27_16-12-29_MSK_"
                        "учитывать-все-запуски-проверок"
                    ),
                    request_label=(
                        "2026-07-27 16:12:29 MSK - "
                        "Учитывать все запуски проверок"
                    ),
                    invocation_rows=[
                        f"| `python3 first.py` | {large} с | успешно |",
                        "| `python3 second.py` | 0.01 с | успешно |",
                    ],
                    invocation_total=(
                        f"Общее время прямых запусков проверок: {total} с."
                    ),
                )

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                if expected_error is None:
                    self.assertEqual(errors, [])
                else:
                    self.assertIn(expected_error, errors)

    def test_current_journal_requires_direct_check_run_table_and_total(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_stem=(
                    "2026-07-27_16-12-29_MSK_"
                    "учитывать-все-запуски-проверок"
                ),
                request_label=(
                    "2026-07-27 16:12:29 MSK - "
                    "Учитывать все запуски проверок"
                ),
                invocation_rows=None,
                invocation_total=None,
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "missing journal time profile subsection: "
                "Прямые запуски проверок",
                errors,
            )

    def test_current_journal_rejects_invalid_direct_check_run_accounting(self):
        cases = (
            (
                [],
                "Общее время прямых запусков проверок: 0 с.",
                "journal direct check run table must contain at least one "
                "invocation row",
            ),
            (
                ["| `python3 -m unittest` | 1 мин | успешно |"],
                "Общее время прямых запусков проверок: 60 с.",
                "journal direct check run row 1 has invalid duration: 1 мин",
            ),
            (
                ["| `python3 -m unittest` | 1 с | прошла |"],
                "Общее время прямых запусков проверок: 1 с.",
                "journal direct check run row 1 has invalid result status: прошла",
            ),
            (
                [
                    "| `python3 -m unittest` | 1,2 с | неуспешно |",
                    "| `python3 -m unittest` | 2,3 с | успешно |",
                ],
                "Общее время прямых запусков проверок: 2,3 с.",
                "journal direct check run total must equal the sum of row durations: "
                "expected 3.5 с, got 2.3 с",
            ),
            (
                ["| `python3 -m unittest` | 1 с | успешно |"],
                None,
                "journal direct check runs must contain exactly one total line: "
                "Общее время прямых запусков проверок:",
            ),
        )
        for invocation_rows, invocation_total, expected_error in cases:
            with self.subTest(expected_error=expected_error), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                request_path = self.write_time_profile_journal(
                    root,
                    request_stem=(
                        "2026-07-27_16-12-29_MSK_"
                        "учитывать-все-запуски-проверок"
                    ),
                    request_label=(
                        "2026-07-27 16:12:29 MSK - "
                        "Учитывать все запуски проверок"
                    ),
                    invocation_rows=invocation_rows,
                    invocation_total=invocation_total,
                )

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                self.assertIn(expected_error, errors)

    def test_journal_before_direct_check_run_rule_keeps_old_time_profile_contract(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_time_profile_journal(
                root,
                request_stem=(
                    "2026-07-27_16-12-28_MSK_"
                    "учитывать-старый-профиль-времени"
                ),
                request_label=(
                    "2026-07-27 16:12:28 MSK - "
                    "Учитывать старый профиль времени"
                ),
                invocation_rows=None,
                invocation_total=None,
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_граница_машинного_отчёта_сохраняет_исторический_ручной_профиль(себя):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса = себя.write_time_profile_journal(
                корень,
                request_stem=(
                    "2026-08-04_20-45-25_MSK_"
                    "сохранить-ручной-отчёт"
                ),
                request_label=(
                    "2026-08-04 20:45:25 MSK - "
                    "Сохранить ручной отчёт"
                ),
                invocation_rows=[
                    "| ручной тест | 1 с | успешно |",
                ],
                invocation_total=(
                    "Общее время прямых запусков проверок: 1 с."
                ),
            )

            ошибки = check_session_coherence.validate_journal(
                корень.resolve(),
                путь_запроса.resolve(),
            )

            себя.assertEqual(ошибки, [])

    def test_граница_машинного_отчёта_отклоняет_новый_ручной_профиль(себя):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса = себя.write_time_profile_journal(
                корень,
                request_stem=(
                    "2026-08-04_20-45-26_MSK_"
                    "формировать-отчёты-о-запусках-тестов"
                ),
                request_label=(
                    "2026-08-04 20:45:26 MSK - "
                    "Формировать отчёты о запусках тестов"
                ),
                invocation_rows=[
                    "| ручной тест | 1 с | успешно |",
                ],
                invocation_total=(
                    "Общее время прямых запусков проверок: 1 с."
                ),
            )

            ошибки = check_session_coherence.validate_journal(
                корень.resolve(),
                путь_запроса.resolve(),
            )

            себя.assertTrue(ошибки)

    def test_открытый_машинный_журнал_проходит_с_активной_записью(себя):
        стем = (
            "2026-08-04_20-45-26_MSK_"
            "формировать-отчёты-о-запусках-тестов"
        )
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса, _, _, _ = себя._записать_машинный_профиль(
                корень,
                стем=стем,
                метка=(
                    "2026-08-04 20:45:26 MSK - "
                    "Формировать отчёты о запусках тестов"
                ),
                записи=себя._записи_с_активной(стем),
                состояние="открыт",
            )

            ошибки = check_session_coherence.validate_journal(
                корень.resolve(),
                путь_запроса.resolve(),
            )

            себя.assertEqual(ошибки, [])

    def test_открытый_машинный_журнал_без_активной_записи_отклоняется(себя):
        стем = (
            "2026-08-04_20-45-26_MSK_"
            "формировать-отчёты-о-запусках-тестов"
        )
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса, _, _, _ = себя._записать_машинный_профиль(
                корень,
                стем=стем,
                метка=(
                    "2026-08-04 20:45:26 MSK - "
                    "Формировать отчёты о запусках тестов"
                ),
                записи=себя._завершённые_записи(стем),
                состояние="открыт",
            )

            ошибки = check_session_coherence.validate_journal(
                корень.resolve(),
                путь_запроса.resolve(),
            )

            себя.assertTrue(ошибки)

    def test_закрытый_снимок_и_точно_сформированный_блок_проходят(себя):
        стем = (
            "2026-08-04_20-45-26_MSK_"
            "формировать-отчёты-о-запусках-тестов"
        )
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса, _, путь_снимка, _ = себя._записать_машинный_профиль(
                корень,
                стем=стем,
                метка=(
                    "2026-08-04 20:45:26 MSK - "
                    "Формировать отчёты о запусках тестов"
                ),
                записи=себя._завершённые_записи(стем),
                состояние="закрыт",
            )

            себя.assertIsNotNone(путь_снимка)
            ошибки = check_session_coherence.validate_journal(
                корень.resolve(),
                путь_запроса.resolve(),
            )

            себя.assertEqual(ошибки, [])

    def test_закрытый_отчёт_отклоняет_изменение_удаление_и_перестановку_строк(себя):
        стем = (
            "2026-08-04_20-45-26_MSK_"
            "формировать-отчёты-о-запусках-тестов"
        )
        for изменение in ("изменить", "удалить", "переставить"):
            with себя.subTest(изменение=изменение), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                путь_запроса, _, _, _ = себя._записать_машинный_профиль(
                    корень,
                    стем=стем,
                    метка=(
                        "2026-08-04 20:45:26 MSK - "
                        "Формировать отчёты о запусках тестов"
                    ),
                    записи=себя._завершённые_записи(стем),
                    состояние="закрыт",
                )
                путь_отчёта = путь_запроса.parent / "отчёт.md"
                строки = путь_отчёта.read_text(encoding="utf-8").splitlines()
                номера = [
                    номер
                    for номер, строка in enumerate(строки)
                    if строка.startswith("| [")
                ]
                себя.assertEqual(len(номера), 2)
                if изменение == "изменить":
                    строки[номера[0]] = строки[номера[0]].replace(
                        "первый тест",
                        "подменённый тест",
                    )
                elif изменение == "удалить":
                    del строки[номера[0]]
                    строки = [
                        строка.replace("3,25 с.", "2 с.")
                        for строка in строки
                    ]
                else:
                    строки[номера[0]], строки[номера[1]] = (
                        строки[номера[1]],
                        строки[номера[0]],
                    )
                путь_отчёта.write_text("\n".join(строки) + "\n", encoding="utf-8")

                ошибки = check_session_coherence.validate_journal(
                    корень.resolve(),
                    путь_запроса.resolve(),
                )

                себя.assertTrue(ошибки, изменение)

    def test_закрытый_отчёт_отклоняет_неверный_хэш_снимка_и_записи(себя):
        стем = (
            "2026-08-04_20-45-26_MSK_"
            "формировать-отчёты-о-запусках-тестов"
        )
        for изменение in ("маркер", "запись"):
            with себя.subTest(изменение=изменение), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                путь_запроса, _, путь_снимка, маркер = себя._записать_машинный_профиль(
                    корень,
                    стем=стем,
                    метка=(
                        "2026-08-04 20:45:26 MSK - "
                        "Формировать отчёты о запусках тестов"
                    ),
                    записи=себя._завершённые_записи(стем),
                    состояние="закрыт",
                )
                себя.assertIsNotNone(путь_снимка)
                путь_снимка = Path(путь_снимка)
                путь_отчёта = путь_запроса.parent / "отчёт.md"
                if изменение == "маркер":
                    новый_маркер = маркер.replace(
                        f"sha256=sha256:{себя._хэш_машинных_данных(путь_снимка.read_bytes())}",
                        f"sha256=sha256:{'0' * 64}",
                    )
                    путь_отчёта.write_text(
                        путь_отчёта.read_text(encoding="utf-8").replace(маркер, новый_маркер),
                        encoding="utf-8",
                    )
                else:
                    прежние_байты = путь_снимка.read_bytes()
                    снимок = json.loads(прежние_байты)
                    снимок["файлы"][0]["sha256"] = "0" * 64
                    новые_байты = себя._канонические_машинные_байты(снимок)
                    путь_снимка.write_bytes(новые_байты)
                    новый_маркер = маркер.replace(
                        f"sha256=sha256:{себя._хэш_машинных_данных(прежние_байты)}",
                        f"sha256=sha256:{себя._хэш_машинных_данных(новые_байты)}",
                    )
                    путь_отчёта.write_text(
                        путь_отчёта.read_text(encoding="utf-8").replace(маркер, новый_маркер),
                        encoding="utf-8",
                    )

                ошибки = check_session_coherence.validate_journal(
                    корень.resolve(),
                    путь_запроса.resolve(),
                )

                себя.assertTrue(ошибки, изменение)

    def test_закрытый_отчёт_отклоняет_лишнюю_запись_журнала(себя):
        стем = (
            "2026-08-04_20-45-26_MSK_"
            "формировать-отчёты-о-запусках-тестов"
        )
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            путь_запроса, каталог, _, _ = себя._записать_машинный_профиль(
                корень,
                стем=стем,
                метка=(
                    "2026-08-04 20:45:26 MSK - "
                    "Формировать отчёты о запусках тестов"
                ),
                записи=себя._завершённые_записи(стем),
                состояние="закрыт",
            )
            лишняя_запись = себя._запись_запуска(
                стем=стем,
                порядок=3,
                идентификатор="00000000-0000-4000-8000-000000000004",
                исполнитель="корень",
                вызов="лишний тест",
                длительность_наносекунды=500_000_000,
            )
            (каталог / "000003_00000000-0000-4000-8000-000000000004.json").write_bytes(
                себя._канонические_машинные_байты(лишняя_запись)
            )

            ошибки = check_session_coherence.validate_journal(
                корень.resolve(),
                путь_запроса.resolve(),
            )

            себя.assertTrue(ошибки)

    def test_new_journal_rejects_incomplete_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Журнал").mkdir()
            session_dir = (
                root
                / "Журнал"
                / "2026-07-23_14-47-43_MSK_"
                "включать-профиль-времени-в-отчёты-журнала"
            )
            session_dir.mkdir()
            request_path = session_dir / "запрос.md"
            journal_path = session_dir / "отчёт.md"
            journal_path.write_text(
                "\n".join(
                    [
                        "# Отчёт 2026-07-23 14:47:43 MSK - "
                        "Включать профиль времени в отчёты журнала",
                        "",
                        "## Профиль времени выполнения",
                        "",
                        "| Стадия | Длительность | Границы и способ измерения |",
                        "| --- | ---: | --- |",
                        "| Анализ | 12 с | Монотонные отметки начала и конца. |",
                        "",
                        "## Источники",
                        "",
                        "- [исходный запрос](запрос.md)",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertIn(
                "journal time profile must contain at least two stage rows",
                errors,
            )
            self.assertIn(
                "journal time profile must contain a non-empty boundary line "
                "after its table: Граница профиля:",
                errors,
            )

    def test_new_journal_rejects_early_or_empty_time_profile_boundary(self):
        for boundary_before, boundary_after in (
            ("Граница профиля: до таблицы.", None),
            (None, "Граница профиля:"),
        ):
            with self.subTest(
                boundary_before=boundary_before,
                boundary_after=boundary_after,
            ), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "Журнал").mkdir()
                session_dir = (
                    root
                    / "Журнал"
                    / "2026-07-23_14-47-43_MSK_"
                    "включать-профиль-времени-в-отчёты-журнала"
                )
                session_dir.mkdir()
                request_path = session_dir / "запрос.md"
                journal_path = session_dir / "отчёт.md"
                lines = [
                    "# Отчёт 2026-07-23 14:47:43 MSK - "
                    "Включать профиль времени в отчёты журнала",
                    "",
                    "## Профиль времени выполнения",
                    "",
                ]
                if boundary_before is not None:
                    lines.extend([boundary_before, ""])
                lines.extend(
                    [
                        "| Стадия | Длительность | Границы и способ измерения |",
                        "| --- | ---: | --- |",
                        "| Анализ | 12 с | Монотонные отметки. |",
                        "| Smoke-check | 31 с | Wall-clock `real`. |",
                        "",
                    ]
                )
                if boundary_after is not None:
                    lines.extend([boundary_after, ""])
                lines.extend(
                    [
                        "## Источники",
                        "",
                        "- [исходный запрос](запрос.md)",
                        "",
                    ]
                )
                journal_path.write_text("\n".join(lines), encoding="utf-8")

                errors = check_session_coherence.validate_journal(
                    root.resolve(),
                    request_path.resolve(),
                )

                self.assertIn(
                    "journal time profile must contain a non-empty boundary line "
                    "after its table: Граница профиля:",
                    errors,
                )

    def test_historical_journal_does_not_require_time_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)

            errors = check_session_coherence.validate_journal(
                root.resolve(),
                request_path.resolve(),
            )

            self.assertEqual(errors, [])

    def test_reports_broken_markdown_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            broken = request_path.read_text(encoding="utf-8").replace(
                "../Документация/17-воспроизводимые-автоматизации.md",
                "../Документация/нет-такого-файла.md",
            )
            request_path.write_text(broken, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertTrue(
                any("broken Markdown link" in error for error in errors),
                errors,
            )

    def test_request_text_links_are_raw_provenance_but_links_after_it_remain_active(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = (
                root
                / "Журнал"
                / "2026-08-03_12-34-56_MSK_проверить-ссылки"
                / "запрос.md"
            )
            request_path.parent.mkdir(parents=True)
            request_path.write_text(
                "# Исходный запрос 2026-08-03 12:34:56 MSK - Проверить ссылки\n\n"
                "## Текст запроса\n\n"
                "> Дословная [историческая ссылка](../нет-такого-файла.md).\n\n"
                "## Результат\n\n"
                "Активная [битая ссылка](../тоже-нет.md).\n",
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_markdown_links(
                {request_path},
                root,
            )

            self.assertEqual(len(errors), 1)
            self.assertIn("тоже-нет.md", errors[0])
            self.assertNotIn("нет-такого-файла.md", errors[0])

    def test_rejects_absolute_and_escaping_local_markdown_links(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "Документация"
            docs.mkdir()
            outside = root.parent / f"{root.name}-outside.md"
            outside.write_text("# Outside\n", encoding="utf-8")
            self.addCleanup(outside.unlink)
            source = docs / "индекс.md"
            targets = (
                outside.as_posix(),
                f"../../{outside.name}",
                f"file://{outside.as_posix()}",
                "C:\\repo\\outside.md",
                "\\\\server\\share\\outside.md",
            )

            for target in targets:
                with self.subTest(target=target):
                    source.write_text(
                        f"# Индекс\n\n[внешняя цель](<{target}>)\n",
                        encoding="utf-8",
                    )
                    errors = check_session_coherence.validate_markdown_links(
                        {source},
                        root,
                    )
                    self.assertTrue(
                        any(
                            "local Markdown link" in error
                            and "Документация/индекс.md:3" in error
                            for error in errors
                        ),
                        errors,
                    )

    def test_external_url_and_relative_link_inside_repository_remain_valid(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "Документация" / "вложенная"
            docs.mkdir(parents=True)
            target = root / "README.md"
            target.write_text("# README\n", encoding="utf-8")
            source = docs / "индекс.md"
            source.write_text(
                "# Индекс\n\n"
                "[репозиторий](../../README.md)\n"
                "[сайт](https://example.invalid/path)\n",
                encoding="utf-8",
            )

            self.assertEqual(
                check_session_coherence.validate_markdown_links({source}, root),
                [],
            )

    def test_nested_shorter_fence_does_not_expose_markdown_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs = root / "Документация"
            docs.mkdir()
            target = root / "README.md"
            target.write_text("# README\n", encoding="utf-8")
            source = docs / "индекс.md"
            source.write_text(
                "# Индекс\n\n"
                "````text\n"
                "<input>\n"
                "```json\n"
                '{"task":"[термин](../../Глоссарий/термин.md)"}\n'
                "```\n"
                "</input>\n"
                "````\n\n"
                "[README](../README.md)\n",
                encoding="utf-8",
            )

            links = check_session_coherence.iter_markdown_links(source)

            self.assertEqual(
                [(link.line, link.target) for link in links],
                [(11, "../README.md")],
            )
            self.assertEqual(
                check_session_coherence.validate_markdown_links({source}, root),
                [],
            )

    def test_reports_case_mismatched_markdown_link_anywhere_in_repo(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            note = root / "Документация" / "индекс.md"
            note.write_text(
                "\n".join(
                    [
                        "# Индекс",
                        "",
                        "[автоматизации](../документация/17-воспроизводимые-автоматизации.md)",
                        "",
                    ]
                ),
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertTrue(
                any(
                    "Markdown link case mismatch in Документация/индекс.md:3" in error
                    and "points to Документация/17-воспроизводимые-автоматизации.md"
                    in error
                    for error in errors
                ),
                errors,
            )

    def test_ignored_build_and_cache_markdown_files_are_not_checked(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            ignored_paths = [
                ".build/checkouts/vendor/README.md",
                ".swiftpm/cache/README.md",
                ".obsidian/cache/README.md",
                ".obsidian/plugins/local/README.md",
            ]
            for relative in ignored_paths:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(
                    "# Ignored cache\n\n[broken](missing-target.md)\n",
                    encoding="utf-8",
                )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertEqual(errors, [])

    def test_reports_unlisted_git_status_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            git_status = "?? temporary-debug.log\n"

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status=git_status,
            )

            self.assertIn("unexpected Git status path: temporary-debug.log", errors)

    def test_reports_md_recency_check_failure_when_tool_exists(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            script = (
                root
                / "Инструменты"
                / "fum-svezhestj-markdown"
                / "scripts"
                / "update-md-recency.py"
            )
            script.parent.mkdir(parents=True)
            script.write_text(
                "import sys\nprint('stale recency index', file=sys.stderr)\nsys.exit(1)\n",
                encoding="utf-8",
            )

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="",
            )

            self.assertIn(
                "md recency check failed: stale recency index",
                errors,
            )

    def test_reports_possible_meta_request_without_request_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            note = root / "Документация" / "служебная-записка.md"
            note.write_text(
                "\n".join(
                    [
                        "# Служебная записка",
                        "",
                        "Пользователь уточнил правило ведения памяти FUM: такие ответы надо сохранять в папке запроса.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/текущий отчёт](отчёт.md)",
                "\n".join(
                    [
                        "- [Документация/служебная-записка.md](../../Документация/служебная-записка.md)",
                        "- [Журнал/текущий отчёт](отчёт.md)",
                    ]
                ),
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="?? Документация/служебная-записка.md",
            )

            self.assertIn(
                "possible unregistered meta request in Документация/служебная-записка.md:3: add a link to a concrete Журнал/<session-stem>/запрос.md or create a separate request folder",
                errors,
            )

    def test_detects_meta_request_context_from_request_folder_marker(self):
        text = "Пользователь спросил, нужно ли сохранять это в папке запроса."

        line = check_session_coherence.possible_meta_request_line(text)

        self.assertEqual(line, 1)

    def test_reports_top_provenance_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            note = root / "Документация" / "служебная-записка.md"
            note.write_text(
                "\n".join(
                    [
                        "# Служебная записка",
                        "",
                        "Источники требований:",
                        "",
                        "- [исходный запрос 2026-06-24 16:32:29 MSK - Проверка связности сессии](../Журнал/2026-06-24_16-32-29_MSK_проверка-связности-сессии/запрос.md)",
                        "",
                        "## Содержание",
                        "",
                        "Основной текст.",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/текущий отчёт](отчёт.md)",
                "\n".join(
                    [
                        "- [Документация/служебная-записка.md](../../Документация/служебная-записка.md)",
                        "- [Журнал/текущий отчёт](отчёт.md)",
                    ]
                ),
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="?? Документация/служебная-записка.md",
            )

            self.assertIn(
                "provenance section must follow content in Документация/служебная-записка.md:3: move 'Источники требований:' to the bottom of the file before FUM-MD-RECENCY",
                errors,
            )

    def test_reports_mermaid_label_that_starts_as_markdown_list(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_path = self.write_fixture(root)
            diagram = root / "Документация" / "диаграмма.md"
            diagram.write_text(
                "\n".join(
                    [
                        "# Диаграмма",
                        "",
                        "```mermaid",
                        "flowchart TD",
                        '    A["1. Первый шаг"]',
                        '    B["Этап 2 - Второй шаг"]',
                        "```",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            request_text = request_path.read_text(encoding="utf-8").replace(
                "- [Журнал/текущий отчёт](отчёт.md)",
                "\n".join(
                    [
                        "- [Документация/диаграмма.md](../../Документация/диаграмма.md)",
                        "- [Журнал/текущий отчёт](отчёт.md)",
                    ]
                ),
            )
            request_path.write_text(request_text, encoding="utf-8")

            errors = check_session_coherence.validate_session(
                root,
                request_path.relative_to(root),
                git_status="?? Документация/диаграмма.md",
            )

            self.assertIn(
                "unsupported Mermaid Markdown list label in Документация/диаграмма.md:5: use text like 'Этап 1 - ...' instead of '1. ...'",
                errors,
            )


if __name__ == "__main__":
    unittest.main()
