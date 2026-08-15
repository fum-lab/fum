#!/usr/bin/env python3
"""Archive a ChatGPT share page for a FUM sources folder."""

from __future__ import annotations

import argparse
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
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
from typing import Any
from urllib.parse import unquote, urlsplit


REQUEST_LAYOUT_SCRIPTS = (
    Path(__file__).resolve().parents[2]
    / "fum-struktura-papok-zaprosov"
    / "scripts"
)
if str(REQUEST_LAYOUT_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(REQUEST_LAYOUT_SCRIPTS))

from request_folder_layout import session_stem_for_request_path  # noqa: E402


REDACTION = "[REDACTED: local request metadata]"
COOKIE_REDACTION = "set-cookie: [REDACTED: response cookie]\n"
SNAPSHOT_MANIFEST_NAME = "snapshot-manifest.json"
SNAPSHOT_MANIFEST_SCHEMA = "fum.request-materials.snapshot-manifest.v1"
LOCAL_METADATA_KEYS = {
    "account_user_id",
    "async_source",
    "notification_id",
    "request_id",
    "turn_exchange_id",
    "working_turn_id",
}


class ScriptCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.in_script = False
        self.current: list[str] = []
        self.scripts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "script":
            self.in_script = True
            self.current = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "script" and self.in_script:
            self.scripts.append("".join(self.current))
            self.in_script = False

    def handle_data(self, data: str) -> None:
        if self.in_script:
            self.current.append(data)


class VisibleTextCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.skip = 0
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in {"script", "style", "template", "svg"}:
            self.skip += 1
        if tag in {"p", "div", "section", "article", "main", "li", "h1", "h2", "h3", "h4", "h5", "h6", "br", "tr"} and not self.skip:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "template", "svg"} and self.skip:
            self.skip -= 1
        if tag in {"p", "div", "section", "article", "main", "li", "h1", "h2", "h3", "h4", "h5", "h6", "tr"} and not self.skip:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self.skip:
            text = data.strip()
            if text:
                self.parts.append(text)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="ChatGPT share URL")
    parser.add_argument(
        "--request-file",
        required=True,
        type=Path,
        help=(
            "Path to Журнал/<YYYY-MM-DD_HH-MM-SS_MSK[_name]>/запрос.md"
        ),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Explicit sources directory. Overrides the URL-derived default.",
    )
    parser.add_argument(
        "--source-name",
        help=(
            "Optional descriptive source name. Kept for compatibility; "
            "stable URLs use an URL-derived default directory."
        ),
    )
    return parser.parse_args()


def source_name_slug(source_name: str) -> str:
    parts = re.findall(r"[0-9A-Za-zА-Яа-яЁё]+", source_name)
    return "-".join(parts) or "источник"


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


def request_materials_root(request_file: Path) -> Path:
    request_repo_root(request_file)
    return Path(os.path.abspath(request_file)).parent / "материалы" / "источники"


def validate_source_url(url: str):
    parsed = urlsplit(url)
    if not parsed.scheme or not parsed.netloc:
        raise ValueError("URL must include scheme and host")
    if parsed.scheme.lower() not in {"http", "https"}:
        raise ValueError("source archive URL must use HTTP or HTTPS")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("source archive URL must not contain userinfo")
    return parsed


def url_output_dir(base_dir: Path, url: str) -> Path:
    parsed = validate_source_url(url)

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


def default_output_dir(
    request_file: Path,
    url: str,
    source_name: str | None = None,
) -> Path:
    repo_root = request_base_dir(request_file)
    try:
        return url_output_dir(repo_root, url)
    except ValueError:
        if source_name:
            return request_materials_root(request_file) / source_name_slug(source_name)
        raise


def run_curl(url: str, html_path: Path, headers_path: Path) -> dict[str, str]:
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
                str(html_path),
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
    info: dict[str, str] = {}
    for line in proc.stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            info[key] = value
    return info


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


def markdown_text(value: str) -> str:
    normalized = re.sub(r"\s+", " ", value).strip()
    return normalized.replace("\\", "\\\\").replace("[", "\\[").replace("]", "\\]")


def readable_dialog_title(messages_data: dict[str, Any]) -> str:
    title = messages_data.get("title")
    if isinstance(title, str) and title.strip():
        return title.strip()
    return "Расшаренный диалог ChatGPT"


def formatted_messages_markdown_name(messages_data: dict[str, Any]) -> str:
    title = readable_dialog_title(messages_data)
    segment = source_name_slug(title).lower()
    if not re.search(r"[0-9A-Za-zА-Яа-яЁё]", title):
        segment = "расшаренный-диалог-chatgpt"
    return f"{segment}.md"


def readable_role(role: Any) -> str:
    labels = {
        "assistant": "Ассистент",
        "system": "Система",
        "tool": "Служебный вывод инструмента",
        "user": "Пользователь",
    }
    if isinstance(role, str) and role:
        return labels.get(role, role)
    return "Неизвестная роль"


def strip_chatgpt_citations(text: str) -> str:
    return re.sub(r"\s*\ue200cite\ue202[^\ue201]*\ue201", "", text)


def format_obsidian_math(text: str) -> str:
    text = re.sub(r"(?m)^[ \t]*\\\[[ \t]*$", "$$", text)
    text = re.sub(r"(?m)^[ \t]*\\\][ \t]*$", "$$", text)
    return re.sub(r"\\\(([^\n]+?)\\\)", r"$\1$", text)


def is_json_only_text(text: Any) -> bool:
    if not isinstance(text, str):
        return False
    stripped = text.strip()
    if not stripped.startswith(("{", "[")):
        return False
    try:
        json.loads(stripped)
    except json.JSONDecodeError:
        return False
    return True


def is_service_message(message: dict[str, Any]) -> bool:
    role = message.get("role")
    if role not in {"assistant", "user"}:
        return True
    return role == "assistant" and is_json_only_text(message.get("text"))


def format_message_text(text: Any) -> str:
    if not isinstance(text, str):
        return ""
    stripped = text.strip()
    if not stripped:
        return ""
    if stripped.startswith(("{", "[")):
        try:
            parsed = json.loads(stripped)
        except json.JSONDecodeError:
            return stripped
        return "```json\n" + json.dumps(parsed, ensure_ascii=False, indent=2) + "\n```"
    return format_obsidian_math(strip_chatgpt_citations(stripped))


def redact_initial_state(value: Any) -> Any:
    sensitive_exact = {
        "cfConnectingIp",
        "cfIpCity",
        "cfIpLatitude",
        "cfIpLongitude",
        "cfIpRegion",
        "cfIpRegionCode",
        "cfIpCountry",
        "userContinent",
        "userCountry",
        "userRegion",
        "userRegionCode",
        "sessionId",
        "DeviceId",
        "WebAnonymousCookieID",
        "stableID",
        "ip",
        "userAgent",
        "user_agent",
        "region",
        "region_code",
        "country",
        *LOCAL_METADATA_KEYS,
    }
    if isinstance(value, dict):
        redacted: dict[str, Any] = {}
        for key, item in value.items():
            if key == "statsigPayload" and isinstance(item, str):
                try:
                    statsig = json.loads(item)
                    redacted[key] = json.dumps(redact_initial_state(statsig), ensure_ascii=False)
                except json.JSONDecodeError:
                    redacted[key] = REDACTION
            elif key in sensitive_exact:
                redacted[key] = REDACTION
            elif key == "id" and isinstance(item, str) and item.startswith("ua-"):
                redacted[key] = REDACTION
            else:
                redacted[key] = redact_initial_state(item)
        return redacted
    if isinstance(value, list):
        return [redact_initial_state(item) for item in value]
    return value


def собрать_значения_локальных_метаданных(value: Any) -> set[str]:
    values: set[str] = set()
    if isinstance(value, dict):
        for key, item in value.items():
            if key in LOCAL_METADATA_KEYS and isinstance(item, str) and item:
                values.add(item)
            if key == "statsigPayload" and isinstance(item, str):
                try:
                    разобранная_телеметрия = json.loads(item)
                except json.JSONDecodeError:
                    pass
                else:
                    values.update(собрать_значения_локальных_метаданных(разобранная_телеметрия))
            values.update(собрать_значения_локальных_метаданных(item))
    elif isinstance(value, list):
        for item in value:
            values.update(собрать_значения_локальных_метаданных(item))
    elif isinstance(value, str) and "bon-user-" in value:
        values.add(value)
    return values


def redact_text_values(text: str, values: set[str]) -> str:
    redacted = text
    for value in sorted(values, key=len, reverse=True):
        if value:
            redacted = redacted.replace(value, REDACTION)
    return redacted


def collect_scripts(html_text: str) -> list[str]:
    parser = ScriptCollector()
    parser.feed(html_text)
    return parser.scripts


def collect_visible_text(html_text: str) -> str:
    parser = VisibleTextCollector()
    parser.feed(html_text)
    joined = " ".join(parser.parts)
    return "\n".join(line.strip() for line in re.split(r"\n+", joined) if line.strip())


def sanitize_html(html_text: str, scripts: list[str]) -> tuple[str, Any | None]:
    initial_state = None
    for body in scripts:
        stripped = body.strip()
        if not stripped.startswith('{"authStatus"'):
            continue
        try:
            parsed = json.loads(stripped)
        except json.JSONDecodeError:
            continue
        значения_локальных_метаданных = собрать_значения_локальных_метаданных(parsed)
        initial_state = redact_initial_state(parsed)
        redacted_body = json.dumps(initial_state, ensure_ascii=False, separators=(",", ":"))
        html_text = html_text.replace(body, redacted_body, 1)
        html_text = redact_text_values(html_text, значения_локальных_метаданных)
        break
    return html_text, initial_state


def extract_stream_parts(scripts: list[str]) -> list[str]:
    parts: list[str] = []
    pattern = re.compile(
        r"window\.__reactRouterContext\.streamController\.enqueue\((\"(?:[^\"\\]|\\.)*\")\);",
        re.S,
    )
    for body in scripts:
        for match in pattern.finditer(body):
            try:
                parts.append(json.loads(match.group(1)))
            except json.JSONDecodeError:
                parts.append(match.group(1))
    return parts


def decode_react_router_table(stream_text: str) -> Any:
    first = stream_text.split("\n\n--- stream part ---\n\n", 1)[0]
    table = json.loads(first)
    if not isinstance(table, list):
        raise ValueError("React Router stream root is not a table array")

    size = len(table)
    negative = {
        -1: "$NEGATIVE_ONE",
        -2: "$NEGATIVE_TWO",
        -3: "$NEGATIVE_THREE",
        -4: "$NEGATIVE_FOUR",
        -5: "$UNDEFINED",
    }
    memo: dict[int, Any] = {}
    resolving: set[int] = set()

    def resolve_ref(index: int) -> Any:
        if index < 0:
            return negative.get(index, f"$NEGATIVE:{index}")
        if index >= size:
            return index
        if index in memo:
            return memo[index]
        if index in resolving:
            return f"$CYCLE:{index}"
        resolving.add(index)
        value = decode(table[index])
        resolving.remove(index)
        memo[index] = value
        return value

    def decode(value: Any) -> Any:
        if isinstance(value, int):
            return resolve_ref(value)
        if isinstance(value, list):
            return [decode(item) for item in value]
        if isinstance(value, dict):
            out: dict[str, Any] = {}
            for key, item in value.items():
                if isinstance(key, str) and key.startswith("_") and key[1:].isdigit():
                    decoded_key = resolve_ref(int(key[1:]))
                else:
                    decoded_key = key
                if not isinstance(decoded_key, str):
                    decoded_key = json.dumps(decoded_key, ensure_ascii=False)
                out[decoded_key] = decode(item)
            return out
        return value

    return resolve_ref(0)


def extract_messages(decoded: Any) -> dict[str, Any]:
    route = (
        decoded.get("loaderData", {})
        .get("routes/share.$shareId.($action)", {})
    )
    server = route.get("serverResponse", {})
    data = server.get("data", {}) if isinstance(server, dict) else {}
    linear = data.get("linear_conversation", []) if isinstance(data, dict) else []

    messages: list[dict[str, Any]] = []
    for item in linear:
        node = item if isinstance(item, dict) else None
        if not isinstance(node, dict):
            continue
        msg = node.get("message")
        if not isinstance(msg, dict):
            continue
        author = msg.get("author") or {}
        content = msg.get("content") or {}
        parts = content.get("parts")
        if isinstance(parts, list):
            text = "\n".join(part for part in parts if isinstance(part, str)).strip()
        elif isinstance(parts, str):
            text = parts.strip()
        elif isinstance(content.get("text"), str):
            text = content["text"].strip()
        else:
            text = ""
        if not text:
            continue
        timestamp = msg.get("create_time")
        timestamp_utc = None
        if isinstance(timestamp, (int, float)):
            timestamp_utc = dt.datetime.fromtimestamp(timestamp, dt.timezone.utc).isoformat()
        messages.append(
            {
                "node_id": node.get("id"),
                "parent": node.get("parent"),
                "role": author.get("role") or author.get("name") or "unknown",
                "content_type": content.get("content_type"),
                "create_time": timestamp,
                "create_time_utc": timestamp_utc,
                "text": text,
            }
        )

    return {
        "title": data.get("title"),
        "conversation_id": data.get("conversation_id"),
        "backing_conversation_id": data.get("backing_conversation_id"),
        "create_time": data.get("create_time"),
        "update_time": data.get("update_time"),
        "message_count": len(messages),
        "messages": messages,
    }


def write_messages_markdown(path: Path, url: str, messages_data: dict[str, Any]) -> None:
    title = readable_dialog_title(messages_data)
    readable_messages = [
        message
        for message in messages_data.get("messages", [])
        if isinstance(message, dict) and not is_service_message(message)
    ]
    lines = [
        f"# {markdown_text(title)}",
        "",
        f"Источник: <{url}>",
        "",
        "Полный структурный слой: [chatgpt-share.messages.json](chatgpt-share.messages.json).",
        "",
        "## Диалог",
        "",
    ]
    if not readable_messages:
        lines.append("_Читаемых сообщений не найдено._")
        lines.append("")
    for index, message in enumerate(readable_messages, 1):
        role = message.get("role")
        lines.append(f"### {index}. {readable_role(role)}")
        lines.append("")
        lines.append(format_message_text(message.get("text", "")))
        lines.append("")
    path.write_text(trim_trailing_whitespace("\n".join(lines)), encoding="utf-8")


def markdown_relative_path(from_file: Path, target: Path, directory: bool = False) -> str:
    relative = Path(os.path.relpath(target, from_file.parent)).as_posix()
    if directory and not relative.endswith("/"):
        relative += "/"
    return relative


def write_source_index(
    path: Path,
    url: str,
    files: list[str],
    messages_data: dict[str, Any],
) -> None:
    title = readable_dialog_title(messages_data)
    file_set = set(files)
    markdown_name = formatted_messages_markdown_name(messages_data)
    lines = [
        f"# Источник: {markdown_text(title)}",
        "",
        f"Исходный URL: <{url}>",
        "",
        "Тип источника: расшаренный диалог ChatGPT.",
        "",
        "## Основные файлы",
        "",
    ]
    if markdown_name in file_set:
        lines.append(f"- [Оформленный диалог]({markdown_name})")
    if "extraction-report.md" in file_set:
        lines.append("- [Отчёт об извлечении](extraction-report.md)")
    if "chatgpt-share.messages.json" in file_set:
        lines.append("- [Структурный слой сообщений](chatgpt-share.messages.json)")
    if "chatgpt-share.html" in file_set:
        lines.append("- [Сохранённый HTML](chatgpt-share.html)")
    lines.extend(["", "## Все сохранённые файлы", ""])
    lines.extend(f"- `{name}`" for name in sorted(file_set))
    path.write_text(trim_trailing_whitespace("\n".join(lines)), encoding="utf-8")


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


def write_report(
    path: Path,
    url: str,
    info: dict[str, str],
    files: list[str],
    message_count: int,
    had_initial_state: bool,
    decoded_ok: bool,
) -> None:
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    lines = [
        "# Отчёт об извлечении прикрепляемого материала",
        "",
        f"- Источник: {url}",
        f"- Время извлечения UTC: {now}",
        f"- Effective URL: {info.get('url_effective', '')}",
        f"- HTTP-код: {info.get('http_code', '')}",
        f"- Content-Type: {info.get('content_type', '')}",
        f"- Размер загрузки: {info.get('size_download', '')} байт",
        f"- Начальное состояние страницы найдено: {'да' if had_initial_state else 'нет'}",
        f"- Распаковка диалога выполнена: {'да' if decoded_ok else 'нет'}",
        f"- Извлечено сообщений: {message_count}",
        "",
        "## Редакции перед сохранением",
        "",
        "- Значения `Set-Cookie` в HTTP-заголовках заменены на `[REDACTED: response cookie]`.",
        "- Локальные IP, геометаданные запроса, user-agent, идентификаторы устройства, сессии, пользователя, аккаунта и Statsig в bootstrap-состоянии страницы, а также служебные request-id распакованного потока заменены на `[REDACTED: local request metadata]`.",
        "- Сырой текст диалога, поток React Router и распакованные сообщения не нормализовались и не переводились.",
        "- Оформленный Markdown-слой пропускает служебные сообщения, убирает машинные citation-маркеры и переводит TeX-делимитеры в формат, отображаемый Obsidian.",
        "",
        "## Сохранённые файлы",
        "",
    ]
    lines.extend(f"- `{name}`" for name in sorted(files))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


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


def install_snapshot(staging_dir: Path, output_dir: Path) -> None:
    if output_dir.is_symlink() or (output_dir.exists() and not output_dir.is_dir()):
        raise ValueError(f"snapshot destination is not a real directory: {output_dir}")

    if not output_dir.exists():
        os.replace(staging_dir, output_dir)
        return

    if try_atomic_directory_exchange(staging_dir, output_dir):
        return

    raise RuntimeError(
        "atomic directory exchange is unavailable for the existing snapshot; "
        "the canonical snapshot was not changed"
    )


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


def validate_request_file(request_file: Path) -> None:
    if request_file.is_symlink() or not request_file.is_file():
        raise ValueError(f"request file must be an existing regular file: {request_file}")
    if request_file.suffix.lower() != ".md":
        raise ValueError(f"request file must be Markdown: {request_file}")
    request_repo_root(request_file)


def build_snapshot(staging_dir: Path, url: str) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="fum-chatgpt-share-") as tmp:
        tmpdir = Path(tmp)
        raw_html = tmpdir / "chatgpt-share.html"
        raw_headers = tmpdir / "chatgpt-share.headers.txt"
        info = run_curl(url, raw_html, raw_headers)
        html_text = raw_html.read_text(encoding="utf-8", errors="replace")
        headers_text = raw_headers.read_text(encoding="utf-8", errors="replace")

    original_scripts = collect_scripts(html_text)
    sanitized_html, initial_state = sanitize_html(html_text, original_scripts)
    scripts = collect_scripts(sanitized_html)

    stream_parts = extract_stream_parts(scripts)
    stream_text = "\n\n--- stream part ---\n\n".join(stream_parts)

    decoded_ok = False
    decoded: Any | None = None
    local_metadata_values: set[str] = set()
    messages_data: dict[str, Any] = {"message_count": 0, "messages": []}
    if stream_parts:
        try:
            raw_decoded = decode_react_router_table(stream_text)
            decoded_ok = True
            local_metadata_values = собрать_значения_локальных_метаданных(raw_decoded)
            decoded = redact_initial_state(raw_decoded)
            messages_data = extract_messages(decoded)
            messages_data["source_url"] = url
        except Exception as exc:  # noqa: BLE001 - preserve failure in report.
            (staging_dir / "decode-error.txt").write_text(
                repr(exc) + "\n",
                encoding="utf-8",
            )

    if local_metadata_values:
        sanitized_html = redact_text_values(sanitized_html, local_metadata_values)
        scripts = [redact_text_values(body, local_metadata_values) for body in scripts]
        stream_text = redact_text_values(stream_text, local_metadata_values)

    (staging_dir / "source-url.txt").write_text(url + "\n", encoding="utf-8")
    (staging_dir / "chatgpt-share.headers.txt").write_text(
        trim_trailing_whitespace(redact_headers(headers_text)),
        encoding="utf-8",
    )
    (staging_dir / "chatgpt-share.html").write_text(
        trim_trailing_whitespace(sanitized_html),
        encoding="utf-8",
    )
    (staging_dir / "chatgpt-share.visible-text.txt").write_text(
        collect_visible_text(sanitized_html),
        encoding="utf-8",
    )

    if initial_state is not None:
        (staging_dir / "chatgpt-share.initial-state.json").write_text(
            json.dumps(initial_state, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    for index, body in enumerate(scripts):
        if len(body) > 1000 or "streamController.enqueue" in body:
            (staging_dir / f"chatgpt-share.script-{index:02d}.txt").write_text(
                body,
                encoding="utf-8",
            )

    (staging_dir / "chatgpt-share.react-router-stream.txt").write_text(
        stream_text,
        encoding="utf-8",
    )

    if decoded is not None:
        (staging_dir / "chatgpt-share.decoded-data.json").write_text(
            json.dumps(decoded, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        (staging_dir / "chatgpt-share.messages.json").write_text(
            json.dumps(messages_data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        markdown_name = formatted_messages_markdown_name(messages_data)
        write_messages_markdown(
            staging_dir / markdown_name,
            url,
            messages_data,
        )

    managed_files = sorted(
        set(snapshot_relative_files(staging_dir))
        | {
            "extraction-report.md",
            SNAPSHOT_MANIFEST_NAME,
            "source-index.md",
        }
    )
    write_source_index(
        staging_dir / "source-index.md",
        url,
        managed_files,
        messages_data,
    )
    write_report(
        staging_dir / "extraction-report.md",
        url,
        info,
        managed_files,
        int(messages_data.get("message_count", 0)),
        initial_state is not None,
        decoded_ok,
    )
    write_snapshot_manifest(staging_dir, managed_files)
    validate_snapshot_manifest(staging_dir)
    return messages_data


def main() -> int:
    args = parse_args()
    validate_source_url(args.url)
    request_file = args.request_file
    validate_request_file(request_file)
    output_dir = args.output_dir or default_output_dir(request_file, args.url, args.source_name)
    ensure_destination_matches_url(output_dir, args.url)
    output_dir.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(
        prefix=f".{output_dir.name}.staging-",
        dir=output_dir.parent,
        ignore_cleanup_errors=True,
    ) as staging:
        staging_dir = Path(staging)
        messages_data = build_snapshot(staging_dir, args.url)
        ensure_destination_matches_url(output_dir, args.url)
        install_snapshot(staging_dir, output_dir)

    if os.path.lexists(staging_dir):
        print(
            "warning: old snapshot remains in staging after commit: "
            f"{staging_dir}",
            file=sys.stderr,
        )

    link_error: OSError | None = None
    try:
        linked_request = link_source_in_request_file(
            request_file,
            output_dir,
            readable_dialog_title(messages_data),
        )
    except OSError as exc:
        linked_request = False
        link_error = exc

    print(f"saved {output_dir}")
    print(f"messages {messages_data.get('message_count', 0)}")
    if link_error is None:
        print(f"request_file_linked {'yes' if linked_request else 'no'}")
    else:
        print("request_file_linked error")
        print(
            "warning: snapshot was saved, but the request file was not linked: "
            f"{link_error}",
            file=sys.stderr,
        )
    return 0


def cli() -> int:
    try:
        return main()
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(cli())
