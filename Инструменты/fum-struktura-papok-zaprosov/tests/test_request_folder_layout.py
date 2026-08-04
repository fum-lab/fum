from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


TOOL_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = TOOL_ROOT / "scripts"
MODULE = SCRIPTS / "request_folder_layout.py"
CLI = SCRIPTS / "struktura-papok-zaprosov.py"
ШАБЛОНЫ = TOOL_ROOT / "шаблоны"
СВЯЗНОСТЬ = (
    TOOL_ROOT.parent
    / "fum-svyaznostj-rabochej-sessii"
    / "scripts"
    / "check-session-coherence.py"
)

EARLY = "2026-06-23_18-43-31_MSK"
LATE = "2026-06-24_13-57-52_MSK_vtoroj-zapros"
NEW = "2026-08-03_12-00-00_MSK_создать-новый-запрос"
THREAD_ID = "019fc66e-2668-77e1-8b1a-45d82a17b99a"


def navigation(previous: str | None, following: str | None) -> str:
    previous_value = (
        f"[Предыдущий](../{previous}/запрос.md)" if previous else "нет"
    )
    following_value = (
        f"[Следующий](../{following}/запрос.md)" if following else "нет"
    )
    return (
        "## Навигация по запросам\n\n"
        f"- Предыдущий запрос: {previous_value}\n"
        f"- Следующий запрос: {following_value}\n"
    )


def legacy_navigation(previous: str | None, following: str | None) -> str:
    previous_value = (
        f"[Предыдущий]({previous}.md)" if previous else "нет"
    )
    following_value = (
        f"[Следующий]({following}.md)" if following else "нет"
    )
    return (
        "## Навигация по запросам\n\n"
        f"- Предыдущий запрос: {previous_value}\n"
        f"- Следующий запрос: {following_value}\n"
    )


def request_document(
    stem: str,
    *,
    previous: str | None,
    following: str | None,
    legacy: bool,
    message: str = "Запрос.",
    heading_title: str | None = None,
) -> str:
    nav = legacy_navigation(previous, following) if legacy else navigation(previous, following)
    time_label = f"{stem[:10]} {stem[11:19].replace('-', ':')} MSK"
    return (
        f"# Исходный запрос {time_label}"
        f"{' - ' + heading_title if heading_title else ''}\n\n"
        f"{nav}\n"
        "## Текст запроса\n\n"
        "````text\n"
        f"{message}\n"
        "Дословно: Запросы/legacy.md и "
        "[ссылка](../Документация/target.md)\n"
        "````\n\n"
        "## Идентификатор сеанса Codex\n\n"
        f"Codex-Thread-ID: {THREAD_ID}\n"
    )


class RepositoryFixture:
    def __init__(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.git("init", "-q")
        self.git("config", "user.name", "FUM Test")
        self.git("config", "user.email", "fum-test@example.invalid")

    def close(self) -> None:
        self.temporary.cleanup()

    def git(self, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", *arguments],
            cwd=self.root,
            check=check,
            capture_output=True,
            text=True,
        )

    def write(self, relative: str, content: str | bytes, mode: int = 0o644) -> Path:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding="utf-8")
        path.chmod(mode)
        return path

    def commit(self) -> None:
        self.git("add", "--all")
        self.git("commit", "-qm", "fixture")

    def run_tool(
        self,
        mode: str,
        *arguments: str,
        stdin: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(CLI),
                mode,
                "--repo-root",
                str(self.root),
                *arguments,
            ],
            cwd=self.root,
            input=stdin,
            check=False,
            capture_output=True,
            text=True,
        )

    def make_legacy_layout(self) -> bytes:
        protected_message = (
            "Байты этого блока нельзя менять.\n"
            "Путь Запросы/old.md и [target](../Документация/target.md)."
        )
        early = request_document(
            EARLY,
            previous=None,
            following=LATE,
            legacy=True,
            message=protected_message,
        )
        early += (
            "\n## Прикреплённый материал\n\n"
            f"[Пакет](../Источники/{EARLY}_appshot/)\n"
            "[`.gitignore`](../.gitignore)\n"
            "[`README.md`](../README.md)\n"
            "[`Журнал/README.md`](../Журнал/README.md)\n"
        )
        late = request_document(
            LATE,
            previous=EARLY,
            following=None,
            legacy=True,
            heading_title="Vtoroj: особый Запрос!",
        )
        self.write(f"Запросы/{EARLY}.md", early)
        self.write(f"Запросы/{LATE}.md", late)
        self.write(
            f"Журнал/{LATE}.md",
            "# Отчёт\n\n"
            f"[запрос](../Запросы/{LATE}.md)\n"
            "[цель](../Документация/target.md)\n",
            mode=0o755,
        )
        self.write(
            "Журнал/README.md",
            "# Журнал\n\n## Отчёты\n\n"
            f"- [Второй]({LATE}.md) — точное курированное описание.\n\n"
            "## Источники требований\n\n"
            f"- [Дубль из источников](../Запросы/{LATE}.md)\n",
        )
        self.write("Документация/target.md", "# Target\n")
        self.write(
            "Документация/incoming.md",
            f"[запрос](../Запросы/{LATE}.md)\n"
            f"[отчёт](../Журнал/{LATE}.md)\n",
        )
        review_name = "2026-06-24_14-00-00_MSK_revyu"
        self.write(
            f"Ревью/{review_name}.md",
            "# Ревью\n\n"
            f"[владелец](../Запросы/{LATE}.md)\n",
        )
        self.write(
            f"Ревью/Автоматизации/{review_name}.json",
            json.dumps(
                {
                    "request_file": f"Запросы/{LATE}.md",
                    "report_file": f"Журнал/{LATE}.md",
                    "config_file": f"Ревью/Автоматизации/{review_name}.json",
                    "checks": [
                        {
                            "command": f"python check.py --request Запросы/{LATE}.md"
                        }
                    ],
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
        )
        estimate_name = "ocenka"
        self.write(
            f"Оценки/{estimate_name}.md",
            "# Оценка\n\n"
            f"[владелец](../Запросы/{EARLY}.md)\n",
        )
        self.write(
            f"Оценки/Автоматизации/{estimate_name}.json",
            json.dumps(
                {"request_file": f"Запросы/{EARLY}.md"},
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
        )
        self.write(
            f"Источники/{EARLY}_appshot/извлечение.md",
            f"[Владелец](../../Запросы/{EARLY}.md)\n"
            "[Цель](../../Документация/target.md)\n"
            "Сырые байты Запросы/old.md\n",
        )
        self.write(".gitignore", ".build/\n")
        self.write("README.md", "# Root\n")
        self.write(
            "Источники/URL/https/example.test/shared.md",
            f"Сырой URL-снимок: Запросы/{EARLY}.md\n",
        )
        self.write(
            "Источники/URL/https/example.test/source-index.md",
            f"[Исходный запрос](../../../../Запросы/{LATE}.md)\n",
        )
        self.write(
            "Источники/URL/https/example.test/response.body.md",
            f"[Сырой payload](../../../../Запросы/{LATE}.md)\n",
        )
        self.write(
            "Документация/live.json",
            json.dumps(
                {
                    "provenance_refs": [f"Запросы/{LATE}.md#fragment"],
                    "exceptions": [{"path": f"Запросы/{EARLY}.md"}],
                    "narrative": f"Исторически упомянут Запросы/{EARLY}.md",
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
        )
        self.write(
            "Документация/pinned.json",
            json.dumps(
                {
                    "state_ref": "git:commit:" + "a" * 40,
                    "publication_ref": f"Запросы/{EARLY}.md",
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
        )
        self.write(
            "Документация/frozen.json",
            json.dumps(
                {
                    "package_id": "immutable.v1",
                    "inputs": [
                        {
                            "path": f"Запросы/{EARLY}.md",
                            "sha256": "sha256:" + "b" * 64,
                        }
                    ],
                    "change_scope": {"excluded_paths": ["Запросы"]},
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
        )
        self.commit()
        marker = "## Текст запроса\n"
        start = early.index(marker) + len(marker)
        return early[start:].split("\n## Идентификатор", 1)[0].encode("utf-8")

    def make_canonical_layout(self) -> None:
        self.write(
            "Журнал/README.md",
            "# Журнал\n\n## Сессии\n\n"
            f"- [Второй]({LATE}/отчёт.md)\n",
        )
        self.write(
            f"Журнал/{LATE}/запрос.md",
            request_document(
                LATE,
                previous=None,
                following=None,
                legacy=False,
                heading_title="Vtoroj: особый Запрос!",
            ),
        )
        self.write(
            f"Журнал/{LATE}/отчёт.md",
            "# Отчёт\n\n[Исходный запрос](запрос.md)\n",
        )
        self.commit()


class RequestFolderLayoutTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = RepositoryFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def load_module(self, name: str = "request_folder_layout_test") -> object:
        spec = importlib.util.spec_from_file_location(name, MODULE)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module

    def test_plan_builds_complete_simultaneous_manifest_without_mutation(self) -> None:
        self.fixture.make_legacy_layout()
        before_status = self.fixture.git("status", "--porcelain=v1", "-z").stdout
        index = self.fixture.root / ".git" / "index"
        before_index = index.read_bytes()

        first = self.fixture.run_tool("plan")
        second = self.fixture.run_tool("plan")

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(first.stdout, second.stdout)
        payload = json.loads(first.stdout)
        self.assertEqual(payload["mode"], "plan")
        manifest = {
            item["source"]: item["destination"] for item in payload["moves"]
        }
        self.assertEqual(
            manifest[f"Запросы/{EARLY}.md"],
            f"Журнал/{EARLY}/запрос.md",
        )
        self.assertEqual(
            manifest[f"Журнал/{LATE}.md"],
            f"Журнал/{LATE}/отчёт.md",
        )
        self.assertNotIn(f"Журнал/{EARLY}/отчёт.md", manifest.values())
        self.assertEqual(
            manifest["Оценки/ocenka.md"],
            f"Журнал/{EARLY}/материалы/оценки/ocenka.md",
        )
        self.assertEqual(
            manifest[
                f"Источники/{EARLY}_appshot/извлечение.md"
            ],
            f"Журнал/{EARLY}/материалы/источники/appshot/извлечение.md",
        )
        self.assertNotIn("Источники/URL/https/example.test/shared.md", manifest)
        self.assertEqual(payload["schema_version"], 1)
        classifications = {
            (item["file"], item["pointer"]): (item["classification"], item["reason"])
            for item in payload["json_references"]
        }
        review_config = "Ревью/Автоматизации/2026-06-24_14-00-00_MSK_revyu.json"
        self.assertEqual(classifications[(review_config, "/request_file")][0], "rewrite")
        self.assertEqual(classifications[(review_config, "/checks/0/command")][0], "preserve")
        self.assertEqual(
            classifications[("Документация/pinned.json", "/publication_ref")],
            ("preserve", "pinned_git_commit"),
        )
        self.assertEqual(
            classifications[("Документация/frozen.json", "/inputs/0/path")],
            ("preserve", "immutable_hashed_package"),
        )
        self.assertEqual(self.fixture.git("status", "--porcelain=v1", "-z").stdout, before_status)
        self.assertEqual(index.read_bytes(), before_index)

    def test_plan_is_clone_independent_and_contains_only_relative_paths(self) -> None:
        self.fixture.make_legacy_layout()
        first = self.fixture.run_tool("plan")
        self.assertEqual(first.returncode, 0, first.stderr)
        with tempfile.TemporaryDirectory() as temporary:
            clone = Path(temporary) / "independent-fork"
            subprocess.run(
                ["git", "clone", "-q", str(self.fixture.root), str(clone)],
                check=True,
                capture_output=True,
                text=True,
            )
            second = subprocess.run(
                [sys.executable, str(CLI), "plan", "--repo-root", str(clone)],
                cwd=clone,
                check=False,
                capture_output=True,
                text=True,
            )
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(first.stdout, second.stdout)
        payload = json.loads(first.stdout)
        rendered = json.dumps(payload, ensure_ascii=False)
        self.assertNotIn(str(self.fixture.root), rendered)
        self.assertNotIn(tempfile.gettempdir(), rendered)
        for item in payload["moves"]:
            self.assertFalse(Path(item["source"]).is_absolute())
            self.assertFalse(Path(item["destination"]).is_absolute())

    def test_plan_ignores_build_cache_but_rejects_publishable_invalid_json(self) -> None:
        self.fixture.make_legacy_layout()
        self.fixture.write("Прототипы/demo/.build/dry-archive-report.json", "{ invalid\n")

        accepted = self.fixture.run_tool("plan")

        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertNotIn("dry-archive-report.json", accepted.stdout)

        self.fixture.write("Документация/untracked-invalid.json", "{ invalid\n")
        rejected = self.fixture.run_tool("plan")

        self.assertEqual(rejected.returncode, 1)
        self.assertIn("invalid json", rejected.stderr.casefold())

    def test_apply_rewrites_links_and_path_fields_but_preserves_request_text(self) -> None:
        protected_before = self.fixture.make_legacy_layout()
        report_mode = (self.fixture.root / f"Журнал/{LATE}.md").stat().st_mode & 0o777

        result = self.fixture.run_tool("apply")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.fixture.root / "Запросы").exists())
        early_request = self.fixture.root / f"Журнал/{EARLY}/запрос.md"
        late_request = self.fixture.root / f"Журнал/{LATE}/запрос.md"
        late_report = self.fixture.root / f"Журнал/{LATE}/отчёт.md"
        self.assertTrue(early_request.is_file())
        self.assertTrue(late_request.is_file())
        self.assertTrue(late_report.is_file())
        self.assertFalse((self.fixture.root / f"Журнал/{EARLY}/отчёт.md").exists())
        self.assertEqual(late_report.stat().st_mode & 0o777, report_mode)

        early_text = early_request.read_text(encoding="utf-8")
        marker = "## Текст запроса\n"
        protected_after = early_text[early_text.index(marker) + len(marker) :].split(
            "\n## Идентификатор", 1
        )[0].encode("utf-8")
        self.assertEqual(protected_after, protected_before)
        self.assertIn(f"../{LATE}/запрос.md", early_text)
        self.assertIn("[`.gitignore`](../../.gitignore)", early_text)
        self.assertIn("[`README.md`](../../README.md)", early_text)
        self.assertIn("[`Журнал/README.md`](../README.md)", early_text)
        self.assertIn(f"../{EARLY}/запрос.md", late_request.read_text(encoding="utf-8"))
        self.assertIn("[запрос](запрос.md)", late_report.read_text(encoding="utf-8"))
        self.assertIn("../../Документация/target.md", late_report.read_text(encoding="utf-8"))
        self.assertEqual(
            (self.fixture.root / "Документация/incoming.md").read_text(encoding="utf-8"),
            f"[запрос](../Журнал/{LATE}/запрос.md)\n"
            f"[отчёт](../Журнал/{LATE}/отчёт.md)\n",
        )

        review_json = json.loads(
            (
                self.fixture.root
                / f"Журнал/{LATE}/материалы/ревью/2026-06-24_14-00-00_MSK_revyu.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(review_json["request_file"], f"Журнал/{LATE}/запрос.md")
        self.assertEqual(review_json["report_file"], f"Журнал/{LATE}/отчёт.md")
        self.assertEqual(
            review_json["config_file"],
            f"Журнал/{LATE}/материалы/ревью/2026-06-24_14-00-00_MSK_revyu.json",
        )
        self.assertIn(f"Запросы/{LATE}.md", review_json["checks"][0]["command"])
        live = json.loads((self.fixture.root / "Документация/live.json").read_text(encoding="utf-8"))
        self.assertEqual(live["provenance_refs"], [f"Журнал/{LATE}/запрос.md#fragment"])
        self.assertEqual(live["exceptions"], [{"path": f"Журнал/{EARLY}/запрос.md"}])
        self.assertIn(f"Запросы/{EARLY}.md", live["narrative"])
        self.assertIn(
            f"Запросы/{EARLY}.md",
            (self.fixture.root / "Документация/pinned.json").read_text(encoding="utf-8"),
        )
        self.assertIn(
            f"Запросы/{EARLY}.md",
            (self.fixture.root / "Документация/frozen.json").read_text(encoding="utf-8"),
        )
        source_metadata = (
            self.fixture.root
            / f"Журнал/{EARLY}/материалы/источники/appshot/извлечение.md"
        )
        self.assertTrue(source_metadata.is_file())
        self.assertEqual(
            source_metadata.read_text(encoding="utf-8"),
            f"[Владелец](../../../запрос.md)\n"
            "[Цель](../../../../../Документация/target.md)\n"
            "Сырые байты Запросы/old.md\n",
        )
        self.assertTrue((self.fixture.root / "Источники/URL/https/example.test/shared.md").is_file())
        self.assertEqual(
            (
                self.fixture.root
                / "Источники/URL/https/example.test/source-index.md"
            ).read_text(encoding="utf-8"),
            f"[Исходный запрос](../../../../Журнал/{LATE}/запрос.md)\n",
        )
        self.assertEqual(
            (
                self.fixture.root
                / "Источники/URL/https/example.test/response.body.md"
            ).read_text(encoding="utf-8"),
            f"[Сырой payload](../../../../Запросы/{LATE}.md)\n",
        )
        index_text = (self.fixture.root / "Журнал/README.md").read_text(encoding="utf-8")
        self.assertIn("## Сессии", index_text)
        self.assertNotIn("## Отчёты", index_text)
        self.assertIn(f"{EARLY}/запрос.md", index_text)
        self.assertIn(f"{LATE}/отчёт.md", index_text)
        self.assertIn(
            f"- [Второй]({LATE}/отчёт.md) — точное курированное описание.",
            index_text,
        )
        self.assertIn(
            f"- [Дубль из источников]({LATE}/запрос.md)",
            index_text,
        )

        validated = self.fixture.run_tool("validate")
        self.assertEqual(validated.returncode, 0, validated.stderr)
        self.assertEqual(json.loads(validated.stdout)["sessions"], 2)

    def test_plan_fails_closed_for_orphan_invalid_collision_symlink_and_guessed_owner(self) -> None:
        cases: list[tuple[str, str]] = []

        orphan = RepositoryFixture()
        try:
            orphan.write("Запросы/2026-06-23_18-43-31_MSK_ok.md", "# Request\n")
            orphan.write("Журнал/2026-06-24_13-57-52_MSK_orphan.md", "# Report\n")
            orphan.write("Журнал/README.md", "# Journal\n")
            orphan.commit()
            cases.append((orphan.run_tool("plan").stderr, "orphan"))
        finally:
            orphan.close()

        invalid = RepositoryFixture()
        try:
            invalid.write("Запросы/bez-vremeni.md", "# Request\n")
            invalid.write("Журнал/README.md", "# Journal\n")
            invalid.commit()
            cases.append((invalid.run_tool("plan").stderr, "session stem"))
        finally:
            invalid.close()

        collision = RepositoryFixture()
        try:
            stem = "2026-06-23_18-43-31_MSK_Test"
            collision.write(f"Запросы/{stem}.md", "# Request\n")
            collision.write(f"Журнал/{stem.casefold()}", b"occupied")
            collision.write("Журнал/README.md", "# Journal\n")
            collision.commit()
            cases.append((collision.run_tool("plan").stderr, "collision"))
        finally:
            collision.close()

        symlink = RepositoryFixture()
        try:
            symlink.write("real/2026-06-23_18-43-31_MSK_ok.md", "# Request\n")
            (symlink.root / "Запросы").symlink_to("real", target_is_directory=True)
            symlink.write("Журнал/README.md", "# Journal\n")
            symlink.git("add", "--all")
            symlink.git("commit", "-qm", "fixture")
            cases.append((symlink.run_tool("plan").stderr, "symbolic"))
        finally:
            symlink.close()

        guessed = RepositoryFixture()
        try:
            stem = "2026-06-23_18-43-31_MSK_same-time"
            guessed.write(f"Запросы/{stem}.md", "# Request\n")
            guessed.write("Журнал/README.md", "# Journal\n")
            guessed.write(f"Ревью/{stem}.md", "# No explicit owner\n")
            guessed.commit()
            cases.append((guessed.run_tool("plan").stderr, "owner"))
        finally:
            guessed.close()

        guessed_source = RepositoryFixture()
        try:
            stem = "2026-06-23_18-43-31_MSK_same-time"
            guessed_source.write(f"Запросы/{stem}.md", "# Request\n")
            guessed_source.write("Журнал/README.md", "# Journal\n")
            guessed_source.write(
                f"Источники/{stem}_looks-owned/raw.md",
                "# No explicit owner\n",
            )
            guessed_source.commit()
            cases.append((guessed_source.run_tool("plan").stderr, "owner"))
        finally:
            guessed_source.close()

        for stderr, expected in cases:
            with self.subTest(expected=expected):
                self.assertIn(expected, stderr.casefold())

    def test_apply_failure_rolls_back_exact_dirty_state(self) -> None:
        self.fixture.make_legacy_layout()
        self.fixture.write("staged.md", "before\n")
        self.fixture.write("unstaged.md", "before\n")
        self.fixture.commit()
        self.fixture.write("staged.md", "staged change\n")
        self.fixture.git("add", "--", "staged.md")
        self.fixture.write("unstaged.md", "unstaged change\n")
        before_status = self.fixture.git("status", "--porcelain=v1", "-z").stdout
        before_index = (self.fixture.root / ".git/index").read_bytes()
        before_files = {
            path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
            for path in self.fixture.root.rglob("*")
            if path.is_file() and ".git" not in path.parts
        }
        before_directories = {
            path.relative_to(self.fixture.root).as_posix()
            for path in self.fixture.root.rglob("*")
            if path.is_dir() and ".git" not in path.parts
        }

        module = self.load_module("request_folder_layout_rollback")
        real_install = module._install_prepared_file
        calls = 0

        def fail_second(*args: object, **kwargs: object) -> object:
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("injected install failure")
            return real_install(*args, **kwargs)

        stderr = io.StringIO()
        with mock.patch.object(module, "_install_prepared_file", side_effect=fail_second):
            with contextlib.redirect_stderr(stderr):
                result = module.main(["apply", "--repo-root", str(self.fixture.root)])

        self.assertEqual(result, 1)
        self.assertIn("rolled back", stderr.getvalue())
        self.assertEqual(self.fixture.git("status", "--porcelain=v1", "-z").stdout, before_status)
        self.assertEqual((self.fixture.root / ".git/index").read_bytes(), before_index)
        after_files = {
            path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
            for path in self.fixture.root.rglob("*")
            if path.is_file() and ".git" not in path.parts
        }
        self.assertEqual(after_files, before_files)
        after_directories = {
            path.relative_to(self.fixture.root).as_posix()
            for path in self.fixture.root.rglob("*")
            if path.is_dir() and ".git" not in path.parts
        }
        self.assertEqual(after_directories, before_directories)

    def test_validate_rejects_active_legacy_path_but_ignores_literal_and_raw_url(self) -> None:
        self.fixture.make_canonical_layout()
        request_path = self.fixture.root / f"Журнал/{LATE}/запрос.md"
        original = request_path.read_text(encoding="utf-8")
        request_path.write_text(
            original.replace("Запросы/legacy.md", "Запросы/still-literal.md"),
            encoding="utf-8",
        )
        self.fixture.write(
            "Источники/URL/https/example.test/raw.txt",
            "Запросы/raw.md\n",
        )
        accepted = self.fixture.run_tool("validate")
        self.assertEqual(accepted.returncode, 0, accepted.stderr)

        self.fixture.write("doc.md", f"[наследие](Запросы/{LATE}.md)\n")
        rejected = self.fixture.run_tool("validate")
        self.assertEqual(rejected.returncode, 1)
        self.assertIn("legacy", rejected.stderr.casefold())

    def test_start_requires_timestamp_updates_navigation_and_is_idempotent(self) -> None:
        self.fixture.make_canonical_layout()
        messages = ["Pierwsza wiadomość\nbez normalizacji", "Второе ``` сообщение"]
        arguments = (
            "--session-stem",
            NEW,
            "--label",
            "создать-новый-запрос",
            "--title",
            "Создать новый запрос",
            "--codex-thread-id",
            THREAD_ID,
            "--messages-json",
            "-",
        )

        first = self.fixture.run_tool("start", *arguments, stdin=json.dumps(messages, ensure_ascii=False))

        self.assertEqual(first.returncode, 0, first.stderr)
        new_request = self.fixture.root / f"Журнал/{NEW}/запрос.md"
        new_report = self.fixture.root / f"Журнал/{NEW}/отчёт.md"
        self.assertTrue(new_request.is_file())
        self.assertTrue(new_report.is_file())
        request_text = new_request.read_text(encoding="utf-8")
        for message in messages:
            self.assertIn(message, request_text)
        self.assertIn(f"../{LATE}/запрос.md", request_text)
        self.assertIn(
            f"[2026-06-24 13:57:52 MSK - Vtoroj: особый Запрос!](../{LATE}/запрос.md)",
            request_text,
        )
        previous_text = (
            self.fixture.root / f"Журнал/{LATE}/запрос.md"
        ).read_text(encoding="utf-8")
        self.assertIn(f"../{NEW}/запрос.md", previous_text)
        self.assertIn(
            f"[2026-08-03 12:00:00 MSK - Создать новый запрос](../{NEW}/запрос.md)",
            previous_text,
        )
        self.assertIn(f"{NEW}/отчёт.md", (self.fixture.root / "Журнал/README.md").read_text(encoding="utf-8"))
        before_repeat = {
            path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
            for path in self.fixture.root.rglob("*.md")
        }

        repeated = self.fixture.run_tool("start", *arguments, stdin=json.dumps(messages, ensure_ascii=False))

        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        after_repeat = {
            path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
            for path in self.fixture.root.rglob("*.md")
        }
        self.assertEqual(after_repeat, before_repeat)
        self.assertTrue(json.loads(repeated.stdout)["idempotent"])

        conflict = self.fixture.run_tool(
            "start",
            *arguments,
            stdin=json.dumps(["different"], ensure_ascii=False),
        )
        self.assertEqual(conflict.returncode, 1)
        self.assertIn("conflict", conflict.stderr.casefold())

        bad_stem = self.fixture.run_tool(
            "start",
            "--session-stem",
            "bez-vremeni",
            "--label",
            "bez-vremeni",
            "--title",
            "Bad",
            "--codex-thread-id",
            THREAD_ID,
            "--messages-json",
            "-",
            stdin="[]",
        )
        self.assertEqual(bad_stem.returncode, 1)
        self.assertIn("session stem", bad_stem.stderr.casefold())

    def test_шаблоны_задают_полный_формат_старта(себя) -> None:
        шаблон_запроса = (ШАБЛОНЫ / "запрос.md.шаблон").read_text(encoding="utf-8")
        шаблон_отчёта = (ШАБЛОНЫ / "отчёт.md.шаблон").read_text(encoding="utf-8")
        себя.assertEqual(
            [
                строка
                for строка in шаблон_запроса.splitlines()
                if строка.startswith("## ")
            ],
            [
                "## Навигация по запросам",
                "## Текст запроса",
                "## Идентификатор сеанса Codex",
                "## Использованные инструменты",
                "## Проверки",
                "## Повлиял на файлы",
            ],
        )
        for маркер in (
            "{{метка_времени}}",
            "{{заголовок}}",
            "{{предыдущий_запрос}}",
            "{{следующий_запрос}}",
            "{{текст_запроса}}",
            "{{идентификатор_сеанса}}",
        ):
            себя.assertEqual(шаблон_запроса.count(маркер), 1)
        себя.assertIn(
            "# Отчёт {{метка_времени}} - {{заголовок}}",
            шаблон_отчёта,
        )
        себя.assertIn("## Профиль времени выполнения", шаблон_отчёта)
        себя.assertRegex(
            шаблон_отчёта,
            r"\|\s*Стадия\s*\|\s*Длительность\s*\|\s*Границы и способ измерения\s*\|",
        )
        себя.assertIn("### Прямые запуски проверок", шаблон_отчёта)
        себя.assertEqual(
            шаблон_отчёта.count(
                "<!-- FUM-CHECK-RUNS:BEGIN состояние=открыт; "
                "каталог=материалы/запуски-проверок -->"
            ),
            1,
        )
        себя.assertEqual(
            шаблон_отчёта.count("<!-- FUM-CHECK-RUNS:END -->"),
            1,
        )
        себя.assertRegex(
            шаблон_отчёта,
            r"\|\s*Вызов\s*\|\s*Длительность\s*\|\s*Результат\s*\|",
        )
        себя.assertEqual(шаблон_запроса.count("<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->"), 3)
        себя.assertEqual(шаблон_отчёта.count("<!-- ШАБЛОН:НЕЗАПОЛНЕНО -->"), 5)
        for заголовок_таблицы in ("| Стадия", "| Вызов"):
            строки = шаблон_отчёта.splitlines()
            начало = next(
                номер
                for номер, строка in enumerate(строки)
                if строка.startswith(заголовок_таблицы)
            )
            таблица = []
            for строка in строки[начало:]:
                if not строка.startswith("|"):
                    break
                таблица.append(строка)
            позиции = [
                tuple(номер for номер, знак in enumerate(строка) if знак == "|")
                for строка in таблица
            ]
            себя.assertTrue(позиции)
            себя.assertTrue(all(позиция == позиции[0] for позиция in позиции))

        себя.fixture.make_canonical_layout()
        путь_предыдущего = себя.fixture.root / f"Журнал/{LATE}/запрос.md"
        текст_предыдущего = путь_предыдущего.read_text(encoding="utf-8")
        путь_предыдущего.write_text(
            текст_предыдущего.replace(
                "# Исходный запрос 2026-06-24 13:57:52 MSK - Vtoroj: особый Запрос!",
                "# Исходный запрос 2026-06-24 13:57:52 MSK - Vtoroj zapros",
                1,
            ),
            encoding="utf-8",
        )
        результат = себя.fixture.run_tool(
            "start",
            "--session-stem",
            NEW,
            "--label",
            "создать-новый-запрос",
            "--title",
            "Создать новый запрос",
            "--codex-thread-id",
            THREAD_ID,
            "--messages-json",
            "-",
            stdin='["Текст {{идентификатор_сеанса}} с Unicode и ```."]',
        )
        себя.assertEqual(результат.returncode, 0, результат.stderr)
        запрос = (себя.fixture.root / f"Журнал/{NEW}/запрос.md").read_text(encoding="utf-8")
        отчёт = (себя.fixture.root / f"Журнал/{NEW}/отчёт.md").read_text(encoding="utf-8")
        себя.assertIn("## Использованные инструменты", запрос)
        себя.assertIn("## Проверки", запрос)
        себя.assertIn("## Повлиял на файлы", запрос)
        себя.assertIn("Текст {{идентификатор_сеанса}} с Unicode и ```.", запрос)
        себя.assertTrue(
            отчёт.startswith(
                "# Отчёт 2026-08-03 12:00:00 MSK - Создать новый запрос\n"
            )
        )
        себя.assertIn("## Профиль времени выполнения", отчёт)
        спецификация = importlib.util.spec_from_file_location(
            "проверка_связности_шаблона",
            СВЯЗНОСТЬ,
        )
        себя.assertIsNotNone(спецификация)
        себя.assertIsNotNone(спецификация.loader)
        модуль_связности = importlib.util.module_from_spec(спецификация)
        sys.modules[спецификация.name] = модуль_связности
        спецификация.loader.exec_module(модуль_связности)
        путь_запроса = себя.fixture.root / f"Журнал/{NEW}/запрос.md"
        себя.assertEqual(
            модуль_связности.validate_used_tools_section(запрос, путь_запроса),
            [],
        )
        себя.assertEqual(
            модуль_связности.validate_journal_time_profile(отчёт),
            [],
        )
        себя.assertEqual(
            модуль_связности.validate_journal_direct_check_runs(отчёт),
            [],
        )
        себя.assertEqual(
            модуль_связности.validate_navigation(
                себя.fixture.root,
                путь_запроса.resolve(),
                запрос,
                markdown_paths={
                    путь.resolve() for путь in себя.fixture.root.rglob("*.md")
                },
            ),
            [],
        )
        себя.assertEqual(
            модуль_связности.validate_codex_thread_id_section(
                запрос,
                путь_запроса.resolve(),
                expected_codex_thread_id=THREAD_ID,
            ),
            [],
        )
        себя.assertEqual(
            модуль_связности.validate_journal(
                себя.fixture.root,
                путь_запроса.resolve(),
            ),
            [],
        )
        себя.assertEqual(
            модуль_связности.validate_request_filename_title(
                путь_запроса.resolve(),
            ),
            [],
        )
        себя.assertEqual(
            len(
                модуль_связности.проверить_незаполненный_маркер_шаблона(
                    запрос,
                    путь_запроса.resolve(),
                    себя.fixture.root,
                )
            ),
            3,
        )
        себя.assertEqual(
            len(
                модуль_связности.проверить_незаполненный_маркер_шаблона(
                    отчёт,
                    (себя.fixture.root / f"Журнал/{NEW}/отчёт.md").resolve(),
                    себя.fixture.root,
                )
            ),
            5,
        )

    def test_команда_старта_читает_изменённые_хранимые_шаблоны(себя) -> None:
        модуль = себя.load_module("рендер_хранимых_шаблонов")
        себя.fixture.make_canonical_layout()
        маркеры = {
            "запрос.md.шаблон": "Маркер хранимого шаблона запроса.",
            "отчёт.md.шаблон": "Маркер хранимого шаблона отчёта.",
        }
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный)
            for имя, маркер in маркеры.items():
                исходный = (ШАБЛОНЫ / имя).read_text(encoding="utf-8")
                изменённый = исходный.replace("\n\n", f"\n\n{маркер}\n\n", 1)
                (каталог / имя).write_text(изменённый, encoding="utf-8")
            with mock.patch.object(модуль, "КАТАЛОГ_ШАБЛОНОВ", каталог):
                модуль.start_session(
                    себя.fixture.root,
                    NEW,
                    "создать-новый-запрос",
                    "Создать новый запрос",
                    THREAD_ID,
                    ["Текст."],
                )
        себя.assertIn(
            маркеры["запрос.md.шаблон"],
            (себя.fixture.root / f"Журнал/{NEW}/запрос.md").read_text(encoding="utf-8"),
        )
        себя.assertIn(
            маркеры["отчёт.md.шаблон"],
            (себя.fixture.root / f"Журнал/{NEW}/отчёт.md").read_text(encoding="utf-8"),
        )

    def test_ошибка_шаблона_останавливает_команду_старта_до_записи(себя) -> None:
        модуль = себя.load_module("проверка_шаблона")
        себя.fixture.make_canonical_layout()
        состояние_до = себя.fixture.git("status", "--porcelain=v1", "-z").stdout
        исходный_запрос = (ШАБЛОНЫ / "запрос.md.шаблон").read_text(encoding="utf-8")
        исходный_отчёт = (ШАБЛОНЫ / "отчёт.md.шаблон").read_text(encoding="utf-8")
        варианты = {
            "неизвестное поле": (
                исходный_запрос.replace(
                    "{{идентификатор_сеанса}}",
                    "{{неизвестное_поле}}",
                ),
                исходный_отчёт,
            ),
            "отсутствующее поле": (
                исходный_запрос.replace(
                    "{{идентификатор_сеанса}}",
                    "идентификатор не задан",
                ),
                исходный_отчёт,
            ),
            "повторное поле": (
                исходный_запрос.replace(
                    "{{идентификатор_сеанса}}",
                    "{{идентификатор_сеанса}}\n{{идентификатор_сеанса}}",
                ),
                исходный_отчёт,
            ),
            "пропавший раздел отчёта": (
                исходный_запрос,
                исходный_отчёт.replace("## Проверки\n\n", "", 1),
            ),
            "переставленные поля навигации": (
                исходный_запрос.replace(
                    "- Предыдущий запрос: {{предыдущий_запрос}}\n"
                    "- Следующий запрос: {{следующий_запрос}}",
                    "- Предыдущий запрос: {{следующий_запрос}}\n"
                    "- Следующий запрос: {{предыдущий_запрос}}",
                ),
                исходный_отчёт,
            ),
            "повреждённые колонки профиля": (
                исходный_запрос,
                исходный_отчёт.replace("Длительность", "Время", 1),
            ),
            "пропавший конечный маркер запусков": (
                исходный_запрос,
                исходный_отчёт.replace(
                    "<!-- FUM-CHECK-RUNS:END -->",
                    "",
                    1,
                ),
            ),
            "закомментированный профиль": (
                исходный_запрос,
                исходный_отчёт.replace(
                    "## Профиль времени выполнения",
                    "<!--\n## Профиль времени выполнения",
                    1,
                ).replace("## Проверки", "-->\n\n## Проверки", 1),
            ),
        }
        for название, (повреждённый_запрос, повреждённый_отчёт) in варианты.items():
            with себя.subTest(случай=название):
                with tempfile.TemporaryDirectory() as временный:
                    каталог = Path(временный)
                    (каталог / "запрос.md.шаблон").write_text(
                        повреждённый_запрос,
                        encoding="utf-8",
                    )
                    (каталог / "отчёт.md.шаблон").write_text(
                        повреждённый_отчёт,
                        encoding="utf-8",
                    )
                    with mock.patch.object(модуль, "КАТАЛОГ_ШАБЛОНОВ", каталог):
                        with себя.assertRaises(модуль.LayoutError):
                            модуль.validate_layout(себя.fixture.root)
                        with mock.patch.object(
                            модуль,
                            "_apply_prepared_transaction",
                        ) as транзакция:
                            with себя.assertRaises(модуль.LayoutError):
                                модуль.start_session(
                                    себя.fixture.root,
                                    NEW,
                                    "создать-новый-запрос",
                                    "Создать новый запрос",
                                    THREAD_ID,
                                    ["Текст."],
                                )
                            транзакция.assert_not_called()
        себя.assertEqual(
            себя.fixture.git("status", "--porcelain=v1", "-z").stdout,
            состояние_до,
        )

    def test_каталог_шаблонов_не_может_быть_символической_ссылкой(себя) -> None:
        модуль = себя.load_module("граница_каталога_шаблонов")
        себя.fixture.make_canonical_layout()
        with tempfile.TemporaryDirectory() as временный:
            ссылка = Path(временный) / "шаблоны"
            ссылка.symlink_to(ШАБЛОНЫ, target_is_directory=True)
            with mock.patch.object(модуль, "КАТАЛОГ_ШАБЛОНОВ", ссылка):
                with себя.assertRaises(модуль.LayoutError):
                    модуль.validate_layout(себя.fixture.root)
                with mock.patch.object(
                    модуль,
                    "_apply_prepared_transaction",
                ) as транзакция:
                    with себя.assertRaises(модуль.LayoutError):
                        модуль.start_session(
                            себя.fixture.root,
                            NEW,
                            "создать-новый-запрос",
                            "Создать новый запрос",
                            THREAD_ID,
                            ["Текст."],
                        )
                    транзакция.assert_not_called()

    def test_команда_старта_отклоняет_неканонические_входы(себя) -> None:
        модуль = себя.load_module("канонические_входы_старта")
        себя.fixture.make_canonical_layout()
        варианты = (
            (" Чужой заголовок", THREAD_ID, ["Текст."]),
            ("Создать новый запрос\n", THREAD_ID, ["Текст."]),
            ("Чужой заголовок", THREAD_ID, ["Текст."]),
            ("Создать новый запрос", "НЕ-UUID", ["Текст."]),
            ("Создать новый запрос", THREAD_ID, []),
            ("Создать новый запрос", THREAD_ID, [""]),
        )
        with mock.patch.object(
            модуль,
            "_apply_prepared_transaction",
        ) as транзакция:
            with себя.assertRaises(модуль.LayoutError):
                модуль.start_session(
                    себя.fixture.root,
                    "2026-08-03_12-00-00_MSK_новый-запрос",
                    "новый-запрос",
                    "Новый запрос",
                    THREAD_ID,
                    ["Текст."],
                )
            транзакция.assert_not_called()
            for заголовок, идентификатор, сообщения in варианты:
                with себя.subTest(
                    заголовок=заголовок,
                    идентификатор=идентификатор,
                    сообщения=сообщения,
                ):
                    транзакция.reset_mock()
                    with себя.assertRaises(модуль.LayoutError):
                        модуль.start_session(
                            себя.fixture.root,
                            NEW,
                            "создать-новый-запрос",
                            заголовок,
                            идентификатор,
                            сообщения,
                        )
                    транзакция.assert_not_called()

    def test_reindex_uses_only_baseline_index_section_and_rolls_back(self) -> None:
        self.fixture.make_canonical_layout()
        current = (
            "# Журнал\n\nТекущее введение.\n\n"
            "## Сессии\n\n"
            f"- [Повреждённая строка]({LATE}/запрос.md)\n\n"
            "## Источники требований\n\n"
            f"- [Текущий дубль]({LATE}/запрос.md)\n"
        )
        index = self.fixture.root / "Журнал/README.md"
        index.write_text(current, encoding="utf-8")
        baseline = (
            "# Старый журнал\n\n"
            "## Отчёты\n\n"
            f"- [Курированная запись]({LATE}.md) — точное описание.\n\n"
            "## Источники требований\n\n"
            f"- [Не индекс]({LATE}.md) — эта строка не должна победить.\n"
        )

        first = self.fixture.run_tool(
            "reindex", "--baseline-markdown", "-", stdin=baseline
        )

        self.assertEqual(first.returncode, 0, first.stderr)
        updated = index.read_text(encoding="utf-8")
        self.assertIn(
            f"- [Курированная запись]({LATE}/отчёт.md) — точное описание.",
            updated,
        )
        self.assertNotIn("Не индекс", updated)
        self.assertIn(
            f"- [Текущий дубль]({LATE}/запрос.md)", updated
        )
        self.assertIn("Текущее введение.", updated)

        repeated = self.fixture.run_tool(
            "reindex", "--baseline-markdown", "-", stdin=baseline
        )
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertTrue(json.loads(repeated.stdout)["idempotent"])
        self.assertEqual(index.read_text(encoding="utf-8"), updated)

        index.write_text(current, encoding="utf-8")
        before = index.read_bytes()
        before_index = (self.fixture.root / ".git/index").read_bytes()
        module = self.load_module("request_folder_layout_reindex_rollback")
        stderr = io.StringIO()
        with mock.patch.object(module, "_install_prepared_file", side_effect=OSError("injected")):
            with mock.patch("sys.stdin", io.StringIO(baseline)):
                with contextlib.redirect_stderr(stderr):
                    result = module.main(
                        [
                            "reindex",
                            "--repo-root",
                            str(self.fixture.root),
                            "--baseline-markdown",
                            "-",
                        ]
                    )
        self.assertEqual(result, 1)
        self.assertIn("rolled back", stderr.getvalue())
        self.assertEqual(index.read_bytes(), before)
        self.assertEqual((self.fixture.root / ".git/index").read_bytes(), before_index)

    def test_repair_from_exact_base_rewrites_only_proven_links_and_navigation(self) -> None:
        protected_before = self.fixture.make_legacy_layout()
        base_revision = self.fixture.git("rev-parse", "HEAD").stdout.strip()
        applied = self.fixture.run_tool("apply")
        self.assertEqual(applied.returncode, 0, applied.stderr)

        early_request = self.fixture.root / f"Журнал/{EARLY}/запрос.md"
        early_text = early_request.read_text(encoding="utf-8").replace(
            "[`.gitignore`](../../.gitignore)",
            "[`.gitignore`](../.gitignore)",
        ).replace(
            "[`README.md`](../../README.md)",
            "[`README.md`](../README.md)",
        ).replace(
            "[`Журнал/README.md`](../README.md)",
            "[`Журнал/README.md`](../Журнал/README.md)",
        )
        early_request.write_text(early_text, encoding="utf-8")
        source_metadata = (
            self.fixture.root
            / f"Журнал/{EARLY}/материалы/источники/appshot/извлечение.md"
        )
        source_metadata.write_text(
            source_metadata.read_text(encoding="utf-8")
            .replace(f"../../../запрос.md", f"../../Запросы/{EARLY}.md")
            .replace(
                "../../../../../Документация/target.md",
                "../../Документация/target.md",
            ),
            encoding="utf-8",
        )
        source_index = (
            self.fixture.root
            / "Источники/URL/https/example.test/source-index.md"
        )
        source_index.write_text(
            source_index.read_text(encoding="utf-8").replace(
                f"../../../../Журнал/{LATE}/запрос.md",
                f"../../../../Запросы/{LATE}.md",
            ),
            encoding="utf-8",
        )
        raw_payload = (
            self.fixture.root
            / "Источники/URL/https/example.test/response.body.md"
        )
        raw_payload_before = raw_payload.read_bytes()
        for stem in (EARLY, LATE):
            request = self.fixture.root / f"Журнал/{stem}/запрос.md"
            request.write_text(
                request.read_text(encoding="utf-8")
                .replace("[2026-06-23 18:43:31 MSK]", "[Предыдущий]")
                .replace(
                    "[2026-06-24 13:57:52 MSK - Vtoroj: особый Запрос!]",
                    "[Следующий]",
                ),
                encoding="utf-8",
            )

        rejected_symbolic = self.fixture.run_tool(
            "repair-plan", "--base-revision", "HEAD"
        )
        self.assertEqual(rejected_symbolic.returncode, 1)
        self.assertIn("exact full", rejected_symbolic.stderr)

        index_before = (self.fixture.root / ".git/index").read_bytes()
        before_plan = {
            path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
            for path in self.fixture.root.rglob("*")
            if path.is_file() and ".git" not in path.parts
        }
        planned = self.fixture.run_tool(
            "repair-plan", "--base-revision", base_revision
        )
        self.assertEqual(planned.returncode, 0, planned.stderr)
        self.assertEqual(
            {
                path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
                for path in self.fixture.root.rglob("*")
                if path.is_file() and ".git" not in path.parts
            },
            before_plan,
        )
        plan_payload = json.loads(planned.stdout)
        self.assertEqual(plan_payload["base_revision"], base_revision)
        self.assertGreaterEqual(plan_payload["semantic_links"], 4)
        self.assertGreaterEqual(plan_payload["navigation_files"], 2)

        first = self.fixture.run_tool("repair", "--base-revision", base_revision)
        self.assertEqual(first.returncode, 0, first.stderr)
        first_payload = json.loads(first.stdout)
        self.assertFalse(first_payload["idempotent"])
        self.assertIn("[`.gitignore`](../../.gitignore)", early_request.read_text(encoding="utf-8"))
        self.assertIn("[`README.md`](../../README.md)", early_request.read_text(encoding="utf-8"))
        self.assertIn(
            "[`Журнал/README.md`](../README.md)",
            early_request.read_text(encoding="utf-8"),
        )
        self.assertEqual(
            source_metadata.read_text(encoding="utf-8"),
            f"[Владелец](../../../запрос.md)\n"
            "[Цель](../../../../../Документация/target.md)\n"
            "Сырые байты Запросы/old.md\n",
        )
        self.assertEqual(
            source_index.read_text(encoding="utf-8"),
            f"[Исходный запрос](../../../../Журнал/{LATE}/запрос.md)\n",
        )
        self.assertEqual(raw_payload.read_bytes(), raw_payload_before)
        self.assertEqual((self.fixture.root / ".git/index").read_bytes(), index_before)
        repaired_early = early_request.read_text(encoding="utf-8")
        marker = "## Текст запроса\n"
        protected_after = repaired_early[
            repaired_early.index(marker) + len(marker) :
        ].split("\n## Идентификатор", 1)[0].encode("utf-8")
        self.assertEqual(protected_after, protected_before)
        self.assertIn(
            f"[2026-06-24 13:57:52 MSK - Vtoroj: особый Запрос!](../{LATE}/запрос.md)",
            repaired_early,
        )

        after_first = {
            path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
            for path in self.fixture.root.rglob("*")
            if path.is_file() and ".git" not in path.parts
        }
        repeated = self.fixture.run_tool("repair", "--base-revision", base_revision)
        self.assertEqual(repeated.returncode, 0, repeated.stderr)
        self.assertTrue(json.loads(repeated.stdout)["idempotent"])
        self.assertEqual(
            {
                path.relative_to(self.fixture.root).as_posix(): path.read_bytes()
                for path in self.fixture.root.rglob("*")
                if path.is_file() and ".git" not in path.parts
            },
            after_first,
        )

        early_request.write_text(
            early_request.read_text(encoding="utf-8").replace(
                "[`Журнал/README.md`](../README.md)",
                "[`Журнал/README.md`](../../README.md)",
            ),
            encoding="utf-8",
        )
        recovered = self.fixture.run_tool(
            "repair", "--base-revision", base_revision
        )
        self.assertEqual(recovered.returncode, 0, recovered.stderr)
        self.assertFalse(json.loads(recovered.stdout)["idempotent"])
        self.assertIn(
            "[`Журнал/README.md`](../README.md)",
            early_request.read_text(encoding="utf-8"),
        )
        final_repeat = self.fixture.run_tool(
            "repair", "--base-revision", base_revision
        )
        self.assertEqual(final_repeat.returncode, 0, final_repeat.stderr)
        self.assertTrue(json.loads(final_repeat.stdout)["idempotent"])

    def test_exact_time_prefix_is_enforced_in_plan_apply_validate_and_start(self) -> None:
        legacy = RepositoryFixture()
        try:
            legacy.write("Запросы/no-time-prefix.md", "# Request\n")
            legacy.write("Журнал/README.md", "# Journal\n")
            legacy.commit()
            for mode in ("plan", "apply"):
                with self.subTest(mode=mode, case="legacy-without-prefix"):
                    result = legacy.run_tool(mode)
                    self.assertEqual(result.returncode, 1)
                    self.assertIn("session stem", result.stderr.casefold())
                    self.assertTrue((legacy.root / "Запросы/no-time-prefix.md").is_file())
        finally:
            legacy.close()

        invalid_folder = RepositoryFixture()
        try:
            bad = "2026-99-40_25-61-61_MSK_bad-time"
            invalid_folder.write("Журнал/README.md", "# Journal\n")
            invalid_folder.write(f"Журнал/{bad}/запрос.md", "# Request\n")
            invalid_folder.write(f"Журнал/{bad}/отчёт.md", "# Report\n")
            invalid_folder.commit()
            result = invalid_folder.run_tool("validate")
            self.assertEqual(result.returncode, 1)
            self.assertIn("session stem", result.stderr.casefold())
        finally:
            invalid_folder.close()

        wrong_prefix = RepositoryFixture()
        try:
            wrong_prefix.make_canonical_layout()
            request = wrong_prefix.root / f"Журнал/{LATE}/запрос.md"
            request.write_text(
                request.read_text(encoding="utf-8").replace(
                    "# Исходный запрос 2026-06-24 13:57:52 MSK",
                    "# Исходный запрос 2026-06-24 13:57:53 MSK",
                ),
                encoding="utf-8",
            )
            result = wrong_prefix.run_tool("validate")
            self.assertEqual(result.returncode, 1)
            self.assertIn("prefix", result.stderr.casefold())
        finally:
            wrong_prefix.close()

        self.fixture.make_canonical_layout()
        impossible = self.fixture.run_tool(
            "start",
            "--session-stem",
            "2026-02-30_12-00-00_MSK_impossible",
            "--label",
            "impossible",
            "--title",
            "Impossible",
            "--codex-thread-id",
            THREAD_ID,
            "--messages-json",
            "-",
            stdin="[]",
        )
        self.assertEqual(impossible.returncode, 1)
        self.assertIn("session stem", impossible.stderr.casefold())

    def test_public_helpers_and_skill_contract(self) -> None:
        module = self.load_module("request_folder_layout_helpers")
        self.assertTrue(module.is_valid_session_stem(LATE))
        self.assertFalse(module.is_valid_session_stem("no-time-prefix"))
        self.assertEqual(
            module.session_stem_for_request_path(f"Журнал/{LATE}/запрос.md"),
            LATE,
        )
        self.assertEqual(
            module.canonical_report_path(LATE).as_posix(),
            f"Журнал/{LATE}/отчёт.md",
        )
        self.assertEqual(
            module._portable_key(Path("Session/É")),
            module._portable_key(Path("session/E\u0301")),
        )
        skill = (TOOL_ROOT / "SKILL.md").read_text(encoding="utf-8")
        for mode in ("plan", "apply", "validate", "start"):
            self.assertIn(f"`{mode}`", skill)


if __name__ == "__main__":
    unittest.main()
