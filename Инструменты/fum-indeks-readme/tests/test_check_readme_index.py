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
            "Документация/README.md",
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
        links: tuple[str, ...],
        *,
        include_section: bool = True,
        links_before_section: tuple[str, ...] = (),
    ) -> None:
        lines = ["# FUM", ""]
        lines.extend(
            f"- [Внешняя ссылка на индекс]({target})"
            for target in links_before_section
        )
        if links_before_section:
            lines.append("")
        if include_section:
            lines.extend(["## Документация по темам", ""])
            lines.extend(
                f"- [Документ {index}]({target})"
                for index, target in enumerate(links, start=1)
            )
            lines.extend(["", "## Следующий раздел", "", "Текст."])
        else:
            lines.extend(["## Другой раздел", "", "Текст."])
        lines.append("")
        (root / "README.md").write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

    def test_accepts_complete_numbered_documentation_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root, paths)

            result = check_readme_index.validate_repository(root)

            self.assertEqual(result.errors, ())
            self.assertEqual(result.required_count, 4)
            self.assertEqual(result.indexed_count, 4)

    def test_accepts_url_decoded_and_lexically_normalized_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            normalized_links = (
                "Документация/%30%30-обзор.md",
                "./Документация/01-модель.md",
                paths[2],
                paths[3],
            )
            self.write_root_readme(root, normalized_links)

            result = check_readme_index.validate_repository(root)

            self.assertEqual(result.errors, ())

    def test_reports_new_numbered_document_missing_from_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root, paths)
            new_document = root / "Документация/02-новый-документ.md"
            new_document.write_text("# Новый документ\n", encoding="utf-8")

            result = check_readme_index.validate_repository(root)

            self.assertEqual(
                result.errors,
                (
                    "missing README thematic-index link: "
                    "Документация/02-новый-документ.md",
                ),
            )

    def test_reports_new_numbered_folder_entrypoint_missing_from_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root, paths)
            new_entrypoint = root / "Документация/31-истории/README.md"
            new_entrypoint.parent.mkdir(parents=True)
            new_entrypoint.write_text("# Истории\n", encoding="utf-8")

            result = check_readme_index.validate_repository(root)

            self.assertEqual(
                result.errors,
                (
                    "missing README thematic-index link: "
                    "Документация/31-истории/README.md",
                ),
            )

    def test_does_not_count_link_outside_thematic_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            missing = paths[-1]
            self.write_root_readme(
                root,
                paths[:-1],
                links_before_section=(missing,),
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_does_not_count_link_in_multiline_code_span(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            missing = paths[-1]
            visible_links = "\n".join(
                f"- [Документ]({path})" for path in paths[:-1]
            )
            (root / "README.md").write_text(
                "# FUM\n\n"
                "## Документация по темам\n\n"
                f"{visible_links}\n\n"
                "`скрытый пример\n"
                f"[Не индекс]({missing})\n"
                "продолжение примера`\n\n"
                "## Следующий раздел\n",
                encoding="utf-8",
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_indented_level_two_heading_ends_thematic_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            missing = paths[-1]
            visible_links = "\n".join(
                f"- [Документ]({path})" for path in paths[:-1]
            )
            (root / "README.md").write_text(
                "# FUM\n\n"
                "## Документация по темам\n\n"
                f"{visible_links}\n\n"
                "  ## Следующий раздел\n\n"
                f"- [Не индекс]({missing})\n",
                encoding="utf-8",
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_level_one_heading_ends_thematic_section(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            missing = paths[-1]
            visible_links = "\n".join(
                f"- [Документ]({path})" for path in paths[:-1]
            )
            (root / "README.md").write_text(
                "# FUM\n\n"
                "## Документация по темам\n\n"
                f"{visible_links}\n\n"
                "# Новый документ верхнего уровня\n\n"
                f"- [Не индекс]({missing})\n",
                encoding="utf-8",
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_does_not_count_links_in_fence_or_html_comment(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            hidden_in_fence, hidden_in_comment = paths[-2:]
            visible_links = "\n".join(
                f"- [Документ]({path})" for path in paths[:-2]
            )
            (root / "README.md").write_text(
                "# FUM\n\n"
                "## Документация по темам\n\n"
                f"{visible_links}\n\n"
                "```markdown\n"
                f"[Не индекс]({hidden_in_fence})\n"
                "```\n\n"
                "<!--\n"
                f"[Не индекс]({hidden_in_comment})\n"
                "-->\n\n"
                "## Следующий раздел\n",
                encoding="utf-8",
            )

            result = check_readme_index.validate_repository(root)

            self.assertEqual(
                result.errors,
                tuple(
                    f"missing README thematic-index link: {path}"
                    for path in sorted((hidden_in_fence, hidden_in_comment))
                ),
            )

    def test_does_not_count_link_in_indented_code_block(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            missing = paths[-1]
            visible_links = "\n".join(
                f"- [Документ]({path})" for path in paths[:-1]
            )
            (root / "README.md").write_text(
                "# FUM\n\n"
                "## Документация по темам\n\n"
                f"{visible_links}\n\n"
                f"    [Не индекс]({missing})\n\n"
                "## Следующий раздел\n",
                encoding="utf-8",
            )

            result = check_readme_index.validate_repository(root)

            self.assertIn(missing, result.errors[0])

    def test_does_not_count_case_mismatched_target(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            mismatched = tuple(
                "Документация/28-Реестр/README.md"
                if path == "Документация/28-реестр/README.md"
                else path
                for path in paths
            )
            self.write_root_readme(root, mismatched)

            result = check_readme_index.validate_repository(root)

            self.assertIn(
                "Документация/28-реестр/README.md",
                result.errors[0],
            )

    def test_ignores_nonnumbered_and_nested_documents(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root, paths)

            result = check_readme_index.validate_repository(root)

            self.assertEqual(result.errors, ())
            self.assertEqual(result.required_count, len(paths))

    def test_fails_closed_when_thematic_section_is_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_documentation_fixture(root)
            self.write_root_readme(root, (), include_section=False)

            result = check_readme_index.validate_repository(root)

            self.assertEqual(
                result.errors,
                ("README.md is missing section: Документация по темам",),
            )

    def test_fails_closed_when_thematic_section_is_duplicated(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = self.write_documentation_fixture(root)
            self.write_root_readme(root, paths)
            readme = root / "README.md"
            readme.write_text(
                readme.read_text(encoding="utf-8")
                + "\n## Документация по темам\n",
                encoding="utf-8",
            )

            result = check_readme_index.validate_repository(root)

            self.assertEqual(
                result.errors,
                ("README.md has duplicate section: Документация по темам",),
            )

    def test_cli_reports_sorted_missing_targets_and_exit_one(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_documentation_fixture(root)
            self.write_root_readme(root, ())

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

    def test_current_repository_readme_index_is_complete(self):
        repo_root = Path(__file__).resolve().parents[3]

        result = check_readme_index.validate_repository(repo_root)

        self.assertEqual(result.errors, ())


if __name__ == "__main__":
    unittest.main()
