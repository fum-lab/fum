"""Portable orchestration for archiving stable HTML URLs into FUM sources."""

from __future__ import annotations

import ctypes
import datetime as dt
import errno
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
from typing import Any, Callable, Protocol
from urllib.parse import unquote, urlsplit


REQUEST_LAYOUT_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-struktura-papok-zaprosov"
    / "scripts"
)
if str(REQUEST_LAYOUT_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(REQUEST_LAYOUT_SCRIPTS))

from request_folder_layout import session_stem_for_request_path  # noqa: E402


COOKIE_REDACTION = "set-cookie: [REDACTED: response cookie]\n"
SNAPSHOT_MANIFEST_NAME = "snapshot-manifest.json"
SNAPSHOT_MANIFEST_SCHEMA = "fum.request-materials.snapshot-manifest.v1"
TEST_FIXTURE_ENV = "FUM_SOURCE_ARCHIVE_TEST_FIXTURE_DIR"
TEST_FAILPOINT_ENV = "FUM_SOURCE_ARCHIVE_TEST_FAILPOINT"


class Transport(Protocol):
    def __call__(
        self,
        url: str,
        body_path: Path,
        headers_path: Path,
    ) -> dict[str, str]: ...


BeforeInstall = Callable[[Path], None]


@dataclass(frozen=True)
class ArchiveResult:
    output_dir: Path
    linked_request: bool
    title: str


class VisibleTextCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.skip = 0
        self.parts: list[str] = []

    def handle_starttag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        if tag in {"script", "style", "template", "svg"}:
            self.skip += 1
        if tag in {
            "p",
            "div",
            "section",
            "article",
            "main",
            "li",
            "h1",
            "h2",
            "h3",
            "h4",
            "h5",
            "h6",
            "br",
            "tr",
        } and not self.skip:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "template", "svg"} and self.skip:
            self.skip -= 1
        if tag in {
            "p",
            "div",
            "section",
            "article",
            "main",
            "li",
            "h1",
            "h2",
            "h3",
            "h4",
            "h5",
            "h6",
            "tr",
        } and not self.skip:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self.skip:
            text = data.strip()
            if text:
                self.parts.append(text)


class HtmlMetadataCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.in_title = False
        self.title_parts: list[str] = []
        self.in_json_ld = False
        self.current_json_ld: list[str] = []
        self.json_ld_blocks: list[str] = []

    def handle_starttag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        if tag == "title":
            self.in_title = True
        if tag != "script":
            return
        attributes = {name.lower(): value for name, value in attrs}
        script_type = (attributes.get("type") or "").split(";", 1)[0].strip().lower()
        if script_type == "application/ld+json":
            self.in_json_ld = True
            self.current_json_ld = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False
        if tag == "script" and self.in_json_ld:
            self.json_ld_blocks.append("".join(self.current_json_ld))
            self.current_json_ld = []
            self.in_json_ld = False

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_parts.append(data)
        if self.in_json_ld:
            self.current_json_ld.append(data)


def source_path_segment(value: str) -> str:
    decoded = unquote(value)
    candidate = decoded.strip()
    safe_pattern = r"[0-9A-Za-zА-Яа-яЁё._~-]+"
    if (
        decoded == candidate
        and candidate not in {"", ".", ".."}
        and re.fullmatch(safe_pattern, candidate)
        and len(candidate) <= 120
    ):
        return candidate

    digest = hashlib.sha256(decoded.encode("utf-8")).hexdigest()[:16]
    parts = re.findall(safe_pattern, candidate)
    readable = "-".join(parts).strip(".-_")[:96].rstrip(".-_")
    if readable:
        return f"{readable}-{digest}"
    return f"_segment-{digest}"


def hashed_url_component(prefix: str, value: str) -> str:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]
    return f"_{prefix}-{digest}"


def request_repo_root(request_file: Path) -> Path:
    absolute = Path(os.path.abspath(request_file))
    candidate = PurePosixPath(
        absolute.parent.parent.name,
        absolute.parent.name,
        absolute.name,
    )
    if session_stem_for_request_path(candidate) is None:
        raise ValueError(
            "request file must match "
            "Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_название]>/запрос.md"
        )
    return absolute.parent.parent.parent


def request_base_dir(request_file: Path) -> Path:
    """Return the repository root for a canonical request path."""

    return request_repo_root(request_file)


def url_output_dir(base_dir: Path, url: str) -> Path:
    parsed = urlsplit(url)
    if not parsed.scheme or not parsed.netloc:
        raise ValueError("URL must include scheme and host")
    if parsed.scheme.lower() not in {"http", "https"}:
        raise ValueError("source archive URL must use HTTP or HTTPS")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("source archive URL must not contain userinfo")

    host = parsed.hostname or parsed.netloc
    netloc = host.lower()
    try:
        port = parsed.port
    except ValueError:
        port = None
    if port is not None:
        netloc = f"{netloc}-{port}"

    parts = [
        "URL",
        source_path_segment(parsed.scheme.lower()),
        source_path_segment(netloc),
    ]
    path_parts = [source_path_segment(part) for part in parsed.path.split("/") if part]
    parts.extend(path_parts or ["_root"])
    if parsed.query:
        parts.append(hashed_url_component("query", parsed.query))
    if parsed.fragment:
        parts.append(hashed_url_component("fragment", parsed.fragment))
    return base_dir / "Источники" / Path(*parts)


def default_output_dir(request_file: Path, url: str) -> Path:
    return url_output_dir(request_base_dir(request_file), url)


def run_curl(url: str, body_path: Path, headers_path: Path) -> dict[str, str]:
    curl = shutil.which("curl")
    if not curl:
        raise RuntimeError("curl is required for reproducible header/body capture")

    write_out = (
        "url_effective=%{url_effective}\\n"
        "http_code=%{http_code}\\n"
        "content_type=%{content_type}\\n"
        "size_download=%{size_download}\\n"
        "time_total=%{time_total}\\n"
        "redirect_url=%{redirect_url}\\n"
    )
    try:
        proc = subprocess.run(
            [
                curl,
                "--proto",
                "=http,https",
                "--proto-redir",
                "=http,https",
                "-L",
                url,
                "-D",
                str(headers_path),
                "-o",
                str(body_path),
                "-w",
                write_out,
            ],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"curl capture failed with exit code {exc.returncode}"
        ) from exc
    info: dict[str, str] = {"transport": "curl"}
    for line in proc.stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            info[key] = value
    return info


def fixture_transport(fixture_dir: Path) -> Transport:
    body_fixture = fixture_dir / "response.body.html"
    headers_fixture = fixture_dir / "response.headers.txt"
    if not body_fixture.is_file() or not headers_fixture.is_file():
        raise ValueError(
            "test fixture transport requires response.body.html and response.headers.txt"
        )

    def capture(url: str, body_path: Path, headers_path: Path) -> dict[str, str]:
        shutil.copyfile(body_fixture, body_path)
        shutil.copyfile(headers_fixture, headers_path)
        headers = headers_fixture.read_text(encoding="utf-8", errors="replace")
        content_type = ""
        http_code = ""
        for index, line in enumerate(headers.splitlines()):
            if index == 0:
                match = re.search(r"\s(\d{3})(?:\s|$)", line)
                if match:
                    http_code = match.group(1)
            if line.lower().startswith("content-type:"):
                content_type = line.split(":", 1)[1].strip()
        return {
            "transport": "fixture",
            "url_effective": url,
            "http_code": http_code,
            "content_type": content_type,
            "size_download": str(body_fixture.stat().st_size),
        }

    return capture


def redact_headers(raw: str) -> str:
    lines = []
    for line in raw.splitlines(keepends=True):
        if line.lower().startswith("set-cookie:"):
            lines.append(COOKIE_REDACTION)
        else:
            lines.append(line)
    return "".join(lines)


def trim_trailing_whitespace(text: str) -> str:
    lines = [line.rstrip() for line in text.splitlines()]
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"


def collect_visible_text(html_text: str) -> str:
    parser = VisibleTextCollector()
    parser.feed(html_text)
    joined = " ".join(parser.parts)
    return "\n".join(line.strip() for line in re.split(r"\n+", joined) if line.strip())


def extract_html_metadata(html_text: str) -> tuple[str, list[Any], list[str]]:
    parser = HtmlMetadataCollector()
    parser.feed(html_text)
    title = re.sub(r"\s+", " ", "".join(parser.title_parts)).strip()
    structured: list[Any] = []
    errors: list[str] = []
    for index, block in enumerate(parser.json_ld_blocks, 1):
        try:
            structured.append(json.loads(block))
        except json.JSONDecodeError as exc:
            errors.append(f"JSON-LD block {index}: {exc.msg}")
    return title, structured, errors


def markdown_relative_path(from_file: Path, target: Path, directory: bool = False) -> str:
    relative = Path(os.path.relpath(target, from_file.parent)).as_posix()
    if directory and not relative.endswith("/"):
        relative += "/"
    return relative


def markdown_text(value: str) -> str:
    normalized = re.sub(r"\s+", " ", value).strip()
    return normalized.replace("\\", "\\\\").replace("[", "\\[").replace("]", "\\]")


def write_text_atomically(path: Path, text: str) -> None:
    if path.is_symlink():
        raise OSError(errno.ELOOP, "refusing to replace a symlink", str(path))

    mode = path.stat().st_mode & 0o7777 if path.exists() else None
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.tmp-",
        dir=path.parent,
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as temporary_file:
            temporary_file.write(text)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        if mode is not None:
            os.chmod(temporary_path, mode)
        os.replace(temporary_path, path)
    except BaseException:
        try:
            temporary_path.unlink(missing_ok=True)
        except OSError:
            pass
        raise


def link_source_in_request_file(request_file: Path, output_dir: Path, title: str) -> bool:
    if not request_file.exists():
        return False

    source_link = markdown_relative_path(request_file, output_dir, directory=True)
    index_link = markdown_relative_path(request_file, output_dir / "source-index.md")
    report_link = markdown_relative_path(request_file, output_dir / "extraction-report.md")
    text = request_file.read_text(encoding="utf-8")
    if index_link in text:
        return False

    entry = "\n".join(
        [
            f"- [Источник: {markdown_text(title)}]({source_link})",
            f"- [Индекс источника]({index_link})",
            f"- [Отчёт об извлечении]({report_link})",
        ]
    )
    header = "## Прикрепляемые материалы"
    if header not in text:
        updated = trim_trailing_whitespace(text) + "\n\n" + header + "\n\n" + entry + "\n"
        write_text_atomically(request_file, updated)
        return True

    pattern = re.compile(rf"({re.escape(header)}\n)(.*?)(?=\n## |\Z)", re.S)

    def append_entry(match: re.Match[str]) -> str:
        body = match.group(2).rstrip()
        if body:
            return match.group(1) + body + "\n" + entry + "\n"
        return match.group(1) + "\n" + entry + "\n"

    updated = pattern.sub(append_entry, text, count=1)
    write_text_atomically(request_file, updated)
    return True


def snapshot_relative_files(directory: Path) -> list[str]:
    return sorted(
        path.relative_to(directory).as_posix()
        for path in directory.rglob("*")
        if path.is_file()
    )


def write_snapshot_manifest(directory: Path, managed_files: list[str]) -> None:
    payload = {
        "schema": SNAPSHOT_MANIFEST_SCHEMA,
        "managed_files": managed_files,
    }
    (directory / SNAPSHOT_MANIFEST_NAME).write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def validate_snapshot_manifest(directory: Path) -> None:
    manifest_path = directory / SNAPSHOT_MANIFEST_NAME
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError("snapshot manifest is missing or invalid") from exc

    if not isinstance(manifest, dict) or manifest.get("schema") != SNAPSHOT_MANIFEST_SCHEMA:
        raise ValueError("snapshot manifest schema is invalid")
    managed_files = manifest.get("managed_files")
    if not isinstance(managed_files, list) or not all(
        isinstance(name, str) for name in managed_files
    ):
        raise ValueError("snapshot manifest managed_files must be a string list")
    if managed_files != sorted(set(managed_files)):
        raise ValueError("snapshot manifest managed_files must be sorted and unique")
    for name in managed_files:
        relative = Path(name)
        if not name or relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"snapshot manifest contains unsafe path: {name!r}")
    actual_files = snapshot_relative_files(directory)
    if actual_files != managed_files:
        raise ValueError(
            "snapshot files do not match manifest: "
            f"expected {managed_files!r}, got {actual_files!r}"
        )


def try_atomic_directory_exchange(first: Path, second: Path) -> bool:
    libc = ctypes.CDLL(None, use_errno=True)
    first_bytes = os.fsencode(first)
    second_bytes = os.fsencode(second)
    flags = 0x00000002
    if sys.platform == "darwin":
        try:
            rename = libc.renameatx_np
        except AttributeError:
            return False
        rename.argtypes = [
            ctypes.c_int,
            ctypes.c_char_p,
            ctypes.c_int,
            ctypes.c_char_p,
            ctypes.c_uint,
        ]
        rename.restype = ctypes.c_int
        result = rename(-2, first_bytes, -2, second_bytes, flags)
    elif sys.platform.startswith("linux"):
        try:
            rename = libc.renameat2
        except AttributeError:
            return False
        rename.argtypes = [
            ctypes.c_int,
            ctypes.c_char_p,
            ctypes.c_int,
            ctypes.c_char_p,
            ctypes.c_uint,
        ]
        rename.restype = ctypes.c_int
        result = rename(-100, first_bytes, -100, second_bytes, flags)
    else:
        return False
    if result == 0:
        return True
    error_number = ctypes.get_errno()
    unsupported_errors = {
        errno.EINVAL,
        errno.ENOSYS,
        errno.EXDEV,
        getattr(errno, "ENOTSUP", errno.EINVAL),
        getattr(errno, "EOPNOTSUPP", errno.EINVAL),
    }
    if error_number in unsupported_errors:
        return False
    raise OSError(error_number, os.strerror(error_number))


def install_snapshot(
    staging_dir: Path,
    output_dir: Path,
    exchange: Callable[[Path, Path], bool] = try_atomic_directory_exchange,
) -> None:
    if output_dir.is_symlink() or (output_dir.exists() and not output_dir.is_dir()):
        raise ValueError(f"snapshot destination is not a real directory: {output_dir}")
    if not output_dir.exists():
        os.replace(staging_dir, output_dir)
        return
    if exchange(staging_dir, output_dir):
        return
    raise RuntimeError(
        "atomic directory exchange is unavailable for the existing snapshot; "
        "the canonical snapshot was not changed"
    )


def validate_request_file(request_file: Path) -> None:
    if request_file.is_symlink() or not request_file.is_file():
        raise ValueError(f"request file must be an existing regular file: {request_file}")
    if request_file.suffix.lower() != ".md":
        raise ValueError(f"request file must be Markdown: {request_file}")
    request_repo_root(request_file)


def ensure_destination_matches_url(output_dir: Path, url: str) -> None:
    if not os.path.lexists(output_dir):
        return
    if output_dir.is_symlink() or not output_dir.is_dir():
        raise ValueError(f"snapshot destination is not a real directory: {output_dir}")
    source_url = output_dir / "source-url.txt"
    if source_url.is_symlink() or not source_url.is_file():
        raise ValueError(
            "existing snapshot has no trustworthy source-url.txt and cannot be replaced"
        )
    try:
        stored_url = source_url.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise ValueError("existing snapshot source-url.txt is unreadable") from exc
    if stored_url != url + "\n":
        raise ValueError(
            "existing snapshot belongs to a different URL and cannot be replaced"
        )


def write_extracted_text(path: Path, url: str, visible_text: str) -> None:
    lines = [
        "# Извлечённый текст",
        "",
        f"Источник: <{url}>",
        "",
        "## Содержимое",
        "",
        visible_text or "_Видимый текст не найден._",
    ]
    path.write_text(trim_trailing_whitespace("\n".join(lines)), encoding="utf-8")


def write_source_index(
    path: Path,
    url: str,
    title: str,
    files: list[str],
) -> None:
    file_set = set(files)
    lines = [
        f"# Источник: {markdown_text(title)}",
        "",
        f"Исходный URL: <{url}>",
        "",
        "Тип источника: HTML-страница по устойчивому URL.",
        "",
        "## Основные файлы",
        "",
        "- [Извлечённый текст](extracted-text.md)",
        "- [Отчёт об извлечении](extraction-report.md)",
        "- [Очищенные HTTP-заголовки](response.headers.txt)",
        "- [Сохранённый HTML](response.body.html)",
    ]
    if "structured-data.json" in file_set:
        lines.append("- [Структурированные данные](structured-data.json)")
    lines.extend(["", "## Все сохранённые файлы", ""])
    lines.extend(f"- `{name}`" for name in sorted(file_set))
    path.write_text(trim_trailing_whitespace("\n".join(lines)), encoding="utf-8")


def write_report(
    path: Path,
    url: str,
    info: dict[str, str],
    files: list[str],
    structured_count: int,
    structured_errors: list[str],
) -> None:
    lines = [
        "# Отчёт об извлечении прикрепляемого материала",
        "",
        f"- Источник: {url}",
        f"- Время извлечения UTC: {dt.datetime.now(dt.timezone.utc).isoformat()}",
        f"- Транспорт: {info.get('transport', '')}",
        f"- Effective URL: {info.get('url_effective', '')}",
        f"- HTTP-код: {info.get('http_code', '')}",
        f"- Content-Type: {info.get('content_type', '')}",
        f"- Размер загрузки: {info.get('size_download', '')} байт",
        f"- Извлечено блоков JSON-LD: {structured_count}",
        "",
        "## Редакции перед сохранением",
        "",
        "- Значения `Set-Cookie` в HTTP-заголовках заменены на `[REDACTED: response cookie]`.",
        "- HTML и извлечённый текст сохранены без перевода и смысловой нормализации.",
        "",
        "## Ограничения извлечения",
        "",
    ]
    if structured_errors:
        lines.extend(f"- {error}" for error in structured_errors)
    else:
        lines.append("- Ошибок разбора JSON-LD не обнаружено.")
    lines.extend(["", "## Сохранённые файлы", ""])
    lines.extend(f"- `{name}`" for name in sorted(files))
    path.write_text(trim_trailing_whitespace("\n".join(lines)), encoding="utf-8")


def build_snapshot(
    staging_dir: Path,
    url: str,
    transport: Transport,
) -> str:
    with tempfile.TemporaryDirectory(prefix="fum-source-capture-") as capture:
        capture_dir = Path(capture)
        raw_body = capture_dir / "response.body.html"
        raw_headers = capture_dir / "response.headers.txt"
        info = transport(url, raw_body, raw_headers)
        body_bytes = raw_body.read_bytes()
        html_text = body_bytes.decode("utf-8", errors="replace")
        headers_text = raw_headers.read_text(encoding="utf-8", errors="replace")

    title, structured, structured_errors = extract_html_metadata(html_text)
    if not title:
        title = urlsplit(url).hostname or "URL-источник"
    visible_text = collect_visible_text(html_text)
    (staging_dir / "source-url.txt").write_text(url + "\n", encoding="utf-8")
    (staging_dir / "response.headers.txt").write_text(
        trim_trailing_whitespace(redact_headers(headers_text)),
        encoding="utf-8",
    )
    (staging_dir / "response.body.html").write_bytes(body_bytes)
    write_extracted_text(staging_dir / "extracted-text.md", url, visible_text)
    if structured:
        structured_payload: Any = structured[0] if len(structured) == 1 else structured
        (staging_dir / "structured-data.json").write_text(
            json.dumps(structured_payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    managed_files = sorted(
        set(snapshot_relative_files(staging_dir))
        | {
            "extraction-report.md",
            SNAPSHOT_MANIFEST_NAME,
            "source-index.md",
        }
    )
    write_source_index(staging_dir / "source-index.md", url, title, managed_files)
    write_report(
        staging_dir / "extraction-report.md",
        url,
        info,
        managed_files,
        len(structured),
        structured_errors,
    )
    write_snapshot_manifest(staging_dir, managed_files)
    validate_snapshot_manifest(staging_dir)
    return title


def archive_url(
    url: str,
    request_file: Path,
    *,
    transport: Transport = run_curl,
    before_install: BeforeInstall | None = None,
) -> ArchiveResult:
    validate_request_file(request_file)
    output_dir = default_output_dir(request_file, url)
    ensure_destination_matches_url(output_dir, url)
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix=f".{output_dir.name}.staging-",
        dir=output_dir.parent,
        ignore_cleanup_errors=True,
    ) as staging:
        staging_dir = Path(staging)
        title = build_snapshot(staging_dir, url, transport)
        if before_install is not None:
            before_install(staging_dir)
        ensure_destination_matches_url(output_dir, url)
        install_snapshot(staging_dir, output_dir)

    if os.path.lexists(staging_dir):
        print(
            "warning: old snapshot remains in staging after commit: "
            f"{staging_dir}",
            file=sys.stderr,
        )

    link_error: OSError | None = None
    try:
        linked_request = link_source_in_request_file(request_file, output_dir, title)
    except OSError as exc:
        linked_request = False
        link_error = exc
    if link_error is not None:
        print(
            "warning: snapshot was saved, but the request file was not linked: "
            f"{link_error}",
            file=sys.stderr,
        )
    return ArchiveResult(output_dir, linked_request, title)


def test_failpoint(name: str) -> BeforeInstall:
    if name != "after-build":
        raise ValueError(f"unsupported source archive test failpoint: {name}")

    def fail_after_build(staging_dir: Path) -> None:
        validate_snapshot_manifest(staging_dir)
        raise RuntimeError("test failpoint after-build")

    return fail_after_build


def archive_command(args: Any) -> int:
    fixture_dir = os.environ.get(TEST_FIXTURE_ENV)
    failpoint_name = os.environ.get(TEST_FAILPOINT_ENV)
    if failpoint_name and not fixture_dir:
        raise ValueError(f"{TEST_FAILPOINT_ENV} requires {TEST_FIXTURE_ENV}")
    transport = fixture_transport(Path(fixture_dir)) if fixture_dir else run_curl
    before_install = test_failpoint(failpoint_name) if failpoint_name else None
    result = archive_url(
        args.url,
        args.request,
        transport=transport,
        before_install=before_install,
    )
    print(f"saved {result.output_dir}")
    print(f"request_file_linked {'yes' if result.linked_request else 'no'}")
    return 0
