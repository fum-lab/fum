import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "check-readme-index.py"
)

spec = importlib.util.spec_from_file_location(
    "check_readme_index",
    SCRIPT_PATH,
)
check_readme_index = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = check_readme_index
spec.loader.exec_module(check_readme_index)


class CheckReadmeIndexTests(unittest.TestCase):
    def write_documentation_fixture(self, root: Path) -> tuple[str, ...]:
        paths = (
            "Документация/00-обзор.md",
            "Документация/01-модель.md",
            "Документация/28-реестр.md",
            "Документация/28-реестр/README.md",
        )
        for relative in paths:
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f"# {target.stem}\n", encoding="utf-8")

        ignored = (
            "Документация/черновик.md",
            "Документация/28-реестр/FUM-MAP-01.md",
            "Документация/вложенное/README.md",
        )
        for relative in ignored:
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f"# {target.stem}\n", encoding="utf-8")
        return paths

    def write_root_readme(
        self,
        root: Path,
        *,
        число_разделов_сценария: int = 1,
        ссылка_на_индекс: bool = True,
        тематический_раздел: bool = False,
        дополнение: str = "",
    ) -> None:
        lines = ["# FUM", ""]
        for _ in range(число_разделов_сценария):
            lines.extend(
                ["## Как использовать FUM сейчас", "", "Отправьте запрос.", ""]
            )
        if тематический_раздел:
            lines.extend(["## Документация по темам", "", "Список.", ""])
        if ссылка_на_индекс:
            lines.extend(
                ["## Куда идти дальше", "", "[Документация](Документация/README.md)", ""]
            )
        if дополнение:
            lines.append(дополнение)
        (root / "README.md").write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

    def записать_индекс_документации(
        сам,
        корень: Path,
        ссылки: tuple[str, ...],
        *,
        число_тематических_разделов: int = 1,
        ссылки_до_раздела: tuple[str, ...] = (),
        дополнительные_строки_раздела: tuple[str, ...] = (),
        заголовок_границы: str = "## Следующий раздел",
        строки_после_раздела: tuple[str, ...] = (),
    ) -> None:
        строки = ["# Документация FUM", ""]
        строки.extend(
            f"- [Внешняя ссылка]({цель})" for цель in ссылки_до_раздела
        )
        if ссылки_до_раздела:
            строки.append("")
        for _ in range(число_тематических_разделов):
            строки.extend(["## Документация по темам", ""])
            строки.extend(
                f"- [Документ {номер}]({цель})"
                for номер, цель in enumerate(ссылки, start=1)
            )
            строки.extend(дополнительные_строки_раздела)
            строки.append("")
        строки.extend([заголовок_границы, "", "Текст.", ""])
        строки.extend(строки_после_раздела)
        цель = корень / "Документация/README.md"
        цель.parent.mkdir(parents=True, exist_ok=True)
        цель.write_text("\n".join(строки), encoding="utf-8")

    def подготовить_полный_контракт(сам, корень: Path) -> tuple[str, ...]:
        пути = сам.write_documentation_fixture(корень)
        сам.write_root_readme(корень)
        относительные = tuple(
            Path(путь).relative_to("Документация").as_posix()
            for путь in пути
        )
        сам.записать_индекс_документации(корень, относительные)
        return пути

    def test_accepts_complete_numbered_documentation_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.подготовить_полный_контракт(root)

            result = check_readme_index.validate_repository(root)

            self.assertEqual(result.errors, ())
            self.assertEqual(result.required_count, len(paths))
            self.assertEqual(result.indexed_count, len(paths))

    def test_accepts_url_decoded_and_lexically_normalized_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            normalized_links = (
                "%30%30-обзор.md",
                "./01-модель.md",
                Path(paths[2]).relative_to("Документация").as_posix(),
                Path(paths[3]).relative_to("Документация").as_posix(),
            )
            self.записать_индекс_документации(
                root,
                normalized_links,
            )

            result = check_readme_index.validate_repository(root)

            self.assertEqual(result.errors, ())

    def test_reports_new_numbered_document_missing_from_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.подготовить_полный_контракт(root)
            new_document = root / "Документация/02-новый-документ.md"
            new_document.write_text("# Новый документ\n", encoding="utf-8")

            result = check_readme_index.validate_repository(root)

            self.assertIn(
                "Документация/02-новый-документ.md",
                result.errors[0],
            )
            self.assertEqual(result.required_count, len(paths) + 1)

    def test_reports_new_numbered_folder_entrypoint_missing_from_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.подготовить_полный_контракт(root)
            new_entrypoint = root / "Документация/31-истории/README.md"
            new_entrypoint.parent.mkdir(parents=True)
            new_entrypoint.write_text("# Истории\n", encoding="utf-8")

            result = check_readme_index.validate_repository(root)

            self.assertIn(
                "Документация/31-истории/README.md",
                result.errors[0],
            )
            self.assertEqual(result.required_count, len(paths) + 1)

    def test_does_not_count_link_outside_thematic_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            относительные = tuple(
                Path(путь).relative_to("Документация").as_posix()
                for путь in paths
            )
            missing = относительные[-1]
            self.записать_индекс_документации(
                root,
                относительные[:-1],
                ссылки_до_раздела=(missing,),
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(paths[-1], result.errors[0])

    def test_does_not_count_link_in_multiline_code_span(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            missing = paths[-1]
            visible_links = tuple(
                Path(path).relative_to("Документация").as_posix()
                for path in paths[:-1]
            )
            self.записать_индекс_документации(
                root,
                visible_links,
                дополнительные_строки_раздела=(
                    "`скрытый пример",
                    "[Не индекс]("
                    f"{Path(missing).relative_to('Документация').as_posix()})",
                    "продолжение примера`",
                ),
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_indented_level_two_heading_ends_thematic_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            missing = paths[-1]
            visible_links = tuple(
                Path(path).relative_to("Документация").as_posix()
                for path in paths[:-1]
            )
            self.записать_индекс_документации(
                root,
                visible_links,
                заголовок_границы="  ## Следующий раздел",
                строки_после_раздела=(
                    "[Не индекс]("
                    f"{Path(missing).relative_to('Документация').as_posix()})",
                ),
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_level_one_heading_ends_thematic_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            missing = paths[-1]
            visible_links = tuple(
                Path(path).relative_to("Документация").as_posix()
                for path in paths[:-1]
            )
            self.записать_индекс_документации(
                root,
                visible_links,
                заголовок_границы="# Новый документ верхнего уровня",
                строки_после_раздела=(
                    "[Не индекс]("
                    f"{Path(missing).relative_to('Документация').as_posix()})",
                ),
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_does_not_count_links_in_fence_or_html_comment(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            hidden_in_fence, hidden_in_comment = paths[-2:]
            visible_links = tuple(
                Path(путь).relative_to("Документация").as_posix()
                for путь in paths[:-2]
            )
            self.записать_индекс_документации(
                root,
                visible_links,
                дополнительные_строки_раздела=(
                    "```markdown",
                    "[Не индекс]("
                    f"{Path(hidden_in_fence).relative_to('Документация').as_posix()})",
                    "```",
                    "<!--",
                    "[Не индекс]("
                    f"{Path(hidden_in_comment).relative_to('Документация').as_posix()})",
                    "-->",
                ),
            )

            result = check_readme_index.validate_repository(root)

            self.assertEqual(
                result.errors,
                tuple(
                    f"missing documentation-index link: {path}"
                    for path in sorted((hidden_in_fence, hidden_in_comment))
                ),
            )

    def test_does_not_count_link_in_indented_code_block(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            missing = paths[-1]
            visible_links = tuple(
                Path(path).relative_to("Документация").as_posix()
                for path in paths[:-1]
            )
            self.записать_индекс_документации(
                root,
                visible_links,
                дополнительные_строки_раздела=(
                    "    [Не индекс]("
                    f"{Path(missing).relative_to('Документация').as_posix()})",
                ),
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_does_not_count_case_mismatched_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            mismatched = tuple(
                "28-Реестр/README.md"
                if path.endswith("28-реестр/README.md")
                else Path(path).relative_to("Документация").as_posix()
                for path in paths
            )
            self.записать_индекс_документации(root, mismatched)

            result = check_readme_index.validate_repository(root)

            self.assertIn(paths[-1], result.errors[0])

    def test_отклоняет_отсутствующий_индекс_документации(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.write_documentation_fixture(корень)
            сам.write_root_readme(корень)

            результат = check_readme_index.validate_repository(корень)

            сам.assertIn("Документация/README.md is missing", результат.errors)

    def test_отклоняет_корневую_инструкцию_без_текущего_сценария(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(
                корень,
                число_разделов_сценария=0,
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertIn(
                "README.md is missing section: Как использовать FUM сейчас",
                результат.errors,
            )

    def test_отклоняет_повтор_раздела_текущего_сценария(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(
                корень,
                число_разделов_сценария=2,
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertIn(
                "README.md has duplicate section: Как использовать FUM сейчас",
                результат.errors,
            )

    def test_отклоняет_тематический_индекс_в_корневой_инструкции(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(
                корень,
                тематический_раздел=True,
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertIn(
                "README.md must not contain section: Документация по темам",
                результат.errors,
            )

    def test_отклоняет_скрытую_вместо_видимой_ссылку_на_индекс(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(
                корень,
                ссылка_на_индекс=False,
                дополнение="<!-- [Документация](Документация/README.md) -->",
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertIn(
                "README.md is missing visible link: Документация/README.md",
                результат.errors,
            )

    def test_отклоняет_ссылку_на_индекс_с_неверным_регистром(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(
                корень,
                ссылка_на_индекс=False,
                дополнение="[Документация](документация/README.md)",
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertIn(
                "README.md is missing visible link: Документация/README.md",
                результат.errors,
            )

    def test_принимает_корневую_инструкцию_ровно_из_12000_символов(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            путь_инструкции = корень / "README.md"
            текст = путь_инструкции.read_text(encoding="utf-8")
            путь_инструкции.write_text(
                текст + "я" * (12000 - len(текст)),
                encoding="utf-8",
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertEqual(len(путь_инструкции.read_text(encoding="utf-8")), 12000)
            сам.assertEqual(результат.errors, ())

    def test_отклоняет_раздутую_корневую_инструкцию(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(
                корень,
                дополнение="я" * 12001,
            )

            результат = check_readme_index.validate_repository(корень)

            сам.assertTrue(
                any("README.md exceeds 12000 characters" in ошибка for ошибка in результат.errors)
            )

    def test_fails_closed_when_thematic_section_is_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.подготовить_полный_контракт(root)
            self.записать_индекс_документации(
                root,
                (),
                число_тематических_разделов=0,
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(
                "Документация/README.md is missing section: Документация по темам",
                result.errors,
            )

    def test_fails_closed_when_thematic_section_is_duplicated(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root)
            относительные = tuple(
                Path(путь).relative_to("Документация").as_posix()
                for путь in paths
            )
            self.записать_индекс_документации(
                root,
                относительные,
                число_тематических_разделов=2,
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(
                "Документация/README.md has duplicate section: Документация по темам",
                result.errors,
            )

    def test_ignores_nonnumbered_and_nested_documents(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.подготовить_полный_контракт(root)

            result = check_readme_index.validate_repository(root)

            self.assertEqual(result.errors, ())
            self.assertEqual(result.required_count, len(paths))

    def test_cli_reports_sorted_missing_targets_and_exit_one(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_documentation_fixture(root)
            self.write_root_readme(root)
            self.записать_индекс_документации(root, ())

            result = subprocess.run(
                [sys.executable, str(SCRIPT_PATH), "--repo-root", str(root)],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            expected = sorted(
                [
                    "Документация/00-обзор.md",
                    "Документация/01-модель.md",
                    "Документация/28-реестр.md",
                    "Документация/28-реестр/README.md",
                ]
            )
            positions = [result.stderr.index(path) for path in expected]
            self.assertEqual(positions, sorted(positions))
            self.assertIn(f"missing={len(expected)}", result.stderr)

    def test_итог_команды_отделяет_ошибки_инструкции_от_пропусков_индекса(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            сам.подготовить_полный_контракт(корень)
            сам.write_root_readme(корень, дополнение="я" * 12001)

            результат_команды = subprocess.run(
                [sys.executable, str(SCRIPT_PATH), "--repo-root", str(корень)],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            сам.assertEqual(результат_команды.returncode, 1)
            сам.assertIn("missing=0", результат_команды.stderr)

    def test_current_repository_readme_index_is_complete(self):
        repo_root = Path(__file__).resolve().parents[3]

        result = check_readme_index.validate_repository(repo_root)

        self.assertEqual(result.errors, ())


if __name__ == "__main__":
    unittest.main()
