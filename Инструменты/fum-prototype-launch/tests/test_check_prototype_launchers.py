import importlib.util
import stat
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "check-prototype-launchers.py"
)

spec = importlib.util.spec_from_file_location(
    "check_prototype_launchers",
    SCRIPT_PATH,
)
check_prototype_launchers = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = check_prototype_launchers
spec.loader.exec_module(check_prototype_launchers)


class CheckPrototypeLaunchersTests(unittest.TestCase):
    def make_prototype(
        self,
        root: Path,
        name: str,
        launcher: str | None = None,
        executable: bool = True,
    ) -> Path:
        prototype = root / "Прототипы" / name
        prototype.mkdir(parents=True)
        (prototype / "README.md").write_text(
            f"# {name}\n",
            encoding="utf-8",
        )
        if launcher is not None:
            launcher_path = prototype / "запустить.sh"
            launcher_path.write_text(launcher, encoding="utf-8")
            if executable:
                launcher_path.chmod(
                    launcher_path.stat().st_mode
                    | stat.S_IXUSR
                    | stat.S_IXGRP
                    | stat.S_IXOTH
                )
        return prototype

    def test_accepts_executable_posix_launcher(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_prototype(
                root,
                "пример",
                "#!/bin/sh\nset -eu\nprintf '%s\\n' ok\n",
            )

            errors = check_prototype_launchers.validate_prototype_launchers(root)

            self.assertEqual(errors, [])

    def test_reports_missing_prototypes_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            errors = check_prototype_launchers.validate_prototype_launchers(root)

            self.assertEqual(errors, ["Прототипы: каталог отсутствует"])

    def test_reports_missing_launcher(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_prototype(root, "без-запуска")

            errors = check_prototype_launchers.validate_prototype_launchers(root)

            self.assertEqual(
                errors,
                ["Прототипы/без-запуска/запустить.sh: файл отсутствует"],
            )

    def test_reports_non_executable_launcher(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_prototype(
                root,
                "без-права",
                "#!/bin/sh\nexit 0\n",
                executable=False,
            )

            errors = check_prototype_launchers.validate_prototype_launchers(root)

            self.assertIn(
                "Прототипы/без-права/запустить.sh: "
                "не установлен исполняемый бит",
                errors,
            )

    def test_reports_wrong_shebang_and_shell_syntax(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_prototype(
                root,
                "сломанный",
                "#!/bin/bash\nif true; then\n",
            )

            errors = check_prototype_launchers.validate_prototype_launchers(root)

            self.assertIn(
                "Прототипы/сломанный/запустить.sh: "
                "первая строка должна быть #!/bin/sh",
                errors,
            )
            self.assertTrue(
                any("ошибка синтаксиса /bin/sh" in error for error in errors)
            )

    def test_ignores_non_prototype_directories(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ignored = root / "Прототипы" / "служебное"
            ignored.mkdir(parents=True)
            (ignored / "заметка.txt").write_text("не прототип\n", encoding="utf-8")

            errors = check_prototype_launchers.validate_prototype_launchers(root)

            self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
